// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — the identity a help symbol, a guide heading and that object's
// screenshot all share.
//
// One dotted id, lower case, never translated: `<area>.<screen>.<object>`.
// The guide carries it as an HTML comment on the line above the heading
// it names — invisible on GitHub and invisible in the app — and
// `tool/build_help.dart` compiles those comments into
// `assets/help/<lang>.anchors.json`, so the help screen opens at the
// exact paragraph instead of the first heading whose text happens to
// contain a word.
//
// The rule that keeps a Danish reader from tapping a `?` and landing
// nowhere: an anchor may only be pointed at when EVERY wiki language
// carries that heading. `test/lint/help_anchor_test.dart` enforces it.
abstract final class HelpAnchor {
  // ── search · the criteria sheet ────────────────────────────────────
  /// The one button, and what it does from each place it is pressed.
  static const searchButton = 'search.criteria.button';

  /// Nearby versus along-route: two different questions.
  static const searchMode = 'search.criteria.mode';

  /// Which fuel the prices are for, and why the app asks once.
  static const searchFuelType = 'search.criteria.fuel-type';

  /// How far to look, and what a wider radius costs you in waiting.
  static const searchRadius = 'search.criteria.radius';

  /// Open now only.
  static const searchOpenOnly = 'search.criteria.open-only';

  /// Shop, car wash, air, WC — filters that reduce the list, not the price.
  static const searchAmenities = 'search.criteria.amenities';

  /// Whether motorway stations count, and why they usually should not.
  static const searchHighway = 'search.criteria.highway';

  /// Saving the criteria as the defaults every later search starts from.
  static const searchDefaults = 'search.criteria.defaults';

  /// Every anchor the app points at — the lint's left-hand side.
  static const all = <String>{
    searchButton,
    searchMode,
    searchFuelType,
    searchRadius,
    searchOpenOnly,
    searchAmenities,
    searchHighway,
    searchDefaults,
  };

  /// The screenshot that documents [anchor], by the naming rule.
  static String imageFor(String anchor) => '${anchor.replaceAll('.', '-')}.jpg';
}
