// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../features/itinerary/presentation/screens/itineraries_screen.dart';
import '../../features/loyalty/presentation/loyalty_settings_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/developer_tools_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/error_log_viewer_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/feature_flag_dump_screen.dart';
import '../../features/profile/presentation/screens/privacy_dashboard_screen.dart';
import '../../features/profile/presentation/screens/theme_settings_screen.dart';
import '../../features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import '../../features/vehicle/presentation/screens/vehicle_list_screen.dart';

/// Profile/settings sub-screens that push on top of the Profile shell branch:
/// vehicle list and editor, saved itineraries, privacy dashboard, theme
/// settings (#897), loyalty/fuel-club discount cards (#1120), and the
/// Developer / Debug tools (#2248). The Developer-tools screens self-guard
/// on `Feature.debugMode` so a stale deep-link cannot expose them.
List<RouteBase> get profileRoutes => [
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleListScreen(),
      ),
      GoRoute(
        path: '/vehicles/edit',
        builder: (context, state) {
          final extra = state.extra;
          final vehicleId = extra is String ? extra : null;
          return EditVehicleScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/itineraries',
        builder: (context, state) => const ItinerariesScreen(),
      ),
      GoRoute(
        path: '/privacy-dashboard',
        builder: (context, state) => const PrivacyDashboardScreen(),
      ),
      // #897 — dedicated Theme settings screen, pushed from the
      // Theme card on the profile/settings screen. Extracted from
      // the inline bottom sheet so the Theme entry matches the
      // Privacy + Storage card pattern.
      GoRoute(
        path: '/theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      // #1120 — fuel-club / loyalty discount settings. Pilot ships
      // with one brand (Total Energies); the screen lists, adds,
      // toggles, and deletes user-entered cards.
      GoRoute(
        path: '/loyalty-settings',
        builder: (context, state) => const LoyaltySettingsScreen(),
      ),
      // #2248 — Developer / Debug tools. Reached from the Settings tile
      // that only renders when `Feature.debugMode` is on; the screens
      // also self-guard on the flag so a stale deep-link is inert.
      GoRoute(
        path: '/developer-tools',
        builder: (context, state) => const DeveloperToolsScreen(),
      ),
      GoRoute(
        path: '/developer-tools/error-log',
        builder: (context, state) => const ErrorLogViewerScreen(),
      ),
      GoRoute(
        path: '/developer-tools/flags',
        builder: (context, state) => const FeatureFlagDumpScreen(),
      ),
    ];
