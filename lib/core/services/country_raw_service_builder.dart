// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'country_service_data.dart';
import 'country_service_dependencies.dart';
import 'impl/demo_station_service.dart';
import 'station_service.dart';

// #3746 — [CountryServiceDependencies] moved to its own file so the
// feature-side per-country factories can import it without pulling this
// dispatcher in; re-export it so existing
// `import '.../country_raw_service_builder.dart'` sites keep resolving it.
export 'country_service_dependencies.dart';

/// Builds the **raw** (un-chained) [StationService] for [countryCode] from
/// explicit [deps] — no Riverpod `Ref`, so the same wiring runs in the
/// WorkManager / BGAppRefresh background isolate that has no provider scope
/// (#2861).
///
/// #3746 — the old per-country `switch` is gone: each
/// `CountryServiceEntry` in [kCountryServiceEntries] now carries its own
/// `buildService` factory (living feature-side, next to the service it
/// constructs), so registering a country is one data row and this
/// dispatcher never changes again (open/closed).
///
/// This is still the single construction seam:
/// `CountryServiceRegistry`'s foreground `buildService(Ref)` resolves its
/// dependencies from the `Ref` and delegates here via
/// `buildBackgroundService`, so the foreground and the background isolate
/// share byte-identical per-country wiring.
///
/// Returns [DemoStationService] for an unregistered country — and the
/// API-key-gated factories (DE, KR, CL) themselves return it when no key
/// is configured, so a keyless user still sees realistic demo data.
StationService buildRawCountryService(
  String countryCode,
  CountryServiceDependencies deps,
) {
  for (final entry in kCountryServiceEntries) {
    if (entry.countryCode == countryCode) return entry.buildService(deps);
  }
  return DemoStationService(countryCode: countryCode);
}
