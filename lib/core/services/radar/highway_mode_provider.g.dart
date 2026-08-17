// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'highway_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide highway-mode verdict (#3631).
///
/// Fed by whichever surface currently owns a live GPS stream (the radar
/// search provider on the search screen) — one detector, one truth, so
/// the ahead-filter and the UI chip always agree. `keepAlive` because
/// the sustained-speed history must survive screen churn: driving 10
/// minutes on the motorway then opening the search screen should land
/// directly in highway mode.

@ProviderFor(HighwayMode)
final highwayModeProvider = HighwayModeProvider._();

/// App-wide highway-mode verdict (#3631).
///
/// Fed by whichever surface currently owns a live GPS stream (the radar
/// search provider on the search screen) — one detector, one truth, so
/// the ahead-filter and the UI chip always agree. `keepAlive` because
/// the sustained-speed history must survive screen churn: driving 10
/// minutes on the motorway then opening the search screen should land
/// directly in highway mode.
final class HighwayModeProvider extends $NotifierProvider<HighwayMode, bool> {
  /// App-wide highway-mode verdict (#3631).
  ///
  /// Fed by whichever surface currently owns a live GPS stream (the radar
  /// search provider on the search screen) — one detector, one truth, so
  /// the ahead-filter and the UI chip always agree. `keepAlive` because
  /// the sustained-speed history must survive screen churn: driving 10
  /// minutes on the motorway then opening the search screen should land
  /// directly in highway mode.
  HighwayModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'highwayModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$highwayModeHash();

  @$internal
  @override
  HighwayMode create() => HighwayMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$highwayModeHash() => r'e5eae2512e1ea3d21847fb8c75a1a2f5eb9a41ce';

/// App-wide highway-mode verdict (#3631).
///
/// Fed by whichever surface currently owns a live GPS stream (the radar
/// search provider on the search screen) — one detector, one truth, so
/// the ahead-filter and the UI chip always agree. `keepAlive` because
/// the sustained-speed history must survive screen churn: driving 10
/// minutes on the motorway then opening the search screen should land
/// directly in highway mode.

abstract class _$HighwayMode extends $Notifier<bool> {
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
