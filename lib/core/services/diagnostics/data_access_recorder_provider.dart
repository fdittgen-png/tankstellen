// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/feature_management/application/feature_flags_provider.dart';
import '../../../features/feature_management/domain/feature.dart';
import 'data_access_recorder.dart';

part 'data_access_recorder_provider.g.dart';

/// The process-wide [DataAccessRecorder] when developer mode is on, else null
/// (#2824).
///
/// Gated on [Feature.debugMode] exactly like the OBD2 comm-diagnostics gate
/// (#2465): in production (developer mode off — the default) this resolves to
/// `null`, so [recordDataAccess] at every chain call site early-returns and
/// the data layer carries ZERO overhead. When a developer toggles the flag,
/// the keep-alive provider rebuilds, hands a live recorder to the next-built
/// country service, and the chain begins recording without an app restart.
@Riverpod(keepAlive: true)
DataAccessRecorder? dataAccessRecorder(Ref ref) =>
    ref.watch(enabledFeaturesProvider).contains(Feature.debugMode)
        ? DataAccessRecorder()
        : null;
