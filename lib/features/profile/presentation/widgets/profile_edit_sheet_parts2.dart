// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'profile_edit_sheet.dart';

/// Country selector rendered as a wrap of ChoiceChips with flag + name.
///
/// #2597 — enforces one profile per country: a country already owned by a
/// *different* profile is rendered disabled, and tapping it surfaces a
/// localized "edit that one instead" SnackBar rather than re-binding it.
class _CountrySection extends ConsumerWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;
  final String profileId;

  const _CountrySection({
    required this.state,
    required this.ctrl,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(profileRepositoryProvider);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: Countries.verified.map((c) {
        // A country owned by another profile is taken — the profile being
        // edited may keep its own current country.
        final taken = repo.isCountryTaken(c.code, excludeProfileId: profileId);
        return ChoiceChip(
          label: Text('${c.flag} ${c.name}'),
          selected: c.code == state.countryCode,
          // Taken countries stay tappable but, instead of re-binding,
          // explain (SnackBar) that another profile already owns them —
          // a clearer "edit that one instead" affordance than a silently
          // dead chip.
          onSelected: (_) =>
              taken ? _explainTaken(context, c) : _selectCountry(context, c),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  void _explainTaken(BuildContext context, CountryConfig c) {
    final l10n = AppLocalizations.of(context);
    SnackBarHelper.show(context, l10n.profileCountryTaken(c.name));
  }

  Future<void> _selectCountry(BuildContext context, CountryConfig c) async {
    // Confirm silently-impactful unit changes (currency, distance, volume,
    // price-per-unit format) before mutating the profile. Same-unit
    // switches (e.g. FR ↔ DE, both EUR + km + L + €/L) skip the dialog. A
    // profile with no country set yet also skips — nothing to warn about.
    final currentCode = state.countryCode;
    final current = currentCode == null ? null : Countries.byCode(currentCode);
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
  }
}

/// In-trip approach-overlay (Fuel Station Radar) settings (#2067 /
/// Epic #2065), bound to the sheet's edit state.
///
/// #3884 — the controls themselves live in the public [RadarSettingsCard]
/// so Settings → Driving & consumption → Fuel Station Radar can host the
/// same card for the ACTIVE profile; this thin adapter keeps the edit
/// sheet's `ProfileEditState` / `ProfileEditController` wiring.
class _ApproachOverlaySection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _ApproachOverlaySection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return RadarSettingsCard(
      radiusKm: state.approachRadiusKm,
      priceMode: state.approachPriceMode,
      minPollSeconds: state.approachMinPollSeconds,
      onRadiusChanged: ctrl.setApproachRadiusKm,
      onPriceModeChanged: ctrl.setApproachPriceMode,
      onMinPollSecondsChanged: ctrl.setApproachMinPollSeconds,
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
    return Wrap(
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
    );
  }
}
