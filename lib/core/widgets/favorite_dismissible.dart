// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/dark_mode_colors.dart';
import '../utils/navigation_utils.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/snackbar_helper.dart';
import '../../l10n/app_localizations.dart';

/// The ONE swipe-to-act favorites wrapper, promoted to core after the
/// fuel-station and EV twins (#1958) diverged only in their provider
/// and card types. Swiping right launches turn-by-turn navigation in
/// the system maps app; swiping left removes the favorite (behind the
/// #3682 app-wide delete confirmation) with an undo snackbar.
///
/// Feature boundary: this widget takes primitives + callbacks only.
/// The generic [T] is the caller's keepAlive notifier handle —
/// [captureHandle] runs synchronously at the START of the swipe
/// callback, BEFORE any await (#3159): the dismissed row's element
/// unmounts once the swipe completes, so any post-await `ref` use
/// would throw a StateError on the dead WidgetRef. The captured
/// handle stays valid for [removeFavorite] and the snackbar's
/// [undoRemove].
class FavoriteDismissible<T> extends StatelessWidget {
  /// Stable per-row [Dismissible] key value (e.g. `'fav-<id>'`).
  final String dismissKey;

  /// Display name used in semantics + the undo snackbar.
  final String label;

  /// Destination for the swipe-right navigation launch.
  final double latitude;
  final double longitude;

  /// Returns the keepAlive notifier handle — called synchronously
  /// before any await (#3159).
  final T Function() captureHandle;

  /// Removes the favorite via the captured handle.
  final Future<void> Function(T handle) removeFavorite;

  /// Re-adds the favorite via the captured handle (undo snackbar).
  final void Function(T handle) undoRemove;

  final Widget child;

  const FavoriteDismissible({
    super.key,
    required this.dismissKey,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.captureHandle,
    required this.removeFavorite,
    required this.undoRemove,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey(dismissKey),
      confirmDismiss: (direction) async {
        // #3159 — capture before any await (see class doc).
        final handle = captureHandle();
        if (direction == DismissDirection.startToEnd) {
          await NavigationUtils.openInMaps(latitude, longitude, label: label);
          return false;
        }
        // #3682 — the app-wide delete confirmation before the removal.
        if (!await confirmDestructiveAction(context)) return false;
        if (!context.mounted) return false;
        await removeFavorite(handle);
        if (!context.mounted) return true;
        final l10nSnack = AppLocalizations.of(context);
        SnackBarHelper.showWithUndo(
          context,
          l10nSnack.removedFromFavoritesName(label),
          undoLabel: l10nSnack.undo,
          onUndo: () => undoRemove(handle),
        );
        return true;
      },
      background: Semantics(
        label: l10n.semanticsNavigateTo(label),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.navigation, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.navigate,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      secondaryBackground: Semantics(
        label: l10n.semanticsRemoveFromFavorites(label),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: DarkModeColors.error(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.remove,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
      child: child,
    );
  }
}
