import 'package:flutter/material.dart';

/// Centralized SnackBar utility to eliminate duplicate
/// ScaffoldMessenger.of(context).showSnackBar calls.
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
  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  /// Show a success snackbar (green background).
  static void showSuccess(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show a snackbar with an undo action.
  static void showWithUndo(BuildContext context, String message, {required VoidCallback onUndo, String undoLabel = 'Undo'}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
  }

  /// Show an error snackbar (red background).
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
