import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class PhotoController extends GetxController {
  var photos = <File>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedPhotos();
  }

  Future<void> loadSavedPhotos() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    photos.value = files
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.png'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // Mais recentes primeiro
  }

  Future<String> saveImage(Uint8List imageBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/photo_$timestamp.jpg';
    final file = File(path);
    await file.writeAsBytes(imageBytes);
    photos.insert(0, file); // Adiciona no topo da lista
    print('📸 Foto salva em: $path');
    return path;
  }

  Future<void> deletePhoto(File photo) async {
    try {
      await photo.delete();
      photos.remove(photo);
    } catch (e) {
      debugPrint('Erro ao deletar foto: $e');
    }
  }
}
