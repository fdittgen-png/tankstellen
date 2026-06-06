// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

class AppConstants {
  AppConstants._();

  static const String appName = 'Sparkilo'; // i18n-ignore: brand name
  static const String appPackage = 'de.tankstellen.app';

  /// Runtime app version cached at startup by [AppInitializer].
  /// Falls back to build-time constant if not yet initialized.
  static String get appVersion => _runtimeVersion ?? _buildVersion;
  static const String _buildVersion = '5.0.0';
  static String? _runtimeVersion;

  /// Called once at startup with the real version from package_info_plus.
  static void setRuntimeVersion(String version) => _runtimeVersion = version;

  // Developer / Publisher
  static const String developerName = 'Florian DITTGEN';
  static const String developerEmail = 'fdittgen@gmail.com';
  static const String developerWebsite =
      'https://github.com/fdittgen-png/tankstellen';

  /// Shared User-Agent for all HTTP clients.
  static String get userAgent => '$appPackage/$appVersion';

  // ---------------------------------------------------------------------------
  // Search radius + auto-refresh policy.
  //
  // The radius and refresh values below are intentionally compile-time `const`
  // with no runtime or remote-config override. They are bounded by the
  // upstream Tankerkoenig contract (25 km max radius, 5-minute price cadence /
  // rate limit), so a user- or server-tunable knob would mostly let callers
  // pick values that desync from upstream and either over-fetch or show stale
  // prices. Fixing them also keeps search and refresh behaviour reproducible
  // in tests. This is a deliberate trade-off, not an oversight: if a future
  // need arises to tune freshness per-user or react to upstream changes
  // without an app release, route these through a `RuntimeConfig` /
  // remote-config layer that supplies overrides while falling back to these
  // constants as defaults.
  // ---------------------------------------------------------------------------

  /// Default nearby-search radius (km) for a fresh install / unset preference.
  /// 10 km balances result coverage against query cost; sits inside the
  /// [minSearchRadiusKm]..[maxSearchRadiusKm] band. Compile-time by policy.
  static const double defaultSearchRadiusKm = 10.0;

  /// Upper bound the user may select for the search radius (km).
  /// Pinned to the Tankerkoenig upstream cap (25 km); a larger value would be
  /// rejected by the API. Compile-time by policy (mirrors
  /// `ApiConstants.maxRadiusKm`).
  static const double maxSearchRadiusKm = 25.0;

  /// Lower bound the user may select for the search radius (km).
  /// 1 km keeps "nearby" meaningful and avoids zero-result queries.
  /// Compile-time by policy.
  static const double minSearchRadiusKm = 1.0;

  /// Floor for the auto-refresh cadence of the station/price list.
  /// 5 minutes matches the Tankerkoenig price-update cadence and rate limit:
  /// refreshing faster cannot surface newer data and risks the upstream
  /// limit. Compile-time by policy (mirrors `ApiConstants.minRefreshInterval`).
  static const Duration minAutoRefreshInterval = Duration(minutes: 5);

  /// Maximum random delay added to each auto-refresh tick to spread requests.
  /// Up to 30 s of jitter de-synchronises many clients so they do not all hit
  /// the upstream on the same wall-clock boundary. Compile-time by policy.
  static const Duration refreshJitterMax = Duration(seconds: 30);

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Stable, version-free identity sent on every OSM/tile request
  /// (#2396). OSM's tile-usage policy wants a *stable* User-Agent that
  /// identifies the app, NOT one that changes on every release — a
  /// per-version UA looks like many distinct clients to their abuse
  /// heuristics. So this is deliberately the bare package id with no
  /// `/appVersion` suffix. The versioned [userAgent] above is still used
  /// by the data-API HTTP clients, where per-release identification is
  /// useful for upstream debugging. Not user-facing (an HTTP header).
  static const String osmUserAgent = appPackage;

  /// Tile-proxy URL template (LAYER 2 / #2397). The Supabase `tiles` edge
  /// function (`supabase/functions/tiles`) fetches from OSM with the stable
  /// server-side [tileProxyOsmUserAgent] and serves tiles back with a 7-day
  /// `Cache-Control`, taking direct tile load off OSM. The subdomain is the
  /// real project ref `klelxnkzrxlpzuddhpfg`; the `.png` suffix + `{z}/{x}/
  /// {y}` shape match both [osmTileUrl] and the function's route.
  ///
  /// Wired up by #2396: [SparkiloTileLayer] / [effectiveTileUrl] default to
  /// this. The function MUST be deployed before the app flip ships, or every
  /// tile 404s — see `supabase/functions/tiles/README.md`. Set to empty to
  /// fall back to OSM-direct (see [effectiveTileUrl]). Not user-facing (URL).
  static const String tileProxyUrl =
      'https://klelxnkzrxlpzuddhpfg.supabase.co/functions/v1/tiles/{z}/{x}/{y}.png';

  /// The tile-URL template the app should actually use: the [tileProxyUrl]
  /// proxy when it is configured, else OSM-direct ([osmTileUrl]) as a clean
  /// fallback so a build with the proxy cleared still renders a map instead
  /// of grey (#2396). This is the single source the map surfaces resolve
  /// through.
  static String get effectiveTileUrl =>
      tileProxyUrl.isEmpty ? osmTileUrl : tileProxyUrl;

  /// Stable OSM-facing User-Agent the [tileProxyUrl] edge function imports
  /// to identify itself to OSM (LAYER 2 / #2397). Carries a contact URL
  /// per OSM policy. Not user-facing (an HTTP header).
  static const String tileProxyOsmUserAgent =
      'de.tankstellen.tile-proxy/1.0 (+https://github.com/fdittgen-png/tankstellen)';

  static const String tankerkoenigAttribution =
      'Daten von Tankerkoenig.de (CC BY 4.0)';
  static const String osmAttribution =
      '\u00a9 OpenStreetMap contributors';

  /// Where the user requests a personal Tankerk\u00f6nig API key.
  static const String tankerkoenigRegistrationUrl =
      'https://onboarding.tankerkoenig.de/';

  /// Where the [tankerkoenigAttribution] string points \u2014 the project's
  /// CC BY 4.0 page that documents the data licence + how the dataset
  /// is built. Linked from the about / parameters screen.
  static const String tankerkoenigCreativeCommonsUrl =
      'https://creativecommons.tankerkoenig.de/';

  static const String privacyPolicyUrl =
      'https://fdittgen-png.github.io/tankstellen/';

  // Donation links
  static const String paypalUrl = 'https://www.paypal.me/FlorianDITTGEN';
  static const String revolutUrl = 'https://revolut.me/floriamcep';

  // GitHub project
  static const String githubRepoUrl =
      'https://github.com/fdittgen-png/tankstellen';
  static const String githubIssuesUrl =
      'https://github.com/fdittgen-png/tankstellen/issues';

  /// Sentinel value for price sorting when a station has no price for the selected fuel.
  /// Ensures stations without prices sort to the bottom of the list.
  static const double noPriceSentinel = 999.0;
}
