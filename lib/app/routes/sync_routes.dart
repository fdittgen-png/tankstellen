// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/sync/presentation/screens/auth_screen.dart';
import '../../features/sync/presentation/screens/data_transparency_screen.dart';
import '../../features/sync/presentation/screens/link_device_screen.dart';
import '../../features/sync/presentation/screens/sync_setup_screen.dart';

/// TankSync (cloud-sync) routes — anonymous-auth screen, sync setup wizard,
/// link-a-device flow, and the data-transparency screen. All optional —
/// users who never opt into sync never see them.
List<RouteBase> get syncRoutes => [
      GoRoute(
        path: RoutePaths.syncSetup,
        builder: (context, state) => const SyncSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.linkDevice,
        builder: (context, state) => const LinkDeviceScreen(),
      ),
      GoRoute(
        path: RoutePaths.dataTransparency,
        builder: (context, state) => const DataTransparencyScreen(),
      ),
      GoRoute(
        path: RoutePaths.auth,
        builder: (context, state) => const AuthScreen(),
      ),
    ];
