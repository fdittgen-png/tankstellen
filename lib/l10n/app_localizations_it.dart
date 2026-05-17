// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get searchCriteriaTitle => 'Criteri di ricerca';

  @override
  String get searchCriteriaOpen => 'Cerca';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Entro $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tocca per iniziare la ricerca';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Cambiare paese?';

  @override
  String countryChangeBody(String country) {
    return 'Passare a $country modificherà:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Distanza';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Formato prezzo';

  @override
  String get countryChangeNote =>
      'I preferiti e i registri dei rifornimenti esistenti non vengono riscritti; solo le nuove voci usano le nuove unità.';

  @override
  String get countryChangeConfirm => 'Cambia';

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
  String get apiKeyFormatError =>
      'Formato non valido — UUID previsto (8-4-4-4-12)';

  @override
  String get supportProject => 'Supporta questo progetto';

  @override
  String get supportDescription =>
      'Questa app è gratuita, open source e senza pubblicità. Se la trovi utile, considera di supportare lo sviluppatore.';

  @override
  String get reportBug => 'Segnala un bug / Suggerisci una funzione';

  @override
  String get reportThisIssue => 'Segnala questo problema';

  @override
  String get reportAlreadySent => 'Hai già segnalato questo problema.';

  @override
  String get reportConsentTitle => 'Segnalare su GitHub?';

  @override
  String get reportConsentBody =>
      'Verrà aperta una segnalazione pubblica su GitHub con i dettagli dell\'errore riportati di seguito. Non vengono incluse coordinate GPS, chiavi API o dati personali.';

  @override
  String get reportConsentConfirm => 'Apri GitHub';

  @override
  String get reportConsentCancel => 'Annulla';

  @override
  String get configProfileSection => 'Profilo';

  @override
  String get configActiveProfile => 'Profilo attivo';

  @override
  String get configPreferredFuel => 'Carburante preferito';

  @override
  String get configCountry => 'Paese';

  @override
  String get configRouteSegment => 'Segmento di percorso';

  @override
  String get configApiKeysSection => 'Chiavi API';

  @override
  String get configTankerkoenigKey => 'Chiave API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Configurata';

  @override
  String get configApiKeyNotSet => 'Non impostata (modalità demo)';

  @override
  String get configApiKeyCommunity => 'Predefinita (chiave community)';

  @override
  String get searchLocationPlaceholder => 'Indirizzo, CAP o città';

  @override
  String get configEvKey => 'Chiave API ricarica EV';

  @override
  String get configEvKeyCustom => 'Chiave personalizzata';

  @override
  String get configEvKeyShared => 'Predefinita (condivisa)';

  @override
  String get configCloudSyncSection => 'Sincronizzazione cloud';

  @override
  String get configTankSyncConnected => 'Connesso';

  @override
  String get configTankSyncDisabled => 'Disabilitato';

  @override
  String get configAuthMode => 'Modalità di autenticazione';

  @override
  String get configAuthEmail => 'E-mail (persistente)';

  @override
  String get configAuthAnonymous => 'Anonimo (solo dispositivo)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Riepilogo privacy';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Preferiti, avvisi e stazioni ignorate sono sincronizzati con il tuo database privato\n• La posizione GPS e le chiavi API non lasciano mai il dispositivo\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Tutti i dati sono archiviati solo localmente su questo dispositivo\n• Nessun dato viene inviato a nessun server\n• Chiavi API cifrate nello spazio di archiviazione sicuro del dispositivo';

  @override
  String get configAuthNoteEmail =>
      'L\'account e-mail consente l\'accesso multi-dispositivo';

  @override
  String get configAuthNoteAnonymous =>
      'Account anonimo — dati legati a questo dispositivo';

  @override
  String get configNone => 'Nessuno';

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
  String get demoModeBannerAction => 'Ottieni prezzi in tempo reale';

  @override
  String get sortDistance => 'Distanza';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Valutazione';

  @override
  String get sortPriceDistance => 'Prezzo/km';

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
  String get forgetAllSyncedTripsButton =>
      'Elimina tutti i percorsi sincronizzati';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Eliminare tutti i percorsi sincronizzati?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Ogni riepilogo e dettaglio del percorso verrà rimosso dal server. La cronologia locale dei percorsi su questo dispositivo non sarà modificata.\n\nQuesta azione non può essere annullata.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Elimina tutti';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Tutti i percorsi sincronizzati rimossi dal server';

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

  @override
  String itineraryDeleted(String name) {
    return '$name eliminato';
  }

  @override
  String loadingRoute(String name) {
    return 'Caricamento percorso: $name';
  }

  @override
  String get refreshFailed => 'Aggiornamento non riuscito. Riprova.';

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
      'Configura l\'app in pochi semplici passaggi.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrati per ottenere una chiave API gratuita, oppure salta per esplorare l\'app con dati demo.';

  @override
  String get onboardingComplete => 'Tutto pronto!';

  @override
  String get onboardingCompleteHint =>
      'Puoi modificare queste impostazioni in qualsiasi momento nel tuo profilo.';

  @override
  String get onboardingBack => 'Indietro';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingFinish => 'Inizia';

  @override
  String crossBorderNearby(String country) {
    return '$country è vicino';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km dal confine';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Media qui: $price EUR ($count stazioni)';
  }

  @override
  String get allPricesView => 'Tutti i prezzi';

  @override
  String get compactView => 'Compatto';

  @override
  String get switchToAllPricesView => 'Passa alla vista tutti i prezzi';

  @override
  String get switchToCompactView => 'Passa alla vista compatta';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'Esaurito';

  @override
  String get gdprTitle => 'La tua privacy';

  @override
  String get gdprSubtitle =>
      'Questa app rispetta la tua privacy. Scegli quali dati condividere. Puoi modificare queste impostazioni in qualsiasi momento.';

  @override
  String get gdprLocationTitle => 'Accesso alla posizione';

  @override
  String get gdprLocationDescription =>
      'Le tue coordinate vengono inviate all\'API dei prezzi carburante per trovare le stazioni vicine. I dati di posizione non vengono mai archiviati su un server e non vengono usati per il tracciamento.';

  @override
  String get gdprLocationShort =>
      'Trova le stazioni di carburante vicine usando la tua posizione';

  @override
  String get gdprErrorReportingTitle => 'Segnalazione errori';

  @override
  String get gdprErrorReportingDescription =>
      'I rapporti di arresto anomalo anonimi aiutano a migliorare l\'app. Non vengono inclusi dati personali. I rapporti vengono inviati tramite Sentry solo se configurato.';

  @override
  String get gdprErrorReportingShort =>
      'Invia rapporti di arresto anomalo anonimi per migliorare l\'app';

  @override
  String get gdprCloudSyncTitle => 'Sincronizzazione cloud';

  @override
  String get gdprCloudSyncDescription =>
      'Sincronizza preferiti e avvisi su dispositivi tramite TankSync. Usa l\'autenticazione anonima. I tuoi dati sono cifrati in transito.';

  @override
  String get gdprCloudSyncShort =>
      'Sincronizza preferiti e avvisi su dispositivi';

  @override
  String get gdprLegalBasis =>
      'Base giuridica: art. 6, par. 1, lett. a) GDPR (Consenso). Puoi revocare il consenso in qualsiasi momento nelle Impostazioni.';

  @override
  String get gdprAcceptAll => 'Accetta tutto';

  @override
  String get gdprAcceptSelected => 'Accetta selezionati';

  @override
  String get gdprSettingsHint =>
      'Puoi modificare le tue scelte sulla privacy in qualsiasi momento.';

  @override
  String get routeSaved => 'Percorso salvato!';

  @override
  String get routeSaveFailed => 'Salvataggio percorso non riuscito';

  @override
  String get sqlCopied => 'SQL copiato negli appunti';

  @override
  String get connectionDataCopied => 'Dati di connessione copiati';

  @override
  String get accountDeleted => 'Account eliminato. Dati locali conservati.';

  @override
  String get switchedToAnonymous => 'Passato alla sessione anonima';

  @override
  String failedToSwitch(String error) {
    return 'Cambio non riuscito: $error';
  }

  @override
  String get topicUrlCopied => 'URL argomento copiato';

  @override
  String get testNotificationSent => 'Notifica di test inviata!';

  @override
  String get testNotificationFailed => 'Invio notifica di test non riuscito';

  @override
  String get pushUpdateFailed =>
      'Aggiornamento impostazione notifica push non riuscito';

  @override
  String get connectedAsGuest => 'Connesso come ospite';

  @override
  String get accountCreated => 'Account creato!';

  @override
  String get signedIn => 'Accesso effettuato!';

  @override
  String stationHidden(String name) {
    return '$name nascosta';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name rimossa dai preferiti';
  }

  @override
  String invalidApiKey(String error) {
    return 'Chiave API non valida: $error';
  }

  @override
  String get invalidQrCode => 'Formato codice QR non valido';

  @override
  String get invalidQrCodeTankSync =>
      'Codice QR non valido — formato TankSync atteso';

  @override
  String get tankSyncConnected => 'TankSync connesso!';

  @override
  String get syncCompleted => 'Sincronizzazione completata — dati aggiornati';

  @override
  String get deviceCodeCopied => 'Codice dispositivo copiato';

  @override
  String get undo => 'Annulla';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Inserisci un $label di $length cifre valido';
  }

  @override
  String get freshnessAgo => 'fa';

  @override
  String get freshnessStale => 'Non aggiornato';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Aggiornamento dati: $age';
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
      other: 'Dai $count stelle',
      one: 'Dai 1 stella',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Debole';

  @override
  String get passwordStrengthFair => 'Discreta';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordReqMinLength => 'Almeno 8 caratteri';

  @override
  String get passwordReqUppercase => 'Almeno 1 lettera maiuscola';

  @override
  String get passwordReqLowercase => 'Almeno 1 lettera minuscola';

  @override
  String get passwordReqDigit => 'Almeno 1 numero';

  @override
  String get passwordReqSpecial => 'Almeno 1 carattere speciale';

  @override
  String get passwordTooWeak => 'La password non soddisfa tutti i requisiti';

  @override
  String get brandFilterAll => 'Tutte';

  @override
  String get brandFilterNoHighway => 'No autostrada';

  @override
  String get swipeTutorialMessage =>
      'Scorri a destra per navigare, scorri a sinistra per rimuovere';

  @override
  String get swipeTutorialDismiss => 'Capito';

  @override
  String get alertStatsActive => 'Attivi';

  @override
  String get alertStatsToday => 'Oggi';

  @override
  String get alertStatsThisWeek => 'Questa settimana';

  @override
  String get privacyDashboardTitle => 'Dashboard privacy';

  @override
  String get privacyDashboardSubtitle =>
      'Visualizza, esporta o elimina i tuoi dati';

  @override
  String get privacyDashboardBanner =>
      'I tuoi dati ti appartengono. Qui puoi vedere tutto ciò che questa app archivia, esportarlo o eliminarlo.';

  @override
  String get privacyLocalData => 'Dati su questo dispositivo';

  @override
  String get privacyIgnoredStations => 'Stazioni ignorate';

  @override
  String get privacyRatings => 'Valutazioni stazioni';

  @override
  String get privacyPriceHistory => 'Stazioni cronologia prezzi';

  @override
  String get privacyProfiles => 'Profili di ricerca';

  @override
  String get privacyItineraries => 'Percorsi salvati';

  @override
  String get privacyCacheEntries => 'Voci nella cache';

  @override
  String get privacyApiKey => 'Chiave API archiviata';

  @override
  String get privacyEvApiKey => 'Chiave API EV archiviata';

  @override
  String get privacyEstimatedSize => 'Spazio di archiviazione stimato';

  @override
  String get privacySyncedData => 'Sincronizzazione cloud (TankSync)';

  @override
  String get privacySyncDisabled =>
      'La sincronizzazione cloud è disabilitata. Tutti i dati rimangono solo su questo dispositivo.';

  @override
  String get privacySyncMode => 'Modalità sincronizzazione';

  @override
  String get privacySyncUserId => 'ID utente';

  @override
  String get privacySyncDescription =>
      'Quando la sincronizzazione è abilitata, i preferiti, gli avvisi, le stazioni ignorate e le valutazioni vengono archiviati anche sul server TankSync.';

  @override
  String get privacyViewServerData => 'Visualizza dati server';

  @override
  String get privacyExportButton => 'Esporta tutti i dati come JSON';

  @override
  String get privacyExportSuccess => 'Dati esportati negli appunti';

  @override
  String get privacyExportCsvButton => 'Esporta tutti i dati come CSV';

  @override
  String get privacyExportCsvSuccess => 'Dati CSV esportati negli appunti';

  @override
  String get privacyDeleteButton => 'Elimina tutti i dati';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Copia registro errori negli appunti ($count)';
  }

  @override
  String get privacyDeleteTitle => 'Eliminare tutti i dati?';

  @override
  String get privacyDeleteBody =>
      'Verranno eliminati definitivamente:\n\n- Tutti i preferiti e i dati delle stazioni\n- Tutti i profili di ricerca\n- Tutti gli avvisi di prezzo\n- Tutta la cronologia prezzi\n- Tutti i dati memorizzati nella cache\n- La tua chiave API\n- Tutte le impostazioni dell\'app\n\nL\'app verrà ripristinata allo stato iniziale. Questa azione non può essere annullata.';

  @override
  String get privacyDeleteConfirm => 'Elimina tutto';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get amenities => 'Dotazioni';

  @override
  String get amenityShop => 'Negozio';

  @override
  String get amenityCarWash => 'Lavaggio';

  @override
  String get amenityAirPump => 'Aria';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Cibo';

  @override
  String get amenityAtm => 'Bancomat';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'Ricarica';

  @override
  String get paymentMethods => 'Metodi di pagamento';

  @override
  String get paymentMethodCash => 'Contanti';

  @override
  String get paymentMethodCard => 'Carta';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Carta carburante';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Paga con $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Confrontato con la media mobile degli ultimi 3 rifornimenti ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumo $value L/100 km, $delta rispetto alla tua media mobile';
  }

  @override
  String get drivingMode => 'Modalità guida';

  @override
  String get drivingExit => 'Esci';

  @override
  String get drivingNearestStation => 'Più vicina';

  @override
  String get drivingTapToUnlock => 'Tocca per sbloccare';

  @override
  String get drivingSafetyTitle => 'Avviso di sicurezza';

  @override
  String get drivingSafetyMessage =>
      'Non utilizzare l\'app mentre guidi. Accosta in un luogo sicuro prima di interagire con lo schermo. Il conducente è responsabile della guida sicura del veicolo in ogni momento.';

  @override
  String get drivingSafetyAccept => 'Ho capito';

  @override
  String get voiceAnnouncementsTitle => 'Annunci vocali';

  @override
  String get voiceAnnouncementsDescription =>
      'Annuncia le stazioni economiche vicine durante la guida';

  @override
  String get voiceAnnouncementsEnabled => 'Abilita annunci vocali';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Solo sotto $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance chilometri avanti, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Raggio annunci';

  @override
  String get voiceAnnouncementCooldown => 'Intervallo ripetizione';

  @override
  String get nearestStations => 'Stazioni piu vicine';

  @override
  String get nearestStationsHint =>
      'Trova le stazioni piu vicine con la tua posizione attuale';

  @override
  String get consumptionLogTitle => 'Consumo carburante';

  @override
  String get consumptionLogMenuTitle => 'Registro consumi';

  @override
  String get consumptionLogMenuSubtitle =>
      'Tieni traccia dei rifornimenti e calcola L/100km';

  @override
  String get consumptionStatsTitle => 'Statistiche consumo';

  @override
  String get addFillUp => 'Aggiungi rifornimento';

  @override
  String get noFillUpsTitle => 'Nessun rifornimento ancora';

  @override
  String get noFillUpsSubtitle =>
      'Registra il tuo primo rifornimento per iniziare a monitorare i consumi.';

  @override
  String get fillUpDate => 'Data';

  @override
  String get liters => 'Litri';

  @override
  String get odometerKm => 'Odometro (km)';

  @override
  String get notesOptional => 'Note (opzionale)';

  @override
  String get stationPreFilled => 'Stazione precompilata';

  @override
  String get statAvgConsumption => 'Media L/100km';

  @override
  String get statAvgCostPerKm => 'Costo medio/km';

  @override
  String get statTotalLiters => 'Litri totali';

  @override
  String get statTotalSpent => 'Spesa totale';

  @override
  String get statFillUpCount => 'Rifornimenti';

  @override
  String get fieldRequired => 'Obbligatorio';

  @override
  String get fieldInvalidNumber => 'Numero non valido';

  @override
  String get carbonDashboardTitle => 'Dashboard CO2';

  @override
  String get carbonEmptyTitle => 'Nessun dato ancora';

  @override
  String get carbonEmptySubtitle =>
      'Registra i rifornimenti per vedere la tua dashboard CO2.';

  @override
  String get carbonSummaryTotalCost => 'Costo totale';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 totale';

  @override
  String get monthlyCostsTitle => 'Costi mensili';

  @override
  String get monthlyEmissionsTitle => 'Emissioni CO2 mensili';

  @override
  String get vehiclesTitle => 'I miei veicoli';

  @override
  String get vehiclesMenuTitle => 'I miei veicoli';

  @override
  String get vehiclesMenuSubtitle =>
      'Batteria, connettori, preferenze di ricarica';

  @override
  String get vehiclesEmptyMessage =>
      'Aggiungi la tua auto per filtrare per connettore e stimare i costi di ricarica.';

  @override
  String get vehiclesWizardTitle => 'I miei veicoli (opzionale)';

  @override
  String get vehiclesWizardSubtitle =>
      'Aggiungi la tua auto per precompilare il registro consumi e abilitare i filtri connettori EV. Puoi saltare questo passaggio e aggiungere veicoli in seguito.';

  @override
  String get vehiclesWizardNoneYet => 'Nessun veicolo configurato ancora.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veicoli',
      one: '1 veicolo',
    );
    return 'Hai $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Salta per completare la configurazione — puoi aggiungere veicoli in qualsiasi momento dalle Impostazioni.';

  @override
  String get fillUpVehicleLabel => 'Veicolo';

  @override
  String get fillUpVehicleNone => 'Nessun veicolo';

  @override
  String get fillUpVehicleRequired => 'Il veicolo è obbligatorio';

  @override
  String get reportScanError => 'Segnala errore di scansione';

  @override
  String get pickStationTitle => 'Seleziona una stazione';

  @override
  String get pickStationHelper =>
      'Inizia il rifornimento da una stazione nota in modo che prezzi, marchio e tipo di carburante vengano precompilati.';

  @override
  String get pickStationEmpty =>
      'Nessuna stazione preferita ancora — aggiungine dalla Ricerca o dai Preferiti, oppure salta e compila manualmente.';

  @override
  String get pickStationSkip => 'Salta — aggiungi senza stazione';

  @override
  String get scanPump => 'Scansiona pompa';

  @override
  String get scanPayment => 'Scansiona QR pagamento';

  @override
  String get qrPaymentBeneficiary => 'Beneficiario';

  @override
  String get qrPaymentAmount => 'Importo';

  @override
  String get qrPaymentEpcTitle => 'Pagamento SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Nessun campo decodificato';

  @override
  String get qrPaymentOpenInBank => 'Apri nell\'app bancaria';

  @override
  String get qrPaymentLaunchFailed =>
      'Nessuna app disponibile per aprire questo codice';

  @override
  String get qrPaymentUnknownTitle => 'Codice non riconosciuto';

  @override
  String get qrPaymentCopyRaw => 'Copia testo grezzo';

  @override
  String get qrPaymentCopiedRaw => 'Copiato negli appunti';

  @override
  String get qrPaymentReport => 'Segnala questa scansione';

  @override
  String get qrPaymentEpcCopied =>
      'Dati bancari copiati — incolla nella tua app bancaria';

  @override
  String get qrScannerGuidance => 'Punta la fotocamera su un codice QR';

  @override
  String get qrScannerPermissionDenied =>
      'L\'accesso alla fotocamera è necessario per scansionare i codici QR.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'L\'accesso alla fotocamera è stato negato. Apri le impostazioni per concederlo.';

  @override
  String get qrScannerRetryPermission => 'Riprova';

  @override
  String get qrScannerOpenSettings => 'Apri impostazioni';

  @override
  String get qrScannerTimeout =>
      'Nessun codice QR rilevato. Avvicinati o riprova.';

  @override
  String get qrScannerRetry => 'Riprova';

  @override
  String get torchOn => 'Attiva flash';

  @override
  String get torchOff => 'Disattiva flash';

  @override
  String get obdNoAdapter => 'Nessun adattatore OBD2 nel raggio';

  @override
  String get obdOdometerUnavailable => 'Impossibile leggere l\'odometro';

  @override
  String get obdPermissionDenied =>
      'Concedi l\'autorizzazione Bluetooth nelle impostazioni di sistema';

  @override
  String get obdAdapterUnresponsive =>
      'L\'adattatore non risponde — accendi il quadro e riprova';

  @override
  String get obdPickerTitle => 'Seleziona un adattatore OBD2';

  @override
  String get obdPickerScanning => 'Ricerca adattatori…';

  @override
  String get obdPickerConnecting => 'Connessione in corso…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Chiaro';

  @override
  String get themeModeDark => 'Scuro';

  @override
  String get themeModeSystem => 'Segui sistema';

  @override
  String get tripRecordingTitle => 'Registrazione percorso';

  @override
  String get tripSummaryTitle => 'Riepilogo percorso';

  @override
  String get tripMetricDistance => 'Distanza';

  @override
  String get tripMetricSpeed => 'Velocità';

  @override
  String get tripMetricFuelUsed => 'Carburante usato';

  @override
  String get tripMetricAvgConsumption => 'Media';

  @override
  String get tripMetricElapsed => 'Trascorso';

  @override
  String get tripMetricOdometer => 'Odometro';

  @override
  String get tripStop => 'Ferma registrazione';

  @override
  String get tripPause => 'Pausa';

  @override
  String get tripResume => 'Riprendi';

  @override
  String get tripBannerRecording => 'Registrazione percorso';

  @override
  String get tripBannerPaused => 'Percorso in pausa — tocca per riprendere';

  @override
  String get navConsumption => 'Consumo';

  @override
  String get vehicleBaselineSectionTitle => 'Calibrazione di riferimento';

  @override
  String get vehicleBaselineEmpty =>
      'Nessun campione ancora — avvia un percorso OBD2 per iniziare ad apprendere il profilo carburante di questo veicolo.';

  @override
  String get vehicleBaselineProgress =>
      'Appreso da campioni in diverse situazioni di guida.';

  @override
  String get vehicleBaselineReset => 'Reimposta baseline situazione di guida';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Reimpostare la baseline della situazione di guida?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Questo elimina tutti i campioni appresi per questo veicolo. Tornerai ai valori predefiniti di avviamento a freddo finché nuovi percorsi non riempiono nuovamente il profilo.';

  @override
  String get vehicleAdapterSectionTitle => 'Adattatore OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Nessun adattatore abbinato. Abbinane uno affinché l\'app possa riconnettersi automaticamente la prossima volta.';

  @override
  String get vehicleAdapterUnnamed => 'Adattatore sconosciuto';

  @override
  String get vehicleAdapterPair => 'Abbina adattatore';

  @override
  String get vehicleAdapterForget => 'Dimentica adattatore';

  @override
  String get achievementsTitle => 'Obiettivi';

  @override
  String get achievementFirstTrip => 'Primo percorso';

  @override
  String get achievementFirstTripDesc => 'Registra il tuo primo percorso OBD2.';

  @override
  String get achievementFirstFillUp => 'Primo rifornimento';

  @override
  String get achievementFirstFillUpDesc =>
      'Registra il tuo primo rifornimento.';

  @override
  String get achievementTenTrips => '10 percorsi';

  @override
  String get achievementTenTripsDesc => 'Registra 10 percorsi OBD2.';

  @override
  String get achievementZeroHarsh => 'Guida fluida';

  @override
  String get achievementZeroHarshDesc =>
      'Completa un percorso di 10 km o più senza frenate o accelerazioni brusche.';

  @override
  String get achievementEcoWeek => 'Settimana eco';

  @override
  String get achievementEcoWeekDesc =>
      'Guida per 7 giorni consecutivi con almeno un percorso fluido al giorno.';

  @override
  String get achievementPriceWin => 'Affare carburante';

  @override
  String get achievementPriceWinDesc =>
      'Registra un rifornimento che batte la media dei 30 giorni della stazione di almeno il 5%.';

  @override
  String get syncBaselinesToggleTitle => 'Condividi profili veicolo appresi';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Carica le baseline di consumo per veicolo così un secondo dispositivo può riutilizzarle.';

  @override
  String get obd2StatusConnected => 'Adattatore OBD2: connesso';

  @override
  String get obd2StatusAttempting => 'Adattatore OBD2: connessione in corso';

  @override
  String get obd2StatusUnreachable => 'Adattatore OBD2: non raggiungibile';

  @override
  String get obd2StatusPermissionDenied =>
      'Adattatore OBD2: autorizzazione Bluetooth necessaria';

  @override
  String get obd2StatusConnectedBody => 'Pronto per registrare un percorso.';

  @override
  String get obd2StatusAttemptingBody => 'Connessione in background…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adattatore fuori portata o già in uso da un\'altra app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Concedi l\'autorizzazione Bluetooth nelle impostazioni di sistema per riconnettersi automaticamente.';

  @override
  String get obd2StatusNoAdapter => 'Nessun adattatore abbinato';

  @override
  String get obd2StatusForget => 'Dimentica adattatore';

  @override
  String get tripHistoryTitle => 'Cronologia percorsi';

  @override
  String get tripHistoryEmptyTitle => 'Nessun percorso ancora';

  @override
  String get tripHistoryEmptySubtitle =>
      'Connetti un adattatore OBD2 e registra un percorso per iniziare a costruire la tua cronologia di guida.';

  @override
  String get tripHistoryUnknownDate => 'Data sconosciuta';

  @override
  String get situationIdle => 'Fermo';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urbano';

  @override
  String get situationHighway => 'Autostrada';

  @override
  String get situationDecel => 'Decelerazione';

  @override
  String get situationClimbing => 'Salita / carico';

  @override
  String get situationHardAccel => 'Accelerazione brusca';

  @override
  String get situationFuelCut => 'Taglio carburante — costa';

  @override
  String get tripSaveAsFillUp => 'Salva come rifornimento';

  @override
  String get tripSaveRecording => 'Salva percorso';

  @override
  String get tripDiscard => 'Scarta';

  @override
  String obdOdometerRead(int km) {
    return 'Odometro letto: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Non impostato';

  @override
  String get wizardVehicleTapToEdit => 'Tocca per modificare';

  @override
  String get wizardVehicleDefaultBadge => 'Predefinito';

  @override
  String get wizardProfileChoiceHint =>
      'Scegli come vuoi usare l\'app. Puoi cambiarlo in seguito nelle Impostazioni.';

  @override
  String get wizardProfileChoiceFooter =>
      'Puoi cambiare la tua scelta in qualsiasi momento da Impostazioni → Modalità d\'uso.';

  @override
  String get wizardProfileBasicName => 'Base';

  @override
  String get wizardProfileBasicDescription =>
      'Prezzi carburante e ricarica EV più economici nelle vicinanze. Preferiti e avvisi di prezzo.';

  @override
  String get wizardProfileMediumName => 'Medio';

  @override
  String get wizardProfileMediumDescription =>
      'Tutto di Base, più il tracciamento manuale dei rifornimenti e della ricarica EV.';

  @override
  String get wizardProfileFullName => 'Completo';

  @override
  String get wizardProfileFullDescription =>
      'Tutto di Medio, più la registrazione automatica dei percorsi OBD2, punteggi di guida e tessere fedeltà.';

  @override
  String get wizardProfileCustomName => 'Personalizzato';

  @override
  String get wizardProfileCustomDescription =>
      'La tua combinazione di funzionalità. Regola ogni interruttore di seguito.';

  @override
  String get useModeSectionHint =>
      'Adatta l\'app al tuo utilizzo reale. La scelta di un preset abilita il set di funzionalità corrispondente.';

  @override
  String get useModeCustomSettingsDescription =>
      'La tua combinazione di funzionalità non corrisponde a nessun preset. Scegli uno sopra per sovrascrivere, o continua a personalizzare le singole funzionalità nella sezione di seguito.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Modalità d\'uso impostata su $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Veicolo predefinito (opzionale)';

  @override
  String get profileDefaultVehicleNone => 'Nessun predefinito';

  @override
  String get profileFuelFromVehicleHint =>
      'Il tipo di carburante viene ricavato dal tuo veicolo predefinito. Rimuovi il veicolo per scegliere direttamente il carburante.';

  @override
  String get consumptionNoVehicleTitle => 'Prima aggiungi un veicolo';

  @override
  String get consumptionNoVehicleBody =>
      'I rifornimenti sono attribuiti a un veicolo. Aggiungi la tua auto per iniziare a registrare i consumi.';

  @override
  String get vehicleAdd => 'Aggiungi veicolo';

  @override
  String get vehicleAddTitle => 'Aggiungi veicolo';

  @override
  String get vehicleEditTitle => 'Modifica veicolo';

  @override
  String get vehicleDeleteTitle => 'Eliminare il veicolo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Rimuovere \"$name\" dai tuoi profili?';
  }

  @override
  String get vehicleNameLabel => 'Nome';

  @override
  String get vehicleNameHint => 'es. La mia Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustione';

  @override
  String get vehicleTypeHybrid => 'Ibrido';

  @override
  String get vehicleTypeEv => 'Elettrico';

  @override
  String get vehicleEvSectionTitle => 'Elettrico';

  @override
  String get vehicleCombustionSectionTitle => 'Combustione';

  @override
  String get vehicleBatteryLabel => 'Capacità batteria (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Potenza di ricarica massima (kW)';

  @override
  String get vehicleConnectorsLabel => 'Connettori supportati';

  @override
  String get vehicleMinSocLabel => 'SoC min %';

  @override
  String get vehicleMaxSocLabel => 'SoC max %';

  @override
  String get vehicleTankLabel => 'Capacità serbatoio (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Carburante preferito';

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
  String get connectorThreePin => '3 pin';

  @override
  String get evShowOnMap => 'Mostra stazioni EV';

  @override
  String get evAvailableOnly => 'Solo disponibili';

  @override
  String get evMinPower => 'Potenza min';

  @override
  String get evMaxPower => 'Potenza max';

  @override
  String get evOperator => 'Operatore';

  @override
  String get evLastUpdate => 'Ultimo aggiornamento';

  @override
  String get evStatusAvailable => 'Disponibile';

  @override
  String get evStatusOccupied => 'Occupato';

  @override
  String get evStatusOutOfOrder => 'Fuori servizio';

  @override
  String get openOnlyFilter => 'Solo aperte';

  @override
  String get saveAsDefaults => 'Salva come predefiniti';

  @override
  String get criteriaSavedToProfile => 'Salvato come predefiniti';

  @override
  String get profileNotFound => 'Nessun profilo attivo';

  @override
  String get updatingFavorites => 'Aggiornamento dei tuoi preferiti...';

  @override
  String get fetchingLatestPrices => 'Recupero dei prezzi più recenti';

  @override
  String get noDataAvailable => 'Nessun dato';

  @override
  String get configAndPrivacy => 'Configurazione e privacy';

  @override
  String get searchToSeeMap => 'Cerca per vedere le stazioni sulla mappa';

  @override
  String get evPowerAny => 'Qualsiasi';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profilo';

  @override
  String get sectionLocation => 'Posizione';

  @override
  String get tooltipBack => 'Indietro';

  @override
  String get tooltipClose => 'Chiudi';

  @override
  String get tooltipClearSearch => 'Cancella input di ricerca';

  @override
  String get tooltipUseGps => 'Usa posizione GPS';

  @override
  String get tooltipShowPassword => 'Mostra password';

  @override
  String get tooltipHidePassword => 'Nascondi password';

  @override
  String get evConnectorsLabel => 'Connettori disponibili';

  @override
  String get evConnectorsNone => 'Nessuna informazione sui connettori';

  @override
  String get switchToEmail => 'Passa a e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Mantieni i dati, aggiungi accesso da altri dispositivi';

  @override
  String get switchToAnonymousAction => 'Passa ad anonimo';

  @override
  String get switchToAnonymousSubtitle =>
      'Mantieni i dati locali, usa una nuova sessione anonima';

  @override
  String get linkDevice => 'Collega dispositivo';

  @override
  String get shareDatabase => 'Condividi database';

  @override
  String get disconnectAction => 'Disconnetti';

  @override
  String get disconnectSubtitle =>
      'Interrompi la sincronizzazione (dati locali conservati)';

  @override
  String get deleteAccountAction => 'Elimina account';

  @override
  String get deleteAccountSubtitle =>
      'Rimuovi tutti i dati del server definitivamente';

  @override
  String get localOnly => 'Solo locale';

  @override
  String get localOnlySubtitle =>
      'Opzionale: sincronizza preferiti, avvisi e valutazioni su dispositivi';

  @override
  String get setupCloudSync => 'Configura sincronizzazione cloud';

  @override
  String get disconnectTitle => 'Disconnettere TankSync?';

  @override
  String get disconnectBody =>
      'La sincronizzazione cloud verrà disabilitata. I tuoi dati locali (preferiti, avvisi, cronologia) vengono conservati su questo dispositivo. I dati del server non vengono eliminati.';

  @override
  String get deleteAccountTitle => 'Eliminare l\'account?';

  @override
  String get deleteAccountBody =>
      'Questo elimina definitivamente tutti i tuoi dati dal server (preferiti, avvisi, valutazioni, percorsi). I dati locali su questo dispositivo vengono conservati.\n\nQuesta azione non può essere annullata.';

  @override
  String get switchToAnonymousTitle => 'Passare ad anonimo?';

  @override
  String get switchToAnonymousBody =>
      'Verrai disconnesso dal tuo account e-mail e continuerai con una nuova sessione anonima.\n\nI tuoi dati locali (preferiti, avvisi) vengono conservati su questo dispositivo e verranno sincronizzati con il nuovo account anonimo.';

  @override
  String get switchAction => 'Cambia';

  @override
  String get helpBannerCriteria =>
      'I valori predefiniti del tuo profilo sono precompilati. Regola i criteri di seguito per affinare la ricerca.';

  @override
  String get helpBannerAlerts =>
      'Imposta una soglia di prezzo per una stazione. Riceverai una notifica quando i prezzi scendono al di sotto. I controlli vengono eseguiti ogni 30 minuti.';

  @override
  String get helpBannerConsumption =>
      'Registra ogni rifornimento per monitorare il tuo consumo reale e l\'impronta di CO₂. Scorri a sinistra per eliminare una voce.';

  @override
  String get helpBannerVehicles =>
      'Aggiungi i tuoi veicoli in modo che i rifornimenti e le preferenze carburante vengano impostati correttamente. Il primo veicolo diventa il tuo predefinito.';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get onboardingPreferencesTitle => 'Le tue preferenze';

  @override
  String get onboardingZipHelper => 'Usato quando il GPS non è disponibile';

  @override
  String get onboardingRadiusHelper => 'Raggio maggiore = più risultati';

  @override
  String get onboardingPrivacy =>
      'Queste impostazioni sono archiviate solo sul tuo dispositivo e non vengono mai condivise.';

  @override
  String get onboardingLandingTitle => 'Schermata iniziale';

  @override
  String get onboardingLandingHint =>
      'Scegli quale schermata si apre quando avvii l\'app.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Resta fuori dall\'app — ma non chiuderla.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Apri Sparkilo una volta dopo ogni riavvio.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple riattiva Sparkilo solo dopo che l\'hai aperta almeno una volta dal riavvio del telefono. Dopodiché, i tuoi percorsi vengono registrati automaticamente.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Non chiudere Sparkilo dal task switcher.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Forza chiusura\" dice a iOS di smettere di riavviare l\'app. I tuoi percorsi smetteranno di essere registrati finché non apri di nuovo Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Quando iOS chiede la posizione \"Sempre\", dì sì.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Il fallback che registra il tuo percorso quando l\'adattatore OBD2 è lento ha bisogno della posizione in background. Non la condividiamo mai.';

  @override
  String get scanReceipt => 'Scansiona scontrino';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Carburante';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Autostrada';

  @override
  String get ratingModeLocal => 'Locale';

  @override
  String get ratingModePrivate => 'Privato';

  @override
  String get ratingModeShared => 'Condiviso';

  @override
  String get ratingDescLocal =>
      'Valutazioni salvate solo su questo dispositivo';

  @override
  String get ratingDescPrivate =>
      'Sincronizzato con il tuo database (non visibile agli altri)';

  @override
  String get ratingDescShared => 'Visibile a tutti gli utenti del tuo database';

  @override
  String get errorNoEvApiKey =>
      'Chiave API OpenChargeMap non configurata. Aggiungine una nelle Impostazioni per cercare stazioni di ricarica EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Il fornitore dati ($host) sta servendo un certificato TLS scaduto o non valido. L\'app non può caricare dati da questa fonte finché il fornitore non risolve il problema. Contatta $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed non disponibile. Si usa $current.';
  }

  @override
  String get errorTitleApiKey => 'Chiave API richiesta';

  @override
  String get errorTitleLocation => 'Posizione non disponibile';

  @override
  String get errorHintNoStations =>
      'Prova ad aumentare il raggio di ricerca o cerca una posizione diversa.';

  @override
  String get errorHintApiKey =>
      'Configura la tua chiave API nelle Impostazioni.';

  @override
  String get errorHintConnection =>
      'Controlla la tua connessione Internet e riprova.';

  @override
  String get errorHintRouting =>
      'Calcolo percorso non riuscito. Controlla la tua connessione Internet e riprova.';

  @override
  String get errorHintFallback => 'Riprova o cerca per CAP / nome città.';

  @override
  String get alertsLoadErrorTitle => 'Impossibile caricare gli avvisi';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Controllo avvisi in background non riuscito';

  @override
  String get detailsLabel => 'Dettagli';

  @override
  String get remove => 'Rimuovi';

  @override
  String get showKey => 'Mostra chiave';

  @override
  String get hideKey => 'Nascondi chiave';

  @override
  String get syncOptionalTitle => 'TankSync è opzionale';

  @override
  String get syncOptionalDescription =>
      'La tua app funziona perfettamente senza sincronizzazione cloud. TankSync ti consente di sincronizzare preferiti, avvisi e valutazioni su dispositivi usando Supabase (livello gratuito disponibile).';

  @override
  String get syncHowToConnectQuestion => 'Come vorresti connetterti?';

  @override
  String get syncCreateOwnTitle => 'Crea il mio database';

  @override
  String get syncCreateOwnSubtitle =>
      'Progetto Supabase gratuito — ti guideremo passo dopo passo';

  @override
  String get syncJoinExistingTitle => 'Unisciti a un database esistente';

  @override
  String get syncJoinExistingSubtitle =>
      'Scansiona il codice QR del proprietario del database o incolla le credenziali';

  @override
  String get syncChooseAccountType => 'Scegli il tipo di account';

  @override
  String get syncAccountTypeAnonymous => 'Anonimo';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Immediato, senza e-mail. Dati legati a questo dispositivo.';

  @override
  String get syncAccountTypeEmail => 'Account e-mail';

  @override
  String get syncAccountTypeEmailDesc =>
      'Accedi da qualsiasi dispositivo. Recupera i dati se il telefono viene perso.';

  @override
  String get syncHaveAccountSignIn => 'Hai già un account? Accedi';

  @override
  String get syncCreateNewAccount => 'Crea nuovo account';

  @override
  String get syncTestConnection => 'Testa connessione';

  @override
  String get syncTestingConnection => 'Test in corso...';

  @override
  String get syncConnectButton => 'Connetti';

  @override
  String get syncConnectingButton => 'Connessione in corso...';

  @override
  String get syncDatabaseReady => 'Database pronto!';

  @override
  String get syncDatabaseNeedsSetup => 'Il database deve essere configurato';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Mancante';

  @override
  String get syncSqlEditorInstructions =>
      'Copia il codice SQL qui sotto ed eseguilo nel tuo editor SQL di Supabase (Dashboard → SQL Editor → Nuova query → Incolla → Esegui)';

  @override
  String get syncCopySqlButton => 'Copia SQL negli appunti';

  @override
  String get syncRecheckSchemaButton => 'Ricontrolla schema';

  @override
  String get syncDoneButton => 'Fine';

  @override
  String syncSignedInAs(String email) {
    return 'Accesso effettuato come $email';
  }

  @override
  String get syncEmailDescription =>
      'I tuoi dati si sincronizzano su tutti i dispositivi con questa e-mail.';

  @override
  String get syncSwitchToAnonymousTitle => 'Passa ad anonimo';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continua senza e-mail, nuova sessione anonima';

  @override
  String get syncGuestDescription => 'Anonimo, senza e-mail.';

  @override
  String get syncOrDivider => 'oppure';

  @override
  String get syncHowToSyncQuestion => 'Come vorresti sincronizzare?';

  @override
  String get syncOfflineDescription =>
      'La tua app funziona completamente offline. La sincronizzazione cloud è opzionale.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Condividi preferiti e valutazioni con tutti gli utenti';

  @override
  String get syncModePrivateTitle => 'Database privato';

  @override
  String get syncModePrivateSubtitle =>
      'Il tuo Supabase — controllo completo dei dati';

  @override
  String get syncModeGroupTitle => 'Unisciti a un gruppo';

  @override
  String get syncModeGroupSubtitle => 'Database condiviso per famiglia o amici';

  @override
  String get syncPrivacyShared => 'Condiviso';

  @override
  String get syncPrivacyPrivate => 'Privato';

  @override
  String get syncPrivacyGroup => 'Gruppo';

  @override
  String get syncStayOfflineButton => 'Rimani offline';

  @override
  String get syncSuccessTitle => 'Connessione avvenuta con successo!';

  @override
  String get syncSuccessDescription =>
      'I tuoi dati verranno ora sincronizzati automaticamente.';

  @override
  String get syncWizardTitleConnect => 'Connetti TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Il tuo database';

  @override
  String get syncSetupTitleJoinGroup => 'Unisciti a un gruppo';

  @override
  String get syncSetupTitleAccount => 'Il tuo account';

  @override
  String get syncWizardBack => 'Indietro';

  @override
  String get syncWizardNext => 'Avanti';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Passaggio $current di $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Crea un progetto Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tocca \"Apri Supabase\" qui sotto\n2. Crea un account gratuito (se non ne hai uno)\n3. Clicca \"New Project\"\n4. Scegli un nome e una regione\n5. Attendi ~2 minuti per l\'avvio';

  @override
  String get syncWizardOpenSupabase => 'Apri Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Abilita accessi anonimi';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Nella tua dashboard Supabase:\n   Authentication → Providers\n2. Trova \"Anonymous Sign-ins\"\n3. Attivalo\n4. Clicca \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Apri impostazioni autenticazione';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copia le tue credenziali';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Vai a Settings → API nella tua dashboard\n2. Copia il \"Project URL\"\n3. Copia la chiave \"anon public\"\n4. Incollali qui sotto';

  @override
  String get syncWizardOpenApiSettings => 'Apri impostazioni API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Unisciti a un database esistente';

  @override
  String get syncWizardScanQrCode => 'Scansiona codice QR';

  @override
  String get syncWizardAskOwnerQr =>
      'Chiedi al proprietario del database di mostrarti il suo codice QR\n(Impostazioni → TankSync → Condividi)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Chiedi al proprietario del database di mostrare il codice QR';

  @override
  String get syncWizardEnterManuallyTitle => 'Inserisci manualmente';

  @override
  String get syncWizardOrEnterManually => 'oppure inserisci manualmente';

  @override
  String get syncWizardUrlHelperText =>
      'Spazi e interruzioni di riga rimossi automaticamente';

  @override
  String get syncCredentialsPrivateHint =>
      'Inserisci le credenziali del tuo progetto Supabase. Puoi trovarle nella tua dashboard sotto Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL database';

  @override
  String get syncCredentialsAccessKeyLabel => 'Chiave di accesso';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Conferma password';

  @override
  String get authPleaseEnterEmail => 'Inserisci la tua e-mail';

  @override
  String get authInvalidEmail => 'Indirizzo e-mail non valido';

  @override
  String get authPasswordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get authConnectAnonymously => 'Connetti in modo anonimo';

  @override
  String get authCreateAccountAndConnect => 'Crea account e connetti';

  @override
  String get authSignInAndConnect => 'Accedi e connetti';

  @override
  String get authAnonymousSegment => 'Anonimo';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Accesso immediato, senza e-mail. Dati legati a questo dispositivo.';

  @override
  String get authEmailDescription =>
      'Accedi da qualsiasi dispositivo. Recupera i tuoi dati se il telefono viene perso.';

  @override
  String get authSyncAcrossDevices =>
      'Sincronizza i dati automaticamente su tutti i tuoi dispositivi.';

  @override
  String get authNewHereCreateAccount => 'Prima volta? Crea account';

  @override
  String get ntfyCardTitle => 'Notifiche push (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Abilita push ntfy.sh';

  @override
  String get ntfyEnableSubtitle => 'Ricevi avvisi di prezzo tramite ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'URL argomento';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Copia URL argomento';

  @override
  String get ntfySendTestButton => 'Invia notifica di test';

  @override
  String get ntfyFdroidHint =>
      'Installa l\'app ntfy da F-Droid per ricevere notifiche push sul tuo dispositivo.';

  @override
  String get ntfyConnectFirstHint =>
      'Prima connetti TankSync per abilitare le notifiche push.';

  @override
  String get linkDeviceScreenTitle => 'Collega dispositivo';

  @override
  String get linkDeviceThisDeviceLabel => 'Questo dispositivo';

  @override
  String get linkDeviceShareCodeHint =>
      'Condividi questo codice con il tuo altro dispositivo:';

  @override
  String get linkDeviceNotConnected => 'Non connesso';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copia codice';

  @override
  String get linkDeviceImportSectionTitle => 'Importa da un altro dispositivo';

  @override
  String get linkDeviceImportDescription =>
      'Inserisci il codice dispositivo del tuo altro dispositivo per importare i suoi preferiti, avvisi, veicoli e registro consumi. Ogni dispositivo mantiene il proprio profilo e i propri valori predefiniti.';

  @override
  String get linkDeviceCodeFieldLabel => 'Codice dispositivo';

  @override
  String get linkDeviceCodeFieldHint =>
      'Incolla l\'UUID dall\'altro dispositivo';

  @override
  String get linkDeviceImportButton => 'Importa dati';

  @override
  String get linkDeviceHowItWorksTitle => 'Come funziona';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Sul dispositivo A: copia il codice dispositivo sopra\n2. Sul dispositivo B: incollalo nel campo \"Codice dispositivo\"\n3. Tocca \"Importa dati\" per unire preferiti, avvisi, veicoli e registri consumi\n4. Entrambi i dispositivi avranno tutti i dati combinati\n\nOgni dispositivo mantiene la propria identità anonima e il proprio profilo (carburante preferito, veicolo predefinito, schermata iniziale). I dati vengono uniti, non spostati.';

  @override
  String get vehicleSetActive => 'Imposta attivo';

  @override
  String get swipeHide => 'Nascondi';

  @override
  String get evChargingSection => 'Ricarica EV';

  @override
  String get fuelStationsSection => 'Stazioni carburante';

  @override
  String get yourRating => 'La tua valutazione';

  @override
  String get noStorageUsed => 'Nessuno spazio utilizzato';

  @override
  String get aboutReportBug => 'Segnala un bug / Suggerisci una funzionalità';

  @override
  String get aboutSupportProject => 'Supporta questo progetto';

  @override
  String get aboutSupportDescription =>
      'Questa app è gratuita, open source e senza pubblicità. Se la trovi utile, considera di supportare lo sviluppatore.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'I prezzi del carburante in Lussemburgo sono regolati dal governo e uniformi in tutto il paese.';

  @override
  String get luxembourgFuelUnleaded95 => 'Senza piombo 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Senza piombo 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'GPL';

  @override
  String get luxembourgPricesUnavailable =>
      'I prezzi regolamentati del Lussemburgo non sono disponibili.';

  @override
  String get reportIssueTitle => 'Segnala un problema';

  @override
  String get enterCorrection => 'Inserisci la correzione';

  @override
  String get reportNoBackendAvailable =>
      'Impossibile inviare la segnalazione: nessun servizio di segnalazione è configurato per questo paese. Abilita TankSync nelle Impostazioni per inviare segnalazioni alla community.';

  @override
  String get correctName => 'Correggi il nome della stazione';

  @override
  String get correctAddress => 'Correggi l\'indirizzo';

  @override
  String get wrongE85Price => 'Prezzo E85 errato';

  @override
  String get wrongE98Price => 'Prezzo Super 98 errato';

  @override
  String get wrongLpgPrice => 'Prezzo GPL errato';

  @override
  String get wrongStationName => 'Nome stazione errato';

  @override
  String get wrongStationAddress => 'Indirizzo errato';

  @override
  String get independentStation => 'Stazione indipendente';

  @override
  String get serviceRemindersSection => 'Promemoria manutenzione';

  @override
  String get serviceRemindersEmpty =>
      'Nessun promemoria ancora — scegli un preset sopra.';

  @override
  String get addServiceReminder => 'Aggiungi promemoria';

  @override
  String get serviceReminderPresetOil => 'Olio (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Cambio olio';

  @override
  String get serviceReminderPresetTires => 'Pneumatici (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Pneumatici';

  @override
  String get serviceReminderPresetInspection => 'Revisione (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Revisione';

  @override
  String get serviceReminderLabel => 'Etichetta';

  @override
  String get serviceReminderInterval => 'Intervallo (km)';

  @override
  String get serviceReminderLastService => 'Ultima manutenzione';

  @override
  String get serviceReminderMarkDone => 'Segna come fatto';

  @override
  String get serviceReminderDueTitle => 'Manutenzione in scadenza';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label è in scadenza — $kmOver km dopo l\'intervallo.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Registrati su OPINET per ottenere una chiave API gratuita';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registrati su CNE per ottenere una chiave API gratuita';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'È la tua auto?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders cil., $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Info parziali (offline). Puoi modificare di seguito.';

  @override
  String get vinDecodeError => 'Impossibile decodificare questo VIN';

  @override
  String get vinInvalidFormat => 'Formato VIN non valido';

  @override
  String get obd2PauseBannerTitle =>
      'Connessione OBD2 persa — registrazione in pausa';

  @override
  String get obd2PauseBannerResume => 'Riprendi registrazione';

  @override
  String get obd2PauseBannerEnd => 'Termina registrazione';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Calibrazione consumo aggiornata per $vehicleName — precisione migliorata del $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Reimpostare l\'efficienza volumetrica?';

  @override
  String get veResetConfirmBody =>
      'Questo eliminerà l\'efficienza volumetrica (η_v) appresa e ripristinerà il valore predefinito (0,85). Le stime del flusso carburante a livello di percorso torneranno alla costante del produttore finché il calibratore non raccoglie nuovi campioni dai prossimi percorsi.';

  @override
  String get alertsRadiusSectionTitle => 'Avvisi di raggio';

  @override
  String get alertsRadiusAdd => 'Aggiungi avviso di raggio';

  @override
  String get alertsRadiusEmptyTitle => 'Nessun avviso di raggio ancora';

  @override
  String get alertsRadiusEmptyCta => 'Crea un avviso di raggio';

  @override
  String get alertsRadiusCreateTitle => 'Crea avviso di raggio';

  @override
  String get alertsRadiusLabelHint => 'Etichetta (es. Diesel casa)';

  @override
  String get alertsRadiusFuelType => 'Tipo di carburante';

  @override
  String get alertsRadiusThreshold => 'Soglia (€/L)';

  @override
  String get alertsRadiusKm => 'Raggio (km)';

  @override
  String get alertsRadiusCenterGps => 'Usa la mia posizione';

  @override
  String get alertsRadiusCenterPostalCode => 'Codice postale';

  @override
  String get alertsRadiusSave => 'Salva';

  @override
  String get alertsRadiusCancel => 'Annulla';

  @override
  String get alertsRadiusDeleteConfirm => 'Eliminare l\'avviso di raggio?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 connesso: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Abbina un adattatore OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel in calo alle stazioni vicine';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stazioni sono scese fino a $maxDropCents¢ nell\'ultima ora';
  }

  @override
  String get fillUpSavedSnackbar => 'Rifornimento salvato';

  @override
  String get radiusAlertsEntryTitle => 'Avvisi di raggio e statistiche';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Ricevi notifiche quando i prezzi scendono vicino a te';

  @override
  String get notFoundTitle => 'Pagina non trovata';

  @override
  String notFoundBody(String location) {
    return '\"$location\" non trovato.';
  }

  @override
  String get notFoundHomeButton => 'Home';

  @override
  String get consumptionTabHiddenNotice =>
      'La scheda Consumo è stata nascosta dalle impostazioni del tuo profilo.';

  @override
  String get swipeBetweenTabsHint =>
      'Suggerimento: scorri a sinistra o a destra per passare tra le schede.';

  @override
  String get discardChangesTitle => 'Scartare le modifiche?';

  @override
  String get discardChangesBody =>
      'Hai modifiche non salvate. Se esci ora, verranno scartate.';

  @override
  String get discardChangesConfirm => 'Scarta';

  @override
  String get discardChangesKeepEditing => 'Continua a modificare';

  @override
  String get tankSyncSectionSubtitle =>
      'Sincronizzazione cloud su tutti i tuoi dispositivi';

  @override
  String get mapUnavailable => 'Mappa non disponibile';

  @override
  String get routeNameHintExample => 'es. Parigi → Lione';

  @override
  String get priceStatsCurrent => 'Attuale';

  @override
  String get tankerkoenigApiKeyLabel => 'Chiave API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Chiave API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Tocca per aggiornare la posizione GPS';

  @override
  String get nameLabel => 'Nome';

  @override
  String get obd2ErrorPermissionDenied =>
      'È necessaria l\'autorizzazione Bluetooth per connettersi a un adattatore OBD2.';

  @override
  String get obd2ErrorBluetoothOff => 'Attiva il Bluetooth e riprova.';

  @override
  String get obd2ErrorScanTimeout =>
      'Nessun adattatore OBD2 trovato nelle vicinanze. Assicurati che sia collegato e acceso.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'L\'adattatore OBD2 non ha risposto. Inserisci il quadro e riprova.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'L\'adattatore OBD2 ha inviato una risposta non riconosciuta. Potrebbe essere incompatibile: prova un altro adattatore.';

  @override
  String get obd2ErrorDisconnected =>
      'L\'adattatore OBD2 si è disconnesso. Riconnettilo e riprova.';

  @override
  String get onboardingExploreDemoData => 'Esplora con dati demo';

  @override
  String get achievementSmoothDriver => 'Serie di guida fluida';

  @override
  String get achievementSmoothDriverDesc =>
      'Effettua 5 percorsi di fila con un punteggio di guida fluida di 80 o superiore.';

  @override
  String get achievementColdStartAware => 'Esperto di avviamento a freddo';

  @override
  String get achievementColdStartAwareDesc =>
      'Mantieni il costo del carburante di avviamento a freddo di un intero mese sotto il 2% del totale — combina i tragitti brevi.';

  @override
  String get achievementHighwayMaster => 'Re dell\'autostrada';

  @override
  String get achievementHighwayMasterDesc =>
      'Completa un percorso di 30 km o più a velocità costante con un punteggio di guida fluida di 90 o superiore.';

  @override
  String get authErrorNoNetwork =>
      'Nessuna connessione di rete. Riprova più tardi.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail o password non valide. Controlla le tue credenziali.';

  @override
  String get authErrorUserAlreadyExists =>
      'Questa e-mail è già registrata. Prova ad accedere.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Controlla la tua e-mail e conferma prima il tuo account.';

  @override
  String get authErrorGeneric => 'Accesso non riuscito. Riprova.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Posizione in background — solo per la registrazione automatica';

  @override
  String get autoRecordConsentExplanationTitle =>
      'Informazioni su questa autorizzazione';

  @override
  String get autoRecordConsentExplanationBody =>
      'La registrazione automatica ha bisogno della posizione in background per rilevare quando inizi a guidare con l\'app chiusa. Questa concessione viene usata solo dalla registrazione automatica — la ricerca stazioni e il centraggio mappa usano un\'autorizzazione separata per la posizione in primo piano.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Capito';

  @override
  String get autoRecordConsentExplanationTooltip => 'Cosa significa questo?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Tocca per gestire nelle impostazioni di sistema';

  @override
  String get autoRecordSectionTitle => 'Registrazione automatica';

  @override
  String get autoRecordToggleLabel => 'Registra percorsi automaticamente';

  @override
  String get autoRecordStatusActiveLabel =>
      'La registrazione automatica si attiverà la prossima volta che sali in auto.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Abbina un adattatore OBD2 per abilitare la registrazione automatica.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Consenti la posizione in background affinché la registrazione automatica continui a funzionare con lo schermo spento.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Abbina un adattatore';

  @override
  String get autoRecordSpeedThresholdLabel => 'Velocità di avvio (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Ritardo di salvataggio dopo la disconnessione (secondi)';

  @override
  String get autoRecordPairedAdapterLabel => 'Adattatore abbinato';

  @override
  String get autoRecordPairedAdapterNone =>
      'Nessun adattatore abbinato. Prima abbinane uno tramite l\'avvio guidato OBD2.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Posizione in background consentita';

  @override
  String get autoRecordBackgroundLocationRequest => 'Richiedi autorizzazione';

  @override
  String get autoRecordBackgroundLocationRationaleTitle => 'Perché \"Sempre\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'La registrazione automatica trasmette le coordinate GPS dal servizio in primo piano OBD-II mentre lo schermo è spento, così il percorso rimane preciso. Android richiede l\'opzione \"Sempre\" affinché continui a funzionare dopo che il dispositivo si blocca.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Apri impostazioni';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Autorizzazione posizione richiesta';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Impossibile richiedere la posizione in background';

  @override
  String get autoRecordBadgeClearTooltip => 'Azzera contatore';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Abbina un adattatore nella sezione di seguito per abilitare la registrazione automatica';

  @override
  String get exportBackupTooltip => 'Esporta backup';

  @override
  String get exportBackupReady => 'Backup pronto — scegli una destinazione';

  @override
  String get exportBackupFailed => 'Esportazione backup non riuscita — riprova';

  @override
  String get brokenMapChipVerifying => 'Verifica sensore MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Letture MAP sospette';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Il sensore MAP legge in modo errato — le letture carburante potrebbero essere del 50–80% troppo basse. Prova un altro adattatore.';

  @override
  String get brokenMapBannerHardDisable =>
      'Sensore MAP inaffidabile. Vengono mostrate le medie dei rifornimenti anziché il flusso carburante in tempo reale.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Sensore MAP: verificato ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Sensore MAP: verifica in corso ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Sensore MAP: sospetto ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Sensore MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Sensore MAP: $posterior% ± $margin% (verificato)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostica sensore MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Affidabilità MAP difettoso: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count osservazioni registrate';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verificato funzionante';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Il sensore MAP di questo veicolo non è ancora stato osservato.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Adattatori nella lista nera';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Nessun adattatore nella lista nera.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — segnalato $percent% difettoso';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Azzera';

  @override
  String get brokenMapRevPromptTitle => 'Accelera il motore';

  @override
  String get brokenMapRevPromptBody =>
      'Dai brevemente gas affinché l\'app possa verificare che il sensore MAP risponda.';

  @override
  String get brokenMapRevPromptConfirm => 'Fatto — ho accelerato';

  @override
  String get calibrationAdvancedTitle => 'Calibrazione avanzata';

  @override
  String get calibrationDisplacementLabel => 'Cilindrata motore (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Efficienza volumetrica (η_v)';

  @override
  String get calibrationAfrLabel => 'Rapporto aria-carburante (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Densità carburante (g/L)';

  @override
  String get calibrationSourceDetected => '(rilevato dal VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catalogo: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(predefinito)';

  @override
  String get calibrationSourceManual => '(manuale)';

  @override
  String get calibrationResetToDetected => 'Ripristina al valore rilevato';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (calibrato, $samples campioni)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (apprendimento, $samples campioni)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (predefinito — nessun pieno ancora)';

  @override
  String get calibrationResetLearner => 'Reimposta il learner';

  @override
  String get calibrationBasisAtkinson => 'Ciclo Atkinson';

  @override
  String get calibrationBasisVnt => 'Diesel VNT + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbocompresso + DI';

  @override
  String get calibrationBasisTurbo => 'Turbocompresso';

  @override
  String get calibrationBasisNaDi => 'Aspirazione naturale + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catalogo: $makeModel — $basis predefinito)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Il tuo $makeModel è contrassegnato come diesel ma corrisponde a una voce di catalogo a benzina. Tocca per aggiornare.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aggiorna';

  @override
  String get consumptionTabFuel => 'Carburante';

  @override
  String get consumptionTabCharging => 'Ricarica';

  @override
  String get noChargingLogsTitle => 'Nessun registro di ricarica ancora';

  @override
  String get noChargingLogsSubtitle =>
      'Registra la tua prima sessione di ricarica per iniziare a monitorare EUR/100 km e kWh/100 km.';

  @override
  String get addChargingLog => 'Registra ricarica';

  @override
  String get addChargingLogTitle => 'Registra sessione di ricarica';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Costo totale';

  @override
  String get chargingTimeMin => 'Tempo di ricarica (min)';

  @override
  String get chargingStationName => 'Stazione (opzionale)';

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
      'Occorre un registro precedente per il confronto';

  @override
  String get chargingLogButtonLabel => 'Registra ricarica';

  @override
  String get chargingCostTrendTitle => 'Andamento costo ricarica';

  @override
  String get chargingEfficiencyTitle => 'Efficienza (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Dati insufficienti ancora';

  @override
  String get chargingChartsMonthAxis => 'Mese';

  @override
  String get gdprCommunityWaitTimeTitle => 'Tempi di attesa della community';

  @override
  String get gdprCommunityWaitTimeShort =>
      'Condividi in modo anonimo i tempi di attesa alle stazioni';

  @override
  String get gdprCommunityWaitTimeDescription =>
      'Condividi in modo anonimo quando arrivi a una stazione di carburante e quando la lasci, così l\'app può mostrare i tempi di attesa tipici. Non vengono caricate coordinate di posizione — solo l\'ID della stazione.';

  @override
  String get consoFeatureGroupTitle => 'Conso';

  @override
  String get consoFeatureGroupDescription =>
      'Tieni traccia dei consumi — rifornimenti manuali o registrazione automatica percorsi OBD2.';

  @override
  String get consoModeOff => 'Disattivo';

  @override
  String get consoModeFuel => 'Carburante';

  @override
  String get consoModeFuelAndTrips => 'Carburante + Percorsi';

  @override
  String get consoModeOffDescription =>
      'Nessuna scheda Conso e nessuna sezione impostazioni Conso.';

  @override
  String get consoModeFuelDescription =>
      'Solo rifornimenti manuali. Utile senza un adattatore OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Aggiunge la registrazione automatica dei percorsi OBD2. Richiede un adattatore abbinato.';

  @override
  String get consoSubsectionVehicles => 'I miei veicoli';

  @override
  String get consoSubsectionTrajets => 'Percorsi (OBD2)';

  @override
  String get consoSubsectionToggles => 'Guida';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count rifornimenti parziali in attesa del pieno — non inclusi nella media',
      one:
          '1 rifornimento parziale in attesa del pieno — non incluso nella media',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% del carburante da auto-correzioni — rivedi le voci';
  }

  @override
  String get fillUpCorrectionLabel => 'Auto-correzione — tocca per modificare';

  @override
  String get fillUpCorrectionEditTitle => 'Modifica auto-correzione';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Questa voce è stata generata automaticamente per colmare il divario tra i percorsi registrati e il carburante erogato. Modifica i valori se conosci i dati effettivi.';

  @override
  String get fillUpCorrectionDelete => 'Elimina correzione';

  @override
  String get fillUpCorrectionStation => 'Nome stazione (opzionale)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grecia)';

  @override
  String get greeceCommunityApiNotice =>
      'Alimentato dall\'API fuelpricesgr mantenuta dalla community';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Alimentato da pretcarburant.ro (Consiglio della Concorrenza + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stazioni in $country a $km km — €$price/L più economico';
  }

  @override
  String get crossBorderTapToSwitch => 'Tocca per cambiare paese';

  @override
  String get crossBorderDismissTooltip => 'Ignora';

  @override
  String get insightCardTitle => 'Comportamenti più dispendiosi';

  @override
  String get insightEmptyState =>
      'Nessuna inefficienza notevole — continua così!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motore oltre i 3000 RPM ($pctTime% del percorso): sprecato $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count accelerazioni brusche: sprecato $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Fermo al minimo ($pctTime% del percorso): sprecato $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% del percorso';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'In marcia bassa ($minutes min)';
  }

  @override
  String get drivingScoreCardTitle => 'Punteggio di guida';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Punteggio composito da fermo al minimo, accelerazioni brusche, frenate brusche e tempo ad alto numero di giri. Un confronto \"migliore del X% dei percorsi passati\" sarà aggiunto in un aggiornamento futuro.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Punteggio di guida $score su 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Fermo al minimo';

  @override
  String get drivingScorePenaltyHardAccel => 'Accelerazioni brusche';

  @override
  String get drivingScorePenaltyHardBrake => 'Frenate brusche';

  @override
  String get drivingScorePenaltyHighRpm => 'Alto numero di giri';

  @override
  String get drivingScorePenaltyFullThrottle => 'Acceleratore a fondo';

  @override
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L risparmiati';
  }

  @override
  String get ecoRouteHint =>
      'Guida più intelligente — privilegia l\'autostrada costante rispetto alle scorciatoie tortuose.';

  @override
  String get favoritesShareAction => 'Condividi';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — preferiti del $date';
  }

  @override
  String get favoritesShareError =>
      'Impossibile generare l\'immagine da condividere';

  @override
  String get featureManagementSectionTitle => 'Gestione funzionalità';

  @override
  String get featureManagementSectionSubtitle =>
      'Attiva o disattiva le singole funzionalità. Alcune funzionalità dipendono da altre — gli interruttori sono disabilitati finché i prerequisiti non sono soddisfatti.';

  @override
  String get featureLabel_obd2TripRecording => 'Registrazione percorsi OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Cattura i percorsi automaticamente tramite OBD2.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification =>
      'Punteggi di guida e badge guadagnati.';

  @override
  String get featureLabel_hapticEcoCoach => 'Coach eco aptico';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Feedback aptico in tempo reale durante un percorso.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sincronizzazione multi-dispositivo tramite Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analisi consumi';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Scheda analisi rifornimenti e percorsi.';

  @override
  String get featureLabel_baselineSync => 'Sincronizzazione baseline';

  @override
  String get featureDescription_baselineSync =>
      'Sincronizza le baseline di guida tramite TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Risultati di ricerca unificati';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Elenco risultati unico che combina stazioni carburante ed EV.';

  @override
  String get featureLabel_priceAlerts => 'Avvisi di prezzo';

  @override
  String get featureDescription_priceAlerts =>
      'Notifiche di calo prezzo basate su soglia.';

  @override
  String get featureLabel_priceHistory => 'Cronologia prezzi';

  @override
  String get featureDescription_priceHistory =>
      'Grafici prezzi 30 giorni sui dettagli della stazione.';

  @override
  String get featureLabel_routePlanning => 'Pianificazione percorso';

  @override
  String get featureDescription_routePlanning =>
      'Fermata più economica lungo il tuo percorso.';

  @override
  String get featureLabel_evCharging => 'Ricarica EV';

  @override
  String get featureDescription_evCharging =>
      'Stazioni di ricarica tramite OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Guida al risparmio carburante usando i semafori OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Percorso GPS';

  @override
  String get featureDescription_gpsTripPath =>
      'Salva i campioni del percorso GPS insieme a ogni viaggio.';

  @override
  String get featureLabel_autoRecord => 'Registrazione automatica';

  @override
  String get featureDescription_autoRecord =>
      'Avvia automaticamente un percorso quando l\'adattatore OBD2 si connette a un veicolo in movimento.';

  @override
  String get featureLabel_showFuel => 'Mostra stazioni carburante';

  @override
  String get featureDescription_showFuel =>
      'Mostra i risultati delle stazioni benzina/diesel nella ricerca e sulla mappa.';

  @override
  String get featureLabel_showElectric => 'Mostra stazioni di ricarica';

  @override
  String get featureDescription_showElectric =>
      'Mostra le stazioni di ricarica EV nella ricerca e sulla mappa.';

  @override
  String get featureLabel_showConsumptionTab => 'Scheda consumi';

  @override
  String get featureDescription_showConsumptionTab =>
      'Mostra la scheda analisi consumi nella barra di navigazione inferiore.';

  @override
  String get featureBlockedEnable_gamification =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Prima abilita TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureBlockedEnable_showFuel => 'Prerequisiti non soddisfatti';

  @override
  String get featureBlockedEnable_showElectric =>
      'Prerequisiti non soddisfatti';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Previsione prezzi TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Modello di previsione prezzi sul dispositivo — l\'inferenza viene eseguita localmente; caratteristiche e previsioni non lasciano mai il dispositivo.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Prima abilita la cronologia prezzi';

  @override
  String get featureLabel_fuelCalculator => 'Calcolatore carburante';

  @override
  String get featureDescription_fuelCalculator =>
      'Calcolatore costo carburante raggiungibile dai risultati di ricerca.';

  @override
  String get featureLabel_carbonDashboard => 'Dashboard CO2';

  @override
  String get featureDescription_carbonDashboard =>
      'Dashboard impronta CO2 raggiungibile dalla scheda Consumo.';

  @override
  String get featureLabel_experimentalOemPids => 'PID OEM sperimentali';

  @override
  String get featureDescription_experimentalOemPids =>
      'Leggi i litri esatti del serbatoio tramite PID specifici del produttore sugli adattatori supportati.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Prima abilita la registrazione percorsi OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Scansiona QR pagamento';

  @override
  String get featureDescription_paymentQrScan =>
      'Lettore QR scan-to-pay nella schermata dettagli stazione.';

  @override
  String get featureLabel_communityPriceReports =>
      'Segnalazioni prezzi community';

  @override
  String get featureDescription_communityPriceReports =>
      'Segnala il prezzo di una stazione dalla schermata dettagli stazione.';

  @override
  String get feedbackConsentTitle => 'Inviare la segnalazione su GitHub?';

  @override
  String get feedbackConsentBody =>
      'Verrà creato un ticket pubblico nel nostro repository GitHub con la tua foto e il testo OCR. Non vengono inviati dati personali (posizione, ID account). Continuare?';

  @override
  String get feedbackConsentContinue => 'Continua';

  @override
  String get feedbackConsentCancel => 'Annulla';

  @override
  String get feedbackConsentLater => 'Più tardi';

  @override
  String get feedbackTokenSectionTitle => 'Feedback scansione errata (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Per aprire automaticamente un ticket GitHub da una scansione non riuscita, incolla un GitHub PAT (ambito `public_repo` sul repository tankstellen). Altrimenti la condivisione manuale rimane disponibile.';

  @override
  String get feedbackTokenStatusSet => 'Token configurato';

  @override
  String get feedbackTokenStatusUnset => 'Nessun token';

  @override
  String get feedbackTokenSet => 'Imposta';

  @override
  String get feedbackTokenClear => 'Cancella';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel =>
      'Verificato dall\'adattatore';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Non corrisponde alla lettura dell\'adattatore';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'La tua voce: $userL L. L\'adattatore dice: $adapterL L (delta dalla cattura del livello carburante prima/dopo). Usare il valore dell\'adattatore?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Mantieni la mia voce';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Usa il valore dell\'adattatore';

  @override
  String get scanReceiptNoData => 'Nessun dato scontrino trovato — riprova';

  @override
  String get scanReceiptSuccess =>
      'Scontrino scansionato — verifica i valori. Tocca \"Segnala errore di scansione\" di seguito se qualcosa non va.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scansione non riuscita: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Display della pompa non leggibile — riprova';

  @override
  String get scanPumpSuccess =>
      'Display pompa scansionato — verifica i valori.';

  @override
  String scanPumpFailed(String error) {
    return 'Scansione pompa non riuscita: $error';
  }

  @override
  String get badScanReportTitle => 'Segnala un errore di scansione';

  @override
  String get badScanReportTitleReceipt =>
      'Segnala un errore di scansione — Scontrino';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Segnala un errore di scansione — Display pompa';

  @override
  String get pumpScanFailureTitle => 'Display illeggibile';

  @override
  String get pumpScanFailureBody =>
      'La scansione non è riuscita a leggere il display della pompa. Cosa vuoi fare?';

  @override
  String get pumpScanFailureCorrectManually => 'Correggi manualmente';

  @override
  String get pumpScanFailureReport => 'Segnala';

  @override
  String get pumpScanFailureRemove => 'Rimuovi foto';

  @override
  String get badScanReportHint =>
      'Condivideremo la foto dello scontrino e entrambi i set di valori affinché la prossima build possa imparare questo layout.';

  @override
  String get badScanReportShareAction => 'Condividi segnalazione + foto';

  @override
  String get badScanReportFieldBrandLayout => 'Layout marchio';

  @override
  String get badScanReportFieldTotal => 'Totale';

  @override
  String get badScanReportFieldPricePerLiter => 'Prezzo/L';

  @override
  String get badScanReportFieldStation => 'Stazione';

  @override
  String get badScanReportFieldFuel => 'Carburante';

  @override
  String get badScanReportFieldDate => 'Data';

  @override
  String get badScanReportHeaderField => 'Campo';

  @override
  String get badScanReportHeaderScanned => 'Scansionato';

  @override
  String get badScanReportHeaderYouTyped => 'Hai digitato';

  @override
  String get badScanReportCreateTicket => 'Crea segnalazione';

  @override
  String get badScanReportOpenInBrowser => 'Apri nel browser';

  @override
  String get badScanReportFallbackToShare =>
      'Invio non riuscito — condivisione manuale';

  @override
  String get fillUpSectionWhatTitle => 'Cosa hai rifornito';

  @override
  String get fillUpSectionWhatSubtitle => 'Carburante, quantità, prezzo';

  @override
  String get fillUpSectionWhereTitle => 'Dove eri';

  @override
  String get fillUpSectionWhereSubtitle => 'Stazione, odometro, note';

  @override
  String get fillUpImportFromLabel => 'Importa da…';

  @override
  String get fillUpImportSheetTitle => 'Importa dati rifornimento';

  @override
  String get fillUpImportReceiptLabel => 'Scontrino';

  @override
  String get fillUpImportReceiptDescription =>
      'Scansiona uno scontrino cartaceo con la fotocamera';

  @override
  String get fillUpImportPumpLabel => 'Display pompa';

  @override
  String get fillUpImportPumpDescription =>
      'Leggi Betrag / Preis dal display LCD della pompa';

  @override
  String get fillUpImportObdLabel => 'Adattatore OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Leggi l\'odometro dalla porta OBD-II tramite Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Prezzo per litro';

  @override
  String get vehicleHeaderPlateLabel => 'Targa';

  @override
  String get vehicleHeaderUntitled => 'Nuovo veicolo';

  @override
  String get vehicleSectionIdentityTitle => 'Identità';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nome e VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Propulsione';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Come si muove questo veicolo';

  @override
  String get calibrationModeLabel => 'Modalità calibrazione';

  @override
  String get calibrationModeRule => 'Basata su regole';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'La modalità basata su regole assegna ogni campione di guida esattamente a una situazione. La modalità fuzzy lo distribuisce su tutte in base all\'adattabilità — più fluida intorno ai 60 km/h o con gradienti variabili, ma più lenta a riempire tutti i bucket.';

  @override
  String get profileGamificationToggleTitle => 'Mostra obiettivi e punteggi';

  @override
  String get profileGamificationToggleSubtitle =>
      'Quando disattivato, badge, punteggi e icone trofeo sono nascosti nell\'app.';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostica campionamento GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps lacune',
      one: '1 lacuna',
      zero: 'nessuna lacuna',
    );
    return '$count campioni · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Intervallo mediano: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Catturato durante la registrazione per verificare la cadenza GPS quando il telefono è in standby.';

  @override
  String get hapticEcoCoachSectionTitle => 'Guida';

  @override
  String get hapticEcoCoachSettingTitle => 'Coach eco in tempo reale';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Leggero feedback aptico + suggerimento su schermo quando pigi il gas durante la crociera';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Giù l\'acceleratore — il rilascio del gas fa risparmiare di più';

  @override
  String get anonKeyLabel => 'Chiave Anon';

  @override
  String get anonKeyHideTooltip => 'Nascondi chiave';

  @override
  String get anonKeyShowTooltip => 'Mostra chiave per verifica';

  @override
  String anonKeyTooLong(int length) {
    return 'La chiave è troppo lunga ($length caratteri) — verifica la presenza di testo extra';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'La chiave sembra corretta ($length caratteri)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'La chiave dovrebbe essere un JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'La chiave potrebbe essere troncata ($length di ~208 caratteri attesi)';
  }

  @override
  String get anonKeyExceedsMax => 'La chiave supera la lunghezza massima';

  @override
  String get qrShareTitle => 'Condividi il tuo database';

  @override
  String get qrShareSubtitle =>
      'Gli altri possono scansionare questo codice QR per connettersi';

  @override
  String get qrShareCopyAsText => 'Copia come testo';

  @override
  String get authInfoTitle => 'Perché creare un account?';

  @override
  String get authInfoBenefit1 =>
      '• Sincronizza preferiti, avvisi e percorsi salvati su dispositivi';

  @override
  String get authInfoBenefit2 =>
      '• Prepara un percorso sul telefono, usalo in auto';

  @override
  String get authInfoBenefit3 =>
      '• Nessun dato viene condiviso con terze parti';

  @override
  String get authInfoBenefit4 =>
      '• Puoi eliminare il tuo account in qualsiasi momento';

  @override
  String get privacyLocalDataEmpty =>
      'Nessun elemento archiviato ancora. Aggiungi un preferito o imposta un avviso di prezzo per vedere le voci qui.';

  @override
  String get privacyHideEmptyRows => 'Nascondi righe vuote';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostra $count righe vuote',
      one: 'Mostra $count riga vuota',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Configurazione chiave API (opzionale)';

  @override
  String get apiKeySetupDescription =>
      'Registrati per ottenere una chiave API gratuita, oppure salta per esplorare l\'app con dati demo.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Registrazione $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Inserendo una chiave API accetti i termini di $provider. La ridistribuzione dei dati è vietata.';
  }

  @override
  String get calculatorDistanceHint => 'es. 150';

  @override
  String get calculatorConsumptionHint => 'es. 7.0';

  @override
  String get calculatorPriceHint => 'es. 1.899';

  @override
  String get routeStrategyLabel => 'Strategia:';

  @override
  String get routeStrategyUniform => 'Uniforme';

  @override
  String get routeStrategyBalanced => 'Bilanciata';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (sperimentale)';

  @override
  String get glideCoachBetaSubtitle =>
      'Leggero feedback aptico quando rallenti prima di un semaforo rosso. Disattivato di default — rischio di distrazione.';

  @override
  String get consentSyncTripsTitle => 'Sincronizza registrazioni percorsi';

  @override
  String get consentSyncTripsSubtitle =>
      'Backup percorsi OBD2 + GPS su TankSync. Multi-dispositivo, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Abilita la sincronizzazione cloud sopra per fare il backup dei percorsi.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Accedi con un account e-mail per sincronizzare i viaggi tra dispositivi.';

  @override
  String get consentHideDetails => 'Nascondi dettagli';

  @override
  String get consentShowDetails => 'Mostra dettagli';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Link non valido';

  @override
  String invalidLinkBody(String path) {
    return 'Il link \"$path\" non è valido.';
  }

  @override
  String get home => 'Home';

  @override
  String get loyaltySettingsTitle => 'Carte fedeltà carburante';

  @override
  String get loyaltySettingsSubtitle =>
      'Applica il tuo sconto fedeltà ai prezzi visualizzati';

  @override
  String get loyaltyMenuTitle => 'Carte fedeltà carburante';

  @override
  String get loyaltyMenuSubtitle =>
      'Applica sconti per litro da Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Aggiungi carta';

  @override
  String get loyaltyAddCardSheetTitle => 'Aggiungi carta fedeltà carburante';

  @override
  String get loyaltyBrandLabel => 'Marchio';

  @override
  String get loyaltyCardLabelLabel => 'Etichetta (opzionale)';

  @override
  String get loyaltyDiscountLabel => 'Sconto (per litro)';

  @override
  String get loyaltyDiscountInvalid => 'Inserisci un numero positivo';

  @override
  String get loyaltyDeleteConfirmTitle => 'Eliminare la carta?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Questa carta smetterà di applicare il suo sconto.';

  @override
  String get loyaltyEmptyTitle => 'Nessuna carta fedeltà carburante ancora';

  @override
  String get loyaltyEmptyBody =>
      'Aggiungi una carta per applicare automaticamente il tuo sconto per litro alle stazioni corrispondenti.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Rilevato aumento graduale RPM al minimo';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Gli RPM al minimo sono aumentati del $percent% negli ultimi $tripCount percorsi. Possibile segnale precoce di un filtro dell\'aria intasato o di derive del sensore.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Possibile restrizione dell\'aspirazione';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Il consumo di carburante in crociera è diminuito del $percent% negli ultimi $tripCount percorsi. Possibile segnale di un filtro dell\'aria intasato o aspirazione ristretta — vale la pena un controllo.';
  }

  @override
  String get maintenanceActionDismiss => 'Ignora';

  @override
  String get maintenanceActionSnooze => 'Posticipa di 30 giorni';

  @override
  String get consumptionMonthlyInsightsTitle => 'Questo mese vs il mese scorso';

  @override
  String get consumptionMonthlyTripsLabel => 'Percorsi';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Tempo di guida';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distanza';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Consumo medio';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Servono almeno 3 percorsi al mese per il confronto';

  @override
  String get obd2CapabilitySectionTitle => 'Capacità adattatore';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'PID OEM';

  @override
  String get obd2CapabilityFullCan => 'CAN completo';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Per i litri esatti nel serbatoio su Peugeot/Citroën, l\'app supporta OBDLink MX+/LX/CX (chip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Overlay diagnostico OBD2 abilitato';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Overlay diagnostico OBD2 disabilitato';

  @override
  String get obd2DebugOverlayClearButton => 'Azzera';

  @override
  String get obd2DebugOverlayCloseButton => 'Chiudi';

  @override
  String get obd2DebugOverlayTitle => 'Breadcrumb OBD2';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Impossibile raggiungere \'$adapterName\' — scegli un altro adattatore';
  }

  @override
  String get onboardingObd2StepTitle => 'Connetti il tuo adattatore OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Collega il tuo adattatore OBD2 alla porta dell\'auto e accendi il quadro. Leggeremo il VIN e inseriremo i dettagli del motore per te.';

  @override
  String get onboardingObd2ConnectButton => 'Connetti adattatore';

  @override
  String get onboardingObd2SkipButton => 'Forse più tardi';

  @override
  String get onboardingObd2ReadingVin => 'Lettura VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Impossibile leggere il VIN — inserisci manualmente';

  @override
  String get onboardingObd2ConnectFailed =>
      'Impossibile connettersi all\'adattatore. Puoi riprovare o saltare.';

  @override
  String get onboardingPickUseMode =>
      'Scegli una modalità d\'uso per continuare.';

  @override
  String get alertsRadiusFrequencyLabel => 'Frequenza di controllo';

  @override
  String get alertsRadiusFrequencyDaily => 'Una volta al giorno';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Due volte al giorno';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tre volte al giorno';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Quattro volte al giorno';

  @override
  String get radiusAlertPickOnMap => 'Seleziona sulla mappa';

  @override
  String get radiusAlertMapPickerTitle => 'Seleziona il centro dell\'avviso';

  @override
  String get radiusAlertMapPickerConfirm => 'Conferma';

  @override
  String get radiusAlertMapPickerCancel => 'Annulla';

  @override
  String get radiusAlertMapPickerHint =>
      'Trascina la mappa per posizionare il centro dell\'avviso';

  @override
  String get radiusAlertCenterFromMap => 'Posizione dalla mappa';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel vicino a $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Una stazione è a $price € (obiettivo: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sessione';

  @override
  String get speedConsumptionCardTitle => 'Consumo per velocità';

  @override
  String get speedBandIdleJam => 'Fermo / ingorgo';

  @override
  String get speedBandUrban => 'Urbano (10–50)';

  @override
  String get speedBandSuburban => 'Suburbano (50–80)';

  @override
  String get speedBandRural => 'Extraurbano (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Crociera eco (100–115)';

  @override
  String get speedBandMotorway => 'Autostrada (115–130)';

  @override
  String get speedBandMotorwayFast => 'Autostrada veloce (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Registra 30+ minuti di percorsi con l\'adattatore OBD2 per sbloccare l\'analisi velocità/consumo.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent% della guida';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Servono più dati';

  @override
  String get splashLoadingLabel => 'Caricamento Sparkilo';

  @override
  String get tankLevelTitle => 'Livello serbatoio';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km di autonomia';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Ultimo rifornimento: $date · $count percorso/i da allora';
  }

  @override
  String get tankLevelMethodObd2 => 'Misurato da OBD2';

  @override
  String get tankLevelMethodDistanceFallback => 'stima basata sulla distanza';

  @override
  String get tankLevelMethodMixed => 'misurazione mista';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Registra un rifornimento per vedere il livello del serbatoio';

  @override
  String get tankLevelDetailSheetTitle => 'Percorsi dall\'ultimo rifornimento';

  @override
  String get addFillUpIsFullTankLabel => 'Pieno';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Serbatoio riempito al massimo — deseleziona se è stato un rifornimento parziale';

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'Sistema';

  @override
  String get themeCardSubtitleLight => 'Chiaro';

  @override
  String get themeCardSubtitleDark => 'Scuro';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Segui sistema';

  @override
  String get themeSettingsLightLabel => 'Chiaro';

  @override
  String get themeSettingsDarkLabel => 'Scuro';

  @override
  String get themeSettingsSystemDescription =>
      'Adatta l\'aspetto del dispositivo corrente.';

  @override
  String get themeSettingsLightDescription =>
      'Sfondi chiari — ottimi per l\'uso diurno.';

  @override
  String get themeSettingsDarkDescription =>
      'Sfondi scuri — meno affaticanti per gli occhi di notte e risparmio batteria sugli schermi OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'Il look verde caratteristico dell\'app — luminoso e facile da leggere, con sfondi delicatamente tinti di verde.';

  @override
  String get throttleRpmHistogramTitle => 'Come hai usato il motore';

  @override
  String get throttleRpmHistogramThrottleSection => 'Posizione acceleratore';

  @override
  String get throttleRpmHistogramRpmSection => 'Giri motore';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Rilascio (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Leggero (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Deciso (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Tutto gas (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Minimo (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Crociera (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Brillante (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Sostenuto (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Nessun campione acceleratore o RPM in questo percorso.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Percorsi';

  @override
  String get trajetsStartRecordingButton => 'Avvia registrazione';

  @override
  String get trajetsResumeRecordingButton => 'Riprendi registrazione';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Connessione all\'adattatore OBD2…';

  @override
  String get tripStartProgressReadingVehicleData => 'Lettura dati veicolo…';

  @override
  String get tripStartProgressStartingRecording => 'Avvio registrazione…';

  @override
  String get trajetsEmptyStateTitle => 'Nessun percorso ancora';

  @override
  String get trajetsEmptyStateBody =>
      'Tocca Avvia registrazione per iniziare a registrare le tue guidate.';

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
  String get trajetDetailSummaryTitle => 'Riepilogo';

  @override
  String get trajetDetailFieldDate => 'Data';

  @override
  String get trajetDetailFieldVehicle => 'Veicolo';

  @override
  String get trajetDetailFieldAdapter => 'Adattatore OBD2';

  @override
  String get trajetDetailFieldDistance => 'Distanza';

  @override
  String get trajetDetailFieldDuration => 'Durata';

  @override
  String get trajetDetailFieldAvgConsumption => 'Consumo medio';

  @override
  String get trajetDetailFieldFuelUsed => 'Carburante usato';

  @override
  String get trajetDetailFieldFuelCost => 'Costo carburante';

  @override
  String get trajetDetailFieldAvgSpeed => 'Velocità media';

  @override
  String get trajetDetailFieldMaxSpeed => 'Velocità massima';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Velocità (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Flusso carburante (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Carico motore (%)';

  @override
  String get trajetsRowColdStartChip => 'Avviamento a freddo';

  @override
  String get trajetsRowColdStartTooltip =>
      'Il motore non ha raggiunto la temperatura di esercizio durante questo percorso — il consumo di carburante era più alto del solito.';

  @override
  String get trajetDetailChartEmpty => 'Nessun campione registrato';

  @override
  String get trajetDetailShareAction => 'Condividi';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — percorso del $date';
  }

  @override
  String get trajetDetailShareError =>
      'Impossibile generare l\'immagine da condividere';

  @override
  String get trajetDetailDeleteAction => 'Elimina';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Eliminare questo percorso?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Questo percorso verrà rimosso definitivamente dalla tua cronologia.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Annulla';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Elimina';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adattatore OBD2 connesso ma non restituisce dati. Prova un adattatore diverso o verifica il protocollo diagnostico del veicolo.';

  @override
  String get tripLengthCardTitle => 'Consumo per lunghezza percorso';

  @override
  String get tripLengthBucketShort => 'Corto (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Medio (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Lungo (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Servono più dati';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count percorsi',
      one: '1 percorso',
      zero: 'nessun percorso',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Percorso del viaggio';

  @override
  String get tripPathCardSubtitle => 'Percorso registrato via GPS';

  @override
  String get tripPathLegendTitle => 'Consumo';

  @override
  String get tripPathLegendEfficient => 'Efficiente (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Limite (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Dispendioso (≥ 10 L/100km)';

  @override
  String get tripRecordingPinTooltip =>
      'Fissare mantiene lo schermo acceso — consuma più batteria';

  @override
  String get tripRecordingPinSemanticOn => 'Sblocca il modulo di registrazione';

  @override
  String get tripRecordingPinSemanticOff => 'Blocca il modulo di registrazione';

  @override
  String get tripRecordingPinHelpTooltip => 'Cosa fa il blocco?';

  @override
  String get tripRecordingPinHelpTitle => 'Informazioni sul blocco';

  @override
  String get tripRecordingPinHelpBody =>
      'Il blocco mantiene lo schermo acceso e nasconde le barre di sistema affinché il modulo rimanga leggibile sul supporto del cruscotto. Tocca di nuovo per sbloccare. Si sblocca automaticamente quando il percorso si ferma.';

  @override
  String get tripRecordingResumeHintMessage =>
      'La registrazione continua in background. Tocca il banner rosso in cima a qualsiasi schermata per tornare.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Apri il percorso attivo dalla scheda Conso';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Blocca lo schermo per mantenere il GPS attivo durante il percorso — Android potrebbe limitare il GPS durante la sospensione.';

  @override
  String get unifiedFilterFuel => 'Carburante';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Entrambi';

  @override
  String get unifiedNoResultsForFilter => 'Nessun risultato per questo filtro';

  @override
  String get searchFailedSnackbar => 'Ricerca non riuscita — riprova';

  @override
  String get vinLabel => 'VIN (opzionale)';

  @override
  String get vinDecodeTooltip => 'Decodifica VIN';

  @override
  String get vinConfirmAction => 'Sì, compila automaticamente';

  @override
  String get vinModifyAction => 'Modifica manualmente';

  @override
  String get veResetAction => 'Reimposta efficienza volumetrica';

  @override
  String get vehicleReadVinFromCarButton => 'Leggi VIN dall\'auto';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Leggi il VIN dall\'adattatore OBD2 abbinato';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN non disponibile (Mode 09 PID 02 non supportato sui veicoli precedenti al 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Lettura VIN non riuscita — inserisci manualmente';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Prima abbina un adattatore OBD2 per leggere il VIN automaticamente';

  @override
  String get pickerButtonLabel => 'Scegli dal catalogo';

  @override
  String get pickerSearchHint => 'Cerca marca o modello';

  @override
  String get pickerHelpText => 'Precompila da 50+ veicoli supportati';

  @override
  String get pickerEmptyResults => 'Nessuna corrispondenza';

  @override
  String get pickerCancel => 'Annulla';

  @override
  String get pickerLoading => 'Caricamento catalogo…';

  @override
  String get vinInfoTooltip => 'Cos\'è un VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Cos\'è un VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Il Vehicle Identification Number è un codice di 17 caratteri unico per la tua auto. È inciso sul telaio e stampato sul documento di immatricolazione.';

  @override
  String get vinInfoSectionWhyTitle => 'Perché lo chiediamo';

  @override
  String get vinInfoSectionWhyBody =>
      'La decodifica del VIN precompila automaticamente cilindrata, numero di cilindri, anno del modello, tipo di carburante principale e peso lordo — risparmiadoti di cercare manualmente le specifiche tecniche. Il calcolo del flusso carburante OBD2 usa questi valori per fornirti dati di consumo accurati.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacy';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Il tuo VIN è archiviato solo localmente nello spazio di archiviazione cifrato dell\'app — non viene mai caricato sui server di Sparkilo. Il database NHTSA vPIC viene interrogato con il VIN ma restituisce solo specifiche tecniche anonime; NHTSA non collega il VIN a nessun dato personale. Senza rete, una ricerca offline restituisce solo produttore e paese.';

  @override
  String get vinInfoSectionWhereTitle => 'Dove trovarlo';

  @override
  String get vinInfoSectionWhereBody =>
      'Guardalo attraverso il parabrezza nell\'angolo in basso a sinistra lato conducente, controlla l\'adesivo sul montante della porta lato conducente quando la porta è aperta, oppure leggilo dal documento di immatricolazione (libretto / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Capito';

  @override
  String get vinConfirmPrivacyNote =>
      'Abbiamo cercato il tuo VIN nel database veicoli gratuito di NHTSA — nulla inviato ai server di Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Decodifica VIN online';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Decodifica il VIN tramite il servizio pubblico gratuito di NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Quando abbini un adattatore, il VIN del tuo veicolo viene letto localmente per identificare l\'auto. Abilitando questa opzione, il VIN di 17 caratteri viene inviato al servizio vPIC gratuito di NHTSA per cercare dettagli aggiuntivi (modello, cilindrata, tipo carburante). Il VIN è l\'unico dato inviato — nessun\'altra informazione lascia il dispositivo.';

  @override
  String get vehicleDetectedFromVinBadge => '(rilevato)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Rilevato dal VIN: $summary. Applicare?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Applica';

  @override
  String waitTimeHint(int minutes) {
    return '~$minutes min di attesa';
  }

  @override
  String get waitTimeTrackStart => 'Tieni traccia della mia attesa';

  @override
  String get waitTimeTrackEnd => 'Me ne vado';

  @override
  String waitTimeElapsedShort(int minutes) {
    return '$minutes min finora';
  }

  @override
  String get widgetHelpSectionTitle => 'Widget schermata Home';

  @override
  String get widgetHelpIntro =>
      'Aggiungi il widget SparKilo alla tua schermata Home per vedere i prezzi di carburante e ricarica a colpo d\'occhio.';

  @override
  String get widgetHelpAdd =>
      'Aggiungilo dal selettore widget del tuo launcher — tieni premuto un\'area vuota della schermata Home, scegli Widget e trova SparKilo.';

  @override
  String get widgetHelpTap =>
      'Tocca una stazione nel widget per aprirla nell\'app. Tocca l\'icona di aggiornamento per aggiornare i prezzi.';

  @override
  String get widgetHelpConfigure =>
      'Su Android, tieni premuto il widget e scegli Riconfigura per cambiare il profilo, il colore e il contenuto.';

  @override
  String get widgetVariantDefault => 'Solo prezzo attuale';

  @override
  String get widgetVariantPredictive =>
      'Predittivo: miglior momento per rifornire';

  @override
  String get widgetPredictiveNowPrefix => 'adesso';
}
