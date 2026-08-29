// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'privacy_controls_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3870 (Epic #3865) — privacy controls that are not consents.
///
/// Two flows reached third parties with no disclosure and no switch: every
/// map pan sent the viewport + IP to the developer's tile proxy, and every
/// station list fetched brand logos from logo.clearbit.com. Both are now
/// named in the policy and switchable here; the logo fetch is OFF by
/// default (bundled fallback), the proxy stays on (it exists to spare
/// OSM's tile servers) but can be turned off for OSM-direct.
/// Route map tiles through the Sparkilo proxy (default on; F-Droid builds
/// have no proxy at all). Mirrors into [AppConstants.tileProxyDisabledByUser]
/// because every map surface resolves the URL through that const class.

@ProviderFor(TileProxyEnabled)
final tileProxyEnabledProvider = TileProxyEnabledProvider._();

/// #3870 (Epic #3865) — privacy controls that are not consents.
///
/// Two flows reached third parties with no disclosure and no switch: every
/// map pan sent the viewport + IP to the developer's tile proxy, and every
/// station list fetched brand logos from logo.clearbit.com. Both are now
/// named in the policy and switchable here; the logo fetch is OFF by
/// default (bundled fallback), the proxy stays on (it exists to spare
/// OSM's tile servers) but can be turned off for OSM-direct.
/// Route map tiles through the Sparkilo proxy (default on; F-Droid builds
/// have no proxy at all). Mirrors into [AppConstants.tileProxyDisabledByUser]
/// because every map surface resolves the URL through that const class.
final class TileProxyEnabledProvider
    extends $NotifierProvider<TileProxyEnabled, bool> {
  /// #3870 (Epic #3865) — privacy controls that are not consents.
  ///
  /// Two flows reached third parties with no disclosure and no switch: every
  /// map pan sent the viewport + IP to the developer's tile proxy, and every
  /// station list fetched brand logos from logo.clearbit.com. Both are now
  /// named in the policy and switchable here; the logo fetch is OFF by
  /// default (bundled fallback), the proxy stays on (it exists to spare
  /// OSM's tile servers) but can be turned off for OSM-direct.
  /// Route map tiles through the Sparkilo proxy (default on; F-Droid builds
  /// have no proxy at all). Mirrors into [AppConstants.tileProxyDisabledByUser]
  /// because every map surface resolves the URL through that const class.
  TileProxyEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tileProxyEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tileProxyEnabledHash();

  @$internal
  @override
  TileProxyEnabled create() => TileProxyEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tileProxyEnabledHash() => r'b75b82810222f677eaf3500d7b5e108eb05539ed';

/// #3870 (Epic #3865) — privacy controls that are not consents.
///
/// Two flows reached third parties with no disclosure and no switch: every
/// map pan sent the viewport + IP to the developer's tile proxy, and every
/// station list fetched brand logos from logo.clearbit.com. Both are now
/// named in the policy and switchable here; the logo fetch is OFF by
/// default (bundled fallback), the proxy stays on (it exists to spare
/// OSM's tile servers) but can be turned off for OSM-direct.
/// Route map tiles through the Sparkilo proxy (default on; F-Droid builds
/// have no proxy at all). Mirrors into [AppConstants.tileProxyDisabledByUser]
/// because every map surface resolves the URL through that const class.

abstract class _$TileProxyEnabled extends $Notifier<bool> {
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

/// Load brand logos from the internet (logo.clearbit.com). Default OFF:
/// the bundled monogram fallback renders instead, and no third party sees
/// the user's IP on a station list.

@ProviderFor(RemoteBrandLogos)
final remoteBrandLogosProvider = RemoteBrandLogosProvider._();

/// Load brand logos from the internet (logo.clearbit.com). Default OFF:
/// the bundled monogram fallback renders instead, and no third party sees
/// the user's IP on a station list.
final class RemoteBrandLogosProvider
    extends $NotifierProvider<RemoteBrandLogos, bool> {
  /// Load brand logos from the internet (logo.clearbit.com). Default OFF:
  /// the bundled monogram fallback renders instead, and no third party sees
  /// the user's IP on a station list.
  RemoteBrandLogosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteBrandLogosProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteBrandLogosHash();

  @$internal
  @override
  RemoteBrandLogos create() => RemoteBrandLogos();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$remoteBrandLogosHash() => r'f8b09666d415de137deea96d92614095fc697fc8';

/// Load brand logos from the internet (logo.clearbit.com). Default OFF:
/// the bundled monogram fallback renders instead, and no third party sees
/// the user's IP on a station list.

abstract class _$RemoteBrandLogos extends $Notifier<bool> {
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
