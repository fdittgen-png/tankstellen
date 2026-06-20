// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// #3386 — single-authority gate for OBD2 reconnect.
///
/// Two reconnect authorities existed for the one adapter:
///  * the in-trip [DroppedSessionManager] (#2188) — the reconnect owner WHILE a
///    recording is active;
///  * the app-wide, trip-INDEPENDENT [Obd2Reconnect] (#3019) — documented as
///    the owner for a drop "while idle / between trips".
///
/// But #3019 subscribed to the link-drop signal UNCONDITIONALLY, so during a
/// recording BOTH reconnected the single adapter. Establishing a second RFCOMM
/// socket tears down the first (one SPP channel), the first sees a socket-close
/// drop and reconnects, tearing down the second — a perpetual reconnect WAR
/// that never let the link settle, leaving the trip stuck on GPS-estimated
/// consumption (field: "Enregistrement via GPS — reconnexion OBD2" all drive).
///
/// This latch lets the OBD2 recording pipeline CLAIM the adapter so #3019
/// stands down (and stops any in-flight loop) for the trip's lifetime; the
/// trip's own [DroppedSessionManager] is then the sole in-trip authority, as
/// the design always intended. Releasing it hands the idle/between-trips role
/// back to #3019.
///
/// A process-wide singleton (not a Riverpod provider) so the data-layer
/// reconnect controller and the recording pipeline coordinate WITHOUT a
/// cross-feature provider dependency; the [recordingOwnsLink] notifier lets
/// #3019 react the instant a recording claims the link.
class Obd2RecordingLinkOwnership {
  Obd2RecordingLinkOwnership._();

  /// Process-wide instance.
  static final Obd2RecordingLinkOwnership instance =
      Obd2RecordingLinkOwnership._();

  /// True while a trip recording owns the adapter. Notifies on every change.
  final ValueNotifier<bool> recordingOwnsLink = ValueNotifier<bool>(false);

  /// Whether a recording currently owns the adapter (the in-trip
  /// [DroppedSessionManager] is the reconnect authority).
  bool get active => recordingOwnsLink.value;

  /// A recording now owns the adapter — #3019 stands down.
  void claim() => recordingOwnsLink.value = true;

  /// The recording released the adapter — #3019 resumes the idle role.
  void release() => recordingOwnsLink.value = false;

  /// Reset to the unowned state (tests).
  @visibleForTesting
  void resetForTest() => recordingOwnsLink.value = false;
}
