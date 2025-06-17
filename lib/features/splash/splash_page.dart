import 'package:app_v0/features/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // A inicialização do controller agora é feita apenas pelo GetBuilder
    return GetBuilder<SplashPageController>(
      init: SplashPageController(),
      builder: (controller) {
        return Scaffold(
          // O corpo da página agora tem a nova decoração
          body: Container(
            alignment: Alignment.center,
            // MODIFICADO: Gradiente atualizado para o tema escuro
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E), // Cor primária escura
                  Color(0xFF16213E), // Cor secundária escura
                ],
              ),
            ),
            // MODIFICADO: Adicionado o ícone junto com o texto para reforçar a identidade
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.crib_outlined,
                  size: 80,
                  color: Colors.white,
                ),
                SizedBox(height: 20),
                Text(
                  'SafeBaby',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}