import 'package:flutter/services.dart';

class ARCoreChannel {
  static const MethodChannel _channel =
      MethodChannel('vawar.arcore/channel');

  /// Start AR session
  static Future<bool> startSession() async {
    return await _channel.invokeMethod<bool>('startSession') ?? false;
  }

  /// Stop AR session
  static Future<void> stopSession() async {
    await _channel.invokeMethod('stopSession');
  }

  /// Perform hit test
  static Future<Map<String, dynamic>?> hitTest(double x, double y) async {
    final result = await _channel.invokeMethod('hitTest', {"x": x, "y": y});
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Get AR frame data (planes, point cloud, etc.)
  static Future<Map<String, dynamic>> getFrame() async {
    final result = await _channel.invokeMethod('getFrame');
    return Map<String, dynamic>.from(result ?? {});
  }
}
