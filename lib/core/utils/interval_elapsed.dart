// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// "Has at least [interval] passed since [last]?" — true when nothing has
/// happened yet (#4073). The recording controller carried this predicate
/// in three hand-rolled shapes; one of them was written the other way
/// round (`< interval → return`). One name, one direction.
bool intervalElapsed(DateTime? last, DateTime now, Duration interval) =>
    last == null || now.difference(last) >= interval;
