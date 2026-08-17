// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../hive_boxes.dart';
import '../storage_keys.dart';

/// Hive-backed implementation of [SettingsStorage] and [ApiKeyStorage].
///
/// Manages app settings (plain Hive) and API keys (FlutterSecureStorage
/// with in-memory cache for synchronous reads).
class SettingsHiveStore implements SettingsStorage, ApiKeyStorage {
  Box<dynamic> get _settings => Hive.box(HiveBoxes.settings);

  // API Key — stored in platform secure enclave, NOT in plain Hive.
  static const _secureStorage = FlutterSecureStorage();

  // #3746 — per-country in-memory cache (synchronous reads on the search
  // hot path), keyed by lowercase ISO country code. Backed by one secure-
  // storage entry per country under `api_key_<lowercase-cc>`.
  static final Map<String, String> _apiKeyCache = {};

  // The pre-#3746 single 'api_key' slot, cached at load time so the lazy
  // DE migration in [getApiKey] stays synchronous.
  static String? _legacyApiKeyCache;

  // Key für den Zugriff auf die freie Tankerkönig-Spritpreis-API
  // Für eigenen Key bitte hier https://onboarding.tankerkoenig.de
  // registrieren.
  //
  // The Tankerkönig terms of service (#713) forbid publishing any API key
  // — including demo / community keys — in public source repositories.
  // The app therefore ships with NO bundled key: the user must register
  // at creativecommons.tankerkoenig.de and paste their personal key into
  // Settings → API keys. Until then, Germany falls back to
  // [DemoStationService] (see `buildRawCountryService`).

  /// The secure-storage entry name for [countryCode]'s API key.
  static String _slotFor(String countryCode) =>
      '${StorageKeys.apiKey}_${countryCode.toLowerCase()}';

  /// Load all per-country API keys from secure storage into memory. Call
  /// once at startup. Also caches the pre-#3746 legacy single slot so the
  /// one-time DE migration in [getApiKey] can run synchronously.
  static Future<void> loadApiKey() async {
    final all = await _secureStorage.readAll();
    const prefix = '${StorageKeys.apiKey}_';
    _apiKeyCache.clear();
    for (final entry in all.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final value = entry.value;
      if (value.isEmpty) continue;
      _apiKeyCache[entry.key.substring(prefix.length)] = value;
    }
    _legacyApiKeyCache = all[StorageKeys.apiKey];
    await loadEvApiKey();
    await loadSupabaseAnonKey();
  }

  @override
  String? getApiKey(String countryCode) {
    final cc = countryCode.toLowerCase();
    var key = _apiKeyCache[cc];
    if (key == null && cc == 'de') {
      // #3746 one-time lazy migration: the pre-#3746 single 'api_key' slot
      // was documented (and validated) as the Tankerkönig key, so its value
      // becomes the DE slot on first read after the upgrade. The legacy
      // slot itself is deliberately LEFT IN PLACE for one release so a
      // downgrade to a pre-#3746 build still finds its key; remove it (and
      // this branch) in the release after #3746 ships.
      final legacy = _legacyApiKeyCache;
      if (legacy != null && legacy.isNotEmpty) {
        _apiKeyCache[cc] = legacy;
        key = legacy;
        unawaited(_secureStorage.write(key: _slotFor('de'), value: legacy));
      }
    }
    return (key != null && key.isNotEmpty) ? key : null;
  }

  @override
  Future<void> setApiKey(String countryCode, String key) async {
    final cc = countryCode.toLowerCase();
    await _secureStorage.write(key: _slotFor(cc), value: key);
    _apiKeyCache[cc] = key;
  }

  @override
  Future<void> deleteApiKey(String countryCode) async {
    final cc = countryCode.toLowerCase();
    await _secureStorage.delete(key: _slotFor(cc));
    _apiKeyCache.remove(cc);
    if (cc == 'de') {
      // Deleting the DE key must also clear the legacy slot — otherwise
      // the lazy migration above would resurrect the just-deleted key on
      // the next read.
      await _secureStorage.delete(key: StorageKeys.apiKey);
      _legacyApiKeyCache = null;
    }
  }

  @override
  Future<void> deleteAllApiKeys() async {
    for (final cc in _apiKeyCache.keys.toList()) {
      await _secureStorage.delete(key: _slotFor(cc));
    }
    _apiKeyCache.clear();
    await _secureStorage.delete(key: StorageKeys.apiKey);
    _legacyApiKeyCache = null;
  }

  @override
  bool hasApiKey(String countryCode) => getApiKey(countryCode) != null;

  @override
  bool hasCustomApiKey(String countryCode) => hasApiKey(countryCode);

  // EV Charging API key (OpenChargeMap)
  static String? _evApiKeyCache;

  static Future<void> loadEvApiKey() async {
    _evApiKeyCache = await _secureStorage.read(key: StorageKeys.evApiKey);
  }

  /// Default Open Charge Map API key shipped with the app.
  /// Users can override this with their own key in Settings.
  static const defaultEvApiKey = '9612e839-2a49-44b8-a2f6-08f5d197c36a';

  @override
  String? getEvApiKey() => _evApiKeyCache ?? defaultEvApiKey;

  @override
  bool hasEvApiKey() => true; // Always true — default key is always available

  @override
  bool hasCustomEvApiKey() =>
      _evApiKeyCache != null && _evApiKeyCache!.isNotEmpty;

  @override
  Future<void> setEvApiKey(String key) async {
    await _secureStorage.write(key: StorageKeys.evApiKey, value: key);
    _evApiKeyCache = key;
  }

  // Supabase anon key — secure storage with in-memory cache.
  static String? _supabaseAnonKeyCache;

  /// Load the Supabase anon key into memory and migrate any legacy plain-Hive
  /// value that pre-dates secure storage (issue #389).
  static Future<void> loadSupabaseAnonKey() async {
    _supabaseAnonKeyCache =
        await _secureStorage.read(key: StorageKeys.supabaseAnonKey);
    if (_supabaseAnonKeyCache != null) return;

    // One-time migration from plain Hive settings.
    final box = Hive.box<dynamic>(HiveBoxes.settings);
    final legacy = box.get(StorageKeys.supabaseAnonKey) as String?;
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(
          key: StorageKeys.supabaseAnonKey, value: legacy);
      _supabaseAnonKeyCache = legacy;
      await box.delete(StorageKeys.supabaseAnonKey);
    }
  }

  @override
  String? getSupabaseAnonKey() => _supabaseAnonKeyCache;

  @override
  Future<void> setSupabaseAnonKey(String key) async {
    await _secureStorage.write(
        key: StorageKeys.supabaseAnonKey, value: key);
    _supabaseAnonKeyCache = key;
  }

  @override
  Future<void> deleteSupabaseAnonKey() async {
    await _secureStorage.delete(key: StorageKeys.supabaseAnonKey);
    _supabaseAnonKeyCache = null;
  }

  // Generic settings access
  @override
  dynamic getSetting(String key) => _settings.get(key);

  @override
  Future<void> putSetting(String key, dynamic value) =>
      _guardedWrite('putSetting', () => _settings.put(key, value));

  /// Run [write] against the settings box, swallowing the benign teardown
  /// race where the box is (or becomes) closed.
  ///
  /// #3370 — a settings write racing app teardown (the box already closed —
  /// e.g. a fire-and-forget `markKnownGood` during an OBD2 disconnect at
  /// shutdown) must NOT throw an uncaught `FileSystemException: File closed`
  /// to PlatformDispatcher.onError. The value is simply dropped — the app is
  /// going away. This is the root of the recurring "File closed, settings.hive"
  /// field reports.
  ///
  /// #3377 — the [Hive.isBoxOpen] guard alone is a point-in-time check: the
  /// box can still close DURING the awaited file write (a background-scan
  /// `HiveBoxes.closeIsolateBoxes` interleaving the async append), so we also
  /// catch the `FileSystemException` the write itself can throw — the same
  /// belt-and-braces degrade `CacheManager.put` uses (#2670).
  Future<void> _guardedWrite(
    String label,
    Future<void> Function() write,
  ) async {
    if (!Hive.isBoxOpen(HiveBoxes.settings)) return;
    try {
      await write();
      // Benign teardown race — the box closed mid-write and the app is going
      // away, so the stack is useless; we only drop the value.
      // ignore: catch_no_st
    } on FileSystemException catch (e) {
      debugPrint(
          'SettingsHiveStore.$label: settings box closed mid-write, '
          'dropping ($e)');
    }
  }

  // Setup completion — tracks whether the onboarding wizard has been completed
  // or explicitly skipped. Must NOT depend on hasApiKey() because the bundled
  // community key (#521) makes hasApiKey() always true, which permanently
  // bypassed the wizard on fresh install (#555).
  @override
  bool get isSetupComplete =>
      _settings.get(StorageKeys.setupSkipped) == true;

  @override
  bool get isSetupSkipped => _settings.get(StorageKeys.setupSkipped) == true;

  @override
  Future<void> skipSetup() => _guardedWrite(
      'skipSetup', () => _settings.put(StorageKeys.setupSkipped, true));

  @override
  Future<void> resetSetupSkip() => _guardedWrite(
      'resetSetupSkip', () => _settings.delete(StorageKeys.setupSkipped));
}
