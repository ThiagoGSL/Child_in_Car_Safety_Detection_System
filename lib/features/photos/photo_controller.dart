import 'dart:io';
import 'dart:typed_data';
import 'package:app_v0/features/Child_detection/baby_detection_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Import necessário para XFile
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PhotoController extends GetxController {
  // Observáveis
  var lastPhoto = Rx<File?>(null);
  var detectionResult = Rx<Map<String, dynamic>?>(null);
  var isProcessing = false.obs;
  var criancaDetectada = false.obs;

  // Injetando o controller de detecção
  final BabyDetectionController _babyDetectionController = Get.find();

  final String _lastPhotoFileName = 'last_received_photo.jpg';

  @override
  void onInit() {
    super.onInit();
    // --- MUDANÇA PRINCIPAL ---
    // O worker 'ever' escuta a variável 'lastPhoto'.
    // Sempre que ela for alterada (seja por salvar ou carregar), 
    // a função _analyzePhoto será executada automaticamente.
    ever(lastPhoto, _analyzePhoto);
  }

  Future<void> init() async {
    print("PhotoController: Iniciando carregamento da última foto...");
    await loadLastPhoto();
    print("PhotoController: Inicialização concluída.");
  }

  /// Carrega a última foto salva, se ela existir.
  /// A análise será disparada automaticamente pelo worker 'ever'.
  Future<void> loadLastPhoto() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_lastPhotoFileName');

      if (await file.exists()) {
        lastPhoto.value = file; // Apenas atualiza o valor
        print('📸 Última foto carregada de: ${file.path}');
      } else {
        print('ℹ️ Nenhuma foto salva encontrada.');
      }
    } catch (e) {
      print('❌ Erro ao carregar a última foto: $e');
    }
  }

  /// Salva a imagem recebida.
  /// A análise será disparada automaticamente pelo worker 'ever'.
  Future<void> saveImage(Uint8List imageBytes) async {
    // Não é mais necessário controlar o isProcessing aqui
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_lastPhotoFileName';
      final file = File(path);
      
      await file.writeAsBytes(imageBytes);

      // Limpa o cache para garantir que a UI mostre a nova imagem
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // Apenas atualiza o valor, o 'ever' fará o resto
      lastPhoto.value = file; 
      
      print('📸 Foto salva/sobrescrita em: $path');

    } catch (e) {
      print('❌ Erro ao salvar a imagem: $e');
      detectionResult.value = {"error": "Falha ao salvar a imagem"};
    }
  }

  /// Analisa a foto. Este método agora é privado e chamado pelo worker.
  Future<void> _analyzePhoto(File? photo) async {
    if (photo == null) {
      print("ℹ️ Foto nula, limpando resultado.");
      detectionResult.value = null; // Limpa o resultado se a foto for removida
      return;
    }

    if (!_babyDetectionController.modelReady) {
      print("❌ Modelo de IA não carregado. Não é possível analisar.");
      detectionResult.value = {"error": "Modelo de IA não carregado"};
      return;
    }

    print("🤖 Iniciando análise da imagem...");
    isProcessing.value = true;
    try {
      final result = await _babyDetectionController.detectInImage(XFile(photo.path));
      detectionResult.value = result;
      criancaDetectada.value = result['label'] == "Criança" ? true : false;
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
        lastPhoto.value = null; // Dispara o worker 'ever' que vai limpar o resultado
        Get.snackbar('Sucesso!', 'A foto foi excluída.');
        print('🗑️ Última foto excluída.');
      } catch (e) {
        print('❌ Erro ao excluir a foto: $e');
        Get.snackbar('Erro', 'Não foi possível excluir a foto.');
      }
    }
  }

  // O método shareLastPhoto continua igual
  Future<void> shareLastPhoto() async {
    final photo = lastPhoto.value;
    
    if (photo != null && await photo.exists()) {
      try {
        final xfile = XFile(photo.path);
        await Share.shareXFiles([xfile], text: 'Foto monitorada pelo SafeBaby!');
        print('🚀 Foto compartilhada com sucesso.');
      } catch (e) {
        print('❌ Erro ao compartilhar a foto: $e');
      }
    } else {
      Get.snackbar('Erro', 'Não foi possível encontrar a foto para compartilhar.');
      print('⚠️ Tentativa de compartilhar uma foto que não existe.');
    }
  }
}