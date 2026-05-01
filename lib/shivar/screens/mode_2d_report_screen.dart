import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/analysis_result.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/themed_button.dart';
import '../widgets/themed_card.dart';

class Mode2DReportScreen extends StatelessWidget {
  final AnalysisResult result;

  const Mode2DReportScreen({super.key, required this.result});

  Future<void> _shareAnalysisReport() async {
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
    } catch (e) {
      // Handle error
      debugPrint('Error sharing report: $e');
    }
  }

  String? _deriveWeatherTip(AnalysisResult result) {
    final weather = result.weather;
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

    if (result.weatherErrorCode != null) {
      return 'Using vegetation-only data – confirm local forecast before spraying or irrigation changes.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final weatherTip = _deriveWeatherTip(result);

    return Scaffold(
      appBar: AppBar(
        title: const Text('2D Analysis Report'),
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
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: _shareAnalysisReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview
            ThemedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Location: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Captured at: ${result.timestamp.toLocal().toString().split('.').first}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Season: ${result.season ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Vegetation Health
            ThemedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vegetation Health',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${result.vegetationPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.healthLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: result.vegetation.vegetationScore.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.border,
                    color: AppTheme.primaryGreen,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confidence: ${result.confidencePercent.toStringAsFixed(0)}% (${result.confidenceLabel})',
                    style: TextStyle(
                      fontSize: 14,
                      color: result.confidencePercent >= 80
                          ? AppTheme.success
                          : result.confidencePercent >= 50
                              ? AppTheme.warning
                              : AppTheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coverage: ${(result.vegetation.vegetationCoverageRatio * 100).clamp(0, 100).toStringAsFixed(0)}% vegetation',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Lighting: ${(result.vegetation.lightingQuality * 100).clamp(0, 100).toStringAsFixed(0)}% quality',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Weather
            ThemedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weather',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (result.weather != null) ...[
                    Text(
                      'Temperature: ${result.weather!.temperatureC.toStringAsFixed(1)}°C',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Humidity: ${result.weather!.humidityPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Wind Speed: ${result.weather!.windSpeedMs.toStringAsFixed(1)} m/s',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Condition: ${result.weather!.condition}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else if (result.weatherErrorCode != null) ...[
                    const Text(
                      'Weather unavailable. Showing offline vegetation analysis.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${result.weatherErrorCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Weather data was not available.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (weatherTip != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      weatherTip!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Using visible-light vegetation analysis (offline approximation).',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 24),
            ThemedButton(
              title: 'Share Report',
              onPressed: _shareAnalysisReport,
              variant: ButtonVariant.primary,
            ),
            const SizedBox(height: 12),
            ThemedButton(
              title: 'Back to Analysis',
              onPressed: () => context.pop(),
              variant: ButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }
}
