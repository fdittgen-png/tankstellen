import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/feedback/auto_record_badge_service.dart';

/// Unit tests for [AutoRecordBadgeService] (#1004 phase 5).
///
/// The launcher-side `AppBadgePlus.updateBadge` call is replaced with
/// an in-test recorder so we can assert exact call sequences without
/// reaching for a platform channel mock — that level of indirection
/// belongs in the integration suite, not here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  Future<({AutoRecordBadgeService service, List<int> calls})> build({
    Future<void> Function(int)? overrideSetBadge,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final calls = <int>[];
    final service = AutoRecordBadgeService(
      prefs: prefs,
      setBadge: overrideSetBadge ??
          (count) async {
            calls.add(count);
          },
    );
    return (service: service, calls: calls);
  }

  group('AutoRecordBadgeService', () {
    test('initial count is 0', () async {
      final fixture = await build();
      expect(fixture.service.count, 0);
    });

    test('increment from 0 sets count to 1 and badge to 1', () async {
      final fixture = await build();
      await fixture.service.increment();
      expect(fixture.service.count, 1);
      expect(fixture.calls, [1]);
    });

    test('three increments push the badge to 1, 2, 3 in order', () async {
      final fixture = await build();
      await fixture.service.increment();
      await fixture.service.increment();
      await fixture.service.increment();
      expect(fixture.service.count, 3);
      expect(fixture.calls, [1, 2, 3]);
    });

    test('decrement from 2 drops to 1 and pushes 1 to the badge', () async {
      final fixture = await build();
      await fixture.service.increment();
      await fixture.service.increment();
      fixture.calls.clear();
      await fixture.service.decrement();
      expect(fixture.service.count, 1);
      expect(fixture.calls, [1]);
    });

    test('decrement from 0 clamps at 0 and pushes 0 to clear the badge',
        () async {
      final fixture = await build();
      await fixture.service.decrement();
      expect(fixture.service.count, 0);
      expect(fixture.calls, [0]);
    });

    test('markAllAsRead resets to 0 and clears the badge', () async {
      final fixture = await build();
      for (var i = 0; i < 5; i++) {
        await fixture.service.increment();
      }
      fixture.calls.clear();
      await fixture.service.markAllAsRead();
      expect(fixture.service.count, 0);
      expect(fixture.calls, [0]);
    });

    test('platform exception in setBadge does not propagate, state persists',
        () async {
      final fixture = await build(
        overrideSetBadge: (_) async {
          throw StateError('launcher does not support badges');
        },
      );
      await fixture.service.increment(); // must not throw
      expect(fixture.service.count, 1);

      // The next service instance reading the same prefs sees the
      // persisted count — proving the Dart-level state survives the
      // platform-side failure.
      final prefs = await SharedPreferences.getInstance();
      final reread = AutoRecordBadgeService(prefs: prefs);
      expect(reread.count, 1);
    });

    test('count survives across instances backed by the same prefs',
        () async {
      final fixture = await build();
      await fixture.service.increment();
      await fixture.service.increment();
      final prefs = await SharedPreferences.getInstance();
      final reread = AutoRecordBadgeService(prefs: prefs);
      expect(reread.count, 2);
    });
  });
}
