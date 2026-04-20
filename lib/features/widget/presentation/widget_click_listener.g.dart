// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_click_listener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(widgetLaunchHandler)
final widgetLaunchHandlerProvider = WidgetLaunchHandlerProvider._();

final class WidgetLaunchHandlerProvider
    extends
        $FunctionalProvider<
          WidgetLaunchHandler,
          WidgetLaunchHandler,
          WidgetLaunchHandler
        >
    with $Provider<WidgetLaunchHandler> {
  WidgetLaunchHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetLaunchHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetLaunchHandlerHash();

  @$internal
  @override
  $ProviderElement<WidgetLaunchHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WidgetLaunchHandler create(Ref ref) {
    return widgetLaunchHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WidgetLaunchHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WidgetLaunchHandler>(value),
    );
  }
}

String _$widgetLaunchHandlerHash() =>
    r'259f9b333bd7222fdc6f1ca6fafd5841f6314dfb';
