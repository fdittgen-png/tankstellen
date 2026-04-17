import 'package:flutter/material.dart';

import '../../../../core/country/country_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows a blocking dialog when the user picks a different country
/// in the profile editor — spells out which units will change
/// (currency, distance, fuel volume) so the switch is never silent.
///
/// Returns `true` if the user confirmed, `false` on cancel / dismiss.
/// When the two countries share all unit conventions there is
/// nothing to warn about; callers should short-circuit via
/// [countriesDifferInUnits] and skip the dialog in that case.
Future<bool> showCountryChangeDialog(
  BuildContext context, {
  required CountryConfig from,
  required CountryConfig to,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n?.countryChangeTitle ?? 'Switch country?'),
        content: _DialogBody(from: from, to: to, l10n: l10n),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.countryChangeConfirm ?? 'Switch'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Returns `true` when switching from [from] to [to] changes at
/// least one of currency / distance unit / volume unit / price
/// suffix. When everything matches (e.g. FR ↔ DE, both EUR + km +
/// L + €/L) there is no user-visible difference and the caller
/// should skip the confirmation dialog.
bool countriesDifferInUnits(CountryConfig from, CountryConfig to) {
  if (from.code == to.code) return false;
  return from.currencySymbol != to.currencySymbol ||
      from.distanceUnit != to.distanceUnit ||
      from.volumeUnit != to.volumeUnit ||
      from.pricePerUnitSuffix != to.pricePerUnitSuffix;
}

class _DialogBody extends StatelessWidget {
  final CountryConfig from;
  final CountryConfig to;
  final AppLocalizations? l10n;

  const _DialogBody({
    required this.from,
    required this.to,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.countryChangeBody(to.name) ??
              'Switching to ${to.name} will change:',
        ),
        const SizedBox(height: 12),
        if (from.currencySymbol != to.currencySymbol)
          _UnitRow(
            label: l10n?.countryChangeCurrency ?? 'Currency',
            fromValue: from.currencySymbol,
            toValue: to.currencySymbol,
            theme: theme,
          ),
        if (from.distanceUnit != to.distanceUnit)
          _UnitRow(
            label: l10n?.countryChangeDistance ?? 'Distance',
            fromValue: from.distanceUnit,
            toValue: to.distanceUnit,
            theme: theme,
          ),
        if (from.volumeUnit != to.volumeUnit)
          _UnitRow(
            label: l10n?.countryChangeVolume ?? 'Volume',
            fromValue: from.volumeUnit,
            toValue: to.volumeUnit,
            theme: theme,
          ),
        if (from.pricePerUnitSuffix != to.pricePerUnitSuffix)
          _UnitRow(
            label: l10n?.countryChangePricePerUnit ?? 'Price format',
            fromValue: from.pricePerUnitSuffix,
            toValue: to.pricePerUnitSuffix,
            theme: theme,
          ),
        const SizedBox(height: 12),
        Text(
          l10n?.countryChangeNote ??
              'Existing favorites and fill-up logs are not rewritten; '
                  'only new entries use the new units.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _UnitRow extends StatelessWidget {
  final String label;
  final String fromValue;
  final String toValue;
  final ThemeData theme;

  const _UnitRow({
    required this.label,
    required this.fromValue,
    required this.toValue,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(text: fromValue),
                  const TextSpan(text: '  →  '),
                  TextSpan(
                    text: toValue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
