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
  var showBlePage = false.obs;

  // Variável reativa para controlar o título da AppBar
  var appBarTitle = 'Início'.obs;

  final List<Widget> widgetOptions = [
    const HomePage(),
    PhotoPage(),
    const ConfigPage(),
  ];

  @override
  void onInit(){
    super.onInit();
    // Garante que o título inicial corresponda à primeira aba
    _updateTitle(selectedIndex.value);
  }

  void onItemTapped(int index) {
    if (selectedIndex.value != index) {
      showBlePage.value = false;
    }
    selectedIndex.value = index;
    // Atualiza o título baseado no novo índice da aba
    _updateTitle(index);
  }
  
  void navigateToBlePage(bool show) {
    showBlePage.value = show;
    // Atualiza o título para refletir a sub-página de Bluetooth
    if (show) {
      appBarTitle.value = 'Conexão Bluetooth';
      final bleController = Get.find<BluetoothController>();
      if (!bleController.isScanning.value) {
        bleController.startAutoScan();
      }
    } else {
      // Quando voltar, restaura o título da aba de Configurações
      appBarTitle.value = 'Configurações';
    }
  }

  // Função privada para atualizar o título com base no índice da aba
  void _updateTitle(int index){
    switch (index) {
      case 0:
        appBarTitle.value = 'Início';
        break;
      case 1:
        appBarTitle.value = 'Galeria de Fotos';
        break;
      case 2:
        // Se já estivermos na página de BLE, não muda o título
        if (!showBlePage.value) {
           appBarTitle.value = 'Configurações';
        }
        break;
      default:
        appBarTitle.value = 'ForgottenBaby';
    }
  }
}