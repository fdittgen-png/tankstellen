import 'package:flutter/material.dart';

import '../../../../core/country/country_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Setup screen section: a wrap of [ChoiceChip]s for picking the active
/// [CountryConfig] (one chip per supported country). Pulled out of
/// `setup_screen.dart` so the screen no longer carries this widget block
/// inline and so the Semantics labels (which announce "selected" state to
/// screen readers) can be exercised by widget tests in isolation.
class CountrySelector extends StatelessWidget {
  final CountryConfig selected;
  final ValueChanged<CountryConfig> onSelect;

  const CountrySelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n?.country ?? 'Country', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Countries.all.map((c) {
            final isSelected = c.code == selected.code;
            return Semantics(
              label: 'Country ${c.name}${isSelected ? ", selected" : ""}',
              child: ChoiceChip(
                label: Text('${c.flag} ${c.name}'),
                selected: isSelected,
                onSelected: (_) => onSelect(c),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
