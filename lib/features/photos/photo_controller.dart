import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class PhotoController extends GetxController {
  var lastPhoto = Rx<File?>(null);

  final String _lastPhotoFileName = 'last_received_photo.jpg';

  @override
  void onInit() {
    super.onInit();
    // Ao iniciar, tenta carregar a última foto que pode ter sido salva anteriormente.
    loadLastPhoto();
  }

  /// Carrega a última foto salva, se ela existir.
  Future<void> loadLastPhoto() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_lastPhotoFileName');

      if (await file.exists()) {
        lastPhoto.value = file;
        print('📸 Última foto carregada de: ${file.path}');
      } else {
        print('ℹ️ Nenhuma foto salva encontrada.');
      }
    } catch (e) {
      print('❌ Erro ao carregar a última foto: $e');
    }
  }

  /// Salva a imagem recebida, sobrescrevendo a anterior.
  Future<void> saveImage(Uint8List imageBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_lastPhotoFileName';
      final file = File(path);
      
      // Escreve os bytes no arquivo, sobrescrevendo o conteúdo anterior.
      await file.writeAsBytes(imageBytes);

      // Atualiza a variável reativa para a UI reagir.
      // Adicionamos um timestamp para forçar a atualização do cache do Image.file.
      lastPhoto.value = await file.copy('${file.path}?v=${DateTime.now().millisecondsSinceEpoch}');
      
      print('📸 Foto salva/sobrescrita em: $path');
    } catch (e) {
      print('❌ Erro ao salvar a imagem: $e');
    }
  }

  /// Exclui a última foto salva.
  Future<void> deleteLastPhoto() async {
    if (lastPhoto.value != null && await lastPhoto.value!.exists()) {
      try {
        await lastPhoto.value!.delete();
        lastPhoto.value = null; // Limpa a variável para a UI atualizar.
        // MODIFICADO: SnackBar de sucesso com a nova identidade visual
        Get.snackbar(
          'Sucesso!',
          'A foto foi excluída.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF16213E),
          colorText: Colors.white,
          margin: EdgeInsets.zero,
          borderRadius: 0,
          icon: const Icon(Icons.check_circle_outline, color: Color(0xFF53BF9D)),
          snackStyle: SnackStyle.GROUNDED,
        );
        print('🗑️ Última foto excluída.');
      } catch (e) {
        print('❌ Erro ao excluir a foto: $e');
        // MODIFICADO: SnackBar de erro com a nova identidade visual
        Get.snackbar(
          'Erro',
          'Não foi possível excluir a foto.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF16213E),
          colorText: Colors.white,
          margin: EdgeInsets.zero,
          borderRadius: 0,
          icon: Icon(Icons.error_outline, color: Colors.red.shade400),
          snackStyle: SnackStyle.GROUNDED,
        );
      }
    }
  }
}