// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The stale-price policy moved to core at #4092 so the results list
/// could share it without `features/search` importing
/// `features/favorites`. This re-export keeps every existing caller and
/// test pointing at the same names.
library;

export '../../../core/domain/price_freshness.dart';
