import 'dart:io';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoPage extends StatelessWidget {
  final PhotoController photoController = Get.find<PhotoController>();

  PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obx reage às mudanças na variável 'lastPhoto' do controller.
    return Obx(() {
      final photoFile = photoController.lastPhoto.value;

      // Se não houver foto, exibe uma mensagem centralizada.
      if (photoFile == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhuma foto salva ainda.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        );
      }

      // Se houver uma foto, exibe a imagem e um botão para excluir.
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Última Foto Recebida',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                // InteractiveViewer permite dar zoom e mover a imagem.
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Image.file(
                    File(photoFile.path),
                    fit: BoxFit.contain,
                    // key é importante para forçar o Flutter a recarregar a imagem quando o arquivo muda
                    key: ValueKey(photoFile.path), 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Adiciona um diálogo de confirmação antes de excluir.
                Get.dialog(
                  AlertDialog(
                    title: const Text('Excluir Foto'),
                    content: const Text('Tem certeza que deseja excluir esta foto?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(), // Fecha o diálogo
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          photoController.deleteLastPhoto();
                          Get.back(); // Fecha o diálogo
                        },
                        child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }
}