// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'animated_splash.dart';

/// Top-level recovery screen shown when [AppInitializer.run] fails in
/// the storage phase (#2294).
///
/// #4116 — it says TWO different things now, because it was saying the
/// wrong one. `_initStorage`'s generic catch routes ANY storage-phase
/// fault here — a cipher failure, a TraceStorage failure, or a plain bug
/// in our own code — and the screen told every one of them "the storage
/// file appears to be damaged … clear the app's storage or reinstall.
/// Your favourites and history cannot be restored." A recursion I
/// shipped in #4115 produced exactly that screen, so the app was
/// advising users to destroy their data to work around a bug a patch
/// fixed in one line.
///
/// [cause] therefore gates the copy. Only an actual
/// `HiveCorruptionException` — Hive itself reporting a file it cannot
/// recover — earns the clear-your-storage advice. Everything else gets a
/// message that states what is known, says the data is intact, and
/// explicitly tells the user NOT to clear storage.
///
/// #4118 added a third cause. A restored install carries the encrypted
/// boxes without the KeyStore key that reads them, and the old screen
/// called that damage: the files are perfectly intact, the cause is
/// known, and the good news the corruption copy cannot offer — TankSync
/// still holds whatever was synced — was never said.
///
/// Before this screen existed, a box damaged beyond Hive's own crash
/// recovery threw an uncaught exception out of `_initStorage`, leaving
/// the user frozen on the animated splash with no message and — because
/// `debugPrint` is silenced in release — no telemetry. The class
/// docstring on `AppInitializer` promised "we surface it but still
/// attempt to keep going"; this widget is how we surface it.
///
/// Like [SplashHost], it mounts a bare [WidgetsApp] (no Material
/// scaffolding, no Navigator) because it is rendered *before* Hive /
/// Riverpod are wired — it must not transitively touch any service
/// layer (the bare ProviderScope around its runApp only satisfies the
/// `missing_provider_scope` lint — it wires no services, #3272). Localization delegates are wired so the recovery copy is
/// shown in the device language; if the delegate has not resolved yet a
/// hard-coded English fallback keeps the screen useful rather than
/// blank.
/// Why the storage phase failed — which decides what the screen is
/// allowed to claim, and whether it may advise data loss (#4116/#4118).
enum StorageRecoveryCause {
  /// Cause not established: a cipher fault, a TraceStorage fault, or a
  /// bug of ours. The DEFAULT, and the only safe default — this branch
  /// never advises data loss.
  unknown,

  /// Hive itself reported a box file it could not recover.
  corruptBox,

  /// The boxes are intact but this install has no key for them — a
  /// backup or device-transfer restore.
  keyLost,
}

class StorageRecoveryHost extends StatelessWidget {
  const StorageRecoveryHost({
    super.key,
    this.cause = StorageRecoveryCause.unknown,
  });

  /// Why startup failed. Defaults to [StorageRecoveryCause.unknown] —
  /// the safe direction, because that branch never advises data loss.
  final StorageRecoveryCause cause;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Sparkilo', // i18n-ignore: brand name
      color: AnimatedSplash.brandBackground,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _StorageRecoveryBody(cause: cause),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class _StorageRecoveryBody extends StatelessWidget {
  const _StorageRecoveryBody({required this.cause});

  final StorageRecoveryCause cause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // #4116 — claim damage only when damage was actually reported;
    // #4118 — and name the restore when that is what happened.
    final (title, message, guidance) = switch (cause) {
      StorageRecoveryCause.corruptBox => (
          l10n.storageRecoveryTitle,
          l10n.storageRecoveryMessage,
          l10n.storageRecoveryGuidance,
        ),
      StorageRecoveryCause.keyLost => (
          l10n.storageKeyLostTitle,
          l10n.storageKeyLostMessage,
          l10n.storageKeyLostGuidance,
        ),
      StorageRecoveryCause.unknown => (
          l10n.startupFailureTitle,
          l10n.startupFailureMessage,
          l10n.startupFailureGuidance,
        ),
    };

    return Semantics(
      container: true,
      label: '$title. $message',
      child: ColoredBox(
        color: AnimatedSplash.brandBackground,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storage_rounded,
                    color: AnimatedSplash.logoColor,
                    size: 56,
                    semanticLabel: '',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AnimatedSplash.logoColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AnimatedSplash.logoColor,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    guidance,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // Slightly lower-contrast for the secondary guidance.
                      color: AnimatedSplash.logoColor.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
