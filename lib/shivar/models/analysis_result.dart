import 'dart:convert';

class WeatherInfo {
  final double temperatureC;
  final double humidityPercent;
  final double windSpeedMs;
  final String condition;

  const WeatherInfo({
    required this.temperatureC,
    required this.humidityPercent,
    required this.windSpeedMs,
    required this.condition,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 25.0,
      humidityPercent: (json['humidityPercent'] as num?)?.toDouble() ?? 60.0,
      windSpeedMs: (json['windSpeedMs'] as num?)?.toDouble() ?? 3.0,
      condition: (json['condition'] as String?) ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureC': temperatureC,
      'humidityPercent': humidityPercent,
      'windSpeedMs': windSpeedMs,
      'condition': condition,
    };
  }
}

class VegetationAnalysis {
  /// Normalized 0–1 vegetation index score derived from VARI.
  final double vegetationScore;

  /// Overall confidence in the vegetationScore (0–1).
  final double confidence;

  /// Estimated fraction of vegetation pixels in the frame (0–1).
  final double vegetationCoverageRatio;

  /// Lighting quality score (0–1).
  final double lightingQuality;

  /// Weather consistency score (0–1) – how realistic the weather is
  /// relative to typical vegetation conditions.
  final double weatherConsistency;

  const VegetationAnalysis({
    required this.vegetationScore,
    required this.confidence,
    required this.vegetationCoverageRatio,
    required this.lightingQuality,
    required this.weatherConsistency,
  });

  factory VegetationAnalysis.fromJson(Map<String, dynamic> json) {
    return VegetationAnalysis(
      vegetationScore: (json['vegetationScore'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      vegetationCoverageRatio:
          (json['vegetationCoverageRatio'] as num?)?.toDouble() ?? 0.0,
      lightingQuality: (json['lightingQuality'] as num?)?.toDouble() ?? 0.0,
      weatherConsistency:
          (json['weatherConsistency'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vegetationScore': vegetationScore,
      'confidence': confidence,
      'vegetationCoverageRatio': vegetationCoverageRatio,
      'lightingQuality': lightingQuality,
      'weatherConsistency': weatherConsistency,
    };
  }
}

class AnalysisResult {
  final double latitude;
  final double longitude;
  final VegetationAnalysis vegetation;
  final WeatherInfo? weather;
  final DateTime timestamp;

  /// Detected agricultural season label (e.g. KHARIF / RABI / ZAID).
  final String season;

  /// True when this result was loaded from local cache.
  final bool fromCache;

  /// Optional code & message describing why weather was unavailable.
  final String? weatherErrorCode;
  final String? weatherErrorMessage;

  const AnalysisResult({
    required this.latitude,
    required this.longitude,
    required this.vegetation,
    required this.timestamp,
    required this.season,
    this.weather,
    this.fromCache = false,
    this.weatherErrorCode,
    this.weatherErrorMessage,
  });

  double get vegetationPercent => (vegetation.vegetationScore * 100).clamp(0, 100);

  double get confidencePercent => (vegetation.confidence * 100).clamp(0, 100);

  String get healthLabel {
    final percent = vegetationPercent;
    if (percent >= 70) return 'Healthy';
    if (percent >= 40) return 'Moderate';
    return 'Stressed';
  }

  String get confidenceLabel {
    final p = confidencePercent;
    if (p >= 80) return 'High';
    if (p >= 50) return 'Medium';
    return 'Low';
  }

  bool get hasWeather => weather != null;

  AnalysisResult copyWith({
    bool? fromCache,
    String? season,
  }) {
    return AnalysisResult(
      latitude: latitude,
      longitude: longitude,
      vegetation: vegetation,
      weather: weather,
      timestamp: timestamp,
      season: season ?? this.season,
      fromCache: fromCache ?? this.fromCache,
      weatherErrorCode: weatherErrorCode,
      weatherErrorMessage: weatherErrorMessage,
    );
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      vegetation: VegetationAnalysis.fromJson(
        json['vegetation'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      weather: json['weather'] != null
          ? WeatherInfo.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      season: (json['season'] as String?) ?? 'UNKNOWN',
      fromCache: json['fromCache'] as bool? ?? false,
      weatherErrorCode: json['weatherErrorCode'] as String?,
      weatherErrorMessage: json['weatherErrorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'vegetation': vegetation.toJson(),
      'weather': weather?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'season': season,
      'fromCache': fromCache,
      'weatherErrorCode': weatherErrorCode,
      'weatherErrorMessage': weatherErrorMessage,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static AnalysisResult? fromJsonString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return AnalysisResult.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

