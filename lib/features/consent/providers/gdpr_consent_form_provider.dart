// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/app_state_provider.dart';

part 'gdpr_consent_form_provider.g.dart';

/// UI state for the first-launch GDPR consent screen toggles.
///
/// Distinct from the persistent `gdprConsentProvider` which holds the
/// saved consent state in Hive. This provider only tracks the user's
/// pending choices before they hit Accept.
class GdprConsentFormState {
  final bool locationConsent;
  final bool errorReportingConsent;
  final bool cloudSyncConsent;
  final bool vinOnlineDecodeConsent;

  const GdprConsentFormState({
    this.locationConsent = false,
    this.errorReportingConsent = false,
    this.cloudSyncConsent = false,
    this.vinOnlineDecodeConsent = false,
  });

  GdprConsentFormState copyWith({
    bool? locationConsent,
    bool? errorReportingConsent,
    bool? cloudSyncConsent,
    bool? vinOnlineDecodeConsent,
  }) {
    return GdprConsentFormState(
      locationConsent: locationConsent ?? this.locationConsent,
      errorReportingConsent:
          errorReportingConsent ?? this.errorReportingConsent,
      cloudSyncConsent: cloudSyncConsent ?? this.cloudSyncConsent,
      vinOnlineDecodeConsent:
          vinOnlineDecodeConsent ?? this.vinOnlineDecodeConsent,
    );
  }
}

@riverpod
class GdprConsentFormController extends _$GdprConsentFormController {
  @override
  GdprConsentFormState build() {
    // #3866 — when the screen re-surfaces after a policy bump, start from
    // the choices the user already made instead of all-off.
    final ({bool location, bool errorReporting, bool cloudSync,
        bool vinOnlineDecode}) saved;
    try {
      final c = ref.read(gdprConsentProvider);
      saved = (location: c.location, errorReporting: c.errorReporting,
          cloudSync: c.cloudSync, vinOnlineDecode: c.vinOnlineDecode);
    } catch (_) {
      // No storage yet (first launch before the boxes, unit tests).
      return const GdprConsentFormState();
    }
    return GdprConsentFormState(
      locationConsent: saved.location,
      errorReportingConsent: saved.errorReporting,
      cloudSyncConsent: saved.cloudSync,
      vinOnlineDecodeConsent: saved.vinOnlineDecode,
    );
  }

  void setLocation(bool value) {
    state = state.copyWith(locationConsent: value);
  }

  void setErrorReporting(bool value) {
    state = state.copyWith(errorReportingConsent: value);
  }

  void setCloudSync(bool value) {
    state = state.copyWith(cloudSyncConsent: value);
  }

  void setVinOnlineDecode(bool value) {
    state = state.copyWith(vinOnlineDecodeConsent: value);
  }
}
