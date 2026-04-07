// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Bränslepriser';

  @override
  String get search => 'Sök';

  @override
  String get favorites => 'Favoriter';

  @override
  String get map => 'Karta';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Inställningar';

  @override
  String get gpsLocation => 'GPS-position';

  @override
  String get zipCode => 'Postnummer';

  @override
  String get zipCodeHint => 't.ex. 111 22';

  @override
  String get fuelType => 'Bränsle';

  @override
  String get searchRadius => 'Radie';

  @override
  String get searchNearby => 'Bensinstationer i närheten';

  @override
  String get searchButton => 'Sök';

  @override
  String get noResults => 'Inga bensinstationer hittades.';

  @override
  String get startSearch => 'Sök för att hitta bensinstationer.';

  @override
  String get open => 'Öppen';

  @override
  String get closed => 'Stängd';

  @override
  String distance(String distance) {
    return '$distance bort';
  }

  @override
  String get price => 'Pris';

  @override
  String get prices => 'Priser';

  @override
  String get address => 'Adress';

  @override
  String get openingHours => 'Öppettider';

  @override
  String get open24h => 'Öppet 24 timmar';

  @override
  String get navigate => 'Navigera';

  @override
  String get retry => 'Försök igen';

  @override
  String get apiKeySetup => 'API-nyckel';

  @override
  String get apiKeyDescription =>
      'Registrera dig en gång för att få en gratis API-nyckel.';

  @override
  String get apiKeyLabel => 'API-nyckel';

  @override
  String get register => 'Registrering';

  @override
  String get continueButton => 'Fortsätt';

  @override
  String get welcome => 'Bränslepriser';

  @override
  String get welcomeSubtitle => 'Hitta det billigaste bränslet nära dig.';

  @override
  String get profileName => 'Profilnamn';

  @override
  String get preferredFuel => 'Föredraget bränsle';

  @override
  String get defaultRadius => 'Standardradie';

  @override
  String get landingScreen => 'Startskärm';

  @override
  String get homeZip => 'Hempostnummer';

  @override
  String get newProfile => 'Ny profil';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get save => 'Spara';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Ta bort';

  @override
  String get activate => 'Aktivera';

  @override
  String get configured => 'Konfigurerad';

  @override
  String get notConfigured => 'Ej konfigurerad';

  @override
  String get about => 'Om';

  @override
  String get openSource => 'Öppen källkod (MIT-licens)';

  @override
  String get sourceCode => 'Källkod på GitHub';

  @override
  String get noFavorites => 'Inga favoriter ännu';

  @override
  String get noFavoritesHint =>
      'Tryck på stjärnan vid en bensinstation för att spara den som favorit.';

  @override
  String get language => 'Språk';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demoläge — exempeldata visas.';

  @override
  String get setupLiveData => 'Konfigurera för live-data';

  @override
  String get freeNoKey => 'Gratis — ingen nyckel behövs';

  @override
  String get apiKeyRequired => 'API-nyckel krävs';

  @override
  String get skipWithoutKey => 'Fortsätt utan nyckel';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get storageAndCache => 'Lagring och cache';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String get clearAllData => 'Ta bort all data';

  @override
  String get errorLog => 'Fellogg';

  @override
  String stationsFound(int count) {
    return '$count bensinstationer hittades';
  }

  @override
  String get whatIsShared => 'Vad delas — och med vem?';

  @override
  String get gpsCoordinates => 'GPS-koordinater';

  @override
  String get gpsReason =>
      'Skickas med varje sökning för att hitta närliggande stationer.';

  @override
  String get postalCodeData => 'Postnummer';

  @override
  String get postalReason =>
      'Konverteras till koordinater via geokodarens tjänst.';

  @override
  String get mapViewport => 'Kartvy';

  @override
  String get mapReason =>
      'Kartplattor laddas från servern. Inga personuppgifter överförs.';

  @override
  String get apiKeyData => 'API-nyckel';

  @override
  String get apiKeyReason =>
      'Din personliga nyckel skickas med varje API-förfrågan. Den är kopplad till din e-post.';

  @override
  String get notShared => 'Delas INTE:';

  @override
  String get searchHistory => 'Sökhistorik';

  @override
  String get favoritesData => 'Favoriter';

  @override
  String get profileNames => 'Profilnamn';

  @override
  String get homeZipData => 'Hempostnummer';

  @override
  String get usageData => 'Användningsdata';

  @override
  String get privacyBanner =>
      'Denna app har ingen server. All data stannar på din enhet. Ingen analys, ingen spårning, ingen reklam.';

  @override
  String get storageUsage => 'Lagringsanvändning på denna enhet';

  @override
  String get settingsLabel => 'Inställningar';

  @override
  String get profilesStored => 'profiler sparade';

  @override
  String get stationsMarked => 'stationer markerade';

  @override
  String get cachedResponses => 'cachade svar';

  @override
  String get total => 'Totalt';

  @override
  String get cacheManagement => 'Cachehantering';

  @override
  String get cacheDescription =>
      'Cachen lagrar API-svar för snabbare laddning och offlineåtkomst.';

  @override
  String get stationSearch => 'Stationssökning';

  @override
  String get stationDetails => 'Stationsdetaljer';

  @override
  String get priceQuery => 'Prisförfrågan';

  @override
  String get zipGeocoding => 'Postnummergeokning';

  @override
  String minutes(int n) {
    return '$n minuter';
  }

  @override
  String hours(int n) {
    return '$n timmar';
  }

  @override
  String get clearCacheTitle => 'Rensa cache?';

  @override
  String get clearCacheBody =>
      'Cachade sökresultat och priser raderas. Profiler, favoriter och inställningar bevaras.';

  @override
  String get clearCacheButton => 'Rensa cache';

  @override
  String get deleteAllTitle => 'Ta bort all data?';

  @override
  String get deleteAllBody =>
      'Detta raderar permanent alla profiler, favoriter, API-nyckel, inställningar och cache. Appen återställs.';

  @override
  String get deleteAllButton => 'Ta bort allt';

  @override
  String get entries => 'poster';

  @override
  String get cacheEmpty => 'Cachen är tom';

  @override
  String get noStorage => 'Ingen lagring använd';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data från statliga pristransparensorgan.';

  @override
  String get apiKeyFormatError =>
      'Ogiltigt format — UUID förväntat (8-4-4-4-12)';

  @override
  String get supportProject => 'Stöd detta projekt';

  @override
  String get supportDescription =>
      'Denna app är gratis, öppen källkod och utan reklam. Om du tycker den är användbar, överväg att stödja utvecklaren.';

  @override
  String get reportBug => 'Rapportera fel / Föreslå funktion';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get fuels => 'Bränslen';

  @override
  String get services => 'Tjänster';

  @override
  String get zone => 'Zon';

  @override
  String get highway => 'Motorväg';

  @override
  String get localStation => 'Lokal station';

  @override
  String get lastUpdate => 'Senaste uppdatering';

  @override
  String get automate24h => '24t/24 — Automat';

  @override
  String get refreshPrices => 'Uppdatera priser';

  @override
  String get station => 'Bensinstation';

  @override
  String get locationDenied =>
      'Platstillstånd nekades. Du kan söka med postnummer.';

  @override
  String get demoModeBanner =>
      'Demoläge. Konfigurera API-nyckel i inställningar.';

  @override
  String get sortDistance => 'Avstånd';

  @override
  String get cheap => 'billig';

  @override
  String get expensive => 'dyr';

  @override
  String stationsOnMap(int count) {
    return '$count stationer';
  }

  @override
  String get loadingFavorites =>
      'Laddar favoriter...\nSök efter stationer först för att spara data.';

  @override
  String get reportPrice => 'Rapportera pris';

  @override
  String get whatsWrong => 'Vad är fel?';

  @override
  String get correctPrice => 'Korrekt pris (t.ex. 15,79)';

  @override
  String get sendReport => 'Skicka rapport';

  @override
  String get reportSent => 'Rapport skickad. Tack!';

  @override
  String get enterValidPrice => 'Ange ett giltigt pris';

  @override
  String get cacheCleared => 'Cache rensad.';

  @override
  String get yourPosition => 'Din position';

  @override
  String get positionUnknown => 'Position okänd';

  @override
  String get distancesFromCenter => 'Avstånd från sökcentrum';

  @override
  String get autoUpdatePosition => 'Uppdatera position automatiskt';

  @override
  String get autoUpdateDescription =>
      'Uppdatera GPS-position före varje sökning';

  @override
  String get location => 'Plats';

  @override
  String get switchProfileTitle => 'Land ändrat';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Du är nu i $country. Byta till profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Bytt till profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ingen profil för detta land';

  @override
  String noProfileForCountry(String country) {
    return 'Du är i $country, men ingen profil är konfigurerad. Skapa en i Inställningar.';
  }

  @override
  String get autoSwitchProfile => 'Automatiskt profilbyte';

  @override
  String get autoSwitchDescription =>
      'Byt profil automatiskt vid gränsöverskridande';

  @override
  String get switchProfile => 'Byt';

  @override
  String get dismiss => 'Stäng';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Språk';

  @override
  String get settingsStorageDetail => 'API-nyckel, aktiv profil';

  @override
  String get allFuels => 'Alla';

  @override
  String get priceAlerts => 'Prisvarningar';

  @override
  String get noPriceAlerts => 'Inga prisvarningar';

  @override
  String get noPriceAlertsHint =>
      'Skapa en varning från en stations detaljsida.';

  @override
  String alertDeleted(String name) {
    return 'Varning \"$name\" borttagen';
  }

  @override
  String get createAlert => 'Skapa prisvarning';

  @override
  String currentPrice(String price) {
    return 'Aktuellt pris: $price';
  }

  @override
  String get targetPrice => 'Målpris (EUR)';

  @override
  String get enterPrice => 'Ange ett pris';

  @override
  String get invalidPrice => 'Ogiltigt pris';

  @override
  String get priceTooHigh => 'Priset för högt';

  @override
  String get create => 'Skapa';

  @override
  String get alertCreated => 'Prisvarning skapad';

  @override
  String get wrongE5Price => 'Fel Super E5 pris';

  @override
  String get wrongE10Price => 'Fel Super E10 pris';

  @override
  String get wrongDieselPrice => 'Fel Diesel pris';

  @override
  String get wrongStatusOpen => 'Visas öppen, men stängd';

  @override
  String get wrongStatusClosed => 'Visas stängd, men öppen';

  @override
  String get searchAlongRouteLabel => 'Längs rutten';

  @override
  String get searchEvStations => 'Sök laddstationer';

  @override
  String get allStations => 'Alla stationer';

  @override
  String get bestStops => 'Bästa stopp';

  @override
  String get openInMaps => 'Öppna i Kartor';

  @override
  String get noStationsAlongRoute => 'Inga stationer hittades längs rutten';

  @override
  String get evOperational => 'I drift';

  @override
  String get evStatusUnknown => 'Status okänd';

  @override
  String evConnectors(int count) {
    return 'Kontakter ($count punkter)';
  }

  @override
  String get evNoConnectors => 'Inga kontaktdetaljer tillgängliga';

  @override
  String get evUsageCost => 'Användningskostnad';

  @override
  String get evPricingUnavailable =>
      'Prissättning inte tillgänglig från leverantören';

  @override
  String get evLastUpdated => 'Senast uppdaterad';

  @override
  String get evUnknown => 'Okänd';

  @override
  String get evDataAttribution => 'Data från OpenChargeMap (community-källa)';

  @override
  String get evStatusDisclaimer =>
      'Status kanske inte återspeglar tillgänglighet i realtid. Tryck på uppdatera för att hämta senaste data.';

  @override
  String get evNavigateToStation => 'Navigera till station';

  @override
  String get evRefreshStatus => 'Uppdatera status';

  @override
  String get evStatusUpdated => 'Status uppdaterad';

  @override
  String get evStationNotFound =>
      'Kunde inte uppdatera — station hittades inte i närheten';

  @override
  String get addedToFavorites => 'Tillagd i favoriter';

  @override
  String get removedFromFavorites => 'Borttagen från favoriter';

  @override
  String get addFavorite => 'Lägg till i favoriter';

  @override
  String get removeFavorite => 'Ta bort från favoriter';

  @override
  String get currentLocation => 'Aktuell plats';

  @override
  String get gpsError => 'GPS-fel';

  @override
  String get couldNotResolve => 'Kunde inte avgöra start eller destination';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get cityAddressOrGps => 'Stad, adress eller GPS';

  @override
  String get cityOrAddress => 'Stad eller adress';

  @override
  String get useGps => 'Använd GPS';

  @override
  String get stop => 'Stopp';

  @override
  String stopN(int n) {
    return 'Stopp $n';
  }

  @override
  String get addStop => 'Lägg till stopp';

  @override
  String get searchAlongRoute => 'Sök längs rutten';

  @override
  String get cheapest => 'Billigast';

  @override
  String nStations(int count) {
    return '$count stationer';
  }

  @override
  String nBest(int count) {
    return '$count bästa';
  }

  @override
  String get fuelPricesTankerkoenig => 'Bränslepriser (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Krävs för bränsleprissökning i Tyskland';

  @override
  String get evChargingOpenChargeMap => 'EV-laddning (OpenChargeMap)';

  @override
  String get customKey => 'Egen nyckel';

  @override
  String get appDefaultKey => 'App-standardnyckel';

  @override
  String get optionalOverrideKey =>
      'Valfritt: ersätt den inbyggda appnyckeln med din egen';

  @override
  String get requiredForEvSearch => 'Krävs för sökning efter EV-laddstationer';

  @override
  String get edit => 'Redigera';

  @override
  String get fuelPricesApiKey => 'Bränslepriser API-nyckel';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-nyckel';

  @override
  String get evChargingApiKey => 'EV-laddning API-nyckel';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-nyckel';

  @override
  String get routeSegment => 'Ruttsegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Visa billigaste station var $km:e km längs rutten';
  }

  @override
  String get avoidHighways => 'Undvik motorvägar';

  @override
  String get avoidHighwaysDesc =>
      'Ruttberäkning undviker avgiftsvägar och motorvägar';

  @override
  String get showFuelStations => 'Visa bensinstationer';

  @override
  String get showFuelStationsDesc =>
      'Inkludera bensin-, diesel-, LPG-, CNG-stationer';

  @override
  String get showEvStations => 'Visa laddstationer';

  @override
  String get showEvStationsDesc =>
      'Inkludera elektriska laddstationer i sökresultat';

  @override
  String get noStationsAlongThisRoute =>
      'Inga stationer hittades längs denna rutt.';

  @override
  String get fuelCostCalculator => 'Bränslekostnadskalkylator';

  @override
  String get distanceKm => 'Avstånd (km)';

  @override
  String get consumptionL100km => 'Förbrukning (L/100km)';

  @override
  String get fuelPriceEurL => 'Bränslepris (EUR/L)';

  @override
  String get tripCost => 'Resekostnad';

  @override
  String get fuelNeeded => 'Bränsle som behövs';

  @override
  String get totalCost => 'Total kostnad';

  @override
  String get enterCalcValues =>
      'Ange avstånd, förbrukning och pris för att beräkna resekostnaden';

  @override
  String get priceHistory => 'Prishistorik';

  @override
  String get noPriceHistory => 'Ingen prishistorik ännu';

  @override
  String get noHourlyData => 'Inga timdata';

  @override
  String get noStatistics => 'Ingen statistik tillgänglig';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Medel';

  @override
  String get showAllFuelTypes => 'Visa alla bränsletyper';

  @override
  String get connected => 'Ansluten';

  @override
  String get notConnected => 'Inte ansluten';

  @override
  String get connectTankSync => 'Anslut TankSync';

  @override
  String get disconnectTankSync => 'Koppla från TankSync';

  @override
  String get viewMyData => 'Visa mina data';

  @override
  String get optionalCloudSync =>
      'Valfri molnsynkronisering för varningar, favoriter och push-notiser';

  @override
  String get tapToUpdateGps => 'Tryck för att uppdatera GPS-position';

  @override
  String get gpsAutoUpdateHint =>
      'GPS-positionen hämtas automatiskt vid sökning. Du kan också uppdatera den manuellt här.';

  @override
  String get clearGpsConfirm =>
      'Rensa den sparade GPS-positionen? Du kan uppdatera den igen när som helst.';

  @override
  String get pageNotFound => 'Sidan hittades inte';

  @override
  String get deleteAllServerData => 'Ta bort all serverdata';

  @override
  String get deleteServerDataConfirm => 'Ta bort all serverdata?';

  @override
  String get deleteEverything => 'Ta bort allt';

  @override
  String get allDataDeleted => 'All serverdata borttagen';

  @override
  String get disconnectConfirm => 'Koppla från TankSync?';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get myServerData => 'Min serverdata';

  @override
  String get anonymousUuid => 'Anonym UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synkroniserad data';

  @override
  String get pushTokens => 'Push-tokens';

  @override
  String get priceReports => 'Prisrapporter';

  @override
  String get totalItems => 'Totalt antal';

  @override
  String get estimatedSize => 'Uppskattad storlek';

  @override
  String get viewRawJson => 'Visa rådata som JSON';

  @override
  String get exportJson => 'Exportera som JSON (urklipp)';

  @override
  String get jsonCopied => 'JSON kopierad till urklipp';

  @override
  String get rawDataJson => 'Rådata (JSON)';

  @override
  String get close => 'Stäng';

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
}
