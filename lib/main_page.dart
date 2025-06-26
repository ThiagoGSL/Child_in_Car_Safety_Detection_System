import 'package:app_v0/common/constants/app_colors.dart';
import 'package:app_v0/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_v0/common/constants/app_colors.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainPageController>(
      init: MainPageController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              Icon(Icons.child_care,
              color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text('ForgottenBaby'),
            ],

            ),
            backgroundColor: Colors.blue[900],
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
          bottomNavigationBar: BottomNavigationBar(backgroundColor: Colors.blue[900] ,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.settings),label: 'Configuração',),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
              BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Sensores')
            ],
            currentIndex: controller.selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.7),
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              controller.onItemTapped(index);
            },
          ),
        );
      },
    );
  }
}