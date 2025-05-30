class Resource {
  final String id;
  final String title;
  final String fileUrl;
  final String fileType;
  final String uploadDate;
  final String category; // 'notes' or 'question_bank'
  final String subject;
  final int semester;
  final String description;

  Resource({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.uploadDate,
    required this.category,
    required this.subject,
    required this.semester,
    required this.description,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      title: json['title'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      uploadDate: json['upload_date'],
      category: json['category'],
      subject: json['subject'],
      semester: json['semester'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_url': fileUrl,
      'file_type': fileType,
      'upload_date': uploadDate,
      'category': category,
      'subject': subject,
      'semester': semester,
      'description': description,
    };
  }
}
