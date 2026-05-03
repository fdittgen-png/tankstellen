// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_reresolve_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(catalogReresolveCandidates)
final catalogReresolveCandidatesProvider =
    CatalogReresolveCandidatesProvider._();

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

final class CatalogReresolveCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogReresolveCandidate>>,
          List<CatalogReresolveCandidate>,
          FutureOr<List<CatalogReresolveCandidate>>
        >
    with
        $FutureModifier<List<CatalogReresolveCandidate>>,
        $FutureProvider<List<CatalogReresolveCandidate>> {
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
  CatalogReresolveCandidatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogReresolveCandidatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogReresolveCandidatesHash();

  @$internal
  @override
  $FutureProviderElement<List<CatalogReresolveCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CatalogReresolveCandidate>> create(Ref ref) {
    return catalogReresolveCandidates(ref);
  }
}

String _$catalogReresolveCandidatesHash() =>
    r'dac43c5b4e9094521cd14bcf0ee831c7758aa338';
