// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3866 (Epic #3865) — consent is enforced where the data moves, and the
// record of it is demonstrable (Art. 7): the Cloud Sync consent gates the
// whole sync path, Location is ONE key, Error reporting gates the trace
// uploader and closes Sentry in-session, and a policy bump re-surfaces
// the consent screen once.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/location/location_consent.dart';
import 'package:tankstellen/core/privacy/consent_enforcement.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

class _MemStorage implements SettingsStorage {
  final Map<String, dynamic> _m = {};
  @override
  dynamic getSetting(String key) => _m[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => _m[key] = value;
  @override
  bool get isSetupComplete => true;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

void main() {
  group('ConsentRecord', () {
    test('no consent → not current', () {
      expect(ConsentRecord.isCurrent(_MemStorage()), isFalse);
    });

    test('a pre-#3866 record (given, no version) is NOT current — the '
        'policy bump re-surfaces the screen once', () async {
      final s = _MemStorage();
      await s.putSetting(StorageKeys.gdprConsentGiven, true);
      expect(ConsentRecord.isCurrent(s), isFalse);
      expect(ConsentRecord.policyVersionOf(s), 0);
      expect(ConsentRecord.recordedAt(s), isNull);
    });

    test('consent against the current policy version is current', () async {
      final s = _MemStorage();
      await s.putSetting(StorageKeys.gdprConsentGiven, true);
      await s.putSetting(
          StorageKeys.consentPolicyVersion, AppConstants.privacyPolicyVersion);
      await s.putSetting(
          StorageKeys.consentRecordedAt, '2026-08-29T10:00:00.000Z');
      expect(ConsentRecord.isCurrent(s), isTrue);
      expect(ConsentRecord.recordedAt(s), DateTime.utc(2026, 8, 29, 10));
    });

    test('consent against an OLDER policy version is not current', () async {
      final s = _MemStorage();
      await s.putSetting(StorageKeys.gdprConsentGiven, true);
      await s.putSetting(StorageKeys.consentPolicyVersion,
          AppConstants.privacyPolicyVersion - 1);
      expect(ConsentRecord.isCurrent(s), isFalse);
    });
  });

  group('LocationConsentDialog — one key', () {
    test('the consent-screen key wins, false included', () async {
      final s = _MemStorage();
      await s.putSetting(LocationConsentDialog.legacyConsentKey, true);
      await s.putSetting(StorageKeys.consentLocation, false);
      expect(LocationConsentDialog.hasConsent(s), isFalse,
          reason: 'switching Location off in Settings must stop the search '
              'from reading GPS — the legacy key no longer overrides it');
    });

    test('a pre-#3866 install with only the legacy key carries over', () async {
      final s = _MemStorage();
      await s.putSetting(LocationConsentDialog.legacyConsentKey, true);
      expect(LocationConsentDialog.hasConsent(s), isTrue);
    });

    test('recordConsent writes the consent-screen key', () async {
      final s = _MemStorage();
      await LocationConsentDialog.recordConsent(s);
      expect(s.getSetting(StorageKeys.consentLocation), isTrue);
    });
  });

  group('ConsentEnforcement.notifyErrorReporting', () {
    tearDown(() => ConsentEnforcement.errorReportingHook = null);

    test('forwards the new value to the installed hook', () async {
      final seen = <bool>[];
      ConsentEnforcement.errorReportingHook = (v) async => seen.add(v);
      await ConsentEnforcement.notifyErrorReporting(false);
      await ConsentEnforcement.notifyErrorReporting(true);
      expect(seen, [false, true]);
    });

    test('never throws — a failing SDK teardown must not block the save',
        () async {
      ConsentEnforcement.errorReportingHook =
          (_) async => throw StateError('sdk');
      await expectLater(
          ConsentEnforcement.notifyErrorReporting(false), completes);
    });

    test('no hook installed is a no-op', () async {
      await expectLater(
          ConsentEnforcement.notifyErrorReporting(true), completes);
    });
  });
}
