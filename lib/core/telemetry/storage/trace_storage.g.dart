// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trace_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(traceStorage)
final traceStorageProvider = TraceStorageProvider._();

final class TraceStorageProvider
    extends $FunctionalProvider<TraceStorage, TraceStorage, TraceStorage>
    with $Provider<TraceStorage> {
  TraceStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'traceStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$traceStorageHash();

  @$internal
  @override
  $ProviderElement<TraceStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TraceStorage create(Ref ref) {
    return traceStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TraceStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TraceStorage>(value),
    );
  }
}

String _$traceStorageHash() => r'deb340d663df4fb2d3dac4ce4747e4ea672fe979';
