// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveCountry)
final activeCountryProvider = ActiveCountryProvider._();

final class ActiveCountryProvider
    extends $NotifierProvider<ActiveCountry, CountryConfig> {
  ActiveCountryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCountryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCountryHash();

  @$internal
  @override
  ActiveCountry create() => ActiveCountry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountryConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountryConfig>(value),
    );
  }
}

String _$activeCountryHash() => r'687ba3085ccf486e1daa9fdfdbfc1eb156abd70b';

abstract class _$ActiveCountry extends $Notifier<CountryConfig> {
  CountryConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CountryConfig, CountryConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CountryConfig, CountryConfig>,
              CountryConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// #3361 — `true` when the user has EXPLICITLY configured their country — an
/// active-profile country, or the legacy saved `active_country_code` setting —
/// vs the app having fallen back to locale detection in [ActiveCountry.build].
///
/// Lives here, not in the `location_coverage` classifier, on purpose: reading
/// the profile is already this file's concern, so the country↔profile coupling
/// stays put and the coverage classifier needs no cross-feature import.

@ProviderFor(countryExplicitlyConfigured)
final countryExplicitlyConfiguredProvider =
    CountryExplicitlyConfiguredProvider._();

/// #3361 — `true` when the user has EXPLICITLY configured their country — an
/// active-profile country, or the legacy saved `active_country_code` setting —
/// vs the app having fallen back to locale detection in [ActiveCountry.build].
///
/// Lives here, not in the `location_coverage` classifier, on purpose: reading
/// the profile is already this file's concern, so the country↔profile coupling
/// stays put and the coverage classifier needs no cross-feature import.

final class CountryExplicitlyConfiguredProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// #3361 — `true` when the user has EXPLICITLY configured their country — an
  /// active-profile country, or the legacy saved `active_country_code` setting —
  /// vs the app having fallen back to locale detection in [ActiveCountry.build].
  ///
  /// Lives here, not in the `location_coverage` classifier, on purpose: reading
  /// the profile is already this file's concern, so the country↔profile coupling
  /// stays put and the coverage classifier needs no cross-feature import.
  CountryExplicitlyConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countryExplicitlyConfiguredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countryExplicitlyConfiguredHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return countryExplicitlyConfigured(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$countryExplicitlyConfiguredHash() =>
    r'3f624fd57b6883384dbc78127142689015443805';
