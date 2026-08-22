// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Persisted per-user (and optionally per-vehicle) preferences that
/// shape how a trip recording behaves the moment it starts (#2274
/// concern 1).
///
/// Every field defaults to the conservative, opt-in-each-drive
/// behaviour the app shipped before this profile existed:
///
///   * [autoPin] — when true, the recording screen pins itself the
///     instant it appears (wake lock + immersive system bars) instead
///     of waiting for the user to tap the push-pin. **Defaults to true**
///     (#2785): the dashboard-mount use case is the common one, so the
///     form is pinned every drive out of the box; the pin-help sheet's
///     toggle lets a user who minds the extra battery opt out once. A
///     stored explicit `false` (a deliberate opt-out) is always honoured
///     — only an absent value falls back to the `true` default.
///   * [autoEnterReducedOnStart] — Android-only hint that the recording
///     screen should make itself foreground+active on start so the
///     existing onUserLeaveHint auto-enter Picture-in-Picture fires
///     reliably when the user swaps to Maps (#2274 concern 4). No-op on
///     iOS (PiP there is video-only). Defaults to false.
///   * [keepScreenAwake] — keep the screen awake while recording even
///     when the form is NOT pinned (no immersive bars, just no dim).
///     Independent of [autoPin]; defaults to false.
///
/// The model is a plain immutable value object with JSON round-tripping
/// so it can live in the unencrypted `settings` Hive box alongside the
/// other small flag-shaped preferences. A null / absent payload
/// deserialises to [RecordingProfile.defaults], so a pre-#2274 install
/// reads cleanly with every field off.
@immutable
class RecordingProfile {
  final bool autoPin;
  final bool autoEnterReducedOnStart;
  final bool keepScreenAwake;

  const RecordingProfile({
    this.autoPin = true,
    this.autoEnterReducedOnStart = false,
    this.keepScreenAwake = false,
  });

  /// The default profile — auto-pin on (#2785), the rest off.
  static const RecordingProfile defaults = RecordingProfile();

  /// Whether this profile equals [defaults]. Used by the per-vehicle
  /// override store to avoid persisting a redundant override row (an
  /// absent override and a matches-the-default one are indistinguishable —
  /// both fall through to the global profile). Compared against [defaults]
  /// rather than hardcoding "all off" so that, now `autoPin` defaults on,
  /// a per-vehicle "auto-pin OFF" override is correctly treated as a real
  /// override and persisted (not silently cleared).
  bool get isDefault => this == defaults;

  /// Whether the recording screen should hold the screen awake on start
  /// — true when EITHER pinning (which already implies a wake lock) or
  /// the standalone keep-awake preference is set.
  bool get wantsScreenAwakeOnStart => autoPin || keepScreenAwake;

  RecordingProfile copyWith({
    bool? autoPin,
    bool? autoEnterReducedOnStart,
    bool? keepScreenAwake,
  }) =>
      RecordingProfile(
        autoPin: autoPin ?? this.autoPin,
        autoEnterReducedOnStart:
            autoEnterReducedOnStart ?? this.autoEnterReducedOnStart,
        keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      );

  Map<String, dynamic> toJson() => {
        'autoPin': autoPin,
        'autoEnterReducedOnStart': autoEnterReducedOnStart,
        'keepScreenAwake': keepScreenAwake,
      };

  /// Deserialise from a (possibly partial / legacy) JSON map. A missing
  /// field falls back to its default, so a forward-compatible superset
  /// reads cleanly. [autoPin] defaults to `true` when absent (#2785) but a
  /// stored explicit `false` is honoured — [toJson] always writes the key,
  /// so any profile the user has actually touched round-trips their choice;
  /// only a never-saved / partial payload takes the `true` default.
  factory RecordingProfile.fromJson(Map<String, dynamic> json) {
    bool readBool(String key, {bool defaultValue = false}) =>
        json.containsKey(key) ? json[key] == true : defaultValue;
    return RecordingProfile(
      autoPin: readBool('autoPin', defaultValue: true),
      autoEnterReducedOnStart: readBool('autoEnterReducedOnStart'),
      keepScreenAwake: readBool('keepScreenAwake'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecordingProfile &&
      other.autoPin == autoPin &&
      other.autoEnterReducedOnStart == autoEnterReducedOnStart &&
      other.keepScreenAwake == keepScreenAwake;

  @override
  int get hashCode =>
      Object.hash(autoPin, autoEnterReducedOnStart, keepScreenAwake);

  @override
  String toString() => 'RecordingProfile(autoPin: $autoPin, '
      'autoEnterReducedOnStart: $autoEnterReducedOnStart, '
      'keepScreenAwake: $keepScreenAwake)';
}
