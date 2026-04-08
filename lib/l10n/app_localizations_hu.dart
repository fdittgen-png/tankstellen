// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Üzemanyagárak';

  @override
  String get search => 'Keresés';

  @override
  String get favorites => 'Kedvencek';

  @override
  String get map => 'Térkép';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Beállítások';

  @override
  String get gpsLocation => 'GPS helyzet';

  @override
  String get zipCode => 'Irányítószám';

  @override
  String get zipCodeHint => 'pl. 1011';

  @override
  String get fuelType => 'Üzemanyag';

  @override
  String get searchRadius => 'Sugár';

  @override
  String get searchNearby => 'Közeli kutak';

  @override
  String get searchButton => 'Keresés';

  @override
  String get noResults => 'Nem találhatók benzinkutak.';

  @override
  String get startSearch => 'Keressen benzinkutakat.';

  @override
  String get open => 'Nyitva';

  @override
  String get closed => 'Zárva';

  @override
  String distance(String distance) {
    return '$distance távolságra';
  }

  @override
  String get price => 'Ár';

  @override
  String get prices => 'Árak';

  @override
  String get address => 'Cím';

  @override
  String get openingHours => 'Nyitvatartás';

  @override
  String get open24h => 'Nonstop nyitva';

  @override
  String get navigate => 'Navigálás';

  @override
  String get retry => 'Újrapróbálás';

  @override
  String get apiKeySetup => 'API-kulcs';

  @override
  String get apiKeyDescription =>
      'Regisztráljon egyszer egy ingyenes API-kulcsért.';

  @override
  String get apiKeyLabel => 'API-kulcs';

  @override
  String get register => 'Regisztráció';

  @override
  String get continueButton => 'Tovább';

  @override
  String get welcome => 'Üzemanyagárak';

  @override
  String get welcomeSubtitle =>
      'Találja meg a legolcsóbb üzemanyagot a közelben.';

  @override
  String get profileName => 'Profil neve';

  @override
  String get preferredFuel => 'Preferált üzemanyag';

  @override
  String get defaultRadius => 'Alapértelmezett sugár';

  @override
  String get landingScreen => 'Kezdőképernyő';

  @override
  String get homeZip => 'Otthoni irányítószám';

  @override
  String get newProfile => 'Új profil';

  @override
  String get editProfile => 'Profil szerkesztése';

  @override
  String get save => 'Mentés';

  @override
  String get cancel => 'Mégse';

  @override
  String get delete => 'Törlés';

  @override
  String get activate => 'Aktiválás';

  @override
  String get configured => 'Beállítva';

  @override
  String get notConfigured => 'Nincs beállítva';

  @override
  String get about => 'Névjegy';

  @override
  String get openSource => 'Nyílt forráskód (MIT licenc)';

  @override
  String get sourceCode => 'Forráskód a GitHubon';

  @override
  String get noFavorites => 'Nincsenek kedvencek';

  @override
  String get noFavoritesHint =>
      'Érintse meg a csillagot egy kútnál a kedvencekhez adáshoz.';

  @override
  String get language => 'Nyelv';

  @override
  String get country => 'Ország';

  @override
  String get demoMode => 'Demó mód — mintaadatok.';

  @override
  String get setupLiveData => 'Élő adatok beállítása';

  @override
  String get freeNoKey => 'Ingyenes — kulcs nem szükséges';

  @override
  String get apiKeyRequired => 'API-kulcs szükséges';

  @override
  String get skipWithoutKey => 'Folytatás kulcs nélkül';

  @override
  String get dataTransparency => 'Adatátláthatóság';

  @override
  String get storageAndCache => 'Tárhely és gyorsítótár';

  @override
  String get clearCache => 'Gyorsítótár törlése';

  @override
  String get clearAllData => 'Összes adat törlése';

  @override
  String get errorLog => 'Hibanapló';

  @override
  String stationsFound(int count) {
    return '$count kút találva';
  }

  @override
  String get whatIsShared => 'Mi kerül megosztásra — és kivel?';

  @override
  String get gpsCoordinates => 'GPS-koordináták';

  @override
  String get gpsReason =>
      'Minden kereséssel elküldve a közeli kutak megtalálásához.';

  @override
  String get postalCodeData => 'Irányítószám';

  @override
  String get postalReason =>
      'Koordinátákká alakítva a geokódolási szolgáltatáson keresztül.';

  @override
  String get mapViewport => 'Térképnézet';

  @override
  String get mapReason =>
      'A térképcsempék a szerverről töltődnek be. Személyes adatok nem kerülnek továbbításra.';

  @override
  String get apiKeyData => 'API-kulcs';

  @override
  String get apiKeyReason =>
      'Személyes kulcsa minden API-kéréssel elküldésre kerül. Az e-mail címéhez van kötve.';

  @override
  String get notShared => 'NEM kerül megosztásra:';

  @override
  String get searchHistory => 'Keresési előzmények';

  @override
  String get favoritesData => 'Kedvencek';

  @override
  String get profileNames => 'Profilnevek';

  @override
  String get homeZipData => 'Otthoni irányítószám';

  @override
  String get usageData => 'Használati adatok';

  @override
  String get privacyBanner =>
      'Ennek az alkalmazásnak nincs szervere. Minden adat az eszközén marad. Nincs elemzés, nyomon követés vagy hirdetés.';

  @override
  String get storageUsage => 'Tárhelyhasználat ezen az eszközön';

  @override
  String get settingsLabel => 'Beállítások';

  @override
  String get profilesStored => 'profil mentve';

  @override
  String get stationsMarked => 'kút jelölve';

  @override
  String get cachedResponses => 'gyorsítótárazott válasz';

  @override
  String get total => 'Összesen';

  @override
  String get cacheManagement => 'Gyorsítótár kezelése';

  @override
  String get cacheDescription =>
      'A gyorsítótár API-válaszokat tárol a gyorsabb betöltés és offline hozzáférés érdekében.';

  @override
  String get stationSearch => 'Kútkeresés';

  @override
  String get stationDetails => 'Kút részletei';

  @override
  String get priceQuery => 'Árlekérdezés';

  @override
  String get zipGeocoding => 'Irányítószám geokódolás';

  @override
  String minutes(int n) {
    return '$n perc';
  }

  @override
  String hours(int n) {
    return '$n óra';
  }

  @override
  String get clearCacheTitle => 'Gyorsítótár törlése?';

  @override
  String get clearCacheBody =>
      'A tárolt keresési eredmények és árak törlődnek. A profilok, kedvencek és beállítások megmaradnak.';

  @override
  String get clearCacheButton => 'Gyorsítótár törlése';

  @override
  String get deleteAllTitle => 'Összes adat törlése?';

  @override
  String get deleteAllBody =>
      'Ez véglegesen törli az összes profilt, kedvencet, API-kulcsot, beállítást és gyorsítótárat. Az alkalmazás visszaáll.';

  @override
  String get deleteAllButton => 'Mindent töröl';

  @override
  String get entries => 'bejegyzés';

  @override
  String get cacheEmpty => 'A gyorsítótár üres';

  @override
  String get noStorage => 'Nincs felhasznált tárhely';

  @override
  String get apiKeyNote =>
      'Ingyenes regisztráció. Adatok a kormányzati ártranszparencia-ügynökségektől.';

  @override
  String get apiKeyFormatError =>
      'Érvénytelen formátum — UUID elvárva (8-4-4-4-12)';

  @override
  String get supportProject => 'Támogassa a projektet';

  @override
  String get supportDescription =>
      'Ez az alkalmazás ingyenes, nyílt forráskódú és reklámmentes. Ha hasznosnak találja, fontolja meg a fejlesztő támogatását.';

  @override
  String get reportBug => 'Hiba bejelentése / Funkció javaslata';

  @override
  String get privacyPolicy => 'Adatvédelmi irányelvek';

  @override
  String get fuels => 'Üzemanyagok';

  @override
  String get services => 'Szolgáltatások';

  @override
  String get zone => 'Zóna';

  @override
  String get highway => 'Autópálya';

  @override
  String get localStation => 'Helyi kút';

  @override
  String get lastUpdate => 'Utolsó frissítés';

  @override
  String get automate24h => '24ó/24 — Automata';

  @override
  String get refreshPrices => 'Árak frissítése';

  @override
  String get station => 'Benzinkút';

  @override
  String get locationDenied =>
      'Helymeghatározás megtagadva. Irányítószám alapján kereshet.';

  @override
  String get demoModeBanner =>
      'Demó mód. Állítsa be az API-kulcsot a beállításokban.';

  @override
  String get sortDistance => 'Távolság';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'olcsó';

  @override
  String get expensive => 'drága';

  @override
  String stationsOnMap(int count) {
    return '$count kút';
  }

  @override
  String get loadingFavorites =>
      'Kedvencek betöltése...\nElőször keressen kutakat az adatok mentéséhez.';

  @override
  String get reportPrice => 'Ár bejelentése';

  @override
  String get whatsWrong => 'Mi a probléma?';

  @override
  String get correctPrice => 'Helyes ár (pl. 1,459)';

  @override
  String get sendReport => 'Jelentés küldése';

  @override
  String get reportSent => 'Jelentés elküldve. Köszönjük!';

  @override
  String get enterValidPrice => 'Adjon meg egy érvényes árat';

  @override
  String get cacheCleared => 'Gyorsítótár törölve.';

  @override
  String get yourPosition => 'Az Ön pozíciója';

  @override
  String get positionUnknown => 'Pozíció ismeretlen';

  @override
  String get distancesFromCenter => 'Távolságok a keresés központjától';

  @override
  String get autoUpdatePosition => 'Pozíció automatikus frissítése';

  @override
  String get autoUpdateDescription =>
      'GPS-pozíció frissítése minden keresés előtt';

  @override
  String get location => 'Helyzet';

  @override
  String get switchProfileTitle => 'Ország megváltozott';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Most $country területén van. Váltás a(z) \"$profile\" profilra?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Átváltva a(z) \"$profile\" profilra ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Nincs profil ehhez az országhoz';

  @override
  String noProfileForCountry(String country) {
    return '$country területén van, de nincs beállított profil. Hozzon létre egyet a Beállításokban.';
  }

  @override
  String get autoSwitchProfile => 'Automatikus profilváltás';

  @override
  String get autoSwitchDescription =>
      'Profil automatikus váltása határátlépéskor';

  @override
  String get switchProfile => 'Váltás';

  @override
  String get dismiss => 'Bezárás';

  @override
  String get profileCountry => 'Ország';

  @override
  String get profileLanguage => 'Nyelv';

  @override
  String get settingsStorageDetail => 'API-kulcs, aktív profil';

  @override
  String get allFuels => 'Összes';

  @override
  String get priceAlerts => 'Ár riasztások';

  @override
  String get noPriceAlerts => 'Nincsenek ár riasztások';

  @override
  String get noPriceAlertsHint =>
      'Hozzon létre riasztást egy kút részletes oldalán.';

  @override
  String alertDeleted(String name) {
    return '\"$name\" riasztás törölve';
  }

  @override
  String get createAlert => 'Ár riasztás létrehozása';

  @override
  String currentPrice(String price) {
    return 'Aktuális ár: $price';
  }

  @override
  String get targetPrice => 'Célár (EUR)';

  @override
  String get enterPrice => 'Adjon meg egy árat';

  @override
  String get invalidPrice => 'Érvénytelen ár';

  @override
  String get priceTooHigh => 'Az ár túl magas';

  @override
  String get create => 'Létrehozás';

  @override
  String get alertCreated => 'Ár riasztás létrehozva';

  @override
  String get wrongE5Price => 'Hibás Super E5 ár';

  @override
  String get wrongE10Price => 'Hibás Super E10 ár';

  @override
  String get wrongDieselPrice => 'Hibás dízel ár';

  @override
  String get wrongStatusOpen => 'Nyitottnak jelölve, de zárva van';

  @override
  String get wrongStatusClosed => 'Zártnak jelölve, de nyitva van';

  @override
  String get searchAlongRouteLabel => 'Útvonal mentén';

  @override
  String get searchEvStations => 'Töltőállomások keresése';

  @override
  String get allStations => 'Összes állomás';

  @override
  String get bestStops => 'Legjobb megállók';

  @override
  String get openInMaps => 'Megnyitás Térképben';

  @override
  String get noStationsAlongRoute =>
      'Nem találhatók állomások az útvonal mentén';

  @override
  String get evOperational => 'Üzemel';

  @override
  String get evStatusUnknown => 'Állapot ismeretlen';

  @override
  String evConnectors(int count) {
    return 'Csatlakozók ($count pont)';
  }

  @override
  String get evNoConnectors => 'Nincsenek csatlakozó részletek';

  @override
  String get evUsageCost => 'Használati költség';

  @override
  String get evPricingUnavailable => 'Árazás nem elérhető a szolgáltatótól';

  @override
  String get evLastUpdated => 'Utoljára frissítve';

  @override
  String get evUnknown => 'Ismeretlen';

  @override
  String get evDataAttribution =>
      'Adatok az OpenChargeMap-ból (közösségi forrás)';

  @override
  String get evStatusDisclaimer =>
      'Az állapot nem feltétlenül tükrözi a valós idejű elérhetőséget. Érintse meg a frissítést a legújabb adatokhoz.';

  @override
  String get evNavigateToStation => 'Navigálás az állomáshoz';

  @override
  String get evRefreshStatus => 'Állapot frissítése';

  @override
  String get evStatusUpdated => 'Állapot frissítve';

  @override
  String get evStationNotFound =>
      'Nem sikerült frissíteni — állomás nem található a közelben';

  @override
  String get addedToFavorites => 'Hozzáadva a kedvencekhez';

  @override
  String get removedFromFavorites => 'Eltávolítva a kedvencekből';

  @override
  String get addFavorite => 'Hozzáadás a kedvencekhez';

  @override
  String get removeFavorite => 'Eltávolítás a kedvencekből';

  @override
  String get currentLocation => 'Jelenlegi helyzet';

  @override
  String get gpsError => 'GPS hiba';

  @override
  String get couldNotResolve =>
      'Nem sikerült feloldani a kiindulást vagy a célt';

  @override
  String get start => 'Indulás';

  @override
  String get destination => 'Úticél';

  @override
  String get cityAddressOrGps => 'Város, cím vagy GPS';

  @override
  String get cityOrAddress => 'Város vagy cím';

  @override
  String get useGps => 'GPS használata';

  @override
  String get stop => 'Megálló';

  @override
  String stopN(int n) {
    return 'Megálló $n';
  }

  @override
  String get addStop => 'Megálló hozzáadása';

  @override
  String get searchAlongRoute => 'Keresés az útvonal mentén';

  @override
  String get cheapest => 'Legolcsóbb';

  @override
  String nStations(int count) {
    return '$count kút';
  }

  @override
  String nBest(int count) {
    return '$count legjobb';
  }

  @override
  String get fuelPricesTankerkoenig => 'Üzemanyagárak (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Szükséges az üzemanyag-árkereséshez Németországban';

  @override
  String get evChargingOpenChargeMap => 'EV töltés (OpenChargeMap)';

  @override
  String get customKey => 'Egyéni kulcs';

  @override
  String get appDefaultKey => 'Alkalmazás alapértelmezett kulcsa';

  @override
  String get optionalOverrideKey =>
      'Opcionális: a beépített alkalmazáskulcs felülírása sajáttal';

  @override
  String get requiredForEvSearch => 'Szükséges az EV töltőállomás kereséséhez';

  @override
  String get edit => 'Szerkesztés';

  @override
  String get fuelPricesApiKey => 'Üzemanyagárak API-kulcs';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-kulcs';

  @override
  String get evChargingApiKey => 'EV töltés API-kulcs';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-kulcs';

  @override
  String get routeSegment => 'Útvonalszakasz';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Legolcsóbb kút mutatása $km km-enként az útvonal mentén';
  }

  @override
  String get avoidHighways => 'Autópályák elkerülése';

  @override
  String get avoidHighwaysDesc =>
      'Az útvonaltervezés elkerüli a fizetős utakat és autópályákat';

  @override
  String get showFuelStations => 'Benzinkutak mutatása';

  @override
  String get showFuelStationsDesc => 'Benzin, dízel, LPG, CNG kutak bevonása';

  @override
  String get showEvStations => 'Töltőállomások mutatása';

  @override
  String get showEvStationsDesc =>
      'Elektromos töltőállomások bevonása a keresési eredményekbe';

  @override
  String get noStationsAlongThisRoute =>
      'Nem találhatók állomások ezen útvonal mentén.';

  @override
  String get fuelCostCalculator => 'Üzemanyagköltség-kalkulátor';

  @override
  String get distanceKm => 'Távolság (km)';

  @override
  String get consumptionL100km => 'Fogyasztás (L/100km)';

  @override
  String get fuelPriceEurL => 'Üzemanyag ára (EUR/L)';

  @override
  String get tripCost => 'Útköltség';

  @override
  String get fuelNeeded => 'Szükséges üzemanyag';

  @override
  String get totalCost => 'Összköltség';

  @override
  String get enterCalcValues =>
      'Adja meg a távolságot, fogyasztást és árat az útköltség kiszámításához';

  @override
  String get priceHistory => 'Ártörténet';

  @override
  String get noPriceHistory => 'Még nincs ártörténet';

  @override
  String get noHourlyData => 'Nincsenek óránkénti adatok';

  @override
  String get noStatistics => 'Nincsenek elérhető statisztikák';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Átl';

  @override
  String get showAllFuelTypes => 'Összes üzemanyagtípus mutatása';

  @override
  String get connected => 'Csatlakoztatva';

  @override
  String get notConnected => 'Nincs csatlakoztatva';

  @override
  String get connectTankSync => 'TankSync csatlakoztatása';

  @override
  String get disconnectTankSync => 'TankSync leválasztása';

  @override
  String get viewMyData => 'Adataim megtekintése';

  @override
  String get optionalCloudSync =>
      'Opcionális felhőszinkronizálás riasztásokhoz, kedvencekhez és push értesítésekhez';

  @override
  String get tapToUpdateGps => 'Érintse meg a GPS-pozíció frissítéséhez';

  @override
  String get gpsAutoUpdateHint =>
      'A GPS-pozíció automatikusan lekérdezésre kerül kereséskor. Itt manuálisan is frissítheti.';

  @override
  String get clearGpsConfirm =>
      'Tárolt GPS-pozíció törlése? Bármikor frissítheti újra.';

  @override
  String get pageNotFound => 'Az oldal nem található';

  @override
  String get deleteAllServerData => 'Összes szerveradat törlése';

  @override
  String get deleteServerDataConfirm => 'Törli az összes szerveradatot?';

  @override
  String get deleteEverything => 'Mindent töröl';

  @override
  String get allDataDeleted => 'Összes szerveradat törölve';

  @override
  String get disconnectConfirm => 'TankSync leválasztása?';

  @override
  String get disconnect => 'Leválasztás';

  @override
  String get myServerData => 'Szerveradataim';

  @override
  String get anonymousUuid => 'Anonim UUID';

  @override
  String get server => 'Szerver';

  @override
  String get syncedData => 'Szinkronizált adatok';

  @override
  String get pushTokens => 'Push tokenek';

  @override
  String get priceReports => 'Árjelentések';

  @override
  String get totalItems => 'Összes elem';

  @override
  String get estimatedSize => 'Becsült méret';

  @override
  String get viewRawJson => 'Nyers adatok megtekintése JSON-ként';

  @override
  String get exportJson => 'Exportálás JSON-ként (vágólap)';

  @override
  String get jsonCopied => 'JSON vágólapra másolva';

  @override
  String get rawDataJson => 'Nyers adatok (JSON)';

  @override
  String get close => 'Bezárás';

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
  String get alertStatsActive => 'Aktív';

  @override
  String get alertStatsToday => 'Ma';

  @override
  String get alertStatsThisWeek => 'Ezen a héten';

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
}
