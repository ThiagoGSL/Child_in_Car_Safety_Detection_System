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

  final Color accentColor = const Color(0xFF53BF9D);
  final Color tileColor = const Color(0xFF16213E);

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isScanning.value && !controller.isConnected.value) {
         controller.startManualScan();
      }
    });
  }

  void _showSnackbar(BuildContext context, String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: tileColor,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Obx(() {
              final device = controller.connectedDevice.value;
              if (device == null) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Dispositivo Conectado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  _buildDeviceTile(device, true),
                ],
              );
            }),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                final otherDevices = controller.foundDevices.where((d) => 
                    d.id != controller.connectedDevice.value?.id).toList();

                if (otherDevices.isEmpty && !controller.isScanning.value) {
                  return const Center(child: Text('Nenhum dispositivo encontrado', style: TextStyle(color: Colors.white70)));
                }
                if (controller.isScanning.value && otherDevices.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: accentColor));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: otherDevices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Dispositivos Disponíveis',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
                  _showSnackbar(context, 'Buscando dispositivos...');
                },
                icon: const Icon(Icons.search, color: Colors.white),
                // MODIFICAÇÃO 3: Texto do botão alterado
                label: const Text('Procurar Dispositivos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(DiscoveredDevice device, bool connected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: connected ? Border.all(color: accentColor, width: 1.5) : null,
      ),
      child: ListTile(
        leading: Icon(
          connected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: connected ? accentColor : Colors.white54,
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : '(Dispositivo sem nome)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: connected ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis, // Garante que o texto não quebre a linha
        ),
        subtitle: Text(
          'RSSI: ${device.rssi}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Obx(() {
          if (connected) {
            // MODIFICAÇÃO 1: Botão "Desconectar" com borda vermelha
            return OutlinedButton(
              onPressed: controller.isConnecting.value ? null : controller.disconnect,
              style: OutlinedButton.styleFrom(
                // MODIFICAÇÃO 2: Padding do botão diminuído
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Desconectar'),
            );
          } else {
            return ElevatedButton(
              onPressed: controller.isConnecting.value || controller.isConnected.value ? null : () {
                controller.connectToDevice(device);
                _showSnackbar(Get.context!, 'Conectando a ${device.name}...');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                // MODIFICAÇÃO 2: Padding do botão diminuído
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: controller.isConnecting.value && controller.connectedDeviceName.value == device.id
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    ) 
                  : const Text('Conectar'),
            );
          }
        }),
      ),
    );
  }
}