class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String chatRoomId;
  final bool isAdmin;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.chatRoomId,
    required this.isAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'chatRoomId': chatRoomId,
      'isAdmin': isAdmin,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      chatRoomId: map['chatRoomId'],
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
