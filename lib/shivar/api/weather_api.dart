import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherApi {
  static Future<Weather> fetchWeather(String city) async {
    return WeatherService.fetchWeather(city);
  }


  static Future<Weather> fetchWeatherByLocation(double lat, double lon) async {
    return WeatherService.fetchWeatherByLocation(lat, lon);
  }

  static Future<List<Forecast>> fetchForecastByLocation(
    double lat,
    double lon,
  ) async {
    return WeatherService.fetchForecastByLocation(lat, lon);
  }

  static Future<Map<String, dynamic>> fetchFarmingSuggestions(
    double lat,
    double lon,
  ) async {
    return WeatherService.fetchFarmingSuggestions(lat, lon);
  }
}

