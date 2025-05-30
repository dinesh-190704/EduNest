class ChatSettings {
  final bool allowStudentMessages;
  final DateTime lastUpdated;

  ChatSettings({
    required this.allowStudentMessages,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowStudentMessages': allowStudentMessages,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      allowStudentMessages: map['allowStudentMessages'] ?? false,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
