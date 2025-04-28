// lib/screens/chats/chat_top_section.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:talky/screens/chat/components/search_bar.dart';
import 'package:talky/screens/chat/new_message_screen.dart';
import 'package:talky/utils/app_colors.dart';

class ChatTopSection extends StatelessWidget {
  final String? initials;
  final String? profileImageUrl;
  final TextEditingController searchController;

  const ChatTopSection({
    super.key,
    required this.initials,
    required this.profileImageUrl,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      height: screenHeight * 0.23,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: profileImageUrl!,
                        imageBuilder:
                            (context, imageProvider) => CircleAvatar(
                              radius: 20,
                              backgroundImage: imageProvider,
                              backgroundColor: Colors.grey.shade300,
                            ),
                        placeholder:
                            (context, url) => const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey,
                            ),

                        errorWidget:
                            (context, url, error) => CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade400,
                              child: Text(
                                initials ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      )
                      : CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade400,
                        child: Text(
                          initials ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                  const SizedBox(width: 12),
                  const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => NewMessageScreen(),
                  );
                },
                child: Image.asset(
                  'assets/icons/add.png',
                  width: 28,
                  height: 28,
                  color: AppColors.buttonColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SearchBarWidget(controller: searchController),
        ],
      ),
    );
  }
}
