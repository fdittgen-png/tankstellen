import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Submit button for [RouteInput].
///
/// Listens to the start/end text controllers so it enables as the user types
/// without forcing a parent rebuild, and renders a progress spinner while a
/// route resolution is in flight.
class RouteSearchButton extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final bool isSearching;
  final VoidCallback onSearch;

  const RouteSearchButton({
    super.key,
    required this.startController,
    required this.endController,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([startController, endController]),
      builder: (context, _) {
        final canSearch = startController.text.isNotEmpty &&
            endController.text.isNotEmpty &&
            !isSearching;
        return FilledButton.icon(
          onPressed: canSearch ? onSearch : null,
          icon: isSearching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.route),
          label: Text(l10n?.searchAlongRoute ?? 'Search along route'),
        );
      },
    );
  }
}
