// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Ceny pohonných hmôt';

  @override
  String get search => 'Hľadať';

  @override
  String get favorites => 'Obľúbené';

  @override
  String get map => 'Mapa';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Nastavenia';

  @override
  String get gpsLocation => 'Poloha GPS';

  @override
  String get zipCode => 'PSČ';

  @override
  String get zipCodeHint => 'napr. 811 01';

  @override
  String get fuelType => 'Palivo';

  @override
  String get searchRadius => 'Okruh';

  @override
  String get searchNearby => 'Čerpacie stanice v okolí';

  @override
  String get searchButton => 'Hľadať';

  @override
  String get noResults => 'Nenašli sa žiadne čerpacie stanice.';

  @override
  String get startSearch => 'Vyhľadajte čerpacie stanice.';

  @override
  String get open => 'Otvorené';

  @override
  String get closed => 'Zatvorené';

  @override
  String distance(String distance) {
    return '$distance ďaleko';
  }

  @override
  String get price => 'Cena';

  @override
  String get prices => 'Ceny';

  @override
  String get address => 'Adresa';

  @override
  String get openingHours => 'Otváracie hodiny';

  @override
  String get open24h => 'Otvorené 24 hodín';

  @override
  String get navigate => 'Navigovať';

  @override
  String get retry => 'Skúsiť znova';

  @override
  String get apiKeySetup => 'Kľúč API';

  @override
  String get apiKeyDescription =>
      'Zaregistrujte sa raz pre bezplatný kľúč API.';

  @override
  String get apiKeyLabel => 'Kľúč API';

  @override
  String get register => 'Registrácia';

  @override
  String get continueButton => 'Pokračovať';

  @override
  String get welcome => 'Ceny pohonných hmôt';

  @override
  String get welcomeSubtitle => 'Nájdite najlacnejšie palivo vo vašom okolí.';

  @override
  String get profileName => 'Názov profilu';

  @override
  String get preferredFuel => 'Preferované palivo';

  @override
  String get defaultRadius => 'Predvolený okruh';

  @override
  String get landingScreen => 'Úvodná obrazovka';

  @override
  String get homeZip => 'Domáce PSČ';

  @override
  String get newProfile => 'Nový profil';

  @override
  String get editProfile => 'Upraviť profil';

  @override
  String get save => 'Uložiť';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get delete => 'Vymazať';

  @override
  String get activate => 'Aktivovať';

  @override
  String get configured => 'Nakonfigurované';

  @override
  String get notConfigured => 'Nenakonfigurované';

  @override
  String get about => 'O aplikácii';

  @override
  String get openSource => 'Open Source (licencia MIT)';

  @override
  String get sourceCode => 'Zdrojový kód na GitHube';

  @override
  String get noFavorites => 'Žiadne obľúbené';

  @override
  String get noFavoritesHint =>
      'Ťuknite na hviezdičku pri stanici, aby ste ju uložili do obľúbených.';

  @override
  String get language => 'Jazyk';

  @override
  String get country => 'Krajina';

  @override
  String get demoMode => 'Demo režim — ukážkové dáta.';

  @override
  String get setupLiveData => 'Nastaviť živé dáta';

  @override
  String get freeNoKey => 'Zadarmo — kľúč nie je potrebný';

  @override
  String get apiKeyRequired => 'Vyžaduje sa kľúč API';

  @override
  String get skipWithoutKey => 'Pokračovať bez kľúča';

  @override
  String get dataTransparency => 'Transparentnosť údajov';

  @override
  String get storageAndCache => 'Úložisko a vyrovnávacia pamäť';

  @override
  String get clearCache => 'Vymazať vyrovnávaciu pamäť';

  @override
  String get clearAllData => 'Vymazať všetky údaje';

  @override
  String get errorLog => 'Protokol chýb';

  @override
  String stationsFound(int count) {
    return 'Nájdených $count staníc';
  }

  @override
  String get whatIsShared => 'Čo sa zdieľa — a s kým?';

  @override
  String get gpsCoordinates => 'Súradnice GPS';

  @override
  String get gpsReason =>
      'Odosielané s každým vyhľadávaním na nájdenie blízkych staníc.';

  @override
  String get postalCodeData => 'PSČ';

  @override
  String get postalReason =>
      'Prevedené na súradnice prostredníctvom geokódovacej služby.';

  @override
  String get mapViewport => 'Výrez mapy';

  @override
  String get mapReason =>
      'Mapové dlaždice sa načítavajú zo servera. Žiadne osobné údaje sa neprenášajú.';

  @override
  String get apiKeyData => 'Kľúč API';

  @override
  String get apiKeyReason =>
      'Váš osobný kľúč sa odosiela s každou API požiadavkou. Je prepojený s vaším e-mailom.';

  @override
  String get notShared => 'NEZDIEĽA sa:';

  @override
  String get searchHistory => 'História vyhľadávania';

  @override
  String get favoritesData => 'Obľúbené';

  @override
  String get profileNames => 'Názvy profilov';

  @override
  String get homeZipData => 'Domáce PSČ';

  @override
  String get usageData => 'Údaje o používaní';

  @override
  String get privacyBanner =>
      'Táto aplikácia nemá server. Všetky údaje zostávajú na vašom zariadení. Žiadna analytika, sledovanie ani reklamy.';

  @override
  String get storageUsage => 'Využitie úložiska na tomto zariadení';

  @override
  String get settingsLabel => 'Nastavenia';

  @override
  String get profilesStored => 'uložených profilov';

  @override
  String get stationsMarked => 'označených staníc';

  @override
  String get cachedResponses => 'odpovedí vo vyrovnávacej pamäti';

  @override
  String get total => 'Celkom';

  @override
  String get cacheManagement => 'Správa vyrovnávacej pamäte';

  @override
  String get cacheDescription =>
      'Vyrovnávacia pamäť ukladá odpovede API pre rýchlejšie načítanie a offline prístup.';

  @override
  String get stationSearch => 'Vyhľadávanie staníc';

  @override
  String get stationDetails => 'Podrobnosti stanice';

  @override
  String get priceQuery => 'Dopyt na cenu';

  @override
  String get zipGeocoding => 'Geokódovanie PSČ';

  @override
  String minutes(int n) {
    return '$n minút';
  }

  @override
  String hours(int n) {
    return '$n hodín';
  }

  @override
  String get clearCacheTitle => 'Vymazať vyrovnávaciu pamäť?';

  @override
  String get clearCacheBody =>
      'Uložené výsledky hľadania a ceny budú vymazané. Profily, obľúbené a nastavenia zostanú zachované.';

  @override
  String get clearCacheButton => 'Vymazať vyrovnávaciu pamäť';

  @override
  String get deleteAllTitle => 'Vymazať všetky údaje?';

  @override
  String get deleteAllBody =>
      'Toto natrvalo vymaže všetky profily, obľúbené, kľúč API, nastavenia a vyrovnávaciu pamäť. Aplikácia sa resetuje.';

  @override
  String get deleteAllButton => 'Vymazať všetko';

  @override
  String get entries => 'záznamov';

  @override
  String get cacheEmpty => 'Vyrovnávacia pamäť je prázdna';

  @override
  String get noStorage => 'Žiadne využité úložisko';

  @override
  String get apiKeyNote =>
      'Bezplatná registrácia. Údaje od vládnych agentúr pre cenovú transparentnosť.';

  @override
  String get apiKeyFormatError =>
      'Neplatný formát — očakávané UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Podporte tento projekt';

  @override
  String get supportDescription =>
      'Táto aplikácia je bezplatná, s otvoreným zdrojovým kódom a bez reklám. Ak ju považujete za užitočnú, zvážte podporu vývojára.';

  @override
  String get reportBug => 'Nahlásiť chybu / Navrhnúť funkciu';

  @override
  String get privacyPolicy => 'Zásady ochrany súkromia';

  @override
  String get fuels => 'Palivá';

  @override
  String get services => 'Služby';

  @override
  String get zone => 'Zóna';

  @override
  String get highway => 'Diaľnica';

  @override
  String get localStation => 'Miestna stanica';

  @override
  String get lastUpdate => 'Posledná aktualizácia';

  @override
  String get automate24h => '24h/24 — Automat';

  @override
  String get refreshPrices => 'Aktualizovať ceny';

  @override
  String get station => 'Čerpacia stanica';

  @override
  String get locationDenied =>
      'Povolenie polohy zamietnuté. Môžete hľadať podľa PSČ.';

  @override
  String get demoModeBanner => 'Demo režim. Nastavte kľúč API v nastaveniach.';

  @override
  String get sortDistance => 'Vzdialenosť';

  @override
  String get cheap => 'lacné';

  @override
  String get expensive => 'drahé';

  @override
  String stationsOnMap(int count) {
    return '$count staníc';
  }

  @override
  String get loadingFavorites =>
      'Načítavanie obľúbených...\nNajprv vyhľadajte stanice na uloženie údajov.';

  @override
  String get reportPrice => 'Nahlásiť cenu';

  @override
  String get whatsWrong => 'Čo nie je v poriadku?';

  @override
  String get correctPrice => 'Správna cena (napr. 1,459)';

  @override
  String get sendReport => 'Odoslať hlásenie';

  @override
  String get reportSent => 'Hlásenie odoslané. Ďakujeme!';

  @override
  String get enterValidPrice => 'Zadajte platnú cenu';

  @override
  String get cacheCleared => 'Vyrovnávacia pamäť vymazaná.';

  @override
  String get yourPosition => 'Vaša poloha';

  @override
  String get positionUnknown => 'Poloha neznáma';

  @override
  String get distancesFromCenter => 'Vzdialenosti od centra hľadania';

  @override
  String get autoUpdatePosition => 'Automaticky aktualizovať polohu';

  @override
  String get autoUpdateDescription =>
      'Aktualizovať polohu GPS pred každým hľadaním';

  @override
  String get location => 'Poloha';

  @override
  String get switchProfileTitle => 'Krajina zmenená';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Nachádzate sa v $country. Prepnúť na profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Prepnuté na profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Žiadny profil pre túto krajinu';

  @override
  String noProfileForCountry(String country) {
    return 'Nachádzate sa v $country, ale nie je nakonfigurovaný žiadny profil. Vytvorte ho v Nastaveniach.';
  }

  @override
  String get autoSwitchProfile => 'Automatické prepnutie profilu';

  @override
  String get autoSwitchDescription =>
      'Automaticky prepnúť profil pri prekročení hraníc';

  @override
  String get switchProfile => 'Prepnúť';

  @override
  String get dismiss => 'Zavrieť';

  @override
  String get profileCountry => 'Krajina';

  @override
  String get profileLanguage => 'Jazyk';

  @override
  String get settingsStorageDetail => 'Kľúč API, aktívny profil';

  @override
  String get allFuels => 'Všetky';

  @override
  String get priceAlerts => 'Cenové upozornenia';

  @override
  String get noPriceAlerts => 'Žiadne cenové upozornenia';

  @override
  String get noPriceAlertsHint =>
      'Vytvorte upozornenie zo stránky s podrobnosťami stanice.';

  @override
  String alertDeleted(String name) {
    return 'Upozornenie \"$name\" vymazané';
  }

  @override
  String get createAlert => 'Vytvoriť cenové upozornenie';

  @override
  String currentPrice(String price) {
    return 'Aktuálna cena: $price';
  }

  @override
  String get targetPrice => 'Cieľová cena (EUR)';

  @override
  String get enterPrice => 'Zadajte cenu';

  @override
  String get invalidPrice => 'Neplatná cena';

  @override
  String get priceTooHigh => 'Cena príliš vysoká';

  @override
  String get create => 'Vytvoriť';

  @override
  String get alertCreated => 'Cenové upozornenie vytvorené';

  @override
  String get wrongE5Price => 'Nesprávna cena Super E5';

  @override
  String get wrongE10Price => 'Nesprávna cena Super E10';

  @override
  String get wrongDieselPrice => 'Nesprávna cena nafty';

  @override
  String get wrongStatusOpen => 'Zobrazené ako otvorené, ale zatvorené';

  @override
  String get wrongStatusClosed => 'Zobrazené ako zatvorené, ale otvorené';

  @override
  String get searchAlongRouteLabel => 'Pozdĺž trasy';

  @override
  String get searchEvStations => 'Hľadať nabíjacie stanice';

  @override
  String get allStations => 'Všetky stanice';

  @override
  String get bestStops => 'Najlepšie zastávky';

  @override
  String get openInMaps => 'Otvoriť v Mapách';

  @override
  String get noStationsAlongRoute =>
      'Pozdĺž trasy neboli nájdené žiadne stanice';

  @override
  String get evOperational => 'V prevádzke';

  @override
  String get evStatusUnknown => 'Stav neznámy';

  @override
  String evConnectors(int count) {
    return 'Konektory ($count bodov)';
  }

  @override
  String get evNoConnectors => 'Žiadne podrobnosti o konektoroch';

  @override
  String get evUsageCost => 'Náklady na použitie';

  @override
  String get evPricingUnavailable =>
      'Ceny nie sú k dispozícii od poskytovateľa';

  @override
  String get evLastUpdated => 'Naposledy aktualizované';

  @override
  String get evUnknown => 'Neznámy';

  @override
  String get evDataAttribution => 'Údaje z OpenChargeMap (komunitný zdroj)';

  @override
  String get evStatusDisclaimer =>
      'Stav nemusí odrážať dostupnosť v reálnom čase. Ťuknite na aktualizovať pre najnovšie údaje.';

  @override
  String get evNavigateToStation => 'Navigovať na stanicu';

  @override
  String get evRefreshStatus => 'Aktualizovať stav';

  @override
  String get evStatusUpdated => 'Stav aktualizovaný';

  @override
  String get evStationNotFound =>
      'Nie je možné aktualizovať — stanica nenájdená v okolí';

  @override
  String get addedToFavorites => 'Pridané do obľúbených';

  @override
  String get removedFromFavorites => 'Odstránené z obľúbených';

  @override
  String get addFavorite => 'Pridať do obľúbených';

  @override
  String get removeFavorite => 'Odstrániť z obľúbených';

  @override
  String get currentLocation => 'Aktuálna poloha';

  @override
  String get gpsError => 'Chyba GPS';

  @override
  String get couldNotResolve => 'Nie je možné určiť štart alebo cieľ';

  @override
  String get start => 'Štart';

  @override
  String get destination => 'Cieľ';

  @override
  String get cityAddressOrGps => 'Mesto, adresa alebo GPS';

  @override
  String get cityOrAddress => 'Mesto alebo adresa';

  @override
  String get useGps => 'Použiť GPS';

  @override
  String get stop => 'Zastávka';

  @override
  String stopN(int n) {
    return 'Zastávka $n';
  }

  @override
  String get addStop => 'Pridať zastávku';

  @override
  String get searchAlongRoute => 'Hľadať pozdĺž trasy';

  @override
  String get cheapest => 'Najlacnejšia';

  @override
  String nStations(int count) {
    return '$count staníc';
  }

  @override
  String nBest(int count) {
    return '$count najlepších';
  }

  @override
  String get fuelPricesTankerkoenig => 'Ceny palív (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Vyžadované pre vyhľadávanie cien palív v Nemecku';

  @override
  String get evChargingOpenChargeMap => 'Nabíjanie EV (OpenChargeMap)';

  @override
  String get customKey => 'Vlastný kľúč';

  @override
  String get appDefaultKey => 'Predvolený kľúč aplikácie';

  @override
  String get optionalOverrideKey =>
      'Voliteľné: nahradiť vstavaný kľúč aplikácie vlastným';

  @override
  String get requiredForEvSearch =>
      'Vyžadované pre vyhľadávanie nabíjacích staníc EV';

  @override
  String get edit => 'Upraviť';

  @override
  String get fuelPricesApiKey => 'Kľúč API cien palív';

  @override
  String get tankerkoenigApiKey => 'Kľúč API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Kľúč API nabíjania EV';

  @override
  String get openChargeMapApiKey => 'Kľúč API OpenChargeMap';

  @override
  String get routeSegment => 'Úsek trasy';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Zobraziť najlacnejšiu stanicu každých $km km pozdĺž trasy';
  }

  @override
  String get avoidHighways => 'Vyhnúť sa diaľniciam';

  @override
  String get avoidHighwaysDesc =>
      'Výpočet trasy sa vyhýba spoplatneným cestám a diaľniciam';

  @override
  String get showFuelStations => 'Zobraziť čerpacie stanice';

  @override
  String get showFuelStationsDesc =>
      'Zahrnúť benzínové, naftové, LPG, CNG stanice';

  @override
  String get showEvStations => 'Zobraziť nabíjacie stanice';

  @override
  String get showEvStationsDesc =>
      'Zahrnúť elektrické nabíjacie stanice vo výsledkoch';

  @override
  String get noStationsAlongThisRoute =>
      'Pozdĺž tejto trasy neboli nájdené žiadne stanice.';

  @override
  String get fuelCostCalculator => 'Kalkulačka nákladov na palivo';

  @override
  String get distanceKm => 'Vzdialenosť (km)';

  @override
  String get consumptionL100km => 'Spotreba (L/100km)';

  @override
  String get fuelPriceEurL => 'Cena paliva (EUR/L)';

  @override
  String get tripCost => 'Náklady na cestu';

  @override
  String get fuelNeeded => 'Potrebné palivo';

  @override
  String get totalCost => 'Celkové náklady';

  @override
  String get enterCalcValues =>
      'Zadajte vzdialenosť, spotrebu a cenu pre výpočet nákladov na cestu';

  @override
  String get priceHistory => 'História cien';

  @override
  String get noPriceHistory => 'Zatiaľ žiadna história cien';

  @override
  String get noHourlyData => 'Žiadne hodinové údaje';

  @override
  String get noStatistics => 'Žiadne štatistiky k dispozícii';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Priem';

  @override
  String get showAllFuelTypes => 'Zobraziť všetky typy palív';

  @override
  String get connected => 'Pripojené';

  @override
  String get notConnected => 'Nepripojené';

  @override
  String get connectTankSync => 'Pripojiť TankSync';

  @override
  String get disconnectTankSync => 'Odpojiť TankSync';

  @override
  String get viewMyData => 'Zobraziť moje údaje';

  @override
  String get optionalCloudSync =>
      'Voliteľná cloudová synchronizácia pre upozornenia, obľúbené a push notifikácie';

  @override
  String get tapToUpdateGps => 'Ťuknite pre aktualizáciu polohy GPS';

  @override
  String get gpsAutoUpdateHint =>
      'Poloha GPS sa získava automaticky pri hľadaní. Môžete ju tiež aktualizovať manuálne tu.';

  @override
  String get clearGpsConfirm =>
      'Vymazať uloženú polohu GPS? Môžete ju kedykoľvek znova aktualizovať.';

  @override
  String get pageNotFound => 'Stránka nenájdená';

  @override
  String get deleteAllServerData => 'Vymazať všetky údaje servera';

  @override
  String get deleteServerDataConfirm => 'Vymazať všetky údaje servera?';

  @override
  String get deleteEverything => 'Vymazať všetko';

  @override
  String get allDataDeleted => 'Všetky údaje servera vymazané';

  @override
  String get disconnectConfirm => 'Odpojiť TankSync?';

  @override
  String get disconnect => 'Odpojiť';

  @override
  String get myServerData => 'Moje údaje na serveri';

  @override
  String get anonymousUuid => 'Anonymné UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synchronizované údaje';

  @override
  String get pushTokens => 'Push tokeny';

  @override
  String get priceReports => 'Hlásenia cien';

  @override
  String get totalItems => 'Celkom položiek';

  @override
  String get estimatedSize => 'Odhadovaná veľkosť';

  @override
  String get viewRawJson => 'Zobraziť surové údaje ako JSON';

  @override
  String get exportJson => 'Exportovať ako JSON (schránka)';

  @override
  String get jsonCopied => 'JSON skopírovaný do schránky';

  @override
  String get rawDataJson => 'Surové údaje (JSON)';

  @override
  String get close => 'Zavrieť';

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
