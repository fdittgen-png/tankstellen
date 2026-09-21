// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../l10n/app_localizations.dart';
import '../domain/entities/user_profile.dart';

/// Localized labels for [LandingScreen] (#4269).
///
/// The labels used to live on the enum itself as a hard-coded
/// `{key: {languageCode: text}}` table covering 10 languages, so the other
/// 13 locales silently rendered English beside a fully translated screen —
/// and the ARB coverage gate could not see the strings at all, because they
/// were not ARB keys. They are now ordinary ARB keys, and the mapping lives
/// in the presentation layer where display text belongs.
///
/// The switch is exhaustive with no default, so adding a [LandingScreen]
/// value fails to compile here instead of quietly falling back to English.
extension LandingScreenL10n on LandingScreen {
  /// The user-facing name of this landing screen.
  String label(AppLocalizations l10n) => switch (this) {
    LandingScreen.favorites => l10n.landingScreenFavorites,
    LandingScreen.map => l10n.landingScreenMap,
    LandingScreen.cheapest => l10n.landingScreenCheapest,
    LandingScreen.nearest => l10n.landingScreenNearest,
  };
}
