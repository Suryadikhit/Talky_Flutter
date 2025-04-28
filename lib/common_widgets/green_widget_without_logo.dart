import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class GreenWidgetWithoutLogo extends StatelessWidget {
  final String title;
  final String? subtitle;

  const GreenWidgetWithoutLogo({required this.title, required this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/mask.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Color(0xFF1C1D21), // Your custom background color
            BlendMode.srcATop, // Applies the color while keeping the image texture
          ),
        ),
      ),

      height: Get.height * 0.3,
      child: Container(
        height: Get.height * 0.1,
        width: Get.width,
        margin: EdgeInsets.only(bottom: Get.height * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
