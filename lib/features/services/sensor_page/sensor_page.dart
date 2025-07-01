import 'dart:async'; // Import necessário para usar a classe Timer.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_v0/features/notification_ext/notification_controller_ext.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  // Obtém a instância do nosso controller de notificações.
  final NotificationExtController notificationController = Get.find();

  // Variáveis para controlar o estado do timer na tela.
  Timer? _timer;
  int _countdown = 10;
  bool _isTimerRunning = false;
  bool _wasCheckinConfirmed = false;

  /// Cancela o timer quando a tela é destruída para evitar vazamentos de memória.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Reseta o estado da tela para o inicial.
  void _resetCheckinState() {
    setState(() {
      _isTimerRunning = false;
      _wasCheckinConfirmed = false;
      _countdown = 10;
    });
    _timer?.cancel();
  }

  /// Inicia o fluxo de check-in e o timer de 10 segundos.
  void _startCheckinProcess() {
    // Reseta qualquer estado anterior e dispara a notificação de check-in.
    _resetCheckinState();
    notificationController.showCheckinNotification();

    setState(() {
      _isTimerRunning = true;
    });

    // Cria um timer que executa a cada 1 segundo.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Verifica se o usuário pressionou o botão da notificação.
      // O controller 'notificationController' nos diz isso através da variável reativa.
      if (notificationController.isCheckinConfirmed.value) {
        print("Check-in confirmado pelo usuário! Cancelando timer.");
        setState(() {
          _wasCheckinConfirmed = true; // Muda o estado para mostrar o feedback verde.
          _isTimerRunning = false;
        });
        timer.cancel(); // Para o timer.
        return;
      }

      // Se o tempo não se esgotou, apenas decrementa o contador.
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        // Se o tempo se esgotou (countdown chegou a 0).
        print("Tempo esgotado! Disparando alerta de emergência...");
        setState(() {
          _isTimerRunning = false;
        });
        timer.cancel(); // Para o timer.
        notificationController.triggerFullEmergencyAlert(); // Dispara o alerta completo!
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Controle de Alertas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BOTÃO DE CHECK-IN ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              // Desabilita o botão enquanto o timer estiver rodando.
              onPressed: _isTimerRunning ? null : _startCheckinProcess,
              child: const Text(
                'Disparar Notificação de Check-in',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 30),

            // --- VISUALIZADOR DO TIMER ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _wasCheckinConfirmed ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _wasCheckinConfirmed ? Colors.green.shade400 : Colors.grey.shade400,
                    width: 2,
                  )
              ),
              child: Center(
                child: _isTimerRunning
                    ? Text(
                  'Tempo restante: $_countdown s',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )
                    : Text(
                  _wasCheckinConfirmed ? 'Check-in Confirmado!' : 'Aguardando check-in...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _wasCheckinConfirmed ? Colors.green.shade800 : Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- BOTÃO DE ALERTA DIRETO ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Chama diretamente a função de alerta completo (SMS + Notificação).
                notificationController.triggerFullEmergencyAlert();
              },
              child: const Text(
                'Disparar Alerta de Emergência',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}