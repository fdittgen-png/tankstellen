import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/providers/selected_station_provider.dart';

/// Tests for [SelectedStation] — the inline-detail selection notifier.
///
/// The provider has a tiny surface (three methods) but each path controls
/// whether the wide-screen split view shows station detail or not, so all
/// three branches need an explicit guard.
void main() {
  ProviderContainer createContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('SelectedStation.build', () {
    test('starts with null (no station selected)', () {
      final container = createContainer();
      expect(container.read(selectedStationProvider), isNull);
    });
  });

  group('SelectedStation.select', () {
    test('stores the given station id', () {
      final container = createContainer();

      container.read(selectedStationProvider.notifier).select('shell-42');

      expect(container.read(selectedStationProvider), 'shell-42');
    });

    test('overwrites a previously-selected station', () {
      final container = createContainer();
      final notifier = container.read(selectedStationProvider.notifier);

      notifier.select('first');
      expect(container.read(selectedStationProvider), 'first');

      notifier.select('second');
      expect(container.read(selectedStationProvider), 'second');
    });

    test('accepts the empty string as a distinct selected id', () {
      // Defensive: UI guards that compare the state against null should
      // not break if a consumer accidentally passes an empty id.
      final container = createContainer();

      container.read(selectedStationProvider.notifier).select('');

      expect(container.read(selectedStationProvider), '');
      // Critically: empty string is NOT null — readers that gate on
      // `state != null` still render the detail pane.
      expect(container.read(selectedStationProvider), isNotNull);
    });
  });

  group('SelectedStation.clear', () {
    test('resets the state to null', () {
      final container = createContainer();
      final notifier = container.read(selectedStationProvider.notifier);

      notifier.select('aral-7');
      expect(container.read(selectedStationProvider), 'aral-7');

      notifier.clear();
      expect(container.read(selectedStationProvider), isNull);
    });

    test('is a no-op when already cleared', () {
      final container = createContainer();
      final notifier = container.read(selectedStationProvider.notifier);

      notifier.clear();
      notifier.clear();

      expect(container.read(selectedStationProvider), isNull);
    });

    test('can be reused after clearing', () {
      final container = createContainer();
      final notifier = container.read(selectedStationProvider.notifier);

      notifier.select('first');
      notifier.clear();
      notifier.select('second');

      expect(container.read(selectedStationProvider), 'second');
    });
  });
}
