import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/star_rating.dart';
import '../../../search/providers/station_rating_provider.dart';

/// User rating section showing interactive star rating for a station.
class StationRatingSection extends StatelessWidget {
  final String stationId;

  const StationRatingSection({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your rating', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Consumer(builder: (context, ref, _) {
          final rating = ref.watch(stationRatingProvider(stationId));
          return Row(
            children: [
              StarRating(
                rating: rating,
                onRatingChanged: (stars) {
                  ref.read(stationRatingsProvider.notifier).rate(stationId, stars);
                },
              ),
              if (rating != null) ...[
                const SizedBox(width: 12),
                Text('$rating/5', style: theme.textTheme.bodyMedium),
              ],
            ],
          );
        }),
      ],
    );
  }
}
