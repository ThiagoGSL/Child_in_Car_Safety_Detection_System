// lib/features/services/notification_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../features/cadastro/form_controller.dart';
import 'package:get/get.dart';

class NotificationService {
  static const _platform = MethodChannel('com.seuapp.sms/send');

  /// Callback global para ações de notificação (quando o usuário interage).
  /// DEVE TER @pragma('vm:entry-point')
  @pragma('vm:entry-point') // ADICIONE ESTA LINHA
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    if (action.buttonKeyPressed == 'CONFIRM_OK') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checkinConfirmed', true);
      await AwesomeNotifications().cancel(0);
    }
  }

  /// Callback global para quando uma notificação é exibida.
  /// DEVE TER @pragma('vm:entry-point')
  @pragma('vm:entry-point') // ADICIONE ESTA LINHA
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification notification) async {
    print('DEBUG: Notificação exibida. ID: ${notification.id}, Canal: ${notification.channelKey}');

    // Verifica se a notificação exibida é a de alerta de perigo
    if (notification.channelKey == 'alert_channel') {
      print('DEBUG: É uma notificação de alerta. Chamando _sendEmergencySms...');
      await _sendEmergencySms(); // Chama o envio do SMS aqui
    }
  }

  /// Exibe a notificação de check-in.
  static Future<void> showCheckinNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'checkin_channel',
        title: '⚠️ Veículo parado',
        body: 'Seu veículo está parado há 30 segundos. Tudo OK?',
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'CONFIRM_OK',
          label: 'Tudo OK',
          autoDismissible: true,
        ),
      ],
    );
  }

  /// Exibe a notificação de perigo/alerta de emergência.
  static Future<void> showDangerNotification() async {
    // Apenas cria e exibe a notificação.
    // O envio do SMS será tratado pelo onNotificationDisplayedMethod.
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'alert_channel',
        title: '🚨 Alerta de Emergência!',
        body: 'Nenhuma resposta recebida. Alerta de emergência ativado.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  /// Envia um SMS de alerta para o número de emergência cadastrado.
  static Future<void> _sendEmergencySms() async {
    print('DEBUG: _sendEmergencySms iniciado.');
    try {
      final formController = Get.find<FormController>();
      print('DEBUG: FormController encontrado.');
      final emergencyNumber = formController.emergencyPhoneNumber;

      print('DEBUG: Número de emergência obtido: $emergencyNumber');

      if (emergencyNumber.isNotEmpty) {
        print('DEBUG: Número de emergência NÃO está vazio. Tentando enviar SMS...');
        final result = await _platform.invokeMethod<String>(
          'sendSms',
          {'number': emergencyNumber, 'message': '🚨 Alerta: Bebe em perigo! Verifique agora.'},
        );
        print('Resultado do envio de SMS: $result');
      } else {
        print('Nenhum número de emergência cadastrado para enviar SMS.');
      }
    } on PlatformException catch (e) {
      print("Falha ao enviar SMS (PlatformException): '${e.message}'.");
    } catch (e) {
      print("Erro inesperado ao enviar SMS (Catch All): $e");
    }
    print('DEBUG: _sendEmergencySms finalizado.');
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