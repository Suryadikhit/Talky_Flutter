import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:talky/controller/chat/typing_controller.dart';

class ChatTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String otherUserId; // 👈 Add this
  final String otherUserName;
  final String? profileImageUrl;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoCallPressed;
  final String? statusText;
  final String chatId;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback? onDeleteSelectedMessages;

  const ChatTopBar({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.profileImageUrl,
    this.onCallPressed,
    this.onVideoCallPressed,
    this.statusText,
    required this.chatId,
    required this.isSelectionMode,
    required this.selectedCount,
    this.onDeleteSelectedMessages,
  });

  Stream<DatabaseEvent> getPresenceStream() {
    return FirebaseDatabase.instance.ref('status/$otherUserId').onValue;
  }

  String _formatLastSeen(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formatted = DateFormat('h:mm a').format(dateTime);
    return 'Last seen at $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: const Color(0xFF272A30),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 55,
            bottom: 5,
          ),
          child:
              isSelectionMode
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$selectedCount selected",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: onDeleteSelectedMessages,
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      // Profile Image or Initials
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage:
                            profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null,
                        child:
                            profileImageUrl == null
                                ? Text(
                                  otherUserName.isNotEmpty
                                      ? otherUserName[0].toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                                : null,
                      ),

                      const SizedBox(width: 12),

                      // Username & Status with StreamBuilder
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUserName,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFE7E1EB),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            /// ✅ TYPING INDICATOR
                            StreamBuilder<bool>(
                              stream: Get.find<TypingController>()
                                  .getTypingStatus(chatId, otherUserId),
                              builder: (context, typingSnapshot) {
                                if (typingSnapshot.hasData &&
                                    typingSnapshot.data == true) {
                                  return const Text(
                                    'Typing...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueAccent,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  );
                                }

                                /// ✅ Only show presence if not typing
                                return StreamBuilder<DatabaseEvent>(
                                  stream: getPresenceStream(),
                                  // 👈 Your existing presence stream
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data!.snapshot.value != null) {
                                      final data = Map<String, dynamic>.from(
                                        snapshot.data!.snapshot.value as Map,
                                      );
                                      final isOnline = data['isOnline'] == true;
                                      final lastSeen = data['lastSeen'] as int?;

                                      if (isOnline) {
                                        return const Text(
                                          'Online',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        );
                                      } else if (lastSeen != null) {
                                        return Text(
                                          _formatLastSeen(lastSeen),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Call & Video Call Icons
                      IconButton(
                        icon: const Icon(Icons.call),
                        color: const Color(0xFFE7E1EB),
                        onPressed: onCallPressed,
                      ),
                      IconButton(
                        icon: const Icon(Icons.videocam),
                        color: const Color(0xFFE7E1EB),
                        onPressed: onVideoCallPressed,
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(78);
}
