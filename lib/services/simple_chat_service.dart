import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_settings.dart';
import 'package:uuid/uuid.dart';

class SimpleChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  // Get chat settings
  Stream<ChatSettings> getChatSettings() {
    return _firestore
        .collection('chatSettings')
        .doc('global')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        // Create default settings if they don't exist
        final defaultSettings = ChatSettings(
          allowStudentMessages: false,
          lastUpdated: DateTime.now(),
        );
        doc.reference.set(defaultSettings.toMap());
        return defaultSettings;
      }
      return ChatSettings.fromMap(doc.data()!);
    });
  }

  // Toggle student messages permission
  Future<void> toggleStudentMessages(bool allowStudentMessages) async {
    await _firestore.collection('chatSettings').doc('global').set({
      'allowStudentMessages': allowStudentMessages,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // Get all messages
  Stream<List<ChatMessage>> getMessages() {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    });
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String content,
    required bool isAdmin,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      chatRoomId: 'global', // Single chat room
      isAdmin: isAdmin,
    );

    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }
}
