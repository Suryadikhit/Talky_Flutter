import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      height: Get.height * 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ), // Adds spacing from edges
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align text to the start
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hey! 😊',
              style: GoogleFonts.poppins(
                fontSize: 28, // Bigger size for "Hey!"
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Ready to chat seamlessly?',
              style: GoogleFonts.poppins(
                fontSize: 18, // Smaller than "Hey!"
                fontWeight: FontWeight.w500,
                color: Colors.grey, // Gray color for subtle contrast
              ),
            ),
          ],
        ),
      ),
    );
  }
}
