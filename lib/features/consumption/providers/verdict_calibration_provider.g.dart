// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verdict_calibration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3503 — the verdict-driven KPI calibration store, backed by the shared
/// Hive `settings` box (same pattern as the last-good-adapter pin store).

@ProviderFor(verdictCalibrationStore)
final verdictCalibrationStoreProvider = VerdictCalibrationStoreProvider._();

/// #3503 — the verdict-driven KPI calibration store, backed by the shared
/// Hive `settings` box (same pattern as the last-good-adapter pin store).

final class VerdictCalibrationStoreProvider
    extends
        $FunctionalProvider<
          VerdictCalibrationStore,
          VerdictCalibrationStore,
          VerdictCalibrationStore
        >
    with $Provider<VerdictCalibrationStore> {
  /// #3503 — the verdict-driven KPI calibration store, backed by the shared
  /// Hive `settings` box (same pattern as the last-good-adapter pin store).
  VerdictCalibrationStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verdictCalibrationStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verdictCalibrationStoreHash();

  @$internal
  @override
  $ProviderElement<VerdictCalibrationStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VerdictCalibrationStore create(Ref ref) {
    return verdictCalibrationStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerdictCalibrationStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerdictCalibrationStore>(value),
    );
  }
}

String _$verdictCalibrationStoreHash() =>
    r'3cd5013c44ac078d145c96209188d307f859bf94';

/// #3503 — the resolved KPI bands: the defaults until enough #3501 verdicts
/// accumulate, then the personal set the store derives. Invalidated by
/// [TripHistoryList.setVerdict] after each new label so the KPI card
/// re-bands on the next build.

@ProviderFor(gpsKpiBands)
final gpsKpiBandsProvider = GpsKpiBandsProvider._();

/// #3503 — the resolved KPI bands: the defaults until enough #3501 verdicts
/// accumulate, then the personal set the store derives. Invalidated by
/// [TripHistoryList.setVerdict] after each new label so the KPI card
/// re-bands on the next build.

final class GpsKpiBandsProvider
    extends $FunctionalProvider<GpsKpiBands, GpsKpiBands, GpsKpiBands>
    with $Provider<GpsKpiBands> {
  /// #3503 — the resolved KPI bands: the defaults until enough #3501 verdicts
  /// accumulate, then the personal set the store derives. Invalidated by
  /// [TripHistoryList.setVerdict] after each new label so the KPI card
  /// re-bands on the next build.
  GpsKpiBandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gpsKpiBandsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gpsKpiBandsHash();

  @$internal
  @override
  $ProviderElement<GpsKpiBands> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GpsKpiBands create(Ref ref) {
    return gpsKpiBands(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GpsKpiBands value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GpsKpiBands>(value),
    );
  }
}

String _$gpsKpiBandsHash() => r'695f8b571c9ff76d8dd30ec42726120543ef94ee';
