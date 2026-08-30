// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/consumption_unit.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// #3883 — the app-wide consumption unit: automatic (the country
/// convention) or an explicit L/100 km, km/L, mpg (US), mpg (UK).
/// Home: Settings › Units & display (#3884: one home per parameter).
class ConsumptionUnitSettingTile extends ConsumerWidget {
  const ConsumptionUnitSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final display = ref.watch(consumptionDisplaySettingProvider);
    final notifier = ref.read(consumptionDisplaySettingProvider.notifier);
    final autoUnit = const ConsumptionDisplay().unit;
    return ListTile(
      key: const Key('consumptionUnitTile'),
      leading: const Icon(Icons.local_gas_station_outlined, size: 20),
      title: Text(l.consumptionUnitSettingTitle),
      subtitle:
          Text(l.consumptionUnitSettingSubtitle, style: theme.textTheme.bodySmall),
      trailing: DropdownButton<ConsumptionUnit?>(
        key: const Key('consumptionUnitDropdown'),
        value: display.unitOverride,
        underline: const SizedBox.shrink(),
        onChanged: (u) => unawaited(notifier.setUnit(u)),
        items: [
          DropdownMenuItem<ConsumptionUnit?>(
            value: null,
            child: Text(l.consumptionUnitAuto(autoUnit.mask)),
          ),
          for (final u in ConsumptionUnit.values)
            DropdownMenuItem<ConsumptionUnit?>(value: u, child: Text(u.mask)),
        ],
      ),
    );
  }
}

/// #3883 — the rolling window of the live "Last N s" consumption figure
/// on the recording screen. Home: Settings › Driving & consumption.
class LiveConsumptionWindowSettingTile extends ConsumerWidget {
  const LiveConsumptionWindowSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final display = ref.watch(consumptionDisplaySettingProvider);
    final notifier = ref.read(consumptionDisplaySettingProvider.notifier);
    return ListTile(
      key: const Key('settingsLiveConsumptionTile'),
      leading: const Icon(Icons.timer_outlined, size: 20),
      title: Text(l.consumptionWindowSettingTitle),
      subtitle: Text(l.consumptionWindowSettingSubtitle,
          style: theme.textTheme.bodySmall),
      trailing: DropdownButton<int>(
        key: const Key('consumptionWindowDropdown'),
        value: display.windowSeconds,
        underline: const SizedBox.shrink(),
        onChanged: (s) {
          if (s != null) unawaited(notifier.setWindowSeconds(s));
        },
        items: [
          for (final s in kLiveConsumptionWindowChoices)
            DropdownMenuItem<int>(
                value: s, child: Text(l.consumptionWindowOption(s))),
        ],
      ),
    );
  }
}

/// Both tiles together — the pre-#3884 flat settings layout.
class ConsumptionDisplaySettingsTiles extends StatelessWidget {
  const ConsumptionDisplaySettingsTiles({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConsumptionUnitSettingTile(),
          LiveConsumptionWindowSettingTile(),
        ],
      );
}
