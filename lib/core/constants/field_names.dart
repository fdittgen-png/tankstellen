/// Tankerkoenig API response field names.
///
/// Centralizes magic strings used when parsing JSON responses from
/// the Tankerkoenig prices API, preventing typos and making
/// field renames easy to trace.
class TankerkoenigFields {
  TankerkoenigFields._();

  static const ok = 'ok';
  static const prices = 'prices';
  static const message = 'message';
  static const status = 'status';
  static const statusOpen = 'open';
  static const statusNoPrices = 'no prices';
  static const e5 = 'e5';
  static const e10 = 'e10';
  static const diesel = 'diesel';
  static const isOpen = 'isOpen';
}

/// Supabase table and column names for TankSync.
///
/// Keeps all Supabase schema references in one place so that
/// a column rename in the database only requires changing one file.
class SyncFields {
  SyncFields._();

  // Tables
  static const usersTable = 'users';
  static const favoritesTable = 'favorites';
  static const alertsTable = 'alerts';
  static const ratingsTable = 'station_ratings';
  static const routesTable = 'saved_routes';
  static const reportsTable = 'price_reports';
  static const ignoredTable = 'ignored_stations';
  static const linkCodesTable = 'link_codes';

  // Common columns
  static const id = 'id';
  static const userId = 'user_id';
  static const stationId = 'station_id';
  static const fuelType = 'fuel_type';
  static const countryCode = 'country_code';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';

  // Favorites columns
  static const stationName = 'station_name';
  static const stationBrand = 'station_brand';

  // Alerts columns
  static const targetPrice = 'target_price';
  static const isActive = 'is_active';

  // Ratings columns
  static const rating = 'rating';
  static const comment = 'comment';

  // Reports columns
  static const reporterId = 'reporter_id';
  static const reportedPrice = 'reported_price';
  static const reportedAt = 'reported_at';

  // Link codes columns
  static const code = 'code';
  static const expiresAt = 'expires_at';
}
