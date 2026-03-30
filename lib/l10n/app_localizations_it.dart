// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Prezzi Carburanti';

  @override
  String get search => 'Cerca';

  @override
  String get favorites => 'Preferiti';

  @override
  String get map => 'Mappa';

  @override
  String get profile => 'Profilo';

  @override
  String get settings => 'Impostazioni';

  @override
  String get gpsLocation => 'Posizione GPS';

  @override
  String get zipCode => 'CAP';

  @override
  String get zipCodeHint => 'es. 00100';

  @override
  String get fuelType => 'Carburante';

  @override
  String get searchRadius => 'Raggio';

  @override
  String get searchNearby => 'Stazioni vicine';

  @override
  String get searchButton => 'Cerca';

  @override
  String get noResults => 'Nessuna stazione trovata.';

  @override
  String get startSearch => 'Cerca per trovare distributori.';

  @override
  String get open => 'Aperto';

  @override
  String get closed => 'Chiuso';

  @override
  String distance(String distance) {
    return 'a $distance';
  }

  @override
  String get price => 'Prezzo';

  @override
  String get prices => 'Prezzi';

  @override
  String get address => 'Indirizzo';

  @override
  String get openingHours => 'Orari';

  @override
  String get open24h => 'Aperto 24 ore';

  @override
  String get navigate => 'Naviga';

  @override
  String get retry => 'Riprova';

  @override
  String get apiKeySetup => 'Chiave API';

  @override
  String get apiKeyDescription =>
      'Registrati una volta per ottenere una chiave API gratuita.';

  @override
  String get apiKeyLabel => 'Chiave API';

  @override
  String get register => 'Registrazione';

  @override
  String get continueButton => 'Continua';

  @override
  String get welcome => 'Prezzi Carburanti';

  @override
  String get welcomeSubtitle =>
      'Trova il carburante più economico vicino a te.';

  @override
  String get profileName => 'Nome profilo';

  @override
  String get preferredFuel => 'Carburante preferito';

  @override
  String get defaultRadius => 'Raggio predefinito';

  @override
  String get landingScreen => 'Schermata iniziale';

  @override
  String get homeZip => 'CAP di casa';

  @override
  String get newProfile => 'Nuovo profilo';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get activate => 'Attiva';

  @override
  String get configured => 'Configurato';

  @override
  String get notConfigured => 'Non configurato';

  @override
  String get about => 'Info';

  @override
  String get openSource => 'Open Source (Licenza MIT)';

  @override
  String get sourceCode => 'Codice sorgente su GitHub';

  @override
  String get noFavorites => 'Nessun preferito';

  @override
  String get noFavoritesHint =>
      'Tocca la stella di una stazione per aggiungerla ai preferiti.';

  @override
  String get language => 'Lingua';

  @override
  String get country => 'Paese';

  @override
  String get demoMode => 'Modalità demo — dati di esempio.';

  @override
  String get setupLiveData => 'Configura per dati reali';

  @override
  String get freeNoKey => 'Gratuito — nessuna chiave necessaria';

  @override
  String get apiKeyRequired => 'Chiave API necessaria';

  @override
  String get skipWithoutKey => 'Continua senza chiave';

  @override
  String get dataTransparency => 'Trasparenza dei dati';

  @override
  String get storageAndCache => 'Archiviazione e cache';

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get clearAllData => 'Elimina tutti i dati';

  @override
  String get errorLog => 'Registro errori';

  @override
  String stationsFound(int count) {
    return '$count stazioni trovate';
  }

  @override
  String get whatIsShared => 'Cosa viene condiviso — e con chi?';

  @override
  String get gpsCoordinates => 'Coordinate GPS';

  @override
  String get gpsReason =>
      'Inviate a ogni ricerca per trovare le stazioni vicine.';

  @override
  String get postalCodeData => 'Codice postale';

  @override
  String get postalReason =>
      'Convertito in coordinate tramite il servizio di geocodifica.';

  @override
  String get mapViewport => 'Area della mappa';

  @override
  String get mapReason =>
      'Le mappe vengono caricate dal server. Nessun dato personale viene trasmesso.';

  @override
  String get apiKeyData => 'Chiave API';

  @override
  String get apiKeyReason =>
      'La tua chiave personale viene inviata con ogni richiesta API. È collegata alla tua email.';

  @override
  String get notShared => 'NON condiviso:';

  @override
  String get searchHistory => 'Cronologia ricerche';

  @override
  String get favoritesData => 'Preferiti';

  @override
  String get profileNames => 'Nomi profili';

  @override
  String get homeZipData => 'CAP di casa';

  @override
  String get usageData => 'Dati di utilizzo';

  @override
  String get privacyBanner =>
      'Questa app non ha un server. Tutti i dati restano sul tuo dispositivo. Nessuna analisi, nessun tracciamento, nessuna pubblicità.';

  @override
  String get storageUsage => 'Utilizzo dello spazio su questo dispositivo';

  @override
  String get settingsLabel => 'Impostazioni';

  @override
  String get profilesStored => 'profili salvati';

  @override
  String get stationsMarked => 'stazioni salvate';

  @override
  String get cachedResponses => 'risposte in cache';

  @override
  String get total => 'Totale';

  @override
  String get cacheManagement => 'Gestione cache';

  @override
  String get cacheDescription =>
      'La cache memorizza le risposte API per un caricamento più veloce e l\'accesso offline.';

  @override
  String get stationSearch => 'Ricerca stazioni';

  @override
  String get stationDetails => 'Dettagli stazione';

  @override
  String get priceQuery => 'Richiesta prezzi';

  @override
  String get zipGeocoding => 'Geocodifica CAP';

  @override
  String minutes(int n) {
    return '$n minuti';
  }

  @override
  String hours(int n) {
    return '$n ore';
  }

  @override
  String get clearCacheTitle => 'Svuotare la cache?';

  @override
  String get clearCacheBody =>
      'I risultati di ricerca e i prezzi memorizzati verranno eliminati. Profili, preferiti e impostazioni vengono conservati.';

  @override
  String get clearCacheButton => 'Svuota cache';

  @override
  String get deleteAllTitle => 'Eliminare tutti i dati?';

  @override
  String get deleteAllBody =>
      'Questo elimina definitivamente tutti i profili, i preferiti, la chiave API, le impostazioni e la cache. L\'app verrà reimpostata.';

  @override
  String get deleteAllButton => 'Elimina tutto';

  @override
  String get entries => 'voci';

  @override
  String get cacheEmpty => 'La cache è vuota';

  @override
  String get noStorage => 'Nessuno spazio utilizzato';

  @override
  String get apiKeyNote =>
      'Registrazione gratuita. Dati dalle agenzie governative per la trasparenza dei prezzi.';

  @override
  String get supportProject => 'Supporta questo progetto';

  @override
  String get supportDescription =>
      'Questa app è gratuita, open source e senza pubblicità. Se la trovi utile, considera di supportare lo sviluppatore.';

  @override
  String get reportBug => 'Segnala un bug / Suggerisci una funzione';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get fuels => 'Carburanti';

  @override
  String get services => 'Servizi';

  @override
  String get zone => 'Zona';

  @override
  String get highway => 'Autostrada';

  @override
  String get localStation => 'Stazione locale';

  @override
  String get lastUpdate => 'Ultimo aggiornamento';

  @override
  String get automate24h => '24h/24 — Automatico';

  @override
  String get refreshPrices => 'Aggiorna prezzi';

  @override
  String get station => 'Stazione';

  @override
  String get locationDenied =>
      'Permesso di localizzazione negato. Puoi cercare per codice postale.';

  @override
  String get demoModeBanner =>
      'Modalità demo. Configura la chiave API nelle impostazioni.';

  @override
  String get sortDistance => 'Distanza';

  @override
  String get cheap => 'economico';

  @override
  String get expensive => 'costoso';

  @override
  String stationsOnMap(int count) {
    return '$count stazioni';
  }

  @override
  String get loadingFavorites =>
      'Caricamento preferiti...\nCerca prima le stazioni per salvare i dati.';

  @override
  String get reportPrice => 'Segnala prezzo';

  @override
  String get whatsWrong => 'Cosa non va?';

  @override
  String get correctPrice => 'Prezzo corretto (es. 1,459)';

  @override
  String get sendReport => 'Invia segnalazione';

  @override
  String get reportSent => 'Segnalazione inviata. Grazie!';

  @override
  String get enterValidPrice => 'Inserisci un prezzo valido';

  @override
  String get cacheCleared => 'Cache svuotata.';

  @override
  String get yourPosition => 'La tua posizione';

  @override
  String get positionUnknown => 'Posizione sconosciuta';

  @override
  String get distancesFromCenter => 'Distanze dal centro di ricerca';

  @override
  String get autoUpdatePosition => 'Aggiorna posizione automaticamente';

  @override
  String get autoUpdateDescription => 'Aggiorna GPS prima di ogni ricerca';

  @override
  String get location => 'Posizione';

  @override
  String get switchProfileTitle => 'Paese cambiato';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Sei in $country. Passare al profilo \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Profilo \"$profile\" attivato ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Nessun profilo per questo paese';

  @override
  String noProfileForCountry(String country) {
    return 'Sei in $country, ma nessun profilo è configurato. Creane uno nelle Impostazioni.';
  }

  @override
  String get autoSwitchProfile => 'Cambio automatico profilo';

  @override
  String get autoSwitchDescription =>
      'Cambia profilo automaticamente attraversando i confini';

  @override
  String get switchProfile => 'Cambia';

  @override
  String get dismiss => 'Chiudi';

  @override
  String get profileCountry => 'Paese';

  @override
  String get profileLanguage => 'Lingua';

  @override
  String get settingsStorageDetail => 'Chiave API, profilo attivo';

  @override
  String get allFuels => 'Tutti';

  @override
  String get priceAlerts => 'Avvisi prezzo';

  @override
  String get noPriceAlerts => 'Nessun avviso prezzo';

  @override
  String get noPriceAlertsHint =>
      'Crea un avviso dalla pagina dettaglio di una stazione.';

  @override
  String alertDeleted(String name) {
    return 'Avviso \"$name\" eliminato';
  }

  @override
  String get createAlert => 'Crea avviso prezzo';

  @override
  String currentPrice(String price) {
    return 'Prezzo attuale: $price';
  }

  @override
  String get targetPrice => 'Prezzo obiettivo (EUR)';

  @override
  String get enterPrice => 'Inserisci un prezzo';

  @override
  String get invalidPrice => 'Prezzo non valido';

  @override
  String get priceTooHigh => 'Prezzo troppo alto';

  @override
  String get create => 'Crea';

  @override
  String get alertCreated => 'Avviso prezzo creato';

  @override
  String get wrongE5Price => 'Prezzo Super E5 errato';

  @override
  String get wrongE10Price => 'Prezzo Super E10 errato';

  @override
  String get wrongDieselPrice => 'Prezzo Diesel errato';

  @override
  String get wrongStatusOpen => 'Indicato aperto, ma chiuso';

  @override
  String get wrongStatusClosed => 'Indicato chiuso, ma aperto';

  @override
  String get searchAlongRouteLabel => 'Lungo il percorso';

  @override
  String get searchEvStations => 'Cerca stazioni di ricarica';

  @override
  String get allStations => 'Tutte le stazioni';

  @override
  String get bestStops => 'Migliori soste';

  @override
  String get openInMaps => 'Apri in Mappe';

  @override
  String get noStationsAlongRoute =>
      'Nessuna stazione trovata lungo il percorso';

  @override
  String get evOperational => 'Operativa';

  @override
  String get evStatusUnknown => 'Stato sconosciuto';

  @override
  String evConnectors(int count) {
    return 'Connettori ($count punti)';
  }

  @override
  String get evNoConnectors => 'Nessun dettaglio connettore disponibile';

  @override
  String get evUsageCost => 'Costo di utilizzo';

  @override
  String get evPricingUnavailable => 'Prezzo non disponibile dal fornitore';

  @override
  String get evLastUpdated => 'Ultimo aggiornamento';

  @override
  String get evUnknown => 'Sconosciuto';

  @override
  String get evDataAttribution => 'Dati da OpenChargeMap (fonte comunitaria)';

  @override
  String get evStatusDisclaimer =>
      'Lo stato potrebbe non riflettere la disponibilità in tempo reale. Tocca aggiorna per ottenere i dati più recenti.';

  @override
  String get evNavigateToStation => 'Naviga verso la stazione';

  @override
  String get evRefreshStatus => 'Aggiorna stato';

  @override
  String get evStatusUpdated => 'Stato aggiornato';

  @override
  String get evStationNotFound =>
      'Impossibile aggiornare — stazione non trovata nelle vicinanze';

  @override
  String get addedToFavorites => 'Aggiunto ai preferiti';

  @override
  String get removedFromFavorites => 'Rimosso dai preferiti';

  @override
  String get addFavorite => 'Aggiungi ai preferiti';

  @override
  String get removeFavorite => 'Rimuovi dai preferiti';

  @override
  String get currentLocation => 'Posizione attuale';

  @override
  String get gpsError => 'Errore GPS';

  @override
  String get couldNotResolve => 'Impossibile risolvere partenza o destinazione';

  @override
  String get start => 'Partenza';

  @override
  String get destination => 'Destinazione';

  @override
  String get cityAddressOrGps => 'Città, indirizzo o GPS';

  @override
  String get cityOrAddress => 'Città o indirizzo';

  @override
  String get useGps => 'Usa GPS';

  @override
  String get stop => 'Tappa';

  @override
  String stopN(int n) {
    return 'Tappa $n';
  }

  @override
  String get addStop => 'Aggiungi tappa';

  @override
  String get searchAlongRoute => 'Cerca lungo il percorso';

  @override
  String get cheapest => 'Più economica';

  @override
  String nStations(int count) {
    return '$count stazioni';
  }

  @override
  String nBest(int count) {
    return '$count migliori';
  }

  @override
  String get fuelPricesTankerkoenig => 'Prezzi carburanti (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Necessario per la ricerca prezzi carburanti in Germania';

  @override
  String get evChargingOpenChargeMap => 'Ricarica EV (OpenChargeMap)';

  @override
  String get customKey => 'Chiave personalizzata';

  @override
  String get appDefaultKey => 'Chiave predefinita dell\'app';

  @override
  String get optionalOverrideKey =>
      'Facoltativo: sostituire la chiave integrata con la propria';

  @override
  String get requiredForEvSearch =>
      'Necessario per la ricerca di stazioni di ricarica EV';

  @override
  String get edit => 'Modifica';

  @override
  String get fuelPricesApiKey => 'Chiave API prezzi carburanti';

  @override
  String get tankerkoenigApiKey => 'Chiave API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Chiave API ricarica EV';

  @override
  String get openChargeMapApiKey => 'Chiave API OpenChargeMap';

  @override
  String get routeSegment => 'Segmento percorso';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Mostra la stazione più economica ogni $km km lungo il percorso';
  }

  @override
  String get avoidHighways => 'Evita autostrade';

  @override
  String get avoidHighwaysDesc =>
      'Il calcolo del percorso evita strade a pedaggio e autostrade';

  @override
  String get showFuelStations => 'Mostra distributori';

  @override
  String get showFuelStationsDesc =>
      'Includi stazioni benzina, diesel, GPL, metano';

  @override
  String get showEvStations => 'Mostra stazioni di ricarica';

  @override
  String get showEvStationsDesc =>
      'Includi stazioni di ricarica elettrica nei risultati';

  @override
  String get noStationsAlongThisRoute =>
      'Nessuna stazione trovata lungo questo percorso.';

  @override
  String get fuelCostCalculator => 'Calcolatore costi carburante';

  @override
  String get distanceKm => 'Distanza (km)';

  @override
  String get consumptionL100km => 'Consumo (L/100km)';

  @override
  String get fuelPriceEurL => 'Prezzo carburante (EUR/L)';

  @override
  String get tripCost => 'Costo del viaggio';

  @override
  String get fuelNeeded => 'Carburante necessario';

  @override
  String get totalCost => 'Costo totale';

  @override
  String get enterCalcValues =>
      'Inserisci distanza, consumo e prezzo per calcolare il costo del viaggio';

  @override
  String get priceHistory => 'Storico prezzi';

  @override
  String get noPriceHistory => 'Nessuno storico prezzi ancora';

  @override
  String get noHourlyData => 'Nessun dato orario';

  @override
  String get noStatistics => 'Nessuna statistica disponibile';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Med';

  @override
  String get showAllFuelTypes => 'Mostra tutti i tipi di carburante';

  @override
  String get connected => 'Connesso';

  @override
  String get notConnected => 'Non connesso';

  @override
  String get connectTankSync => 'Connetti TankSync';

  @override
  String get disconnectTankSync => 'Disconnetti TankSync';

  @override
  String get viewMyData => 'Visualizza i miei dati';

  @override
  String get optionalCloudSync =>
      'Sincronizzazione cloud opzionale per avvisi, preferiti e notifiche push';

  @override
  String get tapToUpdateGps => 'Tocca per aggiornare la posizione GPS';

  @override
  String get gpsAutoUpdateHint =>
      'La posizione GPS viene acquisita automaticamente durante la ricerca. Puoi aggiornarla manualmente qui.';

  @override
  String get clearGpsConfirm =>
      'Cancellare la posizione GPS memorizzata? Puoi aggiornarla in qualsiasi momento.';

  @override
  String get pageNotFound => 'Pagina non trovata';

  @override
  String get deleteAllServerData => 'Elimina tutti i dati del server';

  @override
  String get deleteServerDataConfirm => 'Eliminare tutti i dati del server?';

  @override
  String get deleteEverything => 'Elimina tutto';

  @override
  String get allDataDeleted => 'Tutti i dati del server eliminati';

  @override
  String get disconnectConfirm => 'Disconnettere TankSync?';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get myServerData => 'I miei dati server';

  @override
  String get anonymousUuid => 'UUID anonimo';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Dati sincronizzati';

  @override
  String get pushTokens => 'Token push';

  @override
  String get priceReports => 'Segnalazioni prezzi';

  @override
  String get totalItems => 'Elementi totali';

  @override
  String get estimatedSize => 'Dimensione stimata';

  @override
  String get viewRawJson => 'Visualizza dati grezzi come JSON';

  @override
  String get exportJson => 'Esporta come JSON (appunti)';

  @override
  String get jsonCopied => 'JSON copiato negli appunti';

  @override
  String get rawDataJson => 'Dati grezzi (JSON)';

  @override
  String get close => 'Chiudi';

  @override
  String get account => 'Account';

  @override
  String get continueAsGuest => 'Continua come ospite';

  @override
  String get createAccount => 'Crea account';

  @override
  String get signIn => 'Accedi';

  @override
  String get upgradeToEmail => 'Crea account e-mail';

  @override
  String get savedRoutes => 'Percorsi salvati';

  @override
  String get noSavedRoutes => 'Nessun percorso salvato';

  @override
  String get noSavedRoutesHint =>
      'Cerca lungo un percorso e salvalo per un accesso rapido.';

  @override
  String get saveRoute => 'Salva percorso';

  @override
  String get routeName => 'Nome del percorso';
}
