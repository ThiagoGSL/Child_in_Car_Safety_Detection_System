import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/notification/notification_model.dart';
import 'package:app_v0/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  // Mapeia o tipo de notificação para um ícone e cor específicos.
  Widget _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.connected:
        return Icon(Icons.bluetooth_connected, color: Colors.green.shade700);
      case NotificationType.disconnected:
        return Icon(Icons.bluetooth_disabled, color: Colors.red.shade700);
      case NotificationType.photoReceived:
        return Icon(Icons.photo_camera, color: Colors.blue.shade700);
      case NotificationType.error:
        return Icon(Icons.error_outline, color: Colors.orange.shade700);
      default:
        return Icon(Icons.info_outline, color: Colors.grey.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {

    final NotificationController controller = Get.find<NotificationController>();
    final MainPageController mainPageController = Get.find<MainPageController>();
    return Obx(() {
      if (controller.notifications.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhuma notificação ainda.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          final formattedTime = DateFormat('HH:mm:ss dd/MM/yyyy').format(notification.timestamp);

          // Determina se a notificação é clicável para mostrar a seta
          bool isClickable = notification.type == NotificationType.connected ||
                              notification.type == NotificationType.disconnected ||
                              notification.type == NotificationType.photoReceived;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: _getIconForType(notification.type),
              title: Text(notification.message),
              subtitle: Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              // Mostra a seta apenas para itens clicáveis
              trailing: isClickable ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null,
              // <-- MUDANÇA: Adiciona a lógica de clique (onTap)
              onTap: () {
                switch (notification.type) {
                  // Caso seja uma notificação de conexão ou desconexão...
                  case NotificationType.connected:
                  case NotificationType.disconnected:
                    Get.back(); // 1. Fecha a página de notificações
                    mainPageController.onItemTapped(2); // 2. Vai para a aba "Configurações"
                    mainPageController.navigateToBlePage(true); // 3. Mostra a sub-página de Bluetooth
                    break;
                  
                  // Caso seja uma notificação de foto recebida...
                  case NotificationType.photoReceived:
                    Get.back(); // 1. Fecha a página de notificações
                    mainPageController.onItemTapped(2); // 2. Vai para a aba "Configurações"
                    mainPageController.navigateToPhotoPage(true); // 3. Mostra a sub-página de Logs/Foto
                    break;

                  // Para outros tipos de notificação, não faz nada.
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