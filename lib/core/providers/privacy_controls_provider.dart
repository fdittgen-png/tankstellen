// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_providers.dart';

part 'privacy_controls_provider.g.dart';

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
@Riverpod(keepAlive: true)
class TileProxyEnabled extends _$TileProxyEnabled {
  @override
  bool build() {
    final enabled = _readBool(ref, StorageKeys.tileProxyEnabled, orElse: true);
    AppConstants.tileProxyDisabledByUser = !enabled;
    return enabled;
  }

  Future<void> set(bool enabled) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.tileProxyEnabled, enabled);
    AppConstants.tileProxyDisabledByUser = !enabled;
    state = enabled;
  }
}

/// Load brand logos from the internet (logo.clearbit.com). Default OFF:
/// the bundled monogram fallback renders instead, and no third party sees
/// the user's IP on a station list.
@Riverpod(keepAlive: true)
class RemoteBrandLogos extends _$RemoteBrandLogos {
  @override
  bool build() {
    return _readBool(ref, StorageKeys.remoteBrandLogos, orElse: false);
  }

  Future<void> set(bool enabled) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.remoteBrandLogos, enabled);
    state = enabled;
  }
}

/// Reads a bool setting defensively: an unavailable settings box (widget
/// tests, the pre-storage boot window) degrades to the default — a
/// privacy switch must never take a render surface down.
bool _readBool(Ref ref, String key, {required bool orElse}) {
  try {
    return ref.watch(storageRepositoryProvider).getSetting(key) as bool? ??
        orElse;
  } catch (_) {
    return orElse;
  }
}
