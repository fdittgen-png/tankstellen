import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/country/country_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Setup screen section: optional API key input with format validation and a
/// link to the provider's registration page. Used only when
/// [CountryConfig.requiresApiKey] is true. Pulled out of `setup_screen.dart`
/// so the screen no longer carries an 80-line widget block and so the
/// validation indicator + registration launch can be exercised by widget
/// tests in isolation.
class ApiKeyInputSection extends StatelessWidget {
  final CountryConfig country;
  final TextEditingController controller;
  final bool? formatValid;
  final AppLocalizations? l10n;

  const ApiKeyInputSection({
    super.key,
    required this.country,
    required this.controller,
    required this.formatValid,
    required this.l10n,
  });

  Widget? _buildFormatIndicator() {
    if (formatValid == null) return null;
    if (formatValid!) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return const Icon(Icons.error_outline, color: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('API key setup (optional)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Register for a free API key, or skip to explore '
          'the app with demo data.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (country.apiKeyRegistrationUrl != null)
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(country.apiKeyRegistrationUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: Text('${country.apiProvider} Registration'),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n?.apiKeyLabel ?? 'API Key',
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            prefixIcon: const Icon(Icons.key),
            border: const OutlineInputBorder(),
            suffixIcon: _buildFormatIndicator(),
            errorText: formatValid == false
                ? (l10n?.apiKeyFormatError ??
                    'Invalid format — expected UUID (8-4-4-4-12)')
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'By entering an API key you accept the terms of '
          '${country.apiProvider}. Data redistribution is prohibited.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
