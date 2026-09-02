// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'zone_alert_price_sample_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stations whose CURRENT prices seed the zone-alert threshold (#3905).
///
/// The zone-alert sheet used to open with a hard-coded `1.500` threshold —
/// far below a ~2.2 € diesel price, so a freshly saved alert could never
/// fire. The sheet now defaults to "the local price minus 5 %", and this
/// is the local sample it reads: the last search results first (they are
/// the stations around the user right now), else the favorites cache.
/// Both are already in memory — no network call is made for the form.
/// Empty when neither has loaded; the sheet then falls back to its
/// constant default.

@ProviderFor(zoneAlertPriceSample)
final zoneAlertPriceSampleProvider = ZoneAlertPriceSampleProvider._();

/// Stations whose CURRENT prices seed the zone-alert threshold (#3905).
///
/// The zone-alert sheet used to open with a hard-coded `1.500` threshold —
/// far below a ~2.2 € diesel price, so a freshly saved alert could never
/// fire. The sheet now defaults to "the local price minus 5 %", and this
/// is the local sample it reads: the last search results first (they are
/// the stations around the user right now), else the favorites cache.
/// Both are already in memory — no network call is made for the form.
/// Empty when neither has loaded; the sheet then falls back to its
/// constant default.

final class ZoneAlertPriceSampleProvider
    extends $FunctionalProvider<List<Station>, List<Station>, List<Station>>
    with $Provider<List<Station>> {
  /// Stations whose CURRENT prices seed the zone-alert threshold (#3905).
  ///
  /// The zone-alert sheet used to open with a hard-coded `1.500` threshold —
  /// far below a ~2.2 € diesel price, so a freshly saved alert could never
  /// fire. The sheet now defaults to "the local price minus 5 %", and this
  /// is the local sample it reads: the last search results first (they are
  /// the stations around the user right now), else the favorites cache.
  /// Both are already in memory — no network call is made for the form.
  /// Empty when neither has loaded; the sheet then falls back to its
  /// constant default.
  ZoneAlertPriceSampleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zoneAlertPriceSampleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zoneAlertPriceSampleHash();

  @$internal
  @override
  $ProviderElement<List<Station>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Station> create(Ref ref) {
    return zoneAlertPriceSample(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Station> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Station>>(value),
    );
  }
}

String _$zoneAlertPriceSampleHash() =>
    r'7aa00f9ba0de0b653870bbe2f21b4d3d9c7d4204';
