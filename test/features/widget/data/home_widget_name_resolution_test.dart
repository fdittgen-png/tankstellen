// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Regression test for the home-widget name-resolution field bug
// (#2207 follow-up). The device error log showed 35 traces of
//   `PlatformException: No Widget found with Name FuelPriceWidgetProvider`
// — the SHORT provider name — even though the call site passed the
// fully-qualified name as well.
//
// home_widget 0.9.2 resolves the provider class as
//   `Class.forName(qualifiedAndroidName ?? "${packageName}.${androidName}")`
// so a non-null `qualifiedAndroidName` is honoured as-is, but the
// plugin's ClassNotFoundException message always prints the short
// `androidName`. We therefore pass ONLY the fully-qualified name at every
// `updateWidget` call site so the qualified class is always resolved and
// a future failure can never report the wrong (short) name.
//
// This test taps the real `home_widget` MethodChannel, captures the
// `updateWidget` arguments, and asserts:
//   - `qualifiedAndroidName` == `de.tankstellen.tankstellen.FuelPriceWidgetProvider`
//   - `android` (the short name) is null

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';

const _expectedQualifiedName =
    'de.tankstellen.tankstellen.FuelPriceWidgetProvider';

/// Minimal favorite storage with NO favorites, so `updateWidget` takes
/// the empty-favorites early-return — which still issues the
/// `HomeWidget.updateWidget` channel call we want to inspect, without
/// needing the full station-data graph.
class _EmptyFavoriteStorage implements FavoriteStorage {
  @override
  List<String> getFavoriteIds() => const [];

  @override
  Map<String, dynamic>? getFavoriteStationData(String id) => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeWidgetService.updateWidget name resolution (#2207 follow-up)',
      () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('home_widget');

    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        // `getInstalledWidgets` must hand back a List so the per-widget
        // profile lookup degrades to "no override" instead of throwing
        // (which would route through errorLogger → Hive, unavailable here).
        if (call.method == 'getInstalledWidgets') return <dynamic>[];
        // saveWidgetData / updateWidget both return bool? in the plugin.
        return true;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test(
        'passes ONLY the fully-qualified provider name (short `android` '
        'arg is null) so the wrong short name can never be resolved', () async {
      await HomeWidgetService.updateWidget(_EmptyFavoriteStorage());

      final updateCalls =
          calls.where((c) => c.method == 'updateWidget').toList();
      expect(updateCalls, isNotEmpty,
          reason: 'updateWidget must reach the home_widget channel');

      for (final call in updateCalls) {
        final args = (call.arguments as Map).cast<String, dynamic>();
        expect(args['qualifiedAndroidName'], _expectedQualifiedName,
            reason: 'every updateWidget call must pass the fully-qualified '
                'provider class so resolution never falls back to '
                '"\${applicationId}.FuelPriceWidgetProvider"');
        expect(args['android'], isNull,
            reason: 'the short `androidName` must NOT be passed — when set '
                'alongside the qualified name it is only used in the '
                'misleading ClassNotFoundException message');
      }
    });
  });

  // BUG 2c — a benign home-widget update failure (no widget placed / name
  // not found) must NOT spam the user-exportable error log. The device log
  // had 35 such traces. We assert the benign PlatformException(-3) does NOT
  // reach errorLogger, while a genuinely unexpected failure still does.
  group('HomeWidgetService log-flood suppression (#2207 follow-up)', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('home_widget');

    late int spoolCalls;

    setUp(() {
      spoolCalls = 0;
      // No container bound → errorLogger.log routes to the spool seam.
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {
        spoolCalls++;
      };
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      errorLogger.resetForTest();
    });

    void wireUpdateWidgetThrow(Object toThrow) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInstalledWidgets') return <dynamic>[];
        if (call.method == 'updateWidget') throw toThrow;
        return true;
      });
    }

    test(
        'benign "No Widget found" PlatformException(-3) is swallowed, NOT '
        'logged (no error-log flood)', () async {
      wireUpdateWidgetThrow(
        PlatformException(
          code: '-3',
          message: 'No Widget found with Name FuelPriceWidgetProvider',
        ),
      );

      await HomeWidgetService.updateWidget(_EmptyFavoriteStorage());

      expect(spoolCalls, 0,
          reason: 'a not-placed / name-not-found widget update is expected '
              'and must not reach the error log');
    });

    test('a genuinely unexpected failure IS still logged', () async {
      wireUpdateWidgetThrow(
        PlatformException(code: 'oom', message: 'out of memory'),
      );

      await HomeWidgetService.updateWidget(_EmptyFavoriteStorage());

      expect(spoolCalls, 1,
          reason: 'unexpected widget-update failures must stay visible in '
              'the error log');
    });
  });
}
