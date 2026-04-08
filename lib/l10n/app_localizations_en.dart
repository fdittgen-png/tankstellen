// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fuel Prices';

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
  String get searchButton => 'Search';

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
  String get apiKeyDescription => 'Register once for a free API key.';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get register => 'Registration';

  @override
  String get continueButton => 'Continue';

  @override
  String get welcome => 'Fuel Prices';

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
  String get demoMode => 'Demo mode — sample data shown.';

  @override
  String get setupLiveData => 'Set up for live data';

  @override
  String get freeNoKey => 'Free — no key needed';

  @override
  String get apiKeyRequired => 'API key required';

  @override
  String get skipWithoutKey => 'Continue without key';

  @override
  String get dataTransparency => 'Data transparency';

  @override
  String get storageAndCache => 'Storage & cache';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearAllData => 'Delete all data';

  @override
  String get errorLog => 'Error log';

  @override
  String stationsFound(int count) {
    return '$count stations found';
  }

  @override
  String get whatIsShared => 'What is shared — and with whom?';

  @override
  String get gpsCoordinates => 'GPS coordinates';

  @override
  String get gpsReason =>
      'Sent with every location search to find nearby stations.';

  @override
  String get postalCodeData => 'Postal code';

  @override
  String get postalReason => 'Converted to coordinates via geocoding service.';

  @override
  String get mapViewport => 'Map viewport';

  @override
  String get mapReason =>
      'Map tiles are loaded from the tile server. No personal data is transmitted.';

  @override
  String get apiKeyData => 'API Key';

  @override
  String get apiKeyReason =>
      'Your personal key is sent with every API request. It is linked to your email.';

  @override
  String get notShared => 'NOT shared:';

  @override
  String get searchHistory => 'Search history';

  @override
  String get favoritesData => 'Favorites';

  @override
  String get profileNames => 'Profile names';

  @override
  String get homeZipData => 'Home ZIP';

  @override
  String get usageData => 'Usage data';

  @override
  String get privacyBanner =>
      'This app has no server. All data stays on your device. No analytics, no tracking, no ads.';

  @override
  String get storageUsage => 'Storage usage on this device';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get profilesStored => 'profiles stored';

  @override
  String get stationsMarked => 'stations marked';

  @override
  String get cachedResponses => 'cached responses';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Cache management';

  @override
  String get cacheDescription =>
      'The cache stores API responses for faster loading and offline access.';

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
  String get deleteAllTitle => 'Delete all data?';

  @override
  String get deleteAllBody =>
      'This permanently deletes all profiles, favorites, API key, settings, and cache. The app will reset.';

  @override
  String get deleteAllButton => 'Delete all';

  @override
  String get entries => 'entries';

  @override
  String get cacheEmpty => 'Cache is empty';

  @override
  String get noStorage => 'No storage used';

  @override
  String get apiKeyNote =>
      'Free registration. Data from government price transparency agencies.';

  @override
  String get apiKeyFormatError => 'Invalid format — expected UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Support this project';

  @override
  String get supportDescription =>
      'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.';

  @override
  String get reportBug => 'Report a bug / Suggest a feature';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get fuels => 'Fuels';

  @override
  String get services => 'Services';

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
  String get demoModeBanner =>
      'Demo mode. Configure API key in settings for live prices.';

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
  String stationsOnMap(int count) {
    return '$count stations';
  }

  @override
  String get loadingFavorites =>
      'Loading favorites...\nSearch for stations first to save data.';

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
  String get noPriceAlerts => 'No price alerts';

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
  String get searchAlongRouteLabel => 'Along route';

  @override
  String get searchEvStations => 'Search to find EV charging stations';

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
  String stopN(int n) {
    return 'Stop $n';
  }

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
  String get requiredForEvSearch => 'Required for EV charging station search';

  @override
  String get edit => 'Edit';

  @override
  String get fuelPricesApiKey => 'Fuel prices API Key';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API Key';

  @override
  String get evChargingApiKey => 'EV Charging API Key';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API Key';

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
  String get showFuelStations => 'Show fuel stations';

  @override
  String get showFuelStationsDesc => 'Include gas, diesel, LPG, CNG stations';

  @override
  String get showEvStations => 'Show EV charging stations';

  @override
  String get showEvStationsDesc =>
      'Include electric charging stations in search results';

  @override
  String get noStationsAlongThisRoute => 'No stations found along this route.';

  @override
  String get fuelCostCalculator => 'Fuel Cost Calculator';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get consumptionL100km => 'Consumption (L/100km)';

  @override
  String get fuelPriceEurL => 'Fuel price (EUR/L)';

  @override
  String get tripCost => 'Trip Cost';

  @override
  String get fuelNeeded => 'Fuel needed';

  @override
  String get totalCost => 'Total cost';

  @override
  String get enterCalcValues =>
      'Enter distance, consumption, and price to calculate trip cost';

  @override
  String get priceHistory => 'Price History';

  @override
  String get noPriceHistory => 'No price history yet';

  @override
  String get noHourlyData => 'No hourly data';

  @override
  String get noStatistics => 'No statistics available';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Avg';

  @override
  String get showAllFuelTypes => 'Show all fuel types';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get connectTankSync => 'Connect TankSync';

  @override
  String get disconnectTankSync => 'Disconnect TankSync';

  @override
  String get viewMyData => 'View my data';

  @override
  String get optionalCloudSync =>
      'Optional cloud sync for alerts, favorites, and push notifications';

  @override
  String get tapToUpdateGps => 'Tap to update GPS position';

  @override
  String get gpsAutoUpdateHint =>
      'GPS position is acquired automatically when you search. You can also update it manually here.';

  @override
  String get clearGpsConfirm =>
      'Clear the stored GPS position? You can update it again at any time.';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get deleteAllServerData => 'Delete all server data';

  @override
  String get deleteServerDataConfirm => 'Delete all server data?';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get allDataDeleted => 'All server data deleted';

  @override
  String get disconnectConfirm => 'Disconnect TankSync?';

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
  String get upgradeToEmail => 'Create email account';

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
  String crossBorderNearby(String country) {
    return '$country is nearby';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km to border';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Avg here: $price EUR ($count stations)';
  }

  @override
  String get allPricesView => 'All prices';

  @override
  String get compactView => 'Compact';

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
      'Sync favorites and alerts across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.';

  @override
  String get gdprCloudSyncShort => 'Sync favorites and alerts across devices';

  @override
  String get gdprLegalBasis =>
      'Legal basis: Art. 6(1)(a) GDPR (Consent). You can withdraw consent anytime in Settings.';

  @override
  String get gdprAcceptAll => 'Accept All';

  @override
  String get gdprAcceptSelected => 'Accept Selected';

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
  String get topicUrlCopied => 'Topic URL copied';

  @override
  String get testNotificationSent => 'Test notification sent!';

  @override
  String get testNotificationFailed => 'Failed to send test notification';

  @override
  String get pushUpdateFailed => 'Failed to update push notification setting';

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
  String get privacyDashboardTitle => 'Privacy Dashboard';

  @override
  String get privacyDashboardSubtitle => 'View, export, or delete your data';

  @override
  String get privacyDashboardBanner =>
      'Your data belongs to you. Here you can see everything this app stores, export it, or delete it.';

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
  String get privacyCacheEntries => 'Cache entries';

  @override
  String get privacyApiKey => 'API key stored';

  @override
  String get privacyEvApiKey => 'EV API key stored';

  @override
  String get privacyEstimatedSize => 'Estimated storage';

  @override
  String get privacySyncedData => 'Cloud sync (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Cloud sync is disabled. All data stays on this device only.';

  @override
  String get privacySyncMode => 'Sync mode';

  @override
  String get privacySyncUserId => 'User ID';

  @override
  String get privacySyncDescription =>
      'When sync is enabled, favorites, alerts, ignored stations, and ratings are also stored on the TankSync server.';

  @override
  String get privacyViewServerData => 'View server data';

  @override
  String get privacyExportButton => 'Export all data as JSON';

  @override
  String get privacyExportSuccess => 'Data exported to clipboard';

  @override
  String get privacyDeleteButton => 'Delete all data';

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
}
