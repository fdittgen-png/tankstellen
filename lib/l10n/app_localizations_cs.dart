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
}
