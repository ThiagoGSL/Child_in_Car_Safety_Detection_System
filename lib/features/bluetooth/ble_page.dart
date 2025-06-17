import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class BlePage extends StatefulWidget {
  const BlePage({Key? key}) : super(key: key);

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final BluetoothController controller = Get.find<BluetoothController>();

  @override
  void initState() {
    super.initState();
    
    // Inicia a busca por dispositivos disponíveis assim que a página é aberta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isScanning.value) {
         controller.startManualScan();
      }
    });
  }

  void _showSnackbar(BuildContext context, String message, {Color? color}) {
    // Garante que o contexto é válido antes de mostrar a SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.blueGrey,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade200,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Dispositivo conectado 
            Obx(() {
              final device = controller.connectedDevice.value;
              if (device == null) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Dispositivo Conectado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                  _buildDeviceTile(device, true),
                ],
              );
            }),
            const SizedBox(height: 10),

            // Lista rolável de dispositivos disponíveis 
            Expanded(
              child: Obx(() {
                final otherDevices = controller.foundDevices.where((d) => 
                    d.id != controller.connectedDevice.value?.id).toList();

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

            Obx(() {
              return ElevatedButton.icon(
                onPressed: controller.isScanning.value || controller.isConnecting.value ? null : () {
                  controller.startManualScan();
                  _showSnackbar(context, 'Buscando novamente...');
                },
                icon: const Icon(Icons.search, color: Colors.blueGrey),
                label: const Text('Procurar Dispositivos', style: TextStyle(color: Colors.blueGrey)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white70),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(DiscoveredDevice device, bool connected) {
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
              child: controller.isConnecting.value && controller.connectedDeviceName.value == device.name
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) 
                  : const Text('Conectar'),
            );
          }
        }),
      ),
    );
  }
}