/// Web build stub — dart:ffi (which tflite_flutter depends on) does not
/// exist on Flutter Web, so this file provides a same-shaped API that
/// always reports "unavailable." RecommendationService then transparently
/// falls back to rule-based recommendations on web, with no compile error.
class TFLiteLoader {
  Future<bool> load(String assetPath) async {
    return false; // never available on web
  }

  List<double>? runInference(List<double> features, int outputSize) {
    return null; // never called since load() always returns false
  }

  void dispose() {}
}
