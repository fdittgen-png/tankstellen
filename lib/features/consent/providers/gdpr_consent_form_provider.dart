import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  const GdprConsentFormState({
    this.locationConsent = false,
    this.errorReportingConsent = false,
    this.cloudSyncConsent = false,
  });

  GdprConsentFormState copyWith({
    bool? locationConsent,
    bool? errorReportingConsent,
    bool? cloudSyncConsent,
  }) {
    return GdprConsentFormState(
      locationConsent: locationConsent ?? this.locationConsent,
      errorReportingConsent:
          errorReportingConsent ?? this.errorReportingConsent,
      cloudSyncConsent: cloudSyncConsent ?? this.cloudSyncConsent,
    );
  }
}

@riverpod
class GdprConsentFormController extends _$GdprConsentFormController {
  @override
  GdprConsentFormState build() => const GdprConsentFormState();

  void setLocation(bool value) {
    state = state.copyWith(locationConsent: value);
  }

  void setErrorReporting(bool value) {
    state = state.copyWith(errorReportingConsent: value);
  }

  void setCloudSync(bool value) {
    state = state.copyWith(cloudSyncConsent: value);
  }
}
