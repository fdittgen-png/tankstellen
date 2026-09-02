// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favorites';

  @override
  String get map => 'Map';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get gpsLocation => 'GPS Location';

  @override
  String get zipCode => 'Postal code';

  @override
  String get zipCodeHint => 'e.g. 10115';

  @override
  String get fuelType => 'Fuel type';

  @override
  String get searchRadius => 'Radius';

  @override
  String get searchNearby => 'Nearby stations';

  @override
  String get fabRunSearch => 'Run search';

  @override
  String get routeSearchingChip => 'Searching the route…';

  @override
  String get searchCriteriaTitle => 'Search criteria';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Within $km km';
  }

  @override
  String get noResults => 'No stations found.';

  @override
  String get startSearch => 'Search to find fuel stations.';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String distance(String distance) {
    return '$distance away';
  }

  @override
  String get price => 'Price';

  @override
  String get prices => 'Prices';

  @override
  String get address => 'Address';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get open24h => 'Open 24 hours';

  @override
  String get navigate => 'Navigate';

  @override
  String get retry => 'Try again';

  @override
  String get apiKeySetup => 'API key setup';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get register => 'Registration';

  @override
  String get continueButton => 'Continue';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle => 'Find the cheapest fuel near you.';

  @override
  String get profileName => 'Profile name';

  @override
  String get preferredFuel => 'Preferred fuel';

  @override
  String get defaultRadius => 'Default radius';

  @override
  String get landingScreen => 'Start screen';

  @override
  String get homeZip => 'Home postal code';

  @override
  String get newProfile => 'New profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get countryChangeTitle => 'Switch country?';

  @override
  String countryChangeBody(String country) {
    return 'Switching to $country will change:';
  }

  @override
  String get countryChangeCurrency => 'Currency';

  @override
  String get countryChangeDistance => 'Distance';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Price format';

  @override
  String get countryChangeNote =>
      'Existing favorites and fill-up logs are not rewritten; only new entries use the new units.';

  @override
  String get countryChangeConfirm => 'Switch';

  @override
  String get delete => 'Delete';

  @override
  String get activate => 'Activate';

  @override
  String get configured => 'Configured';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get about => 'About';

  @override
  String get openSource => 'Open Source (MIT License)';

  @override
  String get sourceCode => 'Source code on GitHub';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get noFavoritesHint =>
      'Tap the star on a station to save it as a favorite.';

  @override
  String get language => 'Language';

  @override
  String get country => 'Country';

  @override
  String get freeNoKey => 'Free — no key needed';

  @override
  String get apiKeyRequired => 'API key required';

  @override
  String get dataTransparency => 'Data transparency';

  @override
  String get clearCache => 'Clear cache';

  @override
  String stationsFound(int count) {
    return '$count stations found';
  }

  @override
  String get storageUsage => 'Storage usage on this device';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get total => 'Total';

  @override
  String get cacheDescription =>
      'The cache stores API responses for faster loading and offline access.';

  @override
  String get cacheTtlGroupNetwork => 'Network';

  @override
  String get cacheTtlGroupData => 'Data';

  @override
  String get cacheTtlGroupGeocoding => 'Geocoding';

  @override
  String get stationSearch => 'Station search';

  @override
  String get stationDetails => 'Station details';

  @override
  String get priceQuery => 'Price query';

  @override
  String get zipGeocoding => 'Postal code geocoding';

  @override
  String minutes(int n) {
    return '$n minutes';
  }

  @override
  String hours(int n) {
    return '$n hours';
  }

  @override
  String get clearCacheTitle => 'Clear cache?';

  @override
  String get clearCacheBody =>
      'Cached search results and prices will be deleted. Profiles, favorites and settings are preserved.';

  @override
  String get clearCacheButton => 'Clear cache';

  @override
  String get deleteAllButton => 'Delete all';

  @override
  String get cacheEmpty => 'Cache is empty';

  @override
  String get apiKeyNote =>
      'Free registration. Data from government price transparency agencies.';

  @override
  String get apiKeyFormatError => 'Invalid format — expected UUID (8-4-4-4-12)';

  @override
  String get reportThisIssue => 'Report this issue';

  @override
  String get reportAlreadySent => 'You already reported this issue.';

  @override
  String get reportConsentTitle => 'Report to GitHub?';

  @override
  String get reportConsentBody =>
      'This will open a public GitHub issue with the error details below. No GPS coordinates, API keys, or personal data are included.';

  @override
  String get reportConsentConfirm => 'Open GitHub';

  @override
  String get reportConsentCancel => 'Cancel';

  @override
  String get searchLocationPlaceholder => 'Address, postal code or city';

  @override
  String get configTankSyncConnected => 'Connected';

  @override
  String get configTankSyncDisabled => 'Disabled';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get fuels => 'Fuels';

  @override
  String get zone => 'Zone';

  @override
  String get highway => 'Highway';

  @override
  String get localStation => 'Local station';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get automate24h => '24h/24 — Automate';

  @override
  String get refreshPrices => 'Refresh prices';

  @override
  String get station => 'Station';

  @override
  String get locationDenied =>
      'Location permission denied. You can search by postal code.';

  @override
  String get demoModeBanner => 'Demo mode — showing sample prices.';

  @override
  String get demoModeBannerAction => 'Get live prices';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'cheap';

  @override
  String get expensive => 'expensive';

  @override
  String get reportPrice => 'Report price';

  @override
  String get whatsWrong => 'What\'s wrong?';

  @override
  String get correctPrice => 'Correct price (e.g. 1.459)';

  @override
  String get sendReport => 'Send report';

  @override
  String get reportSent => 'Report sent. Thank you!';

  @override
  String get enterValidPrice => 'Please enter a valid price';

  @override
  String get cacheCleared => 'Cache cleared.';

  @override
  String get yourPosition => 'Your position';

  @override
  String get positionUnknown => 'Position unknown';

  @override
  String get distancesFromCenter => 'Distances from search center';

  @override
  String get autoUpdatePosition => 'Auto-update position';

  @override
  String get autoUpdateDescription => 'Refresh GPS position before each search';

  @override
  String get location => 'Location';

  @override
  String get switchProfileTitle => 'Country changed';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'You are now in $country. Switch to profile \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Switched to profile \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'No profile for this country';

  @override
  String noProfileForCountry(String country) {
    return 'You are in $country, but no profile is configured for it. Create one in Settings.';
  }

  @override
  String get autoSwitchProfile => 'Auto-switch profile';

  @override
  String get autoSwitchDescription =>
      'Automatically switch profile when crossing borders';

  @override
  String profileSwitchedTo(String profile) {
    return 'Switched to $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profile $name created';
  }

  @override
  String profileCountryTaken(String country) {
    return 'A profile for $country already exists — edit it instead.';
  }

  @override
  String get switchProfile => 'Switch';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get profileCountry => 'Country';

  @override
  String get profileLanguage => 'Language';

  @override
  String get settingsStorageDetail => 'API key, active profile';

  @override
  String get allFuels => 'All';

  @override
  String get priceAlerts => 'Price Alerts';

  @override
  String get noPriceAlertsHint =>
      'Create an alert from a station\'s detail page.';

  @override
  String alertDeleted(String name) {
    return 'Alert \"$name\" deleted';
  }

  @override
  String get createAlert => 'Create Price Alert';

  @override
  String currentPrice(String price) {
    return 'Current price: $price';
  }

  @override
  String get targetPrice => 'Target price (EUR)';

  @override
  String get enterPrice => 'Please enter a price';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get priceTooHigh => 'Price too high';

  @override
  String get create => 'Create';

  @override
  String get alertCreated => 'Price alert created';

  @override
  String get wrongE5Price => 'Wrong Super E5 price';

  @override
  String get wrongE10Price => 'Wrong Super E10 price';

  @override
  String get wrongDieselPrice => 'Wrong Diesel price';

  @override
  String get wrongStatusOpen => 'Shown as open, but closed';

  @override
  String get wrongStatusClosed => 'Shown as closed, but open';

  @override
  String get allStations => 'All stations';

  @override
  String get bestStops => 'Best stops';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get noStationsAlongRoute => 'No stations found along route';

  @override
  String get evOperational => 'Operational';

  @override
  String get evStatusUnknown => 'Status unknown';

  @override
  String evConnectors(int count) {
    return 'Connectors ($count points)';
  }

  @override
  String get evNoConnectors => 'No connector details available';

  @override
  String get evUsageCost => 'Usage cost';

  @override
  String get evPricingUnavailable => 'Pricing not available from provider';

  @override
  String get evPriceFree => 'Free';

  @override
  String get evPricePayAtLocation => 'Pay at location';

  @override
  String get evPriceMembership => 'Membership required';

  @override
  String get evPriceIndicative => 'Indicative price';

  @override
  String get evPriceDeclaredByOperator =>
      'Indicative price declared by the operator — verify on site';

  @override
  String get evPriceFranceAttribution =>
      'Pricing: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Best-effort pricing from OpenChargeMap — sparse and may be incomplete.';

  @override
  String get evLastUpdated => 'Last updated';

  @override
  String get evUnknown => 'Unknown';

  @override
  String get evDataAttribution => 'Data from OpenChargeMap (community-sourced)';

  @override
  String get evStatusDisclaimer =>
      'Status may not reflect real-time availability. Tap refresh to get the latest data.';

  @override
  String get evNavigateToStation => 'Navigate to station';

  @override
  String get evRefreshStatus => 'Refresh status';

  @override
  String get evStatusUpdated => 'Status updated';

  @override
  String get evStationNotFound =>
      'Could not refresh — station not found nearby';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get currentLocation => 'Current location';

  @override
  String get gpsError => 'GPS error';

  @override
  String get couldNotResolve => 'Could not resolve start or destination';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get cityAddressOrGps => 'City, address, or GPS';

  @override
  String get cityOrAddress => 'City or address';

  @override
  String get useGps => 'Use GPS';

  @override
  String get stop => 'Stop';

  @override
  String get addStop => 'Add stop';

  @override
  String get searchAlongRoute => 'Search along route';

  @override
  String get cheapest => 'Cheapest';

  @override
  String nStations(int count) {
    return '$count stations';
  }

  @override
  String nBest(int count) {
    return '$count best';
  }

  @override
  String get fuelPricesTankerkoenig => 'Fuel prices (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Required for fuel price search in Germany';

  @override
  String get evChargingOpenChargeMap => 'EV Charging (OpenChargeMap)';

  @override
  String get customKey => 'Custom key';

  @override
  String get appDefaultKey => 'App default key';

  @override
  String get optionalOverrideKey =>
      'Optional: override the built-in app key with your own';

  @override
  String get edit => 'Edit';

  @override
  String get fuelPricesApiKey => 'Fuel prices API Key';

  @override
  String get evChargingApiKey => 'EV Charging API Key';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API Key';

  @override
  String get routePlanningSection => 'Route planning';

  @override
  String get routeMinSaving => 'Minimum saving';

  @override
  String get routeMinSavingOff => 'Off';

  @override
  String get routeMinSavingOffCaption =>
      'Showing every station found along the route';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Only stations within $amount of the route\'s cheapest';
  }

  @override
  String get routeDetourBudget => 'Maximum detour';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Surface stations up to $km km off your direct route';
  }

  @override
  String get routeSegment => 'Route segment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Show cheapest station every $km km along route';
  }

  @override
  String get avoidHighways => 'Avoid highways';

  @override
  String get avoidHighwaysDesc =>
      'Route calculation avoids toll roads and highways';

  @override
  String get noStationsAlongThisRoute => 'No stations found along this route.';

  @override
  String get fuelCostCalculator => 'Fuel Cost Calculator';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get tripCost => 'Trip Cost';

  @override
  String get fuelNeeded => 'Fuel needed';

  @override
  String get totalCost => 'Total cost';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consumption ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Fuel price ($unit)';
  }

  @override
  String get calculatorUseMine => 'Use';

  @override
  String get calculatorApplied => 'Applied';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get calculatorRoundTrip => 'Round trip';

  @override
  String get roundTripTotal => 'Round trip';

  @override
  String get costPerDistance => 'Cost per km';

  @override
  String get costPerMonth => 'Cost per month';

  @override
  String get calculatorEstimateMonthly => 'Estimate monthly cost';

  @override
  String get calculatorTripsPerMonth => 'Trips per month';

  @override
  String get calculatorTripsPerMonthHint => 'e.g. 20';

  @override
  String get calculatorReset => 'Reset';

  @override
  String get calculatorResultPlaceholder =>
      'Fill in distance, consumption and price to see your trip cost';

  @override
  String get priceHistory => 'Price History';

  @override
  String get favoritesDataCache => 'Favorites data';

  @override
  String get citySearchCache => 'City search';

  @override
  String get noPriceHistory => 'No price history yet';

  @override
  String get noStatistics => 'No statistics available';

  @override
  String get showAllFuelTypes => 'Show all fuel types';

  @override
  String get connected => 'Connected';

  @override
  String get disconnectTankSync => 'Disconnect TankSync';

  @override
  String get viewMyData => 'View my data';

  @override
  String get deleteAllServerData => 'Delete all server data';

  @override
  String get deleteServerDataConfirm => 'Delete all server data?';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get allDataDeleted => 'All server data deleted';

  @override
  String get forgetAllSyncedTripsButton => 'Forget all synced trips';

  @override
  String get forgetAllSyncedTripsConfirmTitle => 'Forget all synced trips?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Every trip summary and detail blob will be removed from the server. Your local trip history on this device won\'t be affected.\n\nThis action cannot be undone.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Forget all';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'All synced trips removed from server';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get myServerData => 'My server data';

  @override
  String get anonymousUuid => 'Anonymous UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synced data';

  @override
  String get pushTokens => 'Push tokens';

  @override
  String get priceReports => 'Price reports';

  @override
  String get syncedTrips => 'Trips';

  @override
  String get totalItems => 'Total items';

  @override
  String get estimatedSize => 'Estimated size';

  @override
  String get viewRawJson => 'View raw data as JSON';

  @override
  String get exportJson => 'Export as JSON (clipboard)';

  @override
  String get jsonCopied => 'JSON copied to clipboard';

  @override
  String get rawDataJson => 'Raw data (JSON)';

  @override
  String get close => 'Close';

  @override
  String get account => 'Account';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get savedRoutes => 'Saved Routes';

  @override
  String get noSavedRoutes => 'No saved routes';

  @override
  String get noSavedRoutesHint =>
      'Search along a route and save it for quick access later.';

  @override
  String get saveRoute => 'Save route';

  @override
  String get routeName => 'Route name';

  @override
  String itineraryDeleted(String name) {
    return '$name deleted';
  }

  @override
  String loadingRoute(String name) {
    return 'Loading route: $name';
  }

  @override
  String get refreshFailed => 'Refresh failed. Please try again.';

  @override
  String get deleteProfileTitle => 'Delete profile?';

  @override
  String get deleteProfileBody =>
      'This profile and its settings will be permanently deleted. This cannot be undone.';

  @override
  String get deleteProfileConfirm => 'Delete profile';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorTimeout => 'Connection timed out. Please try again.';

  @override
  String get errorNoConnection => 'No internet connection.';

  @override
  String get errorApiKey => 'Invalid API key. Check your settings.';

  @override
  String get errorLocation => 'Could not determine your location.';

  @override
  String get errorNoApiKey =>
      'No API key configured. Go to Settings to add one.';

  @override
  String get errorAllServicesFailed =>
      'Could not load data. Check your connection and try again.';

  @override
  String get errorCache => 'Local data error. Try clearing the cache.';

  @override
  String get errorCancelled => 'Request was cancelled.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get onboardingWelcomeHint => 'Set up the app in a few quick steps.';

  @override
  String get onboardingApiKeyDescription =>
      'Register for a free API key, or skip to explore the app with demo data.';

  @override
  String get onboardingComplete => 'All set!';

  @override
  String get onboardingCompleteHint =>
      'You can change these settings anytime in your profile.';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingFinish => 'Get started';

  @override
  String get switchToAllPricesView => 'Switch to all-prices view';

  @override
  String get switchToCompactView => 'Switch to compact view';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get gdprTitle => 'Your Privacy';

  @override
  String get gdprSubtitle =>
      'This app respects your privacy. Choose which data you want to share. You can change these settings anytime.';

  @override
  String get gdprLocationTitle => 'Location Access';

  @override
  String get gdprLocationDescription =>
      'Your coordinates are sent to the fuel price API to find nearby stations. Location data is never stored on a server and is not used for tracking.';

  @override
  String get gdprLocationShort =>
      'Find nearby fuel stations using your location';

  @override
  String get gdprErrorReportingTitle => 'Error Reporting';

  @override
  String get gdprErrorReportingDescription =>
      'Anonymous crash reports help improve the app. No personal data is included. Reports are sent via Sentry only when configured.';

  @override
  String get gdprErrorReportingShort =>
      'Send anonymous crash reports to improve the app';

  @override
  String get gdprCloudSyncTitle => 'Cloud Sync';

  @override
  String get gdprCloudSyncDescription =>
      'Sync favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.';

  @override
  String get gdprCloudSyncShort => 'Sync favorites and alerts across devices';

  @override
  String get gdprLegalBasis =>
      'Legal basis: Art. 6(1)(a) GDPR (Consent). You can withdraw consent anytime in Settings.';

  @override
  String get gdprContinueAll => 'Continue with all';

  @override
  String get gdprContinueSelected => 'Continue with selected';

  @override
  String get gdprSettingsHint =>
      'You can change your privacy choices at any time.';

  @override
  String get routeSaved => 'Route saved!';

  @override
  String get routeSaveFailed => 'Failed to save route';

  @override
  String get sqlCopied => 'SQL copied to clipboard';

  @override
  String get connectionDataCopied => 'Connection data copied';

  @override
  String get accountDeleted => 'Account deleted. Local data preserved.';

  @override
  String get switchedToAnonymous => 'Switched to anonymous session';

  @override
  String failedToSwitch(String error) {
    return 'Failed to switch: $error';
  }

  @override
  String get connectedAsGuest => 'Connected as guest';

  @override
  String get accountCreated => 'Account created!';

  @override
  String get signedIn => 'Signed in!';

  @override
  String stationHidden(String name) {
    return '$name hidden';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name removed from favorites';
  }

  @override
  String invalidApiKey(String error) {
    return 'Invalid API key: $error';
  }

  @override
  String get invalidQrCode => 'Invalid QR code format';

  @override
  String get invalidQrCodeTankSync =>
      'Invalid QR code — expected TankSync format';

  @override
  String get tankSyncConnected => 'TankSync connected!';

  @override
  String get syncCompleted => 'Sync completed — data refreshed';

  @override
  String get deviceCodeCopied => 'Device code copied';

  @override
  String get undo => 'Undo';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Please enter a valid $length-digit $label';
  }

  @override
  String get freshnessAgo => 'ago';

  @override
  String get freshnessStale => 'Stale';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Data freshness: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand logo';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rate $count stars',
      one: 'Rate 1 star',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordReqMinLength => 'At least 8 characters';

  @override
  String get passwordReqUppercase => 'At least 1 uppercase letter';

  @override
  String get passwordReqLowercase => 'At least 1 lowercase letter';

  @override
  String get passwordReqDigit => 'At least 1 number';

  @override
  String get passwordReqSpecial => 'At least 1 special character';

  @override
  String get passwordTooWeak => 'Password does not meet all requirements';

  @override
  String get brandFilterAll => 'All';

  @override
  String get brandFilterNoHighway => 'No highway';

  @override
  String get swipeTutorialMessage =>
      'Swipe right to navigate, swipe left to remove';

  @override
  String get swipeTutorialDismiss => 'Got it';

  @override
  String get alertStatsActive => 'Active';

  @override
  String get alertStatsToday => 'Today';

  @override
  String get alertStatsThisWeek => 'This week';

  @override
  String get privacyLocalData => 'Data on this device';

  @override
  String get privacyIgnoredStations => 'Ignored stations';

  @override
  String get privacyRatings => 'Station ratings';

  @override
  String get privacyPriceHistory => 'Price history stations';

  @override
  String get privacyProfiles => 'Search profiles';

  @override
  String get privacyItineraries => 'Saved routes';

  @override
  String get privacySyncMode => 'Sync mode';

  @override
  String get privacySyncUserId => 'User ID';

  @override
  String get privacySyncDescription =>
      'When sync is enabled, favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips are also stored on the TankSync server.';

  @override
  String get privacyExportSuccess => 'Data exported to clipboard';

  @override
  String get privacyExportCsvSuccess => 'CSV data exported to clipboard';

  @override
  String get savedToDownloadsFolder => 'Saved to your Downloads folder';

  @override
  String get privacyErrorLogCleared => 'Error log cleared';

  @override
  String get privacyDeleteTitle => 'Delete all data?';

  @override
  String get privacyDeleteBody =>
      'This will permanently delete:\n\n- All favorites and station data\n- All search profiles\n- All price alerts\n- All price history\n- All cached data\n- Your API key\n- All app settings\n\nThe app will reset to its initial state. This action cannot be undone.';

  @override
  String get privacyDeleteConfirm => 'Delete everything';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get amenities => 'Amenities';

  @override
  String get amenityShop => 'Shop';

  @override
  String get amenityCarWash => 'Car Wash';

  @override
  String get amenityAirPump => 'Air';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Food';

  @override
  String get amenityAtm => 'ATM';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'EV';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Fuel Card';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Pay with $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Compared to the rolling average over your last 3 fill-ups ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumption $value L/100 km, $delta versus your rolling average';
  }

  @override
  String get drivingMode => 'Driving Mode';

  @override
  String get drivingExit => 'Exit';

  @override
  String get drivingNearestStation => 'Nearest';

  @override
  String get drivingTapToUnlock => 'Tap to unlock';

  @override
  String get drivingSafetyTitle => 'Safety Notice';

  @override
  String get drivingSafetyMessage =>
      'Do not operate the app while driving. Pull over to a safe location before interacting with the screen. The driver is responsible for safe operation of the vehicle at all times.';

  @override
  String get drivingSafetyAccept => 'I understand';

  @override
  String get voiceAnnouncementsTitle => 'Voice Announcements';

  @override
  String get voiceAnnouncementsDescription =>
      'Announce nearby cheap stations while driving';

  @override
  String get voiceAnnouncementsEnabled => 'Enable voice announcements';

  @override
  String get voiceAnnouncementProximityRadius => 'Announcement radius';

  @override
  String get voiceAnnouncementCooldown => 'Repeat interval';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximum price';

  @override
  String get consumptionStatsTitle => 'Consumption stats';

  @override
  String get addFillUp => 'Add fill-up';

  @override
  String get noFillUpsTitle => 'No fill-ups yet';

  @override
  String get noFillUpsSubtitle =>
      'Log your first fill-up to start tracking consumption.';

  @override
  String get fillUpDate => 'Date';

  @override
  String get liters => 'Liters';

  @override
  String get odometerKm => 'Odometer (km)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get statAvgConsumption => 'Avg L/100km';

  @override
  String get statAvgCostPerKm => 'Avg cost/km';

  @override
  String get statTotalLiters => 'Total liters';

  @override
  String get statTotalSpent => 'Total spent';

  @override
  String get statFillUpCount => 'Fill-ups';

  @override
  String get fieldRequired => 'Required';

  @override
  String get fieldInvalidNumber => 'Invalid number';

  @override
  String get carbonDashboardTitle => 'Carbon dashboard';

  @override
  String get carbonEmptyTitle => 'No data yet';

  @override
  String get carbonEmptySubtitle =>
      'Log fill-ups to see your carbon dashboard.';

  @override
  String get carbonSummaryTotalCost => 'Total cost';

  @override
  String get carbonSummaryTotalCo2 => 'Total CO2';

  @override
  String get monthlyCostsTitle => 'Monthly costs';

  @override
  String get monthlyEmissionsTitle => 'Monthly CO2 emissions';

  @override
  String get vehiclesTitle => 'My vehicles';

  @override
  String get vehiclesMenuTitle => 'My vehicles';

  @override
  String get vehiclesMenuSubtitle =>
      'Your cars — fuel type, engine and tank size for accurate consumption estimates';

  @override
  String get vehiclesEmptyMessage =>
      'Add your car to filter by connector and estimate charging costs.';

  @override
  String get vehiclesWizardTitle => 'My vehicles (optional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Add your car to pre-fill the consumption log and enable EV connector filters. You can skip this and add vehicles later.';

  @override
  String get vehiclesWizardNoneYet => 'No vehicle configured yet.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles',
      one: '1 vehicle',
    );
    return 'You have $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Skip to finish setup — you can add vehicles anytime from Settings.';

  @override
  String get fillUpVehicleLabel => 'Vehicle';

  @override
  String get fillUpVehicleRequired => 'Vehicle is required';

  @override
  String get reportScanError => 'Report scan error';

  @override
  String get pickStationTitle => 'Pick a station';

  @override
  String get pickStationHelper =>
      'Start the fill-up from a known station so prices, brand and fuel type fill themselves in.';

  @override
  String get pickStationEmpty =>
      'No favorite stations yet — add some from Search or Favorites, or skip and fill in manually.';

  @override
  String get pickStationSkip => 'Skip — add without a station';

  @override
  String get scanPayment => 'Scan payment QR';

  @override
  String get qrPaymentBeneficiary => 'Beneficiary';

  @override
  String get qrPaymentAmount => 'Amount';

  @override
  String get qrPaymentEpcTitle => 'SEPA payment';

  @override
  String get qrPaymentEpcEmpty => 'No fields decoded';

  @override
  String get qrPaymentOpenInBank => 'Open in bank app';

  @override
  String get qrPaymentLaunchFailed => 'No app available to open this code';

  @override
  String get qrPaymentUnknownTitle => 'Unrecognised code';

  @override
  String get qrPaymentCopyRaw => 'Copy raw text';

  @override
  String get qrPaymentCopiedRaw => 'Copied to clipboard';

  @override
  String get qrPaymentReport => 'Report this scan';

  @override
  String get qrPaymentEpcCopied =>
      'Bank details copied — paste into your banking app';

  @override
  String get qrScannerGuidance => 'Point the camera at a QR code';

  @override
  String get qrScannerPermissionDenied =>
      'Camera access is needed to scan QR codes.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Camera access was denied. Open settings to grant it.';

  @override
  String get qrScannerRetryPermission => 'Try again';

  @override
  String get qrScannerOpenSettings => 'Open settings';

  @override
  String get qrScannerTimeout =>
      'No QR code detected. Move closer or try again.';

  @override
  String get qrScannerRetry => 'Try again';

  @override
  String get torchOn => 'Turn flash on';

  @override
  String get torchOff => 'Turn flash off';

  @override
  String get obdPermissionDenied =>
      'Grant Bluetooth permission in system settings';

  @override
  String get obdPickerTitle => 'Pick an OBD2 adapter';

  @override
  String get obdPickerScanning => 'Scanning for adapters…';

  @override
  String get obdPickerConnecting => 'Connecting…';

  @override
  String get tripSummaryTitle => 'Trip summary';

  @override
  String get tripMetricDistance => 'Distance';

  @override
  String get tripMetricFuelUsed => 'Fuel used';

  @override
  String get tripMetricAvgConsumption => 'Avg';

  @override
  String get tripMetricElapsed => 'Elapsed';

  @override
  String get tripMetricOdometer => 'Odometer';

  @override
  String get tripStop => 'Stop recording';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Resume';

  @override
  String get tripBannerRecording => 'Recording trip';

  @override
  String get tripBannerPaused => 'Trip paused — tap to resume';

  @override
  String get vehicleBaselineSectionTitle => 'Baseline calibration';

  @override
  String get vehicleBaselineEmpty =>
      'No samples yet — start an OBD2 trip to begin learning this vehicle\'s fuel profile.';

  @override
  String get vehicleBaselineProgress =>
      'Learned from samples across driving situations.';

  @override
  String get vehicleBaselineReset => 'Reset driving-situation baseline';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Reset driving-situation baseline?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'This wipes every learned sample for this vehicle. You\'ll drift back to the cold-start defaults until new trips refill the profile.';

  @override
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapter';

  @override
  String get vehicleAdapterEmpty =>
      'No adapter paired. Pair one so the app can reconnect automatically next time.';

  @override
  String get vehicleAdapterUnnamed => 'Unknown adapter';

  @override
  String get vehicleAdapterPair => 'Pair adapter';

  @override
  String get vehicleAdapterForget => 'Forget adapter';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFirstTrip => 'First trip';

  @override
  String get achievementFirstTripDesc => 'Record your first OBD2 trip.';

  @override
  String get achievementFirstFillUp => 'First fill-up';

  @override
  String get achievementFirstFillUpDesc => 'Log your first fill-up.';

  @override
  String get achievementTenTrips => '10 trips';

  @override
  String get achievementTenTripsDesc => 'Record 10 OBD2 trips.';

  @override
  String get achievementZeroHarsh => 'Smooth driver';

  @override
  String get achievementZeroHarshDesc =>
      'Complete a trip of 10 km or more with no harsh braking or acceleration.';

  @override
  String get achievementEcoWeek => 'Eco week';

  @override
  String get achievementEcoWeekDesc =>
      'Drive 7 consecutive days with at least one smooth trip each day.';

  @override
  String get achievementPriceWin => 'Price win';

  @override
  String get achievementPriceWinDesc =>
      'Log a fill-up that beats the station\'s 30-day average by 5 % or more.';

  @override
  String get syncBaselinesToggleTitle => 'Share learned vehicle profiles';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Upload per-vehicle consumption baselines so a second device can reuse them.';

  @override
  String get obd2StatusConnected => 'OBD2 adapter: connected';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: Bluetooth permission needed';

  @override
  String get obd2StatusConnectedBody => 'Ready to record a trip.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Grant Bluetooth permission in system settings to reconnect automatically.';

  @override
  String get obd2StatusNoAdapter => 'No adapter paired';

  @override
  String get obd2StatusForget => 'Forget adapter';

  @override
  String get tripHistoryTitle => 'Trip history';

  @override
  String get tripHistoryEmptyTitle => 'No trips yet';

  @override
  String get tripHistoryUnknownDate => 'Unknown date';

  @override
  String get situationIdle => 'Idle';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urban';

  @override
  String get situationHighway => 'Highway';

  @override
  String get situationDecel => 'Decelerating';

  @override
  String get situationClimbing => 'Climbing / loaded';

  @override
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

  @override
  String get situationHardAccel => 'Hard accel';

  @override
  String get situationFuelCut => 'Fuel cut — coast';

  @override
  String get tripSaveRecording => 'Save trip';

  @override
  String get tripSummaryAutoSaved => 'Trip saved automatically';

  @override
  String get tripSummaryDone => 'Done';

  @override
  String get tripSummaryDelete => 'Delete this trip';

  @override
  String get vehicleFuelNotSet => 'Not set';

  @override
  String get wizardVehicleDefaultBadge => 'Default';

  @override
  String get wizardProfileChoiceHint =>
      'Choose how you want to use the app. You can change this later in Settings.';

  @override
  String get wizardProfileChoiceFooter =>
      'You can change your choice any time from Settings → Use mode.';

  @override
  String get wizardProfileBasicName => 'Basic';

  @override
  String get wizardProfileBasicDescription =>
      'Cheapest fuel and EV charging prices nearby. Favorites and price alerts.';

  @override
  String get wizardProfileMediumName => 'Medium';

  @override
  String get wizardProfileMediumDescription =>
      'Everything in Basic, plus track your fuel fill-ups and EV charging by hand.';

  @override
  String get wizardProfileFullName => 'Full';

  @override
  String get wizardProfileFullDescription =>
      'Everything in Medium, plus automatic OBD2 trip recording, driving scores, and loyalty cards.';

  @override
  String get wizardProfileCustomName => 'Custom';

  @override
  String get useModeSectionHint =>
      'Right-size the app to how you actually use it. Picking a preset enables the matching set of features.';

  @override
  String get useModeCustomSettingsDescription =>
      'Your feature mix doesn\'t match any preset. Pick one above to overwrite, or keep customising individual features in the section below.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Use mode set to $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Default vehicle (optional)';

  @override
  String get profileDefaultVehicleNone => 'No default';

  @override
  String get profileFuelFromVehicleHint =>
      'Fuel type is derived from your default vehicle. Clear the vehicle to pick a fuel directly.';

  @override
  String get consumptionNoVehicleTitle => 'Add a vehicle first';

  @override
  String get consumptionNoVehicleBody =>
      'Fill-ups are attributed to a vehicle. Add your car to start logging consumption.';

  @override
  String get vehicleAdd => 'Add vehicle';

  @override
  String get vehicleAddTitle => 'Add vehicle';

  @override
  String get vehicleEditTitle => 'Edit vehicle';

  @override
  String get vehicleDeleteTitle => 'Delete vehicle?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Remove \"$name\" from your profiles?';
  }

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameHint => 'e.g. My Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustion';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Electric';

  @override
  String get vehicleEvSectionTitle => 'Electric';

  @override
  String get vehicleCombustionSectionTitle => 'Combustion';

  @override
  String get vehicleBatteryLabel => 'Battery capacity (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max charging power (kW)';

  @override
  String get vehicleConnectorsLabel => 'Supported connectors';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max SoC %';

  @override
  String get vehicleTankLabel => 'Tank capacity (L)';

  @override
  String get vehiclePowerLabel => 'Engine power (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps PS';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Preferred fuel';

  @override
  String get connectorType2 => 'Type 2';

  @override
  String get connectorCcs => 'CCS';

  @override
  String get connectorChademo => 'CHAdeMO';

  @override
  String get connectorTesla => 'Tesla';

  @override
  String get connectorSchuko => 'Schuko';

  @override
  String get connectorType1 => 'Type 1';

  @override
  String get connectorThreePin => '3-pin';

  @override
  String get evShowOnMap => 'Show EV stations';

  @override
  String get evAvailableOnly => 'Available only';

  @override
  String get evMinPower => 'Min power';

  @override
  String get evStatusAvailable => 'Available';

  @override
  String get evStatusOccupied => 'Occupied';

  @override
  String get evStatusOutOfOrder => 'Out of order';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Open only';

  @override
  String get saveAsDefaults => 'Save as my defaults';

  @override
  String get criteriaSavedToProfile => 'Saved as defaults';

  @override
  String get updatingFavorites => 'Updating your favorites...';

  @override
  String get fetchingLatestPrices => 'Fetching the latest prices';

  @override
  String get noDataAvailable => 'No data';

  @override
  String get searchToSeeMap => 'Search to see stations on the map';

  @override
  String get evPowerAny => 'Any';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profile';

  @override
  String get sectionLocation => 'Location';

  @override
  String get sectionPrivacyData => 'Privacy & data';

  @override
  String get sectionAdvancedDeveloper => 'Advanced & developer';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipClose => 'Close';

  @override
  String get tooltipShare => 'Share';

  @override
  String get tooltipClearSearch => 'Clear search input';

  @override
  String get minimalDriveInstantConsumption => 'Instant consumption';

  @override
  String get minimalDriveBehaviour => 'Driving behaviour';

  @override
  String get coachingShiftUp => 'Shift up';

  @override
  String get coachingShiftDown => 'Shift down';

  @override
  String get coachingEasePedal => 'Ease off';

  @override
  String get coachingVoiceHardAcceleration => 'Easy on the accelerator';

  @override
  String get coachingVoiceHarshBraking => 'Try to brake more gently';

  @override
  String get coachingVoiceShiftUp => 'Shift up a gear to save fuel';

  @override
  String get coachingVoiceShiftDown => 'Shift down, the engine is labouring';

  @override
  String get coachingVoiceEasePedal =>
      'Ease off the pedal to cut your fuel use';

  @override
  String get coachingVoiceLiftOff => 'Lift off the accelerator and coast';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Look further ahead and lift off earlier';

  @override
  String get coachingVoiceSmoothAccel => 'Accelerate more smoothly';

  @override
  String get coachingVoiceSharpCorner => 'Take corners a little gentler';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'That was a very hard stop — leave more distance';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Very hard acceleration — that burns real fuel';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Very sharp corner — slow in, gentle out';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount harsh events.',
      one: 'One harsh event.',
      zero: 'Nice and smooth — no harsh events.',
    );
    return 'Trip saved: $distanceKm kilometres, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litres per 100 kilometres';
  }

  @override
  String get voiceCoachingSettingTitle => 'Spoken driving coaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hear spoken tips while you drive — hard acceleration, harsh braking and gear hints';

  @override
  String get tooltipUseGps => 'Use GPS location';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get evConnectorsLabel => 'Available connectors';

  @override
  String get evConnectorsNone => 'No connector information';

  @override
  String get switchToEmail => 'Switch to email';

  @override
  String get switchToEmailSubtitle =>
      'Keep data, add sign-in from other devices';

  @override
  String get switchToAnonymousAction => 'Switch to anonymous';

  @override
  String get switchToAnonymousSubtitle =>
      'Keep local data, use new anonymous session';

  @override
  String get linkDevice => 'Link device';

  @override
  String get shareDatabase => 'Share database';

  @override
  String get disconnectAction => 'Disconnect';

  @override
  String get disconnectSubtitle => 'Stop syncing (local data kept)';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Remove all server data permanently';

  @override
  String get localOnly => 'Local only';

  @override
  String get localOnlySubtitle =>
      'Optional: sync favorites, alerts, and ratings across devices';

  @override
  String get tankSyncSchemaOutdatedTitle => 'Cloud database needs an update';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Your self-hosted TankSync schema is outdated — some data cannot sync. Open the sync wizard and run the update SQL on your Supabase project.';

  @override
  String get setupCloudSync => 'Set up cloud sync';

  @override
  String get disconnectTitle => 'Disconnect TankSync?';

  @override
  String get disconnectBody =>
      'Cloud sync will be disabled. Your local data (favorites, alerts, history) is preserved on this device. Server data is not deleted.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes all your data from the server (favorites, alerts, ratings, routes). Local data on this device is preserved.\n\nThis cannot be undone.';

  @override
  String get switchToAnonymousTitle => 'Switch to anonymous?';

  @override
  String get switchToAnonymousBody =>
      'You will be signed out of your email account and continue with a new anonymous session.\n\nYour local data (favorites, alerts) is kept on this device and will be synced to the new anonymous account.';

  @override
  String get switchAction => 'Switch';

  @override
  String get helpBannerCriteria =>
      'Your profile defaults are pre-filled. Adjust criteria below to refine your search.';

  @override
  String get helpBannerAlerts =>
      'Set a price threshold for a station. You\'ll be notified when prices drop below it. Prices are checked periodically in the background — best effort, not in real time.';

  @override
  String get helpBannerConsumption =>
      'Log every fill-up to track your real-world consumption and CO₂ footprint. Swipe left to delete an entry.';

  @override
  String get helpBannerVehicles =>
      'Add your vehicles so fill-ups and fuel preferences default correctly. The first vehicle becomes your default.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get onboardingPreferencesTitle => 'Your preferences';

  @override
  String get onboardingZipHelper => 'Used when GPS is unavailable';

  @override
  String get onboardingRadiusHelper => 'Larger radius = more results';

  @override
  String get onboardingPrivacy =>
      'These settings are stored only on your device and never shared.';

  @override
  String get onboardingLandingTitle => 'Home screen';

  @override
  String get onboardingLandingHint =>
      'Choose which screen opens when you launch the app.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Stay out of the app — but don\'t quit it.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Open Sparkilo once after each reboot.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple wakes Sparkilo only after you\'ve opened it at least once since the phone restarted. After that, your trips record automatically.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Don\'t swipe Sparkilo away in the app switcher.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Force-quit\" tells iOS to stop relaunching the app. Your trips will stop recording until you open Sparkilo again.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'When iOS asks for \"Always\" location, please say yes.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'The fallback that records your trip when the OBD2 adapter is slow needs background location. We never share it.';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get brandFilterHighway => 'Highway';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Private';

  @override
  String get ratingModeShared => 'Shared';

  @override
  String get ratingDescLocal => 'Ratings saved on this device only';

  @override
  String get ratingDescPrivate =>
      'Synced with your database (not visible to others)';

  @override
  String get ratingDescShared => 'Visible to all users of your database';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API key not configured. Add one in Settings to search EV charging stations.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'The data provider ($host) is serving an expired or invalid TLS certificate. The app cannot load data from this source until the provider fixes it. Please contact $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed unavailable. Using $current.';
  }

  @override
  String get errorTitleApiKey => 'API key required';

  @override
  String get errorTitleLocation => 'Location unavailable';

  @override
  String get errorHintNoStations =>
      'Try increasing the search radius or search a different location.';

  @override
  String get errorHintApiKey => 'Configure your API key in Settings.';

  @override
  String get errorHintConnection =>
      'Check your internet connection and try again.';

  @override
  String get errorHintRouting =>
      'Route calculation failed. Check your internet connection and try again.';

  @override
  String get errorHintFallback =>
      'Try again or search by postal code / city name.';

  @override
  String get alertsLoadErrorTitle => 'Couldn\'t load your alerts';

  @override
  String get detailsLabel => 'Details';

  @override
  String get remove => 'Remove';

  @override
  String get showKey => 'Show key';

  @override
  String get hideKey => 'Hide key';

  @override
  String get syncOptionalTitle => 'TankSync is optional';

  @override
  String get syncOptionalDescription =>
      'Your app works fully without cloud sync. TankSync lets you sync favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips across devices using Supabase (free tier available).';

  @override
  String get syncHowToConnectQuestion => 'How would you like to connect?';

  @override
  String get syncCreateOwnTitle => 'Create my own database';

  @override
  String get syncCreateOwnSubtitle =>
      'Free Supabase project — we\'ll guide you step by step';

  @override
  String get syncJoinExistingTitle => 'Join an existing database';

  @override
  String get syncJoinExistingSubtitle =>
      'Scan QR code from the database owner or paste credentials';

  @override
  String get syncChooseAccountType => 'Choose your account type';

  @override
  String get syncAccountTypeAnonymous => 'Anonymous';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Instant, no email needed. Data tied to this device.';

  @override
  String get syncAccountTypeEmail => 'Email Account';

  @override
  String get syncAccountTypeEmailDesc =>
      'Sign in from any device. Recover data if phone is lost.';

  @override
  String get syncHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get syncCreateNewAccount => 'Create new account';

  @override
  String get syncTestConnection => 'Test Connection';

  @override
  String get syncTestingConnection => 'Testing...';

  @override
  String get syncConnectButton => 'Connect';

  @override
  String get syncConnectingButton => 'Connecting...';

  @override
  String get syncDatabaseReady => 'Database ready!';

  @override
  String get syncDatabaseNeedsSetup => 'Database needs setup';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Missing';

  @override
  String get syncSqlEditorInstructions =>
      'Copy the SQL below and run it in your Supabase SQL Editor (Dashboard → SQL Editor → New Query → Paste → Run)';

  @override
  String get syncCopySqlButton => 'Copy SQL to clipboard';

  @override
  String get syncRecheckSchemaButton => 'Re-check schema';

  @override
  String get syncSchemaOutdated =>
      'Your TankSync schema is outdated — re-run the setup SQL below to enable the latest synced features.';

  @override
  String get syncDoneButton => 'Done';

  @override
  String syncSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get syncEmailDescription =>
      'Your data syncs across all devices with this email.';

  @override
  String get syncSwitchToAnonymousTitle => 'Switch to anonymous';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continue without email, new anonymous session';

  @override
  String get syncGuestDescription => 'Anonymous, no email needed.';

  @override
  String get syncOrDivider => 'or';

  @override
  String get syncHowToSyncQuestion => 'How would you like to sync?';

  @override
  String get syncOfflineDescription =>
      'Your app works fully offline. Cloud sync is optional.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Shared database run by the developer — see what syncs below';

  @override
  String get syncModePrivateTitle => 'Private Database';

  @override
  String get syncModePrivateSubtitle => 'Your own Supabase — full data control';

  @override
  String get syncModeGroupTitle => 'Join a Group';

  @override
  String get syncModeGroupSubtitle => 'Family or friends shared database';

  @override
  String get syncPrivacyShared => 'Shared';

  @override
  String get syncPrivacyPrivate => 'Private';

  @override
  String get syncPrivacyGroup => 'Group';

  @override
  String get syncStayOfflineButton => 'Stay offline';

  @override
  String get syncSuccessTitle => 'Successfully connected!';

  @override
  String get syncSuccessDescription => 'Your data will now sync automatically.';

  @override
  String get syncWizardTitleConnect => 'Connect TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Your database';

  @override
  String get syncSetupTitleJoinGroup => 'Join a group';

  @override
  String get syncSetupTitleAccount => 'Your account';

  @override
  String get syncWizardBack => 'Back';

  @override
  String get syncWizardNext => 'Next';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Create a Supabase project';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tap \"Open Supabase\" below\n2. Create a free account (if you don\'t have one)\n3. Click \"New Project\"\n4. Choose a name and region\n5. Wait ~2 minutes for it to start';

  @override
  String get syncWizardOpenSupabase => 'Open Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Enable Anonymous Sign-ins';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. In your Supabase dashboard:\n   Authentication → Providers\n2. Find \"Anonymous Sign-ins\"\n3. Toggle it ON\n4. Click \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Open Auth Settings';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copy your credentials';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Go to Settings → API in your dashboard\n2. Copy the \"Project URL\"\n3. Copy the \"anon public\" key\n4. Paste them below';

  @override
  String get syncWizardOpenApiSettings => 'Open API Settings';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Join an existing database';

  @override
  String get syncWizardScanQrCode => 'Scan QR Code';

  @override
  String get syncWizardAskOwnerQr =>
      'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Ask the database owner to show their QR code';

  @override
  String get syncWizardEnterManuallyTitle => 'Enter manually';

  @override
  String get syncWizardOrEnterManually => 'or enter manually';

  @override
  String get syncWizardUrlHelperText =>
      'Whitespace and line breaks removed automatically';

  @override
  String get syncCredentialsPrivateHint =>
      'Enter your Supabase project credentials. You can find them in your dashboard under Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Database URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Access Key';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPleaseEnterEmail => 'Please enter your email';

  @override
  String get authInvalidEmail => 'Invalid email address';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authConnectAnonymously => 'Connect anonymously';

  @override
  String get authCreateAccountAndConnect => 'Create account & connect';

  @override
  String get authSignInAndConnect => 'Sign in & connect';

  @override
  String get authAnonymousSegment => 'Anonymous';

  @override
  String get authEmailSegment => 'Email';

  @override
  String get authAnonymousDescription =>
      'Instant access, no email needed. Data tied to this device.';

  @override
  String get authEmailDescription =>
      'Sign in from any device. Recover your data if your phone is lost.';

  @override
  String get authSyncAcrossDevices =>
      'Sync data automatically across all your devices.';

  @override
  String get authNewHereCreateAccount => 'New here? Create account';

  @override
  String get linkDeviceScreenTitle => 'Link Device';

  @override
  String get linkDeviceThisDeviceLabel => 'This device';

  @override
  String get linkDeviceShareCodeHint =>
      'Share this code with your other device:';

  @override
  String get linkDeviceNotConnected => 'Not connected';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copy code';

  @override
  String get linkDeviceImportSectionTitle => 'Import from another device';

  @override
  String get linkDeviceImportDescription =>
      'Enter the device code from your other device to import its favorites, alerts, vehicles, and consumption log. Each device keeps its own profile and defaults.';

  @override
  String get linkDeviceCodeFieldLabel => 'Device code';

  @override
  String get linkDeviceCodeFieldHint => 'Paste the UUID from other device';

  @override
  String get linkDeviceImportButton => 'Import data';

  @override
  String get linkDeviceHowItWorksTitle => 'How it works';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. On Device A: copy the device code above\n2. On Device B: paste it in the \"Device code\" field\n3. Tap \"Import data\" to merge favorites, alerts, vehicles, and consumption logs\n4. Both devices will have all combined data\n\nEach device keeps its own anonymous identity and its own profile (preferred fuel, default vehicle, landing screen). Data is merged, not moved.';

  @override
  String get vehicleSetActive => 'Set active';

  @override
  String get swipeHide => 'Hide';

  @override
  String get yourRating => 'Your rating';

  @override
  String get noStorageUsed => 'No storage used';

  @override
  String get aboutReportBug => 'Report a bug / Suggest a feature';

  @override
  String get aboutSupportProject => 'Support this project';

  @override
  String get aboutSupportDescription =>
      'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.';

  @override
  String get reportIssueTitle => 'Report a problem';

  @override
  String get enterCorrection => 'Please enter the correction';

  @override
  String get reportNoBackendAvailable =>
      'The report could not be sent: no reporting service is configured for this country. Enable TankSync in Settings to send community reports.';

  @override
  String get correctName => 'Correct station name';

  @override
  String get correctAddress => 'Correct address';

  @override
  String get wrongE85Price => 'Wrong E85 price';

  @override
  String get wrongE98Price => 'Wrong Super 98 price';

  @override
  String get wrongLpgPrice => 'Wrong LPG price';

  @override
  String get wrongStationName => 'Wrong station name';

  @override
  String get wrongStationAddress => 'Wrong address';

  @override
  String get independentStation => 'Independent station';

  @override
  String get serviceRemindersSection => 'Service reminders';

  @override
  String get serviceRemindersEmpty => 'No reminders yet — pick a preset above.';

  @override
  String get addServiceReminder => 'Add reminder';

  @override
  String get serviceReminderPresetOil => 'Oil (15,000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Oil change';

  @override
  String get serviceReminderPresetTires => 'Tires (20,000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Tires';

  @override
  String get serviceReminderPresetInspection => 'Inspection (30,000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Inspection';

  @override
  String get serviceReminderLabel => 'Label';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Last service';

  @override
  String get serviceReminderMarkDone => 'Mark as done';

  @override
  String get serviceReminderDueTitle => 'Service due';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label is due — $kmOver km past the interval.';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '$label is due now.';
  }

  @override
  String get vinConfirmTitle => 'Is this your car?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-cyl, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Partial info (offline). You can edit below.';

  @override
  String get vinDecodeError => 'Couldn\'t decode this VIN';

  @override
  String get vinInvalidFormat => 'Invalid VIN format';

  @override
  String get obd2PauseBannerTitle => 'OBD2 connection lost — recording paused';

  @override
  String get obd2PauseBannerResume => 'Resume recording';

  @override
  String get obd2PauseBannerEnd => 'End recording';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Recording with GPS — OBD2 reconnecting';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Recording with GPS — waiting for the OBD2 adapter';

  @override
  String get alertsStationSectionTitle => 'Station alerts';

  @override
  String get alertsStationAdd => 'Add a station alert';

  @override
  String get alertsRadiusSectionTitle => 'Radius alerts';

  @override
  String get alertsRadiusAdd => 'Add radius alert';

  @override
  String get alertsRadiusEmptyTitle => 'No radius alerts yet';

  @override
  String get alertsRadiusEmptyCta => 'Create a radius alert';

  @override
  String get alertsRadiusCreateTitle => 'Create radius alert';

  @override
  String get alertsRadiusLabelHint => 'Label (e.g. Home diesel)';

  @override
  String get alertsRadiusFuelType => 'Fuel type';

  @override
  String get alertsRadiusKm => 'Radius (km)';

  @override
  String get alertsRadiusCenterGps => 'Use my location';

  @override
  String get alertsRadiusCenterPostalCode => 'Postal code';

  @override
  String get alertsRadiusSave => 'Save';

  @override
  String get alertsRadiusCancel => 'Cancel';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 connected: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Pair an OBD2 adapter';

  @override
  String get fillUpSavedSnackbar => 'Fill-up saved';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String notFoundBody(String location) {
    return '\"$location\" not found.';
  }

  @override
  String get notFoundHomeButton => 'Home';

  @override
  String get consumptionTabHiddenNotice =>
      'The Consumption tab was hidden by your profile settings.';

  @override
  String get swipeBetweenTabsHint =>
      'Tip: swipe left or right to switch between tabs.';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody =>
      'You have unsaved changes. Leaving now will discard them.';

  @override
  String get discardChangesConfirm => 'Discard';

  @override
  String get discardChangesKeepEditing => 'Keep editing';

  @override
  String get tankSyncSectionSubtitle => 'Cloud sync across your devices';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get routeNameHintExample => 'e.g. Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Current';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API Key';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API Key';

  @override
  String get tapToUpdateGpsPosition => 'Tap to update GPS position';

  @override
  String get nameLabel => 'Name';

  @override
  String get obd2ErrorPermissionDenied =>
      'Bluetooth permission is required to connect to an OBD2 adapter.';

  @override
  String get obd2ErrorBluetoothOff => 'Turn on Bluetooth and try again.';

  @override
  String get obd2ErrorScanTimeout =>
      'No OBD2 adapter found nearby. Make sure it is plugged in and powered on.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'The OBD2 adapter did not respond. Check the connection and try again.';

  @override
  String get obd2ErrorEngineOff =>
      'No data from the vehicle — start the engine and try again.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'The OBD2 adapter sent an unrecognized response. It may be incompatible — try a different adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'The OBD2 adapter disconnected. Reconnect and try again.';

  @override
  String get obd2ErrorPairingRequired =>
      'The adapter needs Bluetooth pairing. Unplug the adapter, plug it back in, then retry within 5 minutes.';

  @override
  String get onboardingExploreDemoData => 'Explore with demo data';

  @override
  String get achievementSmoothDriver => 'Smooth streak';

  @override
  String get achievementSmoothDriverDesc =>
      'Drive 5 trips in a row with a smooth-driving score of 80 or higher.';

  @override
  String get achievementColdStartAware => 'Cold-start aware';

  @override
  String get achievementColdStartAwareDesc =>
      'Keep a whole month\'s cold-start fuel cost under 2 % of total fuel — combine short trips.';

  @override
  String get achievementHighwayMaster => 'Highway master';

  @override
  String get achievementHighwayMasterDesc =>
      'Complete a 30 km+ trip at consistent speed with a smooth-driving score of 90 or higher.';

  @override
  String priceAlertNotificationTitle(String station, String fuelType) {
    return '$station - $fuelType';
  }

  @override
  String priceAlertNotificationBody(
    String price,
    String currency,
    String target,
  ) {
    return '$price $currency (target: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel dropped at nearby stations';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count stations dropped by up to $cents¢ in the last hour';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count stations ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count more';
  }

  @override
  String alertsLastChecked(String when) {
    return 'Last checked: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Prices haven\'t been checked in the background yet';

  @override
  String get alertsIosBestEffortNote =>
      'On iPhone, alert checks are best effort: iOS decides when the app may check prices in the background, so an alert can arrive late or occasionally not at all. Opening the app always runs a fresh check.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Target price ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Threshold ($currency/L)';
  }

  @override
  String get approachOverlaySection => 'Fuel Station Radar';

  @override
  String get approachRadiusLabel => 'Radius';

  @override
  String approachRadiusCaption(String km) {
    return 'Radar leads with the price when within $km km of a fuel station';
  }

  @override
  String get approachPriceModeLabel => 'Show price for';

  @override
  String get approachPriceModeNearest => 'Nearest station';

  @override
  String get approachPriceModeCheapestInRadius => 'Cheapest in radius';

  @override
  String get approachMinPollLabel => 'Min refresh';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Floor on how often the overlay refreshes the nearest station (faster at speed, never tighter than $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Test Fuel Station Radar';

  @override
  String get approachTestStopButton => 'Stop test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test active — radar shows the price for $station';
  }

  @override
  String get approachTestUnavailable =>
      'Add a favorite station to test the Fuel Station Radar';

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximity $percent%';
  }

  @override
  String get pipTapToRestore => 'Tap to open the full app';

  @override
  String get authErrorNoNetwork => 'No network connection. Try again later.';

  @override
  String get authErrorInvalidCredentials =>
      'Invalid email or password. Check your credentials.';

  @override
  String get authErrorUserAlreadyExists =>
      'This email is already registered. Try signing in instead.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please check your email and confirm your account first.';

  @override
  String get authErrorGeneric => 'Sign-in failed. Please try again.';

  @override
  String get authLinkEmailTitle => 'Link an email';

  @override
  String get authLinkEmailSubtitle =>
      'Link an email so your data syncs across devices. Your current favorites and trips stay on this account.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'You\'re using a guest account ($idPrefix…). Link an email so your favorites and trips sync to your other devices.';
  }

  @override
  String get authConfirmationPending =>
      'Almost there — check your email and click the link to finish linking it. Your data is already saved on this account.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Background location — for auto-record only';

  @override
  String get autoRecordConsentExplanationTitle => 'About this permission';

  @override
  String get autoRecordConsentExplanationBody =>
      'Auto-record needs background location to detect when you start driving while the app is closed. This grant is used only by auto-record — station search and map centering use a separate foreground location grant.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Got it';

  @override
  String get autoRecordConsentExplanationTooltip => 'What does this mean?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Tap to manage in system settings';

  @override
  String get autoRecordSectionTitle => 'Auto-record';

  @override
  String get autoRecordToggleLabel => 'Auto-record trips';

  @override
  String get autoRecordStatusActiveLabel =>
      'Auto-record will activate the next time you enter the car.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Pair an OBD2 adapter to enable auto-record.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Allow background location so auto-record keeps running with the screen off.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Pair an adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Start speed (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Save delay after disconnect (seconds)';

  @override
  String get autoRecordBackgroundLocationLabel => 'Background location allowed';

  @override
  String get autoRecordBackgroundLocationRequest => 'Request permission';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Why \"Allow all the time\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Auto-record streams GPS coordinates from the OBD-II foreground service while the screen is off so your trip route stays accurate. Android requires the \"Allow all the time\" option for that to keep working after the device locks.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Open settings';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Location permission required';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Could not request background location';

  @override
  String get aclWakeNotificationTitle => 'Car connected';

  @override
  String get aclWakeNotificationBody =>
      'Tap to open Sparkilo — trip recording can start.';

  @override
  String get exportBackupReady => 'Backup ready — pick a destination';

  @override
  String get exportBackupFailed => 'Backup export failed — please try again';

  @override
  String get backupExportProgress => 'Exporting your backup…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Saved to Downloads as $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Restore backup';

  @override
  String get restoreBackupDialogBody =>
      'Merge adds and updates records from the backup and keeps everything already on this device. Replace deletes all current data first, then restores only the backup — this cannot be undone.';

  @override
  String get restoreBackupMergeAction => 'Merge';

  @override
  String get restoreBackupReplaceAction => 'Replace all';

  @override
  String get restoreBackupEmpty => 'Backup restored — it contained no records';

  @override
  String get restoreBackupCorrupt =>
      'Restore failed — this file is not a valid Tankstellen backup';

  @override
  String get restoreBackupFailed =>
      'Restore failed — the file could not be read';

  @override
  String get backupImportProgress => 'Restoring your backup…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Merged $vehicles vehicles, $fillUps fill-ups, $trips trips, $chargingLogs charging logs';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Replaced all data with $vehicles vehicles, $fillUps fill-ups, $trips trips, $chargingLogs charging logs';
  }

  @override
  String get brokenMapChipDisclaimer => 'MAP readings suspicious';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP sensor reads incorrectly — fuel readings may be 50–80% too low. Try a different adapter.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP sensor unreliable. Showing fill-up averages instead of live fuel rate.';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP sensor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP sensor: $posterior% ± $margin% (verified)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP sensor diagnostics';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Broken-MAP confidence: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observations recorded';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verified clean';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'This vehicle\'s MAP sensor hasn\'t been observed yet.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blocklisted adapters';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'No adapters are blocklisted.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — flagged $percent% broken';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Clear';

  @override
  String get brokenMapRevPromptTitle => 'Rev the engine';

  @override
  String get brokenMapRevPromptBody =>
      'Briefly blip the throttle so the app can check the MAP sensor responds.';

  @override
  String get brokenMapRevPromptConfirm => 'Done — I revved';

  @override
  String get calibrationAdvancedTitle => 'Advanced calibration';

  @override
  String get calibrationDisplacementLabel => 'Engine displacement (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetric efficiency (η_v)';

  @override
  String get calibrationAfrLabel => 'Air-to-fuel ratio (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Fuel density (g/L)';

  @override
  String get calibrationSourceDetected => '(detected from VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(default)';

  @override
  String get calibrationSourceManual => '(manual)';

  @override
  String get calibrationResetToDetected => 'Reset to detected value';

  @override
  String get calibrationBasisAtkinson => 'Atkinson cycle';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbocharged + DI';

  @override
  String get calibrationBasisTurbo => 'Turbocharged';

  @override
  String get calibrationBasisNaDi => 'Naturally aspirated + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catalog: $makeModel — $basis default)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Your $makeModel is marked as diesel but matches a petrol catalog entry. Tap to update.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Update';

  @override
  String get catalogResetAction => 'Reset from vehicle database';

  @override
  String get catalogResetConfirmTitle => 'Reset from the vehicle database?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'This replaces the tank capacity, engine power and displacement of this vehicle with the database values for $vehicle. Other fields and your fill-up history are not touched.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'No matching entry in the vehicle database for this vehicle.';

  @override
  String get catalogResetDoneSnackbar =>
      'Vehicle data reset from the database.';

  @override
  String get consumptionTabFuel => 'Fuel';

  @override
  String get consumptionTabCharging => 'Charging';

  @override
  String get noChargingLogsTitle => 'No charging logs yet';

  @override
  String get noChargingLogsSubtitle =>
      'Log your first charging session to start tracking EUR/100 km and kWh/100 km.';

  @override
  String get addChargingLog => 'Log charging';

  @override
  String get addChargingLogTitle => 'Log charging session';

  @override
  String get chargingKwh => 'Energy (kWh)';

  @override
  String get chargingCost => 'Total cost';

  @override
  String get chargingTimeMin => 'Charge time (min)';

  @override
  String get chargingStationName => 'Station (optional)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Need a previous log to compare';

  @override
  String get chargingLogButtonLabel => 'Log charging';

  @override
  String get chargingCostTrendTitle => 'Charging cost trend';

  @override
  String get chargingEfficiencyTitle => 'Efficiency (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Not enough data yet';

  @override
  String get confirmDeleteTitle => 'Delete?';

  @override
  String get confirmDeleteBody => 'Do you really want to delete this?';

  @override
  String get consoFeatureGroupTitle => 'Consumption';

  @override
  String get consoFeatureGroupDescription =>
      'Track your consumption — manual fill-ups, or automatic OBD2 trip recording.';

  @override
  String get consoModeOff => 'Off';

  @override
  String get consoModeFuel => 'Fuel';

  @override
  String get consoModeFuelAndTrips => 'Fuel + Trips';

  @override
  String get consoModeOffDescription =>
      'No Conso tab and no Conso settings section.';

  @override
  String get consoModeFuelDescription =>
      'Manual fill-ups only. Useful without an OBD2 adapter.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Adds automatic OBD2 trip recording. Requires a paired adapter.';

  @override
  String get consoGroupVehicles => 'Vehicles';

  @override
  String get consoGroupCoaching => 'Coaching while driving';

  @override
  String get consoGroupRewards => 'Rewards & savings';

  @override
  String get consoGroupTroubleshooting => 'Troubleshooting';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Accuracy: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'High';

  @override
  String get consumptionAccuracyMedium => 'Medium';

  @override
  String get consumptionAccuracyLow => 'Low';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Full calibration: fill-ups plus OBD2-recorded trips. The L/100 km figure tracks reality to within a few percent.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Fill-ups have anchored the consumption model, but no OBD2 trip has fed the loop yet. Record one with OBD2 connected to reach High accuracy.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'GPS-only — no fill-ups have anchored the consumption model yet. Add a couple of full fill-ups to improve the accuracy.';

  @override
  String get moreActionsTooltip => 'More';

  @override
  String get exportBackupMenuLabel => 'Export backup';

  @override
  String get restoreBackupMenuLabel => 'Restore backup';

  @override
  String get carbonDashboardMenuLabel => 'Carbon dashboard';

  @override
  String get settingsMenuLabel => 'Settings';

  @override
  String get consumptionStatsPageTitle => 'Consumption statistics';

  @override
  String get consumptionStatsComparisonTitle => 'This month vs last month';

  @override
  String get consumptionStatsTrendsTitle => 'Evolution over time';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Log fill-ups across at least two months to compare.';

  @override
  String get consumptionStatsPricePerLiter => 'Avg price/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litres per month';

  @override
  String get consumptionStatsChartSpend => 'Spend per month';

  @override
  String get consumptionStatsChartPricePerLiter => 'Price per litre';

  @override
  String get consumptionStatsChartConsumption => 'L/100km per month';

  @override
  String get fuelCompareSectionTitle => 'Cost of driving, fuel by fuel';

  @override
  String get fuelComparePricePerLitre => 'Paid per litre';

  @override
  String get fuelCompareCostPer100km => 'Cost per 100 km';

  @override
  String get fuelCompareDistance => 'Distance measured';

  @override
  String get fuelCompareLitres => 'Litres burned';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner is your cheapest fuel to drive on';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser costs $amount more per 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel beats $rival below $price per litre';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Break-even is calculated from each fuel\'s measured consumption, so it moves as your driving does.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litres and cost can disagree: a fuel can burn fewer litres per 100 km and still cost more per kilometre, because the pump price differs. Cost per kilometre is the verdict.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full tanks',
      one: 'one full tank',
    );
    return 'Provisional — based on $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full tanks',
      one: 'one full tank',
    );
    return 'Based on $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 per 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner is your lowest-emission fuel';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel costs $money more per 1000 km but emits $co2 less CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel is both cheaper and cleaner than $rival';
  }

  @override
  String fuelCompareCo2Avoided(
    String distance,
    String fuel,
    String actual,
    String alternative,
    String rival,
    String saved,
  ) {
    return 'Your $distance on $fuel emitted $actual instead of $alternative on $rival — $saved avoided';
  }

  @override
  String get fuelCompareCo2Source =>
      'CO2 figures are well-to-wheel estimates (EU JEC WTW v5) applied to your measured consumption — awareness, not audit-grade accounting.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 is shown for pure fuels only: a blend\'s emission factor depends on the mix, which this row does not record.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partial fills pending plein complet — not in average',
      one: '1 partial fill pending plein complet — not in average',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% of fuel from auto-corrections — review entries';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Report content';

  @override
  String get contentModerationBlockAction => 'Block author';

  @override
  String get contentModerationReportDialogTitle => 'Report this content?';

  @override
  String get contentModerationReportDialogBody =>
      'A report is sent to your TankSync server for review, and this content is hidden on your device.';

  @override
  String get contentModerationReportConfirmButton => 'Report';

  @override
  String get contentModerationBlockDialogTitle => 'Block this author?';

  @override
  String get contentModerationBlockDialogBody =>
      'Everything this account shares with you will be hidden on this device.';

  @override
  String get contentModerationBlockConfirmButton => 'Block';

  @override
  String get contentModerationReportedSnack =>
      'Report submitted — content hidden.';

  @override
  String get contentModerationReportFailedSnack =>
      'Couldn\'t submit the report. Try again.';

  @override
  String get contentModerationBlockedSnack =>
      'Author blocked — their shared content is hidden.';

  @override
  String get fillUpCorrectionLabel => 'Auto-correction — tap to edit';

  @override
  String get fillUpCorrectionEditTitle => 'Edit auto-correction';

  @override
  String get fillUpCorrectionEditExplainer =>
      'This entry was auto-generated to close the gap between recorded trips and pumped fuel. Adjust the values if you know the actual figures.';

  @override
  String get fillUpCorrectionDelete => 'Delete correction';

  @override
  String get fillUpCorrectionStation => 'Station name (optional)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country stations $km km away — €$price/L cheaper';
  }

  @override
  String get crossBorderTapToSwitch => 'Tap to switch country';

  @override
  String get crossBorderDismissTooltip => 'Dismiss';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Developer tools';

  @override
  String get dataAccessTracerExport => 'Export data-access trace';

  @override
  String get dataAccessTracerExportSuccess =>
      'Data-access trace saved to Downloads.';

  @override
  String get dataAccessTracerExportFailure =>
      'Couldn\'t export the data-access trace.';

  @override
  String get dataAccessTracerEmpty =>
      'No data-access events recorded yet — search or open stations first, then export.';

  @override
  String get developerToolsSubtitle =>
      'Diagnostics and tools for debugging — only visible in Developer / Debug mode.';

  @override
  String get developerToolsMenuSubtitle =>
      'Error log, test alerts, diagnostics';

  @override
  String get developerToolsErrorLogGroupTitle => 'Error log';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Save error log ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Clear error log';

  @override
  String get developerToolsViewErrorLog => 'View error log';

  @override
  String get developerToolsErrorLogEmpty => 'No error traces recorded.';

  @override
  String get developerToolsAlertsGroupTitle => 'Alerts & notifications';

  @override
  String get developerToolsFireTestNotification => 'Fire test notification';

  @override
  String get developerToolsTestNotificationTitle => 'Test notification';

  @override
  String get developerToolsTestNotificationBody =>
      'If you can read this, notifications are working.';

  @override
  String get developerToolsTestNotificationSent => 'Test notification sent.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Notifications are blocked — enable them in system settings, then retry.';

  @override
  String get developerToolsRunTestAlert => 'Run test alert pipeline';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Test alert fired — pipeline delivered $count notification(s).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Test price alert';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Synthetic match: $station is below your target.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostics';

  @override
  String get developerToolsFeatureFlagDump => 'Feature flag inspector';

  @override
  String get developerToolsFlagOn => 'On';

  @override
  String get developerToolsFlagOff => 'Off';

  @override
  String get developerToolsClearCaches => 'Clear caches';

  @override
  String get developerToolsCachesCleared => 'Caches cleared.';

  @override
  String get developerToolsCopyDiagnostics => 'Copy diagnostics';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostics copied to clipboard.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Build info';

  @override
  String get developerToolsBuildVersion => 'App version';

  @override
  String get developerToolsBuildChannel => 'Build channel';

  @override
  String get startupTraceSectionTitle => 'Startup initialization trace';

  @override
  String get startupTraceExportButton => 'Export startup trace';

  @override
  String get startupTraceEmpty => 'No startup trace recorded yet.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Total: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess => 'Startup trace saved to Downloads.';

  @override
  String get startupTraceExportFailure => 'Couldn\'t export the startup trace.';

  @override
  String get distanceSourceOdometer => 'Odometer';

  @override
  String get distanceSourceOdometerTooltip =>
      'Distance read from the car\'s odometer — a measured ground truth.';

  @override
  String get distanceSourceGps => 'GPS track';

  @override
  String get distanceSourceGpsTooltip =>
      'Distance summed from the recorded GPS track — true road distance.';

  @override
  String get distanceSourceEstimated => 'Estimated';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Distance integrated from the speed sensor — an estimate; the sensor typically over-reads slightly.';

  @override
  String get insightCardTitle => 'Top wasteful behaviours';

  @override
  String get insightEmptyState => 'No notable inefficiencies — keep it up!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Engine over 3000 RPM ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count hard accelerations: wasted $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Idling ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% of trip';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Labouring in low gear ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Turn the engine off at long stops instead of letting it idle.';

  @override
  String get lessonAdviceHighRpm =>
      'Shift up earlier to keep the engine out of the high-RPM band.';

  @override
  String get lessonAdviceHardAccel =>
      'Ease onto the throttle — smooth acceleration uses less fuel.';

  @override
  String get lessonAdviceLowGear =>
      'Shift up sooner so the engine settles into a lower, more efficient gear.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Sustained high speed ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Sustained high speed ($pctTime% of trip)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Ease off above 110 km/h — drag rises sharply, so a small speed cut saves a lot of fuel.';

  @override
  String get lessonSmoothDrivingTitle => 'Smooth driving — nicely done!';

  @override
  String get lessonAdviceSmoothDriving =>
      'No harsh acceleration or braking this trip — steady inputs like these keep consumption low.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Full throttle ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Ease onto the pedal — a gentler 70 % of the throttle gets you up to speed on far less fuel.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Rich mixture under load ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Heavy, sustained load makes the engine run rich — short-shift and back off on long climbs to keep the mixture lean.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Climbing at $gradePercent% grade ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Carry momentum into a hill and feed the throttle smoothly — surging on a climb burns extra fuel.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stop-and-go restarts: wasted $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticipate traffic and coast toward stops so you roll rather than restart — pulling away from a dead stop is the thirstiest part of stop-and-go.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Mixture looks a little lean — the engine added fuel ($pctTrim% trim) to compensate';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Mixture looks lean — the engine sustained a large $pctTrim% fuel addition, a possible inefficiency';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Mixture looks a little rich — the engine pulled fuel ($pctTrim% trim) to compensate';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Mixture looks rich — the engine sustained a large $pctTrim% fuel cut, a possible inefficiency';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Engine ran rich under load ($pctShare% of the warm drive) — possible wasted fuel';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristic health signal, not a diagnosis';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'A sustained lean-correcting trim can mean an intake-air leak, a weak fuel supply, or an ageing sensor. If consumption or running quality worsens, a workshop scan can confirm.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'A sustained rich-correcting trim can mean a leaking injector, high fuel pressure, or an over-reading sensor. If consumption or running quality worsens, a workshop scan can confirm.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Running rich under heavy load burns extra fuel. Short-shift and ease off on long pulls so the engine can stay near a stoichiometric mixture.';

  @override
  String get lessonTransportTitle =>
      'Engine data missing for most of this trip';

  @override
  String get lessonTransportAdvice =>
      'The engine reported no activity for almost the whole distance. Either the OBD2 stream failed mid-trip or the car was moved without driving — the consumption figure is unreliable and excluded from your statistics.';

  @override
  String get drivingScoreCardTitle => 'Driving score';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Composite score from idling, hard accelerations, hard braking, and high-RPM time. A \'better than X% of past trips\' comparison will land in a follow-up release.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Driving score $score out of 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Idling';

  @override
  String get drivingScorePenaltyHardAccel => 'Hard accelerations';

  @override
  String get drivingScorePenaltyHardBrake => 'Hard braking';

  @override
  String get drivingScorePenaltyHighRpm => 'High RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Full throttle';

  @override
  String get drivingScoreClassVeryGood => 'Very good';

  @override
  String get drivingScoreClassGood => 'Good';

  @override
  String get drivingScoreClassAverage => 'Average';

  @override
  String get drivingScoreClassBad => 'Needs work';

  @override
  String get drivingScorePenaltyLugging => 'Lugging';

  @override
  String get drivingScorePenaltySmoothness => 'Jerky driving';

  @override
  String get drivingScorePenaltyHighSpeed => 'High speed';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Aggressive pedal';

  @override
  String get drivingScorePenaltyLambda => 'Rich mixture';

  @override
  String get gpsKpiCardTitle => 'GPS efficiency';

  @override
  String get gpsKpiRpa => 'Positive acceleration (RPA)';

  @override
  String get gpsKpiPke => 'Kinetic energy demand (PKE)';

  @override
  String get gpsKpiVapos => 'Acceleration intensity (VAPOS)';

  @override
  String get gpsKpiCoast => 'Coasting share';

  @override
  String get gpsKpiClimbEnergy => 'Climb energy';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs your efficient baseline';
  }

  @override
  String get drivingTraceCardTitle => 'Driving-analysis trace (dev)';

  @override
  String get drivingTraceCardBody =>
      'Export this trip\'s GPS KPIs, score and lessons as JSON, write how the drive actually felt in the comment field, and share it back so the driving-style thresholds can be calibrated against real trips.';

  @override
  String get drivingTraceExportAction => 'Export analysis trace';

  @override
  String get drivingTraceExported =>
      'Analysis trace saved to Downloads — add your verdict in the comment field and share it back.';

  @override
  String get drivingTraceExportFailed => 'Couldn\'t export the analysis trace.';

  @override
  String get minimalDriveTripAverage => 'Trip average';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'High-RPM cruising ($pctTime% of trip): shifting up earlier could save $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Shift up earlier when cruising — the same speed at lower RPM burns noticeably less fuel.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Fuel-cut coasting ($pctTime% of trip): saved about $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Nicely anticipated — lifting off early lets the engine cut fuel completely while coasting.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Where your fuel went';

  @override
  String get fuelBreakdownIdle => 'Idling';

  @override
  String get fuelBreakdownHarshAccel => 'Hard accelerations';

  @override
  String get fuelBreakdownHighRpmCruise => 'High-RPM cruising';

  @override
  String get fuelBreakdownCoastingSaved => 'Saved by coasting';

  @override
  String get fuelBreakdownEfficient => 'Normal driving';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Idling for a while — switching the engine off saves fuel';

  @override
  String get ecoNudgeHarshAccel =>
      'Strong acceleration — a gentler pedal saves fuel';

  @override
  String get ecoNudgeHighRpm =>
      'High revs at cruise — shifting up earlier saves fuel';

  @override
  String get obd2CoverageNoneNote =>
      'No engine data arrived from the OBD2 adapter on this trip — fuel figures are GPS-based estimates.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Engine data stopped $percent% into the trip (connection dropped) — fuel figures after that point are GPS-based estimates.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Engine data covered only $percent% of this trip — gaps use GPS-based estimates.';
  }

  @override
  String get favoritesShareAction => 'Share';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favourites on $date';
  }

  @override
  String get favoritesShareError => 'Couldn\'t generate share image';

  @override
  String get featureManagementSectionTitle => 'Feature management';

  @override
  String get featureManagementSectionSubtitle =>
      'Turn individual features on or off. Some features depend on others — switches are disabled until prerequisites are met.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2 trip recording';

  @override
  String get featureDescription_obd2TripRecording =>
      'Capture trips automatically over OBD2.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification =>
      'Driving scores and earned badges.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptic eco-coach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Real-time haptic feedback during a trip.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync => 'Cross-device sync via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Consumption analytics';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Fill-up and trip analysis tab.';

  @override
  String get featureLabel_baselineSync => 'Baseline sync';

  @override
  String get featureDescription_baselineSync =>
      'Sync driving baselines via TankSync.';

  @override
  String get featureLabel_priceAlerts => 'Price alerts';

  @override
  String get featureDescription_priceAlerts =>
      'Threshold-based price-drop notifications.';

  @override
  String get featureLabel_priceHistory => 'Price history';

  @override
  String get featureDescription_priceHistory =>
      '30-day price charts on station details.';

  @override
  String get featureLabel_routePlanning => 'Route planning';

  @override
  String get featureDescription_routePlanning =>
      'Cheapest stop along your route.';

  @override
  String get featureLabel_evCharging => 'EV charging';

  @override
  String get featureDescription_evCharging =>
      'Charging stations via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling guidance using OSM traffic signals.';

  @override
  String get featureLabel_gpsTripPath => 'GPS trip path';

  @override
  String get featureDescription_gpsTripPath =>
      'Persist GPS path samples alongside each trip.';

  @override
  String get featureLabel_autoRecord => 'Auto-record';

  @override
  String get featureDescription_autoRecord =>
      'Automatically start a trip when the OBD2 adapter connects to a moving vehicle.';

  @override
  String get featureLabel_showFuel => 'Show fuel stations';

  @override
  String get featureDescription_showFuel =>
      'Display petrol/diesel station results in search and on the map.';

  @override
  String get featureLabel_showElectric => 'Show charging stations';

  @override
  String get featureDescription_showElectric =>
      'Display EV charging stations in search and on the map.';

  @override
  String get featureLabel_showConsumptionTab => 'Consumption tab';

  @override
  String get featureDescription_showConsumptionTab =>
      'Show the consumption analytics tab in the bottom navigation.';

  @override
  String get featureBlockedEnable_gamification =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_baselineSync => 'Enable TankSync first';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Enable OBD2 trip recording first';

  @override
  String get featureLabel_tflitePricePrediction => 'Best time to fill up';

  @override
  String get featureDescription_tflitePricePrediction =>
      'On-device guidance on when to fill up, computed from your local price history — nothing leaves the device.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Enable price history first';

  @override
  String get featureLabel_fuelCalculator => 'Fuel calculator';

  @override
  String get featureDescription_fuelCalculator =>
      'Reachable fuel-cost calculator from the search results.';

  @override
  String get featureLabel_carbonDashboard => 'Carbon dashboard';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2 footprint dashboard reachable from the Consumption tab.';

  @override
  String get featureLabel_experimentalOemPids => 'Experimental OEM PIDs';

  @override
  String get featureDescription_experimentalOemPids =>
      'Read exact tank litres via manufacturer-specific PIDs on supported adapters.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Enable OBD2 trip recording first';

  @override
  String get featureLabel_paymentQrScan => 'Scan payment QR';

  @override
  String get featureDescription_paymentQrScan =>
      'Scan-to-pay QR reader on the station detail screen.';

  @override
  String get featureLabel_communityPriceReports => 'Community price reports';

  @override
  String get featureDescription_communityPriceReports =>
      'Report a station price from the station detail screen.';

  @override
  String get featureLabel_obd2Optional => 'Require OBD2 for trip recording';

  @override
  String get featureDescription_obd2Optional =>
      'When off, the app records GPS-only trajets without needing an OBD2 adapter. Coaching is reduced — no instant L/100 km, fewer engine-derived signals.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Receipt OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Scan a printed receipt on the Add fill-up screen to pre-fill date, litres, total, and station.';

  @override
  String get featureLabel_developerPatToken =>
      'Developer feedback (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Enable the bad-scan feedback panel that auto-files GitHub issues with a Personal Access Token. Power-user / contributor feature.';

  @override
  String get featureLabel_debugMode => 'Developer / Debug mode';

  @override
  String get featureDescription_debugMode =>
      'Surface a Developer tools section in Settings with diagnostics: error-log export, test notifications, a test-alert pipeline run, a feature-flag dump, clear caches, and copy diagnostics.';

  @override
  String get featureLabel_approachOverlay => 'Fuel Station Radar';

  @override
  String get featureDescription_approachOverlay =>
      'Turn the floating trip tile into a live Fuel Station Radar — as you near a fuel station it flips to the fuel type\'s colour and shows the price.';

  @override
  String get featureLabel_voiceAnnouncements => 'Voice announcements';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Speak nearby cheap fuel stations aloud as you drive, so you can keep your eyes on the road.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Enable the Fuel Station Radar first';

  @override
  String get featureGroupTitle_finding => 'Finding & map';

  @override
  String get featureGroupDescription_finding =>
      'Where to fuel up or charge — search, map, routing.';

  @override
  String get featureGroupTitle_prices => 'Prices & alerts';

  @override
  String get featureGroupDescription_prices =>
      'Price drops, history, and reporting.';

  @override
  String get featureGroupTitle_radar => 'Fuel Station Radar';

  @override
  String get featureGroupDescription_radar => 'Live price nudges as you drive.';

  @override
  String get featureGroupTitle_sync => 'Sync & backup';

  @override
  String get featureGroupDescription_sync => 'Keep your data across devices.';

  @override
  String get featureGroupTitle_input => 'Input & scanning';

  @override
  String get featureGroupDescription_input => 'Helpers for logging fill-ups.';

  @override
  String get featureGroupTitle_developer => 'Developer & experimental';

  @override
  String get featureGroupDescription_developer =>
      'Power-user and contributor tools.';

  @override
  String get featureLabel_voiceFeedback => 'Spoken feedback (text-to-speech)';

  @override
  String get featureDescription_voiceFeedback =>
      'Master switch for every spoken surface — the driving voice coach and station announcements. When off, the app never opens a text-to-speech engine.';

  @override
  String get feedbackConsentTitle => 'Send report to GitHub?';

  @override
  String get feedbackConsentBody =>
      'This creates a public ticket on our GitHub repository with your photo and the OCR text. No personal data (location, account id) is sent. Continue?';

  @override
  String get feedbackConsentContinue => 'Continue';

  @override
  String get feedbackConsentCancel => 'Cancel';

  @override
  String get feedbackConsentLater => 'Later';

  @override
  String get feedbackTokenSectionTitle => 'Bad-scan feedback (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'To automatically open a GitHub ticket from a failed scan, paste a GitHub PAT (`public_repo` scope on the tankstellen repository). Otherwise manual sharing remains available.';

  @override
  String get feedbackTokenStatusSet => 'Token configured';

  @override
  String get feedbackTokenStatusUnset => 'No token';

  @override
  String get feedbackTokenSet => 'Set';

  @override
  String get feedbackTokenClear => 'Clear';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

  @override
  String get fillUpMultiFuelHint =>
      'This vehicle can use different fuels — log the one you actually pumped';

  @override
  String get fillUpGuidanceTitle => 'Best time to fill up';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'The current price is among the cheapest of the last $days days — a good time to fill up.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Prices are near their $days-day high. They are usually cheaper $window — consider waiting.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Prices are trending up — consider filling up soon.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Today\'s price is around the $days-day average.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Could save about $amount/L by timing your fill-up.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count price readings',
      one: 'Based on 1 price reading',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'on $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'in the $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'at other times';

  @override
  String get fillUpGuidanceWeekday1 => 'Mondays';

  @override
  String get fillUpGuidanceWeekday2 => 'Tuesdays';

  @override
  String get fillUpGuidanceWeekday3 => 'Wednesdays';

  @override
  String get fillUpGuidanceWeekday4 => 'Thursdays';

  @override
  String get fillUpGuidanceWeekday5 => 'Fridays';

  @override
  String get fillUpGuidanceWeekday6 => 'Saturdays';

  @override
  String get fillUpGuidanceWeekday7 => 'Sundays';

  @override
  String get fillUpGuidancePartEarlyMorning => 'early mornings';

  @override
  String get fillUpGuidancePartMorning => 'mornings';

  @override
  String get fillUpGuidancePartAfternoon => 'afternoons';

  @override
  String get fillUpGuidancePartEvening => 'evenings';

  @override
  String get fillUpGuidancePartNight => 'nights';

  @override
  String get fillUpOdometerFromCarJustNow => 'From your car · just now';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'From your car · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Estimated from your car\'s last reading plus the distance driven since ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Paste text';

  @override
  String get pasteReceiptDialogTitle => 'Paste receipt text';

  @override
  String get pasteReceiptDialogHint =>
      'Paste the text of a fuel receipt — e-mail, SMS, or a shared PDF. The litres, price per litre, fuel grade, total and station are read on-device and used to pre-fill the form. Nothing is sent to a server.';

  @override
  String get pasteReceiptFieldHint => 'Receipt text';

  @override
  String get pasteReceiptParseAction => 'Pre-fill';

  @override
  String get pasteReceiptNoData =>
      'Couldn\'t read any fuel data from that text — check it\'s a fuel receipt and try again.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verified by adapter';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Doesn\'t match adapter reading';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Your entry: $userL L. Adapter says: $adapterL L (delta from before/after fuel-level capture). Use adapter value?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Keep my entry';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Use adapter value';

  @override
  String get scanReceiptNoData => 'No receipt data found — try again';

  @override
  String get scanReceiptSuccess =>
      'Receipt scanned — verify values. Tap \"Report scan error\" below if anything is off.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get badScanReportTitleReceipt => 'Report a scan error — Receipt';

  @override
  String get badScanReportHint =>
      'We\'ll share the receipt photo and both sets of values so the next build can learn this layout.';

  @override
  String get badScanReportFieldBrandLayout => 'Brand layout';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Price/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Fuel';

  @override
  String get badScanReportFieldDate => 'Date';

  @override
  String get badScanReportHeaderField => 'Field';

  @override
  String get badScanReportHeaderScanned => 'Scanned';

  @override
  String get badScanReportHeaderYouTyped => 'You typed';

  @override
  String get badScanReportCreateTicket => 'Create issue';

  @override
  String get badScanReportOpenInBrowser => 'Open in browser';

  @override
  String get badScanReportFallbackToShare => 'Submission failed — manual share';

  @override
  String get fillUpWarningDialogTitle => 'Check this fill-up';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'You picked $chosenFuel, but this vehicle runs on $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Odometer $entered km is below the previous fill-up\'s $previous km — distance can\'t go backwards.';
  }

  @override
  String get fillUpWarningGoBack => 'Go back and fix';

  @override
  String get fillUpWarningSaveAnyway => 'Save anyway';

  @override
  String get fillUpSectionWhatTitle => 'What you filled';

  @override
  String get fillUpSectionWhatSubtitle => 'Fuel, amount, price';

  @override
  String get fillUpSectionWhereTitle => 'Where you were';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, odometer, notes';

  @override
  String get fillUpImportReceiptLabel => 'Receipt';

  @override
  String get fillUpPricePerLiterLabel => 'Price per liter';

  @override
  String get vehicleHeaderUntitled => 'New vehicle';

  @override
  String get vehicleSectionIdentityTitle => 'Identity';

  @override
  String get vehicleSectionIdentitySubtitle => 'Name & VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Drivetrain';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'How this vehicle moves';

  @override
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get fuelEfficiencyCardTitle => 'Cost per kilometre by fuel';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Which fuel mix is actually cheapest to drive on';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Cheapest per km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Pure';

  @override
  String get fuelEfficiencyMixBadge => 'Blend';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Mostly $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Cost/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Total spent';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills',
      one: '1 fill',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full tanks',
      one: '1 full tank',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Log at least two full tanks per composition to crown the cheapest.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Tanks are grouped by composition: a tank is pure when one fuel is at least 85% of it, otherwise a blend.';

  @override
  String get fuelNameE5 => 'Super E5';

  @override
  String get fuelNameE10 => 'Super E10';

  @override
  String get fuelNameE98 => 'Super 98';

  @override
  String get fuelNameDiesel => 'Diesel';

  @override
  String get fuelNameDieselPremium => 'Diesel Premium';

  @override
  String get fuelNameE85 => 'E85 Bioethanol';

  @override
  String get fuelNameLpg => 'LPG';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Hydrogen';

  @override
  String get fuelNameElectric => 'Electric';

  @override
  String get calibrationModeLabel => 'Calibration mode';

  @override
  String get calibrationModeRule => 'Rule-based';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Rule-based assigns each driving sample to exactly one situation. Fuzzy spreads it across all of them by how well each fits — smoother around 60 km/h or changing gradients, but slower to fill all buckets.';

  @override
  String get profileGamificationToggleTitle => 'Show achievements & scores';

  @override
  String get profileGamificationToggleSubtitle =>
      'When off, badges, scores and trophy icons are hidden across the app.';

  @override
  String gdprPolicyLink(int version) {
    return 'Privacy policy (version $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Consent given on $date · policy version $version';
  }

  @override
  String get consentNotRecorded => 'No consent recorded yet';

  @override
  String serverErasurePartial(String tables) {
    return 'Some server data could not be erased: $tables. Retry, or contact the developer with this list.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Some local data could not be erased: $steps. Restart the app and retry.';
  }

  @override
  String get myCommunityReportsTitle => 'My community reports';

  @override
  String get myCommunityReportsEmpty => 'You have not submitted any reports';

  @override
  String get deleteReportTooltip => 'Delete this report';

  @override
  String get reportDeleted => 'Report deleted';

  @override
  String get reportDeleteFailed => 'Could not delete the report';

  @override
  String get tileProxyToggleTitle =>
      'Route map tiles through the Sparkilo proxy';

  @override
  String get tileProxyToggleSubtitle =>
      'On: the map viewport and your IP address reach the developer\'s EU server, which fetches the tiles from OpenStreetMap. Off: tiles load from tile.openstreetmap.org directly.';

  @override
  String get remoteLogosToggleTitle => 'Load brand logos from the internet';

  @override
  String get remoteLogosToggleSubtitle =>
      'Off by default: bundled placeholders are shown. On: logos are fetched from logo.clearbit.com, which sees your IP address.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return 'Saved $fileName to Downloads — $count files inside';
  }

  @override
  String get privacyExportAllFailed => 'Could not write the export file';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Operated by $operator · Supabase, EU (Frankfurt) · syncs favorites, alerts, vehicles incl. VIN, fill-ups, ratings, reports and — if you enable it — trips with GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'You are the controller — your own Supabase project, we never see it';

  @override
  String get syncModeJoinControllerNotice =>
      'The person who owns the shared database is the controller of your data';

  @override
  String get ugcPublicNoticeTitle => 'Shared with other users';

  @override
  String get ugcPublicNoticeBody =>
      'This is stored in the sync database under your pseudonymous user ID. In Sparkilo Community every signed-in user can read it. You can delete it any time from TankSync → Data Transparency.';

  @override
  String get blockedAuthorsTitle => 'Blocked users';

  @override
  String get blockedAuthorsDescription =>
      'Content shared by these users is hidden on this device. Unblock to see it again.';

  @override
  String get blockedAuthorsEmpty => 'No blocked users';

  @override
  String get blockedAuthorsUnblock => 'Unblock';

  @override
  String get coachingGpsLiftOff => 'Lift off';

  @override
  String get coachingGpsAnticipateBrake => 'Anticipate';

  @override
  String get coachingGpsSmoothAccel => 'Smooth accel';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Track covers $pct% — longest gap $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Track covers $pct% — no gaps detected';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'app in background';

  @override
  String get gpsCoverageAttrOsBatching => 'OS fix batching';

  @override
  String get gpsCoverageAttrGateRejected => 'fixes filtered';

  @override
  String get gpsCoverageAttrDeliveryStall => 'delayed delivery';

  @override
  String get gpsCoverageAttrSignalLoss => 'signal loss';

  @override
  String get gpsCoverageAttrUnknown => 'unknown cause';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'The app was in the background without a foreground service, so the system throttled GPS. Keep the screen on while recording, or enable background recording when available.';

  @override
  String get gpsCoverageHintOsBatching =>
      'The system delivered position fixes late in batches; the track filled in afterwards, so little data was actually lost.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Noisy position fixes in this stretch were filtered out to keep the distance figure honest.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Position fixes were produced on time but reached the app late — the phone was busy (often a Bluetooth reconnect). Reception was fine.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'GPS reception dropped — this usually means a tunnel, parking garage or dense urban canyon.';

  @override
  String get gpsCoverageHintUnknown =>
      'This trip carries no app-lifecycle information for the gap, so the cause can\'t be determined.';

  @override
  String get gpsCoverageAttrLinkRecovery => 'OBD2 reconnection interference';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'The gap coincides with an OBD2 reconnection episode — the adapter link was recovering while GPS ingest stalled. Fixing the adapter connection also fixes the track.';

  @override
  String get gpsDiagnosticsTitle => 'GPS sampling diagnostics';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps gaps',
      one: '1 gap',
      zero: 'no gaps',
    );
    return '$count samples · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Median interval: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Captured during recording to verify GPS cadence under phone-sleep.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Largest gap: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Resumed';

  @override
  String get gpsLifecyclePaused => 'Paused';

  @override
  String get gpsLifecycleInactive => 'Inactive';

  @override
  String get gpsKpiVerdictGood => 'Efficient';

  @override
  String get gpsKpiVerdictModerate => 'Moderate';

  @override
  String get gpsKpiVerdictAggressive => 'Aggressive';

  @override
  String get gpsKpiInterpretationGood =>
      'Smooth, energy-light driving — this is what efficient looks like.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Fairly typical driving — a little smoother on the throttle would save more.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energy-heavy driving — easing off the accelerator and coasting more would cut fuel use.';

  @override
  String get gpsMatrixMaturityCold => 'Cold';

  @override
  String get gpsMatrixMaturityWarming => 'Warming';

  @override
  String get gpsMatrixMaturityConverged => 'Converged';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS matrix is still warming up ($count fill-up refinements so far). Estimates are provisional.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS matrix is converging ($count fill-ups). Estimates are usable but may drift a few %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS matrix has converged ($count fill-ups). Estimates are within ~2 % of real-world burn.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get gpsRoadUseCardTitle => 'How you used the road';

  @override
  String get gpsRoadUseSpeedSection => 'Where you spent your time';

  @override
  String get gpsRoadUseSpeedIdle => 'Stopped (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Town (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Cruise (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Fast (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'How you moved';

  @override
  String get gpsRoadUsePhaseAccel => 'Accelerating';

  @override
  String get gpsRoadUsePhaseSteady => 'Holding speed';

  @override
  String get gpsRoadUsePhaseCoast => 'Coasting';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct%';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Lots of coasting — letting the car roll instead of braking saves fuel. Nice.';

  @override
  String get gpsRoadUseSource => 'From your GPS track';

  @override
  String get hapticEcoCoachSettingTitle => 'Real-time eco coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Gentle haptic + on-screen tip when you floor it during cruise';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Easy on the throttle — coasting saves more';

  @override
  String highwayViaExit(String ref, String km) {
    return 'via exit $ref · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigate to $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Remove $name from favorites';
  }

  @override
  String get showOnMapSemanticLabel => 'Show stations on map';

  @override
  String get searchResultsSemanticLabel => 'Search results';

  @override
  String get searchCriteriaSemanticLabel =>
      'Search criteria summary. Tap to edit.';

  @override
  String get noFavoritesSemanticLabel =>
      'No favorites yet. Tap the star on a station to save it as a favorite.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Station is open',
      'false': 'Station is closed',
      'other': 'Station is closed',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Country $name, selected',
      'false': 'Country $name',
      'other': 'Country $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Language $name, selected',
      'false': 'Language $name',
      'other': 'Language $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sort by $option, selected',
      'false': 'Sort by $option',
      'other': 'Sort by $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Fuel type $type, selected',
      'false': 'Fuel type $type',
      'other': 'Fuel type $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'EV charging station $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Privacy shield with fuel drop';

  @override
  String get globeIllustrationSemantic => 'Globe with fuel station markers';

  @override
  String get fuelPumpIllustrationSemantic => 'Fuel pump with price ticker';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, data source: $provider, $keyRequirement, fuel types: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'API key required';

  @override
  String get countryInfoNoKeyNeeded => 'Free, no key needed';

  @override
  String countryInfoDataSource(String provider) {
    return 'Data: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Fuel types: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon Key';

  @override
  String get anonKeyHideTooltip => 'Hide key';

  @override
  String get anonKeyShowTooltip => 'Show key to verify';

  @override
  String anonKeyTooLong(int length) {
    return 'Key is too long ($length chars) — check for extra text';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Key looks correct ($length chars)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Key should be a JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Key may be truncated ($length of ~208 expected chars)';
  }

  @override
  String get anonKeyExceedsMax => 'Key exceeds maximum length';

  @override
  String get qrShareTitle => 'Share your database';

  @override
  String get qrShareSubtitle => 'Others can scan this QR code to connect';

  @override
  String get qrShareCopyAsText => 'Copy as text';

  @override
  String get authInfoTitle => 'Why create an account?';

  @override
  String get authInfoBenefit1 =>
      '• Sync favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips across devices';

  @override
  String get authInfoBenefit2 =>
      '• Prepare a route on your phone, use it in your car';

  @override
  String get authInfoBenefit3 => '• No data is shared with third parties';

  @override
  String get authInfoBenefit4 => '• You can delete your account at any time';

  @override
  String get apiKeySetupTitle => 'API key setup (optional)';

  @override
  String get apiKeySetupDescription =>
      'Register for a free API key, or skip to explore the app with demo data.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider Registration';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'By entering an API key you accept the terms of $provider. Data redistribution is prohibited.';
  }

  @override
  String get calculatorDistanceHint => 'e.g. 150';

  @override
  String get calculatorConsumptionHint => 'e.g. 7.0';

  @override
  String get calculatorPriceHint => 'e.g. 1.899';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (experimental)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtle haptic when slowing down ahead of a red light. Off by default — distraction risk.';

  @override
  String get consentSyncTripsTitle => 'Sync trip recordings';

  @override
  String get consentSyncTripsSubtitle =>
      'Back up OBD2 + GPS trips to TankSync. Cross-device, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Enable Cloud Sync above to back up trips.';

  @override
  String get consentSyncTripsAnonymousHint =>
      'Trips back up under this device\'s anonymous account. Sign in with an email to reach them from other devices.';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Invalid link';

  @override
  String invalidLinkBody(String path) {
    return 'The link \"$path\" is not valid.';
  }

  @override
  String get home => 'Home';

  @override
  String get accelBrakeCardTitle => 'Acceleration & braking';

  @override
  String get accelBrakeHardAccel => 'Hard accelerations';

  @override
  String get accelBrakeHardBrake => 'Hard braking';

  @override
  String get accelBrakeSharpCorner => 'Sharp corners';

  @override
  String get accelBrakeSource => 'From the phone\'s motion sensors';

  @override
  String lessonHardBrake(String count) {
    return '$count hard braking events';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Anticipate stops and ease off the accelerator earlier — hard braking throws away the fuel you just spent getting up to speed.';

  @override
  String lessonSharpCornering(String count) {
    return '$count sharp corners';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Slow before the bend, not in it — hard cornering scrubs off speed you then have to rebuild.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Last $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Consumption unit';

  @override
  String get consumptionUnitSettingSubtitle =>
      'How fuel consumption is shown everywhere in the app';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automatic ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Live consumption window';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Average the live figure over the last few seconds — longer is steadier, shorter reacts faster';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'est. $unit';
  }

  @override
  String get locationConsentTitle => 'Location Access';

  @override
  String get locationConsentSubtitle =>
      'This app would like to use your location to find fuel stations near you.';

  @override
  String get locationConsentWhatHappens =>
      'What happens with your location data:';

  @override
  String get locationConsentBulletApi =>
      'Your coordinates are sent to the fuel price API to find nearby stations.';

  @override
  String get locationConsentBulletNoServer =>
      'Your location is not stored on any server — there is no server.';

  @override
  String get locationConsentBulletNoTracking =>
      'Location data is not used for advertising, analytics, or tracking.';

  @override
  String get locationConsentRevoke =>
      'You can revoke location access anytime in system settings. Alternatively, search by postal code.';

  @override
  String get locationConsentLegalBasis =>
      'Legal basis: Art. 6(1)(a) GDPR (Consent)';

  @override
  String get loyaltySettingsTitle => 'Fuel club cards';

  @override
  String get loyaltySettingsSubtitle =>
      'Apply your loyalty discount to displayed prices';

  @override
  String get loyaltyMenuTitle => 'Fuel club cards';

  @override
  String get loyaltyMenuSubtitle =>
      'Apply per-litre discounts from Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Add card';

  @override
  String get loyaltyAddCardSheetTitle => 'Add fuel club card';

  @override
  String get loyaltyBrandLabel => 'Brand';

  @override
  String get loyaltyCardLabelLabel => 'Label (optional)';

  @override
  String get loyaltyDiscountLabel => 'Discount (per litre)';

  @override
  String get loyaltyDiscountInvalid => 'Enter a positive number';

  @override
  String get loyaltyDeleteConfirmTitle => 'Delete card?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'This card will stop applying its discount.';

  @override
  String get loyaltyEmptyTitle => 'No fuel club cards yet';

  @override
  String get loyaltyEmptyBody =>
      'Add a card to apply your per-litre discount to matching stations automatically.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle => 'Idle RPM creep detected';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Idle RPM has crept up by $percent% over your last $tripCount trips. Possible early sign of a clogged air filter or sensor drift.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Possible intake restriction';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Cruise fuel rate has dropped by $percent% over your last $tripCount trips. Possible sign of a clogged air filter or restricted intake — worth a check-up.';
  }

  @override
  String get maintenanceActionDismiss => 'Dismiss';

  @override
  String get maintenanceActionSnooze => 'Snooze 30 days';

  @override
  String get consumptionMonthlyInsightsTitle => 'This month vs last month';

  @override
  String get consumptionMonthlyTripsLabel => 'Trips';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Drive time';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distance';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Avg consumption';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Need at least 3 trips per month for comparison';

  @override
  String get consumptionMonthlyClimbLabel => 'Climbed';

  @override
  String get obd2CapabilitySectionTitle => 'Adapter capabilities';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'OEM PIDs';

  @override
  String get obd2CapabilityFullCan => 'Full CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'For exact litres-in-tank on Peugeot/Citroën, the app supports OBDLink MX+/LX/CX (STN chip).';

  @override
  String get obd2DebugOverlayEnabledSnack => 'OBD2 diagnostic overlay enabled';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 diagnostic overlay disabled';

  @override
  String get obd2DebugOverlayClearButton => 'Clear';

  @override
  String get obd2DebugOverlayCloseButton => 'Close';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 breadcrumbs';

  @override
  String get obd2DiagnosticShareLabel => 'Share diagnostic log';

  @override
  String get obd2DebugLoggingTitle => 'OBD2 debug logging';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Record each OBD2 session — connection, handshake, data gaps and reconnects — to an exportable XML log. Off by default.';

  @override
  String get obd2DebugSessionShareLabel => 'Share OBD2 session log';

  @override
  String get obd2DiagnosticsTitle => 'OBD2 communication health';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops drops',
      one: '1 drop',
      zero: 'no drops',
    );
    return '$percent% complete · $duty% duty · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Connection lifecycle';

  @override
  String get obd2DiagnosticsPidSection => 'Per-PID outcomes';

  @override
  String get obd2DiagnosticsReconnectSection => 'Reconnect telemetry';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts reconnect attempts · $successes ok · $transitions transitions · $disconnects typed drops';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'GPS-only fallback activated this session.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Scheduler health';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Completeness';

  @override
  String get obd2DiagnosticsSupportSection => 'Discovered-supported PIDs';

  @override
  String get obd2DiagnosticsFuelSection => 'Fuel-tier rollup';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protocol $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts attempts · $successes ok · $drops drops · time-to-connect p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Reconnects: $silent silent · $visible visible';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips back-pressure skips · $demotions demotions';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dynamics tier starved — RPM / speed fell below the governor floor.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Overall $percent% · active duty $duty%';
  }

  @override
  String obd2DiagnosticsTierLine(String tier, String percent) {
    return '$tier: $percent%';
  }

  @override
  String obd2DiagnosticsSupportLine(
    int supported,
    int unsupported,
    int unknown,
  ) {
    return '$supported supported · $unsupported unsupported · $unknown unknown';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Suspicious $suspicious of $total samples';
  }

  @override
  String obd2DiagnosticsPidRow(
    String pid,
    int polled,
    int ok,
    int noData,
    int timeout,
    int error,
    int p50,
    int p95,
    String effectiveHz,
    String targetHz,
  ) {
    return '$pid: $polled polled · $ok ok · $noData ND · $timeout TO · $error err · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Dongle init transcript';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protocol $protocol · $start · firmware $firmware · $tier · $pids PIDs';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'warm';

  @override
  String get obd2DiagnosticsInitCold => 'cold';

  @override
  String get obd2DiagnosticsEmpty =>
      'No OBD2 comm-health details for this trip. The recording itself is unaffected — check the trip\'s own OBD2 coverage above.';

  @override
  String get obd2DiagnosticsExplain =>
      'Captured while recording to debug the dongle↔app communication — only collected in Developer mode.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 communication health';

  @override
  String get obd2HealthNavLabel => 'OBD2 communication health';

  @override
  String get obd2HealthLiveSection => 'Live session';

  @override
  String get obd2HealthHistorySection => 'Recent sessions';

  @override
  String get obd2HealthDownloadJson => 'Download as JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Download init transcript only';

  @override
  String get obd2HealthDownloadError => 'Couldn\'t save the diagnostics file';

  @override
  String get obd2TestAdapterLabel => 'Adapter to test';

  @override
  String get obd2TestAdapterScanOption => 'Scan for adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Connect to $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Run adapter test';

  @override
  String get obd2TestRunButton => 'Run adapter test';

  @override
  String get obd2TestRunPassed => 'Adapter test passed';

  @override
  String get obd2TestRunFailed => 'Adapter test failed';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — engine off; start the engine to read live data';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed of $total steps OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Stop the active recording before running the adapter test.';

  @override
  String get obd2TestStepScan => 'Scan for adapter';

  @override
  String get obd2TestStepBluetooth => 'Phone Bluetooth';

  @override
  String get obd2TestStepConnect => 'Connect & init';

  @override
  String get obd2TestStepInfo => 'Adapter info';

  @override
  String get obd2TestStepSupportedPids => 'Supported PIDs';

  @override
  String get obd2TestStepProtocol => 'Vehicle protocol';

  @override
  String get obd2TestStepSampleReads => 'Sample reads';

  @override
  String get obd2TestStepSoak => 'Sustained polling';

  @override
  String get obd2TestStepReconnect => 'Reconnect test';

  @override
  String get obd2TestStepDisconnect => 'Disconnect';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Timed out';

  @override
  String get obd2TestStatusGarbage => 'Unreadable reply';

  @override
  String get obd2TestStatusNoResponse => 'No response';

  @override
  String get obd2TestStatusFail => 'Failed';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'unknown — defaulting to BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Recent connect attempts';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'No connect attempts recorded yet.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Download connect trace';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Download all connect traces';

  @override
  String get obd2HealthConnectOrigin => 'Origin';

  @override
  String get obd2HealthConnectTransport => 'Transport';

  @override
  String get obd2HealthConnectOutcome => 'Outcome';

  @override
  String get obd2HealthConnectScanList => 'Scanned devices';

  @override
  String get obd2HealthConnectSteps => 'Steps';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Unknown adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Session recorded · $samples engine samples · $percent% coverage';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'What this trip recorded';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples of $total samples carried engine data ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Protocol handshake: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Session ended: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Session length: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Fuel figures came from the adapter, not from GPS estimates.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'The per-PID communication breakdown was not captured for this trip. Turn on developer mode before recording to collect it.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Couldn\'t reach \'$adapterName\' — pick another adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Other Bluetooth devices';

  @override
  String get obd2PickerTapToTry => 'Unrecognized — tap to try';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone works with Bluetooth-LE adapters only. A Classic-only adapter (e.g. vLinker BM, Konnwei KW902) must be used on Android.';

  @override
  String get obd2PairingConfirmHint =>
      'Confirm the pairing request on your phone';

  @override
  String get obd2ScanEmptyTitle => 'No adapter found';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth is on and permissions are granted. Make sure the adapter is plugged into the OBD2 port and the ignition is on, then scan again.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'This device has no Bluetooth Low Energy hardware, so it cannot connect to an OBD2 adapter.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth is switched off. Turn it on to scan for your adapter.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo needs Bluetooth permission to find your adapter.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Bluetooth permission was denied permanently. Grant it in system settings to scan for your adapter.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Location services are switched off on this device. Android needs them enabled to scan for Bluetooth adapters — no location is recorded or shared.';

  @override
  String get obd2ScanOpenSettings => 'Open settings';

  @override
  String get obd2WaitingForEngineBanner =>
      'Waiting for the engine — recording on GPS';

  @override
  String get obd2StartEngineToReconnect => 'Start the engine to reconnect';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Engine is off — start it to reconnect';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Engine off for $minutes min — stop recording?';
  }

  @override
  String get obd2ParkedPromptStop => 'Stop';

  @override
  String get obd2ParkedPromptKeep => 'Keep';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Engine off for the first $head and the last $tail of this trip — coverage is measured while the engine ran.';
  }

  @override
  String get obd2ReconnectInProgress => 'Reconnecting to your OBD2 adapter…';

  @override
  String get obd2StatusEngineOff => 'OBD2 paused — engine off';

  @override
  String get obd2StatusEngineOffBody =>
      'The adapter was reachable but the vehicle bus stayed silent, so automatic reconnection is paused. It resumes when you drive or reopen the app — or reconnect now.';

  @override
  String get obd2StatusReconnectNow => 'Reconnect now';

  @override
  String get autoRecordNotificationTitle => 'Trip auto-record';

  @override
  String get autoRecordNotificationText => 'Watching for your OBD2 adapter';

  @override
  String get obd2ResetConnection => 'Reset connection';

  @override
  String get obd2ResetConnectionDone =>
      'Adapter reset — connection re-established';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapter reset — reconnecting in the background';

  @override
  String get ocrTesterTitle => 'OCR tester';

  @override
  String get ocrTesterNavLabel => 'OCR tester';

  @override
  String get ocrTesterExplain =>
      'Run the pump / receipt OCR pipeline on a chosen photo and inspect every step — only available in Developer mode.';

  @override
  String get ocrTesterCapture => 'Capture';

  @override
  String get ocrTesterPickImage => 'Pick image';

  @override
  String get ocrTesterRun => 'Run';

  @override
  String get ocrTesterCountry => 'Country';

  @override
  String get ocrTesterCountryNone => 'Default (no profile)';

  @override
  String get ocrTesterNoImage => 'Pick or capture an image, then Run.';

  @override
  String get ocrTesterRunning => 'Running OCR…';

  @override
  String get ocrTesterOverlaySection => 'Block overlay';

  @override
  String get ocrTesterStepsSection => 'Pipeline steps';

  @override
  String get ocrTesterLegendLabel => 'Label';

  @override
  String get ocrTesterLegendNumeric => 'Numeric';

  @override
  String get ocrTesterLegendNoise => 'Noise';

  @override
  String get ocrTesterLegendDerived => 'Derived';

  @override
  String get ocrTesterStageGlare => 'Capture / glare';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Classify';

  @override
  String get ocrTesterStageAssemble => 'Assemble';

  @override
  String get ocrTesterStageAnchor => 'Anchor';

  @override
  String get ocrTesterStageFallback => 'Fallback';

  @override
  String get ocrTesterStageCrossCheck => 'Cross-check';

  @override
  String get ocrTesterStageConfidence => 'Confidence';

  @override
  String get ocrTesterStageGate => 'Gate';

  @override
  String get ocrTesterStageBrand => 'Brand';

  @override
  String get ocrTesterStageOverrides => 'Overrides';

  @override
  String get ocrTesterStageReconcile => 'Reconcile';

  @override
  String get ocrTesterStageResult => 'Result';

  @override
  String get ocrTesterChipRead => 'READ';

  @override
  String get ocrTesterChipDerived => 'DERIVED';

  @override
  String get ocrTesterGateAccepted => 'Accepted';

  @override
  String get ocrTesterGateRejected => 'Rejected';

  @override
  String get ocrTesterFallbackBanner =>
      'A field was recovered via magnitude fallback — verify it.';

  @override
  String get ocrTesterStageNoData => 'Stage did not run.';

  @override
  String get ocrTesterCopyJson => 'Copy as JSON';

  @override
  String get ocrTesterExportPackage => 'Export package';

  @override
  String get ocrTesterCopied => 'OCR trace copied to clipboard.';

  @override
  String get ocrTesterExported => 'OCR package saved to your Downloads folder.';

  @override
  String get onboardingObd2StepTitle => 'Connect your OBD2 adapter';

  @override
  String get onboardingObd2StepBody =>
      'Plug your OBD2 adapter into the car\'s port and turn the ignition on. We\'ll read the VIN and fill in engine details for you.';

  @override
  String get onboardingObd2ConnectButton => 'Connect adapter';

  @override
  String get onboardingObd2SkipButton => 'Maybe later';

  @override
  String get onboardingObd2ReadingVin => 'Reading VIN…';

  @override
  String get onboardingObd2ConnectFailed =>
      'Couldn\'t connect to the adapter. You can retry or skip.';

  @override
  String get onboardingPickUseMode => 'Pick a use mode to continue.';

  @override
  String get onboardingObd2LaterNote =>
      'You can pair a Bluetooth OBD2 adapter anytime later from the vehicle screen to record trips and read engine data.';

  @override
  String get openHoursUnknown => 'Hours unknown';

  @override
  String get open24Hours => 'Open 24 hours';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Public holidays';

  @override
  String get closedLabel => 'Closed';

  @override
  String get openingHoursNotAvailable => 'Opening hours not available';

  @override
  String get showAllHours => 'Show all hours';

  @override
  String get showLessHours => 'Show less';

  @override
  String get openStateUnknown => 'Unknown';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Station is open',
      'false': 'Station is closed',
      'other': 'Open state unknown',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Camera Access';

  @override
  String get permissionRationaleCameraSubtitle =>
      'This app would like to use your camera to read receipts, pump displays and QR codes.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'What happens with the camera image:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'The image is used only to read the receipt, the pump display or the QR code — recognition runs on your device.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'The photo is discarded after the scan.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Nothing is uploaded unless you file a bad-scan report and confirm it.';

  @override
  String get permissionRationaleBluetoothTitle => 'Bluetooth Access';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'This app would like to use Bluetooth to connect to your OBD2 adapter.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'What happens with Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth is used only to find and talk to your OBD2 adapter.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'The adapter identifier stays on your device — it is synced only with TankSync, as part of the vehicle profile.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'On Android 11 and below the system also asks for location, because Bluetooth scanning is a location-class permission there.';

  @override
  String get permissionRationaleNotificationsTitle => 'Notifications';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'This app would like to send you notifications for price alerts and the trip-recording status.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'What happens with notifications:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Notifications are used for local price alerts and the trip-recording status.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'They are generated on your device — nothing leaves the device.';

  @override
  String get permissionRationaleRevoke =>
      'You can revoke this in your device settings at any time.';

  @override
  String get permissionRationaleLegalBasis =>
      'Legal basis: Art. 6(1)(a) GDPR (Consent)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'elapsed';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: consumption estimates re-anchored to the pump ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Open scanned link?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'This QR code points to $host. Only open links you trust.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Open link';

  @override
  String get qrLaunchConfirmCancel => 'Cancel';

  @override
  String get radarPinHelpTitle => 'About pin';

  @override
  String get radarPinHelpBody =>
      'Pin keeps the screen on and hides system bars so the closest-station readout stays readable on a dashboard mount. Tap again to release. Auto-releases when the radar stops.';

  @override
  String get radarAutoPinTitle => 'Always pin when the radar starts';

  @override
  String get radarAutoPinSubtitle =>
      'Pin the radar automatically every time instead of tapping each time. Uses more battery.';

  @override
  String get radarScopeShowScope => 'Radar view';

  @override
  String get radarScopeShowList => 'List view';

  @override
  String get alertsRadiusFrequencyLabel => 'Check frequency';

  @override
  String get alertsRadiusFrequencyDaily => 'Once a day';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Twice a day';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Three times a day';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Four times a day';

  @override
  String get radiusAlertPickOnMap => 'Pick on map';

  @override
  String get radiusAlertMapPickerTitle => 'Pick alert center';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirm';

  @override
  String get radiusAlertMapPickerCancel => 'Cancel';

  @override
  String get radiusAlertMapPickerHint =>
      'Drag the map to position the alert center';

  @override
  String get reconcileWorkflowTitle => 'Reconcile your fuel';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'We found a $gap L gap';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'You pumped $pumped L, but your recorded trips only account for $consumed L. That leaves $gap L unexplained.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'This usually means a drive wasn\'t recorded (the adapter was unplugged or the app was closed), or a fill-up is missing or mistyped.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Until this is resolved, your fuel total and your trips total won\'t match.';

  @override
  String get reconcileWorkflowAttributeQuestion => 'Help us attribute the gap';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Are all your fill-ups for this tank complete and correct?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Are all your drives recorded?';

  @override
  String get reconcileWorkflowAnswerYes => 'Yes';

  @override
  String get reconcileWorkflowAnswerNo => 'No';

  @override
  String get reconcileWorkflowPathAHint =>
      'A fill-up is missing or wrong — we\'ll add a correction so your fill-ups add up.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Your fill-ups are right and a drive went unrecorded — we\'ll add a virtual trip for the missing distance.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Correction litres';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'How far was the unrecorded drive? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Decide later';

  @override
  String get reconcileWorkflowBack => 'Back';

  @override
  String get reconcileWorkflowNext => 'Next';

  @override
  String get reconcileWorkflowApply => 'Apply';

  @override
  String get reconcileVirtualTrajetLabel => 'Virtual trip — tap to edit';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Edit virtual trip';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'This trip was added to account for fuel you used while driving without recording. Adjust the distance or fuel, or delete it.';

  @override
  String get reconcileVirtualTrajetDelete => 'Delete virtual trip';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Unresolved fuel/trip gap of $gap L — tap to resolve';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Resolve unresolved fuel and trip gap';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/session';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String settingsSearchNoResults(String query) {
    return 'No settings match \"$query\"';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profiles & region';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Country, language, fuel type, search radius, route planning';

  @override
  String get settingsTopicProfilesKeywords =>
      'profile, country, language, fuel, radius, postal code, route, home, rating, start screen';

  @override
  String get settingsTopicVehiclesTitle => 'Vehicles & OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Your cars, tank size, OBD2 adapter pairing';

  @override
  String get settingsTopicVehiclesKeywords =>
      'vehicle, car, obd, obd2, adapter, bluetooth, tank, engine, vin, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Driving & consumption';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, rewards, fuel-station radar, troubleshooting';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, eco, haptic, voice, gamification, radar, glide, trip, consumption, fuel club, loyalty, obd2 log, pin';

  @override
  String get settingsTopicPricesTitle => 'Prices & alerts';

  @override
  String get settingsTopicPricesSubtitle =>
      'Price alerts, voice announcements, price history, community reports';

  @override
  String get settingsTopicPricesKeywords =>
      'alert, notification, price, history, prediction, best time, community, report, qr, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Units & display';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Theme, distance unit, home-screen widget';

  @override
  String get settingsTopicUnitsKeywords =>
      'theme, dark, light, eco, unit, km, miles, widget, colour, color, display, appearance';

  @override
  String get settingsTopicFeaturesTitle => 'Features & use mode';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Use-mode presets and every feature switch';

  @override
  String get settingsTopicFeaturesKeywords =>
      'feature, mode, basic, medium, full, custom, switch, toggle, station types, fuel stations, ev stations, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Data sources & location';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'API keys, GPS position, automatic profile switching';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, key, gps, location, position, data source, tankerkoenig, opencharge';

  @override
  String get settingsTopicSyncTitle => 'Sync & account';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'privacy, consent, gdpr, delete, erase, storage, cache, data, error reporting, vin';

  @override
  String get settingsTopicBackupTitle => 'Backup & restore';

  @override
  String get settingsTopicBackupSubtitle =>
      'Export or restore a full backup of your data';

  @override
  String get settingsTopicBackupKeywords =>
      'backup, export, restore, import, zip, xml, transfer';

  @override
  String get settingsTopicAdvancedSubtitle => 'GitHub token, developer tools';

  @override
  String get settingsTopicAdvancedKeywords =>
      'developer, debug, token, pat, github, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Version, licences, links';

  @override
  String get settingsTopicAboutKeywords =>
      'about, version, licence, license, donate, github, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Turn on consumption tracking in Features & use mode to configure vehicles, coaching and rewards.';

  @override
  String get settingsOpenFeaturesLink => 'Open Features & use mode';

  @override
  String get settingsRadarTileSubtitle =>
      'Radius, price mode, polling and screen pinning for the active profile';

  @override
  String get settingsRadarNoProfileHint =>
      'Create a profile first — the radar settings are stored per profile.';

  @override
  String get settingsRadarPinHeader => 'Screen pinning';

  @override
  String get settingsAlertsTileSubtitle =>
      'Station and radius alerts that notify you of price drops';

  @override
  String get settingsPriceFeaturesHeader => 'Price features';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Voice announcements are off. Turn on Voice feedback and Voice announcements in Features & use mode to hear nearby cheap fuel while driving.';

  @override
  String get settingsDistanceUnitTitle => 'Distance unit';

  @override
  String get settingsDistanceUnitSubtitle =>
      'From the active profile\'s country';

  @override
  String get settingsObd2AdapterTitle => 'OBD2 adapter';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Adapters are paired per vehicle — open a vehicle to pair or change its adapter';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Consents';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Cloud Sync and trip-sync consents live under Privacy & data';

  @override
  String get settingsBackupExportSubtitle =>
      'Vehicles, fill-ups, trips and charging logs as a ZIP file';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Merge or replace your data from a previous backup ZIP';

  @override
  String get settingsStationTypesLink =>
      'Station types are set in Features & use mode';

  @override
  String get routeSearchCriterionLabel => 'Station choice per route segment';

  @override
  String get routeSearchCriterionCheapest => 'Cheapest';

  @override
  String get routeSearchCriterionNearest => 'Nearest to route';

  @override
  String get routeSearchTopNLabel => 'Candidates per sample point';

  @override
  String routeSearchTopNCaption(int count) {
    return 'Up to $count stations are considered at each point along the route.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Fuel for price search (hybrid)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Vehicle default';

  @override
  String get scopeThisProfile => 'This profile';

  @override
  String get scopeAllProfiles => 'All profiles';

  @override
  String get scopeThisVehicle => 'This vehicle';

  @override
  String get featureLabel_manualConsumption => 'Manual consumption logging';

  @override
  String get featureDescription_manualConsumption =>
      'Track fuel fill-ups and EV charging sessions by hand (no OBD2 adapter required).';

  @override
  String get featureLabel_loyaltyCards => 'Loyalty cards';

  @override
  String get featureDescription_loyaltyCards =>
      'Fuel-club / loyalty program cards with per-litre discounts in price comparisons.';

  @override
  String get featureLabel_startupTrace => 'Startup initialization trace';

  @override
  String get featureDescription_startupTrace =>
      'Record the timed phases of app startup, view them as a waterfall and export them — a developer diagnostic.';

  @override
  String get locationGpsAutoHint =>
      'GPS position is acquired automatically when you search. You can also update it manually here.';

  @override
  String get locationClearGpsBody =>
      'Clear the stored GPS position? You can update it again at any time.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'That file type can\'t be imported yet — share a photo of the receipt instead.';

  @override
  String get shareReceiptFailed =>
      'Couldn\'t read the shared receipt — try sharing it again or add the fill-up manually.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Share receipt to import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Share a receipt photo from another app to pre-fill a fill-up — date, litres, total, and station are read on-device.';

  @override
  String get speedConsumptionCardTitle => 'Consumption by speed';

  @override
  String get speedBandIdleJam => 'Idle / jam';

  @override
  String get speedBandUrban => 'Urban (10–50)';

  @override
  String get speedBandSuburban => 'Suburban (50–80)';

  @override
  String get speedBandRural => 'Rural (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-cruise (100–115)';

  @override
  String get speedBandMotorway => 'Motorway (115–130)';

  @override
  String get speedBandMotorwayFast => 'Motorway fast (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Record 30+ minutes of trips with the OBD2 adapter to unlock the speed/consumption analysis.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % of driving';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Need more data';

  @override
  String get splashLoadingLabel => 'Loading Sparkilo';

  @override
  String get storageRecoveryTitle => 'Storage problem';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo couldn\'t open its local data store. The storage file appears to be damaged.';

  @override
  String get storageRecoveryGuidance =>
      'To recover, clear the app\'s storage in your device settings, or reinstall the app. Your favourites and history are stored on this device only, so they cannot be restored automatically.';

  @override
  String syncAdoptTitle(String email) {
    return 'Join $email\'s account';
  }

  @override
  String get syncAdoptSubtitle =>
      'Sign in with this account\'s password to share its data across both devices.';

  @override
  String get syncAdoptPasswordLabel => 'Account password';

  @override
  String get syncAdoptJoinButton => 'Join account';

  @override
  String get syncAdoptUseDifferentAccount => 'Use a different account instead';

  @override
  String get syncDeleteDataTitle => 'Delete synced data';

  @override
  String get syncDeleteDataSubtitle =>
      'Remove your trips, vehicles or fill-ups from the sync database';

  @override
  String get syncDeleteDataPickTitle => 'Delete which synced data?';

  @override
  String get syncDeleteDataCategoryTrips => 'Trips';

  @override
  String get syncDeleteDataCategoryVehicles => 'Vehicles';

  @override
  String get syncDeleteDataCategoryFillUps => 'Fill-ups';

  @override
  String get syncDeleteDataCategoryEverything => 'Everything';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Delete $category from the sync database?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'This removes the selected data from your sync database and it will not re-sync from your other devices. Data stored locally on this device is kept.';

  @override
  String get syncDeleteDataConfirmAction => 'Delete from server';

  @override
  String get syncDeleteDataDone => 'Synced data deleted';

  @override
  String get syncDeleteDataFailed =>
      'Deleting synced data failed — please try again';

  @override
  String get syncRelinkTitle => 'Cloud sync needs re-linking';

  @override
  String get syncRelinkBody =>
      'This device\'s saved sync identity is signed out. Sign in with your email to re-link your synced data, or start fresh with a new identity.';

  @override
  String get syncRelinkSignInAction => 'Sign in to re-link';

  @override
  String get syncRelinkStartFreshAction => 'Start fresh';

  @override
  String get syncRelinkStartFreshTitle => 'Start fresh?';

  @override
  String get syncRelinkStartFreshBody =>
      'A new anonymous identity will be created for this device. Data synced under the old identity stays on the server but will no longer be reachable from here unless you sign in with its email account.';

  @override
  String get syncRelinkStartFreshConfirm => 'Start fresh';

  @override
  String get tankLevelTitle => 'Tank level';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km of range';
  }

  @override
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km at your last tank\'s consumption';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Long-run average: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Last fill-up: $date · $count trip(s) since';
  }

  @override
  String get tankLevelEmptyNoFillUp => 'Log a fill-up to see your tank level';

  @override
  String get tankLevelDetailSheetTitle => 'Trips since last fill-up';

  @override
  String get addFillUpIsFullTankLabel => 'Full tank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tank filled to the brim — uncheck if this was a partial fill';

  @override
  String tankLevelSourceFillUp(String date) {
    return 'Anchored at the last fill-up: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'OBD2 tank sensor · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Tank mix: $mix';
  }

  @override
  String get tankReportTitle => 'Tank report';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Since the previous full tank: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km more than the previous tank';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km less than the previous tank';
  }

  @override
  String get tankReportTrendFlat => 'Level with the previous tank';

  @override
  String get tankReportNoPrevious =>
      'Evolution appears after your next full tank.';

  @override
  String get tankReportExplainHeader => 'What the recordings suggest';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'High-RPM share $cur % (was $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Harsh events $cur/100 km (was $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Cold starts $cur (was $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Idle share $cur % (was $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Recordings are spontaneous and cover only part of this tank — these hints are indicative, not the full story.';

  @override
  String get themeCardTitle => 'Theme';

  @override
  String get themeCardSubtitleSystem => 'System';

  @override
  String get themeCardSubtitleLight => 'Light';

  @override
  String get themeCardSubtitleDark => 'Dark';

  @override
  String get themeSettingsScreenTitle => 'Theme';

  @override
  String get themeSettingsSystemLabel => 'Follow system';

  @override
  String get themeSettingsLightLabel => 'Light';

  @override
  String get themeSettingsDarkLabel => 'Dark';

  @override
  String get themeSettingsSystemDescription =>
      'Match the current device appearance.';

  @override
  String get themeSettingsLightDescription =>
      'Bright backgrounds — best for daytime use.';

  @override
  String get themeSettingsDarkDescription =>
      'Dark backgrounds — easier on the eyes at night and saves battery on OLED screens.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'The app\'s signature green look — bright and easy to read, with softly green-tinted backgrounds.';

  @override
  String get throttleRpmHistogramTitle => 'How you used the engine';

  @override
  String get throttleRpmHistogramThrottleSection => 'Throttle position';

  @override
  String get throttleRpmHistogramRpmSection => 'Engine RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Coast (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Light (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Firm (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Wide-open (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Idle (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Cruise (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Spirited (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Hard (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'No throttle or RPM samples in this trip.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Trips';

  @override
  String get trajetsStartRecordingButton => 'Start recording';

  @override
  String get trajetsResumeRecordingButton => 'Resume recording';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Connecting to OBD2 adapter…';

  @override
  String get tripStartProgressReadingVehicleData => 'Reading vehicle data…';

  @override
  String get tripStartProgressStartingRecording => 'Starting recording…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

  @override
  String get trajetsEmptyStateTitle => 'No trips yet';

  @override
  String get trajetsEmptyStateBody =>
      'Tap Start recording to begin logging your drives.';

  @override
  String trajetsRowDistance(String km) {
    return '$km km';
  }

  @override
  String trajetsRowDuration(String minutes) {
    return '$minutes min';
  }

  @override
  String trajetsRowAvgConsumption(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get trajetDetailSummaryTitle => 'Summary';

  @override
  String get trajetDetailFieldDate => 'Date';

  @override
  String get trajetDetailFieldVehicle => 'Vehicle';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adapter';

  @override
  String get trajetDetailFieldDistance => 'Distance';

  @override
  String get trajetDetailFieldDuration => 'Duration';

  @override
  String get trajetDetailFieldAvgConsumption => 'Avg consumption';

  @override
  String get trajetDetailFieldFuelUsed => 'Fuel used';

  @override
  String get trajetDetailFieldFuelCost => 'Fuel cost';

  @override
  String get trajetDetailFieldAvgSpeed => 'Avg speed';

  @override
  String get trajetDetailFieldMaxSpeed => 'Max speed';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Speed (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Fuel rate (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Engine load (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitudeRelative => 'Altitude (m, from start)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Charts';

  @override
  String get trajetsRowColdStartChip => 'Cold start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Engine didn\'t reach operating temperature during this trip — fuel consumption was higher than usual.';

  @override
  String get trajetDetailChartEmpty => 'No samples recorded';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Share';

  @override
  String get trajetDetailShareImageOption => 'Share image';

  @override
  String get trajetDetailShareGpxOption => 'Share GPS track (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'No GPS samples in this trip';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — trip on $date';
  }

  @override
  String get trajetDetailShareError => 'Couldn\'t generate share image';

  @override
  String get trajetDetailDownloadCsvOption => 'Download telemetry (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetry (JSON)';

  @override
  String get trajetDetailDownloadError => 'Couldn\'t save the file';

  @override
  String get trajetDetailDeleteAction => 'Delete';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Delete this trip?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'This trip will be permanently removed from your history.';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Delete';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapter connected but not returning data. Try a different adapter or check the vehicle\'s diagnostic protocol.';

  @override
  String get trajetsViewAllOnMap => 'View all on map';

  @override
  String get trajetsMapTitle => 'Trajets on map';

  @override
  String get trajetsMapShareGpx => 'Share GPX';

  @override
  String get trajetsMapEmpty =>
      'None of the selected trajets carry GPS samples.';

  @override
  String get trajetsMapShareError => 'Couldn\'t share the GPX file';

  @override
  String get trajetDetailChartBoost => 'Boost pressure (MAP − ambient)';

  @override
  String get trajetDetailChartIat => 'Intake air temperature';

  @override
  String get trajetDetailChartTiming => 'Ignition timing advance';

  @override
  String get trajetObd2Degraded =>
      'Started with the OBD2 adapter but recorded mostly GPS — engine data is incomplete';

  @override
  String get tripLengthCardTitle => 'Consumption by trip length';

  @override
  String get tripLengthBucketShort => 'Short (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Medium (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Long (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Need more data';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
      zero: 'no trips',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Trip path';

  @override
  String get tripPathCardSubtitle => 'GPS-recorded route';

  @override
  String get tripPathLegendEfficient => 'Efficient (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Borderline (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Wasteful (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Fuel Station Radar';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get fuelStationRadarNearer => 'Nearer station';

  @override
  String get fuelStationRadarFarther => 'Farther station';

  @override
  String get fuelStationRadarStart => 'Start fuel station radar';

  @override
  String get stopRadar => 'Stop radar';

  @override
  String get fuelStationRadarResultBadge => 'Fuel Station Radar result';

  @override
  String get radarUpdatingLocation => 'Updating your location…';

  @override
  String get radarSearching => 'Searching…';

  @override
  String get highwayModeChip =>
      'Highway mode — showing stations ahead on your route';

  @override
  String get tripRecordingPinTooltip =>
      'Pinning keeps the screen on — uses more battery';

  @override
  String get tripRecordingPinSemanticOn => 'Unpin recording form';

  @override
  String get tripRecordingPinSemanticOff => 'Pin recording form';

  @override
  String get tripRecordingPinHelpTooltip => 'What does pin do?';

  @override
  String get tripRecordingPinHelpTitle => 'About pin';

  @override
  String get tripRecordingPinHelpBody =>
      'Pin keeps the screen on and hides system bars so the form stays readable on a dashboard mount. Tap again to release. Auto-releases when the trip stops.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Recording continues in the background. Tap the red banner at the top of any screen to return.';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Pin the screen to keep GPS active during the trip — Android may throttle GPS during sleep.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimise to a floating tile';

  @override
  String get tripRecordingAutoPinTitle => 'Always pin when recording starts';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Pin the form automatically every drive instead of tapping each time. Uses more battery.';

  @override
  String get tripRecordingConnectingTitle => 'Starting recording…';

  @override
  String get tripRecordingSavingTitle => 'Saving trip…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripRecordingGpsNotificationTitle => 'Recording your trip';

  @override
  String get tripRecordingGpsNotificationText =>
      'Tracking your route for fuel & driving stats';

  @override
  String get tripShareAction => 'Share with another account';

  @override
  String get tripShareSheetTitle => 'Share this trip';

  @override
  String get tripShareSheetSubtitle =>
      'Give another TankSync account read-only access to this recorded trip.';

  @override
  String get tripShareEmailLabel => 'Recipient email';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Share';

  @override
  String get tripShareCreateLinkButton => 'Create share link';

  @override
  String get tripShareLinkCreated =>
      'Share link copied — paste it to the recipient.';

  @override
  String get tripShareSuccess => 'Trip shared.';

  @override
  String get tripShareRecipientNotFound =>
      'No TankSync account uses that email.';

  @override
  String get tripShareError => 'Couldn\'t share this trip. Try again.';

  @override
  String get tripShareExistingTitle => 'Shared with';

  @override
  String get tripShareExistingEmpty => 'Not shared with anyone yet.';

  @override
  String get tripShareDirectRecipient => 'An account';

  @override
  String get tripShareLinkRecipient => 'Share link (unclaimed)';

  @override
  String get tripShareRevokeTooltip => 'Revoke';

  @override
  String get tripShareRevoked => 'Share revoked.';

  @override
  String get trajetsSharedSectionTitle => 'Shared with me';

  @override
  String get trajetsSharedBadge => 'Shared';

  @override
  String get tripVerdictPromptTitle => 'How did this trip feel?';

  @override
  String get tripVerdictSmooth => 'Smooth';

  @override
  String get tripVerdictModerate => 'Moderate';

  @override
  String get tripVerdictAggressive => 'Aggressive';

  @override
  String get tripVerdictDismiss => 'Not now';

  @override
  String get tripVerdictThanks =>
      'Thanks — this helps calibrate your driving analysis.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Fill-up deleted';

  @override
  String get trajetDeletedUndoSnackbar => 'Recording deleted';

  @override
  String get searchFailedSnackbar => 'Search failed — please try again';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Updated $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Also: $names';
  }

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Raw: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Unbranded station';

  @override
  String get unsupportedRegionTitle => 'Not available in your region yet';

  @override
  String get unsupportedRegionBody =>
      'We don\'t have fuel prices for your country yet, so results may be empty or from another country. You can still pick a supported country in the search settings.';

  @override
  String get unsupportedRegionDismiss => 'Got it';

  @override
  String get configureCountryTitle => 'Set your country';

  @override
  String get configureCountryBody =>
      'Your country is supported, but it isn\'t set up yet — so prices may be from another country. Choose your country in the search settings to see local prices.';

  @override
  String get stalePriceBadge => 'Old price';

  @override
  String get radiusAlertCenterChipGps => 'My position';

  @override
  String get radiusAlertCenterChipMap => 'Map point';

  @override
  String radiusAlertCenterChipPostal(String postalCode) {
    return 'Postal code $postalCode';
  }

  @override
  String get radiusAlertCenterClear => 'Clear location';

  @override
  String get radiusAlertBlockerLabel => 'Enter a label';

  @override
  String get radiusAlertBlockerThreshold => 'Enter a threshold above 0';

  @override
  String get radiusAlertBlockerLocation => 'Choose a location';

  @override
  String get allPricesLegend =>
      'Filled = cheapest of these results. Second figure = what 100 km costs on that fuel with your vehicle.';

  @override
  String get allPricesLegendPricesOnly =>
      'Filled = cheapest of these results. Add a vehicle and log fill-ups to see the cost per 100 km.';

  @override
  String get allPricesNoPriceMask => '—';

  @override
  String get allPricesBestMarker => 'best';

  @override
  String allPricesDelta(String amount) {
    return '+$amount';
  }

  @override
  String allPricesCostPer100km(String cost) {
    return '$cost/100 km';
  }

  @override
  String allPricesVerdictHere(String fuel, String cost) {
    return 'Cheapest here: $fuel at $cost';
  }

  @override
  String get allPricesVerdictWinsResults => 'cheapest of the results';

  @override
  String allPricesMoreFuels(int count) {
    return '+$count';
  }

  @override
  String allPricesMoreFuelsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more fuels',
      one: 'Show 1 more fuel',
    );
    return '$_temp0';
  }

  @override
  String get allPricesFewerFuelsTooltip => 'Hide the extra fuels';

  @override
  String allPricesCellPriceSemantics(String fuel, String price) {
    return '$fuel $price';
  }

  @override
  String allPricesCellCostSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '$fuel $price, $cost per 100 km at $consumption';
  }

  @override
  String allPricesCellNoPriceSemantics(String fuel) {
    return '$fuel, no price';
  }

  @override
  String allPricesCellUnavailableSemantics(String fuel) {
    return '$fuel, out of stock';
  }

  @override
  String allPricesCellUnusableSemantics(String fuel) {
    return '$fuel, not usable by your vehicle';
  }

  @override
  String get brandMarkFuelGeneric => 'Fuel station';

  @override
  String get brandMarkEvGeneric => 'Charging point';

  @override
  String get fillInventoryTitle => 'Fill-up summary';

  @override
  String fillInventorySubtitleFull(String date, String fuel) {
    return 'Full tank on $date · $fuel';
  }

  @override
  String fillInventorySubtitlePartial(String date, String fuel) {
    return 'Partial fill on $date · $fuel';
  }

  @override
  String fillInventoryKmSinceLastFull(String km) {
    return '$km km since the last full tank';
  }

  @override
  String fillInventoryPumpLiters(String liters) {
    return '$liters L pumped';
  }

  @override
  String fillInventoryPumpConsumption(String value) {
    return 'Pump consumption: $value';
  }

  @override
  String fillInventoryRecordedTrips(int coverage, String value) {
    return 'Recorded trips: $coverage % of the tank · $value raw';
  }

  @override
  String get fillInventoryNoRecordedTrips => 'No recorded trip in this tank';

  @override
  String fillInventoryTankNow(String liters, String km) {
    return 'Tank now: $liters L · ≈ $km km at pump consumption';
  }

  @override
  String fillInventoryTankNowNoRange(String liters) {
    return 'Tank now: $liters L';
  }

  @override
  String fillInventoryCalibrationApplied(
    String before,
    String after,
    String percent,
  ) {
    return 'Pump calibration: ×$before → ×$after ($percent %)';
  }

  @override
  String fillInventoryCalibrationSkipped(String reason) {
    return 'Pump calibration: skipped — $reason';
  }

  @override
  String get fillInventorySkipNotFullTank =>
      'partial fill (the tank window stays open)';

  @override
  String get fillInventorySkipCorrection =>
      'correction entry, not a pumped fill';

  @override
  String get fillInventorySkipNoVehicle => 'no vehicle on this fill';

  @override
  String get fillInventorySkipNoWindow =>
      'first full tank (no window closed yet)';

  @override
  String fillInventorySkipCoverageTooLow(int coverage) {
    return 'recorded trips cover $coverage % of the tank (60 % needed)';
  }

  @override
  String fillInventorySkipRecordedTooShort(String km) {
    return 'only $km recorded km (40 km needed)';
  }

  @override
  String get fillInventorySkipNoRecordedFuel =>
      'the recorded trips carry no fuel figure';

  @override
  String get fillInventorySkipImplausible =>
      'pump and recordings disagree too much — check the receipt';

  @override
  String get fillInventoryDismiss => 'Got it';

  @override
  String tankReportResidualAfterCalibration(String percent) {
    return 'Gap after calibration: $percent %';
  }

  @override
  String get tripFuelSourceMeasured => 'Measured';

  @override
  String get tripFuelSourceEstimatedCalibrated => 'Estimated · calibrated';

  @override
  String get tripFuelSourceEstimated => 'Estimated';

  @override
  String get tripFuelSourceGps => 'GPS';

  @override
  String get tripFuelSourceMeasuredTooltip =>
      'Fuel rate reported by the engine (PID 5E / 9D / A2) — never rescaled';

  @override
  String get tripFuelSourceEstimatedTooltip =>
      'Fuel estimated from air mass — rescaled by the pump calibration';

  @override
  String get tripFuelSourceGpsTooltip =>
      'GPS-physics estimate — no engine data';

  @override
  String get tripFuelSourceRecalculated => 'recalculated';

  @override
  String tripDetailGainApplied(String percent) {
    return 'Pump gain applied: $percent %';
  }

  @override
  String tripDetailRecalculatedAfterFill(String date) {
    return 'Recalculated after the fill-up of $date';
  }

  @override
  String get criteriaModeNearby => 'Nearby';

  @override
  String get criteriaModeRoute => 'Route';

  @override
  String get criteriaSubmit => 'Search';

  @override
  String get criteriaReset => 'Reset';

  @override
  String get criteriaResetDone => 'Criteria reset to your defaults';

  @override
  String get criteriaSubmitDisabledRoute => 'Enter a start and a destination';

  @override
  String get criteriaSubmitDisabledSearching => 'Search in progress…';

  @override
  String criteriaShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get criteriaShowLess => 'Show less';

  @override
  String get criteriaBrands => 'Brands';

  @override
  String get criteriaRouteOptions => 'Route options';

  @override
  String criteriaRouteOptionsSummary(
    int segmentKm,
    int detourKm,
    String saving,
  ) {
    return 'Every $segmentKm km · $detourKm km detour · $saving';
  }

  @override
  String get criteriaSwapEndpoints => 'Swap start and destination';

  @override
  String get fillUpOdometerFromLastFillUp =>
      'Pre-filled from your last fill-up';

  @override
  String get fillUpStationLabel => 'Station';

  @override
  String get fillUpStationChange => 'Change';

  @override
  String get pickStationSectionLast => 'Last station';

  @override
  String get pickStationSectionFavorites => 'Favorites';

  @override
  String get pickStationSectionNearby => 'Nearby';

  @override
  String get pickStationNearbyEmpty =>
      'No recent search — search for stations on the Search tab and the nearest ones will appear here.';

  @override
  String pickStationLastFillUpAt(String date) {
    return 'Last fill-up: $date';
  }

  @override
  String get privacyTopicSubtitle =>
      'Your choices, data on this device, sync, export or delete';

  @override
  String get privacyDataLocationLocal => 'Your data stays on this device';

  @override
  String get privacyDataLocationSynced =>
      'Your data is also synced to TankSync';

  @override
  String get privacySyncLineEnabledAnonymous => 'Sync: on · anonymous account';

  @override
  String get privacySyncLineEnabledEmail => 'Sync: on · email account';

  @override
  String get privacySyncLineDisabled => 'Sync: off';

  @override
  String privacyStorageLine(String size) {
    return '$size stored on this device';
  }

  @override
  String get privacyTopicChoicesTitle => 'Your choices';

  @override
  String privacyChoicesStatus(int on, int total) {
    return '$on of $total enabled';
  }

  @override
  String privacyDeviceDataStatus(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$size · $_temp0';
  }

  @override
  String get privacyTopicExportDeleteTitle => 'Export or delete';

  @override
  String privacyExportDeleteStatus(int count) {
    return 'ZIP, JSON, CSV · error log ($count)';
  }

  @override
  String get privacyLearnMore => 'Learn more';

  @override
  String get tileProxyToggleShort =>
      'Tiles come via the developer\'s EU proxy, not straight from OpenStreetMap';

  @override
  String get remoteLogosToggleShort =>
      'Fetch brand logos from logo.clearbit.com instead of bundled placeholders';

  @override
  String get privacyCacheDetails => 'Cache details';

  @override
  String privacyCacheResponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cached responses',
      one: '1 cached response',
    );
    return '$_temp0';
  }

  @override
  String privacyClearCacheEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'Clear cache ($_temp0)';
  }

  @override
  String get privacySyncStatusLabel => 'Status';

  @override
  String get privacySyncModeCommunity =>
      'Sparkilo Community — the developer\'s EU server';

  @override
  String get privacySyncModeSelfHosted => 'Self-hosted — your own Supabase';

  @override
  String get privacySyncModeSharedGroup =>
      'Shared group — a database you joined';

  @override
  String get privacySyncAccountLabel => 'Account';

  @override
  String get privacySyncAccountAnonymous =>
      'Anonymous account, tied to this device';

  @override
  String privacySyncAccountEmail(String email) {
    return 'Email account: $email';
  }

  @override
  String get privacyCopyUserId => 'Copy user ID';

  @override
  String get privacyUserIdCopied => 'User ID copied';

  @override
  String get privacySyncDatabaseHost => 'Database host';

  @override
  String get privacyExportSectionTitle => 'Export';

  @override
  String get privacyExportMyData => 'Export my data';

  @override
  String get privacyExportSheetTitle => 'Choose a format';

  @override
  String get privacyExportZipTitle => 'ZIP archive';

  @override
  String get privacyExportZipSubtitle =>
      'Everything, attachments included — for a complete backup';

  @override
  String get privacyExportJsonTitle => 'JSON';

  @override
  String get privacyExportJsonSubtitle => 'Machine-readable — for another app';

  @override
  String get privacyExportCsvTitle => 'CSV';

  @override
  String get privacyExportCsvSubtitle => 'Spreadsheet — one table per category';

  @override
  String get privacyErrorLogTitle => 'Error log';

  @override
  String privacyErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get privacyErrorLogSave => 'Save';

  @override
  String get privacyErrorLogClear => 'Clear';

  @override
  String get privacyDangerZoneTitle => 'Danger zone';

  @override
  String get privacyDangerZoneBody =>
      'Permanently deletes everything the app stores on this device. With sync on, your data on the TankSync server is erased too.';

  @override
  String get privacyDeleteAllMyData => 'Delete all my data';

  @override
  String get tripRecordingScreenTitle => 'Trip in progress';

  @override
  String get recordingObd2ChipLive => 'Live';

  @override
  String recordingObd2ChipLiveRate(int rate) {
    return 'Live · $rate PID/s';
  }

  @override
  String get recordingObd2ChipReconnecting => 'Reconnecting…';

  @override
  String recordingObd2ChipReconnectingAttempt(int attempt) {
    return 'Reconnecting… (try $attempt)';
  }

  @override
  String get recordingObd2ChipGpsOnly => 'GPS only';

  @override
  String get recordingObd2ChipEngineOff => 'Engine off — waiting';

  @override
  String get recordingObd2ChipNoAdapter => 'No adapter';

  @override
  String get recordingObd2SheetTitle => 'OBD2 link';

  @override
  String get recordingObd2SheetLive =>
      'The adapter is delivering engine data, so consumption is measured from the car. Nothing to do — keep driving.';

  @override
  String get recordingObd2SheetReconnecting =>
      'The Bluetooth link is being re-established; meanwhile the recording continues on GPS. No action needed — a reset only helps if it stays like this for minutes.';

  @override
  String get recordingObd2SheetGpsOnly =>
      'The adapter has not answered for a while, so the app waits for it to reappear and records on GPS. Consumption is estimated until it is back.';

  @override
  String get recordingObd2SheetEngineOff =>
      'The engine is off, so there is nothing to read. The recording continues on GPS and picks the adapter up again as soon as the engine runs.';

  @override
  String get recordingObd2SheetNoAdapter =>
      'This trip is recorded without an OBD2 adapter. Speed and distance come from GPS; consumption is a physics estimate calibrated by your fill-ups.';

  @override
  String recordingGpsChipPrecise(int meters) {
    return 'Precise fix (±$meters m)';
  }

  @override
  String recordingGpsChipApprox(int meters) {
    return 'Approximate fix (±$meters m)';
  }

  @override
  String get recordingGpsChipNoFix => 'No fix';

  @override
  String get recordingGpsChipFixUnknownAccuracy => 'Fix (accuracy unknown)';

  @override
  String recordingGpsChipWithCoverage(String fix, int percent) {
    return '$fix · $percent %';
  }

  @override
  String get recordingGpsSheetTitle => 'GPS signal';

  @override
  String get recordingGpsSheetPrecise =>
      'The position is accurate to a few metres, so distance and the trace are reliable.';

  @override
  String get recordingGpsSheetApprox =>
      'The position is only accurate to tens of metres — typical in cities, tunnels or under trees. Distance may drift slightly until the fix improves.';

  @override
  String get recordingGpsSheetNoFix =>
      'No position has arrived recently. Check that location is allowed and the phone can see the sky; the recording resumes with the next fix.';

  @override
  String recordingGpsSheetCoverage(int percent) {
    return 'Coverage so far: $percent % of the seconds had a fix.';
  }

  @override
  String get recordingSheetClose => 'Got it';

  @override
  String get fuelSourceMeasured => 'Measured (ECU fuel flow)';

  @override
  String fuelSourceEstimatedCalibrated(int percent) {
    return 'Estimated · pump-calibrated ±$percent %';
  }

  @override
  String get fuelSourceEstimatedUncalibrated => 'Estimated · not calibrated';

  @override
  String get fuelSourceGpsEstimate => 'GPS estimate';

  @override
  String get recordingTileScore => 'Driving score';

  @override
  String searchSummaryAlongRoute(String km) {
    return 'Along the route · every $km km';
  }

  @override
  String get searchSummaryPricesJustNow => 'Prices from just now';

  @override
  String searchSummaryPricesMinutes(int minutes) {
    return 'Prices from $minutes min ago';
  }

  @override
  String searchSummaryPricesHours(int hours) {
    return 'Prices from $hours h ago';
  }

  @override
  String searchSummaryPricesDays(int days) {
    return 'Prices from $days d ago';
  }

  @override
  String get searchResultsFilterTooltip => 'Filters';

  @override
  String searchResultsFilterActiveSemantic(int count) {
    return 'Filters, $count active';
  }

  @override
  String get searchResultsMoreActionsTooltip => 'More actions';

  @override
  String get searchPriceArrowLegend =>
      '↓ and ↑ compare each price with the other stations in this list.';

  @override
  String get searchPriceArrowCheapTooltip =>
      'Among the lowest prices in this list';

  @override
  String get searchPriceArrowAverageTooltip => 'A mid-range price in this list';

  @override
  String get searchPriceArrowExpensiveTooltip =>
      'Among the highest prices in this list';

  @override
  String get searchRefreshTooltip => 'Update position and refresh prices';

  @override
  String priceHistoryFirstSeen(String date) {
    return 'First seen on $date — the history builds up with every visit';
  }

  @override
  String priceHistoryCurrentPriceLine(String price) {
    return 'Current price: $price';
  }

  @override
  String priceHistoryDeltaSince(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String priceHistoryUnchangedSince(String date) {
    return 'Unchanged since $date';
  }

  @override
  String get priceStatsMin => 'Min';

  @override
  String get priceStatsMax => 'Max';

  @override
  String get priceStatsAvg => 'Avg';

  @override
  String get amenitiesAndServices => 'Amenities & services';

  @override
  String amenitiesServicesShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get amenitiesServicesShowLess => 'Show less';

  @override
  String stationStatusWithFreshness(String status, String ago) {
    return '$status · updated $ago ago';
  }

  @override
  String pricesNotSoldHere(String fuels) {
    return 'Not sold here: $fuels';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return 'Recorded trips cover $pct % of this tank';
  }

  @override
  String tankReportRecordedTripsAvg(String value) {
    return 'Recorded trips: $value';
  }

  @override
  String tankReportRecordedTripsOverestimate(String pct) {
    return 'Your recorded trips overestimate consumption by $pct %';
  }

  @override
  String tankReportRecordedTripsUnderestimate(String pct) {
    return 'Your recorded trips underestimate consumption by $pct %';
  }

  @override
  String get trajetObd2DegradedSubtitle => 'No engine data — GPS estimate';

  @override
  String get vehicleTopicAdapterNone => 'None';

  @override
  String get vehicleTopicCalibrationTitle => 'Calibration';

  @override
  String get vehicleTopicAdvancedBadge => 'Advanced';

  @override
  String vehicleTopicCalibrationStatus(int coverage, String mode) {
    return 'Baseline $coverage % · $mode';
  }

  @override
  String vehicleTopicRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
      zero: 'No reminders',
    );
    return '$_temp0';
  }

  @override
  String get vehicleTopicAutoRecordOn => 'On';

  @override
  String get vehicleTopicAutoRecordOff => 'Off';

  @override
  String get vehicleTopicAutoRecordPairLinkText =>
      'Pair an adapter under “OBD2 adapter” to enable auto-recording';

  @override
  String vehicleBaselineCoverageSamples(int covered, int max) {
    return '$covered / $max samples';
  }

  @override
  String vehicleBaselineRawSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get calibrationModeRuleDescription =>
      'Sorts each driving sample into one situation using fixed speed and load thresholds.';

  @override
  String get calibrationModeFuzzyDescription =>
      'Splits each sample across neighbouring situations by how well it fits each one — smoother estimates around the boundaries.';

  @override
  String get pumpGainChipNotCalibrated => 'Not pump-calibrated yet';

  @override
  String pumpGainChipCalibrated(int fills, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      fills,
      locale: localeName,
      other: 'Pump-calibrated · $fills fill-ups · ±$percent %',
      one: 'Pump-calibrated · 1 fill-up · ±$percent %',
    );
    return '$_temp0';
  }

  @override
  String get pumpGainResetAction => 'Reset pump calibration';

  @override
  String get pumpGainResetConfirmTitle => 'Reset pump calibration?';

  @override
  String get pumpGainResetConfirmBody =>
      'This discards the fuel gain learned from your fill-ups. OBD2 consumption estimates fall back to the uncorrected figure until the next full-to-full tank window re-learns it.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'I may fill up with different fuel types';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Tracks which fuel is cheapest per kilometre';

  @override
  String get vinLabel => 'VIN (optional)';

  @override
  String get vinDecodeTooltip => 'Decode VIN';

  @override
  String get vinConfirmAction => 'Yes, auto-fill';

  @override
  String get vinModifyAction => 'Modify manually';

  @override
  String get vehicleReadVinFromCarButton => 'Read VIN from car';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Read VIN from the paired OBD2 adapter';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN not available (Mode 09 PID 02 unsupported on pre-2005 vehicles)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN read failed — please enter manually';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Pair an OBD2 adapter first to read VIN automatically';

  @override
  String get pickerButtonLabel => 'Pick from catalog';

  @override
  String get pickerSearchHint => 'Search make or model';

  @override
  String get pickerHelpText => 'Pre-fill from 50+ supported vehicles';

  @override
  String get pickerEmptyResults => 'No matches';

  @override
  String get pickerCancel => 'Cancel';

  @override
  String get pickerLoading => 'Loading catalog…';

  @override
  String get vinInfoTooltip => 'What is a VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'What is a VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'The Vehicle Identification Number is a 17-character code unique to your car. It\'s stamped on the chassis and printed on your vehicle registration document.';

  @override
  String get vinInfoSectionWhyTitle => 'Why we ask';

  @override
  String get vinInfoSectionWhyBody =>
      'Decoding the VIN auto-fills engine displacement, cylinder count, model year, primary fuel type, and gross weight — saving you from looking up technical specs manually. The OBD2 fuel-rate calculation uses these values to give you accurate consumption numbers.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacy';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Your VIN is stored only locally in the app\'s encrypted storage — it\'s never uploaded to Sparkilo servers. The NHTSA vPIC database is queried with the VIN but returns only anonymous technical specs; NHTSA does not link the VIN to any personal data. Without network, an offline lookup returns manufacturer and country only.';

  @override
  String get vinInfoSectionWhereTitle => 'Where to find it';

  @override
  String get vinInfoSectionWhereBody =>
      'Look through the windshield at the lower-left corner on the driver\'s side, check the driver-side door-frame sticker when the door is open, or read it off your vehicle registration document (card / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Got it';

  @override
  String get vinConfirmPrivacyNote =>
      'We looked up your VIN on NHTSA\'s free vehicle database — nothing sent to Sparkilo servers.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online decode';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Decode the VIN via NHTSA\'s free public service';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'When you pair an adapter, your vehicle\'s VIN is read locally to identify the car. Enabling this sends the 17-char VIN to NHTSA\'s free vPIC service to look up additional details (model, engine displacement, fuel type). The VIN is the only data sent — no other information leaves your device.';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detected from VIN: $summary. Apply?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Apply';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometers ahead, $fuelType $euros euros $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Home-screen widget';

  @override
  String get widgetHelpIntro =>
      'Add the SparKilo widget to your home screen to see fuel and charging prices at a glance.';

  @override
  String get widgetHelpAdd =>
      'Add it from your launcher\'s widget picker — long-press an empty area of the home screen, choose Widgets, and find SparKilo.';

  @override
  String get widgetHelpTap =>
      'Tap a station in the widget to open it in the app. Tap the refresh icon to update prices.';

  @override
  String get widgetHelpConfigure =>
      'On Android, long-press the widget and choose Reconfigure to change the profile, colour, and content.';

  @override
  String get widgetDefaultsThisProfileHint =>
      'Choices below apply to every installed widget showing this profile, on the next refresh.';

  @override
  String get widgetDefaultsColorLabel => 'Colour scheme';

  @override
  String get widgetDefaultsVariantLabel => 'Content variant';

  @override
  String get widgetColorSchemeSystem => 'Follow system';

  @override
  String get widgetColorSchemeLight => 'Light';

  @override
  String get widgetColorSchemeDark => 'Dark';

  @override
  String get widgetColorSchemeBlue => 'Blue';

  @override
  String get widgetColorSchemeGreen => 'Green';

  @override
  String get widgetColorSchemeOrange => 'Orange';

  @override
  String get widgetVariantDefault => 'Current price only';

  @override
  String get widgetVariantPredictive => 'Predictive: best time to fill';
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get appTitle => '⟦Šƥářķîłó ····⟧';

  @override
  String get search => '⟦Šéářçĥ ···⟧';

  @override
  String get favorites => '⟦Ƒáṽóřîŧéš ····⟧';

  @override
  String get map => '⟦Ṁáƥ ·⟧';

  @override
  String get profile => '⟦Ƥřóƒîłé ···⟧';

  @override
  String get settings => '⟦Šéŧŧîñǧš ····⟧';

  @override
  String get gpsLocation => '⟦ǦƤŠ Łóçáŧîóñ ·····⟧';

  @override
  String get zipCode => '⟦Ƥóšŧáł çóđé ·····⟧';

  @override
  String get zipCodeHint => '⟦é.ǧ. 10115 ·⟧';

  @override
  String get fuelType => '⟦Ƒúéł ŧýƥé ····⟧';

  @override
  String get searchRadius => '⟦Řáđîúš ···⟧';

  @override
  String get searchNearby => '⟦Ñéářƀý šŧáŧîóñš ······⟧';

  @override
  String get fabRunSearch => '⟦Řúñ šéářçĥ ····⟧';

  @override
  String get routeSearchingChip => '⟦Šéářçĥîñǧ ŧĥé řóúŧé… ········⟧';

  @override
  String get searchCriteriaTitle => '⟦Šéářçĥ çřîŧéřîá ······⟧';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '⟦Ŵîŧĥîñ $km ķɱ ····⟧';
  }

  @override
  String get noResults => '⟦Ñó šŧáŧîóñš ƒóúñđ. ·······⟧';

  @override
  String get startSearch => '⟦Šéářçĥ ŧó ƒîñđ ƒúéł šŧáŧîóñš. ···········⟧';

  @override
  String get open => '⟦Óƥéñ ··⟧';

  @override
  String get closed => '⟦Çłóšéđ ···⟧';

  @override
  String distance(String distance) {
    return '⟦$distance áŵáý ··⟧';
  }

  @override
  String get price => '⟦Ƥřîçé ··⟧';

  @override
  String get prices => '⟦Ƥřîçéš ···⟧';

  @override
  String get address => '⟦Áđđřéšš ···⟧';

  @override
  String get openingHours => '⟦Óƥéñîñǧ ĥóúřš ·····⟧';

  @override
  String get open24h => '⟦Óƥéñ 24 ĥóúřš ····⟧';

  @override
  String get navigate => '⟦Ñáṽîǧáŧé ····⟧';

  @override
  String get retry => '⟦Ŧřý áǧáîñ ····⟧';

  @override
  String get apiKeySetup => '⟦ÁƤÎ ķéý šéŧúƥ ·····⟧';

  @override
  String get apiKeyLabel => '⟦ÁƤÎ Ķéý ···⟧';

  @override
  String get register => '⟦Řéǧîšŧřáŧîóñ ·····⟧';

  @override
  String get continueButton => '⟦Çóñŧîñúé ····⟧';

  @override
  String get welcome => '⟦Šƥářķîłó ····⟧';

  @override
  String get welcomeSubtitle =>
      '⟦Ƒîñđ ŧĥé çĥéáƥéšŧ ƒúéł ñéář ýóú. ············⟧';

  @override
  String get profileName => '⟦Ƥřóƒîłé ñáɱé ·····⟧';

  @override
  String get preferredFuel => '⟦Ƥřéƒéřřéđ ƒúéł ······⟧';

  @override
  String get defaultRadius => '⟦Đéƒáúłŧ řáđîúš ······⟧';

  @override
  String get landingScreen => '⟦Šŧářŧ šçřééñ ·····⟧';

  @override
  String get homeZip => '⟦Ĥóɱé ƥóšŧáł çóđé ······⟧';

  @override
  String get newProfile => '⟦Ñéŵ ƥřóƒîłé ·····⟧';

  @override
  String get editProfile => '⟦Éđîŧ ƥřóƒîłé ·····⟧';

  @override
  String get save => '⟦Šáṽé ··⟧';

  @override
  String get cancel => '⟦Çáñçéł ···⟧';

  @override
  String get countryChangeTitle => '⟦Šŵîŧçĥ çóúñŧřý? ······⟧';

  @override
  String countryChangeBody(String country) {
    return '⟦Šŵîŧçĥîñǧ ŧó $country ŵîłł çĥáñǧé: ·········⟧';
  }

  @override
  String get countryChangeCurrency => '⟦Çúřřéñçý ····⟧';

  @override
  String get countryChangeDistance => '⟦Đîšŧáñçé ····⟧';

  @override
  String get countryChangeVolume => '⟦Ṽółúɱé ···⟧';

  @override
  String get countryChangePricePerUnit => '⟦Ƥřîçé ƒóřɱáŧ ·····⟧';

  @override
  String get countryChangeNote =>
      '⟦Éẋîšŧîñǧ ƒáṽóřîŧéš áñđ ƒîłł-úƥ łóǧš ářé ñóŧ řéŵřîŧŧéñ; óñłý ñéŵ éñŧřîéš úšé ŧĥé ñéŵ úñîŧš. ·································⟧';

  @override
  String get countryChangeConfirm => '⟦Šŵîŧçĥ ···⟧';

  @override
  String get delete => '⟦Đéłéŧé ···⟧';

  @override
  String get activate => '⟦Áçŧîṽáŧé ····⟧';

  @override
  String get configured => '⟦Çóñƒîǧúřéđ ·····⟧';

  @override
  String get notConfigured => '⟦Ñóŧ çóñƒîǧúřéđ ······⟧';

  @override
  String get about => '⟦Áƀóúŧ ··⟧';

  @override
  String get openSource => '⟦Óƥéñ Šóúřçé (ṀÎŦ Łîçéñšé) ·········⟧';

  @override
  String get sourceCode => '⟦Šóúřçé çóđé óñ ǦîŧĤúƀ ········⟧';

  @override
  String get noFavorites => '⟦Ñó ƒáṽóřîŧéš ýéŧ ······⟧';

  @override
  String get noFavoritesHint =>
      '⟦Ŧáƥ ŧĥé šŧář óñ á šŧáŧîóñ ŧó šáṽé îŧ áš á ƒáṽóřîŧé. ··················⟧';

  @override
  String get language => '⟦Łáñǧúáǧé ····⟧';

  @override
  String get country => '⟦Çóúñŧřý ···⟧';

  @override
  String get freeNoKey => '⟦Ƒřéé — ñó ķéý ñééđéđ ·······⟧';

  @override
  String get apiKeyRequired => '⟦ÁƤÎ ķéý řéɋúîřéđ ······⟧';

  @override
  String get dataTransparency => '⟦Đáŧá ŧřáñšƥářéñçý ·······⟧';

  @override
  String get clearCache => '⟦Çłéář çáçĥé ·····⟧';

  @override
  String stationsFound(int count) {
    return '⟦$count šŧáŧîóñš ƒóúñđ ······⟧';
  }

  @override
  String get storageUsage => '⟦Šŧóřáǧé úšáǧé óñ ŧĥîš đéṽîçé ···········⟧';

  @override
  String get settingsLabel => '⟦Šéŧŧîñǧš ····⟧';

  @override
  String get total => '⟦Ŧóŧáł ··⟧';

  @override
  String get cacheDescription =>
      '⟦Ŧĥé çáçĥé šŧóřéš ÁƤÎ řéšƥóñšéš ƒóř ƒášŧéř łóáđîñǧ áñđ óƒƒłîñé áççéšš. ··························⟧';

  @override
  String get cacheTtlGroupNetwork => '⟦Ñéŧŵóřķ ···⟧';

  @override
  String get cacheTtlGroupData => '⟦Đáŧá ··⟧';

  @override
  String get cacheTtlGroupGeocoding => '⟦Ǧéóçóđîñǧ ····⟧';

  @override
  String get stationSearch => '⟦Šŧáŧîóñ šéářçĥ ······⟧';

  @override
  String get stationDetails => '⟦Šŧáŧîóñ đéŧáîłš ······⟧';

  @override
  String get priceQuery => '⟦Ƥřîçé ɋúéřý ·····⟧';

  @override
  String get zipGeocoding => '⟦Ƥóšŧáł çóđé ǧéóçóđîñǧ ·········⟧';

  @override
  String minutes(int n) {
    return '⟦$n ɱîñúŧéš ···⟧';
  }

  @override
  String hours(int n) {
    return '⟦$n ĥóúřš ··⟧';
  }

  @override
  String get clearCacheTitle => '⟦Çłéář çáçĥé? ·····⟧';

  @override
  String get clearCacheBody =>
      '⟦Çáçĥéđ šéářçĥ řéšúłŧš áñđ ƥřîçéš ŵîłł ƀé đéłéŧéđ. Ƥřóƒîłéš, ƒáṽóřîŧéš áñđ šéŧŧîñǧš ářé ƥřéšéřṽéđ. ····································⟧';

  @override
  String get clearCacheButton => '⟦Çłéář çáçĥé ·····⟧';

  @override
  String get deleteAllButton => '⟦Đéłéŧé áłł ····⟧';

  @override
  String get cacheEmpty => '⟦Çáçĥé îš éɱƥŧý ·····⟧';

  @override
  String get apiKeyNote =>
      '⟦Ƒřéé řéǧîšŧřáŧîóñ. Đáŧá ƒřóɱ ǧóṽéřñɱéñŧ ƥřîçé ŧřáñšƥářéñçý áǧéñçîéš. ···························⟧';

  @override
  String get apiKeyFormatError =>
      '⟦Îñṽáłîđ ƒóřɱáŧ — éẋƥéçŧéđ ÚÚÎĐ (8-4-4-4-12) ···········⟧';

  @override
  String get reportThisIssue => '⟦Řéƥóřŧ ŧĥîš îššúé ·······⟧';

  @override
  String get reportAlreadySent =>
      '⟦Ýóú áłřéáđý řéƥóřŧéđ ŧĥîš îššúé. ············⟧';

  @override
  String get reportConsentTitle => '⟦Řéƥóřŧ ŧó ǦîŧĤúƀ? ······⟧';

  @override
  String get reportConsentBody =>
      '⟦Ŧĥîš ŵîłł óƥéñ á ƥúƀłîç ǦîŧĤúƀ îššúé ŵîŧĥ ŧĥé éřřóř đéŧáîłš ƀéłóŵ. Ñó ǦƤŠ çóóřđîñáŧéš, ÁƤÎ ķéýš, óř ƥéřšóñáł đáŧá ářé îñçłúđéđ. ··············································⟧';

  @override
  String get reportConsentConfirm => '⟦Óƥéñ ǦîŧĤúƀ ·····⟧';

  @override
  String get reportConsentCancel => '⟦Çáñçéł ···⟧';

  @override
  String get searchLocationPlaceholder =>
      '⟦Áđđřéšš, ƥóšŧáł çóđé óř çîŧý ··········⟧';

  @override
  String get configTankSyncConnected => '⟦Çóññéçŧéđ ····⟧';

  @override
  String get configTankSyncDisabled => '⟦Đîšáƀłéđ ····⟧';

  @override
  String get privacyPolicy => '⟦Ƥřîṽáçý Ƥółîçý ······⟧';

  @override
  String get fuels => '⟦Ƒúéłš ··⟧';

  @override
  String get zone => '⟦Žóñé ··⟧';

  @override
  String get highway => '⟦Ĥîǧĥŵáý ···⟧';

  @override
  String get localStation => '⟦Łóçáł šŧáŧîóñ ·····⟧';

  @override
  String get lastUpdate => '⟦Łášŧ úƥđáŧé ·····⟧';

  @override
  String get automate24h => '⟦24ĥ/24 — Áúŧóɱáŧé ····⟧';

  @override
  String get refreshPrices => '⟦Řéƒřéšĥ ƥřîçéš ······⟧';

  @override
  String get station => '⟦Šŧáŧîóñ ···⟧';

  @override
  String get locationDenied =>
      '⟦Łóçáŧîóñ ƥéřɱîššîóñ đéñîéđ. Ýóú çáñ šéářçĥ ƀý ƥóšŧáł çóđé. ······················⟧';

  @override
  String get demoModeBanner =>
      '⟦Đéɱó ɱóđé — šĥóŵîñǧ šáɱƥłé ƥřîçéš. ············⟧';

  @override
  String get demoModeBannerAction => '⟦Ǧéŧ łîṽé ƥřîçéš ······⟧';

  @override
  String get sortDistance => '⟦Đîšŧáñçé ····⟧';

  @override
  String get sortOpen24h => '⟦24ĥ⟧';

  @override
  String get sortRating => '⟦Řáŧîñǧ ···⟧';

  @override
  String get sortPriceDistance => '⟦Ƥřîçé/ķɱ ···⟧';

  @override
  String get cheap => '⟦çĥéáƥ ··⟧';

  @override
  String get expensive => '⟦éẋƥéñšîṽé ····⟧';

  @override
  String get reportPrice => '⟦Řéƥóřŧ ƥřîçé ·····⟧';

  @override
  String get whatsWrong => '⟦Ŵĥáŧ\'š ŵřóñǧ? ·····⟧';

  @override
  String get correctPrice => '⟦Çóřřéçŧ ƥřîçé (é.ǧ. 1.459) ······⟧';

  @override
  String get sendReport => '⟦Šéñđ řéƥóřŧ ·····⟧';

  @override
  String get reportSent => '⟦Řéƥóřŧ šéñŧ. Ŧĥáñķ ýóú! ········⟧';

  @override
  String get enterValidPrice => '⟦Ƥłéášé éñŧéř á ṽáłîđ ƥřîçé ··········⟧';

  @override
  String get cacheCleared => '⟦Çáçĥé çłéářéđ. ·····⟧';

  @override
  String get yourPosition => '⟦Ýóúř ƥóšîŧîóñ ·····⟧';

  @override
  String get positionUnknown => '⟦Ƥóšîŧîóñ úñķñóŵñ ·······⟧';

  @override
  String get distancesFromCenter =>
      '⟦Đîšŧáñçéš ƒřóɱ šéářçĥ çéñŧéř ···········⟧';

  @override
  String get autoUpdatePosition => '⟦Áúŧó-úƥđáŧé ƥóšîŧîóñ ········⟧';

  @override
  String get autoUpdateDescription =>
      '⟦Řéƒřéšĥ ǦƤŠ ƥóšîŧîóñ ƀéƒóřé éáçĥ šéářçĥ ···············⟧';

  @override
  String get location => '⟦Łóçáŧîóñ ····⟧';

  @override
  String get switchProfileTitle => '⟦Çóúñŧřý çĥáñǧéđ ······⟧';

  @override
  String switchProfilePrompt(String country, String profile) {
    return '⟦Ýóú ářé ñóŵ îñ $country. Šŵîŧçĥ ŧó ƥřóƒîłé \"$profile\"? ············⟧';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return '⟦Šŵîŧçĥéđ ŧó ƥřóƒîłé \"$profile\" ($country) ········⟧';
  }

  @override
  String get noProfileForCountryTitle =>
      '⟦Ñó ƥřóƒîłé ƒóř ŧĥîš çóúñŧřý ··········⟧';

  @override
  String noProfileForCountry(String country) {
    return '⟦Ýóú ářé îñ $country, ƀúŧ ñó ƥřóƒîłé îš çóñƒîǧúřéđ ƒóř îŧ. Çřéáŧé óñé îñ Šéŧŧîñǧš. ·························⟧';
  }

  @override
  String get autoSwitchProfile => '⟦Áúŧó-šŵîŧçĥ ƥřóƒîłé ········⟧';

  @override
  String get autoSwitchDescription =>
      '⟦Áúŧóɱáŧîçáłłý šŵîŧçĥ ƥřóƒîłé ŵĥéñ çřóššîñǧ ƀóřđéřš ····················⟧';

  @override
  String profileSwitchedTo(String profile) {
    return '⟦Šŵîŧçĥéđ ŧó $profile ·····⟧';
  }

  @override
  String profileCreatedNamed(String name) {
    return '⟦Ƥřóƒîłé $name çřéáŧéđ ······⟧';
  }

  @override
  String profileCountryTaken(String country) {
    return '⟦Á ƥřóƒîłé ƒóř $country áłřéáđý éẋîšŧš — éđîŧ îŧ îñšŧéáđ. ·················⟧';
  }

  @override
  String get switchProfile => '⟦Šŵîŧçĥ ···⟧';

  @override
  String get dismiss => '⟦Đîšɱîšš ···⟧';

  @override
  String get profileCountry => '⟦Çóúñŧřý ···⟧';

  @override
  String get profileLanguage => '⟦Łáñǧúáǧé ····⟧';

  @override
  String get settingsStorageDetail => '⟦ÁƤÎ ķéý, áçŧîṽé ƥřóƒîłé ·········⟧';

  @override
  String get allFuels => '⟦Áłł ·⟧';

  @override
  String get priceAlerts => '⟦Ƥřîçé Áłéřŧš ·····⟧';

  @override
  String get noPriceAlertsHint =>
      '⟦Çřéáŧé áñ áłéřŧ ƒřóɱ á šŧáŧîóñ\'š đéŧáîł ƥáǧé. ················⟧';

  @override
  String alertDeleted(String name) {
    return '⟦Áłéřŧ \"$name\" đéłéŧéđ ·····⟧';
  }

  @override
  String get createAlert => '⟦Çřéáŧé Ƥřîçé Áłéřŧ ·······⟧';

  @override
  String currentPrice(String price) {
    return '⟦Çúřřéñŧ ƥřîçé: $price ·····⟧';
  }

  @override
  String get targetPrice => '⟦Ŧářǧéŧ ƥřîçé (ÉÚŘ) ······⟧';

  @override
  String get enterPrice => '⟦Ƥłéášé éñŧéř á ƥřîçé ········⟧';

  @override
  String get invalidPrice => '⟦Îñṽáłîđ ƥřîçé ·····⟧';

  @override
  String get priceTooHigh => '⟦Ƥřîçé ŧóó ĥîǧĥ ·····⟧';

  @override
  String get create => '⟦Çřéáŧé ···⟧';

  @override
  String get alertCreated => '⟦Ƥřîçé áłéřŧ çřéáŧéđ ········⟧';

  @override
  String get wrongE5Price => '⟦Ŵřóñǧ Šúƥéř É5 ƥřîçé ·······⟧';

  @override
  String get wrongE10Price => '⟦Ŵřóñǧ Šúƥéř É10 ƥřîçé ·······⟧';

  @override
  String get wrongDieselPrice => '⟦Ŵřóñǧ Đîéšéł ƥřîçé ·······⟧';

  @override
  String get wrongStatusOpen => '⟦Šĥóŵñ áš óƥéñ, ƀúŧ çłóšéđ ·········⟧';

  @override
  String get wrongStatusClosed => '⟦Šĥóŵñ áš çłóšéđ, ƀúŧ óƥéñ ·········⟧';

  @override
  String get allStations => '⟦Áłł šŧáŧîóñš ·····⟧';

  @override
  String get bestStops => '⟦Ɓéšŧ šŧóƥš ····⟧';

  @override
  String get openInMaps => '⟦Óƥéñ îñ Ṁáƥš ·····⟧';

  @override
  String get noStationsAlongRoute =>
      '⟦Ñó šŧáŧîóñš ƒóúñđ áłóñǧ řóúŧé ···········⟧';

  @override
  String get evOperational => '⟦Óƥéřáŧîóñáł ·····⟧';

  @override
  String get evStatusUnknown => '⟦Šŧáŧúš úñķñóŵñ ······⟧';

  @override
  String evConnectors(int count) {
    return '⟦Çóññéçŧóřš ($count ƥóîñŧš) ·······⟧';
  }

  @override
  String get evNoConnectors => '⟦Ñó çóññéçŧóř đéŧáîłš áṽáîłáƀłé ············⟧';

  @override
  String get evUsageCost => '⟦Úšáǧé çóšŧ ····⟧';

  @override
  String get evPricingUnavailable =>
      '⟦Ƥřîçîñǧ ñóŧ áṽáîłáƀłé ƒřóɱ ƥřóṽîđéř ··············⟧';

  @override
  String get evPriceFree => '⟦Ƒřéé ··⟧';

  @override
  String get evPricePayAtLocation => '⟦Ƥáý áŧ łóçáŧîóñ ······⟧';

  @override
  String get evPriceMembership => '⟦Ṁéɱƀéřšĥîƥ řéɋúîřéđ ········⟧';

  @override
  String get evPriceIndicative => '⟦Îñđîçáŧîṽé ƥřîçé ·······⟧';

  @override
  String get evPriceDeclaredByOperator =>
      '⟦Îñđîçáŧîṽé ƥřîçé đéçłářéđ ƀý ŧĥé óƥéřáŧóř — ṽéřîƒý óñ šîŧé ······················⟧';

  @override
  String get evPriceFranceAttribution =>
      '⟦Ƥřîçîñǧ: Ɓášé ñáŧîóñáłé đéš ÎŘṼÉ — Łîçéñçé Óúṽéřŧé / đáŧá.ǧóúṽ.ƒř / ÓĐŘÉ ························⟧';

  @override
  String get evPriceBestEffortOcm =>
      '⟦Ɓéšŧ-éƒƒóřŧ ƥřîçîñǧ ƒřóɱ ÓƥéñÇĥářǧéṀáƥ — šƥářšé áñđ ɱáý ƀé îñçóɱƥłéŧé. ··························⟧';

  @override
  String get evLastUpdated => '⟦Łášŧ úƥđáŧéđ ·····⟧';

  @override
  String get evUnknown => '⟦Úñķñóŵñ ···⟧';

  @override
  String get evDataAttribution =>
      '⟦Đáŧá ƒřóɱ ÓƥéñÇĥářǧéṀáƥ (çóɱɱúñîŧý-šóúřçéđ) ·················⟧';

  @override
  String get evStatusDisclaimer =>
      '⟦Šŧáŧúš ɱáý ñóŧ řéƒłéçŧ řéáł-ŧîɱé áṽáîłáƀîłîŧý. Ŧáƥ řéƒřéšĥ ŧó ǧéŧ ŧĥé łáŧéšŧ đáŧá. ······························⟧';

  @override
  String get evNavigateToStation => '⟦Ñáṽîǧáŧé ŧó šŧáŧîóñ ········⟧';

  @override
  String get evRefreshStatus => '⟦Řéƒřéšĥ šŧáŧúš ······⟧';

  @override
  String get evStatusUpdated => '⟦Šŧáŧúš úƥđáŧéđ ······⟧';

  @override
  String get evStationNotFound =>
      '⟦Çóúłđ ñóŧ řéƒřéšĥ — šŧáŧîóñ ñóŧ ƒóúñđ ñéářƀý ················⟧';

  @override
  String get addedToFavorites => '⟦Áđđéđ ŧó ƒáṽóřîŧéš ·······⟧';

  @override
  String get removedFromFavorites => '⟦Řéɱóṽéđ ƒřóɱ ƒáṽóřîŧéš ·········⟧';

  @override
  String get addFavorite => '⟦Áđđ ŧó ƒáṽóřîŧéš ······⟧';

  @override
  String get removeFavorite => '⟦Řéɱóṽé ƒřóɱ ƒáṽóřîŧéš ·········⟧';

  @override
  String get currentLocation => '⟦Çúřřéñŧ łóçáŧîóñ ·······⟧';

  @override
  String get gpsError => '⟦ǦƤŠ éřřóř ····⟧';

  @override
  String get couldNotResolve =>
      '⟦Çóúłđ ñóŧ řéšółṽé šŧářŧ óř đéšŧîñáŧîóñ ···············⟧';

  @override
  String get start => '⟦Šŧářŧ ··⟧';

  @override
  String get destination => '⟦Đéšŧîñáŧîóñ ·····⟧';

  @override
  String get cityAddressOrGps => '⟦Çîŧý, áđđřéšš, óř ǦƤŠ ·······⟧';

  @override
  String get cityOrAddress => '⟦Çîŧý óř áđđřéšš ······⟧';

  @override
  String get useGps => '⟦Úšé ǦƤŠ ···⟧';

  @override
  String get stop => '⟦Šŧóƥ ··⟧';

  @override
  String get addStop => '⟦Áđđ šŧóƥ ···⟧';

  @override
  String get searchAlongRoute => '⟦Šéářçĥ áłóñǧ řóúŧé ·······⟧';

  @override
  String get cheapest => '⟦Çĥéáƥéšŧ ····⟧';

  @override
  String nStations(int count) {
    return '⟦$count šŧáŧîóñš ····⟧';
  }

  @override
  String nBest(int count) {
    return '⟦$count ƀéšŧ ··⟧';
  }

  @override
  String get fuelPricesTankerkoenig =>
      '⟦Ƒúéł ƥřîçéš (Ŧáñķéřķóéñîǧ) ··········⟧';

  @override
  String get requiredForFuelSearch =>
      '⟦Řéɋúîřéđ ƒóř ƒúéł ƥřîçé šéářçĥ îñ Ǧéřɱáñý ················⟧';

  @override
  String get evChargingOpenChargeMap =>
      '⟦ÉṼ Çĥářǧîñǧ (ÓƥéñÇĥářǧéṀáƥ) ··········⟧';

  @override
  String get customKey => '⟦Çúšŧóɱ ķéý ····⟧';

  @override
  String get appDefaultKey => '⟦Áƥƥ đéƒáúłŧ ķéý ······⟧';

  @override
  String get optionalOverrideKey =>
      '⟦Óƥŧîóñáł: óṽéřřîđé ŧĥé ƀúîłŧ-îñ áƥƥ ķéý ŵîŧĥ ýóúř óŵñ ···················⟧';

  @override
  String get edit => '⟦Éđîŧ ··⟧';

  @override
  String get fuelPricesApiKey => '⟦Ƒúéł ƥřîçéš ÁƤÎ Ķéý ·······⟧';

  @override
  String get evChargingApiKey => '⟦ÉṼ Çĥářǧîñǧ ÁƤÎ Ķéý ·······⟧';

  @override
  String get openChargeMapApiKey => '⟦ÓƥéñÇĥářǧéṀáƥ ÁƤÎ Ķéý ·········⟧';

  @override
  String get routePlanningSection => '⟦Řóúŧé ƥłáññîñǧ ······⟧';

  @override
  String get routeMinSaving => '⟦Ṁîñîɱúɱ šáṽîñǧ ······⟧';

  @override
  String get routeMinSavingOff => '⟦Óƒƒ ·⟧';

  @override
  String get routeMinSavingOffCaption =>
      '⟦Šĥóŵîñǧ éṽéřý šŧáŧîóñ ƒóúñđ áłóñǧ ŧĥé řóúŧé ·················⟧';

  @override
  String routeMinSavingCaption(String amount) {
    return '⟦Óñłý šŧáŧîóñš ŵîŧĥîñ $amount óƒ ŧĥé řóúŧé\'š çĥéáƥéšŧ ·················⟧';
  }

  @override
  String get routeDetourBudget => '⟦Ṁáẋîɱúɱ đéŧóúř ······⟧';

  @override
  String routeDetourBudgetCaption(int km) {
    return '⟦Šúřƒáçé šŧáŧîóñš úƥ ŧó $km ķɱ óƒƒ ýóúř đîřéçŧ řóúŧé ··················⟧';
  }

  @override
  String get routeSegment => '⟦Řóúŧé šéǧɱéñŧ ·····⟧';

  @override
  String showCheapestEveryNKm(int km) {
    return '⟦Šĥóŵ çĥéáƥéšŧ šŧáŧîóñ éṽéřý $km ķɱ áłóñǧ řóúŧé ················⟧';
  }

  @override
  String get avoidHighways => '⟦Áṽóîđ ĥîǧĥŵáýš ······⟧';

  @override
  String get avoidHighwaysDesc =>
      '⟦Řóúŧé çáłçúłáŧîóñ áṽóîđš ŧółł řóáđš áñđ ĥîǧĥŵáýš ···················⟧';

  @override
  String get noStationsAlongThisRoute =>
      '⟦Ñó šŧáŧîóñš ƒóúñđ áłóñǧ ŧĥîš řóúŧé. ·············⟧';

  @override
  String get fuelCostCalculator => '⟦Ƒúéł Çóšŧ Çáłçúłáŧóř ········⟧';

  @override
  String get distanceKm => '⟦Đîšŧáñçé (ķɱ) ·····⟧';

  @override
  String get tripCost => '⟦Ŧřîƥ Çóšŧ ····⟧';

  @override
  String get fuelNeeded => '⟦Ƒúéł ñééđéđ ·····⟧';

  @override
  String get totalCost => '⟦Ŧóŧáł çóšŧ ····⟧';

  @override
  String calculatorDistanceLabel(String unit) {
    return '⟦Đîšŧáñçé ($unit) ····⟧';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return '⟦Çóñšúɱƥŧîóñ ($unit) ·····⟧';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return '⟦Ƒúéł ƥřîçé ($unit) ····⟧';
  }

  @override
  String get calculatorUseMine => '⟦Úšé ·⟧';

  @override
  String get calculatorApplied => '⟦Áƥƥłîéđ ···⟧';

  @override
  String get tripDetails => '⟦Ŧřîƥ đéŧáîłš ·····⟧';

  @override
  String get calculatorRoundTrip => '⟦Řóúñđ ŧřîƥ ····⟧';

  @override
  String get roundTripTotal => '⟦Řóúñđ ŧřîƥ ····⟧';

  @override
  String get costPerDistance => '⟦Çóšŧ ƥéř ķɱ ····⟧';

  @override
  String get costPerMonth => '⟦Çóšŧ ƥéř ɱóñŧĥ ·····⟧';

  @override
  String get calculatorEstimateMonthly => '⟦Éšŧîɱáŧé ɱóñŧĥłý çóšŧ ·········⟧';

  @override
  String get calculatorTripsPerMonth => '⟦Ŧřîƥš ƥéř ɱóñŧĥ ······⟧';

  @override
  String get calculatorTripsPerMonthHint => '⟦é.ǧ. 20 ·⟧';

  @override
  String get calculatorReset => '⟦Řéšéŧ ··⟧';

  @override
  String get calculatorResultPlaceholder =>
      '⟦Ƒîłł îñ đîšŧáñçé, çóñšúɱƥŧîóñ áñđ ƥřîçé ŧó šéé ýóúř ŧřîƥ çóšŧ ·······················⟧';

  @override
  String get priceHistory => '⟦Ƥřîçé Ĥîšŧóřý ·····⟧';

  @override
  String get favoritesDataCache => '⟦Ƒáṽóřîŧéš đáŧá ······⟧';

  @override
  String get citySearchCache => '⟦Çîŧý šéářçĥ ·····⟧';

  @override
  String get noPriceHistory => '⟦Ñó ƥřîçé ĥîšŧóřý ýéŧ ········⟧';

  @override
  String get noStatistics => '⟦Ñó šŧáŧîšŧîçš áṽáîłáƀłé ·········⟧';

  @override
  String get showAllFuelTypes => '⟦Šĥóŵ áłł ƒúéł ŧýƥéš ·······⟧';

  @override
  String get connected => '⟦Çóññéçŧéđ ····⟧';

  @override
  String get disconnectTankSync => '⟦Đîšçóññéçŧ ŦáñķŠýñç ········⟧';

  @override
  String get viewMyData => '⟦Ṽîéŵ ɱý đáŧá ·····⟧';

  @override
  String get deleteAllServerData => '⟦Đéłéŧé áłł šéřṽéř đáŧá ·········⟧';

  @override
  String get deleteServerDataConfirm => '⟦Đéłéŧé áłł šéřṽéř đáŧá? ·········⟧';

  @override
  String get deleteEverything => '⟦Đéłéŧé éṽéřýŧĥîñǧ ·······⟧';

  @override
  String get allDataDeleted => '⟦Áłł šéřṽéř đáŧá đéłéŧéđ ·········⟧';

  @override
  String get forgetAllSyncedTripsButton =>
      '⟦Ƒóřǧéŧ áłł šýñçéđ ŧřîƥš ·········⟧';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      '⟦Ƒóřǧéŧ áłł šýñçéđ ŧřîƥš? ·········⟧';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      '⟦Éṽéřý ŧřîƥ šúɱɱářý áñđ đéŧáîł ƀłóƀ ŵîłł ƀé řéɱóṽéđ ƒřóɱ ŧĥé šéřṽéř. Ýóúř łóçáł ŧřîƥ ĥîšŧóřý óñ ŧĥîš đéṽîçé ŵóñ\'ŧ ƀé áƒƒéçŧéđ.\n\nŦĥîš áçŧîóñ çáññóŧ ƀé úñđóñé. ························································⟧';

  @override
  String get forgetAllSyncedTripsConfirmAction => '⟦Ƒóřǧéŧ áłł ····⟧';

  @override
  String get forgetAllSyncedTripsSuccess =>
      '⟦Áłł šýñçéđ ŧřîƥš řéɱóṽéđ ƒřóɱ šéřṽéř ··············⟧';

  @override
  String get disconnect => '⟦Đîšçóññéçŧ ·····⟧';

  @override
  String get myServerData => '⟦Ṁý šéřṽéř đáŧá ·····⟧';

  @override
  String get anonymousUuid => '⟦Áñóñýɱóúš ÚÚÎĐ ······⟧';

  @override
  String get server => '⟦Šéřṽéř ···⟧';

  @override
  String get syncedData => '⟦Šýñçéđ đáŧá ·····⟧';

  @override
  String get pushTokens => '⟦Ƥúšĥ ŧóķéñš ·····⟧';

  @override
  String get priceReports => '⟦Ƥřîçé řéƥóřŧš ·····⟧';

  @override
  String get syncedTrips => '⟦Ŧřîƥš ··⟧';

  @override
  String get totalItems => '⟦Ŧóŧáł îŧéɱš ·····⟧';

  @override
  String get estimatedSize => '⟦Éšŧîɱáŧéđ šîžé ······⟧';

  @override
  String get viewRawJson => '⟦Ṽîéŵ řáŵ đáŧá áš ĴŠÓÑ ········⟧';

  @override
  String get exportJson => '⟦Éẋƥóřŧ áš ĴŠÓÑ (çłîƥƀóářđ) ·········⟧';

  @override
  String get jsonCopied => '⟦ĴŠÓÑ çóƥîéđ ŧó çłîƥƀóářđ ·········⟧';

  @override
  String get rawDataJson => '⟦Řáŵ đáŧá (ĴŠÓÑ) ·····⟧';

  @override
  String get close => '⟦Çłóšé ··⟧';

  @override
  String get account => '⟦Áççóúñŧ ···⟧';

  @override
  String get continueAsGuest => '⟦Çóñŧîñúé áš ǧúéšŧ ·······⟧';

  @override
  String get createAccount => '⟦Çřéáŧé áççóúñŧ ······⟧';

  @override
  String get signIn => '⟦Šîǧñ îñ ···⟧';

  @override
  String get savedRoutes => '⟦Šáṽéđ Řóúŧéš ·····⟧';

  @override
  String get noSavedRoutes => '⟦Ñó šáṽéđ řóúŧéš ······⟧';

  @override
  String get noSavedRoutesHint =>
      '⟦Šéářçĥ áłóñǧ á řóúŧé áñđ šáṽé îŧ ƒóř ɋúîçķ áççéšš łáŧéř. ····················⟧';

  @override
  String get saveRoute => '⟦Šáṽé řóúŧé ····⟧';

  @override
  String get routeName => '⟦Řóúŧé ñáɱé ····⟧';

  @override
  String itineraryDeleted(String name) {
    return '⟦$name đéłéŧéđ ···⟧';
  }

  @override
  String loadingRoute(String name) {
    return '⟦Łóáđîñǧ řóúŧé: $name ·····⟧';
  }

  @override
  String get refreshFailed =>
      '⟦Řéƒřéšĥ ƒáîłéđ. Ƥłéášé ŧřý áǧáîñ. ············⟧';

  @override
  String get deleteProfileTitle => '⟦Đéłéŧé ƥřóƒîłé? ······⟧';

  @override
  String get deleteProfileBody =>
      '⟦Ŧĥîš ƥřóƒîłé áñđ îŧš šéŧŧîñǧš ŵîłł ƀé ƥéřɱáñéñŧłý đéłéŧéđ. Ŧĥîš çáññóŧ ƀé úñđóñé. ······························⟧';

  @override
  String get deleteProfileConfirm => '⟦Đéłéŧé ƥřóƒîłé ······⟧';

  @override
  String get errorNetwork =>
      '⟦Ñéŧŵóřķ éřřóř. Çĥéçķ ýóúř çóññéçŧîóñ. ··············⟧';

  @override
  String get errorServer =>
      '⟦Šéřṽéř éřřóř. Ƥłéášé ŧřý áǧáîñ łáŧéř. ··············⟧';

  @override
  String get errorTimeout =>
      '⟦Çóññéçŧîóñ ŧîɱéđ óúŧ. Ƥłéášé ŧřý áǧáîñ. ··············⟧';

  @override
  String get errorNoConnection => '⟦Ñó îñŧéřñéŧ çóññéçŧîóñ. ·········⟧';

  @override
  String get errorApiKey =>
      '⟦Îñṽáłîđ ÁƤÎ ķéý. Çĥéçķ ýóúř šéŧŧîñǧš. ··············⟧';

  @override
  String get errorLocation =>
      '⟦Çóúłđ ñóŧ đéŧéřɱîñé ýóúř łóçáŧîóñ. ·············⟧';

  @override
  String get errorNoApiKey =>
      '⟦Ñó ÁƤÎ ķéý çóñƒîǧúřéđ. Ǧó ŧó Šéŧŧîñǧš ŧó áđđ óñé. ·················⟧';

  @override
  String get errorAllServicesFailed =>
      '⟦Çóúłđ ñóŧ łóáđ đáŧá. Çĥéçķ ýóúř çóññéçŧîóñ áñđ ŧřý áǧáîñ. ·····················⟧';

  @override
  String get errorCache =>
      '⟦Łóçáł đáŧá éřřóř. Ŧřý çłéářîñǧ ŧĥé çáçĥé. ···············⟧';

  @override
  String get errorCancelled => '⟦Řéɋúéšŧ ŵáš çáñçéłłéđ. ·········⟧';

  @override
  String get errorUnknown => '⟦Áñ úñéẋƥéçŧéđ éřřóř óççúřřéđ. ···········⟧';

  @override
  String get onboardingWelcomeHint =>
      '⟦Šéŧ úƥ ŧĥé áƥƥ îñ á ƒéŵ ɋúîçķ šŧéƥš. ············⟧';

  @override
  String get onboardingApiKeyDescription =>
      '⟦Řéǧîšŧéř ƒóř á ƒřéé ÁƤÎ ķéý, óř šķîƥ ŧó éẋƥłóřé ŧĥé áƥƥ ŵîŧĥ đéɱó đáŧá. ·························⟧';

  @override
  String get onboardingComplete => '⟦Áłł šéŧ! ···⟧';

  @override
  String get onboardingCompleteHint =>
      '⟦Ýóú çáñ çĥáñǧé ŧĥéšé šéŧŧîñǧš áñýŧîɱé îñ ýóúř ƥřóƒîłé. ····················⟧';

  @override
  String get onboardingBack => '⟦Ɓáçķ ··⟧';

  @override
  String get onboardingNext => '⟦Ñéẋŧ ··⟧';

  @override
  String get onboardingSkip => '⟦Šķîƥ ··⟧';

  @override
  String get onboardingFinish => '⟦Ǧéŧ šŧářŧéđ ·····⟧';

  @override
  String get switchToAllPricesView => '⟦Šŵîŧçĥ ŧó áłł-ƥřîçéš ṽîéŵ ·········⟧';

  @override
  String get switchToCompactView => '⟦Šŵîŧçĥ ŧó çóɱƥáçŧ ṽîéŵ ·········⟧';

  @override
  String get unavailable => '⟦Ñ/Á ·⟧';

  @override
  String get outOfStock => '⟦Óúŧ óƒ šŧóçķ ·····⟧';

  @override
  String get gdprTitle => '⟦Ýóúř Ƥřîṽáçý ·····⟧';

  @override
  String get gdprSubtitle =>
      '⟦Ŧĥîš áƥƥ řéšƥéçŧš ýóúř ƥřîṽáçý. Çĥóóšé ŵĥîçĥ đáŧá ýóú ŵáñŧ ŧó šĥářé. Ýóú çáñ çĥáñǧé ŧĥéšé šéŧŧîñǧš áñýŧîɱé. ·······································⟧';

  @override
  String get gdprLocationTitle => '⟦Łóçáŧîóñ Áççéšš ······⟧';

  @override
  String get gdprLocationDescription =>
      '⟦Ýóúř çóóřđîñáŧéš ářé šéñŧ ŧó ŧĥé ƒúéł ƥřîçé ÁƤÎ ŧó ƒîñđ ñéářƀý šŧáŧîóñš. Łóçáŧîóñ đáŧá îš ñéṽéř šŧóřéđ óñ á šéřṽéř áñđ îš ñóŧ úšéđ ƒóř ŧřáçķîñǧ. ····················································⟧';

  @override
  String get gdprLocationShort =>
      '⟦Ƒîñđ ñéářƀý ƒúéł šŧáŧîóñš úšîñǧ ýóúř łóçáŧîóñ ··················⟧';

  @override
  String get gdprErrorReportingTitle => '⟦Éřřóř Řéƥóřŧîñǧ ······⟧';

  @override
  String get gdprErrorReportingDescription =>
      '⟦Áñóñýɱóúš çřášĥ řéƥóřŧš ĥéłƥ îɱƥřóṽé ŧĥé áƥƥ. Ñó ƥéřšóñáł đáŧá îš îñçłúđéđ. Řéƥóřŧš ářé šéñŧ ṽîá Šéñŧřý óñłý ŵĥéñ çóñƒîǧúřéđ. ··············································⟧';

  @override
  String get gdprErrorReportingShort =>
      '⟦Šéñđ áñóñýɱóúš çřášĥ řéƥóřŧš ŧó îɱƥřóṽé ŧĥé áƥƥ ··················⟧';

  @override
  String get gdprCloudSyncTitle => '⟦Çłóúđ Šýñç ····⟧';

  @override
  String get gdprCloudSyncDescription =>
      '⟦Šýñç ƒáṽóřîŧéš, řáŧîñǧš, áłéřŧš, îǧñóřéđ šŧáŧîóñš, šáṽéđ řóúŧéš, ṽéĥîçłéš, ƒúéł łóǧš áñđ ŧřîƥš áçřóšš đéṽîçéš ṽîá ŦáñķŠýñç. Úšéš áñóñýɱóúš áúŧĥéñŧîçáŧîóñ. Ýóúř đáŧá îš éñçřýƥŧéđ îñ ŧřáñšîŧ. ······································································⟧';

  @override
  String get gdprCloudSyncShort =>
      '⟦Šýñç ƒáṽóřîŧéš áñđ áłéřŧš áçřóšš đéṽîçéš ················⟧';

  @override
  String get gdprLegalBasis =>
      '⟦Łéǧáł ƀášîš: Ářŧ. 6(1)(á) ǦĐƤŘ (Çóñšéñŧ). Ýóú çáñ ŵîŧĥđřáŵ çóñšéñŧ áñýŧîɱé îñ Šéŧŧîñǧš. ····························⟧';

  @override
  String get gdprContinueAll => '⟦Çóñŧîñúé ŵîŧĥ áłł ·······⟧';

  @override
  String get gdprContinueSelected => '⟦Çóñŧîñúé ŵîŧĥ šéłéçŧéđ ·········⟧';

  @override
  String get gdprSettingsHint =>
      '⟦Ýóú çáñ çĥáñǧé ýóúř ƥřîṽáçý çĥóîçéš áŧ áñý ŧîɱé. ··················⟧';

  @override
  String get routeSaved => '⟦Řóúŧé šáṽéđ! ·····⟧';

  @override
  String get routeSaveFailed => '⟦Ƒáîłéđ ŧó šáṽé řóúŧé ········⟧';

  @override
  String get sqlCopied => '⟦ŠɊŁ çóƥîéđ ŧó çłîƥƀóářđ ·········⟧';

  @override
  String get connectionDataCopied => '⟦Çóññéçŧîóñ đáŧá çóƥîéđ ·········⟧';

  @override
  String get accountDeleted =>
      '⟦Áççóúñŧ đéłéŧéđ. Łóçáł đáŧá ƥřéšéřṽéđ. ··············⟧';

  @override
  String get switchedToAnonymous =>
      '⟦Šŵîŧçĥéđ ŧó áñóñýɱóúš šéššîóñ ············⟧';

  @override
  String failedToSwitch(String error) {
    return '⟦Ƒáîłéđ ŧó šŵîŧçĥ: $error ······⟧';
  }

  @override
  String get connectedAsGuest => '⟦Çóññéçŧéđ áš ǧúéšŧ ·······⟧';

  @override
  String get accountCreated => '⟦Áççóúñŧ çřéáŧéđ! ······⟧';

  @override
  String get signedIn => '⟦Šîǧñéđ îñ! ····⟧';

  @override
  String stationHidden(String name) {
    return '⟦$name ĥîđđéñ ···⟧';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '⟦$name řéɱóṽéđ ƒřóɱ ƒáṽóřîŧéš ·········⟧';
  }

  @override
  String invalidApiKey(String error) {
    return '⟦Îñṽáłîđ ÁƤÎ ķéý: $error ······⟧';
  }

  @override
  String get invalidQrCode => '⟦Îñṽáłîđ ɊŘ çóđé ƒóřɱáŧ ·········⟧';

  @override
  String get invalidQrCodeTankSync =>
      '⟦Îñṽáłîđ ɊŘ çóđé — éẋƥéçŧéđ ŦáñķŠýñç ƒóřɱáŧ ················⟧';

  @override
  String get tankSyncConnected => '⟦ŦáñķŠýñç çóññéçŧéđ! ········⟧';

  @override
  String get syncCompleted => '⟦Šýñç çóɱƥłéŧéđ — đáŧá řéƒřéšĥéđ ············⟧';

  @override
  String get deviceCodeCopied => '⟦Đéṽîçé çóđé çóƥîéđ ·······⟧';

  @override
  String get undo => '⟦Úñđó ··⟧';

  @override
  String invalidPostalCode(String length, String label) {
    return '⟦Ƥłéášé éñŧéř á ṽáłîđ $length-đîǧîŧ $label ··········⟧';
  }

  @override
  String get freshnessAgo => '⟦áǧó ·⟧';

  @override
  String get freshnessStale => '⟦Šŧáłé ··⟧';

  @override
  String freshnessBadgeSemantics(String age) {
    return '⟦Đáŧá ƒřéšĥñéšš: $age ······⟧';
  }

  @override
  String brandLogoLabel(String brand) {
    return '⟦$brand łóǧó ··⟧';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rate $count stars',
      one: 'Rate 1 star',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get passwordStrengthWeak => '⟦Ŵéáķ ··⟧';

  @override
  String get passwordStrengthFair => '⟦Ƒáîř ··⟧';

  @override
  String get passwordStrengthStrong => '⟦Šŧřóñǧ ···⟧';

  @override
  String get passwordReqMinLength => '⟦Áŧ łéášŧ 8 çĥářáçŧéřš ········⟧';

  @override
  String get passwordReqUppercase => '⟦Áŧ łéášŧ 1 úƥƥéřçášé łéŧŧéř ··········⟧';

  @override
  String get passwordReqLowercase => '⟦Áŧ łéášŧ 1 łóŵéřçášé łéŧŧéř ··········⟧';

  @override
  String get passwordReqDigit => '⟦Áŧ łéášŧ 1 ñúɱƀéř ······⟧';

  @override
  String get passwordReqSpecial => '⟦Áŧ łéášŧ 1 šƥéçîáł çĥářáçŧéř ··········⟧';

  @override
  String get passwordTooWeak =>
      '⟦Ƥáššŵóřđ đóéš ñóŧ ɱééŧ áłł řéɋúîřéɱéñŧš ···············⟧';

  @override
  String get brandFilterAll => '⟦Áłł ·⟧';

  @override
  String get brandFilterNoHighway => '⟦Ñó ĥîǧĥŵáý ····⟧';

  @override
  String get swipeTutorialMessage =>
      '⟦Šŵîƥé řîǧĥŧ ŧó ñáṽîǧáŧé, šŵîƥé łéƒŧ ŧó řéɱóṽé ·················⟧';

  @override
  String get swipeTutorialDismiss => '⟦Ǧóŧ îŧ ··⟧';

  @override
  String get alertStatsActive => '⟦Áçŧîṽé ···⟧';

  @override
  String get alertStatsToday => '⟦Ŧóđáý ··⟧';

  @override
  String get alertStatsThisWeek => '⟦Ŧĥîš ŵééķ ····⟧';

  @override
  String get privacyLocalData => '⟦Đáŧá óñ ŧĥîš đéṽîçé ·······⟧';

  @override
  String get privacyIgnoredStations => '⟦Îǧñóřéđ šŧáŧîóñš ·······⟧';

  @override
  String get privacyRatings => '⟦Šŧáŧîóñ řáŧîñǧš ······⟧';

  @override
  String get privacyPriceHistory => '⟦Ƥřîçé ĥîšŧóřý šŧáŧîóñš ·········⟧';

  @override
  String get privacyProfiles => '⟦Šéářçĥ ƥřóƒîłéš ······⟧';

  @override
  String get privacyItineraries => '⟦Šáṽéđ řóúŧéš ·····⟧';

  @override
  String get privacySyncMode => '⟦Šýñç ɱóđé ····⟧';

  @override
  String get privacySyncUserId => '⟦Úšéř ÎĐ ···⟧';

  @override
  String get privacySyncDescription =>
      '⟦Ŵĥéñ šýñç îš éñáƀłéđ, ƒáṽóřîŧéš, řáŧîñǧš, áłéřŧš, îǧñóřéđ šŧáŧîóñš, šáṽéđ řóúŧéš, ṽéĥîçłéš, ƒúéł łóǧš áñđ ŧřîƥš ářé áłšó šŧóřéđ óñ ŧĥé ŦáñķŠýñç šéřṽéř. ······················································⟧';

  @override
  String get privacyExportSuccess => '⟦Đáŧá éẋƥóřŧéđ ŧó çłîƥƀóářđ ··········⟧';

  @override
  String get privacyExportCsvSuccess =>
      '⟦ÇŠṼ đáŧá éẋƥóřŧéđ ŧó çłîƥƀóářđ ············⟧';

  @override
  String get savedToDownloadsFolder =>
      '⟦Šáṽéđ ŧó ýóúř Đóŵñłóáđš ƒółđéř ············⟧';

  @override
  String get privacyErrorLogCleared => '⟦Éřřóř łóǧ çłéářéđ ·······⟧';

  @override
  String get privacyDeleteTitle => '⟦Đéłéŧé áłł đáŧá? ······⟧';

  @override
  String get privacyDeleteBody =>
      '⟦Ŧĥîš ŵîłł ƥéřɱáñéñŧłý đéłéŧé:\n\n- Áłł ƒáṽóřîŧéš áñđ šŧáŧîóñ đáŧá\n- Áłł šéářçĥ ƥřóƒîłéš\n- Áłł ƥřîçé áłéřŧš\n- Áłł ƥřîçé ĥîšŧóřý\n- Áłł çáçĥéđ đáŧá\n- Ýóúř ÁƤÎ ķéý\n- Áłł áƥƥ šéŧŧîñǧš\n\nŦĥé áƥƥ ŵîłł řéšéŧ ŧó îŧš îñîŧîáł šŧáŧé. Ŧĥîš áçŧîóñ çáññóŧ ƀé úñđóñé. ······················································································⟧';

  @override
  String get privacyDeleteConfirm => '⟦Đéłéŧé éṽéřýŧĥîñǧ ·······⟧';

  @override
  String get yes => '⟦Ýéš ·⟧';

  @override
  String get no => '⟦Ñó ·⟧';

  @override
  String get amenities => '⟦Áɱéñîŧîéš ····⟧';

  @override
  String get amenityShop => '⟦Šĥóƥ ··⟧';

  @override
  String get amenityCarWash => '⟦Çář Ŵášĥ ···⟧';

  @override
  String get amenityAirPump => '⟦Áîř ·⟧';

  @override
  String get amenityToilet => '⟦ŴÇ ·⟧';

  @override
  String get amenityRestaurant => '⟦Ƒóóđ ··⟧';

  @override
  String get amenityAtm => '⟦ÁŦṀ ·⟧';

  @override
  String get amenityWifi => '⟦ŴîƑî ··⟧';

  @override
  String get amenityEv => '⟦ÉṼ ·⟧';

  @override
  String get paymentMethods => '⟦Ƥáýɱéñŧ ɱéŧĥóđš ······⟧';

  @override
  String get paymentMethodCash => '⟦Çášĥ ··⟧';

  @override
  String get paymentMethodCard => '⟦Çářđ ··⟧';

  @override
  String get paymentMethodContactless => '⟦Çóñŧáçŧłéšš ·····⟧';

  @override
  String get paymentMethodFuelCard => '⟦Ƒúéł Çářđ ····⟧';

  @override
  String get paymentMethodApp => '⟦Áƥƥ ·⟧';

  @override
  String payWithApp(String app) {
    return '⟦Ƥáý ŵîŧĥ $app ···⟧';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '⟦$value Ł/100 ķɱ ·⟧';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return '⟦Çóɱƥářéđ ŧó ŧĥé řółłîñǧ áṽéřáǧé óṽéř ýóúř łášŧ 3 ƒîłł-úƥš ($avg Ł/100 ķɱ). ······················⟧';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return '⟦Çóñšúɱƥŧîóñ $value Ł/100 ķɱ, $delta ṽéřšúš ýóúř řółłîñǧ áṽéřáǧé ·················⟧';
  }

  @override
  String get drivingMode => '⟦Đřîṽîñǧ Ṁóđé ·····⟧';

  @override
  String get drivingExit => '⟦Éẋîŧ ··⟧';

  @override
  String get drivingNearestStation => '⟦Ñéářéšŧ ···⟧';

  @override
  String get drivingTapToUnlock => '⟦Ŧáƥ ŧó úñłóçķ ·····⟧';

  @override
  String get drivingSafetyTitle => '⟦Šáƒéŧý Ñóŧîçé ·····⟧';

  @override
  String get drivingSafetyMessage =>
      '⟦Đó ñóŧ óƥéřáŧé ŧĥé áƥƥ ŵĥîłé đřîṽîñǧ. Ƥúłł óṽéř ŧó á šáƒé łóçáŧîóñ ƀéƒóřé îñŧéřáçŧîñǧ ŵîŧĥ ŧĥé šçřééñ. Ŧĥé đřîṽéř îš řéšƥóñšîƀłé ƒóř šáƒé óƥéřáŧîóñ óƒ ŧĥé ṽéĥîçłé áŧ áłł ŧîɱéš. ································································⟧';

  @override
  String get drivingSafetyAccept => '⟦Î úñđéřšŧáñđ ·····⟧';

  @override
  String get voiceAnnouncementsTitle => '⟦Ṽóîçé Áññóúñçéɱéñŧš ········⟧';

  @override
  String get voiceAnnouncementsDescription =>
      '⟦Áññóúñçé ñéářƀý çĥéáƥ šŧáŧîóñš ŵĥîłé đřîṽîñǧ ··················⟧';

  @override
  String get voiceAnnouncementsEnabled =>
      '⟦Éñáƀłé ṽóîçé áññóúñçéɱéñŧš ···········⟧';

  @override
  String get voiceAnnouncementProximityRadius =>
      '⟦Áññóúñçéɱéñŧ řáđîúš ········⟧';

  @override
  String get voiceAnnouncementCooldown => '⟦Řéƥéáŧ îñŧéřṽáł ······⟧';

  @override
  String get voiceAnnouncementPriceLimit => '⟦Ṁáẋîɱúɱ ƥřîçé ·····⟧';

  @override
  String get consumptionStatsTitle => '⟦Çóñšúɱƥŧîóñ šŧáŧš ·······⟧';

  @override
  String get addFillUp => '⟦Áđđ ƒîłł-úƥ ····⟧';

  @override
  String get noFillUpsTitle => '⟦Ñó ƒîłł-úƥš ýéŧ ·····⟧';

  @override
  String get noFillUpsSubtitle =>
      '⟦Łóǧ ýóúř ƒîřšŧ ƒîłł-úƥ ŧó šŧářŧ ŧřáçķîñǧ çóñšúɱƥŧîóñ. ····················⟧';

  @override
  String get fillUpDate => '⟦Đáŧé ··⟧';

  @override
  String get liters => '⟦Łîŧéřš ···⟧';

  @override
  String get odometerKm => '⟦Óđóɱéŧéř (ķɱ) ·····⟧';

  @override
  String get notesOptional => '⟦Ñóŧéš (óƥŧîóñáł) ······⟧';

  @override
  String get statAvgConsumption => '⟦Áṽǧ Ł/100ķɱ ···⟧';

  @override
  String get statAvgCostPerKm => '⟦Áṽǧ çóšŧ/ķɱ ····⟧';

  @override
  String get statTotalLiters => '⟦Ŧóŧáł łîŧéřš ·····⟧';

  @override
  String get statTotalSpent => '⟦Ŧóŧáł šƥéñŧ ·····⟧';

  @override
  String get statFillUpCount => '⟦Ƒîłł-úƥš ···⟧';

  @override
  String get fieldRequired => '⟦Řéɋúîřéđ ····⟧';

  @override
  String get fieldInvalidNumber => '⟦Îñṽáłîđ ñúɱƀéř ······⟧';

  @override
  String get carbonDashboardTitle => '⟦Çářƀóñ đášĥƀóářđ ·······⟧';

  @override
  String get carbonEmptyTitle => '⟦Ñó đáŧá ýéŧ ····⟧';

  @override
  String get carbonEmptySubtitle =>
      '⟦Łóǧ ƒîłł-úƥš ŧó šéé ýóúř çářƀóñ đášĥƀóářđ. ···············⟧';

  @override
  String get carbonSummaryTotalCost => '⟦Ŧóŧáł çóšŧ ····⟧';

  @override
  String get carbonSummaryTotalCo2 => '⟦Ŧóŧáł ÇÓ2 ···⟧';

  @override
  String get monthlyCostsTitle => '⟦Ṁóñŧĥłý çóšŧš ·····⟧';

  @override
  String get monthlyEmissionsTitle => '⟦Ṁóñŧĥłý ÇÓ2 éɱîššîóñš ········⟧';

  @override
  String get vehiclesTitle => '⟦Ṁý ṽéĥîçłéš ·····⟧';

  @override
  String get vehiclesMenuTitle => '⟦Ṁý ṽéĥîçłéš ·····⟧';

  @override
  String get vehiclesMenuSubtitle =>
      '⟦Ýóúř çářš — ƒúéł ŧýƥé, éñǧîñé áñđ ŧáñķ šîžé ƒóř áççúřáŧé çóñšúɱƥŧîóñ éšŧîɱáŧéš ·····························⟧';

  @override
  String get vehiclesEmptyMessage =>
      '⟦Áđđ ýóúř çář ŧó ƒîłŧéř ƀý çóññéçŧóř áñđ éšŧîɱáŧé çĥářǧîñǧ çóšŧš. ························⟧';

  @override
  String get vehiclesWizardTitle => '⟦Ṁý ṽéĥîçłéš (óƥŧîóñáł) ········⟧';

  @override
  String get vehiclesWizardSubtitle =>
      '⟦Áđđ ýóúř çář ŧó ƥřé-ƒîłł ŧĥé çóñšúɱƥŧîóñ łóǧ áñđ éñáƀłé ÉṼ çóññéçŧóř ƒîłŧéřš. Ýóú çáñ šķîƥ ŧĥîš áñđ áđđ ṽéĥîçłéš łáŧéř. ···········································⟧';

  @override
  String get vehiclesWizardNoneYet => '⟦Ñó ṽéĥîçłé çóñƒîǧúřéđ ýéŧ. ··········⟧';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles',
      one: '1 vehicle',
    );
    return '⟦Ýóú ĥáṽé $_temp0: ···⟧';
  }

  @override
  String get vehiclesWizardSkipHint =>
      '⟦Šķîƥ ŧó ƒîñîšĥ šéŧúƥ — ýóú çáñ áđđ ṽéĥîçłéš áñýŧîɱé ƒřóɱ Šéŧŧîñǧš. ························⟧';

  @override
  String get fillUpVehicleLabel => '⟦Ṽéĥîçłé ···⟧';

  @override
  String get fillUpVehicleRequired => '⟦Ṽéĥîçłé îš řéɋúîřéđ ········⟧';

  @override
  String get reportScanError => '⟦Řéƥóřŧ šçáñ éřřóř ·······⟧';

  @override
  String get pickStationTitle => '⟦Ƥîçķ á šŧáŧîóñ ·····⟧';

  @override
  String get pickStationHelper =>
      '⟦Šŧářŧ ŧĥé ƒîłł-úƥ ƒřóɱ á ķñóŵñ šŧáŧîóñ šó ƥřîçéš, ƀřáñđ áñđ ƒúéł ŧýƥé ƒîłł ŧĥéɱšéłṽéš îñ. ································⟧';

  @override
  String get pickStationEmpty =>
      '⟦Ñó ƒáṽóřîŧé šŧáŧîóñš ýéŧ — áđđ šóɱé ƒřóɱ Šéářçĥ óř Ƒáṽóřîŧéš, óř šķîƥ áñđ ƒîłł îñ ɱáñúáłłý. ································⟧';

  @override
  String get pickStationSkip => '⟦Šķîƥ — áđđ ŵîŧĥóúŧ á šŧáŧîóñ ··········⟧';

  @override
  String get scanPayment => '⟦Šçáñ ƥáýɱéñŧ ɊŘ ······⟧';

  @override
  String get qrPaymentBeneficiary => '⟦Ɓéñéƒîçîářý ·····⟧';

  @override
  String get qrPaymentAmount => '⟦Áɱóúñŧ ···⟧';

  @override
  String get qrPaymentEpcTitle => '⟦ŠÉƤÁ ƥáýɱéñŧ ·····⟧';

  @override
  String get qrPaymentEpcEmpty => '⟦Ñó ƒîéłđš đéçóđéđ ·······⟧';

  @override
  String get qrPaymentOpenInBank => '⟦Óƥéñ îñ ƀáñķ áƥƥ ······⟧';

  @override
  String get qrPaymentLaunchFailed =>
      '⟦Ñó áƥƥ áṽáîłáƀłé ŧó óƥéñ ŧĥîš çóđé ·············⟧';

  @override
  String get qrPaymentUnknownTitle => '⟦Úñřéçóǧñîšéđ çóđé ·······⟧';

  @override
  String get qrPaymentCopyRaw => '⟦Çóƥý řáŵ ŧéẋŧ ·····⟧';

  @override
  String get qrPaymentCopiedRaw => '⟦Çóƥîéđ ŧó çłîƥƀóářđ ········⟧';

  @override
  String get qrPaymentReport => '⟦Řéƥóřŧ ŧĥîš šçáñ ······⟧';

  @override
  String get qrPaymentEpcCopied =>
      '⟦Ɓáñķ đéŧáîłš çóƥîéđ — ƥášŧé îñŧó ýóúř ƀáñķîñǧ áƥƥ ··················⟧';

  @override
  String get qrScannerGuidance => '⟦Ƥóîñŧ ŧĥé çáɱéřá áŧ á ɊŘ çóđé ··········⟧';

  @override
  String get qrScannerPermissionDenied =>
      '⟦Çáɱéřá áççéšš îš ñééđéđ ŧó šçáñ ɊŘ çóđéš. ···············⟧';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      '⟦Çáɱéřá áççéšš ŵáš đéñîéđ. Óƥéñ šéŧŧîñǧš ŧó ǧřáñŧ îŧ. ···················⟧';

  @override
  String get qrScannerRetryPermission => '⟦Ŧřý áǧáîñ ····⟧';

  @override
  String get qrScannerOpenSettings => '⟦Óƥéñ šéŧŧîñǧš ·····⟧';

  @override
  String get qrScannerTimeout =>
      '⟦Ñó ɊŘ çóđé đéŧéçŧéđ. Ṁóṽé çłóšéř óř ŧřý áǧáîñ. ················⟧';

  @override
  String get qrScannerRetry => '⟦Ŧřý áǧáîñ ····⟧';

  @override
  String get torchOn => '⟦Ŧúřñ ƒłášĥ óñ ·····⟧';

  @override
  String get torchOff => '⟦Ŧúřñ ƒłášĥ óƒƒ ·····⟧';

  @override
  String get obdPermissionDenied =>
      '⟦Ǧřáñŧ Ɓłúéŧóóŧĥ ƥéřɱîššîóñ îñ šýšŧéɱ šéŧŧîñǧš ··················⟧';

  @override
  String get obdPickerTitle => '⟦Ƥîçķ áñ ÓƁĐ2 áđáƥŧéř ·······⟧';

  @override
  String get obdPickerScanning => '⟦Šçáññîñǧ ƒóř áđáƥŧéřš… ·········⟧';

  @override
  String get obdPickerConnecting => '⟦Çóññéçŧîñǧ… ·····⟧';

  @override
  String get tripSummaryTitle => '⟦Ŧřîƥ šúɱɱářý ·····⟧';

  @override
  String get tripMetricDistance => '⟦Đîšŧáñçé ····⟧';

  @override
  String get tripMetricFuelUsed => '⟦Ƒúéł úšéđ ····⟧';

  @override
  String get tripMetricAvgConsumption => '⟦Áṽǧ ·⟧';

  @override
  String get tripMetricElapsed => '⟦Éłáƥšéđ ···⟧';

  @override
  String get tripMetricOdometer => '⟦Óđóɱéŧéř ····⟧';

  @override
  String get tripStop => '⟦Šŧóƥ řéçóřđîñǧ ······⟧';

  @override
  String get tripPause => '⟦Ƥáúšé ··⟧';

  @override
  String get tripResume => '⟦Řéšúɱé ···⟧';

  @override
  String get tripBannerRecording => '⟦Řéçóřđîñǧ ŧřîƥ ······⟧';

  @override
  String get tripBannerPaused => '⟦Ŧřîƥ ƥáúšéđ — ŧáƥ ŧó řéšúɱé ·········⟧';

  @override
  String get vehicleBaselineSectionTitle => '⟦Ɓášéłîñé çáłîƀřáŧîóñ ·········⟧';

  @override
  String get vehicleBaselineEmpty =>
      '⟦Ñó šáɱƥłéš ýéŧ — šŧářŧ áñ ÓƁĐ2 ŧřîƥ ŧó ƀéǧîñ łéářñîñǧ ŧĥîš ṽéĥîçłé\'š ƒúéł ƥřóƒîłé. ·····························⟧';

  @override
  String get vehicleBaselineProgress =>
      '⟦Łéářñéđ ƒřóɱ šáɱƥłéš áçřóšš đřîṽîñǧ šîŧúáŧîóñš. ··················⟧';

  @override
  String get vehicleBaselineReset =>
      '⟦Řéšéŧ đřîṽîñǧ-šîŧúáŧîóñ ƀášéłîñé ·············⟧';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      '⟦Řéšéŧ đřîṽîñǧ-šîŧúáŧîóñ ƀášéłîñé? ·············⟧';

  @override
  String get vehicleBaselineResetConfirmBody =>
      '⟦Ŧĥîš ŵîƥéš éṽéřý łéářñéđ šáɱƥłé ƒóř ŧĥîš ṽéĥîçłé. Ýóú\'łł đřîƒŧ ƀáçķ ŧó ŧĥé çółđ-šŧářŧ đéƒáúłŧš úñŧîł ñéŵ ŧřîƥš řéƒîłł ŧĥé ƥřóƒîłé. ················································⟧';

  @override
  String get vehicleBaselineShowDetails =>
      '⟦Šĥóŵ ƥéř-šîŧúáŧîóñ ƀřéáķđóŵñ ···········⟧';

  @override
  String get vehicleBaselineHideDetails =>
      '⟦Ĥîđé ƥéř-šîŧúáŧîóñ ƀřéáķđóŵñ ···········⟧';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return '⟦Ñóŧ đéŧéçŧéđ ýéŧ: $situations. Ŧĥéšé đřîṽîñǧ šîŧúáŧîóñš šŧîłł řéáđ 0 šáɱƥłéš, šó ŧĥé ƀášéłîñé îš îñçóɱƥłéŧé. ···································⟧';
  }

  @override
  String get vehicleAdapterSectionTitle => '⟦ÓƁĐ2 áđáƥŧéř ·····⟧';

  @override
  String get vehicleAdapterEmpty =>
      '⟦Ñó áđáƥŧéř ƥáîřéđ. Ƥáîř óñé šó ŧĥé áƥƥ çáñ řéçóññéçŧ áúŧóɱáŧîçáłłý ñéẋŧ ŧîɱé. ····························⟧';

  @override
  String get vehicleAdapterUnnamed => '⟦Úñķñóŵñ áđáƥŧéř ······⟧';

  @override
  String get vehicleAdapterPair => '⟦Ƥáîř áđáƥŧéř ·····⟧';

  @override
  String get vehicleAdapterForget => '⟦Ƒóřǧéŧ áđáƥŧéř ······⟧';

  @override
  String get achievementsTitle => '⟦Áçĥîéṽéɱéñŧš ·····⟧';

  @override
  String get achievementFirstTrip => '⟦Ƒîřšŧ ŧřîƥ ····⟧';

  @override
  String get achievementFirstTripDesc =>
      '⟦Řéçóřđ ýóúř ƒîřšŧ ÓƁĐ2 ŧřîƥ. ··········⟧';

  @override
  String get achievementFirstFillUp => '⟦Ƒîřšŧ ƒîłł-úƥ ·····⟧';

  @override
  String get achievementFirstFillUpDesc => '⟦Łóǧ ýóúř ƒîřšŧ ƒîłł-úƥ. ········⟧';

  @override
  String get achievementTenTrips => '⟦10 ŧřîƥš ··⟧';

  @override
  String get achievementTenTripsDesc => '⟦Řéçóřđ 10 ÓƁĐ2 ŧřîƥš. ······⟧';

  @override
  String get achievementZeroHarsh => '⟦Šɱóóŧĥ đřîṽéř ·····⟧';

  @override
  String get achievementZeroHarshDesc =>
      '⟦Çóɱƥłéŧé á ŧřîƥ óƒ 10 ķɱ óř ɱóřé ŵîŧĥ ñó ĥářšĥ ƀřáķîñǧ óř áççéłéřáŧîóñ. ·························⟧';

  @override
  String get achievementEcoWeek => '⟦Éçó ŵééķ ···⟧';

  @override
  String get achievementEcoWeekDesc =>
      '⟦Đřîṽé 7 çóñšéçúŧîṽé đáýš ŵîŧĥ áŧ łéášŧ óñé šɱóóŧĥ ŧřîƥ éáçĥ đáý. ·······················⟧';

  @override
  String get achievementPriceWin => '⟦Ƥřîçé ŵîñ ····⟧';

  @override
  String get achievementPriceWinDesc =>
      '⟦Łóǧ á ƒîłł-úƥ ŧĥáŧ ƀéáŧš ŧĥé šŧáŧîóñ\'š 30-đáý áṽéřáǧé ƀý 5 % óř ɱóřé. ······················⟧';

  @override
  String get syncBaselinesToggleTitle =>
      '⟦Šĥářé łéářñéđ ṽéĥîçłé ƥřóƒîłéš ············⟧';

  @override
  String get syncBaselinesToggleSubtitle =>
      '⟦Úƥłóáđ ƥéř-ṽéĥîçłé çóñšúɱƥŧîóñ ƀášéłîñéš šó á šéçóñđ đéṽîçé çáñ řéúšé ŧĥéɱ. ····························⟧';

  @override
  String get obd2StatusConnected => '⟦ÓƁĐ2 áđáƥŧéř: çóññéçŧéđ ·········⟧';

  @override
  String get obd2StatusPermissionDenied =>
      '⟦ÓƁĐ2 áđáƥŧéř: Ɓłúéŧóóŧĥ ƥéřɱîššîóñ ñééđéđ ················⟧';

  @override
  String get obd2StatusConnectedBody => '⟦Řéáđý ŧó řéçóřđ á ŧřîƥ. ········⟧';

  @override
  String get obd2StatusPermissionDeniedBody =>
      '⟦Ǧřáñŧ Ɓłúéŧóóŧĥ ƥéřɱîššîóñ îñ šýšŧéɱ šéŧŧîñǧš ŧó řéçóññéçŧ áúŧóɱáŧîçáłłý. ·····························⟧';

  @override
  String get obd2StatusNoAdapter => '⟦Ñó áđáƥŧéř ƥáîřéđ ·······⟧';

  @override
  String get obd2StatusForget => '⟦Ƒóřǧéŧ áđáƥŧéř ······⟧';

  @override
  String get tripHistoryTitle => '⟦Ŧřîƥ ĥîšŧóřý ·····⟧';

  @override
  String get tripHistoryEmptyTitle => '⟦Ñó ŧřîƥš ýéŧ ·····⟧';

  @override
  String get tripHistoryUnknownDate => '⟦Úñķñóŵñ đáŧé ·····⟧';

  @override
  String get situationIdle => '⟦Îđłé ··⟧';

  @override
  String get situationStopAndGo => '⟦Šŧóƥ & ǧó ···⟧';

  @override
  String get situationUrban => '⟦Úřƀáñ ··⟧';

  @override
  String get situationHighway => '⟦Ĥîǧĥŵáý ···⟧';

  @override
  String get situationDecel => '⟦Đéçéłéřáŧîñǧ ·····⟧';

  @override
  String get situationClimbing => '⟦Çłîɱƀîñǧ / łóáđéđ ······⟧';

  @override
  String get situationColdStart => '⟦Çółđ šŧářŧ ····⟧';

  @override
  String get situationSustainedLoad => '⟦Šúšŧáîñéđ łóáđ / ŧóŵîñǧ ·········⟧';

  @override
  String get situationPartialDecel => '⟦Çóášŧîñǧ ····⟧';

  @override
  String get situationHardAccel => '⟦Ĥářđ áççéł ····⟧';

  @override
  String get situationFuelCut => '⟦Ƒúéł çúŧ — çóášŧ ·····⟧';

  @override
  String get tripSaveRecording => '⟦Šáṽé ŧřîƥ ····⟧';

  @override
  String get tripSummaryAutoSaved => '⟦Ŧřîƥ šáṽéđ áúŧóɱáŧîçáłłý ··········⟧';

  @override
  String get tripSummaryDone => '⟦Đóñé ··⟧';

  @override
  String get tripSummaryDelete => '⟦Đéłéŧé ŧĥîš ŧřîƥ ······⟧';

  @override
  String get vehicleFuelNotSet => '⟦Ñóŧ šéŧ ···⟧';

  @override
  String get wizardVehicleDefaultBadge => '⟦Đéƒáúłŧ ···⟧';

  @override
  String get wizardProfileChoiceHint =>
      '⟦Çĥóóšé ĥóŵ ýóú ŵáñŧ ŧó úšé ŧĥé áƥƥ. Ýóú çáñ çĥáñǧé ŧĥîš łáŧéř îñ Šéŧŧîñǧš. ··························⟧';

  @override
  String get wizardProfileChoiceFooter =>
      '⟦Ýóú çáñ çĥáñǧé ýóúř çĥóîçé áñý ŧîɱé ƒřóɱ Šéŧŧîñǧš → Úšé ɱóđé. ······················⟧';

  @override
  String get wizardProfileBasicName => '⟦Ɓášîç ··⟧';

  @override
  String get wizardProfileBasicDescription =>
      '⟦Çĥéáƥéšŧ ƒúéł áñđ ÉṼ çĥářǧîñǧ ƥřîçéš ñéářƀý. Ƒáṽóřîŧéš áñđ ƥřîçé áłéřŧš. ···························⟧';

  @override
  String get wizardProfileMediumName => '⟦Ṁéđîúɱ ···⟧';

  @override
  String get wizardProfileMediumDescription =>
      '⟦Éṽéřýŧĥîñǧ îñ Ɓášîç, ƥłúš ŧřáçķ ýóúř ƒúéł ƒîłł-úƥš áñđ ÉṼ çĥářǧîñǧ ƀý ĥáñđ. ···························⟧';

  @override
  String get wizardProfileFullName => '⟦Ƒúłł ··⟧';

  @override
  String get wizardProfileFullDescription =>
      '⟦Éṽéřýŧĥîñǧ îñ Ṁéđîúɱ, ƥłúš áúŧóɱáŧîç ÓƁĐ2 ŧřîƥ řéçóřđîñǧ, đřîṽîñǧ šçóřéš, áñđ łóýáłŧý çářđš. ··································⟧';

  @override
  String get wizardProfileCustomName => '⟦Çúšŧóɱ ···⟧';

  @override
  String get useModeSectionHint =>
      '⟦Řîǧĥŧ-šîžé ŧĥé áƥƥ ŧó ĥóŵ ýóú áçŧúáłłý úšé îŧ. Ƥîçķîñǧ á ƥřéšéŧ éñáƀłéš ŧĥé ɱáŧçĥîñǧ šéŧ óƒ ƒéáŧúřéš. ····································⟧';

  @override
  String get useModeCustomSettingsDescription =>
      '⟦Ýóúř ƒéáŧúřé ɱîẋ đóéšñ\'ŧ ɱáŧçĥ áñý ƥřéšéŧ. Ƥîçķ óñé áƀóṽé ŧó óṽéřŵřîŧé, óř ķééƥ çúšŧóɱîšîñǧ îñđîṽîđúáł ƒéáŧúřéš îñ ŧĥé šéçŧîóñ ƀéłóŵ. ·················································⟧';

  @override
  String useModeSwitchedSnack(String profile) {
    return '⟦Úšé ɱóđé šéŧ ŧó $profile. ·····⟧';
  }

  @override
  String get profileDefaultVehicleLabel =>
      '⟦Đéƒáúłŧ ṽéĥîçłé (óƥŧîóñáł) ··········⟧';

  @override
  String get profileDefaultVehicleNone => '⟦Ñó đéƒáúłŧ ····⟧';

  @override
  String get profileFuelFromVehicleHint =>
      '⟦Ƒúéł ŧýƥé îš đéřîṽéđ ƒřóɱ ýóúř đéƒáúłŧ ṽéĥîçłé. Çłéář ŧĥé ṽéĥîçłé ŧó ƥîçķ á ƒúéł đîřéçŧłý. ·································⟧';

  @override
  String get consumptionNoVehicleTitle => '⟦Áđđ á ṽéĥîçłé ƒîřšŧ ·······⟧';

  @override
  String get consumptionNoVehicleBody =>
      '⟦Ƒîłł-úƥš ářé áŧŧřîƀúŧéđ ŧó á ṽéĥîçłé. Áđđ ýóúř çář ŧó šŧářŧ łóǧǧîñǧ çóñšúɱƥŧîóñ. ·····························⟧';

  @override
  String get vehicleAdd => '⟦Áđđ ṽéĥîçłé ·····⟧';

  @override
  String get vehicleAddTitle => '⟦Áđđ ṽéĥîçłé ·····⟧';

  @override
  String get vehicleEditTitle => '⟦Éđîŧ ṽéĥîçłé ·····⟧';

  @override
  String get vehicleDeleteTitle => '⟦Đéłéŧé ṽéĥîçłé? ······⟧';

  @override
  String vehicleDeleteMessage(String name) {
    return '⟦Řéɱóṽé \"$name\" ƒřóɱ ýóúř ƥřóƒîłéš? ··········⟧';
  }

  @override
  String get vehicleNameLabel => '⟦Ñáɱé ··⟧';

  @override
  String get vehicleNameHint => '⟦é.ǧ. Ṁý Ŧéšłá Ṁóđéł 3 ······⟧';

  @override
  String get vehicleTypeCombustion => '⟦Çóɱƀúšŧîóñ ·····⟧';

  @override
  String get vehicleTypeHybrid => '⟦Ĥýƀřîđ ···⟧';

  @override
  String get vehicleTypeEv => '⟦Éłéçŧřîç ····⟧';

  @override
  String get vehicleEvSectionTitle => '⟦Éłéçŧřîç ····⟧';

  @override
  String get vehicleCombustionSectionTitle => '⟦Çóɱƀúšŧîóñ ·····⟧';

  @override
  String get vehicleBatteryLabel => '⟦Ɓáŧŧéřý çáƥáçîŧý (ķŴĥ) ········⟧';

  @override
  String get vehicleMaxChargeLabel => '⟦Ṁáẋ çĥářǧîñǧ ƥóŵéř (ķŴ) ········⟧';

  @override
  String get vehicleConnectorsLabel => '⟦Šúƥƥóřŧéđ çóññéçŧóřš ·········⟧';

  @override
  String get vehicleMinSocLabel => '⟦Ṁîñ ŠóÇ % ···⟧';

  @override
  String get vehicleMaxSocLabel => '⟦Ṁáẋ ŠóÇ % ···⟧';

  @override
  String get vehicleTankLabel => '⟦Ŧáñķ çáƥáçîŧý (Ł) ······⟧';

  @override
  String get vehiclePowerLabel => '⟦Éñǧîñé ƥóŵéř (ķŴ) ······⟧';

  @override
  String vehiclePowerHelper(String ps) {
    return '⟦≈ $ps ƤŠ ·⟧';
  }

  @override
  String get vehiclePreferredFuelLabel => '⟦Ƥřéƒéřřéđ ƒúéł ······⟧';

  @override
  String get connectorType2 => '⟦Ŧýƥé 2 ··⟧';

  @override
  String get connectorCcs => '⟦ÇÇŠ ·⟧';

  @override
  String get connectorChademo => '⟦ÇĤÁđéṀÓ ···⟧';

  @override
  String get connectorTesla => '⟦Ŧéšłá ··⟧';

  @override
  String get connectorSchuko => '⟦Šçĥúķó ···⟧';

  @override
  String get connectorType1 => '⟦Ŧýƥé 1 ··⟧';

  @override
  String get connectorThreePin => '⟦3-ƥîñ ·⟧';

  @override
  String get evShowOnMap => '⟦Šĥóŵ ÉṼ šŧáŧîóñš ······⟧';

  @override
  String get evAvailableOnly => '⟦Áṽáîłáƀłé óñłý ······⟧';

  @override
  String get evMinPower => '⟦Ṁîñ ƥóŵéř ····⟧';

  @override
  String get evStatusAvailable => '⟦Áṽáîłáƀłé ····⟧';

  @override
  String get evStatusOccupied => '⟦Óççúƥîéđ ····⟧';

  @override
  String get evStatusOutOfOrder => '⟦Óúŧ óƒ óřđéř ·····⟧';

  @override
  String get evStatusPartial => '⟦Ƥářŧłý áṽáîłáƀłé ·······⟧';

  @override
  String get openOnlyFilter => '⟦Óƥéñ óñłý ····⟧';

  @override
  String get saveAsDefaults => '⟦Šáṽé áš ɱý đéƒáúłŧš ·······⟧';

  @override
  String get criteriaSavedToProfile => '⟦Šáṽéđ áš đéƒáúłŧš ·······⟧';

  @override
  String get updatingFavorites => '⟦Úƥđáŧîñǧ ýóúř ƒáṽóřîŧéš... ·········⟧';

  @override
  String get fetchingLatestPrices => '⟦Ƒéŧçĥîñǧ ŧĥé łáŧéšŧ ƥřîçéš ··········⟧';

  @override
  String get noDataAvailable => '⟦Ñó đáŧá ···⟧';

  @override
  String get searchToSeeMap =>
      '⟦Šéářçĥ ŧó šéé šŧáŧîóñš óñ ŧĥé ɱáƥ ············⟧';

  @override
  String get evPowerAny => '⟦Áñý ·⟧';

  @override
  String evPowerKw(int kw) {
    return '⟦$kw ķŴ+ ·⟧';
  }

  @override
  String get sectionProfile => '⟦Ƥřóƒîłé ···⟧';

  @override
  String get sectionLocation => '⟦Łóçáŧîóñ ····⟧';

  @override
  String get sectionPrivacyData => '⟦Ƥřîṽáçý & đáŧá ·····⟧';

  @override
  String get sectionAdvancedDeveloper => '⟦Áđṽáñçéđ & đéṽéłóƥéř ········⟧';

  @override
  String get tooltipBack => '⟦Ɓáçķ ··⟧';

  @override
  String get tooltipClose => '⟦Çłóšé ··⟧';

  @override
  String get tooltipShare => '⟦Šĥářé ··⟧';

  @override
  String get tooltipClearSearch => '⟦Çłéář šéářçĥ îñƥúŧ ·······⟧';

  @override
  String get minimalDriveInstantConsumption => '⟦Îñšŧáñŧ çóñšúɱƥŧîóñ ········⟧';

  @override
  String get minimalDriveBehaviour => '⟦Đřîṽîñǧ ƀéĥáṽîóúř ·······⟧';

  @override
  String get coachingShiftUp => '⟦Šĥîƒŧ úƥ ···⟧';

  @override
  String get coachingShiftDown => '⟦Šĥîƒŧ đóŵñ ····⟧';

  @override
  String get coachingEasePedal => '⟦Éášé óƒƒ ···⟧';

  @override
  String get coachingVoiceHardAcceleration =>
      '⟦Éášý óñ ŧĥé áççéłéřáŧóř ·········⟧';

  @override
  String get coachingVoiceHarshBraking =>
      '⟦Ŧřý ŧó ƀřáķé ɱóřé ǧéñŧłý ·········⟧';

  @override
  String get coachingVoiceShiftUp =>
      '⟦Šĥîƒŧ úƥ á ǧéář ŧó šáṽé ƒúéł ··········⟧';

  @override
  String get coachingVoiceShiftDown =>
      '⟦Šĥîƒŧ đóŵñ, ŧĥé éñǧîñé îš łáƀóúřîñǧ ·············⟧';

  @override
  String get coachingVoiceEasePedal =>
      '⟦Éášé óƒƒ ŧĥé ƥéđáł ŧó çúŧ ýóúř ƒúéł úšé ··············⟧';

  @override
  String get coachingVoiceLiftOff =>
      '⟦Łîƒŧ óƒƒ ŧĥé áççéłéřáŧóř áñđ çóášŧ ·············⟧';

  @override
  String get coachingVoiceAnticipateBrake =>
      '⟦Łóóķ ƒúřŧĥéř áĥéáđ áñđ łîƒŧ óƒƒ éářłîéř ···············⟧';

  @override
  String get coachingVoiceSmoothAccel =>
      '⟦Áççéłéřáŧé ɱóřé šɱóóŧĥłý ··········⟧';

  @override
  String get coachingVoiceSharpCorner =>
      '⟦Ŧáķé çóřñéřš á łîŧŧłé ǧéñŧłéř ···········⟧';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      '⟦Ŧĥáŧ ŵáš á ṽéřý ĥářđ šŧóƥ — łéáṽé ɱóřé đîšŧáñçé ·················⟧';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      '⟦Ṽéřý ĥářđ áççéłéřáŧîóñ — ŧĥáŧ ƀúřñš řéáł ƒúéł ·················⟧';

  @override
  String get coachingVoiceSharpCornerStrong =>
      '⟦Ṽéřý šĥářƥ çóřñéř — šłóŵ îñ, ǧéñŧłé óúŧ ··············⟧';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount harsh events.',
      one: 'One harsh event.',
      zero: 'Nice and smooth — no harsh events.',
    );
    return '⟦Ŧřîƥ šáṽéđ: $distanceKm ķîłóɱéŧřéš, $consumption. $_temp0 ·········⟧';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '⟦$value łîŧřéš ƥéř 100 ķîłóɱéŧřéš ·········⟧';
  }

  @override
  String get voiceCoachingSettingTitle => '⟦Šƥóķéñ đřîṽîñǧ çóáçĥîñǧ ·········⟧';

  @override
  String get voiceCoachingSettingSubtitle =>
      '⟦Ĥéář šƥóķéñ ŧîƥš ŵĥîłé ýóú đřîṽé — ĥářđ áççéłéřáŧîóñ, ĥářšĥ ƀřáķîñǧ áñđ ǧéář ĥîñŧš ······························⟧';

  @override
  String get tooltipUseGps => '⟦Úšé ǦƤŠ łóçáŧîóñ ······⟧';

  @override
  String get tooltipShowPassword => '⟦Šĥóŵ ƥáššŵóřđ ·····⟧';

  @override
  String get tooltipHidePassword => '⟦Ĥîđé ƥáššŵóřđ ·····⟧';

  @override
  String get evConnectorsLabel => '⟦Áṽáîłáƀłé çóññéçŧóřš ·········⟧';

  @override
  String get evConnectorsNone => '⟦Ñó çóññéçŧóř îñƒóřɱáŧîóñ ··········⟧';

  @override
  String get switchToEmail => '⟦Šŵîŧçĥ ŧó éɱáîł ······⟧';

  @override
  String get switchToEmailSubtitle =>
      '⟦Ķééƥ đáŧá, áđđ šîǧñ-îñ ƒřóɱ óŧĥéř đéṽîçéš ···············⟧';

  @override
  String get switchToAnonymousAction => '⟦Šŵîŧçĥ ŧó áñóñýɱóúš ········⟧';

  @override
  String get switchToAnonymousSubtitle =>
      '⟦Ķééƥ łóçáł đáŧá, úšé ñéŵ áñóñýɱóúš šéššîóñ ················⟧';

  @override
  String get linkDevice => '⟦Łîñķ đéṽîçé ·····⟧';

  @override
  String get shareDatabase => '⟦Šĥářé đáŧáƀášé ······⟧';

  @override
  String get disconnectAction => '⟦Đîšçóññéçŧ ·····⟧';

  @override
  String get disconnectSubtitle =>
      '⟦Šŧóƥ šýñçîñǧ (łóçáł đáŧá ķéƥŧ) ···········⟧';

  @override
  String get deleteAccountAction => '⟦Đéłéŧé áççóúñŧ ······⟧';

  @override
  String get deleteAccountSubtitle =>
      '⟦Řéɱóṽé áłł šéřṽéř đáŧá ƥéřɱáñéñŧłý ··············⟧';

  @override
  String get localOnly => '⟦Łóçáł óñłý ····⟧';

  @override
  String get localOnlySubtitle =>
      '⟦Óƥŧîóñáł: šýñç ƒáṽóřîŧéš, áłéřŧš, áñđ řáŧîñǧš áçřóšš đéṽîçéš ·······················⟧';

  @override
  String get tankSyncSchemaOutdatedTitle =>
      '⟦Çłóúđ đáŧáƀášé ñééđš áñ úƥđáŧé ············⟧';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      '⟦Ýóúř šéłƒ-ĥóšŧéđ ŦáñķŠýñç šçĥéɱá îš óúŧđáŧéđ — šóɱé đáŧá çáññóŧ šýñç. Óƥéñ ŧĥé šýñç ŵîžářđ áñđ řúñ ŧĥé úƥđáŧé ŠɊŁ óñ ýóúř Šúƥáƀášé ƥřóĵéçŧ. ··················································⟧';

  @override
  String get setupCloudSync => '⟦Šéŧ úƥ çłóúđ šýñç ······⟧';

  @override
  String get disconnectTitle => '⟦Đîšçóññéçŧ ŦáñķŠýñç? ········⟧';

  @override
  String get disconnectBody =>
      '⟦Çłóúđ šýñç ŵîłł ƀé đîšáƀłéđ. Ýóúř łóçáł đáŧá (ƒáṽóřîŧéš, áłéřŧš, ĥîšŧóřý) îš ƥřéšéřṽéđ óñ ŧĥîš đéṽîçé. Šéřṽéř đáŧá îš ñóŧ đéłéŧéđ. ··············································⟧';

  @override
  String get deleteAccountTitle => '⟦Đéłéŧé áççóúñŧ? ······⟧';

  @override
  String get deleteAccountBody =>
      '⟦Ŧĥîš ƥéřɱáñéñŧłý đéłéŧéš áłł ýóúř đáŧá ƒřóɱ ŧĥé šéřṽéř (ƒáṽóřîŧéš, áłéřŧš, řáŧîñǧš, řóúŧéš). Łóçáł đáŧá óñ ŧĥîš đéṽîçé îš ƥřéšéřṽéđ.\n\nŦĥîš çáññóŧ ƀé úñđóñé. ························································⟧';

  @override
  String get switchToAnonymousTitle => '⟦Šŵîŧçĥ ŧó áñóñýɱóúš? ········⟧';

  @override
  String get switchToAnonymousBody =>
      '⟦Ýóú ŵîłł ƀé šîǧñéđ óúŧ óƒ ýóúř éɱáîł áççóúñŧ áñđ çóñŧîñúé ŵîŧĥ á ñéŵ áñóñýɱóúš šéššîóñ.\n\nÝóúř łóçáł đáŧá (ƒáṽóřîŧéš, áłéřŧš) îš ķéƥŧ óñ ŧĥîš đéṽîçé áñđ ŵîłł ƀé šýñçéđ ŧó ŧĥé ñéŵ áñóñýɱóúš áççóúñŧ. ······································································⟧';

  @override
  String get switchAction => '⟦Šŵîŧçĥ ···⟧';

  @override
  String get helpBannerCriteria =>
      '⟦Ýóúř ƥřóƒîłé đéƒáúłŧš ářé ƥřé-ƒîłłéđ. Áđĵúšŧ çřîŧéřîá ƀéłóŵ ŧó řéƒîñé ýóúř šéářçĥ. ·······························⟧';

  @override
  String get helpBannerAlerts =>
      '⟦Šéŧ á ƥřîçé ŧĥřéšĥółđ ƒóř á šŧáŧîóñ. Ýóú\'łł ƀé ñóŧîƒîéđ ŵĥéñ ƥřîçéš đřóƥ ƀéłóŵ îŧ. Ƥřîçéš ářé çĥéçķéđ ƥéřîóđîçáłłý îñ ŧĥé ƀáçķǧřóúñđ — ƀéšŧ éƒƒóřŧ, ñóŧ îñ řéáł ŧîɱé. ···························································⟧';

  @override
  String get helpBannerConsumption =>
      '⟦Łóǧ éṽéřý ƒîłł-úƥ ŧó ŧřáçķ ýóúř řéáł-ŵóřłđ çóñšúɱƥŧîóñ áñđ ÇÓ₂ ƒóóŧƥřîñŧ. Šŵîƥé łéƒŧ ŧó đéłéŧé áñ éñŧřý. ·····································⟧';

  @override
  String get helpBannerVehicles =>
      '⟦Áđđ ýóúř ṽéĥîçłéš šó ƒîłł-úƥš áñđ ƒúéł ƥřéƒéřéñçéš đéƒáúłŧ çóřřéçŧłý. Ŧĥé ƒîřšŧ ṽéĥîçłé ƀéçóɱéš ýóúř đéƒáúłŧ. ·········································⟧';

  @override
  String get syncNow => '⟦Šýñç ñóŵ ···⟧';

  @override
  String get onboardingPreferencesTitle => '⟦Ýóúř ƥřéƒéřéñçéš ·······⟧';

  @override
  String get onboardingZipHelper =>
      '⟦Úšéđ ŵĥéñ ǦƤŠ îš úñáṽáîłáƀłé ···········⟧';

  @override
  String get onboardingRadiusHelper =>
      '⟦Łářǧéř řáđîúš = ɱóřé řéšúłŧš ··········⟧';

  @override
  String get onboardingPrivacy =>
      '⟦Ŧĥéšé šéŧŧîñǧš ářé šŧóřéđ óñłý óñ ýóúř đéṽîçé áñđ ñéṽéř šĥářéđ. ·······················⟧';

  @override
  String get onboardingLandingTitle => '⟦Ĥóɱé šçřééñ ·····⟧';

  @override
  String get onboardingLandingHint =>
      '⟦Çĥóóšé ŵĥîçĥ šçřééñ óƥéñš ŵĥéñ ýóú łáúñçĥ ŧĥé áƥƥ. ··················⟧';

  @override
  String get iosAutoRecordOnboardingTitle =>
      '⟦Šŧáý óúŧ óƒ ŧĥé áƥƥ — ƀúŧ đóñ\'ŧ ɋúîŧ îŧ. ·············⟧';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      '⟦Óƥéñ Šƥářķîłó óñçé áƒŧéř éáçĥ řéƀóóŧ. ··············⟧';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      '⟦Áƥƥłé ŵáķéš Šƥářķîłó óñłý áƒŧéř ýóú\'ṽé óƥéñéđ îŧ áŧ łéášŧ óñçé šîñçé ŧĥé ƥĥóñé řéšŧářŧéđ. Áƒŧéř ŧĥáŧ, ýóúř ŧřîƥš řéçóřđ áúŧóɱáŧîçáłłý. ··················································⟧';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      '⟦Đóñ\'ŧ šŵîƥé Šƥářķîłó áŵáý îñ ŧĥé áƥƥ šŵîŧçĥéř. ·················⟧';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '⟦\"Ƒóřçé-ɋúîŧ\" ŧéłłš îÓŠ ŧó šŧóƥ řéłáúñçĥîñǧ ŧĥé áƥƥ. Ýóúř ŧřîƥš ŵîłł šŧóƥ řéçóřđîñǧ úñŧîł ýóú óƥéñ Šƥářķîłó áǧáîñ. ·········································⟧';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      '⟦Ŵĥéñ îÓŠ ášķš ƒóř \"Áłŵáýš\" łóçáŧîóñ, ƥłéášé šáý ýéš. ··················⟧';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      '⟦Ŧĥé ƒáłłƀáçķ ŧĥáŧ řéçóřđš ýóúř ŧřîƥ ŵĥéñ ŧĥé ÓƁĐ2 áđáƥŧéř îš šłóŵ ñééđš ƀáçķǧřóúñđ łóçáŧîóñ. Ŵé ñéṽéř šĥářé îŧ. ·········································⟧';

  @override
  String get scanReceipt => '⟦Šçáñ řéçéîƥŧ ·····⟧';

  @override
  String get brandFilterHighway => '⟦Ĥîǧĥŵáý ···⟧';

  @override
  String get ratingModeLocal => '⟦Łóçáł ··⟧';

  @override
  String get ratingModePrivate => '⟦Ƥřîṽáŧé ···⟧';

  @override
  String get ratingModeShared => '⟦Šĥářéđ ···⟧';

  @override
  String get ratingDescLocal =>
      '⟦Řáŧîñǧš šáṽéđ óñ ŧĥîš đéṽîçé óñłý ·············⟧';

  @override
  String get ratingDescPrivate =>
      '⟦Šýñçéđ ŵîŧĥ ýóúř đáŧáƀášé (ñóŧ ṽîšîƀłé ŧó óŧĥéřš) ··················⟧';

  @override
  String get ratingDescShared =>
      '⟦Ṽîšîƀłé ŧó áłł úšéřš óƒ ýóúř đáŧáƀášé ··············⟧';

  @override
  String get errorNoEvApiKey =>
      '⟦ÓƥéñÇĥářǧéṀáƥ ÁƤÎ ķéý ñóŧ çóñƒîǧúřéđ. Áđđ óñé îñ Šéŧŧîñǧš ŧó šéářçĥ ÉṼ çĥářǧîñǧ šŧáŧîóñš. ·································⟧';

  @override
  String errorUpstreamCertExpired(String host) {
    return '⟦Ŧĥé đáŧá ƥřóṽîđéř ($host) îš šéřṽîñǧ áñ éẋƥîřéđ óř îñṽáłîđ ŦŁŠ çéřŧîƒîçáŧé. Ŧĥé áƥƥ çáññóŧ łóáđ đáŧá ƒřóɱ ŧĥîš šóúřçé úñŧîł ŧĥé ƥřóṽîđéř ƒîẋéš îŧ. Ƥłéášé çóñŧáçŧ $host. ·························································⟧';
  }

  @override
  String get offlineLabel => '⟦Óƒƒłîñé ···⟧';

  @override
  String fallbackSummary(String failed, String current) {
    return '⟦$failed úñáṽáîłáƀłé. Úšîñǧ $current. ·······⟧';
  }

  @override
  String get errorTitleApiKey => '⟦ÁƤÎ ķéý řéɋúîřéđ ······⟧';

  @override
  String get errorTitleLocation => '⟦Łóçáŧîóñ úñáṽáîłáƀłé ·········⟧';

  @override
  String get errorHintNoStations =>
      '⟦Ŧřý îñçřéášîñǧ ŧĥé šéářçĥ řáđîúš óř šéářçĥ á đîƒƒéřéñŧ łóçáŧîóñ. ························⟧';

  @override
  String get errorHintApiKey =>
      '⟦Çóñƒîǧúřé ýóúř ÁƤÎ ķéý îñ Šéŧŧîñǧš. ·············⟧';

  @override
  String get errorHintConnection =>
      '⟦Çĥéçķ ýóúř îñŧéřñéŧ çóññéçŧîóñ áñđ ŧřý áǧáîñ. ·················⟧';

  @override
  String get errorHintRouting =>
      '⟦Řóúŧé çáłçúłáŧîóñ ƒáîłéđ. Çĥéçķ ýóúř îñŧéřñéŧ çóññéçŧîóñ áñđ ŧřý áǧáîñ. ···························⟧';

  @override
  String get errorHintFallback =>
      '⟦Ŧřý áǧáîñ óř šéářçĥ ƀý ƥóšŧáł çóđé / çîŧý ñáɱé. ················⟧';

  @override
  String get alertsLoadErrorTitle => '⟦Çóúłđñ\'ŧ łóáđ ýóúř áłéřŧš ·········⟧';

  @override
  String get detailsLabel => '⟦Đéŧáîłš ···⟧';

  @override
  String get remove => '⟦Řéɱóṽé ···⟧';

  @override
  String get showKey => '⟦Šĥóŵ ķéý ···⟧';

  @override
  String get hideKey => '⟦Ĥîđé ķéý ···⟧';

  @override
  String get syncOptionalTitle => '⟦ŦáñķŠýñç îš óƥŧîóñáł ········⟧';

  @override
  String get syncOptionalDescription =>
      '⟦Ýóúř áƥƥ ŵóřķš ƒúłłý ŵîŧĥóúŧ çłóúđ šýñç. ŦáñķŠýñç łéŧš ýóú šýñç ƒáṽóřîŧéš, řáŧîñǧš, áłéřŧš, îǧñóřéđ šŧáŧîóñš, šáṽéđ řóúŧéš, ṽéĥîçłéš, ƒúéł łóǧš áñđ ŧřîƥš áçřóšš đéṽîçéš úšîñǧ Šúƥáƀášé (ƒřéé ŧîéř áṽáîłáƀłé). ···········································································⟧';

  @override
  String get syncHowToConnectQuestion =>
      '⟦Ĥóŵ ŵóúłđ ýóú łîķé ŧó çóññéçŧ? ···········⟧';

  @override
  String get syncCreateOwnTitle => '⟦Çřéáŧé ɱý óŵñ đáŧáƀášé ·········⟧';

  @override
  String get syncCreateOwnSubtitle =>
      '⟦Ƒřéé Šúƥáƀášé ƥřóĵéçŧ — ŵé\'łł ǧúîđé ýóú šŧéƥ ƀý šŧéƥ ··················⟧';

  @override
  String get syncJoinExistingTitle => '⟦Ĵóîñ áñ éẋîšŧîñǧ đáŧáƀášé ··········⟧';

  @override
  String get syncJoinExistingSubtitle =>
      '⟦Šçáñ ɊŘ çóđé ƒřóɱ ŧĥé đáŧáƀášé óŵñéř óř ƥášŧé çřéđéñŧîáłš ······················⟧';

  @override
  String get syncChooseAccountType => '⟦Çĥóóšé ýóúř áççóúñŧ ŧýƥé ·········⟧';

  @override
  String get syncAccountTypeAnonymous => '⟦Áñóñýɱóúš ····⟧';

  @override
  String get syncAccountTypeAnonymousDesc =>
      '⟦Îñšŧáñŧ, ñó éɱáîł ñééđéđ. Đáŧá ŧîéđ ŧó ŧĥîš đéṽîçé. ··················⟧';

  @override
  String get syncAccountTypeEmail => '⟦Éɱáîł Áççóúñŧ ·····⟧';

  @override
  String get syncAccountTypeEmailDesc =>
      '⟦Šîǧñ îñ ƒřóɱ áñý đéṽîçé. Řéçóṽéř đáŧá îƒ ƥĥóñé îš łóšŧ. ···················⟧';

  @override
  String get syncHaveAccountSignIn =>
      '⟦Áłřéáđý ĥáṽé áñ áççóúñŧ? Šîǧñ îñ ············⟧';

  @override
  String get syncCreateNewAccount => '⟦Çřéáŧé ñéŵ áççóúñŧ ·······⟧';

  @override
  String get syncTestConnection => '⟦Ŧéšŧ Çóññéçŧîóñ ······⟧';

  @override
  String get syncTestingConnection => '⟦Ŧéšŧîñǧ... ···⟧';

  @override
  String get syncConnectButton => '⟦Çóññéçŧ ···⟧';

  @override
  String get syncConnectingButton => '⟦Çóññéçŧîñǧ... ·····⟧';

  @override
  String get syncDatabaseReady => '⟦Đáŧáƀášé řéáđý! ······⟧';

  @override
  String get syncDatabaseNeedsSetup => '⟦Đáŧáƀášé ñééđš šéŧúƥ ········⟧';

  @override
  String get syncTableStatusOk => '⟦ÓĶ ·⟧';

  @override
  String get syncTableStatusMissing => '⟦Ṁîššîñǧ ···⟧';

  @override
  String get syncSqlEditorInstructions =>
      '⟦Çóƥý ŧĥé ŠɊŁ ƀéłóŵ áñđ řúñ îŧ îñ ýóúř Šúƥáƀášé ŠɊŁ Éđîŧóř (Đášĥƀóářđ → ŠɊŁ Éđîŧóř → Ñéŵ Ɋúéřý → Ƥášŧé → Řúñ) ····································⟧';

  @override
  String get syncCopySqlButton => '⟦Çóƥý ŠɊŁ ŧó çłîƥƀóářđ ········⟧';

  @override
  String get syncRecheckSchemaButton => '⟦Řé-çĥéçķ šçĥéɱá ······⟧';

  @override
  String get syncSchemaOutdated =>
      '⟦Ýóúř ŦáñķŠýñç šçĥéɱá îš óúŧđáŧéđ — řé-řúñ ŧĥé šéŧúƥ ŠɊŁ ƀéłóŵ ŧó éñáƀłé ŧĥé łáŧéšŧ šýñçéđ ƒéáŧúřéš. ····································⟧';

  @override
  String get syncDoneButton => '⟦Đóñé ··⟧';

  @override
  String syncSignedInAs(String email) {
    return '⟦Šîǧñéđ îñ áš $email ·····⟧';
  }

  @override
  String get syncEmailDescription =>
      '⟦Ýóúř đáŧá šýñçš áçřóšš áłł đéṽîçéš ŵîŧĥ ŧĥîš éɱáîł. ···················⟧';

  @override
  String get syncSwitchToAnonymousTitle => '⟦Šŵîŧçĥ ŧó áñóñýɱóúš ········⟧';

  @override
  String get syncSwitchToAnonymousDesc =>
      '⟦Çóñŧîñúé ŵîŧĥóúŧ éɱáîł, ñéŵ áñóñýɱóúš šéššîóñ ··················⟧';

  @override
  String get syncGuestDescription => '⟦Áñóñýɱóúš, ñó éɱáîł ñééđéđ. ··········⟧';

  @override
  String get syncOrDivider => '⟦óř ·⟧';

  @override
  String get syncHowToSyncQuestion => '⟦Ĥóŵ ŵóúłđ ýóú łîķé ŧó šýñç? ·········⟧';

  @override
  String get syncOfflineDescription =>
      '⟦Ýóúř áƥƥ ŵóřķš ƒúłłý óƒƒłîñé. Çłóúđ šýñç îš óƥŧîóñáł. ···················⟧';

  @override
  String get syncModeCommunityTitle => '⟦Šƥářķîłó Çóɱɱúñîŧý ········⟧';

  @override
  String get syncModeCommunitySubtitle =>
      '⟦Šĥářéđ đáŧáƀášé řúñ ƀý ŧĥé đéṽéłóƥéř — šéé ŵĥáŧ šýñçš ƀéłóŵ ······················⟧';

  @override
  String get syncModePrivateTitle => '⟦Ƥřîṽáŧé Đáŧáƀášé ·······⟧';

  @override
  String get syncModePrivateSubtitle =>
      '⟦Ýóúř óŵñ Šúƥáƀášé — ƒúłł đáŧá çóñŧřół ··············⟧';

  @override
  String get syncModeGroupTitle => '⟦Ĵóîñ á Ǧřóúƥ ·····⟧';

  @override
  String get syncModeGroupSubtitle =>
      '⟦Ƒáɱîłý óř ƒřîéñđš šĥářéđ đáŧáƀášé ·············⟧';

  @override
  String get syncPrivacyShared => '⟦Šĥářéđ ···⟧';

  @override
  String get syncPrivacyPrivate => '⟦Ƥřîṽáŧé ···⟧';

  @override
  String get syncPrivacyGroup => '⟦Ǧřóúƥ ··⟧';

  @override
  String get syncStayOfflineButton => '⟦Šŧáý óƒƒłîñé ·····⟧';

  @override
  String get syncSuccessTitle => '⟦Šúççéššƒúłłý çóññéçŧéđ! ·········⟧';

  @override
  String get syncSuccessDescription =>
      '⟦Ýóúř đáŧá ŵîłł ñóŵ šýñç áúŧóɱáŧîçáłłý. ··············⟧';

  @override
  String get syncWizardTitleConnect => '⟦Çóññéçŧ ŦáñķŠýñç ·······⟧';

  @override
  String get syncSetupTitleYourDatabase => '⟦Ýóúř đáŧáƀášé ·····⟧';

  @override
  String get syncSetupTitleJoinGroup => '⟦Ĵóîñ á ǧřóúƥ ·····⟧';

  @override
  String get syncSetupTitleAccount => '⟦Ýóúř áççóúñŧ ·····⟧';

  @override
  String get syncWizardBack => '⟦Ɓáçķ ··⟧';

  @override
  String get syncWizardNext => '⟦Ñéẋŧ ··⟧';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return '⟦Šŧéƥ $current óƒ $total ···⟧';
  }

  @override
  String get syncWizardCreateSupabaseTitle =>
      '⟦Çřéáŧé á Šúƥáƀášé ƥřóĵéçŧ ··········⟧';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '⟦1. Ŧáƥ \"Óƥéñ Šúƥáƀášé\" ƀéłóŵ\n2. Çřéáŧé á ƒřéé áççóúñŧ (îƒ ýóú đóñ\'ŧ ĥáṽé óñé)\n3. Çłîçķ \"Ñéŵ Ƥřóĵéçŧ\"\n4. Çĥóóšé á ñáɱé áñđ řéǧîóñ\n5. Ŵáîŧ ~2 ɱîñúŧéš ƒóř îŧ ŧó šŧářŧ ··················································⟧';

  @override
  String get syncWizardOpenSupabase => '⟦Óƥéñ Šúƥáƀášé ·····⟧';

  @override
  String get syncWizardEnableAnonTitle =>
      '⟦Éñáƀłé Áñóñýɱóúš Šîǧñ-îñš ··········⟧';

  @override
  String get syncWizardEnableAnonInstructions =>
      '⟦1. Îñ ýóúř Šúƥáƀášé đášĥƀóářđ:\n   Áúŧĥéñŧîçáŧîóñ → Ƥřóṽîđéřš\n2. Ƒîñđ \"Áñóñýɱóúš Šîǧñ-îñš\"\n3. Ŧóǧǧłé îŧ ÓÑ\n4. Çłîçķ \"Šáṽé\" ······································⟧';

  @override
  String get syncWizardOpenAuthSettings => '⟦Óƥéñ Áúŧĥ Šéŧŧîñǧš ·······⟧';

  @override
  String get syncWizardCopyCredentialsTitle =>
      '⟦Çóƥý ýóúř çřéđéñŧîáłš ·········⟧';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '⟦1. Ǧó ŧó Šéŧŧîñǧš → ÁƤÎ îñ ýóúř đášĥƀóářđ\n2. Çóƥý ŧĥé \"Ƥřóĵéçŧ ÚŘŁ\"\n3. Çóƥý ŧĥé \"áñóñ ƥúƀłîç\" ķéý\n4. Ƥášŧé ŧĥéɱ ƀéłóŵ ····································⟧';

  @override
  String get syncWizardOpenApiSettings => '⟦Óƥéñ ÁƤÎ Šéŧŧîñǧš ·······⟧';

  @override
  String get syncWizardSupabaseUrlLabel => '⟦Šúƥáƀášé ÚŘŁ ·····⟧';

  @override
  String get syncWizardSupabaseUrlHint =>
      '⟦ĥŧŧƥš://ýóúř-ƥřóĵéçŧ.šúƥáƀášé.çó ············⟧';

  @override
  String get syncWizardJoinExistingTitle =>
      '⟦Ĵóîñ áñ éẋîšŧîñǧ đáŧáƀášé ··········⟧';

  @override
  String get syncWizardScanQrCode => '⟦Šçáñ ɊŘ Çóđé ·····⟧';

  @override
  String get syncWizardAskOwnerQr =>
      '⟦Ášķ ŧĥé đáŧáƀášé óŵñéř ŧó šĥóŵ ýóú ŧĥéîř ɊŘ çóđé\n(Šéŧŧîñǧš → ŦáñķŠýñç → Šĥářé) ···························⟧';

  @override
  String get syncWizardAskOwnerQrShort =>
      '⟦Ášķ ŧĥé đáŧáƀášé óŵñéř ŧó šĥóŵ ŧĥéîř ɊŘ çóđé ················⟧';

  @override
  String get syncWizardEnterManuallyTitle => '⟦Éñŧéř ɱáñúáłłý ······⟧';

  @override
  String get syncWizardOrEnterManually => '⟦óř éñŧéř ɱáñúáłłý ·······⟧';

  @override
  String get syncWizardUrlHelperText =>
      '⟦Ŵĥîŧéšƥáçé áñđ łîñé ƀřéáķš řéɱóṽéđ áúŧóɱáŧîçáłłý ···················⟧';

  @override
  String get syncCredentialsPrivateHint =>
      '⟦Éñŧéř ýóúř Šúƥáƀášé ƥřóĵéçŧ çřéđéñŧîáłš. Ýóú çáñ ƒîñđ ŧĥéɱ îñ ýóúř đášĥƀóářđ úñđéř Šéŧŧîñǧš > ÁƤÎ. ····································⟧';

  @override
  String get syncCredentialsDatabaseUrlLabel => '⟦Đáŧáƀášé ÚŘŁ ·····⟧';

  @override
  String get syncCredentialsAccessKeyLabel => '⟦Áççéšš Ķéý ····⟧';

  @override
  String get syncCredentialsAccessKeyHint =>
      '⟦éýĴĥƀǦçîÓîĴÎÚžÎ1ÑîÎš... ·········⟧';

  @override
  String get authEmailLabel => '⟦Éɱáîł ··⟧';

  @override
  String get authPasswordLabel => '⟦Ƥáššŵóřđ ····⟧';

  @override
  String get authConfirmPasswordLabel => '⟦Çóñƒîřɱ ƥáššŵóřđ ·······⟧';

  @override
  String get authPleaseEnterEmail => '⟦Ƥłéášé éñŧéř ýóúř éɱáîł ·········⟧';

  @override
  String get authInvalidEmail => '⟦Îñṽáłîđ éɱáîł áđđřéšš ·········⟧';

  @override
  String get authPasswordsDoNotMatch => '⟦Ƥáššŵóřđš đó ñóŧ ɱáŧçĥ ·········⟧';

  @override
  String get authConnectAnonymously => '⟦Çóññéçŧ áñóñýɱóúšłý ········⟧';

  @override
  String get authCreateAccountAndConnect =>
      '⟦Çřéáŧé áççóúñŧ & çóññéçŧ ·········⟧';

  @override
  String get authSignInAndConnect => '⟦Šîǧñ îñ & çóññéçŧ ······⟧';

  @override
  String get authAnonymousSegment => '⟦Áñóñýɱóúš ····⟧';

  @override
  String get authEmailSegment => '⟦Éɱáîł ··⟧';

  @override
  String get authAnonymousDescription =>
      '⟦Îñšŧáñŧ áççéšš, ñó éɱáîł ñééđéđ. Đáŧá ŧîéđ ŧó ŧĥîš đéṽîçé. ·····················⟧';

  @override
  String get authEmailDescription =>
      '⟦Šîǧñ îñ ƒřóɱ áñý đéṽîçé. Řéçóṽéř ýóúř đáŧá îƒ ýóúř ƥĥóñé îš łóšŧ. ·······················⟧';

  @override
  String get authSyncAcrossDevices =>
      '⟦Šýñç đáŧá áúŧóɱáŧîçáłłý áçřóšš áłł ýóúř đéṽîçéš. ··················⟧';

  @override
  String get authNewHereCreateAccount => '⟦Ñéŵ ĥéřé? Çřéáŧé áççóúñŧ ·········⟧';

  @override
  String get linkDeviceScreenTitle => '⟦Łîñķ Đéṽîçé ·····⟧';

  @override
  String get linkDeviceThisDeviceLabel => '⟦Ŧĥîš đéṽîçé ·····⟧';

  @override
  String get linkDeviceShareCodeHint =>
      '⟦Šĥářé ŧĥîš çóđé ŵîŧĥ ýóúř óŧĥéř đéṽîçé: ··············⟧';

  @override
  String get linkDeviceNotConnected => '⟦Ñóŧ çóññéçŧéđ ·····⟧';

  @override
  String get linkDeviceCopyCodeTooltip => '⟦Çóƥý çóđé ····⟧';

  @override
  String get linkDeviceImportSectionTitle =>
      '⟦Îɱƥóřŧ ƒřóɱ áñóŧĥéř đéṽîçé ··········⟧';

  @override
  String get linkDeviceImportDescription =>
      '⟦Éñŧéř ŧĥé đéṽîçé çóđé ƒřóɱ ýóúř óŧĥéř đéṽîçé ŧó îɱƥóřŧ îŧš ƒáṽóřîŧéš, áłéřŧš, ṽéĥîçłéš, áñđ çóñšúɱƥŧîóñ łóǧ. Éáçĥ đéṽîçé ķééƥš îŧš óŵñ ƥřóƒîłé áñđ đéƒáúłŧš. ·························································⟧';

  @override
  String get linkDeviceCodeFieldLabel => '⟦Đéṽîçé çóđé ·····⟧';

  @override
  String get linkDeviceCodeFieldHint =>
      '⟦Ƥášŧé ŧĥé ÚÚÎĐ ƒřóɱ óŧĥéř đéṽîçé ············⟧';

  @override
  String get linkDeviceImportButton => '⟦Îɱƥóřŧ đáŧá ·····⟧';

  @override
  String get linkDeviceHowItWorksTitle => '⟦Ĥóŵ îŧ ŵóřķš ·····⟧';

  @override
  String get linkDeviceHowItWorksBody =>
      '⟦1. Óñ Đéṽîçé Á: çóƥý ŧĥé đéṽîçé çóđé áƀóṽé\n2. Óñ Đéṽîçé Ɓ: ƥášŧé îŧ îñ ŧĥé \"Đéṽîçé çóđé\" ƒîéłđ\n3. Ŧáƥ \"Îɱƥóřŧ đáŧá\" ŧó ɱéřǧé ƒáṽóřîŧéš, áłéřŧš, ṽéĥîçłéš, áñđ çóñšúɱƥŧîóñ łóǧš\n4. Ɓóŧĥ đéṽîçéš ŵîłł ĥáṽé áłł çóɱƀîñéđ đáŧá\n\nÉáçĥ đéṽîçé ķééƥš îŧš óŵñ áñóñýɱóúš îđéñŧîŧý áñđ îŧš óŵñ ƥřóƒîłé (ƥřéƒéřřéđ ƒúéł, đéƒáúłŧ ṽéĥîçłé, łáñđîñǧ šçřééñ). Đáŧá îš ɱéřǧéđ, ñóŧ ɱóṽéđ. ····························································································································⟧';

  @override
  String get vehicleSetActive => '⟦Šéŧ áçŧîṽé ····⟧';

  @override
  String get swipeHide => '⟦Ĥîđé ··⟧';

  @override
  String get yourRating => '⟦Ýóúř řáŧîñǧ ·····⟧';

  @override
  String get noStorageUsed => '⟦Ñó šŧóřáǧé úšéđ ······⟧';

  @override
  String get aboutReportBug => '⟦Řéƥóřŧ á ƀúǧ / Šúǧǧéšŧ á ƒéáŧúřé ···········⟧';

  @override
  String get aboutSupportProject => '⟦Šúƥƥóřŧ ŧĥîš ƥřóĵéçŧ ········⟧';

  @override
  String get aboutSupportDescription =>
      '⟦Ŧĥîš áƥƥ îš ƒřéé, óƥéñ šóúřçé, áñđ ĥáš ñó áđš. Îƒ ýóú ƒîñđ îŧ úšéƒúł, çóñšîđéř šúƥƥóřŧîñǧ ŧĥé đéṽéłóƥéř. ····································⟧';

  @override
  String get reportIssueTitle => '⟦Řéƥóřŧ á ƥřóƀłéɱ ······⟧';

  @override
  String get enterCorrection => '⟦Ƥłéášé éñŧéř ŧĥé çóřřéçŧîóñ ···········⟧';

  @override
  String get reportNoBackendAvailable =>
      '⟦Ŧĥé řéƥóřŧ çóúłđ ñóŧ ƀé šéñŧ: ñó řéƥóřŧîñǧ šéřṽîçé îš çóñƒîǧúřéđ ƒóř ŧĥîš çóúñŧřý. Éñáƀłé ŦáñķŠýñç îñ Šéŧŧîñǧš ŧó šéñđ çóɱɱúñîŧý řéƥóřŧš. ···················································⟧';

  @override
  String get correctName => '⟦Çóřřéçŧ šŧáŧîóñ ñáɱé ········⟧';

  @override
  String get correctAddress => '⟦Çóřřéçŧ áđđřéšš ······⟧';

  @override
  String get wrongE85Price => '⟦Ŵřóñǧ É85 ƥřîçé ·····⟧';

  @override
  String get wrongE98Price => '⟦Ŵřóñǧ Šúƥéř 98 ƥřîçé ·······⟧';

  @override
  String get wrongLpgPrice => '⟦Ŵřóñǧ ŁƤǦ ƥřîçé ······⟧';

  @override
  String get wrongStationName => '⟦Ŵřóñǧ šŧáŧîóñ ñáɱé ·······⟧';

  @override
  String get wrongStationAddress => '⟦Ŵřóñǧ áđđřéšš ·····⟧';

  @override
  String get independentStation => '⟦Îñđéƥéñđéñŧ šŧáŧîóñ ········⟧';

  @override
  String get serviceRemindersSection => '⟦Šéřṽîçé řéɱîñđéřš ·······⟧';

  @override
  String get serviceRemindersEmpty =>
      '⟦Ñó řéɱîñđéřš ýéŧ — ƥîçķ á ƥřéšéŧ áƀóṽé. ··············⟧';

  @override
  String get addServiceReminder => '⟦Áđđ řéɱîñđéř ·····⟧';

  @override
  String get serviceReminderPresetOil => '⟦Óîł (15,000 ķɱ) ··⟧';

  @override
  String get serviceReminderPresetOilLabel => '⟦Óîł çĥáñǧé ····⟧';

  @override
  String get serviceReminderPresetTires => '⟦Ŧîřéš (20,000 ķɱ) ···⟧';

  @override
  String get serviceReminderPresetTiresLabel => '⟦Ŧîřéš ··⟧';

  @override
  String get serviceReminderPresetInspection =>
      '⟦Îñšƥéçŧîóñ (30,000 ķɱ) ·····⟧';

  @override
  String get serviceReminderPresetInspectionLabel => '⟦Îñšƥéçŧîóñ ·····⟧';

  @override
  String get serviceReminderLabel => '⟦Łáƀéł ··⟧';

  @override
  String get serviceReminderInterval => '⟦Îñŧéřṽáł (ķɱ) ·····⟧';

  @override
  String get serviceReminderLastService => '⟦Łášŧ šéřṽîçé ·····⟧';

  @override
  String get serviceReminderMarkDone => '⟦Ṁářķ áš đóñé ·····⟧';

  @override
  String get serviceReminderDueTitle => '⟦Šéřṽîçé đúé ·····⟧';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '⟦$label îš đúé — $kmOver ķɱ ƥášŧ ŧĥé îñŧéřṽáł. ··········⟧';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '⟦$label îš đúé ñóŵ. ····⟧';
  }

  @override
  String get vinConfirmTitle => '⟦Îš ŧĥîš ýóúř çář? ······⟧';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '⟦$year $make $model — $displacementŁ, $cylinders-çýł, $fuel ··⟧';
  }

  @override
  String get vinPartialInfoNote =>
      '⟦Ƥářŧîáł îñƒó (óƒƒłîñé). Ýóú çáñ éđîŧ ƀéłóŵ. ···············⟧';

  @override
  String get vinDecodeError => '⟦Çóúłđñ\'ŧ đéçóđé ŧĥîš ṼÎÑ ·········⟧';

  @override
  String get vinInvalidFormat => '⟦Îñṽáłîđ ṼÎÑ ƒóřɱáŧ ·······⟧';

  @override
  String get obd2PauseBannerTitle =>
      '⟦ÓƁĐ2 çóññéçŧîóñ łóšŧ — řéçóřđîñǧ ƥáúšéđ ··············⟧';

  @override
  String get obd2PauseBannerResume => '⟦Řéšúɱé řéçóřđîñǧ ·······⟧';

  @override
  String get obd2PauseBannerEnd => '⟦Éñđ řéçóřđîñǧ ·····⟧';

  @override
  String get obd2GpsDegradedBannerTitle =>
      '⟦Řéçóřđîñǧ ŵîŧĥ ǦƤŠ — ÓƁĐ2 řéçóññéçŧîñǧ ··············⟧';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      '⟦Řéçóřđîñǧ ŵîŧĥ ǦƤŠ — ŵáîŧîñǧ ƒóř ŧĥé ÓƁĐ2 áđáƥŧéř ··················⟧';

  @override
  String get alertsStationSectionTitle => '⟦Šŧáŧîóñ áłéřŧš ······⟧';

  @override
  String get alertsStationAdd => '⟦Áđđ á šŧáŧîóñ áłéřŧ ·······⟧';

  @override
  String get alertsRadiusSectionTitle => '⟦Řáđîúš áłéřŧš ·····⟧';

  @override
  String get alertsRadiusAdd => '⟦Áđđ řáđîúš áłéřŧ ······⟧';

  @override
  String get alertsRadiusEmptyTitle => '⟦Ñó řáđîúš áłéřŧš ýéŧ ········⟧';

  @override
  String get alertsRadiusEmptyCta => '⟦Çřéáŧé á řáđîúš áłéřŧ ········⟧';

  @override
  String get alertsRadiusCreateTitle => '⟦Çřéáŧé řáđîúš áłéřŧ ········⟧';

  @override
  String get alertsRadiusLabelHint => '⟦Łáƀéł (é.ǧ. Ĥóɱé đîéšéł) ········⟧';

  @override
  String get alertsRadiusFuelType => '⟦Ƒúéł ŧýƥé ····⟧';

  @override
  String get alertsRadiusKm => '⟦Řáđîúš (ķɱ) ····⟧';

  @override
  String get alertsRadiusCenterGps => '⟦Úšé ɱý łóçáŧîóñ ······⟧';

  @override
  String get alertsRadiusCenterPostalCode => '⟦Ƥóšŧáł çóđé ·····⟧';

  @override
  String get alertsRadiusSave => '⟦Šáṽé ··⟧';

  @override
  String get alertsRadiusCancel => '⟦Çáñçéł ···⟧';

  @override
  String radiusAlertDeleted(String name) {
    return '⟦Řáđîúš áłéřŧ \"$name\" đéłéŧéđ ········⟧';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return '⟦ÓƁĐ2 çóññéçŧéđ: $adapterName ·····⟧';
  }

  @override
  String get obd2PairChipTooltip => '⟦Ƥáîř áñ ÓƁĐ2 áđáƥŧéř ·······⟧';

  @override
  String get fillUpSavedSnackbar => '⟦Ƒîłł-úƥ šáṽéđ ·····⟧';

  @override
  String get notFoundTitle => '⟦Ƥáǧé ñóŧ ƒóúñđ ·····⟧';

  @override
  String notFoundBody(String location) {
    return '⟦\"$location\" ñóŧ ƒóúñđ. ····⟧';
  }

  @override
  String get notFoundHomeButton => '⟦Ĥóɱé ··⟧';

  @override
  String get consumptionTabHiddenNotice =>
      '⟦Ŧĥé Çóñšúɱƥŧîóñ ŧáƀ ŵáš ĥîđđéñ ƀý ýóúř ƥřóƒîłé šéŧŧîñǧš. ·····················⟧';

  @override
  String get swipeBetweenTabsHint =>
      '⟦Ŧîƥ: šŵîƥé łéƒŧ óř řîǧĥŧ ŧó šŵîŧçĥ ƀéŧŵééñ ŧáƀš. ·················⟧';

  @override
  String get discardChangesTitle => '⟦Đîšçářđ çĥáñǧéš? ······⟧';

  @override
  String get discardChangesBody =>
      '⟦Ýóú ĥáṽé úñšáṽéđ çĥáñǧéš. Łéáṽîñǧ ñóŵ ŵîłł đîšçářđ ŧĥéɱ. ·····················⟧';

  @override
  String get discardChangesConfirm => '⟦Đîšçářđ ···⟧';

  @override
  String get discardChangesKeepEditing => '⟦Ķééƥ éđîŧîñǧ ·····⟧';

  @override
  String get tankSyncSectionSubtitle =>
      '⟦Çłóúđ šýñç áçřóšš ýóúř đéṽîçéš ············⟧';

  @override
  String get mapUnavailable => '⟦Ṁáƥ úñáṽáîłáƀłé ······⟧';

  @override
  String get routeNameHintExample => '⟦é.ǧ. Ƥářîš → Łýóñ ·····⟧';

  @override
  String get priceStatsCurrent => '⟦Çúřřéñŧ ···⟧';

  @override
  String get tankerkoenigApiKeyLabel => '⟦Ŧáñķéřķóéñîǧ ÁƤÎ Ķéý ········⟧';

  @override
  String get openChargeMapApiKeyLabel => '⟦ÓƥéñÇĥářǧéṀáƥ ÁƤÎ Ķéý ·········⟧';

  @override
  String get tapToUpdateGpsPosition =>
      '⟦Ŧáƥ ŧó úƥđáŧé ǦƤŠ ƥóšîŧîóñ ··········⟧';

  @override
  String get nameLabel => '⟦Ñáɱé ··⟧';

  @override
  String get obd2ErrorPermissionDenied =>
      '⟦Ɓłúéŧóóŧĥ ƥéřɱîššîóñ îš řéɋúîřéđ ŧó çóññéçŧ ŧó áñ ÓƁĐ2 áđáƥŧéř. ·······················⟧';

  @override
  String get obd2ErrorBluetoothOff =>
      '⟦Ŧúřñ óñ Ɓłúéŧóóŧĥ áñđ ŧřý áǧáîñ. ············⟧';

  @override
  String get obd2ErrorScanTimeout =>
      '⟦Ñó ÓƁĐ2 áđáƥŧéř ƒóúñđ ñéářƀý. Ṁáķé šúřé îŧ îš ƥłúǧǧéđ îñ áñđ ƥóŵéřéđ óñ. ·························⟧';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      '⟦Ŧĥé ÓƁĐ2 áđáƥŧéř đîđ ñóŧ řéšƥóñđ. Çĥéçķ ŧĥé çóññéçŧîóñ áñđ ŧřý áǧáîñ. ·························⟧';

  @override
  String get obd2ErrorEngineOff =>
      '⟦Ñó đáŧá ƒřóɱ ŧĥé ṽéĥîçłé — šŧářŧ ŧĥé éñǧîñé áñđ ŧřý áǧáîñ. ····················⟧';

  @override
  String get obd2ErrorProtocolInitFailed =>
      '⟦Ŧĥé ÓƁĐ2 áđáƥŧéř šéñŧ áñ úñřéçóǧñîžéđ řéšƥóñšé. Îŧ ɱáý ƀé îñçóɱƥáŧîƀłé — ŧřý á đîƒƒéřéñŧ áđáƥŧéř. ···································⟧';

  @override
  String get obd2ErrorDisconnected =>
      '⟦Ŧĥé ÓƁĐ2 áđáƥŧéř đîšçóññéçŧéđ. Řéçóññéçŧ áñđ ŧřý áǧáîñ. ····················⟧';

  @override
  String get obd2ErrorPairingRequired =>
      '⟦Ŧĥé áđáƥŧéř ñééđš Ɓłúéŧóóŧĥ ƥáîřîñǧ. Úñƥłúǧ ŧĥé áđáƥŧéř, ƥłúǧ îŧ ƀáçķ îñ, ŧĥéñ řéŧřý ŵîŧĥîñ 5 ɱîñúŧéš. ····································⟧';

  @override
  String get onboardingExploreDemoData => '⟦Éẋƥłóřé ŵîŧĥ đéɱó đáŧá ·········⟧';

  @override
  String get achievementSmoothDriver => '⟦Šɱóóŧĥ šŧřéáķ ·····⟧';

  @override
  String get achievementSmoothDriverDesc =>
      '⟦Đřîṽé 5 ŧřîƥš îñ á řóŵ ŵîŧĥ á šɱóóŧĥ-đřîṽîñǧ šçóřé óƒ 80 óř ĥîǧĥéř. ······················⟧';

  @override
  String get achievementColdStartAware => '⟦Çółđ-šŧářŧ áŵářé ······⟧';

  @override
  String get achievementColdStartAwareDesc =>
      '⟦Ķééƥ á ŵĥółé ɱóñŧĥ\'š çółđ-šŧářŧ ƒúéł çóšŧ úñđéř 2 % óƒ ŧóŧáł ƒúéł — çóɱƀîñé šĥóřŧ ŧřîƥš. ······························⟧';

  @override
  String get achievementHighwayMaster => '⟦Ĥîǧĥŵáý ɱášŧéř ······⟧';

  @override
  String get achievementHighwayMasterDesc =>
      '⟦Çóɱƥłéŧé á 30 ķɱ+ ŧřîƥ áŧ çóñšîšŧéñŧ šƥééđ ŵîŧĥ á šɱóóŧĥ-đřîṽîñǧ šçóřé óƒ 90 óř ĥîǧĥéř. ·····························⟧';

  @override
  String priceAlertNotificationTitle(String station, String fuelType) {
    return '⟦$station - $fuelType⟧';
  }

  @override
  String priceAlertNotificationBody(
    String price,
    String currency,
    String target,
  ) {
    return '⟦$price $currency (ŧářǧéŧ: $target $currency) ···⟧';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '⟦$fuelLabel đřóƥƥéđ áŧ ñéářƀý šŧáŧîóñš ··········⟧';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '⟦$count šŧáŧîóñš đřóƥƥéđ ƀý úƥ ŧó $cents¢ îñ ŧĥé łášŧ ĥóúř ···············⟧';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '⟦$label: $count šŧáŧîóñš ≤ $threshold $currency ····⟧';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '⟦+ $count ɱóřé ··⟧';
  }

  @override
  String alertsLastChecked(String when) {
    return '⟦Łášŧ çĥéçķéđ: $when ·····⟧';
  }

  @override
  String get alertsLastCheckedNever =>
      '⟦Ƥřîçéš ĥáṽéñ\'ŧ ƀééñ çĥéçķéđ îñ ŧĥé ƀáçķǧřóúñđ ýéŧ ··················⟧';

  @override
  String get alertsIosBestEffortNote =>
      '⟦Óñ îƤĥóñé, áłéřŧ çĥéçķš ářé ƀéšŧ éƒƒóřŧ: îÓŠ đéçîđéš ŵĥéñ ŧĥé áƥƥ ɱáý çĥéçķ ƥřîçéš îñ ŧĥé ƀáçķǧřóúñđ, šó áñ áłéřŧ çáñ ářřîṽé łáŧé óř óççášîóñáłłý ñóŧ áŧ áłł. Óƥéñîñǧ ŧĥé áƥƥ áłŵáýš řúñš á ƒřéšĥ çĥéçķ. ········································································⟧';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return '⟦Ŧářǧéŧ ƥřîçé ($currency) ·····⟧';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return '⟦Ŧĥřéšĥółđ ($currency/Ł) ·····⟧';
  }

  @override
  String get approachOverlaySection => '⟦Ƒúéł Šŧáŧîóñ Řáđář ·······⟧';

  @override
  String get approachRadiusLabel => '⟦Řáđîúš ···⟧';

  @override
  String approachRadiusCaption(String km) {
    return '⟦Řáđář łéáđš ŵîŧĥ ŧĥé ƥřîçé ŵĥéñ ŵîŧĥîñ $km ķɱ óƒ á ƒúéł šŧáŧîóñ ······················⟧';
  }

  @override
  String get approachPriceModeLabel => '⟦Šĥóŵ ƥřîçé ƒóř ·····⟧';

  @override
  String get approachPriceModeNearest => '⟦Ñéářéšŧ šŧáŧîóñ ······⟧';

  @override
  String get approachPriceModeCheapestInRadius =>
      '⟦Çĥéáƥéšŧ îñ řáđîúš ·······⟧';

  @override
  String get approachMinPollLabel => '⟦Ṁîñ řéƒřéšĥ ·····⟧';

  @override
  String approachMinPollCaption(int seconds) {
    return '⟦Ƒłóóř óñ ĥóŵ óƒŧéñ ŧĥé óṽéřłáý řéƒřéšĥéš ŧĥé ñéářéšŧ šŧáŧîóñ (ƒášŧéř áŧ šƥééđ, ñéṽéř ŧîǧĥŧéř ŧĥáñ $seconds š) ····································⟧';
  }

  @override
  String get approachTestSimulateButton =>
      '⟦Ŧéšŧ Ƒúéł Šŧáŧîóñ Řáđář ·········⟧';

  @override
  String get approachTestStopButton => '⟦Šŧóƥ ŧéšŧ ····⟧';

  @override
  String approachTestActiveCaption(String station) {
    return '⟦Ŧéšŧ áçŧîṽé — řáđář šĥóŵš ŧĥé ƥřîçé ƒóř $station ··············⟧';
  }

  @override
  String get approachTestUnavailable =>
      '⟦Áđđ á ƒáṽóřîŧé šŧáŧîóñ ŧó ŧéšŧ ŧĥé Ƒúéł Šŧáŧîóñ Řáđář ····················⟧';

  @override
  String fuelStationRadarProximity(int percent) {
    return '⟦Ƥřóẋîɱîŧý $percent% ····⟧';
  }

  @override
  String get pipTapToRestore => '⟦Ŧáƥ ŧó óƥéñ ŧĥé ƒúłł áƥƥ ·········⟧';

  @override
  String get authErrorNoNetwork =>
      '⟦Ñó ñéŧŵóřķ çóññéçŧîóñ. Ŧřý áǧáîñ łáŧéř. ··············⟧';

  @override
  String get authErrorInvalidCredentials =>
      '⟦Îñṽáłîđ éɱáîł óř ƥáššŵóřđ. Çĥéçķ ýóúř çřéđéñŧîáłš. ···················⟧';

  @override
  String get authErrorUserAlreadyExists =>
      '⟦Ŧĥîš éɱáîł îš áłřéáđý řéǧîšŧéřéđ. Ŧřý šîǧñîñǧ îñ îñšŧéáđ. ·····················⟧';

  @override
  String get authErrorEmailNotConfirmed =>
      '⟦Ƥłéášé çĥéçķ ýóúř éɱáîł áñđ çóñƒîřɱ ýóúř áççóúñŧ ƒîřšŧ. ·····················⟧';

  @override
  String get authErrorGeneric =>
      '⟦Šîǧñ-îñ ƒáîłéđ. Ƥłéášé ŧřý áǧáîñ. ············⟧';

  @override
  String get authLinkEmailTitle => '⟦Łîñķ áñ éɱáîł ·····⟧';

  @override
  String get authLinkEmailSubtitle =>
      '⟦Łîñķ áñ éɱáîł šó ýóúř đáŧá šýñçš áçřóšš đéṽîçéš. Ýóúř çúřřéñŧ ƒáṽóřîŧéš áñđ ŧřîƥš šŧáý óñ ŧĥîš áççóúñŧ. ······································⟧';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return '⟦Ýóú\'řé úšîñǧ á ǧúéšŧ áççóúñŧ ($idPrefix…). Łîñķ áñ éɱáîł šó ýóúř ƒáṽóřîŧéš áñđ ŧřîƥš šýñç ŧó ýóúř óŧĥéř đéṽîçéš. ····································⟧';
  }

  @override
  String get authConfirmationPending =>
      '⟦Áłɱóšŧ ŧĥéřé — çĥéçķ ýóúř éɱáîł áñđ çłîçķ ŧĥé łîñķ ŧó ƒîñîšĥ łîñķîñǧ îŧ. Ýóúř đáŧá îš áłřéáđý šáṽéđ óñ ŧĥîš áççóúñŧ. ·········································⟧';

  @override
  String get autoRecordConsentBadgeLabel =>
      '⟦Ɓáçķǧřóúñđ łóçáŧîóñ — ƒóř áúŧó-řéçóřđ óñłý ················⟧';

  @override
  String get autoRecordConsentExplanationTitle =>
      '⟦Áƀóúŧ ŧĥîš ƥéřɱîššîóñ ·········⟧';

  @override
  String get autoRecordConsentExplanationBody =>
      '⟦Áúŧó-řéçóřđ ñééđš ƀáçķǧřóúñđ łóçáŧîóñ ŧó đéŧéçŧ ŵĥéñ ýóú šŧářŧ đřîṽîñǧ ŵĥîłé ŧĥé áƥƥ îš çłóšéđ. Ŧĥîš ǧřáñŧ îš úšéđ óñłý ƀý áúŧó-řéçóřđ — šŧáŧîóñ šéářçĥ áñđ ɱáƥ çéñŧéřîñǧ úšé á šéƥářáŧé ƒóřéǧřóúñđ łóçáŧîóñ ǧřáñŧ. ··············································································⟧';

  @override
  String get autoRecordConsentExplanationCloseButton => '⟦Ǧóŧ îŧ ··⟧';

  @override
  String get autoRecordConsentExplanationTooltip =>
      '⟦Ŵĥáŧ đóéš ŧĥîš ɱéáñ? ·······⟧';

  @override
  String get autoRecordConsentRevokeAction =>
      '⟦Ŧáƥ ŧó ɱáñáǧé îñ šýšŧéɱ šéŧŧîñǧš ············⟧';

  @override
  String get autoRecordSectionTitle => '⟦Áúŧó-řéçóřđ ·····⟧';

  @override
  String get autoRecordToggleLabel => '⟦Áúŧó-řéçóřđ ŧřîƥš ·······⟧';

  @override
  String get autoRecordStatusActiveLabel =>
      '⟦Áúŧó-řéçóřđ ŵîłł áçŧîṽáŧé ŧĥé ñéẋŧ ŧîɱé ýóú éñŧéř ŧĥé çář. ·····················⟧';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      '⟦Ƥáîř áñ ÓƁĐ2 áđáƥŧéř ŧó éñáƀłé áúŧó-řéçóřđ. ···············⟧';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      '⟦Áłłóŵ ƀáçķǧřóúñđ łóçáŧîóñ šó áúŧó-řéçóřđ ķééƥš řúññîñǧ ŵîŧĥ ŧĥé šçřééñ óƒƒ. ····························⟧';

  @override
  String get autoRecordStatusPairAdapterCta => '⟦Ƥáîř áñ áđáƥŧéř ······⟧';

  @override
  String get autoRecordSpeedThresholdLabel => '⟦Šŧářŧ šƥééđ (ķɱ/ĥ) ······⟧';

  @override
  String get autoRecordSaveDelayLabel =>
      '⟦Šáṽé đéłáý áƒŧéř đîšçóññéçŧ (šéçóñđš) ··············⟧';

  @override
  String get autoRecordBackgroundLocationLabel =>
      '⟦Ɓáçķǧřóúñđ łóçáŧîóñ áłłóŵéđ ···········⟧';

  @override
  String get autoRecordBackgroundLocationRequest =>
      '⟦Řéɋúéšŧ ƥéřɱîššîóñ ········⟧';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      '⟦Ŵĥý \"Áłłóŵ áłł ŧĥé ŧîɱé\"? ········⟧';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      '⟦Áúŧó-řéçóřđ šŧřéáɱš ǦƤŠ çóóřđîñáŧéš ƒřóɱ ŧĥé ÓƁĐ-ÎÎ ƒóřéǧřóúñđ šéřṽîçé ŵĥîłé ŧĥé šçřééñ îš óƒƒ šó ýóúř ŧřîƥ řóúŧé šŧáýš áççúřáŧé. Áñđřóîđ řéɋúîřéš ŧĥé \"Áłłóŵ áłł ŧĥé ŧîɱé\" óƥŧîóñ ƒóř ŧĥáŧ ŧó ķééƥ ŵóřķîñǧ áƒŧéř ŧĥé đéṽîçé łóçķš. ···················································································⟧';

  @override
  String get autoRecordBackgroundLocationOpenSettings =>
      '⟦Óƥéñ šéŧŧîñǧš ·····⟧';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      '⟦Łóçáŧîóñ ƥéřɱîššîóñ řéɋúîřéđ ············⟧';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      '⟦Çóúłđ ñóŧ řéɋúéšŧ ƀáçķǧřóúñđ łóçáŧîóñ ···············⟧';

  @override
  String get aclWakeNotificationTitle => '⟦Çář çóññéçŧéđ ·····⟧';

  @override
  String get aclWakeNotificationBody =>
      '⟦Ŧáƥ ŧó óƥéñ Šƥářķîłó — ŧřîƥ řéçóřđîñǧ çáñ šŧářŧ. ·················⟧';

  @override
  String get exportBackupReady =>
      '⟦Ɓáçķúƥ řéáđý — ƥîçķ á đéšŧîñáŧîóñ ············⟧';

  @override
  String get exportBackupFailed =>
      '⟦Ɓáçķúƥ éẋƥóřŧ ƒáîłéđ — ƥłéášé ŧřý áǧáîñ ··············⟧';

  @override
  String get backupExportProgress => '⟦Éẋƥóřŧîñǧ ýóúř ƀáçķúƥ… ·········⟧';

  @override
  String exportBackupSavedAs(String fileName) {
    return '⟦Šáṽéđ ŧó Đóŵñłóáđš áš $fileName ········⟧';
  }

  @override
  String get restoreBackupDialogTitle => '⟦Řéšŧóřé ƀáçķúƥ ······⟧';

  @override
  String get restoreBackupDialogBody =>
      '⟦Ṁéřǧé áđđš áñđ úƥđáŧéš řéçóřđš ƒřóɱ ŧĥé ƀáçķúƥ áñđ ķééƥš éṽéřýŧĥîñǧ áłřéáđý óñ ŧĥîš đéṽîçé. Řéƥłáçé đéłéŧéš áłł çúřřéñŧ đáŧá ƒîřšŧ, ŧĥéñ řéšŧóřéš óñłý ŧĥé ƀáçķúƥ — ŧĥîš çáññóŧ ƀé úñđóñé. ····································································⟧';

  @override
  String get restoreBackupMergeAction => '⟦Ṁéřǧé ··⟧';

  @override
  String get restoreBackupReplaceAction => '⟦Řéƥłáçé áłł ·····⟧';

  @override
  String get restoreBackupEmpty =>
      '⟦Ɓáçķúƥ řéšŧóřéđ — îŧ çóñŧáîñéđ ñó řéçóřđš ···············⟧';

  @override
  String get restoreBackupCorrupt =>
      '⟦Řéšŧóřé ƒáîłéđ — ŧĥîš ƒîłé îš ñóŧ á ṽáłîđ Ŧáñķšŧéłłéñ ƀáçķúƥ ······················⟧';

  @override
  String get restoreBackupFailed =>
      '⟦Řéšŧóřé ƒáîłéđ — ŧĥé ƒîłé çóúłđ ñóŧ ƀé řéáđ ···············⟧';

  @override
  String get backupImportProgress => '⟦Řéšŧóřîñǧ ýóúř ƀáçķúƥ… ·········⟧';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return '⟦Ṁéřǧéđ $vehicles ṽéĥîçłéš, $fillUps ƒîłł-úƥš, $trips ŧřîƥš, $chargingLogs çĥářǧîñǧ łóǧš ·················⟧';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return '⟦Řéƥłáçéđ áłł đáŧá ŵîŧĥ $vehicles ṽéĥîçłéš, $fillUps ƒîłł-úƥš, $trips ŧřîƥš, $chargingLogs çĥářǧîñǧ łóǧš ·······················⟧';
  }

  @override
  String get brokenMapChipDisclaimer => '⟦ṀÁƤ řéáđîñǧš šúšƥîçîóúš ·········⟧';

  @override
  String get brokenMapSnackbarUnreliable =>
      '⟦ṀÁƤ šéñšóř řéáđš îñçóřřéçŧłý — ƒúéł řéáđîñǧš ɱáý ƀé 50–80% ŧóó łóŵ. Ŧřý á đîƒƒéřéñŧ áđáƥŧéř. ·······························⟧';

  @override
  String get brokenMapBannerHardDisable =>
      '⟦ṀÁƤ šéñšóř úñřéłîáƀłé. Šĥóŵîñǧ ƒîłł-úƥ áṽéřáǧéš îñšŧéáđ óƒ łîṽé ƒúéł řáŧé. ···························⟧';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return '⟦ṀÁƤ šéñšóř: $posterior% ± $margin% ····⟧';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return '⟦ṀÁƤ šéñšóř: $posterior% ± $margin% (ṽéřîƒîéđ) ········⟧';
  }

  @override
  String get brokenMapDiagnosticsCardTitle =>
      '⟦ṀÁƤ šéñšóř đîáǧñóšŧîçš ·········⟧';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return '⟦Ɓřóķéñ-ṀÁƤ çóñƒîđéñçé: $posterior% ± $margin% ·········⟧';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '⟦$count óƀšéřṽáŧîóñš řéçóřđéđ ·········⟧';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => '⟦Ṽéřîƒîéđ çłéáñ ······⟧';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      '⟦Ŧĥîš ṽéĥîçłé\'š ṀÁƤ šéñšóř ĥášñ\'ŧ ƀééñ óƀšéřṽéđ ýéŧ. ··················⟧';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      '⟦Ɓłóçķłîšŧéđ áđáƥŧéřš ·········⟧';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      '⟦Ñó áđáƥŧéřš ářé ƀłóçķłîšŧéđ. ···········⟧';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '⟦$adapter — ƒłáǧǧéđ $percent% ƀřóķéñ ······⟧';
  }

  @override
  String get brokenMapDiagnosticsClearButton => '⟦Çłéář ··⟧';

  @override
  String get brokenMapRevPromptTitle => '⟦Řéṽ ŧĥé éñǧîñé ·····⟧';

  @override
  String get brokenMapRevPromptBody =>
      '⟦Ɓřîéƒłý ƀłîƥ ŧĥé ŧĥřóŧŧłé šó ŧĥé áƥƥ çáñ çĥéçķ ŧĥé ṀÁƤ šéñšóř řéšƥóñđš. ··························⟧';

  @override
  String get brokenMapRevPromptConfirm => '⟦Đóñé — Î řéṽṽéđ ·····⟧';

  @override
  String get calibrationAdvancedTitle => '⟦Áđṽáñçéđ çáłîƀřáŧîóñ ·········⟧';

  @override
  String get calibrationDisplacementLabel =>
      '⟦Éñǧîñé đîšƥłáçéɱéñŧ (çç) ·········⟧';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      '⟦Ṽółúɱéŧřîç éƒƒîçîéñçý (η_ṽ) ·········⟧';

  @override
  String get calibrationAfrLabel => '⟦Áîř-ŧó-ƒúéł řáŧîó (ÁƑŘ) ········⟧';

  @override
  String get calibrationFuelDensityLabel => '⟦Ƒúéł đéñšîŧý (ǧ/Ł) ······⟧';

  @override
  String get calibrationSourceDetected => '⟦(đéŧéçŧéđ ƒřóɱ ṼÎÑ) ·······⟧';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '⟦(çáŧáłóǧ: $makeModel) ···⟧';
  }

  @override
  String get calibrationSourceDefault => '⟦(đéƒáúłŧ) ···⟧';

  @override
  String get calibrationSourceManual => '⟦(ɱáñúáł) ···⟧';

  @override
  String get calibrationResetToDetected =>
      '⟦Řéšéŧ ŧó đéŧéçŧéđ ṽáłúé ·········⟧';

  @override
  String get calibrationBasisAtkinson => '⟦Áŧķîñšóñ çýçłé ······⟧';

  @override
  String get calibrationBasisVnt => '⟦ṼÑŦ đîéšéł + ĐÎ ·····⟧';

  @override
  String get calibrationBasisTurboDi => '⟦Ŧúřƀóçĥářǧéđ + ĐÎ ······⟧';

  @override
  String get calibrationBasisTurbo => '⟦Ŧúřƀóçĥářǧéđ ·····⟧';

  @override
  String get calibrationBasisNaDi => '⟦Ñáŧúřáłłý ášƥîřáŧéđ + ĐÎ ·········⟧';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '⟦(çáŧáłóǧ: $makeModel — $basis đéƒáúłŧ) ······⟧';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      '⟦Ŧĥîš ṽéĥîçłé řéƥóřŧš îŧš ƒúéł řáŧé đîřéçŧłý (ƤÎĐ 5É), šó ṽółúɱéŧřîç-éƒƒîçîéñçý çáłîƀřáŧîóñ îš ñóŧ úšéđ — ýóúř çóñšúɱƥŧîóñ îš ɱéášúřéđ, ñóŧ ɱóđéłłéđ. ······················································⟧';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return '⟦Ýóúř $makeModel îš ɱářķéđ áš đîéšéł ƀúŧ ɱáŧçĥéš á ƥéŧřół çáŧáłóǧ éñŧřý. Ŧáƥ ŧó úƥđáŧé. ···························⟧';
  }

  @override
  String get catalogReresolveSnackbarAction => '⟦Úƥđáŧé ···⟧';

  @override
  String get catalogResetAction => '⟦Řéšéŧ ƒřóɱ ṽéĥîçłé đáŧáƀášé ···········⟧';

  @override
  String get catalogResetConfirmTitle =>
      '⟦Řéšéŧ ƒřóɱ ŧĥé ṽéĥîçłé đáŧáƀášé? ············⟧';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return '⟦Ŧĥîš řéƥłáçéš ŧĥé ŧáñķ çáƥáçîŧý, éñǧîñé ƥóŵéř áñđ đîšƥłáçéɱéñŧ óƒ ŧĥîš ṽéĥîçłé ŵîŧĥ ŧĥé đáŧáƀášé ṽáłúéš ƒóř $vehicle. Óŧĥéř ƒîéłđš áñđ ýóúř ƒîłł-úƥ ĥîšŧóřý ářé ñóŧ ŧóúçĥéđ. ····························································⟧';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      '⟦Ñó ɱáŧçĥîñǧ éñŧřý îñ ŧĥé ṽéĥîçłé đáŧáƀášé ƒóř ŧĥîš ṽéĥîçłé. ······················⟧';

  @override
  String get catalogResetDoneSnackbar =>
      '⟦Ṽéĥîçłé đáŧá řéšéŧ ƒřóɱ ŧĥé đáŧáƀášé. ··············⟧';

  @override
  String get consumptionTabFuel => '⟦Ƒúéł ··⟧';

  @override
  String get consumptionTabCharging => '⟦Çĥářǧîñǧ ····⟧';

  @override
  String get noChargingLogsTitle => '⟦Ñó çĥářǧîñǧ łóǧš ýéŧ ········⟧';

  @override
  String get noChargingLogsSubtitle =>
      '⟦Łóǧ ýóúř ƒîřšŧ çĥářǧîñǧ šéššîóñ ŧó šŧářŧ ŧřáçķîñǧ ÉÚŘ/100 ķɱ áñđ ķŴĥ/100 ķɱ. ·························⟧';

  @override
  String get addChargingLog => '⟦Łóǧ çĥářǧîñǧ ·····⟧';

  @override
  String get addChargingLogTitle => '⟦Łóǧ çĥářǧîñǧ šéššîóñ ········⟧';

  @override
  String get chargingKwh => '⟦Éñéřǧý (ķŴĥ) ····⟧';

  @override
  String get chargingCost => '⟦Ŧóŧáł çóšŧ ····⟧';

  @override
  String get chargingTimeMin => '⟦Çĥářǧé ŧîɱé (ɱîñ) ······⟧';

  @override
  String get chargingStationName => '⟦Šŧáŧîóñ (óƥŧîóñáł) ·······⟧';

  @override
  String chargingEurPer100km(String value) {
    return '⟦$value ÉÚŘ / 100 ķɱ ··⟧';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '⟦$value ķŴĥ / 100 ķɱ ··⟧';
  }

  @override
  String get chargingDerivedHelper =>
      '⟦Ñééđ á ƥřéṽîóúš łóǧ ŧó çóɱƥářé ···········⟧';

  @override
  String get chargingLogButtonLabel => '⟦Łóǧ çĥářǧîñǧ ·····⟧';

  @override
  String get chargingCostTrendTitle => '⟦Çĥářǧîñǧ çóšŧ ŧřéñđ ········⟧';

  @override
  String get chargingEfficiencyTitle => '⟦Éƒƒîçîéñçý (ķŴĥ/100 ķɱ) ·······⟧';

  @override
  String get chargingChartsEmpty => '⟦Ñóŧ éñóúǧĥ đáŧá ýéŧ ·······⟧';

  @override
  String get confirmDeleteTitle => '⟦Đéłéŧé? ···⟧';

  @override
  String get confirmDeleteBody =>
      '⟦Đó ýóú řéáłłý ŵáñŧ ŧó đéłéŧé ŧĥîš? ············⟧';

  @override
  String get consoFeatureGroupTitle => '⟦Çóñšúɱƥŧîóñ ·····⟧';

  @override
  String get consoFeatureGroupDescription =>
      '⟦Ŧřáçķ ýóúř çóñšúɱƥŧîóñ — ɱáñúáł ƒîłł-úƥš, óř áúŧóɱáŧîç ÓƁĐ2 ŧřîƥ řéçóřđîñǧ. ···························⟧';

  @override
  String get consoModeOff => '⟦Óƒƒ ·⟧';

  @override
  String get consoModeFuel => '⟦Ƒúéł ··⟧';

  @override
  String get consoModeFuelAndTrips => '⟦Ƒúéł + Ŧřîƥš ····⟧';

  @override
  String get consoModeOffDescription =>
      '⟦Ñó Çóñšó ŧáƀ áñđ ñó Çóñšó šéŧŧîñǧš šéçŧîóñ. ················⟧';

  @override
  String get consoModeFuelDescription =>
      '⟦Ṁáñúáł ƒîłł-úƥš óñłý. Úšéƒúł ŵîŧĥóúŧ áñ ÓƁĐ2 áđáƥŧéř. ···················⟧';

  @override
  String get consoModeFuelAndTripsDescription =>
      '⟦Áđđš áúŧóɱáŧîç ÓƁĐ2 ŧřîƥ řéçóřđîñǧ. Řéɋúîřéš á ƥáîřéđ áđáƥŧéř. ·······················⟧';

  @override
  String get consoGroupVehicles => '⟦Ṽéĥîçłéš ····⟧';

  @override
  String get consoGroupCoaching => '⟦Çóáçĥîñǧ ŵĥîłé đřîṽîñǧ ·········⟧';

  @override
  String get consoGroupRewards => '⟦Řéŵářđš & šáṽîñǧš ······⟧';

  @override
  String get consoGroupTroubleshooting => '⟦Ŧřóúƀłéšĥóóŧîñǧ ·······⟧';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return '⟦Áççúřáçý: $level · $band ····⟧';
  }

  @override
  String get consumptionAccuracyHigh => '⟦Ĥîǧĥ ··⟧';

  @override
  String get consumptionAccuracyMedium => '⟦Ṁéđîúɱ ···⟧';

  @override
  String get consumptionAccuracyLow => '⟦Łóŵ ·⟧';

  @override
  String get consumptionAccuracyTooltipHigh =>
      '⟦Ƒúłł çáłîƀřáŧîóñ: ƒîłł-úƥš ƥłúš ÓƁĐ2-řéçóřđéđ ŧřîƥš. Ŧĥé Ł/100 ķɱ ƒîǧúřé ŧřáçķš řéáłîŧý ŧó ŵîŧĥîñ á ƒéŵ ƥéřçéñŧ. ·······································⟧';

  @override
  String get consumptionAccuracyTooltipMedium =>
      '⟦Ƒîłł-úƥš ĥáṽé áñçĥóřéđ ŧĥé çóñšúɱƥŧîóñ ɱóđéł, ƀúŧ ñó ÓƁĐ2 ŧřîƥ ĥáš ƒéđ ŧĥé łóóƥ ýéŧ. Řéçóřđ óñé ŵîŧĥ ÓƁĐ2 çóññéçŧéđ ŧó řéáçĥ Ĥîǧĥ áççúřáçý. ··················································⟧';

  @override
  String get consumptionAccuracyTooltipLow =>
      '⟦ǦƤŠ-óñłý — ñó ƒîłł-úƥš ĥáṽé áñçĥóřéđ ŧĥé çóñšúɱƥŧîóñ ɱóđéł ýéŧ. Áđđ á çóúƥłé óƒ ƒúłł ƒîłł-úƥš ŧó îɱƥřóṽé ŧĥé áççúřáçý. ··········································⟧';

  @override
  String get moreActionsTooltip => '⟦Ṁóřé ··⟧';

  @override
  String get exportBackupMenuLabel => '⟦Éẋƥóřŧ ƀáçķúƥ ·····⟧';

  @override
  String get restoreBackupMenuLabel => '⟦Řéšŧóřé ƀáçķúƥ ······⟧';

  @override
  String get carbonDashboardMenuLabel => '⟦Çářƀóñ đášĥƀóářđ ·······⟧';

  @override
  String get settingsMenuLabel => '⟦Šéŧŧîñǧš ····⟧';

  @override
  String get consumptionStatsPageTitle => '⟦Çóñšúɱƥŧîóñ šŧáŧîšŧîçš ·········⟧';

  @override
  String get consumptionStatsComparisonTitle =>
      '⟦Ŧĥîš ɱóñŧĥ ṽš łášŧ ɱóñŧĥ ·········⟧';

  @override
  String get consumptionStatsTrendsTitle => '⟦Éṽółúŧîóñ óṽéř ŧîɱé ········⟧';

  @override
  String get consumptionStatsNeedTwoMonths =>
      '⟦Łóǧ ƒîłł-úƥš áçřóšš áŧ łéášŧ ŧŵó ɱóñŧĥš ŧó çóɱƥářé. ··················⟧';

  @override
  String get consumptionStatsPricePerLiter => '⟦Áṽǧ ƥřîçé/Ł ····⟧';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '⟦$pct%⟧';
  }

  @override
  String get consumptionStatsChartLiters => '⟦Łîŧřéš ƥéř ɱóñŧĥ ······⟧';

  @override
  String get consumptionStatsChartSpend => '⟦Šƥéñđ ƥéř ɱóñŧĥ ······⟧';

  @override
  String get consumptionStatsChartPricePerLiter => '⟦Ƥřîçé ƥéř łîŧřé ······⟧';

  @override
  String get consumptionStatsChartConsumption => '⟦Ł/100ķɱ ƥéř ɱóñŧĥ ·····⟧';

  @override
  String get fuelCompareSectionTitle =>
      '⟦Çóšŧ óƒ đřîṽîñǧ, ƒúéł ƀý ƒúéł ··········⟧';

  @override
  String get fuelComparePricePerLitre => '⟦Ƥáîđ ƥéř łîŧřé ·····⟧';

  @override
  String get fuelCompareCostPer100km => '⟦Çóšŧ ƥéř 100 ķɱ ····⟧';

  @override
  String get fuelCompareDistance => '⟦Đîšŧáñçé ɱéášúřéđ ·······⟧';

  @override
  String get fuelCompareLitres => '⟦Łîŧřéš ƀúřñéđ ·····⟧';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '⟦$winner îš ýóúř çĥéáƥéšŧ ƒúéł ŧó đřîṽé óñ ············⟧';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '⟦$loser çóšŧš $amount ɱóřé ƥéř 1000 ķɱ ······⟧';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '⟦$fuel ƀéáŧš $rival ƀéłóŵ $price ƥéř łîŧřé ········⟧';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      '⟦Ɓřéáķ-éṽéñ îš çáłçúłáŧéđ ƒřóɱ éáçĥ ƒúéł\'š ɱéášúřéđ çóñšúɱƥŧîóñ, šó îŧ ɱóṽéš áš ýóúř đřîṽîñǧ đóéš. ····································⟧';

  @override
  String get fuelCompareLitresVsCostNote =>
      '⟦Łîŧřéš áñđ çóšŧ çáñ đîšáǧřéé: á ƒúéł çáñ ƀúřñ ƒéŵéř łîŧřéš ƥéř 100 ķɱ áñđ šŧîłł çóšŧ ɱóřé ƥéř ķîłóɱéŧřé, ƀéçáúšé ŧĥé ƥúɱƥ ƥřîçé đîƒƒéřš. Çóšŧ ƥéř ķîłóɱéŧřé îš ŧĥé ṽéřđîçŧ. ····························································⟧';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full tanks',
      one: 'one full tank',
    );
    return '⟦Ƥřóṽîšîóñáł — ƀášéđ óñ $_temp0 ········⟧';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full tanks',
      one: 'one full tank',
    );
    return '⟦Ɓášéđ óñ $_temp0 ···⟧';
  }

  @override
  String get fuelCompareCo2Per100km => '⟦ÇÓ2 ƥéř 100 ķɱ ···⟧';

  @override
  String fuelCompareCleanest(String winner) {
    return '⟦$winner îš ýóúř łóŵéšŧ-éɱîššîóñ ƒúéł ···········⟧';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '⟦$fuel çóšŧš $money ɱóřé ƥéř 1000 ķɱ ƀúŧ éɱîŧš $co2 łéšš ÇÓ2 ·············⟧';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '⟦$fuel îš ƀóŧĥ çĥéáƥéř áñđ çłéáñéř ŧĥáñ $rival ············⟧';
  }

  @override
  String fuelCompareCo2Avoided(
    String distance,
    String fuel,
    String actual,
    String alternative,
    String rival,
    String saved,
  ) {
    return '⟦Ýóúř $distance óñ $fuel éɱîŧŧéđ $actual îñšŧéáđ óƒ $alternative óñ $rival — $saved áṽóîđéđ ··············⟧';
  }

  @override
  String get fuelCompareCo2Source =>
      '⟦ÇÓ2 ƒîǧúřéš ářé ŵéłł-ŧó-ŵĥééł éšŧîɱáŧéš (ÉÚ ĴÉÇ ŴŦŴ ṽ5) áƥƥłîéđ ŧó ýóúř ɱéášúřéđ çóñšúɱƥŧîóñ — áŵářéñéšš, ñóŧ áúđîŧ-ǧřáđé áççóúñŧîñǧ. ···············································⟧';

  @override
  String get fuelCompareCo2BlendOmitted =>
      '⟦ÇÓ2 îš šĥóŵñ ƒóř ƥúřé ƒúéłš óñłý: á ƀłéñđ\'š éɱîššîóñ ƒáçŧóř đéƥéñđš óñ ŧĥé ɱîẋ, ŵĥîçĥ ŧĥîš řóŵ đóéš ñóŧ řéçóřđ. ·······································⟧';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partial fills pending plein complet — not in average',
      one: '1 partial fill pending plein complet — not in average',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '⟦$percent% óƒ ƒúéł ƒřóɱ áúŧó-çóřřéçŧîóñš — řéṽîéŵ éñŧřîéš ·················⟧';
  }

  @override
  String statCorrectionLiters(String liters) {
    return '⟦Çóřřéçŧîóñš: +$liters Ł ·····⟧';
  }

  @override
  String get contentModerationReportAction => '⟦Řéƥóřŧ çóñŧéñŧ ······⟧';

  @override
  String get contentModerationBlockAction => '⟦Ɓłóçķ áúŧĥóř ·····⟧';

  @override
  String get contentModerationReportDialogTitle =>
      '⟦Řéƥóřŧ ŧĥîš çóñŧéñŧ? ········⟧';

  @override
  String get contentModerationReportDialogBody =>
      '⟦Á řéƥóřŧ îš šéñŧ ŧó ýóúř ŦáñķŠýñç šéřṽéř ƒóř řéṽîéŵ, áñđ ŧĥîš çóñŧéñŧ îš ĥîđđéñ óñ ýóúř đéṽîçé. ··································⟧';

  @override
  String get contentModerationReportConfirmButton => '⟦Řéƥóřŧ ···⟧';

  @override
  String get contentModerationBlockDialogTitle =>
      '⟦Ɓłóçķ ŧĥîš áúŧĥóř? ·······⟧';

  @override
  String get contentModerationBlockDialogBody =>
      '⟦Éṽéřýŧĥîñǧ ŧĥîš áççóúñŧ šĥářéš ŵîŧĥ ýóú ŵîłł ƀé ĥîđđéñ óñ ŧĥîš đéṽîçé. ··························⟧';

  @override
  String get contentModerationBlockConfirmButton => '⟦Ɓłóçķ ··⟧';

  @override
  String get contentModerationReportedSnack =>
      '⟦Řéƥóřŧ šúƀɱîŧŧéđ — çóñŧéñŧ ĥîđđéñ. ·············⟧';

  @override
  String get contentModerationReportFailedSnack =>
      '⟦Çóúłđñ\'ŧ šúƀɱîŧ ŧĥé řéƥóřŧ. Ŧřý áǧáîñ. ··············⟧';

  @override
  String get contentModerationBlockedSnack =>
      '⟦Áúŧĥóř ƀłóçķéđ — ŧĥéîř šĥářéđ çóñŧéñŧ îš ĥîđđéñ. ··················⟧';

  @override
  String get fillUpCorrectionLabel =>
      '⟦Áúŧó-çóřřéçŧîóñ — ŧáƥ ŧó éđîŧ ··········⟧';

  @override
  String get fillUpCorrectionEditTitle => '⟦Éđîŧ áúŧó-çóřřéçŧîóñ ········⟧';

  @override
  String get fillUpCorrectionEditExplainer =>
      '⟦Ŧĥîš éñŧřý ŵáš áúŧó-ǧéñéřáŧéđ ŧó çłóšé ŧĥé ǧáƥ ƀéŧŵééñ řéçóřđéđ ŧřîƥš áñđ ƥúɱƥéđ ƒúéł. Áđĵúšŧ ŧĥé ṽáłúéš îƒ ýóú ķñóŵ ŧĥé áçŧúáł ƒîǧúřéš. ··················································⟧';

  @override
  String get fillUpCorrectionDelete => '⟦Đéłéŧé çóřřéçŧîóñ ·······⟧';

  @override
  String get fillUpCorrectionStation => '⟦Šŧáŧîóñ ñáɱé (óƥŧîóñáł) ·········⟧';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '⟦$country šŧáŧîóñš $km ķɱ áŵáý — €$price/Ł çĥéáƥéř ··········⟧';
  }

  @override
  String get crossBorderTapToSwitch => '⟦Ŧáƥ ŧó šŵîŧçĥ çóúñŧřý ········⟧';

  @override
  String get crossBorderDismissTooltip => '⟦Đîšɱîšš ···⟧';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return '⟦Óƥéñ ŧĥé $source đáŧá šóúřçé ($license) îñ ýóúř ƀřóŵšéř ··············⟧';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '⟦© $brand çóñŧřîƀúŧóřš ·····⟧';
  }

  @override
  String get developerToolsSectionTitle => '⟦Đéṽéłóƥéř ŧóółš ······⟧';

  @override
  String get dataAccessTracerExport => '⟦Éẋƥóřŧ đáŧá-áççéšš ŧřáçé ·········⟧';

  @override
  String get dataAccessTracerExportSuccess =>
      '⟦Đáŧá-áççéšš ŧřáçé šáṽéđ ŧó Đóŵñłóáđš. ··············⟧';

  @override
  String get dataAccessTracerExportFailure =>
      '⟦Çóúłđñ\'ŧ éẋƥóřŧ ŧĥé đáŧá-áççéšš ŧřáçé. ··············⟧';

  @override
  String get dataAccessTracerEmpty =>
      '⟦Ñó đáŧá-áççéšš éṽéñŧš řéçóřđéđ ýéŧ — šéářçĥ óř óƥéñ šŧáŧîóñš ƒîřšŧ, ŧĥéñ éẋƥóřŧ. ·····························⟧';

  @override
  String get developerToolsSubtitle =>
      '⟦Đîáǧñóšŧîçš áñđ ŧóółš ƒóř đéƀúǧǧîñǧ — óñłý ṽîšîƀłé îñ Đéṽéłóƥéř / Đéƀúǧ ɱóđé. ····························⟧';

  @override
  String get developerToolsMenuSubtitle =>
      '⟦Éřřóř łóǧ, ŧéšŧ áłéřŧš, đîáǧñóšŧîçš ·············⟧';

  @override
  String get developerToolsErrorLogGroupTitle => '⟦Éřřóř łóǧ ····⟧';

  @override
  String developerToolsExportErrorLog(int count) {
    return '⟦Šáṽé éřřóř łóǧ ($count) ·····⟧';
  }

  @override
  String get developerToolsClearErrorLog => '⟦Çłéář éřřóř łóǧ ······⟧';

  @override
  String get developerToolsViewErrorLog => '⟦Ṽîéŵ éřřóř łóǧ ·····⟧';

  @override
  String get developerToolsErrorLogEmpty =>
      '⟦Ñó éřřóř ŧřáçéš řéçóřđéđ. ·········⟧';

  @override
  String get developerToolsAlertsGroupTitle =>
      '⟦Áłéřŧš & ñóŧîƒîçáŧîóñš ·········⟧';

  @override
  String get developerToolsFireTestNotification =>
      '⟦Ƒîřé ŧéšŧ ñóŧîƒîçáŧîóñ ·········⟧';

  @override
  String get developerToolsTestNotificationTitle =>
      '⟦Ŧéšŧ ñóŧîƒîçáŧîóñ ·······⟧';

  @override
  String get developerToolsTestNotificationBody =>
      '⟦Îƒ ýóú çáñ řéáđ ŧĥîš, ñóŧîƒîçáŧîóñš ářé ŵóřķîñǧ. ··················⟧';

  @override
  String get developerToolsTestNotificationSent =>
      '⟦Ŧéšŧ ñóŧîƒîçáŧîóñ šéñŧ. ·········⟧';

  @override
  String get developerToolsTestNotificationBlocked =>
      '⟦Ñóŧîƒîçáŧîóñš ářé ƀłóçķéđ — éñáƀłé ŧĥéɱ îñ šýšŧéɱ šéŧŧîñǧš, ŧĥéñ řéŧřý. ··························⟧';

  @override
  String get developerToolsRunTestAlert =>
      '⟦Řúñ ŧéšŧ áłéřŧ ƥîƥéłîñé ·········⟧';

  @override
  String developerToolsTestAlertFired(int count) {
    return '⟦Ŧéšŧ áłéřŧ ƒîřéđ — ƥîƥéłîñé đéłîṽéřéđ $count ñóŧîƒîçáŧîóñ(š). ····················⟧';
  }

  @override
  String get developerToolsTestAlertTitle => '⟦Ŧéšŧ ƥřîçé áłéřŧ ······⟧';

  @override
  String developerToolsTestAlertBody(String station) {
    return '⟦Šýñŧĥéŧîç ɱáŧçĥ: $station îš ƀéłóŵ ýóúř ŧářǧéŧ. ··············⟧';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      '⟦Šéářçĥ ƒóř šŧáŧîóñš ƒîřšŧ, ŧĥéñ řúñ ŧĥé ŧéšŧ áłéřŧ šó ŧĥé ñóŧîƒîçáŧîóñ çáñ óƥéñ á řéáł šŧáŧîóñ. ···································⟧';

  @override
  String get developerToolsDiagnosticsGroupTitle => '⟦Đîáǧñóšŧîçš ·····⟧';

  @override
  String get developerToolsFeatureFlagDump =>
      '⟦Ƒéáŧúřé ƒłáǧ îñšƥéçŧóř ·········⟧';

  @override
  String get developerToolsFlagOn => '⟦Óñ ·⟧';

  @override
  String get developerToolsFlagOff => '⟦Óƒƒ ·⟧';

  @override
  String get developerToolsClearCaches => '⟦Çłéář çáçĥéš ·····⟧';

  @override
  String get developerToolsCachesCleared => '⟦Çáçĥéš çłéářéđ. ······⟧';

  @override
  String get developerToolsCopyDiagnostics => '⟦Çóƥý đîáǧñóšŧîçš ·······⟧';

  @override
  String get developerToolsDiagnosticsCopied =>
      '⟦Đîáǧñóšŧîçš çóƥîéđ ŧó çłîƥƀóářđ. ·············⟧';

  @override
  String get developerToolsBuildInfoGroupTitle => '⟦Ɓúîłđ îñƒó ····⟧';

  @override
  String get developerToolsBuildVersion => '⟦Áƥƥ ṽéřšîóñ ·····⟧';

  @override
  String get developerToolsBuildChannel => '⟦Ɓúîłđ çĥáññéł ·····⟧';

  @override
  String get startupTraceSectionTitle =>
      '⟦Šŧářŧúƥ îñîŧîáłîžáŧîóñ ŧřáçé ············⟧';

  @override
  String get startupTraceExportButton => '⟦Éẋƥóřŧ šŧářŧúƥ ŧřáçé ········⟧';

  @override
  String get startupTraceEmpty =>
      '⟦Ñó šŧářŧúƥ ŧřáçé řéçóřđéđ ýéŧ. ···········⟧';

  @override
  String startupTraceTotalMs(int ms) {
    return '⟦Ŧóŧáł: $ms ɱš ···⟧';
  }

  @override
  String startupTraceMs(int ms) {
    return '⟦$ms ɱš ·⟧';
  }

  @override
  String get startupTraceExportSuccess =>
      '⟦Šŧářŧúƥ ŧřáçé šáṽéđ ŧó Đóŵñłóáđš. ·············⟧';

  @override
  String get startupTraceExportFailure =>
      '⟦Çóúłđñ\'ŧ éẋƥóřŧ ŧĥé šŧářŧúƥ ŧřáçé. ·············⟧';

  @override
  String get distanceSourceOdometer => '⟦Óđóɱéŧéř ····⟧';

  @override
  String get distanceSourceOdometerTooltip =>
      '⟦Đîšŧáñçé řéáđ ƒřóɱ ŧĥé çář\'š óđóɱéŧéř — á ɱéášúřéđ ǧřóúñđ ŧřúŧĥ. ·······················⟧';

  @override
  String get distanceSourceGps => '⟦ǦƤŠ ŧřáçķ ····⟧';

  @override
  String get distanceSourceGpsTooltip =>
      '⟦Đîšŧáñçé šúɱɱéđ ƒřóɱ ŧĥé řéçóřđéđ ǦƤŠ ŧřáçķ — ŧřúé řóáđ đîšŧáñçé. ························⟧';

  @override
  String get distanceSourceEstimated => '⟦Éšŧîɱáŧéđ ····⟧';

  @override
  String get distanceSourceEstimatedTooltip =>
      '⟦Đîšŧáñçé îñŧéǧřáŧéđ ƒřóɱ ŧĥé šƥééđ šéñšóř — áñ éšŧîɱáŧé; ŧĥé šéñšóř ŧýƥîçáłłý óṽéř-řéáđš šłîǧĥŧłý. ····································⟧';

  @override
  String get insightCardTitle => '⟦Ŧóƥ ŵášŧéƒúł ƀéĥáṽîóúřš ·········⟧';

  @override
  String get insightEmptyState =>
      '⟦Ñó ñóŧáƀłé îñéƒƒîçîéñçîéš — ķééƥ îŧ úƥ! ··············⟧';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return '⟦Éñǧîñé óṽéř 3000 ŘƤṀ ($pctTime% óƒ ŧřîƥ): ŵášŧéđ $liters Ł ············⟧';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '⟦$count ĥářđ áççéłéřáŧîóñš: ŵášŧéđ $liters Ł ···········⟧';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return '⟦Îđłîñǧ ($pctTime% óƒ ŧřîƥ): ŵášŧéđ $liters Ł ·········⟧';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '⟦$pctTime% óƒ ŧřîƥ ···⟧';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '⟦+$liters Ł⟧';
  }

  @override
  String insightLowGear(String minutes) {
    return '⟦Łáƀóúřîñǧ îñ łóŵ ǧéář ($minutes ɱîñ) ·········⟧';
  }

  @override
  String get lessonAdviceIdling =>
      '⟦Ŧúřñ ŧĥé éñǧîñé óƒƒ áŧ łóñǧ šŧóƥš îñšŧéáđ óƒ łéŧŧîñǧ îŧ îđłé. ······················⟧';

  @override
  String get lessonAdviceHighRpm =>
      '⟦Šĥîƒŧ úƥ éářłîéř ŧó ķééƥ ŧĥé éñǧîñé óúŧ óƒ ŧĥé ĥîǧĥ-ŘƤṀ ƀáñđ. ······················⟧';

  @override
  String get lessonAdviceHardAccel =>
      '⟦Éášé óñŧó ŧĥé ŧĥřóŧŧłé — šɱóóŧĥ áççéłéřáŧîóñ úšéš łéšš ƒúéł. ······················⟧';

  @override
  String get lessonAdviceLowGear =>
      '⟦Šĥîƒŧ úƥ šóóñéř šó ŧĥé éñǧîñé šéŧŧłéš îñŧó á łóŵéř, ɱóřé éƒƒîçîéñŧ ǧéář. ··························⟧';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return '⟦Šúšŧáîñéđ ĥîǧĥ šƥééđ ($pctTime% óƒ ŧřîƥ): ŵášŧéđ $liters Ł ··············⟧';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return '⟦Šúšŧáîñéđ ĥîǧĥ šƥééđ ($pctTime% óƒ ŧřîƥ) ···········⟧';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      '⟦Éášé óƒƒ áƀóṽé 110 ķɱ/ĥ — đřáǧ řîšéš šĥářƥłý, šó á šɱáłł šƥééđ çúŧ šáṽéš á łóŧ óƒ ƒúéł. ····························⟧';

  @override
  String get lessonSmoothDrivingTitle =>
      '⟦Šɱóóŧĥ đřîṽîñǧ — ñîçéłý đóñé! ··········⟧';

  @override
  String get lessonAdviceSmoothDriving =>
      '⟦Ñó ĥářšĥ áççéłéřáŧîóñ óř ƀřáķîñǧ ŧĥîš ŧřîƥ — šŧéáđý îñƥúŧš łîķé ŧĥéšé ķééƥ çóñšúɱƥŧîóñ łóŵ. ··································⟧';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return '⟦Ƒúłł ŧĥřóŧŧłé ($pctTime% óƒ ŧřîƥ): ŵášŧéđ $liters Ł ···········⟧';
  }

  @override
  String get lessonAdviceFullThrottle =>
      '⟦Éášé óñŧó ŧĥé ƥéđáł — á ǧéñŧłéř 70 % óƒ ŧĥé ŧĥřóŧŧłé ǧéŧš ýóú úƥ ŧó šƥééđ óñ ƒář łéšš ƒúéł. ······························⟧';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return '⟦Řîçĥ ɱîẋŧúřé úñđéř łóáđ ($pctTime% óƒ ŧřîƥ): ŵášŧéđ $liters Ł ···············⟧';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      '⟦Ĥéáṽý, šúšŧáîñéđ łóáđ ɱáķéš ŧĥé éñǧîñé řúñ řîçĥ — šĥóřŧ-šĥîƒŧ áñđ ƀáçķ óƒƒ óñ łóñǧ çłîɱƀš ŧó ķééƥ ŧĥé ɱîẋŧúřé łéáñ. ·········································⟧';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return '⟦Çłîɱƀîñǧ áŧ $gradePercent% ǧřáđé ($pctTime% óƒ ŧřîƥ): ŵášŧéđ $liters Ł ·············⟧';
  }

  @override
  String get lessonAdviceClimbingCost =>
      '⟦Çářřý ɱóɱéñŧúɱ îñŧó á ĥîłł áñđ ƒééđ ŧĥé ŧĥřóŧŧłé šɱóóŧĥłý — šúřǧîñǧ óñ á çłîɱƀ ƀúřñš éẋŧřá ƒúéł. ···································⟧';

  @override
  String insightRestartCost(String count, String liters) {
    return '⟦$count šŧóƥ-áñđ-ǧó řéšŧářŧš: ŵášŧéđ $liters Ł ···········⟧';
  }

  @override
  String get lessonAdviceRestartCost =>
      '⟦Áñŧîçîƥáŧé ŧřáƒƒîç áñđ çóášŧ ŧóŵářđ šŧóƥš šó ýóú řółł řáŧĥéř ŧĥáñ řéšŧářŧ — ƥúłłîñǧ áŵáý ƒřóɱ á đéáđ šŧóƥ îš ŧĥé ŧĥîřšŧîéšŧ ƥářŧ óƒ šŧóƥ-áñđ-ǧó. ····················································⟧';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return '⟦Ṁîẋŧúřé łóóķš á łîŧŧłé łéáñ — ŧĥé éñǧîñé áđđéđ ƒúéł ($pctTrim% ŧřîɱ) ŧó çóɱƥéñšáŧé ··························⟧';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return '⟦Ṁîẋŧúřé łóóķš łéáñ — ŧĥé éñǧîñé šúšŧáîñéđ á łářǧé $pctTrim% ƒúéł áđđîŧîóñ, á ƥóššîƀłé îñéƒƒîçîéñçý ·································⟧';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return '⟦Ṁîẋŧúřé łóóķš á łîŧŧłé řîçĥ — ŧĥé éñǧîñé ƥúłłéđ ƒúéł ($pctTrim% ŧřîɱ) ŧó çóɱƥéñšáŧé ··························⟧';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return '⟦Ṁîẋŧúřé łóóķš řîçĥ — ŧĥé éñǧîñé šúšŧáîñéđ á łářǧé $pctTrim% ƒúéł çúŧ, á ƥóššîƀłé îñéƒƒîçîéñçý ·······························⟧';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return '⟦Éñǧîñé řáñ řîçĥ úñđéř łóáđ ($pctShare% óƒ ŧĥé ŵářɱ đřîṽé) — ƥóššîƀłé ŵášŧéđ ƒúéł ························⟧';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      '⟦Ĥéúřîšŧîç ĥéáłŧĥ šîǧñáł, ñóŧ á đîáǧñóšîš ···············⟧';

  @override
  String get lessonAdviceCombustionHealthLean =>
      '⟦Á šúšŧáîñéđ łéáñ-çóřřéçŧîñǧ ŧřîɱ çáñ ɱéáñ áñ îñŧáķé-áîř łéáķ, á ŵéáķ ƒúéł šúƥƥłý, óř áñ áǧéîñǧ šéñšóř. Îƒ çóñšúɱƥŧîóñ óř řúññîñǧ ɋúáłîŧý ŵóřšéñš, á ŵóřķšĥóƥ šçáñ çáñ çóñƒîřɱ. ·······························································⟧';

  @override
  String get lessonAdviceCombustionHealthRich =>
      '⟦Á šúšŧáîñéđ řîçĥ-çóřřéçŧîñǧ ŧřîɱ çáñ ɱéáñ á łéáķîñǧ îñĵéçŧóř, ĥîǧĥ ƒúéł ƥřéššúřé, óř áñ óṽéř-řéáđîñǧ šéñšóř. Îƒ çóñšúɱƥŧîóñ óř řúññîñǧ ɋúáłîŧý ŵóřšéñš, á ŵóřķšĥóƥ šçáñ çáñ çóñƒîřɱ. ··································································⟧';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      '⟦Řúññîñǧ řîçĥ úñđéř ĥéáṽý łóáđ ƀúřñš éẋŧřá ƒúéł. Šĥóřŧ-šĥîƒŧ áñđ éášé óƒƒ óñ łóñǧ ƥúłłš šó ŧĥé éñǧîñé çáñ šŧáý ñéář á šŧóîçĥîóɱéŧřîç ɱîẋŧúřé. ···················································⟧';

  @override
  String get lessonTransportTitle =>
      '⟦Éñǧîñé đáŧá ɱîššîñǧ ƒóř ɱóšŧ óƒ ŧĥîš ŧřîƥ ···············⟧';

  @override
  String get lessonTransportAdvice =>
      '⟦Ŧĥé éñǧîñé řéƥóřŧéđ ñó áçŧîṽîŧý ƒóř áłɱóšŧ ŧĥé ŵĥółé đîšŧáñçé. Éîŧĥéř ŧĥé ÓƁĐ2 šŧřéáɱ ƒáîłéđ ɱîđ-ŧřîƥ óř ŧĥé çář ŵáš ɱóṽéđ ŵîŧĥóúŧ đřîṽîñǧ — ŧĥé çóñšúɱƥŧîóñ ƒîǧúřé îš úñřéłîáƀłé áñđ éẋçłúđéđ ƒřóɱ ýóúř šŧáŧîšŧîçš. ··············································································⟧';

  @override
  String get drivingScoreCardTitle => '⟦Đřîṽîñǧ šçóřé ·····⟧';

  @override
  String get drivingScoreCardOutOf => '⟦/100⟧';

  @override
  String get drivingScoreCardSubtitle =>
      '⟦Çóɱƥóšîŧé šçóřé ƒřóɱ îđłîñǧ, ĥářđ áççéłéřáŧîóñš, ĥářđ ƀřáķîñǧ, áñđ ĥîǧĥ-ŘƤṀ ŧîɱé. Á \'ƀéŧŧéř ŧĥáñ Ẋ% óƒ ƥášŧ ŧřîƥš\' çóɱƥářîšóñ ŵîłł łáñđ îñ á ƒółłóŵ-úƥ řéłéášé. ························································⟧';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return '⟦Đřîṽîñǧ šçóřé $score óúŧ óƒ 100 ········⟧';
  }

  @override
  String get drivingScorePenaltyIdling => '⟦Îđłîñǧ ···⟧';

  @override
  String get drivingScorePenaltyHardAccel => '⟦Ĥářđ áççéłéřáŧîóñš ········⟧';

  @override
  String get drivingScorePenaltyHardBrake => '⟦Ĥářđ ƀřáķîñǧ ·····⟧';

  @override
  String get drivingScorePenaltyHighRpm => '⟦Ĥîǧĥ ŘƤṀ ···⟧';

  @override
  String get drivingScorePenaltyFullThrottle => '⟦Ƒúłł ŧĥřóŧŧłé ·····⟧';

  @override
  String get drivingScoreClassVeryGood => '⟦Ṽéřý ǧóóđ ····⟧';

  @override
  String get drivingScoreClassGood => '⟦Ǧóóđ ··⟧';

  @override
  String get drivingScoreClassAverage => '⟦Áṽéřáǧé ···⟧';

  @override
  String get drivingScoreClassBad => '⟦Ñééđš ŵóřķ ····⟧';

  @override
  String get drivingScorePenaltyLugging => '⟦Łúǧǧîñǧ ···⟧';

  @override
  String get drivingScorePenaltySmoothness => '⟦Ĵéřķý đřîṽîñǧ ·····⟧';

  @override
  String get drivingScorePenaltyHighSpeed => '⟦Ĥîǧĥ šƥééđ ····⟧';

  @override
  String get drivingScorePenaltyPedalVelocity => '⟦Áǧǧřéššîṽé ƥéđáł ·······⟧';

  @override
  String get drivingScorePenaltyLambda => '⟦Řîçĥ ɱîẋŧúřé ·····⟧';

  @override
  String get gpsKpiCardTitle => '⟦ǦƤŠ éƒƒîçîéñçý ······⟧';

  @override
  String get gpsKpiRpa => '⟦Ƥóšîŧîṽé áççéłéřáŧîóñ (ŘƤÁ) ··········⟧';

  @override
  String get gpsKpiPke => '⟦Ķîñéŧîç éñéřǧý đéɱáñđ (ƤĶÉ) ··········⟧';

  @override
  String get gpsKpiVapos => '⟦Áççéłéřáŧîóñ îñŧéñšîŧý (ṼÁƤÓŠ) ············⟧';

  @override
  String get gpsKpiCoast => '⟦Çóášŧîñǧ šĥářé ······⟧';

  @override
  String get gpsKpiClimbEnergy => '⟦Çłîɱƀ éñéřǧý ·····⟧';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '⟦$pct ṽš ýóúř éƒƒîçîéñŧ ƀášéłîñé ··········⟧';
  }

  @override
  String get drivingTraceCardTitle =>
      '⟦Đřîṽîñǧ-áñáłýšîš ŧřáçé (đéṽ) ··········⟧';

  @override
  String get drivingTraceCardBody =>
      '⟦Éẋƥóřŧ ŧĥîš ŧřîƥ\'š ǦƤŠ ĶƤÎš, šçóřé áñđ łéššóñš áš ĴŠÓÑ, ŵřîŧé ĥóŵ ŧĥé đřîṽé áçŧúáłłý ƒéłŧ îñ ŧĥé çóɱɱéñŧ ƒîéłđ, áñđ šĥářé îŧ ƀáçķ šó ŧĥé đřîṽîñǧ-šŧýłé ŧĥřéšĥółđš çáñ ƀé çáłîƀřáŧéđ áǧáîñšŧ řéáł ŧřîƥš. ········································································⟧';

  @override
  String get drivingTraceExportAction => '⟦Éẋƥóřŧ áñáłýšîš ŧřáçé ·········⟧';

  @override
  String get drivingTraceExported =>
      '⟦Áñáłýšîš ŧřáçé šáṽéđ ŧó Đóŵñłóáđš — áđđ ýóúř ṽéřđîçŧ îñ ŧĥé çóɱɱéñŧ ƒîéłđ áñđ šĥářé îŧ ƀáçķ. ·································⟧';

  @override
  String get drivingTraceExportFailed =>
      '⟦Çóúłđñ\'ŧ éẋƥóřŧ ŧĥé áñáłýšîš ŧřáçé. ·············⟧';

  @override
  String get minimalDriveTripAverage => '⟦Ŧřîƥ áṽéřáǧé ·····⟧';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return '⟦Ĥîǧĥ-ŘƤṀ çřúîšîñǧ ($pctTime% óƒ ŧřîƥ): šĥîƒŧîñǧ úƥ éářłîéř çóúłđ šáṽé $liters Ł ······················⟧';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      '⟦Šĥîƒŧ úƥ éářłîéř ŵĥéñ çřúîšîñǧ — ŧĥé šáɱé šƥééđ áŧ łóŵéř ŘƤṀ ƀúřñš ñóŧîçéáƀłý łéšš ƒúéł. ································⟧';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return '⟦Ƒúéł-çúŧ çóášŧîñǧ ($pctTime% óƒ ŧřîƥ): šáṽéđ áƀóúŧ $liters Ł ··············⟧';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      '⟦Ñîçéłý áñŧîçîƥáŧéđ — łîƒŧîñǧ óƒƒ éářłý łéŧš ŧĥé éñǧîñé çúŧ ƒúéł çóɱƥłéŧéłý ŵĥîłé çóášŧîñǧ. ··································⟧';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '⟦−$liters Ł⟧';
  }

  @override
  String get fuelBreakdownTitle => '⟦Ŵĥéřé ýóúř ƒúéł ŵéñŧ ········⟧';

  @override
  String get fuelBreakdownIdle => '⟦Îđłîñǧ ···⟧';

  @override
  String get fuelBreakdownHarshAccel => '⟦Ĥářđ áççéłéřáŧîóñš ········⟧';

  @override
  String get fuelBreakdownHighRpmCruise => '⟦Ĥîǧĥ-ŘƤṀ çřúîšîñǧ ·······⟧';

  @override
  String get fuelBreakdownCoastingSaved => '⟦Šáṽéđ ƀý çóášŧîñǧ ·······⟧';

  @override
  String get fuelBreakdownEfficient => '⟦Ñóřɱáł đřîṽîñǧ ······⟧';

  @override
  String fuelBreakdownLiters(String liters) {
    return '⟦$liters Ł⟧';
  }

  @override
  String get ecoNudgeIdle =>
      '⟦Îđłîñǧ ƒóř á ŵĥîłé — šŵîŧçĥîñǧ ŧĥé éñǧîñé óƒƒ šáṽéš ƒúéł ····················⟧';

  @override
  String get ecoNudgeHarshAccel =>
      '⟦Šŧřóñǧ áççéłéřáŧîóñ — á ǧéñŧłéř ƥéđáł šáṽéš ƒúéł ··················⟧';

  @override
  String get ecoNudgeHighRpm =>
      '⟦Ĥîǧĥ řéṽš áŧ çřúîšé — šĥîƒŧîñǧ úƥ éářłîéř šáṽéš ƒúéł ···················⟧';

  @override
  String get obd2CoverageNoneNote =>
      '⟦Ñó éñǧîñé đáŧá ářřîṽéđ ƒřóɱ ŧĥé ÓƁĐ2 áđáƥŧéř óñ ŧĥîš ŧřîƥ — ƒúéł ƒîǧúřéš ářé ǦƤŠ-ƀášéđ éšŧîɱáŧéš. ···································⟧';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return '⟦Éñǧîñé đáŧá šŧóƥƥéđ $percent% îñŧó ŧĥé ŧřîƥ (çóññéçŧîóñ đřóƥƥéđ) — ƒúéł ƒîǧúřéš áƒŧéř ŧĥáŧ ƥóîñŧ ářé ǦƤŠ-ƀášéđ éšŧîɱáŧéš. ·········································⟧';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return '⟦Éñǧîñé đáŧá çóṽéřéđ óñłý $percent% óƒ ŧĥîš ŧřîƥ — ǧáƥš úšé ǦƤŠ-ƀášéđ éšŧîɱáŧéš. ·························⟧';
  }

  @override
  String get favoritesShareAction => '⟦Šĥářé ··⟧';

  @override
  String favoritesShareSubject(String date) {
    return '⟦Šƥářķîłó — ƒáṽóúřîŧéš óñ $date ·········⟧';
  }

  @override
  String get favoritesShareError =>
      '⟦Çóúłđñ\'ŧ ǧéñéřáŧé šĥářé îɱáǧé ···········⟧';

  @override
  String get featureManagementSectionTitle => '⟦Ƒéáŧúřé ɱáñáǧéɱéñŧ ········⟧';

  @override
  String get featureManagementSectionSubtitle =>
      '⟦Ŧúřñ îñđîṽîđúáł ƒéáŧúřéš óñ óř óƒƒ. Šóɱé ƒéáŧúřéš đéƥéñđ óñ óŧĥéřš — šŵîŧçĥéš ářé đîšáƀłéđ úñŧîł ƥřéřéɋúîšîŧéš ářé ɱéŧ. ············································⟧';

  @override
  String get featureLabel_obd2TripRecording => '⟦ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ·······⟧';

  @override
  String get featureDescription_obd2TripRecording =>
      '⟦Çáƥŧúřé ŧřîƥš áúŧóɱáŧîçáłłý óṽéř ÓƁĐ2. ··············⟧';

  @override
  String get featureLabel_gamification => '⟦Ǧáɱîƒîçáŧîóñ ·····⟧';

  @override
  String get featureDescription_gamification =>
      '⟦Đřîṽîñǧ šçóřéš áñđ éářñéđ ƀáđǧéš. ·············⟧';

  @override
  String get featureLabel_hapticEcoCoach => '⟦Ĥáƥŧîç éçó-çóáçĥ ······⟧';

  @override
  String get featureDescription_hapticEcoCoach =>
      '⟦Řéáł-ŧîɱé ĥáƥŧîç ƒééđƀáçķ đúřîñǧ á ŧřîƥ. ···············⟧';

  @override
  String get featureLabel_tankSync => '⟦ŦáñķŠýñç ····⟧';

  @override
  String get featureDescription_tankSync =>
      '⟦Çřóšš-đéṽîçé šýñç ṽîá Šúƥáƀášé. ············⟧';

  @override
  String get featureLabel_consumptionAnalytics =>
      '⟦Çóñšúɱƥŧîóñ áñáłýŧîçš ·········⟧';

  @override
  String get featureDescription_consumptionAnalytics =>
      '⟦Ƒîłł-úƥ áñđ ŧřîƥ áñáłýšîš ŧáƀ. ···········⟧';

  @override
  String get featureLabel_baselineSync => '⟦Ɓášéłîñé šýñç ·····⟧';

  @override
  String get featureDescription_baselineSync =>
      '⟦Šýñç đřîṽîñǧ ƀášéłîñéš ṽîá ŦáñķŠýñç. ··············⟧';

  @override
  String get featureLabel_priceAlerts => '⟦Ƥřîçé áłéřŧš ·····⟧';

  @override
  String get featureDescription_priceAlerts =>
      '⟦Ŧĥřéšĥółđ-ƀášéđ ƥřîçé-đřóƥ ñóŧîƒîçáŧîóñš. ················⟧';

  @override
  String get featureLabel_priceHistory => '⟦Ƥřîçé ĥîšŧóřý ·····⟧';

  @override
  String get featureDescription_priceHistory =>
      '⟦30-đáý ƥřîçé çĥářŧš óñ šŧáŧîóñ đéŧáîłš. ··············⟧';

  @override
  String get featureLabel_routePlanning => '⟦Řóúŧé ƥłáññîñǧ ······⟧';

  @override
  String get featureDescription_routePlanning =>
      '⟦Çĥéáƥéšŧ šŧóƥ áłóñǧ ýóúř řóúŧé. ············⟧';

  @override
  String get featureLabel_evCharging => '⟦ÉṼ çĥářǧîñǧ ·····⟧';

  @override
  String get featureDescription_evCharging =>
      '⟦Çĥářǧîñǧ šŧáŧîóñš ṽîá ÓƥéñÇĥářǧéṀáƥ. ··············⟧';

  @override
  String get featureLabel_glideCoach => '⟦Ǧłîđé-çóáçĥ ·····⟧';

  @override
  String get featureDescription_glideCoach =>
      '⟦Ĥýƥéřɱîłîñǧ ǧúîđáñçé úšîñǧ ÓŠṀ ŧřáƒƒîç šîǧñáłš. ··················⟧';

  @override
  String get featureLabel_gpsTripPath => '⟦ǦƤŠ ŧřîƥ ƥáŧĥ ·····⟧';

  @override
  String get featureDescription_gpsTripPath =>
      '⟦Ƥéřšîšŧ ǦƤŠ ƥáŧĥ šáɱƥłéš áłóñǧšîđé éáçĥ ŧřîƥ. ·················⟧';

  @override
  String get featureLabel_autoRecord => '⟦Áúŧó-řéçóřđ ·····⟧';

  @override
  String get featureDescription_autoRecord =>
      '⟦Áúŧóɱáŧîçáłłý šŧářŧ á ŧřîƥ ŵĥéñ ŧĥé ÓƁĐ2 áđáƥŧéř çóññéçŧš ŧó á ɱóṽîñǧ ṽéĥîçłé. ·····························⟧';

  @override
  String get featureLabel_showFuel => '⟦Šĥóŵ ƒúéł šŧáŧîóñš ·······⟧';

  @override
  String get featureDescription_showFuel =>
      '⟦Đîšƥłáý ƥéŧřół/đîéšéł šŧáŧîóñ řéšúłŧš îñ šéářçĥ áñđ óñ ŧĥé ɱáƥ. ·······················⟧';

  @override
  String get featureLabel_showElectric => '⟦Šĥóŵ çĥářǧîñǧ šŧáŧîóñš ·········⟧';

  @override
  String get featureDescription_showElectric =>
      '⟦Đîšƥłáý ÉṼ çĥářǧîñǧ šŧáŧîóñš îñ šéářçĥ áñđ óñ ŧĥé ɱáƥ. ····················⟧';

  @override
  String get featureLabel_showConsumptionTab => '⟦Çóñšúɱƥŧîóñ ŧáƀ ······⟧';

  @override
  String get featureDescription_showConsumptionTab =>
      '⟦Šĥóŵ ŧĥé çóñšúɱƥŧîóñ áñáłýŧîçš ŧáƀ îñ ŧĥé ƀóŧŧóɱ ñáṽîǧáŧîóñ. ·······················⟧';

  @override
  String get featureBlockedEnable_gamification =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureBlockedEnable_baselineSync =>
      '⟦Éñáƀłé ŦáñķŠýñç ƒîřšŧ ·········⟧';

  @override
  String get featureBlockedEnable_glideCoach =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureBlockedEnable_autoRecord =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureLabel_tflitePricePrediction =>
      '⟦Ɓéšŧ ŧîɱé ŧó ƒîłł úƥ ·······⟧';

  @override
  String get featureDescription_tflitePricePrediction =>
      '⟦Óñ-đéṽîçé ǧúîđáñçé óñ ŵĥéñ ŧó ƒîłł úƥ, çóɱƥúŧéđ ƒřóɱ ýóúř łóçáł ƥřîçé ĥîšŧóřý — ñóŧĥîñǧ łéáṽéš ŧĥé đéṽîçé. ······································⟧';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      '⟦Éñáƀłé ƥřîçé ĥîšŧóřý ƒîřšŧ ··········⟧';

  @override
  String get featureLabel_fuelCalculator => '⟦Ƒúéł çáłçúłáŧóř ······⟧';

  @override
  String get featureDescription_fuelCalculator =>
      '⟦Řéáçĥáƀłé ƒúéł-çóšŧ çáłçúłáŧóř ƒřóɱ ŧĥé šéářçĥ řéšúłŧš. ·····················⟧';

  @override
  String get featureLabel_carbonDashboard => '⟦Çářƀóñ đášĥƀóářđ ·······⟧';

  @override
  String get featureDescription_carbonDashboard =>
      '⟦ÇÓ2 ƒóóŧƥřîñŧ đášĥƀóářđ řéáçĥáƀłé ƒřóɱ ŧĥé Çóñšúɱƥŧîóñ ŧáƀ. ·······················⟧';

  @override
  String get featureLabel_experimentalOemPids =>
      '⟦Éẋƥéřîɱéñŧáł ÓÉṀ ƤÎĐš ·········⟧';

  @override
  String get featureDescription_experimentalOemPids =>
      '⟦Řéáđ éẋáçŧ ŧáñķ łîŧřéš ṽîá ɱáñúƒáçŧúřéř-šƥéçîƒîç ƤÎĐš óñ šúƥƥóřŧéđ áđáƥŧéřš. ·····························⟧';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      '⟦Éñáƀłé ÓƁĐ2 ŧřîƥ řéçóřđîñǧ ƒîřšŧ ············⟧';

  @override
  String get featureLabel_paymentQrScan => '⟦Šçáñ ƥáýɱéñŧ ɊŘ ······⟧';

  @override
  String get featureDescription_paymentQrScan =>
      '⟦Šçáñ-ŧó-ƥáý ɊŘ řéáđéř óñ ŧĥé šŧáŧîóñ đéŧáîł šçřééñ. ··················⟧';

  @override
  String get featureLabel_communityPriceReports =>
      '⟦Çóɱɱúñîŧý ƥřîçé řéƥóřŧš ·········⟧';

  @override
  String get featureDescription_communityPriceReports =>
      '⟦Řéƥóřŧ á šŧáŧîóñ ƥřîçé ƒřóɱ ŧĥé šŧáŧîóñ đéŧáîł šçřééñ. ····················⟧';

  @override
  String get featureLabel_obd2Optional =>
      '⟦Řéɋúîřé ÓƁĐ2 ƒóř ŧřîƥ řéçóřđîñǧ ············⟧';

  @override
  String get featureDescription_obd2Optional =>
      '⟦Ŵĥéñ óƒƒ, ŧĥé áƥƥ řéçóřđš ǦƤŠ-óñłý ŧřáĵéŧš ŵîŧĥóúŧ ñééđîñǧ áñ ÓƁĐ2 áđáƥŧéř. Çóáçĥîñǧ îš řéđúçéđ — ñó îñšŧáñŧ Ł/100 ķɱ, ƒéŵéř éñǧîñé-đéřîṽéđ šîǧñáłš. ···················································⟧';

  @override
  String get featureLabel_addFillUpOcrReceipt => '⟦Řéçéîƥŧ ÓÇŘ ·····⟧';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      '⟦Šçáñ á ƥřîñŧéđ řéçéîƥŧ óñ ŧĥé Áđđ ƒîłł-úƥ šçřééñ ŧó ƥřé-ƒîłł đáŧé, łîŧřéš, ŧóŧáł, áñđ šŧáŧîóñ. ·································⟧';

  @override
  String get featureLabel_developerPatToken =>
      '⟦Đéṽéłóƥéř ƒééđƀáçķ (ǦîŧĤúƀ ƤÁŦ) ············⟧';

  @override
  String get featureDescription_developerPatToken =>
      '⟦Éñáƀłé ŧĥé ƀáđ-šçáñ ƒééđƀáçķ ƥáñéł ŧĥáŧ áúŧó-ƒîłéš ǦîŧĤúƀ îššúéš ŵîŧĥ á Ƥéřšóñáł Áççéšš Ŧóķéñ. Ƥóŵéř-úšéř / çóñŧřîƀúŧóř ƒéáŧúřé. ···············································⟧';

  @override
  String get featureLabel_debugMode => '⟦Đéṽéłóƥéř / Đéƀúǧ ɱóđé ········⟧';

  @override
  String get featureDescription_debugMode =>
      '⟦Šúřƒáçé á Đéṽéłóƥéř ŧóółš šéçŧîóñ îñ Šéŧŧîñǧš ŵîŧĥ đîáǧñóšŧîçš: éřřóř-łóǧ éẋƥóřŧ, ŧéšŧ ñóŧîƒîçáŧîóñš, á ŧéšŧ-áłéřŧ ƥîƥéłîñé řúñ, á ƒéáŧúřé-ƒłáǧ đúɱƥ, çłéář çáçĥéš, áñđ çóƥý đîáǧñóšŧîçš. ····································································⟧';

  @override
  String get featureLabel_approachOverlay => '⟦Ƒúéł Šŧáŧîóñ Řáđář ·······⟧';

  @override
  String get featureDescription_approachOverlay =>
      '⟦Ŧúřñ ŧĥé ƒłóáŧîñǧ ŧřîƥ ŧîłé îñŧó á łîṽé Ƒúéł Šŧáŧîóñ Řáđář — áš ýóú ñéář á ƒúéł šŧáŧîóñ îŧ ƒłîƥš ŧó ŧĥé ƒúéł ŧýƥé\'š çółóúř áñđ šĥóŵš ŧĥé ƥřîçé. ··················································⟧';

  @override
  String get featureLabel_voiceAnnouncements =>
      '⟦Ṽóîçé áññóúñçéɱéñŧš ········⟧';

  @override
  String get featureDescription_voiceAnnouncements =>
      '⟦Šƥéáķ ñéářƀý çĥéáƥ ƒúéł šŧáŧîóñš áłóúđ áš ýóú đřîṽé, šó ýóú çáñ ķééƥ ýóúř éýéš óñ ŧĥé řóáđ. ································⟧';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      '⟦Éñáƀłé ŧĥé Ƒúéł Šŧáŧîóñ Řáđář ƒîřšŧ ··············⟧';

  @override
  String get featureGroupTitle_finding => '⟦Ƒîñđîñǧ & ɱáƥ ·····⟧';

  @override
  String get featureGroupDescription_finding =>
      '⟦Ŵĥéřé ŧó ƒúéł úƥ óř çĥářǧé — šéářçĥ, ɱáƥ, řóúŧîñǧ. ·················⟧';

  @override
  String get featureGroupTitle_prices => '⟦Ƥřîçéš & áłéřŧš ·····⟧';

  @override
  String get featureGroupDescription_prices =>
      '⟦Ƥřîçé đřóƥš, ĥîšŧóřý, áñđ řéƥóřŧîñǧ. ·············⟧';

  @override
  String get featureGroupTitle_radar => '⟦Ƒúéł Šŧáŧîóñ Řáđář ·······⟧';

  @override
  String get featureGroupDescription_radar =>
      '⟦Łîṽé ƥřîçé ñúđǧéš áš ýóú đřîṽé. ···········⟧';

  @override
  String get featureGroupTitle_sync => '⟦Šýñç & ƀáçķúƥ ·····⟧';

  @override
  String get featureGroupDescription_sync =>
      '⟦Ķééƥ ýóúř đáŧá áçřóšš đéṽîçéš. ···········⟧';

  @override
  String get featureGroupTitle_input => '⟦Îñƥúŧ & šçáññîñǧ ······⟧';

  @override
  String get featureGroupDescription_input =>
      '⟦Ĥéłƥéřš ƒóř łóǧǧîñǧ ƒîłł-úƥš. ···········⟧';

  @override
  String get featureGroupTitle_developer =>
      '⟦Đéṽéłóƥéř & éẋƥéřîɱéñŧáł ·········⟧';

  @override
  String get featureGroupDescription_developer =>
      '⟦Ƥóŵéř-úšéř áñđ çóñŧřîƀúŧóř ŧóółš. ·············⟧';

  @override
  String get featureLabel_voiceFeedback =>
      '⟦Šƥóķéñ ƒééđƀáçķ (ŧéẋŧ-ŧó-šƥééçĥ) ············⟧';

  @override
  String get featureDescription_voiceFeedback =>
      '⟦Ṁášŧéř šŵîŧçĥ ƒóř éṽéřý šƥóķéñ šúřƒáçé — ŧĥé đřîṽîñǧ ṽóîçé çóáçĥ áñđ šŧáŧîóñ áññóúñçéɱéñŧš. Ŵĥéñ óƒƒ, ŧĥé áƥƥ ñéṽéř óƥéñš á ŧéẋŧ-ŧó-šƥééçĥ éñǧîñé. ·····················································⟧';

  @override
  String get feedbackConsentTitle => '⟦Šéñđ řéƥóřŧ ŧó ǦîŧĤúƀ? ········⟧';

  @override
  String get feedbackConsentBody =>
      '⟦Ŧĥîš çřéáŧéš á ƥúƀłîç ŧîçķéŧ óñ óúř ǦîŧĤúƀ řéƥóšîŧóřý ŵîŧĥ ýóúř ƥĥóŧó áñđ ŧĥé ÓÇŘ ŧéẋŧ. Ñó ƥéřšóñáł đáŧá (łóçáŧîóñ, áççóúñŧ îđ) îš šéñŧ. Çóñŧîñúé? ····················································⟧';

  @override
  String get feedbackConsentContinue => '⟦Çóñŧîñúé ····⟧';

  @override
  String get feedbackConsentCancel => '⟦Çáñçéł ···⟧';

  @override
  String get feedbackConsentLater => '⟦Łáŧéř ··⟧';

  @override
  String get feedbackTokenSectionTitle =>
      '⟦Ɓáđ-šçáñ ƒééđƀáçķ (ǦîŧĤúƀ) ·········⟧';

  @override
  String get feedbackTokenDescription =>
      '⟦Ŧó áúŧóɱáŧîçáłłý óƥéñ á ǦîŧĤúƀ ŧîçķéŧ ƒřóɱ á ƒáîłéđ šçáñ, ƥášŧé á ǦîŧĤúƀ ƤÁŦ (`ƥúƀłîç_řéƥó` šçóƥé óñ ŧĥé ŧáñķšŧéłłéñ řéƥóšîŧóřý). Óŧĥéřŵîšé ɱáñúáł šĥářîñǧ řéɱáîñš áṽáîłáƀłé. ·······························································⟧';

  @override
  String get feedbackTokenStatusSet => '⟦Ŧóķéñ çóñƒîǧúřéđ ·······⟧';

  @override
  String get feedbackTokenStatusUnset => '⟦Ñó ŧóķéñ ···⟧';

  @override
  String get feedbackTokenSet => '⟦Šéŧ ·⟧';

  @override
  String get feedbackTokenClear => '⟦Çłéář ··⟧';

  @override
  String get feedbackTokenDialogTitle => '⟦ǦîŧĤúƀ ƤÁŦ ····⟧';

  @override
  String get feedbackTokenFieldLabel => '⟦Ƥéřšóñáł Áççéšš Ŧóķéñ ·········⟧';

  @override
  String get fillUpMultiFuelHint =>
      '⟦Ŧĥîš ṽéĥîçłé çáñ úšé đîƒƒéřéñŧ ƒúéłš — łóǧ ŧĥé óñé ýóú áçŧúáłłý ƥúɱƥéđ ··························⟧';

  @override
  String get fillUpGuidanceTitle => '⟦Ɓéšŧ ŧîɱé ŧó ƒîłł úƥ ·······⟧';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return '⟦Ŧĥé çúřřéñŧ ƥřîçé îš áɱóñǧ ŧĥé çĥéáƥéšŧ óƒ ŧĥé łášŧ $days đáýš — á ǧóóđ ŧîɱé ŧó ƒîłł úƥ. ····························⟧';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return '⟦Ƥřîçéš ářé ñéář ŧĥéîř $days-đáý ĥîǧĥ. Ŧĥéý ářé úšúáłłý çĥéáƥéř $window — çóñšîđéř ŵáîŧîñǧ. ···························⟧';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      '⟦Ƥřîçéš ářé ŧřéñđîñǧ úƥ — çóñšîđéř ƒîłłîñǧ úƥ šóóñ. ··················⟧';

  @override
  String fillUpGuidanceNeutral(int days) {
    return '⟦Ŧóđáý\'š ƥřîçé îš ářóúñđ ŧĥé $days-đáý áṽéřáǧé. ··············⟧';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return '⟦Çóúłđ šáṽé áƀóúŧ $amount/Ł ƀý ŧîɱîñǧ ýóúř ƒîłł-úƥ. ···············⟧';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count price readings',
      one: 'Based on 1 price reading',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '⟦$day $part⟧';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return '⟦óñ $day ·⟧';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '⟦îñ ŧĥé $part ··⟧';
  }

  @override
  String get fillUpGuidanceWindowGeneric => '⟦áŧ óŧĥéř ŧîɱéš ·····⟧';

  @override
  String get fillUpGuidanceWeekday1 => '⟦Ṁóñđáýš ···⟧';

  @override
  String get fillUpGuidanceWeekday2 => '⟦Ŧúéšđáýš ····⟧';

  @override
  String get fillUpGuidanceWeekday3 => '⟦Ŵéđñéšđáýš ·····⟧';

  @override
  String get fillUpGuidanceWeekday4 => '⟦Ŧĥúřšđáýš ····⟧';

  @override
  String get fillUpGuidanceWeekday5 => '⟦Ƒřîđáýš ···⟧';

  @override
  String get fillUpGuidanceWeekday6 => '⟦Šáŧúřđáýš ····⟧';

  @override
  String get fillUpGuidanceWeekday7 => '⟦Šúñđáýš ···⟧';

  @override
  String get fillUpGuidancePartEarlyMorning => '⟦éářłý ɱóřñîñǧš ······⟧';

  @override
  String get fillUpGuidancePartMorning => '⟦ɱóřñîñǧš ····⟧';

  @override
  String get fillUpGuidancePartAfternoon => '⟦áƒŧéřñóóñš ·····⟧';

  @override
  String get fillUpGuidancePartEvening => '⟦éṽéñîñǧš ····⟧';

  @override
  String get fillUpGuidancePartNight => '⟦ñîǧĥŧš ···⟧';

  @override
  String get fillUpOdometerFromCarJustNow =>
      '⟦Ƒřóɱ ýóúř çář · ĵúšŧ ñóŵ ········⟧';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return '⟦Ƒřóɱ ýóúř çář · $when ·····⟧';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return '⟦Éšŧîɱáŧéđ ƒřóɱ ýóúř çář\'š łášŧ řéáđîñǧ ƥłúš ŧĥé đîšŧáñçé đřîṽéñ šîñçé ($when) ··························⟧';
  }

  @override
  String get fillUpImportPasteLabel => '⟦Ƥášŧé ŧéẋŧ ····⟧';

  @override
  String get pasteReceiptDialogTitle => '⟦Ƥášŧé řéçéîƥŧ ŧéẋŧ ·······⟧';

  @override
  String get pasteReceiptDialogHint =>
      '⟦Ƥášŧé ŧĥé ŧéẋŧ óƒ á ƒúéł řéçéîƥŧ — é-ɱáîł, ŠṀŠ, óř á šĥářéđ ƤĐƑ. Ŧĥé łîŧřéš, ƥřîçé ƥéř łîŧřé, ƒúéł ǧřáđé, ŧóŧáł áñđ šŧáŧîóñ ářé řéáđ óñ-đéṽîçé áñđ úšéđ ŧó ƥřé-ƒîłł ŧĥé ƒóřɱ. Ñóŧĥîñǧ îš šéñŧ ŧó á šéřṽéř. ····································································⟧';

  @override
  String get pasteReceiptFieldHint => '⟦Řéçéîƥŧ ŧéẋŧ ·····⟧';

  @override
  String get pasteReceiptParseAction => '⟦Ƥřé-ƒîłł ···⟧';

  @override
  String get pasteReceiptNoData =>
      '⟦Çóúłđñ\'ŧ řéáđ áñý ƒúéł đáŧá ƒřóɱ ŧĥáŧ ŧéẋŧ — çĥéçķ îŧ\'š á ƒúéł řéçéîƥŧ áñđ ŧřý áǧáîñ. ·····························⟧';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel =>
      '⟦Ṽéřîƒîéđ ƀý áđáƥŧéř ········⟧';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      '⟦Đóéšñ\'ŧ ɱáŧçĥ áđáƥŧéř řéáđîñǧ ···········⟧';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return '⟦Ýóúř éñŧřý: $userL Ł. Áđáƥŧéř šáýš: $adapterL Ł (đéłŧá ƒřóɱ ƀéƒóřé/áƒŧéř ƒúéł-łéṽéł çáƥŧúřé). Úšé áđáƥŧéř ṽáłúé? ·································⟧';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      '⟦Ķééƥ ɱý éñŧřý ·····⟧';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      '⟦Úšé áđáƥŧéř ṽáłúé ·······⟧';

  @override
  String get scanReceiptNoData =>
      '⟦Ñó řéçéîƥŧ đáŧá ƒóúñđ — ŧřý áǧáîñ ············⟧';

  @override
  String get scanReceiptSuccess =>
      '⟦Řéçéîƥŧ šçáññéđ — ṽéřîƒý ṽáłúéš. Ŧáƥ \"Řéƥóřŧ šçáñ éřřóř\" ƀéłóŵ îƒ áñýŧĥîñǧ îš óƒƒ. ·····························⟧';

  @override
  String scanReceiptFailed(String error) {
    return '⟦Šçáñ ƒáîłéđ: $error ·····⟧';
  }

  @override
  String get badScanReportTitleReceipt =>
      '⟦Řéƥóřŧ á šçáñ éřřóř — Řéçéîƥŧ ··········⟧';

  @override
  String get badScanReportHint =>
      '⟦Ŵé\'łł šĥářé ŧĥé řéçéîƥŧ ƥĥóŧó áñđ ƀóŧĥ šéŧš óƒ ṽáłúéš šó ŧĥé ñéẋŧ ƀúîłđ çáñ łéářñ ŧĥîš łáýóúŧ. ··································⟧';

  @override
  String get badScanReportFieldBrandLayout => '⟦Ɓřáñđ łáýóúŧ ·····⟧';

  @override
  String get badScanReportFieldTotal => '⟦Ŧóŧáł ··⟧';

  @override
  String get badScanReportFieldPricePerLiter => '⟦Ƥřîçé/Ł ···⟧';

  @override
  String get badScanReportFieldStation => '⟦Šŧáŧîóñ ···⟧';

  @override
  String get badScanReportFieldFuel => '⟦Ƒúéł ··⟧';

  @override
  String get badScanReportFieldDate => '⟦Đáŧé ··⟧';

  @override
  String get badScanReportHeaderField => '⟦Ƒîéłđ ··⟧';

  @override
  String get badScanReportHeaderScanned => '⟦Šçáññéđ ···⟧';

  @override
  String get badScanReportHeaderYouTyped => '⟦Ýóú ŧýƥéđ ····⟧';

  @override
  String get badScanReportCreateTicket => '⟦Çřéáŧé îššúé ·····⟧';

  @override
  String get badScanReportOpenInBrowser => '⟦Óƥéñ îñ ƀřóŵšéř ······⟧';

  @override
  String get badScanReportFallbackToShare =>
      '⟦Šúƀɱîššîóñ ƒáîłéđ — ɱáñúáł šĥářé ············⟧';

  @override
  String get fillUpWarningDialogTitle => '⟦Çĥéçķ ŧĥîš ƒîłł-úƥ ·······⟧';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return '⟦Ýóú ƥîçķéđ $chosenFuel, ƀúŧ ŧĥîš ṽéĥîçłé řúñš óñ $vehicleFuel. ·············⟧';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return '⟦Óđóɱéŧéř $entered ķɱ îš ƀéłóŵ ŧĥé ƥřéṽîóúš ƒîłł-úƥ\'š $previous ķɱ — đîšŧáñçé çáñ\'ŧ ǧó ƀáçķŵářđš. ···························⟧';
  }

  @override
  String get fillUpWarningGoBack => '⟦Ǧó ƀáçķ áñđ ƒîẋ ·····⟧';

  @override
  String get fillUpWarningSaveAnyway => '⟦Šáṽé áñýŵáý ·····⟧';

  @override
  String get fillUpSectionWhatTitle => '⟦Ŵĥáŧ ýóú ƒîłłéđ ······⟧';

  @override
  String get fillUpSectionWhatSubtitle => '⟦Ƒúéł, áɱóúñŧ, ƥřîçé ·······⟧';

  @override
  String get fillUpSectionWhereTitle => '⟦Ŵĥéřé ýóú ŵéřé ·····⟧';

  @override
  String get fillUpSectionWhereSubtitle =>
      '⟦Šŧáŧîóñ, óđóɱéŧéř, ñóŧéš ·········⟧';

  @override
  String get fillUpImportReceiptLabel => '⟦Řéçéîƥŧ ···⟧';

  @override
  String get fillUpPricePerLiterLabel => '⟦Ƥřîçé ƥéř łîŧéř ······⟧';

  @override
  String get vehicleHeaderUntitled => '⟦Ñéŵ ṽéĥîçłé ·····⟧';

  @override
  String get vehicleSectionIdentityTitle => '⟦Îđéñŧîŧý ····⟧';

  @override
  String get vehicleSectionIdentitySubtitle => '⟦Ñáɱé & ṼÎÑ ···⟧';

  @override
  String get vehicleSectionDrivetrainTitle => '⟦Đřîṽéŧřáîñ ·····⟧';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      '⟦Ĥóŵ ŧĥîš ṽéĥîçłé ɱóṽéš ·········⟧';

  @override
  String get profileSectionDisplayStations => '⟦Đîšƥłáý & šŧáŧîóñš ·······⟧';

  @override
  String get profileSectionRegion => '⟦Řéǧîóñ ···⟧';

  @override
  String get fuelEfficiencyCardTitle =>
      '⟦Çóšŧ ƥéř ķîłóɱéŧřé ƀý ƒúéł ··········⟧';

  @override
  String get fuelEfficiencyCardSubtitle =>
      '⟦Ŵĥîçĥ ƒúéł ɱîẋ îš áçŧúáłłý çĥéáƥéšŧ ŧó đřîṽé óñ ··················⟧';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return '⟦Çĥéáƥéšŧ ƥéř ķɱ: $fuel ($costPerKm) ······⟧';
  }

  @override
  String get fuelEfficiencyPureBadge => '⟦Ƥúřé ··⟧';

  @override
  String get fuelEfficiencyMixBadge => '⟦Ɓłéñđ ··⟧';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return '⟦Ṁóšŧłý $fuel ···⟧';
  }

  @override
  String get fuelEfficiencyColL100km => '⟦Ł/100ķɱ ·⟧';

  @override
  String get fuelEfficiencyColCostPerKm => '⟦Çóšŧ/ķɱ ···⟧';

  @override
  String get fuelEfficiencyColTotalSpent => '⟦Ŧóŧáł šƥéñŧ ·····⟧';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills',
      one: '1 fill',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full tanks',
      one: '1 full tank',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      '⟦Łóǧ áŧ łéášŧ ŧŵó ƒúłł ŧáñķš ƥéř çóɱƥóšîŧîóñ ŧó çřóŵñ ŧĥé çĥéáƥéšŧ. ························⟧';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      '⟦Ŧáñķš ářé ǧřóúƥéđ ƀý çóɱƥóšîŧîóñ: á ŧáñķ îš ƥúřé ŵĥéñ óñé ƒúéł îš áŧ łéášŧ 85% óƒ îŧ, óŧĥéřŵîšé á ƀłéñđ. ···································⟧';

  @override
  String get fuelNameE5 => '⟦Šúƥéř É5 ···⟧';

  @override
  String get fuelNameE10 => '⟦Šúƥéř É10 ···⟧';

  @override
  String get fuelNameE98 => '⟦Šúƥéř 98 ··⟧';

  @override
  String get fuelNameDiesel => '⟦Đîéšéł ···⟧';

  @override
  String get fuelNameDieselPremium => '⟦Đîéšéł Ƥřéɱîúɱ ······⟧';

  @override
  String get fuelNameE85 => '⟦É85 Ɓîóéŧĥáñół ·····⟧';

  @override
  String get fuelNameLpg => '⟦ŁƤǦ ·⟧';

  @override
  String get fuelNameCng => '⟦ÇÑǦ ·⟧';

  @override
  String get fuelNameHydrogen => '⟦Ĥýđřóǧéñ ····⟧';

  @override
  String get fuelNameElectric => '⟦Éłéçŧřîç ····⟧';

  @override
  String get calibrationModeLabel => '⟦Çáłîƀřáŧîóñ ɱóđé ·······⟧';

  @override
  String get calibrationModeRule => '⟦Řúłé-ƀášéđ ····⟧';

  @override
  String get calibrationModeFuzzy => '⟦Ƒúžžý ··⟧';

  @override
  String get calibrationModeTooltip =>
      '⟦Řúłé-ƀášéđ áššîǧñš éáçĥ đřîṽîñǧ šáɱƥłé ŧó éẋáçŧłý óñé šîŧúáŧîóñ. Ƒúžžý šƥřéáđš îŧ áçřóšš áłł óƒ ŧĥéɱ ƀý ĥóŵ ŵéłł éáçĥ ƒîŧš — šɱóóŧĥéř ářóúñđ 60 ķɱ/ĥ óř çĥáñǧîñǧ ǧřáđîéñŧš, ƀúŧ šłóŵéř ŧó ƒîłł áłł ƀúçķéŧš. ········································································⟧';

  @override
  String get profileGamificationToggleTitle =>
      '⟦Šĥóŵ áçĥîéṽéɱéñŧš & šçóřéš ··········⟧';

  @override
  String get profileGamificationToggleSubtitle =>
      '⟦Ŵĥéñ óƒƒ, ƀáđǧéš, šçóřéš áñđ ŧřóƥĥý îçóñš ářé ĥîđđéñ áçřóšš ŧĥé áƥƥ. ························⟧';

  @override
  String gdprPolicyLink(int version) {
    return '⟦Ƥřîṽáçý ƥółîçý (ṽéřšîóñ $version) ·········⟧';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return '⟦Çóñšéñŧ ǧîṽéñ óñ $date · ƥółîçý ṽéřšîóñ $version ············⟧';
  }

  @override
  String get consentNotRecorded => '⟦Ñó çóñšéñŧ řéçóřđéđ ýéŧ ·········⟧';

  @override
  String serverErasurePartial(String tables) {
    return '⟦Šóɱé šéřṽéř đáŧá çóúłđ ñóŧ ƀé éřášéđ: $tables. Řéŧřý, óř çóñŧáçŧ ŧĥé đéṽéłóƥéř ŵîŧĥ ŧĥîš łîšŧ. ·······························⟧';
  }

  @override
  String localErasurePartial(String steps) {
    return '⟦Šóɱé łóçáł đáŧá çóúłđ ñóŧ ƀé éřášéđ: $steps. Řéšŧářŧ ŧĥé áƥƥ áñđ řéŧřý. ·······················⟧';
  }

  @override
  String get myCommunityReportsTitle => '⟦Ṁý çóɱɱúñîŧý řéƥóřŧš ········⟧';

  @override
  String get myCommunityReportsEmpty =>
      '⟦Ýóú ĥáṽé ñóŧ šúƀɱîŧŧéđ áñý řéƥóřŧš ·············⟧';

  @override
  String get deleteReportTooltip => '⟦Đéłéŧé ŧĥîš řéƥóřŧ ·······⟧';

  @override
  String get reportDeleted => '⟦Řéƥóřŧ đéłéŧéđ ······⟧';

  @override
  String get reportDeleteFailed => '⟦Çóúłđ ñóŧ đéłéŧé ŧĥé řéƥóřŧ ··········⟧';

  @override
  String get tileProxyToggleTitle =>
      '⟦Řóúŧé ɱáƥ ŧîłéš ŧĥřóúǧĥ ŧĥé Šƥářķîłó ƥřóẋý ················⟧';

  @override
  String get tileProxyToggleSubtitle =>
      '⟦Óñ: ŧĥé ɱáƥ ṽîéŵƥóřŧ áñđ ýóúř ÎƤ áđđřéšš řéáçĥ ŧĥé đéṽéłóƥéř\'š ÉÚ šéřṽéř, ŵĥîçĥ ƒéŧçĥéš ŧĥé ŧîłéš ƒřóɱ ÓƥéñŠŧřééŧṀáƥ. Óƒƒ: ŧîłéš łóáđ ƒřóɱ ŧîłé.óƥéñšŧřééŧɱáƥ.óřǧ đîřéçŧłý. ·······························································⟧';

  @override
  String get remoteLogosToggleTitle =>
      '⟦Łóáđ ƀřáñđ łóǧóš ƒřóɱ ŧĥé îñŧéřñéŧ ·············⟧';

  @override
  String get remoteLogosToggleSubtitle =>
      '⟦Óƒƒ ƀý đéƒáúłŧ: ƀúñđłéđ ƥłáçéĥółđéřš ářé šĥóŵñ. Óñ: łóǧóš ářé ƒéŧçĥéđ ƒřóɱ łóǧó.çłéářƀîŧ.çóɱ, ŵĥîçĥ šééš ýóúř ÎƤ áđđřéšš. ············································⟧';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '⟦Šáṽéđ $fileName ŧó Đóŵñłóáđš — $count ƒîłéš îñšîđé ············⟧';
  }

  @override
  String get privacyExportAllFailed =>
      '⟦Çóúłđ ñóŧ ŵřîŧé ŧĥé éẋƥóřŧ ƒîłé ············⟧';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return '⟦Óƥéřáŧéđ ƀý $operator · Šúƥáƀášé, ÉÚ (Ƒřáñķƒúřŧ) · šýñçš ƒáṽóřîŧéš, áłéřŧš, ṽéĥîçłéš îñçł. ṼÎÑ, ƒîłł-úƥš, řáŧîñǧš, řéƥóřŧš áñđ — îƒ ýóú éñáƀłé îŧ — ŧřîƥš ŵîŧĥ ǦƤŠ ···················································⟧';
  }

  @override
  String get syncModePrivateControllerNotice =>
      '⟦Ýóú ářé ŧĥé çóñŧřółłéř — ýóúř óŵñ Šúƥáƀášé ƥřóĵéçŧ, ŵé ñéṽéř šéé îŧ ························⟧';

  @override
  String get syncModeJoinControllerNotice =>
      '⟦Ŧĥé ƥéřšóñ ŵĥó óŵñš ŧĥé šĥářéđ đáŧáƀášé îš ŧĥé çóñŧřółłéř óƒ ýóúř đáŧá ··························⟧';

  @override
  String get ugcPublicNoticeTitle => '⟦Šĥářéđ ŵîŧĥ óŧĥéř úšéřš ·········⟧';

  @override
  String get ugcPublicNoticeBody =>
      '⟦Ŧĥîš îš šŧóřéđ îñ ŧĥé šýñç đáŧáƀášé úñđéř ýóúř ƥšéúđóñýɱóúš úšéř ÎĐ. Îñ Šƥářķîłó Çóɱɱúñîŧý éṽéřý šîǧñéđ-îñ úšéř çáñ řéáđ îŧ. Ýóú çáñ đéłéŧé îŧ áñý ŧîɱé ƒřóɱ ŦáñķŠýñç → Đáŧá Ŧřáñšƥářéñçý. ····································································⟧';

  @override
  String get blockedAuthorsTitle => '⟦Ɓłóçķéđ úšéřš ·····⟧';

  @override
  String get blockedAuthorsDescription =>
      '⟦Çóñŧéñŧ šĥářéđ ƀý ŧĥéšé úšéřš îš ĥîđđéñ óñ ŧĥîš đéṽîçé. Úñƀłóçķ ŧó šéé îŧ áǧáîñ. ·····························⟧';

  @override
  String get blockedAuthorsEmpty => '⟦Ñó ƀłóçķéđ úšéřš ······⟧';

  @override
  String get blockedAuthorsUnblock => '⟦Úñƀłóçķ ···⟧';

  @override
  String get coachingGpsLiftOff => '⟦Łîƒŧ óƒƒ ···⟧';

  @override
  String get coachingGpsAnticipateBrake => '⟦Áñŧîçîƥáŧé ·····⟧';

  @override
  String get coachingGpsSmoothAccel => '⟦Šɱóóŧĥ áççéł ·····⟧';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return '⟦Ŧřáçķ çóṽéřš $pct% — łóñǧéšŧ ǧáƥ $gap ($cause) ·········⟧';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return '⟦Ŧřáçķ çóṽéřš $pct% — ñó ǧáƥš đéŧéçŧéđ ···········⟧';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => '⟦áƥƥ îñ ƀáçķǧřóúñđ ·······⟧';

  @override
  String get gpsCoverageAttrOsBatching => '⟦ÓŠ ƒîẋ ƀáŧçĥîñǧ ······⟧';

  @override
  String get gpsCoverageAttrGateRejected => '⟦ƒîẋéš ƒîłŧéřéđ ······⟧';

  @override
  String get gpsCoverageAttrDeliveryStall => '⟦đéłáýéđ đéłîṽéřý ·······⟧';

  @override
  String get gpsCoverageAttrSignalLoss => '⟦šîǧñáł łóšš ·····⟧';

  @override
  String get gpsCoverageAttrUnknown => '⟦úñķñóŵñ çáúšé ·····⟧';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      '⟦Ŧĥé áƥƥ ŵáš îñ ŧĥé ƀáçķǧřóúñđ ŵîŧĥóúŧ á ƒóřéǧřóúñđ šéřṽîçé, šó ŧĥé šýšŧéɱ ŧĥřóŧŧłéđ ǦƤŠ. Ķééƥ ŧĥé šçřééñ óñ ŵĥîłé řéçóřđîñǧ, óř éñáƀłé ƀáçķǧřóúñđ řéçóřđîñǧ ŵĥéñ áṽáîłáƀłé. ·······························································⟧';

  @override
  String get gpsCoverageHintOsBatching =>
      '⟦Ŧĥé šýšŧéɱ đéłîṽéřéđ ƥóšîŧîóñ ƒîẋéš łáŧé îñ ƀáŧçĥéš; ŧĥé ŧřáçķ ƒîłłéđ îñ áƒŧéřŵářđš, šó łîŧŧłé đáŧá ŵáš áçŧúáłłý łóšŧ. ············································⟧';

  @override
  String get gpsCoverageHintGateRejected =>
      '⟦Ñóîšý ƥóšîŧîóñ ƒîẋéš îñ ŧĥîš šŧřéŧçĥ ŵéřé ƒîłŧéřéđ óúŧ ŧó ķééƥ ŧĥé đîšŧáñçé ƒîǧúřé ĥóñéšŧ. ··································⟧';

  @override
  String get gpsCoverageHintDeliveryStall =>
      '⟦Ƥóšîŧîóñ ƒîẋéš ŵéřé ƥřóđúçéđ óñ ŧîɱé ƀúŧ řéáçĥéđ ŧĥé áƥƥ łáŧé — ŧĥé ƥĥóñé ŵáš ƀúšý (óƒŧéñ á Ɓłúéŧóóŧĥ řéçóññéçŧ). Řéçéƥŧîóñ ŵáš ƒîñé. ················································⟧';

  @override
  String get gpsCoverageHintSignalLoss =>
      '⟦ǦƤŠ řéçéƥŧîóñ đřóƥƥéđ — ŧĥîš úšúáłłý ɱéáñš á ŧúññéł, ƥářķîñǧ ǧářáǧé óř đéñšé úřƀáñ çáñýóñ. ·································⟧';

  @override
  String get gpsCoverageHintUnknown =>
      '⟦Ŧĥîš ŧřîƥ çářřîéš ñó áƥƥ-łîƒéçýçłé îñƒóřɱáŧîóñ ƒóř ŧĥé ǧáƥ, šó ŧĥé çáúšé çáñ\'ŧ ƀé đéŧéřɱîñéđ. ··································⟧';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      '⟦ÓƁĐ2 řéçóññéçŧîóñ îñŧéřƒéřéñçé ············⟧';

  @override
  String get gpsCoverageHintLinkRecovery =>
      '⟦Ŧĥé ǧáƥ çóîñçîđéš ŵîŧĥ áñ ÓƁĐ2 řéçóññéçŧîóñ éƥîšóđé — ŧĥé áđáƥŧéř łîñķ ŵáš řéçóṽéřîñǧ ŵĥîłé ǦƤŠ îñǧéšŧ šŧáłłéđ. Ƒîẋîñǧ ŧĥé áđáƥŧéř çóññéçŧîóñ áłšó ƒîẋéš ŧĥé ŧřáçķ. ····························································⟧';

  @override
  String get gpsDiagnosticsTitle => '⟦ǦƤŠ šáɱƥłîñǧ đîáǧñóšŧîçš ··········⟧';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps gaps',
      one: '1 gap',
      zero: 'no gaps',
    );
    return '⟦$count šáɱƥłéš · $span · $_temp0 ···⟧';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return '⟦Ṁéđîáñ îñŧéřṽáł: $ms ɱš ·······⟧';
  }

  @override
  String get gpsDiagnosticsExplain =>
      '⟦Çáƥŧúřéđ đúřîñǧ řéçóřđîñǧ ŧó ṽéřîƒý ǦƤŠ çáđéñçé úñđéř ƥĥóñé-šłééƥ. ·························⟧';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return '⟦Łářǧéšŧ ǧáƥ: $seconds š ·····⟧';
  }

  @override
  String get gpsLifecycleResumed => '⟦Řéšúɱéđ ···⟧';

  @override
  String get gpsLifecyclePaused => '⟦Ƥáúšéđ ···⟧';

  @override
  String get gpsLifecycleInactive => '⟦Îñáçŧîṽé ····⟧';

  @override
  String get gpsKpiVerdictGood => '⟦Éƒƒîçîéñŧ ····⟧';

  @override
  String get gpsKpiVerdictModerate => '⟦Ṁóđéřáŧé ····⟧';

  @override
  String get gpsKpiVerdictAggressive => '⟦Áǧǧřéššîṽé ·····⟧';

  @override
  String get gpsKpiInterpretationGood =>
      '⟦Šɱóóŧĥ, éñéřǧý-łîǧĥŧ đřîṽîñǧ — ŧĥîš îš ŵĥáŧ éƒƒîçîéñŧ łóóķš łîķé. ·······················⟧';

  @override
  String get gpsKpiInterpretationModerate =>
      '⟦Ƒáîřłý ŧýƥîçáł đřîṽîñǧ — á łîŧŧłé šɱóóŧĥéř óñ ŧĥé ŧĥřóŧŧłé ŵóúłđ šáṽé ɱóřé. ···························⟧';

  @override
  String get gpsKpiInterpretationAggressive =>
      '⟦Éñéřǧý-ĥéáṽý đřîṽîñǧ — éášîñǧ óƒƒ ŧĥé áççéłéřáŧóř áñđ çóášŧîñǧ ɱóřé ŵóúłđ çúŧ ƒúéł úšé. ································⟧';

  @override
  String get gpsMatrixMaturityCold => '⟦Çółđ ··⟧';

  @override
  String get gpsMatrixMaturityWarming => '⟦Ŵářɱîñǧ ···⟧';

  @override
  String get gpsMatrixMaturityConverged => '⟦Çóñṽéřǧéđ ····⟧';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return '⟦ǦƤŠ ɱáŧřîẋ îš šŧîłł ŵářɱîñǧ úƥ ($count ƒîłł-úƥ řéƒîñéɱéñŧš šó ƒář). Éšŧîɱáŧéš ářé ƥřóṽîšîóñáł. ································⟧';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return '⟦ǦƤŠ ɱáŧřîẋ îš çóñṽéřǧîñǧ ($count ƒîłł-úƥš). Éšŧîɱáŧéš ářé úšáƀłé ƀúŧ ɱáý đřîƒŧ á ƒéŵ %. ···························⟧';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return '⟦ǦƤŠ ɱáŧřîẋ ĥáš çóñṽéřǧéđ ($count ƒîłł-úƥš). Éšŧîɱáŧéš ářé ŵîŧĥîñ ~2 % óƒ řéáł-ŵóřłđ ƀúřñ. ···························⟧';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      '⟦ǦƤŠ éšŧîɱáŧé (~) — ñó ƒúéł šéñšóř óñ ŧĥîš ŧřîƥ. Ŧĥé ƒîǧúřé îš ɱóđéłłéđ ƒřóɱ šƥééđ áñđ ýóúř ṽéĥîçłé\'š çáłîƀřáŧîóñ; áççúřáçý îɱƥřóṽéš áš ŧĥé ɱáŧřîẋ ɱáŧúřéš. ······················································⟧';

  @override
  String get gpsRoadUseCardTitle => '⟦Ĥóŵ ýóú úšéđ ŧĥé řóáđ ········⟧';

  @override
  String get gpsRoadUseSpeedSection => '⟦Ŵĥéřé ýóú šƥéñŧ ýóúř ŧîɱé ·········⟧';

  @override
  String get gpsRoadUseSpeedIdle => '⟦Šŧóƥƥéđ (<5 ķɱ/ĥ) ·····⟧';

  @override
  String get gpsRoadUseSpeedLow => '⟦Ŧóŵñ (5–50 ķɱ/ĥ) ···⟧';

  @override
  String get gpsRoadUseSpeedCruise => '⟦Çřúîšé (50–110 ķɱ/ĥ) ····⟧';

  @override
  String get gpsRoadUseSpeedHigh => '⟦Ƒášŧ (≥110 ķɱ/ĥ) ···⟧';

  @override
  String get gpsRoadUsePhaseSection => '⟦Ĥóŵ ýóú ɱóṽéđ ·····⟧';

  @override
  String get gpsRoadUsePhaseAccel => '⟦Áççéłéřáŧîñǧ ·····⟧';

  @override
  String get gpsRoadUsePhaseSteady => '⟦Ĥółđîñǧ šƥééđ ·····⟧';

  @override
  String get gpsRoadUsePhaseCoast => '⟦Çóášŧîñǧ ····⟧';

  @override
  String gpsRoadUseShare(String pct) {
    return '⟦$pct%⟧';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      '⟦Łóŧš óƒ çóášŧîñǧ — łéŧŧîñǧ ŧĥé çář řółł îñšŧéáđ óƒ ƀřáķîñǧ šáṽéš ƒúéł. Ñîçé. ···························⟧';

  @override
  String get gpsRoadUseSource => '⟦Ƒřóɱ ýóúř ǦƤŠ ŧřáçķ ·······⟧';

  @override
  String get hapticEcoCoachSettingTitle => '⟦Řéáł-ŧîɱé éçó çóáçĥîñǧ ·········⟧';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      '⟦Ǧéñŧłé ĥáƥŧîç + óñ-šçřééñ ŧîƥ ŵĥéñ ýóú ƒłóóř îŧ đúřîñǧ çřúîšé ······················⟧';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      '⟦Éášý óñ ŧĥé ŧĥřóŧŧłé — çóášŧîñǧ šáṽéš ɱóřé ···············⟧';

  @override
  String highwayViaExit(String ref, String km) {
    return '⟦ṽîá éẋîŧ $ref · +$km ķɱ ····⟧';
  }

  @override
  String semanticsNavigateTo(String name) {
    return '⟦Ñáṽîǧáŧé ŧó $name ·····⟧';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return '⟦Řéɱóṽé $name ƒřóɱ ƒáṽóřîŧéš ·········⟧';
  }

  @override
  String get showOnMapSemanticLabel => '⟦Šĥóŵ šŧáŧîóñš óñ ɱáƥ ········⟧';

  @override
  String get searchResultsSemanticLabel => '⟦Šéářçĥ řéšúłŧš ······⟧';

  @override
  String get searchCriteriaSemanticLabel =>
      '⟦Šéářçĥ çřîŧéřîá šúɱɱářý. Ŧáƥ ŧó éđîŧ. ··············⟧';

  @override
  String get noFavoritesSemanticLabel =>
      '⟦Ñó ƒáṽóřîŧéš ýéŧ. Ŧáƥ ŧĥé šŧář óñ á šŧáŧîóñ ŧó šáṽé îŧ áš á ƒáṽóřîŧé. ························⟧';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Station is open',
      'false': 'Station is closed',
      'other': 'Station is closed',
    });
    return '⟦$_temp0⟧';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Country $name, selected',
      'false': 'Country $name',
      'other': 'Country $name',
    });
    return '⟦$_temp0⟧';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Language $name, selected',
      'false': 'Language $name',
      'other': 'Language $name',
    });
    return '⟦$_temp0⟧';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sort by $option, selected',
      'false': 'Sort by $option',
      'other': 'Sort by $option',
    });
    return '⟦$_temp0⟧';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Fuel type $type, selected',
      'false': 'Fuel type $type',
      'other': 'Fuel type $type',
    });
    return '⟦$_temp0⟧';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return '⟦ÉṼ çĥářǧîñǧ šŧáŧîóñ $name, $power ķŴ ·········⟧';
  }

  @override
  String get shieldIllustrationSemantic =>
      '⟦Ƥřîṽáçý šĥîéłđ ŵîŧĥ ƒúéł đřóƥ ···········⟧';

  @override
  String get globeIllustrationSemantic =>
      '⟦Ǧłóƀé ŵîŧĥ ƒúéł šŧáŧîóñ ɱářķéřš ············⟧';

  @override
  String get fuelPumpIllustrationSemantic =>
      '⟦Ƒúéł ƥúɱƥ ŵîŧĥ ƥřîçé ŧîçķéř ··········⟧';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '⟦$name, đáŧá šóúřçé: $provider, $keyRequirement, ƒúéł ŧýƥéš: $fuelTypes ·········⟧';
  }

  @override
  String get countryInfoApiKeyRequired => '⟦ÁƤÎ ķéý řéɋúîřéđ ······⟧';

  @override
  String get countryInfoNoKeyNeeded => '⟦Ƒřéé, ñó ķéý ñééđéđ ·······⟧';

  @override
  String countryInfoDataSource(String provider) {
    return '⟦Đáŧá: $provider ··⟧';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return '⟦Ƒúéł ŧýƥéš: $fuelTypes ····⟧';
  }

  @override
  String get countryInfoDemoSource => '⟦Đéɱó ··⟧';

  @override
  String get anonKeyLabel => '⟦Áñóñ Ķéý ···⟧';

  @override
  String get anonKeyHideTooltip => '⟦Ĥîđé ķéý ···⟧';

  @override
  String get anonKeyShowTooltip => '⟦Šĥóŵ ķéý ŧó ṽéřîƒý ·······⟧';

  @override
  String anonKeyTooLong(int length) {
    return '⟦Ķéý îš ŧóó łóñǧ ($length çĥářš) — çĥéçķ ƒóř éẋŧřá ŧéẋŧ ···············⟧';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return '⟦Ķéý łóóķš çóřřéçŧ ($length çĥářš) ·········⟧';
  }

  @override
  String get anonKeyShouldBeJwt =>
      '⟦Ķéý šĥóúłđ ƀé á ĴŴŦ (ĥéáđéř.ƥáýłóáđ.šîǧñáŧúřé) ·················⟧';

  @override
  String anonKeyMayBeTruncated(int length) {
    return '⟦Ķéý ɱáý ƀé ŧřúñçáŧéđ ($length óƒ ~208 éẋƥéçŧéđ çĥářš) ··············⟧';
  }

  @override
  String get anonKeyExceedsMax => '⟦Ķéý éẋçééđš ɱáẋîɱúɱ łéñǧŧĥ ··········⟧';

  @override
  String get qrShareTitle => '⟦Šĥářé ýóúř đáŧáƀášé ········⟧';

  @override
  String get qrShareSubtitle =>
      '⟦Óŧĥéřš çáñ šçáñ ŧĥîš ɊŘ çóđé ŧó çóññéçŧ ··············⟧';

  @override
  String get qrShareCopyAsText => '⟦Çóƥý áš ŧéẋŧ ·····⟧';

  @override
  String get authInfoTitle => '⟦Ŵĥý çřéáŧé áñ áççóúñŧ? ········⟧';

  @override
  String get authInfoBenefit1 =>
      '⟦• Šýñç ƒáṽóřîŧéš, řáŧîñǧš, áłéřŧš, îǧñóřéđ šŧáŧîóñš, šáṽéđ řóúŧéš, ṽéĥîçłéš, ƒúéł łóǧš áñđ ŧřîƥš áçřóšš đéṽîçéš ········································⟧';

  @override
  String get authInfoBenefit2 =>
      '⟦• Ƥřéƥářé á řóúŧé óñ ýóúř ƥĥóñé, úšé îŧ îñ ýóúř çář ·················⟧';

  @override
  String get authInfoBenefit3 =>
      '⟦• Ñó đáŧá îš šĥářéđ ŵîŧĥ ŧĥîřđ ƥářŧîéš ··············⟧';

  @override
  String get authInfoBenefit4 =>
      '⟦• Ýóú çáñ đéłéŧé ýóúř áççóúñŧ áŧ áñý ŧîɱé ··············⟧';

  @override
  String get apiKeySetupTitle => '⟦ÁƤÎ ķéý šéŧúƥ (óƥŧîóñáł) ·········⟧';

  @override
  String get apiKeySetupDescription =>
      '⟦Řéǧîšŧéř ƒóř á ƒřéé ÁƤÎ ķéý, óř šķîƥ ŧó éẋƥłóřé ŧĥé áƥƥ ŵîŧĥ đéɱó đáŧá. ·························⟧';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '⟦$provider Řéǧîšŧřáŧîóñ ·····⟧';
  }

  @override
  String apiKeyTerms(String provider) {
    return '⟦Ɓý éñŧéřîñǧ áñ ÁƤÎ ķéý ýóú áççéƥŧ ŧĥé ŧéřɱš óƒ $provider. Đáŧá řéđîšŧřîƀúŧîóñ îš ƥřóĥîƀîŧéđ. ······························⟧';
  }

  @override
  String get calculatorDistanceHint => '⟦é.ǧ. 150 ·⟧';

  @override
  String get calculatorConsumptionHint => '⟦é.ǧ. 7.0 ·⟧';

  @override
  String get calculatorPriceHint => '⟦é.ǧ. 1.899 ·⟧';

  @override
  String get glideCoachBetaTitle =>
      '⟦Ǧłîđé-çóáçĥ ƀéŧá (éẋƥéřîɱéñŧáł) ············⟧';

  @override
  String get glideCoachBetaSubtitle =>
      '⟦Šúƀŧłé ĥáƥŧîç ŵĥéñ šłóŵîñǧ đóŵñ áĥéáđ óƒ á řéđ łîǧĥŧ. Óƒƒ ƀý đéƒáúłŧ — đîšŧřáçŧîóñ řîšķ. ································⟧';

  @override
  String get consentSyncTripsTitle => '⟦Šýñç ŧřîƥ řéçóřđîñǧš ········⟧';

  @override
  String get consentSyncTripsSubtitle =>
      '⟦Ɓáçķ úƥ ÓƁĐ2 + ǦƤŠ ŧřîƥš ŧó ŦáñķŠýñç. Çřóšš-đéṽîçé, óƥŧ-îñ. ···················⟧';

  @override
  String get consentSyncTripsDisabledHint =>
      '⟦Éñáƀłé Çłóúđ Šýñç áƀóṽé ŧó ƀáçķ úƥ ŧřîƥš. ···············⟧';

  @override
  String get consentSyncTripsAnonymousHint =>
      '⟦Ŧřîƥš ƀáçķ úƥ úñđéř ŧĥîš đéṽîçé\'š áñóñýɱóúš áççóúñŧ. Šîǧñ îñ ŵîŧĥ áñ éɱáîł ŧó řéáçĥ ŧĥéɱ ƒřóɱ óŧĥéř đéṽîçéš. ·······································⟧';

  @override
  String get dialogOk => '⟦ÓĶ ·⟧';

  @override
  String get invalidLinkTitle => '⟦Îñṽáłîđ łîñķ ·····⟧';

  @override
  String invalidLinkBody(String path) {
    return '⟦Ŧĥé łîñķ \"$path\" îš ñóŧ ṽáłîđ. ········⟧';
  }

  @override
  String get home => '⟦Ĥóɱé ··⟧';

  @override
  String get accelBrakeCardTitle => '⟦Áççéłéřáŧîóñ & ƀřáķîñǧ ·········⟧';

  @override
  String get accelBrakeHardAccel => '⟦Ĥářđ áççéłéřáŧîóñš ········⟧';

  @override
  String get accelBrakeHardBrake => '⟦Ĥářđ ƀřáķîñǧ ·····⟧';

  @override
  String get accelBrakeSharpCorner => '⟦Šĥářƥ çóřñéřš ·····⟧';

  @override
  String get accelBrakeSource =>
      '⟦Ƒřóɱ ŧĥé ƥĥóñé\'š ɱóŧîóñ šéñšóřš ············⟧';

  @override
  String lessonHardBrake(String count) {
    return '⟦$count ĥářđ ƀřáķîñǧ éṽéñŧš ········⟧';
  }

  @override
  String get lessonAdviceHardBrake =>
      '⟦Áñŧîçîƥáŧé šŧóƥš áñđ éášé óƒƒ ŧĥé áççéłéřáŧóř éářłîéř — ĥářđ ƀřáķîñǧ ŧĥřóŵš áŵáý ŧĥé ƒúéł ýóú ĵúšŧ šƥéñŧ ǧéŧŧîñǧ úƥ ŧó šƥééđ. ··············································⟧';

  @override
  String lessonSharpCornering(String count) {
    return '⟦$count šĥářƥ çóřñéřš ·····⟧';
  }

  @override
  String get lessonAdviceSharpCornering =>
      '⟦Šłóŵ ƀéƒóřé ŧĥé ƀéñđ, ñóŧ îñ îŧ — ĥářđ çóřñéřîñǧ šçřúƀš óƒƒ šƥééđ ýóú ŧĥéñ ĥáṽé ŧó řéƀúîłđ. ································⟧';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return '⟦Łášŧ $seconds š ··⟧';
  }

  @override
  String get consumptionUnitSettingTitle => '⟦Çóñšúɱƥŧîóñ úñîŧ ·······⟧';

  @override
  String get consumptionUnitSettingSubtitle =>
      '⟦Ĥóŵ ƒúéł çóñšúɱƥŧîóñ îš šĥóŵñ éṽéřýŵĥéřé îñ ŧĥé áƥƥ ···················⟧';

  @override
  String consumptionUnitAuto(String unit) {
    return '⟦Áúŧóɱáŧîç ($unit) ····⟧';
  }

  @override
  String get consumptionWindowSettingTitle =>
      '⟦Łîṽé çóñšúɱƥŧîóñ ŵîñđóŵ ·········⟧';

  @override
  String get consumptionWindowSettingSubtitle =>
      '⟦Áṽéřáǧé ŧĥé łîṽé ƒîǧúřé óṽéř ŧĥé łášŧ ƒéŵ šéçóñđš — łóñǧéř îš šŧéáđîéř, šĥóřŧéř řéáçŧš ƒášŧéř ··································⟧';

  @override
  String consumptionWindowOption(int seconds) {
    return '⟦$seconds š⟧';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return '⟦éšŧ. $unit ·⟧';
  }

  @override
  String get locationConsentTitle => '⟦Łóçáŧîóñ Áççéšš ······⟧';

  @override
  String get locationConsentSubtitle =>
      '⟦Ŧĥîš áƥƥ ŵóúłđ łîķé ŧó úšé ýóúř łóçáŧîóñ ŧó ƒîñđ ƒúéł šŧáŧîóñš ñéář ýóú. ··························⟧';

  @override
  String get locationConsentWhatHappens =>
      '⟦Ŵĥáŧ ĥáƥƥéñš ŵîŧĥ ýóúř łóçáŧîóñ đáŧá: ··············⟧';

  @override
  String get locationConsentBulletApi =>
      '⟦Ýóúř çóóřđîñáŧéš ářé šéñŧ ŧó ŧĥé ƒúéł ƥřîçé ÁƤÎ ŧó ƒîñđ ñéářƀý šŧáŧîóñš. ···························⟧';

  @override
  String get locationConsentBulletNoServer =>
      '⟦Ýóúř łóçáŧîóñ îš ñóŧ šŧóřéđ óñ áñý šéřṽéř — ŧĥéřé îš ñó šéřṽéř. ······················⟧';

  @override
  String get locationConsentBulletNoTracking =>
      '⟦Łóçáŧîóñ đáŧá îš ñóŧ úšéđ ƒóř áđṽéřŧîšîñǧ, áñáłýŧîçš, óř ŧřáçķîñǧ. ························⟧';

  @override
  String get locationConsentRevoke =>
      '⟦Ýóú çáñ řéṽóķé łóçáŧîóñ áççéšš áñýŧîɱé îñ šýšŧéɱ šéŧŧîñǧš. Áłŧéřñáŧîṽéłý, šéářçĥ ƀý ƥóšŧáł çóđé. ····································⟧';

  @override
  String get locationConsentLegalBasis =>
      '⟦Łéǧáł ƀášîš: Ářŧ. 6(1)(á) ǦĐƤŘ (Çóñšéñŧ) ···········⟧';

  @override
  String get loyaltySettingsTitle => '⟦Ƒúéł çłúƀ çářđš ······⟧';

  @override
  String get loyaltySettingsSubtitle =>
      '⟦Áƥƥłý ýóúř łóýáłŧý đîšçóúñŧ ŧó đîšƥłáýéđ ƥřîçéš ··················⟧';

  @override
  String get loyaltyMenuTitle => '⟦Ƒúéł çłúƀ çářđš ······⟧';

  @override
  String get loyaltyMenuSubtitle =>
      '⟦Áƥƥłý ƥéř-łîŧřé đîšçóúñŧš ƒřóɱ Ŧóŧáł, Ářáł, Šĥéłł, … ··················⟧';

  @override
  String get loyaltyAddCard => '⟦Áđđ çářđ ···⟧';

  @override
  String get loyaltyAddCardSheetTitle => '⟦Áđđ ƒúéł çłúƀ çářđ ·······⟧';

  @override
  String get loyaltyBrandLabel => '⟦Ɓřáñđ ··⟧';

  @override
  String get loyaltyCardLabelLabel => '⟦Łáƀéł (óƥŧîóñáł) ······⟧';

  @override
  String get loyaltyDiscountLabel => '⟦Đîšçóúñŧ (ƥéř łîŧřé) ·······⟧';

  @override
  String get loyaltyDiscountInvalid => '⟦Éñŧéř á ƥóšîŧîṽé ñúɱƀéř ·········⟧';

  @override
  String get loyaltyDeleteConfirmTitle => '⟦Đéłéŧé çářđ? ·····⟧';

  @override
  String get loyaltyDeleteConfirmBody =>
      '⟦Ŧĥîš çářđ ŵîłł šŧóƥ áƥƥłýîñǧ îŧš đîšçóúñŧ. ················⟧';

  @override
  String get loyaltyEmptyTitle => '⟦Ñó ƒúéł çłúƀ çářđš ýéŧ ········⟧';

  @override
  String get loyaltyEmptyBody =>
      '⟦Áđđ á çářđ ŧó áƥƥłý ýóúř ƥéř-łîŧřé đîšçóúñŧ ŧó ɱáŧçĥîñǧ šŧáŧîóñš áúŧóɱáŧîçáłłý. ······························⟧';

  @override
  String get loyaltyBadgePrefix => '⟦−⟧';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      '⟦Îđłé ŘƤṀ çřééƥ đéŧéçŧéđ ·········⟧';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return '⟦Îđłé ŘƤṀ ĥáš çřéƥŧ úƥ ƀý $percent% óṽéř ýóúř łášŧ $tripCount ŧřîƥš. Ƥóššîƀłé éářłý šîǧñ óƒ á çłóǧǧéđ áîř ƒîłŧéř óř šéñšóř đřîƒŧ. ······································⟧';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      '⟦Ƥóššîƀłé îñŧáķé řéšŧřîçŧîóñ ···········⟧';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return '⟦Çřúîšé ƒúéł řáŧé ĥáš đřóƥƥéđ ƀý $percent% óṽéř ýóúř łášŧ $tripCount ŧřîƥš. Ƥóššîƀłé šîǧñ óƒ á çłóǧǧéđ áîř ƒîłŧéř óř řéšŧřîçŧéđ îñŧáķé — ŵóřŧĥ á çĥéçķ-úƥ. ···············································⟧';
  }

  @override
  String get maintenanceActionDismiss => '⟦Đîšɱîšš ···⟧';

  @override
  String get maintenanceActionSnooze => '⟦Šñóóžé 30 đáýš ·····⟧';

  @override
  String get consumptionMonthlyInsightsTitle =>
      '⟦Ŧĥîš ɱóñŧĥ ṽš łášŧ ɱóñŧĥ ·········⟧';

  @override
  String get consumptionMonthlyTripsLabel => '⟦Ŧřîƥš ··⟧';

  @override
  String get consumptionMonthlyDriveTimeLabel => '⟦Đřîṽé ŧîɱé ····⟧';

  @override
  String get consumptionMonthlyDistanceLabel => '⟦Đîšŧáñçé ····⟧';

  @override
  String get consumptionMonthlyAvgConsumptionLabel =>
      '⟦Áṽǧ çóñšúɱƥŧîóñ ······⟧';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      '⟦Ñééđ áŧ łéášŧ 3 ŧřîƥš ƥéř ɱóñŧĥ ƒóř çóɱƥářîšóñ ·················⟧';

  @override
  String get consumptionMonthlyClimbLabel => '⟦Çłîɱƀéđ ···⟧';

  @override
  String get obd2CapabilitySectionTitle => '⟦Áđáƥŧéř çáƥáƀîłîŧîéš ·········⟧';

  @override
  String get obd2CapabilityStandardOnly => '⟦Šŧáñđářđ ····⟧';

  @override
  String get obd2CapabilityOemPids => '⟦ÓÉṀ ƤÎĐš ···⟧';

  @override
  String get obd2CapabilityFullCan => '⟦Ƒúłł ÇÁÑ ···⟧';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      '⟦Ƒóř éẋáçŧ łîŧřéš-îñ-ŧáñķ óñ Ƥéúǧéóŧ/Çîŧřóëñ, ŧĥé áƥƥ šúƥƥóřŧš ÓƁĐŁîñķ ṀẊ+/ŁẊ/ÇẊ (ŠŦÑ çĥîƥ). ·······························⟧';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      '⟦ÓƁĐ2 đîáǧñóšŧîç óṽéřłáý éñáƀłéđ ············⟧';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      '⟦ÓƁĐ2 đîáǧñóšŧîç óṽéřłáý đîšáƀłéđ ·············⟧';

  @override
  String get obd2DebugOverlayClearButton => '⟦Çłéář ··⟧';

  @override
  String get obd2DebugOverlayCloseButton => '⟦Çłóšé ··⟧';

  @override
  String get obd2DebugOverlayTitle => '⟦ÓƁĐ2 ƀřéáđçřúɱƀš ······⟧';

  @override
  String get obd2DiagnosticShareLabel => '⟦Šĥářé đîáǧñóšŧîç łóǧ ········⟧';

  @override
  String get obd2DebugLoggingTitle => '⟦ÓƁĐ2 đéƀúǧ łóǧǧîñǧ ·······⟧';

  @override
  String get obd2DebugLoggingSubtitle =>
      '⟦Řéçóřđ éáçĥ ÓƁĐ2 šéššîóñ — çóññéçŧîóñ, ĥáñđšĥáķé, đáŧá ǧáƥš áñđ řéçóññéçŧš — ŧó áñ éẋƥóřŧáƀłé ẊṀŁ łóǧ. Óƒƒ ƀý đéƒáúłŧ. ·········································⟧';

  @override
  String get obd2DebugSessionShareLabel => '⟦Šĥářé ÓƁĐ2 šéššîóñ łóǧ ········⟧';

  @override
  String get obd2DiagnosticsTitle => '⟦ÓƁĐ2 çóɱɱúñîçáŧîóñ ĥéáłŧĥ ··········⟧';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops drops',
      one: '1 drop',
      zero: 'no drops',
    );
    return '⟦$percent% çóɱƥłéŧé · $duty% đúŧý · $_temp0 ·····⟧';
  }

  @override
  String get obd2DiagnosticsAdapterSection => '⟦Áđáƥŧéř ···⟧';

  @override
  String get obd2DiagnosticsConnectionSection =>
      '⟦Çóññéçŧîóñ łîƒéçýçłé ·········⟧';

  @override
  String get obd2DiagnosticsPidSection => '⟦Ƥéř-ƤÎĐ óúŧçóɱéš ······⟧';

  @override
  String get obd2DiagnosticsReconnectSection =>
      '⟦Řéçóññéçŧ ŧéłéɱéŧřý ········⟧';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '⟦$attempts řéçóññéçŧ áŧŧéɱƥŧš · $successes óķ · $transitions ŧřáñšîŧîóñš · $disconnects ŧýƥéđ đřóƥš ··················⟧';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '⟦$reason: $count⟧';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      '⟦ǦƤŠ-óñłý ƒáłłƀáçķ áçŧîṽáŧéđ ŧĥîš šéššîóñ. ················⟧';

  @override
  String get obd2DiagnosticsSchedulerSection => '⟦Šçĥéđúłéř ĥéáłŧĥ ·······⟧';

  @override
  String get obd2DiagnosticsCompletenessSection => '⟦Çóɱƥłéŧéñéšš ·····⟧';

  @override
  String get obd2DiagnosticsSupportSection =>
      '⟦Đîšçóṽéřéđ-šúƥƥóřŧéđ ƤÎĐš ··········⟧';

  @override
  String get obd2DiagnosticsFuelSection => '⟦Ƒúéł-ŧîéř řółłúƥ ······⟧';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '⟦$mac · $firmware · ƥřóŧóçół $protocol · ṀŦÚ $mtu ·····⟧';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '⟦$attempts áŧŧéɱƥŧš · $successes óķ · $drops đřóƥš · ŧîɱé-ŧó-çóññéçŧ ƥ50 $p50 / ƥ95 $p95 ··············⟧';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return '⟦Řéçóññéçŧš: $silent šîłéñŧ · $visible ṽîšîƀłé ··········⟧';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '⟦$tickRate Ĥž ŧîçķ · $skips ƀáçķ-ƥřéššúřé šķîƥš · $demotions đéɱóŧîóñš ··············⟧';
  }

  @override
  String get obd2DiagnosticsStarved =>
      '⟦Đýñáɱîçš ŧîéř šŧářṽéđ — ŘƤṀ / šƥééđ ƒéłł ƀéłóŵ ŧĥé ǧóṽéřñóř ƒłóóř. ·······················⟧';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return '⟦Óṽéřáłł $percent% · áçŧîṽé đúŧý $duty% ········⟧';
  }

  @override
  String obd2DiagnosticsTierLine(String tier, String percent) {
    return '⟦$tier: $percent%⟧';
  }

  @override
  String obd2DiagnosticsSupportLine(
    int supported,
    int unsupported,
    int unknown,
  ) {
    return '⟦$supported šúƥƥóřŧéđ · $unsupported úñšúƥƥóřŧéđ · $unknown úñķñóŵñ ············⟧';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return '⟦Šúšƥîçîóúš $suspicious óƒ $total šáɱƥłéš ·········⟧';
  }

  @override
  String obd2DiagnosticsPidRow(
    String pid,
    int polled,
    int ok,
    int noData,
    int timeout,
    int error,
    int p50,
    int p95,
    String effectiveHz,
    String targetHz,
  ) {
    return '⟦$pid: $polled ƥółłéđ · $ok óķ · $noData ÑĐ · $timeout ŦÓ · $error éřř · ƥ50 $p50 / ƥ95 $p95 ɱš · $effectiveHz/$targetHz Ĥž ·········⟧';
  }

  @override
  String get obd2DiagnosticsInitSection => '⟦Đóñǧłé îñîŧ ŧřáñšçřîƥŧ ·········⟧';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return '⟦Ƥřóŧóçół $protocol · $start · ƒîřɱŵářé $firmware · $tier · $pids ƤÎĐš ·········⟧';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '⟦$cmd → $response ($latency ɱš) ·⟧';
  }

  @override
  String get obd2DiagnosticsInitWarm => '⟦ŵářɱ ··⟧';

  @override
  String get obd2DiagnosticsInitCold => '⟦çółđ ··⟧';

  @override
  String get obd2DiagnosticsEmpty =>
      '⟦Ñó ÓƁĐ2 çóɱɱ-ĥéáłŧĥ đéŧáîłš ƒóř ŧĥîš ŧřîƥ. Ŧĥé řéçóřđîñǧ îŧšéłƒ îš úñáƒƒéçŧéđ — çĥéçķ ŧĥé ŧřîƥ\'š óŵñ ÓƁĐ2 çóṽéřáǧé áƀóṽé. ···········································⟧';

  @override
  String get obd2DiagnosticsExplain =>
      '⟦Çáƥŧúřéđ ŵĥîłé řéçóřđîñǧ ŧó đéƀúǧ ŧĥé đóñǧłé↔áƥƥ çóɱɱúñîçáŧîóñ — óñłý çółłéçŧéđ îñ Đéṽéłóƥéř ɱóđé. ·····································⟧';

  @override
  String get obd2HealthScreenTitle => '⟦ÓƁĐ2 çóɱɱúñîçáŧîóñ ĥéáłŧĥ ··········⟧';

  @override
  String get obd2HealthNavLabel => '⟦ÓƁĐ2 çóɱɱúñîçáŧîóñ ĥéáłŧĥ ··········⟧';

  @override
  String get obd2HealthLiveSection => '⟦Łîṽé šéššîóñ ·····⟧';

  @override
  String get obd2HealthHistorySection => '⟦Řéçéñŧ šéššîóñš ······⟧';

  @override
  String get obd2HealthDownloadJson => '⟦Đóŵñłóáđ áš ĴŠÓÑ ······⟧';

  @override
  String get obd2HealthDownloadInitTranscript =>
      '⟦Đóŵñłóáđ îñîŧ ŧřáñšçřîƥŧ óñłý ············⟧';

  @override
  String get obd2HealthDownloadError =>
      '⟦Çóúłđñ\'ŧ šáṽé ŧĥé đîáǧñóšŧîçš ƒîłé ·············⟧';

  @override
  String get obd2TestAdapterLabel => '⟦Áđáƥŧéř ŧó ŧéšŧ ······⟧';

  @override
  String get obd2TestAdapterScanOption => '⟦Šçáñ ƒóř áđáƥŧéř ······⟧';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return '⟦Çóññéçŧ ŧó $adapter ····⟧';
  }

  @override
  String get obd2TestRunTitle => '⟦Řúñ áđáƥŧéř ŧéšŧ ······⟧';

  @override
  String get obd2TestRunButton => '⟦Řúñ áđáƥŧéř ŧéšŧ ······⟧';

  @override
  String get obd2TestRunPassed => '⟦Áđáƥŧéř ŧéšŧ ƥáššéđ ········⟧';

  @override
  String get obd2TestRunFailed => '⟦Áđáƥŧéř ŧéšŧ ƒáîłéđ ········⟧';

  @override
  String get obd2TestRunEngineOff =>
      '⟦Áđáƥŧéř ÓĶ — éñǧîñé óƒƒ; šŧářŧ ŧĥé éñǧîñé ŧó řéáđ łîṽé đáŧá ·····················⟧';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '⟦$passed óƒ $total šŧéƥš ÓĶ · $elapsed ɱš ·····⟧';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      '⟦Šŧóƥ ŧĥé áçŧîṽé řéçóřđîñǧ ƀéƒóřé řúññîñǧ ŧĥé áđáƥŧéř ŧéšŧ. ······················⟧';

  @override
  String get obd2TestStepScan => '⟦Šçáñ ƒóř áđáƥŧéř ······⟧';

  @override
  String get obd2TestStepBluetooth => '⟦Ƥĥóñé Ɓłúéŧóóŧĥ ······⟧';

  @override
  String get obd2TestStepConnect => '⟦Çóññéçŧ & îñîŧ ·····⟧';

  @override
  String get obd2TestStepInfo => '⟦Áđáƥŧéř îñƒó ·····⟧';

  @override
  String get obd2TestStepSupportedPids => '⟦Šúƥƥóřŧéđ ƤÎĐš ······⟧';

  @override
  String get obd2TestStepProtocol => '⟦Ṽéĥîçłé ƥřóŧóçół ·······⟧';

  @override
  String get obd2TestStepSampleReads => '⟦Šáɱƥłé řéáđš ·····⟧';

  @override
  String get obd2TestStepSoak => '⟦Šúšŧáîñéđ ƥółłîñǧ ·······⟧';

  @override
  String get obd2TestStepReconnect => '⟦Řéçóññéçŧ ŧéšŧ ······⟧';

  @override
  String get obd2TestStepDisconnect => '⟦Đîšçóññéçŧ ·····⟧';

  @override
  String get obd2TestStatusOk => '⟦ÓĶ ·⟧';

  @override
  String get obd2TestStatusTimeout => '⟦Ŧîɱéđ óúŧ ····⟧';

  @override
  String get obd2TestStatusGarbage => '⟦Úñřéáđáƀłé řéƥłý ·······⟧';

  @override
  String get obd2TestStatusNoResponse => '⟦Ñó řéšƥóñšé ·····⟧';

  @override
  String get obd2TestStatusFail => '⟦Ƒáîłéđ ···⟧';

  @override
  String get obd2TestAdapterTransportClassic => '⟦Çłáššîç (ŠƤƤ) ·····⟧';

  @override
  String get obd2TestAdapterTransportBle => '⟦Ɓłúéŧóóŧĥ ŁÉ ·····⟧';

  @override
  String get obd2TestAdapterTransportUnknown =>
      '⟦úñķñóŵñ — đéƒáúłŧîñǧ ŧó ƁŁÉ ··········⟧';

  @override
  String get obd2HealthConnectAttemptsSection =>
      '⟦Řéçéñŧ çóññéçŧ áŧŧéɱƥŧš ·········⟧';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      '⟦Ñó çóññéçŧ áŧŧéɱƥŧš řéçóřđéđ ýéŧ. ·············⟧';

  @override
  String get obd2HealthDownloadConnectTrace =>
      '⟦Đóŵñłóáđ çóññéçŧ ŧřáçé ·········⟧';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      '⟦Đóŵñłóáđ áłł çóññéçŧ ŧřáçéš ···········⟧';

  @override
  String get obd2HealthConnectOrigin => '⟦Óřîǧîñ ···⟧';

  @override
  String get obd2HealthConnectTransport => '⟦Ŧřáñšƥóřŧ ····⟧';

  @override
  String get obd2HealthConnectOutcome => '⟦Óúŧçóɱé ···⟧';

  @override
  String get obd2HealthConnectScanList => '⟦Šçáññéđ đéṽîçéš ······⟧';

  @override
  String get obd2HealthConnectSteps => '⟦Šŧéƥš ··⟧';

  @override
  String get obd2HealthConnectUnknownAdapter => '⟦Úñķñóŵñ áđáƥŧéř ······⟧';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return '⟦Šéššîóñ řéçóřđéđ · $samples éñǧîñé šáɱƥłéš · $percent% çóṽéřáǧé ················⟧';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection =>
      '⟦Ŵĥáŧ ŧĥîš ŧřîƥ řéçóřđéđ ·········⟧';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '⟦$samples óƒ $total šáɱƥłéš çářřîéđ éñǧîñé đáŧá ($percent%) ············⟧';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return '⟦Áđáƥŧéř: $adapter ···⟧';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return '⟦Ƥřóŧóçół ĥáñđšĥáķé: $verdict ········⟧';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return '⟦Šéššîóñ éñđéđ: $reason ·····⟧';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return '⟦Šéššîóñ łéñǧŧĥ: $duration ······⟧';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      '⟦Ƒúéł ƒîǧúřéš çáɱé ƒřóɱ ŧĥé áđáƥŧéř, ñóŧ ƒřóɱ ǦƤŠ éšŧîɱáŧéš. ······················⟧';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      '⟦Ŧĥé ƥéř-ƤÎĐ çóɱɱúñîçáŧîóñ ƀřéáķđóŵñ ŵáš ñóŧ çáƥŧúřéđ ƒóř ŧĥîš ŧřîƥ. Ŧúřñ óñ đéṽéłóƥéř ɱóđé ƀéƒóřé řéçóřđîñǧ ŧó çółłéçŧ îŧ. ·············································⟧';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return '⟦Çóúłđñ\'ŧ řéáçĥ \'$adapterName\' — ƥîçķ áñóŧĥéř áđáƥŧéř ··············⟧';
  }

  @override
  String get obd2PickerOtherDevices => '⟦Óŧĥéř Ɓłúéŧóóŧĥ đéṽîçéš ·········⟧';

  @override
  String get obd2PickerTapToTry => '⟦Úñřéçóǧñîžéđ — ŧáƥ ŧó ŧřý ·········⟧';

  @override
  String get obd2PickerBleOnlyNotice =>
      '⟦îƤĥóñé ŵóřķš ŵîŧĥ Ɓłúéŧóóŧĥ-ŁÉ áđáƥŧéřš óñłý. Á Çłáššîç-óñłý áđáƥŧéř (é.ǧ. ṽŁîñķéř ƁṀ, Ķóññŵéî ĶŴ902) ɱúšŧ ƀé úšéđ óñ Áñđřóîđ. ···········································⟧';

  @override
  String get obd2PairingConfirmHint =>
      '⟦Çóñƒîřɱ ŧĥé ƥáîřîñǧ řéɋúéšŧ óñ ýóúř ƥĥóñé ················⟧';

  @override
  String get obd2ScanEmptyTitle => '⟦Ñó áđáƥŧéř ƒóúñđ ······⟧';

  @override
  String get obd2ScanEmptyReady =>
      '⟦Ɓłúéŧóóŧĥ îš óñ áñđ ƥéřɱîššîóñš ářé ǧřáñŧéđ. Ṁáķé šúřé ŧĥé áđáƥŧéř îš ƥłúǧǧéđ îñŧó ŧĥé ÓƁĐ2 ƥóřŧ áñđ ŧĥé îǧñîŧîóñ îš óñ, ŧĥéñ šçáñ áǧáîñ. ·················································⟧';

  @override
  String get obd2ScanBlockedUnsupported =>
      '⟦Ŧĥîš đéṽîçé ĥáš ñó Ɓłúéŧóóŧĥ Łóŵ Éñéřǧý ĥářđŵářé, šó îŧ çáññóŧ çóññéçŧ ŧó áñ ÓƁĐ2 áđáƥŧéř. ································⟧';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      '⟦Ɓłúéŧóóŧĥ îš šŵîŧçĥéđ óƒƒ. Ŧúřñ îŧ óñ ŧó šçáñ ƒóř ýóúř áđáƥŧéř. ·······················⟧';

  @override
  String get obd2ScanBlockedPermission =>
      '⟦Šƥářķîłó ñééđš Ɓłúéŧóóŧĥ ƥéřɱîššîóñ ŧó ƒîñđ ýóúř áđáƥŧéř. ······················⟧';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      '⟦Ɓłúéŧóóŧĥ ƥéřɱîššîóñ ŵáš đéñîéđ ƥéřɱáñéñŧłý. Ǧřáñŧ îŧ îñ šýšŧéɱ šéŧŧîñǧš ŧó šçáñ ƒóř ýóúř áđáƥŧéř. ·····································⟧';

  @override
  String get obd2ScanBlockedLocationServices =>
      '⟦Łóçáŧîóñ šéřṽîçéš ářé šŵîŧçĥéđ óƒƒ óñ ŧĥîš đéṽîçé. Áñđřóîđ ñééđš ŧĥéɱ éñáƀłéđ ŧó šçáñ ƒóř Ɓłúéŧóóŧĥ áđáƥŧéřš — ñó łóçáŧîóñ îš řéçóřđéđ óř šĥářéđ. ······················································⟧';

  @override
  String get obd2ScanOpenSettings => '⟦Óƥéñ šéŧŧîñǧš ·····⟧';

  @override
  String get obd2WaitingForEngineBanner =>
      '⟦Ŵáîŧîñǧ ƒóř ŧĥé éñǧîñé — řéçóřđîñǧ óñ ǦƤŠ ···············⟧';

  @override
  String get obd2StartEngineToReconnect =>
      '⟦Šŧářŧ ŧĥé éñǧîñé ŧó řéçóññéçŧ ···········⟧';

  @override
  String get obd2ResetConnectionEngineOff =>
      '⟦Éñǧîñé îš óƒƒ — šŧářŧ îŧ ŧó řéçóññéçŧ ·············⟧';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return '⟦Éñǧîñé óƒƒ ƒóř $minutes ɱîñ — šŧóƥ řéçóřđîñǧ? ·············⟧';
  }

  @override
  String get obd2ParkedPromptStop => '⟦Šŧóƥ ··⟧';

  @override
  String get obd2ParkedPromptKeep => '⟦Ķééƥ ··⟧';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return '⟦Éñǧîñé óƒƒ ƒóř ŧĥé ƒîřšŧ $head áñđ ŧĥé łášŧ $tail óƒ ŧĥîš ŧřîƥ — çóṽéřáǧé îš ɱéášúřéđ ŵĥîłé ŧĥé éñǧîñé řáñ. ··································⟧';
  }

  @override
  String get obd2ReconnectInProgress =>
      '⟦Řéçóññéçŧîñǧ ŧó ýóúř ÓƁĐ2 áđáƥŧéř… ·············⟧';

  @override
  String get obd2StatusEngineOff => '⟦ÓƁĐ2 ƥáúšéđ — éñǧîñé óƒƒ ········⟧';

  @override
  String get obd2StatusEngineOffBody =>
      '⟦Ŧĥé áđáƥŧéř ŵáš řéáçĥáƀłé ƀúŧ ŧĥé ṽéĥîçłé ƀúš šŧáýéđ šîłéñŧ, šó áúŧóɱáŧîç řéçóññéçŧîóñ îš ƥáúšéđ. Îŧ řéšúɱéš ŵĥéñ ýóú đřîṽé óř řéóƥéñ ŧĥé áƥƥ — óř řéçóññéçŧ ñóŵ. ···························································⟧';

  @override
  String get obd2StatusReconnectNow => '⟦Řéçóññéçŧ ñóŵ ·····⟧';

  @override
  String get autoRecordNotificationTitle => '⟦Ŧřîƥ áúŧó-řéçóřđ ······⟧';

  @override
  String get autoRecordNotificationText =>
      '⟦Ŵáŧçĥîñǧ ƒóř ýóúř ÓƁĐ2 áđáƥŧéř ···········⟧';

  @override
  String get obd2ResetConnection => '⟦Řéšéŧ çóññéçŧîóñ ·······⟧';

  @override
  String get obd2ResetConnectionDone =>
      '⟦Áđáƥŧéř řéšéŧ — çóññéçŧîóñ řé-éšŧáƀłîšĥéđ ················⟧';

  @override
  String get obd2ResetConnectionNoLink =>
      '⟦Áđáƥŧéř řéšéŧ — řéçóññéçŧîñǧ îñ ŧĥé ƀáçķǧřóúñđ ··················⟧';

  @override
  String get ocrTesterTitle => '⟦ÓÇŘ ŧéšŧéř ····⟧';

  @override
  String get ocrTesterNavLabel => '⟦ÓÇŘ ŧéšŧéř ····⟧';

  @override
  String get ocrTesterExplain =>
      '⟦Řúñ ŧĥé ƥúɱƥ / řéçéîƥŧ ÓÇŘ ƥîƥéłîñé óñ á çĥóšéñ ƥĥóŧó áñđ îñšƥéçŧ éṽéřý šŧéƥ — óñłý áṽáîłáƀłé îñ Đéṽéłóƥéř ɱóđé. ········································⟧';

  @override
  String get ocrTesterCapture => '⟦Çáƥŧúřé ···⟧';

  @override
  String get ocrTesterPickImage => '⟦Ƥîçķ îɱáǧé ····⟧';

  @override
  String get ocrTesterRun => '⟦Řúñ ·⟧';

  @override
  String get ocrTesterCountry => '⟦Çóúñŧřý ···⟧';

  @override
  String get ocrTesterCountryNone => '⟦Đéƒáúłŧ (ñó ƥřóƒîłé) ·······⟧';

  @override
  String get ocrTesterNoImage =>
      '⟦Ƥîçķ óř çáƥŧúřé áñ îɱáǧé, ŧĥéñ Řúñ. ············⟧';

  @override
  String get ocrTesterRunning => '⟦Řúññîñǧ ÓÇŘ… ·····⟧';

  @override
  String get ocrTesterOverlaySection => '⟦Ɓłóçķ óṽéřłáý ·····⟧';

  @override
  String get ocrTesterStepsSection => '⟦Ƥîƥéłîñé šŧéƥš ······⟧';

  @override
  String get ocrTesterLegendLabel => '⟦Łáƀéł ··⟧';

  @override
  String get ocrTesterLegendNumeric => '⟦Ñúɱéřîç ···⟧';

  @override
  String get ocrTesterLegendNoise => '⟦Ñóîšé ··⟧';

  @override
  String get ocrTesterLegendDerived => '⟦Đéřîṽéđ ···⟧';

  @override
  String get ocrTesterStageGlare => '⟦Çáƥŧúřé / ǧłářé ·····⟧';

  @override
  String get ocrTesterStageMlkit => '⟦ṀŁ Ķîŧ ··⟧';

  @override
  String get ocrTesterStageClassify => '⟦Çłáššîƒý ····⟧';

  @override
  String get ocrTesterStageAssemble => '⟦Áššéɱƀłé ····⟧';

  @override
  String get ocrTesterStageAnchor => '⟦Áñçĥóř ···⟧';

  @override
  String get ocrTesterStageFallback => '⟦Ƒáłłƀáçķ ····⟧';

  @override
  String get ocrTesterStageCrossCheck => '⟦Çřóšš-çĥéçķ ·····⟧';

  @override
  String get ocrTesterStageConfidence => '⟦Çóñƒîđéñçé ·····⟧';

  @override
  String get ocrTesterStageGate => '⟦Ǧáŧé ··⟧';

  @override
  String get ocrTesterStageBrand => '⟦Ɓřáñđ ··⟧';

  @override
  String get ocrTesterStageOverrides => '⟦Óṽéřřîđéš ····⟧';

  @override
  String get ocrTesterStageReconcile => '⟦Řéçóñçîłé ····⟧';

  @override
  String get ocrTesterStageResult => '⟦Řéšúłŧ ···⟧';

  @override
  String get ocrTesterChipRead => '⟦ŘÉÁĐ ··⟧';

  @override
  String get ocrTesterChipDerived => '⟦ĐÉŘÎṼÉĐ ···⟧';

  @override
  String get ocrTesterGateAccepted => '⟦Áççéƥŧéđ ····⟧';

  @override
  String get ocrTesterGateRejected => '⟦Řéĵéçŧéđ ····⟧';

  @override
  String get ocrTesterFallbackBanner =>
      '⟦Á ƒîéłđ ŵáš řéçóṽéřéđ ṽîá ɱáǧñîŧúđé ƒáłłƀáçķ — ṽéřîƒý îŧ. ·····················⟧';

  @override
  String get ocrTesterStageNoData => '⟦Šŧáǧé đîđ ñóŧ řúñ. ······⟧';

  @override
  String get ocrTesterCopyJson => '⟦Çóƥý áš ĴŠÓÑ ·····⟧';

  @override
  String get ocrTesterExportPackage => '⟦Éẋƥóřŧ ƥáçķáǧé ······⟧';

  @override
  String get ocrTesterCopied => '⟦ÓÇŘ ŧřáçé çóƥîéđ ŧó çłîƥƀóářđ. ···········⟧';

  @override
  String get ocrTesterExported =>
      '⟦ÓÇŘ ƥáçķáǧé šáṽéđ ŧó ýóúř Đóŵñłóáđš ƒółđéř. ················⟧';

  @override
  String get onboardingObd2StepTitle => '⟦Çóññéçŧ ýóúř ÓƁĐ2 áđáƥŧéř ·········⟧';

  @override
  String get onboardingObd2StepBody =>
      '⟦Ƥłúǧ ýóúř ÓƁĐ2 áđáƥŧéř îñŧó ŧĥé çář\'š ƥóřŧ áñđ ŧúřñ ŧĥé îǧñîŧîóñ óñ. Ŵé\'łł řéáđ ŧĥé ṼÎÑ áñđ ƒîłł îñ éñǧîñé đéŧáîłš ƒóř ýóú. ···········································⟧';

  @override
  String get onboardingObd2ConnectButton => '⟦Çóññéçŧ áđáƥŧéř ······⟧';

  @override
  String get onboardingObd2SkipButton => '⟦Ṁáýƀé łáŧéř ·····⟧';

  @override
  String get onboardingObd2ReadingVin => '⟦Řéáđîñǧ ṼÎÑ… ·····⟧';

  @override
  String get onboardingObd2ConnectFailed =>
      '⟦Çóúłđñ\'ŧ çóññéçŧ ŧó ŧĥé áđáƥŧéř. Ýóú çáñ řéŧřý óř šķîƥ. ···················⟧';

  @override
  String get onboardingPickUseMode =>
      '⟦Ƥîçķ á úšé ɱóđé ŧó çóñŧîñúé. ··········⟧';

  @override
  String get onboardingObd2LaterNote =>
      '⟦Ýóú çáñ ƥáîř á Ɓłúéŧóóŧĥ ÓƁĐ2 áđáƥŧéř áñýŧîɱé łáŧéř ƒřóɱ ŧĥé ṽéĥîçłé šçřééñ ŧó řéçóřđ ŧřîƥš áñđ řéáđ éñǧîñé đáŧá. ·········································⟧';

  @override
  String get openHoursUnknown => '⟦Ĥóúřš úñķñóŵñ ·····⟧';

  @override
  String get open24Hours => '⟦Óƥéñ 24 ĥóúřš ····⟧';

  @override
  String get openingHoursAutomate24h =>
      '⟦Šéłƒ-šéřṽîçé ƥúɱƥ 24/7 (çářđ ƥáýɱéñŧ) ············⟧';

  @override
  String get dayMon => '⟦Ṁóñđáý ···⟧';

  @override
  String get dayTue => '⟦Ŧúéšđáý ···⟧';

  @override
  String get dayWed => '⟦Ŵéđñéšđáý ····⟧';

  @override
  String get dayThu => '⟦Ŧĥúřšđáý ····⟧';

  @override
  String get dayFri => '⟦Ƒřîđáý ···⟧';

  @override
  String get daySat => '⟦Šáŧúřđáý ····⟧';

  @override
  String get daySun => '⟦Šúñđáý ···⟧';

  @override
  String get dayShortMon => '⟦Ṁóñ ·⟧';

  @override
  String get dayShortTue => '⟦Ŧúé ·⟧';

  @override
  String get dayShortWed => '⟦Ŵéđ ·⟧';

  @override
  String get dayShortThu => '⟦Ŧĥú ·⟧';

  @override
  String get dayShortFri => '⟦Ƒřî ·⟧';

  @override
  String get dayShortSat => '⟦Šáŧ ·⟧';

  @override
  String get dayShortSun => '⟦Šúñ ·⟧';

  @override
  String dayRange(String from, String to) {
    return '⟦$from – $to⟧';
  }

  @override
  String get publicHolidays => '⟦Ƥúƀłîç ĥółîđáýš ······⟧';

  @override
  String get closedLabel => '⟦Çłóšéđ ···⟧';

  @override
  String get openingHoursNotAvailable =>
      '⟦Óƥéñîñǧ ĥóúřš ñóŧ áṽáîłáƀłé ···········⟧';

  @override
  String get showAllHours => '⟦Šĥóŵ áłł ĥóúřš ·····⟧';

  @override
  String get showLessHours => '⟦Šĥóŵ łéšš ····⟧';

  @override
  String get openStateUnknown => '⟦Úñķñóŵñ ···⟧';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Station is open',
      'false': 'Station is closed',
      'other': 'Open state unknown',
    });
    return '⟦$_temp0⟧';
  }

  @override
  String get permissionRationaleCameraTitle => '⟦Çáɱéřá Áççéšš ·····⟧';

  @override
  String get permissionRationaleCameraSubtitle =>
      '⟦Ŧĥîš áƥƥ ŵóúłđ łîķé ŧó úšé ýóúř çáɱéřá ŧó řéáđ řéçéîƥŧš, ƥúɱƥ đîšƥłáýš áñđ ɊŘ çóđéš. ······························⟧';

  @override
  String get permissionRationaleCameraWhatHappens =>
      '⟦Ŵĥáŧ ĥáƥƥéñš ŵîŧĥ ŧĥé çáɱéřá îɱáǧé: ·············⟧';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      '⟦Ŧĥé îɱáǧé îš úšéđ óñłý ŧó řéáđ ŧĥé řéçéîƥŧ, ŧĥé ƥúɱƥ đîšƥłáý óř ŧĥé ɊŘ çóđé — řéçóǧñîŧîóñ řúñš óñ ýóúř đéṽîçé. ·······································⟧';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      '⟦Ŧĥé ƥĥóŧó îš đîšçářđéđ áƒŧéř ŧĥé šçáñ. ··············⟧';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      '⟦Ñóŧĥîñǧ îš úƥłóáđéđ úñłéšš ýóú ƒîłé á ƀáđ-šçáñ řéƥóřŧ áñđ çóñƒîřɱ îŧ. ·························⟧';

  @override
  String get permissionRationaleBluetoothTitle => '⟦Ɓłúéŧóóŧĥ Áççéšš ·······⟧';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      '⟦Ŧĥîš áƥƥ ŵóúłđ łîķé ŧó úšé Ɓłúéŧóóŧĥ ŧó çóññéçŧ ŧó ýóúř ÓƁĐ2 áđáƥŧéř. ·························⟧';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      '⟦Ŵĥáŧ ĥáƥƥéñš ŵîŧĥ Ɓłúéŧóóŧĥ: ···········⟧';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      '⟦Ɓłúéŧóóŧĥ îš úšéđ óñłý ŧó ƒîñđ áñđ ŧáłķ ŧó ýóúř ÓƁĐ2 áđáƥŧéř. ······················⟧';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      '⟦Ŧĥé áđáƥŧéř îđéñŧîƒîéř šŧáýš óñ ýóúř đéṽîçé — îŧ îš šýñçéđ óñłý ŵîŧĥ ŦáñķŠýñç, áš ƥářŧ óƒ ŧĥé ṽéĥîçłé ƥřóƒîłé. ········································⟧';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      '⟦Óñ Áñđřóîđ 11 áñđ ƀéłóŵ ŧĥé šýšŧéɱ áłšó ášķš ƒóř łóçáŧîóñ, ƀéçáúšé Ɓłúéŧóóŧĥ šçáññîñǧ îš á łóçáŧîóñ-çłášš ƥéřɱîššîóñ ŧĥéřé. ·············································⟧';

  @override
  String get permissionRationaleNotificationsTitle => '⟦Ñóŧîƒîçáŧîóñš ······⟧';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      '⟦Ŧĥîš áƥƥ ŵóúłđ łîķé ŧó šéñđ ýóú ñóŧîƒîçáŧîóñš ƒóř ƥřîçé áłéřŧš áñđ ŧĥé ŧřîƥ-řéçóřđîñǧ šŧáŧúš. ···································⟧';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      '⟦Ŵĥáŧ ĥáƥƥéñš ŵîŧĥ ñóŧîƒîçáŧîóñš: ·············⟧';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      '⟦Ñóŧîƒîçáŧîóñš ářé úšéđ ƒóř łóçáł ƥřîçé áłéřŧš áñđ ŧĥé ŧřîƥ-řéçóřđîñǧ šŧáŧúš. ·····························⟧';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      '⟦Ŧĥéý ářé ǧéñéřáŧéđ óñ ýóúř đéṽîçé — ñóŧĥîñǧ łéáṽéš ŧĥé đéṽîçé. ·······················⟧';

  @override
  String get permissionRationaleRevoke =>
      '⟦Ýóú çáñ řéṽóķé ŧĥîš îñ ýóúř đéṽîçé šéŧŧîñǧš áŧ áñý ŧîɱé. ····················⟧';

  @override
  String get permissionRationaleLegalBasis =>
      '⟦Łéǧáł ƀášîš: Ářŧ. 6(1)(á) ǦĐƤŘ (Çóñšéñŧ) ···········⟧';

  @override
  String get tripRecordingPipEstConsumptionCaption => '⟦éšŧ. Ł/100 ķɱ ···⟧';

  @override
  String get tripRecordingEstimatedInfo =>
      '⟦Éšŧîɱáŧéđ ṽáłúé (~) — ñó ƒúéł šéñšóř óñ ŧĥîš ŧřîƥ, šó ŧĥé Ł/100 ķɱ ƒîǧúřé îš ɱóđéłłéđ ƒřóɱ ǦƤŠ šƥééđ áñđ ýóúř ṽéĥîçłé\'š çáłîƀřáŧîóñ. Îŧ îš áƥƥřóẋîɱáŧé (ŧýƥîçáłłý ±10–30 %, ŧîǧĥŧéñîñǧ áš ŧĥé çáłîƀřáŧîóñ ɱáŧúřéš), ñóŧ á ɱéášúřéđ řéáđîñǧ. ··············································································⟧';

  @override
  String get tripRecordingPipElapsedCaption => '⟦éłáƥšéđ ···⟧';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '⟦$vehicleName: çóñšúɱƥŧîóñ éšŧîɱáŧéš řé-áñçĥóřéđ ŧó ŧĥé ƥúɱƥ ($percent %) ··················⟧';
  }

  @override
  String get qrLaunchConfirmTitle => '⟦Óƥéñ šçáññéđ łîñķ? ·······⟧';

  @override
  String qrLaunchConfirmBody(String host) {
    return '⟦Ŧĥîš ɊŘ çóđé ƥóîñŧš ŧó $host. Óñłý óƥéñ łîñķš ýóú ŧřúšŧ. ··················⟧';
  }

  @override
  String get qrLaunchConfirmOpen => '⟦Óƥéñ łîñķ ····⟧';

  @override
  String get qrLaunchConfirmCancel => '⟦Çáñçéł ···⟧';

  @override
  String get radarPinHelpTitle => '⟦Áƀóúŧ ƥîñ ····⟧';

  @override
  String get radarPinHelpBody =>
      '⟦Ƥîñ ķééƥš ŧĥé šçřééñ óñ áñđ ĥîđéš šýšŧéɱ ƀářš šó ŧĥé çłóšéšŧ-šŧáŧîóñ řéáđóúŧ šŧáýš řéáđáƀłé óñ á đášĥƀóářđ ɱóúñŧ. Ŧáƥ áǧáîñ ŧó řéłéášé. Áúŧó-řéłéášéš ŵĥéñ ŧĥé řáđář šŧóƥš. ·······························································⟧';

  @override
  String get radarAutoPinTitle =>
      '⟦Áłŵáýš ƥîñ ŵĥéñ ŧĥé řáđář šŧářŧš ············⟧';

  @override
  String get radarAutoPinSubtitle =>
      '⟦Ƥîñ ŧĥé řáđář áúŧóɱáŧîçáłłý éṽéřý ŧîɱé îñšŧéáđ óƒ ŧáƥƥîñǧ éáçĥ ŧîɱé. Úšéš ɱóřé ƀáŧŧéřý. ································⟧';

  @override
  String get radarScopeShowScope => '⟦Řáđář ṽîéŵ ····⟧';

  @override
  String get radarScopeShowList => '⟦Łîšŧ ṽîéŵ ····⟧';

  @override
  String get alertsRadiusFrequencyLabel => '⟦Çĥéçķ ƒřéɋúéñçý ······⟧';

  @override
  String get alertsRadiusFrequencyDaily => '⟦Óñçé á đáý ····⟧';

  @override
  String get alertsRadiusFrequencyTwiceDaily => '⟦Ŧŵîçé á đáý ····⟧';

  @override
  String get alertsRadiusFrequencyThriceDaily => '⟦Ŧĥřéé ŧîɱéš á đáý ······⟧';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => '⟦Ƒóúř ŧîɱéš á đáý ······⟧';

  @override
  String get radiusAlertPickOnMap => '⟦Ƥîçķ óñ ɱáƥ ····⟧';

  @override
  String get radiusAlertMapPickerTitle => '⟦Ƥîçķ áłéřŧ çéñŧéř ·······⟧';

  @override
  String get radiusAlertMapPickerConfirm => '⟦Çóñƒîřɱ ···⟧';

  @override
  String get radiusAlertMapPickerCancel => '⟦Çáñçéł ···⟧';

  @override
  String get radiusAlertMapPickerHint =>
      '⟦Đřáǧ ŧĥé ɱáƥ ŧó ƥóšîŧîóñ ŧĥé áłéřŧ çéñŧéř ···············⟧';

  @override
  String get reconcileWorkflowTitle => '⟦Řéçóñçîłé ýóúř ƒúéł ········⟧';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return '⟦Ŵé ƒóúñđ á $gap Ł ǧáƥ ·····⟧';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return '⟦Ýóú ƥúɱƥéđ $pumped Ł, ƀúŧ ýóúř řéçóřđéđ ŧřîƥš óñłý áççóúñŧ ƒóř $consumed Ł. Ŧĥáŧ łéáṽéš $gap Ł úñéẋƥłáîñéđ. ······························⟧';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      '⟦Ŧĥîš úšúáłłý ɱéáñš á đřîṽé ŵášñ\'ŧ řéçóřđéđ (ŧĥé áđáƥŧéř ŵáš úñƥłúǧǧéđ óř ŧĥé áƥƥ ŵáš çłóšéđ), óř á ƒîłł-úƥ îš ɱîššîñǧ óř ɱîšŧýƥéđ. ··············································⟧';

  @override
  String get reconcileWorkflowExplainConsequence =>
      '⟦Úñŧîł ŧĥîš îš řéšółṽéđ, ýóúř ƒúéł ŧóŧáł áñđ ýóúř ŧřîƥš ŧóŧáł ŵóñ\'ŧ ɱáŧçĥ. ··························⟧';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      '⟦Ĥéłƥ úš áŧŧřîƀúŧé ŧĥé ǧáƥ ·········⟧';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      '⟦Ářé áłł ýóúř ƒîłł-úƥš ƒóř ŧĥîš ŧáñķ çóɱƥłéŧé áñđ çóřřéçŧ? ·····················⟧';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      '⟦Ářé áłł ýóúř đřîṽéš řéçóřđéđ? ···········⟧';

  @override
  String get reconcileWorkflowAnswerYes => '⟦Ýéš ·⟧';

  @override
  String get reconcileWorkflowAnswerNo => '⟦Ñó ·⟧';

  @override
  String get reconcileWorkflowPathAHint =>
      '⟦Á ƒîłł-úƥ îš ɱîššîñǧ óř ŵřóñǧ — ŵé\'łł áđđ á çóřřéçŧîóñ šó ýóúř ƒîłł-úƥš áđđ úƥ. ···························⟧';

  @override
  String get reconcileWorkflowPathBHint =>
      '⟦Ýóúř ƒîłł-úƥš ářé řîǧĥŧ áñđ á đřîṽé ŵéñŧ úñřéçóřđéđ — ŵé\'łł áđđ á ṽîřŧúáł ŧřîƥ ƒóř ŧĥé ɱîššîñǧ đîšŧáñçé. ·····································⟧';

  @override
  String get reconcileWorkflowCorrectionLitersLabel =>
      '⟦Çóřřéçŧîóñ łîŧřéš ·······⟧';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      '⟦Ĥóŵ ƒář ŵáš ŧĥé úñřéçóřđéđ đřîṽé? (ķɱ) ·············⟧';

  @override
  String get reconcileWorkflowDecideLater => '⟦Đéçîđé łáŧéř ·····⟧';

  @override
  String get reconcileWorkflowBack => '⟦Ɓáçķ ··⟧';

  @override
  String get reconcileWorkflowNext => '⟦Ñéẋŧ ··⟧';

  @override
  String get reconcileWorkflowApply => '⟦Áƥƥłý ··⟧';

  @override
  String get reconcileVirtualTrajetLabel =>
      '⟦Ṽîřŧúáł ŧřîƥ — ŧáƥ ŧó éđîŧ ·········⟧';

  @override
  String get reconcileVirtualTrajetEditTitle => '⟦Éđîŧ ṽîřŧúáł ŧřîƥ ·······⟧';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      '⟦Ŧĥîš ŧřîƥ ŵáš áđđéđ ŧó áççóúñŧ ƒóř ƒúéł ýóú úšéđ ŵĥîłé đřîṽîñǧ ŵîŧĥóúŧ řéçóřđîñǧ. Áđĵúšŧ ŧĥé đîšŧáñçé óř ƒúéł, óř đéłéŧé îŧ. ·············································⟧';

  @override
  String get reconcileVirtualTrajetDelete => '⟦Đéłéŧé ṽîřŧúáł ŧřîƥ ········⟧';

  @override
  String reconcileResolveGapBanner(String gap) {
    return '⟦Úñřéšółṽéđ ƒúéł/ŧřîƥ ǧáƥ óƒ $gap Ł — ŧáƥ ŧó řéšółṽé ················⟧';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      '⟦Řéšółṽé úñřéšółṽéđ ƒúéł áñđ ŧřîƥ ǧáƥ ··············⟧';

  @override
  String get refuelUnitPerKwh => '⟦/ķŴĥ ·⟧';

  @override
  String get refuelUnitPerSession => '⟦/šéššîóñ ···⟧';

  @override
  String get settingsSearchHint => '⟦Šéářçĥ šéŧŧîñǧš ······⟧';

  @override
  String settingsSearchNoResults(String query) {
    return '⟦Ñó šéŧŧîñǧš ɱáŧçĥ \"$query\" ·······⟧';
  }

  @override
  String get settingsTopicProfilesTitle => '⟦Ƥřóƒîłéš & řéǧîóñ ······⟧';

  @override
  String get settingsTopicProfilesSubtitle =>
      '⟦Çóúñŧřý, łáñǧúáǧé, ƒúéł ŧýƥé, šéářçĥ řáđîúš, řóúŧé ƥłáññîñǧ ······················⟧';

  @override
  String get settingsTopicProfilesKeywords =>
      '⟦ƥřóƒîłé, çóúñŧřý, łáñǧúáǧé, ƒúéł, řáđîúš, ƥóšŧáł çóđé, řóúŧé, ĥóɱé, řáŧîñǧ, šŧářŧ šçřééñ ·······························⟧';

  @override
  String get settingsTopicVehiclesTitle => '⟦Ṽéĥîçłéš & ÓƁĐ2 ·····⟧';

  @override
  String get settingsTopicVehiclesSubtitle =>
      '⟦Ýóúř çářš, ŧáñķ šîžé, ÓƁĐ2 áđáƥŧéř ƥáîřîñǧ ···············⟧';

  @override
  String get settingsTopicVehiclesKeywords =>
      '⟦ṽéĥîçłé, çář, óƀđ, óƀđ2, áđáƥŧéř, ƀłúéŧóóŧĥ, ŧáñķ, éñǧîñé, ṽîñ, çáłîƀřáŧîóñ ·························⟧';

  @override
  String get settingsTopicDrivingTitle => '⟦Đřîṽîñǧ & çóñšúɱƥŧîóñ ········⟧';

  @override
  String get settingsTopicDrivingSubtitle =>
      '⟦Çóáçĥîñǧ, řéŵářđš, ƒúéł-šŧáŧîóñ řáđář, ŧřóúƀłéšĥóóŧîñǧ ·····················⟧';

  @override
  String get settingsTopicDrivingKeywords =>
      '⟦çóáçĥ, éçó, ĥáƥŧîç, ṽóîçé, ǧáɱîƒîçáŧîóñ, řáđář, ǧłîđé, ŧřîƥ, çóñšúɱƥŧîóñ, ƒúéł çłúƀ, łóýáłŧý, óƀđ2 łóǧ, ƥîñ ····································⟧';

  @override
  String get settingsTopicPricesTitle => '⟦Ƥřîçéš & áłéřŧš ·····⟧';

  @override
  String get settingsTopicPricesSubtitle =>
      '⟦Ƥřîçé áłéřŧš, ṽóîçé áññóúñçéɱéñŧš, ƥřîçé ĥîšŧóřý, çóɱɱúñîŧý řéƥóřŧš ··························⟧';

  @override
  String get settingsTopicPricesKeywords =>
      '⟦áłéřŧ, ñóŧîƒîçáŧîóñ, ƥřîçé, ĥîšŧóřý, ƥřéđîçŧîóñ, ƀéšŧ ŧîɱé, çóɱɱúñîŧý, řéƥóřŧ, ɋř, ƥáýɱéñŧ, ṽóîçé, áññóúñçéɱéñŧ ········································⟧';

  @override
  String get settingsTopicUnitsTitle => '⟦Úñîŧš & đîšƥłáý ·····⟧';

  @override
  String get settingsTopicUnitsSubtitle =>
      '⟦Ŧĥéɱé, đîšŧáñçé úñîŧ, ĥóɱé-šçřééñ ŵîđǧéŧ ···············⟧';

  @override
  String get settingsTopicUnitsKeywords =>
      '⟦ŧĥéɱé, đářķ, łîǧĥŧ, éçó, úñîŧ, ķɱ, ɱîłéš, ŵîđǧéŧ, çółóúř, çółóř, đîšƥłáý, áƥƥéářáñçé ····························⟧';

  @override
  String get settingsTopicFeaturesTitle => '⟦Ƒéáŧúřéš & úšé ɱóđé ·······⟧';

  @override
  String get settingsTopicFeaturesSubtitle =>
      '⟦Úšé-ɱóđé ƥřéšéŧš áñđ éṽéřý ƒéáŧúřé šŵîŧçĥ ················⟧';

  @override
  String get settingsTopicFeaturesKeywords =>
      '⟦ƒéáŧúřé, ɱóđé, ƀášîç, ɱéđîúɱ, ƒúłł, çúšŧóɱ, šŵîŧçĥ, ŧóǧǧłé, šŧáŧîóñ ŧýƥéš, ƒúéł šŧáŧîóñš, éṽ šŧáŧîóñš, çĥářǧîñǧ ·······································⟧';

  @override
  String get settingsTopicDataSourcesTitle =>
      '⟦Đáŧá šóúřçéš & łóçáŧîóñ ·········⟧';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      '⟦ÁƤÎ ķéýš, ǦƤŠ ƥóšîŧîóñ, áúŧóɱáŧîç ƥřóƒîłé šŵîŧçĥîñǧ ···················⟧';

  @override
  String get settingsTopicDataSourcesKeywords =>
      '⟦áƥî, ķéý, ǧƥš, łóçáŧîóñ, ƥóšîŧîóñ, đáŧá šóúřçé, ŧáñķéřķóéñîǧ, óƥéñçĥářǧé ··························⟧';

  @override
  String get settingsTopicSyncTitle => '⟦Šýñç & áççóúñŧ ·····⟧';

  @override
  String get settingsTopicSyncKeywords =>
      '⟦ŧáñķšýñç, çłóúđ, áççóúñŧ, éɱáîł, łîñķ đéṽîçé, šýñç, šĥářé đáŧáƀášé, áñóñýɱóúš ···························⟧';

  @override
  String get settingsTopicPrivacyKeywords =>
      '⟦ƥřîṽáçý, çóñšéñŧ, ǧđƥř, đéłéŧé, éřášé, šŧóřáǧé, çáçĥé, đáŧá, éřřóř řéƥóřŧîñǧ, ṽîñ ····························⟧';

  @override
  String get settingsTopicBackupTitle => '⟦Ɓáçķúƥ & řéšŧóřé ······⟧';

  @override
  String get settingsTopicBackupSubtitle =>
      '⟦Éẋƥóřŧ óř řéšŧóřé á ƒúłł ƀáçķúƥ óƒ ýóúř đáŧá ················⟧';

  @override
  String get settingsTopicBackupKeywords =>
      '⟦ƀáçķúƥ, éẋƥóřŧ, řéšŧóřé, îɱƥóřŧ, žîƥ, ẋɱł, ŧřáñšƒéř ··················⟧';

  @override
  String get settingsTopicAdvancedSubtitle =>
      '⟦ǦîŧĤúƀ ŧóķéñ, đéṽéłóƥéř ŧóółš ···········⟧';

  @override
  String get settingsTopicAdvancedKeywords =>
      '⟦đéṽéłóƥéř, đéƀúǧ, ŧóķéñ, ƥáŧ, ǧîŧĥúƀ, đîáǧñóšŧîçš, éřřóř łóǧ, ŧřáçé ·······················⟧';

  @override
  String get settingsTopicAboutSubtitle =>
      '⟦Ṽéřšîóñ, łîçéñçéš, łîñķš ·········⟧';

  @override
  String get settingsTopicAboutKeywords =>
      '⟦áƀóúŧ, ṽéřšîóñ, łîçéñçé, łîçéñšé, đóñáŧé, ǧîŧĥúƀ, áŧŧřîƀúŧîóñ ······················⟧';

  @override
  String get settingsConsumptionOffHint =>
      '⟦Ŧúřñ óñ çóñšúɱƥŧîóñ ŧřáçķîñǧ îñ Ƒéáŧúřéš & úšé ɱóđé ŧó çóñƒîǧúřé ṽéĥîçłéš, çóáçĥîñǧ áñđ řéŵářđš. ····································⟧';

  @override
  String get settingsOpenFeaturesLink => '⟦Óƥéñ Ƒéáŧúřéš & úšé ɱóđé ·········⟧';

  @override
  String get settingsRadarTileSubtitle =>
      '⟦Řáđîúš, ƥřîçé ɱóđé, ƥółłîñǧ áñđ šçřééñ ƥîññîñǧ ƒóř ŧĥé áçŧîṽé ƥřóƒîłé ··························⟧';

  @override
  String get settingsRadarNoProfileHint =>
      '⟦Çřéáŧé á ƥřóƒîłé ƒîřšŧ — ŧĥé řáđář šéŧŧîñǧš ářé šŧóřéđ ƥéř ƥřóƒîłé. ························⟧';

  @override
  String get settingsRadarPinHeader => '⟦Šçřééñ ƥîññîñǧ ······⟧';

  @override
  String get settingsAlertsTileSubtitle =>
      '⟦Šŧáŧîóñ áñđ řáđîúš áłéřŧš ŧĥáŧ ñóŧîƒý ýóú óƒ ƥřîçé đřóƥš ·····················⟧';

  @override
  String get settingsPriceFeaturesHeader => '⟦Ƥřîçé ƒéáŧúřéš ······⟧';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      '⟦Ṽóîçé áññóúñçéɱéñŧš ářé óƒƒ. Ŧúřñ óñ Ṽóîçé ƒééđƀáçķ áñđ Ṽóîçé áññóúñçéɱéñŧš îñ Ƒéáŧúřéš & úšé ɱóđé ŧó ĥéář ñéářƀý çĥéáƥ ƒúéł ŵĥîłé đřîṽîñǧ. ···················································⟧';

  @override
  String get settingsDistanceUnitTitle => '⟦Đîšŧáñçé úñîŧ ·····⟧';

  @override
  String get settingsDistanceUnitSubtitle =>
      '⟦Ƒřóɱ ŧĥé áçŧîṽé ƥřóƒîłé\'š çóúñŧřý ·············⟧';

  @override
  String get settingsObd2AdapterTitle => '⟦ÓƁĐ2 áđáƥŧéř ·····⟧';

  @override
  String get settingsObd2AdapterSubtitle =>
      '⟦Áđáƥŧéřš ářé ƥáîřéđ ƥéř ṽéĥîçłé — óƥéñ á ṽéĥîçłé ŧó ƥáîř óř çĥáñǧé îŧš áđáƥŧéř ····························⟧';

  @override
  String get settingsPrivacyCrossLinkTitle => '⟦Çóñšéñŧš ····⟧';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      '⟦Çłóúđ Šýñç áñđ ŧřîƥ-šýñç çóñšéñŧš łîṽé úñđéř Ƥřîṽáçý & đáŧá ······················⟧';

  @override
  String get settingsBackupExportSubtitle =>
      '⟦Ṽéĥîçłéš, ƒîłł-úƥš, ŧřîƥš áñđ çĥářǧîñǧ łóǧš áš á ŽÎƤ ƒîłé ····················⟧';

  @override
  String get settingsBackupRestoreSubtitle =>
      '⟦Ṁéřǧé óř řéƥłáçé ýóúř đáŧá ƒřóɱ á ƥřéṽîóúš ƀáçķúƥ ŽÎƤ ····················⟧';

  @override
  String get settingsStationTypesLink =>
      '⟦Šŧáŧîóñ ŧýƥéš ářé šéŧ îñ Ƒéáŧúřéš & úšé ɱóđé ················⟧';

  @override
  String get routeSearchCriterionLabel =>
      '⟦Šŧáŧîóñ çĥóîçé ƥéř řóúŧé šéǧɱéñŧ ·············⟧';

  @override
  String get routeSearchCriterionCheapest => '⟦Çĥéáƥéšŧ ····⟧';

  @override
  String get routeSearchCriterionNearest => '⟦Ñéářéšŧ ŧó řóúŧé ······⟧';

  @override
  String get routeSearchTopNLabel =>
      '⟦Çáñđîđáŧéš ƥéř šáɱƥłé ƥóîñŧ ···········⟧';

  @override
  String routeSearchTopNCaption(int count) {
    return '⟦Úƥ ŧó $count šŧáŧîóñš ářé çóñšîđéřéđ áŧ éáçĥ ƥóîñŧ áłóñǧ ŧĥé řóúŧé. ······················⟧';
  }

  @override
  String get hybridFuelChoiceLabel =>
      '⟦Ƒúéł ƒóř ƥřîçé šéářçĥ (ĥýƀřîđ) ···········⟧';

  @override
  String get hybridFuelChoiceVehicleDefault => '⟦Ṽéĥîçłé đéƒáúłŧ ······⟧';

  @override
  String get scopeThisProfile => '⟦Ŧĥîš ƥřóƒîłé ·····⟧';

  @override
  String get scopeAllProfiles => '⟦Áłł ƥřóƒîłéš ·····⟧';

  @override
  String get scopeThisVehicle => '⟦Ŧĥîš ṽéĥîçłé ·····⟧';

  @override
  String get featureLabel_manualConsumption =>
      '⟦Ṁáñúáł çóñšúɱƥŧîóñ łóǧǧîñǧ ···········⟧';

  @override
  String get featureDescription_manualConsumption =>
      '⟦Ŧřáçķ ƒúéł ƒîłł-úƥš áñđ ÉṼ çĥářǧîñǧ šéššîóñš ƀý ĥáñđ (ñó ÓƁĐ2 áđáƥŧéř řéɋúîřéđ). ····························⟧';

  @override
  String get featureLabel_loyaltyCards => '⟦Łóýáłŧý çářđš ·····⟧';

  @override
  String get featureDescription_loyaltyCards =>
      '⟦Ƒúéł-çłúƀ / łóýáłŧý ƥřóǧřáɱ çářđš ŵîŧĥ ƥéř-łîŧřé đîšçóúñŧš îñ ƥřîçé çóɱƥářîšóñš. ······························⟧';

  @override
  String get featureLabel_startupTrace =>
      '⟦Šŧářŧúƥ îñîŧîáłîžáŧîóñ ŧřáçé ············⟧';

  @override
  String get featureDescription_startupTrace =>
      '⟦Řéçóřđ ŧĥé ŧîɱéđ ƥĥášéš óƒ áƥƥ šŧářŧúƥ, ṽîéŵ ŧĥéɱ áš á ŵáŧéřƒáłł áñđ éẋƥóřŧ ŧĥéɱ — á đéṽéłóƥéř đîáǧñóšŧîç. ······································⟧';

  @override
  String get locationGpsAutoHint =>
      '⟦ǦƤŠ ƥóšîŧîóñ îš áçɋúîřéđ áúŧóɱáŧîçáłłý ŵĥéñ ýóú šéářçĥ. Ýóú çáñ áłšó úƥđáŧé îŧ ɱáñúáłłý ĥéřé. ···································⟧';

  @override
  String get locationClearGpsBody =>
      '⟦Çłéář ŧĥé šŧóřéđ ǦƤŠ ƥóšîŧîóñ? Ýóú çáñ úƥđáŧé îŧ áǧáîñ áŧ áñý ŧîɱé. ························⟧';

  @override
  String get shareReceiptUnsupportedFormat =>
      '⟦Ŧĥáŧ ƒîłé ŧýƥé çáñ\'ŧ ƀé îɱƥóřŧéđ ýéŧ — šĥářé á ƥĥóŧó óƒ ŧĥé řéçéîƥŧ îñšŧéáđ. ···························⟧';

  @override
  String get shareReceiptFailed =>
      '⟦Çóúłđñ\'ŧ řéáđ ŧĥé šĥářéđ řéçéîƥŧ — ŧřý šĥářîñǧ îŧ áǧáîñ óř áđđ ŧĥé ƒîłł-úƥ ɱáñúáłłý. ······························⟧';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      '⟦Šĥářé řéçéîƥŧ ŧó îɱƥóřŧ ·········⟧';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      '⟦Šĥářé á řéçéîƥŧ ƥĥóŧó ƒřóɱ áñóŧĥéř áƥƥ ŧó ƥřé-ƒîłł á ƒîłł-úƥ — đáŧé, łîŧřéš, ŧóŧáł, áñđ šŧáŧîóñ ářé řéáđ óñ-đéṽîçé. ········································⟧';

  @override
  String get speedConsumptionCardTitle => '⟦Çóñšúɱƥŧîóñ ƀý šƥééđ ········⟧';

  @override
  String get speedBandIdleJam => '⟦Îđłé / ĵáɱ ···⟧';

  @override
  String get speedBandUrban => '⟦Úřƀáñ (10–50) ··⟧';

  @override
  String get speedBandSuburban => '⟦Šúƀúřƀáñ (50–80) ····⟧';

  @override
  String get speedBandRural => '⟦Řúřáł (80–100) ··⟧';

  @override
  String get speedBandMotorwaySlow => '⟦Éçó-çřúîšé (100–115) ····⟧';

  @override
  String get speedBandMotorway => '⟦Ṁóŧóřŵáý (115–130) ····⟧';

  @override
  String get speedBandMotorwayFast => '⟦Ṁóŧóřŵáý ƒášŧ (130+) ·····⟧';

  @override
  String get speedConsumptionInsufficientData =>
      '⟦Řéçóřđ 30+ ɱîñúŧéš óƒ ŧřîƥš ŵîŧĥ ŧĥé ÓƁĐ2 áđáƥŧéř ŧó úñłóçķ ŧĥé šƥééđ/çóñšúɱƥŧîóñ áñáłýšîš. ································⟧';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '⟦$percent % óƒ đřîṽîñǧ ····⟧';
  }

  @override
  String get speedConsumptionNeedMoreData => '⟦Ñééđ ɱóřé đáŧá ·····⟧';

  @override
  String get splashLoadingLabel => '⟦Łóáđîñǧ Šƥářķîłó ·······⟧';

  @override
  String get storageRecoveryTitle => '⟦Šŧóřáǧé ƥřóƀłéɱ ······⟧';

  @override
  String get storageRecoveryMessage =>
      '⟦Šƥářķîłó çóúłđñ\'ŧ óƥéñ îŧš łóçáł đáŧá šŧóřé. Ŧĥé šŧóřáǧé ƒîłé áƥƥéářš ŧó ƀé đáɱáǧéđ. ·······························⟧';

  @override
  String get storageRecoveryGuidance =>
      '⟦Ŧó řéçóṽéř, çłéář ŧĥé áƥƥ\'š šŧóřáǧé îñ ýóúř đéṽîçé šéŧŧîñǧš, óř řéîñšŧáłł ŧĥé áƥƥ. Ýóúř ƒáṽóúřîŧéš áñđ ĥîšŧóřý ářé šŧóřéđ óñ ŧĥîš đéṽîçé óñłý, šó ŧĥéý çáññóŧ ƀé řéšŧóřéđ áúŧóɱáŧîçáłłý. ···································································⟧';

  @override
  String syncAdoptTitle(String email) {
    return '⟦Ĵóîñ $email\'š áççóúñŧ ·····⟧';
  }

  @override
  String get syncAdoptSubtitle =>
      '⟦Šîǧñ îñ ŵîŧĥ ŧĥîš áççóúñŧ\'š ƥáššŵóřđ ŧó šĥářé îŧš đáŧá áçřóšš ƀóŧĥ đéṽîçéš. ···························⟧';

  @override
  String get syncAdoptPasswordLabel => '⟦Áççóúñŧ ƥáššŵóřđ ·······⟧';

  @override
  String get syncAdoptJoinButton => '⟦Ĵóîñ áççóúñŧ ·····⟧';

  @override
  String get syncAdoptUseDifferentAccount =>
      '⟦Úšé á đîƒƒéřéñŧ áççóúñŧ îñšŧéáđ ············⟧';

  @override
  String get syncDeleteDataTitle => '⟦Đéłéŧé šýñçéđ đáŧá ·······⟧';

  @override
  String get syncDeleteDataSubtitle =>
      '⟦Řéɱóṽé ýóúř ŧřîƥš, ṽéĥîçłéš óř ƒîłł-úƥš ƒřóɱ ŧĥé šýñç đáŧáƀášé ·······················⟧';

  @override
  String get syncDeleteDataPickTitle => '⟦Đéłéŧé ŵĥîçĥ šýñçéđ đáŧá? ·········⟧';

  @override
  String get syncDeleteDataCategoryTrips => '⟦Ŧřîƥš ··⟧';

  @override
  String get syncDeleteDataCategoryVehicles => '⟦Ṽéĥîçłéš ····⟧';

  @override
  String get syncDeleteDataCategoryFillUps => '⟦Ƒîłł-úƥš ···⟧';

  @override
  String get syncDeleteDataCategoryEverything => '⟦Éṽéřýŧĥîñǧ ·····⟧';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return '⟦Đéłéŧé $category ƒřóɱ ŧĥé šýñç đáŧáƀášé? ···········⟧';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      '⟦Ŧĥîš řéɱóṽéš ŧĥé šéłéçŧéđ đáŧá ƒřóɱ ýóúř šýñç đáŧáƀášé áñđ îŧ ŵîłł ñóŧ řé-šýñç ƒřóɱ ýóúř óŧĥéř đéṽîçéš. Đáŧá šŧóřéđ łóçáłłý óñ ŧĥîš đéṽîçé îš ķéƥŧ. ······················································⟧';

  @override
  String get syncDeleteDataConfirmAction => '⟦Đéłéŧé ƒřóɱ šéřṽéř ·······⟧';

  @override
  String get syncDeleteDataDone => '⟦Šýñçéđ đáŧá đéłéŧéđ ········⟧';

  @override
  String get syncDeleteDataFailed =>
      '⟦Đéłéŧîñǧ šýñçéđ đáŧá ƒáîłéđ — ƥłéášé ŧřý áǧáîñ ·················⟧';

  @override
  String get syncRelinkTitle => '⟦Çłóúđ šýñç ñééđš řé-łîñķîñǧ ··········⟧';

  @override
  String get syncRelinkBody =>
      '⟦Ŧĥîš đéṽîçé\'š šáṽéđ šýñç îđéñŧîŧý îš šîǧñéđ óúŧ. Šîǧñ îñ ŵîŧĥ ýóúř éɱáîł ŧó řé-łîñķ ýóúř šýñçéđ đáŧá, óř šŧářŧ ƒřéšĥ ŵîŧĥ á ñéŵ îđéñŧîŧý. ·················································⟧';

  @override
  String get syncRelinkSignInAction => '⟦Šîǧñ îñ ŧó řé-łîñķ ······⟧';

  @override
  String get syncRelinkStartFreshAction => '⟦Šŧářŧ ƒřéšĥ ·····⟧';

  @override
  String get syncRelinkStartFreshTitle => '⟦Šŧářŧ ƒřéšĥ? ·····⟧';

  @override
  String get syncRelinkStartFreshBody =>
      '⟦Á ñéŵ áñóñýɱóúš îđéñŧîŧý ŵîłł ƀé çřéáŧéđ ƒóř ŧĥîš đéṽîçé. Đáŧá šýñçéđ úñđéř ŧĥé ółđ îđéñŧîŧý šŧáýš óñ ŧĥé šéřṽéř ƀúŧ ŵîłł ñó łóñǧéř ƀé řéáçĥáƀłé ƒřóɱ ĥéřé úñłéšš ýóú šîǧñ îñ ŵîŧĥ îŧš éɱáîł áççóúñŧ. ········································································⟧';

  @override
  String get syncRelinkStartFreshConfirm => '⟦Šŧářŧ ƒřéšĥ ·····⟧';

  @override
  String get tankLevelTitle => '⟦Ŧáñķ łéṽéł ····⟧';

  @override
  String tankLevelLitersFormat(String litres) {
    return '⟦$litres Ł⟧';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '⟦≈ $kilometres ķɱ óƒ řáñǧé ····⟧';
  }

  @override
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '⟦≈ $kilometres ķɱ áŧ ýóúř łášŧ ŧáñķ\'š çóñšúɱƥŧîóñ ·············⟧';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return '⟦Łóñǧ-řúñ áṽéřáǧé: ≈ $kilometres ķɱ ·······⟧';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return '⟦Łášŧ ƒîłł-úƥ: $date · $count ŧřîƥ(š) šîñçé ·········⟧';
  }

  @override
  String get tankLevelEmptyNoFillUp =>
      '⟦Łóǧ á ƒîłł-úƥ ŧó šéé ýóúř ŧáñķ łéṽéł ·············⟧';

  @override
  String get tankLevelDetailSheetTitle =>
      '⟦Ŧřîƥš šîñçé łášŧ ƒîłł-úƥ ·········⟧';

  @override
  String get addFillUpIsFullTankLabel => '⟦Ƒúłł ŧáñķ ····⟧';

  @override
  String get addFillUpIsFullTankSubtitle =>
      '⟦Ŧáñķ ƒîłłéđ ŧó ŧĥé ƀřîɱ — úñçĥéçķ îƒ ŧĥîš ŵáš á ƥářŧîáł ƒîłł ·····················⟧';

  @override
  String tankLevelSourceFillUp(String date) {
    return '⟦Áñçĥóřéđ áŧ ŧĥé łášŧ ƒîłł-úƥ: $date ··········⟧';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return '⟦ÓƁĐ2 ŧáñķ šéñšóř · $date ······⟧';
  }

  @override
  String tankMixCaption(String mix) {
    return '⟦Ŧáñķ ɱîẋ: $mix ···⟧';
  }

  @override
  String get tankReportTitle => '⟦Ŧáñķ řéƥóřŧ ·····⟧';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return '⟦Šîñçé ŧĥé ƥřéṽîóúš ƒúłł ŧáñķ: $km ķɱ · $liters Ł · $cost ············⟧';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '⟦$delta Ł/100 ķɱ ɱóřé ŧĥáñ ŧĥé ƥřéṽîóúš ŧáñķ ············⟧';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '⟦$delta Ł/100 ķɱ łéšš ŧĥáñ ŧĥé ƥřéṽîóúš ŧáñķ ············⟧';
  }

  @override
  String get tankReportTrendFlat =>
      '⟦Łéṽéł ŵîŧĥ ŧĥé ƥřéṽîóúš ŧáñķ ···········⟧';

  @override
  String get tankReportNoPrevious =>
      '⟦Éṽółúŧîóñ áƥƥéářš áƒŧéř ýóúř ñéẋŧ ƒúłł ŧáñķ. ·················⟧';

  @override
  String get tankReportExplainHeader =>
      '⟦Ŵĥáŧ ŧĥé řéçóřđîñǧš šúǧǧéšŧ ···········⟧';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return '⟦Ĥîǧĥ-ŘƤṀ šĥářé $cur % (ŵáš $prev %) ·······⟧';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return '⟦Ĥářšĥ éṽéñŧš $cur/100 ķɱ (ŵáš $prev) ·······⟧';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return '⟦Çółđ šŧářŧš $cur (ŵáš $prev) ······⟧';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return '⟦Îđłé šĥářé $cur % (ŵáš $prev %) ·····⟧';
  }

  @override
  String get tankReportCaveat =>
      '⟦Řéçóřđîñǧš ářé šƥóñŧáñéóúš áñđ çóṽéř óñłý ƥářŧ óƒ ŧĥîš ŧáñķ — ŧĥéšé ĥîñŧš ářé îñđîçáŧîṽé, ñóŧ ŧĥé ƒúłł šŧóřý. ········································⟧';

  @override
  String get themeCardTitle => '⟦Ŧĥéɱé ··⟧';

  @override
  String get themeCardSubtitleSystem => '⟦Šýšŧéɱ ···⟧';

  @override
  String get themeCardSubtitleLight => '⟦Łîǧĥŧ ··⟧';

  @override
  String get themeCardSubtitleDark => '⟦Đářķ ··⟧';

  @override
  String get themeSettingsScreenTitle => '⟦Ŧĥéɱé ··⟧';

  @override
  String get themeSettingsSystemLabel => '⟦Ƒółłóŵ šýšŧéɱ ·····⟧';

  @override
  String get themeSettingsLightLabel => '⟦Łîǧĥŧ ··⟧';

  @override
  String get themeSettingsDarkLabel => '⟦Đářķ ··⟧';

  @override
  String get themeSettingsSystemDescription =>
      '⟦Ṁáŧçĥ ŧĥé çúřřéñŧ đéṽîçé áƥƥéářáñçé. ··············⟧';

  @override
  String get themeSettingsLightDescription =>
      '⟦Ɓřîǧĥŧ ƀáçķǧřóúñđš — ƀéšŧ ƒóř đáýŧîɱé úšé. ···············⟧';

  @override
  String get themeSettingsDarkDescription =>
      '⟦Đářķ ƀáçķǧřóúñđš — éášîéř óñ ŧĥé éýéš áŧ ñîǧĥŧ áñđ šáṽéš ƀáŧŧéřý óñ ÓŁÉĐ šçřééñš. ·····························⟧';

  @override
  String get themeSettingsEcoLabel => '⟦Éçó ·⟧';

  @override
  String get themeSettingsEcoDescription =>
      '⟦Ŧĥé áƥƥ\'š šîǧñáŧúřé ǧřééñ łóóķ — ƀřîǧĥŧ áñđ éášý ŧó řéáđ, ŵîŧĥ šóƒŧłý ǧřééñ-ŧîñŧéđ ƀáçķǧřóúñđš. ··································⟧';

  @override
  String get throttleRpmHistogramTitle => '⟦Ĥóŵ ýóú úšéđ ŧĥé éñǧîñé ·········⟧';

  @override
  String get throttleRpmHistogramThrottleSection =>
      '⟦Ŧĥřóŧŧłé ƥóšîŧîóñ ·······⟧';

  @override
  String get throttleRpmHistogramRpmSection => '⟦Éñǧîñé ŘƤṀ ····⟧';

  @override
  String get throttleRpmHistogramThrottleCoast => '⟦Çóášŧ (0–25%) ··⟧';

  @override
  String get throttleRpmHistogramThrottleLight => '⟦Łîǧĥŧ (25–50%) ··⟧';

  @override
  String get throttleRpmHistogramThrottleFirm => '⟦Ƒîřɱ (50–75%) ··⟧';

  @override
  String get throttleRpmHistogramThrottleWide => '⟦Ŵîđé-óƥéñ (75–100%) ····⟧';

  @override
  String get throttleRpmHistogramRpmIdle => '⟦Îđłé (≤900) ··⟧';

  @override
  String get throttleRpmHistogramRpmCruise => '⟦Çřúîšé (901–2000) ···⟧';

  @override
  String get throttleRpmHistogramRpmSpirited => '⟦Šƥîřîŧéđ (2001–3000) ····⟧';

  @override
  String get throttleRpmHistogramRpmHard => '⟦Ĥářđ (>3000) ··⟧';

  @override
  String get throttleRpmHistogramEmpty =>
      '⟦Ñó ŧĥřóŧŧłé óř ŘƤṀ šáɱƥłéš îñ ŧĥîš ŧřîƥ. ··············⟧';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '⟦$pct%⟧';
  }

  @override
  String get trajetsTabLabel => '⟦Ŧřîƥš ··⟧';

  @override
  String get trajetsStartRecordingButton => '⟦Šŧářŧ řéçóřđîñǧ ······⟧';

  @override
  String get trajetsResumeRecordingButton => '⟦Řéšúɱé řéçóřđîñǧ ·······⟧';

  @override
  String get tripStartProgressConnectingAdapter =>
      '⟦Çóññéçŧîñǧ ŧó ÓƁĐ2 áđáƥŧéř… ··········⟧';

  @override
  String get tripStartProgressReadingVehicleData =>
      '⟦Řéáđîñǧ ṽéĥîçłé đáŧá… ········⟧';

  @override
  String get tripStartProgressStartingRecording =>
      '⟦Šŧářŧîñǧ řéçóřđîñǧ… ········⟧';

  @override
  String get tripSaveProgressFinalizingSummary =>
      '⟦Ƒîñáłîžîñǧ šúɱɱářý… ········⟧';

  @override
  String get tripSaveProgressSavingToHistory => '⟦Šáṽîñǧ ŧó ĥîšŧóřý… ·······⟧';

  @override
  String get tripSaveProgressSyncingToCloud =>
      '⟦Šýñçîñǧ îñ ƀáçķǧřóúñđ… ·········⟧';

  @override
  String get trajetsEmptyStateTitle => '⟦Ñó ŧřîƥš ýéŧ ·····⟧';

  @override
  String get trajetsEmptyStateBody =>
      '⟦Ŧáƥ Šŧářŧ řéçóřđîñǧ ŧó ƀéǧîñ łóǧǧîñǧ ýóúř đřîṽéš. ··················⟧';

  @override
  String trajetsRowDistance(String km) {
    return '⟦$km ķɱ ·⟧';
  }

  @override
  String trajetsRowDuration(String minutes) {
    return '⟦$minutes ɱîñ ·⟧';
  }

  @override
  String trajetsRowAvgConsumption(String value, String unit) {
    return '⟦$value $unit⟧';
  }

  @override
  String get trajetDetailSummaryTitle => '⟦Šúɱɱářý ···⟧';

  @override
  String get trajetDetailFieldDate => '⟦Đáŧé ··⟧';

  @override
  String get trajetDetailFieldVehicle => '⟦Ṽéĥîçłé ···⟧';

  @override
  String get trajetDetailFieldAdapter => '⟦ÓƁĐ2 áđáƥŧéř ·····⟧';

  @override
  String get trajetDetailFieldDistance => '⟦Đîšŧáñçé ····⟧';

  @override
  String get trajetDetailFieldDuration => '⟦Đúřáŧîóñ ····⟧';

  @override
  String get trajetDetailFieldAvgConsumption => '⟦Áṽǧ çóñšúɱƥŧîóñ ······⟧';

  @override
  String get trajetDetailFieldFuelUsed => '⟦Ƒúéł úšéđ ····⟧';

  @override
  String get trajetDetailFieldFuelCost => '⟦Ƒúéł çóšŧ ····⟧';

  @override
  String get trajetDetailFieldAvgSpeed => '⟦Áṽǧ šƥééđ ····⟧';

  @override
  String get trajetDetailFieldMaxSpeed => '⟦Ṁáẋ šƥééđ ····⟧';

  @override
  String get trajetDetailFieldValueUnknown => '⟦—⟧';

  @override
  String get trajetDetailChartSpeed => '⟦Šƥééđ (ķɱ/ĥ) ····⟧';

  @override
  String get trajetDetailChartFuelRate => '⟦Ƒúéł řáŧé (Ł/ĥ) ·····⟧';

  @override
  String get trajetDetailChartRpm => '⟦ŘƤṀ ·⟧';

  @override
  String get trajetDetailChartEngineLoad => '⟦Éñǧîñé łóáđ (%) ·····⟧';

  @override
  String get trajetDetailChartThrottle => '⟦Ŧĥřóŧŧłé / ƥéđáł (%) ······⟧';

  @override
  String get trajetDetailChartCoolant => '⟦Çóółáñŧ (°Ç) ····⟧';

  @override
  String get trajetDetailChartAltitudeRelative =>
      '⟦Áłŧîŧúđé (ɱ, ƒřóɱ šŧářŧ) ········⟧';

  @override
  String get trajetDetailChartLambda => '⟦Çóɱɱáñđéđ λ ····⟧';

  @override
  String get trajetDetailChartsSection => '⟦Çĥářŧš ···⟧';

  @override
  String get trajetsRowColdStartChip => '⟦Çółđ šŧářŧ ····⟧';

  @override
  String get trajetsRowColdStartTooltip =>
      '⟦Éñǧîñé đîđñ\'ŧ řéáçĥ óƥéřáŧîñǧ ŧéɱƥéřáŧúřé đúřîñǧ ŧĥîš ŧřîƥ — ƒúéł çóñšúɱƥŧîóñ ŵáš ĥîǧĥéř ŧĥáñ úšúáł. ·····································⟧';

  @override
  String get trajetDetailChartEmpty => '⟦Ñó šáɱƥłéš řéçóřđéđ ········⟧';

  @override
  String get trajetDetailChartEstimatedBadge => '⟦éšŧîɱáŧéđ ····⟧';

  @override
  String get trajetDetailShareAction => '⟦Šĥářé ··⟧';

  @override
  String get trajetDetailShareImageOption => '⟦Šĥářé îɱáǧé ·····⟧';

  @override
  String get trajetDetailShareGpxOption => '⟦Šĥářé ǦƤŠ ŧřáçķ (ǦƤẊ) ·······⟧';

  @override
  String get trajetDetailShareGpxEmpty =>
      '⟦Ñó ǦƤŠ šáɱƥłéš îñ ŧĥîš ŧřîƥ ··········⟧';

  @override
  String trajetDetailShareSubject(String date) {
    return '⟦Šƥářķîłó — ŧřîƥ óñ $date ······⟧';
  }

  @override
  String get trajetDetailShareError =>
      '⟦Çóúłđñ\'ŧ ǧéñéřáŧé šĥářé îɱáǧé ···········⟧';

  @override
  String get trajetDetailDownloadCsvOption =>
      '⟦Đóŵñłóáđ ŧéłéɱéŧřý (ÇŠṼ) ·········⟧';

  @override
  String get trajetDetailDownloadJsonOption =>
      '⟦Đóŵñłóáđ ŧéłéɱéŧřý (ĴŠÓÑ) ·········⟧';

  @override
  String get trajetDetailDownloadError => '⟦Çóúłđñ\'ŧ šáṽé ŧĥé ƒîłé ········⟧';

  @override
  String get trajetDetailDeleteAction => '⟦Đéłéŧé ···⟧';

  @override
  String get trajetDetailDeleteConfirmTitle => '⟦Đéłéŧé ŧĥîš ŧřîƥ? ······⟧';

  @override
  String get trajetDetailDeleteConfirmBody =>
      '⟦Ŧĥîš ŧřîƥ ŵîłł ƀé ƥéřɱáñéñŧłý řéɱóṽéđ ƒřóɱ ýóúř ĥîšŧóřý. ·····················⟧';

  @override
  String get trajetDetailDeleteConfirmConfirm => '⟦Đéłéŧé ···⟧';

  @override
  String get tripRecordingObd2NotResponding =>
      '⟦ÓƁĐ2 áđáƥŧéř çóññéçŧéđ ƀúŧ ñóŧ řéŧúřñîñǧ đáŧá. Ŧřý á đîƒƒéřéñŧ áđáƥŧéř óř çĥéçķ ŧĥé ṽéĥîçłé\'š đîáǧñóšŧîç ƥřóŧóçół. ··········································⟧';

  @override
  String get trajetsViewAllOnMap => '⟦Ṽîéŵ áłł óñ ɱáƥ ·····⟧';

  @override
  String get trajetsMapTitle => '⟦Ŧřáĵéŧš óñ ɱáƥ ·····⟧';

  @override
  String get trajetsMapShareGpx => '⟦Šĥářé ǦƤẊ ····⟧';

  @override
  String get trajetsMapEmpty =>
      '⟦Ñóñé óƒ ŧĥé šéłéçŧéđ ŧřáĵéŧš çářřý ǦƤŠ šáɱƥłéš. ··················⟧';

  @override
  String get trajetsMapShareError =>
      '⟦Çóúłđñ\'ŧ šĥářé ŧĥé ǦƤẊ ƒîłé ··········⟧';

  @override
  String get trajetDetailChartBoost =>
      '⟦Ɓóóšŧ ƥřéššúřé (ṀÁƤ − áɱƀîéñŧ) ··········⟧';

  @override
  String get trajetDetailChartIat => '⟦Îñŧáķé áîř ŧéɱƥéřáŧúřé ·········⟧';

  @override
  String get trajetDetailChartTiming => '⟦Îǧñîŧîóñ ŧîɱîñǧ áđṽáñçé ·········⟧';

  @override
  String get trajetObd2Degraded =>
      '⟦Šŧářŧéđ ŵîŧĥ ŧĥé ÓƁĐ2 áđáƥŧéř ƀúŧ řéçóřđéđ ɱóšŧłý ǦƤŠ — éñǧîñé đáŧá îš îñçóɱƥłéŧé ······························⟧';

  @override
  String get tripLengthCardTitle => '⟦Çóñšúɱƥŧîóñ ƀý ŧřîƥ łéñǧŧĥ ··········⟧';

  @override
  String get tripLengthBucketShort => '⟦Šĥóřŧ (<5 ķɱ) ···⟧';

  @override
  String get tripLengthBucketMedium => '⟦Ṁéđîúɱ (5–25 ķɱ) ····⟧';

  @override
  String get tripLengthBucketLong => '⟦Łóñǧ (>25 ķɱ) ···⟧';

  @override
  String get tripLengthBucketNeedMoreData => '⟦Ñééđ ɱóřé đáŧá ·····⟧';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
      zero: 'no trips',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get tripPathCardTitle => '⟦Ŧřîƥ ƥáŧĥ ····⟧';

  @override
  String get tripPathCardSubtitle => '⟦ǦƤŠ-řéçóřđéđ řóúŧé ·······⟧';

  @override
  String get tripPathLegendEfficient => '⟦Éƒƒîçîéñŧ (< 6 Ł/100ķɱ) ·····⟧';

  @override
  String get tripPathLegendBorderline => '⟦Ɓóřđéřłîñé (6–10 Ł/100ķɱ) ······⟧';

  @override
  String get tripPathLegendWasteful => '⟦Ŵášŧéƒúł (≥ 10 Ł/100ķɱ) ·····⟧';

  @override
  String get tripRadarClosestStation => '⟦Ƒúéł Šŧáŧîóñ Řáđář ·······⟧';

  @override
  String get tripRadarScanning => '⟦Šçáññîñǧ ƒóř ñéářƀý šŧáŧîóñš ···········⟧';

  @override
  String get tripRadarNoStationNearby => '⟦Ñó šŧáŧîóñ ñéářƀý ·······⟧';

  @override
  String get fuelStationRadarNearer => '⟦Ñéářéř šŧáŧîóñ ······⟧';

  @override
  String get fuelStationRadarFarther => '⟦Ƒářŧĥéř šŧáŧîóñ ······⟧';

  @override
  String get fuelStationRadarStart => '⟦Šŧářŧ ƒúéł šŧáŧîóñ řáđář ·········⟧';

  @override
  String get stopRadar => '⟦Šŧóƥ řáđář ····⟧';

  @override
  String get fuelStationRadarResultBadge =>
      '⟦Ƒúéł Šŧáŧîóñ Řáđář řéšúłŧ ··········⟧';

  @override
  String get radarUpdatingLocation => '⟦Úƥđáŧîñǧ ýóúř łóçáŧîóñ… ·········⟧';

  @override
  String get radarSearching => '⟦Šéářçĥîñǧ… ····⟧';

  @override
  String get highwayModeChip =>
      '⟦Ĥîǧĥŵáý ɱóđé — šĥóŵîñǧ šŧáŧîóñš áĥéáđ óñ ýóúř řóúŧé ···················⟧';

  @override
  String get tripRecordingPinTooltip =>
      '⟦Ƥîññîñǧ ķééƥš ŧĥé šçřééñ óñ — úšéš ɱóřé ƀáŧŧéřý ·················⟧';

  @override
  String get tripRecordingPinSemanticOn => '⟦Úñƥîñ řéçóřđîñǧ ƒóřɱ ········⟧';

  @override
  String get tripRecordingPinSemanticOff => '⟦Ƥîñ řéçóřđîñǧ ƒóřɱ ·······⟧';

  @override
  String get tripRecordingPinHelpTooltip => '⟦Ŵĥáŧ đóéš ƥîñ đó? ······⟧';

  @override
  String get tripRecordingPinHelpTitle => '⟦Áƀóúŧ ƥîñ ····⟧';

  @override
  String get tripRecordingPinHelpBody =>
      '⟦Ƥîñ ķééƥš ŧĥé šçřééñ óñ áñđ ĥîđéš šýšŧéɱ ƀářš šó ŧĥé ƒóřɱ šŧáýš řéáđáƀłé óñ á đášĥƀóářđ ɱóúñŧ. Ŧáƥ áǧáîñ ŧó řéłéášé. Áúŧó-řéłéášéš ŵĥéñ ŧĥé ŧřîƥ šŧóƥš. ······················································⟧';

  @override
  String get tripRecordingResumeHintMessage =>
      '⟦Řéçóřđîñǧ çóñŧîñúéš îñ ŧĥé ƀáçķǧřóúñđ. Ŧáƥ ŧĥé řéđ ƀáññéř áŧ ŧĥé ŧóƥ óƒ áñý šçřééñ ŧó řéŧúřñ. ··································⟧';

  @override
  String get tripRecordingUnpinnedWarning =>
      '⟦Ƥîñ ŧĥé šçřééñ ŧó ķééƥ ǦƤŠ áçŧîṽé đúřîñǧ ŧĥé ŧřîƥ — Áñđřóîđ ɱáý ŧĥřóŧŧłé ǦƤŠ đúřîñǧ šłééƥ. ································⟧';

  @override
  String get tripRecordingMinimiseTooltip =>
      '⟦Ṁîñîɱîšé ŧó á ƒłóáŧîñǧ ŧîłé ··········⟧';

  @override
  String get tripRecordingAutoPinTitle =>
      '⟦Áłŵáýš ƥîñ ŵĥéñ řéçóřđîñǧ šŧářŧš ·············⟧';

  @override
  String get tripRecordingAutoPinSubtitle =>
      '⟦Ƥîñ ŧĥé ƒóřɱ áúŧóɱáŧîçáłłý éṽéřý đřîṽé îñšŧéáđ óƒ ŧáƥƥîñǧ éáçĥ ŧîɱé. Úšéš ɱóřé ƀáŧŧéřý. ································⟧';

  @override
  String get tripRecordingConnectingTitle => '⟦Šŧářŧîñǧ řéçóřđîñǧ… ········⟧';

  @override
  String get tripRecordingSavingTitle => '⟦Šáṽîñǧ ŧřîƥ… ·····⟧';

  @override
  String get tripRecordingDiscardedNoMovement =>
      '⟦Řéçóřđîñǧ đîšçářđéđ — ñó ɱóṽéɱéñŧ đéŧéçŧéđ ················⟧';

  @override
  String get tripRecordingGpsNotificationTitle =>
      '⟦Řéçóřđîñǧ ýóúř ŧřîƥ ········⟧';

  @override
  String get tripRecordingGpsNotificationText =>
      '⟦Ŧřáçķîñǧ ýóúř řóúŧé ƒóř ƒúéł & đřîṽîñǧ šŧáŧš ················⟧';

  @override
  String get tripShareAction => '⟦Šĥářé ŵîŧĥ áñóŧĥéř áççóúñŧ ··········⟧';

  @override
  String get tripShareSheetTitle => '⟦Šĥářé ŧĥîš ŧřîƥ ······⟧';

  @override
  String get tripShareSheetSubtitle =>
      '⟦Ǧîṽé áñóŧĥéř ŦáñķŠýñç áççóúñŧ řéáđ-óñłý áççéšš ŧó ŧĥîš řéçóřđéđ ŧřîƥ. ··························⟧';

  @override
  String get tripShareEmailLabel => '⟦Řéçîƥîéñŧ éɱáîł ······⟧';

  @override
  String get tripShareEmailHint => '⟦ñáɱé@éẋáɱƥłé.çóɱ ······⟧';

  @override
  String get tripShareSendButton => '⟦Šĥářé ··⟧';

  @override
  String get tripShareCreateLinkButton => '⟦Çřéáŧé šĥářé łîñķ ·······⟧';

  @override
  String get tripShareLinkCreated =>
      '⟦Šĥářé łîñķ çóƥîéđ — ƥášŧé îŧ ŧó ŧĥé řéçîƥîéñŧ. ················⟧';

  @override
  String get tripShareSuccess => '⟦Ŧřîƥ šĥářéđ. ·····⟧';

  @override
  String get tripShareRecipientNotFound =>
      '⟦Ñó ŦáñķŠýñç áççóúñŧ úšéš ŧĥáŧ éɱáîł. ··············⟧';

  @override
  String get tripShareError =>
      '⟦Çóúłđñ\'ŧ šĥářé ŧĥîš ŧřîƥ. Ŧřý áǧáîñ. ·············⟧';

  @override
  String get tripShareExistingTitle => '⟦Šĥářéđ ŵîŧĥ ·····⟧';

  @override
  String get tripShareExistingEmpty =>
      '⟦Ñóŧ šĥářéđ ŵîŧĥ áñýóñé ýéŧ. ··········⟧';

  @override
  String get tripShareDirectRecipient => '⟦Áñ áççóúñŧ ····⟧';

  @override
  String get tripShareLinkRecipient => '⟦Šĥářé łîñķ (úñçłáîɱéđ) ········⟧';

  @override
  String get tripShareRevokeTooltip => '⟦Řéṽóķé ···⟧';

  @override
  String get tripShareRevoked => '⟦Šĥářé řéṽóķéđ. ·····⟧';

  @override
  String get trajetsSharedSectionTitle => '⟦Šĥářéđ ŵîŧĥ ɱé ·····⟧';

  @override
  String get trajetsSharedBadge => '⟦Šĥářéđ ···⟧';

  @override
  String get tripVerdictPromptTitle => '⟦Ĥóŵ đîđ ŧĥîš ŧřîƥ ƒééł? ········⟧';

  @override
  String get tripVerdictSmooth => '⟦Šɱóóŧĥ ···⟧';

  @override
  String get tripVerdictModerate => '⟦Ṁóđéřáŧé ····⟧';

  @override
  String get tripVerdictAggressive => '⟦Áǧǧřéššîṽé ·····⟧';

  @override
  String get tripVerdictDismiss => '⟦Ñóŧ ñóŵ ···⟧';

  @override
  String get tripVerdictThanks =>
      '⟦Ŧĥáñķš — ŧĥîš ĥéłƥš çáłîƀřáŧé ýóúř đřîṽîñǧ áñáłýšîš. ···················⟧';

  @override
  String get fillUpDeletedUndoSnackbar => '⟦Ƒîłł-úƥ đéłéŧéđ ······⟧';

  @override
  String get trajetDeletedUndoSnackbar => '⟦Řéçóřđîñǧ đéłéŧéđ ·······⟧';

  @override
  String get searchFailedSnackbar =>
      '⟦Šéářçĥ ƒáîłéđ — ƥłéášé ŧřý áǧáîñ ············⟧';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String stationUpdatedLabel(String time) {
    return '⟦Úƥđáŧéđ $time ···⟧';
  }

  @override
  String amenityMoreTooltip(String names) {
    return '⟦Áłšó: $names ··⟧';
  }

  @override
  String get favoriteAdd => '⟦Áđđ ŧó ƒáṽóřîŧéš ······⟧';

  @override
  String get favoriteRemove => '⟦Řéɱóṽé ƒřóɱ ƒáṽóřîŧéš ·········⟧';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return '⟦Řáŵ: $price ·⟧';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '⟦$sources⟧';
  }

  @override
  String get stationUnbrandedTitle => '⟦Úñƀřáñđéđ šŧáŧîóñ ·······⟧';

  @override
  String get unsupportedRegionTitle =>
      '⟦Ñóŧ áṽáîłáƀłé îñ ýóúř řéǧîóñ ýéŧ ············⟧';

  @override
  String get unsupportedRegionBody =>
      '⟦Ŵé đóñ\'ŧ ĥáṽé ƒúéł ƥřîçéš ƒóř ýóúř çóúñŧřý ýéŧ, šó řéšúłŧš ɱáý ƀé éɱƥŧý óř ƒřóɱ áñóŧĥéř çóúñŧřý. Ýóú çáñ šŧîłł ƥîçķ á šúƥƥóřŧéđ çóúñŧřý îñ ŧĥé šéářçĥ šéŧŧîñǧš. ·························································⟧';

  @override
  String get unsupportedRegionDismiss => '⟦Ǧóŧ îŧ ··⟧';

  @override
  String get configureCountryTitle => '⟦Šéŧ ýóúř çóúñŧřý ······⟧';

  @override
  String get configureCountryBody =>
      '⟦Ýóúř çóúñŧřý îš šúƥƥóřŧéđ, ƀúŧ îŧ îšñ\'ŧ šéŧ úƥ ýéŧ — šó ƥřîçéš ɱáý ƀé ƒřóɱ áñóŧĥéř çóúñŧřý. Çĥóóšé ýóúř çóúñŧřý îñ ŧĥé šéářçĥ šéŧŧîñǧš ŧó šéé łóçáł ƥřîçéš. ·······················································⟧';

  @override
  String get stalePriceBadge => '⟦Ółđ ƥřîçé ····⟧';

  @override
  String get radiusAlertCenterChipGps => '⟦Ṁý ƥóšîŧîóñ ·····⟧';

  @override
  String get radiusAlertCenterChipMap => '⟦Ṁáƥ ƥóîñŧ ····⟧';

  @override
  String radiusAlertCenterChipPostal(String postalCode) {
    return '⟦Ƥóšŧáł çóđé $postalCode ·····⟧';
  }

  @override
  String get radiusAlertCenterClear => '⟦Çłéář łóçáŧîóñ ······⟧';

  @override
  String get radiusAlertBlockerLabel => '⟦Éñŧéř á łáƀéł ·····⟧';

  @override
  String get radiusAlertBlockerThreshold =>
      '⟦Éñŧéř á ŧĥřéšĥółđ áƀóṽé 0 ·········⟧';

  @override
  String get radiusAlertBlockerLocation => '⟦Çĥóóšé á łóçáŧîóñ ·······⟧';

  @override
  String get allPricesLegend =>
      '⟦Ƒîłłéđ = çĥéáƥéšŧ óƒ ŧĥéšé řéšúłŧš. Šéçóñđ ƒîǧúřé = ŵĥáŧ 100 ķɱ çóšŧš óñ ŧĥáŧ ƒúéł ŵîŧĥ ýóúř ṽéĥîçłé. ··································⟧';

  @override
  String get allPricesLegendPricesOnly =>
      '⟦Ƒîłłéđ = çĥéáƥéšŧ óƒ ŧĥéšé řéšúłŧš. Áđđ á ṽéĥîçłé áñđ łóǧ ƒîłł-úƥš ŧó šéé ŧĥé çóšŧ ƥéř 100 ķɱ. ·······························⟧';

  @override
  String get allPricesNoPriceMask => '⟦—⟧';

  @override
  String get allPricesBestMarker => '⟦ƀéšŧ ··⟧';

  @override
  String allPricesDelta(String amount) {
    return '⟦+$amount⟧';
  }

  @override
  String allPricesCostPer100km(String cost) {
    return '⟦$cost/100 ķɱ ·⟧';
  }

  @override
  String allPricesVerdictHere(String fuel, String cost) {
    return '⟦Çĥéáƥéšŧ ĥéřé: $fuel áŧ $cost ······⟧';
  }

  @override
  String get allPricesVerdictWinsResults =>
      '⟦çĥéáƥéšŧ óƒ ŧĥé řéšúłŧš ·········⟧';

  @override
  String allPricesMoreFuels(int count) {
    return '⟦+$count⟧';
  }

  @override
  String allPricesMoreFuelsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more fuels',
      one: 'Show 1 more fuel',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get allPricesFewerFuelsTooltip => '⟦Ĥîđé ŧĥé éẋŧřá ƒúéłš ········⟧';

  @override
  String allPricesCellPriceSemantics(String fuel, String price) {
    return '⟦$fuel $price⟧';
  }

  @override
  String allPricesCellCostSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '⟦$fuel $price, $cost ƥéř 100 ķɱ áŧ $consumption ···⟧';
  }

  @override
  String allPricesCellNoPriceSemantics(String fuel) {
    return '⟦$fuel, ñó ƥřîçé ···⟧';
  }

  @override
  String allPricesCellUnavailableSemantics(String fuel) {
    return '⟦$fuel, óúŧ óƒ šŧóçķ ·····⟧';
  }

  @override
  String allPricesCellUnusableSemantics(String fuel) {
    return '⟦$fuel, ñóŧ úšáƀłé ƀý ýóúř ṽéĥîçłé ··········⟧';
  }

  @override
  String get brandMarkFuelGeneric => '⟦Ƒúéł šŧáŧîóñ ·····⟧';

  @override
  String get brandMarkEvGeneric => '⟦Çĥářǧîñǧ ƥóîñŧ ······⟧';

  @override
  String get fillInventoryTitle => '⟦Ƒîłł-úƥ šúɱɱářý ······⟧';

  @override
  String fillInventorySubtitleFull(String date, String fuel) {
    return '⟦Ƒúłł ŧáñķ óñ $date · $fuel ·····⟧';
  }

  @override
  String fillInventorySubtitlePartial(String date, String fuel) {
    return '⟦Ƥářŧîáł ƒîłł óñ $date · $fuel ······⟧';
  }

  @override
  String fillInventoryKmSinceLastFull(String km) {
    return '⟦$km ķɱ šîñçé ŧĥé łášŧ ƒúłł ŧáñķ ··········⟧';
  }

  @override
  String fillInventoryPumpLiters(String liters) {
    return '⟦$liters Ł ƥúɱƥéđ ···⟧';
  }

  @override
  String fillInventoryPumpConsumption(String value) {
    return '⟦Ƥúɱƥ çóñšúɱƥŧîóñ: $value ·······⟧';
  }

  @override
  String fillInventoryRecordedTrips(int coverage, String value) {
    return '⟦Řéçóřđéđ ŧřîƥš: $coverage % óƒ ŧĥé ŧáñķ · $value řáŵ ···········⟧';
  }

  @override
  String get fillInventoryNoRecordedTrips =>
      '⟦Ñó řéçóřđéđ ŧřîƥ îñ ŧĥîš ŧáñķ ···········⟧';

  @override
  String fillInventoryTankNow(String liters, String km) {
    return '⟦Ŧáñķ ñóŵ: $liters Ł · ≈ $km ķɱ áŧ ƥúɱƥ çóñšúɱƥŧîóñ ············⟧';
  }

  @override
  String fillInventoryTankNowNoRange(String liters) {
    return '⟦Ŧáñķ ñóŵ: $liters Ł ····⟧';
  }

  @override
  String fillInventoryCalibrationApplied(
    String before,
    String after,
    String percent,
  ) {
    return '⟦Ƥúɱƥ çáłîƀřáŧîóñ: ×$before → ×$after ($percent %) ·······⟧';
  }

  @override
  String fillInventoryCalibrationSkipped(String reason) {
    return '⟦Ƥúɱƥ çáłîƀřáŧîóñ: šķîƥƥéđ — $reason ··········⟧';
  }

  @override
  String get fillInventorySkipNotFullTank =>
      '⟦ƥářŧîáł ƒîłł (ŧĥé ŧáñķ ŵîñđóŵ šŧáýš óƥéñ) ···············⟧';

  @override
  String get fillInventorySkipCorrection =>
      '⟦çóřřéçŧîóñ éñŧřý, ñóŧ á ƥúɱƥéđ ƒîłł ·············⟧';

  @override
  String get fillInventorySkipNoVehicle =>
      '⟦ñó ṽéĥîçłé óñ ŧĥîš ƒîłł ·········⟧';

  @override
  String get fillInventorySkipNoWindow =>
      '⟦ƒîřšŧ ƒúłł ŧáñķ (ñó ŵîñđóŵ çłóšéđ ýéŧ) ··············⟧';

  @override
  String fillInventorySkipCoverageTooLow(int coverage) {
    return '⟦řéçóřđéđ ŧřîƥš çóṽéř $coverage % óƒ ŧĥé ŧáñķ (60 % ñééđéđ) ···············⟧';
  }

  @override
  String fillInventorySkipRecordedTooShort(String km) {
    return '⟦óñłý $km řéçóřđéđ ķɱ (40 ķɱ ñééđéđ) ··········⟧';
  }

  @override
  String get fillInventorySkipNoRecordedFuel =>
      '⟦ŧĥé řéçóřđéđ ŧřîƥš çářřý ñó ƒúéł ƒîǧúřé ···············⟧';

  @override
  String get fillInventorySkipImplausible =>
      '⟦ƥúɱƥ áñđ řéçóřđîñǧš đîšáǧřéé ŧóó ɱúçĥ — çĥéçķ ŧĥé řéçéîƥŧ ·····················⟧';

  @override
  String get fillInventoryDismiss => '⟦Ǧóŧ îŧ ··⟧';

  @override
  String tankReportResidualAfterCalibration(String percent) {
    return '⟦Ǧáƥ áƒŧéř çáłîƀřáŧîóñ: $percent % ·········⟧';
  }

  @override
  String get tripFuelSourceMeasured => '⟦Ṁéášúřéđ ····⟧';

  @override
  String get tripFuelSourceEstimatedCalibrated =>
      '⟦Éšŧîɱáŧéđ · çáłîƀřáŧéđ ·········⟧';

  @override
  String get tripFuelSourceEstimated => '⟦Éšŧîɱáŧéđ ····⟧';

  @override
  String get tripFuelSourceGps => '⟦ǦƤŠ ·⟧';

  @override
  String get tripFuelSourceMeasuredTooltip =>
      '⟦Ƒúéł řáŧé řéƥóřŧéđ ƀý ŧĥé éñǧîñé (ƤÎĐ 5É / 9Đ / Á2) — ñéṽéř řéšçáłéđ ·····················⟧';

  @override
  String get tripFuelSourceEstimatedTooltip =>
      '⟦Ƒúéł éšŧîɱáŧéđ ƒřóɱ áîř ɱášš — řéšçáłéđ ƀý ŧĥé ƥúɱƥ çáłîƀřáŧîóñ ·······················⟧';

  @override
  String get tripFuelSourceGpsTooltip =>
      '⟦ǦƤŠ-ƥĥýšîçš éšŧîɱáŧé — ñó éñǧîñé đáŧá ··············⟧';

  @override
  String get tripFuelSourceRecalculated => '⟦řéçáłçúłáŧéđ ·····⟧';

  @override
  String tripDetailGainApplied(String percent) {
    return '⟦Ƥúɱƥ ǧáîñ áƥƥłîéđ: $percent % ·······⟧';
  }

  @override
  String tripDetailRecalculatedAfterFill(String date) {
    return '⟦Řéçáłçúłáŧéđ áƒŧéř ŧĥé ƒîłł-úƥ óƒ $date ·············⟧';
  }

  @override
  String get criteriaModeNearby => '⟦Ñéářƀý ···⟧';

  @override
  String get criteriaModeRoute => '⟦Řóúŧé ··⟧';

  @override
  String get criteriaSubmit => '⟦Šéářçĥ ···⟧';

  @override
  String get criteriaReset => '⟦Řéšéŧ ··⟧';

  @override
  String get criteriaResetDone =>
      '⟦Çřîŧéřîá řéšéŧ ŧó ýóúř đéƒáúłŧš ············⟧';

  @override
  String get criteriaSubmitDisabledRoute =>
      '⟦Éñŧéř á šŧářŧ áñđ á đéšŧîñáŧîóñ ············⟧';

  @override
  String get criteriaSubmitDisabledSearching => '⟦Šéářçĥ îñ ƥřóǧřéšš… ·······⟧';

  @override
  String criteriaShowMore(int count) {
    return '⟦Šĥóŵ ɱóřé ($count) ····⟧';
  }

  @override
  String get criteriaShowLess => '⟦Šĥóŵ łéšš ····⟧';

  @override
  String get criteriaBrands => '⟦Ɓřáñđš ···⟧';

  @override
  String get criteriaRouteOptions => '⟦Řóúŧé óƥŧîóñš ·····⟧';

  @override
  String criteriaRouteOptionsSummary(
    int segmentKm,
    int detourKm,
    String saving,
  ) {
    return '⟦Éṽéřý $segmentKm ķɱ · $detourKm ķɱ đéŧóúř · $saving ·······⟧';
  }

  @override
  String get criteriaSwapEndpoints => '⟦Šŵáƥ šŧářŧ áñđ đéšŧîñáŧîóñ ··········⟧';

  @override
  String get fillUpOdometerFromLastFillUp =>
      '⟦Ƥřé-ƒîłłéđ ƒřóɱ ýóúř łášŧ ƒîłł-úƥ ············⟧';

  @override
  String get fillUpStationLabel => '⟦Šŧáŧîóñ ···⟧';

  @override
  String get fillUpStationChange => '⟦Çĥáñǧé ···⟧';

  @override
  String get pickStationSectionLast => '⟦Łášŧ šŧáŧîóñ ·····⟧';

  @override
  String get pickStationSectionFavorites => '⟦Ƒáṽóřîŧéš ····⟧';

  @override
  String get pickStationSectionNearby => '⟦Ñéářƀý ···⟧';

  @override
  String get pickStationNearbyEmpty =>
      '⟦Ñó řéçéñŧ šéářçĥ — šéářçĥ ƒóř šŧáŧîóñš óñ ŧĥé Šéářçĥ ŧáƀ áñđ ŧĥé ñéářéšŧ óñéš ŵîłł áƥƥéář ĥéřé. ··································⟧';

  @override
  String pickStationLastFillUpAt(String date) {
    return '⟦Łášŧ ƒîłł-úƥ: $date ·····⟧';
  }

  @override
  String get privacyTopicSubtitle =>
      '⟦Ýóúř çĥóîçéš, đáŧá óñ ŧĥîš đéṽîçé, šýñç, éẋƥóřŧ óř đéłéŧé ····················⟧';

  @override
  String get privacyDataLocationLocal =>
      '⟦Ýóúř đáŧá šŧáýš óñ ŧĥîš đéṽîçé ···········⟧';

  @override
  String get privacyDataLocationSynced =>
      '⟦Ýóúř đáŧá îš áłšó šýñçéđ ŧó ŦáñķŠýñç ··············⟧';

  @override
  String get privacySyncLineEnabledAnonymous =>
      '⟦Šýñç: óñ · áñóñýɱóúš áççóúñŧ ··········⟧';

  @override
  String get privacySyncLineEnabledEmail =>
      '⟦Šýñç: óñ · éɱáîł áççóúñŧ ········⟧';

  @override
  String get privacySyncLineDisabled => '⟦Šýñç: óƒƒ ···⟧';

  @override
  String privacyStorageLine(String size) {
    return '⟦$size šŧóřéđ óñ ŧĥîš đéṽîçé ········⟧';
  }

  @override
  String get privacyTopicChoicesTitle => '⟦Ýóúř çĥóîçéš ·····⟧';

  @override
  String privacyChoicesStatus(int on, int total) {
    return '⟦$on óƒ $total éñáƀłéđ ····⟧';
  }

  @override
  String privacyDeviceDataStatus(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '⟦$size · $_temp0⟧';
  }

  @override
  String get privacyTopicExportDeleteTitle => '⟦Éẋƥóřŧ óř đéłéŧé ······⟧';

  @override
  String privacyExportDeleteStatus(int count) {
    return '⟦ŽÎƤ, ĴŠÓÑ, ÇŠṼ · éřřóř łóǧ ($count) ········⟧';
  }

  @override
  String get privacyLearnMore => '⟦Łéářñ ɱóřé ····⟧';

  @override
  String get tileProxyToggleShort =>
      '⟦Ŧîłéš çóɱé ṽîá ŧĥé đéṽéłóƥéř\'š ÉÚ ƥřóẋý, ñóŧ šŧřáîǧĥŧ ƒřóɱ ÓƥéñŠŧřééŧṀáƥ ···························⟧';

  @override
  String get remoteLogosToggleShort =>
      '⟦Ƒéŧçĥ ƀřáñđ łóǧóš ƒřóɱ łóǧó.çłéářƀîŧ.çóɱ îñšŧéáđ óƒ ƀúñđłéđ ƥłáçéĥółđéřš ····························⟧';

  @override
  String get privacyCacheDetails => '⟦Çáçĥé đéŧáîłš ·····⟧';

  @override
  String privacyCacheResponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cached responses',
      one: '1 cached response',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String privacyClearCacheEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '⟦Çłéář çáçĥé ($_temp0) ·····⟧';
  }

  @override
  String get privacySyncStatusLabel => '⟦Šŧáŧúš ···⟧';

  @override
  String get privacySyncModeCommunity =>
      '⟦Šƥářķîłó Çóɱɱúñîŧý — ŧĥé đéṽéłóƥéř\'š ÉÚ šéřṽéř ·················⟧';

  @override
  String get privacySyncModeSelfHosted =>
      '⟦Šéłƒ-ĥóšŧéđ — ýóúř óŵñ Šúƥáƀášé ···········⟧';

  @override
  String get privacySyncModeSharedGroup =>
      '⟦Šĥářéđ ǧřóúƥ — á đáŧáƀášé ýóú ĵóîñéđ ·············⟧';

  @override
  String get privacySyncAccountLabel => '⟦Áççóúñŧ ···⟧';

  @override
  String get privacySyncAccountAnonymous =>
      '⟦Áñóñýɱóúš áççóúñŧ, ŧîéđ ŧó ŧĥîš đéṽîçé ··············⟧';

  @override
  String privacySyncAccountEmail(String email) {
    return '⟦Éɱáîł áççóúñŧ: $email ·····⟧';
  }

  @override
  String get privacyCopyUserId => '⟦Çóƥý úšéř ÎĐ ·····⟧';

  @override
  String get privacyUserIdCopied => '⟦Úšéř ÎĐ çóƥîéđ ·····⟧';

  @override
  String get privacySyncDatabaseHost => '⟦Đáŧáƀášé ĥóšŧ ·····⟧';

  @override
  String get privacyExportSectionTitle => '⟦Éẋƥóřŧ ···⟧';

  @override
  String get privacyExportMyData => '⟦Éẋƥóřŧ ɱý đáŧá ·····⟧';

  @override
  String get privacyExportSheetTitle => '⟦Çĥóóšé á ƒóřɱáŧ ······⟧';

  @override
  String get privacyExportZipTitle => '⟦ŽÎƤ ářçĥîṽé ·····⟧';

  @override
  String get privacyExportZipSubtitle =>
      '⟦Éṽéřýŧĥîñǧ, áŧŧáçĥɱéñŧš îñçłúđéđ — ƒóř á çóɱƥłéŧé ƀáçķúƥ ·····················⟧';

  @override
  String get privacyExportJsonTitle => '⟦ĴŠÓÑ ··⟧';

  @override
  String get privacyExportJsonSubtitle =>
      '⟦Ṁáçĥîñé-řéáđáƀłé — ƒóř áñóŧĥéř áƥƥ ·············⟧';

  @override
  String get privacyExportCsvTitle => '⟦ÇŠṼ ·⟧';

  @override
  String get privacyExportCsvSubtitle =>
      '⟦Šƥřéáđšĥééŧ — óñé ŧáƀłé ƥéř çáŧéǧóřý ··············⟧';

  @override
  String get privacyErrorLogTitle => '⟦Éřřóř łóǧ ····⟧';

  @override
  String privacyErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get privacyErrorLogSave => '⟦Šáṽé ··⟧';

  @override
  String get privacyErrorLogClear => '⟦Çłéář ··⟧';

  @override
  String get privacyDangerZoneTitle => '⟦Đáñǧéř žóñé ·····⟧';

  @override
  String get privacyDangerZoneBody =>
      '⟦Ƥéřɱáñéñŧłý đéłéŧéš éṽéřýŧĥîñǧ ŧĥé áƥƥ šŧóřéš óñ ŧĥîš đéṽîçé. Ŵîŧĥ šýñç óñ, ýóúř đáŧá óñ ŧĥé ŦáñķŠýñç šéřṽéř îš éřášéđ ŧóó. ·············································⟧';

  @override
  String get privacyDeleteAllMyData => '⟦Đéłéŧé áłł ɱý đáŧá ·······⟧';

  @override
  String get tripRecordingScreenTitle => '⟦Ŧřîƥ îñ ƥřóǧřéšš ······⟧';

  @override
  String get recordingObd2ChipLive => '⟦Łîṽé ··⟧';

  @override
  String recordingObd2ChipLiveRate(int rate) {
    return '⟦Łîṽé · $rate ƤÎĐ/š ····⟧';
  }

  @override
  String get recordingObd2ChipReconnecting => '⟦Řéçóññéçŧîñǧ… ·····⟧';

  @override
  String recordingObd2ChipReconnectingAttempt(int attempt) {
    return '⟦Řéçóññéçŧîñǧ… (ŧřý $attempt) ·······⟧';
  }

  @override
  String get recordingObd2ChipGpsOnly => '⟦ǦƤŠ óñłý ···⟧';

  @override
  String get recordingObd2ChipEngineOff => '⟦Éñǧîñé óƒƒ — ŵáîŧîñǧ ·······⟧';

  @override
  String get recordingObd2ChipNoAdapter => '⟦Ñó áđáƥŧéř ····⟧';

  @override
  String get recordingObd2SheetTitle => '⟦ÓƁĐ2 łîñķ ···⟧';

  @override
  String get recordingObd2SheetLive =>
      '⟦Ŧĥé áđáƥŧéř îš đéłîṽéřîñǧ éñǧîñé đáŧá, šó çóñšúɱƥŧîóñ îš ɱéášúřéđ ƒřóɱ ŧĥé çář. Ñóŧĥîñǧ ŧó đó — ķééƥ đřîṽîñǧ. ·······································⟧';

  @override
  String get recordingObd2SheetReconnecting =>
      '⟦Ŧĥé Ɓłúéŧóóŧĥ łîñķ îš ƀéîñǧ řé-éšŧáƀłîšĥéđ; ɱéáñŵĥîłé ŧĥé řéçóřđîñǧ çóñŧîñúéš óñ ǦƤŠ. Ñó áçŧîóñ ñééđéđ — á řéšéŧ óñłý ĥéłƥš îƒ îŧ šŧáýš łîķé ŧĥîš ƒóř ɱîñúŧéš. ·························································⟧';

  @override
  String get recordingObd2SheetGpsOnly =>
      '⟦Ŧĥé áđáƥŧéř ĥáš ñóŧ áñšŵéřéđ ƒóř á ŵĥîłé, šó ŧĥé áƥƥ ŵáîŧš ƒóř îŧ ŧó řéáƥƥéář áñđ řéçóřđš óñ ǦƤŠ. Çóñšúɱƥŧîóñ îš éšŧîɱáŧéđ úñŧîł îŧ îš ƀáçķ. ··················································⟧';

  @override
  String get recordingObd2SheetEngineOff =>
      '⟦Ŧĥé éñǧîñé îš óƒƒ, šó ŧĥéřé îš ñóŧĥîñǧ ŧó řéáđ. Ŧĥé řéçóřđîñǧ çóñŧîñúéš óñ ǦƤŠ áñđ ƥîçķš ŧĥé áđáƥŧéř úƥ áǧáîñ áš šóóñ áš ŧĥé éñǧîñé řúñš. ·················································⟧';

  @override
  String get recordingObd2SheetNoAdapter =>
      '⟦Ŧĥîš ŧřîƥ îš řéçóřđéđ ŵîŧĥóúŧ áñ ÓƁĐ2 áđáƥŧéř. Šƥééđ áñđ đîšŧáñçé çóɱé ƒřóɱ ǦƤŠ; çóñšúɱƥŧîóñ îš á ƥĥýšîçš éšŧîɱáŧé çáłîƀřáŧéđ ƀý ýóúř ƒîłł-úƥš. ····················································⟧';

  @override
  String recordingGpsChipPrecise(int meters) {
    return '⟦Ƥřéçîšé ƒîẋ (±$meters ɱ) ·····⟧';
  }

  @override
  String recordingGpsChipApprox(int meters) {
    return '⟦Áƥƥřóẋîɱáŧé ƒîẋ (±$meters ɱ) ·······⟧';
  }

  @override
  String get recordingGpsChipNoFix => '⟦Ñó ƒîẋ ··⟧';

  @override
  String get recordingGpsChipFixUnknownAccuracy =>
      '⟦Ƒîẋ (áççúřáçý úñķñóŵñ) ········⟧';

  @override
  String recordingGpsChipWithCoverage(String fix, int percent) {
    return '⟦$fix · $percent %⟧';
  }

  @override
  String get recordingGpsSheetTitle => '⟦ǦƤŠ šîǧñáł ····⟧';

  @override
  String get recordingGpsSheetPrecise =>
      '⟦Ŧĥé ƥóšîŧîóñ îš áççúřáŧé ŧó á ƒéŵ ɱéŧřéš, šó đîšŧáñçé áñđ ŧĥé ŧřáçé ářé řéłîáƀłé. ·····························⟧';

  @override
  String get recordingGpsSheetApprox =>
      '⟦Ŧĥé ƥóšîŧîóñ îš óñłý áççúřáŧé ŧó ŧéñš óƒ ɱéŧřéš — ŧýƥîçáł îñ çîŧîéš, ŧúññéłš óř úñđéř ŧřééš. Đîšŧáñçé ɱáý đřîƒŧ šłîǧĥŧłý úñŧîł ŧĥé ƒîẋ îɱƥřóṽéš. ····················································⟧';

  @override
  String get recordingGpsSheetNoFix =>
      '⟦Ñó ƥóšîŧîóñ ĥáš ářřîṽéđ řéçéñŧłý. Çĥéçķ ŧĥáŧ łóçáŧîóñ îš áłłóŵéđ áñđ ŧĥé ƥĥóñé çáñ šéé ŧĥé šķý; ŧĥé řéçóřđîñǧ řéšúɱéš ŵîŧĥ ŧĥé ñéẋŧ ƒîẋ. ··················································⟧';

  @override
  String recordingGpsSheetCoverage(int percent) {
    return '⟦Çóṽéřáǧé šó ƒář: $percent % óƒ ŧĥé šéçóñđš ĥáđ á ƒîẋ. ··············⟧';
  }

  @override
  String get recordingSheetClose => '⟦Ǧóŧ îŧ ··⟧';

  @override
  String get fuelSourceMeasured => '⟦Ṁéášúřéđ (ÉÇÚ ƒúéł ƒłóŵ) ·········⟧';

  @override
  String fuelSourceEstimatedCalibrated(int percent) {
    return '⟦Éšŧîɱáŧéđ · ƥúɱƥ-çáłîƀřáŧéđ ±$percent % ··········⟧';
  }

  @override
  String get fuelSourceEstimatedUncalibrated =>
      '⟦Éšŧîɱáŧéđ · ñóŧ çáłîƀřáŧéđ ··········⟧';

  @override
  String get fuelSourceGpsEstimate => '⟦ǦƤŠ éšŧîɱáŧé ·····⟧';

  @override
  String get recordingTileScore => '⟦Đřîṽîñǧ šçóřé ·····⟧';

  @override
  String searchSummaryAlongRoute(String km) {
    return '⟦Áłóñǧ ŧĥé řóúŧé · éṽéřý $km ķɱ ·········⟧';
  }

  @override
  String get searchSummaryPricesJustNow => '⟦Ƥřîçéš ƒřóɱ ĵúšŧ ñóŵ ········⟧';

  @override
  String searchSummaryPricesMinutes(int minutes) {
    return '⟦Ƥřîçéš ƒřóɱ $minutes ɱîñ áǧó ·······⟧';
  }

  @override
  String searchSummaryPricesHours(int hours) {
    return '⟦Ƥřîçéš ƒřóɱ $hours ĥ áǧó ······⟧';
  }

  @override
  String searchSummaryPricesDays(int days) {
    return '⟦Ƥřîçéš ƒřóɱ $days đ áǧó ······⟧';
  }

  @override
  String get searchResultsFilterTooltip => '⟦Ƒîłŧéřš ···⟧';

  @override
  String searchResultsFilterActiveSemantic(int count) {
    return '⟦Ƒîłŧéřš, $count áçŧîṽé ······⟧';
  }

  @override
  String get searchResultsMoreActionsTooltip => '⟦Ṁóřé áçŧîóñš ·····⟧';

  @override
  String get searchPriceArrowLegend =>
      '⟦↓ áñđ ↑ çóɱƥářé éáçĥ ƥřîçé ŵîŧĥ ŧĥé óŧĥéř šŧáŧîóñš îñ ŧĥîš łîšŧ. ······················⟧';

  @override
  String get searchPriceArrowCheapTooltip =>
      '⟦Áɱóñǧ ŧĥé łóŵéšŧ ƥřîçéš îñ ŧĥîš łîšŧ ··············⟧';

  @override
  String get searchPriceArrowAverageTooltip =>
      '⟦Á ɱîđ-řáñǧé ƥřîçé îñ ŧĥîš łîšŧ ···········⟧';

  @override
  String get searchPriceArrowExpensiveTooltip =>
      '⟦Áɱóñǧ ŧĥé ĥîǧĥéšŧ ƥřîçéš îñ ŧĥîš łîšŧ ··············⟧';

  @override
  String get searchRefreshTooltip =>
      '⟦Úƥđáŧé ƥóšîŧîóñ áñđ řéƒřéšĥ ƥřîçéš ··············⟧';

  @override
  String priceHistoryFirstSeen(String date) {
    return '⟦Ƒîřšŧ šééñ óñ $date — ŧĥé ĥîšŧóřý ƀúîłđš úƥ ŵîŧĥ éṽéřý ṽîšîŧ ···················⟧';
  }

  @override
  String priceHistoryCurrentPriceLine(String price) {
    return '⟦Çúřřéñŧ ƥřîçé: $price ·····⟧';
  }

  @override
  String priceHistoryDeltaSince(String delta, String date) {
    return '⟦$delta šîñçé $date ··⟧';
  }

  @override
  String priceHistoryUnchangedSince(String date) {
    return '⟦Úñçĥáñǧéđ šîñçé $date ······⟧';
  }

  @override
  String get priceStatsMin => '⟦Ṁîñ ·⟧';

  @override
  String get priceStatsMax => '⟦Ṁáẋ ·⟧';

  @override
  String get priceStatsAvg => '⟦Áṽǧ ·⟧';

  @override
  String get amenitiesAndServices => '⟦Áɱéñîŧîéš & šéřṽîçéš ········⟧';

  @override
  String amenitiesServicesShowMore(int count) {
    return '⟦Šĥóŵ ɱóřé ($count) ····⟧';
  }

  @override
  String get amenitiesServicesShowLess => '⟦Šĥóŵ łéšš ····⟧';

  @override
  String stationStatusWithFreshness(String status, String ago) {
    return '⟦$status · úƥđáŧéđ $ago áǧó ·····⟧';
  }

  @override
  String pricesNotSoldHere(String fuels) {
    return '⟦Ñóŧ šółđ ĥéřé: $fuels ·····⟧';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return '⟦Řéçóřđéđ ŧřîƥš çóṽéř $pct % óƒ ŧĥîš ŧáñķ ·············⟧';
  }

  @override
  String tankReportRecordedTripsAvg(String value) {
    return '⟦Řéçóřđéđ ŧřîƥš: $value ······⟧';
  }

  @override
  String tankReportRecordedTripsOverestimate(String pct) {
    return '⟦Ýóúř řéçóřđéđ ŧřîƥš óṽéřéšŧîɱáŧé çóñšúɱƥŧîóñ ƀý $pct % ···················⟧';
  }

  @override
  String tankReportRecordedTripsUnderestimate(String pct) {
    return '⟦Ýóúř řéçóřđéđ ŧřîƥš úñđéřéšŧîɱáŧé çóñšúɱƥŧîóñ ƀý $pct % ···················⟧';
  }

  @override
  String get trajetObd2DegradedSubtitle =>
      '⟦Ñó éñǧîñé đáŧá — ǦƤŠ éšŧîɱáŧé ··········⟧';

  @override
  String get vehicleTopicAdapterNone => '⟦Ñóñé ··⟧';

  @override
  String get vehicleTopicCalibrationTitle => '⟦Çáłîƀřáŧîóñ ·····⟧';

  @override
  String get vehicleTopicAdvancedBadge => '⟦Áđṽáñçéđ ····⟧';

  @override
  String vehicleTopicCalibrationStatus(int coverage, String mode) {
    return '⟦Ɓášéłîñé $coverage % · $mode ····⟧';
  }

  @override
  String vehicleTopicRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
      zero: 'No reminders',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get vehicleTopicAutoRecordOn => '⟦Óñ ·⟧';

  @override
  String get vehicleTopicAutoRecordOff => '⟦Óƒƒ ·⟧';

  @override
  String get vehicleTopicAutoRecordPairLinkText =>
      '⟦Ƥáîř áñ áđáƥŧéř úñđéř “ÓƁĐ2 áđáƥŧéř” ŧó éñáƀłé áúŧó-řéçóřđîñǧ ······················⟧';

  @override
  String vehicleBaselineCoverageSamples(int covered, int max) {
    return '⟦$covered / $max šáɱƥłéš ···⟧';
  }

  @override
  String vehicleBaselineRawSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get calibrationModeRuleDescription =>
      '⟦Šóřŧš éáçĥ đřîṽîñǧ šáɱƥłé îñŧó óñé šîŧúáŧîóñ úšîñǧ ƒîẋéđ šƥééđ áñđ łóáđ ŧĥřéšĥółđš. ································⟧';

  @override
  String get calibrationModeFuzzyDescription =>
      '⟦Šƥłîŧš éáçĥ šáɱƥłé áçřóšš ñéîǧĥƀóúřîñǧ šîŧúáŧîóñš ƀý ĥóŵ ŵéłł îŧ ƒîŧš éáçĥ óñé — šɱóóŧĥéř éšŧîɱáŧéš ářóúñđ ŧĥé ƀóúñđářîéš. ··············································⟧';

  @override
  String get pumpGainChipNotCalibrated => '⟦Ñóŧ ƥúɱƥ-çáłîƀřáŧéđ ýéŧ ·········⟧';

  @override
  String pumpGainChipCalibrated(int fills, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      fills,
      locale: localeName,
      other: 'Pump-calibrated · $fills fill-ups · ±$percent %',
      one: 'Pump-calibrated · 1 fill-up · ±$percent %',
    );
    return '⟦$_temp0⟧';
  }

  @override
  String get pumpGainResetAction => '⟦Řéšéŧ ƥúɱƥ çáłîƀřáŧîóñ ·········⟧';

  @override
  String get pumpGainResetConfirmTitle => '⟦Řéšéŧ ƥúɱƥ çáłîƀřáŧîóñ? ·········⟧';

  @override
  String get pumpGainResetConfirmBody =>
      '⟦Ŧĥîš đîšçářđš ŧĥé ƒúéł ǧáîñ łéářñéđ ƒřóɱ ýóúř ƒîłł-úƥš. ÓƁĐ2 çóñšúɱƥŧîóñ éšŧîɱáŧéš ƒáłł ƀáçķ ŧó ŧĥé úñçóřřéçŧéđ ƒîǧúřé úñŧîł ŧĥé ñéẋŧ ƒúłł-ŧó-ƒúłł ŧáñķ ŵîñđóŵ řé-łéářñš îŧ. ·······························································⟧';

  @override
  String get vehicleMultiFuelCapableLabel =>
      '⟦Î ɱáý ƒîłł úƥ ŵîŧĥ đîƒƒéřéñŧ ƒúéł ŧýƥéš ··············⟧';

  @override
  String get vehicleMultiFuelCapableHelper =>
      '⟦Ŧřáçķš ŵĥîçĥ ƒúéł îš çĥéáƥéšŧ ƥéř ķîłóɱéŧřé ·················⟧';

  @override
  String get vinLabel => '⟦ṼÎÑ (óƥŧîóñáł) ·····⟧';

  @override
  String get vinDecodeTooltip => '⟦Đéçóđé ṼÎÑ ····⟧';

  @override
  String get vinConfirmAction => '⟦Ýéš, áúŧó-ƒîłł ·····⟧';

  @override
  String get vinModifyAction => '⟦Ṁóđîƒý ɱáñúáłłý ······⟧';

  @override
  String get vehicleReadVinFromCarButton => '⟦Řéáđ ṼÎÑ ƒřóɱ çář ······⟧';

  @override
  String get vehicleReadVinFromCarTooltip =>
      '⟦Řéáđ ṼÎÑ ƒřóɱ ŧĥé ƥáîřéđ ÓƁĐ2 áđáƥŧéř ··············⟧';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      '⟦ṼÎÑ ñóŧ áṽáîłáƀłé (Ṁóđé 09 ƤÎĐ 02 úñšúƥƥóřŧéđ óñ ƥřé-2005 ṽéĥîçłéš) ·····················⟧';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      '⟦ṼÎÑ řéáđ ƒáîłéđ — ƥłéášé éñŧéř ɱáñúáłłý ··············⟧';

  @override
  String get vehicleReadVinNoAdapterHint =>
      '⟦Ƥáîř áñ ÓƁĐ2 áđáƥŧéř ƒîřšŧ ŧó řéáđ ṼÎÑ áúŧóɱáŧîçáłłý ···················⟧';

  @override
  String get pickerButtonLabel => '⟦Ƥîçķ ƒřóɱ çáŧáłóǧ ·······⟧';

  @override
  String get pickerSearchHint => '⟦Šéářçĥ ɱáķé óř ɱóđéł ········⟧';

  @override
  String get pickerHelpText =>
      '⟦Ƥřé-ƒîłł ƒřóɱ 50+ šúƥƥóřŧéđ ṽéĥîçłéš ·············⟧';

  @override
  String get pickerEmptyResults => '⟦Ñó ɱáŧçĥéš ····⟧';

  @override
  String get pickerCancel => '⟦Çáñçéł ···⟧';

  @override
  String get pickerLoading => '⟦Łóáđîñǧ çáŧáłóǧ… ······⟧';

  @override
  String get vinInfoTooltip => '⟦Ŵĥáŧ îš á ṼÎÑ? ·····⟧';

  @override
  String get vinInfoSectionWhatTitle => '⟦Ŵĥáŧ îš á ṼÎÑ? ·····⟧';

  @override
  String get vinInfoSectionWhatBody =>
      '⟦Ŧĥé Ṽéĥîçłé Îđéñŧîƒîçáŧîóñ Ñúɱƀéř îš á 17-çĥářáçŧéř çóđé úñîɋúé ŧó ýóúř çář. Îŧ\'š šŧáɱƥéđ óñ ŧĥé çĥáššîš áñđ ƥřîñŧéđ óñ ýóúř ṽéĥîçłé řéǧîšŧřáŧîóñ đóçúɱéñŧ. ·························································⟧';

  @override
  String get vinInfoSectionWhyTitle => '⟦Ŵĥý ŵé ášķ ····⟧';

  @override
  String get vinInfoSectionWhyBody =>
      '⟦Đéçóđîñǧ ŧĥé ṼÎÑ áúŧó-ƒîłłš éñǧîñé đîšƥłáçéɱéñŧ, çýłîñđéř çóúñŧ, ɱóđéł ýéář, ƥřîɱářý ƒúéł ŧýƥé, áñđ ǧřóšš ŵéîǧĥŧ — šáṽîñǧ ýóú ƒřóɱ łóóķîñǧ úƥ ŧéçĥñîçáł šƥéçš ɱáñúáłłý. Ŧĥé ÓƁĐ2 ƒúéł-řáŧé çáłçúłáŧîóñ úšéš ŧĥéšé ṽáłúéš ŧó ǧîṽé ýóú áççúřáŧé çóñšúɱƥŧîóñ ñúɱƀéřš. ·······························································································⟧';

  @override
  String get vinInfoSectionPrivacyTitle => '⟦Ƥřîṽáçý ···⟧';

  @override
  String get vinInfoSectionPrivacyBody =>
      '⟦Ýóúř ṼÎÑ îš šŧóřéđ óñłý łóçáłłý îñ ŧĥé áƥƥ\'š éñçřýƥŧéđ šŧóřáǧé — îŧ\'š ñéṽéř úƥłóáđéđ ŧó Šƥářķîłó šéřṽéřš. Ŧĥé ÑĤŦŠÁ ṽƤÎÇ đáŧáƀášé îš ɋúéřîéđ ŵîŧĥ ŧĥé ṼÎÑ ƀúŧ řéŧúřñš óñłý áñóñýɱóúš ŧéçĥñîçáł šƥéçš; ÑĤŦŠÁ đóéš ñóŧ łîñķ ŧĥé ṼÎÑ ŧó áñý ƥéřšóñáł đáŧá. Ŵîŧĥóúŧ ñéŧŵóřķ, áñ óƒƒłîñé łóóķúƥ řéŧúřñš ɱáñúƒáçŧúřéř áñđ çóúñŧřý óñłý. ·····················································································································⟧';

  @override
  String get vinInfoSectionWhereTitle => '⟦Ŵĥéřé ŧó ƒîñđ îŧ ······⟧';

  @override
  String get vinInfoSectionWhereBody =>
      '⟦Łóóķ ŧĥřóúǧĥ ŧĥé ŵîñđšĥîéłđ áŧ ŧĥé łóŵéř-łéƒŧ çóřñéř óñ ŧĥé đřîṽéř\'š šîđé, çĥéçķ ŧĥé đřîṽéř-šîđé đóóř-ƒřáɱé šŧîçķéř ŵĥéñ ŧĥé đóóř îš óƥéñ, óř řéáđ îŧ óƒƒ ýóúř ṽéĥîçłé řéǧîšŧřáŧîóñ đóçúɱéñŧ (çářđ / Çářŧé Ǧřîšé). ···········································································⟧';

  @override
  String get vinInfoDismiss => '⟦Ǧóŧ îŧ ··⟧';

  @override
  String get vinConfirmPrivacyNote =>
      '⟦Ŵé łóóķéđ úƥ ýóúř ṼÎÑ óñ ÑĤŦŠÁ\'š ƒřéé ṽéĥîçłé đáŧáƀášé — ñóŧĥîñǧ šéñŧ ŧó Šƥářķîłó šéřṽéřš. ································⟧';

  @override
  String get gdprVinOnlineDecodeTitle => '⟦ṼÎÑ óñłîñé đéçóđé ·······⟧';

  @override
  String get gdprVinOnlineDecodeShort =>
      '⟦Đéçóđé ŧĥé ṼÎÑ ṽîá ÑĤŦŠÁ\'š ƒřéé ƥúƀłîç šéřṽîçé ·················⟧';

  @override
  String get gdprVinOnlineDecodeDescription =>
      '⟦Ŵĥéñ ýóú ƥáîř áñ áđáƥŧéř, ýóúř ṽéĥîçłé\'š ṼÎÑ îš řéáđ łóçáłłý ŧó îđéñŧîƒý ŧĥé çář. Éñáƀłîñǧ ŧĥîš šéñđš ŧĥé 17-çĥář ṼÎÑ ŧó ÑĤŦŠÁ\'š ƒřéé ṽƤÎÇ šéřṽîçé ŧó łóóķ úƥ áđđîŧîóñáł đéŧáîłš (ɱóđéł, éñǧîñé đîšƥłáçéɱéñŧ, ƒúéł ŧýƥé). Ŧĥé ṼÎÑ îš ŧĥé óñłý đáŧá šéñŧ — ñó óŧĥéř îñƒóřɱáŧîóñ łéáṽéš ýóúř đéṽîçé. ······································································································⟧';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return '⟦Đéŧéçŧéđ ƒřóɱ ṼÎÑ: $summary. Áƥƥłý? ·········⟧';
  }

  @override
  String get vehicleDetectedFromVinApply => '⟦Áƥƥłý ··⟧';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '⟦$name, $distanceKm ķîłóɱéŧéřš áĥéáđ, $fuelType $euros éúřóš $cents ·········⟧';
  }

  @override
  String get widgetHelpSectionTitle => '⟦Ĥóɱé-šçřééñ ŵîđǧéŧ ·······⟧';

  @override
  String get widgetHelpIntro =>
      '⟦Áđđ ŧĥé ŠƥářĶîłó ŵîđǧéŧ ŧó ýóúř ĥóɱé šçřééñ ŧó šéé ƒúéł áñđ çĥářǧîñǧ ƥřîçéš áŧ á ǧłáñçé. ································⟧';

  @override
  String get widgetHelpAdd =>
      '⟦Áđđ îŧ ƒřóɱ ýóúř łáúñçĥéř\'š ŵîđǧéŧ ƥîçķéř — łóñǧ-ƥřéšš áñ éɱƥŧý ářéá óƒ ŧĥé ĥóɱé šçřééñ, çĥóóšé Ŵîđǧéŧš, áñđ ƒîñđ ŠƥářĶîłó. ············································⟧';

  @override
  String get widgetHelpTap =>
      '⟦Ŧáƥ á šŧáŧîóñ îñ ŧĥé ŵîđǧéŧ ŧó óƥéñ îŧ îñ ŧĥé áƥƥ. Ŧáƥ ŧĥé řéƒřéšĥ îçóñ ŧó úƥđáŧé ƥřîçéš. ·······························⟧';

  @override
  String get widgetHelpConfigure =>
      '⟦Óñ Áñđřóîđ, łóñǧ-ƥřéšš ŧĥé ŵîđǧéŧ áñđ çĥóóšé Řéçóñƒîǧúřé ŧó çĥáñǧé ŧĥé ƥřóƒîłé, çółóúř, áñđ çóñŧéñŧ. ····································⟧';

  @override
  String get widgetDefaultsThisProfileHint =>
      '⟦Çĥóîçéš ƀéłóŵ áƥƥłý ŧó éṽéřý îñšŧáłłéđ ŵîđǧéŧ šĥóŵîñǧ ŧĥîš ƥřóƒîłé, óñ ŧĥé ñéẋŧ řéƒřéšĥ. ·································⟧';

  @override
  String get widgetDefaultsColorLabel => '⟦Çółóúř šçĥéɱé ·····⟧';

  @override
  String get widgetDefaultsVariantLabel => '⟦Çóñŧéñŧ ṽářîáñŧ ······⟧';

  @override
  String get widgetColorSchemeSystem => '⟦Ƒółłóŵ šýšŧéɱ ·····⟧';

  @override
  String get widgetColorSchemeLight => '⟦Łîǧĥŧ ··⟧';

  @override
  String get widgetColorSchemeDark => '⟦Đářķ ··⟧';

  @override
  String get widgetColorSchemeBlue => '⟦Ɓłúé ··⟧';

  @override
  String get widgetColorSchemeGreen => '⟦Ǧřééñ ··⟧';

  @override
  String get widgetColorSchemeOrange => '⟦Óřáñǧé ···⟧';

  @override
  String get widgetVariantDefault => '⟦Çúřřéñŧ ƥřîçé óñłý ·······⟧';

  @override
  String get widgetVariantPredictive =>
      '⟦Ƥřéđîçŧîṽé: ƀéšŧ ŧîɱé ŧó ƒîłł ···········⟧';
}
