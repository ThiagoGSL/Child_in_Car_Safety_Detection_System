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
        // Mostra um botão de voltar quando a página de BLE estiver visível
        leading: Obx(() {
          if (controller.selectedIndex.value == 2 && controller.showBlePage.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                // Ao pressionar, esconde a página de BLE, voltando ao menu
                controller.navigateToBlePage(false);
              },
            );
          }
          return const SizedBox.shrink(); // Não mostra nada por padrão
        }),
        title: const Text('ForgottenBaby'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.battery_charging_full),
                  Text(' ${controller.bateriaEsp.value} %'),
                  const SizedBox(width: 20),
                ],
              )),
        ],
      ),
      // O corpo agora decide qual widget mostrar
      body: Obx(() {
        // Se a 3ª aba (Config) estiver selecionada e a flag for true, mostra a BlePage
        if (controller.selectedIndex.value == 2 && controller.showBlePage.value) {
          return BlePage();
        }
        // Caso contrário, mostra o widget padrão da aba selecionada
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