// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'profile_edit_sheet.dart';

/// Country selector rendered as a wrap of ChoiceChips with flag + name.
class _CountrySection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _CountrySection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: Countries.verified.map((c) {
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
            final current =
                currentCode == null ? null : Countries.byCode(currentCode);
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
    );
  }
}

/// In-trip approach-overlay settings (#2067 / Epic #2065).
///
/// Three controls:
/// - **Radius** (km) — slider 0.5–5.0 in 0.5 km steps; the geo-fence
///   distance within which the recording overlay grows and flips to
///   a huge price figure.
/// - **Price mode** — `nearest` (default, stable) vs
///   `cheapestInRadius` (re-evaluates as stations enter/leave).
/// - **Min poll** (s) — floor on the speed-adaptive poll cadence
///   (1–10 s). The detector polls more aggressively at higher speed
///   but never tighter than this.
class _ApproachOverlaySection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _ApproachOverlaySection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${l10n?.approachRadiusLabel ?? "Radius"}:'),
            Expanded(
              child: Slider(
                value: state.approachRadiusKm,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: '${state.approachRadiusKm.toStringAsFixed(1)} km',
                onChanged: ctrl.setApproachRadiusKm,
              ),
            ),
            Text('${state.approachRadiusKm.toStringAsFixed(1)} km'),
          ],
        ),
        Text(
          l10n?.approachRadiusCaption(
                  state.approachRadiusKm.toStringAsFixed(1)) ??
              'Overlay grows + shows the price when within '
                  '${state.approachRadiusKm.toStringAsFixed(1)} km '
                  'of a fuel station',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          l10n?.approachPriceModeLabel ?? 'Show price for',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text(l10n?.approachPriceModeNearest ?? 'Nearest station'),
              selected:
                  state.approachPriceMode == ApproachPriceMode.nearest,
              onSelected: (_) =>
                  ctrl.setApproachPriceMode(ApproachPriceMode.nearest),
              visualDensity: VisualDensity.compact,
            ),
            ChoiceChip(
              label: Text(l10n?.approachPriceModeCheapestInRadius ??
                  'Cheapest in radius'),
              selected: state.approachPriceMode ==
                  ApproachPriceMode.cheapestInRadius,
              onSelected: (_) => ctrl
                  .setApproachPriceMode(ApproachPriceMode.cheapestInRadius),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Text('${l10n?.approachMinPollLabel ?? "Min refresh"}:'),
            Expanded(
              child: Slider(
                value: state.approachMinPollSeconds.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${state.approachMinPollSeconds} s',
                onChanged: (v) =>
                    ctrl.setApproachMinPollSeconds(v.round()),
              ),
            ),
            Text('${state.approachMinPollSeconds} s'),
          ],
        ),
        Text(
          l10n?.approachMinPollCaption(state.approachMinPollSeconds) ??
              'Floor on how often the overlay refreshes the nearest '
                  'station (faster at speed, never tighter than '
                  '${state.approachMinPollSeconds} s)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
