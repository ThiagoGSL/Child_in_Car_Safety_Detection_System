import 'dart:async';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/car_moviment_verification/sensores_service_controller.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'external_controllers.dart';

/**
 * Controla a lógica de estados da aplicação de forma reativa.
 * * Esta máquina de estados reage a mudanças em `Controllers` externos (Bluetooth, Carro, etc.)
 * e utiliza um sistema de ações de entrada/saída para gerir processos contínuos,
 * como Timers, garantindo que sejam iniciados e cancelados nos momentos certos.
 */

enum EstadoApp {
  idle,
  conectado,
  carroandando,
  monitorando,
  notificacaoinicial,
  alerta,
  perdadeconexao,
  relembrando,
  esperando
}

class StateMachineController extends GetxController {
  // O estado atual da aplicação, observável pela UI.
  final estadoAtual = EstadoApp.idle.obs;
  final tempoSeguroExpirado = false.obs;
  final tempoSeguro = 5.obs;
  final tempoResposta = 5.obs;

  // Timers para controlar processos assíncronos dentro de estados específicos.
  // Devem ser cancelados nas ações de saída para evitar memory leaks.
  Timer? _timerSeguro;
  Timer? _timerReconexao;
  Timer? _timerAlerta;

  // Dependências de outros controllers, injetadas via GetX.
  final BluetoothController _bluetoothController = Get.find<BluetoothController>();
  late final PhotoController _photoController;
  late final DeteccaoController _deteccaoController;
  late final VehicleDetectionController _vehicleDetectionController;

  @override
  void onInit() {
    super.onInit();

    init();
  }

  Future<void> init() async {
    print("StateMachineController: Iniciando");

    // Obtém as instâncias dos controllers de dependência.
    _deteccaoController = Get.find<DeteccaoController>();
    _photoController = Get.find<PhotoController>();
    _vehicleDetectionController = Get.find<VehicleDetectionController>();

    // Registra listeners para as variáveis de estado externas.
    // Qualquer alteração nelas dispara uma reavaliação da máquina de estados.
    ever(_bluetoothController.isConnected, (_) => _avaliarEstado());
    ever(_vehicleDetectionController.vehicleState, (_) => _avaliarEstado());
    ever(_photoController.detectionResult, (_) => _avaliarEstado());
    ever(_deteccaoController.temBebe, (_) => _avaliarEstado());
    ever(_deteccaoController.tempoSeguroExpirado, (_) => _avaliarEstado());
    ever(_deteccaoController.semResposta, (_) => _avaliarEstado());

    // Avalia o estado inicial assim que o app começa.
    _avaliarEstado();
    print("StateMachineController: Inicialização concluída.");
  }

  // Garante a limpeza dos timers quando o controller é removido da memória.
  @override
  void onClose() {
    _timerSeguro?.cancel();
    _timerReconexao?.cancel();
    _timerAlerta?.cancel();
    super.onClose();
  }

  /**
   * Avalia o estado atual e realiza as transições necessárias.
   * * Utiliza um loop `do-while` para permitir "transições em cadeia": após uma mudança
   * de estado, a lógica é reavaliada imediatamente para verificar se o novo estado
   * também deve transitar. O loop para quando um estado estável é alcançado.
   */
  void _avaliarEstado() {
    bool stateDidChange;
    do {
      stateDidChange = false;
      EstadoApp estadoAnterior = estadoAtual.value;

      switch (estadoAtual.value) {
        case EstadoApp.idle:
          if (_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.relembrando;
          } else if (_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.conectado;
          }
          break;

        case EstadoApp.conectado:
          if (!_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.idle;
          }
          else if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) {
            estadoAtual.value = EstadoApp.carroandando;
          } else if (_photoController.criancaDetectada.value) {
            estadoAtual.value = EstadoApp.monitorando;
          }
          break;

        case EstadoApp.carroandando:
          if (_vehicleDetectionController.vehicleState.value != VehicleState.moving) {
            estadoAtual.value = EstadoApp.conectado;
          }
          break;

        case EstadoApp.monitorando:
          if (!_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.perdadeconexao;
          } else if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) {
            estadoAtual.value = EstadoApp.carroandando;
          } else if (!_photoController.criancaDetectada.value) {
            estadoAtual.value = EstadoApp.conectado;
          } else if (tempoSeguroExpirado.value) {
            estadoAtual.value = EstadoApp.notificacaoinicial;
          }
          break;

        case EstadoApp.notificacaoinicial:
          if (!_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.monitorando;
            _deteccaoController.tempoSeguroExpirado.value = false;
          } else if (!_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.esperando;
          } else if (!_photoController.criancaDetectada.value) {
            estadoAtual.value = EstadoApp.conectado;
          } else if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) {
            estadoAtual.value = EstadoApp.carroandando;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          }
          break;

        case EstadoApp.perdadeconexao:
          if (_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.monitorando;
          } else if (!_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.relembrando;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          }
          break;

        case EstadoApp.relembrando:
          if (!_deteccaoController.temBebe.value || !_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.idle;
          } else if (_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.conectado;
          } else if (_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.relembrando;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          }
          break;

        case EstadoApp.esperando:
          if (!_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.idle;
          }
          break;

        case EstadoApp.alerta:
        // A saída do alerta é intencionalmente gerida apenas por uma ação explícita do usuário.
          if (!_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.idle;
          }
          break;
      }

      if (estadoAnterior != estadoAtual.value) {
        stateDidChange = true; // Sinaliza que o loop precisa continuar para garantir a estabilidade.
        debugPrint('MUDANÇA DE ESTADO: ${estadoAnterior.name} -> ${estadoAtual.value.name}');

        // Padrão de Ações: primeiro limpa o estado antigo, depois inicializa o novo.
        _executarAcaoDeSaida(estadoAnterior);
        _executarAcaoDeEntrada(estadoAtual.value);
      }

    } while (stateDidChange);
  }

  /// Chamado por um evento da UI quando o usuário interage para cancelar um alerta ou notificação.
  void usuarioRespondeuPositivamente() {
    final statesAwaitingResponse = [
      EstadoApp.notificacaoinicial,
      EstadoApp.alerta,
      EstadoApp.perdadeconexao,
      EstadoApp.relembrando,
    ];

    if (statesAwaitingResponse.contains(estadoAtual.value)) {
      debugPrint("EVENTO: Usuário respondeu positivamente a partir do estado ${estadoAtual.value.name}.");

      EstadoApp stateBeforeResponse = estadoAtual.value;

      // Zera os gatilhos que levaram ao estado de espera.
      _deteccaoController.semResposta.value = false;
      _deteccaoController.tempoSeguroExpirado.value = false;

      // Determina o próximo estado com base na resposta.
      EstadoApp? nextState;
      switch(stateBeforeResponse) {
        case EstadoApp.notificacaoinicial:
        case EstadoApp.alerta:
          nextState = EstadoApp.monitorando;
          break;
        case EstadoApp.perdadeconexao:
          nextState = EstadoApp.relembrando;
          break;
        case EstadoApp.relembrando:
          nextState = EstadoApp.idle;
          break;
        default: break;
      }

      if (nextState != null && nextState != stateBeforeResponse) {
        debugPrint('TRANSIÇÃO FORÇADA: ${stateBeforeResponse.name} -> ${nextState.name}');

        // Executa o ciclo de transição manualmente para garantir a execução das ações.
        _executarAcaoDeSaida(stateBeforeResponse);
        estadoAtual.value = nextState;
        _executarAcaoDeEntrada(nextState);
      }

      // Reavalia para garantir estabilidade após a transição forçada.
      _avaliarEstado();
    }
  }

  /// Executa lógicas de limpeza ao sair de um estado.
  /// Fundamental para cancelar Timers e evitar processos órfãos.
  void _executarAcaoDeSaida(EstadoApp estadoQueSaiu) {
    debugPrint("--> Ação de SAÍDA do estado: ${estadoQueSaiu.name}");
    switch (estadoQueSaiu) {
      case EstadoApp.monitorando:
        debugPrint("    Cancelando timer de segurança.");
        _timerSeguro?.cancel();
        _timerSeguro = null;
        break;
      case EstadoApp.notificacaoinicial:
        debugPrint("    Cancelando timer para alerta.");
        _timerAlerta?.cancel();
        _timerAlerta = null;
        break;
      case EstadoApp.perdadeconexao:
        debugPrint("    Cancelando tentativas de reconexão.");
        _timerReconexao?.cancel();
        _timerReconexao = null;
        break;
      default:
        break;
    }
  }

  /// Executa lógicas de inicialização ao entrar em um novo estado.
  /// Ideal para iniciar Timers, listeners ou processos contínuos.
  void _executarAcaoDeEntrada(EstadoApp novoEstado) {
    debugPrint("--> Ação de ENTRADA no estado: ${novoEstado.name}");
    switch (novoEstado) {
      case EstadoApp.monitorando:
      // Inicia um timer que, se não for cancelado, levará ao estado de NotificacaoInicial.
        debugPrint("    Iniciando timer de segurança de 5 segundos.");
        _timerSeguro = Timer(Duration(seconds: tempoSeguro.value), () {
          debugPrint("!!! Gatilho: TIMER DE SEGURANÇA EXPIROU !!!");
          tempoSeguroExpirado.value = true;
        });
        break;
      case EstadoApp.notificacaoinicial:
      // Se o usuário não responder dentro deste tempo, o estado escalará para Alerta.
        debugPrint("    Iniciando timer de 10 segundos para alerta (sem resposta).");
        _timerAlerta = Timer(Duration(seconds: tempoResposta.value), () {
          debugPrint("!!! Gatilho: TIMER PARA ALERTA EXPIROU (sem resposta) !!!");
          _deteccaoController.semResposta.value = true;
        });
        break;
      case EstadoApp.perdadeconexao:
      // Exemplo de um processo contínuo: tentar reconectar periodicamente.
        debugPrint("    Iniciando tentativas periódicas de reconexão a cada 3 segundos.");
        _timerReconexao = Timer.periodic(const Duration(seconds: 3), (timer) {
          debugPrint("    ...tentando reconectar o bluetooth (simulação)...");
        });
        break;
      case EstadoApp.carroandando:
      // Ação de limpeza: cancela estados de notificação pendentes se o carro andar.
        _deteccaoController.tempoSeguroExpirado.value = false;
        _deteccaoController.semResposta.value = false;
        break;
      case EstadoApp.alerta:
        debugPrint("    Enviando SMS de alerta (simulação).");
        break;
      default:
        break;
    }
  }

  // **FUNÇÃO CORRIGIDA E MOVIDA PARA DENTRO DA CLASSE**
  String currentStateToString(EstadoApp currentState) {
    switch (currentState) {
      case EstadoApp.idle:
        return "Idle";

      case EstadoApp.conectado:
        return "Conectado";

      case EstadoApp.carroandando:
        return "Carro Andando";

      case EstadoApp.monitorando:
        return "Monitorando";

      case EstadoApp.notificacaoinicial:
        return "Notificação Inicial Enviada";

      case EstadoApp.alerta:
        return "Alerta";

      case EstadoApp.perdadeconexao:
        return "Perdeu Conexão";

      case EstadoApp.relembrando:
        return "Relembrando";

      case EstadoApp.esperando:
        return "Esperando";
    }
  }
}