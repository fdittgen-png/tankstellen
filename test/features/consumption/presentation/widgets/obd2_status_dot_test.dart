import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_status_dot.dart';
import 'package:tankstellen/features/consumption/providers/obd2_connection_state_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Fake notifier lets tests pin the status snapshot to a specific
/// state without running the full boot-probe sequence.
class _FakeObd2Status extends Obd2ConnectionStatus {
  final Obd2ConnectionSnapshot _initial;
  _FakeObd2Status(this._initial);

  @override
  Obd2ConnectionSnapshot build() => _initial;
}

void main() {
  group('Obd2StatusDot (#784)', () {
    testWidgets('idle state: nothing rendered — zero UX weight for '
        'users who have never paired an adapter', (tester) async {
      await pumpApp(
        tester,
        const Obd2StatusDot(),
        overrides: [
          obd2ConnectionStatusProvider.overrideWith(
            () => _FakeObd2Status(const Obd2ConnectionSnapshot()),
          ),
        ],
      );
      expect(find.byKey(const Key('obd2StatusDot')), findsNothing);
    });

    testWidgets('connected state renders the dot with a Semantics '
        'label announcing the status to TalkBack', (tester) async {
      await pumpApp(
        tester,
        const Obd2StatusDot(),
        overrides: [
          obd2ConnectionStatusProvider.overrideWith(
            () => _FakeObd2Status(const Obd2ConnectionSnapshot(
              state: Obd2ConnectionState.connected,
              adapterName: 'vLinker FS',
              adapterMac: 'AA:BB',
            )),
          ),
        ],
      );
      expect(find.byKey(const Key('obd2StatusDot')), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('OBD2 adapter: connected'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('tapping the dot opens a sheet naming the adapter + '
        '"Forget adapter" action', (tester) async {
      await pumpApp(
        tester,
        const Obd2StatusDot(),
        overrides: [
          obd2ConnectionStatusProvider.overrideWith(
            () => _FakeObd2Status(const Obd2ConnectionSnapshot(
              state: Obd2ConnectionState.connected,
              adapterName: 'vLinker FS',
              adapterMac: 'AA:BB:CC:DD',
            )),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('obd2StatusDot')));
      await tester.pumpAndSettle();
      expect(find.text('vLinker FS'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD'), findsOneWidget);
      expect(find.byKey(const Key('obd2StatusDotForget')), findsOneWidget);
    });

    testWidgets('attempting state uses the amber semantics label '
        'so colour-blind users hear the state, not just see it',
        (tester) async {
      await pumpApp(
        tester,
        const Obd2StatusDot(),
        overrides: [
          obd2ConnectionStatusProvider.overrideWith(
            () => _FakeObd2Status(const Obd2ConnectionSnapshot(
              state: Obd2ConnectionState.attempting,
              adapterName: 'vLinker FS',
              adapterMac: 'AA:BB',
            )),
          ),
        ],
      );
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('OBD2 adapter: connecting'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
