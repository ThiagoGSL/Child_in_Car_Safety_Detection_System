import 'package:app_v0/main_page/main_page.dart';
import 'package:get/get.dart';

class SplashPageController extends GetxController {
  
  void goToHome() async {
    await Future.delayed(Duration(seconds: 5)); // espera 3 segundos
    Get.off(() => MainPage()); // navega para a HomePage e remove a SplashPage da pilha
  }

  @override
  void onInit() {
    super.onInit();
    goToHome(); // chama automaticamente ao iniciar
  }
}
