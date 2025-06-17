import 'package:app_v0/features/bluetooth/ble_page.dart';
import 'package:app_v0/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainPageController controller = Get.put(MainPageController());

    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          // Lógica para o botão de voltar da página de Bluetooth
          if (controller.selectedIndex.value == 2 && controller.showBlePage.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => controller.navigateToBlePage(false),
            );
          }
          return const SizedBox.shrink();
        }),
        title: Obx(() => FittedBox(
          fit: BoxFit.contain,
          child: Text(
            controller.appBarTitle.value,
            style: const TextStyle(fontSize: 18.0),
          ),
        )),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Obx(() {      
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.battery_charging_full),
                Text(' ${controller.bateriaEsp.value} %'),
                const SizedBox(width: 20),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.selectedIndex.value == 2 && controller.showBlePage.value) {
          return BlePage();
        }
        return Center(
          child: controller.widgetOptions.elementAt(controller.selectedIndex.value),
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Galeria'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configurações'),
            ],
            currentIndex: controller.selectedIndex.value,
            selectedItemColor: Colors.blue.shade700,
            onTap: controller.onItemTapped,
          )),
    );
  }
}