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
    const Color primaryColor = Color(0xFF53A194);
    const Color secondaryColor = Color(0xFFE5E0D2);

    return Scaffold(
      backgroundColor: secondaryColor,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Obx(
                      () => Visibility(
                        visible: controller.currentPageIndex.value > 0,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: TextButton(
                          onPressed: controller.previousPage,
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Voltar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => DotsIndicator(
                        dotsCount: 6,
                        position: controller.currentPageIndex.value.toDouble(),
                        decorator: DotsDecorator(
                          color: primaryColor.withOpacity(0.3),
                          activeColor: primaryColor,
                          size: const Size.square(9.0),
                          activeSize: const Size(18.0, 9.0),
                          activeShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(() {
                      bool isButtonEnabled = false;
                      switch (controller.currentPageIndex.value) {
                        case 0:
                          isButtonEnabled = true;
                          break;
                        case 1:
                          isButtonEnabled =
                              controller.bluetoothPermissionGranted.value &&
                              controller.notificationsPermissionGranted.value &&
                              controller.locationPermissionGranted.value &&
                              controller.smsPermissionGranted.value;
                          break;
                        case 2:
                          // isButtonEnabled = bleController.isConnected.value;
                          isButtonEnabled = true;
                          break;
                        case 3:
                          isButtonEnabled = true;
                          break;
                        case 4:
                          isButtonEnabled = controller.isFormValid.value;
                          break;
                        case 5:
                          isButtonEnabled = true;
                          break;
                      }

                      return ElevatedButton(
                        onPressed:
                            isButtonEnabled
                                ? controller.validateAndProceed
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: secondaryColor,
                          disabledBackgroundColor: primaryColor.withOpacity(
                            0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          controller.currentPageIndex.value == 4
                              ? 'Concluir'
                              : 'Próximo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
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
    const Color textColor = Color(0xFF524F42);
    const Color primaryColor = Color(0xFF53A194);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('lib/assets/logoBranca.png', height: 150),
          const SizedBox(height: 0),
          const Text(
            'Bem-vindo(a) ao SafeBaby!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Seu assistente inteligente para o monitoramento e segurança do seu bebê.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontSize: 16),
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
    const Color textColor = Color(0xFF524F42);
    const Color primaryColor = Color(0xFF53A194);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permissões Necessárias',
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Obx(
            () => _PermissionRequestTile(
              icon: Icons.bluetooth,
              title: 'Bluetooth',
              subtitle: 'Para conectar ao dispositivo de monitoramento.',
              isGranted: controller.bluetoothPermissionGranted.value,
              onPressed: controller.requestBluetoothPermission,
              primaryColor: primaryColor,
              textColor: textColor,
            ),
          ),
          Obx(
            () => _PermissionRequestTile(
              icon: Icons.notifications,
              title: 'Notificações',
              subtitle: 'Para enviar alertas importantes sobre seu bebê.',
              isGranted: controller.notificationsPermissionGranted.value,
              onPressed: controller.requestNotificationsPermission,
              primaryColor: primaryColor,
              textColor: textColor,
            ),
          ),
          Obx(
            () => _PermissionRequestTile(
              icon: Icons.location_on_outlined,
              title: 'Localização',
              subtitle: 'Para registrar onde os eventos ocorrem.',
              isGranted: controller.locationPermissionGranted.value,
              onPressed: controller.requestLocationPermission,
              primaryColor: primaryColor,
              textColor: textColor,
            ),
          ),
          Obx(
            () => _PermissionRequestTile(
              icon: Icons.sms,
              title: 'SMS',
              subtitle: 'Para enviar alertas de emergência para seu contato.',
              isGranted: controller.smsPermissionGranted.value,
              onPressed: controller.requestSmsPermission,
              primaryColor: primaryColor,
              textColor: textColor,
            ),
          ),
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
  final Color primaryColor;
  final Color textColor;

  const _PermissionRequestTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onPressed,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Icon(icon, color: primaryColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
      ),
      trailing: TextButton(
        onPressed: isGranted ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
              isGranted
                  ? primaryColor.withOpacity(0.2)
                  : primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Text(
          isGranted ? 'Permitido' : 'Permitir',
          style: TextStyle(
            color: isGranted ? primaryColor : primaryColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
