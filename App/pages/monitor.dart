// lib/monitor.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart'; // Adicionado para a permissão no main se desejar
import '../services/sensores_service.dart';
// Importe seu Database_helper se ele for usado diretamente na IntegratedMonitorPage
// import 'Database_helper.dart'; // Removido pois dbHelper agora está no SensorService

/// Callback global para ações de notificação
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  if (action.buttonKeyPressed == 'CONFIRM_OK') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkinConfirmed', true);
    await AwesomeNotifications().cancel(1);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Mantenha a solicitação de permissão de notificação aqui, pois é um requisito geral do app
  await Permission.notification.request();

  // Inicializar notificações
  await AwesomeNotifications().initialize(
    null,
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
    debug: true,
  );

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor de Segurança',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: IntegratedMonitorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum CheckinStatus { idle, pending, confirmed, timeout }
// VehicleState agora vem do sensores_service.dart
// enum VehicleState { moving, stopped, unknown }


class IntegratedMonitorPage extends StatefulWidget {
  @override
  _IntegratedMonitorPageState createState() => _IntegratedMonitorPageState();
}

class _IntegratedMonitorPageState extends State<IntegratedMonitorPage>
    with WidgetsBindingObserver {

  // Instância do serviço de sensores
  late SensorService _sensorService;

  // Variáveis para exibição dos dados dos sensores
  String _accelerometerDisplay = 'Accel\nX: 0.00\nY: 0.00';
  String _gyroscopeDisplay = 'Gyro\nX: 0.00\nY: 0.00';
  String _locationDisplay = 'Lat: 0.000000\nLon: 0.000000';

  // Variáveis do sistema de notificação (mantidas aqui pois são da lógica do app)
  Timer? _parkedTimer, _alertTimer;
  int _checkinSeconds = 0, _alertSeconds = 0;
  VehicleState _vehicleState = VehicleState.unknown; // Agora vem do SensorService
  CheckinStatus _checkinStatus = CheckinStatus.idle;
  // A variável _isCollectingData aqui agora *reflete* o estado do SensorService
  bool _isCollectingData = true;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMonitorPage();
  }

  void _initializeMonitorPage() async {
    _sensorService = SensorService(); // Cria a instância do SensorService

    // Configura os callbacks para o SensorService
    _sensorService.onVehicleStateChanged = (newState) {
      setState(() {
        _vehicleState = newState;
      });
      if (newState == VehicleState.stopped) {
        _onVehicleStopped();
      } else if (newState == VehicleState.moving) {
        _onVehicleMoving();
      }
    };

    _sensorService.onInfoDialogRequested = (title, message) {
      _showInfoDialog(title, message);
      setState(() {
        // Atualiza a UI para refletir a pausa na coleta, usando o getter público do SensorService
        _isCollectingData = _sensorService.isCollectingData;
      });
    };

    // Escuta os streams dos sensores para atualizar a UI
    _sensorService.accelerometerStream.listen((event) {
      setState(() {
        _accelerometerDisplay = 'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });

    _sensorService.gyroscopeStream.listen((event) {
      setState(() {
        _gyroscopeDisplay = 'Gyro\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });

    _sensorService.locationStream.listen((position) {
      setState(() {
        _locationDisplay = 'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
      });
    });

    await _restoreStatus(); // Lógica de notificação
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    _sensorService.dispose(); // Importante: descartar o SensorService
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForConfirmation();
    }
  }

  // ============ SISTEMA DE NOTIFICAÇÕES (Lógica Principal do Aplicativo) ============

  Future<void> _restoreStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      setState(() => _checkinStatus = CheckinStatus.confirmed);
      prefs.remove('checkinConfirmed');
    }
  }

  Future<void> _checkForConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      prefs.remove('checkinConfirmed');
      _confirmCheckin();
    }
  }

  void _onVehicleStopped() {
    print('Veículo parou - iniciando timer de check-in');
    _resetNotificationTimers();
    setState(() {
      _checkinStatus = CheckinStatus.pending;
      _checkinSeconds = 30;
    });

    _parkedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_checkinSeconds > 0) {
        setState(() => _checkinSeconds--);
      } else {
        timer.cancel();
        _showCheckinNotification();
      }
    });
  }

  void _onVehicleMoving() {
    print('Veículo em movimento - cancelando alertas');
    _resetNotificationTimers();
    setState(() => _checkinStatus = CheckinStatus.idle);
    AwesomeNotifications().cancelAll();

    // Reativar coleta de dados no SensorService
    // Agora usando o método público resumeDataCollection() do SensorService
    _sensorService.resumeDataCollection();
    setState(() {
      _isCollectingData = _sensorService.isCollectingData; // Atualiza a UI para refletir a reativação
    });
  }

  void _resetNotificationTimers() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    setState(() {
      _checkinSeconds = 0;
      _alertSeconds = 0;
    });
  }

  Future<void> _showCheckinNotification() async {
    if (_checkinStatus != CheckinStatus.pending) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'checkin_channel',
        title: '⚠️ Veículo parado',
        body: 'Seu veículo está parado há 30 segundos. Tudo OK?',
      ),
      actionButtons: [
        NotificationActionButton(key: 'CONFIRM_OK', label: 'Tudo OK'),
      ],
    );
    _startAlertCountdown();
  }

  void _startAlertCountdown() {
    if (_checkinStatus != CheckinStatus.pending) return;
    setState(() => _alertSeconds = 30);

    _alertTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_alertSeconds > 0) {
        setState(() => _alertSeconds--);
      } else {
        timer.cancel();
        setState(() => _checkinStatus = CheckinStatus.timeout);
        _showDangerNotification();
      }
    });
  }

  Future<void> _showDangerNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'alert_channel',
        title: '🚨 Alerta de Emergência!',
        body: 'Nenhuma resposta recebida. Alerta de emergência ativado.',
      ),
    );
  }

  void _confirmCheckin() {
    _resetNotificationTimers();
    AwesomeNotifications().cancel(1);
    setState(() => _checkinStatus = CheckinStatus.confirmed);
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============ INTERFACE DE USUÁRIO ============

  @override
  Widget build(BuildContext context) {
    final statusLabels = {
      CheckinStatus.idle: '—',
      CheckinStatus.pending: 'Aguardando resposta',
      CheckinStatus.confirmed: 'Confirmado: Tudo OK',
      CheckinStatus.timeout: 'Alerta enviado',
    };

    final statusColors = {
      CheckinStatus.idle: Colors.grey,
      CheckinStatus.pending: Colors.orange,
      CheckinStatus.confirmed: Colors.green,
      CheckinStatus.timeout: Colors.red,
    };

    final vehicleStateLabels = {
      VehicleState.moving: '🚗 Em movimento',
      VehicleState.stopped: '⏸️ Parado',
      VehicleState.unknown: '❓ Analisando...',
    };

    final vehicleStateColors = {
      VehicleState.moving: Colors.green,
      VehicleState.stopped: Colors.red,
      VehicleState.unknown: Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Monitor de Segurança'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado do veículo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vehicleStateColors[_vehicleState],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vehicleStateLabels[_vehicleState]!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Dados dos sensores
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sensores:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_accelerometerDisplay, style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(_gyroscopeDisplay, style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(_locationDisplay, style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status da coleta
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
                    ? '✅ Coletando dados'
                    : '⏸️ Coleta pausada (aguardando movimento)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isCollectingData ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Timers
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Status do check-in
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColors[_checkinStatus],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabels[_checkinStatus]!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botões de teste (manter ou remover conforme necessário)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Simula uma parada do veículo forçando o SensorService a notificar
                    _sensorService.onVehicleStateChanged?.call(VehicleState.stopped);
                  },
                  child: Text('Simular Parada'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Simula movimento do veículo forçando o SensorService a notificar
                    _sensorService.onVehicleStateChanged?.call(VehicleState.moving);
                  },
                  child: Text('Simular Movimento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
