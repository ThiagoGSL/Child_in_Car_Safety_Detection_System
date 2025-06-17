// Enum para categorizar as notificações e facilitar a exibição (ícones/cores)
enum NotificationType {
  connected,
  disconnected,
  photoReceived,
  info,
  error,
}

class AppNotification {
  final String message;
  final DateTime timestamp;
  final NotificationType type;

  AppNotification({
    required this.message,
    required this.timestamp,
    required this.type,
  });
}