import 'package:flutter/material.dart';

/// Determines if the screen is wide enough for split layout.
/// Threshold: 600dp (typical tablet/landscape breakpoint).
bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600;

/// Split layout: search on left, map on right.
/// Falls back to single-column on narrow screens.
class ResponsiveSearchLayout extends StatelessWidget {
  final Widget searchPanel;
  final Widget mapPanel;

  const ResponsiveSearchLayout({
    super.key,
    required this.searchPanel,
    required this.mapPanel,
  });

  @override
  Widget build(BuildContext context) {
    if (isWideScreen(context)) {
      return Row(
        children: [
          Expanded(flex: 1, child: searchPanel),
          const VerticalDivider(width: 1),
          Expanded(flex: 1, child: mapPanel),
        ],
      );
    }
    // Narrow screen: just show search (map via bottom nav tab)
    return searchPanel;
  }
}
