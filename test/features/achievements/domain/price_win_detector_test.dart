import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/achievements/domain/price_win_detector.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Stub repo that returns a caller-controlled `avg` per (station,
/// fuel) pair. Keeps the predicate under test fully isolated from
/// Hive + the real `getHistory` implementation.
class _StubRepo implements PriceHistoryRepository {
  final Map<String, double?> avgByKey;
  _StubRepo(this.avgByKey);

  @override
  PriceStats getStats(String stationId, FuelType fuelType, {int days = 7}) {
    final avg = avgByKey['$stationId:${fuelType.apiValue}'];
    return PriceStats(avg: avg);
  }

  @override
  dynamic noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

FillUp _fillUp({
  String id = 'a',
  String? stationId = 'st1',
  double liters = 40,
  double totalCost = 60,
  FuelType fuelType = FuelType.e10,
}) {
  return FillUp(
    id: id,
    stationId: stationId,
    stationName: 'Station',
    date: DateTime(2026, 1, 1),
    liters: liters,
    totalCost: totalCost,
    odometerKm: 10000,
    fuelType: fuelType,
  );
}

void main() {
  group('isPriceWin (#781)', () {
    test('no stationId on the fill-up → never a win (the user did '
        'not attribute it to a pump; no avg to compare to)', () {
      final repo = _StubRepo({'st1:e10': 1.80});
      final win = isPriceWin(_fillUp(stationId: null), repo);
      expect(win, isFalse);
    });

    test('zero pricePerLiter → not a win (malformed entry)', () {
      final repo = _StubRepo({'st1:e10': 1.80});
      final win = isPriceWin(
        _fillUp(liters: 40, totalCost: 0),
        repo,
      );
      expect(win, isFalse);
    });

    test('station has no history yet → not a win (avg unknown)', () {
      final repo = _StubRepo({});
      final win = isPriceWin(_fillUp(), repo);
      expect(win, isFalse);
    });

    test('avg 0 → not a win — defensive against empty or broken '
        'history payloads', () {
      final repo = _StubRepo({'st1:e10': 0.0});
      final win = isPriceWin(_fillUp(), repo);
      expect(win, isFalse);
    });

    test('paid exactly equals avg → not a win (0 % margin)', () {
      final repo = _StubRepo({'st1:e10': 1.50});
      final win = isPriceWin(
        _fillUp(liters: 40, totalCost: 60), // 1.50 per L
        repo,
      );
      expect(win, isFalse);
    });

    test('paid 4 % below avg → not a win (below the 5 % threshold)',
        () {
      final repo = _StubRepo({'st1:e10': 1.50});
      // pricePerLiter = 60 / 41.67 ≈ 1.440 → 4 % below.
      final win = isPriceWin(
        _fillUp(liters: 41.67, totalCost: 60),
        repo,
      );
      expect(win, isFalse);
    });

    test('paid 6 % below avg → wins (beats the 5 % threshold)', () {
      final repo = _StubRepo({'st1:e10': 1.50});
      // pricePerLiter = 1.41 → 6 % below.
      final win = isPriceWin(
        _fillUp(liters: 42.553, totalCost: 60),
        repo,
      );
      expect(win, isTrue);
    });

    test('custom threshold is respected — stricter margin can '
        'disqualify a 6 % beat', () {
      final repo = _StubRepo({'st1:e10': 1.50});
      final win = isPriceWin(
        _fillUp(liters: 42.553, totalCost: 60),
        repo,
        winMarginPct: 0.08,
      );
      expect(win, isFalse);
    });

    test('fuel-type mismatch looks up a different avg — diesel '
        'fill-up against e10 avg returns 0 and does not win', () {
      final repo = _StubRepo({'st1:e10': 1.50, 'st1:diesel': 0.0});
      final win = isPriceWin(
        _fillUp(fuelType: FuelType.diesel),
        repo,
      );
      expect(win, isFalse);
    });
  });

  group('anyPriceWin (#781)', () {
    test('empty list → false', () {
      final repo = _StubRepo({'st1:e10': 1.50});
      expect(anyPriceWin(const [], repo), isFalse);
    });

    test('none win → false; one wins → true (short-circuits on the '
        'first)', () {
      final repo = _StubRepo({'st1:e10': 1.50, 'st2:e10': 1.50});
      final losers = [
        _fillUp(id: 'a', stationId: 'st1', liters: 40, totalCost: 60),
        _fillUp(id: 'b', stationId: 'st2', liters: 40, totalCost: 60),
      ];
      expect(anyPriceWin(losers, repo), isFalse);

      final withWinner = [
        ...losers,
        _fillUp(id: 'c', stationId: 'st1', liters: 43, totalCost: 60),
      ];
      expect(anyPriceWin(withWinner, repo), isTrue);
    });
  });
}
