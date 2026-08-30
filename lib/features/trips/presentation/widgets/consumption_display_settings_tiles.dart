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
///
/// #3889 — a value + chevron tile that opens a bottom-sheet radio picker:
/// a trailing dropdown wide enough for "Automatic (L/100 km)" squeezed
/// the title into a four-line column.
class ConsumptionUnitSettingTile extends ConsumerWidget {
  const ConsumptionUnitSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final display = ref.watch(consumptionDisplaySettingProvider);
    final autoUnit = const ConsumptionDisplay().unit;
    final current = display.unitOverride;
    return _PickerTile<ConsumptionUnit?>(
      tileKey: const Key('consumptionUnitTile'),
      icon: Icons.local_gas_station_outlined,
      title: l.consumptionUnitSettingTitle,
      subtitle: l.consumptionUnitSettingSubtitle,
      valueLabel: current == null ? l.consumptionUnitAuto(autoUnit.mask) : current.mask,
      value: current,
      options: [
        (null, l.consumptionUnitAuto(autoUnit.mask)),
        for (final u in ConsumptionUnit.values) (u, u.mask),
      ],
      onPicked: (u) => unawaited(
          ref.read(consumptionDisplaySettingProvider.notifier).setUnit(u)),
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
    final display = ref.watch(consumptionDisplaySettingProvider);
    return _PickerTile<int>(
      tileKey: const Key('settingsLiveConsumptionTile'),
      icon: Icons.timer_outlined,
      title: l.consumptionWindowSettingTitle,
      subtitle: l.consumptionWindowSettingSubtitle,
      valueLabel: l.consumptionWindowOption(display.windowSeconds),
      value: display.windowSeconds,
      options: [
        for (final s in kLiveConsumptionWindowChoices)
          (s, l.consumptionWindowOption(s)),
      ],
      onPicked: (s) => unawaited(ref
          .read(consumptionDisplaySettingProvider.notifier)
          .setWindowSeconds(s)),
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

/// A settings row showing the current value; tapping opens a modal
/// bottom sheet with one radio row per option (#3889).
class _PickerTile<T> extends StatelessWidget {
  const _PickerTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.value,
    required this.options,
    required this.onPicked,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String valueLabel;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onPicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: tileKey,
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valueLabel, style: theme.textTheme.titleSmall),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _openSheet(context),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<(T,)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: RadioGroup<T>(
          groupValue: value,
          onChanged: (v) => Navigator.of(ctx).pop((v as T,)),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              for (final (opt, label) in options)
                RadioListTile<T>(
                  key: ValueKey('consumption_picker_$opt'),
                  value: opt,
                  title: Text(label),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onPicked(picked.$1);
  }
}
