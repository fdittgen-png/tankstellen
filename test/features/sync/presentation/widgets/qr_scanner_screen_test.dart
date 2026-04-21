import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tankstellen/core/permissions/camera_permissions.dart';
import 'package:tankstellen/features/sync/presentation/widgets/qr_scanner_screen.dart';

void main() {
  group('QrScannerTorchButton (#721 subset)', () {
    testWidgets('hidden when the platform reports torch unavailable',
        (tester) async {
      await _pumpButton(tester, TorchState.unavailable);
      expect(find.byKey(const Key('qrScannerTorchToggle')), findsNothing);
    });

    testWidgets('off state: flash_off icon + "Turn flash on" tooltip',
        (tester) async {
      await _pumpButton(tester, TorchState.off);
      final btn = find.byKey(const Key('qrScannerTorchToggle'));
      expect(btn, findsOneWidget);
      expect(tester.widget<IconButton>(btn).tooltip, 'Turn flash on');
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('on state: flash_on icon + "Turn flash off" tooltip',
        (tester) async {
      await _pumpButton(tester, TorchState.on);
      final btn = find.byKey(const Key('qrScannerTorchToggle'));
      expect(tester.widget<IconButton>(btn).tooltip, 'Turn flash off');
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('tapping the button calls onToggle', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        TorchState.off,
        onToggle: () async => calls++,
      );
      await tester.tap(find.byKey(const Key('qrScannerTorchToggle')));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('rebuilds when the notifier emits a new torch state',
        (tester) async {
      final notifier = _TorchStateNotifier(TorchState.off);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrScannerTorchButton(
              state: notifier,
              onToggle: () async {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.flash_off), findsOneWidget);

      notifier.setTorch(TorchState.on);
      await tester.pump();
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });
  });

  _registerQrScannerFlowTests();
}

Future<void> _pumpButton(
  WidgetTester tester,
  TorchState torch, {
  Future<void> Function()? onToggle,
}) async {
  final notifier = _TorchStateNotifier(torch);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QrScannerTorchButton(
          state: notifier,
          onToggle: onToggle ?? () async {},
        ),
      ),
    ),
  );
}

class _FakeCameraPermissions implements CameraPermissions {
  CameraPermissionState currentState;
  CameraPermissionState requestResult;
  int openSettingsCalls = 0;
  int requestCalls = 0;

  _FakeCameraPermissions({
    this.currentState = CameraPermissionState.granted,
    CameraPermissionState? requestResult,
  }) : requestResult = requestResult ?? currentState;

  @override
  Future<CameraPermissionState> current() async => currentState;

  @override
  Future<CameraPermissionState> request() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }
}

void _registerQrScannerFlowTests() {
  group('QrScannerScreen flow (#721)', () {
    testWidgets('permanently-denied permission surfaces the '
        'open-settings CTA — otherwise the user stares at a black '
        'screen with no way out', (tester) async {
      final perms = _FakeCameraPermissions(
        currentState: CameraPermissionState.permanentlyDenied,
      );
      await tester.pumpWidget(MaterialApp(
        home: QrScannerScreen(permissions: perms),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('qrScannerPermanentlyDenied')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('qrScannerDeniedAction')));
      await tester.pump();
      expect(perms.openSettingsCalls, 1);
    });

    testWidgets('initial denied re-prompts once — if the user taps '
        'the CTA we want a fresh system dialog, not just a retry of '
        'the cached state', (tester) async {
      final perms = _FakeCameraPermissions(
        currentState: CameraPermissionState.denied,
        requestResult: CameraPermissionState.denied,
      );
      await tester.pumpWidget(MaterialApp(
        home: QrScannerScreen(permissions: perms),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qrScannerDenied')), findsOneWidget);
      expect(perms.requestCalls, 1);

      await tester.tap(find.byKey(const Key('qrScannerDeniedAction')));
      await tester.pumpAndSettle();
      expect(perms.requestCalls, 2);
    });

    testWidgets('denied + re-prompt granted clears the error state — '
        'the user who changes their mind and grants on the second '
        'ask should land on the scanner, not get stuck on the CTA',
        (tester) async {
      final perms = _FakeCameraPermissions(
        currentState: CameraPermissionState.denied,
        requestResult: CameraPermissionState.granted,
      );
      await tester.pumpWidget(MaterialApp(
        home: QrScannerScreen(permissions: perms),
      ));
      // Intentionally don't settle — MobileScanner will start
      // initialising and fail in the test harness. We only want
      // to verify the denied CTA is no longer shown.
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('qrScannerDenied')), findsNothing);
      expect(find.byKey(const Key('qrScannerPermanentlyDenied')), findsNothing);
    });
  });
}

class _TorchStateNotifier extends ValueNotifier<MobileScannerState> {
  _TorchStateNotifier(TorchState torch) : super(_state(torch));

  void setTorch(TorchState torch) {
    value = _state(torch);
  }

  static MobileScannerState _state(TorchState torch) => MobileScannerState(
        availableCameras: 1,
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.wide,
        deviceOrientation: DeviceOrientation.portraitUp,
        isInitialized: true,
        isStarting: false,
        isRunning: true,
        size: Size.zero,
        torchState: torch,
        zoomScale: 1,
        error: null,
      );
}
