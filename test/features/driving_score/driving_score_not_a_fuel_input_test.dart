// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#4205): the driving score describes behaviour and is
/// NEVER an input to a fuel figure. The code that PRODUCES fuel figures —
/// fill-up calibration, consumption, and every fuel-rate / estimator /
/// calibration file in OBD2 and trips — must not reference the score or
/// the behaviour dimensions. (Coaching hints computed beside an estimate
/// and a live score shown next to it are fine: they never feed a litre.)
void main() {
  test('fuel-figure producers never use the driving score', () {
    final score = RegExp(
        r'\b(DrivingScore|computeDrivingScore\w*|DrivingDimensions?|'
        r'computeDrivingDimensions|liveDrivingScore|LiveDrivingBand\w*)\b');
    final producerName =
        RegExp(r'(fuel|pump_gain|calibrat|consum|tank_report|estimat)');
    final offenders = <String>[];
    void scan(String root, {bool allFiles = false}) {
      final dir = Directory(root);
      if (!dir.existsSync()) return;
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') ||
            f.path.endsWith('.g.dart') ||
            f.path.endsWith('.freezed.dart')) {
          continue;
        }
        final name = f.uri.pathSegments.last;
        if (!allFiles && !producerName.hasMatch(name)) continue;
        if (score.hasMatch(f.readAsStringSync())) offenders.add(f.path);
      }
    }

    scan('lib/features/fill_ups/domain', allFiles: true);
    scan('lib/features/fill_ups/data', allFiles: true);
    scan('lib/features/consumption', allFiles: true);
    scan('lib/features/obd2/data');
    scan('lib/features/obd2/domain');
    scan('lib/features/trips/domain');
    expect(offenders, isEmpty,
        reason: 'a behaviour score feeding a fuel figure is the coupling '
            '#4201 / #4205 forbid');
  });
}
