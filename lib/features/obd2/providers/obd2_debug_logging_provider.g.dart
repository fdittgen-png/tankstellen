// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_debug_logging_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opt-in OBD2 debug-session logging flag (#1925).
///
/// When on, every OBD2 connection is recorded — init handshake, data
/// gaps, drops and reconnects — as an exportable XML session log (see
/// [Obd2DebugSessionRecorder]). Off by default; the user opts in via a
/// checkbox in the Trips (OBD2) settings sub-section.
///
/// `build()` mirrors the persisted flag onto
/// [Obd2DebugSessionRecorder.enabled], so reading this provider once at
/// app start (`AppInitializer` warm-up) is enough to arm the recorder
/// for the whole session — the recorder is a plain static and is not
/// itself provider-aware.

@ProviderFor(Obd2DebugSessionLogging)
final obd2DebugSessionLoggingProvider = Obd2DebugSessionLoggingProvider._();

/// Opt-in OBD2 debug-session logging flag (#1925).
///
/// When on, every OBD2 connection is recorded — init handshake, data
/// gaps, drops and reconnects — as an exportable XML session log (see
/// [Obd2DebugSessionRecorder]). Off by default; the user opts in via a
/// checkbox in the Trips (OBD2) settings sub-section.
///
/// `build()` mirrors the persisted flag onto
/// [Obd2DebugSessionRecorder.enabled], so reading this provider once at
/// app start (`AppInitializer` warm-up) is enough to arm the recorder
/// for the whole session — the recorder is a plain static and is not
/// itself provider-aware.
final class Obd2DebugSessionLoggingProvider
    extends $NotifierProvider<Obd2DebugSessionLogging, bool> {
  /// Opt-in OBD2 debug-session logging flag (#1925).
  ///
  /// When on, every OBD2 connection is recorded — init handshake, data
  /// gaps, drops and reconnects — as an exportable XML session log (see
  /// [Obd2DebugSessionRecorder]). Off by default; the user opts in via a
  /// checkbox in the Trips (OBD2) settings sub-section.
  ///
  /// `build()` mirrors the persisted flag onto
  /// [Obd2DebugSessionRecorder.enabled], so reading this provider once at
  /// app start (`AppInitializer` warm-up) is enough to arm the recorder
  /// for the whole session — the recorder is a plain static and is not
  /// itself provider-aware.
  Obd2DebugSessionLoggingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2DebugSessionLoggingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2DebugSessionLoggingHash();

  @$internal
  @override
  Obd2DebugSessionLogging create() => Obd2DebugSessionLogging();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$obd2DebugSessionLoggingHash() =>
    r'9b9bf8868f09bea05287475641b975a04220a56e';

/// Opt-in OBD2 debug-session logging flag (#1925).
///
/// When on, every OBD2 connection is recorded — init handshake, data
/// gaps, drops and reconnects — as an exportable XML session log (see
/// [Obd2DebugSessionRecorder]). Off by default; the user opts in via a
/// checkbox in the Trips (OBD2) settings sub-section.
///
/// `build()` mirrors the persisted flag onto
/// [Obd2DebugSessionRecorder.enabled], so reading this provider once at
/// app start (`AppInitializer` warm-up) is enough to arm the recorder
/// for the whole session — the recorder is a plain static and is not
/// itself provider-aware.

abstract class _$Obd2DebugSessionLogging extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
