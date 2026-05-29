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
///     of waiting for the user to tap the push-pin. **Defaults to
///     false**: pinning costs battery, and the deliberate design of
///     #891 was that the user opts in *each* drive. A user who wants
///     the pin every time flips this once.
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
    this.autoPin = false,
    this.autoEnterReducedOnStart = false,
    this.keepScreenAwake = false,
  });

  /// The conservative all-off default — preserves the opt-in-each-drive
  /// behaviour the app shipped with before #2274.
  static const RecordingProfile defaults = RecordingProfile();

  /// Whether any field is set. Used by the per-vehicle override store to
  /// avoid persisting an all-default override row (an absent override is
  /// indistinguishable from an all-default one — both fall through to
  /// the global profile).
  bool get isDefault =>
      !autoPin && !autoEnterReducedOnStart && !keepScreenAwake;

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

  /// Deserialise from a (possibly partial / legacy) JSON map. Any
  /// missing or non-bool field falls back to its conservative default,
  /// so a pre-#2274 payload or a forward-compatible superset both read
  /// cleanly.
  factory RecordingProfile.fromJson(Map<String, dynamic> json) {
    bool readBool(String key) => json[key] == true;
    return RecordingProfile(
      autoPin: readBool('autoPin'),
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
