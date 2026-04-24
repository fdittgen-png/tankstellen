// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wakelock_facade.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider seam — override in tests with a fake. `keepAlive: true`
/// because the pin toggle on [TripRecordingScreen] is ephemeral UI
/// state but the underlying facade has no per-screen state worth
/// rebuilding.

@ProviderFor(wakelockFacade)
final wakelockFacadeProvider = WakelockFacadeProvider._();

/// Provider seam — override in tests with a fake. `keepAlive: true`
/// because the pin toggle on [TripRecordingScreen] is ephemeral UI
/// state but the underlying facade has no per-screen state worth
/// rebuilding.

final class WakelockFacadeProvider
    extends $FunctionalProvider<WakelockFacade, WakelockFacade, WakelockFacade>
    with $Provider<WakelockFacade> {
  /// Provider seam — override in tests with a fake. `keepAlive: true`
  /// because the pin toggle on [TripRecordingScreen] is ephemeral UI
  /// state but the underlying facade has no per-screen state worth
  /// rebuilding.
  WakelockFacadeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wakelockFacadeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wakelockFacadeHash();

  @$internal
  @override
  $ProviderElement<WakelockFacade> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WakelockFacade create(Ref ref) {
    return wakelockFacade(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WakelockFacade value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WakelockFacade>(value),
    );
  }
}

String _$wakelockFacadeHash() => r'c5b23b20aef8595773123977f48edfd7d3e06878';
