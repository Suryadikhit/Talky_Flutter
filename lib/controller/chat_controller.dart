import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? "";

  /// Get the user's chat list
  Stream<QuerySnapshot> getChatList() {
    return _firestore
        .collection("chats")
        .where("participants", arrayContains: currentUserId)
        .orderBy("lastMessageTime", descending: true) // ✅ Optimized ordering
        .snapshots();
  }

  /// Get messages in a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// Fetch user ID by phone number
  Future<String?> getUserIdByPhoneNumber(String phoneNumber) async {
    try {
      var userSnapshot =
          await _firestore
              .collection("users")
              .where("number", isEqualTo: phoneNumber)
              .limit(1)
              .get();

      return userSnapshot.docs.isNotEmpty ? userSnapshot.docs.first.id : null;
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching user ID: $e");
      return null;
    }
  }

  /// Fetch username by phone number
  Future<String?> getUserNameByPhoneNumber(String phoneNumber) async {
    try {
      var userSnapshot =
          await _firestore
              .collection("users")
              .where("number", isEqualTo: phoneNumber)
              .limit(1)
              .get();

      return userSnapshot.docs.isNotEmpty
          ? userSnapshot.docs.first["username"]
          : null;
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching user name: $e");
      return null;
    }
  }

  /// Check if a chat exists or create a new one
  Future<String?> getOrCreateChatRoom(String phoneNumber) async {
    try {
      if (phoneNumber.trim().isEmpty) {
        if (kDebugMode) print("❌ Error: Phone number is empty!");
        return null;
      }

      if (currentUserId.isEmpty) {
        Get.snackbar(
          "Error",
          "User not authenticated!",
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      if (kDebugMode) {
        print("🔍 Searching for user with phone number: $phoneNumber");
      }

      // Fetch user ID
      String? otherUserId = await getUserIdByPhoneNumber(phoneNumber);
      if (otherUserId == null) {
        Get.snackbar(
          "Error",
          "User not found!",
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      if (kDebugMode) print("✅ Found user ID: $otherUserId");

      // Generate chat ID (Handles self-chat)
      String chatId = generateChatId(currentUserId, otherUserId);
      if (chatId.isEmpty) {
        if (kDebugMode) print("❌ Error: Generated chat ID is empty!");
        return null;
      }

      if (kDebugMode) print("🔄 Generated chat ID: $chatId");

      // Check if chat already exists and create if needed
      var chatRef = _firestore.collection("chats").doc(chatId);
      var chatSnapshot = await chatRef.get();

      if (!chatSnapshot.exists) {
        if (kDebugMode) print("🆕 Creating new chat room with ID: $chatId");

        await chatRef.set({
          "chatId": chatId,
          "participants": [currentUserId, otherUserId],
          "lastMessage": "",
          "lastMessageTime": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (kDebugMode) print("🎉 Chat room created successfully!");
      } else {
        if (kDebugMode) print("✅ Chat already exists with ID: $chatId");
      }

      return chatId;
    } catch (e) {
      if (kDebugMode) print("❌ Error in getOrCreateChatRoom: $e");
      Get.snackbar(
        "Error",
        "Could not start chat!",
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Generate a stable chat ID (Supports self-chat)
  String generateChatId(String userId1, String userId2) {
    return (userId1 == userId2)
        ? "self_$userId1"
        : (userId1.compareTo(userId2) < 0)
        ? "${userId1}_$userId2"
        : "${userId2}_$userId1";
  }

  /// Update typing status
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    try {
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("typingStatus")
          .doc(currentUserId)
          .set({
            "isTyping": isTyping,
            "lastUpdated": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print("❌ Error updating typing status: $e");
    }
  }

  Stream<bool> getTypingStatus(String chatId, String otherUserId) {
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("typingStatus")
        .doc(otherUserId)
        .snapshots()
        .map((doc) => doc.data()?['isTyping'] ?? false);
  }

  /// Send a new message
  Future<void> sendMessage(
    String chatId,
    String message,
    String receiverId,
  ) async {
    final currentUserId = this.currentUserId;
    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);
    final messageRef = chatRef.collection("messages").doc(); // 🔥 auto ID
    final messageId = messageRef.id;

    final batch = FirebaseFirestore.instance.batch();

    final messageData = {
      "messageId": messageId,
      "senderId": currentUserId,
      "receiverId": receiverId,
      "message": message,
      "status": "sent",
      "timestamp": FieldValue.serverTimestamp(),
    };

    batch.set(messageRef, messageData);

    final chatUpdate = {
      "lastMessage": message,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "lastMessageSenderId": currentUserId,
      "lastMessageStatus": "sent",
      "lastMessageId": messageId,
    };

    batch.update(chatRef, chatUpdate);

    if (kDebugMode) {
      print("✉️ Sending message:");
      print("Chat ID: $chatId");
      print("Message ID: $messageId");
      print("From: $currentUserId ➡️ To: $receiverId");
      print("Message content: $message");
    }

    await batch.commit();

    if (kDebugMode) {
      print("✅ Message sent and chat updated");
    }
  }

  Future<void> updateMessageStatuses(String chatId) async {
    final currentUserId = this.currentUserId;
    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);
    final chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      if (kDebugMode) print("❌ Chat not found: $chatId");
      return;
    }

    final chat = chatSnapshot.data()!;
    final lastMessageId = chat["lastMessageId"];

    final querySnapshot =
        await chatRef
            .collection("messages")
            .where("receiverId", isEqualTo: currentUserId)
            .where("status", whereIn: ["sent", "delivered"])
            .orderBy("timestamp", descending: true)
            .get();

    if (querySnapshot.docs.isEmpty) {
      if (kDebugMode) {
        print("ℹ️ No unseen/delivered messages for $currentUserId");
      }
      return;
    }

    if (kDebugMode) {
      print("👀 Updating messages to 'seen' for user: $currentUserId");
      print("🔢 ${querySnapshot.docs.length} messages found");
    }

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      if (kDebugMode) {
        print(
          "🔄 Marking message as seen: ${doc.id} (status: ${doc['status']})",
        );
      }
      batch.update(doc.reference, {
        "status": "seen",
        "seenAt": FieldValue.serverTimestamp(),
      });
    }

    final lastDelivered = querySnapshot.docs.first;

    if (lastDelivered.id == lastMessageId &&
        lastDelivered["senderId"] != currentUserId) {
      if (kDebugMode) {
        print("✅ Updating lastMessageStatus to 'seen' in chat");
      }
      batch.update(chatRef, {"lastMessageStatus": "seen"});
    } else {
      if (kDebugMode) {
        print("ℹ️ Skipped lastMessageStatus update");
      }
    }

    await batch.commit();

    if (kDebugMode) print("✅ All applicable messages marked as seen");
  }
}
