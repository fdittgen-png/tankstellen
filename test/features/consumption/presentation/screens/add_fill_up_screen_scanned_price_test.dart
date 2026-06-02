// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// Seam test for #2689 — e-receipt Phase 1.
///
/// The receipt parser already extracts `pricePerLiter`, but before
/// #2689 the scan→save path *discarded* it and `FillUp` only ever
/// *computed* price/L from `totalCost / liters`. This test drives the
/// real screen through the real `runReceiptScan` handler with a fake
/// [ReceiptScanService] that returns a canned [ReceiptParseResult] (the
/// exact `1.999 €/L` the OCR would read), then taps Save and asserts the
/// persisted [FillUp.scannedPricePerLiter] is the verbatim scanned price.
///
/// RED on master (the field doesn't exist + the value is discarded);
/// GREEN once the plumbing threads `result.pricePerLiter` through to the
/// saved FillUp. Structural — no goldens.

const _stubVehicle = VehicleProfile(
  id: 'stub-vehicle',
  name: 'Stub Car',
  type: VehicleType.combustion,
);

class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [_stubVehicle];
}

/// Captures every fill-up handed to `add` so the test can inspect the
/// persisted `scannedPricePerLiter`. Bypasses the production `add`
/// pipeline (repo, calibration, link-window) — those have their own
/// coverage; this pins only the screen-side scan→persist contract.
class _CapturingFillUpList extends FillUpList {
  final List<FillUp> captured = [];

  @override
  List<FillUp> build() => const [];

  @override
  Future<void> add(FillUp fillUp) async {
    captured.add(fillUp);
  }
}

/// Minimal fake [TextRecognizer] / [ImagePicker] so the real
/// [ReceiptScanService] constructor doesn't reach for the ML Kit native
/// handle — never called because the fake short-circuits `scanReceipt`.
class _NoopRecognizer extends TextRecognizer {
  _NoopRecognizer();

  @override
  Future<RecognizedText> processImage(InputImage input) async =>
      RecognizedText(text: '', blocks: const []);

  @override
  Future<void> close() async {}
}

class _NoopPicker extends ImagePicker {}

/// Fake [ReceiptScanService] that bypasses the camera + ML Kit and
/// returns a pre-canned [ReceiptScanOutcome] for `scanReceipt`. The
/// canned parse carries the four fields the scan now persists — a
/// verbatim `1.999` unit price, E10 grade, 5.24 L and a total.
class _FakeReceiptScanService extends ReceiptScanService {
  _FakeReceiptScanService(this._result)
      : super(
          picker: _NoopPicker(),
          recognizer: _NoopRecognizer(),
          parser: const ReceiptParser(),
        );

  final ReceiptParseResult _result;
  int disposeCalls = 0;

  @override
  Future<ReceiptScanOutcome?> scanReceipt({
    String? country,
    String? brand,
    OcrTraceRecorder? trace,
  }) async {
    return ReceiptScanOutcome(
      parse: _result,
      ocrText: 'fixture',
      imagePath: '/tmp/fake-receipt.jpg',
    );
  }

  @override
  void dispose() {
    // No-op — the test owns this fake's lifecycle.
    disposeCalls++;
  }
}

/// `Feature.addFillUpOcrReceipt` is default-on, but force-enable it so
/// the receipt button renders regardless of the env default.
class _ReceiptOcrEnabled extends FeatureFlags {
  @override
  Set<Feature> build() => {Feature.addFillUpOcrReceipt};
}

Future<void> _pumpScreenInRouter(
  WidgetTester tester, {
  required List<Object> overrides,
  required AddFillUpScreen screen,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ctx.push('/add'),
                child: const Text('open-form'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(path: '/add', builder: (context, state) => screen),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open-form'));
  await tester.pumpAndSettle();
}

Finder _fieldByLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(FillUpNumericField),
    );

void _typeInto(WidgetTester tester, String label, String value) {
  final field = tester.widget<TextField>(
    find.descendant(
      of: _fieldByLabel(label),
      matching: find.byType(TextField),
    ),
  );
  field.controller!.text = value;
}

void main() {
  silenceErrorLoggerSpool();

  group('AddFillUpScreen — scanned price persistence (#2689)', () {
    testWidgets(
        'a receipt scan reading 1.999 €/L persists '
        'FillUp.scannedPricePerLiter == 1.999', (tester) async {
      final fillUpList = _CapturingFillUpList();
      final fake = _FakeReceiptScanService(
        const ReceiptParseResult(
          liters: 5.24,
          totalCost: 10.47,
          pricePerLiter: 1.999,
          fuelType: FuelType.e10,
        ),
      );

      await _pumpScreenInRouter(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          fillUpListProvider.overrideWith(() => fillUpList),
          featureFlagsProvider.overrideWith(() => _ReceiptOcrEnabled()),
        ],
        screen: AddFillUpScreen(scanService: fake),
      );

      // Run the real scan handler — it pre-fills liters/cost/date/grade
      // AND (post-#2689) captures the scanned unit price.
      await tester.tap(find.byKey(const Key('import_receipt_button')));
      await tester.pumpAndSettle();

      // The scan fills liters + total; the odometer is the only field
      // the user must still type before a valid save.
      _typeInto(tester, 'Odometer (km)', '12345');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fillUpList.captured, hasLength(1));
      final saved = fillUpList.captured.single;
      // The load-bearing assertion: the exact scanned price is stored,
      // not re-derived from totalCost / liters.
      expect(saved.scannedPricePerLiter, closeTo(1.999, 0.0001));
      // The computed getter prefers the scanned value over the quotient.
      expect(saved.pricePerLiter, closeTo(1.999, 0.0001));
      // The other scanned fields still flow (no regression).
      expect(saved.liters, closeTo(5.24, 0.001));
      expect(saved.totalCost, closeTo(10.47, 0.001));
      expect(saved.fuelType, FuelType.e10);
    });

    testWidgets(
        'a manual entry (no scan) leaves scannedPricePerLiter null and '
        'falls back to the computed quotient', (tester) async {
      final fillUpList = _CapturingFillUpList();

      await _pumpScreenInRouter(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          fillUpListProvider.overrideWith(() => fillUpList),
          featureFlagsProvider.overrideWith(() => _ReceiptOcrEnabled()),
        ],
        screen: const AddFillUpScreen(),
      );

      _typeInto(tester, 'Liters', '40');
      _typeInto(tester, 'Total cost', '70');
      _typeInto(tester, 'Odometer (km)', '12345');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fillUpList.captured, hasLength(1));
      final saved = fillUpList.captured.single;
      expect(saved.scannedPricePerLiter, isNull);
      // 70 / 40 = 1.75 — the computed fallback.
      expect(saved.pricePerLiter, closeTo(1.75, 0.0001));
    });
  });
}
