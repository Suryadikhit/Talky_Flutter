import 'package:flutter/material.dart';

class MessageStatusIcon extends StatelessWidget {
  final String senderId;
  final String currentUserId;
  final String status;
  final double size;

  const MessageStatusIcon({
    super.key,
    required this.senderId,
    required this.currentUserId,
    required this.status,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    // Only show ticks if the message was sent by the current user
    if (senderId != currentUserId) return const SizedBox();

    Color color;
    IconData iconData;

    switch (status) {
      case 'delivered':
        color = Colors.grey;
        iconData = Icons.done_all;
        break;
      case 'seen':
        color = Colors.green;
        iconData = Icons.done_all;
        break;
      case 'sent':
      default:
        color = Colors.grey;
        iconData = Icons.check;
        break;
    }

    return Icon(iconData, size: size, color: color);
  }
}
