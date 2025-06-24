import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // NOVO: Importa o pacote de compartilhamento

class PhotoController extends GetxController {
  var lastPhoto = Rx<File?>(null);

  final String _lastPhotoFileName = 'last_received_photo.jpg';

  @override
  void onInit() {
    super.onInit();
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
      
      await file.writeAsBytes(imageBytes);

      // Limpamos o cache da imagem para garantir que a nova versão seja exibida
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // Atualiza a variável reativa. O 'File' por si só é suficiente.
      lastPhoto.value = file;
      // Força a atualização do Obx na UI, caso o caminho seja o mesmo.
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

  // NOVO: Método para compartilhar a última foto.
  Future<void> shareLastPhoto() async {
    final photo = lastPhoto.value;
    
    // Verifica se a referência ao arquivo não é nula e se o arquivo realmente existe no disco.
    if (photo != null && await photo.exists()) {
      try {
        // Converte o File para XFile, que é o tipo esperado pelo pacote share_plus.
        final xfile = XFile(photo.path);

        // Abre a interface de compartilhamento nativa do sistema operacional.
        await Share.shareXFiles(
          [xfile],
          text: 'Foto do meu bebê, monitorada pelo SafeBaby!', // Texto opcional que acompanha a imagem.
        );
        print('🚀 Foto compartilhada com sucesso.');
      } catch (e) {
        print('❌ Erro ao compartilhar a foto: $e');
      }
    } else {
      // Se o arquivo não for encontrado, exibe uma mensagem de erro com a identidade visual do app.
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