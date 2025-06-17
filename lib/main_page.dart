import 'package:app_v0/features/bluetooth/ble_page.dart';
import 'package:app_v0/main_page_controller.dart';
import 'package:app_v0/features/notification/notification_controller.dart'; // <-- IMPORTANTE: Importar
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainPageController controller = Get.put(MainPageController());
    // <-- MUDANÇA: Instanciar o NotificationController para usar no badge.
    final NotificationController notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
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
            // Se estiver na aba de notificações, mostra o botão de limpar.
            if (controller.selectedIndex.value == 1) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpar Histórico',
                onPressed: () {
                  // A lógica do diálogo de confirmação agora vive aqui.
                  Get.dialog(AlertDialog(
                    title: const Text('Limpar Histórico?'),
                    content: const Text('Deseja apagar todas as notificações?'),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          notificationController.clearNotifications();
                          Get.back();
                        },
                        child: const Text('Limpar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ));
                },
              );
            }
            
            // Senão, mostra o status da bateria.
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
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              // <-- MUDANÇA: Ícone de notificações com badge.
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications), // Ícone base
                    // Mostra o badge apenas se houver notificações não lidas.
                    if (notificationController.unreadCount.value > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              '${notificationController.unreadCount.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Notificações',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configurações'),
            ],
            currentIndex: controller.selectedIndex.value,
            selectedItemColor: Colors.blue.shade700,
            onTap: controller.onItemTapped,
          )),
    );
  }
}