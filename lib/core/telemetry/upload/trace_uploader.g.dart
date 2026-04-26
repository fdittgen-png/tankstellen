// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trace_uploader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(traceUploader)
final traceUploaderProvider = TraceUploaderProvider._();

final class TraceUploaderProvider
    extends $FunctionalProvider<TraceUploader, TraceUploader, TraceUploader>
    with $Provider<TraceUploader> {
  TraceUploaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'traceUploaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$traceUploaderHash();

  @$internal
  @override
  $ProviderElement<TraceUploader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TraceUploader create(Ref ref) {
    return traceUploader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TraceUploader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TraceUploader>(value),
    );
  }
}

String _$traceUploaderHash() => r'1adf891296dd10477a71c5543d1fbbea425913a0';
