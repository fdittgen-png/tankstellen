// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'ratchet_baseline.dart';

import 'package:flutter_test/flutter_test.dart';

/// Guards the canonical-radius-token mandate
/// (`docs/design/DESIGN_SYSTEM.md`, "Radius scale").
///
/// Scans **all of `lib/`** for an inline corner radius that should instead
/// route through the `AppRadius` tokens in
/// `lib/core/theme/app_radius.dart`:
///
///   * `BorderRadius.circular(<n>)`
///   * a standalone `Radius.circular(<n>)`
///
/// Both forms are matched by the single substring `Radius.circular(` — a
/// `BorderRadius.circular(` line contains it too, so one regex covers the
/// pair. The token file [_radiusTokenFile] is the one place these calls
/// are allowed (it *defines* the helpers), so it is exempt.
///
/// ## Baseline
///
/// [_baseline] is the count of pre-existing inline radii (everything
/// outside the token file). Mirroring `no_hardcoded_ui_strings_test.dart`
/// and HARD RULE #1's pattern, it may only ever **decrease** — the target
/// is **0**. Never raise it. As callers migrate to `AppRadius.sm/md/lg/
/// xl/xxl`, drop the baseline to match.
void main() {
  // Matches both `BorderRadius.circular(` and a bare `Radius.circular(`.
  final inlineRadius = RegExp(r'Radius\.circular\(');

  // The token definition file — the sole legitimate home for
  // `BorderRadius.circular(...)`, since it wraps the raw calls behind the
  // `AppRadius.*` getters that the rest of the app should use instead.
  const radiusTokenFile = _radiusTokenFile;

  test('no new inline BorderRadius/Radius.circular (use AppRadius tokens)',
      () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart')) continue;
      if (path.endsWith('.freezed.dart')) continue;
      // Generated localization output is not source.
      if (path.contains('/l10n/app_localizations')) continue;
      // The token file is allowed to call BorderRadius.circular — it is
      // the canonical wrapper every other widget must reuse.
      if (path == radiusTokenFile) continue;

      final source = entity.readAsStringSync();
      final lineStarts = <int>[0];
      for (var i = 0; i < source.length; i++) {
        if (source[i] == '\n') lineStarts.add(i + 1);
      }
      int lineOf(int offset) {
        var lo = 0, hi = lineStarts.length - 1;
        while (lo < hi) {
          final mid = (lo + hi + 1) >> 1;
          if (lineStarts[mid] <= offset) {
            lo = mid;
          } else {
            hi = mid - 1;
          }
        }
        return lo;
      }

      for (final match in inlineRadius.allMatches(source)) {
        final line = lineOf(match.start) + 1;
        violations.add('$path:$line');
      }
    }

    // #4074 — per FILE, exact in both directions, through the shared
    // ratchet helper. The old growth-only scalar (122) could not lock an
    // improvement in; measured on 2026-09-11 the real count was 84.
    final measured = <String, int>{};
    for (final v in violations) {
      final path = v.substring(0, v.lastIndexOf(':'));
      measured[path] = (measured[path] ?? 0) + 1;
    }
    expectRatchet(
      measured: measured,
      baseline: _baseline,
      what: 'Inline corner radii',
      hint: 'Reuse the canonical tokens in lib/core/theme/app_radius.dart — '
          'e.g. `AppRadius.lg` instead of `BorderRadius.circular(12)`.',
    );
  });
}

/// The one file allowed to call `BorderRadius.circular(...)` — it defines
/// the `AppRadius` tokens everything else must reuse.
const _radiusTokenFile = 'lib/core/theme/app_radius.dart';

/// Inline radii outside the token file, per file (#4074). Driven toward
/// **0** by the Epic #2487 cards/chips children. Exact in both directions:
/// a file may only ever lower its entry, never raise it.
const _baseline = <String, int>{
    'lib/app/widgets/animated_splash.dart': 1,
    'lib/core/feedback/github_issue_reporter/error_reporter.dart': 1,
    'lib/core/services/widgets/freshness_badge.dart': 1,
    'lib/core/widgets/charts/monthly_bar_chart_base.dart': 1,
    'lib/core/widgets/section_card.dart': 1,
    'lib/core/widgets/station_card_shell.dart': 1,
    'lib/features/achievements/presentation/widgets/badge_shelf.dart': 1,
    'lib/features/carbon/presentation/widgets/_speed_bars.dart': 2,
    'lib/features/driving/presentation/widgets/driving_bottom_bar.dart': 2,
    'lib/features/driving/presentation/widgets/driving_station_sheet.dart': 1,
    'lib/features/driving/presentation/widgets/driving_top_bar.dart': 1,
    'lib/features/driving_score/presentation/widgets/coaching_chip.dart': 1,
    'lib/features/driving_score/presentation/widgets/driving_score_card.dart': 1,
    'lib/features/fill_ups/presentation/widgets/fill_up_card.dart': 6,
    'lib/features/fill_ups/presentation/widgets/fuel_type_efficiency_analysis.dart': 1,
    'lib/features/fill_ups/presentation/widgets/fuel_type_efficiency_card.dart': 1,
    'lib/features/fill_ups/presentation/widgets/fuel_type_efficiency_rows.dart': 1,
    'lib/features/fill_ups/presentation/widgets/resolve_gap_banner.dart': 2,
    'lib/features/map/presentation/widgets/cluster_badge.dart': 1,
    'lib/features/map/presentation/widgets/route_station_chip.dart': 1,
    'lib/features/map/presentation/widgets/station_marker.dart': 2,
    'lib/features/obd2/presentation/widgets/obd2_breadcrumb_overlay.dart': 1,
    'lib/features/price_history/presentation/widgets/price_chart.dart': 1,
    'lib/features/profile/presentation/screens/developer_tools/pump_ocr_tester_widgets.dart': 1,
    'lib/features/profile/presentation/widgets/location_section_widget.dart': 1,
    'lib/features/profile/presentation/widgets/storage_bar.dart': 4,
    'lib/features/profile/presentation/widgets/use_mode_section.dart': 2,
    'lib/features/receipts_ocr/presentation/widgets/ocr_trace_steps_panel_rows.dart': 2,
    'lib/features/report/presentation/widgets/no_backend_banner.dart': 1,
    'lib/features/route_search/presentation/widgets/city_autocomplete_field.dart': 1,
    'lib/features/search/presentation/widgets/cross_border_banner.dart': 2,
    'lib/features/search/presentation/widgets/ev_connector_chips.dart': 1,
    'lib/features/search/presentation/widgets/ev_connector_tile.dart': 2,
    'lib/features/search/presentation/widgets/location_input.dart': 1,
    'lib/features/search/presentation/widgets/payment_method_chips.dart': 2,
    'lib/features/search/presentation/widgets/radar_scope_view.dart': 1,
    'lib/features/setup/presentation/widgets/country_status_badge.dart': 1,
    'lib/features/setup/presentation/widgets/illustrations/fuel_pump_illustration.dart': 1,
    'lib/features/setup/presentation/widgets/landing_screen_step.dart': 1,
    'lib/features/setup/presentation/widgets/onboarding_progress_indicator.dart': 1,
    'lib/features/setup/presentation/widgets/preferences_step.dart': 1,
    'lib/features/setup/presentation/widgets/profile_choice_step.dart': 2,
    'lib/features/sync/presentation/widgets/auth_form_error_box.dart': 1,
    'lib/features/sync/presentation/widgets/email_auth_card.dart': 1,
    'lib/features/sync/presentation/widgets/link_device_this_device_card.dart': 1,
    'lib/features/sync/presentation/widgets/qr_scanner_helpers.dart': 1,
    'lib/features/sync/presentation/widgets/qr_scanner_screen.dart': 1,
    'lib/features/sync/presentation/widgets/qr_share_widget.dart': 1,
    'lib/features/sync/presentation/widgets/sync_mode_card.dart': 4,
    'lib/features/sync/presentation/widgets/wizard_option_card.dart': 2,
    'lib/features/trips/presentation/widgets/distance_source_badge.dart': 1,
    'lib/features/trips/presentation/widgets/gps_matrix_maturity_badge.dart': 1,
    'lib/features/trips/presentation/widgets/gps_road_usage_card.dart': 1,
    'lib/features/trips/presentation/widgets/throttle_rpm_histogram_card.dart': 1,
    'lib/features/trips/presentation/widgets/trajet_row.dart': 2,
    'lib/features/trips/presentation/widgets/trip_chart_crosshair.dart': 2,
    'lib/features/trips/presentation/widgets/trip_path_map_card.dart': 1,
    'lib/features/vehicle/presentation/widgets/auto_record_section.dart': 1,
    'lib/features/vehicle/presentation/widgets/vehicle_header.dart': 2,
};
