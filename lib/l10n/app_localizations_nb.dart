// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Drivstoffpriser';

  @override
  String get search => 'Søk';

  @override
  String get favorites => 'Favoritter';

  @override
  String get map => 'Kart';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Innstillinger';

  @override
  String get gpsLocation => 'GPS-posisjon';

  @override
  String get zipCode => 'Postnummer';

  @override
  String get zipCodeHint => 'f.eks. 0101';

  @override
  String get fuelType => 'Drivstoff';

  @override
  String get searchRadius => 'Radius';

  @override
  String get searchNearby => 'Bensinstasjoner i nærheten';

  @override
  String get searchButton => 'Søk';

  @override
  String get noResults => 'Ingen bensinstasjoner funnet.';

  @override
  String get startSearch => 'Søk for å finne bensinstasjoner.';

  @override
  String get open => 'Åpen';

  @override
  String get closed => 'Stengt';

  @override
  String distance(String distance) {
    return '$distance unna';
  }

  @override
  String get price => 'Pris';

  @override
  String get prices => 'Priser';

  @override
  String get address => 'Adresse';

  @override
  String get openingHours => 'Åpningstider';

  @override
  String get open24h => 'Åpent 24 timer';

  @override
  String get navigate => 'Naviger';

  @override
  String get retry => 'Prøv igjen';

  @override
  String get apiKeySetup => 'API-nøkkel';

  @override
  String get apiKeyDescription =>
      'Registrer deg én gang for å få en gratis API-nøkkel.';

  @override
  String get apiKeyLabel => 'API-nøkkel';

  @override
  String get register => 'Registrering';

  @override
  String get continueButton => 'Fortsett';

  @override
  String get welcome => 'Drivstoffpriser';

  @override
  String get welcomeSubtitle => 'Finn det billigste drivstoffet i nærheten.';

  @override
  String get profileName => 'Profilnavn';

  @override
  String get preferredFuel => 'Foretrukket drivstoff';

  @override
  String get defaultRadius => 'Standard radius';

  @override
  String get landingScreen => 'Startskjerm';

  @override
  String get homeZip => 'Hjemmepostnummer';

  @override
  String get newProfile => 'Ny profil';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get save => 'Lagre';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Slett';

  @override
  String get activate => 'Aktiver';

  @override
  String get configured => 'Konfigurert';

  @override
  String get notConfigured => 'Ikke konfigurert';

  @override
  String get about => 'Om';

  @override
  String get openSource => 'Åpen kildekode (MIT-lisens)';

  @override
  String get sourceCode => 'Kildekode på GitHub';

  @override
  String get noFavorites => 'Ingen favoritter ennå';

  @override
  String get noFavoritesHint =>
      'Trykk på stjernen ved en bensinstasjon for å lagre den som favoritt.';

  @override
  String get language => 'Språk';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demomodus — eksempeldata vises.';

  @override
  String get setupLiveData => 'Konfigurer for sanntidsdata';

  @override
  String get freeNoKey => 'Gratis — ingen nøkkel nødvendig';

  @override
  String get apiKeyRequired => 'API-nøkkel kreves';

  @override
  String get skipWithoutKey => 'Fortsett uten nøkkel';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get storageAndCache => 'Lagring og hurtigbuffer';

  @override
  String get clearCache => 'Tøm hurtigbuffer';

  @override
  String get clearAllData => 'Slett alle data';

  @override
  String get errorLog => 'Feillogg';

  @override
  String stationsFound(int count) {
    return '$count bensinstasjoner funnet';
  }

  @override
  String get whatIsShared => 'Hva deles — og med hvem?';

  @override
  String get gpsCoordinates => 'GPS-koordinater';

  @override
  String get gpsReason =>
      'Sendes med hvert søk for å finne nærliggende stasjoner.';

  @override
  String get postalCodeData => 'Postnummer';

  @override
  String get postalReason =>
      'Konverteres til koordinater via geokodingstjenesten.';

  @override
  String get mapViewport => 'Kartutsnitt';

  @override
  String get mapReason =>
      'Kartfliser lastes fra serveren. Ingen personlige data overføres.';

  @override
  String get apiKeyData => 'API-nøkkel';

  @override
  String get apiKeyReason =>
      'Din personlige nøkkel sendes med hver API-forespørsel. Den er knyttet til din e-post.';

  @override
  String get notShared => 'Deles IKKE:';

  @override
  String get searchHistory => 'Søkehistorikk';

  @override
  String get favoritesData => 'Favoritter';

  @override
  String get profileNames => 'Profilnavn';

  @override
  String get homeZipData => 'Hjemmepostnummer';

  @override
  String get usageData => 'Bruksdata';

  @override
  String get privacyBanner =>
      'Denne appen har ingen server. Alle data forblir på enheten din. Ingen analyse, sporing eller reklame.';

  @override
  String get storageUsage => 'Lagringsbruk på denne enheten';

  @override
  String get settingsLabel => 'Innstillinger';

  @override
  String get profilesStored => 'profiler lagret';

  @override
  String get stationsMarked => 'stasjoner merket';

  @override
  String get cachedResponses => 'hurtigbufrede svar';

  @override
  String get total => 'Totalt';

  @override
  String get cacheManagement => 'Hurtigbufferadministrasjon';

  @override
  String get cacheDescription =>
      'Hurtigbufferen lagrer API-svar for raskere lasting og frakoblet tilgang.';

  @override
  String get stationSearch => 'Stasjonssøk';

  @override
  String get stationDetails => 'Stasjonsdetaljer';

  @override
  String get priceQuery => 'Prisforespørsel';

  @override
  String get zipGeocoding => 'Postnummer-geokoding';

  @override
  String minutes(int n) {
    return '$n minutter';
  }

  @override
  String hours(int n) {
    return '$n timer';
  }

  @override
  String get clearCacheTitle => 'Tøm hurtigbuffer?';

  @override
  String get clearCacheBody =>
      'Hurtigbufrede søkeresultater og priser slettes. Profiler, favoritter og innstillinger beholdes.';

  @override
  String get clearCacheButton => 'Tøm hurtigbuffer';

  @override
  String get deleteAllTitle => 'Slette alle data?';

  @override
  String get deleteAllBody =>
      'Dette sletter permanent alle profiler, favoritter, API-nøkkel, innstillinger og hurtigbuffer. Appen tilbakestilles.';

  @override
  String get deleteAllButton => 'Slett alt';

  @override
  String get entries => 'oppføringer';

  @override
  String get cacheEmpty => 'Hurtigbufferen er tom';

  @override
  String get noStorage => 'Ingen lagring brukt';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data fra statlige pristransparensorganer.';

  @override
  String get apiKeyFormatError =>
      'Ugyldig format — forventet UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Støtt dette prosjektet';

  @override
  String get supportDescription =>
      'Denne appen er gratis, åpen kildekode og uten reklame. Hvis du finner den nyttig, vurder å støtte utvikleren.';

  @override
  String get reportBug => 'Rapporter feil / Foreslå funksjon';

  @override
  String get privacyPolicy => 'Personvernerklæring';

  @override
  String get fuels => 'Drivstoff';

  @override
  String get services => 'Tjenester';

  @override
  String get zone => 'Sone';

  @override
  String get highway => 'Motorvei';

  @override
  String get localStation => 'Lokal stasjon';

  @override
  String get lastUpdate => 'Siste oppdatering';

  @override
  String get automate24h => '24t/24 — Automat';

  @override
  String get refreshPrices => 'Oppdater priser';

  @override
  String get station => 'Bensinstasjon';

  @override
  String get locationDenied =>
      'Plasseringstillatelse nektet. Du kan søke etter postnummer.';

  @override
  String get demoModeBanner =>
      'Demomodus. Konfigurer API-nøkkel i innstillinger.';

  @override
  String get sortDistance => 'Avstand';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'billig';

  @override
  String get expensive => 'dyr';

  @override
  String stationsOnMap(int count) {
    return '$count stasjoner';
  }

  @override
  String get loadingFavorites =>
      'Laster favoritter...\nSøk etter stasjoner først for å lagre data.';

  @override
  String get reportPrice => 'Rapporter pris';

  @override
  String get whatsWrong => 'Hva er galt?';

  @override
  String get correctPrice => 'Korrekt pris (f.eks. 15,79)';

  @override
  String get sendReport => 'Send rapport';

  @override
  String get reportSent => 'Rapport sendt. Takk!';

  @override
  String get enterValidPrice => 'Vennligst oppgi en gyldig pris';

  @override
  String get cacheCleared => 'Hurtigbuffer tømt.';

  @override
  String get yourPosition => 'Din posisjon';

  @override
  String get positionUnknown => 'Posisjon ukjent';

  @override
  String get distancesFromCenter => 'Avstander fra søkesentrum';

  @override
  String get autoUpdatePosition => 'Oppdater posisjon automatisk';

  @override
  String get autoUpdateDescription => 'Oppdater GPS-posisjon før hvert søk';

  @override
  String get location => 'Plassering';

  @override
  String get switchProfileTitle => 'Land endret';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Du er nå i $country. Bytte til profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Byttet til profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ingen profil for dette landet';

  @override
  String noProfileForCountry(String country) {
    return 'Du er i $country, men ingen profil er konfigurert. Opprett en i Innstillinger.';
  }

  @override
  String get autoSwitchProfile => 'Automatisk profilbytte';

  @override
  String get autoSwitchDescription =>
      'Bytt profil automatisk ved grensepassering';

  @override
  String get switchProfile => 'Bytt';

  @override
  String get dismiss => 'Lukk';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Språk';

  @override
  String get settingsStorageDetail => 'API-nøkkel, aktiv profil';

  @override
  String get allFuels => 'Alle';

  @override
  String get priceAlerts => 'Prisalarmer';

  @override
  String get noPriceAlerts => 'Ingen prisalarmer';

  @override
  String get noPriceAlertsHint =>
      'Opprett en alarm fra en stasjons detaljside.';

  @override
  String alertDeleted(String name) {
    return 'Alarm \"$name\" slettet';
  }

  @override
  String get createAlert => 'Opprett prisalarm';

  @override
  String currentPrice(String price) {
    return 'Nåværende pris: $price';
  }

  @override
  String get targetPrice => 'Målpris (EUR)';

  @override
  String get enterPrice => 'Oppgi en pris';

  @override
  String get invalidPrice => 'Ugyldig pris';

  @override
  String get priceTooHigh => 'Prisen er for høy';

  @override
  String get create => 'Opprett';

  @override
  String get alertCreated => 'Prisalarm opprettet';

  @override
  String get wrongE5Price => 'Feil Super E5-pris';

  @override
  String get wrongE10Price => 'Feil Super E10-pris';

  @override
  String get wrongDieselPrice => 'Feil dieselpris';

  @override
  String get wrongStatusOpen => 'Vist som åpen, men stengt';

  @override
  String get wrongStatusClosed => 'Vist som stengt, men åpen';

  @override
  String get searchAlongRouteLabel => 'Langs ruten';

  @override
  String get searchEvStations => 'Søk ladestasjoner';

  @override
  String get allStations => 'Alle stasjoner';

  @override
  String get bestStops => 'Beste stopp';

  @override
  String get openInMaps => 'Åpne i Kart';

  @override
  String get noStationsAlongRoute => 'Ingen stasjoner funnet langs ruten';

  @override
  String get evOperational => 'I drift';

  @override
  String get evStatusUnknown => 'Status ukjent';

  @override
  String evConnectors(int count) {
    return 'Kontakter ($count punkter)';
  }

  @override
  String get evNoConnectors => 'Ingen kontaktdetaljer tilgjengelig';

  @override
  String get evUsageCost => 'Brukskostnad';

  @override
  String get evPricingUnavailable => 'Prising ikke tilgjengelig fra leverandør';

  @override
  String get evLastUpdated => 'Sist oppdatert';

  @override
  String get evUnknown => 'Ukjent';

  @override
  String get evDataAttribution => 'Data fra OpenChargeMap (felleskilde)';

  @override
  String get evStatusDisclaimer =>
      'Status gjenspeiler kanskje ikke tilgjengelighet i sanntid. Trykk oppdater for å hente siste data.';

  @override
  String get evNavigateToStation => 'Naviger til stasjon';

  @override
  String get evRefreshStatus => 'Oppdater status';

  @override
  String get evStatusUpdated => 'Status oppdatert';

  @override
  String get evStationNotFound =>
      'Kunne ikke oppdatere — stasjon ikke funnet i nærheten';

  @override
  String get addedToFavorites => 'Lagt til i favoritter';

  @override
  String get removedFromFavorites => 'Fjernet fra favoritter';

  @override
  String get addFavorite => 'Legg til i favoritter';

  @override
  String get removeFavorite => 'Fjern fra favoritter';

  @override
  String get currentLocation => 'Nåværende posisjon';

  @override
  String get gpsError => 'GPS-feil';

  @override
  String get couldNotResolve => 'Kunne ikke bestemme start eller destinasjon';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destinasjon';

  @override
  String get cityAddressOrGps => 'By, adresse eller GPS';

  @override
  String get cityOrAddress => 'By eller adresse';

  @override
  String get useGps => 'Bruk GPS';

  @override
  String get stop => 'Stopp';

  @override
  String stopN(int n) {
    return 'Stopp $n';
  }

  @override
  String get addStop => 'Legg til stopp';

  @override
  String get searchAlongRoute => 'Søk langs ruten';

  @override
  String get cheapest => 'Billigst';

  @override
  String nStations(int count) {
    return '$count stasjoner';
  }

  @override
  String nBest(int count) {
    return '$count beste';
  }

  @override
  String get fuelPricesTankerkoenig => 'Drivstoffpriser (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Påkrevd for drivstoffprissøk i Tyskland';

  @override
  String get evChargingOpenChargeMap => 'EV-lading (OpenChargeMap)';

  @override
  String get customKey => 'Egendefinert nøkkel';

  @override
  String get appDefaultKey => 'Standard app-nøkkel';

  @override
  String get optionalOverrideKey =>
      'Valgfritt: erstatt den innebygde app-nøkkelen med din egen';

  @override
  String get requiredForEvSearch => 'Påkrevd for søk etter EV-ladestasjoner';

  @override
  String get edit => 'Rediger';

  @override
  String get fuelPricesApiKey => 'Drivstoffpriser API-nøkkel';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-nøkkel';

  @override
  String get evChargingApiKey => 'EV-lading API-nøkkel';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-nøkkel';

  @override
  String get routeSegment => 'Rutesegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Vis billigste stasjon for hver $km km langs ruten';
  }

  @override
  String get avoidHighways => 'Unngå motorveier';

  @override
  String get avoidHighwaysDesc =>
      'Ruteberegning unngår bompenger og motorveier';

  @override
  String get showFuelStations => 'Vis bensinstasjoner';

  @override
  String get showFuelStationsDesc =>
      'Inkluder bensin-, diesel-, LPG-, CNG-stasjoner';

  @override
  String get showEvStations => 'Vis ladestasjoner';

  @override
  String get showEvStationsDesc =>
      'Inkluder elektriske ladestasjoner i søkeresultater';

  @override
  String get noStationsAlongThisRoute =>
      'Ingen stasjoner funnet langs denne ruten.';

  @override
  String get fuelCostCalculator => 'Drivstoffkostnadsberegner';

  @override
  String get distanceKm => 'Avstand (km)';

  @override
  String get consumptionL100km => 'Forbruk (L/100km)';

  @override
  String get fuelPriceEurL => 'Drivstoffpris (EUR/L)';

  @override
  String get tripCost => 'Turkostnad';

  @override
  String get fuelNeeded => 'Nødvendig drivstoff';

  @override
  String get totalCost => 'Totalkostnad';

  @override
  String get enterCalcValues =>
      'Oppgi avstand, forbruk og pris for å beregne turkostnaden';

  @override
  String get priceHistory => 'Prishistorikk';

  @override
  String get noPriceHistory => 'Ingen prishistorikk ennå';

  @override
  String get noHourlyData => 'Ingen timedata';

  @override
  String get noStatistics => 'Ingen statistikk tilgjengelig';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Snitt';

  @override
  String get showAllFuelTypes => 'Vis alle drivstofftyper';

  @override
  String get connected => 'Tilkoblet';

  @override
  String get notConnected => 'Ikke tilkoblet';

  @override
  String get connectTankSync => 'Koble til TankSync';

  @override
  String get disconnectTankSync => 'Koble fra TankSync';

  @override
  String get viewMyData => 'Se mine data';

  @override
  String get optionalCloudSync =>
      'Valgfri skysynkronisering for alarmer, favoritter og push-varsler';

  @override
  String get tapToUpdateGps => 'Trykk for å oppdatere GPS-posisjon';

  @override
  String get gpsAutoUpdateHint =>
      'GPS-posisjonen hentes automatisk ved søk. Du kan også oppdatere den manuelt her.';

  @override
  String get clearGpsConfirm =>
      'Tøm lagret GPS-posisjon? Du kan oppdatere den igjen når som helst.';

  @override
  String get pageNotFound => 'Siden ble ikke funnet';

  @override
  String get deleteAllServerData => 'Slett alle serverdata';

  @override
  String get deleteServerDataConfirm => 'Slette alle serverdata?';

  @override
  String get deleteEverything => 'Slett alt';

  @override
  String get allDataDeleted => 'Alle serverdata slettet';

  @override
  String get disconnectConfirm => 'Koble fra TankSync?';

  @override
  String get disconnect => 'Koble fra';

  @override
  String get myServerData => 'Mine serverdata';

  @override
  String get anonymousUuid => 'Anonym UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synkroniserte data';

  @override
  String get pushTokens => 'Push-tokener';

  @override
  String get priceReports => 'Prisrapporter';

  @override
  String get totalItems => 'Totalt antall';

  @override
  String get estimatedSize => 'Estimert størrelse';

  @override
  String get viewRawJson => 'Se rådata som JSON';

  @override
  String get exportJson => 'Eksporter som JSON (utklippstavle)';

  @override
  String get jsonCopied => 'JSON kopiert til utklippstavlen';

  @override
  String get rawDataJson => 'Rådata (JSON)';

  @override
  String get close => 'Lukk';

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
  String get alertStatsActive => 'Aktive';

  @override
  String get alertStatsToday => 'I dag';

  @override
  String get alertStatsThisWeek => 'Denne uken';

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
  String get privacyExportCsvButton => 'Export all data as CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV data exported to clipboard';

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
  String voiceAnnouncementThreshold(String price) {
    return 'Only below $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometers ahead, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Announcement radius';

  @override
  String get voiceAnnouncementCooldown => 'Repeat interval';

  @override
  String get nearestStations => 'Naermeste stasjoner';

  @override
  String get nearestStationsHint =>
      'Finn de naermeste stasjonene med din navaerende posisjon';

  @override
  String get consumptionLogTitle => 'Fuel consumption';

  @override
  String get consumptionLogMenuTitle => 'Consumption log';

  @override
  String get consumptionLogMenuSubtitle =>
      'Track fill-ups and calculate L/100km';

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
  String get stationPreFilled => 'Station pre-filled';

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
  String get carbonTabCharts => 'Charts';

  @override
  String get carbonTabAchievements => 'Achievements';

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
  String get milestonesTitle => 'Milestones';

  @override
  String get milestoneFirstFillUp => 'First fill-up logged';

  @override
  String get milestoneTenFillUps => '10 fill-ups tracked';

  @override
  String get milestoneFiftyFillUps => '50 fill-ups tracked';

  @override
  String get milestoneHundredLiters => '100 L tracked';

  @override
  String get milestoneThousandLiters => '1000 L tracked';

  @override
  String get milestoneHundredKgCo2 => '100 kg CO2 tracked';

  @override
  String get milestoneOneTonneCo2 => '1 tonne CO2 tracked';

  @override
  String get milestoneThousandKm => '1000 km driven';

  @override
  String get milestoneTenThousandKm => '10,000 km driven';

  @override
  String get fuelVsEvTitle => 'Fuel vs EV';

  @override
  String get fuelVsEvSubtitle => 'CO2 comparison for the same distance driven';

  @override
  String get fuelVsEvYourFuel => 'Your fuel';

  @override
  String get fuelVsEvEquivalent => 'Equivalent EV';

  @override
  String get fuelVsEvDistance => 'Distance';

  @override
  String get fuelVsEvDifference => 'Difference';

  @override
  String get shareProgress => 'Share';

  @override
  String get shareCopied => 'Copied to clipboard';

  @override
  String shareCo2Message(String kg) {
    return 'I tracked $kg kg CO2 with Tankstellen.';
  }

  @override
  String get vehiclesTitle => 'My vehicles';

  @override
  String get vehiclesMenuTitle => 'My vehicles';

  @override
  String get vehiclesMenuSubtitle =>
      'Battery, connectors, charging preferences';

  @override
  String get vehiclesEmptyMessage =>
      'Add your car to filter by connector and estimate charging costs.';

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
}
