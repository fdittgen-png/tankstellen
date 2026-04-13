// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Ceny pohonných hmot';

  @override
  String get search => 'Hledat';

  @override
  String get favorites => 'Oblíbené';

  @override
  String get map => 'Mapa';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Nastavení';

  @override
  String get gpsLocation => 'Poloha GPS';

  @override
  String get zipCode => 'PSČ';

  @override
  String get zipCodeHint => 'např. 110 00';

  @override
  String get fuelType => 'Palivo';

  @override
  String get searchRadius => 'Okruh';

  @override
  String get searchNearby => 'Čerpací stanice poblíž';

  @override
  String get searchButton => 'Hledat';

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
  String get noResults => 'Žádné čerpací stanice nenalezeny.';

  @override
  String get startSearch => 'Hledejte čerpací stanice.';

  @override
  String get open => 'Otevřeno';

  @override
  String get closed => 'Zavřeno';

  @override
  String distance(String distance) {
    return '$distance daleko';
  }

  @override
  String get price => 'Cena';

  @override
  String get prices => 'Ceny';

  @override
  String get address => 'Adresa';

  @override
  String get openingHours => 'Otevírací doba';

  @override
  String get open24h => 'Otevřeno 24 hodin';

  @override
  String get navigate => 'Navigovat';

  @override
  String get retry => 'Zkusit znovu';

  @override
  String get apiKeySetup => 'Klíč API';

  @override
  String get apiKeyDescription =>
      'Zaregistrujte se jednou pro bezplatný klíč API.';

  @override
  String get apiKeyLabel => 'Klíč API';

  @override
  String get register => 'Registrace';

  @override
  String get continueButton => 'Pokračovat';

  @override
  String get welcome => 'Ceny pohonných hmot';

  @override
  String get welcomeSubtitle => 'Najděte nejlevnější palivo ve svém okolí.';

  @override
  String get profileName => 'Název profilu';

  @override
  String get preferredFuel => 'Preferované palivo';

  @override
  String get defaultRadius => 'Výchozí okruh';

  @override
  String get landingScreen => 'Úvodní obrazovka';

  @override
  String get homeZip => 'PSČ domova';

  @override
  String get newProfile => 'Nový profil';

  @override
  String get editProfile => 'Upravit profil';

  @override
  String get save => 'Uložit';

  @override
  String get cancel => 'Zrušit';

  @override
  String get delete => 'Smazat';

  @override
  String get activate => 'Aktivovat';

  @override
  String get configured => 'Nakonfigurováno';

  @override
  String get notConfigured => 'Nenakonfigurováno';

  @override
  String get about => 'O aplikaci';

  @override
  String get openSource => 'Open Source (licence MIT)';

  @override
  String get sourceCode => 'Zdrojový kód na GitHubu';

  @override
  String get noFavorites => 'Žádné oblíbené';

  @override
  String get noFavoritesHint =>
      'Klepněte na hvězdičku u stanice, abyste ji uložili do oblíbených.';

  @override
  String get language => 'Jazyk';

  @override
  String get country => 'Země';

  @override
  String get demoMode => 'Demo režim — ukázková data.';

  @override
  String get setupLiveData => 'Nastavit živá data';

  @override
  String get freeNoKey => 'Zdarma — klíč není potřeba';

  @override
  String get apiKeyRequired => 'Vyžadován klíč API';

  @override
  String get skipWithoutKey => 'Pokračovat bez klíče';

  @override
  String get dataTransparency => 'Transparentnost dat';

  @override
  String get storageAndCache => 'Úložiště a mezipaměť';

  @override
  String get clearCache => 'Vymazat mezipaměť';

  @override
  String get clearAllData => 'Smazat všechna data';

  @override
  String get errorLog => 'Protokol chyb';

  @override
  String stationsFound(int count) {
    return 'Nalezeno $count stanic';
  }

  @override
  String get whatIsShared => 'Co se sdílí — a s kým?';

  @override
  String get gpsCoordinates => 'Souřadnice GPS';

  @override
  String get gpsReason =>
      'Odesílány s každým vyhledáváním pro nalezení blízkých stanic.';

  @override
  String get postalCodeData => 'PSČ';

  @override
  String get postalReason =>
      'Převedeno na souřadnice prostřednictvím geokódovací služby.';

  @override
  String get mapViewport => 'Výřez mapy';

  @override
  String get mapReason =>
      'Mapové dlaždice se načítají ze serveru. Žádné osobní údaje se nepřenášejí.';

  @override
  String get apiKeyData => 'Klíč API';

  @override
  String get apiKeyReason =>
      'Váš osobní klíč se odesílá s každým požadavkem API. Je spojen s vaším e-mailem.';

  @override
  String get notShared => 'NESDÍLÍ se:';

  @override
  String get searchHistory => 'Historie vyhledávání';

  @override
  String get favoritesData => 'Oblíbené';

  @override
  String get profileNames => 'Názvy profilů';

  @override
  String get homeZipData => 'PSČ domova';

  @override
  String get usageData => 'Údaje o používání';

  @override
  String get privacyBanner =>
      'Tato aplikace nemá server. Všechna data zůstávají na vašem zařízení. Žádná analytika, žádné sledování, žádné reklamy.';

  @override
  String get storageUsage => 'Využití úložiště na tomto zařízení';

  @override
  String get settingsLabel => 'Nastavení';

  @override
  String get profilesStored => 'uložených profilů';

  @override
  String get stationsMarked => 'označených stanic';

  @override
  String get cachedResponses => 'odpovědí v mezipaměti';

  @override
  String get total => 'Celkem';

  @override
  String get cacheManagement => 'Správa mezipaměti';

  @override
  String get cacheDescription =>
      'Mezipaměť ukládá odpovědi API pro rychlejší načítání a offline přístup.';

  @override
  String get stationSearch => 'Vyhledávání stanic';

  @override
  String get stationDetails => 'Detail stanice';

  @override
  String get priceQuery => 'Dotaz na cenu';

  @override
  String get zipGeocoding => 'Geokódování PSČ';

  @override
  String minutes(int n) {
    return '$n minut';
  }

  @override
  String hours(int n) {
    return '$n hodin';
  }

  @override
  String get clearCacheTitle => 'Vymazat mezipaměť?';

  @override
  String get clearCacheBody =>
      'Uložené výsledky hledání a ceny budou smazány. Profily, oblíbené a nastavení zůstanou zachovány.';

  @override
  String get clearCacheButton => 'Vymazat mezipaměť';

  @override
  String get deleteAllTitle => 'Smazat všechna data?';

  @override
  String get deleteAllBody =>
      'Tím trvale smažete všechny profily, oblíbené, klíč API, nastavení a mezipaměť. Aplikace bude resetována.';

  @override
  String get deleteAllButton => 'Smazat vše';

  @override
  String get entries => 'záznamů';

  @override
  String get cacheEmpty => 'Mezipaměť je prázdná';

  @override
  String get noStorage => 'Žádné využité úložiště';

  @override
  String get apiKeyNote =>
      'Bezplatná registrace. Data od vládních agentur pro cenovou transparentnost.';

  @override
  String get apiKeyFormatError =>
      'Neplatný formát — očekáváno UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Podpořte tento projekt';

  @override
  String get supportDescription =>
      'Tato aplikace je zdarma, s otevřeným zdrojovým kódem a bez reklam. Pokud ji považujete za užitečnou, zvažte podporu vývojáře.';

  @override
  String get reportBug => 'Nahlásit chybu / Navrhnout funkci';

  @override
  String get privacyPolicy => 'Zásady ochrany soukromí';

  @override
  String get fuels => 'Paliva';

  @override
  String get services => 'Služby';

  @override
  String get zone => 'Zóna';

  @override
  String get highway => 'Dálnice';

  @override
  String get localStation => 'Místní stanice';

  @override
  String get lastUpdate => 'Poslední aktualizace';

  @override
  String get automate24h => '24h/24 — Automat';

  @override
  String get refreshPrices => 'Aktualizovat ceny';

  @override
  String get station => 'Čerpací stanice';

  @override
  String get locationDenied =>
      'Oprávnění k poloze zamítnuto. Můžete hledat podle PSČ.';

  @override
  String get demoModeBanner => 'Demo režim. Nastavte klíč API v nastavení.';

  @override
  String get sortDistance => 'Vzdálenost';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'levné';

  @override
  String get expensive => 'drahé';

  @override
  String stationsOnMap(int count) {
    return '$count stanic';
  }

  @override
  String get loadingFavorites =>
      'Načítání oblíbených...\nNejprve vyhledejte stanice pro uložení dat.';

  @override
  String get reportPrice => 'Nahlásit cenu';

  @override
  String get whatsWrong => 'Co je špatně?';

  @override
  String get correctPrice => 'Správná cena (např. 1,459)';

  @override
  String get sendReport => 'Odeslat hlášení';

  @override
  String get reportSent => 'Hlášení odesláno. Děkujeme!';

  @override
  String get enterValidPrice => 'Zadejte platnou cenu';

  @override
  String get cacheCleared => 'Mezipaměť vymazána.';

  @override
  String get yourPosition => 'Vaše poloha';

  @override
  String get positionUnknown => 'Poloha neznámá';

  @override
  String get distancesFromCenter => 'Vzdálenosti od centra hledání';

  @override
  String get autoUpdatePosition => 'Automaticky aktualizovat polohu';

  @override
  String get autoUpdateDescription =>
      'Aktualizovat polohu GPS před každým hledáním';

  @override
  String get location => 'Poloha';

  @override
  String get switchProfileTitle => 'Země změněna';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Nacházíte se v $country. Přepnout na profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Přepnuto na profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Žádný profil pro tuto zemi';

  @override
  String noProfileForCountry(String country) {
    return 'Nacházíte se v $country, ale není nakonfigurován žádný profil. Vytvořte ho v Nastavení.';
  }

  @override
  String get autoSwitchProfile => 'Automatické přepnutí profilu';

  @override
  String get autoSwitchDescription =>
      'Automaticky přepnout profil při překročení hranic';

  @override
  String get switchProfile => 'Přepnout';

  @override
  String get dismiss => 'Zavřít';

  @override
  String get profileCountry => 'Země';

  @override
  String get profileLanguage => 'Jazyk';

  @override
  String get settingsStorageDetail => 'Klíč API, aktivní profil';

  @override
  String get allFuels => 'Vše';

  @override
  String get priceAlerts => 'Cenové výstrahy';

  @override
  String get noPriceAlerts => 'Žádné cenové výstrahy';

  @override
  String get noPriceAlertsHint =>
      'Vytvořte výstrahu na stránce s podrobnostmi stanice.';

  @override
  String alertDeleted(String name) {
    return 'Výstraha \"$name\" smazána';
  }

  @override
  String get createAlert => 'Vytvořit cenovou výstrahu';

  @override
  String currentPrice(String price) {
    return 'Aktuální cena: $price';
  }

  @override
  String get targetPrice => 'Cílová cena (EUR)';

  @override
  String get enterPrice => 'Zadejte cenu';

  @override
  String get invalidPrice => 'Neplatná cena';

  @override
  String get priceTooHigh => 'Cena příliš vysoká';

  @override
  String get create => 'Vytvořit';

  @override
  String get alertCreated => 'Cenová výstraha vytvořena';

  @override
  String get wrongE5Price => 'Nesprávná cena Super E5';

  @override
  String get wrongE10Price => 'Nesprávná cena Super E10';

  @override
  String get wrongDieselPrice => 'Nesprávná cena nafty';

  @override
  String get wrongStatusOpen => 'Zobrazeno jako otevřeno, ale zavřeno';

  @override
  String get wrongStatusClosed => 'Zobrazeno jako zavřeno, ale otevřeno';

  @override
  String get searchAlongRouteLabel => 'Podél trasy';

  @override
  String get searchEvStations => 'Hledat nabíjecí stanice';

  @override
  String get allStations => 'Všechny stanice';

  @override
  String get bestStops => 'Nejlepší zastávky';

  @override
  String get openInMaps => 'Otevřít v Mapách';

  @override
  String get noStationsAlongRoute =>
      'Podél trasy nebyly nalezeny žádné stanice';

  @override
  String get evOperational => 'V provozu';

  @override
  String get evStatusUnknown => 'Stav neznámý';

  @override
  String evConnectors(int count) {
    return 'Konektory ($count bodů)';
  }

  @override
  String get evNoConnectors => 'Žádné podrobnosti o konektorech';

  @override
  String get evUsageCost => 'Náklady na použití';

  @override
  String get evPricingUnavailable => 'Ceny nejsou k dispozici od poskytovatele';

  @override
  String get evLastUpdated => 'Naposledy aktualizováno';

  @override
  String get evUnknown => 'Neznámý';

  @override
  String get evDataAttribution => 'Data z OpenChargeMap (komunitní zdroj)';

  @override
  String get evStatusDisclaimer =>
      'Stav nemusí odrážet dostupnost v reálném čase. Klepněte na aktualizovat pro získání nejnovějších dat.';

  @override
  String get evNavigateToStation => 'Navigovat na stanici';

  @override
  String get evRefreshStatus => 'Aktualizovat stav';

  @override
  String get evStatusUpdated => 'Stav aktualizován';

  @override
  String get evStationNotFound =>
      'Nelze aktualizovat — stanice nenalezena v okolí';

  @override
  String get addedToFavorites => 'Přidáno do oblíbených';

  @override
  String get removedFromFavorites => 'Odebráno z oblíbených';

  @override
  String get addFavorite => 'Přidat do oblíbených';

  @override
  String get removeFavorite => 'Odebrat z oblíbených';

  @override
  String get currentLocation => 'Aktuální poloha';

  @override
  String get gpsError => 'Chyba GPS';

  @override
  String get couldNotResolve => 'Nelze určit start nebo cíl';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Cíl';

  @override
  String get cityAddressOrGps => 'Město, adresa nebo GPS';

  @override
  String get cityOrAddress => 'Město nebo adresa';

  @override
  String get useGps => 'Použít GPS';

  @override
  String get stop => 'Zastávka';

  @override
  String stopN(int n) {
    return 'Zastávka $n';
  }

  @override
  String get addStop => 'Přidat zastávku';

  @override
  String get searchAlongRoute => 'Hledat podél trasy';

  @override
  String get cheapest => 'Nejlevnější';

  @override
  String nStations(int count) {
    return '$count stanic';
  }

  @override
  String nBest(int count) {
    return '$count nejlepších';
  }

  @override
  String get fuelPricesTankerkoenig => 'Ceny paliv (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Vyžadováno pro vyhledávání cen paliv v Německu';

  @override
  String get evChargingOpenChargeMap => 'Nabíjení EV (OpenChargeMap)';

  @override
  String get customKey => 'Vlastní klíč';

  @override
  String get appDefaultKey => 'Výchozí klíč aplikace';

  @override
  String get optionalOverrideKey =>
      'Volitelné: nahradit vestavěný klíč aplikace vlastním';

  @override
  String get requiredForEvSearch =>
      'Vyžadováno pro vyhledávání nabíjecích stanic EV';

  @override
  String get edit => 'Upravit';

  @override
  String get fuelPricesApiKey => 'Klíč API cen paliv';

  @override
  String get tankerkoenigApiKey => 'Klíč API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Klíč API nabíjení EV';

  @override
  String get openChargeMapApiKey => 'Klíč API OpenChargeMap';

  @override
  String get routeSegment => 'Úsek trasy';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Zobrazit nejlevnější stanici každých $km km podél trasy';
  }

  @override
  String get avoidHighways => 'Vyhnout se dálnicím';

  @override
  String get avoidHighwaysDesc =>
      'Výpočet trasy se vyhýbá placeným silnicím a dálnicím';

  @override
  String get showFuelStations => 'Zobrazit čerpací stanice';

  @override
  String get showFuelStationsDesc =>
      'Zahrnout benzínové, naftové, LPG, CNG stanice';

  @override
  String get showEvStations => 'Zobrazit nabíjecí stanice';

  @override
  String get showEvStationsDesc =>
      'Zahrnout elektrické nabíjecí stanice ve výsledcích';

  @override
  String get noStationsAlongThisRoute =>
      'Podél této trasy nebyly nalezeny žádné stanice.';

  @override
  String get fuelCostCalculator => 'Kalkulačka nákladů na palivo';

  @override
  String get distanceKm => 'Vzdálenost (km)';

  @override
  String get consumptionL100km => 'Spotřeba (L/100km)';

  @override
  String get fuelPriceEurL => 'Cena paliva (EUR/L)';

  @override
  String get tripCost => 'Náklady na cestu';

  @override
  String get fuelNeeded => 'Potřebné palivo';

  @override
  String get totalCost => 'Celkové náklady';

  @override
  String get enterCalcValues =>
      'Zadejte vzdálenost, spotřebu a cenu pro výpočet nákladů na cestu';

  @override
  String get priceHistory => 'Historie cen';

  @override
  String get noPriceHistory => 'Zatím žádná historie cen';

  @override
  String get noHourlyData => 'Žádná hodinová data';

  @override
  String get noStatistics => 'Žádné statistiky k dispozici';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Prům';

  @override
  String get showAllFuelTypes => 'Zobrazit všechny typy paliv';

  @override
  String get connected => 'Připojeno';

  @override
  String get notConnected => 'Nepřipojeno';

  @override
  String get connectTankSync => 'Připojit TankSync';

  @override
  String get disconnectTankSync => 'Odpojit TankSync';

  @override
  String get viewMyData => 'Zobrazit moje data';

  @override
  String get optionalCloudSync =>
      'Volitelná cloudová synchronizace pro výstrahy, oblíbené a push notifikace';

  @override
  String get tapToUpdateGps => 'Klepněte pro aktualizaci polohy GPS';

  @override
  String get gpsAutoUpdateHint =>
      'Poloha GPS se získává automaticky při hledání. Můžete ji také aktualizovat ručně zde.';

  @override
  String get clearGpsConfirm =>
      'Vymazat uloženou polohu GPS? Můžete ji kdykoli znovu aktualizovat.';

  @override
  String get pageNotFound => 'Stránka nenalezena';

  @override
  String get deleteAllServerData => 'Smazat všechna data serveru';

  @override
  String get deleteServerDataConfirm => 'Smazat všechna data serveru?';

  @override
  String get deleteEverything => 'Smazat vše';

  @override
  String get allDataDeleted => 'Všechna data serveru smazána';

  @override
  String get disconnectConfirm => 'Odpojit TankSync?';

  @override
  String get disconnect => 'Odpojit';

  @override
  String get myServerData => 'Moje data na serveru';

  @override
  String get anonymousUuid => 'Anonymní UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synchronizovaná data';

  @override
  String get pushTokens => 'Push tokeny';

  @override
  String get priceReports => 'Hlášení cen';

  @override
  String get totalItems => 'Celkem položek';

  @override
  String get estimatedSize => 'Odhadovaná velikost';

  @override
  String get viewRawJson => 'Zobrazit surová data jako JSON';

  @override
  String get exportJson => 'Exportovat jako JSON (schránka)';

  @override
  String get jsonCopied => 'JSON zkopírován do schránky';

  @override
  String get rawDataJson => 'Surová data (JSON)';

  @override
  String get close => 'Zavřít';

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
  String get alertStatsToday => 'Dnes';

  @override
  String get alertStatsThisWeek => 'Tento tyden';

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
  String get nearestStations => 'Nejblizsi stanice';

  @override
  String get nearestStationsHint =>
      'Najdete nejblizsi stanice pomoci vasi aktualni polohy';

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
      'Enter the device code from your other device to import its favorites and alerts.';

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
      '1. On Device A: copy the device code above\n2. On Device B: paste it in the \"Device code\" field\n3. Tap \"Import data\" to merge favorites and alerts\n4. Both devices will have all combined data\n\nEach device keeps its own anonymous identity. Data is merged, not moved.';
}
