// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/entities/recording_profile.dart';

part 'recording_profile_provider.g.dart';

/// App-wide owner of the persisted [RecordingProfile] (#2274 concern 1).
///
/// Holds the GLOBAL profile as its state and reads/writes per-vehicle
/// overrides on demand. Both live in the unencrypted `settings` Hive box
/// (the profile is a handful of bools, not PII) keyed by
/// [StorageKeys.recordingProfile] and
/// [StorageKeys.recordingProfileVehicleOverridePrefix]`<vehicleId>`.
///
/// `keepAlive: true` because the profile is read on every recording-screen
/// mount; rebuilding it on every listener churn would re-read Hive for
/// nothing. Every field defaults OFF, so a fresh install — and a
/// pre-#2274 install with no persisted payload — behaves exactly as the
/// app did before this provider existed (opt-in pinning each drive).
@Riverpod(keepAlive: true)
class RecordingProfileController extends _$RecordingProfileController {
  @override
  RecordingProfile build() => _readGlobal();

  RecordingProfile _readGlobal() {
    try {
      final raw = ref.read(settingsStorageProvider)
          .getSetting(StorageKeys.recordingProfile);
      return _decode(raw);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RecordingProfile: read global failed'}));
      return RecordingProfile.defaults;
    }
  }

  /// Persist the global [profile] and publish it as the new state.
  Future<void> setGlobal(RecordingProfile profile) async {
    state = profile;
    try {
      await ref.read(settingsStorageProvider).putSetting(
            StorageKeys.recordingProfile,
            jsonEncode(profile.toJson()),
          );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RecordingProfile: write global failed'}));
    }
  }

  /// Flip the global [RecordingProfile.autoPin] preference. The
  /// recording screen's pin-help sheet drives this so a user who wants
  /// the form pinned every drive can opt in once.
  Future<void> setAutoPin(bool value) =>
      setGlobal(state.copyWith(autoPin: value));

  /// Flip the global [RecordingProfile.keepScreenAwake] preference.
  Future<void> setKeepScreenAwake(bool value) =>
      setGlobal(state.copyWith(keepScreenAwake: value));

  /// Flip the global [RecordingProfile.autoEnterReducedOnStart]
  /// preference (Android-only effect; a no-op surface elsewhere).
  Future<void> setAutoEnterReducedOnStart(bool value) =>
      setGlobal(state.copyWith(autoEnterReducedOnStart: value));

  /// The per-vehicle override for [vehicleId], or null when none is
  /// stored. A null [vehicleId] always returns null (no per-vehicle
  /// scope to look up).
  RecordingProfile? overrideFor(String? vehicleId) {
    if (vehicleId == null || vehicleId.isEmpty) return null;
    try {
      final raw = ref.read(settingsStorageProvider).getSetting(
            '${StorageKeys.recordingProfileVehicleOverridePrefix}$vehicleId',
          );
      if (raw == null) return null;
      return _decode(raw);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'RecordingProfile: read vehicle override failed',
      }));
      return null;
    }
  }

  /// Persist (or clear) a per-vehicle override. An all-default
  /// [profile] clears the override row so it falls back to the global
  /// profile — an absent override and an all-default one are
  /// indistinguishable, so we never store the redundant row.
  Future<void> setOverride(String vehicleId, RecordingProfile? profile) async {
    if (vehicleId.isEmpty) return;
    final key =
        '${StorageKeys.recordingProfileVehicleOverridePrefix}$vehicleId';
    try {
      final storage = ref.read(settingsStorageProvider);
      if (profile == null || profile.isDefault) {
        await storage.putSetting(key, null);
      } else {
        await storage.putSetting(key, jsonEncode(profile.toJson()));
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'RecordingProfile: write vehicle override failed',
      }));
    }
  }

  /// The profile that actually applies for [vehicleId]: the per-vehicle
  /// override when one is stored, otherwise the global profile. Read by
  /// the recording screen on start to decide whether to auto-pin.
  RecordingProfile effectiveFor(String? vehicleId) =>
      overrideFor(vehicleId) ?? state;

  /// Decode a persisted payload. Accepts a JSON string (the format
  /// [setGlobal] writes) or an already-decoded `Map` (forward-compat /
  /// test fakes that store the map directly). Anything else — including
  /// a null absent key — decodes to the all-default profile.
  RecordingProfile _decode(dynamic raw) {
    if (raw is Map) {
      return RecordingProfile.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return RecordingProfile.fromJson(Map<String, dynamic>.from(decoded));
      }
    }
    return RecordingProfile.defaults;
  }
}
