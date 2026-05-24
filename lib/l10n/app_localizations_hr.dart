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
  String get searchButton => 'Pretraži';

  @override
  String get searchCriteriaTitle => 'Kriteriji pretraživanja';

  @override
  String get searchCriteriaOpen => 'Pretraži';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'U polumjeru $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Dodirnite za početak pretraživanja';

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
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktivni profil';

  @override
  String get configPreferredFuel => 'Željeno gorivo';

  @override
  String get configCountry => 'Država';

  @override
  String get configRouteSegment => 'Segment rute';

  @override
  String get configApiKeysSection => 'API ključevi';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API ključ';

  @override
  String get configApiKeyConfigured => 'Konfigurirano';

  @override
  String get configApiKeyNotSet => 'Nije postavljeno (demo način)';

  @override
  String get configApiKeyCommunity => 'Zadano (zajednički ključ)';

  @override
  String get searchLocationPlaceholder => 'Adresa, poštanski broj ili grad';

  @override
  String get configEvKey => 'EV punionice API ključ';

  @override
  String get configEvKeyCustom => 'Vlastiti ključ';

  @override
  String get configEvKeyShared => 'Zadano (dijeljeni)';

  @override
  String get configCloudSyncSection => 'Sinkronizacija u oblaku';

  @override
  String get configTankSyncConnected => 'Spojeno';

  @override
  String get configTankSyncDisabled => 'Onemogućeno';

  @override
  String get configAuthMode => 'Način autentifikacije';

  @override
  String get configAuthEmail => 'E-pošta (trajna)';

  @override
  String get configAuthAnonymous => 'Anonimno (samo uređaj)';

  @override
  String get configDatabase => 'Baza podataka';

  @override
  String get configPrivacySummary => 'Sažetak privatnosti';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoriti, upozorenja i ignorirane postaje sinkronizirani su s vašom privatnom bazom podataka\n• GPS lokacija i API ključevi nikad ne napuštaju vaš uređaj\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Svi podaci pohranjeni su lokalno samo na ovom uređaju\n• Nikakvi podaci ne šalju se na server\n• API ključevi šifrirani u sigurnoj pohrani uređaja';

  @override
  String get configAuthNoteEmail =>
      'E-mail račun omogućuje pristup s više uređaja';

  @override
  String get configAuthNoteAnonymous =>
      'Anonimni račun — podaci vezani uz ovaj uređaj';

  @override
  String get configNone => 'Nema';

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
  String get account => 'Račun';

  @override
  String get continueAsGuest => 'Nastavi kao gost';

  @override
  String get createAccount => 'Stvori račun';

  @override
  String get signIn => 'Prijava';

  @override
  String get upgradeToEmail => 'Stvori e-mail račun';

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
  String crossBorderNearby(String country) {
    return '$country je u blizini';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km do granice';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Prosj. ovdje: $price EUR ($count postaja)';
  }

  @override
  String get allPricesView => 'Sve cijene';

  @override
  String get compactView => 'Kompaktno';

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
  String get gdprAcceptAll => 'Prihvati sve';

  @override
  String get gdprAcceptSelected => 'Prihvati odabrano';

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
  String get topicUrlCopied => 'URL teme kopiran';

  @override
  String get testNotificationSent => 'Testna obavijest poslana!';

  @override
  String get testNotificationFailed => 'Slanje testne obavijesti nije uspjelo';

  @override
  String get pushUpdateFailed =>
      'Ažuriranje postavki push obavijesti nije uspjelo';

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
  String get privacyDashboardTitle => 'Nadzorna ploča privatnosti';

  @override
  String get privacyDashboardSubtitle =>
      'Pregledajte, izvezite ili izbrišite svoje podatke';

  @override
  String get privacyDashboardBanner =>
      'Vaši podaci su vaši. Ovdje možete vidjeti sve što aplikacija pohranjuje, izvesti ih ili ih obrisati.';

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
  String get privacyCacheEntries => 'Unosi u predmemoriji';

  @override
  String get privacyApiKey => 'Pohranjen API ključ';

  @override
  String get privacyEvApiKey => 'Pohranjen EV API ključ';

  @override
  String get privacyEstimatedSize => 'Procijenjeni prostor';

  @override
  String get privacySyncedData => 'Sinkronizacija u oblaku (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Sinkronizacija u oblaku onemogućena. Svi podaci ostaju samo na ovom uređaju.';

  @override
  String get privacySyncMode => 'Način sinkronizacije';

  @override
  String get privacySyncUserId => 'ID korisnika';

  @override
  String get privacySyncDescription =>
      'Kada je sinkronizacija omogućena, favoriti, upozorenja, ignorirane postaje i ocjene pohranjuju se i na TankSync serveru.';

  @override
  String get privacyViewServerData => 'Pregledaj podatke na serveru';

  @override
  String get privacyExportButton => 'Izvezi sve podatke kao JSON';

  @override
  String get privacyExportSuccess => 'Podaci izvezeni u međuspremnik';

  @override
  String get privacyExportCsvButton => 'Izvezi sve podatke kao CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV podaci izvezeni u međuspremnik';

  @override
  String savedToFile(String path) {
    return 'Spremljeno u $path';
  }

  @override
  String get privacyDeleteButton => 'Obriši sve podatke';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopiraj dnevnik grešaka u međuspremnik ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Očisti zapisnik pogrešaka';

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
  String voiceAnnouncementThreshold(String price) {
    return 'Samo ispod $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometara ispred, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Polumjer najava';

  @override
  String get voiceAnnouncementCooldown => 'Interval ponavljanja';

  @override
  String get nearestStations => 'Najblize postaje';

  @override
  String get nearestStationsHint =>
      'Pronadite najblize postaje pomocu vase trenutne lokacije';

  @override
  String get consumptionLogTitle => 'Potrošnja goriva';

  @override
  String get consumptionLogMenuTitle => 'Evidencija potrošnje';

  @override
  String get consumptionLogMenuSubtitle =>
      'Pratite punjenja i izračunajte L/100km';

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
  String get stationPreFilled => 'Postaja prethodno unesena';

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
  String get fillUpVehicleNone => 'Bez vozila';

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
  String get scanPump => 'Skeniraj pumpu';

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
  String get obdNoAdapter => 'Nema OBD2 adaptera u dosegu';

  @override
  String get obdOdometerUnavailable => 'Nije moguće očitati kilometar-sat';

  @override
  String get obdPermissionDenied =>
      'Odobrite Bluetooth dozvolu u sistemskim postavkama';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter ne odgovara — uključite paljenje i pokušajte ponovo';

  @override
  String get obdPickerTitle => 'Odaberite OBD2 adapter';

  @override
  String get obdPickerScanning => 'Traženje adaptera…';

  @override
  String get obdPickerConnecting => 'Spajanje…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Svijetla';

  @override
  String get themeModeDark => 'Tamna';

  @override
  String get themeModeSystem => 'Prati sustav';

  @override
  String get tripRecordingTitle => 'Snimanje vožnje';

  @override
  String get tripSummaryTitle => 'Sažetak vožnje';

  @override
  String get tripMetricDistance => 'Udaljenost';

  @override
  String get tripMetricSpeed => 'Brzina';

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
  String get navConsumption => 'Potrošnja';

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
  String get obd2StatusAttempting => 'OBD2 adapter: spajanje';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapter: nedostupan';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: potrebna Bluetooth dozvola';

  @override
  String get obd2StatusConnectedBody => 'Spreman za snimanje vožnje.';

  @override
  String get obd2StatusAttemptingBody => 'Spajanje u pozadini…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter izvan dosega ili ga već koristi druga aplikacija.';

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
  String get tripHistoryEmptySubtitle =>
      'Spojite OBD2 adapter i snimite vožnju za početak izgradnje vaše povijesti vožnji.';

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
  String get situationHardAccel => 'Naglo ubrzanje';

  @override
  String get situationFuelCut => 'Isključenje goriva — klizanje';

  @override
  String get tripSaveAsFillUp => 'Spremi kao punjenje';

  @override
  String get tripSaveRecording => 'Spremi vožnju';

  @override
  String get tripDiscard => 'Odbaci';

  @override
  String obdOdometerRead(int km) {
    return 'Kilometar-sat pročitan: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nije postavljeno';

  @override
  String get wizardVehicleTapToEdit => 'Dodirnite za uređivanje';

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
  String get wizardProfileCustomDescription =>
      'Vlastita kombinacija značajki. Podesite svaki prekidač ispod.';

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
  String get evMaxPower => 'Maks snaga';

  @override
  String get evOperator => 'Operater';

  @override
  String get evLastUpdate => 'Posljednje ažuriranje';

  @override
  String get evStatusAvailable => 'Dostupno';

  @override
  String get evStatusOccupied => 'Zauzeto';

  @override
  String get evStatusOutOfOrder => 'Izvan pogona';

  @override
  String get openOnlyFilter => 'Samo otvorene';

  @override
  String get saveAsDefaults => 'Spremi kao moje zadane';

  @override
  String get criteriaSavedToProfile => 'Spremljeno kao zadano';

  @override
  String get profileNotFound => 'Nema aktivnog profila';

  @override
  String get updatingFavorites => 'Ažuriranje favorita...';

  @override
  String get fetchingLatestPrices => 'Dohvaćanje najnovijih cijena';

  @override
  String get noDataAvailable => 'Nema podataka';

  @override
  String get configAndPrivacy => 'Konfiguracija i privatnost';

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
  String get tooltipBack => 'Natrag';

  @override
  String get tooltipClose => 'Zatvori';

  @override
  String get tooltipShare => 'Podijeli';

  @override
  String get tooltipClearSearch => 'Obriši unos pretraživanja';

  @override
  String get coachingShiftUp => 'Prebaci gore';

  @override
  String get coachingShiftDown => 'Prebaci dolje';

  @override
  String get coachingEasePedal => 'Smanji gas';

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
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Gorivo';

  @override
  String get stationTypeEv => 'EV';

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
  String get alertsBackgroundCheckErrorTitle =>
      'Provjera upozorenja u pozadini nije uspjela';

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
      'Dijelite favourite i ocjene sa svim korisnicima';

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
  String get ntfyCardTitle => 'Push obavijesti (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Omogući ntfy.sh push';

  @override
  String get ntfyEnableSubtitle =>
      'Primajte upozorenja o cijenama putem ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'URL teme';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Kopiraj URL teme';

  @override
  String get ntfySendTestButton => 'Pošalji testnu obavijest';

  @override
  String get ntfyFdroidHint =>
      'Instalirajte ntfy aplikaciju s F-Droid za primanje push obavijesti na vašem uređaju.';

  @override
  String get ntfyConnectFirstHint =>
      'Prvo povežite TankSync za omogućavanje push obavijesti.';

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
  String get evChargingSection => 'EV punjenje';

  @override
  String get fuelStationsSection => 'Benzinske postaje';

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
  String get luxembourgRegulatedPricesNotice =>
      'Cijene goriva u Luksemburgu regulira vlada i jedinstvene su diljem cijele zemlje.';

  @override
  String get luxembourgFuelUnleaded95 => 'Bezolovni 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Bezolovni 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luksemburške regulirane cijene nisu dostupne.';

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
  String get southKoreaApiKeyRequired =>
      'Registrirajte se na OPINET za besplatni API ključ';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registrirajte se na CNE za besplatni API ključ';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

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
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Kalibracija potrošnje ažurirana za $vehicleName — točnost poboljšana za $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Resetirati volumetrijsku učinkovitost?';

  @override
  String get veResetConfirmBody =>
      'Ovo će odbaciti naučenu volumetrijsku učinkovitost (η_v) i vratiti zadanu vrijednost (0.85). Procjene protoka goriva na razini putovanja vraćat će se na tvornički konstantu dok kalibracija ne prikupi nove uzorke iz nadolazećih putovanja.';

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
  String get alertsRadiusThreshold => 'Prag (€/L)';

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
  String get alertsRadiusDeleteConfirm => 'Obrisati upozorenje polumjera?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 spojen: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Upari OBD2 adapter';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel pao na obližnjim postajama';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount postaja palo za do $maxDropCents¢ u posljednjem satu';
  }

  @override
  String get fillUpSavedSnackbar => 'Punjenje spremljeno';

  @override
  String get radiusAlertsEntryTitle => 'Upozorenja polumjera i statistika';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Primajte obavijest kada cijene padnu u vašoj blizini';

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
  String get obd2ErrorProtocolInitFailed =>
      'OBD2 adapter poslao je neprepoznat odgovor. Možda nije kompatibilan — pokušajte s drugim adapterom.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2 adapter se isključio. Ponovno se povežite i pokušajte ponovno.';

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
  String get autoRecordPairedAdapterLabel => 'Upareni adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Nema uparenog adaptera. Uparite ga prvo putem OBD2 uvodnika.';

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
  String get autoRecordBadgeClearTooltip => 'Očisti brojač';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Uparite adapter u odjeljku ispod za omogućavanje automatskog snimanja';

  @override
  String get exportBackupTooltip => 'Izvezi sigurnosnu kopiju';

  @override
  String get exportBackupReady =>
      'Sigurnosna kopija spremna — odaberite odredište';

  @override
  String get exportBackupFailed =>
      'Izvoz sigurnosne kopije nije uspio — pokušajte ponovo';

  @override
  String get brokenMapChipVerifying => 'MAP senzor se verificira…';

  @override
  String get brokenMapChipDisclaimer => 'MAP očitanja su sumnjiva';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP senzor čita netočno — očitanja goriva mogu biti 50–80% preniska. Pokušajte s drugim adapterom.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP senzor nije pouzdan. Prikazujem prosjeke punjenja umjesto stvarne potrošnje.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP senzor: verificiran ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP senzor: verificira se ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP senzor: sumnjiv ($confidence)';
  }

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
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrirano, $samples uzoraka)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (učenje, $samples uzoraka)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (zadano — još nema plein-complet)';

  @override
  String get calibrationResetLearner => 'Resetiraj učilicu';

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
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vaš $makeModel je označen kao diesel, ali odgovara benzinskom katalogu. Dodirnite za ažuriranje.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Ažuriraj';

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
  String get chargingChartsMonthAxis => 'Mjesec';

  @override
  String get gdprCommunityWaitTimeTitle => 'Vremena čekanja zajednice';

  @override
  String get gdprCommunityWaitTimeShort =>
      'Anonimno dijeli vremena čekanja na postajama';

  @override
  String get gdprCommunityWaitTimeDescription =>
      'Anonimno dijelite kada stignete i napustate benzinsku postaju kako bi aplikacija mogla prikazivati tipična vremena čekanja. Ne učitavaju se koordinate lokacije — samo ID postaje.';

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
  String get consoSubsectionVehicles => 'Moja vozila';

  @override
  String get consoSubsectionTrajets => 'Vožnje (OBD2)';

  @override
  String get consoSubsectionToggles => 'Vožnja';

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
  String get greeceApiProvider => 'Paratiritirio Timon (Greece)';

  @override
  String get greeceCommunityApiNotice =>
      'Pokreće ga API fuelpricesgr koji održava zajednica';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Pokreće pretcarburant.ro (Vijeće za tržišno natjecanje + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Postaje u $country $km km dalje — €$price/L jeftinije';
  }

  @override
  String get crossBorderTapToSwitch => 'Dodirnite za promjenu države';

  @override
  String get crossBorderDismissTooltip => 'Odbaci';

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
  String get ecoRouteOption => 'Eko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L uštede';
  }

  @override
  String get ecoRouteHint =>
      'Pametnije upravljanje — prednost autocesti pred zaobilaznim rutama.';

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
  String get featureLabel_unifiedSearchResults =>
      'Objedinjeni rezultati pretraživanja';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Jedinstvena lista rezultata koja kombinira benzinske i EV postaje.';

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
  String get featureBlockedEnable_showFuel => 'Preduvjeti nisu ispunjeni';

  @override
  String get featureBlockedEnable_showElectric => 'Preduvjeti nisu ispunjeni';

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
  String get scanPumpUnreadable =>
      'Zaslon pumpe nije čitljiv — pokušajte ponovo';

  @override
  String get scanPumpSuccess =>
      'Zaslon pumpe skeniran — provjerite vrijednosti.';

  @override
  String scanPumpFailed(String error) {
    return 'Skeniranje pumpe nije uspjelo: $error';
  }

  @override
  String get badScanReportTitle => 'Prijavi grešku skeniranja';

  @override
  String get badScanReportTitleReceipt => 'Prijavi grešku skeniranja — Račun';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Prijavi grešku skeniranja — Zaslon pumpe';

  @override
  String get pumpScanFailureTitle => 'Zaslon nije čitljiv';

  @override
  String get pumpScanFailureBody =>
      'Skeniranje nije moglo pročitati zaslon pumpe. Što želite napraviti?';

  @override
  String get pumpScanFailureCorrectManually => 'Ispravi ručno';

  @override
  String get pumpScanFailureReport => 'Prijavi';

  @override
  String get pumpScanFailureRemove => 'Ukloni fotografiju';

  @override
  String get badScanReportHint =>
      'Dijelit ćemo fotografiju računa i oba skupa vrijednosti kako bi sljedeće verzije mogle naučiti ovaj raspored.';

  @override
  String get badScanReportShareAction => 'Dijeli izvješće + fotografiju';

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
  String get pumpCameraHint =>
      'Poravnajte tri broja sa zaslona crpke unutar okvira';

  @override
  String get pumpCameraCapture => 'Snimi';

  @override
  String get pumpCameraPermissionDenied =>
      'Pristup kameri potreban je za skeniranje zaslona crpke. Omogućite ga u postavkama uređaja.';

  @override
  String get pumpCameraError =>
      'Kamera se nije mogla pokrenuti. Pokušajte ponovno ili unesite vrijednosti ručno.';

  @override
  String get fillUpSectionWhatTitle => 'Što ste natočili';

  @override
  String get fillUpSectionWhatSubtitle => 'Gorivo, količina, cijena';

  @override
  String get fillUpSectionWhereTitle => 'Gdje ste bili';

  @override
  String get fillUpSectionWhereSubtitle => 'Postaja, kilometar-sat, napomene';

  @override
  String get fillUpImportFromLabel => 'Uvezi iz…';

  @override
  String get fillUpImportSheetTitle => 'Uvezi podatke o punjenju';

  @override
  String get fillUpImportReceiptLabel => 'Račun';

  @override
  String get fillUpImportReceiptDescription =>
      'Skenirajte papirnati račun kamerom';

  @override
  String get fillUpImportPumpLabel => 'Zaslon pumpe';

  @override
  String get fillUpImportPumpDescription =>
      'Čitanje Betrag / Preis s LCD zaslona pumpe';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Čitanje kilometar-sata s OBD-II priključka putem Bluetootha';

  @override
  String get fillUpPricePerLiterLabel => 'Cijena po litri';

  @override
  String get vehicleHeaderPlateLabel => 'Registracija';

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
  String get hapticEcoCoachSectionTitle => 'Vožnja';

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
  String get privacyLocalDataEmpty =>
      'Još ništa nije pohranjeno. Dodajte omiljenu postaju ili postavite upozorenje na cijenu za prikaz unosa ovdje.';

  @override
  String get privacyHideEmptyRows => 'Sakrij prazne retke';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prikaži $count praznih redaka',
      one: 'Prikaži $count prazan redak',
    );
    return '$_temp0';
  }

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
  String get routeStrategyLabel => 'Strategija:';

  @override
  String get routeStrategyUniform => 'Jednoličan';

  @override
  String get routeStrategyBalanced => 'Uravnotežen';

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
  String get consentSyncTripsNeedsEmailHint =>
      'Prijavite se s računom e-pošte za sinkronizaciju vožnji među uređajima.';

  @override
  String get consentHideDetails => 'Sakrij pojedinosti';

  @override
  String get consentShowDetails => 'Prikaži pojedinosti';

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
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nije moguće dosegnuti \'$adapterName\' — odaberite drugi adapter';
  }

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
  String get onboardingObd2VinReadFailed =>
      'Nije moguće pročitati VIN — unesite ručno';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nije moguće spojiti se na adapter. Možete ponoviti pokušaj ili preskočiti.';

  @override
  String get onboardingPickUseMode => 'Odaberite način korištenja za nastavak.';

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
  String get radiusAlertCenterFromMap => 'Lokacija na karti';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel kod $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Postaja je na $price € (cilj: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesija';

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
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Zadnje punjenje: $date · $count vožnja(i) od tada';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 izmjereno';

  @override
  String get tankLevelMethodDistanceFallback =>
      'procjena na temelju udaljenosti';

  @override
  String get tankLevelMethodMixed => 'mješovita mjerenja';

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
  String get trajetDetailChartsSection => 'Grafikoni';

  @override
  String get trajetsRowColdStartChip => 'Hladan start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motor nije dostigao radnu temperaturu za vrijeme ove vožnje — potrošnja goriva bila je viša od uobičajene.';

  @override
  String get trajetDetailChartEmpty => 'Nema snimljenih uzoraka';

  @override
  String get trajetDetailShareAction => 'Dijeli';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — vožnja na $date';
  }

  @override
  String get trajetDetailShareError =>
      'Nije moguće generirati sliku za dijeljenje';

  @override
  String get trajetDetailDeleteAction => 'Obriši';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Obrisati ovu vožnju?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ova vožnja bit će trajno uklonjena iz vaše povijesti.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Odustani';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Obriši';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapter spojen, ali ne vraća podatke. Pokušajte s drugim adapterom ili provjerite dijagnostički protokol vozila.';

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
  String get tripPathLegendTitle => 'Potrošnja';

  @override
  String get tripPathLegendEfficient => 'Učinkovito (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Na granici (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Rastrošno (≥ 10 L/100km)';

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
  String get tripBannerOpenFromConsumptionTab =>
      'Otvori aktivnu vožnju iz kartice Conso';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Prikačite ekran za održavanje GPS-a aktivnim za vrijeme vožnje — Android može ograničiti GPS za vrijeme spavanja.';

  @override
  String get tripRecordingMinimiseTooltip => 'Smanji u plutajuću pločicu';

  @override
  String get unifiedFilterFuel => 'Gorivo';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Oboje';

  @override
  String get unifiedNoResultsForFilter =>
      'Nema rezultata koji odgovaraju ovom filteru';

  @override
  String get searchFailedSnackbar =>
      'Pretraživanje nije uspjelo — molimo pokušajte ponovo';

  @override
  String get vinLabel => 'VIN (neobavezno)';

  @override
  String get vinDecodeTooltip => 'Dekodiraj VIN';

  @override
  String get vinConfirmAction => 'Da, automatski popuni';

  @override
  String get vinModifyAction => 'Izmijeni ručno';

  @override
  String get veResetAction => 'Resetiraj volumetrijsku učinkovitost';

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
  String get vehicleDetectedFromVinBadge => '(otkriveno)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Otkriveno iz VIN-a: $summary. Primijeniti?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Primijeni';

  @override
  String waitTimeHint(int minutes) {
    return '~$minutes min čekanja';
  }

  @override
  String get waitTimeTrackStart => 'Prati moje čekanje';

  @override
  String get waitTimeTrackEnd => 'Odlazim';

  @override
  String waitTimeElapsedShort(int minutes) {
    return '$minutes min do sada';
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
  String get widgetVariantDefault => 'Samo trenutna cijena';

  @override
  String get widgetVariantPredictive =>
      'Prediktivno: najbolje vrijeme za punjenje';

  @override
  String get widgetPredictiveNowPrefix => 'sada';
}
