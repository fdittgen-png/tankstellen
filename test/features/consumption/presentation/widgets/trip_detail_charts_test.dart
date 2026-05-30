// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';

import '../../../../helpers/pump_app.dart';

/// #890 — chart-widget tests for the Trip detail screen.
///
/// The screen composes three near-identical [CustomPaint] line charts
/// (speed, fuel rate, RPM). Every chart renders a `CustomPaint` when
/// samples exist and a localized empty caption when none do.

List<TripDetailSample> _withAllFields(int n) => [
      for (var i = 0; i < n; i++)
        TripDetailSample(
          timestamp: DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
          speedKmh: 30 + i.toDouble(),
          rpm: 1500 + i * 10,
          fuelRateLPerHour: 4 + (i % 3),
        ),
    ];

List<TripDetailSample> _withSpeedOnly(int n) => [
      for (var i = 0; i < n; i++)
        TripDetailSample(
          timestamp: DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
          speedKmh: 20 + i.toDouble(),
        ),
    ];

void _expectCustomPaintPresent(WidgetTester tester, Type chartType) {
  expect(
    find.descendant(
      of: find.byType(chartType),
      matching: find.byType(CustomPaint),
    ),
    findsWidgets,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripDetailSpeedChart', () {
    testWidgets('renders CustomPaint when samples exist', (tester) async {
      await pumpApp(
        tester,
        TripDetailSpeedChart(samples: _withAllFields(10)),
      );
      _expectCustomPaintPresent(tester, TripDetailSpeedChart);
      expect(find.text('No samples recorded'), findsNothing);
    });

    testWidgets('renders CustomPaint even when only speed is present',
        (tester) async {
      await pumpApp(
        tester,
        TripDetailSpeedChart(samples: _withSpeedOnly(5)),
      );
      _expectCustomPaintPresent(tester, TripDetailSpeedChart);
    });

    testWidgets('renders empty-state caption for an empty list',
        (tester) async {
      await pumpApp(
        tester,
        const TripDetailSpeedChart(samples: []),
      );
      expect(find.text('No samples recorded'), findsOneWidget);
    });
  });

  group('TripDetailFuelRateChart', () {
    testWidgets('renders CustomPaint when fuel rate samples exist',
        (tester) async {
      await pumpApp(
        tester,
        TripDetailFuelRateChart(samples: _withAllFields(10)),
      );
      _expectCustomPaintPresent(tester, TripDetailFuelRateChart);
      expect(find.text('No samples recorded'), findsNothing);
    });

    testWidgets(
      'renders empty-state caption when every sample has null fuel rate',
      (tester) async {
        await pumpApp(
          tester,
          TripDetailFuelRateChart(samples: _withSpeedOnly(10)),
        );
        expect(find.text('No samples recorded'), findsOneWidget);
      },
    );

    testWidgets('renders empty-state caption for an empty list',
        (tester) async {
      await pumpApp(
        tester,
        const TripDetailFuelRateChart(samples: []),
      );
      expect(find.text('No samples recorded'), findsOneWidget);
    });

    // #2431 — when the measured series is all-null but a GPS-physics
    // estimate exists, the chart plots the estimate with a badge instead
    // of the empty caption.
    testWidgets(
      'falls back to the ESTIMATED series + badge when measured is all-null',
      (tester) async {
        final estimated = [
          for (var i = 0; i < 8; i++)
            TripDetailSample(
              timestamp:
                  DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
              speedKmh: 60 + i.toDouble(),
              estimatedFuelRateLPerHour: 4.5 + (i % 3),
            ),
        ];
        await pumpApp(tester, TripDetailFuelRateChart(samples: estimated));
        _expectCustomPaintPresent(tester, TripDetailFuelRateChart);
        expect(find.text('No samples recorded'), findsNothing);
        // The estimated badge ('~ estimated') is shown.
        expect(find.textContaining('estimated'), findsOneWidget);
      },
    );

    testWidgets(
      'prefers the MEASURED series (no badge) when both are present',
      (tester) async {
        final both = [
          for (var i = 0; i < 8; i++)
            TripDetailSample(
              timestamp:
                  DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
              speedKmh: 60 + i.toDouble(),
              fuelRateLPerHour: 5 + (i % 2),
              estimatedFuelRateLPerHour: 4.5 + (i % 3),
            ),
        ];
        await pumpApp(tester, TripDetailFuelRateChart(samples: both));
        _expectCustomPaintPresent(tester, TripDetailFuelRateChart);
        expect(find.textContaining('estimated'), findsNothing);
      },
    );
  });

  group('TripDetailRpmChart', () {
    testWidgets('renders CustomPaint when RPM samples exist', (tester) async {
      await pumpApp(
        tester,
        TripDetailRpmChart(samples: _withAllFields(10)),
      );
      _expectCustomPaintPresent(tester, TripDetailRpmChart);
      expect(find.text('No samples recorded'), findsNothing);
    });

    testWidgets(
      'renders empty-state caption when every sample has null RPM',
      (tester) async {
        await pumpApp(
          tester,
          TripDetailRpmChart(samples: _withSpeedOnly(10)),
        );
        expect(find.text('No samples recorded'), findsOneWidget);
      },
    );

    testWidgets('renders empty-state caption for an empty list',
        (tester) async {
      await pumpApp(
        tester,
        const TripDetailRpmChart(samples: []),
      );
      expect(find.text('No samples recorded'), findsOneWidget);
    });
  });

  // #1262 phase 3 — engine-load sparkline. Mirrors the RPM chart
  // gating: cars without PID 0x04 carry null engineLoadPercent on
  // every sample, and the chart falls back to the shared empty-state
  // caption (the parent screen actually skips the section header for
  // that case; tested in trip_detail_body_test.dart).
  group('TripDetailEngineLoadChart', () {
    List<TripDetailSample> withEngineLoad(int n) => [
          for (var i = 0; i < n; i++)
            TripDetailSample(
              timestamp:
                  DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
              speedKmh: 25 + i.toDouble(),
              engineLoadPercent: 30 + (i % 60).toDouble(),
            ),
        ];

    testWidgets('renders CustomPaint when engine-load samples exist',
        (tester) async {
      await pumpApp(
        tester,
        TripDetailEngineLoadChart(samples: withEngineLoad(10)),
      );
      _expectCustomPaintPresent(tester, TripDetailEngineLoadChart);
      expect(find.text('No samples recorded'), findsNothing);
    });

    testWidgets(
      'renders empty-state caption when every sample has null engineLoad',
      (tester) async {
        await pumpApp(
          tester,
          TripDetailEngineLoadChart(samples: _withSpeedOnly(10)),
        );
        expect(find.text('No samples recorded'), findsOneWidget);
      },
    );

    testWidgets('renders empty-state caption for an empty list',
        (tester) async {
      await pumpApp(
        tester,
        const TripDetailEngineLoadChart(samples: []),
      );
      expect(find.text('No samples recorded'), findsOneWidget);
    });
  });

  group('TripDetailSample accepts partial data without throwing', () {
    testWidgets('every chart survives mixed null/non-null samples',
        (tester) async {
      final mixed = <TripDetailSample>[
        TripDetailSample(
          timestamp: DateTime.utc(2026, 4, 22, 10),
          speedKmh: 10,
        ),
        TripDetailSample(
          timestamp: DateTime.utc(2026, 4, 22, 10, 0, 1),
          speedKmh: 12,
          rpm: 1500,
        ),
        TripDetailSample(
          timestamp: DateTime.utc(2026, 4, 22, 10, 0, 2),
          speedKmh: 14,
          fuelRateLPerHour: 3.5,
        ),
      ];
      await pumpApp(tester, TripDetailSpeedChart(samples: mixed));
      await pumpApp(tester, TripDetailFuelRateChart(samples: mixed));
      await pumpApp(tester, TripDetailRpmChart(samples: mixed));
      expect(tester.takeException(), isNull);
    });
  });

  // #2461 — the new driving-signal charts. Each renders when its signal
  // is present and falls back to the shared empty caption when all-null.
  group('TripDetailThrottleChart (#2461)', () {
    List<TripDetailSample> withPedal(int n) => [
          for (var i = 0; i < n; i++)
            TripDetailSample(
              timestamp:
                  DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
              speedKmh: 40,
              pedalPercent: 20 + i.toDouble(),
            ),
        ];

    List<TripDetailSample> withThrottleOnly(int n) => [
          for (var i = 0; i < n; i++)
            TripDetailSample(
              timestamp:
                  DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
              speedKmh: 40,
              throttlePercent: 30 + i.toDouble(),
            ),
        ];

    testWidgets('renders CustomPaint when pedal samples exist',
        (tester) async {
      await pumpApp(tester, TripDetailThrottleChart(samples: withPedal(8)));
      _expectCustomPaintPresent(tester, TripDetailThrottleChart);
      expect(find.text('No samples recorded'), findsNothing);
    });

    testWidgets('falls back to throttle % when pedal is absent',
        (tester) async {
      await pumpApp(
        tester,
        TripDetailThrottleChart(samples: withThrottleOnly(8)),
      );
      _expectCustomPaintPresent(tester, TripDetailThrottleChart);
    });

    testWidgets('renders empty caption when pedal AND throttle are all-null',
        (tester) async {
      await pumpApp(tester, TripDetailThrottleChart(samples: _withSpeedOnly(5)));
      expect(find.text('No samples recorded'), findsOneWidget);
    });
  });

  group('TripDetailCoolantChart / Altitude / Lambda (#2461)', () {
    List<TripDetailSample> withSignals(int n) => [
          for (var i = 0; i < n; i++)
            TripDetailSample(
              timestamp:
                  DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
              speedKmh: 40,
              coolantTempC: 60 + i.toDouble(),
              altitudeM: 100 + i.toDouble(),
              lambda: 0.95 + i * 0.001,
            ),
        ];

    testWidgets('coolant chart renders when coolant samples exist',
        (tester) async {
      await pumpApp(tester, TripDetailCoolantChart(samples: withSignals(8)));
      _expectCustomPaintPresent(tester, TripDetailCoolantChart);
    });

    testWidgets('altitude chart renders when altitude samples exist',
        (tester) async {
      await pumpApp(tester, TripDetailAltitudeChart(samples: withSignals(8)));
      _expectCustomPaintPresent(tester, TripDetailAltitudeChart);
    });

    testWidgets('lambda chart renders when lambda samples exist',
        (tester) async {
      await pumpApp(tester, TripDetailLambdaChart(samples: withSignals(8)));
      _expectCustomPaintPresent(tester, TripDetailLambdaChart);
    });

    testWidgets('each optional chart is empty when its signal is all-null',
        (tester) async {
      await pumpApp(tester, TripDetailCoolantChart(samples: _withSpeedOnly(5)));
      expect(find.text('No samples recorded'), findsOneWidget);
      await pumpApp(tester, TripDetailAltitudeChart(samples: _withSpeedOnly(5)));
      expect(find.text('No samples recorded'), findsOneWidget);
      await pumpApp(tester, TripDetailLambdaChart(samples: _withSpeedOnly(5)));
      expect(find.text('No samples recorded'), findsOneWidget);
    });
  });
}
