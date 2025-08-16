import 'package:app_v0/features/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingFinishingPage extends StatelessWidget {
  const OnboardingFinishingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = Get.find<OnboardingController>();
    const Color primaryColor = Color(0xFF53A194);
    const Color secondaryColor = Color(0xFFE5E0D2);
    const Color textColor = Color(0xFF524F42);

    return Container(
      color: secondaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.check_circle_outline_rounded,
              size: 120,
              color: primaryColor,
            ),
            const SizedBox(height: 30),
            const Text(
              'Tudo pronto!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Suas configurações foram salvas com sucesso. O SafeBaby já está pronto para cuidar da segurança de quem você ama.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                controller.goToMainPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Começar a usar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
