import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talky/screens/profile_settings/profile_image_widget.dart';

import '../../common_widgets/green_widget_without_logo.dart';
import '../../controller/profile_controller.dart';
import '../../utils/app_colors.dart';
import 'gender_selection_widget.dart';
import 'profile_form_widget.dart';

class ProfileSettingScreen extends StatefulWidget {
  static String routeName = "/ProfileSettingScreen";
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  final ProfileController controller = Get.put(ProfileController()); // ✅ FIXED

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: Get.height * 0.4,
              child: Stack(
                children: [
                  GreenWidgetWithoutLogo(
                    title: "Profile Settings",
                    subtitle: "",
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: ProfileImageWidget(controller: controller),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    ProfileFormWidget(controller: controller),
                    const SizedBox(height: 50),
                    GenderSelectionWidget(controller: controller),
                    const SizedBox(height: 50),
                    ProfileButton(controller: controller), // ✅ FIXED
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
