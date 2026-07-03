// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3451 — chunked bulk persists: yield to the event loop every
/// [kBulkWriteYieldEvery] writes so a large sync pull (100+ Hive puts in
/// one loop) can't starve frame production while the app is visible.
const int kBulkWriteYieldEvery = 25;

/// Call after the [index]-th (0-based) write of a bulk persist loop:
/// completes synchronously-fast except after every [every]-th write, where
/// it defers through the event queue (`Future.delayed(Duration.zero)`, NOT
/// a microtask — microtasks run before the frame scheduler gets a slot).
///
/// Write order is preserved: the loop simply awaits, it never reorders or
/// batches the writes themselves.
Future<void> yieldToEventLoopEvery(int index,
    {int every = kBulkWriteYieldEvery}) async {
  if ((index + 1) % every != 0) return;
  await Future<void>.delayed(Duration.zero);
}
