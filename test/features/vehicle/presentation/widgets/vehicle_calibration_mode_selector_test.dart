import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_calibration_mode_selector.dart';
import 'package:tankstellen/features/vehicle/providers/calibration_mode_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Fake [VehicleProfileList] that lets tests seed an initial list and
/// records every call to [save] so widget interactions can be asserted
/// without wiring a real [VehicleProfileRepository].
class _FakeVehicleProfileList extends VehicleProfileList {
  _FakeVehicleProfileList(this._seed);

  final List<VehicleProfile> _seed;
  final List<VehicleProfile> savedProfiles = <VehicleProfile>[];

  @override
  List<VehicleProfile> build() => _seed;

  @override
  Future<void> save(VehicleProfile profile) async {
    savedProfiles.add(profile);
    final next = [..._seed.where((v) => v.id != profile.id), profile];
    state = next;
  }
}

/// Fake [CalibrationReplayQueue] that records every [requestReplay]
/// invocation so the widget's mode-flip side-effect can be asserted.
class _FakeReplayQueue extends CalibrationReplayQueue {
  final List<String> replayed = <String>[];

  @override
  List<String> build() => const <String>[];

  @override
  void requestReplay(String vehicleId) {
    replayed.add(vehicleId);
    super.requestReplay(vehicleId);
  }
}

Future<_FakeReplayQueue> _pumpSelector(
  WidgetTester tester, {
  required String vehicleId,
  required _FakeVehicleProfileList list,
  _FakeReplayQueue? replayQueue,
}) async {
  final queue = replayQueue ?? _FakeReplayQueue();
  await pumpApp(
    tester,
    VehicleCalibrationModeSelector(vehicleId: vehicleId),
    overrides: [
      vehicleProfileListProvider.overrideWith(() => list),
      calibrationReplayQueueProvider.overrideWith(() => queue),
    ],
  );
  return queue;
}

void main() {
  group('VehicleCalibrationModeSelector', () {
    testWidgets('renders SizedBox.shrink when the list is empty',
        (tester) async {
      final list = _FakeVehicleProfileList(const []);
      await _pumpSelector(tester, vehicleId: 'v1', list: list);

      expect(find.byType(Card), findsNothing);
      expect(find.byType(SegmentedButton<VehicleCalibrationMode>),
          findsNothing);
      // The widget itself is mounted but produces nothing visible.
      expect(find.byType(VehicleCalibrationModeSelector), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when the matching profile is missing',
        (tester) async {
      final list = _FakeVehicleProfileList(const [
        VehicleProfile(id: 'other', name: 'Other'),
      ]);
      await _pumpSelector(tester, vehicleId: 'v1', list: list);

      // firstWhere falls back to a synthetic empty-id profile, which the
      // widget treats as "not yet saved" and bails out.
      expect(find.byType(Card), findsNothing);
      expect(find.byType(SegmentedButton<VehicleCalibrationMode>),
          findsNothing);
    });

    testWidgets('renders the rule segment as selected for a rule profile',
        (tester) async {
      final list = _FakeVehicleProfileList(const [
        VehicleProfile(
          id: 'v1',
          name: 'Golf',
        ),
      ]);
      await _pumpSelector(tester, vehicleId: 'v1', list: list);

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Calibration mode'), findsOneWidget);
      expect(find.text('Rule-based'), findsOneWidget);
      expect(find.text('Fuzzy'), findsOneWidget);

      final segmented = tester.widget<SegmentedButton<VehicleCalibrationMode>>(
        find.byType(SegmentedButton<VehicleCalibrationMode>),
      );
      expect(segmented.selected, {VehicleCalibrationMode.rule});
    });

    testWidgets('renders the fuzzy segment as selected for a fuzzy profile',
        (tester) async {
      final list = _FakeVehicleProfileList(const [
        VehicleProfile(
          id: 'v1',
          name: 'Golf',
          calibrationMode: VehicleCalibrationMode.fuzzy,
        ),
      ]);
      await _pumpSelector(tester, vehicleId: 'v1', list: list);

      final segmented = tester.widget<SegmentedButton<VehicleCalibrationMode>>(
        find.byType(SegmentedButton<VehicleCalibrationMode>),
      );
      expect(segmented.selected, {VehicleCalibrationMode.fuzzy});
    });

    testWidgets('flipping rule → fuzzy persists the profile and enqueues a '
        'replay', (tester) async {
      final list = _FakeVehicleProfileList(const [
        VehicleProfile(
          id: 'v1',
          name: 'Golf',
        ),
      ]);
      final queue = await _pumpSelector(tester, vehicleId: 'v1', list: list);

      await tester.tap(find.text('Fuzzy'));
      await tester.pumpAndSettle();

      expect(list.savedProfiles, hasLength(1));
      expect(list.savedProfiles.single.id, 'v1');
      expect(
        list.savedProfiles.single.calibrationMode,
        VehicleCalibrationMode.fuzzy,
      );
      // Other fields must round-trip unchanged via copyWith.
      expect(list.savedProfiles.single.name, 'Golf');
      expect(queue.replayed, ['v1']);
    });

    testWidgets('tapping the already-selected mode is a no-op',
        (tester) async {
      final list = _FakeVehicleProfileList(const [
        VehicleProfile(
          id: 'v1',
          name: 'Golf',
        ),
      ]);
      final queue = await _pumpSelector(tester, vehicleId: 'v1', list: list);

      await tester.tap(find.text('Rule-based'));
      await tester.pumpAndSettle();

      expect(list.savedProfiles, isEmpty);
      expect(queue.replayed, isEmpty);
    });

    testWidgets('info icon exposes the tooltip text as a semantic label',
        (tester) async {
      final list = _FakeVehicleProfileList(const [
        VehicleProfile(
          id: 'v1',
          name: 'Golf',
        ),
      ]);
      await _pumpSelector(tester, vehicleId: 'v1', list: list);

      final info = tester.widget<Icon>(find.byIcon(Icons.info_outline));
      expect(info.semanticLabel, isNotNull);
      expect(info.semanticLabel, contains('Rule-based'));
      expect(info.semanticLabel, contains('Fuzzy'));
    });
  });
}
