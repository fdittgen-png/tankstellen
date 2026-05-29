// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Căutare';

  @override
  String get favorites => 'Favorite';

  @override
  String get map => 'Hartă';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Setări';

  @override
  String get gpsLocation => 'Locație GPS';

  @override
  String get zipCode => 'Cod poștal';

  @override
  String get zipCodeHint => 'ex. 010001';

  @override
  String get fuelType => 'Carburant';

  @override
  String get searchRadius => 'Rază';

  @override
  String get searchNearby => 'Benzinării în apropiere';

  @override
  String get searchButton => 'Caută';

  @override
  String get fabOpenCriteria => 'Deschide căutarea';

  @override
  String get fabOpenResults => 'Deschide rezultatele';

  @override
  String get fabRunSearch => 'Execută căutarea';

  @override
  String get fabRefineCriteria => 'Rafinează căutarea';

  @override
  String get routeSearchPartialBanner => 'Se caută mai multe stații…';

  @override
  String get searchCriteriaTitle => 'Criterii de căutare';

  @override
  String get searchCriteriaOpen => 'Căutare';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'În raza de $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Apăsați pentru a căuta';

  @override
  String get noResults => 'Nu s-au găsit benzinării.';

  @override
  String get startSearch => 'Căutați pentru a găsi benzinării.';

  @override
  String get open => 'Deschis';

  @override
  String get closed => 'Închis';

  @override
  String distance(String distance) {
    return 'la $distance';
  }

  @override
  String get price => 'Preț';

  @override
  String get prices => 'Prețuri';

  @override
  String get address => 'Adresă';

  @override
  String get openingHours => 'Program';

  @override
  String get open24h => 'Deschis 24 de ore';

  @override
  String get navigate => 'Navigare';

  @override
  String get retry => 'Reîncearcă';

  @override
  String get apiKeySetup => 'Cheie API';

  @override
  String get apiKeyDescription =>
      'Înregistrați-vă o dată pentru o cheie API gratuită.';

  @override
  String get apiKeyLabel => 'Cheie API';

  @override
  String get register => 'Înregistrare';

  @override
  String get continueButton => 'Continuă';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle =>
      'Găsiți cel mai ieftin carburant în apropierea dvs.';

  @override
  String get profileName => 'Numele profilului';

  @override
  String get preferredFuel => 'Carburant preferat';

  @override
  String get defaultRadius => 'Rază implicită';

  @override
  String get landingScreen => 'Ecran de pornire';

  @override
  String get homeZip => 'Cod poștal de acasă';

  @override
  String get newProfile => 'Profil nou';

  @override
  String get editProfile => 'Editare profil';

  @override
  String get save => 'Salvează';

  @override
  String get cancel => 'Anulează';

  @override
  String get countryChangeTitle => 'Schimbați țara?';

  @override
  String countryChangeBody(String country) {
    return 'Trecerea la $country va modifica:';
  }

  @override
  String get countryChangeCurrency => 'Moneda';

  @override
  String get countryChangeDistance => 'Distanța';

  @override
  String get countryChangeVolume => 'Volumul';

  @override
  String get countryChangePricePerUnit => 'Formatul prețului';

  @override
  String get countryChangeNote =>
      'Favoritele și jurnalele de alimentare existente nu sunt rescrise; doar intrările noi vor folosi noile unități.';

  @override
  String get countryChangeConfirm => 'Schimbați';

  @override
  String get delete => 'Șterge';

  @override
  String get activate => 'Activează';

  @override
  String get configured => 'Configurat';

  @override
  String get notConfigured => 'Neconfigurat';

  @override
  String get about => 'Despre';

  @override
  String get openSource => 'Open Source (Licență MIT)';

  @override
  String get sourceCode => 'Cod sursă pe GitHub';

  @override
  String get noFavorites => 'Fără favorite';

  @override
  String get noFavoritesHint =>
      'Atingeți steaua la o benzinărie pentru a o salva ca favorită.';

  @override
  String get language => 'Limbă';

  @override
  String get country => 'Țară';

  @override
  String get demoMode => 'Mod demo — date exemplu.';

  @override
  String get setupLiveData => 'Configurare date în timp real';

  @override
  String get freeNoKey => 'Gratuit — fără cheie necesară';

  @override
  String get apiKeyRequired => 'Cheie API necesară';

  @override
  String get skipWithoutKey => 'Continuă fără cheie';

  @override
  String get dataTransparency => 'Transparența datelor';

  @override
  String get storageAndCache => 'Stocare și cache';

  @override
  String get clearCache => 'Golește cache';

  @override
  String get clearAllData => 'Șterge toate datele';

  @override
  String get errorLog => 'Jurnal erori';

  @override
  String stationsFound(int count) {
    return '$count benzinării găsite';
  }

  @override
  String get whatIsShared => 'Ce se partajează — și cu cine?';

  @override
  String get gpsCoordinates => 'Coordonate GPS';

  @override
  String get gpsReason =>
      'Trimise la fiecare căutare pentru a găsi benzinării în apropiere.';

  @override
  String get postalCodeData => 'Cod poștal';

  @override
  String get postalReason =>
      'Convertit în coordonate prin serviciul de geocodificare.';

  @override
  String get mapViewport => 'Zona hărții';

  @override
  String get mapReason =>
      'Plăcile hărții sunt încărcate de pe server. Nu se transmit date personale.';

  @override
  String get apiKeyData => 'Cheie API';

  @override
  String get apiKeyReason =>
      'Cheia dvs. personală este trimisă cu fiecare cerere API. Este legată de e-mailul dvs.';

  @override
  String get notShared => 'NU se partajează:';

  @override
  String get searchHistory => 'Istoric căutări';

  @override
  String get favoritesData => 'Favorite';

  @override
  String get profileNames => 'Nume profiluri';

  @override
  String get homeZipData => 'Cod poștal de acasă';

  @override
  String get usageData => 'Date de utilizare';

  @override
  String get privacyBanner =>
      'Această aplicație nu are server. Toate datele rămân pe dispozitivul dvs. Fără analiză, fără urmărire, fără reclame.';

  @override
  String get storageUsage => 'Utilizare stocare pe acest dispozitiv';

  @override
  String get settingsLabel => 'Setări';

  @override
  String get profilesStored => 'profiluri salvate';

  @override
  String get stationsMarked => 'benzinării marcate';

  @override
  String get cachedResponses => 'răspunsuri în cache';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Gestionare cache';

  @override
  String get cacheDescription =>
      'Cache-ul stochează răspunsuri API pentru încărcare mai rapidă și acces offline.';

  @override
  String get cacheTtlGroupNetwork => 'Rețea';

  @override
  String get cacheTtlGroupData => 'Date';

  @override
  String get cacheTtlGroupGeocoding => 'Geocodare';

  @override
  String get stationSearch => 'Căutare benzinării';

  @override
  String get stationDetails => 'Detalii benzinărie';

  @override
  String get priceQuery => 'Interogare prețuri';

  @override
  String get zipGeocoding => 'Geocodificare cod poștal';

  @override
  String minutes(int n) {
    return '$n minute';
  }

  @override
  String hours(int n) {
    return '$n ore';
  }

  @override
  String get clearCacheTitle => 'Golești cache-ul?';

  @override
  String get clearCacheBody =>
      'Rezultatele căutărilor și prețurile din cache vor fi șterse. Profilurile, favoritele și setările sunt păstrate.';

  @override
  String get clearCacheButton => 'Golește cache';

  @override
  String get deleteAllTitle => 'Ștergi toate datele?';

  @override
  String get deleteAllBody =>
      'Aceasta șterge permanent toate profilurile, favoritele, cheia API, setările și cache-ul. Aplicația va fi resetată.';

  @override
  String get deleteAllButton => 'Șterge tot';

  @override
  String get entries => 'intrări';

  @override
  String get cacheEmpty => 'Cache-ul este gol';

  @override
  String get noStorage => 'Fără stocare utilizată';

  @override
  String get apiKeyNote =>
      'Înregistrare gratuită. Date de la agențiile guvernamentale de transparență a prețurilor.';

  @override
  String get apiKeyFormatError => 'Format invalid — UUID așteptat (8-4-4-4-12)';

  @override
  String get supportProject => 'Susțineți acest proiect';

  @override
  String get supportDescription =>
      'Această aplicație este gratuită, open source și fără reclame. Dacă o găsiți utilă, luați în considerare susținerea dezvoltatorului.';

  @override
  String get reportBug => 'Raportează eroare / Sugerează funcție';

  @override
  String get reportThisIssue => 'Raportați această problemă';

  @override
  String get reportAlreadySent => 'Ați raportat deja această problemă.';

  @override
  String get reportConsentTitle => 'Raportați pe GitHub?';

  @override
  String get reportConsentBody =>
      'Aceasta va deschide o problemă publică pe GitHub cu detaliile erorii de mai jos. Nu sunt incluse coordonate GPS, chei API sau date personale.';

  @override
  String get reportConsentConfirm => 'Deschide GitHub';

  @override
  String get reportConsentCancel => 'Anulare';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Profil activ';

  @override
  String get configPreferredFuel => 'Combustibil preferat';

  @override
  String get configCountry => 'Țara';

  @override
  String get configRouteSegment => 'Segment de rută';

  @override
  String get configApiKeysSection => 'Chei API';

  @override
  String get configTankerkoenigKey => 'Cheie API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Configurată';

  @override
  String get configApiKeyNotSet => 'Neconfigurată (mod demo)';

  @override
  String get configApiKeyCommunity => 'Implicită (cheie comunitate)';

  @override
  String get searchLocationPlaceholder => 'Adresă, cod poștal sau oraș';

  @override
  String get configEvKey => 'Cheie API stații EV';

  @override
  String get configEvKeyCustom => 'Cheie personalizată';

  @override
  String get configEvKeyShared => 'Implicită (partajată)';

  @override
  String get configCloudSyncSection => 'Sincronizare cloud';

  @override
  String get configTankSyncConnected => 'Conectat';

  @override
  String get configTankSyncDisabled => 'Dezactivat';

  @override
  String get configAuthMode => 'Mod autentificare';

  @override
  String get configAuthEmail => 'Email (persistent)';

  @override
  String get configAuthAnonymous => 'Anonim (doar pe dispozitiv)';

  @override
  String get configDatabase => 'Bază de date';

  @override
  String get configPrivacySummary => 'Rezumat confidențialitate';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoritele, alertele și stațiile ignorate sunt sincronizate cu baza dvs. de date privată\n• Poziția GPS și cheile API nu părăsesc niciodată dispozitivul\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Toate datele sunt stocate local doar pe acest dispozitiv\n• Nicio dată nu este trimisă la niciun server\n• Cheile API sunt criptate în spațiul de stocare securizat al dispozitivului';

  @override
  String get configAuthNoteEmail =>
      'Contul de email permite accesul de pe mai multe dispozitive';

  @override
  String get configAuthNoteAnonymous =>
      'Cont anonim — date legate de acest dispozitiv';

  @override
  String get configNone => 'Niciunul';

  @override
  String get privacyPolicy => 'Politica de confidențialitate';

  @override
  String get fuels => 'Carburanți';

  @override
  String get services => 'Servicii';

  @override
  String get zone => 'Zonă';

  @override
  String get highway => 'Autostradă';

  @override
  String get localStation => 'Benzinărie locală';

  @override
  String get lastUpdate => 'Ultima actualizare';

  @override
  String get automate24h => '24h/24 — Automat';

  @override
  String get refreshPrices => 'Actualizare prețuri';

  @override
  String get station => 'Benzinărie';

  @override
  String get locationDenied =>
      'Permisiunea de localizare refuzată. Puteți căuta după cod poștal.';

  @override
  String get demoModeBanner => 'Mod demo. Configurați cheia API în setări.';

  @override
  String get demoModeBannerAction => 'Obțineți prețuri live';

  @override
  String get sortDistance => 'Distanță';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Evaluare';

  @override
  String get sortPriceDistance => 'Preț/km';

  @override
  String get cheap => 'ieftin';

  @override
  String get expensive => 'scump';

  @override
  String stationsOnMap(int count) {
    return '$count benzinării';
  }

  @override
  String get loadingFavorites =>
      'Se încarcă favoritele...\nCăutați benzinării mai întâi pentru a salva date.';

  @override
  String get reportPrice => 'Raportează preț';

  @override
  String get whatsWrong => 'Ce nu este corect?';

  @override
  String get correctPrice => 'Preț corect (ex. 1,459)';

  @override
  String get sendReport => 'Trimite raportul';

  @override
  String get reportSent => 'Raport trimis. Mulțumim!';

  @override
  String get enterValidPrice => 'Introduceți un preț valid';

  @override
  String get cacheCleared => 'Cache golit.';

  @override
  String get yourPosition => 'Poziția dvs.';

  @override
  String get positionUnknown => 'Poziție necunoscută';

  @override
  String get routeModeBannerLabel =>
      'Mod rută — distanțele sunt de-a lungul coridorului';

  @override
  String get distancesFromCenter => 'Distanțe de la centrul căutării';

  @override
  String get autoUpdatePosition => 'Actualizare automată a poziției';

  @override
  String get autoUpdateDescription =>
      'Actualizează poziția GPS înainte de fiecare căutare';

  @override
  String get location => 'Locație';

  @override
  String get switchProfileTitle => 'Țară schimbată';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Sunteți acum în $country. Comutați la profilul \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Comutat la profilul \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Niciun profil pentru această țară';

  @override
  String noProfileForCountry(String country) {
    return 'Sunteți în $country, dar niciun profil nu este configurat. Creați unul în Setări.';
  }

  @override
  String get autoSwitchProfile => 'Comutare automată a profilului';

  @override
  String get autoSwitchDescription =>
      'Comută profilul automat la trecerea frontierei';

  @override
  String get switchProfile => 'Comută';

  @override
  String get dismiss => 'Închide';

  @override
  String get profileCountry => 'Țară';

  @override
  String get profileLanguage => 'Limbă';

  @override
  String get settingsStorageDetail => 'Cheie API, profil activ';

  @override
  String get allFuels => 'Toate';

  @override
  String get priceAlerts => 'Alerte de preț';

  @override
  String get noPriceAlerts => 'Fără alerte de preț';

  @override
  String get noPriceAlertsHint =>
      'Creați o alertă din pagina de detalii a unei benzinării.';

  @override
  String alertDeleted(String name) {
    return 'Alertă \"$name\" ștearsă';
  }

  @override
  String get createAlert => 'Creează alertă de preț';

  @override
  String currentPrice(String price) {
    return 'Preț curent: $price';
  }

  @override
  String get targetPrice => 'Preț țintă (EUR)';

  @override
  String get enterPrice => 'Introduceți un preț';

  @override
  String get invalidPrice => 'Preț invalid';

  @override
  String get priceTooHigh => 'Preț prea mare';

  @override
  String get create => 'Creează';

  @override
  String get alertCreated => 'Alertă de preț creată';

  @override
  String get wrongE5Price => 'Preț Super E5 incorect';

  @override
  String get wrongE10Price => 'Preț Super E10 incorect';

  @override
  String get wrongDieselPrice => 'Preț Diesel incorect';

  @override
  String get wrongStatusOpen => 'Afișat ca deschis, dar închis';

  @override
  String get wrongStatusClosed => 'Afișat ca închis, dar deschis';

  @override
  String get searchAlongRouteLabel => 'De-a lungul rutei';

  @override
  String get searchEvStations => 'Caută stații de încărcare';

  @override
  String get allStations => 'Toate stațiile';

  @override
  String get bestStops => 'Cele mai bune opriri';

  @override
  String get openInMaps => 'Deschide în Hărți';

  @override
  String get noStationsAlongRoute => 'Nu s-au găsit stații de-a lungul rutei';

  @override
  String get evOperational => 'Operațională';

  @override
  String get evStatusUnknown => 'Stare necunoscută';

  @override
  String evConnectors(int count) {
    return 'Conectori ($count puncte)';
  }

  @override
  String get evNoConnectors => 'Fără detalii conectori disponibile';

  @override
  String get evUsageCost => 'Cost de utilizare';

  @override
  String get evPricingUnavailable => 'Prețuri indisponibile de la furnizor';

  @override
  String get evLastUpdated => 'Ultima actualizare';

  @override
  String get evUnknown => 'Necunoscut';

  @override
  String get evDataAttribution => 'Date de la OpenChargeMap (sursă comunitară)';

  @override
  String get evStatusDisclaimer =>
      'Starea poate să nu reflecte disponibilitatea în timp real. Atingeți actualizare pentru cele mai recente date.';

  @override
  String get evNavigateToStation => 'Navigare la stație';

  @override
  String get evRefreshStatus => 'Actualizare stare';

  @override
  String get evStatusUpdated => 'Stare actualizată';

  @override
  String get evStationNotFound =>
      'Nu s-a putut actualiza — stație negăsită în apropiere';

  @override
  String get addedToFavorites => 'Adăugat la favorite';

  @override
  String get removedFromFavorites => 'Eliminat din favorite';

  @override
  String get addFavorite => 'Adaugă la favorite';

  @override
  String get removeFavorite => 'Elimină din favorite';

  @override
  String get currentLocation => 'Locația curentă';

  @override
  String get gpsError => 'Eroare GPS';

  @override
  String get couldNotResolve =>
      'Nu s-a putut determina punctul de plecare sau destinația';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destinație';

  @override
  String get cityAddressOrGps => 'Oraș, adresă sau GPS';

  @override
  String get cityOrAddress => 'Oraș sau adresă';

  @override
  String get useGps => 'Folosește GPS';

  @override
  String get stop => 'Oprire';

  @override
  String stopN(int n) {
    return 'Oprire $n';
  }

  @override
  String get addStop => 'Adaugă oprire';

  @override
  String get searchAlongRoute => 'Caută de-a lungul rutei';

  @override
  String get cheapest => 'Cea mai ieftină';

  @override
  String nStations(int count) {
    return '$count stații';
  }

  @override
  String nBest(int count) {
    return '$count cele mai bune';
  }

  @override
  String get fuelPricesTankerkoenig => 'Prețuri carburanți (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Necesar pentru căutarea prețurilor de carburanți în Germania';

  @override
  String get evChargingOpenChargeMap => 'Încărcare EV (OpenChargeMap)';

  @override
  String get customKey => 'Cheie personalizată';

  @override
  String get appDefaultKey => 'Cheie implicită a aplicației';

  @override
  String get optionalOverrideKey =>
      'Opțional: înlocuiți cheia încorporată cu a dvs.';

  @override
  String get requiredForEvSearch =>
      'Necesar pentru căutarea stațiilor de încărcare EV';

  @override
  String get edit => 'Editare';

  @override
  String get fuelPricesApiKey => 'Cheie API prețuri carburanți';

  @override
  String get tankerkoenigApiKey => 'Cheie API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Cheie API încărcare EV';

  @override
  String get openChargeMapApiKey => 'Cheie API OpenChargeMap';

  @override
  String get routePlanningSection => 'Planificarea rutei';

  @override
  String get routeMinSaving => 'Economie minimă';

  @override
  String get routeMinSavingOff => 'Dezactivat';

  @override
  String get routeMinSavingOffCaption =>
      'Se afișează toate stațiile găsite de-a lungul rutei';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Doar stații în limita a $amount față de cea mai ieftină de pe rută';
  }

  @override
  String get routeDetourBudget => 'Ocol maxim';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Afișează stații până la $km km de ruta directă';
  }

  @override
  String get routeSegment => 'Segment rută';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Arată cea mai ieftină stație la fiecare $km km de-a lungul rutei';
  }

  @override
  String get avoidHighways => 'Evită autostrăzile';

  @override
  String get avoidHighwaysDesc =>
      'Calculul rutei evită drumurile cu taxă și autostrăzile';

  @override
  String get showFuelStations => 'Arată benzinăriile';

  @override
  String get showFuelStationsDesc =>
      'Include stații de benzină, motorină, GPL, GNC';

  @override
  String get showEvStations => 'Arată stații de încărcare';

  @override
  String get showEvStationsDesc =>
      'Include stații de încărcare electrică în rezultate';

  @override
  String get noStationsAlongThisRoute =>
      'Nu s-au găsit stații de-a lungul acestei rute.';

  @override
  String get fuelCostCalculator => 'Calculator cost carburant';

  @override
  String get distanceKm => 'Distanță (km)';

  @override
  String get consumptionL100km => 'Consum (L/100km)';

  @override
  String get fuelPriceEurL => 'Preț carburant (EUR/L)';

  @override
  String get tripCost => 'Costul călătoriei';

  @override
  String get fuelNeeded => 'Carburant necesar';

  @override
  String get totalCost => 'Cost total';

  @override
  String get enterCalcValues =>
      'Introduceți distanța, consumul și prețul pentru a calcula costul călătoriei';

  @override
  String get priceHistory => 'Istoric prețuri';

  @override
  String get ignoredStationsLabel => 'Ignorate';

  @override
  String get ratingsLabel => 'Evaluări';

  @override
  String get favoritesDataCache => 'Date favorite';

  @override
  String get citySearchCache => 'Căutare oraș';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Ștergerea datelor nu este disponibilă în modul Comunitate. Deconectați-vă mai întâi sau utilizați o bază de date privată.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count stații urmărite';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count configurate';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count stații ascunse';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count stații evaluate';
  }

  @override
  String get noPriceHistory => 'Încă nu există istoric de prețuri';

  @override
  String get noHourlyData => 'Fără date orare';

  @override
  String get noStatistics => 'Nu sunt statistici disponibile';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Med';

  @override
  String get showAllFuelTypes => 'Arată toate tipurile de carburant';

  @override
  String get connected => 'Conectat';

  @override
  String get notConnected => 'Neconectat';

  @override
  String get connectTankSync => 'Conectare TankSync';

  @override
  String get disconnectTankSync => 'Deconectare TankSync';

  @override
  String get viewMyData => 'Vezi datele mele';

  @override
  String get optionalCloudSync =>
      'Sincronizare cloud opțională pentru alerte, favorite și notificări push';

  @override
  String get tapToUpdateGps => 'Atingeți pentru a actualiza poziția GPS';

  @override
  String get gpsAutoUpdateHint =>
      'Poziția GPS este obținută automat la căutare. O puteți actualiza și manual aici.';

  @override
  String get clearGpsConfirm =>
      'Ștergeți poziția GPS stocată? O puteți actualiza oricând.';

  @override
  String get pageNotFound => 'Pagină negăsită';

  @override
  String get deleteAllServerData => 'Șterge toate datele de pe server';

  @override
  String get deleteServerDataConfirm => 'Ștergeți toate datele de pe server?';

  @override
  String get deleteEverything => 'Șterge tot';

  @override
  String get allDataDeleted => 'Toate datele de pe server șterse';

  @override
  String get forgetAllSyncedTripsButton =>
      'Ștergeți toate călătoriile sincronizate';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Ștergeți toate călătoriile sincronizate?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Fiecare rezumat de călătorie și blob de detalii va fi eliminat de pe server. Istoricul local al călătoriilor de pe acest dispozitiv nu va fi afectat.\n\nAceastă acțiune nu poate fi anulată.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Ștergeți toate';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Toate călătoriile sincronizate au fost eliminate de pe server';

  @override
  String get disconnectConfirm => 'Deconectați TankSync?';

  @override
  String get disconnect => 'Deconectare';

  @override
  String get myServerData => 'Datele mele de pe server';

  @override
  String get anonymousUuid => 'UUID anonim';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Date sincronizate';

  @override
  String get pushTokens => 'Tokeni push';

  @override
  String get priceReports => 'Rapoarte de prețuri';

  @override
  String get syncedTrips => 'Călătorii';

  @override
  String get totalItems => 'Total elemente';

  @override
  String get estimatedSize => 'Dimensiune estimată';

  @override
  String get viewRawJson => 'Vezi date brute ca JSON';

  @override
  String get exportJson => 'Exportă ca JSON (clipboard)';

  @override
  String get jsonCopied => 'JSON copiat în clipboard';

  @override
  String get rawDataJson => 'Date brute (JSON)';

  @override
  String get close => 'Închide';

  @override
  String get account => 'Cont';

  @override
  String get continueAsGuest => 'Continuați ca oaspete';

  @override
  String get createAccount => 'Creați cont';

  @override
  String get signIn => 'Conectați-vă';

  @override
  String get upgradeToEmail => 'Creați cont cu email';

  @override
  String get savedRoutes => 'Rute salvate';

  @override
  String get noSavedRoutes => 'Nicio rută salvată';

  @override
  String get noSavedRoutesHint =>
      'Căutați de-a lungul unei rute și salvați-o pentru acces rapid ulterior.';

  @override
  String get saveRoute => 'Salvați ruta';

  @override
  String get routeName => 'Numele rutei';

  @override
  String itineraryDeleted(String name) {
    return '$name șters';
  }

  @override
  String loadingRoute(String name) {
    return 'Se încarcă ruta: $name';
  }

  @override
  String get refreshFailed =>
      'Actualizarea a eșuat. Vă rugăm să încercați din nou.';

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
      'Configurați aplicația în câțiva pași rapizi.';

  @override
  String get onboardingApiKeyDescription =>
      'Înregistrați-vă pentru o cheie API gratuită sau omiteți pentru a explora aplicația cu date demo.';

  @override
  String get onboardingComplete => 'Totul e gata!';

  @override
  String get onboardingCompleteHint =>
      'Puteți modifica aceste setări oricând din profilul dvs.';

  @override
  String get onboardingBack => 'Înapoi';

  @override
  String get onboardingNext => 'Înainte';

  @override
  String get onboardingSkip => 'Omiteți';

  @override
  String get onboardingFinish => 'Începeți';

  @override
  String crossBorderNearby(String country) {
    return '$country este în apropiere';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km până la frontieră';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Medie aici: $price EUR ($count stații)';
  }

  @override
  String get allPricesView => 'Toate prețurile';

  @override
  String get compactView => 'Compact';

  @override
  String get switchToAllPricesView =>
      'Comutați la vizualizarea tuturor prețurilor';

  @override
  String get switchToCompactView => 'Comutați la vizualizarea compactă';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'Stoc epuizat';

  @override
  String get gdprTitle => 'Confidențialitatea dvs.';

  @override
  String get gdprSubtitle =>
      'Această aplicație vă respectă confidențialitatea. Alegeți ce date doriți să partajați. Puteți modifica aceste setări oricând.';

  @override
  String get gdprLocationTitle => 'Acces la locație';

  @override
  String get gdprLocationDescription =>
      'Coordonatele dvs. sunt trimise la API-ul de prețuri combustibil pentru a găsi stații din apropiere. Datele de locație nu sunt niciodată stocate pe un server și nu sunt utilizate pentru urmărire.';

  @override
  String get gdprLocationShort =>
      'Găsiți stații de combustibil din apropiere folosind locația dvs.';

  @override
  String get gdprErrorReportingTitle => 'Raportare erori';

  @override
  String get gdprErrorReportingDescription =>
      'Rapoartele anonime de blocare ajută la îmbunătățirea aplicației. Nu sunt incluse date personale. Rapoartele sunt trimise prin Sentry doar când este configurat.';

  @override
  String get gdprErrorReportingShort =>
      'Trimiteți rapoarte anonime de blocare pentru îmbunătățirea aplicației';

  @override
  String get gdprCloudSyncTitle => 'Sincronizare cloud';

  @override
  String get gdprCloudSyncDescription =>
      'Sincronizați favoritele și alertele pe mai multe dispozitive prin TankSync. Folosește autentificare anonimă. Datele dvs. sunt criptate în tranzit.';

  @override
  String get gdprCloudSyncShort =>
      'Sincronizați favoritele și alertele pe mai multe dispozitive';

  @override
  String get gdprLegalBasis =>
      'Baza legală: Art. 6(1)(a) GDPR (Consimțământ). Puteți retrage consimțământul oricând din Setări.';

  @override
  String get gdprAcceptAll => 'Acceptați toate';

  @override
  String get gdprAcceptSelected => 'Acceptați selecția';

  @override
  String get gdprSettingsHint =>
      'Puteți modifica preferințele de confidențialitate oricând.';

  @override
  String get routeSaved => 'Ruta salvată!';

  @override
  String get routeSaveFailed => 'Salvarea rutei a eșuat';

  @override
  String get sqlCopied => 'SQL copiat în clipboard';

  @override
  String get connectionDataCopied => 'Datele de conexiune copiate';

  @override
  String get accountDeleted => 'Contul a fost șters. Datele locale păstrate.';

  @override
  String get switchedToAnonymous => 'Trecut la sesiune anonimă';

  @override
  String failedToSwitch(String error) {
    return 'Comutarea a eșuat: $error';
  }

  @override
  String get topicUrlCopied => 'URL-ul temei copiat';

  @override
  String get testNotificationSent => 'Notificare de test trimisă!';

  @override
  String get testNotificationFailed => 'Trimiterea notificării de test a eșuat';

  @override
  String get pushUpdateFailed =>
      'Actualizarea setării de notificare push a eșuat';

  @override
  String get connectedAsGuest => 'Conectat ca oaspete';

  @override
  String get accountCreated => 'Contul a fost creat!';

  @override
  String get signedIn => 'Conectat!';

  @override
  String stationHidden(String name) {
    return '$name ascunsă';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name eliminată din favorite';
  }

  @override
  String invalidApiKey(String error) {
    return 'Cheie API invalidă: $error';
  }

  @override
  String get invalidQrCode => 'Format cod QR invalid';

  @override
  String get invalidQrCodeTankSync =>
      'Cod QR invalid — format TankSync așteptat';

  @override
  String get tankSyncConnected => 'TankSync conectat!';

  @override
  String get syncCompleted => 'Sincronizare finalizată — date actualizate';

  @override
  String get deviceCodeCopied => 'Codul dispozitivului copiat';

  @override
  String get undo => 'Anulați';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Introduceți un $label valid de $length cifre';
  }

  @override
  String get freshnessAgo => 'în urmă';

  @override
  String get freshnessStale => 'Expirat';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Prospețimea datelor: $age';
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
      other: 'Acordați $count stele',
      one: 'Acordați 1 stea',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Slab';

  @override
  String get passwordStrengthFair => 'Acceptabil';

  @override
  String get passwordStrengthStrong => 'Puternic';

  @override
  String get passwordReqMinLength => 'Minimum 8 caractere';

  @override
  String get passwordReqUppercase => 'Cel puțin 1 literă majusculă';

  @override
  String get passwordReqLowercase => 'Cel puțin 1 literă mică';

  @override
  String get passwordReqDigit => 'Cel puțin 1 cifră';

  @override
  String get passwordReqSpecial => 'Cel puțin 1 caracter special';

  @override
  String get passwordTooWeak => 'Parola nu îndeplinește toate cerințele';

  @override
  String get brandFilterAll => 'Toate';

  @override
  String get brandFilterNoHighway => 'Fără autostradă';

  @override
  String get swipeTutorialMessage =>
      'Glisați dreapta pentru navigare, glisați stânga pentru a elimina';

  @override
  String get swipeTutorialDismiss => 'Am înțeles';

  @override
  String get alertStatsActive => 'Active';

  @override
  String get alertStatsToday => 'Astăzi';

  @override
  String get alertStatsThisWeek => 'Săptămâna aceasta';

  @override
  String get privacyDashboardTitle => 'Tablou de bord confidențialitate';

  @override
  String get privacyDashboardSubtitle =>
      'Vizualizați, exportați sau ștergeți datele dvs.';

  @override
  String get privacyDashboardBanner =>
      'Datele dvs. vă aparțin. Aici puteți vedea tot ce stochează această aplicație, le puteți exporta sau șterge.';

  @override
  String get privacyLocalData => 'Date pe acest dispozitiv';

  @override
  String get privacyIgnoredStations => 'Stații ignorate';

  @override
  String get privacyRatings => 'Evaluări stații';

  @override
  String get privacyPriceHistory => 'Stații cu istoric prețuri';

  @override
  String get privacyProfiles => 'Profile de căutare';

  @override
  String get privacyItineraries => 'Rute salvate';

  @override
  String get privacyCacheEntries => 'Intrări în cache';

  @override
  String get privacyApiKey => 'Cheie API stocată';

  @override
  String get privacyEvApiKey => 'Cheie API EV stocată';

  @override
  String get privacyEstimatedSize => 'Spațiu estimat';

  @override
  String get privacySyncedData => 'Sincronizare cloud (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Sincronizarea cloud este dezactivată. Toate datele rămân doar pe acest dispozitiv.';

  @override
  String get privacySyncMode => 'Mod sincronizare';

  @override
  String get privacySyncUserId => 'ID utilizator';

  @override
  String get privacySyncDescription =>
      'Când sincronizarea este activată, favoritele, alertele, stațiile ignorate și evaluările sunt stocate și pe serverul TankSync.';

  @override
  String get privacyViewServerData => 'Vizualizați datele de pe server';

  @override
  String get privacyExportButton => 'Exportați toate datele ca JSON';

  @override
  String get privacyExportSuccess => 'Date exportate în clipboard';

  @override
  String get privacyExportCsvButton => 'Exportați toate datele ca CSV';

  @override
  String get privacyExportCsvSuccess => 'Date CSV exportate în clipboard';

  @override
  String get savedToDownloadsFolder => 'Salvat în folderul Descărcări';

  @override
  String get privacyDeleteButton => 'Ștergeți toate datele';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Copiați jurnalul de erori în clipboard ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Salvează jurnalul de erori ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Șterge jurnalul de erori';

  @override
  String get privacyErrorLogCleared => 'Jurnalul de erori a fost șters';

  @override
  String get privacyDeleteTitle => 'Ștergeți toate datele?';

  @override
  String get privacyDeleteBody =>
      'Aceasta va șterge permanent:\n\n- Toate favoritele și datele stațiilor\n- Toate profilurile de căutare\n- Toate alertele de prețuri\n- Tot istoricul prețurilor\n- Toate datele din cache\n- Cheia dvs. API\n- Toate setările aplicației\n\nAplicația se va reseta la starea inițială. Această acțiune nu poate fi anulată.';

  @override
  String get privacyDeleteConfirm => 'Ștergeți totul';

  @override
  String get yes => 'Da';

  @override
  String get no => 'Nu';

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
  String get paymentMethods => 'Metode de plată';

  @override
  String get paymentMethodCash => 'Numerar';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Card combustibil';

  @override
  String get paymentMethodApp => 'Aplicație';

  @override
  String payWithApp(String app) {
    return 'Plătiți cu $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Comparativ cu media rulantă din ultimele 3 alimentări ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consum $value L/100 km, $delta față de media dvs. rulantă';
  }

  @override
  String get drivingMode => 'Mod de condus';

  @override
  String get drivingExit => 'Ieșire';

  @override
  String get drivingNearestStation => 'Cea mai apropiată';

  @override
  String get drivingTapToUnlock => 'Apăsați pentru deblocare';

  @override
  String get drivingSafetyTitle => 'Avertisment de siguranță';

  @override
  String get drivingSafetyMessage =>
      'Nu utilizați aplicația în timp ce conduceți. Opriți-vă într-un loc sigur înainte de a interacționa cu ecranul. Șoferul este responsabil pentru operarea în siguranță a vehiculului în orice moment.';

  @override
  String get drivingSafetyAccept => 'Am înțeles';

  @override
  String get voiceAnnouncementsTitle => 'Anunțuri vocale';

  @override
  String get voiceAnnouncementsDescription =>
      'Anunță stații ieftine din apropiere în timp ce conduceți';

  @override
  String get voiceAnnouncementsEnabled => 'Activați anunțurile vocale';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Doar sub $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, la $distance kilometri înainte, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Raza de anunț';

  @override
  String get voiceAnnouncementCooldown => 'Interval de repetare';

  @override
  String get nearestStations => 'Cele mai apropiate statii';

  @override
  String get nearestStationsHint =>
      'Gasiti cele mai apropiate statii cu locatia dvs. actuala';

  @override
  String get consumptionLogTitle => 'Consum combustibil';

  @override
  String get consumptionLogMenuTitle => 'Jurnal consum';

  @override
  String get consumptionLogMenuSubtitle =>
      'Urmăriți alimentările și calculați L/100km';

  @override
  String get consumptionStatsTitle => 'Statistici consum';

  @override
  String get addFillUp => 'Adăugați alimentare';

  @override
  String get noFillUpsTitle => 'Nicio alimentare încă';

  @override
  String get noFillUpsSubtitle =>
      'Înregistrați prima alimentare pentru a începe urmărirea consumului.';

  @override
  String get fillUpDate => 'Data';

  @override
  String get liters => 'Litri';

  @override
  String get odometerKm => 'Odometru (km)';

  @override
  String get notesOptional => 'Note (opțional)';

  @override
  String get stationPreFilled => 'Stație precompletată';

  @override
  String get statAvgConsumption => 'Medie L/100km';

  @override
  String get statAvgCostPerKm => 'Cost mediu/km';

  @override
  String get statTotalLiters => 'Total litri';

  @override
  String get statTotalSpent => 'Total cheltuit';

  @override
  String get statFillUpCount => 'Alimentări';

  @override
  String get fieldRequired => 'Obligatoriu';

  @override
  String get fieldInvalidNumber => 'Număr invalid';

  @override
  String get carbonDashboardTitle => 'Tablou de bord carbon';

  @override
  String get carbonEmptyTitle => 'Nicio dată încă';

  @override
  String get carbonEmptySubtitle =>
      'Înregistrați alimentări pentru a vedea tabloul de bord carbon.';

  @override
  String get carbonSummaryTotalCost => 'Cost total';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 total';

  @override
  String get monthlyCostsTitle => 'Costuri lunare';

  @override
  String get monthlyEmissionsTitle => 'Emisii lunare de CO2';

  @override
  String get vehiclesTitle => 'Vehiculele mele';

  @override
  String get vehiclesMenuTitle => 'Vehiculele mele';

  @override
  String get vehiclesMenuSubtitle =>
      'Baterie, conectori, preferințe de încărcare';

  @override
  String get vehiclesEmptyMessage =>
      'Adăugați mașina dvs. pentru a filtra după conector și a estima costurile de încărcare.';

  @override
  String get vehiclesWizardTitle => 'Vehiculele mele (opțional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Adăugați mașina pentru a precompletă jurnalul de consum și a activa filtrele de conectori EV. Puteți omite și adăuga vehicule mai târziu.';

  @override
  String get vehiclesWizardNoneYet => 'Niciun vehicul configurat încă.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicule',
      one: '1 vehicul',
    );
    return 'Aveți $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Omiteți pentru a finaliza configurarea — puteți adăuga vehicule oricând din Setări.';

  @override
  String get fillUpVehicleLabel => 'Vehicul';

  @override
  String get fillUpVehicleNone => 'Niciun vehicul';

  @override
  String get fillUpVehicleRequired => 'Vehiculul este obligatoriu';

  @override
  String get reportScanError => 'Raportați eroare de scanare';

  @override
  String get pickStationTitle => 'Alegeți o stație';

  @override
  String get pickStationHelper =>
      'Porniți alimentarea de la o stație cunoscută pentru a completa automat prețurile, marca și tipul de combustibil.';

  @override
  String get pickStationEmpty =>
      'Nicio stație favorită încă — adăugați din Căutare sau Favorite sau omiteți și completați manual.';

  @override
  String get pickStationSkip => 'Omiteți — adăugați fără stație';

  @override
  String get scanPump => 'Scanați pompa';

  @override
  String get scanPayment => 'Scanați QR de plată';

  @override
  String get qrPaymentBeneficiary => 'Beneficiar';

  @override
  String get qrPaymentAmount => 'Suma';

  @override
  String get qrPaymentEpcTitle => 'Plată SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Niciun câmp decodat';

  @override
  String get qrPaymentOpenInBank => 'Deschideți în aplicația bancară';

  @override
  String get qrPaymentLaunchFailed =>
      'Nicio aplicație disponibilă pentru a deschide acest cod';

  @override
  String get qrPaymentUnknownTitle => 'Cod nerecunoscut';

  @override
  String get qrPaymentCopyRaw => 'Copiați textul brut';

  @override
  String get qrPaymentCopiedRaw => 'Copiat în clipboard';

  @override
  String get qrPaymentReport => 'Raportați această scanare';

  @override
  String get qrPaymentEpcCopied =>
      'Detalii bancare copiate — lipiți în aplicația dvs. bancară';

  @override
  String get qrScannerGuidance => 'Îndreptați camera spre un cod QR';

  @override
  String get qrScannerPermissionDenied =>
      'Accesul la cameră este necesar pentru a scana coduri QR.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Accesul la cameră a fost refuzat. Deschideți setările pentru a-l permite.';

  @override
  String get qrScannerRetryPermission => 'Încercați din nou';

  @override
  String get qrScannerOpenSettings => 'Deschideți setările';

  @override
  String get qrScannerTimeout =>
      'Niciun cod QR detectat. Apropiați-vă sau încercați din nou.';

  @override
  String get qrScannerRetry => 'Încercați din nou';

  @override
  String get torchOn => 'Activați blițul';

  @override
  String get torchOff => 'Dezactivați blițul';

  @override
  String get obdNoAdapter => 'Niciun adaptor OBD2 în rază';

  @override
  String get obdOdometerUnavailable => 'Nu s-a putut citi odometrul';

  @override
  String get obdPermissionDenied =>
      'Acordați permisiunea Bluetooth în setările sistemului';

  @override
  String get obdAdapterUnresponsive =>
      'Adaptorul nu a răspuns — porniți contactul și reîncercați';

  @override
  String get obdPickerTitle => 'Alegeți un adaptor OBD2';

  @override
  String get obdPickerScanning => 'Se caută adaptoare…';

  @override
  String get obdPickerConnecting => 'Se conectează…';

  @override
  String get themeSettingTitle => 'Temă';

  @override
  String get themeModeLight => 'Luminos';

  @override
  String get themeModeDark => 'Întunecat';

  @override
  String get themeModeSystem => 'Urmați sistemul';

  @override
  String get tripRecordingTitle => 'Se înregistrează călătoria';

  @override
  String get tripSummaryTitle => 'Rezumat călătorie';

  @override
  String get tripMetricDistance => 'Distanță';

  @override
  String get tripMetricSpeed => 'Viteză';

  @override
  String get tripMetricFuelUsed => 'Combustibil utilizat';

  @override
  String get tripMetricAvgConsumption => 'Medie';

  @override
  String get tripMetricElapsed => 'Timp scurs';

  @override
  String get tripMetricOdometer => 'Odometru';

  @override
  String get tripStop => 'Opriți înregistrarea';

  @override
  String get tripPause => 'Pauză';

  @override
  String get tripResume => 'Reluați';

  @override
  String get tripBannerRecording => 'Se înregistrează călătoria';

  @override
  String get tripBannerPaused => 'Călătorie în pauză — apăsați pentru a relua';

  @override
  String get navConsumption => 'Consum';

  @override
  String get vehicleBaselineSectionTitle => 'Calibrare referință';

  @override
  String get vehicleBaselineEmpty =>
      'Niciun eșantion încă — porniți o călătorie OBD2 pentru a învăța profilul de combustibil al acestui vehicul.';

  @override
  String get vehicleBaselineProgress =>
      'Învățat din eșantioane în diverse situații de condus.';

  @override
  String get vehicleBaselineReset => 'Resetați referința situației de condus';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Resetați referința situației de condus?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Aceasta șterge toate eșantioanele învățate pentru acest vehicul. Veți reveni la valorile implicite de pornire la rece până când noile călătorii vor reumple profilul.';

  @override
  String get vehicleAdapterSectionTitle => 'Adaptor OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Niciun adaptor asociat. Asociați unul pentru ca aplicația să se poată reconecta automat data viitoare.';

  @override
  String get vehicleAdapterUnnamed => 'Adaptor necunoscut';

  @override
  String get vehicleAdapterPair => 'Asociați adaptorul';

  @override
  String get vehicleAdapterForget => 'Uitați adaptorul';

  @override
  String get achievementsTitle => 'Realizări';

  @override
  String get achievementFirstTrip => 'Prima călătorie';

  @override
  String get achievementFirstTripDesc => 'Înregistrați prima călătorie OBD2.';

  @override
  String get achievementFirstFillUp => 'Prima alimentare';

  @override
  String get achievementFirstFillUpDesc => 'Înregistrați prima alimentare.';

  @override
  String get achievementTenTrips => '10 călătorii';

  @override
  String get achievementTenTripsDesc => 'Înregistrați 10 călătorii OBD2.';

  @override
  String get achievementZeroHarsh => 'Șofer lin';

  @override
  String get achievementZeroHarshDesc =>
      'Finalizați o călătorie de 10 km sau mai mult fără frânări sau accelerări bruște.';

  @override
  String get achievementEcoWeek => 'Săptămână eco';

  @override
  String get achievementEcoWeekDesc =>
      'Conduceți 7 zile consecutive cu cel puțin o călătorie lină în fiecare zi.';

  @override
  String get achievementPriceWin => 'Câștig la preț';

  @override
  String get achievementPriceWinDesc =>
      'Înregistrați o alimentare cu 5% sau mai mult sub media de 30 de zile a stației.';

  @override
  String get syncBaselinesToggleTitle =>
      'Partajați profilurile vehiculelor învățate';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Încărcați referințele de consum per vehicul pentru a le reutiliza pe un al doilea dispozitiv.';

  @override
  String get obd2StatusConnected => 'Adaptor OBD2: conectat';

  @override
  String get obd2StatusAttempting => 'Adaptor OBD2: se conectează';

  @override
  String get obd2StatusUnreachable => 'Adaptor OBD2: inaccesibil';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptor OBD2: permisiune Bluetooth necesară';

  @override
  String get obd2StatusConnectedBody =>
      'Gata pentru înregistrarea unei călătorii.';

  @override
  String get obd2StatusAttemptingBody => 'Se conectează în fundal…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adaptorul este în afara razei sau deja utilizat de o altă aplicație.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Acordați permisiunea Bluetooth în setările sistemului pentru a vă reconecta automat.';

  @override
  String get obd2StatusNoAdapter => 'Niciun adaptor asociat';

  @override
  String get obd2StatusForget => 'Uitați adaptorul';

  @override
  String get tripHistoryTitle => 'Istoricul călătoriilor';

  @override
  String get tripHistoryEmptyTitle => 'Nicio călătorie încă';

  @override
  String get tripHistoryEmptySubtitle =>
      'Conectați un adaptor OBD2 și înregistrați o călătorie pentru a începe istoricul de condus.';

  @override
  String get tripHistoryUnknownDate => 'Dată necunoscută';

  @override
  String get situationIdle => 'Ralanti';

  @override
  String get situationStopAndGo => 'Stop & Go';

  @override
  String get situationUrban => 'Urban';

  @override
  String get situationHighway => 'Autostradă';

  @override
  String get situationDecel => 'Decelerare';

  @override
  String get situationClimbing => 'Urcare / încărcat';

  @override
  String get situationHardAccel => 'Accelerare bruscă';

  @override
  String get situationFuelCut => 'Tăiere combustibil — inerție';

  @override
  String get tripSaveAsFillUp => 'Salvați ca alimentare';

  @override
  String get tripSaveRecording => 'Salvați călătoria';

  @override
  String get tripDiscard => 'Renunțați';

  @override
  String obdOdometerRead(int km) {
    return 'Odometru citit: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nesetat';

  @override
  String get wizardVehicleTapToEdit => 'Apăsați pentru a edita';

  @override
  String get wizardVehicleDefaultBadge => 'Implicit';

  @override
  String get wizardProfileChoiceHint =>
      'Alegeți cum doriți să utilizați aplicația. Puteți modifica aceasta mai târziu din Setări.';

  @override
  String get wizardProfileChoiceFooter =>
      'Puteți schimba oricând alegerea din Setări → Mod de utilizare.';

  @override
  String get wizardProfileBasicName => 'De bază';

  @override
  String get wizardProfileBasicDescription =>
      'Cele mai ieftine prețuri de combustibil și încărcare EV din apropiere. Favorite și alerte de prețuri.';

  @override
  String get wizardProfileMediumName => 'Mediu';

  @override
  String get wizardProfileMediumDescription =>
      'Tot din De bază, plus urmărirea manuală a alimentărilor și a încărcărilor EV.';

  @override
  String get wizardProfileFullName => 'Complet';

  @override
  String get wizardProfileFullDescription =>
      'Tot din Mediu, plus înregistrarea automată a călătoriilor OBD2, scoruri de condus și carduri de fidelitate.';

  @override
  String get wizardProfileCustomName => 'Personalizat';

  @override
  String get wizardProfileCustomDescription =>
      'Propria combinație de funcționalități. Ajustați fiecare comutator mai jos.';

  @override
  String get useModeSectionHint =>
      'Adaptați aplicația la modul în care o utilizați efectiv. Alegând un preset se activează setul corespunzător de funcționalități.';

  @override
  String get useModeCustomSettingsDescription =>
      'Combinația dvs. de funcționalități nu corespunde niciunui preset. Alegeți unul de mai sus pentru a suprascrie sau continuați personalizarea funcționalităților individuale în secțiunea de mai jos.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Modul de utilizare setat la $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Vehicul implicit (opțional)';

  @override
  String get profileDefaultVehicleNone => 'Fără implicit';

  @override
  String get profileFuelFromVehicleHint =>
      'Tipul de combustibil este derivat din vehiculul dvs. implicit. Ștergeți vehiculul pentru a alege direct combustibilul.';

  @override
  String get consumptionNoVehicleTitle => 'Adăugați mai întâi un vehicul';

  @override
  String get consumptionNoVehicleBody =>
      'Alimentările sunt atribuite unui vehicul. Adăugați mașina dvs. pentru a începe înregistrarea consumului.';

  @override
  String get vehicleAdd => 'Adăugați vehicul';

  @override
  String get vehicleAddTitle => 'Adăugați vehicul';

  @override
  String get vehicleEditTitle => 'Editați vehiculul';

  @override
  String get vehicleDeleteTitle => 'Ștergeți vehiculul?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Eliminați \"$name\" din profilurile dvs.?';
  }

  @override
  String get vehicleNameLabel => 'Nume';

  @override
  String get vehicleNameHint => 'ex. Mașina mea Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustie';

  @override
  String get vehicleTypeHybrid => 'Hibrid';

  @override
  String get vehicleTypeEv => 'Electric';

  @override
  String get vehicleEvSectionTitle => 'Electric';

  @override
  String get vehicleCombustionSectionTitle => 'Combustie';

  @override
  String get vehicleBatteryLabel => 'Capacitate baterie (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Putere maximă de încărcare (kW)';

  @override
  String get vehicleConnectorsLabel => 'Conectori suportați';

  @override
  String get vehicleMinSocLabel => 'SoC minim %';

  @override
  String get vehicleMaxSocLabel => 'SoC maxim %';

  @override
  String get vehicleTankLabel => 'Capacitate rezervor (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Combustibil preferat';

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
  String get connectorThreePin => '3 pini';

  @override
  String get evShowOnMap => 'Afișați stații EV';

  @override
  String get evAvailableOnly => 'Numai disponibile';

  @override
  String get evMinPower => 'Putere minimă';

  @override
  String get evMaxPower => 'Putere maximă';

  @override
  String get evOperator => 'Operator';

  @override
  String get evLastUpdate => 'Ultima actualizare';

  @override
  String get evStatusAvailable => 'Disponibil';

  @override
  String get evStatusOccupied => 'Ocupat';

  @override
  String get evStatusOutOfOrder => 'Defect';

  @override
  String get openOnlyFilter => 'Numai deschise';

  @override
  String get saveAsDefaults => 'Salvați ca setări implicite';

  @override
  String get criteriaSavedToProfile => 'Salvat ca setări implicite';

  @override
  String get profileNotFound => 'Niciun profil activ';

  @override
  String get updatingFavorites => 'Se actualizează favoritele...';

  @override
  String get fetchingLatestPrices => 'Se preiau cele mai recente prețuri';

  @override
  String get noDataAvailable => 'Fără date';

  @override
  String get configAndPrivacy => 'Configurare și confidențialitate';

  @override
  String get searchToSeeMap => 'Căutați pentru a vedea stațiile pe hartă';

  @override
  String get evPowerAny => 'Oricare';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Locație';

  @override
  String get tooltipBack => 'Înapoi';

  @override
  String get tooltipClose => 'Închideți';

  @override
  String get tooltipShare => 'Distribuie';

  @override
  String get tooltipClearSearch => 'Ștergeți căutarea';

  @override
  String get minimalDriveInstantConsumption => 'Consum instantaneu';

  @override
  String get coachingShiftUp => 'Schimbă în sus';

  @override
  String get coachingShiftDown => 'Schimbă în jos';

  @override
  String get coachingEasePedal => 'Mai puțină accelerație';

  @override
  String get tooltipUseGps => 'Utilizați locația GPS';

  @override
  String get tooltipShowPassword => 'Afișați parola';

  @override
  String get tooltipHidePassword => 'Ascundeți parola';

  @override
  String get evConnectorsLabel => 'Conectori disponibili';

  @override
  String get evConnectorsNone => 'Nicio informație despre conectori';

  @override
  String get switchToEmail => 'Treceți la email';

  @override
  String get switchToEmailSubtitle =>
      'Păstrați datele, adăugați autentificare de pe alte dispozitive';

  @override
  String get switchToAnonymousAction => 'Treceți la anonim';

  @override
  String get switchToAnonymousSubtitle =>
      'Păstrați datele locale, utilizați o sesiune anonimă nouă';

  @override
  String get linkDevice => 'Conectați dispozitivul';

  @override
  String get shareDatabase => 'Partajați baza de date';

  @override
  String get disconnectAction => 'Deconectați';

  @override
  String get disconnectSubtitle =>
      'Opriți sincronizarea (datele locale păstrate)';

  @override
  String get deleteAccountAction => 'Ștergeți contul';

  @override
  String get deleteAccountSubtitle =>
      'Eliminați permanent toate datele de pe server';

  @override
  String get localOnly => 'Numai local';

  @override
  String get localOnlySubtitle =>
      'Opțional: sincronizați favorite, alerte și evaluări pe mai multe dispozitive';

  @override
  String get setupCloudSync => 'Configurați sincronizarea cloud';

  @override
  String get disconnectTitle => 'Deconectați TankSync?';

  @override
  String get disconnectBody =>
      'Sincronizarea cloud va fi dezactivată. Datele dvs. locale (favorite, alerte, istoric) sunt păstrate pe acest dispozitiv. Datele de pe server nu sunt șterse.';

  @override
  String get deleteAccountTitle => 'Ștergeți contul?';

  @override
  String get deleteAccountBody =>
      'Aceasta șterge permanent toate datele dvs. de pe server (favorite, alerte, evaluări, rute). Datele locale de pe acest dispozitiv sunt păstrate.\n\nAceastă acțiune nu poate fi anulată.';

  @override
  String get switchToAnonymousTitle => 'Treceți la anonim?';

  @override
  String get switchToAnonymousBody =>
      'Veți fi deconectat din contul de email și veți continua cu o sesiune anonimă nouă.\n\nDatele locale (favorite, alerte) sunt păstrate pe acest dispozitiv și vor fi sincronizate cu noul cont anonim.';

  @override
  String get switchAction => 'Comutați';

  @override
  String get helpBannerCriteria =>
      'Setările implicite ale profilului sunt precompletate. Ajustați criteriile de mai jos pentru a rafina căutarea.';

  @override
  String get helpBannerAlerts =>
      'Setați un prag de preț pentru o stație. Veți fi notificat când prețurile scad sub acesta. Verificările se efectuează la fiecare 30 de minute.';

  @override
  String get helpBannerConsumption =>
      'Înregistrați fiecare alimentare pentru a urmări consumul real și amprenta de CO₂. Glisați stânga pentru a șterge o intrare.';

  @override
  String get helpBannerVehicles =>
      'Adăugați vehiculele pentru ca alimentările și preferințele de combustibil să fie precompletate corect. Primul vehicul devine cel implicit.';

  @override
  String get syncNow => 'Sincronizați acum';

  @override
  String get onboardingPreferencesTitle => 'Preferințele dvs.';

  @override
  String get onboardingZipHelper => 'Folosit când GPS-ul nu este disponibil';

  @override
  String get onboardingRadiusHelper => 'Rază mai mare = mai multe rezultate';

  @override
  String get onboardingPrivacy =>
      'Aceste setări sunt stocate doar pe dispozitivul dvs. și nu sunt niciodată partajate.';

  @override
  String get onboardingLandingTitle => 'Ecranul principal';

  @override
  String get onboardingLandingHint =>
      'Alegeți ce ecran se deschide când lansați aplicația.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Stați departe de aplicație — dar nu o închideți.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Deschideți Sparkilo o dată după fiecare repornire.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple activează Sparkilo doar după ce l-ați deschis cel puțin o dată de la ultima repornire a telefonului. După aceea, călătoriile dvs. sunt înregistrate automat.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Nu închideți forțat Sparkilo din comutătorul de aplicații.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Forțarea închiderii\" îi spune iOS să nu mai relanseze aplicația. Călătoriile dvs. nu vor mai fi înregistrate până când nu deschideți din nou Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Când iOS cere locație \"Întotdeauna\", vă rugăm să spuneți da.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Mecanismul de rezervă care înregistrează călătoria când adaptorul OBD2 este lent necesită locație în fundal. Nu o partajăm niciodată.';

  @override
  String get scanReceipt => 'Scanați bonul';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Combustibil';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Autostradă';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Privat';

  @override
  String get ratingModeShared => 'Partajat';

  @override
  String get ratingDescLocal => 'Evaluări salvate doar pe acest dispozitiv';

  @override
  String get ratingDescPrivate =>
      'Sincronizate cu baza dvs. de date (invizibile pentru alții)';

  @override
  String get ratingDescShared =>
      'Vizibile pentru toți utilizatorii bazei dvs. de date';

  @override
  String get errorNoEvApiKey =>
      'Cheia API OpenChargeMap nu este configurată. Adăugați una în Setări pentru a căuta stații de încărcare EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Furnizorul de date ($host) servește un certificat TLS expirat sau invalid. Aplicația nu poate încărca date din această sursă până când furnizorul nu rezolvă problema. Contactați $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed indisponibil. Se folosește $current.';
  }

  @override
  String get errorTitleApiKey => 'Cheie API necesară';

  @override
  String get errorTitleLocation => 'Locație indisponibilă';

  @override
  String get errorHintNoStations =>
      'Încercați să măriți raza de căutare sau căutați o altă locație.';

  @override
  String get errorHintApiKey => 'Configurați cheia API în Setări.';

  @override
  String get errorHintConnection =>
      'Verificați conexiunea la internet și încercați din nou.';

  @override
  String get errorHintRouting =>
      'Calculul rutei a eșuat. Verificați conexiunea la internet și încercați din nou.';

  @override
  String get errorHintFallback =>
      'Încercați din nou sau căutați după cod poștal / nume de oraș.';

  @override
  String get alertsLoadErrorTitle => 'Nu s-au putut încărca alertele';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Verificarea alertei în fundal a eșuat';

  @override
  String get detailsLabel => 'Detalii';

  @override
  String get remove => 'Eliminați';

  @override
  String get showKey => 'Afișați cheia';

  @override
  String get hideKey => 'Ascundeți cheia';

  @override
  String get syncOptionalTitle => 'TankSync este opțional';

  @override
  String get syncOptionalDescription =>
      'Aplicația funcționează complet fără sincronizare cloud. TankSync vă permite să sincronizați favorite, alerte și evaluări pe mai multe dispozitive folosind Supabase (nivel gratuit disponibil).';

  @override
  String get syncHowToConnectQuestion => 'Cum doriți să vă conectați?';

  @override
  String get syncCreateOwnTitle => 'Creați propria bază de date';

  @override
  String get syncCreateOwnSubtitle =>
      'Proiect Supabase gratuit — vă ghidăm pas cu pas';

  @override
  String get syncJoinExistingTitle =>
      'Alăturați-vă unei baze de date existente';

  @override
  String get syncJoinExistingSubtitle =>
      'Scanați codul QR de la proprietarul bazei de date sau lipiți credențialele';

  @override
  String get syncChooseAccountType => 'Alegeți tipul de cont';

  @override
  String get syncAccountTypeAnonymous => 'Anonim';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Instant, fără email. Datele legate de acest dispozitiv.';

  @override
  String get syncAccountTypeEmail => 'Cont cu email';

  @override
  String get syncAccountTypeEmailDesc =>
      'Conectați-vă de pe orice dispozitiv. Recuperați datele dacă telefonul se pierde.';

  @override
  String get syncHaveAccountSignIn => 'Aveți deja un cont? Conectați-vă';

  @override
  String get syncCreateNewAccount => 'Creați cont nou';

  @override
  String get syncTestConnection => 'Testați conexiunea';

  @override
  String get syncTestingConnection => 'Se testează...';

  @override
  String get syncConnectButton => 'Conectați';

  @override
  String get syncConnectingButton => 'Se conectează...';

  @override
  String get syncDatabaseReady => 'Baza de date este gata!';

  @override
  String get syncDatabaseNeedsSetup => 'Baza de date necesită configurare';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Lipsă';

  @override
  String get syncSqlEditorInstructions =>
      'Copiați SQL-ul de mai jos și rulați-l în editorul SQL Supabase (Tablou de bord → SQL Editor → Interogare nouă → Lipiți → Rulați)';

  @override
  String get syncCopySqlButton => 'Copiați SQL în clipboard';

  @override
  String get syncRecheckSchemaButton => 'Reverificați schema';

  @override
  String get syncDoneButton => 'Gata';

  @override
  String syncSignedInAs(String email) {
    return 'Autentificat ca $email';
  }

  @override
  String get syncEmailDescription =>
      'Datele dvs. se sincronizează pe toate dispozitivele cu acest email.';

  @override
  String get syncSwitchToAnonymousTitle => 'Treceți la anonim';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continuați fără email, sesiune anonimă nouă';

  @override
  String get syncGuestDescription => 'Anonim, fără email.';

  @override
  String get syncOrDivider => 'sau';

  @override
  String get syncHowToSyncQuestion => 'Cum doriți să sincronizați?';

  @override
  String get syncOfflineDescription =>
      'Aplicația funcționează complet offline. Sincronizarea cloud este opțională.';

  @override
  String get syncModeCommunityTitle => 'Comunitatea Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Partajați favorite și evaluări cu toți utilizatorii';

  @override
  String get syncModePrivateTitle => 'Bază de date privată';

  @override
  String get syncModePrivateSubtitle =>
      'Propriul Supabase — control total al datelor';

  @override
  String get syncModeGroupTitle => 'Alăturați-vă unui grup';

  @override
  String get syncModeGroupSubtitle =>
      'Bază de date partajată cu familia sau prietenii';

  @override
  String get syncPrivacyShared => 'Partajat';

  @override
  String get syncPrivacyPrivate => 'Privat';

  @override
  String get syncPrivacyGroup => 'Grup';

  @override
  String get syncStayOfflineButton => 'Rămâneți offline';

  @override
  String get syncSuccessTitle => 'Conectat cu succes!';

  @override
  String get syncSuccessDescription =>
      'Datele dvs. se vor sincroniza acum automat.';

  @override
  String get syncWizardTitleConnect => 'Conectați TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Baza dvs. de date';

  @override
  String get syncSetupTitleJoinGroup => 'Alăturați-vă unui grup';

  @override
  String get syncSetupTitleAccount => 'Contul dvs.';

  @override
  String get syncWizardBack => 'Înapoi';

  @override
  String get syncWizardNext => 'Înainte';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Pasul $current din $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Creați un proiect Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Apăsați \"Deschideți Supabase\" mai jos\n2. Creați un cont gratuit (dacă nu aveți unul)\n3. Apăsați \"New Project\"\n4. Alegeți un nume și o regiune\n5. Așteptați ~2 minute pentru pornire';

  @override
  String get syncWizardOpenSupabase => 'Deschideți Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Activați autentificarea anonimă';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. În tabloul de bord Supabase:\n   Authentication → Providers\n2. Găsiți \"Anonymous Sign-ins\"\n3. Activați-l\n4. Apăsați \"Save\"';

  @override
  String get syncWizardOpenAuthSettings =>
      'Deschideți setările de autentificare';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copiați credențialele';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Mergeți la Settings → API în tabloul de bord\n2. Copiați \"Project URL\"\n3. Copiați cheia \"anon public\"\n4. Lipiți-le mai jos';

  @override
  String get syncWizardOpenApiSettings => 'Deschideți setările API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Alăturați-vă unei baze de date existente';

  @override
  String get syncWizardScanQrCode => 'Scanați codul QR';

  @override
  String get syncWizardAskOwnerQr =>
      'Rugați proprietarul bazei de date să vă arate codul QR\n(Setări → TankSync → Partajare)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Rugați proprietarul bazei de date să vă arate codul QR';

  @override
  String get syncWizardEnterManuallyTitle => 'Introduceți manual';

  @override
  String get syncWizardOrEnterManually => 'sau introduceți manual';

  @override
  String get syncWizardUrlHelperText =>
      'Spațiile și întreruperile de linie sunt eliminate automat';

  @override
  String get syncCredentialsPrivateHint =>
      'Introduceți credențialele proiectului Supabase. Le găsiți în tabloul de bord la Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL bază de date';

  @override
  String get syncCredentialsAccessKeyLabel => 'Cheie de acces';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Parolă';

  @override
  String get authConfirmPasswordLabel => 'Confirmați parola';

  @override
  String get authPleaseEnterEmail => 'Introduceți adresa de email';

  @override
  String get authInvalidEmail => 'Adresă de email invalidă';

  @override
  String get authPasswordsDoNotMatch => 'Parolele nu coincid';

  @override
  String get authConnectAnonymously => 'Conectați-vă anonim';

  @override
  String get authCreateAccountAndConnect => 'Creați cont și conectați';

  @override
  String get authSignInAndConnect => 'Autentificați-vă și conectați';

  @override
  String get authAnonymousSegment => 'Anonim';

  @override
  String get authEmailSegment => 'Email';

  @override
  String get authAnonymousDescription =>
      'Acces instant, fără email. Datele legate de acest dispozitiv.';

  @override
  String get authEmailDescription =>
      'Conectați-vă de pe orice dispozitiv. Recuperați datele dacă telefonul se pierde.';

  @override
  String get authSyncAcrossDevices =>
      'Sincronizați datele automat pe toate dispozitivele dvs.';

  @override
  String get authNewHereCreateAccount => 'Nou aici? Creați cont';

  @override
  String get linkDeviceScreenTitle => 'Conectați dispozitivul';

  @override
  String get linkDeviceThisDeviceLabel => 'Acest dispozitiv';

  @override
  String get linkDeviceShareCodeHint =>
      'Partajați acest cod cu celălalt dispozitiv:';

  @override
  String get linkDeviceNotConnected => 'Neconectat';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copiați codul';

  @override
  String get linkDeviceImportSectionTitle => 'Importați de pe alt dispozitiv';

  @override
  String get linkDeviceImportDescription =>
      'Introduceți codul dispozitivului de pe celălalt dispozitiv pentru a importa favoritele, alertele, vehiculele și jurnalul de consum. Fiecare dispozitiv își păstrează propriul profil și setările implicite.';

  @override
  String get linkDeviceCodeFieldLabel => 'Codul dispozitivului';

  @override
  String get linkDeviceCodeFieldHint =>
      'Lipiți UUID-ul de pe celălalt dispozitiv';

  @override
  String get linkDeviceImportButton => 'Importați datele';

  @override
  String get linkDeviceHowItWorksTitle => 'Cum funcționează';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Pe Dispozitivul A: copiați codul dispozitivului de mai sus\n2. Pe Dispozitivul B: lipiți-l în câmpul \"Codul dispozitivului\"\n3. Apăsați \"Importați datele\" pentru a combina favoritele, alertele, vehiculele și jurnalele de consum\n4. Ambele dispozitive vor avea toate datele combinate\n\nFiecare dispozitiv își păstrează propria identitate anonimă și propriul profil (combustibil preferat, vehicul implicit, ecran de start). Datele sunt combinate, nu mutate.';

  @override
  String get vehicleSetActive => 'Setați ca activ';

  @override
  String get swipeHide => 'Ascundeți';

  @override
  String get evChargingSection => 'Încărcare EV';

  @override
  String get fuelStationsSection => 'Stații de combustibil';

  @override
  String get yourRating => 'Evaluarea dvs.';

  @override
  String get noStorageUsed => 'Niciun spațiu utilizat';

  @override
  String get aboutReportBug => 'Raportați un bug / Sugerați o funcționalitate';

  @override
  String get aboutSupportProject => 'Susțineți acest proiect';

  @override
  String get aboutSupportDescription =>
      'Această aplicație este gratuită, open source și fără reclame. Dacă o găsiți utilă, luați în considerare susținerea dezvoltatorului.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Prețurile combustibililor din Luxembourg sunt reglementate de guvern și uniforme la nivel național.';

  @override
  String get luxembourgFuelUnleaded95 => 'Fără plumb 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Fără plumb 98';

  @override
  String get luxembourgFuelDiesel => 'Motorină';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Prețurile reglementate din Luxembourg sunt indisponibile.';

  @override
  String get reportIssueTitle => 'Raportați o problemă';

  @override
  String get enterCorrection => 'Introduceți corecția';

  @override
  String get reportNoBackendAvailable =>
      'Raportul nu a putut fi trimis: nu este configurat niciun serviciu de raportare pentru această țară. Activați TankSync în Setări pentru a trimite rapoarte comunității.';

  @override
  String get correctName => 'Corectați numele stației';

  @override
  String get correctAddress => 'Corectați adresa';

  @override
  String get wrongE85Price => 'Preț E85 incorect';

  @override
  String get wrongE98Price => 'Preț Super 98 incorect';

  @override
  String get wrongLpgPrice => 'Preț LPG incorect';

  @override
  String get wrongStationName => 'Nume stație incorect';

  @override
  String get wrongStationAddress => 'Adresă incorectă';

  @override
  String get independentStation => 'Stație independentă';

  @override
  String get serviceRemindersSection => 'Mementouri de service';

  @override
  String get serviceRemindersEmpty =>
      'Niciun memento încă — alegeți un preset de mai sus.';

  @override
  String get addServiceReminder => 'Adăugați memento';

  @override
  String get serviceReminderPresetOil => 'Ulei (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Schimb ulei';

  @override
  String get serviceReminderPresetTires => 'Anvelope (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Anvelope';

  @override
  String get serviceReminderPresetInspection => 'Inspecție (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Inspecție';

  @override
  String get serviceReminderLabel => 'Etichetă';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Ultimul service';

  @override
  String get serviceReminderMarkDone => 'Marcați ca efectuat';

  @override
  String get serviceReminderDueTitle => 'Service scadent';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label este scadent — $kmOver km peste interval.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Înregistrați-vă la OPINET pentru a obține o cheie API gratuită';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Înregistrați-vă la CNE pentru a obține o cheie API gratuită';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Aceasta este mașina dvs.?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders cilindri, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Informații parțiale (offline). Puteți edita mai jos.';

  @override
  String get vinDecodeError => 'Nu s-a putut decoda VIN-ul';

  @override
  String get vinInvalidFormat => 'Format VIN invalid';

  @override
  String get obd2PauseBannerTitle =>
      'Conexiune OBD2 pierdută — înregistrare în pauză';

  @override
  String get obd2PauseBannerResume => 'Reluați înregistrarea';

  @override
  String get obd2PauseBannerEnd => 'Terminați înregistrarea';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Calibrarea consumului actualizată pentru $vehicleName — precizie îmbunătățită cu $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Resetați eficiența volumetrică?';

  @override
  String get veResetConfirmBody =>
      'Aceasta va elimina eficiența volumetrică (η_v) învățată și va restaura valoarea implicită (0.85). Estimările de debit combustibil la nivel de călătorie vor reveni la constanta producătorului până când calibratorul colectează noi eșantioane din viitoarele călătorii.';

  @override
  String get alertsRadiusSectionTitle => 'Alerte de rază';

  @override
  String get alertsRadiusAdd => 'Adăugați alertă de rază';

  @override
  String get alertsRadiusEmptyTitle => 'Nicio alertă de rază încă';

  @override
  String get alertsRadiusEmptyCta => 'Creați o alertă de rază';

  @override
  String get alertsRadiusCreateTitle => 'Creați alertă de rază';

  @override
  String get alertsRadiusLabelHint => 'Etichetă (ex. Motorină acasă)';

  @override
  String get alertsRadiusFuelType => 'Tip combustibil';

  @override
  String get alertsRadiusThreshold => 'Prag (€/L)';

  @override
  String get alertsRadiusKm => 'Rază (km)';

  @override
  String get alertsRadiusCenterGps => 'Utilizați locația mea';

  @override
  String get alertsRadiusCenterPostalCode => 'Cod poștal';

  @override
  String get alertsRadiusSave => 'Salvați';

  @override
  String get alertsRadiusCancel => 'Anulare';

  @override
  String get alertsRadiusDeleteConfirm => 'Ștergeți alerta de rază?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 conectat: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Asociați un adaptor OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel a scăzut la stații din apropiere';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stații au scăzut cu până la $maxDropCents¢ în ultima oră';
  }

  @override
  String get fillUpSavedSnackbar => 'Alimentare salvată';

  @override
  String get radiusAlertsEntryTitle => 'Alerte de rază și statistici';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Fiți notificat când prețurile scad în zona dvs.';

  @override
  String get notFoundTitle => 'Pagina nu a fost găsită';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nu a fost găsit.';
  }

  @override
  String get notFoundHomeButton => 'Acasă';

  @override
  String get consumptionTabHiddenNotice =>
      'Fila Consum a fost ascunsă de setările profilului dvs.';

  @override
  String get swipeBetweenTabsHint =>
      'Sfat: glisați stânga sau dreapta pentru a comuta între file.';

  @override
  String get discardChangesTitle => 'Renunțați la modificări?';

  @override
  String get discardChangesBody =>
      'Aveți modificări nesalvate. Dacă plecați acum, acestea vor fi pierdute.';

  @override
  String get discardChangesConfirm => 'Renunțați';

  @override
  String get discardChangesKeepEditing => 'Continuați editarea';

  @override
  String get tankSyncSectionSubtitle =>
      'Sincronizare cloud pe dispozitivele dvs.';

  @override
  String get mapUnavailable => 'Hartă indisponibilă';

  @override
  String get routeNameHintExample => 'de ex. Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Curent';

  @override
  String get tankerkoenigApiKeyLabel => 'Cheie API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Cheie API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition =>
      'Atingeți pentru a actualiza poziția GPS';

  @override
  String get nameLabel => 'Nume';

  @override
  String get obd2ErrorPermissionDenied =>
      'Este necesară permisiunea Bluetooth pentru a vă conecta la un adaptor OBD2.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Activați Bluetooth și încercați din nou.';

  @override
  String get obd2ErrorScanTimeout =>
      'Nu s-a găsit niciun adaptor OBD2 în apropiere. Asigurați-vă că este conectat și pornit.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Adaptorul OBD2 nu a răspuns. Porniți contactul și încercați din nou.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adaptorul OBD2 a trimis un răspuns nerecunoscut. Poate fi incompatibil — încercați alt adaptor.';

  @override
  String get obd2ErrorDisconnected =>
      'Adaptorul OBD2 s-a deconectat. Reconectați-vă și încercați din nou.';

  @override
  String get onboardingExploreDemoData => 'Explorează cu date demo';

  @override
  String get achievementSmoothDriver => 'Serie de condus lin';

  @override
  String get achievementSmoothDriverDesc =>
      'Conduceți 5 călătorii consecutive cu un scor de condus lin de 80 sau mai mult.';

  @override
  String get achievementColdStartAware => 'Conștient de pornire la rece';

  @override
  String get achievementColdStartAwareDesc =>
      'Mențineți costul combustibilului de pornire la rece dintr-o lună întreagă sub 2% din total — combinați călătoriile scurte.';

  @override
  String get achievementHighwayMaster => 'Maestru de autostradă';

  @override
  String get achievementHighwayMasterDesc =>
      'Finalizați o călătorie de 30+ km la viteză constantă cu un scor de condus lin de 90 sau mai mult.';

  @override
  String get alertGatingNonDeStationWarning =>
      'Alertele de preț în fundal funcționează momentan doar pentru stațiile din Germania. Această alertă va fi salvată, dar este posibil să nu vă notifice niciodată până când vor fi disponibile alertele între țări.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Alertele pe rază verifică momentan doar stațiile din Germania.';

  @override
  String get approachOverlaySection => 'Suprapunere la apropierea de stație';

  @override
  String get approachRadiusLabel => 'Rază';

  @override
  String approachRadiusCaption(String km) {
    return 'Suprapunerea se mărește și afișează prețul când ești la $km km de o stație';
  }

  @override
  String get approachPriceModeLabel => 'Afișează prețul pentru';

  @override
  String get approachPriceModeNearest => 'Stația cea mai apropiată';

  @override
  String get approachPriceModeCheapestInRadius => 'Cea mai ieftină din rază';

  @override
  String get approachMinPollLabel => 'Reîmprospătare min.';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Limita inferioară a reîmprospătării celei mai apropiate stații (mai rapid la viteză, niciodată mai des de $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testează suprapunerea de apropiere';

  @override
  String get approachTestStopButton => 'Oprește testul';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test activ — suprapunerea afișează prețul pentru $station';
  }

  @override
  String get approachTestUnavailable =>
      'Adăugați o stație preferată pentru a testa suprapunerea de apropiere';

  @override
  String approachStationDistance(String meters) {
    return 'la $meters m';
  }

  @override
  String get authErrorNoNetwork =>
      'Nicio conexiune la rețea. Încercați mai târziu.';

  @override
  String get authErrorInvalidCredentials =>
      'Email sau parolă incorectă. Verificați credențialele.';

  @override
  String get authErrorUserAlreadyExists =>
      'Acest email este deja înregistrat. Încercați să vă conectați.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Vă rugăm să vă verificați emailul și să confirmați contul mai întâi.';

  @override
  String get authErrorGeneric =>
      'Autentificarea a eșuat. Vă rugăm să încercați din nou.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Locație în fundal — numai pentru înregistrare automată';

  @override
  String get autoRecordConsentExplanationTitle => 'Despre această permisiune';

  @override
  String get autoRecordConsentExplanationBody =>
      'Înregistrarea automată necesită locație în fundal pentru a detecta când începeți să conduceți cu aplicația închisă. Această permisiune este utilizată numai de înregistrarea automată — căutarea stațiilor și centrarea hărții folosesc o permisiune de locație separată în prim-plan.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Am înțeles';

  @override
  String get autoRecordConsentExplanationTooltip => 'Ce înseamnă aceasta?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Apăsați pentru a gestiona în setările sistemului';

  @override
  String get autoRecordSectionTitle => 'Înregistrare automată';

  @override
  String get autoRecordToggleLabel => 'Înregistrare automată a călătoriilor';

  @override
  String get autoRecordStatusActiveLabel =>
      'Înregistrarea automată se va activa data viitoare când intrați în mașină.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Asociați un adaptor OBD2 pentru a activa înregistrarea automată.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Permiteți locația în fundal pentru ca înregistrarea automată să continue cu ecranul oprit.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Asociați un adaptor';

  @override
  String get autoRecordSpeedThresholdLabel => 'Viteză de pornire (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Întârziere salvare după deconectare (secunde)';

  @override
  String get autoRecordPairedAdapterLabel => 'Adaptor asociat';

  @override
  String get autoRecordPairedAdapterNone =>
      'Niciun adaptor asociat. Asociați unul mai întâi prin configurarea OBD2.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Locație în fundal permisă';

  @override
  String get autoRecordBackgroundLocationRequest => 'Solicitați permisiunea';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'De ce \"Permite întotdeauna\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Înregistrarea automată transmite coordonate GPS din serviciul de prim-plan OBD-II cu ecranul oprit, astfel încât ruta călătoriei să rămână precisă. Android necesită opțiunea \"Permite întotdeauna\" pentru ca aceasta să continue să funcționeze după blocarea dispozitivului.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Deschideți setările';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Permisiunea de locație este necesară';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nu s-a putut solicita locația în fundal';

  @override
  String get autoRecordBadgeClearTooltip => 'Resetați contorul';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Asociați un adaptor în secțiunea de mai jos pentru a activa înregistrarea automată';

  @override
  String get exportBackupTooltip => 'Exportați backup';

  @override
  String get exportBackupReady => 'Backup gata — alegeți destinația';

  @override
  String get exportBackupFailed =>
      'Exportul backup-ului a eșuat — vă rugăm să încercați din nou';

  @override
  String get brokenMapChipVerifying => 'Se verifică senzorul MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Citiri MAP suspecte';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Senzorul MAP citește incorect — citirile de combustibil pot fi cu 50–80% prea mici. Încercați un adaptor diferit.';

  @override
  String get brokenMapBannerHardDisable =>
      'Senzorul MAP este nesigur. Se afișează mediile de alimentare în loc de debitul live de combustibil.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Senzor MAP: verificat ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Senzor MAP: se verifică ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Senzor MAP: suspect ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Senzor MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Senzor MAP: $posterior% ± $margin% (verificat)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostice senzor MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Probabilitate MAP defect: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observații înregistrate';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verificat curat';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Senzorul MAP al acestui vehicul nu a fost observat încă.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Adaptoare în lista de blocare';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Niciun adaptor în lista de blocare.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — marcat $percent% defect';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Ștergeți';

  @override
  String get brokenMapRevPromptTitle => 'Accelerați motorul';

  @override
  String get brokenMapRevPromptBody =>
      'Apăsați scurt acceleratorul pentru ca aplicația să verifice că senzorul MAP răspunde.';

  @override
  String get brokenMapRevPromptConfirm => 'Gata — am accelerat';

  @override
  String get calibrationAdvancedTitle => 'Calibrare avansată';

  @override
  String get calibrationDisplacementLabel => 'Cilindree motor (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Eficiență volumetrică (η_v)';

  @override
  String get calibrationAfrLabel => 'Raport aer-combustibil (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Densitate combustibil (g/L)';

  @override
  String get calibrationSourceDetected => '(detectat din VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(implicit)';

  @override
  String get calibrationSourceManual => '(manual)';

  @override
  String get calibrationResetToDetected => 'Resetați la valoarea detectată';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (calibrat, $samples eșantioane)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (se învață, $samples eșantioane)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (implicit — niciun plein-complet încă)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples mostre';
  }

  @override
  String get calibrationResetLearner => 'Resetați calibratorul';

  @override
  String get calibrationBasisAtkinson => 'Ciclu Atkinson';

  @override
  String get calibrationBasisVnt => 'Diesel VNT + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbocompresor + DI';

  @override
  String get calibrationBasisTurbo => 'Turbocompresor';

  @override
  String get calibrationBasisNaDi => 'Aspirat natural + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catalog: $makeModel — implicit $basis)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Vehiculul dvs. $makeModel este marcat ca diesel, dar corespunde unei intrări din catalog pentru benzină. Apăsați pentru actualizare.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Actualizați';

  @override
  String get consumptionTabFuel => 'Combustibil';

  @override
  String get consumptionTabCharging => 'Încărcare';

  @override
  String get noChargingLogsTitle => 'Niciun jurnal de încărcare încă';

  @override
  String get noChargingLogsSubtitle =>
      'Înregistrați prima sesiune de încărcare pentru a urmări EUR/100 km și kWh/100 km.';

  @override
  String get addChargingLog => 'Înregistrați încărcarea';

  @override
  String get addChargingLogTitle => 'Înregistrați sesiunea de încărcare';

  @override
  String get chargingKwh => 'Energie (kWh)';

  @override
  String get chargingCost => 'Cost total';

  @override
  String get chargingTimeMin => 'Timp de încărcare (min)';

  @override
  String get chargingStationName => 'Stație (opțional)';

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
      'Este necesar un jurnal anterior pentru comparație';

  @override
  String get chargingLogButtonLabel => 'Înregistrați încărcarea';

  @override
  String get chargingCostTrendTitle => 'Tendința costului de încărcare';

  @override
  String get chargingEfficiencyTitle => 'Eficiență (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Date insuficiente încă';

  @override
  String get chargingChartsMonthAxis => 'Luna';

  @override
  String get consoFeatureGroupTitle => 'Conso';

  @override
  String get consoFeatureGroupDescription =>
      'Urmăriți consumul — alimentări manuale sau înregistrare automată de călătorii OBD2.';

  @override
  String get consoModeOff => 'Oprit';

  @override
  String get consoModeFuel => 'Combustibil';

  @override
  String get consoModeFuelAndTrips => 'Combustibil + Călătorii';

  @override
  String get consoModeOffDescription =>
      'Fără fila Conso și fără secțiunea de setări Conso.';

  @override
  String get consoModeFuelDescription =>
      'Numai alimentări manuale. Util fără adaptor OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Adaugă înregistrarea automată a călătoriilor OBD2. Necesită un adaptor asociat.';

  @override
  String get consoSubsectionVehicles => 'Vehiculele mele';

  @override
  String get consoSubsectionTrajets => 'Călătorii (OBD2)';

  @override
  String get consoSubsectionToggles => 'Condus';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Precizie: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Ridicată';

  @override
  String get consumptionAccuracyMedium => 'Medie';

  @override
  String get consumptionAccuracyLow => 'Scăzută';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Calibrare completă: alimentări plus călătorii înregistrate cu OBD2. Valoarea L/100 km urmărește realitatea în limita câtorva procente.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Alimentările au ancorat modelul de consum, dar nicio călătorie OBD2 nu a fost încă procesată. Înregistrează una cu OBD2 conectat pentru a atinge precizia ridicată.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Doar GPS — nicio alimentare nu a ancorat încă modelul de consum. Adaugă câteva alimentări complete pentru a îmbunătăți precizia.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count alimentări parțiale în așteptarea plein complet — nu în medie',
      one: '1 alimentare parțială în așteptarea plein complet — nu în medie',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% din combustibil provine din corecții automate — revizuiți intrările';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Corecție automată — apăsați pentru a edita';

  @override
  String get fillUpCorrectionEditTitle => 'Editați corecția automată';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Această intrare a fost generată automat pentru a închide diferența dintre călătoriile înregistrate și combustibilul pompat. Ajustați valorile dacă cunoașteți cifrele reale.';

  @override
  String get fillUpCorrectionDelete => 'Ștergeți corecția';

  @override
  String get fillUpCorrectionStation => 'Nume stație (opțional)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grecia)';

  @override
  String get greeceCommunityApiNotice =>
      'Alimentat de API-ul fuelpricesgr întreținut de comunitate';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (România)';

  @override
  String get romaniaScrapingNotice =>
      'Alimentat de pretcarburant.ro (Consiliul Concurenței + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stații în $country la $km km distanță — cu €$price/L mai ieftin';
  }

  @override
  String get crossBorderTapToSwitch => 'Apăsați pentru a schimba țara';

  @override
  String get crossBorderDismissTooltip => 'Respingeți';

  @override
  String dataSourceAttribution(String source, String license) {
    return 'Sursă: $source ($license)';
  }

  @override
  String dataSourceAttributionSemantic(String source, String license) {
    return 'Datele privind prețurile carburanților sunt furnizate de $source, licențiate sub $license.';
  }

  @override
  String get developerToolsSectionTitle => 'Instrumente pentru dezvoltatori';

  @override
  String get developerToolsSubtitle =>
      'Diagnosticare și instrumente de depanare — vizibile doar în modul dezvoltator / depanare.';

  @override
  String get developerToolsMenuSubtitle =>
      'Jurnal de erori, alerte de test, diagnosticare';

  @override
  String get developerToolsErrorLogGroupTitle => 'Jurnal de erori';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Salvează jurnalul de erori ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Șterge jurnalul de erori';

  @override
  String get developerToolsViewErrorLog => 'Vezi jurnalul de erori';

  @override
  String get developerToolsErrorLogEmpty =>
      'Nicio urmă de eroare înregistrată.';

  @override
  String get developerToolsAlertsGroupTitle => 'Alerte și notificări';

  @override
  String get developerToolsFireTestNotification =>
      'Trimite o notificare de test';

  @override
  String get developerToolsTestNotificationTitle => 'Notificare de test';

  @override
  String get developerToolsTestNotificationBody =>
      'Dacă poți citi asta, notificările funcționează.';

  @override
  String get developerToolsTestNotificationSent =>
      'Notificare de test trimisă.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Notificările sunt blocate — activează-le din setările sistemului, apoi reîncearcă.';

  @override
  String get developerToolsRunTestAlert => 'Rulează fluxul de alertă de test';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Alertă de test declanșată — fluxul a livrat $count notificare(i).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Alertă de preț de test';

  @override
  String get developerToolsTestAlertBody =>
      'Potrivire sintetică: a fost găsită în apropiere o stație sub ținta ta.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnosticare';

  @override
  String get developerToolsFeatureFlagDump =>
      'Inspector de indicatori de funcții';

  @override
  String get developerToolsFlagOn => 'Activat';

  @override
  String get developerToolsFlagOff => 'Dezactivat';

  @override
  String get developerToolsClearCaches => 'Golește memoriile cache';

  @override
  String get developerToolsCachesCleared => 'Memorii cache golite.';

  @override
  String get developerToolsCopyDiagnostics => 'Copiază diagnosticarea';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnosticare copiată în clipboard.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Informații despre compilare';

  @override
  String get developerToolsBuildVersion => 'Versiunea aplicației';

  @override
  String get developerToolsBuildChannel => 'Canal de compilare';

  @override
  String get insightCardTitle => 'Cele mai risipitoare comportamente';

  @override
  String get insightEmptyState =>
      'Nicio ineficiență notabilă — continuați tot așa!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor peste 3000 RPM ($pctTime% din călătorie): $liters L risipiți';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count accelerări bruște: $liters L risipiți';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Ralanti ($pctTime% din călătorie): $liters L risipiți';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% din călătorie';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Mersul în treaptă mică ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Opriți motorul la opririle lungi în loc să-l lăsați la ralanti.';

  @override
  String get lessonAdviceHighRpm =>
      'Schimbați mai devreme într-o treaptă superioară pentru a menține motorul în afara zonei de turații înalte.';

  @override
  String get lessonAdviceHardAccel =>
      'Apăsați lin pedala de accelerație — o accelerare uniformă consumă mai puțin combustibil.';

  @override
  String get lessonAdviceLowGear =>
      'Schimbați mai devreme într-o treaptă superioară pentru ca motorul să funcționeze la turații mai mici și mai economice.';

  @override
  String get drivingScoreCardTitle => 'Scor de condus';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Scor compus din ralanti, accelerări bruște, frânări bruște și timp la RPM ridicat. O comparație \'mai bun decât X% din călătoriile anterioare\' va apărea într-o versiune viitoare.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Scor de condus $score din 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Ralanti';

  @override
  String get drivingScorePenaltyHardAccel => 'Accelerări bruște';

  @override
  String get drivingScorePenaltyHardBrake => 'Frânări bruște';

  @override
  String get drivingScorePenaltyHighRpm => 'RPM ridicat';

  @override
  String get drivingScorePenaltyFullThrottle => 'Accelerator la maxim';

  @override
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L economisiți';
  }

  @override
  String get ecoRouteHint =>
      'Condus mai inteligent — favorizează autostrada constantă față de scurtăturile în zigzag.';

  @override
  String get favoritesShareAction => 'Partajați';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favorite din $date';
  }

  @override
  String get favoritesShareError => 'Nu s-a putut genera imaginea de partajare';

  @override
  String get featureManagementSectionTitle => 'Gestionarea funcționalităților';

  @override
  String get featureManagementSectionSubtitle =>
      'Activați sau dezactivați funcționalitățile individuale. Unele funcționalități depind de altele — comutatoarele sunt dezactivate până când condițiile prealabile sunt îndeplinite.';

  @override
  String get featureLabel_obd2TripRecording => 'Înregistrare călătorii OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Capturați călătorii automat prin OBD2.';

  @override
  String get featureLabel_gamification => 'Gamificare';

  @override
  String get featureDescription_gamification =>
      'Scoruri de condus și insigne câștigate.';

  @override
  String get featureLabel_hapticEcoCoach => 'Eco-coach haptic';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Feedback haptic în timp real în timpul unei călătorii.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sincronizare între dispozitive prin Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analitica consumului';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Fila de analiză a alimentărilor și călătoriilor.';

  @override
  String get featureLabel_baselineSync => 'Sincronizare referință';

  @override
  String get featureDescription_baselineSync =>
      'Sincronizați referințele de condus prin TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Rezultate de căutare unificate';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Listă unică de rezultate combinând stații de combustibil și EV.';

  @override
  String get featureLabel_priceAlerts => 'Alerte de prețuri';

  @override
  String get featureDescription_priceAlerts =>
      'Notificări de scădere a prețului bazate pe prag.';

  @override
  String get featureLabel_priceHistory => 'Istoricul prețurilor';

  @override
  String get featureDescription_priceHistory =>
      'Grafice de 30 de zile ale prețurilor în detaliile stației.';

  @override
  String get featureLabel_routePlanning => 'Planificare rută';

  @override
  String get featureDescription_routePlanning =>
      'Cea mai ieftină oprire de-a lungul rutei dvs.';

  @override
  String get featureLabel_evCharging => 'Încărcare EV';

  @override
  String get featureDescription_evCharging =>
      'Stații de încărcare prin OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Ghidare hypermiling folosind semafoarele OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Traseul GPS al călătoriei';

  @override
  String get featureDescription_gpsTripPath =>
      'Stocați eșantioane GPS alături de fiecare călătorie.';

  @override
  String get featureLabel_autoRecord => 'Înregistrare automată';

  @override
  String get featureDescription_autoRecord =>
      'Porniți automat o călătorie când adaptorul OBD2 se conectează la un vehicul în mișcare.';

  @override
  String get featureLabel_showFuel => 'Afișați stații de combustibil';

  @override
  String get featureDescription_showFuel =>
      'Afișați rezultate cu stații de benzină/motorină în căutare și pe hartă.';

  @override
  String get featureLabel_showElectric => 'Afișați stații de încărcare';

  @override
  String get featureDescription_showElectric =>
      'Afișați stații de încărcare EV în căutare și pe hartă.';

  @override
  String get featureLabel_showConsumptionTab => 'Fila Consum';

  @override
  String get featureDescription_showConsumptionTab =>
      'Afișați fila de analitica consumului în navigarea inferioară.';

  @override
  String get featureBlockedEnable_gamification =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Activați mai întâi TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureBlockedEnable_showFuel =>
      'Condiții prealabile neîndeplinite';

  @override
  String get featureBlockedEnable_showElectric =>
      'Condiții prealabile neîndeplinite';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Predicție prețuri TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Model de prognoză a prețurilor pe dispozitiv — inferența rulează local; funcționalitățile și predicțiile nu părăsesc niciodată dispozitivul.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Activați mai întâi istoricul prețurilor';

  @override
  String get featureLabel_fuelCalculator => 'Calculator combustibil';

  @override
  String get featureDescription_fuelCalculator =>
      'Calculator de cost-combustibil accesibil din rezultatele de căutare.';

  @override
  String get featureLabel_carbonDashboard => 'Tablou de bord carbon';

  @override
  String get featureDescription_carbonDashboard =>
      'Tablou de bord amprentă CO2 accesibil din fila Consum.';

  @override
  String get featureLabel_experimentalOemPids => 'PID-uri OEM experimentale';

  @override
  String get featureDescription_experimentalOemPids =>
      'Citiți litrii exacți din rezervor prin PID-uri specifice producătorului pe adaptoarele suportate.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Activați mai întâi înregistrarea călătoriilor OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Scanare QR de plată';

  @override
  String get featureDescription_paymentQrScan =>
      'Cititor QR de plată pe ecranul de detalii al stației.';

  @override
  String get featureLabel_communityPriceReports =>
      'Rapoarte de prețuri comunitate';

  @override
  String get featureDescription_communityPriceReports =>
      'Raportați prețul unei stații din ecranul de detalii al stației.';

  @override
  String get featureLabel_obd2Optional =>
      'Solicită OBD2 pentru înregistrarea călătoriilor';

  @override
  String get featureDescription_obd2Optional =>
      'Când este oprit, aplicația înregistrează călătorii doar cu GPS fără adaptor OBD2. Coachingul este redus — fără L/100 km instantaneu, mai puține semnale ale motorului.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR bon';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Scanați un bon imprimat pe ecranul Adăugare alimentare pentru a precompleta data, litrii, totalul și stația.';

  @override
  String get featureLabel_addFillUpOcrPump => 'OCR afișaj pompă (experimental)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Scanați afișajul unei pompe de carburant pentru a precompleta formularul. Recunoașterea nu este fiabilă astăzi — activați doar dacă doriți să testați.';

  @override
  String get featureLabel_developerPatToken =>
      'Feedback dezvoltator (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Activează panoul de feedback pentru scanări eșuate care creează automat issues pe GitHub cu un Personal Access Token. Funcție pentru utilizatori avansați / contribuitori.';

  @override
  String get featureLabel_debugMode => 'Mod dezvoltator / depanare';

  @override
  String get featureDescription_debugMode =>
      'Afișează o secțiune Instrumente pentru dezvoltatori în setări cu diagnosticare: exportul jurnalului de erori, notificări de test, rularea fluxului de alertă de test, lista indicatorilor de funcții, golirea memoriilor cache și copierea diagnosticării.';

  @override
  String get feedbackConsentTitle => 'Trimiteți raportul pe GitHub?';

  @override
  String get feedbackConsentBody =>
      'Aceasta creează un tichet public în depozitul nostru GitHub cu fotografia și textul OCR. Nu sunt trimise date personale (locație, ID cont). Continuați?';

  @override
  String get feedbackConsentContinue => 'Continuați';

  @override
  String get feedbackConsentCancel => 'Anulare';

  @override
  String get feedbackConsentLater => 'Mai târziu';

  @override
  String get feedbackTokenSectionTitle => 'Feedback scanare eșuată (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Pentru a deschide automat un tichet GitHub dintr-o scanare eșuată, lipiți un GitHub PAT (sfera `public_repo` pe depozitul tankstellen). Altfel, partajarea manuală rămâne disponibilă.';

  @override
  String get feedbackTokenStatusSet => 'Token configurat';

  @override
  String get feedbackTokenStatusUnset => 'Niciun token';

  @override
  String get feedbackTokenSet => 'Setați';

  @override
  String get feedbackTokenClear => 'Ștergeți';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Token de acces personal';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verificat de adaptor';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Nu corespunde cu citirea adaptorului';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Intrarea dvs.: $userL L. Adaptorul indică: $adapterL L (delta din captura nivelului combustibil înainte/după). Utilizați valoarea adaptorului?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Păstrați intrarea mea';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Utilizați valoarea adaptorului';

  @override
  String get scanReceiptNoData =>
      'Nicio dată găsită pe bon — încercați din nou';

  @override
  String get scanReceiptSuccess =>
      'Bon scanat — verificați valorile. Apăsați \"Raportați eroare de scanare\" mai jos dacă ceva este greșit.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scanarea a eșuat: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Afișajul pompei nu poate fi citit — încercați din nou';

  @override
  String get scanPumpSuccess => 'Afișajul pompei scanat — verificați valorile.';

  @override
  String scanPumpFailed(String error) {
    return 'Scanarea pompei a eșuat: $error';
  }

  @override
  String get badScanReportTitle => 'Raportați o eroare de scanare';

  @override
  String get badScanReportTitleReceipt => 'Raportați o eroare de scanare — Bon';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Raportați o eroare de scanare — Afișaj pompă';

  @override
  String get pumpScanFailureTitle => 'Afișaj necitibil';

  @override
  String get pumpScanFailureBody =>
      'Scanarea nu a putut citi afișajul pompei. Ce doriți să faceți?';

  @override
  String get pumpScanFailureCorrectManually => 'Corectați manual';

  @override
  String get pumpScanFailureReport => 'Raportați';

  @override
  String get pumpScanFailureRemove => 'Eliminați fotografia';

  @override
  String get badScanReportHint =>
      'Vom partaja fotografia bonului și ambele seturi de valori pentru ca viitoarea versiune să poată învăța acest format.';

  @override
  String get badScanReportShareAction => 'Partajați raportul + fotografia';

  @override
  String get badScanReportFieldBrandLayout => 'Format brand';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Preț/L';

  @override
  String get badScanReportFieldStation => 'Stație';

  @override
  String get badScanReportFieldFuel => 'Combustibil';

  @override
  String get badScanReportFieldDate => 'Data';

  @override
  String get badScanReportHeaderField => 'Câmp';

  @override
  String get badScanReportHeaderScanned => 'Scanat';

  @override
  String get badScanReportHeaderYouTyped => 'Ați introdus';

  @override
  String get badScanReportCreateTicket => 'Creați tichet';

  @override
  String get badScanReportOpenInBrowser => 'Deschideți în browser';

  @override
  String get badScanReportFallbackToShare =>
      'Trimiterea a eșuat — partajare manuală';

  @override
  String get pumpCameraHint =>
      'Aliniază cele trei cifre de pe afișajul pompei în interiorul cadrului';

  @override
  String get pumpCameraCapture => 'Capturează';

  @override
  String get pumpCameraPermissionDenied =>
      'Accesul la cameră este necesar pentru a scana afișajul pompei. Activează-l în setările dispozitivului.';

  @override
  String get pumpCameraError =>
      'Camera nu a putut porni. Încearcă din nou sau introdu valorile manual.';

  @override
  String get fillUpSectionWhatTitle => 'Ce ați alimentat';

  @override
  String get fillUpSectionWhatSubtitle => 'Combustibil, cantitate, preț';

  @override
  String get fillUpSectionWhereTitle => 'Unde erați';

  @override
  String get fillUpSectionWhereSubtitle => 'Stație, odometru, note';

  @override
  String get fillUpImportFromLabel => 'Importați din…';

  @override
  String get fillUpImportSheetTitle => 'Importați date de alimentare';

  @override
  String get fillUpImportReceiptLabel => 'Bon';

  @override
  String get fillUpImportReceiptDescription =>
      'Scanați un bon de hârtie cu camera';

  @override
  String get fillUpImportPumpLabel => 'Afișaj pompă';

  @override
  String get fillUpImportPumpDescription =>
      'Citiți Betrag / Preis de pe LCD-ul pompei';

  @override
  String get fillUpImportObdLabel => 'Adaptor OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Citiți odometrul de la portul OBD-II prin Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Preț per litru';

  @override
  String get vehicleHeaderPlateLabel => 'Număr';

  @override
  String get vehicleHeaderUntitled => 'Vehicul nou';

  @override
  String get vehicleSectionIdentityTitle => 'Identitate';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nume și VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Sistem de propulsie';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Cum se mișcă acest vehicul';

  @override
  String get calibrationModeLabel => 'Mod de calibrare';

  @override
  String get calibrationModeRule => 'Bazat pe reguli';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Bazat pe reguli atribuie fiecare eșantion de condus exact unei situații. Fuzzy îl distribuie pe toate în funcție de cât de bine se potrivește fiecare — mai fluid în jurul a 60 km/h sau la gradienți în schimbare, dar mai lent la umplerea tuturor categoriilor.';

  @override
  String get profileGamificationToggleTitle => 'Afișați realizări și scoruri';

  @override
  String get profileGamificationToggleSubtitle =>
      'Când e dezactivat, insignele, scorurile și icoanele trofeu sunt ascunse în toată aplicația.';

  @override
  String get coachingGpsLiftOff => 'Eliberează';

  @override
  String get coachingGpsAnticipateBrake => 'Anticipează';

  @override
  String get coachingGpsSmoothAccel => 'Accelerare lină';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostice eșantionare GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps întreruperi',
      one: '1 întrerupere',
      zero: 'fără întreruperi',
    );
    return '$count eșantioane · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Interval mediu: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Capturat în timpul înregistrării pentru a verifica cadența GPS în timpul somnului telefonului.';

  @override
  String get gpsMatrixMaturityCold => 'Rece';

  @override
  String get gpsMatrixMaturityWarming => 'Se încălzește';

  @override
  String get gpsMatrixMaturityConverged => 'Convergentă';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'Matricea GPS încă se încălzește ($count rafinamente până acum). Estimări provizorii.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'Matricea GPS converge ($count alimentări). Estimări utilizabile dar pot devia câteva %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'Matricea GPS a convers ($count alimentări). Estimări în limita a ~2 % din consumul real.';
  }

  @override
  String get hapticEcoCoachSectionTitle => 'Condus';

  @override
  String get hapticEcoCoachSettingTitle => 'Coaching eco în timp real';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Feedback haptic blând + sfat pe ecran când apăsați acceleratorul în croazieră';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Ușor cu acceleratorul — inerția economisește mai mult';

  @override
  String get anonKeyLabel => 'Cheie anonimă';

  @override
  String get anonKeyHideTooltip => 'Ascundeți cheia';

  @override
  String get anonKeyShowTooltip => 'Afișați cheia pentru verificare';

  @override
  String anonKeyTooLong(int length) {
    return 'Cheia este prea lungă ($length caractere) — verificați dacă există text suplimentar';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Cheia pare corectă ($length caractere)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Cheia trebuie să fie un JWT (antet.payload.semnătură)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Cheia poate fi trunchiată ($length din ~208 caractere așteptate)';
  }

  @override
  String get anonKeyExceedsMax => 'Cheia depășește lungimea maximă';

  @override
  String get qrShareTitle => 'Partajați baza dvs. de date';

  @override
  String get qrShareSubtitle =>
      'Alții pot scana acest cod QR pentru a se conecta';

  @override
  String get qrShareCopyAsText => 'Copiați ca text';

  @override
  String get authInfoTitle => 'De ce să creați un cont?';

  @override
  String get authInfoBenefit1 =>
      '• Sincronizați favorite, alerte și rute salvate pe mai multe dispozitive';

  @override
  String get authInfoBenefit2 =>
      '• Pregătiți o rută pe telefon, folosiți-o în mașină';

  @override
  String get authInfoBenefit3 => '• Nicio dată nu este partajată cu terți';

  @override
  String get authInfoBenefit4 => '• Puteți șterge contul oricând';

  @override
  String get privacyLocalDataEmpty =>
      'Nimic stocat încă. Adăugați un favorit sau setați o alertă de preț pentru a vedea intrările aici.';

  @override
  String get privacyHideEmptyRows => 'Ascundeți rândurile goale';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afișați $count rânduri goale',
      one: 'Afișați $count rând gol',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Configurare cheie API (opțional)';

  @override
  String get apiKeySetupDescription =>
      'Înregistrați-vă pentru o cheie API gratuită sau omiteți pentru a explora aplicația cu date demo.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Înregistrare $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Prin introducerea unei chei API acceptați termenii $provider. Redistribuirea datelor este interzisă.';
  }

  @override
  String get calculatorDistanceHint => 'ex. 150';

  @override
  String get calculatorConsumptionHint => 'ex. 7.0';

  @override
  String get calculatorPriceHint => 'ex. 1.899';

  @override
  String get routeStrategyLabel => 'Strategie:';

  @override
  String get routeStrategyUniform => 'Uniformă';

  @override
  String get routeStrategyBalanced => 'Echilibrată';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (experimental)';

  @override
  String get glideCoachBetaSubtitle =>
      'Feedback haptic subtil la decelerare înainte de semafor roșu. Dezactivat implicit — risc de distragere.';

  @override
  String get consentSyncTripsTitle =>
      'Sincronizați înregistrările de călătorii';

  @override
  String get consentSyncTripsSubtitle =>
      'Faceți backup la călătoriile OBD2 + GPS în TankSync. Cross-device, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Activați mai întâi Sincronizarea cloud pentru a face backup la călătorii.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Conectează-te cu un cont de e-mail pentru a sincroniza călătoriile între dispozitive.';

  @override
  String get consentHideDetails => 'Ascundeți detaliile';

  @override
  String get consentShowDetails => 'Afișați detaliile';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Link invalid';

  @override
  String invalidLinkBody(String path) {
    return 'Link-ul \"$path\" nu este valid.';
  }

  @override
  String get home => 'Acasă';

  @override
  String get loyaltySettingsTitle => 'Carduri de fidelitate combustibil';

  @override
  String get loyaltySettingsSubtitle =>
      'Aplicați reducerea de fidelitate la prețurile afișate';

  @override
  String get loyaltyMenuTitle => 'Carduri de fidelitate combustibil';

  @override
  String get loyaltyMenuSubtitle =>
      'Aplicați reduceri per litru de la Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Adăugați card';

  @override
  String get loyaltyAddCardSheetTitle =>
      'Adăugați card de fidelitate combustibil';

  @override
  String get loyaltyBrandLabel => 'Brand';

  @override
  String get loyaltyCardLabelLabel => 'Etichetă (opțional)';

  @override
  String get loyaltyDiscountLabel => 'Reducere (per litru)';

  @override
  String get loyaltyDiscountInvalid => 'Introduceți un număr pozitiv';

  @override
  String get loyaltyDeleteConfirmTitle => 'Ștergeți cardul?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Acest card nu va mai aplica reducerea sa.';

  @override
  String get loyaltyEmptyTitle => 'Niciun card de fidelitate încă';

  @override
  String get loyaltyEmptyBody =>
      'Adăugați un card pentru a aplica automat reducerea per litru la stațiile corespunzătoare.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Creștere RPM la ralanti detectată';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'RPM-ul la ralanti a crescut cu $percent% în ultimele $tripCount călătorii. Posibil semn timpuriu al unui filtru de aer înfundat sau derivă senzor.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Posibilă restricție de admisie';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Debitul de combustibil în croazieră a scăzut cu $percent% în ultimele $tripCount călătorii. Posibil semn al unui filtru de aer înfundat sau admisie restricționată — merită o verificare.';
  }

  @override
  String get maintenanceActionDismiss => 'Respingeți';

  @override
  String get maintenanceActionSnooze => 'Amânați 30 de zile';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Luna aceasta față de luna trecută';

  @override
  String get consumptionMonthlyTripsLabel => 'Călătorii';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Timp de condus';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distanță';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Consum mediu';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Sunt necesare cel puțin 3 călătorii pe lună pentru comparație';

  @override
  String get obd2CapabilitySectionTitle => 'Capacitățile adaptorului';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'PID-uri OEM';

  @override
  String get obd2CapabilityFullCan => 'CAN complet';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Pentru litrii exacți din rezervor pe Peugeot/Citroën, aplicația suportă OBDLink MX+/LX/CX (chip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Overlay de diagnostice OBD2 activat';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Overlay de diagnostice OBD2 dezactivat';

  @override
  String get obd2DebugOverlayClearButton => 'Ștergeți';

  @override
  String get obd2DebugOverlayCloseButton => 'Închideți';

  @override
  String get obd2DebugOverlayTitle => 'Traseu OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Partajează jurnalul de diagnosticare';

  @override
  String get obd2DebugLoggingTitle => 'Jurnalizare depanare OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Înregistrați fiecare sesiune OBD2 — conectare, handshake, întreruperi de date și reconectări — într-un jurnal XML exportabil. Dezactivat în mod implicit.';

  @override
  String get obd2DebugSessionShareLabel => 'Partajează jurnalul sesiunii OBD2';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nu s-a putut accesa \'$adapterName\' — alegeți alt adaptor';
  }

  @override
  String get onboardingObd2StepTitle => 'Conectați adaptorul OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Introduceți adaptorul OBD2 în portul mașinii și porniți contactul. Vom citi VIN-ul și vom completa detaliile motorului pentru dvs.';

  @override
  String get onboardingObd2ConnectButton => 'Conectați adaptorul';

  @override
  String get onboardingObd2SkipButton => 'Poate mai târziu';

  @override
  String get onboardingObd2ReadingVin => 'Se citește VIN-ul…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Nu s-a putut citi VIN-ul — introduceți manual';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nu s-a putut conecta la adaptor. Puteți reîncerca sau omite.';

  @override
  String get onboardingPickUseMode =>
      'Alegeți un mod de utilizare pentru a continua.';

  @override
  String get tripRecordingPipElapsedCaption => 'scurs';

  @override
  String get alertsRadiusFrequencyLabel => 'Frecvența verificărilor';

  @override
  String get alertsRadiusFrequencyDaily => 'O dată pe zi';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'De două ori pe zi';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'De trei ori pe zi';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'De patru ori pe zi';

  @override
  String get radiusAlertPickOnMap => 'Alegeți pe hartă';

  @override
  String get radiusAlertMapPickerTitle => 'Alegeți centrul alertei';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirmați';

  @override
  String get radiusAlertMapPickerCancel => 'Anulare';

  @override
  String get radiusAlertMapPickerHint =>
      'Trageți harta pentru a poziționa centrul alertei';

  @override
  String get radiusAlertCenterFromMap => 'Locație pe hartă';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel lângă $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'O stație are prețul $price € (țintă: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesiune';

  @override
  String get speedConsumptionCardTitle => 'Consum pe viteză';

  @override
  String get speedBandIdleJam => 'Ralanti / ambuteiaj';

  @override
  String get speedBandUrban => 'Urban (10–50)';

  @override
  String get speedBandSuburban => 'Suburban (50–80)';

  @override
  String get speedBandRural => 'Rural (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Croazieră eco (100–115)';

  @override
  String get speedBandMotorway => 'Autostradă (115–130)';

  @override
  String get speedBandMotorwayFast => 'Autostradă rapidă (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Înregistrați 30+ minute de călătorii cu adaptorul OBD2 pentru a debloca analiza viteză/consum.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % din condus';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Sunt necesare mai multe date';

  @override
  String get splashLoadingLabel => 'Se încarcă Sparkilo';

  @override
  String get tankLevelTitle => 'Nivel rezervor';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km autonomie';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Ultima alimentare: $date · $count călătorie(călătorii) de atunci';
  }

  @override
  String get tankLevelMethodObd2 => 'Măsurat OBD2';

  @override
  String get tankLevelMethodDistanceFallback => 'estimare bazată pe distanță';

  @override
  String get tankLevelMethodMixed => 'măsurătoare mixtă';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Înregistrați o alimentare pentru a vedea nivelul rezervorului';

  @override
  String get tankLevelDetailSheetTitle => 'Călătorii de la ultima alimentare';

  @override
  String get addFillUpIsFullTankLabel => 'Rezervor plin';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Rezervor umplut până la refuz — debifați dacă aceasta a fost o alimentare parțială';

  @override
  String get themeCardTitle => 'Temă';

  @override
  String get themeCardSubtitleSystem => 'Sistem';

  @override
  String get themeCardSubtitleLight => 'Luminos';

  @override
  String get themeCardSubtitleDark => 'Întunecat';

  @override
  String get themeSettingsScreenTitle => 'Temă';

  @override
  String get themeSettingsSystemLabel => 'Urmați sistemul';

  @override
  String get themeSettingsLightLabel => 'Luminos';

  @override
  String get themeSettingsDarkLabel => 'Întunecat';

  @override
  String get themeSettingsSystemDescription =>
      'Urmați aspectul actual al dispozitivului.';

  @override
  String get themeSettingsLightDescription =>
      'Fundal luminos — cel mai bun pentru utilizare ziua.';

  @override
  String get themeSettingsDarkDescription =>
      'Fundal întunecat — mai ușor pe ochi noaptea și economisește bateria pe ecranele OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'Aspectul verde caracteristic al aplicației — luminos și ușor de citit, cu fundal ușor verzui.';

  @override
  String get throttleRpmHistogramTitle => 'Cum ați folosit motorul';

  @override
  String get throttleRpmHistogramThrottleSection => 'Poziția acceleratorului';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM motor';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Inerție (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Ușor (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Ferm (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Complet deschis (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Ralanti (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Croazieră (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Dinamic (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Intens (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Niciun eșantion de accelerator sau RPM în această călătorie.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Călătorii';

  @override
  String get trajetsStartRecordingButton => 'Porniți înregistrarea';

  @override
  String get trajetsResumeRecordingButton => 'Reluați înregistrarea';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Se conectează la adaptorul OBD2…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Se citesc datele vehiculului…';

  @override
  String get tripStartProgressStartingRecording => 'Se pornește înregistrarea…';

  @override
  String get trajetsEmptyStateTitle => 'Nicio călătorie încă';

  @override
  String get trajetsEmptyStateBody =>
      'Apăsați Porniți înregistrarea pentru a începe să înregistrați drumurile.';

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
  String get trajetDetailSummaryTitle => 'Rezumat';

  @override
  String get trajetDetailFieldDate => 'Data';

  @override
  String get trajetDetailFieldVehicle => 'Vehicul';

  @override
  String get trajetDetailFieldAdapter => 'Adaptor OBD2';

  @override
  String get trajetDetailFieldDistance => 'Distanță';

  @override
  String get trajetDetailFieldDuration => 'Durată';

  @override
  String get trajetDetailFieldAvgConsumption => 'Consum mediu';

  @override
  String get trajetDetailFieldFuelUsed => 'Combustibil utilizat';

  @override
  String get trajetDetailFieldFuelCost => 'Cost combustibil';

  @override
  String get trajetDetailFieldAvgSpeed => 'Viteză medie';

  @override
  String get trajetDetailFieldMaxSpeed => 'Viteză maximă';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Viteză (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Debit combustibil (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Sarcină motor (%)';

  @override
  String get trajetDetailChartsSection => 'Grafice';

  @override
  String get trajetsRowColdStartChip => 'Pornire la rece';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motorul nu a atins temperatura de funcționare în această călătorie — consumul a fost mai mare decât de obicei.';

  @override
  String get trajetDetailChartEmpty => 'Niciun eșantion înregistrat';

  @override
  String get trajetDetailShareAction => 'Partajați';

  @override
  String get trajetDetailShareImageOption => 'Partajează imaginea';

  @override
  String get trajetDetailShareGpxOption => 'Partajează traseul GPS (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Fără date GPS în această călătorie';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — călătorie din $date';
  }

  @override
  String get trajetDetailShareError =>
      'Nu s-a putut genera imaginea de partajare';

  @override
  String get trajetDetailDeleteAction => 'Ștergeți';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Ștergeți această călătorie?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Această călătorie va fi eliminată permanent din istoricul dvs.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Anulare';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Ștergeți';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adaptorul OBD2 este conectat dar nu returnează date. Încercați un adaptor diferit sau verificați protocolul de diagnosticare al vehiculului.';

  @override
  String get trajetsViewAllOnMap => 'Vezi toate pe hartă';

  @override
  String get trajetsMapTitle => 'Călătorii pe hartă';

  @override
  String get trajetsMapShareGpx => 'Partajează GPX';

  @override
  String get trajetsMapEmpty =>
      'Niciuna dintre călătoriile selectate nu conține date GPS.';

  @override
  String get trajetsMapShareError => 'Fișierul GPX nu a putut fi partajat';

  @override
  String get tripLengthCardTitle => 'Consum pe lungimea călătoriei';

  @override
  String get tripLengthBucketShort => 'Scurtă (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Medie (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Lungă (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Sunt necesare mai multe date';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count călătorii',
      one: '1 călătorie',
      zero: 'nicio călătorie',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Traseul călătoriei';

  @override
  String get tripPathCardSubtitle => 'Rută înregistrată GPS';

  @override
  String get tripPathLegendTitle => 'Consum';

  @override
  String get tripPathLegendEfficient => 'Eficient (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'La limită (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Risipitor (≥ 10 L/100km)';

  @override
  String get tripRecordingPinTooltip =>
      'Fixarea menține ecranul aprins — consumă mai multă baterie';

  @override
  String get tripRecordingPinSemanticOn =>
      'Defixați formularul de înregistrare';

  @override
  String get tripRecordingPinSemanticOff => 'Fixați formularul de înregistrare';

  @override
  String get tripRecordingPinHelpTooltip => 'Ce face fixarea?';

  @override
  String get tripRecordingPinHelpTitle => 'Despre fixare';

  @override
  String get tripRecordingPinHelpBody =>
      'Fixarea menține ecranul aprins și ascunde barele sistemului pentru ca formularul să rămână lizibil pe un suport de bord. Apăsați din nou pentru a elibera. Se eliberează automat când călătoria se oprește.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Înregistrarea continuă în fundal. Apăsați bannerul roșu din partea de sus a oricărui ecran pentru a reveni.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Deschideți călătoria activă din fila Conso';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Fixați ecranul pentru a menține GPS-ul activ în timpul călătoriei — Android poate reduce GPS-ul în somn.';

  @override
  String get tripRecordingMinimiseTooltip =>
      'Minimizează într-o casetă flotantă';

  @override
  String get tripShareAction => 'Partajează cu alt cont';

  @override
  String get tripShareSheetTitle => 'Partajează acest traseu';

  @override
  String get tripShareSheetSubtitle =>
      'Acordă altui cont TankSync acces doar pentru citire la acest traseu înregistrat.';

  @override
  String get tripShareEmailLabel => 'E-mailul destinatarului';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Partajează';

  @override
  String get tripShareCreateLinkButton => 'Creează link de partajare';

  @override
  String get tripShareLinkCreated =>
      'Link de partajare copiat — lipește-l destinatarului.';

  @override
  String get tripShareSuccess => 'Traseu partajat.';

  @override
  String get tripShareRecipientNotFound =>
      'Niciun cont TankSync nu folosește acest e-mail.';

  @override
  String get tripShareError =>
      'Traseul nu a putut fi partajat. Încearcă din nou.';

  @override
  String get tripShareExistingTitle => 'Partajat cu';

  @override
  String get tripShareExistingEmpty => 'Încă nepartajat cu nimeni.';

  @override
  String get tripShareDirectRecipient => 'Un cont';

  @override
  String get tripShareLinkRecipient => 'Link de partajare (nerevendicat)';

  @override
  String get tripShareRevokeTooltip => 'Revocă';

  @override
  String get tripShareRevoked => 'Partajare revocată.';

  @override
  String get trajetsSharedSectionTitle => 'Partajat cu mine';

  @override
  String get trajetsSharedBadge => 'Partajat';

  @override
  String get unifiedFilterFuel => 'Combustibil';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Ambele';

  @override
  String get unifiedNoResultsForFilter => 'Niciun rezultat pentru acest filtru';

  @override
  String get searchFailedSnackbar =>
      'Căutarea a eșuat — vă rugăm să încercați din nou';

  @override
  String get vinLabel => 'VIN (opțional)';

  @override
  String get vinDecodeTooltip => 'Decodați VIN';

  @override
  String get vinConfirmAction => 'Da, completați automat';

  @override
  String get vinModifyAction => 'Modificați manual';

  @override
  String get veResetAction => 'Resetați eficiența volumetrică';

  @override
  String get vehicleReadVinFromCarButton => 'Citiți VIN-ul din mașină';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Citiți VIN-ul din adaptorul OBD2 asociat';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN indisponibil (Modul 09 PID 02 nesuportat pe vehicule pre-2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Citirea VIN a eșuat — introduceți manual';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Asociați mai întâi un adaptor OBD2 pentru a citi VIN automat';

  @override
  String get pickerButtonLabel => 'Alegeți din catalog';

  @override
  String get pickerSearchHint => 'Căutați marcă sau model';

  @override
  String get pickerHelpText => 'Precompletare din 50+ vehicule suportate';

  @override
  String get pickerEmptyResults => 'Niciun rezultat';

  @override
  String get pickerCancel => 'Anulare';

  @override
  String get pickerLoading => 'Se încarcă catalogul…';

  @override
  String get vinInfoTooltip => 'Ce este un VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Ce este un VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Numărul de identificare al vehiculului este un cod unic de 17 caractere specific mașinii dvs. Este ștanțat pe șasiu și tipărit pe documentul de înmatriculare.';

  @override
  String get vinInfoSectionWhyTitle => 'De ce îl cerem';

  @override
  String get vinInfoSectionWhyBody =>
      'Decodarea VIN-ului completează automat cilindreea motorului, numărul de cilindri, anul modelului, tipul principal de combustibil și greutatea brută — scutindu-vă de a căuta manual specificațiile tehnice. Calculul debitului de combustibil OBD2 folosește aceste valori pentru a vă oferi cifre precise de consum.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Confidențialitate';

  @override
  String get vinInfoSectionPrivacyBody =>
      'VIN-ul dvs. este stocat doar local în spațiul de stocare criptat al aplicației — nu este niciodată încărcat pe serverele Sparkilo. Baza de date NHTSA vPIC este interogată cu VIN-ul, dar returnează doar specificații tehnice anonime; NHTSA nu leagă VIN-ul de nicio dată personală. Fără rețea, o căutare offline returnează doar producătorul și țara.';

  @override
  String get vinInfoSectionWhereTitle => 'Unde să îl găsiți';

  @override
  String get vinInfoSectionWhereBody =>
      'Uitați-vă prin parbriz în colțul din stânga jos al părții șoferului, verificați autocolantul de pe cadrul ușii șoferului când ușa este deschisă sau citiți-l de pe documentul de înmatriculare (carte de identitate / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Am înțeles';

  @override
  String get vinConfirmPrivacyNote =>
      'Am căutat VIN-ul dvs. în baza de date gratuită NHTSA — nimic trimis la serverele Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Decodare VIN online';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Decodați VIN-ul prin serviciul public gratuit NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Când asociați un adaptor, VIN-ul vehiculului dvs. este citit local pentru a identifica mașina. Activarea acestei opțiuni trimite VIN-ul de 17 caractere la serviciul gratuit vPIC al NHTSA pentru a obține detalii suplimentare (model, cilindree, tip combustibil). VIN-ul este singurul dat trimis — nicio altă informație nu părăsește dispozitivul.';

  @override
  String get vehicleDetectedFromVinBadge => '(detectat)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detectat din VIN: $summary. Aplicați?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Aplicați';

  @override
  String get widgetHelpSectionTitle => 'Widget ecran principal';

  @override
  String get widgetHelpIntro =>
      'Adăugați widgetul SparKilo pe ecranul principal pentru a vedea prețurile la combustibil și încărcare dintr-o privire.';

  @override
  String get widgetHelpAdd =>
      'Adăugați-l din selectorul de widget-uri al launcher-ului — apăsați lung pe o zonă liberă a ecranului principal, alegeți Widget-uri și găsiți SparKilo.';

  @override
  String get widgetHelpTap =>
      'Apăsați o stație din widget pentru a o deschide în aplicație. Apăsați pictograma de actualizare pentru a actualiza prețurile.';

  @override
  String get widgetHelpConfigure =>
      'Pe Android, apăsați lung pe widget și alegeți Reconfigurați pentru a modifica profilul, culoarea și conținutul.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Opțiunile de mai jos se aplică fiecărui widget instalat la următoarea reîmprospătare.';

  @override
  String get widgetDefaultsColorLabel => 'Schemă de culori';

  @override
  String get widgetDefaultsVariantLabel => 'Variantă de conținut';

  @override
  String get widgetColorSchemeSystem => 'Conform sistemului';

  @override
  String get widgetColorSchemeLight => 'Luminos';

  @override
  String get widgetColorSchemeDark => 'Întunecat';

  @override
  String get widgetColorSchemeBlue => 'Albastru';

  @override
  String get widgetColorSchemeGreen => 'Verde';

  @override
  String get widgetColorSchemeOrange => 'Portocaliu';

  @override
  String get widgetVariantDefault => 'Numai prețul curent';

  @override
  String get widgetVariantPredictive =>
      'Predictiv: cel mai bun moment pentru alimentare';

  @override
  String get widgetPredictiveNowPrefix => 'acum';
}
