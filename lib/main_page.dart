import 'package:app_v0/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainPageController>(
      init: MainPageController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text('ForgottenBaby'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.battery_charging_full),
                  Text('${controller.bateriaEsp} %'),
                  const SizedBox(width: 20),
                ],
              ),
            ],
          ),
          body: Center(
            child: controller.widgetOptions.elementAt(controller.selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.settings),label: 'Configuração',),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
              BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Sensores')
            ],
            currentIndex: controller.selectedIndex,
            selectedItemColor: Colors.blue,
            onTap: (index) {
              controller.onItemTapped(index);
            },
          ),
        );
      },
    );
  }
}