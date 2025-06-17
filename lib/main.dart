import 'package:app_v0/features/splash/splash_page.dart';
import 'package:app_v0/main_binding.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  // O WidgetsFlutterBinding.ensureInitialized() é importante para garantir
  // a inicialização de plugins do Flutter antes da execução do app.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Meu App',
      theme: ThemeData(primarySwatch: Colors.blue),

      // Use o initialBinding injeta todas as dependências globais
      // antes que qualquer tela seja construída.
      initialBinding: MainBinding(),

      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}