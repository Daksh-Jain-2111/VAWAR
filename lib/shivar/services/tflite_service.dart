import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class InferenceData {
  final Uint8List imageBytes;
  InferenceData(this.imageBytes);
}

/// Top-level isolate function (REQUIRED by compute)
Future<Map<String, dynamic>> runInferenceInIsolate(
    InferenceData data) async {
  // Placeholder – safe on low-end devices
  return {
    'disease': 'Unknown',
    'confidence': 0.0,
    'severity': 'Low',
    'recommendation': 'Analysis pending',
  };
}

class TFLiteService {
  bool _initialized = false;

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<Map<String, dynamic>> detectDisease(
      Uint8List imageBytes) async {
    if (!_initialized) {
      await initialize();
    }

    final data = InferenceData(imageBytes);
    return await compute(runInferenceInIsolate, data);
  }

  void dispose() {
    _initialized = false;
  }
}
