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
}
