// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabRunSearch => 'Spustiť vyhľadávanie';

  @override
  String get routeSearchingChip => 'Hľadám trasu…';

  @override
  String get searchCriteriaTitle => 'Kritériá vyhľadávania';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'V okruhu $km km';
  }

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
  String get apiKeyLabel => 'Kľúč API';

  @override
  String get register => 'Registrácia';

  @override
  String get continueButton => 'Pokračovať';

  @override
  String get welcome => 'Sparkilo';

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
  String get landingScreenFavorites => 'Favorites';

  @override
  String get landingScreenMap => 'Map';

  @override
  String get landingScreenCheapest => 'Cheapest nearby';

  @override
  String get landingScreenNearest => 'Nearest stations';

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
  String get countryChangeTitle => 'Prepnúť krajinu?';

  @override
  String countryChangeBody(String country) {
    return 'Prepnutím na $country sa zmení:';
  }

  @override
  String get countryChangeCurrency => 'Mena';

  @override
  String get countryChangeDistance => 'Vzdialenosť';

  @override
  String get countryChangeVolume => 'Objem';

  @override
  String get countryChangePricePerUnit => 'Formát ceny';

  @override
  String get countryChangeNote =>
      'Existujúce obľúbené položky a záznamy o tankovaní sa neprepíšu; nové záznamy budú používať nové jednotky.';

  @override
  String get countryChangeConfirm => 'Prepnúť';

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
  String get dataTransparency => 'Transparentnosť údajov';

  @override
  String get clearCache => 'Vymazať vyrovnávaciu pamäť';

  @override
  String get storageUsage => 'Využitie úložiska na tomto zariadení';

  @override
  String get settingsLabel => 'Nastavenia';

  @override
  String get total => 'Celkom';

  @override
  String get cacheDescription =>
      'Vyrovnávacia pamäť ukladá odpovede API pre rýchlejšie načítanie a offline prístup.';

  @override
  String get cacheTtlGroupNetwork => 'Sieť';

  @override
  String get cacheTtlGroupData => 'Dáta';

  @override
  String get cacheTtlGroupGeocoding => 'Geokódovanie';

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
  String get deleteAllButton => 'Vymazať všetko';

  @override
  String get cacheEmpty => 'Vyrovnávacia pamäť je prázdna';

  @override
  String get apiKeyNote =>
      'Bezplatná registrácia. Údaje od vládnych agentúr pre cenovú transparentnosť.';

  @override
  String get apiKeyFormatError =>
      'Neplatný formát — očakávané UUID (8-4-4-4-12)';

  @override
  String get reportThisIssue => 'Nahlásiť tento problém';

  @override
  String get reportAlreadySent => 'Tento problém ste už nahlásili.';

  @override
  String get reportConsentTitle => 'Nahlásiť na GitHub?';

  @override
  String get reportConsentBody =>
      'Tým sa otvorí verejný problém na GitHub s podrobnosťami o chybe uvedenými nižšie. Nie sú zahrnuté žiadne súradnice GPS, kľúče API ani osobné údaje.';

  @override
  String get reportConsentConfirm => 'Otvoriť GitHub';

  @override
  String get reportConsentCancel => 'Zrušiť';

  @override
  String get searchLocationPlaceholder => 'Adresa, PSČ alebo mesto';

  @override
  String get configTankSyncConnected => 'Pripojené';

  @override
  String get configTankSyncDisabled => 'Zakázané';

  @override
  String get privacyPolicy => 'Zásady ochrany súkromia';

  @override
  String get fuels => 'Palivá';

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
  String get demoModeBannerAction => 'Získať živé ceny';

  @override
  String get sortDistance => 'Vzdialenosť';

  @override
  String get sortRating => 'Hodnotenie';

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
  String profileSwitchedTo(String profile) {
    return 'Prepnuté na $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name vytvorený';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Profil pre $country už existuje — namiesto toho ho upravte.';
  }

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
  String get refuelPlanTab => 'Plan';

  @override
  String get refuelPlanCheapestTitle => 'Cheapest trip';

  @override
  String get refuelPlanFastestTitle => 'Fastest trip';

  @override
  String refuelPlanStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
      zero: 'No stop needed',
    );
    return '$_temp0';
  }

  @override
  String refuelPlanTotal(String cost, String perKm) {
    return '$cost total · $perKm/km';
  }

  @override
  String refuelPlanGap(String from, String to) {
    return 'No station in range between $from and $to';
  }

  @override
  String get refuelPlanNeedsConsumption =>
      'Add a few fill-ups and Sparkilo can plan your stops';

  @override
  String get refuelPlanNeedsTank =>
      'Set your tank size to plan refuelling stops';

  @override
  String get refuelPlanNeedsPrices =>
      'No station on this route has a price for your fuel';

  @override
  String get decisionConfidentLead => 'Best stop for you';

  @override
  String get decisionConfidentWhy =>
      'Open now, price from the last day, and measured on your own consumption';

  @override
  String get savingsTitle => 'Against your usual price';

  @override
  String savingsNet(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills',
      one: '1 fill',
    );
    return '$amount net over $_temp0';
  }

  @override
  String savingsReference(String price, String litres) {
    return 'Your usual: $price per litre, $litres per fill';
  }

  @override
  String get savingsNeedsHistory =>
      'A few more fill-ups and Sparkilo can tell you what you are saving';

  @override
  String criteriaMoreFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'More filters ($count)',
      zero: 'More filters',
    );
    return '$_temp0';
  }

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
  String get evPriceFree => 'Zadarmo';

  @override
  String get evPricePayAtLocation => 'Platba na mieste';

  @override
  String get evPriceMembership => 'Vyžaduje členstvo';

  @override
  String get evPriceIndicative => 'Orientačná cena';

  @override
  String get evPriceDeclaredByOperator =>
      'Orientačná cena deklarovaná prevádzkovateľom — overte na mieste';

  @override
  String get evPriceFranceAttribution =>
      'Ceny: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Ceny z OpenChargeMap na báze najlepšieho úsilia — riedke a môžu byť neúplné.';

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
  String get edit => 'Upraviť';

  @override
  String get fuelPricesApiKey => 'Kľúč API cien palív';

  @override
  String get evChargingApiKey => 'Kľúč API nabíjania EV';

  @override
  String get openChargeMapApiKey => 'Kľúč API OpenChargeMap';

  @override
  String get routePlanningSection => 'Plánovanie trasy';

  @override
  String get routeMinSaving => 'Minimálna úspora';

  @override
  String get routeMinSavingOff => 'Vypnuté';

  @override
  String get routeMinSavingOffCaption =>
      'Zobrazujú sa všetky stanice nájdené na trase';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Iba stanice do $amount od najlacnejšej na trase';
  }

  @override
  String get routeDetourBudget => 'Maximálna obchádzka';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Zobraziť stanice až $km km od priamej trasy';
  }

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
  String get noStationsAlongThisRoute =>
      'Pozdĺž tejto trasy neboli nájdené žiadne stanice.';

  @override
  String get fuelCostCalculator => 'Kalkulačka nákladov na palivo';

  @override
  String get distanceKm => 'Vzdialenosť (km)';

  @override
  String get tripCost => 'Náklady na cestu';

  @override
  String get fuelNeeded => 'Potrebné palivo';

  @override
  String get totalCost => 'Celkové náklady';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Vzdialenosť ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Spotreba ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Cena paliva ($unit)';
  }

  @override
  String get calculatorUseMine => 'Použiť';

  @override
  String get calculatorApplied => 'Použité';

  @override
  String get tripDetails => 'Podrobnosti výletu';

  @override
  String get calculatorRoundTrip => 'Spiatočná cesta';

  @override
  String get roundTripTotal => 'Spiatočná cesta';

  @override
  String get costPerDistance => 'Náklady na km';

  @override
  String get costPerMonth => 'Náklady za mesiac';

  @override
  String get calculatorEstimateMonthly => 'Odhadnúť mesačné náklady';

  @override
  String get calculatorTripsPerMonth => 'Výlety za mesiac';

  @override
  String get calculatorTripsPerMonthHint => 'napr. 20';

  @override
  String get calculatorReset => 'Resetovať';

  @override
  String get calculatorResultPlaceholder =>
      'Vyplňte vzdialenosť, spotrebu a cenu, aby ste videli náklady na výlet';

  @override
  String get priceHistory => 'História cien';

  @override
  String get favoritesDataCache => 'Dáta obľúbených';

  @override
  String get citySearchCache => 'Vyhľadávanie mesta';

  @override
  String get noPriceHistory => 'Zatiaľ žiadna história cien';

  @override
  String get showAllFuelTypes => 'Zobraziť všetky typy palív';

  @override
  String get connected => 'Pripojené';

  @override
  String get disconnectTankSync => 'Odpojiť TankSync';

  @override
  String get viewMyData => 'Zobraziť moje údaje';

  @override
  String get deleteAllServerData => 'Vymazať všetky údaje servera';

  @override
  String get deleteServerDataConfirm => 'Vymazať všetky údaje servera?';

  @override
  String get deleteEverything => 'Vymazať všetko';

  @override
  String get allDataDeleted => 'Všetky údaje servera vymazané';

  @override
  String get forgetAllSyncedTripsButton =>
      'Odstrániť všetky synchronizované jazdy';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Odstrániť všetky synchronizované jazdy?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Všetky súhrny jázd a detailné záznamy budú odstránené zo servera. Vaša lokálna história jázd na tomto zariadení nebude ovplyvnená.\n\nTúto akciu nie je možné vrátiť späť.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Odstrániť všetko';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Všetky synchronizované jazdy boli odstránené zo servera';

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
  String get syncedTrips => 'Cesty';

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
  String get account => 'Účet';

  @override
  String get continueAsGuest => 'Pokračovať ako hosť';

  @override
  String get createAccount => 'Vytvoriť účet';

  @override
  String get signIn => 'Prihlásiť sa';

  @override
  String get savedRoutes => 'Uložené trasy';

  @override
  String get noSavedRoutes => 'Žiadne uložené trasy';

  @override
  String get noSavedRoutesHint =>
      'Vyhľadajte pozdĺž trasy a uložte ju pre rýchly prístup neskôr.';

  @override
  String get saveRoute => 'Uložiť trasu';

  @override
  String get routeName => 'Názov trasy';

  @override
  String itineraryDeleted(String name) {
    return '$name odstránená';
  }

  @override
  String loadingRoute(String name) {
    return 'Načítava sa trasa: $name';
  }

  @override
  String loyaltyCardDeleted(String card) {
    return 'Deleted $card';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get positionAgeUnderMinute => '< 1 min';

  @override
  String positionAgeHours(int hours) {
    return '$hours h';
  }

  @override
  String positionAgeDays(int days) {
    return '$days d';
  }

  @override
  String durationHoursMinutesCompact(int hours, String minutes) {
    return '${hours}h $minutes';
  }

  @override
  String durationSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get savedRoutesLoading => 'Loading your saved routes…';

  @override
  String get refreshFailed => 'Obnovenie zlyhalo. Skúste to znova.';

  @override
  String get deleteProfileTitle => 'Delete profile?';

  @override
  String get deleteProfileBody =>
      'This profile and its settings will be permanently deleted. This cannot be undone.';

  @override
  String get deleteProfileConfirm => 'Delete profile';

  @override
  String activeCountryChangedTo(String country) {
    return 'Active country is now $country';
  }

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String aboutVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String referenceVehicleLoadFailed(String reason) {
    return 'Couldn\'t load the vehicle catalog: $reason';
  }

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
      'Nastavte aplikáciu v niekoľkých rýchlych krokoch.';

  @override
  String get onboardingApiKeyDescription =>
      'Zaregistrujte sa pre bezplatný kľúč API alebo preskočte a preskúmajte aplikáciu s demo dátami.';

  @override
  String get onboardingComplete => 'Všetko pripravené!';

  @override
  String get onboardingCompleteHint =>
      'Tieto nastavenia môžete kedykoľvek zmeniť vo svojom profile.';

  @override
  String get onboardingBack => 'Späť';

  @override
  String get onboardingNext => 'Ďalej';

  @override
  String get onboardingSkip => 'Preskočiť';

  @override
  String get onboardingFinish => 'Začať';

  @override
  String get switchToAllPricesView => 'Prepnúť na zobrazenie všetkých cien';

  @override
  String get switchToCompactView => 'Prepnúť na kompaktné zobrazenie';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Nedostupné';

  @override
  String get gdprTitle => 'Vaše súkromie';

  @override
  String get gdprSubtitle =>
      'Táto aplikácia rešpektuje vaše súkromie. Vyberte, ktoré údaje chcete zdieľať. Tieto nastavenia môžete kedykoľvek zmeniť.';

  @override
  String get gdprLocationTitle => 'Prístup k polohe';

  @override
  String get gdprLocationDescription =>
      'Vaše súradnice sa odošlú do API cien palív, aby sa našli najbližšie stanice. Údaje o polohe sa nikdy neukladajú na server a nepoužívajú sa na sledovanie.';

  @override
  String get gdprLocationShort =>
      'Nájsť najbližšie čerpacie stanice pomocou vašej polohy';

  @override
  String get gdprErrorReportingTitle => 'Hlásenie chýb';

  @override
  String get gdprErrorReportingDescription =>
      'Anonymné správy o páde aplikácie pomáhajú vylepšovať aplikáciu. Neobsahujú žiadne osobné údaje. Správy sa odosielajú cez Sentry iba keď je nakonfigurovaný.';

  @override
  String get gdprErrorReportingShort =>
      'Odosielať anonymné správy o páde pre zlepšenie aplikácie';

  @override
  String get gdprCloudSyncTitle => 'Synchronizácia s cloudom';

  @override
  String get gdprCloudSyncDescription =>
      'Synchronizujte obľúbené a upozornenia naprieč zariadeniami cez TankSync. Používa anonymné overenie. Vaše údaje sú šifrované pri prenose.';

  @override
  String get gdprCloudSyncShort =>
      'Synchronizovať obľúbené a upozornenia naprieč zariadeniami';

  @override
  String get gdprLegalBasis =>
      'Právny základ: čl. 6 ods. 1 písm. a) GDPR (Súhlas). Súhlas môžete kedykoľvek odvolať v Nastaveniach.';

  @override
  String get gdprContinueAll => 'Pokračovať so všetkým';

  @override
  String get gdprContinueSelected => 'Pokračovať s vybraným';

  @override
  String get gdprSettingsHint =>
      'Vaše nastavenia ochrany súkromia môžete kedykoľvek zmeniť.';

  @override
  String get routeSaved => 'Trasa uložená!';

  @override
  String get routeSaveFailed => 'Uloženie trasy zlyhalo';

  @override
  String get sqlCopied => 'SQL skopírovaný do schránky';

  @override
  String get connectionDataCopied => 'Údaje o pripojení skopírované';

  @override
  String get accountDeleted =>
      'Účet bol odstránený. Lokálne údaje sú zachované.';

  @override
  String get switchedToAnonymous => 'Prepnuté na anonymnú reláciu';

  @override
  String failedToSwitch(String error) {
    return 'Prepnutie zlyhalo: $error';
  }

  @override
  String get connectedAsGuest => 'Pripojený ako hosť';

  @override
  String get accountCreated => 'Účet vytvorený!';

  @override
  String get signedIn => 'Prihlásený!';

  @override
  String stationHidden(String name) {
    return '$name skrytá';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name odstránená z obľúbených';
  }

  @override
  String invalidApiKey(String error) {
    return 'Neplatný kľúč API: $error';
  }

  @override
  String get invalidQrCode => 'Neplatný formát QR kódu';

  @override
  String get invalidQrCodeTankSync =>
      'Neplatný QR kód — očakávaný formát TankSync';

  @override
  String get tankSyncConnected => 'TankSync pripojený!';

  @override
  String get syncCompleted => 'Synchronizácia dokončená — údaje obnovené';

  @override
  String get deviceCodeCopied => 'Kód zariadenia skopírovaný';

  @override
  String get undo => 'Vrátiť späť';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Zadajte platné $length-miestne $label';
  }

  @override
  String get freshnessAgo => 'pred';

  @override
  String get freshnessStale => 'Zastarané';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Aktuálnosť dát: $age';
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
      other: 'Ohodnotiť $count hviezdičkami',
      one: 'Ohodnotiť 1 hviezdičkou',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Slabé';

  @override
  String get passwordStrengthFair => 'Primerané';

  @override
  String get passwordStrengthStrong => 'Silné';

  @override
  String get passwordReqMinLength => 'Aspoň 8 znakov';

  @override
  String get passwordReqUppercase => 'Aspoň 1 veľké písmeno';

  @override
  String get passwordReqLowercase => 'Aspoň 1 malé písmeno';

  @override
  String get passwordReqDigit => 'Aspoň 1 číslica';

  @override
  String get passwordReqSpecial => 'Aspoň 1 špeciálny znak';

  @override
  String get passwordTooWeak => 'Heslo nespĺňa všetky požiadavky';

  @override
  String get brandFilterAll => 'Všetky';

  @override
  String get brandFilterNoHighway => 'Bez diaľnice';

  @override
  String get swipeTutorialMessage =>
      'Potiahnutím doprava navigovať, potiahnutím doľava odstrániť';

  @override
  String get swipeTutorialDismiss => 'Rozumiem';

  @override
  String get alertStatsActive => 'Aktívne';

  @override
  String get alertStatsToday => 'Dnes';

  @override
  String get alertStatsThisWeek => 'Tento týždeň';

  @override
  String get privacyLocalData => 'Dáta na tomto zariadení';

  @override
  String get privacyIgnoredStations => 'Ignorované stanice';

  @override
  String get privacyRatings => 'Hodnotenia staníc';

  @override
  String get privacyPriceHistory => 'Stanice s históriou cien';

  @override
  String get privacyProfiles => 'Vyhľadávacie profily';

  @override
  String get privacyItineraries => 'Uložené trasy';

  @override
  String get privacySyncMode => 'Režim synchronizácie';

  @override
  String get privacySyncUserId => 'ID používateľa';

  @override
  String get privacySyncDescription =>
      'Keď je synchronizácia zapnutá, obľúbené, upozornenia, ignorované stanice a hodnotenia sú tiež uložené na serveri TankSync.';

  @override
  String get privacyExportSuccess => 'Údaje exportované do schránky';

  @override
  String get privacyExportCsvSuccess => 'Údaje CSV exportované do schránky';

  @override
  String get savedToDownloadsFolder => 'Uložené do priečinka Stiahnuté';

  @override
  String get privacyErrorLogCleared => 'Protokol chýb vymazaný';

  @override
  String get privacyDeleteTitle => 'Odstrániť všetky údaje?';

  @override
  String get privacyDeleteBody =>
      'Toto natrvalo odstráni:\n\n- Všetky obľúbené a údaje o staniciach\n- Všetky vyhľadávacie profily\n- Všetky cenové upozornenia\n- Celú históriu cien\n- Všetky uložené dáta v cache\n- Váš kľúč API\n- Všetky nastavenia aplikácie\n\nAplikácia sa resetuje do počiatočného stavu. Túto akciu nie je možné vrátiť späť.';

  @override
  String get privacyDeleteConfirm => 'Odstrániť všetko';

  @override
  String get yes => 'Áno';

  @override
  String get no => 'Nie';

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
  String get paymentMethods => 'Spôsoby platby';

  @override
  String get paymentMethodCash => 'Hotovosť';

  @override
  String get paymentMethodCard => 'Karta';

  @override
  String get paymentMethodContactless => 'Bezkontaktne';

  @override
  String get paymentMethodFuelCard => 'Palivová karta';

  @override
  String get paymentMethodApp => 'Aplikácia';

  @override
  String payWithApp(String app) {
    return 'Zaplatiť cez $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'V porovnaní s priemierom za posledné 3 tankovania ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Spotreba $value L/100 km, $delta oproti vášmu priemeru';
  }

  @override
  String get drivingMode => 'Jazdný režim';

  @override
  String get drivingExit => 'Ukončiť';

  @override
  String get drivingNearestStation => 'Najbližšia';

  @override
  String get drivingTapToUnlock => 'Klepnutím odomknúť';

  @override
  String get drivingSafetyTitle => 'Bezpečnostné upozornenie';

  @override
  String get drivingSafetyMessage =>
      'Nepoužívajte aplikáciu počas jazdy. Zastavte na bezpečnom mieste pred interakciou s obrazovkou. Vodič je vždy zodpovedný za bezpečnú prevádzku vozidla.';

  @override
  String get drivingSafetyAccept => 'Rozumiem';

  @override
  String get voiceAnnouncementsTitle => 'Hlasové oznámenia';

  @override
  String get voiceAnnouncementsDescription =>
      'Oznamovať blízke lacné stanice počas jazdy';

  @override
  String get voiceAnnouncementsEnabled => 'Zapnúť hlasové oznámenia';

  @override
  String get voiceAnnouncementProximityRadius => 'Polomer oznámenia';

  @override
  String get voiceAnnouncementCooldown => 'Interval opakovania';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximálna cena';

  @override
  String get consumptionStatsTitle => 'Štatistiky spotreby';

  @override
  String get addFillUp => 'Pridať tankovanie';

  @override
  String get noFillUpsTitle => 'Zatiaľ žiadne tankovania';

  @override
  String get noFillUpsSubtitle =>
      'Zaznamenajte prvé tankovanie a začnite sledovať spotrebu.';

  @override
  String get fillUpDate => 'Dátum';

  @override
  String get liters => 'Litre';

  @override
  String get odometerKm => 'Tachometer (km)';

  @override
  String get notesOptional => 'Poznámky (voliteľné)';

  @override
  String get statAvgConsumption => 'Priem. L/100km';

  @override
  String get statAvgCostPerKm => 'Priem. náklady/km';

  @override
  String get statTotalLiters => 'Celkové litre';

  @override
  String get statTotalSpent => 'Celkové výdavky';

  @override
  String get statFillUpCount => 'Tankovania';

  @override
  String get fieldRequired => 'Povinné';

  @override
  String get fieldInvalidNumber => 'Neplatné číslo';

  @override
  String get carbonDashboardTitle => 'Uhlíkový panel';

  @override
  String get carbonEmptyTitle => 'Zatiaľ žiadne údaje';

  @override
  String get carbonEmptySubtitle =>
      'Zaznamenajte tankovania a zobrazte váš uhlíkový panel.';

  @override
  String get carbonSummaryTotalCost => 'Celkové náklady';

  @override
  String get carbonSummaryTotalCo2 => 'Celkové CO2';

  @override
  String get monthlyCostsTitle => 'Mesačné náklady';

  @override
  String get monthlyEmissionsTitle => 'Mesačné emisie CO2';

  @override
  String get vehiclesTitle => 'Moje vozidlá';

  @override
  String get vehiclesMenuTitle => 'Moje vozidlá';

  @override
  String get vehiclesMenuSubtitle =>
      'Batéria, konektory, preferencie nabíjania';

  @override
  String get vehiclesEmptyMessage =>
      'Pridajte svoje auto na filtrovanie podľa konektora a odhadnutie nákladov na nabíjanie.';

  @override
  String get vehiclesWizardTitle => 'Moje vozidlá (voliteľné)';

  @override
  String get vehiclesWizardSubtitle =>
      'Pridajte auto pre predvyplnenie záznamu spotreby a zapnutie filtrov konektorov EV. Môžete preskočiť a pridať vozidlá neskôr.';

  @override
  String get vehiclesWizardNoneYet => 'Zatiaľ žiadne vozidlo.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vozidiel',
      one: '1 vozidlo',
    );
    return 'Máte $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Preskočiť nastavenie — vozidlá môžete pridať kedykoľvek z Nastavení.';

  @override
  String get fillUpVehicleLabel => 'Vozidlo';

  @override
  String get fillUpVehicleRequired => 'Vozidlo je povinné';

  @override
  String get reportScanError => 'Nahlásiť chybu skenovania';

  @override
  String get pickStationTitle => 'Vybrať stanicu';

  @override
  String get pickStationHelper =>
      'Začnite tankovanie zo známej stanice, aby sa ceny, značka a typ paliva vyplnili automaticky.';

  @override
  String get pickStationEmpty =>
      'Zatiaľ žiadne obľúbené stanice — pridajte ich z Vyhľadávania alebo Obľúbených, alebo preskočte a vyplňte ručne.';

  @override
  String get pickStationSkip => 'Preskočiť — pridať bez stanice';

  @override
  String get scanPayment => 'Skenovať platobný QR';

  @override
  String get qrPaymentBeneficiary => 'Príjemca';

  @override
  String get qrPaymentAmount => 'Suma';

  @override
  String get qrPaymentEpcTitle => 'SEPA platba';

  @override
  String get qrPaymentEpcEmpty => 'Žiadne dekódované polia';

  @override
  String get qrPaymentOpenInBank => 'Otvoriť v bankovej aplikácii';

  @override
  String get qrPaymentLaunchFailed =>
      'Nie je dostupná žiadna aplikácia na otvorenie tohto kódu';

  @override
  String get qrPaymentUnknownTitle => 'Nerozpoznaný kód';

  @override
  String get qrPaymentUnknownBody =>
      'This isn\'t a payment code SparKilo knows — it may be a loyalty or receipt code, or a payment scheme we haven\'t added yet. Nothing is wrong with your scan.';

  @override
  String get qrPaymentUnknownAction =>
      'Report it and we\'ll try to add the scheme in a future release.';

  @override
  String get qrPaymentRawHeading => 'What the code contains';

  @override
  String get qrPaymentCopyRaw => 'Kopírovať surový text';

  @override
  String get qrPaymentCopiedRaw => 'Skopírované do schránky';

  @override
  String get qrPaymentReport => 'Nahlásiť toto skenovanie';

  @override
  String get qrPaymentEpcCopied =>
      'Bankové údaje skopírované — vložte do vašej bankovej aplikácie';

  @override
  String get qrScannerGuidance => 'Nasmerujte kameru na QR kód';

  @override
  String get qrScannerPermissionDenied =>
      'Na skenovanie QR kódov je potrebný prístup ku kamere.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Prístup ku kamere bol zamietnutý. Otvorte nastavenia a udeľte ho.';

  @override
  String get qrScannerRetryPermission => 'Skúsiť znova';

  @override
  String get qrScannerOpenSettings => 'Otvoriť nastavenia';

  @override
  String get qrScannerTimeout =>
      'QR kód nebol detekovaný. Priblížte sa alebo skúste znova.';

  @override
  String get qrScannerRetry => 'Skúsiť znova';

  @override
  String get torchOn => 'Zapnúť blesk';

  @override
  String get torchOff => 'Vypnúť blesk';

  @override
  String get obdPermissionDenied =>
      'Udeľte oprávnenie Bluetooth v systémových nastaveniach';

  @override
  String get obdPickerTitle => 'Vybrať OBD2 adaptér';

  @override
  String get obdPickerScanning => 'Vyhľadávanie adaptérov…';

  @override
  String get obdPickerConnecting => 'Pripájanie…';

  @override
  String get tripMetricDistance => 'Vzdialenosť';

  @override
  String get tripMetricFuelUsed => 'Spotrebované palivo';

  @override
  String get tripMetricAvgConsumption => 'Priem.';

  @override
  String get tripMetricElapsed => 'Uplynulý čas';

  @override
  String get tripStop => 'Zastaviť záznam';

  @override
  String get tripPause => 'Pozastaviť';

  @override
  String get tripResume => 'Pokračovať';

  @override
  String get tripBannerRecording => 'Záznam jazdy';

  @override
  String get tripBannerPaused => 'Jazda pozastavená — klepnutím pokračujte';

  @override
  String get vehicleBaselineSectionTitle => 'Základná kalibrácia';

  @override
  String get vehicleBaselineEmpty =>
      'Zatiaľ žiadne vzorky — spustite OBD2 jazdu a začnite zaznamenávať palivový profil vozidla.';

  @override
  String get vehicleBaselineProgress =>
      'Naučené zo vzoriek v rôznych jazdných situáciách.';

  @override
  String get vehicleBaselineReset => 'Resetovať základňu jazdnej situácie';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Resetovať základňu jazdnej situácie?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Toto vymaže všetky naučené vzorky pre toto vozidlo. Vrátite sa k predvoleným hodnotám studeného štartu, kým nové jazdy znova nevyplnia profil.';

  @override
  String get vehicleBaselineShowDetails => 'Zobraziť rozpis podľa situácií';

  @override
  String get vehicleBaselineHideDetails => 'Skryť rozpis podľa situácií';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Ešte nezistené: $situations. Tieto jazdné situácie stále majú 0 vzoriek, takže referenčná hodnota je neúplná.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adaptér';

  @override
  String get vehicleAdapterEmpty =>
      'Nie je spárovaný žiadny adaptér. Spárujte ho, aby sa aplikácia mohla automaticky znova pripojiť.';

  @override
  String get vehicleAdapterUnnamed => 'Neznámy adaptér';

  @override
  String get vehicleAdapterPair => 'Spárovať adaptér';

  @override
  String get vehicleAdapterForget => 'Zabudnúť adaptér';

  @override
  String get syncBaselinesToggleTitle => 'Zdieľať naučené profily vozidiel';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Nahrávať základné hodnoty spotreby pre každé vozidlo, aby ich mohlo použiť druhé zariadenie.';

  @override
  String get obd2StatusConnected => 'OBD2 adaptér: pripojený';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adaptér: potrebné oprávnenie Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Pripravený na záznam jazdy.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Udeľte oprávnenie Bluetooth v systémových nastaveniach pre automatické opätovné pripojenie.';

  @override
  String get obd2StatusNoAdapter => 'Žiadny adaptér nie je spárovaný';

  @override
  String get obd2StatusForget => 'Zabudnúť adaptér';

  @override
  String get tripHistoryTitle => 'História jázd';

  @override
  String get tripHistoryEmptyTitle => 'Zatiaľ žiadne jazdy';

  @override
  String get tripHistoryUnknownDate => 'Neznámy dátum';

  @override
  String get situationIdle => 'Voľnobeh';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Mestská';

  @override
  String get situationHighway => 'Diaľnica';

  @override
  String get situationDecel => 'Spomaľovanie';

  @override
  String get situationClimbing => 'Stúpanie / zaťaženie';

  @override
  String get situationColdStart => 'Studený štart';

  @override
  String get situationSustainedLoad => 'Trvalá záťaž / vlečenie';

  @override
  String get situationPartialDecel => 'Voľný beh';

  @override
  String get situationHardAccel => 'Prudké zrýchlenie';

  @override
  String get situationFuelCut => 'Odpojenie paliva — voľný beh';

  @override
  String get tripSummaryAutoSaved => 'Jazda uložená automaticky';

  @override
  String get tripSummaryDelete => 'Odstrániť túto jazdu';

  @override
  String get vehicleFuelNotSet => 'Nenastavené';

  @override
  String get wizardVehicleDefaultBadge => 'Predvolené';

  @override
  String get wizardProfileChoiceHint =>
      'Vyberte, ako chcete používať aplikáciu. Toto môžete neskôr zmeniť v Nastaveniach.';

  @override
  String get wizardProfileChoiceFooter =>
      'Svoju voľbu môžete kedykoľvek zmeniť v Nastaveniach → Režim používania.';

  @override
  String get wizardProfileBasicName => 'Základný';

  @override
  String get wizardProfileBasicDescription =>
      'Najlacnejšie palivo a ceny nabíjania EV v okolí. Obľúbené a cenové upozornenia.';

  @override
  String get wizardProfileMediumName => 'Stredný';

  @override
  String get wizardProfileMediumDescription =>
      'Všetko v Základnom, plus ručné sledovanie tankovania paliva a nabíjania EV.';

  @override
  String get wizardProfileFullName => 'Plný';

  @override
  String get wizardProfileFullDescription =>
      'Všetko v Strednom, plus automatický záznam jázd OBD2, jazdné skóre a vernostné karty.';

  @override
  String get wizardProfileCustomName => 'Vlastný';

  @override
  String get useModeSectionHint =>
      'Prispôsobte aplikáciu vášmu skutočnému využitiu. Výber predvoľby aktivuje zodpovedajúcu sadu funkcií.';

  @override
  String get useModeCustomSettingsDescription =>
      'Vaša kombinácia funkcií nezodpovedá žiadnej predvoľbe. Vyberte predvoľbu pre prepísanie alebo pokračujte v úprave jednotlivých funkcií nižšie.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Režim používania nastavený na $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Predvolené vozidlo (voliteľné)';

  @override
  String get profileDefaultVehicleNone => 'Žiadne predvolené';

  @override
  String get profileFuelFromVehicleHint =>
      'Typ paliva sa odvodzuje z vášho predvoleného vozidla. Zrušte vozidlo pre priamy výber paliva.';

  @override
  String get consumptionNoVehicleTitle => 'Najprv pridajte vozidlo';

  @override
  String get consumptionNoVehicleBody =>
      'Tankovania sa pripisujú vozidlu. Pridajte svoje auto pre začatie záznamu spotreby.';

  @override
  String get vehicleAdd => 'Pridať vozidlo';

  @override
  String get vehicleAddTitle => 'Pridať vozidlo';

  @override
  String get vehicleEditTitle => 'Upraviť vozidlo';

  @override
  String get vehicleDeleteTitle => 'Odstrániť vozidlo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Odstrániť \"$name\" z vašich profilov?';
  }

  @override
  String get vehicleNameLabel => 'Názov';

  @override
  String get vehicleNameHint => 'napr. Moje Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Spaľovací';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Elektrický';

  @override
  String get vehicleEvSectionTitle => 'Elektrický';

  @override
  String get vehicleCombustionSectionTitle => 'Spaľovací';

  @override
  String get vehicleBatteryLabel => 'Kapacita batérie (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maximálny výkon nabíjania (kW)';

  @override
  String get vehicleConnectorsLabel => 'Podporované konektory';

  @override
  String get vehicleMinSocLabel => 'Min. SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max. SoC %';

  @override
  String get vehicleTankLabel => 'Objem nádrže (L)';

  @override
  String get vehiclePowerLabel => 'Výkon motora (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps k';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Preferovaný typ paliva';

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
  String get connectorThreePin => '3-kolíkový';

  @override
  String get evShowOnMap => 'Zobraziť EV stanice';

  @override
  String get evAvailableOnly => 'Iba dostupné';

  @override
  String get evMinPower => 'Min. výkon';

  @override
  String get evStatusAvailable => 'Dostupná';

  @override
  String get evStatusOccupied => 'Obsadená';

  @override
  String get evStatusOutOfOrder => 'Mimo prevádzky';

  @override
  String get evStatusPartial => 'Čiastočne dostupné';

  @override
  String get openOnlyFilter => 'Iba otvorené';

  @override
  String get saveAsDefaults => 'Uložiť ako predvolené';

  @override
  String get criteriaSavedToProfile => 'Uložené ako predvolené';

  @override
  String get updatingFavorites => 'Aktualizujú sa obľúbené...';

  @override
  String get fetchingLatestPrices => 'Načítavajú sa najnovšie ceny';

  @override
  String get noDataAvailable => 'Žiadne údaje';

  @override
  String get searchToSeeMap => 'Vyhľadajte pre zobrazenie staníc na mape';

  @override
  String get evPowerAny => 'Akýkoľvek';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Poloha';

  @override
  String get sectionPrivacyData => 'Súkromie a údaje';

  @override
  String get sectionAdvancedDeveloper => 'Pokročilé a vývojárske';

  @override
  String get tooltipBack => 'Späť';

  @override
  String get tooltipClose => 'Zavrieť';

  @override
  String get tooltipShare => 'Zdieľať';

  @override
  String get tooltipClearSearch => 'Vymazať vstup vyhľadávania';

  @override
  String get minimalDriveInstantConsumption => 'Okamžitá spotreba';

  @override
  String get minimalDriveBehaviour => 'Štýl jazdy';

  @override
  String get coachingShiftUp => 'Zaraď vyššie';

  @override
  String get coachingShiftDown => 'Zaraď nižšie';

  @override
  String get coachingEasePedal => 'Pusť plyn';

  @override
  String get coachingVoiceHardAcceleration => 'Jemnejšie na plyn';

  @override
  String get coachingVoiceHarshBraking => 'Skúste brzdiť plynulejšie';

  @override
  String get coachingVoiceShiftUp => 'Zaraďte vyšší stupeň a ušetrite palivo';

  @override
  String get coachingVoiceShiftDown => 'Zaraďte nižší stupeň, motor ťaží';

  @override
  String get coachingVoiceEasePedal => 'Uvoľnite pedál a znížte spotrebu';

  @override
  String get coachingVoiceLiftOff =>
      'Zdvihnite nohu z plynu a dajte sa do voľného behu';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Pozerajte ďalej dopredu a skôr zdvihnite nohu';

  @override
  String get coachingVoiceSmoothAccel => 'Zrýchľujte plynulejšie';

  @override
  String get coachingVoiceSharpCorner =>
      'Prechádzajte zákruty o niečo plynulejšie';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'To bolo veľmi prudké brzdenie — držte väčší odstup';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Veľmi prudké zrýchlenie — to naozaj spaľuje palivo';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Veľmi ostrá zákruta — pomaly dnu, plynulo von';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount prudkých manévrov.',
      few: '$harshCount prudké manévre.',
      one: 'Jeden prudký manéver.',
      zero: 'Pekne plynulo — žiadne prudké manévre.',
    );
    return 'Jazda uložená: $distanceKm kilometrov, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litra na 100 kilometrov';
  }

  @override
  String get voiceCoachingSettingTitle => 'Hlasový koučing jazdy';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Počúvajte hlasové tipy počas jazdy — prudké zrýchlenie, prudké brzdenie a rady o radení';

  @override
  String get tooltipUseGps => 'Použiť GPS polohu';

  @override
  String get tooltipShowPassword => 'Zobraziť heslo';

  @override
  String get tooltipHidePassword => 'Skryť heslo';

  @override
  String get evConnectorsLabel => 'Dostupné konektory';

  @override
  String get evConnectorsNone => 'Žiadne informácie o konektore';

  @override
  String get switchToEmail => 'Prepnúť na e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Zachovať údaje, pridať prihlásenie z iných zariadení';

  @override
  String get switchToAnonymousAction => 'Prepnúť na anonymný';

  @override
  String get switchToAnonymousSubtitle =>
      'Zachovať lokálne údaje, použiť novú anonymnú reláciu';

  @override
  String get linkDevice => 'Prepojiť zariadenie';

  @override
  String get shareDatabase => 'Zdieľať databázu';

  @override
  String get disconnectAction => 'Odpojiť';

  @override
  String get disconnectSubtitle =>
      'Zastaviť synchronizáciu (lokálne údaje zachované)';

  @override
  String get deleteAccountAction => 'Odstrániť účet';

  @override
  String get deleteAccountSubtitle =>
      'Natrvalo odstrániť všetky serverové údaje';

  @override
  String get localOnly => 'Iba lokálne';

  @override
  String get localOnlySubtitle =>
      'Voliteľné: synchronizujte obľúbené, upozornenia a hodnotenia naprieč zariadeniami';

  @override
  String get tankSyncSchemaOutdatedTitle =>
      'Cloudová databáza potrebuje aktualizáciu';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Vaša vlastná hostovaná schéma TankSync je zastaraná — niektoré údaje sa nemôžu synchronizovať. Otvorte sprievodcu synchronizáciou a spustite aktualizačný SQL vo svojom projekte Supabase.';

  @override
  String get setupCloudSync => 'Nastaviť synchronizáciu s cloudom';

  @override
  String get disconnectTitle => 'Odpojiť TankSync?';

  @override
  String get disconnectBody =>
      'Synchronizácia s cloudom bude zakázaná. Vaše lokálne údaje (obľúbené, upozornenia, história) sú zachované na tomto zariadení. Serverové údaje sa neodstránia.';

  @override
  String get deleteAccountTitle => 'Odstrániť účet?';

  @override
  String get deleteAccountBody =>
      'Toto natrvalo odstráni všetky vaše údaje zo servera (obľúbené, upozornenia, hodnotenia, trasy). Lokálne údaje na tomto zariadení sú zachované.\n\nTúto akciu nie je možné vrátiť späť.';

  @override
  String get switchToAnonymousTitle => 'Prepnúť na anonymný?';

  @override
  String get switchToAnonymousBody =>
      'Budete odhlásený z e-mailového účtu a budete pokračovať s novou anonymnou reláciou.\n\nVaše lokálne údaje (obľúbené, upozornenia) zostanú na tomto zariadení a budú synchronizované s novým anonymným účtom.';

  @override
  String get switchAction => 'Prepnúť';

  @override
  String get helpBannerCriteria =>
      'Predvolené hodnoty vášho profilu sú predvyplnené. Upravte kritériá nižšie pre spresnenie vyhľadávania.';

  @override
  String get helpBannerAlerts =>
      'Nastavte cenovú hranicu pre stanicu. Budete upozornení, keď ceny klesnú pod ňu. Kontroly prebiehajú každých 30 minút.';

  @override
  String get helpBannerConsumption =>
      'Zaznamenávajte každé tankovanie pre sledovanie reálnej spotreby a uhlíkovej stopy CO₂. Potiahnutím doľava odstránite záznam.';

  @override
  String get helpBannerVehicles =>
      'Pridajte vaše vozidlá, aby sa tankovania a preferencie paliva predvypĺňali správne. Prvé vozidlo sa stane predvoleným.';

  @override
  String get syncNow => 'Synchronizovať teraz';

  @override
  String get onboardingPreferencesTitle => 'Vaše preferencie';

  @override
  String get onboardingZipHelper => 'Používa sa, keď GPS nie je dostupné';

  @override
  String get onboardingRadiusHelper => 'Väčší polomer = viac výsledkov';

  @override
  String get onboardingPrivacy =>
      'Tieto nastavenia sú uložené iba na vašom zariadení a nikdy sa nezdieľajú.';

  @override
  String get onboardingLandingTitle => 'Domovská obrazovka';

  @override
  String get onboardingLandingHint =>
      'Vyberte, ktorá obrazovka sa otvorí pri spustení aplikácie.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Zostaňte mimo aplikácie — ale nezatvárajte ju.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Otvorte Sparkilo raz po každom reštarte.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple prebudí Sparkilo iba po tom, čo ste ho otvorili aspoň raz od reštartu telefónu. Potom sa vaše jazdy zaznamenávajú automaticky.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Nepretiahnite Sparkilo preč v prepínači aplikácií.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Vynútené ukončenie\" povie iOS, aby prestal spúšťať aplikáciu. Vaše jazdy sa prestanú zaznamenávať, kým znova neotvoríte Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Keď iOS žiada o polohu \"Vždy\", prosím povedzte áno.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Záložná funkcia, ktorá zaznamenáva jazdu pri pomalom OBD2 adaptéri, potrebuje polohu na pozadí. Nikdy ju nezdieľame.';

  @override
  String get scanReceipt => 'Skenovať doklad';

  @override
  String get brandFilterHighway => 'Diaľnica';

  @override
  String get ratingModeLocal => 'Lokálne';

  @override
  String get ratingModePrivate => 'Súkromné';

  @override
  String get ratingModeShared => 'Zdieľané';

  @override
  String get ratingDescLocal => 'Hodnotenia uložené iba na tomto zariadení';

  @override
  String get ratingDescPrivate =>
      'Synchronizované s vašou databázou (nie sú viditeľné pre ostatných)';

  @override
  String get ratingDescShared =>
      'Viditeľné pre všetkých používateľov vašej databázy';

  @override
  String get errorNoEvApiKey =>
      'Kľúč API OpenChargeMap nie je nakonfigurovaný. Pridajte ho v Nastaveniach pre vyhľadávanie EV nabíjacích staníc.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Poskytovateľ dát ($host) poskytuje vypršaný alebo neplatný TLS certifikát. Aplikácia nemôže načítať dáta z tohto zdroja, kým to poskytovateľ neopraví. Kontaktujte prosím $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nedostupné. Používa sa $current.';
  }

  @override
  String get errorTitleApiKey => 'Vyžaduje sa kľúč API';

  @override
  String get errorTitleLocation => 'Poloha nedostupná';

  @override
  String get errorHintNoStations =>
      'Skúste zvýšiť polomer vyhľadávania alebo vyhľadajte iné miesto.';

  @override
  String get errorHintApiKey => 'Nakonfigurujte kľúč API v Nastaveniach.';

  @override
  String get errorHintConnection =>
      'Skontrolujte internetové pripojenie a skúste znova.';

  @override
  String get errorHintRouting =>
      'Výpočet trasy zlyhal. Skontrolujte internetové pripojenie a skúste znova.';

  @override
  String get errorHintFallback =>
      'Skúste znova alebo vyhľadajte podľa PSČ / názvu mesta.';

  @override
  String get alertsLoadErrorTitle => 'Upozornenia sa nepodarilo načítať';

  @override
  String get detailsLabel => 'Podrobnosti';

  @override
  String get remove => 'Odstrániť';

  @override
  String get showKey => 'Zobraziť kľúč';

  @override
  String get hideKey => 'Skryť kľúč';

  @override
  String get syncOptionalTitle => 'TankSync je voliteľný';

  @override
  String get syncOptionalDescription =>
      'Vaša aplikácia funguje plnohodnotne bez synchronizácie s cloudom. TankSync vám umožňuje synchronizovať obľúbené, upozornenia a hodnotenia naprieč zariadeniami pomocou Supabase (dostupná bezplatná úroveň).';

  @override
  String get syncHowToConnectQuestion => 'Ako sa chcete pripojiť?';

  @override
  String get syncCreateOwnTitle => 'Vytvoriť vlastnú databázu';

  @override
  String get syncCreateOwnSubtitle =>
      'Bezplatný projekt Supabase — prevedieme vás krok za krokom';

  @override
  String get syncJoinExistingTitle => 'Pripojiť sa k existujúcej databáze';

  @override
  String get syncJoinExistingSubtitle =>
      'Naskenujte QR kód od vlastníka databázy alebo vložte prihlásavacie údaje';

  @override
  String get syncChooseAccountType => 'Vyberte typ účtu';

  @override
  String get syncAccountTypeAnonymous => 'Anonymný';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Okamžitý prístup, nevyžaduje e-mail. Dáta viazané na toto zariadenie.';

  @override
  String get syncAccountTypeEmail => 'E-mailový účet';

  @override
  String get syncAccountTypeEmailDesc =>
      'Prihláste sa z akéhokoľvek zariadenia. Obnovte dáta pri strate telefónu.';

  @override
  String get syncHaveAccountSignIn => 'Máte účet? Prihláste sa';

  @override
  String get syncCreateNewAccount => 'Vytvoriť nový účet';

  @override
  String get syncTestConnection => 'Otestovať pripojenie';

  @override
  String get syncTestingConnection => 'Testovanie...';

  @override
  String get syncConnectButton => 'Pripojiť';

  @override
  String get syncConnectingButton => 'Pripájanie...';

  @override
  String get syncDatabaseReady => 'Databáza pripravená!';

  @override
  String get syncDatabaseNeedsSetup => 'Databáza vyžaduje nastavenie';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Chýba';

  @override
  String get syncSqlEditorInstructions =>
      'Skopírujte SQL nižšie a spustite ho v editore SQL Supabase (Ovládací panel → SQL Editor → Nový dopyt → Vložiť → Spustiť)';

  @override
  String get syncCopySqlButton => 'Kopírovať SQL do schránky';

  @override
  String get syncRecheckSchemaButton => 'Znovu skontrolovať schému';

  @override
  String get syncSchemaOutdated =>
      'Vaša schéma TankSync je zastaraná — spustite znova nižšie uvedený inštalačný SQL, aby sa zapli najnovšie synchronizované funkcie.';

  @override
  String get syncDoneButton => 'Hotovo';

  @override
  String syncSignedInAs(String email) {
    return 'Prihlásený ako $email';
  }

  @override
  String get syncEmailDescription =>
      'Vaše dáta sa synchronizujú naprieč všetkými zariadeniami s týmto e-mailom.';

  @override
  String get syncSwitchToAnonymousTitle => 'Prepnúť na anonymný';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Pokračovať bez e-mailu, nová anonymná relácia';

  @override
  String get syncGuestDescription => 'Anonymný, nevyžaduje e-mail.';

  @override
  String get syncOrDivider => 'alebo';

  @override
  String get syncHowToSyncQuestion => 'Ako chcete synchronizovať?';

  @override
  String get syncOfflineDescription =>
      'Vaša aplikácia funguje plnohodnotne offline. Synchronizácia s cloudom je voliteľná.';

  @override
  String get syncModeCommunityTitle => 'Komunita Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Zdieľaná databáza prevádzkovaná vývojárom — nižšie vidíte, čo sa synchronizuje';

  @override
  String get syncModePrivateTitle => 'Súkromná databáza';

  @override
  String get syncModePrivateSubtitle =>
      'Vlastný Supabase — plná kontrola nad dátami';

  @override
  String get syncModeGroupTitle => 'Pripojiť sa ku skupine';

  @override
  String get syncModeGroupSubtitle =>
      'Zdieľaná databáza pre rodinu alebo priateľov';

  @override
  String get syncPrivacyShared => 'Zdieľané';

  @override
  String get syncPrivacyPrivate => 'Súkromné';

  @override
  String get syncPrivacyGroup => 'Skupina';

  @override
  String get syncStayOfflineButton => 'Zostať offline';

  @override
  String get syncSuccessTitle => 'Úspešne pripojené!';

  @override
  String get syncSuccessDescription =>
      'Vaše dáta sa budú teraz automaticky synchronizovať.';

  @override
  String get syncWizardTitleConnect => 'Pripojiť TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Vaša databáza';

  @override
  String get syncSetupTitleJoinGroup => 'Pripojiť sa ku skupine';

  @override
  String get syncSetupTitleAccount => 'Váš účet';

  @override
  String get syncWizardBack => 'Späť';

  @override
  String get syncWizardNext => 'Ďalej';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Vytvoriť projekt Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Klepnite na \"Otvoriť Supabase\" nižšie\n2. Vytvorte bezplatný účet (ak ho nemáte)\n3. Kliknite na \"Nový projekt\"\n4. Vyberte názov a región\n5. Počkajte ~2 minúty na spustenie';

  @override
  String get syncWizardOpenSupabase => 'Otvoriť Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Povoliť anonymné prihlásenie';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Na vašom ovládacom paneli Supabase:\n   Autentifikácia → Poskytovatelia\n2. Nájdite \"Anonymné prihlásenie\"\n3. Zapnite prepínač\n4. Kliknite na \"Uložiť\"';

  @override
  String get syncWizardOpenAuthSettings => 'Otvoriť nastavenia autentifikácie';

  @override
  String get syncWizardCopyCredentialsTitle =>
      'Skopírovať vaše prihlasovacie údaje';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Prejdite na Nastavenia → API na vašom ovládacom paneli\n2. Skopírujte \"URL projektu\"\n3. Skopírujte kľúč \"anon public\"\n4. Vložte ich nižšie';

  @override
  String get syncWizardOpenApiSettings => 'Otvoriť nastavenia API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Pripojiť sa k existujúcej databáze';

  @override
  String get syncWizardScanQrCode => 'Skenovať QR kód';

  @override
  String get syncWizardAskOwnerQr =>
      'Požiadajte vlastníka databázy, aby vám ukázal svoj QR kód\n(Nastavenia → TankSync → Zdieľať)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Požiadajte vlastníka databázy o zobrazenie QR kódu';

  @override
  String get syncWizardEnterManuallyTitle => 'Zadať ručne';

  @override
  String get syncWizardOrEnterManually => 'alebo zadajte ručne';

  @override
  String get syncWizardUrlHelperText =>
      'Medzery a zalomenia riadkov sú automaticky odstraňované';

  @override
  String get syncCredentialsPrivateHint =>
      'Zadajte prihlasovacie údaje vášho projektu Supabase. Nájdete ich na ovládacom paneli pod Nastavenia > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL databázy';

  @override
  String get syncCredentialsAccessKeyLabel => 'Prístupový kľúč';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Heslo';

  @override
  String get authConfirmPasswordLabel => 'Potvrdiť heslo';

  @override
  String get authPleaseEnterEmail => 'Prosím zadajte váš e-mail';

  @override
  String get authInvalidEmail => 'Neplatná e-mailová adresa';

  @override
  String get authPasswordsDoNotMatch => 'Heslá sa nezhodujú';

  @override
  String get authConnectAnonymously => 'Pripojiť anonymne';

  @override
  String get authCreateAccountAndConnect => 'Vytvoriť účet a pripojiť';

  @override
  String get authSignInAndConnect => 'Prihlásiť sa a pripojiť';

  @override
  String get authAnonymousSegment => 'Anonymný';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Okamžitý prístup, nevyžaduje e-mail. Dáta viazané na toto zariadenie.';

  @override
  String get authEmailDescription =>
      'Prihláste sa z akéhokoľvek zariadenia. Obnovte dáta pri strate telefónu.';

  @override
  String get authSyncAcrossDevices =>
      'Automaticky synchronizovať dáta naprieč všetkými zariadeniami.';

  @override
  String get authNewHereCreateAccount => 'Prvýkrát tu? Vytvoriť účet';

  @override
  String get linkDeviceScreenTitle => 'Prepojiť zariadenie';

  @override
  String get linkDeviceThisDeviceLabel => 'Toto zariadenie';

  @override
  String get linkDeviceShareCodeHint =>
      'Zdieľajte tento kód s vaším iným zariadením:';

  @override
  String get linkDeviceNotConnected => 'Nepripojené';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopírovať kód';

  @override
  String get linkDeviceImportSectionTitle => 'Importovať z iného zariadenia';

  @override
  String get linkDeviceImportDescription =>
      'Zadajte kód zariadenia z vášho iného zariadenia pre import obľúbených, upozornení, vozidiel a záznamu spotreby. Každé zariadenie si uchováva vlastný profil a predvolené hodnoty.';

  @override
  String get linkDeviceCodeFieldLabel => 'Kód zariadenia';

  @override
  String get linkDeviceCodeFieldHint => 'Vložte UUID z iného zariadenia';

  @override
  String get linkDeviceImportButton => 'Importovať dáta';

  @override
  String get linkDeviceHowItWorksTitle => 'Ako to funguje';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Na zariadení A: skopírujte kód zariadenia uvedený vyššie\n2. Na zariadení B: vložte ho do poľa \"Kód zariadenia\"\n3. Klepnite na \"Importovať dáta\" pre zlúčenie obľúbených, upozornení, vozidiel a záznamov spotreby\n4. Obe zariadenia budú mať všetky kombinované dáta\n\nKaždé zariadenie si uchováva vlastnú anonymnú identitu a vlastný profil (preferované palivo, predvolené vozidlo, úvodná obrazovka). Dáta sa zlúčia, nie presunú.';

  @override
  String get vehicleSetActive => 'Nastaviť ako aktívne';

  @override
  String get swipeHide => 'Skryť';

  @override
  String get yourRating => 'Vaše hodnotenie';

  @override
  String get noStorageUsed => 'Žiadne využité úložisko';

  @override
  String storageSegmentSemantics(String category, String size, int percent) {
    return '$category: $size, $percent% of the total';
  }

  @override
  String get aboutReportBug => 'Nahlásiť chybu / Navrhnúť funkciu';

  @override
  String get aboutSupportProject => 'Podporiť tento projekt';

  @override
  String get aboutSupportDescription =>
      'Táto aplikácia je bezplatná, open source a bez reklám. Ak vám je užitočná, zvážte podporu vývojára.';

  @override
  String get reportIssueTitle => 'Nahlásiť problém';

  @override
  String get enterCorrection => 'Prosím zadajte opravu';

  @override
  String get reportNoBackendAvailable =>
      'Správu sa nepodarilo odoslať: pre túto krajinu nie je nakonfigurovaná žiadna služba hlásení. Zapnite TankSync v Nastaveniach pre odosielanie komunitných hlásení.';

  @override
  String get correctName => 'Správny názov stanice';

  @override
  String get correctAddress => 'Správna adresa';

  @override
  String get wrongE85Price => 'Nesprávna cena E85';

  @override
  String get wrongE98Price => 'Nesprávna cena Super 98';

  @override
  String get wrongLpgPrice => 'Nesprávna cena LPG';

  @override
  String get wrongStationName => 'Nesprávny názov stanice';

  @override
  String get wrongStationAddress => 'Nesprávna adresa';

  @override
  String get independentStation => 'Nezávislá stanica';

  @override
  String get serviceRemindersSection => 'Servisné pripomienky';

  @override
  String get serviceRemindersEmpty =>
      'Zatiaľ žiadne pripomienky — vyberte predvoľbu vyššie.';

  @override
  String get addServiceReminder => 'Pridať pripomienku';

  @override
  String get serviceReminderPresetOil => 'Olej (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Výmena oleja';

  @override
  String get serviceReminderPresetTires => 'Pneumatiky (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Pneumatiky';

  @override
  String get serviceReminderPresetInspection => 'Prehliadka (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Prehliadka';

  @override
  String get serviceReminderLabel => 'Označenie';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Posledný servis';

  @override
  String get serviceReminderMarkDone => 'Označiť ako hotové';

  @override
  String get serviceReminderDueTitle => 'Servis splatný';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label je splatný — $kmOver km po intervale.';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '$label je práve na rade.';
  }

  @override
  String get vinConfirmTitle => 'Je to vaše auto?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-valec, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Čiastočné informácie (offline). Môžete upraviť nižšie.';

  @override
  String get vinDecodeError => 'Tento VIN sa nepodarilo dekódovať';

  @override
  String get vinInvalidFormat => 'Neplatný formát VIN';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2 pripojenie prerušené — záznam pozastavený';

  @override
  String get obd2PauseBannerResume => 'Obnoviť záznam';

  @override
  String get obd2PauseBannerEnd => 'Ukončiť záznam';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Záznam cez GPS — OBD2 sa znova pripája';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Záznam pomocou GPS — čakanie na adaptér OBD2';

  @override
  String get alertsStationSectionTitle => 'Alerty staníc';

  @override
  String get alertsStationAdd => 'Pridať alert stanice';

  @override
  String get alertsRadiusSectionTitle => 'Upozornenia v okruhu';

  @override
  String get alertsRadiusAdd => 'Pridať upozornenie v okruhu';

  @override
  String get alertsRadiusEmptyTitle => 'Zatiaľ žiadne upozornenia v okruhu';

  @override
  String get alertsRadiusEmptyCta => 'Vytvoriť upozornenie v okruhu';

  @override
  String get alertsRadiusCreateTitle => 'Vytvoriť upozornenie v okruhu';

  @override
  String get alertsRadiusLabelHint => 'Označenie (napr. Domov nafta)';

  @override
  String get alertsRadiusFuelType => 'Typ paliva';

  @override
  String get alertsRadiusKm => 'Polomer (km)';

  @override
  String get alertsRadiusCenterGps => 'Použiť moju polohu';

  @override
  String get alertsRadiusCenterPostalCode => 'PSČ';

  @override
  String get alertsRadiusSave => 'Uložiť';

  @override
  String get alertsRadiusCancel => 'Zrušiť';

  @override
  String radiusAlertDeleted(String name) {
    return 'Polohový alert \"$name\" vymazaný';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 pripojený: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Spárovať OBD2 adaptér';

  @override
  String get fillUpSavedSnackbar => 'Tankovanie uložené';

  @override
  String get notFoundTitle => 'Stránka nenájdená';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nenájdené.';
  }

  @override
  String get notFoundHomeButton => 'Domov';

  @override
  String get consumptionTabHiddenNotice =>
      'Karta Spotreba bola skrytá nastaveniami vášho profilu.';

  @override
  String stationSourceFlagTooltip(String country, String source) {
    return 'Prices from $country — $source';
  }

  @override
  String get decisionBestValue => 'Best value';

  @override
  String get decisionCheapest => 'Cheapest';

  @override
  String get decisionClosest => 'Closest';

  @override
  String get decisionReasonBestValue => 'Best balance of price and detour';

  @override
  String decisionReasonSaves(String amount, String volume, String distance) {
    return 'Saves $amount on $volume · $distance more driving';
  }

  @override
  String decisionReasonBreakEven(String volume) {
    return 'Only worth the detour from $volume up';
  }

  @override
  String get decisionValueUnavailable =>
      'Record a fill-up and the detour can be priced, not just the pump';

  @override
  String decisionShowAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show all $count stations',
      one: 'Show the one station',
    );
    return '$_temp0';
  }

  @override
  String decisionAssumption(String consumption, String volume) {
    return 'Based on $consumption and $volume';
  }

  @override
  String get priceFreshnessFresh => 'Fresh price';

  @override
  String get priceFreshnessRecent => 'Recent price';

  @override
  String get priceFreshnessAging => 'Aging price';

  @override
  String get priceFreshnessStale => 'Old price';

  @override
  String get priceFreshnessUnknown => 'Price age unknown';

  @override
  String priceFreshnessTooltip(String band, String stamp) {
    return '$band · $stamp';
  }

  @override
  String get priceLabel => 'Price';

  @override
  String get priceFreshnessLabel => 'Price freshness';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get availabilityNotReported => 'Not reported';

  @override
  String get refuelQuantityTitle => 'How much do you usually buy?';

  @override
  String get refuelQuantityExplainer =>
      'Best value compares what a refuel really costs, so it needs a rough volume. Sparkilo uses the median of your own fill-ups until you say otherwise.';

  @override
  String get refuelQuantityMeasured => 'Use my fill-up history';

  @override
  String get refuelQuantityFullTank => 'A full tank';

  @override
  String get refuelQuantityChange => 'Change';

  @override
  String refuelQuantityMeasuredValue(String volume) {
    return '$volume (from your fill-ups)';
  }

  @override
  String refuelConsumptionMeasured(String consumption) {
    return '$consumption (measured)';
  }

  @override
  String get refuelConsumptionMissing => 'No consumption yet';

  @override
  String get mapSheetViewDetails => 'View station details';

  @override
  String get startupFailureTitle => 'Sparkilo couldn\'t start';

  @override
  String get startupFailureMessage =>
      'Sparkilo could not finish starting up. Your saved data has not been touched.';

  @override
  String get startupFailureGuidance =>
      'Close the app and open it again. If it keeps happening, check for an update: this is almost always a fault in the app rather than in your data. Do not clear the app\'s storage — that would delete your favourites and history without fixing anything.';

  @override
  String priceIsForFuel(String fuel) {
    return 'This price is for $fuel — not the fuel you selected, which this station does not sell';
  }

  @override
  String get shellSwipeCoachMark =>
      'Swipe down to hide the bars and use the whole screen';

  @override
  String get shellBarHiddenAnnounce =>
      'Navigation hidden. Swipe up from the bottom, or long-press the button, to bring it back.';

  @override
  String get shellBarShownAnnounce => 'Navigation shown.';

  @override
  String get shellBarToggleHint => 'Long-press to hide or show the navigation';

  @override
  String get swipeBetweenTabsHint =>
      'Tip: potiahnutím doľava alebo doprava prepínajte medzi kartami.';

  @override
  String get discardChangesTitle => 'Zahodiť zmeny?';

  @override
  String get discardChangesBody =>
      'Máte neuložené zmeny. Odchodom ich zahodíte.';

  @override
  String get discardChangesConfirm => 'Zahodiť';

  @override
  String get discardChangesKeepEditing => 'Pokračovať v úprave';

  @override
  String get tankSyncSectionSubtitle =>
      'Synchronizácia s cloudom naprieč vašimi zariadeniami';

  @override
  String get mapUnavailable => 'Mapa nie je k dispozícii';

  @override
  String get routeNameHintExample => 'napr. Paríž → Lyon';

  @override
  String get priceStatsCurrent => 'Aktuálna';

  @override
  String get tankerkoenigApiKeyLabel => 'Kľúč API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Kľúč API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Ťuknutím aktualizujete polohu GPS';

  @override
  String get nameLabel => 'Názov';

  @override
  String get obd2ErrorPermissionDenied =>
      'Na pripojenie k adaptéru OBD2 je potrebné povolenie Bluetooth.';

  @override
  String get obd2ErrorBluetoothOff => 'Zapnite Bluetooth a skúste to znova.';

  @override
  String get obd2ErrorScanTimeout =>
      'V blízkosti sa nenašiel žiadny adaptér OBD2. Skontrolujte, či je zapojený a zapnutý.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Adaptér OBD2 neodpovedal. Zapnite zapaľovanie a skúste to znova.';

  @override
  String get obd2ErrorEngineOff =>
      'Z vozidla neprichádzajú žiadne údaje — naštartujte motor a skúste to znova.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adaptér OBD2 odoslal nerozpoznanú odpoveď. Možno nie je kompatibilný — skúste iný adaptér.';

  @override
  String get obd2ErrorDisconnected =>
      'Adaptér OBD2 sa odpojil. Pripojte sa znova a skúste to znova.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adaptér vyžaduje párovanie Bluetooth. Odpojte adaptér, znova ho zapojte a do 5 minút to skúste znova.';

  @override
  String get onboardingExploreDemoData => 'Preskúmať s ukážkovými údajmi';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpOpenGuide => 'Open the guide';

  @override
  String helpUnavailable(String asset) {
    return 'The guide could not be loaded ($asset).';
  }

  @override
  String get linkDeviceInvalidCode => 'Please enter a valid device code';

  @override
  String linkDeviceFailed(String error) {
    return 'Link failed: $error';
  }

  @override
  String linkDeviceLinked(
    int favorites,
    int alerts,
    int vehicles,
    int fillUps,
  ) {
    return 'Linked! Imported $favorites favourites, $alerts alerts, $vehicles vehicles, $fillUps fill-ups.';
  }

  @override
  String syncConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get showFewerFuelTypes => 'Show fewer fuel types';

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
    return '$price $currency (cieľ: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel zlacnel na blízkych staniciach';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count staníc zlacnelo až o $cents¢ za poslednú hodinu';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count staníc ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count ďalších';
  }

  @override
  String get alertsNotificationsOffTitle => 'Notifications are off';

  @override
  String get alertsNotificationsOffPermissionBody =>
      'Your price alerts are still checked, but they can\'t notify you: notifications for this app are turned off in your phone\'s settings.';

  @override
  String get alertsNotificationsOffChannelBody =>
      'Your price alerts are still checked, but they can\'t notify you: price alert notifications are turned off in your phone\'s settings.';

  @override
  String get alertsNotificationsOffOpenSettings => 'Open settings';

  @override
  String alertReasonNetSaving(String amount) {
    return 'About $amount on your usual fill';
  }

  @override
  String alertReasonBelowThreshold(String delta) {
    return '$delta/L below the price you set';
  }

  @override
  String alertReasonBelowYourMedian(String delta) {
    return '$delta/L below what you usually pay';
  }

  @override
  String alertReasonBelowLocalMedian(String delta) {
    return '$delta/L below the local average';
  }

  @override
  String alertReasonBelowEarlier(String delta) {
    return '$delta/L cheaper than earlier';
  }

  @override
  String alertReasonBelowCheapestOnRoute(String delta) {
    return '$delta/L below the best on your route';
  }

  @override
  String alertReasonBelowCheapestNearby(String delta) {
    return '$delta/L below the best nearby';
  }

  @override
  String alertReasonDistance(String distance) {
    return '$distance away';
  }

  @override
  String alertReasonPriceAge(String age) {
    return 'Price updated $age ago';
  }

  @override
  String get alertReasonPriceAgeUnknown =>
      'This data source doesn\'t say when the price was set';

  @override
  String get alertReasonSourceMedium =>
      'This country\'s data refreshes less often';

  @override
  String get alertReasonSourceLow =>
      'This country\'s data is incomplete or slow to refresh';

  @override
  String get alertConfidenceMediumPrefix => 'Potential saving';

  @override
  String alertsLastChecked(String when) {
    return 'Naposledy skontrolované: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Ceny zatiaľ neboli na pozadí skontrolované';

  @override
  String get alertsIosBestEffortNote =>
      'Na iPhone sa upozornenia kontrolujú podľa možností: o tom, kedy smie aplikácia kontrolovať ceny na pozadí, rozhoduje iOS, takže upozornenie môže prísť neskoro alebo občas vôbec. Otvorenie aplikácie vždy spustí novú kontrolu.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Cieľová cena ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Prah ($currency/L)';
  }

  @override
  String get alertsEmptyTitle => 'No price alerts yet';

  @override
  String get alertsEmptySubtitle =>
      'Get notified when a station, or any station in a zone, drops below your target price.';

  @override
  String get favoritesLoadErrorTitle => 'Favorites';

  @override
  String allPricesEstimatedCost(String cost) {
    return '≈ $cost';
  }

  @override
  String allPricesCellEstimatedSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '$fuel $price, about $cost per 100 km, estimated at $consumption from your vehicle\'s measured consumption and the fuel\'s energy content';
  }

  @override
  String get approachOverlaySection => 'Prekryv pri približovaní k stanici';

  @override
  String get approachRadiusLabel => 'Polomer';

  @override
  String approachRadiusCaption(String km) {
    return 'Prekryv sa zväčší a zobrazí cenu, keď ste do $km km od čerpacej stanice';
  }

  @override
  String get approachPriceModeLabel => 'Zobraziť cenu';

  @override
  String get approachPriceModeNearest => 'Najbližšia stanica';

  @override
  String get approachPriceModeCheapestInRadius => 'Najlacnejšia v polomere';

  @override
  String get approachMinPollLabel => 'Min. obnovenie';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Spodný limit obnovovania najbližšej stanice (rýchlejšie pri rýchlosti, nikdy častejšie ako $seconds s)';
  }

  @override
  String get approachTestSimulateButton =>
      'Otestovať prekrytie pri približovaní';

  @override
  String get approachTestStopButton => 'Zastaviť test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktívny — prekrytie zobrazuje cenu pre $station';
  }

  @override
  String get approachTestUnavailable =>
      'Pridajte obľúbenú stanicu, aby ste mohli otestovať prekrytie pri približovaní';

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Blízkosť $percent%';
  }

  @override
  String get pipTapToRestore => 'Ťuknutím otvoríte celú aplikáciu';

  @override
  String get authErrorNoNetwork =>
      'Žiadne sieťové pripojenie. Skúste to neskôr.';

  @override
  String get authErrorInvalidCredentials =>
      'Neplatný e-mail alebo heslo. Skontrolujte prihlasovacie údaje.';

  @override
  String get authErrorUserAlreadyExists =>
      'Tento e-mail je už zaregistrovaný. Skúste sa prihlásiť.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Skontrolujte prosím e-mail a najprv potvrďte účet.';

  @override
  String get authErrorGeneric => 'Prihlásenie zlyhalo. Skúste to znova.';

  @override
  String get authLinkEmailTitle => 'Prepojiť e-mail';

  @override
  String get authLinkEmailSubtitle =>
      'Prepojte e-mail, aby sa vaše údaje synchronizovali medzi zariadeniami. Súčasné obľúbené položky a jazdy zostanú na tomto účte.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Používate účet hosťa ($idPrefix…). Prepojte e-mail, aby sa vaše obľúbené položky a jazdy synchronizovali s ostatnými zariadeniami.';
  }

  @override
  String get authConfirmationPending =>
      'Takmer hotovo — skontrolujte e-mail a kliknite na odkaz na dokončenie prepojenia. Vaše údaje sú na tomto účte už uložené.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Poloha na pozadí — iba pre automatický záznam';

  @override
  String get autoRecordConsentExplanationTitle => 'O tomto oprávnení';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatický záznam potrebuje polohu na pozadí pre detekciu začiatku jazdy, keď je aplikácia zatvorená. Toto oprávnenie používa iba automatický záznam — vyhľadávanie staníc a centrovanie mapy používajú samostatné povolenie polohy v popredí.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Rozumiem';

  @override
  String get autoRecordConsentExplanationTooltip => 'Čo to znamená?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Klepnutím spravovať v systémových nastaveniach';

  @override
  String get autoRecordSectionTitle => 'Automatický záznam';

  @override
  String get autoRecordToggleLabel => 'Automaticky zaznamenávať jazdy';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatický záznam sa aktivuje nabudúce, keď nastúpite do auta.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Spárujte OBD2 adaptér pre zapnutie automatického záznamu.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Povolte polohu na pozadí, aby automatický záznam fungoval aj s vypnutou obrazovkou.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Spárovať adaptér';

  @override
  String get autoRecordSpeedThresholdLabel => 'Rýchlosť spustenia (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Oneskorenie uloženia po odpojení (sekundy)';

  @override
  String get autoRecordBackgroundLocationLabel => 'Poloha na pozadí povolená';

  @override
  String get autoRecordBackgroundLocationRequest => 'Požiadať o oprávnenie';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Prečo \"Vždy povoliť\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatický záznam streamuje GPS súradnice zo služby OBD-II na popredí, keď je obrazovka vypnutá, aby vaša trasa jazdy zostala presná. Android vyžaduje možnosť \"Vždy povoliť\", aby to fungovalo aj po zamknutí zariadenia.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Otvoriť nastavenia';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Vyžaduje sa oprávnenie polohy';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nepodarilo sa požiadať o polohu na pozadí';

  @override
  String get aclWakeNotificationTitle => 'Auto pripojené';

  @override
  String get aclWakeNotificationBody =>
      'Ťuknutím otvoríte Sparkilo — záznam jazdy sa môže začať.';

  @override
  String get exportBackupReady => 'Záloha pripravená — vyberte cieľ';

  @override
  String get exportBackupFailed => 'Export zálohy zlyhal — skúste to znova';

  @override
  String get backupExportProgress => 'Exportujem zálohu…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Uložené do Stiahnuté ako $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Obnoviť zálohu';

  @override
  String get restoreBackupDialogBody =>
      'Zlúčenie pridá a aktualizuje záznamy zo zálohy a zachová všetko, čo je už na tomto zariadení. Nahradenie najprv vymaže všetky aktuálne údaje a potom obnoví iba zálohu — to nie je možné vrátiť späť.';

  @override
  String get restoreBackupMergeAction => 'Zlúčiť';

  @override
  String get restoreBackupReplaceAction => 'Nahradiť všetko';

  @override
  String get restoreBackupEmpty =>
      'Záloha obnovená — neobsahovala žiadne záznamy';

  @override
  String get restoreBackupCorrupt =>
      'Obnovenie zlyhalo — tento súbor nie je platná záloha Tankstellen';

  @override
  String get restoreBackupFailed =>
      'Obnovenie zlyhalo — súbor sa nedalo prečítať';

  @override
  String get backupImportProgress => 'Obnovu zálohu…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Zlúčené $vehicles vozidiel, $fillUps tankovania, $trips výletov, $chargingLogs záznamy nabíjania';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Všetky údaje nahradené s $vehicles vozidlami, $fillUps tankovaniami, $trips výletmi, $chargingLogs záznamami nabíjania';
  }

  @override
  String get brokenMapChipDisclaimer => 'Hodnoty MAP senzora sú podozrivé';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP senzor číta nesprávne — hodnoty paliva môžu byť o 50–80 % nízke. Skúste iný adaptér.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP senzor nespoľahlivý. Zobrazujú sa priemerné hodnoty tankovania namiesto živého prietoku paliva.';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP senzor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP senzor: $posterior% ± $margin% (overený)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostika MAP senzora';

  @override
  String get brokenMapDiagnosticsExplainer =>
      'Live fuel use is worked out from the engine air-pressure reading (the MAP sensor) your car reports over OBD2. Some adapters report it wrong, which makes live fuel use look far too low — when that happens SparKilo shows your fill-up averages instead.';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Spoľahlivosť chyby MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count zaznamenaných meraní';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Overené čisté';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'MAP senzor tohto vozidla ešte nebol pozorovaný.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Zablokované adaptéry';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Žiadne adaptéry nie sú zablokované.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — označený $percent% chybný';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Vymazať';

  @override
  String get brokenMapRevPromptTitle => 'Zaревujte motor';

  @override
  String get brokenMapRevPromptBody =>
      'Krátko stlačte plyn, aby aplikácia mohla skontrolovať odozvu MAP senzora.';

  @override
  String get brokenMapRevPromptConfirm => 'Hotovo — zarevoval som';

  @override
  String get calibrationAdvancedTitle => 'Pokročilá kalibrácia';

  @override
  String get calibrationDisplacementLabel => 'Zdvihový objem motora (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrická účinnosť (η_v)';

  @override
  String get calibrationAfrLabel => 'Pomer vzduch/palivo (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Hustota paliva (g/L)';

  @override
  String get calibrationSourceDetected => '(zistené z VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalóg: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(predvolené)';

  @override
  String get calibrationSourceManual => '(ručné)';

  @override
  String get calibrationResetToDetected => 'Resetovať na zistenú hodnotu';

  @override
  String get calibrationBasisAtkinson => 'Atkinson cyklus';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbodúchadlo + DI';

  @override
  String get calibrationBasisTurbo => 'Turbodúchadlo';

  @override
  String get calibrationBasisNaDi => 'Atmosferický + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalóg: $makeModel — $basis predvolené)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'Toto vozidlo hlási spotrebu paliva priamo (PID 5E), takže kalibrácia objemovej účinnosti sa nepoužíva — vaša spotreba je meraná, nie modelovaná.';

  @override
  String get carbonCo2ScopeWellToWheel => 'Well-to-wheel';

  @override
  String carbonCo2FactorSource(String source) {
    return 'Factors: $source';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Váš $makeModel je označený ako diesel, ale zodpovedá katalógovej položke benzín. Klepnutím aktualizujte.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aktualizovať';

  @override
  String get catalogResetAction => 'Obnoviť z databázy vozidiel';

  @override
  String get catalogResetConfirmTitle => 'Obnoviť z databázy vozidiel?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Nahradí objem nádrže, výkon motora a zdvihový objem tohto vozidla hodnotami z databázy pre $vehicle. Ostatné polia a história tankovania zostanú nezmenené.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'V databáze vozidiel nie je pre toto vozidlo žiadny zodpovedajúci záznam.';

  @override
  String get catalogResetDoneSnackbar => 'Údaje o vozidle obnovené z databázy.';

  @override
  String get consumptionTabFuel => 'Palivo';

  @override
  String get consumptionTabCharging => 'Nabíjanie';

  @override
  String get noChargingLogsTitle => 'Zatiaľ žiadne záznamy nabíjania';

  @override
  String get noChargingLogsSubtitle =>
      'Zaznamenajte prvú reláciu nabíjania pre sledovanie EUR/100 km a kWh/100 km.';

  @override
  String get addChargingLog => 'Zaznamenať nabíjanie';

  @override
  String get addChargingLogTitle => 'Zaznamenať reláciu nabíjania';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Celkové náklady';

  @override
  String get chargingTimeMin => 'Čas nabíjania (min)';

  @override
  String get chargingStationName => 'Stanica (voliteľné)';

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
      'Potrebný predchádzajúci záznam na porovnanie';

  @override
  String get chargingLogButtonLabel => 'Zaznamenať nabíjanie';

  @override
  String get chargingCostTrendTitle => 'Trend nákladov na nabíjanie';

  @override
  String get chargingEfficiencyTitle => 'Účinnosť (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Zatiaľ nedostatok dát';

  @override
  String get chargingLogDeletedUndoSnackbar => 'Charging session deleted';

  @override
  String get confirmDeleteTitle => 'Odstrániť?';

  @override
  String get confirmDeleteBody => 'Naozaj to chcete odstrániť?';

  @override
  String get consoFeatureGroupTitle => 'Spotreba';

  @override
  String get consoFeatureGroupDescription =>
      'Sledujte svoju spotrebu — ručné tankovania alebo automatický záznam jázd OBD2.';

  @override
  String get consoModeOff => 'Vypnuté';

  @override
  String get consoModeFuel => 'Palivo';

  @override
  String get consoModeFuelAndTrips => 'Palivo + Jazdy';

  @override
  String get consoModeOffDescription =>
      'Žiadna karta Spotreba a žiadna sekcia nastavení spotreby.';

  @override
  String get consoModeFuelDescription =>
      'Iba ručné tankovania. Vhodné bez OBD2 adaptéra.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Pridáva automatický záznam jázd OBD2. Vyžaduje spárovaný adaptér.';

  @override
  String get consoGroupVehicles => 'Vozidlá';

  @override
  String get consoGroupCoaching => 'Koučing počas jazdy';

  @override
  String get consoGroupRewards => 'Odmeny a úspory';

  @override
  String get consoGroupTroubleshooting => 'Riešenie problémov';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Presnosť: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Vysoká';

  @override
  String get consumptionAccuracyMedium => 'Stredná';

  @override
  String get consumptionAccuracyLow => 'Nízka';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Úplná kalibrácia: tankovania plus jazdy zaznamenané cez OBD2. Hodnota L/100 km zodpovedá realite s odchýlkou niekoľkých percent.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankovania ukotvili model spotreby, ale zatiaľ nebola spracovaná žiadna jazda z OBD2. Zaznamenajte jednu s pripojeným OBD2 na dosiahnutie vysokej presnosti.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Iba GPS — model spotreby zatiaľ neukotvilo žiadne tankovanie. Pridajte niekoľko plných tankovaní na zlepšenie presnosti.';

  @override
  String get moreActionsTooltip => 'Viac';

  @override
  String get exportBackupMenuLabel => 'Exportovať zálohu';

  @override
  String get restoreBackupMenuLabel => 'Obnoviť zálohu';

  @override
  String get carbonDashboardMenuLabel => 'Uhlíkový panel';

  @override
  String get settingsMenuLabel => 'Nastavenia';

  @override
  String get consumptionMetricLitres => 'Litres';

  @override
  String get consumptionMetricSpend => 'Spend';

  @override
  String get consumptionMetricPricePerLitre => 'Price/L';

  @override
  String get consumptionMetricPerHundred => 'L/100 km';

  @override
  String get consumptionStatsPageTitle => 'Štatistiky spotreby';

  @override
  String get consumptionStatsComparisonTitle => 'Tento mesiac vs minulý mesiac';

  @override
  String get consumptionStatsTrendsTitle => 'Vývoj v čase';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Zaznamenávajte tankovania aspoň dva mesiace, aby ste mohli porovnávať.';

  @override
  String get consumptionStatsPricePerLiter => 'Priem. cena/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litre za mesiac';

  @override
  String get consumptionStatsChartSpend => 'Výdavky za mesiac';

  @override
  String get consumptionStatsChartPricePerLiter => 'Cena za liter';

  @override
  String get consumptionStatsChartConsumption => 'L/100km za mesiac';

  @override
  String get fuelCompareSectionTitle => 'Náklady na jazdu podľa paliva';

  @override
  String get fuelComparePricePerLitre => 'Zaplatené za liter';

  @override
  String get fuelCompareCostPer100km => 'Náklady na 100 km';

  @override
  String get fuelCompareDistance => 'Nameraná vzdialenosť';

  @override
  String get fuelCompareLitres => 'Spotrebované litre';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner je vaše najlacnejšie palivo na jazdenie';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser stojí o $amount viac na 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel poráža $rival pod $price za liter';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Bod zvratu sa počíta z nameranej spotreby každého paliva, takže sa posúva spolu s vašou jazdou.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litre a náklady si môžu protirečiť: palivo môže spotrebovať menej litrov na 100 km a napriek tomu stáť viac za kilometer, pretože sa líši cena za liter. Rozhodujú náklady na kilometer.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plných nádrží',
      one: 'jednej plnej nádrže',
    );
    return 'Predbežné — na základe $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plných nádrží',
      one: 'jednej plnej nádrže',
    );
    return 'Na základe $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 na 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner je vaše palivo s najnižšími emisiami';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel stojí o $money viac na 1000 km, ale vypustí o $co2 menej CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel je zároveň lacnejšie aj čistejšie než $rival';
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
    return 'Vašich $distance na $fuel vypustilo $actual namiesto $alternative na $rival — $saved ušetrených';
  }

  @override
  String get fuelCompareCo2Source =>
      'Hodnoty CO2 sú odhady „od zdroja ku kolesu“ (EU JEC WTW v5) použité na vašu nameranú spotrebu — orientačné, nie certifikované účtovníctvo.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 sa zobrazuje len pri čistých palivách: emisný faktor zmesi závisí od jej zloženia, ktoré tento riadok nezaznamenáva.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count čiastočných tankovaní čaká na plné — nie sú zahrnuté v priemere',
      one: '1 čiastočné tankovanie čaká na plné — nie je zahrnuté v priemere',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% paliva z automatických korekcií — skontrolujte záznamy';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Korekcie: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Nahlásiť obsah';

  @override
  String get contentModerationBlockAction => 'Blokovať autora';

  @override
  String get contentModerationReportDialogTitle => 'Nahlásiť tento obsah?';

  @override
  String get contentModerationReportDialogBody =>
      'Hlásenie sa odošle na váš server TankSync na kontrolu a tento obsah bude na vašom zariadení skrytý.';

  @override
  String get contentModerationReportConfirmButton => 'Nahlásiť';

  @override
  String get contentModerationBlockDialogTitle => 'Blokovať tohto autora?';

  @override
  String get contentModerationBlockDialogBody =>
      'Všetko, čo s vami tento účet zdieľa, bude na tomto zariadení skryté.';

  @override
  String get contentModerationBlockConfirmButton => 'Blokovať';

  @override
  String get contentModerationReportedSnack =>
      'Hlásenie odoslané — obsah skrytý.';

  @override
  String get contentModerationReportFailedSnack =>
      'Hlásenie sa nepodarilo odoslať. Skúste to znova.';

  @override
  String get contentModerationBlockedSnack =>
      'Autor blokovaný — jeho zdieľaný obsah je skrytý.';

  @override
  String get fillUpCorrectionLabel =>
      'Automatická korekcia — klepnutím upraviť';

  @override
  String get fillUpCorrectionEditTitle => 'Upraviť automatickú korekciu';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Tento záznam bol automaticky vygenerovaný na uzatvorenie medzery medzi zaznamananými jazdami a natankovaným palivom. Upravte hodnoty, ak poznáte skutočné čísla.';

  @override
  String get fillUpCorrectionDelete => 'Odstrániť korekciu';

  @override
  String get fillUpCorrectionStation => 'Názov stanice (voliteľné)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stanice v $country vzdialené $km km — €$price/L lacnejšie';
  }

  @override
  String get crossBorderTapToSwitch => 'Klepnutím prepnúť krajinu';

  @override
  String get crossBorderDismissTooltip => 'Zatvoriť';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Otvoriť zdroj údajov $source ($license) v prehliadači';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© prispievatelia $brand';
  }

  @override
  String dataApproximate(String value) {
    return '≈ $value';
  }

  @override
  String dataStale(String value, String age) {
    return '$value ($age old)';
  }

  @override
  String dataLastSeen(String age) {
    return 'Last seen $age ago';
  }

  @override
  String get dataUnknownProvider => 'This data source doesn\'t publish it';

  @override
  String get dataUnknownItem => 'Not published for this station';

  @override
  String get dataUnknownNotMeasured => 'Not measured yet';

  @override
  String get dataUnknownVehicle => 'Missing from your vehicle';

  @override
  String get dataUnknownUnreadable =>
      'The data source sent something unreadable';

  @override
  String get dataBasisCatalog => 'Manufacturer figure';

  @override
  String get dataBasisFleetAverage => 'Class average';

  @override
  String get dataBasisDerived => 'Derived from other figures';

  @override
  String get decisionLeadCaveatHours =>
      'opening hours aren\'t published for this country';

  @override
  String get decisionLeadCaveatPriceAge =>
      'this source doesn\'t say when the price was set';

  @override
  String get decisionLeadCaveatSeparator => ' · ';

  @override
  String get developerToolsSectionTitle => 'Nástroje pre vývojárov';

  @override
  String get dataAccessTracerExport => 'Exportovať záznam prístupu k údajom';

  @override
  String get dataAccessTracerExportSuccess =>
      'Záznam prístupu k údajom uložený do priečinka Stiahnuté.';

  @override
  String get dataAccessTracerExportFailure =>
      'Záznam prístupu k údajom sa nepodarilo exportovať.';

  @override
  String get dataAccessTracerEmpty =>
      'Zatiaľ nie sú zaznamenané žiadne udalosti prístupu k údajom — najprv vyhľadajte alebo otvorte stanice, potom exportujte.';

  @override
  String get developerToolsSubtitle =>
      'Diagnostika a nástroje na ladenie — viditeľné iba vo vývojárskom/ladiacom režime.';

  @override
  String get developerToolsMenuSubtitle =>
      'Protokol chýb, testovacie upozornenia, diagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Protokol chýb';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Uložiť protokol chýb ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Vymazať protokol chýb';

  @override
  String get developerToolsViewErrorLog => 'Zobraziť protokol chýb';

  @override
  String get developerToolsErrorLogEmpty =>
      'Nezaznamenali sa žiadne stopy chýb.';

  @override
  String get developerToolsAlertsGroupTitle => 'Upozornenia a oznámenia';

  @override
  String get developerToolsFireTestNotification =>
      'Odoslať testovacie oznámenie';

  @override
  String get developerToolsTestNotificationTitle => 'Testovacie oznámenie';

  @override
  String get developerToolsTestNotificationBody =>
      'Ak toto čítate, oznámenia fungujú.';

  @override
  String get developerToolsTestNotificationSent =>
      'Testovacie oznámenie odoslané.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Oznámenia sú zablokované — povoľte ich v nastaveniach systému a skúste to znova.';

  @override
  String get developerToolsRunTestAlert =>
      'Spustiť testovací proces upozornenia';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testovacie upozornenie spustené — proces doručil $count oznámení.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testovacie cenové upozornenie';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Syntetická zhoda: v okolí sa našla stanica pod vaším cieľom.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Najprv vyhľadajte stanice, potom spustite testovací alert, aby notifikácia mohla otvoriť skutočnú stanicu.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostika';

  @override
  String get developerToolsFeatureFlagDump => 'Inšpektor príznakov funkcií';

  @override
  String get developerToolsFlagOn => 'Zapnuté';

  @override
  String get developerToolsFlagOff => 'Vypnuté';

  @override
  String get developerToolsClearCaches => 'Vymazať vyrovnávacie pamäte';

  @override
  String get developerToolsCachesCleared => 'Vyrovnávacie pamäte vymazané.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopírovať diagnostiku';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostika skopírovaná do schránky.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Informácie o zostavení';

  @override
  String get developerToolsBuildVersion => 'Verzia aplikácie';

  @override
  String get developerToolsBuildChannel => 'Kanál zostavenia';

  @override
  String get startupTraceSectionTitle => 'Záznam inicializácie pri spustení';

  @override
  String get startupTraceExportButton => 'Exportovať záznam spustenia';

  @override
  String get startupTraceEmpty =>
      'Zatiaľ nie je zaznamenaný žiadny záznam spustenia.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Celkom: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Záznam spustenia uložený do priečinka Stiahnuté.';

  @override
  String get startupTraceExportFailure =>
      'Záznam spustenia sa nepodarilo exportovať.';

  @override
  String get distanceSourceOdometer => 'Tachometer';

  @override
  String get distanceSourceOdometerTooltip =>
      'Vzdialenosť odčítaná z tachometra auta — nameraná referenčná hodnota.';

  @override
  String get distanceSourceGps => 'Stopa GPS';

  @override
  String get distanceSourceGpsTooltip =>
      'Vzdialenosť sčítaná zo zaznamenanej stopy GPS — skutočná vzdialenosť po ceste.';

  @override
  String get distanceSourceEstimated => 'Odhad';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Vzdialenosť integrovaná zo snímača rýchlosti — odhad; snímač zvyčajne mierne nadhodnocuje.';

  @override
  String get insightCardTitle => 'Najväčšie plytvania';

  @override
  String get insightEmptyState => 'Žiadne výrazné neefektívnosti — tak ďalej!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor nad 3000 RPM ($pctTime% jazdy): premrhaných $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count prudkých zrýchlení: premrhaných $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Voľnobeh ($pctTime% jazdy): premrhaných $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% jazdy';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Jazda na nízky prevodový stupeň ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Pri dlhých zastaveniach vypínajte motor, namiesto toho aby ste ho nechávali bežať na voľnobeh.';

  @override
  String get lessonAdviceHighRpm =>
      'Preraďte nahor skôr, aby ste udržali motor mimo pásma vysokých otáčok.';

  @override
  String get lessonAdviceHardAccel =>
      'Plynulo pridávajte plyn — rovnomerné zrýchľovanie spotrebuje menej paliva.';

  @override
  String get lessonAdviceLowGear =>
      'Preraďte nahor skôr, aby sa motor ustálil na nižších, úspornejších otáčkach.';

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Trvalo vysoká rýchlosť ($pctTime % jazdy)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Nad 110 km/h ubertte plyn – odpor vzduchu prudko rastie, mierne spomalenie ušetrí veľa paliva.';

  @override
  String get lessonSmoothDrivingTitle => 'Plynulá jazda – výborne!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Žiadne prudké zrýchľovanie ani brzdenie na tejto jazde – plynulá jazda udržiava spotrebu nízku.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Plný plyn ($pctTime% výletu): premárnených $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Šliapajte na pedál jemnejšie — plynulý 70 % výkon pedála vás rozbehne na oveľa menej paliva.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Bohatá zmes pri záťaži ($pctTime% výletu): premárnených $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Ťažká trvalá záťaž spôsobuje bohatú zmes motora — skoro radťe a uvoľnite na dlhých stúpaniach, aby zmes zostala chudobná.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Stúpanie so sklonom $gradePercent% ($pctTime% výletu): premárnených $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Naberajte rýchlosť pred kopcom a plynne dávajte plyn — prudké pridávanie na stúpaní spaľuje extra palivo.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count štartov zo zastávky: premárnených $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Predvídajte premávku a voľným behom sa blížte k zastávkam, aby ste sa skôr váľali, ako zastavili — rozjazd z úplného zastavenia je najúspornejšia časť stop-and-go.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Zmes sa zdá mierne chudobná — motor pridával palivo (korekcia $pctTrim %), aby to vyrovnal';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Zmes sa zdá chudobná — motor trvalo pridával veľké množstvo paliva ($pctTrim %), možná neefektivita';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Zmes sa zdá mierne bohatá — motor uberal palivo (korekcia $pctTrim %), aby to vyrovnal';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Zmes sa zdá bohatá — motor trvalo uberal veľké množstvo paliva ($pctTrim %), možná neefektivita';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Motor bežal pri zaťažení na bohatú zmes ($pctShare % zahriatej jazdy) — možné plytvanie palivom';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristický signál stavu, nie diagnóza';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Trvalá korekcia smerom k chudobnej zmesi môže znamenať prisávanie vzduchu v saní, slabé zásobovanie palivom alebo starnúci snímač. Ak sa spotreba alebo chod zhorší, diagnostika v servise to môže potvrdiť.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Trvalá korekcia smerom k bohatej zmesi môže znamenať netesný vstrekovač, vysoký tlak paliva alebo snímač, ktorý nadhodnocuje. Ak sa spotreba alebo chod zhorší, diagnostika v servise to môže potvrdiť.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Bohatá zmes pri vysokom zaťažení spaľuje palivo navyše. Raďte nahor skôr a pri dlhom zrýchľovaní uberte plyn, aby motor zostal blízko stechiometrickej zmesi.';

  @override
  String get lessonTransportTitle =>
      'Počas väčšiny tejto jazdy chýbajú údaje z motora';

  @override
  String get lessonTransportAdvice =>
      'Motor nehlásil takmer po celú vzdialenosť žiadnu aktivitu. Buď dátový tok OBD2 v polovici jazdy zlyhal, alebo bolo auto premiestnené bez jazdy — údaj o spotrebe je nespoľahlivý a zo štatistík je vylúčený.';

  @override
  String insightHighRpmShare(String pctTime) {
    return 'Engine over 3000 RPM ($pctTime% of trip)';
  }

  @override
  String insightHardAccelEvents(String count) {
    return '$count hard accelerations';
  }

  @override
  String insightIdlingLong(String minutes) {
    return 'Long idling with the engine running ($minutes min)';
  }

  @override
  String insightFullThrottleShare(String pctTime) {
    return 'Full throttle ($pctTime% of trip)';
  }

  @override
  String insightLambdaEnrichmentShare(String pctTime) {
    return 'Rich mixture under load ($pctTime% of trip)';
  }

  @override
  String insightClimbingShare(String gradePercent, String pctTime) {
    return 'Climbing at $gradePercent% grade ($pctTime% of trip)';
  }

  @override
  String insightRestartEvents(String count) {
    return '$count stop-and-go restarts';
  }

  @override
  String insightTrailingLitersApprox(String liters) {
    return '≈ +$liters L';
  }

  @override
  String get drivingPatternComparisonTitle => 'Driving patterns';

  @override
  String get drivingPatternComparisonSubtitle =>
      'What was observed at the wheel, with the driving each figure rests on.';

  @override
  String get drivingPatternNotFuelNote =>
      'Behaviour observations only. No litres and no money are attributed to them here — that would need its own validated comparison.';

  @override
  String get drivingPatternInsufficient =>
      'Not enough recorded driving to compare patterns yet.';

  @override
  String drivingPatternMatchedOn(String criteria) {
    return 'Matched on: $criteria';
  }

  @override
  String get drivingPatternUnmatchedNotice =>
      'No trip conditions in common, so the figures below are descriptive observations over unequal routes.';

  @override
  String drivingPatternMatchCounts(int matched, int unmatched) {
    return '$matched trips matched, $unmatched outside the matched conditions';
  }

  @override
  String drivingPatternUnassignedExcluded(int count) {
    return '$count recorded trips belong to no vehicle and are counted for none.';
  }

  @override
  String get drivingPatternNoAdjustedRanking =>
      'No condition-adjusted ranking: expected consumption per trip is not recorded, so route, terrain and traffic cannot be taken out of these figures.';

  @override
  String get drivingPatternContextNote =>
      'A higher figure here can be the road rather than the driver — necessary braking, a climb, or an engine that simply turns faster.';

  @override
  String get drivingPatternDifferencesTitle => 'Largest observed differences';

  @override
  String drivingPatternDifferenceLine(
    String measure,
    String higher,
    String higherVehicle,
    String lower,
    String lowerVehicle,
  ) {
    return '$measure: $higher for $higherVehicle, $lower for $lowerVehicle';
  }

  @override
  String get drivingPatternUnavailableNoSignal =>
      'Not recorded — these trips carry no such signal';

  @override
  String get drivingPatternUnavailableTooLittle =>
      'Too little driving to state a figure';

  @override
  String drivingMeasureEventsPer100Km(String value) {
    return '$value per 100 km';
  }

  @override
  String drivingMeasureSharePercent(String value) {
    return '$value %';
  }

  @override
  String drivingPatternEvidenceCaption(
    String numerator,
    String denominator,
    int trips,
  ) {
    return '$numerator over $denominator · $trips trips';
  }

  @override
  String drivingPatternCountEvents(String count) {
    return '$count events';
  }

  @override
  String drivingPatternCountMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String drivingPatternCountKm(String km) {
    return '$km km';
  }

  @override
  String get drivingMeasureHardAccelRate => 'Hard accelerations';

  @override
  String get drivingMeasureFullThrottleShare => 'Full-throttle time';

  @override
  String get drivingMeasureHardBrakeRate => 'Hard braking';

  @override
  String get drivingMeasureAvoidableBrakeShare => 'Avoidable hard braking';

  @override
  String get drivingMeasureEngineIdleShare => 'Engine idling';

  @override
  String get drivingMeasureHighRpmShare => 'High engine speed';

  @override
  String get drivingMeasureSustainedHighSpeedShare => 'Sustained high speed';

  @override
  String get drivingMeasureEnergyOscillationRate =>
      'Accelerate and brake cycles';

  @override
  String get drivingMeasureCoastingFuelCutShare => 'Coasting without fuel';

  @override
  String get drivingMeasureLateCurveShare => 'Late braking into curves';

  @override
  String get drivingMeasureClimbFullThrottleShare => 'Full throttle climbing';

  @override
  String get drivingMeasureFlatFullThrottleShare => 'Full throttle on the flat';

  @override
  String get drivingPatternQualUncontrolled => 'conditions not controlled';

  @override
  String get drivingPatternQualPartialConditions =>
      'only cold starts were evaluated';

  @override
  String get drivingPatternQualUnequalEvidence =>
      'very unequal amounts of evidence';

  @override
  String get drivingPatternQualExcluded => 'some records were excluded';

  @override
  String get drivingPatternBandShort => 'trips under 5 km';

  @override
  String get drivingPatternBandMedium => 'trips of 5 to 30 km';

  @override
  String get drivingPatternBandLong => 'trips over 30 km';

  @override
  String get drivingPatternStartCold => 'cold start';

  @override
  String get drivingPatternStartWarm => 'warm start';

  @override
  String get drivingPatternStartUnknown => 'start temperature not recorded';

  @override
  String drivingPatternCohortLabel(String band, String start) {
    return '$band, $start';
  }

  @override
  String drivingPatternMeasureSemantics(
    String measure,
    String vehicle,
    String value,
    String evidence,
  ) {
    return '$measure for $vehicle: $value, $evidence';
  }

  @override
  String drivingPatternUnavailableSemantics(
    String measure,
    String vehicle,
    String reason,
  ) {
    return '$measure for $vehicle: $reason';
  }

  @override
  String get drivingScoreCardTitle => 'Jazdné skóre';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Kompozitné skóre z voľnobehu, prudkých zrýchlení, prudkého brzdenia a času na vysoké RPM. Porovnanie \"lepšie ako X% minulých jázd\" bude dostupné v nasledujúcej verzii.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Jazdné skóre $score zo 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Voľnobeh';

  @override
  String get drivingScorePenaltyHardAccel => 'Prudké zrýchlenia';

  @override
  String get drivingScorePenaltyHardBrake => 'Prudké brzdenie';

  @override
  String get drivingScorePenaltyHighRpm => 'Vysoké RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Plný plyn';

  @override
  String get drivingScoreClassVeryGood => 'Veľmi dobrý';

  @override
  String get drivingScoreClassGood => 'Dobrý';

  @override
  String get drivingScoreClassAverage => 'Priemerný';

  @override
  String get drivingScoreClassBad => 'Treba zlepšiť';

  @override
  String get drivingScorePenaltyLugging => 'Ťahanie motora';

  @override
  String get drivingScorePenaltySmoothness => 'Trhavá jazda';

  @override
  String get drivingScorePenaltyHighSpeed => 'Vysoká rýchlosť';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresívny pedál';

  @override
  String get drivingScorePenaltyLambda => 'Bohatá zmes';

  @override
  String get gpsKpiCardTitle => 'GPS efektivita';

  @override
  String get gpsKpiRpa => 'Pozitívne zrýchlenie (RPA)';

  @override
  String get gpsKpiPke => 'Požiadavka na kinetickú energiu (PKE)';

  @override
  String get gpsKpiVapos => 'Intenzita zrýchlenia (VAPOS)';

  @override
  String get gpsKpiCoast => 'Podiel voľného behu';

  @override
  String get gpsKpiClimbEnergy => 'Energia stúpania';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct oproti vašej efektívnej referenčnej hodnote';
  }

  @override
  String get drivingTraceCardTitle => 'Stopa analýzy jazdy (vývoj)';

  @override
  String get drivingTraceCardBody =>
      'Exportujte GPS KPI, skóre a lekcie tohto výletu ako JSON, napíšte, ako jazda skutočne prebiehala, do poľa komentára a zdieľajte späť, aby bolo možné kalibrovať prahové hodnoty štýlu jazdy podľa skutočných výletov.';

  @override
  String get drivingTraceExportAction => 'Exportovať stopu analýzy';

  @override
  String get drivingTraceExported =>
      'Stopa analýzy uložená do Stiahnuté — pridajte svoj verdikt do poľa komentára a zdieľajte späť.';

  @override
  String get drivingTraceExportFailed =>
      'Stopu analýzy sa nepodarilo exportovať.';

  @override
  String get minimalDriveTripAverage => 'Priemer jazdy';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Jazda vo vysokých otáčkach ($pctTime % jazdy): skoršie preradenie nahor by mohlo ušetriť $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Pri ustálenej jazde raďte nahor skôr — rovnaká rýchlosť v nižších otáčkach spaľuje badateľne menej.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Dojazd s odpojením paliva ($pctTime % jazdy): ušetrené asi $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Dobre predvídané — včasné ubratie plynu nechá motor pri dojazde úplne odpojiť palivo.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Kam išlo vaše palivo';

  @override
  String get fuelBreakdownIdle => 'Voľnobeh';

  @override
  String get fuelBreakdownHarshAccel => 'Prudké zrýchlenia';

  @override
  String get fuelBreakdownHighRpmCruise => 'Jazda vo vysokých otáčkach';

  @override
  String get fuelBreakdownCoastingSaved => 'Ušetrené dojazdom';

  @override
  String get fuelBreakdownEfficient => 'Bežná jazda';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Voľnobeh už nejaký čas — vypnutie motora šetrí palivo';

  @override
  String get ecoNudgeHarshAccel =>
      'Prudké zrýchlenie — jemnejšia noha na plyne šetrí palivo';

  @override
  String get ecoNudgeHighRpm =>
      'Vysoké otáčky pri ustálenej jazde — skoršie preradenie nahor šetrí palivo';

  @override
  String insightUpshiftCruiseShare(String pctTime) {
    return 'High-RPM cruising ($pctTime% of trip): shifting up earlier uses less fuel';
  }

  @override
  String get obd2CoverageNoneNote =>
      'Počas tejto jazdy neprišli z adaptéra OBD2 žiadne údaje z motora — údaje o palive sú odhady z GPS.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Údaje z motora sa skončili v $percent % jazdy (spojenie prerušené) — údaje o palive potom sú odhady z GPS.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Údaje z motora pokryli len $percent % tejto jazdy — medzery používajú odhady z GPS.';
  }

  @override
  String get favoritesShareAction => 'Zdieľať';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — obľúbené dňa $date';
  }

  @override
  String get favoritesShareError =>
      'Nepodarilo sa vygenerovať obrázok pre zdieľanie';

  @override
  String get featureManagementSectionTitle => 'Správa funkcií';

  @override
  String get featureManagementSectionSubtitle =>
      'Zapínajte alebo vypínajte jednotlivé funkcie. Niektoré funkcie závisia od iných — prepínače sú zakázané, kým nie sú splnené predpoklady.';

  @override
  String get featureLabel_obd2TripRecording => 'Záznam jázd OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Automaticky zachytávať jazdy cez OBD2.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptický eko-koučing';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Haptická spätná väzba v reálnom čase počas jazdy.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synchronizácia naprieč zariadeniami cez Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analýza spotreby';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Karta analýzy tankovaní a jázd.';

  @override
  String get featureLabel_baselineSync => 'Synchronizácia základní';

  @override
  String get featureDescription_baselineSync =>
      'Synchronizovať jazdné základne cez TankSync.';

  @override
  String get featureLabel_priceAlerts => 'Cenové upozornenia';

  @override
  String get featureDescription_priceAlerts =>
      'Upozornenia na pokles cien na základe prahovej hodnoty.';

  @override
  String get featureLabel_priceHistory => 'História cien';

  @override
  String get featureDescription_priceHistory =>
      '30-dňové cenové grafy v detailoch stanice.';

  @override
  String get featureLabel_routePlanning => 'Plánovanie trasy';

  @override
  String get featureDescription_routePlanning =>
      'Najlacnejšia zastávka na vašej trase.';

  @override
  String get featureLabel_evCharging => 'Nabíjanie EV';

  @override
  String get featureDescription_evCharging =>
      'Nabíjacie stanice cez OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Koučing plachtenia';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling navody pomocou dopravných signálov OSM.';

  @override
  String get featureLabel_gpsTripPath => 'GPS trasa jazdy';

  @override
  String get featureDescription_gpsTripPath =>
      'Uložiť vzorky GPS trasy pri každej jazde.';

  @override
  String get featureLabel_autoRecord => 'Automatický záznam';

  @override
  String get featureDescription_autoRecord =>
      'Automaticky spustiť jazdu, keď sa OBD2 adaptér pripojí k pohybujúcemu sa vozidlu.';

  @override
  String get featureLabel_showFuel => 'Zobraziť čerpacie stanice';

  @override
  String get featureDescription_showFuel =>
      'Zobraziť výsledky benzínových/naftových staníc vo vyhľadávaní a na mape.';

  @override
  String get featureLabel_showElectric => 'Zobraziť nabíjacie stanice';

  @override
  String get featureDescription_showElectric =>
      'Zobraziť EV nabíjacie stanice vo vyhľadávaní a na mape.';

  @override
  String get featureLabel_showConsumptionTab => 'Karta spotreby';

  @override
  String get featureDescription_showConsumptionTab =>
      'Zobraziť kartu analýzy spotreby v dolnej navigácii.';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Najprv zapnite TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite predikcia cien';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Model predpovede cien na zariadení — inference beží lokálne; funkcie a predpovede nikdy neopustia zariadenie.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Najprv zapnite históriu cien';

  @override
  String get featureLabel_fuelCalculator => 'Kalkulačka paliva';

  @override
  String get featureDescription_fuelCalculator =>
      'Kalkulačka nákladov na palivo dostupná z výsledkov vyhľadávania.';

  @override
  String get featureLabel_carbonDashboard => 'Uhlíkový panel';

  @override
  String get featureDescription_carbonDashboard =>
      'Panel uhlíkovej stopy CO2 dostupný z karty Spotreba.';

  @override
  String get featureLabel_experimentalOemPids => 'Experimentálne OEM PID';

  @override
  String get featureDescription_experimentalOemPids =>
      'Čítať presné litre v nádrži cez výrobcom špecifické PID na podporovaných adaptéroch.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Najprv zapnite záznam jázd OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Skenovanie platobného QR';

  @override
  String get featureDescription_paymentQrScan =>
      'QR čítačka pre platbu na obrazovke detailov stanice.';

  @override
  String get featureLabel_communityPriceReports => 'Komunitné hlásenia cien';

  @override
  String get featureDescription_communityPriceReports =>
      'Nahlásiť cenu stanice z obrazovky detailov stanice.';

  @override
  String get featureLabel_obd2Optional => 'Vyžadovať OBD2 pre záznam jázd';

  @override
  String get featureDescription_obd2Optional =>
      'Keď je vypnuté, aplikácia zaznamenáva jazdy iba pomocou GPS bez OBD2 adaptéra. Coaching je obmedzený — žiadne okamžité L/100 km, menej motorových signálov.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR účtenky';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Naskenujte vytlačenú účtenku na obrazovke Pridať tankovanie, aby ste vopred vyplnili dátum, litre, celkovú sumu a čerpaciu stanicu.';

  @override
  String get featureLabel_developerPatToken =>
      'Vývojárska spätná väzba (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Aktivuje panel spätnej väzby pre neúspešné skenovanie, ktorý automaticky vytvára GitHub issues s Personal Access Tokenom. Funkcia pre pokročilých používateľov / prispievateľov.';

  @override
  String get featureLabel_debugMode => 'Vývojársky/ladiaci režim';

  @override
  String get featureDescription_debugMode =>
      'Zobrazí v nastaveniach sekciu Nástroje pre vývojárov s diagnostikou: export protokolu chýb, testovacie oznámenia, spustenie testovacieho procesu upozornenia, výpis príznakov funkcií, vymazanie vyrovnávacích pamätí a kopírovanie diagnostiky.';

  @override
  String get featureLabel_approachOverlay => 'Radar čerpacích staníc';

  @override
  String get featureDescription_approachOverlay =>
      'Premenuje plávajúcu dlaždicu výletu na živý radar čerpacích staníc — keď sa blížite k čerpacej stanici, prepne sa na farbu paliva a zobrazí cenu.';

  @override
  String get featureLabel_voiceAnnouncements => 'Hlasové oznámenia';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Hovorí nahlas o blízkych lacných čerpacích staniciach počas jazdy, aby ste mohli mať oči na ceste.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Najprv aktivujte Radar čerpacích staníc';

  @override
  String get featureGroupTitle_finding => 'Vyhľadávanie a mapa';

  @override
  String get featureGroupDescription_finding =>
      'Kde natankovať alebo nabiť — vyhľadávanie, mapa, navigácia.';

  @override
  String get featureGroupTitle_prices => 'Ceny a alerty';

  @override
  String get featureGroupDescription_prices =>
      'Pokles cien, história a hlásenie.';

  @override
  String get featureGroupTitle_radar => 'Radar čerpacích staníc';

  @override
  String get featureGroupDescription_radar =>
      'Živé upozornenia na ceny počas jazdy.';

  @override
  String get featureGroupTitle_sync => 'Synchronizácia a záloha';

  @override
  String get featureGroupDescription_sync =>
      'Udržujte svoje údaje naprieč zariadeniami.';

  @override
  String get featureGroupTitle_input => 'Vstup a skenovanie';

  @override
  String get featureGroupDescription_input =>
      'Pomocníci pre zaznamenávanie tankovania.';

  @override
  String get featureGroupTitle_developer => 'Vývojárske a experimentálne';

  @override
  String get featureGroupDescription_developer =>
      'Nástroje pre pokročilých používateľov a prispievateľov.';

  @override
  String get featureLabel_voiceFeedback =>
      'Hlasová spätná väzba (syntéza reči)';

  @override
  String get featureDescription_voiceFeedback =>
      'Hlavný vypínač všetkých hlasových výstupov — hlasového kouča jazdy a hlásení staníc. Keď je vypnutý, aplikácia nikdy nespustí syntézu reči.';

  @override
  String get feedbackConsentTitle => 'Odoslať hlásenie na GitHub?';

  @override
  String get feedbackConsentBody =>
      'Tým sa vytvorí verejný ticket v našom repozitári GitHub s vašou fotografiou a OCR textom. Neodosielajú sa žiadne osobné údaje (poloha, ID účtu). Pokračovať?';

  @override
  String get feedbackConsentContinue => 'Pokračovať';

  @override
  String get feedbackConsentCancel => 'Zrušiť';

  @override
  String get feedbackConsentLater => 'Neskôr';

  @override
  String get feedbackTokenSectionTitle =>
      'Spätná väzba o neúspešnom skenovaní (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Pre automatické otvorenie GitHub ticketu pri neúspešnom skenovaní vložte GitHub PAT (rozsah `public_repo` na repozitári tankstellen). Inak je k dispozícii ručné zdieľanie.';

  @override
  String get feedbackTokenStatusSet => 'Token nakonfigurovaný';

  @override
  String get feedbackTokenStatusUnset => 'Žiadny token';

  @override
  String get feedbackTokenSet => 'Nastaviť';

  @override
  String get feedbackTokenClear => 'Vymazať';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

  @override
  String get fillUpMultiFuelHint =>
      'Toto vozidlo môže jazdiť na rôzne palivá — zapíšte to, ktoré ste skutočne natankovali';

  @override
  String get fillUpGuidanceTitle => 'Najlepší čas na tankovanie';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Aktuálna cena patrí medzi najlacnejšie za posledných $days dní — vhodný čas na tankovanie.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Ceny sú blízko $days-dňového maxima. Zvyčajne bývajú lacnejšie $window — zvážte počkanie.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Ceny rastú — zvážte čoskoro zatankovať.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Dnešná cena je okolo $days-dňového priemeru.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Správnym načasovaním môžete ušetriť asi $amount/L.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na základe $count záznamov cien',
      one: 'Na základe 1 záznamu ceny',
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
  String get fillUpGuidanceWindowGeneric => 'v iných časoch';

  @override
  String get fillUpGuidanceWeekday1 => 'v pondelky';

  @override
  String get fillUpGuidanceWeekday2 => 'v utorky';

  @override
  String get fillUpGuidanceWeekday3 => 'v stredy';

  @override
  String get fillUpGuidanceWeekday4 => 'vo štvrtky';

  @override
  String get fillUpGuidanceWeekday5 => 'v piatky';

  @override
  String get fillUpGuidanceWeekday6 => 'v soboty';

  @override
  String get fillUpGuidanceWeekday7 => 'v nedele';

  @override
  String get fillUpGuidancePartEarlyMorning => 'skoro ráno';

  @override
  String get fillUpGuidancePartMorning => 'dopoludnia';

  @override
  String get fillUpGuidancePartAfternoon => 'popoludní';

  @override
  String get fillUpGuidancePartEvening => 'večer';

  @override
  String get fillUpGuidancePartNight => 'v noci';

  @override
  String get fillUpOdometerFromCarJustNow => 'Z vášho vozidla · práve teraz';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Z vášho vozidla · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Odhad z posledného údaja z vozidla plus vzdialenosť prejdená odvtedy ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Vložiť text';

  @override
  String get pasteReceiptDialogTitle => 'Vložiť text bločku';

  @override
  String get pasteReceiptDialogHint =>
      'Vložte text bločku za palivo — e-mail, SMS alebo zdieľané PDF. Litre, cena za liter, druh paliva, celková suma a stanica sa prečítajú v zariadení a predvyplnia formulár. Nič sa neodosiela na server.';

  @override
  String get pasteReceiptFieldHint => 'Text bločku';

  @override
  String get pasteReceiptParseAction => 'Predvyplniť';

  @override
  String get pasteReceiptNoData =>
      'Z tohto textu sa nepodarilo prečítať žiadne údaje o palive — skontrolujte, či ide o bloček za palivo, a skúste to znova.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Overené adaptérom';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Nezhoduje sa s hodnotou adaptéra';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Váš záznam: $userL L. Adaptér uvádza: $adapterL L (rozdiel z merania hladiny paliva pred/po). Použiť hodnotu adaptéra?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Zachovať môj záznam';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Použiť hodnotu adaptéra';

  @override
  String get scanReceiptNoData =>
      'Nenašli sa žiadne údaje z dokladu — skúste znova';

  @override
  String get scanReceiptSuccess =>
      'Doklad naskenovaný — overte hodnoty. Klepnite na \"Nahlásiť chybu skenovania\" nižšie, ak je niečo nesprávne.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skenovanie zlyhalo: $error';
  }

  @override
  String get badScanReportTitleReceipt => 'Nahlásiť chybu skenovania — Doklad';

  @override
  String get badScanReportHint =>
      'Zdieľame fotografiu dokladu a obe sady hodnôt, aby sa nasledujúca verzia mohla naučiť toto rozloženie.';

  @override
  String get badScanReportFieldBrandLayout => 'Rozloženie značky';

  @override
  String get badScanReportFieldTotal => 'Celkom';

  @override
  String get badScanReportFieldPricePerLiter => 'Cena/L';

  @override
  String get badScanReportFieldStation => 'Stanica';

  @override
  String get badScanReportFieldFuel => 'Palivo';

  @override
  String get badScanReportFieldDate => 'Dátum';

  @override
  String get badScanReportHeaderField => 'Pole';

  @override
  String get badScanReportHeaderScanned => 'Naskenované';

  @override
  String get badScanReportHeaderYouTyped => 'Vy ste zadali';

  @override
  String get badScanReportCreateTicket => 'Vytvoriť problém';

  @override
  String get badScanReportOpenInBrowser => 'Otvoriť v prehliadači';

  @override
  String get badScanReportFallbackToShare =>
      'Odoslanie zlyhalo — ručné zdieľanie';

  @override
  String get fillUpWarningDialogTitle => 'Skontrolujte toto tankovanie';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Vybrali ste $chosenFuel, ale toto vozidlo jazdí na $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Stav tachometra $entered km je nižší než $previous km z predchádzajúceho tankovania — vzdialenosť nemôže ísť späť.';
  }

  @override
  String get fillUpWarningGoBack => 'Vrátiť sa a opraviť';

  @override
  String get fillUpWarningSaveAnyway => 'Napriek tomu uložiť';

  @override
  String get featureLabel_fleetMode => 'Fleet mode';

  @override
  String get featureDescription_fleetMode =>
      'Company-vehicle mode: your fleet assignment, the org vehicle directory, and an explicit current-vehicle switcher.';

  @override
  String get featureBlockedEnable_fleetMode =>
      'Turn TankSync on first — a fleet lives in your own database.';

  @override
  String get featureLabel_fleetManagerTools => 'Fleet manager tools';

  @override
  String get featureDescription_fleetManagerTools =>
      'Aggregate fleet cost and efficiency views for a manager — totals and exceptions, never per-employee journeys.';

  @override
  String get featureBlockedEnable_fleetManagerTools =>
      'Turn fleet mode on first.';

  @override
  String get featureGroupTitle_fleet => 'Fleet';

  @override
  String get featureGroupDescription_fleet =>
      'Company vehicles, assignments and manager reporting.';

  @override
  String get fleetExpensesTitle => 'Fuel expenses';

  @override
  String get fleetExpensesEmptyTitle => 'No expenses yet';

  @override
  String get fleetExpensesEmptyBody =>
      'Scan a fuel receipt and it appears here as a candidate you can check before submitting it.';

  @override
  String get fleetExpenseStatusDraft => 'Draft';

  @override
  String get fleetExpenseStatusNeedsReview => 'Needs review';

  @override
  String get fleetExpenseStatusSubmitted => 'Submitted';

  @override
  String get fleetExpenseStatusApproved => 'Approved';

  @override
  String get fleetExpenseStatusRejected => 'Rejected';

  @override
  String get fleetExpenseStatusExported => 'Exported';

  @override
  String get fleetExpenseStatusArchived => 'Archived';

  @override
  String get fleetExpenseUnknownStation => 'Station not read';

  @override
  String get fleetExpenseReviewTitle => 'Check this receipt';

  @override
  String get fleetExpenseNotFound => 'This expense is not on this device.';

  @override
  String get fleetExpenseArithmeticOk =>
      'Litres × price per litre matches the printed total.';

  @override
  String get fleetExpenseArithmeticMismatch =>
      'Litres × price per litre does not match the printed total. Check the numbers before you submit.';

  @override
  String get fleetExpenseArithmeticIncomplete =>
      'A number is missing, so the total cannot be checked.';

  @override
  String get fleetExpenseNeedsConfirmationTitle => 'Needs your confirmation';

  @override
  String get fleetExpenseReadTitle => 'Read from the document';

  @override
  String get fleetExpenseFieldStation => 'Station';

  @override
  String get fleetExpenseFieldDate => 'Date';

  @override
  String get fleetExpenseFieldFuel => 'Fuel grade';

  @override
  String get fleetExpenseFieldLitres => 'Volume';

  @override
  String get fleetExpenseFieldPricePerLitre => 'Price per litre';

  @override
  String get fleetExpenseFieldTotal => 'Total';

  @override
  String get fleetExpenseFieldVat => 'VAT';

  @override
  String get fleetExpenseFieldVatRate => 'VAT rate';

  @override
  String get fleetExpenseFieldPaymentReference => 'Payment reference';

  @override
  String get fleetExpenseFieldOdometer => 'Odometer';

  @override
  String get fleetExpenseValueMissing => 'Not read';

  @override
  String get fleetExpenseDocumentTitle => 'Document';

  @override
  String get fleetExpenseSourceOcrPhoto => 'Photographed receipt';

  @override
  String get fleetExpenseSourceOcrPdf => 'PDF receipt';

  @override
  String get fleetExpenseSourceEReceipt => 'Digital receipt';

  @override
  String get fleetExpenseSourceStructuredInvoice => 'Electronic invoice';

  @override
  String get fleetExpenseNotAuthoritative =>
      'A photograph is not an authoritative document, however well it was read.';

  @override
  String get fleetExpenseAuthoritative =>
      'The company treats this document as an authoritative record.';

  @override
  String get fleetExpenseAttachedToFillUp =>
      'Attached to a fill-up you already logged.';

  @override
  String fleetExpenseCorrections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields corrected',
      one: '1 field corrected',
      zero: 'No corrections',
    );
    return '$_temp0';
  }

  @override
  String get fleetExpenseNotAnAccountingRecord =>
      'Submitting hands this to your company as a claim. It is not an accounting record, and it does not decide whether you are reimbursed.';

  @override
  String get fleetExpenseConfirmAndSubmit => 'Confirm and submit';

  @override
  String get fleetExpenseFixFirst => 'Confirm the highlighted fields first';

  @override
  String get fleetExpenseAlreadySubmitted => 'Already submitted';

  @override
  String get fleetExpenseSubmitFailed => 'Could not submit this expense.';

  @override
  String get fleetManagerOverviewTitle => 'Fleet overview';

  @override
  String get fleetManagerNoFleetTitle => 'No fleet on this device';

  @override
  String get fleetManagerNoFleetBody =>
      'Join an organisation to see its vehicles, costs and expenses here.';

  @override
  String get fleetManagerUnavailableTitle => 'Figures not loaded';

  @override
  String get fleetManagerUnavailableBody =>
      'The organisation\'s figures could not be read. Check your connection and try again.';

  @override
  String get fleetManagerEmptyPeriodTitle => 'Nothing reported in this period';

  @override
  String get fleetManagerEmptyPeriodBody =>
      'No confirmed expenses fall inside the selected dates.';

  @override
  String get fleetManagerAttentionTitle => 'Needs attention';

  @override
  String get fleetManagerAttentionNone =>
      'Nothing needs attention in this period.';

  @override
  String fleetManagerAttentionCostOutlier(String vehicle) {
    return '$vehicle: cost per km well above the fleet\'s own median';
  }

  @override
  String fleetManagerAttentionLowCoverage(String vehicle) {
    return '$vehicle: less than half its fuel is backed by measured distance';
  }

  @override
  String fleetManagerAttentionNoDistance(String vehicle) {
    return '$vehicle: no odometer readings, so cost per km cannot be stated';
  }

  @override
  String fleetManagerAttentionCo2(String vehicle) {
    return '$vehicle: CO₂e not calculated — a grade in this period has no published factor';
  }

  @override
  String get fleetManagerAttentionMixedCurrency =>
      'This period mixes currencies, so there is no single total';

  @override
  String fleetManagerAttentionSuppressed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles are hidden: too few expenses to report',
      one: '1 vehicle is hidden: too few expenses to report',
    );
    return '$_temp0';
  }

  @override
  String get fleetManagerKpiSpend => 'Fuel spend';

  @override
  String get fleetManagerKpiCostPerKm => 'Cost per km';

  @override
  String get fleetManagerKpiConsumption => 'Consumption';

  @override
  String get fleetManagerKpiCo2 => 'CO₂e';

  @override
  String get fleetManagerKpiMeasuredCoverage => 'Measured coverage';

  @override
  String get fleetManagerKpiLitres => 'Fuel volume';

  @override
  String get fleetManagerKpiDistance => 'Distance';

  @override
  String fleetManagerSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
      zero: 'no expenses',
    );
    return '$_temp0';
  }

  @override
  String get fleetManagerNotCalculated => 'Not calculated';

  @override
  String get fleetManagerMultiCurrencyTotals => 'Totals by currency';

  @override
  String get fleetManagerVehiclesTitle => 'Vehicles';

  @override
  String fleetManagerVehicleSuppressed(int threshold) {
    return 'Fewer than $threshold expenses — hidden to protect the people behind the numbers';
  }

  @override
  String fleetManagerVehicleUnnamed(String code) {
    return 'Vehicle $code';
  }

  @override
  String get fleetManagerVehicleTitle => 'Vehicle';

  @override
  String get fleetManagerVehicleNotInPeriod =>
      'This vehicle reported nothing in the selected period.';

  @override
  String get fleetManagerNoJourneys =>
      'Journeys are not shown here. Fleet reporting reads confirmed expenses only — never GPS traces or engine telemetry.';

  @override
  String get fleetManagerQueueTitle => 'Expense queue';

  @override
  String get fleetManagerQueueEmptyTitle => 'Nothing to review';

  @override
  String get fleetManagerQueueEmptyBody =>
      'Submitted expenses appear here. Drafts stay with the employee.';

  @override
  String get fleetManagerQueueApprove => 'Approve';

  @override
  String get fleetManagerQueueReject => 'Reject';

  @override
  String get fleetManagerQueueDecisionFailed =>
      'The decision was not recorded. Nothing has changed.';

  @override
  String get fleetManagerQueueApproved => 'Approved';

  @override
  String get fleetManagerQueueRejected => 'Rejected';

  @override
  String get fleetManagerQueueNotAnApproval =>
      'Approval is a company decision, not an accounting record.';

  @override
  String get fleetManagerReportsTitle => 'Reports';

  @override
  String get fleetManagerCo2ScopeLabel => 'Scope';

  @override
  String get fleetManagerCo2ScopeWtw =>
      'Well-to-wheel (production, distribution and combustion)';

  @override
  String get fleetManagerCo2FactorLabel => 'Factor';

  @override
  String get fleetManagerCo2NotCalculatedBody =>
      'A fuel grade in this period has no published emission factor, so no figure is given. No undocumented factor is substituted.';

  @override
  String get fleetManagerCo2MixedVersions =>
      'This period used more than one factor version. Two methodologies are never added together.';

  @override
  String get fleetManagerExport => 'Export CSV';

  @override
  String get fleetManagerExportAudited =>
      'Exports are recorded in your organisation\'s audit log. Location and telemetry are never included.';

  @override
  String get fleetManagerExportFailed =>
      'The export was not recorded, so no file was produced.';

  @override
  String get fleetManagerExportReady => 'Export ready';

  @override
  String fleetManagerPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get fleetManagerClaimMeasured => 'Measured';

  @override
  String get fleetManagerClaimCalculated => 'Calculated';

  @override
  String get fleetManagerClaimEstimate => 'Estimate';

  @override
  String get fleetManagerClaimEnvironmental => 'Environmental estimate';

  @override
  String get fleetManagerOpenReports => 'Reports';

  @override
  String get fleetManagerOpenQueue => 'Expenses';

  @override
  String get wizardProfileFleetName => 'Company or fleet vehicle';

  @override
  String get wizardProfileFleetDescription =>
      'I drive my employer\'s car. Fleet assignment, expenses, and a clear view of what my manager can see.';

  @override
  String get fleetIdentityTitle => 'Your fleet';

  @override
  String get fleetIdentityIntro =>
      'Enter the invite code your fleet administrator gave you. If you are setting the fleet up yourself, create it below instead.';

  @override
  String get fleetInviteCodeLabel => 'Invite code';

  @override
  String get fleetScanQrCode => 'Scan QR code';

  @override
  String get fleetJoinButton => 'Join fleet';

  @override
  String get fleetCreateSectionTitle => 'I am setting up this fleet';

  @override
  String get fleetOrgNameLabel => 'Fleet name';

  @override
  String get fleetCreateButton => 'Create fleet';

  @override
  String get fleetIdentityLater =>
      'You can also do this later under Settings, then Fleet.';

  @override
  String fleetMemberOf(String org) {
    return 'You are in $org.';
  }

  @override
  String fleetYourRole(String role) {
    return 'Your role: $role';
  }

  @override
  String get fleetRoleEmployee => 'Employee';

  @override
  String get fleetRoleManager => 'Fleet manager';

  @override
  String get fleetRoleAdmin => 'Fleet administrator';

  @override
  String get fleetBlockedIdentityRequired =>
      'Joining a fleet needs an account with an e-mail address. This device still uses an anonymous account, which nobody can assign to a company — add an e-mail address in Settings, then Sync, first.';

  @override
  String get fleetBlockedCommunityBackend =>
      'A fleet cannot live on the shared community database. Your employer\'s own database, or one you were invited to, is required.';

  @override
  String get fleetBlockedSyncDisabled =>
      'Cloud sync is switched off. Set up your employer\'s database in Settings, then Sync, before joining a fleet.';

  @override
  String get fleetBlockedEnterCode =>
      'Enter the invite code your fleet administrator gave you.';

  @override
  String get fleetBlockedEnterName => 'Enter a name for the fleet.';

  @override
  String get fleetJoinErrorInvalidCode =>
      'That invite code is not valid or has expired. Ask your fleet administrator for a new one.';

  @override
  String get fleetJoinErrorAlreadyMember =>
      'This account already belongs to a fleet. Leave it before joining another one.';

  @override
  String get fleetJoinErrorNotSupported =>
      'This database does not offer fleet joining. Your administrator has to enable fleet mode on it first.';

  @override
  String get fleetJoinErrorUnavailable =>
      'The fleet could not be reached. Check your connection and try again.';

  @override
  String get fleetPrivacyTitle => 'What is shared, and what is not';

  @override
  String get fleetPrivacyDeviceTitle => 'Stays on this device';

  @override
  String get fleetPrivacyDeviceBody =>
      'Your journeys, your position and the raw data read from the adapter never leave this phone for your fleet. They are yours, for your own consumption figures and coaching.';

  @override
  String get fleetPrivacySyncTitle => 'Goes to your fleet\'s database';

  @override
  String get fleetPrivacySyncBody =>
      'Which company vehicle you are assigned to and when, plus the fill-ups and expenses you submit yourself. Nothing is sent while fleet sharing is switched off.';

  @override
  String get fleetPrivacyManagerTitle => 'What your manager can see';

  @override
  String get fleetPrivacyManagerBody =>
      'Vehicles and assignments, submitted expenses, and cost and consumption figures as fleet totals. Not your journeys, not your live position, and never a driving-style ranking of individual employees.';

  @override
  String get fleetPrivacyRetentionTitle =>
      'How long it is kept, and your controls';

  @override
  String get fleetPrivacyRetentionBody =>
      'Your employer configures how long expenses and assignment history are kept. You can export everything, switch sharing off, and delete your own data at any time in Settings, then Privacy and data.';

  @override
  String get settingsTopicFleetTitle => 'Fleet';

  @override
  String get settingsTopicFleetSubtitle =>
      'Your organisation, your role and what your manager can see.';

  @override
  String get settingsTopicFleetKeywords =>
      'fleet, company car, employer, organisation, manager, assignment, expenses';

  @override
  String get fleetSettingsNoFleet =>
      'You are not in a fleet yet. Join one with an invite code, or create one if you administer it.';

  @override
  String get fleetSettingsOrgLabel => 'Fleet';

  @override
  String get fleetSettingsRoleLabel => 'Your role';

  @override
  String get fleetSettingsSharingLabel => 'Sharing with your fleet';

  @override
  String get fleetSettingsSharingOn =>
      'On. The fill-ups and expenses you submit reach your fleet.';

  @override
  String get fleetSettingsSharingOff =>
      'Off. Nothing fleet-related leaves this device.';

  @override
  String get fleetSettingsManagerSeesTitle => 'What my manager can see';

  @override
  String get fleetVisibilityVehicle =>
      'Which company vehicle you are assigned to, and for which period.';

  @override
  String get fleetVisibilityExpenses =>
      'The fill-ups and expenses you submit yourself.';

  @override
  String get fleetVisibilityCosts =>
      'Cost per kilometre and consumption, as part of fleet totals.';

  @override
  String get fleetVisibilityNeverJourneys =>
      'Never your journeys, your live position or raw adapter data.';

  @override
  String get fleetVisibilityNeverBehaviour =>
      'Never a driving-style ranking of individual employees.';

  @override
  String get fleetSettingsStale =>
      'These fleet details could not be refreshed recently.';

  @override
  String get fleetSettingsExpired =>
      'These fleet details are out of date. Reconnect so they can be refreshed before you choose a vehicle.';

  @override
  String get fleetVehicleCurrentLabel => 'Current vehicle';

  @override
  String get fleetVehicleNoneAssigned => 'No vehicle assigned';

  @override
  String get fleetVehicleSwitchTitle => 'Choose your vehicle';

  @override
  String get fleetVehicleSwitchHelper =>
      'Switching applies from now on. Everything you already logged keeps the vehicle it was logged with.';

  @override
  String get fleetVehicleSearchLabel => 'Fleet code, model or registration';

  @override
  String get fleetVehicleSearchEmpty =>
      'No assigned vehicle matches your search.';

  @override
  String get fleetVehicleCurrentBadge => 'Current';

  @override
  String get fleetVehicleStaleBadge => 'Offline copy';

  @override
  String get fleetVehicleStaleNotice =>
      'This is the vehicle list your device downloaded last. It may not show a very recent handover.';

  @override
  String get fleetVehicleExpiredNotice =>
      'Your vehicle list is too old to switch safely. Connect to your fleet to refresh it.';

  @override
  String get fleetVehicleNeedsConfirmationTitle => 'Vehicle needs confirmation';

  @override
  String get fleetVehicleNeedsConfirmationBody =>
      'The adapter and the vehicle data point at different cars. Pick the right one — nothing is attributed until you do.';

  @override
  String fleetVehicleSemanticsCurrent(String vehicle) {
    return 'Current vehicle: $vehicle';
  }

  @override
  String get fleetVehicleSemanticsChange => 'Change current vehicle';

  @override
  String get fillUpSectionWhatTitle => 'Čo ste natankovali';

  @override
  String get fillUpSectionWhatSubtitle => 'Palivo, množstvo, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kde ste boli';

  @override
  String get fillUpSectionWhereSubtitle => 'Stanica, tachometer, poznámky';

  @override
  String get fillUpImportReceiptLabel => 'Doklad';

  @override
  String get fillUpPricePerLiterLabel => 'Cena za liter';

  @override
  String get vehicleHeaderUntitled => 'Nové vozidlo';

  @override
  String get vehicleSectionIdentityTitle => 'Identita';

  @override
  String get vehicleSectionIdentitySubtitle => 'Názov a VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Pohon';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Ako sa toto vozidlo pohybuje';

  @override
  String get profileSectionDisplayStations => 'Zobrazenie a stanice';

  @override
  String get profileSectionRegion => 'Región';

  @override
  String get fuelAndTankTitle => 'Fuel & Tank';

  @override
  String get fuelAndTankOpenAction => 'What\'s in my tank?';

  @override
  String get fuelAndTankNoVehicle =>
      'Select a vehicle that runs on liquid fuel to see its tank and how it behaves on each fuel.';

  @override
  String get fuelAndTankMixTitle => 'In your tank now';

  @override
  String fuelAndTankMixFocalAtLeast(String percent) {
    return '≥ $percent %';
  }

  @override
  String fuelAndTankMixFocalExact(String percent) {
    return '$percent %';
  }

  @override
  String fuelAndTankMixShareAtLeast(String percent, String fuel) {
    return '≥ $percent % $fuel';
  }

  @override
  String fuelAndTankMixShareExact(String percent, String fuel) {
    return '$percent % $fuel';
  }

  @override
  String fuelAndTankMixUnknownShare(String percent) {
    return '$percent % unknown';
  }

  @override
  String get fuelAndTankMixExplainPartial =>
      'The shares are guaranteed minimums. The unknown part could be any of these fuels — it grows with fill-ups logged without a tank level.';

  @override
  String get fuelAndTankMixExplainExact =>
      'Every litre is accounted for by your fill-up history.';

  @override
  String get fuelAndTankMixUnknownTitle => 'Mix unknown';

  @override
  String get fuelAndTankMixUnknownBody =>
      'Your fill-up history can\'t tell what is in the tank yet. A fill-up to a full tank makes the mix known again.';

  @override
  String fuelAndTankMixVolumeExact(String litres) {
    return '$litres in the tank';
  }

  @override
  String fuelAndTankMixVolumeRange(String min, String max) {
    return 'Between $min and $max in the tank';
  }

  @override
  String fuelAndTankMixVolumeAtLeast(String min) {
    return 'At least $min in the tank';
  }

  @override
  String fuelAndTankMixBarSemantics(String summary) {
    return 'Tank mix: $summary';
  }

  @override
  String get fuelAndTankCompatTitle => 'Fuels for this vehicle';

  @override
  String get fuelAndTankCompatApproved => 'Approved in your vehicle settings';

  @override
  String get fuelAndTankCompatUnconfirmed =>
      'Fit, but not confirmed for this vehicle';

  @override
  String get fuelAndTankCompatUnknown =>
      'This vehicle has no fuel set, so its approved fuels are unknown. Set its fuel in the vehicle settings.';

  @override
  String get fuelAndTankCompatHint =>
      'Only your vehicle settings count as approval — a fuel that fits the filler neck is not necessarily approved.';

  @override
  String get fuelAndTankBehaviourTitle => 'How your car behaves';

  @override
  String get fuelAndTankObservedBadge => 'Your car';

  @override
  String get fuelAndTankMetricConsumption => 'Consumption';

  @override
  String get fuelAndTankMetricCostPerKm => 'Cost per km';

  @override
  String get fuelAndTankMetricRange => 'Range per tank';

  @override
  String get fuelAndTankMetricCo2e => 'CO2e per km';

  @override
  String fuelAndTankCostPerKmValue(String amount, String currency) {
    return '$amount $currency/km';
  }

  @override
  String fuelAndTankCo2eValue(String grams) {
    return '$grams g/km';
  }

  @override
  String get fuelAndTankNotEnoughEvidence => 'Not enough evidence yet';

  @override
  String get fuelAndTankProvenanceMeasured => 'Measured';

  @override
  String get fuelAndTankProvenanceEstimated => 'Estimated';

  @override
  String get fuelAndTankProvenanceGeneral => 'General information';

  @override
  String fuelAndTankSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get fuelAndTankConfidenceLow => 'low confidence';

  @override
  String get fuelAndTankConfidenceMedium => 'medium confidence';

  @override
  String get fuelAndTankConfidenceHigh => 'high confidence';

  @override
  String fuelAndTankInterval(String low, String high) {
    return '95 % range $low – $high';
  }

  @override
  String get fuelAndTankInsufficientNoEvidence => 'No data on this fuel yet';

  @override
  String get fuelAndTankInsufficientTooFewSamples => 'Too few samples so far';

  @override
  String get fuelAndTankInsufficientTooLittleDistance =>
      'Not enough distance driven yet';

  @override
  String get fuelAndTankInsufficientCapacityUnknown =>
      'Needs the tank capacity in your vehicle settings';

  @override
  String get fuelAndTankInsufficientNoCo2eFactor =>
      'No CO2e factor on record for this fuel';

  @override
  String get fuelAndTankInsufficientContextNotPure =>
      'Not available for a mixed tank';

  @override
  String get fuelAndTankInsufficientTooUncertain => 'Too uncertain to show';

  @override
  String get fuelAndTankInsufficientConditionCoverage =>
      'Can\'t be adjusted for conditions yet — hills and traffic aren\'t recorded';

  @override
  String get fuelAndTankInsufficientMixedCurrencies =>
      'Several currencies — no single figure';

  @override
  String get fuelAndTankUncontrolled =>
      'Not adjusted for driving conditions yet — hills, cold starts and traffic are still in these figures.';

  @override
  String get fuelAndTankBasisReferenceWindows =>
      'From full-tank to full-tank fill-ups';

  @override
  String get fuelAndTankBasisMeasuredTrips =>
      'From engine readings on your trips';

  @override
  String get fuelAndTankBasisEstimatedTrips => 'Estimated from your trips';

  @override
  String get fuelAndTankBasisMeasuredResiduals =>
      'From engine readings, adjusted for driving conditions';

  @override
  String get fuelAndTankBasisEstimatedResiduals =>
      'Estimated, adjusted for driving conditions';

  @override
  String get fuelAndTankBasisDerived => 'Calculated from your other figures';

  @override
  String fuelAndTankMixedContext(String first, String second) {
    return 'Mixed $first + $second';
  }

  @override
  String get fuelAndTankNoEvidenceRow => 'Not driven on this fuel yet';

  @override
  String get fuelAndTankDetailsToggle => 'How these figures are made';

  @override
  String fuelAndTankModelVersions(String profile, String blend) {
    return 'Behaviour model v$profile · blend model v$blend';
  }

  @override
  String fuelAndTankCompareMore(String fuel, String percent, String other) {
    return '$fuel uses $percent % more than $other';
  }

  @override
  String fuelAndTankCompareLess(String fuel, String percent, String other) {
    return '$fuel uses $percent % less than $other';
  }

  @override
  String fuelAndTankCompareSame(String fuel, String other) {
    return '$fuel and $other use about the same';
  }

  @override
  String fuelAndTankCompareInsufficient(String fuel, String other) {
    return 'Not enough evidence yet to compare $fuel with $other';
  }

  @override
  String get fuelAndTankCompareWithinUncertainty =>
      'The difference is still within the uncertainty.';

  @override
  String get fuelAndTankCompareAdjusted => 'Adjusted for driving conditions.';

  @override
  String get fuelAndTankCompareNeedsTwo =>
      'Drive on two different fuels to compare them.';

  @override
  String get fuelAndTankFactsTitle => 'General fuel facts';

  @override
  String get fuelAndTankFactsSubtitle =>
      'From the fuel standards — not measured on your car.';

  @override
  String fuelAndTankFactPetrol(String fuel, String petrol, String open) {
    return '$fuel: at least $petrol % petrol; up to $open % can be ethanol.';
  }

  @override
  String fuelAndTankFactEthanol(String fuel, String ethanol) {
    return '$fuel: at least $ethanol % ethanol; the rest varies with the season.';
  }

  @override
  String fuelAndTankFactDiesel(String fuel, String diesel, String open) {
    return '$fuel: at least $diesel % diesel; up to $open % can be biodiesel.';
  }

  @override
  String fuelAndTankFactLpg(String fuel) {
    return '$fuel: liquefied petroleum gas, a fuel of its own.';
  }

  @override
  String fuelAndTankFactOctane(String fuel) {
    return '$fuel names the octane rating, not the ethanol content.';
  }

  @override
  String get fuelAndTankObjectiveTitle => 'Optimise the next fill for';

  @override
  String get fuelAndTankObjectiveCost => 'Lowest cost per km';

  @override
  String get fuelAndTankObjectiveConsumption => 'Lowest consumption';

  @override
  String get fuelAndTankObjectiveCo2e => 'Lowest CO2e';

  @override
  String get fuelAndTankObjectiveBalanced => 'Cost and CO2e';

  @override
  String get fuelAndTankObjectiveRange => 'Longest range';

  @override
  String get fuelAndTankNextFillTitle => 'Next fill';

  @override
  String fuelAndTankOutcomeRecommend(String fuel) {
    return 'Fill $fuel next';
  }

  @override
  String get fuelAndTankOutcomeNoAdvantage =>
      'No fuel is clearly better right now';

  @override
  String get fuelAndTankOutcomeInsufficient =>
      'Not enough evidence to recommend a fuel yet';

  @override
  String get fuelAndTankOutcomeTradeOff =>
      'A trade-off: one fuel is cheaper, another emits less';

  @override
  String get fuelAndTankOutcomeNoCompatible =>
      'No priced fuel is confirmed for this vehicle';

  @override
  String get fuelAndTankOutcomeCompatibilityUnknown =>
      'Approved fuels unknown — no recommendation';

  @override
  String fuelAndTankDecisionConfidence(String confidence) {
    return 'Decision made with $confidence';
  }

  @override
  String get fuelAndTankNoPricesTitle => 'No price comparison possible';

  @override
  String get fuelAndTankNoPricesBody =>
      'None of your favourite stations has a current price for a fuel this vehicle can take. Add stations to your favourites to compare.';

  @override
  String fuelAndTankPricesSource(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cheapest prices for $count fuels among your favourite stations',
      one: 'Cheapest price for 1 fuel among your favourite stations',
    );
    return '$_temp0';
  }

  @override
  String get fuelAndTankReasonCapabilityUnknown =>
      'This vehicle\'s approved fuels aren\'t set, so nothing can be recommended.';

  @override
  String get fuelAndTankReasonGradeNotApproved =>
      'Not confirmed as approved in your vehicle settings.';

  @override
  String get fuelAndTankReasonFillVolumeUnknown =>
      'The size of the next fill is unknown — set the tank capacity and log a full-tank fill-up.';

  @override
  String get fuelAndTankReasonResultingBlendUnknown =>
      'The tank mix after this fill can\'t be determined.';

  @override
  String get fuelAndTankReasonNoBehaviourEvidence =>
      'No consumption on record for this mix yet.';

  @override
  String get fuelAndTankReasonInterpolated =>
      'Estimated from how your car burns each fuel on its own.';

  @override
  String get fuelAndTankReasonConfoundersUncontrolled =>
      'Not adjusted for driving conditions yet.';

  @override
  String get fuelAndTankReasonNoCo2eFactor =>
      'No CO2e factor on record for this fuel mix.';

  @override
  String get fuelAndTankReasonCapacityUnknown =>
      'Range needs the tank capacity in your vehicle settings.';

  @override
  String get fuelAndTankReasonDetourNotPriced =>
      'The detour to the station isn\'t priced in.';

  @override
  String get fuelAndTankReasonDetourIncluded =>
      'The detour to the station is priced in.';

  @override
  String get fuelAndTankReasonOnlyOneCandidate =>
      'Only one fuel has a price, so there is nothing to compare.';

  @override
  String get fuelAndTankReasonUnevaluatedAlternatives =>
      'Some fuels couldn\'t be evaluated yet.';

  @override
  String get fuelAndTankReasonUncertaintyDominates =>
      'The difference is smaller than the uncertainty in your data.';

  @override
  String get fuelAndTankReasonBelowMaterialThreshold =>
      'The difference is too small to be worth switching.';

  @override
  String get fuelAndTankCandidatesToggle => 'Compare the fuels';

  @override
  String fuelAndTankCandidatePrice(String price) {
    return 'Pump price $price';
  }

  @override
  String fuelAndTankCandidateFill(String litres) {
    return 'Filling $litres';
  }

  @override
  String fuelAndTankCandidateResultingMix(String mix) {
    return 'Tank after this fill: $mix';
  }

  @override
  String fuelAndTankExcludedLine(String fuel, String reason) {
    return '$fuel — $reason';
  }

  @override
  String fuelAndTankTradeOffCheaper(
    String amount,
    String currency,
    String other,
  ) {
    return '$amount $currency/km cheaper than $other';
  }

  @override
  String fuelAndTankTradeOffDearer(
    String amount,
    String currency,
    String other,
  ) {
    return '$amount $currency/km dearer than $other';
  }

  @override
  String fuelAndTankTradeOffCo2eLess(String grams, String other) {
    return '$grams g CO2e/km less than $other';
  }

  @override
  String fuelAndTankTradeOffCo2eMore(String grams, String other) {
    return '$grams g CO2e/km more than $other';
  }

  @override
  String fuelAndTankBreakEvenPrice(String fuel, String price, String other) {
    return 'Break-even: $fuel at $price costs the same per km as $other';
  }

  @override
  String fuelAndTankBreakEvenConsumption(String other, String consumption) {
    return 'At today\'s prices it ties with $other at $consumption';
  }

  @override
  String fuelAndTankCostPerKgCo2e(String fuel, String amount) {
    return '$fuel avoids CO2e at $amount per kg';
  }

  @override
  String fuelAndTankConvergenceAlready(String percent, String fuel) {
    return 'The tank already holds at least $percent % $fuel.';
  }

  @override
  String fuelAndTankConvergenceReachable(
    int count,
    String fuel,
    String percent,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills of $fuel bring the tank to at least $percent %.',
      one: '1 fill of $fuel brings the tank to at least $percent %.',
    );
    return '$_temp0';
  }

  @override
  String fuelAndTankConvergenceUnreachable(
    String fuel,
    String percent,
    String count,
  ) {
    return '$fuel can\'t reach $percent % within $count fills.';
  }

  @override
  String get fuelAndTankConvergenceNotComputable =>
      'How quickly the tank changes over can\'t be computed yet.';

  @override
  String get fuelAndTankExcludedTitle => 'Left out';

  @override
  String fuelAndTankPricesSourceNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cheapest prices for $count fuels among the stations of your last search, detour included',
      one:
          'Cheapest price for 1 fuel among the stations of your last search, detour included',
    );
    return '$_temp0';
  }

  @override
  String fuelAndTankConvergenceTolerance(String tolerance, String target) {
    return 'Counted as reached within $tolerance points of the $target % target.';
  }

  @override
  String fuelAndTankMaterialThreshold(String percent) {
    return 'A fuel is only suggested when it is at least $percent % better.';
  }

  @override
  String get vehicleFlexFuelApprovedLabel => 'Approved for E85 (flex-fuel)';

  @override
  String get vehicleFlexFuelApprovedHelper =>
      'Only if the manufacturer approves E85. Fuel & Tank then compares E85 even when you usually fill another fuel.';

  @override
  String get fuelEfficiencyCardTitle => 'Náklady na kilometer podľa paliva';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Na ktorú zmes paliva sa skutočne jazdí najlacnejšie';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Najlacnejšie na km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Čisté';

  @override
  String get fuelEfficiencyMixBadge => 'Zmes';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Prevažne $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Náklady/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Celkom minuté';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tankovaní',
      few: '$count tankovania',
      one: '1 tankovanie',
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
      'Zaznamenajte aspoň dve plné nádrže na každé zloženie, aby bolo možné určiť najlacnejšie.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Nádrže sa zoskupujú podľa zloženia: nádrž je čistá, keď jedno palivo tvorí aspoň 85 %, inak ide o zmes.';

  @override
  String get fuelNameE5 => 'Benzín 95';

  @override
  String get fuelNameE10 => 'Benzín 95 E10';

  @override
  String get fuelNameE98 => 'Benzín 98';

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
  String get fuelNameElectric => 'Elektrina';

  @override
  String tankReportRecordedSummary(String pct, String value, String residual) {
    return 'Recorded trips cover $pct % of this tank and average $value · $residual % gap after calibration';
  }

  @override
  String tankReportRecordedSummaryNoResidual(String pct, String value) {
    return 'Recorded trips cover $pct % of this tank and average $value';
  }

  @override
  String get calibrationModeLabel => 'Režim kalibrácie';

  @override
  String get calibrationModeRule => 'Pravidlami riadený';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Pravidlami riadený priradí každú jazdnú vzorku presne jednej situácii. Fuzzy ju rozdelí medzi všetky podľa toho, ako dobre každá vyhovuje — plynulejšie okolo 60 km/h alebo pri meniacich sa skrátkach, ale pomalšie na naplnenie všetkých skupín.';

  @override
  String gdprPolicyLink(int version) {
    return 'Zásady ochrany osobných údajov (verzia $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Súhlas udelený $date · verzia zásad $version';
  }

  @override
  String get consentNotRecorded => 'Zatiaľ nebol zaznamenaný žiadny súhlas';

  @override
  String serverErasurePartial(String tables) {
    return 'Niektoré údaje na serveri sa nepodarilo vymazať: $tables. Skúste to znova alebo kontaktujte vývojára s týmto zoznamom.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Niektoré miestne údaje sa nepodarilo vymazať: $steps. Reštartujte aplikáciu a skúste to znova.';
  }

  @override
  String get myCommunityReportsTitle => 'Moje komunitné hlásenia';

  @override
  String get myCommunityReportsEmpty => 'Zatiaľ ste neodoslali žiadne hlásenie';

  @override
  String get deleteReportTooltip => 'Vymazať toto hlásenie';

  @override
  String get reportDeleted => 'Hlásenie vymazané';

  @override
  String get reportDeleteFailed => 'Hlásenie sa nepodarilo vymazať';

  @override
  String get tileProxyToggleTitle =>
      'Načítavať mapové dlaždice cez proxy Sparkilo';

  @override
  String get tileProxyToggleSubtitle =>
      'Zapnuté: zobrazený výrez mapy a vaša IP adresa sa dostanú na server vývojára v EÚ, ktorý dlaždice stiahne z OpenStreetMap. Vypnuté: dlaždice sa načítavajú priamo z tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle => 'Načítavať logá značiek z internetu';

  @override
  String get remoteLogosToggleSubtitle =>
      'Predvolene vypnuté: zobrazujú sa vstavané zástupné obrázky. Zapnuté: logá sa sťahujú z logo.clearbit.com, ktoré vidí vašu IP adresu.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName uložené do Stiahnuté — obsahuje $count súborov';
  }

  @override
  String get privacyExportAllFailed => 'Exportný súbor sa nepodarilo zapísať';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Prevádzkuje $operator · Supabase, EÚ (Frankfurt) · synchronizuje obľúbené, upozornenia, vozidlá vrátane VIN, tankovania, hodnotenia, hlásenia a — ak to zapnete — jazdy s GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Prevádzkovateľom údajov ste vy — váš vlastný projekt Supabase, my ho nikdy nevidíme';

  @override
  String get syncModeJoinControllerNotice =>
      'Prevádzkovateľom vašich údajov je ten, kto vlastní zdieľanú databázu';

  @override
  String get ugcPublicNoticeTitle => 'Zdieľané s ostatnými používateľmi';

  @override
  String get ugcPublicNoticeBody =>
      'Toto je uložené v synchronizačnej databáze pod vaším pseudonymným ID používateľa. V Komunite Sparkilo si to môže prečítať každý prihlásený používateľ. Kedykoľvek to môžete vymazať v TankSync → Transparentnosť údajov.';

  @override
  String get blockedAuthorsTitle => 'Blokovaní používatelia';

  @override
  String get blockedAuthorsDescription =>
      'Obsah zdieľaný týmito používateľmi je na tomto zariadení skrytý. Odblokujte ich, aby ste ho znova videli.';

  @override
  String get blockedAuthorsEmpty => 'Žiadni blokovaní používatelia';

  @override
  String get blockedAuthorsUnblock => 'Odblokovať';

  @override
  String get coachingGpsLiftOff => 'Uvoľniť plyn';

  @override
  String get coachingGpsAnticipateBrake => 'Predvídať';

  @override
  String get coachingGpsSmoothAccel => 'Plynulé zrýchlenie';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Stopa pokrýva $pct % — najdlhšia medzera $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Stopa pokrýva $pct % — žiadne medzery nezistené';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'aplikácia na pozadí';

  @override
  String get gpsCoverageAttrOsBatching => 'systém združoval polohy do dávok';

  @override
  String get gpsCoverageAttrGateRejected => 'polohy odfiltrované';

  @override
  String get gpsCoverageAttrDeliveryStall => 'oneskorené doručenie';

  @override
  String get gpsCoverageAttrSignalLoss => 'strata signálu';

  @override
  String get gpsCoverageAttrUnknown => 'neznáma príčina';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Aplikácia bola na pozadí bez služby v popredí, takže systém obmedzil GPS. Nechajte počas záznamu zapnutú obrazovku alebo zapnite záznam na pozadí, keď bude k dispozícii.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Systém doručil polohy neskoro a v dávkach; stopa sa doplnila dodatočne, takže sa v skutočnosti stratilo len málo údajov.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Zašumené polohy v tomto úseku boli odfiltrované, aby údaj o vzdialenosti zostal poctivý.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Polohy boli určené včas, ale do aplikácie dorazili neskoro — telefón bol zaneprázdnený (často opätovné pripájanie Bluetooth). Príjem bol v poriadku.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Príjem GPS vypadol — zvyčajne tunel, kryté parkovisko alebo hustá mestská zástavba.';

  @override
  String get gpsCoverageHintUnknown =>
      'Táto jazda neobsahuje informácie o stave aplikácie počas medzery, takže príčinu nemožno určiť.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'rušenie pri opätovnom pripájaní OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Medzera sa zhoduje s opätovným pripájaním OBD2 — spojenie s adaptérom sa obnovovalo, kým príjem GPS stál. Oprava spojenia s adaptérom opraví aj stopu.';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostika vzorkovania GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps medzier',
      one: '1 medzera',
      zero: 'žiadne medzery',
    );
    return '$count vzoriek · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Medián intervalu: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Zachytené počas záznamu pre overenie kadencie GPS počas spánku telefónu.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Najväčšia medzera: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Obnovené';

  @override
  String get gpsLifecyclePaused => 'Pozastavené';

  @override
  String get gpsLifecycleInactive => 'Neaktívne';

  @override
  String get gpsKpiVerdictGood => 'Úsporná';

  @override
  String get gpsKpiVerdictModerate => 'Priemerná';

  @override
  String get gpsKpiVerdictAggressive => 'Agresívna';

  @override
  String get gpsKpiInterpretationGood =>
      'Plynulá, úsporná jazda — takto vyzerá efektivita.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Celkom bežná jazda — o niečo jemnejšia práca s plynom by ušetrila viac.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energeticky náročná jazda — ubratie plynu a častejší dojazd by znížili spotrebu.';

  @override
  String get gpsMatrixMaturityCold => 'Studená';

  @override
  String get gpsMatrixMaturityWarming => 'Zahrieva sa';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergujúca';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'Matica GPS sa zahrieva ($count úprav). Odhady dočasné.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'Matica GPS konverguje ($count tankovaní). Odhady použiteľné, môžu sa líšiť o niekoľko %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'Matica GPS konvergovala ($count tankovaní). Odhady do ~2 % skutočnej spotreby.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'Odhadovaná hodnota GPS (~) — na tomto výlete nie je snímač paliva. Číslo je modelované z rýchlosti a kalibrácie vášho vozidla; presnosť sa zlepšuje s dozrievaním matice.';

  @override
  String get gpsRoadUseCardTitle => 'Ako ste využili cestu';

  @override
  String get gpsRoadUseSpeedSection => 'Kde ste strávili čas';

  @override
  String get gpsRoadUseSpeedIdle => 'Státie (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Mesto (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Cesta (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Rýchlo (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Ako ste sa pohybovali';

  @override
  String get gpsRoadUsePhaseAccel => 'Zrýchľovanie';

  @override
  String get gpsRoadUsePhaseSteady => 'Ustálená rýchlosť';

  @override
  String get gpsRoadUsePhaseCoast => 'Dojazd';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Veľa dojazdu — nechať auto ísť zotrvačnosťou namiesto brzdenia šetrí palivo. Pekné.';

  @override
  String get gpsRoadUseSource => 'Z vašej stopy GPS';

  @override
  String get hapticEcoCoachSettingTitle => 'Eko koučing v reálnom čase';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Jemná haptika + tip na obrazovke, keď šliahnete plyn pri jazde na stálo';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Šetrite plynom — voľný beh šetrí viac';

  @override
  String highwayViaExit(String ref, String km) {
    return 'cez výjazd $ref · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigovať na $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Odstrániť $name z obľúbených';
  }

  @override
  String get showOnMapSemanticLabel => 'Zobraziť stanice na mape';

  @override
  String get searchResultsSemanticLabel => 'Výsledky vyhľadávania';

  @override
  String get searchCriteriaSemanticLabel =>
      'Súhrn kritérií vyhľadávania. Ťuknutím upravíte.';

  @override
  String get noFavoritesSemanticLabel =>
      'Zatiaľ žiadne obľúbené. Ťuknutím na hviezdičku pri stanici ju uložíte ako obľúbenú.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stanica je otvorená',
      'false': 'Stanica je zatvorená',
      'other': 'Stanica je zatvorená',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Krajina $name, vybraté',
      'false': 'Krajina $name',
      'other': 'Krajina $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Jazyk $name, vybraté',
      'false': 'Jazyk $name',
      'other': 'Jazyk $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Zoradiť podľa $option, vybraté',
      'false': 'Zoradiť podľa $option',
      'other': 'Zoradiť podľa $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Palivo $type, vybraté',
      'false': 'Palivo $type',
      'other': 'Palivo $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Nabíjacia stanica $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Štít súkromia s kvapkou paliva';

  @override
  String get globeIllustrationSemantic => 'Glóbus so značkami čerpacích staníc';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Čerpací stojan s cenovým tickerom';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, zdroj údajov: $provider, $keyRequirement, druhy paliva: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Vyžaduje sa kľúč API';

  @override
  String get countryInfoNoKeyNeeded => 'Zadarmo, bez kľúča';

  @override
  String countryInfoDataSource(String provider) {
    return 'Údaje: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Druhy paliva: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon Key';

  @override
  String get anonKeyHideTooltip => 'Skryť kľúč';

  @override
  String get anonKeyShowTooltip => 'Zobraziť kľúč pre overenie';

  @override
  String anonKeyTooLong(int length) {
    return 'Kľúč je príliš dlhý ($length znakov) — skontrolujte nadbytočný text';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Kľúč vyzerá správne ($length znakov)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Kľúč by mal byť JWT (hlavička.obsah.podpis)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Kľúč môže byť skrátený ($length z ~208 očakávaných znakov)';
  }

  @override
  String get anonKeyExceedsMax => 'Kľúč prekračuje maximálnu dĺžku';

  @override
  String get qrShareTitle => 'Zdieľať vašu databázu';

  @override
  String get qrShareSubtitle =>
      'Ostatní môžu naskenovať tento QR kód pre pripojenie';

  @override
  String get qrShareCopyAsText => 'Kopírovať ako text';

  @override
  String get authInfoTitle => 'Prečo vytvoriť účet?';

  @override
  String get authInfoBenefit1 =>
      '• Synchronizovať obľúbené, upozornenia a uložené trasy naprieč zariadeniami';

  @override
  String get authInfoBenefit2 =>
      '• Pripravte trasu na telefóne, použite ju v aute';

  @override
  String get authInfoBenefit3 =>
      '• Žiadne údaje sa nezdieľajú s tretími stranami';

  @override
  String get authInfoBenefit4 => '• Účet môžete kedykoľvek odstrániť';

  @override
  String get apiKeySetupTitle => 'Nastavenie kľúča API (voliteľné)';

  @override
  String get apiKeySetupDescription =>
      'Zaregistrujte sa pre bezplatný kľúč API alebo preskočte a preskúmajte aplikáciu s demo dátami.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Registrácia $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Zadaním kľúča API prijímate podmienky $provider. Ďalšia distribúcia dát je zakázaná.';
  }

  @override
  String get calculatorDistanceHint => 'napr. 150';

  @override
  String get calculatorConsumptionHint => 'napr. 7,0';

  @override
  String get calculatorPriceHint => 'napr. 1,899';

  @override
  String get glideCoachBetaTitle => 'Beta koučingu plachtenia (experimentálne)';

  @override
  String get glideCoachBetaSubtitle =>
      'Jemná haptika pri spomaľovaní pred červenou. Vypnuté štandardne — riziko rozptyľovania.';

  @override
  String get consentSyncTripsTitle => 'Synchronizovať záznamy jázd';

  @override
  String get consentSyncTripsSubtitle =>
      'Zálohovať OBD2 + GPS jazdy do TankSync. Naprieč zariadeniami, dobrovoľné.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Zapnite synchronizáciu s cloudom vyššie pre zálohovanie jázd.';

  @override
  String get consentSyncTripsAnonymousHint =>
      'Jazdy sa zálohujú pod anonymným účtom tohto zariadenia. Prihláste sa e-mailom, aby ste sa k nim dostali z iných zariadení.';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Neplatný odkaz';

  @override
  String invalidLinkBody(String path) {
    return 'Odkaz \"$path\" nie je platný.';
  }

  @override
  String get home => 'Domov';

  @override
  String get accelBrakeCardTitle => 'Zrýchlenie a brzdenie';

  @override
  String get accelBrakeHardAccel => 'Prudké zrýchlenia';

  @override
  String get accelBrakeHardBrake => 'Prudké brzdenia';

  @override
  String get accelBrakeSharpCorner => 'Ostré zákruty';

  @override
  String get accelBrakeSource => 'Zo snímačov pohybu telefónu';

  @override
  String lessonHardBrake(String count) {
    return '$count udalostí prudkého brzdenia';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Predvídajte zastávky a skôr uvoľnite plyn — prudké brzdenie premárni palivo, ktoré ste práve spotrebovali na nabratie rýchlosti.';

  @override
  String lessonSharpCornering(String count) {
    return '$count ostrých zákrut';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Spomaľte pred zákrutou, nie v nej — prudké kútovanie shodí rýchlosť, ktorú potom musíte znova nabrať.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Posledných $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Jednotka spotreby';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Ako sa spotreba paliva zobrazuje v celej aplikácii';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automaticky ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Okno živej spotreby';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Priemeruje živú hodnotu za posledných niekoľko sekúnd – dlhšie je pokojnejšie, kratšie reaguje rýchlejšie';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'odh. $unit';
  }

  @override
  String get locationConsentTitle => 'Prístup k polohe';

  @override
  String get locationConsentSubtitle =>
      'Táto aplikácia chce použiť vašu polohu na vyhľadanie čerpacích staníc vo vašom okolí.';

  @override
  String get locationConsentWhatHappens =>
      'Čo sa deje s údajmi o vašej polohe:';

  @override
  String get locationConsentBulletApi =>
      'Vaše súradnice sa odosielajú do API cien palív na vyhľadanie blízkych staníc.';

  @override
  String get locationConsentBulletNoServer =>
      'Vaša poloha sa neukladá na žiadnom serveri — žiadny server neexistuje.';

  @override
  String get locationConsentBulletNoTracking =>
      'Údaje o polohe sa nepoužívajú na reklamu, analytiku ani sledovanie.';

  @override
  String get locationConsentRevoke =>
      'Prístup k polohe môžete kedykoľvek odvolať v nastaveniach systému. Prípadne môžete vyhľadávať podľa PSČ.';

  @override
  String get locationConsentLegalBasis =>
      'Právny základ: čl. 6 ods. 1 písm. a) GDPR (súhlas)';

  @override
  String get loyaltySettingsTitle => 'Vernostné palivové karty';

  @override
  String get loyaltySettingsSubtitle =>
      'Uplatniť vernostné zľavy na zobrazené ceny';

  @override
  String get loyaltyMenuTitle => 'Vernostné palivové karty';

  @override
  String get loyaltyMenuSubtitle =>
      'Uplatniť zľavy za liter od Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Pridať kartu';

  @override
  String get loyaltyAddCardSheetTitle => 'Pridať vernostnú palivovú kartu';

  @override
  String get loyaltyBrandLabel => 'Značka';

  @override
  String get loyaltyCardLabelLabel => 'Označenie (voliteľné)';

  @override
  String get loyaltyDiscountLabel => 'Zľava (za liter)';

  @override
  String get loyaltyDiscountInvalid => 'Zadajte kladné číslo';

  @override
  String get loyaltyDeleteConfirmTitle => 'Odstrániť kartu?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Táto karta prestane uplatňovať svoju zľavu.';

  @override
  String get loyaltyEmptyTitle => 'Zatiaľ žiadne vernostné palivové karty';

  @override
  String get loyaltyEmptyBody =>
      'Pridajte kartu pre automatické uplatňovanie vašej zľavy za liter na zodpovedajúce stanice.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Zistený nárast otáčok voľnobehu';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Otáčky voľnobehu narástli o $percent% počas vašich posledných $tripCount jázd. Možný skorý príznak upchateného vzduchového filtra alebo driftu senzora.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Možné obmedzenie nasávania';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Prietok paliva pri plávnej jazde klesol o $percent% počas vašich posledných $tripCount jázd. Možný príznak upchateného vzduchového filtra alebo obmedzeného nasávania — stojí za kontrolu.';
  }

  @override
  String get maintenanceActionDismiss => 'Zatvoriť';

  @override
  String get maintenanceActionSnooze => 'Odložiť na 30 dní';

  @override
  String mapMarkerLimitNotice(int shown, int total) {
    return 'Showing $shown of $total — zoom in for the rest';
  }

  @override
  String get consumptionMonthlyInsightsTitle => 'Tento mesiac vs minulý mesiac';

  @override
  String get consumptionMonthlyTripsLabel => 'Jazdy';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Čas jazdy';

  @override
  String get consumptionMonthlyDistanceLabel => 'Vzdialenosť';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Priem. spotreba';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Pre porovnanie sú potrebné aspoň 3 jazdy za mesiac';

  @override
  String get consumptionMonthlyClimbLabel => 'Vystúpané';

  @override
  String get obd2CapabilitySectionTitle => 'Možnosti adaptéra';

  @override
  String get obd2CapabilityStandardOnly => 'Štandardné';

  @override
  String get obd2CapabilityOemPids => 'OEM PID';

  @override
  String get obd2CapabilityFullCan => 'Plný CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Pre presné litre v nádrži na Peugeot/Citroën aplikácia podporuje OBDLink MX+/LX/CX (čip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack => 'Diagnostická vrstva OBD2 zapnutá';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Diagnostická vrstva OBD2 vypnutá';

  @override
  String get obd2DebugOverlayClearButton => 'Vymazať';

  @override
  String get obd2DebugOverlayCloseButton => 'Zavrieť';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 záznamy';

  @override
  String get obd2DiagnosticShareLabel => 'Zdieľať diagnostický denník';

  @override
  String get obd2DebugLoggingTitle => 'Ladiace protokolovanie OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Zaznamenávajte každú reláciu OBD2 — pripojenie, handshake, výpadky dát a opätovné pripojenia — do exportovateľného XML protokolu. V predvolenom nastavení vypnuté.';

  @override
  String get obd2DebugSessionShareLabel => 'Zdieľať protokol relácie OBD2';

  @override
  String get obd2DiagnosticsTitle => 'Stav komunikácie OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops výpadkov',
      one: '1 výpadok',
      zero: 'žiadne výpadky',
    );
    return '$percent% dokončené · $duty% záťaž · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adaptér';

  @override
  String get obd2DiagnosticsConnectionSection => 'Životný cyklus pripojenia';

  @override
  String get obd2DiagnosticsPidSection => 'Výsledky na PID';

  @override
  String get obd2DiagnosticsReconnectSection =>
      'Telemetria opätovného pripájania';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts pokusov o opätovné pripojenie · $successes úspešných · $transitions prechodov · $disconnects klasifikovaných výpadkov';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'V tejto relácii bol aktivovaný núdzový režim iba s GPS.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Stav plánovača';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Úplnosť';

  @override
  String get obd2DiagnosticsSupportSection => 'Zistené podporované PIDy';

  @override
  String get obd2DiagnosticsFuelSection => 'Súhrn paliva';

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
    return '$attempts pokusov · $successes OK · $drops výpadkov · čas pripojenia p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Opätovné pripojenia: $silent tiché · $visible viditeľné';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips preskočení pri pretlaku · $demotions degradácií';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Vrstva Dynamics hladuje — RPM / rýchlosť klesla pod prahovú hodnotu regulátora.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Celkovo $percent% · aktívna záťaž $duty%';
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
    return '$supported podporovaných · $unsupported nepodporovaných · $unknown neznámych';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Podozrivých $suspicious z $total vzoriek';
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
    return '$pid: $polled dopytovaných · $ok OK · $noData ND · $timeout TO · $error chýb · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Záznam inicializácie dongle';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokol $protocol · $start · firmware $firmware · $tier · $pids PIDov';
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
      'Zatiaľ nie je zaznamenaná žiadna OBD2 relácia — pripojte adaptér a zaznamenajte výlet so zapnutým vývojárskym režimom.';

  @override
  String get obd2DiagnosticsExplain =>
      'Zachytené počas záznamu na ladenie komunikácie dongle↔aplikácia — zbiera sa iba vo vývojárskom režime.';

  @override
  String get obd2HealthScreenTitle => 'Stav komunikácie OBD2';

  @override
  String get obd2HealthNavLabel => 'Stav komunikácie OBD2';

  @override
  String get obd2HealthLiveSection => 'Živá relácia';

  @override
  String get obd2HealthHistorySection => 'Nedávne relácie';

  @override
  String get obd2HealthDownloadJson => 'Stiahnuť ako JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Stiahnuť iba prepis inicializácie';

  @override
  String get obd2HealthDownloadError =>
      'Diagnostický súbor sa nepodarilo uložiť';

  @override
  String get obd2TestAdapterLabel => 'Adaptér na otestovanie';

  @override
  String get obd2TestAdapterScanOption => 'Vyhľadať adaptér';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Pripojenie k $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Spustiť test adaptéra';

  @override
  String get obd2TestRunButton => 'Spustiť test adaptéra';

  @override
  String get obd2TestRunPassed => 'Test adaptéra prebehol úspešne';

  @override
  String get obd2TestRunFailed => 'Test adaptéra zlyhal';

  @override
  String get obd2TestRunEngineOff =>
      'Adaptér OK — motor vypnutý; naštartujte motor na čítanie živých údajov';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed z $total krokov OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Pred spustením testu adaptéra zastavte aktívny záznam.';

  @override
  String get obd2TestStepScan => 'Hľadať adaptér';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth telefónu';

  @override
  String get obd2TestStepConnect => 'Pripojiť a inicializovať';

  @override
  String get obd2TestStepInfo => 'Informácie o adaptéri';

  @override
  String get obd2TestStepSupportedPids => 'Podporované PIDy';

  @override
  String get obd2TestStepProtocol => 'Protokol vozidla';

  @override
  String get obd2TestStepSampleReads => 'Ukážkové čítania';

  @override
  String get obd2TestStepSoak => 'Dlhodobé dopytovanie';

  @override
  String get obd2TestStepReconnect => 'Test opätovného pripojenia';

  @override
  String get obd2TestStepDisconnect => 'Odpojiť';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Vypršal čas';

  @override
  String get obd2TestStatusGarbage => 'Nečitateľná odpoveď';

  @override
  String get obd2TestStatusNoResponse => 'Žiadna odpoveď';

  @override
  String get obd2TestStatusFail => 'Zlyhalo';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'neznámy — predvolene BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Posledné pokusy o pripojenie';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Zatiaľ nie sú zaznamenané žiadne pokusy o pripojenie.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Stiahnuť záznam pripojenia';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Stiahnuť všetky záznamy pripojenia';

  @override
  String get obd2HealthConnectOrigin => 'Pôvod';

  @override
  String get obd2HealthConnectTransport => 'Prenos';

  @override
  String get obd2HealthConnectOutcome => 'Výsledok';

  @override
  String get obd2HealthConnectScanList => 'Nájdené zariadenia';

  @override
  String get obd2HealthConnectSteps => 'Kroky';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Neznámy adaptér';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Relácia zaznamenaná · $samples vzoriek motora · $percent% pokrytie';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'Čo táto jazda zaznamenala';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples z $total vzoriek obsahovalo údaje motora ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adaptér: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Dohodnutie protokolu: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Relácia ukončená: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Dĺžka relácie: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Údaje o spotrebe pochádzajú z adaptéra, nie z odhadov podľa GPS.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Podrobnosti komunikácie podľa PID neboli pri tejto jazde zachytené. Ak ich chcete zbierať, pred nahrávaním zapnite vývojársky režim.';

  @override
  String obd2DiagnosticsImplausibleFramesLine(int voltage, int odometer) {
    return 'Implausible frames: $voltage battery voltage · $odometer odometer';
  }

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nepodarilo sa dosiahnuť \'$adapterName\' — vyberte iný adaptér';
  }

  @override
  String get obd2PickerOtherDevices => 'Ďalšie zariadenia Bluetooth';

  @override
  String get obd2PickerTapToTry => 'Nerozpoznané — ťuknutím vyskúšať';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone funguje iba s adaptérmi Bluetooth LE. Adaptér podporujúci iba Classic (napr. vLinker BM, Konnwei KW902) treba použiť na Androide.';

  @override
  String get obd2PairingConfirmHint =>
      'Potvrďte žiadosť o párovanie v telefóne';

  @override
  String get obd2ScanEmptyTitle => 'Adaptér sa nenašiel';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth je zapnutý a povolenia udelené. Uistite sa, že je adaptér zapojený do zásuvky OBD2 a zapaľovanie je zapnuté, a vyhľadajte znova.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Toto zariadenie nemá hardvér Bluetooth Low Energy, takže sa nemôže pripojiť k adaptéru OBD2.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth je vypnutý. Zapnite ho, aby bolo možné vyhľadať adaptér.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo potrebuje povolenie Bluetooth, aby našlo váš adaptér.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Povolenie Bluetooth bolo natrvalo zamietnuté. Udeľte ho v nastaveniach systému, aby bolo možné vyhľadať adaptér.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Služby určovania polohy sú na tomto zariadení vypnuté. Android ich na vyhľadávanie adaptérov Bluetooth vyžaduje — žiadna poloha sa nezaznamenáva ani nezdieľa.';

  @override
  String get obd2ScanOpenSettings => 'Otvoriť nastavenia';

  @override
  String get obd2WaitingForEngineBanner =>
      'Čaká sa na motor — záznam pomocou GPS';

  @override
  String get obd2AdapterNotRespondingBanner =>
      'Adapter not responding — still recording with GPS';

  @override
  String get obd2StartEngineToReconnect =>
      'Naštartujte motor na opätovné pripojenie';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motor je vypnutý — naštartujte ho na opätovné pripojenie';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motor je vypnutý $minutes min — ukončiť záznam?';
  }

  @override
  String get obd2ParkedPromptStop => 'Ukončiť';

  @override
  String get obd2ParkedPromptKeep => 'Pokračovať';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motor bol vypnutý prvých $head a posledných $tail tejto jazdy — pokrytie sa meria pri bežiacom motore.';
  }

  @override
  String get obd2ReconnectInProgress => 'Opätovné pripájanie k adaptéru OBD2…';

  @override
  String get obd2StatusEngineOff => 'OBD2 pozastavené — motor vypnutý';

  @override
  String get obd2StatusEngineOffBody =>
      'Adaptér bol dostupný, ale zbernica vozidla mlčala, takže automatické opätovné pripájanie je pozastavené. Obnoví sa, keď pôjdete alebo znova otvoríte aplikáciu — alebo sa pripojte znova hneď.';

  @override
  String get obd2StatusReconnectNow => 'Pripojiť znova hneď';

  @override
  String get autoRecordNotificationTitle => 'Automatický záznam jázd';

  @override
  String get autoRecordNotificationText => 'Čakanie na váš adaptér OBD2';

  @override
  String get obd2ResetConnection => 'Resetovať pripojenie';

  @override
  String get obd2ResetConnectionDone =>
      'Adaptér resetovaný — spojenie obnovené';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adaptér resetovaný — opätovné pripájanie na pozadí';

  @override
  String get obd2ResetConnectionAuto =>
      'Reconnecting the adapter automatically…';

  @override
  String get ocrTesterTitle => 'Tester OCR';

  @override
  String get ocrTesterNavLabel => 'Tester OCR';

  @override
  String get ocrTesterExplain =>
      'Spustí kanál OCR pre pumpu/paragon na vybranej fotografii a skontroluje každý krok — dostupné iba vo vývojárskom režime.';

  @override
  String get ocrTesterCapture => 'Zachytiť';

  @override
  String get ocrTesterPickImage => 'Vybrať obrázok';

  @override
  String get ocrTesterRun => 'Spustiť';

  @override
  String get ocrTesterCountry => 'Krajina';

  @override
  String get ocrTesterCountryNone => 'Predvolené (žiadny profil)';

  @override
  String get ocrTesterNoImage =>
      'Vyberte alebo zachyťte obrázok, potom spustite.';

  @override
  String get ocrTesterRunning => 'Spúšťam OCR…';

  @override
  String get ocrTesterOverlaySection => 'Prekrytie blokov';

  @override
  String get ocrTesterStepsSection => 'Kroky kanála';

  @override
  String get ocrTesterLegendLabel => 'Popis';

  @override
  String get ocrTesterLegendNumeric => 'Číselné';

  @override
  String get ocrTesterLegendNoise => 'Šum';

  @override
  String get ocrTesterLegendDerived => 'Odvodené';

  @override
  String get ocrTesterStageGlare => 'Zachytenie / oslnenie';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klasifikovať';

  @override
  String get ocrTesterStageAssemble => 'Zostaviť';

  @override
  String get ocrTesterStageAnchor => 'Kotva';

  @override
  String get ocrTesterStageFallback => 'Záložný';

  @override
  String get ocrTesterStageCrossCheck => 'Krížová kontrola';

  @override
  String get ocrTesterStageConfidence => 'Spoľahlivosť';

  @override
  String get ocrTesterStageGate => 'Brána';

  @override
  String get ocrTesterStageBrand => 'Značka';

  @override
  String get ocrTesterStageOverrides => 'Prepísania';

  @override
  String get ocrTesterStageReconcile => 'Zosúladenie';

  @override
  String get ocrTesterStageResult => 'Výsledok';

  @override
  String get ocrTesterChipRead => 'PREČÍTANÉ';

  @override
  String get ocrTesterChipDerived => 'ODVODENÉ';

  @override
  String get ocrTesterGateAccepted => 'Prijaté';

  @override
  String get ocrTesterGateRejected => 'Zamietnuté';

  @override
  String get ocrTesterFallbackBanner =>
      'Pole bolo obnovené záložným mechanizmom — overte ho.';

  @override
  String get ocrTesterStageNoData => 'Fáza sa nespustila.';

  @override
  String get ocrTesterCopyJson => 'Kopírovať ako JSON';

  @override
  String get ocrTesterExportPackage => 'Exportovať balík';

  @override
  String get ocrTesterCopied => 'Stopa OCR skopírovaná do schránky.';

  @override
  String get ocrTesterExported => 'Balík OCR uložený do priečinka Stiahnuté.';

  @override
  String get onboardingObd2StepTitle => 'Pripojiť OBD2 adaptér';

  @override
  String get onboardingObd2StepBody =>
      'Zapojte OBD2 adaptér do portu auta a zapnite zapaľovanie. Prečítame VIN a vyplníme detaily motora za vás.';

  @override
  String get onboardingObd2ConnectButton => 'Pripojiť adaptér';

  @override
  String get onboardingObd2SkipButton => 'Možno neskôr';

  @override
  String get onboardingObd2ReadingVin => 'Čítanie VIN…';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nepodarilo sa pripojiť k adaptéru. Môžete skúsiť znova alebo preskočiť.';

  @override
  String get onboardingPickUseMode =>
      'Pre pokračovanie vyberte režim používania.';

  @override
  String get onboardingObd2LaterNote =>
      'Adaptér Bluetooth OBD2 môžete kedykoľvek neskôr spárovať z obrazovky vozidla, aby ste mohli zaznamenávať jazdy a čítať údaje z motora.';

  @override
  String get onboardingTitle => 'Set up Sparkilo';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get openHoursUnknown => 'Otváracie hodiny neznáme';

  @override
  String get open24Hours => 'Otvorené 24 hodín';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Pondelok';

  @override
  String get dayTue => 'Utorok';

  @override
  String get dayWed => 'Streda';

  @override
  String get dayThu => 'Štvrtok';

  @override
  String get dayFri => 'Piatok';

  @override
  String get daySat => 'Sobota';

  @override
  String get daySun => 'Nedeľa';

  @override
  String get dayShortMon => 'Po';

  @override
  String get dayShortTue => 'Ut';

  @override
  String get dayShortWed => 'St';

  @override
  String get dayShortThu => 'Št';

  @override
  String get dayShortFri => 'Pi';

  @override
  String get dayShortSat => 'So';

  @override
  String get dayShortSun => 'Ne';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Štátne sviatky';

  @override
  String get closedLabel => 'Zatvorené';

  @override
  String get openingHoursNotAvailable => 'Otváracie hodiny nie sú k dispozícii';

  @override
  String get showAllHours => 'Zobraziť všetky hodiny';

  @override
  String get showLessHours => 'Zobraziť menej';

  @override
  String get openStateUnknown => 'Neznámy';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stanica je otvorená',
      'false': 'Stanica je zatvorená',
      'other': 'Stav otvorenia neznámy',
    });
    return '$_temp0';
  }

  @override
  String get opportunitiesSectionTitle => 'Opportunities';

  @override
  String get opportunitiesEmptyTitle => 'Nothing worth telling you about yet';

  @override
  String get opportunitiesEmptyBody =>
      'SparKilo checks your stations and your area in the background. A stop worth the detour, a price unusual for your area, or one below what you normally pay will appear here — whether or not it was worth a notification.';

  @override
  String get opportunityNotSentLabel => 'Not sent';

  @override
  String get opportunityKindBestStopNow => 'Best stop nearby';

  @override
  String get opportunityKindBestStopOnRoute => 'Best stop on your route';

  @override
  String get opportunityKindRefuelSoon => 'You will need fuel';

  @override
  String get opportunityKindExceptionalLocalPrice => 'Unusual price nearby';

  @override
  String get opportunityKindPersonalBaseline => 'Below what you usually pay';

  @override
  String get opportunityKindLocalMovement => 'Prices moving nearby';

  @override
  String get opportunityKindFavouriteStation => 'Your price alert';

  @override
  String get opportunityRefusalDailyCap =>
      'You had already had today\'s alerts';

  @override
  String get opportunityRefusalTooSoon => 'Another alert had just gone out';

  @override
  String get opportunityRefusalBelowFloor =>
      'Not enough to be worth interrupting you';

  @override
  String get opportunityRefusalAlreadyTold =>
      'You were told about this station recently';

  @override
  String get opportunityRefusalOutranked => 'A better one went out instead';

  @override
  String get opportunityRefusalConfidenceTooLow =>
      'Too weakly supported to arrive uninvited';

  @override
  String get opportunityRefusalIneligible =>
      'It stopped being true before we could send it';

  @override
  String get opportunityRefusalNotWatched => 'You are not watching for this';

  @override
  String get opportunitiesScreenTitle => 'Opportunities';

  @override
  String get opportunitiesWatchHeader => 'What to watch for';

  @override
  String get opportunitiesWatchHint =>
      'Everything the engine finds appears in Opportunities. These switches decide what may interrupt you.';

  @override
  String get usualStationTitle => 'Your usual station';

  @override
  String usualStationCandidate(Object fills, Object station) {
    return '$station — $fills fill-ups';
  }

  @override
  String get usualStationConfirm => 'Set as usual';

  @override
  String get usualStationClear => 'Not my usual';

  @override
  String get usualStationNone =>
      'Add a few fill-ups and SparKilo can suggest one';

  @override
  String opportunityBestStopNowTitle(String fuelType) {
    return 'Cheapest $fuelType nearby';
  }

  @override
  String opportunityBestStopNowBody(
    String price,
    String currency,
    String station,
    String distance,
  ) {
    return '$price $currency at $station · $distance km';
  }

  @override
  String opportunityBestStopOnRouteTitle(String fuelType) {
    return 'Cheapest $fuelType on your route';
  }

  @override
  String opportunityBestStopOnRouteBody(
    String price,
    String currency,
    String station,
    String distance,
  ) {
    return '$price $currency at $station · $distance km ahead';
  }

  @override
  String get opportunityRefuelSoonTitle => 'Time to refuel';

  @override
  String opportunityRefuelSoonBody(
    String station,
    String distance,
    String price,
    String currency,
  ) {
    return '$station · $distance km ahead · $price $currency';
  }

  @override
  String opportunityPersonalBaselineTitle(String fuelType) {
    return '$fuelType below your usual price';
  }

  @override
  String opportunityPersonalBaselineBody(
    String price,
    String currency,
    String station,
  ) {
    return '$price $currency at $station';
  }

  @override
  String get permissionRationaleCameraTitle => 'Prístup ku kamere';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Táto aplikácia chce použiť vašu kameru na čítanie dokladov, displejov stojanov a QR kódov.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Čo sa deje s obrazom z kamery:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'Obraz sa používa len na čítanie dokladu, displeja stojana alebo QR kódu — rozpoznávanie prebieha vo vašom zariadení.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'Fotografia sa po skenovaní zahodí.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Nič sa nenahráva, pokiaľ nenahlásite chybné skenovanie a nepotvrdíte to.';

  @override
  String get permissionRationaleBluetoothTitle => 'Prístup k Bluetooth';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Táto aplikácia chce použiť Bluetooth na pripojenie k vášmu OBD2 adaptéru.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Čo sa deje s Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth sa používa len na vyhľadanie vášho OBD2 adaptéra a komunikáciu s ním.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Identifikátor adaptéra zostáva vo vašom zariadení — synchronizuje sa len cez TankSync ako súčasť profilu vozidla.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'V systéme Android 11 a staršom si systém vyžiada aj polohu, pretože vyhľadávanie Bluetooth tam patrí medzi oprávnenia k polohe.';

  @override
  String get permissionRationaleNotificationsTitle => 'Oznámenia';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Táto aplikácia vám chce posielať oznámenia o cenových upozorneniach a o stave záznamu jazdy.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Čo sa deje s oznámeniami:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Oznámenia sa používajú na miestne cenové upozornenia a stav záznamu jazdy.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Vytvárajú sa vo vašom zariadení — nič zariadenie neopúšťa.';

  @override
  String get permissionRationaleRevoke =>
      'Toto môžete kedykoľvek odvolať v nastaveniach zariadenia.';

  @override
  String get permissionRationaleLegalBasis =>
      'Právny základ: čl. 6 ods. 1 písm. a) GDPR (súhlas)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'odh. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Odhadovaná hodnota (~) — na tomto výlete nie je snímač paliva, takže hodnota L/100 km je modelovaná z rýchlosti GPS a kalibrácie vášho vozidla. Je to priblíženie (zvyčajne ±10–30 %, spresňuje sa s kalibráciou), nie nameraná hodnota.';

  @override
  String get tripRecordingPipElapsedCaption => 'uplynulo';

  @override
  String get processWorkflowsDriving => 'Record and understand driving';

  @override
  String get processWorkflowsRecordDescription =>
      'Record journeys and review them in your driving history.';

  @override
  String get processWorkflowsEnabled => 'Workflow enabled';

  @override
  String get processWorkflowsNotEnabled => 'Workflow not enabled';

  @override
  String get processWorkflowsDetails => 'Why is this enabled?';

  @override
  String get processWorkflowsEnable => 'Enable workflow';

  @override
  String get processWorkflowsRequired =>
      'Required capabilities — enabled together';

  @override
  String get processWorkflowsNeeds =>
      'Before recording, choose a vehicle and configure its recording mode and required permissions. Enabling this workflow may resume automatic recording if you previously enabled it for a vehicle.';

  @override
  String get processWorkflowsImpact =>
      'Capabilities that will become active (including saved preferences)';

  @override
  String get processWorkflowsUsedBy => 'Used by these optional capabilities';

  @override
  String get processWorkflowsConfirm => 'Confirm activation';

  @override
  String get processWorkflowsActivated => 'Workflow enabled.';

  @override
  String get processWorkflowsChanged =>
      'Your settings changed during review. Open the preview again.';

  @override
  String get processWorkflowsFailed =>
      'Could not finish updating the workflow. Check its current state and try again.';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: odhady spotreby znovu ukotvené k stojanu ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Otvoriť naskenovaný odkaz?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Tento QR kód vedie na $host. Otvárajte iba odkazy, ktorým dôverujete.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Otvoriť odkaz';

  @override
  String get qrLaunchConfirmCancel => 'Zrušiť';

  @override
  String get radarPinHelpTitle => 'O pripnutí';

  @override
  String get radarPinHelpBody =>
      'Pripnutie udrží obrazovku zapnutú a skryje systémové lišty, aby bol údaj o najbližšej stanici čitateľný na paluboví. Klepnutím znova uvoľnite. Automaticky sa uvoľní pri zastavení radaru.';

  @override
  String get radarAutoPinTitle => 'Vždy pripnúť pri spustení radaru';

  @override
  String get radarAutoPinSubtitle =>
      'Radar sa automaticky pripína zakaždým namiesto manuálneho klepnutia. Spotrebúva viac batérie.';

  @override
  String get radarScopeShowScope => 'Zobrazenie radaru';

  @override
  String get radarScopeShowList => 'Zobrazenie zoznamu';

  @override
  String get alertsRadiusFrequencyLabel => 'Frekvencia kontrol';

  @override
  String get alertsRadiusFrequencyDaily => 'Raz denne';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Dvakrát denne';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Trikrát denne';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Štyrikrát denne';

  @override
  String get radiusAlertPickOnMap => 'Vybrať na mape';

  @override
  String get radiusAlertMapPickerTitle => 'Vybrať stred upozornenia';

  @override
  String get radiusAlertMapPickerConfirm => 'Potvrdiť';

  @override
  String get radiusAlertMapPickerCancel => 'Zrušiť';

  @override
  String get radiusAlertMapPickerHint =>
      'Potiahnite mapu pre nastavenie stredu upozornenia';

  @override
  String get reconcileWorkflowTitle => 'Zosuladiť palivo';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Našli sme rozdiel $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Natankovali ste $pumped L, ale zaznamenané výlety pokrývajú iba $consumed L. Zostáva nevysvetlených $gap L.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Zvyčajne to znamená, že jazda nebola zaznamenaná (adaptér bol odpojený alebo aplikácia bola zatvorená), alebo chýba alebo je nesprávne zadané tankovanie.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Kým to nevyriešite, celkové palivo a celkové výlety sa nezhodujú.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Pomôžte nám priradiť rozdiel';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Sú všetky tankovaní pre túto nádrž úplné a správne?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Sú všetky jazdy zaznamenané?';

  @override
  String get reconcileWorkflowAnswerYes => 'Áno';

  @override
  String get reconcileWorkflowAnswerNo => 'Nie';

  @override
  String get reconcileWorkflowPathAHint =>
      'Chýba alebo je nesprávne tankovanie — pridáme korekciu, aby sa vaše tankovania sčítali.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Vaše tankovania sú správne a jazda nebola zaznamenaná — pridáme virtuálny výlet pre chýbajúcu vzdialenosť.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Korekcia litrov';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Akú vzdialenosť mal nezaznamenaný výlet? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Rozhodnúť neskôr';

  @override
  String get reconcileWorkflowBack => 'Späť';

  @override
  String get reconcileWorkflowNext => 'Ďalej';

  @override
  String get reconcileWorkflowApply => 'Použiť';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtuálny výlet — klepnite na úpravu';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Upraviť virtuálny výlet';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Tento výlet bol pridaný na pokrytie paliva spotrebovaného počas jazdy bez záznamu. Upravte vzdialenosť alebo palivo, alebo ho vymažte.';

  @override
  String get reconcileVirtualTrajetDelete => 'Vymazať virtuálny výlet';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Nevyriešený rozdiel palivo/výlet $gap L — klepnite na vyriešenie';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Vyriešiť nevyriešený rozdiel paliva a výletov';

  @override
  String get recoveryStillWorksNoStations =>
      'Nothing is wrong — the search simply came back empty.';

  @override
  String get recoveryStillWorksApiKey =>
      'Saved stations and your fill-up history still work.';

  @override
  String get recoveryStillWorksLocation =>
      'You can still search by postal code or city.';

  @override
  String get recoveryStillWorksConnection =>
      'Prices you have already loaded are still shown.';

  @override
  String get recoveryStillWorksRouting =>
      'Nearby search still works — only the route is unavailable.';

  @override
  String get recoveryStillWorksFallback =>
      'Saved stations and your fill-up history still work.';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/relácia';

  @override
  String get refuelCompareAdd => 'Compare';

  @override
  String get refuelCompareRemove => 'Remove from comparison';

  @override
  String get refuelComparePickStations => 'Compare stations';

  @override
  String get refuelComparePickingActive => 'Compare stations, picking is on';

  @override
  String get refuelComparePickPrompt =>
      'Tap the compare button on any station to add it to this comparison.';

  @override
  String get refuelCompareTitle => 'Your comparison';

  @override
  String refuelCompareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String get refuelCompareClear => 'Clear';

  @override
  String refuelCompareFull(int max) {
    return 'You can compare up to $max stations';
  }

  @override
  String refuelCompareContextLine(
    String fuel,
    String quantity,
    String consumption,
  ) {
    return '$fuel · buying $quantity · $consumption';
  }

  @override
  String refuelCompareConsumptionEstimated(String consumption) {
    return '$consumption (estimated)';
  }

  @override
  String get refuelCompareConsumptionMissing =>
      'no consumption yet — add a few fill-ups to see costs';

  @override
  String get refuelCompareQuantityEdit => 'Change the quantity';

  @override
  String get refuelCompareOriginMissing =>
      'Distances are straight-line until a search sets where you are.';

  @override
  String refuelCompareRowCost(String litres, String cash, String distance) {
    return 'Buy $litres · $cash · $distance there and back';
  }

  @override
  String refuelCompareRowStopCost(String litres, String cash, String distance) {
    return 'Buy $litres · $cash · $distance off your route';
  }

  @override
  String get refuelCompareBaseline => 'Cheapest for this quantity';

  @override
  String refuelCompareCostsMore(String amount, String station) {
    return '$amount more than $station';
  }

  @override
  String get refuelCompareDistanceApproximate =>
      'straight-line distance, estimated';

  @override
  String get refuelCompareDistancePending => 'road distance on its way';

  @override
  String refuelCompareNoPrice(String fuel) {
    return 'No price for $fuel here';
  }

  @override
  String get refuelCompareOutOfRange => 'Out of reach on what is in the tank';

  @override
  String get refuelCompareExceedsCapacity =>
      'That quantity would not fit in the tank';

  @override
  String get refuelCompareNotCosted =>
      'Cannot be costed with the current inputs';

  @override
  String get refuelCompareCurrencyWithheld =>
      'Prices are in different currencies and no exchange rate is available, so no cheapest is named.';

  @override
  String get refuelPlanApply => 'Add stops to route';

  @override
  String refuelPlanApplyOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops added to your route',
      one: '1 stop added to your route',
    );
    return '$_temp0';
  }

  @override
  String get refuelPlanApplyRefusedReference =>
      'A reference price is not a place to stop at, so this plan cannot be sent to navigation.';

  @override
  String get refuelPlanApplyRefusedUnavailable =>
      'This country\'s price source is unavailable, so its stops cannot be sent to navigation.';

  @override
  String get refuelPlanApplyFailed => 'Could not open navigation';

  @override
  String get refuelPlanNeedsExchangeRate =>
      'These prices are in another currency and no exchange rate is available, so no comparable total can be shown.';

  @override
  String get refuelPlanLeastDrivingTitle => 'Least extra driving';

  @override
  String refuelPlanStopNamed(int position, String station) {
    return '$position. $station';
  }

  @override
  String refuelPlanStopDetail(String litres, String cost, String arrival) {
    return 'Buy $litres for $cost · arrive with $arrival';
  }

  @override
  String refuelPlanStopNativePrice(String price) {
    return '$price at the pump';
  }

  @override
  String refuelPlanJourneyTotals(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String refuelPlanTradeOff(String cost, String minutes, String distance) {
    return 'Against the cheapest: $cost · $minutes · $distance';
  }

  @override
  String refuelPlanNoStopSummary(String litres) {
    return 'Your tank covers this journey — about $litres used, nothing to buy.';
  }

  @override
  String get refuelPlanDetourTimeApproximate =>
      'Detour times are estimated from the route\'s average speed.';

  @override
  String get refuelPlanSearchBounded =>
      'The best of the itineraries compared — this route has more stations than the planner combines.';

  @override
  String get refuelPlanEvidenceIncomplete =>
      'Some stations were left out — hidden by you, or not listed by this country\'s source — so this is the best among the rest.';

  @override
  String refuelPlanReferencePricesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count reference prices for this area are not places you can stop at',
      one: '1 reference price for this area is not a place you can stop at',
    );
    return '$_temp0';
  }

  @override
  String routeOriginStaleCurrentLocation(String age) {
    return 'Current position ($age ago)';
  }

  @override
  String routeStopOffRoute(String distance) {
    return '$distance from the route';
  }

  @override
  String get routeStopOffRouteQualifier => 'geometric estimate';

  @override
  String get routeStopOffRouteTooltip =>
      'Straight-line distance from this route to the station. Not the distance from you, and not the extra driving a stop would cost.';

  @override
  String stationCardPriceUnit(String currency) {
    return '$currency/L';
  }

  @override
  String stationCardStatus24h(String status) {
    return '$status · 24 h';
  }

  @override
  String mapStationCountTooltip(int count) {
    return '$count stations in the current result set';
  }

  @override
  String get settingsSearchHint => 'Hľadať v nastaveniach';

  @override
  String settingsSearchNoResults(String query) {
    return 'Žiadne nastavenie nezodpovedá „$query“';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profily a región';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Krajina, jazyk, palivo, okruh hľadania, plánovanie trasy';

  @override
  String get settingsTopicProfilesKeywords =>
      'profil, krajina, jazyk, palivo, okruh, psč, trasa, domov, hodnotenie, úvodná obrazovka, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Vozidlá a OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Vaše autá, objem nádrže, párovanie adaptéra OBD2';

  @override
  String get settingsTopicVehiclesKeywords =>
      'vozidlo, auto, obd, obd2, adaptér, bluetooth, nádrž, motor, vin, kalibrácia, vehicle, car, adapter, tank, engine, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Jazda a spotreba';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Koučing, odmeny, radar čerpacích staníc, riešenie problémov';

  @override
  String get settingsTopicDrivingKeywords =>
      'kouč, eko, haptický, hlas, gamifikácia, radar, dojazd, jazda, spotreba, palivový klub, vernosť, log obd2, pripnúť, coach, eco, haptic, voice, gamification, glide, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Ceny a upozornenia';

  @override
  String get settingsTopicPricesSubtitle =>
      'Cenové upozornenia, hlasové oznámenia, história cien, hlásenia komunity';

  @override
  String get settingsTopicPricesKeywords =>
      'upozornenie, oznámenie, cena, história, predpoveď, najlepší čas, komunita, hlásenie, qr, platba, hlas, alert, notification, price, history, prediction, community, report, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Jednotky a zobrazenie';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Motív, jednotka vzdialenosti, widget na domovskej obrazovke';

  @override
  String get settingsTopicUnitsKeywords =>
      'motív, tmavý, svetlý, eko, jednotka, km, míle, widget, farba, zobrazenie, vzhľad, theme, dark, light, eco, unit, miles, colour, display, appearance';

  @override
  String get settingsTopicFeaturesTitle => 'Funkcie a režim používania';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Predvoľby režimu používania a všetky prepínače funkcií';

  @override
  String get settingsTopicFeaturesKeywords =>
      'funkcia, režim, základný, stredný, plný, vlastný, prepínač, typy staníc, čerpacie stanice, nabíjačky, nabíjanie, feature, mode, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Zdroje údajov a poloha';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'Kľúče API, poloha GPS, automatické prepínanie profilu';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, kľúč, gps, poloha, pozícia, zdroj údajov, tankerkoenig, opencharge, key, location, data source';

  @override
  String get settingsTopicSyncTitle => 'Synchronizácia a účet';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, cloud, účet, e-mail, prepojiť zariadenie, synchronizácia, zdieľať databázu, anonymný, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'súkromie, súhlas, gdpr, vymazať, odstrániť, úložisko, cache, údaje, hlásenie chýb, vin, privacy, consent, delete, erase, storage, data, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Záloha a obnovenie';

  @override
  String get settingsTopicBackupSubtitle =>
      'Exportujte alebo obnovte úplnú zálohu svojich údajov';

  @override
  String get settingsTopicBackupKeywords =>
      'záloha, export, obnoviť, import, zip, xml, prenos, backup, restore, transfer';

  @override
  String get settingsTopicAdvancedSubtitle =>
      'Token GitHub, vývojárske nástroje';

  @override
  String get settingsTopicAdvancedKeywords =>
      'vývojár, ladenie, token, pat, github, diagnostika, protokol chýb, trasovanie, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Verzia, licencie, odkazy';

  @override
  String get settingsTopicAboutKeywords =>
      'o aplikácii, verzia, licencia, prispieť, github, autorstvo, about, version, license, donate, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Zapnite sledovanie spotreby v časti Funkcie a režim používania, aby ste mohli nastaviť vozidlá, koučing a odmeny.';

  @override
  String get settingsOpenFeaturesLink => 'Otvoriť Funkcie a režim používania';

  @override
  String get settingsRadarTileSubtitle =>
      'Okruh, cenový režim, dopytovanie a pripnutie obrazovky pre aktívny profil';

  @override
  String get settingsRadarNoProfileHint =>
      'Najprv vytvorte profil – nastavenia radaru sa ukladajú pre každý profil zvlášť.';

  @override
  String get settingsRadarPinHeader => 'Pripnutie obrazovky';

  @override
  String get settingsAlertsTileSubtitle =>
      'Upozornenia na stanice a okruh, ktoré vás informujú o poklese cien';

  @override
  String get settingsPriceFeaturesHeader => 'Cenové funkcie';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Hlasové oznámenia sú vypnuté. Zapnite Hlasovú spätnú väzbu a Hlasové oznámenia v časti Funkcie a režim používania, aby ste počas jazdy počuli o lacnom palive v okolí.';

  @override
  String get settingsDistanceUnitTitle => 'Jednotka vzdialenosti';

  @override
  String get settingsDistanceUnitSubtitle => 'Podľa krajiny aktívneho profilu';

  @override
  String get settingsObd2AdapterTitle => 'Adaptér OBD2';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Adaptéry sa párujú pre každé vozidlo – otvorte vozidlo, ak chcete spárovať alebo zmeniť jeho adaptér';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Súhlasy';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Súhlasy pre Cloud Sync a synchronizáciu jázd nájdete v časti Súkromie a údaje';

  @override
  String get settingsBackupExportSubtitle =>
      'Vozidlá, tankovania, jazdy a záznamy nabíjania ako súbor ZIP';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Zlúčiť alebo nahradiť údaje zo skoršej zálohy ZIP';

  @override
  String get settingsStationTypesLink =>
      'Typy staníc sa nastavujú v časti Funkcie a režim používania';

  @override
  String get routeSearchCriterionLabel => 'Výber stanice pre úsek trasy';

  @override
  String get routeSearchCriterionCheapest => 'Najlacnejšia';

  @override
  String get routeSearchCriterionNearest => 'Najbližšie k trase';

  @override
  String get routeSearchTopNLabel => 'Kandidátov na bod vzorkovania';

  @override
  String routeSearchTopNCaption(int count) {
    return 'V každom bode pozdĺž trasy sa zvažuje až $count staníc.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Palivo pre hľadanie cien (hybrid)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Predvolené pre vozidlo';

  @override
  String get scopeThisProfile => 'Tento profil';

  @override
  String get scopeAllProfiles => 'Všetky profily';

  @override
  String get scopeThisVehicle => 'Toto vozidlo';

  @override
  String get featureLabel_manualConsumption => 'Ručný záznam spotreby';

  @override
  String get featureDescription_manualConsumption =>
      'Zaznamenávajte tankovania a nabíjania ručne (adaptér OBD2 nie je potrebný).';

  @override
  String get featureLabel_loyaltyCards => 'Vernostné karty';

  @override
  String get featureDescription_loyaltyCards =>
      'Karty palivových klubov / vernostné karty so zľavou na liter v porovnaní cien.';

  @override
  String get featureLabel_startupTrace =>
      'Trasovanie inicializácie pri spustení';

  @override
  String get featureDescription_startupTrace =>
      'Zaznamenáva časované fázy spustenia aplikácie, zobrazuje ich ako vodopád a exportuje – diagnostika pre vývojárov.';

  @override
  String get locationGpsAutoHint =>
      'Poloha GPS sa získava automaticky pri hľadaní. Tu ju môžete aktualizovať aj ručne.';

  @override
  String get locationClearGpsBody =>
      'Vymazať uloženú polohu GPS? Kedykoľvek ju môžete znova aktualizovať.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Tento typ súboru zatiaľ nie je možné importovať — namiesto toho zdieľajte fotografiu paragónu.';

  @override
  String get shareReceiptFailed =>
      'Zdieľaný paragon sa nedalo prečítať — skúste ho zdieľať znova alebo pridajte tankovanie ručne.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Zdieľať paragon na import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Zdieľajte fotografiu paragónu z inej aplikácie na predvyplnenie tankovania — dátum, litre, celková suma a stanica sú čítané priamo na zariadení.';

  @override
  String get shellTabFind => 'Find';

  @override
  String get shellTabCost => 'Cost';

  @override
  String get shellTabDrive => 'Drive';

  @override
  String get speedConsumptionCardTitle => 'Spotreba podľa rýchlosti';

  @override
  String get speedBandIdleJam => 'Voľnobeh / zápcha';

  @override
  String get speedBandUrban => 'Mestská (10–50)';

  @override
  String get speedBandSuburban => 'Prímestská (50–80)';

  @override
  String get speedBandRural => 'Vidiecka (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eko-cruise (100–115)';

  @override
  String get speedBandMotorway => 'Diaľnica (115–130)';

  @override
  String get speedBandMotorwayFast => 'Rýchla diaľnica (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Zaznamenajte 30+ minút jázd s OBD2 adaptérom pre odomknutie analýzy rýchlosť/spotreba.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % jazdy';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Potrebné viac dát';

  @override
  String get splashLoadingLabel => 'Načítava sa Sparkilo';

  @override
  String get stationReferencePriceNotice =>
      'Reference price for this area, not a station location — there is nowhere to navigate to.';

  @override
  String get decisionPartialCoverageNote =>
      'This country\'s source lists only some stations, so these picks are the best among the stations shown.';

  @override
  String get errorTitleProviderUnavailable => 'No prices for this country';

  @override
  String get errorProviderUnavailable =>
      'This country\'s price source publishes no live prices at the moment. Retrying will not change that.';

  @override
  String get recoveryStillWorksProviderUnavailable =>
      'Your favorites, fill-ups and searches in other countries still work.';

  @override
  String get storageRecoveryTitle => 'Problém s úložiskom';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo nedokázalo otvoriť svoje lokálne dátové úložisko. Súbor úložiska je zrejme poškodený.';

  @override
  String get storageRecoveryGuidance =>
      'Na obnovu vymažte úložisko aplikácie v nastaveniach zariadenia alebo aplikáciu preinštalujte. Vaše obľúbené položky a história sú uložené iba v tomto zariadení, takže ich nemožno obnoviť automaticky.';

  @override
  String get storageKeyLostTitle => 'Restored data cannot be read';

  @override
  String get storageKeyLostMessage =>
      'This install was restored from a backup, which brought back Sparkilo\'s data but not the key that unlocks it. Android keeps that key in the phone\'s secure hardware, and it cannot be copied to another device or restored from a backup.';

  @override
  String get storageKeyLostGuidance =>
      'The restored history cannot be recovered. Clear the app’s storage in your device settings to start fresh — then sign in to TankSync and everything you had synced comes back.';

  @override
  String syncAdoptTitle(String email) {
    return 'Pripojiť sa k účtu $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Prihláste sa heslom k tomuto účtu, aby sa jeho údaje zdieľali na oboch zariadeniach.';

  @override
  String get syncAdoptPasswordLabel => 'Heslo k účtu';

  @override
  String get syncAdoptJoinButton => 'Pripojiť sa k účtu';

  @override
  String get syncAdoptUseDifferentAccount => 'Použiť radšej iný účet';

  @override
  String get syncDeleteDataTitle => 'Odstrániť synchronizované údaje';

  @override
  String get syncDeleteDataSubtitle =>
      'Odstráňte svoje jazdy, vozidlá alebo tankovania zo synchronizačnej databázy';

  @override
  String get syncDeleteDataPickTitle =>
      'Ktoré synchronizované údaje odstrániť?';

  @override
  String get syncDeleteDataCategoryTrips => 'Jazdy';

  @override
  String get syncDeleteDataCategoryVehicles => 'Vozidlá';

  @override
  String get syncDeleteDataCategoryFillUps => 'Tankovania';

  @override
  String get syncDeleteDataCategoryEverything => 'Všetko';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Odstrániť $category zo synchronizačnej databázy?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Odstráni vybrané údaje z vašej synchronizačnej databázy a tie sa už z ostatných zariadení znova nesynchronizujú. Údaje uložené lokálne v tomto zariadení zostanú zachované.';

  @override
  String get syncDeleteDataConfirmAction => 'Odstrániť zo servera';

  @override
  String get syncDeleteDataDone => 'Synchronizované údaje odstránené';

  @override
  String get syncDeleteDataDonePending =>
      'Deleted. Your other devices will drop it the next time this device syncs.';

  @override
  String get syncDeleteDataDoneSchemaOutdated =>
      'Deleted on the server — but your sync database is outdated, so another device could re-upload it. Re-run the setup SQL.';

  @override
  String get syncDeleteDataFailed =>
      'Odstraňovanie synchronizovaných údajov zlyhalo — skúste to znova';

  @override
  String get syncRelinkTitle => 'Cloudovú synchronizáciu treba znova prepojiť';

  @override
  String get syncRelinkBody =>
      'Uložená synchronizačná identita tohto zariadenia je odhlásená. Prihláste sa e-mailom na opätovné prepojenie synchronizovaných údajov alebo začnite odznova s novou identitou.';

  @override
  String get syncRelinkSignInAction => 'Prihlásiť sa a znova prepojiť';

  @override
  String get syncRelinkStartFreshAction => 'Začať odznova';

  @override
  String get syncRelinkStartFreshTitle => 'Začať odznova?';

  @override
  String get syncRelinkStartFreshBody =>
      'Pre toto zariadenie sa vytvorí nová anonymná identita. Údaje synchronizované pod starou identitou zostanú na serveri, ale odtiaľto už nebudú dostupné, pokiaľ sa neprihlásite jej e-mailovým účtom.';

  @override
  String get syncRelinkStartFreshConfirm => 'Začať odznova';

  @override
  String get tankLevelTitle => 'Hladina nádrže';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km dojazdu';
  }

  @override
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km pri spotrebe z poslednej nádrže';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Dlhodobý priemer: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Posledné tankovanie: $date · $count jazda(y) odvtedy';
  }

  @override
  String get tankLevelEmptyNoFillUp =>
      'Zaznamenajte tankovanie pre zobrazenie hladiny nádrže';

  @override
  String get tankLevelDetailSheetTitle => 'Jazdy od posledného tankovania';

  @override
  String get addFillUpIsFullTankLabel => 'Plná nádrž';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Nádrž naplnená po okraj — odznačte, ak išlo o čiastočné plnenie';

  @override
  String tankLevelSourceFillUp(String date) {
    return 'Ukotvené k poslednému tankovaniu: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'Snímač nádrže OBD2 · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Zmes v nádrži: $mix';
  }

  @override
  String get tankReportTitle => 'Správa o nádrži';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Od predchádzajúcej plnej nádrže: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return 'O $delta L/100 km viac než predchádzajúca nádrž';
  }

  @override
  String tankReportTrendDown(String delta) {
    return 'O $delta L/100 km menej než predchádzajúca nádrž';
  }

  @override
  String get tankReportTrendFlat => 'Na úrovni predchádzajúcej nádrže';

  @override
  String get tankReportNoPrevious =>
      'Vývoj sa zobrazí po vašej ďalšej plnej nádrži.';

  @override
  String get tankReportExplainHeader => 'Čo záznamy naznačujú';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Podiel vysokých otáčok $cur % (predtým $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Prudké manévre $cur/100 km (predtým $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Studené štarty $cur (predtým $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Podiel voľnobehu $cur % (predtým $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Záznamy sú náhodné a pokrývajú len časť tejto nádrže — tieto náznaky sú orientačné, nie celý obraz.';

  @override
  String get themeCardTitle => 'Téma';

  @override
  String get themeCardSubtitleSystem => 'Systém';

  @override
  String get themeCardSubtitleLight => 'Svetlá';

  @override
  String get themeCardSubtitleDark => 'Tmavá';

  @override
  String get themeSettingsScreenTitle => 'Téma';

  @override
  String get themeSettingsSystemLabel => 'Podľa systému';

  @override
  String get themeSettingsLightLabel => 'Svetlá';

  @override
  String get themeSettingsDarkLabel => 'Tmavá';

  @override
  String get themeSettingsSystemDescription =>
      'Zodpovedá aktuálnemu vzhľadu zariadenia.';

  @override
  String get themeSettingsLightDescription =>
      'Svetlé pozadia — najlepšie pre denné použitie.';

  @override
  String get themeSettingsDarkDescription =>
      'Tmavé pozadia — menej námahy pre oči v noci a šetrí batériu na OLED displejoch.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Charakteristický zelený vzhľad aplikácie — jasný a ľahko čitateľný, s jemne zelene zafarbenými pozadiami.';

  @override
  String get throttleRpmHistogramTitle => 'Ako ste využívali motor';

  @override
  String get throttleRpmHistogramThrottleSection => 'Poloha plynu';

  @override
  String get throttleRpmHistogramRpmSection => 'Otáčky motora RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Voľný beh (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Ľahký (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Pevný (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Plný plyn (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Voľnobeh (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Plavba (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Živšia jazda (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Tvrdá jazda (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Žiadne vzorky plynu ani RPM v tejto jazde.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Jazdy';

  @override
  String get trajetsStartRecordingButton => 'Spustiť záznam';

  @override
  String get trajetsResumeRecordingButton => 'Obnoviť záznam';

  @override
  String get tripStartStepAdapter => 'OBD2 adapter';

  @override
  String get tripStartStepVehicle => 'Vehicle data';

  @override
  String get tripStartStepRecording => 'Recording';

  @override
  String tripStartSlowHint(String action) {
    return 'Reaching the adapter usually takes a few seconds. If it stays here, pick \"$action\" from the menu above.';
  }

  @override
  String get tripStartProgressConnectingAdapter =>
      'Pripájanie k OBD2 adaptéru…';

  @override
  String get tripStartProgressReadingVehicleData => 'Čítanie údajov o vozidle…';

  @override
  String get tripStartProgressStartingRecording => 'Spúšťanie záznamu…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Dokončujem súhrn…';

  @override
  String get tripSaveProgressSavingToHistory => 'Ukladám do histórie…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Synchronizujem na pozadí…';

  @override
  String get trajetsEmptyStateTitle => 'Zatiaľ žiadne jazdy';

  @override
  String get trajetsEmptyStateBody =>
      'Klepnite na Spustiť záznam pre začatie zaznamenávania jázd.';

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
  String get trajetDetailSummaryTitle => 'Súhrn';

  @override
  String get trajetDetailFieldDate => 'Dátum';

  @override
  String get trajetDetailFieldVehicle => 'Vozidlo';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adaptér';

  @override
  String get trajetDetailFieldDistance => 'Vzdialenosť';

  @override
  String get trajetDetailFieldDuration => 'Trvanie';

  @override
  String get trajetDetailFieldAvgConsumption => 'Priem. spotreba';

  @override
  String get trajetDetailFieldFuelUsed => 'Spotrebované palivo';

  @override
  String get trajetDetailFieldFuelCost => 'Náklady na palivo';

  @override
  String get trajetDetailFieldAvgSpeed => 'Priem. rýchlosť';

  @override
  String get trajetDetailFieldMaxSpeed => 'Max. rýchlosť';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Rýchlosť (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Prietok paliva (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Zaťaženie motora (%)';

  @override
  String get trajetDetailChartThrottle => 'Plyn / pedál (%)';

  @override
  String get trajetDetailChartCoolant => 'Chladivo (°C)';

  @override
  String get trajetDetailChartAltitudeRelative =>
      'Nadmorská výška (m, od štartu)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Grafy';

  @override
  String get trajetsRowColdStartChip => 'Studený štart';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motor nedosiahol prevádzkovú teplotu počas tejto jazdy — spotreba paliva bola vyššia ako zvyčajne.';

  @override
  String get trajetDetailChartEmpty => 'Žiadne zaznamenané vzorky';

  @override
  String get trajetDetailChartEstimatedBadge => 'odhadované';

  @override
  String get trajetDetailShareAction => 'Zdieľať';

  @override
  String get trajetDetailShareImageOption => 'Zdieľať obrázok';

  @override
  String get trajetDetailShareGpxOption => 'Zdieľať GPS stopu (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Žiadne GPS údaje v tejto jazde';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — jazda dňa $date';
  }

  @override
  String get trajetDetailShareError =>
      'Nepodarilo sa vygenerovať obrázok pre zdieľanie';

  @override
  String get trajetDetailDownloadCsvOption => 'Stiahnuť telemetriu (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Stiahnuť telemetriu (JSON)';

  @override
  String get trajetDetailDownloadError => 'Súbor sa nedalo uložiť';

  @override
  String get trajetDetailDeleteAction => 'Odstrániť';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Odstrániť túto jazdu?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Táto jazda bude natrvalo odstránená z vašej histórie.';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Odstrániť';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adaptér je pripojený, ale nevracia dáta. Skúste iný adaptér alebo skontrolujte diagnostický protokol vozidla.';

  @override
  String get trajetsViewAllOnMap => 'Zobraziť všetko na mape';

  @override
  String get trajetsMapTitle => 'Jazdy na mape';

  @override
  String get trajetsMapShareGpx => 'Zdieľať GPX';

  @override
  String get trajetsMapEmpty => 'Žiadna z vybraných jázd nemá GPS údaje.';

  @override
  String get trajetsMapShareError => 'Súbor GPX sa nepodarilo zdieľať';

  @override
  String get trajetDetailChartBoost => 'Plniaci tlak (MAP − okolie)';

  @override
  String get trajetDetailChartIat => 'Teplota nasávaného vzduchu';

  @override
  String get trajetDetailChartTiming => 'Predstih zapaľovania';

  @override
  String get trajetObd2Degraded =>
      'Spustené s adaptérom OBD2, ale zaznamenané prevažne cez GPS — údaje motora sú neúplné';

  @override
  String get tripLengthCardTitle => 'Spotreba podľa dĺžky jazdy';

  @override
  String get tripLengthBucketShort => 'Krátka (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Stredná (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Dlhá (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Potrebné viac dát';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jázd',
      one: '1 jazda',
      zero: 'žiadne jazdy',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Trasa jazdy';

  @override
  String get tripPathCardSubtitle => 'GPS zaznamenaná trasa';

  @override
  String get tripPathLegendEfficient => 'Efektívna (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Hraničná (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Plytvaná (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar čerpacích staníc';

  @override
  String get tripRadarScanning => 'Hľadám blízke stanice';

  @override
  String get tripRadarNoStationNearby => 'Žiadna stanica v blízkosti';

  @override
  String get fuelStationRadarNearer => 'Bližšia stanica';

  @override
  String get fuelStationRadarFarther => 'Vzdialenejšia stanica';

  @override
  String get fuelStationRadarStart => 'Spustiť radar čerpacích staníc';

  @override
  String get stopRadar => 'Zastaviť radar';

  @override
  String get fuelStationRadarResultBadge => 'Výsledok radaru čerpacích staníc';

  @override
  String get radarUpdatingLocation => 'Aktualizuje sa vaša poloha…';

  @override
  String get radarSearching => 'Hľadá sa…';

  @override
  String get highwayModeChip =>
      'Diaľničný režim — zobrazuje stanice pred vami na trase';

  @override
  String get tripRecordingPinTooltip =>
      'Pripnutie udržuje obrazovku zapnutú — vyčerpáva viac batérie';

  @override
  String get tripRecordingPinSemanticOn => 'Odopnúť formulár záznamu';

  @override
  String get tripRecordingPinSemanticOff => 'Pripnúť formulár záznamu';

  @override
  String get tripRecordingPinHelpTooltip => 'Čo robí pripnutie?';

  @override
  String get tripRecordingPinHelpTitle => 'O pripnutí';

  @override
  String get tripRecordingPinHelpBody =>
      'Pripnutie udržuje obrazovku zapnutú a skrýva systémové lišty, aby formulár zostal čitateľný pri montáži na palubnej doske. Klepnutím znova uvoľnite. Automaticky sa uvoľní po zastavení jazdy.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Záznam pokračuje na pozadí. Klepnite na červený banner v hornej časti ľubovoľnej obrazovky pre návrat.';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Pripnite obrazovku pre udržanie GPS aktívneho počas jazdy — Android môže obmedziť GPS počas spánku.';

  @override
  String get tripRecordingMinimiseTooltip =>
      'Minimalizovať do plávajúcej dlaždice';

  @override
  String get tripRecordingAutoPinTitle =>
      'Pri spustení nahrávania vždy pripnúť';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Pripnúť formulár automaticky pri každej jazde namiesto klepnutia zakaždým. Spotrebuje viac batérie.';

  @override
  String get tripRecordingConnectingTitle => 'Spúšťa sa nahrávanie…';

  @override
  String get tripRecordingSavingTitle => 'Ukladám výlet…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Záznam zrušený — nebol zistený pohyb';

  @override
  String get tripRecordingGpsNotificationTitle => 'Zaznamenávam výlet';

  @override
  String get tripRecordingGpsNotificationText =>
      'Sledujem trasu pre štatistiky paliva a jazdy';

  @override
  String get tripSaveFailedKept =>
      'Couldn\'t save this trip — it\'s kept and will be retried';

  @override
  String get tripSaveRetryAction => 'Retry';

  @override
  String get tripShareAction => 'Zdieľať s iným účtom';

  @override
  String get tripShareSheetTitle => 'Zdieľať túto jazdu';

  @override
  String get tripShareSheetSubtitle =>
      'Poskytnite inému účtu TankSync prístup len na čítanie k tejto zaznamenanej jazde.';

  @override
  String get tripShareEmailLabel => 'E-mail príjemcu';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Zdieľať';

  @override
  String get tripShareCreateLinkButton => 'Vytvoriť odkaz na zdieľanie';

  @override
  String get tripShareLinkCreated =>
      'Odkaz na zdieľanie skopírovaný — vložte ho príjemcovi.';

  @override
  String get tripShareSuccess => 'Jazda zdieľaná.';

  @override
  String get tripShareRecipientNotFound =>
      'Tento e-mail nepoužíva žiadny účet TankSync.';

  @override
  String get tripShareNotSyncedYet =>
      'This trip hasn\'t reached your sync database yet — try again in a moment.';

  @override
  String get tripShareError => 'Jazdu sa nepodarilo zdieľať. Skúste znova.';

  @override
  String get tripShareExistingTitle => 'Zdieľané s';

  @override
  String get tripShareExistingEmpty => 'Zatiaľ s nikým nezdieľané.';

  @override
  String get tripShareDirectRecipient => 'Účet';

  @override
  String get tripShareLinkRecipient => 'Odkaz na zdieľanie (nevyzdvihnutý)';

  @override
  String get tripShareRevokeTooltip => 'Zrušiť';

  @override
  String get tripShareRevoked => 'Zdieľanie zrušené.';

  @override
  String get trajetsSharedSectionTitle => 'Zdieľané so mnou';

  @override
  String get trajetsSharedBadge => 'Zdieľané';

  @override
  String get tripVerdictPromptTitle => 'Aká bola táto jazda?';

  @override
  String get tripVerdictSmooth => 'Plynulá';

  @override
  String get tripVerdictModerate => 'Priemerná';

  @override
  String get tripVerdictAggressive => 'Agresívna';

  @override
  String get tripVerdictDismiss => 'Teraz nie';

  @override
  String get tripVerdictThanks =>
      'Ďakujeme — pomáha to kalibrovať analýzu vašej jazdy.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Tankovanie odstránené';

  @override
  String get trajetDeletedUndoSnackbar => 'Záznam odstránený';

  @override
  String get searchFailedSnackbar => 'Vyhľadávanie zlyhalo — skúste to znova';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staníc',
      one: '1 stanica',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Aktualizované $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Tiež: $names';
  }

  @override
  String get favoriteAdd => 'Pridať do obľúbených';

  @override
  String get favoriteRemove => 'Odstrániť z obľúbených';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Základná cena: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Stanica bez značky';

  @override
  String get unsupportedRegionTitle =>
      'Vo vašom regióne zatiaľ nie je k dispozícii';

  @override
  String get unsupportedRegionBody =>
      'Pre vašu krajinu zatiaľ nemáme ceny palív, takže výsledky môžu byť prázdne alebo z inej krajiny. V nastaveniach vyhľadávania si aj tak môžete vybrať podporovanú krajinu.';

  @override
  String get unsupportedRegionDismiss => 'Rozumiem';

  @override
  String get configureCountryTitle => 'Nastavte svoju krajinu';

  @override
  String get configureCountryBody =>
      'Vaša krajina je podporovaná, ale ešte nie je nastavená — ceny tak môžu byť z inej krajiny. Vyberte svoju krajinu v nastaveniach vyhľadávania, aby sa zobrazili miestne ceny.';

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
  String get allPricesNoPriceMask => '—';

  @override
  String get allPricesBestMarker => 'best';

  @override
  String allPricesDelta(String amount) {
    return '+$amount';
  }

  @override
  String allPricesMoreFuels(int count) {
    return '+$count';
  }

  @override
  String allPricesMoreFuelsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more fuels',
      one: 'Show 1 more fuel',
    );
    return '$_temp0';
  }

  @override
  String get allPricesFewerFuelsTooltip => 'Hide the extra fuels';

  @override
  String allPricesCellPriceSemantics(String fuel, String price) {
    return '$fuel $price';
  }

  @override
  String allPricesCellCostSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '$fuel $price, $cost per 100 km at $consumption';
  }

  @override
  String allPricesCellNoPriceSemantics(String fuel) {
    return '$fuel, no price';
  }

  @override
  String allPricesCellUnavailableSemantics(String fuel) {
    return '$fuel, out of stock';
  }

  @override
  String allPricesCellUnusableSemantics(String fuel) {
    return '$fuel, not usable by your vehicle';
  }

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
  String get fillInventorySkipMixedFuel =>
      'the tank held a mix of grades, so it cannot calibrate one';

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
  String get criteriaModeNearby => 'Nearby';

  @override
  String get criteriaModeRoute => 'Route';

  @override
  String get criteriaReset => 'Reset';

  @override
  String get criteriaResetDone => 'Criteria reset to your defaults';

  @override
  String get criteriaSubmitDisabledRoute => 'Enter a start and a destination';

  @override
  String get criteriaSubmitDisabledSearching => 'Search in progress…';

  @override
  String criteriaShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get criteriaShowLess => 'Show less';

  @override
  String get criteriaBrands => 'Brands';

  @override
  String get criteriaRouteOptions => 'Route options';

  @override
  String criteriaRouteOptionsSummary(
    int segmentKm,
    int detourKm,
    String saving,
  ) {
    return 'Every $segmentKm km · $detourKm km detour · $saving';
  }

  @override
  String get criteriaSwapEndpoints => 'Swap start and destination';

  @override
  String get criteriaRadiusCustom => 'Custom';

  @override
  String get criteriaIntentHeader => 'What are you looking for?';

  @override
  String get criteriaIntentCheapestNearby => 'Cheapest nearby';

  @override
  String get criteriaIntentBestStop => 'Best stop';

  @override
  String get criteriaIntentOnMyRoute => 'On my route';

  @override
  String get criteriaIntentFastest => 'Fastest';

  @override
  String get criteriaIntentFavourite => 'A favourite';

  @override
  String get criteriaIntentCustom => 'Custom';

  @override
  String get criteriaIntentNeedsConsumption =>
      'Add a fill-up first so we know your consumption';

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
  String get helpBubblePreviousTip => 'Previous tip';

  @override
  String get helpBubbleNextTip => 'Next tip';

  @override
  String helpBubbleTipPosition(int index, int total) {
    return '$index/$total';
  }

  @override
  String helpBubbleTipPositionSemantic(int index, int total) {
    return 'Tip $index of $total';
  }

  @override
  String get helpSearchTipSummaryBar =>
      'Tap the grey bar above the results to change your fuel, your radius and every other search criterion.';

  @override
  String get helpSearchTipFillEmphasis =>
      'In the comparison table, a filled cell marks the cheapest price for that fuel among the stations you are looking at.';

  @override
  String get helpSearchTipSecondFigure =>
      'The smaller second figure in a cell is what 100 km on that fuel costs in your vehicle.';

  @override
  String get helpSearchTipPriceArrows =>
      'The arrow beside a price ranks it inside this list — cheapest, middle or dearest third of these results. It is not a price trend over time.';

  @override
  String get helpSearchTipViewToggle =>
      'The view button switches between the compact cards and the table that compares every fuel at once.';

  @override
  String searchSummaryFuelTooltip(String fuel) {
    return 'Fuel: $fuel';
  }

  @override
  String searchSummaryRadiusValue(String km) {
    return '$km km';
  }

  @override
  String get searchSummaryAgeJustNow => 'now';

  @override
  String searchSummaryAgeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String searchSummaryAgeHours(int hours) {
    return '$hours h';
  }

  @override
  String searchSummaryAgeDays(int days) {
    return '$days d';
  }

  @override
  String get homeNextStopTitle => 'Your next fuel stop';

  @override
  String get homeVehicleTitle => 'Your car';

  @override
  String get homeVehicleCostPerKm => 'per km';

  @override
  String get homeVehicleConsumption => 'L/100 km';

  @override
  String get homeVehicleFromFillUps => 'Measured from your fill-ups';

  @override
  String get homeSavingsTitle => 'You\'ve saved';

  @override
  String get logoCreditsTitle => 'Logo credits';

  @override
  String logoCreditsAboutSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brand logos from Wikimedia Commons',
      one: '1 brand logo from Wikimedia Commons',
    );
    return '$_temp0';
  }

  @override
  String get logoCreditsIntro =>
      'These station and charging-network logos are bundled with the app. Every file was taken from Wikimedia Commons and is public domain or published under a Creative Commons licence — nothing is downloaded while you browse.';

  @override
  String get logoCreditsMonogramNote =>
      'Brands whose logo is not available under a free licence keep the lettered mark in the app\'s own colours.';

  @override
  String get logoCreditsTrademarkNotice =>
      'All trademarks are the property of their respective owners and are shown only to identify the station or the charging network.';

  @override
  String logoCreditsEntryDetails(String licence, String author) {
    return '$licence · $author';
  }

  @override
  String get logoCreditsOpenFilePage =>
      'Open the file page on Wikimedia Commons';

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
  String searchSummaryAlongRoute(String km) {
    return 'Along the route · every $km km';
  }

  @override
  String get searchSummaryPricesJustNow => 'Prices from just now';

  @override
  String searchSummaryPricesMinutes(int minutes) {
    return 'Prices from $minutes min ago';
  }

  @override
  String searchSummaryPricesHours(int hours) {
    return 'Prices from $hours h ago';
  }

  @override
  String searchSummaryPricesDays(int days) {
    return 'Prices from $days d ago';
  }

  @override
  String get searchResultsFilterTooltip => 'Filters';

  @override
  String searchResultsFilterActiveSemantic(int count) {
    return 'Filters, $count active';
  }

  @override
  String get searchResultsMoreActionsTooltip => 'More actions';

  @override
  String get searchPriceArrowCheapTooltip =>
      'Among the lowest prices in this list';

  @override
  String get searchPriceArrowAverageTooltip => 'A mid-range price in this list';

  @override
  String get searchPriceArrowExpensiveTooltip =>
      'Among the highest prices in this list';

  @override
  String get searchRefreshTooltip => 'Update position and refresh prices';

  @override
  String get sortMenuByName => 'Sort by name (A–Z)';

  @override
  String get sortMenuOpen24h => '24-hour stations first';

  @override
  String get sortMenuPriceDistance => 'Sort by price per kilometre';

  @override
  String sortMenuActiveSemantic(String option) {
    return '$option, current sort';
  }

  @override
  String priceHistoryFirstSeen(String date) {
    return 'First seen on $date — the history builds up with every visit';
  }

  @override
  String priceHistoryCurrentPriceLine(String price) {
    return 'Current price: $price';
  }

  @override
  String priceHistoryDeltaSince(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String priceHistoryUnchangedSince(String date) {
    return 'Unchanged since $date';
  }

  @override
  String get priceStatsMin => 'Min';

  @override
  String get priceStatsMax => 'Max';

  @override
  String get priceStatsAvg => 'Avg';

  @override
  String get amenitiesAndServices => 'Amenities & services';

  @override
  String amenitiesServicesShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get amenitiesServicesShowLess => 'Show less';

  @override
  String pricesNotSoldHere(String fuels) {
    return 'Not sold here: $fuels';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return 'Recorded trips cover $pct % of this tank';
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
  String get vehCompareTitle => 'Compare vehicles';

  @override
  String get vehCompareOpenTooltip => 'Compare vehicles';

  @override
  String get vehCompareSelectHint => 'Pick at least two vehicles to compare.';

  @override
  String get vehCompareNotEnoughVehicles =>
      'Add a second vehicle profile before comparing histories.';

  @override
  String get vehCompareHonestyNote =>
      'These figures come from your own records, at the prices you actually paid. They do not measure how efficient a vehicle is in itself, they do not predict what a future trip will cost, and they are not savings against a price this app never saw.';

  @override
  String get vehComparePeriodLabel => 'Period';

  @override
  String get vehComparePeriodAll => 'All history';

  @override
  String get vehComparePeriodYear => 'Last 12 months';

  @override
  String get vehComparePeriodQuarter => 'Last 90 days';

  @override
  String get vehCompareBoundaryPolicyLabel => 'Tanks crossing the period edge';

  @override
  String get vehCompareBoundaryClosing => 'Count the whole tank it ended in';

  @override
  String get vehCompareBoundaryContained => 'Only tanks entirely inside';

  @override
  String get vehCompareBoundaryNote =>
      'A tank is never split at a date. Its litres were measured over the whole tank, so the whole tank is counted or none of it is.';

  @override
  String vehCompareReferenceLabel(String vehicle) {
    return 'Differences shown against $vehicle';
  }

  @override
  String get vehCompareSetReference => 'Use as reference';

  @override
  String get vehCompareEvidenceTitle => 'Evidence';

  @override
  String vehCompareWindowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count closed tanks',
      one: '1 closed tank',
      zero: 'No closed tank',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareMatchedDistance => 'Matched distance';

  @override
  String get vehCompareRecordedDistance => 'Recorded distance';

  @override
  String vehCompareTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorded drives',
      one: '1 recorded drive',
      zero: 'No recorded drive',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareConsumptionTitle => 'Observed consumption';

  @override
  String get vehCompareCostTitle => 'Cost';

  @override
  String get vehCompareCostPerKmLabel => 'Per km, tank purchases';

  @override
  String get vehCompareConsumedFuelLabel => 'Per km, fuel burned (modelled)';

  @override
  String get vehCompareRecordedSpendLabel => 'Paid at the pump';

  @override
  String get vehComparePricePerUnitLabel => 'Average price paid';

  @override
  String get vehCompareRefuellingTitle => 'Refuelling';

  @override
  String get vehCompareFillCountLabel => 'Pump visits';

  @override
  String get vehCompareTotalQuantityLabel => 'Total pumped';

  @override
  String get vehCompareTypicalQuantityLabel => 'Typical fill';

  @override
  String get vehCompareFullPartialLabel => 'Full / partial';

  @override
  String vehCompareFullPartialValue(int full, int partial) {
    return '$full full, $partial partial';
  }

  @override
  String get vehCompareBetweenFillsLabel => 'Between refuels';

  @override
  String vehCompareBetweenFillsDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareCorrectionsLabel => 'Corrections';

  @override
  String get vehCompareStationsTitle => 'Stations';

  @override
  String vehCompareStationUnnamed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills with no station recorded',
      one: '1 fill with no station recorded',
    );
    return '$_temp0';
  }

  @override
  String vehCompareStationVisits(String station, int count) {
    return '$station: $count';
  }

  @override
  String get vehCompareRangeLabel => 'Estimated range';

  @override
  String vehCompareFuelShare(String fuel, String share) {
    return '$fuel: $share';
  }

  @override
  String vehCompareBoundaryIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanks opened before this period and were counted whole.',
      one: '1 tank opened before this period and was counted whole.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareBoundaryExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanks crossed the period edge and were left out.',
      one: '1 tank crossed the period edge and was left out.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareOpeningCarried(String date) {
    return 'The first counted tank was filled on $date, before this period — its fuel is carried forward, not re-counted.';
  }

  @override
  String get vehCompareMissingVehicle =>
      'This vehicle is no longer on record, so its figures cannot be recomputed. The selection is kept so you can restore it.';

  @override
  String get vehCompareRemoveFromSelection => 'Remove from the comparison';

  @override
  String vehCompareUnassignedFills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fill-ups belong to no vehicle and count for none of these columns.',
      one:
          '1 fill-up belongs to no vehicle and counts for none of these columns.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareAmbiguousFills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fill-ups could belong to more than one of these vehicles and count for none.',
      one:
          '1 fill-up could belong to more than one of these vehicles and counts for none.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareUnassignedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorded drives belong to no vehicle.',
      one: '1 recorded drive belongs to no vehicle.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareWinnerConsumption(String vehicle) {
    return 'Lowest observed consumption: $vehicle';
  }

  @override
  String vehCompareWinnerCost(String vehicle) {
    return 'Lowest observed cost per km: $vehicle';
  }

  @override
  String vehCompareNoWinner(String reason) {
    return 'No vehicle can be named here: $reason';
  }

  @override
  String get vehCompareSourcesAction => 'Show the records';

  @override
  String get vehCompareSourcesTitle => 'Records behind this figure';

  @override
  String vehCompareSourcesFills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fill-ups',
      one: '1 fill-up',
      zero: 'No fill-up',
    );
    return '$_temp0';
  }

  @override
  String vehCompareSourcesWindows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count closed tanks',
      one: '1 closed tank',
      zero: 'No closed tank',
    );
    return '$_temp0';
  }

  @override
  String vehCompareSourcesTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drives',
      one: '1 drive',
      zero: 'No drive',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareUnavailableShort => 'Not comparable';

  @override
  String get vehCompareEstimateBadge => 'Estimate';

  @override
  String vehCompareSemanticsColumn(String vehicle, int index, int total) {
    return '$vehicle, vehicle $index of $total';
  }

  @override
  String vehCompareSemanticsMetric(String label, String value, String vehicle) {
    return '$label: $value, $vehicle';
  }

  @override
  String get vehCompareReasonNoEvidence => 'Nothing on record for this figure.';

  @override
  String get vehCompareReasonTooFewSamples =>
      'Too few closed tanks to compare.';

  @override
  String get vehCompareReasonNoMatchedDistance =>
      'No matched distance to divide by.';

  @override
  String get vehCompareReasonMixedCurrencies =>
      'Amounts in more than one currency, and no conversion was chosen.';

  @override
  String get vehCompareReasonUnknownCurrency =>
      'Some amounts have no recorded currency.';

  @override
  String get vehCompareReasonExchangeRateUnavailable =>
      'No exchange rate relates these currencies.';

  @override
  String get vehCompareReasonExchangeRateStale =>
      'The exchange rate is too old to decide this.';

  @override
  String get vehCompareReasonIncompatibleUnits =>
      'These quantities are measured in different units.';

  @override
  String get vehCompareReasonUnsupportedUnit =>
      'This fuel is not sold by the litre, so there is no L/100 km figure.';

  @override
  String get vehCompareReasonAmbiguousAttribution =>
      'These records cannot be attributed to exactly one vehicle.';

  @override
  String get vehCompareReasonMissingPrices =>
      'Some fills in the counted tanks carry no price.';

  @override
  String get vehCompareReasonNoExpectedConsumption =>
      'No expected consumption is recorded, so nothing can be adjusted against it.';

  @override
  String get vehCompareReasonIncompleteConditionCoverage =>
      'Not every driving condition was evaluated.';

  @override
  String get vehCompareQualUncontrolledConditions =>
      'Hills, cold and traffic are not accounted for.';

  @override
  String get vehCompareQualPartialConditionCoverage =>
      'Only cold starts are recorded; gradient and stop-and-go are not.';

  @override
  String get vehCompareQualUnequalSampleSizes =>
      'The vehicles rest on very different amounts of evidence.';

  @override
  String get vehCompareQualEstimatedBasis => 'Modelled, not measured.';

  @override
  String get vehCompareQualStaleBasis =>
      'Measured, but too old to read as current.';

  @override
  String get vehCompareQualMixedProvenance =>
      'Measured and modelled evidence both exist; they are reported apart.';

  @override
  String get vehCompareQualConvertedCurrency =>
      'Converted at a named, dated rate — a valuation, not the amount paid.';

  @override
  String get vehCompareQualExcludedRecords =>
      'Some records were left out of this total.';

  @override
  String get vehCompareQualOpenWindowExcluded =>
      'The tank in progress is not counted.';

  @override
  String get vehCompareQualUnknownBlendShare =>
      'Part of the tank cannot be attributed to one grade.';

  @override
  String get vehCompareQualReconstructedValuation =>
      'A reconstructed valuation of the fuel burned, not money paid.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Môžem tankovať rôzne druhy paliva';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Sleduje, ktoré palivo je najlacnejšie na kilometer';

  @override
  String get vinLabel => 'VIN (voliteľné)';

  @override
  String get vinDecodeTooltip => 'Dekódovať VIN';

  @override
  String get vinConfirmAction => 'Áno, automaticky vyplniť';

  @override
  String get vinModifyAction => 'Upraviť ručne';

  @override
  String get vehicleReadVinFromCarButton => 'Prečítať VIN z auta';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Prečítať VIN zo spárovaného OBD2 adaptéra';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN nie je dostupný (Režim 09 PID 02 nepodporovaný na vozidlách pred rokom 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Čítanie VIN zlyhalo — prosím zadajte ručne';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Najprv spárujte OBD2 adaptér pre automatické čítanie VIN';

  @override
  String get pickerButtonLabel => 'Vybrať z katalógu';

  @override
  String get pickerSearchHint => 'Hľadať značku alebo model';

  @override
  String get pickerHelpText => 'Predvyplniť z 50+ podporovaných vozidiel';

  @override
  String get pickerEmptyResults => 'Žiadne zhody';

  @override
  String get pickerCancel => 'Zrušiť';

  @override
  String get pickerLoading => 'Načítava sa katalóg…';

  @override
  String get vehTripTitle => 'Compare this trip';

  @override
  String get vehTripOpenTooltip => 'Compare this trip across vehicles';

  @override
  String get vehTripNoRoute =>
      'Plan a route first — there is no journey to compare yet.';

  @override
  String get vehTripNotEnoughVehicles =>
      'Pick at least two vehicles to compare this trip.';

  @override
  String get vehTripForecastNote =>
      'These are estimates for a journey you have not driven yet, built from each vehicle\'s own consumption evidence, tank and compatible fuel. They are a forecast, not the history you recorded.';

  @override
  String get vehTripScopeNote =>
      'Fuel and refuelling only. Maintenance, depreciation and insurance are in no total on this screen.';

  @override
  String get vehTripObjectiveLabel => 'Compare on';

  @override
  String get vehTripObjectiveCost => 'Lowest total cost';

  @override
  String get vehTripObjectiveTime => 'Shortest expected time';

  @override
  String get vehTripObjectiveDistance => 'Least extra driving';

  @override
  String get vehTripFuelUsedLabel => 'Fuel this trip burns';

  @override
  String get vehTripCostToDriveLabel => 'Fuel cost to drive';

  @override
  String get vehTripCostToDriveNote =>
      'The fuel the journey burns, valued at the best price for this vehicle\'s fuel on this route. It does not change with what is already in the tank.';

  @override
  String get vehTripCashRequiredLabel => 'Cash at the pump';

  @override
  String get vehTripCashRequiredNote =>
      'What you would pay on this trip with the tank as it is now, known stop charges included. A full tank is cheaper to refuel, not cheaper to drive.';

  @override
  String get vehTripStopsLabel => 'Refuelling stops';

  @override
  String get vehTripExtraKmLabel => 'Extra kilometres';

  @override
  String get vehTripTimeLabel => 'Expected time';

  @override
  String get vehTripStartTankLabel => 'Tank at departure';

  @override
  String get vehTripEndTankLabel => 'Tank at arrival';

  @override
  String get vehTripConsumptionLabel => 'Consumption assumed';

  @override
  String get vehTripNoStops => 'No refuelling stop needed.';

  @override
  String vehTripStopLine(String station, String litres, String cost) {
    return '$station: buy $litres for $cost';
  }

  @override
  String get vehTripSourceMeasured => 'from your records';

  @override
  String get vehTripSourceManual => 'your own assumption';

  @override
  String get vehTripSourceEstimated => 'estimated';

  @override
  String get vehTripSourceUnknown => 'not known';

  @override
  String vehTripGap(String fromKm, String toKm) {
    return 'This vehicle cannot cross from $fromKm to $toKm on one tank.';
  }

  @override
  String vehTripWinnerCost(String vehicle) {
    return '$vehicle costs the least to drive';
  }

  @override
  String vehTripWinnerCash(String vehicle) {
    return '$vehicle needs the least cash at the pump';
  }

  @override
  String vehTripWinnerTime(String vehicle) {
    return '$vehicle is expected to arrive first';
  }

  @override
  String get vehTripWinnerWithheld =>
      'No single winner: not every selected vehicle could be compared on this figure.';

  @override
  String get vehTripApply => 'Use this plan';

  @override
  String vehTripApplied(String vehicle) {
    return 'Navigation started for $vehicle.';
  }

  @override
  String get vehTripApplyRefused =>
      'This plan could not be handed to navigation.';

  @override
  String get vehTripBoundedSearch =>
      'The best of the stations searched, not proof that nothing better exists.';

  @override
  String get vehTripCurrencyWithheld =>
      'Some stations on this route quote a currency this trip cannot be expressed in. Their prices stay as quoted.';

  @override
  String get vehTripIncompleteEvidence =>
      'Some stations were left out of this vehicle\'s plan, so it speaks only for the ones searched.';

  @override
  String get vehTripAssumptionLabel => 'Consumption for this trip';

  @override
  String get vehTripAssumptionClear => 'Use my records again';

  @override
  String vehTripSemanticsColumn(String vehicle, int index, int total) {
    return '$vehicle, vehicle $index of $total';
  }

  @override
  String get vehTripNoPriceForFuel =>
      'No station on this route sells this vehicle\'s fuel, so there is no fuel cost to show.';

  @override
  String get vehTripUnavailableShort => 'Not comparable';

  @override
  String get vinInfoTooltip => 'Čo je VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Čo je VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Identifikačné číslo vozidla je 17-znakový kód jedinečný pre vaše auto. Je vyrazený na karosérii a vytlačený na vašom osvedčení o evidencii vozidla.';

  @override
  String get vinInfoSectionWhyTitle => 'Prečo sa pýtame';

  @override
  String get vinInfoSectionWhyBody =>
      'Dekódovanie VIN automaticky vyplní zdvihový objem motora, počet valcov, rok výroby, primárny typ paliva a celkovú hmotnosť — ušetrí vám hľadanie technických špecifikácií. Výpočet spotreby paliva OBD2 používa tieto hodnoty pre presné čísla spotreby.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Súkromie';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Váš VIN je uložený iba lokálne v šifrovanom úložisku aplikácie — nikdy sa nenahrá na servery Sparkilo. Databáza NHTSA vPIC je dopytovaná s VIN, ale vracia iba anonymné technické špecifikácie; NHTSA nespája VIN so žiadnymi osobnými údajmi. Bez siete offline vyhľadávanie vráti iba výrobcu a krajinu.';

  @override
  String get vinInfoSectionWhereTitle => 'Kde ho nájsť';

  @override
  String get vinInfoSectionWhereBody =>
      'Pozrite cez čelné sklo do ľavého dolného rohu na strane vodiča, skontrolujte nálepku na ráme dverí vodiča pri otvorených dverách, alebo ho prečítajte z osvedčenia o evidencii vozidla (karta / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Rozumiem';

  @override
  String get vinConfirmPrivacyNote =>
      'Váš VIN sme vyhľadali v bezplatnej databáze vozidiel NHTSA — nič sa neodoslalo na servery Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Online dekódovanie VIN';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekódovať VIN cez bezplatnú verejnú službu NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Keď spárujete adaptér, VIN vášho vozidla sa prečíta lokálne pre identifikáciu auta. Povolením tohto sa 17-znakový VIN odošle do bezplatnej služby NHTSA vPIC pre vyhľadanie ďalších detailov (model, zdvihový objem, typ paliva). VIN je jediný odoslaný údaj — žiadne iné informácie neopustia vaše zariadenie.';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Zistené z VIN: $summary. Použiť?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Použiť';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometrov pred vami, $fuelType $euros euro $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Widget na domovskej obrazovke';

  @override
  String get widgetHelpIntro =>
      'Pridajte widget SparKilo na domovskú obrazovku pre zobrazenie cien paliva a nabíjania na prvý pohľad.';

  @override
  String get widgetHelpAdd =>
      'Pridajte ho z vyberača widgetov vašej spúšťacej obrazovky — podržte prázdnu oblasť domovskej obrazovky, vyberte Widgety a nájdite SparKilo.';

  @override
  String get widgetHelpTap =>
      'Klepnutím na stanicu vo widgete ju otvoríte v aplikácii. Klepnutím na ikonu obnovenia aktualizujete ceny.';

  @override
  String get widgetHelpConfigure =>
      'Na Androide podržte widget a vyberte Nakonfigurovať pre zmenu profilu, farby a obsahu.';

  @override
  String get widgetDefaultsThisProfileHint =>
      'Nižšie uvedené voľby platia pre všetky nainštalované widgety zobrazujúce tento profil, pri najbližšej aktualizácii.';

  @override
  String get widgetDefaultsColorLabel => 'Farebná schéma';

  @override
  String get widgetDefaultsVariantLabel => 'Variant obsahu';

  @override
  String get widgetColorSchemeSystem => 'Podľa systému';

  @override
  String get widgetColorSchemeLight => 'Svetlá';

  @override
  String get widgetColorSchemeDark => 'Tmavá';

  @override
  String get widgetColorSchemeBlue => 'Modrá';

  @override
  String get widgetColorSchemeGreen => 'Zelená';

  @override
  String get widgetColorSchemeOrange => 'Oranžová';

  @override
  String get widgetVariantDefault => 'Iba aktuálna cena';

  @override
  String get widgetVariantPredictive =>
      'Prediktívny: najlepší čas na tankovanie';
}
