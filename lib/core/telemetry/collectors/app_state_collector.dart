// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/storage_providers.dart';
import '../../../features/feature_management/application/feature_flags_provider.dart';
import '../models/error_trace.dart';

class AppStateCollector {
  static String? _currentRoute;
  static String? _lastApiEndpoint;
  static String? _lastSearchParams;

  static void updateRoute(String route) => _currentRoute = route;
  static void updateLastApi(String endpoint) => _lastApiEndpoint = endpoint;
  static void updateLastSearch(String params) => _lastSearchParams = params;

  static AppStateSnapshot collect(Ref ref) {
    final storage = ref.read(storageRepositoryProvider);
    final profileId = storage.getActiveProfileId();
    final profile = profileId != null ? storage.getProfile(profileId) : null;

    return AppStateSnapshot(
      activeRoute: _currentRoute,
      activeProfileId: profileId,
      activeProfileName: profile?['name'] as String?,
      lastApiEndpoint: _lastApiEndpoint,
      lastSearchParams: _lastSearchParams,
      enabledFeatures: _enabledFeatures(ref),
    );
  }

  /// #3150 — the enabled feature-flag names at error time (sorted for a
  /// stable rendering). Defensive: the collector runs inside the error
  /// path, so a provider-graph fault here must degrade to an empty list
  /// rather than losing the whole trace.
  static List<String> _enabledFeatures(Ref ref) {
    try {
      return ref.read(enabledFeaturesProvider).map((f) => f.name).toList()
        ..sort();
    } catch (_) {
      return const [];
    }
  }
}
