import 'dart:async';
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
  final Color accentColor = const Color(0xFF53BF9D);
  final Color tileColor = const Color(0xFF16213E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicia a busca contínua ao entrar na página
      if (!controller.isScanning.value) {
        // Correção: Garante que a busca seja manual, sem conexão automática.
        controller.startManualScan();
      }
    });
  }

  @override
  void dispose() {
    // Garante que a busca pare ao sair da página
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
              const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Conecte o Dispositivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Ligue o seu dispositivo e conecte via Bluetooth.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: Obx(() {
                  final connectedDevice = controller.connectedDevice.value;
                  final foundDevices = controller.foundDevices.toList();

                  final List<DiscoveredDevice> sortedList = [];

                  if (connectedDevice != null) {
                    sortedList.add(connectedDevice);
                    foundDevices.removeWhere((d) => d.id == connectedDevice.id);
                  }
                  sortedList.addAll(foundDevices);

                  // MODIFICAÇÃO: Removido o indicador de progresso central
                  if (sortedList.isEmpty && !controller.isScanning.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Nenhum dispositivo encontrado.',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final device = sortedList[index];
                      final isConnected = device.id == connectedDevice?.id;
                      return _buildDeviceTile(device, isConnected);
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              Center(
                child: Obx(
                  () {
                    bool isScanning = controller.isScanning.value;
                    return OutlinedButton.icon(
                      onPressed: () {
                        if (isScanning) {
                          controller.stopScan();
                        } else {
                          controller.startManualScan();
                        }
                      },
                      icon: isScanning
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            )
                          : Icon(
                              Icons.search,
                              size: 20,
                              color: accentColor,
                            ),
                      label: Text(
                        isScanning ? 'Buscando...' : 'Procurar Dispositivo',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: accentColor.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(DiscoveredDevice device, bool connected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border:
                connected ? Border.all(color: accentColor, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(
                connected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: connected ? accentColor : Colors.white54,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  device.name.isNotEmpty
                      ? device.name
                      : '(Dispositivo sem nome)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        connected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (connected)
                const SizedBox.shrink()
              else
                ElevatedButton(
                  onPressed: controller.isConnecting.value
                      ? null
                      : () {
                          controller.connectToDevice(device);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accentColor.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: Obx(() => controller.isConnecting.value &&
                          controller.connectedDevice.value?.id == device.id
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Conectar')),
                ),
            ],
          ),
        ),
        if (connected)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: accentColor, size: 14),
                const SizedBox(width: 6),
                const Text(
                  "Conexão estabelecida.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          )
      ],
    );
  }
}
