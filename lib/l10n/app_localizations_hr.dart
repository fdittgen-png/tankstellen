// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Cijene goriva';

  @override
  String get search => 'Pretraži';

  @override
  String get favorites => 'Favoriti';

  @override
  String get map => 'Karta';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Postavke';

  @override
  String get gpsLocation => 'GPS lokacija';

  @override
  String get zipCode => 'Poštanski broj';

  @override
  String get zipCodeHint => 'npr. 10000';

  @override
  String get fuelType => 'Gorivo';

  @override
  String get searchRadius => 'Radijus';

  @override
  String get searchNearby => 'Benzinske postaje u blizini';

  @override
  String get searchButton => 'Pretraži';

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
  String get noResults => 'Benzinske postaje nisu pronađene.';

  @override
  String get startSearch => 'Pretražite za pronalaženje benzinskih postaja.';

  @override
  String get open => 'Otvoreno';

  @override
  String get closed => 'Zatvoreno';

  @override
  String distance(String distance) {
    return '$distance daleko';
  }

  @override
  String get price => 'Cijena';

  @override
  String get prices => 'Cijene';

  @override
  String get address => 'Adresa';

  @override
  String get openingHours => 'Radno vrijeme';

  @override
  String get open24h => 'Otvoreno 24 sata';

  @override
  String get navigate => 'Navigiraj';

  @override
  String get retry => 'Pokušaj ponovo';

  @override
  String get apiKeySetup => 'API ključ';

  @override
  String get apiKeyDescription =>
      'Registrirajte se jednom za besplatni API ključ.';

  @override
  String get apiKeyLabel => 'API ključ';

  @override
  String get register => 'Registracija';

  @override
  String get continueButton => 'Nastavi';

  @override
  String get welcome => 'Cijene goriva';

  @override
  String get welcomeSubtitle => 'Pronađite najjeftinije gorivo u blizini.';

  @override
  String get profileName => 'Naziv profila';

  @override
  String get preferredFuel => 'Preferirano gorivo';

  @override
  String get defaultRadius => 'Zadani radijus';

  @override
  String get landingScreen => 'Početni zaslon';

  @override
  String get homeZip => 'Kućni poštanski broj';

  @override
  String get newProfile => 'Novi profil';

  @override
  String get editProfile => 'Uredi profil';

  @override
  String get save => 'Spremi';

  @override
  String get cancel => 'Odustani';

  @override
  String get delete => 'Obriši';

  @override
  String get activate => 'Aktiviraj';

  @override
  String get configured => 'Konfigurirano';

  @override
  String get notConfigured => 'Nije konfigurirano';

  @override
  String get about => 'O aplikaciji';

  @override
  String get openSource => 'Otvoreni kod (MIT licenca)';

  @override
  String get sourceCode => 'Izvorni kod na GitHubu';

  @override
  String get noFavorites => 'Nema favorita';

  @override
  String get noFavoritesHint =>
      'Dodirnite zvjezdicu na postaji da je spremite kao favorita.';

  @override
  String get language => 'Jezik';

  @override
  String get country => 'Država';

  @override
  String get demoMode => 'Demo način — prikazani primjeri podataka.';

  @override
  String get setupLiveData => 'Postavke za stvarne podatke';

  @override
  String get freeNoKey => 'Besplatno — ključ nije potreban';

  @override
  String get apiKeyRequired => 'Potreban API ključ';

  @override
  String get skipWithoutKey => 'Nastavi bez ključa';

  @override
  String get dataTransparency => 'Transparentnost podataka';

  @override
  String get storageAndCache => 'Pohrana i predmemorija';

  @override
  String get clearCache => 'Očisti predmemoriju';

  @override
  String get clearAllData => 'Obriši sve podatke';

  @override
  String get errorLog => 'Dnevnik grešaka';

  @override
  String stationsFound(int count) {
    return 'Pronađeno $count postaja';
  }

  @override
  String get whatIsShared => 'Što se dijeli — i s kim?';

  @override
  String get gpsCoordinates => 'GPS koordinate';

  @override
  String get gpsReason =>
      'Šalju se sa svakom pretragom za pronalaženje obližnjih postaja.';

  @override
  String get postalCodeData => 'Poštanski broj';

  @override
  String get postalReason => 'Pretvara se u koordinate putem geokodiranja.';

  @override
  String get mapViewport => 'Prikaz karte';

  @override
  String get mapReason =>
      'Pločice karte učitavaju se s poslužitelja. Osobni podaci se ne prenose.';

  @override
  String get apiKeyData => 'API ključ';

  @override
  String get apiKeyReason =>
      'Vaš osobni ključ šalje se sa svakim API zahtjevom. Povezan je s vašom e-poštom.';

  @override
  String get notShared => 'NE dijeli se:';

  @override
  String get searchHistory => 'Povijest pretraživanja';

  @override
  String get favoritesData => 'Favoriti';

  @override
  String get profileNames => 'Nazivi profila';

  @override
  String get homeZipData => 'Kućni poštanski broj';

  @override
  String get usageData => 'Podaci o korištenju';

  @override
  String get privacyBanner =>
      'Ova aplikacija nema poslužitelj. Svi podaci ostaju na vašem uređaju. Bez analitike, praćenja ili reklama.';

  @override
  String get storageUsage => 'Korištenje pohrane na ovom uređaju';

  @override
  String get settingsLabel => 'Postavke';

  @override
  String get profilesStored => 'spremljenih profila';

  @override
  String get stationsMarked => 'označenih postaja';

  @override
  String get cachedResponses => 'predmemoriranih odgovora';

  @override
  String get total => 'Ukupno';

  @override
  String get cacheManagement => 'Upravljanje predmemorijom';

  @override
  String get cacheDescription =>
      'Predmemorija pohranjuje API odgovore za brže učitavanje i offline pristup.';

  @override
  String get stationSearch => 'Pretraživanje postaja';

  @override
  String get stationDetails => 'Detalji postaje';

  @override
  String get priceQuery => 'Upit o cijeni';

  @override
  String get zipGeocoding => 'Geokodiranje poštanskog broja';

  @override
  String minutes(int n) {
    return '$n minuta';
  }

  @override
  String hours(int n) {
    return '$n sati';
  }

  @override
  String get clearCacheTitle => 'Očistiti predmemoriju?';

  @override
  String get clearCacheBody =>
      'Predmemorirani rezultati pretrage i cijene bit će obrisani. Profili, favoriti i postavke su sačuvani.';

  @override
  String get clearCacheButton => 'Očisti predmemoriju';

  @override
  String get deleteAllTitle => 'Obrisati sve podatke?';

  @override
  String get deleteAllBody =>
      'Ovo trajno briše sve profile, favorite, API ključ, postavke i predmemoriju. Aplikacija će se resetirati.';

  @override
  String get deleteAllButton => 'Obriši sve';

  @override
  String get entries => 'unosa';

  @override
  String get cacheEmpty => 'Predmemorija je prazna';

  @override
  String get noStorage => 'Nema korištene pohrane';

  @override
  String get apiKeyNote =>
      'Besplatna registracija. Podaci od vladinih agencija za transparentnost cijena.';

  @override
  String get apiKeyFormatError =>
      'Nevažeći format — očekivan UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Podržite ovaj projekt';

  @override
  String get supportDescription =>
      'Ova aplikacija je besplatna, otvorenog koda i bez reklama. Ako je smatrate korisnom, razmislite o podršci razvojnom programeru.';

  @override
  String get reportBug => 'Prijavi grešku / Predloži značajku';

  @override
  String get reportThisIssue => 'Report this issue';

  @override
  String get reportConsentTitle => 'Report to GitHub?';

  @override
  String get reportConsentBody =>
      'This will open a public GitHub issue with the error details below. No GPS coordinates, API keys, or personal data are included.';

  @override
  String get reportConsentConfirm => 'Open GitHub';

  @override
  String get reportConsentCancel => 'Cancel';

  @override
  String get configProfileSection => 'Profile';

  @override
  String get configActiveProfile => 'Active profile';

  @override
  String get configPreferredFuel => 'Preferred fuel';

  @override
  String get configCountry => 'Country';

  @override
  String get configRouteSegment => 'Route segment';

  @override
  String get configApiKeysSection => 'API keys';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API key';

  @override
  String get configApiKeyConfigured => 'Configured';

  @override
  String get configApiKeyNotSet => 'Not set (demo mode)';

  @override
  String get configApiKeyCommunity => 'Default (community key)';

  @override
  String get searchLocationPlaceholder => 'Address, postal code or city';

  @override
  String get configEvKey => 'EV charging API key';

  @override
  String get configEvKeyCustom => 'Custom key';

  @override
  String get configEvKeyShared => 'Default (shared)';

  @override
  String get configCloudSyncSection => 'Cloud Sync';

  @override
  String get configTankSyncConnected => 'Connected';

  @override
  String get configTankSyncDisabled => 'Disabled';

  @override
  String get configAuthMode => 'Auth mode';

  @override
  String get configAuthEmail => 'Email (persistent)';

  @override
  String get configAuthAnonymous => 'Anonymous (device-only)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Privacy summary';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favorites, alerts, and ignored stations are synced to your private database\n• GPS position and API keys never leave your device\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• All data is stored locally on this device only\n• No data is sent to any server\n• API keys encrypted in device secure storage';

  @override
  String get configAuthNoteEmail => 'Email account enables cross-device access';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymous account — data tied to this device';

  @override
  String get configNone => 'None';

  @override
  String get privacyPolicy => 'Pravila o privatnosti';

  @override
  String get fuels => 'Goriva';

  @override
  String get services => 'Usluge';

  @override
  String get zone => 'Zona';

  @override
  String get highway => 'Autocesta';

  @override
  String get localStation => 'Lokalna postaja';

  @override
  String get lastUpdate => 'Zadnje ažuriranje';

  @override
  String get automate24h => '24h/24 — Automat';

  @override
  String get refreshPrices => 'Osvježi cijene';

  @override
  String get station => 'Benzinska postaja';

  @override
  String get locationDenied =>
      'Dopuštenje lokacije odbijeno. Možete pretraživati po poštanskom broju.';

  @override
  String get demoModeBanner =>
      'Demo način. Konfigurirajte API ključ u postavkama.';

  @override
  String get sortDistance => 'Udaljenost';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'jeftino';

  @override
  String get expensive => 'skupo';

  @override
  String stationsOnMap(int count) {
    return '$count postaja';
  }

  @override
  String get loadingFavorites =>
      'Učitavanje favorita...\nNajprije pretražite postaje za spremanje podataka.';

  @override
  String get reportPrice => 'Prijavi cijenu';

  @override
  String get whatsWrong => 'Što nije u redu?';

  @override
  String get correctPrice => 'Ispravna cijena (npr. 1,459)';

  @override
  String get sendReport => 'Pošalji prijavu';

  @override
  String get reportSent => 'Prijava poslana. Hvala!';

  @override
  String get enterValidPrice => 'Unesite valjanu cijenu';

  @override
  String get cacheCleared => 'Predmemorija očišćena.';

  @override
  String get yourPosition => 'Vaša pozicija';

  @override
  String get positionUnknown => 'Pozicija nepoznata';

  @override
  String get distancesFromCenter => 'Udaljenosti od centra pretrage';

  @override
  String get autoUpdatePosition => 'Automatsko ažuriranje pozicije';

  @override
  String get autoUpdateDescription =>
      'Ažuriraj GPS poziciju prije svake pretrage';

  @override
  String get location => 'Lokacija';

  @override
  String get switchProfileTitle => 'Država promijenjena';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Sada ste u $country. Prebaciti na profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Prebačeno na profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Nema profila za ovu državu';

  @override
  String noProfileForCountry(String country) {
    return 'Nalazite se u $country, ali nema konfiguriranog profila. Izradite jedan u Postavkama.';
  }

  @override
  String get autoSwitchProfile => 'Automatska promjena profila';

  @override
  String get autoSwitchDescription =>
      'Automatski promijeni profil pri prelasku granice';

  @override
  String get switchProfile => 'Prebaci';

  @override
  String get dismiss => 'Zatvori';

  @override
  String get profileCountry => 'Država';

  @override
  String get profileLanguage => 'Jezik';

  @override
  String get settingsStorageDetail => 'API ključ, aktivni profil';

  @override
  String get allFuels => 'Sve';

  @override
  String get priceAlerts => 'Cjenovne obavijesti';

  @override
  String get noPriceAlerts => 'Nema cjenovnih obavijesti';

  @override
  String get noPriceAlertsHint =>
      'Izradite obavijest sa stranice detalja postaje.';

  @override
  String alertDeleted(String name) {
    return 'Obavijest \"$name\" obrisana';
  }

  @override
  String get createAlert => 'Izradi cjenovnu obavijest';

  @override
  String currentPrice(String price) {
    return 'Trenutna cijena: $price';
  }

  @override
  String get targetPrice => 'Ciljna cijena (EUR)';

  @override
  String get enterPrice => 'Unesite cijenu';

  @override
  String get invalidPrice => 'Nevažeća cijena';

  @override
  String get priceTooHigh => 'Cijena previsoka';

  @override
  String get create => 'Izradi';

  @override
  String get alertCreated => 'Cenovna obavijest izrađena';

  @override
  String get wrongE5Price => 'Pogrešna cijena Super E5';

  @override
  String get wrongE10Price => 'Pogrešna cijena Super E10';

  @override
  String get wrongDieselPrice => 'Pogrešna cijena dizela';

  @override
  String get wrongStatusOpen => 'Prikazano kao otvoreno, ali zatvoreno';

  @override
  String get wrongStatusClosed => 'Prikazano kao zatvoreno, ali otvoreno';

  @override
  String get searchAlongRouteLabel => 'Duž rute';

  @override
  String get searchEvStations => 'Pretraži stanice za punjenje';

  @override
  String get allStations => 'Sve postaje';

  @override
  String get bestStops => 'Najbolja zaustavljanja';

  @override
  String get openInMaps => 'Otvori u Kartama';

  @override
  String get noStationsAlongRoute => 'Postaje duž rute nisu pronađene';

  @override
  String get evOperational => 'U funkciji';

  @override
  String get evStatusUnknown => 'Status nepoznat';

  @override
  String evConnectors(int count) {
    return 'Priključci ($count točaka)';
  }

  @override
  String get evNoConnectors => 'Nema dostupnih detalja o priključcima';

  @override
  String get evUsageCost => 'Trošak korištenja';

  @override
  String get evPricingUnavailable => 'Cijena nije dostupna od pružatelja';

  @override
  String get evLastUpdated => 'Zadnje ažurirano';

  @override
  String get evUnknown => 'Nepoznato';

  @override
  String get evDataAttribution => 'Podaci iz OpenChargeMap (izvor zajednice)';

  @override
  String get evStatusDisclaimer =>
      'Status možda ne odražava dostupnost u stvarnom vremenu. Dodirnite osvježi za najnovije podatke.';

  @override
  String get evNavigateToStation => 'Navigiraj do postaje';

  @override
  String get evRefreshStatus => 'Osvježi status';

  @override
  String get evStatusUpdated => 'Status ažuriran';

  @override
  String get evStationNotFound =>
      'Nije moguće osvježiti — postaja nije pronađena u blizini';

  @override
  String get addedToFavorites => 'Dodano u favorite';

  @override
  String get removedFromFavorites => 'Uklonjeno iz favorita';

  @override
  String get addFavorite => 'Dodaj u favorite';

  @override
  String get removeFavorite => 'Ukloni iz favorita';

  @override
  String get currentLocation => 'Trenutna lokacija';

  @override
  String get gpsError => 'GPS greška';

  @override
  String get couldNotResolve => 'Nije moguće odrediti početak ili odredište';

  @override
  String get start => 'Početak';

  @override
  String get destination => 'Odredište';

  @override
  String get cityAddressOrGps => 'Grad, adresa ili GPS';

  @override
  String get cityOrAddress => 'Grad ili adresa';

  @override
  String get useGps => 'Koristi GPS';

  @override
  String get stop => 'Zaustavljanje';

  @override
  String stopN(int n) {
    return 'Zaustavljanje $n';
  }

  @override
  String get addStop => 'Dodaj zaustavljanje';

  @override
  String get searchAlongRoute => 'Pretraži duž rute';

  @override
  String get cheapest => 'Najjeftinija';

  @override
  String nStations(int count) {
    return '$count postaja';
  }

  @override
  String nBest(int count) {
    return '$count najboljih';
  }

  @override
  String get fuelPricesTankerkoenig => 'Cijene goriva (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Potrebno za pretraživanje cijena goriva u Njemačkoj';

  @override
  String get evChargingOpenChargeMap => 'EV punjenje (OpenChargeMap)';

  @override
  String get customKey => 'Prilagođeni ključ';

  @override
  String get appDefaultKey => 'Zadani ključ aplikacije';

  @override
  String get optionalOverrideKey =>
      'Neobavezno: zamijenite ugrađeni ključ svojim vlastitim';

  @override
  String get requiredForEvSearch =>
      'Potrebno za pretraživanje EV stanica za punjenje';

  @override
  String get edit => 'Uredi';

  @override
  String get fuelPricesApiKey => 'API ključ cijena goriva';

  @override
  String get tankerkoenigApiKey => 'API ključ Tankerkoenig';

  @override
  String get evChargingApiKey => 'API ključ EV punjenja';

  @override
  String get openChargeMapApiKey => 'API ključ OpenChargeMap';

  @override
  String get routeSegment => 'Segment rute';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Prikaži najjeftiniju postaju svakih $km km duž rute';
  }

  @override
  String get avoidHighways => 'Izbjegavaj autoceste';

  @override
  String get avoidHighwaysDesc =>
      'Izračun rute izbjegava cestarine i autoceste';

  @override
  String get showFuelStations => 'Prikaži benzinske postaje';

  @override
  String get showFuelStationsDesc => 'Uključi benzin, dizel, LPG, CNG postaje';

  @override
  String get showEvStations => 'Prikaži stanice za punjenje';

  @override
  String get showEvStationsDesc =>
      'Uključi električne stanice za punjenje u rezultatima';

  @override
  String get noStationsAlongThisRoute => 'Nisu pronađene postaje duž ove rute.';

  @override
  String get fuelCostCalculator => 'Kalkulator troškova goriva';

  @override
  String get distanceKm => 'Udaljenost (km)';

  @override
  String get consumptionL100km => 'Potrošnja (L/100km)';

  @override
  String get fuelPriceEurL => 'Cijena goriva (EUR/L)';

  @override
  String get tripCost => 'Trošak putovanja';

  @override
  String get fuelNeeded => 'Potrebno gorivo';

  @override
  String get totalCost => 'Ukupni trošak';

  @override
  String get enterCalcValues =>
      'Unesite udaljenost, potrošnju i cijenu za izračun troška putovanja';

  @override
  String get priceHistory => 'Povijest cijena';

  @override
  String get noPriceHistory => 'Još nema povijesti cijena';

  @override
  String get noHourlyData => 'Nema satnih podataka';

  @override
  String get noStatistics => 'Nema dostupnih statistika';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Pros';

  @override
  String get showAllFuelTypes => 'Prikaži sve vrste goriva';

  @override
  String get connected => 'Spojeno';

  @override
  String get notConnected => 'Nije spojeno';

  @override
  String get connectTankSync => 'Spoji TankSync';

  @override
  String get disconnectTankSync => 'Odspoji TankSync';

  @override
  String get viewMyData => 'Pogledaj moje podatke';

  @override
  String get optionalCloudSync =>
      'Neobavezna sinkronizacija u oblaku za obavijesti, favorite i push obavijesti';

  @override
  String get tapToUpdateGps => 'Dodirnite za ažuriranje GPS pozicije';

  @override
  String get gpsAutoUpdateHint =>
      'GPS pozicija se automatski dobiva pri pretrazi. Možete je ažurirati i ručno ovdje.';

  @override
  String get clearGpsConfirm =>
      'Obrisati spremljenu GPS poziciju? Možete je ažurirati ponovno u bilo kojem trenutku.';

  @override
  String get pageNotFound => 'Stranica nije pronađena';

  @override
  String get deleteAllServerData => 'Obriši sve podatke s poslužitelja';

  @override
  String get deleteServerDataConfirm => 'Obrisati sve podatke s poslužitelja?';

  @override
  String get deleteEverything => 'Obriši sve';

  @override
  String get allDataDeleted => 'Svi podaci s poslužitelja obrisani';

  @override
  String get disconnectConfirm => 'Odspojiti TankSync?';

  @override
  String get disconnect => 'Odspoji';

  @override
  String get myServerData => 'Moji podaci na poslužitelju';

  @override
  String get anonymousUuid => 'Anonimni UUID';

  @override
  String get server => 'Poslužitelj';

  @override
  String get syncedData => 'Sinkronizirani podaci';

  @override
  String get pushTokens => 'Push tokeni';

  @override
  String get priceReports => 'Prijave cijena';

  @override
  String get totalItems => 'Ukupno stavki';

  @override
  String get estimatedSize => 'Procijenjena veličina';

  @override
  String get viewRawJson => 'Pogledaj neobrađene podatke kao JSON';

  @override
  String get exportJson => 'Izvezi kao JSON (međuspremnik)';

  @override
  String get jsonCopied => 'JSON kopiran u međuspremnik';

  @override
  String get rawDataJson => 'Neobrađeni podaci (JSON)';

  @override
  String get close => 'Zatvori';

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
  String get alertStatsActive => 'Aktivne';

  @override
  String get alertStatsToday => 'Danas';

  @override
  String get alertStatsThisWeek => 'Ovaj tjedan';

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
  String get paymentMethods => 'Payment methods';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Fuel Card';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Pay with $app';
  }

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
  String get nearestStations => 'Najblize postaje';

  @override
  String get nearestStationsHint =>
      'Pronadite najblize postaje pomocu vase trenutne lokacije';

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
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get evConnectorsLabel => 'Available connectors';

  @override
  String get evConnectorsNone => 'No connector information';

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

  @override
  String get vehicleSetActive => 'Set active';

  @override
  String get swipeHide => 'Hide';

  @override
  String get evChargingSection => 'EV Charging';

  @override
  String get fuelStationsSection => 'Fuel Stations';

  @override
  String get yourRating => 'Your rating';

  @override
  String get noStorageUsed => 'No storage used';

  @override
  String get aboutReportBug => 'Report a bug / Suggest a feature';

  @override
  String get aboutSupportProject => 'Support this project';

  @override
  String get aboutSupportDescription =>
      'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.';
}
