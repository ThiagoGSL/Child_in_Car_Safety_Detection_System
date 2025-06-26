import 'dart:async';
import 'dart:math'; // Para cálculo de magnitude (sensores)
import 'package:app_v0/features/services/sensores_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Para acelerômetro e giroscópio
import 'package:geolocator/geolocator.dart'; // Para geolocalização
import 'package:fl_chart/fl_chart.dart'; // Para os gráficos
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  if (action.buttonKeyPressed == 'CONFIRM_OK') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkinConfirmed', true);
    await AwesomeNotifications().cancel(1); // Cancela a notificação de alerta
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Solicita permissão de notificação ao iniciar o app
  await Permission.notification.request();

  // Inicializa o plugin AwesomeNotifications e os canais de notificação
  await AwesomeNotifications().initialize(
    null, // @mipmap/ic_launcher - Use o ícone padrão do seu app
    [
      NotificationChannel(
        channelKey: 'checkin_channel',
        channelName: 'Check-In',
        channelDescription: 'Canal de check-in',
        importance: NotificationImportance.High,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'alert_channel',
        channelName: 'Alerta de Perigo',
        channelDescription: 'Canal de alerta',
        importance: NotificationImportance.Max,
        playSound: true,
      ),
    ],
    debug: true, // Define como true para ver logs de depuração no console
  );

  // Registra o handler global para ações de notificação
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SensorPage(), // Define SensorPage como a tela inicial do aplicativo
      debugShowCheckedModeBanner: false, // Remove o banner de debug
    );
  }
}


enum CheckinStatus { idle, pending, confirmed, timeout }
enum VehicleState { moving, stopped, unknown } // Para o status de movimento real


class SensorGraph extends StatefulWidget {
  final String tipo; // 'x', 'y', ou 'z'
  final Stream<AccelerometerEvent> accelerometerStream; // Recebe o stream do acelerômetro

  const SensorGraph({Key? key, required this.tipo, required this.accelerometerStream}) : super(key: key);

  @override
  State<SensorGraph> createState() => _SensorGraphState();
}

class _SensorGraphState extends State<SensorGraph> {
  List<FlSpot> _spots = [];
  double _minY = -10.0; // Valores padrão para o gráfico do acelerômetro
  double _maxY = 10.0;
  final int _maxDataPoints = 50; // Quantidade máxima de pontos no gráfico

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(covariant SensorGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tipo != widget.tipo || oldWidget.accelerometerStream != widget.accelerometerStream) {
      _stopListening();
      _startListening();
    }
  }

  void _startListening() {
    _accelerometerSubscription = widget.accelerometerStream.listen((event) {
      setState(() {
        double value;
        switch (widget.tipo) {
          case 'x':
            value = event.x;
            break;
          case 'y':
            value = event.y;
            break;
          case 'z':
            value = event.z;
            break;
          default:
            value = 0.0;
        }

        // Adiciona o novo ponto
        _spots.add(FlSpot(_spots.length.toDouble(), value));

        // Remove pontos antigos se exceder o limite
        if (_spots.length > _maxDataPoints) {
          _spots.removeAt(0);
          // Atualiza os X de todos os pontos para que o gráfico "role"
          _spots = _spots.map((spot) => FlSpot(spot.x - 1, spot.y)).toList();
        }

        // Ajusta os limites Y do gráfico dinamicamente
        _minY = _spots.map((e) => e.y).reduce(min) - 1.0;
        _maxY = _spots.map((e) => e.y).reduce(max) + 1.0;
        if (_minY.abs() < 1.0 && _maxY.abs() < 1.0) { // Evitar zoom excessivo em valores muito pequenos
          _minY = -1.0;
          _maxY = 1.0;
        }
      });
    });
  }

  void _stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Color _getLineColor() {
    switch (widget.tipo) {
      case 'x': return Colors.red;
      case 'y': return Colors.green;
      case 'z': return Colors.blue;
      default: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: _minY,
        maxY: _maxY,
        minX: _spots.isEmpty ? 0 : _spots.first.x,
        maxX: _spots.isEmpty ? (_maxDataPoints -1).toDouble() : _spots.last.x,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (_maxY - _minY) / 5,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // Oculta números no eixo X, pois o gráfico é dinâmico
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            color: _getLineColor(),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _getLineColor().withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// ======================================================================
/// CLASSE SensorPage (AGORA COM SENSORES E GRÁFICOS INTEGRADOS)
/// ======================================================================
class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> with WidgetsBindingObserver {
  // Timers para controlar os contadores de "parado" e "alerta"
  Timer? _parkedTimer, _alertTimer;
  // Segundos restantes para o check-in e para o alerta
  int _checkinSeconds = 0, _alertSeconds = 0;
  // Status atual do check-in
  CheckinStatus _status = CheckinStatus.idle;

  // --- Variáveis para Sensores e Gráficos (NOVO) ---
  // Streams para dados dos sensores
  final _accelerometerController = StreamController<AccelerometerEvent>.broadcast();
  final _gyroscopeController = StreamController<GyroscopeEvent>.broadcast();
  final _locationController = StreamController<Position>.broadcast();

  // Variáveis para exibição na UI
  String _accelerometerDisplay = 'Accel\nX: 0.00\nY: 0.00\nZ: 0.00';
  String _gyroscopeDisplay = 'Gyro\nX: 0.00\nY: 0.00\nZ: 0.00';
  String _locationDisplay = 'Lat: 0.000000\nLon: 0.000000';

  // Status do movimento real do veículo (determinado pelos sensores)
  VehicleState _actualVehicleState = VehicleState.unknown;
  // Flag para indicar se a coleta de dados está ativa (para economia de energia)
  bool _isCollectingData = true;

  // Timers e thresholds para detecção de movimento/parada
  Timer? _stopDetectionTimer; // Timer para confirmar que o carro parou
  static const double _movementThreshold = 0.5; // m/s^2 (Limiar de aceleração para considerar movimento)
  static const int _stopDelaySeconds = 3; // Tempo em segundos para confirmar que o carro está parado

  // --- Subscrições de Stream (NOVO) ---
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _locationSubscription;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreStatus(); // Restaura o status do check-in ao iniciar o app
    _initSensorMonitoring(); // Inicia o monitoramento dos sensores
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    _stopDetectionTimer?.cancel(); // Cancela o timer de detecção de parada

    // Fecha os controllers e cancela as subscrições dos sensores
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _accelerometerController.close();
    _gyroscopeController.close();
    _locationController.close();

    super.dispose();
  }

  // Monitora o ciclo de vida do aplicativo para verificar confirmação ao retornar
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForConfirmation(); // Checa se o check-in foi confirmado enquanto o app estava em segundo plano
    }
  }

  // ============================================================
  // LÓGICA DE SENSORES E DETECÇÃO DE MOVIMENTO (NOVO)
  // ============================================================
  void _initSensorMonitoring() async {
    // Escuta eventos do acelerômetro
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (_isCollectingData) {
        _accelerometerController.sink.add(event); // Envia para o stream do gráfico
        _detectVehicleState(event); // Lógica para detectar o estado do veículo
        setState(() {
          _accelerometerDisplay = 'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
        });
      }
    });

    // Escuta eventos do giroscópio
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (_isCollectingData) {
        _gyroscopeController.sink.add(event);
        setState(() {
          _gyroscopeDisplay = 'Gyro\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
        });
      }
    });

    _getLocationUpdates(); // Inicia o monitoramento de localização
  }

  Future<void> _getLocationUpdates() async {
    // Verifica e solicita permissão de localização
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showInfoDialog('Permissão de Localização', 'Permissão de localização negada. O monitoramento de GPS não funcionará.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showInfoDialog('Permissão de Localização', 'Permissão de localização permanentemente negada. Habilite nas configurações do aplicativo.');
      return;
    }

    // Escuta atualizações de posição
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Atualiza a cada 1 metro
      ),
    ).listen((position) {
      if (_isCollectingData) {
        _locationController.sink.add(position);
        setState(() {
          _locationDisplay = 'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
        });
      }
    }, onError: (e) {
      print('Erro na localização: $e');
    });
  }

  void _detectVehicleState(AccelerometerEvent event) {
    // Calcula a magnitude da aceleração vetorial
    final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Se a magnitude estiver abaixo do limiar, inicia/continua o timer de parada
    if (magnitude < _movementThreshold) {
      if (_stopDetectionTimer == null || !_stopDetectionTimer!.isActive) {
        _stopDetectionTimer = Timer(Duration(seconds: _stopDelaySeconds), () {
          _updateActualVehicleState(VehicleState.stopped);
        });
      }
    } else {
      // Se houver movimento significativo, cancela o timer e define como "moving"
      _stopDetectionTimer?.cancel();
      _updateActualVehicleState(VehicleState.moving);
    }
  }

  void _updateActualVehicleState(VehicleState newState) {
    if (newState != _actualVehicleState) {
      setState(() {
        _actualVehicleState = newState;
      });

      if (newState == VehicleState.stopped) {
        _onCarStopped(); // Chama a lógica de check-in quando o carro REALMENTE para
        _pauseDataCollection();
      } else if (newState == VehicleState.moving) {
        _onCarMoving(); // Chama a lógica de check-in quando o carro REALMENTE se move
        _resumeDataCollection();
      }
    }
  }

  void _pauseDataCollection() {
    if (_isCollectingData) {
      setState(() {
        _isCollectingData = false;
      });
      _showInfoDialog('Coleta de Dados Pausada', 'Veículo parado. Coleta de dados de sensores em segundo plano pausada para economizar bateria.');
    }
  }

  void _resumeDataCollection() {
    if (!_isCollectingData) {
      setState(() {
        _isCollectingData = true;
      });
      _showInfoDialog('Coleta de Dados Retomada', 'Veículo em movimento. Coleta de dados de sensores retomada.');
    }
  }

  // ============================================================
  // LÓGICA DE NOTIFICAÇÃO E CHECK-IN (Modificada para usar sensores)
  // ============================================================

  // Restaura o status de confirmação salvo nas preferências compartilhadas
  Future<void> _restoreStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      setState(() => _status = CheckinStatus.confirmed);
      await prefs.remove('checkinConfirmed'); // Remove o flag após restaurar
    }
  }

  // Verifica se o check-in foi confirmado via notificação
  Future<void> _checkForConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      await prefs.remove('checkinConfirmed');
      _confirmCheckin(); // Se confirmado, atualiza o UI e cancela timers/notificações
    }
  }

  // Lógica para confirmar o check-in
  void _confirmCheckin() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    AwesomeNotifications().cancel(1); // Cancela a notificação de alerta (ID 1)
    setState(() => _status = CheckinStatus.confirmed);
  }

  // Lógica quando o carro para (Chamado por _updateActualVehicleState)
  void _onCarStopped() {
    _resetAllTimersAndNotifications(); // Reseta todos os estados e timers
    setState(() {
      _status = CheckinStatus.pending; // Estado pendente de check-in
      _checkinSeconds = 30; // Inicia o contador de 30 segundos
    });
    // Inicia o timer de check-in
    _parkedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_checkinSeconds > 0) {
        setState(() => _checkinSeconds--);
      } else {
        t.cancel();
        _showCheckinNotification(); // Mostra a notificação de check-in
      }
    });
  }

  // Lógica quando o carro está em movimento (Chamado por _updateActualVehicleState)
  void _onCarMoving() {
    _resetAllTimersAndNotifications(); // Reseta todos os estados e timers
    setState(() {
      _status = CheckinStatus.idle; // Retorna ao estado ocioso
    });
  }

  // Reseta todos os timers, contadores e cancela todas as notificações
  void _resetAllTimersAndNotifications() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    setState(() {
      _checkinSeconds = 0;
      _alertSeconds = 0;
      // Não reseta _status aqui, pois ele é definido por _onCarStopped/_onCarMoving
    });
    AwesomeNotifications().cancelAll();
  }

  // Mostra a notificação de check-in
  Future<void> _showCheckinNotification() async {
    if (_status != CheckinStatus.pending) return; // Só mostra se o status for pendente
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0, // ID da notificação de check-in
        channelKey: 'checkin_channel',
        title: '⚠️ Veículo parado',
        body: 'Seu veículo está parado há 30 segundos. Tudo OK?',
      ),
      actionButtons: [
        NotificationActionButton(
            key: 'CONFIRM_OK', label: 'Tudo OK?', autoDismissible: true), // Botão de ação na notificação
      ],
    );
    _startAlertCountdown(); // Inicia o contador para o alerta de perigo
  }

  // Inicia o contador para a notificação de alerta de perigo
  void _startAlertCountdown() {
    if (_status != CheckinStatus.pending) return; // Só inicia se o status for pendente
    setState(() => _alertSeconds = 30); // Define 30 segundos para o alerta
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_alertSeconds > 0) {
        setState(() => _alertSeconds--);
      } else {
        t.cancel();
        setState(() => _status = CheckinStatus.timeout); // Muda o status para timeout
        _showDangerNotification(); // Mostra a notificação de perigo
      }
    });
  }

  // Mostra a notificação de perigo
  Future<void> _showDangerNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1, // ID da notificação de perigo (para poder ser cancelada)
        channelKey: 'alert_channel',
        title: '🚨 Bebê em perigo!',
        body: 'Nenhuma resposta. Alerta enviado.',
      ),
    );
  }

  // Exibe um diálogo de informação
  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTERFACE DE USUÁRIO (BUILD METHOD)
  // ============================================================
  @override
  Widget build(BuildContext ctx) {
    // Mapeamento de status para textos visíveis na UI
    final checkinLabels = {
      CheckinStatus.idle: '—',
      CheckinStatus.pending: 'Aguardando resposta',
      CheckinStatus.confirmed: 'Confirmado: Tudo OK',
      CheckinStatus.timeout: 'Não confirmado: Alerta enviado',
    };
    // Mapeamento de status para cores de fundo na UI
    final checkinColors = {
      CheckinStatus.idle: Colors.grey,
      CheckinStatus.pending: Colors.orange,
      CheckinStatus.confirmed: Colors.green,
      CheckinStatus.timeout: Colors.red,
    };

    final vehicleStateLabels = {
      VehicleState.moving: '🚗 Em movimento (Detectado)',
      VehicleState.stopped: '⏸️ Parado (Detectado)',
      VehicleState.unknown: '❓ Analisando Estado do Veículo...',
    };

    final vehicleStateColors = {
      VehicleState.moving: Colors.green,
      VehicleState.stopped: Colors.red,
      VehicleState.unknown: Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Monitor de Segurança')),
      body: SingleChildScrollView( // Permite rolagem
        padding: const EdgeInsets.all(20), // Padding geral no corpo da tela
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de Status do Carro (real)
            Container(
              width: double.infinity, // Ocupa toda a largura disponível
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vehicleStateColors[_actualVehicleState],
                borderRadius: BorderRadius.circular(8), // Cantos arredondados
              ),
              child: Text(
                vehicleStateLabels[_actualVehicleState]!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20), // Espaçamento vertical

            // Dados dos Sensores
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dados dos Sensores:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text(_accelerometerDisplay, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(_gyroscopeDisplay, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(_locationDisplay, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status da Coleta de Dados
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCollectingData ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isCollectingData ? Colors.green : Colors.orange,
                ),
              ),
              child: Text(
                _isCollectingData
                    ? '✅ Coletando dados (sensores ativos)'
                    : '⏸️ Coleta pausada (veículo parado para economia de energia)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isCollectingData ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Indicadores de Tempo (Cronômetros)
            if (_checkinSeconds > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⏱️ Check-in em: $_checkinSeconds s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            if (_alertSeconds > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🚨 Alerta em: $_alertSeconds s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 20), // Espaçamento vertical

            // Indicador de Status do Check-in/Alerta
            Container(
              width: double.infinity, // Ocupa toda a largura disponível
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: checkinColors[_status], // Cor baseada no status do check-in
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                checkinLabels[_status]!, // Texto baseado no status do check-in
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30), // Espaçamento vertical

            // Botões de Simulação (agora para testar a lógica do check-in/alerta)
            // Estes botões NÃO simulam os dados reais do sensor, mas disparam a lógica de notificação.
            // O estado do veículo é determinado pelos sensores, não mais por esses botões diretamente.
            const Text(
              'Botões de Teste da Lógica (NÃO simulam sensores reais):',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Simula que o carro parou E chama a lógica de notificação
                    _updateActualVehicleState(VehicleState.stopped);
                    // O carro parar via simulação aqui irá acionar o timer de 30s
                    // e a notificação de check-in, assim como os sensores reais fariam.
                  },
                  child: const Text('Simular Carro Parado'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Simula que o carro está em movimento E chama a lógica de reset
                    _updateActualVehicleState(VehicleState.moving);
                  },
                  child: const Text('Simular Carro em Movimento'),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Título para os gráficos
            const Text(
              'Gráficos do Acelerômetro',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Gráfico do eixo X
            _buildGraphCard('Eixo X', 'x', Colors.red),
            const SizedBox(height: 20),

            // Gráfico do eixo Y
            _buildGraphCard('Eixo Y', 'y', Colors.green),
            const SizedBox(height: 20),

            // Gráfico do eixo Z
            _buildGraphCard('Eixo Z', 'z', Colors.blue),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para construir um card de gráfico
  Widget _buildGraphCard(String title, String type, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250, // Altura fixa para o gráfico
              child: SensorGraph(tipo: type, accelerometerStream: _accelerometerController.stream),
            ),
          ],
        ),
      ),
    );
  }
}