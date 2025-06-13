import 'dart:typed_data';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class BlePage extends StatelessWidget {
  BlePage({Key? key}) : super(key: key);

  final BluetoothController controller = Get.find<BluetoothController>();

  void _showSnackbar(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.blueGrey,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold foi removido. Este widget é o "conteúdo" a ser exibido.
    return Container(
      color: Colors.blue.shade200,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Dispositivo conectado fixo no topo
            Obx(() {
              if (!controller.isConnected.value) return const SizedBox.shrink();
              final connectedDevice = controller.foundDevices.firstWhereOrNull(
                  (d) => d.name == controller.connectedDeviceName.value);
              if (connectedDevice == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Dispositivo Conectado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                  _buildDeviceTile(connectedDevice, true),
                ],
              );
            }),
            const SizedBox(height: 10),

            // Lista rolável de dispositivos disponíveis
            Expanded(
              child: Obx(() {
                final otherDevices = controller.foundDevices.where((d) =>
                    !controller.isConnected.value || d.name != controller.connectedDeviceName.value).toList();
                if (otherDevices.isEmpty && !controller.isScanning.value) {
                  return const Center(child: Text('Nenhum dispositivo encontrado', style: TextStyle(color: Colors.white70)));
                }
                if (controller.isScanning.value && otherDevices.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: otherDevices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Text('Dispositivos Disponíveis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                      );
                    }
                    final device = otherDevices[index - 1];
                    return _buildDeviceTile(device, false);
                  },
                );
              }),
            ),
            const SizedBox(height: 10),

            // Botão procurar dispositivos
            Obx(() {
              return ElevatedButton.icon(
                onPressed: controller.isScanning.value || controller.isConnecting.value ? null : () {
                  controller.startScan();
                  _showSnackbar(context, 'Iniciando busca por dispositivos...');
                },
                icon: const Icon(Icons.search, color: Colors.blueGrey),
                label: const Text('Procurar Dispositivos', style: TextStyle(color: Colors.blueGrey)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white70),
              );
            }),
            const SizedBox(height: 10),

            // Imagem recebida
            Obx(() {
              final Uint8List? imageData = controller.receivedImage.value;
              if (imageData == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    const Text('Imagem Recebida', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.white70), borderRadius: BorderRadius.circular(8)),
                      child: Image.memory(imageData),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Lógica original do _buildDeviceTile mantida
  Widget _buildDeviceTile(DiscoveredDevice device, bool connected) {
    final controller = Get.find<BluetoothController>();
    return Card(
      color: connected ? Colors.green.shade300 : Colors.white,
      child: ListTile(
        leading: Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth, color: connected ? Colors.white : Colors.black),
        title: Text(device.name.isNotEmpty ? device.name : '(sem nome)', style: TextStyle(color: connected ? Colors.white : Colors.black, fontWeight: connected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text('RSSI: ${device.rssi}', style: TextStyle(color: connected ? Colors.white70 : Colors.black54)),
        trailing: Obx(() {
          if (connected) {
            return ElevatedButton(
              onPressed: controller.isConnecting.value ? null : () {
                controller.disconnect();
                _showSnackbar(Get.context!, 'Desconectado com sucesso', color: Colors.green.shade700);
              },
              child: const Text('Desconectar'),
            );
          } else {
            return ElevatedButton(
              onPressed: controller.isConnecting.value || controller.isConnected.value ? null : () {
                controller.connectToDevice(device);
                _showSnackbar(Get.context!, 'Conectando ao dispositivo ${device.name}...');
              },
              child: controller.isConnecting.value ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Conectar'),
            );
          }
        }),
      ),
    );
  }
}