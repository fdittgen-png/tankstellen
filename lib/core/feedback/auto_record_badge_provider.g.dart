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
