// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The compact privacy explanation of the onboarding wizard (#4217 §5).
///
/// Four questions, in the order people actually ask them: what stays on
/// the phone, what is synced, what a fleet manager can see, and how long
/// any of it is kept. Each is one headline the user reads at a glance
/// and one expandable paragraph — "no legal wall of text; details are
/// expandable".
///
/// **Copy only.** There is no control here and no consent is taken: the
/// consent switches the app has (cloud sync, trip sync, fleet sharing)
/// keep living in Settings → Privacy & data, and this slice deliberately
/// adds none (ADR 0025 D6 — the privacy-policy version does not move
/// until the manager surfaces ship). Tests assert the absence of a
/// Switch here for exactly that reason.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';

/// The four privacy questions, each one headline and one expandable
/// paragraph. Reads nothing and writes nothing.
class PrivacySummaryStep extends StatelessWidget {
  const PrivacySummaryStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.fleetPrivacyTitle,
            style: AppText.title(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _PrivacyTopic(
            topicKey: const Key('privacySummaryDevice'),
            icon: Icons.phone_iphone,
            title: l.fleetPrivacyDeviceTitle,
            body: l.fleetPrivacyDeviceBody,
          ),
          const SizedBox(height: 8),
          _PrivacyTopic(
            topicKey: const Key('privacySummarySync'),
            icon: Icons.cloud_outlined,
            title: l.fleetPrivacySyncTitle,
            body: l.fleetPrivacySyncBody,
          ),
          const SizedBox(height: 8),
          _PrivacyTopic(
            topicKey: const Key('privacySummaryManager'),
            icon: Icons.visibility_outlined,
            title: l.fleetPrivacyManagerTitle,
            body: l.fleetPrivacyManagerBody,
          ),
          const SizedBox(height: 8),
          _PrivacyTopic(
            topicKey: const Key('privacySummaryRetention'),
            icon: Icons.schedule_outlined,
            title: l.fleetPrivacyRetentionTitle,
            body: l.fleetPrivacyRetentionBody,
          ),
        ],
      ),
    );
  }
}

/// One headline the user always sees, with its paragraph behind a
/// disclosure triangle.
class _PrivacyTopic extends StatelessWidget {
  const _PrivacyTopic({
    required this.topicKey,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Key topicKey;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: topicKey,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: AppText.body(context)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(body, style: AppText.label(context))],
      ),
    );
  }
}
