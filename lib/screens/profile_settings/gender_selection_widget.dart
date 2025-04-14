import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../controller/profile_controller.dart';
import '../../utils/app_colors.dart';

class GenderSelectionWidget extends StatelessWidget {
  final ProfileController controller;
  const GenderSelectionWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ), // Added border
        ),
        child: Row(
          children:
              ["Male", "Female", "Other"].map((gender) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectedGender.value = gender,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            controller.selectedGender.value == gender
                                ? AppColors.background
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              controller.selectedGender.value == gender
                                  ? AppColors.background
                                  : Colors.transparent,
                          width: 2,
                        ), // Border for selected gender
                      ),
                      child: Text(
                        gender,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              controller.selectedGender.value == gender
                                  ? Colors.white
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
