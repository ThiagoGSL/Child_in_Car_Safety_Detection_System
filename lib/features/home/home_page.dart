import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/home/components/pulsing_card.dart';
import 'package:app_v0/features/home/components/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final BluetoothController bleController = Get.find<BluetoothController>();
    final FormController formController = Get.find<FormController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // MODIFICADO: Título agora usa RichText para múltiplos estilos
              Obx(() {
                final childName = formController.childName.value;

                if (childName.isNotEmpty) {
                  // Widget RichText para aplicar estilos diferentes
                  return RichText(
                    text: TextSpan(
                      // Estilo padrão (aplicado a ambos, se não for sobrescrito)
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Monitorando ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22, // Fonte menor para "Monitorando"
                          ),
                        ),
                        TextSpan(
                          text: childName,
                          style: const TextStyle(
                            color: Color(0xFF53BF9D), // Cor verde padrão do app
                            fontSize: 24, // Fonte ligeiramente maior para o nome
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Título padrão caso não haja nome
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
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
                        child: Text(
                          isConnected ? 'CONECTADO' : 'PROCURANDO DISPOSITIVO...',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        child: Text(
                          isChildDetected ? 'BEBÊ DETECTADO' : 'NENHUM BEBÊ DETECTADO',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        child: Text(
                          isPhotoReceived ? 'FOTO RECEBIDA' : 'AGUARDANDO FOTO',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}