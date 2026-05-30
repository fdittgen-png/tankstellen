// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/domain/entities/fill_up_guidance.dart';
import 'package:tankstellen/features/price_history/providers/fill_up_guidance_provider.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests for the feature-gate wiring of [fillUpGuidanceProvider] (#1543).
///
/// The heuristic maths is covered by
/// `fill_up_guidance_predictor_test.dart`; here we only exercise the
/// provider's responsibilities: the feature-flag gate (incl. the
/// `requires: {priceHistory}` cascade) and the thin-data → null
/// collapse.
void main() {
  ProviderContainer makeContainer({
    required Set<Feature> enabled,
    required List<PriceRecord> records,
  }) {
    final c = ProviderContainer(overrides: [
      priceHistoryRepositoryProvider
          .overrideWithValue(_FakePriceHistoryRepository(records)),
      featureFlagsProvider.overrideWith(() => _TestFeatureFlags(enabled)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// 20 dated e10 readings — enough to clear the predictor's sample
  /// threshold and with enough spread to yield an actionable verdict.
  List<PriceRecord> richHistory() {
    final base = DateTime.now();
    return [
      // current — clearly cheap so the verdict is goodTimeNow.
      PriceRecord(stationId: 's1', recordedAt: base, e10: 1.20),
      for (int i = 1; i < 20; i++)
        PriceRecord(
          stationId: 's1',
          recordedAt: base.subtract(Duration(days: i)),
          e10: 1.60,
        ),
    ];
  }

  group('feature-flag gate', () {
    test('flag off → null even with rich history', () {
      final c = makeContainer(
        enabled: {Feature.priceHistory}, // prediction flag NOT enabled
        records: richHistory(),
      );
      expect(
        c.read(fillUpGuidanceProvider('s1', FuelType.e10)),
        isNull,
      );
    });

    test('flag on but priceHistory prerequisite off → null (cascade)', () {
      final c = makeContainer(
        // tflitePricePrediction set but its required priceHistory is not,
        // so isEffectivelyEnabled cascades to false.
        enabled: {Feature.tflitePricePrediction},
        records: richHistory(),
      );
      expect(
        c.read(fillUpGuidanceProvider('s1', FuelType.e10)),
        isNull,
      );
    });

    test('flag + prerequisite on → non-null actionable guidance', () {
      final c = makeContainer(
        enabled: {Feature.priceHistory, Feature.tflitePricePrediction},
        records: richHistory(),
      );
      final g = c.read(fillUpGuidanceProvider('s1', FuelType.e10));
      expect(g, isNotNull);
      expect(g!.hasGuidance, isTrue);
      expect(g.kind, FillUpGuidanceKind.goodTimeNow);
    });
  });

  group('thin-data collapse', () {
    test('flag on but too few readings → null (no claim from thin data)', () {
      final base = DateTime.now();
      final c = makeContainer(
        enabled: {Feature.priceHistory, Feature.tflitePricePrediction},
        records: [
          for (int i = 0; i < 5; i++)
            PriceRecord(
              stationId: 's1',
              recordedAt: base.subtract(Duration(days: i)),
              e10: 1.50,
            ),
        ],
      );
      expect(
        c.read(fillUpGuidanceProvider('s1', FuelType.e10)),
        isNull,
      );
    });

    test('flag on but wrong fuel type → null', () {
      final c = makeContainer(
        enabled: {Feature.priceHistory, Feature.tflitePricePrediction},
        records: richHistory(), // e10 only
      );
      expect(
        c.read(fillUpGuidanceProvider('s1', FuelType.diesel)),
        isNull,
      );
    });
  });
}

/// Fake repository returning a fixed record list without storage.
class _FakePriceHistoryRepository extends PriceHistoryRepository {
  final List<PriceRecord> _records;
  _FakePriceHistoryRepository(this._records) : super(_NullStorage());

  @override
  List<PriceRecord> getHistory(String stationId, {int days = 30}) =>
      List.of(_records);
}

/// Notifier override returning a fixed enabled-set for the test.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags(this._initial);
  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};
}

/// Stub storage — never invoked because [getHistory] is overridden.
class _NullStorage implements PriceHistoryStorage {
  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) => const [];
  @override
  Future<void> savePriceRecords(
      String stationId, List<Map<String, dynamic>> records) async {}
  @override
  List<String> getPriceHistoryKeys() => const [];
  @override
  Future<void> clearPriceHistoryForStation(String stationId) async {}
  @override
  Future<void> clearPriceHistory() async {}
  @override
  int get priceHistoryEntryCount => 0;
}
