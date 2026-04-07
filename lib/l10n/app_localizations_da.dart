// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Brændstofpriser';

  @override
  String get search => 'Søg';

  @override
  String get favorites => 'Favoritter';

  @override
  String get map => 'Kort';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Indstillinger';

  @override
  String get gpsLocation => 'GPS-position';

  @override
  String get zipCode => 'Postnummer';

  @override
  String get zipCodeHint => 'f.eks. 1000';

  @override
  String get fuelType => 'Brændstof';

  @override
  String get searchRadius => 'Radius';

  @override
  String get searchNearby => 'Tankstationer i nærheden';

  @override
  String get searchButton => 'Søg';

  @override
  String get noResults => 'Ingen tankstationer fundet.';

  @override
  String get startSearch => 'Søg for at finde tankstationer.';

  @override
  String get open => 'Åben';

  @override
  String get closed => 'Lukket';

  @override
  String distance(String distance) {
    return '$distance væk';
  }

  @override
  String get price => 'Pris';

  @override
  String get prices => 'Priser';

  @override
  String get address => 'Adresse';

  @override
  String get openingHours => 'Åbningstider';

  @override
  String get open24h => 'Åben 24 timer';

  @override
  String get navigate => 'Navigér';

  @override
  String get retry => 'Prøv igen';

  @override
  String get apiKeySetup => 'API-nøgle';

  @override
  String get apiKeyDescription =>
      'Registrer dig én gang for at få en gratis API-nøgle.';

  @override
  String get apiKeyLabel => 'API-nøgle';

  @override
  String get register => 'Registrering';

  @override
  String get continueButton => 'Fortsæt';

  @override
  String get welcome => 'Brændstofpriser';

  @override
  String get welcomeSubtitle => 'Find den billigste brændstof i nærheden.';

  @override
  String get profileName => 'Profilnavn';

  @override
  String get preferredFuel => 'Foretrukket brændstof';

  @override
  String get defaultRadius => 'Standard radius';

  @override
  String get landingScreen => 'Startskærm';

  @override
  String get homeZip => 'Hjemmepostnummer';

  @override
  String get newProfile => 'Ny profil';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get save => 'Gem';

  @override
  String get cancel => 'Annuller';

  @override
  String get delete => 'Slet';

  @override
  String get activate => 'Aktivér';

  @override
  String get configured => 'Konfigureret';

  @override
  String get notConfigured => 'Ikke konfigureret';

  @override
  String get about => 'Om';

  @override
  String get openSource => 'Open Source (MIT Licens)';

  @override
  String get sourceCode => 'Kildekode på GitHub';

  @override
  String get noFavorites => 'Ingen favoritter endnu';

  @override
  String get noFavoritesHint =>
      'Tryk på stjernen ved en tankstation for at gemme den som favorit.';

  @override
  String get language => 'Sprog';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demotilstand — eksempeldata vises.';

  @override
  String get setupLiveData => 'Opsæt til live data';

  @override
  String get freeNoKey => 'Gratis — ingen nøgle nødvendig';

  @override
  String get apiKeyRequired => 'API-nøgle påkrævet';

  @override
  String get skipWithoutKey => 'Fortsæt uden nøgle';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get storageAndCache => 'Lagring og cache';

  @override
  String get clearCache => 'Ryd cache';

  @override
  String get clearAllData => 'Slet alle data';

  @override
  String get errorLog => 'Fejllog';

  @override
  String stationsFound(int count) {
    return '$count tankstationer fundet';
  }

  @override
  String get whatIsShared => 'Hvad deles — og med hvem?';

  @override
  String get gpsCoordinates => 'GPS-koordinater';

  @override
  String get gpsReason =>
      'Sendes med hver søgning for at finde nærliggende stationer.';

  @override
  String get postalCodeData => 'Postnummer';

  @override
  String get postalReason =>
      'Konverteres til koordinater via geokodningstjenesten.';

  @override
  String get mapViewport => 'Kortudsnit';

  @override
  String get mapReason =>
      'Kortfliser indlæses fra serveren. Ingen personlige data overføres.';

  @override
  String get apiKeyData => 'API-nøgle';

  @override
  String get apiKeyReason =>
      'Din personlige nøgle sendes med hver API-anmodning. Den er knyttet til din e-mail.';

  @override
  String get notShared => 'Deles IKKE:';

  @override
  String get searchHistory => 'Søgehistorik';

  @override
  String get favoritesData => 'Favoritter';

  @override
  String get profileNames => 'Profilnavne';

  @override
  String get homeZipData => 'Hjemmepostnummer';

  @override
  String get usageData => 'Brugsdata';

  @override
  String get privacyBanner =>
      'Denne app har ingen server. Alle data forbliver på din enhed. Ingen analyse, ingen sporing, ingen reklamer.';

  @override
  String get storageUsage => 'Lagringsforbrug på denne enhed';

  @override
  String get settingsLabel => 'Indstillinger';

  @override
  String get profilesStored => 'profiler gemt';

  @override
  String get stationsMarked => 'stationer markeret';

  @override
  String get cachedResponses => 'cachelagrede svar';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Cacheadministration';

  @override
  String get cacheDescription =>
      'Cachen gemmer API-svar for hurtigere indlæsning og offline adgang.';

  @override
  String get stationSearch => 'Stationssøgning';

  @override
  String get stationDetails => 'Stationsdetaljer';

  @override
  String get priceQuery => 'Prisforespørgsel';

  @override
  String get zipGeocoding => 'Postnummer-geokodning';

  @override
  String minutes(int n) {
    return '$n minutter';
  }

  @override
  String hours(int n) {
    return '$n timer';
  }

  @override
  String get clearCacheTitle => 'Ryd cache?';

  @override
  String get clearCacheBody =>
      'Cachelagrede søgeresultater og priser slettes. Profiler, favoritter og indstillinger bevares.';

  @override
  String get clearCacheButton => 'Ryd cache';

  @override
  String get deleteAllTitle => 'Slet alle data?';

  @override
  String get deleteAllBody =>
      'Dette sletter permanent alle profiler, favoritter, API-nøgle, indstillinger og cache. Appen nulstilles.';

  @override
  String get deleteAllButton => 'Slet alt';

  @override
  String get entries => 'poster';

  @override
  String get cacheEmpty => 'Cachen er tom';

  @override
  String get noStorage => 'Ingen lagring brugt';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data fra statslige pristransparensorganer.';

  @override
  String get supportProject => 'Støt dette projekt';

  @override
  String get supportDescription =>
      'Denne app er gratis, open source og uden reklamer. Hvis du finder den nyttig, overvej at støtte udvikleren.';

  @override
  String get reportBug => 'Rapportér fejl / Foreslå funktion';

  @override
  String get privacyPolicy => 'Privatlivspolitik';

  @override
  String get fuels => 'Brændstoffer';

  @override
  String get services => 'Tjenester';

  @override
  String get zone => 'Zone';

  @override
  String get highway => 'Motorvej';

  @override
  String get localStation => 'Lokal station';

  @override
  String get lastUpdate => 'Seneste opdatering';

  @override
  String get automate24h => '24t/24 — Automat';

  @override
  String get refreshPrices => 'Opdater priser';

  @override
  String get station => 'Tankstation';

  @override
  String get locationDenied =>
      'Placeringstilladelse nægtet. Du kan søge efter postnummer.';

  @override
  String get demoModeBanner =>
      'Demo-tilstand. Konfigurer API-nøgle i indstillinger.';

  @override
  String get sortDistance => 'Afstand';

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
      'Indlæser favoritter...\nSøg først efter stationer for at gemme data.';

  @override
  String get reportPrice => 'Rapportér pris';

  @override
  String get whatsWrong => 'Hvad er galt?';

  @override
  String get correctPrice => 'Korrekt pris (f.eks. 15,79)';

  @override
  String get sendReport => 'Send rapport';

  @override
  String get reportSent => 'Rapport sendt. Tak!';

  @override
  String get enterValidPrice => 'Indtast venligst en gyldig pris';

  @override
  String get cacheCleared => 'Cache ryddet.';

  @override
  String get yourPosition => 'Din position';

  @override
  String get positionUnknown => 'Position ukendt';

  @override
  String get distancesFromCenter => 'Afstande fra søgecentrum';

  @override
  String get autoUpdatePosition => 'Opdater position automatisk';

  @override
  String get autoUpdateDescription => 'Opdater GPS-position før hver søgning';

  @override
  String get location => 'Placering';

  @override
  String get switchProfileTitle => 'Land ændret';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Du er nu i $country. Skift til profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Skiftet til profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ingen profil for dette land';

  @override
  String noProfileForCountry(String country) {
    return 'Du er i $country, men ingen profil er konfigureret. Opret en i Indstillinger.';
  }

  @override
  String get autoSwitchProfile => 'Automatisk profilskift';

  @override
  String get autoSwitchDescription =>
      'Skift profil automatisk ved grænseoverskridelse';

  @override
  String get switchProfile => 'Skift';

  @override
  String get dismiss => 'Luk';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Sprog';

  @override
  String get settingsStorageDetail => 'API-nøgle, aktiv profil';

  @override
  String get allFuels => 'Alle';

  @override
  String get priceAlerts => 'Prisalarmer';

  @override
  String get noPriceAlerts => 'Ingen prisalarmer';

  @override
  String get noPriceAlertsHint => 'Opret en alarm fra en stations detaljeside.';

  @override
  String alertDeleted(String name) {
    return 'Alarm \"$name\" slettet';
  }

  @override
  String get createAlert => 'Opret prisalarm';

  @override
  String currentPrice(String price) {
    return 'Aktuel pris: $price';
  }

  @override
  String get targetPrice => 'Målpris (EUR)';

  @override
  String get enterPrice => 'Indtast en pris';

  @override
  String get invalidPrice => 'Ugyldig pris';

  @override
  String get priceTooHigh => 'Pris for høj';

  @override
  String get create => 'Opret';

  @override
  String get alertCreated => 'Prisalarm oprettet';

  @override
  String get wrongE5Price => 'Forkert Super E5 pris';

  @override
  String get wrongE10Price => 'Forkert Super E10 pris';

  @override
  String get wrongDieselPrice => 'Forkert Diesel pris';

  @override
  String get wrongStatusOpen => 'Vist som åben, men lukket';

  @override
  String get wrongStatusClosed => 'Vist som lukket, men åben';

  @override
  String get searchAlongRouteLabel => 'Langs ruten';

  @override
  String get searchEvStations => 'Søg ladestationer';

  @override
  String get allStations => 'Alle stationer';

  @override
  String get bestStops => 'Bedste stop';

  @override
  String get openInMaps => 'Åbn i Kort';

  @override
  String get noStationsAlongRoute => 'Ingen stationer fundet langs ruten';

  @override
  String get evOperational => 'I drift';

  @override
  String get evStatusUnknown => 'Status ukendt';

  @override
  String evConnectors(int count) {
    return 'Stik ($count punkter)';
  }

  @override
  String get evNoConnectors => 'Ingen stikdetaljer tilgængelige';

  @override
  String get evUsageCost => 'Brugsomkostninger';

  @override
  String get evPricingUnavailable => 'Pris ikke tilgængelig fra udbyderen';

  @override
  String get evLastUpdated => 'Sidst opdateret';

  @override
  String get evUnknown => 'Ukendt';

  @override
  String get evDataAttribution => 'Data fra OpenChargeMap (community-kilde)';

  @override
  String get evStatusDisclaimer =>
      'Status afspejler muligvis ikke tilgængeligheden i realtid. Tryk på opdater for at hente de seneste data.';

  @override
  String get evNavigateToStation => 'Navigér til station';

  @override
  String get evRefreshStatus => 'Opdater status';

  @override
  String get evStatusUpdated => 'Status opdateret';

  @override
  String get evStationNotFound =>
      'Kunne ikke opdatere — station ikke fundet i nærheden';

  @override
  String get addedToFavorites => 'Tilføjet til favoritter';

  @override
  String get removedFromFavorites => 'Fjernet fra favoritter';

  @override
  String get addFavorite => 'Tilføj til favoritter';

  @override
  String get removeFavorite => 'Fjern fra favoritter';

  @override
  String get currentLocation => 'Aktuel placering';

  @override
  String get gpsError => 'GPS-fejl';

  @override
  String get couldNotResolve => 'Kunne ikke bestemme start eller destination';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get cityAddressOrGps => 'By, adresse eller GPS';

  @override
  String get cityOrAddress => 'By eller adresse';

  @override
  String get useGps => 'Brug GPS';

  @override
  String get stop => 'Stop';

  @override
  String stopN(int n) {
    return 'Stop $n';
  }

  @override
  String get addStop => 'Tilføj stop';

  @override
  String get searchAlongRoute => 'Søg langs ruten';

  @override
  String get cheapest => 'Billigste';

  @override
  String nStations(int count) {
    return '$count stationer';
  }

  @override
  String nBest(int count) {
    return '$count bedste';
  }

  @override
  String get fuelPricesTankerkoenig => 'Brændstofpriser (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Påkrævet til brændstofprissøgning i Tyskland';

  @override
  String get evChargingOpenChargeMap => 'EV-opladning (OpenChargeMap)';

  @override
  String get customKey => 'Brugerdefineret nøgle';

  @override
  String get appDefaultKey => 'App-standardnøgle';

  @override
  String get optionalOverrideKey =>
      'Valgfrit: erstat den indbyggede app-nøgle med din egen';

  @override
  String get requiredForEvSearch =>
      'Påkrævet til søgning efter EV-ladestationer';

  @override
  String get edit => 'Rediger';

  @override
  String get fuelPricesApiKey => 'Brændstofpriser API-nøgle';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-nøgle';

  @override
  String get evChargingApiKey => 'EV-opladning API-nøgle';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-nøgle';

  @override
  String get routeSegment => 'Rutesegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Vis billigste station for hver $km km langs ruten';
  }

  @override
  String get avoidHighways => 'Undgå motorveje';

  @override
  String get avoidHighwaysDesc =>
      'Ruteberegning undgår betalingsveje og motorveje';

  @override
  String get showFuelStations => 'Vis tankstationer';

  @override
  String get showFuelStationsDesc =>
      'Inkluder benzin-, diesel-, LPG-, CNG-stationer';

  @override
  String get showEvStations => 'Vis ladestationer';

  @override
  String get showEvStationsDesc =>
      'Inkluder elektriske ladestationer i søgeresultater';

  @override
  String get noStationsAlongThisRoute =>
      'Ingen stationer fundet langs denne rute.';

  @override
  String get fuelCostCalculator => 'Brændstofomkostningsberegner';

  @override
  String get distanceKm => 'Afstand (km)';

  @override
  String get consumptionL100km => 'Forbrug (L/100km)';

  @override
  String get fuelPriceEurL => 'Brændstofpris (EUR/L)';

  @override
  String get tripCost => 'Turomkostning';

  @override
  String get fuelNeeded => 'Nødvendigt brændstof';

  @override
  String get totalCost => 'Samlede omkostninger';

  @override
  String get enterCalcValues =>
      'Indtast afstand, forbrug og pris for at beregne turomkostningen';

  @override
  String get priceHistory => 'Prishistorik';

  @override
  String get noPriceHistory => 'Ingen prishistorik endnu';

  @override
  String get noHourlyData => 'Ingen timedata';

  @override
  String get noStatistics => 'Ingen statistikker tilgængelige';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Gns';

  @override
  String get showAllFuelTypes => 'Vis alle brændstoftyper';

  @override
  String get connected => 'Forbundet';

  @override
  String get notConnected => 'Ikke forbundet';

  @override
  String get connectTankSync => 'Forbind TankSync';

  @override
  String get disconnectTankSync => 'Afbryd TankSync';

  @override
  String get viewMyData => 'Se mine data';

  @override
  String get optionalCloudSync =>
      'Valgfri cloudsynkronisering for alarmer, favoritter og push-notifikationer';

  @override
  String get tapToUpdateGps => 'Tryk for at opdatere GPS-position';

  @override
  String get gpsAutoUpdateHint =>
      'GPS-positionen hentes automatisk ved søgning. Du kan også opdatere den manuelt her.';

  @override
  String get clearGpsConfirm =>
      'Ryd den gemte GPS-position? Du kan opdatere den igen når som helst.';

  @override
  String get pageNotFound => 'Side ikke fundet';

  @override
  String get deleteAllServerData => 'Slet alle serverdata';

  @override
  String get deleteServerDataConfirm => 'Slet alle serverdata?';

  @override
  String get deleteEverything => 'Slet alt';

  @override
  String get allDataDeleted => 'Alle serverdata slettet';

  @override
  String get disconnectConfirm => 'Afbryd TankSync?';

  @override
  String get disconnect => 'Afbryd';

  @override
  String get myServerData => 'Mine serverdata';

  @override
  String get anonymousUuid => 'Anonym UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synkroniserede data';

  @override
  String get pushTokens => 'Push-tokens';

  @override
  String get priceReports => 'Prisrapporter';

  @override
  String get totalItems => 'Antal elementer';

  @override
  String get estimatedSize => 'Estimeret størrelse';

  @override
  String get viewRawJson => 'Se rådata som JSON';

  @override
  String get exportJson => 'Eksportér som JSON (udklipsholder)';

  @override
  String get jsonCopied => 'JSON kopieret til udklipsholder';

  @override
  String get rawDataJson => 'Rådata (JSON)';

  @override
  String get close => 'Luk';

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
}
