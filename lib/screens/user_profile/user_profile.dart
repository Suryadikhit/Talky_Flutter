import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talky/utils/app_colors.dart';

class MyProfile extends StatefulWidget {
  static String routeName = '/MyProfile';
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  TextEditingController nameController = TextEditingController();
  TextEditingController homeController = TextEditingController();
  TextEditingController businessController = TextEditingController();
  TextEditingController shopController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  // Image picker function
  Future<void> getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Dummy data for preview
    nameController.text = 'John Doe';
    homeController.text = '123 Street, New York, USA';
    shopController.text = 'Mall Center, NY';
    businessController.text = 'Downtown Business Park, NY';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: Get.height * 0.4,
              child: Stack(
                children: [
                  _buildHeader(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      onTap: () => getImage(ImageSource.gallery),
                      child: selectedImage == null
                          ? _buildProfilePlaceholder()
                          : _buildProfileImage(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: Get.height * 0.3,
      decoration: const BoxDecoration(
        color: AppColors.greenColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Center(
        child: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xffD6D6D6),
      ),
      child: const Center(
        child: Icon(
          Icons.camera_alt_outlined,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(selectedImage!),
          fit: BoxFit.fill,
        ),
        shape: BoxShape.circle,
        color: const Color(0xffD6D6D6),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _buildTextField('Name', Icons.person_outlined, nameController),
            const SizedBox(height: 10),
            _buildTextField('Home Address', Icons.home_outlined, homeController),
            const SizedBox(height: 10),
            _buildTextField('Business Address', Icons.card_travel, businessController),
            const SizedBox(height: 10),
            _buildTextField('Shopping Center', Icons.shopping_cart_outlined, shopController),
            const SizedBox(height: 30),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String title, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xffA7A7A7),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: Get.width,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 1,
              )
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xffA7A7A7),
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(icon, color: AppColors.greenColor),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return MaterialButton(
      minWidth: Get.width,
      height: 50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      color: AppColors.greenColor,
      onPressed: () {
        if (formKey.currentState!.validate()) {
          Get.snackbar('Profile Updated', 'Your profile has been updated successfully!',
              snackPosition: SnackPosition.BOTTOM);
        }
      },
      child: Text(
        'Update',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
