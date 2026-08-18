// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Platform fork for the OBD2 scan-readiness probe, isolated in `impl/`
/// so the shared code stays free of inline platform branching
/// (ADR 0009; enforced by `test/lint/no_inline_platform_check_test.dart`).
///
/// Mirrors the shape of `core/telemetry/impl/proc_cpu_support.dart`.
///
/// Whether the BLE scan on this platform additionally requires **location
/// services to be enabled system-wide**. This is an Android constraint:
/// on many builds a scan performed without location services returns an
/// empty list *successfully* — no error, no permission complaint — which
/// is the most confusing failure in the whole OBD2 flow. iOS has no such
/// requirement, so it must never be shown a location message it cannot
/// act on.
///
/// `defaultTargetPlatform` rather than `dart:io`: no import needed, so
/// the file stays web-safe, and tests can override it with
/// `debugDefaultTargetPlatformOverride`.
bool scanNeedsLocationServices() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
