import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/home/components/pulsing_card.dart';
import 'package:app_v0/features/home/components/timeline_tile.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:app_v0/features/state_machine/state_machine_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:app_v0/features/notification/notification_ext_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final BluetoothController bleController = Get.find<BluetoothController>();
    final FormController formController = Get.find<FormController>();
    final MainPageController mainPageController = Get.find<MainPageController>();
    final StateMachineController stateMachineController = Get.find<StateMachineController>();
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
              Obx(() {
                final currentState = stateMachineController.estadoAtual.value;
                return RichText(
                  text: TextSpan(
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(
                        text: 'Estado Atual: ',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      TextSpan(
                        // **CHAMADA ATUALIZADA AQUI**
                        text: stateMachineController.currentStateToString(currentState),
                        style: TextStyle(color: accentColor, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              const Text(
                'Acompanhe em tempo real os eventos do dispositivo.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
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
                      eventCard: GestureDetector(
                        onTap: () {
                          // MODIFICAÇÃO: Removida a condição. Sempre navega para a ble_page.
                          mainPageController.onItemTapped(2); // Muda para a aba de Configurações
                          mainPageController.navigateToBlePage(true); // Mostra a BlePage
                        },
                        child: PulsingCard(
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
                    ),
                    MyTimelineTile(
                      isFirst: false,
                      isLast: false,
                      isPast: isPhotoReceived,
                      isActive: isNotifyingStepActive,
                      // MODIFICAÇÃO: Adicionado GestureDetector para navegar para a galeria
                      eventCard: GestureDetector(
                        onTap: () {
                          mainPageController.onItemTapped(2); // Muda para a aba de Configurações
                          mainPageController.navigateToPhotoPage(true); // Mostra a PhotoPage
                        },
                        child: PulsingCard(
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
                    ),
                    MyTimelineTile(
                      isFirst: false,
                      isLast: true,
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
                   // POP-UP REATIVO DE NOTIFICAÇÃO
                   Obx(() {
                     final notificationController = Get.find<NotificationExtController>();
                     final popup = notificationController.popupData.value;
                     if (popup == null) return SizedBox.shrink();
                     return Card(
                       color: Colors.amber[100],
                       margin: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(popup.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                             SizedBox(height: 8),
                             Text(popup.message),
                             SizedBox(height: 12),
                             Row(
                               children: popup.buttons.map((btn) => Padding(
                                 padding: const EdgeInsets.only(right: 8.0),
                                 child: ElevatedButton(
                                   onPressed: btn.onPressed,
                                   child: Text(btn.label),
                                 ),
                               )).toList(),
                             ),
                           ],
                         ),
                       ),
                     );
                   }),
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
