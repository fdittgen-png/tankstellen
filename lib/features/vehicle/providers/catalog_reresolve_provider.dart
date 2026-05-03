import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/catalog_reresolve_detector.dart';
import '../data/reference_vehicle_catalog_provider.dart';
import 'vehicle_providers.dart';

part 'catalog_reresolve_provider.g.dart';

/// Async provider returning the diesel-mismatch nudge candidates for
/// the current launch (#1396).
///
/// Reads:
///   - the bundled reference catalog,
///   - every stored [VehicleProfile] (so a user with several diesels
///     gets one snackbar per car), and
///   - the per-vehicle Hive flag that records "we already showed the
///     nudge to this vehicle".
///
/// Returns the list filtered by the [CatalogReresolveDetector]. The
/// snackbar host watches this provider; when the list is empty it
/// renders nothing, otherwise it surfaces one snackbar per candidate.
///
/// `keepAlive: true` because the catalog is also kept-alive and the
/// list of nudges is short-lived (drained as the host fires
/// snackbars). Re-reading the provider after the user re-picks their
/// catalog row in the vehicle editor is cheap — invalidation is the
/// easiest way to pick up a freshly re-saved profile.
@Riverpod(keepAlive: true)
Future<List<CatalogReresolveCandidate>> catalogReresolveCandidates(
  Ref ref,
) async {
  final settings = ref.watch(settingsStorageProvider);
  final profiles = ref.watch(vehicleProfileListProvider);
  final catalog = await ref.watch(referenceVehicleCatalogProvider.future);

  bool hasFlagFor(String vehicleId) {
    final raw = settings.getSetting(
      CatalogReresolveDetector.flagKeyFor(vehicleId),
    );
    return raw == true;
  }

  final candidates = CatalogReresolveDetector.findCandidates(
    profiles: profiles,
    catalog: catalog,
    hasFlagFor: hasFlagFor,
  );
  if (kDebugMode && candidates.isNotEmpty) {
    debugPrint(
        'catalogReresolveCandidates: ${candidates.length} pending nudge(s)');
  }
  return candidates;
}

/// Persists the per-vehicle "already nudged" flag once a snackbar has
/// fired for [vehicleId]. The host calls this exactly once per
/// candidate it surfaces.
///
/// Exposed as a top-level helper that accepts a [WidgetRef] so the
/// snackbar host can fire it directly from inside its
/// `ConsumerState`. Returning a future lets the host await the Hive
/// write before invalidating the candidates provider, so the next
/// rebuild sees a consistent flag store.
Future<void> markCatalogReresolveSuggested(
  WidgetRef ref,
  String vehicleId,
) async {
  final settings = ref.read(settingsStorageProvider);
  await settings.putSetting(
    CatalogReresolveDetector.flagKeyFor(vehicleId),
    true,
  );
}
