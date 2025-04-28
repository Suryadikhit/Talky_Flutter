import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:talky/controller/audio_controller.dart';
import 'package:talky/controller/chat/message_controller.dart';
import 'package:talky/controller/chat/typing_controller.dart';
import 'package:talky/controller/profile_controller.dart';
import 'package:talky/message/message_bubble.dart';
import 'package:talky/screens/chat/components/chatting_screen_topbar.dart';
import 'package:talky/utils/app_colors.dart';

import '../../controller/chat/chat_controller.dart';
import '../../controller/chat/reply_controller.dart';
import '../../controller/new_message_controller.dart';
import 'chat_input_section_main.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
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
  final NewMessageController newMessageController = Get.find();
  final ProfileController profileController = Get.find();
  final TextEditingController messageController = TextEditingController();
  final Map<String, bool> deletedMessageStates = {};
  final Set<String> deletedMessageIds = {};

  late String currentUserId;
  late String otherUserId;
  Map<String, String> phoneToNameMap = {}; // Store phone to name mapping

  @override
  void initState() {
    super.initState();
    final _ = Get.find<ReplyController>();

    Get.find<ReplyController>().markChatAsOpened(widget.chatId);
    currentUserId = chatController.currentUserId;
    otherUserId = widget.chatId
        .replaceAll(currentUserId, '')
        .replaceAll('_', '');

    // ✅ Update statuses when chat is opened
    Get.find<MessageController>().updateMessageStatuses(widget.chatId);
  }

  @override
  void dispose() {
    Get.find<ReplyController>().markChatAsClosed(widget.chatId);
    super.dispose();
  }

  bool isSelectionMode = false;

  void toggleSelection(String messageId) {
    final wasSelected = selectedMessageIds.contains(messageId);
    setState(() {
      wasSelected
          ? selectedMessageIds.remove(messageId)
          : selectedMessageIds.add(messageId);

      isSelectionMode = selectedMessageIds.isNotEmpty;
    });
  }

  void enterSelectionMode(String messageId) {
    if (!selectedMessageIds.contains(messageId)) {
      setState(() {
        selectedMessageIds.add(messageId);
        isSelectionMode = true;
      });
    }
  }

  void deleteSelectedMessages() async {
    for (String id in selectedMessageIds) {
      await chatController.deleteMessage(widget.chatId, id);
    }
    setState(() {
      selectedMessageIds.clear();
      isSelectionMode = false;
    });
  }

  Set<String> selectedMessageIds = {};

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
                statusText = 'Online';
              } else if (lastSeen != null) {
                final dateTime = lastSeen.toDate();
                final formattedTime = TimeOfDay.fromDateTime(
                  dateTime,
                ).format(context);
                statusText = 'Last seen at $formattedTime';
              }
            }

            return StreamBuilder<bool>(
              // Check if the other user is typing
              stream: Get.find<TypingController>().getTypingStatus(
                widget.chatId,
                otherUserId,
              ),
              builder: (context, typingSnapshot) {
                final isTyping = typingSnapshot.data ?? false;
                final String chatId = '${currentUserId}_$otherUserId';
                return ChatTopBar(
                  isSelectionMode: isSelectionMode,
                  selectedCount: selectedMessageIds.length,
                  onDeleteSelectedMessages: deleteSelectedMessages,
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserName: widget.otherUserName,
                  statusText: isTyping ? 'typing...' : statusText,
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
                if (!snapshot.hasData) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading_animation.json',
                      width: 30,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>? ?? {};
                    final messageText = message['message'] ?? '';
                    final senderPhoneNumber =
                        message['senderPhoneNumber'] ?? '';
                    final senderUid = message['senderId'] ?? '';
                    final messageId = messages[index].id;
                    final replyController = Get.find<ReplyController>();
                    final mediaUrl = message['mediaUrl'];
                    if (kDebugMode) {
                      print('mediaUrl: $mediaUrl');
                    }

                    final isCurrentUser =
                        senderPhoneNumber ==
                        FirebaseAuth.instance.currentUser?.phoneNumber;
                    String senderName =
                        isCurrentUser
                            ? 'You'
                            : replyController
                                    .phoneToNameMap[senderPhoneNumber] ??
                                'Unknown';

                    if (senderName == 'Unknown') {
                      senderName = 'Fetching Name...';
                    }
                    final mediaFilePath = message['mediaFilePath'];
                    final replyToMessage = message['replyToMessage'];
                    final replyToMessageId = message['replyToMessageId'];
                    final replyToSenderName = message['replyToSenderName'];
                    final replyToSenderPhoneNumber =
                        message['replyToSenderPhoneNumber'];

                    return GestureDetector(
                      child:
                          deletedMessageIds.contains(messageId)
                              ? const SizedBox()
                              : MessageBubble(
                                isSelected: selectedMessageIds.contains(
                                  messageId,
                                ),
                                onLongPressSelect:
                                    () => enterSelectionMode(messageId),
                                onTapSelect: () => toggleSelection(messageId),
                                message: messageText,
                                onDelete: (messageId) async {
                                  setState(() {
                                    deletedMessageStates[messageId] = true;
                                  });

                                  await Future.delayed(
                                    const Duration(milliseconds: 250),
                                  );

                                  setState(() {
                                    deletedMessageIds.add(messageId);
                                  });

                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  await chatController.deleteMessage(
                                    widget.chatId,
                                    messageId,
                                  );
                                },
                                messageId: messageId,
                                senderId: senderUid,
                                currentUserId: chatController.currentUserId,
                                status: message['status'] ?? 'sent',
                                timestamp:
                                    (message['timestamp'] as Timestamp?)
                                        ?.toDate() ??
                                    DateTime.now(),
                                replyToMessage: replyToMessage,
                                replyToMessageId: replyToMessageId,
                                senderName: senderName,
                                mediaFilePath: mediaFilePath,
                                type: message['type'] ?? 'text',
                                audioUrl: message['audioUrl'],
                                mediaUrl: mediaUrl,
                                replyToSenderName: replyToSenderName,
                                replyToSenderPhoneNumber:
                                    replyToSenderPhoneNumber,
                                onSwipeReply: (
                                  swipedMessage,
                                  swipedMessageId,
                                ) async {
                                  await replyController.setReply(
                                    swipedMessage,
                                    senderPhoneNumber,
                                    swipedMessageId,
                                  );
                                },
                              ),
                    );
                  },
                );
              },
            ),
          ),

          // Chat Input Section
          ChatInputSection(
            chatId: widget.chatId,
            controller: messageController,
            onSend: (msg, {String? mediaFilePath, String? mediaType}) async {
              final replyController = Get.find<ReplyController>();
              final messageCtrl = Get.find<MessageController>();
              final audioController = Get.find<AudioController>();

              // Log Typing Status Update
              if (kDebugMode) {
                print('[ChatInput] Typing status update: false');
              }

              // Update typing status
              Get.find<TypingController>().updateTypingStatus(
                widget.chatId,
                false,
              );

              if (audioController.recordedFilePath.value != null &&
                  audioController.recordedFilePath.value!.isNotEmpty) {
                // Send audio message
                if (kDebugMode) {
                  print('[ChatInput] Sending audio message...');
                }
                if (kDebugMode) {
                  print(
                    '[ChatInput] Audio file path: ${audioController.recordedFilePath.value}',
                  );
                }

                messageCtrl.sendMessage(
                  widget.chatId,
                  'Audio Message',
                  otherUserId,
                  audioFilePath: audioController.recordedFilePath.value,
                  replyToMessage: replyController.replyMessage.value,
                  replyToMessageId: replyController.replyMessageId.value,
                  replyToSenderName: replyController.replyMessageSender.value,
                  replyToSenderPhoneNumber:
                      replyController.replyPhoneNumber.value,
                );
                audioController.recordedFilePath.value =
                    ''; // Clear after sending
                if (kDebugMode) {
                  print('[ChatInput] Audio message sent, file path cleared');
                }
              } else if (msg.trim().isNotEmpty) {
                // Send regular text message
                if (kDebugMode) {
                  print('[ChatInput] Sending text message: $msg');
                }
                messageCtrl.sendMessage(
                  widget.chatId,
                  msg,
                  otherUserId,
                  replyToMessage: replyController.replyMessage.value,
                  replyToMessageId: replyController.replyMessageId.value,
                  replyToSenderName: replyController.replyMessageSender.value,
                  replyToSenderPhoneNumber:
                      replyController.replyPhoneNumber.value,
                );
                if (kDebugMode) {
                  print('[ChatInput] Text message sent');
                }
              } else {
                // Send media (image/video) if available
                if (mediaFilePath != null && mediaType != null) {
                  if (kDebugMode) {
                    print('[ChatInput] Sending media message...');
                  }
                  if (kDebugMode) {
                    print(
                      '[ChatInput] Media file path: $mediaFilePath, Media type: $mediaType',
                    );
                  }

                  // Send media (image/video)
                  messageCtrl.sendMessage(
                    widget.chatId,
                    'Media Message',
                    otherUserId,
                    mediaFilePath: mediaFilePath,
                    mediaType: mediaType,

                    replyToMessage: replyController.replyMessage.value,
                    replyToMessageId: replyController.replyMessageId.value,
                    replyToSenderName: replyController.replyMessageSender.value,
                    replyToSenderPhoneNumber:
                        replyController.replyPhoneNumber.value,
                  );
                  if (kDebugMode) {
                    print('[ChatInput] Media message sent');
                  }
                }
              }

              replyController.clearReply(); // ✅ Clear reply after sending
              if (kDebugMode) {
                print('[ChatInput] Reply cleared');
              }
            },

            onChanged: (text) {
              // Log Typing Status Update on text change
              if (kDebugMode) {
                print('[ChatInput] Typing status update: ${text.isNotEmpty}');
              }
              Get.find<TypingController>().updateTypingStatus(
                widget.chatId,
                text.isNotEmpty,
              );
            },
          ),
        ],
      ),
    );
  }
}
