// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/services/announcement_engine.dart';
import '../../profile/providers/voice_announcements_enabled_provider.dart';

part 'voice_announcement_settings_provider.g.dart';

/// Persisted user settings for voice announcements while driving (#2569).
///
/// Backs the four tunables the dormant [AnnouncementEngine] already reads
/// — enable, price threshold, proximity radius, repeat cooldown — onto
/// `SharedPreferences`. The shape mirrors `GlideCoachSettingsNotifier`
/// (#1125 phase 3b): a device-local preference (not profile-bound), read
/// on startup, write-through on every setter. The value type IS the
/// engine's own [AnnouncementConfig] so the live call site
/// (`voiceAnnouncementListenerProvider`) can hand it to the engine
/// without an adapter layer.
///
/// ### Layered gate (master flag + user toggle)
///
/// Two independent off-switches must both be true before a word is
/// spoken:
///
///   1. The central [Feature.voiceAnnouncements] flag, read via
///      [voiceAnnouncementsEnabledProvider] (default-off; requires the
///      approach overlay). When the flag is off, the resolved config's
///      `enabled` is forced `false` even if the persisted toggle is
///      `true` — exactly the glide-coach contract.
///   2. The user-facing `enabled` toggle persisted here.
///
/// `setEnabled(true)` still WRITES `true` so a later flag flip restores
/// the user's historical opt-in, but the in-memory `enabled` stays gated.
@Riverpod(keepAlive: true)
class VoiceAnnouncementSettings extends _$VoiceAnnouncementSettings {
  /// Versioned keys (`v1`) so a future schema change can introduce a v2
  /// without colliding with stale values.
  @visibleForTesting
  static const String enabledKey = 'settings.voiceAnnouncements.enabled.v1';
  @visibleForTesting
  static const String thresholdKey =
      'settings.voiceAnnouncements.thresholdEur.v1';
  @visibleForTesting
  static const String radiusKey =
      'settings.voiceAnnouncements.radiusKm.v1';
  @visibleForTesting
  static const String cooldownKey =
      'settings.voiceAnnouncements.cooldownMinutes.v1';

  /// Default repeat interval — matches [AnnouncementConfig]'s own default.
  static const Duration _defaultCooldown = Duration(minutes: 30);

  @override
  AnnouncementConfig build() {
    _load();
    // Pre-load frame: the engine's own defaults, but gated off until the
    // feature flag + persisted toggle resolve.
    return const AnnouncementConfig();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(enabledKey) ?? false;
      final effective =
          ref.read(voiceAnnouncementsEnabledProvider) ? stored : false;
      final threshold = prefs.getDouble(thresholdKey);
      final radius = prefs.getDouble(radiusKey) ??
          const AnnouncementConfig().proximityRadiusKm;
      final cooldownMin = prefs.getInt(cooldownKey);
      final next = AnnouncementConfig(
        enabled: effective,
        proximityRadiusKm: radius,
        cooldown: cooldownMin != null
            ? Duration(minutes: cooldownMin)
            : _defaultCooldown,
        priceThreshold: threshold,
      );
      if (next != state) state = next;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'op': 'VoiceAnnouncementSettings._load',
      }));
    }
  }

  /// Flip the user-facing enable toggle. Writes the requested value
  /// unconditionally (preserving the opt-in across flag flips) but the
  /// in-memory `enabled` is gated by [voiceAnnouncementsEnabledProvider].
  Future<void> setEnabled(bool value) async {
    final effective =
        ref.read(voiceAnnouncementsEnabledProvider) ? value : false;
    state = state.copyWith(enabled: effective);
    await _writeBool(enabledKey, value);
  }

  /// Set the cheap-fuel price threshold in the active currency's major
  /// unit (e.g. EUR/litre). `null` clears the threshold (announce every
  /// in-radius station).
  Future<void> setPriceThreshold(double? value) async {
    state = AnnouncementConfig(
      enabled: state.enabled,
      proximityRadiusKm: state.proximityRadiusKm,
      cooldown: state.cooldown,
      priceThreshold: value,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(thresholdKey);
      } else {
        await prefs.setDouble(thresholdKey, value);
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'op': 'VoiceAnnouncementSettings.setPriceThreshold',
      }));
    }
  }

  /// Set the announcement proximity radius in kilometres.
  Future<void> setProximityRadiusKm(double value) async {
    state = state.copyWith(proximityRadiusKm: value);
    await _writeDouble(radiusKey, value);
  }

  /// Set the per-station repeat cooldown.
  Future<void> setCooldown(Duration value) async {
    state = state.copyWith(cooldown: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(cooldownKey, value.inMinutes);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'op': 'VoiceAnnouncementSettings.setCooldown',
      }));
    }
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'op': 'VoiceAnnouncementSettings.write',
        'key': key,
      }));
    }
  }

  Future<void> _writeDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'op': 'VoiceAnnouncementSettings.write',
        'key': key,
      }));
    }
  }
}
