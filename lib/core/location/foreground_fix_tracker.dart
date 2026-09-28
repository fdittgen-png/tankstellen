// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../error/guarded.dart';
import '../time/app_clock.dart';
import 'position_fix_policy.dart';

/// Settings a non-recording foreground surface joins the shared position
/// stream with (#4432). Coarse on purpose: a map dot needs ~100 m, not
/// the recorder's 1 s high-accuracy cadence — and a non-recording
/// consumer never re-configures an upstream a recording already owns
/// (#2766 / #4353), so this cannot degrade a trip in progress.
const LocationSettings kForegroundFixSettings = LocationSettings(
  accuracy: LocationAccuracy.medium,
  distanceFilter: 25,
);

/// The latest CURRENT device position a visible surface may show
/// (#4432).
///
/// Wraps one subscription to a position stream — in production the
/// shared, refcounted `GeolocatorWrapper.sharedPositionStream` — and
/// exposes [fix]: the newest sample that passed [rejectFix] when it
/// arrived, or null. Two things the stream alone would get wrong:
///
/// * The shared source REPLAYS its last fix to a late joiner, and a
///   platform may answer from a cache. Every sample is judged by its own
///   timestamp, so a replayed or cached fix never passes as current.
/// * A fix accepted a minute ago is not current forever. [fix] drops
///   back to null once the accepted sample ages past
///   [kRouteOriginMaxFixAge] with nothing newer, so a dot cannot outlive
///   the evidence for it.
///
/// Non-recording and owner-driven: [start] / [stop] follow the surface's
/// own visibility and app lifecycle; it never requests permission and
/// never starts a search.
class ForegroundFixTracker {
  ForegroundFixTracker({
    required this._open,
    required this._clock,
  });

  final Stream<Position> Function() _open;
  final AppClock _clock;

  final ValueNotifier<AcceptedDeviceFix?> fix =
      ValueNotifier<AcceptedDeviceFix?>(null);

  StreamSubscription<Position>? _sub;
  Timer? _expiry;
  bool _disposed = false;

  /// Whether the position stream is currently subscribed.
  bool get isListening => _sub != null;

  void start() {
    if (_disposed || _sub != null) return;
    _sub = _open().listen(
      _onPosition,
      onError: (Object e, StackTrace st) =>
          logFailure(e, st, where: 'ForegroundFixTracker'),
    );
  }

  /// Release the subscription (hidden, paused). The last accepted fix
  /// stays until it ages out — or until [revalidate] after a resume.
  Future<void> stop() {
    // Cleared before the cancel completes, so a resume arriving mid-cancel
    // re-subscribes instead of finding a dying subscription.
    final cancelled = _sub?.cancel();
    _sub = null;
    return cancelled ?? Future<void>.value();
  }

  /// Drop [fix] if it has aged past the freshness bound — call on resume,
  /// where the expiry timer may have been suspended with the app.
  void revalidate() {
    final current = fix.value;
    if (current == null || _disposed) return;
    if (current.isCurrentAt(_clock.now())) {
      _scheduleExpiry(current);
    } else {
      _expiry?.cancel();
      fix.value = null;
    }
  }

  void _onPosition(Position position) {
    if (_disposed) return;
    final accepted = AcceptedDeviceFix.tryAccept(position, _clock.now());
    if (accepted == null) return;
    final current = fix.value;
    // An out-of-order older sample never replaces a newer one.
    if (current != null && accepted.measuredAt.isBefore(current.measuredAt)) {
      return;
    }
    fix.value = accepted;
    _scheduleExpiry(accepted);
  }

  void _scheduleExpiry(AcceptedDeviceFix accepted) {
    _expiry?.cancel();
    final remaining = accepted.remainingAt(_clock.now());
    // Just past the bound, so the check inside sees it expired.
    _expiry = Timer(
      (remaining.isNegative ? Duration.zero : remaining) +
          const Duration(milliseconds: 1),
      revalidate,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _expiry?.cancel();
    await stop();
    fix.dispose();
  }
}
