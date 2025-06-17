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
    return Obx(() {
      if (photoController.photos.isEmpty) {
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

      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: photoController.photos.length,
        itemBuilder: (context, index) {
          final originalPhoto = photoController.photos[index];
          final thumbnailPath = photoController.getThumbnailPath(originalPhoto);
          
          return GestureDetector(
            onTap: () {
              if (photoController.isSelectionMode.value) {
                photoController.togglePhotoSelection(originalPhoto);
              } else {
                OpenFile.open(originalPhoto.path);
              }
            },
            onLongPress: () {
              if (!photoController.isSelectionMode.value) {
                photoController.toggleSelectionMode();
              }
              photoController.togglePhotoSelection(originalPhoto);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Obx(() {
                final isThumbReady = photoController.readyThumbnails.contains(thumbnailPath);
                final isSelected = photoController.selectedPhotos.contains(originalPhoto);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Exibe a miniatura se estiver pronta, senão um placeholder
                    if (isThumbReady)
                      Image.file(File(thumbnailPath), fit: BoxFit.cover, gaplessPlayback: true)
                    else
                      Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                      ),
                    // Overlay de seleção
                    if (isSelected)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                      ),
                  ],
                );
              }),
            ),
          );
        },
      );
    });
  }
}