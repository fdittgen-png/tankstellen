// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Prix Carburants';

  @override
  String get search => 'Recherche';

  @override
  String get favorites => 'Favoris';

  @override
  String get map => 'Carte';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get gpsLocation => 'Position GPS';

  @override
  String get zipCode => 'Code postal';

  @override
  String get zipCodeHint => 'ex. 75001';

  @override
  String get fuelType => 'Carburant';

  @override
  String get searchRadius => 'Rayon';

  @override
  String get searchNearby => 'Stations à proximité';

  @override
  String get searchButton => 'Rechercher';

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
  String get noResults => 'Aucune station trouvée.';

  @override
  String get startSearch => 'Recherchez pour trouver des stations.';

  @override
  String get open => 'Ouvert';

  @override
  String get closed => 'Fermé';

  @override
  String distance(String distance) {
    return 'à $distance';
  }

  @override
  String get price => 'Prix';

  @override
  String get prices => 'Prix';

  @override
  String get address => 'Adresse';

  @override
  String get openingHours => 'Horaires';

  @override
  String get open24h => 'Ouvert 24h/24';

  @override
  String get navigate => 'Naviguer';

  @override
  String get retry => 'Réessayer';

  @override
  String get apiKeySetup => 'Clé API';

  @override
  String get apiKeyDescription =>
      'Inscrivez-vous une fois pour obtenir une clé API gratuite.';

  @override
  String get apiKeyLabel => 'Clé API';

  @override
  String get register => 'Inscription';

  @override
  String get continueButton => 'Continuer';

  @override
  String get welcome => 'Prix Carburants';

  @override
  String get welcomeSubtitle =>
      'Trouvez le carburant le moins cher près de chez vous.';

  @override
  String get profileName => 'Nom du profil';

  @override
  String get preferredFuel => 'Carburant préféré';

  @override
  String get defaultRadius => 'Rayon par défaut';

  @override
  String get landingScreen => 'Écran d\'accueil';

  @override
  String get homeZip => 'Code postal domicile';

  @override
  String get newProfile => 'Nouveau profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get countryChangeTitle => 'Changer de pays ?';

  @override
  String countryChangeBody(String country) {
    return 'Passer en $country va changer :';
  }

  @override
  String get countryChangeCurrency => 'Devise';

  @override
  String get countryChangeDistance => 'Distance';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Format du prix';

  @override
  String get countryChangeNote =>
      'Les favoris et les pleins existants ne seront pas recalculés ; seules les nouvelles entrées utiliseront les nouvelles unités.';

  @override
  String get countryChangeConfirm => 'Changer';

  @override
  String get delete => 'Supprimer';

  @override
  String get activate => 'Activer';

  @override
  String get configured => 'Configuré';

  @override
  String get notConfigured => 'Non configuré';

  @override
  String get about => 'À propos';

  @override
  String get openSource => 'Open Source (Licence MIT)';

  @override
  String get sourceCode => 'Code source sur GitHub';

  @override
  String get noFavorites => 'Pas encore de favoris';

  @override
  String get noFavoritesHint =>
      'Appuyez sur l\'étoile d\'une station pour l\'ajouter aux favoris.';

  @override
  String get language => 'Langue';

  @override
  String get country => 'Pays';

  @override
  String get demoMode => 'Mode démo — données d\'exemple affichées.';

  @override
  String get setupLiveData => 'Configurer pour les données en direct';

  @override
  String get freeNoKey => 'Gratuit — aucune clé requise';

  @override
  String get apiKeyRequired => 'Clé API requise';

  @override
  String get skipWithoutKey => 'Continuer sans clé';

  @override
  String get dataTransparency => 'Transparence des données';

  @override
  String get storageAndCache => 'Stockage et cache';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get clearAllData => 'Supprimer toutes les données';

  @override
  String get errorLog => 'Journal d\'erreurs';

  @override
  String stationsFound(int count) {
    return '$count stations trouvées';
  }

  @override
  String get whatIsShared => 'Quelles données sont partagées — et avec qui ?';

  @override
  String get gpsCoordinates => 'Coordonnées GPS';

  @override
  String get gpsReason =>
      'Envoyées à chaque recherche pour trouver les stations proches.';

  @override
  String get postalCodeData => 'Code postal';

  @override
  String get postalReason =>
      'Converti en coordonnées via le service de géocodage.';

  @override
  String get mapViewport => 'Zone de carte affichée';

  @override
  String get mapReason =>
      'Les tuiles de carte sont chargées depuis le serveur. Aucune donnée personnelle n\'est transmise.';

  @override
  String get apiKeyData => 'Clé API';

  @override
  String get apiKeyReason =>
      'Votre clé personnelle est envoyée à chaque requête API. Elle est liée à votre e-mail.';

  @override
  String get notShared => 'NON partagé :';

  @override
  String get searchHistory => 'Historique de recherche';

  @override
  String get favoritesData => 'Favoris';

  @override
  String get profileNames => 'Noms de profil';

  @override
  String get homeZipData => 'Code postal domicile';

  @override
  String get usageData => 'Données d\'utilisation';

  @override
  String get privacyBanner =>
      'Cette application n\'a pas de serveur. Toutes les données restent sur votre appareil. Pas d\'analyse, pas de suivi, pas de publicité.';

  @override
  String get storageUsage => 'Utilisation du stockage sur cet appareil';

  @override
  String get settingsLabel => 'Paramètres';

  @override
  String get profilesStored => 'profils enregistrés';

  @override
  String get stationsMarked => 'stations marquées';

  @override
  String get cachedResponses => 'réponses en cache';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Gestion du cache';

  @override
  String get cacheDescription =>
      'Le cache stocke les réponses API pour un chargement plus rapide et l\'accès hors ligne.';

  @override
  String get stationSearch => 'Recherche de stations';

  @override
  String get stationDetails => 'Détails station';

  @override
  String get priceQuery => 'Requête prix';

  @override
  String get zipGeocoding => 'Géocodage code postal';

  @override
  String minutes(int n) {
    return '$n minutes';
  }

  @override
  String hours(int n) {
    return '$n heures';
  }

  @override
  String get clearCacheTitle => 'Vider le cache ?';

  @override
  String get clearCacheBody =>
      'Les résultats de recherche et prix en cache seront supprimés. Profils, favoris et paramètres sont conservés.';

  @override
  String get clearCacheButton => 'Vider le cache';

  @override
  String get deleteAllTitle => 'Supprimer toutes les données ?';

  @override
  String get deleteAllBody =>
      'Cela supprime définitivement tous les profils, favoris, clé API, paramètres et cache. L\'app sera réinitialisée.';

  @override
  String get deleteAllButton => 'Tout supprimer';

  @override
  String get entries => 'entrées';

  @override
  String get cacheEmpty => 'Le cache est vide';

  @override
  String get noStorage => 'Aucun stockage utilisé';

  @override
  String get apiKeyNote =>
      'Inscription gratuite. Données des agences gouvernementales de transparence des prix.';

  @override
  String get apiKeyFormatError => 'Format invalide — UUID attendu (8-4-4-4-12)';

  @override
  String get supportProject => 'Soutenir ce projet';

  @override
  String get supportDescription =>
      'Cette application est gratuite, open source et sans publicité. Si vous la trouvez utile, pensez à soutenir le développeur.';

  @override
  String get reportBug => 'Signaler un bug / Suggérer une amélioration';

  @override
  String get reportThisIssue => 'Signaler ce problème';

  @override
  String get reportConsentTitle => 'Signaler sur GitHub ?';

  @override
  String get reportConsentBody =>
      'Ceci ouvrira une issue publique sur GitHub avec les détails de l\'erreur ci-dessous. Aucune coordonnée GPS, clé API ou donnée personnelle n\'est incluse.';

  @override
  String get reportConsentConfirm => 'Ouvrir GitHub';

  @override
  String get reportConsentCancel => 'Annuler';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Profil actif';

  @override
  String get configPreferredFuel => 'Carburant préféré';

  @override
  String get configCountry => 'Pays';

  @override
  String get configRouteSegment => 'Segment d\'itinéraire';

  @override
  String get configApiKeysSection => 'Clés API';

  @override
  String get configTankerkoenigKey => 'Clé API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Configurée';

  @override
  String get configApiKeyNotSet => 'Non définie (mode démo)';

  @override
  String get configApiKeyCommunity => 'Clé communautaire par défaut';

  @override
  String get searchLocationPlaceholder => 'Adresse, code postal ou ville';

  @override
  String get configEvKey => 'Clé API recharge VE';

  @override
  String get configEvKeyCustom => 'Clé personnalisée';

  @override
  String get configEvKeyShared => 'Partagée par défaut';

  @override
  String get configCloudSyncSection => 'Synchronisation';

  @override
  String get configTankSyncConnected => 'Connectée';

  @override
  String get configTankSyncDisabled => 'Désactivée';

  @override
  String get configAuthMode => 'Mode d\'authentification';

  @override
  String get configAuthEmail => 'E-mail (persistant)';

  @override
  String get configAuthAnonymous => 'Anonyme (appareil uniquement)';

  @override
  String get configDatabase => 'Base de données';

  @override
  String get configPrivacySummary => 'Résumé de confidentialité';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoris, alertes et stations ignorées sont synchronisés dans votre base de données privée\n• Position GPS et clés API ne quittent jamais votre appareil\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Toutes les données sont stockées localement sur cet appareil uniquement\n• Aucune donnée n\'est envoyée à un serveur\n• Clés API chiffrées dans le stockage sécurisé de l\'appareil';

  @override
  String get configAuthNoteEmail =>
      'Le compte e-mail permet l\'accès multi-appareils';

  @override
  String get configAuthNoteAnonymous =>
      'Compte anonyme — données liées à cet appareil';

  @override
  String get configNone => 'Aucun';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get fuels => 'Carburants';

  @override
  String get services => 'Services';

  @override
  String get zone => 'Zone';

  @override
  String get highway => 'Autoroute';

  @override
  String get localStation => 'Station de proximité';

  @override
  String get lastUpdate => 'Dernière mise à jour';

  @override
  String get automate24h => '24h/24 — Automate';

  @override
  String get refreshPrices => 'Actualiser les prix';

  @override
  String get station => 'Station';

  @override
  String get locationDenied =>
      'Autorisation de localisation refusée. Vous pouvez chercher par code postal.';

  @override
  String get demoModeBanner =>
      'Mode démo. Configurez la clé API dans les paramètres.';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'bon marché';

  @override
  String get expensive => 'cher';

  @override
  String stationsOnMap(int count) {
    return '$count stations';
  }

  @override
  String get loadingFavorites =>
      'Chargement des favoris...\nRecherchez d\'abord des stations pour enregistrer des données.';

  @override
  String get reportPrice => 'Signaler un prix';

  @override
  String get whatsWrong => 'Quel est le problème ?';

  @override
  String get correctPrice => 'Prix correct (ex. 1,459)';

  @override
  String get sendReport => 'Envoyer le signalement';

  @override
  String get reportSent => 'Signalement envoyé. Merci !';

  @override
  String get enterValidPrice => 'Veuillez entrer un prix valide';

  @override
  String get cacheCleared => 'Cache vidé.';

  @override
  String get yourPosition => 'Votre position';

  @override
  String get positionUnknown => 'Position inconnue';

  @override
  String get distancesFromCenter => 'Distances depuis le centre de recherche';

  @override
  String get autoUpdatePosition => 'Mise à jour automatique';

  @override
  String get autoUpdateDescription =>
      'Actualiser la position GPS avant chaque recherche';

  @override
  String get location => 'Localisation';

  @override
  String get switchProfileTitle => 'Pays changé';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Vous êtes maintenant en $country. Passer au profil \"$profile\" ?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Profil \"$profile\" activé ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Aucun profil pour ce pays';

  @override
  String noProfileForCountry(String country) {
    return 'Vous êtes en $country, mais aucun profil n\'est configuré. Créez-en un dans les Réglages.';
  }

  @override
  String get autoSwitchProfile => 'Changement automatique de profil';

  @override
  String get autoSwitchDescription =>
      'Changer de profil automatiquement en traversant une frontière';

  @override
  String get switchProfile => 'Changer';

  @override
  String get dismiss => 'Fermer';

  @override
  String get profileCountry => 'Pays';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get settingsStorageDetail => 'Clé API, profil actif';

  @override
  String get allFuels => 'Tous';

  @override
  String get priceAlerts => 'Alertes de prix';

  @override
  String get noPriceAlerts => 'Aucune alerte de prix';

  @override
  String get noPriceAlertsHint =>
      'Créez une alerte depuis la page détail d\'une station.';

  @override
  String alertDeleted(String name) {
    return 'Alerte \"$name\" supprimée';
  }

  @override
  String get createAlert => 'Créer une alerte de prix';

  @override
  String currentPrice(String price) {
    return 'Prix actuel : $price';
  }

  @override
  String get targetPrice => 'Prix cible (EUR)';

  @override
  String get enterPrice => 'Veuillez entrer un prix';

  @override
  String get invalidPrice => 'Prix invalide';

  @override
  String get priceTooHigh => 'Prix trop élevé';

  @override
  String get create => 'Créer';

  @override
  String get alertCreated => 'Alerte de prix créée';

  @override
  String get wrongE5Price => 'Prix Super E5 incorrect';

  @override
  String get wrongE10Price => 'Prix Super E10 incorrect';

  @override
  String get wrongDieselPrice => 'Prix Diesel incorrect';

  @override
  String get wrongStatusOpen => 'Affiché ouvert, mais fermé';

  @override
  String get wrongStatusClosed => 'Affiché fermé, mais ouvert';

  @override
  String get searchAlongRouteLabel => 'Le long du trajet';

  @override
  String get searchEvStations => 'Recherchez des bornes de recharge';

  @override
  String get allStations => 'Toutes les stations';

  @override
  String get bestStops => 'Meilleurs arrêts';

  @override
  String get openInMaps => 'Ouvrir dans Maps';

  @override
  String get noStationsAlongRoute => 'Aucune station trouvée le long du trajet';

  @override
  String get evOperational => 'En service';

  @override
  String get evStatusUnknown => 'Statut inconnu';

  @override
  String evConnectors(int count) {
    return 'Connecteurs ($count points)';
  }

  @override
  String get evNoConnectors => 'Aucun détail de connecteur disponible';

  @override
  String get evUsageCost => 'Coût d\'utilisation';

  @override
  String get evPricingUnavailable =>
      'Tarification non disponible auprès du fournisseur';

  @override
  String get evLastUpdated => 'Dernière mise à jour';

  @override
  String get evUnknown => 'Inconnu';

  @override
  String get evDataAttribution =>
      'Données de OpenChargeMap (source communautaire)';

  @override
  String get evStatusDisclaimer =>
      'Le statut peut ne pas refléter la disponibilité en temps réel. Appuyez sur actualiser pour obtenir les dernières données.';

  @override
  String get evNavigateToStation => 'Naviguer vers la station';

  @override
  String get evRefreshStatus => 'Actualiser le statut';

  @override
  String get evStatusUpdated => 'Statut mis à jour';

  @override
  String get evStationNotFound =>
      'Impossible d\'actualiser — station introuvable à proximité';

  @override
  String get addedToFavorites => 'Ajouté aux favoris';

  @override
  String get removedFromFavorites => 'Retiré des favoris';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String get currentLocation => 'Position actuelle';

  @override
  String get gpsError => 'Erreur GPS';

  @override
  String get couldNotResolve =>
      'Impossible de résoudre le départ ou la destination';

  @override
  String get start => 'Départ';

  @override
  String get destination => 'Destination';

  @override
  String get cityAddressOrGps => 'Ville, adresse ou GPS';

  @override
  String get cityOrAddress => 'Ville ou adresse';

  @override
  String get useGps => 'Utiliser le GPS';

  @override
  String get stop => 'Étape';

  @override
  String stopN(int n) {
    return 'Étape $n';
  }

  @override
  String get addStop => 'Ajouter une étape';

  @override
  String get searchAlongRoute => 'Rechercher le long du trajet';

  @override
  String get cheapest => 'Le moins cher';

  @override
  String nStations(int count) {
    return '$count stations';
  }

  @override
  String nBest(int count) {
    return '$count meilleures';
  }

  @override
  String get fuelPricesTankerkoenig => 'Prix carburants (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Requis pour la recherche de prix de carburant en Allemagne';

  @override
  String get evChargingOpenChargeMap => 'Recharge EV (OpenChargeMap)';

  @override
  String get customKey => 'Clé personnalisée';

  @override
  String get appDefaultKey => 'Clé par défaut de l\'app';

  @override
  String get optionalOverrideKey =>
      'Optionnel : remplacer la clé intégrée par la vôtre';

  @override
  String get requiredForEvSearch =>
      'Requis pour la recherche de bornes de recharge';

  @override
  String get edit => 'Modifier';

  @override
  String get fuelPricesApiKey => 'Clé API prix carburants';

  @override
  String get tankerkoenigApiKey => 'Clé API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Clé API recharge EV';

  @override
  String get openChargeMapApiKey => 'Clé API OpenChargeMap';

  @override
  String get routeSegment => 'Segment de trajet';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Afficher la station la moins chère tous les $km km le long du trajet';
  }

  @override
  String get avoidHighways => 'Éviter les autoroutes';

  @override
  String get avoidHighwaysDesc =>
      'Le calcul d\'itinéraire évite les routes à péage et les autoroutes';

  @override
  String get showFuelStations => 'Afficher les stations-service';

  @override
  String get showFuelStationsDesc =>
      'Inclure les stations essence, diesel, GPL, GNC';

  @override
  String get showEvStations => 'Afficher les bornes de recharge';

  @override
  String get showEvStationsDesc =>
      'Inclure les bornes de recharge électrique dans les résultats';

  @override
  String get noStationsAlongThisRoute =>
      'Aucune station trouvée le long de ce trajet.';

  @override
  String get fuelCostCalculator => 'Calculateur de coût carburant';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get consumptionL100km => 'Consommation (L/100km)';

  @override
  String get fuelPriceEurL => 'Prix carburant (EUR/L)';

  @override
  String get tripCost => 'Coût du trajet';

  @override
  String get fuelNeeded => 'Carburant nécessaire';

  @override
  String get totalCost => 'Coût total';

  @override
  String get enterCalcValues =>
      'Saisissez la distance, la consommation et le prix pour calculer le coût du trajet';

  @override
  String get priceHistory => 'Historique des prix';

  @override
  String get noPriceHistory => 'Pas encore d\'historique de prix';

  @override
  String get noHourlyData => 'Pas de données horaires';

  @override
  String get noStatistics => 'Aucune statistique disponible';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Moy';

  @override
  String get showAllFuelTypes => 'Afficher tous les types de carburant';

  @override
  String get connected => 'Connecté';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get connectTankSync => 'Connecter TankSync';

  @override
  String get disconnectTankSync => 'Déconnecter TankSync';

  @override
  String get viewMyData => 'Voir mes données';

  @override
  String get optionalCloudSync =>
      'Synchronisation cloud optionnelle pour les alertes, favoris et notifications push';

  @override
  String get tapToUpdateGps => 'Appuyez pour mettre à jour la position GPS';

  @override
  String get gpsAutoUpdateHint =>
      'La position GPS est acquise automatiquement lors de la recherche. Vous pouvez aussi la mettre à jour manuellement ici.';

  @override
  String get clearGpsConfirm =>
      'Effacer la position GPS enregistrée ? Vous pourrez la mettre à jour à tout moment.';

  @override
  String get pageNotFound => 'Page introuvable';

  @override
  String get deleteAllServerData => 'Supprimer toutes les données serveur';

  @override
  String get deleteServerDataConfirm =>
      'Supprimer toutes les données serveur ?';

  @override
  String get deleteEverything => 'Tout supprimer';

  @override
  String get allDataDeleted => 'Toutes les données serveur supprimées';

  @override
  String get disconnectConfirm => 'Déconnecter TankSync ?';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get myServerData => 'Mes données serveur';

  @override
  String get anonymousUuid => 'UUID anonyme';

  @override
  String get server => 'Serveur';

  @override
  String get syncedData => 'Données synchronisées';

  @override
  String get pushTokens => 'Jetons push';

  @override
  String get priceReports => 'Signalements de prix';

  @override
  String get totalItems => 'Total éléments';

  @override
  String get estimatedSize => 'Taille estimée';

  @override
  String get viewRawJson => 'Voir les données brutes en JSON';

  @override
  String get exportJson => 'Exporter en JSON (presse-papiers)';

  @override
  String get jsonCopied => 'JSON copié dans le presse-papiers';

  @override
  String get rawDataJson => 'Données brutes (JSON)';

  @override
  String get close => 'Fermer';

  @override
  String get account => 'Compte';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get upgradeToEmail => 'Créer un compte e-mail';

  @override
  String get savedRoutes => 'Itinéraires enregistrés';

  @override
  String get noSavedRoutes => 'Aucun itinéraire enregistré';

  @override
  String get noSavedRoutesHint =>
      'Recherchez le long d\'un itinéraire et enregistrez-le pour un accès rapide.';

  @override
  String get saveRoute => 'Enregistrer l\'itinéraire';

  @override
  String get routeName => 'Nom de l\'itinéraire';

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
  String get deleteProfileTitle => 'Supprimer le profil ?';

  @override
  String get deleteProfileBody =>
      'Ce profil et ses paramètres seront définitivement supprimés. Cette action est irréversible.';

  @override
  String get deleteProfileConfirm => 'Supprimer le profil';

  @override
  String get errorNetwork => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get errorServer => 'Erreur serveur. Réessayez plus tard.';

  @override
  String get errorTimeout => 'Délai de connexion dépassé. Réessayez.';

  @override
  String get errorNoConnection => 'Pas de connexion internet.';

  @override
  String get errorApiKey => 'Clé API invalide. Vérifiez vos paramètres.';

  @override
  String get errorLocation => 'Impossible de déterminer votre position.';

  @override
  String get errorNoApiKey =>
      'Aucune clé API configurée. Allez dans Paramètres.';

  @override
  String get errorAllServicesFailed =>
      'Impossible de charger les données. Vérifiez votre connexion.';

  @override
  String get errorCache =>
      'Erreur de données locales. Essayez de vider le cache.';

  @override
  String get errorCancelled => 'Requête annulée.';

  @override
  String get errorUnknown => 'Une erreur inattendue est survenue.';

  @override
  String get onboardingWelcomeHint =>
      'Configurez l\'application en quelques étapes rapides.';

  @override
  String get onboardingApiKeyDescription =>
      'Créez une clé API gratuite, ou passez pour explorer l\'application avec des données de démonstration.';

  @override
  String get onboardingComplete => 'Tout est prêt !';

  @override
  String get onboardingCompleteHint =>
      'Vous pouvez modifier ces paramètres à tout moment dans votre profil.';

  @override
  String get onboardingBack => 'Retour';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingFinish => 'Commencer';

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
  String get freshnessAgo => 'il y a';

  @override
  String get freshnessStale => 'Périmé';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Fraîcheur des données : $age';
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
  String get swipeTutorialDismiss => 'Compris';

  @override
  String get alertStatsActive => 'Actives';

  @override
  String get alertStatsToday => 'Aujourd\'hui';

  @override
  String get alertStatsThisWeek => 'Cette semaine';

  @override
  String get privacyDashboardTitle => 'Tableau de bord Confidentialité';

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
  String get privacyPriceHistory => 'Stations avec historique des prix';

  @override
  String get privacyProfiles => 'Profils de recherche';

  @override
  String get privacyItineraries => 'Itinéraires enregistrés';

  @override
  String get privacyCacheEntries => 'Entrées en cache';

  @override
  String get privacyApiKey => 'Clé API enregistrée';

  @override
  String get privacyEvApiKey => 'Clé API VE enregistrée';

  @override
  String get privacyEstimatedSize => 'Stockage estimé';

  @override
  String get privacySyncedData => 'Synchronisation cloud (TankSync)';

  @override
  String get privacySyncDisabled =>
      'La synchronisation cloud est désactivée. Toutes les données restent uniquement sur cet appareil.';

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
  String get privacyExportButton => 'Exporter toutes les données en JSON';

  @override
  String get privacyExportSuccess => 'Data exported to clipboard';

  @override
  String get privacyExportCsvButton => 'Exporter toutes les données en CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV data exported to clipboard';

  @override
  String get privacyDeleteButton => 'Tout supprimer';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Copier le journal d\'erreurs ($count)';
  }

  @override
  String get privacyDeleteTitle => 'Delete all data?';

  @override
  String get privacyDeleteBody =>
      'This will permanently delete:\n\n- All favorites and station data\n- All search profiles\n- All price alerts\n- All price history\n- All cached data\n- Your API key\n- All app settings\n\nThe app will reset to its initial state. This action cannot be undone.';

  @override
  String get privacyDeleteConfirm => 'Delete everything';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get amenities => 'Équipements';

  @override
  String get amenityShop => 'Boutique';

  @override
  String get amenityCarWash => 'Lavage';

  @override
  String get amenityAirPump => 'Air';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Resto';

  @override
  String get amenityAtm => 'DAB';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'Recharge';

  @override
  String get paymentMethods => 'Moyens de paiement';

  @override
  String get paymentMethodCash => 'Espèces';

  @override
  String get paymentMethodCard => 'Carte';

  @override
  String get paymentMethodContactless => 'Sans contact';

  @override
  String get paymentMethodFuelCard => 'Carte carburant';

  @override
  String get paymentMethodApp => 'Appli';

  @override
  String payWithApp(String app) {
    return 'Payer avec $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Comparé à la moyenne glissante de vos 3 derniers pleins ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consommation $value L/100 km, $delta par rapport à votre moyenne';
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
  String get nearestStations => 'Stations les plus proches';

  @override
  String get nearestStationsHint =>
      'Trouver les stations les plus proches avec votre position actuelle';

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
  String get addFillUp => 'Ajouter un plein';

  @override
  String get noFillUpsTitle => 'No fill-ups yet';

  @override
  String get noFillUpsSubtitle =>
      'Log your first fill-up to start tracking consumption.';

  @override
  String get fillUpDate => 'Date';

  @override
  String get liters => 'Litres';

  @override
  String get odometerKm => 'Compteur (km)';

  @override
  String get notesOptional => 'Notes (facultatif)';

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
  String get vehiclesWizardTitle => 'Mes véhicules (facultatif)';

  @override
  String get vehiclesWizardSubtitle =>
      'Ajoutez votre voiture pour pré-remplir le journal de consommation et activer les filtres de connecteurs EV. Vous pouvez ignorer cette étape et ajouter des véhicules plus tard.';

  @override
  String get vehiclesWizardNoneYet =>
      'Aucun véhicule configuré pour le moment.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count véhicules',
      one: '1 véhicule',
    );
    return 'Vous avez $_temp0 :';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Ignorer pour terminer la configuration — vous pouvez ajouter des véhicules à tout moment depuis les Paramètres.';

  @override
  String get fillUpVehicleLabel => 'Véhicule';

  @override
  String get fillUpVehicleNone => 'Aucun véhicule';

  @override
  String get fillUpVehicleRequired => 'Véhicule requis';

  @override
  String get reportScanError => 'Signaler une erreur de scan';

  @override
  String get pickStationTitle => 'Choisir une station';

  @override
  String get pickStationHelper =>
      'Démarrer le plein depuis une station connue — les prix, la marque et le carburant sont pré-remplis.';

  @override
  String get pickStationEmpty =>
      'Aucune station favorite — ajoutez-en depuis Recherche ou Favoris, ou passez cette étape.';

  @override
  String get pickStationSkip => 'Passer — saisir sans station';

  @override
  String get scanPump => 'Scanner la pompe';

  @override
  String get scanPayment => 'Scanner le QR de paiement';

  @override
  String get qrPaymentBeneficiary => 'Bénéficiaire';

  @override
  String get qrPaymentAmount => 'Montant';

  @override
  String get qrPaymentEpcTitle => 'Virement SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Aucun champ décodé';

  @override
  String get qrPaymentOpenInBank => 'Ouvrir dans la banque';

  @override
  String get qrPaymentLaunchFailed =>
      'Aucune application ne peut ouvrir ce code';

  @override
  String get qrPaymentUnknownTitle => 'Code non reconnu';

  @override
  String get qrPaymentCopyRaw => 'Copier le texte brut';

  @override
  String get qrPaymentCopiedRaw => 'Copié dans le presse-papiers';

  @override
  String get qrPaymentReport => 'Signaler ce scan';

  @override
  String get qrPaymentEpcCopied =>
      'Coordonnées copiées — collez dans votre app bancaire';

  @override
  String get qrScannerGuidance => 'Pointez la caméra sur un QR code';

  @override
  String get qrScannerPermissionDenied =>
      'L\'accès à la caméra est nécessaire pour scanner les QR codes.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'L\'accès à la caméra a été refusé. Ouvrez les réglages pour l\'autoriser.';

  @override
  String get qrScannerRetryPermission => 'Réessayer';

  @override
  String get qrScannerOpenSettings => 'Ouvrir les réglages';

  @override
  String get qrScannerTimeout =>
      'Aucun QR code détecté. Rapprochez-vous ou réessayez.';

  @override
  String get qrScannerRetry => 'Réessayer';

  @override
  String get torchOn => 'Allumer le flash';

  @override
  String get torchOff => 'Éteindre le flash';

  @override
  String get obdNoAdapter => 'Aucun adaptateur OBD2 à portée';

  @override
  String get obdOdometerUnavailable => 'Impossible de lire le compteur';

  @override
  String get obdPermissionDenied =>
      'Accorder la permission Bluetooth dans les paramètres';

  @override
  String get obdAdapterUnresponsive =>
      'Pas de réponse — mettez le contact et réessayez';

  @override
  String get obdPickerTitle => 'Choisir un adaptateur OBD2';

  @override
  String get obdPickerScanning => 'Recherche d\'adaptateurs…';

  @override
  String get obdPickerConnecting => 'Connexion…';

  @override
  String get themeSettingTitle => 'Thème';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get themeModeSystem => 'Suivre le système';

  @override
  String get tripRecordingTitle => 'Enregistrement du trajet';

  @override
  String get tripSummaryTitle => 'Résumé du trajet';

  @override
  String get tripMetricDistance => 'Distance';

  @override
  String get tripMetricSpeed => 'Vitesse';

  @override
  String get tripMetricFuelUsed => 'Carburant utilisé';

  @override
  String get tripMetricAvgConsumption => 'Moyenne';

  @override
  String get tripMetricElapsed => 'Durée';

  @override
  String get tripMetricOdometer => 'Compteur';

  @override
  String get tripStop => 'Arrêter l\'enregistrement';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Reprendre';

  @override
  String get tripBannerRecording => 'Enregistrement en cours';

  @override
  String get tripBannerPaused => 'Trajet en pause — toucher pour reprendre';

  @override
  String get navConsumption => 'Conso';

  @override
  String get vehicleBaselineSectionTitle => 'Calibrage de la baseline';

  @override
  String get vehicleBaselineEmpty =>
      'Aucun échantillon pour l\'instant — lancez un trajet OBD2 pour commencer à apprendre le profil de consommation de ce véhicule.';

  @override
  String get vehicleBaselineProgress =>
      'Appris à partir d\'échantillons issus de différentes situations de conduite.';

  @override
  String get vehicleBaselineReset => 'Réinitialiser la baseline';

  @override
  String get vehicleBaselineResetConfirmTitle => 'Réinitialiser la baseline ?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Ceci efface tous les échantillons appris pour ce véhicule. Les valeurs par défaut au démarrage à froid seront utilisées jusqu\'à ce que de nouveaux trajets reconstruisent le profil.';

  @override
  String get vehicleAdapterSectionTitle => 'Adaptateur OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Aucun adaptateur couplé. Couplez-en un pour que l\'application se reconnecte automatiquement la prochaine fois.';

  @override
  String get vehicleAdapterUnnamed => 'Adaptateur inconnu';

  @override
  String get vehicleAdapterPair => 'Coupler un adaptateur';

  @override
  String get vehicleAdapterForget => 'Oublier l\'adaptateur';

  @override
  String get achievementsTitle => 'Succès';

  @override
  String get achievementFirstTrip => 'Premier trajet';

  @override
  String get achievementFirstTripDesc =>
      'Enregistrez votre premier trajet OBD2.';

  @override
  String get achievementFirstFillUp => 'Premier plein';

  @override
  String get achievementFirstFillUpDesc => 'Enregistrez votre premier plein.';

  @override
  String get achievementTenTrips => '10 trajets';

  @override
  String get achievementTenTripsDesc => 'Enregistrez 10 trajets OBD2.';

  @override
  String get achievementZeroHarsh => 'Conduite souple';

  @override
  String get achievementZeroHarshDesc =>
      'Terminez un trajet d\'au moins 10 km sans freinage ni accélération brusques.';

  @override
  String get achievementEcoWeek => 'Semaine éco';

  @override
  String get achievementEcoWeekDesc =>
      'Conduisez 7 jours d\'affilée avec au moins un trajet souple par jour.';

  @override
  String get achievementPriceWin => 'Bon plan prix';

  @override
  String get achievementPriceWinDesc =>
      'Enregistrez un plein qui bat la moyenne sur 30 jours de la station d\'au moins 5 %.';

  @override
  String get syncBaselinesToggleTitle =>
      'Partager les profils de véhicules appris';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Téléverser les baselines de consommation par véhicule pour qu\'un second appareil puisse les réutiliser.';

  @override
  String get obd2StatusConnected => 'Adaptateur OBD2 : connecté';

  @override
  String get obd2StatusAttempting => 'Adaptateur OBD2 : connexion en cours';

  @override
  String get obd2StatusUnreachable => 'Adaptateur OBD2 : injoignable';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptateur OBD2 : autorisation Bluetooth requise';

  @override
  String get obd2StatusConnectedBody => 'Prêt à enregistrer un trajet.';

  @override
  String get obd2StatusAttemptingBody => 'Connexion en cours en arrière-plan…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adaptateur hors de portée ou déjà utilisé par une autre application.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Autorisez le Bluetooth dans les réglages système pour reconnecter automatiquement.';

  @override
  String get obd2StatusNoAdapter => 'Aucun adaptateur couplé';

  @override
  String get obd2StatusForget => 'Oublier l\'adaptateur';

  @override
  String get tripHistoryTitle => 'Historique des trajets';

  @override
  String get tripHistoryEmptyTitle => 'Aucun trajet';

  @override
  String get tripHistoryEmptySubtitle =>
      'Branchez un adaptateur OBD2 et enregistrez un trajet pour commencer à constituer votre historique.';

  @override
  String get tripHistoryUnknownDate => 'Date inconnue';

  @override
  String get situationIdle => 'Ralenti';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urbain';

  @override
  String get situationHighway => 'Autoroute';

  @override
  String get situationDecel => 'Décélération';

  @override
  String get situationClimbing => 'Côte / chargé';

  @override
  String get situationHardAccel => 'Accél. forte';

  @override
  String get situationFuelCut => 'Coupure — roue libre';

  @override
  String get tripSaveAsFillUp => 'Enregistrer comme plein';

  @override
  String get tripDiscard => 'Abandonner';

  @override
  String obdOdometerRead(int km) {
    return 'Compteur lu : $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Non défini';

  @override
  String get wizardVehicleTapToEdit => 'Toucher pour modifier';

  @override
  String get wizardVehicleDefaultBadge => 'Par défaut';

  @override
  String get profileDefaultVehicleLabel => 'Véhicule par défaut (facultatif)';

  @override
  String get profileDefaultVehicleNone => 'Aucun par défaut';

  @override
  String get profileFuelFromVehicleHint =>
      'Le carburant est dérivé de votre véhicule par défaut. Supprimez le véhicule pour choisir un carburant directement.';

  @override
  String get consumptionNoVehicleTitle => 'Ajoutez d\'abord un véhicule';

  @override
  String get consumptionNoVehicleBody =>
      'Les pleins sont attribués à un véhicule. Ajoutez votre voiture pour commencer à suivre la consommation.';

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
  String get openOnlyFilter => 'Ouvertes uniquement';

  @override
  String get saveAsDefaults => 'Enregistrer comme valeurs par défaut';

  @override
  String get criteriaSavedToProfile => 'Enregistré comme valeurs par défaut';

  @override
  String get profileNotFound => 'Aucun profil actif';

  @override
  String get updatingFavorites => 'Mise à jour de vos favoris…';

  @override
  String get fetchingLatestPrices => 'Récupération des derniers prix';

  @override
  String get noDataAvailable => 'Pas de données';

  @override
  String get configAndPrivacy => 'Configuration & Confidentialité';

  @override
  String get searchToSeeMap => 'Recherchez pour voir les stations sur la carte';

  @override
  String get evPowerAny => 'Tous';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Localisation';

  @override
  String get tooltipBack => 'Retour';

  @override
  String get tooltipClose => 'Fermer';

  @override
  String get tooltipClearSearch => 'Effacer la recherche';

  @override
  String get tooltipUseGps => 'Utiliser la position GPS';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get evConnectorsLabel => 'Available connectors';

  @override
  String get evConnectorsNone => 'No connector information';

  @override
  String get switchToEmail => 'Passer à l\'e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Conserver les données, se connecter depuis d\'autres appareils';

  @override
  String get switchToAnonymousAction => 'Passer en anonyme';

  @override
  String get switchToAnonymousSubtitle =>
      'Conserver les données locales, nouvelle session anonyme';

  @override
  String get linkDevice => 'Lier un appareil';

  @override
  String get shareDatabase => 'Partager la base de données';

  @override
  String get disconnectAction => 'Déconnecter';

  @override
  String get disconnectSubtitle =>
      'Arrêter la synchronisation (données locales conservées)';

  @override
  String get deleteAccountAction => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle =>
      'Supprimer définitivement toutes les données serveur';

  @override
  String get localOnly => 'Local uniquement';

  @override
  String get localOnlySubtitle =>
      'Optionnel : synchroniser favoris, alertes et notes entre appareils';

  @override
  String get setupCloudSync => 'Configurer la synchronisation cloud';

  @override
  String get disconnectTitle => 'Déconnecter TankSync ?';

  @override
  String get disconnectBody =>
      'La synchronisation cloud sera désactivée. Vos données locales (favoris, alertes, historique) sont conservées sur cet appareil. Les données serveur ne sont pas supprimées.';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountBody =>
      'Toutes vos données seront définitivement supprimées du serveur (favoris, alertes, notes, itinéraires). Les données locales sur cet appareil sont conservées.\n\nCette action est irréversible.';

  @override
  String get switchToAnonymousTitle => 'Passer en anonyme ?';

  @override
  String get switchToAnonymousBody =>
      'Vous serez déconnecté de votre compte e-mail et continuerez avec une nouvelle session anonyme.\n\nVos données locales (favoris, alertes) restent sur cet appareil et seront synchronisées avec le nouveau compte anonyme.';

  @override
  String get switchAction => 'Changer';

  @override
  String get helpBannerCriteria =>
      'Vos valeurs par défaut sont pré-remplies. Ajustez les critères ci-dessous pour affiner votre recherche.';

  @override
  String get helpBannerAlerts =>
      'Définissez un seuil de prix pour une station. Vous serez notifié quand les prix passent en dessous. Vérification toutes les 30 minutes.';

  @override
  String get helpBannerConsumption =>
      'Enregistrez chaque plein pour suivre votre consommation réelle et votre empreinte CO₂. Glissez vers la gauche pour supprimer une entrée.';

  @override
  String get helpBannerVehicles =>
      'Ajoutez vos véhicules pour que les pleins et préférences carburant soient bien pré-réglés. Le premier véhicule devient le véhicule par défaut.';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get onboardingPreferencesTitle => 'Vos préférences';

  @override
  String get onboardingZipHelper =>
      'Utilisé quand le GPS n\'est pas disponible';

  @override
  String get onboardingRadiusHelper => 'Rayon plus grand = plus de résultats';

  @override
  String get onboardingPrivacy =>
      'Ces paramètres sont stockés uniquement sur votre appareil et ne sont jamais partagés.';

  @override
  String get onboardingLandingTitle => 'Écran d\'accueil';

  @override
  String get onboardingLandingHint =>
      'Choisissez l\'écran qui s\'ouvre au lancement de l\'application.';

  @override
  String get scanReceipt => 'Scanner le reçu';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Carburant';

  @override
  String get stationTypeEv => 'Recharge';

  @override
  String get brandFilterHighway => 'Autoroute';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Privé';

  @override
  String get ratingModeShared => 'Partagé';

  @override
  String get ratingDescLocal =>
      'Notes enregistrées uniquement sur cet appareil';

  @override
  String get ratingDescPrivate =>
      'Synchronisé avec votre base de données (non visible par les autres)';

  @override
  String get ratingDescShared =>
      'Visible par tous les utilisateurs de votre base de données';

  @override
  String get errorNoEvApiKey =>
      'Clé API OpenChargeMap non configurée. Ajoutez-en une dans Paramètres pour rechercher des bornes de recharge.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'The data provider ($host) is serving an expired or invalid TLS certificate. The app cannot load data from this source until the provider fixes it. Please contact $host.';
  }

  @override
  String get offlineLabel => 'Hors ligne';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed indisponible. Utilisation de $current.';
  }

  @override
  String get errorTitleApiKey => 'Clé API requise';

  @override
  String get errorTitleLocation => 'Position indisponible';

  @override
  String get errorHintNoStations =>
      'Augmentez le rayon de recherche ou cherchez à un autre endroit.';

  @override
  String get errorHintApiKey => 'Configurez votre clé API dans Paramètres.';

  @override
  String get errorHintConnection =>
      'Vérifiez votre connexion internet et réessayez.';

  @override
  String get errorHintRouting =>
      'Calcul d\'itinéraire échoué. Vérifiez votre connexion internet.';

  @override
  String get errorHintFallback =>
      'Réessayez ou cherchez par code postal / ville.';

  @override
  String get alertsLoadErrorTitle => 'Couldn\'t load your alerts';

  @override
  String get alertsBackgroundCheckErrorTitle => 'Alert background check failed';

  @override
  String get detailsLabel => 'Détails';

  @override
  String get remove => 'Retirer';

  @override
  String get showKey => 'Afficher la clé';

  @override
  String get hideKey => 'Masquer la clé';

  @override
  String get syncOptionalTitle => 'TankSync est optionnel';

  @override
  String get syncOptionalDescription =>
      'L\'application fonctionne entièrement sans synchronisation cloud. TankSync permet de synchroniser favoris, alertes et notes entre appareils via Supabase (forfait gratuit disponible).';

  @override
  String get syncHowToConnectQuestion =>
      'Comment souhaitez-vous vous connecter ?';

  @override
  String get syncCreateOwnTitle => 'Créer ma propre base de données';

  @override
  String get syncCreateOwnSubtitle =>
      'Projet Supabase gratuit — guidé pas à pas';

  @override
  String get syncJoinExistingTitle => 'Rejoindre une base existante';

  @override
  String get syncJoinExistingSubtitle =>
      'Scannez le QR code du propriétaire ou collez les identifiants';

  @override
  String get syncChooseAccountType => 'Choisissez votre type de compte';

  @override
  String get syncAccountTypeAnonymous => 'Anonyme';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Instantané, sans e-mail. Les données restent sur cet appareil.';

  @override
  String get syncAccountTypeEmail => 'Compte e-mail';

  @override
  String get syncAccountTypeEmailDesc =>
      'Connectez-vous depuis n\'importe quel appareil. Récupérez vos données en cas de perte.';

  @override
  String get syncHaveAccountSignIn => 'Déjà un compte ? Connectez-vous';

  @override
  String get syncCreateNewAccount => 'Créer un nouveau compte';

  @override
  String get syncTestConnection => 'Tester la connexion';

  @override
  String get syncTestingConnection => 'Test en cours...';

  @override
  String get syncConnectButton => 'Connecter';

  @override
  String get syncConnectingButton => 'Connexion...';

  @override
  String get syncDatabaseReady => 'Base de données prête !';

  @override
  String get syncDatabaseNeedsSetup => 'Configuration requise';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Manquante';

  @override
  String get syncSqlEditorInstructions =>
      'Copiez le SQL ci-dessous et exécutez-le dans l\'éditeur SQL Supabase (Dashboard → SQL Editor → New Query → Coller → Exécuter)';

  @override
  String get syncCopySqlButton => 'Copier le SQL';

  @override
  String get syncRecheckSchemaButton => 'Re-vérifier le schéma';

  @override
  String get syncDoneButton => 'Terminé';

  @override
  String syncSignedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get syncEmailDescription =>
      'Vos données sont synchronisées sur tous vos appareils avec cet e-mail.';

  @override
  String get syncSwitchToAnonymousTitle => 'Passer en anonyme';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continuer sans e-mail, nouvelle session anonyme';

  @override
  String get syncGuestDescription => 'Anonyme, sans e-mail.';

  @override
  String get syncOrDivider => 'ou';

  @override
  String get syncHowToSyncQuestion => 'Comment souhaitez-vous synchroniser ?';

  @override
  String get syncOfflineDescription =>
      'L\'application fonctionne entièrement hors ligne. La synchronisation cloud est optionnelle.';

  @override
  String get syncModeCommunityTitle => 'Communauté Tankstellen';

  @override
  String get syncModeCommunitySubtitle =>
      'Partagez favoris et notes avec tous les utilisateurs';

  @override
  String get syncModePrivateTitle => 'Base privée';

  @override
  String get syncModePrivateSubtitle =>
      'Votre propre Supabase — contrôle total';

  @override
  String get syncModeGroupTitle => 'Rejoindre un groupe';

  @override
  String get syncModeGroupSubtitle => 'Base partagée famille ou amis';

  @override
  String get syncPrivacyShared => 'Partagé';

  @override
  String get syncPrivacyPrivate => 'Privé';

  @override
  String get syncPrivacyGroup => 'Groupe';

  @override
  String get syncStayOfflineButton => 'Rester hors ligne';

  @override
  String get syncSuccessTitle => 'Connecté avec succès !';

  @override
  String get syncSuccessDescription =>
      'Vos données seront maintenant synchronisées automatiquement.';

  @override
  String get syncWizardTitleConnect => 'Connecter TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Votre base de données';

  @override
  String get syncSetupTitleJoinGroup => 'Rejoindre un groupe';

  @override
  String get syncSetupTitleAccount => 'Votre compte';

  @override
  String get syncWizardBack => 'Retour';

  @override
  String get syncWizardNext => 'Suivant';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Créer un projet Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Appuyez sur « Ouvrir Supabase » ci-dessous\n2. Créez un compte gratuit (si vous n\'en avez pas)\n3. Cliquez sur « New Project »\n4. Choisissez un nom et une région\n5. Attendez environ 2 minutes';

  @override
  String get syncWizardOpenSupabase => 'Ouvrir Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Activer les connexions anonymes';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Dans votre tableau de bord Supabase :\n   Authentication → Providers\n2. Trouvez « Anonymous Sign-ins »\n3. Activez-le\n4. Cliquez sur « Save »';

  @override
  String get syncWizardOpenAuthSettings =>
      'Ouvrir les paramètres d\'authentification';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copier vos identifiants';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Allez dans Settings → API dans votre tableau de bord\n2. Copiez la « Project URL »\n3. Copiez la clé « anon public »\n4. Collez-les ci-dessous';

  @override
  String get syncWizardOpenApiSettings => 'Ouvrir les paramètres API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://votre-projet.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Rejoindre une base existante';

  @override
  String get syncWizardScanQrCode => 'Scanner le QR Code';

  @override
  String get syncWizardAskOwnerQr =>
      'Demandez au propriétaire de la base de vous montrer son QR code\n(Paramètres → TankSync → Partager)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Demandez au propriétaire de la base de montrer son QR code';

  @override
  String get syncWizardEnterManuallyTitle => 'Saisir manuellement';

  @override
  String get syncWizardOrEnterManually => 'ou saisir manuellement';

  @override
  String get syncWizardUrlHelperText =>
      'Les espaces et les sauts de ligne sont automatiquement supprimés';

  @override
  String get syncCredentialsPrivateHint =>
      'Entrez les identifiants de votre projet Supabase. Vous les trouverez dans votre tableau de bord sous Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL de la base de données';

  @override
  String get syncCredentialsAccessKeyLabel => 'Clé d\'accès';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authPleaseEnterEmail => 'Veuillez saisir votre e-mail';

  @override
  String get authInvalidEmail => 'Adresse e-mail invalide';

  @override
  String get authPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get authConnectAnonymously => 'Se connecter anonymement';

  @override
  String get authCreateAccountAndConnect => 'Créer un compte et se connecter';

  @override
  String get authSignInAndConnect => 'Se connecter';

  @override
  String get authAnonymousSegment => 'Anonyme';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Accès instantané, sans e-mail. Données liées à cet appareil.';

  @override
  String get authEmailDescription =>
      'Connectez-vous depuis n\'importe quel appareil. Récupérez vos données en cas de perte du téléphone.';

  @override
  String get authSyncAcrossDevices =>
      'Synchronisez automatiquement vos données sur tous vos appareils.';

  @override
  String get authNewHereCreateAccount => 'Nouveau ? Créer un compte';

  @override
  String get ntfyCardTitle => 'Notifications push (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Activer les push ntfy.sh';

  @override
  String get ntfyEnableSubtitle => 'Recevez les alertes de prix via ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'URL du topic';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Copier l\'URL du topic';

  @override
  String get ntfySendTestButton => 'Envoyer une notification test';

  @override
  String get ntfyFdroidHint =>
      'Installez l\'application ntfy depuis F-Droid pour recevoir des notifications push sur votre appareil.';

  @override
  String get ntfyConnectFirstHint =>
      'Connectez d\'abord TankSync pour activer les notifications push.';

  @override
  String get linkDeviceScreenTitle => 'Lier un appareil';

  @override
  String get linkDeviceThisDeviceLabel => 'Cet appareil';

  @override
  String get linkDeviceShareCodeHint =>
      'Partagez ce code avec votre autre appareil :';

  @override
  String get linkDeviceNotConnected => 'Non connecté';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copier le code';

  @override
  String get linkDeviceImportSectionTitle =>
      'Importer depuis un autre appareil';

  @override
  String get linkDeviceImportDescription =>
      'Saisissez le code de votre autre appareil pour importer ses favoris, alertes, véhicules et journal de consommation. Chaque appareil conserve son propre profil et ses préférences.';

  @override
  String get linkDeviceCodeFieldLabel => 'Code de l\'appareil';

  @override
  String get linkDeviceCodeFieldHint => 'Collez l\'UUID de l\'autre appareil';

  @override
  String get linkDeviceImportButton => 'Importer les données';

  @override
  String get linkDeviceHowItWorksTitle => 'Comment ça marche';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Sur l\'appareil A : copiez le code ci-dessus\n2. Sur l\'appareil B : collez-le dans le champ « Code de l\'appareil »\n3. Appuyez sur « Importer les données » pour fusionner favoris, alertes, véhicules et journal de consommation\n4. Les deux appareils auront toutes les données combinées\n\nChaque appareil garde sa propre identité anonyme et son propre profil (carburant préféré, véhicule par défaut, écran d\'accueil). Les données sont fusionnées, pas déplacées.';

  @override
  String get vehicleSetActive => 'Activer';

  @override
  String get swipeHide => 'Masquer';

  @override
  String get evChargingSection => 'Recharge EV';

  @override
  String get fuelStationsSection => 'Stations-service';

  @override
  String get yourRating => 'Votre note';

  @override
  String get noStorageUsed => 'Aucun stockage utilisé';

  @override
  String get aboutReportBug => 'Signaler un bug / Suggérer une fonctionnalité';

  @override
  String get aboutSupportProject => 'Soutenir ce projet';

  @override
  String get aboutSupportDescription =>
      'Cette application est gratuite, open source et sans publicité. Si vous la trouvez utile, soutenez le développeur.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxembourg fuel prices are government-regulated and uniform nationwide.';

  @override
  String get luxembourgFuelUnleaded95 => 'Unleaded 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Unleaded 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxembourg regulated prices are unavailable.';

  @override
  String get reportIssueTitle => 'Report a problem';

  @override
  String get enterCorrection => 'Please enter the correction';

  @override
  String get reportNoBackendAvailable =>
      'The report could not be sent: no reporting service is configured for this country. Enable TankSync in Settings to send community reports.';

  @override
  String get correctName => 'Correct station name';

  @override
  String get correctAddress => 'Correct address';

  @override
  String get wrongE85Price => 'Wrong E85 price';

  @override
  String get wrongE98Price => 'Wrong Super 98 price';

  @override
  String get wrongLpgPrice => 'Wrong LPG price';

  @override
  String get wrongStationName => 'Wrong station name';

  @override
  String get wrongStationAddress => 'Wrong address';

  @override
  String get independentStation => 'Independent station';

  @override
  String get serviceRemindersSection => 'Service reminders';

  @override
  String get serviceRemindersEmpty => 'No reminders yet — pick a preset above.';

  @override
  String get addServiceReminder => 'Add reminder';

  @override
  String get serviceReminderPresetOil => 'Oil (15,000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Oil change';

  @override
  String get serviceReminderPresetTires => 'Tires (20,000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Tires';

  @override
  String get serviceReminderPresetInspection => 'Inspection (30,000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Inspection';

  @override
  String get serviceReminderLabel => 'Label';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Last service';

  @override
  String get serviceReminderMarkDone => 'Mark as done';

  @override
  String get serviceReminderDueTitle => 'Service due';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label is due — $kmOver km past the interval.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Register at OPINET to get a free API key';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired => 'Register at CNE to get a free API key';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Is this your car?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-cyl, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Partial info (offline). You can edit below.';

  @override
  String get vinDecodeError => 'Couldn\'t decode this VIN';

  @override
  String get vinInvalidFormat => 'Invalid VIN format';

  @override
  String get obd2PauseBannerTitle => 'OBD2 connection lost — recording paused';

  @override
  String get obd2PauseBannerResume => 'Resume recording';

  @override
  String get obd2PauseBannerEnd => 'End recording';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Consumption calibration updated for $vehicleName — accuracy improved by $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Reset calibration?';

  @override
  String get veResetConfirmBody =>
      'This will discard the learned per-vehicle calibration and restore the default value (0.85).';

  @override
  String get alertsRadiusSectionTitle => 'Radius alerts';

  @override
  String get alertsRadiusAdd => 'Add radius alert';

  @override
  String get alertsRadiusEmptyTitle => 'No radius alerts yet';

  @override
  String get alertsRadiusEmptyCta => 'Create a radius alert';

  @override
  String get alertsRadiusCreateTitle => 'Create radius alert';

  @override
  String get alertsRadiusLabelHint => 'Label (e.g. Home diesel)';

  @override
  String get alertsRadiusFuelType => 'Fuel type';

  @override
  String get alertsRadiusThreshold => 'Threshold (€/L)';

  @override
  String get alertsRadiusKm => 'Radius (km)';

  @override
  String get alertsRadiusCenterGps => 'Use my location';

  @override
  String get alertsRadiusCenterPostalCode => 'Postal code';

  @override
  String get alertsRadiusSave => 'Save';

  @override
  String get alertsRadiusCancel => 'Cancel';

  @override
  String get alertsRadiusDeleteConfirm => 'Delete radius alert?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 connected: $adapterName';
  }

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel dropped at nearby stations';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stations dropped by up to $maxDropCents¢ in the last hour';
  }

  @override
  String get consumptionTabFuel => 'Fuel';

  @override
  String get consumptionTabCharging => 'Charging';

  @override
  String get noChargingLogsTitle => 'No charging logs yet';

  @override
  String get noChargingLogsSubtitle =>
      'Log your first charging session to start tracking EUR/100 km and kWh/100 km.';

  @override
  String get addChargingLog => 'Log charging';

  @override
  String get addChargingLogTitle => 'Log charging session';

  @override
  String get chargingKwh => 'Energy (kWh)';

  @override
  String get chargingCost => 'Total cost';

  @override
  String get chargingTimeMin => 'Charge time (min)';

  @override
  String get chargingStationName => 'Station (optional)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Need a previous log to compare';

  @override
  String get chargingLogButtonLabel => 'Log charging';

  @override
  String get chargingCostTrendTitle => 'Charging cost trend';

  @override
  String get chargingEfficiencyTitle => 'Efficiency (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Not enough data yet';

  @override
  String get chargingChartsMonthAxis => 'Month';

  @override
  String get scanReceiptNoData => 'No receipt data found — try again';

  @override
  String get scanReceiptSuccess =>
      'Receipt scanned — verify values. Tap \"Report scan error\" below if anything is off.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get scanPumpUnreadable => 'Pump display not readable — try again';

  @override
  String get scanPumpSuccess => 'Pump display scanned — verify the values.';

  @override
  String scanPumpFailed(String error) {
    return 'Pump scan failed: $error';
  }

  @override
  String get badScanReportTitle => 'Report a scan error';

  @override
  String get badScanReportHint =>
      'We\'ll share the receipt photo and both sets of values so the next build can learn this layout.';

  @override
  String get badScanReportShareAction => 'Share report + photo';

  @override
  String get badScanReportFieldBrandLayout => 'Brand layout';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Price/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Fuel';

  @override
  String get badScanReportFieldDate => 'Date';

  @override
  String get badScanReportHeaderField => 'Field';

  @override
  String get badScanReportHeaderScanned => 'Scanned';

  @override
  String get badScanReportHeaderYouTyped => 'You typed';

  @override
  String get fillUpSectionWhatTitle => 'What you filled';

  @override
  String get fillUpSectionWhatSubtitle => 'Fuel, amount, price';

  @override
  String get fillUpSectionWhereTitle => 'Where you were';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, odometer, notes';

  @override
  String get fillUpImportFromLabel => 'Import from…';

  @override
  String get fillUpImportSheetTitle => 'Import fill-up data';

  @override
  String get fillUpImportReceiptLabel => 'Receipt';

  @override
  String get fillUpImportReceiptDescription =>
      'Scan a paper receipt with the camera';

  @override
  String get fillUpImportPumpLabel => 'Pump display';

  @override
  String get fillUpImportPumpDescription =>
      'Read Betrag / Preis from the pump LCD';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Read odometer from the OBD-II port over Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Price per liter';

  @override
  String get vehicleHeaderPlateLabel => 'Plate';

  @override
  String get vehicleHeaderUntitled => 'New vehicle';

  @override
  String get vehicleSectionIdentityTitle => 'Identity';

  @override
  String get vehicleSectionIdentitySubtitle => 'Name & VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Drivetrain';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'How this vehicle moves';

  @override
  String get onboardingObd2StepTitle => 'Connecter votre adaptateur OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Branchez votre adaptateur OBD2 pour lire automatiquement les informations de votre véhicule — marque, modèle, motorisation — via le numéro de série (VIN). Vous pouvez aussi passer cette étape et saisir manuellement.';

  @override
  String get onboardingObd2ConnectButton => 'Connecter l\'adaptateur';

  @override
  String get onboardingObd2SkipButton => 'Plus tard';

  @override
  String get onboardingObd2ReadingVin => 'Lecture du VIN en cours...';

  @override
  String get onboardingObd2VinReadFailed =>
      'Impossible de lire le VIN — saisie manuelle';

  @override
  String get onboardingObd2ConnectFailed =>
      'Connexion impossible — vérifiez l\'adaptateur ou passez l\'étape';

  @override
  String get radiusAlertPickOnMap => 'Pick on map';

  @override
  String get radiusAlertMapPickerTitle => 'Pick alert center';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirm';

  @override
  String get radiusAlertMapPickerCancel => 'Cancel';

  @override
  String get radiusAlertMapPickerHint =>
      'Drag the map to position the alert center';

  @override
  String get radiusAlertCenterFromMap => 'Map location';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel near $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'A station is at $price € (target: $threshold €)';
  }

  @override
  String get splashLoadingLabel => 'Loading Tankstellen';

  @override
  String get vinLabel => 'VIN (optional)';

  @override
  String get vinDecodeTooltip => 'Decode VIN';

  @override
  String get vinConfirmAction => 'Yes, auto-fill';

  @override
  String get vinModifyAction => 'Modify manually';

  @override
  String get veResetAction => 'Reset calibration';
}
