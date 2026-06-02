// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/error_logger.dart';

part 'voice_coaching_enabled_provider.g.dart';

/// Persisted user toggle for spoken driving coaching (#2663).
///
/// Backs a single device-local boolean onto `SharedPreferences`,
/// mirroring [GlideCoachSettingsNotifier] / [VoiceAnnouncementSettings].
/// Two deliberate departures from the voice-announcement settings:
///
///   1. **Default ON.** The issue asks coaching to speak by default
///      ("default on if no setting"); the bug was that it was silently
///      never wired, not that users opted out. The visible toggle (in
///      the coaching settings section) lets anyone mute it.
///   2. **Decoupled — no `Feature` gate.** Spoken coaching must work in
///      both OBD2 and GPS-only trips and has nothing to do with the
///      station-proximity approach overlay that gates
///      `Feature.voiceAnnouncements`. Wiring it behind that flag would
///      reproduce exactly the coupling the root-cause analysis flags.
///      Avoiding a `Feature` enum value also sidesteps the manifest +
///      feature-management-switch + count-test cascade.
///
/// The [DrivingCoachVoiceListener] reads this on every `build`; when it
/// resolves `false` the listener returns early and never subscribes — so
/// silence is guaranteed when disabled.
@Riverpod(keepAlive: true)
class VoiceCoachingEnabled extends _$VoiceCoachingEnabled {
  /// Versioned key (`v1`) so a future schema change can introduce a v2
  /// without colliding with stale values.
  static const String prefsKey = 'settings.voiceCoaching.enabled.v1';

  @override
  bool build() {
    _load();
    // Pre-load frame: default ON. `_load` only overrides it if the user
    // has explicitly persisted a value (i.e. opted out).
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(prefsKey);
      // No stored value → keep the default-ON build() result. Only a
      // persisted explicit choice changes the resolved state.
      if (stored != null && stored != state) state = stored;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'op': 'VoiceCoachingEnabled._load',
      }));
    }
  }

  /// Flip the user-facing toggle and write through to SharedPreferences.
  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'op': 'VoiceCoachingEnabled.setEnabled',
      }));
    }
  }
}
