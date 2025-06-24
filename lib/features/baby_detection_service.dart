import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tensorflow_lite_fluttzer/tensorflow_lite_flutter.dart' as Tflite_old;
import 'package:tflite_flutter/tflite_flutter.dart';

class BabyDetectionService {
  static const int inputSize = 224;
  static const double mean = 0.0;
  static const double std = 255.0;

  static BabyDetectionService? _instance;
  static bool _modelLoaded = false;
  static String? _loadError;

  late Interpreter _interpreter;

  String? _lastImagePath;
  Map<String, dynamic>? _lastResult;

  factory BabyDetectionService() {
    _instance ??= BabyDetectionService._internal();
    return _instance!;
  }

  BabyDetectionService._internal();

  Future<void> loadModel() async {
    if (_modelLoaded) {
      print("✅ Model already loaded");
      return;
    }

    try {
      print("🔄 Starting model loading...");

      // Close any previous interpreter from the old plugin if it was loaded.
      try {
        await Tflite_old.Tflite.close().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print("⚠️ Old Tflite plugin close timeout - continuing anyway");
          },
        );
      } catch (e) {
        print("⚠️ Error closing previous old Tflite model: $e");
      }

      // Close the Interpreter instance of this service if it was previously loaded
      // by a prior successful call to loadModel().
      // This is safe because _modelLoaded being true implies _interpreter was initialized.
      if (_modelLoaded) {
        try {
          _interpreter.close();
          print("⚠️ Closed previous Interpreter instance of this service.");
        } catch (e) {
          print("⚠️ Error closing previous Interpreter (likely not fully initialized/closed cleanly before): $e");
        }
      }


      print("🔄 Loading TensorFlow Lite model using Interpreter.fromAsset...");

      // Verifica se os arquivos existem
      try {
        await rootBundle.load("assets/ml/model_child_detection_v3.tflite");
        print("✅ Model file found");
      } catch (e) {
        throw Exception("Arquivo do modelo não encontrado: $e");
      }

      // Labels are optional for the Interpreter, but we might read them later
      try {
        await rootBundle.load("assets/ml/labels.txt"); // Still check if it exists
        print("✅ Labels file found");
      } catch (e) {
        print("⚠️ Labels file not found, continuing without it: $e");
      }

      _interpreter = await Interpreter.fromAsset(
        "assets/ml/model_child_detection_v3.tflite",
        options: InterpreterOptions()..threads = 1,
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          throw Exception("Timeout: Modelo demorou mais de 25 segundos para carregar");
        },
      );

      _modelLoaded = true;
      _loadError = null;
      print("✅ Model Loaded Successfully: ${_interpreter.getInputTensor(0).type}");
      print("Model Output Tensor Type: ${_interpreter.getOutputTensor(0).type}");

    } catch (e) {
      _loadError = e.toString();
      _modelLoaded = false;
      print("❌ Failed to load model: $e");
      rethrow;
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      print("❌ Failed to decode image from path: $imagePath");
      throw Exception("Failed to decode image");
    }

    print("🔄 Original image size: ${originalImage.width}x${originalImage.height}");

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
              return grayValue / 255.0; // Normalize to [0, 1]
            },
          ),
        ),
      ),
    );
    return input;
  }

  Future<Map<String, dynamic>> detectInImage(XFile imageFile) async {
    if (!_modelLoaded) {
      return {"error": "Model not loaded${_loadError != null ? ': $_loadError' : ''}"};
    }

    if (_lastImagePath == imageFile.path && _lastResult != null) {
      print("📋 Using cached result");
      var cachedResult = Map<String, dynamic>.from(_lastResult!);
      cachedResult['cached'] = true;
      return cachedResult;
    }

    try {
      int startTime = DateTime.now().millisecondsSinceEpoch;

      print("🔄 Running inference on image: ${imageFile.path}");

      final List<List<List<List<double>>>> processedImageInput = await _preprocessImage(imageFile.path);
      if (processedImageInput == null) {
        return {"error": "Failed to preprocess image."};
      }

      var output = List<List<double>>.filled(1, List<double>.filled(1, 0.0));

      _interpreter.run(processedImageInput, output);

      int endTime = DateTime.now().millisecondsSinceEpoch;
      int inferenceTime = endTime - startTime;

      print("⚡ Inference time: ${inferenceTime}ms");

      double confidenceValue = (output[0][0]).toDouble();
      String detectedLabel;

      if (confidenceValue > 0.5) {
        detectedLabel = "Child";
      } else {
        detectedLabel = "No Child";
      }

      var result = {
        "label": detectedLabel,
        "confidence": confidenceValue,
        "index": -1,
        "all_results": [
          {"confidence": confidenceValue, "label": detectedLabel, "index": -1}
        ],
        "inference_time": inferenceTime,
        "cached": false,
      };

      _lastImagePath = imageFile.path;
      _lastResult = result;

      return result;
    } catch (e) {
      print("❌ Inference error: $e");
      return {"error": "Inference failed: $e"};
    }
  }

  Future<Map<String, dynamic>> quickPreview(XFile imageFile) async {
    if (!_modelLoaded) {
      return {"error": "Model not loaded"};
    }

    try {
      int startTime = DateTime.now().millisecondsSinceEpoch;

      print("⚡ Running quick preview...");

      final List<List<List<List<double>>>> processedImageInput = await _preprocessImage(imageFile.path);
      if (processedImageInput == null) {
        return {"error": "Failed to preprocess image for quick preview."};
      }

      var output = List<List<double>>.filled(1, List<double>.filled(1, 0.0));

      _interpreter.run(processedImageInput, output);

      int endTime = DateTime.now().millisecondsSinceEpoch;
      double confidenceValue = (output[0][0]).toDouble();
      String detectedLabel;

      if (confidenceValue > 0.8) {
        detectedLabel = "Child";
      } else {
        detectedLabel = "No Child";
      }

      var result = {
        "label": detectedLabel,
        "confidence": confidenceValue,
        "inference_time": endTime - startTime,
        "is_preview": true,
      };
      return result;

    } catch (e) {
      print("❌ Quick preview error: $e");
      return {"error": "Quick preview unavailable"};
    }
  }

  Future<Map<String, dynamic>> detectWithFallback(XFile imageFile) async {
    if (!_modelLoaded) {
      return {"error": "Model not loaded"};
    }

    try {
      print("🔄 Running full fallback detection...");

      int startTime = DateTime.now().millisecondsSinceEpoch;

      final List<List<List<List<double>>>> processedImageInput = await _preprocessImage(imageFile.path);
      if (processedImageInput == null) {
        return {"error": "Failed to preprocess image for fallback detection."};
      }

      var output = List<List<double>>.filled(1, List<double>.filled(1, 0.0));

      _interpreter.run(processedImageInput, output);

      int endTime = DateTime.now().millisecondsSinceEpoch;

      double confidenceValue = (output[0][0]).toDouble();
      String detectedLabel;

      if (confidenceValue > 0.05) {
        detectedLabel = "Child";
      } else {
        detectedLabel = "No Child";
      }

      return {
        "label": detectedLabel,
        "confidence": confidenceValue,
        "index": -1,
        "all_results": [
          {"confidence": confidenceValue, "label": detectedLabel, "index": -1}
        ],
        "inference_time": endTime - startTime,
        "method": "fallback",
      };
    } catch (e) {
      print("❌ Fallback inference error: $e");
      throw e;
    }
  }

  void clearCache() {
    _lastImagePath = null;
    _lastResult = null;
    print("🧹 Cache cleared");
  }

  Future<void> optimizeModel() async {
    if (!_modelLoaded) return;

    try {
      print("🔥 Model ready for inference");
    } catch (e) {
      print("⚠️ Model optimization note: $e");
    }
  }

  Future<void> close() async {
    try {
      if (_modelLoaded) {
        _interpreter.close();
        print("🛑 TensorFlow Lite interpreter closed.");
      }
      // If you are still using tensorflow_lite_flutter's Tflite methods elsewhere,
      // consider removing or carefully managing that dependency.
      // For now, the old Tflite plugin's close is commented out.
      // await Tflite_old.Tflite.close();
    } catch (e) {
      print("⚠️ Error closing interpreter: $e");
    }

    _modelLoaded = false;
    _loadError = null;
    clearCache();
  }

  bool get isModelLoaded => _modelLoaded;
  String? get loadError => _loadError;

  static void reset() {
    _instance = null;
    _modelLoaded = false;
    _loadError = null;
  }
}