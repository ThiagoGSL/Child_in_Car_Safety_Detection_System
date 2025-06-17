import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/home/components/pulsing_card.dart'; // NOVO: Importa o widget de animação
import 'package:app_v0/features/home/components/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final BluetoothController bleController = Get.find<BluetoothController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Obx(() {
          // Lógica para determinar qual passo está ativo (piscando)
          bool isConnectingStepActive = !bleController.isConnected.value;
          bool isDetectingStepActive = bleController.isConnected.value && !bleController.childDetected.value;
          bool isNotifyingStepActive = bleController.childDetected.value && bleController.receivedImage.value == null;

          return ListView(
            children: [
              MyTimelineTile(
                isFirst: true,
                isLast: false,
                isPast: bleController.isConnected.value,
                eventCard: PulsingCard( // NOVO: Envolve o card com o widget de pulso
                  isPulsing: isConnectingStepActive,
                  child: Text(
                    bleController.isConnected.value
                        ? 'CONECTADO AO DISPOSITIVO'
                        : 'PROCURANDO DISPOSITIVO...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              MyTimelineTile(
                isFirst: false,
                isLast: false,
                isPast: bleController.childDetected.value,
                eventCard: PulsingCard( // NOVO: Envolve o card com o widget de pulso
                  isPulsing: isDetectingStepActive,
                  child: Text( // MODIFICADO: Texto agora é dinâmico
                    bleController.childDetected.value
                        ? 'BEBÊ DETECTADO'
                        : 'NENHUM BEBÊ DETECTADO',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              MyTimelineTile(
                isFirst: false,
                isLast: true,
                isPast: false,
                eventCard: PulsingCard( // NOVO: Envolve o card com o widget de pulso
                  isPulsing: isNotifyingStepActive,
                  child: const Text(
                    'ENVIANDO NOTIFICAÇÃO...',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}