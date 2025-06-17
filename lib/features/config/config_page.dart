import 'package:app_v0/features/cadastro/form_page.dart'; // Importe a FormPage
import 'package:app_v0/features/photos/photo_page.dart';
import 'package:app_v0/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<MainPageController>();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        _buildConfigTile(
          icon: Icons.bluetooth,
          title: 'Conexão Bluetooth',
          subtitle: 'Gerenciar conexão com o dispositivo',
          onTap: () {
            // Apenas altera o estado para mostrar a página de BLE
            mainController.navigateToBlePage(true);
          },
        ),
        // >>> LÓGICA ALTERADA <<<
        _buildConfigTile(
          icon: Icons.person_add_alt_1,
          title: 'Cadastro de Usuário',
          subtitle: 'Editar suas informações de perfil',
          onTap: () {
            // Navega para a FormPage como uma nova tela
            Get.to(() => FormPage());
          },
        ),
        _buildConfigTile(
          icon: Icons.receipt_long,
          title: 'Logs do Sistema',
          subtitle: 'Visualizar logs de eventos e erros',
          onTap: () {
            Get.to(() => PhotoPage());
          },
        ),
         _buildConfigTile(
          icon: Icons.info_outline,
          title: 'Sobre o App',
          subtitle: 'Versão 1.0.0',
          onTap: () {
             Get.snackbar('Sobre', 'Aplicativo desenvolvido para o projeto ForgottenBaby.');
          },
        ),
      ],
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}