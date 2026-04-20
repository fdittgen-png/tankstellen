import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';

void main() {
  final registry = Obd2AdapterRegistry.defaults();

  group('Obd2AdapterRegistry.resolve (#733 step 1)', () {
    test('vLinker FS matched by name — case insensitive, substring', () {
      final hit = _candidate(name: 'vLinker FS 2.2', services: []);
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'vlinker');
    });

    test('OBDLink MX+ matched by name', () {
      final hit = _candidate(name: 'OBDLink MX+', services: []);
      expect(registry.resolve(hit)?.id, 'obdlink-mx');
    });

    test('Carista matched by name even though it shares the FFF0 service',
        () {
      final hit = _candidate(
        name: 'Carista OBD2',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      expect(registry.resolve(hit)?.id, 'carista');
    });

    test('unknown name with FFF0 service → generic fallback', () {
      final hit = _candidate(
        name: 'Some Random Clone',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      expect(registry.resolve(hit)?.id, 'generic-fff0');
    });

    test('unknown name and unrelated service → null (hide from picker)', () {
      final hit = _candidate(
        name: 'Apple Watch',
        services: const ['0000180d-0000-1000-8000-00805f9b34fb'], // heart rate
      );
      expect(registry.resolve(hit), isNull);
    });

    test('empty name + empty services → null', () {
      expect(registry.resolve(_candidate(name: '', services: [])), isNull);
    });

    test('service UUID match is case-insensitive', () {
      final hit = _candidate(
        name: '',
        services: const ['0000FFF0-0000-1000-8000-00805F9B34FB'],
      );
      expect(registry.resolve(hit)?.id, 'generic-fff0');
    });
  });

  group('Obd2AdapterRegistry.allServiceUuids', () {
    test('deduplicates shared service UUIDs', () {
      // 4 of the 5 bundled profiles share FFF0 — allServiceUuids must
      // collapse them so FlutterBluePlus.startScan isn't told the same
      // filter 4 times.
      final uuids = registry.allServiceUuids;
      expect(uuids.contains('0000fff0-0000-1000-8000-00805f9b34fb'), isTrue);
      expect(uuids.contains('000018f0-0000-1000-8000-00805f9b34fb'), isTrue);
      expect(uuids.length, lessThanOrEqualTo(registry.profiles.length));
    });
  });

  group('Obd2AdapterRegistry.rank', () {
    test('drops unresolved candidates, sorts resolved by RSSI desc', () {
      final cands = [
        _candidate(name: 'Apple Watch', services: [], rssi: -40),
        _candidate(name: 'vLinker FS', services: [], rssi: -70),
        _candidate(name: 'OBDLink MX+', services: [], rssi: -55),
      ];
      final ranked = registry.rank(cands);
      expect(ranked.map((r) => r.profile.id).toList(),
          ['obdlink-mx', 'vlinker']);
    });

    test('empty list → empty result', () {
      expect(registry.rank(const []), isEmpty);
    });
  });

  group('Obd2AdapterProfile', () {
    test('vLinker defaults to 100 ms init delay', () {
      final v = registry.profiles.firstWhere((p) => p.id == 'vlinker');
      expect(v.initDelay, const Duration(milliseconds: 100));
    });

    test('generic fallback uses a longer init delay for slow clones', () {
      final g = registry.profiles.firstWhere((p) => p.id == 'generic-fff0');
      expect(g.initDelay, const Duration(milliseconds: 300));
    });
  });
}

Obd2AdapterCandidate _candidate({
  required String name,
  required Iterable<String> services,
  int rssi = -60,
}) =>
    Obd2AdapterCandidate(
      deviceId: 'aa:bb:cc:dd:ee:ff',
      deviceName: name,
      advertisedServiceUuids: services,
      rssi: rssi,
    );
