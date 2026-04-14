import 'package:flutter/material.dart';

import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Setup screen section: a wrap of [ChoiceChip]s for picking the active
/// [AppLanguage]. Pulled out of `setup_screen.dart` so the screen no
/// longer carries this widget block inline and so the Semantics labels
/// (which announce "selected" state to screen readers) can be exercised
/// by widget tests in isolation.
class LanguageSelector extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelect;

  const LanguageSelector({
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
        Text(l10n?.language ?? 'Language', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AppLanguages.all.map((lang) {
            final isSelected = lang.code == selected.code;
            return Semantics(
              label:
                  'Language ${lang.nativeName}${isSelected ? ", selected" : ""}',
              child: ChoiceChip(
                label: Text(lang.nativeName),
                selected: isSelected,
                onSelected: (_) => onSelect(lang),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
