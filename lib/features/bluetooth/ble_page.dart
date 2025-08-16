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

  final Color primaryColor = const Color(0xFF53A194);
  final Color secondaryColor = const Color(0xFFE5E0D2);
  final Color textColor = const Color(0xFF524F42);
  final Color tileColor = const Color(0xFFF0EAE1);

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        backgroundColor: secondaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: secondaryColor,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Dispositivo Conectado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  _buildDeviceTile(device, true),
                ],
              );
            }),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                final otherDevices =
                    controller.foundDevices
                        .where(
                          (d) => d.id != controller.connectedDevice.value?.id,
                        )
                        .toList();

                if (otherDevices.isEmpty && !controller.isScanning.value) {
                  return Center(
                    child: Text(
                      'Nenhum dispositivo encontrado',
                      style: TextStyle(color: textColor.withOpacity(0.5)),
                    ),
                  );
                }
                if (controller.isScanning.value && otherDevices.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: otherDevices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Dispositivos Disponíveis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
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
                onPressed:
                    controller.isScanning.value || controller.isConnecting.value
                        ? null
                        : () {
                          controller.startManualScan();
                          _showSnackbar(context, 'Buscando dispositivos...');
                        },
                icon: Icon(Icons.search, color: secondaryColor),
                label: Text(
                  'Procurar Dispositivos',
                  style: TextStyle(
                    color: secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: connected ? Border.all(color: primaryColor, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: connected ? primaryColor : textColor.withOpacity(0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isNotEmpty
                      ? device.name
                      : '(Dispositivo sem nome)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: connected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            if (connected) {
              return ElevatedButton(
                onPressed:
                    controller.isConnecting.value
                        ? null
                        : controller.disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: secondaryColor,
                  disabledBackgroundColor: Colors.redAccent.withOpacity(0.25),
                  disabledForegroundColor: secondaryColor.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                ),
                child: const Text('Desconectar'),
              );
            } else {
              return ElevatedButton(
                onPressed:
                    controller.isConnecting.value ||
                            controller.isConnected.value
                        ? null
                        : () {
                          controller.connectToDevice(device);
                          _showSnackbar(
                            Get.context!,
                            'Conectando a ${device.name}...',
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: secondaryColor,
                  disabledBackgroundColor: primaryColor.withOpacity(0.25),
                  disabledForegroundColor: secondaryColor.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child:
                    controller.isConnecting.value &&
                            controller.connectedDeviceName.value == device.id
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              secondaryColor,
                            ),
                          ),
                        )
                        : const Text('Conectar'),
              );
            }
          }),
        ],
      ),
    );
  }
}
