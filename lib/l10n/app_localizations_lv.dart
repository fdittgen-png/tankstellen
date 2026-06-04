// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Atvērt meklēšanu';

  @override
  String get fabOpenResults => 'Atvērt rezultātus';

  @override
  String get fabRunSearch => 'Veikt meklēšanu';

  @override
  String get fabRefineCriteria => 'Precizēt meklēšanu';

  @override
  String get routeSearchPartialBanner => 'Tiek meklētas vairāk staciju…';

  @override
  String get routeSearchingChip => 'Searching the route…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Every $km km';
  }

  @override
  String get searchCriteriaTitle => 'Meklēšanas kritēriji';

  @override
  String get searchCriteriaOpen => 'Meklēt';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km rādiusā';
  }

  @override
  String get searchCriteriaTapToSearch => 'Pieskarieties, lai sāktu meklēšanu';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Mainīt valsti?';

  @override
  String countryChangeBody(String country) {
    return 'Pārslēdzoties uz $country, mainīsies:';
  }

  @override
  String get countryChangeCurrency => 'Valūta';

  @override
  String get countryChangeDistance => 'Attālums';

  @override
  String get countryChangeVolume => 'Tilpums';

  @override
  String get countryChangePricePerUnit => 'Cenas formāts';

  @override
  String get countryChangeNote =>
      'Esošie izlases un uzpildes žurnāli netiek pārrakstīti; tikai jauniem ierakstiem tiek lietotas jaunās mērvienības.';

  @override
  String get countryChangeConfirm => 'Mainīt';

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
  String get cacheTtlGroupNetwork => 'Tīkls';

  @override
  String get cacheTtlGroupData => 'Dati';

  @override
  String get cacheTtlGroupGeocoding => 'Ģeokodēšana';

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
  String get reportThisIssue => 'Ziņot par problēmu';

  @override
  String get reportAlreadySent => 'Jūs jau ziņojāt par šo problēmu.';

  @override
  String get reportConsentTitle => 'Ziņot GitHub?';

  @override
  String get reportConsentBody =>
      'Tiks atvērts publisks GitHub ziņojums ar kļūdas informāciju. GPS koordinātas, API atslēgas vai personas dati netiek iekļauti.';

  @override
  String get reportConsentConfirm => 'Atvērt GitHub';

  @override
  String get reportConsentCancel => 'Atcelt';

  @override
  String get configProfileSection => 'Profils';

  @override
  String get configActiveProfile => 'Aktīvais profils';

  @override
  String get configPreferredFuel => 'Vēlamais degvielas veids';

  @override
  String get configCountry => 'Valsts';

  @override
  String get configRouteSegment => 'Maršruta posms';

  @override
  String get configApiKeysSection => 'API atslēgas';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API atslēga';

  @override
  String get configApiKeyConfigured => 'Konfigurēta';

  @override
  String get configApiKeyNotSet => 'Nav iestatīta (demonstrācijas režīms)';

  @override
  String get configApiKeyCommunity => 'Noklusējums (kopienas atslēga)';

  @override
  String get searchLocationPlaceholder => 'Adrese, pasta indekss vai pilsēta';

  @override
  String get configEvKey => 'EV uzlādes API atslēga';

  @override
  String get configEvKeyCustom => 'Pielāgota atslēga';

  @override
  String get configEvKeyShared => 'Noklusējums (kopīga)';

  @override
  String get configCloudSyncSection => 'Mākoņa sinhronizācija';

  @override
  String get configTankSyncConnected => 'Savienots';

  @override
  String get configTankSyncDisabled => 'Atspējots';

  @override
  String get configAuthMode => 'Autentifikācijas veids';

  @override
  String get configAuthEmail => 'E-pasts (pastāvīgs)';

  @override
  String get configAuthAnonymous => 'Anonīms (tikai šī ierīce)';

  @override
  String get configDatabase => 'Datu bāze';

  @override
  String get configPrivacySummary => 'Privātuma kopsavilkums';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Izlases, brīdinājumi un ignorētās stacijas tiek sinhronizētas ar jūsu privāto datu bāzi\n• GPS atrašanās vieta un API atslēgas nekad neatstāj jūsu ierīci\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Visi dati tiek glabāti tikai lokāli šajā ierīcē\n• Nav datu, kas tiek sūtīti uz serveri\n• API atslēgas šifrētas ierīces drošajā atmiņā';

  @override
  String get configAuthNoteEmail =>
      'E-pasta konts nodrošina piekļuvi no vairākām ierīcēm';

  @override
  String get configAuthNoteAnonymous =>
      'Anonīms konts — dati saistīti ar šo ierīci';

  @override
  String get configNone => 'Nav';

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
  String get demoModeBannerAction => 'Iegūt aktuālās cenas';

  @override
  String get sortDistance => 'Attālums';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Vērtējums';

  @override
  String get sortPriceDistance => 'Cena/km';

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
  String get routeModeBannerLabel => 'Maršruta režīms — attālumi gar koridoru';

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
  String get routePlanningSection => 'Maršruta plānošana';

  @override
  String get routeMinSaving => 'Minimālais ietaupījums';

  @override
  String get routeMinSavingOff => 'Izslēgts';

  @override
  String get routeMinSavingOffCaption =>
      'Tiek rādītas visas maršrutā atrastās stacijas';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Tikai stacijas $amount robežās no lētākās maršrutā';
  }

  @override
  String get routeDetourBudget => 'Maksimālais apvedceļš';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Rādīt stacijas līdz $km km no tiešā maršruta';
  }

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
  String get priceHistory => 'Cenu vēsture';

  @override
  String get ignoredStationsLabel => 'Ignorētas';

  @override
  String get ratingsLabel => 'Vērtējumi';

  @override
  String get favoritesDataCache => 'Iecienīto dati';

  @override
  String get citySearchCache => 'Pilsētas meklēšana';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Datu dzēšana nav pieejama Kopienas režīmā. Vispirms atvienojieties vai izmantojiet privātu datu bāzi.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count izsekotas stacijas';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count konfigurētas';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count paslēptas stacijas';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count novērtētas stacijas';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Dzēst visus sinhronizētos braucienus';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Dzēst visus sinhronizētos braucienus?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Visi braucienu kopsavilkumi un detaļu dati tiks noņemti no servera. Lokālā braucienu vēsture šajā ierīcē netiks ietekmēta.\n\nŠo darbību nevar atcelt.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Dzēst visu';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Visi sinhronizētie braucieni noņemti no servera';

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
  String get syncedTrips => 'Braucieni';

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
  String get account => 'Konts';

  @override
  String get continueAsGuest => 'Turpināt kā viesis';

  @override
  String get createAccount => 'Izveidot kontu';

  @override
  String get signIn => 'Pierakstīties';

  @override
  String get upgradeToEmail => 'Izveidot e-pasta kontu';

  @override
  String get savedRoutes => 'Saglabātie maršruti';

  @override
  String get noSavedRoutes => 'Nav saglabātu maršrutu';

  @override
  String get noSavedRoutesHint =>
      'Meklējiet gar maršrutu un saglabājiet to ātrai piekļuvei vēlāk.';

  @override
  String get saveRoute => 'Saglabāt maršrutu';

  @override
  String get routeName => 'Maršruta nosaukums';

  @override
  String itineraryDeleted(String name) {
    return '$name dzēsts';
  }

  @override
  String loadingRoute(String name) {
    return 'Ielādē maršrutu: $name';
  }

  @override
  String get refreshFailed =>
      'Atjaunināšana neizdevās. Lūdzu, mēģiniet vēlreiz.';

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
  String get onboardingWelcomeHint => 'Iestatiet lietotni dažos ātros soļos.';

  @override
  String get onboardingApiKeyDescription =>
      'Reģistrējieties bezmaksas API atslēgai vai izlaidiet un izpētiet lietotni ar demonstrācijas datiem.';

  @override
  String get onboardingComplete => 'Viss gatavs!';

  @override
  String get onboardingCompleteHint =>
      'Šos iestatījumus varat mainīt jebkurā laikā savā profilā.';

  @override
  String get onboardingBack => 'Atpakaļ';

  @override
  String get onboardingNext => 'Tālāk';

  @override
  String get onboardingSkip => 'Izlaist';

  @override
  String get onboardingFinish => 'Sākt';

  @override
  String crossBorderNearby(String country) {
    return '$country ir tuvumā';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km līdz robežai';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Vid. šeit: $price EUR ($count stacijas)';
  }

  @override
  String get allPricesView => 'Visas cenas';

  @override
  String get compactView => 'Kompakts';

  @override
  String get switchToAllPricesView => 'Pārslēgties uz visu cenu skatu';

  @override
  String get switchToCompactView => 'Pārslēgties uz kompakto skatu';

  @override
  String get unavailable => 'Nav pieejams';

  @override
  String get outOfStock => 'Nav krājumā';

  @override
  String get gdprTitle => 'Jūsu privātums';

  @override
  String get gdprSubtitle =>
      'Šī lietotne ciena jūsu privātumu. Izvēlieties, kurus datus vēlaties kopīgot. Šos iestatījumus varat mainīt jebkurā laikā.';

  @override
  String get gdprLocationTitle => 'Atrašanās vietas piekļuve';

  @override
  String get gdprLocationDescription =>
      'Jūsu koordinātas tiek nosūtītas degvielas cenu API, lai atrastu tuvākās stacijas. Atrašanās vietas dati nekad netiek glabāti serverī un netiek izmantoti izsekošanai.';

  @override
  String get gdprLocationShort =>
      'Atrast tuvākās degvielas stacijas, izmantojot jūsu atrašanās vietu';

  @override
  String get gdprErrorReportingTitle => 'Kļūdu ziņošana';

  @override
  String get gdprErrorReportingDescription =>
      'Anonīmi avārijas ziņojumi palīdz uzlabot lietotni. Personas dati netiek iekļauti. Ziņojumi tiek sūtīti caur Sentry tikai tad, ja tas ir konfigurēts.';

  @override
  String get gdprErrorReportingShort =>
      'Sūtīt anonīmus avārijas ziņojumus lietotnes uzlabošanai';

  @override
  String get gdprCloudSyncTitle => 'Mākoņa sinhronizācija';

  @override
  String get gdprCloudSyncDescription =>
      'Sinhronizējiet izlases un brīdinājumus starp ierīcēm, izmantojot TankSync. Tiek izmantota anonīma autentifikācija. Jūsu dati ir šifrēti pārsūtīšanas laikā.';

  @override
  String get gdprCloudSyncShort =>
      'Sinhronizēt izlases un brīdinājumus starp ierīcēm';

  @override
  String get gdprLegalBasis =>
      'Juridiskais pamats: VDAR 6. panta 1. punkta a) apakšpunkts (piekrišana). Piekrišanu varat atsaukt jebkurā laikā iestatījumos.';

  @override
  String get gdprAcceptAll => 'Pieņemt visu';

  @override
  String get gdprAcceptSelected => 'Pieņemt izvēlētos';

  @override
  String get gdprSettingsHint =>
      'Jūs varat mainīt privātuma izvēles jebkurā laikā.';

  @override
  String get routeSaved => 'Maršruts saglabāts!';

  @override
  String get routeSaveFailed => 'Maršruta saglabāšana neizdevās';

  @override
  String get sqlCopied => 'SQL nokopēts starpliktuvē';

  @override
  String get connectionDataCopied => 'Savienojuma dati nokopēti';

  @override
  String get accountDeleted => 'Konts dzēsts. Lokālie dati saglabāti.';

  @override
  String get switchedToAnonymous => 'Pārslēgts uz anonīmo sesiju';

  @override
  String failedToSwitch(String error) {
    return 'Pārslēgšanās neizdevās: $error';
  }

  @override
  String get topicUrlCopied => 'Tēmas URL nokopēts';

  @override
  String get testNotificationSent => 'Testa paziņojums nosūtīts!';

  @override
  String get testNotificationFailed => 'Testa paziņojuma nosūtīšana neizdevās';

  @override
  String get pushUpdateFailed =>
      'Push paziņojuma iestatījuma atjaunināšana neizdevās';

  @override
  String get connectedAsGuest => 'Savienots kā viesis';

  @override
  String get accountCreated => 'Konts izveidots!';

  @override
  String get signedIn => 'Pierakstīšanās veiksmīga!';

  @override
  String stationHidden(String name) {
    return '$name paslēpts';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name noņemts no izlases';
  }

  @override
  String invalidApiKey(String error) {
    return 'Nederīga API atslēga: $error';
  }

  @override
  String get invalidQrCode => 'Nederīgs QR koda formāts';

  @override
  String get invalidQrCodeTankSync =>
      'Nederīgs QR kods — gaidīts TankSync formāts';

  @override
  String get tankSyncConnected => 'TankSync savienots!';

  @override
  String get syncCompleted => 'Sinhronizācija pabeigta — dati atjaunināti';

  @override
  String get deviceCodeCopied => 'Ierīces kods nokopēts';

  @override
  String get undo => 'Atsaukt';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Lūdzu, ievadiet derīgu $length ciparu $label';
  }

  @override
  String get freshnessAgo => 'pirms';

  @override
  String get freshnessStale => 'Novecojis';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Datu aktualitāte: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand logotips';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Novērtēt ar $count zvaigznēm',
      one: 'Novērtēt ar 1 zvaigzni',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Vāja';

  @override
  String get passwordStrengthFair => 'Vidēja';

  @override
  String get passwordStrengthStrong => 'Stipra';

  @override
  String get passwordReqMinLength => 'Vismaz 8 rakstzīmes';

  @override
  String get passwordReqUppercase => 'Vismaz 1 lielais burts';

  @override
  String get passwordReqLowercase => 'Vismaz 1 mazais burts';

  @override
  String get passwordReqDigit => 'Vismaz 1 cipars';

  @override
  String get passwordReqSpecial => 'Vismaz 1 īpašā rakstzīme';

  @override
  String get passwordTooWeak => 'Parole neatbilst visām prasībām';

  @override
  String get brandFilterAll => 'Visas';

  @override
  String get brandFilterNoHighway => 'Bez autoceļa';

  @override
  String get swipeTutorialMessage =>
      'Velciet pa labi, lai navigētu, velciet pa kreisi, lai noņemtu';

  @override
  String get swipeTutorialDismiss => 'Sapratu';

  @override
  String get alertStatsActive => 'Aktīvas';

  @override
  String get alertStatsToday => 'Šodien';

  @override
  String get alertStatsThisWeek => 'Šo nedēļu';

  @override
  String get privacyDashboardTitle => 'Privātuma panelis';

  @override
  String get privacyDashboardSubtitle =>
      'Skatīt, eksportēt vai dzēst savus datus';

  @override
  String get privacyDashboardBanner =>
      'Jūsu dati pieder jums. Šeit varat redzēt visu, ko šī lietotne glabā, eksportēt vai dzēst.';

  @override
  String get privacyLocalData => 'Dati šajā ierīcē';

  @override
  String get privacyIgnoredStations => 'Ignorētās stacijas';

  @override
  String get privacyRatings => 'Staciju vērtējumi';

  @override
  String get privacyPriceHistory => 'Cenu vēstures stacijas';

  @override
  String get privacyProfiles => 'Meklēšanas profili';

  @override
  String get privacyItineraries => 'Saglabātie maršruti';

  @override
  String get privacyCacheEntries => 'Kešatmiņas ieraksti';

  @override
  String get privacyApiKey => 'API atslēga glabāta';

  @override
  String get privacyEvApiKey => 'EV API atslēga glabāta';

  @override
  String get privacyEstimatedSize => 'Aptuvens krātuve';

  @override
  String get privacySyncedData => 'Mākoņa sinhronizācija (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Mākoņa sinhronizācija ir atspējota. Visi dati paliek tikai šajā ierīcē.';

  @override
  String get privacySyncMode => 'Sinhronizācijas režīms';

  @override
  String get privacySyncUserId => 'Lietotāja ID';

  @override
  String get privacySyncDescription =>
      'Kad sinhronizācija ir iespējota, izlases, brīdinājumi, ignorētās stacijas un vērtējumi tiek glabāti arī TankSync serverī.';

  @override
  String get privacyViewServerData => 'Skatīt servera datus';

  @override
  String get privacyExportButton => 'Eksportēt visus datus kā JSON';

  @override
  String get privacyExportSuccess => 'Dati eksportēti starpliktuvē';

  @override
  String get privacyExportCsvButton => 'Eksportēt visus datus kā CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV dati eksportēti starpliktuvē';

  @override
  String get savedToDownloadsFolder => 'Saglabāts mapē Lejupielādes';

  @override
  String get privacyDeleteButton => 'Dzēst visus datus';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopēt kļūdu žurnālu starpliktuvē ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Saglabāt kļūdu žurnālu ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Notīrīt kļūdu žurnālu';

  @override
  String get privacyErrorLogCleared => 'Kļūdu žurnāls notīrīts';

  @override
  String get privacyDeleteTitle => 'Dzēst visus datus?';

  @override
  String get privacyDeleteBody =>
      'Tiks neatgriezeniski dzēsts:\n\n- Visas izlases un staciju dati\n- Visi meklēšanas profili\n- Visi cenu brīdinājumi\n- Visa cenu vēsture\n- Visi kešatmiņas dati\n- Jūsu API atslēga\n- Visi lietotnes iestatījumi\n\nLietotne atiestatīsies uz sākotnējo stāvokli. Šo darbību nevar atcelt.';

  @override
  String get privacyDeleteConfirm => 'Dzēst visu';

  @override
  String get yes => 'Jā';

  @override
  String get no => 'Nē';

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
  String get paymentMethods => 'Maksājumu veidi';

  @override
  String get paymentMethodCash => 'Skaidra nauda';

  @override
  String get paymentMethodCard => 'Karte';

  @override
  String get paymentMethodContactless => 'Bezkontakta';

  @override
  String get paymentMethodFuelCard => 'Degvielas karte';

  @override
  String get paymentMethodApp => 'Lietotne';

  @override
  String payWithApp(String app) {
    return 'Maksāt ar $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Salīdzinājumā ar mainīgo vidējo pēdējo 3 uzpilžu laikā ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Patēriņš $value L/100 km, $delta salīdzinājumā ar jūsu mainīgo vidējo';
  }

  @override
  String get drivingMode => 'Braukšanas režīms';

  @override
  String get drivingExit => 'Iziet';

  @override
  String get drivingNearestStation => 'Tuvākā';

  @override
  String get drivingTapToUnlock => 'Pieskarieties, lai atbloķētu';

  @override
  String get drivingSafetyTitle => 'Drošības paziņojums';

  @override
  String get drivingSafetyMessage =>
      'Nelietojiet lietotni braukšanas laikā. Pirms mijiedarbošanās ar ekrānu apstājieties drošā vietā. Vadītājs ir atbildīgs par drošu transportlīdzekļa vadīšanu jebkurā laikā.';

  @override
  String get drivingSafetyAccept => 'Saprotu';

  @override
  String get voiceAnnouncementsTitle => 'Balss paziņojumi';

  @override
  String get voiceAnnouncementsDescription =>
      'Paziņot par lētākajām tuvākajām stacijām braukšanas laikā';

  @override
  String get voiceAnnouncementsEnabled => 'Iespējot balss paziņojumus';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Tikai zem $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometri priekšā, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Paziņojumu rādiuss';

  @override
  String get voiceAnnouncementCooldown => 'Atkārtošanas intervāls';

  @override
  String get nearestStations => 'Tuvakias degvielas uzpildes stacijas';

  @override
  String get nearestStationsHint =>
      'Atrodiet tuvakias degvielas uzpildes stacijas pec jusu pasreizejas atrasanas vietas';

  @override
  String get consumptionLogTitle => 'Degvielas patēriņš';

  @override
  String get consumptionLogMenuTitle => 'Patēriņa žurnāls';

  @override
  String get consumptionLogMenuSubtitle =>
      'Izsekot uzpildes un aprēķināt L/100km';

  @override
  String get consumptionStatsTitle => 'Patēriņa statistika';

  @override
  String get addFillUp => 'Pievienot uzpildi';

  @override
  String get noFillUpsTitle => 'Vēl nav uzpilžu';

  @override
  String get noFillUpsSubtitle =>
      'Reģistrējiet pirmo uzpildi, lai sāktu izsekot patēriņu.';

  @override
  String get fillUpDate => 'Datums';

  @override
  String get liters => 'Litri';

  @override
  String get odometerKm => 'Odometrs (km)';

  @override
  String get notesOptional => 'Piezīmes (neobligāti)';

  @override
  String get stationPreFilled => 'Stacija iepriekš aizpildīta';

  @override
  String get statAvgConsumption => 'Vid. L/100km';

  @override
  String get statAvgCostPerKm => 'Vid. izmaksas/km';

  @override
  String get statTotalLiters => 'Kopā litri';

  @override
  String get statTotalSpent => 'Kopā iztērēts';

  @override
  String get statFillUpCount => 'Uzpildes';

  @override
  String get fieldRequired => 'Obligāts lauks';

  @override
  String get fieldInvalidNumber => 'Nederīgs skaitlis';

  @override
  String get carbonDashboardTitle => 'Oglekļa panelis';

  @override
  String get carbonEmptyTitle => 'Vēl nav datu';

  @override
  String get carbonEmptySubtitle =>
      'Reģistrējiet uzpildes, lai redzētu oglekļa paneli.';

  @override
  String get carbonSummaryTotalCost => 'Kopējās izmaksas';

  @override
  String get carbonSummaryTotalCo2 => 'Kopējais CO2';

  @override
  String get monthlyCostsTitle => 'Ikmēneša izmaksas';

  @override
  String get monthlyEmissionsTitle => 'Ikmēneša CO2 emisijas';

  @override
  String get vehiclesTitle => 'Mani transportlīdzekļi';

  @override
  String get vehiclesMenuTitle => 'Mani transportlīdzekļi';

  @override
  String get vehiclesMenuSubtitle =>
      'Akumulators, savienotāji, uzlādes preferences';

  @override
  String get vehiclesEmptyMessage =>
      'Pievienojiet savu automašīnu, lai filtrētu pēc savienotāja un aprēķinātu uzlādes izmaksas.';

  @override
  String get vehiclesWizardTitle => 'Mani transportlīdzekļi (neobligāti)';

  @override
  String get vehiclesWizardSubtitle =>
      'Pievienojiet savu automašīnu, lai iepriekš aizpildītu patēriņa žurnālu un iespējotu EV savienotāju filtrus. Varat izlaist un pievienot transportlīdzekļus vēlāk.';

  @override
  String get vehiclesWizardNoneYet =>
      'Vēl nav konfigurēts neviens transportlīdzeklis.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transportlīdzekļi',
      one: '1 transportlīdzeklis',
    );
    return 'Jums ir $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Izlaist, lai pabeigtu iestatīšanu — transportlīdzekļus varat pievienot jebkurā laikā no Iestatījumiem.';

  @override
  String get fillUpVehicleLabel => 'Transportlīdzeklis';

  @override
  String get fillUpVehicleNone => 'Nav transportlīdzekļa';

  @override
  String get fillUpVehicleRequired => 'Transportlīdzeklis ir obligāts';

  @override
  String get reportScanError => 'Ziņot par skenēšanas kļūdu';

  @override
  String get pickStationTitle => 'Izvēlieties staciju';

  @override
  String get pickStationHelper =>
      'Sāciet uzpildi no zināmas stacijas, lai cenas, zīmols un degvielas veids tiku aizpildīti automātiski.';

  @override
  String get pickStationEmpty =>
      'Vēl nav izlases staciju — pievienojiet no Meklēšanas vai Izlases, vai izlaidiet un aizpildiet manuāli.';

  @override
  String get pickStationSkip => 'Izlaist — pievienot bez stacijas';

  @override
  String get scanPump => 'Skenēt sūkni';

  @override
  String get scanPayment => 'Skenēt maksājuma QR';

  @override
  String get qrPaymentBeneficiary => 'Saņēmējs';

  @override
  String get qrPaymentAmount => 'Summa';

  @override
  String get qrPaymentEpcTitle => 'SEPA maksājums';

  @override
  String get qrPaymentEpcEmpty => 'Nav atšifrēto lauku';

  @override
  String get qrPaymentOpenInBank => 'Atvērt bankas lietotnē';

  @override
  String get qrPaymentLaunchFailed =>
      'Nav pieejamas lietotnes šī koda atvēršanai';

  @override
  String get qrPaymentUnknownTitle => 'Neatpazīts kods';

  @override
  String get qrPaymentCopyRaw => 'Kopēt neapstrādātu tekstu';

  @override
  String get qrPaymentCopiedRaw => 'Nokopēts starpliktuvē';

  @override
  String get qrPaymentReport => 'Ziņot par šo skenēšanu';

  @override
  String get qrPaymentEpcCopied =>
      'Bankas dati nokopēti — ielīmējiet bankas lietotnē';

  @override
  String get qrScannerGuidance => 'Novirziet kameru uz QR kodu';

  @override
  String get qrScannerPermissionDenied =>
      'Kameras piekļuve ir nepieciešama, lai skenētu QR kodus.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kameras piekļuve tika liegta. Atveriet iestatījumus, lai to piešķirtu.';

  @override
  String get qrScannerRetryPermission => 'Mēģināt vēlreiz';

  @override
  String get qrScannerOpenSettings => 'Atvērt iestatījumus';

  @override
  String get qrScannerTimeout =>
      'QR kods nav atklāts. Tuvieties vai mēģiniet vēlreiz.';

  @override
  String get qrScannerRetry => 'Mēģināt vēlreiz';

  @override
  String get torchOn => 'Ieslēgt zibspuldzi';

  @override
  String get torchOff => 'Izslēgt zibspuldzi';

  @override
  String get obdNoAdapter => 'Nav OBD2 adaptera diapazonā';

  @override
  String get obdOdometerUnavailable => 'Nevarēja nolasīt odometru';

  @override
  String get obdPermissionDenied =>
      'Piešķiriet Bluetooth atļauju sistēmas iestatījumos';

  @override
  String get obdAdapterUnresponsive =>
      'Adapteris neatbildēja — ieslēdziet aizdedzi un mēģiniet vēlreiz';

  @override
  String get obdPickerTitle => 'Izvēlieties OBD2 adapteru';

  @override
  String get obdPickerScanning => 'Meklē adapterus…';

  @override
  String get obdPickerConnecting => 'Savienojas…';

  @override
  String get themeSettingTitle => 'Dizains';

  @override
  String get themeModeLight => 'Gaišs';

  @override
  String get themeModeDark => 'Tumšs';

  @override
  String get themeModeSystem => 'Sekot sistēmai';

  @override
  String get tripRecordingTitle => 'Brauciena ierakstīšana';

  @override
  String get tripSummaryTitle => 'Brauciena kopsavilkums';

  @override
  String get tripMetricDistance => 'Attālums';

  @override
  String get tripMetricSpeed => 'Ātrums';

  @override
  String get tripMetricFuelUsed => 'Patērētā degviela';

  @override
  String get tripMetricAvgConsumption => 'Vid.';

  @override
  String get tripMetricElapsed => 'Pagājušais laiks';

  @override
  String get tripMetricOdometer => 'Odometrs';

  @override
  String get tripStop => 'Apturēt ierakstīšanu';

  @override
  String get tripPause => 'Pauze';

  @override
  String get tripResume => 'Turpināt';

  @override
  String get tripBannerRecording => 'Ieraksta braucienu';

  @override
  String get tripBannerPaused =>
      'Brauciens pauzēts — pieskarieties, lai turpinātu';

  @override
  String get navConsumption => 'Patēriņš';

  @override
  String get vehicleBaselineSectionTitle => 'Bāzlīnijas kalibrēšana';

  @override
  String get vehicleBaselineEmpty =>
      'Vēl nav paraugu — sāciet OBD2 braucienu, lai sāktu apgūt šī transportlīdzekļa degvielas profilu.';

  @override
  String get vehicleBaselineProgress =>
      'Apgūts no paraugiem dažādās braukšanas situācijās.';

  @override
  String get vehicleBaselineReset =>
      'Atiestatīt braukšanas situācijas bāzlīniju';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Atiestatīt braukšanas situācijas bāzlīniju?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Tiks dzēsti visi apgūtie paraugi šim transportlīdzeklim. Līdz jauniem braucieniem atgriezīsies aukstās starta noklusējumi.';

  @override
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapteris';

  @override
  String get vehicleAdapterEmpty =>
      'Nav savienota adaptera. Savienojiet, lai lietotne varētu automātiski atkārtoti savienoties.';

  @override
  String get vehicleAdapterUnnamed => 'Nezināms adapteris';

  @override
  String get vehicleAdapterPair => 'Savienot adapteru';

  @override
  String get vehicleAdapterForget => 'Aizmirst adapteru';

  @override
  String get achievementsTitle => 'Sasniegumi';

  @override
  String get achievementFirstTrip => 'Pirmais brauciens';

  @override
  String get achievementFirstTripDesc => 'Ierakstiet pirmo OBD2 braucienu.';

  @override
  String get achievementFirstFillUp => 'Pirmā uzpilde';

  @override
  String get achievementFirstFillUpDesc => 'Reģistrējiet pirmo uzpildi.';

  @override
  String get achievementTenTrips => '10 braucieni';

  @override
  String get achievementTenTripsDesc => 'Ierakstiet 10 OBD2 braucienus.';

  @override
  String get achievementZeroHarsh => 'Maigs braucējs';

  @override
  String get achievementZeroHarshDesc =>
      'Pabeidziet braucienu vismaz 10 km bez asas bremzēšanas vai paātrinājuma.';

  @override
  String get achievementEcoWeek => 'Eko nedēļa';

  @override
  String get achievementEcoWeekDesc =>
      'Brauciet 7 dienas pēc kārtas ar vismaz vienu maigo braucienu katru dienu.';

  @override
  String get achievementPriceWin => 'Cenas uzvara';

  @override
  String get achievementPriceWinDesc =>
      'Reģistrējiet uzpildi, kas ir par 5 % vai vairāk lētāka nekā stacijas 30 dienu vidējā cena.';

  @override
  String get syncBaselinesToggleTitle =>
      'Kopīgot apgūtos transportlīdzekļu profilus';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Augšupielādēt patēriņa bāzlīnijas katram transportlīdzeklim, lai cita ierīce varētu tās izmantot.';

  @override
  String get obd2StatusConnected => 'OBD2 adapteris: savienots';

  @override
  String get obd2StatusAttempting => 'OBD2 adapteris: savienojas';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapteris: nesasniedzams';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapteris: nepieciešama Bluetooth atļauja';

  @override
  String get obd2StatusConnectedBody => 'Gatavs ierakstīt braucienu.';

  @override
  String get obd2StatusAttemptingBody => 'Savienojas fonā…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapteris ārpus diapazona vai jau tiek izmantots citā lietotnē.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Piešķiriet Bluetooth atļauju sistēmas iestatījumos, lai automātiski atkārtoti savienotos.';

  @override
  String get obd2StatusNoAdapter => 'Nav savienota adaptera';

  @override
  String get obd2StatusForget => 'Aizmirst adapteru';

  @override
  String get tripHistoryTitle => 'Braucienu vēsture';

  @override
  String get tripHistoryEmptyTitle => 'Vēl nav braucienu';

  @override
  String get tripHistoryEmptySubtitle =>
      'Savienojiet OBD2 adapteru un ierakstiet braucienu, lai sāktu veidot braukšanas vēsturi.';

  @override
  String get tripHistoryUnknownDate => 'Nezināms datums';

  @override
  String get situationIdle => 'Dīkstāvē';

  @override
  String get situationStopAndGo => 'Apstāšanās & braukšana';

  @override
  String get situationUrban => 'Pilsētas';

  @override
  String get situationHighway => 'Šosejas';

  @override
  String get situationDecel => 'Palēninot';

  @override
  String get situationClimbing => 'Kāpšana / noslogots';

  @override
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

  @override
  String get situationHardAccel => 'Straujš paātrinājums';

  @override
  String get situationFuelCut => 'Degvielas pārtraukšana — skriešana';

  @override
  String get tripSaveAsFillUp => 'Saglabāt kā uzpildi';

  @override
  String get tripSaveRecording => 'Saglabāt braucienu';

  @override
  String get tripDiscard => 'Atmest';

  @override
  String obdOdometerRead(int km) {
    return 'Odometrs nolasīts: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nav iestatīts';

  @override
  String get wizardVehicleTapToEdit => 'Pieskarieties, lai rediģētu';

  @override
  String get wizardVehicleDefaultBadge => 'Noklusējums';

  @override
  String get wizardProfileChoiceHint =>
      'Izvēlieties, kā vēlaties izmantot lietotni. To varat mainīt vēlāk Iestatījumos.';

  @override
  String get wizardProfileChoiceFooter =>
      'Savu izvēli varat mainīt jebkurā laikā no Iestatījumi → Lietošanas veids.';

  @override
  String get wizardProfileBasicName => 'Pamata';

  @override
  String get wizardProfileBasicDescription =>
      'Lētākās degvielas un EV uzlādes cenas tuvumā. Izlases un cenu brīdinājumi.';

  @override
  String get wizardProfileMediumName => 'Vidējs';

  @override
  String get wizardProfileMediumDescription =>
      'Viss no Pamata, plus izsekot degvielas uzpildes un EV uzlādi manuāli.';

  @override
  String get wizardProfileFullName => 'Pilns';

  @override
  String get wizardProfileFullDescription =>
      'Viss no Vidēja, plus automātiska OBD2 braucienu ierakstīšana, braukšanas novērtējumi un lojalitātes kartes.';

  @override
  String get wizardProfileCustomName => 'Pielāgots';

  @override
  String get wizardProfileCustomDescription =>
      'Jūsu pašu funkciju kombinācija. Pielāgojiet katru slēdzi zemāk.';

  @override
  String get useModeSectionHint =>
      'Pielāgojiet lietotni tam, kā faktiski to izmantojat. Izvēloties sākotnējo iestatījumu, tiek iespējots atbilstošais funkciju kopums.';

  @override
  String get useModeCustomSettingsDescription =>
      'Jūsu funkciju kombinācija neatbilst nevienam sākotnējam iestatījumam. Izvēlieties vienu augstāk, lai pārrakstītu, vai turpiniet pielāgot atsevišķas funkcijas zemāk esošajā sadaļā.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Lietošanas veids iestatīts uz $profile.';
  }

  @override
  String get profileDefaultVehicleLabel =>
      'Noklusējuma transportlīdzeklis (neobligāti)';

  @override
  String get profileDefaultVehicleNone => 'Nav noklusējuma';

  @override
  String get profileFuelFromVehicleHint =>
      'Degvielas veids tiek iegūts no jūsu noklusējuma transportlīdzekļa. Notīriet transportlīdzekli, lai tieši izvēlētos degvielu.';

  @override
  String get consumptionNoVehicleTitle =>
      'Vispirms pievienojiet transportlīdzekli';

  @override
  String get consumptionNoVehicleBody =>
      'Uzpildes tiek attiecinātas uz transportlīdzekli. Pievienojiet savu automašīnu, lai sāktu reģistrēt patēriņu.';

  @override
  String get vehicleAdd => 'Pievienot transportlīdzekli';

  @override
  String get vehicleAddTitle => 'Pievienot transportlīdzekli';

  @override
  String get vehicleEditTitle => 'Rediģēt transportlīdzekli';

  @override
  String get vehicleDeleteTitle => 'Dzēst transportlīdzekli?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Noņemt \"$name\" no jūsu profiliem?';
  }

  @override
  String get vehicleNameLabel => 'Nosaukums';

  @override
  String get vehicleNameHint => 'piem. Mans Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Iekšdedzes';

  @override
  String get vehicleTypeHybrid => 'Hibrīds';

  @override
  String get vehicleTypeEv => 'Elektriskais';

  @override
  String get vehicleEvSectionTitle => 'Elektriskais';

  @override
  String get vehicleCombustionSectionTitle => 'Iekšdedzes';

  @override
  String get vehicleBatteryLabel => 'Akumulatora kapacitāte (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maks. uzlādes jauda (kW)';

  @override
  String get vehicleConnectorsLabel => 'Atbalstītie savienotāji';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Tvertnes kapacitāte (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Vēlamā degviela';

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
  String get connectorThreePin => '3 tapu';

  @override
  String get evShowOnMap => 'Rādīt EV stacijas';

  @override
  String get evAvailableOnly => 'Tikai pieejamās';

  @override
  String get evMinPower => 'Min jauda';

  @override
  String get evMaxPower => 'Maks jauda';

  @override
  String get evOperator => 'Operators';

  @override
  String get evLastUpdate => 'Pēdējā atjaunināšana';

  @override
  String get evStatusAvailable => 'Pieejama';

  @override
  String get evStatusOccupied => 'Aizņemta';

  @override
  String get evStatusOutOfOrder => 'Nedarbojas';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Tikai atvērtās';

  @override
  String get saveAsDefaults => 'Saglabāt kā manus noklusējumus';

  @override
  String get criteriaSavedToProfile => 'Saglabāts kā noklusējums';

  @override
  String get profileNotFound => 'Nav aktīva profila';

  @override
  String get updatingFavorites => 'Atjaunina jūsu izlasi...';

  @override
  String get fetchingLatestPrices => 'Iegūst jaunākās cenas';

  @override
  String get noDataAvailable => 'Nav datu';

  @override
  String get configAndPrivacy => 'Konfigurācija un privātums';

  @override
  String get searchToSeeMap => 'Meklējiet, lai redzētu stacijas kartē';

  @override
  String get evPowerAny => 'Jebkāda';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profils';

  @override
  String get sectionLocation => 'Atrašanās vieta';

  @override
  String get sectionSetupDataSources => 'Setup & data sources';

  @override
  String get sectionFeaturesUsage => 'Features & usage';

  @override
  String get sectionAccountSync => 'Account & sync';

  @override
  String get sectionAppearanceWidgets => 'Appearance & widgets';

  @override
  String get sectionPrivacyData => 'Privacy & data';

  @override
  String get sectionAdvancedDeveloper => 'Advanced & developer';

  @override
  String get tooltipBack => 'Atpakaļ';

  @override
  String get tooltipClose => 'Aizvērt';

  @override
  String get tooltipShare => 'Kopīgot';

  @override
  String get tooltipClearSearch => 'Notīrīt meklēšanu';

  @override
  String get minimalDriveInstantConsumption => 'Momentānais patēriņš';

  @override
  String get coachingShiftUp => 'Pārslēgt augšup';

  @override
  String get coachingShiftDown => 'Pārslēgt lejup';

  @override
  String get coachingEasePedal => 'Atlaid gāzi';

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
  String get voiceCoachingSettingTitle => 'Spoken driving coaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hear spoken tips while you drive — hard acceleration, harsh braking and gear hints';

  @override
  String get tooltipUseGps => 'Izmantot GPS atrašanās vietu';

  @override
  String get tooltipShowPassword => 'Rādīt paroli';

  @override
  String get tooltipHidePassword => 'Slēpt paroli';

  @override
  String get evConnectorsLabel => 'Pieejamie savienotāji';

  @override
  String get evConnectorsNone => 'Nav savienotāja informācijas';

  @override
  String get switchToEmail => 'Pārslēgties uz e-pastu';

  @override
  String get switchToEmailSubtitle =>
      'Saglabāt datus, pievienot pieteikšanos no citām ierīcēm';

  @override
  String get switchToAnonymousAction => 'Pārslēgties uz anonīmu';

  @override
  String get switchToAnonymousSubtitle =>
      'Saglabāt lokālos datus, izmantot jaunu anonīmu sesiju';

  @override
  String get linkDevice => 'Saistīt ierīci';

  @override
  String get shareDatabase => 'Kopīgot datu bāzi';

  @override
  String get disconnectAction => 'Atvienot';

  @override
  String get disconnectSubtitle =>
      'Apturēt sinhronizāciju (lokālie dati saglabāti)';

  @override
  String get deleteAccountAction => 'Dzēst kontu';

  @override
  String get deleteAccountSubtitle =>
      'Neatgriezeniski noņemt visus servera datus';

  @override
  String get localOnly => 'Tikai lokāli';

  @override
  String get localOnlySubtitle =>
      'Neobligāti: sinhronizēt izlases, brīdinājumus un vērtējumus starp ierīcēm';

  @override
  String get setupCloudSync => 'Iestatīt mākoņa sinhronizāciju';

  @override
  String get disconnectTitle => 'Atvienot TankSync?';

  @override
  String get disconnectBody =>
      'Mākoņa sinhronizācija tiks atspējota. Jūsu lokālie dati (izlases, brīdinājumi, vēsture) tiek saglabāti šajā ierīcē. Servera dati netiek dzēsti.';

  @override
  String get deleteAccountTitle => 'Dzēst kontu?';

  @override
  String get deleteAccountBody =>
      'Tiks neatgriezeniski dzēsti visi jūsu dati no servera (izlases, brīdinājumi, vērtējumi, maršruti). Lokālie dati šajā ierīcē tiek saglabāti.\n\nŠo nevar atcelt.';

  @override
  String get switchToAnonymousTitle => 'Pārslēgties uz anonīmu?';

  @override
  String get switchToAnonymousBody =>
      'Jūs tiksiet izrakstīts no sava e-pasta konta un turpināsiet ar jaunu anonīmu sesiju.\n\nJūsu lokālie dati (izlases, brīdinājumi) paliek šajā ierīcē un tiks sinhronizēti ar jauno anonīmo kontu.';

  @override
  String get switchAction => 'Pārslēgt';

  @override
  String get helpBannerCriteria =>
      'Jūsu profila noklusējumi ir iepriekš aizpildīti. Pielāgojiet kritērijus zemāk, lai precizētu meklēšanu.';

  @override
  String get helpBannerAlerts =>
      'Iestatiet cenas slieksni stacijai. Jūs saņemsiet paziņojumu, kad cenas nokritīsies zem tā. Pārbaudes notiek ik 30 minūtes.';

  @override
  String get helpBannerConsumption =>
      'Reģistrējiet katru uzpildi, lai izsekotu reālo patēriņu un CO₂ nospiedumu. Velciet pa kreisi, lai dzēstu ierakstu.';

  @override
  String get helpBannerVehicles =>
      'Pievienojiet savus transportlīdzekļus, lai uzpildes un degvielas preferences tiktu iepriekš aizpildītas pareizi. Pirmais transportlīdzeklis kļūst par noklusējumu.';

  @override
  String get syncNow => 'Sinhronizēt tagad';

  @override
  String get onboardingPreferencesTitle => 'Jūsu preferences';

  @override
  String get onboardingZipHelper => 'Tiek izmantots, ja GPS nav pieejams';

  @override
  String get onboardingRadiusHelper => 'Lielāks rādiuss = vairāk rezultātu';

  @override
  String get onboardingPrivacy =>
      'Šie iestatījumi tiek glabāti tikai jūsu ierīcē un nekad netiek kopīgoti.';

  @override
  String get onboardingLandingTitle => 'Sākuma ekrāns';

  @override
  String get onboardingLandingHint =>
      'Izvēlieties, kurš ekrāns tiek atvērts, palaižot lietotni.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Neejiet prom no lietotnes — bet neslēdziet to.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Atveriet Sparkilo vienu reizi pēc katras pārstartēšanas.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple aktivizē Sparkilo tikai pēc tam, kad esat to atvēris vismaz vienu reizi kopš tālruņa restartēšanas. Pēc tam jūsu braucieni tiek ierakstīti automātiski.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Neizslēdziet Sparkilo lietotņu pārvaldniekā.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Piespiedu slēgšana\" liek iOS apturēt lietotnes palaišanu. Braucieni pārstās ierakstīties, kamēr atkal neatversiet Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Kad iOS jautā par \"Vienmēr\" atrašanās vietu, lūdzu sakiet jā.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Rezerves funkcija, kas ieraksta jūsu braucienu, kad OBD2 adapteris ir lēns, nepieciešama fona atrašanās vieta. Mēs to nekad nekopīgojam.';

  @override
  String get scanReceipt => 'Skenēt čeku';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Degviela';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Autoceļš';

  @override
  String get ratingModeLocal => 'Lokāls';

  @override
  String get ratingModePrivate => 'Privāts';

  @override
  String get ratingModeShared => 'Kopīgots';

  @override
  String get ratingDescLocal => 'Vērtējumi saglabāti tikai šajā ierīcē';

  @override
  String get ratingDescPrivate =>
      'Sinhronizēts ar jūsu datu bāzi (nav redzams citiem)';

  @override
  String get ratingDescShared => 'Redzams visiem jūsu datu bāzes lietotājiem';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API atslēga nav konfigurēta. Pievienojiet vienu Iestatījumos, lai meklētu EV uzlādes stacijas.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Datu sniedzējs ($host) izmanto beidzies vai nederīgs TLS sertifikāts. Lietotne nevar ielādēt datus no šī avota, kamēr sniedzējs to nenovērsīs. Lūdzu, sazinieties ar $host.';
  }

  @override
  String get offlineLabel => 'Bezsaistē';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nav pieejams. Izmanto $current.';
  }

  @override
  String get errorTitleApiKey => 'Nepieciešama API atslēga';

  @override
  String get errorTitleLocation => 'Atrašanās vieta nav pieejama';

  @override
  String get errorHintNoStations =>
      'Mēģiniet palielināt meklēšanas rādiusu vai meklēt citā vietā.';

  @override
  String get errorHintApiKey => 'Konfigurējiet API atslēgu Iestatījumos.';

  @override
  String get errorHintConnection =>
      'Pārbaudiet interneta savienojumu un mēģiniet vēlreiz.';

  @override
  String get errorHintRouting =>
      'Maršruta aprēķins neizdevās. Pārbaudiet interneta savienojumu un mēģiniet vēlreiz.';

  @override
  String get errorHintFallback =>
      'Mēģiniet vēlreiz vai meklējiet pēc pasta indeksa / pilsētas nosaukuma.';

  @override
  String get alertsLoadErrorTitle => 'Nevarēja ielādēt jūsu brīdinājumus';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Brīdinājumu fona pārbaude neizdevās';

  @override
  String get detailsLabel => 'Detaļas';

  @override
  String get remove => 'Noņemt';

  @override
  String get showKey => 'Rādīt atslēgu';

  @override
  String get hideKey => 'Slēpt atslēgu';

  @override
  String get syncOptionalTitle => 'TankSync ir neobligāts';

  @override
  String get syncOptionalDescription =>
      'Jūsu lietotne darbojas pilnībā bez mākoņa sinhronizācijas. TankSync ļauj sinhronizēt izlases, brīdinājumus un vērtējumus starp ierīcēm, izmantojot Supabase (pieejams bezmaksas līmenis).';

  @override
  String get syncHowToConnectQuestion => 'Kā vēlaties savienoties?';

  @override
  String get syncCreateOwnTitle => 'Izveidot savu datu bāzi';

  @override
  String get syncCreateOwnSubtitle =>
      'Bezmaksas Supabase projekts — vadīsim jūs soli pa solim';

  @override
  String get syncJoinExistingTitle => 'Pievienoties esošai datu bāzei';

  @override
  String get syncJoinExistingSubtitle =>
      'Skenējiet QR kodu no datu bāzes īpašnieka vai ielīmējiet akreditācijas datus';

  @override
  String get syncChooseAccountType => 'Izvēlieties konta veidu';

  @override
  String get syncAccountTypeAnonymous => 'Anonīms';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Tūlītēja piekļuve, nav nepieciešams e-pasts. Dati saistīti ar šo ierīci.';

  @override
  String get syncAccountTypeEmail => 'E-pasta konts';

  @override
  String get syncAccountTypeEmailDesc =>
      'Pierakstieties no jebkuras ierīces. Atgūstiet datus, ja tālrunis tiek pazaudēts.';

  @override
  String get syncHaveAccountSignIn => 'Jau ir konts? Pierakstīties';

  @override
  String get syncCreateNewAccount => 'Izveidot jaunu kontu';

  @override
  String get syncTestConnection => 'Pārbaudīt savienojumu';

  @override
  String get syncTestingConnection => 'Pārbauda...';

  @override
  String get syncConnectButton => 'Savienoties';

  @override
  String get syncConnectingButton => 'Savienojas...';

  @override
  String get syncDatabaseReady => 'Datu bāze gatava!';

  @override
  String get syncDatabaseNeedsSetup => 'Datu bāzei nepieciešama iestatīšana';

  @override
  String get syncTableStatusOk => 'Labi';

  @override
  String get syncTableStatusMissing => 'Trūkst';

  @override
  String get syncSqlEditorInstructions =>
      'Kopējiet tālāk esošo SQL un palaidiet to jūsu Supabase SQL redaktorā (Panelis → SQL redaktors → Jauns vaicājums → Ielīmēt → Palaist)';

  @override
  String get syncCopySqlButton => 'Kopēt SQL starpliktuvē';

  @override
  String get syncRecheckSchemaButton => 'Atkārtoti pārbaudīt shēmu';

  @override
  String get syncDoneButton => 'Pabeigts';

  @override
  String syncSignedInAs(String email) {
    return 'Pierakstījies kā $email';
  }

  @override
  String get syncEmailDescription =>
      'Jūsu dati tiek sinhronizēti visās ierīcēs ar šo e-pastu.';

  @override
  String get syncSwitchToAnonymousTitle => 'Pārslēgties uz anonīmu';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Turpināt bez e-pasta, jauna anonīma sesija';

  @override
  String get syncGuestDescription => 'Anonīms, nav nepieciešams e-pasts.';

  @override
  String get syncOrDivider => 'vai';

  @override
  String get syncHowToSyncQuestion => 'Kā vēlaties sinhronizēt?';

  @override
  String get syncOfflineDescription =>
      'Jūsu lietotne darbojas pilnībā bezsaistē. Mākoņa sinhronizācija ir neobligāta.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo kopiena';

  @override
  String get syncModeCommunitySubtitle =>
      'Kopīgot izlases un vērtējumus ar visiem lietotājiem';

  @override
  String get syncModePrivateTitle => 'Privāta datu bāze';

  @override
  String get syncModePrivateSubtitle =>
      'Jūsu pašu Supabase — pilna datu kontrole';

  @override
  String get syncModeGroupTitle => 'Pievienoties grupai';

  @override
  String get syncModeGroupSubtitle => 'Ģimenes vai draugu kopīgā datu bāze';

  @override
  String get syncPrivacyShared => 'Kopīgots';

  @override
  String get syncPrivacyPrivate => 'Privāts';

  @override
  String get syncPrivacyGroup => 'Grupa';

  @override
  String get syncStayOfflineButton => 'Palikt bezsaistē';

  @override
  String get syncSuccessTitle => 'Veiksmīgi savienots!';

  @override
  String get syncSuccessDescription =>
      'Jūsu dati tagad tiks sinhronizēti automātiski.';

  @override
  String get syncWizardTitleConnect => 'Savienot TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Jūsu datu bāze';

  @override
  String get syncSetupTitleJoinGroup => 'Pievienoties grupai';

  @override
  String get syncSetupTitleAccount => 'Jūsu konts';

  @override
  String get syncWizardBack => 'Atpakaļ';

  @override
  String get syncWizardNext => 'Tālāk';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Solis $current no $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Izveidojiet Supabase projektu';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Pieskarieties \"Atvērt Supabase\" zemāk\n2. Izveidojiet bezmaksas kontu (ja tāda nav)\n3. Noklikšķiniet \"Jauns projekts\"\n4. Izvēlieties nosaukumu un reģionu\n5. Uzgaidiet ~2 minūtes, kamēr tas startē';

  @override
  String get syncWizardOpenSupabase => 'Atvērt Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Iespējot anonīmo pierakstīšanos';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Jūsu Supabase panelī:\n   Autentifikācija → Sniedzēji\n2. Atrodiet \"Anonīmā pierakstīšanās\"\n3. Ieslēdziet to\n4. Noklikšķiniet \"Saglabāt\"';

  @override
  String get syncWizardOpenAuthSettings =>
      'Atvērt autentifikācijas iestatījumus';

  @override
  String get syncWizardCopyCredentialsTitle =>
      'Kopējiet savus akreditācijas datus';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Ejiet uz Iestatījumi → API jūsu panelī\n2. Kopējiet \"Projekta URL\"\n3. Kopējiet \"anon public\" atslēgu\n4. Ielīmējiet zemāk';

  @override
  String get syncWizardOpenApiSettings => 'Atvērt API iestatījumus';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Pievienoties esošai datu bāzei';

  @override
  String get syncWizardScanQrCode => 'Skenēt QR kodu';

  @override
  String get syncWizardAskOwnerQr =>
      'Lūdziet datu bāzes īpašniekam parādīt viņa QR kodu\n(Iestatījumi → TankSync → Kopīgot)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Lūdziet datu bāzes īpašniekam parādīt savu QR kodu';

  @override
  String get syncWizardEnterManuallyTitle => 'Ievadīt manuāli';

  @override
  String get syncWizardOrEnterManually => 'vai ievadīt manuāli';

  @override
  String get syncWizardUrlHelperText =>
      'Atstarpes un rindu pārtraukumi tiek noņemti automātiski';

  @override
  String get syncCredentialsPrivateHint =>
      'Ievadiet sava Supabase projekta akreditācijas datus. Tos varat atrast panelī sadaļā Iestatījumi > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Datu bāzes URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Piekļuves atslēga';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-pasts';

  @override
  String get authPasswordLabel => 'Parole';

  @override
  String get authConfirmPasswordLabel => 'Apstiprināt paroli';

  @override
  String get authPleaseEnterEmail => 'Lūdzu, ievadiet savu e-pastu';

  @override
  String get authInvalidEmail => 'Nederīga e-pasta adrese';

  @override
  String get authPasswordsDoNotMatch => 'Paroles nesakrīt';

  @override
  String get authConnectAnonymously => 'Savienoties anonīmi';

  @override
  String get authCreateAccountAndConnect => 'Izveidot kontu un savienoties';

  @override
  String get authSignInAndConnect => 'Pierakstīties un savienoties';

  @override
  String get authAnonymousSegment => 'Anonīms';

  @override
  String get authEmailSegment => 'E-pasts';

  @override
  String get authAnonymousDescription =>
      'Tūlītēja piekļuve, nav nepieciešams e-pasts. Dati saistīti ar šo ierīci.';

  @override
  String get authEmailDescription =>
      'Pierakstieties no jebkuras ierīces. Atgūstiet savus datus, ja tālrunis tiek pazaudēts.';

  @override
  String get authSyncAcrossDevices =>
      'Automātiski sinhronizēt datus visās jūsu ierīcēs.';

  @override
  String get authNewHereCreateAccount => 'Jauns lietotājs? Izveidot kontu';

  @override
  String get linkDeviceScreenTitle => 'Saistīt ierīci';

  @override
  String get linkDeviceThisDeviceLabel => 'Šī ierīce';

  @override
  String get linkDeviceShareCodeHint =>
      'Kopīgojiet šo kodu ar savu citu ierīci:';

  @override
  String get linkDeviceNotConnected => 'Nav savienots';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopēt kodu';

  @override
  String get linkDeviceImportSectionTitle => 'Importēt no citas ierīces';

  @override
  String get linkDeviceImportDescription =>
      'Ievadiet ierīces kodu no savas citas ierīces, lai importētu tās izlases, brīdinājumus, transportlīdzekļus un patēriņa žurnālu. Katra ierīce saglabā savu profilu un noklusējumus.';

  @override
  String get linkDeviceCodeFieldLabel => 'Ierīces kods';

  @override
  String get linkDeviceCodeFieldHint => 'Ielīmējiet UUID no otras ierīces';

  @override
  String get linkDeviceImportButton => 'Importēt datus';

  @override
  String get linkDeviceHowItWorksTitle => 'Kā tas darbojas';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Ierīcē A: kopējiet ierīces kodu augstāk\n2. Ierīcē B: ielīmējiet to laukā \"Ierīces kods\"\n3. Pieskarieties \"Importēt datus\", lai apvienotu izlases, brīdinājumus, transportlīdzekļus un patēriņa žurnālus\n4. Abām ierīcēm būs visi apvienotie dati\n\nKatra ierīce saglabā savu anonīmo identitāti un savu profilu (vēlamā degviela, noklusējuma transportlīdzeklis, sākuma ekrāns). Dati tiek apvienoti, nevis pārvietoti.';

  @override
  String get vehicleSetActive => 'Iestatīt aktīvu';

  @override
  String get swipeHide => 'Slēpt';

  @override
  String get evChargingSection => 'EV uzlāde';

  @override
  String get fuelStationsSection => 'Degvielas stacijas';

  @override
  String get yourRating => 'Jūsu vērtējums';

  @override
  String get noStorageUsed => 'Krātuve netiek izmantota';

  @override
  String get aboutReportBug => 'Ziņot par kļūdu / Ieteikt funkciju';

  @override
  String get aboutSupportProject => 'Atbalstīt šo projektu';

  @override
  String get aboutSupportDescription =>
      'Šī lietotne ir bezmaksas, atvērtā koda un bez reklāmām. Ja tā ir noderīga, apsveriet iespēju atbalstīt izstrādātāju.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luksemburgas degvielas cenas ir valsts regulētas un vienādas visā valstī.';

  @override
  String get luxembourgFuelUnleaded95 => 'Bezsvina 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Bezsvina 98';

  @override
  String get luxembourgFuelDiesel => 'Dīzelis';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luksemburgas regulētās cenas nav pieejamas.';

  @override
  String get reportIssueTitle => 'Ziņot par problēmu';

  @override
  String get enterCorrection => 'Lūdzu, ievadiet labojumu';

  @override
  String get reportNoBackendAvailable =>
      'Ziņojumu nevarēja nosūtīt: šai valstij nav konfigurēts ziņošanas pakalpojums. Iespējojiet TankSync Iestatījumos, lai nosūtītu kopienas ziņojumus.';

  @override
  String get correctName => 'Pareizais stacijas nosaukums';

  @override
  String get correctAddress => 'Pareizā adrese';

  @override
  String get wrongE85Price => 'Nepareiza E85 cena';

  @override
  String get wrongE98Price => 'Nepareiza Super 98 cena';

  @override
  String get wrongLpgPrice => 'Nepareiza LPG cena';

  @override
  String get wrongStationName => 'Nepareizs stacijas nosaukums';

  @override
  String get wrongStationAddress => 'Nepareiza adrese';

  @override
  String get independentStation => 'Neatkarīga stacija';

  @override
  String get serviceRemindersSection => 'Apkopes atgādinājumi';

  @override
  String get serviceRemindersEmpty =>
      'Vēl nav atgādinājumu — izvēlieties sākotnējo iestatījumu augstāk.';

  @override
  String get addServiceReminder => 'Pievienot atgādinājumu';

  @override
  String get serviceReminderPresetOil => 'Eļļa (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Eļļas maiņa';

  @override
  String get serviceReminderPresetTires => 'Riepas (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Riepas';

  @override
  String get serviceReminderPresetInspection => 'Tehniskā apskate (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Tehniskā apskate';

  @override
  String get serviceReminderLabel => 'Apzīmējums';

  @override
  String get serviceReminderInterval => 'Intervāls (km)';

  @override
  String get serviceReminderLastService => 'Pēdējā apkope';

  @override
  String get serviceReminderMarkDone => 'Atzīmēt kā pabeigtu';

  @override
  String get serviceReminderDueTitle => 'Apkopes laiks';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label ir pienācis — $kmOver km pāri intervālam.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Reģistrējieties OPINET, lai iegūtu bezmaksas API atslēgu';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Reģistrējieties CNE, lai iegūtu bezmaksas API atslēgu';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Vai šī ir jūsu automašīna?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders cilindri, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Daļēja informācija (bezsaistē). Varat rediģēt zemāk.';

  @override
  String get vinDecodeError => 'Nevarēja atšifrēt šo VIN';

  @override
  String get vinInvalidFormat => 'Nederīgs VIN formāts';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2 savienojums zaudēts — ierakstīšana apturēta';

  @override
  String get obd2PauseBannerResume => 'Atsākt ierakstīšanu';

  @override
  String get obd2PauseBannerEnd => 'Beigt ierakstīšanu';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Recording with GPS — OBD2 reconnecting';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Recording with GPS — waiting for the OBD2 adapter';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Patēriņa kalibrēšana atjaunināta $vehicleName — precizitāte uzlabojusies par $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Atiestatīt tilpuma efektivitāti?';

  @override
  String get veResetConfirmBody =>
      'Tiks atceltas apgūtās tilpuma efektivitātes (η_v) vērtības un atjaunota noklusējuma vērtība (0.85). Brauciena degvielas plūsmas aprēķini atgriezīsies pie ražotāja konstantes, līdz kalibrētājs savāks jaunus paraugus no nākamajiem braucieniem.';

  @override
  String get alertsStationSectionTitle => 'Station alerts';

  @override
  String get alertsStationAdd => 'Add a station alert';

  @override
  String get alertsRadiusSectionTitle => 'Rādiusa brīdinājumi';

  @override
  String get alertsRadiusAdd => 'Pievienot rādiusa brīdinājumu';

  @override
  String get alertsRadiusEmptyTitle => 'Vēl nav rādiusa brīdinājumu';

  @override
  String get alertsRadiusEmptyCta => 'Izveidot rādiusa brīdinājumu';

  @override
  String get alertsRadiusCreateTitle => 'Izveidot rādiusa brīdinājumu';

  @override
  String get alertsRadiusLabelHint => 'Apzīmējums (piem. Mājas dīzelis)';

  @override
  String get alertsRadiusFuelType => 'Degvielas veids';

  @override
  String get alertsRadiusThreshold => 'Slieksnis (€/L)';

  @override
  String get alertsRadiusKm => 'Rādiuss (km)';

  @override
  String get alertsRadiusCenterGps => 'Izmantot manu atrašanās vietu';

  @override
  String get alertsRadiusCenterPostalCode => 'Pasta indekss';

  @override
  String get alertsRadiusSave => 'Saglabāt';

  @override
  String get alertsRadiusCancel => 'Atcelt';

  @override
  String get alertsRadiusDeleteConfirm => 'Dzēst rādiusa brīdinājumu?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 savienots: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Savienot OBD2 adapteru';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel cena kritās tuvākajās stacijās';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stacijas cena kritās par līdz $maxDropCents¢ pēdējā stundā';
  }

  @override
  String get fillUpSavedSnackbar => 'Uzpilde saglabāta';

  @override
  String get radiusAlertsEntryTitle => 'Rādiusa brīdinājumi un statistika';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Saņemiet paziņojumu, kad cenas krītas jūsu tuvumā';

  @override
  String get notFoundTitle => 'Lapa nav atrasta';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nav atrasts.';
  }

  @override
  String get notFoundHomeButton => 'Sākums';

  @override
  String get consumptionTabHiddenNotice =>
      'Patēriņa cilne ir paslēpta ar jūsu profila iestatījumiem.';

  @override
  String get swipeBetweenTabsHint =>
      'Padoms: velciet pa kreisi vai pa labi, lai pārslēgtos starp cilnēm.';

  @override
  String get discardChangesTitle => 'Atmest izmaiņas?';

  @override
  String get discardChangesBody =>
      'Jums ir nesaglabātas izmaiņas. Atstājot tagad, tās tiks atceltas.';

  @override
  String get discardChangesConfirm => 'Atmest';

  @override
  String get discardChangesKeepEditing => 'Turpināt rediģēt';

  @override
  String get tankSyncSectionSubtitle =>
      'Mākoņa sinhronizācija starp jūsu ierīcēm';

  @override
  String get mapUnavailable => 'Karte nav pieejama';

  @override
  String get routeNameHintExample => 'piem. Parīze → Liona';

  @override
  String get priceStatsCurrent => 'Pašreizējā';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API atslēga';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API atslēga';

  @override
  String get tapToUpdateGpsPosition =>
      'Pieskarieties, lai atjauninātu GPS pozīciju';

  @override
  String get nameLabel => 'Nosaukums';

  @override
  String get obd2ErrorPermissionDenied =>
      'Lai izveidotu savienojumu ar OBD2 adapteri, nepieciešama Bluetooth atļauja.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Ieslēdziet Bluetooth un mēģiniet vēlreiz.';

  @override
  String get obd2ErrorScanTimeout =>
      'Tuvumā nav atrasts OBD2 adapteris. Pārliecinieties, ka tas ir pievienots un ieslēgts.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2 adapteris neatbildēja. Ieslēdziet aizdedzi un mēģiniet vēlreiz.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2 adapteris nosūtīja neatpazītu atbildi. Tas var nebūt saderīgs — izmēģiniet citu adapteri.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2 adapteris atvienojās. Pievienojiet to vēlreiz un mēģiniet vēlreiz.';

  @override
  String get onboardingExploreDemoData => 'Izpētīt ar demonstrācijas datiem';

  @override
  String get achievementSmoothDriver => 'Maigā braukšana sērijā';

  @override
  String get achievementSmoothDriverDesc =>
      'Brauciet 5 braucienus pēc kārtas ar maigās braukšanas novērtējumu 80 vai augstāku.';

  @override
  String get achievementColdStartAware => 'Aukstās starta apzinātājs';

  @override
  String get achievementColdStartAwareDesc =>
      'Uzturiet vesela mēneša aukstās starta degvielas izmaksas zem 2 % no kopējās degvielas — apvienojiet īsos braucienus.';

  @override
  String get achievementHighwayMaster => 'Šosejas meistars';

  @override
  String get achievementHighwayMasterDesc =>
      'Pabeidziet 30 km+ braucienu ar nemainīgu ātrumu un maigās braukšanas novērtējumu 90 vai augstāku.';

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
    return '$price $currency (mērķis: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel kritās tuvumā esošajās stacijās';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count stacijās cena kritās līdz pat $cents¢ pēdējās stundas laikā';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count stacijas ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ vēl $count';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Fona cenu brīdinājumi pašlaik darbojas tikai Vācijas degvielas uzpildes stacijām. Šis brīdinājums tiks saglabāts, taču tas var nekad jūs nebrīdināt, līdz būs pieejami starpvalstu brīdinājumi.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Rādiusa brīdinājumi pašlaik pārbauda tikai Vācijas degvielas uzpildes stacijas.';

  @override
  String get approachOverlaySection =>
      'Pārklājums tuvojoties degvielas uzpildes stacijai';

  @override
  String get approachRadiusLabel => 'Rādiuss';

  @override
  String approachRadiusCaption(String km) {
    return 'Pārklājums palielinās un parāda cenu, kad esat tuvāk par $km km uzpildes stacijai';
  }

  @override
  String get approachPriceModeLabel => 'Rādīt cenu par';

  @override
  String get approachPriceModeNearest => 'Tuvākā stacija';

  @override
  String get approachPriceModeCheapestInRadius => 'Lētākā rādiusā';

  @override
  String get approachMinPollLabel => 'Min. atjaunināšana';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Tuvākās stacijas atjaunināšanas apakšējā robeža (ātrāk ar lielāku ātrumu, nekad biežāk nekā $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testēt tuvošanās pārklājumu';

  @override
  String get approachTestStopButton => 'Apturēt testu';

  @override
  String approachTestActiveCaption(String station) {
    return 'Tests aktīvs — pārklājums rāda cenu stacijai $station';
  }

  @override
  String get approachTestUnavailable =>
      'Pievienojiet iecienītāko staciju, lai testētu tuvošanās pārklājumu';

  @override
  String approachStationDistance(String meters) {
    return '$meters m attālumā';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return '$km km away';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximity $percent%';
  }

  @override
  String get authErrorNoNetwork => 'Nav tīkla savienojuma. Mēģiniet vēlāk.';

  @override
  String get authErrorInvalidCredentials =>
      'Nepareizs e-pasts vai parole. Pārbaudiet savus akreditācijas datus.';

  @override
  String get authErrorUserAlreadyExists =>
      'Šis e-pasts jau ir reģistrēts. Mēģiniet pierakstīties.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Lūdzu, pārbaudiet savu e-pastu un vispirms apstipriniet savu kontu.';

  @override
  String get authErrorGeneric =>
      'Pierakstīšanās neizdevās. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Fona atrašanās vieta — tikai automātiskai ierakstīšanai';

  @override
  String get autoRecordConsentExplanationTitle => 'Par šo atļauju';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automātiskajai ierakstīšanai nepieciešama fona atrašanās vieta, lai noteiktu, kad sākat braukt, kamēr lietotne ir aizvērta. Šī atļauja tiek izmantota tikai automātiskajai ierakstīšanai — staciju meklēšana un kartes centrēšana izmanto atsevišķu priekšplāna atrašanās vietas atļauju.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Sapratu';

  @override
  String get autoRecordConsentExplanationTooltip => 'Ko tas nozīmē?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Pieskarieties, lai pārvaldītu sistēmas iestatījumos';

  @override
  String get autoRecordSectionTitle => 'Automātiskā ierakstīšana';

  @override
  String get autoRecordToggleLabel => 'Automātiski ierakstīt braucienus';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automātiskā ierakstīšana aktivizēsies nākamreiz, kad iesēsieties automašīnā.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Savienojiet OBD2 adapteru, lai iespējotu automātisko ierakstīšanu.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Atļaujiet fona atrašanās vietu, lai automātiskā ierakstīšana turpinātu darboties ar izslēgtu ekrānu.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Savienot adapteru';

  @override
  String get autoRecordSpeedThresholdLabel => 'Starta ātrums (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Saglabāšanas aizkave pēc atvienošanas (sekundes)';

  @override
  String get autoRecordPairedAdapterLabel => 'Savienotais adapteris';

  @override
  String get autoRecordPairedAdapterNone =>
      'Nav savienota adaptera. Vispirms savienojiet caur OBD2 iestatīšanu.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Fona atrašanās vieta atļauta';

  @override
  String get autoRecordBackgroundLocationRequest => 'Pieprasīt atļauju';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Kāpēc \"Vienmēr atļaut\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automātiskā ierakstīšana straumē GPS koordinātas no OBD-II priekšplāna pakalpojuma, kad ekrāns ir izslēgts, lai jūsu brauciena maršruts paliek precīzs. Android prasa opciju \"Vienmēr atļaut\", lai tas turpinātu darboties pēc ierīces bloķēšanas.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Atvērt iestatījumus';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Nepieciešama atrašanās vietas atļauja';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nevarēja pieprasīt fona atrašanās vietu';

  @override
  String get autoRecordBadgeClearTooltip => 'Notīrīt skaitītāju';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Savienojiet adapteru zemāk esošajā sadaļā, lai iespējotu automātisko ierakstīšanu';

  @override
  String get exportBackupTooltip => 'Eksportēt rezerves kopiju';

  @override
  String get exportBackupReady =>
      'Rezerves kopija gatava — izvēlieties galamērķi';

  @override
  String get exportBackupFailed =>
      'Rezerves kopijas eksports neizdevās — lūdzu, mēģiniet vēlreiz';

  @override
  String get backupExportProgress => 'Exporting your backup…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Saved to Downloads as $fileName';
  }

  @override
  String get restoreBackupTooltip => 'Restore backup';

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
  String restoreBackupSuccess(int count) {
    return 'Backup restored — $count records imported';
  }

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
  String get brokenMapChipVerifying => 'MAP sensors tiek verificēts…';

  @override
  String get brokenMapChipDisclaimer => 'MAP rādījumi ir aizdomīgi';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP sensors rāda nepareizi — degvielas rādījumi var būt par 50–80% par zemu. Mēģiniet ar citu adapteru.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP sensors neuzticams. Rāda uzpildes vidējos rādījumus, nevis reāllaika degvielas patēriņu.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP sensors: verificēts ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP sensors: verificē ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP sensors: aizdomīgs ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP sensors: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP sensors: $posterior% ± $margin% (verificēts)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP sensora diagnostika';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Bojāta MAP ticamība: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count novērojumi reģistrēti';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge =>
      'Verificēts kā darboties spējīgs';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Šī transportlīdzekļa MAP sensors vēl nav novērots.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Bloķēto sarakstā esošie adapteri';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Nav bloķētu adapteru.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — atzīmēts $percent% bojāts';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Notīrīt';

  @override
  String get brokenMapRevPromptTitle => 'Pagrieziet motoru';

  @override
  String get brokenMapRevPromptBody =>
      'Īsi paspiediet gāzi, lai lietotne varētu pārbaudīt, vai MAP sensors reaģē.';

  @override
  String get brokenMapRevPromptConfirm => 'Gatavs — pagriežu';

  @override
  String get calibrationAdvancedTitle => 'Uzlabotā kalibrēšana';

  @override
  String get calibrationDisplacementLabel => 'Motora tilpums (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Tilpuma efektivitāte (η_v)';

  @override
  String get calibrationAfrLabel => 'Gaisa un degvielas attiecība (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Degvielas blīvums (g/L)';

  @override
  String get calibrationSourceDetected => '(noteikts no VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalogs: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(noklusējums)';

  @override
  String get calibrationSourceManual => '(manuāls)';

  @override
  String get calibrationResetToDetected => 'Atiestatīt uz noteikto vērtību';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrēts, $samples paraugi)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (mācoties, $samples paraugi)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (noklusējums — vēl nav pilnas uzpildes)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples paraugi';
  }

  @override
  String get calibrationResetLearner => 'Atiestatīt mācīšanos';

  @override
  String get calibrationBasisAtkinson => 'Atkinson cikls';

  @override
  String get calibrationBasisVnt => 'VNT dīzelis + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbodzelzceļš + DI';

  @override
  String get calibrationBasisTurbo => 'Turbodzelzceļš';

  @override
  String get calibrationBasisNaDi => 'Dabiskais aspirācijas + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalogs: $makeModel — $basis noklusējums)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Jūsu $makeModel ir atzīmēts kā dīzelis, bet atbilst benzīna kataloga ierakstam. Pieskarieties, lai atjauninātu.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Atjaunināt';

  @override
  String get consumptionTabFuel => 'Degviela';

  @override
  String get consumptionTabCharging => 'Uzlāde';

  @override
  String get noChargingLogsTitle => 'Vēl nav uzlādes žurnālu';

  @override
  String get noChargingLogsSubtitle =>
      'Reģistrējiet pirmo uzlādes sesiju, lai sāktu izsekot EUR/100 km un kWh/100 km.';

  @override
  String get addChargingLog => 'Reģistrēt uzlādi';

  @override
  String get addChargingLogTitle => 'Reģistrēt uzlādes sesiju';

  @override
  String get chargingKwh => 'Enerģija (kWh)';

  @override
  String get chargingCost => 'Kopējās izmaksas';

  @override
  String get chargingTimeMin => 'Uzlādes laiks (min)';

  @override
  String get chargingStationName => 'Stacija (neobligāti)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper =>
      'Nepieciešams iepriekšējs žurnāls salīdzināšanai';

  @override
  String get chargingLogButtonLabel => 'Reģistrēt uzlādi';

  @override
  String get chargingCostTrendTitle => 'Uzlādes izmaksu tendence';

  @override
  String get chargingEfficiencyTitle => 'Efektivitāte (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Vēl nav pietiekami datu';

  @override
  String get chargingChartsMonthAxis => 'Mēnesis';

  @override
  String get consoFeatureGroupTitle => 'Patēriņš';

  @override
  String get consoFeatureGroupDescription =>
      'Izsekot patēriņu — manuālas uzpildes vai automātiska OBD2 braucienu ierakstīšana.';

  @override
  String get consoModeOff => 'Izslēgts';

  @override
  String get consoModeFuel => 'Degviela';

  @override
  String get consoModeFuelAndTrips => 'Degviela + Braucieni';

  @override
  String get consoModeOffDescription =>
      'Nav Patēriņa cilnes un nav Patēriņa iestatījumu sadaļas.';

  @override
  String get consoModeFuelDescription =>
      'Tikai manuālas uzpildes. Noderīgi bez OBD2 adaptera.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Pievieno automātisku OBD2 braucienu ierakstīšanu. Nepieciešams savienots adapteris.';

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
    return 'Precizitāte: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Augsta';

  @override
  String get consumptionAccuracyMedium => 'Vidēja';

  @override
  String get consumptionAccuracyLow => 'Zema';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Pilna kalibrēšana: uzpildes plus ar OBD2 ierakstīti braucieni. L/100 km rādītājs atbilst realitātei dažu procentu robežās.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Uzpildes ir nostiprinājušas patēriņa modeli, taču neviens OBD2 brauciens vēl nav apstrādāts. Ierakstiet vienu ar pievienotu OBD2, lai sasniegtu augstu precizitāti.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Tikai GPS — neviena uzpilde vēl nav nostiprinājusi patēriņa modeli. Pievienojiet dažas pilnas uzpildes, lai uzlabotu precizitāti.';

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
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count daļējas uzpildes gaida pilno uzpildi — nav vidējā rādījumā',
      one: '1 daļēja uzpilde gaida pilno uzpildi — nav vidējā rādījumā',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% degvielas no automātiskiem labojumiem — pārskatiet ierakstus';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Automātisks labojums — pieskarieties, lai rediģētu';

  @override
  String get fillUpCorrectionEditTitle => 'Rediģēt automātisko labojumu';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Šis ieraksts tika automātiski ģenerēts, lai aizpildītu plaisu starp ierakstītajiem braucieniem un iepildīto degvielu. Pielāgojiet vērtības, ja zināt faktiskos skaitļus.';

  @override
  String get fillUpCorrectionDelete => 'Dzēst labojumu';

  @override
  String get fillUpCorrectionStation => 'Stacijas nosaukums (neobligāti)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grieķija)';

  @override
  String get greeceCommunityApiNotice =>
      'Nodrošina kopienas uzturēta fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumānija)';

  @override
  String get romaniaScrapingNotice =>
      'Nodrošina pretcarburant.ro (Konkurences padome + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country stacijas $km km tālāk — €$price/L lētāk';
  }

  @override
  String get crossBorderTapToSwitch => 'Pieskarieties, lai mainītu valsti';

  @override
  String get crossBorderDismissTooltip => 'Aizvērt';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Izstrādātāja rīki';

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
      'Diagnostika un atkļūdošanas rīki — redzami tikai izstrādātāja/atkļūdošanas režīmā.';

  @override
  String get developerToolsMenuSubtitle =>
      'Kļūdu žurnāls, testa brīdinājumi, diagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Kļūdu žurnāls';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Saglabāt kļūdu žurnālu ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Notīrīt kļūdu žurnālu';

  @override
  String get developerToolsViewErrorLog => 'Skatīt kļūdu žurnālu';

  @override
  String get developerToolsErrorLogEmpty => 'Nav reģistrētu kļūdu pēdu.';

  @override
  String get developerToolsAlertsGroupTitle => 'Brīdinājumi un paziņojumi';

  @override
  String get developerToolsFireTestNotification => 'Sūtīt testa paziņojumu';

  @override
  String get developerToolsTestNotificationTitle => 'Testa paziņojums';

  @override
  String get developerToolsTestNotificationBody =>
      'Ja jūs to varat izlasīt, paziņojumi darbojas.';

  @override
  String get developerToolsTestNotificationSent => 'Testa paziņojums nosūtīts.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Paziņojumi ir bloķēti — iespējojiet tos sistēmas iestatījumos un mēģiniet vēlreiz.';

  @override
  String get developerToolsRunTestAlert => 'Palaist testa brīdinājumu plūsmu';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testa brīdinājums aktivizēts — plūsma piegādāja $count paziņojumus.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testa cenas brīdinājums';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Sintētiska atbilstība: tuvumā tika atrasta stacija zem jūsu mērķa.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostika';

  @override
  String get developerToolsFeatureFlagDump => 'Funkciju karodziņu inspektors';

  @override
  String get developerToolsFlagOn => 'Ieslēgts';

  @override
  String get developerToolsFlagOff => 'Izslēgts';

  @override
  String get developerToolsClearCaches => 'Notīrīt kešatmiņas';

  @override
  String get developerToolsCachesCleared => 'Kešatmiņas notīrītas.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopēt diagnostiku';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostika nokopēta starpliktuvē.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Būvējuma informācija';

  @override
  String get developerToolsBuildVersion => 'Lietotnes versija';

  @override
  String get developerToolsBuildChannel => 'Būvējuma kanāls';

  @override
  String get insightCardTitle => 'Galvenie izšķērdīgākie paradumi';

  @override
  String get insightEmptyState =>
      'Neievērojamas neefektivitātes — turpiniet tā!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Dzinējs virs 3000 RPM ($pctTime% no brauciena): iztērēts $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count straujie paātrinājumi: iztērēts $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Dīkstāvē ($pctTime% no brauciena): iztērēts $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% no brauciena';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Braukšana zemā pārnesumā ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Garās apstāšanās reizēs izslēdziet dzinēju, nevis ļaujiet tam darboties tukšgaitā.';

  @override
  String get lessonAdviceHighRpm =>
      'Pārslēdziet augstāku pārnesumu agrāk, lai dzinējs nebūtu augsto apgriezienu zonā.';

  @override
  String get lessonAdviceHardAccel =>
      'Spiediet gāzi vienmērīgi — gluda paātrināšanās patērē mazāk degvielas.';

  @override
  String get lessonAdviceLowGear =>
      'Pārslēdziet augstāku pārnesumu agrāk, lai dzinējs darbotos zemākos un ekonomiskākos apgriezienos.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Ilgstoši augsts ātrums ($pctTime% no brauciena): izšķērdēti $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Ilgstoši augsts ātrums ($pctTime% no brauciena)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Virs 110 km/h atlaidiet gāzi – gaisa pretestība strauji pieaug, nedaudz lēnāk ietaupa daudz degvielas.';

  @override
  String get lessonSmoothDrivingTitle => 'Vienmērīga braukšana – lieliski!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Šajā braucienā nebija strauja paātrinājuma vai bremzēšanas – vienmērīga braukšana uztur zemu patēriņu.';

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
  String get drivingScoreCardTitle => 'Braukšanas novērtējums';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Kompozīts novērtējums no dīkstāves, straujo paātrinājumu, asas bremzēšanas un augsta RPM laika. Salīdzinājums \"labāks par X% no iepriekšējiem braucieniem\" nāks nākamajā laidienā.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Braukšanas novērtējums $score no 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Dīkstāvē';

  @override
  String get drivingScorePenaltyHardAccel => 'Straujie paātrinājumi';

  @override
  String get drivingScorePenaltyHardBrake => 'Asā bremzēšana';

  @override
  String get drivingScorePenaltyHighRpm => 'Augsts RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Pilna gāze';

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
  String get ecoRouteOption => 'Eko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L ietaupīts';
  }

  @override
  String get ecoRouteHint =>
      'Gudrāks brauciens — dod priekšroku vienmērīgam šosejas braucienam nevis izlocītiem saīsinājumiem.';

  @override
  String get favoritesShareAction => 'Kopīgot';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — izlase $date';
  }

  @override
  String get favoritesShareError => 'Nevarēja ģenerēt kopīgošanas attēlu';

  @override
  String get featureManagementSectionTitle => 'Funkciju pārvaldība';

  @override
  String get featureManagementSectionSubtitle =>
      'Ieslēgt vai izslēgt atsevišķas funkcijas. Dažas funkcijas ir atkarīgas no citām — slēdži ir atspējoti, kamēr priekšnoteikumi nav izpildīti.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2 braucienu ierakstīšana';

  @override
  String get featureDescription_obd2TripRecording =>
      'Automātiski ierakstīt braucienus caur OBD2.';

  @override
  String get featureLabel_gamification => 'Spēlifikācija';

  @override
  String get featureDescription_gamification =>
      'Braukšanas novērtējumi un nopelnītās zīmotnes.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptiskais eko treneris';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Reāllaika haptiskā atgriezeniskā saite brauciena laikā.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Starpierīču sinhronizācija caur Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Patēriņa analītika';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Uzpilžu un braucienu analīzes cilne.';

  @override
  String get featureLabel_baselineSync => 'Bāzlīnijas sinhronizācija';

  @override
  String get featureDescription_baselineSync =>
      'Sinhronizēt braukšanas bāzlīnijas caur TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Vienotie meklēšanas rezultāti';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Viens rezultātu saraksts, kas apvieno degvielas un EV stacijas.';

  @override
  String get featureLabel_priceAlerts => 'Cenu brīdinājumi';

  @override
  String get featureDescription_priceAlerts =>
      'Paziņojumi par cenu kritumu pēc sliekšņa.';

  @override
  String get featureLabel_priceHistory => 'Cenu vēsture';

  @override
  String get featureDescription_priceHistory =>
      '30 dienu cenu diagrammas stacijas detaļās.';

  @override
  String get featureLabel_routePlanning => 'Maršruta plānošana';

  @override
  String get featureDescription_routePlanning =>
      'Lētākā pietura gar jūsu maršrutu.';

  @override
  String get featureLabel_evCharging => 'EV uzlāde';

  @override
  String get featureDescription_evCharging =>
      'Uzlādes stacijas caur OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Slīdēšanas treneris';

  @override
  String get featureDescription_glideCoach =>
      'Hipermīlēšanas vadība, izmantojot OSM satiksmes signālus.';

  @override
  String get featureLabel_gpsTripPath => 'GPS brauciena ceļš';

  @override
  String get featureDescription_gpsTripPath =>
      'Saglabāt GPS ceļa paraugus kopā ar katru braucienu.';

  @override
  String get featureLabel_autoRecord => 'Automātiskā ierakstīšana';

  @override
  String get featureDescription_autoRecord =>
      'Automātiski sākt braucienu, kad OBD2 adapteris savienojas ar kustībā esošu transportlīdzekli.';

  @override
  String get featureLabel_showFuel => 'Rādīt degvielas stacijas';

  @override
  String get featureDescription_showFuel =>
      'Rādīt benzīna/dīzeļa staciju rezultātus meklēšanā un kartē.';

  @override
  String get featureLabel_showElectric => 'Rādīt uzlādes stacijas';

  @override
  String get featureDescription_showElectric =>
      'Rādīt EV uzlādes stacijas meklēšanā un kartē.';

  @override
  String get featureLabel_showConsumptionTab => 'Patēriņa cilne';

  @override
  String get featureDescription_showConsumptionTab =>
      'Rādīt patēriņa analītikas cilni apakšējā navigācijā.';

  @override
  String get featureBlockedEnable_gamification =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureBlockedEnable_baselineSync =>
      'Vispirms iespējojiet TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureBlockedEnable_showFuel => 'Priekšnoteikumi nav izpildīti';

  @override
  String get featureBlockedEnable_showElectric =>
      'Priekšnoteikumi nav izpildīti';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite cenu prognozēšana';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Cenu prognozēšanas modelis ierīcē — secinājumi tiek veikti lokāli; pazīmes un prognozes nekad neatstāj ierīci.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Vispirms iespējojiet cenu vēsturi';

  @override
  String get featureLabel_fuelCalculator => 'Degvielas kalkulators';

  @override
  String get featureDescription_fuelCalculator =>
      'Sasniedzamais degvielas izmaksu kalkulators no meklēšanas rezultātiem.';

  @override
  String get featureLabel_carbonDashboard => 'Oglekļa panelis';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2 nospieduma panelis, kas pieejams no Patēriņa cilnes.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentālie OEM PID';

  @override
  String get featureDescription_experimentalOemPids =>
      'Nolasīt precīzu tvertnes litru daudzumu, izmantojot ražotājam specifiskus PID uz atbalstītiem adapteriem.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Vispirms iespējojiet OBD2 braucienu ierakstīšanu';

  @override
  String get featureLabel_paymentQrScan => 'Skenēt maksājuma QR';

  @override
  String get featureDescription_paymentQrScan =>
      'Skenēšana-maksāšanai QR lasītājs stacijas detaļu ekrānā.';

  @override
  String get featureLabel_communityPriceReports => 'Kopienas cenu ziņojumi';

  @override
  String get featureDescription_communityPriceReports =>
      'Ziņot par stacijas cenu no stacijas detaļu ekrāna.';

  @override
  String get featureLabel_obd2Optional =>
      'Pieprasīt OBD2 braucienu ierakstīšanai';

  @override
  String get featureDescription_obd2Optional =>
      'Kad izslēgts, lietotne ieraksta braucienus tikai ar GPS bez OBD2 adaptera. Treniņš ir ierobežots — nav momentānā L/100 km, mazāk dzinēja signālu.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Čeka OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skenējiet izdrukāto čeku ekrānā Pievienot uzpildi, lai iepriekš aizpildītu datumu, litrus, summu un staciju.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'Sūkņa displeja OCR (eksperimentāls)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Skenējiet degvielas sūkņa displeju, lai iepriekš aizpildītu veidlapu. Atpazīšana šodien nav uzticama — ieslēdziet tikai tad, ja vēlaties pārbaudīt.';

  @override
  String get featureLabel_developerPatToken =>
      'Izstrādātāja atsauksmes (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Iespējo neveiksmīgu skenējumu atsauksmju paneli, kas ar Personal Access Token automātiski izveido GitHub problēmas. Pieredzējušu lietotāju / līdzdalībnieku funkcija.';

  @override
  String get featureLabel_debugMode => 'Izstrādātāja/atkļūdošanas režīms';

  @override
  String get featureDescription_debugMode =>
      'Iestatījumos parāda sadaļu Izstrādātāja rīki ar diagnostiku: kļūdu žurnāla eksports, testa paziņojumi, testa brīdinājumu plūsmas palaišana, funkciju karodziņu saraksts, kešatmiņu notīrīšana un diagnostikas kopēšana.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get featureLabel_voiceAnnouncements => 'Voice announcements';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Speak nearby cheap fuel stations aloud as you drive, so you can keep your eyes on the road.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Enable the approach overlay first';

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
  String get feedbackConsentTitle => 'Nosūtīt ziņojumu uz GitHub?';

  @override
  String get feedbackConsentBody =>
      'Tiks izveidota publiska biļete mūsu GitHub repozitorijā ar jūsu fotoattēlu un OCR tekstu. Tiek sūtīti nav nekādi personas dati (atrašanās vieta, konta ID). Turpināt?';

  @override
  String get feedbackConsentContinue => 'Turpināt';

  @override
  String get feedbackConsentCancel => 'Atcelt';

  @override
  String get feedbackConsentLater => 'Vēlāk';

  @override
  String get feedbackTokenSectionTitle =>
      'Sliktas skenēšanas atsauksmes (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Lai automātiski atvērtu GitHub biļeti no neveiksmīgas skenēšanas, ielīmējiet GitHub PAT (`public_repo` darbības joma uz tankstellen repozitoriju). Pretējā gadījumā manuālā kopīgošana joprojām ir pieejama.';

  @override
  String get feedbackTokenStatusSet => 'Marķieris konfigurēts';

  @override
  String get feedbackTokenStatusUnset => 'Nav marķiera';

  @override
  String get feedbackTokenSet => 'Iestatīt';

  @override
  String get feedbackTokenClear => 'Notīrīt';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personīgās piekļuves marķieris';

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
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verificēts ar adapteru';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Nesakrīt ar adaptera rādījumu';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Jūsu ieraksts: $userL L. Adapteris rāda: $adapterL L (starpība no pirms/pēc degvielas līmeņa uztveršanas). Izmantot adaptera vērtību?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Paturēt manu ierakstu';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Izmantot adaptera vērtību';

  @override
  String get scanReceiptNoData => 'Nav atrasti čeka dati — mēģiniet vēlreiz';

  @override
  String get scanReceiptSuccess =>
      'Čeks skenēts — pārbaudiet vērtības. Pieskarieties \"Ziņot par skenēšanas kļūdu\" zemāk, ja kaut kas nav pareizi.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skenēšana neizdevās: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Sūkņa displejs nav lasāms — mēģiniet vēlreiz';

  @override
  String get scanPumpSuccess => 'Sūkņa displejs skenēts — pārbaudiet vērtības.';

  @override
  String get scanPumpGlare =>
      'Pārāk daudz atspīduma uz displeja — mēģiniet vēlreiz nelielā leņķī, lai cipari nebūtu pārgaismoti.';

  @override
  String get scanPumpInconsistent =>
      'The scanned values don\'t add up — please enter them manually.';

  @override
  String scanPumpFailed(String error) {
    return 'Sūkņa skenēšana neizdevās: $error';
  }

  @override
  String get badScanReportTitle => 'Ziņot par skenēšanas kļūdu';

  @override
  String get badScanReportTitleReceipt => 'Ziņot par skenēšanas kļūdu — čeks';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Ziņot par skenēšanas kļūdu — sūkņa displejs';

  @override
  String get pumpScanFailureTitle => 'Displejs nav lasāms';

  @override
  String get pumpScanFailureBody =>
      'Skenēšana nevarēja nolasīt sūkņa displeju. Ko vēlaties darīt?';

  @override
  String get pumpScanFailureCorrectManually => 'Labot manuāli';

  @override
  String get pumpScanFailureReport => 'Ziņot';

  @override
  String get pumpScanFailureRemove => 'Noņemt fotoattēlu';

  @override
  String get badScanReportHint =>
      'Mēs kopīgosim čeka fotoattēlu un abas vērtību kopas, lai nākamā versija varētu apgūt šo izkārtojumu.';

  @override
  String get badScanReportShareAction => 'Kopīgot ziņojumu + fotoattēlu';

  @override
  String get badScanReportFieldBrandLayout => 'Zīmola izkārtojums';

  @override
  String get badScanReportFieldTotal => 'Kopā';

  @override
  String get badScanReportFieldPricePerLiter => 'Cena/L';

  @override
  String get badScanReportFieldStation => 'Stacija';

  @override
  String get badScanReportFieldFuel => 'Degviela';

  @override
  String get badScanReportFieldDate => 'Datums';

  @override
  String get badScanReportHeaderField => 'Lauks';

  @override
  String get badScanReportHeaderScanned => 'Skenēts';

  @override
  String get badScanReportHeaderYouTyped => 'Jūs ievadījāt';

  @override
  String get badScanReportCreateTicket => 'Izveidot biļeti';

  @override
  String get badScanReportOpenInBrowser => 'Atvērt pārlūkprogrammā';

  @override
  String get badScanReportFallbackToShare =>
      'Iesniegšana neizdevās — manuāla kopīgošana';

  @override
  String get pumpCameraHint =>
      'Salāgojiet trīs degvielas uzpildes ekrāna ciparus rāmī';

  @override
  String get pumpCameraCapture => 'Uzņemt';

  @override
  String get pumpCameraPermissionDenied =>
      'Lai skenētu uzpildes ekrānu, nepieciešama piekļuve kamerai. Iespējojiet to ierīces iestatījumos.';

  @override
  String get pumpCameraError =>
      'Kameru neizdevās palaist. Mēģiniet vēlreiz vai ievadiet vērtības manuāli.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Pārslēgties uz horizontālo izkārtojumu';

  @override
  String get pumpCameraOrientationVertical =>
      'Pārslēgties uz vertikālo izkārtojumu';

  @override
  String get pumpCameraGlareWarning =>
      'Pārāk daudz atspulgu — nedaudz nolieciet, lai izvairītos no atspīdumiem';

  @override
  String get pumpCameraAlignHint =>
      'Novietojiet displeju rāmītī un pēc tam fotografējiet';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

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
  String get fillUpSectionWhatTitle => 'Ko jūs uzpildījāt';

  @override
  String get fillUpSectionWhatSubtitle => 'Degviela, daudzums, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kur jūs bijāt';

  @override
  String get fillUpSectionWhereSubtitle => 'Stacija, odometrs, piezīmes';

  @override
  String get fillUpImportFromLabel => 'Importēt no…';

  @override
  String get fillUpImportSheetTitle => 'Importēt uzpildes datus';

  @override
  String get fillUpImportReceiptLabel => 'Čeks';

  @override
  String get fillUpImportReceiptDescription => 'Skenēt papīra čeku ar kameru';

  @override
  String get fillUpImportPumpLabel => 'Sūkņa displejs';

  @override
  String get fillUpImportPumpDescription =>
      'Nolasīt summu / cenu no sūkņa LCD displeja';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapteris';

  @override
  String get fillUpImportObdDescription =>
      'Nolasīt odometru no OBD-II porta caur Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Cena par litru';

  @override
  String get vehicleHeaderPlateLabel => 'Numura zīme';

  @override
  String get vehicleHeaderUntitled => 'Jauns transportlīdzeklis';

  @override
  String get vehicleSectionIdentityTitle => 'Identitāte';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nosaukums un VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Transmisija';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Kā šis transportlīdzeklis pārvietojas';

  @override
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get calibrationModeLabel => 'Kalibrēšanas režīms';

  @override
  String get calibrationModeRule => 'Uz noteikumiem balstīts';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Uz noteikumiem balstīts piešķir katru braukšanas paraugu tieši vienai situācijai. Fuzzy to izplata starp visām pēc atbilstības — gludāk ap 60 km/h vai mainīgiem slīpumiem, bet lēnāk aizpilda visus grozus.';

  @override
  String get profileGamificationToggleTitle => 'Rādīt sasniegumus un punktus';

  @override
  String get profileGamificationToggleSubtitle =>
      'Kad izslēgts, visā lietotnē tiek paslēptas zīmotnes, novērtējumi un trofeju ikonas.';

  @override
  String get coachingGpsLiftOff => 'Atlaid gāzi';

  @override
  String get coachingGpsAnticipateBrake => 'Paredzi';

  @override
  String get coachingGpsSmoothAccel => 'Vienmērīga paātrināšana';

  @override
  String get gpsDiagnosticsTitle => 'GPS paraugu ņemšanas diagnostika';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps atstarpēs',
      one: '1 atstarpē',
      zero: 'bez atstarpēm',
    );
    return '$count paraugi · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Vidējais intervāls: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Uztverts ierakstīšanas laikā, lai verificētu GPS kadenci tālruņa miega laikā.';

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
  String get gpsMatrixMaturityCold => 'Auksta';

  @override
  String get gpsMatrixMaturityWarming => 'Sasilst';

  @override
  String get gpsMatrixMaturityConverged => 'Konverģējusi';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS matrica vēl sasilst ($count pielāgojumi līdz šim). Aplēses ir provizoriskas.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS matrica konverģē ($count uzpildes). Aplēses ir lietojamas, var atšķirties par dažiem %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS matrica ir konverģējusi ($count uzpildes). Aplēses ~2 % robežās no faktiskā patēriņa.';
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
  String get hapticEcoCoachSectionTitle => 'Braukšana';

  @override
  String get hapticEcoCoachSettingTitle => 'Reāllaika eko trenēšana';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Maiga haptika + ekrāna padoms, kad pilnībā spiedat gāzi kruīza laikā';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Uzmanīgi ar gāzi — skriešana ietaupa vairāk';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigēt uz $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Noņemt $name no izlases';
  }

  @override
  String get showOnMapSemanticLabel => 'Rādīt stacijas kartē';

  @override
  String get searchResultsSemanticLabel => 'Meklēšanas rezultāti';

  @override
  String get searchCriteriaSemanticLabel =>
      'Meklēšanas kritēriju kopsavilkums. Pieskarieties, lai rediģētu.';

  @override
  String get noFavoritesSemanticLabel =>
      'Vēl nav izlases. Pieskarieties stacijas zvaigznītei, lai saglabātu to izlasē.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stacija ir atvērta',
      'false': 'Stacija ir slēgta',
      'other': 'Stacija ir slēgta',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Valsts $name, atlasīta',
      'false': 'Valsts $name',
      'other': 'Valsts $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Valoda $name, atlasīts',
      'false': 'Valoda $name',
      'other': 'Valoda $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Kārtot pēc $option, atlasīts',
      'false': 'Kārtot pēc $option',
      'other': 'Kārtot pēc $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Degviela $type, atlasīta',
      'false': 'Degviela $type',
      'other': 'Degviela $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Uzlādes stacija $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Konfidencialitātes vairogs ar degvielas pilienu';

  @override
  String get globeIllustrationSemantic =>
      'Globuss ar degvielas uzpildes staciju marķieriem';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Degvielas sūknis ar cenu rādītāju';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, datu avots: $provider, $keyRequirement, degvielas veidi: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Nepieciešama API atslēga';

  @override
  String get countryInfoNoKeyNeeded => 'Bez maksas, atslēga nav vajadzīga';

  @override
  String countryInfoDataSource(String provider) {
    return 'Dati: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Degvielas veidi: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon atslēga';

  @override
  String get anonKeyHideTooltip => 'Slēpt atslēgu';

  @override
  String get anonKeyShowTooltip => 'Rādīt atslēgu verificēšanai';

  @override
  String anonKeyTooLong(int length) {
    return 'Atslēga ir pārāk gara ($length rakstzīmes) — pārbaudiet, vai nav papildu teksta';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Atslēga izskatās pareizi ($length rakstzīmes)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Atslēgai jābūt JWT (galvene.lietderīga krava.paraksts)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Atslēga var būt saīsināta ($length no ~208 gaidītajām rakstzīmēm)';
  }

  @override
  String get anonKeyExceedsMax => 'Atslēga pārsniedz maksimālo garumu';

  @override
  String get qrShareTitle => 'Kopīgot savu datu bāzi';

  @override
  String get qrShareSubtitle => 'Citi var skenēt šo QR kodu, lai savienotos';

  @override
  String get qrShareCopyAsText => 'Kopēt kā tekstu';

  @override
  String get authInfoTitle => 'Kāpēc izveidot kontu?';

  @override
  String get authInfoBenefit1 =>
      '• Sinhronizēt izlases, brīdinājumus un saglabātos maršrutus starp ierīcēm';

  @override
  String get authInfoBenefit2 =>
      '• Sagatavojiet maršrutu savā tālrunī, izmantojiet to savā automašīnā';

  @override
  String get authInfoBenefit3 => '• Dati netiek kopīgoti ar trešajām pusēm';

  @override
  String get authInfoBenefit4 => '• Jūs varat dzēst savu kontu jebkurā laikā';

  @override
  String get privacyLocalDataEmpty =>
      'Vēl nekas nav saglabāts. Pievienojiet izlasi vai iestatiet cenu brīdinājumu, lai redzētu ierakstus šeit.';

  @override
  String get privacyHideEmptyRows => 'Slēpt tukšās rindas';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rādīt $count tukšas rindas',
      one: 'Rādīt $count tukšu rindu',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API atslēgas iestatīšana (neobligāti)';

  @override
  String get apiKeySetupDescription =>
      'Reģistrējieties bezmaksas API atslēgai vai izlaidiet un izpētiet lietotni ar demonstrācijas datiem.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider reģistrācija';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Ievadot API atslēgu, jūs pieņemat $provider noteikumus. Datu tālāknodošana ir aizliegta.';
  }

  @override
  String get calculatorDistanceHint => 'piem. 150';

  @override
  String get calculatorConsumptionHint => 'piem. 7.0';

  @override
  String get calculatorPriceHint => 'piem. 1.899';

  @override
  String get routeStrategyLabel => 'Stratēģija:';

  @override
  String get routeStrategyUniform => 'Vienāda';

  @override
  String get routeStrategyBalanced => 'Līdzsvarota';

  @override
  String get glideCoachBetaTitle => 'Slīdēšanas treneris beta (eksperimentāls)';

  @override
  String get glideCoachBetaSubtitle =>
      'Smalka haptika, palēninot pirms sarkanās gaismas. Pēc noklusējuma izslēgts — novēršanas risks.';

  @override
  String get consentSyncTripsTitle => 'Sinhronizēt braucienu ierakstus';

  @override
  String get consentSyncTripsSubtitle =>
      'Dublēt OBD2 + GPS braucienus ar TankSync. Starpierīču, pēc izvēles.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Iespējojiet Mākoņa sinhronizāciju augstāk, lai dublētu braucienus.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Pierakstieties ar e-pasta kontu, lai sinhronizētu braucienus starp ierīcēm.';

  @override
  String get consentHideDetails => 'Slēpt detaļas';

  @override
  String get consentShowDetails => 'Rādīt detaļas';

  @override
  String get dialogOk => 'Labi';

  @override
  String get invalidLinkTitle => 'Nederīga saite';

  @override
  String invalidLinkBody(String path) {
    return 'Saite \"$path\" nav derīga.';
  }

  @override
  String get home => 'Sākums';

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
  String get locationConsentTitle => 'Atrašanās vietas piekļuve';

  @override
  String get locationConsentSubtitle =>
      'Šī lietotne vēlas izmantot jūsu atrašanās vietu, lai atrastu tuvumā esošās degvielas uzpildes stacijas.';

  @override
  String get locationConsentWhatHappens =>
      'Kas notiek ar jūsu atrašanās vietas datiem:';

  @override
  String get locationConsentBulletApi =>
      'Jūsu koordinātes tiek nosūtītas degvielas cenu API, lai atrastu tuvumā esošās stacijas.';

  @override
  String get locationConsentBulletNoServer =>
      'Jūsu atrašanās vieta netiek glabāta nevienā serverī — servera nav.';

  @override
  String get locationConsentBulletNoTracking =>
      'Atrašanās vietas dati netiek izmantoti reklāmai, analītikai vai izsekošanai.';

  @override
  String get locationConsentRevoke =>
      'Atrašanās vietas piekļuvi varat jebkurā laikā atsaukt sistēmas iestatījumos. Varat arī meklēt pēc pasta indeksa.';

  @override
  String get locationConsentLegalBasis =>
      'Juridiskais pamats: VDAR 6. panta 1. punkta a) apakšpunkts (piekrišana)';

  @override
  String get locationConsentDecline => 'Noraidīt';

  @override
  String get locationConsentAccept => 'Piekrist';

  @override
  String get loyaltySettingsTitle => 'Degvielas kluba kartes';

  @override
  String get loyaltySettingsSubtitle =>
      'Lietojiet savu lojalitātes atlaidi rādītajām cenām';

  @override
  String get loyaltyMenuTitle => 'Degvielas kluba kartes';

  @override
  String get loyaltyMenuSubtitle =>
      'Lietojiet par litru atlaides no Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Pievienot karti';

  @override
  String get loyaltyAddCardSheetTitle => 'Pievienot degvielas kluba karti';

  @override
  String get loyaltyBrandLabel => 'Zīmols';

  @override
  String get loyaltyCardLabelLabel => 'Apzīmējums (neobligāti)';

  @override
  String get loyaltyDiscountLabel => 'Atlaide (par litru)';

  @override
  String get loyaltyDiscountInvalid => 'Ievadiet pozitīvu skaitli';

  @override
  String get loyaltyDeleteConfirmTitle => 'Dzēst karti?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Šī karte vairs nepiemēros savu atlaidi.';

  @override
  String get loyaltyEmptyTitle => 'Vēl nav degvielas kluba karšu';

  @override
  String get loyaltyEmptyBody =>
      'Pievienojiet karti, lai automātiski piemērotu savu par litru atlaidi atbilstošajām stacijām.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Noteikta dīkstāves RPM pieauguma tendence';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Dīkstāves RPM ir pieaudzis par $percent% jūsu pēdējo $tripCount braucienu laikā. Iespējama gaisa filtra aizsērēšanas vai sensora novirzīšanās agrīna pazīme.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Iespējams ieplūdes ierobežojums';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Kruīza degvielas patēriņš ir samazinājies par $percent% jūsu pēdējo $tripCount braucienu laikā. Iespējama gaisa filtra aizsērēšanas vai ierobežotas ieplūdes pazīme — vērts pārbaudīt.';
  }

  @override
  String get maintenanceActionDismiss => 'Aizvērt';

  @override
  String get maintenanceActionSnooze => 'Atgādināt pēc 30 dienām';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Šis mēnesis salīdzinājumā ar iepriekšējo';

  @override
  String get consumptionMonthlyTripsLabel => 'Braucieni';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Braukšanas laiks';

  @override
  String get consumptionMonthlyDistanceLabel => 'Attālums';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Vidējais patēriņš';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Salīdzināšanai nepieciešami vismaz 3 braucieni mēnesī';

  @override
  String get consumptionMonthlyClimbLabel => 'Climbed';

  @override
  String get obd2CapabilitySectionTitle => 'Adaptera iespējas';

  @override
  String get obd2CapabilityStandardOnly => 'Standarts';

  @override
  String get obd2CapabilityOemPids => 'OEM PID';

  @override
  String get obd2CapabilityFullCan => 'Pilns CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Precīzam litru daudzumam tvertnē uz Peugeot/Citroën, lietotne atbalsta OBDLink MX+/LX/CX (STN mikroshēma).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2 diagnostikas pārklājums iespējots';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 diagnostikas pārklājums atspējots';

  @override
  String get obd2DebugOverlayClearButton => 'Notīrīt';

  @override
  String get obd2DebugOverlayCloseButton => 'Aizvērt';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 izsekošanas pēdas';

  @override
  String get obd2DiagnosticShareLabel => 'Kopīgot diagnostikas žurnālu';

  @override
  String get obd2DebugLoggingTitle => 'OBD2 atkļūdošanas žurnāls';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Ierakstiet katru OBD2 sesiju — savienojumu, rokasspiedienu, datu pārtraukumus un atkārtotus savienojumus — eksportējamā XML žurnālā. Pēc noklusējuma izslēgts.';

  @override
  String get obd2DebugSessionShareLabel => 'Kopīgot OBD2 sesijas žurnālu';

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
  String get obd2HealthCopyInitTranscript => 'Copy init transcript only';

  @override
  String get obd2DiagnosticsEmpty =>
      'No OBD2 session recorded yet — connect an adapter and record a trip with Developer mode on.';

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
  String get obd2HealthCopyJson => 'Copy as JSON';

  @override
  String get obd2HealthCopied => 'OBD2 diagnostics copied to clipboard.';

  @override
  String get obd2TestRunTitle => 'Run adapter test';

  @override
  String get obd2TestRunButton => 'Run adapter test';

  @override
  String get obd2TestRunPassed => 'Adapter test passed';

  @override
  String get obd2TestRunFailed => 'Adapter test failed';

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
  String get obd2TestStepConnect => 'Connect & init';

  @override
  String get obd2TestStepInfo => 'Adapter info';

  @override
  String get obd2TestStepSupportedPids => 'Supported PIDs';

  @override
  String get obd2TestStepSampleReads => 'Sample reads';

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
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nevarēja sasniegt \'$adapterName\' — izvēlieties citu adapteru';
  }

  @override
  String get ocrTesterTitle => 'OCR tester';

  @override
  String get ocrTesterNavLabel => 'OCR tester';

  @override
  String get ocrTesterExplain =>
      'Run the pump / receipt OCR pipeline on a chosen photo and inspect every step — only available in Developer mode.';

  @override
  String get ocrTesterModePump => 'Pump';

  @override
  String get ocrTesterModeReceipt => 'Receipt';

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
  String get ocrTesterNoResult => 'OCR produced no readable result.';

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
  String get ocrTesterSaveFixture => 'Save as fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture saved to your Downloads folder. Move it under test/fixtures and run tool/promote_ocr_fixture.dart.';

  @override
  String get onboardingObd2StepTitle => 'Savienojiet savu OBD2 adapteru';

  @override
  String get onboardingObd2StepBody =>
      'Pievienojiet OBD2 adapteru automašīnas portam un ieslēdziet aizdedzi. Mēs nolasīsim VIN un aizpildīsim dzinēja datus jūsu vietā.';

  @override
  String get onboardingObd2ConnectButton => 'Savienot adapteru';

  @override
  String get onboardingObd2SkipButton => 'Varbūt vēlāk';

  @override
  String get onboardingObd2ReadingVin => 'Nolasa VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Nevarēja nolasīt VIN — ievadiet manuāli';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nevarēja savienoties ar adapteru. Varat mēģināt vēlreiz vai izlaist.';

  @override
  String get onboardingPickUseMode =>
      'Izvēlieties lietošanas veidu, lai turpinātu.';

  @override
  String get openNow => 'Open';

  @override
  String get openNowClosed => 'Closed';

  @override
  String get openHoursUnknown => 'Hours unknown';

  @override
  String closesAt(String time) {
    return 'Closes $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Opens $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Opens $time';
  }

  @override
  String get open24Hours => 'Open 24 hours';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => '24/7 automate';

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
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'pagājis';

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
  String get alertsRadiusFrequencyLabel => 'Pārbaudes biežums';

  @override
  String get alertsRadiusFrequencyDaily => 'Vienu reizi dienā';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Divas reizes dienā';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Trīs reizes dienā';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Četras reizes dienā';

  @override
  String get radiusAlertPickOnMap => 'Izvēlēties kartē';

  @override
  String get radiusAlertMapPickerTitle => 'Izvēlieties brīdinājuma centru';

  @override
  String get radiusAlertMapPickerConfirm => 'Apstiprināt';

  @override
  String get radiusAlertMapPickerCancel => 'Atcelt';

  @override
  String get radiusAlertMapPickerHint =>
      'Velciet karti, lai novietotu brīdinājuma centru';

  @override
  String get radiusAlertCenterFromMap => 'Kartes atrašanās vieta';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel pie $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Stacija ir pie $price € (mērķis: $threshold €)';
  }

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
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesija';

  @override
  String get shareReceiptImporting => 'Importing shared receipt…';

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
  String get speedConsumptionCardTitle => 'Patēriņš pēc ātruma';

  @override
  String get speedBandIdleJam => 'Dīkstāvē / sastrēgumā';

  @override
  String get speedBandUrban => 'Pilsētas (10–50)';

  @override
  String get speedBandSuburban => 'Piepilsētas (50–80)';

  @override
  String get speedBandRural => 'Lauku (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eko kruīzs (100–115)';

  @override
  String get speedBandMotorway => 'Šoseja (115–130)';

  @override
  String get speedBandMotorwayFast => 'Ātrā šoseja (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Ierakstiet 30+ minūtes braucienu ar OBD2 adapteru, lai atbloķētu ātruma/patēriņa analīzi.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % no braukšanas';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Nepieciešami vairāk datu';

  @override
  String get splashLoadingLabel => 'Ielādē Sparkilo';

  @override
  String get storageRecoveryTitle => 'Krātuves problēma';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo nevarēja atvērt savu vietējo datu krātuvi. Šķiet, ka krātuves fails ir bojāts.';

  @override
  String get storageRecoveryGuidance =>
      'Lai atjaunotu, ierīces iestatījumos notīriet lietotnes krātuvi vai pārinstalējiet lietotni. Jūsu izlase un vēsture tiek glabāta tikai šajā ierīcē, tāpēc tās nevar atjaunot automātiski.';

  @override
  String get tankLevelTitle => 'Tvertnes līmenis';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km braukšanas';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Pēdējā uzpilde: $date · $count brauciens(-i) kopš';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 mērīts';

  @override
  String get tankLevelMethodDistanceFallback => 'uz attālumu balstīts aprēķins';

  @override
  String get tankLevelMethodMixed => 'jaukts mērījums';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Reģistrējiet uzpildi, lai redzētu tvertnes līmeni';

  @override
  String get tankLevelDetailSheetTitle => 'Braucieni kopš pēdējās uzpildes';

  @override
  String get addFillUpIsFullTankLabel => 'Pilna tvertne';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tvertne piepildīta līdz malai — noņemiet atzīmi, ja tā bija daļēja uzpilde';

  @override
  String get themeCardTitle => 'Dizains';

  @override
  String get themeCardSubtitleSystem => 'Sistēma';

  @override
  String get themeCardSubtitleLight => 'Gaišs';

  @override
  String get themeCardSubtitleDark => 'Tumšs';

  @override
  String get themeSettingsScreenTitle => 'Dizains';

  @override
  String get themeSettingsSystemLabel => 'Sekot sistēmai';

  @override
  String get themeSettingsLightLabel => 'Gaišs';

  @override
  String get themeSettingsDarkLabel => 'Tumšs';

  @override
  String get themeSettingsSystemDescription =>
      'Atbilst pašreizējam ierīces izskatam.';

  @override
  String get themeSettingsLightDescription =>
      'Gaišs fons — vislabāk izmantošanai dienā.';

  @override
  String get themeSettingsDarkDescription =>
      'Tumšs fons — mazāk nogurdina acis naktī un taupo akumulatoru OLED ekrānos.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Lietotnes parakstīgais zaļais izskats — gaišs un viegli lasāms ar maigi zaļiem foniem.';

  @override
  String get throttleRpmHistogramTitle => 'Kā izmantojāt dzinēju';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gāzes pedāļa stāvoklis';

  @override
  String get throttleRpmHistogramRpmSection => 'Dzinēja RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Skriešana (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Viegls (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Vidējs (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Pilna gāze (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Dīkstāvē (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Kruīzs (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Aktīvs (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Intensīvs (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Šajā braucienā nav gāzes pedāļa vai RPM paraugu.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Braucieni';

  @override
  String get trajetsStartRecordingButton => 'Sākt ierakstīšanu';

  @override
  String get trajetsResumeRecordingButton => 'Turpināt ierakstīšanu';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Savienojas ar OBD2 adapteru…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Nolasa transportlīdzekļa datus…';

  @override
  String get tripStartProgressStartingRecording => 'Sāk ierakstīšanu…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

  @override
  String get trajetsEmptyStateTitle => 'Vēl nav braucienu';

  @override
  String get trajetsEmptyStateBody =>
      'Pieskarieties Sākt ierakstīšanu, lai sāktu reģistrēt braucienus.';

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
  String get trajetDetailSummaryTitle => 'Kopsavilkums';

  @override
  String get trajetDetailFieldDate => 'Datums';

  @override
  String get trajetDetailFieldVehicle => 'Transportlīdzeklis';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adapteris';

  @override
  String get trajetDetailFieldDistance => 'Attālums';

  @override
  String get trajetDetailFieldDuration => 'Ilgums';

  @override
  String get trajetDetailFieldAvgConsumption => 'Vidējais patēriņš';

  @override
  String get trajetDetailFieldFuelUsed => 'Patērētā degviela';

  @override
  String get trajetDetailFieldFuelCost => 'Degvielas izmaksas';

  @override
  String get trajetDetailFieldAvgSpeed => 'Vidējais ātrums';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maksimālais ātrums';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Ātrums (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Degvielas patēriņš (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Dzinēja slodze (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Diagrammas';

  @override
  String get trajetsRowColdStartChip => 'Aukstais starts';

  @override
  String get trajetsRowColdStartTooltip =>
      'Dzinējs šī brauciena laikā nesasniedza darba temperatūru — degvielas patēriņš bija augstāks nekā parasti.';

  @override
  String get trajetDetailChartEmpty => 'Nav ierakstītu paraugu';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Kopīgot';

  @override
  String get trajetDetailShareImageOption => 'Kopīgot attēlu';

  @override
  String get trajetDetailShareGpxOption => 'Kopīgot GPS taku (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Nav GPS datu šim braucienam';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — brauciens $date';
  }

  @override
  String get trajetDetailShareError => 'Nevarēja ģenerēt kopīgošanas attēlu';

  @override
  String get trajetDetailDownloadCsvOption => 'Download telemetry (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetry (JSON)';

  @override
  String get trajetDetailDownloadError => 'Couldn\'t save the file';

  @override
  String get trajetDetailDeleteAction => 'Dzēst';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Dzēst šo braucienu?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Šis brauciens tiks neatgriezeniski noņemts no jūsu vēstures.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Atcelt';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Dzēst';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapteris savienots, bet neatgriež datus. Mēģiniet ar citu adapteru vai pārbaudiet transportlīdzekļa diagnostikas protokolu.';

  @override
  String get trajetsViewAllOnMap => 'Rādīt visus kartē';

  @override
  String get trajetsMapTitle => 'Braucieni kartē';

  @override
  String get trajetsMapShareGpx => 'Kopīgot GPX';

  @override
  String get trajetsMapEmpty =>
      'Nevienam no atlasītajiem braucieniem nav GPS datu.';

  @override
  String get trajetsMapShareError => 'GPX failu nevarēja kopīgot';

  @override
  String get tripLengthCardTitle => 'Patēriņš pēc brauciena garuma';

  @override
  String get tripLengthBucketShort => 'Īss (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Vidējs (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Garš (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Nepieciešami vairāk datu';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count braucieni',
      one: '1 brauciens',
      zero: 'nav braucienu',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Brauciena ceļš';

  @override
  String get tripPathCardSubtitle => 'GPS ierakstīts maršruts';

  @override
  String get tripPathLegendTitle => 'Patēriņš';

  @override
  String get tripPathLegendEfficient => 'Efektīvs (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Robežlīnija (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Izšķērdīgs (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

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
  String get tripRecordingPinTooltip =>
      'Piespraušana patur ekrānu ieslēgtu — patērē vairāk akumulatora';

  @override
  String get tripRecordingPinSemanticOn => 'Atspraust ierakstīšanas formu';

  @override
  String get tripRecordingPinSemanticOff => 'Piespraust ierakstīšanas formu';

  @override
  String get tripRecordingPinHelpTooltip => 'Ko dara piespraušana?';

  @override
  String get tripRecordingPinHelpTitle => 'Par piespraušanu';

  @override
  String get tripRecordingPinHelpBody =>
      'Piespraušana patur ekrānu ieslēgtu un paslēpj sistēmas joslas, lai forma paliek lasāma uz paneļa stiprinājuma. Pieskarieties vēlreiz, lai atbrīvotu. Automātiski atbrīvojas, kad brauciens apstājas.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Ierakstīšana turpinās fonā. Pieskarieties sarkanajam banerim jebkura ekrāna augšdaļā, lai atgrieztos.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Atveriet aktīvo braucienu no Patēriņa cilnes';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Piespraudiet ekrānu, lai GPS paliek aktīvs brauciena laikā — Android var ierobežot GPS miega laikā.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimizēt uz peldošu elementu';

  @override
  String get tripRecordingAutoPinTitle => 'Vienmēr piespraust, sākot ierakstu';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Automātiski piespraust veidlapu katrā braucienā, nevis pieskaroties katru reizi. Patērē vairāk akumulatora.';

  @override
  String get tripRecordingConnectingTitle => 'Notiek ieraksta sākšana…';

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
  String get tripShareAction => 'Kopīgot ar citu kontu';

  @override
  String get tripShareSheetTitle => 'Kopīgot šo braucienu';

  @override
  String get tripShareSheetSubtitle =>
      'Piešķiriet citam TankSync kontam tikai lasīšanas piekļuvi šim ierakstītajam braucienam.';

  @override
  String get tripShareEmailLabel => 'Saņēmēja e-pasts';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Kopīgot';

  @override
  String get tripShareCreateLinkButton => 'Izveidot kopīgošanas saiti';

  @override
  String get tripShareLinkCreated =>
      'Kopīgošanas saite nokopēta — ielīmējiet to saņēmējam.';

  @override
  String get tripShareSuccess => 'Brauciens kopīgots.';

  @override
  String get tripShareRecipientNotFound =>
      'Neviens TankSync konts neizmanto šo e-pastu.';

  @override
  String get tripShareError => 'Neizdevās kopīgot braucienu. Mēģiniet vēlreiz.';

  @override
  String get tripShareExistingTitle => 'Kopīgots ar';

  @override
  String get tripShareExistingEmpty => 'Vēl ne ar vienu nav kopīgots.';

  @override
  String get tripShareDirectRecipient => 'Konts';

  @override
  String get tripShareLinkRecipient => 'Kopīgošanas saite (nepieprasīta)';

  @override
  String get tripShareRevokeTooltip => 'Atsaukt';

  @override
  String get tripShareRevoked => 'Kopīgošana atsaukta.';

  @override
  String get trajetsSharedSectionTitle => 'Kopīgots ar mani';

  @override
  String get trajetsSharedBadge => 'Kopīgots';

  @override
  String get unifiedFilterFuel => 'Degviela';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Abi';

  @override
  String get unifiedNoResultsForFilter =>
      'Šim filtram nav atbilstošu rezultātu';

  @override
  String get searchFailedSnackbar =>
      'Meklēšana neizdevās — lūdzu, mēģiniet vēlreiz';

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
  String get vinLabel => 'VIN (neobligāti)';

  @override
  String get vinDecodeTooltip => 'Atšifrēt VIN';

  @override
  String get vinConfirmAction => 'Jā, automātiski aizpildīt';

  @override
  String get vinModifyAction => 'Labot manuāli';

  @override
  String get veResetAction => 'Atiestatīt tilpuma efektivitāti';

  @override
  String get vehicleReadVinFromCarButton => 'Nolasīt VIN no automašīnas';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Nolasīt VIN no savienotā OBD2 adaptera';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN nav pieejams (9. režīms PID 02 neatbalstīts pirms 2005. gada automašīnās)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN nolasīšana neizdevās — lūdzu, ievadiet manuāli';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Vispirms savienojiet OBD2 adapteru, lai nolasītu VIN automātiski';

  @override
  String get pickerButtonLabel => 'Izvēlēties no kataloga';

  @override
  String get pickerSearchHint => 'Meklēt marku vai modeli';

  @override
  String get pickerHelpText =>
      'Iepriekš aizpildīt no 50+ atbalstītajiem transportlīdzekļiem';

  @override
  String get pickerEmptyResults => 'Nav atbilstību';

  @override
  String get pickerCancel => 'Atcelt';

  @override
  String get pickerLoading => 'Ielādē katalogu…';

  @override
  String get vinInfoTooltip => 'Kas ir VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Kas ir VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Transportlīdzekļa identifikācijas numurs ir 17 rakstzīmju kods, kas ir unikāls jūsu automašīnai. Tas ir iespiedots uz šasijas un drukāts jūsu transportlīdzekļa reģistrācijas dokumentā.';

  @override
  String get vinInfoSectionWhyTitle => 'Kāpēc mēs jautājam';

  @override
  String get vinInfoSectionWhyBody =>
      'VIN atšifrēšana automātiski aizpilda dzinēja tilpumu, cilindru skaitu, modeļa gadu, primāro degvielas veidu un bruto svaru — ietaupa no tehnisko specifikāciju meklēšanas. OBD2 degvielas patēriņa aprēķins izmanto šīs vērtības, lai sniegtu precīzus patēriņa skaitļus.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privātums';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Jūsu VIN tiek glabāts tikai lokāli lietotnes šifrētajā atmiņā — tas nekad netiek augšupielādēts uz Sparkilo serveriem. NHTSA vPIC datu bāze tiek vaicāta ar VIN, bet atgriež tikai anonīmas tehniskas specifikācijas; NHTSA nesaista VIN ar personas datiem. Bez tīkla bezsaistes uzmeklēšana atgriež tikai ražotāju un valsti.';

  @override
  String get vinInfoSectionWhereTitle => 'Kur to atrast';

  @override
  String get vinInfoSectionWhereBody =>
      'Skatieties caur vējstiklu vadītāja puses apakšējā kreisajā stūrī, pārbaudiet vadītāja puses durvju rāmja uzlīmi, kad durvis ir atvērtas, vai nolasiet no sava transportlīdzekļa reģistrācijas dokumenta (kartiņa / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Sapratu';

  @override
  String get vinConfirmPrivacyNote =>
      'Mēs uzmeklējām jūsu VIN NHTSA bezmaksas transportlīdzekļu datu bāzē — nekas nosūtīts uz Sparkilo serveriem.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN tiešsaistes atšifrēšana';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Atšifrēt VIN caur NHTSA bezmaksas publisku pakalpojumu';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Savienojot adapteru, jūsu transportlīdzekļa VIN tiek nolasīts lokāli, lai identificētu automašīnu. Iespējojot šo, 17 rakstzīmju VIN tiek nosūtīts uz NHTSA bezmaksas vPIC pakalpojumu, lai uzmeklētu papildu detaļas (modelis, dzinēja tilpums, degvielas veids). VIN ir vienīgie nosūtītie dati — nekas cits neatstāj jūsu ierīci.';

  @override
  String get vehicleDetectedFromVinBadge => '(noteikts)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Noteikts no VIN: $summary. Lietot?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Lietot';

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
  String get widgetHelpSectionTitle => 'Sākuma ekrāna logrīks';

  @override
  String get widgetHelpIntro =>
      'Pievienojiet SparKilo logrīku savam sākuma ekrānam, lai redzētu degvielas un uzlādes cenas uzreiz.';

  @override
  String get widgetHelpAdd =>
      'Pievienojiet to no palaišanas programmas logrīku izvēlnes — ilgi spiediet tukšu sākuma ekrāna apgabalu, izvēlieties Logrīki un atrodiet SparKilo.';

  @override
  String get widgetHelpTap =>
      'Pieskarieties logrīkā stacijai, lai to atvērtu lietotnē. Pieskarieties atjaunināšanas ikonai, lai atjauninātu cenas.';

  @override
  String get widgetHelpConfigure =>
      'Android lietotnē ilgi spiediet logrīku un izvēlieties Pārkonfigurēt, lai mainītu profilu, krāsu un saturu.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Turpmākās izvēles tiek piemērotas katram instalētajam logrīkam nākamajā atjaunināšanā.';

  @override
  String get widgetDefaultsColorLabel => 'Krāsu shēma';

  @override
  String get widgetDefaultsVariantLabel => 'Satura variants';

  @override
  String get widgetColorSchemeSystem => 'Sekot sistēmai';

  @override
  String get widgetColorSchemeLight => 'Gaišs';

  @override
  String get widgetColorSchemeDark => 'Tumšs';

  @override
  String get widgetColorSchemeBlue => 'Zils';

  @override
  String get widgetColorSchemeGreen => 'Zaļš';

  @override
  String get widgetColorSchemeOrange => 'Oranžs';

  @override
  String get widgetVariantDefault => 'Tikai pašreizējā cena';

  @override
  String get widgetVariantPredictive => 'Prognozējošs: labākais laiks uzpildei';

  @override
  String get widgetPredictiveNowPrefix => 'tagad';
}
