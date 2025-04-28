// message_bubble.dart
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:talky/message/message_status_icon.dart';

import 'message_bubble_content.dart'; // Importing the content builder
import 'reply_preview.dart'; // Import the reply preview widget

class MessageBubble extends StatefulWidget {
  final String message;
  final String senderId;
  final String currentUserId;
  final String status;
  final DateTime timestamp;
  final String? replyToMessage;
  final String? replyToMessageId;
  final String? senderName;
  final String messageId;
  final String? replyToSenderName;
  final String? replyToSenderPhoneNumber;
  final void Function(String message, String messageId)? onSwipeReply;
  final void Function(String messageId)? onDelete;
  final bool isSelected;
  final VoidCallback onLongPressSelect;
  final VoidCallback onTapSelect;
  final String? audioUrl;
  final String? mediaUrl;
  final String type;
  final PlayerController? playerController;
  final bool isSending;
  final String? mediaFilePath;

  const MessageBubble({
    super.key,
    required this.message,
    this.mediaUrl,
    required this.senderId,
    required this.currentUserId,
    required this.status,
    required this.timestamp,
    this.replyToMessage,
    this.replyToMessageId,
    this.senderName,
    required this.messageId,
    this.replyToSenderName,
    this.replyToSenderPhoneNumber,
    this.onSwipeReply,
    this.onDelete,
    required this.isSelected,
    required this.onLongPressSelect,
    required this.onTapSelect,
    this.audioUrl,
    this.type = 'text',
    this.playerController,
    this.mediaFilePath,
    this.isSending = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _hapticFired = false;
  bool _replyTriggered = false;

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.senderId == widget.currentUserId;
    final String formattedTime = DateFormat('HH:mm').format(widget.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Reply preview section
          if (widget.replyToMessage != null)
            ReplyPreview(
              replyToSenderName: widget.replyToSenderName,
              replyToMessage: widget.replyToMessage,
              isMe: isMe,
            ),

          GestureDetector(
            onLongPress: widget.onLongPressSelect,
            onTap: widget.onTapSelect,
            onHorizontalDragUpdate: (details) {
              if (widget.isSelected) return; // Block swipe if selected

              setState(() {
                _dragOffset += details.primaryDelta!;
                if (_dragOffset > 30 && !_hapticFired) {
                  HapticFeedback.mediumImpact();
                  _hapticFired = true;
                }

                if (_dragOffset > 60 && !_replyTriggered) {
                  _replyTriggered = true;
                  widget.onSwipeReply?.call(widget.message, widget.messageId);
                }
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragOffset = 0;
                _hapticFired = false;
                _replyTriggered = false;
              });
            },
            child: Stack(
              children: [
                // Show reply icon on swipe
                if (_dragOffset > 10)
                  Positioned(
                    left: isMe ? null : 0,
                    right: isMe ? 0 : null,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: 1,
                      child: Icon(
                        Icons.reply,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color:
                        widget.isSelected
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.translationValues(_dragOffset, 0, 0),
                    child: MessageBubbleContent(
                      message: widget.message,
                      senderId: widget.senderId,
                      currentUserId: widget.currentUserId,
                      status: widget.status,
                      timestamp: widget.timestamp,
                      type: widget.type,
                      mediaUrl: widget.mediaUrl,
                      audioUrl: widget.audioUrl,
                      isSending: widget.isSending,
                      mediaFilePath: widget.mediaFilePath,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 2),

          // Timestamp + status
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.white70,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                MessageStatusIcon(
                  senderId: widget.senderId,
                  currentUserId: widget.currentUserId,
                  status: widget.status,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
