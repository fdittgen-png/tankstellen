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
}
