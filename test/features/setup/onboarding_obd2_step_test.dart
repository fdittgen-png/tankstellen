import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_obd2_step.dart';
import 'package:tankstellen/features/setup/providers/onboarding_obd2_connector.dart';
import 'package:tankstellen/features/setup/providers/onboarding_wizard_provider.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vin_decoder_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the OBD2 adapter-first onboarding step (#816).
///
/// Pattern:
///   * an injectable [OnboardingObd2Connector] is the seam the step
///     uses to talk to the adapter stack — the fake returns the VIN
///     the test wants to exercise (null, complete vPIC, partial WMI).
///   * a stub [VinDecoder] overrides the network-bound vPIC fetch so
///     every branch runs offline.
///   * an in-memory [SettingsStorage] fake overrides
///     [settingsStorageProvider] so the profile save hits plain Dart
///     maps instead of Hive — the fake-async test zone cannot flush
///     real file I/O, which would hang `pumpAndSettle` for the full
///     10-minute default timeout.
void main() {
  group('OnboardingObd2Step (#816)', () {
    testWidgets('skip path: tapping "Maybe later" advances without '
        'calling the connector', (tester) async {
      final connector = _FakeConnector();
      var proceeded = 0;
      var autoFilled = 0;

      await _pumpStep(
        tester,
        connector: connector,
        onProceed: () => proceeded++,
        onAutoFillSuccess: () => autoFilled++,
      );

      expect(find.text('Maybe later'), findsOneWidget);
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      expect(proceeded, 1);
      expect(autoFilled, 0);
      expect(connector.connectCalls, 0);
      expect(connector.readVinCalls, 0);
    });

    testWidgets('connect + VIN read + user confirms → saves a '
        'pre-filled VehicleProfile and invokes onAutoFillSuccess',
        (tester) async {
      final service = _buildService();
      final connector = _FakeConnector(
        onConnect: () async => service,
        onReadVin: (_) async => '1HGCM82633A004352',
      );
      final decoder = _StubDecoder(
        (vin) => VinData(
          vin: vin,
          make: 'Honda',
          model: 'Accord',
          modelYear: 2003,
          displacementL: 2.4,
          cylinderCount: 4,
          fuelTypePrimary: 'Gasoline',
          source: VinDataSource.vpic,
        ),
      );

      var proceeded = 0;
      var autoFilled = 0;
      late ProviderContainer container;

      await _pumpStep(
        tester,
        connector: connector,
        vinDecoder: decoder,
        onProceed: () => proceeded++,
        onAutoFillSuccess: () => autoFilled++,
        onContainerReady: (c) => container = c,
      );

      await tester.tap(find.text('Connect adapter'));
      await tester.pumpAndSettle();

      // VinConfirmDialog opens — accept.
      expect(find.text('Yes, auto-fill'), findsOneWidget);
      await tester.tap(find.text('Yes, auto-fill'));
      await tester.pumpAndSettle();

      expect(autoFilled, 1);
      expect(proceeded, 0);
      expect(connector.connectCalls, 1);
      expect(connector.readVinCalls, 1);
      expect(decoder.calls, ['1HGCM82633A004352']);

      // VehicleProfile was pre-filled from the decoded VIN and saved
      // — the manual VehiclesStep can be skipped entirely.
      final vehicles = container.read(vehicleProfileListProvider);
      expect(vehicles, hasLength(1));
      final saved = vehicles.first;
      expect(saved.vin, '1HGCM82633A004352');
      expect(saved.engineDisplacementCc, 2400);
      expect(saved.engineCylinders, 4);
      expect(saved.preferredFuelType, 'e10');
      expect(saved.name, contains('Honda'));
      expect(saved.name, contains('Accord'));
    });

    testWidgets('connect succeeds, VIN read returns null → flags '
        'obd2VinReadFailed and advances without showing the dialog',
        (tester) async {
      final service = _buildService();
      final connector = _FakeConnector(
        onConnect: () async => service,
        onReadVin: (_) async => null,
      );

      late ProviderContainer container;
      var proceeded = 0;

      await _pumpStep(
        tester,
        connector: connector,
        onProceed: () => proceeded++,
        onAutoFillSuccess: () {},
        onContainerReady: (c) => container = c,
      );

      await tester.tap(find.text('Connect adapter'));
      await tester.pumpAndSettle();

      expect(proceeded, 1, reason: 'advances to the manual step');
      // The dialog must NOT show — VIN read returned null.
      expect(find.text('Yes, auto-fill'), findsNothing);
      final state = container.read(onboardingWizardControllerProvider);
      expect(state.obd2VinReadFailed, isTrue,
          reason: 'manual step surfaces a banner from this flag');
    });

    testWidgets('partial WMI decode → dialog renders the partial-info '
        'note (integration path, dialog behaviour comes from #861)',
        (tester) async {
      final service = _buildService();
      final connector = _FakeConnector(
        onConnect: () async => service,
        onReadVin: (_) async => 'VF36B8HZL8R123456',
      );
      final decoder = _StubDecoder(
        (vin) => VinData(
          vin: vin,
          make: 'Peugeot',
          country: 'France',
          source: VinDataSource.wmiOffline,
        ),
      );

      await _pumpStep(
        tester,
        connector: connector,
        vinDecoder: decoder,
        onProceed: () {},
        onAutoFillSuccess: () {},
      );

      await tester.tap(find.text('Connect adapter'));
      await tester.pumpAndSettle();

      // The #861 VinConfirmDialog surfaces the partial-info label in
      // its body — the onboarding step doesn't own that string, we
      // just assert the dialog rendered.
      expect(find.text('Is this your car?'), findsOneWidget);
      expect(find.textContaining('Partial info'), findsOneWidget);
    });

    testWidgets('user modifies manually in the confirm dialog → advances '
        'to the manual step with the VIN stashed on wizard state',
        (tester) async {
      final service = _buildService();
      final connector = _FakeConnector(
        onConnect: () async => service,
        onReadVin: (_) async => '1HGCM82633A004352',
      );
      final decoder = _StubDecoder(
        (vin) => VinData(
          vin: vin,
          make: 'Honda',
          model: 'Accord',
          modelYear: 2003,
          displacementL: 2.4,
          source: VinDataSource.vpic,
        ),
      );

      var proceeded = 0;
      var autoFilled = 0;
      late ProviderContainer container;

      await _pumpStep(
        tester,
        connector: connector,
        vinDecoder: decoder,
        onProceed: () => proceeded++,
        onAutoFillSuccess: () => autoFilled++,
        onContainerReady: (c) => container = c,
      );

      await tester.tap(find.text('Connect adapter'));
      await tester.pumpAndSettle();

      // Choose "Modify manually".
      expect(find.text('Modify manually'), findsOneWidget);
      await tester.tap(find.text('Modify manually'));
      await tester.pumpAndSettle();

      expect(proceeded, 1);
      expect(autoFilled, 0);
      // The VIN is stashed on wizard state so a future pre-fill can
      // pick it up; engine fields stay blank because the user opted
      // out of auto-fill.
      final state = container.read(onboardingWizardControllerProvider);
      expect(state.obd2VinData?.vin, '1HGCM82633A004352');
    });

    testWidgets('connect failure (connector returns null) → snackbar '
        'error and the skip button stays accessible', (tester) async {
      final connector = _FakeConnector(onConnect: () async => null);

      var proceeded = 0;

      await _pumpStep(
        tester,
        connector: connector,
        onProceed: () => proceeded++,
        onAutoFillSuccess: () {},
      );

      await tester.tap(find.text('Connect adapter'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining("Couldn't connect to the adapter"),
          findsOneWidget);
      // Step didn't advance — user can retry or skip.
      expect(proceeded, 0);
      // Skip button still reachable.
      expect(find.text('Maybe later'), findsOneWidget);
    });
  });

  group('OnboardingObd2Step — pairedAdapterMac persistence (#1310)', () {
    testWidgets(
      'happy path: connect + VIN read + confirm → saved profile carries '
      'the picked MAC on BOTH obd2AdapterMac AND pairedAdapterMac',
      (tester) async {
        const pickedMac = 'AA:BB:CC:11:22:33';
        final service = _buildService();
        final connector = _FakeConnector(
          onConnect: () async => service,
          onReadVin: (_) async => '1HGCM82633A004352',
          pickedMac: pickedMac,
        );
        final decoder = _StubDecoder(
          (vin) => VinData(
            vin: vin,
            make: 'Honda',
            model: 'Accord',
            modelYear: 2003,
            displacementL: 2.4,
            cylinderCount: 4,
            fuelTypePrimary: 'Gasoline',
            source: VinDataSource.vpic,
          ),
        );

        late ProviderContainer container;
        await _pumpStep(
          tester,
          connector: connector,
          vinDecoder: decoder,
          onProceed: () {},
          onAutoFillSuccess: () {},
          onContainerReady: (c) => container = c,
        );

        await tester.tap(find.text('Connect adapter'));
        await tester.pumpAndSettle();

        // Accept the auto-fill in the VIN confirm dialog.
        await tester.tap(find.text('Yes, auto-fill'));
        await tester.pumpAndSettle();

        // Without the #1310 fix, the saved profile carried no MAC at
        // all — the orchestrator's `pairedAdapterMac != null` gate
        // silently dropped the user.
        final vehicles = container.read(vehicleProfileListProvider);
        expect(vehicles, hasLength(1));
        final saved = vehicles.first;
        expect(saved.pairedAdapterMac, pickedMac,
            reason: 'auto-record orchestrator gates on pairedAdapterMac '
                'being non-empty (#1310)');
        expect(saved.obd2AdapterMac, pickedMac,
            reason: 'pinned-MAC fast path keys on obd2AdapterMac (#1188)');
      },
    );

    testWidgets(
      'connector reports an empty MAC → saved profile leaves '
      'pairedAdapterMac null (does not persist a bogus value)',
      (tester) async {
        final service = _buildService();
        final connector = _FakeConnector(
          onConnect: () async => service,
          onReadVin: (_) async => '1HGCM82633A004352',
          pickedMac: '', // production picker always supplies a non-empty
          // id, but defensively the empty case must not write a bogus
          // value into pairedAdapterMac.
        );
        final decoder = _StubDecoder(
          (vin) => VinData(
            vin: vin,
            make: 'Honda',
            model: 'Accord',
            modelYear: 2003,
            displacementL: 2.4,
            cylinderCount: 4,
            source: VinDataSource.vpic,
          ),
        );

        late ProviderContainer container;
        await _pumpStep(
          tester,
          connector: connector,
          vinDecoder: decoder,
          onProceed: () {},
          onAutoFillSuccess: () {},
          onContainerReady: (c) => container = c,
        );

        await tester.tap(find.text('Connect adapter'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, auto-fill'));
        await tester.pumpAndSettle();

        final saved = container.read(vehicleProfileListProvider).first;
        expect(saved.pairedAdapterMac, isNull);
        expect(saved.obd2AdapterMac, isNull);
      },
    );
  });
}

// --- helpers ---------------------------------------------------------

Future<void> _pumpStep(
  WidgetTester tester, {
  required OnboardingObd2Connector connector,
  required VoidCallback onProceed,
  required VoidCallback onAutoFillSuccess,
  VinDecoder? vinDecoder,
  void Function(ProviderContainer)? onContainerReady,
}) async {
  // The onboarding step may save a VehicleProfile via
  // [vehicleProfileListProvider], which normally writes through
  // [SettingsStorage] to Hive. Overriding [settingsStorageProvider]
  // with an in-memory fake keeps the save synchronous from the
  // widget's perspective — Hive's real file I/O would suspend on
  // futures the fake-async test clock can't flush, causing
  // pumpAndSettle to hang for the default 10-minute timeout.
  final fakeStorage = _InMemorySettingsStorage();
  final container = ProviderContainer(overrides: [
    onboardingObd2ConnectorProvider.overrideWithValue(connector),
    settingsStorageProvider.overrideWithValue(fakeStorage),
    if (vinDecoder != null) vinDecoderProvider.overrideWithValue(vinDecoder),
  ]);
  addTearDown(container.dispose);
  onContainerReady?.call(container);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: OnboardingObd2Step(
            onProceed: onProceed,
            onAutoFillSuccess: onAutoFillSuccess,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Obd2Service _buildService() => Obd2Service(FakeObd2Transport());

class _FakeConnector implements OnboardingObd2Connector {
  _FakeConnector({this.onConnect, this.onReadVin, this.pickedMac = ''});

  final Future<Obd2Service?> Function()? onConnect;
  final Future<String?> Function(Obd2Service)? onReadVin;

  /// MAC the fake reports as picked. Empty by default so legacy tests
  /// keep the original "no MAC threaded" behaviour; #1310 tests
  /// override with a real value to assert the persistence path.
  final String pickedMac;

  int connectCalls = 0;
  int readVinCalls = 0;

  @override
  Future<OnboardingObd2Session?> connect(BuildContext context) async {
    connectCalls++;
    final factory = onConnect;
    if (factory == null) return null;
    final service = await factory();
    if (service == null) return null;
    return OnboardingObd2Session(service: service, mac: pickedMac);
  }

  @override
  Future<String?> readVin(Obd2Service service) async {
    readVinCalls++;
    final factory = onReadVin;
    if (factory == null) return null;
    return factory(service);
  }
}

class _StubDecoder implements VinDecoder {
  _StubDecoder(this._fn);

  final VinData Function(String) _fn;
  final List<String> calls = [];

  @override
  Future<VinData?> decode(String vin) async {
    calls.add(vin);
    return _fn(vin);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Pure in-memory [SettingsStorage] used by the step tests. Synchronous
/// get/put semantics avoid the Hive → fake-async deadlock that broke
/// the first iteration of these tests (profile save suspended forever
/// under `pumpAndSettle`).
class _InMemorySettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _settings = {};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  bool get isSetupComplete => _settings['setup_complete'] == true;

  @override
  bool get isSetupSkipped => _settings['setup_skipped'] == true;

  @override
  Future<void> skipSetup() async {
    _settings['setup_skipped'] = true;
  }

  @override
  Future<void> resetSetupSkip() async {
    _settings.remove('setup_skipped');
  }
}
