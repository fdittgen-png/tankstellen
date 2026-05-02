import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/auto_record_section.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

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
  VoidCallback? onPairAdapter,
  Future<ResolvedObd2Candidate?> Function(BuildContext)? showAdapterPicker,
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
        onPairAdapter: onPairAdapter,
        showAdapterPicker: showAdapterPicker,
      ),
    ),
    overrides: [
      vehicleProfileListProvider.overrideWith(() => list),
    ],
  );
  return list;
}

/// Build a [ResolvedObd2Candidate] for the picker stub. Mirrors the
/// shape produced by the real BLE/Classic scanner so the persist
/// path receives the same `(deviceId, deviceName, profile)` tuple
/// it would in production.
ResolvedObd2Candidate _candidate({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String name = 'vLinker FS 1234',
}) {
  return ResolvedObd2Candidate(
    candidate: Obd2AdapterCandidate(
      deviceId: mac,
      deviceName: name,
      advertisedServiceUuids: const [],
      rssi: -55,
    ),
    profile: const Obd2AdapterProfile(
      id: 'vlinker-fs-classic',
      displayName: 'vLinker FS (Classic)',
    ),
  );
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
      // No sliders, no banner.
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
    });

    testWidgets('toggle ON reveals sliders bound to profile defaults',
        (tester) async {
      final list = _FakeVehicleProfileList([
        const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
      ]);
      await _pumpSection(tester, vehicleId: 'v1', list: list);

      // State-aware banner is visible (no paired adapter → needsPairing).
      expect(
        find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
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
    });

    testWidgets(
      'autoRecord ON, no paired MAC — needsPairing banner with the '
      '"Pair an adapter" CTA',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        await _pumpSection(tester, vehicleId: 'v1', list: list);

        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
          findsOneWidget,
        );
        expect(
          find.text('Pair an OBD2 adapter to enable auto-record.'),
          findsOneWidget,
        );
        // Other states must NOT render simultaneously.
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsBackgroundLocation')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('autoRecordStatusBannerActive')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'autoRecord ON, MAC paired, backgroundLocationConsent=false — '
      'needsBackgroundLocation banner without the pair CTA',
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
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
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
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
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
      'tapping the "Pair an adapter" CTA falls back to /setup when the '
      'picker is cancelled (GoRouter wrapper) — #1350',
      (tester) async {
        // Tall canvas so the banner + sliders fit without overflow.
        tester.view.physicalSize = const Size(900, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);

        // Stub picker that simulates user cancel (null result). Per the
        // #1350 spec the /setup fallback fires on cancel so the CTA
        // still has somewhere to land.
        Future<ResolvedObd2Candidate?> cancelledPicker(BuildContext _) async {
          return null;
        }

        final router = GoRouter(
          initialLocation: '/edit',
          routes: [
            GoRoute(
              path: '/edit',
              builder: (_, _) => Scaffold(
                body: SingleChildScrollView(
                  child: AutoRecordSection(
                    vehicleId: 'v1',
                    showAdapterPicker: cancelledPicker,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/setup',
              builder: (_, _) => const Scaffold(
                key: Key('setupScreenStub'),
                body: Text('OBD2 onboarding'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vehicleProfileListProvider.overrideWith(() => list),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Sanity — sitting on /edit with the needsPairing banner.
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
        );
        // Pump twice to allow the route push to settle without
        // invoking pumpAndSettle (some Flutter versions hold a frame).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byKey(const Key('setupScreenStub')), findsOneWidget);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          '/setup',
        );
        // Cancel must NOT persist anything onto the profile.
        expect(list.savedProfiles, isEmpty);
      },
    );

    testWidgets(
      'tapping the "Pair an adapter" CTA persists the picked adapter '
      'onto the current profile (#1350 happy path)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);

        Future<ResolvedObd2Candidate?> pickerStub(BuildContext _) async {
          return _candidate(
            mac: 'DE:AD:BE:EF:00:01',
            name: 'vLinker FS 9000',
          );
        }

        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          showAdapterPicker: pickerStub,
        );

        // Sanity — needsPairing banner is up before the tap.
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
        );
        // Bounded pumps — the picker stub resolves synchronously but
        // the persist + rebuild needs at least one frame.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Repository got exactly one save call carrying the picked
        // adapter's MAC + name on the original profile.
        expect(list.savedProfiles, hasLength(1));
        final saved = list.savedProfiles.single;
        expect(saved.id, 'v1');
        expect(saved.name, 'Golf');
        expect(saved.autoRecord, isTrue);
        expect(saved.pairedAdapterMac, 'DE:AD:BE:EF:00:01');
        expect(saved.obd2AdapterMac, 'DE:AD:BE:EF:00:01');
        expect(saved.obd2AdapterName, 'vLinker FS 9000');

        // After persist the banner flips off needsPairing — the
        // backgroundLocationConsent gate is still missing so we land
        // on needsBackgroundLocation, not active.
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsBackgroundLocation')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'happy path uses the registry display name when the candidate '
      'advertises an empty deviceName (#1350)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);

        Future<ResolvedObd2Candidate?> pickerStub(BuildContext _) async {
          return _candidate(
            mac: '11:22:33:44:55:66',
            name: '', // empty advertised name → fall back to profile.displayName
          );
        }

        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          showAdapterPicker: pickerStub,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(list.savedProfiles, hasLength(1));
        expect(list.savedProfiles.single.obd2AdapterName,
            'vLinker FS (Classic)');
        expect(list.savedProfiles.single.pairedAdapterMac,
            '11:22:33:44:55:66');
      },
    );

    testWidgets(
      'cancel path (picker returns null) does NOT persist anything '
      '(#1350)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);

        Future<ResolvedObd2Candidate?> cancelledPicker(BuildContext _) async {
          return null;
        }

        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          showAdapterPicker: cancelledPicker,
        );

        await tester.tap(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(list.savedProfiles, isEmpty);
        // Banner stays on needsPairing — the user cancelled.
        expect(
          find.byKey(const Key('autoRecordStatusBannerNeedsPairing')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'onPairAdapter test hook still takes precedence over the picker '
      'when supplied (#1350)',
      (tester) async {
        final list = _FakeVehicleProfileList([
          const VehicleProfile(id: 'v1', name: 'Golf', autoRecord: true),
        ]);
        var hookCalls = 0;
        var pickerCalls = 0;

        await _pumpSection(
          tester,
          vehicleId: 'v1',
          list: list,
          onPairAdapter: () => hookCalls++,
          showAdapterPicker: (_) async {
            pickerCalls++;
            return null;
          },
        );

        await tester.tap(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(hookCalls, 1);
        expect(pickerCalls, 0,
            reason: 'onPairAdapter must short-circuit the picker path');
        expect(list.savedProfiles, isEmpty);
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
}
