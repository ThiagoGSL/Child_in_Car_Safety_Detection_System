import 'dart:async';
import 'dart:ui';

import 'package:app_v0/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// O import 'flutter_background_service_android' já não é necessário aqui.
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

// Importa a biblioteca para criar o canal de notificação
import 'package:awesome_notifications/awesome_notifications.dart';

const int FOREGROUND_SERVICE_NOTIFICATION_ID = 100;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Garante que os plugins estão disponíveis neste isolate.
  DartPluginRegistrant.ensureInitialized();

  print('BACKGROUND SERVICE: Isolate iniciado.');

  await GetStorage.init();
  final box = GetStorage();

  // Garante que sempre haverá um estado inicial
  if (box.read('currentState') == null) {
    box.write('currentState', 'Serviço Iniciado');
  }

  // Listener para parar o serviço
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listener para receber o estado da UI
  service.on('updateState').listen((event) {
    if (event != null && event['state'] != null) {
      final newState = event['state'];
      box.write('currentState', newState);
      print('BACKGROUND: Estado recebido e salvo -> $newState');
    }
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    final now = DateTime.now();
    await box.write('last_run', now.toIso8601String());

    final currentState = box.read('currentState') ?? 'Aguardando...';

    // ===================================================================
    // <<< NOVA LÓGICA DE NOTIFICAÇÃO USANDO AWESOME NOTIFICATIONS >>>
    // Cria e atualiza a notificação persistente.
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: FOREGROUND_SERVICE_NOTIFICATION_ID, // ID Fixo para que a notificação seja atualizada
        channelKey: 'safebaby_service_channel', // O mesmo canal criado no main()
        title: 'SafeBaby: $currentState',
        body: 'Monitoramento ativo. Verificado às ${now.hour}:${now.minute}:${now.second}',
        notificationLayout: NotificationLayout.Default,
        locked: true, // Mantém a notificação persistente
        autoDismissible: false, // Impede que o utilizador a remova
      ),
    );
    // ===================================================================

    print('BACKGROUND SERVICE: Estado atual é "$currentState" em $now');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  // Inicializa o awesome_notifications e cria o canal ANTES de tudo.
  // Isto é crucial para garantir que o canal existe.
  await AwesomeNotifications().initialize(
    'resource://drawable/ic_bg_service_small',
    [
      NotificationChannel(
        channelKey: 'safebaby_service_channel',
        channelName: 'Serviço SafeBaby',
        channelDescription: 'Canal de notificação para o serviço de monitoramento.',
        defaultColor: const Color(0xFF53BF9D),
        ledColor: Colors.white,
        importance: NotificationImportance.Low,
        channelShowBadge: false,
        locked: true,
      )
    ],
    debug: true,
  );
  // ===================================================================

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await GetStorage.init();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      // Continua a ser 'true' para o SO não matar o serviço.
      isForegroundMode: false,
      autoStart: true,
      // O ID do canal aqui DEVE ser exatamente o mesmo que o 'channelKey' acima.
      notificationChannelId: 'safebaby_service_channel',
      // Estes são agora apenas um fallback para a notificação inicial.
      initialNotificationTitle: 'SafeBaby',
      initialNotificationContent: 'A iniciar o serviço de monitoramento...',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SafeBaby',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
