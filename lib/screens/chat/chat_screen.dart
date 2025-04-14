import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../controller/chat_controller.dart';
import '../../controller/profile_controller.dart';
import '../../message/message_bubble.dart';
import '../../utils/app_colors.dart';
import 'components/chat_input_section.dart';
import 'components/chatting_screen_topbar.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
  // StatefulWidget class definition
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState(); // Use ChatScreenState
}

class ChatScreenState extends State<ChatScreen> {
  final ChatController chatController = Get.find();
  final ProfileController profileController = Get.find();
  final TextEditingController messageController = TextEditingController();

  late String currentUserId;
  late String otherUserId;

  @override
  void initState() {
    super.initState();

    currentUserId = chatController.currentUserId;
    otherUserId = widget.chatId
        .replaceAll(currentUserId, '')
        .replaceAll('_', '');

    // ✅ Update statuses when chat is opened
    chatController.updateMessageStatuses(widget.chatId);
  }

  @override
  void dispose() {
    // Make sure to set offline status when the screen is disposed (user leaves)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .snapshots(),
          builder: (context, snapshot) {
            String? statusText;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;

              final bool isOnline = data['isOnline'] == true;
              final Timestamp? lastSeen = data['lastSeen'];

              if (isOnline) {
                statusText = "Online";
              } else if (lastSeen != null) {
                final dateTime = lastSeen.toDate();
                final formattedTime = TimeOfDay.fromDateTime(
                  dateTime,
                ).format(context);
                statusText = "Last seen at $formattedTime";
              }
            }

            return StreamBuilder<bool>(
              stream: chatController.getTypingStatus(
                widget.chatId,
                otherUserId,
              ),
              builder: (context, typingSnapshot) {
                final isTyping = typingSnapshot.data ?? false;
                String chatId = "${currentUserId}_$otherUserId";
                return ChatTopBar(
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserName: widget.otherUserName,
                  profileImageUrl: null,
                  statusText: isTyping ? "typing..." : statusText,
                  onCallPressed: () {},
                  onVideoCallPressed: () {},
                );
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatController.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading_animation.json',
                      width: 30,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  );
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message =
                        messages[index].data() as Map<String, dynamic>? ?? {};

                    return MessageBubble(
                      message: message["message"] ?? "",
                      senderId: message["senderId"] ?? "",
                      currentUserId: chatController.currentUserId,
                      status: message["status"] ?? "sent",
                      timestamp:
                          (message["timestamp"] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    );
                  },
                );
              },
            ),
          ),
          ChatInputSection(
            chatId: widget.chatId,
            controller: messageController,
            onSend: (msg) {
              chatController.updateTypingStatus(widget.chatId, false);
              chatController.sendMessage(widget.chatId, msg, otherUserId);
              messageController.clear();
            },
            onChanged: (text) {
              chatController.updateTypingStatus(widget.chatId, text.isNotEmpty);
            },
          ),
        ],
      ),
    );
  }
}
