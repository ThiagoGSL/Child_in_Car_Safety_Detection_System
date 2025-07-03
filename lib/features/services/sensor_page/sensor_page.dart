// lib/features/services/sensor_page/sensor_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_v0/features/notification_ext/notification_controller_ext.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final NotificationExtController notificationController = Get.find();

  // Variáveis reativas para controlar o estado da UI
  final _isProcessRunning = false.obs;
  final _statusMessage = "Aguardando início...".obs;
  final _statusColor = Colors.grey.shade200.obs;

  @override
  void dispose() {
    // Garante que o processo seja cancelado se a página for fechada
    notificationController.cancelCheckinProcess();
    super.dispose();
  }

  /// Este método simula a MÁQUINA DE ESTADOS iniciando o processo.
  void _startCheckinSimulation() {
    // Estado inicial: processo rodando
    _isProcessRunning.value = true;
    _statusMessage.value = "Aguardando...";
    _statusColor.value = Colors.orange.shade100;

    // Chama o controller, passando os 3 callbacks (as "instruções")
    notificationController.startCheckinProcess(
      countdownSeconds: 10, // Para teste, usamos 10 segundos

      // apresentar o timer na tela opicional
      onTick: (secondsRemaining) {
        _statusMessage.value = "Tempo restante: $secondsRemaining s";
      },

      // INSTRUÇÃO 2: O que fazer em caso de SUCESSO (botão clicado)
      onSuccess: () {
        print("SENSOR_PAGE (CÉREBRO): Recebi o callback de SUCESSO!");
        _statusMessage.value = "Check-in Confirmado!";
        _statusColor.value = Colors.green.shade100;
        _isProcessRunning.value = false;
      },

      // INSTRUÇÃO 3: O que fazer em caso de FALHA (timeout)
      onFailure: () {
        print("SENSOR_PAGE (CÉREBRO): Recebi o callback de FALHA!");
        _statusMessage.value = "Alerta de Emergência Disparado!";
        _statusColor.value = Colors.red.shade100;
        _isProcessRunning.value = false;

        // A máquina de estados então comandaria o envio do alerta final
        notificationController.triggerFullEmergencyAlert();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Máquina de Estados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // O botão que simula o evento "Carro Parou"
            Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isProcessRunning.value ? null : _startCheckinSimulation,
              child: Text(
                _isProcessRunning.value ? 'PROCESSO EM ANDAMENTO' : 'Simular "Carro Parou"',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            )),

            const SizedBox(height: 40),

            // O container de status que reage aos callbacks
            Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _statusColor.value,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _statusColor.value.withOpacity(0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  _statusMessage.value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}