// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Single source of truth for "which distribution flavor is this build?".
///
/// The app ships three ways — Google Play, Apple App Store, and F-Droid — from
/// ONE code base, switched only by configuration (see the project's
/// one-codebase-by-config rule). The only axis that changes app *behaviour* is
/// whether Google's proprietary libraries (GMS, ML Kit, Play Core) are present:
///
///   * `play` flavor + iOS  → proprietary Google services available.
///   * `fdroid` flavor      → GMS-free / libre: no proprietary Google code in
///                            the dex (#2574 / #3473), so any capability that
///                            would touch it must use a FOSS or no-op
///                            implementation instead.
///
/// This is the seam every GMS-tied *capability* selects its implementation on
/// (location, barcode scanning, store review …). Centralising it here — rather
/// than each feature re-deriving `bool.fromEnvironment(...)` — means:
///   * the fdroid build is decided in exactly ONE place, and
///   * a new GMS-pulling plugin cannot silently re-enter the libre build,
///     because libre code paths structurally never reach the Play-only impls.
///
/// The signal is the `FORCE_LOCATION_MANAGER` dart-define, which the F-Droid
/// build command passes (`--dart-define=FORCE_LOCATION_MANAGER=true`, see
/// `metadata/de.tankstellen.fuelprices.yml` and `.github/workflows/fdroid.yml`)
/// and no other build does. It doubles as the libre marker so the recipe needs
/// no extra define. [GeolocatorWrapper.forceLocationManager] reads the same
/// define for its own routing.
abstract final class AppFlavor {
  const AppFlavor._();

  /// True on the GMS-free / F-Droid (libre) build; false on Play + iOS.
  ///
  /// A compile-time constant so tree-shaking and R8 can fold libre-only
  /// branches, and so tests can reason about it without a platform channel.
  static const bool isLibre =
      bool.fromEnvironment('FORCE_LOCATION_MANAGER');

  /// True when proprietary Google services (GMS / ML Kit / Play Core) may be
  /// present — i.e. the Play or iOS build. The inverse of [isLibre].
  static const bool hasGoogleServices = !isLibre;
}
