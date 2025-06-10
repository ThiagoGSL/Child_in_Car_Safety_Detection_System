import 'package:flutter/foundation.dart';

/*
  1---------
    Analisar logica da face detectada: nao pode ser um booleano que mudara a cada momento,
    pois se a deteccao falhar uma vez, pode sair do estado de monitorando para conectado

*/

/// Enumeração para os possíveis estados da aplicação, baseados no diagrama.
enum EstadoApp {
  idle,
  conectado,
  carroandando,
  monitorando,
  notificacaoinicial,
  alerta,
  perdadeconexao
}

/// Enumeração para os eventos que podem disparar transições de estado.
enum EventoApp {
  temposeguroexpirado,      // TS: e.g., booleano `tempoSeguroExpirou` = true
  semresposta,
  bluetoothconectado,
  facedetectada,
  carroparado,

  bluetoothdesconectado,    // BT': e.g., booleano `bluetoothConectado` = false
  facenaodetectada,
  carroandando,
  comresposta
}

/// Classe que gerencia a máquina de estados.
/// Utiliza ChangeNotifier para notificar os listeners (como a UI) sobre mudanças de estado.
class MaquinaDeEstados extends ChangeNotifier {
  EstadoApp _estadoAtual = EstadoApp.idle;
  EstadoApp get estadoAtual => _estadoAtual;

  /// Construtor que define o estado inicial.
  MaquinaDeEstados({EstadoApp estadoinicial = EstadoApp.idle}) {
    _estadoAtual = estadoinicial;
    // É possível executar ações para o estado inicial aqui também, se necessário.
  }

  /// Processa um evento e atualiza o estado da máquina conforme as transições definidas.
  void processarEvento(EventoApp evento) {
    EstadoApp estadoAnterior = _estadoAtual;

    switch (_estadoAtual) {
      case EstadoApp.idle:
        if (evento == EventoApp.bluetoothconectado) {
          _estadoAtual = EstadoApp.conectado;
        }
        break;

      case EstadoApp.conectado:
        switch (evento) {
          case EventoApp.carroandando:
            _estadoAtual = EstadoApp.carroandando;
            break;
          case EventoApp.facedetectada:
            _estadoAtual = EstadoApp.monitorando;
            break;
          case EventoApp.bluetoothdesconectado:
            _estadoAtual = EstadoApp.idle;
            break;
          default:
            break;
        }
        break;

      case EstadoApp.carroandando:
        if (evento == EventoApp.carroparado) {
          _estadoAtual = EstadoApp.conectado;
        }
        break;

      case EstadoApp.monitorando:
        switch (evento) {
          case EventoApp.temposeguroexpirado:
            _estadoAtual = EstadoApp.notificacaoinicial;
            break;
          case EventoApp.facenaodetectada:
            _estadoAtual = EstadoApp.conectado;
            break;
          case EventoApp.bluetoothdesconectado:
            _estadoAtual = EstadoApp.perdadeconexao;
            break;
          case EventoApp.carroandando:
            _estadoAtual = EstadoApp.carroandando;
            break;
          default:
            break;
        }
        break;

      case EstadoApp.notificacaoinicial:
        switch (evento) {
          case EventoApp.semresposta:
            _estadoAtual = EstadoApp.alerta;
            break;
          case EventoApp.carroandando:
            _estadoAtual = EstadoApp.carroandando;
            break;
          case EventoApp.comresposta:
            _estadoAtual = EstadoApp.monitorando;
            break;
          default:
            break;
        }
        break;

      case EstadoApp.alerta:
        if (evento == EventoApp.comresposta) {
          _estadoAtual = EstadoApp.idle;
        }
        break;

      case EstadoApp.perdadeconexao:
        switch (evento) {
          case EventoApp.bluetoothconectado:
            _estadoAtual = EstadoApp.monitorando;
            break;
          case EventoApp.semresposta:
            _estadoAtual = EstadoApp.alerta;
            break;
          case EventoApp.comresposta:
            _estadoAtual = EstadoApp.idle;
            break;
          default:
            break;
        }
        break;
    }

    if (estadoAnterior != _estadoAtual) {
      debugPrint('Mudança de Estado: ${estadoAnterior.name} -> ${_estadoAtual.name} (Evento: ${evento.name})');
      // Executa ações associadas à entrada no novo estado e/ou saída do estado anterior.
      _executarAcoesDoEstado(_estadoAtual, estadoAnterior);
      notifyListeners();
    }
  }

  /// Executa ações específicas ao entrar em um novo estado ou sair de um estado anterior.
  void _executarAcoesDoEstado(EstadoApp novoEstado, EstadoApp? estadoAnterior) {

    if (estadoAnterior != null) {
      switch (estadoAnterior) {
        case EstadoApp.monitorando:
        // Ex: Parar timer de segurança se estava no estado Monitorando e saiu.
        // _pararTimerSeguro();
          debugPrint("Saindo do estado Monitorando: Parando timer de segurança (exemplo).");
          break;
      // Adicione outros casos de saída conforme necessário
        default:
          break;
      }
    }

    // Ações de entrada no novo estado
    switch (novoEstado) {
      case EstadoApp.idle:
        debugPrint("Entrando no estado Idle");
        // _pararMonitoramentoDeRosto();
        // _desativarGPS();
        break;
      case EstadoApp.conectado:
        debugPrint("Entrando no estado Conectado");
        // _atualizarUIConexaoBluetooth(true);
        break;
      case EstadoApp.carroandando:
        debugPrint("Entrando no estado CarroAndando");
        //
        break;
      case EstadoApp.monitorando:
        debugPrint("Entrando no estado Monitorando");
        // _iniciarDeteccaoDeFace();
        // _iniciarTimerSeguro();
        break;
      case EstadoApp.notificacaoinicial:
        debugPrint("Entrando no estado NotificacaoInicial");
        // _vibrarDispositivo();
        // _mostrarNotificacaoUsuario();
        break;
      case EstadoApp.alerta:
        debugPrint("Entrando no estado Alerta: Enviando SMS, tocando alarme (exemplo).");
        // _enviarAlertaEmergencia();
        // _tocarAlarmeSonoro(); ----> Opcao para o usuario habilitar, talvez?
        break;
      case EstadoApp.perdadeconexao:
        debugPrint("Entrando no estado PerdaDeConexao: Tentando reconectar (exemplo).");
        // _tentarReconectarBluetooth();
        // _mostrarAvisoPerdaConexao();
        break;
    }
  }

  /// Método para definir um estado diretamente. Use com cautela para testes.
  void definirEstadoParaTeste(EstadoApp novoEstado) {
    EstadoApp estadoAnterior = _estadoAtual;
    _estadoAtual = novoEstado;
    if (estadoAnterior != _estadoAtual) {
      debugPrint('Estado definido para teste: ${estadoAnterior.name} -> ${_estadoAtual.name}');
      _executarAcoesDoEstado(_estadoAtual, estadoAnterior); // Executar ações também ao definir para teste
      notifyListeners();
    }
  }
}

// Exemplo de como usar (pode ser colocado em seu widget principal ou provider):
/*
void main() {
  final maquinaDeEstados = MaquinaDeEstados();

  // Para ouvir as mudanças de estado (exemplo em um widget):
  // maquinaDeEstados.addListener(() {
  //   print("Listener: Novo estado: ${maquinaDeEstados.estadoAtual}");
  //   // Atualize a UI aqui com base no maquinaDeEstados.estadoAtual
  // });

  // Simulando eventos:
  print("--- INÍCIO DA SIMULAÇÃO ---");
  print("Estado inicial: ${maquinaDeEstados.estadoAtual.name}");

  maquinaDeEstados.processarEvento(EventoApp.BluetoothConectado);
  // maquinaDeEstados.processarEvento(EventoApp.FaceDetectada);
  // maquinaDeEstados.processarEvento(EventoApp.TempoSeguroExpirado);
  // maquinaDeEstados.processarEvento(EventoApp.SemResposta);
  // maquinaDeEstados.processarEvento(EventoApp.ComResposta);

  // print("\n--- TESTANDO OUTRA RAMIFICAÇÃO ---");
  // maquinaDeEstados.definirEstadoParaTeste(EstadoApp.Conectado);
  // maquinaDeEstados.processarEvento(EventoApp.CarroAndando);
  // maquinaDeEstados.processarEvento(EventoApp.BluetoothDesconectado);
  // maquinaDeEstados.processarEvento(EventoApp.BluetoothConectado);
  // maquinaDeEstados.definirEstadoParaTeste(EstadoApp.PerdaDeConexao);
  // maquinaDeEstados.processarEvento(EventoApp.ComResposta);
  print("--- FIM DA SIMULAÇÃO ---");
}
*/

