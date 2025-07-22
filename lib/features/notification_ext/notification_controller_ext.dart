// lib/features/notification_ext/notification_controller_ext.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // <<< IMPORT ADICIONADO PARA CORRIGIR O ERRO 'Colors'
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';

// --- CHAVES DE BOTÃO E RESPOSTAS ---
const String KEY_AWARE_YES = 'AWARE_YES';
const String KEY_AWARE_NO_BABY = 'AWARE_NO_BABY';
const String KEY_CONN_LOSS_AWARE_YES = 'CONN_LOSS_AWARE_YES';
const String KEY_REMINDER_YES = 'REMINDER_YES';
const String KEY_REMINDER_NO = 'REMINDER_NO';
const String KEY_ALERT_CONFIRMED_OK = 'ALERT_CONFIRMED_OK';

// --- CALLBACK DE BACKGROUND (LIDANDO COM CLIQUES) ---
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  final prefs = await SharedPreferences.getInstance();
  switch (receivedAction.buttonKeyPressed) {
    case KEY_AWARE_YES:
    case KEY_AWARE_NO_BABY:
    case KEY_CONN_LOSS_AWARE_YES:
    case KEY_REMINDER_YES:
    case KEY_REMINDER_NO:
      await prefs.setString('user_response', receivedAction.buttonKeyPressed);
      break;
    case KEY_ALERT_CONFIRMED_OK:
      break;
  }
}
@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(ReceivedNotification r) async {}


class NotificationExtController extends GetxController {

  static const _smsChannel = MethodChannel('com.seuapp.sms/send_direct');

  // --- SEÇÃO DE ALERTA DE EMERGÊNCIA (CÓDIGO FUNCIONAL MANTIDO) ---
  Future<void> triggerFullEmergencyAlert() async {
    final bool smsSuccess = await sendPureSms();
    if (smsSuccess) {
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      print("SMS falhou.");
    }
    await showEmergencyAlertNotification();
  }

  Future<bool> sendPureSms() async {
    final FormController formController = Get.find();
    final number = formController.emergencyPhone.value;
    if (number.isEmpty) {
      print('Erro no Controller: Número de emergência não configurado.');
      return false;
    }
    final message = 'ALERTA DE SEGURANÇA: Um bebê pode ter sido esquecido no veículo. Por favor, verifique imediatamente.';
    try {
      print("Controller chamando o canal nativo para enviar SMS para: $number");
      await _smsChannel.invokeMethod('send', {'number': number, 'message': message,});
      print("Controller recebeu o resultado do canal nativo");
      return true;
    } on PlatformException catch (e) {
      print("Controller encontrou um erro ao chamar canal nativo: ${e.message}");
      return false;
    }
  }

  Future<void> showEmergencyAlertNotification() async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 20, channelKey: 'alert_channel',
          title: '🚨 ALERTA DE EMERGÊNCIA 🚨',
          body: 'Ação de emergência reportada e SMS enviado para contato.',
          notificationLayout: NotificationLayout.Default, backgroundColor: Colors.red,
        ),
        actionButtons: [
          NotificationActionButton(key: KEY_ALERT_CONFIRMED_OK, label: 'OK')
        ]
    );
  }
  // --- FIM DA SEÇÃO DE ALERTA DE EMERGÊNCIA ---


  // --- MÉTODOS "BURROS" - APENAS MOSTRAM NOTIFICAÇÕES ---

  Future<void> showInitialBabyQuestion() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(id: 11, channelKey: 'checkin_channel', title: 'Bebê a Bordo?', body: 'Detectamos um bebê no seu carro. Está ciente?', locked: true, autoDismissible: false),
      actionButtons: [
        NotificationActionButton(key: KEY_AWARE_YES, label: 'Sim'),
        NotificationActionButton(key: KEY_AWARE_NO_BABY, label: 'Não tem Bebê'),
      ],
    );
  }

  Future<void> showConnectionLossNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(id: 12, channelKey: 'checkin_channel', title: '⚠️ Perda de Conexão!', body: 'Meu último dado é que seu bebê está no carro, está ciente?', locked: true, autoDismissible: false),
      actionButtons: [
        NotificationActionButton(key: KEY_CONN_LOSS_AWARE_YES, label: 'Sim'),
        NotificationActionButton(key: KEY_AWARE_NO_BABY, label: 'Não tem Bebê'),
      ],
    );
  }

  Future<void> showReminderQuestion() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(id: 13, channelKey: 'checkin_channel', title: 'Relembrando...', body: 'Seu bebê está no carro. Gostaria de ser relembrado novamente?'),
      actionButtons: [
        NotificationActionButton(key: KEY_REMINDER_YES, label: 'Sim, me lembre'),
        NotificationActionButton(key: KEY_REMINDER_NO, label: 'Não precisa'),
      ],
    );
  }

  // --- Funções de utilidade e inicialização ---
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> init() async {
    await AwesomeNotifications().initialize( null,
      [
        NotificationChannel(
            channelKey: 'checkin_channel',
            channelName: 'Verificação de Veículo',
            channelDescription: 'Notificações para checagem e lembretes do status do bebê.', // <<< PARÂMETRO ADICIONADO
            importance: NotificationImportance.High,
            playSound: true
        ),
        NotificationChannel(
            channelKey: 'alert_channel',
            channelName: 'Alerta de Emergência',
            channelDescription: 'Notificações críticas de alerta de emergência.', // <<< PARÂMETRO ADICIONADO
            importance: NotificationImportance.Max,
            playSound: true,
            defaultColor: Colors.red, // Agora 'Colors' é reconhecido
            ledColor: Colors.white
        ),
      ],
      debug: true,
    );
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    );
  }
}