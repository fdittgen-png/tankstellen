// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('NearbyMapView.shouldFit (#2177 guard predicate)', () {
    final boundsA = LatLngBounds(
      const LatLng(48.0, 2.0),
      const LatLng(49.0, 3.0),
    );
    final boundsAClone = LatLngBounds(
      const LatLng(48.0, 2.0),
      const LatLng(49.0, 3.0),
    );
    final boundsB = LatLngBounds(
      const LatLng(43.0, 3.0),
      const LatLng(44.0, 4.0),
    );

    test('first fit (last == null) always fits', () {
      expect(NearbyMapView.shouldFit(null, boundsA), isTrue);
    });

    test('identical (value-equal) bounds skip the re-fit', () {
      // A redundant rebuild (EV toggle, app resume) recomputes the SAME
      // bounds; the guard must skip scheduling another fitCamera.
      expect(NearbyMapView.shouldFit(boundsA, boundsAClone), isFalse);
      expect(NearbyMapView.shouldFit(boundsA, boundsA), isFalse);
    });

    test('changed bounds fit again', () {
      // A genuinely new search area must still fit.
      expect(NearbyMapView.shouldFit(boundsA, boundsB), isTrue);
    });
  });

  group('Camera lifecycle: initialCameraFit + single re-fit (#2399)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nearby_map_fit_test_');
      Hive.init(tempDir.path);
      await HiveStorage.initForTest();
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    const parisStations = [
      Station(
        id: 'fr-paris-1',
        name: 'Paris Station 1',
        brand: 'Total',
        street: 'Rue de Rivoli',
        houseNumber: '10',
        postCode: '75001',
        place: 'Paris',
        lat: 48.8606,
        lng: 2.3376,
        dist: 0.5,
        e10: 1.729,
        isOpen: true,
      ),
    ];

    const lyonStations = [
      Station(
        id: 'fr-lyon-1',
        name: 'Lyon Station 1',
        brand: 'BP',
        street: 'Rue de la Republique',
        houseNumber: '5',
        postCode: '69001',
        place: 'Lyon',
        lat: 45.7640,
        lng: 4.8357,
        dist: 0.3,
        e10: 1.699,
        isOpen: true,
      ),
    ];

    AsyncValue resultFor(List<Station> stations) => AsyncValue.data(
          ServiceResult(
            data: stations.map((s) => FuelStationResult(s)).toList(),
            source: ServiceSource.tankerkoenigApi,
            fetchedAt: DateTime.now(),
          ),
        );

    Widget viewFor(
      AsyncValue searchState,
      _CountingMapController controller,
    ) =>
        SizedBox(
          width: 800,
          height: 1000,
          child: NearbyMapView(
            searchState: searchState,
            selectedFuel: FuelType.e10,
            searchRadiusKm: 19,
            mapController: controller,
          ),
        );

    testWidgets(
      'first paint is framed by initialCameraFit + keepAlive; a same-bounds '
      'rebuild does NOT re-fit',
      (tester) async {
        final controller = _CountingMapController();
        addTearDown(controller.dispose);

        await pumpApp(
          tester,
          _Rebuildable(
            controller: controller,
            viewFor: viewFor,
            initial: resultFor(parisStations),
          ),
        );
        await tester.pumpAndSettle();

        // #2399 — first paint is positioned by `MapOptions.initialCameraFit`
        // applied during the first layout pass (flutter_map routes that one
        // application through the controller, hence the baseline of 1). The
        // OLD per-build post-frame `fitCamera` in NearbyMapView — which
        // raced the cold-start reset window — is gone.
        final flutterMap =
            tester.widget<FlutterMap>(find.byType(FlutterMap));
        expect(flutterMap.options.initialCameraFit, isNotNull,
            reason: 'first paint must be framed via initialCameraFit');
        expect(flutterMap.options.keepAlive, isTrue,
            reason: 'keepAlive must be set so a tab flip keeps the tiles');
        final baseline = controller.fitCount;
        expect(baseline, lessThanOrEqualTo(1),
            reason: 'at most the single initialCameraFit application');

        // A genuine rebuild recomputing the SAME bounds (new ServiceResult
        // object, same Paris station) must NOT add a re-fit — `LatLngBounds`
        // value `==` makes the guard skip it.
        final state =
            tester.state<_RebuildableState>(find.byType(_Rebuildable));
        state.show(resultFor(parisStations));
        await tester.pumpAndSettle();

        expect(controller.fitCount, baseline,
            reason: 'an unchanged fit target must NOT re-fit the camera');
      },
    );

    testWidgets(
      'exactly one re-fit per distinct search bounds (no fit loop)',
      (tester) async {
        final controller = _CountingMapController();
        addTearDown(controller.dispose);

        await pumpApp(
          tester,
          _Rebuildable(
            controller: controller,
            viewFor: viewFor,
            initial: resultFor(parisStations),
          ),
        );
        await tester.pumpAndSettle();

        // Baseline = the single initialCameraFit application on first paint.
        final baseline = controller.fitCount;

        // Swap to a different search area (Lyon): the centre changes value,
        // so `StationMapLayers.didUpdateWidget` schedules exactly ONE fit.
        final state =
            tester.state<_RebuildableState>(find.byType(_Rebuildable));
        state.show(resultFor(lyonStations));
        await tester.pumpAndSettle();

        expect(controller.fitCount, baseline + 1,
            reason: 'a genuinely changed centre fits exactly once');

        // Settle does not loop: a fit→rebuild→fit cycle would keep
        // incrementing. `_lastFitBounds` is set at schedule time, so the
        // post-fit rebuild recomputes the same bounds and skips.
        await tester.pump(const Duration(milliseconds: 32));
        expect(controller.fitCount, baseline + 1, reason: 'no fit loop');

        // Back to Paris: a third distinct bounds → one more fit.
        state.show(resultFor(parisStations));
        await tester.pumpAndSettle();
        expect(controller.fitCount, baseline + 2,
            reason: 'each distinct bounds fits exactly once');
      },
    );
  });
}

/// A [MapController] that counts `fitCamera` calls while behaving exactly
/// like the real controller (it subclasses [MapControllerImpl], so it binds
/// to the [FlutterMap] correctly and every other member is the genuine
/// implementation). Lets the test observe how many real fits NearbyMapView
/// actually scheduled — the #2177 regression surface.
class _CountingMapController extends MapControllerImpl {
  int fitCount = 0;

  @override
  bool fitCamera(CameraFit cameraFit) {
    fitCount++;
    return super.fitCamera(cameraFit);
  }
}

/// Test harness whose [State] can swap the [searchState] passed to
/// NearbyMapView, so a test can drive a genuine (or value-equal) rebuild.
class _Rebuildable extends StatefulWidget {
  final _CountingMapController controller;
  final Widget Function(AsyncValue, _CountingMapController) viewFor;
  final AsyncValue initial;

  const _Rebuildable({
    required this.controller,
    required this.viewFor,
    required this.initial,
  });

  @override
  State<_Rebuildable> createState() => _RebuildableState();
}

class _RebuildableState extends State<_Rebuildable> {
  late AsyncValue _state = widget.initial;

  void show(AsyncValue next) => setState(() => _state = next);

  @override
  Widget build(BuildContext context) =>
      widget.viewFor(_state, widget.controller);
}
