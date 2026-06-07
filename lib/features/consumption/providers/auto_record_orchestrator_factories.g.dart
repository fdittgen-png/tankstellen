// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_record_orchestrator_factories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default factory: Android in production, an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.

@ProviderFor(autoRecordListenerFactory)
final autoRecordListenerFactoryProvider = AutoRecordListenerFactoryProvider._();

/// Default factory: Android in production, an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.

final class AutoRecordListenerFactoryProvider
    extends
        $FunctionalProvider<
          BackgroundAdapterListenerFactory,
          BackgroundAdapterListenerFactory,
          BackgroundAdapterListenerFactory
        >
    with $Provider<BackgroundAdapterListenerFactory> {
  /// Default factory: Android in production, an unimplemented stub
  /// elsewhere. Tests override this provider to inject a
  /// [FakeBackgroundAdapterListener] without touching platform-detection
  /// code.
  AutoRecordListenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordListenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordListenerFactoryHash();

  @$internal
  @override
  $ProviderElement<BackgroundAdapterListenerFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundAdapterListenerFactory create(Ref ref) {
    return autoRecordListenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundAdapterListenerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundAdapterListenerFactory>(
        value,
      ),
    );
  }
}

String _$autoRecordListenerFactoryHash() =>
    r'3ac9db8a2ce1a0919d0fb75fc9b9906b736d40af';

/// Default opener: opens a fresh [Obd2Service] for the configured MAC
/// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
/// Returns null when the adapter is out of range or the scan times
/// out — the coordinator stays idle for that connect cycle and waits
/// for the next `AdapterConnected`. Tests override this provider to
/// inject a fake opener that returns a stub service.

@ProviderFor(autoRecordSessionOpenerFactory)
final autoRecordSessionOpenerFactoryProvider =
    AutoRecordSessionOpenerFactoryProvider._();

/// Default opener: opens a fresh [Obd2Service] for the configured MAC
/// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
/// Returns null when the adapter is out of range or the scan times
/// out — the coordinator stays idle for that connect cycle and waits
/// for the next `AdapterConnected`. Tests override this provider to
/// inject a fake opener that returns a stub service.

final class AutoRecordSessionOpenerFactoryProvider
    extends
        $FunctionalProvider<
          Obd2SessionOpener,
          Obd2SessionOpener,
          Obd2SessionOpener
        >
    with $Provider<Obd2SessionOpener> {
  /// Default opener: opens a fresh [Obd2Service] for the configured MAC
  /// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
  /// Returns null when the adapter is out of range or the scan times
  /// out — the coordinator stays idle for that connect cycle and waits
  /// for the next `AdapterConnected`. Tests override this provider to
  /// inject a fake opener that returns a stub service.
  AutoRecordSessionOpenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordSessionOpenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordSessionOpenerFactoryHash();

  @$internal
  @override
  $ProviderElement<Obd2SessionOpener> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2SessionOpener create(Ref ref) {
    return autoRecordSessionOpenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2SessionOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2SessionOpener>(value),
    );
  }
}

String _$autoRecordSessionOpenerFactoryHash() =>
    r'bb6af1c2c633c61722cb5329e5ea038cb7c0e33f';

/// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
/// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
/// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
/// resume to start engine-detection while the app is in front, independent of
/// the disabled foreground service.
///
/// #3025 — now TRANSPORT-AWARE via
/// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
/// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
/// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
/// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
/// shared. Transport is inferred from the paired adapter NAME (read defensively
/// off the active vehicle so a provider hiccup never makes the connect throw).
/// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
/// direct attempt fails. Tests override this provider to inject a fake opener.

@ProviderFor(autoRecordForegroundSessionOpenerFactory)
final autoRecordForegroundSessionOpenerFactoryProvider =
    AutoRecordForegroundSessionOpenerFactoryProvider._();

/// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
/// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
/// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
/// resume to start engine-detection while the app is in front, independent of
/// the disabled foreground service.
///
/// #3025 — now TRANSPORT-AWARE via
/// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
/// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
/// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
/// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
/// shared. Transport is inferred from the paired adapter NAME (read defensively
/// off the active vehicle so a provider hiccup never makes the connect throw).
/// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
/// direct attempt fails. Tests override this provider to inject a fake opener.

final class AutoRecordForegroundSessionOpenerFactoryProvider
    extends
        $FunctionalProvider<
          Obd2ForegroundSessionOpener,
          Obd2ForegroundSessionOpener,
          Obd2ForegroundSessionOpener
        >
    with $Provider<Obd2ForegroundSessionOpener> {
  /// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
  /// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
  /// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
  /// resume to start engine-detection while the app is in front, independent of
  /// the disabled foreground service.
  ///
  /// #3025 — now TRANSPORT-AWARE via
  /// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
  /// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
  /// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
  /// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
  /// shared. Transport is inferred from the paired adapter NAME (read defensively
  /// off the active vehicle so a provider hiccup never makes the connect throw).
  /// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
  /// direct attempt fails. Tests override this provider to inject a fake opener.
  AutoRecordForegroundSessionOpenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordForegroundSessionOpenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$autoRecordForegroundSessionOpenerFactoryHash();

  @$internal
  @override
  $ProviderElement<Obd2ForegroundSessionOpener> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2ForegroundSessionOpener create(Ref ref) {
    return autoRecordForegroundSessionOpenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2ForegroundSessionOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2ForegroundSessionOpener>(value),
    );
  }
}

String _$autoRecordForegroundSessionOpenerFactoryHash() =>
    r'2767dfb1262c9bd41e561d1fef3210daa04a3362';
