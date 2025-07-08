import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class BabyDetectionController extends GetxController {
  static const String _modelPath = "assets/ml/model_child_detection_v5.tflite";
  static const int _inputSize = 224;
  static const int _maxRecentInferences = 5;

  var isModelLoaded = false.obs;
  var isLoadingModel = false.obs;
  var errorLoadingModel = Rx<String?>(null);
  var lastInferenceResult = Rx<Map<String, dynamic>?>(null);
  var lastInferenceTime = 0.obs;
  var averageConfidence = 0.0.obs;
  final RxList<double> recentConfidences = <double>[].obs;

  late Interpreter _interpreter;
  final Queue<double> _confidenceQueue = Queue<double>();

  // --- Getters ---
  bool get modelReady => isModelLoaded.value && !isLoadingModel.value;

  // --- MUDANÇA 1: onInit REMOVIDO ---
  // O método onInit() foi removido. A inicialização agora é controlada
  // externamente através do método init().

  @override
  void onInit() {
    super.onInit();
  }

  void onClose() {
    _interpreter.close();
    super.onClose();
  }

  /// --- MUDANÇA 2: MÉTODO DE INICIALIZAÇÃO ASSÍNCRONO ---
  /// Este método será chamado pelo SplashPageController para carregar o modelo.
  Future<void> init() async {
    if (isModelLoaded.value || isLoadingModel.value) {
      print("ℹ️ Tentativa de carregar modelo que já está carregado ou em processo.");
      return;
    }

    isLoadingModel.value = true;
    errorLoadingModel.value = null;
    print("⏳ Carregando modelo de detecção...");

    try {
      _interpreter = await Interpreter.fromAsset(
        _modelPath
      );

      isModelLoaded.value = true;
      errorLoadingModel.value = null;
      print("✅ Modelo TFLite (BabyDetectionController) carregado com sucesso!");

    } catch (e) {
      errorLoadingModel.value = e.toString();
      isModelLoaded.value = false;
      print("❌ Falha ao carregar modelo (BabyDetectionController): $e");
      // Propaga o erro para que o Future.wait no splash controller possa capturá-lo.
      throw Exception("Falha ao carregar BabyDetectionController: $e");
    } finally {
      isLoadingModel.value = false;
    }
  }

  /// Atualiza a fila de confianças recentes e recalcula a média.
  void _updateAverageConfidence(double newConfidence) {
    _confidenceQueue.addLast(newConfidence);
    if (_confidenceQueue.length > _maxRecentInferences) {
      _confidenceQueue.removeFirst();
    }

    if (_confidenceQueue.isNotEmpty) {
      final double sum = _confidenceQueue.reduce((a, b) => a + b);
      averageConfidence.value = sum / _confidenceQueue.length;
    } else {
      averageConfidence.value = 0.0;
    }
    recentConfidences.assignAll(_confidenceQueue.toList().reversed);
  }

  Future<Map<String, dynamic>> detectInImage(XFile imageFile) async {
    if (!modelReady) {
      final errorMsg = "Modelo não está pronto. ${errorLoadingModel.value ?? ''}";
      print("⚠️ $errorMsg");
      return {"error": errorMsg};
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      final imageBytes = await imageFile.readAsBytes();
      final processedImage = await _preprocessImage(imageBytes);
      
      var output = List.filled(1, 0.0).reshape([1, 1]);

      _interpreter.run(processedImage, output);

      final endTime = DateTime.now().millisecondsSinceEpoch;
      lastInferenceTime.value = endTime - startTime;

      final double confidence = output[0][0];
      final String label = confidence > 0.5 ? "Criança" : "Não Criança";

      _updateAverageConfidence(confidence);

      final result = {
        "label": label,
        "confidence": confidence,
        "inference_time": lastInferenceTime.value,
        "cached": false,
        "image_path": imageFile.path,
      };

      lastInferenceResult.value = result;
      return result;

    } catch (e) {
      print("❌ Erro durante a inferência: $e");
      return {"error": "Falha na inferência: $e"};
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(Uint8List imageBytes) async {
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception("Falha ao decodificar a imagem.");
    }

    img.Image resizedImage = img.copyResize(
      originalImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    var input = List.generate(
      1, (i) => List.generate(
      _inputSize, (y) => List.generate(
        _inputSize, (x) {
      final pixel = resizedImage.getPixel(x, y);

      // Usamos a fórmula de luminância padrão para converter o pixel.
      final luminance = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);

      // Normalizar e retornar um array com APENAS UM canal.
      return [luminance / 255.0];
    }
    ),
    ),
    );

    return input;
  }
}
