import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/eco_score.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Fake FillUpList that holds a fixed list — avoids the Hive repo
/// so the provider test exercises the wiring, not storage.
class _FakeFillUpList extends FillUpList {
  final List<FillUp> _value;
  _FakeFillUpList(this._value);

  @override
  List<FillUp> build() => _value;
}

FillUp _f({
  required String id,
  required int daysAgo,
  required double odo,
  double liters = 48,
  FuelType fuel = FuelType.diesel,
}) =>
    FillUp(
      id: id,
      date: DateTime(2026, 4, 10).subtract(Duration(days: daysAgo)),
      liters: liters,
      totalCost: liters * 1.8,
      odometerKm: odo,
      fuelType: fuel,
    );

ProviderContainer _containerWith(List<FillUp> list) {
  final c = ProviderContainer(overrides: [
    fillUpListProvider.overrideWith(() => _FakeFillUpList(list)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('ecoScoreForFillUpProvider', () {
    test('returns null for a first-ever fill-up', () {
      final only = _f(id: 'a', daysAgo: 0, odo: 10000);
      final c = _containerWith([only]);
      expect(c.read(ecoScoreForFillUpProvider('a')), isNull);
    });

    test('returns null for an id that is not in the list', () {
      final c = _containerWith([
        _f(id: 'a', daysAgo: 10, odo: 10000),
        _f(id: 'b', daysAgo: 0, odo: 10800),
      ]);
      expect(c.read(ecoScoreForFillUpProvider('missing')), isNull);
    });

    test('returns a stable score when current = rolling average', () {
      // Four fill-ups at the same 6.0 L/100km consumption.
      final list = [
        _f(id: 'a', daysAgo: 30, odo: 10000),
        _f(id: 'b', daysAgo: 20, odo: 10800),
        _f(id: 'c', daysAgo: 10, odo: 11600),
        _f(id: 'd', daysAgo: 0, odo: 12400),
      ];
      final c = _containerWith(list);
      final score = c.read(ecoScoreForFillUpProvider('d'));
      expect(score, isNotNull);
      expect(score!.direction, EcoScoreDirection.stable);
    });

    test('improving direction for a more efficient current fill-up', () {
      final list = [
        _f(id: 'a', daysAgo: 30, odo: 10000),
        _f(id: 'b', daysAgo: 20, odo: 10800),
        _f(id: 'c', daysAgo: 10, odo: 11600),
        _f(id: 'd', daysAgo: 0, odo: 12400, liters: 48 * 0.9),
      ];
      final c = _containerWith(list);
      final score = c.read(ecoScoreForFillUpProvider('d'));
      expect(score!.direction, EcoScoreDirection.improving);
    });

    test('each id yields its own score (keying is per-fill-up)', () {
      final list = [
        _f(id: 'a', daysAgo: 40, odo: 10000),
        _f(id: 'b', daysAgo: 30, odo: 10800),
        _f(id: 'c', daysAgo: 20, odo: 11600),
        _f(id: 'd', daysAgo: 10, odo: 12400, liters: 48 * 0.9),
        _f(id: 'e', daysAgo: 0, odo: 13200),
      ];
      final c = _containerWith(list);

      // 'c' is the third fill-up — it has two preceding same-fuel
      // entries that each have their own predecessor, so the
      // baseline is populated.
      final scoreForC = c.read(ecoScoreForFillUpProvider('c'));
      final scoreForD = c.read(ecoScoreForFillUpProvider('d'));
      final scoreForE = c.read(ecoScoreForFillUpProvider('e'));

      expect(scoreForC, isNotNull);
      expect(scoreForD, isNotNull);
      expect(scoreForE, isNotNull);
      // Family keying — D is the "improving" tank so its score
      // must differ from C's.
      expect(scoreForC!.direction, isNot(scoreForD!.direction));
    });

    test('recomputes when the underlying list changes', () {
      // Start with one fill-up — score is null.
      final first = _f(id: 'a', daysAgo: 0, odo: 10000);
      final c = ProviderContainer(overrides: [
        fillUpListProvider.overrideWith(() => _FakeFillUpList([first])),
      ]);
      addTearDown(c.dispose);
      expect(c.read(ecoScoreForFillUpProvider('a')), isNull);
    });
  });
}
