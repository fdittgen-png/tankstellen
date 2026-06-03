// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_pin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Always pin when the fuel-station radar starts" preference (#2785).
///
/// Mirrors the trip-recording [RecordingProfile.autoPin]: when on, the search
/// screen pins itself (wake lock + immersive bars) the moment the radar
/// activates, so the closest-station readout stays visible on a dashboard
/// mount without a manual tap each time.
///
/// **Defaults to true** — the dashboard-mount use case is the common one. The
/// read is defensive: a missing key (fresh install) or briefly-unavailable
/// storage (before init / in tests) degrades to the `true` default rather than
/// crashing the search screen. A stored explicit `false` (a deliberate opt-out
/// via the pin-help toggle) is honoured.

@ProviderFor(RadarAutoPin)
final radarAutoPinProvider = RadarAutoPinProvider._();

/// "Always pin when the fuel-station radar starts" preference (#2785).
///
/// Mirrors the trip-recording [RecordingProfile.autoPin]: when on, the search
/// screen pins itself (wake lock + immersive bars) the moment the radar
/// activates, so the closest-station readout stays visible on a dashboard
/// mount without a manual tap each time.
///
/// **Defaults to true** — the dashboard-mount use case is the common one. The
/// read is defensive: a missing key (fresh install) or briefly-unavailable
/// storage (before init / in tests) degrades to the `true` default rather than
/// crashing the search screen. A stored explicit `false` (a deliberate opt-out
/// via the pin-help toggle) is honoured.
final class RadarAutoPinProvider extends $NotifierProvider<RadarAutoPin, bool> {
  /// "Always pin when the fuel-station radar starts" preference (#2785).
  ///
  /// Mirrors the trip-recording [RecordingProfile.autoPin]: when on, the search
  /// screen pins itself (wake lock + immersive bars) the moment the radar
  /// activates, so the closest-station readout stays visible on a dashboard
  /// mount without a manual tap each time.
  ///
  /// **Defaults to true** — the dashboard-mount use case is the common one. The
  /// read is defensive: a missing key (fresh install) or briefly-unavailable
  /// storage (before init / in tests) degrades to the `true` default rather than
  /// crashing the search screen. A stored explicit `false` (a deliberate opt-out
  /// via the pin-help toggle) is honoured.
  RadarAutoPinProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarAutoPinProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarAutoPinHash();

  @$internal
  @override
  RadarAutoPin create() => RadarAutoPin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$radarAutoPinHash() => r'35056e35490e600022ddd3f86ceaffd102b54276';

/// "Always pin when the fuel-station radar starts" preference (#2785).
///
/// Mirrors the trip-recording [RecordingProfile.autoPin]: when on, the search
/// screen pins itself (wake lock + immersive bars) the moment the radar
/// activates, so the closest-station readout stays visible on a dashboard
/// mount without a manual tap each time.
///
/// **Defaults to true** — the dashboard-mount use case is the common one. The
/// read is defensive: a missing key (fresh install) or briefly-unavailable
/// storage (before init / in tests) degrades to the `true` default rather than
/// crashing the search screen. A stored explicit `false` (a deliberate opt-out
/// via the pin-help toggle) is honoured.

abstract class _$RadarAutoPin extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
