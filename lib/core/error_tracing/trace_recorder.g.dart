// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trace_recorder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(traceRecorder)
final traceRecorderProvider = TraceRecorderProvider._();

final class TraceRecorderProvider
    extends $FunctionalProvider<TraceRecorder, TraceRecorder, TraceRecorder>
    with $Provider<TraceRecorder> {
  TraceRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'traceRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$traceRecorderHash();

  @$internal
  @override
  $ProviderElement<TraceRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TraceRecorder create(Ref ref) {
    return traceRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TraceRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TraceRecorder>(value),
    );
  }
}

String _$traceRecorderHash() => r'd661c34a550e07d9fed1ee25838dc1c72b4c065b';
