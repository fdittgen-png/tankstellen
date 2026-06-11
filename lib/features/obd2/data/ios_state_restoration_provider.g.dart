// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ios_state_restoration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton provider exposing the [IosStateRestorationService]
/// (#1295 phase 2).
///
/// `keepAlive: true` because the service holds a broadcast stream
/// controller that callers (Phase 3 — BLE listener) subscribe to
/// for the entire app lifetime. Letting Riverpod recreate it on
/// dependency churn would silently drop the controller and break
/// the listener wiring.
///
/// Production resolves to [FlutterBluePlusIosStateRestorationService]
/// — the only implementation. Tests override the provider with a
/// fake (or instantiate the service directly with
/// [FlutterBluePlusIosStateRestorationService.debugIsIOSOverride]
/// to drive both platform branches).

@ProviderFor(iosStateRestorationService)
final iosStateRestorationServiceProvider =
    IosStateRestorationServiceProvider._();

/// Singleton provider exposing the [IosStateRestorationService]
/// (#1295 phase 2).
///
/// `keepAlive: true` because the service holds a broadcast stream
/// controller that callers (Phase 3 — BLE listener) subscribe to
/// for the entire app lifetime. Letting Riverpod recreate it on
/// dependency churn would silently drop the controller and break
/// the listener wiring.
///
/// Production resolves to [FlutterBluePlusIosStateRestorationService]
/// — the only implementation. Tests override the provider with a
/// fake (or instantiate the service directly with
/// [FlutterBluePlusIosStateRestorationService.debugIsIOSOverride]
/// to drive both platform branches).

final class IosStateRestorationServiceProvider
    extends
        $FunctionalProvider<
          IosStateRestorationService,
          IosStateRestorationService,
          IosStateRestorationService
        >
    with $Provider<IosStateRestorationService> {
  /// Singleton provider exposing the [IosStateRestorationService]
  /// (#1295 phase 2).
  ///
  /// `keepAlive: true` because the service holds a broadcast stream
  /// controller that callers (Phase 3 — BLE listener) subscribe to
  /// for the entire app lifetime. Letting Riverpod recreate it on
  /// dependency churn would silently drop the controller and break
  /// the listener wiring.
  ///
  /// Production resolves to [FlutterBluePlusIosStateRestorationService]
  /// — the only implementation. Tests override the provider with a
  /// fake (or instantiate the service directly with
  /// [FlutterBluePlusIosStateRestorationService.debugIsIOSOverride]
  /// to drive both platform branches).
  IosStateRestorationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iosStateRestorationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iosStateRestorationServiceHash();

  @$internal
  @override
  $ProviderElement<IosStateRestorationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IosStateRestorationService create(Ref ref) {
    return iosStateRestorationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IosStateRestorationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IosStateRestorationService>(value),
    );
  }
}

String _$iosStateRestorationServiceHash() =>
    r'ecb8a1e8e23fa11371ce36ac58c41c608c2dc68e';
