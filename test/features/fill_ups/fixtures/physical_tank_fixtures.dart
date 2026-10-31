// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';

FillUp physicalFill(
  String id,
  int day,
  double liters,
  double odo, {
  bool full = true,
  bool correction = false,
  FuelType fuel = FuelType.e10,
  String? vehicle = 'car',
}) => FillUp(
  id: id,
  date: DateTime.utc(2026, 1, day),
  liters: liters,
  totalCost: correction ? 0 : liters * 2,
  odometerKm: odo,
  fuelType: fuel,
  vehicleId: vehicle,
  isFullTank: full,
  isCorrection: correction,
);
