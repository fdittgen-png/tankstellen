// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../error/exceptions.dart';
import '../telemetry/collectors/breadcrumb_collector.dart';

/// #3455 — the chain-level guard that keeps non-fuel station ids out of
/// the fuel-price service chains.
///
/// OpenChargeMap EV stations carry `ocm-*` ids (see `OcmPoiParser`).
/// `Countries.countryCodeForStationId` returns null for them (no
/// fuel-country prefix), so any caller that falls back to "the active
/// country's fuel service" ends up sending an EV id to a fuel detail
/// endpoint — the field-verified 400 burst on FR/UK/LU
/// (`detail:ocm-196522`, ~1/s on every refresh).
///
/// Two layers use this:
///
///  1. `stationDetail` routes `ocm-*` ids to the cached EV station BEFORE
///     any fuel-chain fallback (the actual fix), and
///  2. `StationServiceChain.getStationDetail` calls [rejectNonFuelStationId]
///     as defense-in-depth so no future caller can re-introduce the storm:
///     the throw happens BEFORE the cache/transient-retry machinery, so the
///     rejection is non-retrying and writes no cache entry.
///
/// The rejection is an EXPECTED routing violation, not an upstream outage,
/// so it is recorded as a breadcrumb (the #3370 de-noise pattern of
/// `logStationApiFailure`) instead of flooding the error log at burst rate.

/// Whether [stationId] belongs to a non-fuel source (OpenChargeMap EV).
bool isNonFuelStationId(String stationId) => stationId.startsWith('ocm-');

/// Throws a typed [NonFuelStationIdException] when [stationId] is a
/// non-fuel id, after recording an actionable breadcrumb. No-op for
/// fuel ids.
void rejectNonFuelStationId(String stationId, {required String countryCode}) {
  if (!isNonFuelStationId(stationId)) return;
  BreadcrumbCollector.add(
    'service: non-fuel id rejected ($countryCode)',
    detail: 'EV id "$stationId" reached a fuel-price chain — routed callers '
        'must serve it from the EV detail source (#3455)',
  );
  throw NonFuelStationIdException(stationId);
}
