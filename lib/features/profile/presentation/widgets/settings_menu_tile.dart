import 'package:flutter/material.dart';

/// Reusable menu row used by `ProfileScreen` for the top-level
/// destinations (My vehicles, Privacy Dashboard). Each instance is a
/// `Card`-wrapped `ListTile` with a small leading icon, a bold title,
/// a body-small subtitle, a trailing chevron, and an `onTap` callback.
///
/// Pulled out of `profile_screen.dart` so the screen drops nearly
/// identical 20-line `Card` blocks and so the tile shape can be exercised
/// by widget tests in isolation.
///
/// #896 — the Consumption log entry was removed in favour of the
/// dedicated bottom-nav tab to avoid duplicate navigation.
class SettingsMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
