import 'dart:async'; // Importe para usar o Future.wait

import 'package:app_v0/features/Child_detection/baby_detection_controller.dart';
import 'package:app_v0/features/main_page/main_page.dart';
import 'package:app_v0/features/notification_ext/notification_controller_ext.dart';
import 'package:app_v0/features/onboarding/onboarding_page.dart';
import 'package:app_v0/features/car_moviment_verification/sensores_service_controller.dart';
import 'package:app_v0/features/state_machine/external_controllers.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:app_v0/features/state_machine/state_machine_controller.dart';

class SplashPageController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  void _initializeApp() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _loadDependencies(),
    ]);

    // **LÓGICA DE NAVEGAÇÃO ADICIONADA AQUI**
    // Verifica se o onboarding foi concluído
    final box = GetStorage();
    // Se 'onboarding_completed' não existir, retorna false por padrão.
    bool onboardingCompleted = box.read('onboarding_completed') ?? false;

    // Após a conclusão de tudo, navega para a página correta.
    if (onboardingCompleted) {
      // Se já completou, vai para a página principal.
      Get.off(() => const MainPage(), transition: Transition.fadeIn);
    } else {
      // Se não completou, vai para a página de onboarding.
      Get.off(() => const OnboardingPage(), transition: Transition.fadeIn);
    }
  }

  /// Carrega e inicializa todas as dependências do aplicativo.
  Future<void> _loadDependencies() async {
    // --- FASE 1: INJEÇÃO DE DEPENDÊNCIAS ---
    print("--- Fase 1: Injetando dependências...");
    Get.put(DeteccaoController(), permanent: true);
    Get.put(VehicleDetectionController(), permanent: true);
    Get.put(BabyDetectionController(), permanent: true);
    Get.put(PhotoController(), permanent: true);
    Get.put(FormController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(MainPageController(), permanent: true);
    Get.put(BluetoothController(), permanent: true);
    Get.put(CarroController(), permanent: true);
    Get.put(NotificationExtController(), permanent: true);
    Get.put(StateMachineController(), permanent: true);
    print("--- Fase 1: Concluída.");

    // --- FASE 2: INICIALIZAÇÃO ASSÍNCRONA ---
    print("--- Fase 2: Executando inicializações assíncronas em paralelo...");
    try {
      await Future.wait([
        Get.find<VehicleDetectionController>().init(),
        Get.find<BabyDetectionController>().init(),
        Get.find<PhotoController>().init(),
        Get.find<FormController>().init(),
        Get.find<NotificationController>().init(),
        Get.find<BluetoothController>().init(),
        Get.find<NotificationExtController>().init(),
        Get.find<StateMachineController>().init(),
        // Nota: MainPageController não tem um método init(), então não é chamado aqui.

      ]);
    } catch (e) {
      print("❌ Ocorreu um erro crítico durante a inicialização: $e");
    }
    print("--- Fase 2: Concluída. Todas as dependências estão prontas!");
  }
}
