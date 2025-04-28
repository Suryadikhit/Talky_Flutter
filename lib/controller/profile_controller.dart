import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talky/screens/home/home_screen.dart';

class ProfileController extends GetxController {
  TextEditingController nameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  Rx<File?> selectedImage = Rx<File?>(null);
  RxBool isUploading = false.obs;
  RxString selectedGender = 'Male'.obs;
  RxString initials = ''.obs; // Reactive initials

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(updateInitials);
    lastNameController.addListener(updateInitials);
  }

  void updateInitials() {
    final String firstName = nameController.text.trim();
    final String lastName = lastNameController.text.trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      initials.value = firstName[0].toUpperCase() + lastName[0].toUpperCase();
    } else if (firstName.isNotEmpty) {
      initials.value = firstName[0].toUpperCase();
    } else {
      initials.value = ''; // Reset initials if no name is entered
    }
  }

  Future<void> getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  Future<void> saveProfileData() async {
    if (!formKey.currentState!.validate()) return;

    isUploading.value = true;
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String firstName = nameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String phoneNumber =
        FirebaseAuth.instance.currentUser!.phoneNumber ?? '';
    String? profileImageUrl;

    try {
      if (selectedImage.value != null) {
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$userId.jpg');

        final UploadTask uploadTask = storageRef.putFile(selectedImage.value!);
        final TaskSnapshot snapshot = await uploadTask;
        profileImageUrl = await snapshot.ref.getDownloadURL();
      } else {
        profileImageUrl = '';
      }

      // Fetch existing user data
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      final String previousName =
          userDoc.exists ? (userDoc['username'] ?? '') : '';

      // Generate initials only if name has changed
      final String userInitials =
          previousName != '$firstName $lastName'
              ? (firstName.isNotEmpty
                  ? (lastName.isNotEmpty
                      ? firstName[0].toUpperCase() + lastName[0].toUpperCase()
                      : firstName[0].toUpperCase())
                  : '?')
              : userDoc['initials'] ?? '?';

      final String? fcmToken = await FirebaseMessaging.instance.getToken();

      final Map<String, dynamic> userData = {
        'userId': userId,
        'username': '$firstName $lastName',
        'number': phoneNumber,
        'gender': selectedGender.value,
        'profileImageUrl': profileImageUrl,
        'fcmToken': fcmToken ?? '',
        'initials': userInitials, // Store initials in Firestore
        'status': {
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        }, // Store user status
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userData);
      Get.snackbar('Success', 'Profile Updated!');
      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isUploading.value = false;
    }
  }
}
