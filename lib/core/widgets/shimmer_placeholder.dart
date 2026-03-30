import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerStationCard extends StatelessWidget {
  const ShimmerStationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 150, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 10, width: 100, color: Colors.white),
              ],
            )),
            Container(height: 20, width: 60, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class ShimmerStationList extends StatelessWidget {
  final int count;
  const ShimmerStationList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: List.generate(count, (_) => const ShimmerStationCard()));
  }
}

/// A shimmer placeholder for the station detail screen loading state.
class ShimmerStationDetail extends StatelessWidget {
  const ShimmerStationDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white)),
                const SizedBox(width: 8),
                Container(height: 14, width: 60, color: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            // Name
            Container(height: 20, width: 200, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 14, width: 160, color: Colors.white),
            const SizedBox(height: 24),
            // Prices section
            Container(height: 16, width: 80, color: Colors.white),
            const SizedBox(height: 12),
            ...List.generate(
                3,
                (_) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                              width: 24, height: 24, color: Colors.white),
                          const SizedBox(width: 12),
                          Container(
                              height: 14, width: 80, color: Colors.white),
                          const Spacer(),
                          Container(
                              height: 16, width: 60, color: Colors.white),
                        ],
                      ),
                    )),
            const SizedBox(height: 24),
            // Address section
            Container(height: 16, width: 80, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 14, width: 220, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 12, width: 140, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
