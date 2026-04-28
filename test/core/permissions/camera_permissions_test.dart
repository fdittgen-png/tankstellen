import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tankstellen/core/permissions/camera_permissions.dart';

/// The `permission_handler` plugin talks to the host over a single
/// MethodChannel. Mocking it directly (instead of swapping the platform
/// instance) means we exercise the real `PluginCameraPermissions` plumbing —
/// the `await Permission.camera.status` / `request()` / `openAppSettings()`
/// calls in production code — and only stub the boundary the OS would
/// otherwise own. That's the contract that actually breaks when the plugin
/// upgrades, so it's the contract worth testing.
const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

/// Camera's wire integer (see `permission_handler_platform_interface`'s
/// `permissions.dart` — `static const camera = Permission._(1);`). Hard-coded
/// because the codec on the request side returns a `Map<int, int>` — the
/// plugin doesn't expose a public accessor for the wire value.
const _cameraPermissionValue = 1;

/// Wire integers for `PermissionStatus` (see
/// `permission_handler_platform_interface/lib/src/permission_status.dart`,
/// the `PermissionStatusValue.value` extension). Inlined because the
/// extension isn't re-exported by the top-level `permission_handler`
/// package, and the platform_interface package isn't a direct dep of
/// this app — adding it just to read six ints would be heavier than
/// pinning them here.
int _wire(PermissionStatus s) {
  switch (s) {
    case PermissionStatus.denied:
      return 0;
    case PermissionStatus.granted:
      return 1;
    case PermissionStatus.restricted:
      return 2;
    case PermissionStatus.limited:
      return 3;
    case PermissionStatus.permanentlyDenied:
      return 4;
    case PermissionStatus.provisional:
      return 5;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Records the raw method calls reaching the plugin boundary, so each
  /// test can both stub the response and assert the method/args the
  /// production code sent. The handler is reinstalled per test via
  /// [_installHandler] so failures don't leak across tests.
  late List<MethodCall> calls;

  void installHandler({
    PermissionStatus? statusResponse,
    PermissionStatus? requestResponse,
    bool openAppSettingsResult = true,
  }) {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'checkPermissionStatus':
          return _wire(statusResponse ?? PermissionStatus.denied);
        case 'requestPermissions':
          // Wire format: `Map<int, int>` keyed by Permission.value.
          return <int, int>{
            _cameraPermissionValue:
                _wire(requestResponse ?? PermissionStatus.denied),
          };
        case 'openAppSettings':
          return openAppSettingsResult;
      }
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('PluginCameraPermissions.current()', () {
    test('granted → CameraPermissionState.granted', () async {
      installHandler(statusResponse: PermissionStatus.granted);
      const sut = PluginCameraPermissions();

      expect(await sut.current(), CameraPermissionState.granted);
      expect(calls.single.method, 'checkPermissionStatus');
      expect(calls.single.arguments, _cameraPermissionValue);
    });

    test('limited (iOS 14+) → granted — limited access still lets the '
        'scanner read a frame', () async {
      installHandler(statusResponse: PermissionStatus.limited);
      const sut = PluginCameraPermissions();

      expect(await sut.current(), CameraPermissionState.granted);
    });

    test('provisional (iOS 12+) → granted — same rationale as limited; '
        'mapping must not split iOS-only states into denied buckets',
        () async {
      installHandler(statusResponse: PermissionStatus.provisional);
      const sut = PluginCameraPermissions();

      expect(await sut.current(), CameraPermissionState.granted);
    });

    test('permanentlyDenied → permanentlyDenied — UI must surface the '
        '"open settings" CTA, not the request prompt', () async {
      installHandler(statusResponse: PermissionStatus.permanentlyDenied);
      const sut = PluginCameraPermissions();

      expect(await sut.current(), CameraPermissionState.permanentlyDenied);
    });

    test('restricted (iOS parental controls) → permanentlyDenied — '
        "the user can't change it from the prompt either", () async {
      installHandler(statusResponse: PermissionStatus.restricted);
      const sut = PluginCameraPermissions();

      expect(await sut.current(), CameraPermissionState.permanentlyDenied);
    });

    test('denied → denied — the request prompt is still useful', () async {
      installHandler(statusResponse: PermissionStatus.denied);
      const sut = PluginCameraPermissions();

      expect(await sut.current(), CameraPermissionState.denied);
    });
  });

  group('PluginCameraPermissions.request()', () {
    test('granted result → granted state and the system request '
        'method actually fires (not a silent status read)', () async {
      installHandler(requestResponse: PermissionStatus.granted);
      const sut = PluginCameraPermissions();

      final result = await sut.request();

      expect(result, CameraPermissionState.granted);
      // The plugin sends a single `requestPermissions` call with the
      // permission's int wire value — assert both to catch a regression
      // where `current()` got wired to `request()`.
      expect(calls.single.method, 'requestPermissions');
      expect(calls.single.arguments, <int>[_cameraPermissionValue]);
    });

    test('denied result → denied state', () async {
      installHandler(requestResponse: PermissionStatus.denied);
      const sut = PluginCameraPermissions();

      expect(await sut.request(), CameraPermissionState.denied);
    });

    test('permanentlyDenied result → permanentlyDenied state — Android 11+ '
        'can return this from request() after a second decline', () async {
      installHandler(requestResponse: PermissionStatus.permanentlyDenied);
      const sut = PluginCameraPermissions();

      expect(await sut.request(), CameraPermissionState.permanentlyDenied);
    });
  });

  group('PluginCameraPermissions.openSettings()', () {
    test('forwards to the plugin without throwing', () async {
      installHandler();
      const sut = PluginCameraPermissions();

      await sut.openSettings();

      expect(calls.single.method, 'openAppSettings');
    });

    test('does not throw when the plugin reports settings-page failure '
        '(returns false) — UI handles the no-op silently', () async {
      installHandler(openAppSettingsResult: false);
      const sut = PluginCameraPermissions();

      await expectLater(sut.openSettings(), completes);
    });
  });
}
