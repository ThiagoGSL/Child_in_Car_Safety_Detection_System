import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app_v0/features/photos/photo_controller.dart'; // Verifique se o caminho está correto
import 'package:flutter/material.dart';
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
  var isConnecting = false.obs;
  var connectedDeviceName = ''.obs;
  var foundDevices = <DiscoveredDevice>[].obs;
  
  // Variável dedicada para o dispositivo conectado
  var connectedDevice = Rx<DiscoveredDevice?>(null);

  var receivedImage = Rx<Uint8List?>(null);
  var childDetected = false.obs;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _photoSub;
  StreamSubscription<List<int>>? _childSub;

  final List<int> _imageBuffer = [];
  bool _receivingImage = false;
  int? _lastByteOfPrevChunk;
  bool _decodingInProgress = false;

  late final PhotoController _photoController;

  DateTime? _receptionStartTime;

  @override
  void onInit() {
    super.onInit();
    _photoController = Get.find<PhotoController>();
    flutterReactiveBle.statusStream.listen((status) {
      print('BLE status: $status');
      if (status == BleStatus.ready) {
        startAutoScan();
      }
    });

    ever(receivedImage, (Uint8List? ImageData){
      if (ImageData != null && ImageData.isNotEmpty) {
        Get.snackbar(
          "Foto Recebida!",
           "Uma nova imagem foi recebida do ESP32CAM",
           snackPosition: SnackPosition.TOP,
           backgroundColor: Colors.green,
           colorText: Colors.white,
           margin: const EdgeInsets.all(10),
           duration: const Duration(seconds: 4),);
      }
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

  void startAutoScan() async {
    if (isConnected.value || isConnecting.value || isScanning.value) return;
    if (!await _checkPermissions()) {
      print('Permissões de Bluetooth e Localização não concedidas.');
      return;
    }

    print('🏁 Iniciando varredura automática pelo Service UUID: $serviceUuid');
    isScanning.value = true;
    
    // Não limpa 'foundDevices' aqui para não afetar a UI da BlePage se ela estiver aberta
    _scanSub?.cancel();
    _scanSub = flutterReactiveBle.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      print('✅ Dispositivo com o serviço correto encontrado! (${device.name}, ${device.id})');
      stopScan();
      connectToDevice(device);
    }, onError: (e) {
      print('Erro na varredura automática: $e');
      isScanning.value = false;
    });
  }

  void startManualScan() async {
    if (isScanning.value || isConnecting.value) return;
    if (!await _checkPermissions()) {
      print('Permissões não concedidas');
      return;
    }

    print('🏁 Iniciando varredura MANUAL por todos os dispositivos...');
    foundDevices.clear(); // Limpa a lista para uma nova busca
    isScanning.value = true;

    _scanSub?.cancel();
    _scanSub = flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency)
        .listen((device) {
      if (device.name.isNotEmpty && !foundDevices.any((d) => d.id == device.id)) {
        foundDevices.add(device);
      }
    }, onError: (e) {
      print('Erro na varredura manual: $e');
      isScanning.value = false;
    });

    Future.delayed(const Duration(seconds: 10), stopScan);
  }

  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
    isScanning.value = false;
    print('🛑 Varredura parada.');
  }

  void connectToDevice(DiscoveredDevice device) {
    if (isConnecting.value || isConnected.value) return;

    stopScan();
    isConnecting.value = true;
    connectedDeviceName.value = device.name.isNotEmpty ? device.name : device.id;

    _connSub?.cancel();
    _connSub = flutterReactiveBle.connectToDevice(
      id: device.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [photoCharUuid, childCharUuid]
      },
      connectionTimeout: const Duration(seconds: 15),
    ).listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        print('🔗 Conectado ao ${device.name}');
        
        connectedDevice.value = device; 
        
        try {
          final mtu = await flutterReactiveBle.requestMtu(
              deviceId: device.id, mtu: 247);
          print('MTU negociado: $mtu');
          await flutterReactiveBle.requestConnectionPriority(
              deviceId: device.id, priority: ConnectionPriority.highPerformance);
          print('Solicitada prioridade de conexão alta.');
        } catch (e) {
          print('Erro ao solicitar MTU ou prioridade: $e');
        }

        isConnected.value = true;
        isConnecting.value = false;
        _subscribeToCharacteristics(device.id);
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        print('❌ Desconectado de ${device.name}');
        disconnect();
        Future.delayed(const Duration(seconds: 5), startAutoScan);
      }
    }, onError: (e) {
      print('Erro na conexão: $e');
      disconnect();
      Future.delayed(const Duration(seconds: 5), startAutoScan);
    });
  }

  void disconnect() {
    _connSub?.cancel();
    _photoSub?.cancel();
    _childSub?.cancel();
    _connSub = null;
    _photoSub = null;
    _childSub = null;

    isConnected.value = false;
    isConnecting.value = false;
    connectedDeviceName.value = '';
    
    connectedDevice.value = null; 
    
    receivedImage.value = null;
    childDetected.value = false;

    _imageBuffer.clear();
    _receivingImage = false;
    _lastByteOfPrevChunk = null;
    _decodingInProgress = false;

    print('🔌 Conexão encerrada.');
    Future.delayed(const Duration(seconds: 5), startAutoScan);
  }
  
  void _subscribeToCharacteristics(String deviceId) {
    _photoSub?.cancel();
    _childSub?.cancel();

    _imageBuffer.clear();
    _receivingImage = false;
    _lastByteOfPrevChunk = null;
    _decodingInProgress = false;
    _receptionStartTime = null;

    _photoSub = flutterReactiveBle
        .subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: photoCharUuid,
    ))
        .listen((chunk) async {
      print('📦 Chunk recebido: ${chunk.length} bytes');
      int i = 0;
      if (!_receivingImage &&
          _lastByteOfPrevChunk == 0xFF &&
          chunk.isNotEmpty &&
          chunk[0] == 0xD8) {
        print('🟢 Início JPEG detectado entre chunks');
        _receptionStartTime = DateTime.now();
        _receivingImage = true;
        _imageBuffer.clear();
        _imageBuffer.add(0xFF);
      }

      while (i < chunk.length) {
        if (!_receivingImage) {
          if (i < chunk.length - 1 &&
              chunk[i] == 0xFF &&
              chunk[i + 1] == 0xD8) {
            print('🟢 Início JPEG detectado dentro do chunk');
            _receptionStartTime = DateTime.now();
            _receivingImage = true;
            _imageBuffer.clear();
            _imageBuffer.add(0xFF);
            _imageBuffer.add(0xD8);
            i += 2;
          } else {
            i++;
          }
        } else {
          _imageBuffer.add(chunk[i]);

          if (i < chunk.length - 1 &&
              chunk[i] == 0xFF &&
              chunk[i + 1] == 0xD8) {
            print('⚠️ Novo início JPEG antes do fim do anterior. Reiniciando...');
            _receptionStartTime = DateTime.now();
            _imageBuffer.clear();
            _imageBuffer.add(0xFF);
            _imageBuffer.add(0xD8);
            i += 2;
            continue;
          }

          int len = _imageBuffer.length;
          if (len >= 2 &&
              _imageBuffer[len - 2] == 0xFF &&
              _imageBuffer[len - 1] == 0xD9) {
            
            final eoiDetectionTime = DateTime.now();
            if (_receptionStartTime != null) {
              final receptionDuration =
                  eoiDetectionTime.difference(_receptionStartTime!);
              print(
                  'DEBUG: 📸 Imagem completa recebida em ${receptionDuration.inMilliseconds} ms.');
            }
            print('✅ JPEG completo com $len bytes');

            final data = Uint8List.fromList(List<int>.from(_imageBuffer));

            if (_decodingInProgress) {
              print('⚠️ Ignorando imagem pois outra está sendo decodificada');
              _imageBuffer.clear();
              _receivingImage = false;
              _lastByteOfPrevChunk = null;
              return;
            }

            _decodingInProgress = true;
            try {
              final decodingStartTime = DateTime.now();
              ui.decodeImageFromList(data, (ui.Image img) {
                
                final decodingDuration =
                    DateTime.now().difference(decodingStartTime);
                final totalDuration = _receptionStartTime != null
                    ? DateTime.now().difference(_receptionStartTime!)
                    : null;
                final durationSinceEoi = DateTime.now().difference(eoiDetectionTime);
                print('DEBUG: ⏱️ Tempo (FIM RECEPÇÃO -> FIM DECODIFICAÇÃO): ${durationSinceEoi.inMilliseconds} ms.');

                print(
                    'DEBUG: 🖼️ Imagem decodificada em ${decodingDuration.inMilliseconds} ms.');
                if (totalDuration != null) {
                  print(
                      'DEBUG: ⏱️ Tempo TOTAL (INÍCIO RECEPÇÃO -> FIM DECODIFICAÇÃO): ${totalDuration.inMilliseconds} ms.');
                }

                try {
                  print('🖼️ JPEG decodificado: ${img.width}x${img.height}');
                  receivedImage.value = data;
                  _photoController.saveImage(data);
                } catch (e) {
                  print('❌ Erro na callback de decodificação: $e');
                } finally {
                  _decodingInProgress = false;
                }
              });
            } catch (e) {
              print('❌ Erro ao iniciar decodificação da imagem: $e');
              _decodingInProgress = false;
            }

            _imageBuffer.clear();
            _receivingImage = false;
            _lastByteOfPrevChunk = null;
          }
          i++;
        }
      }

      _lastByteOfPrevChunk = chunk.isNotEmpty ? chunk.last : null;

      if (_receivingImage && _imageBuffer.length > 150000) {
        print(
            '🚨 Buffer muito grande (${_imageBuffer.length} bytes). Descartando...');
        _imageBuffer.clear();
        _receivingImage = false;
        _decodingInProgress = false;
      }
    }, onError: (e) {
      print('Erro ao receber imagem: $e');
      _imageBuffer.clear();
      _receivingImage = false;
      _decodingInProgress = false;
    });

    _childSub = flutterReactiveBle
        .subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: childCharUuid,
    ))
        .listen((data) {
      var str = String.fromCharCodes(data);
      childDetected.value = str.toLowerCase() == 'true' || str == '1';
    }, onError: (e) {
      print('Erro ao receber dado child: $e');
    });
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