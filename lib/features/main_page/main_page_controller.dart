// Arquivo: main_page_controller.dart

import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/config/config_page.dart';
import 'package:app_v0/features/home/home_page.dart';
import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/notification/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPageController extends GetxController {
  var selectedIndex = 0.obs;
  var bateriaEsp = 50.obs;
  var appBarTitle = 'Início'.obs;

  // Variáveis para controlar a exibição de sub-páginas dentro da aba 'Configurações'
  var showBlePage = false.obs;
  // <-- MUDANÇA: Nova variável de estado para a página de fotos/logs
  var showPhotoPage = false.obs;

  final List<Widget> widgetOptions = [
    const HomePage(),
    NotificationPage(),
    const ConfigPage(),
  ];

  @override
  void onInit(){
    super.onInit();
    _updateTitle(selectedIndex.value);
  }

  void onItemTapped(int index) {
    if (selectedIndex.value != index) {
      // <-- MUDANÇA: Reseta ambas as sub-páginas ao trocar de aba
      showBlePage.value = false;
      showPhotoPage.value = false;
    }
    selectedIndex.value = index;
    _updateTitle(index);

    if (index == 1) {
      Get.find<NotificationController>().markNotificationsAsRead();
    }
  }
  
  void navigateToBlePage(bool show) {
    showBlePage.value = show;
    if (show) {
      // Garante que a outra sub-página seja desativada
      showPhotoPage.value = false; 
      appBarTitle.value = 'Conexão Bluetooth';
      final bleController = Get.find<BluetoothController>();
      if (!bleController.isScanning.value) {
        bleController.startAutoScan();
      }
    } else {
      appBarTitle.value = 'Configurações';
    }
  }

  // <-- MUDANÇA: Novo método para navegar para a página de fotos/logs
  void navigateToPhotoPage(bool show) {
    showPhotoPage.value = show;
    if (show) {
      // Garante que a outra sub-página seja desativada
      showBlePage.value = false; 
      appBarTitle.value = 'Foto salva';
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
        // Verifica o estado das sub-páginas para não sobrescrever o título
        if (!showBlePage.value && !showPhotoPage.value) {
           appBarTitle.value = 'Configurações';
        }
        break;
      default:
        appBarTitle.value = 'ForgottenBaby';
    }
  }
}