import 'package:flutter/material.dart';

import '../../../../core/widgets/shimmer_placeholder.dart';

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
    )..repeat(reverse: true);
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

    return Column(
      children: [
        // Reassuring header with pulsing icon
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      child: const Text('Updating your favorites...'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fetching the latest prices',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Animated progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(minHeight: 3),
          ),
        ),
        const SizedBox(height: 16),
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
