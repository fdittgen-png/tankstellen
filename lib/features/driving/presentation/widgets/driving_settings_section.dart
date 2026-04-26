import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/haptic_eco_coach_provider.dart';

/// Driving (wheel-lens) settings section on the profile screen
/// (#1122).
///
/// Currently surfaces the single real-time eco-coaching toggle. The
/// section is its own widget so future wheel-lens toggles
/// (auto-pause-on-drop, voice nudges, etc.) can be added here without
/// growing `profile_screen.dart` further.
///
/// Default of the toggle is **off** — `HapticEcoCoachEnabled` reads
/// the persisted Hive setting, which is null for first-launch users
/// and only flips to true after an explicit tap on this switch.
class DrivingSettingsSection extends ConsumerWidget {
  const DrivingSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final enabled = ref.watch(hapticEcoCoachEnabledProvider);

    return SwitchListTile(
      key: const Key('hapticEcoCoachToggle'),
      value: enabled,
      title: Text(
        l?.hapticEcoCoachSettingTitle ?? 'Real-time eco coaching',
      ),
      subtitle: Text(
        l?.hapticEcoCoachSettingSubtitle ??
            'Gentle haptic when you floor it during cruise',
        style: theme.textTheme.bodySmall,
      ),
      onChanged: (v) =>
          ref.read(hapticEcoCoachEnabledProvider.notifier).set(v),
      contentPadding: EdgeInsets.zero,
    );
  }
}
