// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'obd2_reattach_source.dart';
import 'obd2_service.dart';

/// #3915 (Epic #3914) — the re-adoption cycle breaker.
///
/// Field trip 2026-09-01: the trip rebound the SAME `Obd2Service`
/// instance every ~8.2 s for 43 minutes — a connected-flag corpse the
/// owner never recycled — and recorded zero engine samples. The reattach
/// source now proves adoption with a round-trip; this is the belt to
/// that brace: an instance that comes back and dies again twice within
/// [window] of its rebound is REFUSED for the rest of the trip, journaled
/// and breadcrumbed, and the source waits for a DIFFERENT instance
/// (handing the refused one back to the owner if it is still held).
/// Instance identity is `identical` — never equality, never a MAC.
class ReadoptionCycleBreaker implements Obd2AdoptionGate {
  ReadoptionCycleBreaker({
    required this.now,
    this.window = const Duration(seconds: 60),
    this.quickDropsToRefuse = 2,
  });

  /// Clock seam (the manager's `_now`).
  final DateTime Function() now;

  /// A drop this soon after the rebind counts as a quick re-drop.
  final Duration window;

  /// Quick re-drops of the SAME instance, in a row, that refuse it.
  final int quickDropsToRefuse;

  final Set<Obd2Service> _refused = Set<Obd2Service>.identity();
  Obd2Service? _lastAdopted;
  DateTime? _lastAdoptedAt;
  int _quickDrops = 0;

  @override
  bool isRefused(Obd2Service service) => _refused.contains(service);

  @override
  void noteAdopted(Obd2Service service) {
    if (!identical(service, _lastAdopted)) {
      // A different instance — the streak belongs to the old one.
      _lastAdopted = service;
      _quickDrops = 0;
    }
    _lastAdoptedAt = now();
  }

  /// A drop verdict fired. Returns the instance to refuse when this drop
  /// completes the cycle (the same instance re-dropped within [window]
  /// of its rebind, [quickDropsToRefuse] times in a row); null otherwise.
  Obd2Service? noteDrop() {
    final adopted = _lastAdopted;
    final at = _lastAdoptedAt;
    if (adopted == null || at == null) return null;
    if (now().difference(at) > window) {
      // A link that lived past the window earned its adoption.
      _quickDrops = 0;
      return null;
    }
    _quickDrops++;
    if (_quickDrops < quickDropsToRefuse) return null;
    _refused.add(adopted);
    return adopted;
  }
}
