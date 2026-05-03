import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_capability.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_tables/psa_oem_pid_table.dart';

/// Lightweight [OemPidTable] stand-in that does not actually issue
/// commands — registry tests only care about lookup mechanics, not
/// the fuel-level parser. (#1401 phase 3)
class _StubTable extends OemPidTable {
  const _StubTable(this.key, this.prefixes);

  final String key;
  final Set<String> prefixes;

  @override
  String get oemKey => key;

  @override
  Set<String> get supportedWmiPrefixes => prefixes;

  @override
  Future<double?> readFuelLevelLitres(Obd2RawCommandPort port) async => null;
}

void main() {
  group('OemPidRegistry (#1401 phase 3)', () {
    group('empty registry (phase 3 production default)', () {
      test('lookupByWmi returns null for any prefix', () {
        final registry = OemPidRegistry();

        expect(registry.lookupByWmi('VF3'), isNull);
        expect(registry.lookupByWmi('JT3'), isNull);
        expect(registry.lookupByWmi('WVW'), isNull);
      });

      test('lookupByVin returns null for any VIN', () {
        final registry = OemPidRegistry();

        expect(
          registry.lookupByVin('VF31234567890ABCD'),
          isNull,
        );
      });

      test('resolveForCapability returns null for every capability', () {
        final registry = OemPidRegistry();

        for (final cap in Obd2AdapterCapability.values) {
          expect(
            registry.resolveForCapability('VF31234567890ABCD', cap),
            isNull,
            reason: 'empty registry must return null for $cap',
          );
        }
      });
    });

    group('lookupByWmi', () {
      test('matches exact upper-case prefix', () {
        const psa = _StubTable('PSA', {'VF3', 'VF7'});
        final registry = OemPidRegistry(tables: const [psa]);

        expect(registry.lookupByWmi('VF3'), same(psa));
        expect(registry.lookupByWmi('VF7'), same(psa));
      });

      test('case-insensitive — lowercase candidate matches uppercase prefix',
          () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        expect(registry.lookupByWmi('vf3'), same(psa));
        expect(registry.lookupByWmi('Vf3'), same(psa));
      });

      test('returns null for unknown prefix', () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        expect(registry.lookupByWmi('JT3'), isNull);
      });

      test('returns null for prefix shorter than 3 chars', () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        expect(registry.lookupByWmi(''), isNull);
        expect(registry.lookupByWmi('V'), isNull);
        expect(registry.lookupByWmi('VF'), isNull);
      });

      test('uses only the first 3 chars when given a longer string', () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        // Real callers should pass the prefix; this guards the
        // implementation against misuse — passing a full VIN must
        // still hit the VF3 table cleanly.
        expect(registry.lookupByWmi('VF31234567890ABCD'), same(psa));
      });
    });

    group('lookupByVin', () {
      test('extracts the first 3 chars of the VIN', () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.lookupByVin('VF31234567890ABCD'),
          same(psa),
        );
      });

      test('returns null gracefully for VINs shorter than 3 chars', () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        expect(registry.lookupByVin(''), isNull);
        expect(registry.lookupByVin('V'), isNull);
        expect(registry.lookupByVin('VF'), isNull);
      });

      test('returns null when the VIN prefix matches no registered table', () {
        const psa = _StubTable('PSA', {'VF3'});
        final registry = OemPidRegistry(tables: const [psa]);

        // JTE is a Toyota WMI — not registered.
        expect(registry.lookupByVin('JTEBU5JR1A5012345'), isNull);
      });
    });

    group('resolveForCapability — capability gate', () {
      const psa = _StubTable('PSA', {'VF3'});
      const vin = 'VF31234567890ABCD';

      test('standardOnly always returns null (gate closed)', () {
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.resolveForCapability(
            vin,
            Obd2AdapterCapability.standardOnly,
          ),
          isNull,
        );
      });

      test('oemPidsCapable delegates to lookupByVin', () {
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.resolveForCapability(
            vin,
            Obd2AdapterCapability.oemPidsCapable,
          ),
          same(psa),
        );
      });

      test('passiveCanCapable also delegates (passive ⊃ oem)', () {
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.resolveForCapability(
            vin,
            Obd2AdapterCapability.passiveCanCapable,
          ),
          same(psa),
        );
      });

      test('null VIN returns null even with capable adapter', () {
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.resolveForCapability(
            null,
            Obd2AdapterCapability.oemPidsCapable,
          ),
          isNull,
        );
      });

      test('VIN shorter than 3 chars returns null gracefully', () {
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.resolveForCapability(
            'VF',
            Obd2AdapterCapability.oemPidsCapable,
          ),
          isNull,
        );
      });

      test('unknown WMI returns null even with capable adapter', () {
        final registry = OemPidRegistry(tables: const [psa]);

        expect(
          registry.resolveForCapability(
            'JTEBU5JR1A5012345',
            Obd2AdapterCapability.oemPidsCapable,
          ),
          isNull,
        );
      });
    });

    group('multiple tables', () {
      test('lookup picks the correct table by prefix', () {
        const psa = _StubTable('PSA', {'VF3', 'VF7'});
        const vag = _StubTable('VAG', {'WVW', 'WAU'});
        const toyota = _StubTable('TOYOTA', {'JTE', 'JTD'});
        final registry = OemPidRegistry(tables: const [psa, vag, toyota]);

        expect(registry.lookupByWmi('VF3'), same(psa));
        expect(registry.lookupByWmi('VF7'), same(psa));
        expect(registry.lookupByWmi('WVW'), same(vag));
        expect(registry.lookupByWmi('WAU'), same(vag));
        expect(registry.lookupByWmi('JTE'), same(toyota));
        expect(registry.lookupByWmi('JTD'), same(toyota));
      });

      test('overlapping prefixes — first registered wins (documented rule)',
          () {
        // Two tables both claim VF3. First-registered wins — see the
        // class docstring "Overlap precedence" section. This test
        // pins the contract so a future refactor that reorders the
        // iteration cannot silently flip behaviour.
        const psaPrimary = _StubTable('PSA-primary', {'VF3'});
        const psaShadow = _StubTable('PSA-shadow', {'VF3'});
        final registry =
            OemPidRegistry(tables: const [psaPrimary, psaShadow]);

        final hit = registry.lookupByWmi('VF3');
        expect(hit, same(psaPrimary));
        expect(hit?.oemKey, 'PSA-primary');
      });
    });

    group('withDefaults factory (#1401 phase 4)', () {
      test('finds PsaOemPidTable for a Peugeot VIN (VF3 prefix)', () {
        final registry = OemPidRegistry.withDefaults();

        final hit = registry.lookupByVin('VF31234567890ABCD');

        expect(hit, isA<PsaOemPidTable>());
        expect(hit?.oemKey, 'PSA');
      });

      test('finds PsaOemPidTable for a Citroën VIN (VF7 prefix)', () {
        final registry = OemPidRegistry.withDefaults();

        expect(
          registry.lookupByVin('VF71234567890ABCD'),
          isA<PsaOemPidTable>(),
        );
      });

      test('returns null for non-PSA VINs (e.g. BMW WBA prefix)', () {
        final registry = OemPidRegistry.withDefaults();

        // WBA is BMW — not registered in phase 4. Subsequent epic
        // phases / issues may add it; this test pins the current
        // PSA-only scope so a future "added BMW" PR has to update
        // the assertion deliberately.
        expect(registry.lookupByVin('WBA1234567890ABCD'), isNull);
      });

      test('respects the capability gate even with the PSA table loaded', () {
        final registry = OemPidRegistry.withDefaults();

        expect(
          registry.resolveForCapability(
            'VF31234567890ABCD',
            Obd2AdapterCapability.standardOnly,
          ),
          isNull,
        );
        expect(
          registry.resolveForCapability(
            'VF31234567890ABCD',
            Obd2AdapterCapability.oemPidsCapable,
          ),
          isA<PsaOemPidTable>(),
        );
      });
    });

    test('constructor stores tables defensively (later mutation does not leak)',
        () {
      const psa = _StubTable('PSA', {'VF3'});
      final mutable = <OemPidTable>[psa];
      final registry = OemPidRegistry(tables: mutable);

      // Append after construction — must not affect the registry.
      mutable.add(const _StubTable('VAG', {'WVW'}));

      expect(registry.lookupByWmi('VF3'), same(psa));
      expect(registry.lookupByWmi('WVW'), isNull);
    });
  });
}
