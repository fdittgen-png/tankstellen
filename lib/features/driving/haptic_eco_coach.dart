import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/logging/error_logger.dart';
import '../consumption/data/obd2/trip_live_reading.dart';
import 'coach_event.dart';

/// Real-time eco-coaching haptic (#1122).
///
/// Pure wheel-lens feature: fires a gentle haptic when the driver is
/// "flooring it on the highway" — sustained high throttle without a
/// matching rise in speed. The classic case is the impatient stab
/// after a slow car pulls in: throttle pegged at 80 %, speed barely
/// moves because the gear is already maxed out, and the engine just
/// burns extra fuel for no acceleration. A short vibration there is
/// the cheapest correction available — no UI, no nag, just a "hey,
/// you're wasting fuel" tap on the wrist.
///
/// The heuristic is intentionally narrow:
///
///   * **Rolling 5 s window** — single-spike throttle stabs (overtake,
///     merge) are fine; this fires only on *sustained* high throttle.
///   * **Average throttle > 75 %** — keeps "firm pedal" cruising
///     (50–75 %) silent so the haptic stays meaningful.
///   * **Δspeed < 10 km/h over the window** — distinguishes wasteful
///     pedal-mashing from honest acceleration. A 0→100 km/h pull does
///     burn fuel but it's the only way to get there; we don't want to
///     buzz the driver during deliberate acceleration.
///   * **30 s cooldown** — without it the heuristic refires every tick
///     while the condition holds and we'd buzz once per second of
///     cruising. Cooldown turns it into a single, easy-to-ignore tap.
///
/// The coach takes a [Stream<TripLiveReading>] (from the trip-recording
/// provider) and a [haptic] callback (defaults to
/// [HapticFeedback.mediumImpact]; injected in tests so the heuristic can
/// be exercised without touching the platform channel). Calling [start]
/// returns a [StreamSubscription] the caller can cancel to tear down.
///
/// **Defaults OFF** — the wiring layer (`hapticEcoCoachEnabledProvider`)
/// gates this behind an explicit setting, so users who don't opt in
/// never see haptics from this code path.
class HapticEcoCoach {
  HapticEcoCoach({
    required this.readings,
    Future<void> Function()? haptic,
    this.onCoach,
    this.windowSize = const Duration(seconds: 5),
    this.throttleThresholdPercent = 75.0,
    this.maxSpeedDeltaKmh = 10.0,
    this.cooldown = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : haptic = haptic ?? HapticFeedback.mediumImpact,
        _clock = clock ?? DateTime.now;

  /// Live readings stream. Each reading represents one OBD2 tick — at
  /// the default 5 Hz polling cadence we get ~25 samples per 5 s
  /// window, which is plenty to average throttle without false fires
  /// from a single-tick spike.
  final Stream<TripLiveReading> readings;

  /// Triggered every time the heuristic decides to nudge the driver.
  /// Defaults to [HapticFeedback.mediumImpact]. Tests inject a captor
  /// so they can count fires deterministically.
  final Future<void> Function() haptic;

  /// Optional visual / analytics hook — invoked synchronously alongside
  /// [haptic] on the same fire decision so a UI surface (#1273 visual
  /// SnackBar) can subscribe via the lifecycle provider's broadcast
  /// stream WITHOUT duplicating the cooldown logic. Receives a
  /// [CoachEvent] describing the fire context (timestamp + averaged
  /// throttle + speed delta from the window).
  ///
  /// Errors raised by the callback are caught and surfaced via
  /// [debugPrint] (the unified [errorLogger] cannot be reached from
  /// this callback site without breaking the unit-test harness — see
  /// `_fireCoachCallback`). The live-readings subscription keeps
  /// flowing in all cases; the haptic that fires before this hook
  /// is independent of failures here. Null in tests that only care
  /// about the haptic path.
  final void Function(CoachEvent event)? onCoach;

  /// Rolling-window length the heuristic averages over. Bigger windows
  /// smooth out short stabs but lag the user's actual behaviour;
  /// smaller windows would fire on every single overtake. 5 s is the
  /// sweet spot in the issue and matches how the post-trip
  /// driving-insights analyzer treats "sustained" throttle events.
  final Duration windowSize;

  /// Average-throttle floor for a fire decision. Set high enough that
  /// firm-pedal cruising (50–75 %) doesn't trigger — we only want
  /// genuinely wasteful pedal-mashing to fire. The default mirrors
  /// the absolute throttle quartile in `throttle_rpm_histogram_calculator.dart`.
  final double throttleThresholdPercent;

  /// Maximum speed change across the window for the "cruising, not
  /// accelerating" decision. 10 km/h captures normal cruise wobble
  /// (highway speed ±5 km/h is typical) without letting hard
  /// acceleration through.
  final double maxSpeedDeltaKmh;

  /// Minimum time between two haptic fires. Prevents the heuristic
  /// from buzzing every tick while the condition holds — once the
  /// driver has been nudged, give them at least 30 s to react before
  /// nudging again.
  final Duration cooldown;

  /// Clock seam — tests inject a deterministic clock so the cooldown
  /// can be verified without `Future.delayed`.
  final DateTime Function() _clock;

  /// Sliding window of recent readings. Bounded by [windowSize] — older
  /// entries are dropped on every tick. We keep the full reading
  /// (timestamp + throttle + speed) rather than a derived metric so
  /// the speed-delta computation can grab the boundary values directly.
  final List<_WindowEntry> _window = <_WindowEntry>[];

  /// Last fire timestamp. Null until the first fire. The cooldown is
  /// enforced against this value rather than wall-clock-now so a paused
  /// recording (no readings → no `_lastFireAt` updates) can resume
  /// without artificially extending the cooldown.
  DateTime? _lastFireAt;

  /// Subscribe to [readings] and start firing haptics when the
  /// heuristic matches. Returns the underlying subscription so the
  /// caller (typically the provider) can cancel it on teardown.
  ///
  /// **Errors in [haptic] are swallowed and logged via [errorLogger]**
  /// — a vibration channel hiccup must not kill the live-readings
  /// subscription. The driver still sees their trip recording.
  StreamSubscription<TripLiveReading> start() {
    return readings.listen(_onReading);
  }

  /// Apply [reading] to the rolling window and decide whether to fire.
  /// Visible for tests so the heuristic can be exercised without a
  /// real `Stream` — `coach.debugFeed(reading)` is equivalent to one
  /// arrival on the live stream.
  @visibleForTesting
  void debugFeed(TripLiveReading reading) => _onReading(reading);

  void _onReading(TripLiveReading reading) {
    final now = _clock();
    _appendAndPrune(reading, now);
    if (!_windowIsFull(now)) return;
    if (_inCooldown(now)) return;
    final match = _heuristicMatch();
    if (match == null) return;
    _lastFireAt = now;
    _fireHaptic();
    _fireCoachCallback(now, match);
  }

  /// Push the new reading into the buffer and drop anything older than
  /// [windowSize]. Stores the throttle / speed from the reading
  /// (nullable — the heuristic skips entries with null throttle in
  /// the average calculation, see [_heuristicMatches]).
  void _appendAndPrune(TripLiveReading reading, DateTime now) {
    _window.add(_WindowEntry(
      timestamp: now,
      throttlePercent: reading.throttlePercent,
      speedKmh: reading.speedKmh,
    ));
    final cutoff = now.subtract(windowSize);
    while (_window.isNotEmpty && _window.first.timestamp.isBefore(cutoff)) {
      _window.removeAt(0);
    }
  }

  /// True once the buffer spans the full [windowSize]. Without this
  /// the very first sample on a fresh trip would already pass an
  /// empty-window heuristic check.
  bool _windowIsFull(DateTime now) {
    if (_window.length < 2) return false;
    final span = now.difference(_window.first.timestamp);
    // Allow a small lower bound — at 5 Hz polling we'll have 24-25
    // samples in a 5 s window, but the very first tick that closes
    // the window may land 4.8 s after the first sample. Demand at
    // least 80 % of the configured window so the heuristic doesn't
    // race the very first edge.
    return span >= windowSize * 0.8;
  }

  bool _inCooldown(DateTime now) {
    final last = _lastFireAt;
    if (last == null) return false;
    return now.difference(last) < cooldown;
  }

  /// The actual heuristic — applied only after the buffer is full and
  /// we're past cooldown. Returns a [_HeuristicMatch] (carrying the
  /// averaged throttle + speed delta the fire decision was based on)
  /// when both checks pass; null otherwise. The diagnostic numbers
  /// flow into [CoachEvent] for the visual surface (#1273) without
  /// requiring a second pass over the window.
  ///
  /// Match conditions:
  ///   * The mean throttle across all non-null entries in the window
  ///     is greater than [throttleThresholdPercent].
  ///   * The speed change between the first and last non-null speed
  ///     in the window is less than [maxSpeedDeltaKmh] (in absolute
  ///     value — both sustained-flat and slight-deceleration cases
  ///     count as "not accelerating").
  ///
  /// Both checks must pass. Either failing → null (no fire).
  _HeuristicMatch? _heuristicMatch() {
    final throttleSamples = _window
        .map((e) => e.throttlePercent)
        .whereType<double>()
        .toList(growable: false);
    if (throttleSamples.isEmpty) return null;
    final avgThrottle =
        throttleSamples.reduce((a, b) => a + b) / throttleSamples.length;
    if (avgThrottle <= throttleThresholdPercent) return null;

    final speedSamples = _window
        .map((e) => e.speedKmh)
        .whereType<double>()
        .toList(growable: false);
    if (speedSamples.length < 2) return null;
    final delta = (speedSamples.last - speedSamples.first).abs();
    if (delta >= maxSpeedDeltaKmh) return null;

    return _HeuristicMatch(
      avgThrottlePercent: avgThrottle,
      speedDeltaKmh: delta,
    );
  }

  /// Fire the platform haptic. Errors are routed through [errorLogger]
  /// so a vibration-channel hiccup doesn't kill the trip subscription;
  /// the live-reading stream MUST keep flowing for the rest of the app.
  void _fireHaptic() {
    // ignore: discarded_futures — fire-and-forget by design; we don't
    // want to block the next reading on the platform channel reply.
    haptic().catchError((Object e, StackTrace st) {
      errorLogger.log(
        ErrorLayer.ui,
        e,
        st,
        context: <String, Object?>{
          'where': 'HapticEcoCoach.fire',
        },
      );
    });
  }

  /// Invoke [onCoach] with a fresh [CoachEvent] for the visual surface
  /// (#1273). Errors are caught and surfaced via [debugPrint] with
  /// surrounding context so they remain debuggable, while the trip's
  /// live-readings stream — and the haptic that already fired before
  /// us — keep going. The trip recording MUST keep flowing even when
  /// a UI subscriber throws (e.g. accessing a disposed BuildContext
  /// from a SnackBar handler). No-op when [onCoach] is null.
  void _fireCoachCallback(DateTime now, _HeuristicMatch match) {
    final cb = onCoach;
    if (cb == null) return;
    final event = CoachEvent(
      firedAt: now,
      avgThrottlePercent: match.avgThrottlePercent,
      speedDeltaKmh: match.speedDeltaKmh,
    );
    try {
      cb(event);
    } catch (subscriberError, subscriberStack) {
      // ignore: avoid_print — debugPrint with full context, NOT a
      // raw exception variable. The lint scanner allows this form
      // (#1104) because the surrounding string is informative on
      // its own.
      debugPrint(
        'HapticEcoCoach.onCoach threw — visual surface skipped '
        'this fire (haptic still vibrated): $subscriberError\n'
        '$subscriberStack',
      );
    }
  }
}

/// Bundled fire-decision payload returned by [HapticEcoCoach._heuristicMatch].
/// Pure data — flows into [CoachEvent] for the visual subscriber.
@immutable
class _HeuristicMatch {
  const _HeuristicMatch({
    required this.avgThrottlePercent,
    required this.speedDeltaKmh,
  });

  final double avgThrottlePercent;
  final double speedDeltaKmh;
}

/// One entry in the rolling window. Internal helper — pure data.
@immutable
class _WindowEntry {
  const _WindowEntry({
    required this.timestamp,
    required this.throttlePercent,
    required this.speedKmh,
  });

  final DateTime timestamp;
  final double? throttlePercent;
  final double? speedKmh;
}
