import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Centralized SnackBar utility to eliminate duplicate
/// ScaffoldMessenger.of(context).showSnackBar calls.
///
/// Success and error snackbars are themed via [ColorScheme] (never
/// hard-coded colours, so dark mode stays harmonious) and carry a
/// leading icon — so the success/error distinction is conveyed by more
/// than colour alone (#1683 / #1692, accessibility).
///
/// Usage:
/// ```dart
/// SnackBarHelper.show(context, 'Station added to favorites');
/// SnackBarHelper.showSuccess(context, 'Report sent');
/// SnackBarHelper.showWithUndo(context, 'Station hidden', onUndo: () => ...);
/// SnackBarHelper.showError(context, 'Connection failed');
/// ```
class SnackBarHelper {
  SnackBarHelper._();

  /// Show a simple informational snackbar.
  static void show(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  /// Show a success snackbar — themed (`tertiaryContainer`) with a
  /// check icon so success is not signalled by colour alone.
  static void showSuccess(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _IconatedContent(
          icon: Icons.check_circle_outline,
          message: message,
          foreground: scheme.onTertiaryContainer,
        ),
        backgroundColor: scheme.tertiaryContainer,
        duration: duration,
      ),
    );
  }

  /// Show a snackbar with an undo action. [undoLabel] defaults to the
  /// localized "Undo" string — never a hard-coded literal.
  static void showWithUndo(BuildContext context, String message,
      {required VoidCallback onUndo, String? undoLabel}) {
    if (!context.mounted) return;
    final label =
        undoLabel ?? AppLocalizations.of(context)?.undo ?? 'Undo';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: label, onPressed: onUndo),
      ),
    );
  }

  /// Show an error snackbar — themed (`errorContainer`) with an error
  /// icon so the failure is not signalled by colour alone.
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _IconatedContent(
          icon: Icons.error_outline,
          message: message,
          foreground: scheme.onErrorContainer,
        ),
        backgroundColor: scheme.errorContainer,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

/// SnackBar content row: a leading status icon plus the message. The
/// icon gives success/error a non-colour signal; the message [Text] is
/// what the screen reader announces when the SnackBar appears.
class _IconatedContent extends StatelessWidget {
  const _IconatedContent({
    required this.icon,
    required this.message,
    required this.foreground,
  });

  final IconData icon;
  final String message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: foreground, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: TextStyle(color: foreground)),
        ),
      ],
    );
  }
}
