// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// The brand registry moved to `lib/core/domain/brand_registry.dart`
// (#3614) so core consumers (the OSM brand enricher, the logo mapper's
// drift guard) no longer need a core→feature import. This re-export
// keeps the search feature's public surface (and its `api.dart`
// barrel) stable.
export '../../../../core/domain/brand_registry.dart';
