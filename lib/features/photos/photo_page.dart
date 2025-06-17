import 'dart:io';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoPage extends StatelessWidget {
  final PhotoController photoController = Get.find<PhotoController>();

  PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Cor de destaque do tema
    final Color accentColor = const Color(0xFF53BF9D);
    // Cor de fundo dos cards/dialogs
    final Color tileColor = const Color(0xFF16213E);

    return Obx(() {
      final photoFile = photoController.lastPhoto.value;

      // MODIFICADO: Estilo da tela de "nenhuma foto" para o tema escuro
      if (photoFile == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 60, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                'Nenhuma foto salva ainda.',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MODIFICADO: Estilo do título
            const Text(
              'Última Foto Recebida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Expanded(
              // NOVO: Container para criar uma moldura sutil para a foto
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: InteractiveViewer(
                    maxScale: 5.0,
                    child: Image.file(
                      File(photoFile.path),
                      fit: BoxFit.contain,
                      key: ValueKey(photoFile.path),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // MODIFICADO: Botão de exclusão reestilizado
            OutlinedButton.icon(
              onPressed: () {
                Get.dialog(
                  // MODIFICADO: AlertDialog estilizado para o tema escuro
                  AlertDialog(
                    backgroundColor: tileColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('Excluir Foto', style: TextStyle(color: Colors.white)),
                    content: const Text('Tem certeza que deseja excluir esta foto?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () {
                          photoController.deleteLastPhoto();
                          Get.back();
                        },
                        child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir Foto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      );
    });
  }
}