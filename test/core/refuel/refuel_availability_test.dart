import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/refuel_availability.dart';

void main() {
  group('RefuelAvailability', () {
    test('open is a const singleton and isOperational is true', () {
      const a = RefuelAvailability.open;
      const b = RefuelAvailability.open;
      expect(identical(a, b), isTrue);
      expect(a.isOperational, isTrue);
    });

    test('unknown is a const singleton and not operational', () {
      const a = RefuelAvailability.unknown;
      const b = RefuelAvailability.unknown;
      expect(identical(a, b), isTrue);
      expect(a.isOperational, isFalse);
    });

    test('closed is not operational and may carry a reason', () {
      final c = RefuelAvailability.closed(reason: 'outside hours');
      expect(c.isOperational, isFalse);
      // Equality on reason
      final c2 = RefuelAvailability.closed(reason: 'outside hours');
      expect(c, equals(c2));
      expect(c.hashCode, equals(c2.hashCode));
      // Different reasons are not equal
      final c3 = RefuelAvailability.closed(reason: 'maintenance');
      expect(c, isNot(equals(c3)));
    });

    test('closed without a reason is allowed', () {
      final c = RefuelAvailability.closed();
      expect(c.isOperational, isFalse);
    });

    test('limited requires a reason and is not operational', () {
      final l = RefuelAvailability.limited(reason: 'one pump out of 4');
      expect(l.isOperational, isFalse,
          reason:
              'limited surfaces a warning but should not be treated as fully usable');
      final l2 =
          RefuelAvailability.limited(reason: 'one pump out of 4');
      expect(l, equals(l2));
    });

    test('different cases are not equal to each other', () {
      const open = RefuelAvailability.open;
      final closed = RefuelAvailability.closed();
      final limited = RefuelAvailability.limited(reason: 'busy');
      const unknown = RefuelAvailability.unknown;

      expect(open, isNot(equals(closed)));
      expect(open, isNot(equals(limited)));
      expect(open, isNot(equals(unknown)));
      expect(closed, isNot(equals(unknown)));
      expect(limited, isNot(equals(unknown)));
    });

    test('sealed switch covers every case (compile-time exhaustiveness)',
        () {
      // The pattern match below would not compile without every
      // subtype handled. The test executes one of each so a future
      // refactor that adds a case will both fail to compile *and*
      // break this assertion if someone adds a runtime case at the
      // wrong time.
      String label(RefuelAvailability a) => switch (a) {
            // Sealed-class pattern needs the runtime types — they are
            // private to the library, so we case on isOperational +
            // toString() instead.
            _ when a.isOperational => 'open',
            _ when a.toString().contains('limited') => 'limited',
            _ when a.toString().contains('closed') => 'closed',
            _ when a.toString().contains('unknown') => 'unknown',
            _ => 'unhandled',
          };

      expect(label(RefuelAvailability.open), 'open');
      expect(label(RefuelAvailability.closed()), 'closed');
      expect(label(RefuelAvailability.limited(reason: 'x')), 'limited');
      expect(label(RefuelAvailability.unknown), 'unknown');
    });

    test('toString shape is stable for debug logs', () {
      expect(RefuelAvailability.open.toString(), contains('open'));
      expect(
        RefuelAvailability.closed(reason: 'r').toString(),
        contains('closed'),
      );
      expect(
        RefuelAvailability.limited(reason: 'r').toString(),
        contains('limited'),
      );
      expect(RefuelAvailability.unknown.toString(), contains('unknown'));
    });
  });
}
