import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/profile_controller.dart';

class ProfileImageWidget extends StatelessWidget {
  final ProfileController controller;
  const ProfileImageWidget({super.key, required this.controller});

  void _showImageSourceDialog() {
    Get.defaultDialog(
      title: "Choose Image",
      content: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text("Camera"),
            onTap: () {
              Get.back();
              controller.getImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.green),
            title: const Text("Gallery"),
            onTap: () {
              Get.back();
              controller.getImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Obx(() {
        if (controller.selectedImage.value != null) {
          return CircleAvatar(
            radius: 60,
            backgroundImage: FileImage(controller.selectedImage.value!),
          );
        } else {
          return CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade400,
            child:
                controller.initials.value.isEmpty
                    ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ) // Default icon
                    : Text(
                      controller.initials.value,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
          );
        }
      }),
    );
  }
}
