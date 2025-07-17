// lib/features/notification_ext/notification_controller_ext.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';

// --- DEFINIÇÃO DAS CHAVES DOS BOTÕES PARA AS NOVAS NOTIFICAÇÕES ---
const String KEY_AWARE_YES = 'AWARE_YES';
const String KEY_AWARE_NO_BABY = 'AWARE_NO_BABY';
const String KEY_CONN_LOSS_AWARE_YES = 'CONN_LOSS_AWARE_YES';
const String KEY_REMINDER_YES = 'REMINDER_YES';
const String KEY_REMINDER_NO = 'REMINDER_NO';
const String KEY_ALERT_CONFIRMED_OK = 'ALERT_CONFIRMED_OK';

// --- CLASSES PARA POPUP REATIVO NA HOME ---
class NotificationPopupData {
  final String title;
  final String message;
  final List<NotificationPopupButton> buttons;
  NotificationPopupData({required this.title, required this.message, required this.buttons});
}

class NotificationPopupButton {
  final String label;
  final VoidCallback onPressed;
  NotificationPopupButton({required this.label, required this.onPressed});
}

// --- onActionReceivedMethod ATUALIZADO PARA LIDAR COM TODOS OS BOTÕES ---
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  final prefs = await SharedPreferences.getInstance();

  // O switch é necessário para lidar com os múltiplos botões das novas notificações
  switch (receivedAction.buttonKeyPressed) {
  // Respostas para os novos fluxos
    case KEY_AWARE_YES:
    case KEY_AWARE_NO_BABY:
    case KEY_CONN_LOSS_AWARE_YES:
    case KEY_REMINDER_YES:
    case KEY_REMINDER_NO:
      await prefs.setString('user_response', receivedAction.buttonKeyPressed);
      break;

  // Lógica do botão do check-in antigo (mantida para compatibilidade)
    case 'USER_CONFIRMED_OK':
      await prefs.setBool('isCheckinConfirmed', true);
      break;

  // Botão da notificação de alerta final
    case KEY_ALERT_CONFIRMED_OK:
    // Nenhuma ação lógica necessária, só fecha a notificação
      break;
  }
}

@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
  print('Notificação ${receivedNotification.id} exibida no celular.');
}

class NotificationExtController extends GetxController {

  final isCheckinConfirmed = false.obs; // Mantido para a lógica antiga de check-in
  static const _smsChannel = MethodChannel('com.seuapp.sms/send_direct');
  Timer? _checkinTimer; // Usado para todos os processos com timer
  final Rx<NotificationPopupData?> popupData = Rx<NotificationPopupData?>(null);

  // ======================================================================
  // <<< INÍCIO DA SEÇÃO DE ALERTA (BASEADA NO SEU CÓDIGO FUNCIONAL) >>>
  // ESTA PARTE NÃO FOI ALTERADA, APENAS O BOTÃO 'OK' FOI ADICIONADO.
  // ======================================================================

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
    // Mensagem de alerta atualizada para ser mais informativa
    final message = 'Alerta!! Seu bebê foi esquecido. Por favor, verifique imadiatamente. ';
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
        // --- ÚNICA MUDANÇA: ADICIONADO O BOTÃO 'OK' ---
        actionButtons: [
          NotificationActionButton(key: KEY_ALERT_CONFIRMED_OK, label: 'OK')
        ]
    );
  }

  // ======================================================================
  // <<< FIM DA SEÇÃO DE ALERTA RESTAURADA >>>
  // ======================================================================


  // --- NOVAS FUNÇÕES DE NOTIFICAÇÃO ADICIONADAS ABAIXO ---

  /// NOTIFICAÇÃO 1: Pergunta inicial sobre o bebê.
  Future<String?> askIfBabyIsPresent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_response');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(id: 11, channelKey: 'checkin_channel', title: 'Bebê a Bordo?', body: 'Detectamos um bebê no seu carro. Está ciente?', locked: true),
      actionButtons: [
        NotificationActionButton(key: KEY_AWARE_YES, label: 'Sim'),
        NotificationActionButton(key: KEY_AWARE_NO_BABY, label: 'Não tem Bebê'),
      ],
    );

    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final response = prefs.getString('user_response');
      if (response != null) {
        await AwesomeNotifications().cancel(11);
        return response;
      }
    }
    await AwesomeNotifications().cancel(11);
    return null;
  }

  /// NOTIFICAÇÃO 2: Processo de perda de conexão com timer.
  void startConnectionLossProcess({
    required VoidCallback onAware, required VoidCallback onNoBaby, required VoidCallback onTimeout, Function(int secondsRemaining)? onTick,
  }) {
    _checkinTimer?.cancel();
    SharedPreferences.getInstance().then((p) => p.remove('user_response'));

    AwesomeNotifications().createNotification(
      content: NotificationContent(id: 12, channelKey: 'checkin_channel', title: '⚠️ Perda de Conexão!', body: 'Meu último dado é que seu bebê está no carro, está ciente?', locked: true),
      actionButtons: [
        NotificationActionButton(key: KEY_CONN_LOSS_AWARE_YES, label: 'Sim'),
        NotificationActionButton(key: KEY_AWARE_NO_BABY, label: 'Não tem Bebê'),
      ],
    );

    const countdownSeconds = 30;
    _checkinTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final p = await SharedPreferences.getInstance();
      final response = p.getString('user_response');

      if (response == KEY_CONN_LOSS_AWARE_YES) {
        timer.cancel(); onAware();
      } else if (response == KEY_AWARE_NO_BABY) {
        timer.cancel(); onNoBaby();
      } else if (timer.tick < countdownSeconds) {
        onTick?.call(countdownSeconds - timer.tick);
      } else {
        timer.cancel(); onTimeout();
      }
    });
  }

  /// NOTIFICAÇÃO 3: Processo de lembrete.
  Future<String?> askForReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_response');
    await AwesomeNotifications().createNotification(
      content: NotificationContent(id: 13, channelKey: 'checkin_channel', title: 'Relembrando...', body: 'Seu bebê está no carro. Gostaria de ser relembrado novamente?'),
      actionButtons: [
        NotificationActionButton(key: KEY_REMINDER_YES, label: 'Sim, me lembre'),
        NotificationActionButton(key: KEY_REMINDER_NO, label: 'Não precisa'),
      ],
    );

    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final response = prefs.getString('user_response');
      if (response != null) { return response; }
    }
    return null;
  }

  void startReminderLoop({required VoidCallback onReminderDue}) {
    _checkinTimer?.cancel();
    _checkinTimer = Timer(const Duration(minutes: 5), () { onReminderDue(); });
  }

  void showInitialPopup({VoidCallback? onYes, VoidCallback? onNoBaby}) {
    popupData.value = NotificationPopupData(
      title: 'Bebê a Bordo?',
      message: 'Detectamos um bebê no seu carro. Está ciente?',
      buttons: [
        NotificationPopupButton(label: 'Sim', onPressed: () {
          onYes?.call();
          popupData.value = null;
        }),
        NotificationPopupButton(label: 'Não tem Bebê', onPressed: () {
          onNoBaby?.call();
          popupData.value = null;
        }),
      ],
    );
  }

  void showConnectionLossPopup({VoidCallback? onYes, VoidCallback? onNoBaby}) {
    popupData.value = NotificationPopupData(
      title: '⚠️ Perda de Conexão!',
      message: 'Meu último dado é que seu bebê está no carro, está ciente?',
      buttons: [
        NotificationPopupButton(label: 'Sim', onPressed: () {
          onYes?.call();
          popupData.value = null;
        }),
        NotificationPopupButton(label: 'Não tem Bebê', onPressed: () {
          onNoBaby?.call();
          popupData.value = null;
        }),
      ],
    );
  }

  void showAlertPopup({VoidCallback? onOk}) {
    popupData.value = NotificationPopupData(
      title: '🚨 ALERTA DE EMERGÊNCIA 🚨',
      message: 'Ação de emergência reportada e SMS enviado para contato.',
      buttons: [
        NotificationPopupButton(label: 'OK', onPressed: () {
          onOk?.call();
          popupData.value = null;
        }),
      ],
    );
  }

  // --- MÉTODOS DE UTILIDADE E INICIALIZAÇÃO (NÃO MUDAM) ---

  void cancelAllProcesses() {
    _checkinTimer?.cancel();
  }

  @override
  void onInit() {
    super.onInit();
  }

  void resetCheckinState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isCheckinConfirmed');
    isCheckinConfirmed.value = false;
  }

  Future<void> init() async {
    await AwesomeNotifications().initialize( null,
      [
        NotificationChannel( channelKey: 'checkin_channel', channelName: 'Verificação de Veículo', channelDescription: '...', importance: NotificationImportance.High, playSound: true,),
        NotificationChannel( channelKey: 'alert_channel', channelName: 'Alerta de Emergência', channelDescription: '...', importance: NotificationImportance.Max, playSound: true, defaultColor: Colors.red, ledColor: Colors.white,),
      ],
      debug: true,
    );
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    );
  }
}