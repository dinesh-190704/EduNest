import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  // Create a new chat room
  Future<ChatRoom> createChatRoom(String name, List<String> participants, String adminId) async {
    final chatRoom = ChatRoom(
      id: _uuid.v4(),
      name: name,
      participants: participants,
      isActive: true,
      allowStudentMessages: false,
      createdAt: DateTime.now(),
      createdBy: adminId,
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoom.id)
        .set(chatRoom.toMap());

    return chatRoom;
  }

  // Get all chat rooms for a user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          .toList();
    });
  }

  // Get messages for a specific chat room
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chatMessages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    });
  }

  // Send a message
  Future<void> sendMessage(ChatMessage message) async {
    await _firestore
        .collection('chatMessages')
        .doc(message.id)
        .set(message.toMap());

    // Update the chat room's last message
    await _firestore.collection('chatRooms').doc(message.chatRoomId).update({
      'lastMessage': message.content,
      'lastMessageTime': message.timestamp.toIso8601String(),
    });
  }

  // Toggle student message permission
  Future<void> toggleStudentMessages(String chatRoomId, bool allowStudentMessages) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .update({'allowStudentMessages': allowStudentMessages});
  }

  // Add participants to a chat room
  Future<void> addParticipants(String chatRoomId, List<String> newParticipants) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'participants': FieldValue.arrayUnion(newParticipants),
    });
  }

  // Remove participants from a chat room
  Future<void> removeParticipants(String chatRoomId, List<String> participantsToRemove) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'participants': FieldValue.arrayRemove(participantsToRemove),
    });
  }

  // Delete a chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    // Delete the chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).delete();

    // Delete all messages in the chat room
    final messages = await _firestore
        .collection('chatMessages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .get();

    for (var message in messages.docs) {
      await message.reference.delete();
    }
  }

  // Delete a specific message
  Future<void> deleteMessage(String messageId, String chatRoomId) async {
    // Delete the message
    await _firestore.collection('chatMessages').doc(messageId).delete();

    // Update the chat room's last message if needed
    final lastMessages = await _firestore
        .collection('chatMessages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastMessages.docs.isNotEmpty) {
      final lastMessage = ChatMessage.fromMap(lastMessages.docs.first.data());
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': lastMessage.content,
        'lastMessageTime': lastMessage.timestamp.toIso8601String(),
      });
    } else {
      // No messages left, clear the last message
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': null,
        'lastMessageTime': null,
      });
    }
  }
}
