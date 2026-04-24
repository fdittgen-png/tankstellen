import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'section_header.dart';

/// Canonical grouped-content card used across every screen body.
///
/// One card, one elevation, one radius, one padding — replaces the
/// 80+ raw `Card(...)` call sites with ad-hoc elevation/margin/color
/// flagged in the #923 audit.
///
/// Visual contract (see `docs/design/DESIGN_SYSTEM.md` §"SectionCard"):
///
///   * `elevation: 0` — separation from the scaffold is handled by the
///     `surfaceContainerLow` tint, not a shadow.
///   * `color: colorScheme.surfaceContainerLow`.
///   * Corner radius is inherited from the global theme
///     (`AppRadius.lg` / 12 px via `FlexColorScheme.subThemesData`).
///   * Default inner padding = `Spacing.cardPadding`.
///   * Default outer margin = `EdgeInsets.zero` so the host `ListView`
///     / `Column` owns card-to-card spacing.
///
/// When [title] is non-null the card renders an internal
/// [SectionHeader] at the top followed by a small gap and the [child].
class SectionCard extends StatelessWidget {
  /// Optional card header title. When null the card has no built-in
  /// header — consumers can place their own leading widget inside
  /// [child].
  final String? title;

  /// Optional sub-title rendered under [title].
  final String? subtitle;

  /// Optional icon rendered by the internal [SectionHeader].
  final IconData? leadingIcon;

  /// Accent color forwarded to the header icon. Defaults to
  /// `colorScheme.primary` when null.
  final Color? accent;

  /// The card body. Required.
  final Widget child;

  /// Inner padding — defaults to `Spacing.cardPadding`
  /// (`EdgeInsets.all(16)`). Override when a card hosts a
  /// full-bleed list (then pass `EdgeInsets.zero` and let the list
  /// owner add its own padding).
  final EdgeInsets padding;

  /// Outer margin — defaults to `EdgeInsets.zero` so the host
  /// scrollable owns card-to-card spacing.
  final EdgeInsets margin;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leadingIcon,
    this.accent,
    this.padding = Spacing.cardPadding,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      // `shape` intentionally omitted — FlexColorScheme applies the
      // canonical `AppRadius.lg` (12 px) card radius globally.
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              SectionHeader(
                title: title!,
                subtitle: subtitle,
                leadingIcon: leadingIcon,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
