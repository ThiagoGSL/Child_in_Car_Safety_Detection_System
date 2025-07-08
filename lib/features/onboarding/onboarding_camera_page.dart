import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingCameraPage extends StatefulWidget {
  const OnboardingCameraPage({super.key});

  @override
  State<OnboardingCameraPage> createState() => _OnboardingCameraPageState();
}

class _OnboardingCameraPageState extends State<OnboardingCameraPage> {
  final BluetoothController bleController = Get.find<BluetoothController>();

  @override
  void initState() {
    super.initState();
    // Inicia a transmissão ao vivo quando a página é aberta
    bleController.startLiveStream();
  }

  @override
  void dispose() {
    // Para a transmissão ao vivo quando a página é fechada
    bleController.stopLiveStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF53BF9D);

    return Center(
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
                    'Posicione a Câmera',
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
              'Encontre o melhor ângulo para o seu bebê. Quando estiver pronto, avance.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Obx(() {
                  final imageData = bleController.receivedImage.value;
                  if (imageData != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.memory(
                        imageData,
                        gaplessPlayback: true, // Evita piscar entre as imagens
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: accentColor),
                          SizedBox(height: 16),
                          Text(
                            'Aguardando imagem...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
