class Assignment {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final String description;
  final DateTime createdAt;
  final List<AssignmentSubmission> submissions;

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.description,
    required this.createdAt,
    this.submissions = const [],
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      dueDate: DateTime.parse(map['dueDate']),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      submissions: (map['submissions'] as List?)
          ?.map((e) => AssignmentSubmission.fromMap(e))
          .toList() ?? [],
    );
  }
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String fileUrl;
  final DateTime submittedAt;
  final double? marks;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.fileUrl,
    required this.submittedAt,
    this.marks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'submittedAt': submittedAt.toIso8601String(),
      'marks': marks,
    };
  }

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id'],
      assignmentId: map['assignmentId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      fileUrl: map['fileUrl'],
      submittedAt: DateTime.parse(map['submittedAt']),
      marks: map['marks']?.toDouble(),
    );
  }
}
