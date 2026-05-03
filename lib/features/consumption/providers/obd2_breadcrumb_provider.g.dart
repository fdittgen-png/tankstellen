// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_breadcrumb_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod-backed wrapper around [Obd2BreadcrumbCollector] so widgets
/// (the in-app diagnostic overlay, tests) can subscribe to fuel-rate
/// breadcrumb updates without poking the collector directly (#1395).
///
/// `keepAlive: true` because the breadcrumbs are most useful AFTER
/// the trip ends (the user opens the overlay to inspect the trace
/// that produced a suspicious L/100 km figure on the summary). An
/// auto-disposing provider would throw the trace away the moment the
/// recording screen popped, defeating the diagnostic purpose.
///
/// The notifier implements [Obd2BreadcrumbRecorder] so the trip
/// recording controller and [Obd2Service] can write through ONE
/// reference and have every push republish the (immutable) entries
/// list to the overlay listeners. Tests that don't need Riverpod
/// reach for the raw [Obd2BreadcrumbCollector] instead.

@ProviderFor(Obd2BreadcrumbsNotifier)
final obd2BreadcrumbsProvider = Obd2BreadcrumbsNotifierProvider._();

/// Riverpod-backed wrapper around [Obd2BreadcrumbCollector] so widgets
/// (the in-app diagnostic overlay, tests) can subscribe to fuel-rate
/// breadcrumb updates without poking the collector directly (#1395).
///
/// `keepAlive: true` because the breadcrumbs are most useful AFTER
/// the trip ends (the user opens the overlay to inspect the trace
/// that produced a suspicious L/100 km figure on the summary). An
/// auto-disposing provider would throw the trace away the moment the
/// recording screen popped, defeating the diagnostic purpose.
///
/// The notifier implements [Obd2BreadcrumbRecorder] so the trip
/// recording controller and [Obd2Service] can write through ONE
/// reference and have every push republish the (immutable) entries
/// list to the overlay listeners. Tests that don't need Riverpod
/// reach for the raw [Obd2BreadcrumbCollector] instead.
final class Obd2BreadcrumbsNotifierProvider
    extends $NotifierProvider<Obd2BreadcrumbsNotifier, List<Obd2Breadcrumb>> {
  /// Riverpod-backed wrapper around [Obd2BreadcrumbCollector] so widgets
  /// (the in-app diagnostic overlay, tests) can subscribe to fuel-rate
  /// breadcrumb updates without poking the collector directly (#1395).
  ///
  /// `keepAlive: true` because the breadcrumbs are most useful AFTER
  /// the trip ends (the user opens the overlay to inspect the trace
  /// that produced a suspicious L/100 km figure on the summary). An
  /// auto-disposing provider would throw the trace away the moment the
  /// recording screen popped, defeating the diagnostic purpose.
  ///
  /// The notifier implements [Obd2BreadcrumbRecorder] so the trip
  /// recording controller and [Obd2Service] can write through ONE
  /// reference and have every push republish the (immutable) entries
  /// list to the overlay listeners. Tests that don't need Riverpod
  /// reach for the raw [Obd2BreadcrumbCollector] instead.
  Obd2BreadcrumbsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2BreadcrumbsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2BreadcrumbsNotifierHash();

  @$internal
  @override
  Obd2BreadcrumbsNotifier create() => Obd2BreadcrumbsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Obd2Breadcrumb> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Obd2Breadcrumb>>(value),
    );
  }
}

String _$obd2BreadcrumbsNotifierHash() =>
    r'f66a7552ca877b9aab8eee2e9af4eb5ac42921de';

/// Riverpod-backed wrapper around [Obd2BreadcrumbCollector] so widgets
/// (the in-app diagnostic overlay, tests) can subscribe to fuel-rate
/// breadcrumb updates without poking the collector directly (#1395).
///
/// `keepAlive: true` because the breadcrumbs are most useful AFTER
/// the trip ends (the user opens the overlay to inspect the trace
/// that produced a suspicious L/100 km figure on the summary). An
/// auto-disposing provider would throw the trace away the moment the
/// recording screen popped, defeating the diagnostic purpose.
///
/// The notifier implements [Obd2BreadcrumbRecorder] so the trip
/// recording controller and [Obd2Service] can write through ONE
/// reference and have every push republish the (immutable) entries
/// list to the overlay listeners. Tests that don't need Riverpod
/// reach for the raw [Obd2BreadcrumbCollector] instead.

abstract class _$Obd2BreadcrumbsNotifier
    extends $Notifier<List<Obd2Breadcrumb>> {
  List<Obd2Breadcrumb> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Obd2Breadcrumb>, List<Obd2Breadcrumb>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Obd2Breadcrumb>, List<Obd2Breadcrumb>>,
              List<Obd2Breadcrumb>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
