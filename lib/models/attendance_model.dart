import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final String regNo;
  final String department;
  final String year;
  final String section;
  final DateTime date;
  final bool isPresent;

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.regNo,
    required this.department,
    required this.year,
    required this.section,
    required this.date,
    required this.isPresent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'regNo': regNo,
      'department': department,
      'year': year,
      'section': section,
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      regNo: json['regNo'],
      department: json['department'],
      year: json['year'],
      section: json['section'],
      date: (json['date'] as Timestamp).toDate(),
      isPresent: json['isPresent'],
    );
  }
}

class AttendanceReport {
  final String studentId;
  final String studentName;
  final String regNo;
  final int totalDays;
  final int presentDays;
  final double percentage;
  final List<DateTime> absentDates;

  AttendanceReport({
    required this.studentId,
    required this.studentName,
    required this.regNo,
    required this.totalDays,
    required this.presentDays,
    required this.percentage,
    required this.absentDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'regNo': regNo,
      'totalDays': totalDays,
      'presentDays': presentDays,
      'percentage': percentage,
      'absentDates': absentDates.map((date) => Timestamp.fromDate(date)).toList(),
    };
  }

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      studentId: json['studentId'],
      studentName: json['studentName'],
      regNo: json['regNo'],
      totalDays: json['totalDays'],
      presentDays: json['presentDays'],
      percentage: json['percentage'],
      absentDates: (json['absentDates'] as List)
          .map((date) => (date as Timestamp).toDate())
          .toList(),
    );
  }
}
