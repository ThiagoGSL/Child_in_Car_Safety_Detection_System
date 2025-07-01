import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  /// Callback global para ações de notificação.
  /// Deve ser definido como `@pragma('vm:entry-point')` no `main.dart`.
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    if (action.buttonKeyPressed == 'CONFIRM_OK') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checkinConfirmed', true);
      await AwesomeNotifications().cancel(0); // Cancela a notificação de check-in (ID 0)
    }
  }

  /// Exibe a notificação de check-in.
  static Future<void> showCheckinNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0, // ID 0 para a notificação de check-in
        channelKey: 'checkin_channel',
        title: '⚠️ Veículo parado',
        body: 'Seu veículo está parado há 30 segundos. Tudo OK?',
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false, // Não permite que seja dispensada deslizando
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'CONFIRM_OK',
          label: 'Tudo OK',
          autoDismissible: true, // Ação fecha a notificação
        ),
      ],
    );
  }

  /// Exibe a notificação de perigo/alerta de emergência.
  static Future<void> showDangerNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1, // ID 1 para a notificação de alerta
        channelKey: 'alert_channel',
        title: '🚨 Alerta de Emergência!',
        body: 'Nenhuma resposta recebida. Alerta de emergência ativado.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  /// Cancela a notificação de alerta de perigo (ID 1).
  static Future<void> cancelDangerNotification() async {
    await AwesomeNotifications().cancel(1);
  }

  /// Cancela todas as notificações.
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}