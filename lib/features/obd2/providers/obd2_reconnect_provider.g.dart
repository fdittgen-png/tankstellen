// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_reconnect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
/// Epic #3013 phase 3), backed by the Hive `settings` box.

@ProviderFor(lastGoodAdapterStore)
final lastGoodAdapterStoreProvider = LastGoodAdapterStoreProvider._();

/// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
/// Epic #3013 phase 3), backed by the Hive `settings` box.

final class LastGoodAdapterStoreProvider
    extends
        $FunctionalProvider<
          LastGoodAdapterStore,
          LastGoodAdapterStore,
          LastGoodAdapterStore
        >
    with $Provider<LastGoodAdapterStore> {
  /// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
  /// Epic #3013 phase 3), backed by the Hive `settings` box.
  LastGoodAdapterStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastGoodAdapterStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastGoodAdapterStoreHash();

  @$internal
  @override
  $ProviderElement<LastGoodAdapterStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LastGoodAdapterStore create(Ref ref) {
    return lastGoodAdapterStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastGoodAdapterStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastGoodAdapterStore>(value),
    );
  }
}

String _$lastGoodAdapterStoreHash() =>
    r'e3f12c50ac74faa882a1a248c7f6b1b80d74a623';

/// App-wide owner of the trip-INDEPENDENT auto-reconnect controller (#3019 /
/// Epic #3013 phase 3).
///
/// This is the decoupling the Epic asks for: the in-trip [DroppedSessionManager]
/// (#2188) only runs while a recording is active, so a drop while idle / between
/// trips never re-establishes. This notifier owns an [Obd2ReconnectController]
/// whose loop is driven purely by the connection lifecycle:
///   * drops reach it EXCLUSIVELY through its registered [Obd2LinkArbiter]
///     idle policy (#3420) — the arbiter is the sole consumer of the
///     proactive link-drop signal, so this loop runs only while no lease
///     holds the link (#3424 deleted the bypassing `reportDropped` seam);
///   * each attempt tries the auto-pinned adapter first (transport-correct
///     direct connect, #3016), then a re-scan fallback;
///   * after the bound it stops in [Obd2ReconnectState.terminalFailed] and the
///     UI shows a "tap to retry" affordance wired to [retry].
///
/// On a successful (re)connect it republishes the live state into the app-wide
/// [Obd2ConnectionStatus] dot so every screen reflects the recovered link.

@ProviderFor(Obd2Reconnect)
final obd2ReconnectProvider = Obd2ReconnectProvider._();

/// App-wide owner of the trip-INDEPENDENT auto-reconnect controller (#3019 /
/// Epic #3013 phase 3).
///
/// This is the decoupling the Epic asks for: the in-trip [DroppedSessionManager]
/// (#2188) only runs while a recording is active, so a drop while idle / between
/// trips never re-establishes. This notifier owns an [Obd2ReconnectController]
/// whose loop is driven purely by the connection lifecycle:
///   * drops reach it EXCLUSIVELY through its registered [Obd2LinkArbiter]
///     idle policy (#3420) — the arbiter is the sole consumer of the
///     proactive link-drop signal, so this loop runs only while no lease
///     holds the link (#3424 deleted the bypassing `reportDropped` seam);
///   * each attempt tries the auto-pinned adapter first (transport-correct
///     direct connect, #3016), then a re-scan fallback;
///   * after the bound it stops in [Obd2ReconnectState.terminalFailed] and the
///     UI shows a "tap to retry" affordance wired to [retry].
///
/// On a successful (re)connect it republishes the live state into the app-wide
/// [Obd2ConnectionStatus] dot so every screen reflects the recovered link.
final class Obd2ReconnectProvider
    extends $NotifierProvider<Obd2Reconnect, Obd2ReconnectState> {
  /// App-wide owner of the trip-INDEPENDENT auto-reconnect controller (#3019 /
  /// Epic #3013 phase 3).
  ///
  /// This is the decoupling the Epic asks for: the in-trip [DroppedSessionManager]
  /// (#2188) only runs while a recording is active, so a drop while idle / between
  /// trips never re-establishes. This notifier owns an [Obd2ReconnectController]
  /// whose loop is driven purely by the connection lifecycle:
  ///   * drops reach it EXCLUSIVELY through its registered [Obd2LinkArbiter]
  ///     idle policy (#3420) — the arbiter is the sole consumer of the
  ///     proactive link-drop signal, so this loop runs only while no lease
  ///     holds the link (#3424 deleted the bypassing `reportDropped` seam);
  ///   * each attempt tries the auto-pinned adapter first (transport-correct
  ///     direct connect, #3016), then a re-scan fallback;
  ///   * after the bound it stops in [Obd2ReconnectState.terminalFailed] and the
  ///     UI shows a "tap to retry" affordance wired to [retry].
  ///
  /// On a successful (re)connect it republishes the live state into the app-wide
  /// [Obd2ConnectionStatus] dot so every screen reflects the recovered link.
  Obd2ReconnectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ReconnectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ReconnectHash();

  @$internal
  @override
  Obd2Reconnect create() => Obd2Reconnect();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2ReconnectState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2ReconnectState>(value),
    );
  }
}

String _$obd2ReconnectHash() => r'638d0d5c851179aefffd6c51962af20f9e450d65';

/// App-wide owner of the trip-INDEPENDENT auto-reconnect controller (#3019 /
/// Epic #3013 phase 3).
///
/// This is the decoupling the Epic asks for: the in-trip [DroppedSessionManager]
/// (#2188) only runs while a recording is active, so a drop while idle / between
/// trips never re-establishes. This notifier owns an [Obd2ReconnectController]
/// whose loop is driven purely by the connection lifecycle:
///   * drops reach it EXCLUSIVELY through its registered [Obd2LinkArbiter]
///     idle policy (#3420) — the arbiter is the sole consumer of the
///     proactive link-drop signal, so this loop runs only while no lease
///     holds the link (#3424 deleted the bypassing `reportDropped` seam);
///   * each attempt tries the auto-pinned adapter first (transport-correct
///     direct connect, #3016), then a re-scan fallback;
///   * after the bound it stops in [Obd2ReconnectState.terminalFailed] and the
///     UI shows a "tap to retry" affordance wired to [retry].
///
/// On a successful (re)connect it republishes the live state into the app-wide
/// [Obd2ConnectionStatus] dot so every screen reflects the recovered link.

abstract class _$Obd2Reconnect extends $Notifier<Obd2ReconnectState> {
  Obd2ReconnectState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Obd2ReconnectState, Obd2ReconnectState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Obd2ReconnectState, Obd2ReconnectState>,
              Obd2ReconnectState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
