import 'dart:developer' as developer;

import 'package:flutter/material.dart';

/// Centralized app-wide error handling helper.
///
/// Responsibilities:
/// - Log errors with stack traces for diagnostics
/// - Optionally show a user-facing snackbar message
/// - Ensure errors never crash the UI layer directly
class AppErrorHandler {
  const AppErrorHandler._();

  static void handle(
    Object error, {
    StackTrace? stackTrace,
    BuildContext? context,
    String? userMessage,
    String? logLabel,
  }) {
    // Structured log for easier debugging.
    developer.log(
      userMessage ?? 'Unhandled application error',
      name: logLabel ?? 'AppErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // Show a lightweight snackbar when a context is available.
    if (context != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              userMessage ?? 'Something went wrong. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

