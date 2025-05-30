import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  late AttendanceService _attendanceService;
  List<AttendanceReport> _reports = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedDepartment = '';
  String _selectedYear = '';
  String _selectedSection = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _attendanceService = AttendanceService();
    _selectedDepartment = 'Information Technology';
    _selectedYear = '1st Year';
    _selectedSection = 'A';
    await _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final students = await _attendanceService.getStudentsByClass(
        department: _selectedDepartment,
        year: _selectedYear,
        section: _selectedSection,
      );

      final reports = await Future.wait(
        students.map((student) async {
          final attendance = await _attendanceService.getStudentAttendance(student.id);
          final attendanceInRange = attendance.where((a) =>
              a.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              a.date.isBefore(_endDate.add(const Duration(days: 1))));

          final totalDays = _endDate.difference(_startDate).inDays + 1;
          final presentDays = attendanceInRange.where((a) => a.isPresent).length;
          final percentage = (presentDays / totalDays) * 100;

          return AttendanceReport(
            studentId: student.id,
            studentName: student.name,
            regNo: student.regNo,
            totalDays: totalDays,
            presentDays: presentDays,
            percentage: percentage,
            absentDates: attendanceInRange
                .where((a) => !a.isPresent)
                .map((a) => a.date)
                .toList(),
          );
        }),
      );

      if (mounted) {
        setState(() => _reports = reports);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Report',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.date_range),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                        items: _attendanceService
                            .getDepartments()
                            .map((dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedDepartment = value);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        items: _attendanceService
                            .getYears()
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedYear = value);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                        ),
                        items: _attendanceService
                            .getSections()
                            .map((section) => DropdownMenuItem(
                                  value: section,
                                  child: Text(section),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSection = value);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? Center(
                        child: Text(
                          'No attendance records found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final attendanceColor =
                              _getAttendanceColor(report.percentage);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(
                                report.studentName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                report.regNo,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: attendanceColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: attendanceColor,
                                  ),
                                ),
                                child: Text(
                                  '${report.percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                    color: attendanceColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Days: ${report.totalDays}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Present Days: ${report.presentDays}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Absent Days: ${report.absentDates.length}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (report.absentDates.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Absent Dates:',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: report.absentDates
                                              .map((date) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      DateFormat('MMM d')
                                                          .format(date),
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
