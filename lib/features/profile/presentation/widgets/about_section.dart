import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text('Version ${AppConstants.appVersion}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(AppConstants.developerName),
            subtitle: const Text(AppConstants.developerEmail),
            onTap: () => launchUrl(
              Uri.parse('mailto:${AppConstants.developerEmail}'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(
              AppLocalizations.of(context)?.openSource ??
                  'Open Source (MIT License)',
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.sourceCode ??
                  'Source code on GitHub',
            ),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.developerWebsite),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(
              AppLocalizations.of(context)?.privacyPolicy ??
                  'Privacy Policy',
            ),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub'),
            subtitle: const Text('fdittgen-png/tankstellen'),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.githubRepoUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a bug / Suggest a feature'),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.githubIssuesUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          // Donations
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Support this project',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'This app is free, open source, and has no ads. '
              'If you find it useful, consider supporting the developer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading:
                const Icon(Icons.payment, color: Color(0xFF003087)),
            title: const Text('PayPal'),
            subtitle: const Text('paypal.me/FlorianDITTGEN'),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.paypalUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet,
                color: Color(0xFF0075EB)),
            title: const Text('Revolut'),
            subtitle: const Text('revolut.me/floriamcep'),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.revolutUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          // Attributions
          const ListTile(
            leading: Icon(Icons.data_usage),
            title: Text(AppConstants.tankerkoenigAttribution),
          ),
          const ListTile(
            leading: Icon(Icons.map),
            title: Text(AppConstants.osmAttribution),
          ),
        ],
      ),
    );
  }
}
