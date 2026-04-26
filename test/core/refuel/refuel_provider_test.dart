import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/refuel_provider.dart';

void main() {
  group('RefuelProvider', () {
    test('value equality compares name and kind', () {
      const a =
          RefuelProvider(name: 'Total', kind: RefuelProviderKind.fuel);
      const b =
          RefuelProvider(name: 'Total', kind: RefuelProviderKind.fuel);
      const c =
          RefuelProvider(name: 'Total', kind: RefuelProviderKind.ev);
      const d =
          RefuelProvider(name: 'Aral', kind: RefuelProviderKind.fuel);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c))); // kind differs
      expect(a, isNot(equals(d))); // name differs
    });

    test('unknown is a const sentinel with empty name', () {
      const first = RefuelProvider.unknown;
      const second = RefuelProvider.unknown;

      expect(identical(first, second), isTrue,
          reason: 'unknown must be a const singleton');
      expect(first.name, isEmpty);
      // Default kind must be deterministic — fuel is the documented choice.
      expect(first.kind, RefuelProviderKind.fuel);
    });

    test('all RefuelProviderKind cases are exhausted', () {
      // Static guard: if a future phase adds a new kind without
      // updating this assertion, the test fails and forces a deliberate
      // review of every consumer that switch-cased on the enum.
      expect(RefuelProviderKind.values, hasLength(3));
      expect(
        RefuelProviderKind.values,
        containsAll(<RefuelProviderKind>[
          RefuelProviderKind.fuel,
          RefuelProviderKind.ev,
          RefuelProviderKind.both,
        ]),
      );
    });

    test('toString includes name and kind for debug logs', () {
      const p =
          RefuelProvider(name: 'Ionity', kind: RefuelProviderKind.ev);
      final s = p.toString();
      expect(s, contains('Ionity'));
      expect(s, contains('ev'));
    });
  });
}
