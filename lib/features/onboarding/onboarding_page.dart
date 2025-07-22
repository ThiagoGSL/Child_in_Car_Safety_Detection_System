import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/onboarding/onboarding_ble_page.dart';
import 'package:app_v0/features/onboarding/onboarding_camera_page.dart';
import 'package:app_v0/features/onboarding/onboarding_controller.dart';
import 'package:app_v0/features/onboarding/onboarding_finishing_page.dart';
import 'package:app_v0/features/onboarding/onboarding_form_page.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = Get.put(OnboardingController());
    final BluetoothController bleController = Get.find<BluetoothController>();
    const Color accentColor = Color(0xFF53BF9D);
    const Color backgroundColor = Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.pageController,
                onPageChanged: (index) {
                  controller.currentPageIndex.value = index;
                },
                children: [
                  const _OnboardingWelcomeStep(),
                  _OnboardingPermissionsStep(),
                  const OnboardingBlePage(),
                  const OnboardingCameraPage(),
                  OnboardingFormPage(formKey: controller.formKey),
                  const OnboardingFinishingPage(),
                ],
              ),
            ),
            Obx(() {
              if (controller.currentPageIndex.value == 5) {
                return const SizedBox.shrink(); 
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Obx(() => Visibility(
                          visible: controller.currentPageIndex.value > 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: TextButton(
                            onPressed: controller.previousPage,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 12),
                            ),
                            child: const Text(
                              'Voltar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                    const Spacer(),
                    Obx(() => DotsIndicator(
                          dotsCount: 6,
                          position: controller.currentPageIndex.value.toDouble(),
                          decorator: DotsDecorator(
                            color: Colors.white24,
                            activeColor: accentColor,
                            size: const Size.square(9.0),
                            activeSize: const Size(18.0, 9.0),
                            activeShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                          ),
                        )),
                    const SizedBox(width: 12),
                    Obx(() {
                      bool isButtonEnabled = false;
                      switch (controller.currentPageIndex.value) {
                        case 0:
                          isButtonEnabled = true;
                          break;
                        case 1:
                          // MODIFICAÇÃO: Agora exige as três permissões.
                          isButtonEnabled = controller.bluetoothPermissionGranted.value &&
                                            controller.notificationsPermissionGranted.value &&
                                            controller.locationPermissionGranted.value &&
                                            controller.smsPermissionGranted.value;
                          break;
                        case 2:
                          isButtonEnabled = bleController.isConnected.value;
                          break;
                        case 3:
                          isButtonEnabled = true;
                          break;
                        case 4:
                          isButtonEnabled = controller.isFormValid.value;
                          break;
                        case 5: 
                          isButtonEnabled = true;
                      }

                      return ElevatedButton(
                        onPressed: isButtonEnabled ? controller.validateAndProceed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                        child: Text(
                          controller.currentPageIndex.value == 4
                              ? 'Concluir'
                              : 'Próximo',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    })
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OnboardingWelcomeStep extends StatelessWidget {
  const _OnboardingWelcomeStep();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.crib_outlined,
            size: 100,
            color: Color(0xFF53BF9D),
          ),
          SizedBox(height: 30),
          Text(
            'Bem-vindo(a) ao SafeBaby!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Seu assistente inteligente para o monitoramento e segurança do seu bebê.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPermissionsStep extends StatelessWidget {
  final OnboardingController controller = Get.find();

  _OnboardingPermissionsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permissões Necessárias',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Para funcionar corretamente, o SafeBaby precisa de algumas permissões.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => _PermissionRequestTile(
                icon: Icons.bluetooth,
                title: 'Bluetooth',
                subtitle: 'Para conectar ao dispositivo de monitoramento.',
                isGranted: controller.bluetoothPermissionGranted.value,
                onPressed: controller.requestBluetoothPermission,
              )),
          const SizedBox(height: 20),
          Obx(() => _PermissionRequestTile(
                icon: Icons.notifications,
                title: 'Notificações',
                subtitle: 'Para enviar alertas importantes sobre seu bebê.',
                isGranted: controller.notificationsPermissionGranted.value,
                onPressed: controller.requestNotificationsPermission,
              )),
          const SizedBox(height: 20),
          // MODIFICAÇÃO: Tile para a permissão de localização.
          Obx(() => _PermissionRequestTile(
                icon: Icons.location_on_outlined,
                title: 'Localização',
                subtitle: 'Para registrar onde os eventos ocorrem.',
                isGranted: controller.locationPermissionGranted.value,
                onPressed: controller.requestLocationPermission,
              )),
          const SizedBox(height: 12),
          Obx(() => _PermissionRequestTile(
            icon: Icons.sms,
            title: 'SMS',
            subtitle: 'Para enviar alertas de emergência para seu contato.',
            isGranted: controller.smsPermissionGranted.value,
            onPressed: controller.requestSmsPermission, 
          )),
        ],
      ),
    );
  }
}

class _PermissionRequestTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback onPressed;

  const _PermissionRequestTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      leading: Icon(icon, color: const Color(0xFF53BF9D), size: 30),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: TextButton(
        onPressed: isGranted ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
              isGranted ? Colors.green.withOpacity(0.2) : Colors.white10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isGranted ? 'Permitido' : 'Permitir',
          style: TextStyle(
              color: isGranted ? const Color(0xFF53BF9D) : Colors.white),
        ),
      ),
    );
  }
}
