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
  String get searchButton => 'Hľadať';

  @override
  String get fabOpenCriteria => 'Otvoriť vyhľadávanie';

  @override
  String get fabOpenResults => 'Otvoriť výsledky';

  @override
  String get fabRunSearch => 'Spustiť vyhľadávanie';

  @override
  String get fabRefineCriteria => 'Spresniť vyhľadávanie';

  @override
  String get routeSearchPartialBanner => 'Hľadajú sa ďalšie stanice…';

  @override
  String get routeSearchingChip => 'Hľadám trasu…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Každých $km km';
  }

  @override
  String get searchCriteriaTitle => 'Kritériá vyhľadávania';

  @override
  String get searchCriteriaOpen => 'Vyhľadať';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'V okruhu $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Klepnutím spustíte vyhľadávanie';

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
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktívny profil';

  @override
  String get configPreferredFuel => 'Preferovaný typ paliva';

  @override
  String get configCountry => 'Krajina';

  @override
  String get configRouteSegment => 'Úsek trasy';

  @override
  String get configApiKeysSection => 'Kľúče API';

  @override
  String get configTankerkoenigKey => 'Kľúč API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Nakonfigurovaný';

  @override
  String get configApiKeyNotSet => 'Nenastavený (demo režim)';

  @override
  String get configApiKeyCommunity => 'Predvolený (komunitný kľúč)';

  @override
  String get searchLocationPlaceholder => 'Adresa, PSČ alebo mesto';

  @override
  String get configEvKey => 'Kľúč API pre nabíjanie EV';

  @override
  String get configEvKeyCustom => 'Vlastný kľúč';

  @override
  String get configEvKeyShared => 'Predvolený (zdieľaný)';

  @override
  String get configCloudSyncSection => 'Synchronizácia s cloudom';

  @override
  String get configTankSyncConnected => 'Pripojené';

  @override
  String get configTankSyncDisabled => 'Zakázané';

  @override
  String get configAuthMode => 'Režim overenia';

  @override
  String get configAuthEmail => 'E-mail (trvalý)';

  @override
  String get configAuthAnonymous => 'Anonymný (iba zariadenie)';

  @override
  String get configDatabase => 'Databáza';

  @override
  String get configPrivacySummary => 'Súhrn ochrany súkromia';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Obľúbené, upozornenia a ignorované stanice sú synchronizované s vašou súkromnou databázou\n• Poloha GPS a kľúče API nikdy neopustia vaše zariadenie\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Všetky údaje sú uložené iba lokálne na tomto zariadení\n• Žiadne údaje sa neodosielajú na žiadny server\n• Kľúče API sú šifrované v zabezpečenom úložisku zariadenia';

  @override
  String get configAuthNoteEmail =>
      'E-mailový účet umožňuje prístup z viacerých zariadení';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymný účet — údaje viazané na toto zariadenie';

  @override
  String get configNone => 'Žiadne';

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
  String get demoModeBannerAction => 'Získať živé ceny';

  @override
  String get sortDistance => 'Vzdialenosť';

  @override
  String get sortOpen24h => '24 h';

  @override
  String get sortRating => 'Hodnotenie';

  @override
  String get sortPriceDistance => 'Cena/km';

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
  String get routeModeBannerLabel =>
      'Režim trasy — vzdialenosti pozdĺž koridoru';

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
  String get ignoredStationsLabel => 'Ignorované';

  @override
  String get ratingsLabel => 'Hodnotenia';

  @override
  String get favoritesDataCache => 'Dáta obľúbených';

  @override
  String get citySearchCache => 'Vyhľadávanie mesta';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Mazanie údajov nie je v komunitnom režime k dispozícii. Najprv sa odpojte alebo použite súkromnú databázu.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count sledovaných staníc';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count nakonfigurované';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count skrytých staníc';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count hodnotených staníc';
  }

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
  String get upgradeToEmail => 'Vytvoriť e-mailový účet';

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
  String get refreshFailed => 'Obnovenie zlyhalo. Skúste to znova.';

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
  String crossBorderNearby(String country) {
    return '$country je v blízkosti';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km k hranici';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Priem. tu: $price EUR ($count staníc)';
  }

  @override
  String get allPricesView => 'Všetky ceny';

  @override
  String get compactView => 'Kompaktné';

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
  String get gdprAcceptAll => 'Prijať všetko';

  @override
  String get gdprAcceptSelected => 'Prijať vybrané';

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
  String get topicUrlCopied => 'URL témy skopírovaná';

  @override
  String get testNotificationSent => 'Testové upozornenie odoslané!';

  @override
  String get testNotificationFailed =>
      'Odoslanie testového upozornenia zlyhalo';

  @override
  String get pushUpdateFailed =>
      'Aktualizácia nastavenia push upozornení zlyhala';

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
  String get privacyDashboardTitle => 'Ovládací panel ochrany súkromia';

  @override
  String get privacyDashboardSubtitle =>
      'Zobraziť, exportovať alebo odstrániť vaše údaje';

  @override
  String get privacyDashboardBanner =>
      'Vaše údaje vám patria. Tu môžete vidieť všetko, čo táto aplikácia ukladá, exportovať to alebo odstrániť.';

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
  String get privacyCacheEntries => 'Záznamy v cache';

  @override
  String get privacyApiKey => 'Uložený kľúč API';

  @override
  String get privacyEvApiKey => 'Uložený kľúč EV API';

  @override
  String get privacyEstimatedSize => 'Odhadovaná veľkosť úložiska';

  @override
  String get privacySyncedData => 'Synchronizácia s cloudom (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Synchronizácia s cloudom je zakázaná. Všetky údaje zostávajú iba na tomto zariadení.';

  @override
  String get privacySyncMode => 'Režim synchronizácie';

  @override
  String get privacySyncUserId => 'ID používateľa';

  @override
  String get privacySyncDescription =>
      'Keď je synchronizácia zapnutá, obľúbené, upozornenia, ignorované stanice a hodnotenia sú tiež uložené na serveri TankSync.';

  @override
  String get privacyViewServerData => 'Zobraziť serverové údaje';

  @override
  String get privacyExportButton => 'Exportovať všetky údaje ako JSON';

  @override
  String get privacyExportSuccess => 'Údaje exportované do schránky';

  @override
  String get privacyExportCsvButton => 'Exportovať všetky údaje ako CSV';

  @override
  String get privacyExportCsvSuccess => 'Údaje CSV exportované do schránky';

  @override
  String get savedToDownloadsFolder => 'Uložené do priečinka Stiahnuté';

  @override
  String get privacyDeleteButton => 'Odstrániť všetky údaje';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopírovať chybový log do schránky ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Uložiť záznam chýb ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Vymazať protokol chýb';

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
  String voiceAnnouncementThreshold(String price) {
    return 'Iba pod $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometrov pred vami, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Polomer oznámenia';

  @override
  String get voiceAnnouncementCooldown => 'Interval opakovania';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximum price';

  @override
  String get nearestStations => 'Najblizsie stanice';

  @override
  String get nearestStationsHint =>
      'Najdite najblizsie stanice podla vasej aktualnej polohy';

  @override
  String get consumptionLogTitle => 'Spotreba paliva';

  @override
  String get consumptionLogMenuTitle => 'Záznam spotreby';

  @override
  String get consumptionLogMenuSubtitle =>
      'Sledujte tankovania a vypočítajte L/100km';

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
  String get stationPreFilled => 'Stanica predvyplnená';

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
  String get fillUpVehicleNone => 'Žiadne vozidlo';

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
  String get scanPump => 'Skenovať pumpu';

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
  String get obdNoAdapter => 'Žiadny OBD2 adaptér v dosahu';

  @override
  String get obdOdometerUnavailable => 'Tachometer sa nepodarilo prečítať';

  @override
  String get obdPermissionDenied =>
      'Udeľte oprávnenie Bluetooth v systémových nastaveniach';

  @override
  String get obdAdapterUnresponsive =>
      'Adaptér neodpovedal — zapnite zapaľovanie a skúste znova';

  @override
  String get obdPickerTitle => 'Vybrať OBD2 adaptér';

  @override
  String get obdPickerScanning => 'Vyhľadávanie adaptérov…';

  @override
  String get obdPickerConnecting => 'Pripájanie…';

  @override
  String get themeSettingTitle => 'Téma';

  @override
  String get themeModeLight => 'Svetlá';

  @override
  String get themeModeDark => 'Tmavá';

  @override
  String get themeModeSystem => 'Podľa systému';

  @override
  String get tripRecordingTitle => 'Záznam jazdy';

  @override
  String get tripSummaryTitle => 'Súhrn jazdy';

  @override
  String get tripMetricDistance => 'Vzdialenosť';

  @override
  String get tripMetricSpeed => 'Rýchlosť';

  @override
  String get tripMetricFuelUsed => 'Spotrebované palivo';

  @override
  String get tripMetricAvgConsumption => 'Priem.';

  @override
  String get tripMetricElapsed => 'Uplynulý čas';

  @override
  String get tripMetricOdometer => 'Tachometer';

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
  String get navConsumption => 'Spotreba';

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
  String get achievementsTitle => 'Úspechy';

  @override
  String get achievementFirstTrip => 'Prvá jazda';

  @override
  String get achievementFirstTripDesc => 'Zaznamenajte svoju prvú OBD2 jazdu.';

  @override
  String get achievementFirstFillUp => 'Prvé tankovanie';

  @override
  String get achievementFirstFillUpDesc => 'Zaznamenajte prvé tankovanie.';

  @override
  String get achievementTenTrips => '10 jázd';

  @override
  String get achievementTenTripsDesc => 'Zaznamenajte 10 OBD2 jázd.';

  @override
  String get achievementZeroHarsh => 'Plynulý vodič';

  @override
  String get achievementZeroHarshDesc =>
      'Dokončite jazdu 10 km alebo viac bez prudkého brzdenia alebo zrýchľovania.';

  @override
  String get achievementEcoWeek => 'Eko týždeň';

  @override
  String get achievementEcoWeekDesc =>
      'Jazdite 7 po sebe idúcich dní s aspoň jednou plynulou jazdou každý deň.';

  @override
  String get achievementPriceWin => 'Výhodná cena';

  @override
  String get achievementPriceWinDesc =>
      'Zaznamenajte tankovanie, ktoré je o 5 % alebo viac nižšie ako 30-dňový priemer stanice.';

  @override
  String get syncBaselinesToggleTitle => 'Zdieľať naučené profily vozidiel';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Nahrávať základné hodnoty spotreby pre každé vozidlo, aby ich mohlo použiť druhé zariadenie.';

  @override
  String get obd2StatusConnected => 'OBD2 adaptér: pripojený';

  @override
  String get obd2StatusAttempting => 'OBD2 adaptér: pripájanie';

  @override
  String get obd2StatusUnreachable => 'OBD2 adaptér: nedostupný';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adaptér: potrebné oprávnenie Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Pripravený na záznam jazdy.';

  @override
  String get obd2StatusAttemptingBody => 'Pripájanie na pozadí…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adaptér je mimo dosahu alebo ho používa iná aplikácia.';

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
  String get tripHistoryEmptySubtitle =>
      'Pripojte OBD2 adaptér a zaznamenajte jazdu pre začatie vašej histórie jázd.';

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
  String get tripSaveAsFillUp => 'Uložiť ako tankovanie';

  @override
  String get tripSaveRecording => 'Uložiť jazdu';

  @override
  String get tripDiscard => 'Zahodiť';

  @override
  String obdOdometerRead(int km) {
    return 'Tachometer prečítaný: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nenastavené';

  @override
  String get wizardVehicleTapToEdit => 'Klepnutím upraviť';

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
  String get wizardProfileCustomDescription =>
      'Vaša vlastná kombinácia funkcií. Upravte každý prepínač nižšie.';

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
  String get vehiclePowerLabel => 'Engine power (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps PS';
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
  String get evMaxPower => 'Max. výkon';

  @override
  String get evOperator => 'Prevádzkovateľ';

  @override
  String get evLastUpdate => 'Posledná aktualizácia';

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
  String get profileNotFound => 'Žiadny aktívny profil';

  @override
  String get updatingFavorites => 'Aktualizujú sa obľúbené...';

  @override
  String get fetchingLatestPrices => 'Načítavajú sa najnovšie ceny';

  @override
  String get noDataAvailable => 'Žiadne údaje';

  @override
  String get configAndPrivacy => 'Konfigurácia a súkromie';

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
  String get sectionSetupDataSources => 'Nastavenie a dátové zdroje';

  @override
  String get sectionFeaturesUsage => 'Funkcie a používanie';

  @override
  String get sectionAccountSync => 'Účet a synchronizácia';

  @override
  String get sectionAppearanceWidgets => 'Vzhľad a widgety';

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
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Palivo';

  @override
  String get stationTypeEv => 'EV';

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
  String get alertsBackgroundCheckErrorTitle =>
      'Kontrola upozornení na pozadí zlyhala';

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
      'Your TankSync schema is outdated — re-run the setup SQL below to enable the latest synced features.';

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
      'Zdieľajte obľúbené a hodnotenia so všetkými používateľmi';

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
  String get evChargingSection => 'Nabíjanie EV';

  @override
  String get fuelStationsSection => 'Čerpacie stanice';

  @override
  String get yourRating => 'Vaše hodnotenie';

  @override
  String get noStorageUsed => 'Žiadne využité úložisko';

  @override
  String get aboutReportBug => 'Nahlásiť chybu / Navrhnúť funkciu';

  @override
  String get aboutSupportProject => 'Podporiť tento projekt';

  @override
  String get aboutSupportDescription =>
      'Táto aplikácia je bezplatná, open source a bez reklám. Ak vám je užitočná, zvážte podporu vývojára.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Ceny palív v Luxemburgu sú regulované vládou a jednotné po celej krajine.';

  @override
  String get luxembourgFuelUnleaded95 => 'Natural 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Natural 98';

  @override
  String get luxembourgFuelDiesel => 'Nafta';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Regulované ceny palív v Luxemburgu nie sú dostupné.';

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
    return '$label is due now.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Zaregistrujte sa na OPINET pre získanie bezplatného kľúča API';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Zaregistrujte sa na CNE pre získanie bezplatného kľúča API';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

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
      'Recording with GPS — waiting for the OBD2 adapter';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Kalibrácia spotreby aktualizovaná pre $vehicleName — presnosť zlepšená o $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Resetovať volumetrickú účinnosť?';

  @override
  String get veResetConfirmBody =>
      'Toto zahodí naučenú volumetrickú účinnosť (η_v) a obnoví predvolenú hodnotu (0,85). Odhady prietoku paliva na úrovni jazdy sa vrátia k výrobnej konštante, kým kalibrátor nezhromaždí nové vzorky z nasledujúcich jázd.';

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
  String get alertsRadiusThreshold => 'Prahová hodnota (€/L)';

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
  String get alertsRadiusDeleteConfirm => 'Odstrániť upozornenie v okruhu?';

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
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel klesol na blízkych staniciach';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount staníc kleslo až o $maxDropCents¢ za poslednú hodinu';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankovanie uložené';

  @override
  String get radiusAlertsEntryTitle => 'Upozornenia v okruhu a štatistiky';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Dostávajte upozornenia, keď ceny klesnú vo vašej blízkosti';

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
      'No data from the vehicle — start the engine and try again.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adaptér OBD2 odoslal nerozpoznanú odpoveď. Možno nie je kompatibilný — skúste iný adaptér.';

  @override
  String get obd2ErrorDisconnected =>
      'Adaptér OBD2 sa odpojil. Pripojte sa znova a skúste to znova.';

  @override
  String get obd2ErrorPairingRequired =>
      'The adapter needs Bluetooth pairing. Unplug the adapter, plug it back in, then retry within 5 minutes.';

  @override
  String get onboardingExploreDemoData => 'Preskúmať s ukážkovými údajmi';

  @override
  String get achievementSmoothDriver => 'Séria plynulej jazdy';

  @override
  String get achievementSmoothDriverDesc =>
      'Jazdite 5 jázd za sebou so skóre plynulej jazdy 80 alebo vyšším.';

  @override
  String get achievementColdStartAware => 'Vedomý studeného štartu';

  @override
  String get achievementColdStartAwareDesc =>
      'Udržujte náklady na palivo pri studenom štarte počas celého mesiaca pod 2 % z celkového paliva — kombinujte krátke jazdy.';

  @override
  String get achievementHighwayMaster => 'Majster diaľnic';

  @override
  String get achievementHighwayMasterDesc =>
      'Dokončite jazdu 30+ km pri konštantnej rýchlosti so skóre plynulej jazdy 90 alebo vyšším.';

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
  String alertsLastChecked(String when) {
    return 'Last checked: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Prices haven\'t been checked in the background yet';

  @override
  String get alertsIosBestEffortNote =>
      'On iPhone, alert checks are best effort: iOS decides when the app may check prices in the background, so an alert can arrive late or occasionally not at all. Opening the app always runs a fresh check.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Cieľová cena ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Prah ($currency/L)';
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
  String approachStationDistance(String meters) {
    return '$meters m ďaleko';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return '$km km ďalej';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Blízkosť $percent%';
  }

  @override
  String get pipTapToRestore => 'Tap to open the full app';

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
  String get authLinkEmailTitle => 'Link an email';

  @override
  String get authLinkEmailSubtitle =>
      'Link an email so your data syncs across devices. Your current favorites and trips stay on this account.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'You\'re using a guest account ($idPrefix…). Link an email so your favorites and trips sync to your other devices.';
  }

  @override
  String get authConfirmationPending =>
      'Almost there — check your email and click the link to finish linking it. Your data is already saved on this account.';

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
  String get autoRecordPairedAdapterLabel => 'Spárovaný adaptér';

  @override
  String get autoRecordPairedAdapterNone =>
      'Žiadny adaptér nie je spárovaný. Najprv spárujte cez úvodné nastavenie OBD2.';

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
  String get autoRecordBadgeClearTooltip => 'Vymazať počítadlo';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Spárujte adaptér v sekcii nižšie pre zapnutie automatického záznamu';

  @override
  String get exportBackupTooltip => 'Exportovať zálohu';

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
  String get restoreBackupTooltip => 'Obnoviť zálohu';

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
  String restoreBackupSuccess(int count) {
    return 'Záloha obnovená — importovaných $count záznamov';
  }

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
  String get brokenMapChipVerifying => 'Overovanie MAP senzora…';

  @override
  String get brokenMapChipDisclaimer => 'Hodnoty MAP senzora sú podozrivé';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP senzor číta nesprávne — hodnoty paliva môžu byť o 50–80 % nízke. Skúste iný adaptér.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP senzor nespoľahlivý. Zobrazujú sa priemerné hodnoty tankovania namiesto živého prietoku paliva.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP senzor: overený ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP senzor: overuje sa ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP senzor: podozrivý ($confidence)';
  }

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
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrované, $samples vzoriek)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (učenie, $samples vzoriek)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (predvolené — zatiaľ žiadne plné tankovanie)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples vzoriek';
  }

  @override
  String get calibrationResetLearner => 'Resetovať učenie';

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
      'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Váš $makeModel je označený ako diesel, ale zodpovedá katalógovej položke benzín. Klepnutím aktualizujte.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aktualizovať';

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
  String get chargingChartsMonthAxis => 'Mesiac';

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
  String get greeceApiProvider => 'Paratiritirio Timon (Grécko)';

  @override
  String get greeceCommunityApiNotice =>
      'Poháňané komunitne udržiavaným API fuelpricesgr';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumunsko)';

  @override
  String get romaniaScrapingNotice =>
      'Poháňané monitorulpreturilor.info (Rada pre hospodársku súťaž + ANPC)';

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
  String get developerToolsSectionTitle => 'Nástroje pre vývojárov';

  @override
  String get dataAccessTracerExport => 'Export data-access trace';

  @override
  String get dataAccessTracerExportSuccess =>
      'Data-access trace saved to Downloads.';

  @override
  String get dataAccessTracerExportFailure =>
      'Couldn\'t export the data-access trace.';

  @override
  String get dataAccessTracerEmpty =>
      'No data-access events recorded yet — search or open stations first, then export.';

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
  String get startupTraceSectionTitle => 'Startup initialization trace';

  @override
  String get startupTraceExportButton => 'Export startup trace';

  @override
  String get startupTraceEmpty => 'No startup trace recorded yet.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Total: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess => 'Startup trace saved to Downloads.';

  @override
  String get startupTraceExportFailure => 'Couldn\'t export the startup trace.';

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
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Trvalo vysoká rýchlosť ($pctTime % jazdy): zbytočne $liters l';
  }

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
    return 'Mixture looks a little lean — the engine added fuel ($pctTrim% trim) to compensate';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Mixture looks lean — the engine sustained a large $pctTrim% fuel addition, a possible inefficiency';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Mixture looks a little rich — the engine pulled fuel ($pctTrim% trim) to compensate';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Mixture looks rich — the engine sustained a large $pctTrim% fuel cut, a possible inefficiency';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Engine ran rich under load ($pctShare% of the warm drive) — possible wasted fuel';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristic health signal, not a diagnosis';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'A sustained lean-correcting trim can mean an intake-air leak, a weak fuel supply, or an ageing sensor. If consumption or running quality worsens, a workshop scan can confirm.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'A sustained rich-correcting trim can mean a leaking injector, high fuel pressure, or an over-reading sensor. If consumption or running quality worsens, a workshop scan can confirm.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Running rich under heavy load burns extra fuel. Short-shift and ease off on long pulls so the engine can stay near a stoichiometric mixture.';

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
  String get minimalDriveTripAverage => 'Trip average';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'High-RPM cruising ($pctTime% of trip): shifting up earlier could save $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Shift up earlier when cruising — the same speed at lower RPM burns noticeably less fuel.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Fuel-cut coasting ($pctTime% of trip): saved about $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Nicely anticipated — lifting off early lets the engine cut fuel completely while coasting.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Where your fuel went';

  @override
  String get fuelBreakdownIdle => 'Idling';

  @override
  String get fuelBreakdownHarshAccel => 'Hard accelerations';

  @override
  String get fuelBreakdownHighRpmCruise => 'High-RPM cruising';

  @override
  String get fuelBreakdownCoastingSaved => 'Saved by coasting';

  @override
  String get fuelBreakdownEfficient => 'Normal driving';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Idling for a while — switching the engine off saves fuel';

  @override
  String get ecoNudgeHarshAccel =>
      'Strong acceleration — a gentler pedal saves fuel';

  @override
  String get ecoNudgeHighRpm =>
      'High revs at cruise — shifting up earlier saves fuel';

  @override
  String get ecoRouteOption => 'Eko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L ušetrených';
  }

  @override
  String get ecoRouteHint =>
      'Inteligentnejšia jazda — uprednostňuje plynulú diaľnicu pred kľukatými skratkami.';

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
  String get featureLabel_gamification => 'Gamifikácia';

  @override
  String get featureDescription_gamification =>
      'Jazdné skóre a získané odznaky.';

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
  String get featureLabel_unifiedSearchResults =>
      'Zlúčené výsledky vyhľadávania';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Jeden zoznam výsledkov kombinujúci palivové a EV stanice.';

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
  String get featureBlockedEnable_gamification =>
      'Najprv zapnite záznam jázd OBD2';

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
  String get featureBlockedEnable_showFuel => 'Predpoklady nie sú splnené';

  @override
  String get featureBlockedEnable_showElectric => 'Predpoklady nie sú splnené';

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
  String get featureLabel_addFillUpOcrPump =>
      'OCR displeja pumpy (experimentálne)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Naskenujte displej palivovej pumpy a predvyplňte formulár. Rozpoznávanie je dnes nespoľahlivé — aktivujte iba ak chcete testovať.';

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
      'This vehicle can use different fuels — log the one you actually pumped';

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
  String get fillUpImportPasteLabel => 'Paste text';

  @override
  String get pasteReceiptDialogTitle => 'Paste receipt text';

  @override
  String get pasteReceiptDialogHint =>
      'Paste the text of a fuel receipt — e-mail, SMS, or a shared PDF. The litres, price per litre, fuel grade, total and station are read on-device and used to pre-fill the form. Nothing is sent to a server.';

  @override
  String get pasteReceiptFieldHint => 'Receipt text';

  @override
  String get pasteReceiptParseAction => 'Pre-fill';

  @override
  String get pasteReceiptNoData =>
      'Couldn\'t read any fuel data from that text — check it\'s a fuel receipt and try again.';

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
  String get scanPumpUnreadable =>
      'Displej pumpy nie je čitateľný — skúste znova';

  @override
  String get scanPumpSuccess => 'Displej pumpy naskenovaný — overte hodnoty.';

  @override
  String get scanPumpGlare =>
      'Príliš veľa odleskov na displeji — skús to znova z mierneho uhla, aby čísla neboli prežiarené.';

  @override
  String get scanPumpInconsistent =>
      'Naskenované hodnoty nesedí — zadajte ich prosím ručne.';

  @override
  String scanPumpFailed(String error) {
    return 'Skenovanie pumpy zlyhalo: $error';
  }

  @override
  String get badScanReportTitle => 'Nahlásiť chybu skenovania';

  @override
  String get badScanReportTitleReceipt => 'Nahlásiť chybu skenovania — Doklad';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Nahlásiť chybu skenovania — Displej pumpy';

  @override
  String get pumpScanFailureTitle => 'Displej nečitateľný';

  @override
  String get pumpScanFailureBody =>
      'Skenovanie nemohlo prečítať displej pumpy. Čo chcete urobiť?';

  @override
  String get pumpScanFailureCorrectManually => 'Opraviť ručne';

  @override
  String get pumpScanFailureReport => 'Nahlásiť';

  @override
  String get pumpScanFailureRemove => 'Odstrániť fotografiu';

  @override
  String get badScanReportHint =>
      'Zdieľame fotografiu dokladu a obe sady hodnôt, aby sa nasledujúca verzia mohla naučiť toto rozloženie.';

  @override
  String get badScanReportShareAction => 'Zdieľať hlásenie + fotografiu';

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
  String get pumpCameraHint =>
      'Zarovnajte tri čísla z displeja stojana do rámčeka';

  @override
  String get pumpCameraCapture => 'Odfotiť';

  @override
  String get pumpCameraPermissionDenied =>
      'Na naskenovanie displeja stojana je potrebný prístup ku kamere. Povoľte ho v nastaveniach zariadenia.';

  @override
  String get pumpCameraError =>
      'Kameru sa nepodarilo spustiť. Skúste to znova alebo zadajte hodnoty ručne.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Prepnúť na vodorovné rozloženie';

  @override
  String get pumpCameraOrientationVertical => 'Prepnúť na zvislé rozloženie';

  @override
  String get pumpCameraGlareWarning =>
      'Príliš veľa odleskov — mierne nakloňte, aby ste sa vyhli odrazom';

  @override
  String get pumpCameraAlignHint =>
      'Zarovnajte displej do rámčeka a potom odfotografujte';

  @override
  String get pumpCameraRotateToLandscape =>
      'Otočte telefón na šírku — displej pumpy je široký, takže čísla vychádzajú väčšie a vzpriamené';

  @override
  String get fillUpWarningDialogTitle => 'Check this fill-up';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'You picked $chosenFuel, but this vehicle runs on $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Odometer $entered km is below the previous fill-up\'s $previous km — distance can\'t go backwards.';
  }

  @override
  String get fillUpWarningGoBack => 'Go back and fix';

  @override
  String get fillUpWarningSaveAnyway => 'Save anyway';

  @override
  String get fillUpSectionWhatTitle => 'Čo ste natankovali';

  @override
  String get fillUpSectionWhatSubtitle => 'Palivo, množstvo, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kde ste boli';

  @override
  String get fillUpSectionWhereSubtitle => 'Stanica, tachometer, poznámky';

  @override
  String get fillUpImportFromLabel => 'Importovať z…';

  @override
  String get fillUpImportSheetTitle => 'Importovať údaje o tankovaní';

  @override
  String get fillUpImportReceiptLabel => 'Doklad';

  @override
  String get fillUpImportReceiptDescription =>
      'Naskenovať papierový doklad kamerou';

  @override
  String get fillUpImportPumpLabel => 'Displej pumpy';

  @override
  String get fillUpImportPumpDescription =>
      'Prečítať Betrag / Preis z LCD pumpy';

  @override
  String get fillUpImportObdLabel => 'OBD-II adaptér';

  @override
  String get fillUpImportObdDescription =>
      'Prečítať tachometer z OBD-II portu cez Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Cena za liter';

  @override
  String get vehicleHeaderPlateLabel => 'ŠPZ';

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
  String get fuelEfficiencyCardTitle => 'Cost per kilometre by fuel';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Which fuel is actually cheapest to drive on';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Cheapest per km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Pure';

  @override
  String get fuelEfficiencyMixBadge => 'Blend';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Mostly $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Cost/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Total spent';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills',
      one: '1 fill',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyMixedFootnote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mixed tanks counted toward their main fuel',
      one: '1 mixed tank counted toward its main fuel',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Log at least two full tanks per fuel to crown the cheapest.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Tanks are grouped by composition: a tank is pure when one fuel is at least 85% of it, otherwise a blend.';

  @override
  String get fuelNameE5 => 'Super E5';

  @override
  String get fuelNameE10 => 'Super E10';

  @override
  String get fuelNameE98 => 'Super 98';

  @override
  String get fuelNameDiesel => 'Diesel';

  @override
  String get fuelNameDieselPremium => 'Diesel Premium';

  @override
  String get fuelNameE85 => 'E85 Bioethanol';

  @override
  String get fuelNameLpg => 'LPG';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Hydrogen';

  @override
  String get fuelNameElectric => 'Electric';

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
  String get profileGamificationToggleTitle => 'Zobrazovať úspechy a skóre';

  @override
  String get profileGamificationToggleSubtitle =>
      'Keď je vypnuté, odznaky, skóre a trofejové ikony sú skryté v celej aplikácii.';

  @override
  String get coachingGpsLiftOff => 'Uvoľniť plyn';

  @override
  String get coachingGpsAnticipateBrake => 'Predvídať';

  @override
  String get coachingGpsSmoothAccel => 'Plynulé zrýchlenie';

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
  String get gpsKpiVerdictGood => 'Efficient';

  @override
  String get gpsKpiVerdictModerate => 'Moderate';

  @override
  String get gpsKpiVerdictAggressive => 'Aggressive';

  @override
  String get gpsKpiInterpretationGood =>
      'Smooth, energy-light driving — this is what efficient looks like.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Fairly typical driving — a little smoother on the throttle would save more.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energy-heavy driving — easing off the accelerator and coasting more would cut fuel use.';

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
  String get gpsRoadUseCardTitle => 'How you used the road';

  @override
  String get gpsRoadUseSpeedSection => 'Where you spent your time';

  @override
  String get gpsRoadUseSpeedIdle => 'Stopped (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Town (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Cruise (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Fast (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'How you moved';

  @override
  String get gpsRoadUsePhaseAccel => 'Accelerating';

  @override
  String get gpsRoadUsePhaseSteady => 'Holding speed';

  @override
  String get gpsRoadUsePhaseCoast => 'Coasting';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct%';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Lots of coasting — letting the car roll instead of braking saves fuel. Nice.';

  @override
  String get gpsRoadUseSource => 'From your GPS track';

  @override
  String get hapticEcoCoachSectionTitle => 'Jazda';

  @override
  String get hapticEcoCoachSettingTitle => 'Eko koučing v reálnom čase';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Jemná haptika + tip na obrazovke, keď šliahnete plyn pri jazde na stálo';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Šetrite plynom — voľný beh šetrí viac';

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
  String get privacyLocalDataEmpty =>
      'Zatiaľ nič neuložené. Pridajte obľúbenú položku alebo nastavte cenové upozornenie pre zobrazenie záznamov tu.';

  @override
  String get privacyHideEmptyRows => 'Skryť prázdne riadky';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobraziť $count prázdnych riadkov',
      one: 'Zobraziť $count prázdny riadok',
    );
    return '$_temp0';
  }

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
  String get routeStrategyLabel => 'Stratégia:';

  @override
  String get routeStrategyUniform => 'Rovnomerná';

  @override
  String get routeStrategyBalanced => 'Vyvážená';

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
      'Trips back up under this device\'s anonymous account. Sign in with an email to reach them from other devices.';

  @override
  String get consentHideDetails => 'Skryť podrobnosti';

  @override
  String get consentShowDetails => 'Zobraziť podrobnosti';

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
  String get locationConsentDecline => 'Odmietnuť';

  @override
  String get locationConsentAccept => 'Prijať';

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
  String get obd2DiagnosticsReconnectSection => 'Reconnect telemetry';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts reconnect attempts · $successes ok · $transitions transitions · $disconnects typed drops';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'GPS-only fallback activated this session.';

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
  String get obd2HealthCopyInitTranscript =>
      'Kopírovať iba záznam inicializácie';

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
  String get obd2HealthCopyJson => 'Kopírovať ako JSON';

  @override
  String get obd2HealthCopied => 'Diagnostika OBD2 skopírovaná do schránky.';

  @override
  String get obd2HealthDownloadJson => 'Download as JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Download init transcript only';

  @override
  String get obd2HealthDownloadError => 'Couldn\'t save the diagnostics file';

  @override
  String get obd2TestAdapterLabel => 'Adapter to test';

  @override
  String get obd2TestAdapterScanOption => 'Scan for adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Connect to $adapter';
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
      'Adapter OK — engine off; start the engine to read live data';

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
  String get obd2TestStepConnect => 'Pripojiť a inicializovať';

  @override
  String get obd2TestStepInfo => 'Informácie o adaptéri';

  @override
  String get obd2TestStepSupportedPids => 'Podporované PIDy';

  @override
  String get obd2TestStepSampleReads => 'Ukážkové čítania';

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
  String get obd2TestAdapterTransportUnknown => 'unknown — defaulting to BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Recent connect attempts';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'No connect attempts recorded yet.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Download connect trace';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Download all connect traces';

  @override
  String get obd2HealthConnectOrigin => 'Origin';

  @override
  String get obd2HealthConnectTransport => 'Transport';

  @override
  String get obd2HealthConnectOutcome => 'Outcome';

  @override
  String get obd2HealthConnectScanList => 'Scanned devices';

  @override
  String get obd2HealthConnectSteps => 'Steps';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Unknown adapter';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nepodarilo sa dosiahnuť \'$adapterName\' — vyberte iný adaptér';
  }

  @override
  String get obd2PickerOtherDevices => 'Other Bluetooth devices';

  @override
  String get obd2PickerTapToTry => 'Unrecognized — tap to try';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone works with Bluetooth-LE adapters only. A Classic-only adapter (e.g. vLinker BM, Konnwei KW902) must be used on Android.';

  @override
  String get obd2PairingConfirmHint =>
      'Confirm the pairing request on your phone';

  @override
  String get obd2ReconnectInProgress => 'Reconnecting to your OBD2 adapter…';

  @override
  String obd2ReconnectInProgressNamed(String adapter) {
    return 'Reconnecting to $adapter…';
  }

  @override
  String get obd2ReconnectFailedTitle => 'Couldn’t reconnect to your adapter';

  @override
  String get obd2ReconnectFailedBody =>
      'The OBD2 connection was lost and automatic reconnection didn’t succeed. Check the adapter is powered and in range, then tap retry.';

  @override
  String get obd2ReconnectRetry => 'Tap to retry';

  @override
  String get obd2WedgeHintBody =>
      'Your OBD2 adapter stopped responding. Switch the ignition off and on or replug the adapter — or toggle Bluetooth off and on.';

  @override
  String get obd2WedgeHintOpenBtSettings => 'Bluetooth settings';

  @override
  String get ocrTesterTitle => 'Tester OCR';

  @override
  String get ocrTesterNavLabel => 'Tester OCR';

  @override
  String get ocrTesterExplain =>
      'Spustí kanál OCR pre pumpu/paragon na vybranej fotografii a skontroluje každý krok — dostupné iba vo vývojárskom režime.';

  @override
  String get ocrTesterModePump => 'Pumpa';

  @override
  String get ocrTesterModeReceipt => 'Paragon';

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
  String get ocrTesterNoResult => 'OCR neprodukoval čitateľný výsledok.';

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
  String get ocrTesterSaveFixture => 'Uložiť ako fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture uložená do priečinka Stiahnuté. Presuňte ju do test/fixtures a spustite tool/promote_ocr_fixture.dart.';

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
  String get onboardingObd2VinReadFailed =>
      'Nepodarilo sa prečítať VIN — zadajte ručne';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nepodarilo sa pripojiť k adaptéru. Môžete skúsiť znova alebo preskočiť.';

  @override
  String get onboardingPickUseMode =>
      'Pre pokračovanie vyberte režim používania.';

  @override
  String get openNow => 'Otvorené';

  @override
  String get openNowClosed => 'Zatvorené';

  @override
  String get openHoursUnknown => 'Otváracie hodiny neznáme';

  @override
  String closesAt(String time) {
    return 'Zatvára o $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Otvára $day o $time';
  }

  @override
  String opensToday(String time) {
    return 'Otvára o $time';
  }

  @override
  String get open24Hours => 'Otvorené 24 hodín';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => 'Automatizovať 24/7';

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
  String get openStateUnknown => 'Unknown';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Station is open',
      'false': 'Station is closed',
      'other': 'Open state unknown',
    });
    return '$_temp0';
  }

  @override
  String get tripRecordingPipEstConsumptionCaption => 'odh. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Odhadovaná hodnota (~) — na tomto výlete nie je snímač paliva, takže hodnota L/100 km je modelovaná z rýchlosti GPS a kalibrácie vášho vozidla. Je to priblíženie (zvyčajne ±10–30 %, spresňuje sa s kalibráciou), nie nameraná hodnota.';

  @override
  String get tripRecordingPipElapsedCaption => 'uplynulo';

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
  String get radarScopeShowScope => 'Radar view';

  @override
  String get radarScopeShowList => 'List view';

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
  String get radiusAlertCenterFromMap => 'Poloha na mape';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel pri $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Stanica má cenu $price € (cieľ: $threshold €)';
  }

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
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/relácia';

  @override
  String get shareReceiptImporting => 'Importujem zdieľaný paragon…';

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
  String get storageRecoveryTitle => 'Problém s úložiskom';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo nedokázalo otvoriť svoje lokálne dátové úložisko. Súbor úložiska je zrejme poškodený.';

  @override
  String get storageRecoveryGuidance =>
      'Na obnovu vymažte úložisko aplikácie v nastaveniach zariadenia alebo aplikáciu preinštalujte. Vaše obľúbené položky a história sú uložené iba v tomto zariadení, takže ich nemožno obnoviť automaticky.';

  @override
  String syncAdoptTitle(String email) {
    return 'Join $email\'s account';
  }

  @override
  String get syncAdoptSubtitle =>
      'Sign in with this account\'s password to share its data across both devices.';

  @override
  String get syncAdoptPasswordLabel => 'Account password';

  @override
  String get syncAdoptJoinButton => 'Join account';

  @override
  String get syncAdoptUseDifferentAccount => 'Use a different account instead';

  @override
  String get syncRelinkTitle => 'Cloud sync needs re-linking';

  @override
  String get syncRelinkBody =>
      'This device\'s saved sync identity is signed out. Sign in with your email to re-link your synced data, or start fresh with a new identity.';

  @override
  String get syncRelinkSignInAction => 'Sign in to re-link';

  @override
  String get syncRelinkStartFreshAction => 'Start fresh';

  @override
  String get syncRelinkStartFreshTitle => 'Start fresh?';

  @override
  String get syncRelinkStartFreshBody =>
      'A new anonymous identity will be created for this device. Data synced under the old identity stays on the server but will no longer be reachable from here unless you sign in with its email account.';

  @override
  String get syncRelinkStartFreshConfirm => 'Start fresh';

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
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Posledné tankovanie: $date · $count jazda(y) odvtedy';
  }

  @override
  String get tankLevelMethodObd2 => 'Merané OBD2';

  @override
  String get tankLevelMethodDistanceFallback => 'odhad na základe vzdialenosti';

  @override
  String get tankLevelMethodMixed => 'zmiešané meranie';

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
  String get trajetDetailChartAltitude => 'Nadmorská výška (m)';

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
  String get trajetDetailDeleteConfirmCancel => 'Zrušiť';

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
  String get tripPathLegendTitle => 'Spotreba';

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
  String get radarAcquiringLocation => 'Finding your location…';

  @override
  String get radarUpdatingLocation => 'Updating your location…';

  @override
  String get radarSearching => 'Searching…';

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
  String get tripBannerOpenFromConsumptionTab =>
      'Otvoriť aktívnu jazdu z karty Spotreba';

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
  String get unifiedFilterFuel => 'Palivo';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Oboje';

  @override
  String get unifiedNoResultsForFilter => 'Žiadne výsledky pre tento filter';

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
  String get stationUnbrandedTitle => 'Unbranded station';

  @override
  String get unsupportedRegionTitle => 'Not available in your region yet';

  @override
  String get unsupportedRegionBody =>
      'We don\'t have fuel prices for your country yet, so results may be empty or from another country. You can still pick a supported country in the search settings.';

  @override
  String get unsupportedRegionDismiss => 'Got it';

  @override
  String get configureCountryTitle => 'Set your country';

  @override
  String get configureCountryBody =>
      'Your country is supported, but it isn\'t set up yet — so prices may be from another country. Choose your country in the search settings to see local prices.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'I may fill up with different fuel types';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Tracks which fuel is cheapest per kilometre';

  @override
  String get vinLabel => 'VIN (voliteľné)';

  @override
  String get vinDecodeTooltip => 'Dekódovať VIN';

  @override
  String get vinConfirmAction => 'Áno, automaticky vyplniť';

  @override
  String get vinModifyAction => 'Upraviť ručne';

  @override
  String get veResetAction => 'Resetovať volumetrickú účinnosť';

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
  String get vehicleDetectedFromVinBadge => '(zistené)';

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
  String get widgetDefaultsApplyToAllHint =>
      'Voľby nižšie sa použijú na všetky nainštalované widgety pri ďalšom obnovení.';

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

  @override
  String get widgetPredictiveNowPrefix => 'teraz';
}
