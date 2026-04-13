import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/search_mode.dart';

/// Two-button SegmentedButton that switches between *nearby* and *along
/// route* search modes. Stateless: the parent owns the [SearchMode] state
/// and receives changes via [onChanged].
class SearchModeToggle extends StatelessWidget {
  final SearchMode mode;
  final ValueChanged<SearchMode> onChanged;

  const SearchModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<SearchMode>(
      key: const ValueKey('criteria-mode-toggle'),
      segments: [
        ButtonSegment(
          value: SearchMode.nearby,
          label: Text(l10n?.searchNearby ?? 'Nearby'),
          icon: const Icon(Icons.near_me),
        ),
        ButtonSegment(
          value: SearchMode.route,
          label: Text(l10n?.searchAlongRoute ?? 'Along route'),
          icon: const Icon(Icons.route),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}
