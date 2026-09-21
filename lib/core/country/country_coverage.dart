// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../domain/fuel_type.dart';
import '../services/country_service_registry.dart';
import 'country_config.dart';
import 'country_fuel_capability.dart';

/// Serializable coverage shared by route and nearby country setup.
enum CountryCoverageStatus {
  configured,
  missingProfile,
  unsupported,
  configurationRequired,
  unavailableFuel,
  serviceFailed,
}

class CountryCoverage {
  const CountryCoverage({
    required this.countryCode,
    required this.status,
    this.fuel,
  });

  final String countryCode;
  final CountryCoverageStatus status;
  final FuelType? fuel;
  bool get canSetUp => status == CountryCoverageStatus.missingProfile;

  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'status': status.name,
    'fuel': fuel?.name,
  };

  factory CountryCoverage.fromJson(Map<String, dynamic> json) => CountryCoverage(
    countryCode: json['countryCode'] as String,
    status: CountryCoverageStatus.values.byName(json['status'] as String),
    fuel: json['fuel'] == null
        ? null
        // `FuelType` is a sealed class with a static `values` list, not
        // an enum — `byName` is an enum-only extension. `fromString` is
        // the round-trip partner of `apiValue` every consumer uses.
        : FuelType.fromString(json['fuel'] as String),
  );
}

/// Uses the existing registry and fuel resolver; never invents a query fuel.
List<CountryCoverage> analyzeCountryCoverage({
  required Iterable<String> countries,
  required Map<String, FuelType> configuredFuels,
  required FuelType sourceFuel,
  required bool Function(String) hasApiKey,
}) {
  final configured = {
    for (final entry in configuredFuels.entries)
      entry.key.trim().toUpperCase(): entry.value,
  };
  return countries.map((code) => code.trim().toUpperCase()).toSet().map((code) {
    final config = Countries.byCode(code);
    final service = CountryServiceRegistry.entryFor(code);
    if (config == null || !config.verified || service == null) {
      return CountryCoverage(
        countryCode: code, status: CountryCoverageStatus.unsupported);
    }
    if (service.requiresApiKey && !hasApiKey(code)) {
      return CountryCoverage(
        countryCode: code, status: CountryCoverageStatus.configurationRequired);
    }
    if (configured.containsKey(code)) {
      return CountryCoverage(countryCode: code,
        status: CountryCoverageStatus.configured, fuel: configured[code]);
    }
    final resolved = CountryFuelCapability.resolveForCountry(
      countryCode: code, sourceFuel: sourceFuel);
    return CountryCoverage(countryCode: code, fuel: resolved.fuel,
      status: resolved.isResolved ? CountryCoverageStatus.missingProfile
          : CountryCoverageStatus.unavailableFuel);
  }).toList(growable: false);
}
