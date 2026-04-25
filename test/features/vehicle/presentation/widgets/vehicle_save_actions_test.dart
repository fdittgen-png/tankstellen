import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_save_actions.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Unit + harness tests for `vehicle_save_actions.dart` (#561 coverage).
///
/// Covers two surfaces:
///  - the pure top-level [deriveFuelTypeFromVehicle] helper, exercised
///    directly with `VehicleProfile` fixtures;
///  - the [VehicleSaveActions] extension on `WidgetRef`, exercised
///    through a small [ConsumerWidget] harness so we can capture a
///    real `WidgetRef` against an overridden [ProviderContainer].

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// Captures a `WidgetRef` so the test can invoke extension methods on
/// it. The optional [onBuild] runs synchronously inside `build`, which
/// is the only context where `ref.watch(...)` is legal.
class _RefHost extends ConsumerWidget {
  const _RefHost({required this.refKey, this.onBuild});

  final GlobalKey refKey;
  final void Function(WidgetRef ref)? onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild?.call(ref);
    // The KeyedSubtree is just a stable host so we can find the ref via
    // its parent's WidgetRef; the actual capture happens via
    // [_capturedRefHolder] below.
    _capturedRefHolder.ref = ref;
    return const SizedBox.shrink(key: ValueKey('ref-host-body'));
  }
}

/// Tiny mutable holder so each test can read the captured ref after
/// `tester.pumpWidget` returns.
class _CapturedRef {
  WidgetRef? ref;
}

final _capturedRefHolder = _CapturedRef();

Future<WidgetRef> _pumpAndCaptureRef(
  WidgetTester tester, {
  required List<Object> overrides,
  void Function(WidgetRef ref)? onBuild,
}) async {
  _capturedRefHolder.ref = null;
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        home: _RefHost(refKey: key, onBuild: onBuild),
      ),
    ),
  );
  final captured = _capturedRefHolder.ref;
  if (captured == null) {
    throw StateError('WidgetRef was not captured during pumpWidget.');
  }
  return captured;
}

// ---------------------------------------------------------------------------
// Fakes for the notifiers we need to observe / override
// ---------------------------------------------------------------------------

/// Overrides the active-profile notifier with a fixed value plus a
/// call-recording `refresh()`.
class _FakeActiveProfile extends ActiveProfile {
  _FakeActiveProfile(this._initial);
  final UserProfile? _initial;
  int refreshCallCount = 0;

  @override
  UserProfile? build() => _initial;

  @override
  void refresh() {
    refreshCallCount += 1;
  }
}

/// Overrides the vehicle list with a fixed seed plus a recording
/// `save(...)`.
class _FakeVehicleList extends VehicleProfileList {
  _FakeVehicleList(this._initial);
  final List<VehicleProfile> _initial;
  final List<VehicleProfile> savedProfiles = [];

  @override
  List<VehicleProfile> build() => _initial;

  @override
  Future<void> save(VehicleProfile profile) async {
    savedProfiles.add(profile);
    state = [
      for (final v in state)
        if (v.id == profile.id) profile else v,
      if (state.every((v) => v.id != profile.id)) profile,
    ];
  }
}

/// Overrides the fill-up list with a fixed seed.
class _FakeFillUpList extends FillUpList {
  _FakeFillUpList(this._initial);
  final List<FillUp> _initial;

  @override
  List<FillUp> build() => _initial;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

VehicleProfile _vehicle({
  String id = 'v1',
  String name = 'Test',
  VehicleType type = VehicleType.combustion,
  String? preferredFuelType,
  double volumetricEfficiency = 0.85,
  int volumetricEfficiencySamples = 0,
}) {
  return VehicleProfile(
    id: id,
    name: name,
    type: type,
    preferredFuelType: preferredFuelType,
    volumetricEfficiency: volumetricEfficiency,
    volumetricEfficiencySamples: volumetricEfficiencySamples,
  );
}

UserProfile _userProfile({
  String id = 'p1',
  String? defaultVehicleId,
  FuelType preferredFuelType = FuelType.e10,
}) {
  return UserProfile(
    id: id,
    name: 'profile',
    preferredFuelType: preferredFuelType,
    defaultVehicleId: defaultVehicleId,
  );
}

FillUp _fillUp({
  required String id,
  required String? vehicleId,
  required double odometerKm,
  int daysAgo = 0,
}) {
  return FillUp(
    id: id,
    date: DateTime(2026, 4, 24).subtract(Duration(days: daysAgo)),
    liters: 40,
    totalCost: 60,
    odometerKm: odometerKm,
    fuelType: FuelType.e10,
    vehicleId: vehicleId,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_userProfile());
  });

  // -------------------------------------------------------------------------
  // deriveFuelTypeFromVehicle — pure unit tests
  // -------------------------------------------------------------------------

  group('deriveFuelTypeFromVehicle', () {
    test('EV vehicle → FuelType.electric (preferredFuelType ignored)', () {
      final v = _vehicle(type: VehicleType.ev, preferredFuelType: 'diesel');
      expect(deriveFuelTypeFromVehicle(v), FuelType.electric);
    });

    test('combustion + "e10" → FuelType.e10', () {
      final v = _vehicle(preferredFuelType: 'e10');
      expect(deriveFuelTypeFromVehicle(v), FuelType.e10);
    });

    test('combustion + "diesel" → FuelType.diesel', () {
      final v = _vehicle(preferredFuelType: 'diesel');
      expect(deriveFuelTypeFromVehicle(v), FuelType.diesel);
    });

    test('combustion + null preferredFuelType → null', () {
      final v = _vehicle(preferredFuelType: null);
      expect(deriveFuelTypeFromVehicle(v), isNull);
    });

    test('combustion + empty preferredFuelType → null', () {
      final v = _vehicle(preferredFuelType: '');
      expect(deriveFuelTypeFromVehicle(v), isNull);
    });

    test('combustion + whitespace preferredFuelType → null', () {
      final v = _vehicle(preferredFuelType: '   ');
      expect(deriveFuelTypeFromVehicle(v), isNull);
    });

    test(
      'combustion + unknown raw string → FuelType.all '
      '(fromString catch-all)',
      () {
        // Documents the current contract: `FuelType.fromString` falls
        // back to `FuelType.all` for unknown values rather than null,
        // so the helper passes that meta-fuel through.
        final v = _vehicle(preferredFuelType: 'plutonium');
        expect(deriveFuelTypeFromVehicle(v), FuelType.all);
      },
    );

    test('hybrid vehicle keeps combustion fuel (no EV shortcut)', () {
      // The doc-comment on the helper notes hybrids fall through the
      // EV branch until #704 ships — the parsed combustion fuel wins.
      final v = _vehicle(type: VehicleType.hybrid, preferredFuelType: 'e5');
      expect(deriveFuelTypeFromVehicle(v), FuelType.e5);
    });
  });

  // -------------------------------------------------------------------------
  // VehicleSaveActions.syncActiveProfile
  // -------------------------------------------------------------------------

  group('VehicleSaveActions.syncActiveProfile', () {
    testWidgets('no active profile → does nothing', (tester) async {
      final repo = _MockProfileRepository();
      final fakeActive = _FakeActiveProfile(null);

      final ref = await _pumpAndCaptureRef(
        tester,
        overrides: [
          profileRepositoryProvider.overrideWithValue(repo),
          activeProfileProvider.overrideWith(() => fakeActive),
        ],
      );

      await ref.syncActiveProfile(_vehicle(id: 'v1'));

      verifyNever(() => repo.updateProfile(any()));
      expect(fakeActive.refreshCallCount, 0);
    });

    testWidgets(
      'defaultVehicleId == profile.id → updateProfile + refresh called',
      (tester) async {
        final repo = _MockProfileRepository();
        when(() => repo.updateProfile(any())).thenAnswer((_) async {});
        final initial = _userProfile(
          defaultVehicleId: 'v1',
          preferredFuelType: FuelType.e5,
        );
        final fakeActive = _FakeActiveProfile(initial);

        final ref = await _pumpAndCaptureRef(
          tester,
          overrides: [
            profileRepositoryProvider.overrideWithValue(repo),
            activeProfileProvider.overrideWith(() => fakeActive),
          ],
        );

        await ref.syncActiveProfile(_vehicle(
          id: 'v1',
          preferredFuelType: 'diesel',
        ));

        final captured = verify(() => repo.updateProfile(captureAny()))
            .captured
            .single as UserProfile;
        expect(captured.defaultVehicleId, 'v1');
        expect(captured.preferredFuelType, FuelType.diesel);
        expect(fakeActive.refreshCallCount, 1);
      },
    );

    testWidgets(
      'no defaultVehicleId yet → adopts the saved vehicle as default',
      (tester) async {
        final repo = _MockProfileRepository();
        when(() => repo.updateProfile(any())).thenAnswer((_) async {});
        final initial = _userProfile(
          defaultVehicleId: null,
          preferredFuelType: FuelType.e5,
        );
        final fakeActive = _FakeActiveProfile(initial);

        final ref = await _pumpAndCaptureRef(
          tester,
          overrides: [
            profileRepositoryProvider.overrideWithValue(repo),
            activeProfileProvider.overrideWith(() => fakeActive),
          ],
        );

        await ref.syncActiveProfile(_vehicle(
          id: 'v-new',
          preferredFuelType: 'e10',
        ));

        final captured = verify(() => repo.updateProfile(captureAny()))
            .captured
            .single as UserProfile;
        expect(captured.defaultVehicleId, 'v-new');
        expect(captured.preferredFuelType, FuelType.e10);
        expect(fakeActive.refreshCallCount, 1);
      },
    );

    testWidgets(
      'defaultVehicleId differs from saved vehicle → no-op',
      (tester) async {
        final repo = _MockProfileRepository();
        final initial = _userProfile(defaultVehicleId: 'other');
        final fakeActive = _FakeActiveProfile(initial);

        final ref = await _pumpAndCaptureRef(
          tester,
          overrides: [
            profileRepositoryProvider.overrideWithValue(repo),
            activeProfileProvider.overrideWith(() => fakeActive),
          ],
        );

        await ref.syncActiveProfile(_vehicle(id: 'v1'));

        verifyNever(() => repo.updateProfile(any()));
        expect(fakeActive.refreshCallCount, 0);
      },
    );

    testWidgets(
      'derived fuel is null → keeps the existing profile preferredFuelType',
      (tester) async {
        // Vehicle has no preferred fuel string, so the helper returns
        // null and the extension must not clobber the user's existing
        // profile fuel preference.
        final repo = _MockProfileRepository();
        when(() => repo.updateProfile(any())).thenAnswer((_) async {});
        final initial = _userProfile(
          defaultVehicleId: 'v1',
          preferredFuelType: FuelType.dieselPremium,
        );
        final fakeActive = _FakeActiveProfile(initial);

        final ref = await _pumpAndCaptureRef(
          tester,
          overrides: [
            profileRepositoryProvider.overrideWithValue(repo),
            activeProfileProvider.overrideWith(() => fakeActive),
          ],
        );

        await ref.syncActiveProfile(_vehicle(
          id: 'v1',
          preferredFuelType: null,
        ));

        final captured = verify(() => repo.updateProfile(captureAny()))
            .captured
            .single as UserProfile;
        expect(captured.preferredFuelType, FuelType.dieselPremium);
        expect(captured.defaultVehicleId, 'v1');
      },
    );
  });

  // -------------------------------------------------------------------------
  // VehicleSaveActions.resetVolumetricEfficiency
  // -------------------------------------------------------------------------

  group('VehicleSaveActions.resetVolumetricEfficiency', () {
    testWidgets(
      'vehicle present → save called with VE = 0.85 and samples = 0',
      (tester) async {
        final seeded = _vehicle(
          id: 'v1',
          volumetricEfficiency: 0.71,
          volumetricEfficiencySamples: 7,
        );
        final fakeList = _FakeVehicleList([seeded]);

        final ref = await _pumpAndCaptureRef(
          tester,
          overrides: [
            vehicleProfileListProvider.overrideWith(() => fakeList),
          ],
        );

        await ref.resetVolumetricEfficiency('v1');

        expect(fakeList.savedProfiles, hasLength(1));
        final saved = fakeList.savedProfiles.single;
        expect(saved.id, 'v1');
        expect(saved.volumetricEfficiency, 0.85);
        expect(saved.volumetricEfficiencySamples, 0);
      },
    );

    testWidgets('vehicle missing → no save', (tester) async {
      final fakeList = _FakeVehicleList([_vehicle(id: 'v1')]);

      final ref = await _pumpAndCaptureRef(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => fakeList),
        ],
      );

      await ref.resetVolumetricEfficiency('not-there');

      expect(fakeList.savedProfiles, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // VehicleSaveActions.latestOdometerKm
  // -------------------------------------------------------------------------

  group('VehicleSaveActions.latestOdometerKm', () {
    testWidgets(
      'returns the highest odometer reading for the vehicle',
      (tester) async {
        final fillUps = [
          _fillUp(id: 'a', vehicleId: 'v1', odometerKm: 12000, daysAgo: 30),
          _fillUp(id: 'b', vehicleId: 'v1', odometerKm: 13500, daysAgo: 5),
          _fillUp(id: 'c', vehicleId: 'v1', odometerKm: 12800, daysAgo: 15),
          // Different vehicle — must be excluded from the lookup.
          _fillUp(id: 'd', vehicleId: 'v2', odometerKm: 99999, daysAgo: 1),
        ];

        double? observed;
        await _pumpAndCaptureRef(
          tester,
          overrides: [
            fillUpListProvider.overrideWith(() => _FakeFillUpList(fillUps)),
          ],
          onBuild: (ref) {
            observed = ref.latestOdometerKm('v1');
          },
        );

        expect(observed, 13500);
      },
    );

    testWidgets(
      'no fill-ups for the vehicle → null',
      (tester) async {
        final fillUps = [
          _fillUp(id: 'a', vehicleId: 'v2', odometerKm: 12000),
        ];

        double? observed = -1;
        await _pumpAndCaptureRef(
          tester,
          overrides: [
            fillUpListProvider.overrideWith(() => _FakeFillUpList(fillUps)),
          ],
          onBuild: (ref) {
            observed = ref.latestOdometerKm('v1');
          },
        );

        expect(observed, isNull);
      },
    );

    testWidgets(
      'empty fill-up list → null',
      (tester) async {
        double? observed = -1;
        await _pumpAndCaptureRef(
          tester,
          overrides: [
            fillUpListProvider.overrideWith(() => _FakeFillUpList(const [])),
          ],
          onBuild: (ref) {
            observed = ref.latestOdometerKm('v1');
          },
        );

        expect(observed, isNull);
      },
    );
  });
}
