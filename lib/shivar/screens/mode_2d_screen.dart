import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/mode_2d_controller.dart';
import '../models/analysis_result.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_error_handler.dart';
import '../widgets/themed_button.dart';
import '../services/location_service.dart';

class Mode2DScreen extends StatefulWidget {
  final Map<String, dynamic>? formData;

  const Mode2DScreen({super.key, this.formData});

  @override
  State<Mode2DScreen> createState() => _Mode2DScreenState();
}

class _Mode2DScreenState extends State<Mode2DScreen> {
  CameraController? _cameraController;
  bool _initializingCamera = false;
  bool _heatmapEnabled = false;

  double? _lat;
  double? _lon;
  String? _seasonLabel;
  LocationResult? _locationResult;

  @override
  void initState() {
    super.initState();
    _initLocationAndSeason();
    _initializeCamera();
  }

  Future<void> _initLocationAndSeason() async {
    // Fetch live GPS once; never from build.
    final location = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _locationResult = location;
      if (location.isSuccess) {
        _lat = location.latitude;
        _lon = location.longitude;
      } else {
        _lat = null;
        _lon = null;
      }
    });
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _initializingCamera = true;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available on this device')),
          );
        }
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
      });
    } catch (e, st) {
      if (!mounted) return;
      AppErrorHandler.handle(
        e,
        stackTrace: st,
        context: context,
        userMessage: 'Error initializing camera. Please try again.',
        logLabel: 'Mode2D.initializeCamera',
      );
    } finally {
      if (mounted) {
        setState(() {
          _initializingCamera = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis(Mode2DController controller) async {
    final camera = _cameraController;
    if (camera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready yet')),
      );
      return;
    }

    final result = await controller.analyzeFromCamera(
      lat: _lat,
      lon: _lon,
      cameraController: camera,
    );

    if (result != null) {
      // Navigate to report screen
      if (mounted) {
        context.push('/mode-2d-report', extra: result);
      }
    } else {
      if (_lat == null || _lon == null) {
        // Location missing or permission denied – controller falls back to
        // vegetation-only analysis via AnalysisApi.analyzeVegetationOnly.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Weather unavailable. Showing offline vegetation analysis.',
            ),
          ),
        );
      }
    }
  }

  void _showInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'About 2D Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'This mode estimates vegetation health from visible light (RGB) using a VARI-based index. '
                'It is an offline approximation and can be affected by lighting, shadows, and camera angle.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              SizedBox(height: 12),
              Text(
                'Tips: capture in daylight, avoid strong shadows, and keep plants centered in frame.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _deriveWeatherTip(AnalysisResult? result) {
    final weather = result?.weather;
    if (weather != null) {
      final temp = weather.temperatureC;
      final humidity = weather.humidityPercent;
      final windMs = weather.windSpeedMs;

      if (humidity >= 80) {
        return 'High humidity – monitor closely for fungal diseases.';
      }
      if (temp >= 35) {
        return 'Hot conditions – avoid heavy work at midday and watch for crop stress.';
      }
      if (windMs >= 0.5 && windMs <= 3.0) {
        return 'Calm to moderate wind – generally suitable window for spraying if needed.';
      }
      if (temp <= 10) {
        return 'Cool conditions – young crops may grow slower; protect sensitive seedlings.';
      }
      return 'Weather is generally normal for routine field operations.';
    }

    if (result != null && result.weatherErrorCode != null) {
      return 'Using vegetation-only data – confirm local forecast before spraying or irrigation changes.';
    }

    return null;
  }

  Future<void> _shareAnalysisReport(AnalysisResult result) async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                '2D Field Analysis Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Overview',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Location: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
            ),
            pw.Text(
              'Captured at: ${result.timestamp.toLocal().toString().split(".").first}',
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Vegetation Health',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Bullet(
              text:
                  'Vegetation score: ${result.vegetationPercent.toStringAsFixed(0)}% (${result.healthLabel})',
            ),
            pw.Bullet(
              text:
                  'Confidence: ${result.confidenceLabel} (${result.confidencePercent.toStringAsFixed(0)}%)',
            ),
            pw.Bullet(
              text:
                  'Vegetation coverage: ${(result.vegetation.vegetationCoverageRatio * 100).clamp(0, 100).toStringAsFixed(0)}%',
            ),
            pw.Bullet(
              text:
                  'Lighting quality: ${(result.vegetation.lightingQuality * 100).clamp(0, 100).toStringAsFixed(0)}%',
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Weather (at capture time)',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            if (result.weather != null) ...[
              pw.Bullet(
                text:
                    'Temperature: ${result.weather!.temperatureC.toStringAsFixed(1)} °C',
              ),
              pw.Bullet(
                text:
                    'Humidity: ${result.weather!.humidityPercent.toStringAsFixed(0)} %',
              ),
              pw.Bullet(
                text:
                    'Wind speed: ${result.weather!.windSpeedMs.toStringAsFixed(1)} m/s',
              ),
              pw.Bullet(
                text: 'Condition: ${result.weather!.condition}',
              ),
            ] else ...[
              pw.Text(
                'Weather data was not available at analysis time. Values are based on vegetation only.',
              ),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
              'Notes',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Analysis is based on visible-light (RGB) approximation and can be influenced by lighting, shadows, and framing.',
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/shivAR_2d_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await doc.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '2D Field Analysis Report from ShivAR',
      );
    } catch (e, st) {
      if (!mounted) return;
      AppErrorHandler.handle(
        e,
        stackTrace: st,
        context: context,
        userMessage: 'Failed to generate report. Please try again.',
        logLabel: 'Mode2D.shareReport',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Mode2DController>(
      create: (_) {
        final controller = Mode2DController();
        controller.loadLastAnalysis();
        return controller;
      },
      child: Consumer<Mode2DController>(
        builder: (context, controller, _) {
          final AnalysisResult? result = controller.currentResult;
          final previewBytes = controller.lastPreviewJpgBytes;
          final weatherTip = _deriveWeatherTip(result);

          return Scaffold(
            appBar: AppBar(
              title: const Text('2D Vegetation Analysis'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
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
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'About this analysis',
                  onPressed: _showInfoSheet,
                ),
              ],
            ),
            body: Column(
              children: [
                // Top: Season label + live location indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Season',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            result?.season ?? 'Detecting…',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                _locationResult?.isSuccess == true
                                    ? Icons.gps_fixed
                                    : Icons.gps_off,
                                size: 16,
                                color: _locationResult?.isSuccess == true
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _locationResult?.isSuccess == true
                                    ? '${_lat?.toStringAsFixed(4)}, ${_lon?.toStringAsFixed(4)}'
                                    : 'GPS unavailable',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Camera preview or placeholder
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_initializingCamera)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (previewBytes != null)
                        Image.memory(
                          previewBytes,
                          fit: BoxFit.cover,
                        )
                      else if (_cameraController != null &&
                          _cameraController!.value.isInitialized)
                        CameraPreview(_cameraController!)
                      else
                        Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Text(
                              'Camera preview unavailable',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      if (_heatmapEnabled && result != null)
                        Container(
                          decoration: BoxDecoration(
                            gradient: controller.heatmapGradient,
                          ),
                        ),
                      if (previewBytes != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: FilledButton.tonal(
                            onPressed: controller.isAnalyzing
                                ? null
                                : () => controller.clearPreview(),
                            child: const Text('Retake'),
                          ),
                        ),
                      if (result != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              result.fromCache ? 'Cached' : 'Latest',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ThemedButton(
                          title: 'Capture & Analyze',
                          onPressed: controller.isAnalyzing
                              ? null
                              : () => _runAnalysis(controller),
                          variant: ButtonVariant.primary,
                          isLoading: controller.isAnalyzing,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Using visible-light vegetation analysis (offline approximation).',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (controller.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          controller.errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
