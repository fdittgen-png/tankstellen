import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/reference_vehicle_catalog_provider.dart';
import '../domain/entities/reference_vehicle.dart';
import '../domain/psa_vin_engine_resolver.dart';
import 'vin_decoder_provider.dart';

part 'psa_vin_engine_candidates_provider.g.dart';

/// Offline engine-candidate set for a PSA VIN (#1864).
///
/// Decodes [vin] via [decodedVinProvider] (offline WMI + position-10
/// year, no proprietary VDS table) and resolves the reference-catalog
/// candidates whose make + generation match — see
/// [resolvePsaEngineCandidates].
///
/// Returns an empty list for a non-PSA VIN, an undecodable VIN, or
/// when nothing in the catalog matches. Keyed by VIN so two callers
/// asking for the same VIN share one resolution.
@riverpod
Future<List<ReferenceVehicle>> psaVinEngineCandidates(
  Ref ref,
  String vin,
) async {
  final vinData = await ref.watch(decodedVinProvider(vin).future);
  if (vinData == null) return const [];
  final catalog = await ref.watch(referenceVehicleCatalogProvider.future);
  return resolvePsaEngineCandidates(vinData: vinData, catalog: catalog);
}
