import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/notification/notification_model.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  final Color primaryColor = const Color(0xFF53A194);
  final Color secondaryColor = const Color(0xFFE5E0D2);
  final Color textColor = const Color(0xFF524F42);
  final Color tileBackgroundColor = const Color(0xFFF0EAE1);

  Widget _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.connected:
        return Icon(Icons.bluetooth_connected, color: primaryColor);
      case NotificationType.disconnected:
        return Icon(Icons.bluetooth_disabled, color: Colors.red.shade600);
      case NotificationType.photoReceived:
        return Icon(Icons.photo_camera_outlined, color: primaryColor);
      case NotificationType.error:
        return Icon(Icons.error_outline, color: Colors.red.shade600);
      default:
        return Icon(Icons.info_outline, color: textColor.withOpacity(0.5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationController controller =
        Get.find<NotificationController>();
    final MainPageController mainPageController =
        Get.find<MainPageController>();

    return Scaffold(
      backgroundColor: secondaryColor,
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 60,
                  color: textColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma notificação ainda.',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final formattedTime = DateFormat(
              'HH:mm:ss dd/MM/yyyy',
            ).format(notification.timestamp);

            bool isClickable =
                notification.type == NotificationType.connected ||
                notification.type == NotificationType.disconnected ||
                notification.type == NotificationType.photoReceived;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                leading: _getIconForType(notification.type),
                title: Text(
                  notification.message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                trailing:
                    isClickable
                        ? Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: textColor.withOpacity(0.3),
                        )
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
      }),
    );
  }
}
