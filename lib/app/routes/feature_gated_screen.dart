// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/feature_management/application/feature_flags_provider.dart';
import '../../features/feature_management/domain/feature.dart';

/// Route-level feature guard — the #1613 `Feature.carbonDashboard`
/// precedent (consumption_routes.dart) as ONE reusable widget instead
/// of a re-copied inline Consumer per gated route.
///
/// Guarding the route (not just the entry-point button) means a deep
/// link or restored navigation stack cannot reach the screen when the
/// feature is disabled: the frame after build, the user is redirected
/// to [fallbackPath].
class FeatureGatedScreen extends ConsumerWidget {
  final Feature feature;

  /// Where a disabled deep link lands (typically the shell tab the
  /// gated screen is normally entered from).
  final String fallbackPath;

  final Widget child;

  const FeatureGatedScreen({
    super.key,
    required this.feature,
    required this.fallbackPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(enabledFeaturesProvider).contains(feature);
    if (!enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(fallbackPath);
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}
