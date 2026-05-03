// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_breadcrumb_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod-backed wrapper around [MapBreadcrumbCollector] so widgets
/// (the in-app debug overlay, tests) can subscribe to breadcrumb
/// updates without poking the collector directly (#1316 phase 2).
///
/// `keepAlive: true` because the breadcrumbs are most useful on cold
/// start, BEFORE any consumer mounts — auto-disposing on listener-zero
/// would throw away the very first frame's trace.

@ProviderFor(MapBreadcrumbsNotifier)
final mapBreadcrumbsProvider = MapBreadcrumbsNotifierProvider._();

/// Riverpod-backed wrapper around [MapBreadcrumbCollector] so widgets
/// (the in-app debug overlay, tests) can subscribe to breadcrumb
/// updates without poking the collector directly (#1316 phase 2).
///
/// `keepAlive: true` because the breadcrumbs are most useful on cold
/// start, BEFORE any consumer mounts — auto-disposing on listener-zero
/// would throw away the very first frame's trace.
final class MapBreadcrumbsNotifierProvider
    extends $NotifierProvider<MapBreadcrumbsNotifier, List<MapBreadcrumb>> {
  /// Riverpod-backed wrapper around [MapBreadcrumbCollector] so widgets
  /// (the in-app debug overlay, tests) can subscribe to breadcrumb
  /// updates without poking the collector directly (#1316 phase 2).
  ///
  /// `keepAlive: true` because the breadcrumbs are most useful on cold
  /// start, BEFORE any consumer mounts — auto-disposing on listener-zero
  /// would throw away the very first frame's trace.
  MapBreadcrumbsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapBreadcrumbsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapBreadcrumbsNotifierHash();

  @$internal
  @override
  MapBreadcrumbsNotifier create() => MapBreadcrumbsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MapBreadcrumb> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MapBreadcrumb>>(value),
    );
  }
}

String _$mapBreadcrumbsNotifierHash() =>
    r'141adda9d0f60f76e378b620c05a2b4b9cd545f7';

/// Riverpod-backed wrapper around [MapBreadcrumbCollector] so widgets
/// (the in-app debug overlay, tests) can subscribe to breadcrumb
/// updates without poking the collector directly (#1316 phase 2).
///
/// `keepAlive: true` because the breadcrumbs are most useful on cold
/// start, BEFORE any consumer mounts — auto-disposing on listener-zero
/// would throw away the very first frame's trace.

abstract class _$MapBreadcrumbsNotifier extends $Notifier<List<MapBreadcrumb>> {
  List<MapBreadcrumb> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<MapBreadcrumb>, List<MapBreadcrumb>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<MapBreadcrumb>, List<MapBreadcrumb>>,
              List<MapBreadcrumb>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
