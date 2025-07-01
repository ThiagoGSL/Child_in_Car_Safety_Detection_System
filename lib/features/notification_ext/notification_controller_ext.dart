// lib/features/notification_ext/notification_ext_controller.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';

// As funções de callback precisam ficar fora da classe para rodar em background.
@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification) async {
  // print('Notificação ${receivedNotification.id} exibida no celular.');
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.buttonKeyPressed == 'USER_CONFIRMED_OK') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCheckinConfirmed', true);
    await AwesomeNotifications().cancel(10);
  }
}


//==============================================================================
//====== GUIA RÁPIDO (README) DE USO DO NOTIFICATIONEXTCONTROLLER ==============
//==============================================================================
///
/// Este controller centraliza o gerenciamento de todas as notificações do app.
///
/// **Pré-requisito:** Certifique-se de que este controller foi inicializado na
/// inicialização do seu app usando `Get.put(NotificationExtController())`.
///
/// ---
///
/// ### 1. Como Disparar o Alerta de Emergência Completo (SMS + Notificação)
///
/// Este é o alerta principal. Ele envia um SMS para o contato de emergência
/// e, em seguida, exibe uma notificação visual para o usuário.
///
/// **Método a ser chamado:** `triggerFullEmergencyAlert()`
///
/// **Exemplo de uso (na sua máquina de estado):**
/// ```dart
/// // Obtém a instância do controller
/// final NotificationExtController notificationController = Get.find();
///
/// // Dispara o fluxo completo de alerta
/// notificationController.triggerFullEmergencyAlert();
/// ```
/// **Importante:** Esta função depende que o `FormController` já tenha carregado
/// o número do contato de emergência.
///
/// ---
///
/// ### 2. Como Disparar a Notificação de Check-in ("Está tudo bem?")
///
/// Esta notificação apenas exibe um alerta visual com um botão de confirmação,
/// sem enviar SMS.
///
/// **Método a ser chamado:** `showCheckinNotification()`
///
/// **Exemplo de uso:**
/// ```dart
/// final NotificationExtController notificationController = Get.find();
/// notificationController.showCheckinNotification();
/// ```
/// **Como saber se o botão foi clicado?**
/// Você pode observar a variável reativa `isCheckinConfirmed` neste controller.
/// Ex: `if (notificationController.isCheckinConfirmed.value) { ... }`
///
//==============================================================================

class NotificationExtController extends GetxController {
  // --- VARIÁVEIS DE ESTADO ---

  final isCheckinConfirmed = false.obs;
  static const _smsChannel = MethodChannel('com.seuapp.sms/send_direct');

  // --- MÉTODOS PÚBLICOS (API do Controller) ---

  /// Orquestra o ALERTA DE EMERGÊNCIA COMPLETO.
  Future<void> triggerFullEmergencyAlert() async {
    final bool smsSuccess = await _sendPureSms();
    if (smsSuccess) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _showAwesomeEmergencyAlert();
    }
  }

  /// Mostra a NOTIFICAÇÃO DE CHECK-IN (pergunta "Está tudo bem?").
  Future<void> showCheckinNotification() async {
    resetCheckinState();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'checkin_channel',
        title: '⚠️ Está tudo bem?',
        body: 'Detectamos que o veículo está parado. Por favor, confirme se está tudo OK.',
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'USER_CONFIRMED_OK',
          label: 'Sim, tudo OK!',
          autoDismissible: true,
        ),
      ],
    );
  }

  /// Cancela TODAS as notificações que este app criou.
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  // --- MÉTODOS INTERNOS E DE INICIALIZAÇÃO ---

  @override
  void onInit() {
    super.onInit();
    _loadCheckinConfirmationFromPrefs();
  }

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'checkin_channel',
          channelName: 'Verificação de Veículo',
          channelDescription: 'Canal para notificações de verificação de segurança.',
          importance: NotificationImportance.High,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'alert_channel',
          channelName: 'Alerta de Emergência',
          channelDescription: 'Canal para alertas visuais de emergência.',
          importance: NotificationImportance.Max,
          playSound: true,
          defaultColor: Colors.red,
          ledColor: Colors.white,
        ),
      ],
      debug: false,
    );
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    );
  }

  Future<bool> _sendPureSms() async {
    final FormController formController = Get.find();
    final number = formController.emergencyPhone.value;
    if (number.isEmpty) {
      return false;
    }
    final message =
        '🚨 Alerta de perigo! Uma atividade incomum foi detectada. Por favor, verifique a situação.';
    try {
      await _smsChannel.invokeMethod('send', {
        'number': number,
        'message': message,
      });
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _showAwesomeEmergencyAlert() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 20,
        channelKey: 'alert_channel',
        title: '🚨 ALERTA DE EMERGÊNCIA 🚨',
        body: 'Ação de emergência reportada e SMS enviado para contato.',
        notificationLayout: NotificationLayout.Default,
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadCheckinConfirmationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isCheckinConfirmed.value = prefs.getBool('isCheckinConfirmed') ?? false;
  }

  void resetCheckinState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCheckinConfirmed', false);
    isCheckinConfirmed.value = false;
  }
}