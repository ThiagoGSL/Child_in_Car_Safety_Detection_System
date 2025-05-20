import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
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

