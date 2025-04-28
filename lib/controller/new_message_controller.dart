import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat/chat_controller.dart';
import 'chat/chat_utils.dart';

class NewMessageController extends GetxController {
  var contacts = <Contact>[].obs;
  var talkyUsers = <String>[].obs;
  var isLoading = true.obs;
  var permissionDenied = false.obs;

  // Check if the current user is authenticated before accessing the UID
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String currentUserId;

  @override
  void onInit() {
    super.onInit();
    // Ensure that currentUser is not null before accessing the UID
    if (_auth.currentUser != null) {
      currentUserId = _auth.currentUser!.uid;
    } else {
      // Handle the case where the user is not authenticated (maybe sign them out or prompt for login)
      if (kDebugMode) {
        print("User is not authenticated");
      }
      // You can choose to navigate to the login screen or perform any other action
    }

    checkPermission();
  }

  // Check and request permission to access contacts
  Future<void> checkPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      permissionDenied.value = false;
      fetchContacts();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      permissionDenied.value = true;
      // Request permission if denied
      requestPermission();
    }
  }

  // Request permission if denied
  Future<void> requestPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      permissionDenied.value = false;
      fetchContacts();
    } else {
      // Optionally, you can show a dialog here to inform the user
      permissionDenied.value = true;
      // Keep asking until it's granted (can be adjusted as needed)
      Future.delayed(Duration(seconds: 2), () {
        checkPermission(); // Keep asking after delay
      });
    }
  }

  static String normalizeNumber(String number) {
    final String cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.startsWith('91') && cleaned.length == 12) return '+$cleaned';
    return '+$cleaned';
  }

  Future<void> fetchContacts() async {
    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      isLoading.value = false;
      permissionDenied.value = true;
      return;
    }

    try {
      final List<Contact> phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      final List<String> phoneNumbers =
          phoneContacts
              .where((contact) => contact.phones.isNotEmpty)
              .map((contact) => normalizeNumber(contact.phones.first.number))
              .toList();

      if (phoneNumbers.isEmpty) {
        isLoading.value = false;
        return;
      }

      final List<String> registeredNumbers = await fetchRegisteredUsers(
        phoneNumbers,
      );

      // Sort contacts: Talky users first
      phoneContacts.sort((a, b) {
        final bool aIsTalkyUser = registeredNumbers.contains(
          normalizeNumber(a.phones.isNotEmpty ? a.phones.first.number : ''),
        );
        final bool bIsTalkyUser = registeredNumbers.contains(
          normalizeNumber(b.phones.isNotEmpty ? b.phones.first.number : ''),
        );

        return (bIsTalkyUser ? 1 : 0) - (aIsTalkyUser ? 1 : 0);
      });

      talkyUsers.assignAll(registeredNumbers);
      contacts.assignAll(phoneContacts);
      isLoading.value = false;

      // Cache the phone numbers in shared preferences for offline usage
      await cacheContacts(phoneContacts);
      await uploadContactsToFirebase();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching contacts: $e');
      }
      isLoading.value = false;
    }
  }

  Future<void> uploadContactsToFirebase() async {
    if (contacts.isEmpty || currentUserId.isEmpty) {
      if (kDebugMode) print("No contacts or user not authenticated");
      return;
    }

    final CollectionReference contactRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('contacts');

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var contact in contacts) {
      if (contact.phones.isEmpty) continue;

      final normalizedNumber = normalizeNumber(contact.phones.first.number);
      final contactData = {
        'name': contact.displayName,
        'number': normalizedNumber,
      };

      final docRef = contactRef.doc(
        normalizedNumber,
      ); // using phone number as ID
      batch.set(docRef, contactData);
    }

    try {
      await batch.commit();
    } catch (e) {
      if (kDebugMode) print("❌ Error uploading contacts: $e");
      Get.snackbar('Error', 'Failed to upload contacts!');
    }
  }

  Future<void> cacheContacts(List<Contact> phoneContacts) async {
    final prefs = await SharedPreferences.getInstance();

    // Serialize the contacts into a list of strings (name|phone)
    final List<String> serializedContacts =
        phoneContacts.map((contact) {
          final phoneNumber =
              contact.phones.isNotEmpty
                  ? normalizeNumber(
                    contact.phones.first.number,
                  ) // Normalize phone number
                  : '';
          return '${contact.displayName}|$phoneNumber';
        }).toList();

    await prefs.setStringList('cachedContacts', serializedContacts);
    if (kDebugMode) {
      print('Contacts cached: $serializedContacts');
    }
  }

  Future<List<Contact>> getCachedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final serializedContacts = prefs.getStringList('cachedContacts') ?? [];

    List<Contact> contacts = [];
    for (var serializedContact in serializedContacts) {
      try {
        final parts = serializedContact.split('|');
        if (parts.length == 2 && parts[1].isNotEmpty) {
          final cleanedPhoneNumber = normalizeNumber(
            parts[1],
          ); // Normalize the phone number here
          contacts.add(
            Contact(
              displayName: parts[0],
              phones: [
                Phone(cleanedPhoneNumber),
              ], // Use the cleaned phone number
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deserializing contact: $e');
        }
      }
    }

    // Log the deserialized contacts for verification
    if (kDebugMode) {
      for (var contact in contacts) {
        print(
          'Deserialized contact: ${contact.displayName} - ${contact.phones.first.number}',
        );
      }
    }

    return contacts;
  }

  Future<List<String>> fetchRegisteredUsers(List<String> phoneNumbers) async {
    final List<String> registeredNumbers = [];
    final List<List<String>> chunkedNumbers = _splitList(phoneNumbers, 30);

    for (List<String> chunk in chunkedNumbers) {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('number', whereIn: chunk)
              .get();

      registeredNumbers.addAll(
        usersSnapshot.docs.map((doc) => doc['number'] as String),
      );
    }

    return registeredNumbers;
  }

  List<List<String>> _splitList(List<String> list, int chunkSize) {
    final List<List<String>> chunks = [];
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

    final String? chatId = await chatController.getOrCreateChatRoom(
      phoneNumber,
    );
    if (kDebugMode) {
      print('🔎 Checking chat navigation: Chat ID -> $chatId');
    }

    if (chatId != null && chatId.isNotEmpty) {
      final String? otherUserName = await getUserNameByPhoneNumber(phoneNumber);

      if (kDebugMode) {
        print(
          '🚀 Navigating to chat screen with Chat ID: $chatId and Name: $otherUserName',
        );
      }
      Get.toNamed(
        '/chat',
        arguments: {
          'chatId': chatId,
          'otherUserName': otherUserName ?? phoneNumber,
        },
      );
    } else {
      Get.snackbar(
        'Error',
        'Could not start chat!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void inviteUser(String phoneNumber) {
    Get.snackbar(
      'Invite',
      'Invite sent to $phoneNumber',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
