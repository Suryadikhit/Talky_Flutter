// lib/screens/chats/chat_list_tile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talky/common_widgets/timestamp_formatter.dart';
import 'package:talky/controller/chat/message_controller.dart';
import 'package:talky/message/message_status_icon.dart';
import 'package:talky/screens/chat/chat_screen.dart';

import '../../../controller/chat/chat_controller.dart';

class ChatListTile extends StatelessWidget {
  final String chatId;
  final Map<String, String> phoneToNameMap;

  const ChatListTile({
    super.key,
    required this.chatId,
    required this.phoneToNameMap,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserId = Get.find<ChatController>().currentUserId;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
          return const SizedBox();
        }

        final chat = chatSnapshot.data!;
        final List<dynamic> participants = chat['participants'];

        final String otherUserId =
            participants.length == 1
                ? currentUserId
                : participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => currentUserId,
                );

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .where('receiverId', isEqualTo: currentUserId)
                  .where('status', whereIn: ['sent', 'delivered'])
                  .snapshots(),
          builder: (context, unreadSnapshot) {
            final int unreadCount = unreadSnapshot.data?.docs.length ?? 0;

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();

                final userData = userSnapshot.data!;
                final String phoneNumber = userData['number'] ?? 'Unknown';
                final String otherUserName =
                    phoneToNameMap[phoneNumber] ?? phoneNumber;

                final Timestamp? lastMessageTime = chat['lastMessageTime'];
                final String formattedTime =
                    lastMessageTime != null
                        ? formatTimestamp(lastMessageTime)
                        : '';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            (userData['profileImageUrl']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false)
                                ? NetworkImage(userData['profileImageUrl'])
                                : null,
                        child:
                            (userData['profileImageUrl']?.toString().isEmpty ??
                                    true)
                                ? Text(
                                  userData['initials'] ??
                                      otherUserName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                                : null,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      // ✅ Show tick only if the current user sent the last message
                      if (chat['lastMessageSenderId'] == currentUserId)
                        Row(
                          children: [
                            MessageStatusIcon(
                              senderId: chat['lastMessageSenderId'],
                              currentUserId: currentUserId,
                              status: chat['lastMessageStatus'] ?? 'sent',
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),

                      // ✅ Expanded last message text with styling
                      Expanded(
                        child: Text(
                          chat['lastMessage']?.toString().trim().isNotEmpty ==
                                  true
                              ? chat['lastMessage']
                              : 'Start a conversation...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                unreadCount > 0
                                    ? Colors.black
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  onTap: () {
                    Get.find<MessageController>().startListeningForMessages(
                      chatId,
                    );

                    Get.toNamed(
                      ChatScreen.routeName,
                      arguments: {
                        'chatId': chatId,
                        'otherUserName': otherUserName,
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
