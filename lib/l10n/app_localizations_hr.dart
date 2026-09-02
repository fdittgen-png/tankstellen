// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabRunSearch => 'Pokreni pretraživanje';

  @override
  String get routeSearchingChip => 'Pretraživanje rute…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Svakih $km km';
  }

  @override
  String get searchCriteriaTitle => 'Kriteriji pretraživanja';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'U polumjeru $km km';
  }

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
  String get apiKeyLabel => 'API ključ';

  @override
  String get register => 'Registracija';

  @override
  String get continueButton => 'Nastavi';

  @override
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Promjena države?';

  @override
  String countryChangeBody(String country) {
    return 'Prelaskom na $country mijenjaju se:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Udaljenost';

  @override
  String get countryChangeVolume => 'Volumen';

  @override
  String get countryChangePricePerUnit => 'Format cijene';

  @override
  String get countryChangeNote =>
      'Postojeće oznake i evidencija punjenja neće biti prepravljena; samo novi unosi koriste nove jedinice.';

  @override
  String get countryChangeConfirm => 'Promijeni';

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
  String get freeNoKey => 'Besplatno — ključ nije potreban';

  @override
  String get apiKeyRequired => 'Potreban API ključ';

  @override
  String get dataTransparency => 'Transparentnost podataka';

  @override
  String get clearCache => 'Očisti predmemoriju';

  @override
  String stationsFound(int count) {
    return 'Pronađeno $count postaja';
  }

  @override
  String get storageUsage => 'Korištenje pohrane na ovom uređaju';

  @override
  String get settingsLabel => 'Postavke';

  @override
  String get total => 'Ukupno';

  @override
  String get cacheDescription =>
      'Predmemorija pohranjuje API odgovore za brže učitavanje i offline pristup.';

  @override
  String get cacheTtlGroupNetwork => 'Mreža';

  @override
  String get cacheTtlGroupData => 'Podaci';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodiranje';

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
  String get deleteAllButton => 'Obriši sve';

  @override
  String get cacheEmpty => 'Predmemorija je prazna';

  @override
  String get apiKeyNote =>
      'Besplatna registracija. Podaci od vladinih agencija za transparentnost cijena.';

  @override
  String get apiKeyFormatError =>
      'Nevažeći format — očekivan UUID (8-4-4-4-12)';

  @override
  String get reportThisIssue => 'Prijavi ovaj problem';

  @override
  String get reportAlreadySent => 'Već ste prijavili ovaj problem.';

  @override
  String get reportConsentTitle => 'Prijaviti na GitHub?';

  @override
  String get reportConsentBody =>
      'Ovo će otvoriti javnu GitHub prijavu s pojedinostima greške navedenim ispod. Koordinate GPS-a, API ključevi ni osobni podaci neće biti uključeni.';

  @override
  String get reportConsentConfirm => 'Otvori GitHub';

  @override
  String get reportConsentCancel => 'Odustani';

  @override
  String get searchLocationPlaceholder => 'Adresa, poštanski broj ili grad';

  @override
  String get configTankSyncConnected => 'Spojeno';

  @override
  String get configTankSyncDisabled => 'Onemogućeno';

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
  String get demoModeBannerAction => 'Dohvati stvarne cijene';

  @override
  String get sortDistance => 'Udaljenost';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Ocjena';

  @override
  String get sortPriceDistance => 'Cijena/km';

  @override
  String get cheap => 'jeftino';

  @override
  String get expensive => 'skupo';

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
  String profileSwitchedTo(String profile) {
    return 'Prebačeno na $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name stvoren';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Profil za $country već postoji — umjesto toga uredite ga.';
  }

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
  String get evPriceFree => 'Besplatno';

  @override
  String get evPricePayAtLocation => 'Plaćanje na lokaciji';

  @override
  String get evPriceMembership => 'Potrebno članstvo';

  @override
  String get evPriceIndicative => 'Indikativna cijena';

  @override
  String get evPriceDeclaredByOperator =>
      'Indikativna cijena koju je naveo operater — provjerite na licu mjesta';

  @override
  String get evPriceFranceAttribution =>
      'Cijene: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Cijene po najboljoj mogućnosti iz OpenChargeMap — nepotpune i mogu biti neprecizne.';

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
  String get edit => 'Uredi';

  @override
  String get fuelPricesApiKey => 'API ključ cijena goriva';

  @override
  String get evChargingApiKey => 'API ključ EV punjenja';

  @override
  String get openChargeMapApiKey => 'API ključ OpenChargeMap';

  @override
  String get routePlanningSection => 'Planiranje rute';

  @override
  String get routeMinSaving => 'Minimalna ušteda';

  @override
  String get routeMinSavingOff => 'Isključeno';

  @override
  String get routeMinSavingOffCaption =>
      'Prikazuju se sve postaje pronađene uz rutu';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Samo postaje unutar $amount od najjeftinije na ruti';
  }

  @override
  String get routeDetourBudget => 'Maksimalni obilazak';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Prikaži postaje do $km km od izravne rute';
  }

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
  String get noStationsAlongThisRoute => 'Nisu pronađene postaje duž ove rute.';

  @override
  String get fuelCostCalculator => 'Kalkulator troškova goriva';

  @override
  String get distanceKm => 'Udaljenost (km)';

  @override
  String get tripCost => 'Trošak putovanja';

  @override
  String get fuelNeeded => 'Potrebno gorivo';

  @override
  String get totalCost => 'Ukupni trošak';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Udaljenost ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Potrošnja ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Cijena goriva ($unit)';
  }

  @override
  String get calculatorUseMine => 'Upotrijebi';

  @override
  String get calculatorApplied => 'Primijenjeno';

  @override
  String get tripDetails => 'Detalji puta';

  @override
  String get calculatorRoundTrip => 'Povratno putovanje';

  @override
  String get roundTripTotal => 'Povratno putovanje';

  @override
  String get costPerDistance => 'Trošak po km';

  @override
  String get costPerMonth => 'Trošak po mjesecu';

  @override
  String get calculatorEstimateMonthly => 'Procijeni mjesečni trošak';

  @override
  String get calculatorTripsPerMonth => 'Putova po mjesecu';

  @override
  String get calculatorTripsPerMonthHint => 'npr. 20';

  @override
  String get calculatorReset => 'Poništi';

  @override
  String get calculatorResultPlaceholder =>
      'Unesite udaljenost, potrošnju i cijenu da biste vidjeli trošak puta';

  @override
  String get priceHistory => 'Povijest cijena';

  @override
  String get favoritesDataCache => 'Podaci favorita';

  @override
  String get citySearchCache => 'Pretraga gradova';

  @override
  String get noPriceHistory => 'Još nema povijesti cijena';

  @override
  String get noStatistics => 'Nema dostupnih statistika';

  @override
  String get showAllFuelTypes => 'Prikaži sve vrste goriva';

  @override
  String get connected => 'Spojeno';

  @override
  String get disconnectTankSync => 'Odspoji TankSync';

  @override
  String get viewMyData => 'Pogledaj moje podatke';

  @override
  String get deleteAllServerData => 'Obriši sve podatke s poslužitelja';

  @override
  String get deleteServerDataConfirm => 'Obrisati sve podatke s poslužitelja?';

  @override
  String get deleteEverything => 'Obriši sve';

  @override
  String get allDataDeleted => 'Svi podaci s poslužitelja obrisani';

  @override
  String get forgetAllSyncedTripsButton => 'Zaboravi sve sinkronizirane vožnje';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Zaboraviti sve sinkronizirane vožnje?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Svaki sažetak vožnje i detalji bit će uklonjeni s poslužitelja. Lokalna povijest vožnji na ovom uređaju neće biti zahvaćena.\n\nOva se radnja ne može poništiti.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Zaboravi sve';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Sve sinkronizirane vožnje uklonjene s poslužitelja';

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
  String get syncedTrips => 'Putovanja';

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
  String get account => 'Račun';

  @override
  String get continueAsGuest => 'Nastavi kao gost';

  @override
  String get createAccount => 'Stvori račun';

  @override
  String get signIn => 'Prijava';

  @override
  String get savedRoutes => 'Spremljene rute';

  @override
  String get noSavedRoutes => 'Nema spremljenih ruta';

  @override
  String get noSavedRoutesHint =>
      'Pretražite duž rute i spremite je za brzi pristup kasnije.';

  @override
  String get saveRoute => 'Spremi rutu';

  @override
  String get routeName => 'Naziv rute';

  @override
  String itineraryDeleted(String name) {
    return '$name obrisano';
  }

  @override
  String loadingRoute(String name) {
    return 'Učitavanje rute: $name';
  }

  @override
  String get refreshFailed => 'Osvježavanje nije uspjelo. Pokušajte ponovo.';

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
      'Postavite aplikaciju u nekoliko brzih koraka.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrirajte se za besplatni API ključ ili preskočite za istraživanje aplikacije s demo podacima.';

  @override
  String get onboardingComplete => 'Sve je spremno!';

  @override
  String get onboardingCompleteHint =>
      'Ove postavke možete promijeniti u bilo kojem trenutku u svom profilu.';

  @override
  String get onboardingBack => 'Natrag';

  @override
  String get onboardingNext => 'Dalje';

  @override
  String get onboardingSkip => 'Preskoči';

  @override
  String get onboardingFinish => 'Počni';

  @override
  String get switchToAllPricesView => 'Prebaci na prikaz svih cijena';

  @override
  String get switchToCompactView => 'Prebaci na kompaktni prikaz';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'Nema na zalihi';

  @override
  String get gdprTitle => 'Vaša privatnost';

  @override
  String get gdprSubtitle =>
      'Ova aplikacija poštuje vašu privatnost. Odaberite koje podatke želite dijeliti. Ove postavke možete promijeniti u bilo kojem trenutku.';

  @override
  String get gdprLocationTitle => 'Pristup lokaciji';

  @override
  String get gdprLocationDescription =>
      'Vaše koordinate šalju se API-ju za cijene goriva kako bi se pronašle obližnje postaje. Podaci o lokaciji nikada se ne pohranjuju na serveru i ne koriste se za praćenje.';

  @override
  String get gdprLocationShort =>
      'Pronađi obližnje benzinske postaje koristeći vašu lokaciju';

  @override
  String get gdprErrorReportingTitle => 'Prijava grešaka';

  @override
  String get gdprErrorReportingDescription =>
      'Anonimna izvješća o rušenju pomažu poboljšati aplikaciju. Osobni podaci nisu uključeni. Izvješća se šalju putem Sentry samo kada je konfigurirano.';

  @override
  String get gdprErrorReportingShort =>
      'Pošalji anonimna izvješća o rušenju za poboljšanje aplikacije';

  @override
  String get gdprCloudSyncTitle => 'Sinkronizacija u oblaku';

  @override
  String get gdprCloudSyncDescription =>
      'Sinkronizirajte favorite i upozorenja na svim uređajima putem TankSync. Koristi anonimnu autentifikaciju. Vaši podaci su šifrirani u prijenosu.';

  @override
  String get gdprCloudSyncShort =>
      'Sinkroniziraj favorite i upozorenja na svim uređajima';

  @override
  String get gdprLegalBasis =>
      'Pravna osnova: čl. 6(1)(a) GDPR (Pristanak). Pristanak možete povući u bilo kojem trenutku u Postavkama.';

  @override
  String get gdprContinueAll => 'Nastavi sa svime';

  @override
  String get gdprContinueSelected => 'Nastavi s odabranim';

  @override
  String get gdprSettingsHint =>
      'Možete promijeniti svoje odluke o privatnosti u bilo kojem trenutku.';

  @override
  String get routeSaved => 'Ruta spremljena!';

  @override
  String get routeSaveFailed => 'Spremanje rute nije uspjelo';

  @override
  String get sqlCopied => 'SQL kopiran u međuspremnik';

  @override
  String get connectionDataCopied => 'Podaci o povezivanju kopirani';

  @override
  String get accountDeleted => 'Račun obrisan. Lokalni podaci sačuvani.';

  @override
  String get switchedToAnonymous => 'Prebačeno na anonimnu sesiju';

  @override
  String failedToSwitch(String error) {
    return 'Prebacivanje nije uspjelo: $error';
  }

  @override
  String get connectedAsGuest => 'Spojeni kao gost';

  @override
  String get accountCreated => 'Račun stvoren!';

  @override
  String get signedIn => 'Prijavljeni!';

  @override
  String stationHidden(String name) {
    return '$name skrivena';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name uklonjena iz favorita';
  }

  @override
  String invalidApiKey(String error) {
    return 'Nevažeći API ključ: $error';
  }

  @override
  String get invalidQrCode => 'Nevažeći format QR koda';

  @override
  String get invalidQrCodeTankSync =>
      'Nevažeći QR kod — očekivani TankSync format';

  @override
  String get tankSyncConnected => 'TankSync spojen!';

  @override
  String get syncCompleted => 'Sinkronizacija završena — podaci osvježeni';

  @override
  String get deviceCodeCopied => 'Kôd uređaja kopiran';

  @override
  String get undo => 'Poništi';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Unesite valjani $length-znamenkasti $label';
  }

  @override
  String get freshnessAgo => 'prije';

  @override
  String get freshnessStale => 'Zastarjelo';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Svježina podataka: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand logo';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ocijeni $count zvjezdice',
      one: 'Ocijeni 1 zvjezdicom',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Slaba';

  @override
  String get passwordStrengthFair => 'Srednja';

  @override
  String get passwordStrengthStrong => 'Jaka';

  @override
  String get passwordReqMinLength => 'Najmanje 8 znakova';

  @override
  String get passwordReqUppercase => 'Najmanje 1 veliko slovo';

  @override
  String get passwordReqLowercase => 'Najmanje 1 malo slovo';

  @override
  String get passwordReqDigit => 'Najmanje 1 broj';

  @override
  String get passwordReqSpecial => 'Najmanje 1 poseban znak';

  @override
  String get passwordTooWeak => 'Lozinka ne ispunjava sve zahtjeve';

  @override
  String get brandFilterAll => 'Sve';

  @override
  String get brandFilterNoHighway => 'Bez autoceste';

  @override
  String get swipeTutorialMessage =>
      'Povucite desno za navigaciju, povucite lijevo za uklanjanje';

  @override
  String get swipeTutorialDismiss => 'Razumijem';

  @override
  String get alertStatsActive => 'Aktivne';

  @override
  String get alertStatsToday => 'Danas';

  @override
  String get alertStatsThisWeek => 'Ovaj tjedan';

  @override
  String get privacyLocalData => 'Podaci na ovom uređaju';

  @override
  String get privacyIgnoredStations => 'Ignorirane postaje';

  @override
  String get privacyRatings => 'Ocjene postaja';

  @override
  String get privacyPriceHistory => 'Postaje s poviješću cijena';

  @override
  String get privacyProfiles => 'Profili pretraživanja';

  @override
  String get privacyItineraries => 'Spremljene rute';

  @override
  String get privacySyncMode => 'Način sinkronizacije';

  @override
  String get privacySyncUserId => 'ID korisnika';

  @override
  String get privacySyncDescription =>
      'Kada je sinkronizacija omogućena, favoriti, upozorenja, ignorirane postaje i ocjene pohranjuju se i na TankSync serveru.';

  @override
  String get privacyExportSuccess => 'Podaci izvezeni u međuspremnik';

  @override
  String get privacyExportCsvSuccess => 'CSV podaci izvezeni u međuspremnik';

  @override
  String get savedToDownloadsFolder => 'Spremljeno u mapu Preuzimanja';

  @override
  String get privacyErrorLogCleared => 'Zapisnik pogrešaka očišćen';

  @override
  String get privacyDeleteTitle => 'Obrisati sve podatke?';

  @override
  String get privacyDeleteBody =>
      'Ovo će trajno obrisati:\n\n- Sve favorite i podatke o postajama\n- Sve profile pretraživanja\n- Sva upozorenja o cijenama\n- Cjelokupnu povijest cijena\n- Sve predmemorirane podatke\n- Vaš API ključ\n- Sve postavke aplikacije\n\nAplikacija će se resetirati na početno stanje. Ova se radnja ne može poništiti.';

  @override
  String get privacyDeleteConfirm => 'Obriši sve';

  @override
  String get yes => 'Da';

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
  String get paymentMethods => 'Načini plaćanja';

  @override
  String get paymentMethodCash => 'Gotovina';

  @override
  String get paymentMethodCard => 'Kartica';

  @override
  String get paymentMethodContactless => 'Beskontaktno';

  @override
  String get paymentMethodFuelCard => 'Kartica za gorivo';

  @override
  String get paymentMethodApp => 'Aplikacija';

  @override
  String payWithApp(String app) {
    return 'Plati s $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'U usporedbi s tekućim prosjekom vaših posljednjih 3 punjenja ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Potrošnja $value L/100 km, $delta u odnosu na vaš tekući prosjek';
  }

  @override
  String get drivingMode => 'Način vožnje';

  @override
  String get drivingExit => 'Izlaz';

  @override
  String get drivingNearestStation => 'Najbliža';

  @override
  String get drivingTapToUnlock => 'Dodirnite za otključavanje';

  @override
  String get drivingSafetyTitle => 'Sigurnosna napomena';

  @override
  String get drivingSafetyMessage =>
      'Ne upravljajte aplikacijom za vrijeme vožnje. Zaustavite se na sigurnom mjestu prije interakcije s ekranom. Vozač je u svakom trenutku odgovoran za sigurno upravljanje vozilom.';

  @override
  String get drivingSafetyAccept => 'Razumijem';

  @override
  String get voiceAnnouncementsTitle => 'Glasovne najave';

  @override
  String get voiceAnnouncementsDescription =>
      'Najava obližnjih jeftinih postaja za vrijeme vožnje';

  @override
  String get voiceAnnouncementsEnabled => 'Omogući glasovne najave';

  @override
  String get voiceAnnouncementProximityRadius => 'Polumjer najava';

  @override
  String get voiceAnnouncementCooldown => 'Interval ponavljanja';

  @override
  String get voiceAnnouncementPriceLimit => 'Najviša cijena';

  @override
  String get consumptionStatsTitle => 'Statistika potrošnje';

  @override
  String get addFillUp => 'Dodaj punjenje';

  @override
  String get noFillUpsTitle => 'Još nema punjenja';

  @override
  String get noFillUpsSubtitle =>
      'Unesite prvo punjenje za početak praćenja potrošnje.';

  @override
  String get fillUpDate => 'Datum';

  @override
  String get liters => 'Litri';

  @override
  String get odometerKm => 'Kilometar-sat (km)';

  @override
  String get notesOptional => 'Napomene (neobavezno)';

  @override
  String get statAvgConsumption => 'Prosj. L/100km';

  @override
  String get statAvgCostPerKm => 'Prosj. trošak/km';

  @override
  String get statTotalLiters => 'Ukupno litara';

  @override
  String get statTotalSpent => 'Ukupno potrošeno';

  @override
  String get statFillUpCount => 'Punjenja';

  @override
  String get fieldRequired => 'Obavezno';

  @override
  String get fieldInvalidNumber => 'Nevažeći broj';

  @override
  String get carbonDashboardTitle => 'CO2 nadzorna ploča';

  @override
  String get carbonEmptyTitle => 'Još nema podataka';

  @override
  String get carbonEmptySubtitle =>
      'Unesite punjenja za pregled CO2 nadzorne ploče.';

  @override
  String get carbonSummaryTotalCost => 'Ukupni trošak';

  @override
  String get carbonSummaryTotalCo2 => 'Ukupni CO2';

  @override
  String get monthlyCostsTitle => 'Mjesečni troškovi';

  @override
  String get monthlyEmissionsTitle => 'Mjesečne CO2 emisije';

  @override
  String get vehiclesTitle => 'Moja vozila';

  @override
  String get vehiclesMenuTitle => 'Moja vozila';

  @override
  String get vehiclesMenuSubtitle => 'Baterija, priključci, postavke punjenja';

  @override
  String get vehiclesEmptyMessage =>
      'Dodajte svoje vozilo za filtriranje prema priključku i procjenu troška punjenja.';

  @override
  String get vehiclesWizardTitle => 'Moja vozila (neobavezno)';

  @override
  String get vehiclesWizardSubtitle =>
      'Dodajte vozilo za prethodno popunjavanje evidencije potrošnje i omogućavanje filtera EV priključaka. Možete preskočiti i dodati vozila kasnije.';

  @override
  String get vehiclesWizardNoneYet => 'Još nije konfigurirano nijedno vozilo.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vozila',
      one: '1 vozilo',
    );
    return 'Imate $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Preskoči za završetak postavljanja — vozila možete dodati u bilo kojem trenutku iz Postavki.';

  @override
  String get fillUpVehicleLabel => 'Vozilo';

  @override
  String get fillUpVehicleRequired => 'Vozilo je obavezno';

  @override
  String get reportScanError => 'Prijavi grešku skeniranja';

  @override
  String get pickStationTitle => 'Odaberite postaju';

  @override
  String get pickStationHelper =>
      'Pokrenite punjenje s poznate postaje kako bi se automatski popunili cijena, brand i vrsta goriva.';

  @override
  String get pickStationEmpty =>
      'Još nema omiljenih postaja — dodajte ih iz Pretraživanja ili Favorita, ili preskočite i ispunite ručno.';

  @override
  String get pickStationSkip => 'Preskoči — dodaj bez postaje';

  @override
  String get scanPayment => 'Skeniraj QR za plaćanje';

  @override
  String get qrPaymentBeneficiary => 'Primatelj';

  @override
  String get qrPaymentAmount => 'Iznos';

  @override
  String get qrPaymentEpcTitle => 'SEPA plaćanje';

  @override
  String get qrPaymentEpcEmpty => 'Nema dekodiranih polja';

  @override
  String get qrPaymentOpenInBank => 'Otvori u bankovnoj aplikaciji';

  @override
  String get qrPaymentLaunchFailed => 'Nema aplikacije za otvaranje ovog koda';

  @override
  String get qrPaymentUnknownTitle => 'Neprepoznat kod';

  @override
  String get qrPaymentCopyRaw => 'Kopiraj neformatiran tekst';

  @override
  String get qrPaymentCopiedRaw => 'Kopirano u međuspremnik';

  @override
  String get qrPaymentReport => 'Prijavi ovo skeniranje';

  @override
  String get qrPaymentEpcCopied =>
      'Bankovni podaci kopirani — zalijepite u svoju bankovnu aplikaciju';

  @override
  String get qrScannerGuidance => 'Usmjerite kameru prema QR kodu';

  @override
  String get qrScannerPermissionDenied =>
      'Za skeniranje QR kodova potreban je pristup kameri.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Pristup kameri je odbijen. Otvorite postavke za odobrenje.';

  @override
  String get qrScannerRetryPermission => 'Pokušaj ponovo';

  @override
  String get qrScannerOpenSettings => 'Otvori postavke';

  @override
  String get qrScannerTimeout =>
      'Nije otkriven QR kod. Približite se ili pokušajte ponovo.';

  @override
  String get qrScannerRetry => 'Pokušaj ponovo';

  @override
  String get torchOn => 'Uključi bljeskalicu';

  @override
  String get torchOff => 'Isključi bljeskalicu';

  @override
  String get obdPermissionDenied =>
      'Odobrite Bluetooth dozvolu u sistemskim postavkama';

  @override
  String get obdPickerTitle => 'Odaberite OBD2 adapter';

  @override
  String get obdPickerScanning => 'Traženje adaptera…';

  @override
  String get obdPickerConnecting => 'Spajanje…';

  @override
  String get tripSummaryTitle => 'Sažetak vožnje';

  @override
  String get tripMetricDistance => 'Udaljenost';

  @override
  String get tripMetricFuelUsed => 'Potrošeno gorivo';

  @override
  String get tripMetricAvgConsumption => 'Prosj.';

  @override
  String get tripMetricElapsed => 'Proteklo';

  @override
  String get tripMetricOdometer => 'Kilometar-sat';

  @override
  String get tripStop => 'Zaustavi snimanje';

  @override
  String get tripPause => 'Pauziraj';

  @override
  String get tripResume => 'Nastavi';

  @override
  String get tripBannerRecording => 'Snimanje vožnje';

  @override
  String get tripBannerPaused => 'Vožnja pauzirana — dodirnite za nastavak';

  @override
  String get vehicleBaselineSectionTitle => 'Osnovna kalibracija';

  @override
  String get vehicleBaselineEmpty =>
      'Još nema uzoraka — pokrenite OBD2 vožnju za početak učenja profila goriva ovog vozila.';

  @override
  String get vehicleBaselineProgress =>
      'Naučeno iz uzoraka u raznim situacijama vožnje.';

  @override
  String get vehicleBaselineReset => 'Resetiraj osnovu situacija vožnje';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Resetirati osnovu situacija vožnje?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Ovo briše sve naučene uzorke za ovo vozilo. Vraćate se na zadane vrijednosti hladnog starta dok novi putovi ne popune profil.';

  @override
  String get vehicleBaselineShowDetails => 'Prikaži razčlambu po situacijama';

  @override
  String get vehicleBaselineHideDetails => 'Sakrij razčlambu po situacijama';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Još nije otkriveno: $situations. Ove situacije vožnje još imaju 0 uzoraka, pa je osnovna linija nepotpuna.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Nema uparen adapter. Uparite ga kako bi se aplikacija automatski ponovo spojila.';

  @override
  String get vehicleAdapterUnnamed => 'Nepoznat adapter';

  @override
  String get vehicleAdapterPair => 'Upari adapter';

  @override
  String get vehicleAdapterForget => 'Zaboravi adapter';

  @override
  String get achievementsTitle => 'Dostignuća';

  @override
  String get achievementFirstTrip => 'Prva vožnja';

  @override
  String get achievementFirstTripDesc => 'Snimite svoju prvu OBD2 vožnju.';

  @override
  String get achievementFirstFillUp => 'Prvo punjenje';

  @override
  String get achievementFirstFillUpDesc => 'Unesite svoje prvo punjenje.';

  @override
  String get achievementTenTrips => '10 vožnji';

  @override
  String get achievementTenTripsDesc => 'Snimite 10 OBD2 vožnji.';

  @override
  String get achievementZeroHarsh => 'Miran vozač';

  @override
  String get achievementZeroHarshDesc =>
      'Završite vožnju od 10 km ili više bez naglih kočenja ili ubrzanja.';

  @override
  String get achievementEcoWeek => 'Eko tjedan';

  @override
  String get achievementEcoWeekDesc =>
      'Vozite 7 uzastopnih dana s barem jednom mirnom vožnjom svaki dan.';

  @override
  String get achievementPriceWin => 'Pobjednička cijena';

  @override
  String get achievementPriceWinDesc =>
      'Unesite punjenje koje je za 5 % ili više niže od 30-dnevnog prosjeka postaje.';

  @override
  String get syncBaselinesToggleTitle => 'Dijeli naučene profile vozila';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Učitajte osnove potrošnje po vozilu kako bi ih drugi uređaj mogao koristiti.';

  @override
  String get obd2StatusConnected => 'OBD2 adapter: spojen';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: potrebna Bluetooth dozvola';

  @override
  String get obd2StatusConnectedBody => 'Spreman za snimanje vožnje.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Odobrite Bluetooth dozvolu u sistemskim postavkama za automatsko ponovno spajanje.';

  @override
  String get obd2StatusNoAdapter => 'Nema uparenog adaptera';

  @override
  String get obd2StatusForget => 'Zaboravi adapter';

  @override
  String get tripHistoryTitle => 'Povijest vožnji';

  @override
  String get tripHistoryEmptyTitle => 'Još nema vožnji';

  @override
  String get tripHistoryUnknownDate => 'Nepoznat datum';

  @override
  String get situationIdle => 'Mirovanje';

  @override
  String get situationStopAndGo => 'Zaustavljanje i kretanje';

  @override
  String get situationUrban => 'Urbano';

  @override
  String get situationHighway => 'Autocesta';

  @override
  String get situationDecel => 'Usporavanje';

  @override
  String get situationClimbing => 'Uspinjanje / opterećenje';

  @override
  String get situationColdStart => 'Hladan start';

  @override
  String get situationSustainedLoad => 'Trajno opterećenje / vuča';

  @override
  String get situationPartialDecel => 'Klizanje inercijom';

  @override
  String get situationHardAccel => 'Naglo ubrzanje';

  @override
  String get situationFuelCut => 'Isključenje goriva — klizanje';

  @override
  String get tripSaveRecording => 'Spremi vožnju';

  @override
  String get tripSummaryAutoSaved => 'Vožnja automatski spremljena';

  @override
  String get tripSummaryDone => 'Gotovo';

  @override
  String get tripSummaryDelete => 'Izbriši ovu vožnju';

  @override
  String get vehicleFuelNotSet => 'Nije postavljeno';

  @override
  String get wizardVehicleDefaultBadge => 'Zadano';

  @override
  String get wizardProfileChoiceHint =>
      'Odaberite kako želite koristiti aplikaciju. To možete promijeniti kasnije u Postavkama.';

  @override
  String get wizardProfileChoiceFooter =>
      'Svoju izbor možete promijeniti u bilo kojem trenutku iz Postavki → Način korištenja.';

  @override
  String get wizardProfileBasicName => 'Osnovno';

  @override
  String get wizardProfileBasicDescription =>
      'Najjeftinije gorivo i EV punionice u blizini. Favoriti i upozorenja na cijene.';

  @override
  String get wizardProfileMediumName => 'Srednje';

  @override
  String get wizardProfileMediumDescription =>
      'Sve iz Osnovnog, plus ručno praćenje punjenja goriva i EV punjenja.';

  @override
  String get wizardProfileFullName => 'Potpuno';

  @override
  String get wizardProfileFullDescription =>
      'Sve iz Srednjeg, plus automatsko OBD2 snimanje vožnji, ocjene vožnje i kartice lojalnosti.';

  @override
  String get wizardProfileCustomName => 'Prilagođeno';

  @override
  String get useModeSectionHint =>
      'Prilagodite aplikaciju načinu na koji je stvarno koristite. Odabirom unaprijed postavljenog profila omogućuju se odgovarajuće značajke.';

  @override
  String get useModeCustomSettingsDescription =>
      'Vaša kombinacija značajki ne odgovara nijednom unaprijed postavljenom profilu. Odaberite jedan gore za prepisivanje ili nastavite prilagođavati pojedinačne značajke u odjeljku ispod.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Način korištenja postavljen na $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Zadano vozilo (neobavezno)';

  @override
  String get profileDefaultVehicleNone => 'Bez zadanog';

  @override
  String get profileFuelFromVehicleHint =>
      'Vrsta goriva izvodi se iz vašeg zadanog vozila. Uklonite vozilo za izravni odabir goriva.';

  @override
  String get consumptionNoVehicleTitle => 'Prvo dodajte vozilo';

  @override
  String get consumptionNoVehicleBody =>
      'Punjenja se pripisuju vozilu. Dodajte svoje vozilo za početak bilježenja potrošnje.';

  @override
  String get vehicleAdd => 'Dodaj vozilo';

  @override
  String get vehicleAddTitle => 'Dodaj vozilo';

  @override
  String get vehicleEditTitle => 'Uredi vozilo';

  @override
  String get vehicleDeleteTitle => 'Obrisati vozilo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Ukloniti \"$name\" iz vaših profila?';
  }

  @override
  String get vehicleNameLabel => 'Naziv';

  @override
  String get vehicleNameHint => 'npr. Moj Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Benzinski/dizelski';

  @override
  String get vehicleTypeHybrid => 'Hibrid';

  @override
  String get vehicleTypeEv => 'Električni';

  @override
  String get vehicleEvSectionTitle => 'Električni';

  @override
  String get vehicleCombustionSectionTitle => 'Motor s unutarnjim izgaranjem';

  @override
  String get vehicleBatteryLabel => 'Kapacitet baterije (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maksimalna snaga punjenja (kW)';

  @override
  String get vehicleConnectorsLabel => 'Podržani priključci';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Kapacitet spremnika (L)';

  @override
  String get vehiclePowerLabel => 'Snaga motora (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps KS';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Željeno gorivo';

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
  String get connectorThreePin => '3-pinski';

  @override
  String get evShowOnMap => 'Prikaži EV postaje';

  @override
  String get evAvailableOnly => 'Samo dostupne';

  @override
  String get evMinPower => 'Min snaga';

  @override
  String get evStatusAvailable => 'Dostupno';

  @override
  String get evStatusOccupied => 'Zauzeto';

  @override
  String get evStatusOutOfOrder => 'Izvan pogona';

  @override
  String get evStatusPartial => 'Djelomično dostupno';

  @override
  String get openOnlyFilter => 'Samo otvorene';

  @override
  String get saveAsDefaults => 'Spremi kao moje zadane';

  @override
  String get criteriaSavedToProfile => 'Spremljeno kao zadano';

  @override
  String get updatingFavorites => 'Ažuriranje favorita...';

  @override
  String get fetchingLatestPrices => 'Dohvaćanje najnovijih cijena';

  @override
  String get noDataAvailable => 'Nema podataka';

  @override
  String get searchToSeeMap => 'Pretražite da vidite postaje na karti';

  @override
  String get evPowerAny => 'Bilo koja';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Lokacija';

  @override
  String get sectionPrivacyData => 'Privatnost i podaci';

  @override
  String get sectionAdvancedDeveloper => 'Napredno i razvijatelj';

  @override
  String get tooltipBack => 'Natrag';

  @override
  String get tooltipClose => 'Zatvori';

  @override
  String get tooltipShare => 'Podijeli';

  @override
  String get tooltipClearSearch => 'Obriši unos pretraživanja';

  @override
  String get minimalDriveInstantConsumption => 'Trenutna potrošnja';

  @override
  String get minimalDriveBehaviour => 'Stil vožnje';

  @override
  String get coachingShiftUp => 'Prebaci gore';

  @override
  String get coachingShiftDown => 'Prebaci dolje';

  @override
  String get coachingEasePedal => 'Smanji gas';

  @override
  String get coachingVoiceHardAcceleration => 'Polako s papučicom gasa';

  @override
  String get coachingVoiceHarshBraking => 'Pokušajte kočiti blaže';

  @override
  String get coachingVoiceShiftUp => 'Ubacite višu brzinu za uštedu goriva';

  @override
  String get coachingVoiceShiftDown =>
      'Ubacite nižu brzinu, motor naporno radi';

  @override
  String get coachingVoiceEasePedal =>
      'Popustite papučicu kako biste smanjili potrošnju goriva';

  @override
  String get coachingVoiceLiftOff =>
      'Dignite nogu s papučice i kližite inercijom';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Gledajte dalje naprijed i dignite nogu ranije';

  @override
  String get coachingVoiceSmoothAccel => 'Ubrzavajte ravnomjernije';

  @override
  String get coachingVoiceSharpCorner => 'Prolazite zavoje malo mekše';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'To je bilo vrlo naglo kočenje — držite veći razmak';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Vrlo naglo ubrzanje — to stvarno troši gorivo';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Vrlo oštar zavoj — polako unutra, glatko van';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount naglih manevara.',
      few: '$harshCount nagla manevra.',
      one: 'Jedan nagli manevar.',
      zero: 'Lijepo i glatko — bez naglih manevara.',
    );
    return 'Vožnja spremljena: $distanceKm kilometara, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litara na 100 kilometara';
  }

  @override
  String get voiceCoachingSettingTitle => 'Glasovni coaching za vožnju';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Slušajte glasovne savjete za vrijeme vožnje — jako ubrzavanje, naglo kočenje i savjeti za mijenjanje brzina';

  @override
  String get tooltipUseGps => 'Koristi GPS lokaciju';

  @override
  String get tooltipShowPassword => 'Prikaži lozinku';

  @override
  String get tooltipHidePassword => 'Sakrij lozinku';

  @override
  String get evConnectorsLabel => 'Dostupni priključci';

  @override
  String get evConnectorsNone => 'Nema informacija o priključcima';

  @override
  String get switchToEmail => 'Prebaci na e-poštu';

  @override
  String get switchToEmailSubtitle =>
      'Zadrži podatke, dodaj prijavu s drugih uređaja';

  @override
  String get switchToAnonymousAction => 'Prebaci na anonimno';

  @override
  String get switchToAnonymousSubtitle =>
      'Zadrži lokalne podatke, koristi novu anonimnu sesiju';

  @override
  String get linkDevice => 'Poveži uređaj';

  @override
  String get shareDatabase => 'Dijeli bazu podataka';

  @override
  String get disconnectAction => 'Odspoji';

  @override
  String get disconnectSubtitle =>
      'Zaustavi sinkronizaciju (lokalni podaci sačuvani)';

  @override
  String get deleteAccountAction => 'Obriši račun';

  @override
  String get deleteAccountSubtitle =>
      'Trajno ukloni sve podatke s poslužitelja';

  @override
  String get localOnly => 'Samo lokalno';

  @override
  String get localOnlySubtitle =>
      'Neobavezno: sinkroniziraj favorite, upozorenja i ocjene na svim uređajima';

  @override
  String get tankSyncSchemaOutdatedTitle => 'Baza u oblaku treba ažuriranje';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Vaša samostalno hostana TankSync shema je zastarjela — neki se podaci ne mogu sinkronizirati. Otvorite čarobnjak za sinkronizaciju i pokrenite SQL za ažuriranje na svom Supabase projektu.';

  @override
  String get setupCloudSync => 'Postavi sinkronizaciju u oblaku';

  @override
  String get disconnectTitle => 'Odspojiti TankSync?';

  @override
  String get disconnectBody =>
      'Sinkronizacija u oblaku bit će onemogućena. Vaši lokalni podaci (favoriti, upozorenja, povijest) sačuvani su na ovom uređaju. Podaci na poslužitelju neće biti obrisani.';

  @override
  String get deleteAccountTitle => 'Obrisati račun?';

  @override
  String get deleteAccountBody =>
      'Ovo trajno briše sve vaše podatke s poslužitelja (favoriti, upozorenja, ocjene, rute). Lokalni podaci na ovom uređaju su sačuvani.\n\nOvo se ne može poništiti.';

  @override
  String get switchToAnonymousTitle => 'Prebaciti na anonimno?';

  @override
  String get switchToAnonymousBody =>
      'Bit ćete odjavljeni s e-mail računa i nastaviti s novom anonimnom sesijom.\n\nVaši lokalni podaci (favoriti, upozorenja) ostaju na ovom uređaju i bit će sinkronizirani s novim anonimnim računom.';

  @override
  String get switchAction => 'Prebaci';

  @override
  String get helpBannerCriteria =>
      'Zadane vrijednosti vašeg profila su prethodno popunjene. Prilagodite kriterije ispod za preciznije pretraživanje.';

  @override
  String get helpBannerAlerts =>
      'Postavite prag cijene za postaju. Bit ćete obaviješteni kada cijene padnu ispod njega. Provjere se vrše svakih 30 minuta.';

  @override
  String get helpBannerConsumption =>
      'Evidentirajte svako punjenje za praćenje stvarne potrošnje i CO₂ otiska. Povucite lijevo za brisanje unosa.';

  @override
  String get helpBannerVehicles =>
      'Dodajte svoja vozila kako bi se punjenja i preferencije goriva automatski popunjavale. Prvo vozilo postaje zadano.';

  @override
  String get syncNow => 'Sinkroniziraj odmah';

  @override
  String get onboardingPreferencesTitle => 'Vaše preferencije';

  @override
  String get onboardingZipHelper => 'Koristi se kada GPS nije dostupan';

  @override
  String get onboardingRadiusHelper => 'Veći polumjer = više rezultata';

  @override
  String get onboardingPrivacy =>
      'Ove postavke pohranjuju se samo na vašem uređaju i nikada se ne dijele.';

  @override
  String get onboardingLandingTitle => 'Početni zaslon';

  @override
  String get onboardingLandingHint =>
      'Odaberite koji se zaslon otvara pri pokretanju aplikacije.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Ostanite izvan aplikacije — ali je nemojte zatvarati.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Otvorite Sparkilo jednom nakon svakog ponovnog pokretanja.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple aktivira Sparkilo samo nakon što ste ga otvorili najmanje jednom od posljednjeg ponovnog pokretanja telefona. Nakon toga, vaše vožnje se snimaju automatski.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Nemojte izbaciti Sparkilo iz preklopnika aplikacija.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Prisilno zatvaranje\" govori iOS-u da prestane pokretati aplikaciju. Vaše vožnje neće se snimati dok ponovo ne otvorite Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Kada iOS zatraži lokaciju \"Uvijek\", molimo recite da.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Sigurnosna kopija koja snima vožnju kada je OBD2 adapter spor treba lokaciju u pozadini. Nikada je ne dijelimo.';

  @override
  String get scanReceipt => 'Skeniraj račun';

  @override
  String get brandFilterHighway => 'Autocesta';

  @override
  String get ratingModeLocal => 'Lokalno';

  @override
  String get ratingModePrivate => 'Privatno';

  @override
  String get ratingModeShared => 'Dijeljeno';

  @override
  String get ratingDescLocal => 'Ocjene pohranjene samo na ovom uređaju';

  @override
  String get ratingDescPrivate =>
      'Sinkronizirano s vašom bazom podataka (nije vidljivo drugima)';

  @override
  String get ratingDescShared => 'Vidljivo svim korisnicima vaše baze podataka';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API ključ nije konfiguriran. Dodajte ga u Postavkama za pretraživanje EV punionica.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Davatelj podataka ($host) poslužuje istekli ili nevažeći TLS certifikat. Aplikacija ne može učitati podatke iz ovog izvora dok davatelj to ne ispravi. Kontaktirajte $host.';
  }

  @override
  String get offlineLabel => 'Izvan mreže';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nedostupno. Koristim $current.';
  }

  @override
  String get errorTitleApiKey => 'Potreban API ključ';

  @override
  String get errorTitleLocation => 'Lokacija nedostupna';

  @override
  String get errorHintNoStations =>
      'Pokušajte povećati polumjer pretraživanja ili pretražite drugu lokaciju.';

  @override
  String get errorHintApiKey => 'Konfigurirajte API ključ u Postavkama.';

  @override
  String get errorHintConnection =>
      'Provjerite internetsku vezu i pokušajte ponovo.';

  @override
  String get errorHintRouting =>
      'Izračun rute nije uspio. Provjerite internetsku vezu i pokušajte ponovo.';

  @override
  String get errorHintFallback =>
      'Pokušajte ponovo ili pretražite prema poštanskom broju / nazivu grada.';

  @override
  String get alertsLoadErrorTitle => 'Nije moguće učitati upozorenja';

  @override
  String get detailsLabel => 'Pojedinosti';

  @override
  String get remove => 'Ukloni';

  @override
  String get showKey => 'Prikaži ključ';

  @override
  String get hideKey => 'Sakrij ključ';

  @override
  String get syncOptionalTitle => 'TankSync je neobavezan';

  @override
  String get syncOptionalDescription =>
      'Vaša aplikacija radi potpuno bez sinkronizacije u oblaku. TankSync vam omogućuje sinkronizaciju favorita, upozorenja i ocjena na svim uređajima koristeći Supabase (dostupan besplatan plan).';

  @override
  String get syncHowToConnectQuestion => 'Kako se želite spojiti?';

  @override
  String get syncCreateOwnTitle => 'Stvori vlastitu bazu podataka';

  @override
  String get syncCreateOwnSubtitle =>
      'Besplatni Supabase projekt — vodimo vas korak po korak';

  @override
  String get syncJoinExistingTitle => 'Pridruži se postojećoj bazi podataka';

  @override
  String get syncJoinExistingSubtitle =>
      'Skenirajte QR kod od vlasnika baze podataka ili zalijepite vjerodajnice';

  @override
  String get syncChooseAccountType => 'Odaberite vrstu računa';

  @override
  String get syncAccountTypeAnonymous => 'Anonimno';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Trenutačno, bez e-maila. Podaci vezani uz ovaj uređaj.';

  @override
  String get syncAccountTypeEmail => 'E-mail račun';

  @override
  String get syncAccountTypeEmailDesc =>
      'Prijavite se s bilo kojeg uređaja. Oporavite podatke ako izgubite telefon.';

  @override
  String get syncHaveAccountSignIn => 'Već imate račun? Prijavite se';

  @override
  String get syncCreateNewAccount => 'Stvori novi račun';

  @override
  String get syncTestConnection => 'Testiraj vezu';

  @override
  String get syncTestingConnection => 'Testiranje...';

  @override
  String get syncConnectButton => 'Spoji';

  @override
  String get syncConnectingButton => 'Spajanje...';

  @override
  String get syncDatabaseReady => 'Baza podataka sprema!';

  @override
  String get syncDatabaseNeedsSetup => 'Baza podataka treba postavljanje';

  @override
  String get syncTableStatusOk => 'U redu';

  @override
  String get syncTableStatusMissing => 'Nedostaje';

  @override
  String get syncSqlEditorInstructions =>
      'Kopirajte SQL ispod i pokrenite ga u Supabase SQL Editoru (Nadzorna ploča → SQL Editor → Novi upit → Zalijepite → Pokrenite)';

  @override
  String get syncCopySqlButton => 'Kopiraj SQL u međuspremnik';

  @override
  String get syncRecheckSchemaButton => 'Ponovo provjeri shemu';

  @override
  String get syncSchemaOutdated =>
      'Vaša TankSync shema je zastarjela — ponovno pokrenite SQL za postavljanje u nastavku da biste omogućili najnovije sinkronizirane značajke.';

  @override
  String get syncDoneButton => 'Gotovo';

  @override
  String syncSignedInAs(String email) {
    return 'Prijavljeni kao $email';
  }

  @override
  String get syncEmailDescription =>
      'Vaši podaci sinkroniziraju se na svim uređajima s ovim e-mailom.';

  @override
  String get syncSwitchToAnonymousTitle => 'Prebaci na anonimno';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Nastavite bez e-maila, nova anonimna sesija';

  @override
  String get syncGuestDescription => 'Anonimno, bez e-maila.';

  @override
  String get syncOrDivider => 'ili';

  @override
  String get syncHowToSyncQuestion => 'Kako se želite sinkronizirati?';

  @override
  String get syncOfflineDescription =>
      'Vaša aplikacija radi potpuno izvan mreže. Sinkronizacija u oblaku je neobavezna.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo zajednica';

  @override
  String get syncModeCommunitySubtitle =>
      'Zajednička baza podataka koju vodi razvojni programer — u nastavku pogledajte što se sinkronizira';

  @override
  String get syncModePrivateTitle => 'Privatna baza podataka';

  @override
  String get syncModePrivateSubtitle =>
      'Vlastiti Supabase — potpuna kontrola podataka';

  @override
  String get syncModeGroupTitle => 'Pridruži se grupi';

  @override
  String get syncModeGroupSubtitle =>
      'Zajednička baza podataka obitelji ili prijatelja';

  @override
  String get syncPrivacyShared => 'Dijeljeno';

  @override
  String get syncPrivacyPrivate => 'Privatno';

  @override
  String get syncPrivacyGroup => 'Grupa';

  @override
  String get syncStayOfflineButton => 'Ostani izvan mreže';

  @override
  String get syncSuccessTitle => 'Uspješno spojeno!';

  @override
  String get syncSuccessDescription =>
      'Vaši podaci sada će se automatski sinkronizirati.';

  @override
  String get syncWizardTitleConnect => 'Spoji TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Vaša baza podataka';

  @override
  String get syncSetupTitleJoinGroup => 'Pridruži se grupi';

  @override
  String get syncSetupTitleAccount => 'Vaš račun';

  @override
  String get syncWizardBack => 'Natrag';

  @override
  String get syncWizardNext => 'Dalje';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Korak $current od $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Stvori Supabase projekt';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Dodirnite \"Otvori Supabase\" ispod\n2. Stvorite besplatni račun (ako ga nemate)\n3. Kliknite \"Novi projekt\"\n4. Odaberite naziv i regiju\n5. Pričekajte ~2 minute za pokretanje';

  @override
  String get syncWizardOpenSupabase => 'Otvori Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Omogući anonimne prijave';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. U Supabase nadzornoj ploči:\n   Autentifikacija → Davatelji\n2. Pronađite \"Anonimne prijave\"\n3. Uključite\n4. Kliknite \"Spremi\"';

  @override
  String get syncWizardOpenAuthSettings => 'Otvori postavke autentifikacije';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopirajte svoje vjerodajnice';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Idite na Postavke → API u nadzornoj ploči\n2. Kopirajte \"URL projekta\"\n3. Kopirajte \"anon javni\" ključ\n4. Zalijepite ih ispod';

  @override
  String get syncWizardOpenApiSettings => 'Otvori API postavke';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Pridruži se postojećoj bazi podataka';

  @override
  String get syncWizardScanQrCode => 'Skeniraj QR kod';

  @override
  String get syncWizardAskOwnerQr =>
      'Zamolite vlasnika baze podataka da vam pokaže QR kod\n(Postavke → TankSync → Dijeli)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Zamolite vlasnika baze podataka da pokaže QR kod';

  @override
  String get syncWizardEnterManuallyTitle => 'Unesite ručno';

  @override
  String get syncWizardOrEnterManually => 'ili unesite ručno';

  @override
  String get syncWizardUrlHelperText =>
      'Razmaci i prijelomi redova uklanjaju se automatski';

  @override
  String get syncCredentialsPrivateHint =>
      'Unesite vjerodajnice Supabase projekta. Možete ih pronaći u nadzornoj ploči pod Postavke > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL baze podataka';

  @override
  String get syncCredentialsAccessKeyLabel => 'Pristupni ključ';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Lozinka';

  @override
  String get authConfirmPasswordLabel => 'Potvrdi lozinku';

  @override
  String get authPleaseEnterEmail => 'Molimo unesite e-mail adresu';

  @override
  String get authInvalidEmail => 'Nevažeća e-mail adresa';

  @override
  String get authPasswordsDoNotMatch => 'Lozinke se ne podudaraju';

  @override
  String get authConnectAnonymously => 'Spoji se anonimno';

  @override
  String get authCreateAccountAndConnect => 'Stvori račun i spoji se';

  @override
  String get authSignInAndConnect => 'Prijavi se i spoji';

  @override
  String get authAnonymousSegment => 'Anonimno';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Trenutačni pristup, bez e-maila. Podaci vezani uz ovaj uređaj.';

  @override
  String get authEmailDescription =>
      'Prijavite se s bilo kojeg uređaja. Oporavite podatke ako izgubite telefon.';

  @override
  String get authSyncAcrossDevices =>
      'Automatski sinkronizirajte podatke na svim vašim uređajima.';

  @override
  String get authNewHereCreateAccount => 'Novi ste ovdje? Stvorite račun';

  @override
  String get linkDeviceScreenTitle => 'Poveži uređaj';

  @override
  String get linkDeviceThisDeviceLabel => 'Ovaj uređaj';

  @override
  String get linkDeviceShareCodeHint =>
      'Podijelite ovaj kôd s vašim drugim uređajem:';

  @override
  String get linkDeviceNotConnected => 'Nije spojeno';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopiraj kôd';

  @override
  String get linkDeviceImportSectionTitle => 'Uvezi s drugog uređaja';

  @override
  String get linkDeviceImportDescription =>
      'Unesite kôd uređaja s vašeg drugog uređaja za uvoz favorita, upozorenja, vozila i evidencije potrošnje. Svaki uređaj zadržava vlastiti profil i zadane vrijednosti.';

  @override
  String get linkDeviceCodeFieldLabel => 'Kôd uređaja';

  @override
  String get linkDeviceCodeFieldHint => 'Zalijepite UUID s drugog uređaja';

  @override
  String get linkDeviceImportButton => 'Uvezi podatke';

  @override
  String get linkDeviceHowItWorksTitle => 'Kako to radi';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Na uređaju A: kopirajte kôd uređaja gore\n2. Na uređaju B: zalijepite ga u polje \"Kôd uređaja\"\n3. Dodirnite \"Uvezi podatke\" za spajanje favorita, upozorenja, vozila i evidencije potrošnje\n4. Oba uređaja imat će sve kombinirane podatke\n\nSvaki uređaj zadržava vlastiti anonimni identitet i vlastiti profil (željeno gorivo, zadano vozilo, početni zaslon). Podaci se spajaju, ne premještaju.';

  @override
  String get vehicleSetActive => 'Postavi kao aktivno';

  @override
  String get swipeHide => 'Sakrij';

  @override
  String get yourRating => 'Vaša ocjena';

  @override
  String get noStorageUsed => 'Nema iskorištenog prostora';

  @override
  String get aboutReportBug => 'Prijavi grešku / Predloži značajku';

  @override
  String get aboutSupportProject => 'Podrži ovaj projekt';

  @override
  String get aboutSupportDescription =>
      'Ova aplikacija je besplatna, open source i bez oglasa. Ako vam je korisna, razmislite o podršci razvojnom programeru.';

  @override
  String get reportIssueTitle => 'Prijavi problem';

  @override
  String get enterCorrection => 'Molimo unesite ispravak';

  @override
  String get reportNoBackendAvailable =>
      'Izvješće nije moglo biti poslano: nije konfigurirana usluga za prijavu za ovu zemlju. Omogućite TankSync u Postavkama za slanje izvješća zajednice.';

  @override
  String get correctName => 'Ispravi naziv postaje';

  @override
  String get correctAddress => 'Ispravi adresu';

  @override
  String get wrongE85Price => 'Pogrešna cijena E85';

  @override
  String get wrongE98Price => 'Pogrešna cijena Super 98';

  @override
  String get wrongLpgPrice => 'Pogrešna cijena LPG';

  @override
  String get wrongStationName => 'Pogrešan naziv postaje';

  @override
  String get wrongStationAddress => 'Pogrešna adresa';

  @override
  String get independentStation => 'Neovisna postaja';

  @override
  String get serviceRemindersSection => 'Podsjetnici za servis';

  @override
  String get serviceRemindersEmpty =>
      'Još nema podsjetnika — odaberite unaprijed postavljeni gore.';

  @override
  String get addServiceReminder => 'Dodaj podsjetnik';

  @override
  String get serviceReminderPresetOil => 'Ulje (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Izmjena ulja';

  @override
  String get serviceReminderPresetTires => 'Gume (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Gume';

  @override
  String get serviceReminderPresetInspection => 'Tehnički pregled (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Tehnički pregled';

  @override
  String get serviceReminderLabel => 'Oznaka';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Posljednji servis';

  @override
  String get serviceReminderMarkDone => 'Označi kao obavljeno';

  @override
  String get serviceReminderDueTitle => 'Servis dospijeva';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label dospijeva — $kmOver km prošlo od intervala.';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '$label — rok je sada.';
  }

  @override
  String get vinConfirmTitle => 'Je li ovo vaše vozilo?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-cilindarski, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Djelomične informacije (izvan mreže). Možete urediti ispod.';

  @override
  String get vinDecodeError => 'Nije moguće dekodirati ovaj VIN';

  @override
  String get vinInvalidFormat => 'Nevažeći VIN format';

  @override
  String get obd2PauseBannerTitle => 'OBD2 veza prekinuta — snimanje pauzirano';

  @override
  String get obd2PauseBannerResume => 'Nastavi snimanje';

  @override
  String get obd2PauseBannerEnd => 'Završi snimanje';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Snimanje s GPS-om — OBD2 se ponovno spaja';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Snimanje GPS-om — čekanje OBD2 adaptera';

  @override
  String get alertsStationSectionTitle => 'Upozorenja za postaje';

  @override
  String get alertsStationAdd => 'Dodaj upozorenje za postaju';

  @override
  String get alertsRadiusSectionTitle => 'Upozorenja polumjera';

  @override
  String get alertsRadiusAdd => 'Dodaj upozorenje polumjera';

  @override
  String get alertsRadiusEmptyTitle => 'Još nema upozorenja polumjera';

  @override
  String get alertsRadiusEmptyCta => 'Stvori upozorenje polumjera';

  @override
  String get alertsRadiusCreateTitle => 'Stvori upozorenje polumjera';

  @override
  String get alertsRadiusLabelHint => 'Oznaka (npr. Kućni diesel)';

  @override
  String get alertsRadiusFuelType => 'Vrsta goriva';

  @override
  String get alertsRadiusKm => 'Polumjer (km)';

  @override
  String get alertsRadiusCenterGps => 'Koristi moju lokaciju';

  @override
  String get alertsRadiusCenterPostalCode => 'Poštanski broj';

  @override
  String get alertsRadiusSave => 'Spremi';

  @override
  String get alertsRadiusCancel => 'Odustani';

  @override
  String radiusAlertDeleted(String name) {
    return 'Upozorenje za radijus \"$name\" izbrisano';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 spojen: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Upari OBD2 adapter';

  @override
  String get fillUpSavedSnackbar => 'Punjenje spremljeno';

  @override
  String get notFoundTitle => 'Stranica nije pronađena';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nije pronađeno.';
  }

  @override
  String get notFoundHomeButton => 'Početna';

  @override
  String get consumptionTabHiddenNotice =>
      'Kartica Potrošnja skrivena je vašim postavkama profila.';

  @override
  String get swipeBetweenTabsHint =>
      'Savjet: povucite lijevo ili desno za prebacivanje između kartica.';

  @override
  String get discardChangesTitle => 'Odbaciti promjene?';

  @override
  String get discardChangesBody =>
      'Imate nespremljene promjene. Ako sada napustite, bit će odbačene.';

  @override
  String get discardChangesConfirm => 'Odbaci';

  @override
  String get discardChangesKeepEditing => 'Nastavi uređivanje';

  @override
  String get tankSyncSectionSubtitle =>
      'Sinkronizacija u oblaku na svim uređajima';

  @override
  String get mapUnavailable => 'Karta nije dostupna';

  @override
  String get routeNameHintExample => 'npr. Pariz → Lyon';

  @override
  String get priceStatsCurrent => 'Trenutačno';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API ključ';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API ključ';

  @override
  String get tapToUpdateGpsPosition => 'Dodirnite za ažuriranje GPS položaja';

  @override
  String get nameLabel => 'Naziv';

  @override
  String get obd2ErrorPermissionDenied =>
      'Za povezivanje s OBD2 adapterom potrebno je dopuštenje za Bluetooth.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Uključite Bluetooth i pokušajte ponovno.';

  @override
  String get obd2ErrorScanTimeout =>
      'U blizini nije pronađen OBD2 adapter. Provjerite je li priključen i uključen.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2 adapter nije odgovorio. Uključite paljenje i pokušajte ponovno.';

  @override
  String get obd2ErrorEngineOff =>
      'Nema podataka iz vozila — pokrenite motor i pokušajte ponovno.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2 adapter poslao je neprepoznat odgovor. Možda nije kompatibilan — pokušajte s drugim adapterom.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2 adapter se isključio. Ponovno se povežite i pokušajte ponovno.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adapter zahtijeva Bluetooth uparivanje. Iskopčajte adapter, ponovno ga ukopčajte i pokušajte ponovno unutar 5 minuta.';

  @override
  String get onboardingExploreDemoData => 'Istraži s demo podacima';

  @override
  String get achievementSmoothDriver => 'Niz mirnih vožnji';

  @override
  String get achievementSmoothDriverDesc =>
      'Vozite 5 uzastopnih vožnji s ocjenom mirne vožnje 80 ili više.';

  @override
  String get achievementColdStartAware => 'Svjestan hladnog starta';

  @override
  String get achievementColdStartAwareDesc =>
      'Zadržite trošak goriva hladnog starta cijelog mjeseca ispod 2 % ukupnog goriva — kombinirajte kratke vožnje.';

  @override
  String get achievementHighwayMaster => 'Majstor autoceste';

  @override
  String get achievementHighwayMasterDesc =>
      'Završite vožnju od 30 km+ pri konstantnoj brzini s ocjenom mirne vožnje 90 ili više.';

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
    return '$price $currency (cilj: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel pao na obližnjim postajama';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count postaja pojeftinilo do $cents¢ u posljednjem satu';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count postaja ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ još $count';
  }

  @override
  String alertsLastChecked(String when) {
    return 'Zadnja provjera: $when';
  }

  @override
  String get alertsLastCheckedNever => 'Cijene još nisu provjerene u pozadini';

  @override
  String get alertsIosBestEffortNote =>
      'Na iPhoneu se upozorenja provjeravaju prema mogućnostima: iOS odlučuje kada aplikacija smije provjeriti cijene u pozadini, pa upozorenje može stići kasno ili povremeno uopće ne stići. Otvaranje aplikacije uvijek pokreće novu provjeru.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Ciljna cijena ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Prag ($currency/L)';
  }

  @override
  String get approachOverlaySection =>
      'Preklapanje pri prilasku benzinskoj postaji';

  @override
  String get approachRadiusLabel => 'Polumjer';

  @override
  String approachRadiusCaption(String km) {
    return 'Preklapanje se povećava i prikazuje cijenu kada ste unutar $km km od postaje';
  }

  @override
  String get approachPriceModeLabel => 'Prikaži cijenu za';

  @override
  String get approachPriceModeNearest => 'Najbliža postaja';

  @override
  String get approachPriceModeCheapestInRadius => 'Najjeftinija u polumjeru';

  @override
  String get approachMinPollLabel => 'Min. osvježavanje';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Donja granica osvježavanja najbliže postaje (brže pri brzini, nikada češće od $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testiraj sloj približavanja';

  @override
  String get approachTestStopButton => 'Zaustavi test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test je aktivan — sloj prikazuje cijenu za $station';
  }

  @override
  String get approachTestUnavailable =>
      'Dodajte omiljenu postaju za testiranje sloja približavanja';

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Blizina $percent%';
  }

  @override
  String get pipTapToRestore => 'Dodirnite za otvaranje cijele aplikacije';

  @override
  String get authErrorNoNetwork =>
      'Nema mrežne veze. Pokušajte ponovno kasnije.';

  @override
  String get authErrorInvalidCredentials =>
      'Nevažeći e-mail ili lozinka. Provjerite svoje vjerodajnice.';

  @override
  String get authErrorUserAlreadyExists =>
      'Ovaj e-mail je već registriran. Pokušajte se prijaviti.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Molimo provjerite e-poštu i prvo potvrdite račun.';

  @override
  String get authErrorGeneric =>
      'Prijava nije uspjela. Molimo pokušajte ponovo.';

  @override
  String get authLinkEmailTitle => 'Poveži e-poštu';

  @override
  String get authLinkEmailSubtitle =>
      'Povežite e-poštu kako bi se vaši podaci sinkronizirali između uređaja. Trenutni favoriti i vožnje ostaju na ovom računu.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Koristite račun gosta ($idPrefix…). Povežite e-poštu kako bi se vaši favoriti i vožnje sinkronizirali s ostalim uređajima.';
  }

  @override
  String get authConfirmationPending =>
      'Skoro gotovo — provjerite e-poštu i kliknite poveznicu da dovršite povezivanje. Vaši su podaci već spremljeni na ovom računu.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Lokacija u pozadini — samo za automatsko snimanje';

  @override
  String get autoRecordConsentExplanationTitle => 'O ovoj dozvoli';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatsko snimanje treba lokaciju u pozadini za otkrivanje kada počnete voziti dok je aplikacija zatvorena. Ova dozvola koristi se samo za automatsko snimanje — pretraživanje postaja i centriranje karte koristi zasebnu dozvolu lokacije u prednjem planu.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Razumijem';

  @override
  String get autoRecordConsentExplanationTooltip => 'Što to znači?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Dodirnite za upravljanje u sistemskim postavkama';

  @override
  String get autoRecordSectionTitle => 'Automatsko snimanje';

  @override
  String get autoRecordToggleLabel => 'Automatski snimaj vožnje';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatsko snimanje aktivirat će se sljedeći put kada uđete u automobil.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Uparite OBD2 adapter za omogućavanje automatskog snimanja.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Dopustite lokaciju u pozadini kako bi automatsko snimanje nastavilo raditi s isključenim ekranom.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Upari adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Brzina pokretanja (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Kašnjenje pohrane nakon odspajanja (sekunde)';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Lokacija u pozadini dopuštena';

  @override
  String get autoRecordBackgroundLocationRequest => 'Zatraži dozvolu';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Zašto \"Uvijek dopusti\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatsko snimanje prenosi GPS koordinate iz OBD-II prednje usluge dok je ekran isključen kako bi ruta vožnje bila točna. Android zahtijeva opciju \"Uvijek dopusti\" da bi to nastavilo funkcionirati nakon zaključavanja uređaja.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Otvori postavke';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Potrebna je dozvola za lokaciju';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nije moguće zatražiti lokaciju u pozadini';

  @override
  String get aclWakeNotificationTitle => 'Automobil povezan';

  @override
  String get aclWakeNotificationBody =>
      'Dodirnite za otvaranje Sparkila — snimanje vožnje može početi.';

  @override
  String get exportBackupReady =>
      'Sigurnosna kopija spremna — odaberite odredište';

  @override
  String get exportBackupFailed =>
      'Izvoz sigurnosne kopije nije uspio — pokušajte ponovo';

  @override
  String get backupExportProgress => 'Izvoz sigurnosne kopije…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Spremljeno u Downloads kao $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Obnovi sigurnosnu kopiju';

  @override
  String get restoreBackupDialogBody =>
      'Spajanje dodaje i ažurira zapise iz sigurnosne kopije i zadržava sve što je već na ovom uređaju. Zamjena briše sve trenutne podatke, a zatim obnavlja samo sigurnosnu kopiju — ovo se ne može poništiti.';

  @override
  String get restoreBackupMergeAction => 'Spoji';

  @override
  String get restoreBackupReplaceAction => 'Zamijeni sve';

  @override
  String get restoreBackupEmpty =>
      'Sigurnosna kopija obnovljena — nije sadržavala zapise';

  @override
  String get restoreBackupCorrupt =>
      'Obnavljanje nije uspjelo — ova datoteka nije valjana Tankstellen sigurnosna kopija';

  @override
  String get restoreBackupFailed =>
      'Obnavljanje nije uspjelo — datoteka se nije mogla pročitati';

  @override
  String get backupImportProgress => 'Obnavljanje sigurnosne kopije…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Spojeno $vehicles vozila, $fillUps punjenja, $trips putova, $chargingLogs zapisa punjenja';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Svi podaci zamijenjeni s $vehicles vozila, $fillUps punjenja, $trips putova, $chargingLogs zapisa punjenja';
  }

  @override
  String get brokenMapChipDisclaimer => 'MAP očitanja su sumnjiva';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP senzor čita netočno — očitanja goriva mogu biti 50–80% preniska. Pokušajte s drugim adapterom.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP senzor nije pouzdan. Prikazujem prosjeke punjenja umjesto stvarne potrošnje.';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP senzor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP senzor: $posterior% ± $margin% (verificiran)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Dijagnostika MAP senzora';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Pouzdanost pokvarenog MAP-a: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count zabilježenih promatranja';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verificirano ispravno';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'MAP senzor ovog vozila još nije promatran.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokirani adapteri';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Nema blokiranih adaptera.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — označen $percent% pokvaren';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Očisti';

  @override
  String get brokenMapRevPromptTitle => 'Ubrzajte motor';

  @override
  String get brokenMapRevPromptBody =>
      'Kratko pritisnite gas kako bi aplikacija mogla provjeriti odaziv MAP senzora.';

  @override
  String get brokenMapRevPromptConfirm => 'Gotovo — ubrzao sam';

  @override
  String get calibrationAdvancedTitle => 'Napredna kalibracija';

  @override
  String get calibrationDisplacementLabel => 'Radni obujam motora (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrijska učinkovitost (η_v)';

  @override
  String get calibrationAfrLabel => 'Omjer zraka i goriva (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Gustoća goriva (g/L)';

  @override
  String get calibrationSourceDetected => '(otkriveno iz VIN-a)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(zadano)';

  @override
  String get calibrationSourceManual => '(ručno)';

  @override
  String get calibrationResetToDetected => 'Resetiraj na otkrivenu vrijednost';

  @override
  String get calibrationBasisAtkinson => 'Atkinson ciklus';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbopunjač + DI';

  @override
  String get calibrationBasisTurbo => 'Turbopunjač';

  @override
  String get calibrationBasisNaDi => 'Prirodno usisni + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — $basis zadano)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'Ovo vozilo izravno javlja potrošnju goriva (PID 5E), pa se kalibracija volumetrijske učinkovitosti ne koristi — vaša je potrošnja izmjerena, a ne modelirana.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vaš $makeModel je označen kao diesel, ali odgovara benzinskom katalogu. Dodirnite za ažuriranje.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Ažuriraj';

  @override
  String get catalogResetAction => 'Vrati iz baze vozila';

  @override
  String get catalogResetConfirmTitle => 'Vratiti iz baze vozila?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Ovo zamjenjuje zapremninu spremnika, snagu motora i obujam ovog vozila vrijednostima iz baze za $vehicle. Ostala polja i povijest točenja ostaju netaknuti.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'U bazi vozila nema odgovarajućeg unosa za ovo vozilo.';

  @override
  String get catalogResetDoneSnackbar => 'Podaci o vozilu vraćeni iz baze.';

  @override
  String get consumptionTabFuel => 'Gorivo';

  @override
  String get consumptionTabCharging => 'Punjenje';

  @override
  String get noChargingLogsTitle => 'Još nema evidencije punjenja';

  @override
  String get noChargingLogsSubtitle =>
      'Evidentirste prvu sesiju punjenja za početak praćenja EUR/100 km i kWh/100 km.';

  @override
  String get addChargingLog => 'Evidentiraj punjenje';

  @override
  String get addChargingLogTitle => 'Evidentiraj sesiju punjenja';

  @override
  String get chargingKwh => 'Energija (kWh)';

  @override
  String get chargingCost => 'Ukupni trošak';

  @override
  String get chargingTimeMin => 'Trajanje punjenja (min)';

  @override
  String get chargingStationName => 'Postaja (neobavezno)';

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
      'Potreban je prethodni zapis za usporedbu';

  @override
  String get chargingLogButtonLabel => 'Evidentiraj punjenje';

  @override
  String get chargingCostTrendTitle => 'Trend troška punjenja';

  @override
  String get chargingEfficiencyTitle => 'Učinkovitost (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Još nema dovoljno podataka';

  @override
  String get confirmDeleteTitle => 'Izbrisati?';

  @override
  String get confirmDeleteBody => 'Želite li ovo doista izbrisati?';

  @override
  String get consoFeatureGroupTitle => 'Conso';

  @override
  String get consoFeatureGroupDescription =>
      'Pratite potrošnju — ručna punjenja ili automatsko OBD2 snimanje vožnji.';

  @override
  String get consoModeOff => 'Isključeno';

  @override
  String get consoModeFuel => 'Gorivo';

  @override
  String get consoModeFuelAndTrips => 'Gorivo + Vožnje';

  @override
  String get consoModeOffDescription =>
      'Bez kartice Conso i bez odjeljka Conso postavki.';

  @override
  String get consoModeFuelDescription =>
      'Samo ručna punjenja. Korisno bez OBD2 adaptera.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Dodaje automatsko OBD2 snimanje vožnji. Zahtijeva upareni adapter.';

  @override
  String get consoGroupVehicles => 'Vozila';

  @override
  String get consoGroupCoaching => 'Coaching za vrijeme vožnje';

  @override
  String get consoGroupRewards => 'Nagrade i uštedine';

  @override
  String get consoGroupTroubleshooting => 'Rješavanje problema';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Točnost: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Visoka';

  @override
  String get consumptionAccuracyMedium => 'Srednja';

  @override
  String get consumptionAccuracyLow => 'Niska';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Potpuna kalibracija: točenja goriva plus vožnje snimljene putem OBD2. Vrijednost L/100 km prati stvarnost unutar nekoliko postotaka.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Točenja su usidrila model potrošnje, ali još nije obrađena nijedna OBD2 vožnja. Snimite jednu s povezanim OBD2 da biste postigli visoku točnost.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Samo GPS — još nijedno točenje nije usidrilo model potrošnje. Dodajte nekoliko punih točenja da biste poboljšali točnost.';

  @override
  String get moreActionsTooltip => 'Više';

  @override
  String get exportBackupMenuLabel => 'Izvezi sigurnosnu kopiju';

  @override
  String get restoreBackupMenuLabel => 'Obnovi sigurnosnu kopiju';

  @override
  String get carbonDashboardMenuLabel => 'Ugljična nadzorna ploča';

  @override
  String get settingsMenuLabel => 'Postavke';

  @override
  String get consumptionStatsPageTitle => 'Statistika potrošnje';

  @override
  String get consumptionStatsComparisonTitle =>
      'Ovaj mjesec u usporedbi s prošlim';

  @override
  String get consumptionStatsTrendsTitle => 'Razvoj kroz vrijeme';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Bilježite punjenja goriva kroz najmanje dva mjeseca za usporedbu.';

  @override
  String get consumptionStatsPricePerLiter => 'Prosj. cijena/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litara po mjesecu';

  @override
  String get consumptionStatsChartSpend => 'Potrošnja po mjesecu';

  @override
  String get consumptionStatsChartPricePerLiter => 'Cijena po litri';

  @override
  String get consumptionStatsChartConsumption => 'L/100km po mjesecu';

  @override
  String get fuelCompareSectionTitle => 'Trošak vožnje po gorivu';

  @override
  String get fuelComparePricePerLitre => 'Plaćeno po litri';

  @override
  String get fuelCompareCostPer100km => 'Trošak na 100 km';

  @override
  String get fuelCompareDistance => 'Izmjerena udaljenost';

  @override
  String get fuelCompareLitres => 'Potrošene litre';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner je vaše najjeftinije gorivo za vožnju';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser košta $amount više na 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel pobjeđuje $rival ispod $price po litri';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Točka isplativosti računa se iz izmjerene potrošnje svakog goriva pa se pomiče zajedno s vašom vožnjom.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litre i trošak mogu se razilaziti: gorivo može trošiti manje litara na 100 km i ipak koštati više po kilometru jer je cijena litre drukčija. Presuđuje trošak po kilometru.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punih spremnika',
      one: 'jednog punog spremnika',
    );
    return 'Privremeno — na temelju $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punih spremnika',
      one: 'jednog punog spremnika',
    );
    return 'Na temelju $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 na 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner je vaše gorivo s najnižim emisijama';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel košta $money više na 1000 km, ali ispušta $co2 manje CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel je istodobno jeftinije i čišće od $rival';
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
    return 'Vaših $distance na $fuel ispustilo je $actual umjesto $alternative na $rival — $saved izbjegnuto';
  }

  @override
  String get fuelCompareCo2Source =>
      'Vrijednosti CO2 su procjene od izvora do kotača (EU JEC WTW v5) primijenjene na vašu izmjerenu potrošnju — za orijentaciju, ne kao certificirano računovodstvo.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 se prikazuje samo za čista goriva: faktor emisije mješavine ovisi o sastavu koji ovaj redak ne bilježi.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count djelomičnih punjenja čeka plein complet — nisu u prosjeku',
      one: '1 djelomično punjenje čeka plein complet — nije u prosjeku',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% goriva iz automatskih ispravaka — pregledajte unose';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Korekcije: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Prijavi sadržaj';

  @override
  String get contentModerationBlockAction => 'Blokiraj autora';

  @override
  String get contentModerationReportDialogTitle => 'Prijaviti ovaj sadržaj?';

  @override
  String get contentModerationReportDialogBody =>
      'Prijava se šalje vašem TankSync poslužitelju na pregled, a ovaj se sadržaj skriva na vašem uređaju.';

  @override
  String get contentModerationReportConfirmButton => 'Prijavi';

  @override
  String get contentModerationBlockDialogTitle => 'Blokirati ovog autora?';

  @override
  String get contentModerationBlockDialogBody =>
      'Sve što ovaj račun dijeli s vama bit će skriveno na ovom uređaju.';

  @override
  String get contentModerationBlockConfirmButton => 'Blokiraj';

  @override
  String get contentModerationReportedSnack =>
      'Prijava poslana — sadržaj skriven.';

  @override
  String get contentModerationReportFailedSnack =>
      'Prijavu nije bilo moguće poslati. Pokušajte ponovno.';

  @override
  String get contentModerationBlockedSnack =>
      'Autor blokiran — njegov podijeljeni sadržaj je skriven.';

  @override
  String get fillUpCorrectionLabel =>
      'Automatski ispravak — dodirnite za uređivanje';

  @override
  String get fillUpCorrectionEditTitle => 'Uredi automatski ispravak';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Ovaj unos je automatski generiran za zatvaranje razlike između snimljenih vožnji i natočenog goriva. Prilagodite vrijednosti ako znate stvarne podatke.';

  @override
  String get fillUpCorrectionDelete => 'Obriši ispravak';

  @override
  String get fillUpCorrectionStation => 'Naziv postaje (neobavezno)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Postaje u $country $km km dalje — €$price/L jeftinije';
  }

  @override
  String get crossBorderTapToSwitch => 'Dodirnite za promjenu države';

  @override
  String get crossBorderDismissTooltip => 'Odbaci';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Otvori izvor podataka $source ($license) u pregledniku';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand suradnici';
  }

  @override
  String get developerToolsSectionTitle => 'Razvojni alati';

  @override
  String get dataAccessTracerExport => 'Izvezi zapisnik pristupa podacima';

  @override
  String get dataAccessTracerExportSuccess =>
      'Zapisnik pristupa podacima spremljen u Preuzimanja.';

  @override
  String get dataAccessTracerExportFailure =>
      'Zapisnik pristupa podacima nije bilo moguće izvesti.';

  @override
  String get dataAccessTracerEmpty =>
      'Još nema zabilježenih događaja pristupa podacima — prvo pretražite ili otvorite postaje, zatim izvezite.';

  @override
  String get developerToolsSubtitle =>
      'Dijagnostika i alati za otklanjanje pogrešaka — vidljivi samo u razvojnom načinu / načinu za otklanjanje pogrešaka.';

  @override
  String get developerToolsMenuSubtitle =>
      'Zapisnik pogrešaka, testna upozorenja, dijagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Zapisnik pogrešaka';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Spremi zapisnik pogrešaka ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Očisti zapisnik pogrešaka';

  @override
  String get developerToolsViewErrorLog => 'Prikaži zapisnik pogrešaka';

  @override
  String get developerToolsErrorLogEmpty =>
      'Nema zabilježenih tragova pogrešaka.';

  @override
  String get developerToolsAlertsGroupTitle => 'Upozorenja i obavijesti';

  @override
  String get developerToolsFireTestNotification => 'Pošalji testnu obavijest';

  @override
  String get developerToolsTestNotificationTitle => 'Testna obavijest';

  @override
  String get developerToolsTestNotificationBody =>
      'Ako ovo možete pročitati, obavijesti rade.';

  @override
  String get developerToolsTestNotificationSent => 'Testna obavijest poslana.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Obavijesti su blokirane — omogućite ih u postavkama sustava pa pokušajte ponovno.';

  @override
  String get developerToolsRunTestAlert => 'Pokreni testni tijek upozorenja';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testno upozorenje pokrenuto — tijek je isporučio $count obavijesti.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testno cjenovno upozorenje';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Sintetičko podudaranje: u blizini je pronađena postaja ispod vašeg cilja.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Prvo pretražite postaje, zatim pokrenite testno upozorenje kako bi obavijest mogla otvoriti stvarnu postaju.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Dijagnostika';

  @override
  String get developerToolsFeatureFlagDump => 'Inspektor zastavica značajki';

  @override
  String get developerToolsFlagOn => 'Uključeno';

  @override
  String get developerToolsFlagOff => 'Isključeno';

  @override
  String get developerToolsClearCaches => 'Očisti predmemorije';

  @override
  String get developerToolsCachesCleared => 'Predmemorije očišćene.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopiraj dijagnostiku';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Dijagnostika kopirana u međuspremnik.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Informacije o međuverziji';

  @override
  String get developerToolsBuildVersion => 'Verzija aplikacije';

  @override
  String get developerToolsBuildChannel => 'Kanal međuverzije';

  @override
  String get startupTraceSectionTitle =>
      'Zapisnik inicijalizacije pri pokretanju';

  @override
  String get startupTraceExportButton => 'Izvezi zapisnik pokretanja';

  @override
  String get startupTraceEmpty => 'Još nema zabilježenog zapisnika pokretanja.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Ukupno: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Zapisnik pokretanja spremljen u Preuzimanja.';

  @override
  String get startupTraceExportFailure =>
      'Zapisnik pokretanja nije bilo moguće izvesti.';

  @override
  String get distanceSourceOdometer => 'Brojač kilometara';

  @override
  String get distanceSourceOdometerTooltip =>
      'Udaljenost očitana s brojača kilometara automobila — izmjerena referentna vrijednost.';

  @override
  String get distanceSourceGps => 'GPS trag';

  @override
  String get distanceSourceGpsTooltip =>
      'Udaljenost zbrojena iz snimljenog GPS traga — stvarna udaljenost cestom.';

  @override
  String get distanceSourceEstimated => 'Procijenjeno';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Udaljenost integrirana iz senzora brzine — procjena; senzor obično pokazuje malo više.';

  @override
  String get insightCardTitle => 'Najrastrošnija ponašanja';

  @override
  String get insightEmptyState =>
      'Nema primjetnih neučinkovitosti — tako se nastavi!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor iznad 3000 RPM ($pctTime% vožnje): izgubljeno $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count nagla ubrzanja: izgubljeno $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Mirovanje ($pctTime% vožnje): izgubljeno $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% vožnje';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Vožnja u niskom stupnju ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Na duljim zaustavljanjima ugasite motor umjesto da ga ostavljate raditi u praznom hodu.';

  @override
  String get lessonAdviceHighRpm =>
      'Mijenjajte ranije u viši stupanj kako biste motor držali izvan zone visokih okretaja.';

  @override
  String get lessonAdviceHardAccel =>
      'Lagano pritišćite papučicu gasa — ravnomjerno ubrzavanje troši manje goriva.';

  @override
  String get lessonAdviceLowGear =>
      'Mijenjajte u viši stupanj ranije kako bi motor radio na nižim, ekonomičnijim okretajima.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Trajno visoka brzina ($pctTime% vožnje): potrošeno bez potrebe $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Trajno visoka brzina ($pctTime% vožnje)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Iznad 110 km/h skinite nogu s gasa – otpor zraka naglo raste, malo sporije štedi puno goriva.';

  @override
  String get lessonSmoothDrivingTitle => 'Mirna vožnja – odlično!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Nema naglog ubrzavanja ni kočenja na ovoj vožnji – ravnomjerna vožnja drži potrošnju niskom.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Puni gas ($pctTime% puta): izgubljeno $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Polako na pedalu — blaži pritisak od 70 % papučice dovoljno vas ubrzava uz puno manje goriva.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Bogata smjesa pod opterećenjem ($pctTime% puta): izgubljeno $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Jako, dugotrajno opterećenje čini motor prebogatim — kratko mjenjajte brzinu i pустите na dugim usponima da smjesa ostane siromašna.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Vožnja uz $gradePercent% nagib ($pctTime% puta): izgubljeno $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Zadržite zamah pri ulasku u uspon i ravnomjerno povećavajte gas — nagle promjene na usponu troše više goriva.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count zaustavljanja i ponovnih kretanja: izgubljeno $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Predvidite promet i kližite prema zaustavljanjima kako biste klizali, a ne stajali — kretanje s mjesta najtroši više goriva u stop-start vožnji.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Smjesa se čini malo siromašnom — motor je dodavao gorivo (korekcija $pctTrim %) da nadoknadi';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Smjesa se čini siromašnom — motor je trajno dodavao mnogo goriva ($pctTrim %), moguća neučinkovitost';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Smjesa se čini malo bogatom — motor je oduzimao gorivo (korekcija $pctTrim %) da nadoknadi';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Smjesa se čini bogatom — motor je trajno oduzimao mnogo goriva ($pctTrim %), moguća neučinkovitost';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Motor je radio bogato pod opterećenjem ($pctShare % zagrijane vožnje) — moguće rasipanje goriva';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristički signal stanja, ne dijagnoza';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Trajna korekcija prema siromašnoj smjesi može značiti propuštanje zraka u usisu, slab dovod goriva ili ostarjeli senzor. Ako se potrošnja ili rad pogoršaju, dijagnostika u servisu to može potvrditi.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Trajna korekcija prema bogatoj smjesi može značiti brizgaljku koja propušta, previsok tlak goriva ili senzor koji pokazuje previše. Ako se potrošnja ili rad pogoršaju, dijagnostika u servisu to može potvrditi.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Bogata smjesa pod velikim opterećenjem troši dodatno gorivo. Prebacujte ranije u viši stupanj i popustite gas pri dugim ubrzanjima kako bi motor ostao blizu stehiometrijske smjese.';

  @override
  String get lessonTransportTitle =>
      'Podaci motora nedostaju za veći dio ove vožnje';

  @override
  String get lessonTransportAdvice =>
      'Motor nije javio aktivnost gotovo cijelom udaljenošću. Ili je OBD2 tok otkazao usred vožnje ili je automobil premješten bez vožnje — vrijednost potrošnje je nepouzdana i isključena iz vaše statistike.';

  @override
  String get drivingScoreCardTitle => 'Ocjena vožnje';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Složena ocjena od mirovanja, naglih ubrzanja, naglih kočenja i vremena visokog RPM-a. Usporedba \'bolji od X% prošlih vožnji\' stići će u nadolazećoj verziji.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Ocjena vožnje $score od 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Mirovanje';

  @override
  String get drivingScorePenaltyHardAccel => 'Nagla ubrzanja';

  @override
  String get drivingScorePenaltyHardBrake => 'Nagla kočenja';

  @override
  String get drivingScorePenaltyHighRpm => 'Visoki RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Puni gas';

  @override
  String get drivingScoreClassVeryGood => 'Odlično';

  @override
  String get drivingScoreClassGood => 'Dobro';

  @override
  String get drivingScoreClassAverage => 'Prosječno';

  @override
  String get drivingScoreClassBad => 'Potrebno poboljšanje';

  @override
  String get drivingScorePenaltyLugging => 'Vučenje motora';

  @override
  String get drivingScorePenaltySmoothness => 'Trzava vožnja';

  @override
  String get drivingScorePenaltyHighSpeed => 'Visoka brzina';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresivna papučica';

  @override
  String get drivingScorePenaltyLambda => 'Bogata smjesa';

  @override
  String get gpsKpiCardTitle => 'GPS učinkovitost';

  @override
  String get gpsKpiRpa => 'Pozitivno ubrzanje (RPA)';

  @override
  String get gpsKpiPke => 'Potražnja kinetičke energije (PKE)';

  @override
  String get gpsKpiVapos => 'Intenzitet ubrzanja (VAPOS)';

  @override
  String get gpsKpiCoast => 'Udio klizanja inercijom';

  @override
  String get gpsKpiClimbEnergy => 'Energija uspona';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs vaša učinkovita osnova';
  }

  @override
  String get drivingTraceCardTitle => 'Trag analize vožnje (dev)';

  @override
  String get drivingTraceCardBody =>
      'Izvezite GPS KPI-je ovog puta, rezultat i lekcije kao JSON, napišite kako se vožnja zapravo osjećala u polju za komentar i podijelite natrag kako bi se pragovi stila vožnje mogli kalibrirati prema stvarnim putovanjima.';

  @override
  String get drivingTraceExportAction => 'Izvezi trag analize';

  @override
  String get drivingTraceExported =>
      'Trag analize spreman u Downloads — dodajte svoju procjenu u polje za komentar i podijelite ga natrag.';

  @override
  String get drivingTraceExportFailed => 'Trag analize se nije mogao izvesti.';

  @override
  String get minimalDriveTripAverage => 'Prosjek vožnje';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Vožnja na visokim okretajima ($pctTime % vožnje): ranije prebacivanje u viši stupanj moglo bi uštedjeti $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Pri stalnoj brzini prebacujte ranije u viši stupanj — ista brzina na nižim okretajima troši osjetno manje.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Kotrljanje s prekidom dovoda goriva ($pctTime % vožnje): ušteđeno oko $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Dobro predviđeno — rano popuštanje gasa omogućuje motoru da potpuno prekine dovod goriva tijekom kotrljanja.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Kamo je otišlo vaše gorivo';

  @override
  String get fuelBreakdownIdle => 'Prazni hod';

  @override
  String get fuelBreakdownHarshAccel => 'Nagla ubrzanja';

  @override
  String get fuelBreakdownHighRpmCruise => 'Vožnja na visokim okretajima';

  @override
  String get fuelBreakdownCoastingSaved => 'Ušteđeno kotrljanjem';

  @override
  String get fuelBreakdownEfficient => 'Normalna vožnja';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Prazni hod već neko vrijeme — gašenje motora štedi gorivo';

  @override
  String get ecoNudgeHarshAccel =>
      'Snažno ubrzanje — lakša noga na gasu štedi gorivo';

  @override
  String get ecoNudgeHighRpm =>
      'Visoki okretaji pri stalnoj brzini — ranije prebacivanje u viši stupanj štedi gorivo';

  @override
  String get obd2CoverageNoneNote =>
      'Tijekom ove vožnje nisu stigli podaci motora s OBD2 adaptera — vrijednosti goriva su procjene na temelju GPS-a.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Podaci motora prestali su na $percent % vožnje (veza prekinuta) — vrijednosti goriva nakon toga su procjene na temelju GPS-a.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Podaci motora pokrili su samo $percent % ove vožnje — praznine koriste procjene na temelju GPS-a.';
  }

  @override
  String get favoritesShareAction => 'Dijeli';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favoriti na $date';
  }

  @override
  String get favoritesShareError =>
      'Nije moguće generirati sliku za dijeljenje';

  @override
  String get featureManagementSectionTitle => 'Upravljanje značajkama';

  @override
  String get featureManagementSectionSubtitle =>
      'Uključite ili isključite pojedine značajke. Neke značajke ovise o drugima — prekidači su onemogućeni dok preduvjeti nisu ispunjeni.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2 snimanje vožnji';

  @override
  String get featureDescription_obd2TripRecording =>
      'Automatski snimajte vožnje putem OBD2.';

  @override
  String get featureLabel_gamification => 'Gamifikacija';

  @override
  String get featureDescription_gamification =>
      'Ocjene vožnje i zarađene značke.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptički eko trener';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Haptičke povratne informacije u stvarnom vremenu za vrijeme vožnje.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sinkronizacija na više uređaja putem Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analitika potrošnje';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Kartica za analizu punjenja i vožnji.';

  @override
  String get featureLabel_baselineSync => 'Sinkronizacija osnove';

  @override
  String get featureDescription_baselineSync =>
      'Sinkronizacija osnova vožnje putem TankSync.';

  @override
  String get featureLabel_priceAlerts => 'Upozorenja o cijenama';

  @override
  String get featureDescription_priceAlerts =>
      'Obavijesti o padu cijene na temelju praga.';

  @override
  String get featureLabel_priceHistory => 'Povijest cijena';

  @override
  String get featureDescription_priceHistory =>
      '30-dnevni grafovi cijena na detaljima postaje.';

  @override
  String get featureLabel_routePlanning => 'Planiranje rute';

  @override
  String get featureDescription_routePlanning =>
      'Najjeftinija postaja duž vaše rute.';

  @override
  String get featureLabel_evCharging => 'EV punjenje';

  @override
  String get featureDescription_evCharging => 'Punionice putem OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Smjernice za hipermilovanje koristeći OSM prometne signale.';

  @override
  String get featureLabel_gpsTripPath => 'GPS put vožnje';

  @override
  String get featureDescription_gpsTripPath =>
      'Spremi GPS uzorke puta zajedno sa svakom vožnjom.';

  @override
  String get featureLabel_autoRecord => 'Automatsko snimanje';

  @override
  String get featureDescription_autoRecord =>
      'Automatski pokreni vožnju kada se OBD2 adapter spoji na vozilo u pokretu.';

  @override
  String get featureLabel_showFuel => 'Prikaži benzinske postaje';

  @override
  String get featureDescription_showFuel =>
      'Prikaži rezultate benzinskih/dizelskih postaja u pretraživanju i na karti.';

  @override
  String get featureLabel_showElectric => 'Prikaži punionice';

  @override
  String get featureDescription_showElectric =>
      'Prikaži EV punionice u pretraživanju i na karti.';

  @override
  String get featureLabel_showConsumptionTab => 'Kartica potrošnje';

  @override
  String get featureDescription_showConsumptionTab =>
      'Prikaži karticu analitike potrošnje u donjoj navigaciji.';

  @override
  String get featureBlockedEnable_gamification =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureBlockedEnable_baselineSync => 'Prvo omogući TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite predviđanje cijena';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Model predviđanja cijena na uređaju — zaključivanje se odvija lokalno; značajke i predviđanja nikad ne napuštaju uređaj.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Prvo omogući povijest cijena';

  @override
  String get featureLabel_fuelCalculator => 'Kalkulator goriva';

  @override
  String get featureDescription_fuelCalculator =>
      'Kalkulator troška goriva za doseg iz rezultata pretraživanja.';

  @override
  String get featureLabel_carbonDashboard => 'CO2 nadzorna ploča';

  @override
  String get featureDescription_carbonDashboard =>
      'Nadzorna ploča CO2 otiska dostupna iz kartice Potrošnja.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentalni OEM PID-ovi';

  @override
  String get featureDescription_experimentalOemPids =>
      'Čitaj točne litre u spremniku putem PID-ova specifičnih za proizvođača na podržanim adapterima.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Prvo omogući OBD2 snimanje vožnji';

  @override
  String get featureLabel_paymentQrScan => 'Skeniraj QR za plaćanje';

  @override
  String get featureDescription_paymentQrScan =>
      'QR čitač za plaćanje na zaslonu detalja postaje.';

  @override
  String get featureLabel_communityPriceReports =>
      'Izvještaji o cijenama zajednice';

  @override
  String get featureDescription_communityPriceReports =>
      'Prijavite cijenu postaje sa zaslona detalja postaje.';

  @override
  String get featureLabel_obd2Optional =>
      'Zahtijevaj OBD2 za snimanje putovanja';

  @override
  String get featureDescription_obd2Optional =>
      'Kada je isključeno, aplikacija snima putovanja samo s GPS-om bez OBD2 adaptera. Coaching je smanjen — nema trenutne L/100 km, manje motornih signala.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR računa';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skenirajte ispisani račun na zaslonu Dodaj točenje da unaprijed ispunite datum, litre, ukupno i postaju.';

  @override
  String get featureLabel_developerPatToken =>
      'Razvojni povratni podaci (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Omogućuje ploču povratnih informacija za neuspjela skeniranja koja automatski stvara GitHub issues uz Personal Access Token. Funkcija za napredne korisnike / suradnike.';

  @override
  String get featureLabel_debugMode =>
      'Razvojni način / način za otklanjanje pogrešaka';

  @override
  String get featureDescription_debugMode =>
      'Prikazuje odjeljak Razvojni alati u postavkama s dijagnostikom: izvoz zapisnika pogrešaka, testne obavijesti, pokretanje testnog tijeka upozorenja, popis zastavica značajki, čišćenje predmemorija i kopiranje dijagnostike.';

  @override
  String get featureLabel_approachOverlay => 'Radar benzinskih postaja';

  @override
  String get featureDescription_approachOverlay =>
      'Pretvara plutajuću pločicu putovanja u živi radar benzinskih postaja — kako se približavate benzinskoj postaji, pločica mijenja boju prema vrsti goriva i prikazuje cijenu.';

  @override
  String get featureLabel_voiceAnnouncements => 'Glasovne objave';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Glasovno najavljuje obližnje jeftine benzinske postaje dok vozite, kako biste mogli zadržati pogled na cesti.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Prvo omogućite Radar benzinskih postaja';

  @override
  String get featureGroupTitle_finding => 'Traženje i karta';

  @override
  String get featureGroupDescription_finding =>
      'Gdje se natočiti ili napuniti — pretraživanje, karta, navigacija.';

  @override
  String get featureGroupTitle_prices => 'Cijene i upozorenja';

  @override
  String get featureGroupDescription_prices =>
      'Padovi cijena, povijest i prijave.';

  @override
  String get featureGroupTitle_radar => 'Radar benzinskih postaja';

  @override
  String get featureGroupDescription_radar =>
      'Žive obavijesti o cijenama za vrijeme vožnje.';

  @override
  String get featureGroupTitle_sync => 'Sinkronizacija i sigurnosne kopije';

  @override
  String get featureGroupDescription_sync =>
      'Čuvajte podatke na svim uređajima.';

  @override
  String get featureGroupTitle_input => 'Unos i skeniranje';

  @override
  String get featureGroupDescription_input =>
      'Pomoćni alati za bilježenje punjenja goriva.';

  @override
  String get featureGroupTitle_developer => 'Razvijatelj i eksperimentalno';

  @override
  String get featureGroupDescription_developer =>
      'Alati za napredne korisnike i suradnike.';

  @override
  String get featureLabel_voiceFeedback =>
      'Govorne povratne informacije (sinteza govora)';

  @override
  String get featureDescription_voiceFeedback =>
      'Glavni prekidač za sav govorni izlaz — glasovnog trenera vožnje i najave postaja. Kad je isključen, aplikacija nikad ne pokreće sintezu govora.';

  @override
  String get feedbackConsentTitle => 'Poslati izvješće na GitHub?';

  @override
  String get feedbackConsentBody =>
      'Ovo stvara javnu prijavu na našem GitHub repozitoriju s vašom fotografijom i OCR tekstom. Osobni podaci (lokacija, ID računa) ne šalju se. Nastaviti?';

  @override
  String get feedbackConsentContinue => 'Nastavi';

  @override
  String get feedbackConsentCancel => 'Odustani';

  @override
  String get feedbackConsentLater => 'Kasnije';

  @override
  String get feedbackTokenSectionTitle =>
      'Povratne informacije o lošem skeniranju (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Za automatsko otvaranje GitHub prijave iz neuspjelog skeniranja, zalijepite GitHub PAT (opseg `public_repo` na tankstellen repozitoriju). Inače ostaje dostupno ručno dijeljenje.';

  @override
  String get feedbackTokenStatusSet => 'Token konfiguriran';

  @override
  String get feedbackTokenStatusUnset => 'Nema tokena';

  @override
  String get feedbackTokenSet => 'Postavi';

  @override
  String get feedbackTokenClear => 'Očisti';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Osobni pristupni token';

  @override
  String get fillUpMultiFuelHint =>
      'Ovo vozilo može koristiti različita goriva — zabilježite ono koje ste stvarno natočili';

  @override
  String get fillUpGuidanceTitle => 'Najbolje vrijeme za punjenje';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Trenutna cijena je među najjeftinijima zadnjih $days dana — dobro je vrijeme za punjenje.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Cijene su blizu $days-dnevnog maksimuma. Obično su jeftinije $window — razmislite o čekanju.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Cijene rastu — razmislite o punjenju uskoro.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Današnja cijena je oko $days-dnevnog prosjeka.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Mogla bi se uštedjeti oko $amount/L pravovremenim punjenjem.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na temelju $count očitanja cijene',
      one: 'Na temelju 1 očitanja cijene',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'u $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'u ostalim vremenima';

  @override
  String get fillUpGuidanceWeekday1 => 'Ponedjeljkom';

  @override
  String get fillUpGuidanceWeekday2 => 'Utorkom';

  @override
  String get fillUpGuidanceWeekday3 => 'Srijedom';

  @override
  String get fillUpGuidanceWeekday4 => 'Četvrtkom';

  @override
  String get fillUpGuidanceWeekday5 => 'Petkom';

  @override
  String get fillUpGuidanceWeekday6 => 'Subotom';

  @override
  String get fillUpGuidanceWeekday7 => 'Nedjeljom';

  @override
  String get fillUpGuidancePartEarlyMorning => 'rano ujutro';

  @override
  String get fillUpGuidancePartMorning => 'ujutro';

  @override
  String get fillUpGuidancePartAfternoon => 'poslijepodne';

  @override
  String get fillUpGuidancePartEvening => 'navečer';

  @override
  String get fillUpGuidancePartNight => 'noću';

  @override
  String get fillUpOdometerFromCarJustNow => 'Iz vašeg vozila · upravo sada';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Iz vašeg vozila · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Procijenjeno iz zadnjeg očitanja vozila i udaljenosti prijeđene otada ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Zalijepi tekst';

  @override
  String get pasteReceiptDialogTitle => 'Zalijepi tekst računa';

  @override
  String get pasteReceiptDialogHint =>
      'Zalijepite tekst računa za gorivo — e-pošta, SMS ili podijeljeni PDF. Litre, cijena po litri, vrsta goriva, ukupni iznos i postaja čitaju se na uređaju i unaprijed popunjavaju obrazac. Ništa se ne šalje na poslužitelj.';

  @override
  String get pasteReceiptFieldHint => 'Tekst računa';

  @override
  String get pasteReceiptParseAction => 'Popuni unaprijed';

  @override
  String get pasteReceiptNoData =>
      'Iz tog teksta nije bilo moguće pročitati podatke o gorivu — provjerite je li riječ o računu za gorivo i pokušajte ponovno.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verificirano adapterom';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Ne odgovara očitanju adaptera';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Vaš unos: $userL L. Adapter kaže: $adapterL L (razlika od snimanja razine goriva prije/poslije). Koristiti vrijednost adaptera?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Zadrži moj unos';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Koristi vrijednost adaptera';

  @override
  String get scanReceiptNoData =>
      'Nisu pronađeni podaci s računa — pokušajte ponovo';

  @override
  String get scanReceiptSuccess =>
      'Račun skeniran — provjerite vrijednosti. Dodirnite \"Prijavi grešku skeniranja\" ispod ako nešto nije ispravno.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skeniranje nije uspjelo: $error';
  }

  @override
  String get badScanReportTitleReceipt => 'Prijavi grešku skeniranja — Račun';

  @override
  String get badScanReportHint =>
      'Dijelit ćemo fotografiju računa i oba skupa vrijednosti kako bi sljedeće verzije mogle naučiti ovaj raspored.';

  @override
  String get badScanReportFieldBrandLayout => 'Raspored brenda';

  @override
  String get badScanReportFieldTotal => 'Ukupno';

  @override
  String get badScanReportFieldPricePerLiter => 'Cijena/L';

  @override
  String get badScanReportFieldStation => 'Postaja';

  @override
  String get badScanReportFieldFuel => 'Gorivo';

  @override
  String get badScanReportFieldDate => 'Datum';

  @override
  String get badScanReportHeaderField => 'Polje';

  @override
  String get badScanReportHeaderScanned => 'Skenirano';

  @override
  String get badScanReportHeaderYouTyped => 'Upisano';

  @override
  String get badScanReportCreateTicket => 'Stvori prijavu';

  @override
  String get badScanReportOpenInBrowser => 'Otvori u pregledniku';

  @override
  String get badScanReportFallbackToShare =>
      'Slanje nije uspjelo — ručno dijeljenje';

  @override
  String get fillUpWarningDialogTitle => 'Provjerite ovo točenje';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Odabrali ste $chosenFuel, ali ovo vozilo vozi na $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Stanje brojača $entered km niže je od $previous km prethodnog točenja — udaljenost ne može ići unatrag.';
  }

  @override
  String get fillUpWarningGoBack => 'Natrag i ispravi';

  @override
  String get fillUpWarningSaveAnyway => 'Svejedno spremi';

  @override
  String get fillUpSectionWhatTitle => 'Što ste natočili';

  @override
  String get fillUpSectionWhatSubtitle => 'Gorivo, količina, cijena';

  @override
  String get fillUpSectionWhereTitle => 'Gdje ste bili';

  @override
  String get fillUpSectionWhereSubtitle => 'Postaja, kilometar-sat, napomene';

  @override
  String get fillUpImportReceiptLabel => 'Račun';

  @override
  String get fillUpPricePerLiterLabel => 'Cijena po litri';

  @override
  String get vehicleHeaderUntitled => 'Novo vozilo';

  @override
  String get vehicleSectionIdentityTitle => 'Identitet';

  @override
  String get vehicleSectionIdentitySubtitle => 'Naziv i VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Pogon';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Kako se ovo vozilo kreće';

  @override
  String get profileSectionDisplayStations => 'Prikaz i postaje';

  @override
  String get profileSectionRegion => 'Regija';

  @override
  String get fuelEfficiencyCardTitle => 'Trošak po kilometru prema gorivu';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Koja je mješavina goriva zapravo najjeftinija za vožnju';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Najjeftinije po km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Čisto';

  @override
  String get fuelEfficiencyMixBadge => 'Mješavina';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Uglavnom $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Trošak/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Ukupno potrošeno';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count točenja',
      few: '$count točenja',
      one: '1 točenje',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punih spremnika',
      few: '$count puna spremnika',
      one: '1 puni spremnik',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Zabilježite najmanje dva puna spremnika po sastavu da biste odredili najjeftiniji.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Spremnici se grupiraju prema sastavu: spremnik je čist kada jedno gorivo čini najmanje 85 %, inače je mješavina.';

  @override
  String get fuelNameE5 => 'Eurosuper 95';

  @override
  String get fuelNameE10 => 'Eurosuper 95 E10';

  @override
  String get fuelNameE98 => 'Eurosuper 98';

  @override
  String get fuelNameDiesel => 'Eurodizel';

  @override
  String get fuelNameDieselPremium => 'Eurodizel Premium';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'Autoplin (LPG)';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Vodik';

  @override
  String get fuelNameElectric => 'Električni';

  @override
  String get calibrationModeLabel => 'Način kalibracije';

  @override
  String get calibrationModeRule => 'Na temelju pravila';

  @override
  String get calibrationModeFuzzy => 'Rasplinuto';

  @override
  String get calibrationModeTooltip =>
      'Kalibracija na temelju pravila svaki uzorak vožnje dodjeljuje točno jednoj situaciji. Rasplinuta kalibracija ga raspoređuje na sve situacije prema tome koliko dobro svaka odgovara — glađe oko 60 km/h ili promjene nagiba, ali sporije popunjava sve segmente.';

  @override
  String get profileGamificationToggleTitle => 'Prikaži dostignuća i ocjene';

  @override
  String get profileGamificationToggleSubtitle =>
      'Kada je isključeno, značke, ocjene i ikone trofeja su skrivene u cijeloj aplikaciji.';

  @override
  String gdprPolicyLink(int version) {
    return 'Pravila privatnosti (verzija $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Privola dana $date · verzija pravila $version';
  }

  @override
  String get consentNotRecorded => 'Još nije zabilježena nikakva privola';

  @override
  String serverErasurePartial(String tables) {
    return 'Neki podaci na poslužitelju nisu mogli biti izbrisani: $tables. Pokušajte ponovno ili kontaktirajte razvojnog programera s ovim popisom.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Neki lokalni podaci nisu mogli biti izbrisani: $steps. Ponovno pokrenite aplikaciju i pokušajte ponovno.';
  }

  @override
  String get myCommunityReportsTitle => 'Moje prijave zajednici';

  @override
  String get myCommunityReportsEmpty => 'Niste poslali nijednu prijavu';

  @override
  String get deleteReportTooltip => 'Izbriši ovu prijavu';

  @override
  String get reportDeleted => 'Prijava izbrisana';

  @override
  String get reportDeleteFailed => 'Prijavu nije bilo moguće izbrisati';

  @override
  String get tileProxyToggleTitle =>
      'Učitavaj pločice karte putem Sparkilo proxyja';

  @override
  String get tileProxyToggleSubtitle =>
      'Uključeno: prikazani dio karte i vaša IP adresa stižu na EU poslužitelj razvojnog programera, koji dohvaća pločice s OpenStreetMapa. Isključeno: pločice se učitavaju izravno s tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle => 'Učitavaj logotipe marki s interneta';

  @override
  String get remoteLogosToggleSubtitle =>
      'Zadano isključeno: prikazuju se ugrađene zamjenske slike. Uključeno: logotipi se dohvaćaju s logo.clearbit.com, koji vidi vašu IP adresu.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName spremljeno u Downloads — $count datoteka unutra';
  }

  @override
  String get privacyExportAllFailed =>
      'Izvoznu datoteku nije bilo moguće zapisati';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Upravlja $operator · Supabase, EU (Frankfurt) · sinkronizira favorite, upozorenja, vozila uklj. VIN, točenja goriva, ocjene, prijave i — ako to uključite — putovanja s GPS-om';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Vi ste voditelj obrade — vaš vlastiti Supabase projekt, mi ga nikada ne vidimo';

  @override
  String get syncModeJoinControllerNotice =>
      'Vlasnik zajedničke baze podataka voditelj je obrade vaših podataka';

  @override
  String get ugcPublicNoticeTitle => 'Podijeljeno s drugim korisnicima';

  @override
  String get ugcPublicNoticeBody =>
      'Ovo se pohranjuje u bazi za sinkronizaciju pod vašim pseudonimnim korisničkim ID-om. U Sparkilo zajednici to može pročitati svaki prijavljeni korisnik. Možete to izbrisati u bilo kojem trenutku u TankSync → Transparentnost podataka.';

  @override
  String get blockedAuthorsTitle => 'Blokirani korisnici';

  @override
  String get blockedAuthorsDescription =>
      'Sadržaj koji dijele ovi korisnici skriven je na ovom uređaju. Deblokirajte ih da biste ga ponovno vidjeli.';

  @override
  String get blockedAuthorsEmpty => 'Nema blokiranih korisnika';

  @override
  String get blockedAuthorsUnblock => 'Deblokiraj';

  @override
  String get coachingGpsLiftOff => 'Otpusti gas';

  @override
  String get coachingGpsAnticipateBrake => 'Predvidi';

  @override
  String get coachingGpsSmoothAccel => 'Glatko ubrzanje';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Trag pokriva $pct % — najdulja praznina $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Trag pokriva $pct % — nema otkrivenih praznina';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'aplikacija u pozadini';

  @override
  String get gpsCoverageAttrOsBatching => 'sustav je grupirao položaje';

  @override
  String get gpsCoverageAttrGateRejected => 'položaji filtrirani';

  @override
  String get gpsCoverageAttrDeliveryStall => 'kašnjenje isporuke';

  @override
  String get gpsCoverageAttrSignalLoss => 'gubitak signala';

  @override
  String get gpsCoverageAttrUnknown => 'nepoznat uzrok';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Aplikacija je bila u pozadini bez usluge u prednjem planu, pa je sustav ograničio GPS. Držite zaslon uključen tijekom snimanja ili uključite snimanje u pozadini kada bude dostupno.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Sustav je isporučio položaje kasno i u paketima; trag je naknadno popunjen, pa je zapravo izgubljeno malo podataka.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Šumoviti položaji na ovoj dionici filtrirani su kako bi udaljenost ostala poštena.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Položaji su određeni na vrijeme, ali su do aplikacije stigli kasno — telefon je bio zauzet (često ponovno povezivanje Bluetootha). Prijem je bio dobar.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'GPS prijem je nestao — obično tunel, natkrivena garaža ili gusto gradsko područje.';

  @override
  String get gpsCoverageHintUnknown =>
      'Ova vožnja ne sadrži podatke o stanju aplikacije tijekom praznine, pa se uzrok ne može utvrditi.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'smetnja od ponovnog povezivanja OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Praznina se poklapa s epizodom ponovnog povezivanja OBD2 — veza s adapterom se oporavljala dok je prijem GPS-a stao. Popravak veze s adapterom popravlja i trag.';

  @override
  String get gpsDiagnosticsTitle => 'Dijagnostika GPS uzorkovanja';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps prekida',
      one: '1 prekid',
      zero: 'bez prekida',
    );
    return '$count uzoraka · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Srednji interval: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Snimljeno za vrijeme snimanja za provjeru GPS kadence tijekom spavanja telefona.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Najveći razmak: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Nastavljeno';

  @override
  String get gpsLifecyclePaused => 'Pauzirano';

  @override
  String get gpsLifecycleInactive => 'Neaktivno';

  @override
  String get gpsKpiVerdictGood => 'Učinkovita';

  @override
  String get gpsKpiVerdictModerate => 'Umjerena';

  @override
  String get gpsKpiVerdictAggressive => 'Agresivna';

  @override
  String get gpsKpiInterpretationGood =>
      'Glatka, štedljiva vožnja — tako izgleda učinkovitost.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Prilično uobičajena vožnja — malo mekši gas uštedio bi više.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energetski zahtjevna vožnja — popuštanje gasa i više kotrljanja smanjili bi potrošnju.';

  @override
  String get gpsMatrixMaturityCold => 'Hladna';

  @override
  String get gpsMatrixMaturityWarming => 'Zagrijava se';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergirana';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS matrica se još zagrijava ($count dorada do sada). Procjene su privremene.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS matrica konvergira ($count točenja). Procjene su upotrebljive uz mogući otklon nekoliko %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS matrica je konvergirala ($count točenja). Procjene unutar ~2 % stvarne potrošnje.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS procjena (~) — nema senzora goriva na ovom putu. Iznos je modeliran na temelju brzine i kalibracije vašeg vozila; točnost se poboljšava kako matrica sazrijeva.';

  @override
  String get gpsRoadUseCardTitle => 'Kako ste koristili cestu';

  @override
  String get gpsRoadUseSpeedSection => 'Gdje ste proveli vrijeme';

  @override
  String get gpsRoadUseSpeedIdle => 'Stajanje (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Grad (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Otvorena cesta (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Brzo (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Kako ste se kretali';

  @override
  String get gpsRoadUsePhaseAccel => 'Ubrzavanje';

  @override
  String get gpsRoadUsePhaseSteady => 'Stalna brzina';

  @override
  String get gpsRoadUsePhaseCoast => 'Kotrljanje';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Puno kotrljanja — puštanje automobila da se kotrlja umjesto kočenja štedi gorivo. Odlično.';

  @override
  String get gpsRoadUseSource => 'Iz vašeg GPS traga';

  @override
  String get hapticEcoCoachSettingTitle =>
      'Eko treneriranje u stvarnom vremenu';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Nježna haptika + savjet na ekranu kada snažno ubrzate za vrijeme krstarenja';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Polako s gasom — klizanje više štedi';

  @override
  String highwayViaExit(String ref, String km) {
    return 'preko izlaza $ref · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigiraj do $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Ukloni $name iz favorita';
  }

  @override
  String get showOnMapSemanticLabel => 'Prikaži postaje na karti';

  @override
  String get searchResultsSemanticLabel => 'Rezultati pretraživanja';

  @override
  String get searchCriteriaSemanticLabel =>
      'Sažetak kriterija pretraživanja. Dodirnite za uređivanje.';

  @override
  String get noFavoritesSemanticLabel =>
      'Još nema favorita. Dodirnite zvjezdicu postaje da biste je spremili kao favorit.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Postaja je otvorena',
      'false': 'Postaja je zatvorena',
      'other': 'Postaja je zatvorena',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Država $name, odabrano',
      'false': 'Država $name',
      'other': 'Država $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Jezik $name, odabrano',
      'false': 'Jezik $name',
      'other': 'Jezik $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sortiraj po $option, odabrano',
      'false': 'Sortiraj po $option',
      'other': 'Sortiraj po $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Gorivo $type, odabrano',
      'false': 'Gorivo $type',
      'other': 'Gorivo $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Stanica za punjenje $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Štit privatnosti s kapljicom goriva';

  @override
  String get globeIllustrationSemantic =>
      'Globus s oznakama benzinskih postaja';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Crpka za gorivo s prikazom cijena';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, izvor podataka: $provider, $keyRequirement, vrste goriva: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Potreban je API ključ';

  @override
  String get countryInfoNoKeyNeeded => 'Besplatno, ključ nije potreban';

  @override
  String countryInfoDataSource(String provider) {
    return 'Podaci: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Vrste goriva: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon ključ';

  @override
  String get anonKeyHideTooltip => 'Sakrij ključ';

  @override
  String get anonKeyShowTooltip => 'Prikaži ključ za provjeru';

  @override
  String anonKeyTooLong(int length) {
    return 'Ključ je predug ($length znakova) — provjerite ima li extra teksta';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Ključ izgleda ispravno ($length znakova)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Ključ bi trebao biti JWT (zaglavlje.sadržaj.potpis)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Ključ je možda skraćen ($length od ~208 očekivanih znakova)';
  }

  @override
  String get anonKeyExceedsMax => 'Ključ premašuje maksimalnu duljinu';

  @override
  String get qrShareTitle => 'Dijeli svoju bazu podataka';

  @override
  String get qrShareSubtitle => 'Drugi mogu skenirati ovaj QR kod za spajanje';

  @override
  String get qrShareCopyAsText => 'Kopiraj kao tekst';

  @override
  String get authInfoTitle => 'Zašto stvoriti račun?';

  @override
  String get authInfoBenefit1 =>
      '• Sinkroniziraj favourite, upozorenja i spremljene rute na svim uređajima';

  @override
  String get authInfoBenefit2 =>
      '• Pripremite rutu na telefonu, koristite je u autu';

  @override
  String get authInfoBenefit3 =>
      '• Nijedan podatak se ne dijeli s trećim stranama';

  @override
  String get authInfoBenefit4 =>
      '• Račun možete obrisati u bilo kojem trenutku';

  @override
  String get apiKeySetupTitle => 'Postavljanje API ključa (neobavezno)';

  @override
  String get apiKeySetupDescription =>
      'Registrirajte se za besplatni API ključ ili preskočite za istraživanje aplikacije s demo podacima.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider registracija';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Unosom API ključa prihvaćate uvjete korištenja $provider. Redistribucija podataka je zabranjena.';
  }

  @override
  String get calculatorDistanceHint => 'npr. 150';

  @override
  String get calculatorConsumptionHint => 'npr. 7.0';

  @override
  String get calculatorPriceHint => 'npr. 1.899';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (eksperimentalno)';

  @override
  String get glideCoachBetaSubtitle =>
      'Suptilna haptika pri usporavanju pred crvenim svjetlom. Zadano isključeno — rizik od odvraćanja pažnje.';

  @override
  String get consentSyncTripsTitle => 'Sinkroniziraj snimanja vožnji';

  @override
  String get consentSyncTripsSubtitle =>
      'Sigurnosno kopirajte OBD2 + GPS vožnje na TankSync. Između uređaja, po izboru.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Omogućite Sinkronizaciju u oblaku gore za sigurnosno kopiranje vožnji.';

  @override
  String get consentSyncTripsAnonymousHint =>
      'Vožnje se sigurnosno kopiraju pod anonimnim računom ovog uređaja. Prijavite se e-poštom da im pristupite s drugih uređaja.';

  @override
  String get dialogOk => 'U redu';

  @override
  String get invalidLinkTitle => 'Nevažeća veza';

  @override
  String invalidLinkBody(String path) {
    return 'Veza \"$path\" nije valjana.';
  }

  @override
  String get home => 'Početna';

  @override
  String get accelBrakeCardTitle => 'Ubrzavanje i kočenje';

  @override
  String get accelBrakeHardAccel => 'Nagla ubrzavanja';

  @override
  String get accelBrakeHardBrake => 'Naglo kočenje';

  @override
  String get accelBrakeSharpCorner => 'Oštri zavoji';

  @override
  String get accelBrakeSource => 'Iz senzora kretanja telefona';

  @override
  String lessonHardBrake(String count) {
    return '$count događaja naglog kočenja';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Predvidite zaustavljanja i ranije dignite nogu s papučice — naglo kočenje baca gorivo koje ste upravo potrošili za ubrzavanje.';

  @override
  String lessonSharpCornering(String count) {
    return '$count oštrih zavoja';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Usporite prije zavoja, ne u njemu — naglo skretanje gubi brzinu koju zatim morate obnavljati.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Zadnjih $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Jedinica potrošnje';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Kako se potrošnja goriva prikazuje u cijeloj aplikaciji';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automatski ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Prozor potrošnje uživo';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Prosjek vrijednosti uživo u zadnjih nekoliko sekundi — dulji je mirniji, kraći reagira brže';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'proc. $unit';
  }

  @override
  String get locationConsentTitle => 'Pristup lokaciji';

  @override
  String get locationConsentSubtitle =>
      'Ova aplikacija želi koristiti vašu lokaciju za pronalaženje benzinskih postaja u blizini.';

  @override
  String get locationConsentWhatHappens =>
      'Što se događa s podacima o vašoj lokaciji:';

  @override
  String get locationConsentBulletApi =>
      'Vaše se koordinate šalju API-ju cijena goriva radi pronalaženja obližnjih postaja.';

  @override
  String get locationConsentBulletNoServer =>
      'Vaša se lokacija ne pohranjuje ni na jednom poslužitelju — poslužitelja nema.';

  @override
  String get locationConsentBulletNoTracking =>
      'Podaci o lokaciji ne koriste se za oglašavanje, analitiku ni praćenje.';

  @override
  String get locationConsentRevoke =>
      'Pristup lokaciji možete opozvati u bilo kojem trenutku u postavkama sustava. Alternativno, pretražujte prema poštanskom broju.';

  @override
  String get locationConsentLegalBasis =>
      'Pravna osnova: čl. 6. st. 1. t. (a) GDPR-a (privola)';

  @override
  String get loyaltySettingsTitle => 'Kartice gorivnog kluba';

  @override
  String get loyaltySettingsSubtitle =>
      'Primijenite popust lojalnosti na prikazane cijene';

  @override
  String get loyaltyMenuTitle => 'Kartice gorivnog kluba';

  @override
  String get loyaltyMenuSubtitle =>
      'Primijenite popuste po litri od Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Dodaj karticu';

  @override
  String get loyaltyAddCardSheetTitle => 'Dodaj karticu gorivnog kluba';

  @override
  String get loyaltyBrandLabel => 'Brand';

  @override
  String get loyaltyCardLabelLabel => 'Oznaka (neobavezno)';

  @override
  String get loyaltyDiscountLabel => 'Popust (po litri)';

  @override
  String get loyaltyDiscountInvalid => 'Unesite pozitivan broj';

  @override
  String get loyaltyDeleteConfirmTitle => 'Obrisati karticu?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Ova kartica prestat će primjenjivati popust.';

  @override
  String get loyaltyEmptyTitle => 'Još nema kartica gorivnog kluba';

  @override
  String get loyaltyEmptyBody =>
      'Dodajte karticu za automatsku primjenu popusta po litri na odgovarajuće postaje.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Otkriveno povećanje RPM-a u mirovanju';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'RPM u mirovanju porastao je za $percent% u posljednjih $tripCount vožnji. Mogući rani znak začepljenog filtera zraka ili pomaka senzora.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Moguće ograničenje usisnog sustava';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Potrošnja goriva pri krstarenju pala je za $percent% u posljednjih $tripCount vožnji. Mogući znak začepljenog filtera zraka ili ograničenog usisnog sustava — vrijedi provjeriti.';
  }

  @override
  String get maintenanceActionDismiss => 'Odbaci';

  @override
  String get maintenanceActionSnooze => 'Odgodi 30 dana';

  @override
  String get consumptionMonthlyInsightsTitle => 'Ovaj mjesec naspram prošlog';

  @override
  String get consumptionMonthlyTripsLabel => 'Vožnje';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Trajanje vožnje';

  @override
  String get consumptionMonthlyDistanceLabel => 'Udaljenost';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Prosj. potrošnja';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Potrebno je najmanje 3 vožnje po mjesecu za usporedbu';

  @override
  String get consumptionMonthlyClimbLabel => 'Uspon';

  @override
  String get obd2CapabilitySectionTitle => 'Sposobnosti adaptera';

  @override
  String get obd2CapabilityStandardOnly => 'Standardno';

  @override
  String get obd2CapabilityOemPids => 'OEM PID-ovi';

  @override
  String get obd2CapabilityFullCan => 'Puni CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Za točne litre u spremniku na Peugeot/Citroën vozilima, aplikacija podržava OBDLink MX+/LX/CX (STN čip).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2 dijagnostički preklopnik omogućen';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 dijagnostički preklopnik onemogućen';

  @override
  String get obd2DebugOverlayClearButton => 'Očisti';

  @override
  String get obd2DebugOverlayCloseButton => 'Zatvori';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 trag';

  @override
  String get obd2DiagnosticShareLabel => 'Podijeli dijagnostički zapisnik';

  @override
  String get obd2DebugLoggingTitle =>
      'Zapisivanje za otklanjanje pogrešaka OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Zabilježite svaku OBD2 sesiju — povezivanje, handshake, prekide podataka i ponovna povezivanja — u izvozivi XML zapisnik. Prema zadanim postavkama isključeno.';

  @override
  String get obd2DebugSessionShareLabel => 'Podijeli zapisnik OBD2 sesije';

  @override
  String get obd2DiagnosticsTitle => 'OBD2 zdravlje komunikacije';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops prekida',
      one: '1 prekid',
      zero: 'bez prekida',
    );
    return '$percent% dovršeno · $duty% korištenosti · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Životni ciklus veze';

  @override
  String get obd2DiagnosticsPidSection => 'Ishodi po PID-u';

  @override
  String get obd2DiagnosticsReconnectSection =>
      'Telemetrija ponovnog povezivanja';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts pokušaja ponovnog povezivanja · $successes uspješnih · $transitions prijelaza · $disconnects klasificiranih prekida';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'U ovoj je sesiji aktiviran pričuvni način rada samo s GPS-om.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Zdravlje raspoređivača';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Potpunost';

  @override
  String get obd2DiagnosticsSupportSection => 'Otkriveni podržani PID-ovi';

  @override
  String get obd2DiagnosticsFuelSection => 'Sažetak razine goriva';

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
    return '$attempts pokušaja · $successes uspješnih · $drops prekida · vrijeme spajanja p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Ponovno spajanje: $silent tih · $visible vidljivih';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz takt · $skips preskakanja protupritiska · $demotions degradacija';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Razina dinamike izgladnjela — RPM / brzina pala ispod praga upravljača.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Ukupno $percent% · aktivno korištenost $duty%';
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
    return '$supported podržano · $unsupported nije podržano · $unknown nepoznato';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Sumnjivo $suspicious od $total uzoraka';
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
    return '$pid: $polled ispitano · $ok uspješno · $noData ND · $timeout TO · $error pogrešaka · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Transkript inicijalizacije ključa';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokol $protocol · $start · firmware $firmware · $tier · $pids PID-ova';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'toplo';

  @override
  String get obd2DiagnosticsInitCold => 'hladno';

  @override
  String get obd2DiagnosticsEmpty =>
      'Još nije snimljena OBD2 sesija — spojite adapter i snimite put s uključenim načinom Razvijatelj.';

  @override
  String get obd2DiagnosticsExplain =>
      'Snimljeno za vrijeme snimanja radi debugiranja komunikacije ključ↔aplikacija — prikuplja se samo u načinu Razvijatelj.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 zdravlje komunikacije';

  @override
  String get obd2HealthNavLabel => 'OBD2 zdravlje komunikacije';

  @override
  String get obd2HealthLiveSection => 'Živa sesija';

  @override
  String get obd2HealthHistorySection => 'Nedavne sesije';

  @override
  String get obd2HealthDownloadJson => 'Preuzmi kao JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Preuzmi samo zapis inicijalizacije';

  @override
  String get obd2HealthDownloadError =>
      'Dijagnostičku datoteku nije bilo moguće spremiti';

  @override
  String get obd2TestAdapterLabel => 'Adapter za testiranje';

  @override
  String get obd2TestAdapterScanOption => 'Potraži adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Povezivanje s $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Pokreni test adaptera';

  @override
  String get obd2TestRunButton => 'Pokreni test adaptera';

  @override
  String get obd2TestRunPassed => 'Test adaptera prošao';

  @override
  String get obd2TestRunFailed => 'Test adaptera nije prošao';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — motor ugašen; pokrenite motor za čitanje podataka uživo';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed od $total koraka uspješno · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Zaustavite aktivno snimanje prije pokretanja testa adaptera.';

  @override
  String get obd2TestStepScan => 'Skeniraj adapter';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth telefona';

  @override
  String get obd2TestStepConnect => 'Spoji i inicijaliziraj';

  @override
  String get obd2TestStepInfo => 'Info o adapteru';

  @override
  String get obd2TestStepSupportedPids => 'Podržani PID-ovi';

  @override
  String get obd2TestStepProtocol => 'Protokol vozila';

  @override
  String get obd2TestStepSampleReads => 'Uzorci očitavanja';

  @override
  String get obd2TestStepSoak => 'Dugotrajno očitavanje';

  @override
  String get obd2TestStepReconnect => 'Test ponovnog spajanja';

  @override
  String get obd2TestStepDisconnect => 'Odspoji';

  @override
  String get obd2TestStatusOk => 'U redu';

  @override
  String get obd2TestStatusTimeout => 'Vremenski odmak';

  @override
  String get obd2TestStatusGarbage => 'Nečitljiv odgovor';

  @override
  String get obd2TestStatusNoResponse => 'Nema odgovora';

  @override
  String get obd2TestStatusFail => 'Neuspješno';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'nepoznato — zadano BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Nedavni pokušaji povezivanja';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Još nema zabilježenih pokušaja povezivanja.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Preuzmi zapisnik povezivanja';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Preuzmi sve zapisnike povezivanja';

  @override
  String get obd2HealthConnectOrigin => 'Izvor';

  @override
  String get obd2HealthConnectTransport => 'Prijenos';

  @override
  String get obd2HealthConnectOutcome => 'Ishod';

  @override
  String get obd2HealthConnectScanList => 'Pronađeni uređaji';

  @override
  String get obd2HealthConnectSteps => 'Koraci';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Nepoznat adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Sesija snimljena · $samples uzoraka motora · $percent% pokrivenosti';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection =>
      'Što je ova vožnja zabilježila';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples od $total uzoraka sadržavalo je podatke motora ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Uspostava protokola: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Sesija završena: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Trajanje sesije: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Podaci o potrošnji dolaze s adaptera, a ne iz GPS procjena.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Detalji komunikacije po PID-u za ovu vožnju nisu zabilježeni. Za njihovo prikupljanje uključite razvojni način prije snimanja.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nije moguće dosegnuti \'$adapterName\' — odaberite drugi adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Ostali Bluetooth uređaji';

  @override
  String get obd2PickerTapToTry => 'Neprepoznat — dodirnite za pokušaj';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone radi samo s Bluetooth LE adapterima. Adapter koji podržava samo Classic (npr. vLinker BM, Konnwei KW902) mora se koristiti na Androidu.';

  @override
  String get obd2PairingConfirmHint =>
      'Potvrdite zahtjev za uparivanje na telefonu';

  @override
  String get obd2ScanEmptyTitle => 'Adapter nije pronađen';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth je uključen i dopuštenja su dodijeljena. Provjerite je li adapter ukopčan u OBD2 priključak i je li kontakt uključen, zatim ponovno pretražite.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Ovaj uređaj nema Bluetooth Low Energy hardver, pa se ne može povezati s OBD2 adapterom.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth je isključen. Uključite ga da biste potražili svoj adapter.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo treba dopuštenje za Bluetooth da bi pronašao vaš adapter.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Dopuštenje za Bluetooth trajno je odbijeno. Dodijelite ga u postavkama sustava da biste potražili adapter.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Usluge lokacije isključene su na ovom uređaju. Android ih zahtijeva za traženje Bluetooth adaptera — nikakva se lokacija ne bilježi niti dijeli.';

  @override
  String get obd2ScanOpenSettings => 'Otvori postavke';

  @override
  String get obd2WaitingForEngineBanner => 'Čekanje motora — snimanje GPS-om';

  @override
  String get obd2StartEngineToReconnect =>
      'Pokrenite motor za ponovno povezivanje';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motor je ugašen — pokrenite ga za ponovno povezivanje';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motor ugašen već $minutes min — zaustaviti snimanje?';
  }

  @override
  String get obd2ParkedPromptStop => 'Zaustavi';

  @override
  String get obd2ParkedPromptKeep => 'Nastavi';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motor ugašen prvih $head i zadnjih $tail ove vožnje — pokrivenost se mjeri dok motor radi.';
  }

  @override
  String get obd2ReconnectInProgress =>
      'Ponovno povezivanje s vašim OBD2 adapterom…';

  @override
  String get obd2StatusEngineOff => 'OBD2 pauziran — motor ugašen';

  @override
  String get obd2StatusEngineOffBody =>
      'Adapter je bio dostupan, ali sabirnica vozila ostala je tiha, pa je automatsko ponovno povezivanje pauzirano. Nastavlja se kad krenete voziti ili ponovno otvorite aplikaciju — ili se povežite odmah.';

  @override
  String get obd2StatusReconnectNow => 'Poveži se odmah';

  @override
  String get autoRecordNotificationTitle => 'Automatsko snimanje vožnji';

  @override
  String get autoRecordNotificationText => 'Čekanje vašeg OBD2 adaptera';

  @override
  String get obd2ResetConnection => 'Resetiraj vezu';

  @override
  String get obd2ResetConnectionDone =>
      'Adapter resetiran — veza ponovno uspostavljena';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapter resetiran — ponovno povezivanje u pozadini';

  @override
  String get ocrTesterTitle => 'OCR tester';

  @override
  String get ocrTesterNavLabel => 'OCR tester';

  @override
  String get ocrTesterExplain =>
      'Pokrenite OCR cjevovod pumpe/računa na odabranoj fotografiji i pregledajte svaki korak — dostupno samo u načinu Razvijatelj.';

  @override
  String get ocrTesterCapture => 'Snimi';

  @override
  String get ocrTesterPickImage => 'Odaberi sliku';

  @override
  String get ocrTesterRun => 'Pokreni';

  @override
  String get ocrTesterCountry => 'Država';

  @override
  String get ocrTesterCountryNone => 'Zadano (bez profila)';

  @override
  String get ocrTesterNoImage =>
      'Odaberite ili snimite sliku, zatim Pokrenite.';

  @override
  String get ocrTesterRunning => 'Pokretanje OCR-a…';

  @override
  String get ocrTesterOverlaySection => 'Prekrivač blokova';

  @override
  String get ocrTesterStepsSection => 'Koraci cjevovoda';

  @override
  String get ocrTesterLegendLabel => 'Oznaka';

  @override
  String get ocrTesterLegendNumeric => 'Numeričko';

  @override
  String get ocrTesterLegendNoise => 'Šum';

  @override
  String get ocrTesterLegendDerived => 'Izvedeno';

  @override
  String get ocrTesterStageGlare => 'Snimanje / sjaj';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klasificiraj';

  @override
  String get ocrTesterStageAssemble => 'Sastavi';

  @override
  String get ocrTesterStageAnchor => 'Sidro';

  @override
  String get ocrTesterStageFallback => 'Pričuva';

  @override
  String get ocrTesterStageCrossCheck => 'Unakrsna provjera';

  @override
  String get ocrTesterStageConfidence => 'Pouzdanost';

  @override
  String get ocrTesterStageGate => 'Prolaz';

  @override
  String get ocrTesterStageBrand => 'Brend';

  @override
  String get ocrTesterStageOverrides => 'Prepisivanja';

  @override
  String get ocrTesterStageReconcile => 'Uskladi';

  @override
  String get ocrTesterStageResult => 'Rezultat';

  @override
  String get ocrTesterChipRead => 'PROČITANO';

  @override
  String get ocrTesterChipDerived => 'IZVEDENO';

  @override
  String get ocrTesterGateAccepted => 'Prihvaćeno';

  @override
  String get ocrTesterGateRejected => 'Odbijeno';

  @override
  String get ocrTesterFallbackBanner =>
      'Polje je oporavljeno pričuvnom metodom magnitude — provjerite ga.';

  @override
  String get ocrTesterStageNoData => 'Faza nije pokrenuta.';

  @override
  String get ocrTesterCopyJson => 'Kopiraj kao JSON';

  @override
  String get ocrTesterExportPackage => 'Izvezi paket';

  @override
  String get ocrTesterCopied => 'OCR trag kopiran u međuspremnik.';

  @override
  String get ocrTesterExported => 'OCR paket spreman u mapu Downloads.';

  @override
  String get onboardingObd2StepTitle => 'Spojite vaš OBD2 adapter';

  @override
  String get onboardingObd2StepBody =>
      'Priključite OBD2 adapter u priključak automobila i uključite paljenje. Pročitat ćemo VIN i popuniti detalje motora za vas.';

  @override
  String get onboardingObd2ConnectButton => 'Spoji adapter';

  @override
  String get onboardingObd2SkipButton => 'Možda kasnije';

  @override
  String get onboardingObd2ReadingVin => 'Čitanje VIN-a…';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nije moguće spojiti se na adapter. Možete ponoviti pokušaj ili preskočiti.';

  @override
  String get onboardingPickUseMode => 'Odaberite način korištenja za nastavak.';

  @override
  String get onboardingObd2LaterNote =>
      'Bluetooth OBD2 adapter možete upariti bilo kada kasnije sa zaslona vozila kako biste snimali vožnje i čitali podatke motora.';

  @override
  String get openHoursUnknown => 'Radno vrijeme nepoznato';

  @override
  String get open24Hours => 'Otvoreno 24 sata';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Ponedjeljak';

  @override
  String get dayTue => 'Utorak';

  @override
  String get dayWed => 'Srijeda';

  @override
  String get dayThu => 'Četvrtak';

  @override
  String get dayFri => 'Petak';

  @override
  String get daySat => 'Subota';

  @override
  String get daySun => 'Nedjelja';

  @override
  String get dayShortMon => 'Pon';

  @override
  String get dayShortTue => 'Uto';

  @override
  String get dayShortWed => 'Sri';

  @override
  String get dayShortThu => 'Čet';

  @override
  String get dayShortFri => 'Pet';

  @override
  String get dayShortSat => 'Sub';

  @override
  String get dayShortSun => 'Ned';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Državni praznici';

  @override
  String get closedLabel => 'Zatvoreno';

  @override
  String get openingHoursNotAvailable => 'Radno vrijeme nije dostupno';

  @override
  String get showAllHours => 'Prikaži sva radna vremena';

  @override
  String get showLessHours => 'Prikaži manje';

  @override
  String get openStateUnknown => 'Nepoznato';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Postaja je otvorena',
      'false': 'Postaja je zatvorena',
      'other': 'Stanje otvorenosti nepoznato',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Pristup kameri';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Ova aplikacija želi koristiti vašu kameru za čitanje računa, zaslona crpki i QR kodova.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Što se događa sa slikom s kamere:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'Slika se koristi samo za čitanje računa, zaslona crpke ili QR koda — prepoznavanje se izvodi na vašem uređaju.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'Fotografija se odbacuje nakon skeniranja.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Ništa se ne prenosi osim ako ne pošaljete prijavu pogrešnog skeniranja i ne potvrdite je.';

  @override
  String get permissionRationaleBluetoothTitle => 'Pristup Bluetoothu';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Ova aplikacija želi koristiti Bluetooth za povezivanje s vašim OBD2 adapterom.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Što se događa s Bluetoothom:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth se koristi samo za pronalaženje vašeg OBD2 adaptera i komunikaciju s njim.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Identifikator adaptera ostaje na vašem uređaju — sinkronizira se samo putem TankSynca kao dio profila vozila.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'Na Androidu 11 i starijim verzijama sustav traži i lokaciju jer se Bluetooth skeniranje ondje smatra dozvolom za lokaciju.';

  @override
  String get permissionRationaleNotificationsTitle => 'Obavijesti';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Ova aplikacija želi vam slati obavijesti o upozorenjima o cijenama i statusu snimanja putovanja.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Što se događa s obavijestima:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Obavijesti se koriste za lokalna upozorenja o cijenama i status snimanja putovanja.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Generiraju se na vašem uređaju — ništa ne napušta uređaj.';

  @override
  String get permissionRationaleRevoke =>
      'To možete opozvati u bilo kojem trenutku u postavkama uređaja.';

  @override
  String get permissionRationaleLegalBasis =>
      'Pravna osnova: čl. 6. st. 1. t. (a) GDPR-a (privola)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'proci. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Procijenjena vrijednost (~) — nema senzora goriva na ovom putu, pa je L/100 km modeliran iz GPS brzine i kalibracije vašeg vozila. Vrijednost je aproksimativna (tipično ±10–30 %, poboljšava se kako kalibracija sazrijeva), nije izmjereno očitanje.';

  @override
  String get tripRecordingPipElapsedCaption => 'proteklo';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: procjene potrošnje ponovno usidrene na pumpu ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Otvoriti skeniranu poveznicu?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Ovaj QR kod vodi na $host. Otvarajte samo poveznice kojima vjerujete.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Otvori poveznicu';

  @override
  String get qrLaunchConfirmCancel => 'Odustani';

  @override
  String get radarPinHelpTitle => 'O prikačivanju';

  @override
  String get radarPinHelpBody =>
      'Prikačivanje drži zaslon uključenim i skriva sistemske trake kako bi prikaz najbliže postaje ostao čitljiv na nosaču upravljačke ploče. Dodirnite ponovo za otpuštanje. Automatski se otpušta kad radar stane.';

  @override
  String get radarAutoPinTitle => 'Uvijek prikači kad se radar pokrene';

  @override
  String get radarAutoPinSubtitle =>
      'Automatski prikači radar svaki put umjesto da ga svaki put dodirnete. Troši više baterije.';

  @override
  String get radarScopeShowScope => 'Prikaz radara';

  @override
  String get radarScopeShowList => 'Prikaz popisa';

  @override
  String get alertsRadiusFrequencyLabel => 'Učestalost provjere';

  @override
  String get alertsRadiusFrequencyDaily => 'Jednom dnevno';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Dva puta dnevno';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tri puta dnevno';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Četiri puta dnevno';

  @override
  String get radiusAlertPickOnMap => 'Odaberi na karti';

  @override
  String get radiusAlertMapPickerTitle => 'Odaberi centar upozorenja';

  @override
  String get radiusAlertMapPickerConfirm => 'Potvrdi';

  @override
  String get radiusAlertMapPickerCancel => 'Odustani';

  @override
  String get radiusAlertMapPickerHint =>
      'Povucite kartu za pozicioniranje centra upozorenja';

  @override
  String get reconcileWorkflowTitle => 'Uskladi gorivo';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Pronašli smo razliku od $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Natočili ste $pumped L, ali vaša snimljena putovanja bilježe samo $consumed L. Preostaje $gap L neobjašnjenih.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'To obično znači da neko vožnje nije snimljeno (adapter je bio odspojeni ili aplikacija zatvorena), ili nedostaje punjenje goriva ili je pogrešno uneseno.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Dok se ovo ne razriješi, ukupno gorivo i ukupno putovanja neće se slagati.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Pomozite nam pripisati razliku';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Jesu li sva punjena goriva za ovaj rezervoar potpuna i točna?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Jesu li sve vožnje snimljene?';

  @override
  String get reconcileWorkflowAnswerYes => 'Da';

  @override
  String get reconcileWorkflowAnswerNo => 'Ne';

  @override
  String get reconcileWorkflowPathAHint =>
      'Nedostaje punjenje ili je pogrešno — dodajemo korekciju kako bi punjenja bila točna.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Punjenja su točna, ali neka vožnja nije snimljena — dodajemo virtualni put za propuštenu udaljenost.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Korekcija litara';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Koliko daleko je bila nesnimljena vožnja? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Odluči kasnije';

  @override
  String get reconcileWorkflowBack => 'Natrag';

  @override
  String get reconcileWorkflowNext => 'Dalje';

  @override
  String get reconcileWorkflowApply => 'Primijeni';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtualni put — dodirnite za uređivanje';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Uredi virtualni put';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Ovaj put je dodan kako bi se prikazalo gorivo korišteno tijekom vožnje bez snimanja. Prilagodite udaljenost ili gorivo, ili ga izbrišite.';

  @override
  String get reconcileVirtualTrajetDelete => 'Izbriši virtualni put';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Nerazriješena razlika goriva/puta od $gap L — dodirnite za razrješavanje';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Razriješi nerazriješenu razliku goriva i puta';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesija';

  @override
  String get settingsSearchHint => 'Pretraži postavke';

  @override
  String settingsSearchNoResults(String query) {
    return 'Nijedna postavka ne odgovara „$query”';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profili i regija';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Država, jezik, gorivo, radijus pretrage, planiranje rute';

  @override
  String get settingsTopicProfilesKeywords =>
      'profil, država, jezik, gorivo, radijus, poštanski broj, ruta, dom, ocjena, početni zaslon, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Vozila i OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Vaši automobili, veličina spremnika, uparivanje OBD2 adaptera';

  @override
  String get settingsTopicVehiclesKeywords =>
      'vozilo, auto, obd, obd2, adapter, bluetooth, spremnik, motor, vin, kalibracija, vehicle, car, tank, engine, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Vožnja i potrošnja';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, nagrade, radar benzinskih postaja, rješavanje problema';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, eko, haptički, glas, gamifikacija, radar, klizanje, putovanje, potrošnja, klub goriva, vjernost, obd2 zapisnik, prikvači, eco, haptic, voice, gamification, glide, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Cijene i upozorenja';

  @override
  String get settingsTopicPricesSubtitle =>
      'Upozorenja o cijenama, glasovne najave, povijest cijena, prijave zajednice';

  @override
  String get settingsTopicPricesKeywords =>
      'upozorenje, obavijest, cijena, povijest, predviđanje, najbolje vrijeme, zajednica, prijava, qr, plaćanje, glas, najava, alert, notification, price, history, prediction, community, report, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Jedinice i prikaz';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Tema, jedinica udaljenosti, widget na početnom zaslonu';

  @override
  String get settingsTopicUnitsKeywords =>
      'tema, tamna, svijetla, eko, jedinica, km, milje, widget, boja, prikaz, izgled, theme, dark, light, eco, unit, miles, colour, display, appearance';

  @override
  String get settingsTopicFeaturesTitle => 'Značajke i način korištenja';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Predlošci načina korištenja i svaki prekidač značajki';

  @override
  String get settingsTopicFeaturesKeywords =>
      'značajka, način, osnovni, srednji, puni, prilagođeni, prekidač, vrste postaja, benzinske postaje, punjači, punjenje, feature, mode, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Izvori podataka i lokacija';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'API ključevi, GPS položaj, automatska promjena profila';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, ključ, gps, lokacija, položaj, izvor podataka, tankerkoenig, opencharge, key, location, data source';

  @override
  String get settingsTopicSyncTitle => 'Sinkronizacija i račun';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, oblak, račun, e-pošta, poveži uređaj, sinkronizacija, dijeli bazu, anoniman, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'privatnost, privola, gdpr, izbriši, obriši, pohrana, predmemorija, podaci, izvještavanje o pogreškama, vin, privacy, consent, delete, erase, storage, cache, data, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Sigurnosna kopija i vraćanje';

  @override
  String get settingsTopicBackupSubtitle =>
      'Izvezite ili vratite potpunu sigurnosnu kopiju svojih podataka';

  @override
  String get settingsTopicBackupKeywords =>
      'sigurnosna kopija, izvoz, vraćanje, uvoz, zip, xml, prijenos, backup, export, restore, import, transfer';

  @override
  String get settingsTopicAdvancedSubtitle => 'GitHub token, razvojni alati';

  @override
  String get settingsTopicAdvancedKeywords =>
      'razvojni programer, otklanjanje pogrešaka, token, pat, github, dijagnostika, zapisnik pogrešaka, trag, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Verzija, licence, poveznice';

  @override
  String get settingsTopicAboutKeywords =>
      'o aplikaciji, verzija, licenca, doniraj, github, navođenje autora, about, version, license, donate, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Uključite praćenje potrošnje u odjeljku Značajke i način korištenja da biste postavili vozila, coaching i nagrade.';

  @override
  String get settingsOpenFeaturesLink => 'Otvori Značajke i način korištenja';

  @override
  String get settingsRadarTileSubtitle =>
      'Radijus, način cijena, ispitivanje i prikvačivanje zaslona za aktivni profil';

  @override
  String get settingsRadarNoProfileHint =>
      'Najprije izradite profil — postavke radara spremaju se po profilu.';

  @override
  String get settingsRadarPinHeader => 'Prikvačivanje zaslona';

  @override
  String get settingsAlertsTileSubtitle =>
      'Upozorenja za postaje i radijus koja vas obavještavaju o padu cijena';

  @override
  String get settingsPriceFeaturesHeader => 'Značajke cijena';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Glasovne najave su isključene. Uključite Glasovne povratne informacije i Glasovne najave u odjeljku Značajke i način korištenja da biste tijekom vožnje čuli za jeftino gorivo u blizini.';

  @override
  String get settingsDistanceUnitTitle => 'Jedinica udaljenosti';

  @override
  String get settingsDistanceUnitSubtitle => 'Iz države aktivnog profila';

  @override
  String get settingsObd2AdapterTitle => 'OBD2 adapter';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Adapteri se uparuju po vozilu — otvorite vozilo da biste uparili ili promijenili njegov adapter';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Privole';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Privole za Cloud Sync i sinkronizaciju putovanja nalaze se pod Privatnost i podaci';

  @override
  String get settingsBackupExportSubtitle =>
      'Vozila, točenja, putovanja i zapisnici punjenja kao ZIP datoteka';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Spojite ili zamijenite podatke iz prethodne sigurnosne kopije ZIP';

  @override
  String get settingsStationTypesLink =>
      'Vrste postaja postavljaju se u odjeljku Značajke i način korištenja';

  @override
  String get routeSearchCriterionLabel => 'Izbor postaje po dionici rute';

  @override
  String get routeSearchCriterionCheapest => 'Najjeftinija';

  @override
  String get routeSearchCriterionNearest => 'Najbliža ruti';

  @override
  String get routeSearchTopNLabel => 'Kandidata po točki uzorkovanja';

  @override
  String routeSearchTopNCaption(int count) {
    return 'Na svakoj točki duž rute razmatra se do $count postaja.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Gorivo za pretragu cijena (hibrid)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Zadano za vozilo';

  @override
  String get scopeThisProfile => 'Ovaj profil';

  @override
  String get scopeAllProfiles => 'Svi profili';

  @override
  String get scopeThisVehicle => 'Ovo vozilo';

  @override
  String get featureLabel_manualConsumption => 'Ručno bilježenje potrošnje';

  @override
  String get featureDescription_manualConsumption =>
      'Ručno bilježite točenja goriva i punjenja (OBD2 adapter nije potreban).';

  @override
  String get featureLabel_loyaltyCards => 'Kartice vjernosti';

  @override
  String get featureDescription_loyaltyCards =>
      'Kartice klubova goriva / vjernosti s popustom po litri u usporedbama cijena.';

  @override
  String get featureLabel_startupTrace => 'Trag inicijalizacije pri pokretanju';

  @override
  String get featureDescription_startupTrace =>
      'Bilježi vremenski mjerene faze pokretanja aplikacije, prikazuje ih kao vodopad i izvozi — dijagnostika za razvojne programere.';

  @override
  String get locationGpsAutoHint =>
      'GPS položaj dohvaća se automatski pri pretraživanju. Ovdje ga možete ažurirati i ručno.';

  @override
  String get locationClearGpsBody =>
      'Obrisati spremljeni GPS položaj? Možete ga ponovno ažurirati u bilo kojem trenutku.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Ovaj format datoteke još se ne može uvesti — umjesto toga podijelite fotografiju računa.';

  @override
  String get shareReceiptFailed =>
      'Dijeljeni račun se nije mogao pročitati — pokušajte ga dijeliti ponovo ili ručno dodajte punjenje.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Podijeli račun za uvoz';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Podijelite fotografiju računa iz druge aplikacije za prethodno popunjavanje punjenja — datum, litri, ukupno i postaja se čitaju na uređaju.';

  @override
  String get speedConsumptionCardTitle => 'Potrošnja prema brzini';

  @override
  String get speedBandIdleJam => 'Mirovanje / gužva';

  @override
  String get speedBandUrban => 'Urbano (10–50)';

  @override
  String get speedBandSuburban => 'Prigradsko (50–80)';

  @override
  String get speedBandRural => 'Ruralno (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eko krstarenje (100–115)';

  @override
  String get speedBandMotorway => 'Autocesta (115–130)';

  @override
  String get speedBandMotorwayFast => 'Brza autocesta (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Snimite 30+ minuta vožnji s OBD2 adapterom za otključavanje analize brzine/potrošnje.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % vožnje';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Potrebno više podataka';

  @override
  String get splashLoadingLabel => 'Učitavanje Sparkilo';

  @override
  String get storageRecoveryTitle => 'Problem s pohranom';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo nije mogao otvoriti svoju lokalnu pohranu podataka. Datoteka pohrane čini se oštećenom.';

  @override
  String get storageRecoveryGuidance =>
      'Za oporavak izbrišite pohranu aplikacije u postavkama uređaja ili ponovno instalirajte aplikaciju. Vaši favoriti i povijest pohranjeni su samo na ovom uređaju pa se ne mogu automatski vratiti.';

  @override
  String syncAdoptTitle(String email) {
    return 'Pridruži se računu $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Prijavite se lozinkom ovog računa kako biste njegove podatke dijelili na oba uređaja.';

  @override
  String get syncAdoptPasswordLabel => 'Lozinka računa';

  @override
  String get syncAdoptJoinButton => 'Pridruži se računu';

  @override
  String get syncAdoptUseDifferentAccount => 'Radije koristi drugi račun';

  @override
  String get syncDeleteDataTitle => 'Izbriši sinkronizirane podatke';

  @override
  String get syncDeleteDataSubtitle =>
      'Uklonite svoje vožnje, vozila ili točenja iz baze za sinkronizaciju';

  @override
  String get syncDeleteDataPickTitle =>
      'Koje sinkronizirane podatke izbrisati?';

  @override
  String get syncDeleteDataCategoryTrips => 'Vožnje';

  @override
  String get syncDeleteDataCategoryVehicles => 'Vozila';

  @override
  String get syncDeleteDataCategoryFillUps => 'Točenja';

  @override
  String get syncDeleteDataCategoryEverything => 'Sve';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Izbrisati $category iz baze za sinkronizaciju?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Ovo uklanja odabrane podatke iz vaše baze za sinkronizaciju i oni se neće ponovno sinkronizirati s vaših drugih uređaja. Podaci pohranjeni lokalno na ovom uređaju ostaju.';

  @override
  String get syncDeleteDataConfirmAction => 'Izbriši s poslužitelja';

  @override
  String get syncDeleteDataDone => 'Sinkronizirani podaci izbrisani';

  @override
  String get syncDeleteDataFailed =>
      'Brisanje sinkroniziranih podataka nije uspjelo — pokušajte ponovno';

  @override
  String get syncRelinkTitle =>
      'Sinkronizaciju u oblaku treba ponovno povezati';

  @override
  String get syncRelinkBody =>
      'Spremljeni identitet za sinkronizaciju ovog uređaja je odjavljen. Prijavite se e-poštom da ponovno povežete sinkronizirane podatke ili počnite ispočetka s novim identitetom.';

  @override
  String get syncRelinkSignInAction => 'Prijavi se za ponovno povezivanje';

  @override
  String get syncRelinkStartFreshAction => 'Počni ispočetka';

  @override
  String get syncRelinkStartFreshTitle => 'Početi ispočetka?';

  @override
  String get syncRelinkStartFreshBody =>
      'Za ovaj će se uređaj stvoriti novi anonimni identitet. Podaci sinkronizirani pod starim identitetom ostaju na poslužitelju, ali odavde više neće biti dostupni osim ako se ne prijavite njegovim računom e-pošte.';

  @override
  String get syncRelinkStartFreshConfirm => 'Počni ispočetka';

  @override
  String get tankLevelTitle => 'Razina goriva';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km dosega';
  }

  @override
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km uz potrošnju vašeg zadnjeg spremnika';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Dugoročni prosjek: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Zadnje punjenje: $date · $count vožnja(i) od tada';
  }

  @override
  String get tankLevelEmptyNoFillUp =>
      'Unesite punjenje za prikaz razine goriva';

  @override
  String get tankLevelDetailSheetTitle => 'Vožnje od zadnjeg punjenja';

  @override
  String get addFillUpIsFullTankLabel => 'Puni spremnik';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Spremnik napunjen do vrha — poništite ako je ovo djelomično punjenje';

  @override
  String tankLevelSourceFillUp(String date) {
    return 'Usidreno na zadnjem točenju: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'OBD2 senzor spremnika · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Mješavina u spremniku: $mix';
  }

  @override
  String get tankReportTitle => 'Izvještaj o spremniku';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Od prethodnog punog spremnika: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km više od prethodnog spremnika';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km manje od prethodnog spremnika';
  }

  @override
  String get tankReportTrendFlat => 'Na razini prethodnog spremnika';

  @override
  String get tankReportNoPrevious =>
      'Kretanje se prikazuje nakon vašeg sljedećeg punog spremnika.';

  @override
  String get tankReportExplainHeader => 'Što snimke sugeriraju';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Udio visokih okretaja $cur % (prije $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Nagli manevri $cur/100 km (prije $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Hladni startovi $cur (prije $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Udio praznog hoda $cur % (prije $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Snimke su nasumične i pokrivaju samo dio ovog spremnika — ovi su nagovještaji orijentacijski, a ne cijela priča.';

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'Sustav';

  @override
  String get themeCardSubtitleLight => 'Svijetla';

  @override
  String get themeCardSubtitleDark => 'Tamna';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Prati sustav';

  @override
  String get themeSettingsLightLabel => 'Svijetla';

  @override
  String get themeSettingsDarkLabel => 'Tamna';

  @override
  String get themeSettingsSystemDescription =>
      'Uskladi s trenutnim izgledom uređaja.';

  @override
  String get themeSettingsLightDescription =>
      'Svijetla pozadina — najbolje za dnevnu upotrebu.';

  @override
  String get themeSettingsDarkDescription =>
      'Tamna pozadina — ugodnija za oči noću i štedi bateriju na OLED ekranima.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Prepoznatljivi zeleni izgled aplikacije — svijetlo i lako za čitanje, s blago zelenkasto toniranom pozadinom.';

  @override
  String get throttleRpmHistogramTitle => 'Kako ste koristili motor';

  @override
  String get throttleRpmHistogramThrottleSection => 'Položaj gasa';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM motora';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Klizanje (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Lagano (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Umjereno (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Puni otvor (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Mirovanje (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Krstarenje (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Dinamično (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Agresivno (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Nema uzoraka gasa ili RPM-a u ovoj vožnji.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Vožnje';

  @override
  String get trajetsStartRecordingButton => 'Počni snimanje';

  @override
  String get trajetsResumeRecordingButton => 'Nastavi snimanje';

  @override
  String get tripStartProgressConnectingAdapter => 'Spajanje na OBD2 adapter…';

  @override
  String get tripStartProgressReadingVehicleData => 'Čitanje podataka vozila…';

  @override
  String get tripStartProgressStartingRecording => 'Pokretanje snimanja…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Dovršavanje sažetka…';

  @override
  String get tripSaveProgressSavingToHistory => 'Spremanje u povijest…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Sinkronizacija u pozadini…';

  @override
  String get trajetsEmptyStateTitle => 'Još nema vožnji';

  @override
  String get trajetsEmptyStateBody =>
      'Dodirnite Počni snimanje za početak bilježenja vaših vožnji.';

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
  String get trajetDetailSummaryTitle => 'Sažetak';

  @override
  String get trajetDetailFieldDate => 'Datum';

  @override
  String get trajetDetailFieldVehicle => 'Vozilo';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adapter';

  @override
  String get trajetDetailFieldDistance => 'Udaljenost';

  @override
  String get trajetDetailFieldDuration => 'Trajanje';

  @override
  String get trajetDetailFieldAvgConsumption => 'Prosj. potrošnja';

  @override
  String get trajetDetailFieldFuelUsed => 'Potrošeno gorivo';

  @override
  String get trajetDetailFieldFuelCost => 'Trošak goriva';

  @override
  String get trajetDetailFieldAvgSpeed => 'Prosj. brzina';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maks. brzina';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Brzina (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Protok goriva (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Opterećenje motora (%)';

  @override
  String get trajetDetailChartThrottle => 'Papučica gasa (%)';

  @override
  String get trajetDetailChartCoolant => 'Rashladna tekućina (°C)';

  @override
  String get trajetDetailChartAltitudeRelative =>
      'Nadmorska visina (m, od početka)';

  @override
  String get trajetDetailChartLambda => 'Komandirana λ';

  @override
  String get trajetDetailChartsSection => 'Grafikoni';

  @override
  String get trajetsRowColdStartChip => 'Hladan start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motor nije dostigao radnu temperaturu za vrijeme ove vožnje — potrošnja goriva bila je viša od uobičajene.';

  @override
  String get trajetDetailChartEmpty => 'Nema snimljenih uzoraka';

  @override
  String get trajetDetailChartEstimatedBadge => 'procijenjeno';

  @override
  String get trajetDetailShareAction => 'Dijeli';

  @override
  String get trajetDetailShareImageOption => 'Podijeli sliku';

  @override
  String get trajetDetailShareGpxOption => 'Podijeli GPS trag (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Nema GPS podataka na ovom putovanju';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — vožnja na $date';
  }

  @override
  String get trajetDetailShareError =>
      'Nije moguće generirati sliku za dijeljenje';

  @override
  String get trajetDetailDownloadCsvOption => 'Preuzmi telemetriju (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Preuzmi telemetriju (JSON)';

  @override
  String get trajetDetailDownloadError => 'Datoteka se nije mogla spremiti';

  @override
  String get trajetDetailDeleteAction => 'Obriši';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Obrisati ovu vožnju?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ova vožnja bit će trajno uklonjena iz vaše povijesti.';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Obriši';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapter spojen, ali ne vraća podatke. Pokušajte s drugim adapterom ili provjerite dijagnostički protokol vozila.';

  @override
  String get trajetsViewAllOnMap => 'Prikaži sve na karti';

  @override
  String get trajetsMapTitle => 'Putovanja na karti';

  @override
  String get trajetsMapShareGpx => 'Podijeli GPX';

  @override
  String get trajetsMapEmpty =>
      'Nijedno od odabranih putovanja nema GPS podatke.';

  @override
  String get trajetsMapShareError => 'GPX datoteku nije moguće podijeliti';

  @override
  String get trajetDetailChartBoost => 'Tlak prednabijanja (MAP − okolina)';

  @override
  String get trajetDetailChartIat => 'Temperatura usisnog zraka';

  @override
  String get trajetDetailChartTiming => 'Pretpaljenje';

  @override
  String get trajetObd2Degraded =>
      'Pokrenuto s OBD2 adapterom, ali snimljeno uglavnom GPS-om — podaci motora su nepotpuni';

  @override
  String get tripLengthCardTitle => 'Potrošnja prema duljini vožnje';

  @override
  String get tripLengthBucketShort => 'Kratko (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Srednje (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Dugo (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Potrebno više podataka';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vožnji',
      one: '1 vožnja',
      zero: 'nema vožnji',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Put vožnje';

  @override
  String get tripPathCardSubtitle => 'GPS-snimljena ruta';

  @override
  String get tripPathLegendEfficient => 'Učinkovito (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Na granici (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Rastrošno (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar benzinskih postaja';

  @override
  String get tripRadarScanning => 'Traženje obližnjih postaja';

  @override
  String get tripRadarNoStationNearby => 'Nema obližnje postaje';

  @override
  String get fuelStationRadarNearer => 'Bliža postaja';

  @override
  String get fuelStationRadarFarther => 'Dalja postaja';

  @override
  String get fuelStationRadarStart => 'Pokreni radar benzinskih postaja';

  @override
  String get stopRadar => 'Zaustavi radar';

  @override
  String get fuelStationRadarResultBadge =>
      'Rezultat radara benzinskih postaja';

  @override
  String get radarUpdatingLocation => 'Ažuriranje vaše lokacije…';

  @override
  String get radarSearching => 'Pretraživanje…';

  @override
  String get highwayModeChip =>
      'Način autoceste — prikazuje postaje ispred vas na ruti';

  @override
  String get tripRecordingPinTooltip =>
      'Prikačivanje drži ekran uključenim — troši više baterije';

  @override
  String get tripRecordingPinSemanticOn => 'Otkači obrazac snimanja';

  @override
  String get tripRecordingPinSemanticOff => 'Prikači obrazac snimanja';

  @override
  String get tripRecordingPinHelpTooltip => 'Što radi pin?';

  @override
  String get tripRecordingPinHelpTitle => 'O prikačivanju';

  @override
  String get tripRecordingPinHelpBody =>
      'Prikačivanje drži ekran uključenim i sakriva sistemske trake kako bi obrazac ostao čitljiv na nosaču. Dodirnite ponovo za otpuštanje. Automatski se otpušta kada vožnja završi.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Snimanje se nastavlja u pozadini. Dodirnite crveni natpis na vrhu bilo kojeg zaslona za povratak.';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Prikačite ekran za održavanje GPS-a aktivnim za vrijeme vožnje — Android može ograničiti GPS za vrijeme spavanja.';

  @override
  String get tripRecordingMinimiseTooltip => 'Smanji u plutajuću pločicu';

  @override
  String get tripRecordingAutoPinTitle =>
      'Uvijek prikvači pri pokretanju snimanja';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Automatski prikvači obrazac pri svakoj vožnji umjesto da dodirujete svaki put. Troši više baterije.';

  @override
  String get tripRecordingConnectingTitle => 'Pokretanje snimanja…';

  @override
  String get tripRecordingSavingTitle => 'Spremanje puta…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Snimanje odbačeno — nije otkriveno kretanje';

  @override
  String get tripRecordingGpsNotificationTitle => 'Snimanje vašeg puta';

  @override
  String get tripRecordingGpsNotificationText =>
      'Praćenje vaše rute za statistiku goriva i vožnje';

  @override
  String get tripShareAction => 'Podijeli s drugim računom';

  @override
  String get tripShareSheetTitle => 'Podijeli ovu vožnju';

  @override
  String get tripShareSheetSubtitle =>
      'Dajte drugom TankSync računu pristup samo za čitanje ovoj snimljenoj vožnji.';

  @override
  String get tripShareEmailLabel => 'E-pošta primatelja';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Podijeli';

  @override
  String get tripShareCreateLinkButton => 'Stvori vezu za dijeljenje';

  @override
  String get tripShareLinkCreated =>
      'Veza za dijeljenje kopirana — zalijepite je primatelju.';

  @override
  String get tripShareSuccess => 'Vožnja podijeljena.';

  @override
  String get tripShareRecipientNotFound =>
      'Nijedan TankSync račun ne koristi tu e-poštu.';

  @override
  String get tripShareError =>
      'Vožnju nije moguće podijeliti. Pokušajte ponovno.';

  @override
  String get tripShareExistingTitle => 'Podijeljeno s';

  @override
  String get tripShareExistingEmpty => 'Još nije ni s kim podijeljeno.';

  @override
  String get tripShareDirectRecipient => 'Račun';

  @override
  String get tripShareLinkRecipient => 'Veza za dijeljenje (neiskorištena)';

  @override
  String get tripShareRevokeTooltip => 'Opozovi';

  @override
  String get tripShareRevoked => 'Dijeljenje opozvano.';

  @override
  String get trajetsSharedSectionTitle => 'Podijeljeno sa mnom';

  @override
  String get trajetsSharedBadge => 'Podijeljeno';

  @override
  String get tripVerdictPromptTitle => 'Kakva je bila ova vožnja?';

  @override
  String get tripVerdictSmooth => 'Glatka';

  @override
  String get tripVerdictModerate => 'Umjerena';

  @override
  String get tripVerdictAggressive => 'Agresivna';

  @override
  String get tripVerdictDismiss => 'Ne sada';

  @override
  String get tripVerdictThanks =>
      'Hvala — ovo pomaže kalibrirati analizu vaše vožnje.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Točenje izbrisano';

  @override
  String get trajetDeletedUndoSnackbar => 'Snimka izbrisana';

  @override
  String get searchFailedSnackbar =>
      'Pretraživanje nije uspjelo — molimo pokušajte ponovo';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postaje',
      one: '1 postaja',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Ažurirano $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Također: $names';
  }

  @override
  String get favoriteAdd => 'Dodaj u favorite';

  @override
  String get favoriteRemove => 'Ukloni iz favorita';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Izvorno: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Postaja bez marke';

  @override
  String get unsupportedRegionTitle => 'Još nije dostupno u vašoj regiji';

  @override
  String get unsupportedRegionBody =>
      'Još nemamo cijene goriva za vašu zemlju, pa rezultati mogu biti prazni ili iz druge zemlje. Ipak možete odabrati podržanu zemlju u postavkama pretraživanja.';

  @override
  String get unsupportedRegionDismiss => 'Razumijem';

  @override
  String get configureCountryTitle => 'Postavite svoju zemlju';

  @override
  String get configureCountryBody =>
      'Vaša je zemlja podržana, ali još nije postavljena — pa cijene mogu biti iz druge zemlje. Odaberite svoju zemlju u postavkama pretraživanja da biste vidjeli lokalne cijene.';

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
  String get vehicleMultiFuelCapableLabel =>
      'Možda točim različite vrste goriva';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Prati koje je gorivo najjeftinije po kilometru';

  @override
  String get vinLabel => 'VIN (neobavezno)';

  @override
  String get vinDecodeTooltip => 'Dekodiraj VIN';

  @override
  String get vinConfirmAction => 'Da, automatski popuni';

  @override
  String get vinModifyAction => 'Izmijeni ručno';

  @override
  String get vehicleReadVinFromCarButton => 'Pročitaj VIN iz automobila';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Pročitaj VIN iz uparenog OBD2 adaptera';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN nije dostupan (Mode 09 PID 02 nije podržan na vozilima prije 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Čitanje VIN-a nije uspjelo — molimo unesite ručno';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Uparite OBD2 adapter prvo za automatsko čitanje VIN-a';

  @override
  String get pickerButtonLabel => 'Odaberi iz kataloga';

  @override
  String get pickerSearchHint => 'Pretraži marku ili model';

  @override
  String get pickerHelpText => 'Prethodno popunite iz 50+ podržanih vozila';

  @override
  String get pickerEmptyResults => 'Nema podudaranja';

  @override
  String get pickerCancel => 'Odustani';

  @override
  String get pickerLoading => 'Učitavanje kataloga…';

  @override
  String get vinInfoTooltip => 'Što je VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Što je VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Broj identifikacije vozila je 17-znakovna šifra jedinstvena za vaše vozilo. Utisnuta je na šasiji i ispisana na dokumentu registracije vozila.';

  @override
  String get vinInfoSectionWhyTitle => 'Zašto pitamo';

  @override
  String get vinInfoSectionWhyBody =>
      'Dekodiranjem VIN-a automatski se popunjavaju radni obujam motora, broj cilindara, godište, primarna vrsta goriva i ukupna masa — što vas oslobađa ručnog traženja tehničkih specifikacija. OBD2 izračun potrošnje goriva koristi ove vrijednosti za točne podatke o potrošnji.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privatnost';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Vaš VIN pohranjuje se samo lokalno u šifriranoj pohrani aplikacije — nikada se ne učitava na Sparkilo poslužitelje. Baza podataka NHTSA vPIC upitana je s VIN-om, ali vraća samo anonimne tehničke specifikacije; NHTSA ne povezuje VIN s osobnim podacima. Bez mreže, pretraživanje izvan mreže vraća samo proizvođača i zemlju.';

  @override
  String get vinInfoSectionWhereTitle => 'Gdje ga pronaći';

  @override
  String get vinInfoSectionWhereBody =>
      'Pogledajte kroz vjetrobransko staklo u donjem lijevom kutu na strani vozača, provjerite naljepnicu na okviru vrata s vozačeve strane kada su vrata otvorena, ili ga pročitajte s dokumenta registracije vozila (kartice / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Razumijem';

  @override
  String get vinConfirmPrivacyNote =>
      'Potražili smo vaš VIN u besplatnoj bazi podataka vozila NHTSA — ništa nije poslano na Sparkilo poslužitelje.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online dekodiranje';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekodiraj VIN putem besplatne javne usluge NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Kada uparite adapter, VIN vašeg vozila čita se lokalno za identifikaciju automobila. Omogućavanjem ovoga šalje se 17-znakovni VIN usluzi NHTSA vPIC za pretraživanje dodatnih detalja (model, radni obujam, vrsta goriva). VIN je jedini podatak koji se šalje — nikakvi drugi podaci ne napuštaju vaš uređaj.';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Otkriveno iz VIN-a: $summary. Primijeniti?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Primijeni';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometara naprijed, $fuelType $euros eura $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Widget na početnom zaslonu';

  @override
  String get widgetHelpIntro =>
      'Dodajte SparKilo widget na početni zaslon za prikaz cijena goriva i punjenja na prvi pogled.';

  @override
  String get widgetHelpAdd =>
      'Dodajte ga iz birača widgeta pokretača — dugo pritisnite prazno područje početnog zaslona, odaberite Widgeti i pronađite SparKilo.';

  @override
  String get widgetHelpTap =>
      'Dodirnite postaju u widgetu za otvaranje u aplikaciji. Dodirnite ikonu osvježavanja za ažuriranje cijena.';

  @override
  String get widgetHelpConfigure =>
      'Na Androidu, dugo pritisnite widget i odaberite Rekonfiguriraj za promjenu profila, boje i sadržaja.';

  @override
  String get widgetDefaultsThisProfileHint =>
      'Odabiri u nastavku vrijede za svaki instalirani widget koji prikazuje ovaj profil, pri sljedećem osvježavanju.';

  @override
  String get widgetDefaultsColorLabel => 'Shema boja';

  @override
  String get widgetDefaultsVariantLabel => 'Varijanta sadržaja';

  @override
  String get widgetColorSchemeSystem => 'Slijedi sustav';

  @override
  String get widgetColorSchemeLight => 'Svijetla';

  @override
  String get widgetColorSchemeDark => 'Tamna';

  @override
  String get widgetColorSchemeBlue => 'Plava';

  @override
  String get widgetColorSchemeGreen => 'Zelena';

  @override
  String get widgetColorSchemeOrange => 'Narančasta';

  @override
  String get widgetVariantDefault => 'Samo trenutna cijena';

  @override
  String get widgetVariantPredictive =>
      'Prediktivno: najbolje vrijeme za punjenje';
}
