import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/splash/splash_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:get/get.dart';
import 'features/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Solicitar permissões
  await Permission.notification.request();
  await Permission.location.request();

  // Inicializar notificações
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'checkin_channel',
        channelName: 'Check-In',
        channelDescription: 'Canal de check-in',
        importance: NotificationImportance.High,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'alert_channel',
        channelName: 'Alerta de Perigo',
        channelDescription: 'Canal de alerta',
        importance: NotificationImportance.Max,
        playSound: true,
      ),
    ],
    debug: true,
  );

  // Definir listener global de ações de notificação
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationService.onActionReceivedMethod, // Usando o método do serviço
  );

  Get.lazyPut<FormController>(() => FormController());
  runApp(App());

}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Meu App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

