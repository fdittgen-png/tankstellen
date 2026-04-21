import 'package:permission_handler/permission_handler.dart';

/// Coarse state for the camera permission needed by the QR scanner
/// (#721). Mirrors [Obd2PermissionState] — keeping the vocabulary
/// consistent lets future screens reuse the same CTA patterns.
enum CameraPermissionState { granted, denied, permanentlyDenied }

/// Abstract facade over the runtime camera permission probe. Kept
/// behind an interface so the scanner screen can be widget-tested
/// without the real `permission_handler` binding — the test injects
/// a fake that returns the desired state.
abstract class CameraPermissions {
  /// Read the current state without prompting — lets the UI decide
  /// whether to show the camera, the "grant" CTA, or the "open
  /// settings" CTA before any system dialog interrupts the user.
  Future<CameraPermissionState> current();

  /// Trigger the system prompt. Returns the resulting state. On
  /// Android, a permanent denial never shows the prompt again;
  /// callers handle that via [openSettings].
  Future<CameraPermissionState> request();

  /// Deep-link to the app's OS settings so the user can grant
  /// permission manually after a permanent denial.
  Future<void> openSettings();
}

class PluginCameraPermissions implements CameraPermissions {
  const PluginCameraPermissions();

  @override
  Future<CameraPermissionState> current() async {
    return _mapStatus(await Permission.camera.status);
  }

  @override
  Future<CameraPermissionState> request() async {
    return _mapStatus(await Permission.camera.request());
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  static CameraPermissionState _mapStatus(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return CameraPermissionState.granted;
    }
    if (s.isPermanentlyDenied || s.isRestricted) {
      return CameraPermissionState.permanentlyDenied;
    }
    return CameraPermissionState.denied;
  }
}
