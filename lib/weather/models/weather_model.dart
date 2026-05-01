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

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: json['main']['temp']?.toDouble() ?? 0.0,
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: json['wind']['speed']?.toDouble() ?? 0.0,
      condition: json['weather'][0]['main'] ?? '',
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      city: json['name'] ?? '',
      country: json['sys']['country'] ?? '',
    );
  }

  String? get fluyttcondition => null;
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

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      date: json['date'] ?? '',
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity'] ?? 0,
      windSpeed: json['wind_speed']?.toDouble() ?? 0.0,
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      rainfall: json['rainfall']?.toDouble() ?? 0.0,
    );
  }
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

  factory FarmingSuggestion.fromJson(Map<String, dynamic> json) {
    return FarmingSuggestion(
      date: json['date'] ?? '',
      month: json['month'] ?? 1,
      condition: json['condition'] ?? '',
      temperature: json['temperature']?.toDouble() ?? 0.0,
      rainfall: json['rainfall']?.toDouble() ?? 0.0,
      crops: List<String>.from(json['crops'] ?? []),
      activities: List<String>.from(json['activities'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}
