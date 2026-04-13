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
  String get searchCriteriaTitle => 'Search criteria';

  @override
  String get searchCriteriaOpen => 'Search';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Within $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tap to start searching';

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
  String get apiKeyFormatError =>
      'Nederīgs formāts — gaidīts UUID (8-4-4-4-12)';

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
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

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
  String get alertStatsActive => 'Aktīvas';

  @override
  String get alertStatsToday => 'Šodien';

  @override
  String get alertStatsThisWeek => 'Šo nedēļu';

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
  String get nearestStations => 'Tuvakias degvielas uzpildes stacijas';

  @override
  String get nearestStationsHint =>
      'Atrodiet tuvakias degvielas uzpildes stacijas pec jusu pasreizejas atrasanas vietas';

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

  @override
  String get evShowOnMap => 'Show EV stations';

  @override
  String get evAvailableOnly => 'Available only';

  @override
  String get evMinPower => 'Min power';

  @override
  String get evMaxPower => 'Max power';

  @override
  String get evOperator => 'Operator';

  @override
  String get evLastUpdate => 'Last update';

  @override
  String get evStatusAvailable => 'Available';

  @override
  String get evStatusOccupied => 'Occupied';

  @override
  String get evStatusOutOfOrder => 'Out of order';

  @override
  String get openOnlyFilter => 'Open only';

  @override
  String get saveAsDefaults => 'Save as my defaults';

  @override
  String get criteriaSavedToProfile => 'Saved as defaults';

  @override
  String get profileNotFound => 'No active profile';

  @override
  String get updatingFavorites => 'Updating your favorites...';

  @override
  String get fetchingLatestPrices => 'Fetching the latest prices';

  @override
  String get noDataAvailable => 'No data';

  @override
  String get configAndPrivacy => 'Configuration & Privacy';

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
  String get tooltipBack => 'Back';

  @override
  String get tooltipClose => 'Close';

  @override
  String get tooltipClearSearch => 'Clear search input';

  @override
  String get tooltipUseGps => 'Use GPS location';

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
      'Set a price threshold for a station. You\'ll be notified when prices drop below it. Checks run every 30 minutes.';

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
  String get scanReceipt => 'Scan receipt';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Fuel';

  @override
  String get stationTypeEv => 'EV';

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
  String get detailsLabel => 'Details';

  @override
  String get remove => 'Remove';

  @override
  String get showKey => 'Show key';

  @override
  String get hideKey => 'Hide key';
}
