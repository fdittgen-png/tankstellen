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
  String get countryChangeTitle => 'Switch country?';

  @override
  String countryChangeBody(String country) {
    return 'Switching to $country will change:';
  }

  @override
  String get countryChangeCurrency => 'Currency';

  @override
  String get countryChangeDistance => 'Distance';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Price format';

  @override
  String get countryChangeNote =>
      'Existing favorites and fill-up logs are not rewritten; only new entries use the new units.';

  @override
  String get countryChangeConfirm => 'Switch';

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
  String get apiKeyFormatError => 'Format invalid — UUID așteptat (8-4-4-4-12)';

  @override
  String get supportProject => 'Susțineți acest proiect';

  @override
  String get supportDescription =>
      'Această aplicație este gratuită, open source și fără reclame. Dacă o găsiți utilă, luați în considerare susținerea dezvoltatorului.';

  @override
  String get reportBug => 'Raportează eroare / Sugerează funcție';

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
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

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
  String get alertStatsActive => 'Active';

  @override
  String get alertStatsToday => 'Astăzi';

  @override
  String get alertStatsThisWeek => 'Săptămâna aceasta';

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
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Compared to the rolling average over your last 3 fill-ups ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumption $value L/100 km, $delta versus your rolling average';
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
  String get nearestStations => 'Cele mai apropiate statii';

  @override
  String get nearestStationsHint =>
      'Gasiti cele mai apropiate statii cu locatia dvs. actuala';

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
  String get vehiclesWizardTitle => 'My vehicles (optional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Add your car to pre-fill the consumption log and enable EV connector filters. You can skip this and add vehicles later.';

  @override
  String get vehiclesWizardNoneYet => 'No vehicle configured yet.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles',
      one: '1 vehicle',
    );
    return 'You have $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Skip to finish setup — you can add vehicles anytime from Settings.';

  @override
  String get fillUpVehicleLabel => 'Vehicle (optional)';

  @override
  String get fillUpVehicleNone => 'No vehicle';

  @override
  String get profileDefaultVehicleLabel => 'Default vehicle (optional)';

  @override
  String get profileDefaultVehicleNone => 'No default';

  @override
  String get profileFuelFromVehicleHint =>
      'Fuel type is derived from your default vehicle. Clear the vehicle to pick a fuel directly.';

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
