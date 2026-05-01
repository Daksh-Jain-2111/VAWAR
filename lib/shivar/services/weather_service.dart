import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';
import '../models/weather_model.dart';

class WeatherException implements Exception {
  final String code;
  final String message;

  WeatherException(this.code, this.message);

  @override
  String toString() => 'WeatherException($code): $message';
}

class WeatherService {
  static const String _weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Lightweight lat/lon weather for 2D mode (returns WeatherInfo model).
  Future<WeatherInfo> fetchWeatherForLocation({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final uri = Uri.parse(
        '$_weatherBaseUrl?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m'
        '&hourly=temperature_2m,precipitation_probability&forecast_days=7',
      );

      final response = await http.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        throw WeatherException(
          'http_error',
          'Failed to fetch weather (code ${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current =
          data['current'] as Map<String, dynamic>? ?? const <String, dynamic>{};

      final double temperature =
          (current['temperature_2m'] as num?)?.toDouble() ?? 25.0;
      final double humidity =
          (current['relative_humidity_2m'] as num?)?.toDouble() ?? 60.0;
      final double precipitation =
          (current['precipitation'] as num?)?.toDouble() ?? 0.0;
      final double windSpeed =
          (current['wind_speed_10m'] as num?)?.toDouble() ?? 3.0;

      final condition = _deriveCondition(
        temperature: temperature,
        humidity: humidity,
        precipitation: precipitation,
      );

      return WeatherInfo(
        temperatureC: temperature,
        humidityPercent: humidity,
        windSpeedMs: windSpeed,
        condition: condition,
      );
    } on SocketException {
      throw WeatherException('no_internet', 'No internet connection');
    } on TimeoutException {
      throw WeatherException('timeout', 'Weather request timed out');
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('unknown', e.toString());
    }
  }

  String _deriveCondition({
    required double temperature,
    required double humidity,
    required double precipitation,
  }) {
    if (precipitation > 1.0) return 'Rainy';
    if (humidity > 80) return 'Humid';
    if (temperature > 32) return 'Hot';
    if (temperature < 10) return 'Cold';
    return 'Clear';
  }

  // ---------------------------------------------------------------------------
  // Extended weather API used by WeatherApi & advisory flows
  // ---------------------------------------------------------------------------

  static Future<Weather> fetchWeather(String city) async {
    try {
      // Geocode the city to get lat/lon
      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=en&format=json',
      );
      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        throw Exception('Failed to geocode city: $city');
      }

      final geoData = json.decode(geoResponse.body);
      final results = geoData['results'];

      if (results == null || results.isEmpty) {
        throw Exception('City not found: $city');
      }

      final lat = results[0]['latitude'];
      final lon = results[0]['longitude'];
      final cityName = results[0]['name'];
      final country = results[0]['country'];

      // Fetch current weather
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,precipitation,rain,wind_speed_10m,wind_direction_10m,showers,is_day,apparent_temperature,relative_humidity_2m&timezone=auto',
      );
      final response = await http.get(weatherUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        return Weather(
          temperature: current['temperature_2m']?.toDouble() ?? 0.0,
          humidity: current['relative_humidity_2m'] ?? 0,
          windSpeed: current['wind_speed_10m']?.toDouble() ?? 0.0,
          condition: 'Clear',
          description: 'Clear sky',
          icon: '01d',
          city: cityName,
          country: country,
        );
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  static Future<Weather> fetchWeatherByLocation(double lat, double lon) async {
    try {
      // Reverse geocode to get city and country
      final geoUrl = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final geoResponse = await http.get(geoUrl);

      String city = 'Unknown';
      String country = 'Unknown';
      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        city = geoData['city'] ?? geoData['locality'] ?? 'Unknown';
        country = geoData['countryName'] ?? 'Unknown';
      }

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,precipitation,rain,wind_speed_10m,wind_direction_10m,showers,is_day,apparent_temperature,relative_humidity_2m&timezone=auto',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        return Weather(
          temperature: current['temperature_2m']?.toDouble() ?? 0.0,
          humidity: current['relative_humidity_2m'] ?? 0,
          windSpeed: current['wind_speed_10m']?.toDouble() ?? 0.0,
          condition: 'Clear',
          description: 'Clear sky',
          icon: '01d',
          city: city,
          country: country,
        );
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  static Future<List<Forecast>> fetchForecastByLocation(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_min,temperature_2m_max,daylight_duration,apparent_temperature_max,apparent_temperature_min,wind_speed_10m_max,wind_direction_10m_dominant,sunshine_duration,uv_index_max,showers_sum,rain_sum,precipitation_sum,precipitation_hours,precipitation_probability_max&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,apparent_temperature,dew_point_2m,wind_speed_120m,wind_direction_120m,temperature_120m,visibility,soil_temperature_6cm&current=temperature_2m,precipitation,rain,wind_speed_10m,wind_direction_10m,showers,is_day,apparent_temperature,relative_humidity_2m&models=best_match&timezone=auto',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecastList = <Forecast>[];
        final daily = data['daily'] ?? {};

        final dates = daily['time'] ?? [];
        final tempMax = daily['temperature_2m_max'] ?? [];
        final tempMin = daily['temperature_2m_min'] ?? [];
        final precipitation = daily['precipitation_sum'] ?? [];

        for (int i = 0; i < dates.length && i < 7; i++) {
          final date = dates[i];
          final maxTemp = tempMax[i]?.toDouble() ?? 0.0;
          final minTemp = tempMin[i]?.toDouble() ?? 0.0;
          final avgTemp = (maxTemp + minTemp) / 2.0;
          final rainfall = precipitation[i]?.toDouble() ?? 0.0;

          final forecastInfo = Forecast(
            date: date,
            temperature: avgTemp,
            humidity: 0,
            windSpeed: 0.0,
            condition: 'Clear',
            description: 'Clear sky',
            icon: '01d',
            rainfall: rainfall,
          );
          forecastList.add(forecastInfo);
        }
        return forecastList;
      } else {
        throw Exception(
          'Failed to load forecast data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchFarmingSuggestions(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,precipitation,rain,wind_speed_10m,wind_direction_10m,showers,is_day,apparent_temperature,relative_humidity_2m&daily=temperature_2m_min,temperature_2m_max,precipitation_sum,weathercode&timezone=auto',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final daily = data['daily'] ?? {};

        final temp = current['temperature_2m']?.toDouble() ?? 0.0;
        final precipitation = current['precipitation']?.toDouble() ?? 0.0;
        final humidity = current['relative_humidity_2m'] ?? 0;

        final dates = daily['time'] ?? [];
        final tempMin = daily['temperature_2m_min'] ?? [];
        final tempMax = daily['temperature_2m_max'] ?? [];
        final precipSum = daily['precipitation_sum'] ?? [];
        final weatherCodes = daily['weathercode'] ?? [];

        // Build 7-day forecast
        final forecastList = <Forecast>[];
        for (int i = 0; i < dates.length && i < 7; i++) {
          final date = dates[i];
          final maxTemp = tempMax[i]?.toDouble() ?? 0.0;
          final minTemp = tempMin[i]?.toDouble() ?? 0.0;
          final avgTemp = (maxTemp + minTemp) / 2.0;
          final rainfall = precipSum[i]?.toDouble() ?? 0.0;
          final weatherCode = weatherCodes[i] ?? 0;

          // Map weather code to condition (simplified mapping)
          String condition = 'Clear';
          String description = 'Clear sky';
          String icon = '01d';

          if (weatherCode == 0) {
            condition = 'Clear';
            description = 'Clear sky';
            icon = '01d';
          } else if (weatherCode >= 1 && weatherCode <= 3) {
            condition = 'Cloudy';
            description = 'Partly cloudy';
            icon = '02d';
          } else if (weatherCode >= 45 && weatherCode <= 48) {
            condition = 'Fog';
            description = 'Foggy';
            icon = '50d';
          } else if (weatherCode >= 51 && weatherCode <= 55) {
            condition = 'Rain';
            description = 'Light rain';
            icon = '10d';
          } else if (weatherCode >= 61 && weatherCode <= 65) {
            condition = 'Rain';
            description = 'Rain';
            icon = '10d';
          } else if (weatherCode >= 71 && weatherCode <= 75) {
            condition = 'Snow';
            description = 'Snow';
            icon = '13d';
          } else if (weatherCode >= 80 && weatherCode <= 82) {
            condition = 'Rain';
            description = 'Rain showers';
            icon = '09d';
          }

          final forecastInfo = Forecast(
            date: date,
            temperature: avgTemp,
            humidity: 0, // Not available in daily data
            windSpeed: 0.0, // Not available in daily data
            condition: condition,
            description: description,
            icon: icon,
            rainfall: rainfall,
          );
          forecastList.add(forecastInfo);
        }

        // Generate farming suggestions for each day
        final farmingSuggestions = <FarmingSuggestion>[];
        for (int i = 0; i < forecastList.length; i++) {
          final forecast = forecastList[i];
          final avgTemp = forecast.temperature;
          final totalRain = forecast.rainfall;

          List<String> crops = [];
          List<String> activities = [];
          List<String> warnings = [];

          if (avgTemp > 25) {
            crops.addAll(['Tomatoes', 'Peppers', 'Eggplants']);
            activities.add('Water plants early in the morning');
            if (humidity > 70) {
              warnings.add('High humidity may cause fungal diseases');
            }
          } else if (avgTemp > 15) {
            crops.addAll(['Lettuce', 'Carrots', 'Broccoli']);
            activities.add('Prepare soil for planting');
          } else {
            crops.addAll(['Wheat', 'Barley']);
            activities.add('Protect crops from frost');
            warnings.add('Cold weather may affect growth');
          }

          if (totalRain > 10) {
            activities.add('Ensure proper drainage to avoid waterlogging');
            warnings.add('Heavy rainfall may lead to soil erosion');
          } else if (totalRain < 5) {
            activities.add('Irrigate crops if necessary');
            warnings.add('Low rainfall may require additional watering');
          }

          final suggestion = FarmingSuggestion(
            date: forecast.date,
            month: DateTime.parse(forecast.date).month,
            condition: forecast.condition,
            temperature: forecast.temperature,
            rainfall: forecast.rainfall,
            crops: crops,
            activities: activities,
            warnings: warnings,
          );
          farmingSuggestions.add(suggestion);
        }

        return {
          'forecast': forecastList,
          'farming_suggestions': farmingSuggestions,
        };
      } else {
        throw Exception('Failed to load weather data for suggestions');
      }
    } catch (e) {
      throw Exception('Error fetching farming suggestions: $e');
    }
  }
}

