import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:talky/screens/otp/widgets/otp_widget.dart';

import '../../controller/auth_controller.dart';
import '../../utils/app_colors.dart';

class OTPScreen extends StatelessWidget {
  static String routeName = "/OTPScreen";

  const OTPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    // Initialize arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      authController.initArgs(args);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildBackButton(context),
          const SizedBox(height: 70),
          _buildOTPContainer(authController),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 45),
      child: Align(
        alignment: Alignment.topLeft,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.background,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPContainer(AuthController authController) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OTPWidgets(
                controller: authController.otpController,
                onSubmit: authController.verifyOTP,
              ),
              const SizedBox(height: 20),
              Obx(
                () =>
                    authController.isResendAvailable.value
                        ? TextButton(
                          onPressed: authController.resendOTP,
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                          ),
                        )
                        : Text(
                          "Resend OTP in ${authController.secondsRemaining.value} sec",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
              ),
              const SizedBox(height: 30),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      authController.isVerifying.value
                          ? null
                          : authController.verifyOTP,
                  child:
                      authController.isVerifying.value
                          ? SizedBox(
                            height: 30,
                            width: 30,
                            child: Lottie.asset(
                              'assets/animations/loading_animation.json',
                              fit: BoxFit.contain,
                            ),
                          )
                          : const Text("Verify OTP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
