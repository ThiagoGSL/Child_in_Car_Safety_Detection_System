import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final flutterReactiveBle = FlutterReactiveBle();
  final serviceUuid = Uuid.parse('19b10000-e8f2-537e-4f6c-d104768a1214');
  final photoCharUuid = Uuid.parse('6df8c9f3-0d19-4457-aec9-befd07394aa0');
  final childCharUuid = Uuid.parse('4f0ebb9b-74a5-429e-83dd-ebc3a2b37421');

  var isConnected = false.obs;
  var isScanning = false.obs;
  var connectedDeviceName = ''.obs;
  var foundDevices = <DiscoveredDevice>[].obs;

  var receivedImage = Rx<Uint8List?>(null);
  var childDetected = false.obs;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _photoSub;
  StreamSubscription<List<int>>? _childSub;

  final List<int> _imageBuffer = [];
  bool _receivingImage = false;

  @override
  void onInit() {
    super.onInit();
    flutterReactiveBle.statusStream.listen((status) {
      print('BLE status: $status');
    });
  }

  Future<bool> _checkPermissions() async {
    var statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  void startScan() async {
    if (!await _checkPermissions()) return;
    foundDevices.clear();
    isScanning.value = true;

    _scanSub?.cancel();
    _scanSub = flutterReactiveBle
      .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
      .listen((device) {
        if (!foundDevices.any((d) => d.id == device.id)) {
          foundDevices.add(device);
        }
      }, onError: (e) {
        print('Erro scan: $e');
        isScanning.value = false;
      });

    Future.delayed(const Duration(seconds: 10), stopScan);
  }

  void stopScan() {
    _scanSub?.cancel();
    isScanning.value = false;
  }

  void connectToDevice(DiscoveredDevice device) {
    stopScan();
    connectedDeviceName.value = device.name;

    _connSub?.cancel();
    _connSub = flutterReactiveBle
      .connectToDevice(
        id: device.id,
        servicesWithCharacteristicsToDiscover: {
          serviceUuid: [photoCharUuid, childCharUuid]
        },
        connectionTimeout: const Duration(seconds: 10),
      )
      .listen((state) {
        if (state.connectionState == DeviceConnectionState.connected) {
          print('🔗 Conectado ao ${device.name}');
          isConnected.value = true;
          _subscribeToCharacteristics(device.id);
        } else if (state.connectionState == DeviceConnectionState.disconnected) {
          print('❌ Desconectado de ${device.name}');
          isConnected.value = false;
        }
      }, onError: (e) {
        print('Erro conexão: $e');
        isConnected.value = false;
      });
  }

  void _subscribeToCharacteristics(String deviceId) {
    _photoSub?.cancel();
    _childSub?.cancel();
    _imageBuffer.clear();
    _receivingImage = false;

    // 1) Foto
    _photoSub = flutterReactiveBle
      .subscribeToCharacteristic(QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: serviceUuid,
        characteristicId: photoCharUuid,
      ))
      .listen((chunk) {
        // Debug: cada fragmento recebido
        print('📦 Chunk recebido: ${chunk.length} bytes');

        // Detecta início JPEG (0xFF 0xD8)
        if (!_receivingImage) {
          for (int i = 0; i < chunk.length - 1; i++) {
            if (chunk[i] == 0xFF && chunk[i + 1] == 0xD8) {
              print('▶️ Início do JPEG detectado no chunk');
              _receivingImage = true;
              _imageBuffer.clear();
              break;
            }
          }
        }

        if (_receivingImage) {
          _imageBuffer.addAll(chunk);

          // Detecta fim JPEG (0xFF 0xD9)
          for (int i = 0; i < _imageBuffer.length - 1; i++) {
            if (_imageBuffer[i] == 0xFF && _imageBuffer[i + 1] == 0xD9) {
              print('🔚 Fim do JPEG detectado, montando imagem');
              final data = Uint8List.fromList(_imageBuffer);
              receivedImage.value = data;
              print('✅ Imagem completa recebida: ${data.length} bytes');
              _receivingImage = false;
              _imageBuffer.clear();
              return;
            }
          }
        }
      }, onError: (e) => print('Erro foto: $e'));

    // 2) Boolean CHILD
    _childSub = flutterReactiveBle
      .subscribeToCharacteristic(QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: serviceUuid,
        characteristicId: childCharUuid,
      ))
      .listen((data) {
        var str = String.fromCharCodes(data);
        childDetected.value = str.toLowerCase() == 'true' || str == '1';
        print('👶 Criança detectada: ${childDetected.value}');
      }, onError: (e) => print('Erro bool: $e'));
  }

  @override
  void onClose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _photoSub?.cancel();
    _childSub?.cancel();
    super.onClose();
  }
}
