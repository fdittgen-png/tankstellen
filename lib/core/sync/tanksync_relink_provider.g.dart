// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'tanksync_relink_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether TankSync's stored identity needs re-linking — the owner of
/// `SyncConfig.relinkRequired` (#4338).
///
/// The flag used to live only on the `SyncConfig` object `SyncState`
/// published by hand, and `SyncState.build` never set it: the next
/// rebuild — a consent save, a storage swap, an `invalidate` — dropped it
/// while the session was still gone, and the re-link guidance vanished.
///
/// **Why keepAlive, and why not persisted.** It must outlive every rebuild
/// of `SyncState` in this process, so it cannot live inside it. It must
/// NOT outlive the process: whether a session is missing is re-derived at
/// every launch by the #3449 identity guard from what is actually on the
/// device, and a persisted flag would go stale the moment the keychain or
/// the settings changed underneath it (a restore, a reinstall).
///
/// Writers: the launch guard and the session gate's `signedOut` hook mark
/// it; an email sign-in, "start fresh" and disconnect clear it.

@ProviderFor(TankSyncRelink)
final tankSyncRelinkProvider = TankSyncRelinkProvider._();

/// Whether TankSync's stored identity needs re-linking — the owner of
/// `SyncConfig.relinkRequired` (#4338).
///
/// The flag used to live only on the `SyncConfig` object `SyncState`
/// published by hand, and `SyncState.build` never set it: the next
/// rebuild — a consent save, a storage swap, an `invalidate` — dropped it
/// while the session was still gone, and the re-link guidance vanished.
///
/// **Why keepAlive, and why not persisted.** It must outlive every rebuild
/// of `SyncState` in this process, so it cannot live inside it. It must
/// NOT outlive the process: whether a session is missing is re-derived at
/// every launch by the #3449 identity guard from what is actually on the
/// device, and a persisted flag would go stale the moment the keychain or
/// the settings changed underneath it (a restore, a reinstall).
///
/// Writers: the launch guard and the session gate's `signedOut` hook mark
/// it; an email sign-in, "start fresh" and disconnect clear it.
final class TankSyncRelinkProvider
    extends $NotifierProvider<TankSyncRelink, bool> {
  /// Whether TankSync's stored identity needs re-linking — the owner of
  /// `SyncConfig.relinkRequired` (#4338).
  ///
  /// The flag used to live only on the `SyncConfig` object `SyncState`
  /// published by hand, and `SyncState.build` never set it: the next
  /// rebuild — a consent save, a storage swap, an `invalidate` — dropped it
  /// while the session was still gone, and the re-link guidance vanished.
  ///
  /// **Why keepAlive, and why not persisted.** It must outlive every rebuild
  /// of `SyncState` in this process, so it cannot live inside it. It must
  /// NOT outlive the process: whether a session is missing is re-derived at
  /// every launch by the #3449 identity guard from what is actually on the
  /// device, and a persisted flag would go stale the moment the keychain or
  /// the settings changed underneath it (a restore, a reinstall).
  ///
  /// Writers: the launch guard and the session gate's `signedOut` hook mark
  /// it; an email sign-in, "start fresh" and disconnect clear it.
  TankSyncRelinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tankSyncRelinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tankSyncRelinkHash();

  @$internal
  @override
  TankSyncRelink create() => TankSyncRelink();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tankSyncRelinkHash() => r'192ecc31d244dbb91bd2ce1875136f46fabe9d7f';

/// Whether TankSync's stored identity needs re-linking — the owner of
/// `SyncConfig.relinkRequired` (#4338).
///
/// The flag used to live only on the `SyncConfig` object `SyncState`
/// published by hand, and `SyncState.build` never set it: the next
/// rebuild — a consent save, a storage swap, an `invalidate` — dropped it
/// while the session was still gone, and the re-link guidance vanished.
///
/// **Why keepAlive, and why not persisted.** It must outlive every rebuild
/// of `SyncState` in this process, so it cannot live inside it. It must
/// NOT outlive the process: whether a session is missing is re-derived at
/// every launch by the #3449 identity guard from what is actually on the
/// device, and a persisted flag would go stale the moment the keychain or
/// the settings changed underneath it (a restore, a reinstall).
///
/// Writers: the launch guard and the session gate's `signedOut` hook mark
/// it; an email sign-in, "start fresh" and disconnect clear it.

abstract class _$TankSyncRelink extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
