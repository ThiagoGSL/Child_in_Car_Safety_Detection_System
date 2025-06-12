import 'dart:io';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

class PhotoPage extends StatelessWidget {
  final PhotoController photoController = Get.find<PhotoController>();

  PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos Salvas')),
      body: Obx(() {
        if (photoController.photos.isEmpty) {
          return const Center(child: Text('Nenhuma foto salva'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photoController.photos.length,
          itemBuilder: (context, index) {
            final photo = photoController.photos[index];
            return GestureDetector(
              onTap: () async {
                await OpenFile.open(photo.path);
              },
              onLongPress: () {
                _confirmDelete(context, photo);
              },
              child: Image.file(photo, fit: BoxFit.cover),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, File photo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir foto?'),
        content: const Text('Tem certeza que deseja excluir esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              photoController.deletePhoto(photo);
              Get.back();
              Get.snackbar('Sucesso', 'Foto excluída');
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
