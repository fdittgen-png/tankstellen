// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the app-wide [NotificationService] instance.
///
/// Kept alive for the entire app lifetime because the notification subsystem
/// is initialized once in `main()` and reused by background tasks and UI.
/// Defaults to [LocalNotificationService]; override in tests or when
/// adding FCM support.

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

/// Provides the app-wide [NotificationService] instance.
///
/// Kept alive for the entire app lifetime because the notification subsystem
/// is initialized once in `main()` and reused by background tasks and UI.
/// Defaults to [LocalNotificationService]; override in tests or when
/// adding FCM support.

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  /// Provides the app-wide [NotificationService] instance.
  ///
  /// Kept alive for the entire app lifetime because the notification subsystem
  /// is initialized once in `main()` and reused by background tasks and UI.
  /// Defaults to [LocalNotificationService]; override in tests or when
  /// adding FCM support.
  NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'445de4d12e27916d07943435c5c5a66cb7fc0205';
