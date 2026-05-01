import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/themed_card.dart';
import '../widgets/themed_button.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class InsightsReport extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const InsightsReport({super.key, this.reportData});

  Future<String?> _generatePDF() async {
    if (reportData == null) return null;

    final pdf = pw.Document();

    final farmContext = reportData!['farm_context'] as Map<String, dynamic>?;
    final ndvi = reportData!['ndvi'] as Map<String, dynamic>?;
    final weather = reportData!['weather'] as Map<String, dynamic>?;
    final cropHealth = reportData!['crop_health'] as Map<String, dynamic>?;
    final advisory = reportData!['advisory'] as Map<String, dynamic>?;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Farm Insights Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          // Farm Overview
          pw.Text(
            'Farm Overview',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          if (farmContext != null) ...[
            pw.Text(
                'Location: ${reportData!['location']?['latitude']}, ${reportData!['location']?['longitude']}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Crop Type: ${farmContext['crop_type'] ?? 'Not specified'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Field Size: ${farmContext['field_size'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Season: ${farmContext['season'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
          ],
          pw.SizedBox(height: 20),
          // NDVI & Crop Health
          pw.Text(
            'NDVI & Crop Health',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          if (ndvi != null) ...[
            pw.Text('NDVI Score: ${ndvi['ndvi_value']?.toString() ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Status: ${ndvi['status'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
          ],
          if (cropHealth != null) ...[
            pw.Text(
                'Health Classification: ${cropHealth['classification'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text(
                'Health Score: ${cropHealth['health_score']?.toString() ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            if (cropHealth['issues'] != null)
              pw.Text('Issues: ${(cropHealth['issues'] as List).join(', ')}',
                  style: const pw.TextStyle(fontSize: 12)),
          ],
          pw.SizedBox(height: 20),
          // Weather Advisory
          if (weather != null) ...[
            pw.Text(
              'Weather Advisory',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Temperature: ${weather['current']?['temperature']}°C',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Humidity: ${weather['current']?['humidity']}%',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Rainfall: ${weather['current']?['rainfall']}mm',
                style: const pw.TextStyle(fontSize: 12)),
            if (weather['forecast_7d'] != null) ...[
              pw.SizedBox(height: 10),
              pw.Text('7-Day Forecast:',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ...(weather['forecast_7d'] as List).take(7).map((day) => pw.Text(
                  '${day['date']}: ${day['temp']}°C, Rain: ${day['rain']}mm',
                  style: const pw.TextStyle(fontSize: 12))),
            ],
            pw.SizedBox(height: 20),
          ],
          // Pest & Disease Advisory
          if (advisory != null && advisory['pest_control'] != null) ...[
            pw.Text(
              'Pest & Disease Advisory',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
                'Risk Level: ${advisory['pest_control']['risk_level'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            if (advisory['pest_control']['recommendations'] != null)
              pw.Text(
                  'Recommendations: ${(advisory['pest_control']['recommendations'] as List).join(', ')}',
                  style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
          ],
          // Fertilizer Recommendation
          if (advisory != null &&
              advisory['fertilizer_recommendation'] != null) ...[
            pw.Text(
              'Fertilizer Recommendation',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
                'Type: ${advisory['fertilizer_recommendation']['type'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text(
                'Quantity: ${advisory['fertilizer_recommendation']['quantity'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text(
                'Timing: ${advisory['fertilizer_recommendation']['timing'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
          ],
          // Irrigation Schedule
          if (advisory != null && advisory['irrigation_schedule'] != null) ...[
            pw.Text(
              'Irrigation Schedule',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 10),
            ...(advisory['irrigation_schedule'] as List).take(7).map(
                (schedule) => pw.Text(
                    '${schedule['date']}: ${schedule['recommended'] ? schedule['amount'] : 'Not needed'}',
                    style: const pw.TextStyle(fontSize: 12))),
          ],
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/farm_insights_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> _shareReport() async {
    final pdfPath = await _generatePDF();
    if (pdfPath != null) {
      await Share.shareXFiles([XFile(pdfPath)],
          text: 'Farm Insights Report - Generated by ShivAR');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reportData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights Report')),
        body: const Center(child: Text('No report data available')),
      );
    }

    final farmContext = reportData!['farm_context'] as Map<String, dynamic>?;
    final ndvi = reportData!['ndvi'] as Map<String, dynamic>?;
    final weather = reportData!['weather'] as Map<String, dynamic>?;
    final cropHealth = reportData!['crop_health'] as Map<String, dynamic>?;
    final advisory = reportData!['advisory'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Insights Report'),
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
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Farm Overview
            ThemedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Farm Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (farmContext != null) ...[
                    _buildInfoRow('Location',
                        reportData!['location']?.toString() ?? 'N/A'),
                    _buildInfoRow('Crop Type',
                        farmContext['crop_type'] ?? 'Not specified'),
                    _buildInfoRow(
                        'Field Size', farmContext['field_size'] ?? 'N/A'),
                    _buildInfoRow('Season', farmContext['season'] ?? 'N/A'),
                  ],
                ],
              ),
            ),
            // NDVI & Crop Health
            ThemedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NDVI & Crop Health',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ndvi != null) ...[
                    _buildInfoRow(
                        'NDVI Score', ndvi['ndvi_value']?.toString() ?? 'N/A'),
                    _buildInfoRow('Status', ndvi['status'] ?? 'N/A'),
                  ],
                  if (cropHealth != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Health Classification',
                        cropHealth['classification'] ?? 'N/A'),
                    _buildInfoRow('Health Score',
                        cropHealth['health_score']?.toString() ?? 'N/A'),
                    if (cropHealth['issues'] != null)
                      ...(cropHealth['issues'] as List)
                          .map((issue) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('⚠️ $issue',
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                  ],
                ],
              ),
            ),
            // Weather Advisory
            if (weather != null)
              ThemedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weather Advisory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Temperature',
                        '${weather['current']?['temperature']}°C'),
                    _buildInfoRow(
                        'Humidity', '${weather['current']?['humidity']}%'),
                    _buildInfoRow(
                        'Rainfall', '${weather['current']?['rainfall']}mm'),
                    if (weather['forecast_7d'] != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '7-Day Forecast:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...(weather['forecast_7d'] as List)
                          .take(7)
                          .map((day) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${day['date']}: ${day['temp']}°C, Rain: ${day['rain']}mm',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )),
                    ],
                  ],
                ),
              ),
            // Pest & Disease Advisory
            if (advisory != null && advisory['pest_control'] != null)
              ThemedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pest & Disease Advisory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Risk Level',
                      advisory['pest_control']['risk_level'] ?? 'N/A',
                    ),
                    if (advisory['pest_control']['recommendations'] != null)
                      ...(advisory['pest_control']['recommendations'] as List)
                          .map((rec) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('• $rec',
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                  ],
                ),
              ),
            // Fertilizer Recommendation
            if (advisory != null &&
                advisory['fertilizer_recommendation'] != null)
              ThemedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fertilizer Recommendation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Type',
                      advisory['fertilizer_recommendation']['type'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Quantity',
                      advisory['fertilizer_recommendation']['quantity'] ??
                          'N/A',
                    ),
                    _buildInfoRow(
                      'Timing',
                      advisory['fertilizer_recommendation']['timing'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            // Irrigation Schedule
            if (advisory != null && advisory['irrigation_schedule'] != null)
              ThemedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Irrigation Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(advisory['irrigation_schedule'] as List)
                        .take(7)
                        .map((schedule) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${schedule['date']}: ${schedule['recommended'] ? schedule['amount'] : 'Not needed'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                  ],
                ),
              ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ThemedButton(
                    title: 'Download PDF',
                    onPressed: _generatePDF,
                    variant: ButtonVariant.primary,
                  ),
                  const SizedBox(height: 12),
                  ThemedButton(
                    title: 'Share Report',
                    onPressed: _shareReport,
                    variant: ButtonVariant.outline,
                  ),
                  const SizedBox(height: 12),
                  ThemedButton(
                    title: 'Return Home',
                    onPressed: () => context.go('/'),
                    variant: ButtonVariant.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
