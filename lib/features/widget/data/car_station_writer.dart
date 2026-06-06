// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import 'car_station_data.dart';

/// Android Auto v1 — persists the latest in-app Search / Radar station lists
/// into the same SharedPreferences file the home-widget already uses
/// (`HomeWidgetPreferences`), under the [CarStationData.searchKey] /
/// [CarStationData.radarKey] keys the native car screens read.
///
/// This is the v1 stand-in for a live data bridge: the headless-engine
/// MethodChannel bridge is deferred to the v2 rewrite (#2947). Reusing the
/// `home_widget` SharedPreferences write means the car list is exactly as
/// fresh as the last in-app search/radar — good enough to test Android Auto on
/// the Desktop Head Unit and the internal track today.
///
/// **Never throws** — a write failure (e.g. no platform channel in a unit
/// test, or a background isolate) is logged and swallowed so it can never
/// surface in the search / radar UI.
class CarStationWriter {
  const CarStationWriter();

  /// Persist [stations] (already distance-sorted by the caller) as the latest
  /// search result list for the car Search screen.
  Future<void> writeSearch(List<Station> stations, FuelType fuel) =>
      _write(CarStationData.searchKey, stations, fuel, 'search');

  /// Persist [stations] (already distance-sorted by the caller) as the latest
  /// radar result list for the car Radar screen.
  Future<void> writeRadar(List<Station> stations, FuelType fuel) =>
      _write(CarStationData.radarKey, stations, fuel, 'radar');

  Future<void> _write(
    String key,
    List<Station> stations,
    FuelType fuel,
    String which,
  ) async {
    try {
      await HomeWidget.saveWidgetData(key, CarStationData.encode(stations, fuel));
    } catch (e, st) {
      // Best-effort car-data mirror — a SharedPreferences write fault never
      // breaks search/radar; the car UI just shows the previous (or empty)
      // list. The no-platform-channel / no-binding case is EXPECTED in unit
      // tests + background isolates, and a write fault here is never
      // actionable, so it goes to debugPrint only (no exportable-log spam).
      // The v2 rewrite (#2947) replaces this whole mirror with a live bridge.
      debugPrint('CarStationWriter.$which skipped (write failed): $e\n$st');
    }
  }
}
