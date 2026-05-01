import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vawar/shivar/theme/app_theme.dart';
import 'package:vawar/shivar/models/analysis_result.dart';
import 'package:vawar/shivar/providers/theme_provider.dart';
import 'package:vawar/shivar/screens/pre_scan_form.dart';
import 'package:vawar/shivar/screens/ar_mode_selection.dart';
import 'package:vawar/shivar/screens/ar_mode_screen.dart';
import 'package:vawar/shivar/screens/mode_2d_screen.dart';
import 'package:vawar/shivar/screens/mode_2d_report_screen.dart';
import 'package:vawar/shivar/screens/insights_report.dart';
import 'package:vawar/shivar/screens/home_dashboard.dart';

class ShivARApp extends StatelessWidget {
  const ShivARApp({super.key});

  @override

  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'ShivAR',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/home-dashboard',
  routes: [
    GoRoute(
      path: '/pre-scan',
      builder: (context, state) => const PreScanForm(),
    ),
    GoRoute(
      path: '/ar-mode-selection',
      builder: (context, state) => const ARModeSelection(),
    ),
    GoRoute(
      path: '/ar-mode',
      builder: (context, state) =>
          ARModeScreen(formData: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/mode-2d',
      builder: (context, state) =>
          Mode2DScreen(formData: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/mode-2d-report',
      builder: (context, state) =>
          Mode2DReportScreen(result: state.extra as AnalysisResult),
    ),
    GoRoute(
      path: '/insights-report',
      builder: (context, state) => const InsightsReport(),
    ),
    GoRoute(
      path: '/home-dashboard',
      builder: (context, state) => const HomeDashboard(),
    ),
  ],
);
