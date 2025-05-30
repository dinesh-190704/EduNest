import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import 'chat_room_screen.dart';
import 'package:uuid/uuid.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final ChatService _chatService = ChatService();
  final _uuid = Uuid();

  void _createNewChatRoom() {
    showDialog(
      context: context,
      builder: (context) {
        String roomName = '';
        return AlertDialog(
          title: Text(
            'Create New Chat Room',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Room Name',
              hintText: 'Enter room name',
            ),
            onChanged: (value) => roomName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (roomName.isNotEmpty) {
                  // TODO: Get actual admin ID from auth service
                  final adminId = 'admin123';
                  await _chatService.createChatRoom(
                    roomName,
                    [adminId],
                    adminId,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

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
        backgroundColor: Colors.teal[600],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChatRoom,
        backgroundColor: Colors.teal[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        // TODO: Get actual admin ID from auth service
        stream: _chatService.getChatRooms('admin123'),
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
              child: Text(
                'No chat rooms yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: const Icon(
                      Icons.chat,
                      color: Colors.teal,
                    ),
                  ),
                  title: Text(
                    room.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: room.lastMessage != null
                      ? Text(
                          room.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Text(
                    room.lastMessageTime != null
                        ? _formatTime(room.lastMessageTime!)
                        : '',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatRoom: room,
                          isAdmin: true,
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
