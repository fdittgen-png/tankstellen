// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks for the Cloud Sync consent before any cloud-sync setup (#4337).
///
/// The setup used to be offered — and to mint an identity and upload —
/// with the consent withdrawn, because `SyncConfig.enabled` folds the
/// consent in and so the section read "not set up". The request reuses the
/// consent screen's own wording (what is synced, the legal basis) so the
/// user agrees to the same text in both places, and saves through
/// [gdprConsentProvider] like every other consent change.
///
/// Returns true when the consent is given (already, or now).
Future<bool> requestCloudSyncConsent(BuildContext context, WidgetRef ref) async {
  final consent = ref.read(gdprConsentProvider);
  if (consent.cloudSync) return true;
  final l = AppLocalizations.of(context);
  final granted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('cloudSyncConsentRequest'),
      icon: const Icon(Icons.cloud_outlined),
      title: Text(l.gdprCloudSyncTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.gdprCloudSyncDescription),
            const SizedBox(height: 12),
            Text(l.gdprLegalBasis, style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.continueButton),
        ),
      ],
    ),
  );
  if (granted != true || !context.mounted) return false;
  await ref.read(gdprConsentProvider.notifier).save(
        location: consent.location,
        errorReporting: consent.errorReporting,
        cloudSync: true,
        vinOnlineDecode: consent.vinOnlineDecode,
        syncTrips: consent.syncTrips,
      );
  return true;
}
