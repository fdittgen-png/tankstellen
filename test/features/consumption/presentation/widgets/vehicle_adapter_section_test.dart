import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/vehicle_adapter_section.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('VehicleAdapterSection (#779)', () {
    testWidgets('unpaired state shows the empty message + Pair CTA',
        (tester) async {
      var pairTaps = 0;
      await pumpApp(
        tester,
        VehicleAdapterSection(
          adapterMac: null,
          adapterName: null,
          onPaired: (_, __) => pairTaps++,
          onForget: () {},
        ),
      );
      expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);
      expect(find.byKey(const Key('vehicleAdapterForget')), findsNothing);
      // Empty-state copy is the only way a user knows "pair here so
      // auto-reconnect works next time" — the widget should advertise
      // that rather than leaving a bare button.
      expect(
        find.textContaining('Pair one so the app can reconnect'),
        findsOneWidget,
      );
    });

    testWidgets('paired state shows the adapter name, MAC, and a '
        'Forget action', (tester) async {
      var forgetTaps = 0;
      await pumpApp(
        tester,
        VehicleAdapterSection(
          adapterMac: 'AA:BB:CC:DD:EE:FF',
          adapterName: 'vLinker FS 1234',
          onPaired: (_, __) {},
          onForget: () => forgetTaps++,
        ),
      );
      expect(find.text('vLinker FS 1234'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      final forget = find.byKey(const Key('vehicleAdapterForget'));
      expect(forget, findsOneWidget);
      await tester.tap(forget);
      await tester.pump();
      expect(forgetTaps, 1);
      // Pair CTA is hidden while paired so the user doesn't get
      // nudged to reconfigure something that already works.
      expect(find.byKey(const Key('vehicleAdapterPair')), findsNothing);
    });

    testWidgets('empty adapterName + non-empty MAC still renders '
        '"Unknown adapter" instead of a blank label so the paired '
        'card never looks broken', (tester) async {
      await pumpApp(
        tester,
        VehicleAdapterSection(
          adapterMac: 'AA:BB',
          adapterName: '',
          onPaired: (_, __) {},
          onForget: () {},
        ),
      );
      expect(find.text('Unknown adapter'), findsOneWidget);
      expect(find.text('AA:BB'), findsOneWidget);
    });

    testWidgets('empty MAC is treated as unpaired — guards against '
        'a corrupt profile that set name but lost the MAC',
        (tester) async {
      await pumpApp(
        tester,
        VehicleAdapterSection(
          adapterMac: '',
          adapterName: 'ghost',
          onPaired: (_, __) {},
          onForget: () {},
        ),
      );
      expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);
      expect(find.byKey(const Key('vehicleAdapterForget')), findsNothing);
    });
  });
}
