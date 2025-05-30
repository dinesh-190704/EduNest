import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentName;
  final String department;
  final String regNo;
  final String year;
  final String section;

  const StudentAttendanceScreen({
    Key? key,
    required this.studentName,
    required this.department,
    required this.regNo,
    required this.year,
    required this.section,
  }) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final TextEditingController _dateController = TextEditingController();
  AttendanceService? _attendanceService;
  DateTime _selectedDate = DateTime.now();
  List<Student> _classmates = [];
  Map<String, bool> _attendance = {};
  bool _isLoading = true;
  String _errorMessage = '';
  double _monthlyPercentage = 0.0;
  List<Attendance> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    print('StudentAttendanceScreen - initState');
    print('Student Info - RegNo: ${widget.regNo}, Department: ${widget.department}, Year: ${widget.year}, Section: ${widget.section}');
    _dateController.text = DateFormat('MMMM dd, yyyy').format(_selectedDate);
    _initializeService();
  }

  Future<void> _initializeService() async {
    print('Initializing attendance service...');
    setState(() {
      _attendanceService = AttendanceService();
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Loading data for student: ${widget.regNo}');
      print('Department: ${widget.department}, Year: ${widget.year}, Section: ${widget.section}');
      
      // Load classmates
      final students = await _attendanceService!.getStudentsByClass(
        department: widget.department,
        year: widget.year,
        section: widget.section,
      );
      print('Found ${students.length} classmates');
      
      // Load today's attendance
      final todayAttendance = await _attendanceService!.getAttendanceByDate(
        _selectedDate,
        section: widget.section,
      );
      print('Found ${todayAttendance.length} attendance records for today');

      // Load attendance history
      print('Loading attendance history for student: ${widget.regNo}');
      final attendanceHistory = await _attendanceService!.getStudentAttendance(
        widget.regNo
      );
      print('Found ${attendanceHistory.length} attendance history records');
      
      setState(() {
        _classmates = students;
        _attendance = {
          for (var attendance in todayAttendance)
            attendance.studentId: attendance.isPresent
        };
        _attendanceHistory = attendanceHistory;
        _isLoading = false;
      });

      print('Attendance data loaded successfully');
      print('Attendance history records: ${_attendanceHistory.length}');
      if (_attendanceHistory.isNotEmpty) {
        print('First attendance record: ${_attendanceHistory.first.date}, isPresent: ${_attendanceHistory.first.isPresent}');
      }
    } catch (e) {
      print('Error in _initializeService: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      await _initializeService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Attendance',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.department} - ${widget.year} ${widget.section}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage),
                )
              : RefreshIndicator(
                  onRefresh: _initializeService,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dateController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Select Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => _selectDate(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Attendance History',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_attendanceHistory.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No attendance records found',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ..._attendanceHistory
                                    .take(5)
                                    .map((attendance) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            attendance.isPresent
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: attendance.isPresent
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          title: Text(
                                            DateFormat('MMMM dd, yyyy')
                                                .format(attendance.date),
                                            style: GoogleFonts.poppins(),
                                          ),
                                          trailing: Text(
                                            attendance.isPresent
                                                ? 'Present'
                                                : 'Absent',
                                            style: GoogleFonts.poppins(
                                              color: attendance.isPresent
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
    );
  }
}
