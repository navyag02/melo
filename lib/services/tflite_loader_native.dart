import 'package:flutter_litert/flutter_litert.dart';

/// Native build implementation — only compiled in for Android, iOS, and
/// desktop targets (anything with dart:io), where dart:ffi is available
/// and tflite_flutter can actually run inference.
class TFLiteLoader {
  Interpreter? _interpreter;

  Future<bool> load(String assetPath) async {
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
      return true;
    } catch (e) {
      print('TFLiteLoader: failed to load model: $e');
      return false;
    }
  }

  List<double>? runInference(List<double> features, int outputSize) {
    if (_interpreter == null) return null;
    try {
      final input = [features];
      final output = List.filled(outputSize, 0.0).reshape([1, outputSize]);
      _interpreter!.run(input, output);
      return List<double>.from(output[0]);
    } catch (e) {
      print('TFLiteLoader: inference failed: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
