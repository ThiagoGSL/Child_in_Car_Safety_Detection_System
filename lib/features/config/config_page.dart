import 'package:app_v0/features/main_page/main_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<MainPageController>();

    // Novas cores da identidade visual
    final Color primaryColor = const Color(0xFF53A194);
    final Color secondaryColor = const Color(0xFFE5E0D2);
    final Color textColor = const Color(0xFF524F42);
    final Color tileBackgroundColor = const Color(0xFF524F42).withOpacity(0.1);

    return Scaffold(
      backgroundColor: secondaryColor,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildConfigTile(
            icon: Icons.bluetooth_searching,
            title: 'Conexão Bluetooth',
            subtitle: 'Gerenciar conexão com o dispositivo',
            onTap: () {
              mainController.navigateToBlePage(true);
            },
            primaryColor: primaryColor,
            textColor: textColor,
            tileBackgroundColor: tileBackgroundColor,
          ),
          _buildConfigTile(
            icon: Icons.person_outline,
            title: 'Cadastro de Usuário',
            subtitle: 'Editar suas informações de perfil',
            onTap: () {
              mainController.navigateToFormPage(true);
            },
            primaryColor: primaryColor,
            textColor: textColor,
            tileBackgroundColor: tileBackgroundColor,
          ),
          _buildConfigTile(
            icon: Icons.photo_library_outlined,
            title: 'Galeria',
            subtitle: 'Visualizar última foto recebida',
            onTap: () {
              mainController.navigateToPhotoPage(true);
            },
            primaryColor: primaryColor,
            textColor: textColor,
            tileBackgroundColor: tileBackgroundColor,
          ),
          _buildConfigTile(
            icon: Icons.info_outline,
            title: 'Sobre o App',
            subtitle: 'Versão 1.0.0',
            onTap: () {
              Get.snackbar(
                'Sobre o App',
                'SafeBaby Monitor v1.0.0',
                snackPosition: SnackPosition.TOP,
                backgroundColor: primaryColor,
                colorText: secondaryColor,
                icon: Icon(Icons.info_outline, color: secondaryColor),
                margin: const EdgeInsets.all(12),
                borderRadius: 12,
                duration: const Duration(seconds: 2),
              );
            },
            primaryColor: primaryColor,
            textColor: textColor,
            tileBackgroundColor: tileBackgroundColor,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color textColor,
    required Color tileBackgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(icon, color: primaryColor, size: 30),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textColor.withOpacity(0.3),
        ),
        onTap: onTap,
      ),
    );
  }
}
