// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/osm_attribution.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/donation_links_provider.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // App Review 3.1.1 (#3536) — external donation links (PayPal /
    // Revolut) must not render on iOS; only IAP may take payments there.
    final showDonations = ref.watch(donationLinksVisibleProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppConstants.appName),
            subtitle: Text('Version ${AppConstants.appVersion}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(AppConstants.developerName),
            subtitle: const Text(AppConstants.developerEmail),
            onTap: () =>
                launchUrl(Uri.parse('mailto:${AppConstants.developerEmail}')),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(AppLocalizations.of(context).openSource),
            subtitle: Text(AppLocalizations.of(context).sourceCode),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.developerWebsite),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(AppLocalizations.of(context).privacyPolicy),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub'), // i18n-ignore: brand / proper noun
            subtitle: const Text('fdittgen-png/tankstellen'),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.githubRepoUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(AppLocalizations.of(context).aboutReportBug),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.githubIssuesUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (showDonations) ...[
            const Divider(height: 1),
            // Donations
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                AppLocalizations.of(context).aboutSupportProject,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).aboutSupportDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.payment, color: Color(0xFF003087)),
              title: const Text('PayPal'), // i18n-ignore: brand / proper noun
              subtitle: const Text('paypal.me/FlorianDITTGEN'),
              onTap: () => launchUrl(
                Uri.parse(AppConstants.paypalUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF0075EB),
              ),
              title: const Text('Revolut'), // i18n-ignore: brand / proper noun
              subtitle: const Text('revolut.me/floriamcep'),
              onTap: () => launchUrl(
                Uri.parse(AppConstants.revolutUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
          const Divider(height: 1),
          // Attributions
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text(AppConstants.tankerkoenigAttribution),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.tankerkoenigCreativeCommonsUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: Text(osmAttributionText(context)),
          ),
        ],
      ),
    );
  }
}
