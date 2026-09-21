// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/data/repositories/fill_up_repository.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_up_scan_handlers.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_up_share_scan_handlers.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_parser.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_scan_outcomes.dart';

/// #4428 — the field report itself, as a test.
///
/// A driver with an **EUR** profile refuelled at Piccadilly-SOCAR in
/// Gandria (CH) on 2026-09-20 and paid **CHF 51,73** by card. The app
/// stored EUR 51,73: ~6-7 % understated, and invisible to the #4364
/// currency segregation because the row asserted it was EUR.
const String _gandriaReceipt = '''
Piccadilly-SOCAR
Gandria
20.09.2026
SP95   25,61 L   CHF 2,020/L
Total  CHF 51,73
Netto 47,85
MWST 8,10 % 3,88
VISA DEBIT **** 3014
''';

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

/// Records what the prefill body writes back, standing in for the
/// screen's `setState` calls.
class _CapturedForm {
  final litersCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  DateTime? date;
  FuelType? fuelType;
  double? scannedPricePerLiter;
  String? scannedCurrency;
  ReceiptScanOutcome? lastScan;

  FillUpScanHostState get host => FillUpScanHostState(
        litersCtrl: litersCtrl,
        costCtrl: costCtrl,
        vehicleId: null,
        readService: () => null,
        writeService: (_) {},
        setScanning: (_) {},
        setDate: (d) => date = d,
        setFuelType: (f) => fuelType = f,
        setScannedPricePerLiter: (p) => scannedPricePerLiter = p,
        setScannedCurrency: (c) => scannedCurrency = c,
        setLastScan: (o) => lastScan = o,
        isMounted: () => true,
        activeCountry: 'DE',
      );

  void dispose() {
    litersCtrl.dispose();
    costCtrl.dispose();
  }
}

FillUp _fill({
  required String id,
  required double liters,
  required double cost,
  required double odo,
  required DateTime date,
  String? currency,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: FuelType.e10,
      currency: currency,
    );

void main() {
  setUp(() => PriceFormatter.setCountry('DE'));
  tearDown(() => PriceFormatter.setCountry('FR'));

  group('the receipt is read in the currency it prints', () {
    test('the paper says CHF three times, so the parse says CHF', () {
      final parsed = const ReceiptParser().parse(_gandriaReceipt);
      expect(parsed.currency, 'CHF');
    });

    test('the amounts come off the paper unchanged', () {
      final parsed = const ReceiptParser().parse(_gandriaReceipt);
      expect(parsed.liters, closeTo(25.61, 0.001));
      expect(parsed.totalCost, closeTo(51.73, 0.001));
      expect(parsed.pricePerLiter, closeTo(2.020, 0.002));
    });

    test('an EUR profile does not turn the read into EUR', () {
      // The profile only supplies a FALLBACK for paper that names no
      // currency at all; an explicit code always wins.
      final parsed = const ReceiptParser().parse(_gandriaReceipt);
      expect(parsed.currency, isNot('EUR'));
    });
  });

  group('the prefill carries the currency to the form', () {
    late _CapturedForm form;

    setUp(() => form = _CapturedForm());
    tearDown(() => form.dispose());

    test('a CHF receipt prefills CHF alongside the numbers', () {
      final parsed = const ReceiptParser().parse(_gandriaReceipt);
      applyReceiptOutcome(
        form.host,
        ReceiptScanOutcome(
          parse: parsed,
          ocrText: _gandriaReceipt,
          imagePath: '',
        ),
      );

      expect(form.scannedCurrency, 'CHF');
      expect(form.litersCtrl.text, '25.61');
      expect(form.costCtrl.text, '51.73');
      expect(form.scannedPricePerLiter, closeTo(2.020, 0.002));
    });

    test('a receipt that names no currency prefills none', () {
      applyReceiptOutcome(
        form.host,
        const ReceiptScanOutcome(
          parse: ReceiptParseResult(liters: 30, totalCost: 45),
          ocrText: '30 L 45',
          imagePath: '',
        ),
      );
      expect(form.scannedCurrency, isNull);
    });
  });

  group('the record survives the store', () {
    late FillUpRepository repo;

    setUp(() => repo = FillUpRepository(_FakeSettingsStorage()));

    test('CHF 51,73 / 25,61 L round-trips as CHF, not EUR', () async {
      await repo.save(_fill(
        id: 'gandria',
        liters: 25.61,
        cost: 51.73,
        odo: 120450,
        date: DateTime(2026, 9, 20),
        currency: 'CHF',
      ));

      final stored = repo.getAll().single;
      expect(stored.currency, 'CHF');
      expect(stored.totalCost, 51.73);
      expect(stored.liters, 25.61);
      expect(stored.pricePerLiter, closeTo(2.0199, 0.001));
    });
  });

  test('consumption is unaffected by the currency — litres are litres', () {
    // Acceptance box 2: the L/100 km a foreign fill produces must be
    // identical to the same litres logged at home. Only money needs
    // converting; volume and distance never did.
    ConsumptionStats statsIn(String currency) => ConsumptionStats.fromFillUps([
          _fill(
            id: 'a',
            liters: 40,
            cost: 60,
            odo: 120000,
            date: DateTime(2026, 9, 1),
            currency: currency,
          ),
          _fill(
            id: 'b',
            liters: 25.61,
            cost: 51.73,
            odo: 120450,
            date: DateTime(2026, 9, 20),
            currency: currency,
          ),
        ]);

    final abroad = statsIn('CHF');
    final home = statsIn('EUR');
    expect(abroad.avgConsumptionL100km, home.avgConsumptionL100km);
    expect(abroad.totalLiters, home.totalLiters);
    expect(abroad.totalDistanceKm, home.totalDistanceKm);
  });

  test('a CHF fill in an EUR history withholds the total, never sums it',
      () {
    final mixed = ConsumptionStats.fromFillUps([
      _fill(
        id: 'home',
        liters: 40,
        cost: 60,
        odo: 120000,
        date: DateTime(2026, 9, 1),
        currency: 'EUR',
      ),
      _fill(
        id: 'gandria',
        liters: 25.61,
        cost: 51.73,
        odo: 120450,
        date: DateTime(2026, 9, 20),
        currency: 'CHF',
      ),
    ]);

    expect(mixed.totalSpent, isNull, reason: '60 + 51.73 is not 111.73 of '
        'anything');
    expect(mixed.spend.amountIn('EUR'), 60);
    expect(mixed.spend.amountIn('CHF'), 51.73);
  });
}
