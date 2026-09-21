// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/travel_estimate.dart';

/// The point a nearby result set's distances are measured FROM (#4359).
///
/// A refuelling errand starts where the driver is, which is what the
/// search already used to compute each row's distance: the user's known
/// position when there is one, else the search centre. The search entry
/// points publish that same point here, so road estimates for the result
/// set are routed from the origin the list's own numbers describe.
///
/// Null until a search has run — then there is nothing to route from and
/// the decision stays on its explicitly approximate crow-flies figures.
class RefuelTravelOrigin extends Notifier<TravelPoint?> {
  @override
  TravelPoint? build() => null;

  void set(TravelPoint? origin) => state = origin;
}

final refuelTravelOriginProvider =
    NotifierProvider<RefuelTravelOrigin, TravelPoint?>(RefuelTravelOrigin.new);
