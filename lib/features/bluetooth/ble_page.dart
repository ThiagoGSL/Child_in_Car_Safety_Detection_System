import 'dart:typed_data';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlePage extends StatelessWidget {
  BlePage({Key? key}) : super(key: key);

  final BluetoothController controller = Get.put(BluetoothController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade200,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Status de conexão
            Obx(() {
              return Icon(
                controller.isConnected.value
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                size: 60,
                color:
                    controller.isConnected.value ? Colors.green : Colors.red,
              );
            }),
            const SizedBox(height: 10),
            // Texto de status
            Obx(() {
              final text = controller.isConnected.value
                  ? 'Conectado: ${controller.connectedDeviceName.value}'
                  : controller.isScanning.value
                      ? 'Procurando dispositivos...'
                      : 'ESP32-CAM desconectado';
              return Text(
                text,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              );
            }),
            const SizedBox(height: 20),
            // Botão de scan
            ElevatedButton.icon(
              onPressed: controller.isScanning.value
                  ? null
                  : controller.startScan,
              icon: const Icon(Icons.search, color: Colors.blueGrey),
              label: const Text(
                'Procurar Dispositivos',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
            const SizedBox(height: 20),
            // Lista de dispositivos
            Expanded(
              child: Obx(() {
                if (controller.foundDevices.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum dispositivo encontrado.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: controller.foundDevices.length,
                  itemBuilder: (ctx, i) {
                    final dev = controller.foundDevices[i];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      child: ListTile(
                        title:
                            Text(dev.name.isNotEmpty ? dev.name : 'Sem nome'),
                        subtitle: Text(dev.id),
                        trailing: ElevatedButton(
                          onPressed: controller.isConnected.value
                              ? null
                              : () => controller.connectToDevice(dev),
                          child: const Text('Conectar'),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const Divider(color: Colors.white70),
            // Exibição da imagem recebida
            Obx(() {
              final Uint8List? img = controller.receivedImage.value;
              if (img == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aguardando foto...',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Image.memory(
                    img,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (ctx, error, stack) {
                      return const Center(
                        child: Text(
                          'Erro ao decodificar imagem',
                          style: TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            // Exibição do boolean childDetected
            Obx(() {
              return Text(
                'Criança detectada: ${controller.childDetected.value}',
                style: const TextStyle(color: Colors.white),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
