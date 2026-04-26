import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/telemetry/collectors/app_state_collector.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/integrations/navigation_trace_observer.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

/// Minimal storage repo so AppStateCollector.collect doesn't fail when reading
/// the active profile.
class _NullStorage implements StorageRepository {
  @override
  String? getActiveProfileId() => null;

  @override
  Map<String, dynamic>? getProfile(String id) => null;

  @override
  noSuchMethod(Invocation invocation) => null;
}

Route<dynamic> _route(String? name) => MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: name),
      builder: (_) => const SizedBox.shrink(),
    );

void main() {
  late ProviderContainer container;
  late Ref ref;

  setUp(() {
    BreadcrumbCollector.clear();
    AppStateCollector.updateRoute('');

    container = ProviderContainer(overrides: [
      storageRepositoryProvider.overrideWithValue(_NullStorage()),
    ]);
    final refCapture = Provider<int>((r) {
      ref = r;
      return 0;
    });
    container.read(refCapture);
  });

  tearDown(() => container.dispose());

  group('NavigationTraceObserver', () {
    test('didPush updates active route + records navigate breadcrumb', () {
      final observer = NavigationTraceObserver();

      observer.didPush(_route('home'), null);

      expect(AppStateCollector.collect(ref).activeRoute, 'home');
      final breadcrumbs = BreadcrumbCollector.snapshot();
      expect(breadcrumbs, hasLength(1));
      expect(breadcrumbs.first.action, 'navigate:home');
    });

    test('didPush with null name defaults to "unknown"', () {
      final observer = NavigationTraceObserver();

      observer.didPush(_route(null), null);

      expect(AppStateCollector.collect(ref).activeRoute, 'unknown');
      expect(BreadcrumbCollector.snapshot().last.action, 'navigate:unknown');
    });

    test('didReplace tracks newRoute when present', () {
      final observer = NavigationTraceObserver();

      observer.didReplace(
        newRoute: _route('settings'),
        oldRoute: _route('home'),
      );

      expect(AppStateCollector.collect(ref).activeRoute, 'settings');
      expect(BreadcrumbCollector.snapshot().last.action, 'navigate:settings');
    });

    test('didReplace with newRoute=null is a no-op', () {
      final observer = NavigationTraceObserver();
      // Seed a known route via didPush so we can detect a leak.
      observer.didPush(_route('seeded'), null);
      final breadcrumbCountAfterSeed = BreadcrumbCollector.snapshot().length;

      observer.didReplace(newRoute: null, oldRoute: _route('home'));

      // Active route unchanged; no new breadcrumb added.
      expect(AppStateCollector.collect(ref).activeRoute, 'seeded');
      expect(
        BreadcrumbCollector.snapshot().length,
        breadcrumbCountAfterSeed,
      );
    });

    test('didPop tracks the previous route', () {
      final observer = NavigationTraceObserver();

      observer.didPop(_route('detail'), _route('list'));

      expect(AppStateCollector.collect(ref).activeRoute, 'list');
      expect(BreadcrumbCollector.snapshot().last.action, 'navigate:list');
    });

    test('didPop with previousRoute=null is a no-op', () {
      final observer = NavigationTraceObserver();
      observer.didPush(_route('seeded'), null);
      final beforeLen = BreadcrumbCollector.snapshot().length;

      observer.didPop(_route('detail'), null);

      expect(AppStateCollector.collect(ref).activeRoute, 'seeded');
      expect(BreadcrumbCollector.snapshot().length, beforeLen);
    });

    test('didPop with anonymous previousRoute defaults to "unknown"', () {
      final observer = NavigationTraceObserver();

      observer.didPop(_route('detail'), _route(null));

      expect(AppStateCollector.collect(ref).activeRoute, 'unknown');
      expect(BreadcrumbCollector.snapshot().last.action, 'navigate:unknown');
    });
  });
}
