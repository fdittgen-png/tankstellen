import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
