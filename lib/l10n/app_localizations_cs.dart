// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Otevřít vyhledávání';

  @override
  String get fabOpenResults => 'Otevřít výsledky';

  @override
  String get fabRunSearch => 'Spustit vyhledávání';

  @override
  String get fabRefineCriteria => 'Upřesnit vyhledávání';

  @override
  String get routeSearchPartialBanner => 'Hledání dalších stanic…';

  @override
  String get searchCriteriaTitle => 'Kritéria hledání';

  @override
  String get searchCriteriaOpen => 'Hledat';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Do $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Klepněte pro zahájení hledání';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Přepnout zemi?';

  @override
  String countryChangeBody(String country) {
    return 'Přepnutím na $country se změní:';
  }

  @override
  String get countryChangeCurrency => 'Měna';

  @override
  String get countryChangeDistance => 'Vzdálenost';

  @override
  String get countryChangeVolume => 'Objem';

  @override
  String get countryChangePricePerUnit => 'Formát ceny';

  @override
  String get countryChangeNote =>
      'Existující oblíbené položky a záznamy tankování nebudou přepsány; nové záznamy budou používat nové jednotky.';

  @override
  String get countryChangeConfirm => 'Přepnout';

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
  String get cacheTtlGroupNetwork => 'Síť';

  @override
  String get cacheTtlGroupData => 'Data';

  @override
  String get cacheTtlGroupGeocoding => 'Geokódování';

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
  String get reportThisIssue => 'Nahlásit problém';

  @override
  String get reportAlreadySent => 'Tento problém jste již nahlásili.';

  @override
  String get reportConsentTitle => 'Nahlásit na GitHub?';

  @override
  String get reportConsentBody =>
      'Tímto se otevře veřejný problém na GitHubu s podrobnostmi o chybě uvedenými níže. Nejsou zahrnuty žádné souřadnice GPS, klíče API ani osobní údaje.';

  @override
  String get reportConsentConfirm => 'Otevřít GitHub';

  @override
  String get reportConsentCancel => 'Zrušit';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktivní profil';

  @override
  String get configPreferredFuel => 'Preferované palivo';

  @override
  String get configCountry => 'Země';

  @override
  String get configRouteSegment => 'Segment trasy';

  @override
  String get configApiKeysSection => 'Klíče API';

  @override
  String get configTankerkoenigKey => 'Klíč API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Nakonfigurováno';

  @override
  String get configApiKeyNotSet => 'Nenastaveno (ukázkový režim)';

  @override
  String get configApiKeyCommunity => 'Výchozí (komunitní klíč)';

  @override
  String get searchLocationPlaceholder => 'Adresa, PSČ nebo město';

  @override
  String get configEvKey => 'Klíč API pro nabíjení EV';

  @override
  String get configEvKeyCustom => 'Vlastní klíč';

  @override
  String get configEvKeyShared => 'Výchozí (sdílený)';

  @override
  String get configCloudSyncSection => 'Cloudová synchronizace';

  @override
  String get configTankSyncConnected => 'Připojeno';

  @override
  String get configTankSyncDisabled => 'Zakázáno';

  @override
  String get configAuthMode => 'Režim ověřování';

  @override
  String get configAuthEmail => 'E-mail (trvalý)';

  @override
  String get configAuthAnonymous => 'Anonymní (pouze zařízení)';

  @override
  String get configDatabase => 'Databáze';

  @override
  String get configPrivacySummary => 'Přehled ochrany soukromí';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Oblíbené, upozornění a ignorované stanice jsou synchronizovány do vaší soukromé databáze\n• Poloha GPS a klíče API nikdy neopustí vaše zařízení\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Všechna data jsou uložena pouze lokálně na tomto zařízení\n• Žádná data nejsou odesílána na žádný server\n• Klíče API jsou šifrovány v zabezpečeném úložišti zařízení';

  @override
  String get configAuthNoteEmail =>
      'E-mailový účet umožňuje přístup z více zařízení';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymní účet — data vázána na toto zařízení';

  @override
  String get configNone => 'Žádný';

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
  String get demoModeBannerAction => 'Získat živé ceny';

  @override
  String get sortDistance => 'Vzdálenost';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Hodnocení';

  @override
  String get sortPriceDistance => 'Cena/km';

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
  String get routeModeBannerLabel =>
      'Režim trasy — vzdálenosti jsou podél koridoru';

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
  String get routePlanningSection => 'Plánování trasy';

  @override
  String get routeMinSaving => 'Minimální úspora';

  @override
  String get routeMinSavingOff => 'Vypnuto';

  @override
  String get routeMinSavingOffCaption =>
      'Zobrazují se všechny stanice nalezené na trase';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Pouze stanice do $amount od nejlevnější na trase';
  }

  @override
  String get routeDetourBudget => 'Maximální zajížďka';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Zobrazit stanice až $km km od přímé trasy';
  }

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
  String calculatorDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consumption ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Fuel price ($unit)';
  }

  @override
  String get calculatorUseMine => 'Use';

  @override
  String get calculatorApplied => 'Applied';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get calculatorRoundTrip => 'Round trip';

  @override
  String get roundTripTotal => 'Round trip';

  @override
  String get costPerDistance => 'Cost per km';

  @override
  String get costPerMonth => 'Cost per month';

  @override
  String get calculatorEstimateMonthly => 'Estimate monthly cost';

  @override
  String get calculatorTripsPerMonth => 'Trips per month';

  @override
  String get calculatorTripsPerMonthHint => 'e.g. 20';

  @override
  String get calculatorReset => 'Reset';

  @override
  String get calculatorResultPlaceholder =>
      'Fill in distance, consumption and price to see your trip cost';

  @override
  String get priceHistory => 'Historie cen';

  @override
  String get ignoredStationsLabel => 'Ignorováno';

  @override
  String get ratingsLabel => 'Hodnocení';

  @override
  String get favoritesDataCache => 'Data oblíbených';

  @override
  String get citySearchCache => 'Hledání města';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Mazání dat není v komunitním režimu k dispozici. Nejprve se odpojte nebo použijte soukromou databázi.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count sledovaných stanic';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count nakonfigurováno';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count skrytých stanic';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count hodnocených stanic';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Zapomenout všechny synchronizované cesty';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Zapomenout všechny synchronizované cesty?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Každý přehled cesty a blob s podrobnostmi bude odstraněn ze serveru. Vaše lokální historie cest na tomto zařízení nebude ovlivněna.\n\nTuto akci nelze vrátit zpět.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Zapomenout vše';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Všechny synchronizované cesty odstraněny ze serveru';

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
  String get syncedTrips => 'Cesty';

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
  String get account => 'Účet';

  @override
  String get continueAsGuest => 'Pokračovat jako host';

  @override
  String get createAccount => 'Vytvořit účet';

  @override
  String get signIn => 'Přihlásit se';

  @override
  String get upgradeToEmail => 'Vytvořit e-mailový účet';

  @override
  String get savedRoutes => 'Uložené trasy';

  @override
  String get noSavedRoutes => 'Žádné uložené trasy';

  @override
  String get noSavedRoutesHint =>
      'Hledejte podél trasy a uložte ji pro rychlý přístup.';

  @override
  String get saveRoute => 'Uložit trasu';

  @override
  String get routeName => 'Název trasy';

  @override
  String itineraryDeleted(String name) {
    return '$name odstraněno';
  }

  @override
  String loadingRoute(String name) {
    return 'Načítání trasy: $name';
  }

  @override
  String get refreshFailed => 'Obnovení selhalo. Zkuste to znovu.';

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
      'Nastavte aplikaci v několika rychlých krocích.';

  @override
  String get onboardingApiKeyDescription =>
      'Zaregistrujte se pro bezplatný klíč API, nebo přeskočte a prozkoumejte aplikaci s ukázkovými daty.';

  @override
  String get onboardingComplete => 'Vše připraveno!';

  @override
  String get onboardingCompleteHint =>
      'Tato nastavení můžete kdykoli změnit v profilu.';

  @override
  String get onboardingBack => 'Zpět';

  @override
  String get onboardingNext => 'Další';

  @override
  String get onboardingSkip => 'Přeskočit';

  @override
  String get onboardingFinish => 'Začít';

  @override
  String crossBorderNearby(String country) {
    return '$country je poblíž';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km k hranici';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Průměr zde: $price EUR ($count stanic)';
  }

  @override
  String get allPricesView => 'Všechny ceny';

  @override
  String get compactView => 'Kompaktní';

  @override
  String get switchToAllPricesView => 'Přepnout na zobrazení všech cen';

  @override
  String get switchToCompactView => 'Přepnout na kompaktní zobrazení';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Není skladem';

  @override
  String get gdprTitle => 'Vaše soukromí';

  @override
  String get gdprSubtitle =>
      'Tato aplikace respektuje vaše soukromí. Zvolte, která data chcete sdílet. Tato nastavení můžete kdykoli změnit.';

  @override
  String get gdprLocationTitle => 'Přístup k poloze';

  @override
  String get gdprLocationDescription =>
      'Vaše souřadnice jsou odesílány do API pro ceny paliv, aby bylo možné najít blízké stanice. Data o poloze nejsou nikdy uložena na serveru a nejsou používána ke sledování.';

  @override
  String get gdprLocationShort =>
      'Hledání blízkých čerpacích stanic pomocí vaší polohy';

  @override
  String get gdprErrorReportingTitle => 'Hlášení chyb';

  @override
  String get gdprErrorReportingDescription =>
      'Anonymní hlášení pádů pomáhají zlepšovat aplikaci. Žádné osobní údaje nejsou zahrnuty. Hlášení jsou odesílána přes Sentry pouze pokud je nakonfigurováno.';

  @override
  String get gdprErrorReportingShort =>
      'Odesílat anonymní hlášení pádů pro zlepšení aplikace';

  @override
  String get gdprCloudSyncTitle => 'Cloudová synchronizace';

  @override
  String get gdprCloudSyncDescription =>
      'Synchronizujte oblíbené a upozornění mezi zařízeními přes TankSync. Používá anonymní ověřování. Vaše data jsou šifrována při přenosu.';

  @override
  String get gdprCloudSyncShort =>
      'Synchronizovat oblíbené a upozornění mezi zařízeními';

  @override
  String get gdprLegalBasis =>
      'Právní základ: čl. 6 odst. 1 písm. a) GDPR (souhlas). Souhlas můžete kdykoli odvolat v nastavení.';

  @override
  String get gdprAcceptAll => 'Přijmout vše';

  @override
  String get gdprAcceptSelected => 'Přijmout vybrané';

  @override
  String get gdprSettingsHint =>
      'Svá nastavení ochrany soukromí můžete kdykoli změnit.';

  @override
  String get routeSaved => 'Trasa uložena!';

  @override
  String get routeSaveFailed => 'Uložení trasy selhalo';

  @override
  String get sqlCopied => 'SQL zkopírováno do schránky';

  @override
  String get connectionDataCopied => 'Data připojení zkopírována';

  @override
  String get accountDeleted => 'Účet odstraněn. Lokální data zachována.';

  @override
  String get switchedToAnonymous => 'Přepnuto na anonymní relaci';

  @override
  String failedToSwitch(String error) {
    return 'Přepnutí selhalo: $error';
  }

  @override
  String get topicUrlCopied => 'URL tématu zkopírována';

  @override
  String get testNotificationSent => 'Testovací oznámení odesláno!';

  @override
  String get testNotificationFailed => 'Odeslání testovacího oznámení selhalo';

  @override
  String get pushUpdateFailed => 'Aktualizace nastavení push oznámení selhala';

  @override
  String get connectedAsGuest => 'Připojeno jako host';

  @override
  String get accountCreated => 'Účet vytvořen!';

  @override
  String get signedIn => 'Přihlášeno!';

  @override
  String stationHidden(String name) {
    return '$name skryta';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name odstraněna z oblíbených';
  }

  @override
  String invalidApiKey(String error) {
    return 'Neplatný klíč API: $error';
  }

  @override
  String get invalidQrCode => 'Neplatný formát QR kódu';

  @override
  String get invalidQrCodeTankSync =>
      'Neplatný QR kód — očekáván formát TankSync';

  @override
  String get tankSyncConnected => 'TankSync připojen!';

  @override
  String get syncCompleted => 'Synchronizace dokončena — data obnovena';

  @override
  String get deviceCodeCopied => 'Kód zařízení zkopírován';

  @override
  String get undo => 'Zpět';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Zadejte platné ${length}místné $label';
  }

  @override
  String get freshnessAgo => 'zpět';

  @override
  String get freshnessStale => 'Neaktuální';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Aktuálnost dat: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Logo $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hodnotit $count hvězdičkami',
      one: 'Hodnotit 1 hvězdičkou',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Slabé';

  @override
  String get passwordStrengthFair => 'Dobré';

  @override
  String get passwordStrengthStrong => 'Silné';

  @override
  String get passwordReqMinLength => 'Alespoň 8 znaků';

  @override
  String get passwordReqUppercase => 'Alespoň 1 velké písmeno';

  @override
  String get passwordReqLowercase => 'Alespoň 1 malé písmeno';

  @override
  String get passwordReqDigit => 'Alespoň 1 číslice';

  @override
  String get passwordReqSpecial => 'Alespoň 1 speciální znak';

  @override
  String get passwordTooWeak => 'Heslo nesplňuje všechny požadavky';

  @override
  String get brandFilterAll => 'Vše';

  @override
  String get brandFilterNoHighway => 'Bez dálnice';

  @override
  String get swipeTutorialMessage =>
      'Přejeďte doprava pro navigaci, doleva pro odstranění';

  @override
  String get swipeTutorialDismiss => 'Rozumím';

  @override
  String get alertStatsActive => 'Aktivni';

  @override
  String get alertStatsToday => 'Dnes';

  @override
  String get alertStatsThisWeek => 'Tento tyden';

  @override
  String get privacyDashboardTitle => 'Přehled ochrany soukromí';

  @override
  String get privacyDashboardSubtitle =>
      'Zobrazit, exportovat nebo smazat vaše data';

  @override
  String get privacyDashboardBanner =>
      'Vaše data patří vám. Zde vidíte vše, co tato aplikace ukládá, můžete to exportovat nebo smazat.';

  @override
  String get privacyLocalData => 'Data na tomto zařízení';

  @override
  String get privacyIgnoredStations => 'Ignorované stanice';

  @override
  String get privacyRatings => 'Hodnocení stanic';

  @override
  String get privacyPriceHistory => 'Stanice s historií cen';

  @override
  String get privacyProfiles => 'Vyhledávací profily';

  @override
  String get privacyItineraries => 'Uložené trasy';

  @override
  String get privacyCacheEntries => 'Záznamy mezipaměti';

  @override
  String get privacyApiKey => 'Uložený klíč API';

  @override
  String get privacyEvApiKey => 'Uložený klíč API pro EV';

  @override
  String get privacyEstimatedSize => 'Odhadovaný úložný prostor';

  @override
  String get privacySyncedData => 'Cloudová synchronizace (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Cloudová synchronizace je zakázána. Všechna data zůstávají pouze na tomto zařízení.';

  @override
  String get privacySyncMode => 'Režim synchronizace';

  @override
  String get privacySyncUserId => 'ID uživatele';

  @override
  String get privacySyncDescription =>
      'Když je synchronizace povolena, oblíbené, upozornění, ignorované stanice a hodnocení jsou také uloženy na serveru TankSync.';

  @override
  String get privacyViewServerData => 'Zobrazit data na serveru';

  @override
  String get privacyExportButton => 'Exportovat všechna data jako JSON';

  @override
  String get privacyExportSuccess => 'Data exportována do schránky';

  @override
  String get privacyExportCsvButton => 'Exportovat všechna data jako CSV';

  @override
  String get privacyExportCsvSuccess => 'Data CSV exportována do schránky';

  @override
  String get savedToDownloadsFolder => 'Uloženo do složky Stažené';

  @override
  String get privacyDeleteButton => 'Smazat všechna data';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopírovat protokol chyb do schránky ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Uložit záznam chyb ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Vymazat protokol chyb';

  @override
  String get privacyErrorLogCleared => 'Protokol chyb byl vymazán';

  @override
  String get privacyDeleteTitle => 'Smazat všechna data?';

  @override
  String get privacyDeleteBody =>
      'Tím se trvale odstraní:\n\n- Všechny oblíbené a data stanic\n- Všechny vyhledávací profily\n- Všechna cenová upozornění\n- Celá historie cen\n- Všechna data mezipaměti\n- Váš klíč API\n- Všechna nastavení aplikace\n\nAplikace se resetuje do počátečního stavu. Tuto akci nelze vrátit zpět.';

  @override
  String get privacyDeleteConfirm => 'Smazat vše';

  @override
  String get yes => 'Ano';

  @override
  String get no => 'Ne';

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
  String get paymentMethods => 'Platební metody';

  @override
  String get paymentMethodCash => 'Hotovost';

  @override
  String get paymentMethodCard => 'Karta';

  @override
  String get paymentMethodContactless => 'Bezkontaktně';

  @override
  String get paymentMethodFuelCard => 'Palivová karta';

  @override
  String get paymentMethodApp => 'Aplikace';

  @override
  String payWithApp(String app) {
    return 'Zaplatit přes $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Ve srovnání s průměrem za vaše poslední 3 tankování ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Spotřeba $value L/100 km, $delta oproti průměru';
  }

  @override
  String get drivingMode => 'Režim jízdy';

  @override
  String get drivingExit => 'Konec';

  @override
  String get drivingNearestStation => 'Nejbližší';

  @override
  String get drivingTapToUnlock => 'Klepnutím odemknout';

  @override
  String get drivingSafetyTitle => 'Bezpečnostní upozornění';

  @override
  String get drivingSafetyMessage =>
      'Neovládejte aplikaci za jízdy. Zastavte na bezpečném místě, než začnete se obrazovkou pracovat. Řidič je vždy zodpovědný za bezpečné ovládání vozidla.';

  @override
  String get drivingSafetyAccept => 'Rozumím';

  @override
  String get voiceAnnouncementsTitle => 'Hlasová oznámení';

  @override
  String get voiceAnnouncementsDescription =>
      'Oznamovat blízké levné stanice při jízdě';

  @override
  String get voiceAnnouncementsEnabled => 'Povolit hlasová oznámení';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Pouze pod $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, za $distance km, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Poloměr oznámení';

  @override
  String get voiceAnnouncementCooldown => 'Interval opakování';

  @override
  String get nearestStations => 'Nejblizsi stanice';

  @override
  String get nearestStationsHint =>
      'Najdete nejblizsi stanice pomoci vasi aktualni polohy';

  @override
  String get consumptionLogTitle => 'Spotřeba paliva';

  @override
  String get consumptionLogMenuTitle => 'Protokol spotřeby';

  @override
  String get consumptionLogMenuSubtitle =>
      'Sledovat tankování a výpočet L/100km';

  @override
  String get consumptionStatsTitle => 'Statistiky spotřeby';

  @override
  String get addFillUp => 'Přidat tankování';

  @override
  String get noFillUpsTitle => 'Zatím žádná tankování';

  @override
  String get noFillUpsSubtitle =>
      'Zaznamenejte první tankování a začněte sledovat spotřebu.';

  @override
  String get fillUpDate => 'Datum';

  @override
  String get liters => 'Litry';

  @override
  String get odometerKm => 'Tachometr (km)';

  @override
  String get notesOptional => 'Poznámky (volitelné)';

  @override
  String get stationPreFilled => 'Stanice předvyplněna';

  @override
  String get statAvgConsumption => 'Průměr L/100km';

  @override
  String get statAvgCostPerKm => 'Průměrné náklady/km';

  @override
  String get statTotalLiters => 'Celkem litrů';

  @override
  String get statTotalSpent => 'Celkem utraceno';

  @override
  String get statFillUpCount => 'Tankování';

  @override
  String get fieldRequired => 'Povinné';

  @override
  String get fieldInvalidNumber => 'Neplatné číslo';

  @override
  String get carbonDashboardTitle => 'Uhlíkový přehled';

  @override
  String get carbonEmptyTitle => 'Zatím žádná data';

  @override
  String get carbonEmptySubtitle =>
      'Zaznamenejte tankování pro zobrazení uhlíkového přehledu.';

  @override
  String get carbonSummaryTotalCost => 'Celkové náklady';

  @override
  String get carbonSummaryTotalCo2 => 'Celkem CO2';

  @override
  String get monthlyCostsTitle => 'Měsíční náklady';

  @override
  String get monthlyEmissionsTitle => 'Měsíční emise CO2';

  @override
  String get vehiclesTitle => 'Moje vozidla';

  @override
  String get vehiclesMenuTitle => 'Moje vozidla';

  @override
  String get vehiclesMenuSubtitle => 'Baterie, konektory, předvolby nabíjení';

  @override
  String get vehiclesEmptyMessage =>
      'Přidejte své auto pro filtrování podle konektoru a odhad nákladů na nabíjení.';

  @override
  String get vehiclesWizardTitle => 'Moje vozidla (volitelné)';

  @override
  String get vehiclesWizardSubtitle =>
      'Přidejte auto pro předvyplnění protokolu spotřeby a aktivaci filtrů EV konektorů. Vozidla můžete přeskočit a přidat je později.';

  @override
  String get vehiclesWizardNoneYet => 'Zatím žádné vozidlo.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vozidel',
      one: '1 vozidlo',
    );
    return 'Máte $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Přeskočte a dokončete nastavení — vozidla lze přidat kdykoli z Nastavení.';

  @override
  String get fillUpVehicleLabel => 'Vozidlo';

  @override
  String get fillUpVehicleNone => 'Žádné vozidlo';

  @override
  String get fillUpVehicleRequired => 'Vozidlo je povinné';

  @override
  String get reportScanError => 'Nahlásit chybu skenování';

  @override
  String get pickStationTitle => 'Vybrat stanici';

  @override
  String get pickStationHelper =>
      'Začněte tankování ze známé stanice, aby se automaticky vyplnily ceny, značka a typ paliva.';

  @override
  String get pickStationEmpty =>
      'Zatím žádné oblíbené stanice — přidejte je z Hledat nebo Oblíbené, nebo přeskočte a vyplňte ručně.';

  @override
  String get pickStationSkip => 'Přeskočit — přidat bez stanice';

  @override
  String get scanPump => 'Skenovat pumpu';

  @override
  String get scanPayment => 'Skenovat platební QR';

  @override
  String get qrPaymentBeneficiary => 'Příjemce';

  @override
  String get qrPaymentAmount => 'Částka';

  @override
  String get qrPaymentEpcTitle => 'Platba SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Žádná pole nebyla dekódována';

  @override
  String get qrPaymentOpenInBank => 'Otevřít v bankovní aplikaci';

  @override
  String get qrPaymentLaunchFailed => 'Žádná aplikace pro otevření tohoto kódu';

  @override
  String get qrPaymentUnknownTitle => 'Nerozpoznaný kód';

  @override
  String get qrPaymentCopyRaw => 'Kopírovat surový text';

  @override
  String get qrPaymentCopiedRaw => 'Zkopírováno do schránky';

  @override
  String get qrPaymentReport => 'Nahlásit tento sken';

  @override
  String get qrPaymentEpcCopied =>
      'Bankovní údaje zkopírovány — vložte do bankovní aplikace';

  @override
  String get qrScannerGuidance => 'Namiřte kameru na QR kód';

  @override
  String get qrScannerPermissionDenied =>
      'Pro skenování QR kódů je potřeba přístup ke kameře.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Přístup ke kameře byl odepřen. Povolte ho v nastavení.';

  @override
  String get qrScannerRetryPermission => 'Zkusit znovu';

  @override
  String get qrScannerOpenSettings => 'Otevřít nastavení';

  @override
  String get qrScannerTimeout =>
      'QR kód nenalezen. Přibližte se nebo zkuste znovu.';

  @override
  String get qrScannerRetry => 'Zkusit znovu';

  @override
  String get torchOn => 'Zapnout blesk';

  @override
  String get torchOff => 'Vypnout blesk';

  @override
  String get obdNoAdapter => 'V dosahu není žádný adaptér OBD2';

  @override
  String get obdOdometerUnavailable => 'Nepodařilo se přečíst tachometr';

  @override
  String get obdPermissionDenied =>
      'Udělte oprávnění Bluetooth v nastavení systému';

  @override
  String get obdAdapterUnresponsive =>
      'Adaptér neodpověděl — zapněte zapalování a zkuste znovu';

  @override
  String get obdPickerTitle => 'Vybrat adaptér OBD2';

  @override
  String get obdPickerScanning => 'Hledání adaptérů…';

  @override
  String get obdPickerConnecting => 'Připojování…';

  @override
  String get themeSettingTitle => 'Motiv';

  @override
  String get themeModeLight => 'Světlý';

  @override
  String get themeModeDark => 'Tmavý';

  @override
  String get themeModeSystem => 'Sledovat systém';

  @override
  String get tripRecordingTitle => 'Nahrávání cesty';

  @override
  String get tripSummaryTitle => 'Přehled cesty';

  @override
  String get tripMetricDistance => 'Vzdálenost';

  @override
  String get tripMetricSpeed => 'Rychlost';

  @override
  String get tripMetricFuelUsed => 'Spotřebované palivo';

  @override
  String get tripMetricAvgConsumption => 'Průměr';

  @override
  String get tripMetricElapsed => 'Uplynulý čas';

  @override
  String get tripMetricOdometer => 'Tachometr';

  @override
  String get tripStop => 'Zastavit nahrávání';

  @override
  String get tripPause => 'Pozastavit';

  @override
  String get tripResume => 'Pokračovat';

  @override
  String get tripBannerRecording => 'Nahrávání cesty';

  @override
  String get tripBannerPaused => 'Cesta pozastavena — klepnutím pokračujte';

  @override
  String get navConsumption => 'Spotřeba';

  @override
  String get vehicleBaselineSectionTitle => 'Základní kalibrace';

  @override
  String get vehicleBaselineEmpty =>
      'Zatím žádné vzorky — začněte cestu s OBD2 pro učení profilu spotřeby vozidla.';

  @override
  String get vehicleBaselineProgress =>
      'Naučeno ze vzorků v různých jízdních situacích.';

  @override
  String get vehicleBaselineReset => 'Resetovat základní jízdní profil';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Resetovat základní jízdní profil?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Tímto se vymažou všechny naučené vzorky pro toto vozidlo. Vrátíte se k výchozím hodnotám studeného startu, dokud nové cesty znovu nenaplní profil.';

  @override
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'Adaptér OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Žádný adaptér není spárován. Spárujte ho, aby se aplikace mohla příště automaticky znovu připojit.';

  @override
  String get vehicleAdapterUnnamed => 'Neznámý adaptér';

  @override
  String get vehicleAdapterPair => 'Spárovat adaptér';

  @override
  String get vehicleAdapterForget => 'Zapomenout adaptér';

  @override
  String get achievementsTitle => 'Úspěchy';

  @override
  String get achievementFirstTrip => 'První cesta';

  @override
  String get achievementFirstTripDesc =>
      'Zaznamenejte svou první cestu s OBD2.';

  @override
  String get achievementFirstFillUp => 'První tankování';

  @override
  String get achievementFirstFillUpDesc => 'Zaznamenejte své první tankování.';

  @override
  String get achievementTenTrips => '10 cest';

  @override
  String get achievementTenTripsDesc => 'Zaznamenejte 10 cest s OBD2.';

  @override
  String get achievementZeroHarsh => 'Plynulý řidič';

  @override
  String get achievementZeroHarshDesc =>
      'Dokončete cestu 10 km nebo více bez prudkého brzdění nebo zrychlení.';

  @override
  String get achievementEcoWeek => 'Ekologický týden';

  @override
  String get achievementEcoWeekDesc =>
      'Jeďte 7 po sobě jdoucích dní s alespoň jednou plynulou cestou každý den.';

  @override
  String get achievementPriceWin => 'Cenový úspěch';

  @override
  String get achievementPriceWinDesc =>
      'Zaznamenejte tankování, které překoná 30denní průměr stanice o 5 % nebo více.';

  @override
  String get syncBaselinesToggleTitle => 'Sdílet naučené profily vozidel';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Nahrát základní hodnoty spotřeby pro každé vozidlo, aby je mohlo využít druhé zařízení.';

  @override
  String get obd2StatusConnected => 'Adaptér OBD2: připojen';

  @override
  String get obd2StatusAttempting => 'Adaptér OBD2: připojování';

  @override
  String get obd2StatusUnreachable => 'Adaptér OBD2: nedostupný';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptér OBD2: potřebné oprávnění Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Připraveno k nahrávání cesty.';

  @override
  String get obd2StatusAttemptingBody => 'Připojování na pozadí…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adaptér mimo dosah nebo používán jinou aplikací.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Udělte oprávnění Bluetooth v nastavení systému pro automatické opětovné připojení.';

  @override
  String get obd2StatusNoAdapter => 'Žádný adaptér není spárován';

  @override
  String get obd2StatusForget => 'Zapomenout adaptér';

  @override
  String get tripHistoryTitle => 'Historie cest';

  @override
  String get tripHistoryEmptyTitle => 'Zatím žádné cesty';

  @override
  String get tripHistoryEmptySubtitle =>
      'Připojte adaptér OBD2 a zaznamenejte cestu pro vytváření vaší jízdní historie.';

  @override
  String get tripHistoryUnknownDate => 'Neznámé datum';

  @override
  String get situationIdle => 'Volnoběh';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Město';

  @override
  String get situationHighway => 'Dálnice';

  @override
  String get situationDecel => 'Zpomalování';

  @override
  String get situationClimbing => 'Stoupání / zatížení';

  @override
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

  @override
  String get situationHardAccel => 'Prudké zrychlení';

  @override
  String get situationFuelCut => 'Odříznutí paliva — výběh';

  @override
  String get tripSaveAsFillUp => 'Uložit jako tankování';

  @override
  String get tripSaveRecording => 'Uložit cestu';

  @override
  String get tripDiscard => 'Zahodit';

  @override
  String obdOdometerRead(int km) {
    return 'Tachometr přečten: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nenastaveno';

  @override
  String get wizardVehicleTapToEdit => 'Klepnutím upravit';

  @override
  String get wizardVehicleDefaultBadge => 'Výchozí';

  @override
  String get wizardProfileChoiceHint =>
      'Zvolte, jak chcete aplikaci používat. Toto lze změnit v Nastavení.';

  @override
  String get wizardProfileChoiceFooter =>
      'Volbu lze kdykoli změnit v Nastavení → Režim použití.';

  @override
  String get wizardProfileBasicName => 'Základní';

  @override
  String get wizardProfileBasicDescription =>
      'Nejlevnější palivo a nabíjení EV v okolí. Oblíbené a cenová upozornění.';

  @override
  String get wizardProfileMediumName => 'Střední';

  @override
  String get wizardProfileMediumDescription =>
      'Vše ze Základního, plus ruční sledování tankování a nabíjení EV.';

  @override
  String get wizardProfileFullName => 'Plný';

  @override
  String get wizardProfileFullDescription =>
      'Vše ze Středního, plus automatické nahrávání cest přes OBD2, hodnocení jízdy a věrnostní karty.';

  @override
  String get wizardProfileCustomName => 'Vlastní';

  @override
  String get wizardProfileCustomDescription =>
      'Vaše vlastní kombinace funkcí. Upravte každý přepínač níže.';

  @override
  String get useModeSectionHint =>
      'Přizpůsobte aplikaci způsobu, jakým ji skutečně používáte. Výběrem předvolby se aktivuje odpovídající sada funkcí.';

  @override
  String get useModeCustomSettingsDescription =>
      'Vaše nastavení funkcí neodpovídá žádné předvolbě. Vyberte předvolbu výše pro přepsání, nebo pokračujte v přizpůsobování jednotlivých funkcí níže.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Režim použití nastaven na $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Výchozí vozidlo (volitelné)';

  @override
  String get profileDefaultVehicleNone => 'Žádné výchozí';

  @override
  String get profileFuelFromVehicleHint =>
      'Typ paliva je odvozen od výchozího vozidla. Odstraňte vozidlo pro přímý výběr paliva.';

  @override
  String get consumptionNoVehicleTitle => 'Nejprve přidejte vozidlo';

  @override
  String get consumptionNoVehicleBody =>
      'Tankování je přiřazeno k vozidlu. Přidejte auto pro zahájení sledování spotřeby.';

  @override
  String get vehicleAdd => 'Přidat vozidlo';

  @override
  String get vehicleAddTitle => 'Přidat vozidlo';

  @override
  String get vehicleEditTitle => 'Upravit vozidlo';

  @override
  String get vehicleDeleteTitle => 'Smazat vozidlo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Odebrat \"$name\" z vašich profilů?';
  }

  @override
  String get vehicleNameLabel => 'Název';

  @override
  String get vehicleNameHint => 'např. Moje Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Spalovací';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Elektrické';

  @override
  String get vehicleEvSectionTitle => 'Elektrické';

  @override
  String get vehicleCombustionSectionTitle => 'Spalovací';

  @override
  String get vehicleBatteryLabel => 'Kapacita baterie (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maximální výkon nabíjení (kW)';

  @override
  String get vehicleConnectorsLabel => 'Podporované konektory';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max SoC %';

  @override
  String get vehicleTankLabel => 'Objem nádrže (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Preferované palivo';

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
  String get evShowOnMap => 'Zobrazit EV stanice';

  @override
  String get evAvailableOnly => 'Pouze dostupné';

  @override
  String get evMinPower => 'Min výkon';

  @override
  String get evMaxPower => 'Max výkon';

  @override
  String get evOperator => 'Provozovatel';

  @override
  String get evLastUpdate => 'Poslední aktualizace';

  @override
  String get evStatusAvailable => 'Dostupné';

  @override
  String get evStatusOccupied => 'Obsazeno';

  @override
  String get evStatusOutOfOrder => 'Mimo provoz';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Pouze otevřené';

  @override
  String get saveAsDefaults => 'Uložit jako výchozí';

  @override
  String get criteriaSavedToProfile => 'Uloženo jako výchozí';

  @override
  String get profileNotFound => 'Žádný aktivní profil';

  @override
  String get updatingFavorites => 'Aktualizace oblíbených...';

  @override
  String get fetchingLatestPrices => 'Načítání nejnovějších cen';

  @override
  String get noDataAvailable => 'Žádná data';

  @override
  String get configAndPrivacy => 'Konfigurace a soukromí';

  @override
  String get searchToSeeMap => 'Hledáním zobrazíte stanice na mapě';

  @override
  String get evPowerAny => 'Libovolný';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Poloha';

  @override
  String get sectionSetupDataSources => 'Setup & data sources';

  @override
  String get sectionFeaturesUsage => 'Features & usage';

  @override
  String get sectionAccountSync => 'Account & sync';

  @override
  String get sectionAppearanceWidgets => 'Appearance & widgets';

  @override
  String get sectionPrivacyData => 'Privacy & data';

  @override
  String get sectionAdvancedDeveloper => 'Advanced & developer';

  @override
  String get tooltipBack => 'Zpět';

  @override
  String get tooltipClose => 'Zavřít';

  @override
  String get tooltipShare => 'Sdílet';

  @override
  String get tooltipClearSearch => 'Vymazat vstup hledání';

  @override
  String get minimalDriveInstantConsumption => 'Okamžitá spotřeba';

  @override
  String get coachingShiftUp => 'Zařadit vyšší';

  @override
  String get coachingShiftDown => 'Zařadit nižší';

  @override
  String get coachingEasePedal => 'Uberte plyn';

  @override
  String get tooltipUseGps => 'Použít polohu GPS';

  @override
  String get tooltipShowPassword => 'Zobrazit heslo';

  @override
  String get tooltipHidePassword => 'Skrýt heslo';

  @override
  String get evConnectorsLabel => 'Dostupné konektory';

  @override
  String get evConnectorsNone => 'Žádné informace o konektoru';

  @override
  String get switchToEmail => 'Přepnout na e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Zachovat data, přidat přihlašování z jiných zařízení';

  @override
  String get switchToAnonymousAction => 'Přepnout na anonymní';

  @override
  String get switchToAnonymousSubtitle =>
      'Zachovat lokální data, použít novou anonymní relaci';

  @override
  String get linkDevice => 'Propojit zařízení';

  @override
  String get shareDatabase => 'Sdílet databázi';

  @override
  String get disconnectAction => 'Odpojit';

  @override
  String get disconnectSubtitle =>
      'Zastavit synchronizaci (lokální data zachována)';

  @override
  String get deleteAccountAction => 'Smazat účet';

  @override
  String get deleteAccountSubtitle =>
      'Trvale odstranit všechna data ze serveru';

  @override
  String get localOnly => 'Pouze lokálně';

  @override
  String get localOnlySubtitle =>
      'Volitelně: synchronizovat oblíbené, upozornění a hodnocení napříč zařízeními';

  @override
  String get setupCloudSync => 'Nastavit cloudovou synchronizaci';

  @override
  String get disconnectTitle => 'Odpojit TankSync?';

  @override
  String get disconnectBody =>
      'Cloudová synchronizace bude zakázána. Vaše lokální data (oblíbené, upozornění, historie) jsou zachována na tomto zařízení. Serverová data nejsou smazána.';

  @override
  String get deleteAccountTitle => 'Smazat účet?';

  @override
  String get deleteAccountBody =>
      'Tímto se trvale smažou všechna vaše data ze serveru (oblíbené, upozornění, hodnocení, trasy). Lokální data na tomto zařízení jsou zachována.\n\nTuto akci nelze vrátit zpět.';

  @override
  String get switchToAnonymousTitle => 'Přepnout na anonymní?';

  @override
  String get switchToAnonymousBody =>
      'Budete odhlášeni z e-mailového účtu a budete pokračovat s novou anonymní relací.\n\nVaše lokální data (oblíbené, upozornění) jsou zachována na tomto zařízení a budou synchronizována na nový anonymní účet.';

  @override
  String get switchAction => 'Přepnout';

  @override
  String get helpBannerCriteria =>
      'Výchozí hodnoty vašeho profilu jsou předvyplněny. Upravte kritéria níže pro upřesnění hledání.';

  @override
  String get helpBannerAlerts =>
      'Nastavte cenový práh pro stanici. Budete upozorněni, když ceny klesnou pod něj. Kontrola probíhá každých 30 minut.';

  @override
  String get helpBannerConsumption =>
      'Zaznamenávejte každé tankování pro sledování skutečné spotřeby a uhlíkové stopy. Přejeďte doleva pro smazání záznamu.';

  @override
  String get helpBannerVehicles =>
      'Přidejte vozidla, aby se tankování a preference paliva vyplňovaly správně. První vozidlo se stane výchozím.';

  @override
  String get syncNow => 'Synchronizovat nyní';

  @override
  String get onboardingPreferencesTitle => 'Vaše preference';

  @override
  String get onboardingZipHelper => 'Použito, když GPS není dostupné';

  @override
  String get onboardingRadiusHelper => 'Větší poloměr = více výsledků';

  @override
  String get onboardingPrivacy =>
      'Tato nastavení jsou uložena pouze na vašem zařízení a nikdy nejsou sdílena.';

  @override
  String get onboardingLandingTitle => 'Domovská obrazovka';

  @override
  String get onboardingLandingHint =>
      'Vyberte, která obrazovka se otevře při spuštění aplikace.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Nebuďte v aplikaci — ale nevypínejte ji.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Po každém restartu jednou otevřete Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple spustí Sparkilo pouze poté, co jste ho od posledního restartu telefonu alespoň jednou otevřeli. Poté se vaše cesty nahrávají automaticky.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Nevypínejte Sparkilo v přepínači aplikací.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Vynucené ukončení\" říká iOS, aby aplikaci přestal spouštět. Nahrávání cest se zastaví, dokud Sparkilo znovu neotevřete.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Když vás iOS požádá o polohu \"Vždy\", prosím souhlaste.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Záložní funkce, která zaznamená vaši cestu, když je adaptér OBD2 pomalý, potřebuje polohu na pozadí. Nikdy ji nesdílíme.';

  @override
  String get scanReceipt => 'Skenovat účtenku';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Palivo';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Dálnice';

  @override
  String get ratingModeLocal => 'Lokální';

  @override
  String get ratingModePrivate => 'Soukromé';

  @override
  String get ratingModeShared => 'Sdílené';

  @override
  String get ratingDescLocal => 'Hodnocení uložena pouze na tomto zařízení';

  @override
  String get ratingDescPrivate =>
      'Synchronizováno s vaší databází (neviditelné pro ostatní)';

  @override
  String get ratingDescShared =>
      'Viditelné pro všechny uživatele vaší databáze';

  @override
  String get errorNoEvApiKey =>
      'Klíč API OpenChargeMap není nakonfigurován. Přidejte ho v Nastavení pro vyhledávání stanic EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Poskytovatel dat ($host) vydává vypršený nebo neplatný certifikát TLS. Aplikace nemůže načíst data z tohoto zdroje, dokud to poskytovatel neopraví. Kontaktujte prosím $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nedostupné. Používám $current.';
  }

  @override
  String get errorTitleApiKey => 'Požadován klíč API';

  @override
  String get errorTitleLocation => 'Poloha nedostupná';

  @override
  String get errorHintNoStations =>
      'Zkuste zvětšit poloměr hledání nebo hledat na jiném místě.';

  @override
  String get errorHintApiKey => 'Nakonfigurujte klíč API v Nastavení.';

  @override
  String get errorHintConnection =>
      'Zkontrolujte připojení k internetu a zkuste znovu.';

  @override
  String get errorHintRouting =>
      'Výpočet trasy selhal. Zkontrolujte připojení k internetu a zkuste znovu.';

  @override
  String get errorHintFallback =>
      'Zkuste znovu nebo vyhledejte podle PSČ / názvu města.';

  @override
  String get alertsLoadErrorTitle => 'Nepodařilo se načíst upozornění';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Kontrola upozornění na pozadí selhala';

  @override
  String get detailsLabel => 'Podrobnosti';

  @override
  String get remove => 'Odebrat';

  @override
  String get showKey => 'Zobrazit klíč';

  @override
  String get hideKey => 'Skrýt klíč';

  @override
  String get syncOptionalTitle => 'TankSync je volitelný';

  @override
  String get syncOptionalDescription =>
      'Aplikace funguje plně bez cloudové synchronizace. TankSync umožňuje synchronizovat oblíbené, upozornění a hodnocení napříč zařízeními pomocí Supabase (dostupná bezplatná úroveň).';

  @override
  String get syncHowToConnectQuestion => 'Jak se chcete připojit?';

  @override
  String get syncCreateOwnTitle => 'Vytvořit vlastní databázi';

  @override
  String get syncCreateOwnSubtitle =>
      'Bezplatný projekt Supabase — provedeme vás krok za krokem';

  @override
  String get syncJoinExistingTitle => 'Připojit se k existující databázi';

  @override
  String get syncJoinExistingSubtitle =>
      'Naskenovat QR kód od vlastníka databáze nebo vložit přihlašovací údaje';

  @override
  String get syncChooseAccountType => 'Zvolte typ účtu';

  @override
  String get syncAccountTypeAnonymous => 'Anonymní';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Okamžité, bez e-mailu. Data vázána na toto zařízení.';

  @override
  String get syncAccountTypeEmail => 'E-mailový účet';

  @override
  String get syncAccountTypeEmailDesc =>
      'Přihlaste se z libovolného zařízení. Obnovte data v případě ztráty telefonu.';

  @override
  String get syncHaveAccountSignIn => 'Máte již účet? Přihlaste se';

  @override
  String get syncCreateNewAccount => 'Vytvořit nový účet';

  @override
  String get syncTestConnection => 'Otestovat připojení';

  @override
  String get syncTestingConnection => 'Testování...';

  @override
  String get syncConnectButton => 'Připojit';

  @override
  String get syncConnectingButton => 'Připojování...';

  @override
  String get syncDatabaseReady => 'Databáze připravena!';

  @override
  String get syncDatabaseNeedsSetup => 'Databáze vyžaduje nastavení';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Chybí';

  @override
  String get syncSqlEditorInstructions =>
      'Zkopírujte SQL níže a spusťte ho v Supabase SQL Editoru (Dashboard → SQL Editor → Nový dotaz → Vložit → Spustit)';

  @override
  String get syncCopySqlButton => 'Zkopírovat SQL do schránky';

  @override
  String get syncRecheckSchemaButton => 'Znovu zkontrolovat schéma';

  @override
  String get syncDoneButton => 'Hotovo';

  @override
  String syncSignedInAs(String email) {
    return 'Přihlášen jako $email';
  }

  @override
  String get syncEmailDescription =>
      'Vaše data se synchronizují napříč všemi zařízeními s tímto e-mailem.';

  @override
  String get syncSwitchToAnonymousTitle => 'Přepnout na anonymní';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Pokračovat bez e-mailu, nová anonymní relace';

  @override
  String get syncGuestDescription => 'Anonymní, bez e-mailu.';

  @override
  String get syncOrDivider => 'nebo';

  @override
  String get syncHowToSyncQuestion => 'Jak chcete synchronizovat?';

  @override
  String get syncOfflineDescription =>
      'Aplikace funguje plně offline. Cloudová synchronizace je volitelná.';

  @override
  String get syncModeCommunityTitle => 'Komunita Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Sdílejte oblíbené a hodnocení se všemi uživateli';

  @override
  String get syncModePrivateTitle => 'Soukromá databáze';

  @override
  String get syncModePrivateSubtitle =>
      'Vlastní Supabase — plná kontrola nad daty';

  @override
  String get syncModeGroupTitle => 'Připojit se ke skupině';

  @override
  String get syncModeGroupSubtitle =>
      'Sdílená databáze pro rodinu nebo přátele';

  @override
  String get syncPrivacyShared => 'Sdílené';

  @override
  String get syncPrivacyPrivate => 'Soukromé';

  @override
  String get syncPrivacyGroup => 'Skupina';

  @override
  String get syncStayOfflineButton => 'Zůstat offline';

  @override
  String get syncSuccessTitle => 'Úspěšně připojeno!';

  @override
  String get syncSuccessDescription =>
      'Vaše data se nyní budou automaticky synchronizovat.';

  @override
  String get syncWizardTitleConnect => 'Připojit TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Vaše databáze';

  @override
  String get syncSetupTitleJoinGroup => 'Připojit se ke skupině';

  @override
  String get syncSetupTitleAccount => 'Váš účet';

  @override
  String get syncWizardBack => 'Zpět';

  @override
  String get syncWizardNext => 'Další';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Vytvořit projekt Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Klepněte na \"Otevřít Supabase\" níže\n2. Vytvořte bezplatný účet (pokud ho nemáte)\n3. Klikněte na \"Nový projekt\"\n4. Zvolte název a region\n5. Počkejte ~2 minuty na spuštění';

  @override
  String get syncWizardOpenSupabase => 'Otevřít Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Povolit anonymní přihlašování';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. V dashboardu Supabase:\n   Authentication → Providers\n2. Najděte \"Anonymous Sign-ins\"\n3. Přepněte na ZAP\n4. Klikněte na \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Otevřít nastavení Auth';

  @override
  String get syncWizardCopyCredentialsTitle => 'Zkopírovat přihlašovací údaje';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Přejděte na Settings → API ve vašem dashboardu\n2. Zkopírujte \"Project URL\"\n3. Zkopírujte klíč \"anon public\"\n4. Vložte je níže';

  @override
  String get syncWizardOpenApiSettings => 'Otevřít nastavení API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Připojit se k existující databázi';

  @override
  String get syncWizardScanQrCode => 'Skenovat QR kód';

  @override
  String get syncWizardAskOwnerQr =>
      'Požádejte vlastníka databáze, aby vám ukázal QR kód\n(Nastavení → TankSync → Sdílet)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Požádejte vlastníka databáze, aby ukázal QR kód';

  @override
  String get syncWizardEnterManuallyTitle => 'Zadat ručně';

  @override
  String get syncWizardOrEnterManually => 'nebo zadat ručně';

  @override
  String get syncWizardUrlHelperText =>
      'Mezery a zalomení řádků jsou odstraněny automaticky';

  @override
  String get syncCredentialsPrivateHint =>
      'Zadejte přihlašovací údaje projektu Supabase. Najdete je v dashboardu pod Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL databáze';

  @override
  String get syncCredentialsAccessKeyLabel => 'Přístupový klíč';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Heslo';

  @override
  String get authConfirmPasswordLabel => 'Potvrdit heslo';

  @override
  String get authPleaseEnterEmail => 'Zadejte prosím e-mail';

  @override
  String get authInvalidEmail => 'Neplatná e-mailová adresa';

  @override
  String get authPasswordsDoNotMatch => 'Hesla se neshodují';

  @override
  String get authConnectAnonymously => 'Připojit anonymně';

  @override
  String get authCreateAccountAndConnect => 'Vytvořit účet a připojit';

  @override
  String get authSignInAndConnect => 'Přihlásit se a připojit';

  @override
  String get authAnonymousSegment => 'Anonymní';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Okamžitý přístup, bez e-mailu. Data vázána na toto zařízení.';

  @override
  String get authEmailDescription =>
      'Přihlaste se z libovolného zařízení. Obnovte data v případě ztráty telefonu.';

  @override
  String get authSyncAcrossDevices =>
      'Automaticky synchronizovat data napříč všemi zařízeními.';

  @override
  String get authNewHereCreateAccount => 'Jste tu nový? Vytvořit účet';

  @override
  String get linkDeviceScreenTitle => 'Propojit zařízení';

  @override
  String get linkDeviceThisDeviceLabel => 'Toto zařízení';

  @override
  String get linkDeviceShareCodeHint =>
      'Sdílejte tento kód s druhým zařízením:';

  @override
  String get linkDeviceNotConnected => 'Nepřipojeno';

  @override
  String get linkDeviceCopyCodeTooltip => 'Zkopírovat kód';

  @override
  String get linkDeviceImportSectionTitle => 'Import z jiného zařízení';

  @override
  String get linkDeviceImportDescription =>
      'Zadejte kód zařízení z druhého zařízení pro import oblíbených, upozornění, vozidel a protokolu spotřeby. Každé zařízení si ponechá vlastní profil a výchozí hodnoty.';

  @override
  String get linkDeviceCodeFieldLabel => 'Kód zařízení';

  @override
  String get linkDeviceCodeFieldHint => 'Vložte UUID z jiného zařízení';

  @override
  String get linkDeviceImportButton => 'Importovat data';

  @override
  String get linkDeviceHowItWorksTitle => 'Jak to funguje';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Na zařízení A: zkopírujte kód zařízení výše\n2. Na zařízení B: vložte ho do pole \"Kód zařízení\"\n3. Klepněte na \"Importovat data\" pro sloučení oblíbených, upozornění, vozidel a protokolů spotřeby\n4. Obě zařízení budou mít všechna kombinovaná data\n\nKaždé zařízení si ponechá vlastní anonymní identitu a vlastní profil (preferované palivo, výchozí vozidlo, domovská obrazovka). Data jsou sloučena, ne přesunuta.';

  @override
  String get vehicleSetActive => 'Nastavit jako aktivní';

  @override
  String get swipeHide => 'Skrýt';

  @override
  String get evChargingSection => 'Nabíjení EV';

  @override
  String get fuelStationsSection => 'Čerpací stanice';

  @override
  String get yourRating => 'Vaše hodnocení';

  @override
  String get noStorageUsed => 'Žádný úložný prostor není využit';

  @override
  String get aboutReportBug => 'Nahlásit chybu / Navrhnout funkci';

  @override
  String get aboutSupportProject => 'Podpořit tento projekt';

  @override
  String get aboutSupportDescription =>
      'Tato aplikace je zdarma, open source a bez reklam. Pokud vám přijde užitečná, zvažte podporu vývojáře.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Ceny paliv v Lucembursku jsou státem regulované a jednotné po celé zemi.';

  @override
  String get luxembourgFuelUnleaded95 => 'Natural 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Natural 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Regulované ceny paliv v Lucembursku jsou nedostupné.';

  @override
  String get reportIssueTitle => 'Nahlásit problém';

  @override
  String get enterCorrection => 'Zadejte prosím opravu';

  @override
  String get reportNoBackendAvailable =>
      'Hlášení nebylo možné odeslat: pro tuto zemi není nakonfigurována žádná služba hlášení. Povolte TankSync v Nastavení pro odesílání komunitních hlášení.';

  @override
  String get correctName => 'Opravit název stanice';

  @override
  String get correctAddress => 'Opravit adresu';

  @override
  String get wrongE85Price => 'Špatná cena E85';

  @override
  String get wrongE98Price => 'Špatná cena Super 98';

  @override
  String get wrongLpgPrice => 'Špatná cena LPG';

  @override
  String get wrongStationName => 'Špatný název stanice';

  @override
  String get wrongStationAddress => 'Špatná adresa';

  @override
  String get independentStation => 'Nezávislá stanice';

  @override
  String get serviceRemindersSection => 'Připomínky servisních prohlídek';

  @override
  String get serviceRemindersEmpty =>
      'Zatím žádné připomínky — vyberte předvolbu výše.';

  @override
  String get addServiceReminder => 'Přidat připomínku';

  @override
  String get serviceReminderPresetOil => 'Olej (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Výměna oleje';

  @override
  String get serviceReminderPresetTires => 'Pneumatiky (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Pneumatiky';

  @override
  String get serviceReminderPresetInspection => 'Kontrola (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Kontrola';

  @override
  String get serviceReminderLabel => 'Popis';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Poslední servis';

  @override
  String get serviceReminderMarkDone => 'Označit jako hotové';

  @override
  String get serviceReminderDueTitle => 'Servis je splatný';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label je splatný — $kmOver km po intervalu.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Zaregistrujte se na OPINET pro získání bezplatného klíče API';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Zaregistrujte se na CNE pro získání bezplatného klíče API';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Je toto vaše auto?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-válec, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Částečné informace (offline). Můžete upravit níže.';

  @override
  String get vinDecodeError => 'VIN se nepodařilo dekódovat';

  @override
  String get vinInvalidFormat => 'Neplatný formát VIN';

  @override
  String get obd2PauseBannerTitle =>
      'Připojení OBD2 ztraceno — nahrávání pozastaveno';

  @override
  String get obd2PauseBannerResume => 'Obnovit nahrávání';

  @override
  String get obd2PauseBannerEnd => 'Ukončit nahrávání';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Kalibrace spotřeby aktualizována pro $vehicleName — přesnost zlepšena o $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Resetovat volumetrickou účinnost?';

  @override
  String get veResetConfirmBody =>
      'Tímto se zruší naučená volumetrická účinnost (η_v) a obnoví se výchozí hodnota (0,85). Odhady průtoku paliva na úrovni cesty se vrátí na konstantu výrobce, dokud kalibrátor nenasbírá nové vzorky z nadcházejících cest.';

  @override
  String get alertsRadiusSectionTitle => 'Polohová upozornění';

  @override
  String get alertsRadiusAdd => 'Přidat polohové upozornění';

  @override
  String get alertsRadiusEmptyTitle => 'Zatím žádná polohová upozornění';

  @override
  String get alertsRadiusEmptyCta => 'Vytvořit polohové upozornění';

  @override
  String get alertsRadiusCreateTitle => 'Vytvořit polohové upozornění';

  @override
  String get alertsRadiusLabelHint => 'Popis (např. Domácí nafta)';

  @override
  String get alertsRadiusFuelType => 'Typ paliva';

  @override
  String get alertsRadiusThreshold => 'Práh (€/L)';

  @override
  String get alertsRadiusKm => 'Poloměr (km)';

  @override
  String get alertsRadiusCenterGps => 'Použít mou polohu';

  @override
  String get alertsRadiusCenterPostalCode => 'PSČ';

  @override
  String get alertsRadiusSave => 'Uložit';

  @override
  String get alertsRadiusCancel => 'Zrušit';

  @override
  String get alertsRadiusDeleteConfirm => 'Smazat polohové upozornění?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 připojeno: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Spárovat adaptér OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel pokleslo na blízkých stanicích';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stanic kleslo až o $maxDropCents¢ za poslední hodinu';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankování uloženo';

  @override
  String get radiusAlertsEntryTitle => 'Polohová upozornění a statistiky';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Dostávejte oznámení, když ceny klesnou ve vašem okolí';

  @override
  String get notFoundTitle => 'Stránka nenalezena';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nenalezeno.';
  }

  @override
  String get notFoundHomeButton => 'Domů';

  @override
  String get consumptionTabHiddenNotice =>
      'Záložka Spotřeba je skryta nastavením profilu.';

  @override
  String get swipeBetweenTabsHint =>
      'Tip: přejeďte doleva nebo doprava pro přepínání záložek.';

  @override
  String get discardChangesTitle => 'Zahodit změny?';

  @override
  String get discardChangesBody =>
      'Máte neuložené změny. Odchodem je ztratíte.';

  @override
  String get discardChangesConfirm => 'Zahodit';

  @override
  String get discardChangesKeepEditing => 'Pokračovat v úpravách';

  @override
  String get tankSyncSectionSubtitle =>
      'Cloudová synchronizace napříč zařízeními';

  @override
  String get mapUnavailable => 'Mapa není k dispozici';

  @override
  String get routeNameHintExample => 'např. Paříž → Lyon';

  @override
  String get priceStatsCurrent => 'Aktuální';

  @override
  String get tankerkoenigApiKeyLabel => 'Klíč API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Klíč API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Klepnutím aktualizujete polohu GPS';

  @override
  String get nameLabel => 'Název';

  @override
  String get obd2ErrorPermissionDenied =>
      'K připojení k adaptéru OBD2 je nutné oprávnění Bluetooth.';

  @override
  String get obd2ErrorBluetoothOff => 'Zapněte Bluetooth a zkuste to znovu.';

  @override
  String get obd2ErrorScanTimeout =>
      'Poblíž nebyl nalezen žádný adaptér OBD2. Zkontrolujte, zda je zapojený a zapnutý.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Adaptér OBD2 neodpověděl. Zapněte zapalování a zkuste to znovu.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adaptér OBD2 odeslal nerozpoznanou odpověď. Možná není kompatibilní — zkuste jiný adaptér.';

  @override
  String get obd2ErrorDisconnected =>
      'Adaptér OBD2 se odpojil. Připojte se znovu a zkuste to znovu.';

  @override
  String get onboardingExploreDemoData => 'Prozkoumat s ukázkovými daty';

  @override
  String get achievementSmoothDriver => 'Série plynulé jízdy';

  @override
  String get achievementSmoothDriverDesc =>
      'Jeďte 5 cest za sebou se skóre plynulé jízdy 80 nebo vyšším.';

  @override
  String get achievementColdStartAware => 'Vědomý studeného startu';

  @override
  String get achievementColdStartAwareDesc =>
      'Udržujte náklady na palivo při studeném startu za celý měsíc pod 2 % z celkového paliva — kombinujte krátké cesty.';

  @override
  String get achievementHighwayMaster => 'Mistr dálnice';

  @override
  String get achievementHighwayMasterDesc =>
      'Dokončete cestu 30 km+ při konstantní rychlosti se skóre plynulé jízdy 90 nebo vyšším.';

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
    return '$price $currency (cíl: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel zlevnil na blízkých stanicích';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count stanic zlevnilo až o $cents¢ za poslední hodinu';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count stanic ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count dalších';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Cenová upozornění na pozadí aktuálně fungují pouze pro čerpací stanice v Německu. Toto upozornění bude uloženo, ale nemusí vás upozornit, dokud nebudou k dispozici upozornění napříč zeměmi.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Upozornění podle okruhu aktuálně kontrolují pouze čerpací stanice v Německu.';

  @override
  String get approachOverlaySection => 'Překryv při příjezdu k čerpací stanici';

  @override
  String get approachRadiusLabel => 'Poloměr';

  @override
  String approachRadiusCaption(String km) {
    return 'Překryv se zvětší a zobrazí cenu, když jste do $km km od čerpací stanice';
  }

  @override
  String get approachPriceModeLabel => 'Zobrazit cenu';

  @override
  String get approachPriceModeNearest => 'Nejbližší stanice';

  @override
  String get approachPriceModeCheapestInRadius => 'Nejlevnější v okruhu';

  @override
  String get approachMinPollLabel => 'Min. obnovení';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Spodní hranice obnovování nejbližší stanice (rychlejší při vyšší rychlosti, nikdy častěji než $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Otestovat překryv přiblížení';

  @override
  String get approachTestStopButton => 'Zastavit test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktivní — překryv ukazuje cenu pro $station';
  }

  @override
  String get approachTestUnavailable =>
      'Přidejte oblíbenou stanici, abyste mohli překryv přiblížení otestovat';

  @override
  String approachStationDistance(String meters) {
    return '$meters m daleko';
  }

  @override
  String get authErrorNoNetwork => 'Žádné síťové připojení. Zkuste to znovu.';

  @override
  String get authErrorInvalidCredentials =>
      'Neplatný e-mail nebo heslo. Zkontrolujte přihlašovací údaje.';

  @override
  String get authErrorUserAlreadyExists =>
      'Tento e-mail je již zaregistrován. Zkuste se přihlásit.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Zkontrolujte e-mail a nejprve potvrďte účet.';

  @override
  String get authErrorGeneric => 'Přihlášení selhalo. Zkuste to znovu.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Poloha na pozadí — pouze pro automatické nahrávání';

  @override
  String get autoRecordConsentExplanationTitle => 'O tomto oprávnění';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatické nahrávání potřebuje polohu na pozadí, aby zjistilo, kdy začínáte řídit se zavřenou aplikací. Toto oprávnění používá pouze automatické nahrávání — hledání stanic a centrování mapy používají samostatné oprávnění k poloze v popředí.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Rozumím';

  @override
  String get autoRecordConsentExplanationTooltip => 'Co to znamená?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Klepnutím spravovat v nastavení systému';

  @override
  String get autoRecordSectionTitle => 'Automatické nahrávání';

  @override
  String get autoRecordToggleLabel => 'Automaticky nahrávat cesty';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatické nahrávání se aktivuje při příštím nasednutí do auta.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Spárujte adaptér OBD2 pro povolení automatického nahrávání.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Povolte polohu na pozadí, aby automatické nahrávání fungovalo i se vypnutou obrazovkou.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Spárovat adaptér';

  @override
  String get autoRecordSpeedThresholdLabel => 'Počáteční rychlost (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Prodleva před uložením po odpojení (sekundy)';

  @override
  String get autoRecordPairedAdapterLabel => 'Spárovaný adaptér';

  @override
  String get autoRecordPairedAdapterNone =>
      'Žádný adaptér není spárován. Nejprve ho spárujte přes OBD2 úvodní nastavení.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Poloha na pozadí povolena';

  @override
  String get autoRecordBackgroundLocationRequest => 'Požádat o oprávnění';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Proč \"Vždy povolit\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatické nahrávání streamuje GPS souřadnice ze služby OBD-II na popředí i se vypnutou obrazovkou, aby trasa cesty zůstala přesná. Android vyžaduje možnost \"Vždy povolit\", aby to fungovalo i po zamknutí zařízení.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Otevřít nastavení';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Vyžadováno oprávnění k poloze';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nepodařilo se požádat o polohu na pozadí';

  @override
  String get autoRecordBadgeClearTooltip => 'Vymazat počítadlo';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Spárujte adaptér v sekci níže pro povolení automatického nahrávání';

  @override
  String get exportBackupTooltip => 'Exportovat zálohu';

  @override
  String get exportBackupReady => 'Záloha připravena — vyberte cíl';

  @override
  String get exportBackupFailed => 'Export zálohy selhal — zkuste to znovu';

  @override
  String get brokenMapChipVerifying => 'Ověřování snímače MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Odečty MAP jsou podezřelé';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Snímač MAP čte nesprávně — odečty paliva mohou být o 50–80 % nižší. Zkuste jiný adaptér.';

  @override
  String get brokenMapBannerHardDisable =>
      'Snímač MAP není spolehlivý. Zobrazuji průměry tankování místo živého průtoku paliva.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Snímač MAP: ověřen ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Snímač MAP: ověřování ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Snímač MAP: podezřelý ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Snímač MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Snímač MAP: $posterior% ± $margin% (ověřen)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostika snímače MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Spolehlivost vadného MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return 'Zaznamenáno $count pozorování';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Ověřeně funkční';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Snímač MAP tohoto vozidla dosud nebyl pozorován.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokované adaptéry';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Žádné adaptéry nejsou blokovány.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — označen jako $percent% vadný';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Vymazat';

  @override
  String get brokenMapRevPromptTitle => 'Přidejte plyn';

  @override
  String get brokenMapRevPromptBody =>
      'Krátce stlačte plynový pedál, aby aplikace mohla zkontrolovat odezvu snímače MAP.';

  @override
  String get brokenMapRevPromptConfirm => 'Hotovo — přidal jsem plyn';

  @override
  String get calibrationAdvancedTitle => 'Pokročilá kalibrace';

  @override
  String get calibrationDisplacementLabel => 'Zdvihový objem motoru (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrická účinnost (η_v)';

  @override
  String get calibrationAfrLabel => 'Poměr vzduch/palivo (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Hustota paliva (g/L)';

  @override
  String get calibrationSourceDetected => '(zjištěno z VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(výchozí)';

  @override
  String get calibrationSourceManual => '(ruční)';

  @override
  String get calibrationResetToDetected => 'Resetovat na zjištěnou hodnotu';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrováno, $samples vzorků)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (učení, $samples vzorků)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (výchozí — zatím žádné plné tankování)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples vzorků';
  }

  @override
  String get calibrationResetLearner => 'Resetovat učení';

  @override
  String get calibrationBasisAtkinson => 'Atkinsonův cyklus';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbodmychadlo + DI';

  @override
  String get calibrationBasisTurbo => 'Turbodmychadlo';

  @override
  String get calibrationBasisNaDi => 'Přirozené sání + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — výchozí $basis)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vaše $makeModel je označena jako diesel, ale odpovídá katalogovému záznamu pro benzin. Klepnutím aktualizujte.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aktualizovat';

  @override
  String get consumptionTabFuel => 'Palivo';

  @override
  String get consumptionTabCharging => 'Nabíjení';

  @override
  String get noChargingLogsTitle => 'Zatím žádné záznamy nabíjení';

  @override
  String get noChargingLogsSubtitle =>
      'Zaznamenejte první nabíjecí relaci pro sledování EUR/100 km a kWh/100 km.';

  @override
  String get addChargingLog => 'Zaznamenat nabíjení';

  @override
  String get addChargingLogTitle => 'Zaznamenat nabíjecí relaci';

  @override
  String get chargingKwh => 'Energie (kWh)';

  @override
  String get chargingCost => 'Celkové náklady';

  @override
  String get chargingTimeMin => 'Doba nabíjení (min)';

  @override
  String get chargingStationName => 'Stanice (volitelné)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Pro porovnání je nutný předchozí záznam';

  @override
  String get chargingLogButtonLabel => 'Zaznamenat nabíjení';

  @override
  String get chargingCostTrendTitle => 'Trend nákladů na nabíjení';

  @override
  String get chargingEfficiencyTitle => 'Účinnost (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Zatím nedostatek dat';

  @override
  String get chargingChartsMonthAxis => 'Měsíc';

  @override
  String get consoFeatureGroupTitle => 'Spotřeba';

  @override
  String get consoFeatureGroupDescription =>
      'Sledujte spotřebu — ruční tankování nebo automatické nahrávání cest přes OBD2.';

  @override
  String get consoModeOff => 'Vypnuto';

  @override
  String get consoModeFuel => 'Palivo';

  @override
  String get consoModeFuelAndTrips => 'Palivo + Cesty';

  @override
  String get consoModeOffDescription =>
      'Žádná záložka Spotřeba ani sekce nastavení Spotřeba.';

  @override
  String get consoModeFuelDescription =>
      'Pouze ruční tankování. Vhodné bez adaptéru OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Přidává automatické nahrávání cest přes OBD2. Vyžaduje spárovaný adaptér.';

  @override
  String get consoSubsectionVehicles => 'Moje vozidla';

  @override
  String get consoSubsectionTrajets => 'Cesty (OBD2)';

  @override
  String get consoSubsectionToggles => 'Jízda';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Přesnost: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Vysoká';

  @override
  String get consumptionAccuracyMedium => 'Střední';

  @override
  String get consumptionAccuracyLow => 'Nízká';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Plná kalibrace: tankování plus jízdy zaznamenané přes OBD2. Hodnota L/100 km odpovídá realitě s odchylkou několika procent.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankování ukotvila model spotřeby, ale zatím nebyla zpracována žádná jízda z OBD2. Zaznamenejte jednu s připojeným OBD2 pro dosažení vysoké přesnosti.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Pouze GPS — model spotřeby zatím neukotvilo žádné tankování. Přidejte několik plných tankování pro zlepšení přesnosti.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count částečných tankování čeká na plné — nezahrnuto v průměru',
      one: '1 částečné tankování čeká na plné — nezahrnuto v průměru',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% paliva z automatických oprav — zkontrolujte záznamy';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel => 'Automatická oprava — klepnutím upravit';

  @override
  String get fillUpCorrectionEditTitle => 'Upravit automatickou opravu';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Tento záznam byl automaticky vygenerován pro uzavření mezery mezi zaznamenanými cestami a natankovaným palivem. Upravte hodnoty, pokud znáte skutečné údaje.';

  @override
  String get fillUpCorrectionDelete => 'Smazat opravu';

  @override
  String get fillUpCorrectionStation => 'Název stanice (volitelné)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Řecko)';

  @override
  String get greeceCommunityApiNotice =>
      'Využívá komunitně spravované API fuelpricesgr';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumunsko)';

  @override
  String get romaniaScrapingNotice =>
      'Využívá pretcarburant.ro (Rada pro hospodářskou soutěž + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stanice v $country za $km km — o €$price/L levnější';
  }

  @override
  String get crossBorderTapToSwitch => 'Klepnutím přepnout zemi';

  @override
  String get crossBorderDismissTooltip => 'Zavřít';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Nástroje pro vývojáře';

  @override
  String get developerToolsSubtitle =>
      'Diagnostika a nástroje pro ladění — viditelné pouze ve vývojářském/ladicím režimu.';

  @override
  String get developerToolsMenuSubtitle =>
      'Protokol chyb, testovací upozornění, diagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Protokol chyb';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Uložit protokol chyb ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Vymazat protokol chyb';

  @override
  String get developerToolsViewErrorLog => 'Zobrazit protokol chyb';

  @override
  String get developerToolsErrorLogEmpty =>
      'Nebyly zaznamenány žádné stopy chyb.';

  @override
  String get developerToolsAlertsGroupTitle => 'Upozornění a oznámení';

  @override
  String get developerToolsFireTestNotification => 'Odeslat testovací oznámení';

  @override
  String get developerToolsTestNotificationTitle => 'Testovací oznámení';

  @override
  String get developerToolsTestNotificationBody =>
      'Pokud toto čtete, oznámení fungují.';

  @override
  String get developerToolsTestNotificationSent =>
      'Testovací oznámení odesláno.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Oznámení jsou zablokována — povolte je v nastavení systému a zkuste to znovu.';

  @override
  String get developerToolsRunTestAlert =>
      'Spustit testovací proces upozornění';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testovací upozornění spuštěno — proces doručil $count oznámení.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testovací cenové upozornění';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Syntetická shoda: poblíž byla nalezena stanice pod vaším cílem.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostika';

  @override
  String get developerToolsFeatureFlagDump => 'Inspektor příznaků funkcí';

  @override
  String get developerToolsFlagOn => 'Zapnuto';

  @override
  String get developerToolsFlagOff => 'Vypnuto';

  @override
  String get developerToolsClearCaches => 'Vymazat mezipaměti';

  @override
  String get developerToolsCachesCleared => 'Mezipaměti vymazány.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopírovat diagnostiku';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostika zkopírována do schránky.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Informace o sestavení';

  @override
  String get developerToolsBuildVersion => 'Verze aplikace';

  @override
  String get developerToolsBuildChannel => 'Kanál sestavení';

  @override
  String get insightCardTitle => 'Nejméně úsporné způsoby jízdy';

  @override
  String get insightEmptyState => 'Žádné výrazné neefektivity — tak dál!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor nad 3000 RPM ($pctTime% cesty): zbytečně spotřebováno $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count prudkých zrychlení: zbytečně spotřebováno $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Volnoběh ($pctTime% cesty): zbytečně spotřebováno $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% cesty';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Jízda na nízký převod ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Při dlouhých zastávkách vypínejte motor, místo abyste jej nechávali běžet na volnoběh.';

  @override
  String get lessonAdviceHighRpm =>
      'Řaďte dříve nahoru, abyste udrželi motor mimo pásmo vysokých otáček.';

  @override
  String get lessonAdviceHardAccel =>
      'Plynule přidávejte plyn — plynulá akcelerace spotřebuje méně paliva.';

  @override
  String get lessonAdviceLowGear =>
      'Řaďte nahoru dříve, aby se motor usadil v nižších, úspornějších otáčkách.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Trvale vysoká rychlost ($pctTime % jízdy): zbytečně $liters l';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Trvale vysoká rychlost ($pctTime % jízdy)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Nad 110 km/h ubertte plyn – odpor vzduchu prudce roste, mírné zpomalení ušetří hodně paliva.';

  @override
  String get lessonSmoothDrivingTitle => 'Plynulá jízda – skvělá práce!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Tato jízda bez prudkého zrychlování a brzdění – plynulá jízda udržuje spotřebu nízkou.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Full throttle ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Ease onto the pedal — a gentler 70 % of the throttle gets you up to speed on far less fuel.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Rich mixture under load ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Heavy, sustained load makes the engine run rich — short-shift and back off on long climbs to keep the mixture lean.';

  @override
  String get drivingScoreCardTitle => 'Skóre jízdy';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Souhrnné skóre z volnoběhu, prudkých zrychlení, prudkého brzdění a času při vysokém RPM. Srovnání „lepší než X % předchozích cest\" přijde v budoucí verzi.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Skóre jízdy $score ze 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Volnoběh';

  @override
  String get drivingScorePenaltyHardAccel => 'Prudká zrychlení';

  @override
  String get drivingScorePenaltyHardBrake => 'Prudké brzdění';

  @override
  String get drivingScorePenaltyHighRpm => 'Vysoké RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Plný plyn';

  @override
  String get drivingScoreClassVeryGood => 'Very good';

  @override
  String get drivingScoreClassGood => 'Good';

  @override
  String get drivingScoreClassAverage => 'Average';

  @override
  String get drivingScoreClassBad => 'Needs work';

  @override
  String get drivingScorePenaltyLugging => 'Lugging';

  @override
  String get drivingScorePenaltySmoothness => 'Jerky driving';

  @override
  String get drivingScorePenaltyHighSpeed => 'High speed';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Aggressive pedal';

  @override
  String get drivingScorePenaltyLambda => 'Rich mixture';

  @override
  String get ecoRouteOption => 'Eko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L ušetřeno';
  }

  @override
  String get ecoRouteHint =>
      'Chytřejší jízda — upřednostňuje stabilní dálnici před klikatými zkratkami.';

  @override
  String get favoritesShareAction => 'Sdílet';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — oblíbené ze dne $date';
  }

  @override
  String get favoritesShareError =>
      'Nepodařilo se vygenerovat obrázek pro sdílení';

  @override
  String get featureManagementSectionTitle => 'Správa funkcí';

  @override
  String get featureManagementSectionSubtitle =>
      'Zapínejte nebo vypínejte jednotlivé funkce. Některé funkce závisí na jiných — přepínače jsou deaktivovány, dokud nejsou splněny předpoklady.';

  @override
  String get featureLabel_obd2TripRecording => 'Nahrávání cest OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Automatické zachycení cest přes OBD2.';

  @override
  String get featureLabel_gamification => 'Gamifikace';

  @override
  String get featureDescription_gamification => 'Skóre jízdy a odznaky.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptický eko-kouč';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Haptická zpětná vazba v reálném čase během cesty.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synchronizace mezi zařízeními přes Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analýza spotřeby';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Záložka analýzy tankování a cest.';

  @override
  String get featureLabel_baselineSync => 'Synchronizace základny';

  @override
  String get featureDescription_baselineSync =>
      'Synchronizace jízdních základen přes TankSync.';

  @override
  String get featureLabel_unifiedSearchResults => 'Sjednocené výsledky hledání';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Jeden seznam výsledků kombinující benzínové a EV stanice.';

  @override
  String get featureLabel_priceAlerts => 'Cenová upozornění';

  @override
  String get featureDescription_priceAlerts =>
      'Oznámení o poklesu ceny na základě prahu.';

  @override
  String get featureLabel_priceHistory => 'Historie cen';

  @override
  String get featureDescription_priceHistory =>
      '30denní grafy cen v detailech stanice.';

  @override
  String get featureLabel_routePlanning => 'Plánování tras';

  @override
  String get featureDescription_routePlanning =>
      'Nejlevnější zastávka na vaší trase.';

  @override
  String get featureLabel_evCharging => 'Nabíjení EV';

  @override
  String get featureDescription_evCharging =>
      'Nabíjecí stanice přes OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling poradenství pomocí dopravních signálů OSM.';

  @override
  String get featureLabel_gpsTripPath => 'GPS trasa cesty';

  @override
  String get featureDescription_gpsTripPath =>
      'Ukládání vzorků GPS trasy spolu s každou cestou.';

  @override
  String get featureLabel_autoRecord => 'Automatické nahrávání';

  @override
  String get featureDescription_autoRecord =>
      'Automaticky spustit cestu, když se adaptér OBD2 připojí k pohybujícímu se vozidlu.';

  @override
  String get featureLabel_showFuel => 'Zobrazit benzínové stanice';

  @override
  String get featureDescription_showFuel =>
      'Zobrazit výsledky benzínových/dieselových stanic ve vyhledávání a na mapě.';

  @override
  String get featureLabel_showElectric => 'Zobrazit nabíjecí stanice';

  @override
  String get featureDescription_showElectric =>
      'Zobrazit nabíjecí stanice EV ve vyhledávání a na mapě.';

  @override
  String get featureLabel_showConsumptionTab => 'Záložka Spotřeba';

  @override
  String get featureDescription_showConsumptionTab =>
      'Zobrazit záložku analýzy spotřeby v dolní navigaci.';

  @override
  String get featureBlockedEnable_gamification =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Nejprve povolte TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureBlockedEnable_showFuel => 'Předpoklady nejsou splněny';

  @override
  String get featureBlockedEnable_showElectric => 'Předpoklady nejsou splněny';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Předpověď ceny TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Model předpovědi cen přímo v zařízení — inference běží lokálně; funkce a předpovědi nikdy neopustí zařízení.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Nejprve povolte historii cen';

  @override
  String get featureLabel_fuelCalculator => 'Kalkulačka paliva';

  @override
  String get featureDescription_fuelCalculator =>
      'Kalkulačka dostupných nákladů na palivo z výsledků hledání.';

  @override
  String get featureLabel_carbonDashboard => 'Uhlíkový přehled';

  @override
  String get featureDescription_carbonDashboard =>
      'Přehled uhlíkové stopy dostupný ze záložky Spotřeba.';

  @override
  String get featureLabel_experimentalOemPids => 'Experimentální OEM PID';

  @override
  String get featureDescription_experimentalOemPids =>
      'Čtení přesného množství paliva v nádrži přes výrobcem specifické PID na podporovaných adaptérech.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Nejprve povolte nahrávání cest OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Skenovat platební QR';

  @override
  String get featureDescription_paymentQrScan =>
      'QR čtečka pro platbu na obrazovce detailu stanice.';

  @override
  String get featureLabel_communityPriceReports => 'Komunitní cenová hlášení';

  @override
  String get featureDescription_communityPriceReports =>
      'Nahlásit cenu stanice z obrazovky detailu stanice.';

  @override
  String get featureLabel_obd2Optional => 'Vyžadovat OBD2 pro záznam jízd';

  @override
  String get featureDescription_obd2Optional =>
      'Když je vypnuto, aplikace zaznamenává jízdy pouze pomocí GPS bez OBD2 adaptéru. Coaching je omezen — žádné okamžité L/100 km, méně motorových signálů.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR účtenky';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Naskenujte vytištěnou účtenku na obrazovce Přidat tankování, abyste předvyplnili datum, litry, celkovou částku a čerpací stanici.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'OCR displeje pumpy (experimentální)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Naskenujte displej palivového čerpadla a předvyplňte formulář. Rozpoznávání je dnes nespolehlivé — aktivujte pouze, pokud chcete testovat.';

  @override
  String get featureLabel_developerPatToken =>
      'Vývojářská zpětná vazba (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Aktivuje panel pro hlášení neúspěšných skenů, který automaticky vytváří GitHub issues s Personal Access Token. Funkce pro pokročilé uživatele/přispěvatele.';

  @override
  String get featureLabel_debugMode => 'Vývojářský/ladicí režim';

  @override
  String get featureDescription_debugMode =>
      'Zobrazí v nastavení sekci Nástroje pro vývojáře s diagnostikou: export protokolu chyb, testovací oznámení, spuštění testovacího procesu upozornění, výpis příznaků funkcí, vymazání mezipamětí a kopírování diagnostiky.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get feedbackConsentTitle => 'Odeslat hlášení na GitHub?';

  @override
  String get feedbackConsentBody =>
      'Tímto se vytvoří veřejný ticket v našem GitHub repozitáři s vaší fotografií a textem z OCR. Nejsou odesílány žádné osobní údaje (poloha, ID účtu). Pokračovat?';

  @override
  String get feedbackConsentContinue => 'Pokračovat';

  @override
  String get feedbackConsentCancel => 'Zrušit';

  @override
  String get feedbackConsentLater => 'Později';

  @override
  String get feedbackTokenSectionTitle =>
      'Zpětná vazba na špatné skenování (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Pro automatické otevření GitHub ticketu při neúspěšném skenování vložte GitHub PAT (oprávnění `public_repo` na repozitáři tankstellen). Jinak zůstane dostupné ruční sdílení.';

  @override
  String get feedbackTokenStatusSet => 'Token nastaven';

  @override
  String get feedbackTokenStatusUnset => 'Žádný token';

  @override
  String get feedbackTokenSet => 'Nastavit';

  @override
  String get feedbackTokenClear => 'Vymazat';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Osobní přístupový token';

  @override
  String get fillUpGuidanceTitle => 'Best time to fill up';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'The current price is among the cheapest of the last $days days — a good time to fill up.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Prices are near their $days-day high. They are usually cheaper $window — consider waiting.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Prices are trending up — consider filling up soon.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Today\'s price is around the $days-day average.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Could save about $amount/L by timing your fill-up.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count price readings',
      one: 'Based on 1 price reading',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'on $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'in the $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'at other times';

  @override
  String get fillUpGuidanceWeekday1 => 'Mondays';

  @override
  String get fillUpGuidanceWeekday2 => 'Tuesdays';

  @override
  String get fillUpGuidanceWeekday3 => 'Wednesdays';

  @override
  String get fillUpGuidanceWeekday4 => 'Thursdays';

  @override
  String get fillUpGuidanceWeekday5 => 'Fridays';

  @override
  String get fillUpGuidanceWeekday6 => 'Saturdays';

  @override
  String get fillUpGuidanceWeekday7 => 'Sundays';

  @override
  String get fillUpGuidancePartEarlyMorning => 'early mornings';

  @override
  String get fillUpGuidancePartMorning => 'mornings';

  @override
  String get fillUpGuidancePartAfternoon => 'afternoons';

  @override
  String get fillUpGuidancePartEvening => 'evenings';

  @override
  String get fillUpGuidancePartNight => 'nights';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Ověřeno adaptérem';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Neshoduje se s odečtem adaptéru';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Váš záznam: $userL L. Adaptér uvádí: $adapterL L (rozdíl z odečtu hladiny paliva před/po). Použít hodnotu adaptéru?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Ponechat můj záznam';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Použít hodnotu adaptéru';

  @override
  String get scanReceiptNoData =>
      'Nenalezena žádná data účtenky — zkuste znovu';

  @override
  String get scanReceiptSuccess =>
      'Účtenka naskenována — ověřte hodnoty. Klepněte na „Nahlásit chybu skenování\" níže, pokud je něco špatně.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skenování selhalo: $error';
  }

  @override
  String get scanPumpUnreadable => 'Displej pumpy není čitelný — zkuste znovu';

  @override
  String get scanPumpSuccess => 'Displej pumpy naskenován — ověřte hodnoty.';

  @override
  String get scanPumpGlare =>
      'Příliš mnoho odlesků na displeji — zkuste to znovu z mírného úhlu, aby čísla nebyla přezářená.';

  @override
  String scanPumpFailed(String error) {
    return 'Skenování pumpy selhalo: $error';
  }

  @override
  String get badScanReportTitle => 'Nahlásit chybu skenování';

  @override
  String get badScanReportTitleReceipt => 'Nahlásit chybu skenování — Účtenka';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Nahlásit chybu skenování — Displej pumpy';

  @override
  String get pumpScanFailureTitle => 'Displej nečitelný';

  @override
  String get pumpScanFailureBody =>
      'Skenování nemohlo přečíst displej pumpy. Co chcete udělat?';

  @override
  String get pumpScanFailureCorrectManually => 'Opravit ručně';

  @override
  String get pumpScanFailureReport => 'Nahlásit';

  @override
  String get pumpScanFailureRemove => 'Odebrat fotografii';

  @override
  String get badScanReportHint =>
      'Sdílíme fotografii účtenky a obě sady hodnot, aby se příští verze naučila toto rozvržení.';

  @override
  String get badScanReportShareAction => 'Sdílet hlášení + fotografii';

  @override
  String get badScanReportFieldBrandLayout => 'Rozvržení značky';

  @override
  String get badScanReportFieldTotal => 'Celkem';

  @override
  String get badScanReportFieldPricePerLiter => 'Cena/L';

  @override
  String get badScanReportFieldStation => 'Stanice';

  @override
  String get badScanReportFieldFuel => 'Palivo';

  @override
  String get badScanReportFieldDate => 'Datum';

  @override
  String get badScanReportHeaderField => 'Pole';

  @override
  String get badScanReportHeaderScanned => 'Naskenováno';

  @override
  String get badScanReportHeaderYouTyped => 'Zadali jste';

  @override
  String get badScanReportCreateTicket => 'Vytvořit ticket';

  @override
  String get badScanReportOpenInBrowser => 'Otevřít v prohlížeči';

  @override
  String get badScanReportFallbackToShare => 'Odeslání selhalo — ruční sdílení';

  @override
  String get pumpCameraHint =>
      'Zarovnejte tři čísla z displeje stojanu do rámečku';

  @override
  String get pumpCameraCapture => 'Vyfotit';

  @override
  String get pumpCameraPermissionDenied =>
      'Pro naskenování displeje stojanu je potřeba přístup ke kameře. Povolte jej v nastavení zařízení.';

  @override
  String get pumpCameraError =>
      'Kameru se nepodařilo spustit. Zkuste to znovu nebo zadejte hodnoty ručně.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Přepnout na vodorovné rozložení';

  @override
  String get pumpCameraOrientationVertical => 'Přepnout na svislé rozložení';

  @override
  String get pumpCameraGlareWarning =>
      'Příliš mnoho odlesků — mírně nakloňte, abyste se vyhnuli odrazům';

  @override
  String get pumpCameraAlignHint =>
      'Zarovnejte displej do rámečku a poté vyfotografujte';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Co jste natankovali';

  @override
  String get fillUpSectionWhatSubtitle => 'Palivo, množství, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kde jste byli';

  @override
  String get fillUpSectionWhereSubtitle => 'Stanice, tachometr, poznámky';

  @override
  String get fillUpImportFromLabel => 'Importovat z…';

  @override
  String get fillUpImportSheetTitle => 'Importovat data tankování';

  @override
  String get fillUpImportReceiptLabel => 'Účtenka';

  @override
  String get fillUpImportReceiptDescription =>
      'Naskenovat papírovou účtenku kamerou';

  @override
  String get fillUpImportPumpLabel => 'Displej pumpy';

  @override
  String get fillUpImportPumpDescription =>
      'Přečíst Betrag / Preis z LCD displeje pumpy';

  @override
  String get fillUpImportObdLabel => 'Adaptér OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Přečíst tachometr z portu OBD-II přes Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Cena za litr';

  @override
  String get vehicleHeaderPlateLabel => 'Poznávací značka';

  @override
  String get vehicleHeaderUntitled => 'Nové vozidlo';

  @override
  String get vehicleSectionIdentityTitle => 'Identita';

  @override
  String get vehicleSectionIdentitySubtitle => 'Název a VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Pohon';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Jak se toto vozidlo pohání';

  @override
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get calibrationModeLabel => 'Režim kalibrace';

  @override
  String get calibrationModeRule => 'Pravidlový';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Pravidlový přiřadí každý vzorek jízdy přesně do jedné situace. Fuzzy ho rozloží napříč všemi situacemi podle míry shody — plynulejší kolem 60 km/h nebo při měnícím se sklonu, ale pomalejší pro naplnění všech kategorií.';

  @override
  String get profileGamificationToggleTitle => 'Zobrazovat úspěchy a skóre';

  @override
  String get profileGamificationToggleSubtitle =>
      'Pokud je vypnuto, odznaky, skóre a ikony pohárů jsou v celé aplikaci skryty.';

  @override
  String get coachingGpsLiftOff => 'Uvolnit plyn';

  @override
  String get coachingGpsAnticipateBrake => 'Předvídat';

  @override
  String get coachingGpsSmoothAccel => 'Plynulé zrychlení';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostika vzorkování GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps mezer',
      one: '1 mezera',
      zero: 'žádné mezery',
    );
    return '$count vzorků · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Medián intervalu: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Zachyceno během nahrávání pro ověření kadence GPS při spánku telefonu.';

  @override
  String get gpsMatrixMaturityCold => 'Studená';

  @override
  String get gpsMatrixMaturityWarming => 'Zahřívá se';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergující';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'Matice GPS se zahřívá ($count úprav). Odhady prozatímní.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'Matice GPS konverguje ($count tankování). Odhady použitelné, mohou se lišit o pár %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'Matice GPS konverguje ($count tankování). Odhady do ~2 % skutečné spotřeby.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Jízda';

  @override
  String get hapticEcoCoachSettingTitle => 'Eko coaching v reálném čase';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Jemná haptika + tip na obrazovce při plném plynu v krouticím režimu';

  @override
  String get hapticEcoCoachSnackBarMessage => 'Mírnit plyn — výběh šetří více';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigovat na $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Odebrat $name z oblíbených';
  }

  @override
  String get showOnMapSemanticLabel => 'Zobrazit stanice na mapě';

  @override
  String get searchResultsSemanticLabel => 'Výsledky vyhledávání';

  @override
  String get searchCriteriaSemanticLabel =>
      'Souhrn kritérií vyhledávání. Klepnutím upravíte.';

  @override
  String get noFavoritesSemanticLabel =>
      'Zatím žádné oblíbené. Klepnutím na hvězdičku u stanice ji uložíte jako oblíbenou.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stanice je otevřená',
      'false': 'Stanice je zavřená',
      'other': 'Stanice je zavřená',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Země $name, vybráno',
      'false': 'Země $name',
      'other': 'Země $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Jazyk $name, vybráno',
      'false': 'Jazyk $name',
      'other': 'Jazyk $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Seřadit podle $option, vybráno',
      'false': 'Seřadit podle $option',
      'other': 'Seřadit podle $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Palivo $type, vybráno',
      'false': 'Palivo $type',
      'other': 'Palivo $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Nabíjecí stanice $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Štít soukromí s kapkou paliva';

  @override
  String get globeIllustrationSemantic => 'Globus se značkami čerpacích stanic';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Čerpací stojan s cenovým tickerem';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, zdroj dat: $provider, $keyRequirement, druhy paliva: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Vyžadován klíč API';

  @override
  String get countryInfoNoKeyNeeded => 'Zdarma, bez klíče';

  @override
  String countryInfoDataSource(String provider) {
    return 'Data: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Druhy paliva: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anonymní klíč';

  @override
  String get anonKeyHideTooltip => 'Skrýt klíč';

  @override
  String get anonKeyShowTooltip => 'Zobrazit klíč pro ověření';

  @override
  String anonKeyTooLong(int length) {
    return 'Klíč je příliš dlouhý ($length znaků) — zkontrolujte nadbytečný text';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Klíč vypadá správně ($length znaků)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Klíč by měl být JWT (záhlaví.payload.podpis)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Klíč může být zkrácen ($length z ~208 očekávaných znaků)';
  }

  @override
  String get anonKeyExceedsMax => 'Klíč překračuje maximální délku';

  @override
  String get qrShareTitle => 'Sdílet vaši databázi';

  @override
  String get qrShareSubtitle =>
      'Ostatní mohou naskenovat tento QR kód pro připojení';

  @override
  String get qrShareCopyAsText => 'Kopírovat jako text';

  @override
  String get authInfoTitle => 'Proč vytvořit účet?';

  @override
  String get authInfoBenefit1 =>
      '• Synchronizovat oblíbené, upozornění a uložené trasy napříč zařízeními';

  @override
  String get authInfoBenefit2 =>
      '• Naplánovat trasu na telefonu, použít ji v autě';

  @override
  String get authInfoBenefit3 =>
      '• Žádná data nejsou sdílena s třetími stranami';

  @override
  String get authInfoBenefit4 => '• Účet lze kdykoli smazat';

  @override
  String get privacyLocalDataEmpty =>
      'Zatím nic uloženo. Přidejte oblíbenou nebo nastavte cenové upozornění pro zobrazení záznamů.';

  @override
  String get privacyHideEmptyRows => 'Skrýt prázdné řádky';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobrazit $count prázdných řádků',
      one: 'Zobrazit $count prázdný řádek',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Nastavení klíče API (volitelné)';

  @override
  String get apiKeySetupDescription =>
      'Zaregistrujte se pro bezplatný klíč API, nebo přeskočte a prozkoumejte aplikaci s ukázkovými daty.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Registrace $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Zadáním klíče API přijímáte podmínky $provider. Redistribuce dat je zakázána.';
  }

  @override
  String get calculatorDistanceHint => 'např. 150';

  @override
  String get calculatorConsumptionHint => 'např. 7,0';

  @override
  String get calculatorPriceHint => 'např. 1,899';

  @override
  String get routeStrategyLabel => 'Strategie:';

  @override
  String get routeStrategyUniform => 'Rovnoměrná';

  @override
  String get routeStrategyBalanced => 'Vyvážená';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (experimentální)';

  @override
  String get glideCoachBetaSubtitle =>
      'Jemná haptika při zpomalování před červenou. Ve výchozím stavu vypnuto — riziko rozptýlení.';

  @override
  String get consentSyncTripsTitle => 'Synchronizovat záznamy cest';

  @override
  String get consentSyncTripsSubtitle =>
      'Zálohovat OBD2 + GPS cesty na TankSync. Mezi zařízeními, volitelné.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Pro zálohování cest povolte cloudovou synchronizaci výše.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Přihlaste se pomocí e-mailového účtu pro synchronizaci jízd mezi zařízeními.';

  @override
  String get consentHideDetails => 'Skrýt podrobnosti';

  @override
  String get consentShowDetails => 'Zobrazit podrobnosti';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Neplatný odkaz';

  @override
  String invalidLinkBody(String path) {
    return 'Odkaz \"$path\" není platný.';
  }

  @override
  String get home => 'Domů';

  @override
  String get locationConsentTitle => 'Přístup k poloze';

  @override
  String get locationConsentSubtitle =>
      'Tato aplikace chce použít vaši polohu k vyhledání čerpacích stanic ve vašem okolí.';

  @override
  String get locationConsentWhatHappens => 'Co se děje s údaji o vaší poloze:';

  @override
  String get locationConsentBulletApi =>
      'Vaše souřadnice se odesílají do API cen paliv pro vyhledání blízkých stanic.';

  @override
  String get locationConsentBulletNoServer =>
      'Vaše poloha se neukládá na žádném serveru — žádný server neexistuje.';

  @override
  String get locationConsentBulletNoTracking =>
      'Údaje o poloze se nepoužívají k reklamě, analytice ani sledování.';

  @override
  String get locationConsentRevoke =>
      'Přístup k poloze můžete kdykoli odvolat v nastavení systému. Případně můžete vyhledávat podle PSČ.';

  @override
  String get locationConsentLegalBasis =>
      'Právní základ: čl. 6 odst. 1 písm. a) GDPR (souhlas)';

  @override
  String get locationConsentDecline => 'Odmítnout';

  @override
  String get locationConsentAccept => 'Přijmout';

  @override
  String get loyaltySettingsTitle => 'Věrnostní karty palivových klubů';

  @override
  String get loyaltySettingsSubtitle =>
      'Uplatnit věrnostní slevu na zobrazené ceny';

  @override
  String get loyaltyMenuTitle => 'Věrnostní karty palivových klubů';

  @override
  String get loyaltyMenuSubtitle =>
      'Uplatnit slevy za litr od Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Přidat kartu';

  @override
  String get loyaltyAddCardSheetTitle => 'Přidat věrnostní palivovou kartu';

  @override
  String get loyaltyBrandLabel => 'Značka';

  @override
  String get loyaltyCardLabelLabel => 'Popis (volitelné)';

  @override
  String get loyaltyDiscountLabel => 'Sleva (za litr)';

  @override
  String get loyaltyDiscountInvalid => 'Zadejte kladné číslo';

  @override
  String get loyaltyDeleteConfirmTitle => 'Smazat kartu?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Tato karta přestane uplatňovat svou slevu.';

  @override
  String get loyaltyEmptyTitle => 'Zatím žádné věrnostní palivové karty';

  @override
  String get loyaltyEmptyBody =>
      'Přidejte kartu pro automatické uplatnění slevy za litr na odpovídajících stanicích.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Detekováno zvyšování volnoběžného RPM';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Volnoběžné RPM se zvýšilo o $percent% za posledních $tripCount cest. Možný raný příznak ucpaného vzduchového filtru nebo driftu senzoru.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Možné omezení nasávání';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Průtok paliva při jízdě klesl o $percent% za posledních $tripCount cest. Možný příznak ucpaného vzduchového filtru nebo omezeného nasávání — stojí za kontrolu.';
  }

  @override
  String get maintenanceActionDismiss => 'Zavřít';

  @override
  String get maintenanceActionSnooze => 'Odložit na 30 dní';

  @override
  String get consumptionMonthlyInsightsTitle => 'Tento měsíc vs. minulý měsíc';

  @override
  String get consumptionMonthlyTripsLabel => 'Cesty';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Doba jízdy';

  @override
  String get consumptionMonthlyDistanceLabel => 'Vzdálenost';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Průměrná spotřeba';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Pro porovnání jsou potřeba alespoň 3 cesty za měsíc';

  @override
  String get obd2CapabilitySectionTitle => 'Možnosti adaptéru';

  @override
  String get obd2CapabilityStandardOnly => 'Standardní';

  @override
  String get obd2CapabilityOemPids => 'OEM PID';

  @override
  String get obd2CapabilityFullCan => 'Plný CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Pro přesné litry v nádrži Peugeot/Citroën podporuje aplikace OBDLink MX+/LX/CX (čip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Diagnostická vrstva OBD2 povolena';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Diagnostická vrstva OBD2 zakázána';

  @override
  String get obd2DebugOverlayClearButton => 'Vymazat';

  @override
  String get obd2DebugOverlayCloseButton => 'Zavřít';

  @override
  String get obd2DebugOverlayTitle => 'Stopy OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Sdílet diagnostický protokol';

  @override
  String get obd2DebugLoggingTitle => 'Ladicí protokolování OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Zaznamenávejte každou relaci OBD2 — připojení, handshake, výpadky dat a opětovná připojení — do exportovatelného XML protokolu. Ve výchozím nastavení vypnuto.';

  @override
  String get obd2DebugSessionShareLabel => 'Sdílet protokol relace OBD2';

  @override
  String get obd2DiagnosticsTitle => 'OBD2 communication health';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops drops',
      one: '1 drop',
      zero: 'no drops',
    );
    return '$percent% complete · $duty% duty · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Connection lifecycle';

  @override
  String get obd2DiagnosticsPidSection => 'Per-PID outcomes';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Scheduler health';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Completeness';

  @override
  String get obd2DiagnosticsSupportSection => 'Discovered-supported PIDs';

  @override
  String get obd2DiagnosticsFuelSection => 'Fuel-tier rollup';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protocol $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts attempts · $successes ok · $drops drops · time-to-connect p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Reconnects: $silent silent · $visible visible';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips back-pressure skips · $demotions demotions';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dynamics tier starved — RPM / speed fell below the governor floor.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Overall $percent% · active duty $duty%';
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
    return '$supported supported · $unsupported unsupported · $unknown unknown';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Suspicious $suspicious of $total samples';
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
    return '$pid: $polled polled · $ok ok · $noData ND · $timeout TO · $error err · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Dongle init transcript';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protocol $protocol · $start · firmware $firmware · $tier · $pids PIDs';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'warm';

  @override
  String get obd2DiagnosticsInitCold => 'cold';

  @override
  String get obd2HealthCopyInitTranscript => 'Copy init transcript only';

  @override
  String get obd2DiagnosticsEmpty =>
      'No OBD2 session recorded yet — connect an adapter and record a trip with Developer mode on.';

  @override
  String get obd2DiagnosticsExplain =>
      'Captured while recording to debug the dongle↔app communication — only collected in Developer mode.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 communication health';

  @override
  String get obd2HealthNavLabel => 'OBD2 communication health';

  @override
  String get obd2HealthLiveSection => 'Live session';

  @override
  String get obd2HealthHistorySection => 'Recent sessions';

  @override
  String get obd2HealthCopyJson => 'Copy as JSON';

  @override
  String get obd2HealthCopied => 'OBD2 diagnostics copied to clipboard.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nelze se připojit k \'$adapterName\' — vyberte jiný adaptér';
  }

  @override
  String get ocrTesterTitle => 'OCR tester';

  @override
  String get ocrTesterNavLabel => 'OCR tester';

  @override
  String get ocrTesterExplain =>
      'Run the pump / receipt OCR pipeline on a chosen photo and inspect every step — only available in Developer mode.';

  @override
  String get ocrTesterModePump => 'Pump';

  @override
  String get ocrTesterModeReceipt => 'Receipt';

  @override
  String get ocrTesterCapture => 'Capture';

  @override
  String get ocrTesterPickImage => 'Pick image';

  @override
  String get ocrTesterRun => 'Run';

  @override
  String get ocrTesterCountry => 'Country';

  @override
  String get ocrTesterCountryNone => 'Default (no profile)';

  @override
  String get ocrTesterNoImage => 'Pick or capture an image, then Run.';

  @override
  String get ocrTesterRunning => 'Running OCR…';

  @override
  String get ocrTesterNoResult => 'OCR produced no readable result.';

  @override
  String get ocrTesterOverlaySection => 'Block overlay';

  @override
  String get ocrTesterStepsSection => 'Pipeline steps';

  @override
  String get ocrTesterLegendLabel => 'Label';

  @override
  String get ocrTesterLegendNumeric => 'Numeric';

  @override
  String get ocrTesterLegendNoise => 'Noise';

  @override
  String get ocrTesterLegendDerived => 'Derived';

  @override
  String get ocrTesterStageGlare => 'Capture / glare';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Classify';

  @override
  String get ocrTesterStageAssemble => 'Assemble';

  @override
  String get ocrTesterStageAnchor => 'Anchor';

  @override
  String get ocrTesterStageFallback => 'Fallback';

  @override
  String get ocrTesterStageCrossCheck => 'Cross-check';

  @override
  String get ocrTesterStageConfidence => 'Confidence';

  @override
  String get ocrTesterStageGate => 'Gate';

  @override
  String get ocrTesterStageBrand => 'Brand';

  @override
  String get ocrTesterStageOverrides => 'Overrides';

  @override
  String get ocrTesterStageReconcile => 'Reconcile';

  @override
  String get ocrTesterStageResult => 'Result';

  @override
  String get ocrTesterChipRead => 'READ';

  @override
  String get ocrTesterChipDerived => 'DERIVED';

  @override
  String get ocrTesterGateAccepted => 'Accepted';

  @override
  String get ocrTesterGateRejected => 'Rejected';

  @override
  String get ocrTesterFallbackBanner =>
      'A field was recovered via magnitude fallback — verify it.';

  @override
  String get ocrTesterStageNoData => 'Stage did not run.';

  @override
  String get ocrTesterCopyJson => 'Copy as JSON';

  @override
  String get ocrTesterExportPackage => 'Export package';

  @override
  String get ocrTesterCopied => 'OCR trace copied to clipboard.';

  @override
  String get ocrTesterExported => 'OCR package saved to your Downloads folder.';

  @override
  String get ocrTesterSaveFixture => 'Save as fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture saved to your Downloads folder. Move it under test/fixtures and run tool/promote_ocr_fixture.dart.';

  @override
  String get onboardingObd2StepTitle => 'Připojit adaptér OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Zapojte adaptér OBD2 do portu auta a zapněte zapalování. Přečteme VIN a vyplníme podrobnosti o motoru za vás.';

  @override
  String get onboardingObd2ConnectButton => 'Připojit adaptér';

  @override
  String get onboardingObd2SkipButton => 'Možná později';

  @override
  String get onboardingObd2ReadingVin => 'Čtení VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Nepodařilo se přečíst VIN — zadejte ručně';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nepodařilo se připojit k adaptéru. Můžete to zkusit znovu nebo přeskočit.';

  @override
  String get onboardingPickUseMode => 'Pro pokračování vyberte režim použití.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'uplynulo';

  @override
  String get alertsRadiusFrequencyLabel => 'Frekvence kontroly';

  @override
  String get alertsRadiusFrequencyDaily => 'Jednou denně';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Dvakrát denně';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Třikrát denně';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Čtyřikrát denně';

  @override
  String get radiusAlertPickOnMap => 'Vybrat na mapě';

  @override
  String get radiusAlertMapPickerTitle => 'Vybrat střed upozornění';

  @override
  String get radiusAlertMapPickerConfirm => 'Potvrdit';

  @override
  String get radiusAlertMapPickerCancel => 'Zrušit';

  @override
  String get radiusAlertMapPickerHint =>
      'Přetáhněte mapu pro umístění středu upozornění';

  @override
  String get radiusAlertCenterFromMap => 'Poloha na mapě';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel poblíž $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Stanice je za $price € (cíl: $threshold €)';
  }

  @override
  String get reconcileWorkflowTitle => 'Reconcile your fuel';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'We found a $gap L gap';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'You pumped $pumped L, but your recorded trips only account for $consumed L. That leaves $gap L unexplained.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'This usually means a drive wasn\'t recorded (the adapter was unplugged or the app was closed), or a fill-up is missing or mistyped.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Until this is resolved, your fuel total and your trips total won\'t match.';

  @override
  String get reconcileWorkflowAttributeQuestion => 'Help us attribute the gap';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Are all your fill-ups for this tank complete and correct?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Are all your drives recorded?';

  @override
  String get reconcileWorkflowAnswerYes => 'Yes';

  @override
  String get reconcileWorkflowAnswerNo => 'No';

  @override
  String get reconcileWorkflowPathAHint =>
      'A fill-up is missing or wrong — we\'ll add a correction so your fill-ups add up.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Your fill-ups are right and a drive went unrecorded — we\'ll add a virtual trip for the missing distance.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Correction litres';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'How far was the unrecorded drive? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Decide later';

  @override
  String get reconcileWorkflowBack => 'Back';

  @override
  String get reconcileWorkflowNext => 'Next';

  @override
  String get reconcileWorkflowApply => 'Apply';

  @override
  String get reconcileVirtualTrajetLabel => 'Virtual trip — tap to edit';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Edit virtual trip';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'This trip was added to account for fuel you used while driving without recording. Adjust the distance or fuel, or delete it.';

  @override
  String get reconcileVirtualTrajetDelete => 'Delete virtual trip';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Unresolved fuel/trip gap of $gap L — tap to resolve';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Resolve unresolved fuel and trip gap';

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/relaci';

  @override
  String get speedConsumptionCardTitle => 'Spotřeba podle rychlosti';

  @override
  String get speedBandIdleJam => 'Volnoběh / kolona';

  @override
  String get speedBandUrban => 'Město (10–50)';

  @override
  String get speedBandSuburban => 'Předměstí (50–80)';

  @override
  String get speedBandRural => 'Venkov (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eko-cestovní (100–115)';

  @override
  String get speedBandMotorway => 'Dálnice (115–130)';

  @override
  String get speedBandMotorwayFast => 'Rychlá dálnice (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Zaznamenejte 30+ minut cest s adaptérem OBD2 pro odemčení analýzy rychlosti/spotřeby.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % jízdy';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Potřeba více dat';

  @override
  String get splashLoadingLabel => 'Načítání Sparkilo';

  @override
  String get storageRecoveryTitle => 'Problém s úložištěm';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo nemohlo otevřít své místní úložiště dat. Soubor úložiště je zřejmě poškozený.';

  @override
  String get storageRecoveryGuidance =>
      'Pro obnovu vymažte úložiště aplikace v nastavení zařízení nebo aplikaci přeinstalujte. Vaše oblíbené položky a historie jsou uloženy pouze v tomto zařízení, proto je nelze obnovit automaticky.';

  @override
  String get tankLevelTitle => 'Hladina paliva';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km dojezdu';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Poslední tankování: $date · $count cesta/cest od té doby';
  }

  @override
  String get tankLevelMethodObd2 => 'Měřeno OBD2';

  @override
  String get tankLevelMethodDistanceFallback => 'odhad podle vzdálenosti';

  @override
  String get tankLevelMethodMixed => 'kombinované měření';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Pro zobrazení hladiny paliva zaznamenejte tankování';

  @override
  String get tankLevelDetailSheetTitle => 'Cesty od posledního tankování';

  @override
  String get addFillUpIsFullTankLabel => 'Plná nádrž';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Nádrž natankována nadoraz — odškrtněte, pokud to bylo pouze částečné tankování';

  @override
  String get themeCardTitle => 'Motiv';

  @override
  String get themeCardSubtitleSystem => 'Systém';

  @override
  String get themeCardSubtitleLight => 'Světlý';

  @override
  String get themeCardSubtitleDark => 'Tmavý';

  @override
  String get themeSettingsScreenTitle => 'Motiv';

  @override
  String get themeSettingsSystemLabel => 'Sledovat systém';

  @override
  String get themeSettingsLightLabel => 'Světlý';

  @override
  String get themeSettingsDarkLabel => 'Tmavý';

  @override
  String get themeSettingsSystemDescription =>
      'Přizpůsobit aktuálnímu vzhledu zařízení.';

  @override
  String get themeSettingsLightDescription =>
      'Světlé pozadí — nejlepší pro denní použití.';

  @override
  String get themeSettingsDarkDescription =>
      'Tmavé pozadí — šetří oči v noci a šetří baterii na OLED obrazovkách.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Charakteristický zelený vzhled aplikace — jasný a čitelný se jemně zelenými pozadími.';

  @override
  String get throttleRpmHistogramTitle => 'Jak jste využívali motor';

  @override
  String get throttleRpmHistogramThrottleSection => 'Poloha plynového pedálu';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM motoru';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Výběh (0–25 %)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Lehký (25–50 %)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Střední (50–75 %)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Plný (75–100 %)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Volnoběh (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Cestovní (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Dynamický (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Tvrdý (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'V této cestě nejsou žádné vzorky plynu nebo RPM.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Cesty';

  @override
  String get trajetsStartRecordingButton => 'Spustit nahrávání';

  @override
  String get trajetsResumeRecordingButton => 'Obnovit nahrávání';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Připojování k adaptéru OBD2…';

  @override
  String get tripStartProgressReadingVehicleData => 'Čtení dat vozidla…';

  @override
  String get tripStartProgressStartingRecording => 'Spouštění nahrávání…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

  @override
  String get trajetsEmptyStateTitle => 'Zatím žádné cesty';

  @override
  String get trajetsEmptyStateBody =>
      'Klepnutím na Spustit nahrávání začněte zaznamenávat jízdy.';

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
  String get trajetDetailSummaryTitle => 'Přehled';

  @override
  String get trajetDetailFieldDate => 'Datum';

  @override
  String get trajetDetailFieldVehicle => 'Vozidlo';

  @override
  String get trajetDetailFieldAdapter => 'Adaptér OBD2';

  @override
  String get trajetDetailFieldDistance => 'Vzdálenost';

  @override
  String get trajetDetailFieldDuration => 'Trvání';

  @override
  String get trajetDetailFieldAvgConsumption => 'Průměrná spotřeba';

  @override
  String get trajetDetailFieldFuelUsed => 'Spotřebované palivo';

  @override
  String get trajetDetailFieldFuelCost => 'Náklady na palivo';

  @override
  String get trajetDetailFieldAvgSpeed => 'Průměrná rychlost';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maximální rychlost';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Rychlost (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Průtok paliva (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Zatížení motoru (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Grafy';

  @override
  String get trajetsRowColdStartChip => 'Studený start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motor nedosáhl provozní teploty během této cesty — spotřeba paliva byla vyšší než obvykle.';

  @override
  String get trajetDetailChartEmpty => 'Žádné vzorky nezaznamenány';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Sdílet';

  @override
  String get trajetDetailShareImageOption => 'Sdílet obrázek';

  @override
  String get trajetDetailShareGpxOption => 'Sdílet GPS trasu (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Žádná GPS data v této jízdě';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — cesta ze dne $date';
  }

  @override
  String get trajetDetailShareError =>
      'Nepodařilo se vygenerovat obrázek pro sdílení';

  @override
  String get trajetDetailDeleteAction => 'Smazat';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Smazat tuto cestu?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Tato cesta bude trvale odstraněna z vaší historie.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Zrušit';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Smazat';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adaptér OBD2 je připojen, ale nevrací data. Zkuste jiný adaptér nebo zkontrolujte diagnostický protokol vozidla.';

  @override
  String get trajetsViewAllOnMap => 'Zobrazit vše na mapě';

  @override
  String get trajetsMapTitle => 'Jízdy na mapě';

  @override
  String get trajetsMapShareGpx => 'Sdílet GPX';

  @override
  String get trajetsMapEmpty => 'Žádná z vybraných jízd nemá GPS data.';

  @override
  String get trajetsMapShareError => 'Soubor GPX nelze sdílet';

  @override
  String get tripLengthCardTitle => 'Spotřeba podle délky cesty';

  @override
  String get tripLengthBucketShort => 'Krátká (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Střední (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Dlouhá (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Potřeba více dat';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cest',
      one: '1 cesta',
      zero: 'žádné cesty',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Trasa cesty';

  @override
  String get tripPathCardSubtitle => 'GPS zaznamenaná trasa';

  @override
  String get tripPathLegendTitle => 'Spotřeba';

  @override
  String get tripPathLegendEfficient => 'Úsporná (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Přijatelná (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Neúsporná (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get tripRecordingPinTooltip =>
      'Připnutí udržuje obrazovku zapnutou — spotřebuje více baterie';

  @override
  String get tripRecordingPinSemanticOn => 'Odepnout formulář nahrávání';

  @override
  String get tripRecordingPinSemanticOff => 'Připnout formulář nahrávání';

  @override
  String get tripRecordingPinHelpTooltip => 'Co dělá připnutí?';

  @override
  String get tripRecordingPinHelpTitle => 'O připnutí';

  @override
  String get tripRecordingPinHelpBody =>
      'Připnutí udržuje obrazovku zapnutou a skryje systémové lišty, aby byl formulář čitelný na palubní desce. Klepnutím znovu uvolněte. Automaticky se uvolní po zastavení cesty.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Nahrávání pokračuje na pozadí. Klepněte na červený banner v horní části libovolné obrazovky pro návrat.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Otevřít aktivní cestu ze záložky Spotřeba';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Připněte obrazovku pro zachování aktivní GPS během cesty — Android může GPS při spánku omezit.';

  @override
  String get tripRecordingMinimiseTooltip =>
      'Minimalizovat do plovoucí dlaždice';

  @override
  String get tripRecordingAutoPinTitle =>
      'Při zahájení nahrávání vždy připnout';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Připnout formulář automaticky při každé jízdě místo klepání pokaždé. Spotřebuje více baterie.';

  @override
  String get tripRecordingConnectingTitle => 'Spouštění nahrávání…';

  @override
  String get tripRecordingSavingTitle => 'Saving trip…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripShareAction => 'Sdílet s jiným účtem';

  @override
  String get tripShareSheetTitle => 'Sdílet tuto jízdu';

  @override
  String get tripShareSheetSubtitle =>
      'Poskytněte jinému účtu TankSync přístup pouze ke čtení k této zaznamenané jízdě.';

  @override
  String get tripShareEmailLabel => 'E-mail příjemce';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Sdílet';

  @override
  String get tripShareCreateLinkButton => 'Vytvořit odkaz ke sdílení';

  @override
  String get tripShareLinkCreated =>
      'Odkaz ke sdílení zkopírován — vložte jej příjemci.';

  @override
  String get tripShareSuccess => 'Jízda sdílena.';

  @override
  String get tripShareRecipientNotFound =>
      'Tento e-mail nepoužívá žádný účet TankSync.';

  @override
  String get tripShareError => 'Jízdu se nepodařilo sdílet. Zkuste to znovu.';

  @override
  String get tripShareExistingTitle => 'Sdíleno s';

  @override
  String get tripShareExistingEmpty => 'Zatím s nikým nesdíleno.';

  @override
  String get tripShareDirectRecipient => 'Účet';

  @override
  String get tripShareLinkRecipient => 'Odkaz ke sdílení (nevyzvednutý)';

  @override
  String get tripShareRevokeTooltip => 'Zrušit';

  @override
  String get tripShareRevoked => 'Sdílení zrušeno.';

  @override
  String get trajetsSharedSectionTitle => 'Sdíleno se mnou';

  @override
  String get trajetsSharedBadge => 'Sdíleno';

  @override
  String get unifiedFilterFuel => 'Palivo';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Oboje';

  @override
  String get unifiedNoResultsForFilter =>
      'Tomuto filtru neodpovídají žádné výsledky';

  @override
  String get searchFailedSnackbar => 'Hledání selhalo — zkuste to znovu';

  @override
  String get vinLabel => 'VIN (volitelné)';

  @override
  String get vinDecodeTooltip => 'Dekódovat VIN';

  @override
  String get vinConfirmAction => 'Ano, automaticky vyplnit';

  @override
  String get vinModifyAction => 'Upravit ručně';

  @override
  String get veResetAction => 'Resetovat volumetrickou účinnost';

  @override
  String get vehicleReadVinFromCarButton => 'Přečíst VIN z auta';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Přečíst VIN ze spárovaného adaptéru OBD2';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN není dostupný (Mode 09 PID 02 nepodporován na vozidlech před rokem 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Čtení VIN selhalo — zadejte prosím ručně';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Pro automatické čtení VIN nejprve spárujte adaptér OBD2';

  @override
  String get pickerButtonLabel => 'Vybrat z katalogu';

  @override
  String get pickerSearchHint => 'Hledat značku nebo model';

  @override
  String get pickerHelpText => 'Předvyplnit z 50+ podporovaných vozidel';

  @override
  String get pickerEmptyResults => 'Žádné shody';

  @override
  String get pickerCancel => 'Zrušit';

  @override
  String get pickerLoading => 'Načítání katalogu…';

  @override
  String get vinInfoTooltip => 'Co je VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Co je VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Identifikační číslo vozidla (VIN) je 17místný kód jedinečný pro vaše auto. Je vyrazen na podvozku a vytištěn na technickém průkazu.';

  @override
  String get vinInfoSectionWhyTitle => 'Proč se ptáme';

  @override
  String get vinInfoSectionWhyBody =>
      'Dekódování VIN automaticky vyplní zdvihový objem motoru, počet válců, rok výroby, primární typ paliva a hmotnost — ušetří vám hledání technických specifikací. Výpočet průtoku paliva OBD2 tyto hodnoty využívá pro přesné spotřební údaje.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Soukromí';

  @override
  String get vinInfoSectionPrivacyBody =>
      'VIN je uložen pouze lokálně v šifrovaném úložišti aplikace — nikdy není nahrán na servery Sparkilo. Databáze NHTSA vPIC je dotazována s VIN, ale vrací pouze anonymní technické specifikace; NHTSA nepropojuje VIN s osobními údaji. Bez sítě vrátí offline vyhledávání pouze výrobce a zemi.';

  @override
  String get vinInfoSectionWhereTitle => 'Kde ho najít';

  @override
  String get vinInfoSectionWhereBody =>
      'Hledejte skrz čelní sklo v levém dolním rohu na straně řidiče, zkontrolujte nálepku na rámu dveří na straně řidiče při otevřených dveřích, nebo ho přečtěte z technického průkazu.';

  @override
  String get vinInfoDismiss => 'Rozumím';

  @override
  String get vinConfirmPrivacyNote =>
      'VIN jsme vyhledali v bezplatné databázi vozidel NHTSA — nic nebylo odesláno na servery Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Online dekódování VIN';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekódovat VIN přes bezplatnou veřejnou službu NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Po spárování adaptéru je VIN vašeho vozidla přečten lokálně pro identifikaci auta. Povolením se 17místný VIN odešle do bezplatné služby NHTSA vPIC pro vyhledání dalších podrobností (model, zdvihový objem, typ paliva). VIN je jediný odeslaný údaj — žádné jiné informace neopustí zařízení.';

  @override
  String get vehicleDetectedFromVinBadge => '(zjištěno)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Zjištěno z VIN: $summary. Použít?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Použít';

  @override
  String get widgetHelpSectionTitle => 'Widget domovské obrazovky';

  @override
  String get widgetHelpIntro =>
      'Přidejte widget SparKilo na domovskou obrazovku pro zobrazení cen paliva a nabíjení na první pohled.';

  @override
  String get widgetHelpAdd =>
      'Přidejte ho z výběru widgetů ve spouštěči — podržte prázdnou oblast domovské obrazovky, vyberte Widgety a najděte SparKilo.';

  @override
  String get widgetHelpTap =>
      'Klepnutím na stanici ve widgetu ji otevřete v aplikaci. Klepnutím na ikonu obnovení aktualizujete ceny.';

  @override
  String get widgetHelpConfigure =>
      'Na Androidu podržte widget a vyberte Překonfigurovat pro změnu profilu, barvy a obsahu.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Volby níže se použijí na všechny instalované widgety při příští aktualizaci.';

  @override
  String get widgetDefaultsColorLabel => 'Barevné schéma';

  @override
  String get widgetDefaultsVariantLabel => 'Varianta obsahu';

  @override
  String get widgetColorSchemeSystem => 'Systémové';

  @override
  String get widgetColorSchemeLight => 'Světlé';

  @override
  String get widgetColorSchemeDark => 'Tmavé';

  @override
  String get widgetColorSchemeBlue => 'Modré';

  @override
  String get widgetColorSchemeGreen => 'Zelené';

  @override
  String get widgetColorSchemeOrange => 'Oranžové';

  @override
  String get widgetVariantDefault => 'Pouze aktuální cena';

  @override
  String get widgetVariantPredictive => 'Předpověď: nejlepší čas na tankování';

  @override
  String get widgetPredictiveNowPrefix => 'nyní';
}
