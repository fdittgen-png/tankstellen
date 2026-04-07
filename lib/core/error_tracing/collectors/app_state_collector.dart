import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/storage_providers.dart';
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
    );
  }
}
