import 'dart:async';
import 'dart:ui';

import 'package:app_v0/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// 1. Crie a função de ponto de entrada para o background
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // O DartPluginRegistrant é necessário para registrar os plugins do Flutter
  // para o novo isolate de background.
  DartPluginRegistrant.ensureInitialized();

  // 2. Reinitialize os plugins que o serviço de background usará.
  await GetStorage.init();
  final box = GetStorage();

  // Sua lógica de background vai aqui.
  // Exemplo: salvar um valor a cada 10 segundos.
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    await box.write('last_run', DateTime.now().toIso8601String());
    print('BACKGROUND SERVICE: Salvo em ${DateTime.now()}');
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Inicialize o GetStorage para a UI principal.
  await GetStorage.init();

  // 4. Configure e inicie o serviço de background.
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true, // Requer uma notificação persistente.
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SafeBaby',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}