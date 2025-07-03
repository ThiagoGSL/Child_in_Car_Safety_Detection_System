import 'package:app_v0/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  // O WidgetsFlutterBinding.ensureInitialized() é importante para garantir
  // a inicialização de plugins do Flutter antes da execução do app.
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
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