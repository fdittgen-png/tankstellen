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
  String get fabRunSearch => 'Spustit vyhledávání';

  @override
  String get routeSearchingChip => 'Prohledávám trasu…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Každých $km km';
  }

  @override
  String get searchCriteriaTitle => 'Kritéria hledání';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Do $km km';
  }

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
  String get freeNoKey => 'Zdarma — klíč není potřeba';

  @override
  String get apiKeyRequired => 'Vyžadován klíč API';

  @override
  String get dataTransparency => 'Transparentnost dat';

  @override
  String get clearCache => 'Vymazat mezipaměť';

  @override
  String stationsFound(int count) {
    return 'Nalezeno $count stanic';
  }

  @override
  String get storageUsage => 'Využití úložiště na tomto zařízení';

  @override
  String get settingsLabel => 'Nastavení';

  @override
  String get total => 'Celkem';

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
  String get deleteAllButton => 'Smazat vše';

  @override
  String get cacheEmpty => 'Mezipaměť je prázdná';

  @override
  String get apiKeyNote =>
      'Bezplatná registrace. Data od vládních agentur pro cenovou transparentnost.';

  @override
  String get apiKeyFormatError =>
      'Neplatný formát — očekáváno UUID (8-4-4-4-12)';

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
  String get searchLocationPlaceholder => 'Adresa, PSČ nebo město';

  @override
  String get configTankSyncConnected => 'Připojeno';

  @override
  String get configTankSyncDisabled => 'Zakázáno';

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
  String profileSwitchedTo(String profile) {
    return 'Přepnuto na $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name byl vytvořen';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Profil pro zemi $country již existuje — místo toho ho upravte.';
  }

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
  String get evPriceFree => 'Zdarma';

  @override
  String get evPricePayAtLocation => 'Platba na místě';

  @override
  String get evPriceMembership => 'Vyžadováno členství';

  @override
  String get evPriceIndicative => 'Orientační cena';

  @override
  String get evPriceDeclaredByOperator =>
      'Orientační cena uvedená provozovatelem — ověřte na místě';

  @override
  String get evPriceFranceAttribution =>
      'Ceny: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Ceny podle nejlepšího úsilí z OpenChargeMap — řídké a mohou být neúplné.';

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
  String get edit => 'Upravit';

  @override
  String get fuelPricesApiKey => 'Klíč API cen paliv';

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
  String get noStationsAlongThisRoute =>
      'Podél této trasy nebyly nalezeny žádné stanice.';

  @override
  String get fuelCostCalculator => 'Kalkulačka nákladů na palivo';

  @override
  String get distanceKm => 'Vzdálenost (km)';

  @override
  String get tripCost => 'Náklady na cestu';

  @override
  String get fuelNeeded => 'Potřebné palivo';

  @override
  String get totalCost => 'Celkové náklady';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Vzdálenost ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Spotřeba ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Cena paliva ($unit)';
  }

  @override
  String get calculatorUseMine => 'Použít';

  @override
  String get calculatorApplied => 'Použito';

  @override
  String get tripDetails => 'Podrobnosti jízdy';

  @override
  String get calculatorRoundTrip => 'Zpáteční cesta';

  @override
  String get roundTripTotal => 'Zpáteční cesta';

  @override
  String get costPerDistance => 'Náklady na km';

  @override
  String get costPerMonth => 'Náklady na měsíc';

  @override
  String get calculatorEstimateMonthly => 'Odhadnout měsíční náklady';

  @override
  String get calculatorTripsPerMonth => 'Jízdy za měsíc';

  @override
  String get calculatorTripsPerMonthHint => 'např. 20';

  @override
  String get calculatorReset => 'Resetovat';

  @override
  String get calculatorResultPlaceholder =>
      'Vyplňte vzdálenost, spotřebu a cenu paliva pro zobrazení nákladů na jízdu';

  @override
  String get priceHistory => 'Historie cen';

  @override
  String get favoritesDataCache => 'Data oblíbených';

  @override
  String get citySearchCache => 'Hledání města';

  @override
  String get noPriceHistory => 'Zatím žádná historie cen';

  @override
  String get noStatistics => 'Žádné statistiky k dispozici';

  @override
  String get showAllFuelTypes => 'Zobrazit všechny typy paliv';

  @override
  String get connected => 'Připojeno';

  @override
  String get disconnectTankSync => 'Odpojit TankSync';

  @override
  String get viewMyData => 'Zobrazit moje data';

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
  String get gdprContinueAll => 'Pokračovat se vším';

  @override
  String get gdprContinueSelected => 'Pokračovat s vybraným';

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
  String get privacySyncMode => 'Režim synchronizace';

  @override
  String get privacySyncUserId => 'ID uživatele';

  @override
  String get privacySyncDescription =>
      'Když je synchronizace povolena, oblíbené, upozornění, ignorované stanice a hodnocení jsou také uloženy na serveru TankSync.';

  @override
  String get privacyExportSuccess => 'Data exportována do schránky';

  @override
  String get privacyExportCsvSuccess => 'Data CSV exportována do schránky';

  @override
  String get savedToDownloadsFolder => 'Uloženo do složky Stažené';

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
  String get voiceAnnouncementProximityRadius => 'Poloměr oznámení';

  @override
  String get voiceAnnouncementCooldown => 'Interval opakování';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximální cena';

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
  String get obdPermissionDenied =>
      'Udělte oprávnění Bluetooth v nastavení systému';

  @override
  String get obdPickerTitle => 'Vybrat adaptér OBD2';

  @override
  String get obdPickerScanning => 'Hledání adaptérů…';

  @override
  String get obdPickerConnecting => 'Připojování…';

  @override
  String get tripSummaryTitle => 'Přehled cesty';

  @override
  String get tripMetricDistance => 'Vzdálenost';

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
  String get vehicleBaselineShowDetails => 'Zobrazit přehled podle situací';

  @override
  String get vehicleBaselineHideDetails => 'Skrýt přehled podle situací';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Dosud nezjištěno: $situations. Tyto jízdní situace zatím mají 0 vzorků, základní hodnota je neúplná.';
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
  String get obd2StatusPermissionDenied =>
      'Adaptér OBD2: potřebné oprávnění Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Připraveno k nahrávání cesty.';

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
  String get situationColdStart => 'Studený start';

  @override
  String get situationSustainedLoad => 'Trvalé zatížení / tažení';

  @override
  String get situationPartialDecel => 'Volné vedení (výbeh)';

  @override
  String get situationHardAccel => 'Prudké zrychlení';

  @override
  String get situationFuelCut => 'Odříznutí paliva — výběh';

  @override
  String get tripSaveRecording => 'Uložit cestu';

  @override
  String get tripSummaryAutoSaved => 'Jízda uložena automaticky';

  @override
  String get tripSummaryDone => 'Hotovo';

  @override
  String get tripSummaryDelete => 'Smazat tuto jízdu';

  @override
  String get vehicleFuelNotSet => 'Nenastaveno';

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
  String get vehiclePowerLabel => 'Výkon motoru (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps k';
  }

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
  String get evStatusAvailable => 'Dostupné';

  @override
  String get evStatusOccupied => 'Obsazeno';

  @override
  String get evStatusOutOfOrder => 'Mimo provoz';

  @override
  String get evStatusPartial => 'Částečně dostupné';

  @override
  String get openOnlyFilter => 'Pouze otevřené';

  @override
  String get saveAsDefaults => 'Uložit jako výchozí';

  @override
  String get criteriaSavedToProfile => 'Uloženo jako výchozí';

  @override
  String get updatingFavorites => 'Aktualizace oblíbených...';

  @override
  String get fetchingLatestPrices => 'Načítání nejnovějších cen';

  @override
  String get noDataAvailable => 'Žádná data';

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
  String get sectionPrivacyData => 'Soukromí a data';

  @override
  String get sectionAdvancedDeveloper => 'Pokročilé a vývojář';

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
  String get minimalDriveBehaviour => 'Styl jízdy';

  @override
  String get coachingShiftUp => 'Zařadit vyšší';

  @override
  String get coachingShiftDown => 'Zařadit nižší';

  @override
  String get coachingEasePedal => 'Uberte plyn';

  @override
  String get coachingVoiceHardAcceleration => 'Zlehčete na akcelerátoru';

  @override
  String get coachingVoiceHarshBraking => 'Zkuste brzdit plynuleji';

  @override
  String get coachingVoiceShiftUp =>
      'Přeřaďte na vyšší převodový stupeň a ušetřete palivo';

  @override
  String get coachingVoiceShiftDown =>
      'Přeřaďte na nižší stupeň, motor se přetěžuje';

  @override
  String get coachingVoiceEasePedal =>
      'Uvolněte pedál a snižte spotřebu paliva';

  @override
  String get coachingVoiceLiftOff =>
      'Sundejte nohu z plynu a nechte auto jet setrvačností';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Dívejte se dál dopředu a dříve uvolňujte plyn';

  @override
  String get coachingVoiceSmoothAccel => 'Přidávejte plyn plynuleji';

  @override
  String get coachingVoiceSharpCorner => 'Projíždějte zatáčky o něco plynuleji';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'To bylo velmi prudké brzdění — držte větší odstup';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Velmi prudké zrychlení — to opravdu spaluje palivo';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Velmi ostrá zatáčka — pomalu dovnitř, plynule ven';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount prudkých manévrů.',
      few: '$harshCount prudké manévry.',
      one: 'Jeden prudký manévr.',
      zero: 'Hezky plynule — žádné prudké manévry.',
    );
    return 'Jízda uložena: $distanceKm kilometrů, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litru na 100 kilometrů';
  }

  @override
  String get voiceCoachingSettingTitle => 'Hlasový koučink při jízdě';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Při jízdě dostávejte hlasové tipy — prudká akcelerace, tvrdé brzdění a rady k řazení';

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
  String get tankSyncSchemaOutdatedTitle =>
      'Cloudová databáze potřebuje aktualizaci';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Vaše vlastní hostované schéma TankSync je zastaralé — některá data se nemohou synchronizovat. Otevřete průvodce synchronizací a spusťte aktualizační SQL ve svém projektu Supabase.';

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
  String get syncSchemaOutdated =>
      'Vaše schéma TankSync je zastaralé — spusťte znovu níže uvedený instalační SQL, aby se zapnuly nejnovější synchronizované funkce.';

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
      'Sdílená databáze provozovaná vývojářem — níže vidíte, co se synchronizuje';

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
  String serviceReminderDueNowBody(String label) {
    return '$label je právě na řadě.';
  }

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
  String get obd2GpsDegradedBannerTitle =>
      'Záznam přes GPS — OBD2 se připojuje';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Záznam pomocí GPS — čekání na adaptér OBD2';

  @override
  String get alertsStationSectionTitle => 'Upozornění na stanice';

  @override
  String get alertsStationAdd => 'Přidat upozornění na stanici';

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
  String radiusAlertDeleted(String name) {
    return 'Polohové upozornění \"$name\" smazáno';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 připojeno: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Spárovat adaptér OBD2';

  @override
  String get fillUpSavedSnackbar => 'Tankování uloženo';

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
  String get obd2ErrorEngineOff =>
      'Z vozidla nepřicházejí žádná data — nastartujte motor a zkuste to znovu.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adaptér OBD2 odeslal nerozpoznanou odpověď. Možná není kompatibilní — zkuste jiný adaptér.';

  @override
  String get obd2ErrorDisconnected =>
      'Adaptér OBD2 se odpojil. Připojte se znovu a zkuste to znovu.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adaptér vyžaduje párování Bluetooth. Odpojte adaptér, znovu jej zapojte a do 5 minut to zkuste znovu.';

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
  String alertsLastChecked(String when) {
    return 'Naposledy zkontrolováno: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Ceny zatím nebyly na pozadí zkontrolovány';

  @override
  String get alertsIosBestEffortNote =>
      'Na iPhonu se upozornění kontrolují podle možností: o tom, kdy smí aplikace kontrolovat ceny na pozadí, rozhoduje iOS, takže upozornění může přijít pozdě nebo občas vůbec. Otevření aplikace vždy spustí novou kontrolu.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Cílová cena ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Práh ($currency/L)';
  }

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
  String fuelStationRadarProximity(int percent) {
    return 'Blízkost $percent%';
  }

  @override
  String get pipTapToRestore => 'Klepnutím otevřete celou aplikaci';

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
  String get authLinkEmailTitle => 'Propojit e-mail';

  @override
  String get authLinkEmailSubtitle =>
      'Propojte e-mail, aby se vaše data synchronizovala mezi zařízeními. Současné oblíbené položky a jízdy zůstanou na tomto účtu.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Používáte účet hosta ($idPrefix…). Propojte e-mail, aby se vaše oblíbené položky a jízdy synchronizovaly s ostatními zařízeními.';
  }

  @override
  String get authConfirmationPending =>
      'Téměř hotovo — zkontrolujte e-mail a klikněte na odkaz pro dokončení propojení. Vaše data jsou na tomto účtu již uložena.';

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
  String get aclWakeNotificationTitle => 'Auto připojeno';

  @override
  String get aclWakeNotificationBody =>
      'Klepnutím otevřete Sparkilo — záznam jízdy může začít.';

  @override
  String get exportBackupReady => 'Záloha připravena — vyberte cíl';

  @override
  String get exportBackupFailed => 'Export zálohy selhal — zkuste to znovu';

  @override
  String get backupExportProgress => 'Exportuji vaši zálohu…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Uloženo do Stažené jako $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Obnovit zálohu';

  @override
  String get restoreBackupDialogBody =>
      'Sloučení přidá a aktualizuje záznamy ze zálohy a zachová vše, co je již na tomto zařízení. Nahrazení nejprve smaže všechna aktuální data a poté obnoví pouze zálohu — tuto akci nelze vrátit zpět.';

  @override
  String get restoreBackupMergeAction => 'Sloučit';

  @override
  String get restoreBackupReplaceAction => 'Nahradit vše';

  @override
  String get restoreBackupEmpty =>
      'Záloha obnovena — neobsahovala žádné záznamy';

  @override
  String get restoreBackupCorrupt =>
      'Obnova se nezdařila — tento soubor není platná záloha Tankstellen';

  @override
  String get restoreBackupFailed =>
      'Obnova se nezdařila — soubor nebylo možné přečíst';

  @override
  String get backupImportProgress => 'Obnova zálohy…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Sloučeno $vehicles vozidel, $fillUps tankování, $trips jízd, $chargingLogs záznamů nabíjení';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Všechna data nahrazena $vehicles vozidly, $fillUps tankováními, $trips jízdami, $chargingLogs záznamy nabíjení';
  }

  @override
  String get brokenMapChipDisclaimer => 'Odečty MAP jsou podezřelé';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Snímač MAP čte nesprávně — odečty paliva mohou být o 50–80 % nižší. Zkuste jiný adaptér.';

  @override
  String get brokenMapBannerHardDisable =>
      'Snímač MAP není spolehlivý. Zobrazuji průměry tankování místo živého průtoku paliva.';

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
  String get calibrationDirectFuelRateNote =>
      'Toto vozidlo hlásí spotřebu paliva přímo (PID 5E), takže kalibrace objemové účinnosti se nepoužívá — vaše spotřeba je měřená, ne modelovaná.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vaše $makeModel je označena jako diesel, ale odpovídá katalogovému záznamu pro benzin. Klepnutím aktualizujte.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aktualizovat';

  @override
  String get catalogResetAction => 'Obnovit z databáze vozidel';

  @override
  String get catalogResetConfirmTitle => 'Obnovit z databáze vozidel?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Nahradí objem nádrže, výkon motoru a zdvihový objem tohoto vozidla hodnotami z databáze pro $vehicle. Ostatní pole a historie tankování zůstanou beze změny.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'V databázi vozidel není pro toto vozidlo žádný odpovídající záznam.';

  @override
  String get catalogResetDoneSnackbar => 'Údaje o vozidle obnoveny z databáze.';

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
  String get confirmDeleteTitle => 'Smazat?';

  @override
  String get confirmDeleteBody => 'Opravdu to chcete smazat?';

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
  String get consoGroupVehicles => 'Vozidla';

  @override
  String get consoGroupCoaching => 'Coaching při jízdě';

  @override
  String get consoGroupRewards => 'Odměny a úspory';

  @override
  String get consoGroupTroubleshooting => 'Řešení problémů';

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
  String get moreActionsTooltip => 'Více';

  @override
  String get exportBackupMenuLabel => 'Exportovat zálohu';

  @override
  String get restoreBackupMenuLabel => 'Obnovit zálohu';

  @override
  String get carbonDashboardMenuLabel => 'Uhlíkový přehled';

  @override
  String get settingsMenuLabel => 'Nastavení';

  @override
  String get consumptionStatsPageTitle => 'Statistiky spotřeby';

  @override
  String get consumptionStatsComparisonTitle => 'Tento měsíc vs. minulý měsíc';

  @override
  String get consumptionStatsTrendsTitle => 'Vývoj v čase';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Zaznamenejte tankování alespoň ve dvou měsících pro srovnání.';

  @override
  String get consumptionStatsPricePerLiter => 'Prům. cena/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litry za měsíc';

  @override
  String get consumptionStatsChartSpend => 'Výdaje za měsíc';

  @override
  String get consumptionStatsChartPricePerLiter => 'Cena za litr';

  @override
  String get consumptionStatsChartConsumption => 'L/100 km za měsíc';

  @override
  String get fuelCompareSectionTitle => 'Náklady na jízdu podle paliva';

  @override
  String get fuelComparePricePerLitre => 'Zaplaceno za litr';

  @override
  String get fuelCompareCostPer100km => 'Náklady na 100 km';

  @override
  String get fuelCompareDistance => 'Naměřená vzdálenost';

  @override
  String get fuelCompareLitres => 'Spotřebované litry';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner je vaše nejlevnější palivo na ježdění';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser stojí o $amount více na 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel porazí $rival pod $price za litr';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Bod zvratu se počítá z naměřené spotřeby každého paliva, takže se posouvá spolu s vaší jízdou.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litry a náklady si mohou odporovat: palivo může spotřebovat méně litrů na 100 km a přesto stát více za kilometr, protože se liší cena za litr. Rozhodují náklady na kilometr.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plných nádrží',
      one: 'jedné plné nádrže',
    );
    return 'Předběžné — na základě $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plných nádrží',
      one: 'jedné plné nádrže',
    );
    return 'Na základě $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 na 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner je vaše palivo s nejnižšími emisemi';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel stojí o $money více na 1000 km, ale vypustí o $co2 méně CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel je zároveň levnější i čistší než $rival';
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
    return 'Vašich $distance na $fuel vypustilo $actual místo $alternative na $rival — $saved ušetřeno';
  }

  @override
  String get fuelCompareCo2Source =>
      'Hodnoty CO2 jsou odhady „od zdroje ke kolu“ (EU JEC WTW v5) použité na vaši naměřenou spotřebu — pro orientaci, nikoli certifikované účetnictví.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 se zobrazuje jen u čistých paliv: emisní faktor směsi závisí na jejím složení, které tento řádek nezaznamenává.';

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
    return 'Korekce: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Nahlásit obsah';

  @override
  String get contentModerationBlockAction => 'Blokovat autora';

  @override
  String get contentModerationReportDialogTitle => 'Nahlásit tento obsah?';

  @override
  String get contentModerationReportDialogBody =>
      'Hlášení se odešle na váš server TankSync ke kontrole a tento obsah bude na vašem zařízení skryt.';

  @override
  String get contentModerationReportConfirmButton => 'Nahlásit';

  @override
  String get contentModerationBlockDialogTitle => 'Blokovat tohoto autora?';

  @override
  String get contentModerationBlockDialogBody =>
      'Vše, co s vámi tento účet sdílí, bude na tomto zařízení skryto.';

  @override
  String get contentModerationBlockConfirmButton => 'Blokovat';

  @override
  String get contentModerationReportedSnack =>
      'Hlášení odesláno — obsah skryt.';

  @override
  String get contentModerationReportFailedSnack =>
      'Hlášení se nepodařilo odeslat. Zkuste to znovu.';

  @override
  String get contentModerationBlockedSnack =>
      'Autor blokován — jeho sdílený obsah je skryt.';

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
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stanice v $country za $km km — o €$price/L levnější';
  }

  @override
  String get crossBorderTapToSwitch => 'Klepnutím přepnout zemi';

  @override
  String get crossBorderDismissTooltip => 'Zavřít';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Otevřít zdroj dat $source ($license) v prohlížeči';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© přispěvatelé $brand';
  }

  @override
  String get developerToolsSectionTitle => 'Nástroje pro vývojáře';

  @override
  String get dataAccessTracerExport => 'Exportovat záznam přístupu k datům';

  @override
  String get dataAccessTracerExportSuccess =>
      'Záznam přístupu k datům uložen do složky Stažené.';

  @override
  String get dataAccessTracerExportFailure =>
      'Záznam přístupu k datům se nepodařilo exportovat.';

  @override
  String get dataAccessTracerEmpty =>
      'Zatím nejsou zaznamenány žádné události přístupu k datům — nejprve vyhledejte nebo otevřete stanice, pak exportujte.';

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
      'Nejprve vyhledejte stanice a pak spusťte testovací upozornění, aby mohlo oznámení otevřít skutečnou stanici.';

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
  String get startupTraceSectionTitle => 'Záznam inicializace při spuštění';

  @override
  String get startupTraceExportButton => 'Exportovat záznam spuštění';

  @override
  String get startupTraceEmpty =>
      'Zatím není zaznamenán žádný záznam spuštění.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Celkem: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Záznam spuštění uložen do složky Stažené.';

  @override
  String get startupTraceExportFailure =>
      'Záznam spuštění se nepodařilo exportovat.';

  @override
  String get distanceSourceOdometer => 'Tachometr';

  @override
  String get distanceSourceOdometerTooltip =>
      'Vzdálenost odečtená z tachometru auta — naměřená referenční hodnota.';

  @override
  String get distanceSourceGps => 'Stopa GPS';

  @override
  String get distanceSourceGpsTooltip =>
      'Vzdálenost sečtená ze zaznamenané stopy GPS — skutečná vzdálenost po silnici.';

  @override
  String get distanceSourceEstimated => 'Odhad';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Vzdálenost integrovaná ze snímače rychlosti — odhad; snímač obvykle mírně nadhodnocuje.';

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
    return 'Plný plyn ($pctTime% jízdy): zbytečně spotřebováno $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Přidávejte plyn pomalu — jemné 70 % sešlápnutí vás rozjede na podstatně méně paliva.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Bohatá směs pod zatížením ($pctTime% jízdy): zbytečně spotřebováno $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Silné trvalé zatížení způsobuje přeobohacení směsi — přeřazujte dříve a ubírejte plyn při dlouhých stoupáních, aby směs zůstala chudá.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Stoupání s $gradePercent% sklonem ($pctTime% jízdy): zbytečně spotřebováno $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Nabírejte hybnost před kopcem a plynně přidávejte plyn — prudké přidání na stoupání spaluje více paliva.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count zastavení a opětovných rozjezdů: zbytečně spotřebováno $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticipujte provoz a kolejte k zastavení, abyste spíše dojeli než startovali — rozjezd z klidu je nejnáročnější část stop-and-go jízdy.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Směs se zdá mírně chudá — motor přidával palivo (korekce $pctTrim %), aby to vyrovnal';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Směs se zdá chudá — motor trvale přidával velké množství paliva ($pctTrim %), možná neefektivita';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Směs se zdá mírně bohatá — motor ubíral palivo (korekce $pctTrim %), aby to vyrovnal';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Směs se zdá bohatá — motor trvale ubíral velké množství paliva ($pctTrim %), možná neefektivita';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Motor běžel při zatížení na bohatou směs ($pctShare % zahřáté jízdy) — možné plýtvání palivem';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristický signál stavu, ne diagnóza';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Trvalá korekce směrem k chudé směsi může znamenat přisávání vzduchu v sání, slabé zásobování palivem nebo stárnoucí snímač. Pokud se spotřeba nebo chod zhorší, diagnostika v servisu to může potvrdit.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Trvalá korekce směrem k bohaté směsi může znamenat netěsný vstřikovač, vysoký tlak paliva nebo snímač, který nadhodnocuje. Pokud se spotřeba nebo chod zhorší, diagnostika v servisu to může potvrdit.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Bohatá směs při vysokém zatížení spaluje palivo navíc. Řaďte nahoru dříve a při dlouhém zrychlování uberte plyn, aby motor zůstal blízko stechiometrické směsi.';

  @override
  String get lessonTransportTitle =>
      'Po většinu této jízdy chybí data z motoru';

  @override
  String get lessonTransportAdvice =>
      'Motor nehlásil téměř po celou vzdálenost žádnou aktivitu. Buď datový tok OBD2 v půli jízdy selhal, nebo bylo auto přemístěno bez jízdy — údaj o spotřebě je nespolehlivý a ze statistik je vyloučen.';

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
  String get drivingScoreClassVeryGood => 'Velmi dobrý';

  @override
  String get drivingScoreClassGood => 'Dobrý';

  @override
  String get drivingScoreClassAverage => 'Průměrný';

  @override
  String get drivingScoreClassBad => 'Třeba zlepšit';

  @override
  String get drivingScorePenaltyLugging => 'Přetěžování motoru';

  @override
  String get drivingScorePenaltySmoothness => 'Trhavá jízda';

  @override
  String get drivingScorePenaltyHighSpeed => 'Vysoká rychlost';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresivní pedál';

  @override
  String get drivingScorePenaltyLambda => 'Bohatá směs';

  @override
  String get gpsKpiCardTitle => 'Efektivita GPS';

  @override
  String get gpsKpiRpa => 'Pozitivní zrychlení (RPA)';

  @override
  String get gpsKpiPke => 'Poptávka kinetické energie (PKE)';

  @override
  String get gpsKpiVapos => 'Intenzita zrychlení (VAPOS)';

  @override
  String get gpsKpiCoast => 'Podíl volného vedení';

  @override
  String get gpsKpiClimbEnergy => 'Energie stoupání';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct oproti vašemu efektivnímu základu';
  }

  @override
  String get drivingTraceCardTitle => 'Stopa analýzy jízdy (dev)';

  @override
  String get drivingTraceCardBody =>
      'Exportujte GPS KPI, skóre a lekce z této jízdy jako JSON, napište do pole komentáře, jak jízda skutečně probíhala, a sdílejte zpět, aby bylo možné kalibrovat prahy stylu jízdy podle skutečných jízd.';

  @override
  String get drivingTraceExportAction => 'Exportovat stopu analýzy';

  @override
  String get drivingTraceExported =>
      'Stopa analýzy uložena do složky Stažené — přidejte svůj verdikt do pole komentáře a sdílejte zpět.';

  @override
  String get drivingTraceExportFailed =>
      'Stopu analýzy se nepodařilo exportovat.';

  @override
  String get minimalDriveTripAverage => 'Průměr jízdy';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Jízda ve vysokých otáčkách ($pctTime % jízdy): dřívější přeřazení nahoru by mohlo ušetřit $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Při ustálené jízdě řaďte nahoru dříve — stejná rychlost v nižších otáčkách spaluje znatelně méně.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Dojezd s odpojením paliva ($pctTime % jízdy): ušetřeno asi $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Dobře předvídáno — včasné ubrání plynu nechá motor při dojezdu zcela odpojit palivo.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Kam šlo vaše palivo';

  @override
  String get fuelBreakdownIdle => 'Volnoběh';

  @override
  String get fuelBreakdownHarshAccel => 'Prudká zrychlení';

  @override
  String get fuelBreakdownHighRpmCruise => 'Jízda ve vysokých otáčkách';

  @override
  String get fuelBreakdownCoastingSaved => 'Ušetřeno dojezdem';

  @override
  String get fuelBreakdownEfficient => 'Běžná jízda';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Volnoběh už nějakou dobu — vypnutí motoru šetří palivo';

  @override
  String get ecoNudgeHarshAccel =>
      'Prudké zrychlení — jemnější noha na plynu šetří palivo';

  @override
  String get ecoNudgeHighRpm =>
      'Vysoké otáčky při ustálené jízdě — dřívější přeřazení nahoru šetří palivo';

  @override
  String get obd2CoverageNoneNote =>
      'Během této jízdy nedorazila z adaptéru OBD2 žádná data z motoru — údaje o palivu jsou odhady z GPS.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Data z motoru skončila v $percent % jízdy (spojení přerušeno) — údaje o palivu poté jsou odhady z GPS.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Data z motoru pokryla jen $percent % této jízdy — mezery používají odhady z GPS.';
  }

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
  String get featureLabel_approachOverlay => 'Radar čerpacích stanic';

  @override
  String get featureDescription_approachOverlay =>
      'Plovoucí dlaždice jízdy se změní na živý Radar čerpacích stanic — při přiblížení ke stanici se přebarví podle druhu paliva a zobrazí cenu.';

  @override
  String get featureLabel_voiceAnnouncements => 'Hlasová oznámení';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Při jízdě nahlas oznamuje okolní levné čerpací stanice, abyste mohli sledovat cestu.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Nejprve aktivujte Radar čerpacích stanic';

  @override
  String get featureGroupTitle_finding => 'Hledání a mapa';

  @override
  String get featureGroupDescription_finding =>
      'Kde natankovat nebo dobít — hledání, mapa, trasy.';

  @override
  String get featureGroupTitle_prices => 'Ceny a upozornění';

  @override
  String get featureGroupDescription_prices =>
      'Poklesy cen, historie a hlášení.';

  @override
  String get featureGroupTitle_radar => 'Radar čerpacích stanic';

  @override
  String get featureGroupDescription_radar =>
      'Živá upozornění na ceny při jízdě.';

  @override
  String get featureGroupTitle_sync => 'Synchronizace a záloha';

  @override
  String get featureGroupDescription_sync =>
      'Uchovejte data napříč zařízeními.';

  @override
  String get featureGroupTitle_input => 'Zadávání a skenování';

  @override
  String get featureGroupDescription_input =>
      'Pomůcky pro zaznamenávání tankování.';

  @override
  String get featureGroupTitle_developer => 'Vývojář a experimentální';

  @override
  String get featureGroupDescription_developer =>
      'Nástroje pro pokročilé uživatele a přispěvatele.';

  @override
  String get featureLabel_voiceFeedback =>
      'Hlasová zpětná vazba (syntéza řeči)';

  @override
  String get featureDescription_voiceFeedback =>
      'Hlavní vypínač všech hlasových výstupů — hlasového kouče jízdy a hlášení stanic. Když je vypnutý, aplikace nikdy nespustí syntézu řeči.';

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
  String get fillUpMultiFuelHint =>
      'Toto vozidlo může jezdit na různá paliva — zapište to, které jste skutečně natankovali';

  @override
  String get fillUpGuidanceTitle => 'Nejlepší čas na tankování';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Aktuální cena patří k nejlevnějším za posledních $days dní — vhodný čas k tankování.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Ceny jsou blízko svého ${days}denního maxima. Obvykle jsou levnější $window — zvažte vyčkání.';
  }

  @override
  String get fillUpGuidanceFillSoon => 'Ceny rostou — zvažte brzy natankovat.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Dnešní cena se pohybuje kolem průměru za $days dní.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Správným načasováním tankování byste mohli ušetřit asi $amount/L.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na základě $count záznamů cen',
      one: 'Na základě 1 záznamu ceny',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'v $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'jindy';

  @override
  String get fillUpGuidanceWeekday1 => 'v pondělí';

  @override
  String get fillUpGuidanceWeekday2 => 'v úterý';

  @override
  String get fillUpGuidanceWeekday3 => 've středu';

  @override
  String get fillUpGuidanceWeekday4 => 've čtvrtek';

  @override
  String get fillUpGuidanceWeekday5 => 'v pátek';

  @override
  String get fillUpGuidanceWeekday6 => 'v sobotu';

  @override
  String get fillUpGuidanceWeekday7 => 'v neděli';

  @override
  String get fillUpGuidancePartEarlyMorning => 'brzy ráno';

  @override
  String get fillUpGuidancePartMorning => 'dopoledne';

  @override
  String get fillUpGuidancePartAfternoon => 'odpoledne';

  @override
  String get fillUpGuidancePartEvening => 'večer';

  @override
  String get fillUpGuidancePartNight => 'v noci';

  @override
  String get fillUpOdometerFromCarJustNow => 'Z vašeho vozu · právě teď';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Z vašeho vozu · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Odhad z posledního údaje z vozu plus vzdálenost ujetá od té doby ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Vložit text';

  @override
  String get pasteReceiptDialogTitle => 'Vložit text účtenky';

  @override
  String get pasteReceiptDialogHint =>
      'Vložte text účtenky za palivo — e-mail, SMS nebo sdílené PDF. Litry, cena za litr, druh paliva, celková částka a stanice se přečtou v zařízení a předvyplní formulář. Nic se neodesílá na server.';

  @override
  String get pasteReceiptFieldHint => 'Text účtenky';

  @override
  String get pasteReceiptParseAction => 'Předvyplnit';

  @override
  String get pasteReceiptNoData =>
      'Z tohoto textu se nepodařilo přečíst žádné údaje o palivu — zkontrolujte, že jde o účtenku za palivo, a zkuste to znovu.';

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
  String get badScanReportTitleReceipt => 'Nahlásit chybu skenování — Účtenka';

  @override
  String get badScanReportHint =>
      'Sdílíme fotografii účtenky a obě sady hodnot, aby se příští verze naučila toto rozvržení.';

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
  String get fillUpWarningDialogTitle => 'Zkontrolujte toto tankování';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Vybrali jste $chosenFuel, ale toto vozidlo jezdí na $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Stav tachometru $entered km je nižší než $previous km z předchozího tankování — vzdálenost nemůže jít zpět.';
  }

  @override
  String get fillUpWarningGoBack => 'Vrátit se a opravit';

  @override
  String get fillUpWarningSaveAnyway => 'Přesto uložit';

  @override
  String get fillUpSectionWhatTitle => 'Co jste natankovali';

  @override
  String get fillUpSectionWhatSubtitle => 'Palivo, množství, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kde jste byli';

  @override
  String get fillUpSectionWhereSubtitle => 'Stanice, tachometr, poznámky';

  @override
  String get fillUpImportReceiptLabel => 'Účtenka';

  @override
  String get fillUpPricePerLiterLabel => 'Cena za litr';

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
  String get profileSectionDisplayStations => 'Zobrazení a stanice';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get fuelEfficiencyCardTitle => 'Náklady na kilometr podle paliva';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Na kterou směs paliva se skutečně jezdí nejlevněji';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Nejlevnější na km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Čisté';

  @override
  String get fuelEfficiencyMixBadge => 'Směs';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Převážně $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Náklady/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Celkem utraceno';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tankování',
      few: '$count tankování',
      one: '1 tankování',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plných nádrží',
      few: '$count plné nádrže',
      one: '1 plná nádrž',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Zaznamenejte alespoň dvě plné nádrže na každé složení, aby bylo možné určit nejlevnější.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Nádrže se seskupují podle složení: nádrž je čistá, když jedno palivo tvoří alespoň 85 %, jinak jde o směs.';

  @override
  String get fuelNameE5 => 'Natural 95';

  @override
  String get fuelNameE10 => 'Natural 95 E10';

  @override
  String get fuelNameE98 => 'Natural 98';

  @override
  String get fuelNameDiesel => 'Nafta';

  @override
  String get fuelNameDieselPremium => 'Nafta Premium';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'LPG';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Vodík';

  @override
  String get fuelNameElectric => 'Elektřina';

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
  String gdprPolicyLink(int version) {
    return 'Zásady ochrany osobních údajů (verze $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Souhlas udělen $date · verze zásad $version';
  }

  @override
  String get consentNotRecorded => 'Zatím nebyl zaznamenán žádný souhlas';

  @override
  String serverErasurePartial(String tables) {
    return 'Některá data na serveru se nepodařilo smazat: $tables. Zkuste to znovu nebo kontaktujte vývojáře s tímto seznamem.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Některá místní data se nepodařilo smazat: $steps. Restartujte aplikaci a zkuste to znovu.';
  }

  @override
  String get myCommunityReportsTitle => 'Moje komunitní hlášení';

  @override
  String get myCommunityReportsEmpty => 'Zatím jste neodeslali žádné hlášení';

  @override
  String get deleteReportTooltip => 'Smazat toto hlášení';

  @override
  String get reportDeleted => 'Hlášení smazáno';

  @override
  String get reportDeleteFailed => 'Hlášení se nepodařilo smazat';

  @override
  String get tileProxyToggleTitle =>
      'Načítat mapové dlaždice přes proxy Sparkilo';

  @override
  String get tileProxyToggleSubtitle =>
      'Zapnuto: zobrazený výřez mapy a vaše IP adresa se dostanou na server vývojáře v EU, který dlaždice stáhne z OpenStreetMap. Vypnuto: dlaždice se načítají přímo z tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle => 'Načítat loga značek z internetu';

  @override
  String get remoteLogosToggleSubtitle =>
      'Ve výchozím stavu vypnuto: zobrazují se vestavěné zástupné obrázky. Zapnuto: loga se stahují z logo.clearbit.com, které vidí vaši IP adresu.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName uloženo do Stažené — obsahuje $count souborů';
  }

  @override
  String get privacyExportAllFailed => 'Exportní soubor se nepodařilo zapsat';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Provozuje $operator · Supabase, EU (Frankfurt) · synchronizuje oblíbené, upozornění, vozidla vč. VIN, tankování, hodnocení, hlášení a — pokud to zapnete — jízdy s GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Správcem údajů jste vy — váš vlastní projekt Supabase, my ho nikdy nevidíme';

  @override
  String get syncModeJoinControllerNotice =>
      'Správcem vašich údajů je ten, kdo vlastní sdílenou databázi';

  @override
  String get ugcPublicNoticeTitle => 'Sdíleno s ostatními uživateli';

  @override
  String get ugcPublicNoticeBody =>
      'Toto je uloženo v synchronizační databázi pod vaším pseudonymním ID uživatele. V Komunitě Sparkilo si to může přečíst každý přihlášený uživatel. Kdykoli to můžete smazat v TankSync → Transparentnost dat.';

  @override
  String get blockedAuthorsTitle => 'Blokovaní uživatelé';

  @override
  String get blockedAuthorsDescription =>
      'Obsah sdílený těmito uživateli je na tomto zařízení skrytý. Odblokujte je, abyste ho znovu viděli.';

  @override
  String get blockedAuthorsEmpty => 'Žádní blokovaní uživatelé';

  @override
  String get blockedAuthorsUnblock => 'Odblokovat';

  @override
  String get coachingGpsLiftOff => 'Uvolnit plyn';

  @override
  String get coachingGpsAnticipateBrake => 'Předvídat';

  @override
  String get coachingGpsSmoothAccel => 'Plynulé zrychlení';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Stopa pokrývá $pct % — nejdelší mezera $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Stopa pokrývá $pct % — žádné mezery nezjištěny';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'aplikace na pozadí';

  @override
  String get gpsCoverageAttrOsBatching => 'systém sdružoval polohy do dávek';

  @override
  String get gpsCoverageAttrGateRejected => 'polohy odfiltrovány';

  @override
  String get gpsCoverageAttrDeliveryStall => 'opožděné doručení';

  @override
  String get gpsCoverageAttrSignalLoss => 'ztráta signálu';

  @override
  String get gpsCoverageAttrUnknown => 'neznámá příčina';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Aplikace byla na pozadí bez služby na popředí, takže systém omezil GPS. Nechte během záznamu zapnutou obrazovku, nebo zapněte záznam na pozadí, až bude k dispozici.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Systém doručil polohy pozdě a v dávkách; stopa se doplnila dodatečně, takže se ve skutečnosti ztratilo jen málo dat.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Zašuměné polohy v tomto úseku byly odfiltrovány, aby údaj o vzdálenosti zůstal poctivý.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Polohy byly určeny včas, ale do aplikace dorazily pozdě — telefon byl zaneprázdněn (často opětovné připojování Bluetooth). Příjem byl v pořádku.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Příjem GPS vypadl — obvykle tunel, kryté parkoviště nebo hustá městská zástavba.';

  @override
  String get gpsCoverageHintUnknown =>
      'Tato jízda neobsahuje informace o stavu aplikace během mezery, takže příčinu nelze určit.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'rušení při opětovném připojování OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Mezera se shoduje s opětovným připojováním OBD2 — spojení s adaptérem se obnovovalo, zatímco příjem GPS stál. Oprava spojení s adaptérem opraví i stopu.';

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
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Největší mezera: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Obnoveno';

  @override
  String get gpsLifecyclePaused => 'Pozastaveno';

  @override
  String get gpsLifecycleInactive => 'Neaktivní';

  @override
  String get gpsKpiVerdictGood => 'Úsporná';

  @override
  String get gpsKpiVerdictModerate => 'Průměrná';

  @override
  String get gpsKpiVerdictAggressive => 'Agresivní';

  @override
  String get gpsKpiInterpretationGood =>
      'Plynulá, úsporná jízda — takhle vypadá efektivita.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Celkem běžná jízda — o něco jemnější práce s plynem by ušetřila víc.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energeticky náročná jízda — ubrání plynu a častější dojezd by snížily spotřebu.';

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
      'Odhadnuto GPS (~) — na této jízdě není snímač paliva. Hodnota je modelována z rychlosti a kalibrace vašeho vozidla; přesnost se zlepšuje s rostoucí maticí.';

  @override
  String get gpsRoadUseCardTitle => 'Jak jste využili silnici';

  @override
  String get gpsRoadUseSpeedSection => 'Kde jste strávili čas';

  @override
  String get gpsRoadUseSpeedIdle => 'Stání (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Město (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Silnice (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Rychle (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Jak jste se pohybovali';

  @override
  String get gpsRoadUsePhaseAccel => 'Zrychlování';

  @override
  String get gpsRoadUsePhaseSteady => 'Ustálená rychlost';

  @override
  String get gpsRoadUsePhaseCoast => 'Dojezd';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Hodně dojezdu — nechat auto jet setrvačností místo brzdění šetří palivo. Pěkné.';

  @override
  String get gpsRoadUseSource => 'Z vaší stopy GPS';

  @override
  String get hapticEcoCoachSettingTitle => 'Eko coaching v reálném čase';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Jemná haptika + tip na obrazovce při plném plynu v krouticím režimu';

  @override
  String get hapticEcoCoachSnackBarMessage => 'Mírnit plyn — výběh šetří více';

  @override
  String highwayViaExit(String ref, String km) {
    return 'přes výjezd $ref · +$km km';
  }

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
  String get consentSyncTripsAnonymousHint =>
      'Jízdy se zálohují pod anonymním účtem tohoto zařízení. Přihlaste se e-mailem, abyste se k nim dostali z jiných zařízení.';

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
  String get accelBrakeCardTitle => 'Zrychlení a brzdění';

  @override
  String get accelBrakeHardAccel => 'Prudká zrychlení';

  @override
  String get accelBrakeHardBrake => 'Prudká brzdění';

  @override
  String get accelBrakeSharpCorner => 'Ostré zatáčky';

  @override
  String get accelBrakeSource => 'Ze snímačů pohybu telefonu';

  @override
  String lessonHardBrake(String count) {
    return '$count prudkých brzdění';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Anticipujte zastavení a dříve uvolňujte plyn — prudké brzdění maří palivo vynaložené na rozjezd.';

  @override
  String lessonSharpCornering(String count) {
    return '$count ostrých zatáček';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Zpomalujte před zatáčkou, ne v ní — ostré projíždění zatáčkami ztrácí rychlost, kterou pak musíte znovu dobývat.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Posledních $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Jednotka spotřeby';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Jak se spotřeba paliva zobrazuje v celé aplikaci';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automaticky ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Okno živé spotřeby';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Průměruje živou hodnotu za posledních několik sekund – delší je klidnější, kratší reaguje rychleji';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'odh. $unit';
  }

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
  String get consumptionMonthlyClimbLabel => 'Vystoupáno';

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
  String get obd2DiagnosticsTitle => 'Stav OBD2 komunikace';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops výpadků',
      one: '1 výpadek',
      zero: 'žádný výpadek',
    );
    return '$percent% dokončeno · $duty% vytížení · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adaptér';

  @override
  String get obd2DiagnosticsConnectionSection => 'Životní cyklus připojení';

  @override
  String get obd2DiagnosticsPidSection => 'Výsledky podle PID';

  @override
  String get obd2DiagnosticsReconnectSection =>
      'Telemetrie opětovného připojování';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts pokusů o opětovné připojení · $successes úspěšných · $transitions přechodů · $disconnects klasifikovaných výpadků';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'V této relaci byl aktivován nouzový režim pouze s GPS.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Stav plánovače';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Úplnost';

  @override
  String get obd2DiagnosticsSupportSection => 'Detekované podporované PID';

  @override
  String get obd2DiagnosticsFuelSection => 'Souhrnná palivová úroveň';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protokol $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts pokusů · $successes úspěšných · $drops výpadků · čas připojení p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Opětovná připojení: $silent tichých · $visible viditelných';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz takt · $skips přeskočení tlaku · $demotions degradací';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dynamická vrstva hladoví — RPM / rychlost klesla pod minimální práh správce.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Celkem $percent% · aktivní vytížení $duty%';
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
    return '$supported podporovaných · $unsupported nepodporovaných · $unknown neznámých';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Podezřelých $suspicious z $total vzorků';
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
    return '$pid: $polled dotázáno · $ok ok · $noData ND · $timeout TO · $error chyb · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Přepis inicializace donglu';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokol $protocol · $start · firmware $firmware · $tier · $pids PID';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'teplý';

  @override
  String get obd2DiagnosticsInitCold => 'studený';

  @override
  String get obd2DiagnosticsEmpty =>
      'Zatím žádná OBD2 relace — připojte adaptér a zaznamenejte jízdu s aktivovaným vývojářským režimem.';

  @override
  String get obd2DiagnosticsExplain =>
      'Zachyceno během záznamu pro ladění komunikace donglu s aplikací — sbíráno pouze ve vývojářském režimu.';

  @override
  String get obd2HealthScreenTitle => 'Stav OBD2 komunikace';

  @override
  String get obd2HealthNavLabel => 'Stav OBD2 komunikace';

  @override
  String get obd2HealthLiveSection => 'Živá relace';

  @override
  String get obd2HealthHistorySection => 'Nedávné relace';

  @override
  String get obd2HealthDownloadJson => 'Stáhnout jako JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Stáhnout pouze přepis inicializace';

  @override
  String get obd2HealthDownloadError =>
      'Diagnostický soubor se nepodařilo uložit';

  @override
  String get obd2TestAdapterLabel => 'Adaptér k otestování';

  @override
  String get obd2TestAdapterScanOption => 'Vyhledat adaptér';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Připojení k $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Spustit test adaptéru';

  @override
  String get obd2TestRunButton => 'Spustit test adaptéru';

  @override
  String get obd2TestRunPassed => 'Test adaptéru prošel';

  @override
  String get obd2TestRunFailed => 'Test adaptéru selhal';

  @override
  String get obd2TestRunEngineOff =>
      'Adaptér OK — motor vypnutý; nastartujte motor pro čtení živých dat';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed z $total kroků OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Před spuštěním testu adaptéru zastavte aktivní záznam.';

  @override
  String get obd2TestStepScan => 'Skenovat adaptér';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth telefonu';

  @override
  String get obd2TestStepConnect => 'Připojit a inicializovat';

  @override
  String get obd2TestStepInfo => 'Informace o adaptéru';

  @override
  String get obd2TestStepSupportedPids => 'Podporované PID';

  @override
  String get obd2TestStepProtocol => 'Protokol vozidla';

  @override
  String get obd2TestStepSampleReads => 'Zkušební čtení';

  @override
  String get obd2TestStepSoak => 'Dlouhodobé dotazování';

  @override
  String get obd2TestStepReconnect => 'Test opětovného připojení';

  @override
  String get obd2TestStepDisconnect => 'Odpojit';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Vypršel časový limit';

  @override
  String get obd2TestStatusGarbage => 'Nečitelná odpověď';

  @override
  String get obd2TestStatusNoResponse => 'Žádná odpověď';

  @override
  String get obd2TestStatusFail => 'Selhalo';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'neznámý — výchozí BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Poslední pokusy o připojení';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Zatím nejsou zaznamenány žádné pokusy o připojení.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Stáhnout záznam připojení';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Stáhnout všechny záznamy připojení';

  @override
  String get obd2HealthConnectOrigin => 'Původ';

  @override
  String get obd2HealthConnectTransport => 'Přenos';

  @override
  String get obd2HealthConnectOutcome => 'Výsledek';

  @override
  String get obd2HealthConnectScanList => 'Nalezená zařízení';

  @override
  String get obd2HealthConnectSteps => 'Kroky';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Neznámý adaptér';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Relace zaznamenána · $samples vzorků motoru · $percent% pokrytí';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'Co tato jízda zaznamenala';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples z $total vzorků obsahovalo data motoru ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adaptér: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Domluva protokolu: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Relace ukončena: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Délka relace: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Údaje o spotřebě pocházejí z adaptéru, nikoli z odhadů podle GPS.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Podrobnosti komunikace podle PID nebyly u této jízdy zachyceny. Chcete-li je sbírat, zapněte před nahráváním vývojářský režim.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nelze se připojit k \'$adapterName\' — vyberte jiný adaptér';
  }

  @override
  String get obd2PickerOtherDevices => 'Další zařízení Bluetooth';

  @override
  String get obd2PickerTapToTry => 'Nerozpoznáno — klepnutím vyzkoušet';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone funguje pouze s adaptéry Bluetooth LE. Adaptér podporující jen Classic (např. vLinker BM, Konnwei KW902) je nutné použít na Androidu.';

  @override
  String get obd2PairingConfirmHint => 'Potvrďte žádost o párování v telefonu';

  @override
  String get obd2ScanEmptyTitle => 'Adaptér nenalezen';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth je zapnutý a oprávnění udělena. Ujistěte se, že je adaptér zapojen do zásuvky OBD2 a zapalování je zapnuté, a vyhledejte znovu.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Toto zařízení nemá hardware Bluetooth Low Energy, takže se nemůže připojit k adaptéru OBD2.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth je vypnutý. Zapněte jej, aby bylo možné vyhledat adaptér.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo potřebuje oprávnění Bluetooth, aby našlo váš adaptér.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Oprávnění Bluetooth bylo trvale zamítnuto. Udělte je v nastavení systému, aby bylo možné vyhledat adaptér.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Služby určování polohy jsou na tomto zařízení vypnuté. Android je pro vyhledávání adaptérů Bluetooth vyžaduje — žádná poloha se nezaznamenává ani nesdílí.';

  @override
  String get obd2ScanOpenSettings => 'Otevřít nastavení';

  @override
  String get obd2WaitingForEngineBanner =>
      'Čeká se na motor — záznam pomocí GPS';

  @override
  String get obd2StartEngineToReconnect =>
      'Nastartujte motor pro opětovné připojení';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motor je vypnutý — nastartujte jej pro opětovné připojení';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motor je vypnutý $minutes min — ukončit záznam?';
  }

  @override
  String get obd2ParkedPromptStop => 'Ukončit';

  @override
  String get obd2ParkedPromptKeep => 'Pokračovat';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motor byl vypnutý prvních $head a posledních $tail této jízdy — pokrytí se měří při běžícím motoru.';
  }

  @override
  String get obd2ReconnectInProgress => 'Opětovné připojování k adaptéru OBD2…';

  @override
  String get obd2StatusEngineOff => 'OBD2 pozastaveno — motor vypnutý';

  @override
  String get obd2StatusEngineOffBody =>
      'Adaptér byl dostupný, ale sběrnice vozidla mlčela, takže automatické opětovné připojování je pozastaveno. Obnoví se, až pojedete nebo znovu otevřete aplikaci — nebo se připojte znovu hned.';

  @override
  String get obd2StatusReconnectNow => 'Připojit znovu hned';

  @override
  String get autoRecordNotificationTitle => 'Automatický záznam jízd';

  @override
  String get autoRecordNotificationText => 'Čekání na váš adaptér OBD2';

  @override
  String get obd2ResetConnection => 'Resetovat připojení';

  @override
  String get obd2ResetConnectionDone => 'Adaptér resetován — spojení obnoveno';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adaptér resetován — opětovné připojování na pozadí';

  @override
  String get ocrTesterTitle => 'Tester OCR';

  @override
  String get ocrTesterNavLabel => 'Tester OCR';

  @override
  String get ocrTesterExplain =>
      'Spusťte OCR pipeline na vybrané fotce a zkontrolujte každý krok — dostupné pouze ve vývojářském režimu.';

  @override
  String get ocrTesterCapture => 'Vyfotit';

  @override
  String get ocrTesterPickImage => 'Vybrat obrázek';

  @override
  String get ocrTesterRun => 'Spustit';

  @override
  String get ocrTesterCountry => 'Země';

  @override
  String get ocrTesterCountryNone => 'Výchozí (bez profilu)';

  @override
  String get ocrTesterNoImage =>
      'Vyberte nebo vyfotografujte obrázek a spusťte.';

  @override
  String get ocrTesterRunning => 'Probíhá OCR…';

  @override
  String get ocrTesterOverlaySection => 'Překryv bloků';

  @override
  String get ocrTesterStepsSection => 'Kroky pipeline';

  @override
  String get ocrTesterLegendLabel => 'Popis';

  @override
  String get ocrTesterLegendNumeric => 'Číselné';

  @override
  String get ocrTesterLegendNoise => 'Šum';

  @override
  String get ocrTesterLegendDerived => 'Odvozené';

  @override
  String get ocrTesterStageGlare => 'Snímání / odlesk';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klasifikace';

  @override
  String get ocrTesterStageAssemble => 'Sestavení';

  @override
  String get ocrTesterStageAnchor => 'Ukotvení';

  @override
  String get ocrTesterStageFallback => 'Záložní postup';

  @override
  String get ocrTesterStageCrossCheck => 'Křížová kontrola';

  @override
  String get ocrTesterStageConfidence => 'Spolehlivost';

  @override
  String get ocrTesterStageGate => 'Brána';

  @override
  String get ocrTesterStageBrand => 'Značka';

  @override
  String get ocrTesterStageOverrides => 'Přepisy';

  @override
  String get ocrTesterStageReconcile => 'Sladění';

  @override
  String get ocrTesterStageResult => 'Výsledek';

  @override
  String get ocrTesterChipRead => 'PŘEČTENO';

  @override
  String get ocrTesterChipDerived => 'ODVOZENO';

  @override
  String get ocrTesterGateAccepted => 'Přijato';

  @override
  String get ocrTesterGateRejected => 'Odmítnuto';

  @override
  String get ocrTesterFallbackBanner =>
      'Pole bylo obnoveno záložním postupem — ověřte jej.';

  @override
  String get ocrTesterStageNoData => 'Krok nebyl spuštěn.';

  @override
  String get ocrTesterCopyJson => 'Kopírovat jako JSON';

  @override
  String get ocrTesterExportPackage => 'Exportovat balíček';

  @override
  String get ocrTesterCopied => 'Stopa OCR zkopírována do schránky.';

  @override
  String get ocrTesterExported => 'Balíček OCR uložen do složky Stažené.';

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
  String get onboardingObd2ConnectFailed =>
      'Nepodařilo se připojit k adaptéru. Můžete to zkusit znovu nebo přeskočit.';

  @override
  String get onboardingPickUseMode => 'Pro pokračování vyberte režim použití.';

  @override
  String get onboardingObd2LaterNote =>
      'Adaptér Bluetooth OBD2 můžete kdykoli později spárovat z obrazovky vozidla, abyste mohli zaznamenávat jízdy a číst data z motoru.';

  @override
  String get openHoursUnknown => 'Otevírací doba neznámá';

  @override
  String get open24Hours => 'Otevřeno 24 hodin';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Pondělí';

  @override
  String get dayTue => 'Úterý';

  @override
  String get dayWed => 'Středa';

  @override
  String get dayThu => 'Čtvrtek';

  @override
  String get dayFri => 'Pátek';

  @override
  String get daySat => 'Sobota';

  @override
  String get daySun => 'Neděle';

  @override
  String get dayShortMon => 'Po';

  @override
  String get dayShortTue => 'Út';

  @override
  String get dayShortWed => 'St';

  @override
  String get dayShortThu => 'Čt';

  @override
  String get dayShortFri => 'Pá';

  @override
  String get dayShortSat => 'So';

  @override
  String get dayShortSun => 'Ne';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Státní svátky';

  @override
  String get closedLabel => 'Zavřeno';

  @override
  String get openingHoursNotAvailable => 'Otevírací doba není k dispozici';

  @override
  String get showAllHours => 'Zobrazit všechny hodiny';

  @override
  String get showLessHours => 'Zobrazit méně';

  @override
  String get openStateUnknown => 'Neznámý';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stanice je otevřená',
      'false': 'Stanice je zavřená',
      'other': 'Stav otevření neznámý',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Přístup ke kameře';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Tato aplikace chce použít vaši kameru ke čtení účtenek, displejů stojanů a QR kódů.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Co se děje s obrazem z kamery:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'Obraz se používá pouze ke čtení účtenky, displeje stojanu nebo QR kódu — rozpoznávání probíhá ve vašem zařízení.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'Fotografie je po naskenování zahozena.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Nic se nenahrává, pokud nenahlásíte chybné skenování a nepotvrdíte to.';

  @override
  String get permissionRationaleBluetoothTitle => 'Přístup k Bluetooth';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Tato aplikace chce použít Bluetooth k připojení k vašemu adaptéru OBD2.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Co se děje s Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth se používá pouze k vyhledání vašeho adaptéru OBD2 a ke komunikaci s ním.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Identifikátor adaptéru zůstává ve vašem zařízení — synchronizuje se pouze přes TankSync jako součást profilu vozidla.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'V systému Android 11 a starším si systém vyžádá také polohu, protože vyhledávání Bluetooth tam spadá pod oprávnění k poloze.';

  @override
  String get permissionRationaleNotificationsTitle => 'Oznámení';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Tato aplikace vám chce posílat oznámení o cenových upozorněních a o stavu záznamu jízdy.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Co se děje s oznámeními:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Oznámení se používají pro místní cenová upozornění a stav záznamu jízdy.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Vytvářejí se ve vašem zařízení — nic zařízení neopouští.';

  @override
  String get permissionRationaleRevoke =>
      'Toto můžete kdykoli odvolat v nastavení zařízení.';

  @override
  String get permissionRationaleLegalBasis =>
      'Právní základ: čl. 6 odst. 1 písm. a) GDPR (souhlas)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'odh. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Odhadovaná hodnota (~) — na této jízdě není snímač paliva, takže spotřeba L/100 km je modelována z GPS rychlosti a kalibrace vašeho vozidla. Jde o přibližný údaj (typicky ±10–30 %, zpřesňující se s kalibrací), nikoli naměřená hodnota.';

  @override
  String get tripRecordingPipElapsedCaption => 'uplynulo';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: odhady spotřeby znovu ukotveny ke stojanu ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Otevřít naskenovaný odkaz?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Tento QR kód vede na $host. Otevírejte jen odkazy, kterým důvěřujete.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Otevřít odkaz';

  @override
  String get qrLaunchConfirmCancel => 'Zrušit';

  @override
  String get radarPinHelpTitle => 'O připnutí';

  @override
  String get radarPinHelpBody =>
      'Připnutí udržuje obrazovku zapnutou a skryje systémové lišty, aby byl přehled nejbližší stanice čitelný při uchycení na palubní desce. Klepnutím znovu odepněte. Automaticky se uvolní po zastavení radaru.';

  @override
  String get radarAutoPinTitle => 'Vždy připnout při spuštění radaru';

  @override
  String get radarAutoPinSubtitle =>
      'Radar se připne automaticky při každém spuštění místo ručního klepání. Spotřebovává více baterie.';

  @override
  String get radarScopeShowScope => 'Zobrazení radaru';

  @override
  String get radarScopeShowList => 'Zobrazení seznamu';

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
  String get reconcileWorkflowTitle => 'Vyrovnat spotřebu paliva';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Nalezena odchylka $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Natankovali jste $pumped L, ale zaznamenané jízdy pokrývají pouze $consumed L. Zbývá nevysvětlených $gap L.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Obvykle to znamená, že jízda nebyla zaznamenána (adaptér byl odpojen nebo aplikace zavřena), nebo chybí či je chybně zadána výdej.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Dokud není problém vyřešen, celkové palivo a celkové jízdy se nebudou shodovat.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Pomozte nám přiřadit odchylku';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Jsou všechna tankování pro tuto nádrž úplná a správná?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Jsou všechny jízdy zaznamenány?';

  @override
  String get reconcileWorkflowAnswerYes => 'Ano';

  @override
  String get reconcileWorkflowAnswerNo => 'Ne';

  @override
  String get reconcileWorkflowPathAHint =>
      'Chybí nebo je chybné tankování — přidáme korekci, aby tankování souhlasila.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Tankování jsou správná a jízda nebyla zaznamenána — přidáme virtuální jízdu pro chybějící vzdálenost.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Korekce v litrech';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Jak daleko byla nezaznamenaná jízda? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Rozhodnu se později';

  @override
  String get reconcileWorkflowBack => 'Zpět';

  @override
  String get reconcileWorkflowNext => 'Další';

  @override
  String get reconcileWorkflowApply => 'Použít';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtuální jízda — klepnutím upravíte';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Upravit virtuální jízdu';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Tato jízda byla přidána k zahrnutí paliva spotřebovaného při jízdě bez záznamu. Upravte vzdálenost nebo palivo, nebo jízdu smažte.';

  @override
  String get reconcileVirtualTrajetDelete => 'Smazat virtuální jízdu';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Nevyřešená odchylka paliva/jízd $gap L — klepnutím vyřešte';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Vyřešit nevyřešenou odchylku paliva a jízd';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/relaci';

  @override
  String get settingsSearchHint => 'Hledat v nastavení';

  @override
  String settingsSearchNoResults(String query) {
    return 'Žádné nastavení neodpovídá „$query“';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profily a region';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Země, jazyk, palivo, okruh hledání, plánování trasy';

  @override
  String get settingsTopicProfilesKeywords =>
      'profil, země, jazyk, palivo, okruh, psč, trasa, domov, hodnocení, úvodní obrazovka, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Vozidla a OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Vaše auta, objem nádrže, párování adaptéru OBD2';

  @override
  String get settingsTopicVehiclesKeywords =>
      'vozidlo, auto, obd, obd2, adaptér, bluetooth, nádrž, motor, vin, kalibrace, vehicle, car, adapter, tank, engine, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Jízda a spotřeba';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Koučování, odměny, radar čerpacích stanic, řešení potíží';

  @override
  String get settingsTopicDrivingKeywords =>
      'kouč, eko, haptický, hlas, gamifikace, radar, dojezd, jízda, spotřeba, palivový klub, věrnost, log obd2, připnout, coach, eco, haptic, voice, gamification, glide, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Ceny a upozornění';

  @override
  String get settingsTopicPricesSubtitle =>
      'Cenová upozornění, hlasová oznámení, historie cen, hlášení komunity';

  @override
  String get settingsTopicPricesKeywords =>
      'upozornění, oznámení, cena, historie, předpověď, nejlepší čas, komunita, hlášení, qr, platba, hlas, alert, notification, price, history, prediction, community, report, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Jednotky a zobrazení';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Motiv, jednotka vzdálenosti, widget na domovské obrazovce';

  @override
  String get settingsTopicUnitsKeywords =>
      'motiv, tmavý, světlý, eko, jednotka, km, míle, widget, barva, zobrazení, vzhled, theme, dark, light, eco, unit, miles, colour, display, appearance';

  @override
  String get settingsTopicFeaturesTitle => 'Funkce a režim použití';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Předvolby režimu použití a všechny přepínače funkcí';

  @override
  String get settingsTopicFeaturesKeywords =>
      'funkce, režim, základní, střední, plný, vlastní, přepínač, typy stanic, čerpací stanice, nabíječky, nabíjení, feature, mode, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Zdroje dat a poloha';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'Klíče API, poloha GPS, automatické přepínání profilu';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, klíč, gps, poloha, pozice, zdroj dat, tankerkoenig, opencharge, key, location, data source';

  @override
  String get settingsTopicSyncTitle => 'Synchronizace a účet';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, cloud, účet, e-mail, propojit zařízení, synchronizace, sdílet databázi, anonymní, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'soukromí, souhlas, gdpr, smazat, vymazat, úložiště, mezipaměť, data, hlášení chyb, vin, privacy, consent, delete, erase, storage, cache, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Záloha a obnovení';

  @override
  String get settingsTopicBackupSubtitle =>
      'Exportujte nebo obnovte úplnou zálohu svých dat';

  @override
  String get settingsTopicBackupKeywords =>
      'záloha, export, obnovit, import, zip, xml, přenos, backup, restore, transfer';

  @override
  String get settingsTopicAdvancedSubtitle =>
      'Token GitHub, vývojářské nástroje';

  @override
  String get settingsTopicAdvancedKeywords =>
      'vývojář, ladění, token, pat, github, diagnostika, protokol chyb, trasování, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Verze, licence, odkazy';

  @override
  String get settingsTopicAboutKeywords =>
      'o aplikaci, verze, licence, přispět, github, autorství, about, version, license, donate, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Zapněte sledování spotřeby v části Funkce a režim použití, abyste mohli nastavit vozidla, koučování a odměny.';

  @override
  String get settingsOpenFeaturesLink => 'Otevřít Funkce a režim použití';

  @override
  String get settingsRadarTileSubtitle =>
      'Okruh, cenový režim, dotazování a připnutí obrazovky pro aktivní profil';

  @override
  String get settingsRadarNoProfileHint =>
      'Nejprve vytvořte profil – nastavení radaru se ukládá pro každý profil zvlášť.';

  @override
  String get settingsRadarPinHeader => 'Připnutí obrazovky';

  @override
  String get settingsAlertsTileSubtitle =>
      'Upozornění na stanice a okruh, která vás informují o poklesu cen';

  @override
  String get settingsPriceFeaturesHeader => 'Cenové funkce';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Hlasová oznámení jsou vypnutá. Zapněte Hlasovou zpětnou vazbu a Hlasová oznámení v části Funkce a režim použití, abyste během jízdy slyšeli o levném palivu v okolí.';

  @override
  String get settingsDistanceUnitTitle => 'Jednotka vzdálenosti';

  @override
  String get settingsDistanceUnitSubtitle => 'Podle země aktivního profilu';

  @override
  String get settingsObd2AdapterTitle => 'Adaptér OBD2';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Adaptéry se párují pro každé vozidlo – otevřete vozidlo, chcete-li spárovat nebo změnit jeho adaptér';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Souhlasy';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Souhlasy pro Cloud Sync a synchronizaci jízd najdete v části Soukromí a data';

  @override
  String get settingsBackupExportSubtitle =>
      'Vozidla, tankování, jízdy a záznamy nabíjení jako soubor ZIP';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Sloučit nebo nahradit data z dřívější zálohy ZIP';

  @override
  String get settingsStationTypesLink =>
      'Typy stanic se nastavují v části Funkce a režim použití';

  @override
  String get routeSearchCriterionLabel => 'Výběr stanice pro úsek trasy';

  @override
  String get routeSearchCriterionCheapest => 'Nejlevnější';

  @override
  String get routeSearchCriterionNearest => 'Nejblíže trase';

  @override
  String get routeSearchTopNLabel => 'Kandidátů na bod vzorkování';

  @override
  String routeSearchTopNCaption(int count) {
    return 'V každém bodě podél trasy se zvažuje až $count stanic.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Palivo pro hledání cen (hybrid)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Výchozí pro vozidlo';

  @override
  String get scopeThisProfile => 'Tento profil';

  @override
  String get scopeAllProfiles => 'Všechny profily';

  @override
  String get scopeThisVehicle => 'Toto vozidlo';

  @override
  String get featureLabel_manualConsumption => 'Ruční záznam spotřeby';

  @override
  String get featureDescription_manualConsumption =>
      'Zaznamenávejte tankování a nabíjení ručně (adaptér OBD2 není potřeba).';

  @override
  String get featureLabel_loyaltyCards => 'Věrnostní karty';

  @override
  String get featureDescription_loyaltyCards =>
      'Karty palivových klubů / věrnostní karty se slevou na litr v porovnání cen.';

  @override
  String get featureLabel_startupTrace => 'Trasování inicializace při spuštění';

  @override
  String get featureDescription_startupTrace =>
      'Zaznamenává časované fáze spuštění aplikace, zobrazuje je jako vodopád a exportuje – diagnostika pro vývojáře.';

  @override
  String get locationGpsAutoHint =>
      'Poloha GPS se získává automaticky při hledání. Zde ji můžete také aktualizovat ručně.';

  @override
  String get locationClearGpsBody =>
      'Vymazat uloženou polohu GPS? Kdykoli ji můžete znovu aktualizovat.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Tento typ souboru zatím nelze importovat — sdílejte místo toho fotografii účtenky.';

  @override
  String get shareReceiptFailed =>
      'Nepodařilo se přečíst sdílenou účtenku — zkuste ji sdílet znovu nebo přidejte tankování ručně.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Sdílet účtenku pro import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Sdílejte fotografii účtenky z jiné aplikace pro předvyplnění tankování — datum, litry, celková částka a stanice se čtou na zařízení.';

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
  String syncAdoptTitle(String email) {
    return 'Připojit se k účtu $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Přihlaste se heslem k tomuto účtu, aby se jeho data sdílela na obou zařízeních.';

  @override
  String get syncAdoptPasswordLabel => 'Heslo k účtu';

  @override
  String get syncAdoptJoinButton => 'Připojit se k účtu';

  @override
  String get syncAdoptUseDifferentAccount => 'Použít raději jiný účet';

  @override
  String get syncDeleteDataTitle => 'Smazat synchronizovaná data';

  @override
  String get syncDeleteDataSubtitle =>
      'Odstraňte své jízdy, vozidla nebo tankování ze synchronizační databáze';

  @override
  String get syncDeleteDataPickTitle => 'Která synchronizovaná data smazat?';

  @override
  String get syncDeleteDataCategoryTrips => 'Jízdy';

  @override
  String get syncDeleteDataCategoryVehicles => 'Vozidla';

  @override
  String get syncDeleteDataCategoryFillUps => 'Tankování';

  @override
  String get syncDeleteDataCategoryEverything => 'Vše';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Smazat $category ze synchronizační databáze?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Odstraní vybraná data z vaší synchronizační databáze a ta se už z ostatních zařízení znovu nesynchronizují. Data uložená místně v tomto zařízení zůstanou zachována.';

  @override
  String get syncDeleteDataConfirmAction => 'Smazat ze serveru';

  @override
  String get syncDeleteDataDone => 'Synchronizovaná data smazána';

  @override
  String get syncDeleteDataFailed =>
      'Mazání synchronizovaných dat se nezdařilo — zkuste to znovu';

  @override
  String get syncRelinkTitle =>
      'Cloudovou synchronizaci je třeba znovu propojit';

  @override
  String get syncRelinkBody =>
      'Uložená synchronizační identita tohoto zařízení je odhlášena. Přihlaste se e-mailem pro opětovné propojení synchronizovaných dat, nebo začněte znovu s novou identitou.';

  @override
  String get syncRelinkSignInAction => 'Přihlásit se a znovu propojit';

  @override
  String get syncRelinkStartFreshAction => 'Začít znovu';

  @override
  String get syncRelinkStartFreshTitle => 'Začít znovu?';

  @override
  String get syncRelinkStartFreshBody =>
      'Pro toto zařízení bude vytvořena nová anonymní identita. Data synchronizovaná pod starou identitou zůstanou na serveru, ale odsud už nebudou dostupná, pokud se nepřihlásíte jejím e-mailovým účtem.';

  @override
  String get syncRelinkStartFreshConfirm => 'Začít znovu';

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
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km při spotřebě z poslední nádrže';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Dlouhodobý průměr: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Poslední tankování: $date · $count cesta/cest od té doby';
  }

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
  String tankLevelSourceFillUp(String date) {
    return 'Ukotveno k poslednímu tankování: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'Snímač nádrže OBD2 · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Směs v nádrži: $mix';
  }

  @override
  String get tankReportTitle => 'Zpráva o nádrži';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Od předchozí plné nádrže: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return 'O $delta L/100 km více než předchozí nádrž';
  }

  @override
  String tankReportTrendDown(String delta) {
    return 'O $delta L/100 km méně než předchozí nádrž';
  }

  @override
  String get tankReportTrendFlat => 'Na úrovni předchozí nádrže';

  @override
  String get tankReportNoPrevious =>
      'Vývoj se zobrazí po vaší příští plné nádrži.';

  @override
  String get tankReportExplainHeader => 'Co záznamy naznačují';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Podíl vysokých otáček $cur % (dříve $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Prudké manévry $cur/100 km (dříve $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Studené starty $cur (dříve $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Podíl volnoběhu $cur % (dříve $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Záznamy jsou nahodilé a pokrývají jen část této nádrže — tyto náznaky jsou orientační, ne celý obraz.';

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
  String get tripSaveProgressFinalizingSummary => 'Dokončování souhrnu…';

  @override
  String get tripSaveProgressSavingToHistory => 'Ukládání do historie…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Synchronizace na pozadí…';

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
  String get trajetDetailChartThrottle => 'Plyn / pedál (%)';

  @override
  String get trajetDetailChartCoolant => 'Chladivo (°C)';

  @override
  String get trajetDetailChartAltitudeRelative =>
      'Nadmořská výška (m, od startu)';

  @override
  String get trajetDetailChartLambda => 'Požadované λ';

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
  String get trajetDetailChartEstimatedBadge => 'odhadnuto';

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
  String get trajetDetailDownloadCsvOption => 'Stáhnout telemetrii (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Stáhnout telemetrii (JSON)';

  @override
  String get trajetDetailDownloadError => 'Soubor se nepodařilo uložit';

  @override
  String get trajetDetailDeleteAction => 'Smazat';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Smazat tuto cestu?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Tato cesta bude trvale odstraněna z vaší historie.';

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
  String get trajetDetailChartBoost => 'Plnicí tlak (MAP − okolí)';

  @override
  String get trajetDetailChartIat => 'Teplota nasávaného vzduchu';

  @override
  String get trajetDetailChartTiming => 'Předstih zapalování';

  @override
  String get trajetObd2Degraded =>
      'Zahájeno s adaptérem OBD2, ale zaznamenáno převážně přes GPS — data motoru jsou neúplná';

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
  String get tripPathLegendEfficient => 'Úsporná (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Přijatelná (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Neúsporná (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar čerpacích stanic';

  @override
  String get tripRadarScanning => 'Hledám okolní stanice';

  @override
  String get tripRadarNoStationNearby => 'Žádná stanice v okolí';

  @override
  String get fuelStationRadarNearer => 'Bližší stanice';

  @override
  String get fuelStationRadarFarther => 'Vzdálenější stanice';

  @override
  String get fuelStationRadarStart => 'Spustit radar čerpacích stanic';

  @override
  String get stopRadar => 'Zastavit radar';

  @override
  String get fuelStationRadarResultBadge => 'Výsledek Radaru čerpacích stanic';

  @override
  String get radarUpdatingLocation => 'Aktualizace vaší polohy…';

  @override
  String get radarSearching => 'Hledání…';

  @override
  String get highwayModeChip =>
      'Dálniční režim — zobrazuje stanice před vámi na trase';

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
  String get tripRecordingSavingTitle => 'Ukládání jízdy…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Záznam zrušen — žádný pohyb nezjištěn';

  @override
  String get tripRecordingGpsNotificationTitle => 'Nahrávám vaši jízdu';

  @override
  String get tripRecordingGpsNotificationText =>
      'Sledování vaší trasy pro statistiky paliva a jízdy';

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
  String get tripVerdictPromptTitle => 'Jaká byla tato jízda?';

  @override
  String get tripVerdictSmooth => 'Plynulá';

  @override
  String get tripVerdictModerate => 'Průměrná';

  @override
  String get tripVerdictAggressive => 'Agresivní';

  @override
  String get tripVerdictDismiss => 'Teď ne';

  @override
  String get tripVerdictThanks =>
      'Díky — pomáhá to kalibrovat analýzu vaší jízdy.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Tankování smazáno';

  @override
  String get trajetDeletedUndoSnackbar => 'Záznam smazán';

  @override
  String get searchFailedSnackbar => 'Hledání selhalo — zkuste to znovu';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stanic',
      one: '1 stanice',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Aktualizováno $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Také: $names';
  }

  @override
  String get favoriteAdd => 'Přidat do oblíbených';

  @override
  String get favoriteRemove => 'Odebrat z oblíbených';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Originál: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Stanice bez značky';

  @override
  String get unsupportedRegionTitle =>
      'Ve vašem regionu zatím není k dispozici';

  @override
  String get unsupportedRegionBody =>
      'Pro vaši zemi zatím nemáme ceny paliv, takže výsledky mohou být prázdné nebo z jiné země. V nastavení vyhledávání si přesto můžete vybrat podporovanou zemi.';

  @override
  String get unsupportedRegionDismiss => 'Rozumím';

  @override
  String get configureCountryTitle => 'Nastavte svou zemi';

  @override
  String get configureCountryBody =>
      'Vaše země je podporována, ale ještě není nastavena — ceny tak mohou být z jiné země. Vyberte svou zemi v nastavení vyhledávání, aby se zobrazily místní ceny.';

  @override
  String get stalePriceBadge => 'Old price';

  @override
  String get radiusAlertCenterChipGps => 'My position';

  @override
  String get radiusAlertCenterChipMap => 'Map point';

  @override
  String radiusAlertCenterChipPostal(String postalCode) {
    return 'Postal code $postalCode';
  }

  @override
  String get radiusAlertCenterClear => 'Clear location';

  @override
  String get radiusAlertBlockerLabel => 'Enter a label';

  @override
  String get radiusAlertBlockerThreshold => 'Enter a threshold above 0';

  @override
  String get radiusAlertBlockerLocation => 'Choose a location';

  @override
  String get brandMarkFuelGeneric => 'Fuel station';

  @override
  String get brandMarkEvGeneric => 'Charging point';

  @override
  String get fillInventoryTitle => 'Fill-up summary';

  @override
  String fillInventorySubtitleFull(String date, String fuel) {
    return 'Full tank on $date · $fuel';
  }

  @override
  String fillInventorySubtitlePartial(String date, String fuel) {
    return 'Partial fill on $date · $fuel';
  }

  @override
  String fillInventoryKmSinceLastFull(String km) {
    return '$km km since the last full tank';
  }

  @override
  String fillInventoryPumpLiters(String liters) {
    return '$liters L pumped';
  }

  @override
  String fillInventoryPumpConsumption(String value) {
    return 'Pump consumption: $value';
  }

  @override
  String fillInventoryRecordedTrips(int coverage, String value) {
    return 'Recorded trips: $coverage % of the tank · $value raw';
  }

  @override
  String get fillInventoryNoRecordedTrips => 'No recorded trip in this tank';

  @override
  String fillInventoryTankNow(String liters, String km) {
    return 'Tank now: $liters L · ≈ $km km at pump consumption';
  }

  @override
  String fillInventoryTankNowNoRange(String liters) {
    return 'Tank now: $liters L';
  }

  @override
  String fillInventoryCalibrationApplied(
    String before,
    String after,
    String percent,
  ) {
    return 'Pump calibration: ×$before → ×$after ($percent %)';
  }

  @override
  String fillInventoryCalibrationSkipped(String reason) {
    return 'Pump calibration: skipped — $reason';
  }

  @override
  String get fillInventorySkipNotFullTank =>
      'partial fill (the tank window stays open)';

  @override
  String get fillInventorySkipCorrection =>
      'correction entry, not a pumped fill';

  @override
  String get fillInventorySkipNoVehicle => 'no vehicle on this fill';

  @override
  String get fillInventorySkipNoWindow =>
      'first full tank (no window closed yet)';

  @override
  String fillInventorySkipCoverageTooLow(int coverage) {
    return 'recorded trips cover $coverage % of the tank (60 % needed)';
  }

  @override
  String fillInventorySkipRecordedTooShort(String km) {
    return 'only $km recorded km (40 km needed)';
  }

  @override
  String get fillInventorySkipNoRecordedFuel =>
      'the recorded trips carry no fuel figure';

  @override
  String get fillInventorySkipImplausible =>
      'pump and recordings disagree too much — check the receipt';

  @override
  String get fillInventoryDismiss => 'Got it';

  @override
  String tankReportResidualAfterCalibration(String percent) {
    return 'Gap after calibration: $percent %';
  }

  @override
  String get tripFuelSourceMeasured => 'Measured';

  @override
  String get tripFuelSourceEstimatedCalibrated => 'Estimated · calibrated';

  @override
  String get tripFuelSourceEstimated => 'Estimated';

  @override
  String get tripFuelSourceGps => 'GPS';

  @override
  String get tripFuelSourceMeasuredTooltip =>
      'Fuel rate reported by the engine (PID 5E / 9D / A2) — never rescaled';

  @override
  String get tripFuelSourceEstimatedTooltip =>
      'Fuel estimated from air mass — rescaled by the pump calibration';

  @override
  String get tripFuelSourceGpsTooltip =>
      'GPS-physics estimate — no engine data';

  @override
  String get tripFuelSourceRecalculated => 'recalculated';

  @override
  String tripDetailGainApplied(String percent) {
    return 'Pump gain applied: $percent %';
  }

  @override
  String tripDetailRecalculatedAfterFill(String date) {
    return 'Recalculated after the fill-up of $date';
  }

  @override
  String get fillUpOdometerFromLastFillUp =>
      'Pre-filled from your last fill-up';

  @override
  String get fillUpStationLabel => 'Station';

  @override
  String get fillUpStationChange => 'Change';

  @override
  String get pickStationSectionLast => 'Last station';

  @override
  String get pickStationSectionFavorites => 'Favorites';

  @override
  String get pickStationSectionNearby => 'Nearby';

  @override
  String get pickStationNearbyEmpty =>
      'No recent search — search for stations on the Search tab and the nearest ones will appear here.';

  @override
  String pickStationLastFillUpAt(String date) {
    return 'Last fill-up: $date';
  }

  @override
  String get privacyTopicSubtitle =>
      'Your choices, data on this device, sync, export or delete';

  @override
  String get privacyDataLocationLocal => 'Your data stays on this device';

  @override
  String get privacyDataLocationSynced =>
      'Your data is also synced to TankSync';

  @override
  String get privacySyncLineEnabledAnonymous => 'Sync: on · anonymous account';

  @override
  String get privacySyncLineEnabledEmail => 'Sync: on · email account';

  @override
  String get privacySyncLineDisabled => 'Sync: off';

  @override
  String privacyStorageLine(String size) {
    return '$size stored on this device';
  }

  @override
  String get privacyTopicChoicesTitle => 'Your choices';

  @override
  String privacyChoicesStatus(int on, int total) {
    return '$on of $total enabled';
  }

  @override
  String privacyDeviceDataStatus(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$size · $_temp0';
  }

  @override
  String get privacyTopicExportDeleteTitle => 'Export or delete';

  @override
  String privacyExportDeleteStatus(int count) {
    return 'ZIP, JSON, CSV · error log ($count)';
  }

  @override
  String get privacyLearnMore => 'Learn more';

  @override
  String get tileProxyToggleShort =>
      'Tiles come via the developer\'s EU proxy, not straight from OpenStreetMap';

  @override
  String get remoteLogosToggleShort =>
      'Fetch brand logos from logo.clearbit.com instead of bundled placeholders';

  @override
  String get privacyCacheDetails => 'Cache details';

  @override
  String privacyCacheResponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cached responses',
      one: '1 cached response',
    );
    return '$_temp0';
  }

  @override
  String privacyClearCacheEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'Clear cache ($_temp0)';
  }

  @override
  String get privacySyncStatusLabel => 'Status';

  @override
  String get privacySyncModeCommunity =>
      'Sparkilo Community — the developer\'s EU server';

  @override
  String get privacySyncModeSelfHosted => 'Self-hosted — your own Supabase';

  @override
  String get privacySyncModeSharedGroup =>
      'Shared group — a database you joined';

  @override
  String get privacySyncAccountLabel => 'Account';

  @override
  String get privacySyncAccountAnonymous =>
      'Anonymous account, tied to this device';

  @override
  String privacySyncAccountEmail(String email) {
    return 'Email account: $email';
  }

  @override
  String get privacyCopyUserId => 'Copy user ID';

  @override
  String get privacyUserIdCopied => 'User ID copied';

  @override
  String get privacySyncDatabaseHost => 'Database host';

  @override
  String get privacyExportSectionTitle => 'Export';

  @override
  String get privacyExportMyData => 'Export my data';

  @override
  String get privacyExportSheetTitle => 'Choose a format';

  @override
  String get privacyExportZipTitle => 'ZIP archive';

  @override
  String get privacyExportZipSubtitle =>
      'Everything, attachments included — for a complete backup';

  @override
  String get privacyExportJsonTitle => 'JSON';

  @override
  String get privacyExportJsonSubtitle => 'Machine-readable — for another app';

  @override
  String get privacyExportCsvTitle => 'CSV';

  @override
  String get privacyExportCsvSubtitle => 'Spreadsheet — one table per category';

  @override
  String get privacyErrorLogTitle => 'Error log';

  @override
  String privacyErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get privacyErrorLogSave => 'Save';

  @override
  String get privacyErrorLogClear => 'Clear';

  @override
  String get privacyDangerZoneTitle => 'Danger zone';

  @override
  String get privacyDangerZoneBody =>
      'Permanently deletes everything the app stores on this device. With sync on, your data on the TankSync server is erased too.';

  @override
  String get privacyDeleteAllMyData => 'Delete all my data';

  @override
  String get tripRecordingScreenTitle => 'Trip in progress';

  @override
  String get recordingObd2ChipLive => 'Live';

  @override
  String recordingObd2ChipLiveRate(int rate) {
    return 'Live · $rate PID/s';
  }

  @override
  String get recordingObd2ChipReconnecting => 'Reconnecting…';

  @override
  String recordingObd2ChipReconnectingAttempt(int attempt) {
    return 'Reconnecting… (try $attempt)';
  }

  @override
  String get recordingObd2ChipGpsOnly => 'GPS only';

  @override
  String get recordingObd2ChipEngineOff => 'Engine off — waiting';

  @override
  String get recordingObd2ChipNoAdapter => 'No adapter';

  @override
  String get recordingObd2SheetTitle => 'OBD2 link';

  @override
  String get recordingObd2SheetLive =>
      'The adapter is delivering engine data, so consumption is measured from the car. Nothing to do — keep driving.';

  @override
  String get recordingObd2SheetReconnecting =>
      'The Bluetooth link is being re-established; meanwhile the recording continues on GPS. No action needed — a reset only helps if it stays like this for minutes.';

  @override
  String get recordingObd2SheetGpsOnly =>
      'The adapter has not answered for a while, so the app waits for it to reappear and records on GPS. Consumption is estimated until it is back.';

  @override
  String get recordingObd2SheetEngineOff =>
      'The engine is off, so there is nothing to read. The recording continues on GPS and picks the adapter up again as soon as the engine runs.';

  @override
  String get recordingObd2SheetNoAdapter =>
      'This trip is recorded without an OBD2 adapter. Speed and distance come from GPS; consumption is a physics estimate calibrated by your fill-ups.';

  @override
  String recordingGpsChipPrecise(int meters) {
    return 'Precise fix (±$meters m)';
  }

  @override
  String recordingGpsChipApprox(int meters) {
    return 'Approximate fix (±$meters m)';
  }

  @override
  String get recordingGpsChipNoFix => 'No fix';

  @override
  String get recordingGpsChipFixUnknownAccuracy => 'Fix (accuracy unknown)';

  @override
  String recordingGpsChipWithCoverage(String fix, int percent) {
    return '$fix · $percent %';
  }

  @override
  String get recordingGpsSheetTitle => 'GPS signal';

  @override
  String get recordingGpsSheetPrecise =>
      'The position is accurate to a few metres, so distance and the trace are reliable.';

  @override
  String get recordingGpsSheetApprox =>
      'The position is only accurate to tens of metres — typical in cities, tunnels or under trees. Distance may drift slightly until the fix improves.';

  @override
  String get recordingGpsSheetNoFix =>
      'No position has arrived recently. Check that location is allowed and the phone can see the sky; the recording resumes with the next fix.';

  @override
  String recordingGpsSheetCoverage(int percent) {
    return 'Coverage so far: $percent % of the seconds had a fix.';
  }

  @override
  String get recordingSheetClose => 'Got it';

  @override
  String get fuelSourceMeasured => 'Measured (ECU fuel flow)';

  @override
  String fuelSourceEstimatedCalibrated(int percent) {
    return 'Estimated · pump-calibrated ±$percent %';
  }

  @override
  String get fuelSourceEstimatedUncalibrated => 'Estimated · not calibrated';

  @override
  String get fuelSourceGpsEstimate => 'GPS estimate';

  @override
  String get recordingTileScore => 'Driving score';

  @override
  String stationStatusWithFreshness(String status, String ago) {
    return '$status · updated $ago ago';
  }

  @override
  String pricesNotSoldHere(String fuels) {
    return 'Not sold here: $fuels';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return 'Recorded trips cover $pct % of this tank';
  }

  @override
  String tankReportRecordedTripsAvg(String value) {
    return 'Recorded trips: $value';
  }

  @override
  String tankReportRecordedTripsOverestimate(String pct) {
    return 'Your recorded trips overestimate consumption by $pct %';
  }

  @override
  String tankReportRecordedTripsUnderestimate(String pct) {
    return 'Your recorded trips underestimate consumption by $pct %';
  }

  @override
  String get trajetObd2DegradedSubtitle => 'No engine data — GPS estimate';

  @override
  String get vehicleTopicAdapterNone => 'None';

  @override
  String get vehicleTopicCalibrationTitle => 'Calibration';

  @override
  String get vehicleTopicAdvancedBadge => 'Advanced';

  @override
  String vehicleTopicCalibrationStatus(int coverage, String mode) {
    return 'Baseline $coverage % · $mode';
  }

  @override
  String vehicleTopicRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
      zero: 'No reminders',
    );
    return '$_temp0';
  }

  @override
  String get vehicleTopicAutoRecordOn => 'On';

  @override
  String get vehicleTopicAutoRecordOff => 'Off';

  @override
  String get vehicleTopicAutoRecordPairLinkText =>
      'Pair an adapter under “OBD2 adapter” to enable auto-recording';

  @override
  String vehicleBaselineCoverageSamples(int covered, int max) {
    return '$covered / $max samples';
  }

  @override
  String vehicleBaselineRawSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get calibrationModeRuleDescription =>
      'Sorts each driving sample into one situation using fixed speed and load thresholds.';

  @override
  String get calibrationModeFuzzyDescription =>
      'Splits each sample across neighbouring situations by how well it fits each one — smoother estimates around the boundaries.';

  @override
  String get pumpGainChipNotCalibrated => 'Not pump-calibrated yet';

  @override
  String pumpGainChipCalibrated(int fills, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      fills,
      locale: localeName,
      other: 'Pump-calibrated · $fills fill-ups · ±$percent %',
      one: 'Pump-calibrated · 1 fill-up · ±$percent %',
    );
    return '$_temp0';
  }

  @override
  String get pumpGainResetAction => 'Reset pump calibration';

  @override
  String get pumpGainResetConfirmTitle => 'Reset pump calibration?';

  @override
  String get pumpGainResetConfirmBody =>
      'This discards the fuel gain learned from your fill-ups. OBD2 consumption estimates fall back to the uncorrected figure until the next full-to-full tank window re-learns it.';

  @override
  String get vehicleMultiFuelCapableLabel => 'Mohu tankovat různé druhy paliva';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Sleduje, které palivo je nejlevnější na kilometr';

  @override
  String get vinLabel => 'VIN (volitelné)';

  @override
  String get vinDecodeTooltip => 'Dekódovat VIN';

  @override
  String get vinConfirmAction => 'Ano, automaticky vyplnit';

  @override
  String get vinModifyAction => 'Upravit ručně';

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
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Zjištěno z VIN: $summary. Použít?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Použít';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometrů dopředu, $fuelType $euros euro $cents';
  }

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
  String get widgetDefaultsThisProfileHint =>
      'Níže uvedené volby platí pro všechny nainstalované widgety zobrazující tento profil, při příští aktualizaci.';

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
}
