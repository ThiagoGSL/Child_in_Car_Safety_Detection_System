import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/notification/notification_model.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  // MODIFICADO: Paleta de cores dos ícones atualizada para o tema escuro
  Widget _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.connected:
        // Cor de destaque do tema
        return const Icon(Icons.bluetooth_connected, color: Color(0xFF53BF9D));
      case NotificationType.disconnected:
        // Laranja para alertas
        return Icon(Icons.bluetooth_disabled, color: Colors.red.shade600);
      case NotificationType.photoReceived:
        // Branco para um visual limpo
        return const Icon(Icons.photo_camera_outlined, color: Colors.white70);
      case NotificationType.error:
        // Vermelho para erros
        return Icon(Icons.error_outline, color: Colors.red.shade600);
      default:
        return const Icon(Icons.info_outline, color: Colors.white38);
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.find<NotificationController>();
    final MainPageController mainPageController = Get.find<MainPageController>();

    return Obx(() {
      // MODIFICADO: Estilo da tela de "nenhuma notificação" para o tema escuro
      if (controller.notifications.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                'Nenhuma notificação ainda.',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ],
          ),
        );
      }

      // MODIFICADO: A lista agora tem um padding mais adequado
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          final formattedTime = DateFormat('HH:mm:ss dd/MM/yyyy').format(notification.timestamp);

          bool isClickable = notification.type == NotificationType.connected ||
                              notification.type == NotificationType.disconnected ||
                              notification.type == NotificationType.photoReceived;

          // MODIFICADO: Substituído o Card por um Container estilizado para o tema escuro
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E), // Fundo azul escuro para o item
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: _getIconForType(notification.type),
              // MODIFICADO: Estilos de texto para o tema escuro
              title: Text(
                notification.message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                formattedTime,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              trailing: isClickable
                  ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38)
                  : null,
              onTap: () {
                switch (notification.type) {
                  case NotificationType.connected:
                  case NotificationType.disconnected:
                    Get.back();
                    mainPageController.onItemTapped(2);
                    mainPageController.navigateToBlePage(true);
                    break;
                  case NotificationType.photoReceived:
                    Get.back();
                    mainPageController.onItemTapped(2);
                    mainPageController.navigateToPhotoPage(true);
                    break;
                  case NotificationType.info:
                  case NotificationType.error:
                }
              },
            ),
          );
        },
      );
    });
  }
}