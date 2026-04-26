import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #951 — TDD acceptance test for the "restore two import buttons"
/// rollback. The single "Import from…" chip + bottom-sheet was reverted
/// because the OBD-II tile inside the sheet returned null for the
/// odometer on real Peugeot hardware (PID 0xA6 is unsupported by the
/// generic ELM327 BLE clone the user has). Until that gap is closed by
/// a brand-specific UDS service $22 PID, the OBD-II import path is
/// hidden from this screen.
///
/// Acceptance:
///   1. Two visible buttons (Receipt + Pump display) are present.
///   2. The OBD2 import path is NOT shown on this screen.
///   3. Tapping each button triggers the correct callback (Receipt
///      hits scanReceipt, Pump display hits scanPumpDisplay).
class _NoopRecognizer extends TextRecognizer {
  _NoopRecognizer();

  @override
  Future<RecognizedText> processImage(InputImage input) async =>
      RecognizedText(text: '', blocks: const []);

  @override
  Future<void> close() async {}
}

class _NoopPicker extends ImagePicker {}

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

/// Records which scan path the screen invoked so the test can assert
/// that tapping a button routes to the expected entry point. Both
/// methods short-circuit (return null) so the screen's finally-block
/// flips its busy flag back off and the test can settle.
class _RoutingScanService extends ReceiptScanService {
  _RoutingScanService()
      : super(
          picker: _NoopPicker(),
          recognizer: _NoopRecognizer(),
          parser: const ReceiptParser(),
          pumpParser: const PumpDisplayParser(),
        );

  int receiptCalls = 0;
  int pumpCalls = 0;

  @override
  Future<ReceiptScanOutcome?> scanReceipt() async {
    receiptCalls++;
    return null;
  }

  @override
  Future<PumpDisplayScanOutcome?> scanPumpDisplay() async {
    pumpCalls++;
    return null;
  }

  @override
  void dispose() {
    // Test owns this fake's lifecycle — no-op so the screen's
    // disposeListener doesn't accidentally close the platform ML
    // Kit handle the test never actually opened.
  }
}

void main() {
  group('AddFillUpScreen — restored two import buttons (#951)', () {
    testWidgets('renders Receipt + Pump display buttons; OBD2 absent',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      // Acceptance 1: both buttons present, keyed for stable lookup.
      expect(
        find.byKey(const Key('import_receipt_button')),
        findsOneWidget,
        reason: 'Receipt button must be visible at the top of the form.',
      );
      expect(
        find.byKey(const Key('import_pump_button')),
        findsOneWidget,
        reason: 'Pump display button must be visible at the top of the form.',
      );
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Pump display'), findsOneWidget);

      // Acceptance 2: no OBD2 entry point on this screen — the
      // chip, the bottom-sheet title, and the OBD-II tile labels
      // must all be absent.
      expect(find.text('Import from…'), findsNothing,
          reason: '#951 — the chip wrapper was reverted.');
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('OBD-II adapter'), findsNothing,
          reason: '#951 — OBD-II import path removed from this screen.');
      expect(find.text('Import fill-up data'), findsNothing,
          reason: '#951 — bottom-sheet wrapper is gone, no title to render.');
    });

    testWidgets('tapping Receipt invokes scanReceipt only', (tester) async {
      final fake = _RoutingScanService();
      await pumpApp(
        tester,
        AddFillUpScreen(scanService: fake),
        overrides: _withVehicle,
      );

      await tester.tap(find.byKey(const Key('import_receipt_button')));
      // Drive frames manually — the screen sets _scanning=true before
      // awaiting the (instantly-returning) fake; pumpAndSettle would
      // race the spinner-disabled rebuild.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(fake.receiptCalls, 1,
          reason: 'Receipt button must call scanReceipt().');
      expect(fake.pumpCalls, 0,
          reason: 'Receipt button must NOT call scanPumpDisplay().');
    });

    testWidgets('tapping Pump display invokes scanPumpDisplay only',
        (tester) async {
      final fake = _RoutingScanService();
      await pumpApp(
        tester,
        AddFillUpScreen(scanService: fake),
        overrides: _withVehicle,
      );

      await tester.tap(find.byKey(const Key('import_pump_button')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(fake.pumpCalls, 1,
          reason: 'Pump display button must call scanPumpDisplay().');
      expect(fake.receiptCalls, 0,
          reason: 'Pump display button must NOT call scanReceipt().');
    });
  });
}
