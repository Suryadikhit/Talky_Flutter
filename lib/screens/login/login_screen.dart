import 'dart:async';

import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talky/screens/login/widgets/country_mobile_widget.dart';
import 'package:talky/screens/login/widgets/intro_widget.dart';

import 'package:talky/controller/auth_controller.dart';
import 'package:talky/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = '/LoginScreen';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final countryPicker = const FlCountryCodePicker();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final AuthController authController = Get.put(AuthController());
  // Add these to top of _LoginScreenState
  Timer? _debounce;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();

    // Delay to ensure the TextField is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    });

    authController.txtNumberController.addListener(() {
      final text = authController.txtNumberController.text.trim();

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (text.length == 10 && !_otpSent && !authController.isLoading.value) {
          _otpSent = true;
          authController.sendOTP(context: context);
        } else if (text.length < 10) {
          _otpSent = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Prevent memory leaks
    _focusNode.dispose();
    authController.txtNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox(
        width: Get.width,
        height: Get.height,
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              const IntroWidget(),
              Container(
                width: Get.width,
                height: Get.height - Get.height * 0.2,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    const Text('Sign in now'),
                    Obx(
                      () => CountryMobileWidget(
                        countryCode: authController.countryCode.value,
                        onCountryChange: () async {
                          final code = await countryPicker.showPicker(
                            context: context,
                          );
                          if (code != null && mounted) {
                            authController.countryCode.value = code;
                          }
                        },
                        onSubmit:
                            (input) => authController.sendOTP(context: context),
                        focusNode: _focusNode,
                        txtController: authController.txtNumberController,
                        isLoading: authController.isLoading.value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
