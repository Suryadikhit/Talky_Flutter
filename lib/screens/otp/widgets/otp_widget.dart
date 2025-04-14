import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../common_widgets/text_widget.dart';
import '../../../utils/app_constants.dart';

/// Widget for OTP input section
class OTPWidgets extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const OTPWidgets({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          textWidget(text: AppConstants.phoneVerification), // "Phone Verification" text
          textWidget(
            text: AppConstants.enterOtp,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),

          // OTP input field
          RoundedWithShadow(
            controller: controller,
            onSubmit: onSubmit,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// Widget for OTP input field with rounded corners and shadow
class RoundedWithShadow extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const RoundedWithShadow({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  RoundedWithShadowState createState() => RoundedWithShadowState();
}

class RoundedWithShadowState extends State<RoundedWithShadow> {
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(focusNode);
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: GoogleFonts.poppins(
        fontSize: 20,
        color: const Color.fromRGBO(70, 69, 66, 1),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).toInt()),
            offset: const Offset(0, 3),
            blurRadius: 16,
          ),
        ],
      ),
    );

    return Pinput(
      length: 6,
      controller: widget.controller, // ✅ Use the external controller
      focusNode: focusNode,
      autofocus: true,
      onCompleted: (String input) {
        widget.onSubmit(); // ✅ Call the onSubmit function
      },
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: Colors.blue),
        ),
      ),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      showCursor: true,
    );
  }
}
