import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart'
    show ArCoreView, ArCoreController, ArCoreNode, ArCoreMaterial, ArCoreSphere;
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math_64.dart' as vector;
import '../api/analysis_api.dart';
import '../models/analysis_result.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_error_handler.dart';
import '../utils/arcore_check.dart';

class ARModeScreen extends StatefulWidget {
  final Map<String, dynamic>? formData;

  const ARModeScreen({super.key, this.formData});

  @override
  State<ARModeScreen> createState() => _ARModeScreenState();
}

class _ARModeScreenState extends State<ARModeScreen> {
  ArCoreController? _arCoreController;

  bool _isLoading = true;
  bool _arcoreSupported = false;

  AnalysisResult? _analysisResult;
  final AnalysisApi _analysisApi = AnalysisApi();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Defer heavy initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeARMode();
    });
  }

  void _setupAnimations() {
    // Removed continuous animations to limit AR load
    // Only static nodes for performance
  }

  Future<void> _initializeARMode() async {
    try {
      _arcoreSupported = await ARCoreCheck.isARCoreSupported();

      if (!_arcoreSupported) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // AR not supported -> replace with 2D mode
          GoRouter.of(context)
              .pushReplacement('/mode-2d', extra: widget.formData);
        }
        return;
      }

      // Prefer a single live GPS fetch via LocationService; fall back to
      // pre-scan form location only when necessary.
      double? lat;
      double? lon;

      final liveLocation = await LocationService.instance.getCurrentLocation();
      if (liveLocation.isSuccess) {
        lat = liveLocation.latitude;
        lon = liveLocation.longitude;
      }

      final locationFromForm = widget.formData != null
          ? widget.formData!['location'] as Map<String, dynamic>?
          : null;
      if ((lat == null || lon == null) && locationFromForm != null) {
        lat = (locationFromForm['latitude'] as num?)?.toDouble();
        lon = (locationFromForm['longitude'] as num?)?.toDouble();
      }

      // Synthesize a tiny placeholder image – AR uses live camera for 3D
      // but the unified AnalysisApi still expects an RGB frame to compute
      // vegetation metrics. Use a small solid-color image with the
      // current image package API.
      final placeholder = img.Image(width: 4, height: 4);
      img.fill(
        placeholder,
        color: img.ColorUint8.rgba(60, 160, 60, 255),
      );

      AnalysisResult analysis;
      if (lat != null && lon != null) {
        analysis = await _analysisApi.analyze(
          lat: lat,
          lon: lon,
          image: placeholder,
        );
      } else {
        analysis = await _analysisApi.analyzeVegetationOnly(
          image: placeholder,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GPS unavailable. Showing offline vegetation overlays.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _analysisResult = analysis;
        });
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handle(
          e,
          context: context,
          userMessage: 'AR mode failed. Switching to 2D analysis.',
          logLabel: 'ARMode.initialize',
        );
        GoRouter.of(context)
            .pushReplacement('/mode-2d', extra: widget.formData);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    _addArOverlays();
  }

  void _addArOverlays() {
    if (_arCoreController == null) return;

    if (_analysisResult != null) {
      final score = _analysisResult!.vegetation.vegetationScore;
      final ndviColor = _getNDVIColor(score);

      final ndviNode = ArCoreNode(
        shape: ArCoreSphere(
          materials: [ArCoreMaterial(color: ndviColor, metallic: 0.5)],
          radius: 0.05,
        ),
        position: vector.Vector3(0.0, 0.0, -0.5),
      );

      _arCoreController!.addArCoreNode(ndviNode);

      if (_analysisResult!.weather != null) {
        final weatherNode = ArCoreNode(
          shape: ArCoreSphere(
            materials: [ArCoreMaterial(color: Colors.blue, metallic: 0.3)],
            radius: 0.04,
          ),
          position: vector.Vector3(0.2, 0.0, -0.5),
        );

        _arCoreController!.addArCoreNode(weatherNode);
      }
    }
  }

  Color _getNDVIColor(double? ndvi) {
    if (ndvi == null) return Colors.grey;
    if (ndvi > 0.6) return Colors.green;
    if (ndvi > 0.4) return Colors.yellow;
    return Colors.red;
  }

  @override
  void dispose() {
    _arCoreController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ARCore isn't supported, _initializeARMode will have already
    // redirected to 2D mode. This is just a safety guard.
    if (!_arcoreSupported) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D AR Mode'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera),
            onPressed: _takeScreenshot,
            tooltip: 'Take Screenshot',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showARInfo(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
          ),

          // -------- Overlay Boxes (Fixed Colors) ---------

          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromARGB(179, 0, 0, 0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _buildCropHealthLabel(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          Positioned(
            top: 150,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromARGB(179, 33, 150, 243),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💧 Irrigation: ${_getIrrigationText()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            left: 20,
            child: _buildWeatherIconChip(),
          ),

          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/mode-2d', extra: widget.formData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Switch to 2D Mode'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIrrigationText() {
    if (_analysisResult == null || widget.formData == null) {
      return 'Loading...';
    }

    final vegScore = _analysisResult!.vegetation.vegetationScore;
    final weather = _analysisResult!.weather;

    // Simple heuristic: stressed crops or hot/dry weather -> irrigate sooner.
    int days = 3;
    if (vegScore < 0.4) {
      days = 1;
    } else if (vegScore < 0.6) {
      days = 2;
    }

    if (weather != null) {
      if (weather.temperatureC > 32 || weather.humidityPercent < 40) {
        days = days.clamp(1, 3);
      }
    }

    return '$days days';
  }

  String _buildCropHealthLabel() {
    if (_analysisResult == null) {
      return '🌱 Crop Health: Loading...';
    }

    final health = _analysisResult!.healthLabel;
    final season = _analysisResult!.season;
    return '🌱 Crop Health: $health · Season: $season';
  }

  Widget _buildWeatherIconChip() {
    final weather = _analysisResult?.weather;
    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cloud_off,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    IconData icon;
    final condition = weather.condition.toLowerCase();
    if (condition.contains('rain')) {
      icon = Icons.grain;
    } else if (condition.contains('cloud')) {
      icon = Icons.cloud;
    } else if (condition.contains('fog')) {
      icon = Icons.cloudy_snowing;
    } else {
      icon = Icons.wb_sunny;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  void _showARInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('3D AR Mode'),
        content: const Text(
          'Point your camera at crops to see real-time analysis overlays including:\n\n'
          '• Crop health indicators\n'
          '• Irrigation recommendations\n'
          '• Weather information\n'
          '• Pest alerts\n\n'
          'Move your device to explore the augmented view.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _takeScreenshot() {
    // Placeholder implementation - full AR screenshot would require native integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Screenshot feature coming soon! AR screenshot requires native platform integration.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
