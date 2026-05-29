// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tankerkoenigDio)
final tankerkoenigDioProvider = TankerkoenigDioProvider._();

final class TankerkoenigDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  TankerkoenigDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tankerkoenigDioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tankerkoenigDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return tankerkoenigDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$tankerkoenigDioHash() => r'bf30524d1ff9225e6dd29e0a4b92c6cac725a4e3';

/// Returns the appropriate station service based on the active country.
///
/// Delegates to [CountryServiceRegistry], which is the single source of
/// truth for per-country service wiring — including Germany. Countries
/// that require an API key fall back to [DemoStationService] from inside
/// the registry's factory function when no key is configured.
///
/// #2264 — `keepAlive`: bulk-dataset services (ES/IT/AR/DK) hold the parsed
/// whole-country dataset in instance fields. Under the previous auto-dispose
/// provider the service was rebuilt — and the in-memory dataset thrown away —
/// every time the last listener detached, forcing a re-download far more
/// often than the dataset's TTL. Keeping the provider alive lets the dataset
/// (and its persisted Hive read-through) survive across the session; it still
/// rebuilds when [activeCountryProvider] changes, which is the only time the
/// service identity should change.

@ProviderFor(stationService)
final stationServiceProvider = StationServiceProvider._();

/// Returns the appropriate station service based on the active country.
///
/// Delegates to [CountryServiceRegistry], which is the single source of
/// truth for per-country service wiring — including Germany. Countries
/// that require an API key fall back to [DemoStationService] from inside
/// the registry's factory function when no key is configured.
///
/// #2264 — `keepAlive`: bulk-dataset services (ES/IT/AR/DK) hold the parsed
/// whole-country dataset in instance fields. Under the previous auto-dispose
/// provider the service was rebuilt — and the in-memory dataset thrown away —
/// every time the last listener detached, forcing a re-download far more
/// often than the dataset's TTL. Keeping the provider alive lets the dataset
/// (and its persisted Hive read-through) survive across the session; it still
/// rebuilds when [activeCountryProvider] changes, which is the only time the
/// service identity should change.

final class StationServiceProvider
    extends $FunctionalProvider<StationService, StationService, StationService>
    with $Provider<StationService> {
  /// Returns the appropriate station service based on the active country.
  ///
  /// Delegates to [CountryServiceRegistry], which is the single source of
  /// truth for per-country service wiring — including Germany. Countries
  /// that require an API key fall back to [DemoStationService] from inside
  /// the registry's factory function when no key is configured.
  ///
  /// #2264 — `keepAlive`: bulk-dataset services (ES/IT/AR/DK) hold the parsed
  /// whole-country dataset in instance fields. Under the previous auto-dispose
  /// provider the service was rebuilt — and the in-memory dataset thrown away —
  /// every time the last listener detached, forcing a re-download far more
  /// often than the dataset's TTL. Keeping the provider alive lets the dataset
  /// (and its persisted Hive read-through) survive across the session; it still
  /// rebuilds when [activeCountryProvider] changes, which is the only time the
  /// service identity should change.
  StationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stationServiceHash();

  @$internal
  @override
  $ProviderElement<StationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StationService create(Ref ref) {
    return stationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StationService>(value),
    );
  }
}

String _$stationServiceHash() => r'1a5459fd2f967babafab83d85d20b0c32fd0e358';

/// Cross-country station service lookup (#753 widget tap path, #514
/// favorites currency, #515 route search). Resolves the
/// [StationService] for an arbitrary [countryCode] without changing
/// the active country.
///
/// Exposed as a `Provider.family` so tests can override per-country
/// services without standing up the full `CountryServiceRegistry`.
/// Production paths use the [stationServiceForCountry] sync helper.
///
/// #2264 — `keepAlive` for the same bulk-dataset reason as
/// [stationServiceProvider]: a per-country bulk service keeps its parsed
/// dataset alive across rebuilds instead of re-downloading the whole country
/// on every cross-country lookup.

@ProviderFor(perCountryStationService)
final perCountryStationServiceProvider = PerCountryStationServiceFamily._();

/// Cross-country station service lookup (#753 widget tap path, #514
/// favorites currency, #515 route search). Resolves the
/// [StationService] for an arbitrary [countryCode] without changing
/// the active country.
///
/// Exposed as a `Provider.family` so tests can override per-country
/// services without standing up the full `CountryServiceRegistry`.
/// Production paths use the [stationServiceForCountry] sync helper.
///
/// #2264 — `keepAlive` for the same bulk-dataset reason as
/// [stationServiceProvider]: a per-country bulk service keeps its parsed
/// dataset alive across rebuilds instead of re-downloading the whole country
/// on every cross-country lookup.

final class PerCountryStationServiceProvider
    extends $FunctionalProvider<StationService, StationService, StationService>
    with $Provider<StationService> {
  /// Cross-country station service lookup (#753 widget tap path, #514
  /// favorites currency, #515 route search). Resolves the
  /// [StationService] for an arbitrary [countryCode] without changing
  /// the active country.
  ///
  /// Exposed as a `Provider.family` so tests can override per-country
  /// services without standing up the full `CountryServiceRegistry`.
  /// Production paths use the [stationServiceForCountry] sync helper.
  ///
  /// #2264 — `keepAlive` for the same bulk-dataset reason as
  /// [stationServiceProvider]: a per-country bulk service keeps its parsed
  /// dataset alive across rebuilds instead of re-downloading the whole country
  /// on every cross-country lookup.
  PerCountryStationServiceProvider._({
    required PerCountryStationServiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'perCountryStationServiceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$perCountryStationServiceHash();

  @override
  String toString() {
    return r'perCountryStationServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<StationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StationService create(Ref ref) {
    final argument = this.argument as String;
    return perCountryStationService(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StationService>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerCountryStationServiceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$perCountryStationServiceHash() =>
    r'79b833834003864cb3a193f9e8f7ea184c6fe0f6';

/// Cross-country station service lookup (#753 widget tap path, #514
/// favorites currency, #515 route search). Resolves the
/// [StationService] for an arbitrary [countryCode] without changing
/// the active country.
///
/// Exposed as a `Provider.family` so tests can override per-country
/// services without standing up the full `CountryServiceRegistry`.
/// Production paths use the [stationServiceForCountry] sync helper.
///
/// #2264 — `keepAlive` for the same bulk-dataset reason as
/// [stationServiceProvider]: a per-country bulk service keeps its parsed
/// dataset alive across rebuilds instead of re-downloading the whole country
/// on every cross-country lookup.

final class PerCountryStationServiceFamily extends $Family
    with $FunctionalFamilyOverride<StationService, String> {
  PerCountryStationServiceFamily._()
    : super(
        retry: null,
        name: r'perCountryStationServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Cross-country station service lookup (#753 widget tap path, #514
  /// favorites currency, #515 route search). Resolves the
  /// [StationService] for an arbitrary [countryCode] without changing
  /// the active country.
  ///
  /// Exposed as a `Provider.family` so tests can override per-country
  /// services without standing up the full `CountryServiceRegistry`.
  /// Production paths use the [stationServiceForCountry] sync helper.
  ///
  /// #2264 — `keepAlive` for the same bulk-dataset reason as
  /// [stationServiceProvider]: a per-country bulk service keeps its parsed
  /// dataset alive across rebuilds instead of re-downloading the whole country
  /// on every cross-country lookup.

  PerCountryStationServiceProvider call(String countryCode) =>
      PerCountryStationServiceProvider._(argument: countryCode, from: this);

  @override
  String toString() => r'perCountryStationServiceProvider';
}

@ProviderFor(geocodingChain)
final geocodingChainProvider = GeocodingChainProvider._();

final class GeocodingChainProvider
    extends $FunctionalProvider<GeocodingChain, GeocodingChain, GeocodingChain>
    with $Provider<GeocodingChain> {
  GeocodingChainProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geocodingChainProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geocodingChainHash();

  @$internal
  @override
  $ProviderElement<GeocodingChain> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeocodingChain create(Ref ref) {
    return geocodingChain(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeocodingChain value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeocodingChain>(value),
    );
  }
}

String _$geocodingChainHash() => r'183b5dfca7535d6a902d97f4c40b3239376b4108';
