// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/guarded.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/widgets/snackbar_helper.dart';
import '../../l10n/app_localizations.dart';

/// #1690 — the one-time hint that the tabs respond to a horizontal swipe
/// (an otherwise undiscoverable gesture). Shown once ever, gated on a
/// [SettingsStorage] flag; best-effort, so a missing settings box in a
/// widget test simply skips it. Its own collaborator (#4084) so the shell
/// stays under the file cap without a bump.
class ShellSwipeHint {
  const ShellSwipeHint._();

  /// SettingsStorage key for the one-time swipe-between-tabs hint.
  static const String storageKey = 'shell_swipe_hint_shown';

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    try {
      final settings = ref.read(settingsStorageProvider);
      if (settings.getSetting(storageKey) == true) return;
      await settings.putSetting(storageKey, true);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      // #2173 — route through SnackBarHelper so the liveRegion announce
      // (#1692) isn't bypassed; plain info, no visual change.
      SnackBarHelper.show(
        context,
        l10n.swipeBetweenTabsHint,
        duration: const Duration(seconds: 5),
      );
    } catch (e, st) {
      // #3143 — release-visible: debugPrint is no-opped in release.
      logFailure(e, st, where: 'ShellScreen swipe hint');
    }
  }
}
