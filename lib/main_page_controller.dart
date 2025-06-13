import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/config/config_page.dart';
import 'package:app_v0/features/home/home_page.dart';
import 'package:app_v0/features/photos/photo_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPageController extends GetxController {
  // Variáveis de estado reativas
  var selectedIndex = 0.obs;
  var bateriaEsp = 50.obs;
  
  // Flag para controlar a exibição da página de BLE
  var showBlePage = false.obs;

  // Lista dos widgets principais da BottomNavigationBar
  final List<Widget> widgetOptions = [
    const HomePage(),
    PhotoPage(),
    const ConfigPage(), // A 3ª aba sempre aponta para a página de menu
  ];

  void onItemTapped(int index) {
    // Se o usuário clicar em uma aba diferente, esconde a página de BLE
    if (selectedIndex.value != index) {
      showBlePage.value = false;
    }
    selectedIndex.value = index;
  }
  
  // Controla a visibilidade da página de BLE
  void navigateToBlePage(bool show) {
    showBlePage.value = show;
    // Inicia o scan automaticamente ao mostrar a página de BLE
    if (show) {
      final bleController = Get.find<BluetoothController>();
      if (!bleController.isScanning.value) {
        bleController.startScan();
      }
    }
  }
}