import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Centralized SnackBar utility — the single styling, theming and
/// accessibility authority for every SnackBar in the app.
///
/// Success and error snackbars are themed via [ColorScheme] (never
/// hard-coded colours, so dark mode stays harmonious) and carry a
/// leading icon — so the success/error distinction is conveyed by more
/// than colour alone. Every snackbar's content is wrapped in a
/// `liveRegion` [Semantics] node so assistive technologies announce it
/// when it appears (#1683 / #1692, accessibility).
///
/// Two flavours of API:
///  - `show*` context wrappers — for synchronous call sites that still
///    hold a mounted [BuildContext].
///  - `*SnackBar` builders — pure functions that return a [SnackBar].
///    Call sites that show a snackbar *after* an `await` must capture
///    the [ScaffoldMessengerState] (and, for themed variants, the
///    [ColorScheme]) BEFORE the await and feed them to a builder —
///    passing a possibly-unmounted context into a `show*` wrapper would
///    silently drop the snackbar.
///
/// Usage:
/// ```dart
/// SnackBarHelper.show(context, 'Station added to favorites');
/// SnackBarHelper.showSuccess(context, 'Report sent');
/// SnackBarHelper.showWithUndo(context, 'Station hidden', onUndo: () => ...);
/// SnackBarHelper.showError(context, 'Connection failed');
///
/// // async call site:
/// final messenger = ScaffoldMessenger.of(context);
/// final scheme = Theme.of(context).colorScheme;
/// await doWork();
/// messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, message));
/// ```
class SnackBarHelper {
  SnackBarHelper._();

  static const Duration _infoDuration = Duration(seconds: 3);
  static const Duration _errorDuration = Duration(seconds: 5);
  static const Duration _undoDuration = Duration(seconds: 4);

  // ---- Builders -------------------------------------------------------
  // Pure: take only already-resolved values, so they stay safe to call
  // across an async gap once the messenger has been captured.

  /// A plain informational [SnackBar]. [action] adds a trailing button;
  /// [key] lets a caller keep a stable test handle when routing a
  /// previously-bespoke snackbar through the helper.
  static SnackBar infoSnackBar(
    String message, {
    Duration duration = _infoDuration,
    SnackBarAction? action,
    Key? key,
  }) =>
      SnackBar(
        key: key,
        content: _Announced(child: Text(message)),
        duration: duration,
        action: action,
      );

  /// A success [SnackBar] — themed via [scheme] (`tertiaryContainer`,
  /// never hard-coded green) with a check icon so success is signalled
  /// by more than colour alone.
  static SnackBar successSnackBar(
    ColorScheme scheme,
    String message, {
    Duration duration = _infoDuration,
  }) =>
      SnackBar(
        content: _IconatedContent(
          icon: Icons.check_circle_outline,
          message: message,
          foreground: scheme.onTertiaryContainer,
        ),
        backgroundColor: scheme.tertiaryContainer,
        duration: duration,
      );

  /// An error [SnackBar] — themed via [scheme] (`errorContainer`) with
  /// an error icon so the failure is signalled by more than colour.
  static SnackBar errorSnackBar(ColorScheme scheme, String message) =>
      SnackBar(
        content: _IconatedContent(
          icon: Icons.error_outline,
          message: message,
          foreground: scheme.onErrorContainer,
        ),
        backgroundColor: scheme.errorContainer,
        duration: _errorDuration,
      );

  // ---- Context wrappers ----------------------------------------------

  /// Show a simple informational snackbar. [action] adds a trailing
  /// button (e.g. a navigation shortcut).
  static void show(BuildContext context, String message,
      {Duration duration = _infoDuration, SnackBarAction? action}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      infoSnackBar(message, duration: duration, action: action),
    );
  }

  /// Show a success snackbar — themed with a check icon.
  static void showSuccess(BuildContext context, String message,
      {Duration duration = _infoDuration}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar(Theme.of(context).colorScheme, message,
          duration: duration),
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
      infoSnackBar(
        message,
        duration: _undoDuration,
        action: SnackBarAction(label: label, onPressed: onUndo),
      ),
    );
  }

  /// Show an error snackbar — themed with an error icon.
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      errorSnackBar(Theme.of(context).colorScheme, message),
    );
  }
}

/// Wraps SnackBar content in a `liveRegion` [Semantics] node so
/// assistive technologies announce the message when the snackbar
/// appears — colour and motion are not the only signal (#1692).
class _Announced extends StatelessWidget {
  const _Announced({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(liveRegion: true, container: true, child: child);
}

/// SnackBar content row: a leading status icon plus the message. The
/// icon gives success/error a non-colour signal; the row is wrapped in
/// a `liveRegion` [Semantics] node so the message is announced when the
/// SnackBar appears.
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
    return _Announced(
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
