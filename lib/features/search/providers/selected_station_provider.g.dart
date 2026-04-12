// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_station_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the currently selected station ID for inline detail display.
///
/// On wide screens, selecting a station shows its detail in a side panel
/// rather than navigating to a new route.

@ProviderFor(SelectedStation)
final selectedStationProvider = SelectedStationProvider._();

/// Tracks the currently selected station ID for inline detail display.
///
/// On wide screens, selecting a station shows its detail in a side panel
/// rather than navigating to a new route.
final class SelectedStationProvider
    extends $NotifierProvider<SelectedStation, String?> {
  /// Tracks the currently selected station ID for inline detail display.
  ///
  /// On wide screens, selecting a station shows its detail in a side panel
  /// rather than navigating to a new route.
  SelectedStationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedStationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedStationHash();

  @$internal
  @override
  SelectedStation create() => SelectedStation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedStationHash() => r'1b32d4d16586329c86659de245c99347b783e82c';

/// Tracks the currently selected station ID for inline detail display.
///
/// On wide screens, selecting a station shows its detail in a side panel
/// rather than navigating to a new route.

abstract class _$SelectedStation extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
