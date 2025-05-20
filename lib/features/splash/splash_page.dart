import 'package:app_v0/common/constants/app_colors.dart';
import 'package:app_v0/common/constants/app_text_styles.dart';
import 'package:app_v0/features/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashPage extends StatelessWidget {
  SplashPage({super.key});

  final SplashPageController controller =  Get.put(SplashPageController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashPageController>(
      init: SplashPageController(),
      builder: (controller) {
        return Scaffold(
          body: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.blueGradient,
              )
            ),
            child: Text(
              'ForgottenBaby',
              style: AppTextStyles.bigText.copyWith(color: AppColors.white)
              ),
            ),
          );
      }
    );
  }
}