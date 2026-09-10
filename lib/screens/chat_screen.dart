import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final Stream<List<Map<String, dynamic>>> messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', widget.bookingId)
        .order('created_at', ascending: true);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Row(
          children: [
            AppAvatar(url: widget.receiverAvatar, fallbackId: widget.receiverId, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Connected for Booking', 
                    style: TextStyle(
                      fontSize: 10, 
                      color: isDark ? AppColors.neonGreen : Colors.green, 
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hi!', 
                      style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == user.id;
                    return _ChatMessage(
                      text: msg['text'], 
                      isMe: isMe, 
                      isDark: isDark,
                      time: DateFormat('HH:mm').format(DateTime.parse(msg['created_at'])),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(isDark, user.id),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, String senderId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100], 
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type a message...', 
                    hintStyle: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _sendMessage(senderId),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neonGreen : AppColors.primary, 
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded, 
                  color: isDark ? Colors.black : Colors.white, 
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String senderId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'booking_id': widget.bookingId,
        'sender_id': senderId,
        'receiver_id': widget.receiverId,
        'text': text,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isDark;
  final String time;

  const _ChatMessage({required this.text, required this.isMe, required this.isDark, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe 
                ? (isDark ? AppColors.neonGreen : AppColors.primary) 
                : (isDark ? AppColors.darkSurface : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
              ),
              border: isMe ? null : Border.all(color: isDark ? Colors.white10 : AppColors.divider),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe 
                  ? (isDark ? Colors.black : Colors.white) 
                  : (isDark ? Colors.white : AppColors.textDark),
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            time, 
            style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkGrey : AppColors.grey),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
