import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talky/controller/chat/typing_controller.dart';
import 'package:talky/controller/firebase_options.dart';
import 'package:talky/controller/new_message_controller.dart';
import 'package:talky/controller/notification_controller.dart';
import 'package:talky/controller/presence_controller.dart';
import 'package:talky/controller/profile_controller.dart';
import 'package:talky/routes.dart';
import 'package:talky/screens/home/home_screen.dart';
import 'package:talky/screens/login/login_screen.dart';
import 'package:talky/utils/app_colors.dart';
import 'package:talky/utils/show_snack_bar.dart';

import 'controller/audio_controller.dart';
import 'controller/chat/chat_controller.dart';
import 'controller/chat/message_controller.dart';
import 'controller/chat/reply_controller.dart';
import 'controller/contact_controller.dart';

/// ✅ Background FCM handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📥 Background FCM received: ${message.messageId}');
  await NotificationController.handleIncomingFCM(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  debugPrint('🟢 Firestore offline persistence enabled');
  // ✅ Handle notification tap when app is completely terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await NotificationController.handleIncomingFCM(initialMessage);
    final chatId = initialMessage.data['chatId'];
    if (chatId != null) {
      Get.toNamed('/chat', arguments: {'chatId': chatId});
    }
  }

  // ✅ Initialize controllers
  Get.put(NewMessageController());
  Get.put(ContactController());
  Get.put(PresenceController()); // No need to call setupPresence here now
  Get.put(NotificationController());
  Get.put(ProfileController());
  Get.put(ReplyController());
  Get.put(MessageController());
  Get.put(TypingController());
  Get.put(AudioController());
  Get.put(ChatController());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final presenceController = Get.find<PresenceController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final notificationController = Get.find<NotificationController>();
    notificationController.initializeOnMessageOpenedApp();
    notificationController.handleInitialMessage();

    // Initial online status
    presenceController.setupPresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      presenceController.setupPresence();
    } else if (state == AppLifecycleState.paused) {
      presenceController.setOfflineStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GetMaterialApp(
      title: 'Talky',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ShowSnackBar.messengerKey,
      theme: ThemeData(
        primarySwatch: buildMaterialColor(AppColors.greenColor),
        textTheme: GoogleFonts.poppinsTextTheme(textTheme),
      ),
      routes: routes,
      onGenerateRoute: generateRoute,
      home: _handleAuthState(),
    );
  }

  Widget _handleAuthState() {
    return FirebaseAuth.instance.currentUser == null
        ? const LoginScreen()
        : const HomeScreen();
  }

  MaterialColor buildMaterialColor(Color color) {
    final List strengths = <double>[.05];
    final Map<int, Color> swatch = {};
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
