// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/services/country_service_dependencies.dart';
import '../../../core/services/station_service.dart';
import 'mexico_station_service.dart';

/// Builds the MX raw [StationService] — the `CountryServiceEntry.buildService`
/// factory (#3746). Takes [CountryServiceDependencies], never a Riverpod
/// `Ref`, so the identical wiring runs in the background isolate (#2861).
/// Lives in its own file (the `*_service_builder.dart` pattern) because the
/// service file sits at the #1680 400-line limit.
StationService buildMxStationService(CountryServiceDependencies deps) =>
    MexicoStationService(cache: deps.cache);
