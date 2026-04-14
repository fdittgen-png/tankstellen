import 'package:flutter/material.dart';

/// Section header used inside the Favorites screen to label the EV and
/// fuel groups. Tiny widget but pulled out so the screen's `build` method
/// stops carrying two near-identical 14-line `_buildXxxSectionHeader`
/// helpers — and so the spacing/colour rules are pinned in one place.
class FavoritesSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final EdgeInsets padding;

  const FavoritesSectionHeader({
    super.key,
    required this.icon,
    required this.label,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
