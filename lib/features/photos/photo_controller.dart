import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PhotoController extends GetxController {
  var lastPhoto = Rx<File?>(null);

  final String _lastPhotoFileName = 'last_received_photo.jpg';

  // --- MUDANÇA 1: onInit AGORA É LEVE ---
  // O método onInit agora está limpo. A lógica de inicialização foi
  // movida para o novo método init() abaixo.
  @override
  void onInit() {
    super.onInit();
  }

  // --- MUDANÇA 2: NOVO MÉTODO DE INICIALIZAÇÃO ASSÍNCRONO ---
  /// Este método será chamado e aguardado ('awaited') pelo SplashPageController
  /// durante a tela de carregamento do app.
  Future<void> init() async {
    print("PhotoController: Iniciando carregamento da última foto...");
    await loadLastPhoto();
    print("PhotoController: Inicialização concluída.");
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
      
      await file.writeAsBytes(imageBytes);

      // Limpamos o cache da imagem para garantir que a nova versão seja exibida
      imageCache.clear();
      imageCache.clearLiveImages();
      
      lastPhoto.value = file;
      lastPhoto.refresh();
      
      print('📸 Foto salva/sobrescrita em: $path');
    } catch (e) {
      print('❌ Erro ao salvar a imagem: $e');
    }
  }

  /// Exclui a última foto salva.
  Future<void> deleteLastPhoto() async {
    final photo = lastPhoto.value;
    if (photo != null && await photo.exists()) {
      try {
        await photo.delete();
        lastPhoto.value = null; 
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

  /// Método para compartilhar a última foto.
  Future<void> shareLastPhoto() async {
    final photo = lastPhoto.value;
    
    if (photo != null && await photo.exists()) {
      try {
        final xfile = XFile(photo.path);

        await Share.shareXFiles(
          [xfile],
          text: 'Foto do meu bebê, monitorada pelo SafeBaby!',
        );
        print('🚀 Foto compartilhada com sucesso.');
      } catch (e) {
        print('❌ Erro ao compartilhar a foto: $e');
      }
    } else {
      Get.snackbar(
        'Erro',
        'Não foi possível encontrar a foto para compartilhar.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF16213E),
        colorText: Colors.white,
        margin: EdgeInsets.zero,
        borderRadius: 0,
        icon: Icon(Icons.error_outline, color: Colors.red.shade400),
        snackStyle: SnackStyle.GROUNDED,
      );
      print('⚠️ Tentativa de compartilhar uma foto que não existe.');
    }
  }
}