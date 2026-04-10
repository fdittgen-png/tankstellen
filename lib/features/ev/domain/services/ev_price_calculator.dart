import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../entities/charging_tariff.dart';

part 'ev_price_calculator.freezed.dart';
part 'ev_price_calculator.g.dart';

/// Detailed breakdown of a single charging session cost.
///
/// All monetary fields are denominated in [currency]. `totalCost` is always
/// the exact sum of the component fields and is never computed with rounding
/// so that UI code can display it without re-summing.
@freezed
abstract class ChargingCostBreakdown with _$ChargingCostBreakdown {
  const ChargingCostBreakdown._();

  const factory ChargingCostBreakdown({
    required double totalCost,
    @Default(0) double energyCost,
    @Default(0) double timeCost,
    @Default(0) double flatFee,
    @Default(0) double parkingCost,
    @Default(0) double blockingCost,
    @Default(0) double kwhDelivered,
    @Default('EUR') String currency,
  }) = _ChargingCostBreakdown;

  factory ChargingCostBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ChargingCostBreakdownFromJson(json);

  /// Effective price per kWh, including every fee. Returns `null` if no
  /// energy was delivered (e.g. pure parking session).
  double? get effectivePricePerKwh =>
      kwhDelivered > 0 ? totalCost / kwhDelivered : null;
}

/// Comparison entry returned by [EvPriceCalculator.compareTariffs].
@freezed
abstract class TariffComparisonEntry with _$TariffComparisonEntry {
  const factory TariffComparisonEntry({
    required String tariffId,
    required double totalCost,
    required String currency,
  }) = _TariffComparisonEntry;

  factory TariffComparisonEntry.fromJson(Map<String, dynamic> json) =>
      _$TariffComparisonEntryFromJson(json);
}

/// Pure utility for deriving session costs from OCPI-style tariffs.
///
/// The calculator is stateless; every method is a static function. It is
/// safe to call from providers, widgets, or background isolates alike.
class EvPriceCalculator {
  const EvPriceCalculator._();

  /// Sum every applicable [TariffComponent] from every [TariffElement] in
  /// [tariff] for the given session metrics.
  ///
  /// Time-based components ([PriceComponentType.time],
  /// [PriceComponentType.blockingTime], [PriceComponentType.parkingTime]) are
  /// stored per-second in OCPI. We interpret the `price` field as cost per
  /// minute here because that is what the UI and the tests in this
  /// codebase already show. `stepSize` is respected for rounding: energy
  /// components use Wh step sizes, time components use second step sizes,
  /// flat components are applied as-is.
  ///
  /// When [tariff] has multiple elements, the first matching element per
  /// component type wins — later elements only contribute component types
  /// that earlier elements did not carry. This mirrors how real providers
  /// express "cheaper at night" as a separate element rather than nested
  /// tiers.
  ///
  /// Missing components simply produce `0` cost — the caller must decide
  /// whether a tariff without any components is usable.
  static ChargingCostBreakdown calculateChargingCost(
    ChargingTariff tariff,
    double kwhDelivered,
    Duration duration, {
    Duration parkingTime = Duration.zero,
    Duration blockingTime = Duration.zero,
    DateTime? startTime,
  }) {
    final kwh = kwhDelivered < 0 ? 0.0 : kwhDelivered;
    final minutes = duration.inSeconds < 0 ? 0.0 : duration.inSeconds / 60.0;
    final parkingMinutes = parkingTime.inSeconds < 0
        ? 0.0
        : parkingTime.inSeconds / 60.0;
    final blockingMinutes = blockingTime.inSeconds < 0
        ? 0.0
        : blockingTime.inSeconds / 60.0;

    double energyCost = 0;
    double timeCost = 0;
    double flatFee = 0;
    double parkingCost = 0;
    double blockingCost = 0;
    final seenTypes = <PriceComponentType>{};

    for (final element in tariff.elements) {
      if (!_restrictionApplies(element.restrictions, startTime, kwh)) {
        continue;
      }
      for (final component in element.priceComponents) {
        if (seenTypes.contains(component.type)) continue;
        seenTypes.add(component.type);
        switch (component.type) {
          case PriceComponentType.energy:
            energyCost += _energyCostFor(component, kwh);
            break;
          case PriceComponentType.flat:
            flatFee += component.price;
            break;
          case PriceComponentType.time:
            timeCost += _timeCostFor(component, minutes);
            break;
          case PriceComponentType.parkingTime:
            parkingCost += _timeCostFor(component, parkingMinutes);
            break;
          case PriceComponentType.blockingTime:
            blockingCost += _timeCostFor(component, blockingMinutes);
            break;
        }
      }
    }

    final total =
        energyCost + timeCost + flatFee + parkingCost + blockingCost;

    return ChargingCostBreakdown(
      totalCost: total,
      energyCost: energyCost,
      timeCost: timeCost,
      flatFee: flatFee,
      parkingCost: parkingCost,
      blockingCost: blockingCost,
      kwhDelivered: kwh,
      currency: tariff.currency,
    );
  }

  /// Estimate the cost of charging [vehicle] from [startSoc] to [targetSoc]
  /// (both in percent, 0-100). Uses the vehicle's [VehicleProfile.batteryKwh]
  /// and the vehicle's [VehicleProfile.maxChargingKw] to derive duration.
  ///
  /// Returns `null` when the vehicle profile is missing battery information
  /// or when [targetSoc] is not greater than [startSoc].
  static ChargingCostBreakdown? estimateChargeCost(
    ChargingTariff tariff,
    VehicleProfile vehicle, {
    required double startSoc,
    required double targetSoc,
    DateTime? startTime,
  }) {
    final battery = vehicle.batteryKwh;
    if (battery == null || battery <= 0) return null;
    if (targetSoc <= startSoc) return null;

    final clampedStart = startSoc.clamp(0.0, 100.0);
    final clampedTarget = targetSoc.clamp(0.0, 100.0);
    final kwh = battery * (clampedTarget - clampedStart) / 100.0;

    // Rough duration estimate: assume the vehicle charges at 70% of its
    // rated max to account for tapering above ~80% SoC. When max power is
    // unknown, assume a conservative 11 kW AC rate.
    final ratedKw = (vehicle.maxChargingKw ?? 11).toDouble();
    final effectiveKw = ratedKw <= 0 ? 11.0 : ratedKw * 0.7;
    final hours = kwh / effectiveKw;
    final duration = Duration(seconds: (hours * 3600).round());

    return calculateChargingCost(
      tariff,
      kwh,
      duration,
      startTime: startTime,
    );
  }

  /// Evaluate every tariff against the same session profile and return the
  /// results sorted from cheapest to most expensive.
  ///
  /// Tariffs whose currencies differ are still returned in the same list;
  /// cross-currency comparisons are the caller's responsibility.
  static List<TariffComparisonEntry> compareTariffs(
    List<ChargingTariff> tariffs,
    double kwhDelivered, {
    Duration duration = Duration.zero,
    Duration parkingTime = Duration.zero,
    DateTime? startTime,
  }) {
    final entries = <TariffComparisonEntry>[];
    for (final tariff in tariffs) {
      final breakdown = calculateChargingCost(
        tariff,
        kwhDelivered,
        duration,
        parkingTime: parkingTime,
        startTime: startTime,
      );
      entries.add(
        TariffComparisonEntry(
          tariffId: tariff.id,
          totalCost: breakdown.totalCost,
          currency: breakdown.currency,
        ),
      );
    }
    entries.sort((a, b) => a.totalCost.compareTo(b.totalCost));
    return entries;
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  static double _energyCostFor(TariffComponent component, double kwh) {
    if (kwh <= 0 || component.price <= 0) return 0;
    // stepSize for energy components is in Wh; round up to the next step.
    final step = component.stepSize <= 0 ? 1 : component.stepSize;
    final wh = kwh * 1000.0;
    final steps = (wh / step).ceil();
    final billedKwh = (steps * step) / 1000.0;
    return billedKwh * component.price;
  }

  static double _timeCostFor(TariffComponent component, double minutes) {
    if (minutes <= 0 || component.price <= 0) return 0;
    // stepSize for time components is in seconds; round up to the next step.
    final step = component.stepSize <= 0 ? 1 : component.stepSize;
    final seconds = minutes * 60.0;
    final steps = (seconds / step).ceil();
    final billedMinutes = (steps * step) / 60.0;
    return billedMinutes * component.price;
  }

  static bool _restrictionApplies(
    TariffRestriction? restriction,
    DateTime? startTime,
    double kwh,
  ) {
    if (restriction == null) return true;

    if (restriction.minKwh != null && kwh < restriction.minKwh!) return false;
    if (restriction.maxKwh != null && kwh > restriction.maxKwh!) return false;

    if (startTime != null) {
      if (restriction.daysOfWeek.isNotEmpty &&
          !restriction.daysOfWeek.contains(startTime.weekday)) {
        return false;
      }
      final start = _parseHhMm(restriction.startTime);
      final end = _parseHhMm(restriction.endTime);
      if (start != null && end != null) {
        final minutes = startTime.hour * 60 + startTime.minute;
        if (start <= end) {
          if (minutes < start || minutes >= end) return false;
        } else {
          // Window wraps midnight (e.g. 22:00 - 06:00).
          if (minutes < start && minutes >= end) return false;
        }
      }
    }
    return true;
  }

  static int? _parseHhMm(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
