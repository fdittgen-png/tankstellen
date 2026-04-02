import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pre-configured credentials for the TankSync community database.
///
/// Credentials are loaded from (in priority order):
/// 1. `--dart-define` build-time overrides
/// 2. `assets/tanksync_config.json` (external config file)
///
/// The external config file allows updating credentials without code changes.
/// Run `supabase/create-project.sh` to generate a new config file.
///
/// ## Build-time override
/// ```bash
/// flutter build apk --dart-define=COMMUNITY_SUPABASE_URL=https://...
///                    --dart-define=COMMUNITY_SUPABASE_ANON_KEY=eyJ...
/// ```
class CommunityConfig {
  CommunityConfig._();

  /// Build-time override via `--dart-define`.
  static const _defineUrl = String.fromEnvironment('COMMUNITY_SUPABASE_URL');
  static const _defineKey = String.fromEnvironment('COMMUNITY_SUPABASE_ANON_KEY');

  /// Cached values loaded from the config file.
  static String? _cachedUrl;
  static String? _cachedKey;
  static bool _loaded = false;

  /// Load credentials from `assets/tanksync_config.json`.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final jsonStr = await rootBundle.loadString('assets/tanksync_config.json');
      final config = json.decode(jsonStr) as Map<String, dynamic>;
      _cachedUrl = config['supabase_url'] as String?;
      _cachedKey = config['supabase_anon_key'] as String?;
    } catch (e) {
      debugPrint('CommunityConfig: failed to load asset: $e');
    }
  }

  /// Supabase project URL for the community database.
  /// Priority: --dart-define > config file
  static String get supabaseUrl {
    if (_defineUrl.isNotEmpty) return _defineUrl;
    return _cachedUrl ?? '';
  }

  /// Supabase anonymous key for the community database.
  /// Priority: --dart-define > config file
  static String get supabaseAnonKey {
    if (_defineKey.isNotEmpty) return _defineKey;
    return _cachedKey ?? '';
  }

  /// Whether valid credentials are available.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Reset cached state. Only for testing.
  @visibleForTesting
  static void reset() {
    _loaded = false;
    _cachedUrl = null;
    _cachedKey = null;
  }
}
