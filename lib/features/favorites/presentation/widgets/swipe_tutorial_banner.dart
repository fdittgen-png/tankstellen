// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// A dismissable banner that teaches first-time users about swipe gestures
/// on favorite station cards.
///
/// Shows once per install. The "shown" flag is persisted via [SettingsStorage]
/// so the banner never reappears after the user taps "Got it".
class SwipeTutorialBanner extends ConsumerStatefulWidget {
  const SwipeTutorialBanner({super.key});

  @override
  ConsumerState<SwipeTutorialBanner> createState() =>
      _SwipeTutorialBannerState();
}

class _SwipeTutorialBannerState extends ConsumerState<SwipeTutorialBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_checkIfShouldShow));
  }

  void _checkIfShouldShow() {
    final settings = ref.read(settingsStorageProvider);
    final shown = settings.getSetting(StorageKeys.swipeTutorialShown);
    if (shown != true && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    final settings = ref.read(settingsStorageProvider);
    await settings.putSetting(StorageKeys.swipeTutorialShown, true);
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      label: l10n.swipeTutorialMessage,
      child: Container(
        // #3951 — grammar geometry: surface margin, card radius, body role.
        margin: Spacing.surfaceMargin,
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: AppRadius.lg,
        ),
        child: Row(
          children: [
            Icon(
              Icons.swipe,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: Text(
                l10n.swipeTutorialMessage,
                style: AppText.body(context).copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            TextButton(
              onPressed: _dismiss,
              child: Text(l10n.swipeTutorialDismiss),
            ),
          ],
        ),
      ),
    );
  }
}
