import 'package:flutter/material.dart';

import 'package:talky/utils/app_colors.dart';

class UserCard extends StatelessWidget {
  final int index;

  const UserCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 5,
          ), // Improved spacing
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns everything to the top
            children: [
              CircleAvatar(
                radius: 28, // Profile picture size
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/$index.jpg',
                ),
              ),
              const SizedBox(width: 12), // Space between avatar and text
              Expanded(
                child: Column(
                  mainAxisSize:
                      MainAxisSize
                          .min, // Ensures column takes only required space
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align text to the left
                  children: [
                    Text(
                      'User $index',
                      style: const TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2), // Small spacing
                    Text(
                      'Last message from User $index',
                      style: const TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
          color: AppColors.background,
          thickness: 0.5,
          indent: 70, // Aligns exactly with text start
          endIndent: 10, // Aligns the divider neatly
        ),
      ],
    );
  }
}
