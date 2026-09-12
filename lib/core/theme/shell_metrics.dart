// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// How far the docked centre button protrudes above the bottom bar's
/// top edge in portrait (#2552). Shared with the map overlays (#4080):
/// the bar no longer reserves this strip as dead space, so a widget
/// anchored to the bottom of a tab body that must stay clear of the
/// button's arc offsets itself by this much.
const double kShellButtonRise = 24;
