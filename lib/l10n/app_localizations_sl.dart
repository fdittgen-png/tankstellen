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
  String get reportThisIssue => 'Report this issue';

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
  String get configProfileSection => 'Profile';

  @override
  String get configActiveProfile => 'Active profile';

  @override
  String get configPreferredFuel => 'Preferred fuel';

  @override
  String get configCountry => 'Country';

  @override
  String get configRouteSegment => 'Route segment';

  @override
  String get configApiKeysSection => 'API keys';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API key';

  @override
  String get configApiKeyConfigured => 'Configured';

  @override
  String get configApiKeyNotSet => 'Not set (demo mode)';

  @override
  String get configApiKeyCommunity => 'Default (community key)';

  @override
  String get searchLocationPlaceholder => 'Address, postal code or city';

  @override
  String get configEvKey => 'EV charging API key';

  @override
  String get configEvKeyCustom => 'Custom key';

  @override
  String get configEvKeyShared => 'Default (shared)';

  @override
  String get configCloudSyncSection => 'Cloud Sync';

  @override
  String get configTankSyncConnected => 'Connected';

  @override
  String get configTankSyncDisabled => 'Disabled';

  @override
  String get configAuthMode => 'Auth mode';

  @override
  String get configAuthEmail => 'Email (persistent)';

  @override
  String get configAuthAnonymous => 'Anonymous (device-only)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Privacy summary';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favorites, alerts, and ignored stations are synced to your private database\n• GPS position and API keys never leave your device\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• All data is stored locally on this device only\n• No data is sent to any server\n• API keys encrypted in device secure storage';

  @override
  String get configAuthNoteEmail => 'Email account enables cross-device access';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymous account — data tied to this device';

  @override
  String get configNone => 'None';

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
  String privacyCopyErrorLog(int count) {
    return 'Copy error log to clipboard ($count)';
  }

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
      'Battery, connectors, charging preferences';

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
  String get fillUpVehicleNone => 'No vehicle';

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
  String get scanPump => 'Scan pump';

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
  String get obdNoAdapter => 'No OBD2 adapter in range';

  @override
  String get obdOdometerUnavailable => 'Could not read odometer';

  @override
  String get obdPermissionDenied =>
      'Grant Bluetooth permission in system settings';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter didn\'t answer — turn the ignition on and retry';

  @override
  String get obdPickerTitle => 'Pick an OBD2 adapter';

  @override
  String get obdPickerScanning => 'Scanning for adapters…';

  @override
  String get obdPickerConnecting => 'Connecting…';

  @override
  String get themeSettingTitle => 'Theme';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'Follow system';

  @override
  String get tripRecordingTitle => 'Recording trip';

  @override
  String get tripSummaryTitle => 'Trip summary';

  @override
  String get tripMetricDistance => 'Distance';

  @override
  String get tripMetricSpeed => 'Speed';

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
  String get navConsumption => 'Consumption';

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
  String get obd2StatusAttempting => 'OBD2 adapter: connecting';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapter: unreachable';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: Bluetooth permission needed';

  @override
  String get obd2StatusConnectedBody => 'Ready to record a trip.';

  @override
  String get obd2StatusAttemptingBody => 'Connecting in the background…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter out of range or already in use by another app.';

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
  String get tripHistoryEmptySubtitle =>
      'Connect an OBD2 adapter and record a trip to start building your driving history.';

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
  String get situationHardAccel => 'Hard accel';

  @override
  String get situationFuelCut => 'Fuel cut — coast';

  @override
  String get tripSaveAsFillUp => 'Save as fill-up';

  @override
  String get tripSaveRecording => 'Save trip';

  @override
  String get tripDiscard => 'Discard';

  @override
  String obdOdometerRead(int km) {
    return 'Odometer read: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Not set';

  @override
  String get wizardVehicleTapToEdit => 'Tap to edit';

  @override
  String get wizardVehicleDefaultBadge => 'Default';

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
  String get alertsBackgroundCheckErrorTitle => 'Alert background check failed';

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
      'Your app works fully without cloud sync. TankSync lets you sync favorites, alerts, and ratings across devices using Supabase (free tier available).';

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
  String get syncModeCommunityTitle => 'Tankstellen Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Share favorites & ratings with all users';

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
  String get ntfyCardTitle => 'Push Notifications (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Enable ntfy.sh push';

  @override
  String get ntfyEnableSubtitle => 'Receive price alerts via ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'Topic URL';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Copy topic URL';

  @override
  String get ntfySendTestButton => 'Send test notification';

  @override
  String get ntfyFdroidHint =>
      'Install the ntfy app from F-Droid to receive push notifications on your device.';

  @override
  String get ntfyConnectFirstHint =>
      'Connect TankSync first to enable push notifications.';

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
  String get evChargingSection => 'EV Charging';

  @override
  String get fuelStationsSection => 'Fuel Stations';

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
  String get luxembourgRegulatedPricesNotice =>
      'Luxembourg fuel prices are government-regulated and uniform nationwide.';

  @override
  String get luxembourgFuelUnleaded95 => 'Unleaded 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Unleaded 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxembourg regulated prices are unavailable.';

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
  String get southKoreaApiKeyRequired =>
      'Register at OPINET to get a free API key';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired => 'Register at CNE to get a free API key';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

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
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Consumption calibration updated for $vehicleName — accuracy improved by $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Reset volumetric efficiency?';

  @override
  String get veResetConfirmBody =>
      'This will discard the learned volumetric efficiency (η_v) and restore the default value (0.85). Trip-level fuel-flow estimates will fall back to the manufacturer constant until the calibrator collects new samples from upcoming trips.';

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
  String get alertsRadiusThreshold => 'Threshold (€/L)';

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
  String get alertsRadiusDeleteConfirm => 'Delete radius alert?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 connected: $adapterName';
  }

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel dropped at nearby stations';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stations dropped by up to $maxDropCents¢ in the last hour';
  }

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
  String get autoRecordPairedAdapterLabel => 'Paired adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'No adapter paired. Pair one via the OBD2 onboarding first.';

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
  String get autoRecordBadgeClearTooltip => 'Clear counter';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Pair an adapter in the section below to enable auto-recording';

  @override
  String get exportBackupTooltip => 'Export backup';

  @override
  String get exportBackupReady => 'Backup ready — pick a destination';

  @override
  String get exportBackupFailed => 'Backup export failed — please try again';

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
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (calibrated, $samples samples)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (learning, $samples samples)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (default — no plein-complet yet)';

  @override
  String get calibrationResetLearner => 'Reset learner';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Your $makeModel is marked as diesel but matches a petrol catalog entry. Tap to update.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Update';

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
  String get chargingChartsMonthAxis => 'Month';

  @override
  String get gdprCommunityWaitTimeTitle => 'Community Wait Times';

  @override
  String get gdprCommunityWaitTimeShort =>
      'Anonymously share station wait times';

  @override
  String get gdprCommunityWaitTimeDescription =>
      'Anonymously share when you arrive at and leave a fuel station so the app can show typical wait times. No location coordinates are uploaded — only the station ID.';

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
  String get greeceApiProvider => 'Paratiritirio Timon (Greece)';

  @override
  String get greeceCommunityApiNotice =>
      'Powered by the community-maintained fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Powered by pretcarburant.ro (Competition Council + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country stations $km km away — €$price/L cheaper';
  }

  @override
  String get crossBorderTapToSwitch => 'Tap to switch country';

  @override
  String get crossBorderDismissTooltip => 'Dismiss';

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
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L saved';
  }

  @override
  String get ecoRouteHint =>
      'Smarter drive — favours steady highway over zigzag shortcuts.';

  @override
  String get favoritesShareAction => 'Share';

  @override
  String favoritesShareSubject(String date) {
    return 'Tankstellen — favourites on $date';
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
  String get featureLabel_unifiedSearchResults => 'Unified search results';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Single result list combining fuel and EV stations.';

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
  String featureBlockedDisable_autoRecord(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String get featureBlockedEnable_showFuel => 'Prerequisites not met';

  @override
  String featureBlockedDisable_showFuel(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String get featureBlockedEnable_showElectric => 'Prerequisites not met';

  @override
  String featureBlockedDisable_showElectric(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Enable OBD2 trip recording first';

  @override
  String featureBlockedDisable_showConsumptionTab(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String featureBlockedDisable_obd2TripRecording(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String featureBlockedDisable_tankSync(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

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
  String get scanPumpUnreadable => 'Pump display not readable — try again';

  @override
  String get scanPumpSuccess => 'Pump display scanned — verify the values.';

  @override
  String scanPumpFailed(String error) {
    return 'Pump scan failed: $error';
  }

  @override
  String get badScanReportTitle => 'Report a scan error';

  @override
  String get badScanReportTitleReceipt => 'Report a scan error — Receipt';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Report a scan error — Pump display';

  @override
  String get pumpScanFailureTitle => 'Display unreadable';

  @override
  String get pumpScanFailureBody =>
      'The scan couldn\'t read the pump display. What would you like to do?';

  @override
  String get pumpScanFailureCorrectManually => 'Correct manually';

  @override
  String get pumpScanFailureReport => 'Report';

  @override
  String get pumpScanFailureRemove => 'Remove photo';

  @override
  String get badScanReportHint =>
      'We\'ll share the receipt photo and both sets of values so the next build can learn this layout.';

  @override
  String get badScanReportShareAction => 'Share report + photo';

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
  String get fillUpSectionWhatTitle => 'What you filled';

  @override
  String get fillUpSectionWhatSubtitle => 'Fuel, amount, price';

  @override
  String get fillUpSectionWhereTitle => 'Where you were';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, odometer, notes';

  @override
  String get fillUpImportFromLabel => 'Import from…';

  @override
  String get fillUpImportSheetTitle => 'Import fill-up data';

  @override
  String get fillUpImportReceiptLabel => 'Receipt';

  @override
  String get fillUpImportReceiptDescription =>
      'Scan a paper receipt with the camera';

  @override
  String get fillUpImportPumpLabel => 'Pump display';

  @override
  String get fillUpImportPumpDescription =>
      'Read Betrag / Preis from the pump LCD';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Read odometer from the OBD-II port over Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Price per liter';

  @override
  String get vehicleHeaderPlateLabel => 'Plate';

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
  String get hapticEcoCoachSectionTitle => 'Driving';

  @override
  String get hapticEcoCoachSettingTitle => 'Real-time eco coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Gentle haptic + on-screen tip when you floor it during cruise';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Easy on the throttle — coasting saves more';

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
  String get mapDebugOverlayEnabledSnack => 'Map debug overlay enabled';

  @override
  String get mapDebugOverlayDisabledSnack => 'Map debug overlay disabled';

  @override
  String get mapDebugOverlayClearButton => 'Clear';

  @override
  String get mapDebugOverlayCloseButton => 'Close';

  @override
  String get mapDebugOverlayTitle => 'Map breadcrumbs';

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
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Couldn\'t reach \'$adapterName\' — pick another adapter';
  }

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
  String get onboardingObd2VinReadFailed =>
      'Couldn\'t read VIN — enter manually';

  @override
  String get onboardingObd2ConnectFailed =>
      'Couldn\'t connect to the adapter. You can retry or skip.';

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
  String get radiusAlertCenterFromMap => 'Map location';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel near $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'A station is at $price € (target: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/session';

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
  String get splashLoadingLabel => 'Loading Tankstellen';

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
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Last fill-up: $date · $count trip(s) since';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 measured';

  @override
  String get tankLevelMethodDistanceFallback => 'distance-based estimate';

  @override
  String get tankLevelMethodMixed => 'mixed measurement';

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
  String get trajetsRowColdStartChip => 'Cold start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Engine didn\'t reach operating temperature during this trip — fuel consumption was higher than usual.';

  @override
  String get trajetDetailChartEmpty => 'No samples recorded';

  @override
  String get trajetDetailShareAction => 'Share';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Tankstellen — trip on $date';
  }

  @override
  String get trajetDetailShareError => 'Couldn\'t generate share image';

  @override
  String get trajetDetailDeleteAction => 'Delete';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Delete this trip?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'This trip will be permanently removed from your history.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Cancel';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Delete';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapter connected but not returning data. Try a different adapter or check the vehicle\'s diagnostic protocol.';

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
  String get tripPathLegendTitle => 'Consumption';

  @override
  String get tripPathLegendEfficient => 'Efficient (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Borderline (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Wasteful (≥ 10 L/100km)';

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
  String get tripBannerOpenFromConsumptionTab =>
      'Open the active trip from the Conso tab';

  @override
  String get unifiedFilterFuel => 'Fuel';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Both';

  @override
  String get unifiedNoResultsForFilter => 'No results match this filter';

  @override
  String get vinLabel => 'VIN (optional)';

  @override
  String get vinDecodeTooltip => 'Decode VIN';

  @override
  String get vinConfirmAction => 'Yes, auto-fill';

  @override
  String get vinModifyAction => 'Modify manually';

  @override
  String get veResetAction => 'Reset volumetric efficiency';

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
      'Your VIN is stored only locally in the app\'s encrypted storage — it\'s never uploaded to Tankstellen servers. The NHTSA vPIC database is queried with the VIN but returns only anonymous technical specs; NHTSA does not link the VIN to any personal data. Without network, an offline lookup returns manufacturer and country only.';

  @override
  String get vinInfoSectionWhereTitle => 'Where to find it';

  @override
  String get vinInfoSectionWhereBody =>
      'Look through the windshield at the lower-left corner on the driver\'s side, check the driver-side door-frame sticker when the door is open, or read it off your vehicle registration document (card / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Got it';

  @override
  String get vinConfirmPrivacyNote =>
      'We looked up your VIN on NHTSA\'s free vehicle database — nothing sent to Tankstellen servers.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online decode';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Decode the VIN via NHTSA\'s free public service';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'When you pair an adapter, your vehicle\'s VIN is read locally to identify the car. Enabling this sends the 17-char VIN to NHTSA\'s free vPIC service to look up additional details (model, engine displacement, fuel type). The VIN is the only data sent — no other information leaves your device.';

  @override
  String get vehicleDetectedFromVinBadge => '(detected)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detected from VIN: $summary. Apply?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Apply';

  @override
  String get widgetVariantDefault => 'Current price only';

  @override
  String get widgetVariantPredictive => 'Predictive: best time to fill';

  @override
  String get widgetPredictiveNowPrefix => 'now';
}
