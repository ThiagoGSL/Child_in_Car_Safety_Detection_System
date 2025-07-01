import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/check.dart'; // Importa os enums

class CheckinService {
  static Future<void> showCheckinNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'checkin_channel',
        title: '⚠️ Veículo parado',
        body: 'Seu veículo está parado há 30 segundos. Tudo OK?',
      ),
      actionButtons: [
        NotificationActionButton(key: 'CONFIRM_OK', label: 'Tudo OK'),
      ],
    );
  }

}