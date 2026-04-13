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
  Box get _settings => Hive.box(HiveBoxes.settings);

  // API Key — stored in platform secure enclave, NOT in plain Hive.
  static const _secureStorage = FlutterSecureStorage();

  // In-memory cache to avoid async reads on every API call.
  static String? _apiKeyCache;

  /// Load API key from secure storage into memory. Call once at startup.
  static Future<void> loadApiKey() async {
    _apiKeyCache = await _secureStorage.read(key: StorageKeys.apiKey);
    await loadEvApiKey();
    await loadSupabaseAnonKey();
  }

  @override
  String? getApiKey() => _apiKeyCache;

  @override
  Future<void> setApiKey(String key) async {
    await _secureStorage.write(key: StorageKeys.apiKey, value: key);
    _apiKeyCache = key;
  }

  @override
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: StorageKeys.apiKey);
    _apiKeyCache = null;
  }

  @override
  bool hasApiKey() {
    final key = getApiKey();
    return key != null && key.isNotEmpty;
  }

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
    final box = Hive.box(HiveBoxes.settings);
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
      _settings.put(key, value);

  // Setup skip (demo mode)
  @override
  bool get isSetupComplete =>
      hasApiKey() || (_settings.get(StorageKeys.setupSkipped) == true);

  @override
  bool get isSetupSkipped => _settings.get(StorageKeys.setupSkipped) == true;

  @override
  Future<void> skipSetup() =>
      _settings.put(StorageKeys.setupSkipped, true);

  @override
  Future<void> resetSetupSkip() =>
      _settings.delete(StorageKeys.setupSkipped);
}
