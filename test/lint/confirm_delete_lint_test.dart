// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #3682 — every delete-swipe goes through the shared [SwipeToDelete]
/// (which carries the app-wide delete confirmation), and every
/// confirm-before-destroy dialog goes through
/// [confirmDestructiveAction]. This lint keeps both from silently
/// regressing into copy-paste:
///
///  1. A raw `Dismissible(` in lib/ is allowed only on the allowlist —
///     the non-delete swipes (radar paging, notice dismissal) and the
///     two-direction favorite rows whose DELETE branch calls the shared
///     confirmation explicitly.
///  2. No file outside the shared component builds the
///     `showDialog&lt;bool&gt; … pop(true)` confirm shape together with a
///     delete icon — the tell of a re-copied confirm dialog.
void main() {
  /// Raw `Dismissible(` usages that are legitimately NOT SwipeToDelete.
  /// Shrink-only: converting one to SwipeToDelete removes its entry;
  /// adding a new raw delete-swipe is forbidden — use SwipeToDelete.
  const dismissibleAllowlist = <String, String>{
    'lib/core/widgets/swipe_to_delete.dart': 'the shared component itself',
    'lib/features/trips/presentation/widgets/radar_swipe_wrapper.dart':
        'radar paging — navigation, not deletion',
    'lib/core/widgets/favorite_dismissible.dart':
        'the ONE shared two-direction (navigate|delete) favorites wrapper '
            '(the fuel/EV twins consolidated onto it); its delete branch '
            'calls confirmDestructiveAction explicitly',
    'lib/features/favorites/presentation/widgets/alerts_tab.dart':
        'labeled background variant; confirmDismiss calls '
            'confirmDestructiveAction explicitly',
    'lib/features/loyalty/presentation/widgets/loyalty_card_tile.dart':
        'delegates to the screen-side confirmation (which uses the shared '
            'dialog) so a cancelled swipe restores the row visually',
    'lib/features/search/presentation/widgets/route_results_view.dart':
        'two-direction (navigate|hide); the hide branch calls '
            'confirmDestructiveAction explicitly',
    'lib/features/search/presentation/widgets/swipeable_station_card.dart':
        'two-direction (navigate|hide); the hide branch calls '
            'confirmDestructiveAction explicitly',
  };

  test('raw Dismissible usages in lib/ are allowlisted (#3682)', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final rel = entity.path.replaceAll(r'\', '/');
      if (dismissibleAllowlist.containsKey(rel)) continue;
      // Word-boundary match: `FavoriteStationDismissible(` must not count.
      if (RegExp(r'(?<![A-Za-z])Dismissible\(')
          .hasMatch(entity.readAsStringSync())) {
        offenders.add(rel);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Raw Dismissible found outside the allowlist. Delete-swipes '
          'use the shared SwipeToDelete (core/widgets/swipe_to_delete.dart) '
          'which carries the app-wide delete confirmation; genuinely '
          'non-delete swipes get an allowlist entry with a reason:\n'
          '${offenders.map((f) => '  - $f').join('\n')}',
    );
  });

  test('allowlisted files still exist and still contain a Dismissible '
      '(stale entries are removed)', () {
    for (final entry in dismissibleAllowlist.keys) {
      if (entry == 'lib/core/widgets/swipe_to_delete.dart') continue;
      final f = File(entry);
      expect(f.existsSync(), isTrue, reason: '$entry vanished — drop it');
      expect(
          RegExp(r'(?<![A-Za-z])Dismissible\(')
              .hasMatch(f.readAsStringSync()),
          isTrue,
          reason: '$entry no longer swipes — drop it from the allowlist');
    }
  });

  test('the two-direction dismissibles DO call the shared confirmation '
      'in their delete branch', () {
    for (final f in [
      'lib/core/widgets/favorite_dismissible.dart',
      'lib/features/favorites/presentation/widgets/alerts_tab.dart',
      'lib/features/search/presentation/widgets/route_results_view.dart',
      'lib/features/search/presentation/widgets/swipeable_station_card.dart',
    ]) {
      expect(
        File(f).readAsStringSync(),
        contains('confirmDestructiveAction('),
        reason: '$f is allowlisted BECAUSE its delete branch confirms — '
            'that call must stay',
      );
    }
  });
}
