// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'Kütusehinnad';

  @override
  String get search => 'Otsi';

  @override
  String get favorites => 'Lemmikud';

  @override
  String get map => 'Kaart';

  @override
  String get profile => 'Profiil';

  @override
  String get settings => 'Seaded';

  @override
  String get gpsLocation => 'GPS asukoht';

  @override
  String get zipCode => 'Postiindeks';

  @override
  String get zipCodeHint => 'nt. 10111';

  @override
  String get fuelType => 'Kütus';

  @override
  String get searchRadius => 'Raadius';

  @override
  String get searchNearby => 'Lähedalolevad tankla';

  @override
  String get searchButton => 'Otsi';

  @override
  String get noResults => 'Tanklasid ei leitud.';

  @override
  String get startSearch => 'Otsige tanklasid.';

  @override
  String get open => 'Avatud';

  @override
  String get closed => 'Suletud';

  @override
  String distance(String distance) {
    return '$distance kaugusel';
  }

  @override
  String get price => 'Hind';

  @override
  String get prices => 'Hinnad';

  @override
  String get address => 'Aadress';

  @override
  String get openingHours => 'Lahtiolekuajad';

  @override
  String get open24h => 'Avatud 24 tundi';

  @override
  String get navigate => 'Navigeeri';

  @override
  String get retry => 'Proovi uuesti';

  @override
  String get apiKeySetup => 'API võti';

  @override
  String get apiKeyDescription =>
      'Registreeruge üks kord tasuta API võtme saamiseks.';

  @override
  String get apiKeyLabel => 'API võti';

  @override
  String get register => 'Registreerumine';

  @override
  String get continueButton => 'Jätka';

  @override
  String get welcome => 'Kütusehinnad';

  @override
  String get welcomeSubtitle => 'Leidke lähim odavaim kütus.';

  @override
  String get profileName => 'Profiili nimi';

  @override
  String get preferredFuel => 'Eelistatud kütus';

  @override
  String get defaultRadius => 'Vaikimisi raadius';

  @override
  String get landingScreen => 'Avakuva';

  @override
  String get homeZip => 'Kodu postiindeks';

  @override
  String get newProfile => 'Uus profiil';

  @override
  String get editProfile => 'Muuda profiili';

  @override
  String get save => 'Salvesta';

  @override
  String get cancel => 'Tühista';

  @override
  String get delete => 'Kustuta';

  @override
  String get activate => 'Aktiveeri';

  @override
  String get configured => 'Seadistatud';

  @override
  String get notConfigured => 'Seadistamata';

  @override
  String get about => 'Teave';

  @override
  String get openSource => 'Avatud lähtekood (MIT litsents)';

  @override
  String get sourceCode => 'Lähtekood GitHubis';

  @override
  String get noFavorites => 'Lemmikuid pole';

  @override
  String get noFavoritesHint =>
      'Puudutage tankla tähte, et salvestada see lemmikuks.';

  @override
  String get language => 'Keel';

  @override
  String get country => 'Riik';

  @override
  String get demoMode => 'Demorežiim — näidisandmed.';

  @override
  String get setupLiveData => 'Seadista reaalajas andmed';

  @override
  String get freeNoKey => 'Tasuta — võtit pole vaja';

  @override
  String get apiKeyRequired => 'API võti nõutud';

  @override
  String get skipWithoutKey => 'Jätka ilma võtmeta';

  @override
  String get dataTransparency => 'Andmete läbipaistvus';

  @override
  String get storageAndCache => 'Salvestusruum ja vahemälu';

  @override
  String get clearCache => 'Tühjenda vahemälu';

  @override
  String get clearAllData => 'Kustuta kõik andmed';

  @override
  String get errorLog => 'Vigade logi';

  @override
  String stationsFound(int count) {
    return 'Leiti $count tanklat';
  }

  @override
  String get whatIsShared => 'Mida jagatakse — ja kellega?';

  @override
  String get gpsCoordinates => 'GPS koordinaadid';

  @override
  String get gpsReason =>
      'Saadetakse iga otsinguga lähedalolevate jaamade leidmiseks.';

  @override
  String get postalCodeData => 'Postiindeks';

  @override
  String get postalReason =>
      'Teisendatakse koordinaatideks geokodeerimise teenuse kaudu.';

  @override
  String get mapViewport => 'Kaardi vaade';

  @override
  String get mapReason =>
      'Kaardi paanid laaditakse serverist. Isikuandmeid ei edastata.';

  @override
  String get apiKeyData => 'API võti';

  @override
  String get apiKeyReason =>
      'Teie isiklik võti saadetakse iga API päringuga. See on seotud teie e-postiga.';

  @override
  String get notShared => 'EI jagata:';

  @override
  String get searchHistory => 'Otsinguajalugu';

  @override
  String get favoritesData => 'Lemmikud';

  @override
  String get profileNames => 'Profiilide nimed';

  @override
  String get homeZipData => 'Kodu postiindeks';

  @override
  String get usageData => 'Kasutusandmed';

  @override
  String get privacyBanner =>
      'Sellel rakendusel pole serverit. Kõik andmed jäävad teie seadmesse. Pole analüütikat, jälgimist ega reklaame.';

  @override
  String get storageUsage => 'Salvestusruumi kasutus selles seadmes';

  @override
  String get settingsLabel => 'Seaded';

  @override
  String get profilesStored => 'salvestatud profiili';

  @override
  String get stationsMarked => 'märgitud tanklat';

  @override
  String get cachedResponses => 'vahemällu salvestatud vastust';

  @override
  String get total => 'Kokku';

  @override
  String get cacheManagement => 'Vahemälu haldus';

  @override
  String get cacheDescription =>
      'Vahemälu salvestab API vastuseid kiiremaks laadimiseks ja võrguühenduseta juurdepääsuks.';

  @override
  String get stationSearch => 'Jaamade otsing';

  @override
  String get stationDetails => 'Jaama üksikasjad';

  @override
  String get priceQuery => 'Hinnapäring';

  @override
  String get zipGeocoding => 'Postiindeksi geokodeerimine';

  @override
  String minutes(int n) {
    return '$n minutit';
  }

  @override
  String hours(int n) {
    return '$n tundi';
  }

  @override
  String get clearCacheTitle => 'Tühjenda vahemälu?';

  @override
  String get clearCacheBody =>
      'Vahemällu salvestatud otsingutulemused ja hinnad kustutatakse. Profiilid, lemmikud ja seaded säilitatakse.';

  @override
  String get clearCacheButton => 'Tühjenda vahemälu';

  @override
  String get deleteAllTitle => 'Kustuta kõik andmed?';

  @override
  String get deleteAllBody =>
      'See kustutab jäädavalt kõik profiilid, lemmikud, API võtme, seaded ja vahemälu. Rakendus lähtestatakse.';

  @override
  String get deleteAllButton => 'Kustuta kõik';

  @override
  String get entries => 'kirjet';

  @override
  String get cacheEmpty => 'Vahemälu on tühi';

  @override
  String get noStorage => 'Salvestusruum pole kasutuses';

  @override
  String get apiKeyNote =>
      'Tasuta registreerumine. Andmed riiklike hinnaläbipaistvuse asutuste käest.';

  @override
  String get apiKeyFormatError => 'Vigane vorming — oodatav UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Toetage seda projekti';

  @override
  String get supportDescription =>
      'See rakendus on tasuta, avatud lähtekoodiga ja reklaamivaba. Kui leiate selle kasulikuks, kaaluge arendaja toetamist.';

  @override
  String get reportBug => 'Teata veast / Soovita funktsiooni';

  @override
  String get privacyPolicy => 'Privaatsuspoliitika';

  @override
  String get fuels => 'Kütused';

  @override
  String get services => 'Teenused';

  @override
  String get zone => 'Tsoon';

  @override
  String get highway => 'Kiirtee';

  @override
  String get localStation => 'Kohalik tankla';

  @override
  String get lastUpdate => 'Viimane uuendus';

  @override
  String get automate24h => '24t/24 — Automaat';

  @override
  String get refreshPrices => 'Uuenda hindu';

  @override
  String get station => 'Tankla';

  @override
  String get locationDenied =>
      'Asukoha luba keelatud. Saate otsida postiindeksi järgi.';

  @override
  String get demoModeBanner => 'Demorežiim. Seadistage API võti seadetes.';

  @override
  String get sortDistance => 'Kaugus';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'odav';

  @override
  String get expensive => 'kallis';

  @override
  String stationsOnMap(int count) {
    return '$count tanklat';
  }

  @override
  String get loadingFavorites =>
      'Lemmikute laadimine...\nOtsige kõigepealt tanklasid andmete salvestamiseks.';

  @override
  String get reportPrice => 'Teata hinnast';

  @override
  String get whatsWrong => 'Mis on valesti?';

  @override
  String get correctPrice => 'Õige hind (nt. 1,459)';

  @override
  String get sendReport => 'Saada teade';

  @override
  String get reportSent => 'Teade saadetud. Aitäh!';

  @override
  String get enterValidPrice => 'Sisestage kehtiv hind';

  @override
  String get cacheCleared => 'Vahemälu tühjendatud.';

  @override
  String get yourPosition => 'Teie asukoht';

  @override
  String get positionUnknown => 'Asukoht teadmata';

  @override
  String get distancesFromCenter => 'Kaugused otsingu keskpunktist';

  @override
  String get autoUpdatePosition => 'Uuenda asukohta automaatselt';

  @override
  String get autoUpdateDescription => 'Uuenda GPS asukohta enne iga otsingut';

  @override
  String get location => 'Asukoht';

  @override
  String get switchProfileTitle => 'Riik muutus';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Olete nüüd riigis $country. Lülituda profiilile \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Lülitatud profiilile \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Selle riigi jaoks pole profiili';

  @override
  String noProfileForCountry(String country) {
    return 'Olete riigis $country, kuid profiili pole seadistatud. Looge see Seadetes.';
  }

  @override
  String get autoSwitchProfile => 'Automaatne profiili vahetamine';

  @override
  String get autoSwitchDescription =>
      'Vaheta profiili automaatselt piiri ületamisel';

  @override
  String get switchProfile => 'Vaheta';

  @override
  String get dismiss => 'Sulge';

  @override
  String get profileCountry => 'Riik';

  @override
  String get profileLanguage => 'Keel';

  @override
  String get settingsStorageDetail => 'API võti, aktiivne profiil';

  @override
  String get allFuels => 'Kõik';

  @override
  String get priceAlerts => 'Hinnahoiatused';

  @override
  String get noPriceAlerts => 'Hinnahoiatusi pole';

  @override
  String get noPriceAlertsHint => 'Looge hoiatus jaama üksikasjade lehelt.';

  @override
  String alertDeleted(String name) {
    return 'Hoiatus \"$name\" kustutatud';
  }

  @override
  String get createAlert => 'Loo hinnahoiatus';

  @override
  String currentPrice(String price) {
    return 'Praegune hind: $price';
  }

  @override
  String get targetPrice => 'Sihthind (EUR)';

  @override
  String get enterPrice => 'Sisestage hind';

  @override
  String get invalidPrice => 'Kehtetu hind';

  @override
  String get priceTooHigh => 'Hind liiga kõrge';

  @override
  String get create => 'Loo';

  @override
  String get alertCreated => 'Hinnahoiatus loodud';

  @override
  String get wrongE5Price => 'Vale Super E5 hind';

  @override
  String get wrongE10Price => 'Vale Super E10 hind';

  @override
  String get wrongDieselPrice => 'Vale diiselkütuse hind';

  @override
  String get wrongStatusOpen => 'Näidatud avatuna, kuid suletud';

  @override
  String get wrongStatusClosed => 'Näidatud suletuna, kuid avatud';

  @override
  String get searchAlongRouteLabel => 'Marsruudi ääres';

  @override
  String get searchEvStations => 'Otsi laadimisjaamu';

  @override
  String get allStations => 'Kõik jaamad';

  @override
  String get bestStops => 'Parimad peatused';

  @override
  String get openInMaps => 'Ava Kaartides';

  @override
  String get noStationsAlongRoute => 'Marsruudi ääres jaamu ei leitud';

  @override
  String get evOperational => 'Töökorras';

  @override
  String get evStatusUnknown => 'Olek teadmata';

  @override
  String evConnectors(int count) {
    return 'Pistikud ($count punkti)';
  }

  @override
  String get evNoConnectors => 'Pistiku üksikasjad pole saadaval';

  @override
  String get evUsageCost => 'Kasutuskulu';

  @override
  String get evPricingUnavailable =>
      'Hinnateave teenusepakkujalt pole saadaval';

  @override
  String get evLastUpdated => 'Viimati uuendatud';

  @override
  String get evUnknown => 'Teadmata';

  @override
  String get evDataAttribution => 'Andmed OpenChargeMapist (kogukonnaallikas)';

  @override
  String get evStatusDisclaimer =>
      'Olek ei pruugi kajastada reaalajas saadavust. Puudutage uuenda, et saada uusimaid andmeid.';

  @override
  String get evNavigateToStation => 'Navigeeri jaama';

  @override
  String get evRefreshStatus => 'Uuenda olekut';

  @override
  String get evStatusUpdated => 'Olek uuendatud';

  @override
  String get evStationNotFound =>
      'Ei saanud uuendada — jaama ei leitud lähedusest';

  @override
  String get addedToFavorites => 'Lisatud lemmikutesse';

  @override
  String get removedFromFavorites => 'Eemaldatud lemmikutest';

  @override
  String get addFavorite => 'Lisa lemmikutesse';

  @override
  String get removeFavorite => 'Eemalda lemmikutest';

  @override
  String get currentLocation => 'Praegune asukoht';

  @override
  String get gpsError => 'GPS viga';

  @override
  String get couldNotResolve => 'Algus- või sihtpunkti ei saanud määrata';

  @override
  String get start => 'Algus';

  @override
  String get destination => 'Sihtkoht';

  @override
  String get cityAddressOrGps => 'Linn, aadress või GPS';

  @override
  String get cityOrAddress => 'Linn või aadress';

  @override
  String get useGps => 'Kasuta GPS-i';

  @override
  String get stop => 'Peatus';

  @override
  String stopN(int n) {
    return 'Peatus $n';
  }

  @override
  String get addStop => 'Lisa peatus';

  @override
  String get searchAlongRoute => 'Otsi marsruudi äärest';

  @override
  String get cheapest => 'Odavaim';

  @override
  String nStations(int count) {
    return '$count tanklat';
  }

  @override
  String nBest(int count) {
    return '$count parimat';
  }

  @override
  String get fuelPricesTankerkoenig => 'Kütusehinnad (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Vajalik kütusehinnaotsingurks Saksamaal';

  @override
  String get evChargingOpenChargeMap => 'EV laadimine (OpenChargeMap)';

  @override
  String get customKey => 'Kohandatud võti';

  @override
  String get appDefaultKey => 'Rakenduse vaikevõti';

  @override
  String get optionalOverrideKey =>
      'Valikuline: asendage sisseehitatud rakenduse võti enda omaga';

  @override
  String get requiredForEvSearch => 'Vajalik EV laadimisjaamade otsinguks';

  @override
  String get edit => 'Muuda';

  @override
  String get fuelPricesApiKey => 'Kütusehindade API võti';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API võti';

  @override
  String get evChargingApiKey => 'EV laadimise API võti';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API võti';

  @override
  String get routeSegment => 'Marsruudi segment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Näita odavaimat tanklat iga $km km tagant marsruudil';
  }

  @override
  String get avoidHighways => 'Väldi kiirteid';

  @override
  String get avoidHighwaysDesc =>
      'Marsruudi arvutus väldib tasulisi teid ja kiirteid';

  @override
  String get showFuelStations => 'Näita tanklasid';

  @override
  String get showFuelStationsDesc =>
      'Kaasa bensiini-, diisli-, LPG-, CNG-jaamad';

  @override
  String get showEvStations => 'Näita laadimisjaamu';

  @override
  String get showEvStationsDesc =>
      'Kaasa elektrilaadimise jaamad otsingutulemustes';

  @override
  String get noStationsAlongThisRoute =>
      'Selle marsruudi äärest jaamu ei leitud.';

  @override
  String get fuelCostCalculator => 'Kütusekulude kalkulaator';

  @override
  String get distanceKm => 'Kaugus (km)';

  @override
  String get consumptionL100km => 'Tarbimine (L/100km)';

  @override
  String get fuelPriceEurL => 'Kütuse hind (EUR/L)';

  @override
  String get tripCost => 'Reisikulu';

  @override
  String get fuelNeeded => 'Vajalik kütus';

  @override
  String get totalCost => 'Kogukulu';

  @override
  String get enterCalcValues =>
      'Sisestage kaugus, tarbimine ja hind reisikulu arvutamiseks';

  @override
  String get priceHistory => 'Hinnaajalugu';

  @override
  String get noPriceHistory => 'Hinnaajalugu puudub';

  @override
  String get noHourlyData => 'Tunniandmed puuduvad';

  @override
  String get noStatistics => 'Statistika pole saadaval';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Kesk';

  @override
  String get showAllFuelTypes => 'Näita kõiki kütuseliike';

  @override
  String get connected => 'Ühendatud';

  @override
  String get notConnected => 'Ühendamata';

  @override
  String get connectTankSync => 'Ühenda TankSync';

  @override
  String get disconnectTankSync => 'Katkesta TankSync';

  @override
  String get viewMyData => 'Vaata minu andmeid';

  @override
  String get optionalCloudSync =>
      'Valikuline pilvsünkroniseerimine hoiatuste, lemmikute ja tõuketeadete jaoks';

  @override
  String get tapToUpdateGps => 'Puudutage GPS asukoha uuendamiseks';

  @override
  String get gpsAutoUpdateHint =>
      'GPS asukoht hangitakse automaatselt otsimisel. Saate seda ka käsitsi siin uuendada.';

  @override
  String get clearGpsConfirm =>
      'Kustutada salvestatud GPS asukoht? Saate seda igal ajal uuendada.';

  @override
  String get pageNotFound => 'Lehte ei leitud';

  @override
  String get deleteAllServerData => 'Kustuta kõik serveriandmed';

  @override
  String get deleteServerDataConfirm => 'Kustutada kõik serveriandmed?';

  @override
  String get deleteEverything => 'Kustuta kõik';

  @override
  String get allDataDeleted => 'Kõik serveriandmed kustutatud';

  @override
  String get disconnectConfirm => 'Katkestada TankSync?';

  @override
  String get disconnect => 'Katkesta';

  @override
  String get myServerData => 'Minu serveriandmed';

  @override
  String get anonymousUuid => 'Anonüümne UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Sünkroniseeritud andmed';

  @override
  String get pushTokens => 'Tõukelubad';

  @override
  String get priceReports => 'Hinnateated';

  @override
  String get totalItems => 'Kokku üksusi';

  @override
  String get estimatedSize => 'Hinnanguline suurus';

  @override
  String get viewRawJson => 'Vaata toorandmeid JSON-ina';

  @override
  String get exportJson => 'Ekspordi JSON-ina (lõikelaud)';

  @override
  String get jsonCopied => 'JSON kopeeritud lõikelauale';

  @override
  String get rawDataJson => 'Toorandmed (JSON)';

  @override
  String get close => 'Sulge';

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
  String get alertStatsActive => 'Aktiivsed';

  @override
  String get alertStatsToday => 'Täna';

  @override
  String get alertStatsThisWeek => 'Sel nädalal';

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
  String get nearestStations => 'Lahimad jaamad';

  @override
  String get nearestStationsHint =>
      'Leidke lahimad jaamad oma praeguse asukoha jargi';

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
}
