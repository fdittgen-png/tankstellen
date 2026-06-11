// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `station_services` feature (#3132).
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

export 'argentina/argentina_station_service.dart';
export 'australia/australia_station_service.dart';
export 'austria/econtrol_station_service.dart';
export 'chile/chile_station_service.dart';
export 'denmark/denmark_station_service.dart';
export 'france/prix_carburants_flux_station_service.dart';
export 'france/prix_carburants_station_service.dart';
export 'germany/tankerkoenig_station_service.dart';
export 'greece/greece_station_service.dart';
export 'italy/mise_station_service.dart';
export 'luxembourg/luxembourg_station_service.dart';
export 'mexico/mexico_station_service.dart';
export 'portugal/portugal_station_service.dart';
export 'romania/romania_station_service.dart';
export 'slovenia/slovenia_station_service.dart';
export 'south_korea/south_korea_station_service.dart';
export 'spain/miteco_station_service.dart';
export 'uk/uk_cma_bulk_station_service.dart';
export 'uk/uk_station_service.dart';
