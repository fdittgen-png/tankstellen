import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Multi-line "Notes (optional)" text field on the Add-Fill-Up form.
///
/// Larger-than-default area (4–8 lines) per user request in #695 so
/// the field invites a real memo rather than a one-liner. Uses a
/// multiline keyboard and routes `Enter` to insert a newline instead
/// of submitting the form.
///
/// Pulled out of `add_fill_up_screen.dart` (#727) so the screen's
/// `build` method drops a 14-line inline block and the field's
/// behaviour (line limits, keyboard type, newline action) can be
/// verified by widget tests in isolation.
class FillUpNotesField extends StatelessWidget {
  final TextEditingController controller;

  const FillUpNotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l?.notesOptional ?? 'Notes (optional)',
        prefixIcon: const Icon(Icons.edit_note),
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
      minLines: 4,
      maxLines: 8,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}
