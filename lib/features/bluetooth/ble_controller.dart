import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final flutterReactiveBle = FlutterReactiveBle();

  final String serviceUuid = "19b10000-e8f2-537e-4f6c-d104768a1214";
  final String characteristicUuid = "19b10001-e8f2-537e-4f6c-d104768a1214";

  final isConnected = false.obs;
  final isScanning = false.obs;
  final connectedDeviceName = "".obs;

  final foundDevices = <DiscoveredDevice>[].obs;

  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<BleStatus>? _bleStatusSub;

  @override
  void onInit() {
    super.onInit();

    // Monitorar o estado do BLE (opcional, mas pode ajudar)
    _bleStatusSub = flutterReactiveBle.statusStream.listen((status) {
      print("BLE status: $status");
      if (status != BleStatus.ready) {
        print("Bluetooth não está pronto!");
      }
    });
  }

  Future<bool> _checkPermissions() async {
    final permissions = [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      print("Permissões não concedidas: $statuses");
      return false;
    }
    return true;
  }

  void startScan() async {
    final granted = await _checkPermissions();
    if (!granted) {
      isScanning.value = false;
      return;
    }

    foundDevices.clear();
    isScanning.value = true;

    _scanStream?.cancel();

    _scanStream = flutterReactiveBle
        .scanForDevices(
          withServices: [], // ou [Uuid.parse(serviceUuid)]
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
      print("Encontrado: ID=${device.id}, NAME='${device.name}' RSSI=${device.rssi}");

      final exists = foundDevices.any((d) => d.id == device.id);
      if (!exists) {
        foundDevices.add(device);
      }
    }, onError: (err) {
      isScanning.value = false;
      print("Erro no scan: $err");
    });

    Future.delayed(const Duration(seconds: 10), stopScan);
  }

  void stopScan() {
    print("Scan parado");
    _scanStream?.cancel();
    isScanning.value = false;
  }

  void connectToDevice(DiscoveredDevice device) {
    stopScan();
    _connection?.cancel();

    connectedDeviceName.value = device.name;

    _connection = flutterReactiveBle
        .connectToDevice(
          id: device.id,
          servicesWithCharacteristicsToDiscover: {
            Uuid.parse(serviceUuid): [Uuid.parse(characteristicUuid)],
          },
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen((connectionState) {
      print("Estado de conexão: ${connectionState.connectionState}");

      if (connectionState.connectionState == DeviceConnectionState.connected) {
        isConnected.value = true;
        print("✅ Conectado a ${device.name}");
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        isConnected.value = false;
        print("❌ Desconectado de ${device.name}");
      }
    }, onError: (error) {
      isConnected.value = false;
      print("Erro ao conectar: $error");
    });
  }

  @override
  void onClose() {
    _scanStream?.cancel();
    _connection?.cancel();
    _bleStatusSub?.cancel();
    super.onClose();
  }
}
