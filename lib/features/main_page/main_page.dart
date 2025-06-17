import 'package:app_v0/features/bluetooth/ble_page.dart';
import 'package:app_v0/features/cadastro/form_page.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/photos/photo_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainPageController controller = Get.find<MainPageController>();
    final NotificationController notificationController = Get.find<NotificationController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        leading: Obx(() {
          bool shouldShowBack = (controller.selectedIndex.value == 2) &&
              (controller.showBlePage.value ||
                  controller.showPhotoPage.value ||
                  controller.showFormPage.value);
          if (shouldShowBack) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                if (controller.showBlePage.value) {
                  controller.navigateToBlePage(false);
                } else if (controller.showPhotoPage.value) {
                  controller.navigateToPhotoPage(false);
                } else if (controller.showFormPage.value) {
                  controller.navigateToFormPage(false);
                }
              },
            );
          }
          return const SizedBox.shrink();
        }),
        title: Obx(() {
          if (controller.selectedIndex.value == 0) {
            return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.crib_outlined, size: 24),
                SizedBox(width: 8),
                Text('SafeBaby'),
              ],
            );
          }
          return Text(controller.appBarTitle.value);
        }),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() {
            // CONDIÇÃO ATUALIZADA: Botão só aparece se houver notificações para limpar
            bool showClearButton = controller.selectedIndex.value == 1 && notificationController.notifications.isNotEmpty;

            if (showClearButton) {
              return IconButton(
                // NOVO ÍCONE: Mais sugestivo para "limpar tudo"
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpar notificações',
                onPressed: () {
                  // NOVO: Exibe uma caixa de diálogo para confirmação
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: const Color(0xFF16213E), // Cor de fundo do tema
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Limpar Histórico',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'Deseja realmente apagar todas as notificações? Esta ação não pode ser desfeita.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        // Botão para cancelar a ação
                        TextButton(
                          onPressed: () => Get.back(), // Apenas fecha o diálogo
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                        ),
                        // Botão para confirmar a exclusão
                        TextButton(
                          onPressed: () {
                            notificationController.clearNotifications();
                            Get.back(); // Fecha o diálogo após a exclusão
                          },
                          child: Text(
                            'Excluir',
                            style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            // Mantém o espaço para centralizar o título
            return const SizedBox(width: 48);
          }),
        ],
      ),
      body: Obx(() {
        if (controller.selectedIndex.value == 2) {
          if (controller.showBlePage.value) {
            return BlePage();
          }
          if (controller.showPhotoPage.value) {
            return PhotoPage();
          }
          if (controller.showFormPage.value) {
            return FormPage();
          }
        }
        return Center(
          child: controller.widgetOptions.elementAt(controller.selectedIndex.value),
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            backgroundColor: const Color(0xFF16213E),
            type: BottomNavigationBarType.fixed,
            unselectedItemColor: Colors.white54,
            selectedItemColor: const Color(0xFF53BF9D),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notificationController.unreadCount.value > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF16213E), width: 1.5),
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
                activeIcon: const Icon(Icons.notifications),
                label: 'Notificações',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Configurações'),
            ],
            currentIndex: controller.selectedIndex.value,
            onTap: controller.onItemTapped,
          )),
    );
  }
}