import 'package:app_v0/features/bluetooth/ble_page.dart';
import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/notification/notification_page.dart';
import 'package:app_v0/features/photos/photo_page.dart';
import 'package:app_v0/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainPageController controller = Get.find<MainPageController>();
    final NotificationController notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          // Condição unificada para mostrar o botão de voltar
          bool shouldShowBack = (controller.selectedIndex.value == 2) && 
                                (controller.showBlePage.value || controller.showPhotoPage.value);

          if (shouldShowBack) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                // Determina para qual página voltar
                if (controller.showBlePage.value) {
                  controller.navigateToBlePage(false);
                } else if (controller.showPhotoPage.value) {
                  controller.navigateToPhotoPage(false);
                }
              },
            );
          }
          // Se não, não mostra nada no leading
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
          // Botão para abrir a página de histórico de notificações
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
            onPressed: () {
              // Navega para a página de notificações como uma nova tela
              Get.to(() => NotificationPage());
            },
          ),
          // Ações contextuais (botão de limpar ou status da bateria)
          Obx(() {
            if (controller.selectedIndex.value == 1) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpar Histórico',
                onPressed: () {
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
        // Lógica para exibir a sub-página correta dentro da aba de Configurações
        if (controller.selectedIndex.value == 2) {
          if (controller.showBlePage.value) {
            return BlePage();
          }
          if (controller.showPhotoPage.value) {
            return PhotoPage();
          }
        }
        // Se nenhuma sub-página estiver ativa, mostra a aba principal selecionada
        return Center(
          child: controller.widgetOptions.elementAt(controller.selectedIndex.value),
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
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