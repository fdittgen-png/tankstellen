// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/recording_location_settings.dart';
import '../../../core/logging/error_logger.dart';
import 'companion_device_association.dart';

/// #3320 (Epic #3314) — decides whether to establish a Companion-Device-Manager
/// association for the OBD2 dongle so hands-free auto-record can start the
/// connectedDevice FGS from the background.
///
/// Called from a FOREGROUND, user-initiated moment (the system association
/// dialog needs an Activity) — e.g. the first manual OBD2 trip start with a
/// pinned dongle, which both proves the dongle works and is a natural consent
/// point. One-time in effect: once associated, [ensureAssociated] short-circuits.
///
/// Conservative gating (mirrors the #3313 battery-exemption coordinator):
///   * no-op unless [kGpsRecordingForegroundServiceEnabled] (the recording FGS
///     only runs in FGS-approved builds; the CDM permissions aren't even
///     shipped otherwise);
///   * no-op when CDM isn't supported (iOS / pre-34 / no CDM feature);
///   * skips the dialog when already associated;
///   * never throws into the caller's path.
class CompanionAutoRecordCoordinator {
  CompanionAutoRecordCoordinator({
    required CompanionDeviceAssociation association,
    bool fgsEnabled = kGpsRecordingForegroundServiceEnabled,
  })  : _association = association,
        _fgsEnabled = fgsEnabled;

  final CompanionDeviceAssociation _association;
  final bool _fgsEnabled;

  /// #3437 — MACs whose association dialog was already attempted this app
  /// session. A declined (or failed) system dialog must not re-fire on
  /// every subsequent manual trip start; the production provider is
  /// keepAlive, so the guard lives for the app's lifetime and naturally
  /// resets on the next launch (an established association still
  /// short-circuits via [CompanionDeviceAssociation.isAssociated]).
  final Set<String> _attemptedMacs = <String>{};

  /// Ensure a CDM association exists for [mac]. Returns true if associated
  /// (already or newly). Best-effort; never throws. The system association
  /// dialog is attempted at most once per [mac] per app session (#3437).
  Future<bool> ensureAssociated(String mac) async {
    if (!_fgsEnabled) return false;
    try {
      if (!await _association.isSupported()) return false;
      if (await _association.isAssociated()) return true;
      // Mark BEFORE the dialog (the battery-exemption "mark first" idiom,
      // #3313): a declined or crashed dialog never re-nags this session.
      if (!_attemptedMacs.add(mac)) return false;
      return await _association.associate(mac);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'CompanionAutoRecordCoordinator.ensureAssociated'
      }));
      return false;
    }
  }
}

/// Production wiring: the method-channel-backed association.
final companionAutoRecordCoordinatorProvider =
    Provider<CompanionAutoRecordCoordinator>((ref) {
  return CompanionAutoRecordCoordinator(
    association: const MethodChannelCompanionDeviceAssociation(),
  );
});
