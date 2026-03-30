// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_switch_event.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Computes whether a profile switch should be suggested based on
/// the detected country vs. the active profile's country.

@ProviderFor(countrySwitchEvent)
final countrySwitchEventProvider = CountrySwitchEventProvider._();

/// Computes whether a profile switch should be suggested based on
/// the detected country vs. the active profile's country.

final class CountrySwitchEventProvider
    extends
        $FunctionalProvider<
          CountrySwitchEvent?,
          CountrySwitchEvent?,
          CountrySwitchEvent?
        >
    with $Provider<CountrySwitchEvent?> {
  /// Computes whether a profile switch should be suggested based on
  /// the detected country vs. the active profile's country.
  CountrySwitchEventProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countrySwitchEventProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countrySwitchEventHash();

  @$internal
  @override
  $ProviderElement<CountrySwitchEvent?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CountrySwitchEvent? create(Ref ref) {
    return countrySwitchEvent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountrySwitchEvent? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountrySwitchEvent?>(value),
    );
  }
}

String _$countrySwitchEventHash() =>
    r'c8720509b6523347c73553d239106fb8c9b2b1ab';
