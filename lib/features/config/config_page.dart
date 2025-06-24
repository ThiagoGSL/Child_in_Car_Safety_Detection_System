import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<MainPageController>();

    // MODIFICADO: Adicionado padding à ListView
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildConfigTile(
          icon: Icons.bluetooth_searching,
          title: 'Conexão Bluetooth',
          subtitle: 'Gerenciar conexão com o dispositivo',
          onTap: () {
            mainController.navigateToBlePage(true);
          },
        ),
        _buildConfigTile(
          icon: Icons.person_outline,
          title: 'Cadastro de Usuário',
          subtitle: 'Editar suas informações de perfil',
          onTap: () {
            mainController.navigateToFormPage(true);
          },
        ),
        _buildConfigTile(
          icon: Icons.photo_library_outlined,
          title: 'Galeria',
          subtitle: 'Visualizar última foto recebida',
          onTap: () {
            mainController.navigateToPhotoPage(true);
          },
        ),
         _buildConfigTile(
          icon: Icons.info_outline,
          title: 'Sobre o App',
          subtitle: 'Versão 1.0.0',
          onTap: () {
             // MODIFICADO: SnackBar estilizada para o tema escuro
             Get.snackbar(
              'Sobre o App', 
              'SafeBaby Monitor v1.0.0',
              snackPosition: SnackPosition.TOP,
              backgroundColor: const Color(0xFF16213E), // Fundo escuro
              colorText: Colors.white, // Texto branco
              icon: const Icon(Icons.info_outline, color: Color(0xFF53BF9D)), // Ícone com cor de destaque
              margin: const EdgeInsets.all(12),
              borderRadius: 12,
              );
          },
        ),
      ],
    );
  }

  // MODIFICADO: Widget de tile completamente reestilizado para o tema escuro
  Widget _buildConfigTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Paleta de cores do tema
    final Color accentColor = const Color(0xFF53BF9D);
    final Color tileBackgroundColor = const Color(0xFF16213E);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(icon, color: accentColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}