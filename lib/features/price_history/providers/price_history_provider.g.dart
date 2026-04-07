// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(priceHistoryRepository)
final priceHistoryRepositoryProvider = PriceHistoryRepositoryProvider._();

final class PriceHistoryRepositoryProvider
    extends
        $FunctionalProvider<
          PriceHistoryRepository,
          PriceHistoryRepository,
          PriceHistoryRepository
        >
    with $Provider<PriceHistoryRepository> {
  PriceHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'priceHistoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$priceHistoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<PriceHistoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PriceHistoryRepository create(Ref ref) {
    return priceHistoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PriceHistoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PriceHistoryRepository>(value),
    );
  }
}

String _$priceHistoryRepositoryHash() =>
    r'f73e38765adc67ed624b1362fc98e859a136d950';

@ProviderFor(priceHistory)
final priceHistoryProvider = PriceHistoryFamily._();

final class PriceHistoryProvider
    extends
        $FunctionalProvider<
          List<PriceRecord>,
          List<PriceRecord>,
          List<PriceRecord>
        >
    with $Provider<List<PriceRecord>> {
  PriceHistoryProvider._({
    required PriceHistoryFamily super.from,
    required (String, {int days}) super.argument,
  }) : super(
         retry: null,
         name: r'priceHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$priceHistoryHash();

  @override
  String toString() {
    return r'priceHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<PriceRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PriceRecord> create(Ref ref) {
    final argument = this.argument as (String, {int days});
    return priceHistory(ref, argument.$1, days: argument.days);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PriceRecord> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PriceRecord>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PriceHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$priceHistoryHash() => r'd914e9c5d5c5601ab4c7a082c3219c2c1a6f47c1';

final class PriceHistoryFamily extends $Family
    with $FunctionalFamilyOverride<List<PriceRecord>, (String, {int days})> {
  PriceHistoryFamily._()
    : super(
        retry: null,
        name: r'priceHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PriceHistoryProvider call(String stationId, {int days = 30}) =>
      PriceHistoryProvider._(argument: (stationId, days: days), from: this);

  @override
  String toString() => r'priceHistoryProvider';
}

@ProviderFor(priceStats)
final priceStatsProvider = PriceStatsFamily._();

final class PriceStatsProvider
    extends $FunctionalProvider<PriceStats, PriceStats, PriceStats>
    with $Provider<PriceStats> {
  PriceStatsProvider._({
    required PriceStatsFamily super.from,
    required (String, FuelType) super.argument,
  }) : super(
         retry: null,
         name: r'priceStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$priceStatsHash();

  @override
  String toString() {
    return r'priceStatsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<PriceStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PriceStats create(Ref ref) {
    final argument = this.argument as (String, FuelType);
    return priceStats(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PriceStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PriceStats>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PriceStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$priceStatsHash() => r'3e4a66696d28242cbcae927c973e223fd3593100';

final class PriceStatsFamily extends $Family
    with $FunctionalFamilyOverride<PriceStats, (String, FuelType)> {
  PriceStatsFamily._()
    : super(
        retry: null,
        name: r'priceStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PriceStatsProvider call(String stationId, FuelType fuelType) =>
      PriceStatsProvider._(argument: (stationId, fuelType), from: this);

  @override
  String toString() => r'priceStatsProvider';
}
