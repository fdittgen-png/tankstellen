import 'package:flutter/material.dart';

/// Grouped-form visual component used by the restyled Add-Fill-up and
/// Edit-vehicle forms (#751 phase 2).
///
/// A card with an optional header (title + subtitle) followed by a
/// vertical stack of form rows. Consumers wrap each input row in a
/// [FormFieldTile] so the form gains a consistent:
///
///   * leading 28 dp icon inside a soft colored tile,
///   * label/description pair,
///   * content area (usually the original `TextFormField`).
///
/// The card uses the theme's `surfaceContainer` tint so it rises above
/// the scaffold background without competing with the app-bar color.
/// Spacing and radius mirror the Material-3 list/card rhythm (12 dp
/// radius, 12 dp vertical padding between rows).
class FormSectionCard extends StatelessWidget {
  /// Big section title (e.g. "What you filled").
  final String title;

  /// Optional short sub-title under the title.
  final String? subtitle;

  /// Optional accent color — when null we use
  /// `colorScheme.primary`. The header icon tile and the subtitle use
  /// this color so brand-themed cards (vehicle header) can carry the
  /// brand hue.
  final Color? accent;

  /// Optional icon shown in the header's leading tile. When null the
  /// header renders without a tile, keeping the title on its own.
  final IconData? icon;

  /// Rows of the card. Usually a list of [FormFieldTile]s.
  final List<Widget> children;

  const FormSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = accent ?? theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: title,
              subtitle: subtitle,
              icon: icon,
              accent: accentColor,
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accent;

  const _Header({
    required this.title,
    required this.accent,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Decorative header — screen readers already announce each input
    // below, so the card header tile stays behind ExcludeSemantics to
    // prevent a chatty "icon / title / subtitle" triple announcement.
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            _IconTile(icon: icon!, color: accent),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row inside a [FormSectionCard] — a colored leading icon tile,
/// an optional label, and the input content.
///
/// The icon tile is purely decorative (it mirrors the `TextField`'s
/// label / prefix icon). To avoid the double TalkBack announcement
/// noted in #566 (field labels + tile icon = two chatty nodes), the
/// tile lives inside [ExcludeSemantics]. The wrapped input keeps its
/// real label so TalkBack still reads it.
class FormFieldTile extends StatelessWidget {
  /// Decorative leading icon (28 dp). Pass null to render the row
  /// without a tile — useful for dense sub-rows.
  final IconData? icon;

  /// Optional per-tile color override. Defaults to
  /// `colorScheme.primary`.
  final Color? color;

  /// The input widget itself (TextFormField, DropdownButtonFormField,
  /// a custom tappable row, …). Stretched to the remaining width.
  final Widget content;

  const FormFieldTile({
    super.key,
    required this.content,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(
              child: _IconTile(icon: icon!, color: effective),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// Soft coloured tile that hosts a 28 dp icon. Private helper shared
/// by the card header and every [FormFieldTile].
class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconTile({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }
}
