import '../models/weather_model.dart';
import 'weather_service.dart';

class WeatherApi {
  static Future<Weather> fetchWeather(String city) async {
    return await WeatherService.fetchWeather(city);
  }

  static Future<Weather> fetchWeatherByLocation(double lat, double lon) async {
    return await WeatherService.fetchWeatherByLocation(lat, lon);
  }

  static Future<List<Forecast>> fetchForecastByLocation(
    double lat,
    double lon,
  ) async {
    return await WeatherService.fetchForecastByLocation(lat, lon);
  }

  static Future<Map<String, dynamic>> fetchFarmingSuggestions(
    double lat,
    double lon,
  ) async {
    return await WeatherService.fetchFarmingSuggestions(lat, lon);
  }
}
