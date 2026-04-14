import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';

/// Dropdown for picking the user's preferred [LandingScreen] (the screen
/// that opens when the app is launched). Filters out [LandingScreen.map]
/// because the map is not a valid landing destination, and labels every
/// option using [LandingScreen.localizedName] in the active locale.
///
/// Pulled out of `profile_edit_sheet.dart` so the sheet's `build` method
/// drops 20 lines and so the filter + localization can be exercised by
/// widget tests in isolation.
class ProfileLandingScreenDropdown extends StatelessWidget {
  final LandingScreen value;
  final ValueChanged<LandingScreen> onChanged;

  const ProfileLandingScreenDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return DropdownButtonFormField<LandingScreen>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n?.landingScreen ?? 'Start screen',
        border: const OutlineInputBorder(),
      ),
      items: LandingScreen.values
          .where((s) => s != LandingScreen.map)
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.localizedName(languageCode)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
