// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel/next_fill_decider.dart';
import '../../../core/domain/fuel/next_fill_decision.dart';
import '../../../core/domain/fuel/next_fill_request.dart';
import 'fuel_behaviour_provider.dart';
import 'tank_blend_provider.dart';

part 'next_fill_decision_provider.g.dart';

/// Whether [vehicleId]'s next fill should change fuel under [request]
/// (#4277).
///
/// A pure function of the current tank blend (#4279), the learned
/// behaviour profile (#4276) and the request — so it recomputes when the
/// history changes and is identical for identical inputs. The caller owns
/// the request: the objective, the offers at hand, and the vehicle's
/// approvals (`VehicleFuelCapability`, #4274). No persisted capability
/// exists yet, so an unknown one yields
/// [NextFillOutcome.compatibilityUnknown] rather than a guess.
@riverpod
NextFillDecision nextFillDecision(
  Ref ref,
  String vehicleId,
  NextFillRequest request,
) =>
    NextFillDecider.decide(
      tank: ref.watch(tankBlendProvider(vehicleId)),
      profile: ref.watch(fuelBehaviourProfileProvider(vehicleId)),
      request: request,
    );
