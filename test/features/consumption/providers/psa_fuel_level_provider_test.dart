import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_capability.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/psa_fuel_level_provider.dart';

/// Tests for [psaFuelLevelProvider] (#1418).
///
/// Pins the capability gate (`passiveCanCapable` exact-or-above —
/// matches the data-layer comment in [psa_fuel_level_can_decoder.dart])
/// and the wiring through [PsaFuelLevelCanDecoder] into Riverpod.

const _initResponses = {
  'ATZ': 'STN1110 v4.0.4>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  'ATCRA 0E6': 'OK>',
  'STMA': 'OK>',
  // ATI is what `connect` uses to detect capability — the response
  // string drives the [Obd2AdapterCapability] tier.
  'ATI': 'STN1110 v4.0.4>',
};

/// Build a connected [Obd2Service] whose [Obd2Service.capability]
/// reports [tier]. We achieve this by handing in the firmware string
/// the data-layer parser would produce that tier for.
Future<({Obd2Service service, FakeObd2Transport transport})> _serviceFor(
  Obd2AdapterCapability tier,
) async {
  final ati = switch (tier) {
    Obd2AdapterCapability.passiveCanCapable => 'STN1110 v4.0.4>',
    Obd2AdapterCapability.oemPidsCapable => 'ELM327 v2.2>',
    Obd2AdapterCapability.standardOnly => 'ELM327 v1.5>',
  };
  final transport = FakeObd2Transport({..._initResponses, 'ATI': ati});
  final service = Obd2Service(transport);
  await service.connect();
  // Sanity: the parser must actually produce the requested tier — if
  // the firmware string maps differently we want the test to fail
  // here, not silently in the provider.
  expect(service.capability, equals(tier));
  return (service: service, transport: transport);
}

void main() {
  group('psaFuelLevelProvider gate (#1418)', () {
    test(
        'no service plumbed → empty stream (production default — '
        'first-class "not available" state, never throws)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default override seam returns null in production; provider
      // must short-circuit to an empty stream.
      final values = <double>[];
      final sub = container.listen(
        psaFuelLevelProvider,
        (prev, next) {
          if (next.hasValue) values.add(next.value!);
        },
      );
      addTearDown(sub.close);
      // Drain pending events.
      await Future<void>.delayed(Duration.zero);
      // Stream is empty, completes immediately — AsyncValue settles
      // with no data.
      expect(values, isEmpty);
    });

    test('standardOnly capability → empty stream (no setup commands '
        'sent, gate falls through to active-poll path)', () async {
      final (:service, :transport) =
          await _serviceFor(Obd2AdapterCapability.standardOnly);
      transport.sentCommands.clear();

      final container = ProviderContainer(
        overrides: [
          psaFuelLevelObd2ServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final values = <double>[];
      final sub = container.listen(
        psaFuelLevelProvider,
        (prev, next) {
          if (next.hasValue) values.add(next.value!);
        },
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      expect(values, isEmpty);
      // Gate enforced on the provider — service must NOT have been
      // poked into listen mode at all.
      expect(transport.sentCommands, isNot(contains('STMA')));
      expect(transport.sentCommands, isNot(contains('ATCRA 0E6')));
    });

    test(
        'oemPidsCapable capability → empty stream (passive-CAN gate '
        'is exact-tier, falls through to phase-4 active polling on '
        '`oemPidsCapable`)', () async {
      // Mirrors the decoder file's docstring:
      //   "Passive sniffing requires the STN-chip family
      //    (`Obd2AdapterCapability.passiveCanCapable`). On a
      //    `oemPidsCapable` adapter the caller falls through to the
      //    active-polling path."
      final (:service, :transport) =
          await _serviceFor(Obd2AdapterCapability.oemPidsCapable);
      transport.sentCommands.clear();

      final container = ProviderContainer(
        overrides: [
          psaFuelLevelObd2ServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final values = <double>[];
      final sub = container.listen(
        psaFuelLevelProvider,
        (prev, next) {
          if (next.hasValue) values.add(next.value!);
        },
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      expect(values, isEmpty);
      expect(transport.sentCommands, isNot(contains('STMA')));
    });

    test(
        'passiveCanCapable capability → forwards decoded litres from '
        'real CAN frames pushed through the transport — full gate + '
        'decoder pipe end-to-end', () async {
      final (:service, :transport) =
          await _serviceFor(Obd2AdapterCapability.passiveCanCapable);
      transport.sentCommands.clear();

      final container = ProviderContainer(
        overrides: [
          psaFuelLevelObd2ServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final values = <double>[];
      final sub = container.listen(
        psaFuelLevelProvider,
        (prev, next) {
          if (next.hasValue) values.add(next.value!);
        },
      );
      addTearDown(sub.close);
      // Setup must run BEFORE we push any frames.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Sanity: setup commands fired now that the gate opened.
      expect(transport.sentCommands, contains('ATCRA 0E6'));
      expect(transport.sentCommands, contains('STMA'));

      // Push a canonical PSA frame: bytes 4-5 = 0x00,0x5A → 45.0 L.
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(values, equals([45.0]));

      // A second frame with bytes 4-5 = 0x00,0x64 → 50.0 L.
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 64');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(values, equals([45.0, 50.0]));
    });

    test('passiveCanCapable but the bus emits a non-PSA frame → no '
        'litres value forwarded (decoder filters by frame id)', () async {
      final (:service, :transport) =
          await _serviceFor(Obd2AdapterCapability.passiveCanCapable);
      transport.sentCommands.clear();

      final container = ProviderContainer(
        overrides: [
          psaFuelLevelObd2ServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final values = <double>[];
      final sub = container.listen(
        psaFuelLevelProvider,
        (prev, next) {
          if (next.hasValue) values.add(next.value!);
        },
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Speed broadcast on PSA — different frame id, should not
      // produce a fuel-level reading.
      transport.pushListenLine('0B6 D 6 00 00 12 34 56 78');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(values, isEmpty);
    });
  });
}
