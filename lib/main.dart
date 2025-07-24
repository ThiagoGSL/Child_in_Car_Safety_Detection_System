import 'dart:async';
import 'dart:ui';

import 'package:app_v0/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

const int FOREGROUND_SERVICE_NOTIFICATION_ID = 100;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  print('BACKGROUND SERVICE: Isolate iniciado.');

  await GetStorage.init();
  final box = GetStorage();

  if (box.read('currentState') == null) {
    box.write('currentState', 'Serviço Iniciado');
  }

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

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: FOREGROUND_SERVICE_NOTIFICATION_ID,
        channelKey: 'safebaby_service_channel',
        title: 'SafeBaby: $currentState',
        body: 'Monitoramento ativo. Verificado às ${now.hour}:${now.minute}:${now.second}',
        notificationLayout: NotificationLayout.Default,
        locked: true,
        autoDismissible: false,
      ),
    );

  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await GetStorage.init();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
      autoStart: true,
      notificationChannelId: 'safebaby_service_channel',
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
