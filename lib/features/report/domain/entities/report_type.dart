import '../../../../l10n/app_localizations.dart';

/// The kind of correction the user is filing against a station.
///
/// Report types fall into three buckets:
/// 1. **Price reports** (wrongE5, wrongE10, wrongDiesel, wrongE85,
///    wrongE98, wrongLpg) — take a corrected price number.
/// 2. **Status reports** (wrongStatusOpen, wrongStatusClosed) — no
///    payload, just a flag.
/// 3. **Metadata reports** (wrongName, wrongAddress) — take a free-text
///    correction.
///
/// Routing also splits them: the first 5 (E5/E10/Diesel + status) can go
/// to the Tankerkoenig complaint endpoint (DE-only, API key required);
/// everything price-like also goes to TankSync; metadata types route to
/// a pre-filled GitHub issue because they're almost always implementation
/// bugs, not data corrections (#508).
enum ReportType {
  // Tankerkoenig-supported price reports. apiValue maps to the types
  // the Tankerkoenig complaint endpoint recognises.
  wrongE5('wrongPetrolPremium'),
  wrongE10('wrongPetrolPremiumE10'),
  wrongDiesel('wrongDiesel'),
  // Additional price reports (#484). Tankerkoenig has no endpoint
  // for these, so they route to TankSync only. The `apiValue` is a
  // descriptive string for logging but is not sent to Tankerkoenig —
  // `isTankerkoenigSupported` below controls which backends accept
  // which types.
  wrongE85('wrongPetrolE85'),
  wrongE98('wrongPetrolPremiumE98'),
  wrongLpg('wrongLpg'),
  wrongStatusOpen('wrongStatusOpen'),
  wrongStatusClosed('wrongStatusClosed'),
  // Metadata reports (#484). These carry a free-text correction
  // instead of a price. TankSync only.
  wrongName('wrongName'),
  wrongAddress('wrongAddress');

  final String apiValue;
  const ReportType(this.apiValue);

  /// True when this report type needs the user to enter a corrected
  /// price. Price input replaces the text input in the form.
  bool get needsPrice =>
      this == wrongE5 ||
      this == wrongE10 ||
      this == wrongDiesel ||
      this == wrongE85 ||
      this == wrongE98 ||
      this == wrongLpg;

  /// True when this report type is a free-text metadata correction
  /// (new station name, new address). Takes a text input instead of
  /// a price input.
  ///
  /// Since #508 these also route to GitHub instead of TankSync —
  /// wrong metadata is almost always an implementation bug (the API
  /// returned the wrong field, or our parser mapped it wrong), not
  /// something a user correction can fix downstream.
  bool get needsText => this == wrongName || this == wrongAddress;

  /// True when this report type files a GitHub issue instead of hitting
  /// a community-report backend. Station name and address corrections
  /// are always implementation bugs — shipping them as community edits
  /// just hides the upstream issue, so we route the user to the
  /// pre-filled GitHub issue flow built in #500 instead.
  bool get routesToGitHub => this == wrongName || this == wrongAddress;

  /// True when this report type can be submitted to the Tankerkoenig
  /// complaint endpoint. The endpoint supports the original 5 types
  /// (E5, E10, diesel, status open, status closed). Everything else
  /// is TankSync-only.
  bool get isTankerkoenigSupported =>
      this == wrongE5 ||
      this == wrongE10 ||
      this == wrongDiesel ||
      this == wrongStatusOpen ||
      this == wrongStatusClosed;

  /// The Supabase `fuel_type` column value for this report. For price
  /// reports this is the fuel code; for status and metadata reports
  /// it's a descriptive identifier so analytics queries can filter
  /// by report kind.
  String get fuelTypeColumnValue {
    switch (this) {
      case wrongE5:
        return 'e5';
      case wrongE10:
        return 'e10';
      case wrongDiesel:
        return 'diesel';
      case wrongE85:
        return 'e85';
      case wrongE98:
        return 'e98';
      case wrongLpg:
        return 'lpg';
      case wrongStatusOpen:
        return 'status_open';
      case wrongStatusClosed:
        return 'status_closed';
      case wrongName:
        return 'name';
      case wrongAddress:
        return 'address';
    }
  }

  /// Returns the report types that should be visible on the report
  /// screen for a given country.
  ///
  /// - Germany: all 10 types (Tankerkoenig community report covers
  ///   prices and open/closed status; name/address still route to
  ///   GitHub because they're implementation bugs).
  /// - Everywhere else: only the 2 GitHub-routed types. The first 8
  ///   (price + status) have no meaningful backend outside DE —
  ///   Tankerkoenig is DE-only, and community price corrections don't
  ///   feed back into the source-of-truth country APIs.
  static List<ReportType> visibleForCountry(String countryCode) {
    if (countryCode == 'DE') return ReportType.values;
    return const [ReportType.wrongName, ReportType.wrongAddress];
  }

  /// Localized display name for this report type.
  String displayName(AppLocalizations? l10n) {
    switch (this) {
      case wrongE5:
        return l10n?.wrongE5Price ?? 'Prix Super E5 incorrect';
      case wrongE10:
        return l10n?.wrongE10Price ?? 'Prix Super E10 incorrect';
      case wrongDiesel:
        return l10n?.wrongDieselPrice ?? 'Prix Diesel incorrect';
      // TODO: add ARB keys for the new types. Inline French fallback
      // matches the primary user locale.
      case wrongE85:
        return 'Prix E85 incorrect';
      case wrongE98:
        return 'Prix Super 98 incorrect';
      case wrongLpg:
        return 'Prix GPL incorrect';
      case wrongStatusOpen:
        return l10n?.wrongStatusOpen ?? 'Affiché ouvert, mais fermé';
      case wrongStatusClosed:
        return l10n?.wrongStatusClosed ?? 'Affiché fermé, mais ouvert';
      case wrongName:
        return 'Nom de la station incorrect';
      case wrongAddress:
        return 'Adresse incorrecte';
    }
  }
}
