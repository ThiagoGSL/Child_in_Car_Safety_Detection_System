import 'package:app_v0/features/bluetooth/ble_page.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:app_v0/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainPageController controller = Get.put(MainPageController());
    final PhotoController photoController = Get.find<PhotoController>();

    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          if (controller.selectedIndex.value == 2 && controller.showBlePage.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => controller.navigateToBlePage(false),
            );
          }
          if (controller.selectedIndex.value == 1 && photoController.isSelectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: photoController.toggleSelectionMode,
            );
          }
          return const SizedBox.shrink();
        }),
        title: Obx(() => FittedBox(
          fit: BoxFit.contain,
          child: Text(
            controller.appBarTitle.value,
            style: const TextStyle(fontSize: 18.0),
          ),
        )),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Obx(() {
            if (controller.selectedIndex.value == 1) {
              return Obx(() {
                List<Widget> actions = [];
                if (photoController.selectedPhotos.isNotEmpty) {
                  actions.add(
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        _confirmDeleteSelected(Get.context!, photoController);
                      },
                    )
                  );
                }
                actions.add(
                  TextButton(
                    onPressed: photoController.toggleSelectionMode,
                    child: Text(
                      photoController.isSelectionMode.value ? 'Cancelar' : 'Selecionar',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  )
                );
                return Row(children: actions);
              });
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.battery_charging_full),
                Text(' ${controller.bateriaEsp.value} %'),
                const SizedBox(width: 20),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.selectedIndex.value == 2 && controller.showBlePage.value) {
          return BlePage();
        }
        return Center(
          child: controller.widgetOptions.elementAt(controller.selectedIndex.value),
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Galeria'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configurações'),
            ],
            currentIndex: controller.selectedIndex.value,
            selectedItemColor: Colors.blue.shade700,
            onTap: controller.onItemTapped,
          )),
    );
  }

  void _confirmDeleteSelected(BuildContext context, PhotoController photoController) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Fotos?'),
        content: Text('Tem certeza que deseja excluir as ${photoController.selectedPhotos.length} fotos selecionadas?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              photoController.deleteSelectedPhotos();
              Get.back();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}