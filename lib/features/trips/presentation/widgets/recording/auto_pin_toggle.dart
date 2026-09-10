// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../providers/recording_profile_provider.dart';

/// #2274 concern 1 — the "always pin when recording starts" opt-in in
/// the pin-help bottom sheet. Watches the global [RecordingProfile] so
/// the switch reflects the persisted preference and updates live when
/// flipped. Off by default — preserving the opt-in-each-drive design.
class AutoPinToggle extends ConsumerWidget {
  const AutoPinToggle({super.key, required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final autoPin = ref.watch(recordingProfileControllerProvider).autoPin;
    return SwitchListTile(
      key: const Key('tripRecordingAutoPinToggle'),
      contentPadding: EdgeInsets.zero,
      value: autoPin,
      onChanged: onChanged,
      title: Text(l.tripRecordingAutoPinTitle),
      subtitle: Text(l.tripRecordingAutoPinSubtitle),
    );
  }
}
