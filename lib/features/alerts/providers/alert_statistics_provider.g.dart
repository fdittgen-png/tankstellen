// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_statistics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alertStatistics)
final alertStatisticsProvider = AlertStatisticsProvider._();

final class AlertStatisticsProvider
    extends
        $FunctionalProvider<AlertStatistics, AlertStatistics, AlertStatistics>
    with $Provider<AlertStatistics> {
  AlertStatisticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertStatisticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertStatisticsHash();

  @$internal
  @override
  $ProviderElement<AlertStatistics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertStatistics create(Ref ref) {
    return alertStatistics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertStatistics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertStatistics>(value),
    );
  }
}

String _$alertStatisticsHash() => r'f672d4f728ba0e9df488c68eac73a1984950cce1';
