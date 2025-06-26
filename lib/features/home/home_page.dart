import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/home/components/pulsing_card.dart';
import 'package:app_v0/features/home/components/timeline_tile.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final BluetoothController bleController = Get.find<BluetoothController>();
    final FormController formController = Get.find<FormController>();
    final MainPageController mainPageController = Get.find<MainPageController>();
    final Color accentColor = const Color(0xFF53BF9D);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Obx(() {
                final childName = formController.childName.value;
                if (childName.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monitorando',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AutoSizeText(
                        childName,
                        maxLines: 1, 
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                        ),
                        minFontSize: 12, 
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    'Status do Monitor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              }),
              const SizedBox(height: 10),
              const Text(
                'Acompanhe em tempo real os eventos do dispositivo.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Obx(() {
                bool isConnected = bleController.isConnected.value;
                bool isChildDetected = bleController.childDetected.value;
                bool isPhotoReceived = bleController.receivedImage.value != null;

                bool isConnectingStepActive = !isConnected;
                bool isDetectingStepActive = isConnected && !isChildDetected;
                bool isNotifyingStepActive = isChildDetected && !isPhotoReceived;

                return Column(
                  children: [
                    MyTimelineTile(
                      isFirst: true,
                      isLast: false,
                      isPast: isConnected,
                      isActive: isConnectingStepActive,
                      eventCard: PulsingCard(
                        isPulsing: isConnectingStepActive,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          child: Text(
                            isConnected ? 'CONECTADO' : 'PROCURANDO DISPOSITIVO...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ),
                    MyTimelineTile(
                      isFirst: false,
                      isLast: true,
                      isPast: isPhotoReceived,
                      isActive: isNotifyingStepActive,
                      eventCard: PulsingCard(
                        isPulsing: isNotifyingStepActive,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          child: Text(
                            isPhotoReceived ? 'FOTO RECEBIDA' : 'AGUARDANDO FOTO',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ),
                    MyTimelineTile(
                      isFirst: false,
                      isLast: false,
                      isPast: isChildDetected,
                      isActive: isDetectingStepActive,
                      eventCard: PulsingCard(
                        isPulsing: isDetectingStepActive,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          child: Text(
                            isChildDetected ? 'BEBÊ DETECTADO' : 'NENHUM BEBÊ DETECTADO',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const Spacer(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(-16.0, 0),
        child: FloatingActionButton(
          onPressed: () {
            mainPageController.onItemTapped(2);
            mainPageController.navigateToPhotoPage(true);
          },
          backgroundColor: accentColor,
          tooltip: 'Ver Galeria',
          child: const Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}