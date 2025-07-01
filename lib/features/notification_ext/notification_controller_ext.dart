import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_v0/features/cadastro/form_controller.dart'; // Importe seu FormController

// Funções de callback de background
@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
  print('Notificação ${receivedNotification.id} exibida no celular.');
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
  final isCheckinConfirmed = false.obs;
  static const _smsChannel = MethodChannel('com.seuapp.sms/send_direct');

  /// NOTIFICAÇÃO DE ALERTA
  Future<void> triggerFullEmergencyAlert() async {
    //print("Iniciando fluxo de alerta completo...");

    // 1. Tenta enviar o SMS primeiro.
    final bool smsSuccess = await sendPureSms();

    // 2. Se o envio do SMS foi despachado com sucesso, mostra a notificação.
    if (smsSuccess) {
      //print("Comando de SMS enviado. Exibindo notificação de alerta.");

      // Adicionamos uma pequena pausa para garantir que o sistema operacional
      // não se sobrecarregue, dando um "respiro" entre as duas ações.
      await Future.delayed(const Duration(milliseconds: 500));

      await showEmergencyAlertNotification();
    } else {
      //print("Fluxo de alerta interrompido pois o envio de SMS falhou.");
    }
  }

  /// Método para enviar SMS
  Future<bool> sendPureSms() async {
    final FormController formController = Get.find();
    final number = formController.emergencyPhone.value;
    if (number.isEmpty) {
      print('Erro no Controller: Número de emergência não configurado.');
      return false;
    }
    /// MENSAGEM QUE APARECE NO SMS
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

  // Método para mostrar a notificação de alerta
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

  // --- O resto do seu controller ---
  @override
  void onInit() {
    super.onInit();
    _loadCheckinConfirmationFromPrefs();
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

  Future<void> init() async {
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
  /// CANCELA TODAS AS NOTIFICAÇÕES
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}