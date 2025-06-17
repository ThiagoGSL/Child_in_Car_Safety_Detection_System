import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/notification/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  // Este widget não tem 'const' no construtor para ser consistente
  // com a lista de widgets não-constante no MainPageController.
  NotificationPage({super.key});

  final NotificationController controller = Get.find<NotificationController>();

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
    // Este widget não tem Scaffold ou AppBar próprios.
    // Ele é o "corpo" que será exibido pela MainPage, que controla a AppBar.
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
          // Formata a data e hora para exibição, ex: "13:35:40 17/06/2025"
          final formattedTime = DateFormat('HH:mm:ss dd/MM/yyyy').format(notification.timestamp);

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
            ),
          );
        },
      );
    });
  }
}