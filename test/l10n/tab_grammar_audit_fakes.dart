// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorite_stations_provider.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Provider fakes for `tab_grammar_audit_test.dart` (#3951) — fixed-value
/// notifiers so each tab body can be pumped in its empty and one-item
/// states without Hive or the network.

// ── Alerts ──────────────────────────────────────────────────────────────

PriceAlert auditAlert() => PriceAlert(
      id: 'a1',
      stationId: 'station-1',
      stationName: 'Shell Berlin',
      fuelType: FuelType.e10,
      targetPrice: 1.50,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

class FixedAlerts extends AlertNotifier {
  FixedAlerts(this._alerts);
  final List<PriceAlert> _alerts;
  @override
  List<PriceAlert> build() => _alerts;
}

class EmptyRadiusAlerts extends RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() async => const [];
}

// ── Favorites ───────────────────────────────────────────────────────────

class LoadedFavoriteStations extends FavoriteStations {
  LoadedFavoriteStations(this._stations);
  final List<Station> _stations;

  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.data(
        ServiceResult(
          data: _stations,
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime(2026, 3, 11, 14, 15),
        ),
      );
}

// ── Trips ───────────────────────────────────────────────────────────────

class FixedTripHistoryList extends TripHistoryList {
  FixedTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;
  @override
  List<TripHistoryEntry> build() => _value;
}

class FixedVehicleProfileList extends VehicleProfileList {
  FixedVehicleProfileList(this._value);
  final List<VehicleProfile> _value;
  @override
  List<VehicleProfile> build() => _value;
}

class FixedActiveVehicle extends ActiveVehicleProfile {
  FixedActiveVehicle(this._value);
  final VehicleProfile? _value;
  @override
  VehicleProfile? build() => _value;
}
