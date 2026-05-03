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
  VoidCallback? onScrollToObd2Card,
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
        onScrollToObd2Card: onScrollToObd2Card,
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
      // No sliders, no banner, no link.
      expect(find.byKey(const Key('autoRecordSpeedThreshold')), findsNothing);
      expect(find.byKey(const Key('autoRecordSaveDelay')), findsNothing);
      expect(
        find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('autoRecordStatusBannerActive')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('autoRecordPairAdapterLink')),
        findsNothing,
      );
    });

    testWidgets('toggle ON reveals sliders bound to profile defaults',
        (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      // State-aware banner is visible (no paired adapter → needsPairing
      // renders the passive link, #1400).
      expect(
        find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('autoRecordPairAdapterLink')),
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

  group('AutoRecordSection — status indicator (#1310)', () {
    testWidgets('autoRecord OFF — no status banner is rendered',
        (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf'),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      expect(
        find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('autoRecordStatusBannerNeedsBackgroundLocation')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('autoRecordStatusBannerActive')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('autoRecordPairAdapterLink')),
        findsNothing,
      );
    });

    testWidgets(
      'autoRecord ON, MAC paired, backgroundLocationConsent=false — '
      'needsBackgroundLocation banner without the pair link (#1400)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            pairedAdapterMac: '00:11:22:33:44:55',
          ),
        ]);
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsBackgroundLocation')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('autoRecordStatusBannerActive')),
          findsNothing,
        );
        expect(
          find.textContaining('Allow background location'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'autoRecord ON, MAC paired, backgroundLocationConsent=true — '
      'active banner with the green check icon',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            pairedAdapterMac: '00:11:22:33:44:55',
            backgroundLocationConsent: true,
          ),
        ]);
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        expect(
          find.byKey(const Key('autoRecordStatusBannerActive')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsBackgroundLocation')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsNothing,
        );
        // The active state shows a check_circle icon (not warning_amber).
        // Restrict to the descendant of the active banner so we don't
        // collide with the consent row's check icon.
        expect(
          find.descendant(
            of: find.byKey(const Key('autoRecordStatusBannerActive')),
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Auto-record will activate the next time you '
              'enter the car.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'rendered tree NEVER contains the substring "in development" '
      '(regression guard for the stale phase-status banner)',
      (tester) async {
        // Cycle through every state once and assert the forbidden
        // string is absent. Use a `find.byWidgetPredicate` over Text
        // widgets so we catch literal copy regressions even if the
        // banner shape changes again later.
        final fixtures = [
          // OFF
          const VehicleProfile(id: 'v1', name: 'Golf'),
          // needsPairing
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
          // needsBackgroundLocation
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            pairedAdapterMac: 'DE:AD:BE:EF:00:01',
          ),
          // active
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            pairedAdapterMac: 'DE:AD:BE:EF:00:01',
            backgroundLocationConsent: true,
          ),
        ];

        for (final profile in fixtures) {
          final list = _FakeVehicleProfileList([profile]);
          await _pumpSection(tester, vehicleId: 'v1', list: list);
          expect(
            find.byWidgetPredicate((w) =>
                w is Text &&
                (w.data?.toLowerCase().contains('in development') ?? false)),
            findsNothing,
            reason: '"in development" must not appear in any state',
          );
          expect(
            find.byWidgetPredicate((w) =>
                w is Text &&
                (w.data?.toLowerCase().contains('rolled out') ?? false)),
            findsNothing,
            reason: '"rolled out" must not appear in any state',
          );
        }
      },
    );
  });

  group('AutoRecordSection — pair-adapter link (#1400)', () {
    testWidgets(
      'autoRecord ON, no paired MAC — passive informational link is '
      'rendered with the canonical copy and arrow_downward icon',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        // The passive link carries the needsPairing banner key so
        // existing /screen tests that find by banner key still match.
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsOneWidget,
        );
        // Canonical copy from the en ARB fragment.
        expect(
          find.text(
            'Pair an adapter in the section below to enable '
            'auto-recording',
          ),
          findsOneWidget,
        );
        // Visual cue — info_outline + arrow_downward icons.
        expect(
          find.descendant(
            of: find.byKey(const Key('autoRecordPairAdapterLink')),
            matching: find.byIcon(Icons.info_outline),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('autoRecordPairAdapterLink')),
            matching: find.byIcon(Icons.arrow_downward),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'no orange-tinted "Pair an adapter" CTA button is rendered '
      'anywhere on the auto-record card (#1400)',
      (tester) async {
        // Cycle through both relevant on-states; the deprecated CTA
        // pre-#1400 only ever rendered on needsPairing but we cover
        // needsBackgroundLocation too as a belt-and-suspender.
        final fixtures = [
          // needsPairing
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
          // needsBackgroundLocation
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            pairedAdapterMac: 'DE:AD:BE:EF:00:01',
          ),
        ];

        for (final profile in fixtures) {
          final list = _FakeVehicleProfileList([profile]);
          await _pumpSection(tester, vehicleId: 'v1', list: list);

          expect(
            find.byKey(const Key('autoRecordStatusPairAdapterCta')),
            findsNothing,
            reason: 'Pre-#1400 CTA button must not survive consolidation',
          );
        }
      },
    );

    testWidgets(
      'tapping the link calls onScrollToObd2Card exactly once (#1400)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        var taps = 0;
        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          onScrollToObd2Card: () => taps++,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordPairAdapterLink')),
        );
        await tester.pump();

        expect(taps, 1);
        // The link is passive — tapping it must NOT persist anything.
        expect(list.savedProfiles, isEmpty);
      },
    );

    testWidgets(
      'tapping the link with a null callback is a safe no-op (#1400)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        // No onScrollToObd2Card — isolated widget pump shape.
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        // Tap should not throw even though the callback is null —
        // InkWell with null onTap is a no-op.
        await tester.tap(
          find.byKey(const Key('autoRecordPairAdapterLink')),
        );
        await tester.pump();

        expect(list.savedProfiles, isEmpty);
      },
    );

    testWidgets(
      'paired-adapter state hides the link entirely (#1400)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(
            id: 'v1',
            name: 'Golf',
            autoRecord: true,
            pairedAdapterMac: 'AA:BB:CC:11:22:33',
            backgroundLocationConsent: true,
          ),
        ]);
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsNothing,
        );
        // Active banner takes its place.
        expect(
          find.byKey(const Key('autoRecordStatusBannerActive')),
          findsOneWidget,
        );
      },
    );
  });
}
