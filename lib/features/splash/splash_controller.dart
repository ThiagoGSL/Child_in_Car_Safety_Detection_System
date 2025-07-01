// lib/features/splash/splash_controller.dart

import 'dart:async'; // Importe para usar o Future.wait
import 'package:app_v0/features/Child_detection/baby_detection_controller.dart';
import 'package:app_v0/features/state_machine/external_controllers.dart';
import 'package:get/get.dart';

// Importe todos os controllers
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:app_v0/features/main_page/main_page.dart';
import 'package:app_v0/features/state_machine/state_machine_controller.dart';

class SplashPageController extends GetxController {
  
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  void _initializeApp() async {
    // Roda a inicialização e um timer mínimo em paralelo.
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _loadDependencies(),
    ]);
    // Após a conclusão de tudo, navega para a página principal.
    Get.off(() => const MainPage(), transition: Transition.fadeIn);
  }

  /// Carrega e inicializa todas as dependências do aplicativo.
  Future<void> _loadDependencies() async {
    // --- FASE 1: INJEÇÃO DE DEPENDÊNCIAS ---
    // Instancia todos os controllers e os torna disponíveis globalmente.
    // Esta parte é rápida, pois os métodos onInit() de cada controller são leves.
    print("--- Fase 1: Injetando dependências...");
    Get.put(BabyDetectionController(), permanent: true);
    Get.put(PhotoController(), permanent: true);
    Get.put(FormController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(MainPageController(), permanent: true);
    Get.put(BluetoothController(), permanent: true);
    Get.put(CarroController(), permanent: true);
    Get.put(DeteccaoController(), permanent: true);
    Get.put(StateMachineController(), permanent: true);
    print("--- Fase 1: Concluída.");

    // --- FASE 2: INICIALIZAÇÃO ASSÍNCRONA ---
    // Agora, chamamos o método init() de cada controller.
    // Usamos Future.wait para executar todas as inicializações em paralelo,
    // o que acelera drasticamente o tempo de carregamento.
    print("--- Fase 2: Executando inicializações assíncronas em paralelo...");
    try {
      await Future.wait([
        Get.find<BabyDetectionController>().init(),
        Get.find<PhotoController>().init(),
        Get.find<FormController>().init(),
        Get.find<NotificationController>().init(),
        Get.find<BluetoothController>().init(),
        Get.find<StateMachineController>().init(),
        // Nota: MainPageController não tem um método init(), então não é chamado aqui.
      ]);
    } catch (e) {
      // Se qualquer uma das inicializações falhar, você pode tratar o erro aqui.
      print("❌ Ocorreu um erro crítico durante a inicialização: $e");
      // Ex: mostrar uma mensagem de erro e fechar o app ou tentar novamente.
    }
    print("--- Fase 2: Concluída. Todas as dependências estão prontas!");
  }
}