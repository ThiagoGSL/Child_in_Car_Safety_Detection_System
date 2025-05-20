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
      // appBar: AppBar(
      //   title: Text('Bluetooth ESP32-CAM',),
      //   backgroundColor: Colors.blue.shade900,
      // ),
      body: Center(
        child: Obx(() {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Icon(
                controller.isConnected.value
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                size: 60,
                color: controller.isConnected.value ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                controller.isConnected.value
                    ? 'Conectado: ${controller.connectedDeviceName.value}'
                    : controller.isScanning.value
                        ? 'Procurando dispositivos...'
                        : 'ESP32-CAM desconectado',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Botão para iniciar scan
              ElevatedButton.icon(
                onPressed: controller.isScanning.value
                    ? null
                    : controller.startScan,
                icon: const Icon(Icons.search,
                color: Colors.blueGrey),
                label: const Text("Procurar Dispositivos",
                style: TextStyle(
                  color: Colors.blueGrey
                ),),
              ),

              // Lista dos dispositivos encontrados
              Expanded(
                child: Obx(() {
                  if (controller.foundDevices.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nenhum dispositivo encontrado.",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.foundDevices.length,
                    itemBuilder: (context, index) {
                      final device = controller.foundDevices[index];
                      return Card(
                        color: Colors.white.withOpacity(0.1),
                        child: ListTile(
                          title: Text(device.name.isNotEmpty
                              ? device.name
                              : 'Dispositivo Sem Nome'),
                          subtitle: Text(device.id),
                          trailing: ElevatedButton(
                            onPressed: controller.isConnected.value
                                ? null
                                : () => controller.connectToDevice(device),
                            child: const Text('Conectar'),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}
