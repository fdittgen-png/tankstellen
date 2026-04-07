import 'package:flutter/material.dart';
import '../../../../core/theme/dark_mode_colors.dart';

/// A small badge widget shown on StationCard when there are
/// recent community price reports.
class CommunityBadge extends StatelessWidget {
  final int reportCount;
  const CommunityBadge({super.key, required this.reportCount});

  @override
  Widget build(BuildContext context) {
    if (reportCount == 0) return const SizedBox.shrink();
    final fg = DarkModeColors.success(context);
    final bg = DarkModeColors.successSurface(context);
    return Tooltip(
      message: '$reportCount community price reports in the last 2 hours',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, size: 12, color: fg),
            const SizedBox(width: 2),
            Text(
              '$reportCount',
              style: TextStyle(
                fontSize: 10,
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
