import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consent/providers/gdpr_consent_form_provider.dart';

void main() {
  group('GdprConsentFormController', () {
    test('initial state is all consents off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);
    });

    test('toggles update only the targeted field', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(gdprConsentFormControllerProvider.notifier);

      notifier.setLocation(true);
      var state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isFalse);
      expect(state.cloudSyncConsent, isFalse);

      notifier.setErrorReporting(true);
      state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isTrue);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isFalse);

      notifier.setCloudSync(true);
      state = container.read(gdprConsentFormControllerProvider);
      expect(state.cloudSyncConsent, isTrue);

      notifier.setLocation(false);
      state = container.read(gdprConsentFormControllerProvider);
      expect(state.locationConsent, isFalse);
      expect(state.errorReportingConsent, isTrue);
      expect(state.cloudSyncConsent, isTrue);
    });
  });
}
