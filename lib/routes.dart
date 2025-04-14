import 'package:flutter/material.dart';
import 'package:talky/screens/login/login_screen.dart';
import 'package:talky/screens/otp/otp_screen.dart';
import 'package:talky/screens/profile_settings/profile_settings_screen.dart';

import '../screens/chat/chat_screen.dart';
import '../screens/chat/new_message_screen.dart';
import '../screens/home/home_screen.dart';

final Map<String, WidgetBuilder> routes = {
  HomeScreen.routeName: (context) => const HomeScreen(),
  LoginScreen.routeName: (context) => const LoginScreen(),
  OTPScreen.routeName: (context) => const OTPScreen(),
  ProfileSettingScreen.routeName: (context) => const ProfileSettingScreen(),
};

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case NewMessageScreen.routeName:
      return MaterialPageRoute(builder: (context) => NewMessageScreen());

    case ChatScreen.routeName: // ✅ Ensure consistency
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                chatId: args["chatId"] ?? "",
                otherUserName: args["otherUserName"] ?? "Unknown",
              ),
        );
      }
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ); // ❌ Fallback case

    default:
      return MaterialPageRoute(builder: (context) => const HomeScreen());
  }
}
