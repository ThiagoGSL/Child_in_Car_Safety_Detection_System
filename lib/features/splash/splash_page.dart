// splash_page.dart

import 'package:app_v0/features/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Injeta o controller assim que a SplashPage é construída.
    // O onInit() do controller será chamado automaticamente, disparando a inicialização.
    Get.put(SplashPageController());

    // O resto da sua UI continua exatamente igual, pois ela já é leve e eficiente.
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
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
            // Opcional: Adicionar um indicador de progresso
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}