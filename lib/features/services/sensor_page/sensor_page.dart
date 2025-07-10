// lib/features/services/sensor_page/sensor_page.dart

import 'dart:async';
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

  // Variáveis de estado da UI
  final _statusMessage = "Sistema ocioso.".obs;
  final _isProcessRunning = false.obs;

  // Timer para o "tempo de cortesia" do fluxo de carro parado
  Timer? _gracePeriodTimer;

  @override
  void dispose() {
    notificationController.cancelAllProcesses();
    _gracePeriodTimer?.cancel();
    super.dispose();
  }

  void _resetSystem() {
    notificationController.cancelAllProcesses();
    _gracePeriodTimer?.cancel();
    _isProcessRunning.value = false;
    _statusMessage.value = "Sistema ocioso.";
  }

  /// SIMULAÇÃO DO FLUXO PRINCIPAL: CARRO PARADO
  void _simulateCarStoppedFlow() {
    _isProcessRunning.value = true;
    int gracePeriodSeconds = 15; // Tempo de cortesia (curto para teste)

    // FASE 1: O timer de cortesia começa a rodar na tela
    _gracePeriodTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      int secondsRemaining = gracePeriodSeconds - timer.tick;

      if (secondsRemaining > 0) {
        _statusMessage.value = "Carro parado. Notificação em $secondsRemaining s...";
      } else {
        // FASE 2: O tempo de cortesia acabou, dispara a notificação
        timer.cancel();
        _statusMessage.value = "Tempo esgotado! Perguntando ao usuário se está ciente do bebê...";

        final response = await notificationController.askIfBabyIsPresent();

        // FASE 3: O sistema reage à resposta do usuário
        if (response == KEY_AWARE_YES) {
          _statusMessage.value = "CICLO FINALIZADO: Usuário confirmou que está ciente.";
          _isProcessRunning.value = false;
        } else if (response == KEY_AWARE_NO_BABY) {
          _statusMessage.value = "CICLO FINALIZADO: Usuário informou que não há bebê.";
          _isProcessRunning.value = false;
        } else { // Resposta nula (timeout da notificação)
          _statusMessage.value = "ALERTA: Usuário não respondeu à notificação!";
          // A máquina de estados chama o processo de alerta completo
          notificationController.triggerFullEmergencyAlert();
          _isProcessRunning.value = false;
        }
      }
    });
  }

  /// SIMULAÇÃO PARA TESTE INDIVIDUAL DA NOTIFICAÇÃO 2
  void _simulateConnectionLoss() {
    _isProcessRunning.value = true;
    _statusMessage.value = "Teste: Iniciando contagem de perda de conexão...";

    notificationController.startConnectionLossProcess(
      onTick: (seconds) {
        _statusMessage.value = "Teste (Perda de Conexão): $seconds s";
      },
      onAware: () {
        _statusMessage.value = "Teste finalizado: Usuário ciente.";
        _isProcessRunning.value = false;
      },
      onNoBaby: () {
        _statusMessage.value = "Teste finalizado: Não há bebê.";
        _isProcessRunning.value = false;
      },
      onTimeout: () {
        _statusMessage.value = "Teste finalizado: Timeout!";
        notificationController.triggerFullEmergencyAlert();
        _isProcessRunning.value = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Simulador de Máquina de Estados')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Container de Status
              Obx(() => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _statusMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              )),

              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              const Text("Fluxo Principal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue), textAlign: TextAlign.center),
              const SizedBox(height: 10),

              // Botão para o fluxo completo
              Obx(() => ElevatedButton.icon(
                icon: const Icon(Icons.directions_car),
                label: const Text('Simular "Carro Parou"'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isProcessRunning.value ? null : _simulateCarStoppedFlow,
              )),

              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              const Text("Testes Individuais", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 10),

              // Botão para o fluxo de perda de conexão
              Obx(() => ElevatedButton.icon(
                icon: const Icon(Icons.signal_wifi_off, size: 18),
                label: const Text('Testar Perda de Conexão'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade300),
                onPressed: _isProcessRunning.value ? null : _simulateConnectionLoss,
              )),

              const SizedBox(height: 20),

              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                label: const Text('Resetar Simulação', style: TextStyle(color: Colors.grey)),
                onPressed: _resetSystem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}