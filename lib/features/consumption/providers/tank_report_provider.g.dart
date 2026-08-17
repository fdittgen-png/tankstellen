// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'tank_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active vehicle's per-tank insight report (#3616).
///
/// Scopes fill-ups with the same convention every trajets surface uses
/// (`vehicleId` match OR legacy null tagging), resolves the closing
/// pleins' linked trips from the already-loaded history list, and hands
/// both to the pure [buildTankReport]. Re-derives whenever a fill-up or
/// trip lands — cheap: the walk is O(fills + linked trips) over data the
/// two watched providers already hold in memory.

@ProviderFor(tankReport)
final tankReportProvider = TankReportProvider._();

/// The active vehicle's per-tank insight report (#3616).
///
/// Scopes fill-ups with the same convention every trajets surface uses
/// (`vehicleId` match OR legacy null tagging), resolves the closing
/// pleins' linked trips from the already-loaded history list, and hands
/// both to the pure [buildTankReport]. Re-derives whenever a fill-up or
/// trip lands — cheap: the walk is O(fills + linked trips) over data the
/// two watched providers already hold in memory.

final class TankReportProvider
    extends $FunctionalProvider<TankReport, TankReport, TankReport>
    with $Provider<TankReport> {
  /// The active vehicle's per-tank insight report (#3616).
  ///
  /// Scopes fill-ups with the same convention every trajets surface uses
  /// (`vehicleId` match OR legacy null tagging), resolves the closing
  /// pleins' linked trips from the already-loaded history list, and hands
  /// both to the pure [buildTankReport]. Re-derives whenever a fill-up or
  /// trip lands — cheap: the walk is O(fills + linked trips) over data the
  /// two watched providers already hold in memory.
  TankReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tankReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tankReportHash();

  @$internal
  @override
  $ProviderElement<TankReport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TankReport create(Ref ref) {
    return tankReport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TankReport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TankReport>(value),
    );
  }
}

String _$tankReportHash() => r'dcd5dbef8810d9f267ca4c4a91ef221deb17be09';
