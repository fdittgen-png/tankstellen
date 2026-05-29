// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Keresés megnyitása';

  @override
  String get fabOpenResults => 'Eredmények megnyitása';

  @override
  String get fabRunSearch => 'Keresés futtatása';

  @override
  String get fabRefineCriteria => 'Keresés finomítása';

  @override
  String get routeSearchPartialBanner => 'További állomások keresése…';

  @override
  String get searchCriteriaTitle => 'Keresési feltételek';

  @override
  String get searchCriteriaOpen => 'Keresés';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km-en belül';
  }

  @override
  String get searchCriteriaTapToSearch => 'Érintsen a keresés megkezdéséhez';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Ország váltása?';

  @override
  String countryChangeBody(String country) {
    return 'A(z) $country országra való váltás a következőket módosítja:';
  }

  @override
  String get countryChangeCurrency => 'Pénznem';

  @override
  String get countryChangeDistance => 'Távolság';

  @override
  String get countryChangeVolume => 'Térfogat';

  @override
  String get countryChangePricePerUnit => 'Árformátum';

  @override
  String get countryChangeNote =>
      'A meglévő kedvencek és tankolási naplók nem íródnak át; csak az új bejegyzések használják az új egységeket.';

  @override
  String get countryChangeConfirm => 'Váltás';

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
  String get cacheTtlGroupNetwork => 'Hálózat';

  @override
  String get cacheTtlGroupData => 'Adatok';

  @override
  String get cacheTtlGroupGeocoding => 'Geokódolás';

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
  String get reportThisIssue => 'Probléma jelentése';

  @override
  String get reportAlreadySent => 'Ezt a problémát már bejelentette.';

  @override
  String get reportConsentTitle => 'Bejelentés GitHub-ra?';

  @override
  String get reportConsentBody =>
      'Ez egy nyilvános GitHub-hibajegyet nyit meg az alábbi hibarészletekkel. Nem kerül bele GPS-koordináta, API-kulcs vagy személyes adat.';

  @override
  String get reportConsentConfirm => 'GitHub megnyitása';

  @override
  String get reportConsentCancel => 'Mégse';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktív profil';

  @override
  String get configPreferredFuel => 'Előnyben részesített üzemanyag';

  @override
  String get configCountry => 'Ország';

  @override
  String get configRouteSegment => 'Útvonal-szakasz';

  @override
  String get configApiKeysSection => 'API-kulcsok';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-kulcs';

  @override
  String get configApiKeyConfigured => 'Beállítva';

  @override
  String get configApiKeyNotSet => 'Nincs megadva (demó mód)';

  @override
  String get configApiKeyCommunity => 'Alapértelmezett (közösségi kulcs)';

  @override
  String get searchLocationPlaceholder => 'Cím, irányítószám vagy város';

  @override
  String get configEvKey => 'EV töltési API-kulcs';

  @override
  String get configEvKeyCustom => 'Egyéni kulcs';

  @override
  String get configEvKeyShared => 'Alapértelmezett (megosztott)';

  @override
  String get configCloudSyncSection => 'Felhőszinkronizálás';

  @override
  String get configTankSyncConnected => 'Csatlakoztatva';

  @override
  String get configTankSyncDisabled => 'Letiltva';

  @override
  String get configAuthMode => 'Hitelesítési mód';

  @override
  String get configAuthEmail => 'E-mail (tartós)';

  @override
  String get configAuthAnonymous => 'Névtelen (csak eszköz)';

  @override
  String get configDatabase => 'Adatbázis';

  @override
  String get configPrivacySummary => 'Adatvédelmi összefoglaló';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• A kedvencek, riasztások és figyelmen kívül hagyott állomások szinkronizálódnak a privát adatbázisba\n• A GPS-pozíció és az API-kulcsok soha nem hagyják el az eszközt\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Az összes adat csak ezen az eszközön tárolódik\n• Nem kerül adat semmilyen szerverre\n• Az API-kulcsok titkosítva vannak az eszköz biztonságos tárolójában';

  @override
  String get configAuthNoteEmail =>
      'Az e-mail fiók lehetővé teszi a több eszközről való hozzáférést';

  @override
  String get configAuthNoteAnonymous =>
      'Névtelen fiók — az adatok ehhez az eszközhöz kötöttek';

  @override
  String get configNone => 'Nincs';

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
  String get demoModeBannerAction => 'Élő árak megtekintése';

  @override
  String get sortDistance => 'Távolság';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Értékelés';

  @override
  String get sortPriceDistance => 'Ár/km';

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
  String get routeModeBannerLabel =>
      'Útvonal mód — a távolságok az útvonal mentén';

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
  String get routePlanningSection => 'Útvonaltervezés';

  @override
  String get routeMinSaving => 'Minimális megtakarítás';

  @override
  String get routeMinSavingOff => 'Ki';

  @override
  String get routeMinSavingOffCaption =>
      'Az útvonalon talált összes állomás megjelenítése';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Csak az útvonal legolcsóbb állomásától $amount értéken belüli állomások';
  }

  @override
  String get routeDetourBudget => 'Maximális kerülő';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Állomások megjelenítése legfeljebb $km km-re a közvetlen útvonaltól';
  }

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
  String get ignoredStationsLabel => 'Mellőzött';

  @override
  String get ratingsLabel => 'Értékelések';

  @override
  String get favoritesDataCache => 'Kedvencek adatai';

  @override
  String get citySearchCache => 'Városkeresés';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Az adatok törlése nem érhető el a Közösségi módban. Először kapcsolódjon le, vagy használjon privát adatbázist.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count követett kút';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count beállítva';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count rejtett kút';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count értékelt kút';
  }

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
  String get forgetAllSyncedTripsButton => 'Összes szinkronizált út törlése';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Törli az összes szinkronizált utat?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Az összes út-összefoglaló és részletadat törlődik a szerverről. Az ezen az eszközön tárolt helyi útnapló nem érintett.\n\nEz a művelet nem vonható vissza.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Összes törlése';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Az összes szinkronizált út eltávolítva a szerverről';

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
  String get syncedTrips => 'Utak';

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
  String get account => 'Fiók';

  @override
  String get continueAsGuest => 'Folytatás vendégként';

  @override
  String get createAccount => 'Fiók létrehozása';

  @override
  String get signIn => 'Bejelentkezés';

  @override
  String get upgradeToEmail => 'E-mail fiók létrehozása';

  @override
  String get savedRoutes => 'Mentett útvonalak';

  @override
  String get noSavedRoutes => 'Nincsenek mentett útvonalak';

  @override
  String get noSavedRoutesHint =>
      'Keresés egy útvonalon, majd mentse el a gyors eléréshez.';

  @override
  String get saveRoute => 'Útvonal mentése';

  @override
  String get routeName => 'Útvonal neve';

  @override
  String itineraryDeleted(String name) {
    return '$name törölve';
  }

  @override
  String loadingRoute(String name) {
    return 'Útvonal betöltése: $name';
  }

  @override
  String get refreshFailed => 'A frissítés sikertelen. Kérjük, próbálja újra.';

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
  String get onboardingWelcomeHint =>
      'Állítsa be az alkalmazást néhány gyors lépésben.';

  @override
  String get onboardingApiKeyDescription =>
      'Regisztráljon egy ingyenes API-kulcsért, vagy ugorja át, hogy demó adatokkal fedezze fel az alkalmazást.';

  @override
  String get onboardingComplete => 'Minden kész!';

  @override
  String get onboardingCompleteHint =>
      'Ezeket a beállításokat bármikor megváltoztathatja a profiljában.';

  @override
  String get onboardingBack => 'Vissza';

  @override
  String get onboardingNext => 'Tovább';

  @override
  String get onboardingSkip => 'Kihagyás';

  @override
  String get onboardingFinish => 'Kezdjük el';

  @override
  String crossBorderNearby(String country) {
    return '$country a közelben van';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km a határig';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Átlagár itt: $price EUR ($count állomás)';
  }

  @override
  String get allPricesView => 'Összes ár';

  @override
  String get compactView => 'Kompakt';

  @override
  String get switchToAllPricesView => 'Váltás az összes áras nézetre';

  @override
  String get switchToCompactView => 'Váltás kompakt nézetre';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Elfogyott';

  @override
  String get gdprTitle => 'Az Ön adatvédelme';

  @override
  String get gdprSubtitle =>
      'Ez az alkalmazás tiszteli az Ön adatait. Válassza ki, milyen adatokat kíván megosztani. Ezeket a beállításokat bármikor megváltoztathatja.';

  @override
  String get gdprLocationTitle => 'Helyadat-hozzáférés';

  @override
  String get gdprLocationDescription =>
      'A koordinátáit elküldik az üzemanyagár API-nak a közeli állomások megtalálásához. A helyadatokat soha nem tároljuk szerveren, és nem használjuk nyomon követésre.';

  @override
  String get gdprLocationShort =>
      'Közeli üzemanyag-állomások keresése az Ön helyadatai alapján';

  @override
  String get gdprErrorReportingTitle => 'Hibajelentés';

  @override
  String get gdprErrorReportingDescription =>
      'Az anonim összeomlásjelentések segítenek javítani az alkalmazáson. Nem tartalmaz személyes adatot. A jelentések csak akkor kerülnek elküldésre Sentry-n keresztül, ha be van állítva.';

  @override
  String get gdprErrorReportingShort =>
      'Anonim összeomlásjelentések küldése az alkalmazás fejlesztéséhez';

  @override
  String get gdprCloudSyncTitle => 'Felhőszinkronizálás';

  @override
  String get gdprCloudSyncDescription =>
      'Kedvencek és riasztások szinkronizálása az eszközök között TankSync segítségével. Névtelen hitelesítést használ. Az adatok titkosítva kerülnek átvitelre.';

  @override
  String get gdprCloudSyncShort =>
      'Kedvencek és riasztások szinkronizálása az eszközök között';

  @override
  String get gdprLegalBasis =>
      'Jogalap: GDPR 6. cikk (1) bekezdés a) pont (hozzájárulás). A hozzájárulást bármikor visszavonhatja a Beállításokban.';

  @override
  String get gdprAcceptAll => 'Összes elfogadása';

  @override
  String get gdprAcceptSelected => 'Kiválasztottak elfogadása';

  @override
  String get gdprSettingsHint =>
      'Adatvédelmi beállításait bármikor módosíthatja.';

  @override
  String get routeSaved => 'Útvonal mentve!';

  @override
  String get routeSaveFailed => 'Az útvonal mentése sikertelen';

  @override
  String get sqlCopied => 'SQL vágólapra másolva';

  @override
  String get connectionDataCopied => 'Kapcsolati adatok másolva';

  @override
  String get accountDeleted => 'Fiók törölve. A helyi adatok megmaradtak.';

  @override
  String get switchedToAnonymous => 'Névtelen munkamenetre váltva';

  @override
  String failedToSwitch(String error) {
    return 'A váltás sikertelen: $error';
  }

  @override
  String get topicUrlCopied => 'Téma URL-je másolva';

  @override
  String get testNotificationSent => 'Teszt értesítés elküldve!';

  @override
  String get testNotificationFailed => 'A teszt értesítés küldése sikertelen';

  @override
  String get pushUpdateFailed =>
      'A leküldéses értesítési beállítás frissítése sikertelen';

  @override
  String get connectedAsGuest => 'Csatlakozva vendégként';

  @override
  String get accountCreated => 'Fiók létrehozva!';

  @override
  String get signedIn => 'Bejelentkezve!';

  @override
  String stationHidden(String name) {
    return '$name elrejtve';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name eltávolítva a kedvencekből';
  }

  @override
  String invalidApiKey(String error) {
    return 'Érvénytelen API-kulcs: $error';
  }

  @override
  String get invalidQrCode => 'Érvénytelen QR-kód formátum';

  @override
  String get invalidQrCodeTankSync =>
      'Érvénytelen QR-kód — TankSync formátum várható';

  @override
  String get tankSyncConnected => 'TankSync csatlakoztatva!';

  @override
  String get syncCompleted => 'Szinkronizálás kész — adatok frissítve';

  @override
  String get deviceCodeCopied => 'Eszközkód másolva';

  @override
  String get undo => 'Visszavonás';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Adjon meg érvényes $length jegyű $label';
  }

  @override
  String get freshnessAgo => 'ezelőtt';

  @override
  String get freshnessStale => 'Elavult';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Adatok frissessége: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand logó';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count csillag értékelése',
      one: '1 csillag értékelése',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Gyenge';

  @override
  String get passwordStrengthFair => 'Közepes';

  @override
  String get passwordStrengthStrong => 'Erős';

  @override
  String get passwordReqMinLength => 'Legalább 8 karakter';

  @override
  String get passwordReqUppercase => 'Legalább 1 nagybetű';

  @override
  String get passwordReqLowercase => 'Legalább 1 kisbetű';

  @override
  String get passwordReqDigit => 'Legalább 1 szám';

  @override
  String get passwordReqSpecial => 'Legalább 1 speciális karakter';

  @override
  String get passwordTooWeak =>
      'A jelszó nem felel meg az összes követelménynek';

  @override
  String get brandFilterAll => 'Összes';

  @override
  String get brandFilterNoHighway => 'Autópálya nélkül';

  @override
  String get swipeTutorialMessage =>
      'Csúsztasson jobbra a navigáláshoz, balra a törléshez';

  @override
  String get swipeTutorialDismiss => 'Értem';

  @override
  String get alertStatsActive => 'Aktív';

  @override
  String get alertStatsToday => 'Ma';

  @override
  String get alertStatsThisWeek => 'Ezen a héten';

  @override
  String get privacyDashboardTitle => 'Adatvédelmi irányítópult';

  @override
  String get privacyDashboardSubtitle =>
      'Adatok megtekintése, exportálása vagy törlése';

  @override
  String get privacyDashboardBanner =>
      'Az adatai az Öné. Itt megtekintheti az alkalmazás által tárolt összes adatot, exportálhatja vagy törölheti azokat.';

  @override
  String get privacyLocalData => 'Adatok ezen az eszközön';

  @override
  String get privacyIgnoredStations => 'Figyelmen kívül hagyott állomások';

  @override
  String get privacyRatings => 'Állomásértékelések';

  @override
  String get privacyPriceHistory => 'Ártörténeti állomások';

  @override
  String get privacyProfiles => 'Keresési profilok';

  @override
  String get privacyItineraries => 'Mentett útvonalak';

  @override
  String get privacyCacheEntries => 'Gyorsítótár-bejegyzések';

  @override
  String get privacyApiKey => 'Tárolt API-kulcs';

  @override
  String get privacyEvApiKey => 'Tárolt EV API-kulcs';

  @override
  String get privacyEstimatedSize => 'Becsült tárterület';

  @override
  String get privacySyncedData => 'Felhőszinkronizálás (TankSync)';

  @override
  String get privacySyncDisabled =>
      'A felhőszinkronizálás le van tiltva. Az összes adat csak ezen az eszközön marad.';

  @override
  String get privacySyncMode => 'Szinkronizálási mód';

  @override
  String get privacySyncUserId => 'Felhasználói azonosító';

  @override
  String get privacySyncDescription =>
      'Ha a szinkronizálás engedélyezve van, a kedvencek, riasztások, figyelmen kívül hagyott állomások és értékelések szintén a TankSync szerveren tárolódnak.';

  @override
  String get privacyViewServerData => 'Szerveradatok megtekintése';

  @override
  String get privacyExportButton => 'Összes adat exportálása JSON-ként';

  @override
  String get privacyExportSuccess => 'Adatok exportálva a vágólapra';

  @override
  String get privacyExportCsvButton => 'Összes adat exportálása CSV-ként';

  @override
  String get privacyExportCsvSuccess => 'CSV-adatok exportálva a vágólapra';

  @override
  String get savedToDownloadsFolder => 'Mentve a Letöltések mappába';

  @override
  String get privacyDeleteButton => 'Összes adat törlése';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Hibanapló másolása a vágólapra ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Hibanapló mentése ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Hibanapló törlése';

  @override
  String get privacyErrorLogCleared => 'Hibanapló törölve';

  @override
  String get privacyDeleteTitle => 'Törli az összes adatot?';

  @override
  String get privacyDeleteBody =>
      'Ez véglegesen törli:\n\n- Az összes kedvencet és állomásadatot\n- Az összes keresési profilt\n- Az összes áriasztást\n- Az összes ártörténetet\n- Az összes gyorsítótárazott adatot\n- Az Ön API-kulcsát\n- Az összes alkalmazásbeállítást\n\nAz alkalmazás visszaáll a kezdeti állapotára. Ez a művelet nem vonható vissza.';

  @override
  String get privacyDeleteConfirm => 'Mindent töröl';

  @override
  String get yes => 'Igen';

  @override
  String get no => 'Nem';

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
  String get paymentMethods => 'Fizetési módok';

  @override
  String get paymentMethodCash => 'Készpénz';

  @override
  String get paymentMethodCard => 'Kártya';

  @override
  String get paymentMethodContactless => 'Érintésmentes';

  @override
  String get paymentMethodFuelCard => 'Üzemanyagkártya';

  @override
  String get paymentMethodApp => 'Alkalmazás';

  @override
  String payWithApp(String app) {
    return 'Fizetés ezzel: $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Összehasonlítva az utolsó 3 tankolás gördülő átlagával ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Fogyasztás: $value L/100 km, $delta a gördülő átlaghoz képest';
  }

  @override
  String get drivingMode => 'Vezetési mód';

  @override
  String get drivingExit => 'Kilépés';

  @override
  String get drivingNearestStation => 'Legközelebbi';

  @override
  String get drivingTapToUnlock => 'Érintsen a feloldáshoz';

  @override
  String get drivingSafetyTitle => 'Biztonsági figyelmeztetés';

  @override
  String get drivingSafetyMessage =>
      'Ne használja az alkalmazást vezetés közben. Álljon le biztonságos helyen, mielőtt a képernyővel interakcióba lép. A vezető mindenkor felelős a jármű biztonságos üzemeltetéséért.';

  @override
  String get drivingSafetyAccept => 'Értem';

  @override
  String get voiceAnnouncementsTitle => 'Hangos bejelentések';

  @override
  String get voiceAnnouncementsDescription =>
      'Közeli olcsó állomások bejelentése vezetés közben';

  @override
  String get voiceAnnouncementsEnabled => 'Hangos bejelentések engedélyezése';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Csak $price alatt';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilométerre előre, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Bejelentési sugár';

  @override
  String get voiceAnnouncementCooldown => 'Ismétlési intervallum';

  @override
  String get nearestStations => 'Legkozelebbi kutjak';

  @override
  String get nearestStationsHint =>
      'Talalja meg a legkozelebbi kutjakat a jelenlegi helyzete alapjan';

  @override
  String get consumptionLogTitle => 'Üzemanyag-fogyasztás';

  @override
  String get consumptionLogMenuTitle => 'Fogyasztási napló';

  @override
  String get consumptionLogMenuSubtitle =>
      'Tankolások követése és L/100km kiszámítása';

  @override
  String get consumptionStatsTitle => 'Fogyasztási statisztikák';

  @override
  String get addFillUp => 'Tankolás hozzáadása';

  @override
  String get noFillUpsTitle => 'Még nincs tankolás';

  @override
  String get noFillUpsSubtitle =>
      'Rögzítse az első tankolását a fogyasztás követésének megkezdéséhez.';

  @override
  String get fillUpDate => 'Dátum';

  @override
  String get liters => 'Liter';

  @override
  String get odometerKm => 'Kilométer-számláló (km)';

  @override
  String get notesOptional => 'Megjegyzések (opcionális)';

  @override
  String get stationPreFilled => 'Állomás előre kitöltve';

  @override
  String get statAvgConsumption => 'Átl. L/100km';

  @override
  String get statAvgCostPerKm => 'Átl. költség/km';

  @override
  String get statTotalLiters => 'Összesen liter';

  @override
  String get statTotalSpent => 'Összesen elköltve';

  @override
  String get statFillUpCount => 'Tankolások';

  @override
  String get fieldRequired => 'Kötelező';

  @override
  String get fieldInvalidNumber => 'Érvénytelen szám';

  @override
  String get carbonDashboardTitle => 'Szén-dioxid irányítópult';

  @override
  String get carbonEmptyTitle => 'Még nincs adat';

  @override
  String get carbonEmptySubtitle =>
      'Rögzítsen tankolásokat a szén-dioxid irányítópult megtekintéséhez.';

  @override
  String get carbonSummaryTotalCost => 'Összes költség';

  @override
  String get carbonSummaryTotalCo2 => 'Összesen CO2';

  @override
  String get monthlyCostsTitle => 'Havi költségek';

  @override
  String get monthlyEmissionsTitle => 'Havi CO2-kibocsátás';

  @override
  String get vehiclesTitle => 'Járműveim';

  @override
  String get vehiclesMenuTitle => 'Járműveim';

  @override
  String get vehiclesMenuSubtitle =>
      'Akkumulátor, csatlakozók, töltési beállítások';

  @override
  String get vehiclesEmptyMessage =>
      'Adja hozzá autóját a csatlakozó szerinti szűréshez és a töltési költségek becsléséhez.';

  @override
  String get vehiclesWizardTitle => 'Járműveim (opcionális)';

  @override
  String get vehiclesWizardSubtitle =>
      'Adja hozzá autóját a fogyasztási napló előre kitöltéséhez és az EV-csatlakozó-szűrők engedélyezéséhez. Ezt kihagyhatja, és később adhat hozzá járműveket.';

  @override
  String get vehiclesWizardNoneYet => 'Még nincs jármű beállítva.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count járműve',
      one: '1 járműve',
    );
    return 'Önnek $_temp0 van:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Kihagyja a befejezéshez — járműveket bármikor hozzáadhat a Beállításokban.';

  @override
  String get fillUpVehicleLabel => 'Jármű';

  @override
  String get fillUpVehicleNone => 'Nincs jármű';

  @override
  String get fillUpVehicleRequired => 'Jármű megadása kötelező';

  @override
  String get reportScanError => 'Beolvasási hiba jelentése';

  @override
  String get pickStationTitle => 'Állomás kiválasztása';

  @override
  String get pickStationHelper =>
      'Kezdje el a tankolást egy ismert állomástól, hogy az árak, a márka és az üzemanyag típusa automatikusan kitöltődjön.';

  @override
  String get pickStationEmpty =>
      'Még nincsenek kedvenc állomások — adjon hozzá néhányat a Keresésből vagy a Kedvencekből, vagy ugorja át és töltse ki manuálisan.';

  @override
  String get pickStationSkip => 'Kihagyás — hozzáadás állomás nélkül';

  @override
  String get scanPump => 'Kút beolvasása';

  @override
  String get scanPayment => 'Fizetési QR beolvasása';

  @override
  String get qrPaymentBeneficiary => 'Kedvezményezett';

  @override
  String get qrPaymentAmount => 'Összeg';

  @override
  String get qrPaymentEpcTitle => 'SEPA-átutalás';

  @override
  String get qrPaymentEpcEmpty => 'Nem sikerült mezőket dekódolni';

  @override
  String get qrPaymentOpenInBank => 'Megnyitás a banki appban';

  @override
  String get qrPaymentLaunchFailed =>
      'Nincs elérhető alkalmazás a kód megnyitásához';

  @override
  String get qrPaymentUnknownTitle => 'Ismeretlen kód';

  @override
  String get qrPaymentCopyRaw => 'Nyers szöveg másolása';

  @override
  String get qrPaymentCopiedRaw => 'Vágólapra másolva';

  @override
  String get qrPaymentReport => 'Beolvasás jelentése';

  @override
  String get qrPaymentEpcCopied =>
      'Banki adatok másolva — illessze be a banki alkalmazásba';

  @override
  String get qrScannerGuidance => 'Irányítsa a kamerát a QR-kódra';

  @override
  String get qrScannerPermissionDenied =>
      'A QR-kódok beolvasásához kamerához való hozzáférés szükséges.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'A kamera-hozzáférés meg lett tagadva. Nyissa meg a beállításokat az engedélyezéshez.';

  @override
  String get qrScannerRetryPermission => 'Próbálja újra';

  @override
  String get qrScannerOpenSettings => 'Beállítások megnyitása';

  @override
  String get qrScannerTimeout =>
      'Nem észleltek QR-kódot. Közelítsen, vagy próbálja újra.';

  @override
  String get qrScannerRetry => 'Próbálja újra';

  @override
  String get torchOn => 'Vaku bekapcsolása';

  @override
  String get torchOff => 'Vaku kikapcsolása';

  @override
  String get obdNoAdapter => 'Nincs OBD2-adapter a hatótávolságban';

  @override
  String get obdOdometerUnavailable =>
      'Nem sikerült olvasni a kilométer-számlálót';

  @override
  String get obdPermissionDenied =>
      'Adjon Bluetooth-engedélyt a rendszerbeállításokban';

  @override
  String get obdAdapterUnresponsive =>
      'Az adapter nem válaszolt — kapcsolja be a gyújtást, és próbálja újra';

  @override
  String get obdPickerTitle => 'OBD2-adapter kiválasztása';

  @override
  String get obdPickerScanning => 'Adapterek keresése…';

  @override
  String get obdPickerConnecting => 'Csatlakozás…';

  @override
  String get themeSettingTitle => 'Téma';

  @override
  String get themeModeLight => 'Világos';

  @override
  String get themeModeDark => 'Sötét';

  @override
  String get themeModeSystem => 'Rendszer szerint';

  @override
  String get tripRecordingTitle => 'Út rögzítése';

  @override
  String get tripSummaryTitle => 'Út összefoglalója';

  @override
  String get tripMetricDistance => 'Távolság';

  @override
  String get tripMetricSpeed => 'Sebesség';

  @override
  String get tripMetricFuelUsed => 'Felhasznált üzemanyag';

  @override
  String get tripMetricAvgConsumption => 'Átl.';

  @override
  String get tripMetricElapsed => 'Eltelt idő';

  @override
  String get tripMetricOdometer => 'Kilométer-számláló';

  @override
  String get tripStop => 'Rögzítés leállítása';

  @override
  String get tripPause => 'Szünet';

  @override
  String get tripResume => 'Folytatás';

  @override
  String get tripBannerRecording => 'Út rögzítése folyamatban';

  @override
  String get tripBannerPaused => 'Út szüneteltetve — érintsen a folytatáshoz';

  @override
  String get navConsumption => 'Fogyasztás';

  @override
  String get vehicleBaselineSectionTitle => 'Alapvonal-kalibráció';

  @override
  String get vehicleBaselineEmpty =>
      'Még nincsenek minták — indítson OBD2-utat a jármű üzemanyag-profiljának megtanulásához.';

  @override
  String get vehicleBaselineProgress =>
      'Különböző vezetési helyzetekből tanult minták alapján.';

  @override
  String get vehicleBaselineReset =>
      'Vezetési helyzet alapvonalának visszaállítása';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Visszaállítja a vezetési helyzet alapvonalát?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Ez törli az ehhez a járműhöz tanult összes mintát. A profil újbóli feltöltéséig visszatér az alap értékekhez.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Nincs adapter párosítva. Párosítson egyet, hogy az alkalmazás legközelebb automatikusan csatlakozhasson.';

  @override
  String get vehicleAdapterUnnamed => 'Ismeretlen adapter';

  @override
  String get vehicleAdapterPair => 'Adapter párosítása';

  @override
  String get vehicleAdapterForget => 'Adapter elfelejtése';

  @override
  String get achievementsTitle => 'Eredmények';

  @override
  String get achievementFirstTrip => 'Első út';

  @override
  String get achievementFirstTripDesc => 'Rögzítse az első OBD2-útját.';

  @override
  String get achievementFirstFillUp => 'Első tankolás';

  @override
  String get achievementFirstFillUpDesc => 'Rögzítse az első tankolását.';

  @override
  String get achievementTenTrips => '10 út';

  @override
  String get achievementTenTripsDesc => 'Rögzítsen 10 OBD2-utat.';

  @override
  String get achievementZeroHarsh => 'Sima vezető';

  @override
  String get achievementZeroHarshDesc =>
      'Teljesítsen egy legalább 10 km-es utat erős fékezés és gyorsítás nélkül.';

  @override
  String get achievementEcoWeek => 'Öko-hét';

  @override
  String get achievementEcoWeekDesc =>
      'Vezessen 7 egymást követő napon, minden nap legalább egy sima úttal.';

  @override
  String get achievementPriceWin => 'Ár-győzelem';

  @override
  String get achievementPriceWinDesc =>
      'Rögzítsen olyan tankolást, amely legalább 5%-kal alacsonyabb az állomás 30 napos átlagánál.';

  @override
  String get syncBaselinesToggleTitle => 'Tanult járműprofilok megosztása';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Töltse fel a jármű fogyasztási alapvonalait, hogy egy második eszköz is felhasználhassa azokat.';

  @override
  String get obd2StatusConnected => 'OBD2-adapter: csatlakoztatva';

  @override
  String get obd2StatusAttempting => 'OBD2-adapter: csatlakozás folyamatban';

  @override
  String get obd2StatusUnreachable => 'OBD2-adapter: nem elérhető';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-engedély szükséges';

  @override
  String get obd2StatusConnectedBody => 'Kész az út rögzítésére.';

  @override
  String get obd2StatusAttemptingBody => 'Csatlakozás a háttérben…';

  @override
  String get obd2StatusUnreachableBody =>
      'Az adapter hatótávolságon kívül van, vagy már egy másik alkalmazás használja.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Adjon Bluetooth-engedélyt a rendszerbeállításokban az automatikus újracsatlakozáshoz.';

  @override
  String get obd2StatusNoAdapter => 'Nincs adapter párosítva';

  @override
  String get obd2StatusForget => 'Adapter elfelejtése';

  @override
  String get tripHistoryTitle => 'Úttörténet';

  @override
  String get tripHistoryEmptyTitle => 'Még nincs út';

  @override
  String get tripHistoryEmptySubtitle =>
      'Csatlakoztasson OBD2-adaptert és rögzítsen egy utat a vezetési előzmények elkezdéséhez.';

  @override
  String get tripHistoryUnknownDate => 'Ismeretlen dátum';

  @override
  String get situationIdle => 'Alapjárat';

  @override
  String get situationStopAndGo => 'Megálló-haladás';

  @override
  String get situationUrban => 'Városi';

  @override
  String get situationHighway => 'Autópálya';

  @override
  String get situationDecel => 'Lassítás';

  @override
  String get situationClimbing => 'Emelkedő / terhelt';

  @override
  String get situationHardAccel => 'Erős gyorsítás';

  @override
  String get situationFuelCut => 'Üzemanyag-elvágás — gurulás';

  @override
  String get tripSaveAsFillUp => 'Mentés tankolásként';

  @override
  String get tripSaveRecording => 'Út mentése';

  @override
  String get tripDiscard => 'Elvetés';

  @override
  String obdOdometerRead(int km) {
    return 'Kilométer-számláló olvasva: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nincs beállítva';

  @override
  String get wizardVehicleTapToEdit => 'Érintsen a szerkesztéshez';

  @override
  String get wizardVehicleDefaultBadge => 'Alapértelmezett';

  @override
  String get wizardProfileChoiceHint =>
      'Válassza ki, hogyan kívánja használni az alkalmazást. Ezt később megváltoztathatja a Beállításokban.';

  @override
  String get wizardProfileChoiceFooter =>
      'Bármikor megváltoztathatja a választását a Beállítások → Használati mód alatt.';

  @override
  String get wizardProfileBasicName => 'Alap';

  @override
  String get wizardProfileBasicDescription =>
      'A legolcsóbb üzemanyag és EV-töltési árak a közelben. Kedvencek és áriasztások.';

  @override
  String get wizardProfileMediumName => 'Közepes';

  @override
  String get wizardProfileMediumDescription =>
      'Minden, ami az Alapban van, plusz kézzel rögzítheti az üzemanyag-tankolásokat és az EV-töltéseket.';

  @override
  String get wizardProfileFullName => 'Teljes';

  @override
  String get wizardProfileFullDescription =>
      'Minden, ami a Közepesben van, plusz automatikus OBD2-útfelvétel, vezetési pontszámok és hűségkártyák.';

  @override
  String get wizardProfileCustomName => 'Egyéni';

  @override
  String get wizardProfileCustomDescription =>
      'Saját funkciókombináció. Testreszabhatja az egyes kapcsolókat.';

  @override
  String get useModeSectionHint =>
      'Szabja az alkalmazást a tényleges használatához. Egy előbeállítás kiválasztása engedélyezi a megfelelő funkciókat.';

  @override
  String get useModeCustomSettingsDescription =>
      'A funkcióválasztéka nem egyezik egyetlen előbeállítással sem. Válasszon egyet felül a felülíráshoz, vagy folytassa az egyes funkciók testreszabását az alábbi szakaszban.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Használati mód beállítva: $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Alapértelmezett jármű (opcionális)';

  @override
  String get profileDefaultVehicleNone => 'Nincs alapértelmezett';

  @override
  String get profileFuelFromVehicleHint =>
      'Az üzemanyag típusa az alapértelmezett járműből származik. Törölje a járművet, hogy közvetlenül válasszon üzemanyagot.';

  @override
  String get consumptionNoVehicleTitle => 'Először adjon hozzá egy járművet';

  @override
  String get consumptionNoVehicleBody =>
      'A tankolások egy járműhöz kapcsolódnak. Adja hozzá autóját a fogyasztásnapló megkezdéséhez.';

  @override
  String get vehicleAdd => 'Jármű hozzáadása';

  @override
  String get vehicleAddTitle => 'Jármű hozzáadása';

  @override
  String get vehicleEditTitle => 'Jármű szerkesztése';

  @override
  String get vehicleDeleteTitle => 'Törli a járművet?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Eltávolítja a(z) \"$name\" járművet a profiljaiból?';
  }

  @override
  String get vehicleNameLabel => 'Név';

  @override
  String get vehicleNameHint => 'pl. Saját Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Belső égésű';

  @override
  String get vehicleTypeHybrid => 'Hibrid';

  @override
  String get vehicleTypeEv => 'Elektromos';

  @override
  String get vehicleEvSectionTitle => 'Elektromos';

  @override
  String get vehicleCombustionSectionTitle => 'Belső égésű';

  @override
  String get vehicleBatteryLabel => 'Akkumulátor-kapacitás (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max. töltési teljesítmény (kW)';

  @override
  String get vehicleConnectorsLabel => 'Támogatott csatlakozók';

  @override
  String get vehicleMinSocLabel => 'Min. SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max. SoC %';

  @override
  String get vehicleTankLabel => 'Tartálykapacitás (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Előnyben részesített üzemanyag';

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
  String get connectorThreePin => '3 tűs';

  @override
  String get evShowOnMap => 'EV-állomások megjelenítése';

  @override
  String get evAvailableOnly => 'Csak elérhető';

  @override
  String get evMinPower => 'Min. teljesítmény';

  @override
  String get evMaxPower => 'Max. teljesítmény';

  @override
  String get evOperator => 'Üzemeltető';

  @override
  String get evLastUpdate => 'Utolsó frissítés';

  @override
  String get evStatusAvailable => 'Elérhető';

  @override
  String get evStatusOccupied => 'Foglalt';

  @override
  String get evStatusOutOfOrder => 'Meghibásodott';

  @override
  String get openOnlyFilter => 'Csak nyitva';

  @override
  String get saveAsDefaults => 'Mentés alapértelmezettként';

  @override
  String get criteriaSavedToProfile => 'Alapértelmezettként mentve';

  @override
  String get profileNotFound => 'Nincs aktív profil';

  @override
  String get updatingFavorites => 'Kedvencek frissítése...';

  @override
  String get fetchingLatestPrices => 'Legújabb árak lekérése';

  @override
  String get noDataAvailable => 'Nincs adat';

  @override
  String get configAndPrivacy => 'Konfiguráció és adatvédelem';

  @override
  String get searchToSeeMap =>
      'Keressen az állomások térképen való megjelenítéséhez';

  @override
  String get evPowerAny => 'Bármely';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Helyszín';

  @override
  String get tooltipBack => 'Vissza';

  @override
  String get tooltipClose => 'Bezárás';

  @override
  String get tooltipShare => 'Megosztás';

  @override
  String get tooltipClearSearch => 'Keresési mező törlése';

  @override
  String get minimalDriveInstantConsumption => 'Pillanatnyi fogyasztás';

  @override
  String get coachingShiftUp => 'Sebességet feljebb';

  @override
  String get coachingShiftDown => 'Sebességet lejjebb';

  @override
  String get coachingEasePedal => 'Engedd a gázt';

  @override
  String get tooltipUseGps => 'GPS-helyzet használata';

  @override
  String get tooltipShowPassword => 'Jelszó megjelenítése';

  @override
  String get tooltipHidePassword => 'Jelszó elrejtése';

  @override
  String get evConnectorsLabel => 'Elérhető csatlakozók';

  @override
  String get evConnectorsNone => 'Nincs csatlakozó-információ';

  @override
  String get switchToEmail => 'Váltás e-mailre';

  @override
  String get switchToEmailSubtitle =>
      'Adatok megőrzése, bejelentkezés más eszközről';

  @override
  String get switchToAnonymousAction => 'Váltás névtelenre';

  @override
  String get switchToAnonymousSubtitle =>
      'Helyi adatok megőrzése, új névtelen munkamenet';

  @override
  String get linkDevice => 'Eszköz összekapcsolása';

  @override
  String get shareDatabase => 'Adatbázis megosztása';

  @override
  String get disconnectAction => 'Leválasztás';

  @override
  String get disconnectSubtitle =>
      'Szinkronizálás leállítása (helyi adatok megőrzése)';

  @override
  String get deleteAccountAction => 'Fiók törlése';

  @override
  String get deleteAccountSubtitle =>
      'Az összes szerveradat végleges eltávolítása';

  @override
  String get localOnly => 'Csak helyi';

  @override
  String get localOnlySubtitle =>
      'Opcionális: kedvencek, riasztások és értékelések szinkronizálása az eszközök között';

  @override
  String get setupCloudSync => 'Felhőszinkronizálás beállítása';

  @override
  String get disconnectTitle => 'Leválasztja a TankSync-et?';

  @override
  String get disconnectBody =>
      'A felhőszinkronizálás le lesz tiltva. A helyi adatok (kedvencek, riasztások, előzmények) megmaradnak ezen az eszközön. A szerveradatok nem törlődnek.';

  @override
  String get deleteAccountTitle => 'Törli a fiókot?';

  @override
  String get deleteAccountBody =>
      'Ez véglegesen törli az összes szerveradatot (kedvencek, riasztások, értékelések, útvonalak). Az ezen az eszközön lévő helyi adatok megmaradnak.\n\nEz nem vonható vissza.';

  @override
  String get switchToAnonymousTitle => 'Vált névtelenre?';

  @override
  String get switchToAnonymousBody =>
      'Kijelentkezik az e-mail fiókból, és egy új névtelen munkamenettel folytatja.\n\nA helyi adatai (kedvencek, riasztások) megmaradnak az eszközön, és az új névtelen fiókba szinkronizálódnak.';

  @override
  String get switchAction => 'Váltás';

  @override
  String get helpBannerCriteria =>
      'A profil alapértelmezések előre ki vannak töltve. Pontosítsa a keresést az alábbi feltételekkel.';

  @override
  String get helpBannerAlerts =>
      'Állítson be árlimit-küszöböt egy állomáshoz. Értesítést kap, ha az árak az alá esnek. Az ellenőrzések 30 percenként futnak.';

  @override
  String get helpBannerConsumption =>
      'Rögzítsen minden tankolást a valós fogyasztás és a CO₂-lábnyom követéséhez. Csúsztasson balra egy bejegyzés törléséhez.';

  @override
  String get helpBannerVehicles =>
      'Adja hozzá járműveit, hogy a tankolások és az üzemanyag-preferenciák automatikusan kitöltődjenek. Az első jármű lesz az alapértelmezett.';

  @override
  String get syncNow => 'Szinkronizálás most';

  @override
  String get onboardingPreferencesTitle => 'Beállításai';

  @override
  String get onboardingZipHelper => 'GPS hiányában használt';

  @override
  String get onboardingRadiusHelper => 'Nagyobb sugár = több eredmény';

  @override
  String get onboardingPrivacy =>
      'Ezek a beállítások csak az eszközén tárolódnak, és soha nem kerülnek megosztásra.';

  @override
  String get onboardingLandingTitle => 'Főképernyő';

  @override
  String get onboardingLandingHint =>
      'Válassza ki, melyik képernyő nyíljon meg az alkalmazás indításakor.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Maradjon ki az appból — de ne lépjen ki belőle.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Nyissa meg a Sparkilo-t egyszer minden újraindítás után.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Az Apple csak akkor ébreszti fel a Sparkilo-t, ha legalább egyszer megnyitotta az újraindítás óta. Ezután az útjai automatikusan rögzülnek.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Ne húzza le a Sparkilo-t az alkalmazásváltóban.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      'A \"Kényszer-kilépés\" azt mondja az iOS-nek, hogy ne indítsa újra az alkalmazást. Az útjai nem rögzülnek tovább, amíg újra meg nem nyitja a Sparkilo-t.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Amikor az iOS \"Mindig\" helyadatot kér, kérjük, mondjon igent.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'A tartalék, amely az OBD2-adapter késése esetén rögzíti az utat, háttéres helyadatot igényel. Soha nem osztjuk meg.';

  @override
  String get scanReceipt => 'Nyugta beolvasása';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Üzemanyag';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Autópálya';

  @override
  String get ratingModeLocal => 'Helyi';

  @override
  String get ratingModePrivate => 'Privát';

  @override
  String get ratingModeShared => 'Megosztott';

  @override
  String get ratingDescLocal => 'Értékelések csak ezen az eszközön mentve';

  @override
  String get ratingDescPrivate =>
      'Szinkronizálva az adatbázisával (mások számára nem látható)';

  @override
  String get ratingDescShared =>
      'Az adatbázis összes felhasználója számára látható';

  @override
  String get errorNoEvApiKey =>
      'Az OpenChargeMap API-kulcs nincs beállítva. Adjon hozzá egyet a Beállításokban az EV-töltőállomások kereséséhez.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Az adatszolgáltató ($host) lejárt vagy érvénytelen TLS-tanúsítványt szolgál ki. Az alkalmazás nem tölthet be adatokat ebből a forrásból, amíg a szolgáltató nem javítja azt. Kérjük, vegye fel a kapcsolatot: $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nem elérhető. Jelenleg: $current.';
  }

  @override
  String get errorTitleApiKey => 'API-kulcs szükséges';

  @override
  String get errorTitleLocation => 'Helyadat nem elérhető';

  @override
  String get errorHintNoStations =>
      'Próbáljon nagyobb keresési sugarat, vagy keressen egy másik helyszínt.';

  @override
  String get errorHintApiKey => 'Állítsa be az API-kulcsát a Beállításokban.';

  @override
  String get errorHintConnection =>
      'Ellenőrizze az internetkapcsolatát, és próbálja újra.';

  @override
  String get errorHintRouting =>
      'Az útvonalszámítás sikertelen. Ellenőrizze az internetkapcsolatát, és próbálja újra.';

  @override
  String get errorHintFallback =>
      'Próbálja újra, vagy keressen irányítószám / városnév alapján.';

  @override
  String get alertsLoadErrorTitle => 'Nem sikerült betölteni a riasztásokat';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'A riasztások háttér-ellenőrzése sikertelen';

  @override
  String get detailsLabel => 'Részletek';

  @override
  String get remove => 'Eltávolítás';

  @override
  String get showKey => 'Kulcs megjelenítése';

  @override
  String get hideKey => 'Kulcs elrejtése';

  @override
  String get syncOptionalTitle => 'A TankSync opcionális';

  @override
  String get syncOptionalDescription =>
      'Az alkalmazás teljesen működik felhőszinkronizálás nélkül. A TankSync lehetővé teszi a kedvencek, riasztások és értékelések szinkronizálását az eszközök között Supabase segítségével (ingyenes szint elérhető).';

  @override
  String get syncHowToConnectQuestion => 'Hogyan szeretne csatlakozni?';

  @override
  String get syncCreateOwnTitle => 'Saját adatbázis létrehozása';

  @override
  String get syncCreateOwnSubtitle =>
      'Ingyenes Supabase-projekt — lépésről lépésre végigvezetjük';

  @override
  String get syncJoinExistingTitle => 'Meglévő adatbázishoz csatlakozás';

  @override
  String get syncJoinExistingSubtitle =>
      'QR-kód beolvasása az adatbázis tulajdonosától, vagy hitelesítő adatok beillesztése';

  @override
  String get syncChooseAccountType => 'Válasszon fiók típust';

  @override
  String get syncAccountTypeAnonymous => 'Névtelen';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Azonnali, nem szükséges e-mail. Az adatok ehhez az eszközhöz kötöttek.';

  @override
  String get syncAccountTypeEmail => 'E-mail fiók';

  @override
  String get syncAccountTypeEmailDesc =>
      'Bármely eszközről bejelentkezhet. Ha elveszíti a telefont, visszaszerezheti adatait.';

  @override
  String get syncHaveAccountSignIn => 'Már van fiókja? Jelentkezzen be';

  @override
  String get syncCreateNewAccount => 'Új fiók létrehozása';

  @override
  String get syncTestConnection => 'Kapcsolat tesztelése';

  @override
  String get syncTestingConnection => 'Tesztelés...';

  @override
  String get syncConnectButton => 'Csatlakozás';

  @override
  String get syncConnectingButton => 'Csatlakozás folyamatban...';

  @override
  String get syncDatabaseReady => 'Adatbázis kész!';

  @override
  String get syncDatabaseNeedsSetup => 'Az adatbázist be kell állítani';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Hiányzik';

  @override
  String get syncSqlEditorInstructions =>
      'Másolja az alábbi SQL-t, és futtassa a Supabase SQL Szerkesztőben (Irányítópult → SQL-szerkesztő → Új lekérdezés → Beillesztés → Futtatás)';

  @override
  String get syncCopySqlButton => 'SQL másolása a vágólapra';

  @override
  String get syncRecheckSchemaButton => 'Séma újraellenőrzése';

  @override
  String get syncDoneButton => 'Kész';

  @override
  String syncSignedInAs(String email) {
    return 'Bejelentkezve mint: $email';
  }

  @override
  String get syncEmailDescription =>
      'Az adatok szinkronizálódnak az összes eszközön ezzel az e-mail-fiókkal.';

  @override
  String get syncSwitchToAnonymousTitle => 'Váltás névtelenre';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Folytatás e-mail nélkül, új névtelen munkamenet';

  @override
  String get syncGuestDescription => 'Névtelen, nem szükséges e-mail.';

  @override
  String get syncOrDivider => 'vagy';

  @override
  String get syncHowToSyncQuestion => 'Hogyan szeretne szinkronizálni?';

  @override
  String get syncOfflineDescription =>
      'Az alkalmazás teljesen offline is működik. A felhőszinkronizálás opcionális.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo közösség';

  @override
  String get syncModeCommunitySubtitle =>
      'Kedvencek és értékelések megosztása az összes felhasználóval';

  @override
  String get syncModePrivateTitle => 'Privát adatbázis';

  @override
  String get syncModePrivateSubtitle =>
      'Saját Supabase — teljes adatellenőrzés';

  @override
  String get syncModeGroupTitle => 'Csoporthoz csatlakozás';

  @override
  String get syncModeGroupSubtitle =>
      'Család vagy barátok megosztott adatbázisa';

  @override
  String get syncPrivacyShared => 'Megosztott';

  @override
  String get syncPrivacyPrivate => 'Privát';

  @override
  String get syncPrivacyGroup => 'Csoport';

  @override
  String get syncStayOfflineButton => 'Maradjon offline';

  @override
  String get syncSuccessTitle => 'Sikeresen csatlakoztatva!';

  @override
  String get syncSuccessDescription =>
      'Az adatok mostantól automatikusan szinkronizálódnak.';

  @override
  String get syncWizardTitleConnect => 'TankSync csatlakoztatása';

  @override
  String get syncSetupTitleYourDatabase => 'Az Ön adatbázisa';

  @override
  String get syncSetupTitleJoinGroup => 'Csatlakozás csoporthoz';

  @override
  String get syncSetupTitleAccount => 'Az Ön fiókja';

  @override
  String get syncWizardBack => 'Vissza';

  @override
  String get syncWizardNext => 'Tovább';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return '$current. lépés / $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Supabase-projekt létrehozása';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Érintse meg az alábbi \"Supabase megnyitása\" gombot\n2. Hozzon létre egy ingyenes fiókot (ha még nincs)\n3. Kattintson az \"Új projekt\" gombra\n4. Válasszon nevet és régiót\n5. Várjon ~2 percet az induláshoz';

  @override
  String get syncWizardOpenSupabase => 'Supabase megnyitása';

  @override
  String get syncWizardEnableAnonTitle =>
      'Névtelen bejelentkezések engedélyezése';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. A Supabase irányítópultján:\n   Hitelesítés → Szolgáltatók\n2. Keresse meg a \"Névtelen bejelentkezések\" lehetőséget\n3. Kapcsolja BE\n4. Kattintson a \"Mentés\" gombra';

  @override
  String get syncWizardOpenAuthSettings =>
      'Hitelesítési beállítások megnyitása';

  @override
  String get syncWizardCopyCredentialsTitle =>
      'Másolja ki a hitelesítő adatait';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Lépjen a Beállítások → API menübe az irányítópulton\n2. Másolja a \"Projekt URL\"-t\n3. Másolja az \"anon public\" kulcsot\n4. Illessze be az alábbiakba';

  @override
  String get syncWizardOpenApiSettings => 'API-beállítások megnyitása';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Meglévő adatbázishoz csatlakozás';

  @override
  String get syncWizardScanQrCode => 'QR-kód beolvasása';

  @override
  String get syncWizardAskOwnerQr =>
      'Kérje meg az adatbázis tulajdonosát, mutassa meg a QR-kódját\n(Beállítások → TankSync → Megosztás)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Kérje meg az adatbázis tulajdonosát, mutassa meg a QR-kódját';

  @override
  String get syncWizardEnterManuallyTitle => 'Kézi bevitel';

  @override
  String get syncWizardOrEnterManually => 'vagy adja meg kézzel';

  @override
  String get syncWizardUrlHelperText =>
      'A szóközök és sortörések automatikusan eltávolításra kerülnek';

  @override
  String get syncCredentialsPrivateHint =>
      'Adja meg a Supabase-projekt hitelesítő adatait. Ezeket az irányítópult Beállítások > API menüjében találja.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Adatbázis URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Hozzáférési kulcs';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Jelszó';

  @override
  String get authConfirmPasswordLabel => 'Jelszó megerősítése';

  @override
  String get authPleaseEnterEmail => 'Kérjük, adja meg az e-mail-cím';

  @override
  String get authInvalidEmail => 'Érvénytelen e-mail-cím';

  @override
  String get authPasswordsDoNotMatch => 'A jelszavak nem egyeznek';

  @override
  String get authConnectAnonymously => 'Csatlakozás névtelenül';

  @override
  String get authCreateAccountAndConnect => 'Fiók létrehozása és csatlakozás';

  @override
  String get authSignInAndConnect => 'Bejelentkezés és csatlakozás';

  @override
  String get authAnonymousSegment => 'Névtelen';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Azonnali hozzáférés, nem szükséges e-mail. Az adatok ehhez az eszközhöz kötöttek.';

  @override
  String get authEmailDescription =>
      'Bármely eszközről bejelentkezhet. Ha elveszíti a telefont, visszaszerezheti adatait.';

  @override
  String get authSyncAcrossDevices =>
      'Adatok automatikus szinkronizálása az összes eszközén.';

  @override
  String get authNewHereCreateAccount => 'Új itt? Fiók létrehozása';

  @override
  String get linkDeviceScreenTitle => 'Eszköz összekapcsolása';

  @override
  String get linkDeviceThisDeviceLabel => 'Ez az eszköz';

  @override
  String get linkDeviceShareCodeHint =>
      'Ossza meg ezt a kódot a másik eszközével:';

  @override
  String get linkDeviceNotConnected => 'Nincs csatlakoztatva';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kód másolása';

  @override
  String get linkDeviceImportSectionTitle => 'Importálás másik eszközről';

  @override
  String get linkDeviceImportDescription =>
      'Adja meg a másik eszköz kódját a kedvencek, riasztások, járművek és fogyasztási napló importálásához. Minden eszköz megőrzi saját profilját és alapértelmezéseit.';

  @override
  String get linkDeviceCodeFieldLabel => 'Eszközkód';

  @override
  String get linkDeviceCodeFieldHint =>
      'Illessze be az UUID-t a másik eszközről';

  @override
  String get linkDeviceImportButton => 'Adatok importálása';

  @override
  String get linkDeviceHowItWorksTitle => 'Hogyan működik';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Az A eszközön: másolja a fenti eszközkódot\n2. A B eszközön: illessze be az \"Eszközkód\" mezőbe\n3. Érintse az \"Adatok importálása\" gombot a kedvencek, riasztások, járművek és fogyasztásnaplók egyesítéséhez\n4. Mindkét eszköznek meglesz az összes kombinált adat\n\nMinden eszköz megőrzi saját névtelen identitását és saját profilját (előnyben részesített üzemanyag, alapértelmezett jármű, indítóképernyő). Az adatok egyesülnek, nem mozdulnak.';

  @override
  String get vehicleSetActive => 'Aktívra állítás';

  @override
  String get swipeHide => 'Elrejtés';

  @override
  String get evChargingSection => 'EV-töltés';

  @override
  String get fuelStationsSection => 'Üzemanyag-állomások';

  @override
  String get yourRating => 'Az Ön értékelése';

  @override
  String get noStorageUsed => 'Nem használ tárhelyet';

  @override
  String get aboutReportBug => 'Hiba jelentése / Funkció javaslása';

  @override
  String get aboutSupportProject => 'Projekt támogatása';

  @override
  String get aboutSupportDescription =>
      'Ez az alkalmazás ingyenes, nyílt forráskódú és reklámok nélküli. Ha hasznosnak találja, fontolja meg a fejlesztő támogatását.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'A luxemburgi üzemanyagárakat az állam szabályozza, és egységesek az országban.';

  @override
  String get luxembourgFuelUnleaded95 => 'Ólmozatlan 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Ólmozatlan 98';

  @override
  String get luxembourgFuelDiesel => 'Dízel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'A luxemburgi szabályozott árak nem elérhetők.';

  @override
  String get reportIssueTitle => 'Probléma jelentése';

  @override
  String get enterCorrection => 'Kérjük, adja meg a javítást';

  @override
  String get reportNoBackendAvailable =>
      'A jelentés nem küldhető el: ehhez az országhoz nincs bejelentési szolgáltatás beállítva. Engedélyezze a TankSync-et a Beállításokban közösségi jelentések küldéséhez.';

  @override
  String get correctName => 'Helyes állomásnév';

  @override
  String get correctAddress => 'Helyes cím';

  @override
  String get wrongE85Price => 'Hibás E85-ár';

  @override
  String get wrongE98Price => 'Hibás Super 98-ár';

  @override
  String get wrongLpgPrice => 'Hibás LPG-ár';

  @override
  String get wrongStationName => 'Hibás állomásnév';

  @override
  String get wrongStationAddress => 'Hibás cím';

  @override
  String get independentStation => 'Független állomás';

  @override
  String get serviceRemindersSection => 'SzervizEmlékeztetők';

  @override
  String get serviceRemindersEmpty =>
      'Még nincs emlékeztető — válasszon egy előbeállítást fentről.';

  @override
  String get addServiceReminder => 'Emlékeztető hozzáadása';

  @override
  String get serviceReminderPresetOil => 'Olaj (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Olajcsere';

  @override
  String get serviceReminderPresetTires => 'Gumik (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Gumik';

  @override
  String get serviceReminderPresetInspection => 'Műszaki vizsgálat (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Műszaki vizsgálat';

  @override
  String get serviceReminderLabel => 'Felirat';

  @override
  String get serviceReminderInterval => 'Intervallum (km)';

  @override
  String get serviceReminderLastService => 'Utolsó szerviz';

  @override
  String get serviceReminderMarkDone => 'Megjelölés elvégzettként';

  @override
  String get serviceReminderDueTitle => 'Szerviz esedékes';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label esedékes — $kmOver km-rel meghaladta az intervallumot.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Regisztráljon az OPINET-en ingyenes API-kulcsért';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Regisztráljon a CNE-n ingyenes API-kulcsért';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Ez az Ön autója?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders hengeres, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Részleges info (offline). Szerkesztheti az alábbiakban.';

  @override
  String get vinDecodeError => 'Nem sikerült dekódolni ezt a VIN-t';

  @override
  String get vinInvalidFormat => 'Érvénytelen VIN-formátum';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2-kapcsolat megszakadt — rögzítés szüneteltetve';

  @override
  String get obd2PauseBannerResume => 'Rögzítés folytatása';

  @override
  String get obd2PauseBannerEnd => 'Rögzítés befejezése';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Fogyasztás-kalibráció frissítve a(z) $vehicleName számára — pontosság $percent%-kal javult';
  }

  @override
  String get veResetConfirmTitle =>
      'Visszaállítja a volumetrikus hatékonyságot?';

  @override
  String get veResetConfirmBody =>
      'Ez elveti a tanult volumetrikus hatékonyságot (η_v), és visszaállítja az alapértéket (0,85). Az útszintű üzemanyag-áramlás becslések visszaesnek a gyártói konstansra, amíg a kalibrátor új mintákat nem gyűjt a következő utakból.';

  @override
  String get alertsRadiusSectionTitle => 'Sugárkörös riasztások';

  @override
  String get alertsRadiusAdd => 'Sugárkörös riasztás hozzáadása';

  @override
  String get alertsRadiusEmptyTitle => 'Még nincsenek sugárkörös riasztások';

  @override
  String get alertsRadiusEmptyCta => 'Sugárkörös riasztás létrehozása';

  @override
  String get alertsRadiusCreateTitle => 'Sugárkörös riasztás létrehozása';

  @override
  String get alertsRadiusLabelHint => 'Felirat (pl. Otthoni dízel)';

  @override
  String get alertsRadiusFuelType => 'Üzemanyag típusa';

  @override
  String get alertsRadiusThreshold => 'Küszöbérték (€/L)';

  @override
  String get alertsRadiusKm => 'Sugár (km)';

  @override
  String get alertsRadiusCenterGps => 'Saját helyszín használata';

  @override
  String get alertsRadiusCenterPostalCode => 'Irányítószám';

  @override
  String get alertsRadiusSave => 'Mentés';

  @override
  String get alertsRadiusCancel => 'Mégse';

  @override
  String get alertsRadiusDeleteConfirm => 'Törli a sugárkörös riasztást?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 csatlakoztatva: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'OBD2-adapter párosítása';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel csökkent a közeli állomásokon';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount állomáson legfeljebb $maxDropCents¢-vel csökkent az ár az elmúlt egy órában';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankolás mentve';

  @override
  String get radiusAlertsEntryTitle => 'Sugárkörös riasztások és statisztikák';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Értesítés, ha az árak esnek a közelben';

  @override
  String get notFoundTitle => 'Az oldal nem található';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nem található.';
  }

  @override
  String get notFoundHomeButton => 'Kezdőlap';

  @override
  String get consumptionTabHiddenNotice =>
      'A Fogyasztás fület a profil beállításai elrejtették.';

  @override
  String get swipeBetweenTabsHint =>
      'Tipp: csúsztasson balra vagy jobbra a fülek között váltáshoz.';

  @override
  String get discardChangesTitle => 'Elveti a módosításokat?';

  @override
  String get discardChangesBody =>
      'Nem mentett módosításai vannak. Ha most kilép, elvesznek.';

  @override
  String get discardChangesConfirm => 'Elvetés';

  @override
  String get discardChangesKeepEditing => 'Szerkesztés folytatása';

  @override
  String get tankSyncSectionSubtitle =>
      'Felhőszinkronizálás az eszközei között';

  @override
  String get mapUnavailable => 'A térkép nem érhető el';

  @override
  String get routeNameHintExample => 'pl. Párizs → Lyon';

  @override
  String get priceStatsCurrent => 'Jelenlegi';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API-kulcs';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API-kulcs';

  @override
  String get tapToUpdateGpsPosition => 'Koppintson a GPS-pozíció frissítéséhez';

  @override
  String get nameLabel => 'Név';

  @override
  String get obd2ErrorPermissionDenied =>
      'Az OBD2-adapterhez való csatlakozáshoz Bluetooth-engedély szükséges.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Kapcsolja be a Bluetootht, és próbálja újra.';

  @override
  String get obd2ErrorScanTimeout =>
      'Nem található OBD2-adapter a közelben. Ellenőrizze, hogy be van-e dugva és be van-e kapcsolva.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Az OBD2-adapter nem válaszolt. Kapcsolja be a gyújtást, és próbálja újra.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Az OBD2-adapter ismeretlen választ küldött. Lehet, hogy nem kompatibilis — próbáljon meg másik adaptert.';

  @override
  String get obd2ErrorDisconnected =>
      'Az OBD2-adapter kapcsolata megszakadt. Csatlakozzon újra, és próbálja újra.';

  @override
  String get onboardingExploreDemoData => 'Felfedezés demóadatokkal';

  @override
  String get achievementSmoothDriver => 'Sima sorozat';

  @override
  String get achievementSmoothDriverDesc =>
      'Vezessen egymás után 5 utat legalább 80-as sima-vezetési pontszámmal.';

  @override
  String get achievementColdStartAware => 'Hidegindítás-tudatos';

  @override
  String get achievementColdStartAwareDesc =>
      'Tartsa egy egész hónapban a hidegindítás üzemanyagköltségét a teljes üzemanyag 2%-a alatt — kombinálja a rövid utakat.';

  @override
  String get achievementHighwayMaster => 'Autópálya-mester';

  @override
  String get achievementHighwayMasterDesc =>
      'Teljesítsen egy 30 km-nél hosszabb utat egyenletes sebességgel, legalább 90-es sima-vezetési pontszámmal.';

  @override
  String get alertGatingNonDeStationWarning =>
      'A háttérben futó árriasztások jelenleg csak németországi töltőállomásokra működnek. Ez a riasztás mentésre kerül, de előfordulhat, hogy soha nem értesít, amíg az országok közötti riasztások meg nem érkeznek.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'A sugár alapú riasztások jelenleg csak németországi töltőállomásokat ellenőriznek.';

  @override
  String get approachOverlaySection => 'Töltőállomás-megközelítési átfedés';

  @override
  String get approachRadiusLabel => 'Sugár';

  @override
  String approachRadiusCaption(String km) {
    return 'Az átfedés megnő, és megjeleníti az árat, ha $km km-en belül vagy egy töltőállomástól';
  }

  @override
  String get approachPriceModeLabel => 'Ár megjelenítése';

  @override
  String get approachPriceModeNearest => 'Legközelebbi állomás';

  @override
  String get approachPriceModeCheapestInRadius => 'Legolcsóbb a sugárban';

  @override
  String get approachMinPollLabel => 'Min. frissítés';

  @override
  String approachMinPollCaption(int seconds) {
    return 'A legközelebbi állomás frissítésének alsó határa (gyorsabb sebességnél, soha nem gyakrabban, mint $seconds mp)';
  }

  @override
  String get approachTestSimulateButton => 'Megközelítési rátét tesztelése';

  @override
  String get approachTestStopButton => 'Teszt leállítása';

  @override
  String approachTestActiveCaption(String station) {
    return 'Teszt aktív — a rátét a(z) $station árát mutatja';
  }

  @override
  String get approachTestUnavailable =>
      'Adjon hozzá kedvenc kutat a megközelítési rátét teszteléséhez';

  @override
  String approachStationDistance(String meters) {
    return '$meters m-re';
  }

  @override
  String get authErrorNoNetwork =>
      'Nincs hálózati kapcsolat. Próbálja újra később.';

  @override
  String get authErrorInvalidCredentials =>
      'Érvénytelen e-mail vagy jelszó. Ellenőrizze a hitelesítő adatait.';

  @override
  String get authErrorUserAlreadyExists =>
      'Ez az e-mail már regisztrálva van. Próbáljon bejelentkezni.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Kérjük, ellenőrizze e-mailjét, és erősítse meg a fiókját.';

  @override
  String get authErrorGeneric =>
      'A bejelentkezés sikertelen. Kérjük, próbálja újra.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Háttéres helyadat — csak az automatikus rögzítéshez';

  @override
  String get autoRecordConsentExplanationTitle => 'Erről az engedélyről';

  @override
  String get autoRecordConsentExplanationBody =>
      'Az automatikus rögzítés háttéres helyadatot igényel annak észleléséhez, ha bezárt alkalmazással kezd el vezetni. Ez az engedély kizárólag az automatikus rögzítéshez szükséges — az állomáskeresés és a térkép-centrálás külön előtéri helyadat-engedélyt használ.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Értem';

  @override
  String get autoRecordConsentExplanationTooltip => 'Mit jelent ez?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Érintse a rendszerbeállításokban való kezeléshez';

  @override
  String get autoRecordSectionTitle => 'Automatikus rögzítés';

  @override
  String get autoRecordToggleLabel => 'Utak automatikus rögzítése';

  @override
  String get autoRecordStatusActiveLabel =>
      'Az automatikus rögzítés a következő autóba szálláskor aktiválódik.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Párosítson OBD2-adaptert az automatikus rögzítés engedélyezéséhez.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Engedélyezze a háttéres helyadatot, hogy az automatikus rögzítés kikapcsolt képernyőn is működjön.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Adapter párosítása';

  @override
  String get autoRecordSpeedThresholdLabel => 'Indítási sebesség (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Mentési késleltetés leválasztás után (másodperc)';

  @override
  String get autoRecordPairedAdapterLabel => 'Párosított adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Nincs adapter párosítva. Párosítson egyet az OBD2-bevezetőn keresztül.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Háttéres helyadat engedélyezve';

  @override
  String get autoRecordBackgroundLocationRequest => 'Engedély kérése';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Miért a \"Mindig engedélyezés\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Az automatikus rögzítés GPS-koordinátákat streamel az OBD-II előtéri szolgáltatásból kikapcsolt képernyőn is, hogy az útvonalja pontos maradjon. Az Android megköveteli a \"Mindig engedélyezés\" opciót, hogy ez az eszköz zárolása után is működjön.';

  @override
  String get autoRecordBackgroundLocationOpenSettings =>
      'Beállítások megnyitása';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Helyadat-engedély szükséges';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nem sikerült háttéres helyadatot kérni';

  @override
  String get autoRecordBadgeClearTooltip => 'Számláló törlése';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Párosítson adaptert az alábbi szakaszban az automatikus rögzítés engedélyezéséhez';

  @override
  String get exportBackupTooltip => 'Biztonsági mentés exportálása';

  @override
  String get exportBackupReady =>
      'Biztonsági mentés kész — válasszon célmappát';

  @override
  String get exportBackupFailed =>
      'A biztonsági mentés exportálása sikertelen — kérjük, próbálja újra';

  @override
  String get brokenMapChipVerifying => 'MAP-érzékelő ellenőrzése…';

  @override
  String get brokenMapChipDisclaimer => 'MAP-leolvasások gyanúsak';

  @override
  String get brokenMapSnackbarUnreliable =>
      'A MAP-érzékelő helytelenül olvas — az üzemanyag-leolvasások akár 50–80%-kal alacsonyabbak lehetnek. Próbáljon másik adaptert.';

  @override
  String get brokenMapBannerHardDisable =>
      'A MAP-érzékelő megbízhatatlan. Élő üzemanyag-arány helyett tankolási átlagokat mutat.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP-érzékelő: ellenőrzött ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP-érzékelő: ellenőrzés alatt ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP-érzékelő: gyanús ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-érzékelő: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-érzékelő: $posterior% ± $margin% (ellenőrzött)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-érzékelő diagnosztika';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Hibás MAP megbízhatósága: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count megfigyelés rögzítve';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Ellenőrzötten tiszta';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Ennek a járműnek a MAP-érzékelőjét még nem figyelték meg.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Tiltólistán szereplő adapterek';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Nincsenek tiltólistán szereplő adapterek.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — $percent%-ban hibásnak jelzett';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Törlés';

  @override
  String get brokenMapRevPromptTitle => 'Pörgesse fel a motort';

  @override
  String get brokenMapRevPromptBody =>
      'Röviden nyomja meg a gázpedált, hogy az alkalmazás ellenőrizze, reagál-e a MAP-érzékelő.';

  @override
  String get brokenMapRevPromptConfirm => 'Kész — felpörgettem';

  @override
  String get calibrationAdvancedTitle => 'Speciális kalibráció';

  @override
  String get calibrationDisplacementLabel => 'Motorlökettérfogat (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrikus hatékonyság (η_v)';

  @override
  String get calibrationAfrLabel => 'Levegő-üzemanyag arány (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Üzemanyag-sűrűség (g/L)';

  @override
  String get calibrationSourceDetected => '(VIN-ből észlelve)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalógus: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(alapértelmezett)';

  @override
  String get calibrationSourceManual => '(kézi)';

  @override
  String get calibrationResetToDetected => 'Visszaállítás az észlelt értékre';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrált, $samples minta)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (tanulás, $samples minta)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (alapértelmezett — még nincs teljes tankolás)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples minta';
  }

  @override
  String get calibrationResetLearner => 'Tanuló visszaállítása';

  @override
  String get calibrationBasisAtkinson => 'Atkinson-ciklus';

  @override
  String get calibrationBasisVnt => 'VNT dízel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbóval + DI';

  @override
  String get calibrationBasisTurbo => 'Turbóval';

  @override
  String get calibrationBasisNaDi => 'Szívómotoros + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalógus: $makeModel — $basis alap)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'A(z) $makeModel dízelnek van jelölve, de egy benzinkatalogus-bejegyzéssel egyezik meg. Érintsen a frissítéshez.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Frissítés';

  @override
  String get consumptionTabFuel => 'Üzemanyag';

  @override
  String get consumptionTabCharging => 'Töltés';

  @override
  String get noChargingLogsTitle => 'Még nincs töltési napló';

  @override
  String get noChargingLogsSubtitle =>
      'Rögzítse az első töltési munkamenetet az EUR/100 km és kWh/100 km követésének megkezdéséhez.';

  @override
  String get addChargingLog => 'Töltés naplózása';

  @override
  String get addChargingLogTitle => 'Töltési munkamenet naplózása';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Összköltség';

  @override
  String get chargingTimeMin => 'Töltési idő (perc)';

  @override
  String get chargingStationName => 'Állomás (opcionális)';

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
      'Összehasonlításhoz korábbi napló szükséges';

  @override
  String get chargingLogButtonLabel => 'Töltés naplózása';

  @override
  String get chargingCostTrendTitle => 'Töltési költség trendje';

  @override
  String get chargingEfficiencyTitle => 'Hatékonyság (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Még nincs elég adat';

  @override
  String get chargingChartsMonthAxis => 'Hónap';

  @override
  String get consoFeatureGroupTitle => 'Fogyasztás';

  @override
  String get consoFeatureGroupDescription =>
      'Fogyasztás követése — kézi tankolások vagy automatikus OBD2-útfelvétel.';

  @override
  String get consoModeOff => 'Ki';

  @override
  String get consoModeFuel => 'Üzemanyag';

  @override
  String get consoModeFuelAndTrips => 'Üzemanyag + Utak';

  @override
  String get consoModeOffDescription =>
      'Nincs Fogyasztás fül és Fogyasztás beállítási szakasz.';

  @override
  String get consoModeFuelDescription =>
      'Csak kézi tankolások. Hasznos OBD2-adapter nélkül.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Automatikus OBD2-útfelvételt ad hozzá. Párosított adapter szükséges.';

  @override
  String get consoSubsectionVehicles => 'Járműveim';

  @override
  String get consoSubsectionTrajets => 'Utak (OBD2)';

  @override
  String get consoSubsectionToggles => 'Vezetés';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Pontosság: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Magas';

  @override
  String get consumptionAccuracyMedium => 'Közepes';

  @override
  String get consumptionAccuracyLow => 'Alacsony';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Teljes kalibrálás: tankolások és OBD2-vel rögzített utak. A L/100 km érték néhány százalékon belül követi a valóságot.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'A tankolások rögzítették a fogyasztási modellt, de OBD2-út még nem került feldolgozásra. Rögzíts egyet csatlakoztatott OBD2-vel a magas pontosság eléréséhez.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Csak GPS — még egyetlen tankolás sem rögzítette a fogyasztási modellt. Adj hozzá néhány teljes tankolást a pontosság javításához.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count részleges tankolás vár teljes töltésre — nincs az átlagban',
      one: '1 részleges tankolás vár teljes töltésre — nincs az átlagban',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return 'Az üzemanyag $percent%-a automatikus korrekcióból — tekintse át a bejegyzéseket';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Automatikus korrekció — szerkesztéshez érintsen';

  @override
  String get fillUpCorrectionEditTitle => 'Automatikus korrekció szerkesztése';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Ez a bejegyzés automatikusan jött létre, hogy áthidalja a rögzített utak és a betankolás közti különbséget. Módosítsa az értékeket, ha ismeri a tényleges adatokat.';

  @override
  String get fillUpCorrectionDelete => 'Korrekció törlése';

  @override
  String get fillUpCorrectionStation => 'Állomás neve (opcionális)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Görögország)';

  @override
  String get greeceCommunityApiNotice =>
      'A közösség által fenntartott fuelpricesgr API segítségével';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Románia)';

  @override
  String get romaniaScrapingNotice =>
      'A pretcarburant.ro segítségével (Versenytanács + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country állomások $km km-re — €$price/L olcsóbb';
  }

  @override
  String get crossBorderTapToSwitch => 'Érintsen az ország váltásához';

  @override
  String get crossBorderDismissTooltip => 'Elvetés';

  @override
  String dataSourceAttribution(String source, String license) {
    return 'Forrás: $source ($license)';
  }

  @override
  String dataSourceAttributionSemantic(String source, String license) {
    return 'Az üzemanyagár-adatokat a(z) $source biztosítja, a(z) $license licenc alatt.';
  }

  @override
  String get developerToolsSectionTitle => 'Fejlesztői eszközök';

  @override
  String get developerToolsSubtitle =>
      'Diagnosztika és hibakeresési eszközök — csak fejlesztői/hibakeresési módban láthatók.';

  @override
  String get developerToolsMenuSubtitle =>
      'Hibanapló, tesztriasztások, diagnosztika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Hibanapló';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Hibanapló mentése ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Hibanapló törlése';

  @override
  String get developerToolsViewErrorLog => 'Hibanapló megtekintése';

  @override
  String get developerToolsErrorLogEmpty => 'Nincsenek rögzített hibanyomok.';

  @override
  String get developerToolsAlertsGroupTitle => 'Riasztások és értesítések';

  @override
  String get developerToolsFireTestNotification => 'Tesztértesítés küldése';

  @override
  String get developerToolsTestNotificationTitle => 'Tesztértesítés';

  @override
  String get developerToolsTestNotificationBody =>
      'Ha ezt el tudja olvasni, az értesítések működnek.';

  @override
  String get developerToolsTestNotificationSent => 'Tesztértesítés elküldve.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Az értesítések le vannak tiltva — engedélyezze őket a rendszerbeállításokban, majd próbálja újra.';

  @override
  String get developerToolsRunTestAlert => 'Tesztriasztási folyamat futtatása';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Tesztriasztás aktiválva — a folyamat $count értesítést kézbesített.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Tesztár-riasztás';

  @override
  String get developerToolsTestAlertBody =>
      'Szintetikus egyezés: a közelben találtunk egy a céljánál olcsóbb állomást.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnosztika';

  @override
  String get developerToolsFeatureFlagDump => 'Funkciójelzők vizsgálója';

  @override
  String get developerToolsFlagOn => 'Be';

  @override
  String get developerToolsFlagOff => 'Ki';

  @override
  String get developerToolsClearCaches => 'Gyorsítótárak törlése';

  @override
  String get developerToolsCachesCleared => 'Gyorsítótárak törölve.';

  @override
  String get developerToolsCopyDiagnostics => 'Diagnosztika másolása';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnosztika a vágólapra másolva.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Build-információ';

  @override
  String get developerToolsBuildVersion => 'Alkalmazás verziója';

  @override
  String get developerToolsBuildChannel => 'Build-csatorna';

  @override
  String get insightCardTitle => 'Legpazarlóbb viselkedések';

  @override
  String get insightEmptyState =>
      'Nincs figyelemreméltó hatékonysági hiány — így tovább!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor 3000 RPM felett ($pctTime% az útból): pazarolt $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count erős gyorsítás: pazarolt $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Alapjárat ($pctTime% az útból): pazarolt $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% az útból';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Alacsony fokozatban küszködés ($minutes perc)';
  }

  @override
  String get lessonAdviceIdling =>
      'Hosszú megállóknál kapcsolja ki a motort, ahelyett hogy üresjáraton hagyná.';

  @override
  String get lessonAdviceHighRpm =>
      'Kapcsoljon feljebb korábban, hogy a motor a magas fordulatszámú tartományon kívül maradjon.';

  @override
  String get lessonAdviceHardAccel =>
      'Finoman adjon gázt — az egyenletes gyorsítás kevesebb üzemanyagot fogyaszt.';

  @override
  String get lessonAdviceLowGear =>
      'Kapcsoljon feljebb hamarabb, hogy a motor alacsonyabb, takarékosabb fordulatszámon járjon.';

  @override
  String get drivingScoreCardTitle => 'Vezetési pontszám';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Összetett pontszám az alapjáratból, erős gyorsításokból, erős fékezésekből és magas fordulatszám-időből. Egy \'jobb, mint az elmúlt utak X%-a\' összehasonlítás egy következő kiadásban fog megjelenni.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Vezetési pontszám $score / 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Alapjárat';

  @override
  String get drivingScorePenaltyHardAccel => 'Erős gyorsítások';

  @override
  String get drivingScorePenaltyHardBrake => 'Erős fékezés';

  @override
  String get drivingScorePenaltyHighRpm => 'Magas fordulatszám';

  @override
  String get drivingScorePenaltyFullThrottle => 'Teljes gáz';

  @override
  String get ecoRouteOption => 'Öko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L megtakarítás';
  }

  @override
  String get ecoRouteHint =>
      'Okosabb menet — az egyenletes autópályát részesíti előnyben a tekervényes rövidítésekkel szemben.';

  @override
  String get favoritesShareAction => 'Megosztás';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — kedvencek $date-n';
  }

  @override
  String get favoritesShareError => 'Nem sikerült megosztási képet generálni';

  @override
  String get featureManagementSectionTitle => 'Funkciók kezelése';

  @override
  String get featureManagementSectionSubtitle =>
      'Kapcsoljon be vagy ki egyes funkciókat. Egyes funkciók másoktól függnek — a kapcsolók le vannak tiltva, amíg az előfeltételek nem teljesülnek.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2-útfelvétel';

  @override
  String get featureDescription_obd2TripRecording =>
      'Utak automatikus rögzítése OBD2-n keresztül.';

  @override
  String get featureLabel_gamification => 'Gamifikáció';

  @override
  String get featureDescription_gamification =>
      'Vezetési pontszámok és szerzett jelvények.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptikus öko-edző';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Valós idejű haptikus visszajelzés az út során.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Eszközök közötti szinkronizálás Supabase-en keresztül.';

  @override
  String get featureLabel_consumptionAnalytics => 'Fogyasztáselemzés';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Tankolás és útanalitika fül.';

  @override
  String get featureLabel_baselineSync => 'Alapvonal-szinkronizálás';

  @override
  String get featureDescription_baselineSync =>
      'Vezetési alapvonalak szinkronizálása TankSync-en keresztül.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Egyesített keresési eredmények';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Egyetlen eredménylista, amely kombinálja az üzemanyag- és EV-állomásokat.';

  @override
  String get featureLabel_priceAlerts => 'Áriasztások';

  @override
  String get featureDescription_priceAlerts =>
      'Küszöbértéken alapuló áresés-értesítések.';

  @override
  String get featureLabel_priceHistory => 'Ártörténet';

  @override
  String get featureDescription_priceHistory =>
      '30 napos árgörbék az állomás részleteinél.';

  @override
  String get featureLabel_routePlanning => 'Útvonaltervezés';

  @override
  String get featureDescription_routePlanning =>
      'Legolcsóbb megálló az útvonalon.';

  @override
  String get featureLabel_evCharging => 'EV-töltés';

  @override
  String get featureDescription_evCharging =>
      'Töltőállomások OpenChargeMap-en keresztül.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hipermiling-útmutatás OSM-közlekedési jelzők segítségével.';

  @override
  String get featureLabel_gpsTripPath => 'GPS-útvonal';

  @override
  String get featureDescription_gpsTripPath =>
      'GPS-útvonal-minták megőrzése minden út mellett.';

  @override
  String get featureLabel_autoRecord => 'Automatikus rögzítés';

  @override
  String get featureDescription_autoRecord =>
      'Automatikusan elindítja az utat, amikor az OBD2-adapter mozgó járműhöz csatlakozik.';

  @override
  String get featureLabel_showFuel => 'Üzemanyag-állomások megjelenítése';

  @override
  String get featureDescription_showFuel =>
      'Benzin-/dízel-állomások megjelenítése a keresési eredményekben és a térképen.';

  @override
  String get featureLabel_showElectric => 'Töltőállomások megjelenítése';

  @override
  String get featureDescription_showElectric =>
      'EV-töltőállomások megjelenítése a keresési eredményekben és a térképen.';

  @override
  String get featureLabel_showConsumptionTab => 'Fogyasztás fül';

  @override
  String get featureDescription_showConsumptionTab =>
      'Fogyasztáselemzés fül megjelenítése az alsó navigációban.';

  @override
  String get featureBlockedEnable_gamification =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureBlockedEnable_baselineSync =>
      'Először engedélyezze a TankSync-et';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureBlockedEnable_showFuel =>
      'Az előfeltételek nem teljesülnek';

  @override
  String get featureBlockedEnable_showElectric =>
      'Az előfeltételek nem teljesülnek';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite ár-előrejelzés';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Eszközön futó ár-előrejelzési modell — a következtetés helyileg fut; a funkciók és az előrejelzések soha nem hagyják el az eszközt.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Először engedélyezze az ártörténetet';

  @override
  String get featureLabel_fuelCalculator => 'Üzemanyag-kalkulátor';

  @override
  String get featureDescription_fuelCalculator =>
      'Elérhető üzemanyagköltség-kalkulátor a keresési eredményekből.';

  @override
  String get featureLabel_carbonDashboard => 'Szén-dioxid irányítópult';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2-lábnyom irányítópult a Fogyasztás fülről elérhető.';

  @override
  String get featureLabel_experimentalOemPids => 'Kísérleti OEM PIDs';

  @override
  String get featureDescription_experimentalOemPids =>
      'Pontos tartályliter olvasása gyártóspecifikus PID-eken keresztül támogatott adaptereken.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Először engedélyezze az OBD2-útfelvételt';

  @override
  String get featureLabel_paymentQrScan => 'Fizetési QR beolvasása';

  @override
  String get featureDescription_paymentQrScan =>
      'Beolvasás-fizetés QR-olvasó az állomás részletes képernyőjén.';

  @override
  String get featureLabel_communityPriceReports => 'Közösségi árjelentések';

  @override
  String get featureDescription_communityPriceReports =>
      'Állomás árának bejelentése az állomás részletes képernyőjéről.';

  @override
  String get featureLabel_obd2Optional =>
      'OBD2 megkövetelése az utak rögzítéséhez';

  @override
  String get featureDescription_obd2Optional =>
      'Ha ki van kapcsolva, az alkalmazás csak GPS-szel rögzít utakat OBD2-adapter nélkül. A coaching csökkentett — nincs azonnali L/100 km, kevesebb motorjel.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Számla OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Olvasson be nyomtatott számlát a Tankolás hozzáadása képernyőn, hogy előre kitöltse a dátumot, a litereket, az összeget és a kutat.';

  @override
  String get featureLabel_addFillUpOcrPump => 'Kút kijelző OCR (kísérleti)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Olvasson be egy üzemanyagkút kijelzőjét az űrlap előre kitöltéséhez. A felismerés ma megbízhatatlan — csak akkor kapcsolja be, ha tesztelni szeretné.';

  @override
  String get featureLabel_developerPatToken =>
      'Fejlesztői visszajelzés (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Bekapcsolja a hibás szkenneléshez tartozó visszajelzési panelt, amely Personal Access Tokennel automatikusan létrehoz GitHub-issue-kat. Haladó felhasználói / közreműködői funkció.';

  @override
  String get featureLabel_debugMode => 'Fejlesztői/hibakeresési mód';

  @override
  String get featureDescription_debugMode =>
      'Megjelenít egy Fejlesztői eszközök szakaszt a beállításokban diagnosztikával: hibanapló exportálása, tesztértesítések, tesztriasztási folyamat futtatása, funkciójelzők listázása, gyorsítótárak törlése és diagnosztika másolása.';

  @override
  String get feedbackConsentTitle => 'Elküldi a jelentést GitHub-ra?';

  @override
  String get feedbackConsentBody =>
      'Ez egy nyilvános jegyet hoz létre a GitHub-tárolónkban a fotójával és az OCR-szöveggel. Nem kerül személyes adat (helyszín, fiók-azonosító). Folytatja?';

  @override
  String get feedbackConsentContinue => 'Folytatás';

  @override
  String get feedbackConsentCancel => 'Mégse';

  @override
  String get feedbackConsentLater => 'Később';

  @override
  String get feedbackTokenSectionTitle =>
      'Hibás beolvasás visszajelzés (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Ahhoz, hogy egy sikertelen beolvasásból automatikusan GitHub-jegy nyíljon, illessze be a GitHub PAT-ját (`public_repo` hatókör a tankstellen tárolón). Ellenkező esetben a kézi megosztás továbbra is elérhető.';

  @override
  String get feedbackTokenStatusSet => 'Token beállítva';

  @override
  String get feedbackTokenStatusUnset => 'Nincs token';

  @override
  String get feedbackTokenSet => 'Beállítás';

  @override
  String get feedbackTokenClear => 'Törlés';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Személyes hozzáférési token';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel =>
      'Adapter által ellenőrzött';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Nem egyezik az adapter leolvasásával';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Az Ön bejegyzése: $userL L. Az adapter szerint: $adapterL L (különbség a tankolás előtti/utáni üzemanyagszint-rögzítésből). Adapter értékét használja?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Saját bejegyzés megtartása';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Adapter értékének használata';

  @override
  String get scanReceiptNoData => 'Nem található nyugtaadat — próbálja újra';

  @override
  String get scanReceiptSuccess =>
      'Nyugta beolvasva — ellenőrizze az értékeket. Ha valami nem stimmel, érintse alul a \"Beolvasási hiba jelentése\" gombot.';

  @override
  String scanReceiptFailed(String error) {
    return 'Beolvasás sikertelen: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'A kút kijelzője nem olvasható — próbálja újra';

  @override
  String get scanPumpSuccess =>
      'A kút kijelzője beolvasva — ellenőrizze az értékeket.';

  @override
  String get scanPumpGlare =>
      'Túl sok a tükröződés a kijelzőn — próbáld újra enyhe szögből, hogy a számok ne legyenek túlexponáltak.';

  @override
  String scanPumpFailed(String error) {
    return 'Kút beolvasása sikertelen: $error';
  }

  @override
  String get badScanReportTitle => 'Beolvasási hiba jelentése';

  @override
  String get badScanReportTitleReceipt => 'Beolvasási hiba jelentése — Nyugta';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Beolvasási hiba jelentése — Kút kijelzője';

  @override
  String get pumpScanFailureTitle => 'Kijelző nem olvasható';

  @override
  String get pumpScanFailureBody =>
      'A beolvasás nem tudta olvasni a kút kijelzőjét. Mit szeretne tenni?';

  @override
  String get pumpScanFailureCorrectManually => 'Kézi javítás';

  @override
  String get pumpScanFailureReport => 'Jelentés';

  @override
  String get pumpScanFailureRemove => 'Fotó eltávolítása';

  @override
  String get badScanReportHint =>
      'Megosztjuk a nyugtafotót és mindkét értékkészletet, hogy a következő build megtanulja ezt az elrendezést.';

  @override
  String get badScanReportShareAction => 'Jelentés + fotó megosztása';

  @override
  String get badScanReportFieldBrandLayout => 'Márka-elrendezés';

  @override
  String get badScanReportFieldTotal => 'Összeg';

  @override
  String get badScanReportFieldPricePerLiter => 'Ár/L';

  @override
  String get badScanReportFieldStation => 'Állomás';

  @override
  String get badScanReportFieldFuel => 'Üzemanyag';

  @override
  String get badScanReportFieldDate => 'Dátum';

  @override
  String get badScanReportHeaderField => 'Mező';

  @override
  String get badScanReportHeaderScanned => 'Beolvasott';

  @override
  String get badScanReportHeaderYouTyped => 'Ön írta';

  @override
  String get badScanReportCreateTicket => 'Jegy létrehozása';

  @override
  String get badScanReportOpenInBrowser => 'Megnyitás böngészőben';

  @override
  String get badScanReportFallbackToShare =>
      'Beküldés sikertelen — kézi megosztás';

  @override
  String get pumpCameraHint =>
      'Igazítsa a kút kijelzőjének három számát a kereten belülre';

  @override
  String get pumpCameraCapture => 'Rögzítés';

  @override
  String get pumpCameraPermissionDenied =>
      'A kút kijelzőjének beolvasásához kamera-hozzáférés szükséges. Engedélyezze az eszköz beállításaiban.';

  @override
  String get pumpCameraError =>
      'A kamerát nem sikerült elindítani. Próbálja újra, vagy adja meg az értékeket kézzel.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Váltás vízszintes elrendezésre';

  @override
  String get pumpCameraOrientationVertical => 'Váltás függőleges elrendezésre';

  @override
  String get pumpCameraGlareWarning =>
      'Túl sok fény — kissé döntse meg a tükröződések elkerülése érdekében';

  @override
  String get pumpCameraAlignHint =>
      'Igazítsa a kijelzőt a keretbe, majd készítse el a felvételt';

  @override
  String get fillUpSectionWhatTitle => 'Mit tankolt';

  @override
  String get fillUpSectionWhatSubtitle => 'Üzemanyag, mennyiség, ár';

  @override
  String get fillUpSectionWhereTitle => 'Hol volt';

  @override
  String get fillUpSectionWhereSubtitle =>
      'Állomás, kilométer-számláló, megjegyzések';

  @override
  String get fillUpImportFromLabel => 'Importálás innen…';

  @override
  String get fillUpImportSheetTitle => 'Tankolási adatok importálása';

  @override
  String get fillUpImportReceiptLabel => 'Nyugta';

  @override
  String get fillUpImportReceiptDescription =>
      'Papír nyugta beolvasása kamerával';

  @override
  String get fillUpImportPumpLabel => 'Kút kijelzője';

  @override
  String get fillUpImportPumpDescription =>
      'Összeg / Ár leolvasása a kút LCD-jéről';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Kilométer-számláló leolvasása az OBD-II portról Bluetooth-on';

  @override
  String get fillUpPricePerLiterLabel => 'Liter ára';

  @override
  String get vehicleHeaderPlateLabel => 'Rendszám';

  @override
  String get vehicleHeaderUntitled => 'Új jármű';

  @override
  String get vehicleSectionIdentityTitle => 'Azonosítás';

  @override
  String get vehicleSectionIdentitySubtitle => 'Név és VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Hajtáslánc';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Hogyan mozog ez a jármű';

  @override
  String get calibrationModeLabel => 'Kalibrációs mód';

  @override
  String get calibrationModeRule => 'Szabályalapú';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'A szabályalapú mód minden vezetési mintát pontosan egy helyzethez rendel. A fuzzy mód az összes helyzetre elosztja, attól függően, mennyire illik mindegyik — simább 60 km/h körül vagy változó lejtőknél, de lassabban tölti fel az összes rekeszt.';

  @override
  String get profileGamificationToggleTitle =>
      'Eredmények és pontszámok megjelenítése';

  @override
  String get profileGamificationToggleSubtitle =>
      'Ha ki van kapcsolva, a jelvények, pontszámok és trófeaikonok el vannak rejtve az egész alkalmazásban.';

  @override
  String get coachingGpsLiftOff => 'Levenni a lábat';

  @override
  String get coachingGpsAnticipateBrake => 'Előrelátás';

  @override
  String get coachingGpsSmoothAccel => 'Lágy gyorsítás';

  @override
  String get gpsDiagnosticsTitle => 'GPS-mintavételi diagnosztika';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps hiány',
      one: '1 hiány',
      zero: 'nincs hiány',
    );
    return '$count minta · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Mediánintervallum: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Rögzítés közben rögzítve a GPS-ütem ellenőrzéséhez alvó telefon esetén.';

  @override
  String get gpsMatrixMaturityCold => 'Hideg';

  @override
  String get gpsMatrixMaturityWarming => 'Melegszik';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergens';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS mátrix még melegszik ($count finomítás eddig). Az becslések ideiglenesek.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS mátrix konvergál ($count tankolás). Becslések használhatók, néhány %-kal eltérhetnek.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS mátrix konvergált ($count tankolás). Becslések ~2 %-on belül a tényleges fogyasztáshoz.';
  }

  @override
  String get hapticEcoCoachSectionTitle => 'Vezetés';

  @override
  String get hapticEcoCoachSettingTitle => 'Valós idejű öko-coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Enyhe haptikus visszajelzés + képernyős tipp, ha menetsebesség közben teljesen letapos';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Kíméletes gáz — a gurulás több üzemanyagot takarít meg';

  @override
  String get anonKeyLabel => 'Anon kulcs';

  @override
  String get anonKeyHideTooltip => 'Kulcs elrejtése';

  @override
  String get anonKeyShowTooltip => 'Kulcs megjelenítése az ellenőrzéshez';

  @override
  String anonKeyTooLong(int length) {
    return 'A kulcs túl hosszú ($length karakter) — ellenőrizze, hogy nem tartalmaz-e felesleges szöveget';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'A kulcs helyesnek tűnik ($length karakter)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'A kulcsnak JWT-nek kell lennie (fejléc.tartalom.aláírás)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Lehet, hogy a kulcs csonkolt ($length karakter a várt ~208-ból)';
  }

  @override
  String get anonKeyExceedsMax => 'A kulcs meghaladja a maximális hosszt';

  @override
  String get qrShareTitle => 'Adatbázis megosztása';

  @override
  String get qrShareSubtitle =>
      'Mások beolvashatják ezt a QR-kódot a csatlakozáshoz';

  @override
  String get qrShareCopyAsText => 'Másolás szövegként';

  @override
  String get authInfoTitle => 'Miért érdemes fiókot létrehozni?';

  @override
  String get authInfoBenefit1 =>
      '• Kedvencek, riasztások és mentett útvonalak szinkronizálása az eszközök között';

  @override
  String get authInfoBenefit2 =>
      '• Tervezzen útvonalat a telefonján, és használja az autójában';

  @override
  String get authInfoBenefit3 =>
      '• Semmilyen adat nem kerül megosztásra harmadik felekkel';

  @override
  String get authInfoBenefit4 => '• Fiókját bármikor törölheti';

  @override
  String get privacyLocalDataEmpty =>
      'Még semmi sem tárolódott. Adjon hozzá kedvencet vagy állítson be áriasztást a bejegyzések megtekintéséhez.';

  @override
  String get privacyHideEmptyRows => 'Üres sorok elrejtése';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count üres sor megjelenítése',
      one: '$count üres sor megjelenítése',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-kulcs beállítása (opcionális)';

  @override
  String get apiKeySetupDescription =>
      'Regisztráljon egy ingyenes API-kulcsért, vagy ugorja át, hogy demó adatokkal fedezze fel az alkalmazást.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider regisztráció';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Az API-kulcs megadásával elfogadja a(z) $provider feltételeit. Az adatok terjesztése tilos.';
  }

  @override
  String get calculatorDistanceHint => 'pl. 150';

  @override
  String get calculatorConsumptionHint => 'pl. 7,0';

  @override
  String get calculatorPriceHint => 'pl. 1,899';

  @override
  String get routeStrategyLabel => 'Stratégia:';

  @override
  String get routeStrategyUniform => 'Egyenletes';

  @override
  String get routeStrategyBalanced => 'Kiegyensúlyozott';

  @override
  String get glideCoachBetaTitle => 'Glide-coach béta (kísérleti)';

  @override
  String get glideCoachBetaSubtitle =>
      'Enyhe haptikus visszajelzés lassításkor piros lámpa előtt. Alapból ki van kapcsolva — zavaró lehet.';

  @override
  String get consentSyncTripsTitle => 'Útfelvételek szinkronizálása';

  @override
  String get consentSyncTripsSubtitle =>
      'OBD2 + GPS utak mentése TankSync-re. Eszközök között, opcionális.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Az utak mentéséhez engedélyezze a Felhőszinkronizálást fentebb.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Jelentkezz be e-mail-fiókkal az utak eszközök közötti szinkronizálásához.';

  @override
  String get consentHideDetails => 'Részletek elrejtése';

  @override
  String get consentShowDetails => 'Részletek megjelenítése';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Érvénytelen hivatkozás';

  @override
  String invalidLinkBody(String path) {
    return 'A(z) \"$path\" hivatkozás érvénytelen.';
  }

  @override
  String get home => 'Kezdőlap';

  @override
  String get loyaltySettingsTitle => 'Üzemanyag-törzsvevő kártyák';

  @override
  String get loyaltySettingsSubtitle =>
      'Alkalmazzon hűségkedvezményt a megjelenített árakra';

  @override
  String get loyaltyMenuTitle => 'Üzemanyag-törzsvevő kártyák';

  @override
  String get loyaltyMenuSubtitle =>
      'Literenkénti kedvezmények alkalmazása: Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Kártya hozzáadása';

  @override
  String get loyaltyAddCardSheetTitle =>
      'Üzemanyag-törzsvevő kártya hozzáadása';

  @override
  String get loyaltyBrandLabel => 'Márka';

  @override
  String get loyaltyCardLabelLabel => 'Felirat (opcionális)';

  @override
  String get loyaltyDiscountLabel => 'Kedvezmény (literenként)';

  @override
  String get loyaltyDiscountInvalid => 'Adjon meg pozitív számot';

  @override
  String get loyaltyDeleteConfirmTitle => 'Törli a kártyát?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Ez a kártya nem alkalmazza tovább a kedvezményt.';

  @override
  String get loyaltyEmptyTitle => 'Még nincs üzemanyag-törzsvevő kártya';

  @override
  String get loyaltyEmptyBody =>
      'Adjon hozzá kártyát, hogy a literenkénti kedvezménye automatikusan alkalmazódjon a megfelelő állomásoknál.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Alapjárati fordulatszám-emelkedés észlelve';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Az alapjárati fordulatszám $percent%-kal emelkedett az utolsó $tripCount útja során. Esetleg eltömődött légszűrő vagy szenzordrift korai jele.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Esetleges szívási korlátozás';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'A menetközbeni üzemanyag-arány $percent%-kal csökkent az utolsó $tripCount útja során. Esetleg eltömődött légszűrő vagy korlátozott szívás jele — érdemes ellenőriztetni.';
  }

  @override
  String get maintenanceActionDismiss => 'Elvetés';

  @override
  String get maintenanceActionSnooze => 'Halasztás 30 napra';

  @override
  String get consumptionMonthlyInsightsTitle => 'Ez a hónap vs. előző hónap';

  @override
  String get consumptionMonthlyTripsLabel => 'Utak';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Menetidő';

  @override
  String get consumptionMonthlyDistanceLabel => 'Távolság';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Átl. fogyasztás';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Az összehasonlításhoz havonta legalább 3 út szükséges';

  @override
  String get obd2CapabilitySectionTitle => 'Adapter-képességek';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'OEM PIDs';

  @override
  String get obd2CapabilityFullCan => 'Teljes CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'A Peugeot/Citroën pontos tartálylitersének eléréséhez az alkalmazás az OBDLink MX+/LX/CX (STN chip) adaptereket támogatja.';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2 diagnosztikai overlay engedélyezve';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 diagnosztikai overlay letiltva';

  @override
  String get obd2DebugOverlayClearButton => 'Törlés';

  @override
  String get obd2DebugOverlayCloseButton => 'Bezárás';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 morzsakód-nyomvonal';

  @override
  String get obd2DiagnosticShareLabel => 'Diagnosztikai napló megosztása';

  @override
  String get obd2DebugLoggingTitle => 'OBD2 hibakeresési naplózás';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Rögzítsen minden OBD2-munkamenetet — kapcsolódás, kézfogás, adatkimaradások és újracsatlakozások — egy exportálható XML-naplóba. Alapértelmezés szerint kikapcsolva.';

  @override
  String get obd2DebugSessionShareLabel =>
      'OBD2-munkamenet naplójának megosztása';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nem sikerült elérni a(z) \'$adapterName\'-t — válasszon másik adaptert';
  }

  @override
  String get onboardingObd2StepTitle => 'OBD2-adapter csatlakoztatása';

  @override
  String get onboardingObd2StepBody =>
      'Dugja be az OBD2-adaptert az autó portjába, és kapcsolja be a gyújtást. Beolvassuk a VIN-t, és kitöltjük a motoradatokat.';

  @override
  String get onboardingObd2ConnectButton => 'Adapter csatlakoztatása';

  @override
  String get onboardingObd2SkipButton => 'Talán később';

  @override
  String get onboardingObd2ReadingVin => 'VIN olvasása…';

  @override
  String get onboardingObd2VinReadFailed =>
      'VIN nem olvasható — adja meg kézzel';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nem sikerült csatlakozni az adapterhez. Újra próbálhatja, vagy kihagyhatja.';

  @override
  String get onboardingPickUseMode =>
      'Válasszon használati módot a folytatáshoz.';

  @override
  String get tripRecordingPipElapsedCaption => 'eltelt';

  @override
  String get alertsRadiusFrequencyLabel => 'Ellenőrzési gyakoriság';

  @override
  String get alertsRadiusFrequencyDaily => 'Naponta egyszer';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Naponta kétszer';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Naponta háromszor';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Naponta négyszer';

  @override
  String get radiusAlertPickOnMap => 'Kiválasztás térképen';

  @override
  String get radiusAlertMapPickerTitle =>
      'Riasztás középpontjának kiválasztása';

  @override
  String get radiusAlertMapPickerConfirm => 'Megerősítés';

  @override
  String get radiusAlertMapPickerCancel => 'Mégse';

  @override
  String get radiusAlertMapPickerHint =>
      'Húzza a térképet a riasztás középpontjának beállításához';

  @override
  String get radiusAlertCenterFromMap => 'Térképi helyszín';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel a(z) $label közelében';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Egy állomáson $price € az ár (cél: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/munkamenet';

  @override
  String get speedConsumptionCardTitle => 'Fogyasztás sebességenként';

  @override
  String get speedBandIdleJam => 'Alapjárat / dugó';

  @override
  String get speedBandUrban => 'Városi (10–50)';

  @override
  String get speedBandSuburban => 'Külvárosi (50–80)';

  @override
  String get speedBandRural => 'Vidéki (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Öko-cruise (100–115)';

  @override
  String get speedBandMotorway => 'Autópálya (115–130)';

  @override
  String get speedBandMotorwayFast => 'Gyors autópálya (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Rögzítsen 30+ perces utakat OBD2-adapterrel a sebesség/fogyasztás elemzés feloldásához.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent% a vezetési időből';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Több adatra van szükség';

  @override
  String get splashLoadingLabel => 'Sparkilo betöltése';

  @override
  String get tankLevelTitle => 'Tartályszint';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km hatótávolság';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Utolsó tankolás: $date · $count út azóta';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 mért';

  @override
  String get tankLevelMethodDistanceFallback => 'távolságalapú becslés';

  @override
  String get tankLevelMethodMixed => 'vegyes mérés';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Rögzítsen tankolást a tartályszint megtekintéséhez';

  @override
  String get tankLevelDetailSheetTitle => 'Utak az utolsó tankolás óta';

  @override
  String get addFillUpIsFullTankLabel => 'Teli tartály';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'A tartály tele van — vegye ki a pipát, ha ez részleges töltés volt';

  @override
  String get themeCardTitle => 'Téma';

  @override
  String get themeCardSubtitleSystem => 'Rendszer';

  @override
  String get themeCardSubtitleLight => 'Világos';

  @override
  String get themeCardSubtitleDark => 'Sötét';

  @override
  String get themeSettingsScreenTitle => 'Téma';

  @override
  String get themeSettingsSystemLabel => 'Rendszer szerint';

  @override
  String get themeSettingsLightLabel => 'Világos';

  @override
  String get themeSettingsDarkLabel => 'Sötét';

  @override
  String get themeSettingsSystemDescription =>
      'Az aktuális eszközmegjelenés szerint.';

  @override
  String get themeSettingsLightDescription =>
      'Világos háttér — napközben a legjobb.';

  @override
  String get themeSettingsDarkDescription =>
      'Sötét háttér — éjszakai használatkor kíméletes, és OLED-képernyőn akkumulátort takarít meg.';

  @override
  String get themeSettingsEcoLabel => 'Öko';

  @override
  String get themeSettingsEcoDescription =>
      'Az alkalmazás jellegzetes zöld megjelenése — élénk és könnyen olvasható, enyhén zöld árnyalatú háttérrel.';

  @override
  String get throttleRpmHistogramTitle => 'Hogyan használta a motort';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gázpedál állása';

  @override
  String get throttleRpmHistogramRpmSection => 'Motor fordulatszáma';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Gurulás (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Enyhe (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Határozott (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Teljesen nyomott (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Alapjárat (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Menet (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Élénk (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Erős (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Nincsenek gázpedál- vagy fordulatszámminták ebben az útban.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Utak';

  @override
  String get trajetsStartRecordingButton => 'Rögzítés indítása';

  @override
  String get trajetsResumeRecordingButton => 'Rögzítés folytatása';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Csatlakozás az OBD2-adapterhez…';

  @override
  String get tripStartProgressReadingVehicleData => 'Járműadatok olvasása…';

  @override
  String get tripStartProgressStartingRecording => 'Rögzítés indítása…';

  @override
  String get trajetsEmptyStateTitle => 'Még nincs út';

  @override
  String get trajetsEmptyStateBody =>
      'Az autózások rögzítéséhez érintse a Rögzítés indítása gombot.';

  @override
  String trajetsRowDistance(String km) {
    return '$km km';
  }

  @override
  String trajetsRowDuration(String minutes) {
    return '$minutes perc';
  }

  @override
  String trajetsRowAvgConsumption(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get trajetDetailSummaryTitle => 'Összefoglaló';

  @override
  String get trajetDetailFieldDate => 'Dátum';

  @override
  String get trajetDetailFieldVehicle => 'Jármű';

  @override
  String get trajetDetailFieldAdapter => 'OBD2-adapter';

  @override
  String get trajetDetailFieldDistance => 'Távolság';

  @override
  String get trajetDetailFieldDuration => 'Időtartam';

  @override
  String get trajetDetailFieldAvgConsumption => 'Átl. fogyasztás';

  @override
  String get trajetDetailFieldFuelUsed => 'Felhasznált üzemanyag';

  @override
  String get trajetDetailFieldFuelCost => 'Üzemanyagköltség';

  @override
  String get trajetDetailFieldAvgSpeed => 'Átl. sebesség';

  @override
  String get trajetDetailFieldMaxSpeed => 'Max. sebesség';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Sebesség (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Üzemanyag-arány (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Motorterhelés (%)';

  @override
  String get trajetDetailChartsSection => 'Diagramok';

  @override
  String get trajetsRowColdStartChip => 'Hidegindítás';

  @override
  String get trajetsRowColdStartTooltip =>
      'A motor nem érte el az üzemi hőmérsékletet ezen az úton — az üzemanyag-fogyasztás magasabb volt a szokásosnál.';

  @override
  String get trajetDetailChartEmpty => 'Nincsenek rögzített minták';

  @override
  String get trajetDetailShareAction => 'Megosztás';

  @override
  String get trajetDetailShareImageOption => 'Kép megosztása';

  @override
  String get trajetDetailShareGpxOption => 'GPS-nyomvonal (GPX) megosztása';

  @override
  String get trajetDetailShareGpxEmpty => 'Nincs GPS-adat ezen az úton';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — út $date-n';
  }

  @override
  String get trajetDetailShareError =>
      'Nem sikerült megosztási képet generálni';

  @override
  String get trajetDetailDeleteAction => 'Törlés';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Törli ezt az utat?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ez az út véglegesen eltávolításra kerül az előzményekből.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Mégse';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Törlés';

  @override
  String get tripRecordingObd2NotResponding =>
      'Az OBD2-adapter csatlakoztatva van, de nem küld adatot. Próbáljon másik adaptert, vagy ellenőrizze a jármű diagnosztikai protokollját.';

  @override
  String get trajetsViewAllOnMap => 'Mind a térképen';

  @override
  String get trajetsMapTitle => 'Utak térképen';

  @override
  String get trajetsMapShareGpx => 'GPX megosztása';

  @override
  String get trajetsMapEmpty => 'A kiválasztott utak egyikében sincs GPS-adat.';

  @override
  String get trajetsMapShareError => 'A GPX-fájlt nem sikerült megosztani';

  @override
  String get tripLengthCardTitle => 'Fogyasztás úthossz szerint';

  @override
  String get tripLengthBucketShort => 'Rövid (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Közepes (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Hosszú (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Több adatra van szükség';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count út',
      one: '1 út',
      zero: 'nincs út',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Útvonal';

  @override
  String get tripPathCardSubtitle => 'GPS-sel rögzített útvonal';

  @override
  String get tripPathLegendTitle => 'Fogyasztás';

  @override
  String get tripPathLegendEfficient => 'Hatékony (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Határérték (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Pazarló (≥ 10 L/100km)';

  @override
  String get tripRecordingPinTooltip =>
      'A rögzítés bekapcsolva tartja a képernyőt — több akkumulátort használ';

  @override
  String get tripRecordingPinSemanticOn =>
      'Rögzítési lap rögzítésének feloldása';

  @override
  String get tripRecordingPinSemanticOff => 'Rögzítési lap rögzítése';

  @override
  String get tripRecordingPinHelpTooltip => 'Mit csinál a rögzítés?';

  @override
  String get tripRecordingPinHelpTitle => 'A rögzítésről';

  @override
  String get tripRecordingPinHelpBody =>
      'A rögzítés bekapcsolva tartja a képernyőt, és elrejti a rendszersávokat, hogy az űrlap olvasható maradjon a műszerfalon. Érintsen újra a feloldáshoz. Az út végén automatikusan feloldódik.';

  @override
  String get tripRecordingResumeHintMessage =>
      'A rögzítés a háttérben folytatódik. Érintse a bármelyik képernyő tetején lévő piros sávot a visszatéréshez.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Nyissa meg az aktív utat a Fogyasztás fülről';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Rögzítse a képernyőt a GPS aktív tartásához — az Android korlátozhatja a GPS-t alvás közben.';

  @override
  String get tripRecordingMinimiseTooltip => 'Kicsinyítés lebegő csempére';

  @override
  String get tripRecordingAutoPinTitle =>
      'Mindig rögzítse a felvétel indításakor';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Az űrlap automatikus rögzítése minden út során, ahelyett, hogy mindig megérintené. Több akkumulátort használ.';

  @override
  String get tripRecordingConnectingTitle => 'Felvétel indítása…';

  @override
  String get tripShareAction => 'Megosztás másik fiókkal';

  @override
  String get tripShareSheetTitle => 'Az út megosztása';

  @override
  String get tripShareSheetSubtitle =>
      'Adjon egy másik TankSync-fióknak csak olvasási hozzáférést ehhez a rögzített úthoz.';

  @override
  String get tripShareEmailLabel => 'Címzett e-mail-címe';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Megosztás';

  @override
  String get tripShareCreateLinkButton => 'Megosztási hivatkozás létrehozása';

  @override
  String get tripShareLinkCreated =>
      'Megosztási hivatkozás másolva — illessze be a címzettnek.';

  @override
  String get tripShareSuccess => 'Út megosztva.';

  @override
  String get tripShareRecipientNotFound =>
      'Egyetlen TankSync-fiók sem használja ezt az e-mail-címet.';

  @override
  String get tripShareError =>
      'Az utat nem sikerült megosztani. Próbálja újra.';

  @override
  String get tripShareExistingTitle => 'Megosztva vele';

  @override
  String get tripShareExistingEmpty => 'Még senkivel sincs megosztva.';

  @override
  String get tripShareDirectRecipient => 'Egy fiók';

  @override
  String get tripShareLinkRecipient => 'Megosztási hivatkozás (nem igényelt)';

  @override
  String get tripShareRevokeTooltip => 'Visszavonás';

  @override
  String get tripShareRevoked => 'Megosztás visszavonva.';

  @override
  String get trajetsSharedSectionTitle => 'Velem megosztva';

  @override
  String get trajetsSharedBadge => 'Megosztva';

  @override
  String get unifiedFilterFuel => 'Üzemanyag';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Mindkettő';

  @override
  String get unifiedNoResultsForFilter => 'Nincs eredmény ehhez a szűrőhöz';

  @override
  String get searchFailedSnackbar =>
      'A keresés sikertelen — kérjük, próbálja újra';

  @override
  String get vinLabel => 'VIN (opcionális)';

  @override
  String get vinDecodeTooltip => 'VIN dekódolása';

  @override
  String get vinConfirmAction => 'Igen, automatikus kitöltés';

  @override
  String get vinModifyAction => 'Kézi módosítás';

  @override
  String get veResetAction => 'Volumetrikus hatékonyság visszaállítása';

  @override
  String get vehicleReadVinFromCarButton => 'VIN beolvasása az autóból';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'VIN beolvasása a párosított OBD2-adapterről';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN nem elérhető (9-es mód 02-es PID nem támogatott 2005 előtti járműveken)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN beolvasása sikertelen — kérjük, adja meg kézzel';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'A VIN automatikus beolvasásához először párosítson OBD2-adaptert';

  @override
  String get pickerButtonLabel => 'Kiválasztás katalógusból';

  @override
  String get pickerSearchHint => 'Márka vagy modell keresése';

  @override
  String get pickerHelpText => '50+ támogatott jármű előre kitöltése';

  @override
  String get pickerEmptyResults => 'Nincs egyezés';

  @override
  String get pickerCancel => 'Mégse';

  @override
  String get pickerLoading => 'Katalógus betöltése…';

  @override
  String get vinInfoTooltip => 'Mi az a VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Mi az a VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'A járműazonosító szám egy 17 karakteres kód, amely egyedi az autójára. A vázra van bélyegezve, és a jármű regisztrációs dokumentumán is fel van tüntetve.';

  @override
  String get vinInfoSectionWhyTitle => 'Miért kérjük';

  @override
  String get vinInfoSectionWhyBody =>
      'A VIN dekódolása automatikusan kitölti a motor lökettérfogatát, hengerszámát, modellévét, elsődleges üzemanyagtípusát és össztömegét — megkímélve Önt a műszaki adatok kézi megkeresésétől. Az OBD2-üzemanyag-arány számítás ezeket az értékeket használja a pontos fogyasztási számokhoz.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Adatvédelem';

  @override
  String get vinInfoSectionPrivacyBody =>
      'A VIN-je csak helyben tárolódik az alkalmazás titkosított tárolójában — soha nem kerül fel Sparkilo-szerverekre. Az NHTSA vPIC adatbázist a VIN-nel kérdezik le, de csak anonim műszaki adatokat ad vissza; az NHTSA nem kapcsolja össze a VIN-t személyes adatokkal. Hálózat nélkül az offline keresés csak gyártót és országot ad vissza.';

  @override
  String get vinInfoSectionWhereTitle => 'Hol találja';

  @override
  String get vinInfoSectionWhereBody =>
      'Nézzen be a szélvédőn keresztül a vezető oldali bal alsó saroknál, ellenőrizze a vezető oldali ajtókereten lévő matricát nyitott ajtó esetén, vagy olvassa le a jármű regisztrációs okmányáról.';

  @override
  String get vinInfoDismiss => 'Értem';

  @override
  String get vinConfirmPrivacyNote =>
      'Az Ön VIN-jét az NHTSA ingyenes járműadatbázisában néztük meg — semmi sem kerül el Sparkilo-szerverekre.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online dekódolás';

  @override
  String get gdprVinOnlineDecodeShort =>
      'VIN dekódolása az NHTSA ingyenes nyilvános szolgáltatásán keresztül';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Adapter párosításakor a jármű VIN-je helyileg kerül beolvasásra az autó azonosítása érdekében. Engedélyezés esetén a 17 karakteres VIN-t elküldi az NHTSA ingyenes vPIC szolgáltatásának további adatok kereséséhez (modell, motor lökettérfogata, üzemanyagtípus). Csak a VIN kerül elküldésre — más adat nem hagyja el az eszközt.';

  @override
  String get vehicleDetectedFromVinBadge => '(észlelt)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'VIN alapján észlelve: $summary. Alkalmazza?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Alkalmazás';

  @override
  String get widgetHelpSectionTitle => 'Kezdőképernyő-widget';

  @override
  String get widgetHelpIntro =>
      'Adja hozzá a SparKilo widgetet a kezdőképernyőjéhez, hogy egy pillantásra lássa az üzemanyag- és töltési árakat.';

  @override
  String get widgetHelpAdd =>
      'Adja hozzá az indítóprogram widget-választójából — nyomjon hosszan egy üres területre a kezdőképernyőn, válassza a Widgetek lehetőséget, és keresse meg a SparKilo-t.';

  @override
  String get widgetHelpTap =>
      'Érintsen egy állomást a widgeten az alkalmazásban való megnyitáshoz. Érintse a frissítés ikont az árak frissítéséhez.';

  @override
  String get widgetHelpConfigure =>
      'Android-on nyomjon hosszan a widgetre, és válassza az Újrakonfigurálás lehetőséget a profil, szín és tartalom megváltoztatásához.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Az alábbi beállítások a következő frissítéskor minden telepített widgetre érvényesek.';

  @override
  String get widgetDefaultsColorLabel => 'Színséma';

  @override
  String get widgetDefaultsVariantLabel => 'Tartalomváltozat';

  @override
  String get widgetColorSchemeSystem => 'Rendszer szerint';

  @override
  String get widgetColorSchemeLight => 'Világos';

  @override
  String get widgetColorSchemeDark => 'Sötét';

  @override
  String get widgetColorSchemeBlue => 'Kék';

  @override
  String get widgetColorSchemeGreen => 'Zöld';

  @override
  String get widgetColorSchemeOrange => 'Narancs';

  @override
  String get widgetVariantDefault => 'Csak jelenlegi ár';

  @override
  String get widgetVariantPredictive => 'Prediktív: legjobb tankolási időpont';

  @override
  String get widgetPredictiveNowPrefix => 'most';
}
