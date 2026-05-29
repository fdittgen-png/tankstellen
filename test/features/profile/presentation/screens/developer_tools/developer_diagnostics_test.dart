// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/developer_diagnostics.dart';

void main() {
  group('buildDeveloperDiagnostics (#2248)', () {
    test('emits valid JSON with channel, trace count, and every flag', () {
      final blob = buildDeveloperDiagnostics(
        channel: BuildChannel.beta,
        enabledFeatures: {Feature.debugMode, Feature.priceAlerts},
        errorTraceCount: 7,
      );

      final decoded = jsonDecode(blob) as Map<String, dynamic>;
      expect(decoded['buildChannel'], 'beta');
      expect(decoded['errorTraceCount'], 7);

      final flags = decoded['featureFlags'] as Map<String, dynamic>;
      // Every Feature is represented so a reader sees the full picture.
      expect(flags.keys.length, Feature.values.length);
      expect(flags[Feature.debugMode.name], isTrue);
      expect(flags[Feature.priceAlerts.name], isTrue);
      // A flag not in the enabled set reports false rather than missing.
      expect(flags[Feature.tankSync.name], isFalse);
    });

    test('carries no user-identifying data', () {
      final blob = buildDeveloperDiagnostics(
        channel: BuildChannel.production,
        enabledFeatures: const <Feature>{},
        errorTraceCount: 0,
      );
      final decoded = jsonDecode(blob) as Map<String, dynamic>;
      // The blob is safe to paste into a public bug report — only build /
      // flag metadata, no profiles, API keys, or station data.
      expect(decoded.keys, containsAll(<String>[
        'generatedAt',
        'appVersion',
        'appPackage',
        'buildChannel',
        'errorTraceCount',
        'featureFlags',
      ]));
      expect(decoded.containsKey('apiKey'), isFalse);
      expect(decoded.containsKey('profiles'), isFalse);
    });
  });
}
