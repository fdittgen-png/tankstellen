// GENERATED CODE - DO NOT MODIFY BY HAND

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
    r'9093dfdd33d210bd3c7228d57debf3f56606d7e3';
