import 'dart:async';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/car_moviment_verification/sensores_service_controller.dart';
import 'package:app_v0/features/notification_ext/notification_controller_ext.dart';
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

  // CORRIGIDO: Removida a variável duplicada. Usaremos a do DeteccaoController.
  // final tempoSeguroExpirado = false.obs;

  // Duração configurável para os timers.
  final tempoSeguro = 15.obs;
  final tempoResposta = 15.obs;

  // Timers para controlar processos assíncronos dentro de estados específicos.
  Timer? _timerSeguro;
  Timer? _timerReconexao;
  Timer? _timerAlerta;

  // Dependências de outros controllers, injetadas via GetX.
  final BluetoothController _bluetoothController = Get.find<BluetoothController>();
  final PhotoController _photoController = Get.find<PhotoController>();
  final DeteccaoController _deteccaoController = Get.find<DeteccaoController>();
  final VehicleDetectionController _vehicleDetectionController = Get.find<VehicleDetectionController>();
  final NotificationExtController _notificationExtController = Get.find<NotificationExtController>();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    print("StateMachineController: Iniciando");

    // Registra listeners para as variáveis de estado externas.
    ever(_bluetoothController.isConnected, (_) => _avaliarEstado());
    ever(_vehicleDetectionController.vehicleState, (_) => _avaliarEstado());
    ever(_photoController.criancaDetectada, (_) => _avaliarEstado());
    ever(_deteccaoController.temBebe, (_) => _avaliarEstado());
    ever(_deteccaoController.tempoSeguroExpirado, (_) => _avaliarEstado());
    ever(_deteccaoController.semResposta, (_) => _avaliarEstado());

    _avaliarEstado();
    print("StateMachineController: Inicialização concluída.");
  }

  @override
  void onClose() {
    _timerSeguro?.cancel();
    _timerReconexao?.cancel();
    _timerAlerta?.cancel();
    super.onClose();
  }

  /**
   * Avalia o estado atual e realiza as transições necessárias.
   * * Utiliza um loop `do-while` para permitir "transições em cadeia".
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
          }
          // CORRIGIDO: Verifica a variável no controller correto.
          else if (_deteccaoController.tempoSeguroExpirado.value) {
            estadoAtual.value = EstadoApp.notificacaoinicial;
          }
          break;

        case EstadoApp.notificacaoinicial:
        // CORRIGIDO: Lógica que causava o loop foi removida.
        // Este estado agora é "pegajoso" e só sai por uma ação de maior prioridade
        // ou por uma resposta explícita do usuário.
          if (_vehicleDetectionController.vehicleState.value == VehicleState.moving) {
            estadoAtual.value = EstadoApp.carroandando;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          }
          break;

        case EstadoApp.perdadeconexao:
          if (_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.monitorando;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          }
          break;

        case EstadoApp.relembrando:
        // CORRIGIDO: Removida a saída instantânea por `!semResposta`.
          if (!_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.idle;
          } else if (_bluetoothController.isConnected.value) {
            estadoAtual.value = EstadoApp.conectado;
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
        // CORRIGIDO: A saída deste estado agora é gerida exclusivamente
        // pela função `usuarioRespondeuPositivamente`.
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
      _deteccaoController.semResposta.value = false;
      _deteccaoController.tempoSeguroExpirado.value = false;

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
        _executarAcaoDeSaida(stateBeforeResponse);
        estadoAtual.value = nextState;
        _executarAcaoDeEntrada(nextState);
      }
      _avaliarEstado();
    }
  }

  /// Executa lógicas de limpeza ao sair de um estado.
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
  void _executarAcaoDeEntrada(EstadoApp novoEstado) {
    debugPrint("--> Ação de ENTRADA no estado: ${novoEstado.name}");
    switch (novoEstado) {
      case EstadoApp.monitorando:
        debugPrint("    Iniciando timer de segurança de ${tempoSeguro.value} segundos.");
        _timerSeguro = Timer(Duration(seconds: tempoSeguro.value), () {
          debugPrint("!!! Gatilho: TIMER DE SEGURANÇA EXPIROU !!!");
          // CORRIGIDO: Atualiza a variável no controller correto.
          _deteccaoController.tempoSeguroExpirado.value = true;
        });
        break;
      case EstadoApp.notificacaoinicial:
        debugPrint("    Iniciando timer de ${tempoResposta.value} segundos para alerta (sem resposta).");
        final response = await _notificationExtController.askIfBabyIsPresent();
        print(response);
        _timerAlerta = Timer(Duration(seconds: tempoResposta.value), () {
          debugPrint("!!! Gatilho: TIMER PARA ALERTA EXPIROU (sem resposta) !!!");
          _deteccaoController.semResposta.value = true;
        });
        if (response == 'AWARE_YES'){
          print("AAAAAAAAAAAAAAAAAAAAAAAAAA");
          usuarioRespondeuPositivamente();
        }
        break;
      case EstadoApp.perdadeconexao:
        debugPrint("    Iniciando tentativas periódicas de reconexão a cada 3 segundos.");
        _timerReconexao = Timer.periodic(const Duration(seconds: 3), (timer) {
          debugPrint("    ...tentando reconectar o bluetooth (simulação)...");
        });
        break;
      case EstadoApp.carroandando:
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

  void changeState(EstadoApp newState) {

    EstadoApp currentState = estadoAtual.value;

    // Zera os gatilhos que levaram ao estado de espera.
    _deteccaoController.semResposta.value = false;
    _deteccaoController.tempoSeguroExpirado.value = false;


    // Determina o próximo estado com base na resposta.    }

    if (newState != null && newState != currentState) {
      debugPrint('TRANSIÇÃO FORÇADA: ${currentState.name} -> ${newState.name}');

      // Executa o ciclo de transição manualmente para garantir a execução das ações.
      _executarAcaoDeSaida(currentState);
      estadoAtual.value = newState;
      _executarAcaoDeEntrada(newState);
    }

    // Reavalia para garantir estabilidade após a transição forçada.
    _avaliarEstado();
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