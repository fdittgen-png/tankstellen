import 'package:flutter/material.dart';

/// Reusable "tap to drill in" menu row for settings-style screens.
///
/// Originally lived under `lib/features/profile/presentation/widgets/`
/// and was used only by the Profile screen; promoted to
/// `lib/core/widgets/` in #923 phase 2 so Privacy / Sync / onboarding
/// settings can share the exact same tile shape.
///
/// Visual contract (see `docs/design/DESIGN_SYSTEM.md`
/// §"SettingsMenuTile"): a `Card`-wrapped `ListTile` with a small
/// leading icon, a bold `titleSmall` title, a `bodySmall` subtitle,
/// a trailing chevron, and a `VoidCallback onTap`.
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
