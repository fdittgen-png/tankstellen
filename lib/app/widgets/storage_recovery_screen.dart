// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'animated_splash.dart';

/// Top-level recovery screen shown when [AppInitializer.run] hits a
/// [HiveCorruptionException] during the storage phase (#2294).
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
/// layer. Localization delegates are wired so the recovery copy is
/// shown in the device language; if the delegate has not resolved yet a
/// hard-coded English fallback keeps the screen useful rather than
/// blank.
class StorageRecoveryHost extends StatelessWidget {
  const StorageRecoveryHost({super.key});

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
            const _StorageRecoveryBody(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class _StorageRecoveryBody extends StatelessWidget {
  const _StorageRecoveryBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.storageRecoveryTitle;
    final message = l10n.storageRecoveryMessage;
    final guidance = l10n.storageRecoveryGuidance;

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
