// Arquivo: main_page_controller.dart

import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/config/config_page.dart';
import 'package:app_v0/features/home/home_page.dart';
import 'package:app_v0/features/notification/notification_page.dart';
import 'package:app_v0/features/notification/notification_controller.dart'; // <-- IMPORTANTE: Importar
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPageController extends GetxController {
  var selectedIndex = 0.obs;
  var bateriaEsp = 50.obs;
  var showBlePage = false.obs;
  var appBarTitle = 'Início'.obs;

  // <-- MUDANÇA: A NotificationPage agora não é mais const
  final List<Widget> widgetOptions = [
    const HomePage(),
    NotificationPage(), // Removido o 'const'
    const ConfigPage(),
  ];

  @override
  void onInit(){
    super.onInit();
    _updateTitle(selectedIndex.value);
  }

  void onItemTapped(int index) {
    if (selectedIndex.value != index) {
      showBlePage.value = false;
    }
    selectedIndex.value = index;
    _updateTitle(index);

    // <-- MUDANÇA: Se o usuário tocar na aba de Notificações (índice 1),
    // zeramos o contador de notificações não lidas.
    if (index == 1) {
      final notificationController = Get.find<NotificationController>();
      notificationController.markNotificationsAsRead();
    }
  }
  
  void navigateToBlePage(bool show) {
    showBlePage.value = show;
    if (show) {
      appBarTitle.value = 'Conexão Bluetooth';
      final bleController = Get.find<BluetoothController>();
      if (!bleController.isScanning.value) {
        bleController.startAutoScan();
      }
    } else {
      appBarTitle.value = 'Configurações';
    }
  }

  void _updateTitle(int index){
    switch (index) {
      case 0:
        appBarTitle.value = 'Início';
        break;
      case 1:
        appBarTitle.value = 'Notificações';
        break;
      case 2:
        if (!showBlePage.value) {
           appBarTitle.value = 'Configurações';
        }
        break;
      default:
        appBarTitle.value = 'ForgottenBaby';
    }
  }
}