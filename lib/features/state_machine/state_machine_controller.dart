import 'dart:async';
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
  final tempoLembrete = 10.obs;

  // Timers para controlar processos assíncronos dentro de estados específicos.
  // Devem ser cancelados nas ações de saída para evitar memory leaks.
  Timer? _timerSeguro;
  Timer? _timerReconexao;
  Timer? _timerAlerta;
  Timer? _timerLembrete;

  // Dependências de outros controllers, injetadas via GetX.
  late final BluetoothController _bluetoothController;
  late final CarroController _carroController;
  late final DeteccaoController _deteccaoController;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    print("StateMachineController: Iniciando");

    // Obtém as instâncias dos controllers de dependência.
    _bluetoothController = Get.find<BluetoothController>();
    _carroController = Get.find<CarroController>();
    _deteccaoController = Get.find<DeteccaoController>();

    // Registra listeners para as variáveis de estado externas.
    // Qualquer alteração nelas dispara uma reavaliação da máquina de estados.
    ever(_bluetoothController.conectado, (_) => _avaliarEstado());
    ever(_carroController.andando, (_) => _avaliarEstado());
    ever(_deteccaoController.faceDetectada, (_) => _avaliarEstado());
    ever(_deteccaoController.temBebe, (_) => _avaliarEstado());
    ever(tempoSeguroExpirado, (_) => _avaliarEstado()); // Alterado para a variável local
    ever(_deteccaoController.semResposta, (_) => _avaliarEstado());

    // Avalia o estado inicial assim que o app começa.
    _avaliarEstado();
    print("StateMachineController: Inicialização concluída.");
  }

  @override
  void onClose() {
    _timerSeguro?.cancel();
    _timerReconexao?.cancel();
    _timerAlerta?.cancel();
    _timerLembrete?.cancel();
    super.onClose();
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
      case EstadoApp.relembrando:
        debugPrint("    Cancelando timer para alerta.");
        _timerAlerta?.cancel();
        _timerLembrete?.cancel();
        _timerAlerta = null;
        _timerLembrete = null;
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
          tempoSeguroExpirado.value = true;
        });
        break;
      case EstadoApp.notificacaoinicial:
        debugPrint("    Iniciando timer de ${tempoResposta.value} segundos para alerta (sem resposta).");
        _timerAlerta = Timer(Duration(seconds: tempoResposta.value), () {
          debugPrint("!!! Gatilho: TIMER PARA ALERTA EXPIROU (sem resposta) !!!");
          _deteccaoController.semResposta.value = true;
        });
        break;
      case EstadoApp.perdadeconexao:
        debugPrint("    Iniciando tentativas periódicas de reconexão a cada 3 segundos.");
        _timerReconexao = Timer.periodic(const Duration(seconds: 3), (timer) {
          debugPrint("    ...tentando reconectar o bluetooth (simulação)...");
        });
        break;
      case EstadoApp.carroandando:
        tempoSeguroExpirado.value = false;
        _deteccaoController.semResposta.value = false;
        break;
      case EstadoApp.relembrando:
        debugPrint("    Iniciando tentativas periódicas de reconexão a cada 3 segundos.");
        _timerReconexao = Timer.periodic(const Duration(seconds: 3), (timer) {
          debugPrint("    ...tentando reconectar o bluetooth (simulação)...");
        });
        debugPrint("    Iniciando timer de ${tempoLembrete.value} minutos para lembrete.");
        _timerLembrete = Timer(Duration(minutes: tempoLembrete.value), () {
          debugPrint("Lembrete de que o bebe ainda esta no carro, relembrar novamente?");
          //acao aqui: chamar UI para dizer se tem bb ou nao e se quer ser relembrado dnv E acionar temposeguro
        });
        break;
      case EstadoApp.alerta:
        debugPrint("    Enviando SMS de alerta (simulação).");
        break;
      default:
        break;
    }
  }

  /// Avalia o estado atual e realiza as transições necessárias.
  void _avaliarEstado() {
    bool stateDidChange;
    do {
      stateDidChange = false;
      EstadoApp estadoAnterior = estadoAtual.value;

      switch (estadoAtual.value) {
        case EstadoApp.idle:
          if (_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.relembrando;
          } else if (_bluetoothController.conectado.value) {
            estadoAtual.value = EstadoApp.conectado;
          }
          break;

        case EstadoApp.conectado:
          if (!_bluetoothController.conectado.value) {
            estadoAtual.value = EstadoApp.idle;
          } else if (_carroController.andando.value) {
            estadoAtual.value = EstadoApp.carroandando;
          } else if (_deteccaoController.faceDetectada.value) {
            estadoAtual.value = EstadoApp.monitorando;
          }
          break;

        case EstadoApp.carroandando:
          if (!_carroController.andando.value) {
            estadoAtual.value = EstadoApp.conectado;
          }
          break;

        case EstadoApp.monitorando:
          if (!_bluetoothController.conectado.value) {
            estadoAtual.value = EstadoApp.perdadeconexao;
          } else if (_carroController.andando.value) {
            estadoAtual.value = EstadoApp.carroandando;
          } else if (!_deteccaoController.faceDetectada.value) {
            estadoAtual.value = EstadoApp.conectado;
          } else if (tempoSeguroExpirado.value) {
            estadoAtual.value = EstadoApp.notificacaoinicial;
          }
          break;

        case EstadoApp.notificacaoinicial:
          if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          } else if (!_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.esperando;
          } else if (!_deteccaoController.faceDetectada.value) {
            estadoAtual.value = EstadoApp.conectado;
          } else if (_carroController.andando.value) {
            estadoAtual.value = EstadoApp.carroandando;
          }
          break;

        case EstadoApp.perdadeconexao:
          if (_bluetoothController.conectado.value) {
            estadoAtual.value = EstadoApp.monitorando;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          } else {
            estadoAtual.value = EstadoApp.relembrando;
          }
          break;

        case EstadoApp.relembrando:
          if (!_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.idle;
          } else if (_bluetoothController.conectado.value) {
            estadoAtual.value = EstadoApp.conectado;
          } else if (_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.alerta;
          }
          break;

        case EstadoApp.alerta:
          if (!_deteccaoController.semResposta.value) {
            estadoAtual.value = EstadoApp.idle;
          }
          break;

        case EstadoApp.esperando:
          if (!_bluetoothController.conectado.value) {
            estadoAtual.value = EstadoApp.idle;
          } else if (_deteccaoController.temBebe.value) {
            estadoAtual.value = EstadoApp.notificacaoinicial;
          }
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

  /// Chamado por um evento da UI para cancelar um alerta ou notificação.
  /// refazer logica para estado perda de conexao e relembrando pois a resposta nao é so um sim ou nao,
  /// mas um 'sim, relembrar em x' ou 'sim, nao relembrar' ou 'nao tem bebe'
  void usuarioRespondeuPositivamente() {
    final statesAwaitingResponse = [
      EstadoApp.notificacaoinicial,
      EstadoApp.alerta,
      EstadoApp.perdadeconexao,
      EstadoApp.relembrando,
    ];

    if (statesAwaitingResponse.contains(estadoAtual.value)) {
      debugPrint("EVENTO: Usuário respondeu positivamente do estado ${estadoAtual.value.name}.");
      _deteccaoController.semResposta.value = false;
      tempoSeguroExpirado.value = false;
      _avaliarEstado();
    }
  }

  void agendarLembrete(int minutos) {
    // Cancela qualquer lembrete anterior para evitar múltiplos timers.
    _timerLembrete?.cancel();
    if (minutos <= 0) {
      debugPrint("Lembrete cancelado (minutos <= 0).");
      return;
    }
    debugPrint("Lembrete agendado para daqui a ${minutos} minuto(s).");
    _timerLembrete = Timer(Duration(minutes: minutos), () {
      // Ação a ser executada quando o timer disparar.
      // Pode ser uma notificação local, um som, etc.
      debugPrint("--- LEMBRETE DISPARADO ---");
      debugPrint("Lembrete: Por favor, verifique o status!");
      // Adicionar logica de relembrar denovo ou desligar com base na resposta do usuario
    });
  }

  String currentState_toString(EstadoApp currentState) {
    switch (currentState) {
      case EstadoApp.idle: return "Idle";
      case EstadoApp.conectado: return "Conectado";
      case EstadoApp.carroandando: return "Carro Andando";
      case EstadoApp.monitorando: return "Monitorando";
      case EstadoApp.notificacaoinicial: return "Notificação Inicial Enviada";
      case EstadoApp.alerta: return "Alerta";
      case EstadoApp.perdadeconexao: return "Perdeu Conexão";
      case EstadoApp.relembrando: return "Relembrando";
      case EstadoApp.esperando: return "Esperando";
    }
  }
}
