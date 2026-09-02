// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/consumption_unit.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fill_inventory.dart';
import '../../domain/services/pump_gain_learner.dart';
import '../../domain/services/tank_level_estimator.dart';
import '../../providers/tank_level_provider.dart';
import 'localized_fuel_name.dart';

/// Show the "Bilan du plein" (#3917) after a FULL fill was saved: the
/// inventory the tank window established and the calibration outcome
/// (or the reason it was skipped). Resolves when dismissed.
Future<void> showFillInventorySheet(
  BuildContext context,
  FillInventory inventory,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FillInventorySheet(inventory: inventory),
    );

/// Bottom-sheet host of [FillInventoryContent] with a dismiss button.
class FillInventorySheet extends StatelessWidget {
  const FillInventorySheet({super.key, required this.inventory});

  final FillInventory inventory;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FillInventoryContent(
              key: const Key('fillInventorySheetContent'),
              inventory: inventory,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('fillInventoryDismiss'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.fillInventoryDismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// The inventory lines (#3917) — shared by the post-save sheet and the
/// Carburant-tab card. Reads the consumption unit and the live tank
/// level itself; the pure rendering is [FillInventoryLines].
class FillInventoryContent extends ConsumerWidget {
  const FillInventoryContent({super.key, required this.inventory});

  final FillInventory inventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shell-safety (#2163 idiom): an unwired unit / tank-level graph in
    // a test scope must degrade to "no tank line", never crash the tab.
    final unit = guard(
      () => ref.watch(consumptionDisplaySettingProvider).unit,
      where: 'FillInventoryContent: unit watch failed',
      fallback: ConsumptionUnit.lPer100Km,
    );
    final tank = guard(
      () => inventory.vehicleId.isEmpty
          ? null
          : ref.watch(tankLevelProvider(inventory.vehicleId)),
      where: 'FillInventoryContent: tank level watch failed',
      fallback: null as TankLevelEstimate?,
    );
    return FillInventoryLines(
      inventory: inventory,
      unit: unit,
      tankLevelL: (tank != null && tank.hasFillUp) ? tank.levelL : null,
      tankRangeKm: tank?.rangeKm,
    );
  }
}

/// Provider-free rendering of one [FillInventory].
class FillInventoryLines extends StatelessWidget {
  const FillInventoryLines({
    super.key,
    required this.inventory,
    required this.unit,
    this.tankLevelL,
    this.tankRangeKm,
  });

  final FillInventory inventory;
  final ConsumptionUnit unit;

  /// Live tank content, litres; null hides the "tank now" line.
  final double? tankLevelL;

  /// The estimator's own range, used when no pump consumption exists.
  final double? tankRangeKm;

  /// Kilometres the tank content buys at the window's pump consumption.
  static double? rangeAtPumpConsumption(double? levelL, double? pumpLPer100Km) {
    if (levelL == null || pumpLPer100Km == null || pumpLPer100Km <= 0) {
      return null;
    }
    return levelL / pumpLPer100Km * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final inv = inventory;
    final date = UnitFormatter.formatMediumDate(inv.fillDate, locale: locale);
    final fuel = localizedFuelName(l, FuelType.fromString(inv.fuelKey));
    final km = inv.kmSinceLastFull;
    final pump = inv.pumpLPer100Km;
    final raw = inv.rawRecordedLPer100Km;
    final level = tankLevelL;
    final range = rangeAtPumpConsumption(level, pump) ?? tankRangeKm;

    String fmtKm(double v) => UnitFormatter.formatDecimal(v, fractionDigits: 0);
    String fmtL(double v) => UnitFormatter.formatDecimal(v);
    String fmtCons(double v) => UnitFormatter.formatConsumptionLocalized(v, unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.local_gas_station, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.fillInventoryTitle,
                  style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          inv.isFullTank
              ? l.fillInventorySubtitleFull(date, fuel)
              : l.fillInventorySubtitlePartial(date, fuel),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (km != null)
          _Line(
            icon: Icons.straighten,
            text: l.fillInventoryKmSinceLastFull(fmtKm(km)),
          ),
        _Line(
          icon: Icons.water_drop_outlined,
          text: l.fillInventoryPumpLiters(fmtL(inv.pumpLiters)),
        ),
        if (pump != null)
          _Line(
            icon: Icons.local_gas_station_outlined,
            text: l.fillInventoryPumpConsumption(fmtCons(pump)),
            emphasis: true,
          ),
        if (inv.recordedKm > 0 && raw != null)
          _Line(
            icon: Icons.route,
            text: l.fillInventoryRecordedTrips(
              (inv.coverageShare * 100).round(),
              fmtCons(raw),
            ),
          )
        else if (km != null)
          _Line(icon: Icons.route, text: l.fillInventoryNoRecordedTrips),
        if (level != null)
          _Line(
            icon: Icons.opacity,
            text: range != null
                ? l.fillInventoryTankNow(fmtL(level), fmtKm(range))
                : l.fillInventoryTankNowNoRange(fmtL(level)),
          ),
        const SizedBox(height: 8),
        _CalibrationLine(inventory: inv, l: l),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.emphasis = false});

  final IconData icon;
  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: emphasis
                  ? theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// `Calibrage à la pompe : ×0,93 → ×0,72 (−22 %)` or the skip reason.
class _CalibrationLine extends StatelessWidget {
  const _CalibrationLine({required this.inventory, required this.l});

  final FillInventory inventory;
  final AppLocalizations l;

  static String skipReasonText(
    AppLocalizations l,
    FillInventory inv,
    PumpGainSkipReason reason,
  ) =>
      switch (reason) {
        PumpGainSkipReason.notFullTank => l.fillInventorySkipNotFullTank,
        PumpGainSkipReason.correction => l.fillInventorySkipCorrection,
        PumpGainSkipReason.noVehicle => l.fillInventorySkipNoVehicle,
        PumpGainSkipReason.noWindow => l.fillInventorySkipNoWindow,
        PumpGainSkipReason.coverageTooLow => l.fillInventorySkipCoverageTooLow(
            (inv.coverageShare * 100).round()),
        PumpGainSkipReason.recordedTooShort =>
          l.fillInventorySkipRecordedTooShort(
              UnitFormatter.formatDecimal(inv.recordedKm, fractionDigits: 0)),
        PumpGainSkipReason.noRecordedFuel => l.fillInventorySkipNoRecordedFuel,
        PumpGainSkipReason.implausibleTarget =>
          l.fillInventorySkipImplausible,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inv = inventory;
    final String text;
    final bool calibrated = inv.calibrated;
    if (calibrated) {
      final pct = inv.changePercent ?? 0;
      text = l.fillInventoryCalibrationApplied(
        UnitFormatter.formatDecimal(inv.previousGain!, fractionDigits: 2),
        UnitFormatter.formatDecimal(inv.newGain!, fractionDigits: 2),
        pct > 0 ? '+$pct' : '$pct',
      );
    } else {
      final reason = inv.skipReason;
      text = l.fillInventoryCalibrationSkipped(
        reason == null ? '' : skipReasonText(l, inv, reason),
      );
    }
    return Container(
      key: const Key('fillInventoryCalibrationLine'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: calibrated
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          Icon(
            calibrated ? Icons.tune : Icons.info_outline,
            size: 16,
            color: calibrated ? scheme.onPrimaryContainer : scheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: calibrated
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
