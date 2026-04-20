import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/services/ev_charging_service.dart';

part 'ev_charging_service_provider.g.dart';

/// Exposes an [EVChargingService] instance bound to the user's
/// OpenChargeMap API key (#728 part 2).
///
/// Previously each caller — `EVSearchState`, `RouteSearchProvider`,
/// `EVStationDetailScreen._refreshStation` — constructed its own
/// service inline, each time resolving the key from Hive and creating
/// a fresh Dio. That meant a hot UI path (build / setState) touched
/// secure storage and spun up a new HTTP client on every call, with
/// no request coalescing across the three call sites.
///
/// This provider:
/// * reads the EV API key from [apiKeyStorageProvider];
/// * returns `null` when no key is set (callers surface the
///   "configure your key" empty-state instead of throwing);
/// * uses `keepAlive` so the service survives screen rebuilds and
///   any cache / coalescing the service adds in the future applies
///   across the whole app.
@Riverpod(keepAlive: true)
EVChargingService? evChargingService(Ref ref) {
  final storage = ref.watch(apiKeyStorageProvider);
  final apiKey = storage.getEvApiKey();
  if (apiKey == null || apiKey.isEmpty) return null;
  return EVChargingService(apiKey: apiKey);
}
