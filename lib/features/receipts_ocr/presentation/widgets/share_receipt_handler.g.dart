// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'share_receipt_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device PDF→bitmap rasteriser the handler feeds shared PDFs through
/// (#2737). Exposed as its own provider so a test can override it with a fake
/// — the native PdfRenderer is unavailable under `flutter test`.

@ProviderFor(receiptPdfRasterizer)
final receiptPdfRasterizerProvider = ReceiptPdfRasterizerProvider._();

/// The on-device PDF→bitmap rasteriser the handler feeds shared PDFs through
/// (#2737). Exposed as its own provider so a test can override it with a fake
/// — the native PdfRenderer is unavailable under `flutter test`.

final class ReceiptPdfRasterizerProvider
    extends
        $FunctionalProvider<
          ReceiptPdfRasterizer,
          ReceiptPdfRasterizer,
          ReceiptPdfRasterizer
        >
    with $Provider<ReceiptPdfRasterizer> {
  /// The on-device PDF→bitmap rasteriser the handler feeds shared PDFs through
  /// (#2737). Exposed as its own provider so a test can override it with a fake
  /// — the native PdfRenderer is unavailable under `flutter test`.
  ReceiptPdfRasterizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptPdfRasterizerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptPdfRasterizerHash();

  @$internal
  @override
  $ProviderElement<ReceiptPdfRasterizer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptPdfRasterizer create(Ref ref) {
    return receiptPdfRasterizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptPdfRasterizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptPdfRasterizer>(value),
    );
  }
}

String _$receiptPdfRasterizerHash() =>
    r'2df5feaa52d0f68a13a24268105a7da6914d8dce';

/// #4381 — `keepAlive`: [ShareReceiptHandler] retains this `Ref` and uses it
/// *after* an `await` on the shared-PDF path (`_rasterizeAndRoute` →
/// `_stashAndRoute`). The only caller reads the handler without listening
/// (`ref.read(...).handle(intent)` from the share listener), so an
/// auto-dispose element is torn down while the rasterisation is still in
/// flight and the stash + route silently degrades to "couldn't read the
/// receipt". The handler is a stateless router over app-lifetime providers,
/// so matching the listener's lifetime is the correct scope.

@ProviderFor(shareReceiptHandler)
final shareReceiptHandlerProvider = ShareReceiptHandlerProvider._();

/// #4381 — `keepAlive`: [ShareReceiptHandler] retains this `Ref` and uses it
/// *after* an `await` on the shared-PDF path (`_rasterizeAndRoute` →
/// `_stashAndRoute`). The only caller reads the handler without listening
/// (`ref.read(...).handle(intent)` from the share listener), so an
/// auto-dispose element is torn down while the rasterisation is still in
/// flight and the stash + route silently degrades to "couldn't read the
/// receipt". The handler is a stateless router over app-lifetime providers,
/// so matching the listener's lifetime is the correct scope.

final class ShareReceiptHandlerProvider
    extends
        $FunctionalProvider<
          ShareReceiptHandler,
          ShareReceiptHandler,
          ShareReceiptHandler
        >
    with $Provider<ShareReceiptHandler> {
  /// #4381 — `keepAlive`: [ShareReceiptHandler] retains this `Ref` and uses it
  /// *after* an `await` on the shared-PDF path (`_rasterizeAndRoute` →
  /// `_stashAndRoute`). The only caller reads the handler without listening
  /// (`ref.read(...).handle(intent)` from the share listener), so an
  /// auto-dispose element is torn down while the rasterisation is still in
  /// flight and the stash + route silently degrades to "couldn't read the
  /// receipt". The handler is a stateless router over app-lifetime providers,
  /// so matching the listener's lifetime is the correct scope.
  ShareReceiptHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareReceiptHandlerProvider',
        isAutoDispose: false,
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
    r'91c49b7e7e9c33d269921e7ab3d9bf62c3bd5b46';
