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
  String get searchButton => 'Iskanje';

  @override
  String get fabOpenCriteria => 'Odpri iskanje';

  @override
  String get fabOpenResults => 'Odpri rezultate';

  @override
  String get fabRunSearch => 'Zaženi iskanje';

  @override
  String get fabRefineCriteria => 'Izboljšaj iskanje';

  @override
  String get routeSearchPartialBanner => 'Iskanje dodatnih postaj…';

  @override
  String get routeSearchingChip => 'Iskanje poti…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Vsakih $km km';
  }

  @override
  String get searchCriteriaTitle => 'Merila iskanja';

  @override
  String get searchCriteriaOpen => 'Iskanje';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'V $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tapnite za začetek iskanja';

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
  String get apiKeyDescription =>
      'Registrirajte se enkrat za brezplačni API ključ.';

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
  String get demoMode => 'Demo način — prikazani so vzorčni podatki.';

  @override
  String get setupLiveData => 'Nastavitev za žive podatke';

  @override
  String get freeNoKey => 'Brezplačno — ključ ni potreben';

  @override
  String get apiKeyRequired => 'Potreben API ključ';

  @override
  String get skipWithoutKey => 'Nadaljuj brez ključa';

  @override
  String get dataTransparency => 'Preglednost podatkov';

  @override
  String get storageAndCache => 'Shramba in predpomnilnik';

  @override
  String get clearCache => 'Počisti predpomnilnik';

  @override
  String get clearAllData => 'Izbriši vse podatke';

  @override
  String get errorLog => 'Dnevnik napak';

  @override
  String stationsFound(int count) {
    return 'Najdenih $count postaj';
  }

  @override
  String get whatIsShared => 'Kaj se deli — in s kom?';

  @override
  String get gpsCoordinates => 'GPS koordinate';

  @override
  String get gpsReason =>
      'Pošljejo se z vsakim iskanjem za iskanje bližnjih postaj.';

  @override
  String get postalCodeData => 'Poštna številka';

  @override
  String get postalReason =>
      'Pretvori se v koordinate prek geokodirne storitve.';

  @override
  String get mapViewport => 'Prikaz zemljevida';

  @override
  String get mapReason =>
      'Ploščice zemljevida se naložijo s strežnika. Osebni podatki se ne prenašajo.';

  @override
  String get apiKeyData => 'API ključ';

  @override
  String get apiKeyReason =>
      'Vaš osebni ključ se pošlje z vsako API zahtevo. Povezan je z vašim e-naslovom.';

  @override
  String get notShared => 'SE NE deli:';

  @override
  String get searchHistory => 'Zgodovina iskanja';

  @override
  String get favoritesData => 'Priljubljene';

  @override
  String get profileNames => 'Imena profilov';

  @override
  String get homeZipData => 'Domača poštna številka';

  @override
  String get usageData => 'Podatki o uporabi';

  @override
  String get privacyBanner =>
      'Ta aplikacija nima strežnika. Vsi podatki ostanejo na vaši napravi. Brez analitike, sledenja ali oglasov.';

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
  String get noStorage => 'Ni uporabljene shrambe';

  @override
  String get apiKeyNote =>
      'Brezplačna registracija. Podatki od vladnih agencij za cenovno preglednost.';

  @override
  String get apiKeyFormatError =>
      'Neveljavna oblika — pričakovan UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Podprite ta projekt';

  @override
  String get supportDescription =>
      'Ta aplikacija je brezplačna, odprtokodna in brez oglasov. Če jo smatrate za koristno, razmislite o podpori razvijalcu.';

  @override
  String get reportBug => 'Prijavi napako / Predlagaj funkcijo';

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
  String get configApiKeyNotSet => 'Ni nastavljeno (demo način)';

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
  String stationsOnMap(int count) {
    return '$count postaj';
  }

  @override
  String get loadingFavorites =>
      'Nalaganje priljubljenih...\nNajprej poiščite postaje za shranjevanje podatkov.';

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
  String get routeModeBannerLabel =>
      'Način poti — razdalje so vzdolž koridorja';

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
  String get searchAlongRouteLabel => 'Vzdolž poti';

  @override
  String get searchEvStations => 'Iskanje polnilnih postaj';

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
  String stopN(int n) {
    return 'Postanek $n';
  }

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
  String get requiredForEvSearch => 'Potrebno za iskanje EV polnilnih postaj';

  @override
  String get edit => 'Uredi';

  @override
  String get fuelPricesApiKey => 'API ključ cen goriv';

  @override
  String get tankerkoenigApiKey => 'API ključ Tankerkoenig';

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
  String get consumptionL100km => 'Poraba (L/100km)';

  @override
  String get fuelPriceEurL => 'Cena goriva (EUR/L)';

  @override
  String get tripCost => 'Stroški potovanja';

  @override
  String get fuelNeeded => 'Potrebno gorivo';

  @override
  String get totalCost => 'Skupni stroški';

  @override
  String get enterCalcValues =>
      'Vnesite razdaljo, porabo in ceno za izračun stroškov potovanja';

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
  String get dataDeletionNotAvailableCommunity =>
      'Brisanje podatkov v skupnostnem načinu ni na voljo. Najprej se odjavite ali uporabite zasebno bazo podatkov.';

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
  String get noHourlyData => 'Ni urnih podatkov';

  @override
  String get noStatistics => 'Ni razpoložljivih statistik';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Povp';

  @override
  String get showAllFuelTypes => 'Prikaži vse vrste goriv';

  @override
  String get connected => 'Povezano';

  @override
  String get notConnected => 'Ni povezano';

  @override
  String get connectTankSync => 'Poveži TankSync';

  @override
  String get disconnectTankSync => 'Prekini TankSync';

  @override
  String get viewMyData => 'Ogled mojih podatkov';

  @override
  String get optionalCloudSync =>
      'Neobvezna oblačna sinhronizacija za opozorila, priljubljene in push obvestila';

  @override
  String get tapToUpdateGps => 'Tapnite za posodobitev GPS pozicije';

  @override
  String get gpsAutoUpdateHint =>
      'GPS pozicija se samodejno pridobi ob iskanju. Tukaj jo lahko tudi ročno posodobite.';

  @override
  String get clearGpsConfirm =>
      'Počistiti shranjeno GPS pozicijo? Kadar koli jo lahko znova posodobite.';

  @override
  String get pageNotFound => 'Stran ni najdena';

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
  String get disconnectConfirm => 'Prekiniti TankSync?';

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
  String get upgradeToEmail => 'Ustvari e-poštni račun';

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
  String crossBorderNearby(String country) {
    return '$country je blizu';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km do meje';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Povpr. tukaj: $price EUR ($count postaj)';
  }

  @override
  String get allPricesView => 'Vse cene';

  @override
  String get compactView => 'Kompaktno';

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
  String get gdprAcceptAll => 'Sprejmi vse';

  @override
  String get gdprAcceptSelected => 'Sprejmi izbrano';

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
  String get topicUrlCopied => 'URL teme kopiran';

  @override
  String get testNotificationSent => 'Testno obvestilo poslano!';

  @override
  String get testNotificationFailed =>
      'Pošiljanje testnega obvestila ni uspelo';

  @override
  String get pushUpdateFailed =>
      'Posodobitev nastavitve potisnih obvestil ni uspela';

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
  String privacyCopyErrorLog(int count) {
    return 'Kopiraj dnevnik napak v odložišče ($count)';
  }

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
  String voiceAnnouncementThreshold(String price) {
    return 'Samo pod $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometrov naprej, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Polmer obvestil';

  @override
  String get voiceAnnouncementCooldown => 'Interval ponavljanja';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximum price';

  @override
  String get nearestStations => 'Najblizje postaje';

  @override
  String get nearestStationsHint =>
      'Poiscite najblizje postaje z vaso trenutno lokacijo';

  @override
  String get consumptionLogTitle => 'Poraba goriva';

  @override
  String get consumptionLogMenuTitle => 'Dnevnik porabe';

  @override
  String get consumptionLogMenuSubtitle =>
      'Sledite polnjenjem in izračunajte L/100km';

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
  String get fillUpVehicleNone => 'Brez vozila';

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
  String get scanPump => 'Skeniraj črpalko';

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
  String get obdNoAdapter => 'V dosegu ni adapterja OBD2';

  @override
  String get obdOdometerUnavailable => 'Števca ni bilo mogoče prebrati';

  @override
  String get obdPermissionDenied =>
      'Dovolite Bluetooth v sistemskih nastavitvah';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter se ni odzval — vklopite vžig in poskusite znova';

  @override
  String get obdPickerTitle => 'Izberite adapter OBD2';

  @override
  String get obdPickerScanning => 'Iskanje adapterjev…';

  @override
  String get obdPickerConnecting => 'Povezovanje…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Svetla';

  @override
  String get themeModeDark => 'Temna';

  @override
  String get themeModeSystem => 'Sledi sistemu';

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
  String get obd2StatusAttempting => 'Adapter OBD2: povezovanje';

  @override
  String get obd2StatusUnreachable => 'Adapter OBD2: nedosegljiv';

  @override
  String get obd2StatusPermissionDenied =>
      'Adapter OBD2: potrebno je dovoljenje za Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Pripravljen za snemanje vožnje.';

  @override
  String get obd2StatusAttemptingBody => 'Povezovanje v ozadju…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter je izven dosega ali ga že uporablja druga aplikacija.';

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
  String get tripHistoryEmptySubtitle =>
      'Povežite adapter OBD2 in posnemite vožnjo za začetek gradnje zgodovine vožnje.';

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
  String get tripSaveAsFillUp => 'Shrani kot polnjenje';

  @override
  String get tripSaveRecording => 'Shrani vožnjo';

  @override
  String get tripDiscard => 'Zavrzi';

  @override
  String obdOdometerRead(int km) {
    return 'Prebran števec: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Ni nastavljeno';

  @override
  String get wizardVehicleTapToEdit => 'Tapnite za urejanje';

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
  String get wizardProfileCustomDescription =>
      'Vaša kombinacija funkcij. Prilagodite vsak preklop spodaj.';

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
  String get vehiclePowerLabel => 'Engine power (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps PS';
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
  String get evMaxPower => 'Maks moč';

  @override
  String get evOperator => 'Operater';

  @override
  String get evLastUpdate => 'Zadnja posodobitev';

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
  String get profileNotFound => 'Ni aktivnega profila';

  @override
  String get updatingFavorites => 'Posodabljanje priljubljenih...';

  @override
  String get fetchingLatestPrices => 'Pridobivanje najnovejših cen';

  @override
  String get noDataAvailable => 'Ni podatkov';

  @override
  String get configAndPrivacy => 'Konfiguracija in zasebnost';

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
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Gorivo';

  @override
  String get stationTypeEv => 'EV';

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
  String get alertsBackgroundCheckErrorTitle =>
      'Preverjanje opozoril v ozadju ni uspelo';

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
      'Your TankSync schema is outdated — re-run the setup SQL below to enable the latest synced features.';

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
      'Delite priljubljene in ocene z vsemi uporabniki';

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
  String get evChargingSection => 'Polnjenje EV';

  @override
  String get fuelStationsSection => 'Bencinske postaje';

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
  String get luxembourgRegulatedPricesNotice =>
      'Cene goriva v Luksemburgu so državno regulirane in enotne po vsej državi.';

  @override
  String get luxembourgFuelUnleaded95 => 'Neosvinčeni 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Neosvinčeni 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Regulirane cene goriva v Luksemburgu niso na voljo.';

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
  String get southKoreaApiKeyRequired =>
      'Registrirajte se na OPINET za brezplačni ključ API';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registrirajte se na CNE za brezplačni ključ API';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

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
      'Recording with GPS — waiting for the OBD2 adapter';

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
  String get alertsRadiusThreshold => 'Prag (€/L)';

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
  String get alertsRadiusDeleteConfirm => 'Izbrisati polmerno opozorilo?';

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
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel padlo pri bližnjih postajah';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount postaj je v zadnji uri padlo za do $maxDropCents¢';
  }

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
      'No data from the vehicle — start the engine and try again.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Vmesnik OBD2 je poslal neprepoznan odgovor. Morda ni združljiv — poskusite z drugim vmesnikom.';

  @override
  String get obd2ErrorDisconnected =>
      'Vmesnik OBD2 je prekinil povezavo. Znova se povežite in poskusite znova.';

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
  String approachStationDistance(String meters) {
    return '$meters m oddaljeno';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return '$km km stran';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Bližina $percent%';
  }

  @override
  String get pipTapToRestore => 'Tap to open the full app';

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
  String get autoRecordPairedAdapterLabel => 'Sparani adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Ni sparanega adapterja. Najprej sparajte enega prek uvajanja OBD2.';

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
  String get autoRecordBadgeClearTooltip => 'Ponastavi števec';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Sparajte adapter v spodnjem razdelku za omogočanje samodejnega snemanja';

  @override
  String get exportBackupTooltip => 'Izvozi varnostno kopijo';

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
  String get restoreBackupTooltip => 'Obnovi varnostno kopijo';

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
  String restoreBackupSuccess(int count) {
    return 'Varnostna kopija obnovljena — uvoženih $count zapisov';
  }

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
  String get brokenMapChipVerifying => 'Preverjanje senzorja MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Odčitki MAP so sumljivi';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Senzor MAP bere nepravilno — odčitki goriva so lahko 50–80 % prenizki. Poskusite z drugim adapterjem.';

  @override
  String get brokenMapBannerHardDisable =>
      'Senzor MAP ni zanesljiv. Prikazujejo se povprečja polnjenj namesto živega pretoka goriva.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Senzor MAP: preverjen ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Senzor MAP: preverjanje ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Senzor MAP: sumljiv ($confidence)';
  }

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
      'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vaš $makeModel je označen kot diesel, a se ujema z bencin. vnosom v katalogu. Tapnite za posodobitev.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Posodobi';

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
  String get chargingChartsMonthAxis => 'Mesec';

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
  String get greeceApiProvider => 'Paratiritirio Timon (Grčija)';

  @override
  String get greeceCommunityApiNotice =>
      'Deluje na skupnostno vzdrževanem API fuelpricesgr';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romunija)';

  @override
  String get romaniaScrapingNotice =>
      'Deluje na pretcarburant.ro (Svet za konkurenco + ANPC)';

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
  String get ecoRouteOption => 'Eko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L prihrankov';
  }

  @override
  String get ecoRouteHint =>
      'Pametnejša vožnja — prednost ima stalna avtocesta pred ovinkastimi bližnjicami.';

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
  String get featureLabel_unifiedSearchResults => 'Enotni rezultati iskanja';

  @override
  String get featureDescription_unifiedSearchResults =>
      'En seznam rezultatov z gorivo in EV postajami skupaj.';

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
  String get featureBlockedEnable_showFuel => 'Predpogoji niso izpolnjeni';

  @override
  String get featureBlockedEnable_showElectric => 'Predpogoji niso izpolnjeni';

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
  String get featureLabel_addFillUpOcrPump =>
      'OCR zaslona črpalke (eksperimentalno)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Skenirajte zaslon točilne črpalke za vnaprejšnje izpolnjevanje obrazca. Prepoznavanje je danes nezanesljivo — vklopite samo, če želite preizkusiti.';

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
      'This vehicle can use different fuels — log the one you actually pumped';

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
  String get scanPumpUnreadable =>
      'Zaslon črpalke ni berljiv — poskusite znova';

  @override
  String get scanPumpSuccess =>
      'Zaslon črpalke skeniran — preverite vrednosti.';

  @override
  String get scanPumpGlare =>
      'Preveč bleščanja na zaslonu — poskusite znova pod rahlim kotom, da številke ne bodo presvetljene.';

  @override
  String get scanPumpInconsistent =>
      'Skenirane vrednosti se ne ujemajo — vnesite jih ročno.';

  @override
  String scanPumpFailed(String error) {
    return 'Skeniranje črpalke ni uspelo: $error';
  }

  @override
  String get badScanReportTitle => 'Prijavi napako skeniranja';

  @override
  String get badScanReportTitleReceipt => 'Prijavi napako skeniranja — račun';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Prijavi napako skeniranja — zaslon črpalke';

  @override
  String get pumpScanFailureTitle => 'Zaslon ni berljiv';

  @override
  String get pumpScanFailureBody =>
      'Skeniranje ni moglo prebrati zaslona črpalke. Kaj bi radi naredili?';

  @override
  String get pumpScanFailureCorrectManually => 'Popravi ročno';

  @override
  String get pumpScanFailureReport => 'Prijavi';

  @override
  String get pumpScanFailureRemove => 'Odstrani fotografijo';

  @override
  String get badScanReportHint =>
      'Delili bomo fotografijo računa in oba niza vrednosti, da se naslednja gradnja nauči te postavitve.';

  @override
  String get badScanReportShareAction => 'Deli poročilo + fotografijo';

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
  String get pumpCameraHint =>
      'Poravnajte tri številke z zaslona točilne naprave znotraj okvira';

  @override
  String get pumpCameraCapture => 'Zajemi';

  @override
  String get pumpCameraPermissionDenied =>
      'Za optično branje zaslona točilne naprave je potreben dostop do kamere. Omogočite ga v nastavitvah naprave.';

  @override
  String get pumpCameraError =>
      'Kamere ni bilo mogoče zagnati. Poskusite znova ali vnesite vrednosti ročno.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Preklopi na vodoravno postavitev';

  @override
  String get pumpCameraOrientationVertical => 'Preklopi na navpično postavitev';

  @override
  String get pumpCameraGlareWarning =>
      'Preveč odbleska — rahlo nagnite, da se izognete odsevom';

  @override
  String get pumpCameraAlignHint =>
      'Poravnajte zaslon v okvir in nato posnemite';

  @override
  String get pumpCameraRotateToLandscape =>
      'Obrnite telefon vstran — zaslon črpalke je širok, zato so številke večje in pokončne';

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
  String get fillUpSectionWhatTitle => 'Kaj ste natočili';

  @override
  String get fillUpSectionWhatSubtitle => 'Gorivo, količina, cena';

  @override
  String get fillUpSectionWhereTitle => 'Kje ste bili';

  @override
  String get fillUpSectionWhereSubtitle => 'Postaja, števec km, opombe';

  @override
  String get fillUpImportFromLabel => 'Uvozi iz…';

  @override
  String get fillUpImportSheetTitle => 'Uvozi podatke o polnjenju';

  @override
  String get fillUpImportReceiptLabel => 'Račun';

  @override
  String get fillUpImportReceiptDescription =>
      'Skenirajte papirni račun s kamero';

  @override
  String get fillUpImportPumpLabel => 'Zaslon črpalke';

  @override
  String get fillUpImportPumpDescription =>
      'Preberi Betrag / Preis z LCD zaslona črpalke';

  @override
  String get fillUpImportObdLabel => 'Adapter OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Preberi števec km prek priključka OBD-II prek Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Cena na liter';

  @override
  String get vehicleHeaderPlateLabel => 'Registrska tablica';

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
  String get coachingGpsLiftOff => 'Spusti plin';

  @override
  String get coachingGpsAnticipateBrake => 'Predvidi';

  @override
  String get coachingGpsSmoothAccel => 'Gladko pospeševanje';

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
  String get hapticEcoCoachSectionTitle => 'Vožnja';

  @override
  String get hapticEcoCoachSettingTitle => 'Eko coaching v realnem času';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Blag haptičen odziv + sporočilo na zaslonu, ko med vožnjo pritisnete na plin';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Nežno s plinom — drsenje prihrani več';

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
  String get routeStrategyLabel => 'Strategija:';

  @override
  String get routeStrategyUniform => 'Enakomerno';

  @override
  String get routeStrategyBalanced => 'Uravnoteženo';

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
  String get consentSyncTripsNeedsEmailHint =>
      'Prijavite se z e-poštnim računom za sinhronizacijo voženj med napravami.';

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
  String get locationConsentDecline => 'Zavrni';

  @override
  String get locationConsentAccept => 'Sprejmi';

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
  String get obd2HealthCopyInitTranscript =>
      'Kopiraj samo prepis inicializacije';

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
  String get obd2HealthCopyJson => 'Kopiraj kot JSON';

  @override
  String get obd2HealthCopied => 'Diagnostika OBD2 kopirana v odložišče.';

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
  String get obd2TestRunTitle => 'Zaženi test adapterja';

  @override
  String get obd2TestRunButton => 'Zaženi test adapterja';

  @override
  String get obd2TestRunPassed => 'Test adapterja je uspel';

  @override
  String get obd2TestRunFailed => 'Test adapterja ni uspel';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — engine off; start the engine to read live data';

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
  String get obd2TestStepConnect => 'Poveži in inicializiraj';

  @override
  String get obd2TestStepInfo => 'Informacije o adapterju';

  @override
  String get obd2TestStepSupportedPids => 'Podprti PID';

  @override
  String get obd2TestStepSampleReads => 'Vzorčna branja';

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
    return 'Ni bilo mogoče doseči \'$adapterName\' — izberite drug adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Other Bluetooth devices';

  @override
  String get obd2PickerTapToTry => 'Unrecognized — tap to try';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone works with Bluetooth-LE adapters only. A Classic-only adapter (e.g. vLinker BM, Konnwei KW902) must be used on Android.';

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
  String get ocrTesterTitle => 'Tester OCR';

  @override
  String get ocrTesterNavLabel => 'Tester OCR';

  @override
  String get ocrTesterExplain =>
      'Zaženite cevovod OCR za črpalko/račun na izbrani fotografiji in preglejte vsak korak — na voljo le v načinu za razvijalce.';

  @override
  String get ocrTesterModePump => 'Črpalka';

  @override
  String get ocrTesterModeReceipt => 'Račun';

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
  String get ocrTesterNoResult => 'OCR ni vrnil berljivega rezultata.';

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
  String get ocrTesterSaveFixture => 'Shrani kot fiksacijo';

  @override
  String get ocrTesterFixtureSaved =>
      'Fiksacija shranjena v mapo Prenosi. Premaknite jo v test/fixtures in zaženite tool/promote_ocr_fixture.dart.';

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
  String get onboardingObd2VinReadFailed =>
      'VIN ni bilo mogoče prebrati — vnesite ročno';

  @override
  String get onboardingObd2ConnectFailed =>
      'Povezave z adapterjem ni bilo mogoče vzpostaviti. Lahko poskusite znova ali preskočite.';

  @override
  String get onboardingPickUseMode => 'Za nadaljevanje izberite način uporabe.';

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
  String get tripRecordingPipEstConsumptionCaption => 'ocen. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Ocenjena vrednost (~) — na tej vožnji ni tipala za gorivo, zato je vrednost L/100 km modelirana iz hitrosti GPS in kalibracije vašega vozila. Je približna (tipično ±10–30 %, z dozorevanjem kalibracije se natančnost izboljšuje) in ni izmerjena vrednost.';

  @override
  String get tripRecordingPipElapsedCaption => 'preteklo';

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
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel pri $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Postaja je pri $price € (cilj: $threshold €)';
  }

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
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/seja';

  @override
  String get shareReceiptImporting => 'Uvažanje deljenega računa…';

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
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Zadnje polnjenje: $date · $count vožnja(e) od takrat';
  }

  @override
  String get tankLevelMethodObd2 => 'Merjeno z OBD2';

  @override
  String get tankLevelMethodDistanceFallback => 'ocena na podlagi razdalje';

  @override
  String get tankLevelMethodMixed => 'mešano merjenje';

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
  String get trajetDetailChartAltitude => 'Nadmorska višina (m)';

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
  String get trajetDetailDeleteConfirmCancel => 'Prekliči';

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
  String get tripPathLegendTitle => 'Poraba';

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
  String get tripBannerOpenFromConsumptionTab =>
      'Odpri aktivno vožnjo iz zavihka Poraba';

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
  String get unifiedFilterFuel => 'Gorivo';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Oboje';

  @override
  String get unifiedNoResultsForFilter =>
      'Nobeni rezultati ne ustrezajo temu filtru';

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
  String get stationUnbrandedTitle => 'Unbranded station';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'I may fill up with different fuel types';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Tracks which fuel is cheapest per kilometre';

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
  String get vehicleDetectedFromVinBadge => '(zaznano)';

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

  @override
  String get widgetPredictiveNowPrefix => 'zdaj';
}
