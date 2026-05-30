// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_comm_diagnostics_gate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wires the process-wide [Obd2CommDiagnostics.instance] collector's
/// `enabled` flag from [Feature.debugMode] (#2465, Epic #2463).
///
/// The OBD2 comm-path layers ([Obd2Service.connect] et al.) tee into the
/// static [Obd2CommDiagnostics.instance] singleton — the data layer is
/// deliberately Riverpod-free, exactly like [Obd2DebugSessionRecorder].
/// This keep-alive provider is the single bridge that flips that static
/// from the developer-mode flag:
///
///   * `build()` mirrors `Feature.debugMode ∈ enabledFeaturesProvider`
///     onto [Obd2CommDiagnostics.instance.enabled], and reruns whenever
///     the enabled-feature set changes (the user toggles Developer mode),
///     so the collector arms/disarms live without an app restart.
///   * When it disarms, it also [Obd2CommDiagnostics.reset]s the
///     collector so a previously-captured (now PII-redacted but
///     dev-only) session ring is dropped the instant developer mode is
///     turned off.
///
/// Read once at app start (`AppInitializer` warm-up) so a developer who
/// left the flag on last session has the collector armed before the next
/// OBD2 connect, even if they never open Settings — mirroring how
/// `obd2DebugSessionLoggingProvider` arms [Obd2DebugSessionRecorder].
///
/// In production (developer mode off — the default) this resolves to
/// `false`, the static stays `false`, and every comm-path tee is a pure
/// no-op (one cached-bool read + branch-not-taken per instrumented
/// event), so there is zero behaviour change to connect/init.

@ProviderFor(obd2CommDiagnosticsGate)
final obd2CommDiagnosticsGateProvider = Obd2CommDiagnosticsGateProvider._();

/// Wires the process-wide [Obd2CommDiagnostics.instance] collector's
/// `enabled` flag from [Feature.debugMode] (#2465, Epic #2463).
///
/// The OBD2 comm-path layers ([Obd2Service.connect] et al.) tee into the
/// static [Obd2CommDiagnostics.instance] singleton — the data layer is
/// deliberately Riverpod-free, exactly like [Obd2DebugSessionRecorder].
/// This keep-alive provider is the single bridge that flips that static
/// from the developer-mode flag:
///
///   * `build()` mirrors `Feature.debugMode ∈ enabledFeaturesProvider`
///     onto [Obd2CommDiagnostics.instance.enabled], and reruns whenever
///     the enabled-feature set changes (the user toggles Developer mode),
///     so the collector arms/disarms live without an app restart.
///   * When it disarms, it also [Obd2CommDiagnostics.reset]s the
///     collector so a previously-captured (now PII-redacted but
///     dev-only) session ring is dropped the instant developer mode is
///     turned off.
///
/// Read once at app start (`AppInitializer` warm-up) so a developer who
/// left the flag on last session has the collector armed before the next
/// OBD2 connect, even if they never open Settings — mirroring how
/// `obd2DebugSessionLoggingProvider` arms [Obd2DebugSessionRecorder].
///
/// In production (developer mode off — the default) this resolves to
/// `false`, the static stays `false`, and every comm-path tee is a pure
/// no-op (one cached-bool read + branch-not-taken per instrumented
/// event), so there is zero behaviour change to connect/init.

final class Obd2CommDiagnosticsGateProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Wires the process-wide [Obd2CommDiagnostics.instance] collector's
  /// `enabled` flag from [Feature.debugMode] (#2465, Epic #2463).
  ///
  /// The OBD2 comm-path layers ([Obd2Service.connect] et al.) tee into the
  /// static [Obd2CommDiagnostics.instance] singleton — the data layer is
  /// deliberately Riverpod-free, exactly like [Obd2DebugSessionRecorder].
  /// This keep-alive provider is the single bridge that flips that static
  /// from the developer-mode flag:
  ///
  ///   * `build()` mirrors `Feature.debugMode ∈ enabledFeaturesProvider`
  ///     onto [Obd2CommDiagnostics.instance.enabled], and reruns whenever
  ///     the enabled-feature set changes (the user toggles Developer mode),
  ///     so the collector arms/disarms live without an app restart.
  ///   * When it disarms, it also [Obd2CommDiagnostics.reset]s the
  ///     collector so a previously-captured (now PII-redacted but
  ///     dev-only) session ring is dropped the instant developer mode is
  ///     turned off.
  ///
  /// Read once at app start (`AppInitializer` warm-up) so a developer who
  /// left the flag on last session has the collector armed before the next
  /// OBD2 connect, even if they never open Settings — mirroring how
  /// `obd2DebugSessionLoggingProvider` arms [Obd2DebugSessionRecorder].
  ///
  /// In production (developer mode off — the default) this resolves to
  /// `false`, the static stays `false`, and every comm-path tee is a pure
  /// no-op (one cached-bool read + branch-not-taken per instrumented
  /// event), so there is zero behaviour change to connect/init.
  Obd2CommDiagnosticsGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2CommDiagnosticsGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2CommDiagnosticsGateHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return obd2CommDiagnosticsGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$obd2CommDiagnosticsGateHash() =>
    r'6ac84155baaf568a1fd7270c471170a691b872ea';
