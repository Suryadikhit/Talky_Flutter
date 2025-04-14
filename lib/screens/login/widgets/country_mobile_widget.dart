import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../../../common_widgets/text_widget.dart';
import '../../../../../utils/app_constants.dart';
import '../../../../../utils/show_snack_bar.dart';

class CountryMobileWidget extends StatelessWidget {
  final CountryCode countryCode;
  final Function onCountryChange;
  final Function onSubmit;
  final FocusNode focusNode;
  final TextEditingController txtController;
  final bool isLoading; // Passed from the parent widget

  const CountryMobileWidget({
    super.key,
    required this.countryCode,
    required this.onCountryChange,
    required this.onSubmit,
    required this.focusNode,
    required this.txtController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 3,
                  blurRadius: 3,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => onCountryChange(),
                    child: Row(
                      children: [
                        const SizedBox(width: 5),
                        Expanded(child: countryCode.flagImage()),
                        textWidget(text: countryCode.dialCode),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 55,
                  color: Colors.black.withOpacity(0.2),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      focusNode: focusNode,
                      controller: txtController,
                      onSubmitted: (String? input) => onSubmit(input),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        hintText: AppConstants.enterMobileNumber,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 50, // Adjusted height to give more space
            width: double.infinity, // Full width
            child: ElevatedButton(
              onPressed: () {
                if (isLoading) {
                  // If already loading, don't allow interaction.
                  return;
                }

                // Set isLoading to true to show the animation
                // You can add setState or parent state update logic here if needed
                if (txtController.text.isEmpty) {
                  ShowSnackBar.showSnackBar(
                    text: "Please enter your mobile number",
                  );
                } else {
                  // Perform the onSubmit action
                  onSubmit(txtController.text);
                }
              },
              child:
                  isLoading
                      ? SizedBox(
                        height: 30, // Adjusted size of the animation
                        width: 30, // Adjusted size of the animation
                        child: Lottie.asset(
                          'assets/animations/loading_animation.json',
                          fit:
                              BoxFit
                                  .contain, // Use BoxFit.contain for better animation scaling
                        ),
                      )
                      : const Text("Continue"),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                children: [
                  const TextSpan(text: "${AppConstants.byCreating} "),
                  TextSpan(
                    text: "${AppConstants.termsOfService} ",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: "and "),
                  TextSpan(
                    text: "${AppConstants.privacyPolicy} ",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
