import 'dart:typed_data';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart' as Tflite_old;

class BabyDetectionController extends GetxController {
  static const String _modelPath = "assets/ml/model_child_detection_v3.tflite";
  static const int _inputSize = 224;
  static const int _maxRecentInferences = 5;
  var isModelLoaded = false.obs;
  var isLoadingModel = false.obs;
  var errorLoadingModel = Rx<String?>(null);
  var lastInferenceResult = Rx<Map<String, dynamic>?>(null);
  var lastInferenceTime = 0.obs;
  var averageConfidence = 0.0.obs; // Média de confiança das últimas inferências
  final RxList<double> recentConfidences = <double>[].obs; // Lista das últimas confianças

  late Interpreter _interpreter;
  String? _lastImagePath;
  final Queue<double> _confidenceQueue = Queue<double>();

  // --- Getters ---
  bool get modelReady => isModelLoaded.value && !isLoadingModel.value;

  @override
  void onInit() {
    super.onInit();
    loadModel();
  }

  @override
  void onClose() {
    _interpreter.close();
    try {
      Tflite_old.Tflite.close();
    } catch (e) {
    }
    super.onClose();
  }

  /// Atualiza a fila de confianças recentes e recalcula a média.
  void _updateAverageConfidence(double newConfidence) {
    _confidenceQueue.addLast(newConfidence);
    if (_confidenceQueue.length > _maxRecentInferences) {
      _confidenceQueue.removeFirst(); // Mantém a fila com no máximo 5 itens
    }

    if (_confidenceQueue.isNotEmpty) {
      final double sum = _confidenceQueue.reduce((a, b) => a + b);
      averageConfidence.value = sum / _confidenceQueue.length;
    } else {
      averageConfidence.value = 0.0;
    }

    // Atualiza a lista reativa para a UI, se necessário
    recentConfidences.assignAll(_confidenceQueue.toList().reversed);
    print("📊 Confianças recentes: $recentConfidences");
    print("📈 Média de confiança atual: ${averageConfidence.value}");
  }


  Future<Map<String, dynamic>> detectInImage(XFile imageFile) async {
    if (!modelReady) {
      final errorMsg = "Modelo não está pronto. ${errorLoadingModel.value ?? ''}";
      print("⚠️ $errorMsg");
      return {"error": errorMsg};
    }

    print("🔄 Executando inferência na imagem: ${imageFile.path}");
    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      final imageBytes = await imageFile.readAsBytes();
      final processedImage = await _preprocessImage(imageBytes);

      var output = List<List<double>>.filled(1, List<double>.filled(1, 0.0));

      _interpreter.run(processedImage, output);

      final endTime = DateTime.now().millisecondsSinceEpoch;
      lastInferenceTime.value = endTime - startTime;

      print("⚡ Tempo de inferência: ${lastInferenceTime.value}ms");

      final double confidence = output[0][0];
      final String label = confidence > 0.5 ? "Criança" : "Não Criança";

      // --- ATUALIZA A MÉDIA ---
      _updateAverageConfidence(confidence); // Chama o novo método

      final result = {
        "label": label,
        "confidence": confidence,
        "inference_time": lastInferenceTime.value,
        "cached": false,
        "image_path": imageFile.path, // Adiciona o caminho da imagem ao resultado
      };

      _lastImagePath = imageFile.path;
      lastInferenceResult.value = result;

      return result;

    } catch (e) {
      print("❌ Erro durante a inferência: $e");
      return {"error": "Falha na inferência: $e"};
    }
  }

  Future<void> loadModel() async {
    if (isModelLoaded.value || isLoadingModel.value) {
      print("✅ Modelo já carregado ou em processo de carregamento.");
      return;
    }

    isLoadingModel.value = true;
    errorLoadingModel.value = null;
    print("🔄 Carregando modelo TensorFlow Lite...");

    try {
      await Tflite_old.Tflite.close().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print("⚠️ Timeout ao fechar o plugin TFLite antigo - continuando mesmo assim.");
        },
      );
    } catch (e) {
      print("⚠️ Erro ao fechar o modelo TFLite antigo anterior: $e");
    }

    try {
      await rootBundle.load(_modelPath);
      print("✅ Arquivo do modelo encontrado em '$_modelPath'");
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: InterpreterOptions()..threads = 2,
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw Exception("Timeout: Modelo demorou mais de 25 segundos para carregar"),
      );

      isModelLoaded.value = true;
      errorLoadingModel.value = null;
      print("✅ Modelo TFLite (tflite_flutter) carregado com sucesso!");

    } catch (e) {
      errorLoadingModel.value = e.toString();
      isModelLoaded.value = false;
      print("❌ Falha ao carregar modelo: $e");
    } finally {
      isLoadingModel.value = false;
    }
  }
  Future<List<List<List<List<double>>>>> _preprocessImage(Uint8List imageBytes) async {
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception("Falha ao decodificar a imagem.");
    }

    img.Image grayscaleImage = img.grayscale(originalImage);
    img.Image resizedImage = img.copyResize(
      grayscaleImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    var input = List.generate(1, (batch) =>
        List.generate(_inputSize, (y) =>
            List.generate(_inputSize, (x) {
              final int pixelValue = resizedImage.getPixel(x, y);
              final int grayValue = img.getRed(pixelValue);
              return [grayValue / 255.0];
            }),
        ),
    );

    return input;
  }
}
