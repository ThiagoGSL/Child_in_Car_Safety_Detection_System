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
    final NotificationController notificationController =
        Get.find<NotificationController>();

    const Color primaryColor = Color(0xFF53A194);
    const Color secondaryColor = Color(0xFFE5E0D2);
    const Color textColor = Color(0xFF524F42);

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        leading: Obx(() {
          bool shouldShowBack =
              (controller.selectedIndex.value == 2) &&
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
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Substituído o ícone pelo logo da aplicação
                Image.asset('lib/assets/logoMarrom.png', height: 40),
                const SizedBox(width: 8),
                Text('SafeBaby', style: TextStyle(color: textColor)),
              ],
            );
          }
          return Text(
            controller.appBarTitle.value,
            style: TextStyle(color: textColor),
          );
        }),
        centerTitle: true,
        backgroundColor: secondaryColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          Obx(() {
            bool showClearButton =
                controller.selectedIndex.value == 1 &&
                notificationController.notifications.isNotEmpty;

            if (showClearButton) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpar notificações',
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Limpar Histórico',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Deseja realmente apagar todas as notificações? Esta ação não pode ser desfeita.',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            notificationController.clearNotifications();
                            Get.back();
                          },
                          child: Text(
                            'Excluir',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
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
          child: controller.widgetOptions.elementAt(
            controller.selectedIndex.value,
          ),
        );
      }),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          backgroundColor: secondaryColor,
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: textColor.withOpacity(0.6),
          selectedItemColor: primaryColor,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
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
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: secondaryColor, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            '${notificationController.unreadCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Notificações',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Configurações',
            ),
          ],
          currentIndex: controller.selectedIndex.value,
          onTap: controller.onItemTapped,
        ),
      ),
    );
  }
}
