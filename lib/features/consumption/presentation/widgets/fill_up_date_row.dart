import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Tappable "Date" row on the Add-Fill-Up form.
///
/// Displays a calendar icon, the localised "Date" label, and the
/// currently-selected date as the subtitle. Tapping opens the date
/// picker (handler owned by the parent screen, passed in via
/// [onTap]) — keeping the picker logic with the rest of the form
/// state machine instead of mirroring it in the widget.
///
/// Pulled out of `add_fill_up_screen.dart` (#727) so the screen's
/// `build` method drops a six-line inline block and the row can be
/// rendered in isolation by widget tests.
class FillUpDateRow extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onTap;

  const FillUpDateRow({
    super.key,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: Text(l?.fillUpDate ?? 'Date'),
      subtitle: Text(dateLabel),
      onTap: onTap,
    );
  }
}
