import 'package:app_v0/features/notification/notification_model.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  var notifications = <AppNotification>[].obs;
  // <-- MUDANÇA: Adiciona um contador para notificações não lidas.
  var unreadCount = 0.obs;

  /// Adiciona uma nova notificação e incrementa o contador.
  void addNotification(String message, NotificationType type) {
    final newNotification = AppNotification(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    notifications.insert(0, newNotification);
    // <-- MUDANÇA: Incrementa o contador de não lidas.
    unreadCount.value++;
  }

  /// <-- MUDANÇA: Novo método para zerar o contador quando o usuário vê as notificações.
  void markNotificationsAsRead() {
    unreadCount.value = 0;
  }

  /// Limpa o histórico e também zera o contador.
  void clearNotifications() {
    notifications.clear();
    // <-- MUDANÇA: Zera o contador ao limpar.
    unreadCount.value = 0;
  }
}