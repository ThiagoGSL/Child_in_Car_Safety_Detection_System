import 'dart:io';
import 'dart:typed_data';
import 'package:app_v0/features/Child_detection/baby_detection_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PhotoController extends GetxController {
  // Observável para a última foto
  var lastPhoto = Rx<File?>(null);
  // Observável para o resultado da detecção
  var detectionResult = Rx<Map<String, dynamic>?>(null);
  // Observável para controlar o estado de processamento da imagem
  var isProcessing = false.obs;

  // Injetando o controller de detecção
  final BabyDetectionController _babyDetectionController = Get.find();

  final String _lastPhotoFileName = 'last_received_photo.jpg';

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init() async {
    print("PhotoController: Iniciando carregamento da última foto...");
    await loadLastPhoto();
    // Se uma foto já existir, analisa ela na inicialização
    if (lastPhoto.value != null) {
      await analyzeLastPhoto();
    }
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

  /// Salva a imagem recebida e dispara a análise.
  Future<void> saveImage(Uint8List imageBytes) async {
    isProcessing.value = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_lastPhotoFileName';
      final file = File(path);
      
      await file.writeAsBytes(imageBytes);

      imageCache.clear();
      imageCache.clearLiveImages();
      
      lastPhoto.value = file;
      lastPhoto.refresh();
      
      print('📸 Foto salva/sobrescrita em: $path');

      // Após salvar, chama a análise da imagem
      await analyzeLastPhoto();

    } catch (e) {
      print('❌ Erro ao salvar a imagem: $e');
      detectionResult.value = {"error": "Falha ao salvar a imagem"};
    } finally {
      isProcessing.value = false;
    }
  }

  /// Analisa a foto armazenada em `lastPhoto`.
  Future<void> analyzeLastPhoto() async {
    if (lastPhoto.value == null) {
      print("⚠️ Nenhuma foto para analisar.");
      return;
    }

    // Garante que o modelo esteja pronto antes de tentar a detecção
    if (!_babyDetectionController.modelReady) {
      print("⏳ Modelo não está pronto, aguardando...");
      // Espera um pouco para o caso de o modelo ainda estar carregando
      await Future.delayed(const Duration(seconds: 2)); 
      if (!_babyDetectionController.modelReady) {
        print("❌ Modelo ainda não está pronto após espera.");
        detectionResult.value = {"error": "Modelo de IA não carregado"};
        return;
      }
    }

    print("🤖 Iniciando análise da imagem...");
    isProcessing.value = true;
    try {
      final result = await _babyDetectionController.detectInImage(XFile(lastPhoto.value!.path));
      detectionResult.value = result;
      print("✅ Análise concluída: ${result['label']} com confiança de ${result['confidence']}");
    } catch (e) {
      print("❌ Erro durante a análise da imagem: $e");
      detectionResult.value = {"error": "Falha na análise"};
    } finally {
      isProcessing.value = false;
    }
  }

  /// Exclui a última foto salva e limpa o resultado.
  Future<void> deleteLastPhoto() async {
    final photo = lastPhoto.value;
    if (photo != null && await photo.exists()) {
      try {
        await photo.delete();
        lastPhoto.value = null; 
        detectionResult.value = null; // Limpa o resultado da detecção
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
