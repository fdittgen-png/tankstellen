// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Re-export shim (#3130): this type moved to the shared domain kernel.
///
/// The canonical home is now `lib/core/domain/trip_length_breakdown.dart` — shared app-wide
/// vocabulary lives in `lib/core/domain/` so neither core nor other
/// features have to reach into this feature for it. New code must import
/// the kernel path; this shim only keeps legacy import sites compiling
/// until the feature-boundary lint (#3132) retires them.
library;

export '../../../../core/domain/trip_length_breakdown.dart';
