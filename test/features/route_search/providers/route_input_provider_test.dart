import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('RouteInputController.build', () {
    test('default state: no coords, no stops, not searching', () {
      final c = makeContainer();
      final s = c.read(routeInputControllerProvider);
      expect(s.startCoords, isNull);
      expect(s.endCoords, isNull);
      expect(s.stopCoords, isEmpty);
      expect(s.stopCount, 0);
      expect(s.isSearching, isFalse);
    });
  });

  group('start/end coords', () {
    test('setStartCoords saves the coord', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.setStartCoords(const LatLng(48.85, 2.35));
      expect(c.read(routeInputControllerProvider).startCoords,
          const LatLng(48.85, 2.35));
    });

    test('setStartCoords(null) clears the coord', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.setStartCoords(const LatLng(1, 2));
      n.setStartCoords(null);
      expect(c.read(routeInputControllerProvider).startCoords, isNull);
    });

    test('setEndCoords is independent of setStartCoords', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.setStartCoords(const LatLng(1, 2));
      n.setEndCoords(const LatLng(3, 4));
      final s = c.read(routeInputControllerProvider);
      expect(s.startCoords, const LatLng(1, 2));
      expect(s.endCoords, const LatLng(3, 4));
    });

    test('setEndCoords(null) clears only the end', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.setStartCoords(const LatLng(1, 2));
      n.setEndCoords(const LatLng(3, 4));
      n.setEndCoords(null);
      final s = c.read(routeInputControllerProvider);
      expect(s.startCoords, const LatLng(1, 2));
      expect(s.endCoords, isNull);
    });
  });

  group('stops', () {
    test('addStop appends a null slot and increments stopCount', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.addStop();
      n.addStop();
      final s = c.read(routeInputControllerProvider);
      expect(s.stopCoords, hasLength(2));
      expect(s.stopCount, 2);
      expect(s.stopCoords.every((e) => e == null), isTrue);
    });

    test('setStopCoord fills in a previously-empty slot', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.addStop();
      n.addStop();
      n.setStopCoord(1, const LatLng(42, 10));
      final s = c.read(routeInputControllerProvider);
      expect(s.stopCoords[0], isNull);
      expect(s.stopCoords[1], const LatLng(42, 10));
    });

    test('setStopCoord on an out-of-range index is a no-op', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.addStop();
      n.setStopCoord(5, const LatLng(0, 0));
      expect(c.read(routeInputControllerProvider).stopCoords, [null]);
    });

    test('removeStop deletes the slot and decrements stopCount', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.addStop();
      n.addStop();
      n.setStopCoord(0, const LatLng(1, 1));
      n.setStopCoord(1, const LatLng(2, 2));
      n.removeStop(0);
      final s = c.read(routeInputControllerProvider);
      expect(s.stopCoords, [const LatLng(2, 2)]);
      expect(s.stopCount, 1);
    });

    test('removeStop on an out-of-range index is a no-op', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.addStop();
      n.removeStop(-1);
      n.removeStop(99);
      expect(c.read(routeInputControllerProvider).stopCount, 1);
      expect(c.read(routeInputControllerProvider).stopCoords, hasLength(1));
    });
  });

  group('searching flag + reset', () {
    test('setSearching flips the flag', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.setSearching(true);
      expect(c.read(routeInputControllerProvider).isSearching, isTrue);
      n.setSearching(false);
      expect(c.read(routeInputControllerProvider).isSearching, isFalse);
    });

    test('reset returns to the default state, wiping every field', () {
      final c = makeContainer();
      final n = c.read(routeInputControllerProvider.notifier);
      n.setStartCoords(const LatLng(1, 2));
      n.setEndCoords(const LatLng(3, 4));
      n.addStop();
      n.setSearching(true);
      n.reset();
      final s = c.read(routeInputControllerProvider);
      expect(s.startCoords, isNull);
      expect(s.endCoords, isNull);
      expect(s.stopCoords, isEmpty);
      expect(s.stopCount, 0);
      expect(s.isSearching, isFalse);
    });
  });
}
