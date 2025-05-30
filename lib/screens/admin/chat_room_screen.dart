import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final bool isAdmin;

  const ChatRoomScreen({
    Key? key,
    required this.chatRoom,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final _uuid = Uuid();
  bool _isSettingsOpen = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // TODO: Get actual user data from auth service
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: 'admin123',
      senderName: 'Admin',
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      chatRoomId: widget.chatRoom.id,
      isAdmin: true,
    );

    await _chatService.sendMessage(message);
    _messageController.clear();
  }

  void _toggleStudentMessages() async {
    await _chatService.toggleStudentMessages(
      widget.chatRoom.id,
      !widget.chatRoom.allowStudentMessages,
    );
  }

  void _showAddParticipantsDialog() {
    // TODO: Implement participant selection
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Participants'),
          content: const Text('Participant selection to be implemented'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (widget.isAdmin)
              Text(
                widget.chatRoom.allowStudentMessages
                    ? 'Students can message'
                    : 'Only admin can message',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.teal[600],
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  _isSettingsOpen = !_isSettingsOpen;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSettingsOpen && widget.isAdmin)
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Allow Student Messages'),
                    value: widget.chatRoom.allowStudentMessages,
                    onChanged: (_) => _toggleStudentMessages(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Add Participants'),
                    onTap: _showAddParticipantsDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Delete Chat Room',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Chat Room'),
                          content: const Text(
                            'Are you sure you want to delete this chat room? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _chatService.deleteChatRoom(widget.chatRoom.id);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getChatMessages(widget.chatRoom.id),
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

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == 'admin123'; // TODO: Get from auth

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () {
                            // Allow users to delete their own messages
                            if (isMe) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Message',
                                      style: GoogleFonts.poppins()),
                                  content: Text(
                                      'Are you sure you want to delete this message?',
                                      style: GoogleFonts.poppins()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel',
                                          style: GoogleFonts.poppins()),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await _chatService.deleteMessage(
                                            message.id, widget.chatRoom.id);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.poppins(
                                            color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.teal[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.senderName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isMe ? Colors.teal[700] : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.content,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.timestamp),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (widget.isAdmin ||
              (widget.chatRoom.allowStudentMessages && !widget.isAdmin))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.teal[600],
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
