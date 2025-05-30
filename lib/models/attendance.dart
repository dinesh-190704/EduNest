class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final String department;
  final String year;
  final String className;
  final DateTime date;
  final bool isPresent;
  final String takenBy; // admin ID who took attendance

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.year,
    required this.className,
    required this.date,
    required this.isPresent,
    required this.takenBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'department': department,
      'year': year,
      'className': className,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'takenBy': takenBy,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      department: map['department'],
      year: map['year'],
      className: map['className'],
      date: DateTime.parse(map['date']),
      isPresent: map['isPresent'],
      takenBy: map['takenBy'],
    );
  }
}
