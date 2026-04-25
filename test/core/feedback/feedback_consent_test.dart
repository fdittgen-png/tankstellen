import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/feedback/feedback_consent.dart';

/// Unit tests for [FeedbackConsent] (#952 phase 3).
///
/// The store is backed by `shared_preferences` so we use the in-memory
/// test mock to verify each transition without touching the platform
/// channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('FeedbackConsent', () {
    test('default state is unset when nothing has been written', () async {
      expect(await FeedbackConsent.read(), FeedbackConsentState.unset);
    });

    test('write(granted) → read returns granted', () async {
      await FeedbackConsent.write(FeedbackConsentState.granted);
      expect(await FeedbackConsent.read(), FeedbackConsentState.granted);
    });

    test('write(denied) → read returns denied', () async {
      await FeedbackConsent.write(FeedbackConsentState.denied);
      expect(await FeedbackConsent.read(), FeedbackConsentState.denied);
    });

    test('write(unset) wipes the persisted choice', () async {
      await FeedbackConsent.write(FeedbackConsentState.granted);
      expect(await FeedbackConsent.read(), FeedbackConsentState.granted);
      await FeedbackConsent.write(FeedbackConsentState.unset);
      expect(await FeedbackConsent.read(), FeedbackConsentState.unset);
      // And the prefs key is gone, not just empty.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(FeedbackConsent.storageKey), isFalse);
    });

    test('unknown stored value reads as unset (forward-compat)',
        () async {
      SharedPreferences.setMockInitialValues(const {
        'feedback_github_consent_v1': 'wat',
      });
      expect(await FeedbackConsent.read(), FeedbackConsentState.unset);
    });

    test('toggle granted → denied → granted holds across reads', () async {
      await FeedbackConsent.write(FeedbackConsentState.granted);
      await FeedbackConsent.write(FeedbackConsentState.denied);
      expect(await FeedbackConsent.read(), FeedbackConsentState.denied);
      await FeedbackConsent.write(FeedbackConsentState.granted);
      expect(await FeedbackConsent.read(), FeedbackConsentState.granted);
    });
  });
}
