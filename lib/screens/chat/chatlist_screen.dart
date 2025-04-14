// Import cached_network_image
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../controller/chat_controller.dart';
import '../../controller/new_message_controller.dart';
import '../../utils/app_colors.dart';
import 'components/chat_list_tile.dart';
import 'components/chat_top_section.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  ChatsScreenState createState() => ChatsScreenState();
}

class ChatsScreenState extends State<ChatsScreen> {
  String? initials;
  String? profileImageUrl;
  final TextEditingController _searchController = TextEditingController();
  final NewMessageController newMessageController = Get.put(
    NewMessageController(),
  );
  Map<String, String> phoneToNameMap = {};

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchLocalContacts();
  }

  Future<void> fetchUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        initials = userDoc["initials"] ?? "?";
        profileImageUrl = userDoc["profileImageUrl"];
      });
    }
  }

  Future<void> fetchLocalContacts() async {
    await newMessageController.fetchContacts();
    for (var contact in newMessageController.contacts) {
      if (contact.phones.isNotEmpty) {
        String phoneNumber = newMessageController.normalizeNumber(
          contact.phones.first.number,
        );
        phoneToNameMap[phoneNumber] = contact.displayName;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ChatTopSection(
            initials: initials,
            profileImageUrl: profileImageUrl,
            searchController: _searchController,
          ),
          Expanded(
            child: Container(
              width: screenWidth,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: Get.find<ChatController>().getChatList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Lottie.asset(
                        'assets/animations/loading_animation.json',
                        width: 30,
                        height: 30,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No chats yet."));
                  }

                  var chats = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      var chat = chats[index];
                      return ChatListTile(
                        chatId: chat["chatId"],
                        phoneToNameMap: phoneToNameMap,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cached image loader
}
