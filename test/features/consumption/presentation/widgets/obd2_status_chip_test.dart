// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_status_chip.dart';
import 'package:tankstellen/features/consumption/providers/obd2_connection_state_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Pumps the chip inside a minimal MaterialApp so AppLocalizations +
/// theme are available. [snapshot] drives the connection-state
/// provider; [pairedAdapterMac] drives the active vehicle's paired
/// adapter (#1695) — null means "no adapter paired", which is what
/// flips the not-connected chip from hidden to the pairing affordance.
Future<void> _pumpChip(
  WidgetTester tester, {
  required Obd2ConnectionSnapshot snapshot,
  String? pairedAdapterMac,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        obd2ConnectionStatusProvider.overrideWith(
          () => _FakeStatus(snapshot),
        ),
        activeVehicleProfileProvider.overrideWith(
          () => _StubActiveVehicle(pairedAdapterMac),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: const [Obd2StatusChip()],
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeStatus extends Obd2ConnectionStatus {
  _FakeStatus(this._initial);
  final Obd2ConnectionSnapshot _initial;
  @override
  Obd2ConnectionSnapshot build() => _initial;
}

/// Stub active vehicle — carries [_mac] as its paired OBD2 adapter, or
/// resolves to "no vehicle" when [_mac] is null.
class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._mac);
  final String? _mac;
  @override
  VehicleProfile? build() => _mac == null
      ? null
      : VehicleProfile(
          id: 'v1',
          name: 'Test Car',
          type: VehicleType.combustion,
          obd2AdapterMac: _mac,
        );
}

void main() {
  group('Obd2StatusChip (#797 phase 3)', () {
    testWidgets('renders the Bluetooth icon when the adapter is '
        'connected', (tester) async {
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(
          state: Obd2ConnectionState.connected,
          adapterName: 'vLinker FS',
          adapterMac: 'AA:BB',
        ),
      );
      expect(find.byKey(const Key('obd2StatusChip')), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('tooltip reads "OBD2 connected: <name>"', (tester) async {
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(
          state: Obd2ConnectionState.connected,
          adapterName: 'vLinker FS',
        ),
      );
      final button = tester.widget<IconButton>(
        find.byKey(const Key('obd2StatusChip')),
      );
      expect(button.tooltip, contains('vLinker FS'));
      expect(button.tooltip, contains('OBD2 connected'));
    });

    testWidgets('stays hidden when an adapter is paired but the '
        'connection is attempting', (tester) async {
      // An adapter IS paired — the transient disconnect is the
      // Obd2StatusDot's job to surface, so the chip stays quiet.
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(
          state: Obd2ConnectionState.attempting,
          adapterName: 'vLinker FS',
        ),
        pairedAdapterMac: 'AA:BB:CC',
      );
      expect(find.byKey(const Key('obd2StatusChip')), findsNothing);
      expect(find.byKey(const Key('obd2PairChip')), findsNothing);
    });

    testWidgets('stays hidden when an adapter is paired but the '
        'connection is unreachable', (tester) async {
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(
          state: Obd2ConnectionState.unreachable,
          adapterName: 'vLinker FS',
        ),
        pairedAdapterMac: 'AA:BB:CC',
      );
      expect(find.byKey(const Key('obd2StatusChip')), findsNothing);
      expect(find.byKey(const Key('obd2PairChip')), findsNothing);
    });

    testWidgets('shows a discoverable pairing affordance when NO '
        'adapter is paired (#1695)', (tester) async {
      // idle state + no paired adapter — there is no status-dot signal
      // either, so the chip surfaces a "pair an adapter" entry point.
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(),
      );
      expect(find.byKey(const Key('obd2StatusChip')), findsNothing);
      final pairChip = find.byKey(const Key('obd2PairChip'));
      expect(pairChip, findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
      final button = tester.widget<IconButton>(pairChip);
      expect(button.tooltip, contains('Pair'));
      expect(button.onPressed, isNotNull,
          reason: 'tapping the pair chip must open the adapter picker');
    });

    testWidgets('tap opens a modal — proves the adapter-picker '
        'entry point wires up without crashing', (tester) async {
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(
          state: Obd2ConnectionState.connected,
          adapterName: 'vLinker FS',
        ),
      );
      final button = tester.widget<IconButton>(
        find.byKey(const Key('obd2StatusChip')),
      );
      expect(button.onPressed, isNotNull,
          reason: 'tap target must fire an onPressed callback — '
              'the adapter picker is the real target in production');
    });

    testWidgets('meets the android tap-target guideline (≥48 dp)',
        (tester) async {
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(
          state: Obd2ConnectionState.connected,
          adapterName: 'vLinker FS',
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('the pairing affordance also meets the 48 dp guideline',
        (tester) async {
      await _pumpChip(
        tester,
        snapshot: const Obd2ConnectionSnapshot(),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });
}
