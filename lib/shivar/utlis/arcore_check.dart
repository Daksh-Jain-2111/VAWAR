import 'dart:developer' as developer;
import 'dart:io';

import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

/// ARCore status result with detailed information
class ARCoreStatus {
  final bool isSupported;
  final bool isInstalled;
  final String statusCode;
  final String userMessage;
  final bool canUseAR;

  ARCoreStatus({
    required this.isSupported,
    required this.isInstalled,
    required this.statusCode,
    required this.userMessage,
    required this.canUseAR,
  });
}

class ARCoreCheck {
  /// Returns true if ARCore is installed & ready
  static Future<bool> isARCoreSupported() async {
    if (!Platform.isAndroid) return false;

    try {
      final available = await ArCoreController.checkArCoreAvailability();
      final installed = await ArCoreController.checkIsArCoreInstalled();
      return available && installed;
    } catch (e) {
      developer.log(
        'ARCore check error',
        name: 'ARCoreCheck.isARCoreSupported',
        error: e,
      );
      return false;
    }
  }

  /// Returns detailed ARCore status with user-friendly messages
  static Future<ARCoreStatus> getDetailedStatus() async {
    if (!Platform.isAndroid) {
      return ARCoreStatus(
        isSupported: false,
        isInstalled: false,
        statusCode: "not_android",
        userMessage: "AR features are only available on Android devices.",
        canUseAR: false,
      );
    }

    try {
      final available = await ArCoreController.checkArCoreAvailability();
      final installed = await ArCoreController.checkIsArCoreInstalled();

      if (!available) {
        return ARCoreStatus(
          isSupported: false,
          isInstalled: false,
          statusCode: "device_not_supported",
          userMessage:
              "Your device doesn't support ARCore. You can still use 2D mode for analysis.",
          canUseAR: false,
        );
      }

      if (available && !installed) {
        return ARCoreStatus(
          isSupported: true,
          isInstalled: false,
          statusCode: "supported_not_installed",
          userMessage:
              "ARCore is supported but not installed. Install from Play Store for AR mode, or use 2D mode.",
          canUseAR: false,
        );
      }

      if (available && installed) {
        return ARCoreStatus(
          isSupported: true,
          isInstalled: true,
          statusCode: "ready",
          userMessage: "ARCore is ready. You can use AR mode.",
          canUseAR: true,
        );
      }

      return ARCoreStatus(
        isSupported: false,
        isInstalled: false,
        statusCode: "unknown",
        userMessage: "Unable to determine ARCore status. 2D mode is available.",
        canUseAR: false,
      );
    } catch (e) {
      developer.log(
        'ARCore status error',
        name: 'ARCoreCheck.getDetailedStatus',
        error: e,
      );
      return ARCoreStatus(
        isSupported: false,
        isInstalled: false,
        statusCode: "error",
        userMessage: "Error checking ARCore. Please use 2D mode.",
        canUseAR: false,
      );
    }
  }

  /// Returns a readable status (legacy method for backward compatibility)
  static Future<String> getStatus() async {
    final detailed = await getDetailedStatus();
    return detailed.statusCode;
  }

  /// Check if device can use AR mode with fallback to 2D
  static Future<bool> canUseARMode() async {
    final status = await getDetailedStatus();
    return status.canUseAR;
  }

  /// Open Play Store to install ARCore
  static Future<void> installARCore() async {
    const androidUrl = "market://details?id=com.google.ar.core";
    const webUrl =
        "https://play.google.com/store/apps/details?id=com.google.ar.core";

    try {
      final uri = Uri.parse(androidUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      developer.log(
        'Play Store launch error',
        name: 'ARCoreCheck.installARCore',
        error: e,
      );
    }
  }
}
