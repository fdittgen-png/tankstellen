// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../domain/price_freshness.dart';
import '../../l10n/app_localizations.dart';

/// The localized word for a [PriceFreshness] band (#4092).
///
/// One switch, shared by the result row and the station detail screen, so
/// the two can never call the same price by two different names. It lives
/// in core rather than in `features/search` precisely so the detail
/// screen can use it without one feature reaching into another.
String priceFreshnessWord(PriceFreshness band, AppLocalizations l10n) {
  return switch (band) {
    PriceFreshness.fresh => l10n.priceFreshnessFresh,
    PriceFreshness.recent => l10n.priceFreshnessRecent,
    PriceFreshness.aging => l10n.priceFreshnessAging,
    PriceFreshness.stale => l10n.priceFreshnessStale,
    PriceFreshness.unknown => l10n.priceFreshnessUnknown,
  };
}

/// How strongly a band is allowed to draw the eye (#4092, #4094).
///
/// Only [PriceFreshness.stale] is an attention state — it is the one
/// band where the number on the card may be wrong by a euro. Everything
/// else is metadata and reads as metadata; a "fresh" badge that
/// congratulates itself in green is the colour-washing #4094 is about.
Color priceFreshnessColor(PriceFreshness band, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (band) {
    PriceFreshness.stale => scheme.tertiary,
    PriceFreshness.fresh ||
    PriceFreshness.recent ||
    PriceFreshness.aging ||
    PriceFreshness.unknown =>
      scheme.onSurfaceVariant,
  };
}
