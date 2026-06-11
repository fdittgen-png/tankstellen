// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/radar_pin_provider.dart';

/// #2785 — bottom sheet explaining the fuel-station-radar pin and hosting the
/// persisted "always pin when the radar starts" opt-out toggle. Mirrors the
/// trip-recording pin-help sheet; opened by long-pressing the radar pin.
///
/// [onEnableNow] pins THIS live screen immediately when the toggle is flipped
/// ON, so the effect is visible without waiting for the next radar start.
void showRadarPinHelp(
  BuildContext context, {
  required Future<void> Function() onEnableNow,
}) {
  final l = AppLocalizations.of(context);
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.push_pin, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.radarPinHelpTitle,
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l.radarPinHelpBody),
                const SizedBox(height: 8),
                // Reactive so the switch reflects the persisted preference.
                Consumer(
                  builder: (context, ref, _) {
                    final autoPin = ref.watch(radarAutoPinProvider);
                    return SwitchListTile(
                      key: const Key('radarAutoPinToggle'),
                      contentPadding: EdgeInsets.zero,
                      value: autoPin,
                      onChanged: (value) async {
                        await ref
                            .read(radarAutoPinProvider.notifier)
                            .set(value);
                        if (value) await onEnableNow();
                      },
                      title: Text(l.radarAutoPinTitle),
                      subtitle: Text(l.radarAutoPinSubtitle),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l.tooltipBack),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
