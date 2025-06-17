import 'package:app_v0/features/cadastro/form_page.dart';
import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtém a instância do MainPageController para controlar a navegação
    final mainController = Get.find<MainPageController>();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        _buildConfigTile(
          icon: Icons.bluetooth,
          title: 'Conexão Bluetooth',
          subtitle: 'Gerenciar conexão com o dispositivo',
          onTap: () {
            // Chama o método no controller para mostrar a BlePage
            mainController.navigateToBlePage(true);
          },
        ),
        _buildConfigTile(
          icon: Icons.person_add_alt_1,
          title: 'Cadastro de Usuário',
          subtitle: 'Editar suas informações de perfil',
          onTap: () {
            // Navega para a FormPage como uma nova tela, pois é um fluxo diferente
            Get.to(() => FormPage());
          },
        ),
        _buildConfigTile(
          icon: Icons.photo_library,
          title: 'Fotos Salvas',
          subtitle: 'Visualizar a última foto recebida',
          onTap: () {
            // Chama o método no controller para mostrar a PhotoPage
            mainController.navigateToPhotoPage(true);
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

  // Widget auxiliar para construir os itens da lista de forma consistente
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