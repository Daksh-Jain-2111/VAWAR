import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/themed_card.dart';
import '../widgets/themed_button.dart';
import '../services/api_service.dart';
import '../utils/app_error_handler.dart';
import '../utils/arcore_check.dart';
import '../utils/season_detector.dart';
import '../theme/app_theme.dart';

class PreScanForm extends StatefulWidget {
  const PreScanForm({super.key});

  @override
  State<PreScanForm> createState() => _PreScanFormState();
}

class _PreScanFormState extends State<PreScanForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _arcoreSupported = false;
  String _arcoreStatusMessage = 'Checking AR support...';
  Position? _position;
  String? _cropType;
  String _fieldSize = 'Medium';
  String _season = '';

  final List<String> _cropTypes = [
    'Rice',
    'Wheat',
    'Corn',
    'Soybean',
    'Cotton',
    'Sugarcane',
    'Potato',
    'Tomato',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    setState(() => _isLoading = true);

    try {
      // Check camera permission only (location is lazy-loaded)
      final cameraStatus = await Permission.camera.request();

      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
      }

      // Set default season (location-based season will be set when location is fetched)
      _season = SeasonDetector.getCurrentSeason();

      // Check ARCore support with detailed status
      final arcoreStatus = await ARCoreCheck.getDetailedStatus();
      _arcoreSupported = arcoreStatus.canUseAR;
      _arcoreStatusMessage = arcoreStatus.userMessage;
    } catch (e, st) {
      if (mounted) {
        AppErrorHandler.handle(
          e,
          stackTrace: st,
          context: context,
          userMessage: 'Failed to initialize setup. Please try again.',
          logLabel: 'PreScan.initializeForm',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      // Check if location service is enabled to avoid errors and NPE from plugins
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location service is disabled. Enable it in device settings for accurate location.',
              ),
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      _position = await Geolocator.getCurrentPosition();
      _season = SeasonDetector.getSeasonForLocation(_position!.latitude);
      setState(() {});
    } catch (e, st) {
      if (mounted) {
        AppErrorHandler.handle(
          e,
          stackTrace: st,
          context: context,
          userMessage: 'Error getting location. Please try again.',
          logLabel: 'PreScan.getCurrentLocation',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleStartScanning() {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be detected'),
        ),
      );
      return;
    }

    final formData = {
      'location': {
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
      },
      'address': _addressController.text,
      'cropType': _cropType,
      'fieldSize': _fieldSize,
      'season': _season,
    };

    // Navigate to AR mode selection or 2D fallback
    if (_arcoreSupported) {
      context.push('/ar-mode-selection', extra: formData);
    } else {
      // AR not supported -> replace with 2D mode to avoid stacking setup screens.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_arcoreStatusMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      GoRouter.of(context).pushReplacement('/mode-2d', extra: formData);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShivAR Setup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ThemedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Farm Location (Optional)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Location improves weather and NDVI accuracy. App works without it.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Farm Address',
                              hintText: 'Enter farm address or leave blank',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _position != null
                                      ? 'Location: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                      : 'Location: Not detected (optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _position != null
                                        ? AppTheme.success
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _getCurrentLocation,
                                child: const Text('Get Location'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ThemedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crop Type (Optional)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _cropType,
                            decoration: const InputDecoration(
                              labelText: 'Select crop type',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Select crop type...'),
                              ),
                              ..._cropTypes.map(
                                (crop) => DropdownMenuItem(
                                  value: crop,
                                  child: Text(crop),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _cropType = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    ThemedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Field Size',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _fieldSize,
                            decoration: const InputDecoration(
                              labelText: 'Select field size',
                            ),
                            items: ['Small', 'Medium', 'Large']
                                .map(
                                  (size) => DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _fieldSize = value!);
                            },
                          ),
                        ],
                      ),
                    ),
                    ThemedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Season',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _season,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Auto-detected',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ARCore Status Indicator
                    if (!_arcoreSupported && !_isLoading)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _arcoreStatusMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ThemedButton(
                        title: _arcoreSupported
                            ? 'Start Scanning (AR)'
                            : 'Start Scanning (2D Mode)',
                        onPressed: _handleStartScanning,
                        variant: ButtonVariant.primary,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
