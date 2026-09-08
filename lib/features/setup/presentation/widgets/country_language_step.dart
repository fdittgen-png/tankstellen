// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'illustrations/globe_illustration.dart';
import 'country_info_card.dart';

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
          const SizedBox(height: 8),
          const Center(child: GlobeIllustration(size: 140)),
          const SizedBox(height: 16),
          // Language selector
          Text(
            l10n.language,
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
                label: l10n.languageChipSemantic(
                  lang.nativeName,
                  '$isSelected',
                ),
                child: ChoiceChip(
                  label: Text(lang.nativeName),
                  selected: isSelected,
                  onSelected: (_) {
                    unawaited(
                      ref.read(activeLanguageProvider.notifier).select(lang),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Country selector
          Text(
            l10n.country,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Countries.verified.map((c) {
              final isSelected = c.code == country.code;
              return Semantics(
                label: l10n.countryChipSemantic(c.name, '$isSelected'),
                child: ChoiceChip(
                  label: Text('${c.flag} ${c.name}'),
                  selected: isSelected,
                  onSelected: (_) {
                    unawaited(
                      ref.read(activeCountryProvider.notifier).select(c),
                    );
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // #3987 — the one CountryInfoCard, not an inline copy of it
          // (the copy carried a hard-coded 'Fuel types:').
          CountryInfoCard(country: country),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
