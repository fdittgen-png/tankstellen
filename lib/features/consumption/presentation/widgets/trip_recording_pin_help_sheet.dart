import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Modal bottom sheet explaining what the "pin" toggle on the
/// [TripRecordingScreen] actually does (#1273).
///
/// Mirrors [VinInfoSheet]'s shape: a single titled section with a
/// trailing dismiss button. The pin button itself is documented only
/// by an icon and a short tooltip — first-time users have no clue
/// the behaviour involves wakelock + immersive mode + auto-release,
/// hence this short explainer next to the toggle.
class TripRecordingPinHelpSheet extends StatelessWidget {
  const TripRecordingPinHelpSheet({super.key});

  /// Launch the help sheet. Returns once the user dismisses it.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const TripRecordingPinHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Cap the height so the body scrolls instead of pushing the
    // dismiss button off-screen on small phones.
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.push_pin_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l?.tripRecordingPinHelpTitle ?? 'About the pin button',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l?.tripRecordingPinHelpBody ??
                    'Pin keeps the screen on and hides system bars so '
                        'the form stays readable on a dashboard mount. '
                        'Tap again to release. Auto-releases when the '
                        'trip stops.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l?.tripRecordingPinHelpDismiss ?? 'Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
