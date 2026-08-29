// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/storage_repository.dart';
import '../storage/storage_keys.dart';

/// The runtime permissions that get a GDPR pre-permission rationale (#3872).
enum PermissionRationaleKind { camera, bluetooth, notifications }

/// #3872 (epic #3865, GDPR) — pre-permission rationale for the camera
/// (receipt / pump-display / QR scan), Bluetooth (OBD2 adapter) and
/// notifications (price alerts, trip auto-record status).
///
/// Same shape as `LocationConsentDialog`: title, bold lead sentence, a
/// "what happens" heading, transparency bullets, the revoke hint and the
/// Art. 6(1)(a) legal-basis footnote — and ONE `Continue` action.
///
/// App Review 5.1.1(iv) (#3535): a pre-permission explainer must use
/// neutral wording and ALWAYS proceed to the OS permission prompt; the
/// OS prompt itself is where the user declines. No decline / skip button
/// may appear here and the barrier is not dismissible.
///
/// Shown at most once per [PermissionRationaleKind]: the acknowledgement
/// is persisted on the narrow [SettingsStorage] interface under the
/// `StorageKeys.permissionRationaleShown*` keys, so a second [show] for
/// the same kind returns immediately without rendering anything.
class PermissionRationaleDialog {
  PermissionRationaleDialog._();

  /// Widget key of the rendered dialog (tests).
  static const Key dialogKey = Key('permissionRationaleDialog');

  /// Widget key of the single Continue action (tests).
  static const Key continueKey = Key('permissionRationaleContinue');

  /// Settings key that records the one-time acknowledgement of [kind].
  static String storageKeyFor(PermissionRationaleKind kind) {
    switch (kind) {
      case PermissionRationaleKind.camera:
        return StorageKeys.permissionRationaleShownCamera;
      case PermissionRationaleKind.bluetooth:
        return StorageKeys.permissionRationaleShownBluetooth;
      case PermissionRationaleKind.notifications:
        return StorageKeys.permissionRationaleShownNotifications;
    }
  }

  /// Whether the rationale for [kind] was already shown and acknowledged.
  /// Strict `== true` — a stray non-bool value never counts as shown.
  static bool hasBeenShown(
    SettingsStorage storage,
    PermissionRationaleKind kind,
  ) {
    return storage.getSetting(storageKeyFor(kind)) == true;
  }

  /// Record the acknowledgement of [kind] so it is never shown again.
  static Future<void> markShown(
    SettingsStorage storage,
    PermissionRationaleKind kind,
  ) {
    return storage.putSetting(storageKeyFor(kind), true);
  }

  /// Show the rationale for [kind] unless it was already acknowledged.
  ///
  /// Returns once the user taps Continue (and the acknowledgement is
  /// persisted), or immediately when [hasBeenShown] is already true. The
  /// caller then proceeds to the OS prompt in every case.
  static Future<void> show(
    BuildContext context, {
    required PermissionRationaleKind kind,
    required SettingsStorage storage,
  }) async {
    if (hasBeenShown(storage, kind)) return;
    final copy = _RationaleCopy.of(AppLocalizations.of(context), kind);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionRationaleAlert(copy: copy),
    );
    await markShown(storage, kind);
  }
}

/// Per-kind localized copy, resolved once per [PermissionRationaleDialog.show].
class _RationaleCopy {
  final String title;
  final String subtitle;
  final String whatHappens;
  final List<String> bullets;
  final String revoke;
  final String legalBasis;
  final String continueLabel;

  const _RationaleCopy({
    required this.title,
    required this.subtitle,
    required this.whatHappens,
    required this.bullets,
    required this.revoke,
    required this.legalBasis,
    required this.continueLabel,
  });

  factory _RationaleCopy.of(AppLocalizations l, PermissionRationaleKind kind) {
    switch (kind) {
      case PermissionRationaleKind.camera:
        return _RationaleCopy(
          title: l.permissionRationaleCameraTitle,
          subtitle: l.permissionRationaleCameraSubtitle,
          whatHappens: l.permissionRationaleCameraWhatHappens,
          bullets: [
            l.permissionRationaleCameraBulletOnDevice,
            l.permissionRationaleCameraBulletDiscarded,
            l.permissionRationaleCameraBulletNoUpload,
          ],
          revoke: l.permissionRationaleRevoke,
          legalBasis: l.permissionRationaleLegalBasis,
          continueLabel: l.continueButton,
        );
      case PermissionRationaleKind.bluetooth:
        return _RationaleCopy(
          title: l.permissionRationaleBluetoothTitle,
          subtitle: l.permissionRationaleBluetoothSubtitle,
          whatHappens: l.permissionRationaleBluetoothWhatHappens,
          bullets: [
            l.permissionRationaleBluetoothBulletAdapterOnly,
            l.permissionRationaleBluetoothBulletIdentifierLocal,
            l.permissionRationaleBluetoothBulletLegacyLocation,
          ],
          revoke: l.permissionRationaleRevoke,
          legalBasis: l.permissionRationaleLegalBasis,
          continueLabel: l.continueButton,
        );
      case PermissionRationaleKind.notifications:
        return _RationaleCopy(
          title: l.permissionRationaleNotificationsTitle,
          subtitle: l.permissionRationaleNotificationsSubtitle,
          whatHappens: l.permissionRationaleNotificationsWhatHappens,
          bullets: [
            l.permissionRationaleNotificationsBulletLocal,
            l.permissionRationaleNotificationsBulletNothingLeaves,
          ],
          revoke: l.permissionRationaleRevoke,
          legalBasis: l.permissionRationaleLegalBasis,
          continueLabel: l.continueButton,
        );
    }
  }
}

class _PermissionRationaleAlert extends StatelessWidget {
  final _RationaleCopy copy;

  const _PermissionRationaleAlert({required this.copy});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: PermissionRationaleDialog.dialogKey,
      title: Text(copy.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              copy.subtitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(copy.whatHappens),
            const SizedBox(height: 8),
            ...copy.bullets.map(
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
            Text(copy.revoke, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              copy.legalBasis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // App Review 5.1.1(iv) (#3535) — Continue-only, always proceeds
        // to the OS prompt; no decline / skip action on this message.
        FilledButton(
          key: PermissionRationaleDialog.continueKey,
          onPressed: () => Navigator.pop(context),
          child: Text(copy.continueLabel),
        ),
      ],
    );
  }
}
