// lib/services/sensores_service.dart

import 'dart:async';
import 'package:flutter/material.dart'; // Import necessário para WidgetsBindingObserver
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart'; // Adicione este import se DatabaseHelper usa sqflite
import '../Database/Database_helper.dart'; // Caminho para seu Database_helper
import 'package:speedometer/speedometer.dart';

enum VehicleState { moving, stopped, unknown }

class SensorService {
  // Variáveis dos sensores (para acesso externo ou exibição)
  double vx = 0, vy = 0, vz = 0;
  double ax = 0, ay = 0, az = 0;
  double gx = 0, gy = 0, gz = 0;
  double lat = 0, lon = 0;

  // Stream para notificar a UI sobre atualizações

  final _accelerometerController = StreamController<AccelerometerEvent>.broadcast();
  Stream<AccelerometerEvent> get accelerometerStream => _accelerometerController.stream;

  final _gyroscopeController = StreamController<GyroscopeEvent>.broadcast();
  Stream<GyroscopeEvent> get gyroscopeStream => _gyroscopeController.stream;

  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  // Variáveis para detecção de movimento
  List<double> _accelerationHistory = [];
  List<double> _locationHistory = [];
  final int _historySize = 10; // Tamanho do histórico para análise
  final double _movementThreshold = 2.0; // Limiar para detectar movimento (aceleração)
  final double _locationThreshold = 0.01; // ~11 metros (para localização)

  double _lastLat = 0, _lastLon = 0;
  int _unchangedLocationCount = 0;
  final int _maxUnchangedLocations = 6; // 30 segundos (5s * 6)

  // Variáveis de estado
  VehicleState _vehicleState = VehicleState.unknown;
  bool _isCollectingData = true; // Continua privada internamente

  // **** NOVO GETTER PÚBLICO PARA _isCollectingData ****
  bool get isCollectingData => _isCollectingData;


  // Timers para controle
  Timer? _sensorDataCollectionTimer; // Timer para coletar e processar dados periodicamente

  // Database helper
  final dbHelper = DatabaseHelper();

  // Callbacks para notificar a UI ou a lógica principal sobre o estado do veículo
  // Podem ser configurados externamente ao criar uma instância de SensorService
  Function(VehicleState)? onVehicleStateChanged;
  Function(String, String)? onInfoDialogRequested;


  SensorService() {
    _initializeSensors();
    _startSensorDataCollectionTimer();
  }

  void _initializeSensors() async {
    await _requestSensorPermissions();
    _listenToSensorEvents();
  }

  Future<void> _requestSensorPermissions() async {
    // Permissão de notificação pode ser solicitada no main.dart se for mais global.
    // Aqui, estamos focando nas permissões para os sensores em si.
    // await Permission.notification.request();
    await Permission.location.request();
  }

  void _listenToSensorEvents() {
    accelerometerEvents.listen((event) {
      ax = event.x;
      ay = event.y;
      az = event.z;
      _accelerometerController.add(event); // Adiciona ao stream
      double magnitude = (ax * ax + ay * ay + az * az);
      _updateAccelerationHistory(magnitude);
    });

    gyroscopeEvents.listen((event) {
      gx = event.x;
      gy = event.y;
      gz = event.z;
      _gyroscopeController.add(event); // Adiciona ao stream
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Mínima distância para atualizar (metros)
        timeLimit: Duration(seconds: 180), // Tempo limite para obter a posição
      ),
    ).listen((Position position) {
      lat = position.latitude;
      lon = position.longitude;
      _locationController.add(position); // Adiciona ao stream

      if (_lastLat != 0 && _lastLon != 0) {
        double distance = Geolocator.distanceBetween(_lastLat, _lastLon, lat, lon);
        _updateLocationHistory(distance);
      }
    });
  }

  void _updateAccelerationHistory(double magnitude) {
    _accelerationHistory.add(magnitude);
    if (_accelerationHistory.length > _historySize) {
      _accelerationHistory.removeAt(0);
    }
  }

  void _updateLocationHistory(double distance) {
    _locationHistory.add(distance);
    if (_locationHistory.length > _historySize) {
      _locationHistory.removeAt(0);
    }
  }

  bool _isVehicleMoving() {
    if (_accelerationHistory.length < 3 && _locationHistory.length < 3) {
      return false; // Dados insuficientes para uma decisão robusta
    }

    // Verificar movimento baseado na aceleração (variação)
    bool accelerationMovement = false;
    if (_accelerationHistory.length >= 3) {
      double avgAcceleration = _accelerationHistory.reduce((a, b) => a + b) / _accelerationHistory.length;
      double variance = 0;
      for (double acc in _accelerationHistory) {
        variance += (acc - avgAcceleration) * (acc - avgAcceleration);
      }
      variance /= _accelerationHistory.length;
      accelerationMovement = variance > _movementThreshold;
    }

    // Verificar movimento baseado na localização (mudança de coordenadas)
    bool locationMovement = false;
    if (_locationHistory.length >= 3) {
      double totalDistance = _locationHistory.reduce((a, b) => a + b);
      // Assumindo que a distanceFilter do Geolocator já nos dá a distância em metros
      locationMovement = totalDistance > 5;
    }

    return accelerationMovement || locationMovement;
  }

  void _startSensorDataCollectionTimer() {
    _sensorDataCollectionTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!_isCollectingData) return;

      // Determinar estado do veículo
      bool isMoving = _isVehicleMoving();
      VehicleState newState = isMoving ? VehicleState.moving : VehicleState.stopped;

      // Notificar mudança de estado do veículo
      if (newState != _vehicleState) {
        _vehicleState = newState;
        onVehicleStateChanged?.call(newState); // Chama o callback
      }

      // Verificar se a localização mudou significativamente para pausar a coleta
      bool locationChanged = _hasLocationChangedSignificantly();

      if (!locationChanged) {
        _unchangedLocationCount++;
      } else {
        _unchangedLocationCount = 0;
        _lastLat = lat;
        _lastLon = lon;
      }

      if (_unchangedLocationCount >= _maxUnchangedLocations && _vehicleState == VehicleState.stopped) {
        _isCollectingData = false; // Define o estado interno como não coletando
        onInfoDialogRequested?.call('Coleta pausada', 'Veículo parado por muito tempo. Coleta de dados pausada.');
      }

      // Armazenar dados no banco
      if (_isCollectingData) {
        await dbHelper.inserirAcelerometro(ax, ay);
        await dbHelper.inserirGiroscopio(gx, gy);
        await dbHelper.inserirLocalizacao(lat, lon);
      }
    });
  }

  bool _hasLocationChangedSignificantly() {
    double latDiff = (lat - _lastLat).abs();
    double lonDiff = (lon - _lastLon).abs();
    return latDiff > _locationThreshold || lonDiff > _locationThreshold;
  }

  // Método para reativar a coleta de dados manualmente ou quando o veículo volta a se mover
  void resumeDataCollection() {
    _isCollectingData = true; // Define o estado interno como coletando
    _unchangedLocationCount = 0;
    _startSensorDataCollectionTimer(); // Garante que o timer esteja rodando
  }

  void dispose() {
    _accelerometerController.close();
    _gyroscopeController.close();
    _locationController.close();
    _sensorDataCollectionTimer?.cancel();
  }
}