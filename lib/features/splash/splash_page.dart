import 'package:app_v0/features/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashPageController());

    // Cor de fundo única: verde claro #90BEAB
    const Color splashBackgroundColor = Color(0xFF90BEAB);

    return Scaffold(
      backgroundColor: splashBackgroundColor, // Define a cor de fundo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Substituindo o ícone pela logo
            Image.asset(
              'lib/assets/logoBranca.png',
              height: 150, // Ajuste o tamanho da logo conforme necessário
            ),
            const SizedBox(height: 20),
            // Mudança na cor do texto para melhor contraste
            const Text(
              'SafeBaby',
              style: TextStyle(
                color: Color(0xFF316557), // Cor de texto escura para contraste
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            // Mudança na cor do CircularProgressIndicator para contraste
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF316557)),
            ),
          ],
        ),
      ),
    );
  }
}
