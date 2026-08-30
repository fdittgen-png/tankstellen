// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Iskanje';

  @override
  String get favorites => 'Priljubljene';

  @override
  String get map => 'Zemljevid';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Nastavitve';

  @override
  String get gpsLocation => 'GPS lokacija';

  @override
  String get zipCode => 'Poštna številka';

  @override
  String get zipCodeHint => 'npr. 1000';

  @override
  String get fuelType => 'Gorivo';

  @override
  String get searchRadius => 'Polmer';

  @override
  String get searchNearby => 'Bencinske postaje v bližini';

  @override
  String get fabRunSearch => 'Zaženi iskanje';

  @override
  String get routeSearchingChip => 'Iskanje poti…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Vsakih $km km';
  }

  @override
  String get searchCriteriaTitle => 'Merila iskanja';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'V $km km';
  }

  @override
  String get noResults => 'Ni najdenih bencinskih postaj.';

  @override
  String get startSearch => 'Iščite bencinske postaje.';

  @override
  String get open => 'Odprto';

  @override
  String get closed => 'Zaprto';

  @override
  String distance(String distance) {
    return '$distance stran';
  }

  @override
  String get price => 'Cena';

  @override
  String get prices => 'Cene';

  @override
  String get address => 'Naslov';

  @override
  String get openingHours => 'Odpiralni čas';

  @override
  String get open24h => 'Odprto 24 ur';

  @override
  String get navigate => 'Navigiraj';

  @override
  String get retry => 'Poskusi znova';

  @override
  String get apiKeySetup => 'API ključ';

  @override
  String get apiKeyLabel => 'API ključ';

  @override
  String get register => 'Registracija';

  @override
  String get continueButton => 'Nadaljuj';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle => 'Najdite najcenejše gorivo v bližini.';

  @override
  String get profileName => 'Ime profila';

  @override
  String get preferredFuel => 'Prednostno gorivo';

  @override
  String get defaultRadius => 'Privzeti polmer';

  @override
  String get landingScreen => 'Začetni zaslon';

  @override
  String get homeZip => 'Domača poštna številka';

  @override
  String get newProfile => 'Nov profil';

  @override
  String get editProfile => 'Uredi profil';

  @override
  String get save => 'Shrani';

  @override
  String get cancel => 'Prekliči';

  @override
  String get countryChangeTitle => 'Zamenjati državo?';

  @override
  String countryChangeBody(String country) {
    return 'Preklop na $country bo spremenil:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Razdalja';

  @override
  String get countryChangeVolume => 'Prostornina';

  @override
  String get countryChangePricePerUnit => 'Format cene';

  @override
  String get countryChangeNote =>
      'Obstoječe priljubljene postaje in dnevniki polnjenja se ne prepišejo; samo novi vnosi bodo v novih enotah.';

  @override
  String get countryChangeConfirm => 'Preklopi';

  @override
  String get delete => 'Izbriši';

  @override
  String get activate => 'Aktiviraj';

  @override
  String get configured => 'Nastavljeno';

  @override
  String get notConfigured => 'Ni nastavljeno';

  @override
  String get about => 'O aplikaciji';

  @override
  String get openSource => 'Odprtokodna (licenca MIT)';

  @override
  String get sourceCode => 'Izvorna koda na GitHubu';

  @override
  String get noFavorites => 'Ni priljubljenih';

  @override
  String get noFavoritesHint =>
      'Tapnite zvezdico pri postaji, da jo dodate med priljubljene.';

  @override
  String get language => 'Jezik';

  @override
  String get country => 'Država';

  @override
  String get freeNoKey => 'Brezplačno — ključ ni potreben';

  @override
  String get apiKeyRequired => 'Potreben API ključ';

  @override
  String get dataTransparency => 'Preglednost podatkov';

  @override
  String get storageAndCache => 'Shramba in predpomnilnik';

  @override
  String get clearCache => 'Počisti predpomnilnik';

  @override
  String stationsFound(int count) {
    return 'Najdenih $count postaj';
  }

  @override
  String get storageUsage => 'Poraba shrambe na tej napravi';

  @override
  String get settingsLabel => 'Nastavitve';

  @override
  String get profilesStored => 'shranjenih profilov';

  @override
  String get stationsMarked => 'označenih postaj';

  @override
  String get cachedResponses => 'predpomnjenih odgovorov';

  @override
  String get total => 'Skupaj';

  @override
  String get cacheManagement => 'Upravljanje predpomnilnika';

  @override
  String get cacheDescription =>
      'Predpomnilnik shranjuje API odgovore za hitrejše nalaganje in dostop brez povezave.';

  @override
  String get cacheTtlGroupNetwork => 'Omrežje';

  @override
  String get cacheTtlGroupData => 'Podatki';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodiranje';

  @override
  String get stationSearch => 'Iskanje postaj';

  @override
  String get stationDetails => 'Podrobnosti postaje';

  @override
  String get priceQuery => 'Poizvedba o ceni';

  @override
  String get zipGeocoding => 'Geokodiranje poštne številke';

  @override
  String minutes(int n) {
    return '$n minut';
  }

  @override
  String hours(int n) {
    return '$n ur';
  }

  @override
  String get clearCacheTitle => 'Počistiti predpomnilnik?';

  @override
  String get clearCacheBody =>
      'Predpomnjeni rezultati iskanja in cene bodo izbrisani. Profili, priljubljene in nastavitve so ohranjeni.';

  @override
  String get clearCacheButton => 'Počisti predpomnilnik';

  @override
  String get deleteAllTitle => 'Izbrisati vse podatke?';

  @override
  String get deleteAllBody =>
      'To trajno izbriše vse profile, priljubljene, API ključ, nastavitve in predpomnilnik. Aplikacija se ponastavi.';

  @override
  String get deleteAllButton => 'Izbriši vse';

  @override
  String get entries => 'vnosov';

  @override
  String get cacheEmpty => 'Predpomnilnik je prazen';

  @override
  String get apiKeyNote =>
      'Brezplačna registracija. Podatki od vladnih agencij za cenovno preglednost.';

  @override
  String get apiKeyFormatError =>
      'Neveljavna oblika — pričakovan UUID (8-4-4-4-12)';

  @override
  String get reportThisIssue => 'Prijavi to težavo';

  @override
  String get reportAlreadySent => 'To težavo ste že prijavili.';

  @override
  String get reportConsentTitle => 'Prijaviti na GitHub?';

  @override
  String get reportConsentBody =>
      'S tem bo odprta javna prijava na GitHub z spodnjimi podrobnostmi napake. Koordinate GPS, ključi API ali osebni podatki niso vključeni.';

  @override
  String get reportConsentConfirm => 'Odpri GitHub';

  @override
  String get reportConsentCancel => 'Prekliči';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktivni profil';

  @override
  String get configPreferredFuel => 'Prednostno gorivo';

  @override
  String get configCountry => 'Država';

  @override
  String get configRouteSegment => 'Odsek poti';

  @override
  String get configApiKeysSection => 'Ključi API';

  @override
  String get configTankerkoenigKey => 'Ključ API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Nastavljeno';

  @override
  String get configApiKeyCommunity => 'Privzeto (skupnostni ključ)';

  @override
  String get searchLocationPlaceholder => 'Naslov, poštna številka ali kraj';

  @override
  String get configEvKey => 'Ključ API za polnjenje EV';

  @override
  String get configEvKeyCustom => 'Lasten ključ';

  @override
  String get configEvKeyShared => 'Privzeto (deljeno)';

  @override
  String get configCloudSyncSection => 'Sinhronizacija v oblaku';

  @override
  String get configTankSyncConnected => 'Povezano';

  @override
  String get configTankSyncDisabled => 'Onemogočeno';

  @override
  String get configAuthMode => 'Način prijave';

  @override
  String get configAuthEmail => 'E-pošta (trajno)';

  @override
  String get configAuthAnonymous => 'Anonimno (samo naprava)';

  @override
  String get configDatabase => 'Podatkovna baza';

  @override
  String get configPrivacySummary => 'Povzetek zasebnosti';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Priljubljene, opozorila in skrite postaje se sinhronizirajo z vašo zasebno bazo\n• Lokacija GPS in ključi API nikoli ne zapustijo naprave\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Vsi podatki so shranjeni samo lokalno na tej napravi\n• Nobeni podatki se ne pošiljajo na strežnik\n• Ključi API šifrirani v varnem pomnilniku naprave';

  @override
  String get configAuthNoteEmail =>
      'E-poštni račun omogoča dostop z več naprav';

  @override
  String get configAuthNoteAnonymous =>
      'Anonimni račun — podatki vezani na to napravo';

  @override
  String get configNone => 'Brez';

  @override
  String get privacyPolicy => 'Pravilnik o zasebnosti';

  @override
  String get fuels => 'Goriva';

  @override
  String get services => 'Storitve';

  @override
  String get zone => 'Cona';

  @override
  String get highway => 'Avtocesta';

  @override
  String get localStation => 'Lokalna postaja';

  @override
  String get lastUpdate => 'Zadnja posodobitev';

  @override
  String get automate24h => '24ur/24 — Avtomat';

  @override
  String get refreshPrices => 'Osveži cene';

  @override
  String get station => 'Bencinska postaja';

  @override
  String get locationDenied =>
      'Dovoljenje za lokacijo zavrnjeno. Iščete lahko po poštni številki.';

  @override
  String get demoModeBanner => 'Demo način. Nastavite API ključ v nastavitvah.';

  @override
  String get demoModeBannerAction => 'Pridobi dejanske cene';

  @override
  String get sortDistance => 'Razdalja';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Ocena';

  @override
  String get sortPriceDistance => 'Cena/km';

  @override
  String get cheap => 'poceni';

  @override
  String get expensive => 'drago';

  @override
  String get reportPrice => 'Prijavi ceno';

  @override
  String get whatsWrong => 'Kaj ni v redu?';

  @override
  String get correctPrice => 'Pravilna cena (npr. 1,459)';

  @override
  String get sendReport => 'Pošlji prijavo';

  @override
  String get reportSent => 'Prijava poslana. Hvala!';

  @override
  String get enterValidPrice => 'Vnesite veljavno ceno';

  @override
  String get cacheCleared => 'Predpomnilnik počiščen.';

  @override
  String get yourPosition => 'Vaša pozicija';

  @override
  String get positionUnknown => 'Pozicija neznana';

  @override
  String get distancesFromCenter => 'Razdalje od središča iskanja';

  @override
  String get autoUpdatePosition => 'Samodejno posodobi pozicijo';

  @override
  String get autoUpdateDescription =>
      'Posodobi GPS pozicijo pred vsakim iskanjem';

  @override
  String get location => 'Lokacija';

  @override
  String get switchProfileTitle => 'Država spremenjena';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Zdaj ste v $country. Preklopiti na profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Preklopljeno na profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ni profila za to državo';

  @override
  String noProfileForCountry(String country) {
    return 'Ste v $country, vendar ni nastavljenega profila. Ustvarite ga v Nastavitvah.';
  }

  @override
  String get autoSwitchProfile => 'Samodejna zamenjava profila';

  @override
  String get autoSwitchDescription =>
      'Samodejno zamenjaj profil ob prečkanju meje';

  @override
  String profileSwitchedTo(String profile) {
    return 'Preklopljeno na $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name ustvarjen';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Profil za $country že obstaja — raje ga uredite.';
  }

  @override
  String get switchProfile => 'Zamenjaj';

  @override
  String get dismiss => 'Zapri';

  @override
  String get profileCountry => 'Država';

  @override
  String get profileLanguage => 'Jezik';

  @override
  String get settingsStorageDetail => 'API ključ, aktivni profil';

  @override
  String get allFuels => 'Vse';

  @override
  String get priceAlerts => 'Cenovna opozorila';

  @override
  String get noPriceAlerts => 'Ni cenovnih opozoril';

  @override
  String get noPriceAlertsHint =>
      'Ustvarite opozorilo s strani s podrobnostmi postaje.';

  @override
  String alertDeleted(String name) {
    return 'Opozorilo \"$name\" izbrisano';
  }

  @override
  String get createAlert => 'Ustvari cenovno opozorilo';

  @override
  String currentPrice(String price) {
    return 'Trenutna cena: $price';
  }

  @override
  String get targetPrice => 'Ciljna cena (EUR)';

  @override
  String get enterPrice => 'Vnesite ceno';

  @override
  String get invalidPrice => 'Neveljavna cena';

  @override
  String get priceTooHigh => 'Cena previsoka';

  @override
  String get create => 'Ustvari';

  @override
  String get alertCreated => 'Cenovno opozorilo ustvarjeno';

  @override
  String get wrongE5Price => 'Napačna cena Super E5';

  @override
  String get wrongE10Price => 'Napačna cena Super E10';

  @override
  String get wrongDieselPrice => 'Napačna cena dizla';

  @override
  String get wrongStatusOpen => 'Prikazano kot odprto, vendar zaprto';

  @override
  String get wrongStatusClosed => 'Prikazano kot zaprto, vendar odprto';

  @override
  String get allStations => 'Vse postaje';

  @override
  String get bestStops => 'Najboljše postanke';

  @override
  String get openInMaps => 'Odpri v Zemljevidih';

  @override
  String get noStationsAlongRoute => 'Vzdolž poti ni najdenih postaj';

  @override
  String get evOperational => 'V obratovanju';

  @override
  String get evStatusUnknown => 'Status neznan';

  @override
  String evConnectors(int count) {
    return 'Priključki ($count točk)';
  }

  @override
  String get evNoConnectors => 'Ni podrobnosti o priključkih';

  @override
  String get evUsageCost => 'Stroški uporabe';

  @override
  String get evPricingUnavailable => 'Cenik ni na voljo od ponudnika';

  @override
  String get evPriceFree => 'Brezplačno';

  @override
  String get evPricePayAtLocation => 'Plačilo na mestu';

  @override
  String get evPriceMembership => 'Zahtevano članstvo';

  @override
  String get evPriceIndicative => 'Okvirna cena';

  @override
  String get evPriceDeclaredByOperator =>
      'Okvirna cena, ki jo je navedel operater — preverite na mestu samem';

  @override
  String get evPriceFranceAttribution =>
      'Cene: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Okvirne cene iz OpenChargeMap — redke in morda nepopolne.';

  @override
  String get evLastUpdated => 'Nazadnje posodobljeno';

  @override
  String get evUnknown => 'Neznano';

  @override
  String get evDataAttribution => 'Podatki iz OpenChargeMap (skupnostni vir)';

  @override
  String get evStatusDisclaimer =>
      'Status morda ne odraža razpoložljivosti v realnem času. Tapnite osveži za najnovejše podatke.';

  @override
  String get evNavigateToStation => 'Navigiraj do postaje';

  @override
  String get evRefreshStatus => 'Osveži status';

  @override
  String get evStatusUpdated => 'Status posodobljen';

  @override
  String get evStationNotFound =>
      'Ni mogoče osvežiti — postaja ni najdena v bližini';

  @override
  String get addedToFavorites => 'Dodano med priljubljene';

  @override
  String get removedFromFavorites => 'Odstranjeno iz priljubljenih';

  @override
  String get addFavorite => 'Dodaj med priljubljene';

  @override
  String get removeFavorite => 'Odstrani iz priljubljenih';

  @override
  String get currentLocation => 'Trenutna lokacija';

  @override
  String get gpsError => 'GPS napaka';

  @override
  String get couldNotResolve => 'Ni mogoče določiti začetka ali cilja';

  @override
  String get start => 'Začetek';

  @override
  String get destination => 'Cilj';

  @override
  String get cityAddressOrGps => 'Mesto, naslov ali GPS';

  @override
  String get cityOrAddress => 'Mesto ali naslov';

  @override
  String get useGps => 'Uporabi GPS';

  @override
  String get stop => 'Postanek';

  @override
  String get addStop => 'Dodaj postanek';

  @override
  String get searchAlongRoute => 'Iskanje vzdolž poti';

  @override
  String get cheapest => 'Najcenejša';

  @override
  String nStations(int count) {
    return '$count postaj';
  }

  @override
  String nBest(int count) {
    return '$count najboljših';
  }

  @override
  String get fuelPricesTankerkoenig => 'Cene goriv (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Potrebno za iskanje cen goriv v Nemčiji';

  @override
  String get evChargingOpenChargeMap => 'Polnjenje EV (OpenChargeMap)';

  @override
  String get customKey => 'Ključ po meri';

  @override
  String get appDefaultKey => 'Privzeti ključ aplikacije';

  @override
  String get optionalOverrideKey =>
      'Neobvezno: zamenjajte vgrajeni ključ s svojim';

  @override
  String get edit => 'Uredi';

  @override
  String get fuelPricesApiKey => 'API ključ cen goriv';

  @override
  String get evChargingApiKey => 'API ključ polnjenja EV';

  @override
  String get openChargeMapApiKey => 'API ključ OpenChargeMap';

  @override
  String get routePlanningSection => 'Načrtovanje poti';

  @override
  String get routeMinSaving => 'Najmanjši prihranek';

  @override
  String get routeMinSavingOff => 'Izklopljeno';

  @override
  String get routeMinSavingOffCaption =>
      'Prikazane so vse postaje, najdene na poti';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Samo postaje znotraj $amount od najcenejše na poti';
  }

  @override
  String get routeDetourBudget => 'Največji obvoz';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Prikaži postaje do $km km od neposredne poti';
  }

  @override
  String get routeSegment => 'Segment poti';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Prikaži najcenejšo postajo vsakih $km km vzdolž poti';
  }

  @override
  String get avoidHighways => 'Izogibaj se avtocestam';

  @override
  String get avoidHighwaysDesc =>
      'Izračun poti se izogiba cestninjenim cestam in avtocestam';

  @override
  String get showFuelStations => 'Prikaži bencinske postaje';

  @override
  String get showFuelStationsDesc => 'Vključi bencin, dizel, LPG, CNG postaje';

  @override
  String get showEvStations => 'Prikaži polnilne postaje';

  @override
  String get showEvStationsDesc =>
      'Vključi električne polnilne postaje v rezultatih';

  @override
  String get noStationsAlongThisRoute => 'Vzdolž te poti ni najdenih postaj.';

  @override
  String get fuelCostCalculator => 'Kalkulator stroškov goriva';

  @override
  String get distanceKm => 'Razdalja (km)';

  @override
  String get tripCost => 'Stroški potovanja';

  @override
  String get fuelNeeded => 'Potrebno gorivo';

  @override
  String get totalCost => 'Skupni stroški';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Razdalja ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Poraba ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Cena goriva ($unit)';
  }

  @override
  String get calculatorUseMine => 'Uporabi';

  @override
  String get calculatorApplied => 'Uporabljeno';

  @override
  String get tripDetails => 'Podrobnosti vožnje';

  @override
  String get calculatorRoundTrip => 'Povratna pot';

  @override
  String get roundTripTotal => 'Povratna pot skupaj';

  @override
  String get costPerDistance => 'Strošek na km';

  @override
  String get costPerMonth => 'Strošek na mesec';

  @override
  String get calculatorEstimateMonthly => 'Oceni mesečni strošek';

  @override
  String get calculatorTripsPerMonth => 'Vožnje na mesec';

  @override
  String get calculatorTripsPerMonthHint => 'npr. 20';

  @override
  String get calculatorReset => 'Ponastavi';

  @override
  String get calculatorResultPlaceholder =>
      'Vnesite razdaljo, porabo in ceno, da vidite strošek vožnje';

  @override
  String get priceHistory => 'Zgodovina cen';

  @override
  String get ignoredStationsLabel => 'Prezrte';

  @override
  String get ratingsLabel => 'Ocene';

  @override
  String get favoritesDataCache => 'Podatki priljubljenih';

  @override
  String get citySearchCache => 'Iskanje mesta';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count sledenih postaj';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count konfiguriranih';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count skritih postaj';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count ocenjenih postaj';
  }

  @override
  String get noPriceHistory => 'Še ni zgodovine cen';

  @override
  String get noStatistics => 'Ni razpoložljivih statistik';

  @override
  String get showAllFuelTypes => 'Prikaži vse vrste goriv';

  @override
  String get connected => 'Povezano';

  @override
  String get disconnectTankSync => 'Prekini TankSync';

  @override
  String get viewMyData => 'Ogled mojih podatkov';

  @override
  String get deleteAllServerData => 'Izbriši vse podatke strežnika';

  @override
  String get deleteServerDataConfirm => 'Izbrisati vse podatke strežnika?';

  @override
  String get deleteEverything => 'Izbriši vse';

  @override
  String get allDataDeleted => 'Vsi podatki strežnika izbrisani';

  @override
  String get forgetAllSyncedTripsButton => 'Pozabi vse sinhronizirane vožnje';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Pozabiti vse sinhronizirane vožnje?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Vse povzetke voženj in podrobnosti bo odstranil s strežnika. Lokalna zgodovina voženj na tej napravi ne bo prizadeta.\n\nTega dejanja ni mogoče razveljaviti.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Pozabi vse';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Vse sinhronizirane vožnje odstranjene s strežnika';

  @override
  String get disconnect => 'Prekini';

  @override
  String get myServerData => 'Moji podatki na strežniku';

  @override
  String get anonymousUuid => 'Anonimni UUID';

  @override
  String get server => 'Strežnik';

  @override
  String get syncedData => 'Sinhronizirani podatki';

  @override
  String get pushTokens => 'Push žetoni';

  @override
  String get priceReports => 'Prijave cen';

  @override
  String get syncedTrips => 'Potovanja';

  @override
  String get totalItems => 'Skupaj elementov';

  @override
  String get estimatedSize => 'Ocenjena velikost';

  @override
  String get viewRawJson => 'Ogled surovih podatkov kot JSON';

  @override
  String get exportJson => 'Izvozi kot JSON (odložišče)';

  @override
  String get jsonCopied => 'JSON kopiran v odložišče';

  @override
  String get rawDataJson => 'Surovi podatki (JSON)';

  @override
  String get close => 'Zapri';

  @override
  String get account => 'Račun';

  @override
  String get continueAsGuest => 'Nadaljuj kot gost';

  @override
  String get createAccount => 'Ustvari račun';

  @override
  String get signIn => 'Prijava';

  @override
  String get savedRoutes => 'Shranjene poti';

  @override
  String get noSavedRoutes => 'Ni shranjenih poti';

  @override
  String get noSavedRoutesHint =>
      'Iščite vzdolž poti in jo shranite za hiter dostop pozneje.';

  @override
  String get saveRoute => 'Shrani pot';

  @override
  String get routeName => 'Ime poti';

  @override
  String itineraryDeleted(String name) {
    return '$name izbrisano';
  }

  @override
  String loadingRoute(String name) {
    return 'Nalaganje poti: $name';
  }

  @override
  String get refreshFailed => 'Osvežitev ni uspela. Poskusite znova.';

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
      'Nastavite aplikacijo v nekaj hitrih korakih.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrirajte se za brezplačni ključ API ali preskočite in raziščite aplikacijo z demo podatki.';

  @override
  String get onboardingComplete => 'Vse je pripravljeno!';

  @override
  String get onboardingCompleteHint =>
      'Te nastavitve lahko kadar koli spremenite v svojem profilu.';

  @override
  String get onboardingBack => 'Nazaj';

  @override
  String get onboardingNext => 'Naprej';

  @override
  String get onboardingSkip => 'Preskoči';

  @override
  String get onboardingFinish => 'Začni';

  @override
  String get switchToAllPricesView => 'Preklopi na pogled vseh cen';

  @override
  String get switchToCompactView => 'Preklopi na kompaktni pogled';

  @override
  String get unavailable => 'Ni razp.';

  @override
  String get outOfStock => 'Ni na zalogi';

  @override
  String get gdprTitle => 'Vaša zasebnost';

  @override
  String get gdprSubtitle =>
      'Ta aplikacija spoštuje vašo zasebnost. Izberite, katere podatke želite deliti. Te nastavitve lahko kadar koli spremenite.';

  @override
  String get gdprLocationTitle => 'Dostop do lokacije';

  @override
  String get gdprLocationDescription =>
      'Vaše koordinate se pošljejo API-ju za cene goriva za iskanje bližnjih postaj. Podatki o lokaciji se nikoli ne shranijo na strežnik in se ne uporabljajo za sledenje.';

  @override
  String get gdprLocationShort =>
      'Poiščite bližnje bencinske postaje z vašo lokacijo';

  @override
  String get gdprErrorReportingTitle => 'Poročanje o napakah';

  @override
  String get gdprErrorReportingDescription =>
      'Anonimna poročila o zrušitvah pomagajo izboljšati aplikacijo. Osebni podatki niso vključeni. Poročila se pošiljajo prek Sentry samo, ko je konfigurirano.';

  @override
  String get gdprErrorReportingShort =>
      'Pošlji anonimna poročila o zrušitvah za izboljšanje aplikacije';

  @override
  String get gdprCloudSyncTitle => 'Sinhronizacija v oblaku';

  @override
  String get gdprCloudSyncDescription =>
      'Sinhronizirajte priljubljene in opozorila med napravami prek TankSync. Uporablja anonimno avtentikacijo. Vaši podatki so med prenosom šifrirani.';

  @override
  String get gdprCloudSyncShort =>
      'Sinhronizirajte priljubljene in opozorila med napravami';

  @override
  String get gdprLegalBasis =>
      'Pravna podlaga: čl. 6(1)(a) GDPR (Privolitev). Privolitev lahko kadar koli umaknete v Nastavitvah.';

  @override
  String get gdprContinueAll => 'Nadaljuj z vsem';

  @override
  String get gdprContinueSelected => 'Nadaljuj z izbranim';

  @override
  String get gdprSettingsHint =>
      'Izbire glede zasebnosti lahko kadar koli spremenite.';

  @override
  String get routeSaved => 'Pot shranjena!';

  @override
  String get routeSaveFailed => 'Shranjevanje poti ni uspelo';

  @override
  String get sqlCopied => 'SQL kopiran v odložišče';

  @override
  String get connectionDataCopied => 'Podatki za povezavo kopirani';

  @override
  String get accountDeleted => 'Račun izbrisan. Lokalni podatki ohranjeni.';

  @override
  String get switchedToAnonymous => 'Preklop na anonimno sejo';

  @override
  String failedToSwitch(String error) {
    return 'Preklop ni uspel: $error';
  }

  @override
  String get connectedAsGuest => 'Povezano kot gost';

  @override
  String get accountCreated => 'Račun ustvarjen!';

  @override
  String get signedIn => 'Prijavljeni ste!';

  @override
  String stationHidden(String name) {
    return '$name skrita';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name odstranjena iz priljubljenih';
  }

  @override
  String invalidApiKey(String error) {
    return 'Neveljaven ključ API: $error';
  }

  @override
  String get invalidQrCode => 'Neveljaven format kode QR';

  @override
  String get invalidQrCodeTankSync =>
      'Neveljavna koda QR — pričakovan format TankSync';

  @override
  String get tankSyncConnected => 'TankSync povezan!';

  @override
  String get syncCompleted => 'Sinhronizacija končana — podatki osveženi';

  @override
  String get deviceCodeCopied => 'Koda naprave kopirana';

  @override
  String get undo => 'Razveljavi';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Vnesite veljavno $length-mestno $label';
  }

  @override
  String get freshnessAgo => 'nazaj';

  @override
  String get freshnessStale => 'Zastarelo';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Svežost podatkov: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Logotip $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oceni s $count zvezdicami',
      one: 'Oceni z 1 zvezdico',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Šibko';

  @override
  String get passwordStrengthFair => 'Srednje';

  @override
  String get passwordStrengthStrong => 'Močno';

  @override
  String get passwordReqMinLength => 'Vsaj 8 znakov';

  @override
  String get passwordReqUppercase => 'Vsaj 1 velika črka';

  @override
  String get passwordReqLowercase => 'Vsaj 1 mala črka';

  @override
  String get passwordReqDigit => 'Vsaj 1 številka';

  @override
  String get passwordReqSpecial => 'Vsaj 1 poseben znak';

  @override
  String get passwordTooWeak => 'Geslo ne izpolnjuje vseh zahtev';

  @override
  String get brandFilterAll => 'Vse';

  @override
  String get brandFilterNoHighway => 'Brez avtoceste';

  @override
  String get swipeTutorialMessage =>
      'Podrsajte desno za navigacijo, levo za odstranitev';

  @override
  String get swipeTutorialDismiss => 'Razumem';

  @override
  String get alertStatsActive => 'Aktivni';

  @override
  String get alertStatsToday => 'Danes';

  @override
  String get alertStatsThisWeek => 'Ta teden';

  @override
  String get privacyDashboardTitle => 'Nadzorna plošča zasebnosti';

  @override
  String get privacyDashboardSubtitle =>
      'Oglejte si, izvozite ali izbrišite svoje podatke';

  @override
  String get privacyDashboardBanner =>
      'Vaši podatki so vaši. Tukaj si lahko ogledate vse, kar aplikacija shranjuje, to izvozite ali izbrišete.';

  @override
  String get privacyLocalData => 'Podatki na tej napravi';

  @override
  String get privacyIgnoredStations => 'Skrite postaje';

  @override
  String get privacyRatings => 'Ocene postaj';

  @override
  String get privacyPriceHistory => 'Postaje z zgodovino cen';

  @override
  String get privacyProfiles => 'Profili iskanja';

  @override
  String get privacyItineraries => 'Shranjene poti';

  @override
  String get privacyCacheEntries => 'Vnosi predpomnilnika';

  @override
  String get privacyApiKey => 'Shranjen ključ API';

  @override
  String get privacyEvApiKey => 'Shranjen ključ API za EV';

  @override
  String get privacyEstimatedSize => 'Ocenjen prostor';

  @override
  String get privacySyncedData => 'Sinhronizacija v oblaku (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Sinhronizacija v oblaku je onemogočena. Vsi podatki ostanejo samo na tej napravi.';

  @override
  String get privacySyncMode => 'Način sinhronizacije';

  @override
  String get privacySyncUserId => 'ID uporabnika';

  @override
  String get privacySyncDescription =>
      'Ko je sinhronizacija omogočena, so priljubljene, opozorila, skrite postaje in ocene shranjene tudi na strežniku TankSync.';

  @override
  String get privacyViewServerData => 'Ogled podatkov na strežniku';

  @override
  String get privacyExportButton => 'Izvozi vse podatke kot JSON';

  @override
  String get privacyExportSuccess => 'Podatki izvoženi v odložišče';

  @override
  String get privacyExportCsvButton => 'Izvozi vse podatke kot CSV';

  @override
  String get privacyExportCsvSuccess => 'Podatki CSV izvoženi v odložišče';

  @override
  String get savedToDownloadsFolder => 'Shranjeno v mapo Prenosi';

  @override
  String get privacyDeleteButton => 'Izbriši vse podatke';

  @override
  String privacySaveErrorLog(int count) {
    return 'Shrani dnevnik napak ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Počisti dnevnik napak';

  @override
  String get privacyErrorLogCleared => 'Dnevnik napak počiščen';

  @override
  String get privacyDeleteTitle => 'Izbrisati vse podatke?';

  @override
  String get privacyDeleteBody =>
      'To bo trajno izbrisalo:\n\n- Vse priljubljene in podatke postaj\n- Vse profile iskanja\n- Vsa cenovna opozorila\n- Vso zgodovino cen\n- Vse predpomnjene podatke\n- Vaš ključ API\n- Vse nastavitve aplikacije\n\nAplikacija se bo ponastavila na začetno stanje. Tega dejanja ni mogoče razveljaviti.';

  @override
  String get privacyDeleteConfirm => 'Izbriši vse';

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
  String get paymentMethods => 'Načini plačila';

  @override
  String get paymentMethodCash => 'Gotovina';

  @override
  String get paymentMethodCard => 'Kartica';

  @override
  String get paymentMethodContactless => 'Brez stika';

  @override
  String get paymentMethodFuelCard => 'Kartica za gorivo';

  @override
  String get paymentMethodApp => 'Aplikacija';

  @override
  String payWithApp(String app) {
    return 'Plačaj z $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'V primerjavi z drsečim povprečjem vaših zadnjih 3 polnjenj ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Poraba $value L/100 km, $delta glede na vaše drseče povprečje';
  }

  @override
  String get drivingMode => 'Način vožnje';

  @override
  String get drivingExit => 'Izhod';

  @override
  String get drivingNearestStation => 'Najbližja';

  @override
  String get drivingTapToUnlock => 'Tapnite za odklep';

  @override
  String get drivingSafetyTitle => 'Varnostno opozorilo';

  @override
  String get drivingSafetyMessage =>
      'Med vožnjo ne upravljajte aplikacije. Ustavite se na varnem mestu, preden komunicirate z zaslonom. Voznik je odgovoren za varno upravljanje vozila ves čas.';

  @override
  String get drivingSafetyAccept => 'Razumem';

  @override
  String get voiceAnnouncementsTitle => 'Glasovna obvestila';

  @override
  String get voiceAnnouncementsDescription =>
      'Napovej bližnje poceni postaje med vožnjo';

  @override
  String get voiceAnnouncementsEnabled => 'Omogoči glasovna obvestila';

  @override
  String get voiceAnnouncementProximityRadius => 'Polmer obvestil';

  @override
  String get voiceAnnouncementCooldown => 'Interval ponavljanja';

  @override
  String get voiceAnnouncementPriceLimit => 'Najvišja cena';

  @override
  String get consumptionStatsTitle => 'Statistika porabe';

  @override
  String get addFillUp => 'Dodaj polnjenje';

  @override
  String get noFillUpsTitle => 'Še ni polnjenj';

  @override
  String get noFillUpsSubtitle =>
      'Zabeležite prvo polnjenje za začetek sledenja porabe.';

  @override
  String get fillUpDate => 'Datum';

  @override
  String get liters => 'Litri';

  @override
  String get odometerKm => 'Števec km (km)';

  @override
  String get notesOptional => 'Opombe (neobvezno)';

  @override
  String get stationPreFilled => 'Postaja predizpolnjena';

  @override
  String get statAvgConsumption => 'Povpr. L/100km';

  @override
  String get statAvgCostPerKm => 'Povpr. strošek/km';

  @override
  String get statTotalLiters => 'Skupaj litrov';

  @override
  String get statTotalSpent => 'Skupaj porabljeno';

  @override
  String get statFillUpCount => 'Polnjenja';

  @override
  String get fieldRequired => 'Obvezno';

  @override
  String get fieldInvalidNumber => 'Neveljavna številka';

  @override
  String get carbonDashboardTitle => 'Ogljična nadzorna plošča';

  @override
  String get carbonEmptyTitle => 'Še ni podatkov';

  @override
  String get carbonEmptySubtitle =>
      'Zabeležite polnjenja za prikaz ogljične nadzorne plošče.';

  @override
  String get carbonSummaryTotalCost => 'Skupni strošek';

  @override
  String get carbonSummaryTotalCo2 => 'Skupaj CO2';

  @override
  String get monthlyCostsTitle => 'Mesečni stroški';

  @override
  String get monthlyEmissionsTitle => 'Mesečne emisije CO2';

  @override
  String get vehiclesTitle => 'Moja vozila';

  @override
  String get vehiclesMenuTitle => 'Moja vozila';

  @override
  String get vehiclesMenuSubtitle =>
      'Baterija, priključki, nastavitve polnjenja';

  @override
  String get vehiclesEmptyMessage =>
      'Dodajte vozilo za filtriranje po priključku in oceno stroškov polnjenja.';

  @override
  String get vehiclesWizardTitle => 'Moja vozila (neobvezno)';

  @override
  String get vehiclesWizardSubtitle =>
      'Dodajte vozilo za predizpolnitev dnevnika porabe in filtre priključkov EV. To lahko preskočite in dodate vozila pozneje.';

  @override
  String get vehiclesWizardNoneYet => 'Ni konfiguriranega vozila.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vozil',
      one: '1 vozilo',
    );
    return 'Imate $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Preskočite za dokončanje nastavitve — vozila lahko kadar koli dodate v Nastavitvah.';

  @override
  String get fillUpVehicleLabel => 'Vozilo';

  @override
  String get fillUpVehicleRequired => 'Vozilo je obvezno';

  @override
  String get reportScanError => 'Prijavi napako skeniranja';

  @override
  String get pickStationTitle => 'Izberite postajo';

  @override
  String get pickStationHelper =>
      'Začnite polnjenje na znani postaji, da se cene, blagovna znamka in vrsta goriva samodejno izpolnijo.';

  @override
  String get pickStationEmpty =>
      'Še ni priljubljenih postaj — dodajte jih iz iskanja ali priljubljenih ali preskočite in izpolnite ročno.';

  @override
  String get pickStationSkip => 'Preskoči — dodaj brez postaje';

  @override
  String get scanPayment => 'Skeniraj QR za plačilo';

  @override
  String get qrPaymentBeneficiary => 'Prejemnik';

  @override
  String get qrPaymentAmount => 'Znesek';

  @override
  String get qrPaymentEpcTitle => 'SEPA plačilo';

  @override
  String get qrPaymentEpcEmpty => 'Nobeno polje ni dekodirano';

  @override
  String get qrPaymentOpenInBank => 'Odpri v bančni aplikaciji';

  @override
  String get qrPaymentLaunchFailed => 'Ni aplikacije za odpiranje te kode';

  @override
  String get qrPaymentUnknownTitle => 'Neprepoznana koda';

  @override
  String get qrPaymentCopyRaw => 'Kopiraj surovo besedilo';

  @override
  String get qrPaymentCopiedRaw => 'Kopirano v odložišče';

  @override
  String get qrPaymentReport => 'Prijavi to skeniranje';

  @override
  String get qrPaymentEpcCopied =>
      'Bančni podatki kopirani — prilepite v svojo bančno aplikacijo';

  @override
  String get qrScannerGuidance => 'Usmerite kamero na kodo QR';

  @override
  String get qrScannerPermissionDenied =>
      'Za skeniranje kod QR je potreben dostop do kamere.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Dostop do kamere je bil zavrnjen. Odprite nastavitve in ga omogočite.';

  @override
  String get qrScannerRetryPermission => 'Poskusi znova';

  @override
  String get qrScannerOpenSettings => 'Odpri nastavitve';

  @override
  String get qrScannerTimeout =>
      'Koda QR ni zaznana. Približajte se ali poskusite znova.';

  @override
  String get qrScannerRetry => 'Poskusi znova';

  @override
  String get torchOn => 'Vklopi bliskavico';

  @override
  String get torchOff => 'Izklopi bliskavico';

  @override
  String get obdPermissionDenied =>
      'Dovolite Bluetooth v sistemskih nastavitvah';

  @override
  String get obdPickerTitle => 'Izberite adapter OBD2';

  @override
  String get obdPickerScanning => 'Iskanje adapterjev…';

  @override
  String get obdPickerConnecting => 'Povezovanje…';

  @override
  String get tripRecordingTitle => 'Snemanje vožnje';

  @override
  String get tripSummaryTitle => 'Povzetek vožnje';

  @override
  String get tripMetricDistance => 'Razdalja';

  @override
  String get tripMetricSpeed => 'Hitrost';

  @override
  String get tripMetricFuelUsed => 'Porabljeno gorivo';

  @override
  String get tripMetricAvgConsumption => 'Povpr.';

  @override
  String get tripMetricElapsed => 'Preteklo';

  @override
  String get tripMetricOdometer => 'Števec km';

  @override
  String get tripStop => 'Ustavi snemanje';

  @override
  String get tripPause => 'Pavza';

  @override
  String get tripResume => 'Nadaljuj';

  @override
  String get tripBannerRecording => 'Snemanje vožnje';

  @override
  String get tripBannerPaused => 'Vožnja v pavzi — tapnite za nadaljevanje';

  @override
  String get navConsumption => 'Poraba';

  @override
  String get vehicleBaselineSectionTitle => 'Umerjanje izhodišča';

  @override
  String get vehicleBaselineEmpty =>
      'Še ni vzorcev — začnite vožnjo OBD2 za učenje profila porabe goriva tega vozila.';

  @override
  String get vehicleBaselineProgress =>
      'Naučeno iz vzorcev v različnih situacijah vožnje.';

  @override
  String get vehicleBaselineReset => 'Ponastavi izhodišče situacij vožnje';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Ponastaviti izhodišče situacij vožnje?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'To izbriše vse naučene vzorce za to vozilo. Vrnil se boste na privzete vrednosti hladnega zagona, dokler nove vožnje ne napolnijo profila.';

  @override
  String get vehicleBaselineShowDetails => 'Prikaži razčlenitev po situacijah';

  @override
  String get vehicleBaselineHideDetails => 'Skrij razčlenitev po situacijah';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Še ni zaznano: $situations. Za te situacije vožnje je vzorcev še 0, zato referenčna vrednost ni popolna.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'Adapter OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Ni sparovanega adapterja. Sparajte enega, da se aplikacija samodejno poveže naslednjič.';

  @override
  String get vehicleAdapterUnnamed => 'Neznan adapter';

  @override
  String get vehicleAdapterPair => 'Sparaj adapter';

  @override
  String get vehicleAdapterForget => 'Pozabi adapter';

  @override
  String get achievementsTitle => 'Dosežki';

  @override
  String get achievementFirstTrip => 'Prva vožnja';

  @override
  String get achievementFirstTripDesc => 'Posnemite svojo prvo vožnjo OBD2.';

  @override
  String get achievementFirstFillUp => 'Prvo polnjenje';

  @override
  String get achievementFirstFillUpDesc => 'Zabeležite svoje prvo polnjenje.';

  @override
  String get achievementTenTrips => '10 voženj';

  @override
  String get achievementTenTripsDesc => 'Posnemite 10 voženj OBD2.';

  @override
  String get achievementZeroHarsh => 'Miren voznik';

  @override
  String get achievementZeroHarshDesc =>
      'Opravite vožnjo 10 km ali več brez nenadnega zaviranja ali pospeševanja.';

  @override
  String get achievementEcoWeek => 'Eko teden';

  @override
  String get achievementEcoWeekDesc =>
      'Vozite 7 zaporednih dni z vsaj eno mirno vožnjo vsak dan.';

  @override
  String get achievementPriceWin => 'Cenovna zmaga';

  @override
  String get achievementPriceWinDesc =>
      'Zabeležite polnjenje, ki je za 5 % ali več nižje od 30-dnevnega povprečja postaje.';

  @override
  String get syncBaselinesToggleTitle => 'Deli naučene profile vozil';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Naloži izhodišča porabe po vozilih, da jih druga naprava lahko prevzame.';

  @override
  String get obd2StatusConnected => 'Adapter OBD2: povezan';

  @override
  String get obd2StatusPermissionDenied =>
      'Adapter OBD2: potrebno je dovoljenje za Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Pripravljen za snemanje vožnje.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Za samodejno ponovno povezavo dovolite Bluetooth v sistemskih nastavitvah.';

  @override
  String get obd2StatusNoAdapter => 'Ni sparanega adapterja';

  @override
  String get obd2StatusForget => 'Pozabi adapter';

  @override
  String get tripHistoryTitle => 'Zgodovina voženj';

  @override
  String get tripHistoryEmptyTitle => 'Še ni voženj';

  @override
  String get tripHistoryUnknownDate => 'Neznan datum';

  @override
  String get situationIdle => 'Prosti tek';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Mestno';

  @override
  String get situationHighway => 'Avtocesta';

  @override
  String get situationDecel => 'Zaviranje';

  @override
  String get situationClimbing => 'Vzpenjanje / obremenitev';

  @override
  String get situationColdStart => 'Hladen zagon';

  @override
  String get situationSustainedLoad => 'Trajna obremenitev / vlečenje';

  @override
  String get situationPartialDecel => 'Prosto vklop';

  @override
  String get situationHardAccel => 'Močno pospeševanje';

  @override
  String get situationFuelCut => 'Izklop goriva — drsenje';

  @override
  String get tripSaveRecording => 'Shrani vožnjo';

  @override
  String get tripSummaryAutoSaved => 'Vožnja samodejno shranjena';

  @override
  String get tripSummaryDone => 'Končano';

  @override
  String get tripSummaryDelete => 'Izbriši to vožnjo';

  @override
  String get vehicleFuelNotSet => 'Ni nastavljeno';

  @override
  String get wizardVehicleDefaultBadge => 'Privzeto';

  @override
  String get wizardProfileChoiceHint =>
      'Izberite način uporabe aplikacije. To lahko pozneje spremenite v Nastavitvah.';

  @override
  String get wizardProfileChoiceFooter =>
      'Svojo izbiro lahko kadar koli spremenite v Nastavitve → Način uporabe.';

  @override
  String get wizardProfileBasicName => 'Osnovno';

  @override
  String get wizardProfileBasicDescription =>
      'Najcenejše gorivo in cene polnjenja EV v bližini. Priljubljene in cenovna opozorila.';

  @override
  String get wizardProfileMediumName => 'Srednje';

  @override
  String get wizardProfileMediumDescription =>
      'Vse iz Osnovnega, plus ročno sledenje polnjenju goriva in EV.';

  @override
  String get wizardProfileFullName => 'Polno';

  @override
  String get wizardProfileFullDescription =>
      'Vse iz Srednje, plus samodejno snemanje voženj OBD2, ocene vožnje in kartice zvestobe.';

  @override
  String get wizardProfileCustomName => 'Po meri';

  @override
  String get useModeSectionHint =>
      'Prilagodite aplikacijo dejanskemu načinu uporabe. Izbira prednastavitve omogoči ustrezni nabor funkcij.';

  @override
  String get useModeCustomSettingsDescription =>
      'Vaša kombinacija funkcij se ne ujema z nobeno prednastavitvijo. Izberite eno zgoraj za prepis ali nadaljujte s prilagajanjem posameznih funkcij v spodnjem razdelku.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Način uporabe nastavljen na $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Privzeto vozilo (neobvezno)';

  @override
  String get profileDefaultVehicleNone => 'Brez privzetega';

  @override
  String get profileFuelFromVehicleHint =>
      'Vrsta goriva izhaja iz privzetega vozila. Počistite vozilo za neposredno izbiro goriva.';

  @override
  String get consumptionNoVehicleTitle => 'Najprej dodajte vozilo';

  @override
  String get consumptionNoVehicleBody =>
      'Polnjenja so pripisana vozilu. Dodajte vozilo za začetek beleženja porabe.';

  @override
  String get vehicleAdd => 'Dodaj vozilo';

  @override
  String get vehicleAddTitle => 'Dodaj vozilo';

  @override
  String get vehicleEditTitle => 'Uredi vozilo';

  @override
  String get vehicleDeleteTitle => 'Izbrisati vozilo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Odstraniti \"$name\" iz profilov?';
  }

  @override
  String get vehicleNameLabel => 'Ime';

  @override
  String get vehicleNameHint => 'npr. Moj Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Z motorjem na notranje zgorevanje';

  @override
  String get vehicleTypeHybrid => 'Hibrid';

  @override
  String get vehicleTypeEv => 'Električno';

  @override
  String get vehicleEvSectionTitle => 'Električno';

  @override
  String get vehicleCombustionSectionTitle => 'Motor na notranje zgorevanje';

  @override
  String get vehicleBatteryLabel => 'Kapaciteta baterije (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Največja moč polnjenja (kW)';

  @override
  String get vehicleConnectorsLabel => 'Podprti priključki';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Kapaciteta rezervoarja (L)';

  @override
  String get vehiclePowerLabel => 'Moč motorja (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps KM';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Prednostno gorivo';

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
  String get connectorThreePin => '3-polni';

  @override
  String get evShowOnMap => 'Prikaži EV postaje';

  @override
  String get evAvailableOnly => 'Samo dostopne';

  @override
  String get evMinPower => 'Min moč';

  @override
  String get evStatusAvailable => 'Dostopno';

  @override
  String get evStatusOccupied => 'Zasedeno';

  @override
  String get evStatusOutOfOrder => 'Izven obratovanja';

  @override
  String get evStatusPartial => 'Delno na voljo';

  @override
  String get openOnlyFilter => 'Samo odprte';

  @override
  String get saveAsDefaults => 'Shrani kot privzete';

  @override
  String get criteriaSavedToProfile => 'Shranjeno kot privzete';

  @override
  String get updatingFavorites => 'Posodabljanje priljubljenih...';

  @override
  String get fetchingLatestPrices => 'Pridobivanje najnovejših cen';

  @override
  String get noDataAvailable => 'Ni podatkov';

  @override
  String get searchToSeeMap => 'Iščite za prikaz postaj na zemljevidu';

  @override
  String get evPowerAny => 'Katera koli';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Lokacija';

  @override
  String get sectionSetupDataSources => 'Nastavitev in viri podatkov';

  @override
  String get sectionFeaturesUsage => 'Funkcije in uporaba';

  @override
  String get sectionAccountSync => 'Račun in sinhronizacija';

  @override
  String get sectionAppearanceWidgets => 'Videz in gradniki';

  @override
  String get sectionPrivacyData => 'Zasebnost in podatki';

  @override
  String get sectionAdvancedDeveloper => 'Napredno in razvijalec';

  @override
  String get tooltipBack => 'Nazaj';

  @override
  String get tooltipClose => 'Zapri';

  @override
  String get tooltipShare => 'Deli';

  @override
  String get tooltipClearSearch => 'Počisti iskanje';

  @override
  String get minimalDriveInstantConsumption => 'Trenutna poraba';

  @override
  String get minimalDriveBehaviour => 'Slog vožnje';

  @override
  String get coachingShiftUp => 'Prestavi navzgor';

  @override
  String get coachingShiftDown => 'Prestavi navzdol';

  @override
  String get coachingEasePedal => 'Spusti plin';

  @override
  String get coachingVoiceHardAcceleration => 'Nežno na plin';

  @override
  String get coachingVoiceHarshBraking => 'Zavrite bolj nežno';

  @override
  String get coachingVoiceShiftUp => 'Prestavljajte navzgor za manj goriva';

  @override
  String get coachingVoiceShiftDown => 'Prestavi navzdol, motor se trudi';

  @override
  String get coachingVoiceEasePedal =>
      'Rahljajte pedal za manjšo porabo goriva';

  @override
  String get coachingVoiceLiftOff => 'Dvignite nogo s plina in pojdite prosto';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Glejte dlje naprej in prej rahljajte plin';

  @override
  String get coachingVoiceSmoothAccel => 'Pospeševajte bolj enakomerno';

  @override
  String get coachingVoiceSharpCorner => 'Ovinke vozite malo bolj mehko';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'To je bilo zelo močno zaviranje — ohranite večjo razdaljo';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Zelo močno pospeševanje — to res porabi gorivo';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Zelo oster ovinek — počasi noter, gladko ven';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount sunkovitih manevrov.',
      few: '$harshCount sunkoviti manevri.',
      two: '$harshCount sunkovita manevra.',
      one: 'En sunkovit manever.',
      zero: 'Lepo in gladko — brez sunkovitih manevrov.',
    );
    return 'Vožnja shranjena: $distanceKm kilometrov, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litra na 100 kilometrov';
  }

  @override
  String get voiceCoachingSettingTitle => 'Glasovni coaching med vožnjo';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Poslušajte glasovne nasvete med vožnjo — trdo pospeševanje, ostro zaviranje in namigi za prestavljanje';

  @override
  String get tooltipUseGps => 'Uporabi lokacijo GPS';

  @override
  String get tooltipShowPassword => 'Prikaži geslo';

  @override
  String get tooltipHidePassword => 'Skrij geslo';

  @override
  String get evConnectorsLabel => 'Razpoložljivi priključki';

  @override
  String get evConnectorsNone => 'Ni informacij o priključku';

  @override
  String get switchToEmail => 'Preklopi na e-pošto';

  @override
  String get switchToEmailSubtitle =>
      'Ohrani podatke, dodaj prijavo z drugih naprav';

  @override
  String get switchToAnonymousAction => 'Preklopi na anonimno';

  @override
  String get switchToAnonymousSubtitle =>
      'Ohrani lokalne podatke, uporabi novo anonimno sejo';

  @override
  String get linkDevice => 'Poveži napravo';

  @override
  String get shareDatabase => 'Deli bazo podatkov';

  @override
  String get disconnectAction => 'Odklopi';

  @override
  String get disconnectSubtitle =>
      'Ustavi sinhronizacijo (lokalni podatki ohranjeni)';

  @override
  String get deleteAccountAction => 'Izbriši račun';

  @override
  String get deleteAccountSubtitle => 'Trajno odstrani vse podatke s strežnika';

  @override
  String get localOnly => 'Samo lokalno';

  @override
  String get localOnlySubtitle =>
      'Neobvezno: sinhronizirajte priljubljene, opozorila in ocene med napravami';

  @override
  String get tankSyncSchemaOutdatedTitle =>
      'Baza v oblaku potrebuje posodobitev';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Vaša samostojno gostovana shema TankSync je zastarela — nekaterih podatkov ni mogoče sinhronizirati. Odprite čarovnika za sinhronizacijo in zaženite posodobitveni SQL v svojem projektu Supabase.';

  @override
  String get setupCloudSync => 'Nastavi sinhronizacijo v oblaku';

  @override
  String get disconnectTitle => 'Odklopiti TankSync?';

  @override
  String get disconnectBody =>
      'Sinhronizacija v oblaku bo onemogočena. Vaši lokalni podatki (priljubljene, opozorila, zgodovina) so ohranjeni na tej napravi. Podatki na strežniku niso izbrisani.';

  @override
  String get deleteAccountTitle => 'Izbrisati račun?';

  @override
  String get deleteAccountBody =>
      'To trajno izbriše vse vaše podatke s strežnika (priljubljene, opozorila, ocene, poti). Lokalni podatki na tej napravi so ohranjeni.\n\nTega ni mogoče razveljaviti.';

  @override
  String get switchToAnonymousTitle => 'Preklopi na anonimno?';

  @override
  String get switchToAnonymousBody =>
      'Odjavili se boste iz e-poštnega računa in nadaljevali z novo anonimno sejo.\n\nVaši lokalni podatki (priljubljene, opozorila) so ohranjeni na tej napravi in bodo sinhronizirani z novim anonimnim računom.';

  @override
  String get switchAction => 'Preklopi';

  @override
  String get helpBannerCriteria =>
      'Privzete nastavitve profila so predizpolnjene. Prilagodite merila spodaj za natančnejše iskanje.';

  @override
  String get helpBannerAlerts =>
      'Nastavite cenovni prag za postajo. Obveščeni boste, ko cene padejo pod njega. Preverjanja potekajo vsakih 30 minut.';

  @override
  String get helpBannerConsumption =>
      'Zabeležite vsako polnjenje za sledenje dejanski porabi in odtisu CO₂. Podrsajte levo za brisanje vnosa.';

  @override
  String get helpBannerVehicles =>
      'Dodajte vozila, da se polnjenja in preference glede goriva privzeto pravilno izpolnijo. Prvo vozilo postane privzeto.';

  @override
  String get syncNow => 'Sinhroniziraj zdaj';

  @override
  String get onboardingPreferencesTitle => 'Vaše preference';

  @override
  String get onboardingZipHelper => 'Uporablja se, ko GPS ni na voljo';

  @override
  String get onboardingRadiusHelper => 'Večji polmer = več rezultatov';

  @override
  String get onboardingPrivacy =>
      'Te nastavitve so shranjene samo na vaši napravi in se nikoli ne delijo.';

  @override
  String get onboardingLandingTitle => 'Začetni zaslon';

  @override
  String get onboardingLandingHint =>
      'Izberite, kateri zaslon se odpre ob zagonu aplikacije.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Ostanite izven aplikacije — vendar je ne zaprite.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Odprite Sparkilo enkrat po vsakem ponovnem zagonu.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple prebudi Sparkilo šele, ko ga odprete vsaj enkrat po ponovnem zagonu telefona. Po tem se vaše vožnje samodejno snemajo.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Ne odpihnite Sparkilo v preklopniku aplikacij.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Prisilno zapiranje\" pove iOS-u, naj preneha znova zaganjati aplikacijo. Vaše vožnje se bodo prenehale snemati, dokler Sparkilo znova ne odprete.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Ko iOS prosi za lokacijo »Vedno«, prosim recite da.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Varnostna funkcija, ki zabeleži vašo vožnjo, ko je adapter OBD2 počasen, potrebuje lokacijo v ozadju. Tega nikoli ne delimo.';

  @override
  String get scanReceipt => 'Skeniraj račun';

  @override
  String get brandFilterHighway => 'Avtocesta';

  @override
  String get ratingModeLocal => 'Lokalno';

  @override
  String get ratingModePrivate => 'Zasebno';

  @override
  String get ratingModeShared => 'Deljeno';

  @override
  String get ratingDescLocal => 'Ocene shranjene samo na tej napravi';

  @override
  String get ratingDescPrivate =>
      'Sinhronizirano z vašo bazo (ni vidno drugim)';

  @override
  String get ratingDescShared => 'Vidno vsem uporabnikom vaše baze';

  @override
  String get errorNoEvApiKey =>
      'Ključ API za OpenChargeMap ni konfiguriran. Dodajte ga v Nastavitvah za iskanje postaj za polnjenje EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Ponudnik podatkov ($host) ima potekel ali neveljaven certifikat TLS. Aplikacija ne more naložiti podatkov iz tega vira, dokler ponudnik tega ne odpravi. Obrnite se na $host.';
  }

  @override
  String get offlineLabel => 'Brez povezave';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nedostopno. Uporaba $current.';
  }

  @override
  String get errorTitleApiKey => 'Zahtevan ključ API';

  @override
  String get errorTitleLocation => 'Lokacija ni na voljo';

  @override
  String get errorHintNoStations =>
      'Poskusite povečati polmer iskanja ali poiščite drugo lokacijo.';

  @override
  String get errorHintApiKey => 'Konfigurirajte ključ API v Nastavitvah.';

  @override
  String get errorHintConnection =>
      'Preverite internetno povezavo in poskusite znova.';

  @override
  String get errorHintRouting =>
      'Izračun poti ni uspel. Preverite internetno povezavo in poskusite znova.';

  @override
  String get errorHintFallback =>
      'Poskusite znova ali iščite po poštni številki / imenu kraja.';

  @override
  String get alertsLoadErrorTitle => 'Vaših opozoril ni bilo mogoče naložiti';

  @override
  String get detailsLabel => 'Podrobnosti';

  @override
  String get remove => 'Odstrani';

  @override
  String get showKey => 'Prikaži ključ';

  @override
  String get hideKey => 'Skrij ključ';

  @override
  String get syncOptionalTitle => 'TankSync je neobvezen';

  @override
  String get syncOptionalDescription =>
      'Vaša aplikacija deluje popolnoma brez sinhronizacije v oblaku. TankSync vam omogoča sinhronizacijo priljubljenih, opozoril in ocen med napravami z Supabase (na voljo brezplačni nivo).';

  @override
  String get syncHowToConnectQuestion => 'Kako se želite povezati?';

  @override
  String get syncCreateOwnTitle => 'Ustvari svojo bazo podatkov';

  @override
  String get syncCreateOwnSubtitle =>
      'Brezplačen projekt Supabase — vodili vas bomo korak za korakom';

  @override
  String get syncJoinExistingTitle => 'Pridruži se obstoječi bazi podatkov';

  @override
  String get syncJoinExistingSubtitle =>
      'Skenirajte kodo QR od lastnika baze ali prilepite poverilnice';

  @override
  String get syncChooseAccountType => 'Izberite vrsto računa';

  @override
  String get syncAccountTypeAnonymous => 'Anonimno';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Takojšnje, brez e-pošte. Podatki vezani na to napravo.';

  @override
  String get syncAccountTypeEmail => 'E-poštni račun';

  @override
  String get syncAccountTypeEmailDesc =>
      'Prijavite se z katere koli naprave. Obnovite podatke ob izgubi telefona.';

  @override
  String get syncHaveAccountSignIn => 'Že imate račun? Prijavite se';

  @override
  String get syncCreateNewAccount => 'Ustvari nov račun';

  @override
  String get syncTestConnection => 'Preizkusi povezavo';

  @override
  String get syncTestingConnection => 'Preizkušanje...';

  @override
  String get syncConnectButton => 'Poveži';

  @override
  String get syncConnectingButton => 'Povezovanje...';

  @override
  String get syncDatabaseReady => 'Baza podatkov pripravljena!';

  @override
  String get syncDatabaseNeedsSetup => 'Baza podatkov potrebuje nastavitev';

  @override
  String get syncTableStatusOk => 'V redu';

  @override
  String get syncTableStatusMissing => 'Manjkajoče';

  @override
  String get syncSqlEditorInstructions =>
      'Kopirajte spodnji SQL in ga zaženite v urejevalniku SQL Supabase (Nadzorna plošča → SQL Editor → Nova poizvedba → Prilepi → Zaženi)';

  @override
  String get syncCopySqlButton => 'Kopiraj SQL v odložišče';

  @override
  String get syncRecheckSchemaButton => 'Preveri shemo znova';

  @override
  String get syncSchemaOutdated =>
      'Vaša shema TankSync je zastarela — znova zaženite spodnji namestitveni SQL, da omogočite najnovejše sinhronizirane funkcije.';

  @override
  String get syncDoneButton => 'Končano';

  @override
  String syncSignedInAs(String email) {
    return 'Prijavljeni kot $email';
  }

  @override
  String get syncEmailDescription =>
      'Vaši podatki se sinhronizirajo med vsemi napravami s to e-pošto.';

  @override
  String get syncSwitchToAnonymousTitle => 'Preklopi na anonimno';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Nadaljujte brez e-pošte, nova anonimna seja';

  @override
  String get syncGuestDescription => 'Anonimno, brez e-pošte.';

  @override
  String get syncOrDivider => 'ali';

  @override
  String get syncHowToSyncQuestion => 'Kako želite sinhronizirati?';

  @override
  String get syncOfflineDescription =>
      'Vaša aplikacija deluje popolnoma brez povezave. Sinhronizacija v oblaku je neobvezna.';

  @override
  String get syncModeCommunityTitle => 'Skupnost Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Skupna podatkovna baza, ki jo upravlja razvijalec — spodaj si oglejte, kaj se sinhronizira';

  @override
  String get syncModePrivateTitle => 'Zasebna baza podatkov';

  @override
  String get syncModePrivateSubtitle =>
      'Vaš lastni Supabase — popoln nadzor nad podatki';

  @override
  String get syncModeGroupTitle => 'Pridruži se skupini';

  @override
  String get syncModeGroupSubtitle => 'Deljenja baza za družino ali prijatelje';

  @override
  String get syncPrivacyShared => 'Deljeno';

  @override
  String get syncPrivacyPrivate => 'Zasebno';

  @override
  String get syncPrivacyGroup => 'Skupina';

  @override
  String get syncStayOfflineButton => 'Ostani brez povezave';

  @override
  String get syncSuccessTitle => 'Uspešno povezano!';

  @override
  String get syncSuccessDescription =>
      'Vaši podatki se bodo odslej samodejno sinhronizirali.';

  @override
  String get syncWizardTitleConnect => 'Poveži TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Vaša baza podatkov';

  @override
  String get syncSetupTitleJoinGroup => 'Pridruži se skupini';

  @override
  String get syncSetupTitleAccount => 'Vaš račun';

  @override
  String get syncWizardBack => 'Nazaj';

  @override
  String get syncWizardNext => 'Naprej';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Korak $current od $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Ustvari projekt Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Spodaj tapnite »Odpri Supabase«\n2. Ustvarite brezplačen račun (če ga še nimate)\n3. Kliknite »New Project«\n4. Izberite ime in regijo\n5. Počakajte ~2 minuti, da se zažene';

  @override
  String get syncWizardOpenSupabase => 'Odpri Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Omogoči anonimne prijave';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Na nadzorni plošči Supabase:\n   Authentication → Providers\n2. Poiščite »Anonymous Sign-ins«\n3. Vklopite\n4. Kliknite »Save«';

  @override
  String get syncWizardOpenAuthSettings => 'Odpri nastavitve avtentikacije';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopirajte poverilnice';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Na nadzorni plošči pojdite na Settings → API\n2. Kopirajte »Project URL«\n3. Kopirajte ključ »anon public«\n4. Prilepite jih spodaj';

  @override
  String get syncWizardOpenApiSettings => 'Odpri nastavitve API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Pridruži se obstoječi bazi podatkov';

  @override
  String get syncWizardScanQrCode => 'Skeniraj kodo QR';

  @override
  String get syncWizardAskOwnerQr =>
      'Prosite lastnika baze, da vam pokaže svojo kodo QR\n(Nastavitve → TankSync → Deli)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Prosite lastnika baze, da pokaže svojo kodo QR';

  @override
  String get syncWizardEnterManuallyTitle => 'Vnesite ročno';

  @override
  String get syncWizardOrEnterManually => 'ali vnesite ročno';

  @override
  String get syncWizardUrlHelperText =>
      'Presledki in prelomi vrstic se samodejno odstranijo';

  @override
  String get syncCredentialsPrivateHint =>
      'Vnesite poverilnice projekta Supabase. Najdete jih na nadzorni plošči pod Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL baze podatkov';

  @override
  String get syncCredentialsAccessKeyLabel => 'Dostopni ključ';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-pošta';

  @override
  String get authPasswordLabel => 'Geslo';

  @override
  String get authConfirmPasswordLabel => 'Potrdi geslo';

  @override
  String get authPleaseEnterEmail => 'Prosimo, vnesite e-pošto';

  @override
  String get authInvalidEmail => 'Neveljaven e-poštni naslov';

  @override
  String get authPasswordsDoNotMatch => 'Gesli se ne ujemata';

  @override
  String get authConnectAnonymously => 'Poveži anonimno';

  @override
  String get authCreateAccountAndConnect => 'Ustvari račun in poveži';

  @override
  String get authSignInAndConnect => 'Prijavi se in poveži';

  @override
  String get authAnonymousSegment => 'Anonimno';

  @override
  String get authEmailSegment => 'E-pošta';

  @override
  String get authAnonymousDescription =>
      'Takojšnji dostop, brez e-pošte. Podatki vezani na to napravo.';

  @override
  String get authEmailDescription =>
      'Prijavite se z katere koli naprave. Obnovite podatke ob izgubi telefona.';

  @override
  String get authSyncAcrossDevices =>
      'Samodejno sinhronizirajte podatke med vsemi napravami.';

  @override
  String get authNewHereCreateAccount => 'Prvič tukaj? Ustvari račun';

  @override
  String get linkDeviceScreenTitle => 'Poveži napravo';

  @override
  String get linkDeviceThisDeviceLabel => 'Ta naprava';

  @override
  String get linkDeviceShareCodeHint => 'Delite to kodo z drugo napravo:';

  @override
  String get linkDeviceNotConnected => 'Ni povezano';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopiraj kodo';

  @override
  String get linkDeviceImportSectionTitle => 'Uvozi z druge naprave';

  @override
  String get linkDeviceImportDescription =>
      'Vnesite kodo naprave z druge naprave za uvoz priljubljenih, opozoril, vozil in dnevnika porabe. Vsaka naprava obdrži svoj profil in privzete vrednosti.';

  @override
  String get linkDeviceCodeFieldLabel => 'Koda naprave';

  @override
  String get linkDeviceCodeFieldHint => 'Prilepite UUID z druge naprave';

  @override
  String get linkDeviceImportButton => 'Uvozi podatke';

  @override
  String get linkDeviceHowItWorksTitle => 'Kako deluje';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Na napravi A: kopirajte zgornjo kodo naprave\n2. Na napravi B: prilepite jo v polje »Koda naprave«\n3. Tapnite »Uvozi podatke« za združitev priljubljenih, opozoril, vozil in dnevnikov porabe\n4. Obe napravi bosta imeli vse združene podatke\n\nVsaka naprava obdrži svojo anonimno identiteto in profil (prednostno gorivo, privzeto vozilo, začetni zaslon). Podatki se združijo, ne premaknejo.';

  @override
  String get vehicleSetActive => 'Nastavi kot aktivno';

  @override
  String get swipeHide => 'Skrij';

  @override
  String get yourRating => 'Vaša ocena';

  @override
  String get noStorageUsed => 'Ni porabljeno prostora';

  @override
  String get aboutReportBug => 'Prijavi napako / Predlagaj funkcijo';

  @override
  String get aboutSupportProject => 'Podpri ta projekt';

  @override
  String get aboutSupportDescription =>
      'Ta aplikacija je brezplačna, odprtokodna in brez oglasov. Če se vam zdi koristna, razmislite o podpori razvijalcu.';

  @override
  String get reportIssueTitle => 'Prijavi težavo';

  @override
  String get enterCorrection => 'Prosimo, vnesite popravek';

  @override
  String get reportNoBackendAvailable =>
      'Poročila ni bilo mogoče poslati: za to državo ni konfigurirana nobena storitev poročanja. V Nastavitvah omogočite TankSync za pošiljanje skupnostnih poročil.';

  @override
  String get correctName => 'Pravilno ime postaje';

  @override
  String get correctAddress => 'Pravilen naslov';

  @override
  String get wrongE85Price => 'Napačna cena E85';

  @override
  String get wrongE98Price => 'Napačna cena Super 98';

  @override
  String get wrongLpgPrice => 'Napačna cena LPG';

  @override
  String get wrongStationName => 'Napačno ime postaje';

  @override
  String get wrongStationAddress => 'Napačen naslov';

  @override
  String get independentStation => 'Neodvisna postaja';

  @override
  String get serviceRemindersSection => 'Opomniki za servis';

  @override
  String get serviceRemindersEmpty =>
      'Še ni opomnikov — zgoraj izberite prednastavitev.';

  @override
  String get addServiceReminder => 'Dodaj opomnik';

  @override
  String get serviceReminderPresetOil => 'Olje (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Menjava olja';

  @override
  String get serviceReminderPresetTires => 'Pnevmatike (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Pnevmatike';

  @override
  String get serviceReminderPresetInspection => 'Tehnični pregled (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Tehnični pregled';

  @override
  String get serviceReminderLabel => 'Oznaka';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Zadnji servis';

  @override
  String get serviceReminderMarkDone => 'Označi kot opravljeno';

  @override
  String get serviceReminderDueTitle => 'Servis zapadel';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label je zapadel — $kmOver km po intervalu.';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '$label je na vrsti zdaj.';
  }

  @override
  String get vinConfirmTitle => 'Je to vaše vozilo?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-valj, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Delni podatki (brez povezave). Spodaj jih lahko uredite.';

  @override
  String get vinDecodeError => 'Tega VIN ni bilo mogoče dekodirati';

  @override
  String get vinInvalidFormat => 'Neveljaven format VIN';

  @override
  String get obd2PauseBannerTitle =>
      'Izgubljena OBD2 povezava — snemanje v pavzi';

  @override
  String get obd2PauseBannerResume => 'Nadaljuj snemanje';

  @override
  String get obd2PauseBannerEnd => 'Končaj snemanje';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Snemanje z GPS — OBD2 se ponovno povezuje';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Snemanje z GPS — čakanje na adapter OBD2';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Umerjanje porabe posodobljeno za $vehicleName — natančnost izboljšana za $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Ponastaviti volumetrično učinkovitost?';

  @override
  String get veResetConfirmBody =>
      'To bo zavrglo naučeno volumetrično učinkovitost (η_v) in obnovilo privzeto vrednost (0,85). Ocene pretoka goriva na ravni vožnje bodo padle nazaj na konstanto proizvajalca, dokler kalibrater ne zbere novih vzorcev iz prihodnjih voženj.';

  @override
  String get alertsStationSectionTitle => 'Opozorila za postaje';

  @override
  String get alertsStationAdd => 'Dodaj opozorilo za postajo';

  @override
  String get alertsRadiusSectionTitle => 'Polmerna opozorila';

  @override
  String get alertsRadiusAdd => 'Dodaj polmerno opozorilo';

  @override
  String get alertsRadiusEmptyTitle => 'Še ni polmernih opozoril';

  @override
  String get alertsRadiusEmptyCta => 'Ustvari polmerno opozorilo';

  @override
  String get alertsRadiusCreateTitle => 'Ustvari polmerno opozorilo';

  @override
  String get alertsRadiusLabelHint => 'Oznaka (npr. Domači diesel)';

  @override
  String get alertsRadiusFuelType => 'Vrsta goriva';

  @override
  String get alertsRadiusKm => 'Polmer (km)';

  @override
  String get alertsRadiusCenterGps => 'Uporabi mojo lokacijo';

  @override
  String get alertsRadiusCenterPostalCode => 'Poštna številka';

  @override
  String get alertsRadiusSave => 'Shrani';

  @override
  String get alertsRadiusCancel => 'Prekliči';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radiusno opozorilo \"$name\" izbrisano';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 povezan: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Sparaj adapter OBD2';

  @override
  String get fillUpSavedSnackbar => 'Polnjenje shranjeno';

  @override
  String get radiusAlertsEntryTitle => 'Polmerna opozorila in statistike';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Prejemajte obvestila, ko cene padejo v vaši bližini';

  @override
  String get notFoundTitle => 'Stran ni najdena';

  @override
  String notFoundBody(String location) {
    return '\"$location\" ni najdeno.';
  }

  @override
  String get notFoundHomeButton => 'Domov';

  @override
  String get consumptionTabHiddenNotice =>
      'Zavihek Poraba je bil skrit z nastavitvami profila.';

  @override
  String get swipeBetweenTabsHint =>
      'Nasvet: podrsajte levo ali desno za preklop med zavihki.';

  @override
  String get discardChangesTitle => 'Zavreči spremembe?';

  @override
  String get discardChangesBody =>
      'Imate neshranjene spremembe. Izhod zdaj jih bo zavrgel.';

  @override
  String get discardChangesConfirm => 'Zavrzi';

  @override
  String get discardChangesKeepEditing => 'Nadaljuj urejanje';

  @override
  String get tankSyncSectionSubtitle => 'Sinhronizacija v oblaku med napravami';

  @override
  String get mapUnavailable => 'Zemljevid ni na voljo';

  @override
  String get routeNameHintExample => 'npr. Pariz → Lyon';

  @override
  String get priceStatsCurrent => 'Trenutno';

  @override
  String get tankerkoenigApiKeyLabel => 'Ključ API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Ključ API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Tapnite za posodobitev položaja GPS';

  @override
  String get nameLabel => 'Ime';

  @override
  String get obd2ErrorPermissionDenied =>
      'Za povezavo z vmesnikom OBD2 je potrebno dovoljenje za Bluetooth.';

  @override
  String get obd2ErrorBluetoothOff => 'Vklopite Bluetooth in poskusite znova.';

  @override
  String get obd2ErrorScanTimeout =>
      'V bližini ni bil najden vmesnik OBD2. Preverite, ali je priključen in vklopljen.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Vmesnik OBD2 se ni odzval. Vklopite vžig in poskusite znova.';

  @override
  String get obd2ErrorEngineOff =>
      'Ni podatkov iz vozila — zaženite motor in poskusite znova.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Vmesnik OBD2 je poslal neprepoznan odgovor. Morda ni združljiv — poskusite z drugim vmesnikom.';

  @override
  String get obd2ErrorDisconnected =>
      'Vmesnik OBD2 je prekinil povezavo. Znova se povežite in poskusite znova.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adapter zahteva seznanjanje Bluetooth. Izklopite adapter, ga znova priklopite in poskusite znova v 5 minutah.';

  @override
  String get onboardingExploreDemoData => 'Razišči z demo podatki';

  @override
  String get achievementSmoothDriver => 'Mirna serija';

  @override
  String get achievementSmoothDriverDesc =>
      'Zapored opravite 5 voženj z oceno mirne vožnje 80 ali višjo.';

  @override
  String get achievementColdStartAware => 'Zavedanje hladnega zagona';

  @override
  String get achievementColdStartAwareDesc =>
      'Ohranite strošek goriva za hladni zagon pod 2 % celotnega goriva cel mesec — kombinirajte kratke vožnje.';

  @override
  String get achievementHighwayMaster => 'Mojster avtoceste';

  @override
  String get achievementHighwayMasterDesc =>
      'Opravite vožnjo 30 km+ z enakomerno hitrostjo in oceno mirne vožnje 90 ali višjo.';

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
    return '$fuelLabel se je znižal na bližnjih črpalkah';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count črpalk se je v zadnji uri znižalo do $cents¢';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count črpalk ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ še $count';
  }

  @override
  String alertsLastChecked(String when) {
    return 'Nazadnje preverjeno: $when';
  }

  @override
  String get alertsLastCheckedNever => 'Cene še niso bile preverjene v ozadju';

  @override
  String get alertsIosBestEffortNote =>
      'Na iPhonu se opozorila preverjajo po najboljših močeh: iOS odloča, kdaj sme aplikacija preveriti cene v ozadju, zato lahko opozorilo pride pozno ali občasno sploh ne. Odprtje aplikacije vedno sproži novo preverjanje.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Ciljna cena ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Prag ($currency/L)';
  }

  @override
  String get approachOverlaySection => 'Prekrivanje pri približevanju črpalki';

  @override
  String get approachRadiusLabel => 'Polmer';

  @override
  String approachRadiusCaption(String km) {
    return 'Prekrivanje se poveča in prikaže ceno, ko ste znotraj $km km od bencinske črpalke';
  }

  @override
  String get approachPriceModeLabel => 'Pokaži ceno za';

  @override
  String get approachPriceModeNearest => 'Najbližja črpalka';

  @override
  String get approachPriceModeCheapestInRadius => 'Najcenejša v polmeru';

  @override
  String get approachMinPollLabel => 'Min. osvežitev';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Spodnja meja osveževanja najbližje črpalke (hitreje pri višji hitrosti, nikoli pogosteje kot $seconds s)';
  }

  @override
  String get approachTestSimulateButton =>
      'Preizkusi prekrivanje približevanja';

  @override
  String get approachTestStopButton => 'Ustavi preizkus';

  @override
  String approachTestActiveCaption(String station) {
    return 'Preizkus aktiven — prekrivanje prikazuje ceno za $station';
  }

  @override
  String get approachTestUnavailable =>
      'Dodajte priljubljeno postajo, da preizkusite prekrivanje približevanja';

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Bližina $percent%';
  }

  @override
  String get pipTapToRestore => 'Dotaknite se, da odprete celotno aplikacijo';

  @override
  String get authErrorNoNetwork =>
      'Ni omrežne povezave. Poskusite znova pozneje.';

  @override
  String get authErrorInvalidCredentials =>
      'Napačna e-pošta ali geslo. Preverite poverilnice.';

  @override
  String get authErrorUserAlreadyExists =>
      'Ta e-pošta je že registrirana. Poskusite se prijaviti.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Preverite e-pošto in najprej potrdite račun.';

  @override
  String get authErrorGeneric => 'Prijava ni uspela. Prosimo, poskusite znova.';

  @override
  String get authLinkEmailTitle => 'Poveži e-pošto';

  @override
  String get authLinkEmailSubtitle =>
      'Povežite e-pošto, da se bodo vaši podatki sinhronizirali med napravami. Trenutne priljubljene postaje in vožnje ostanejo na tem računu.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Uporabljate račun gosta ($idPrefix…). Povežite e-pošto, da se bodo vaše priljubljene postaje in vožnje sinhronizirale z drugimi napravami.';
  }

  @override
  String get authConfirmationPending =>
      'Skoraj končano — preverite e-pošto in kliknite povezavo, da dokončate povezovanje. Vaši podatki so že shranjeni na tem računu.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Lokacija v ozadju — samo za samodejno snemanje';

  @override
  String get autoRecordConsentExplanationTitle => 'O tem dovoljenju';

  @override
  String get autoRecordConsentExplanationBody =>
      'Samodejno snemanje potrebuje lokacijo v ozadju za zaznavanje, ko začnete voziti, medtem ko je aplikacija zaprta. To dovoljenje se uporablja samo za samodejno snemanje — iskanje postaj in centriranje zemljevida uporabljata ločeno dovoljenje za lokacijo v ospredju.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Razumem';

  @override
  String get autoRecordConsentExplanationTooltip => 'Kaj to pomeni?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Tapnite za upravljanje v sistemskih nastavitvah';

  @override
  String get autoRecordSectionTitle => 'Samodejno snemanje';

  @override
  String get autoRecordToggleLabel => 'Samodejno snemanje voženj';

  @override
  String get autoRecordStatusActiveLabel =>
      'Samodejno snemanje se bo aktiviralo, ko naslednjič vstopite v vozilo.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Sparajte adapter OBD2 za omogočanje samodejnega snemanja.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Dovolite lokacijo v ozadju, da samodejno snemanje deluje z ugasnjenim zaslonom.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Sparaj adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Začetna hitrost (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Zamuda shranjevanja po odklopu (sekunde)';

  @override
  String get autoRecordBackgroundLocationLabel => 'Lokacija v ozadju dovoljena';

  @override
  String get autoRecordBackgroundLocationRequest => 'Zahtevaj dovoljenje';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Zakaj »Vedno dovoli«?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Samodejno snemanje prenaša GPS koordinate iz storitve OBD-II v ospredju, ko je zaslon ugasnjen, da pot ostane točna. Android zahteva možnost »Vedno dovoli«, da to deluje po zaklepu naprave.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Odpri nastavitve';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Potrebno je dovoljenje za lokacijo';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Zahtevanje lokacije v ozadju ni uspelo';

  @override
  String get aclWakeNotificationTitle => 'Avto povezan';

  @override
  String get aclWakeNotificationBody =>
      'Dotaknite se, da odprete Sparkilo — snemanje vožnje se lahko začne.';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Sparajte adapter v spodnjem razdelku za omogočanje samodejnega snemanja';

  @override
  String get exportBackupReady =>
      'Varnostna kopija pripravljena — izberite cilj';

  @override
  String get exportBackupFailed =>
      'Izvoz varnostne kopije ni uspel — poskusite znova';

  @override
  String get backupExportProgress => 'Izvažanje varnostne kopije…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Shranjeno v Prenosih kot $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Obnovi varnostno kopijo';

  @override
  String get restoreBackupDialogBody =>
      'Združitev doda in posodobi zapise iz varnostne kopije ter ohrani vse, kar je že v tej napravi. Zamenjava najprej izbriše vse trenutne podatke, nato obnovi samo varnostno kopijo — tega ni mogoče razveljaviti.';

  @override
  String get restoreBackupMergeAction => 'Združi';

  @override
  String get restoreBackupReplaceAction => 'Zamenjaj vse';

  @override
  String get restoreBackupEmpty =>
      'Varnostna kopija obnovljena — ni vsebovala zapisov';

  @override
  String get restoreBackupCorrupt =>
      'Obnova ni uspela — ta datoteka ni veljavna varnostna kopija Tankstellen';

  @override
  String get restoreBackupFailed =>
      'Obnova ni uspela — datoteke ni bilo mogoče prebrati';

  @override
  String get backupImportProgress => 'Obnavljanje varnostne kopije…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Združeno $vehicles vozil, $fillUps polnjenj, $trips voženj, $chargingLogs dnevnikov polnjenja';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Vsi podatki zamenjani z $vehicles vozili, $fillUps polnjenji, $trips vožnjami, $chargingLogs dnevniki polnjenja';
  }

  @override
  String get brokenMapChipDisclaimer => 'Odčitki MAP so sumljivi';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Senzor MAP bere nepravilno — odčitki goriva so lahko 50–80 % prenizki. Poskusite z drugim adapterjem.';

  @override
  String get brokenMapBannerHardDisable =>
      'Senzor MAP ni zanesljiv. Prikazujejo se povprečja polnjenj namesto živega pretoka goriva.';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Senzor MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Senzor MAP: $posterior% ± $margin% (preverjen)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostika senzorja MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Zaupanje v pokvarjen MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count zabeleženih opazovanj';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Preverjeno čisto';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Senzor MAP tega vozila še ni bil opazovan.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokirani adapterji';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Ni blokiranih adapterjev.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — označen $percent% pokvarjen';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Počisti';

  @override
  String get brokenMapRevPromptTitle => 'Povečajte število vrtljajev';

  @override
  String get brokenMapRevPromptBody =>
      'Na kratko povečajte plin, da aplikacija preveri odziv senzorja MAP.';

  @override
  String get brokenMapRevPromptConfirm => 'Končano — povečal sem vrtljaje';

  @override
  String get calibrationAdvancedTitle => 'Napredno umerjanje';

  @override
  String get calibrationDisplacementLabel => 'Prostornina motorja (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrična učinkovitost (η_v)';

  @override
  String get calibrationAfrLabel => 'Razmerje zrak/gorivo (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Gostota goriva (g/L)';

  @override
  String get calibrationSourceDetected => '(zaznano iz VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(privzeto)';

  @override
  String get calibrationSourceManual => '(ročno)';

  @override
  String get calibrationResetToDetected => 'Ponastavi na zaznano vrednost';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (umerjeno, $samples vzorcev)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (učenje, $samples vzorcev)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (privzeto — še ni plein-complet)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples vzorcev';
  }

  @override
  String get calibrationResetLearner => 'Ponastavi učilnik';

  @override
  String get calibrationBasisAtkinson => 'Atkinsonov cikel';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbo + DI';

  @override
  String get calibrationBasisTurbo => 'Turbopolnilnik';

  @override
  String get calibrationBasisNaDi => 'Atmosferski + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — privzeto $basis)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'To vozilo neposredno sporoča porabo goriva (PID 5E), zato se umerjanje volumetrične učinkovitosti ne uporablja — vaša poraba je izmerjena, ne modelirana.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vaš $makeModel je označen kot diesel, a se ujema z bencin. vnosom v katalogu. Tapnite za posodobitev.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Posodobi';

  @override
  String get catalogResetAction => 'Ponastavi iz baze vozil';

  @override
  String get catalogResetConfirmTitle => 'Ponastaviti iz baze vozil?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'To zamenja prostornino rezervoarja, moč motorja in delovno prostornino tega vozila z vrednostmi iz baze za $vehicle. Druga polja in zgodovina točenj ostanejo nespremenjeni.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'V bazi vozil ni ustreznega vnosa za to vozilo.';

  @override
  String get catalogResetDoneSnackbar =>
      'Podatki o vozilu ponastavljeni iz baze.';

  @override
  String get consumptionTabFuel => 'Gorivo';

  @override
  String get consumptionTabCharging => 'Polnjenje';

  @override
  String get noChargingLogsTitle => 'Še ni dnevnikov polnjenja';

  @override
  String get noChargingLogsSubtitle =>
      'Zabeležite prvo polnjenje za sledenje EUR/100 km in kWh/100 km.';

  @override
  String get addChargingLog => 'Zabeleži polnjenje';

  @override
  String get addChargingLogTitle => 'Zabeleži sejo polnjenja';

  @override
  String get chargingKwh => 'Energija (kWh)';

  @override
  String get chargingCost => 'Skupni strošek';

  @override
  String get chargingTimeMin => 'Čas polnjenja (min)';

  @override
  String get chargingStationName => 'Postaja (neobvezno)';

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
      'Potreben je prejšnji dnevnik za primerjavo';

  @override
  String get chargingLogButtonLabel => 'Zabeleži polnjenje';

  @override
  String get chargingCostTrendTitle => 'Trend stroškov polnjenja';

  @override
  String get chargingEfficiencyTitle => 'Učinkovitost (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Še ni dovolj podatkov';

  @override
  String get confirmDeleteTitle => 'Izbrisati?';

  @override
  String get confirmDeleteBody => 'Ali res želite to izbrisati?';

  @override
  String get consoFeatureGroupTitle => 'Poraba';

  @override
  String get consoFeatureGroupDescription =>
      'Sledite porabi — ročna polnjenja ali samodejno snemanje voženj OBD2.';

  @override
  String get consoModeOff => 'Izklop';

  @override
  String get consoModeFuel => 'Gorivo';

  @override
  String get consoModeFuelAndTrips => 'Gorivo + Vožnje';

  @override
  String get consoModeOffDescription =>
      'Brez zavihka Poraba in brez razdelka nastavitev Poraba.';

  @override
  String get consoModeFuelDescription =>
      'Samo ročna polnjenja. Koristno brez adapterja OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Doda samodejno snemanje voženj OBD2. Zahteva sparani adapter.';

  @override
  String get consoGroupVehicles => 'Vozila';

  @override
  String get consoGroupCoaching => 'Coaching med vožnjo';

  @override
  String get consoGroupRewards => 'Nagrade in prihranki';

  @override
  String get consoGroupTroubleshooting => 'Odpravljanje težav';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Natančnost: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Visoka';

  @override
  String get consumptionAccuracyMedium => 'Srednja';

  @override
  String get consumptionAccuracyLow => 'Nizka';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Popolna kalibracija: točenja goriva ter vožnje, posnete prek OBD2. Vrednost L/100 km sledi resničnosti znotraj nekaj odstotkov.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Točenja so zasidrala model porabe, vendar še ni bila obdelana nobena vožnja OBD2. Posnemite eno s povezanim OBD2, da dosežete visoko natančnost.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Samo GPS — še nobeno točenje ni zasidralo modela porabe. Dodajte nekaj polnih točenj za izboljšanje natančnosti.';

  @override
  String get moreActionsTooltip => 'Več';

  @override
  String get exportBackupMenuLabel => 'Izvozi varnostno kopijo';

  @override
  String get restoreBackupMenuLabel => 'Obnovi varnostno kopijo';

  @override
  String get carbonDashboardMenuLabel => 'Ogljična nadzorna plošča';

  @override
  String get settingsMenuLabel => 'Nastavitve';

  @override
  String get consumptionStatsPageTitle => 'Statistika porabe';

  @override
  String get consumptionStatsComparisonTitle =>
      'Ta mesec v primerjavi s prejšnjim';

  @override
  String get consumptionStatsTrendsTitle => 'Razvoj skozi čas';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Beležite polnjenja vsaj dva meseca za primerjavo.';

  @override
  String get consumptionStatsPricePerLiter => 'Povp. cena/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litri na mesec';

  @override
  String get consumptionStatsChartSpend => 'Poraba na mesec';

  @override
  String get consumptionStatsChartPricePerLiter => 'Cena na liter';

  @override
  String get consumptionStatsChartConsumption => 'L/100 km na mesec';

  @override
  String get fuelCompareSectionTitle => 'Stroški vožnje po gorivih';

  @override
  String get fuelComparePricePerLitre => 'Plačano za liter';

  @override
  String get fuelCompareCostPer100km => 'Strošek na 100 km';

  @override
  String get fuelCompareDistance => 'Izmerjena razdalja';

  @override
  String get fuelCompareLitres => 'Porabljeni litri';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner je vaše najcenejše gorivo za vožnjo';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser stane $amount več na 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel prekaša $rival pod $price za liter';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Prag donosnosti se izračuna iz izmerjene porabe vsakega goriva, zato se premika skupaj z vašo vožnjo.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litri in stroški si lahko nasprotujejo: gorivo lahko porabi manj litrov na 100 km in vseeno stane več na kilometer, ker se cena za liter razlikuje. Odloča strošek na kilometer.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count polnih rezervoarjev',
      one: 'enega polnega rezervoarja',
    );
    return 'Začasno — na podlagi $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count polnih rezervoarjev',
      one: 'enega polnega rezervoarja',
    );
    return 'Na podlagi $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 na 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner je vaše gorivo z najnižjimi izpusti';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel stane $money več na 1000 km, a izpusti $co2 manj CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel je hkrati cenejše in čistejše od $rival';
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
    return 'Vaših $distance z $fuel je izpustilo $actual namesto $alternative z $rival — $saved prihranjenih';
  }

  @override
  String get fuelCompareCo2Source =>
      'Vrednosti CO2 so ocene od vira do kolesa (EU JEC WTW v5), uporabljene na vaši izmerjeni porabi — za orientacijo, ne za certificirano računovodstvo.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 je prikazan le za čista goriva: emisijski faktor mešanice je odvisen od sestave, ki je ta vrstica ne beleži.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count delnih polnjenj čaka na plein complet — ni vključeno v povprečje',
      one: '1 delno polnjenje čaka na plein complet — ni vključeno v povprečje',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% goriva iz samodejnih popravkov — preverite vnose';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Popravki: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Prijavi vsebino';

  @override
  String get contentModerationBlockAction => 'Blokiraj avtorja';

  @override
  String get contentModerationReportDialogTitle => 'Prijaviti to vsebino?';

  @override
  String get contentModerationReportDialogBody =>
      'Prijava se pošlje vašemu strežniku TankSync v pregled, ta vsebina pa se na vaši napravi skrije.';

  @override
  String get contentModerationReportConfirmButton => 'Prijavi';

  @override
  String get contentModerationBlockDialogTitle => 'Blokirati tega avtorja?';

  @override
  String get contentModerationBlockDialogBody =>
      'Vse, kar ta račun deli z vami, bo na tej napravi skrito.';

  @override
  String get contentModerationBlockConfirmButton => 'Blokiraj';

  @override
  String get contentModerationReportedSnack =>
      'Prijava poslana — vsebina skrita.';

  @override
  String get contentModerationReportFailedSnack =>
      'Prijave ni bilo mogoče poslati. Poskusite znova.';

  @override
  String get contentModerationBlockedSnack =>
      'Avtor blokiran — njegova deljena vsebina je skrita.';

  @override
  String get fillUpCorrectionLabel =>
      'Samodejni popravek — tapnite za urejanje';

  @override
  String get fillUpCorrectionEditTitle => 'Uredi samodejni popravek';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Ta vnos je bil samodejno ustvarjen za zaprtje vrzeli med posnetimi vožnjami in natočenim gorivom. Prilagodite vrednosti, če poznate dejanske podatke.';

  @override
  String get fillUpCorrectionDelete => 'Izbriši popravek';

  @override
  String get fillUpCorrectionStation => 'Ime postaje (neobvezno)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Postaje v $country $km km stran — €$price/L cenejše';
  }

  @override
  String get crossBorderTapToSwitch => 'Tapnite za preklop države';

  @override
  String get crossBorderDismissTooltip => 'Zapri';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Odpri vir podatkov $source ($license) v brskalniku';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Razvijalska orodja';

  @override
  String get dataAccessTracerExport => 'Izvozi dnevnik dostopa do podatkov';

  @override
  String get dataAccessTracerExportSuccess =>
      'Dnevnik dostopa do podatkov shranjen v Prenose.';

  @override
  String get dataAccessTracerExportFailure =>
      'Dnevnika dostopa do podatkov ni bilo mogoče izvoziti.';

  @override
  String get dataAccessTracerEmpty =>
      'Zabeleženih še ni nobenih dogodkov dostopa do podatkov — najprej poiščite ali odprite postaje, nato izvozite.';

  @override
  String get developerToolsSubtitle =>
      'Diagnostika in orodja za odpravljanje napak — vidna samo v razvijalskem načinu / načinu za odpravljanje napak.';

  @override
  String get developerToolsMenuSubtitle =>
      'Dnevnik napak, testna opozorila, diagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Dnevnik napak';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Shrani dnevnik napak ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Počisti dnevnik napak';

  @override
  String get developerToolsViewErrorLog => 'Prikaži dnevnik napak';

  @override
  String get developerToolsErrorLogEmpty => 'Ni zabeleženih sledi napak.';

  @override
  String get developerToolsAlertsGroupTitle => 'Opozorila in obvestila';

  @override
  String get developerToolsFireTestNotification => 'Pošlji testno obvestilo';

  @override
  String get developerToolsTestNotificationTitle => 'Testno obvestilo';

  @override
  String get developerToolsTestNotificationBody =>
      'Če lahko to preberete, obvestila delujejo.';

  @override
  String get developerToolsTestNotificationSent => 'Testno obvestilo poslano.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Obvestila so blokirana — omogočite jih v sistemskih nastavitvah in poskusite znova.';

  @override
  String get developerToolsRunTestAlert => 'Zaženi testni cevovod opozoril';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testno opozorilo sproženo — cevovod je dostavil $count obvestil.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testno cenovno opozorilo';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Sintetično ujemanje: v bližini je bila najdena postaja pod vašim ciljem.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Najprej poiščite postaje, nato zaženite testno obvestilo, da bo obvestilo lahko odprlo pravo postajo.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostika';

  @override
  String get developerToolsFeatureFlagDump => 'Pregledovalnik zastavic funkcij';

  @override
  String get developerToolsFlagOn => 'Vklopljeno';

  @override
  String get developerToolsFlagOff => 'Izklopljeno';

  @override
  String get developerToolsClearCaches => 'Počisti predpomnilnike';

  @override
  String get developerToolsCachesCleared => 'Predpomnilniki počiščeni.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopiraj diagnostiko';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostika kopirana v odložišče.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Podatki o gradnji';

  @override
  String get developerToolsBuildVersion => 'Različica aplikacije';

  @override
  String get developerToolsBuildChannel => 'Kanal gradnje';

  @override
  String get startupTraceSectionTitle => 'Dnevnik inicializacije ob zagonu';

  @override
  String get startupTraceExportButton => 'Izvozi dnevnik zagona';

  @override
  String get startupTraceEmpty =>
      'Zabeleženega še ni nobenega dnevnika zagona.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Skupaj: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess => 'Dnevnik zagona shranjen v Prenose.';

  @override
  String get startupTraceExportFailure =>
      'Dnevnika zagona ni bilo mogoče izvoziti.';

  @override
  String get distanceSourceOdometer => 'Števec kilometrov';

  @override
  String get distanceSourceOdometerTooltip =>
      'Razdalja, odčitana s števca kilometrov avtomobila — izmerjena referenčna vrednost.';

  @override
  String get distanceSourceGps => 'Sled GPS';

  @override
  String get distanceSourceGpsTooltip =>
      'Razdalja, seštevek iz posnete sledi GPS — dejanska razdalja po cesti.';

  @override
  String get distanceSourceEstimated => 'Ocenjeno';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Razdalja, integrirana iz senzorja hitrosti — ocena; senzor običajno kaže nekoliko preveč.';

  @override
  String get insightCardTitle => 'Najbolj potratna vedenja';

  @override
  String get insightEmptyState => 'Ni opaznih neučinkovitosti — tako naprej!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor nad 3000 RPM ($pctTime% vožnje): porabljeno $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count nenadnih pospeševanj: porabljeno $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Prosti tek ($pctTime% vožnje): porabljeno $liters L';
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
    return 'Napenjanje v nizki prestavi ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Ob daljših postankih ugasnite motor, namesto da ga pustite v prostem teku.';

  @override
  String get lessonAdviceHighRpm =>
      'Prej prestavite navzgor, da motor ostane zunaj območja visokih vrtljajev.';

  @override
  String get lessonAdviceHardAccel =>
      'Plin pritiskajte nežno — enakomerno pospeševanje porabi manj goriva.';

  @override
  String get lessonAdviceLowGear =>
      'Prej prestavite navzgor, da se motor umiri pri nižjih in varčnejših vrtljajih.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Trajno visoka hitrost ($pctTime% vožnje): zapravljeno $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Trajno visoka hitrost ($pctTime% vožnje)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Nad 110 km/h spustite plin – zračni upor strmo narašča, malo počasneje prihrani veliko goriva.';

  @override
  String get lessonSmoothDrivingTitle => 'Umirjena vožnja – odlično!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Na tej vožnji ni bilo sunkovitega pospeševanja ali zaviranja – enakomerna vožnja ohranja nizko porabo.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Polni plin ($pctTime% vožnje): zapravljenih $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Nežno na pedal — z zmernim 70 % pospeška do hitrosti porabite bistveno manj goriva.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Bogata mešanica pri obremenitvi ($pctTime% vožnje): zapravljenih $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Velika, trajna obremenitev povzroči bogato mešanico — pri dolgih vzponih prestavljajte zgodaj in rahljajte plin, da ohranite pusto mešanico.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Vzpon pri $gradePercent% naklonu ($pctTime% vožnje): zapravljenih $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Ohranite zagon pred vzponom in enakomerno dodajajte plin — hitri sunki na vzponu povečajo porabo goriva.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count ponovnih zagonov po ustavitvi: zapravljenih $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Predvidite promet in se drsno približajte postanku, da se kotalite namesto da se ustavite — odhod z mesta mirovanja je najtežji del vožnje z ustavljanjem.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Zmes se zdi nekoliko revna — motor je dodajal gorivo (korekcija $pctTrim %), da bi to nadomestil';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Zmes se zdi revna — motor je trajno dodajal veliko goriva ($pctTrim %), možna neučinkovitost';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Zmes se zdi nekoliko bogata — motor je odvzemal gorivo (korekcija $pctTrim %), da bi to nadomestil';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Zmes se zdi bogata — motor je trajno odvzemal veliko goriva ($pctTrim %), možna neučinkovitost';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Motor je pod obremenitvijo tekel bogato ($pctShare % ogrete vožnje) — možna potrata goriva';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Hevristični signal stanja, ne diagnoza';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Trajna korekcija proti revni zmesi lahko pomeni uhajanje zraka v sesalnem delu, šibko oskrbo z gorivom ali starajoč se senzor. Če se poraba ali tek poslabšata, lahko diagnostika v delavnici to potrdi.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Trajna korekcija proti bogati zmesi lahko pomeni puščajočo šobo, previsok tlak goriva ali senzor, ki kaže preveč. Če se poraba ali tek poslabšata, lahko diagnostika v delavnici to potrdi.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Bogata zmes pri veliki obremenitvi porabi dodatno gorivo. Prestavljajte navzgor prej in pri dolgih pospeševanjih popustite plin, da motor ostane blizu stehiometrične zmesi.';

  @override
  String get lessonTransportTitle =>
      'Podatki motorja manjkajo za večino te vožnje';

  @override
  String get lessonTransportAdvice =>
      'Motor skoraj celotno razdaljo ni sporočal nobene dejavnosti. Ali je tok OBD2 med vožnjo odpovedal ali pa je bil avto premaknjen brez vožnje — vrednost porabe je nezanesljiva in izključena iz vaše statistike.';

  @override
  String get drivingScoreCardTitle => 'Ocena vožnje';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Sestavljena ocena iz prostega teka, nenadnih pospeševanj, nenadnega zaviranja in časa pri visoki vrtljajnosti. Primerjava »boljše od X% preteklih voženj« bo dodana v prihodnji različici.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Ocena vožnje $score od 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Prosti tek';

  @override
  String get drivingScorePenaltyHardAccel => 'Nenada pospeševanja';

  @override
  String get drivingScorePenaltyHardBrake => 'Nenado zaviranje';

  @override
  String get drivingScorePenaltyHighRpm => 'Visoka vrtljajnost';

  @override
  String get drivingScorePenaltyFullThrottle => 'Polni plin';

  @override
  String get drivingScoreClassVeryGood => 'Zelo dobro';

  @override
  String get drivingScoreClassGood => 'Dobro';

  @override
  String get drivingScoreClassAverage => 'Povprečno';

  @override
  String get drivingScoreClassBad => 'Potrebuje izboljšave';

  @override
  String get drivingScorePenaltyLugging => 'Vlečenje motorja';

  @override
  String get drivingScorePenaltySmoothness => 'Sunkovita vožnja';

  @override
  String get drivingScorePenaltyHighSpeed => 'Visoka hitrost';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresiven pedal';

  @override
  String get drivingScorePenaltyLambda => 'Bogata mešanica';

  @override
  String get gpsKpiCardTitle => 'Učinkovitost GPS';

  @override
  String get gpsKpiRpa => 'Pozitivno pospeševanje (RPA)';

  @override
  String get gpsKpiPke => 'Zahtevana kinetična energija (PKE)';

  @override
  String get gpsKpiVapos => 'Intenzivnost pospeševanja (VAPOS)';

  @override
  String get gpsKpiCoast => 'Delež prostega teka';

  @override
  String get gpsKpiClimbEnergy => 'Energija vzpona';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct v primerjavi z vašo učinkovito referenčno vrednostjo';
  }

  @override
  String get drivingTraceCardTitle => 'Sled analize vožnje (razv.)';

  @override
  String get drivingTraceCardBody =>
      'Izvozite GPS KPI, rezultat in lekcije te vožnje kot JSON, v polje za komentar napišite, kako je bila vožnja v resnici, in delite nazaj, da se pragovi stila vožnje umerijo na resnične vožnje.';

  @override
  String get drivingTraceExportAction => 'Izvozi sled analize';

  @override
  String get drivingTraceExported =>
      'Sled analize shranjena v Prenose — dodajte svojo oceno v polje za komentar in delite nazaj.';

  @override
  String get drivingTraceExportFailed =>
      'Sledi analize ni bilo mogoče izvoziti.';

  @override
  String get minimalDriveTripAverage => 'Povprečje vožnje';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Vožnja pri visokih vrtljajih ($pctTime % vožnje): zgodnejše prestavljanje navzgor bi lahko prihranilo $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Pri enakomerni vožnji prestavljajte navzgor prej — enaka hitrost pri nižjih vrtljajih porabi opazno manj.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Kotaljenje s prekinitvijo dovoda goriva ($pctTime % vožnje): prihranjenih približno $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Dobro predvideno — zgodnje popuščanje plina omogoči motorju, da med kotaljenjem povsem prekine dovod goriva.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Kam je šlo vaše gorivo';

  @override
  String get fuelBreakdownIdle => 'Prosti tek';

  @override
  String get fuelBreakdownHarshAccel => 'Sunkovita pospeševanja';

  @override
  String get fuelBreakdownHighRpmCruise => 'Vožnja pri visokih vrtljajih';

  @override
  String get fuelBreakdownCoastingSaved => 'Prihranjeno s kotaljenjem';

  @override
  String get fuelBreakdownEfficient => 'Običajna vožnja';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Prosti tek že nekaj časa — ugasnitev motorja prihrani gorivo';

  @override
  String get ecoNudgeHarshAccel =>
      'Močno pospeševanje — nežnejša noga na plinu prihrani gorivo';

  @override
  String get ecoNudgeHighRpm =>
      'Visoki vrtljaji pri enakomerni vožnji — zgodnejše prestavljanje navzgor prihrani gorivo';

  @override
  String get obd2CoverageNoneNote =>
      'Med to vožnjo iz adapterja OBD2 ni prispel noben podatek motorja — vrednosti goriva so ocene na podlagi GPS.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Podatki motorja so se ustavili pri $percent % vožnje (povezava prekinjena) — vrednosti goriva po tem so ocene na podlagi GPS.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Podatki motorja so pokrili le $percent % te vožnje — vrzeli uporabljajo ocene na podlagi GPS.';
  }

  @override
  String get favoritesShareAction => 'Deli';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — priljubljene dne $date';
  }

  @override
  String get favoritesShareError =>
      'Ni bilo mogoče ustvariti slike za deljenje';

  @override
  String get featureManagementSectionTitle => 'Upravljanje funkcij';

  @override
  String get featureManagementSectionSubtitle =>
      'Vklopite ali izklopite posamezne funkcije. Nekatere funkcije so odvisne od drugih — stikala so onemogočena, dokler niso izpolnjene predpogoji.';

  @override
  String get featureLabel_obd2TripRecording => 'Snemanje voženj OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Samodejno zajemanje voženj prek OBD2.';

  @override
  String get featureLabel_gamification => 'Gamifikacija';

  @override
  String get featureDescription_gamification =>
      'Ocene vožnje in pridobljene značke.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptični eko-trener';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Haptična povratna informacija v realnem času med vožnjo.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sinhronizacija med napravami prek Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analitika porabe';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Zavihek za analizo polnjenj in voženj.';

  @override
  String get featureLabel_baselineSync => 'Sinhronizacija izhodišč';

  @override
  String get featureDescription_baselineSync =>
      'Sinhroniziraj izhodišča vožnje prek TankSync.';

  @override
  String get featureLabel_priceAlerts => 'Cenovna opozorila';

  @override
  String get featureDescription_priceAlerts =>
      'Obvestila o padcu cen na podlagi praga.';

  @override
  String get featureLabel_priceHistory => 'Zgodovina cen';

  @override
  String get featureDescription_priceHistory =>
      '30-dnevni grafi cen v podrobnostih postaje.';

  @override
  String get featureLabel_routePlanning => 'Načrtovanje poti';

  @override
  String get featureDescription_routePlanning =>
      'Najcenejša postaja vzdolž vaše poti.';

  @override
  String get featureLabel_evCharging => 'Polnjenje EV';

  @override
  String get featureDescription_evCharging =>
      'Postaje za polnjenje prek OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Nasveti za hipermiling z uporabo prometnih signalov OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Pot vožnje GPS';

  @override
  String get featureDescription_gpsTripPath =>
      'Shrani vzorce poti GPS ob vsaki vožnji.';

  @override
  String get featureLabel_autoRecord => 'Samodejno snemanje';

  @override
  String get featureDescription_autoRecord =>
      'Samodejno začni vožnjo, ko se adapter OBD2 poveže z vozilom v gibanju.';

  @override
  String get featureLabel_showFuel => 'Prikaži bencinske postaje';

  @override
  String get featureDescription_showFuel =>
      'Prikaži rezultate bencin./diesel postaj v iskanju in na zemljevidu.';

  @override
  String get featureLabel_showElectric => 'Prikaži postaje za polnjenje';

  @override
  String get featureDescription_showElectric =>
      'Prikaži EV postaje za polnjenje v iskanju in na zemljevidu.';

  @override
  String get featureLabel_showConsumptionTab => 'Zavihek Poraba';

  @override
  String get featureDescription_showConsumptionTab =>
      'Prikaži zavihek za analitiko porabe v spodnji navigaciji.';

  @override
  String get featureBlockedEnable_gamification =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Najprej omogočite TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Napoved cen TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Model napovedi cen na napravi — sklepanje poteka lokalno; funkcije in napovedi nikoli ne zapustijo naprave.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Najprej omogočite zgodovino cen';

  @override
  String get featureLabel_fuelCalculator => 'Kalkulator goriva';

  @override
  String get featureDescription_fuelCalculator =>
      'Kalkulator dosegljivih stroškov goriva iz rezultatov iskanja.';

  @override
  String get featureLabel_carbonDashboard => 'Ogljična nadzorna plošča';

  @override
  String get featureDescription_carbonDashboard =>
      'Nadzorna plošča ogljičnega odtisa iz zavihka Poraba.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentalni OEM PID-ji';

  @override
  String get featureDescription_experimentalOemPids =>
      'Preberite natančno količino goriva v rezervoarju prek PID-jev proizvajalca na podprtih adapterjih.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Najprej omogočite snemanje voženj OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Skeniraj QR za plačilo';

  @override
  String get featureDescription_paymentQrScan =>
      'QR bralnik za plačilo na zaslonu s podrobnostmi postaje.';

  @override
  String get featureLabel_communityPriceReports =>
      'Skupnostna poročila o cenah';

  @override
  String get featureDescription_communityPriceReports =>
      'Prijavite ceno postaje z zaslona s podrobnostmi postaje.';

  @override
  String get featureLabel_obd2Optional => 'Zahtevaj OBD2 za snemanje voženj';

  @override
  String get featureDescription_obd2Optional =>
      'Ko je izklopljeno, aplikacija snema vožnje samo z GPS brez OBD2 adapterja. Coaching je omejen — brez trenutne L/100 km, manj signalov motorja.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR računa';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skenirajte natisnjen račun na zaslonu Dodaj polnjenje, da vnaprej izpolnite datum, litre, skupno in postajo.';

  @override
  String get featureLabel_developerPatToken =>
      'Razvijalska povratna informacija (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Omogoča ploščo povratnih informacij za neuspešna skeniranja, ki s Personal Access Tokenom samodejno ustvarja težave v GitHubu. Funkcija za napredne uporabnike / sodelavce.';

  @override
  String get featureLabel_debugMode =>
      'Razvijalski način / način za odpravljanje napak';

  @override
  String get featureDescription_debugMode =>
      'V nastavitvah prikaže razdelek Razvijalska orodja z diagnostiko: izvoz dnevnika napak, testna obvestila, zagon testnega cevovoda opozoril, izpis zastavic funkcij, čiščenje predpomnilnikov in kopiranje diagnostike.';

  @override
  String get featureLabel_approachOverlay => 'Radar bencinski servis';

  @override
  String get featureDescription_approachOverlay =>
      'Spremenite lebdeči ploščici potovanja v živi radar bencinskih servisov — ko se približate bencinski postaji, se preklopi na barvo vrste goriva in prikaže ceno.';

  @override
  String get featureLabel_voiceAnnouncements => 'Glasovne napovedi';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Glasno napoveduje bližnje cenejše bencinske postaje med vožnjo, da ohranite oči na cesti.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Najprej vklopite Radar bencinski servis';

  @override
  String get featureGroupTitle_finding => 'Iskanje in karta';

  @override
  String get featureGroupDescription_finding =>
      'Kje se natočiti ali napolniti — iskanje, karta, usmerjanje.';

  @override
  String get featureGroupTitle_prices => 'Cene in opozorila';

  @override
  String get featureGroupDescription_prices =>
      'Padci cen, zgodovina in poročanje.';

  @override
  String get featureGroupTitle_radar => 'Radar bencinski servis';

  @override
  String get featureGroupDescription_radar => 'Obveščanje o cenah med vožnjo.';

  @override
  String get featureGroupTitle_sync => 'Sinhronizacija in varnostno kopiranje';

  @override
  String get featureGroupDescription_sync =>
      'Ohranite podatke na vseh napravah.';

  @override
  String get featureGroupTitle_input => 'Vnos in skeniranje';

  @override
  String get featureGroupDescription_input =>
      'Pomočniki za beleženje polnjenj.';

  @override
  String get featureGroupTitle_developer => 'Razvijalec in eksperimentalno';

  @override
  String get featureGroupDescription_developer =>
      'Orodja za napredne uporabnike in sodelavce.';

  @override
  String get featureLabel_voiceFeedback =>
      'Govorne povratne informacije (sinteza govora)';

  @override
  String get featureDescription_voiceFeedback =>
      'Glavno stikalo za vse govorjeno — glasovnega trenerja vožnje in napovedi postaj. Ko je izklopljeno, aplikacija nikoli ne odpre sinteze govora.';

  @override
  String get feedbackConsentTitle => 'Poslati poročilo na GitHub?';

  @override
  String get feedbackConsentBody =>
      'S tem bo ustvarjena javna prijava v našem repozitoriju GitHub s fotografijo in besedilom OCR. Nobeni osebni podatki (lokacija, ID računa) niso poslani. Nadaljujete?';

  @override
  String get feedbackConsentContinue => 'Nadaljuj';

  @override
  String get feedbackConsentCancel => 'Prekliči';

  @override
  String get feedbackConsentLater => 'Pozneje';

  @override
  String get feedbackTokenSectionTitle =>
      'Povratne informacije o napaki skeniranja (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Za samodejno odpiranje prijave GitHub pri neuspelem skeniranju prilepite GitHub PAT (obseg `public_repo` v repozitoriju tankstellen). Sicer je na voljo ročno deljenje.';

  @override
  String get feedbackTokenStatusSet => 'Žeton konfiguriran';

  @override
  String get feedbackTokenStatusUnset => 'Ni žetona';

  @override
  String get feedbackTokenSet => 'Nastavi';

  @override
  String get feedbackTokenClear => 'Počisti';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Osebni dostopni žeton';

  @override
  String get fillUpMultiFuelHint =>
      'To vozilo lahko uporablja različna goriva — zabeležite tisto, ki ste ga dejansko natočili';

  @override
  String get fillUpGuidanceTitle => 'Najboljši čas za polnjenje';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Trenutna cena je med najcenejšimi zadnjih $days dni — dober čas za polnjenje.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Cene so blizu $days-dnevnega vrha. Navadno so cenejše $window — razmislite o čakanju.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Cene naraščajo — razmislite o zgodnjem polnjenju.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Današnja cena je blizu $days-dnevnega povprečja.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Z ustreznim časom polnjenja bi prihranili okoli $amount/L.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na podlagi $count odčitkov cen',
      one: 'Na podlagi 1 odčitka cene',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'ob $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'v drugih časih';

  @override
  String get fillUpGuidanceWeekday1 => 'v ponedeljek';

  @override
  String get fillUpGuidanceWeekday2 => 'v torek';

  @override
  String get fillUpGuidanceWeekday3 => 'v sredo';

  @override
  String get fillUpGuidanceWeekday4 => 'v četrtek';

  @override
  String get fillUpGuidanceWeekday5 => 'v petek';

  @override
  String get fillUpGuidanceWeekday6 => 'v soboto';

  @override
  String get fillUpGuidanceWeekday7 => 'v nedeljo';

  @override
  String get fillUpGuidancePartEarlyMorning => 'zgodaj zjutraj';

  @override
  String get fillUpGuidancePartMorning => 'dopoldne';

  @override
  String get fillUpGuidancePartAfternoon => 'popoldan';

  @override
  String get fillUpGuidancePartEvening => 'zvečer';

  @override
  String get fillUpGuidancePartNight => 'ponoči';

  @override
  String get fillUpOdometerFromCarJustNow => 'Iz vašega vozila · pravkar';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Iz vašega vozila · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Ocenjeno iz zadnjega odčitka vozila in razdalje, prevožene od takrat ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Prilepi besedilo';

  @override
  String get pasteReceiptDialogTitle => 'Prilepi besedilo računa';

  @override
  String get pasteReceiptDialogHint =>
      'Prilepite besedilo računa za gorivo — e-pošta, SMS ali deljen PDF. Litri, cena na liter, vrsta goriva, skupni znesek in postaja se preberejo v napravi in vnaprej izpolnijo obrazec. Nič se ne pošlje na strežnik.';

  @override
  String get pasteReceiptFieldHint => 'Besedilo računa';

  @override
  String get pasteReceiptParseAction => 'Vnaprej izpolni';

  @override
  String get pasteReceiptNoData =>
      'Iz tega besedila ni bilo mogoče prebrati podatkov o gorivu — preverite, ali gre za račun za gorivo, in poskusite znova.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel =>
      'Preverjeno z adapterjem';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Se ne ujema z odčitkom adapterja';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Vaš vnos: $userL L. Adapter pravi: $adapterL L (razlika iz zajema ravni goriva pred/po). Uporabiti vrednost adapterja?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Ohrani moj vnos';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Uporabi vrednost adapterja';

  @override
  String get scanReceiptNoData =>
      'Ni najdenih podatkov o računu — poskusite znova';

  @override
  String get scanReceiptSuccess =>
      'Račun skeniran — preverite vrednosti. Tapnite »Prijavi napako skeniranja« spodaj, če kaj ni v redu.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skeniranje ni uspelo: $error';
  }

  @override
  String get badScanReportTitleReceipt => 'Prijavi napako skeniranja — račun';

  @override
  String get badScanReportHint =>
      'Delili bomo fotografijo računa in oba niza vrednosti, da se naslednja gradnja nauči te postavitve.';

  @override
  String get badScanReportFieldBrandLayout => 'Postavitev blagovne znamke';

  @override
  String get badScanReportFieldTotal => 'Skupaj';

  @override
  String get badScanReportFieldPricePerLiter => 'Cena/L';

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
  String get badScanReportHeaderYouTyped => 'Vpisali ste';

  @override
  String get badScanReportCreateTicket => 'Ustvari prijavo';

  @override
  String get badScanReportOpenInBrowser => 'Odpri v brskalniku';

  @override
  String get badScanReportFallbackToShare =>
      'Oddaja ni uspela — ročno deljenje';

  @override
  String get fillUpWarningDialogTitle => 'Preverite to točenje';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Izbrali ste $chosenFuel, a to vozilo vozi na $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Stanje števca $entered km je nižje od $previous km prejšnjega točenja — razdalja ne more iti nazaj.';
  }

  @override
  String get fillUpWarningGoBack => 'Nazaj in popravi';

  @override
  String get fillUpWarningSaveAnyway => 'Vseeno shrani';

  @override
  String get fillUpSectionWhatTitle => 'Kaj ste natočili';

  @override
  String get fillUpSectionWhatSubtitle => 'Gorivo, količina, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kje ste bili';

  @override
  String get fillUpSectionWhereSubtitle => 'Postaja, števec km, opombe';

  @override
  String get fillUpImportReceiptLabel => 'Račun';

  @override
  String get fillUpPricePerLiterLabel => 'Cena na liter';

  @override
  String get vehicleHeaderUntitled => 'Novo vozilo';

  @override
  String get vehicleSectionIdentityTitle => 'Identiteta';

  @override
  String get vehicleSectionIdentitySubtitle => 'Ime in VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Pogon';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Kako se to vozilo premika';

  @override
  String get profileSectionDisplayStations => 'Prikaz in postaje';

  @override
  String get profileSectionRegion => 'Regija';

  @override
  String get fuelEfficiencyCardTitle => 'Strošek na kilometer po gorivu';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Katera mešanica goriva je za vožnjo dejansko najcenejša';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Najcenejše na km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Čisto';

  @override
  String get fuelEfficiencyMixBadge => 'Mešanica';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Večinoma $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Strošek/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Skupaj porabljeno';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count točenj',
      few: '$count točenja',
      two: '$count točenji',
      one: '1 točenje',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count polnih rezervoarjev',
      few: '$count polni rezervoarji',
      two: '$count polna rezervoarja',
      one: '1 poln rezervoar',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Zabeležite vsaj dva polna rezervoarja na sestavo, da določite najcenejšo.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Rezervoarji so združeni po sestavi: rezervoar je čist, ko eno gorivo predstavlja vsaj 85 %, sicer je mešanica.';

  @override
  String get fuelNameE5 => 'Bencin 95';

  @override
  String get fuelNameE10 => 'Bencin 95 E10';

  @override
  String get fuelNameE98 => 'Bencin 98';

  @override
  String get fuelNameDiesel => 'Dizel';

  @override
  String get fuelNameDieselPremium => 'Dizel Premium';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'Avtoplin (LPG)';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Vodik';

  @override
  String get fuelNameElectric => 'Električno';

  @override
  String get calibrationModeLabel => 'Način umerjanja';

  @override
  String get calibrationModeRule => 'Na podlagi pravil';

  @override
  String get calibrationModeFuzzy => 'Mehka logika';

  @override
  String get calibrationModeTooltip =>
      'Umerjanje na podlagi pravil dodeluje vsak vzorec vožnje natančno eni situaciji. Mehka logika ga razporedi čez vse glede na ujemanje — bolj gladko pri 60 km/h ali pri spremembi naklona, a počasneje napolni vse razrede.';

  @override
  String get profileGamificationToggleTitle => 'Prikaži dosežke in ocene';

  @override
  String get profileGamificationToggleSubtitle =>
      'Ko je izklopljeno, so značke, ocene in ikone trofej skrite po celotni aplikaciji.';

  @override
  String gdprPolicyLink(int version) {
    return 'Pravilnik o zasebnosti (različica $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Privolitev dana $date · različica pravilnika $version';
  }

  @override
  String get consentNotRecorded => 'Privolitev še ni zabeležena';

  @override
  String serverErasurePartial(String tables) {
    return 'Nekaterih podatkov na strežniku ni bilo mogoče izbrisati: $tables. Poskusite znova ali se s tem seznamom obrnite na razvijalca.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Nekaterih lokalnih podatkov ni bilo mogoče izbrisati: $steps. Znova zaženite aplikacijo in poskusite znova.';
  }

  @override
  String get myCommunityReportsTitle => 'Moje prijave skupnosti';

  @override
  String get myCommunityReportsEmpty => 'Niste oddali nobene prijave';

  @override
  String get deleteReportTooltip => 'Izbriši to prijavo';

  @override
  String get reportDeleted => 'Prijava izbrisana';

  @override
  String get reportDeleteFailed => 'Prijave ni bilo mogoče izbrisati';

  @override
  String get privacyControlsTitle => 'Nastavitve zasebnosti';

  @override
  String get tileProxyToggleTitle =>
      'Nalagaj ploščice zemljevida prek posredniškega strežnika Sparkilo';

  @override
  String get tileProxyToggleSubtitle =>
      'Vklopljeno: prikazani izsek zemljevida in vaš naslov IP prispeta na razvijalčev strežnik v EU, ki ploščice pridobi iz OpenStreetMap. Izklopljeno: ploščice se nalagajo neposredno s tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle =>
      'Nalagaj logotipe blagovnih znamk iz interneta';

  @override
  String get remoteLogosToggleSubtitle =>
      'Privzeto izklopljeno: prikazani so vgrajeni nadomestni logotipi. Vklopljeno: logotipi se pridobijo s logo.clearbit.com, ki vidi vaš naslov IP.';

  @override
  String get privacyExportAllButton => 'Izvozi vse moje podatke (ZIP)';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName shranjeno v Prenose — vsebuje $count datotek';
  }

  @override
  String get privacyExportAllFailed =>
      'Izvozne datoteke ni bilo mogoče zapisati';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Upravlja $operator · Supabase, EU (Frankfurt) · sinhronizira priljubljene, opozorila, vozila vklj. z VIN, točenja goriva, ocene, prijave in — če to vklopite — poti z GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Upravljavec podatkov ste vi — vaš lastni projekt Supabase, mi ga nikoli ne vidimo';

  @override
  String get syncModeJoinControllerNotice =>
      'Lastnik skupne podatkovne baze je upravljavec vaših podatkov';

  @override
  String get ugcPublicNoticeTitle => 'Deljeno z drugimi uporabniki';

  @override
  String get ugcPublicNoticeBody =>
      'To je shranjeno v sinhronizacijski bazi pod vašim psevdonimnim uporabniškim ID-jem. V Skupnosti Sparkilo lahko to prebere vsak prijavljen uporabnik. Kadar koli lahko to izbrišete v TankSync → Preglednost podatkov.';

  @override
  String get blockedAuthorsTitle => 'Blokirani uporabniki';

  @override
  String get blockedAuthorsDescription =>
      'Vsebina, ki jo delijo ti uporabniki, je v tej napravi skrita. Odblokirajte jih, da jo znova vidite.';

  @override
  String get blockedAuthorsEmpty => 'Ni blokiranih uporabnikov';

  @override
  String get blockedAuthorsUnblock => 'Odblokiraj';

  @override
  String get coachingGpsLiftOff => 'Spusti plin';

  @override
  String get coachingGpsAnticipateBrake => 'Predvidi';

  @override
  String get coachingGpsSmoothAccel => 'Gladko pospeševanje';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Sled pokriva $pct % — najdaljša vrzel $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Sled pokriva $pct % — brez zaznanih vrzeli';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'aplikacija v ozadju';

  @override
  String get gpsCoverageAttrOsBatching => 'sistem je združeval položaje';

  @override
  String get gpsCoverageAttrGateRejected => 'položaji filtrirani';

  @override
  String get gpsCoverageAttrDeliveryStall => 'zakasnela dostava';

  @override
  String get gpsCoverageAttrSignalLoss => 'izguba signala';

  @override
  String get gpsCoverageAttrUnknown => 'neznan vzrok';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Aplikacija je bila v ozadju brez storitve v ospredju, zato je sistem omejil GPS. Med snemanjem imejte zaslon vklopljen ali vklopite snemanje v ozadju, ko bo na voljo.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Sistem je položaje dostavil pozno in v paketih; sled se je naknadno dopolnila, zato je bilo dejansko izgubljenih malo podatkov.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Šumni položaji na tem odseku so bili filtrirani, da razdalja ostane poštena.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Položaji so bili določeni pravočasno, a so do aplikacije prispeli pozno — telefon je bil zaseden (pogosto ponovno povezovanje Bluetooth). Sprejem je bil dober.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Sprejem GPS je izpadel — običajno predor, pokrito parkirišče ali gosta mestna pozidava.';

  @override
  String get gpsCoverageHintUnknown =>
      'Ta vožnja ne vsebuje informacij o stanju aplikacije med vrzeljo, zato vzroka ni mogoče določiti.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'motnja zaradi ponovnega povezovanja OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Vrzel sovpada z epizodo ponovnega povezovanja OBD2 — povezava z adapterjem si je opomogla, medtem ko se je sprejem GPS ustavil. Popravilo povezave z adapterjem popravi tudi sled.';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostika vzorčenja GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps vrzeli',
      one: '1 vrzel',
      zero: 'brez vrzeli',
    );
    return '$count vzorcev · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Mediani interval: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Zajeto med snemanjem za preverjanje frekvence GPS pri spanju telefona.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Največja vrzel: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Nadaljevanje';

  @override
  String get gpsLifecyclePaused => 'Zaustavljeno';

  @override
  String get gpsLifecycleInactive => 'Neaktivno';

  @override
  String get gpsKpiVerdictGood => 'Učinkovita';

  @override
  String get gpsKpiVerdictModerate => 'Zmerna';

  @override
  String get gpsKpiVerdictAggressive => 'Agresivna';

  @override
  String get gpsKpiInterpretationGood =>
      'Gladka, varčna vožnja — tako je videti učinkovitost.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Dokaj običajna vožnja — malo mehkejši plin bi prihranil več.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energijsko potratna vožnja — popuščanje plina in več kotaljenja bi zmanjšala porabo.';

  @override
  String get gpsMatrixMaturityCold => 'Hladna';

  @override
  String get gpsMatrixMaturityWarming => 'Segreva se';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergirana';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS matrica se še segreva ($count prilagoditev do zdaj). Ocene so začasne.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS matrica konvergira ($count točenj). Ocene so uporabne z možnim odstopanjem nekaj %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS matrica je konvergirala ($count točenj). Ocene v okviru ~2 % dejanske porabe.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'Ocena GPS (~) — na tej vožnji ni tipala za gorivo. Vrednost je modelirana iz hitrosti in kalibracije vašega vozila; natančnost se izboljša, ko se matrika dozori.';

  @override
  String get gpsRoadUseCardTitle => 'Kako ste uporabljali cesto';

  @override
  String get gpsRoadUseSpeedSection => 'Kje ste preživeli čas';

  @override
  String get gpsRoadUseSpeedIdle => 'Mirovanje (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Mesto (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Odprta cesta (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Hitro (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Kako ste se premikali';

  @override
  String get gpsRoadUsePhaseAccel => 'Pospeševanje';

  @override
  String get gpsRoadUsePhaseSteady => 'Enakomerna hitrost';

  @override
  String get gpsRoadUsePhaseCoast => 'Kotaljenje';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Veliko kotaljenja — pustiti avto, da se kotali, namesto zaviranja prihrani gorivo. Odlično.';

  @override
  String get gpsRoadUseSource => 'Iz vaše sledi GPS';

  @override
  String get hapticEcoCoachSettingTitle => 'Eko coaching v realnem času';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Blag haptičen odziv + sporočilo na zaslonu, ko med vožnjo pritisnete na plin';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Nežno s plinom — drsenje prihrani več';

  @override
  String highwayViaExit(String ref, String km) {
    return 'prek izvoza $ref · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigiraj do $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Odstrani $name iz priljubljenih';
  }

  @override
  String get showOnMapSemanticLabel => 'Prikaži postaje na zemljevidu';

  @override
  String get searchResultsSemanticLabel => 'Rezultati iskanja';

  @override
  String get searchCriteriaSemanticLabel =>
      'Povzetek meril iskanja. Tapnite za urejanje.';

  @override
  String get noFavoritesSemanticLabel =>
      'Še ni priljubljenih. Tapnite zvezdico postaje, da jo shranite med priljubljene.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Postaja je odprta',
      'false': 'Postaja je zaprta',
      'other': 'Postaja je zaprta',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Država $name, izbrano',
      'false': 'Država $name',
      'other': 'Država $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Jezik $name, izbrano',
      'false': 'Jezik $name',
      'other': 'Jezik $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Razvrsti po $option, izbrano',
      'false': 'Razvrsti po $option',
      'other': 'Razvrsti po $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Gorivo $type, izbrano',
      'false': 'Gorivo $type',
      'other': 'Gorivo $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Polnilna postaja $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Ščit zasebnosti s kapljico goriva';

  @override
  String get globeIllustrationSemantic => 'Globus z oznakami bencinskih črpalk';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Točilna naprava s cenovnim prikazom';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, vir podatkov: $provider, $keyRequirement, vrste goriva: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Zahtevan je ključ API';

  @override
  String get countryInfoNoKeyNeeded => 'Brezplačno, ključ ni potreben';

  @override
  String countryInfoDataSource(String provider) {
    return 'Podatki: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Vrste goriva: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anonimni ključ';

  @override
  String get anonKeyHideTooltip => 'Skrij ključ';

  @override
  String get anonKeyShowTooltip => 'Pokaži ključ za preverjanje';

  @override
  String anonKeyTooLong(int length) {
    return 'Ključ je predolg ($length znakov) — preverite, ali ni odvečnega besedila';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Ključ je videti pravilen ($length znakov)';
  }

  @override
  String get anonKeyShouldBeJwt => 'Ključ mora biti JWT (glava.vsebina.podpis)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Ključ je morda okrnjen ($length od ~208 pričakovanih znakov)';
  }

  @override
  String get anonKeyExceedsMax => 'Ključ presega največjo dolžino';

  @override
  String get qrShareTitle => 'Deli svojo bazo podatkov';

  @override
  String get qrShareSubtitle => 'Drugi lahko skenirajo to kodo QR za povezavo';

  @override
  String get qrShareCopyAsText => 'Kopiraj kot besedilo';

  @override
  String get authInfoTitle => 'Zakaj ustvariti račun?';

  @override
  String get authInfoBenefit1 =>
      '• Sinhronizirajte priljubljene, opozorila in shranjene poti med napravami';

  @override
  String get authInfoBenefit2 =>
      '• Načrtujte pot na telefonu, uporabite jo v avtomobilu';

  @override
  String get authInfoBenefit3 =>
      '• Nobeni podatki se ne delijo s tretjimi stranmi';

  @override
  String get authInfoBenefit4 => '• Račun lahko kadar koli izbrišete';

  @override
  String get privacyLocalDataEmpty =>
      'Še ni shranjenih podatkov. Dodajte priljubljeno ali nastavite cenovno opozorilo za prikaz vnosov tukaj.';

  @override
  String get privacyHideEmptyRows => 'Skrij prazne vrstice';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pokaži $count praznih vrstic',
      one: 'Pokaži $count prazno vrstico',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Nastavitev ključa API (neobvezno)';

  @override
  String get apiKeySetupDescription =>
      'Registrirajte se za brezplačni ključ API ali preskočite in raziščite aplikacijo z demo podatki.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Registracija $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Z vnosom ključa API sprejemate pogoje $provider. Prerazporeditev podatkov je prepovedana.';
  }

  @override
  String get calculatorDistanceHint => 'npr. 150';

  @override
  String get calculatorConsumptionHint => 'npr. 7,0';

  @override
  String get calculatorPriceHint => 'npr. 1,899';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (eksperimentalno)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtilna haptika pri upočasnjevanju pred rdečo lučjo. Privzeto izklop — tveganje motenja.';

  @override
  String get consentSyncTripsTitle => 'Sinhroniziraj posnetke voženj';

  @override
  String get consentSyncTripsSubtitle =>
      'Varnostno kopiraj OBD2 + GPS vožnje v TankSync. Med napravami, po izbiri.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Zgoraj omogočite sinhronizacijo v oblaku za varnostno kopiranje voženj.';

  @override
  String get consentSyncTripsAnonymousHint =>
      'Vožnje se varnostno kopirajo pod anonimnim računom te naprave. Prijavite se z e-pošto, da do njih dostopate z drugih naprav.';

  @override
  String get consentHideDetails => 'Skrij podrobnosti';

  @override
  String get consentShowDetails => 'Prikaži podrobnosti';

  @override
  String get dialogOk => 'V redu';

  @override
  String get invalidLinkTitle => 'Neveljavna povezava';

  @override
  String invalidLinkBody(String path) {
    return 'Povezava \"$path\" ni veljavna.';
  }

  @override
  String get home => 'Domov';

  @override
  String get accelBrakeCardTitle => 'Pospeševanje in zaviranje';

  @override
  String get accelBrakeHardAccel => 'Trda pospeševanja';

  @override
  String get accelBrakeHardBrake => 'Trda zaviranja';

  @override
  String get accelBrakeSharpCorner => 'Ostri zavoji';

  @override
  String get accelBrakeSource => 'Iz gibalnih senzorjev telefona';

  @override
  String lessonHardBrake(String count) {
    return '$count dogodkov trdega zaviranja';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Predvidite postanke in prej rahljajte plin — trdo zaviranje zavrže gorivo, ki ste ga porabili za pospeševanje.';

  @override
  String lessonSharpCornering(String count) {
    return '$count ostrih zavojev';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Upočasnite pred zavojem, ne v njem — ostro zavijanje izgubi hitrost, ki jo nato morate pridobiti nazaj.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Zadnjih $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Enota porabe';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Kako je poraba goriva prikazana povsod v aplikaciji';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Samodejno ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Okno porabe v živo';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Povpreči vrednost v živo čez zadnjih nekaj sekund – daljše je mirnejše, krajše se odziva hitreje';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String get consumptionDisplaySectionTitle => 'Prikaz porabe';

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'ocen. $unit';
  }

  @override
  String get locationConsentTitle => 'Dostop do lokacije';

  @override
  String get locationConsentSubtitle =>
      'Ta aplikacija želi uporabiti vašo lokacijo za iskanje bližnjih bencinskih črpalk.';

  @override
  String get locationConsentWhatHappens =>
      'Kaj se zgodi z vašimi podatki o lokaciji:';

  @override
  String get locationConsentBulletApi =>
      'Vaše koordinate so poslane API-ju cen goriv za iskanje bližnjih črpalk.';

  @override
  String get locationConsentBulletNoServer =>
      'Vaša lokacija ni shranjena na nobenem strežniku — strežnika ni.';

  @override
  String get locationConsentBulletNoTracking =>
      'Podatki o lokaciji se ne uporabljajo za oglaševanje, analitiko ali sledenje.';

  @override
  String get locationConsentRevoke =>
      'Dostop do lokacije lahko kadar koli prekličete v sistemskih nastavitvah. Lahko pa iščete tudi po poštni številki.';

  @override
  String get locationConsentLegalBasis =>
      'Pravna podlaga: člen 6(1)(a) GDPR (privolitev)';

  @override
  String get loyaltySettingsTitle => 'Kartice gorivnih klubov';

  @override
  String get loyaltySettingsSubtitle =>
      'Uporabite popust zvestobe na prikazane cene';

  @override
  String get loyaltyMenuTitle => 'Kartice gorivnih klubov';

  @override
  String get loyaltyMenuSubtitle =>
      'Uporabite popuste na liter pri Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Dodaj kartico';

  @override
  String get loyaltyAddCardSheetTitle => 'Dodaj kartico gorivnega kluba';

  @override
  String get loyaltyBrandLabel => 'Blagovna znamka';

  @override
  String get loyaltyCardLabelLabel => 'Oznaka (neobvezno)';

  @override
  String get loyaltyDiscountLabel => 'Popust (na liter)';

  @override
  String get loyaltyDiscountInvalid => 'Vnesite pozitivno število';

  @override
  String get loyaltyDeleteConfirmTitle => 'Izbrisati kartico?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Ta kartica bo prenehala uveljavljati popust.';

  @override
  String get loyaltyEmptyTitle => 'Še ni kartic gorivnih klubov';

  @override
  String get loyaltyEmptyBody =>
      'Dodajte kartico za samodejno uveljavljanje popusta na liter pri ustreznih postajah.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Zaznano naraščanje vrtljajev v prostem teku';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Vrtljaji v prostem teku so v zadnjih $tripCount vožnjah narasli za $percent%. Možen zgodnji znak zamašenega zračnega filtra ali odklona senzorja.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Možna omejitev vsesa';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Pretok goriva pri vožnji se je v zadnjih $tripCount vožnjah zmanjšal za $percent%. Možen znak zamašenega zračnega filtra ali omejenega vsesa — vredno pregleda.';
  }

  @override
  String get maintenanceActionDismiss => 'Zapri';

  @override
  String get maintenanceActionSnooze => 'Odmor 30 dni';

  @override
  String get consumptionMonthlyInsightsTitle => 'Ta mesec vs. prejšnji mesec';

  @override
  String get consumptionMonthlyTripsLabel => 'Vožnje';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Čas vožnje';

  @override
  String get consumptionMonthlyDistanceLabel => 'Razdalja';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Povpr. poraba';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Za primerjavo so potrebne vsaj 3 vožnje na mesec';

  @override
  String get consumptionMonthlyClimbLabel => 'Vzpenjeno';

  @override
  String get obd2CapabilitySectionTitle => 'Zmogljivosti adapterja';

  @override
  String get obd2CapabilityStandardOnly => 'Standardno';

  @override
  String get obd2CapabilityOemPids => 'OEM PID-ji';

  @override
  String get obd2CapabilityFullCan => 'Polni CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Za natančne litre v rezervoarju pri Peugeot/Citroën aplikacija podpira OBDLink MX+/LX/CX (čip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Diagnostična prekrivna plast OBD2 omogočena';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Diagnostična prekrivna plast OBD2 onemogočena';

  @override
  String get obd2DebugOverlayClearButton => 'Počisti';

  @override
  String get obd2DebugOverlayCloseButton => 'Zapri';

  @override
  String get obd2DebugOverlayTitle => 'Sledilne točke OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Deli diagnostični dnevnik';

  @override
  String get obd2DebugLoggingTitle => 'Razhroščevalno beleženje OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Zabeležite vsako sejo OBD2 — povezavo, rokovanje, vrzeli v podatkih in ponovne povezave — v izvozljiv dnevnik XML. Privzeto izklopljeno.';

  @override
  String get obd2DebugSessionShareLabel => 'Deli dnevnik seje OBD2';

  @override
  String get obd2DiagnosticsTitle => 'Diagnostika komunikacije OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops izpadov',
      one: '1 izpad',
      zero: 'ni izpadov',
    );
    return '$percent% dokončano · $duty% obremenitev · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Življenjski cikel povezave';

  @override
  String get obd2DiagnosticsPidSection => 'Rezultati po PID';

  @override
  String get obd2DiagnosticsReconnectSection =>
      'Telemetrija ponovnega povezovanja';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts poskusov ponovne povezave · $successes uspešnih · $transitions prehodov · $disconnects razvrščenih prekinitev';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'V tej seji je bil vklopljen rezervni način samo z GPS.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Zdravje razporejanja';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Popolnost';

  @override
  String get obd2DiagnosticsSupportSection => 'Odkrita podprta PID';

  @override
  String get obd2DiagnosticsFuelSection => 'Zbirni pregled goriva';

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
    return '$attempts poskusov · $successes uspešnih · $drops izpadov · čas do povezave p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Ponovne povezave: $silent tihe · $visible vidne';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz takt · $skips preskočenih zahtev · $demotions razvrstitev';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dinamični nivo stradal — RPM / hitrost je padla pod prag regulatorja.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Skupno $percent% · aktivna obremenitev $duty%';
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
    return '$supported podprtih · $unsupported nepodprtih · $unknown neznanih';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Sumljivih $suspicious od $total vzorcev';
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
    return '$pid: $polled poizvedb · $ok uspešnih · $noData ND · $timeout TO · $error napak · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Prepis inicializacije dongla';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokol $protocol · $start · strojna oprema $firmware · $tier · $pids PID';
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
      'Seja OBD2 še ni bila posneta — priključite adapter in posnemite vožnjo z vklopljenim načinom za razvijalce.';

  @override
  String get obd2DiagnosticsExplain =>
      'Zajeto med snemanjem za odpravljanje napak v komunikaciji dongle↔aplikacija — zbira se le v načinu za razvijalce.';

  @override
  String get obd2HealthScreenTitle => 'Diagnostika komunikacije OBD2';

  @override
  String get obd2HealthNavLabel => 'Diagnostika komunikacije OBD2';

  @override
  String get obd2HealthLiveSection => 'Živa seja';

  @override
  String get obd2HealthHistorySection => 'Nedavne seje';

  @override
  String get obd2HealthDownloadJson => 'Prenesi kot JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Prenesi samo zapis inicializacije';

  @override
  String get obd2HealthDownloadError =>
      'Diagnostične datoteke ni bilo mogoče shraniti';

  @override
  String get obd2TestAdapterLabel => 'Adapter za preizkus';

  @override
  String get obd2TestAdapterScanOption => 'Poišči adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Povezovanje z $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Zaženi test adapterja';

  @override
  String get obd2TestRunButton => 'Zaženi test adapterja';

  @override
  String get obd2TestRunPassed => 'Test adapterja je uspel';

  @override
  String get obd2TestRunFailed => 'Test adapterja ni uspel';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — motor ugasnjen; zaženite motor za branje podatkov v živo';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed od $total korakov OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Pred zagonom testa adapterja ustavite aktivno snemanje.';

  @override
  String get obd2TestStepScan => 'Iskanje adapterja';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth telefona';

  @override
  String get obd2TestStepConnect => 'Poveži in inicializiraj';

  @override
  String get obd2TestStepInfo => 'Informacije o adapterju';

  @override
  String get obd2TestStepSupportedPids => 'Podprti PID';

  @override
  String get obd2TestStepProtocol => 'Protokol vozila';

  @override
  String get obd2TestStepSampleReads => 'Vzorčna branja';

  @override
  String get obd2TestStepSoak => 'Dolgotrajno poizvedovanje';

  @override
  String get obd2TestStepReconnect => 'Test ponovne povezave';

  @override
  String get obd2TestStepDisconnect => 'Prekini';

  @override
  String get obd2TestStatusOk => 'V redu';

  @override
  String get obd2TestStatusTimeout => 'Prekoračen čas';

  @override
  String get obd2TestStatusGarbage => 'Neberljiv odgovor';

  @override
  String get obd2TestStatusNoResponse => 'Ni odgovora';

  @override
  String get obd2TestStatusFail => 'Neuspešno';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'neznano — privzeto BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Nedavni poskusi povezave';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Zabeleženih še ni nobenih poskusov povezave.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Prenesi dnevnik povezave';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Prenesi vse dnevnike povezav';

  @override
  String get obd2HealthConnectOrigin => 'Izvor';

  @override
  String get obd2HealthConnectTransport => 'Prenos';

  @override
  String get obd2HealthConnectOutcome => 'Izid';

  @override
  String get obd2HealthConnectScanList => 'Najdene naprave';

  @override
  String get obd2HealthConnectSteps => 'Koraki';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Neznan adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Seja posneta · $samples vzorcev motorja · $percent-odstotna pokritost';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection =>
      'Kaj je ta vožnja zabeležila';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples od $total vzorcev je vsebovalo podatke motorja ($percent %)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Vzpostavitev protokola: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Seja končana: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Trajanje seje: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Podatki o porabi prihajajo iz adapterja, ne iz ocen GPS.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Podrobnosti komunikacije po PID za to vožnjo niso bile zajete. Če jih želite zbrati, pred snemanjem vklopite razvijalski način.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Ni bilo mogoče doseči \'$adapterName\' — izberite drug adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Druge naprave Bluetooth';

  @override
  String get obd2PickerTapToTry => 'Neprepoznano — dotaknite se za poskus';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone deluje samo z adapterji Bluetooth LE. Adapter, ki podpira samo Classic (npr. vLinker BM, Konnwei KW902), je treba uporabiti na Androidu.';

  @override
  String get obd2PairingConfirmHint =>
      'Potrdite zahtevo za seznanjanje na telefonu';

  @override
  String get obd2ScanEmptyTitle => 'Adapter ni najden';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth je vklopljen in dovoljenja so dodeljena. Preverite, ali je adapter priklopljen v vtičnico OBD2 in ali je kontakt vklopljen, nato znova poiščite.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Ta naprava nima strojne opreme Bluetooth Low Energy, zato se ne more povezati z adapterjem OBD2.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth je izklopljen. Vklopite ga, da poiščete svoj adapter.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo potrebuje dovoljenje za Bluetooth, da najde vaš adapter.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Dovoljenje za Bluetooth je bilo trajno zavrnjeno. Dodelite ga v sistemskih nastavitvah, da poiščete adapter.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Lokacijske storitve so na tej napravi izklopljene. Android jih zahteva za iskanje adapterjev Bluetooth — nobena lokacija se ne beleži ali deli.';

  @override
  String get obd2ScanOpenSettings => 'Odpri nastavitve';

  @override
  String get obd2WaitingForEngineBanner => 'Čakanje na motor — snemanje z GPS';

  @override
  String get obd2StartEngineToReconnect => 'Zaženite motor za ponovno povezavo';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motor je ugasnjen — zaženite ga za ponovno povezavo';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motor ugasnjen že $minutes min — ustaviti snemanje?';
  }

  @override
  String get obd2ParkedPromptStop => 'Ustavi';

  @override
  String get obd2ParkedPromptKeep => 'Nadaljuj';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motor ugasnjen prvih $head in zadnjih $tail te vožnje — pokritost se meri med delovanjem motorja.';
  }

  @override
  String get obd2ReconnectInProgress =>
      'Ponovno povezovanje z vašim adapterjem OBD2…';

  @override
  String get obd2StatusEngineOff => 'OBD2 zaustavljen — motor ugasnjen';

  @override
  String get obd2StatusEngineOffBody =>
      'Adapter je bil dosegljiv, a vodilo vozila je ostalo tiho, zato je samodejno ponovno povezovanje zaustavljeno. Nadaljuje se, ko se peljete ali znova odprete aplikacijo — ali se povežite zdaj.';

  @override
  String get obd2StatusReconnectNow => 'Poveži znova zdaj';

  @override
  String get autoRecordNotificationTitle => 'Samodejno snemanje voženj';

  @override
  String get autoRecordNotificationText => 'Čakanje na vaš adapter OBD2';

  @override
  String get obd2ResetConnection => 'Ponastavi povezavo';

  @override
  String get obd2ResetConnectionDone =>
      'Adapter ponastavljen — povezava znova vzpostavljena';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapter ponastavljen — ponovno povezovanje v ozadju';

  @override
  String get ocrTesterTitle => 'Tester OCR';

  @override
  String get ocrTesterNavLabel => 'Tester OCR';

  @override
  String get ocrTesterExplain =>
      'Zaženite cevovod OCR za črpalko/račun na izbrani fotografiji in preglejte vsak korak — na voljo le v načinu za razvijalce.';

  @override
  String get ocrTesterCapture => 'Zajemi';

  @override
  String get ocrTesterPickImage => 'Izberi sliko';

  @override
  String get ocrTesterRun => 'Zaženi';

  @override
  String get ocrTesterCountry => 'Država';

  @override
  String get ocrTesterCountryNone => 'Privzeto (brez profila)';

  @override
  String get ocrTesterNoImage => 'Izberite ali zajemite sliko, nato zaženite.';

  @override
  String get ocrTesterRunning => 'Izvajanje OCR…';

  @override
  String get ocrTesterOverlaySection => 'Prekrivni blok';

  @override
  String get ocrTesterStepsSection => 'Koraki cevovoda';

  @override
  String get ocrTesterLegendLabel => 'Oznaka';

  @override
  String get ocrTesterLegendNumeric => 'Številčno';

  @override
  String get ocrTesterLegendNoise => 'Šum';

  @override
  String get ocrTesterLegendDerived => 'Izpeljano';

  @override
  String get ocrTesterStageGlare => 'Zajem / blesk';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Razvrsti';

  @override
  String get ocrTesterStageAssemble => 'Sestavi';

  @override
  String get ocrTesterStageAnchor => 'Sidro';

  @override
  String get ocrTesterStageFallback => 'Nadomestek';

  @override
  String get ocrTesterStageCrossCheck => 'Navzkrižno preverjanje';

  @override
  String get ocrTesterStageConfidence => 'Zaupanje';

  @override
  String get ocrTesterStageGate => 'Vrata';

  @override
  String get ocrTesterStageBrand => 'Blagovna znamka';

  @override
  String get ocrTesterStageOverrides => 'Preglasitve';

  @override
  String get ocrTesterStageReconcile => 'Uskladitev';

  @override
  String get ocrTesterStageResult => 'Rezultat';

  @override
  String get ocrTesterChipRead => 'PREBRANO';

  @override
  String get ocrTesterChipDerived => 'IZPELJANO';

  @override
  String get ocrTesterGateAccepted => 'Sprejeto';

  @override
  String get ocrTesterGateRejected => 'Zavrnjeno';

  @override
  String get ocrTesterFallbackBanner =>
      'Polje je bilo obnovljeno z nadomestnim mehanizmom — preverite ga.';

  @override
  String get ocrTesterStageNoData => 'Stopnja ni bila izvedena.';

  @override
  String get ocrTesterCopyJson => 'Kopiraj kot JSON';

  @override
  String get ocrTesterExportPackage => 'Izvozi paket';

  @override
  String get ocrTesterCopied => 'Sled OCR kopirana v odložišče.';

  @override
  String get ocrTesterExported => 'Paket OCR shranjen v mapo Prenosi.';

  @override
  String get onboardingObd2StepTitle => 'Povežite adapter OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Priključite adapter OBD2 v vrata avtomobila in vklopite vžig. Prebrali bomo VIN in izpolnili podrobnosti motorja za vas.';

  @override
  String get onboardingObd2ConnectButton => 'Poveži adapter';

  @override
  String get onboardingObd2SkipButton => 'Morda pozneje';

  @override
  String get onboardingObd2ReadingVin => 'Branje VIN…';

  @override
  String get onboardingObd2ConnectFailed =>
      'Povezave z adapterjem ni bilo mogoče vzpostaviti. Lahko poskusite znova ali preskočite.';

  @override
  String get onboardingPickUseMode => 'Za nadaljevanje izberite način uporabe.';

  @override
  String get onboardingObd2LaterNote =>
      'Adapter Bluetooth OBD2 lahko kadar koli pozneje seznanite z zaslona vozila, da snemate vožnje in berete podatke motorja.';

  @override
  String get openNow => 'Odprto';

  @override
  String get openNowClosed => 'Zaprto';

  @override
  String get openHoursUnknown => 'Delovni čas neznan';

  @override
  String closesAt(String time) {
    return 'Zapre se ob $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Odpre se $day ob $time';
  }

  @override
  String opensToday(String time) {
    return 'Odpre se ob $time';
  }

  @override
  String get open24Hours => 'Odprto 24 ur';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => 'Avtomatiziraj 24/7';

  @override
  String get dayMon => 'Ponedeljek';

  @override
  String get dayTue => 'Torek';

  @override
  String get dayWed => 'Sreda';

  @override
  String get dayThu => 'Četrtek';

  @override
  String get dayFri => 'Petek';

  @override
  String get daySat => 'Sobota';

  @override
  String get daySun => 'Nedelja';

  @override
  String get dayShortMon => 'Pon';

  @override
  String get dayShortTue => 'Tor';

  @override
  String get dayShortWed => 'Sre';

  @override
  String get dayShortThu => 'Čet';

  @override
  String get dayShortFri => 'Pet';

  @override
  String get dayShortSat => 'Sob';

  @override
  String get dayShortSun => 'Ned';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Državni prazniki';

  @override
  String get closedLabel => 'Zaprto';

  @override
  String get openingHoursNotAvailable => 'Delovni čas ni na voljo';

  @override
  String get showAllHours => 'Prikaži ves delovni čas';

  @override
  String get showLessHours => 'Prikaži manj';

  @override
  String get openStateUnknown => 'Neznano';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Postaja je odprta',
      'false': 'Postaja je zaprta',
      'other': 'Stanje odprtosti neznano',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Dostop do kamere';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Ta aplikacija želi uporabiti vašo kamero za branje računov, zaslonov na črpalkah in kod QR.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Kaj se zgodi s sliko kamere:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'Slika se uporablja samo za branje računa, zaslona črpalke ali kode QR — prepoznavanje poteka v vaši napravi.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'Fotografija se po skeniranju zavrže.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Nič se ne naloži, razen če pošljete prijavo napačnega skeniranja in jo potrdite.';

  @override
  String get permissionRationaleBluetoothTitle =>
      'Dostop do funkcije Bluetooth';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Ta aplikacija želi uporabiti Bluetooth za povezavo z vašim adapterjem OBD2.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Kaj se zgodi s funkcijo Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth se uporablja samo za iskanje vašega adapterja OBD2 in komunikacijo z njim.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Identifikator adapterja ostane v vaši napravi — sinhronizira se samo prek storitve TankSync kot del profila vozila.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'V sistemu Android 11 in starejših sistem zahteva tudi lokacijo, ker se iskanje Bluetooth tam šteje za dovoljenje za lokacijo.';

  @override
  String get permissionRationaleNotificationsTitle => 'Obvestila';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Ta aplikacija vam želi pošiljati obvestila o cenovnih opozorilih in stanju snemanja poti.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Kaj se zgodi z obvestili:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Obvestila se uporabljajo za lokalna cenovna opozorila in stanje snemanja poti.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Ustvarijo se v vaši napravi — nič ne zapusti naprave.';

  @override
  String get permissionRationaleRevoke =>
      'To lahko kadar koli prekličete v nastavitvah naprave.';

  @override
  String get permissionRationaleLegalBasis =>
      'Pravna podlaga: člen 6(1)(a) GDPR (privolitev)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'ocen. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Ocenjena vrednost (~) — na tej vožnji ni tipala za gorivo, zato je vrednost L/100 km modelirana iz hitrosti GPS in kalibracije vašega vozila. Je približna (tipično ±10–30 %, z dozorevanjem kalibracije se natančnost izboljšuje) in ni izmerjena vrednost.';

  @override
  String get tripRecordingPipElapsedCaption => 'preteklo';

  @override
  String get qrLaunchConfirmTitle => 'Odpreti skenirano povezavo?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Ta koda QR vodi na $host. Odpirajte samo povezave, ki jim zaupate.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Odpri povezavo';

  @override
  String get qrLaunchConfirmCancel => 'Prekliči';

  @override
  String get radarPinHelpTitle => 'O pritrdilu';

  @override
  String get radarPinHelpBody =>
      'Pritrditev ohranja zaslon vklopljen in skriva sistemske vrstice, da odčitek najbližje postaje ostane berljiv na armaturni plošči. Tapnite znova za sprostitev. Samodejno se sprosti, ko se radar ustavi.';

  @override
  String get radarAutoPinTitle => 'Vedno pritrdite ob zagonu radarja';

  @override
  String get radarAutoPinSubtitle =>
      'Radar se samodejno pritrdi vsakič namesto da tapnete vsak krat. Porabi več baterije.';

  @override
  String get radarScopeShowScope => 'Pogled radarja';

  @override
  String get radarScopeShowList => 'Pogled seznama';

  @override
  String get alertsRadiusFrequencyLabel => 'Pogostost preverjanja';

  @override
  String get alertsRadiusFrequencyDaily => 'Enkrat na dan';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Dvakrat na dan';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Trikrat na dan';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Štirikrat na dan';

  @override
  String get radiusAlertPickOnMap => 'Izberi na zemljevidu';

  @override
  String get radiusAlertMapPickerTitle => 'Izberi središče opozorila';

  @override
  String get radiusAlertMapPickerConfirm => 'Potrdi';

  @override
  String get radiusAlertMapPickerCancel => 'Prekliči';

  @override
  String get radiusAlertMapPickerHint =>
      'Povlecite zemljevid za postavitev središča opozorila';

  @override
  String get radiusAlertCenterFromMap => 'Lokacija na zemljevidu';

  @override
  String get reconcileWorkflowTitle => 'Uskladite gorivo';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Najdena razlika $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Natočili ste $pumped L, a zabeležene vožnje beležijo le $consumed L. Preostalih $gap L je nepojasnjen.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'To se ponavadi zgodi, ker vožnja ni bila zabeležena (adapter je bil izklopljen ali aplikacija zaprta) ali ker manjka oziroma je napačno vnesen natočen liter.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Dokler to ni rešeno, se skupna vsota goriva in skupna vsota voženj ne bosta ujemali.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Pomagajte nam pripisati razliko';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'So vsi vnosi polnjenj za ta rezervoar popolni in pravilni?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'So vse vožnje zabeležene?';

  @override
  String get reconcileWorkflowAnswerYes => 'Da';

  @override
  String get reconcileWorkflowAnswerNo => 'Ne';

  @override
  String get reconcileWorkflowPathAHint =>
      'Manjka ali je napačen vnos polnjenja — dodali bomo popravek, da se seštevek polnjenj ujema.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Polnjenja so pravilna, ena vožnja pa ni bila zabeležena — dodali bomo navidezno vožnjo za manjkajoče kilometre.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Popravek litrov';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Kako daleč je bila nezabeležena vožnja? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Odloči pozneje';

  @override
  String get reconcileWorkflowBack => 'Nazaj';

  @override
  String get reconcileWorkflowNext => 'Naprej';

  @override
  String get reconcileWorkflowApply => 'Uporabi';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Navidezna vožnja — tapnite za urejanje';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Uredi navidezno vožnjo';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Ta vožnja je bila dodana, da bi upoštevali gorivo, porabljeno med vožnjo brez snemanja. Prilagodite razdaljo ali gorivo ali jo izbrišite.';

  @override
  String get reconcileVirtualTrajetDelete => 'Izbriši navidezno vožnjo';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Nerazrešena razlika gorivo/vožnja $gap L — tapnite za rešitev';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Razreši nerazrešeno razliko med gorivom in vožnjami';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/seja';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Te vrste datoteke še ni mogoče uvoziti — namesto tega delite fotografijo računa.';

  @override
  String get shareReceiptFailed =>
      'Deljenega računa ni bilo mogoče prebrati — poskusite znova ali ročno dodajte polnjenje.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt => 'Deli račun za uvoz';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Delite fotografijo računa iz druge aplikacije za predizpolnitev polnjenja — datum, litri, skupaj in postaja se preberejo v napravi.';

  @override
  String get speedConsumptionCardTitle => 'Poraba glede na hitrost';

  @override
  String get speedBandIdleJam => 'Prosti tek / zastoj';

  @override
  String get speedBandUrban => 'Mestno (10–50)';

  @override
  String get speedBandSuburban => 'Primestno (50–80)';

  @override
  String get speedBandRural => 'Podeželsko (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eko vožnja (100–115)';

  @override
  String get speedBandMotorway => 'Avtocesta (115–130)';

  @override
  String get speedBandMotorwayFast => 'Hitra avtocesta (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Posnemite 30+ minut voženj z adapterjem OBD2 za odklepanje analize hitrosti/porabe.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % vožnje';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Potrebnih je več podatkov';

  @override
  String get splashLoadingLabel => 'Nalaganje Sparkilo';

  @override
  String get storageRecoveryTitle => 'Težava s shrambo';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo ni mogel odpreti svoje lokalne shrambe podatkov. Videti je, da je datoteka shrambe poškodovana.';

  @override
  String get storageRecoveryGuidance =>
      'Za obnovitev počistite shrambo aplikacije v nastavitvah naprave ali znova namestite aplikacijo. Vaše priljubljene in zgodovina so shranjene samo v tej napravi, zato jih ni mogoče samodejno obnoviti.';

  @override
  String syncAdoptTitle(String email) {
    return 'Pridruži se računu $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Prijavite se z geslom tega računa, da njegove podatke delite na obeh napravah.';

  @override
  String get syncAdoptPasswordLabel => 'Geslo računa';

  @override
  String get syncAdoptJoinButton => 'Pridruži se računu';

  @override
  String get syncAdoptUseDifferentAccount => 'Raje uporabi drug račun';

  @override
  String get syncDeleteDataTitle => 'Izbriši sinhronizirane podatke';

  @override
  String get syncDeleteDataSubtitle =>
      'Odstranite svoje vožnje, vozila ali točenja iz baze za sinhronizacijo';

  @override
  String get syncDeleteDataPickTitle =>
      'Katere sinhronizirane podatke izbrisati?';

  @override
  String get syncDeleteDataCategoryTrips => 'Vožnje';

  @override
  String get syncDeleteDataCategoryVehicles => 'Vozila';

  @override
  String get syncDeleteDataCategoryFillUps => 'Točenja';

  @override
  String get syncDeleteDataCategoryEverything => 'Vse';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Izbrisati $category iz baze za sinhronizacijo?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'To odstrani izbrane podatke iz vaše baze za sinhronizacijo in se ne bodo znova sinhronizirali z vaših drugih naprav. Podatki, shranjeni lokalno na tej napravi, ostanejo.';

  @override
  String get syncDeleteDataConfirmAction => 'Izbriši s strežnika';

  @override
  String get syncDeleteDataDone => 'Sinhronizirani podatki izbrisani';

  @override
  String get syncDeleteDataFailed =>
      'Brisanje sinhroniziranih podatkov ni uspelo — poskusite znova';

  @override
  String get syncRelinkTitle =>
      'Sinhronizacijo v oblaku je treba znova povezati';

  @override
  String get syncRelinkBody =>
      'Shranjena identiteta za sinhronizacijo te naprave je odjavljena. Prijavite se z e-pošto, da znova povežete sinhronizirane podatke, ali začnite znova z novo identiteto.';

  @override
  String get syncRelinkSignInAction => 'Prijavi se za ponovno povezavo';

  @override
  String get syncRelinkStartFreshAction => 'Začni znova';

  @override
  String get syncRelinkStartFreshTitle => 'Začeti znova?';

  @override
  String get syncRelinkStartFreshBody =>
      'Za to napravo bo ustvarjena nova anonimna identiteta. Podatki, sinhronizirani pod staro identiteto, ostanejo na strežniku, a od tu ne bodo več dosegljivi, razen če se prijavite z njenim e-poštnim računom.';

  @override
  String get syncRelinkStartFreshConfirm => 'Začni znova';

  @override
  String get tankLevelTitle => 'Raven goriva';

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
    return '≈ $kilometres km pri porabi vašega zadnjega rezervoarja';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Dolgoročno povprečje: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Zadnje polnjenje: $date · $count vožnja(e) od takrat';
  }

  @override
  String get tankLevelEmptyNoFillUp =>
      'Zabeležite polnjenje za prikaz ravni goriva';

  @override
  String get tankLevelDetailSheetTitle => 'Vožnje od zadnjega polnjenja';

  @override
  String get addFillUpIsFullTankLabel => 'Poln rezervoar';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Rezervoar napolnjen do roba — odkljukajte, če je bilo to delno polnjenje';

  @override
  String tankLevelSourceFillUp(String date) {
    return 'Zasidrano na zadnjem točenju: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'Senzor rezervoarja OBD2 · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Mešanica v rezervoarju: $mix';
  }

  @override
  String get tankReportTitle => 'Poročilo o rezervoarju';

  @override
  String tankReportHeadline(String value) {
    return '$value L/100 km';
  }

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Od prejšnjega polnega rezervoarja: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km več kot prejšnji rezervoar';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km manj kot prejšnji rezervoar';
  }

  @override
  String get tankReportTrendFlat => 'Na ravni prejšnjega rezervoarja';

  @override
  String get tankReportNoPrevious =>
      'Razvoj se prikaže po vašem naslednjem polnem rezervoarju.';

  @override
  String tankReportCoverage(String pct) {
    return 'Posnetki pokrivajo $pct % tega rezervoarja';
  }

  @override
  String tankReportRecordedAvg(String value) {
    return 'Posneti del: $value L/100 km';
  }

  @override
  String get tankReportExplainHeader => 'Kaj nakazujejo posnetki';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Delež visokih vrtljajev $cur % (prej $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Sunkoviti manevri $cur/100 km (prej $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Hladni zagoni $cur (prej $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Delež prostega teka $cur % (prej $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Posnetki so naključni in pokrivajo le del tega rezervoarja — ti namigi so okvirni, ne celotna slika.';

  @override
  String tankReportCalibrationUnder(String pct) {
    return 'Posnete ocene so $pct % pod dejansko vrednostjo na črpalki';
  }

  @override
  String tankReportCalibrationOver(String pct) {
    return 'Posnete ocene so $pct % nad dejansko vrednostjo na črpalki';
  }

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'Sistem';

  @override
  String get themeCardSubtitleLight => 'Svetla';

  @override
  String get themeCardSubtitleDark => 'Temna';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Sledi sistemu';

  @override
  String get themeSettingsLightLabel => 'Svetla';

  @override
  String get themeSettingsDarkLabel => 'Temna';

  @override
  String get themeSettingsSystemDescription => 'Ujemi z videzom naprave.';

  @override
  String get themeSettingsLightDescription =>
      'Svetla ozadja — najboljše za dnevno uporabo.';

  @override
  String get themeSettingsDarkDescription =>
      'Temna ozadja — bolj ugodno za oči ponoči in varčuje z baterijo na zaslonih OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Prepoznavni zeleni videz aplikacije — svetel in enostaven za branje, z nežno zelenimi ozadji.';

  @override
  String get throttleRpmHistogramTitle => 'Kako ste uporabljali motor';

  @override
  String get throttleRpmHistogramThrottleSection => 'Položaj plina';

  @override
  String get throttleRpmHistogramRpmSection => 'Vrtljaji motorja';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Drsenje (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Nežno (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Zmerno (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Polni plin (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Prosti tek (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Vožnja (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Živahno (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Naporno (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'V tej vožnji ni vzorcev plina ali vrtljajev.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Vožnje';

  @override
  String get trajetsStartRecordingButton => 'Začni snemanje';

  @override
  String get trajetsResumeRecordingButton => 'Nadaljuj snemanje';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Povezovanje z adapterjem OBD2…';

  @override
  String get tripStartProgressReadingVehicleData => 'Branje podatkov vozila…';

  @override
  String get tripStartProgressStartingRecording => 'Zagon snemanja…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Zaključevanje povzetka…';

  @override
  String get tripSaveProgressSavingToHistory => 'Shranjevanje v zgodovino…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Sinhronizacija v ozadju…';

  @override
  String get trajetsEmptyStateTitle => 'Še ni voženj';

  @override
  String get trajetsEmptyStateBody =>
      'Tapnite Začni snemanje za začetek beleženja voženj.';

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
  String get trajetDetailSummaryTitle => 'Povzetek';

  @override
  String get trajetDetailFieldDate => 'Datum';

  @override
  String get trajetDetailFieldVehicle => 'Vozilo';

  @override
  String get trajetDetailFieldAdapter => 'Adapter OBD2';

  @override
  String get trajetDetailFieldDistance => 'Razdalja';

  @override
  String get trajetDetailFieldDuration => 'Trajanje';

  @override
  String get trajetDetailFieldAvgConsumption => 'Povpr. poraba';

  @override
  String get trajetDetailFieldFuelUsed => 'Porabljeno gorivo';

  @override
  String get trajetDetailFieldFuelCost => 'Strošek goriva';

  @override
  String get trajetDetailFieldAvgSpeed => 'Povpr. hitrost';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maks. hitrost';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Hitrost (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Pretok goriva (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Obremenitev motorja (%)';

  @override
  String get trajetDetailChartThrottle => 'Plin / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Hladilna tekočina (°C)';

  @override
  String get trajetDetailChartAltitudeRelative =>
      'Nadmorska višina (m, od začetka)';

  @override
  String get trajetDetailChartLambda => 'Komandirani λ';

  @override
  String get trajetDetailChartsSection => 'Grafikoni';

  @override
  String get trajetsRowColdStartChip => 'Hladen zagon';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motor med to vožnjo ni dosegel obratovalne temperature — poraba goriva je bila višja kot običajno.';

  @override
  String get trajetDetailChartEmpty => 'Ni zabeleženih vzorcev';

  @override
  String get trajetDetailChartEstimatedBadge => 'ocenjeno';

  @override
  String get trajetDetailShareAction => 'Deli';

  @override
  String get trajetDetailShareImageOption => 'Deli sliko';

  @override
  String get trajetDetailShareGpxOption => 'Deli GPS sled (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Brez GPS podatkov na tej vožnji';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — vožnja dne $date';
  }

  @override
  String get trajetDetailShareError =>
      'Ni bilo mogoče ustvariti slike za deljenje';

  @override
  String get trajetDetailDownloadCsvOption => 'Prenesi telemetrijo (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Prenesi telemetrijo (JSON)';

  @override
  String get trajetDetailDownloadError => 'Datoteke ni bilo mogoče shraniti';

  @override
  String get trajetDetailDeleteAction => 'Izbriši';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Izbrisati to vožnjo?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ta vožnja bo trajno odstranjena iz vaše zgodovine.';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Izbriši';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adapter OBD2 je povezan, a ne vrača podatkov. Poskusite z drugim adapterjem ali preverite diagnostični protokol vozila.';

  @override
  String get trajetsViewAllOnMap => 'Prikaži vse na zemljevidu';

  @override
  String get trajetsMapTitle => 'Vožnje na zemljevidu';

  @override
  String get trajetsMapShareGpx => 'Deli GPX';

  @override
  String get trajetsMapEmpty => 'Nobena od izbranih voženj nima GPS podatkov.';

  @override
  String get trajetsMapShareError => 'Datoteke GPX ni bilo mogoče deliti';

  @override
  String get trajetDetailChartBoost => 'Polnilni tlak (MAP − okolica)';

  @override
  String get trajetDetailChartIat => 'Temperatura vstopnega zraka';

  @override
  String get trajetDetailChartTiming => 'Predvžig';

  @override
  String get trajetObd2Degraded =>
      'Začeto z adapterjem OBD2, a posneto pretežno z GPS — podatki motorja so nepopolni';

  @override
  String get tripLengthCardTitle => 'Poraba glede na dolžino vožnje';

  @override
  String get tripLengthBucketShort => 'Kratka (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Srednja (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Dolga (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Potrebnih je več podatkov';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voženj',
      one: '1 vožnja',
      zero: 'ni voženj',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Pot vožnje';

  @override
  String get tripPathCardSubtitle => 'Z GPS posneta pot';

  @override
  String get tripPathLegendEfficient => 'Učinkovito (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Mejno (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Potratno (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar bencinski servis';

  @override
  String get tripRadarScanning => 'Iskanje bližnjih postaj';

  @override
  String get tripRadarNoStationNearby => 'Ni bližnje postaje';

  @override
  String get fuelStationRadarNearer => 'Bližja postaja';

  @override
  String get fuelStationRadarFarther => 'Daljnja postaja';

  @override
  String get fuelStationRadarStart => 'Zaženi radar bencinski servis';

  @override
  String get stopRadar => 'Ustavi radar';

  @override
  String get fuelStationRadarResultBadge => 'Rezultat radarja bencinski servis';

  @override
  String get radarUpdatingLocation => 'Posodabljanje vaše lokacije…';

  @override
  String get radarSearching => 'Iskanje…';

  @override
  String get highwayModeChip =>
      'Avtocestni način — prikazuje postaje pred vami na poti';

  @override
  String get tripRecordingPinTooltip =>
      'Priklepanje ohranja zaslon vklopljen — porablja več baterije';

  @override
  String get tripRecordingPinSemanticOn => 'Odkleni obrazec snemanja';

  @override
  String get tripRecordingPinSemanticOff => 'Prikleni obrazec snemanja';

  @override
  String get tripRecordingPinHelpTooltip => 'Kaj naredi priklepanje?';

  @override
  String get tripRecordingPinHelpTitle => 'O priklepanju';

  @override
  String get tripRecordingPinHelpBody =>
      'Priklepanje ohranja zaslon vklopljen in skrije sistemske vrstice, da obrazec ostane berljiv na armaturni plošči. Tapnite znova za sprostitev. Samodejno se sprosti ob ustavitvi vožnje.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Snemanje se nadaljuje v ozadju. Tapnite rdeči pasico na vrhu katerega koli zaslona za vrnitev.';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Prikleni zaslon za ohranitev GPS-a med vožnjo — Android lahko med spanjem omeji GPS.';

  @override
  String get tripRecordingMinimiseTooltip => 'Pomanjšaj v lebdečo ploščico';

  @override
  String get tripRecordingAutoPinTitle => 'Ob začetku snemanja vedno pripni';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Obrazec samodejno pripni ob vsaki vožnji namesto dotika vsakič. Porabi več baterije.';

  @override
  String get tripRecordingConnectingTitle => 'Začenjanje snemanja…';

  @override
  String get tripRecordingSavingTitle => 'Shranjevanje vožnje…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Snemanje zavrnjeno — ni zaznanega gibanja';

  @override
  String get tripRecordingGpsNotificationTitle => 'Snemanje vaše vožnje';

  @override
  String get tripRecordingGpsNotificationText =>
      'Sledenje vaši poti za statistiko goriva in vožnje';

  @override
  String get tripShareAction => 'Deli z drugim računom';

  @override
  String get tripShareSheetTitle => 'Deli to vožnjo';

  @override
  String get tripShareSheetSubtitle =>
      'Drugemu računu TankSync dajte dostop samo za branje do te zabeležene vožnje.';

  @override
  String get tripShareEmailLabel => 'E-pošta prejemnika';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Deli';

  @override
  String get tripShareCreateLinkButton => 'Ustvari povezavo za deljenje';

  @override
  String get tripShareLinkCreated =>
      'Povezava za deljenje kopirana — prilepite jo prejemniku.';

  @override
  String get tripShareSuccess => 'Vožnja deljena.';

  @override
  String get tripShareRecipientNotFound =>
      'Noben račun TankSync ne uporablja tega e-naslova.';

  @override
  String get tripShareError => 'Vožnje ni bilo mogoče deliti. Poskusite znova.';

  @override
  String get tripShareExistingTitle => 'Deljeno z';

  @override
  String get tripShareExistingEmpty => 'Še ni deljeno z nikomer.';

  @override
  String get tripShareDirectRecipient => 'Račun';

  @override
  String get tripShareLinkRecipient => 'Povezava za deljenje (neprevzeta)';

  @override
  String get tripShareRevokeTooltip => 'Prekliči';

  @override
  String get tripShareRevoked => 'Deljenje preklicano.';

  @override
  String get trajetsSharedSectionTitle => 'Deljeno z mano';

  @override
  String get trajetsSharedBadge => 'Deljeno';

  @override
  String get tripVerdictPromptTitle => 'Kakšna je bila ta vožnja?';

  @override
  String get tripVerdictSmooth => 'Gladka';

  @override
  String get tripVerdictModerate => 'Zmerna';

  @override
  String get tripVerdictAggressive => 'Agresivna';

  @override
  String get tripVerdictDismiss => 'Ne zdaj';

  @override
  String get tripVerdictThanks =>
      'Hvala — to pomaga umeriti analizo vaše vožnje.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Točenje izbrisano';

  @override
  String get trajetDeletedUndoSnackbar => 'Posnetek izbrisan';

  @override
  String get searchFailedSnackbar => 'Iskanje ni uspelo — poskusite znova';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postaj',
      one: '1 postaja',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Posodobljeno $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Tudi: $names';
  }

  @override
  String get favoriteAdd => 'Dodaj med priljubljene';

  @override
  String get favoriteRemove => 'Odstrani iz priljubljenih';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Surova: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Postaja brez blagovne znamke';

  @override
  String get unsupportedRegionTitle => 'V vaši regiji še ni na voljo';

  @override
  String get unsupportedRegionBody =>
      'Za vašo državo še nimamo cen goriva, zato so rezultati lahko prazni ali iz druge države. Kljub temu lahko v nastavitvah iskanja izberete podprto državo.';

  @override
  String get unsupportedRegionDismiss => 'Razumem';

  @override
  String get configureCountryTitle => 'Nastavite svojo državo';

  @override
  String get configureCountryBody =>
      'Vaša država je podprta, a še ni nastavljena — cene so zato lahko iz druge države. Izberite svojo državo v nastavitvah iskanja, da vidite lokalne cene.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Morda točim različne vrste goriva';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Spremlja, katero gorivo je najcenejše na kilometer';

  @override
  String get vinLabel => 'VIN (neobvezno)';

  @override
  String get vinDecodeTooltip => 'Dekodiraj VIN';

  @override
  String get vinConfirmAction => 'Da, samodejno izpolni';

  @override
  String get vinModifyAction => 'Uredi ročno';

  @override
  String get veResetAction => 'Ponastavi volumetrično učinkovitost';

  @override
  String get vehicleReadVinFromCarButton => 'Preberi VIN iz vozila';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Preberi VIN s sparanega adapterja OBD2';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN ni na voljo (Mode 09 PID 02 ni podprt pri vozilih pred 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Branje VIN ni uspelo — prosimo, vnesite ročno';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Najprej sparajte adapter OBD2 za samodejno branje VIN';

  @override
  String get pickerButtonLabel => 'Izberi iz kataloga';

  @override
  String get pickerSearchHint => 'Iščite znamko ali model';

  @override
  String get pickerHelpText => 'Predizpolnite iz 50+ podprtih vozil';

  @override
  String get pickerEmptyResults => 'Ni zadetkov';

  @override
  String get pickerCancel => 'Prekliči';

  @override
  String get pickerLoading => 'Nalaganje kataloga…';

  @override
  String get vinInfoTooltip => 'Kaj je VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Kaj je VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Identifikacijska številka vozila je 17-mestna koda, edinstvena za vaše vozilo. Vtisnjena je na šasijo in natisnjena na prometnem dovoljenju.';

  @override
  String get vinInfoSectionWhyTitle => 'Zakaj to sprašujemo';

  @override
  String get vinInfoSectionWhyBody =>
      'Dekodiranje VIN samodejno izpolni prostornino motorja, število valjev, letnik, vrsto goriva in skupno maso — prihranek pri iskanju tehničnih specifikacij. Izračun pretoka goriva OBD2 te vrednosti uporabi za natančne podatke o porabi.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Zasebnost';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Vaš VIN je shranjen samo lokalno v šifrirani shrambi aplikacije — nikoli ni naložen na strežnike Sparkilo. Baza podatkov NHTSA vPIC se poizveduje z VIN, a vrača samo anonimne tehnične specifikacije; NHTSA VIN ne poveže z osebnimi podatki. Brez omrežja brezspletna poizvedba vrne samo proizvajalca in državo.';

  @override
  String get vinInfoSectionWhereTitle => 'Kje ga najti';

  @override
  String get vinInfoSectionWhereBody =>
      'Poglejte skozi vetrobransko steklo v spodnji levi kot na strani voznika, preverite nalepko v okvirju vrat na strani voznika, ko so vrata odprta, ali ga preberite s prometnega dovoljenja (kartica / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Razumem';

  @override
  String get vinConfirmPrivacyNote =>
      'Vaš VIN smo poiskali v brezplačni bazi vozil NHTSA — nič ni bilo poslano strežnikom Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Spletno dekodiranje VIN';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekodirajte VIN prek brezplačne javne storitve NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Ko sparite adapter, se VIN vašega vozila prebere lokalno za identifikacijo vozila. Omogočanje tega pošlje 17-mestni VIN storitvi NHTSA vPIC za iskanje dodatnih podrobnosti (model, prostornina motorja, vrsta goriva). VIN je edini poslani podatek — nobeni drugi podatki ne zapustijo naprave.';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Zaznano iz VIN: $summary. Uporabiti?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Uporabi';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometrov naprej, $fuelType $euros evrov $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Pripomoček za domači zaslon';

  @override
  String get widgetHelpIntro =>
      'Dodajte pripomoček SparKilo na domači zaslon za hiter pregled cen goriva in polnjenja.';

  @override
  String get widgetHelpAdd =>
      'Dodajte ga iz izbirnika pripomočkov zaganjalnika — dolgo pritisnite prazno območje domačega zaslona, izberite Pripomočki in poiščite SparKilo.';

  @override
  String get widgetHelpTap =>
      'Tapnite postajo v pripomočku za odpiranje v aplikaciji. Tapnite ikono za osvežitev za posodobitev cen.';

  @override
  String get widgetHelpConfigure =>
      'Na Androidu dolgo pritisnite pripomoček in izberite Konfiguriraj za spremembo profila, barve in vsebine.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Spodnje izbire veljajo za vsak nameščen pripomoček ob naslednji osvežitvi.';

  @override
  String get widgetDefaultsColorLabel => 'Barvna shema';

  @override
  String get widgetDefaultsVariantLabel => 'Različica vsebine';

  @override
  String get widgetColorSchemeSystem => 'Sledi sistemu';

  @override
  String get widgetColorSchemeLight => 'Svetla';

  @override
  String get widgetColorSchemeDark => 'Temna';

  @override
  String get widgetColorSchemeBlue => 'Modra';

  @override
  String get widgetColorSchemeGreen => 'Zelena';

  @override
  String get widgetColorSchemeOrange => 'Oranžna';

  @override
  String get widgetVariantDefault => 'Samo trenutna cena';

  @override
  String get widgetVariantPredictive => 'Napovedno: najboljši čas za polnjenje';
}
