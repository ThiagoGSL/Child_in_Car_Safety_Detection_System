import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/main_page/main_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingController extends GetxController {
  late PageController pageController;
  final GetStorage _storageBox = GetStorage();
  final formKey = GlobalKey<FormState>();

  var currentPageIndex = 0.obs;
  var bluetoothPermissionGranted = false.obs;
  var notificationsPermissionGranted = false.obs;
  // MODIFICAÇÃO: Variável para o estado da permissão de localização.
  var locationPermissionGranted = false.obs;
  var smsPermissionGranted= false.obs;
  var isFormValid = false.obs;

  final BluetoothController bleController = Get.find<BluetoothController>();

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    checkPermissions();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void checkFormValidity() {
    isFormValid.value = formKey.currentState?.validate() ?? false;
  }

  // MODIFICAÇÃO: Verifica todas as três permissões na inicialização.
  void checkPermissions() async {
    bluetoothPermissionGranted.value = await Permission.bluetoothConnect.isGranted && await Permission.bluetoothScan.isGranted;
    notificationsPermissionGranted.value = await Permission.notification.isGranted;
    locationPermissionGranted.value = await Permission.locationWhenInUse.isGranted;
    smsPermissionGranted.value = await Permission.sms.isGranted;
  }

  void _showSettingsDialog(String title, String content) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Get.back();
            },
            child: const Text('Abrir Configurações', style: TextStyle(color: Color(0xFF53BF9D))),
          ),
        ],
      ),
    );
  }

  void requestBluetoothPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    bool isGranted = statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
                     statuses[Permission.bluetoothConnect] == PermissionStatus.granted;

    bluetoothPermissionGranted.value = isGranted;

    if (!isGranted && (await Permission.bluetoothScan.isPermanentlyDenied || await Permission.bluetoothConnect.isPermanentlyDenied)) {
      _showSettingsDialog(
        'Permissão de Bluetooth',
        'A permissão de Bluetooth foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo.',
      );
    }
  }

  void requestNotificationsPermission() async {
    final status = await Permission.notification.request();
    notificationsPermissionGranted.value = status.isGranted;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        'Permissão de Notificações',
        'A permissão de notificações foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo.',
      );
    }
  }

  // MODIFICAÇÃO: Novo método para solicitar a permissão de localização.
  void requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    locationPermissionGranted.value = status.isGranted;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        'Permissão de Localização',
        'A permissão de Localização foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo para usar todas as funcionalidades.',
      );
    }
  }

  void requestSmsPermission() async {
    final status = await Permission.sms.request();
    smsPermissionGranted.value = status.isGranted;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        'Permissão de SMS',
        'A permissão de SMS é crucial para os alertas de emergência. Por favor, habilite-a nas configurações do aplicativo.',
      );
    }
  }

  void previousPage() {
    if (currentPageIndex.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void validateAndProceed() {
    if (currentPageIndex.value == 4) {
      if (isFormValid.value) {
        final FormController formController = Get.find<FormController>();
        formController.saveData();

        _storageBox.write('onboarding_completed', true);
        pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.ease,
        );
      }
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
  }

  void goToMainPage() {
    Get.offAll(() => const MainPage());
  }
}
