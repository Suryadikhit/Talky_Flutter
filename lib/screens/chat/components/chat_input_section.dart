import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controller/chat_controller.dart';
import '../../../utils/app_colors.dart';

class ChatInputSection extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final void Function(String)? onChanged;
  final String chatId; // Add chatId as a parameter

  const ChatInputSection({
    super.key,
    required this.controller,
    required this.onSend,
    this.onChanged,
    required this.chatId, // Pass chatId when creating the widget
  });

  @override
  State<ChatInputSection> createState() => _ChatInputSectionState();
}

class _ChatInputSectionState extends State<ChatInputSection> {
  final FocusNode _focusNode = FocusNode();
  bool isTyping = false;
  bool showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTyping);
  }

  void _handleTyping() {
    final typing = widget.controller.text.trim().isNotEmpty;
    if (typing != isTyping) {
      setState(() => isTyping = typing);
    }
  }

  void _toggleEmojiKeyboard() {
    if (showEmojiPicker) {
      _focusNode.requestFocus(); // Show keyboard
    } else {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _focusNode.unfocus(); // Hide keyboard
    }

    setState(() {
      showEmojiPicker = !showEmojiPicker;
    });
  }

  void closeEmojiPicker() {
    setState(() {
      showEmojiPicker = false;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTyping);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (showEmojiPicker) {
          closeEmojiPicker();
          return false; // Prevent pop
        }
        return true; // Allow navigation
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: AppColors.background),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Emoji icon
                GestureDetector(
                  onTap: _toggleEmojiKeyboard,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.asset(
                      showEmojiPicker
                          ? 'assets/icons/keyboard.png'
                          : 'assets/icons/emoji.png',
                      width: 26,
                      height: 26,
                      color: const Color(0xFFE7E1EB),
                    ),
                  ),
                ),

                // TextField with mic/send icon inside
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        focusNode: _focusNode,
                        onChanged: (text) {
                          // Call your onChanged callback if needed
                          widget.onChanged?.call(text);

                          // Track if the user is typing or not
                          final isTyping = text.trim().isNotEmpty;

                          // Update the typing status on Firestore (or Firebase Realtime Database)
                          if (isTyping != this.isTyping) {
                            setState(() {
                              this.isTyping = isTyping;
                            });

                            // Pass the chatId and current user ID to update typing status
                            Get.find<ChatController>().updateTypingStatus(
                              widget.chatId, // Pass the chatId
                              isTyping, // Pass the typing status (true/false)
                            );
                          }
                        },
                        controller: widget.controller,
                        style: const TextStyle(color: Color(0xFFE7E1EB)),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF303133),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      if (!isTyping)
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: GestureDetector(
                            onTap: () {
                              // Mic action
                            },
                            child: Image.asset(
                              'assets/icons/mic.png',
                              width: 24,
                              height: 24,
                              color: const Color(0xFFE7E1EB),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Camera or Send icon
                GestureDetector(
                  onTap: () {
                    final text = widget.controller.text.trim();
                    if (isTyping && text.isNotEmpty) {
                      widget.onSend(text);
                      widget.controller.clear();
                    } else {
                      // Camera action
                    }
                  },
                  child: Image.asset(
                    isTyping
                        ? 'assets/icons/send.png'
                        : 'assets/icons/camera.png',
                    width: 26,
                    height: 26,
                    color:
                        isTyping ? Colors.blueAccent : const Color(0xFFE7E1EB),
                  ),
                ),
              ],
            ),
          ),

          // Emoji Picker
          Offstage(
            offstage: !showEmojiPicker,
            child: SizedBox(
              height: 300,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {},
                onBackspacePressed: () {
                  Future.microtask(() {
                    if (widget.controller.text.isEmpty && showEmojiPicker) {
                      closeEmojiPicker();
                    }
                  });
                },
                textEditingController: widget.controller,
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax:
                        28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.2
                            : 1.0),
                  ),
                  viewOrderConfig: const ViewOrderConfig(
                    top: EmojiPickerItem.categoryBar,
                    middle: EmojiPickerItem.emojiView,
                    bottom: EmojiPickerItem.searchBar,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(),
                  bottomActionBarConfig: const BottomActionBarConfig(),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
