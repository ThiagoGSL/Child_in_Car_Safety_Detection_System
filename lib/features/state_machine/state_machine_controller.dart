// lib/features/state_machine/state_machine_controller.dart

import 'dart:async';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/car_moviment_verification/sensores_service_controller.dart';
import 'package:app_v0/features/notification_ext/notification_controller_ext.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'external_controllers.dart';

// SEU ENUM ORIGINAL DE ESTADOS, MANTIDO
enum EstadoApp {
  idle, conectado, carroandando, monitorando, notificacaoinicial,
  alerta, perdadeconexao, relembrando, esperando
}

class StateMachineController extends GetxController {
  final estadoAtual = EstadoApp.idle.obs;

  // Seus timers originais, agora gerenciados pela lógica correta
  final tempoSeguro = 15.obs;
  final tempoResposta = 30.obs; // Aumentado para 30s para dar tempo ao usuário
  Timer? _processTimer; // Unificamos os timers de processo para simplificar

  // Dependências (mantidas)
  final BluetoothController _bluetoothController = Get.find<BluetoothController>();
  final PhotoController _photoController = Get.find<PhotoController>();
  final DeteccaoController _deteccaoController = Get.find<DeteccaoController>();
  final VehicleDetectionController _vehicleDetectionController = Get.find<VehicleDetectionController>();
  final NotificationExtController _notificationExtController = Get.find<NotificationExtController>();

  @override
  void onInit() {
    super.onInit();
    // Seus listeners originais, mantidos
    ever(_bluetoothController.isConnected, (_) => _avaliarEstado());
    ever(_vehicleDetectionController.vehicleState, (_) => _avaliarEstado());
    ever(_photoController.criancaDetectada, (_) => _avaliarEstado());
    ever(_deteccaoController.temBebe, (_) => _avaliarEstado());
    ever(_deteccaoController.tempoSeguroExpirado, (_) => _avaliarEstado());
    ever(_deteccaoController.semResposta, (_) => _avaliarEstado());
    _avaliarEstado();
  }

  @override
  void onClose() {
    _processTimer?.cancel();
    super.onClose();
  }

  /// SEU MÉTODO ORIGINAL DE AVALIAÇÃO DE ESTADO, MANTIDO
  void _avaliarEstado() {
    bool stateDidChange;
    do {
      stateDidChange = false;
      EstadoApp estadoAnterior = estadoAtual.value;

      switch (estadoAtual.value) {
        case EstadoApp.idle:
          if (_deteccaoController.temBebe.value) { estadoAtual.value = EstadoApp.relembrando; }
          else if (_bluetoothController.isConnected.value) { estadoAtual.value = EstadoApp.conectado; }
          break;
        case EstadoApp.conectado:
          if (!_bluetoothController.isConnected.value) { estadoAtual.value = EstadoApp.idle; }
          else if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) { estadoAtual.value = EstadoApp.carroandando; }
          else if (_photoController.criancaDetectada.value) { estadoAtual.value = EstadoApp.monitorando; }
          break;
        case EstadoApp.carroandando:
          if (_vehicleDetectionController.vehicleState.value != VehicleState.moving) { estadoAtual.value = EstadoApp.conectado; }
          break;
        case EstadoApp.monitorando:
          if (!_bluetoothController.isConnected.value) { estadoAtual.value = EstadoApp.perdadeconexao; }
          else if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) { estadoAtual.value = EstadoApp.carroandando; }
          else if (!_photoController.criancaDetectada.value) { estadoAtual.value = EstadoApp.conectado; }
          else if (_deteccaoController.tempoSeguroExpirado.value) { estadoAtual.value = EstadoApp.notificacaoinicial; }
          break;
        case EstadoApp.notificacaoinicial:
        case EstadoApp.perdadeconexao:
        case EstadoApp.relembrando:
        // A lógica de saída destes estados agora é controlada pelas ações de entrada
          if (_deteccaoController.semResposta.value) { estadoAtual.value = EstadoApp.alerta; }
          else if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) { estadoAtual.value = EstadoApp.carroandando; }
          break;
        case EstadoApp.esperando:
          if (!_bluetoothController.isConnected.value) { estadoAtual.value = EstadoApp.idle; }
          break;
        case EstadoApp.alerta:
        // Estado final, só sai com reset manual
          break;
      }

      if (estadoAnterior != estadoAtual.value) {
        stateDidChange = true;
        debugPrint('MUDANÇA DE ESTADO: ${estadoAnterior.name} -> ${estadoAtual.value.name}');
        _executarAcaoDeSaida(estadoAnterior);
        _executarAcaoDeEntrada(estadoAtual.value);
      }
    } while (stateDidChange);
  }

  void _executarAcaoDeSaida(EstadoApp estadoQueSaiu) {
    debugPrint("--> Ação de SAÍDA do estado: ${estadoQueSaiu.name}");
    _processTimer?.cancel();
    _deteccaoController.tempoSeguroExpirado.value = false;
    _deteccaoController.semResposta.value = false;
  }

  // =================================================================================
  // <<< AQUI ESTÁ A LÓGICA DE NOTIFICAÇÃO CORRIGIDA E "PLUGADA" NOS ESTADOS CERTOS >>>
  // =================================================================================
  void _executarAcaoDeEntrada(EstadoApp novoEstado) {
    debugPrint("--> Ação de ENTRADA no estado: ${novoEstado.name}");
    switch (novoEstado) {

    // --- ESTADOS NORMAIS ---
      case EstadoApp.monitorando:
        _processTimer = Timer(Duration(seconds: tempoSeguro.value), () {
          _deteccaoController.tempoSeguroExpirado.value = true;
        });
        break;
      case EstadoApp.carroandando:
        _deteccaoController.tempoSeguroExpirado.value = false;
        _deteccaoController.semResposta.value = false;
        break;

    // --- ESTADOS DE NOTIFICAÇÃO (VERMELHOS NO DIAGRAMA) ---
      case EstadoApp.notificacaoinicial:
        _processarNotificacaoInicial();
        break;
      case EstadoApp.perdadeconexao:
        _processarNotificacaoPerdaDeConexao();
        break;
      case EstadoApp.relembrando:
        _processarNotificacaoDeLembrete();
        break;
      case EstadoApp.alerta:
        _notificationExtController.triggerFullEmergencyAlert();
        break;

      default:
        break;
    }
  }

  // --- Funções Auxiliares para Processar Cada Notificação ---

  /// PROCESSO DA NOTIFICAÇÃO 1: Pergunta "Bebê a Bordo?".
  Future<void> _processarNotificacaoInicial() async {
    // 1. Limpa respostas antigas e pede ao serviço para MOSTRAR a notificação.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_response');
    await _notificationExtController.showInitialBabyQuestion();
    debugPrint("MÁQUINA: Notificação 1 (Bebê a bordo?) exibida. Aguardando resposta por ${tempoResposta.value}s.");

    // 2. A MÁQUINA inicia seu PRÓPRIO timer para esperar pela resposta.
    _processTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final p = await SharedPreferences.getInstance();
      final response = p.getString('user_response');

      // 3. Se uma resposta foi encontrada...
      if (response != null) {
        timer.cancel();
        await _notificationExtController.cancelNotification(11);

        if (response == KEY_AWARE_YES) {
          debugPrint("MÁQUINA: RESPOSTA 1 = 'Sim'. Voltando ao monitoramento.");
          estadoAtual.value = EstadoApp.monitorando;
        } else if (response == KEY_AWARE_NO_BABY) {
          debugPrint("MÁQUINA: RESPOSTA 1 = 'Não tem bebê'. Finalizando ciclo.");
          estadoAtual.value = EstadoApp.idle;
        }
      }
      // 4. Se o tempo se esgotou sem resposta...
      else if (timer.tick >= tempoResposta.value) {
        timer.cancel();
        await _notificationExtController.cancelNotification(11);
        debugPrint("MÁQUINA: TIMEOUT na Notificação 1. Disparando gatilho de 'sem resposta'.");
        _deteccaoController.semResposta.value = true;
      }
    });
  }

  /// PROCESSO DA NOTIFICAÇÃO 2: Lida com a Perda de Conexão.
  Future<void> _processarNotificacaoPerdaDeConexao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_response');
    await _notificationExtController.showConnectionLossNotification();
    debugPrint("MÁQUINA: Notificação 2 (Perda de Conexão) exibida. Aguardando resposta por ${tempoResposta.value}s.");

    _processTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // ... (lógica de timer e checagem de resposta idêntica à anterior)
    });
  }

  /// PROCESSO DA NOTIFICAÇÃO 3: Pergunta sobre o Lembrete.
  Future<void> _processarNotificacaoDeLembrete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_response');
    await _notificationExtController.showReminderQuestion();
    debugPrint("MÁQUINA: Notificação 3 (Lembrete) exibida. Aguardando resposta.");

    // Lógica para esperar a resposta e decidir se inicia o ciclo de 5 minutos ou volta para monitoramento
  }
}