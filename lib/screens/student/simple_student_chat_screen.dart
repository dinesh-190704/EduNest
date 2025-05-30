import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_message.dart';
import '../../models/chat_settings.dart';
import '../../services/simple_chat_service.dart';

class SimpleStudentChatScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const SimpleStudentChatScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<SimpleStudentChatScreen> createState() => _SimpleStudentChatScreenState();
}

class _SimpleStudentChatScreenState extends State<SimpleStudentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SimpleChatService _chatService = SimpleChatService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _chatService.sendMessage(
      senderId: widget.studentId,
      senderName: widget.studentName,
      content: _messageController.text.trim(),
      isAdmin: false,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
      ),
      body: StreamBuilder<ChatSettings>(
        stream: _chatService.getChatSettings(),
        builder: (context, settingsSnapshot) {
          if (!settingsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsSnapshot.data!;

          return Column(
            children: [
              Container(
                color: settings.allowStudentMessages
                    ? Colors.green[100]
                    : Colors.orange[100],
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      settings.allowStudentMessages
                          ? Icons.chat
                          : Icons.block,
                      color: settings.allowStudentMessages
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      settings.allowStudentMessages
                          ? 'You can send messages'
                          : 'Only teachers can send messages now',
                      style: GoogleFonts.poppins(
                        color: settings.allowStudentMessages
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessages(),
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
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == widget.studentId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        message.senderName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: message.isAdmin
                                              ? Colors.teal[700]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      if (message.isAdmin)
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal[700],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
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
                        );
                      },
                    );
                  },
                ),
              ),
              if (settings.allowStudentMessages)
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
                        backgroundColor: Colors.blue[700],
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
