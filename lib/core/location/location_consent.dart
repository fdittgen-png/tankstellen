// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../data/storage_repository.dart';
import '../storage/storage_keys.dart';

class LocationConsentDialog {
  /// Pre-#3866 key — this dialog and the consent screen used to write two
  /// different booleans, so switching Location off in Settings never
  /// stopped the search from reading GPS. Kept only for the migration.
  static const String legacyConsentKey = 'location_consent_given';

  /// #3866 (Epic #3865) — ONE location consent: the consent screen's
  /// `consent_location`. An explicit value wins; a pre-#3866 install that
  /// only has the legacy key carries it over once.
  static bool hasConsent(SettingsStorage storage) {
    final current = storage.getSetting(StorageKeys.consentLocation);
    if (current is bool) return current;
    return storage.getSetting(legacyConsentKey) == true;
  }

  /// Record consent using the narrow SettingsStorage interface.
  static Future<void> recordConsent(SettingsStorage storage) async {
    await storage.putSetting(StorageKeys.consentLocation, true);
    await storage.putSetting(legacyConsentKey, true);
  }

  /// Show the GDPR Art. 6(1)(a) location-consent dialog.
  ///
  /// #2306 — every string now resolves through [AppLocalizations] so all
  /// 23 shipped locales render the consent surface in the device
  /// language. The legacy `_ConsentTexts` map only covered a subset of
  /// locales and silently fell back to English for the rest, which is
  /// unacceptable on a consent surface.
  static Future<bool> show(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final bullets = <String>[
      l.locationConsentBulletApi,
      l.locationConsentBulletNoServer,
      l.locationConsentBulletNoTracking,
    ];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l.locationConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.locationConsentSubtitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(l.locationConsentWhatHappens),
              const SizedBox(height: 8),
              ...bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('  •  ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(b, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.locationConsentRevoke,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l.locationConsentLegalBasis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // App Review 5.1.1(iv) (#3535) — a pre-permission explainer must
          // use neutral wording ("Continue") and always proceed to the OS
          // permission prompt; the OS prompt itself is where the user
          // declines. No decline/skip button may appear on this message.
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.continueButton),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
