import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// Coverage for #1394 — `ErrorTrace.category` must reflect the
/// [ErrorLayer] passed through `errorLogger.log`, instead of falling
/// back to `ErrorCategory.unknown` for every wrapped error.
///
/// These tests exercise the pure inference helper directly so they do
/// NOT need Hive / Riverpod / connectivity-channel mocking. The
/// recorder-level integration is covered by `trace_recorder_test.dart`.
void main() {
  group('inferCategoryFromLayer — layer mapping', () {
    final genericError = Exception('boom');

    // Each ErrorLayer maps to the ErrorCategory that the privacy
    // dashboard groups under. `background` / `isolate` / `other`
    // intentionally map to `unknown` for generic exceptions because
    // we have no actionable hint about the root cause.
    final expected = <ErrorLayer, ErrorCategory>{
      ErrorLayer.ui: ErrorCategory.ui,
      ErrorLayer.providers: ErrorCategory.provider,
      ErrorLayer.services: ErrorCategory.api,
      ErrorLayer.storage: ErrorCategory.cache,
      ErrorLayer.sync: ErrorCategory.api,
      ErrorLayer.background: ErrorCategory.unknown,
      ErrorLayer.isolate: ErrorCategory.unknown,
      ErrorLayer.other: ErrorCategory.unknown,
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} → ${entry.value.name}', () {
        expect(
          inferCategoryFromLayer(entry.key, genericError),
          entry.value,
          reason: 'layer ${entry.key.name} must map to ${entry.value.name}',
        );
      });
    }

    test('mapping is exhaustive over ErrorLayer', () {
      // Failsafe: if a new ErrorLayer is added without updating the
      // inference helper, this assertion catches it before the
      // privacy dashboard starts bucketing the new layer as
      // `unknown` again.
      for (final layer in ErrorLayer.values) {
        expect(
          expected.containsKey(layer),
          isTrue,
          reason: 'ErrorLayer.${layer.name} missing from inference map',
        );
      }
    });
  });

  group('inferCategoryFromLayer — PlatformException override', () {
    // PlatformException is the most actionable hint the user can act
    // on, so it short-circuits to `platform` regardless of the layer
    // it bubbled up through.
    test('every layer maps a PlatformException to platform', () {
      final platformError = PlatformException(
        code: 'no_permission',
        message: 'location denied',
      );
      for (final layer in ErrorLayer.values) {
        expect(
          inferCategoryFromLayer(layer, platformError),
          ErrorCategory.platform,
          reason:
              'PlatformException must override layer ${layer.name} → platform',
        );
      }
    });
  });

  group('inferCategoryFromLayer — network exception override', () {
    // Network failures usually surface in the services layer but a
    // SocketException is fundamentally a network problem, not an API
    // contract problem — categorise by failure shape.
    test('SocketException maps to network for every layer', () {
      const socketError = SocketException('host unreachable');
      for (final layer in ErrorLayer.values) {
        expect(
          inferCategoryFromLayer(layer, socketError),
          ErrorCategory.network,
          reason:
              'SocketException must override layer ${layer.name} → network',
        );
      }
    });

    test('TimeoutException maps to network for every layer', () {
      final timeoutError = TimeoutException('upstream stalled');
      for (final layer in ErrorLayer.values) {
        expect(
          inferCategoryFromLayer(layer, timeoutError),
          ErrorCategory.network,
          reason:
              'TimeoutException must override layer ${layer.name} → network',
        );
      }
    });

    test('HttpException maps to network for every layer', () {
      const httpError = HttpException('connection reset');
      for (final layer in ErrorLayer.values) {
        expect(
          inferCategoryFromLayer(layer, httpError),
          ErrorCategory.network,
          reason: 'HttpException must override layer ${layer.name} → network',
        );
      }
    });
  });

  group('inferCategoryFromLayer — null / unwrapped error', () {
    test('null error still resolves a category from the layer', () {
      // A null `error` is unusual but possible from synthetic call
      // sites; we still want a non-`unknown` category for the layers
      // that can produce one.
      expect(inferCategoryFromLayer(ErrorLayer.ui, null), ErrorCategory.ui);
      expect(
        inferCategoryFromLayer(ErrorLayer.services, null),
        ErrorCategory.api,
      );
    });
  });

  group('regression: standard layer/error combos never log unknown', () {
    // Regression net — if any of these combos ever drift back to
    // `unknown`, the privacy dashboard's category grouping silently
    // breaks again.
    final cases = <(ErrorLayer, Object)>[
      (ErrorLayer.ui, Exception('layout')),
      (ErrorLayer.providers, StateError('unbound')),
      (ErrorLayer.services, Exception('rate limit')),
      (ErrorLayer.storage, Exception('corrupt box')),
      (ErrorLayer.sync, Exception('supabase 5xx')),
    ];

    for (final (layer, error) in cases) {
      test('${layer.name} + ${error.runtimeType} is not unknown', () {
        expect(
          inferCategoryFromLayer(layer, error),
          isNot(ErrorCategory.unknown),
          reason: 'standard layer ${layer.name} must produce a real category',
        );
      });
    }
  });
}
