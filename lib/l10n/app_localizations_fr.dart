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
  String get supportProject => 'Soutenir ce projet';

  @override
  String get supportDescription =>
      'Cette application est gratuite, open source et sans publicité. Si vous la trouvez utile, pensez à soutenir le développeur.';

  @override
  String get reportBug => 'Signaler un bug / Suggérer une amélioration';

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
}
