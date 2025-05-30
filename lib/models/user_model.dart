class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'student'
  final String name;
  final String? profileImageUrl;
  // Student specific fields
  final String? department;
  final String? year;
  final String? section;
  final String? studentId;
  // Admin specific fields
  final String? staffId;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.profileImageUrl,
    this.department,
    this.year,
    this.section,
    this.studentId,
    this.staffId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      name: map['name'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      department: map['department'],
      year: map['year'],
      section: map['section'],
      studentId: map['studentId'],
      staffId: map['staffId'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? profileImageUrl,
    String? department,
    String? year,
    String? section,
    String? studentId,
    String? staffId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      department: department ?? this.department,
      year: year ?? this.year,
      section: section ?? this.section,
      studentId: studentId ?? this.studentId,
      staffId: staffId ?? this.staffId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'department': department,
      'year': year,
      'section': section,
      'studentId': studentId,
      'staffId': staffId,
    };
  }
}
