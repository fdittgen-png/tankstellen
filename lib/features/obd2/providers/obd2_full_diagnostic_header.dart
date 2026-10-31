// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../data/session/obd2_service.dart';
import '../data/session/trip_full_diagnostics.dart';
import 'obd2_full_diagnostic_provider.dart';

/// #4548 (Epic #4547) — the trip's full-diagnostic collaborator, or null
/// when the user has not opted in (the controller then records no trace
/// at all and polls nothing extra).
TripFullDiagnostics? obd2FullDiagnostics(Ref ref, VehicleProfile? vehicle,
    Obd2Service service, bool automatic) {
  final header = obd2FullDiagnosticHeader(ref,
      vehicle: vehicle, service: service, automatic: automatic);
  return header == null ? null : TripFullDiagnostics(header: header);
}

/// The header line of a full-diagnostic trace, or null when off.
///
/// The header makes a trace self-describing for offline analysis: which
/// car (the user's own profile — make, model, engine, fuel), which
/// adapter, and how the trip started. No location and no adapter MAC.
Map<String, Object?>? obd2FullDiagnosticHeader(
  Ref ref, {
  required VehicleProfile? vehicle,
  required Obd2Service service,
  required bool automatic,
}) {
  try {
    if (!ref.read(obd2FullDiagnosticRecordingProvider)) return null;
  } catch (e, st) {
    // An unreadable setting must never stop a recording — record normally.
    log.warn('obd2FullDiagnosticHeader: flag unreadable',
        error: e, stack: st, layer: ErrorLayer.storage);
    return null;
  }
  return {
    'automatic': automatic,
    'vehicle': {
      'id': vehicle?.id,
      'make': vehicle?.make ?? vehicle?.detectedMake,
      'model': vehicle?.model ?? vehicle?.detectedModel,
      'year': vehicle?.year ?? vehicle?.detectedYear,
      'engineCc':
          vehicle?.engineDisplacementCc ?? vehicle?.detectedEngineDisplacementCc,
      'cylinders': vehicle?.engineCylinders,
      'powerKw': vehicle?.enginePowerKw,
      'fuel': vehicle?.preferredFuelType ?? vehicle?.detectedFuelType,
      'type': vehicle?.type.name,
    },
    'adapter': {
      'name': service.adapterName,
      'firmware': service.adapterFirmware,
      'link': service.linkKind,
      'protocol': service.negotiatedProtocolDigit,
    },
  };
}
