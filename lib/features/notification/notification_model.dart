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

  // <-- MUDANÇA: Novo método para converter o objeto para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      // Salva a data em um formato de texto padrão (ISO 8601)
      'timestamp': timestamp.toIso8601String(),
      // Salva o enum como texto
      'type': type.name,
    };
  }

  // <-- MUDANÇA: Novo "construtor de fábrica" para criar um objeto a partir de um mapa JSON.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      message: json['message'] ?? 'Mensagem inválida',
      // Converte o texto de volta para DateTime
      timestamp: DateTime.parse(json['timestamp']),
      // Converte o texto de volta para o enum NotificationType
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info, // Valor padrão em caso de erro
      ),
    );
  }
}