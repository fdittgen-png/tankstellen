import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station_type_filter.dart';
import 'package:tankstellen/features/search/providers/station_type_filter_provider.dart';

/// Tests for [ActiveStationTypeFilter] — the fuel-vs-EV toggle for the
/// search screen. The notifier is `keepAlive: true` so a user's toggle
/// choice survives the "nobody is listening" gap when the search tab is
/// backgrounded (see #550-style auto-dispose regressions).
void main() {
  ProviderContainer createContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('ActiveStationTypeFilter.build', () {
    test('defaults to fuel (not EV) on a fresh install', () {
      // Fresh-install default. If this ever flips to EV, the Tankerkoenig
      // dispatcher test suite silently stops driving its happy path — so
      // keep the assertion explicit.
      final container = createContainer();
      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.fuel,
      );
    });
  });

  group('ActiveStationTypeFilter.set', () {
    test('switches to EV when requested', () {
      final container = createContainer();

      container
          .read(activeStationTypeFilterProvider.notifier)
          .set(StationTypeFilter.ev);

      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.ev,
      );
    });

    test('can toggle between fuel and EV repeatedly', () {
      final container = createContainer();
      final notifier = container.read(activeStationTypeFilterProvider.notifier);

      notifier.set(StationTypeFilter.ev);
      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.ev,
      );

      notifier.set(StationTypeFilter.fuel);
      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.fuel,
      );

      notifier.set(StationTypeFilter.ev);
      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.ev,
      );
    });

    test('setting the same value twice is idempotent', () {
      final container = createContainer();
      final notifier = container.read(activeStationTypeFilterProvider.notifier);

      notifier.set(StationTypeFilter.ev);
      notifier.set(StationTypeFilter.ev);

      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.ev,
      );
    });
  });

  group('ActiveStationTypeFilter keepAlive semantics', () {
    test('two reads without an active listener return the SAME notifier', () {
      // Guards against a regression where someone drops the
      // `keepAlive: true` — dropping it would auto-dispose the notifier
      // between reads and reset the filter back to fuel mid-session.
      final container = createContainer();
      final first = container.read(activeStationTypeFilterProvider.notifier);

      // No .watch / .listen in between — just a second read.
      final second = container.read(activeStationTypeFilterProvider.notifier);

      expect(identical(first, second), isTrue);
    });

    test('state survives across reads after an explicit set', () {
      final container = createContainer();
      container
          .read(activeStationTypeFilterProvider.notifier)
          .set(StationTypeFilter.ev);

      // Read again — on an auto-dispose notifier the state would reset.
      expect(
        container.read(activeStationTypeFilterProvider),
        StationTypeFilter.ev,
      );
    });
  });

  group('StationTypeFilter enum', () {
    test('contains exactly fuel and ev values', () {
      // Surfaces the contract the search dispatcher and UI rely on:
      // adding a third station type needs an explicit decision about
      // which dispatcher path handles it, not a silent expansion.
      expect(
        StationTypeFilter.values,
        containsAll([StationTypeFilter.fuel, StationTypeFilter.ev]),
      );
      expect(StationTypeFilter.values.length, 2);
    });
  });
}
