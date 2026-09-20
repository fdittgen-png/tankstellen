// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'alert_notifications_blocked_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Why a price alert could not reach the user right now, or null (#4335).
///
/// Only the two answers a user can act on are surfaced —
/// [NotificationDelivery.suppressedPermission] and
/// [NotificationDelivery.suppressedChannel]. A probe that cannot answer
/// ([NotificationDelivery.failed]) is not reported as "notifications are
/// off": that would tell the user something nobody knows. The dispatcher
/// still fails closed on it; this banner stays silent.
///
/// Re-read on demand (the banner invalidates it when the app resumes, so
/// coming back from the system settings clears it).

@ProviderFor(alertNotificationsBlocked)
final alertNotificationsBlockedProvider = AlertNotificationsBlockedProvider._();

/// Why a price alert could not reach the user right now, or null (#4335).
///
/// Only the two answers a user can act on are surfaced —
/// [NotificationDelivery.suppressedPermission] and
/// [NotificationDelivery.suppressedChannel]. A probe that cannot answer
/// ([NotificationDelivery.failed]) is not reported as "notifications are
/// off": that would tell the user something nobody knows. The dispatcher
/// still fails closed on it; this banner stays silent.
///
/// Re-read on demand (the banner invalidates it when the app resumes, so
/// coming back from the system settings clears it).

final class AlertNotificationsBlockedProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationDelivery?>,
          NotificationDelivery?,
          FutureOr<NotificationDelivery?>
        >
    with
        $FutureModifier<NotificationDelivery?>,
        $FutureProvider<NotificationDelivery?> {
  /// Why a price alert could not reach the user right now, or null (#4335).
  ///
  /// Only the two answers a user can act on are surfaced —
  /// [NotificationDelivery.suppressedPermission] and
  /// [NotificationDelivery.suppressedChannel]. A probe that cannot answer
  /// ([NotificationDelivery.failed]) is not reported as "notifications are
  /// off": that would tell the user something nobody knows. The dispatcher
  /// still fails closed on it; this banner stays silent.
  ///
  /// Re-read on demand (the banner invalidates it when the app resumes, so
  /// coming back from the system settings clears it).
  AlertNotificationsBlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertNotificationsBlockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertNotificationsBlockedHash();

  @$internal
  @override
  $FutureProviderElement<NotificationDelivery?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationDelivery?> create(Ref ref) {
    return alertNotificationsBlocked(ref);
  }
}

String _$alertNotificationsBlockedHash() =>
    r'480470c1834100641c99740c58b8da1182db349f';
