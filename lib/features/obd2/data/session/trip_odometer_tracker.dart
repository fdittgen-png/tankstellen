// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The trip's odometer bookkeeping, owned by [TripRecordingController]
/// rather than spread across its `part` files (#4034, epic #4032).
///
/// Six fields used to sit in the controller's shared private scope and be
/// written from four of its parts — the start reading, the latest one,
/// when that landed, the trip distance at that instant, the last refresh
/// attempt and the in-flight guard. Four of them were written from more
/// than one file, so any part could invalidate the pairing between a
/// reading and the distance it was taken at. They are private here, and
/// the pairing is only ever set together, in [recordStart] and
/// [recordRefresh].
///
/// The recording UI does not poll the odometer every tick — it is an
/// expensive Mode 22 query on some cars — so there are exactly three
/// sources: once at trip start (#800), the #3877 periodic refresh while
/// the engine runs, and once just before stop so the save-as-fill-up flow
/// gets a ground-truth end km rather than a derived one.
class TripOdometerTracker {
  double? _startKm;
  double? _latestKm;
  DateTime? _latestAt;
  double? _distanceKmAtLatest;
  DateTime? _refreshAt;
  bool _refreshInFlight = false;

  /// Odometer reading at trip start. Null when the adapter can't read
  /// the odometer (no PID A6, no PID 31 fallback, unknown manufacturer).
  double? get startKm => _startKm;

  /// Latest odometer reading read during the trip. Null until the first
  /// successful poll.
  double? get latestKm => _latestKm;

  /// #3877 — instant of the latest successful reading.
  DateTime? get latestAt => _latestAt;

  /// #3877 — trip distance at the latest reading.
  double? get distanceKmAtLatest => _distanceKmAtLatest;

  /// Whether a periodic refresh is currently in flight.
  bool get refreshInFlight => _refreshInFlight;

  /// True once the car has answered at least once — the #3877 periodic
  /// refresh only runs on a car that answered at trip start, so an
  /// unsupported one never stalls the tick.
  bool get everAnswered => _latestKm != null;

  /// The reference instant the periodic refresh measures its interval
  /// from: the last refresh ATTEMPT if there was one, else the last
  /// successful reading.
  DateTime? get lastRefreshReference => _refreshAt ?? _latestAt;

  /// The trip-start reading (#800). [now] anchors the #3877 pairing at
  /// zero trip distance.
  void recordStart(double? km, DateTime now) {
    _startKm = km;
    _latestKm = km;
    if (km == null) return;
    _latestAt = now; // #3877
    _distanceKmAtLatest = 0;
  }

  /// Mark a refresh attempt as started at [now], so the interval is
  /// measured from the attempt rather than from the last success (a car
  /// that stopped answering must not be re-polled every tick).
  void beginRefresh(DateTime now) => _refreshAt = now;

  /// A refresh answered: remember the reading, WHEN it landed and at
  /// WHICH trip distance, so a stop after it can add the distance driven
  /// since (#3877). The three are set together or not at all.
  ///
  /// [distanceKmAfter] is a callback, not a value, and that is the whole
  /// point: the trip distance (#800) resolves to `latestKm - startKm`
  /// whenever both readings exist, so it must be read AFTER this reading
  /// has landed. Passing the number in would capture the pre-refresh
  /// distance and stamp a zero delta onto a car that has actually moved.
  void recordRefresh(
      double km, DateTime now, double Function() distanceKmAfter) {
    _latestKm = km;
    _latestAt = now;
    _distanceKmAtLatest = distanceKmAfter();
  }

  /// Guard for the #3877 periodic refresh: takes the in-flight slot and
  /// returns true when the caller got it.
  bool claimPeriodicRefresh() {
    if (_refreshInFlight) return false;
    _refreshInFlight = true;
    return true;
  }

  /// Release the in-flight slot when a periodic refresh completes.
  void endPeriodicRefresh() => _refreshInFlight = false;

  /// #3877 — the best current odometer: the latest reading plus the
  /// distance driven since it; null when the car never answered.
  double? estimatedNowKm(double currentDistanceKm) {
    final latest = _latestKm;
    if (latest == null) return null;
    final since = currentDistanceKm - (_distanceKmAtLatest ?? currentDistanceKm);
    return latest + (since > 0 ? since : 0);
  }

  /// Test seam (#800): force readings without an adapter that answers.
  void debugSet({double? startKm, double? latestKm}) {
    if (startKm != null) _startKm = startKm;
    if (latestKm != null) _latestKm = latestKm;
  }
}
