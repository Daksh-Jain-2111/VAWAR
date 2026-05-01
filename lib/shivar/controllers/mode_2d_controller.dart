import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/analysis_api.dart';
import '../models/analysis_result.dart';

class Mode2DController extends ChangeNotifier {
  Mode2DController({AnalysisApi? analysisApi})
      : _analysisApi = analysisApi ?? AnalysisApi();

  static const String _cacheKeyLastResult = 'mode2d_last_analysis';

  final AnalysisApi _analysisApi;

  AnalysisResult? _currentResult;
  bool _isAnalyzing = false;
  String? _errorMessage;
  Uint8List? _lastPreviewJpgBytes;
  LinearGradient? _cachedHeatmapGradient;

  AnalysisResult? get currentResult => _currentResult;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;
  Uint8List? get lastPreviewJpgBytes => _lastPreviewJpgBytes;
  LinearGradient? get heatmapGradient => _cachedHeatmapGradient;

  bool get hasResult => _currentResult != null;

  Future<void> loadLastAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKeyLastResult);
      final result = AnalysisResult.fromJsonString(jsonStr);
      if (result != null) {
        _setResult(result.copyWith(fromCache: true));
        notifyListeners();
      }
    } catch (_) {
      // Corrupt cache should never crash the app.
    }
  }

  Future<void> clearError() async {
    _errorMessage = null;
    notifyListeners();
  }

  void clearPreview() {
    _lastPreviewJpgBytes = null;
    notifyListeners();
  }

  void _setResult(AnalysisResult result) {
    _currentResult = result;

    // Precompute heatmap gradient once per analysis to avoid recomputing
    // on every widget rebuild.
    final vegetationScore = result.vegetation.vegetationScore.clamp(0.0, 1.0);
    final weakAreaOpacity = (1 - vegetationScore).clamp(0.1, 0.7);
    final healthyAreaOpacity = vegetationScore.clamp(0.1, 0.7);

    _cachedHeatmapGradient = LinearGradient(
      colors: [
        Colors.red.withOpacity(0.0),
        Colors.orange.withOpacity(weakAreaOpacity),
        Colors.green.withOpacity(healthyAreaOpacity),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    );
  }

  Future<AnalysisResult?> analyzeFromCamera({
    double? lat,
    double? lon,
    required CameraController cameraController,
  }) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!cameraController.value.isInitialized) {
        _errorMessage = 'Camera not initialized. Please try again.';
        _isAnalyzing = false;
        notifyListeners();
        return null;
      }

      final XFile file = await cameraController.takePicture();
      final Uint8List bytes = await file.readAsBytes();

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _errorMessage = 'Invalid image. Please retake.';
        _isAnalyzing = false;
        notifyListeners();
        return null;
      }

      final img.Image resized = decoded.width > 400
          ? img.copyResize(decoded, width: 400)
          : decoded;

      try {
        _lastPreviewJpgBytes =
            Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      } catch (_) {
        _lastPreviewJpgBytes = null;
      }

      final bool hasLocation = lat != null && lon != null;

      final AnalysisResult result = hasLocation
          ? await _analysisApi
              .analyze(
                lat: lat,
                lon: lon,
                image: resized,
              )
              .timeout(const Duration(seconds: 15))
          : await _analysisApi
              .analyzeVegetationOnly(
                image: resized,
              )
              .timeout(const Duration(seconds: 15));

      _setResult(result);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKeyLastResult, result.toJsonString());
      } catch (_) {
        // Cache failures are non-fatal.
      }

      _isAnalyzing = false;
      notifyListeners();
      return result;
    } on TimeoutException {
      _errorMessage = 'Analysis timed out. Please retry.';
    } catch (_) {
      _errorMessage = 'Analysis failed. Please try again.';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }

    return null;
  }
}

