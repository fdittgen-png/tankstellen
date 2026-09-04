// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';

/// Professional loading view with shimmer skeleton + pulsing fuel icon + reassuring text.
///
/// Shown while favorites are loading after app start, auth transitions,
/// or when station data hasn't been cached yet.
class FavoritesLoadingView extends StatefulWidget {
  const FavoritesLoadingView({super.key});

  @override
  State<FavoritesLoadingView> createState() => _FavoritesLoadingViewState();
}

class _FavoritesLoadingViewState extends State<FavoritesLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        // Reassuring header with pulsing icon
        Padding(
          // #3951 — spacing off the Spacing scale, text off the AppText roles.
          padding: const EdgeInsets.fromLTRB(
            Spacing.xxl,
            Spacing.xxxl,
            Spacing.xxl,
            Spacing.xl,
          ),
          child: Row(
            children: [
              FadeTransition(
                opacity: _pulseAnimation,
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: AppText.title(context),
                      child: Text(l.updatingFavorites),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      l.fetchingLatestPrices,
                      style: AppText.label(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Animated progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
          child: ClipRRect(
            borderRadius: AppRadius.sm,
            child: const LinearProgressIndicator(minHeight: 3),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        // Shimmer skeleton cards
        const Expanded(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: ShimmerStationList(count: 6),
          ),
        ),
      ],
    );
  }
}
