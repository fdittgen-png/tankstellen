// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_vin_reader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default factory — returns a real [Obd2VinReader] backed by the live
/// [Obd2Service] handed in by the caller. Production wiring; tests
/// override [obd2VinReaderFactoryProvider] to inject a stub that
/// captures the call without touching Bluetooth.

@ProviderFor(obd2VinReaderFactory)
final obd2VinReaderFactoryProvider = Obd2VinReaderFactoryProvider._();

/// Default factory — returns a real [Obd2VinReader] backed by the live
/// [Obd2Service] handed in by the caller. Production wiring; tests
/// override [obd2VinReaderFactoryProvider] to inject a stub that
/// captures the call without touching Bluetooth.

final class Obd2VinReaderFactoryProvider
    extends
        $FunctionalProvider<
          Obd2VinReaderFactory,
          Obd2VinReaderFactory,
          Obd2VinReaderFactory
        >
    with $Provider<Obd2VinReaderFactory> {
  /// Default factory — returns a real [Obd2VinReader] backed by the live
  /// [Obd2Service] handed in by the caller. Production wiring; tests
  /// override [obd2VinReaderFactoryProvider] to inject a stub that
  /// captures the call without touching Bluetooth.
  Obd2VinReaderFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2VinReaderFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2VinReaderFactoryHash();

  @$internal
  @override
  $ProviderElement<Obd2VinReaderFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2VinReaderFactory create(Ref ref) {
    return obd2VinReaderFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2VinReaderFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2VinReaderFactory>(value),
    );
  }
}

String _$obd2VinReaderFactoryHash() =>
    r'bb99a09cc7b6a623d54072bc8943029129101d00';
