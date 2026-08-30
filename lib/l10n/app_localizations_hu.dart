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
  String get fabRunSearch => 'Keresés futtatása';

  @override
  String get routeSearchingChip => 'Az útvonal keresése…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Minden $km km-ben';
  }

  @override
  String get searchCriteriaTitle => 'Keresési feltételek';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km-en belül';
  }

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
  String get freeNoKey => 'Ingyenes — kulcs nem szükséges';

  @override
  String get apiKeyRequired => 'API-kulcs szükséges';

  @override
  String get dataTransparency => 'Adatátláthatóság';

  @override
  String get storageAndCache => 'Tárhely és gyorsítótár';

  @override
  String get clearCache => 'Gyorsítótár törlése';

  @override
  String stationsFound(int count) {
    return '$count kút találva';
  }

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
  String get deleteAllButton => 'Mindent töröl';

  @override
  String get entries => 'bejegyzés';

  @override
  String get cacheEmpty => 'A gyorsítótár üres';

  @override
  String get apiKeyNote =>
      'Ingyenes regisztráció. Adatok a kormányzati ártranszparencia-ügynökségektől.';

  @override
  String get apiKeyFormatError =>
      'Érvénytelen formátum — UUID elvárva (8-4-4-4-12)';

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
  String profileSwitchedTo(String profile) {
    return 'Átváltva: $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return '$name profil létrehozva';
  }

  @override
  String profileCountryTaken(String country) {
    return '$country profilja már létezik — szerkessze helyette.';
  }

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
  String get evPriceFree => 'Ingyenes';

  @override
  String get evPricePayAtLocation => 'Helyszíni fizetés';

  @override
  String get evPriceMembership => 'Tagság szükséges';

  @override
  String get evPriceIndicative => 'Tájékoztató ár';

  @override
  String get evPriceDeclaredByOperator =>
      'Az üzemeltető által megadott tájékoztató ár — ellenőrizze a helyszínen';

  @override
  String get evPriceFranceAttribution =>
      'Árazás: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Legjobb erőfeszítéssel megadott ár az OpenChargeMap-ből — ritka és hiányos lehet.';

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
  String get edit => 'Szerkesztés';

  @override
  String get fuelPricesApiKey => 'Üzemanyagárak API-kulcs';

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
  String get noStationsAlongThisRoute =>
      'Nem találhatók állomások ezen útvonal mentén.';

  @override
  String get fuelCostCalculator => 'Üzemanyagköltség-kalkulátor';

  @override
  String get distanceKm => 'Távolság (km)';

  @override
  String get tripCost => 'Útköltség';

  @override
  String get fuelNeeded => 'Szükséges üzemanyag';

  @override
  String get totalCost => 'Összköltség';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Távolság ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Fogyasztás ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Üzemanyag ára ($unit)';
  }

  @override
  String get calculatorUseMine => 'Használat';

  @override
  String get calculatorApplied => 'Alkalmazva';

  @override
  String get tripDetails => 'Út részletei';

  @override
  String get calculatorRoundTrip => 'Oda-vissza';

  @override
  String get roundTripTotal => 'Oda-vissza összesen';

  @override
  String get costPerDistance => 'Költség km-enként';

  @override
  String get costPerMonth => 'Havi költség';

  @override
  String get calculatorEstimateMonthly => 'Havi költség becslése';

  @override
  String get calculatorTripsPerMonth => 'Utak száma havonta';

  @override
  String get calculatorTripsPerMonthHint => 'pl. 20';

  @override
  String get calculatorReset => 'Visszaállítás';

  @override
  String get calculatorResultPlaceholder =>
      'Adja meg a távolságot, fogyasztást és árat az út költségének megtekintéséhez';

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
  String get noStatistics => 'Nincsenek elérhető statisztikák';

  @override
  String get showAllFuelTypes => 'Összes üzemanyagtípus mutatása';

  @override
  String get connected => 'Csatlakoztatva';

  @override
  String get disconnectTankSync => 'TankSync leválasztása';

  @override
  String get viewMyData => 'Adataim megtekintése';

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
  String get gdprContinueAll => 'Folytatás mindennel';

  @override
  String get gdprContinueSelected => 'Folytatás a kijelöltekkel';

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
  String get voiceAnnouncementProximityRadius => 'Bejelentési sugár';

  @override
  String get voiceAnnouncementCooldown => 'Ismétlési intervallum';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximális ár';

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
  String get obdPermissionDenied =>
      'Adjon Bluetooth-engedélyt a rendszerbeállításokban';

  @override
  String get obdPickerTitle => 'OBD2-adapter kiválasztása';

  @override
  String get obdPickerScanning => 'Adapterek keresése…';

  @override
  String get obdPickerConnecting => 'Csatlakozás…';

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
  String get vehicleBaselineShowDetails => 'Helyzetenkénti bontás mutatása';

  @override
  String get vehicleBaselineHideDetails => 'Helyzetenkénti bontás elrejtése';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Még nem észlelt: $situations. Ezek a vezetési helyzetek még 0 mintát tartalmaznak, így az alap hiányos.';
  }

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
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-engedély szükséges';

  @override
  String get obd2StatusConnectedBody => 'Kész az út rögzítésére.';

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
  String get situationColdStart => 'Hidegindítás';

  @override
  String get situationSustainedLoad => 'Tartós terhelés / vontatás';

  @override
  String get situationPartialDecel => 'Gurulás';

  @override
  String get situationHardAccel => 'Erős gyorsítás';

  @override
  String get situationFuelCut => 'Üzemanyag-elvágás — gurulás';

  @override
  String get tripSaveRecording => 'Út mentése';

  @override
  String get tripSummaryAutoSaved => 'Út automatikusan mentve';

  @override
  String get tripSummaryDone => 'Kész';

  @override
  String get tripSummaryDelete => 'Ennek az útnak a törlése';

  @override
  String get vehicleFuelNotSet => 'Nincs beállítva';

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
  String get vehiclePowerLabel => 'Motorteljesítmény (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps LE';
  }

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
  String get evStatusAvailable => 'Elérhető';

  @override
  String get evStatusOccupied => 'Foglalt';

  @override
  String get evStatusOutOfOrder => 'Meghibásodott';

  @override
  String get evStatusPartial => 'Részlegesen elérhető';

  @override
  String get openOnlyFilter => 'Csak nyitva';

  @override
  String get saveAsDefaults => 'Mentés alapértelmezettként';

  @override
  String get criteriaSavedToProfile => 'Alapértelmezettként mentve';

  @override
  String get updatingFavorites => 'Kedvencek frissítése...';

  @override
  String get fetchingLatestPrices => 'Legújabb árak lekérése';

  @override
  String get noDataAvailable => 'Nincs adat';

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
  String get sectionPrivacyData => 'Adatvédelem és adatok';

  @override
  String get sectionAdvancedDeveloper => 'Haladó és fejlesztői';

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
  String get minimalDriveBehaviour => 'Vezetési stílus';

  @override
  String get coachingShiftUp => 'Sebességet feljebb';

  @override
  String get coachingShiftDown => 'Sebességet lejjebb';

  @override
  String get coachingEasePedal => 'Engedd a gázt';

  @override
  String get coachingVoiceHardAcceleration => 'Óvatosan a gázpedállal';

  @override
  String get coachingVoiceHarshBraking => 'Próbáljon lassabban fékezni';

  @override
  String get coachingVoiceShiftUp =>
      'Kapcsoljon felsőbb fokozatba az üzemanyag-megtakarításhoz';

  @override
  String get coachingVoiceShiftDown =>
      'Váltson alacsonyabb fokozatba, a motor túl sokat dolgozik';

  @override
  String get coachingVoiceEasePedal =>
      'Engedje fel a pedált az üzemanyag-fogyasztás csökkentéséhez';

  @override
  String get coachingVoiceLiftOff => 'Engedje fel a gázpedált és guruljon';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Nézzen távolabbra és emelje fel korábban a lábát';

  @override
  String get coachingVoiceSmoothAccel => 'Gyorsítson simábban';

  @override
  String get coachingVoiceSharpCorner => 'Vedd a kanyarokat kicsit lágyabban';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Ez nagyon erős fékezés volt — tarts nagyobb távolságot';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Nagyon erős gyorsítás — ez tényleg sok üzemanyagot éget';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Nagyon éles kanyar — lassan be, finoman ki';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount hirtelen manőver.',
      one: 'Egy hirtelen manőver.',
      zero: 'Szép, egyenletes — nem volt hirtelen manőver.',
    );
    return 'Út mentve: $distanceKm kilométer, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value liter 100 kilométerenként';
  }

  @override
  String get voiceCoachingSettingTitle => 'Hangos vezetési coaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Halljon hangos tippeket vezetés közben — erős gyorsítás, hirtelen fékezés és sebességváltó-javaslatok';

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
  String get tankSyncSchemaOutdatedTitle =>
      'A felhőadatbázis frissítésre szorul';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'A saját üzemeltetésű TankSync-sémád elavult — egyes adatok nem tudnak szinkronizálódni. Nyisd meg a szinkronizálási varázslót, és futtasd a frissítő SQL-t a Supabase-projektedben.';

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
  String get syncSchemaOutdated =>
      'A TankSync-sémád elavult — futtasd újra az alábbi telepítő SQL-t a legújabb szinkronizált funkciók engedélyezéséhez.';

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
      'A fejlesztő által üzemeltetett megosztott adatbázis — lent látható, mi szinkronizálódik';

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
  String serviceReminderDueNowBody(String label) {
    return '$label most esedékes.';
  }

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
  String get obd2GpsDegradedBannerTitle =>
      'Rögzítés GPS-sel — OBD2 újracsatlakozik';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Rögzítés GPS-szel — várakozás az OBD2-adapterre';

  @override
  String get veResetConfirmTitle =>
      'Visszaállítja a volumetrikus hatékonyságot?';

  @override
  String get veResetConfirmBody =>
      'Ez elveti a tanult volumetrikus hatékonyságot (η_v), és visszaállítja az alapértéket (0,85). Az útszintű üzemanyag-áramlás becslések visszaesnek a gyártói konstansra, amíg a kalibrátor új mintákat nem gyűjt a következő utakból.';

  @override
  String get alertsStationSectionTitle => 'Állomásriasztások';

  @override
  String get alertsStationAdd => 'Állomásriasztás hozzáadása';

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
  String radiusAlertDeleted(String name) {
    return '\"$name\" sugaras riasztás törölve';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 csatlakoztatva: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'OBD2-adapter párosítása';

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
  String get obd2ErrorEngineOff =>
      'Nincs adat a járműtől — indítsd be a motort, és próbáld újra.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Az OBD2-adapter ismeretlen választ küldött. Lehet, hogy nem kompatibilis — próbáljon meg másik adaptert.';

  @override
  String get obd2ErrorDisconnected =>
      'Az OBD2-adapter kapcsolata megszakadt. Csatlakozzon újra, és próbálja újra.';

  @override
  String get obd2ErrorPairingRequired =>
      'Az adapterhez Bluetooth-párosítás szükséges. Húzd ki az adaptert, dugd vissza, majd 5 percen belül próbáld újra.';

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
  String priceAlertNotificationTitle(String station, String fuelType) {
    return '$station - $fuelType';
  }

  @override
  String priceAlertNotificationBody(
    String price,
    String currency,
    String target,
  ) {
    return '$price $currency (cél: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel csökkent a közeli kutakon';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count kút ára akár $cents¢ értékkel csökkent az elmúlt órában';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count kút ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count további';
  }

  @override
  String alertsLastChecked(String when) {
    return 'Utolsó ellenőrzés: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Az árak még nem lettek ellenőrizve a háttérben';

  @override
  String get alertsIosBestEffortNote =>
      'iPhone-on a riasztások ellenőrzése a lehetőségekhez mérten történik: az iOS dönti el, mikor ellenőrizheti az app az árakat a háttérben, így egy riasztás késhet, vagy néha el is maradhat. Az app megnyitása mindig friss ellenőrzést futtat.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Célár ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Küszöb ($currency/L)';
  }

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
  String fuelStationRadarProximity(int percent) {
    return 'Közelség: $percent%';
  }

  @override
  String get pipTapToRestore => 'Koppints a teljes app megnyitásához';

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
  String get authLinkEmailTitle => 'E-mail-cím összekapcsolása';

  @override
  String get authLinkEmailSubtitle =>
      'Kapcsolj hozzá egy e-mail-címet, hogy az adataid szinkronizálódjanak az eszközök között. A jelenlegi kedvenceid és útjaid ezen a fiókon maradnak.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Vendégfiókot használsz ($idPrefix…). Kapcsolj hozzá egy e-mail-címet, hogy a kedvenceid és útjaid szinkronizálódjanak a többi eszközödre.';
  }

  @override
  String get authConfirmationPending =>
      'Mindjárt kész — nézd meg az e-mailjeidet, és kattints a linkre az összekapcsolás befejezéséhez. Az adataid már mentve vannak ezen a fiókon.';

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
  String get aclWakeNotificationTitle => 'Autó csatlakoztatva';

  @override
  String get aclWakeNotificationBody =>
      'Koppints a Sparkilo megnyitásához — az útrögzítés elindulhat.';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Párosítson adaptert az alábbi szakaszban az automatikus rögzítés engedélyezéséhez';

  @override
  String get exportBackupReady =>
      'Biztonsági mentés kész — válasszon célmappát';

  @override
  String get exportBackupFailed =>
      'A biztonsági mentés exportálása sikertelen — kérjük, próbálja újra';

  @override
  String get backupExportProgress => 'Biztonsági mentés exportálása…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Mentve a Letöltésekbe: $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Biztonsági mentés visszaállítása';

  @override
  String get restoreBackupDialogBody =>
      'Az összevonás hozzáadja és frissíti a biztonsági mentés rekordjait, és megőriz mindent, ami már az eszközön van. A csere először törli az összes jelenlegi adatot, majd csak a biztonsági mentést állítja vissza — ez nem vonható vissza.';

  @override
  String get restoreBackupMergeAction => 'Összevonás';

  @override
  String get restoreBackupReplaceAction => 'Összes cseréje';

  @override
  String get restoreBackupEmpty =>
      'Biztonsági mentés visszaállítva — nem tartalmazott rekordokat';

  @override
  String get restoreBackupCorrupt =>
      'Visszaállítás sikertelen — ez a fájl nem érvényes Tankstellen biztonsági mentés';

  @override
  String get restoreBackupFailed =>
      'Visszaállítás sikertelen — a fájl nem olvasható';

  @override
  String get backupImportProgress => 'Biztonsági mentés visszaállítása…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return '$vehicles jármű, $fillUps tankolás, $trips út, $chargingLogs töltési napló összevonva';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Minden adat felváltva: $vehicles jármű, $fillUps tankolás, $trips út, $chargingLogs töltési napló';
  }

  @override
  String get brokenMapChipDisclaimer => 'MAP-leolvasások gyanúsak';

  @override
  String get brokenMapSnackbarUnreliable =>
      'A MAP-érzékelő helytelenül olvas — az üzemanyag-leolvasások akár 50–80%-kal alacsonyabbak lehetnek. Próbáljon másik adaptert.';

  @override
  String get brokenMapBannerHardDisable =>
      'A MAP-érzékelő megbízhatatlan. Élő üzemanyag-arány helyett tankolási átlagokat mutat.';

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
  String get calibrationDirectFuelRateNote =>
      'Ez a jármű közvetlenül jelenti az üzemanyag-átfolyást (PID 5E), ezért a volumetrikus hatásfok kalibrálása nincs használatban — a fogyasztásod mért, nem modellezett.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'A(z) $makeModel dízelnek van jelölve, de egy benzinkatalogus-bejegyzéssel egyezik meg. Érintsen a frissítéshez.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Frissítés';

  @override
  String get catalogResetAction => 'Visszaállítás a járműadatbázisból';

  @override
  String get catalogResetConfirmTitle => 'Visszaállítod a járműadatbázisból?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Ez a jármű tankméretét, motorteljesítményét és hengerűrtartalmát az adatbázis $vehicle értékeire cseréli. A többi mező és a tankolási előzményeid érintetlenek maradnak.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'Nincs ehhez a járműhöz illő bejegyzés a járműadatbázisban.';

  @override
  String get catalogResetDoneSnackbar =>
      'Járműadatok visszaállítva az adatbázisból.';

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
  String get confirmDeleteTitle => 'Törlöd?';

  @override
  String get confirmDeleteBody => 'Biztosan törlöd ezt?';

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
  String get consoGroupVehicles => 'Járművek';

  @override
  String get consoGroupCoaching => 'Vezetés közbeni coaching';

  @override
  String get consoGroupRewards => 'Jutalmak és megtakarítások';

  @override
  String get consoGroupTroubleshooting => 'Hibaelhárítás';

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
  String get moreActionsTooltip => 'Több';

  @override
  String get exportBackupMenuLabel => 'Biztonsági mentés exportálása';

  @override
  String get restoreBackupMenuLabel => 'Biztonsági mentés visszaállítása';

  @override
  String get carbonDashboardMenuLabel => 'Szén-dioxid irányítópult';

  @override
  String get settingsMenuLabel => 'Beállítások';

  @override
  String get consumptionStatsPageTitle => 'Fogyasztási statisztikák';

  @override
  String get consumptionStatsComparisonTitle => 'Ez a hónap vs. múlt hónap';

  @override
  String get consumptionStatsTrendsTitle => 'Időbeli fejlődés';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Legalább két hónap tankolásait naplózza az összehasonlításhoz.';

  @override
  String get consumptionStatsPricePerLiter => 'Átlagos ár/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Liter havonta';

  @override
  String get consumptionStatsChartSpend => 'Kiadás havonta';

  @override
  String get consumptionStatsChartPricePerLiter => 'Ár literenként';

  @override
  String get consumptionStatsChartConsumption => 'L/100km havonta';

  @override
  String get fuelCompareSectionTitle => 'Vezetési költség üzemanyagonként';

  @override
  String get fuelComparePricePerLitre => 'Fizetett literenként';

  @override
  String get fuelCompareCostPer100km => 'Költség 100 km-enként';

  @override
  String get fuelCompareDistance => 'Mért távolság';

  @override
  String get fuelCompareLitres => 'Elfogyasztott liter';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return 'A(z) $winner a legolcsóbb üzemanyagod a vezetéshez';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return 'A(z) $loser $amount-val többe kerül 1000 km-enként';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return 'A(z) $fuel legyőzi a(z) $rival üzemanyagot $price literár alatt';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'A fordulópontot az egyes üzemanyagok mért fogyasztásából számoljuk, így a vezetéseddel együtt mozog.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'A liter és a költség ellentmondhat egymásnak: egy üzemanyag fogyaszthat kevesebb litert 100 km-en, és mégis többe kerülhet kilométerenként, mert más a literár. A kilométerenkénti költség dönt.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teli tank',
      one: 'egy teli tank',
    );
    return 'Ideiglenes — $_temp0 alapján';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teli tank',
      one: 'Egy teli tank',
    );
    return '$_temp0 alapján';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 100 km-enként';

  @override
  String fuelCompareCleanest(String winner) {
    return 'A(z) $winner a legkisebb kibocsátású üzemanyagod';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return 'A(z) $fuel $money-val többe kerül 1000 km-enként, de $co2-val kevesebb CO2-t bocsát ki';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return 'A(z) $fuel egyszerre olcsóbb és tisztább, mint a(z) $rival';
  }

  @override
  String fuelCompareCo2Avoided(
    String distance,
    String fuel,
    String actual,
    String alternative,
    String rival,
    String saved,
  ) {
    return 'A(z) $fuel üzemanyaggal megtett $distance $actual kibocsátással járt $alternative helyett a(z) $rival esetén — $saved megtakarítva';
  }

  @override
  String get fuelCompareCo2Source =>
      'A CO2-értékek kúttól a kerékig becslések (EU JEC WTW v5) a mért fogyasztásodra alkalmazva — tájékoztatásul, nem hitelesített elszámolás.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'A CO2 csak tiszta üzemanyagokra jelenik meg: a keverék kibocsátási tényezője az összetételtől függ, amelyet ez a sor nem rögzít.';

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
  String statCorrectionLiters(String liters) {
    return 'Korrekciók: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Tartalom jelentése';

  @override
  String get contentModerationBlockAction => 'Szerző letiltása';

  @override
  String get contentModerationReportDialogTitle => 'Jelented ezt a tartalmat?';

  @override
  String get contentModerationReportDialogBody =>
      'A jelentés a TankSync-szerveredre kerül felülvizsgálatra, és ez a tartalom rejtve lesz az eszközödön.';

  @override
  String get contentModerationReportConfirmButton => 'Jelentés';

  @override
  String get contentModerationBlockDialogTitle => 'Letiltod ezt a szerzőt?';

  @override
  String get contentModerationBlockDialogBody =>
      'Minden, amit ez a fiók megoszt veled, rejtve lesz ezen az eszközön.';

  @override
  String get contentModerationBlockConfirmButton => 'Letiltás';

  @override
  String get contentModerationReportedSnack =>
      'Jelentés elküldve — tartalom elrejtve.';

  @override
  String get contentModerationReportFailedSnack =>
      'A jelentést nem sikerült elküldeni. Próbáld újra.';

  @override
  String get contentModerationBlockedSnack =>
      'Szerző letiltva — a megosztott tartalma rejtve van.';

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
  String crossBorderCheaper(String country, String km, String price) {
    return '$country állomások $km km-re — €$price/L olcsóbb';
  }

  @override
  String get crossBorderTapToSwitch => 'Érintsen az ország váltásához';

  @override
  String get crossBorderDismissTooltip => 'Elvetés';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Nyissa meg a $source adatforrást ($license) a böngészőben';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand közreműködők';
  }

  @override
  String get developerToolsSectionTitle => 'Fejlesztői eszközök';

  @override
  String get dataAccessTracerExport => 'Adathozzáférési napló exportálása';

  @override
  String get dataAccessTracerExportSuccess =>
      'Adathozzáférési napló mentve a Letöltések mappába.';

  @override
  String get dataAccessTracerExportFailure =>
      'Az adathozzáférési naplót nem sikerült exportálni.';

  @override
  String get dataAccessTracerEmpty =>
      'Még nincs rögzített adathozzáférési esemény — előbb keress vagy nyiss meg kutakat, majd exportálj.';

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
  String developerToolsTestAlertBody(String station) {
    return 'Szintetikus egyezés: a közelben találtunk egy a céljánál olcsóbb állomást.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Először keressen állomásokat, majd futtassa a tesztriadót, hogy az értesítés valódi állomást nyithasson meg.';

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
  String get startupTraceSectionTitle => 'Indítási inicializálási napló';

  @override
  String get startupTraceExportButton => 'Indítási napló exportálása';

  @override
  String get startupTraceEmpty => 'Még nincs rögzített indítási napló.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Összesen: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Indítási napló mentve a Letöltések mappába.';

  @override
  String get startupTraceExportFailure =>
      'Az indítási naplót nem sikerült exportálni.';

  @override
  String get distanceSourceOdometer => 'Kilométer-számláló';

  @override
  String get distanceSourceOdometerTooltip =>
      'Az autó kilométer-számlálójáról leolvasott távolság — mért referenciaérték.';

  @override
  String get distanceSourceGps => 'GPS-nyomvonal';

  @override
  String get distanceSourceGpsTooltip =>
      'A rögzített GPS-nyomvonalból összegzett távolság — a valódi közúti távolság.';

  @override
  String get distanceSourceEstimated => 'Becsült';

  @override
  String get distanceSourceEstimatedTooltip =>
      'A sebességérzékelőből integrált távolság — becslés; az érzékelő általában kicsit felfelé tér el.';

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
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Tartósan nagy sebesség (az út $pctTime%-a): elpazarolt $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Tartósan nagy sebesség (az út $pctTime%-a)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      '110 km/h fölött vegye le a gázt – a légellenállás meredeken nő, kicsit lassabban sok üzemanyag megspórolható.';

  @override
  String get lessonSmoothDrivingTitle => 'Egyenletes vezetés – szép munka!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Nem volt heves gyorsítás vagy fékezés ezen az úton – az egyenletes vezetés alacsonyan tartja a fogyasztást.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Teljes gáz (az út $pctTime%-a): $liters L pazarlás';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Nyomja le finoman a pedált — kíméletes, 70%-os gáznyomással sokkal kevesebb üzemanyaggal éri el a kívánt sebességet.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Gazdag keverék terhelés alatt (az út $pctTime%-a): $liters L pazarlás';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'A nagy, tartós terhelés gazdag keveréket okoz — korai sebességváltással és visszafogással hosszú emelkedőkön tartsa soványan a keveréket.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Emelkedő mászása $gradePercent%-os lejtőn (az út $pctTime%-a): $liters L pazarlás';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Vigyen lendületet a dombra, és adagolja finoman a gázt — emelkedőn való hirtelen gyorsítás extra üzemanyagot éget.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stop-and-go újraindulás: $liters L pazarlás';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Számolja előre a forgalmat, és guruljon a megállók felé, hogy guruljon inkább, mint megálljon teljesen — a holttpontról való elindulás a legfogyasztóbb része a stop-and-go-nak.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'A keverék kissé szegénynek tűnik — a motor üzemanyagot adott hozzá ($pctTrim% korrekció), hogy ellensúlyozza';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'A keverék szegénynek tűnik — a motor tartósan nagy, $pctTrim%-os üzemanyag-hozzáadást tartott fenn; lehetséges hatékonyságvesztés';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'A keverék kissé dúsnak tűnik — a motor üzemanyagot vont el ($pctTrim% korrekció), hogy ellensúlyozza';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'A keverék dúsnak tűnik — a motor tartósan nagy, $pctTrim%-os üzemanyag-elvonást tartott fenn; lehetséges hatékonyságvesztés';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'A motor terhelés alatt dúsan járt (a meleg vezetés $pctShare%-ában) — lehetséges üzemanyag-pazarlás';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heurisztikus állapotjelzés, nem diagnózis';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'A tartósan szegény irányú korrekció szívóoldali levegőszivárgásra, gyenge üzemanyag-ellátásra vagy öregedő érzékelőre utalhat. Ha a fogyasztás vagy a járás romlik, egy szervizdiagnosztika megerősítheti.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'A tartósan dús irányú korrekció szivárgó injektorra, túl magas üzemanyagnyomásra vagy felfelé tévedő érzékelőre utalhat. Ha a fogyasztás vagy a járás romlik, egy szervizdiagnosztika megerősítheti.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'A dús keverék nagy terhelésnél többlet üzemanyagot éget. Válts fel korábban, és engedd el a gázt a hosszú gyorsításoknál, hogy a motor a sztöchiometrikus keverék közelében maradhasson.';

  @override
  String get lessonTransportTitle =>
      'Az út nagy részén hiányoznak a motoradatok';

  @override
  String get lessonTransportAdvice =>
      'A motor szinte a teljes távon nem jelzett aktivitást. Vagy az OBD2-adatfolyam szakadt meg út közben, vagy az autót vezetés nélkül mozgatták — a fogyasztási érték megbízhatatlan, és kimarad a statisztikáidból.';

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
  String get drivingScoreClassVeryGood => 'Kiváló';

  @override
  String get drivingScoreClassGood => 'Jó';

  @override
  String get drivingScoreClassAverage => 'Átlagos';

  @override
  String get drivingScoreClassBad => 'Fejlesztésre szorul';

  @override
  String get drivingScorePenaltyLugging => 'Túlterhelés';

  @override
  String get drivingScorePenaltySmoothness => 'Rázós vezetés';

  @override
  String get drivingScorePenaltyHighSpeed => 'Nagy sebesség';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresszív pedál';

  @override
  String get drivingScorePenaltyLambda => 'Gazdag keverék';

  @override
  String get gpsKpiCardTitle => 'GPS-hatékonyság';

  @override
  String get gpsKpiRpa => 'Pozitív gyorsulás (RPA)';

  @override
  String get gpsKpiPke => 'Mozgási energia igény (PKE)';

  @override
  String get gpsKpiVapos => 'Gyorsulási intenzitás (VAPOS)';

  @override
  String get gpsKpiCoast => 'Gurulás aránya';

  @override
  String get gpsKpiClimbEnergy => 'Emelkedési energia';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct az Ön hatékony alapjához képest';
  }

  @override
  String get drivingTraceCardTitle => 'Vezetéselemzési nyomkövetés (fejl.)';

  @override
  String get drivingTraceCardBody =>
      'Exportálja az út GPS KPI-jeit, pontszámát és leckéit JSON-ként, írja le, hogyan érezte ténylegesen a menetet a megjegyzés mezőbe, és ossza meg vissza, hogy a vezetési stílus küszöbértékei valódi utakkal kalibrálhatók legyenek.';

  @override
  String get drivingTraceExportAction => 'Elemzési nyomkövetés exportálása';

  @override
  String get drivingTraceExported =>
      'Elemzési nyomkövetés mentve a Letöltésekbe — adja hozzá véleményét a megjegyzés mezőbe, és ossza meg vissza.';

  @override
  String get drivingTraceExportFailed =>
      'Nem sikerült exportálni az elemzési nyomkövetést.';

  @override
  String get minimalDriveTripAverage => 'Út átlaga';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Magas fordulaton haladás (az út $pctTime%-a): a korábbi felváltással $liters L spórolható';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Egyenletes tempónál válts fel korábban — ugyanaz a sebesség alacsonyabb fordulaton érezhetően kevesebbet fogyaszt.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Gurulás üzemanyag-lezárással (az út $pctTime%-a): kb. $liters L megtakarítás';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Jól előre láttad — a gáz korai elengedésével a motor gurulás közben teljesen lezárhatja az üzemanyagot.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Hová ment az üzemanyagod';

  @override
  String get fuelBreakdownIdle => 'Alapjárat';

  @override
  String get fuelBreakdownHarshAccel => 'Erős gyorsítások';

  @override
  String get fuelBreakdownHighRpmCruise => 'Magas fordulaton haladás';

  @override
  String get fuelBreakdownCoastingSaved => 'Gurulással megtakarítva';

  @override
  String get fuelBreakdownEfficient => 'Normál vezetés';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Már egy ideje alapjáraton — a motor leállítása üzemanyagot takarít meg';

  @override
  String get ecoNudgeHarshAccel =>
      'Erős gyorsítás — a lágyabb gázláb üzemanyagot takarít meg';

  @override
  String get ecoNudgeHighRpm =>
      'Magas fordulat egyenletes tempónál — a korábbi felváltás üzemanyagot takarít meg';

  @override
  String get obd2CoverageNoneNote =>
      'Ezen az úton nem érkezett motoradat az OBD2-adapterről — az üzemanyagadatok GPS-alapú becslések.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'A motoradatok az út $percent%-ánál megszűntek (a kapcsolat megszakadt) — az azutáni üzemanyagadatok GPS-alapú becslések.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'A motoradatok az út csak $percent%-át fedték le — a hézagoknál GPS-alapú becslések szerepelnek.';
  }

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
  String get featureLabel_approachOverlay => 'Töltőállomás-radar';

  @override
  String get featureDescription_approachOverlay =>
      'Az úszó utazáscsempét élő töltőállomás-radárrá alakítja — ahogy közeledik egy töltőállomáshoz, az üzemanyag típusának színére vált, és megjeleníti az árat.';

  @override
  String get featureLabel_voiceAnnouncements => 'Hangos bejelentések';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Hangosan bejelenti a közeli olcsó töltőállomásokat vezetés közben, hogy szemét az úton tartsa.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Először engedélyezze a töltőállomás-radart';

  @override
  String get featureGroupTitle_finding => 'Keresés és térkép';

  @override
  String get featureGroupDescription_finding =>
      'Hol tankoljon vagy töltsön — keresés, térkép, útvonaltervezés.';

  @override
  String get featureGroupTitle_prices => 'Árak és riasztások';

  @override
  String get featureGroupDescription_prices =>
      'Áresések, előzmények és bejelentések.';

  @override
  String get featureGroupTitle_radar => 'Töltőállomás-radar';

  @override
  String get featureGroupDescription_radar => 'Élő árnudge-ok vezetés közben.';

  @override
  String get featureGroupTitle_sync => 'Szinkronizálás és biztonsági mentés';

  @override
  String get featureGroupDescription_sync =>
      'Tartsa meg adatait minden eszközön.';

  @override
  String get featureGroupTitle_input => 'Bevitel és szkennelés';

  @override
  String get featureGroupDescription_input =>
      'Segédeszközök a tankolások naplózásához.';

  @override
  String get featureGroupTitle_developer => 'Fejlesztői és kísérleti';

  @override
  String get featureGroupDescription_developer =>
      'Haladó és közreműködői eszközök.';

  @override
  String get featureLabel_voiceFeedback =>
      'Hangos visszajelzés (beszédszintézis)';

  @override
  String get featureDescription_voiceFeedback =>
      'Főkapcsoló minden hangos visszajelzéshez — a vezetési hangedzőhöz és a kútbemondásokhoz. Kikapcsolva az app soha nem nyit meg beszédszintetizátort.';

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
  String get fillUpMultiFuelHint =>
      'Ez a jármű többféle üzemanyaggal is mehet — azt rögzítsd, amit valóban tankoltál';

  @override
  String get fillUpGuidanceTitle => 'Legjobb idő tankolni';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'A jelenlegi ár az elmúlt $days nap legolcsóbbjai közé tartozik — jó alkalom tankolni.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Az árak közel vannak a $days napos csúcshoz. Általában olcsóbb $window — érdemes megvárni.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Az árak emelkedő tendenciát mutatnak — tankoljon hamarosan.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'A mai ár a $days napos átlag körül van.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'A tankolás időzítésével kb. $amount/L megtakarítás lehetséges.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count áradat alapján',
      one: '1 áradat alapján',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return '$day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'más időpontokban';

  @override
  String get fillUpGuidanceWeekday1 => 'Hétfőn';

  @override
  String get fillUpGuidanceWeekday2 => 'Kedden';

  @override
  String get fillUpGuidanceWeekday3 => 'Szerdán';

  @override
  String get fillUpGuidanceWeekday4 => 'Csütörtökön';

  @override
  String get fillUpGuidanceWeekday5 => 'Pénteken';

  @override
  String get fillUpGuidanceWeekday6 => 'Szombaton';

  @override
  String get fillUpGuidanceWeekday7 => 'Vasárnap';

  @override
  String get fillUpGuidancePartEarlyMorning => 'kora reggel';

  @override
  String get fillUpGuidancePartMorning => 'reggel';

  @override
  String get fillUpGuidancePartAfternoon => 'délután';

  @override
  String get fillUpGuidancePartEvening => 'este';

  @override
  String get fillUpGuidancePartNight => 'éjjel';

  @override
  String get fillUpOdometerFromCarJustNow => 'Az autójából · az imént';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Az autójából · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Becslés az autó utolsó leolvasásából és az azóta megtett távolságból ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Szöveg beillesztése';

  @override
  String get pasteReceiptDialogTitle => 'Nyugta szövegének beillesztése';

  @override
  String get pasteReceiptDialogHint =>
      'Illeszd be egy üzemanyag-nyugta szövegét — e-mail, SMS vagy megosztott PDF. A liter, a literár, az üzemanyagfajta, a végösszeg és a kút az eszközön kerül kiolvasásra, és előre kitölti az űrlapot. Semmi nem kerül szerverre.';

  @override
  String get pasteReceiptFieldHint => 'Nyugta szövege';

  @override
  String get pasteReceiptParseAction => 'Előkitöltés';

  @override
  String get pasteReceiptNoData =>
      'Nem sikerült üzemanyagadatot kiolvasni ebből a szövegből — ellenőrizd, hogy üzemanyag-nyugta-e, és próbáld újra.';

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
  String get badScanReportTitleReceipt => 'Beolvasási hiba jelentése — Nyugta';

  @override
  String get badScanReportHint =>
      'Megosztjuk a nyugtafotót és mindkét értékkészletet, hogy a következő build megtanulja ezt az elrendezést.';

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
  String get fillUpWarningDialogTitle => 'Ellenőrizd ezt a tankolást';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'A(z) $chosenFuel lett kiválasztva, de ez a jármű $vehicleFuel üzemanyaggal megy.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'A(z) $entered km-es kilométeróra-állás alacsonyabb az előző tankolás $previous km-es értékénél — a távolság nem mehet visszafelé.';
  }

  @override
  String get fillUpWarningGoBack => 'Vissza és javítás';

  @override
  String get fillUpWarningSaveAnyway => 'Mentés mindenképp';

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
  String get fillUpImportReceiptLabel => 'Nyugta';

  @override
  String get fillUpPricePerLiterLabel => 'Liter ára';

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
  String get profileSectionDisplayStations => 'Megjelenítés és állomások';

  @override
  String get profileSectionRegion => 'Régió';

  @override
  String get fuelEfficiencyCardTitle =>
      'Kilométerenkénti költség üzemanyagonként';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Melyik üzemanyag-keverékkel a legolcsóbb valójában vezetni';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Legolcsóbb km-enként: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Tiszta';

  @override
  String get fuelEfficiencyMixBadge => 'Keverék';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Főleg $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Költség/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Összes kiadás';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tankolás',
      one: '1 tankolás',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teli tank',
      one: '1 teli tank',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Rögzíts összetételenként legalább két teli tankot a legolcsóbb kiválasztásához.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'A tankok összetétel szerint vannak csoportosítva: egy tank tiszta, ha egy üzemanyag legalább 85%-át teszi ki, különben keverék.';

  @override
  String get fuelNameE5 => 'Benzin 95';

  @override
  String get fuelNameE10 => 'Benzin 95 E10';

  @override
  String get fuelNameE98 => 'Benzin 98';

  @override
  String get fuelNameDiesel => 'Dízel';

  @override
  String get fuelNameDieselPremium => 'Prémium dízel';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'LPG';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Hidrogén';

  @override
  String get fuelNameElectric => 'Elektromos';

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
  String gdprPolicyLink(int version) {
    return 'Adatvédelmi tájékoztató ($version verzió)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Hozzájárulás megadva: $date · tájékoztató verziója: $version';
  }

  @override
  String get consentNotRecorded => 'Még nincs rögzített hozzájárulás';

  @override
  String serverErasurePartial(String tables) {
    return 'Néhány szerveradatot nem sikerült törölni: $tables. Próbálja újra, vagy küldje el ezt a listát a fejlesztőnek.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Néhány helyi adatot nem sikerült törölni: $steps. Indítsa újra az alkalmazást, és próbálja újra.';
  }

  @override
  String get myCommunityReportsTitle => 'Közösségi jelentéseim';

  @override
  String get myCommunityReportsEmpty => 'Még nem küldött be jelentést';

  @override
  String get deleteReportTooltip => 'Jelentés törlése';

  @override
  String get reportDeleted => 'Jelentés törölve';

  @override
  String get reportDeleteFailed => 'A jelentést nem sikerült törölni';

  @override
  String get privacyControlsTitle => 'Adatvédelmi beállítások';

  @override
  String get tileProxyToggleTitle =>
      'Térképcsempék betöltése a Sparkilo proxyn keresztül';

  @override
  String get tileProxyToggleSubtitle =>
      'Be: a látható térképrészlet és az Ön IP-címe a fejlesztő EU-s szerverére kerül, amely a csempéket az OpenStreetMaptől kéri le. Ki: a csempék közvetlenül a tile.openstreetmap.org címről töltődnek be.';

  @override
  String get remoteLogosToggleTitle => 'Márkalogók betöltése az internetről';

  @override
  String get remoteLogosToggleSubtitle =>
      'Alapértelmezés szerint ki: a beépített helyettesítő képek jelennek meg. Be: a logók a logo.clearbit.com címről töltődnek le, amely látja az Ön IP-címét.';

  @override
  String get privacyExportAllButton => 'Összes adatom exportálása (ZIP)';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName mentve a Letöltésekbe — $count fájlt tartalmaz';
  }

  @override
  String get privacyExportAllFailed => 'Az exportfájlt nem sikerült kiírni';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Üzemeltető: $operator · Supabase, EU (Frankfurt) · szinkronizálja a kedvenceket, riasztásokat, járműveket az alvázszámmal együtt, tankolásokat, értékeléseket, jelentéseket és — ha bekapcsolja — a GPS-es utakat';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Az adatkezelő Ön — a saját Supabase-projektje, mi soha nem látjuk';

  @override
  String get syncModeJoinControllerNotice =>
      'A megosztott adatbázis tulajdonosa az Ön adatainak adatkezelője';

  @override
  String get ugcPublicNoticeTitle => 'Megosztva más felhasználókkal';

  @override
  String get ugcPublicNoticeBody =>
      'Ez a szinkronizációs adatbázisban tárolódik az Ön álnevesített felhasználói azonosítója alatt. A Sparkilo közösségben minden bejelentkezett felhasználó elolvashatja. Bármikor törölheti itt: TankSync → Adatátláthatóság.';

  @override
  String get blockedAuthorsTitle => 'Letiltott felhasználók';

  @override
  String get blockedAuthorsDescription =>
      'Ezeknek a felhasználóknak a megosztott tartalma rejtve marad ezen az eszközön. A feloldás után ismét látható lesz.';

  @override
  String get blockedAuthorsEmpty => 'Nincs letiltott felhasználó';

  @override
  String get blockedAuthorsUnblock => 'Feloldás';

  @override
  String get coachingGpsLiftOff => 'Levenni a lábat';

  @override
  String get coachingGpsAnticipateBrake => 'Előrelátás';

  @override
  String get coachingGpsSmoothAccel => 'Lágy gyorsítás';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'A nyomvonal $pct%-ot fed le — leghosszabb hézag: $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'A nyomvonal $pct%-ot fed le — nincs észlelt hézag';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'app a háttérben';

  @override
  String get gpsCoverageAttrOsBatching => 'a rendszer kötegelte a pozíciókat';

  @override
  String get gpsCoverageAttrGateRejected => 'pozíciók kiszűrve';

  @override
  String get gpsCoverageAttrDeliveryStall => 'késleltetett kézbesítés';

  @override
  String get gpsCoverageAttrSignalLoss => 'jelvesztés';

  @override
  String get gpsCoverageAttrUnknown => 'ismeretlen ok';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Az app előtérszolgáltatás nélkül futott a háttérben, így a rendszer visszafogta a GPS-t. Tartsd bekapcsolva a képernyőt rögzítés közben, vagy kapcsold be a háttérrögzítést, amikor elérhető.';

  @override
  String get gpsCoverageHintOsBatching =>
      'A rendszer későn és kötegekben adta át a pozíciókat; a nyomvonal utólag kiegészült, így valójában kevés adat veszett el.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Ezen a szakaszon a zajos pozíciókat kiszűrtük, hogy a távolság adat őszinte maradjon.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'A pozíciók időben elkészültek, de későn értek az apphoz — a telefon elfoglalt volt (gyakran Bluetooth-újracsatlakozás miatt). A vétel rendben volt.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Megszakadt a GPS-vétel — ez általában alagút, mélygarázs vagy sűrű városi beépítés.';

  @override
  String get gpsCoverageHintUnknown =>
      'Ehhez az úthoz nincs információ az app állapotáról a hézag alatt, így az ok nem állapítható meg.';

  @override
  String get gpsCoverageAttrLinkRecovery => 'OBD2-újracsatlakozás zavarása';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'A hézag egybeesik egy OBD2-újracsatlakozással — az adapterkapcsolat épp helyreállt, miközben a GPS-feldolgozás leállt. Az adapterkapcsolat rendbetétele a nyomvonalat is rendbe hozza.';

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
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Legnagyobb rés: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Folytatva';

  @override
  String get gpsLifecyclePaused => 'Szüneteltetve';

  @override
  String get gpsLifecycleInactive => 'Inaktív';

  @override
  String get gpsKpiVerdictGood => 'Hatékony';

  @override
  String get gpsKpiVerdictModerate => 'Mérsékelt';

  @override
  String get gpsKpiVerdictAggressive => 'Agresszív';

  @override
  String get gpsKpiInterpretationGood =>
      'Egyenletes, takarékos vezetés — így néz ki a hatékonyság.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Elég átlagos vezetés — egy kicsit lágyabb gázadás még többet spórolna.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energiaigényes vezetés — a gáz elengedése és a több gurulás csökkentené a fogyasztást.';

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
  String get tripAvgGpsEstimateTooltip =>
      'GPS-becslés (~) — ezen az úton nincs üzemanyag-szenzor. Az érték sebességből és a jármű kalibrálásából van modellezve; a pontosság javul, ahogy a mátrix érik.';

  @override
  String get gpsRoadUseCardTitle => 'Hogyan használtad az utat';

  @override
  String get gpsRoadUseSpeedSection => 'Hol töltötted az időt';

  @override
  String get gpsRoadUseSpeedIdle => 'Álló (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Város (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Országút (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Gyors (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Hogyan haladtál';

  @override
  String get gpsRoadUsePhaseAccel => 'Gyorsítás';

  @override
  String get gpsRoadUsePhaseSteady => 'Egyenletes tempó';

  @override
  String get gpsRoadUsePhaseCoast => 'Gurulás';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct%';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Sok gurulás — az autót hagyni gurulni fékezés helyett üzemanyagot takarít meg. Szép.';

  @override
  String get gpsRoadUseSource => 'A GPS-nyomvonaladból';

  @override
  String get hapticEcoCoachSettingTitle => 'Valós idejű öko-coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Enyhe haptikus visszajelzés + képernyős tipp, ha menetsebesség közben teljesen letapos';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Kíméletes gáz — a gurulás több üzemanyagot takarít meg';

  @override
  String highwayViaExit(String ref, String km) {
    return 'a(z) $ref kijáraton át · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigálás ide: $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return '$name eltávolítása a kedvencekből';
  }

  @override
  String get showOnMapSemanticLabel => 'Állomások megjelenítése a térképen';

  @override
  String get searchResultsSemanticLabel => 'Keresési eredmények';

  @override
  String get searchCriteriaSemanticLabel =>
      'Keresési feltételek összegzése. Koppintson a szerkesztéshez.';

  @override
  String get noFavoritesSemanticLabel =>
      'Még nincsenek kedvencek. Koppintson egy állomás csillagára, hogy kedvencként mentse.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Az állomás nyitva van',
      'false': 'Az állomás zárva van',
      'other': 'Az állomás zárva van',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Ország: $name, kiválasztva',
      'false': 'Ország: $name',
      'other': 'Ország: $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Nyelv: $name, kiválasztva',
      'false': 'Nyelv: $name',
      'other': 'Nyelv: $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Rendezés: $option, kiválasztva',
      'false': 'Rendezés: $option',
      'other': 'Rendezés: $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Üzemanyag: $type, kiválasztva',
      'false': 'Üzemanyag: $type',
      'other': 'Üzemanyag: $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Töltőállomás: $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Adatvédelmi pajzs üzemanyagcseppel';

  @override
  String get globeIllustrationSemantic => 'Földgömb töltőállomás-jelölőkkel';

  @override
  String get fuelPumpIllustrationSemantic => 'Üzemanyagtöltő árkijelzővel';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, adatforrás: $provider, $keyRequirement, üzemanyagtípusok: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'API-kulcs szükséges';

  @override
  String get countryInfoNoKeyNeeded => 'Ingyenes, kulcs nélkül';

  @override
  String countryInfoDataSource(String provider) {
    return 'Adatok: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Üzemanyagtípusok: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demó';

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
  String get consentSyncTripsAnonymousHint =>
      'Az utak ennek az eszköznek a névtelen fiókja alá kerülnek mentésre. Jelentkezz be e-mail-címmel, hogy más eszközökről is elérd őket.';

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
  String get accelBrakeCardTitle => 'Gyorsítás és fékezés';

  @override
  String get accelBrakeHardAccel => 'Erős gyorsítások';

  @override
  String get accelBrakeHardBrake => 'Hirtelen fékezések';

  @override
  String get accelBrakeSharpCorner => 'Éles kanyarok';

  @override
  String get accelBrakeSource => 'A telefon mozgásérzékelőiből';

  @override
  String lessonHardBrake(String count) {
    return '$count hirtelen fékezési esemény';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Számolja előre a megállásokat, és korábban emelje fel a lábát a gázpedálról — a hirtelen fékezés elveszíti a sebességre fordított üzemanyagot.';

  @override
  String lessonSharpCornering(String count) {
    return '$count éles kanyar';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Lassítson a kanyar előtt, ne benne — az éles kanyar elveszi a sebességet, amelyet aztán vissza kell nyerni.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Utolsó $seconds mp';
  }

  @override
  String get consumptionUnitSettingTitle => 'Fogyasztás mértékegysége';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Így jelenik meg az üzemanyag-fogyasztás az egész alkalmazásban';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automatikus ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Élő fogyasztás időablaka';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Az élő értéket az utolsó néhány másodpercre átlagolja – hosszabb nyugodtabb, rövidebb gyorsabban reagál';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds mp';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'becs. $unit';
  }

  @override
  String get locationConsentTitle => 'Helyhozzáférés';

  @override
  String get locationConsentSubtitle =>
      'Ez az alkalmazás szeretné használni a tartózkodási helyét, hogy közeli benzinkutakat találjon.';

  @override
  String get locationConsentWhatHappens => 'Mi történik a helyadataival:';

  @override
  String get locationConsentBulletApi =>
      'A koordinátáit az üzemanyagár-API-nak küldjük el a közeli kutak megtalálásához.';

  @override
  String get locationConsentBulletNoServer =>
      'A tartózkodási helyét semmilyen szerver nem tárolja — nincs szerver.';

  @override
  String get locationConsentBulletNoTracking =>
      'A helyadatokat nem használjuk reklámra, elemzésre vagy nyomon követésre.';

  @override
  String get locationConsentRevoke =>
      'A helyhozzáférést bármikor visszavonhatja a rendszerbeállításokban. Másik lehetőségként irányítószám szerint is kereshet.';

  @override
  String get locationConsentLegalBasis =>
      'Jogalap: a GDPR 6. cikk (1) bekezdés a) pontja (hozzájárulás)';

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
  String get consumptionMonthlyClimbLabel => 'Mászott';

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
  String get obd2DiagnosticsTitle => 'OBD2 kommunikáció állapota';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops kiesés',
      one: '1 kiesés',
      zero: 'nincs kiesés',
    );
    return '$percent% kész · $duty% terhelés · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Kapcsolat életciklusa';

  @override
  String get obd2DiagnosticsPidSection => 'PID-enkénti eredmények';

  @override
  String get obd2DiagnosticsReconnectSection => 'Újracsatlakozási telemetria';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts újracsatlakozási kísérlet · $successes sikeres · $transitions átmenet · $disconnects besorolt megszakadás';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'Ebben a munkamenetben aktiválódott a csak-GPS tartalék mód.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Ütemező állapota';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Teljesség';

  @override
  String get obd2DiagnosticsSupportSection => 'Felismert támogatott PID-ek';

  @override
  String get obd2DiagnosticsFuelSection => 'Üzemanyag-szint összesítő';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protokoll: $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts kísérlet · $successes ok · $drops kiesés · csatlakozási idő p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Újracsatlakozások: $silent néma · $visible látható';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz ütem · $skips visszaterhelési kihagyás · $demotions lefokozás';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'A dinamikus szint kiéhezett — az RPM / sebesség a szabályozó küszöbe alá esett.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Összesített $percent% · aktív terhelés $duty%';
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
    return '$supported támogatott · $unsupported nem támogatott · $unknown ismeretlen';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Gyanús $suspicious / $total minta';
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
    return '$pid: $polled lekérdezve · $ok ok · $noData ND · $timeout TO · $error hiba · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Dongle inicializálási napló';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokoll $protocol · $start · firmware $firmware · $tier · $pids PID';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'meleg';

  @override
  String get obd2DiagnosticsInitCold => 'hideg';

  @override
  String get obd2DiagnosticsEmpty =>
      'Még nem rögzített OBD2-munkamenet — csatlakoztasson adaptert, és rögzítsen egy utat Fejlesztői módban.';

  @override
  String get obd2DiagnosticsExplain =>
      'Rögzítés közben gyűjtve a dongle↔alkalmazás kommunikáció hibakeresésére — csak Fejlesztői módban gyűjtött adat.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 kommunikáció állapota';

  @override
  String get obd2HealthNavLabel => 'OBD2 kommunikáció állapota';

  @override
  String get obd2HealthLiveSection => 'Élő munkamenet';

  @override
  String get obd2HealthHistorySection => 'Legutóbbi munkamenetek';

  @override
  String get obd2HealthDownloadJson => 'Letöltés JSON-ként';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Csak az inicializálási átirat letöltése';

  @override
  String get obd2HealthDownloadError =>
      'A diagnosztikai fájlt nem sikerült menteni';

  @override
  String get obd2TestAdapterLabel => 'Tesztelendő adapter';

  @override
  String get obd2TestAdapterScanOption => 'Adapter keresése';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Csatlakozás: $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Adapterteszt futtatása';

  @override
  String get obd2TestRunButton => 'Adapterteszt futtatása';

  @override
  String get obd2TestRunPassed => 'Adapterteszt sikeres';

  @override
  String get obd2TestRunFailed => 'Adapterteszt sikertelen';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — a motor áll; indítsd be a motort az élő adatok olvasásához';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed / $total lépés OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Állítsa le az aktív rögzítést az adapterteszt futtatása előtt.';

  @override
  String get obd2TestStepScan => 'Adapter keresése';

  @override
  String get obd2TestStepBluetooth => 'A telefon Bluetooth-ja';

  @override
  String get obd2TestStepConnect => 'Csatlakozás és inicializálás';

  @override
  String get obd2TestStepInfo => 'Adapter adatai';

  @override
  String get obd2TestStepSupportedPids => 'Támogatott PID-ek';

  @override
  String get obd2TestStepProtocol => 'Járműprotokoll';

  @override
  String get obd2TestStepSampleReads => 'Mintaolvasások';

  @override
  String get obd2TestStepSoak => 'Tartós lekérdezés';

  @override
  String get obd2TestStepReconnect => 'Újracsatlakozás teszt';

  @override
  String get obd2TestStepDisconnect => 'Lecsatlakozás';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Időtúllépés';

  @override
  String get obd2TestStatusGarbage => 'Olvashatatlan válasz';

  @override
  String get obd2TestStatusNoResponse => 'Nincs válasz';

  @override
  String get obd2TestStatusFail => 'Sikertelen';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown =>
      'ismeretlen — alapértelmezés: BLE';

  @override
  String get obd2HealthConnectAttemptsSection =>
      'Legutóbbi csatlakozási kísérletek';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Még nincs rögzített csatlakozási kísérlet.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Csatlakozási napló letöltése';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Összes csatlakozási napló letöltése';

  @override
  String get obd2HealthConnectOrigin => 'Eredet';

  @override
  String get obd2HealthConnectTransport => 'Átvitel';

  @override
  String get obd2HealthConnectOutcome => 'Eredmény';

  @override
  String get obd2HealthConnectScanList => 'Talált eszközök';

  @override
  String get obd2HealthConnectSteps => 'Lépések';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Ismeretlen adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Munkamenet rögzítve · $samples motoradat-minta · $percent% lefedettség';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'Mit rögzített ez az út';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$total mintából $samples tartalmazott motoradatot ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Protokoll-egyeztetés: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'A munkamenet véget ért: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'A munkamenet hossza: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'A fogyasztási adatok az adaptertől származnak, nem GPS-becslésből.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'A PID-enkénti kommunikációs részleteket nem rögzítettük ehhez az úthoz. A gyűjtéshez kapcsold be a fejlesztői módot a rögzítés előtt.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nem sikerült elérni a(z) \'$adapterName\'-t — válasszon másik adaptert';
  }

  @override
  String get obd2PickerOtherDevices => 'Más Bluetooth-eszközök';

  @override
  String get obd2PickerTapToTry => 'Nem felismert — koppints a kipróbáláshoz';

  @override
  String get obd2PickerBleOnlyNotice =>
      'Az iPhone csak Bluetooth LE-adapterekkel működik. A csak Classic-ot támogató adaptert (pl. vLinker BM, Konnwei KW902) Androidon kell használni.';

  @override
  String get obd2PairingConfirmHint =>
      'Erősítsd meg a párosítási kérést a telefonodon';

  @override
  String get obd2ScanEmptyTitle => 'Nem található adapter';

  @override
  String get obd2ScanEmptyReady =>
      'A Bluetooth be van kapcsolva, az engedélyek megadva. Ellenőrizd, hogy az adapter be van dugva az OBD2-csatlakozóba és a gyújtás be van kapcsolva, majd keress újra.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Ebben az eszközben nincs Bluetooth Low Energy hardver, így nem tud OBD2-adapterhez csatlakozni.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'A Bluetooth ki van kapcsolva. Kapcsold be az adaptered kereséséhez.';

  @override
  String get obd2ScanBlockedPermission =>
      'A Sparkilónak Bluetooth-engedély kell az adaptered megtalálásához.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'A Bluetooth-engedély véglegesen el lett utasítva. Add meg a rendszerbeállításokban az adaptered kereséséhez.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'A helymeghatározási szolgáltatások ki vannak kapcsolva ezen az eszközön. Az Android ezek bekapcsolását kéri a Bluetooth-adapterek kereséséhez — helyadat nem kerül rögzítésre vagy megosztásra.';

  @override
  String get obd2ScanOpenSettings => 'Beállítások megnyitása';

  @override
  String get obd2WaitingForEngineBanner =>
      'Várakozás a motorra — rögzítés GPS-szel';

  @override
  String get obd2StartEngineToReconnect =>
      'Indítsd be a motort az újracsatlakozáshoz';

  @override
  String get obd2ResetConnectionEngineOff =>
      'A motor áll — indítsd be az újracsatlakozáshoz';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'A motor $minutes perce áll — leállítod a rögzítést?';
  }

  @override
  String get obd2ParkedPromptStop => 'Leállítás';

  @override
  String get obd2ParkedPromptKeep => 'Folytatás';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'A motor az út első $head és utolsó $tail részében állt — a lefedettséget járó motor mellett mérjük.';
  }

  @override
  String get obd2ReconnectInProgress => 'Újracsatlakozás az OBD2-adapteredhez…';

  @override
  String get obd2StatusEngineOff => 'OBD2 szüneteltetve — a motor áll';

  @override
  String get obd2StatusEngineOffBody =>
      'Az adapter elérhető volt, de a járműbusz néma maradt, ezért az automatikus újracsatlakozás szünetel. Folytatódik, ha vezetsz vagy újra megnyitod az appot — vagy csatlakozz újra most.';

  @override
  String get obd2StatusReconnectNow => 'Újracsatlakozás most';

  @override
  String get autoRecordNotificationTitle => 'Automatikus útrögzítés';

  @override
  String get autoRecordNotificationText => 'Az OBD2-adapteredre várakozik';

  @override
  String get obd2ResetConnection => 'Kapcsolat visszaállítása';

  @override
  String get obd2ResetConnectionDone =>
      'Adapter visszaállítva — a kapcsolat helyreállt';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapter visszaállítva — újracsatlakozás a háttérben';

  @override
  String get ocrTesterTitle => 'OCR tesztelő';

  @override
  String get ocrTesterNavLabel => 'OCR tesztelő';

  @override
  String get ocrTesterExplain =>
      'Futtassa a kút/blokk OCR-folyamatot egy kiválasztott fotón, és vizsgálja meg minden lépést — csak Fejlesztői módban érhető el.';

  @override
  String get ocrTesterCapture => 'Fénykép';

  @override
  String get ocrTesterPickImage => 'Kép kiválasztása';

  @override
  String get ocrTesterRun => 'Futtatás';

  @override
  String get ocrTesterCountry => 'Ország';

  @override
  String get ocrTesterCountryNone => 'Alapértelmezett (nincs profil)';

  @override
  String get ocrTesterNoImage =>
      'Válasszon vagy készítsen képet, majd futtassa.';

  @override
  String get ocrTesterRunning => 'OCR futtatása…';

  @override
  String get ocrTesterOverlaySection => 'Blokk-réteg';

  @override
  String get ocrTesterStepsSection => 'Folyamat lépései';

  @override
  String get ocrTesterLegendLabel => 'Címke';

  @override
  String get ocrTesterLegendNumeric => 'Numerikus';

  @override
  String get ocrTesterLegendNoise => 'Zaj';

  @override
  String get ocrTesterLegendDerived => 'Levezetett';

  @override
  String get ocrTesterStageGlare => 'Felvétel / fényvisszaverődés';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Osztályozás';

  @override
  String get ocrTesterStageAssemble => 'Összeállítás';

  @override
  String get ocrTesterStageAnchor => 'Horgony';

  @override
  String get ocrTesterStageFallback => 'Tartalék';

  @override
  String get ocrTesterStageCrossCheck => 'Keresztellenőrzés';

  @override
  String get ocrTesterStageConfidence => 'Konfidencia';

  @override
  String get ocrTesterStageGate => 'Kapu';

  @override
  String get ocrTesterStageBrand => 'Márka';

  @override
  String get ocrTesterStageOverrides => 'Felülírások';

  @override
  String get ocrTesterStageReconcile => 'Egyeztetés';

  @override
  String get ocrTesterStageResult => 'Eredmény';

  @override
  String get ocrTesterChipRead => 'OLVASVA';

  @override
  String get ocrTesterChipDerived => 'LEVEZETETT';

  @override
  String get ocrTesterGateAccepted => 'Elfogadva';

  @override
  String get ocrTesterGateRejected => 'Visszautasítva';

  @override
  String get ocrTesterFallbackBanner =>
      'Egy mezőt magnitúdó-tartalékkal állítottak helyre — ellenőrizze.';

  @override
  String get ocrTesterStageNoData => 'A lépés nem futott le.';

  @override
  String get ocrTesterCopyJson => 'Másolás JSON-ként';

  @override
  String get ocrTesterExportPackage => 'Csomag exportálása';

  @override
  String get ocrTesterCopied => 'OCR-nyomkövetés másolva a vágólapra.';

  @override
  String get ocrTesterExported => 'OCR-csomag mentve a Letöltések mappába.';

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
  String get onboardingObd2ConnectFailed =>
      'Nem sikerült csatlakozni az adapterhez. Újra próbálhatja, vagy kihagyhatja.';

  @override
  String get onboardingPickUseMode =>
      'Válasszon használati módot a folytatáshoz.';

  @override
  String get onboardingObd2LaterNote =>
      'Bluetooth OBD2-adaptert bármikor párosíthatsz később a jármű képernyőjéről, hogy utakat rögzíts és motoradatokat olvass.';

  @override
  String get openNow => 'Nyitva';

  @override
  String get openNowClosed => 'Zárva';

  @override
  String get openHoursUnknown => 'Nyitvatartás ismeretlen';

  @override
  String closesAt(String time) {
    return 'Zár: $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Nyit: $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Nyit: $time';
  }

  @override
  String get open24Hours => 'Éjjel-nappal nyitva';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => '24/7 automatizálás';

  @override
  String get dayMon => 'Hétfő';

  @override
  String get dayTue => 'Kedd';

  @override
  String get dayWed => 'Szerda';

  @override
  String get dayThu => 'Csütörtök';

  @override
  String get dayFri => 'Péntek';

  @override
  String get daySat => 'Szombat';

  @override
  String get daySun => 'Vasárnap';

  @override
  String get dayShortMon => 'H';

  @override
  String get dayShortTue => 'K';

  @override
  String get dayShortWed => 'Sze';

  @override
  String get dayShortThu => 'Cs';

  @override
  String get dayShortFri => 'P';

  @override
  String get dayShortSat => 'Szo';

  @override
  String get dayShortSun => 'V';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Állami ünnepek';

  @override
  String get closedLabel => 'Zárva';

  @override
  String get openingHoursNotAvailable => 'A nyitvatartási idő nem elérhető';

  @override
  String get showAllHours => 'Összes óra megjelenítése';

  @override
  String get showLessHours => 'Kevesebb megjelenítése';

  @override
  String get openStateUnknown => 'Ismeretlen';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'A kút nyitva van',
      'false': 'A kút zárva van',
      'other': 'Nyitvatartási állapot ismeretlen',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Kamera-hozzáférés';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Ez az alkalmazás szeretné használni a kameráját nyugták, kútoszlop-kijelzők és QR-kódok beolvasásához.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Mi történik a kameraképpel:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'A kép kizárólag a nyugta, a kútoszlop kijelzője vagy a QR-kód beolvasására szolgál — a felismerés az Ön eszközén fut.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'A fotó a beolvasás után törlődik.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Semmi nem kerül feltöltésre, hacsak nem küld jelentést egy hibás beolvasásról, és azt meg nem erősíti.';

  @override
  String get permissionRationaleBluetoothTitle => 'Bluetooth-hozzáférés';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Ez az alkalmazás szeretné használni a Bluetooth-t, hogy csatlakozzon az OBD2-adapteréhez.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Mi történik a Bluetooth-szal:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'A Bluetooth kizárólag az OBD2-adapter megkeresésére és az azzal való kommunikációra szolgál.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Az adapter azonosítója az Ön eszközén marad — csak a TankSync révén szinkronizálódik, a járműprofil részeként.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'Android 11 és korábbi verziókon a rendszer a helyzetet is elkéri, mert ott a Bluetooth-keresés helyhozzáférési engedélynek számít.';

  @override
  String get permissionRationaleNotificationsTitle => 'Értesítések';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Ez az alkalmazás értesítéseket szeretne küldeni Önnek az áriasztásokról és az útrögzítés állapotáról.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Mi történik az értesítésekkel:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Az értesítések helyi áriasztásokhoz és az útrögzítés állapotához használatosak.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Az Ön eszközén jönnek létre — semmi nem hagyja el az eszközt.';

  @override
  String get permissionRationaleRevoke =>
      'Ezt bármikor visszavonhatja az eszköz beállításaiban.';

  @override
  String get permissionRationaleLegalBasis =>
      'Jogalap: a GDPR 6. cikk (1) bekezdés a) pontja (hozzájárulás)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'becsült L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Becsült érték (~) — ezen az úton nincs üzemanyag-szenzor, ezért a L/100 km értéket GPS-sebesség és a jármű kalibrálása alapján modellezi a rendszer. Hozzávetőleges (általában ±10–30%, szűkülve a kalibráció érettségével), nem mért adat.';

  @override
  String get tripRecordingPipElapsedCaption => 'eltelt';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: fogyasztási becslések a kúthoz igazítva ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Megnyitod a beolvasott linket?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Ez a QR-kód ide mutat: $host. Csak megbízható linkeket nyiss meg.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Link megnyitása';

  @override
  String get qrLaunchConfirmCancel => 'Mégse';

  @override
  String get radarPinHelpTitle => 'A rögzítésről';

  @override
  String get radarPinHelpBody =>
      'A rögzítés bekapcsolva tartja a képernyőt, és elrejti a rendszersávokat, hogy a legközelebbi állomás kijelzője olvasható maradjon a műszerfalon. Érintse meg újra a feloldáshoz. Automatikusan feloldódik, amikor a radar leáll.';

  @override
  String get radarAutoPinTitle => 'Mindig rögzít, amikor a radar elindul';

  @override
  String get radarAutoPinSubtitle =>
      'Automatikusan rögzíti a radart minden alkalommal, ahelyett, hogy minden alkalommal meg kellene érinteni. Több akkumulátort használ.';

  @override
  String get radarScopeShowScope => 'Radarnézet';

  @override
  String get radarScopeShowList => 'Listanézet';

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
  String get reconcileWorkflowTitle => 'Üzemanyag-egyeztetés';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return '$gap L eltérést találtunk';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return '$pumped L-t tankolt, de a rögzített utak csak $consumed L-t magyaráznak meg. Ez $gap L megmagyarázatlan eltérést hagy.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Ez általában azt jelenti, hogy egy menetet nem rögzítettek (az adapter ki volt húzva vagy az alkalmazás zárva volt), vagy hiányzik illetve tévesen szerepel egy tankolt adat.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Amíg ez nincs feloldva, az üzemanyag-összesítő és az utak összesítője nem fog egyezni.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Segítsen az eltérés azonosításában';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Minden tankolt adat teljes és helyes ehhez a tartályhoz?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Minden menet rögzítve van?';

  @override
  String get reconcileWorkflowAnswerYes => 'Igen';

  @override
  String get reconcileWorkflowAnswerNo => 'Nem';

  @override
  String get reconcileWorkflowPathAHint =>
      'Hiányzik vagy hibás egy tankolás — korrekciót adunk hozzá, hogy a tankolások összeadódjanak.';

  @override
  String get reconcileWorkflowPathBHint =>
      'A tankolások helyesek, de egy menet nem lett rögzítve — virtuális utat adunk hozzá a hiányzó távolságra.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Korrekció literben';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Mekkora volt a nem rögzített menet? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Döntök később';

  @override
  String get reconcileWorkflowBack => 'Vissza';

  @override
  String get reconcileWorkflowNext => 'Tovább';

  @override
  String get reconcileWorkflowApply => 'Alkalmaz';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtuális út — érintse meg a szerkesztéshez';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Virtuális út szerkesztése';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Ez az út azért lett hozzáadva, hogy elszámolja a rögzítés nélkül felhasznált üzemanyagot. Módosítsa a távolságot vagy az üzemanyagot, vagy törölje.';

  @override
  String get reconcileVirtualTrajetDelete => 'Virtuális út törlése';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Feloldatlan üzemanyag/út eltérés: $gap L — érintse meg a feloldáshoz';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Feloldatlan üzemanyag- és úteltérés feloldása';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/munkamenet';

  @override
  String get settingsSearchHint => 'Keresés a beállításokban';

  @override
  String settingsSearchNoResults(String query) {
    return 'Nincs a következőre illeszkedő beállítás: „$query”';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profilok és régió';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Ország, nyelv, üzemanyag, keresési sugár, útvonaltervezés';

  @override
  String get settingsTopicProfilesKeywords =>
      'profil, ország, nyelv, üzemanyag, sugár, irányítószám, útvonal, otthon, értékelés, kezdőképernyő, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Járművek és OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Autóid, tankméret, OBD2-adapter párosítása';

  @override
  String get settingsTopicVehiclesKeywords =>
      'jármű, autó, obd, obd2, adapter, bluetooth, tank, motor, vin, kalibrálás, vehicle, car, engine, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Vezetés és fogyasztás';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, jutalmak, benzinkút-radar, hibaelhárítás';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, öko, haptikus, hang, gamifikáció, radar, gurulás, út, fogyasztás, üzemanyagklub, hűség, obd2 napló, rögzítés, eco, haptic, voice, gamification, glide, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Árak és riasztások';

  @override
  String get settingsTopicPricesSubtitle =>
      'Árriasztások, hangbemondás, árelőzmények, közösségi jelentések';

  @override
  String get settingsTopicPricesKeywords =>
      'riasztás, értesítés, ár, előzmények, előrejelzés, legjobb időpont, közösség, jelentés, qr, fizetés, hang, bemondás, alert, notification, price, history, prediction, community, report, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Mértékegységek és megjelenés';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Téma, távolság mértékegysége, kezdőképernyő-widget';

  @override
  String get settingsTopicUnitsKeywords =>
      'téma, sötét, világos, öko, mértékegység, km, mérföld, widget, szín, megjelenés, kinézet, theme, dark, light, eco, unit, miles, colour, display, appearance';

  @override
  String get settingsTopicFeaturesTitle => 'Funkciók és használati mód';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Használati mód sablonok és minden funkciókapcsoló';

  @override
  String get settingsTopicFeaturesKeywords =>
      'funkció, mód, alap, közepes, teljes, egyéni, kapcsoló, állomástípusok, benzinkutak, töltők, töltés, feature, mode, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Adatforrások és helyzet';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'API-kulcsok, GPS-pozíció, automatikus profilváltás';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, kulcs, gps, helyzet, pozíció, adatforrás, tankerkoenig, opencharge, key, location, data source';

  @override
  String get settingsTopicSyncTitle => 'Szinkronizálás és fiók';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, felhő, fiók, e-mail, eszköz összekapcsolása, szinkronizálás, adatbázis megosztása, névtelen, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacySubtitle =>
      'Hozzájárulások, adatvédelmi irányítópult, tárhely és gyorsítótár';

  @override
  String get settingsTopicPrivacyKeywords =>
      'adatvédelem, hozzájárulás, gdpr, törlés, tárhely, gyorsítótár, adatok, hibajelentés, vin, privacy, consent, delete, erase, storage, cache, data, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Biztonsági mentés és visszaállítás';

  @override
  String get settingsTopicBackupSubtitle =>
      'Adataid teljes biztonsági mentésének exportálása vagy visszaállítása';

  @override
  String get settingsTopicBackupKeywords =>
      'biztonsági mentés, exportálás, visszaállítás, importálás, zip, xml, átvitel, backup, export, restore, import, transfer';

  @override
  String get settingsTopicAdvancedSubtitle =>
      'GitHub-token, fejlesztői eszközök';

  @override
  String get settingsTopicAdvancedKeywords =>
      'fejlesztő, hibakeresés, token, pat, github, diagnosztika, hibanapló, nyomkövetés, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Verzió, licencek, hivatkozások';

  @override
  String get settingsTopicAboutKeywords =>
      'névjegy, verzió, licenc, adományozás, github, forrásmegjelölés, about, version, license, donate, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Kapcsold be a fogyasztáskövetést a Funkciók és használati mód alatt a járművek, a coaching és a jutalmak beállításához.';

  @override
  String get settingsOpenFeaturesLink =>
      'Funkciók és használati mód megnyitása';

  @override
  String get settingsRadarTileSubtitle =>
      'Sugár, ármód, lekérdezés és képernyőrögzítés az aktív profilhoz';

  @override
  String get settingsRadarNoProfileHint =>
      'Először hozz létre egy profilt – a radar beállításai profilonként tárolódnak.';

  @override
  String get settingsRadarPinHeader => 'Képernyőrögzítés';

  @override
  String get settingsAlertsTileSubtitle =>
      'Állomás- és sugárriasztások, amelyek árcsökkenésről értesítenek';

  @override
  String get settingsPriceFeaturesHeader => 'Árfunkciók';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'A hangbemondás ki van kapcsolva. Kapcsold be a Hangvisszajelzést és a Hangbemondást a Funkciók és használati mód alatt, hogy vezetés közben halld a közeli olcsó üzemanyagot.';

  @override
  String get settingsDistanceUnitTitle => 'Távolság mértékegysége';

  @override
  String get settingsDistanceUnitSubtitle => 'Az aktív profil országa alapján';

  @override
  String get settingsObd2AdapterTitle => 'OBD2-adapter';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Az adapterek járművenként párosíthatók – nyiss meg egy járművet az adapter párosításához vagy cseréjéhez';

  @override
  String get settingsStorageDeleteHint =>
      'Az összes helyi adat törlése az adatvédelmi irányítópultról történik.';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Hozzájárulások';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'A Cloud Sync és az útszinkronizálás hozzájárulásai az Adatvédelem és adatok alatt találhatók';

  @override
  String get settingsBackupExportSubtitle =>
      'Járművek, tankolások, utak és töltési naplók ZIP-fájlként';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Adatok egyesítése vagy cseréje egy korábbi biztonsági mentés ZIP-fájljából';

  @override
  String get settingsStationTypesLink =>
      'Az állomástípusok a Funkciók és használati mód alatt állíthatók be';

  @override
  String get routeSearchCriterionLabel =>
      'Állomásválasztás útvonalszakaszonként';

  @override
  String get routeSearchCriterionCheapest => 'Legolcsóbb';

  @override
  String get routeSearchCriterionNearest => 'Az útvonalhoz legközelebbi';

  @override
  String get routeSearchTopNLabel => 'Jelöltek mintavételi pontonként';

  @override
  String routeSearchTopNCaption(int count) {
    return 'Az útvonal minden pontján legfeljebb $count állomást veszünk figyelembe.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Üzemanyag az árkereséshez (hibrid)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'A jármű alapértelmezése';

  @override
  String get scopeThisProfile => 'Ez a profil';

  @override
  String get scopeAllProfiles => 'Minden profil';

  @override
  String get scopeThisVehicle => 'Ez a jármű';

  @override
  String get featureLabel_manualConsumption => 'Kézi fogyasztásnaplózás';

  @override
  String get featureDescription_manualConsumption =>
      'Tankolások és töltések kézi rögzítése (nem kell OBD2-adapter).';

  @override
  String get featureLabel_loyaltyCards => 'Hűségkártyák';

  @override
  String get featureDescription_loyaltyCards =>
      'Üzemanyagklub-/hűségkártyák literenkénti kedvezménnyel az ár-összehasonlításban.';

  @override
  String get featureLabel_startupTrace => 'Indítási inicializálási nyomkövetés';

  @override
  String get featureDescription_startupTrace =>
      'Rögzíti az alkalmazás indításának időmért fázisait, vízesésként mutatja és exportálja – fejlesztői diagnosztika.';

  @override
  String get locationGpsAutoHint =>
      'A GPS-pozíciót kereséskor automatikusan lekérjük. Itt kézzel is frissítheted.';

  @override
  String get locationClearGpsBody =>
      'Törlöd a tárolt GPS-pozíciót? Bármikor újra frissítheted.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Ez a fájltípus még nem importálható — osszon meg helyette egy fényképet a bizonylatról.';

  @override
  String get shareReceiptFailed =>
      'Nem sikerült olvasni a megosztott bizonylatot — próbálja meg újra megosztani, vagy adja hozzá a tankolást manuálisan.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Bizonylat megosztása importáláshoz';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Osszon meg egy bizonylat fotót egy másik alkalmazásból a tankolás előkitöltéséhez — dátum, liter, összeg és állomás az eszközön kerül beolvasásra.';

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
  String get storageRecoveryTitle => 'Tárolási probléma';

  @override
  String get storageRecoveryMessage =>
      'A Sparkilo nem tudta megnyitni a helyi adattárolóját. A tárolófájl sérültnek tűnik.';

  @override
  String get storageRecoveryGuidance =>
      'A helyreállításhoz töröld az alkalmazás tárhelyét a készülék beállításaiban, vagy telepítsd újra az alkalmazást. A kedvenceid és az előzményeid csak ezen az eszközön tárolódnak, ezért nem állíthatók helyre automatikusan.';

  @override
  String syncAdoptTitle(String email) {
    return 'Csatlakozás $email fiókjához';
  }

  @override
  String get syncAdoptSubtitle =>
      'Jelentkezz be ennek a fióknak a jelszavával, hogy az adatai mindkét eszközön elérhetők legyenek.';

  @override
  String get syncAdoptPasswordLabel => 'Fiók jelszava';

  @override
  String get syncAdoptJoinButton => 'Csatlakozás a fiókhoz';

  @override
  String get syncAdoptUseDifferentAccount => 'Inkább másik fiók használata';

  @override
  String get syncDeleteDataTitle => 'Szinkronizált adatok törlése';

  @override
  String get syncDeleteDataSubtitle =>
      'Utak, járművek vagy tankolások eltávolítása a szinkronizációs adatbázisból';

  @override
  String get syncDeleteDataPickTitle => 'Melyik szinkronizált adatokat törlöd?';

  @override
  String get syncDeleteDataCategoryTrips => 'Utak';

  @override
  String get syncDeleteDataCategoryVehicles => 'Járművek';

  @override
  String get syncDeleteDataCategoryFillUps => 'Tankolások';

  @override
  String get syncDeleteDataCategoryEverything => 'Minden';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Törlöd a(z) $category adatokat a szinkronizációs adatbázisból?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Ez eltávolítja a kijelölt adatokat a szinkronizációs adatbázisodból, és azok nem szinkronizálódnak újra a többi eszközödről. Az ezen az eszközön helyben tárolt adatok megmaradnak.';

  @override
  String get syncDeleteDataConfirmAction => 'Törlés a szerverről';

  @override
  String get syncDeleteDataDone => 'Szinkronizált adatok törölve';

  @override
  String get syncDeleteDataFailed =>
      'A szinkronizált adatok törlése nem sikerült — próbáld újra';

  @override
  String get syncRelinkTitle =>
      'A felhőszinkronizálást újra össze kell kapcsolni';

  @override
  String get syncRelinkBody =>
      'Az eszköz mentett szinkronizációs azonosítója ki van jelentkezve. Jelentkezz be az e-mail-címeddel a szinkronizált adataid újbóli összekapcsolásához, vagy kezdd újra egy új azonosítóval.';

  @override
  String get syncRelinkSignInAction =>
      'Bejelentkezés az újbóli összekapcsoláshoz';

  @override
  String get syncRelinkStartFreshAction => 'Kezdés elölről';

  @override
  String get syncRelinkStartFreshTitle => 'Kezded elölről?';

  @override
  String get syncRelinkStartFreshBody =>
      'Új névtelen azonosító jön létre ehhez az eszközhöz. A régi azonosító alatt szinkronizált adatok a szerveren maradnak, de innen már nem lesznek elérhetők, hacsak nem jelentkezel be az ahhoz tartozó e-mail-fiókkal.';

  @override
  String get syncRelinkStartFreshConfirm => 'Kezdés elölről';

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
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km az utolsó tankod fogyasztásával';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Hosszú távú átlag: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Utolsó tankolás: $date · $count út azóta';
  }

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
  String tankLevelSourceFillUp(String date) {
    return 'Az utolsó tankoláshoz rögzítve: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'OBD2 tankszenzor · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Tankkeverék: $mix';
  }

  @override
  String get tankReportTitle => 'Tankjelentés';

  @override
  String tankReportHeadline(String value) {
    return '$value L/100 km';
  }

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Az előző teli tank óta: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km-rel több az előző tanknál';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km-rel kevesebb az előző tanknál';
  }

  @override
  String get tankReportTrendFlat => 'Az előző tankkal azonos szinten';

  @override
  String get tankReportNoPrevious =>
      'A változás a következő teli tank után jelenik meg.';

  @override
  String tankReportCoverage(String pct) {
    return 'A rögzítések ennek a tanknak $pct%-át fedik le';
  }

  @override
  String tankReportRecordedAvg(String value) {
    return 'Rögzített rész: $value L/100 km';
  }

  @override
  String get tankReportExplainHeader => 'Amire a rögzítések utalnak';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Magas fordulat aránya: $cur% (korábban $prev%)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Hirtelen manőverek: $cur/100 km (korábban $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Hidegindítások: $cur (korábban $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Alapjárat aránya: $cur% (korábban $prev%)';
  }

  @override
  String get tankReportCaveat =>
      'A rögzítések esetlegesek, és csak ennek a tanknak egy részét fedik le — ezek az utalások tájékoztató jellegűek, nem a teljes kép.';

  @override
  String tankReportCalibrationUnder(String pct) {
    return 'A rögzített becslések $pct%-kal a kútoszlop értéke alatt járnak';
  }

  @override
  String tankReportCalibrationOver(String pct) {
    return 'A rögzített becslések $pct%-kal a kútoszlop értéke felett járnak';
  }

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
  String get tripSaveProgressFinalizingSummary => 'Összesítés véglegesítése…';

  @override
  String get tripSaveProgressSavingToHistory => 'Mentés az előzményekbe…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Szinkronizálás a háttérben…';

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
  String get trajetDetailChartThrottle => 'Gáz / pedál (%)';

  @override
  String get trajetDetailChartCoolant => 'Hűtőfolyadék (°C)';

  @override
  String get trajetDetailChartAltitudeRelative => 'Magasság (m, az indulástól)';

  @override
  String get trajetDetailChartLambda => 'Parancsolt λ';

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
  String get trajetDetailChartEstimatedBadge => 'becsült';

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
  String get trajetDetailDownloadCsvOption => 'Telemetria letöltése (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Telemetria letöltése (JSON)';

  @override
  String get trajetDetailDownloadError => 'Nem sikerült menteni a fájlt';

  @override
  String get trajetDetailDeleteAction => 'Törlés';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Törli ezt az utat?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ez az út véglegesen eltávolításra kerül az előzményekből.';

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
  String get trajetDetailChartBoost => 'Töltőnyomás (MAP − környezeti)';

  @override
  String get trajetDetailChartIat => 'Szívólevegő-hőmérséklet';

  @override
  String get trajetDetailChartTiming => 'Gyújtás-előszög';

  @override
  String get trajetObd2Degraded =>
      'OBD2-adapterrel indult, de főként GPS-szel rögzült — a motoradatok hiányosak';

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
  String get tripPathLegendEfficient => 'Hatékony (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Határérték (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Pazarló (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Töltőállomás-radar';

  @override
  String get tripRadarScanning => 'Közeli állomások keresése';

  @override
  String get tripRadarNoStationNearby => 'Nincs közeli állomás';

  @override
  String get fuelStationRadarNearer => 'Közelebbi állomás';

  @override
  String get fuelStationRadarFarther => 'Távolabbi állomás';

  @override
  String get fuelStationRadarStart => 'Töltőállomás-radar indítása';

  @override
  String get stopRadar => 'Radar leállítása';

  @override
  String get fuelStationRadarResultBadge => 'Töltőállomás-radar eredménye';

  @override
  String get radarUpdatingLocation => 'A helyzeted frissítése…';

  @override
  String get radarSearching => 'Keresés…';

  @override
  String get highwayModeChip =>
      'Autópálya mód — az útvonaladon előtted lévő kutakat mutatja';

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
  String get tripRecordingSavingTitle => 'Út mentése…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Rögzítés elvetve — nem észlelt mozgás';

  @override
  String get tripRecordingGpsNotificationTitle => 'Az út rögzítése';

  @override
  String get tripRecordingGpsNotificationText =>
      'Az útvonal követése üzemanyag- és vezetési statisztikákhoz';

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
  String get tripVerdictPromptTitle => 'Milyen volt ez az út?';

  @override
  String get tripVerdictSmooth => 'Egyenletes';

  @override
  String get tripVerdictModerate => 'Mérsékelt';

  @override
  String get tripVerdictAggressive => 'Agresszív';

  @override
  String get tripVerdictDismiss => 'Most nem';

  @override
  String get tripVerdictThanks =>
      'Köszönjük — ez segít kalibrálni a vezetéselemzésedet.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Tankolás törölve';

  @override
  String get trajetDeletedUndoSnackbar => 'Rögzítés törölve';

  @override
  String get searchFailedSnackbar =>
      'A keresés sikertelen — kérjük, próbálja újra';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count állomás',
      one: '1 állomás',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Frissítve: $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Továbbá: $names';
  }

  @override
  String get favoriteAdd => 'Hozzáadás a kedvencekhez';

  @override
  String get favoriteRemove => 'Eltávolítás a kedvencekből';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Alap: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Márka nélküli kút';

  @override
  String get unsupportedRegionTitle => 'A régiódban még nem elérhető';

  @override
  String get unsupportedRegionBody =>
      'Az országodhoz még nincsenek üzemanyagáraink, így az eredmények üresek lehetnek vagy másik országból származhatnak. A keresési beállításokban ettől függetlenül választhatsz támogatott országot.';

  @override
  String get unsupportedRegionDismiss => 'Értem';

  @override
  String get configureCountryTitle => 'Állítsd be az országodat';

  @override
  String get configureCountryBody =>
      'Az országod támogatott, de még nincs beállítva — így az árak másik országból származhatnak. Válaszd ki az országodat a keresési beállításokban a helyi árakhoz.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Előfordulhat, hogy többféle üzemanyagot tankolok';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Követi, melyik üzemanyag a legolcsóbb kilométerenként';

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
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'VIN alapján észlelve: $summary. Alkalmazza?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Alkalmazás';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilométerre előre, $fuelType $euros euró $cents';
  }

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
  String get widgetDefaultsThisProfileHint =>
      'Az alábbi választások minden telepített, ezt a profilt mutató widgetre érvényesek a következő frissítéskor.';

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
}
