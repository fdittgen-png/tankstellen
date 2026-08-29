// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// #3867 (Epic #3865) — wipe the home-screen widget's shared container.
///
/// The widget reads its station list and the user's last position from a
/// platform container (`SharedPreferences` / App Group) outside the Hive
/// boxes, so "Delete all data" has to clear it explicitly. Every key the
/// widget writers use is listed here; the drift guard in
/// `test/features/widget/home_widget_eraser_test.dart` scans the writers.
const List<String> kHomeWidgetDataKeys = [
  'station_count',
  'stations_json',
  'nearest_count',
  'nearest_empty_reason',
  'nearest_is_stale',
  'nearest_json',
  'nearest_lat',
  'nearest_lng',
  'nearest_updated_at',
  'updated_at',
  'widget_profiles_json',
  'default_color',
  'default_variant',
];

/// Clears every widget data key and asks the launcher to repaint. Never
/// throws — a missing widget host (tests, F-Droid without the widget)
/// must not block the erasure.
Future<void> clearHomeWidgetData() async {
  try {
    for (final key in kHomeWidgetDataKeys) {
      await HomeWidget.saveWidgetData<String?>(key, null);
    }
    await HomeWidget.updateWidget(name: 'FuelPriceWidgetProvider');
  } catch (e, st) {
    debugPrint('clearHomeWidgetData: $e\n$st');
  }
}
