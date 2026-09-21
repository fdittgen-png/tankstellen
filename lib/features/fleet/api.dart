// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Public API barrel of the `fleet` feature (#3132, Epic #4211).
///
/// Cross-feature consumers must import THIS file — never a path under
/// `data/`, `domain/`, `providers/` or `presentation/`. Enforced by
/// `test/lint/feature_boundary_test.dart` with an only-decreasing
/// baseline (epic #3129).
///
/// #4212 seeds it with the scope contract every later fleet slice reads:
/// which org, which role, and how fresh that answer is. #4213 adds the
/// vehicle half: the company-asset identity, the attribution a record
/// is stamped with at creation, the explicit-selection provider and the
/// two context widgets other surfaces embed.
///
/// The F5 slice (#4215) adds the expense / document domain: the state
/// boundary between a receipt and an accounting record, the reconciler
/// that refuses to invent a second fill-up, and the import boundary a
/// structured e-invoice enters through. The F7 slice (#4215, schema
/// v14) adds the server half — the user-owned sync config, the
/// private-document store, the submit/review workflow and its
/// transport seam. Later slices add their own exports to this list.
///
/// The fleet feature imports NO other feature — signals arrive as
/// primitives (an adapter device id, a VIN string, the plain facts in
/// `FillUpMatchCandidate` / `ParsedReceiptFacts`) — so this barrel is
/// a leaf of the dependency graph and `fill_ups -> fleet` cannot close
/// a cycle (`test/lint/feature_boundary_test.dart`, the #4346
/// barrel-aware SCC gate).
/// The F5 slice (#4215) contributes the expense / document domain: the
/// state boundary between a receipt and an accounting record, the
/// reconciler that refuses to invent a second fill-up, and the import
/// boundary a structured e-invoice enters through. The F7 slice
/// (#4215, schema v14) adds the server half — the user-owned sync
/// config, the private-document store, the submit/review workflow and
/// its transport seam. The F9 slice (#4216, #4214, schema v15) adds
/// the manager half — the period aggregation, its reader over the
/// widened transport seam and the location-free export. Later slices
/// add their own exports to this list.

library;

/// #4217 adds the join half: the outcome types, the controller the
/// onboarding step and Settings → Fleet drive, and the one place a
/// role / block / refusal becomes a sentence.
export 'application/fleet_join_service.dart';
export 'data/expense_intake.dart';
export 'data/fleet_document_store.dart';
export 'data/fleet_expense_store.dart';
export 'data/fleet_expense_workflow.dart';
export 'data/fleet_expenses_sync.dart';
export 'data/fleet_metrics_export.dart';
export 'data/fleet_metrics_reader.dart';
export 'data/fleet_review_transport.dart';
export 'domain/document_meta.dart';
export 'domain/expense.dart';
export 'domain/expense_fields.dart';
export 'domain/expense_reconciler.dart';
export 'domain/expense_state_machine.dart';
export 'domain/fleet_attention.dart';
export 'domain/fleet_kpis.dart';
export 'domain/fleet_scope.dart';
export 'domain/fleet_vehicle.dart';
export 'domain/money.dart';
export 'domain/vehicle_attribution.dart';
export 'domain/vehicle_attribution_resolver.dart';
export 'presentation/fleet_labels.dart';
export 'presentation/widgets/current_vehicle_control.dart';
export 'presentation/widgets/vehicle_switch_sheet.dart';
export 'providers/current_fleet_vehicle_provider.dart';
export 'providers/fleet_consent_provider.dart';
export 'providers/fleet_expense_providers.dart';
export 'providers/fleet_join_provider.dart';
export 'providers/fleet_manager_providers.dart';
export 'providers/fleet_scope_provider.dart';
