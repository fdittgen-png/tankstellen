part of 'profile_edit_sheet.dart';

/// Country selector rendered as a wrap of ChoiceChips with flag + name.
class _CountrySection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _CountrySection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.profileCountry ?? 'Country',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: Countries.all.map((c) {
            return ChoiceChip(
              label: Text('${c.flag} ${c.name}'),
              selected: c.code == state.countryCode,
              onSelected: (_) async {
                // Confirm silently-impactful unit changes (currency,
                // distance, volume, price-per-unit format) before
                // mutating the profile. Same-unit switches (e.g.
                // FR ↔ DE, both EUR + km + L + €/L) skip the
                // dialog. A profile with no country set yet also
                // skips — there's nothing to warn about.
                final currentCode = state.countryCode;
                final current = currentCode == null
                    ? null
                    : Countries.byCode(currentCode);
                if (current == null || current.code == c.code) {
                  ctrl.setCountryCode(c.code);
                  return;
                }
                if (!countriesDifferInUnits(current, c)) {
                  ctrl.setCountryCode(c.code);
                  return;
                }
                final confirmed = await showCountryChangeDialog(
                  context,
                  from: current,
                  to: c,
                );
                if (!context.mounted) return;
                if (confirmed) {
                  ctrl.setCountryCode(c.code);
                }
              },
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Language selector rendered as a wrap of ChoiceChips with native names.
class _LanguageSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _LanguageSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.profileLanguage ?? 'Language',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AppLanguages.all.map((l) {
            return ChoiceChip(
              label: Text(l.nativeName),
              selected: l.code == state.languageCode,
              onSelected: (_) => ctrl.setLanguageCode(l.code),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}
