// services/baby_detection_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class BabyDetectionService {
  static const int inputSize = 224;
  static const double mean = 0.0;
  static const double std = 255.0;

  static BabyDetectionService? _instance;
  static bool _modelLoaded = false;
  static String? _loadError;

  late Interpreter _interpreter;

  static const int _maxTestHistory = 5;
  final List<double> _testConfidenceHistory = [];
  double _averageConfidence = 0.0;

  String? _targetFilePath;
  StreamSubscription<FileSystemEvent>? _fileWatcherSubscription;
  final StreamController<double> _averageConfidenceController = StreamController<double>.broadcast();

  Stream<double> get averageConfidenceStream => _averageConfidenceController.stream;
  double get currentAverageConfidence => _averageConfidence;

  BabyDetectionService._internal();

  factory BabyDetectionService() {
    _instance ??= BabyDetectionService._internal();
    return _instance!;
  }

  Future<void> loadModel() async {
    if (_modelLoaded) {
      print("✅ Modelo já carregado.");
      return;
    }

    try {
      print("🔄 Iniciando carregamento do modelo...");

      if (_modelLoaded && _interpreter != null) {
        try {
          _interpreter.close();
          print("⚠️ Instância anterior do interpretador fechada.");
        } catch (e) {
          print("⚠️ Erro ao fechar interpretador anterior: $e");
        }
      }

      print("🔄 Carregando modelo TensorFlow Lite com Interpreter.fromAsset...");

      try {
        await rootBundle.load("assets/ml/model_child_detection_v3.tflite");
        print("✅ Arquivo do modelo encontrado.");
      } catch (e) {
        throw Exception("Arquivo do modelo não encontrado: $e");
      }

      try {
        await rootBundle.load("assets/ml/labels.txt");
        print("✅ Arquivo de labels encontrado.");
      } catch (e) {
        print("⚠️ Arquivo de labels não encontrado, continuando sem ele: $e");
      }

      _interpreter = await Interpreter.fromAsset(
        "assets/ml/model_child_detection_v3.tflite",
        options: InterpreterOptions()..threads = 1,
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          throw Exception("Timeout: Modelo demorou mais de 25 segundos para carregar.");
        },
      );

      _modelLoaded = true;
      _loadError = null;
      print("✅ Modelo carregado com sucesso. Tipo de Tensor de Entrada: ${_interpreter.getInputTensor(0).type}");
      print("Tipo de Tensor de Saída do Modelo: ${_interpreter.getOutputTensor(0).type}");

    } catch (e) {
      _loadError = e.toString();
      _modelLoaded = false;
      print("❌ Falha ao carregar modelo: $e");
      rethrow;
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      print("❌ Falha ao decodificar imagem do caminho: $imagePath");
      throw Exception("Falha ao decodificar imagem.");
    }

    img.Image grayscaleImage = img.grayscale(originalImage);

    img.Image resizedImage = img.copyResize(
      grayscaleImage,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    List<List<List<List<double>>>> input = List.generate(
      1,
          (batchIndex) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) => List.generate(
            1,
                (c) {
              final int pixelValue = resizedImage.getPixel(x, y);
              final int grayValue = img.getRed(pixelValue);
              return grayValue / 255.0;
            },
          ),
        ),
      ),
    );
    return input;
  }

  Future<Map<String, dynamic>> detectInImage(String imagePath) async {
    if (!_modelLoaded) {
      return {"error": "Modelo não carregado${_loadError != null ? ': $_loadError' : ''}"};
    }

    try {
      int startTime = DateTime.now().millisecondsSinceEpoch;

      print("🔄 Executando inferência na imagem: $imagePath");

      final File file = File(imagePath);
      if (!await file.exists()) {
        throw Exception("Arquivo de imagem não encontrado: $imagePath");
      }

      final List<List<List<List<double>>>> processedImageInput = await _preprocessImage(imagePath);
      if (processedImageInput == null) {
        return {"error": "Falha ao pré-processar imagem."};
      }

      var output = List<List<double>>.filled(1, List<double>.filled(1, 0.0));

      _interpreter.run(processedImageInput, output);

      int endTime = DateTime.now().millisecondsSinceEpoch;
      int inferenceTime = endTime - startTime;

      print("⚡ Tempo de inferência para ${imagePath.split('/').last}: ${inferenceTime}ms");

      double confidenceValue = (output[0][0]).toDouble();
      String detectedLabel;

      if (confidenceValue > 0.5) {
        detectedLabel = "Criança";
      } else {
        detectedLabel = "Nenhuma Criança";
      }

      var result = {
        "label": detectedLabel,
        "confidence": confidenceValue,
        "index": -1,
        "all_results": [
          {"confidence": confidenceValue, "label": detectedLabel, "index": -1}
        ],
        "inference_time": inferenceTime,
      };

      _addTestResult(confidenceValue);
      _calculateAndNotifyAverageConfidence();

      return result;
    } catch (e) {
      print("❌ Erro de inferência para $imagePath: $e");
      return {"error": "Inferência falhou: $e"};
    }
  }

  Future<void> startMonitoringFile(String filePath) async {
    if (_targetFilePath == filePath && _fileWatcherSubscription != null) {
      print("ℹ️ Arquivo $filePath já está sendo monitorado.");
      return;
    }

    await stopMonitoringFile();

    final File file = File(filePath);
    if (!await file.exists()) {
      print("❌ Não é possível monitorar arquivo: $filePath não existe.");
      _targetFilePath = null;
      return;
    }

    _targetFilePath = filePath;
    print("👀 Iniciando monitoramento do arquivo: $filePath para mudanças...");

    await detectInImage(filePath);

    _fileWatcherSubscription = file.watch(events: FileSystemEvent.modify).listen((event) async {
      await Future.delayed(const Duration(milliseconds: 500));

      if (event.type == FileSystemEvent.modify) {
        final String modifiedFilePath = event.path;
        if (modifiedFilePath == _targetFilePath) {
          print("✨ Arquivo alvo modificado: ${modifiedFilePath.split('/').last}");
          try {
            await detectInImage(modifiedFilePath);
          } catch (e) {
            print("❌ Erro ao analisar arquivo modificado: $e");
          }
        }
      }
    }, onError: (e) {
      print("❌ Erro ao observar arquivo: $e");
    }, onDone: () {
      print("🛑 Monitoramento de arquivo parado.");
    });
  }

  Future<void> stopMonitoringFile() async {
    if (_fileWatcherSubscription != null) {
      await _fileWatcherSubscription!.cancel();
      _fileWatcherSubscription = null;
      print("🛑 Monitoramento do arquivo: $_targetFilePath parado.");
    }
    _targetFilePath = null;
  }

  void _addTestResult(double confidence) {
    _testConfidenceHistory.add(confidence);
    if (_testConfidenceHistory.length > _maxTestHistory) {
      _testConfidenceHistory.removeAt(0);
    }
    print("📊 Histórico de testes atual (${_testConfidenceHistory.length}): ${_testConfidenceHistory.map((c) => c.toStringAsFixed(2)).join(', ')}");
  }

  Future<void> _calculateAndNotifyAverageConfidence() async {
    if (_testConfidenceHistory.isEmpty) {
      _averageConfidence = 0.0;
      _averageConfidenceController.add(_averageConfidence);
      return;
    }

    double totalConfidence = _testConfidenceHistory.reduce((a, b) => a + b);
    _averageConfidence = totalConfidence / _testConfidenceHistory.length;

    print("📈 Média de confiança calculada dos últimos ${_testConfidenceHistory.length} testes: ${_averageConfidence.toStringAsFixed(4)}");
    _averageConfidenceController.add(_averageConfidence);
  }

  void clearCache() {
    _testConfidenceHistory.clear();
    _averageConfidence = 0.0;
    _averageConfidenceController.add(_averageConfidence);
    print("🧹 Histórico de testes e média de confiança limpos.");
  }

  Future<void> optimizeModel() async {
    if (!_modelLoaded) return;
    try {
      print("🔥 Modelo pronto para inferência.");
    } catch (e) {
      print("⚠️ Nota de otimização do modelo: $e");
    }
  }

  @override
  Future<void> close() async {
    await stopMonitoringFile();
    try {
      if (_modelLoaded && _interpreter != null) {
        _interpreter.close();
        print("🛑 Interpretador TensorFlow Lite fechado.");
      }
      await _averageConfidenceController.close();
    } catch (e) {
      print("⚠️ Erro ao fechar interpretador ou controlador de stream: $e");
    }

    _modelLoaded = false;
    _loadError = null;
    clearCache();
  }

  bool get isModelLoaded => _modelLoaded;
  String? get loadError => _loadError;

  static void reset() {
    _instance?._averageConfidenceController.close();
    _instance = null;
    _modelLoaded = false;
    _loadError = null;
  }
}