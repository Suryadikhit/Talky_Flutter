import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../controller/profile_controller.dart';
import '../../utils/app_colors.dart';

class ProfileFormWidget extends StatelessWidget {
  final ProfileController controller;
  const ProfileFormWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: const InputDecoration(labelText: "First Name"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller.lastNameController,
          decoration: const InputDecoration(labelText: "Last Name"),
        ),
      ],
    );
  }
}

class ProfileButton extends StatelessWidget {
  final ProfileController controller;
  const ProfileButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isLoading = controller.isUploading.value;
      return greenButton(
        isLoading ? null : controller.saveProfileData,
        isLoading,
      );
    });
  }
}

Widget greenButton(VoidCallback? onPressed, bool isLoading) {
  return MaterialButton(
    minWidth: double.infinity,
    height: 50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    color: AppColors.background,
    onPressed: onPressed,
    disabledColor: Colors.grey, // Gray out when disabled
    child:
        isLoading
            ? SizedBox(
              height: 30,
              width: 30,
              child: Lottie.asset(
                'assets/animations/loading_animation.json',
                fit: BoxFit.contain,
              ),
            )
            : Text(
              "Submit",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
  );
}
