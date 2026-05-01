import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Lightweight location service that fetches GPS coordinates once
/// and caches the result for reuse across the app.
///
/// It never touches UI concerns and must NOT be called from build methods.
class LocationService {
  LocationService._internal();

  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;

  Position? _cachedPosition;
  DateTime? _lastFetchTime;

  // Cache duration so we don't spam the GPS hardware.
  static const Duration _cacheValidity = Duration(minutes: 5);

  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Return cached position when still fresh.
      if (_cachedPosition != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
        return LocationResult.success(_cachedPosition!);
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          status: LocationStatus.servicesDisabled,
          errorMessage: 'Location services are disabled.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
          status: LocationStatus.permissionDenied,
          errorMessage: 'Location permission denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationStatus.permissionDeniedForever,
          errorMessage:
              'Location permissions are permanently denied. Please enable them in system settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout);

      _cachedPosition = position;
      _lastFetchTime = DateTime.now();

      return LocationResult.success(position);
    } on TimeoutException {
      return const LocationResult(
        status: LocationStatus.timeout,
        errorMessage: 'Timed out while fetching GPS location.',
      );
    } catch (e) {
      return LocationResult(
        status: LocationStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }
}

enum LocationStatus {
  success,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  failure,
}

class LocationResult {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  const LocationResult({
    required this.status,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  factory LocationResult.success(Position position) {
    return LocationResult(
      status: LocationStatus.success,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  bool get isSuccess => status == LocationStatus.success;
}

