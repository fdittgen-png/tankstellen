// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/core/permissions/permission_rationale_dialog.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_parser.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_scan_service.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/fake_settings_storage.dart';
import '../../../../helpers/pump_app.dart';

/// #951 — TDD acceptance test for the "restore import buttons" rollback.
/// The single "Import from…" chip + bottom-sheet was reverted because
/// the OBD-II tile inside the sheet returned null for the odometer on
/// real Peugeot hardware (PID 0xA6 is unsupported by the generic ELM327
/// BLE clone the user has). Until that gap is closed by a
/// brand-specific UDS service $22 PID, the OBD-II import path is hidden
/// from this screen.
///
/// (#3765 removed the sibling pump-display scan button; the receipt
/// button is the remaining camera entry point.)
///
/// Acceptance:
///   1. The Receipt import button is present.
///   2. The OBD2 import path is NOT shown on this screen.
///   3. Tapping the button triggers scanReceipt.
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

/// #2110 — force-enable the receipt OCR flag so the button renders.
class _ReceiptOcrEnabled extends FeatureFlags {
  @override
  Set<Feature> build() => {
        Feature.addFillUpOcrReceipt,
      };
}

final _withVehicle = <Object>[
  vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
  featureFlagsProvider.overrideWith(() => _ReceiptOcrEnabled()),
  // #3872 — the receipt scan gates on the once-per-install camera
  // rationale; pre-acknowledged so the existing tests keep exercising the
  // scan BEHIND it (the fresh-install case has its own test below).
  settingsStorageProvider.overrideWithValue(
    FakeSettingsStorage.rationalesShown(),
  ),
];

/// Records which scan path the screen invoked so the test can assert
/// that tapping the button routes to the expected entry point. The
/// method short-circuits (returns null) so the screen's finally-block
/// flips its busy flag back off and the test can settle.
class _RoutingScanService extends ReceiptScanService {
  _RoutingScanService()
      : super(
          picker: _NoopPicker(),
          recognizer: _NoopRecognizer(),
          parser: const ReceiptParser(),
        );

  int receiptCalls = 0;

  @override
  Future<ReceiptScanOutcome?> scanReceipt({
    String? country,
    String? brand,
    OcrTraceRecorder? trace,
  }) async {
    receiptCalls++;
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
  group('AddFillUpScreen — restored import button (#951)', () {
    testWidgets('renders the Receipt button; OBD2 and pump absent',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      // Acceptance 1: the button is present, keyed for stable lookup.
      expect(
        find.byKey(const Key('import_receipt_button')),
        findsOneWidget,
        reason: 'Receipt button must be visible at the top of the form.',
      );
      expect(find.text('Receipt'), findsOneWidget);

      // #3765 — the pump-display scanner is gone for good.
      expect(find.byKey(const Key('import_pump_button')), findsNothing,
          reason: '#3765 — pump-display scan button removed.');
      expect(find.text('Pump display'), findsNothing);

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

    testWidgets('tapping Receipt invokes scanReceipt', (tester) async {
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
    });

    testWidgets(
        '#3872 — a fresh install sees the camera rationale BEFORE the scan '
        '(= the OS camera prompt); Continue then runs scanReceipt', (
      tester,
    ) async {
      final fake = _RoutingScanService();
      final storage = FakeSettingsStorage();
      await pumpApp(
        tester,
        AddFillUpScreen(scanService: fake),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          featureFlagsProvider.overrideWith(() => _ReceiptOcrEnabled()),
          settingsStorageProvider.overrideWithValue(storage),
        ],
      );

      await tester.tap(find.byKey(const Key('import_receipt_button')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Rationale up, scan (= OS prompt) NOT yet started.
      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
      expect(fake.receiptCalls, 0);

      await tester.tap(find.byKey(PermissionRationaleDialog.continueKey));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsNothing);
      expect(fake.receiptCalls, 1,
          reason: 'Continue must always proceed to the scan (5.1.1(iv)).');
      expect(
        PermissionRationaleDialog.hasBeenShown(
          storage,
          PermissionRationaleKind.camera,
        ),
        isTrue,
      );
    });
  });
}
