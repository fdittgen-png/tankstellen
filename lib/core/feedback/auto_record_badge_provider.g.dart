// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_record_badge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Process-wide singleton for the auto-record badge counter
/// (#1004 phase 5).
///
/// `keepAlive` because the badge needs to stay coherent for the
/// lifetime of the app — the trip-save path may call `increment`
/// from a background isolate hand-off and the detail screen may
/// `decrement` minutes later. Re-creating the service per-route
/// would lose in-flight writes.
///
/// Returned as `AsyncValue<AutoRecordBadgeService>` because resolving
/// `SharedPreferences` is asynchronous. Callers that need immediate
/// access should await the future; UI consumers can `when` over it.

@ProviderFor(autoRecordBadgeService)
final autoRecordBadgeServiceProvider = AutoRecordBadgeServiceProvider._();

/// Process-wide singleton for the auto-record badge counter
/// (#1004 phase 5).
///
/// `keepAlive` because the badge needs to stay coherent for the
/// lifetime of the app — the trip-save path may call `increment`
/// from a background isolate hand-off and the detail screen may
/// `decrement` minutes later. Re-creating the service per-route
/// would lose in-flight writes.
///
/// Returned as `AsyncValue<AutoRecordBadgeService>` because resolving
/// `SharedPreferences` is asynchronous. Callers that need immediate
/// access should await the future; UI consumers can `when` over it.

final class AutoRecordBadgeServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<AutoRecordBadgeService>,
          AutoRecordBadgeService,
          FutureOr<AutoRecordBadgeService>
        >
    with
        $FutureModifier<AutoRecordBadgeService>,
        $FutureProvider<AutoRecordBadgeService> {
  /// Process-wide singleton for the auto-record badge counter
  /// (#1004 phase 5).
  ///
  /// `keepAlive` because the badge needs to stay coherent for the
  /// lifetime of the app — the trip-save path may call `increment`
  /// from a background isolate hand-off and the detail screen may
  /// `decrement` minutes later. Re-creating the service per-route
  /// would lose in-flight writes.
  ///
  /// Returned as `AsyncValue<AutoRecordBadgeService>` because resolving
  /// `SharedPreferences` is asynchronous. Callers that need immediate
  /// access should await the future; UI consumers can `when` over it.
  AutoRecordBadgeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordBadgeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordBadgeServiceHash();

  @$internal
  @override
  $FutureProviderElement<AutoRecordBadgeService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AutoRecordBadgeService> create(Ref ref) {
    return autoRecordBadgeService(ref);
  }
}

String _$autoRecordBadgeServiceHash() =>
    r'3b635790f0a15f6020ccbc4dfe696ed021b76bf3';

/// Reactive counter mirroring [AutoRecordBadgeService.count] for UI
/// consumers (#1004 phase 6). The service writes to
/// `SharedPreferences` synchronously but does not notify; this
/// provider re-reads the value on demand and on `markAllAsRead`
/// invocations so the trip-history AppBar badge stays in step with
/// the launcher icon.

@ProviderFor(AutoRecordBadgeCount)
final autoRecordBadgeCountProvider = AutoRecordBadgeCountProvider._();

/// Reactive counter mirroring [AutoRecordBadgeService.count] for UI
/// consumers (#1004 phase 6). The service writes to
/// `SharedPreferences` synchronously but does not notify; this
/// provider re-reads the value on demand and on `markAllAsRead`
/// invocations so the trip-history AppBar badge stays in step with
/// the launcher icon.
final class AutoRecordBadgeCountProvider
    extends $NotifierProvider<AutoRecordBadgeCount, int> {
  /// Reactive counter mirroring [AutoRecordBadgeService.count] for UI
  /// consumers (#1004 phase 6). The service writes to
  /// `SharedPreferences` synchronously but does not notify; this
  /// provider re-reads the value on demand and on `markAllAsRead`
  /// invocations so the trip-history AppBar badge stays in step with
  /// the launcher icon.
  AutoRecordBadgeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordBadgeCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordBadgeCountHash();

  @$internal
  @override
  AutoRecordBadgeCount create() => AutoRecordBadgeCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$autoRecordBadgeCountHash() =>
    r'c5a24468db696e7f608480933646d490dcb5e09f';

/// Reactive counter mirroring [AutoRecordBadgeService.count] for UI
/// consumers (#1004 phase 6). The service writes to
/// `SharedPreferences` synchronously but does not notify; this
/// provider re-reads the value on demand and on `markAllAsRead`
/// invocations so the trip-history AppBar badge stays in step with
/// the launcher icon.

abstract class _$AutoRecordBadgeCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
