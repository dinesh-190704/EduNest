import 'package:cloud_firestore/cloud_firestore.dart';

class StudentResult {
  final String regNo;
  final String name;
  final Map<String, String> subjects;
  final String total;
  final String department;
  final String year;
  final String className;
  final DateTime uploadedAt;
  final String exam;
  String status;
  DateTime get date => uploadedAt;
  Map<String, double> get marks {
    return subjects.map((key, value) => MapEntry(key, double.tryParse(value) ?? 0.0));
  }

  StudentResult({
    required this.regNo,
    required this.name,
    required this.subjects,
    required this.total,
    required this.department,
    required this.year,
    required this.className,
    required this.uploadedAt,
    this.exam = 'Semester Exam',
    this.status = 'Pending',
  });

  factory StudentResult.fromMap(Map<String, dynamic> map) {
    // Extract subject marks from the map
    Map<String, String> subjectMarks = {};
    map.forEach((key, value) {
      if (!['regNo', 'name', 'total', 'department', 'year', 'className', 'uploadedAt', 'exam', 'status'].contains(key)) {
        subjectMarks[key] = value.toString();
      }
    });

    return StudentResult(
      regNo: map['regNo'] ?? '',
      name: map['name'] ?? '',
      subjects: subjectMarks,
      total: map['total']?.toString() ?? '0',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      className: map['className'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exam: map['exam'] ?? 'Semester Exam',
      status: map['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'regNo': regNo,
      'name': name,
      'total': total,
      'department': department,
      'year': year,
      'className': className,
      'uploadedAt': FieldValue.serverTimestamp(),
      'exam': exam,
      'status': status,
    };

    // Add subject marks to the map
    subjects.forEach((key, value) {
      data[key] = value;
    });

    return data;
  }
}

class ResultMetadata {
  final String department;
  final String year;
  final String className;
  final int totalStudents;
  final DateTime uploadedAt;
  final List<String> subjects;

  ResultMetadata({
    required this.department,
    required this.year,
    required this.className,
    required this.totalStudents,
    required this.uploadedAt,
    required this.subjects,
  });

  factory ResultMetadata.fromMap(Map<String, dynamic> map) {
    return ResultMetadata(
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      className: map['className'] ?? '',
      totalStudents: map['totalStudents'] ?? 0,
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subjects: List<String>.from(map['subjects'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'year': year,
      'className': className,
      'totalStudents': totalStudents,
      'uploadedAt': FieldValue.serverTimestamp(),
      'subjects': subjects,
    };
  }
}

class PassStats {
  final int totalStudents;
  final int passedStudents;
  final int failedStudents;
  final Map<String, double> subjectWisePassPercent;

  double get passPercentage => totalStudents > 0 
      ? (passedStudents / totalStudents) * 100 
      : 0.0;

  PassStats({
    required this.totalStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.subjectWisePassPercent,
  });

  factory PassStats.fromMap(Map<String, dynamic> map) {
    return PassStats(
      totalStudents: map['totalStudents'] ?? 0,
      passedStudents: map['passedStudents'] ?? 0,
      failedStudents: map['failedStudents'] ?? 0,
      subjectWisePassPercent: Map<String, double>.from(map['subjectWisePassPercent'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalStudents': totalStudents,
      'passedStudents': passedStudents,
      'failedStudents': failedStudents,
      'subjectWisePassPercent': subjectWisePassPercent,
    };
  }
}
