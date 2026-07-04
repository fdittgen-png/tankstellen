// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/providers/recording_lifecycle_marks_recorder.dart';

/// #3465 — the rolling lifecycle-marks recorder that feeds the GPS
/// coverage report: transition mapping, dedupe, the `inactive` blip
/// filter, the rolling cap, the trip-window projection with its leading
/// clamped anchor, and the never-throws contract of the lifecycle hooks.
void main() {
  final t0 = DateTime(2026, 7, 1, 8);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  group('onLifecycleState', () {
    test('maps paused/hidden/detached to backgrounded, resumed to '
        'foregrounded', () {
      final recorder = RecordingLifecycleMarksRecorder();
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(1));
      recorder.onLifecycleState(AppLifecycleState.resumed, at: at(2));
      recorder.onLifecycleState(AppLifecycleState.hidden, at: at(3));
      recorder.onLifecycleState(AppLifecycleState.resumed, at: at(4));
      recorder.onLifecycleState(AppLifecycleState.detached, at: at(5));

      expect(recorder.debugMarks.map((m) => m.backgrounded).toList(),
          [true, false, true, false, true]);
    });

    test('inactive blips are ignored (permission dialogs must not read as '
        'backgrounding)', () {
      final recorder = RecordingLifecycleMarksRecorder();
      recorder.onLifecycleState(AppLifecycleState.inactive, at: at(1));
      recorder.onLifecycleState(AppLifecycleState.resumed, at: at(2));
      recorder.onLifecycleState(AppLifecycleState.inactive, at: at(3));

      expect(recorder.debugMarks, hasLength(1));
      expect(recorder.debugMarks.single.backgrounded, isFalse);
    });

    test('consecutive same-direction transitions are deduped', () {
      final recorder = RecordingLifecycleMarksRecorder();
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(1));
      recorder.onLifecycleState(AppLifecycleState.hidden, at: at(2));
      recorder.onLifecycleState(AppLifecycleState.detached, at: at(3));

      expect(recorder.debugMarks, hasLength(1),
          reason: 'paused→hidden→detached is ONE backgrounding');
    });

    test('the rolling buffer caps at kCap, dropping the oldest slice', () {
      final recorder = RecordingLifecycleMarksRecorder();
      for (var i = 0; i < RecordingLifecycleMarksRecorder.kCap + 10; i++) {
        recorder.onLifecycleState(
          i.isEven ? AppLifecycleState.paused : AppLifecycleState.resumed,
          at: at(i),
        );
      }
      expect(recorder.debugMarks,
          hasLength(RecordingLifecycleMarksRecorder.kCap));
      expect(recorder.debugMarks.last.at, at(RecordingLifecycleMarksRecorder.kCap + 9));
    });

    test('never throws — every lifecycle value returns normally on the '
        'hot path (the documented contract)', () {
      final recorder = RecordingLifecycleMarksRecorder();
      for (final state in AppLifecycleState.values) {
        expect(() => recorder.onLifecycleState(state), returnsNormally);
      }
      expect(
          () => recorder.marksForWindow(at(10), at(0)), returnsNormally,
          reason: 'an inverted window must degrade, not derail a save');
    });
  });

  group('marksForWindow', () {
    test('a foreground-only trip yields the single foreground anchor', () {
      final recorder = RecordingLifecycleMarksRecorder();
      final marks = recorder.marksForWindow(at(0), at(100));

      expect(marks, hasLength(1));
      expect(marks.single.at, at(0));
      expect(marks.single.backgrounded, isFalse,
          reason: 'no transition ever observed → the app never left the '
              'foreground (Flutter launches resumed)');
    });

    test('the leading anchor carries the state the trip STARTED in', () {
      final recorder = RecordingLifecycleMarksRecorder();
      // Backgrounded well before the trip; the trip starts at t=50.
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(10));
      final marks = recorder.marksForWindow(at(50), at(100));

      expect(marks.first.at, at(50), reason: 'clamped to the trip start');
      expect(marks.first.backgrounded, isTrue);
    });

    test('in-window transitions follow the anchor; out-of-window ones are '
        'dropped', () {
      final recorder = RecordingLifecycleMarksRecorder();
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(60));
      recorder.onLifecycleState(AppLifecycleState.resumed, at: at(80));
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(200));

      final marks = recorder.marksForWindow(at(50), at(100));
      expect(marks, hasLength(3));
      expect(marks[0].backgrounded, isFalse); // anchor at t=50
      expect(marks[1].at, at(60));
      expect(marks[1].backgrounded, isTrue);
      expect(marks[2].at, at(80));
      expect(marks[2].backgrounded, isFalse);
    });

    test('the clamp never produces two consecutive same-direction marks',
        () {
      final recorder = RecordingLifecycleMarksRecorder();
      // Foreground anchor + a resumed transition just inside the window
      // would duplicate the direction; the projection keeps changes only.
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(10));
      recorder.onLifecycleState(AppLifecycleState.resumed, at: at(20));
      recorder.onLifecycleState(AppLifecycleState.paused, at: at(60));
      recorder.onLifecycleState(AppLifecycleState.resumed, at: at(70));

      final marks = recorder.marksForWindow(at(15), at(100));
      for (var i = 1; i < marks.length; i++) {
        expect(marks[i].backgrounded, isNot(marks[i - 1].backgrounded));
      }
      expect(marks.first.at, at(15));
      expect(marks.first.backgrounded, isTrue); // paused at t=10 rules
    });
  });
}
