// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_connection_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(obd2Connection)
final obd2ConnectionProvider = Obd2ConnectionProvider._();

final class Obd2ConnectionProvider
    extends
        $FunctionalProvider<
          Obd2ConnectionService,
          Obd2ConnectionService,
          Obd2ConnectionService
        >
    with $Provider<Obd2ConnectionService> {
  Obd2ConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ConnectionHash();

  @$internal
  @override
  $ProviderElement<Obd2ConnectionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2ConnectionService create(Ref ref) {
    return obd2Connection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2ConnectionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2ConnectionService>(value),
    );
  }
}

String _$obd2ConnectionHash() => r'25e66e13f6e8da5e47638fb23797e10feecc8985';
