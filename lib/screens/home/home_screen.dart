import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../utils/app_colors.dart';
import '../call/calls_screen.dart';
import '../chat/chatlist_screen.dart';
import '../stories/stories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static String routeName = "/home";

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey();

  final List<Widget> _screens = [
    const ChatsScreen(),
    const CallsScreen(),
    const StoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.buttonColor  , // Set background color
      bottomNavigationBar: CurvedNavigationBar(
        key: bottomNavigationKey,
        backgroundColor: AppColors.whiteColor,
        color: AppColors.background, // Bottom nav bar color
        buttonBackgroundColor: AppColors.background, // Active button color
        items: <Widget>[
          Image.asset("assets/icons/chats.png", width: 30, height: 30,color: AppColors.buttonColor),
          Image.asset("assets/icons/phone.png", width: 30, height: 30,color: AppColors.buttonColor),
          Image.asset("assets/icons/story.png", width: 30, height: 30,color: AppColors.buttonColor),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}
