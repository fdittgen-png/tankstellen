import 'package:flutter/material.dart';

/// Reusable swipe-to-delete wrapper with red background and delete icon.
///
/// Replaces 2 identical Dismissible implementations in AlertsScreen
/// and FavoritesScreen.
class SwipeToDelete extends StatelessWidget {
  final Key dismissKey;
  final VoidCallback onDismissed;
  final Widget child;

  const SwipeToDelete({
    super.key,
    required this.dismissKey,
    required this.onDismissed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }
}
