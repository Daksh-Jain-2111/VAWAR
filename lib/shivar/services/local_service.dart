import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'tflite_service.dart';

class LocalService {
  // Open-Meteo API for weather (no key required)
  static const String _weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Weather caching
  final Map<String, Map<String, dynamic>> _weatherCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  TFLiteService? _tfliteService;
  CameraController? _cameraController;
  bool _isInitialized = false;

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    // Create cache key from coordinates (rounded to reduce cache misses)
    final cacheKey = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    // Check cache first
    if (_weatherCache.containsKey(cacheKey) &&
        _cacheTimestamps.containsKey(cacheKey) &&
        DateTime.now().difference(_cacheTimestamps[cacheKey]!) < _cacheDuration) {
      return _weatherCache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
        '$_weatherBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m&hourly=temperature_2m,precipitation_probability&forecast_days=7',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = {
          'current': {
            'temperature': data['current']['temperature_2m'],
            'humidity': data['current']['relative_humidity_2m'],
            'precipitation': data['current']['precipitation'],
            'wind_speed': data['current']['wind_speed_10m'],
            'wind_direction': data['current']['wind_direction_10m'],
          },
          'hourly': {
            'temperature': data['hourly']['temperature_2m'],
            'precipitation_probability': data['hourly']['precipitation_probability'],
          },
        };

        // Cache the result
        _weatherCache[cacheKey] = weatherData;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return weatherData;
      } else {
        throw Exception('Failed to fetch weather');
      }
    } catch (e) {
      // Fallback mock data
      final mockData = {
        'current': {
          'temperature': 28.0,
          'humidity': 65.0,
          'precipitation': 0.0,
          'wind_speed': 5.0,
          'wind_direction': 180.0,
        },
        'hourly': {
          'temperature': List.generate(24, (i) => 25.0 + (i % 6) * 2.0),
          'precipitation_probability': List.generate(24, (i) => (i % 8) * 10),
        },
      };

      // Cache mock data too to avoid repeated fallbacks
      _weatherCache[cacheKey] = mockData;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return mockData;
    }
  }

  // RGB-based NDVI proxy (ExG - Excess Green)
  double calculateNDVIProxy(int r, int g, int b) {
    // ExG = 2*G - R - B
    double exg = 2.0 * g - r - b;
    // Normalize to 0-1 range (rough approximation)
    double normalized = (exg + 255) / (2 * 255);
    return normalized.clamp(0.0, 1.0);
  }

  // Mock NDVI data when no image available
  Map<String, dynamic> getMockNDVI(double lat, double lon) {
    // Simulate NDVI based on location (rough approximation)
    double baseNDVI = 0.5 + (lat % 10) / 20.0; // Varies by latitude
    return {
      'ndvi_value': baseNDVI.clamp(0.1, 0.9),
      'health_status': baseNDVI > 0.6 ? 'Good' : baseNDVI > 0.4 ? 'Moderate' : 'Poor',
    };
  }

  // Irrigation planning logic
  Map<String, dynamic> calculateIrrigationPlan(
    String cropType,
    Map<String, dynamic> weather,
    double ndvi,
    double fieldSize,
  ) {
    // Rule-based irrigation planning
    double dailyWaterNeed = _getCropWaterNeed(cropType);
    double temperature = weather['current']['temperature'];
    double humidity = weather['current']['humidity'];
    double precipitation = weather['current']['precipitation'];

    // Adjust for weather conditions
    if (temperature > 30) dailyWaterNeed *= 1.2;
    if (humidity < 40) dailyWaterNeed *= 1.1;
    if (precipitation > 5) dailyWaterNeed *= 0.7;

    // Adjust for NDVI (health indicator)
    if (ndvi < 0.4) dailyWaterNeed *= 1.3; // Stressed plants need more water

    // Calculate for field size (assuming mm/day)
    double totalWaterMm = dailyWaterNeed * fieldSize;

    // Days until next irrigation
    int daysUntilIrrigation = (totalWaterMm / 10).round().clamp(1, 7);

    return {
      'daily_water_need_mm': dailyWaterNeed,
      'total_water_mm': totalWaterMm,
      'days_until_irrigation': daysUntilIrrigation,
      'recommendation': _getIrrigationRecommendation(daysUntilIrrigation, cropType),
    };
  }

  double _getCropWaterNeed(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'rice':
        return 8.0;
      case 'wheat':
        return 4.5;
      case 'maize':
        return 5.0;
      case 'cotton':
        return 6.0;
      default:
        return 5.0; // Default
    }
  }

  String _getIrrigationRecommendation(int days, String cropType) {
    if (days <= 1) {
      return 'Irrigate immediately - $cropType needs water';
    } else if (days <= 3) {
      return 'Irrigate in $days days';
    } else {
      return 'Irrigation not needed for $days days';
    }
  }

  // Get weather forecast from existing fetchWeather data
  Future<List<Map<String, dynamic>>> getWeatherForecast(double lat, double lon) async {
    try {
      final weatherData = await fetchWeather(lat, lon);
      final hourly = weatherData['hourly'] as Map<String, dynamic>;

      final temperatures = hourly['temperature'] as List<dynamic>;
      final precipitations = hourly['precipitation_probability'] as List<dynamic>;

      List<Map<String, dynamic>> forecast = [];

      // Create 7-day forecast (assuming 24 hours per day from API)
      for (int day = 0; day < 7; day++) {
        int startIndex = day * 24;
        int endIndex = startIndex + 24;

        if (startIndex >= temperatures.length) break;

        // Calculate daily averages
        double avgTemp = 0.0;
        double maxPrecip = 0.0;

        int count = 0;
        for (int i = startIndex; i < endIndex && i < temperatures.length; i++) {
          avgTemp += temperatures[i] as double;
          maxPrecip = maxPrecip > (precipitations[i] as int) ? maxPrecip : (precipitations[i] as int).toDouble();
          count++;
        }

        if (count > 0) {
          avgTemp /= count;
        }

        forecast.add({
          'day': day,
          'date': DateTime.now().add(Duration(days: day)).toString().split(' ')[0],
          'temperature': avgTemp,
          'precipitation_probability': maxPrecip,
          'condition': maxPrecip > 50 ? 'Rainy' : maxPrecip > 20 ? 'Partly Cloudy' : 'Sunny',
        });
      }

      return forecast;
    } catch (e) {
      // Fallback forecast
      return List.generate(7, (day) => {
        'day': day,
        'date': DateTime.now().add(Duration(days: day)).toString().split(' ')[0],
        'temperature': 25.0 + (day % 3) * 2.0,
        'precipitation_probability': (day % 4) * 15.0,
        'condition': day % 2 == 0 ? 'Sunny' : 'Cloudy',
      });
    }
  }

  // Advisory based on weather, NDVI, and crop
  Map<String, dynamic> getAdvisory(
    double lat,
    double lon,
    String cropType,
    double fieldSize,
    String season,
  ) {
    // Mock advisory logic
    List<String> advisories = [];

    // Weather-based
    // (Assuming weather is fetched separately)

    // Season-based
    if (season.toLowerCase() == 'kharif') {
      advisories.add('Monitor for monsoon-related diseases');
    } else if (season.toLowerCase() == 'rabi') {
      advisories.add('Prepare for winter crop protection');
    }

    // Crop-specific
    if (cropType.toLowerCase() == 'rice') {
      advisories.add('Check for blast disease in humid conditions');
    }

    return {
      'advisories': advisories,
      'risk_level': advisories.length > 2 ? 'High' : advisories.length > 0 ? 'Medium' : 'Low',
    };
  }
}
