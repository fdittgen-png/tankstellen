// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_receipt_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shareReceiptHandler)
final shareReceiptHandlerProvider = ShareReceiptHandlerProvider._();

final class ShareReceiptHandlerProvider
    extends
        $FunctionalProvider<
          ShareReceiptHandler,
          ShareReceiptHandler,
          ShareReceiptHandler
        >
    with $Provider<ShareReceiptHandler> {
  ShareReceiptHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareReceiptHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareReceiptHandlerHash();

  @$internal
  @override
  $ProviderElement<ShareReceiptHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareReceiptHandler create(Ref ref) {
    return shareReceiptHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareReceiptHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareReceiptHandler>(value),
    );
  }
}

String _$shareReceiptHandlerHash() =>
    r'5f4b3c537a335a72ba795dcf8d2f928b8dc58fe9';
