import 'package:app_v0/features/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingFinishingPage extends StatelessWidget {
  const OnboardingFinishingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // MODIFICAÇÃO: Encontra o controller para chamar a ação do botão.
    final OnboardingController controller = Get.find<OnboardingController>();
    const Color accentColor = Color(0xFF53BF9D);
    const Color backgroundColor = Color(0xFF1A1A2E);

    // Esta página agora é uma parte do PageView, então não precisa de seu próprio Scaffold.
    // O conteúdo é centralizado dentro do espaço que o PageView fornece.
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 120,
              color: accentColor,
            ),
            const SizedBox(height: 30),
            const Text(
              'Tudo pronto!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Suas configurações foram salvas com sucesso. O SafeBaby já está pronto para cuidar da segurança de quem você ama.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // MODIFICAÇÃO: Chama o método do controller para ir para a página principal.
                controller.goToMainPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Começar a usar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
