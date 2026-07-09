// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../data/storage_repository.dart';

class LocationConsentDialog {
  static const String _consentKey = 'location_consent_given';

  /// Check consent using the narrow SettingsStorage interface.
  static bool hasConsent(SettingsStorage storage) {
    return storage.getSetting(_consentKey) == true;
  }

  /// Record consent using the narrow SettingsStorage interface.
  static Future<void> recordConsent(SettingsStorage storage) async {
    await storage.putSetting(_consentKey, true);
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
