import 'dart:math';

import 'package:image/image.dart' as img;

import '../models/analysis_result.dart';

class VegetationIndexService {
  /// Analyze the given RGB image using VARI:
  /// VARI = (G - R) / (G + R - B)
  ///
  /// Returns [VegetationAnalysis] with vegetationScore and confidence in 0–1.
  Future<VegetationAnalysis> analyzeImage(
    img.Image image, {
    WeatherInfo? weather,
  }) async {
    // For typical 400px-wide images this is fast enough to run on the main
    // isolate, but we keep the API async for easy offloading later.
    return _analyze(image, weather: weather);
  }

  VegetationAnalysis _analyze(
    img.Image image, {
    WeatherInfo? weather,
  }) {
    final width = image.width;
    final height = image.height;
    if (width == 0 || height == 0) {
      return const VegetationAnalysis(
        vegetationScore: 0.0,
        confidence: 0.0,
        vegetationCoverageRatio: 0.0,
        lightingQuality: 0.0,
        weatherConsistency: 0.0,
      );
    }

    // Optional subsampling for performance on very large frames.
    final int step = max(1, (width * height / 160000).round());

    double sumVari = 0.0;
    int variCount = 0;

    int vegetationPixels = 0;
    int totalPixels = 0;

    double brightnessSum = 0.0;
    double brightnessMin = 1.0;
    double brightnessMax = 0.0;

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final double denom = g + r - b;
        if (denom.abs() < 1e-3) {
          totalPixels++;
          continue;
        }

        final vari = (g - r) / denom;
        // Track only reasonable vegetation-like pixels
        if (!vari.isNaN && !vari.isInfinite) {
          sumVari += vari;
          variCount++;
        }

        // Simple vegetation heuristic: green-dominant pixels
        final bool isVegetation = g > r && g > b && g > 30;
        if (isVegetation) {
          vegetationPixels++;
        }

        // Approximate brightness using perceived luminance
        final double brightness = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
        brightnessSum += brightness;
        brightnessMin = min(brightnessMin, brightness);
        brightnessMax = max(brightnessMax, brightness);

        totalPixels++;
      }
    }

    if (totalPixels == 0 || variCount == 0) {
      return const VegetationAnalysis(
        vegetationScore: 0.0,
        confidence: 0.0,
        vegetationCoverageRatio: 0.0,
        lightingQuality: 0.0,
        weatherConsistency: 0.0,
      );
    }

    final avgVari = sumVari / variCount;
    // Map VARI (typically around -1..1) into 0–1.
    final vegetationScore = ((avgVari + 1.0) / 2.0).clamp(0.0, 1.0);

    final coverageRatio = (vegetationPixels / totalPixels).clamp(0.0, 1.0);

    final avgBrightness = (brightnessSum / totalPixels).clamp(0.0, 1.0);
    final brightnessRange = (brightnessMax - brightnessMin).clamp(0.0, 1.0);

    // Lighting quality: prefer mid-range brightness and some contrast.
    final double brightnessScore = 1.0 - (2.0 * (avgBrightness - 0.5).abs()).clamp(0.0, 1.0);
    final double contrastScore = (brightnessRange * 1.2).clamp(0.0, 1.0);
    final double lightingQuality = ((brightnessScore + contrastScore) / 2.0).clamp(0.0, 1.0);

    double weatherConsistency = 0.5;
    if (weather != null) {
      final temp = weather.temperatureC;
      final humidity = weather.humidityPercent;

      // Prefer moderate temperatures and reasonable humidity for typical crops.
      double tempScore;
      if (temp < 5 || temp > 45) {
        tempScore = 0.2;
      } else if (temp >= 20 && temp <= 32) {
        tempScore = 1.0;
      } else {
        tempScore = 0.6;
      }

      double humidityScore;
      if (humidity < 20 || humidity > 95) {
        humidityScore = 0.2;
      } else if (humidity >= 40 && humidity <= 80) {
        humidityScore = 1.0;
      } else {
        humidityScore = 0.6;
      }

      weatherConsistency = ((tempScore + humidityScore) / 2.0).clamp(0.0, 1.0);
    }

    // Combine all factors into a global confidence.
    // Give more weight to vegetation coverage & lighting.
    final confidence = (0.45 * coverageRatio +
            0.35 * lightingQuality +
            0.20 * weatherConsistency)
        .clamp(0.0, 1.0);

    return VegetationAnalysis(
      vegetationScore: vegetationScore,
      confidence: confidence,
      vegetationCoverageRatio: coverageRatio,
      lightingQuality: lightingQuality,
      weatherConsistency: weatherConsistency,
    );
  }
}

