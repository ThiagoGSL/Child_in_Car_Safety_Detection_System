import 'dart:async';
import 'dart:math';
import 'package:app_v0/features/models/check.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import '../services/sensores_service.dart'; // Import the new repository

enum VehicleState {moving, stopped}

class VehicleDetectionController extends GetxController{
  final SensorDataRepository _repository = SensorDataRepository();

  var vehicleState = VehicleState.stopped.obs;
  var chechinStatus = CheckinStatus.idle.obs;
  var isCollectingData = true.obs;
  var checkinSeconds = 0.obs;
  var alertSeconds = 0.obs;
  var accelerometerDisplay = 'Accel\nX: 0.00\nY: 0.00\nZ: 0.00'.obs;
  var gyroscopeDisplay = 'Gyro\nX: 0.00\nY: 0.00\nZ: 0.00'.obs;
  var locationDisplay = 'Lat: 0.000000\nLon: 0.000000'.obs;

  Timer? _parkedTimer;
  Timer? _alertTimer;
  Timer? _stopDetectionTimer;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _locationSubscription;
  Position? _lastPosition;
  final accelerometerStreamController = StreamController<AccelerometerEvent>.broadcast();
  static const double _movementThreshold = 1.0; // Threshold for detecting acceleration movement
  static const double _locationThreshold = 0.0001;

  @override
  void onInit(){
    super.onInit();
    _restoreStatus();
    _initSensorMonitoring();
    print('SensorController iniciado');
  }

  @override
  void onClose() {
    // Cancela todos os timers e streams para evitar memory leaks
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    _stopDetectionTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    accelerometerStreamController.close();
    _repository.dispose(); // Também chama o dispose do repositório
    print("SensorController finalizado.");
    super.onClose();
  }

  void _initSensorMonitoring() {
    // Listener do acelerômetro (permanece igual)
    _accelerometerSubscription = _repository.accelerometerStream.listen((event) {
      if (isCollectingData.value) {
        accelerometerStreamController.sink.add(event);
        _detectVehicleStateByAccelerometer(event); // Renomeado para clareza
        accelerometerDisplay.value = 'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      }
    });

    _locationSubscription = _repository.locationStream.listen((position) {
      if (isCollectingData.value) {
        locationDisplay.value = 'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
      }


      // Se já temos uma posição anterior, calculamos a distância
      if (_lastPosition != null) {
        final double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Se a distância for maior que o nosso limite, consideramos como movimento
        if (distance > _locationMovementThresholdMeters) {
          print('Movimento detectado por GPS: ${distance.toStringAsFixed(1)}m');
          // Se o GPS detecta movimento, o estado DEVE ser "moving".
          // Isso cancela qualquer timer de parada que estivesse rodando.
          _updateActualVehicleState(VehicleState.moving);
        }
      }

      // Atualiza a última posição para a próxima verificação
      _lastPosition = position;

      // --- FIM DA NOVA LÓGICA ---

      _repository.saveCurrentSensorData();

    }, onError: (e) {
      print('Erro na localização: $e');
    });
  }


  void _detectVehicleState(AccelerometerEvent event){
    final double magnitude = sqrt(event.x*event.x + event.y*event.y + event.z*event.z);
    if (magnitude <_movementThreshold) {
      if (_stopDetectionTimer == null || !_stopDetectionTimer.isActive) {
        _stopDetectionTimer =
            Timer(const Duration(seconds: _stopDelaySeconds), () {
              _updateActualVehicleState(VehicleState.stopped);
            });
      }
    } else{
        _stopDetectionTimer?.cancel();
        _updateActualVehicleState(VehicleState.moving);

    }
  }

  void _updateActualVehicleState(VehicleState newState){
    if (newState != vehicleState.value){
      vehicleState.value = newState;

      if (newState == VehicleState.stopped){
        _onCarStopped();
        _pauseDataColletion();
      } else if (newState == VehicleState.moving){
        _onCarMoving();
        _resumeDataColletion();
      }
    }
  }

  void _pauseDataColletion() {
    if (isCollectingData.value) {
      isCollectingData.value = false;
      _showInforDialog('Coleta Pausada', 'Veículo parado.Coleta de dados pausada');
    }
  }

  void _resumeDataColletion(){
    if (!isCollectingData.value){
      isCollectingData.value = true;
      _showInfoDialog('Coleta Retomada', 'Veículo em Movimento');

    }
  }

  Future<void> onAppResumed()
  // Public getter for data collection status
  bool get isCollectingData => _isCollectingData;
  VehicleState get currentVehicleState => _vehicleState;


  // Timer for periodic data processing
  Timer? _detectionTimer;

  // Callbacks to notify UI or main logic
  Function(VehicleState)? onVehicleStateChanged;
  Function(String, String)? onInfoDialogRequested;

  VehicleDetectionController(this._sensorDataRepository) {
    _listenToSensorData();
    _startDetectionTimer();
  }

  void _listenToSensorData() {
    _sensorDataRepository.accelerometerStream.listen((event) {
      double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      _updateAccelerationHistory(magnitude);
    });

    _sensorDataRepository.locationStream.listen((position) {
      if (_lastLat != 0 && _lastLon != 0) {
        double distance = Geolocator.distanceBetween(_lastLat, _lastLon, position.latitude, position.longitude);
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
      return false; // Insufficient data for a robust decision
    }

    // Check movement based on acceleration (variance)
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

    // Check movement based on location (coordinate change)
    bool locationMovement = false;
    if (_locationHistory.length >= 3) {
      double totalDistance = _locationHistory.reduce((a, b) => a + b);
      locationMovement = totalDistance > 5; // Assuming distanceFilter of Geolocator gives distance in meters
    }

    return accelerationMovement || locationMovement;
  }

  void _startDetectionTimer() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Determine vehicle state
      bool isMoving = _isVehicleMoving();
      VehicleState newState = isMoving ? VehicleState.moving : VehicleState.stopped;

      // Notify vehicle state change
      if (newState != _vehicleState) {
        _vehicleState = newState;
        onVehicleStateChanged?.call(newState); // Call the callback
      }

      // Check if location has changed significantly to pause collection
      bool locationChanged = _hasLocationChangedSignificantly();

      if (!locationChanged) {
        _unchangedLocationCount++;
      } else {
        _unchangedLocationCount = 0;
        _lastLat = _sensorDataRepository.lat; // Update last known position from repository
        _lastLon = _sensorDataRepository.lon;
      }

      if (_unchangedLocationCount >= _maxUnchangedLocations && _vehicleState == VehicleState.stopped) {
        if (_isCollectingData) { // Only trigger if state is changing
          _isCollectingData = false; // Set internal state to not collecting
          onInfoDialogRequested?.call('Coleta pausada', 'Veículo parado por muito tempo. Coleta de dados pausada.');
        }
      } else {
        if (!_isCollectingData) { // If it was paused and now moving/location changed
          resumeDataCollection();
          onInfoDialogRequested?.call('Coleta de dados reativada', 'Veículo em movimento. Coleta de dados reativada.');
        }
      }

      // Store data in the database if collecting
      if (_isCollectingData) {
        await _sensorDataRepository.saveCurrentSensorData();
      }
    });
  }

  bool _hasLocationChangedSignificantly() {
    double latDiff = (_sensorDataRepository.lat - _lastLat).abs();
    double lonDiff = (_sensorDataRepository.lon - _lastLon).abs();
    return latDiff > _locationThreshold || lonDiff > _locationThreshold;
  }

  // Method to manually resume data collection or when the vehicle starts moving again
  void resumeDataCollection() {
    _isCollectingData = true; // Set internal state to collecting
    _unchangedLocationCount = 0;
    // The timer is already periodic, so no need to restart it here, just update the flag.
  }

  void dispose() {
    _detectionTimer?.cancel();
    // No need to dispose streams here, as they are managed by SensorDataRepository
  }
}
