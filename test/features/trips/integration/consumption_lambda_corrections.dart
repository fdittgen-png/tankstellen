// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4572 intentionally corrects the ten live rates affected by interpreting
/// raw OBD lambda as true phi. Keep the original #4233 historical map frozen.
/// These replacements were independently calculated from frame bytes and
/// MAF/ideal-gas equations, not regenerated from production output.
///
/// Petrol AFR = 14.7 * lambda; measured 0x6666/32768, commanded0x999A/32768.
/// Existing combined trim factor0.9765625 and gain1/.8/1.1 still apply.
/// Diesel measured lambda0.79998779 reciprocates to truephi1.250019 and
/// uses the existing1.2 upper clamp; AFR14.5/1.2, gain1.2, no petrol trims.
/// GPS, direct flow, provenance and all other figures remain bit-identical.
const Map<String, String> kConsumptionLambdaCorrections = {
  'live/raw/maf10MeasuredPhi/rate': '40108c232fa65cfa',
  'live/raw/maf10CommandedPhi/rate': '40069797b2d93b64',
  'live/raw/speedDensityFull/rate': '4015ee2382943550',
  'live/scalar/maf10MeasuredPhi/rate': '400a79d1e5d6fb2a',
  'live/scalar/maf10CommandedPhi/rate': '400212dfc24762b7',
  'live/scalar/speedDensityFull/rate': '40118b4f9ba9c440',
  'live/flex/maf10MeasuredPhi/rate': '401233c04e03ccad',
  'live/flex/maf10CommandedPhi/rate': '4008d9f3ab2227bb',
  'live/flex/speedDensityFull/rate': '40181f8d76096dd9',
  'live/diesel/maf10MeasuredPhi/rate': '401199d13a352ecc',
};
