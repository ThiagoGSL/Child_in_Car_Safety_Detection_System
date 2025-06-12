import 'package:app_v0/features/cadastro/form_page.dart';
import 'package:app_v0/features/home/home_page.dart';
import 'package:app_v0/features/bluetooth/ble_page.dart';
import 'package:app_v0/features/services/sensor_page/sensor_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPageController extends GetxController {
  int selectedIndex = 0;
  int bateriaEsp = 50;

  final List<Widget> widgetOptions = [
    const HomePage(),
    FormPage(),
    BlePage(),
    SensorPage(),
  ];

  void onItemTapped(int index) {
    selectedIndex = index;
    update();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }
}