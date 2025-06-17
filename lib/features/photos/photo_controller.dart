import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Função que roda em background (Isolate) para criar a miniatura sem travar a UI.
Future<bool> _generateAndSaveThumbnail(Map<String, String> paths) async {
  final String originalPath = paths['originalPath']!;
  final String thumbPath = paths['thumbPath']!;
  try {
    final originalFile = File(originalPath);
    if (!await originalFile.exists()) return false;
    final imageBytes = await originalFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) return false;
    final thumbnail = img.copyResize(image, width: 250, height: 250);
    final thumbFile = File(thumbPath);
    await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
    print('✅ Miniatura criada para: $thumbPath');
    return true;
  } catch (e) {
    print('❌ Erro ao gerar miniatura: $e');
    return false;
  }
}

class PhotoController extends GetxController {
  var photos = <File>[].obs;
  var isSelectionMode = false.obs;
  var selectedPhotos = <File>[].obs;
  var readyThumbnails = <String>{}.obs; // Set reativo para miniaturas prontas

  late final Directory _thumbDir;

  @override
  void onInit() {
    super.onInit();
    _initThumbnailsDirectory().then((_) => loadSavedPhotos());
  }

  Future<void> _initThumbnailsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _thumbDir = Directory(p.join(appDir.path, 'thumbnails'));
    if (!await _thumbDir.exists()) {
      await _thumbDir.create(recursive: true);
    }
  }

  String getThumbnailPath(File originalPhoto) {
    final fileName = p.basename(originalPhoto.path);
    return p.join(_thumbDir.path, fileName);
  }

  Future<void> loadSavedPhotos() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final List<File> loadedPhotos = [];
      final Set<String> newReadyThumbnails = {};
      final filesStream = dir.list();

      await for (final FileSystemEntity entity in filesStream) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
            loadedPhotos.add(entity);
            final thumbFile = File(getThumbnailPath(entity));
            if (await thumbFile.exists()) {
              newReadyThumbnails.add(thumbFile.path);
            } else {
              compute(_generateAndSaveThumbnail, {'originalPath': entity.path, 'thumbPath': thumbFile.path})
                  .then((success) {
                if (success) {
                  readyThumbnails.add(thumbFile.path);
                }
              });
            }
          }
        }
      }

      loadedPhotos.sort((a, b) => b.path.compareTo(a.path));
      photos.value = loadedPhotos;
      readyThumbnails.value = newReadyThumbnails;
    } catch (e) {
      print('Erro ao carregar fotos: $e');
    }
  }

  Future<String> saveImage(Uint8List imageBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${dir.path}/photo_$timestamp.jpg';
    final file = File(path);
    await file.writeAsBytes(imageBytes);

    photos.insert(0, file);

    final thumbPath = getThumbnailPath(file);
    compute(_generateAndSaveThumbnail, {'originalPath': path, 'thumbPath': thumbPath})
        .then((success) {
      if (success) {
        readyThumbnails.add(thumbPath);
      }
    });
    print('📸 Foto salva em: $path');
    return path;
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedPhotos.clear();
    }
  }

  void togglePhotoSelection(File photo) {
    if (selectedPhotos.contains(photo)) {
      selectedPhotos.remove(photo);
    } else {
      selectedPhotos.add(photo);
    }
  }

  Future<void> deleteSelectedPhotos() async {
    final photosToDelete = List<File>.from(selectedPhotos);
    int deletedCount = 0;
    for (var photo in photosToDelete) {
      try {
        if (await photo.exists()) {
          final thumbFile = File(getThumbnailPath(photo));
          if (await thumbFile.exists()) {
            await thumbFile.delete();
            readyThumbnails.remove(thumbFile.path);
          }
          await photo.delete();
          photos.remove(photo);
          deletedCount++;
        }
      } catch (e) {
        debugPrint('Erro ao deletar a foto ${photo.path}: $e');
      }
    }
    isSelectionMode.value = false;
    selectedPhotos.clear();
    if (deletedCount > 0) {
      Get.snackbar('Sucesso', '$deletedCount foto(s) excluída(s).');
    }
  }
}