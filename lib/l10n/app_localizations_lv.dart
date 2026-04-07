// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'Degvielas cenas';

  @override
  String get search => 'Meklēt';

  @override
  String get favorites => 'Izlase';

  @override
  String get map => 'Karte';

  @override
  String get profile => 'Profils';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get gpsLocation => 'GPS atrašanās vieta';

  @override
  String get zipCode => 'Pasta indekss';

  @override
  String get zipCodeHint => 'piem. LV-1001';

  @override
  String get fuelType => 'Degviela';

  @override
  String get searchRadius => 'Rādiuss';

  @override
  String get searchNearby => 'Degvielas uzpildes stacijas tuvumā';

  @override
  String get searchButton => 'Meklēt';

  @override
  String get noResults => 'Degvielas uzpildes stacijas nav atrastas.';

  @override
  String get startSearch => 'Meklējiet degvielas uzpildes stacijas.';

  @override
  String get open => 'Atvērts';

  @override
  String get closed => 'Slēgts';

  @override
  String distance(String distance) {
    return '$distance attālumā';
  }

  @override
  String get price => 'Cena';

  @override
  String get prices => 'Cenas';

  @override
  String get address => 'Adrese';

  @override
  String get openingHours => 'Darba laiks';

  @override
  String get open24h => 'Atvērts 24 stundas';

  @override
  String get navigate => 'Navigēt';

  @override
  String get retry => 'Mēģināt vēlreiz';

  @override
  String get apiKeySetup => 'API atslēga';

  @override
  String get apiKeyDescription =>
      'Reģistrējieties vienreiz, lai saņemtu bezmaksas API atslēgu.';

  @override
  String get apiKeyLabel => 'API atslēga';

  @override
  String get register => 'Reģistrācija';

  @override
  String get continueButton => 'Turpināt';

  @override
  String get welcome => 'Degvielas cenas';

  @override
  String get welcomeSubtitle => 'Atrodiet lētāko degvielu tuvumā.';

  @override
  String get profileName => 'Profila nosaukums';

  @override
  String get preferredFuel => 'Izvēlētā degviela';

  @override
  String get defaultRadius => 'Noklusējuma rādiuss';

  @override
  String get landingScreen => 'Sākuma ekrāns';

  @override
  String get homeZip => 'Mājas pasta indekss';

  @override
  String get newProfile => 'Jauns profils';

  @override
  String get editProfile => 'Rediģēt profilu';

  @override
  String get save => 'Saglabāt';

  @override
  String get cancel => 'Atcelt';

  @override
  String get delete => 'Dzēst';

  @override
  String get activate => 'Aktivizēt';

  @override
  String get configured => 'Konfigurēts';

  @override
  String get notConfigured => 'Nav konfigurēts';

  @override
  String get about => 'Par lietotni';

  @override
  String get openSource => 'Atvērtais kods (MIT licence)';

  @override
  String get sourceCode => 'Pirmkods GitHub';

  @override
  String get noFavorites => 'Nav izlases';

  @override
  String get noFavoritesHint =>
      'Pieskarieties zvaigznītei pie stacijas, lai saglabātu to izlasē.';

  @override
  String get language => 'Valoda';

  @override
  String get country => 'Valsts';

  @override
  String get demoMode => 'Demo režīms — tiek rādīti paraugu dati.';

  @override
  String get setupLiveData => 'Iestatīt reāllaika datus';

  @override
  String get freeNoKey => 'Bezmaksas — atslēga nav nepieciešama';

  @override
  String get apiKeyRequired => 'Nepieciešama API atslēga';

  @override
  String get skipWithoutKey => 'Turpināt bez atslēgas';

  @override
  String get dataTransparency => 'Datu caurredzamība';

  @override
  String get storageAndCache => 'Krātuve un kešatmiņa';

  @override
  String get clearCache => 'Iztīrīt kešatmiņu';

  @override
  String get clearAllData => 'Dzēst visus datus';

  @override
  String get errorLog => 'Kļūdu žurnāls';

  @override
  String stationsFound(int count) {
    return 'Atrastas $count stacijas';
  }

  @override
  String get whatIsShared => 'Kas tiek kopīgots — un ar ko?';

  @override
  String get gpsCoordinates => 'GPS koordinātas';

  @override
  String get gpsReason =>
      'Tiek nosūtītas ar katru meklējumu, lai atrastu tuvumā esošās stacijas.';

  @override
  String get postalCodeData => 'Pasta indekss';

  @override
  String get postalReason =>
      'Tiek pārveidots koordinātās, izmantojot ģeokodēšanas pakalpojumu.';

  @override
  String get mapViewport => 'Kartes skats';

  @override
  String get mapReason =>
      'Kartes flīzes tiek ielādētas no servera. Personas dati netiek pārsūtīti.';

  @override
  String get apiKeyData => 'API atslēga';

  @override
  String get apiKeyReason =>
      'Jūsu personīgā atslēga tiek nosūtīta ar katru API pieprasījumu. Tā ir saistīta ar jūsu e-pastu.';

  @override
  String get notShared => 'NETIEK kopīgots:';

  @override
  String get searchHistory => 'Meklēšanas vēsture';

  @override
  String get favoritesData => 'Izlase';

  @override
  String get profileNames => 'Profilu nosaukumi';

  @override
  String get homeZipData => 'Mājas pasta indekss';

  @override
  String get usageData => 'Lietošanas dati';

  @override
  String get privacyBanner =>
      'Šai lietotnei nav servera. Visi dati paliek jūsu ierīcē. Bez analītikas, izsekošanas vai reklāmām.';

  @override
  String get storageUsage => 'Krātuves izmantošana šajā ierīcē';

  @override
  String get settingsLabel => 'Iestatījumi';

  @override
  String get profilesStored => 'saglabāti profili';

  @override
  String get stationsMarked => 'atzīmētas stacijas';

  @override
  String get cachedResponses => 'kešatmiņā saglabātas atbildes';

  @override
  String get total => 'Kopā';

  @override
  String get cacheManagement => 'Kešatmiņas pārvaldība';

  @override
  String get cacheDescription =>
      'Kešatmiņa saglabā API atbildes ātrākai ielādei un bezsaistes piekļuvei.';

  @override
  String get stationSearch => 'Staciju meklēšana';

  @override
  String get stationDetails => 'Stacijas informācija';

  @override
  String get priceQuery => 'Cenu pieprasījums';

  @override
  String get zipGeocoding => 'Pasta indeksa ģeokodēšana';

  @override
  String minutes(int n) {
    return '$n minūtes';
  }

  @override
  String hours(int n) {
    return '$n stundas';
  }

  @override
  String get clearCacheTitle => 'Iztīrīt kešatmiņu?';

  @override
  String get clearCacheBody =>
      'Kešatmiņā saglabātie meklēšanas rezultāti un cenas tiks dzēsti. Profili, izlase un iestatījumi tiks saglabāti.';

  @override
  String get clearCacheButton => 'Iztīrīt kešatmiņu';

  @override
  String get deleteAllTitle => 'Dzēst visus datus?';

  @override
  String get deleteAllBody =>
      'Tas neatgriezeniski dzēš visus profilus, izlasi, API atslēgu, iestatījumus un kešatmiņu. Lietotne tiks atiestatīta.';

  @override
  String get deleteAllButton => 'Dzēst visu';

  @override
  String get entries => 'ieraksti';

  @override
  String get cacheEmpty => 'Kešatmiņa ir tukša';

  @override
  String get noStorage => 'Krātuve netiek izmantota';

  @override
  String get apiKeyNote =>
      'Bezmaksas reģistrācija. Dati no valdības cenu caurredzamības aģentūrām.';

  @override
  String get supportProject => 'Atbalstiet šo projektu';

  @override
  String get supportDescription =>
      'Šī lietotne ir bezmaksas, atvērtā koda un bez reklāmām. Ja tā jums šķiet noderīga, apsveriet iespēju atbalstīt izstrādātāju.';

  @override
  String get reportBug => 'Ziņot par kļūdu / Ieteikt funkciju';

  @override
  String get privacyPolicy => 'Privātuma politika';

  @override
  String get fuels => 'Degvielas';

  @override
  String get services => 'Pakalpojumi';

  @override
  String get zone => 'Zona';

  @override
  String get highway => 'Automaģistrāle';

  @override
  String get localStation => 'Vietējā stacija';

  @override
  String get lastUpdate => 'Pēdējais atjauninājums';

  @override
  String get automate24h => '24st/24 — Automāts';

  @override
  String get refreshPrices => 'Atjaunināt cenas';

  @override
  String get station => 'Degvielas uzpildes stacija';

  @override
  String get locationDenied =>
      'Atrašanās vietas atļauja noraidīta. Varat meklēt pēc pasta indeksa.';

  @override
  String get demoModeBanner =>
      'Demo režīms. Konfigurējiet API atslēgu iestatījumos.';

  @override
  String get sortDistance => 'Attālums';

  @override
  String get cheap => 'lēti';

  @override
  String get expensive => 'dārgi';

  @override
  String stationsOnMap(int count) {
    return '$count stacijas';
  }

  @override
  String get loadingFavorites =>
      'Ielādē izlasi...\nVispirms meklējiet stacijas, lai saglabātu datus.';

  @override
  String get reportPrice => 'Ziņot par cenu';

  @override
  String get whatsWrong => 'Kas nav pareizi?';

  @override
  String get correctPrice => 'Pareizā cena (piem. 1,459)';

  @override
  String get sendReport => 'Nosūtīt ziņojumu';

  @override
  String get reportSent => 'Ziņojums nosūtīts. Paldies!';

  @override
  String get enterValidPrice => 'Ievadiet derīgu cenu';

  @override
  String get cacheCleared => 'Kešatmiņa iztīrīta.';

  @override
  String get yourPosition => 'Jūsu pozīcija';

  @override
  String get positionUnknown => 'Pozīcija nezināma';

  @override
  String get distancesFromCenter => 'Attālumi no meklēšanas centra';

  @override
  String get autoUpdatePosition => 'Automātiski atjaunināt pozīciju';

  @override
  String get autoUpdateDescription =>
      'Atjaunināt GPS pozīciju pirms katras meklēšanas';

  @override
  String get location => 'Atrašanās vieta';

  @override
  String get switchProfileTitle => 'Valsts mainīta';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Jūs tagad esat $country. Pārslēgt uz profilu \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Pārslēgts uz profilu \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Nav profila šai valstij';

  @override
  String noProfileForCountry(String country) {
    return 'Jūs esat $country, bet profils nav konfigurēts. Izveidojiet to Iestatījumos.';
  }

  @override
  String get autoSwitchProfile => 'Automātiska profila maiņa';

  @override
  String get autoSwitchDescription =>
      'Automātiski mainīt profilu, šķērsojot robežu';

  @override
  String get switchProfile => 'Pārslēgt';

  @override
  String get dismiss => 'Aizvērt';

  @override
  String get profileCountry => 'Valsts';

  @override
  String get profileLanguage => 'Valoda';

  @override
  String get settingsStorageDetail => 'API atslēga, aktīvais profils';

  @override
  String get allFuels => 'Visas';

  @override
  String get priceAlerts => 'Cenu brīdinājumi';

  @override
  String get noPriceAlerts => 'Nav cenu brīdinājumu';

  @override
  String get noPriceAlertsHint =>
      'Izveidojiet brīdinājumu no stacijas detaļu lapas.';

  @override
  String alertDeleted(String name) {
    return 'Brīdinājums \"$name\" dzēsts';
  }

  @override
  String get createAlert => 'Izveidot cenu brīdinājumu';

  @override
  String currentPrice(String price) {
    return 'Pašreizējā cena: $price';
  }

  @override
  String get targetPrice => 'Mērķa cena (EUR)';

  @override
  String get enterPrice => 'Ievadiet cenu';

  @override
  String get invalidPrice => 'Nederīga cena';

  @override
  String get priceTooHigh => 'Cena pārāk augsta';

  @override
  String get create => 'Izveidot';

  @override
  String get alertCreated => 'Cenu brīdinājums izveidots';

  @override
  String get wrongE5Price => 'Nepareiza Super E5 cena';

  @override
  String get wrongE10Price => 'Nepareiza Super E10 cena';

  @override
  String get wrongDieselPrice => 'Nepareiza dīzeļa cena';

  @override
  String get wrongStatusOpen => 'Parādīts kā atvērts, bet slēgts';

  @override
  String get wrongStatusClosed => 'Parādīts kā slēgts, bet atvērts';

  @override
  String get searchAlongRouteLabel => 'Gar maršrutu';

  @override
  String get searchEvStations => 'Meklēt uzlādes stacijas';

  @override
  String get allStations => 'Visas stacijas';

  @override
  String get bestStops => 'Labākās pieturas';

  @override
  String get openInMaps => 'Atvērt Kartēs';

  @override
  String get noStationsAlongRoute => 'Stacijas gar maršrutu nav atrastas';

  @override
  String get evOperational => 'Darbojas';

  @override
  String get evStatusUnknown => 'Statuss nezināms';

  @override
  String evConnectors(int count) {
    return 'Savienotāji ($count punkti)';
  }

  @override
  String get evNoConnectors => 'Nav pieejama savienotāju informācija';

  @override
  String get evUsageCost => 'Lietošanas izmaksas';

  @override
  String get evPricingUnavailable =>
      'Cenu informācija nav pieejama no pakalpojumu sniedzēja';

  @override
  String get evLastUpdated => 'Pēdējoreiz atjaunināts';

  @override
  String get evUnknown => 'Nezināms';

  @override
  String get evDataAttribution => 'Dati no OpenChargeMap (kopienas avots)';

  @override
  String get evStatusDisclaimer =>
      'Statuss var neatspoguļot pieejamību reāllaikā. Pieskarieties atjaunināt, lai iegūtu jaunākos datus.';

  @override
  String get evNavigateToStation => 'Navigēt uz staciju';

  @override
  String get evRefreshStatus => 'Atjaunināt statusu';

  @override
  String get evStatusUpdated => 'Statuss atjaunināts';

  @override
  String get evStationNotFound =>
      'Nevar atjaunināt — stacija nav atrasta tuvumā';

  @override
  String get addedToFavorites => 'Pievienots izlasei';

  @override
  String get removedFromFavorites => 'Noņemts no izlases';

  @override
  String get addFavorite => 'Pievienot izlasei';

  @override
  String get removeFavorite => 'Noņemt no izlases';

  @override
  String get currentLocation => 'Pašreizējā atrašanās vieta';

  @override
  String get gpsError => 'GPS kļūda';

  @override
  String get couldNotResolve => 'Nevar noteikt sākumu vai galamērķi';

  @override
  String get start => 'Sākums';

  @override
  String get destination => 'Galamērķis';

  @override
  String get cityAddressOrGps => 'Pilsēta, adrese vai GPS';

  @override
  String get cityOrAddress => 'Pilsēta vai adrese';

  @override
  String get useGps => 'Izmantot GPS';

  @override
  String get stop => 'Pietura';

  @override
  String stopN(int n) {
    return 'Pietura $n';
  }

  @override
  String get addStop => 'Pievienot pieturu';

  @override
  String get searchAlongRoute => 'Meklēt gar maršrutu';

  @override
  String get cheapest => 'Lētākā';

  @override
  String nStations(int count) {
    return '$count stacijas';
  }

  @override
  String nBest(int count) {
    return '$count labākās';
  }

  @override
  String get fuelPricesTankerkoenig => 'Degvielas cenas (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Nepieciešams degvielas cenu meklēšanai Vācijā';

  @override
  String get evChargingOpenChargeMap => 'EV uzlāde (OpenChargeMap)';

  @override
  String get customKey => 'Pielāgota atslēga';

  @override
  String get appDefaultKey => 'Lietotnes noklusējuma atslēga';

  @override
  String get optionalOverrideKey =>
      'Pēc izvēles: aizstāt iebūvēto lietotnes atslēgu ar savu';

  @override
  String get requiredForEvSearch =>
      'Nepieciešams EV uzlādes staciju meklēšanai';

  @override
  String get edit => 'Rediģēt';

  @override
  String get fuelPricesApiKey => 'Degvielas cenu API atslēga';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API atslēga';

  @override
  String get evChargingApiKey => 'EV uzlādes API atslēga';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API atslēga';

  @override
  String get routeSegment => 'Maršruta segments';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Rādīt lētāko staciju ik $km km gar maršrutu';
  }

  @override
  String get avoidHighways => 'Izvairīties no automaģistrālēm';

  @override
  String get avoidHighwaysDesc =>
      'Maršruta aprēķins izvairās no maksas ceļiem un automaģistrālēm';

  @override
  String get showFuelStations => 'Rādīt degvielas uzpildes stacijas';

  @override
  String get showFuelStationsDesc =>
      'Iekļaut benzīna, dīzeļa, LPG, CNG stacijas';

  @override
  String get showEvStations => 'Rādīt uzlādes stacijas';

  @override
  String get showEvStationsDesc =>
      'Iekļaut elektriskās uzlādes stacijas meklēšanas rezultātos';

  @override
  String get noStationsAlongThisRoute =>
      'Stacijas gar šo maršrutu nav atrastas.';

  @override
  String get fuelCostCalculator => 'Degvielas izmaksu kalkulators';

  @override
  String get distanceKm => 'Attālums (km)';

  @override
  String get consumptionL100km => 'Patēriņš (L/100km)';

  @override
  String get fuelPriceEurL => 'Degvielas cena (EUR/L)';

  @override
  String get tripCost => 'Brauciena izmaksas';

  @override
  String get fuelNeeded => 'Nepieciešamā degviela';

  @override
  String get totalCost => 'Kopējās izmaksas';

  @override
  String get enterCalcValues =>
      'Ievadiet attālumu, patēriņu un cenu, lai aprēķinātu brauciena izmaksas';

  @override
  String get priceHistory => 'Cenu vēsture';

  @override
  String get noPriceHistory => 'Vēl nav cenu vēstures';

  @override
  String get noHourlyData => 'Nav stundu datu';

  @override
  String get noStatistics => 'Nav pieejamu statistiku';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Vid';

  @override
  String get showAllFuelTypes => 'Rādīt visus degvielas veidus';

  @override
  String get connected => 'Savienots';

  @override
  String get notConnected => 'Nav savienots';

  @override
  String get connectTankSync => 'Savienot TankSync';

  @override
  String get disconnectTankSync => 'Atvienot TankSync';

  @override
  String get viewMyData => 'Skatīt manus datus';

  @override
  String get optionalCloudSync =>
      'Izvēles mākoņa sinhronizācija brīdinājumiem, izlasei un push paziņojumiem';

  @override
  String get tapToUpdateGps => 'Pieskarieties, lai atjauninātu GPS pozīciju';

  @override
  String get gpsAutoUpdateHint =>
      'GPS pozīcija tiek iegūta automātiski, meklējot. Varat to arī manuāli atjaunināt šeit.';

  @override
  String get clearGpsConfirm =>
      'Notīrīt saglabāto GPS pozīciju? Varat to atjaunināt jebkurā laikā.';

  @override
  String get pageNotFound => 'Lapa nav atrasta';

  @override
  String get deleteAllServerData => 'Dzēst visus servera datus';

  @override
  String get deleteServerDataConfirm => 'Dzēst visus servera datus?';

  @override
  String get deleteEverything => 'Dzēst visu';

  @override
  String get allDataDeleted => 'Visi servera dati dzēsti';

  @override
  String get disconnectConfirm => 'Atvienot TankSync?';

  @override
  String get disconnect => 'Atvienot';

  @override
  String get myServerData => 'Mani servera dati';

  @override
  String get anonymousUuid => 'Anonīms UUID';

  @override
  String get server => 'Serveris';

  @override
  String get syncedData => 'Sinhronizētie dati';

  @override
  String get pushTokens => 'Push marķieri';

  @override
  String get priceReports => 'Cenu ziņojumi';

  @override
  String get totalItems => 'Kopā vienību';

  @override
  String get estimatedSize => 'Aptuvens lielums';

  @override
  String get viewRawJson => 'Skatīt neapstrādātus datus kā JSON';

  @override
  String get exportJson => 'Eksportēt kā JSON (starpliktuve)';

  @override
  String get jsonCopied => 'JSON nokopēts starpliktuvē';

  @override
  String get rawDataJson => 'Neapstrādāti dati (JSON)';

  @override
  String get close => 'Aizvērt';

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
