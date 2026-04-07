// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Prețuri Carburanți';

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
  String get welcome => 'Prețuri Carburanți';

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
  String get supportProject => 'Susțineți acest proiect';

  @override
  String get supportDescription =>
      'Această aplicație este gratuită, open source și fără reclame. Dacă o găsiți utilă, luați în considerare susținerea dezvoltatorului.';

  @override
  String get reportBug => 'Raportează eroare / Sugerează funcție';

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
  String get sortDistance => 'Distanță';

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
}
