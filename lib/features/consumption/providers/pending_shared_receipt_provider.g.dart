// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_shared_receipt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot stash for the file path of a receipt image an external app
/// shared into Sparkilo via the OS share sheet (#2735 / Epic #2687).
///
/// Mirrors `PendingWidgetUri` (`pending_widget_uri_provider.dart`): the
/// inbound-share listener writes the on-disk path of the shared image
/// here, the router's redirect chain consumes it to land the user on
/// `/consumption/add`, and the Add-fill-up screen consumes it again on
/// open to feed `runSharedReceiptScan` so the form is prefilled from the
/// receipt OCR.
///
/// Why a stash rather than navigating directly from the listener: on a
/// cold share (app was killed) the router has not attached its Navigator
/// when the platform reports the initial shared media, so a synchronous
/// `push` would land on an empty stack and be lost — exactly the
/// #widget-deeplink race the home-widget stash was built to remove. The
/// stash makes the destination authoritative from the first redirect
/// pass instead.
///
/// **Lifecycle**: `set(path)` writes; `consume()` returns the current
/// value and clears the field in the same call so the redirect doesn't
/// keep re-routing back to `/consumption/add`; `consumeDeferred()` is the
/// build-phase-safe variant (clears via a microtask) the router redirect
/// uses. Warm shares (app already running) flow through the same stash
/// before the listener pushes the route.

@ProviderFor(PendingSharedReceipt)
final pendingSharedReceiptProvider = PendingSharedReceiptProvider._();

/// One-shot stash for the file path of a receipt image an external app
/// shared into Sparkilo via the OS share sheet (#2735 / Epic #2687).
///
/// Mirrors `PendingWidgetUri` (`pending_widget_uri_provider.dart`): the
/// inbound-share listener writes the on-disk path of the shared image
/// here, the router's redirect chain consumes it to land the user on
/// `/consumption/add`, and the Add-fill-up screen consumes it again on
/// open to feed `runSharedReceiptScan` so the form is prefilled from the
/// receipt OCR.
///
/// Why a stash rather than navigating directly from the listener: on a
/// cold share (app was killed) the router has not attached its Navigator
/// when the platform reports the initial shared media, so a synchronous
/// `push` would land on an empty stack and be lost — exactly the
/// #widget-deeplink race the home-widget stash was built to remove. The
/// stash makes the destination authoritative from the first redirect
/// pass instead.
///
/// **Lifecycle**: `set(path)` writes; `consume()` returns the current
/// value and clears the field in the same call so the redirect doesn't
/// keep re-routing back to `/consumption/add`; `consumeDeferred()` is the
/// build-phase-safe variant (clears via a microtask) the router redirect
/// uses. Warm shares (app already running) flow through the same stash
/// before the listener pushes the route.
final class PendingSharedReceiptProvider
    extends $NotifierProvider<PendingSharedReceipt, String?> {
  /// One-shot stash for the file path of a receipt image an external app
  /// shared into Sparkilo via the OS share sheet (#2735 / Epic #2687).
  ///
  /// Mirrors `PendingWidgetUri` (`pending_widget_uri_provider.dart`): the
  /// inbound-share listener writes the on-disk path of the shared image
  /// here, the router's redirect chain consumes it to land the user on
  /// `/consumption/add`, and the Add-fill-up screen consumes it again on
  /// open to feed `runSharedReceiptScan` so the form is prefilled from the
  /// receipt OCR.
  ///
  /// Why a stash rather than navigating directly from the listener: on a
  /// cold share (app was killed) the router has not attached its Navigator
  /// when the platform reports the initial shared media, so a synchronous
  /// `push` would land on an empty stack and be lost — exactly the
  /// #widget-deeplink race the home-widget stash was built to remove. The
  /// stash makes the destination authoritative from the first redirect
  /// pass instead.
  ///
  /// **Lifecycle**: `set(path)` writes; `consume()` returns the current
  /// value and clears the field in the same call so the redirect doesn't
  /// keep re-routing back to `/consumption/add`; `consumeDeferred()` is the
  /// build-phase-safe variant (clears via a microtask) the router redirect
  /// uses. Warm shares (app already running) flow through the same stash
  /// before the listener pushes the route.
  PendingSharedReceiptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSharedReceiptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSharedReceiptHash();

  @$internal
  @override
  PendingSharedReceipt create() => PendingSharedReceipt();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingSharedReceiptHash() =>
    r'e1546bc9b9dc120716f57cea15060976f154aaf8';

/// One-shot stash for the file path of a receipt image an external app
/// shared into Sparkilo via the OS share sheet (#2735 / Epic #2687).
///
/// Mirrors `PendingWidgetUri` (`pending_widget_uri_provider.dart`): the
/// inbound-share listener writes the on-disk path of the shared image
/// here, the router's redirect chain consumes it to land the user on
/// `/consumption/add`, and the Add-fill-up screen consumes it again on
/// open to feed `runSharedReceiptScan` so the form is prefilled from the
/// receipt OCR.
///
/// Why a stash rather than navigating directly from the listener: on a
/// cold share (app was killed) the router has not attached its Navigator
/// when the platform reports the initial shared media, so a synchronous
/// `push` would land on an empty stack and be lost — exactly the
/// #widget-deeplink race the home-widget stash was built to remove. The
/// stash makes the destination authoritative from the first redirect
/// pass instead.
///
/// **Lifecycle**: `set(path)` writes; `consume()` returns the current
/// value and clears the field in the same call so the redirect doesn't
/// keep re-routing back to `/consumption/add`; `consumeDeferred()` is the
/// build-phase-safe variant (clears via a microtask) the router redirect
/// uses. Warm shares (app already running) flow through the same stash
/// before the listener pushes the route.

abstract class _$PendingSharedReceipt extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
