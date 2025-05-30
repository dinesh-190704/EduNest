class Student {
  final String id;
  final String name;
  final String regNo;
  final String department;
  final String year;
  final String section;
  final String imageUrl;

  Student({
    required this.id,
    required this.name,
    required this.regNo,
    required this.department,
    required this.year,
    required this.section,
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'regNo': regNo,
      'department': department,
      'year': year,
      'section': section,
      'imageUrl': imageUrl,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      regNo: json['regNo'],
      department: json['department'],
      year: json['year'],
      section: json['section'],
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
