// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What is in the tank, and how much it holds (#4146).
@immutable
class TankState {
  const TankState({required this.capacityL, required this.currentL});

  /// Configured or catalog tank capacity. Null when unknown — and a plan
  /// then refuses to compute, because range is the whole constraint and
  /// a default capacity would silently invent it.
  final double? capacityL;

  /// Litres estimated in the tank now (level v2, #3645), or null.
  final double? currentL;

  bool get isComplete =>
      (capacityL ?? 0) > 0 && currentL != null && currentL! >= 0;
}

/// Declared in core so the route screen can plan without importing
/// `fill_ups`; overridden at the composition root with the real
/// estimate, exactly as `refuelProfileProvider` is (#4089).
///
/// Defaults to an empty state rather than a guess: every consumer must
/// already handle "not known", because most users have no capacity on
/// file and no OBD2 level.
final tankStateProvider = Provider<TankState>(
  (ref) => const TankState(capacityL: null, currentL: null),
);
