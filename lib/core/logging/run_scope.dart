// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math';

/// The ADR 0021 `runId`: one id shared by every trace and breadcrumb that
/// belongs to the same run — a search, a background scan, an export, an
/// OCR pass (#3980).
///
/// Carried by the [Zone], not by parameters: `log.*` and
/// `BreadcrumbCollector.add` read [currentId] wherever they are called,
/// so a run's id reaches a failure five awaits deep in a service chain
/// without threading a value through every signature in between. Entry
/// points wrap their work in [run]; everything else stays untouched.
///
/// Ids are a per-run counter plus a per-process random nonce: unique within
/// a process, and — because breadcrumbs outlive a process (#3580) — not
/// colliding with the previous launch's `search-1` either. No wall-clock
/// read (#3660): a nonce is not a timestamp anyone asserts on.
abstract final class RunScope {
  static const _key = #tankstellenRunId;
  static int _seq = 0;
  static final String _nonce = Random().nextInt(0x7fffffff).toRadixString(36);

  /// The id of the run this code is executing inside, or null outside
  /// any [run].
  static String? get currentId => Zone.current[_key] as String?;

  /// Runs [body] inside a fresh run scope named [kind] (`search`,
  /// `background-scan`, `export`, `ocr`). Nested runs get their own id —
  /// a search launched by a scan is a run of its own.
  static Future<T> run<T>(String kind, Future<T> Function() body) {
    final id = '$kind-${++_seq}-$_nonce';
    return runZoned(body, zoneValues: {_key: id});
  }

  /// Test seam: the counter restarts so ids are predictable.
  static void resetForTest() => _seq = 0;
}
