import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class OnboardingBlePage extends StatefulWidget {
  const OnboardingBlePage({super.key});

  @override
  State<OnboardingBlePage> createState() => _OnboardingBlePageState();
}

class _OnboardingBlePageState extends State<OnboardingBlePage> {
  final BluetoothController controller = Get.find<BluetoothController>();
  final Color primaryColor = const Color(0xFF53A194);
  final Color textColor = const Color(0xFF524F42);
  final Color secondaryColor = const Color(0xFFE5E0D2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isScanning.value) {
        controller.startManualScan();
      }
    });
  }

  @override
  void dispose() {
    controller.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Conecte o Dispositivo',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Ligue o seu dispositivo e conecte via Bluetooth.',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              // Use Expanded para que a lista ocupe o máximo de espaço possível
              // A rolagem da ListView.builder é gerenciada pelo SingleChildScrollView pai
              Obx(() {
                final connectedDevice = controller.connectedDevice.value;
                final foundDevices = controller.foundDevices.toList();

                final List<DiscoveredDevice> sortedList = [];

                if (connectedDevice != null) {
                  sortedList.add(connectedDevice);
                  foundDevices.removeWhere((d) => d.id == connectedDevice.id);
                }
                sortedList.addAll(foundDevices);

                if (sortedList.isEmpty && !controller.isScanning.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nenhum dispositivo encontrado.',
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap:
                      true, // Adicionado para a lista rolar dentro do SingleChildScrollView
                  physics:
                      const NeverScrollableScrollPhysics(), // Desabilita a rolagem interna da lista
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final device = sortedList[index];
                    final isConnected = device.id == connectedDevice?.id;
                    return _buildDeviceTile(device, isConnected);
                  },
                );
              }),
              const SizedBox(height: 20),
              Center(
                child: Obx(() {
                  bool isScanning = controller.isScanning.value;
                  return OutlinedButton.icon(
                    onPressed: () {
                      if (isScanning) {
                        controller.stopScan();
                      } else {
                        controller.startManualScan();
                      }
                    },
                    icon:
                        isScanning
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF53A194),
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF53A194),
                            ),
                    label: Text(
                      isScanning ? 'Buscando...' : 'Procurar Dispositivo',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(DiscoveredDevice device, bool connected) {
    const Color tileBgColor = Color(0xFFE5E0D2);
    const Color textColor = Color(0xFF524F42);
    final Color primaryColor = const Color(0xFF53A194);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tileBgColor,
            borderRadius: BorderRadius.circular(12),
            border:
                connected ? Border.all(color: primaryColor, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(
                connected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: connected ? primaryColor : textColor.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  device.name.isNotEmpty
                      ? device.name
                      : '(Dispositivo sem nome)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: connected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (connected)
                const SizedBox.shrink()
              else
                ElevatedButton(
                  onPressed:
                      controller.isConnecting.value
                          ? null
                          : () {
                            controller.connectToDevice(device);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFFE5E0D2),
                    disabledBackgroundColor: primaryColor.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Obx(
                    () =>
                        controller.isConnecting.value &&
                                controller.connectedDevice.value?.id ==
                                    device.id
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Conectar'),
                  ),
                ),
            ],
          ),
        ),
        if (connected)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: primaryColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Conexão estabelecida.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
