// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../data/obd2_comm_diagnostics.dart';

part 'obd2_comm_diagnostics_gate_provider.g.dart';

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
@Riverpod(keepAlive: true)
bool obd2CommDiagnosticsGate(Ref ref) {
  final enabled =
      ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);
  Obd2CommDiagnostics.instance.enabled = enabled;
  if (!enabled) {
    // Drop any retained dev-only session ring the moment the gate closes.
    Obd2CommDiagnostics.instance.reset();
  }
  return enabled;
}
