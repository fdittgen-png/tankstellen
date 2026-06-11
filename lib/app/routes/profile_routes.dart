// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/itinerary/presentation/screens/itineraries_screen.dart';
import '../../features/loyalty/presentation/loyalty_settings_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/developer_tools_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/error_log_viewer_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/feature_flag_dump_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/obd2_health_screen.dart';
import '../../features/profile/presentation/screens/developer_tools/pump_ocr_tester_screen.dart';
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
        path: RoutePaths.vehicles,
        builder: (context, state) => const VehicleListScreen(),
      ),
      GoRoute(
        path: RoutePaths.editVehicle,
        builder: (context, state) {
          final extra = state.extra;
          final vehicleId = extra is String ? extra : null;
          return EditVehicleScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: RoutePaths.itineraries,
        builder: (context, state) => const ItinerariesScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacyDashboard,
        builder: (context, state) => const PrivacyDashboardScreen(),
      ),
      // #897 — dedicated Theme settings screen, pushed from the
      // Theme card on the profile/settings screen. Extracted from
      // the inline bottom sheet so the Theme entry matches the
      // Privacy + Storage card pattern.
      GoRoute(
        path: RoutePaths.themeSettings,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      // #1120 — fuel-club / loyalty discount settings. Pilot ships
      // with one brand (Total Energies); the screen lists, adds,
      // toggles, and deletes user-entered cards.
      GoRoute(
        path: RoutePaths.loyaltySettings,
        builder: (context, state) => const LoyaltySettingsScreen(),
      ),
      // #2248 — Developer / Debug tools. Reached from the Settings tile
      // that only renders when `Feature.debugMode` is on; the screens
      // also self-guard on the flag so a stale deep-link is inert.
      GoRoute(
        path: RoutePaths.developerTools,
        builder: (context, state) => const DeveloperToolsScreen(),
      ),
      GoRoute(
        path: RoutePaths.developerToolsErrorLog,
        builder: (context, state) => const ErrorLogViewerScreen(),
      ),
      GoRoute(
        path: RoutePaths.developerToolsFlags,
        builder: (context, state) => const FeatureFlagDumpScreen(),
      ),
      // #2471 — OBD2 communication-health diagnostics (Epic #2463 TAIL).
      // Self-guards on `Feature.debugMode` like the rest of the dev tools.
      GoRoute(
        path: RoutePaths.developerToolsObd2Health,
        builder: (context, state) => const Obd2HealthScreen(),
      ),
      // #2518 — in-app OCR tester (Epic #2516 Child 2): runs the pump /
      // receipt pipeline on a chosen image and shows the block overlay +
      // step trace. Self-guards on `Feature.debugMode` like its siblings.
      GoRoute(
        path: RoutePaths.developerToolsOcrTester,
        builder: (context, state) => const PumpOcrTesterScreen(),
      ),
    ];
