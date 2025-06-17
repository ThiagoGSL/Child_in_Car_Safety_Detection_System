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
  var appBarTitle = 'SafeBaby'.obs;

  var showBlePage = false.obs;
  var showPhotoPage = false.obs;
  var showFormPage = false.obs; // NOVO: Variável de estado para o formulário

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
      // Reseta TODAS as sub-páginas ao trocar de aba
      showBlePage.value = false;
      showPhotoPage.value = false;
      showFormPage.value = false; // NOVO: Reseta o estado do formulário
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
      showPhotoPage.value = false; 
      showFormPage.value = false;
      appBarTitle.value = 'Conexão Bluetooth';
      final bleController = Get.find<BluetoothController>();
      if (!bleController.isScanning.value) {
        bleController.startAutoScan();
      }
    } else {
      appBarTitle.value = 'Configurações';
    }
  }

  void navigateToPhotoPage(bool show) {
    showPhotoPage.value = show;
    if (show) {
      showBlePage.value = false; 
      showFormPage.value = false;
      appBarTitle.value = 'Fotos Salvas';
    } else {
      appBarTitle.value = 'Configurações';
    }
  }

  // NOVO: Método para navegar para a página de formulário
  void navigateToFormPage(bool show) {
    showFormPage.value = show;
    if (show) {
      showBlePage.value = false;
      showPhotoPage.value = false;
      appBarTitle.value = 'Cadastro de Usuário';
    } else {
      appBarTitle.value = 'Configurações';
    }
  }

  void _updateTitle(int index){
    switch (index) {
      case 0:
        appBarTitle.value = 'SafeBaby';
        break;
      case 1:
        appBarTitle.value = 'Notificações';
        break;
      case 2:
        // MODIFICADO: Condição atualizada para incluir a nova sub-página
        if (!showBlePage.value && !showPhotoPage.value && !showFormPage.value) {
           appBarTitle.value = 'Configurações';
        }
        break;
      default:
        appBarTitle.value = 'SafeBaby';
    }
  }
}