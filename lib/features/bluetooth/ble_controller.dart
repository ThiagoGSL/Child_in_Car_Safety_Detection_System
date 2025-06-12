import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app_v0/features/photos/photo_controller.dart'; // Verifique se o caminho está correto
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

  // DEBUG: Variável para marcar o início da recepção da imagem
  DateTime? _receptionStartTime;

  @override
  void onInit() {
    super.onInit();
    flutterReactiveBle.statusStream.listen((status) {
      print('BLE status: $status');
    });
    _photoController = Get.find<PhotoController>();
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
    if (!await _checkPermissions()) {
      print('Permissões não concedidas');
      return;
    }

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
        try {
          final mtu = await flutterReactiveBle.requestMtu(
              deviceId: device.id, mtu: 247); // MTU pode ser ajustado
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
      }
    }, onError: (e) {
      print('Erro conexão: $e');
      disconnect();
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

    _imageBuffer.clear();
    _receivingImage = false;
    _lastByteOfPrevChunk = null;
    _decodingInProgress = false;

    print('🔌 Desconectado manualmente');
  }

  void _subscribeToCharacteristics(String deviceId) {
    _photoSub?.cancel();
    _childSub?.cancel();

    _imageBuffer.clear();
    _receivingImage = false;
    _lastByteOfPrevChunk = null;
    _decodingInProgress = false;
    _receptionStartTime = null; // DEBUG: Reseta o timer

    _photoSub = flutterReactiveBle
        .subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: photoCharUuid,
    ))
        .listen((chunk) async {
      
      print('📦 Chunk recebido: ${chunk.length} bytes');
      int i = 0;

      // Verifica início entre chunks
      if (!_receivingImage &&
          _lastByteOfPrevChunk == 0xFF &&
          chunk.isNotEmpty &&
          chunk[0] == 0xD8) {
        print('🟢 Início JPEG detectado entre chunks');
        // DEBUG: Marca o início da recepção
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
            // DEBUG: Marca o início da recepção
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
          // _receivingImage == true
          _imageBuffer.add(chunk[i]);

          if (i < chunk.length - 1 &&
              chunk[i] == 0xFF &&
              chunk[i + 1] == 0xD8) {
            print('⚠️ Novo início JPEG antes do fim do anterior. Reiniciando...');
            // DEBUG: Reseta o timer para a nova imagem
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
            
            // Marca o tempo exato em que o fim da imagem foi detectado
            final eoiDetectionTime = DateTime.now();

            // Calcula e imprime o tempo total de recepção
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

                // >>> NOVA MEDIÇÃO <<<
                // Calcula e imprime o tempo entre o fim da recepção e o fim da decodificação.
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
      //print('👶 Child detected: ${childDetected.value}');
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