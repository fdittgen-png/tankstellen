// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/error_logger.dart';
import '../../obd2/api.dart';
import 'active_vehicle_read.dart';

/// #3437 (Epic #3417) — production trigger for the Companion-Device-Manager
/// association (#3320).
///
/// Fired from the MANUAL OBD2 trip start (the same foreground,
/// user-initiated moment the #3313 battery-exemption prompt uses — the
/// system association dialog needs an Activity), for the active vehicle's
/// pinned dongle. Fire-and-forget: the association is a best-effort side
/// effect of starting a trip and must never block or fail the start.
///
/// No-op when:
///   * the active vehicle has no pinned adapter MAC (nothing to associate),
///   * the vehicle provider graph is unavailable (widget tests),
///   * any of the coordinator's own gates hold — FGS-off default builds,
///     iOS / pre-API-34, already associated, or already attempted this
///     session (see [CompanionAutoRecordCoordinator.ensureAssociated]).
///
/// Never throws — every failure path is error-logged and swallowed.
void triggerCompanionAssociationForPinnedAdapter(Ref ref) {
  try {
    final mac = tryReadActiveVehicleProfile(ref,
            where: 'companionAssociationTrigger: active vehicle unavailable')
        ?.obd2AdapterMac;
    if (mac == null || mac.isEmpty) return;
    final coordinator = ref.read(companionAutoRecordCoordinatorProvider);
    // The coordinator's contract is never-throws, but this is a lifecycle
    // seam on the trip-start path — belt-and-braces so even a misbehaving
    // override can't surface an unhandled async error into the zone.
    unawaited(coordinator
        .ensureAssociated(mac)
        .catchError((Object e, StackTrace st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'triggerCompanionAssociationForPinnedAdapter: ensure'
      }));
      return false;
    }));
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
      'where': 'triggerCompanionAssociationForPinnedAdapter'
    }));
  }
}
