import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeLeave {
  final String id;
  final DateTime date;
  final String reason;

  CollegeLeave({
    required this.id,
    required this.date,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'reason': reason,
    };
  }

  factory CollegeLeave.fromJson(Map<String, dynamic> json) {
    return CollegeLeave(
      id: json['id'],
      date: (json['date'] as Timestamp).toDate(),
      reason: json['reason'],
    );
  }
}
