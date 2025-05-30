class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final bool isActive;
  final bool allowStudentMessages;
  final DateTime createdAt;
  final String createdBy;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    required this.isActive,
    required this.allowStudentMessages,
    required this.createdAt,
    required this.createdBy,
    this.lastMessage,
    this.lastMessageTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'isActive': isActive,
      'allowStudentMessages': allowStudentMessages,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'],
      name: map['name'],
      participants: List<String>.from(map['participants']),
      isActive: map['isActive'] ?? true,
      allowStudentMessages: map['allowStudentMessages'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'],
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.parse(map['lastMessageTime'])
          : null,
    );
  }

  ChatRoom copyWith({
    String? name,
    List<String>? participants,
    bool? isActive,
    bool? allowStudentMessages,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return ChatRoom(
      id: id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      isActive: isActive ?? this.isActive,
      allowStudentMessages: allowStudentMessages ?? this.allowStudentMessages,
      createdAt: createdAt,
      createdBy: createdBy,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
