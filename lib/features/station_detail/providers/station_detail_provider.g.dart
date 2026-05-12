// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stationDetail)
final stationDetailProvider = StationDetailFamily._();

final class StationDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ServiceResult<StationDetail>>,
          ServiceResult<StationDetail>,
          FutureOr<ServiceResult<StationDetail>>
        >
    with
        $FutureModifier<ServiceResult<StationDetail>>,
        $FutureProvider<ServiceResult<StationDetail>> {
  StationDetailProvider._({
    required StationDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stationDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stationDetailHash();

  @override
  String toString() {
    return r'stationDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ServiceResult<StationDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ServiceResult<StationDetail>> create(Ref ref) {
    final argument = this.argument as String;
    return stationDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StationDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stationDetailHash() => r'84d8bc8b2d2e887bed2286c3d86d1e9004e76f6b';

final class StationDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ServiceResult<StationDetail>>,
          String
        > {
  StationDetailFamily._()
    : super(
        retry: null,
        name: r'stationDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StationDetailProvider call(String stationId) =>
      StationDetailProvider._(argument: stationId, from: this);

  @override
  String toString() => r'stationDetailProvider';
}
