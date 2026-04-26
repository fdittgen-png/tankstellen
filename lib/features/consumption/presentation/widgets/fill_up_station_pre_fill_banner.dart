import 'package:flutter/material.dart';

/// Small banner above the form cards announcing the pre-filled
/// station (#581 affordance restyled for #751 phase 2). Replaces the
/// old ListTile card so the callout is visible above the fold without
/// stealing visual weight from the "What you filled" card.
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// screen file drops well below 300 LOC.
class FillUpStationPreFillBanner extends StatelessWidget {
  final String stationName;
  final String label;

  const FillUpStationPreFillBanner({
    super.key,
    required this.stationName,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.place_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              container: true,
              label: '$label: $stationName',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      stationName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
