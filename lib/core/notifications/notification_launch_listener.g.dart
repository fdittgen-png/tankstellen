// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_launch_listener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationLaunchHandler)
final notificationLaunchHandlerProvider = NotificationLaunchHandlerProvider._();

final class NotificationLaunchHandlerProvider
    extends
        $FunctionalProvider<
          NotificationLaunchHandler,
          NotificationLaunchHandler,
          NotificationLaunchHandler
        >
    with $Provider<NotificationLaunchHandler> {
  NotificationLaunchHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationLaunchHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationLaunchHandlerHash();

  @$internal
  @override
  $ProviderElement<NotificationLaunchHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationLaunchHandler create(Ref ref) {
    return notificationLaunchHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationLaunchHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationLaunchHandler>(value),
    );
  }
}

String _$notificationLaunchHandlerHash() =>
    r'129376e80e3fb853ea26a0775cde05ea75698515';
