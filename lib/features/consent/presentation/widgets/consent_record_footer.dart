// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// The consent record footer (#3866, Epic #3865 — Art. 7(1): demonstrable
/// consent): when consent was given and against which policy version,
/// plus the policy link. Closes the "Your choices" list (#3909).
class ConsentRecordFooter extends ConsumerWidget {
  const ConsentRecordFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(gdprConsentProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            consent.recordedAt == null
                ? l10n.consentNotRecorded
                : l10n.consentRecordedAt(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(consent.recordedAt!.toLocal()),
                    consent.policyVersion),
            key: const Key('consentRecordFooter'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('consentPolicyLink'),
            onPressed: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl),
                mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.gdprPolicyLink(AppConstants.privacyPolicyVersion)),
          ),
        ),
      ],
    );
  }
}
