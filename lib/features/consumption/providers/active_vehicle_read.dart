// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/vehicle_profile.dart';
import '../../../core/logging/error_logger.dart';
import '../../vehicle/providers/vehicle_providers.dart';

/// Read the active vehicle profile, swallowing any provider-wiring errors
/// that show up in widget tests (where the Riverpod graph for the
/// vehicle-active-profile chain isn't always overridden).
///
/// Shared by the [TripRecording] notifier, the [GpsOnlyRecordingPipeline]
/// and the #3437 companion-association trigger — extracted (#3437/#3438) so
/// each near-cap caller carries a one-line delegation instead of its own
/// copy of this guard. Returns null — both for a cold-start no-vehicle
/// state and an unavailable provider — which every caller already treats
/// as "no vehicle" (generic fuel defaults / cold-start calibration / no
/// pinned adapter). Never throws; the failure is error-logged under the
/// caller-supplied [where] tag.
VehicleProfile? tryReadActiveVehicleProfile(Ref ref, {required String where}) {
  try {
    return ref.read(activeVehicleProfileProvider);
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st,
        context: {'where': where}));
    return null;
  }
}
