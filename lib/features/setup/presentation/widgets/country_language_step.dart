import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Second onboarding step: language and country selection.
class CountryLanguageStep extends ConsumerWidget {
  const CountryLanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final country = ref.watch(activeCountryProvider);
    final language = ref.watch(activeLanguageProvider);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Language selector
          Text(
            l10n?.language ?? 'Language',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppLanguages.all.map((lang) {
              final isSelected = lang.code == language.code;
              return Semantics(
                label:
                    'Language ${lang.nativeName}${isSelected ? ", selected" : ""}',
                child: ChoiceChip(
                  label: Text(lang.nativeName),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(activeLanguageProvider.notifier).select(lang);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Country selector
          Text(
            l10n?.country ?? 'Country',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Countries.all.map((c) {
              final isSelected = c.code == country.code;
              return Semantics(
                label:
                    'Country ${c.name}${isSelected ? ", selected" : ""}',
                child: ChoiceChip(
                  label: Text('${c.flag} ${c.name}'),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(activeCountryProvider.notifier).select(c);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Country info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        country.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              country.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Data: ${country.apiProvider ?? 'Demo'}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: country.requiresApiKey
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          country.requiresApiKey
                              ? (l10n?.apiKeyRequired ?? 'API key required')
                              : (l10n?.freeNoKey ?? 'Free — no key needed'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: country.requiresApiKey
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fuel types: ${country.fuelTypes.join(', ')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
