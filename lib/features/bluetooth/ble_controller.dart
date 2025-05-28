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
  var isConnecting = false.obs;  // estado de conexão em progresso
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
    if (isScanning.value) return;
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
    if (isConnecting.value || isConnected.value) return;

    stopScan();
    isConnecting.value = true;
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
        .listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        print('🔗 Conectado ao ${device.name}');
        
        // Solicitar MTU 200 aqui:
        try {
          final mtu = await flutterReactiveBle.requestMtu(deviceId: device.id, mtu: 200);
          print('MTU negociado: $mtu');
        } catch (e) {
          print('Erro ao solicitar MTU: $e');
        }

        isConnected.value = true;
        isConnecting.value = false;
        _subscribeToCharacteristics(device.id);
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        print('❌ Desconectado de ${device.name}');
        isConnected.value = false;
        isConnecting.value = false;
        connectedDeviceName.value = '';
      }
    }, onError: (e) {
      print('Erro conexão: $e');
      isConnected.value = false;
      isConnecting.value = false;
      connectedDeviceName.value = '';
    });
  }

  void disconnect() {
    _connSub?.cancel();
    _photoSub?.cancel();
    _childSub?.cancel();
    isConnected.value = false;
    isConnecting.value = false;
    connectedDeviceName.value = '';
    receivedImage.value = null;
    childDetected.value = false;
    print('🔌 Desconectado manualmente');
  }

  void _subscribeToCharacteristics(String deviceId) {
    _photoSub?.cancel();
    _childSub?.cancel();
    _imageBuffer.clear();
    _receivingImage = false;

    _photoSub = flutterReactiveBle
        .subscribeToCharacteristic(QualifiedCharacteristic(
          deviceId: deviceId,
          serviceId: serviceUuid,
          characteristicId: photoCharUuid,
        ))
        .listen((chunk) {
      print('📦 Chunk recebido: ${chunk.length} bytes');

      // Detecta múltiplos SOI e reinicia o buffer no início de cada imagem
      for (int i = 0; i < chunk.length - 1; i++) {
        if (chunk[i] == 0xFF && chunk[i + 1] == 0xD8) {
          print('▶️ Início do JPEG detectado - reiniciando buffer');
          _receivingImage = true;
          _imageBuffer.clear();
          _imageBuffer.add(chunk[i]);
          _imageBuffer.add(chunk[i + 1]);
          if (i + 2 < chunk.length) {
            _imageBuffer.addAll(chunk.sublist(i + 2));
          }
          return; // Processou esse chunk; sai do loop
        }
      }

      if (_receivingImage) {
        _imageBuffer.addAll(chunk);

        // Verifica fim do JPEG
        for (int i = 0; i < _imageBuffer.length - 1; i++) {
          if (_imageBuffer[i] == 0xFF && _imageBuffer[i + 1] == 0xD9) {
            print('🔚 Fim do JPEG detectado');
            final data = Uint8List.fromList(_imageBuffer);
            receivedImage.value = data;
            print('✅ Imagem recebida: ${data.length} bytes');
            _receivingImage = false;
            _imageBuffer.clear();
            break;
          }
        }
      }
    }, onError: (e) => print('Erro foto: $e'));

    _childSub = flutterReactiveBle
        .subscribeToCharacteristic(QualifiedCharacteristic(
          deviceId: deviceId,
          serviceId: serviceUuid,
          characteristicId: childCharUuid,
        ))
        .listen((data) {
      var str = String.fromCharCodes(data);
      childDetected.value = str.toLowerCase() == 'true' || str == '1';
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
