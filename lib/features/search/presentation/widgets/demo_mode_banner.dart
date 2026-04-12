import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows a demo-mode banner for API-key countries, or a country info bar for free APIs.
class DemoModeBanner extends ConsumerWidget {
  final CountryConfig country;

  const DemoModeBanner({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(apiKeyStorageProvider);
    final l10n = AppLocalizations.of(context);

    if (country.requiresApiKey && !storage.hasApiKey()) {
      return MaterialBanner(
        content: Text(
          '${country.flag} ${country.name} — '
          '${l10n?.demoModeBanner ?? 'Demo mode. Configure API key in settings for live prices.'}',
        ),
        leading: const Icon(Icons.science_outlined),
        actions: [
          TextButton(
            onPressed: () => context.go('/profile'),
            child: Text(l10n?.apiKeySetup ?? 'Setup'),
          ),
        ],
      );
    }

    if (!country.requiresApiKey) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${country.name} \u2014 ${country.apiProvider}',
                style: Theme.of(context).textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
