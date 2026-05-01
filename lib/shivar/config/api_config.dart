class ApiConfig {
  // Update with your backend URL
  static const String baseUrl = 'http://10.250.243.40:8001'; // Development
  // static const String baseUrl = 'https://api.vawar.com'; // Production

  static const String ndviEndpoint = '/api/ndvi';
  static const String weatherEndpoint = '/api/weather';
  static const String cropHealthEndpoint = '/api/crop-health';
  static const String advisoryEndpoint = '/api/advisory';
  static const String fullReportEndpoint = '/api/full-report';

  static String getNdviUrl() => '$baseUrl$ndviEndpoint';
  static String getWeatherUrl() => '$baseUrl$weatherEndpoint';
  static String getCropHealthUrl() => '$baseUrl$cropHealthEndpoint';
  static String getAdvisoryUrl() => '$baseUrl$advisoryEndpoint';
  static String getFullReportUrl() => '$baseUrl$fullReportEndpoint';
  static String getDiseaseDetectionUrl() => '$baseUrl/api/disease-detection';
  static String getPestRiskUrl() => '$baseUrl/api/pest-risk';
  static String getHealthUrl() => '$baseUrl/health';
}
