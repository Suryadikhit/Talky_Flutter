import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../common_widgets/initials_avatar_generator.dart';

// ... all previous imports stay the same

class NotificationController extends GetxController {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _tag = "[🔔 NotificationController]";

  @override
  void onInit() {
    super.onInit();
    _initializeFCM();
    _initializeLocalNotifications();
    _listenForegroundFCM();
  }

  Future<void> _initializeFCM() async {
    if (kDebugMode) print("$_tag 🔧 Requesting FCM permissions...");
    await _messaging.requestPermission();
    if (kDebugMode) print("$_tag ✅ FCM permission granted");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) print("$_tag ⚠️ No authenticated user to save FCM token");
      return;
    }

    final token = await _messaging.getToken();
    if (token == null) {
      if (kDebugMode) print("$_tag ❌ Failed to get FCM token");
      return;
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await userDoc.get();
    final existingToken = snapshot.data()?['fcmToken'];

    if (existingToken == null || existingToken != token) {
      await userDoc.update({'fcmToken': token});
      if (kDebugMode) print("$_tag 💾 FCM token saved to Firestore: $token");
    } else {
      if (kDebugMode) print("$_tag ℹ️ FCM token already up-to-date");
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      final snap = await userDoc.get();
      final currentToken = snap.data()?['fcmToken'];
      if (currentToken != newToken) {
        await userDoc.update({'fcmToken': newToken});
        if (kDebugMode) {
          print("$_tag 🔁 Token refreshed and updated: $newToken");
        }
      } else {
        if (kDebugMode) print("$_tag 🔁 Token refreshed but already current");
      }
    });
  }

  void _initializeLocalNotifications() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final chatId = response.payload;
        if (chatId != null) {
          _navigateToChat(chatId);
        }
      },
    );

    if (kDebugMode) print("$_tag ✅ Local notifications initialized");
  }

  void _listenForegroundFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("$_tag 📥 Foreground FCM received: ${message.messageId}");
      }
      await handleIncomingFCM(message);
      await _showNotification(message);
    });
  }

  String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    } else {
      return 'U';
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final senderName = message.data['senderName'] ?? 'New Message';
    final messageBody = message.data['messageText'] ?? 'You have a new message';
    final chatId = message.data['chatId'];
    final profileUrl = message.data['profileImageUrl'];
    final initials = getInitials(senderName);

    if (kDebugMode) {
      print("$_tag ✉️ Notification content - sender: $senderName");
      print("$_tag 📝 Message body: $messageBody");
    }

    String? iconPath;

    if (profileUrl != null && profileUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(profileUrl);
        final response = await (await HttpClient().getUrl(uri)).close();
        final bytes = await consolidateHttpClientResponseBytes(response);

        final dir = await getApplicationDocumentsDirectory();
        iconPath = '${dir.path}/profile_${senderName.hashCode}.png';
        await File(iconPath).writeAsBytes(bytes);

        if (kDebugMode) {
          print("$_tag 🖼️ Downloaded profile image for $senderName");
        }
      } catch (e) {
        if (kDebugMode) print("$_tag ❌ Failed to download profile image: $e");
        iconPath = await createInitialsAvatarImage(initials);
        if (kDebugMode) {
          print("$_tag 🧱 Fallback to initials avatar for $senderName");
        }
      }
    } else {
      iconPath = await createInitialsAvatarImage(initials);
      if (kDebugMode) {
        print("$_tag 🧱 Generated initials avatar for $senderName");
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: FilePathAndroidBitmap(iconPath),
      styleInformation: BigTextStyleInformation(
        messageBody,
        contentTitle: senderName,
        summaryText: messageBody,
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      senderName,
      messageBody,
      notificationDetails,
      payload: chatId,
    );

    if (kDebugMode) print("$_tag ✅ Notification shown for chatId: $chatId");
  }

  void initializeOnMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("$_tag 📲 App opened via notification: ${message.data}");
      }
      final chatId = message.data['chatId'];
      if (chatId != null) {
        _navigateToChat(chatId);
      }
    });
  }

  Future<void> handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print("$_tag 🚀 App launched from terminated state via FCM");
      }
      await handleIncomingFCM(initialMessage);

      final chatId = initialMessage.data['chatId'];
      if (chatId != null) {
        _navigateToChat(chatId);
      }
    }
  }

  void _navigateToChat(String chatId) {
    if (Get.currentRoute != '/chat') {
      if (kDebugMode) print("$_tag 🧭 Navigating to chat screen: $chatId");
      Get.toNamed('/chat', arguments: {'chatId': chatId});
    } else {
      if (kDebugMode) print("$_tag ℹ️ Already in chat screen");
    }
  }

  static Future<void> handleIncomingFCM(RemoteMessage message) async {
    const tag = "[🔔 NotificationController]";

    final data = message.data;

    if (data.containsKey('chatId') && data.containsKey('messageId')) {
      final chatId = data['chatId'];
      final messageId = data['messageId'];

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) print("$tag ⚠️ No authenticated user");
        return;
      }

      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId);
      final messageRef = chatRef.collection('messages').doc(messageId);

      final doc = await messageRef.get();
      if (!doc.exists) {
        if (kDebugMode) print("$tag ❌ Message does not exist: $messageId");
        return;
      }

      final senderId = doc['senderId'];
      final status = doc['status'];

      final chatSnap = await chatRef.get();
      final lastMessageId = chatSnap.data()?['lastMessageId'];

      if (senderId != user.uid && status == 'sent') {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          tx.update(messageRef, {'status': 'delivered'});

          if (lastMessageId == messageId) {
            tx.update(chatRef, {'lastMessageStatus': 'delivered'});
          }
        });

        if (kDebugMode) print("$tag ✅ Message marked as 'delivered'");
      } else {
        if (kDebugMode) print("$tag ℹ️ No delivery update required");
      }
    } else {
      if (kDebugMode) print("$tag ⚠️ Missing chatId or messageId in FCM data");
    }
  }
}
