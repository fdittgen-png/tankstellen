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

String _$activeCountryHash() => r'4763c7ed91d4375c29f2100a4da0a4671857fea7';

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
