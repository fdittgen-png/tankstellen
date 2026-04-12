// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'Cene goriv';

  @override
  String get search => 'Iskanje';

  @override
  String get favorites => 'Priljubljene';

  @override
  String get map => 'Zemljevid';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Nastavitve';

  @override
  String get gpsLocation => 'GPS lokacija';

  @override
  String get zipCode => 'Poštna številka';

  @override
  String get zipCodeHint => 'npr. 1000';

  @override
  String get fuelType => 'Gorivo';

  @override
  String get searchRadius => 'Polmer';

  @override
  String get searchNearby => 'Bencinske postaje v bližini';

  @override
  String get searchButton => 'Iskanje';

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
  String get noResults => 'Ni najdenih bencinskih postaj.';

  @override
  String get startSearch => 'Iščite bencinske postaje.';

  @override
  String get open => 'Odprto';

  @override
  String get closed => 'Zaprto';

  @override
  String distance(String distance) {
    return '$distance stran';
  }

  @override
  String get price => 'Cena';

  @override
  String get prices => 'Cene';

  @override
  String get address => 'Naslov';

  @override
  String get openingHours => 'Odpiralni čas';

  @override
  String get open24h => 'Odprto 24 ur';

  @override
  String get navigate => 'Navigiraj';

  @override
  String get retry => 'Poskusi znova';

  @override
  String get apiKeySetup => 'API ključ';

  @override
  String get apiKeyDescription =>
      'Registrirajte se enkrat za brezplačni API ključ.';

  @override
  String get apiKeyLabel => 'API ključ';

  @override
  String get register => 'Registracija';

  @override
  String get continueButton => 'Nadaljuj';

  @override
  String get welcome => 'Cene goriv';

  @override
  String get welcomeSubtitle => 'Najdite najcenejše gorivo v bližini.';

  @override
  String get profileName => 'Ime profila';

  @override
  String get preferredFuel => 'Prednostno gorivo';

  @override
  String get defaultRadius => 'Privzeti polmer';

  @override
  String get landingScreen => 'Začetni zaslon';

  @override
  String get homeZip => 'Domača poštna številka';

  @override
  String get newProfile => 'Nov profil';

  @override
  String get editProfile => 'Uredi profil';

  @override
  String get save => 'Shrani';

  @override
  String get cancel => 'Prekliči';

  @override
  String get delete => 'Izbriši';

  @override
  String get activate => 'Aktiviraj';

  @override
  String get configured => 'Nastavljeno';

  @override
  String get notConfigured => 'Ni nastavljeno';

  @override
  String get about => 'O aplikaciji';

  @override
  String get openSource => 'Odprtokodna (licenca MIT)';

  @override
  String get sourceCode => 'Izvorna koda na GitHubu';

  @override
  String get noFavorites => 'Ni priljubljenih';

  @override
  String get noFavoritesHint =>
      'Tapnite zvezdico pri postaji, da jo dodate med priljubljene.';

  @override
  String get language => 'Jezik';

  @override
  String get country => 'Država';

  @override
  String get demoMode => 'Demo način — prikazani so vzorčni podatki.';

  @override
  String get setupLiveData => 'Nastavitev za žive podatke';

  @override
  String get freeNoKey => 'Brezplačno — ključ ni potreben';

  @override
  String get apiKeyRequired => 'Potreben API ključ';

  @override
  String get skipWithoutKey => 'Nadaljuj brez ključa';

  @override
  String get dataTransparency => 'Preglednost podatkov';

  @override
  String get storageAndCache => 'Shramba in predpomnilnik';

  @override
  String get clearCache => 'Počisti predpomnilnik';

  @override
  String get clearAllData => 'Izbriši vse podatke';

  @override
  String get errorLog => 'Dnevnik napak';

  @override
  String stationsFound(int count) {
    return 'Najdenih $count postaj';
  }

  @override
  String get whatIsShared => 'Kaj se deli — in s kom?';

  @override
  String get gpsCoordinates => 'GPS koordinate';

  @override
  String get gpsReason =>
      'Pošljejo se z vsakim iskanjem za iskanje bližnjih postaj.';

  @override
  String get postalCodeData => 'Poštna številka';

  @override
  String get postalReason =>
      'Pretvori se v koordinate prek geokodirne storitve.';

  @override
  String get mapViewport => 'Prikaz zemljevida';

  @override
  String get mapReason =>
      'Ploščice zemljevida se naložijo s strežnika. Osebni podatki se ne prenašajo.';

  @override
  String get apiKeyData => 'API ključ';

  @override
  String get apiKeyReason =>
      'Vaš osebni ključ se pošlje z vsako API zahtevo. Povezan je z vašim e-naslovom.';

  @override
  String get notShared => 'SE NE deli:';

  @override
  String get searchHistory => 'Zgodovina iskanja';

  @override
  String get favoritesData => 'Priljubljene';

  @override
  String get profileNames => 'Imena profilov';

  @override
  String get homeZipData => 'Domača poštna številka';

  @override
  String get usageData => 'Podatki o uporabi';

  @override
  String get privacyBanner =>
      'Ta aplikacija nima strežnika. Vsi podatki ostanejo na vaši napravi. Brez analitike, sledenja ali oglasov.';

  @override
  String get storageUsage => 'Poraba shrambe na tej napravi';

  @override
  String get settingsLabel => 'Nastavitve';

  @override
  String get profilesStored => 'shranjenih profilov';

  @override
  String get stationsMarked => 'označenih postaj';

  @override
  String get cachedResponses => 'predpomnjenih odgovorov';

  @override
  String get total => 'Skupaj';

  @override
  String get cacheManagement => 'Upravljanje predpomnilnika';

  @override
  String get cacheDescription =>
      'Predpomnilnik shranjuje API odgovore za hitrejše nalaganje in dostop brez povezave.';

  @override
  String get stationSearch => 'Iskanje postaj';

  @override
  String get stationDetails => 'Podrobnosti postaje';

  @override
  String get priceQuery => 'Poizvedba o ceni';

  @override
  String get zipGeocoding => 'Geokodiranje poštne številke';

  @override
  String minutes(int n) {
    return '$n minut';
  }

  @override
  String hours(int n) {
    return '$n ur';
  }

  @override
  String get clearCacheTitle => 'Počistiti predpomnilnik?';

  @override
  String get clearCacheBody =>
      'Predpomnjeni rezultati iskanja in cene bodo izbrisani. Profili, priljubljene in nastavitve so ohranjeni.';

  @override
  String get clearCacheButton => 'Počisti predpomnilnik';

  @override
  String get deleteAllTitle => 'Izbrisati vse podatke?';

  @override
  String get deleteAllBody =>
      'To trajno izbriše vse profile, priljubljene, API ključ, nastavitve in predpomnilnik. Aplikacija se ponastavi.';

  @override
  String get deleteAllButton => 'Izbriši vse';

  @override
  String get entries => 'vnosov';

  @override
  String get cacheEmpty => 'Predpomnilnik je prazen';

  @override
  String get noStorage => 'Ni uporabljene shrambe';

  @override
  String get apiKeyNote =>
      'Brezplačna registracija. Podatki od vladnih agencij za cenovno preglednost.';

  @override
  String get apiKeyFormatError =>
      'Neveljavna oblika — pričakovan UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Podprite ta projekt';

  @override
  String get supportDescription =>
      'Ta aplikacija je brezplačna, odprtokodna in brez oglasov. Če jo smatrate za koristno, razmislite o podpori razvijalcu.';

  @override
  String get reportBug => 'Prijavi napako / Predlagaj funkcijo';

  @override
  String get privacyPolicy => 'Pravilnik o zasebnosti';

  @override
  String get fuels => 'Goriva';

  @override
  String get services => 'Storitve';

  @override
  String get zone => 'Cona';

  @override
  String get highway => 'Avtocesta';

  @override
  String get localStation => 'Lokalna postaja';

  @override
  String get lastUpdate => 'Zadnja posodobitev';

  @override
  String get automate24h => '24ur/24 — Avtomat';

  @override
  String get refreshPrices => 'Osveži cene';

  @override
  String get station => 'Bencinska postaja';

  @override
  String get locationDenied =>
      'Dovoljenje za lokacijo zavrnjeno. Iščete lahko po poštni številki.';

  @override
  String get demoModeBanner => 'Demo način. Nastavite API ključ v nastavitvah.';

  @override
  String get sortDistance => 'Razdalja';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'poceni';

  @override
  String get expensive => 'drago';

  @override
  String stationsOnMap(int count) {
    return '$count postaj';
  }

  @override
  String get loadingFavorites =>
      'Nalaganje priljubljenih...\nNajprej poiščite postaje za shranjevanje podatkov.';

  @override
  String get reportPrice => 'Prijavi ceno';

  @override
  String get whatsWrong => 'Kaj ni v redu?';

  @override
  String get correctPrice => 'Pravilna cena (npr. 1,459)';

  @override
  String get sendReport => 'Pošlji prijavo';

  @override
  String get reportSent => 'Prijava poslana. Hvala!';

  @override
  String get enterValidPrice => 'Vnesite veljavno ceno';

  @override
  String get cacheCleared => 'Predpomnilnik počiščen.';

  @override
  String get yourPosition => 'Vaša pozicija';

  @override
  String get positionUnknown => 'Pozicija neznana';

  @override
  String get distancesFromCenter => 'Razdalje od središča iskanja';

  @override
  String get autoUpdatePosition => 'Samodejno posodobi pozicijo';

  @override
  String get autoUpdateDescription =>
      'Posodobi GPS pozicijo pred vsakim iskanjem';

  @override
  String get location => 'Lokacija';

  @override
  String get switchProfileTitle => 'Država spremenjena';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Zdaj ste v $country. Preklopiti na profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Preklopljeno na profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ni profila za to državo';

  @override
  String noProfileForCountry(String country) {
    return 'Ste v $country, vendar ni nastavljenega profila. Ustvarite ga v Nastavitvah.';
  }

  @override
  String get autoSwitchProfile => 'Samodejna zamenjava profila';

  @override
  String get autoSwitchDescription =>
      'Samodejno zamenjaj profil ob prečkanju meje';

  @override
  String get switchProfile => 'Zamenjaj';

  @override
  String get dismiss => 'Zapri';

  @override
  String get profileCountry => 'Država';

  @override
  String get profileLanguage => 'Jezik';

  @override
  String get settingsStorageDetail => 'API ključ, aktivni profil';

  @override
  String get allFuels => 'Vse';

  @override
  String get priceAlerts => 'Cenovna opozorila';

  @override
  String get noPriceAlerts => 'Ni cenovnih opozoril';

  @override
  String get noPriceAlertsHint =>
      'Ustvarite opozorilo s strani s podrobnostmi postaje.';

  @override
  String alertDeleted(String name) {
    return 'Opozorilo \"$name\" izbrisano';
  }

  @override
  String get createAlert => 'Ustvari cenovno opozorilo';

  @override
  String currentPrice(String price) {
    return 'Trenutna cena: $price';
  }

  @override
  String get targetPrice => 'Ciljna cena (EUR)';

  @override
  String get enterPrice => 'Vnesite ceno';

  @override
  String get invalidPrice => 'Neveljavna cena';

  @override
  String get priceTooHigh => 'Cena previsoka';

  @override
  String get create => 'Ustvari';

  @override
  String get alertCreated => 'Cenovno opozorilo ustvarjeno';

  @override
  String get wrongE5Price => 'Napačna cena Super E5';

  @override
  String get wrongE10Price => 'Napačna cena Super E10';

  @override
  String get wrongDieselPrice => 'Napačna cena dizla';

  @override
  String get wrongStatusOpen => 'Prikazano kot odprto, vendar zaprto';

  @override
  String get wrongStatusClosed => 'Prikazano kot zaprto, vendar odprto';

  @override
  String get searchAlongRouteLabel => 'Vzdolž poti';

  @override
  String get searchEvStations => 'Iskanje polnilnih postaj';

  @override
  String get allStations => 'Vse postaje';

  @override
  String get bestStops => 'Najboljše postanke';

  @override
  String get openInMaps => 'Odpri v Zemljevidih';

  @override
  String get noStationsAlongRoute => 'Vzdolž poti ni najdenih postaj';

  @override
  String get evOperational => 'V obratovanju';

  @override
  String get evStatusUnknown => 'Status neznan';

  @override
  String evConnectors(int count) {
    return 'Priključki ($count točk)';
  }

  @override
  String get evNoConnectors => 'Ni podrobnosti o priključkih';

  @override
  String get evUsageCost => 'Stroški uporabe';

  @override
  String get evPricingUnavailable => 'Cenik ni na voljo od ponudnika';

  @override
  String get evLastUpdated => 'Nazadnje posodobljeno';

  @override
  String get evUnknown => 'Neznano';

  @override
  String get evDataAttribution => 'Podatki iz OpenChargeMap (skupnostni vir)';

  @override
  String get evStatusDisclaimer =>
      'Status morda ne odraža razpoložljivosti v realnem času. Tapnite osveži za najnovejše podatke.';

  @override
  String get evNavigateToStation => 'Navigiraj do postaje';

  @override
  String get evRefreshStatus => 'Osveži status';

  @override
  String get evStatusUpdated => 'Status posodobljen';

  @override
  String get evStationNotFound =>
      'Ni mogoče osvežiti — postaja ni najdena v bližini';

  @override
  String get addedToFavorites => 'Dodano med priljubljene';

  @override
  String get removedFromFavorites => 'Odstranjeno iz priljubljenih';

  @override
  String get addFavorite => 'Dodaj med priljubljene';

  @override
  String get removeFavorite => 'Odstrani iz priljubljenih';

  @override
  String get currentLocation => 'Trenutna lokacija';

  @override
  String get gpsError => 'GPS napaka';

  @override
  String get couldNotResolve => 'Ni mogoče določiti začetka ali cilja';

  @override
  String get start => 'Začetek';

  @override
  String get destination => 'Cilj';

  @override
  String get cityAddressOrGps => 'Mesto, naslov ali GPS';

  @override
  String get cityOrAddress => 'Mesto ali naslov';

  @override
  String get useGps => 'Uporabi GPS';

  @override
  String get stop => 'Postanek';

  @override
  String stopN(int n) {
    return 'Postanek $n';
  }

  @override
  String get addStop => 'Dodaj postanek';

  @override
  String get searchAlongRoute => 'Iskanje vzdolž poti';

  @override
  String get cheapest => 'Najcenejša';

  @override
  String nStations(int count) {
    return '$count postaj';
  }

  @override
  String nBest(int count) {
    return '$count najboljših';
  }

  @override
  String get fuelPricesTankerkoenig => 'Cene goriv (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Potrebno za iskanje cen goriv v Nemčiji';

  @override
  String get evChargingOpenChargeMap => 'Polnjenje EV (OpenChargeMap)';

  @override
  String get customKey => 'Ključ po meri';

  @override
  String get appDefaultKey => 'Privzeti ključ aplikacije';

  @override
  String get optionalOverrideKey =>
      'Neobvezno: zamenjajte vgrajeni ključ s svojim';

  @override
  String get requiredForEvSearch => 'Potrebno za iskanje EV polnilnih postaj';

  @override
  String get edit => 'Uredi';

  @override
  String get fuelPricesApiKey => 'API ključ cen goriv';

  @override
  String get tankerkoenigApiKey => 'API ključ Tankerkoenig';

  @override
  String get evChargingApiKey => 'API ključ polnjenja EV';

  @override
  String get openChargeMapApiKey => 'API ključ OpenChargeMap';

  @override
  String get routeSegment => 'Segment poti';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Prikaži najcenejšo postajo vsakih $km km vzdolž poti';
  }

  @override
  String get avoidHighways => 'Izogibaj se avtocestam';

  @override
  String get avoidHighwaysDesc =>
      'Izračun poti se izogiba cestninjenim cestam in avtocestam';

  @override
  String get showFuelStations => 'Prikaži bencinske postaje';

  @override
  String get showFuelStationsDesc => 'Vključi bencin, dizel, LPG, CNG postaje';

  @override
  String get showEvStations => 'Prikaži polnilne postaje';

  @override
  String get showEvStationsDesc =>
      'Vključi električne polnilne postaje v rezultatih';

  @override
  String get noStationsAlongThisRoute => 'Vzdolž te poti ni najdenih postaj.';

  @override
  String get fuelCostCalculator => 'Kalkulator stroškov goriva';

  @override
  String get distanceKm => 'Razdalja (km)';

  @override
  String get consumptionL100km => 'Poraba (L/100km)';

  @override
  String get fuelPriceEurL => 'Cena goriva (EUR/L)';

  @override
  String get tripCost => 'Stroški potovanja';

  @override
  String get fuelNeeded => 'Potrebno gorivo';

  @override
  String get totalCost => 'Skupni stroški';

  @override
  String get enterCalcValues =>
      'Vnesite razdaljo, porabo in ceno za izračun stroškov potovanja';

  @override
  String get priceHistory => 'Zgodovina cen';

  @override
  String get noPriceHistory => 'Še ni zgodovine cen';

  @override
  String get noHourlyData => 'Ni urnih podatkov';

  @override
  String get noStatistics => 'Ni razpoložljivih statistik';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Povp';

  @override
  String get showAllFuelTypes => 'Prikaži vse vrste goriv';

  @override
  String get connected => 'Povezano';

  @override
  String get notConnected => 'Ni povezano';

  @override
  String get connectTankSync => 'Poveži TankSync';

  @override
  String get disconnectTankSync => 'Prekini TankSync';

  @override
  String get viewMyData => 'Ogled mojih podatkov';

  @override
  String get optionalCloudSync =>
      'Neobvezna oblačna sinhronizacija za opozorila, priljubljene in push obvestila';

  @override
  String get tapToUpdateGps => 'Tapnite za posodobitev GPS pozicije';

  @override
  String get gpsAutoUpdateHint =>
      'GPS pozicija se samodejno pridobi ob iskanju. Tukaj jo lahko tudi ročno posodobite.';

  @override
  String get clearGpsConfirm =>
      'Počistiti shranjeno GPS pozicijo? Kadar koli jo lahko znova posodobite.';

  @override
  String get pageNotFound => 'Stran ni najdena';

  @override
  String get deleteAllServerData => 'Izbriši vse podatke strežnika';

  @override
  String get deleteServerDataConfirm => 'Izbrisati vse podatke strežnika?';

  @override
  String get deleteEverything => 'Izbriši vse';

  @override
  String get allDataDeleted => 'Vsi podatki strežnika izbrisani';

  @override
  String get disconnectConfirm => 'Prekiniti TankSync?';

  @override
  String get disconnect => 'Prekini';

  @override
  String get myServerData => 'Moji podatki na strežniku';

  @override
  String get anonymousUuid => 'Anonimni UUID';

  @override
  String get server => 'Strežnik';

  @override
  String get syncedData => 'Sinhronizirani podatki';

  @override
  String get pushTokens => 'Push žetoni';

  @override
  String get priceReports => 'Prijave cen';

  @override
  String get totalItems => 'Skupaj elementov';

  @override
  String get estimatedSize => 'Ocenjena velikost';

  @override
  String get viewRawJson => 'Ogled surovih podatkov kot JSON';

  @override
  String get exportJson => 'Izvozi kot JSON (odložišče)';

  @override
  String get jsonCopied => 'JSON kopiran v odložišče';

  @override
  String get rawDataJson => 'Surovi podatki (JSON)';

  @override
  String get close => 'Zapri';

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
  String get alertStatsActive => 'Aktivni';

  @override
  String get alertStatsToday => 'Danes';

  @override
  String get alertStatsThisWeek => 'Ta teden';

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
  String get nearestStations => 'Najblizje postaje';

  @override
  String get nearestStationsHint =>
      'Poiscite najblizje postaje z vaso trenutno lokacijo';

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
}
