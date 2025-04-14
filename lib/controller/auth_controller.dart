import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../screens/otp/otp_screen.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<CountryCode> countryCode =
      CountryCode(name: 'India', code: "IN", dialCode: "+91").obs;

  final RxBool isLoading = false.obs;
  final TextEditingController txtNumberController = TextEditingController();

  StreamSubscription? _authSub;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      print("AuthController initialized");
    }
    WidgetsBinding.instance.addObserver(this);

    // Listen for authentication state changes
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        if (kDebugMode) {
          print("User is signed in: ${user.uid}");
        }
      } else {
        if (kDebugMode) {
          print("No user signed in");
        }
      }
    });
  }

  void sendOTP({String? inputPhone, required BuildContext context}) async {
    final String rawInput = inputPhone ?? txtNumberController.text.trim();

    if (rawInput.isEmpty || rawInput.length < 10) {
      if (kDebugMode) {
        print("Error: Invalid phone number entered");
      }
      Get.snackbar("Error", "Please enter a valid phone number");
      return;
    }

    final String phoneNumber = countryCode.value.dialCode + rawInput;
    isLoading.value = true;
    if (kDebugMode) {
      print("Sending OTP to $phoneNumber");
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (kDebugMode) {
          print("Verification completed, signing in");
        }
        await _auth.signInWithCredential(credential);
        Get.offAllNamed('/HomeScreen');
      },
      verificationFailed: (FirebaseAuthException e) {
        isLoading.value = false;
        if (kDebugMode) {
          print("Verification failed: ${e.message}");
        }
        Get.snackbar(
          "Verification Failed",
          e.message ?? "Something went wrong",
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        isLoading.value = false;
        if (kDebugMode) {
          print("OTP sent, verificationId: $verificationId");
        }
        Navigator.pushNamed(
          context,
          OTPScreen.routeName,
          arguments: {"verificationId": verificationId, "phone": phoneNumber},
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        isLoading.value = false;
        if (kDebugMode) {
          print("Code auto-retrieval timed out");
        }
      },
    );
  }

  final RxBool isVerifying = false.obs;
  final RxBool isResendAvailable = false.obs;
  final RxInt secondsRemaining = 60.obs;

  Timer? _timer;
  String phoneNumber = '';
  String verificationId = '';
  final TextEditingController otpController = TextEditingController();

  void initArgs(Map args) {
    phoneNumber = args["phone"] ?? "";
    verificationId = args["verificationId"] ?? "";
    startTimer();
  }

  void startTimer() {
    if (kDebugMode) {
      print("Starting OTP timer");
    }
    isResendAvailable.value = false;
    secondsRemaining.value = 60;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        secondsRemaining.value--;
      } else {
        _timer?.cancel();
        isResendAvailable.value = true;
        if (kDebugMode) {
          print("OTP resend available");
        }
      }
    });
  }

  void resendOTP() async {
    if (!isResendAvailable.value) return;

    if (kDebugMode) {
      print("Resending OTP...");
    }
    isResendAvailable.value = false;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (kDebugMode) {
          print("Verification completed, signing in");
        }
        await _auth.signInWithCredential(credential);
        Get.offAllNamed('/ProfileSettingScreen');
      },
      verificationFailed: (FirebaseAuthException e) {
        if (kDebugMode) {
          print("Resend verification failed: ${e.message}");
        }
        Get.snackbar("Error", e.message ?? "Verification failed");
      },
      codeSent: (String newVerificationId, int? resendToken) {
        verificationId = newVerificationId;
        if (kDebugMode) {
          print("OTP resent, new verificationId: $newVerificationId");
        }
        startTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void verifyOTP() async {
    String smsCode = otpController.text.trim();
    if (smsCode.length != 6) {
      if (kDebugMode) {
        print("Error: Invalid OTP entered");
      }
      Get.snackbar("Error", "Please enter a valid 6-digit OTP");
      return;
    }

    isVerifying.value = true;
    if (kDebugMode) {
      print("Verifying OTP...");
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        if (kDebugMode) {
          print("User verified successfully: ${user.uid}");
        }

        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          // If the user exists, go to the Home screen
          Get.offAllNamed('/HomeScreen');
        } else {
          // If the user doesn't exist, go to the ProfileSetting screen
          Get.offAllNamed('/ProfileSettingScreen');
        }

        // Call ProfileController to set user online
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error during OTP verification: $e");
      }
      Get.snackbar("Error", "Invalid OTP, please try again");
    }

    isVerifying.value = false;
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (kDebugMode) {
      print("AuthController disposed");
    }
    super.onClose();
  }
}
