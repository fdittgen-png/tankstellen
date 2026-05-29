// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import '../../../../../core/constants/app_constants.dart';
import '../../../../feature_management/domain/build_channel.dart';
import '../../../../feature_management/domain/feature.dart';

/// Builds the copy-to-clipboard diagnostics blob for the Developer tools
/// screen (#2248).
///
/// Pure function — no BuildContext, no I/O — so it stays trivially unit-
/// testable and reusable from the copy-diagnostics action. The blob is a
/// pretty-printed JSON document with the running app version, build
/// channel, the count of buffered error traces, and the full enabled /
/// disabled state of every [Feature]. It contains no user-identifying
/// data (no API keys, no profiles, no station data), so it is safe to
/// drop on a clipboard and paste into a bug report.
String buildDeveloperDiagnostics({
  required BuildChannel channel,
  required Set<Feature> enabledFeatures,
  required int errorTraceCount,
}) {
  final flags = <String, bool>{
    for (final f in Feature.values) f.name: enabledFeatures.contains(f),
  };
  return const JsonEncoder.withIndent('  ').convert({
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'appVersion': AppConstants.appVersion,
    'appPackage': AppConstants.appPackage,
    'buildChannel': channel.name,
    'errorTraceCount': errorTraceCount,
    'featureFlags': flags,
  });
}
