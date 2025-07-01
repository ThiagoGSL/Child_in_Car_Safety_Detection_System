// lib/main.dart
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/splash/splash_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:get/get.dart';
import 'features/notification_ext/notification_controller_ext.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Solicitar permissões
  await Permission.notification.request();
  await Permission.location.request();
  await Permission.sms.request(); // <-- ADICIONADO
  await Permission.phone.request();

  Get.lazyPut<FormController>(() => FormController());
  final notifController = Get.put(NotificationExtController());
  await notifController.init();

  runApp(const App());
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