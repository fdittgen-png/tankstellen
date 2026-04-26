import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';
import '../models/error_trace.dart';

class DeviceInfoCollector {
  static DeviceInfo collect() {
    String os;
    String osVersion;
    String platform;

    if (kIsWeb) {
      os = 'web';
      osVersion = 'unknown';
      platform = 'web';
    } else {
      os = Platform.operatingSystem;
      osVersion = Platform.operatingSystemVersion;
      platform =
          (Platform.isAndroid || Platform.isIOS) ? 'mobile' : 'desktop';
    }

    double screenWidth = 0;
    double screenHeight = 0;
    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      screenWidth = size.width;
      screenHeight = size.height;
    } catch (e, st) { debugPrint('DeviceInfoCollector.screenSize: $e\n$st'); }

    return DeviceInfo(
      os: os,
      osVersion: osVersion,
      platform: platform,
      locale: ui.PlatformDispatcher.instance.locale.toString(),
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      appVersion: AppConstants.appVersion,
    );
  }
}
