import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../message/message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String senderId;
  final String currentUserId;
  final String status;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.senderId,
    required this.currentUserId,
    required this.status,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = senderId == currentUserId;
    final String formattedTime = DateFormat('HH.mm').format(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          BubbleSpecialThree(
            text: message,
            color: isMe ? const Color(0xFF305EF2) : Colors.grey.shade300,
            tail: true,
            isSender: isMe,
            textStyle: TextStyle(
              color: isMe ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                MessageStatusIcon(
                  senderId: senderId,
                  currentUserId: currentUserId,
                  status: status,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
