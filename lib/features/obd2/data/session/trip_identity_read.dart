// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3858 — the once-per-session guard on the trip's identity reads
/// (odometer / VIN / ECU fuel type), owned by [TripRecordingController]
/// rather than shared across its parts (#4034, epic #4032).
///
/// The reads happen once the bus can answer: at trip start on a live
/// bus, or at the engine transition of a recording that began with the
/// engine off. Two of the controller's parts used to read and write the
/// bare flag; both go through [claim] now, so "have we read the identity
/// yet" has exactly one owner.
class TripIdentityRead {
  bool _done = false;

  /// Whether the identity reads have already run this session.
  bool get done => _done;

  /// Claim the single run. Returns true exactly once — the caller does
  /// the reads only when it gets that true.
  bool claim() {
    if (_done) return false;
    _done = true;
    return true;
  }
}
