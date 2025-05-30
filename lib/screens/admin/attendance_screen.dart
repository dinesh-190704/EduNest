import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../models/college_leave_model.dart';
import '../../services/attendance_service.dart';
import '../../services/college_leave_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();
  AttendanceService? _attendanceService;
  final CollegeLeaveService _collegeLeaveService = CollegeLeaveService();
  DateTime _selectedDate = DateTime.now();
  String _selectedDepartment = 'Information Technology';
  String _selectedYear = '1st Year';
  String _selectedSection = 'A';
  List<Student> _students = [];
  Map<String, bool> _attendance = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isCollegeLeave = false;

  final List<String> departments = [
    'Information Technology',
  ];

  final List<String> years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  final List<String> sections = ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _checkCollegeLeave();
  }

  Future<void> _checkCollegeLeave() async {
    final isLeave = await _collegeLeaveService.isCollegeLeaveDay(_selectedDate);
    setState(() {
      _isCollegeLeave = isLeave;
    });
  }

  Future<void> _toggleCollegeLeave() async {
    if (_isCollegeLeave) {
      // Remove college leave
      final snapshot = await _collegeLeaveService.getCollegeLeaves().first;
      final leaves = snapshot.where((leave) => 
        leave.date.year == _selectedDate.year && 
        leave.date.month == _selectedDate.month && 
        leave.date.day == _selectedDate.day
      ).toList();
      
      if (leaves.isNotEmpty) {
        await _collegeLeaveService.removeCollegeLeave(leaves.first.id);
      }
    } else {
      // Show dialog to add college leave reason
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add College Leave', style: GoogleFonts.poppins()),
          content: TextField(
            controller: _leaveReasonController,
            decoration: InputDecoration(
              labelText: 'Reason for Leave',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_leaveReasonController.text.isNotEmpty) {
                  await _collegeLeaveService.addCollegeLeave(
                    _selectedDate,
                    _leaveReasonController.text,
                  );
                  _leaveReasonController.clear();
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              child: Text('Add', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    }
    await _checkCollegeLeave();
  }

  Future<void> _initializeService() async {
    try {
      setState(() {
        _attendanceService = AttendanceService();
        _dateController.text = DateFormat('MMMM dd, yyyy').format(_selectedDate);
      });
      await _checkCollegeLeave();
      await _loadStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_attendanceService == null) return;
    setState(() => _isLoading = true);
    try {
      final students = await _attendanceService!.getStudentsByClass(
        department: _selectedDepartment,
        year: _selectedYear,
        section: _selectedSection,
      );
      
      // Load existing attendance for the selected date
      final existingAttendance = await _attendanceService!.getAttendanceByDate(
        _selectedDate,
        section: _selectedSection,
      );
      
      setState(() {
        _students = students;
        _attendance = {
          for (var student in students)
            student.id: existingAttendance
                .where((a) => a.studentId == student.id)
                .map((a) => a.isPresent)
                .firstWhere((isPresent) => true, orElse: () => false),
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMMM dd, yyyy').format(_selectedDate);
      });
      await _loadStudents();
    }
  }

  bool _isTimeValid() {
    final now = DateTime.now();
    // Allow marking attendance from 6 AM to 6 PM
    return now.hour >= 6 && now.hour < 18;
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _saveAttendance() async {
    if (_attendanceService == null) return;
    if (_isCollegeLeave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark attendance on college leave day'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_isTimeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance marking is closed for today'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      // First check if attendance already exists for today
      final existingAttendance = await _attendanceService!.getAttendanceByDate(
        _selectedDate,
        section: _selectedSection,
      );
      final attendanceList = _students.map((student) {
        return Attendance(
          id: '${student.id}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
          studentId: student.id,
          studentName: student.name,
          regNo: student.regNo,
          department: _selectedDepartment,
          year: _selectedYear,
          section: _selectedSection,
          date: _selectedDate,
          isPresent: _attendance[student.id] ?? false,
        );
      }).toList();

      await _attendanceService!.markAttendance(attendanceList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate attendance statistics
    int totalStudents = _students.length;
    int presentCount = _attendance.values.where((present) => present).length;
    int absentCount = totalStudents - presentCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Attendance',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _isTimeValid() ? 'Marking hours: 6 AM to 6 PM' : 'Attendance marking closed',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _isTimeValid() ? Colors.white70 : Colors.red[100],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveAttendance,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: Column(
                children: [
                  // Date Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue[700],
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dateController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // College Leave Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue[700],
                    child: SwitchListTile(
                      title: Text(
                        'College Leave Day',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        _isCollegeLeave
                            ? 'This day is marked as a college leave'
                            : 'Regular working day',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      value: _isCollegeLeave,
                      onChanged: (value) => _toggleCollegeLeave(),
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                    ),
                  ),
                  // Department, Year, Section Selectors
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue[700],
                    child: Column(
                      children: [
                        // Department Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedDepartment,
                            isExpanded: true,
                            dropdownColor: Colors.blue[700],
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                            underline: const SizedBox(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            items: departments
                                .map((dept) => DropdownMenuItem<String>(
                                      value: dept,
                                      child: Text(dept),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDepartment = value;
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Year Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedYear,
                            isExpanded: true,
                            dropdownColor: Colors.blue[700],
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                            underline: const SizedBox(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            items: years
                                .map((year) => DropdownMenuItem<String>(
                                      value: year,
                                      child: Text(year),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedYear = value;
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Section Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedSection,
                            isExpanded: true,
                            dropdownColor: Colors.blue[700],
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                            underline: const SizedBox(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            items: sections
                                .map((section) => DropdownMenuItem<String>(
                                      value: section,
                                      child: Text(section),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSection = value;
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Attendance Summary Card
                  if (_students.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Total Students', _students.length, Colors.blue),
                          _buildStatColumn('Present', presentCount, Colors.green),
                          _buildStatColumn('Absent', absentCount, Colors.red),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _students.isEmpty
                      ? Center(
                          child: Text(
                            'No students found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            bool isPresent = _attendance[student.id] ?? false;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isPresent ? Colors.green[100] : Colors.red[100],
                                  child: Text(
                                    student.name[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isPresent ? Colors.green[700] : Colors.red[700],
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  student.regNo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Switch(
                                  value: _attendance[student.id] ?? false,
                                  onChanged: (_isTimeValid() && !_isCollegeLeave)
                                      ? (value) {
                                          setState(() {
                                            _attendance[student.id] = value;
                                          });
                                        }
                                      : null,
                                  activeColor: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}
