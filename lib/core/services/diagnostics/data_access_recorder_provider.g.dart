// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_access_recorder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The process-wide [DataAccessRecorder] when developer mode is on, else null
/// (#2824).
///
/// Gated on [Feature.debugMode] exactly like the OBD2 comm-diagnostics gate
/// (#2465): in production (developer mode off — the default) this resolves to
/// `null`, so [recordDataAccess] at every chain call site early-returns and
/// the data layer carries ZERO overhead. When a developer toggles the flag,
/// the keep-alive provider rebuilds, hands a live recorder to the next-built
/// country service, and the chain begins recording without an app restart.

@ProviderFor(dataAccessRecorder)
final dataAccessRecorderProvider = DataAccessRecorderProvider._();

/// The process-wide [DataAccessRecorder] when developer mode is on, else null
/// (#2824).
///
/// Gated on [Feature.debugMode] exactly like the OBD2 comm-diagnostics gate
/// (#2465): in production (developer mode off — the default) this resolves to
/// `null`, so [recordDataAccess] at every chain call site early-returns and
/// the data layer carries ZERO overhead. When a developer toggles the flag,
/// the keep-alive provider rebuilds, hands a live recorder to the next-built
/// country service, and the chain begins recording without an app restart.

final class DataAccessRecorderProvider
    extends
        $FunctionalProvider<
          DataAccessRecorder?,
          DataAccessRecorder?,
          DataAccessRecorder?
        >
    with $Provider<DataAccessRecorder?> {
  /// The process-wide [DataAccessRecorder] when developer mode is on, else null
  /// (#2824).
  ///
  /// Gated on [Feature.debugMode] exactly like the OBD2 comm-diagnostics gate
  /// (#2465): in production (developer mode off — the default) this resolves to
  /// `null`, so [recordDataAccess] at every chain call site early-returns and
  /// the data layer carries ZERO overhead. When a developer toggles the flag,
  /// the keep-alive provider rebuilds, hands a live recorder to the next-built
  /// country service, and the chain begins recording without an app restart.
  DataAccessRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataAccessRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataAccessRecorderHash();

  @$internal
  @override
  $ProviderElement<DataAccessRecorder?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DataAccessRecorder? create(Ref ref) {
    return dataAccessRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataAccessRecorder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataAccessRecorder?>(value),
    );
  }
}

String _$dataAccessRecorderHash() =>
    r'e4a33046c1cea0916ad03564b96b98930530516b';
