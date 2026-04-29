import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/auto_record_section.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Fake [VehicleProfileList] that lets tests seed an initial list and
/// records every call to [save]. Mirrors the pattern in
/// `vehicle_calibration_mode_selector_test.dart` so widget interactions
/// can be asserted without a real repository.
class _FakeVehicleProfileList extends VehicleProfileList {
  _FakeVehicleProfileList(this._seed);

  final List<VehicleProfile> _seed;
  final List<VehicleProfile> savedProfiles = <VehicleProfile>[];

  @override
  List<VehicleProfile> build() => List<VehicleProfile>.from(_seed);

  @override
  Future<void> save(VehicleProfile profile) async {
    savedProfiles.add(profile);
    final next = [..._seed.where((v) => v.id != profile.id), profile];
    state = next;
    _seed
      ..clear()
      ..addAll(next);
  }
}

Future<_FakeVehicleProfileList> _pumpSection(
  WidgetTester tester, {
  required String vehicleId,
  required _FakeVehicleProfileList list,
  Future<PermissionStatus> Function()? requestBackgroundLocation,
  Future<PermissionStatus> Function()? requestForegroundLocation,
  Future<void> Function()? openSettings,
}) async {
  // Tall canvas so the slider/banner stack does not overflow when the
  // master toggle is on. Mirror the size used by the extras section
  // test so the same fixture covers both.
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpApp(
    tester,
    SingleChildScrollView(
      child: AutoRecordSection(
        vehicleId: vehicleId,
        requestBackgroundLocation: requestBackgroundLocation,
        requestForegroundLocation: requestForegroundLocation,
        openSettings: openSettings,
      ),
    ),
    overrides: [
      vehicleProfileListProvider.overrideWith(() => list),
    ],
  );
  return list;
}

void main() {
  group('AutoRecordSection', () {
    testWidgets('renders SizedBox.shrink when the matching profile is missing',
        (tester) async {
      final list = _FakeVehicleProfileList([]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('toggle OFF hides the advanced sliders + banner',
        (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf'),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      // Master toggle is rendered.
      expect(find.byKey(const Key('autoRecordToggle')), findsOneWidget);
      // No sliders, no banner copy.
      expect(find.byKey(const Key('autoRecordSpeedThreshold')), findsNothing);
      expect(find.byKey(const Key('autoRecordSaveDelay')), findsNothing);
      expect(
        find.textContaining('rolled out in phases'),
        findsNothing,
      );
    });

    testWidgets('toggle ON reveals sliders bound to profile defaults',
        (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      // Phase status banner is visible.
      expect(
        find.textContaining('rolled out in phases'),
        findsOneWidget,
      );

      // Speed slider exists at default 5 km/h.
      final speedSlider = tester.widget<Slider>(
        find.byKey(const Key('autoRecordSpeedThreshold')),
      );
      expect(speedSlider.value, 5);
      expect(speedSlider.min, 1);
      expect(speedSlider.max, 15);

      // Save-delay slider exists at default 60 s.
      final delaySlider = tester.widget<Slider>(
        find.byKey(const Key('autoRecordSaveDelay')),
      );
      expect(delaySlider.value, 60);
      expect(delaySlider.min, 30);
      expect(delaySlider.max, 300);

      // Numeric labels appear next to the sliders.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('toggling the master switch persists autoRecord=true',
        (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf'),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      await tester.tap(find.byKey(const Key('autoRecordToggle')));
      await tester.pumpAndSettle();

      expect(list.savedProfiles, hasLength(1));
      expect(list.savedProfiles.single.id, 'v1');
      expect(list.savedProfiles.single.autoRecord, isTrue);
      // Other fields round-trip.
      expect(list.savedProfiles.single.name, 'Golf');
    });

    testWidgets('paired adapter MAC renders monospace; missing renders hint',
        (tester) async {
      // No paired MAC — empty hint visible.
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      expect(
        find.textContaining('No adapter paired'),
        findsOneWidget,
      );
    });

    testWidgets('paired adapter MAC is shown when set', (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(
          id: 'v1',
          name: 'Golf',
          autoRecord: true,
          pairedAdapterMac: 'AA:BB:CC:11:22:33',
        ),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      expect(find.text('AA:BB:CC:11:22:33'), findsOneWidget);
      expect(find.textContaining('No adapter paired'), findsNothing);
    });

    testWidgets(
      'background-location request button is hidden when consent is true',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            backgroundLocationConsent: true,
          ),
        ]);
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        expect(
          find.byKey(const Key('autoRecordBackgroundLocationRequest')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tapping background-location request runs the prompt and persists '
      'consent on grant',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          requestForegroundLocation: () async => PermissionStatus.granted,
          requestBackgroundLocation: () async => PermissionStatus.granted,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordBackgroundLocationRequest')),
        );
        await tester.pumpAndSettle();

        expect(list.savedProfiles, hasLength(1));
        expect(list.savedProfiles.single.backgroundLocationConsent, isTrue);
      },
    );

    testWidgets(
      'denied background permission does not persist consent and '
      'shows the rationale dialog',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          requestForegroundLocation: () async => PermissionStatus.granted,
          requestBackgroundLocation: () async => PermissionStatus.denied,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordBackgroundLocationRequest')),
        );
        // Use pump() — the AlertDialog scrim animates indefinitely under
        // pumpAndSettle in some Flutter versions. pump twice with a
        // bounded duration is enough for the route + content to settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(list.savedProfiles, isEmpty);
        expect(
          find.byKey(
            const Key('autoRecordBackgroundLocationRationaleDialog'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'foreground-denied shows snackbar and does NOT call '
      'requestBackgroundLocation (#1302)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        var bgPromptCalls = 0;
        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          requestForegroundLocation: () async => PermissionStatus.denied,
          requestBackgroundLocation: () async {
            bgPromptCalls++;
            return PermissionStatus.granted;
          },
        );

        await tester.tap(
          find.byKey(const Key('autoRecordBackgroundLocationRequest')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(bgPromptCalls, 0,
            reason:
                'Background prompt must not run before foreground is granted');
        expect(list.savedProfiles, isEmpty);
        // SnackBar copy from the en ARB fragment is rendered.
        expect(
          find.text('Location permission required'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'foreground+background granted flips backgroundLocationConsent to true '
      '(#1302)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          requestForegroundLocation: () async => PermissionStatus.granted,
          requestBackgroundLocation: () async => PermissionStatus.granted,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordBackgroundLocationRequest')),
        );
        await tester.pumpAndSettle();

        expect(list.savedProfiles, hasLength(1));
        expect(list.savedProfiles.single.backgroundLocationConsent, isTrue);
      },
    );

    testWidgets(
      'permanently-denied background shows the rationale dialog with '
      'an Open settings button that calls openSettings (#1302)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        var openSettingsCalls = 0;
        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          requestForegroundLocation: () async => PermissionStatus.granted,
          requestBackgroundLocation: () async =>
              PermissionStatus.permanentlyDenied,
          openSettings: () async {
            openSettingsCalls++;
          },
        );

        await tester.tap(
          find.byKey(const Key('autoRecordBackgroundLocationRequest')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Rationale dialog rendered with title + Open Settings CTA.
        expect(
          find.byKey(
            const Key('autoRecordBackgroundLocationRationaleDialog'),
          ),
          findsOneWidget,
        );
        expect(find.text('Why "Allow all the time"?'), findsOneWidget);
        expect(
          find.byKey(
            const Key('autoRecordBackgroundLocationOpenSettings'),
          ),
          findsOneWidget,
        );

        // Tapping the CTA pops the dialog and invokes openSettings.
        await tester.tap(
          find.byKey(
            const Key('autoRecordBackgroundLocationOpenSettings'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(openSettingsCalls, 1);
        expect(list.savedProfiles, isEmpty,
            reason: 'Permanent-denied path must not flip consent silently');
      },
    );
  });
}
