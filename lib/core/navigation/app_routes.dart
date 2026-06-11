// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/ev/charging_station.dart';
import '../domain/fuel_type.dart';

/// Single source of truth for every router path (#3135).
///
/// The route TABLE (`lib/app/routes/*.dart`) declares its `path:` from the
/// constants below, and every navigation call site goes through either a
/// constant (payload-free routes) or a typed [AppRoute] object (routes that
/// carry a path parameter or an `extra` payload). String literals in
/// `go`/`push` call sites are banned by
/// `test/lint/no_string_literal_routes_test.dart`.
///
/// ### Deep-link stability
/// The path VALUES are part of the app's external contract — home-screen
/// widgets (`widgetUriToPath` resolves to [station]/[evStationById]),
/// notification payloads (`NotificationPayload.toRouterPath` resolves to
/// [station]), and the OBD2 auto-record flow (`/trip-recording`, #3167)
/// all depend on them. Renaming a constant is fine; changing its VALUE is
/// a breaking deep-link change.
abstract final class RoutePaths {
  // Shell branches (bottom-nav tabs).
  static const search = '/';
  static const map = '/map';
  static const favorites = '/favorites';
  static const consumptionTab = '/consumption-tab';
  static const profile = '/profile';
  static const trajetsTab = '/trajets-tab';

  // Onboarding gates.
  static const consent = '/consent';
  static const setup = '/setup';

  // Search-adjacent pushes.
  static const driving = '/driving';
  static const alerts = '/alerts';
  static const calculator = '/calculator';

  // Profile / settings sub-screens.
  static const vehicles = '/vehicles';
  static const editVehicle = '/vehicles/edit';
  static const itineraries = '/itineraries';
  static const privacyDashboard = '/privacy-dashboard';
  static const themeSettings = '/theme-settings';
  static const loyaltySettings = '/loyalty-settings';
  static const developerTools = '/developer-tools';
  static const developerToolsErrorLog = '/developer-tools/error-log';
  static const developerToolsFlags = '/developer-tools/flags';
  static const developerToolsObd2Health = '/developer-tools/obd2-health';
  static const developerToolsOcrTester = '/developer-tools/ocr-tester';

  // Consumption / trips.
  static const consumption = '/consumption';
  static const carbon = '/carbon';
  static const consumptionStats = '/consumption-stats';
  static const pickStationForFillUp = '/consumption/pick-station';
  static const tripRecording = '/trip-recording';
  static const addFillUp = '/consumption/add';
  static const tripPattern = '/trip/:id';
  static String trip(String id) => '/trip/$id';

  // Station detail family.
  static const stationPattern = '/station/:id';
  static String station(String id) => '/station/$id';
  static const stationHistoryPattern = '/station/:id/history';
  static String stationHistory(String id) => '/station/$id/history';
  static const evStation = '/ev-station';
  static const evStationPattern = '/ev-station/:id';
  static String evStationById(String id) => '/ev-station/$id';
  static const reportPattern = '/report/:id';
  static String report(String id) => '/report/$id';

  // TankSync.
  static const syncSetup = '/sync-setup';
  static const linkDevice = '/link-device';
  static const dataTransparency = '/data-transparency';
  static const auth = '/auth';
}

/// A typed navigation target: a route that carries data — a path
/// parameter, an `extra` payload, or both (#3135).
///
/// Hand-rolled rather than `go_router_builder` `TypedGoRoute`s: the
/// builder package would be a new dependency and would force the whole
/// route table (including the `StatefulShellRoute`) into its codegen
/// shape; this sealed hierarchy types exactly what was untyped — the
/// `extra` payloads and id interpolation — while the table keeps its
/// existing `GoRoute` declarations and path strings byte-for-byte.
///
/// Payload-free routes don't get a subclass; call sites navigate with a
/// [RoutePaths] constant directly (`context.push(RoutePaths.alerts)`).
sealed class AppRoute {
  const AppRoute();

  /// The concrete location to navigate to (path parameters resolved).
  String get location;

  /// The typed payload passed through go_router's `extra`. The matching
  /// route builder in `lib/app/routes/` downcasts it back; both ends
  /// reference the same subclass so the shape can't silently drift.
  Object? get extra => null;

  void go(BuildContext context) => context.go(location, extra: extra);

  Future<T?> push<T extends Object?>(BuildContext context) =>
      context.push<T>(location, extra: extra);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: extra);
}

/// Fuel-station detail (`/station/:id`). Externally referenced: home-widget
/// taps and radius-alert notifications deep-link here by id.
final class StationDetailRoute extends AppRoute {
  const StationDetailRoute(this.stationId);
  final String stationId;
  @override
  String get location => RoutePaths.station(stationId);
}

/// Price-history chart for one station (`/station/:id/history`).
final class PriceHistoryRoute extends AppRoute {
  const PriceHistoryRoute(this.stationId);
  final String stationId;
  @override
  String get location => RoutePaths.stationHistory(stationId);
}

/// User price-report flow (`/report/:id`).
final class ReportRoute extends AppRoute {
  const ReportRoute(this.stationId);
  final String stationId;
  @override
  String get location => RoutePaths.report(stationId);
}

/// Trip detail (`/trip/:id`).
final class TripDetailRoute extends AppRoute {
  const TripDetailRoute(this.tripId);
  final String tripId;
  @override
  String get location => RoutePaths.trip(tripId);
}

/// EV station detail (`/ev-station`) with the in-memory [ChargingStation]
/// as the typed payload — the route the map overlay / search results /
/// favorites use when they already hold the full station (#3174 unified
/// detail screen). The id-only deep-link variant (`/ev-station/:id`)
/// hydrates by id instead and is reached via
/// [RoutePaths.evStationById] from the widget-URI parser.
final class EvStationDetailRoute extends AppRoute {
  const EvStationDetailRoute(this.station);
  final ChargingStation station;
  @override
  String get location => RoutePaths.evStation;
  @override
  Object? get extra => station;
}

/// Add-fill-up form (`/consumption/add`). Replaces the stringly-keyed
/// `Map<String, Object?>` extra (#3135): the route object itself crosses
/// as the payload, so the station pre-fill fields are compile-checked on
/// both sides. All fields optional — the redirect-driven shared-receipt
/// entry (#2735) and the "skip station" path open the bare form.
final class AddFillUpRoute extends AppRoute {
  const AddFillUpRoute({
    this.stationId,
    this.stationName,
    this.fuelType,
    this.pricePerLiter,
  });

  final String? stationId;
  final String? stationName;
  final FuelType? fuelType;
  final double? pricePerLiter;

  @override
  String get location => RoutePaths.addFillUp;
  @override
  Object? get extra => this;
}

/// Vehicle editor (`/vehicles/edit`). A null [vehicleId] opens the
/// "add vehicle" form; non-null edits the existing vehicle.
final class EditVehicleRoute extends AppRoute {
  const EditVehicleRoute({this.vehicleId});
  final String? vehicleId;
  @override
  String get location => RoutePaths.editVehicle;
  @override
  Object? get extra => vehicleId;
}

/// Fuel-cost calculator (`/calculator`), optionally pre-filled with the
/// cheapest visible price from the search results (#2543).
final class CalculatorRoute extends AppRoute {
  const CalculatorRoute({this.initialPrice});
  final double? initialPrice;
  @override
  String get location => RoutePaths.calculator;
  @override
  Object? get extra => initialPrice;
}
