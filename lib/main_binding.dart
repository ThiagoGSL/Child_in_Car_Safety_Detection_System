import 'package:get/get.dart';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/notification/notification_controller.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:app_v0/main_page/main_page_controller.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    // Injeta todos os controllers que precisam estar disponíveis globalmente.
    // O uso de 'permanent: true' garante que eles não sejam removidos
    // da memória durante o ciclo de vida do aplicativo.
    Get.put(PhotoController(), permanent: true);
    Get.put(FormController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(MainPageController(), permanent: true);
    Get.put(BluetoothController(), permanent: true);
  }
}