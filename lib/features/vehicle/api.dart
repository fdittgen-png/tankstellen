// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `vehicle` feature (#3132).
///
/// Cross-feature consumers must import THIS file — never a path
/// under `providers/`, `data/`, `domain/` or `presentation/` of
/// another feature. Enforced by `test/lint/feature_boundary_test.dart`
/// with an only-decreasing baseline (epic #3129).
///
/// The export list below is the de-facto contract measured when the
/// barrel was introduced — every file of this feature that other
/// features imported at the time. It should only ever SHRINK as
/// cross-feature reach-ins are inverted or moved to `lib/core/`.
library;

export 'data/reference_vehicle_catalog_provider.dart';
export 'data/repositories/vehicle_profile_repository.dart';
export 'data/ve_learner.dart';
export 'data/vehicle_profile_catalog_matcher.dart';
export 'data/vehicle_profile_migrator.dart';
export 'domain/calibration_confidence_tier.dart';
export 'domain/entities/reference_vehicle.dart';
export 'domain/entities/vin_data.dart';
export 'domain/fuzzy_classifier.dart';
export 'presentation/screens/edit_vehicle_screen.dart';
export 'presentation/screens/vehicle_list_screen.dart';
export 'presentation/widgets/catalog_reresolve_snackbar_host.dart';
export 'presentation/widgets/vin_confirm_dialog.dart';
export 'providers/calibration_mode_providers.dart';
export 'providers/service_reminder_providers.dart';
export 'providers/vehicle_aggregate_updater_provider.dart';
export 'providers/vehicle_providers.dart';
export 'providers/vin_decoder_provider.dart';
