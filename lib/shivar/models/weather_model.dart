class Weather {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String description;
  final String icon;
  final String city;
  final String country;

  Weather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.icon,
    required this.city,
    required this.country,
  });
}

class Forecast {
  final String date;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String description;
  final String icon;
  final double rainfall;

  Forecast({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.icon,
    required this.rainfall,
  });
}

class FarmingSuggestion {
  final String date;
  final int month;
  final String condition;
  final double temperature;
  final double rainfall;
  final List<String> crops;
  final List<String> activities;
  final List<String> warnings;

  FarmingSuggestion({
    required this.date,
    required this.month,
    required this.condition,
    required this.temperature,
    required this.rainfall,
    required this.crops,
    required this.activities,
    required this.warnings,
  });
}

