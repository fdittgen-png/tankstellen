// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3788 — the LIBRE build switch: this binary must reach no
/// developer-hosted service by default.
///
/// Set with `--dart-define=FDROID_LIBRE=true` by the F-Droid recipe (and
/// by `scripts/fdroid_publish.sh` for the self-hosted repo), alongside
/// the existing `FORCE_LOCATION_MANAGER` / `FGS_FORM_APPROVED` defines.
///
/// ## Why
///
/// The fdroiddata review of MR !42093 blocked on exactly this: the app
/// shipped a fixed Supabase tile-proxy endpoint and a default
/// `assets/tanksync_config.json` pointing at the developer's instance,
/// with no AntiFeature declaring it. The disclosure was added as the
/// honest short-term answer; this flag is the real one — with it set the
/// build has no such default, and the AntiFeature can be dropped.
///
/// ## What it changes
///
///  * [AppConstants.tileProxyUrl] resolves empty, so `effectiveTileUrl`
///    falls back to OSM-direct — the fallback that already existed for a
///    cleared proxy, now reachable by configuration.
///  * `CommunityConfig` ignores the bundled default credentials, so the
///    community-reports / TankSync features start unconfigured. They stay
///    fully usable: the user points them at their OWN Supabase project
///    through the setup wizard (which is what TankSync was designed for),
///    or via `--dart-define`.
///
/// Nothing is disabled — only the developer-hosted DEFAULTS are absent.
const bool kLibreBuild = bool.fromEnvironment('FDROID_LIBRE');
