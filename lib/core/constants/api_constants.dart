// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://creativecommons.tankerkoenig.de/json';

  static const String listEndpoint = '/list.php';
  static const String detailEndpoint = '/detail.php';
  static const String pricesEndpoint = '/prices.php';
  static const String complaintEndpoint = '/complaint.php';

  // ---------------------------------------------------------------------------
  // Tankerkoenig upstream contract limits.
  //
  // The four constants below mirror hard limits of the Tankerkoenig API. They
  // are intentionally compile-time `const` with no runtime or remote-config
  // override: they are dictated by the upstream service, not by user or app
  // preference, so a tunable knob could only ever drift out of sync with the
  // server and cause rejected requests or rate-limit hits. Keeping them fixed
  // also keeps request-building deterministic in tests. This is a deliberate
  // trade-off, not an oversight: should the upstream lift a limit and we want
  // to react without an app release, route these through a `RuntimeConfig` /
  // remote-config layer that supplies overrides while falling back to these
  // constants as defaults.
  // ---------------------------------------------------------------------------

  /// Maximum search radius (km) accepted by the Tankerkoenig `list` endpoint.
  /// Requests above this are rejected upstream. Compile-time by contract.
  static const int maxRadiusKm = 25;

  /// Default search radius (km) used when a caller does not specify one.
  /// 10 km balances coverage against query cost and stays within
  /// [maxRadiusKm]. Compile-time by policy.
  static const int defaultRadiusKm = 10;

  /// Maximum number of station ids accepted by one `prices` batch request.
  /// Tankerkoenig caps a bulk price query at 10 ids; larger batches must be
  /// chunked by the caller. Compile-time by contract.
  static const int maxPriceQueryIds = 10;

  /// Minimum interval between price refreshes against the upstream.
  /// 5 minutes matches the Tankerkoenig update cadence and rate limit:
  /// refreshing faster cannot surface newer data and risks the limit.
  /// Compile-time by contract.
  static const Duration minRefreshInterval = Duration(minutes: 5);

  /// Test coordinates (Berlin city center) used for API key validation.
  /// When validating a Tankerkoenig API key, we make a minimal search
  /// at these coordinates to verify the key works.
  static const double testLatitude = 52.521;
  static const double testLongitude = 13.438;
}
