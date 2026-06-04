// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_shared_receipt_text_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot stash for the [ReceiptParseResult] of an e-receipt **text** an
/// external app shared into Sparkilo (#2735 + #2838 / Epic #2687).
///
/// The text sibling of [pendingSharedReceiptProvider]. An image / PDF share
/// stashes a file PATH that the Add-fill-up screen OCRs on open; a shared
/// text body, by contrast, is parsed by the pure-Dart [EReceiptTextParser]
/// in the share handler at receive time — there is no file to OCR — so the
/// already-parsed result is what gets stashed here. The Add-fill-up screen
/// consumes it on open and prefills the form through the SAME
/// `applyReceiptOutcome` body the camera / image-share paths use, so a text
/// receipt fills the form with zero prefill drift.
///
/// **Lifecycle** mirrors the path stash: `set(result)` writes;
/// `consumeDeferred()` returns the value and clears via a microtask so it is
/// safe to call from the screen's `initState` (a Riverpod-locked phase).

@ProviderFor(PendingSharedReceiptText)
final pendingSharedReceiptTextProvider = PendingSharedReceiptTextProvider._();

/// One-shot stash for the [ReceiptParseResult] of an e-receipt **text** an
/// external app shared into Sparkilo (#2735 + #2838 / Epic #2687).
///
/// The text sibling of [pendingSharedReceiptProvider]. An image / PDF share
/// stashes a file PATH that the Add-fill-up screen OCRs on open; a shared
/// text body, by contrast, is parsed by the pure-Dart [EReceiptTextParser]
/// in the share handler at receive time — there is no file to OCR — so the
/// already-parsed result is what gets stashed here. The Add-fill-up screen
/// consumes it on open and prefills the form through the SAME
/// `applyReceiptOutcome` body the camera / image-share paths use, so a text
/// receipt fills the form with zero prefill drift.
///
/// **Lifecycle** mirrors the path stash: `set(result)` writes;
/// `consumeDeferred()` returns the value and clears via a microtask so it is
/// safe to call from the screen's `initState` (a Riverpod-locked phase).
final class PendingSharedReceiptTextProvider
    extends $NotifierProvider<PendingSharedReceiptText, ReceiptParseResult?> {
  /// One-shot stash for the [ReceiptParseResult] of an e-receipt **text** an
  /// external app shared into Sparkilo (#2735 + #2838 / Epic #2687).
  ///
  /// The text sibling of [pendingSharedReceiptProvider]. An image / PDF share
  /// stashes a file PATH that the Add-fill-up screen OCRs on open; a shared
  /// text body, by contrast, is parsed by the pure-Dart [EReceiptTextParser]
  /// in the share handler at receive time — there is no file to OCR — so the
  /// already-parsed result is what gets stashed here. The Add-fill-up screen
  /// consumes it on open and prefills the form through the SAME
  /// `applyReceiptOutcome` body the camera / image-share paths use, so a text
  /// receipt fills the form with zero prefill drift.
  ///
  /// **Lifecycle** mirrors the path stash: `set(result)` writes;
  /// `consumeDeferred()` returns the value and clears via a microtask so it is
  /// safe to call from the screen's `initState` (a Riverpod-locked phase).
  PendingSharedReceiptTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSharedReceiptTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSharedReceiptTextHash();

  @$internal
  @override
  PendingSharedReceiptText create() => PendingSharedReceiptText();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptParseResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptParseResult?>(value),
    );
  }
}

String _$pendingSharedReceiptTextHash() =>
    r'b8e66951cc26c0ca44d1bd4624bc500a3127d212';

/// One-shot stash for the [ReceiptParseResult] of an e-receipt **text** an
/// external app shared into Sparkilo (#2735 + #2838 / Epic #2687).
///
/// The text sibling of [pendingSharedReceiptProvider]. An image / PDF share
/// stashes a file PATH that the Add-fill-up screen OCRs on open; a shared
/// text body, by contrast, is parsed by the pure-Dart [EReceiptTextParser]
/// in the share handler at receive time — there is no file to OCR — so the
/// already-parsed result is what gets stashed here. The Add-fill-up screen
/// consumes it on open and prefills the form through the SAME
/// `applyReceiptOutcome` body the camera / image-share paths use, so a text
/// receipt fills the form with zero prefill drift.
///
/// **Lifecycle** mirrors the path stash: `set(result)` writes;
/// `consumeDeferred()` returns the value and clears via a microtask so it is
/// safe to call from the screen's `initState` (a Riverpod-locked phase).

abstract class _$PendingSharedReceiptText
    extends $Notifier<ReceiptParseResult?> {
  ReceiptParseResult? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReceiptParseResult?, ReceiptParseResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReceiptParseResult?, ReceiptParseResult?>,
              ReceiptParseResult?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
