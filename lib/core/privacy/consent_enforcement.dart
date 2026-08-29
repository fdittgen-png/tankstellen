// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../data/storage_repository.dart';
import '../storage/storage_keys.dart';

/// #3866 (Epic #3865) — makes a consent change take effect the moment it
/// is saved, and records WHEN it was given against WHICH policy version.
///
/// Consent used to be four booleans read once at startup: revoking
/// "Error reporting" left Sentry running until the next launch, and
/// nothing recorded the date or the policy the user actually saw. GDPR
/// Art. 7(1) asks the controller to be able to demonstrate consent;
/// Art. 7(3) asks withdrawal to be as easy as giving it — and to work.
class ConsentEnforcement {
  ConsentEnforcement._();

  /// Installed by the app initializer: `false` closes Sentry in-session,
  /// `true` starts it (when a DSN is configured). Null in tests / libre.
  static Future<void> Function(bool enabled)? errorReportingHook;

  /// Fire the error-reporting hook. Never throws — a failing SDK
  /// teardown must not block the consent save.
  static Future<void> notifyErrorReporting(bool enabled) async {
    final hook = errorReportingHook;
    if (hook == null) return;
    try {
      await hook(enabled);
    } catch (e, st) {
      debugPrint('ConsentEnforcement: error-reporting hook failed: $e\n$st');
    }
  }
}

/// The persisted consent record: the instant the user last saved their
/// choices and the privacy-policy version they were shown.
class ConsentRecord {
  ConsentRecord._();

  /// True when consent was given against the CURRENT policy version.
  /// A policy bump ([AppConstants.privacyPolicyVersion]) makes this false
  /// once, so the router re-surfaces the consent screen (pre-filled with
  /// the previous choices) — the user re-confirms against the new text.
  static bool isCurrent(SettingsStorage storage) {
    if (storage.getSetting(StorageKeys.gdprConsentGiven) != true) return false;
    return policyVersionOf(storage) >= AppConstants.privacyPolicyVersion;
  }

  /// The policy version the stored consent refers to; 0 for a pre-#3866
  /// record that carried no version.
  static int policyVersionOf(SettingsStorage storage) =>
      storage.getSetting(StorageKeys.consentPolicyVersion) as int? ?? 0;

  /// When the consent was last saved, or null for a pre-#3866 record.
  static DateTime? recordedAt(SettingsStorage storage) {
    final raw = storage.getSetting(StorageKeys.consentRecordedAt) as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
