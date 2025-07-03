// lib/features/notification_ext/notification_controller_ext.dart

// 1. IMPORTS NECESSÁRIOS PARA AS NOVAS FUNÇÕES
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports que você já tinha
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';

// Funções de callback de background (não mudam)
@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
  print('Notificação ${receivedNotification.id} exibida no celular.');
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.buttonKeyPressed == 'USER_CONFIRMED_OK') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCheckinConfirmed', true);
    // Esta linha foi removida em uma etapa anterior para evitar conflito,
    // o cancelamento da notificação de check-in é melhor gerenciado pela UI ou pelo processo.
    // await AwesomeNotifications().cancel(10);
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

  // Suas variáveis de estado e canais (não mudam)
  final isCheckinConfirmed = false.obs;
  static const _smsChannel = MethodChannel('com.seuapp.sms/send_direct');

  // 2. ADIÇÃO DA VARIÁVEL PARA CONTROLAR O TIMER DO CHECK-IN
  Timer? _checkinTimer;

  // Suas funções de alerta e SMS (não mudam)
  Future<void> triggerFullEmergencyAlert() async {
    final bool smsSuccess = await sendPureSms();
    if (smsSuccess) {
      await Future.delayed(const Duration(milliseconds: 500));
      await showEmergencyAlertNotification();
    } else {
      print("Fluxo de alerta interrompido pois o envio de SMS falhou.");
    }
  }

  Future<bool> sendPureSms() async {
    final FormController formController = Get.find();
    final number = formController.emergencyPhone.value;
    if (number.isEmpty) {
      print('Erro no Controller: Número de emergência não configurado.');
      return false;
    }
    final message = 'Mensagem de teste puro.';
    try {
      print("Controller chamando o canal nativo para enviar SMS para: $number");
      final result = await _smsChannel.invokeMethod('send', {
        'number': number,
        'message': message,
      });
      print("Controller recebeu o resultado do canal nativo: $result");
      return true;
    } on PlatformException catch (e) {
      print("Controller encontrou um erro ao chamar canal nativo: ${e.message}");
      return false;
    }
  }

  Future<void> showEmergencyAlertNotification() async {
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

  // Seus métodos de inicialização e estado (não mudam)
  @override
  void onInit() {
    super.onInit();
    // A sincronização agora é feita pela UI/Máquina de Estados quando necessário
    // _loadCheckinConfirmationFromPrefs(); foi removido corretamente.
  }

  void resetCheckinState() async {
    final prefs = await SharedPreferences.getInstance();
    // Limpa tanto o flag persistente quanto a variável reativa
    await prefs.remove('isCheckinConfirmed');
    isCheckinConfirmed.value = false;
  }

  Future<void> init() async {
    // ... seu código de inicialização do AwesomeNotifications não muda ...
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'checkin_channel',
          channelName: 'Verificação de Veículo',
          channelDescription: '...',
          importance: NotificationImportance.High,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'alert_channel',
          channelName: 'Alerta de Emergência',
          channelDescription: '...',
          importance: NotificationImportance.Max,
          playSound: true,
          defaultColor: Colors.red,
          ledColor: Colors.white,
        ),
      ],
      debug: true,
    );
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    );
  }

  // Sua função de criar a notificação de check-in (não muda)
  Future<void> showCheckinNotification() async {
    // Apenas garante que a flag do processo anterior seja limpa
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

  // 3. ADIÇÃO DOS NOVOS MÉTODOS PARA GERENCIAR O PROCESSO DE CHECK-IN

  /// Inicia o processo de check-in com contagem regressiva.
  /// Notifica o chamador (sua máquina de estados) sobre o resultado através de callbacks.
  void startCheckinProcess({
    required int countdownSeconds,
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
    Function(int secondsRemaining)? onTick,
  }) {
    _checkinTimer?.cancel();
    resetCheckinState();

    showCheckinNotification();

    _checkinTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      final isConfirmedByClick = prefs.getBool('isCheckinConfirmed') ?? false;

      if (isConfirmedByClick) {
        timer.cancel();
        await prefs.remove('isCheckinConfirmed');
        onSuccess();
      }
      else if (timer.tick < countdownSeconds) {
        final secondsRemaining = countdownSeconds - timer.tick;
        onTick?.call(secondsRemaining);
      }
      else {
        timer.cancel();
        onFailure();
      }
    });
  }

  /// Permite que a máquina de estados cancele o processo de check-in a qualquer momento.
  /// (Ex: se o carro voltar a se mover).
  void cancelCheckinProcess() {
    _checkinTimer?.cancel();
    print("Processo de check-in cancelado externamente.");
  }

  // Sua função de cancelar todas as notificações (não muda)
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}