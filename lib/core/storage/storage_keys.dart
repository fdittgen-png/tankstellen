// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

class StorageKeys {
  StorageKeys._();

  /// #3746 — LEGACY single-slot name. Per-country keys live under
  /// `api_key_<lowercase-cc>` now (see `SettingsHiveStore`); this bare slot
  /// only survives as the one-time DE (Tankerkönig) migration source and as
  /// the prefix of the per-country slots.
  static const String apiKey = 'api_key';
  static const String activeProfileId = 'active_profile_id';
  static const String favoriteStationIds = 'favorite_station_ids';
  static const String setupSkipped = 'setup_skipped';
  static const String userPositionLat = 'user_position_lat';
  static const String userPositionLng = 'user_position_lng';
  static const String userPositionTimestamp = 'user_position_timestamp';
  static const String userPositionSource = 'user_position_source';
  static const String autoSwitchProfile = 'auto_switch_profile';
  static const String evApiKey = 'ev_api_key';
  static const String ignoredStationIds = 'ignored_station_ids';
  static const String stationRatings = 'station_ratings';
  static const String favoriteStationData = 'favorite_station_data';
  static const String gdprConsentGiven = 'gdpr_consent_given';
  static const String consentLocation = 'consent_location';
  static const String consentErrorReporting = 'consent_error_reporting';
  static const String consentCloudSync = 'consent_cloud_sync';
  /// #1399 — opt-in toggle for sending the 17-character VIN to NHTSA's
  /// free public vPIC service to enrich the VIN-driven profile auto-
  /// population with full make/model/displacement/cylinders/fuel type.
  /// Defaults to `false`: the offline WMI decoder (make + country +
  /// year-from-position-10) always runs locally regardless of this
  /// flag; only the network call is gated.
  static const String consentVinOnlineDecode = 'consent_vin_online_decode';

  /// #1479 phase 1 — opt-in consent for syncing OBD2 + GPS trip
  /// recordings to TankSync (cross-device backup). Defaults to false.
  /// Gated on `consentCloudSync` at the toggle UI layer — without
  /// the master TankSync consent the trip-sync toggle cannot be
  /// enabled at all.
  static const String consentSyncTrips = 'consent_sync_trips';

  /// #3866 (Epic #3865) — the consent record: ISO-8601 instant of the last
  /// save and the privacy-policy version the user was shown. A version
  /// bump re-surfaces the consent screen once (`ConsentRecord.isCurrent`).
  static const String consentRecordedAt = 'consent_recorded_at';

  /// #3870 (Epic #3865) — privacy controls that are not consents: the
  /// developer tile proxy (default on, disclosed) and internet brand
  /// logos from logo.clearbit.com (default OFF — bundled fallback).
  static const String tileProxyEnabled = 'tile_proxy_enabled';
  static const String remoteBrandLogos = 'remote_brand_logos';
  static const String consentPolicyVersion = 'consent_policy_version';

  static const String swipeTutorialShown = 'swipe_tutorial_shown';

  /// #3872 (epic #3865, GDPR) — set once the pre-permission rationale
  /// for the given runtime permission has been shown and acknowledged
  /// (Continue). One-time per kind: the explainer must precede the FIRST
  /// OS prompt, never nag afterwards. Read/written only through
  /// `PermissionRationaleDialog` (#3592 one-accessor rule).
  static const String permissionRationaleShownCamera =
      'permission_rationale_shown_camera';
  static const String permissionRationaleShownBluetooth =
      'permission_rationale_shown_bluetooth';
  static const String permissionRationaleShownNotifications =
      'permission_rationale_shown_notifications';

  /// #3313 — set once we've prompted the user to exempt the app from
  /// battery optimization (so a recording foreground service survives
  /// Doze / aggressive OEM task-killers on long drives). One-time: set
  /// the first time a recording FGS starts, never re-prompted, so a
  /// declined dialog doesn't nag. Only ever consulted in FGS-approved
  /// builds (`kGpsRecordingForegroundServiceEnabled`).
  static const String batteryOptExemptionAsked = 'battery_opt_exemption_asked';

  static const String consumptionLog = 'consumption_log';
  static const String vehicleProfiles = 'vehicle_profiles';
  static const String activeVehicleProfileId = 'active_vehicle_profile_id';
  static const String evStationsCache = 'ev_stations_cache';
  static const String evShowOnMap = 'ev_show_on_map';
  static const String evFavoriteStationIds = 'ev_favorite_station_ids';
  static const String evFavoriteStationData = 'ev_favorite_station_data';
  static const String helpBannerCriteria = 'help_banner_criteria_shown';
  static const String helpBannerAlerts = 'help_banner_alerts_shown';
  static const String helpBannerConsumption = 'help_banner_consumption_shown';
  static const String helpBannerVehicles = 'help_banner_vehicles_shown';

  /// #3938 (Epic #3937) — the search-results surface's help bubble. Carries
  /// the explanations the results chrome used to spend permanent height on
  /// (the all-prices legend, what the price arrows rank, where the criteria
  /// live). Dismissal persists exactly like the four flags above.
  static const String helpBannerSearchResults =
      'help_banner_search_results_shown';

  /// #3938 — the paged help bubble remembers WHICH tip it last showed on a
  /// surface, so the next visit opens on the tip AFTER it and every visit
  /// teaches something new. One `int` slot per surface, alongside (never
  /// instead of) that surface's dismissal flag; read/written only through
  /// `HelpBanner` (#3592 one-accessor rule). A stored index from a shorter
  /// or longer tip list is tolerated — the bubble takes it modulo the
  /// current tip count.
  static const String helpBannerCriteriaPosition =
      'help_banner_criteria_position';
  static const String helpBannerAlertsPosition = 'help_banner_alerts_position';
  static const String helpBannerConsumptionPosition =
      'help_banner_consumption_position';
  static const String helpBannerVehiclesPosition =
      'help_banner_vehicles_position';
  static const String helpBannerSearchResultsPosition =
      'help_banner_search_results_position';

  /// The position slot that pairs with a help bubble's dismissal flag.
  ///
  /// Every shipped surface has an explicit constant above; an unknown key
  /// (a widget test's throwaway `'test_banner'`) derives its slot by
  /// suffix rather than crashing, so a new surface always has somewhere to
  /// remember its place even before it gets a named constant.
  static String helpBannerPositionKey(String shownKey) =>
      _helpBannerPositions[shownKey] ?? '${shownKey}_position';

  static const Map<String, String> _helpBannerPositions = <String, String>{
    helpBannerCriteria: helpBannerCriteriaPosition,
    helpBannerAlerts: helpBannerAlertsPosition,
    helpBannerConsumption: helpBannerConsumptionPosition,
    helpBannerVehicles: helpBannerVehiclesPosition,
    helpBannerSearchResults: helpBannerSearchResultsPosition,
  };

  static const String supabaseAnonKey = 'supabase_anon_key';

  /// #780 — opt-in switch for per-vehicle baseline sync. Defaults to
  /// false (off) so users who only want favourite sync aren't
  /// silently uploading driving data.
  @Deprecated(
    'Migrated to Feature.baselineSync in #1373 phase 3e; '
    'kept for one-shot migration read.',
  )
  static const String syncBaselinesEnabled = 'sync_baselines_enabled';

  /// #950 phase 4 — flag set once the
  /// [VehicleProfileCatalogMigrator] has run, so subsequent app
  /// launches skip the migration. Stored in the settings box rather
  /// than in shared_preferences to keep all app-state in one place
  /// (matches how onboarding completion is tracked).
  static const String vehicleCatalogMigrationDone =
      'vehicle_catalog_migration_done';

  /// #1122 — opt-in toggle for the real-time eco-coaching haptic that
  /// fires on sustained-high-throttle / low-Δspeed cruise. Defaults to
  /// off so we never buzz a user who hasn't asked for live feedback.
  @Deprecated(
    'Migrated to Feature.hapticEcoCoach in #1373 phase 3a; '
    'kept for one-shot migration read.',
  )
  static const String hapticEcoCoachEnabled = 'haptic_eco_coach_enabled';

  /// #1273 — flag set the first time the user backs out of the trip
  /// recording screen WHILE recording, after they've seen the "tap the
  /// red banner to return" tooltip. Persisted so the tooltip never
  /// fires twice for the same user.
  static const String tripRecordingResumeHintShown =
      'trip_recording_resume_hint_shown';

  /// #1395 — toggle that surfaces the in-app OBD2 fuel-rate
  /// diagnostic overlay in release builds. The overlay is always
  /// visible in `kDebugMode`; this flag flips it on for production
  /// users investigating a suspicious L/100 km figure on a trip
  /// summary, via a hidden 5-tap gesture on the trip-recording
  /// screen title. Defaults to `false`.
  static const String obd2DebugOverlayEnabled = 'obd2_debug_overlay_enabled';

  /// #1925 — opt-in OBD2 debug-session logging. When on, each OBD2
  /// connection is recorded (init handshake, data gaps, reconnects)
  /// as an exportable XML session log. Toggled by a checkbox in the
  /// Trips (OBD2) settings sub-section. Defaults to `false`.
  static const String obd2DebugSessionLoggingEnabled =
      'obd2_debug_session_logging_enabled';

  /// #1396 — prefix for the per-vehicle "we already nudged this user
  /// to re-pick their catalog row" Hive flag. The full key is
  /// `<prefix><vehicleId>` and stores a `bool true` once the snackbar
  /// fires for a given vehicle, so it never fires twice for the same
  /// profile even if the user dismisses the snackbar without tapping.
  ///
  /// The detector flags vehicles whose `preferredFuelType == "diesel"`
  /// but whose resolved [referenceVehicleId] points at a non-diesel
  /// catalog entry — which used to be the only outcome for a 1.5 dCi
  /// Dacia Duster (the catalog shipped only the TCe 130 petrol row
  /// for that body). With the diesel siblings added in this PR the
  /// nudge gives existing users a one-time prompt to update their
  /// pick.
  static const String vehicleCatalogReresolveSuggestedPrefix =
      'vehicle_catalog_reresolve_suggested_';

  /// #1792 — device-local "Save as default values" for the search
  /// criteria that have no `UserProfile` field of their own. Fuel type
  /// and radius live on the profile; open-only, the amenity set and the
  /// brand filter persist here so the whole default set round-trips
  /// when the Search-criteria screen reopens, not just the profile
  /// subset.
  static const String defaultOpenOnly = 'default_open_only';
  static const String defaultAmenities = 'default_amenities';
  static const String defaultBrands = 'default_brands';
  static const String defaultExcludeHighway = 'default_exclude_highway';

  /// #2785 — "always pin when the fuel-station radar starts" preference.
  /// Defaults to true (absent key → on), mirroring the trip-recording
  /// auto-pin default; the radar pin-help sheet's toggle persists it.
  static const String radarAutoPin = 'radar_auto_pin';

  /// #2274 concern 1 — JSON-encoded global [RecordingProfile]
  /// (autoPin / autoEnterReducedOnStart / keepScreenAwake). Absent ⇒
  /// every field off (the opt-in-each-drive default). Applied on the
  /// recording screen's `initState` so a user who flips `autoPin` once
  /// gets the screen pinned automatically on every subsequent start.
  static const String recordingProfile = 'recording_profile';

  /// #2274 concern 1 — prefix for a per-vehicle [RecordingProfile]
  /// override. The full key is `<prefix><vehicleId>`; an override is
  /// persisted only when it differs from the all-default profile, and a
  /// missing override falls through to [recordingProfile].
  static const String recordingProfileVehicleOverridePrefix =
      'recording_profile_vehicle_';

  /// #3069 — running count of "positive moments" (a successful station
  /// search that returned results) since the last review prompt. The
  /// in-app review service requests an OS-native rating dialog once this
  /// reaches the threshold, then resets it to 0. Stored in plain Hive
  /// settings (a counter, not PII).
  static const String inAppReviewPositiveSignalCount =
      'in_app_review_positive_signal_count';

  /// #3069 — ISO-8601 timestamp of the last review-prompt attempt. Used
  /// to enforce the 30-day throttle so we never re-ask a user inside the
  /// cooldown window (the OS itself also rate-limits, but we never even
  /// reach the platform channel before this gate passes). Absent ⇒ never
  /// prompted.
  static const String inAppReviewLastPromptIso =
      'in_app_review_last_prompt_iso';

  /// #3647 — per-vehicle prefix for the persisted OBD2 fuel-level
  /// snapshot (`<prefix><vehicleId>` -> JSON `{"l": litres, "at": ms}`).
  /// The ONLY reader/writer is [Obd2FuelLevelSnapshotStore] (#3592
  /// one-accessor rule).
  static const String obd2FuelLevelSnapshotPrefix =
      'obd2_fuel_level_snapshot_';

  /// #3877 — per-vehicle latest odometer from OBD2 (`{km, at, src}`), the
  /// fill-up form's prefill source. One entry per vehicle id.
  static const String obd2OdometerSnapshotPrefix = 'obd2_odometer_snapshot_';

  /// #3726 — device-local block list for community-content authors
  /// (Play UGC policy). Stores the TankSync user ids whose shared
  /// content ("Shared with me" trips, and any future community surface)
  /// is filtered out of display on this device. Local-only, never
  /// synced — blocking is a viewer preference, not shared state.
  static const String blockedContentAuthorIds = 'blocked_content_author_ids';

  /// #3726 — device-local ids of community-content items the user
  /// REPORTED (`content_reports.target_id`). A reported item is hidden
  /// locally right away, and stays hidden across restarts, without
  /// waiting for any server-side moderation outcome.
  static const String reportedContentTargetIds = 'reported_content_target_ids';

  /// #3871 (Epic #3865, GDPR) — `true` once the one-time "Shared with
  /// other users" notice was accepted. Shown before the FIRST public
  /// contribution (a community price report, or switching ratings to
  /// "shared"); never again after Continue. Cancel leaves it unset.
  static const String ugcPublicNoticeShown = 'ugc_public_notice_shown';
}
