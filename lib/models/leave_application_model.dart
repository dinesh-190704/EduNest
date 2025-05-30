class LeaveApplication {
  final String id;
  final String studentName;
  final String regNo;
  final String department;
  final String year;
  final String section;
  final String reason;
  final String description;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime appliedDate;
  String status; // 'pending', 'approved', 'rejected'
  String? adminRemarks;

  LeaveApplication({
    required this.id,
    required this.studentName,
    required this.regNo,
    required this.department,
    required this.year,
    required this.section,
    required this.reason,
    required this.description,
    required this.fromDate,
    required this.toDate,
    required this.appliedDate,
    this.status = 'pending',
    this.adminRemarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'regNo': regNo,
      'department': department,
      'year': year,
      'section': section,
      'reason': reason,
      'description': description,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'appliedDate': appliedDate.toIso8601String(),
      'status': status,
      'adminRemarks': adminRemarks,
    };
  }

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'],
      studentName: json['studentName'],
      regNo: json['regNo'],
      department: json['department'],
      year: json['year'],
      section: json['section'],
      reason: json['reason'],
      description: json['description'],
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      appliedDate: DateTime.parse(json['appliedDate']),
      status: json['status'],
      adminRemarks: json['adminRemarks'],
    );
  }
}
