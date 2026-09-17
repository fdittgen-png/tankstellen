// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'fuzzy_consumption_engine.dart';

/// The one fuzzy consumption engine production runs (#4233, ADR 0024).
///
/// This is the **only** construction site of a [FuzzyConsumptionEngine] or
/// a [FuzzyRuleBase] in `lib/` outside the engine's own declarations —
/// `test/lint/single_consumption_estimator_test.dart` fails the build on a
/// second one. There is no factory, no provider, no setting and no
/// `Feature` flag that could hand a producer a different engine: a fitted
/// rule base ships by changing this constant (and its `rulesVersion`),
/// through the epic's validation gate, never by a runtime choice.
///
/// It carries the neutral rule base (ADR 0023 §3), so every estimate it
/// refines comes back unchanged — which is how #4233 wires the engine in
/// without moving a single shipped figure.
const FuzzyConsumptionEngine kProductionFuzzyEngine = FuzzyConsumptionEngine();
