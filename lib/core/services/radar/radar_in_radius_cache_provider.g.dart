// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_in_radius_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The shared, movement+time-gated in-radius merge cache (#3254) used by the
/// radar surfaces that re-evaluate on every GPS fix — the swipe page-set
/// ([radarCandidateList]) and the live on-search radar.
///
/// keepAlive so the gate's last-fetch position/time survives the per-fix
/// rebuilds of those providers; the country's `minInterval` is read live so a
/// country switch picks up the new published cadence. The fetch is fuel-
/// agnostic (`FuelType.all`) — the chain returns every fuel's price per row, so
/// one cached merge serves any selected fuel and a fuel change never forces a
/// re-fetch; [RadarRanking] applies the per-fuel filter downstream.

@ProviderFor(radarInRadiusCache)
final radarInRadiusCacheProvider = RadarInRadiusCacheProvider._();

/// The shared, movement+time-gated in-radius merge cache (#3254) used by the
/// radar surfaces that re-evaluate on every GPS fix — the swipe page-set
/// ([radarCandidateList]) and the live on-search radar.
///
/// keepAlive so the gate's last-fetch position/time survives the per-fix
/// rebuilds of those providers; the country's `minInterval` is read live so a
/// country switch picks up the new published cadence. The fetch is fuel-
/// agnostic (`FuelType.all`) — the chain returns every fuel's price per row, so
/// one cached merge serves any selected fuel and a fuel change never forces a
/// re-fetch; [RadarRanking] applies the per-fuel filter downstream.

final class RadarInRadiusCacheProvider
    extends
        $FunctionalProvider<
          RadarInRadiusCache,
          RadarInRadiusCache,
          RadarInRadiusCache
        >
    with $Provider<RadarInRadiusCache> {
  /// The shared, movement+time-gated in-radius merge cache (#3254) used by the
  /// radar surfaces that re-evaluate on every GPS fix — the swipe page-set
  /// ([radarCandidateList]) and the live on-search radar.
  ///
  /// keepAlive so the gate's last-fetch position/time survives the per-fix
  /// rebuilds of those providers; the country's `minInterval` is read live so a
  /// country switch picks up the new published cadence. The fetch is fuel-
  /// agnostic (`FuelType.all`) — the chain returns every fuel's price per row, so
  /// one cached merge serves any selected fuel and a fuel change never forces a
  /// re-fetch; [RadarRanking] applies the per-fuel filter downstream.
  RadarInRadiusCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarInRadiusCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarInRadiusCacheHash();

  @$internal
  @override
  $ProviderElement<RadarInRadiusCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RadarInRadiusCache create(Ref ref) {
    return radarInRadiusCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadarInRadiusCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadarInRadiusCache>(value),
    );
  }
}

String _$radarInRadiusCacheHash() =>
    r'382244a11b25abd4db677d606231b88322a288fb';
