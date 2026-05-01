import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_model.dart';
import '../services/weather_api.dart';
import '../services/weather_advisory_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _locationController = TextEditingController();
  Weather? _weather;
  List<Forecast>? _forecast;
  AdvisoryResult? _advisoryResult;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentLocation = 'Dhule, Unknown State, India';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _fetchWeatherByLocation();
    }
  }

  Future<void> _handleLiveLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
              'Location services are disabled. Please enable location services to use live location.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is permanently denied. Please enable location permission in app settings to use live location.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _fetchWeatherByLocation();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to use live location'),
        ),
      );
    }
  }

  Future<void> _fetchWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 30),
      );

      final weather = await WeatherApi.fetchWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      final forecast = await WeatherApi.fetchForecastByLocation(
        position.latitude,
        position.longitude,
      );

      // Reverse geocode to get location name
      final geoUrl = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en',
      );
      final geoResponse = await http.get(geoUrl);
      String locationName = 'Unknown Location';
      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        locationName =
            '${geoData['city'] ?? geoData['locality'] ?? 'Unknown'}, ${geoData['countryName'] ?? 'Unknown'}';
      }

      final weatherInput = WeatherInput(
        temperatureC: weather.temperature,
        humidity: weather.humidity.toDouble(),
        windSpeedKmph: weather.windSpeed,
        rainMm: 0.0,
        rainProbability: 0.0,
        thunderstorm: false,
        cyclone: false,
        flood: false,
        fog: false,
        dryDaysAhead: 3,
        uvIndex: 5.0,
      );

      final advisoryService = WeatherAdvisoryService();
      final advisoryResult = advisoryService.generateAdvisory(weatherInput);

      setState(() {
        _weather = weather;
        _forecast = forecast;
        _advisoryResult = advisoryResult;
        _currentLocation = locationName;
        _locationController.text = locationName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get weather for current location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherByCity(String city) async {
    if (city.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await WeatherApi.fetchWeather(city);

      // Geocode the city to get coordinates for forecast
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

      final forecast = await WeatherApi.fetchForecastByLocation(lat, lon);

      final weatherInput = WeatherInput(
        temperatureC: weather.temperature,
        humidity: weather.humidity.toDouble(),
        windSpeedKmph: weather.windSpeed,
        rainMm: 0.0,
        rainProbability: 0.0,
        thunderstorm: false,
        cyclone: false,
        flood: false,
        fog: false,
        dryDaysAhead: 3,
        uvIndex: 5.0,
      );

      final advisoryService = WeatherAdvisoryService();
      final advisoryResult = advisoryService.generateAdvisory(weatherInput);

      setState(() {
        _weather = weather;
        _forecast = forecast;
        _advisoryResult = advisoryResult;
        _currentLocation = '${weather.city}, ${weather.country}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get weather for $city: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {},
                    ),
                    const Text(
                      'Weather Forecast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.refresh, color: Colors.black),
                      ),
                      onPressed: _isLoading ? null : _fetchWeatherByLocation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location Input Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Enter city name or use current location',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () =>
                                _fetchWeatherByCity(_locationController.text),
                          ),
                        ),
                        onSubmitted: _fetchWeatherByCity,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Colors.black54,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Current: $_currentLocation',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _handleLiveLocation,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('Use Live Location'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (_weather != null) ...[
                  // Current Weather Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_weather!.temperature.round()}°C',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _weather!.description,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Feels like ${(_weather!.temperature + 6).round()}°C',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildWeatherMetric(
                                    'Humidity',
                                    '${_weather!.humidity}%',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildWeatherMetric(
                                    'Wind',
                                    '${_weather!.windSpeed.round()} km/h',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildWeatherMetric('Visibility', '8 km'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.wb_sunny,
                          size: 80,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Both sections visible simultaneously
                  const SizedBox(height: 24),

                  // 7-Day Forecast List
                  const Text(
                    '7-Day Forecast',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_forecast != null && _forecast!.isNotEmpty)
                    ..._forecast!.take(7).map((forecast) {
                      final date = DateTime.parse(forecast.date);
                      final dayName = _getDayName(date.weekday);
                      final dateStr = '${date.month}/${date.day}';
                      return _buildForecastCard(
                        dayName,
                        dateStr,
                        _getWeatherIcon(forecast.condition),
                        '${forecast.rainfall.toStringAsFixed(1)}mm',
                        '${forecast.temperature.round()}°',
                        '${(forecast.temperature - 6).round()}°',
                        forecast.description,
                      );
                    })
                  else
                    const Text('No forecast data available'),

                  const SizedBox(height: 32),

                  // Farm Advisory Section (shown beside/after forecast)
                  const Text(
                    'Farm Advisory',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_advisoryResult != null) ...[
                    if (_advisoryResult!.mustDo100.isNotEmpty)
                      _buildAdvisoryCard(
                        Icons.warning,
                        'Critical Actions Required',
                        _advisoryResult!.mustDo100.join('\n• '),
                        'High Priority',
                        Colors.red,
                      ),
                    if (_advisoryResult!.canDo50.isNotEmpty)
                      _buildAdvisoryCard(
                        Icons.info,
                        'Recommended Actions',
                        _advisoryResult!.canDo50.join('\n• '),
                        'Medium Priority',
                        Colors.orange,
                      ),
                    if (_advisoryResult!.canDo20.isNotEmpty)
                      _buildAdvisoryCard(
                        Icons.check_circle,
                        'Optional Actions',
                        _advisoryResult!.canDo20.join('\n• '),
                        'Low Priority',
                        Colors.green,
                      ),
                  ] else ...[
                    _buildAdvisoryCard(
                      Icons.water_drop,
                      'Irrigation',
                      'Light rain expected. Reduce irrigation by 30% today.',
                      'High Priority',
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildAdvisoryCard(
                      Icons.bug_report,
                      'Pest Management',
                      'High humidity may increase aphid activity. Monitor crops closely.',
                      'Medium Priority',
                      Colors.yellow,
                    ),
                    const SizedBox(height: 12),
                    _buildAdvisoryCard(
                      Icons.agriculture,
                      'Harvesting',
                      'Perfect weather for harvesting this weekend. Plan accordingly.',
                      'Low Priority',
                      Colors.green,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Weather Alert Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No Weather Alerts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Current weather conditions are favorable for farming activities.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloud':
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      default:
        return Icons.wb_sunny;
    }
  }

  Widget _buildWeatherMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(
    String day,
    String date,
    IconData icon,
    String precipitation,
    String high,
    String low,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 32, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.grain, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    precipitation,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    high,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    low,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(description, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(
    IconData icon,
    String title,
    String description,
    String priority,
    Color priorityColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: priorityColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 12,
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
