import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controller/chat_controller.dart';

class NewMessageController extends GetxController {
  var contacts = <Contact>[].obs;
  var talkyUsers = <String>[].obs;
  var isLoading = true.obs;
  var permissionDenied = false.obs;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    checkPermissionAndFetchContacts();
  }

  Future<void> checkPermissionAndFetchContacts() async {
    var status = await Permission.contacts.status;
    if (status.isGranted) {
      await fetchContacts();
    } else if (status.isDenied || status.isRestricted) {
      await requestAndFetchContacts();
    } else if (status.isPermanentlyDenied) {
      isLoading.value = false;
      permissionDenied.value = true;
    }
  }

  Future<void> requestAndFetchContacts() async {
    PermissionStatus status = await Permission.contacts.request();
    if (status.isGranted) {
      await fetchContacts();
    } else {
      isLoading.value = false;
      permissionDenied.value = true;
    }
  }

  String normalizeNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) return "+91$cleaned";
    if (cleaned.startsWith("91") && cleaned.length == 12) return "+$cleaned";
    return "+$cleaned";
  }

  Future<void> fetchContacts() async {
    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      isLoading.value = false;
      permissionDenied.value = true;
      return;
    }

    try {
      List<Contact> phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      List<String> phoneNumbers =
          phoneContacts
              .where((contact) => contact.phones.isNotEmpty)
              .map((contact) => normalizeNumber(contact.phones.first.number))
              .toList();

      if (phoneNumbers.isEmpty) {
        isLoading.value = false;
        return;
      }

      List<String> registeredNumbers = await fetchRegisteredUsers(phoneNumbers);

      // Sort contacts: Talky users first
      phoneContacts.sort((a, b) {
        bool aIsTalkyUser = registeredNumbers.contains(
          normalizeNumber(a.phones.isNotEmpty ? a.phones.first.number : ""),
        );
        bool bIsTalkyUser = registeredNumbers.contains(
          normalizeNumber(b.phones.isNotEmpty ? b.phones.first.number : ""),
        );

        return (bIsTalkyUser ? 1 : 0) - (aIsTalkyUser ? 1 : 0);
      });

      talkyUsers.assignAll(registeredNumbers);
      contacts.assignAll(phoneContacts);
      isLoading.value = false;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching contacts: $e");
      }
      isLoading.value = false;
    }
  }

  Future<List<String>> fetchRegisteredUsers(List<String> phoneNumbers) async {
    List<String> registeredNumbers = [];
    List<List<String>> chunkedNumbers = _splitList(phoneNumbers, 30);

    for (List<String> chunk in chunkedNumbers) {
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .where("number", whereIn: chunk)
              .get();

      registeredNumbers.addAll(
        usersSnapshot.docs.map((doc) => doc["number"] as String),
      );
    }

    return registeredNumbers;
  }

  List<List<String>> _splitList(List<String> list, int chunkSize) {
    List<List<String>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  void startChat(String phoneNumber) async {
    final ChatController chatController = Get.find<ChatController>();

    String? chatId = await chatController.getOrCreateChatRoom(phoneNumber);
    if (kDebugMode) {
      print("🔎 Checking chat navigation: Chat ID -> $chatId");
    }

    if (chatId != null && chatId.isNotEmpty) {
      String? otherUserName = await chatController.getUserNameByPhoneNumber(
        phoneNumber,
      );

      if (kDebugMode) {
        print(
          "🚀 Navigating to chat screen with Chat ID: $chatId and Name: $otherUserName",
        );
      }
      Get.toNamed(
        "/chat",
        arguments: {
          "chatId": chatId,
          "otherUserName": otherUserName ?? phoneNumber,
        },
      );
    } else {
      Get.snackbar(
        "Error",
        "Could not start chat!",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void inviteUser(String phoneNumber) {
    Get.snackbar(
      "Invite",
      "Invite sent to $phoneNumber",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
