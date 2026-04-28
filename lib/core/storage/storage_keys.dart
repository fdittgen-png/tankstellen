class StorageKeys {
  StorageKeys._();

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
  static const String swipeTutorialShown = 'swipe_tutorial_shown';
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
  static const String supabaseAnonKey = 'supabase_anon_key';
  /// #580 — ntfy.sh push mirror of the Supabase push_tokens row, so
  /// the background isolate can fire push alerts without needing a
  /// Riverpod / Supabase handshake from inside WorkManager.
  static const String ntfyEnabled = 'ntfy_enabled';
  static const String ntfyTopic = 'ntfy_topic';

  /// #780 — opt-in switch for per-vehicle baseline sync. Defaults to
  /// false (off) so users who only want favourite sync aren't
  /// silently uploading driving data.
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
  static const String hapticEcoCoachEnabled = 'haptic_eco_coach_enabled';

  /// #1273 — one-shot flag tracking whether we've already shown the
  /// "recording continues in the background, tap the red banner to
  /// return" tip the first time a user backs out of the recording
  /// screen mid-trip. Default null/false → tip shows once; flips to
  /// true on display, never resurfacing on this install.
  static const String tripRecordingResumeTipShown =
      'trip_recording_resume_tip_shown';
}
