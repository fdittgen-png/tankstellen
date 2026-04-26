import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/fill_up_auto_cost_calculator.dart';

/// Unit tests for the auto-cost computation extracted from
/// `add_fill_up_screen.dart` (#563 refactor).
///
/// The contract:
///   * Recompute when liters parses to > 0 AND the cost field is
///     either empty or matches the previous auto-fill (so the user's
///     manually-typed cost is never clobbered).
///   * Return the formatted "L * price" string in the controller-
///     ready 2dp format.
///   * Return null when liters is unparseable / non-positive, or when
///     the user has typed a custom cost.
void main() {
  group('FillUpAutoCostCalculator.recompute', () {
    test('returns formatted cost when liters and price are positive', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 1.859);
      expect(
        calc.recompute(litersText: '40', costText: ''),
        equals('74.36'),
      );
    });

    test('accepts comma as decimal separator (FR/DE locale)', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      expect(
        calc.recompute(litersText: '12,5', costText: ''),
        equals('25.00'),
      );
    });

    test('returns null when liters is empty', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      expect(calc.recompute(litersText: '', costText: ''), isNull);
    });

    test('returns null when liters is unparseable', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      expect(calc.recompute(litersText: 'abc', costText: ''), isNull);
    });

    test('returns null when liters is zero or negative', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      expect(calc.recompute(litersText: '0', costText: ''), isNull);
      expect(calc.recompute(litersText: '-5', costText: ''), isNull);
    });

    test('returns null when the user has typed a custom cost', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      // First call seeds the auto-fill at 20.00.
      expect(
        calc.recompute(litersText: '10', costText: ''),
        equals('20.00'),
      );
      // The user then types 99.99 — a subsequent recompute (e.g.
      // because liters changed) must NOT clobber the user's value.
      expect(
        calc.recompute(litersText: '15', costText: '99.99'),
        isNull,
      );
    });

    test('overwrites a stale auto-fill when liters changes', () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      // Seed the cost at 20.00 from 10 L.
      expect(
        calc.recompute(litersText: '10', costText: ''),
        equals('20.00'),
      );
      // Liters bumped to 15 — the cost field still shows the prior
      // auto-fill (20.00), so the calculator may overwrite it.
      expect(
        calc.recompute(litersText: '15', costText: '20.00'),
        equals('30.00'),
      );
    });

    test('updates internal lastAutoCost so the next recompute can compare',
        () {
      final calc = FillUpAutoCostCalculator(pricePerLiter: 2.0);
      // Seed 20.00, then re-seed via the previous-auto path at 30.00.
      expect(
        calc.recompute(litersText: '10', costText: ''),
        equals('20.00'),
      );
      expect(
        calc.recompute(litersText: '15', costText: '20.00'),
        equals('30.00'),
      );
      // After two seeds the lastAutoCost must now match the *latest*
      // 30.00 — typing 31.00 manually then bumping liters should be
      // treated as a user override, not a stale auto-fill.
      expect(
        calc.recompute(litersText: '20', costText: '31.00'),
        isNull,
      );
    });
  });
}
