import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_report_sheet.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_scan_failure_sheet.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Minimal fake [TextRecognizer] — not actually called from this test
/// (the fake service overrides `scanPumpDisplay`) but required so the
/// real ReceiptScanService constructor doesn't try to spin up the ML
/// Kit native handle when we hand it to `super(...)`.
class _NoopRecognizer extends TextRecognizer {
  _NoopRecognizer();

  @override
  Future<RecognizedText> processImage(InputImage input) async =>
      RecognizedText(text: '', blocks: const []);

  @override
  Future<void> close() async {}
}

/// Likewise — a stub [ImagePicker] so the constructor doesn't grab a
/// real one. Never called because the fake service short-circuits.
class _NoopPicker extends ImagePicker {}

/// Stub vehicle list so the AddFillUpScreen leaves the empty-state CTA
/// behind and renders the full form (#706).
class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
        ),
      ];
}

final _withVehicle = <Object>[
  vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
];

/// Fake [ReceiptScanService] that bypasses the camera + ML Kit and
/// returns a pre-canned [PumpDisplayScanOutcome] for [scanPumpDisplay].
/// Used by the failure-flow test (#953) to verify the screen opens the
/// [PumpScanFailureSheet] when the parse result has no usable data.
class _FakeFailingScanService extends ReceiptScanService {
  _FakeFailingScanService()
      : super(
          picker: _NoopPicker(),
          recognizer: _NoopRecognizer(),
          parser: const ReceiptParser(),
          pumpParser: const PumpDisplayParser(),
        );

  int deleteCalls = 0;

  @override
  Future<PumpDisplayScanOutcome?> scanPumpDisplay() async {
    return const PumpDisplayScanOutcome(
      // confidence == 0 + only one usable field → !hasUsableData → opens
      // the failure-flow sheet.
      parse: PumpDisplayParseResult(liters: 40.0),
      ocrText: 'unreadable garbage',
      imagePath: '/tmp/fake-pump-failure.jpg',
    );
  }

  @override
  Future<void> deleteCapturedImage(String path) async {
    deleteCalls++;
  }

  @override
  void dispose() {
    // No-op — the test owns this fake's lifecycle.
  }
}

void main() {
  group('AddFillUpScreen — pump-display failure flow (#953)', () {
    /// Pumps enough frames to drive the async chain through:
    ///   open import sheet → tap pump → fake returns failing outcome
    ///   → screen calls showModalBottomSheet → failure sheet appears.
    /// Cannot use pumpAndSettle past the failure-sheet open because
    /// the import-chip's busy spinner keeps animating until the host
    /// finally-block flips _scanningPump back to false (which only
    /// happens AFTER the failure sheet returns).
    Future<void> openFailureSheet(
      WidgetTester tester,
      ReceiptScanService scanService,
    ) async {
      await pumpApp(
        tester,
        AddFillUpScreen(scanService: scanService),
        overrides: _withVehicle,
      );
      await tester.tap(find.text('Import from…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pump display'));
      // Drive the async chain manually — pumpAndSettle would deadlock
      // on the import-chip's busy spinner.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets(
        'failing pump scan opens PumpScanFailureSheet with all three actions',
        (tester) async {
      final fake = _FakeFailingScanService();

      await openFailureSheet(tester, fake);

      // The failure sheet replaces the legacy snackbar — verify all
      // three actions are present so the user can pick one.
      expect(find.byType(PumpScanFailureSheet), findsOneWidget);
      expect(find.text('Display unreadable'), findsOneWidget);
      expect(find.text('Correct manually'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Remove photo'), findsOneWidget);
    });

    testWidgets(
        '"Report" opens BadScanReportSheet with ScanKind.pumpDisplay',
        (tester) async {
      final fake = _FakeFailingScanService();

      await openFailureSheet(tester, fake);
      await tester.tap(find.text('Report'));
      // Drive frames manually — host screen's busy spinner is still on.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The bad-scan sheet receives the failing outcome with the
      // pumpDisplay kind, so the title MUST switch to the pump-display
      // variant.
      expect(find.byType(BadScanReportSheet), findsOneWidget);
      expect(
        find.text('Report a scan error — Pump display'),
        findsOneWidget,
        reason:
            '#953 — failure sheet "Report" must open BadScanReportSheet '
            'parameterised with ScanKind.pumpDisplay (kind-specific title).',
      );
    });

    testWidgets('"Remove photo" deletes the captured image and dismisses',
        (tester) async {
      final fake = _FakeFailingScanService();

      await openFailureSheet(tester, fake);
      await tester.tap(find.text('Remove photo'));
      // After Remove photo the host returns from the failure sheet,
      // flips _scanningPump back to false — chip spinner stops, so
      // pumpAndSettle can settle frames cleanly.
      await tester.pumpAndSettle();

      expect(
        fake.deleteCalls,
        1,
        reason: 'Picking "Remove photo" must delete the captured temp '
            'file so the failed scan does not leak to disk.',
      );
      expect(find.byType(PumpScanFailureSheet), findsNothing);
    });

    testWidgets(
        '"Correct manually" closes without deleting and leaves form alone',
        (tester) async {
      final fake = _FakeFailingScanService();

      await openFailureSheet(tester, fake);
      await tester.tap(find.text('Correct manually'));
      await tester.pumpAndSettle();

      expect(fake.deleteCalls, 0,
          reason: '"Correct manually" must NOT delete the photo — the '
              'user might want to revisit the report path later.');
      expect(find.byType(PumpScanFailureSheet), findsNothing);
    });
  });
}
