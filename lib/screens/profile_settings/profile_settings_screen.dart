import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talky/screens/profile_settings/profile_image_widget.dart';

import 'package:talky/common_widgets/green_widget_without_logo.dart';
import 'package:talky/controller/profile_controller.dart';
import 'package:talky/utils/app_colors.dart';
import 'package:talky/screens/profile_settings/gender_selection_widget.dart';
import 'package:talky/screens/profile_settings/profile_form_widget.dart';

class ProfileSettingScreen extends StatefulWidget {
  static String routeName = '/ProfileSettingScreen';
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
                  const GreenWidgetWithoutLogo(
                    title: 'Profile Settings',
                    subtitle: '',
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
