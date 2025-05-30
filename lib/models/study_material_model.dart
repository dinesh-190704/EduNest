class StudyMaterial {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String department;
  final String category; // 'Lecture Notes' or 'Question Bank'
  final String subject;
  final String uploadDate;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.department,
    required this.category,
    required this.subject,
    required this.uploadDate,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      fileUrl: json['fileUrl'] as String,
      department: json['department'] as String,
      category: json['category'] as String,
      subject: json['subject'] as String,
      uploadDate: json['uploadDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'department': department,
      'category': category,
      'subject': subject,
      'uploadDate': uploadDate,
    };
  }
}
