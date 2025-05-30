import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../admin/chat_room_screen.dart';

class StudentChatScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentChatScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat Rooms',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getChatRooms(widget.studentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chatRooms = snapshot.data!;
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chat rooms available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your teachers will add you to chat rooms',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(
                      Icons.chat,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    room.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room.lastMessage != null)
                        Text(
                          room.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        room.allowStudentMessages
                            ? 'You can send messages'
                            : 'Only teachers can send messages',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: room.allowStudentMessages
                              ? Colors.green[600]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: room.lastMessageTime != null
                      ? Text(
                          _formatTime(room.lastMessageTime!),
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatRoom: room,
                          isAdmin: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
