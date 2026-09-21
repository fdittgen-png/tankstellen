// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One answer to "is this station open?", for every surface (#4179).
///
/// The rule is #4156's: **an absence is not a negative — nor a
/// positive.** Eleven of the seventeen registered countries publish no
/// opening hours for anybody, so for most of the app's stations the
/// honest answer is a third state, and a surface that collapses it makes
/// a claim the data does not support.
///
/// This library exists because the home-screen widget had invented the
/// rule twice, in opposite directions: the nearest-station builder read
/// an unknown as OPEN, the favorites builder read the same unknown as
/// CLOSED, and which one a user saw depended on which widget they had
/// placed. Both are wrong — `true` sends someone to a forecourt that may
/// be shut, `false` hides a station that is probably fine — and neither
/// was visible from the other's file.
library;

import '../domain/data_value.dart';
import 'country_service_registry.dart';

/// Resolve [published] — whatever the adapter put in `Station.isOpen` —
/// through the owning country's [ProviderCapability].
///
/// [stationId] is tried first because the id prefix is canonical;
/// [lat]/[lng] is the fallback for a station whose id carries no prefix.
/// An unregistered country yields
/// [DataUnknownReason.notPublishedByProvider]: we do not know what that
/// provider supports, and guessing is what this library prevents.
DataValue<bool> resolveStationOpenState({
  required String? stationId,
  required double? lat,
  required double? lng,
  required bool? published,
}) {
  final code = CountryServiceRegistry.countryForStationId(stationId) ??
      (lat == null || lng == null
          ? null
          : CountryServiceRegistry.countryForLatLng(lat, lng));
  final capability =
      code == null ? null : CountryServiceRegistry.capabilityFor(code);
  if (capability == null) {
    return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedByProvider);
  }
  return capability.openState(published);
}
