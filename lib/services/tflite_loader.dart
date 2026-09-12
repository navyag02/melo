/// Conditional export: on Android/iOS/desktop (where dart:io exists),
/// this resolves to the real TFLite implementation. On web, dart:io is
/// unavailable, so it falls back to the stub — keeping dart:ffi out of
/// the web build entirely, which is what fixes the "dart:ffi is not
/// available on this platform" compile error.
export 'tflite_loader_stub.dart'
    if (dart.library.io) 'tflite_loader_native.dart';
