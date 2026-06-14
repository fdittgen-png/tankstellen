// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_scope_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the active Fuel Station Radar renders its stations as the PPI
/// radar-scope view (#3342) instead of the distance-sorted list.
///
/// A pure UI toggle scoped to the search results panel — flipping it never
/// re-runs the scan, it only swaps the visualization of the same station set.
/// Defaults to the list (familiar, accessible default); the scope is the
/// opt-in second view.

@ProviderFor(RadarScopeMode)
final radarScopeModeProvider = RadarScopeModeProvider._();

/// Whether the active Fuel Station Radar renders its stations as the PPI
/// radar-scope view (#3342) instead of the distance-sorted list.
///
/// A pure UI toggle scoped to the search results panel — flipping it never
/// re-runs the scan, it only swaps the visualization of the same station set.
/// Defaults to the list (familiar, accessible default); the scope is the
/// opt-in second view.
final class RadarScopeModeProvider
    extends $NotifierProvider<RadarScopeMode, bool> {
  /// Whether the active Fuel Station Radar renders its stations as the PPI
  /// radar-scope view (#3342) instead of the distance-sorted list.
  ///
  /// A pure UI toggle scoped to the search results panel — flipping it never
  /// re-runs the scan, it only swaps the visualization of the same station set.
  /// Defaults to the list (familiar, accessible default); the scope is the
  /// opt-in second view.
  RadarScopeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarScopeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarScopeModeHash();

  @$internal
  @override
  RadarScopeMode create() => RadarScopeMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$radarScopeModeHash() => r'f29822dac8b5062c06d21deddad3e50cf21efd45';

/// Whether the active Fuel Station Radar renders its stations as the PPI
/// radar-scope view (#3342) instead of the distance-sorted list.
///
/// A pure UI toggle scoped to the search results panel — flipping it never
/// re-runs the scan, it only swaps the visualization of the same station set.
/// Defaults to the list (familiar, accessible default); the scope is the
/// opt-in second view.

abstract class _$RadarScopeMode extends $Notifier<bool> {
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
