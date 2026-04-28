import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/charging_log_readout.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_log_derived_readout_panel.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_log_form_fields.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_date_row.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_vehicle_dropdown.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [ChargingLogFormFields] (#561 coverage). The widget
/// is a pure stateless layout — every controller and callback is owned
/// by the parent screen — so the tests assert that each child widget is
/// rendered with the right key and that the user-driven callbacks
/// (date tap, vehicle dropdown selection, save tap) flow back to the
/// caller verbatim.
void main() {
  const vehicles = <VehicleProfile>[
    VehicleProfile(id: 'veh-zoe', name: 'Renault Zoe', type: VehicleType.ev),
    VehicleProfile(id: 'veh-id3', name: 'VW ID.3', type: VehicleType.ev),
  ];

  /// Owns a fresh set of controllers for each test so leftover text
  /// from a previous test cannot leak through.
  ({
    TextEditingController kwh,
    TextEditingController cost,
    TextEditingController time,
    TextEditingController odo,
    TextEditingController station,
  }) makeControllers() {
    return (
      kwh: TextEditingController(),
      cost: TextEditingController(),
      time: TextEditingController(),
      odo: TextEditingController(),
      station: TextEditingController(),
    );
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    required ({
      TextEditingController kwh,
      TextEditingController cost,
      TextEditingController time,
      TextEditingController odo,
      TextEditingController station,
    }) controllers,
    String dateLabel = '2026-04-28',
    VoidCallback? onPickDate,
    String? vehicleId = 'veh-zoe',
    void Function(String? id, VehicleProfile? selected)? onVehicleChanged,
    ChargingLogReadout? derived,
    bool saving = false,
    VoidCallback? onSave,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(viewPadding: viewPadding),
          child: Scaffold(
            body: Form(
              child: ChargingLogFormFields(
                dateLabel: dateLabel,
                onPickDate: onPickDate ?? () {},
                vehicleId: vehicleId,
                vehicles: vehicles,
                onVehicleChanged: onVehicleChanged ?? (_, _) {},
                kwhCtrl: controllers.kwh,
                costCtrl: controllers.cost,
                timeMinCtrl: controllers.time,
                odoCtrl: controllers.odo,
                stationCtrl: controllers.station,
                derived: derived,
                saving: saving,
                onSave: onSave ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders all five input fields with their stable keys',
      (tester) async {
    final c = makeControllers();
    await pumpForm(tester, controllers: c);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('charging_kwh_field')), findsOneWidget);
    expect(find.byKey(const Key('charging_cost_field')), findsOneWidget);
    expect(find.byKey(const Key('charging_time_field')), findsOneWidget);
    expect(find.byKey(const Key('charging_odo_field')), findsOneWidget);
    expect(find.byKey(const Key('charging_station_field')), findsOneWidget);
    expect(find.byKey(const Key('charging_save_button')), findsOneWidget);
  });

  testWidgets('renders the date row with the supplied dateLabel',
      (tester) async {
    final c = makeControllers();
    await pumpForm(tester, controllers: c, dateLabel: '2026-04-28');
    await tester.pumpAndSettle();

    expect(find.byType(FillUpDateRow), findsOneWidget);
    expect(find.text('2026-04-28'), findsOneWidget);
  });

  testWidgets('tapping the date row fires onPickDate', (tester) async {
    var picked = false;
    final c = makeControllers();
    await pumpForm(
      tester,
      controllers: c,
      onPickDate: () => picked = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FillUpDateRow));
    expect(picked, isTrue);
  });

  testWidgets(
      'vehicle dropdown selection forwards id + resolved profile to '
      'onVehicleChanged', (tester) async {
    String? capturedId;
    VehicleProfile? capturedProfile;
    final c = makeControllers();
    await pumpForm(
      tester,
      controllers: c,
      vehicleId: 'veh-zoe',
      onVehicleChanged: (id, profile) {
        capturedId = id;
        capturedProfile = profile;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FillUpVehicleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VW ID.3').last);
    await tester.pumpAndSettle();

    expect(capturedId, 'veh-id3');
    expect(capturedProfile?.name, 'VW ID.3');
  });

  testWidgets('Save button is enabled and renders the save icon when not '
      'saving — tap fires onSave', (tester) async {
    var saved = false;
    final c = makeControllers();
    await pumpForm(
      tester,
      controllers: c,
      saving: false,
      onSave: () => saved = true,
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('charging_save_button')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const Key('charging_save_button')));
    expect(saved, isTrue);
  });

  testWidgets('Save button is disabled and renders a spinner when saving',
      (tester) async {
    var saved = false;
    final c = makeControllers();
    await pumpForm(
      tester,
      controllers: c,
      saving: true,
      onSave: () => saved = true,
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('charging_save_button')),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.save), findsNothing);

    // Even attempting to tap the disabled button must not fire onSave —
    // guards against a regression where the FilledButton kept its tap
    // handler while showing the spinner.
    await tester.tap(
      find.byKey(const Key('charging_save_button')),
      warnIfMissed: false,
    );
    expect(saved, isFalse);
  });

  testWidgets('always mounts the derived readout panel when derived is null',
      (tester) async {
    final c = makeControllers();
    await pumpForm(tester, controllers: c, derived: null);
    await tester.pumpAndSettle();

    // The panel itself collapses to a SizedBox.shrink when readout is
    // null — what matters at this layer is that it is in the tree, so
    // the parent screen does not need to remount it on state changes.
    expect(find.byType(ChargingLogDerivedReadoutPanel), findsOneWidget);
  });

  testWidgets('mounts the derived readout panel when derived has values',
      (tester) async {
    final c = makeControllers();
    await pumpForm(
      tester,
      controllers: c,
      derived: const ChargingLogReadout(
        eurPer100km: 4.20,
        kwhPer100km: 17.5,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChargingLogDerivedReadoutPanel), findsOneWidget);
    expect(find.byKey(const Key('charging_derived_readout')), findsOneWidget);
  });

  testWidgets('reflects controller text in the rendered fields',
      (tester) async {
    final c = makeControllers();
    c.kwh.text = '42.5';
    c.cost.text = '12.30';
    c.station.text = 'Ionity Béziers';

    await pumpForm(tester, controllers: c);
    await tester.pumpAndSettle();

    expect(find.text('42.5'), findsOneWidget);
    expect(find.text('12.30'), findsOneWidget);
    expect(find.text('Ionity Béziers'), findsOneWidget);
  });

  testWidgets('bottom safe-area inset adds viewPadding.bottom + 16 of slack',
      (tester) async {
    final c = makeControllers();
    await pumpForm(
      tester,
      controllers: c,
      viewPadding: const EdgeInsets.only(bottom: 24),
    );
    await tester.pumpAndSettle();

    // The last item in the ListView is a SizedBox sized to
    // `viewPadding.bottom + 16` so the Save button is never tucked
    // behind the gesture bar — assert at least one such SizedBox is
    // mounted at exactly the expected height.
    final spacer = find.byWidgetPredicate(
      (w) => w is SizedBox && w.height == 24 + 16,
    );
    expect(spacer, findsOneWidget);
  });
}
