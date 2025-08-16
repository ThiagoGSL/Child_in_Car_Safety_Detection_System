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
    bleController.startLiveStream();
  }

  @override
  void dispose() {
    bleController.stopLiveStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Novas cores
    const Color primaryColor = Color(0xFF53A194);
    const Color textColor = Color(0xFF524F42);
    const Color cameraFrameColor = Color(0xFFF0EAE1);

    return Center(
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
                    'Posicione a Câmera',
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
              'Encontre o melhor ângulo para o seu bebê. Quando estiver pronto, avance.',
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: cameraFrameColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: Obx(() {
                  final imageData = bleController.receivedImage.value;
                  if (imageData != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.memory(
                        imageData,
                        gaplessPlayback: true,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Aguardando imagem...',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
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
