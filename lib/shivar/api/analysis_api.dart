import 'dart:async';

import 'package:image/image.dart' as img;

import '../models/analysis_result.dart';
import '../services/weather_service.dart';
import '../services/vegetation_index_service.dart';
import '../services/season_service.dart';

class AnalysisApi {
  final WeatherService _weatherService;
  final VegetationIndexService _vegetationService;
  final SeasonService _seasonService;

  AnalysisApi({
    WeatherService? weatherService,
    VegetationIndexService? vegetationIndexService,
    SeasonService? seasonService,
  })  : _weatherService = weatherService ?? WeatherService(),
        _vegetationService = vegetationIndexService ?? VegetationIndexService(),
        _seasonService = seasonService ?? const SeasonService();

  /// Unified analysis entrypoint shared between 2D and AR modes.
  ///
  /// Steps:
  /// 1. Fetch weather (non-fatal – falls back to vegetation-only on failure)
  /// 2. Perform vegetation index analysis using VARI
  /// 3. Calculate confidence score
  /// 4. Return structured [AnalysisResult]
  Future<AnalysisResult> analyze({
    required double lat,
    required double lon,
    required img.Image image,
  }) async {
    WeatherInfo? weather;
    String? weatherErrorCode;
    String? weatherErrorMessage;

    try {
      weather = await _weatherService.fetchWeatherForLocation(
        lat: lat,
        lon: lon,
      );
    } on WeatherException catch (e) {
      weatherErrorCode = e.code;
      weatherErrorMessage = e.message;
    } on TimeoutException catch (e) {
      weatherErrorCode = 'timeout';
      weatherErrorMessage = e.message;
    } catch (e) {
      weatherErrorCode = 'unknown';
      weatherErrorMessage = e.toString();
    }

    // 2. Detect agricultural season from current date.
    final String season = _seasonService.currentSeason();

    // 3. Run vegetation index analysis (offline VARI approximation).
    final vegetation = await _vegetationService.analyzeImage(
      image,
      weather: weather,
    );

    return AnalysisResult(
      latitude: lat,
      longitude: lon,
      vegetation: vegetation,
      weather: weather,
      timestamp: DateTime.now(),
      season: season,
      fromCache: false,
      weatherErrorCode: weatherErrorCode,
      weatherErrorMessage: weatherErrorMessage,
    );
  }

  /// Vegetation-only analysis path used when GPS is unavailable or
  /// the user has chosen to stay offline. Skips weather API calls
  /// entirely while still computing season and vegetation metrics.
  Future<AnalysisResult> analyzeVegetationOnly({
    required img.Image image,
  }) async {
    final String season = _seasonService.currentSeason();
    final vegetation = await _vegetationService.analyzeImage(image);

    return AnalysisResult(
      latitude: 0.0,
      longitude: 0.0,
      vegetation: vegetation,
      weather: null,
      timestamp: DateTime.now(),
      season: season,
      fromCache: false,
      weatherErrorCode: 'location_unavailable',
      weatherErrorMessage:
          'GPS location unavailable – using offline vegetation analysis.',
    );
  }

  /// Backwards-compatible 2D entrypoint. Prefer [analyze].
  Future<AnalysisResult> analyze2DMode({
    required double lat,
    required double lon,
    required img.Image image,
  }) {
    return analyze(lat: lat, lon: lon, image: image);
  }
}

