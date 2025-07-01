import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/notification_ext/notification_controller_ext.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SensorPage extends StatelessWidget {
  const SensorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Encontra as instâncias dos controllers.
    final FormController formController = Get.find();
    final NotificationExtController notificationController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Controle de Alertas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => Text(
              'Contato de Emergência Configurado:\n${formController.emergencyPhone.value.isEmpty ? "Nenhum" : formController.emergencyPhone.value}',
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            )),

            const Spacer(),

            // Botão principal que dispara o fluxo completo.
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Agora é o botão de alerta principal
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              onPressed: () {
                // Chama o método orquestrador no controller.
                notificationController.triggerFullEmergencyAlert();

                // Opcional: Mostra um feedback imediato ao usuário.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comando de Alerta de Emergência enviado!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Disparar Alerta de Emergência'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}