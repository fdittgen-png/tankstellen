// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Ouvrir la recherche';

  @override
  String get fabOpenResults => 'Ouvrir les résultats';

  @override
  String get fabRunSearch => 'Lancer la recherche';

  @override
  String get fabRefineCriteria => 'Affiner la recherche';

  @override
  String get routeSearchPartialBanner => 'Recherche d\'autres stations…';

  @override
  String get routeSearchingChip => 'Recherche sur l\'itinéraire…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Tous les $km km';
  }

  @override
  String get searchCriteriaTitle => 'Critères de recherche';

  @override
  String get searchCriteriaOpen => 'Rechercher';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Dans un rayon de $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Touchez pour lancer la recherche';

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
  String get welcome => 'Sparkilo';

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
  String get cacheTtlGroupNetwork => 'Réseau';

  @override
  String get cacheTtlGroupData => 'Données';

  @override
  String get cacheTtlGroupGeocoding => 'Géocodage';

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
  String get reportAlreadySent => 'Vous avez déjà signalé ce problème.';

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
  String get demoModeBanner => 'Mode démo – prix d\'exemple affichés.';

  @override
  String get demoModeBannerAction => 'Activer les prix réels';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Note';

  @override
  String get sortPriceDistance => 'Prix/km';

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
  String get routeModeBannerLabel =>
      'Mode itinéraire — distances le long du corridor';

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
  String profileSwitchedTo(String profile) {
    return 'Profil $profile activé';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name créé';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Un profil existe déjà pour $country — modifiez-le plutôt.';
  }

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
  String get evPriceFree => 'Gratuit';

  @override
  String get evPricePayAtLocation => 'Paiement sur place';

  @override
  String get evPriceMembership => 'Abonnement requis';

  @override
  String get evPriceIndicative => 'Prix indicatif';

  @override
  String get evPriceDeclaredByOperator =>
      'Prix indicatif déclaré par l\'opérateur — à vérifier sur place';

  @override
  String get evPriceFranceAttribution =>
      'Tarification : Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Tarification au mieux d\'OpenChargeMap — partielle et peut être incomplète.';

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
  String get routePlanningSection => 'Planification d\'itinéraire';

  @override
  String get routeMinSaving => 'Économie minimale';

  @override
  String get routeMinSavingOff => 'Désactivé';

  @override
  String get routeMinSavingOffCaption =>
      'Affiche toutes les stations trouvées le long de l\'itinéraire';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Uniquement les stations dans une marge de $amount de la moins chère de l\'itinéraire';
  }

  @override
  String get routeDetourBudget => 'Détour maximal';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Afficher les stations jusqu\'à $km km de votre itinéraire direct';
  }

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
  String calculatorDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consommation ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Prix du carburant ($unit)';
  }

  @override
  String get calculatorUseMine => 'Utiliser';

  @override
  String get calculatorApplied => 'Appliqué';

  @override
  String get tripDetails => 'Détails du trajet';

  @override
  String get calculatorRoundTrip => 'Aller-retour';

  @override
  String get roundTripTotal => 'Total aller-retour';

  @override
  String get costPerDistance => 'Coût par km';

  @override
  String get costPerMonth => 'Coût par mois';

  @override
  String get calculatorEstimateMonthly => 'Estimer le coût mensuel';

  @override
  String get calculatorTripsPerMonth => 'Trajets par mois';

  @override
  String get calculatorTripsPerMonthHint => 'ex. 20';

  @override
  String get calculatorReset => 'Réinitialiser';

  @override
  String get calculatorResultPlaceholder =>
      'Renseignez la distance, la consommation et le prix pour voir le coût de votre trajet';

  @override
  String get priceHistory => 'Historique des prix';

  @override
  String get ignoredStationsLabel => 'Stations masquées';

  @override
  String get ratingsLabel => 'Notes';

  @override
  String get favoritesDataCache => 'Données favoris';

  @override
  String get citySearchCache => 'Recherche de ville';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'La suppression des données n\'est pas disponible en mode Communauté. Déconnectez-vous d\'abord, ou utilisez une base de données privée.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count stations suivies';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count configurée(s)';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count stations masquées';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count stations notées';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Oublier tous les trajets synchronisés';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Oublier tous les trajets synchronisés ?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Chaque résumé de trajet et bloc de détails sera supprimé du serveur. L\'historique de trajets local sur cet appareil ne sera pas affecté.\n\nCette action est irréversible.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Tout oublier';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Tous les trajets synchronisés ont été supprimés du serveur';

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
  String get syncedTrips => 'Trajets';

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
    return '$name supprimé';
  }

  @override
  String loadingRoute(String name) {
    return 'Chargement de l\'itinéraire : $name';
  }

  @override
  String get refreshFailed => 'Échec de l\'actualisation. Veuillez réessayer.';

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
    return '$country est à proximité';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km jusqu\'à la frontière';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Moy. ici : $price EUR ($count stations)';
  }

  @override
  String get allPricesView => 'Tous les prix';

  @override
  String get compactView => 'Compact';

  @override
  String get switchToAllPricesView => 'Passer à la vue tous les prix';

  @override
  String get switchToCompactView => 'Passer à la vue compacte';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'En rupture';

  @override
  String get gdprTitle => 'Votre confidentialité';

  @override
  String get gdprSubtitle =>
      'Cette application respecte votre vie privée. Choisissez les données que vous souhaitez partager. Vous pouvez modifier ces paramètres à tout moment.';

  @override
  String get gdprLocationTitle => 'Accès à la localisation';

  @override
  String get gdprLocationDescription =>
      'Vos coordonnées sont envoyées à l\'API des prix des carburants pour trouver les stations à proximité. Les données de localisation ne sont jamais stockées sur un serveur et ne servent pas au suivi.';

  @override
  String get gdprLocationShort =>
      'Trouver les stations-service à proximité grâce à votre localisation';

  @override
  String get gdprErrorReportingTitle => 'Rapports d\'erreurs';

  @override
  String get gdprErrorReportingDescription =>
      'Les rapports de plantage anonymes aident à améliorer l\'application. Aucune donnée personnelle n\'est incluse. Les rapports sont envoyés via Sentry uniquement lorsqu\'il est configuré.';

  @override
  String get gdprErrorReportingShort =>
      'Envoyer des rapports de plantage anonymes pour améliorer l\'application';

  @override
  String get gdprCloudSyncTitle => 'Synchronisation cloud';

  @override
  String get gdprCloudSyncDescription =>
      'Synchronisez vos favoris et alertes entre appareils via TankSync. Utilise une authentification anonyme. Vos données sont chiffrées pendant le transfert.';

  @override
  String get gdprCloudSyncShort =>
      'Synchroniser les favoris et alertes entre appareils';

  @override
  String get gdprLegalBasis =>
      'Base légale : art. 6(1)(a) du RGPD (consentement). Vous pouvez retirer votre consentement à tout moment dans les Paramètres.';

  @override
  String get gdprAcceptAll => 'Tout accepter';

  @override
  String get gdprAcceptSelected => 'Accepter la sélection';

  @override
  String get gdprSettingsHint =>
      'Vous pouvez modifier vos choix de confidentialité à tout moment.';

  @override
  String get routeSaved => 'Itinéraire enregistré !';

  @override
  String get routeSaveFailed => 'Échec de l\'enregistrement de l\'itinéraire';

  @override
  String get sqlCopied => 'SQL copié dans le presse-papiers';

  @override
  String get connectionDataCopied => 'Données de connexion copiées';

  @override
  String get accountDeleted => 'Compte supprimé. Données locales conservées.';

  @override
  String get switchedToAnonymous => 'Passé en session anonyme';

  @override
  String failedToSwitch(String error) {
    return 'Échec du changement : $error';
  }

  @override
  String get topicUrlCopied => 'URL du sujet copiée';

  @override
  String get testNotificationSent => 'Notification de test envoyée !';

  @override
  String get testNotificationFailed =>
      'Échec de l\'envoi de la notification de test';

  @override
  String get pushUpdateFailed =>
      'Échec de la mise à jour du paramètre de notification push';

  @override
  String get connectedAsGuest => 'Connecté en tant qu\'invité';

  @override
  String get accountCreated => 'Compte créé !';

  @override
  String get signedIn => 'Connecté !';

  @override
  String stationHidden(String name) {
    return '$name masquée';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name retirée des favoris';
  }

  @override
  String invalidApiKey(String error) {
    return 'Clé API invalide : $error';
  }

  @override
  String get invalidQrCode => 'Format de QR code invalide';

  @override
  String get invalidQrCodeTankSync =>
      'QR code invalide — format TankSync attendu';

  @override
  String get tankSyncConnected => 'TankSync connecté !';

  @override
  String get syncCompleted => 'Synchronisation terminée — données actualisées';

  @override
  String get deviceCodeCopied => 'Code d\'appareil copié';

  @override
  String get undo => 'Annuler';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Veuillez saisir un $label valide à $length chiffres';
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
  String brandLogoLabel(String brand) {
    return 'Logo $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noter $count étoiles',
      one: 'Noter 1 étoile',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthFair => 'Moyen';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get passwordReqMinLength => 'Au moins 8 caractères';

  @override
  String get passwordReqUppercase => 'Au moins 1 majuscule';

  @override
  String get passwordReqLowercase => 'Au moins 1 minuscule';

  @override
  String get passwordReqDigit => 'Au moins 1 chiffre';

  @override
  String get passwordReqSpecial => 'Au moins 1 caractère spécial';

  @override
  String get passwordTooWeak =>
      'Le mot de passe ne respecte pas toutes les exigences';

  @override
  String get brandFilterAll => 'Toutes';

  @override
  String get brandFilterNoHighway => 'Hors autoroute';

  @override
  String get swipeTutorialMessage =>
      'Balayez vers la droite pour naviguer, vers la gauche pour supprimer';

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
  String get privacyDashboardSubtitle =>
      'Consultez, exportez ou supprimez vos données';

  @override
  String get privacyDashboardBanner =>
      'Vos données vous appartiennent. Vous pouvez voir ici tout ce que cette application stocke, l\'exporter ou le supprimer.';

  @override
  String get privacyLocalData => 'Données sur cet appareil';

  @override
  String get privacyIgnoredStations => 'Stations ignorées';

  @override
  String get privacyRatings => 'Notes des stations';

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
  String get privacySyncMode => 'Mode de synchronisation';

  @override
  String get privacySyncUserId => 'Identifiant utilisateur';

  @override
  String get privacySyncDescription =>
      'Lorsque la synchronisation est activée, les favoris, alertes, stations ignorées et notes sont aussi stockés sur le serveur TankSync.';

  @override
  String get privacyViewServerData => 'Voir les données du serveur';

  @override
  String get privacyExportButton => 'Exporter toutes les données en JSON';

  @override
  String get privacyExportSuccess => 'Données exportées dans le presse-papiers';

  @override
  String get privacyExportCsvButton => 'Exporter toutes les données en CSV';

  @override
  String get privacyExportCsvSuccess =>
      'Données CSV exportées dans le presse-papiers';

  @override
  String get savedToDownloadsFolder =>
      'Enregistré dans le dossier Téléchargements';

  @override
  String get privacyDeleteButton => 'Tout supprimer';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Copier le journal d\'erreurs ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Enregistrer le journal d\'erreurs ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Effacer le journal d\'erreurs';

  @override
  String get privacyErrorLogCleared => 'Journal d\'erreurs effacé';

  @override
  String get privacyDeleteTitle => 'Supprimer toutes les données ?';

  @override
  String get privacyDeleteBody =>
      'Cela supprimera définitivement :\n\n- Tous les favoris et données de stations\n- Tous les profils de recherche\n- Toutes les alertes de prix\n- Tout l\'historique des prix\n- Toutes les données en cache\n- Votre clé API\n- Tous les paramètres de l\'application\n\nL\'application sera réinitialisée à son état initial. Cette action est irréversible.';

  @override
  String get privacyDeleteConfirm => 'Tout supprimer';

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
  String get drivingMode => 'Mode conduite';

  @override
  String get drivingExit => 'Quitter';

  @override
  String get drivingNearestStation => 'La plus proche';

  @override
  String get drivingTapToUnlock => 'Touchez pour déverrouiller';

  @override
  String get drivingSafetyTitle => 'Avis de sécurité';

  @override
  String get drivingSafetyMessage =>
      'N\'utilisez pas l\'application en conduisant. Arrêtez-vous dans un endroit sûr avant d\'interagir avec l\'écran. Le conducteur est responsable de la conduite sûre du véhicule à tout moment.';

  @override
  String get drivingSafetyAccept => 'J\'ai compris';

  @override
  String get voiceAnnouncementsTitle => 'Annonces vocales';

  @override
  String get voiceAnnouncementsDescription =>
      'Annoncer les stations bon marché à proximité pendant la conduite';

  @override
  String get voiceAnnouncementsEnabled => 'Activer les annonces vocales';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Uniquement en dessous de $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, à $distance kilomètres, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Rayon d\'annonce';

  @override
  String get voiceAnnouncementCooldown => 'Intervalle de répétition';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximum price';

  @override
  String get nearestStations => 'Stations les plus proches';

  @override
  String get nearestStationsHint =>
      'Trouver les stations les plus proches avec votre position actuelle';

  @override
  String get consumptionLogTitle => 'Consommation';

  @override
  String get consumptionLogMenuTitle => 'Journal de consommation';

  @override
  String get consumptionLogMenuSubtitle =>
      'Suivez les pleins et calculez les L/100 km';

  @override
  String get consumptionStatsTitle => 'Statistiques de consommation';

  @override
  String get addFillUp => 'Ajouter un plein';

  @override
  String get noFillUpsTitle => 'Aucun plein pour l\'instant';

  @override
  String get noFillUpsSubtitle =>
      'Enregistrez votre premier plein pour suivre votre consommation.';

  @override
  String get fillUpDate => 'Date';

  @override
  String get liters => 'Litres';

  @override
  String get odometerKm => 'Compteur (km)';

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get stationPreFilled => 'Station pré-remplie';

  @override
  String get statAvgConsumption => 'Conso moy. L/100 km';

  @override
  String get statAvgCostPerKm => 'Coût moy./km';

  @override
  String get statTotalLiters => 'Litres au total';

  @override
  String get statTotalSpent => 'Total dépensé';

  @override
  String get statFillUpCount => 'Pleins';

  @override
  String get fieldRequired => 'Obligatoire';

  @override
  String get fieldInvalidNumber => 'Nombre invalide';

  @override
  String get carbonDashboardTitle => 'Tableau de bord carbone';

  @override
  String get carbonEmptyTitle => 'Aucune donnée pour l\'instant';

  @override
  String get carbonEmptySubtitle =>
      'Enregistrez des pleins pour voir votre tableau de bord carbone.';

  @override
  String get carbonSummaryTotalCost => 'Coût total';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 total';

  @override
  String get monthlyCostsTitle => 'Coûts mensuels';

  @override
  String get monthlyEmissionsTitle => 'Émissions de CO2 mensuelles';

  @override
  String get vehiclesTitle => 'Mes véhicules';

  @override
  String get vehiclesMenuTitle => 'Mes véhicules';

  @override
  String get vehiclesMenuSubtitle =>
      'Vos voitures — type de carburant, moteur et capacité du réservoir pour des estimations de consommation précises';

  @override
  String get vehiclesEmptyMessage =>
      'Ajoutez votre voiture pour filtrer par connecteur et estimer les coûts de recharge.';

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
  String get vehicleBaselineReset => 'Réinitialiser la baseline par situation';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Réinitialiser la baseline par situation ?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Ceci efface tous les échantillons appris pour ce véhicule. Les valeurs par défaut au démarrage à froid seront utilisées jusqu\'à ce que de nouveaux trajets reconstruisent le profil.';

  @override
  String get vehicleBaselineShowDetails => 'Afficher le détail par situation';

  @override
  String get vehicleBaselineHideDetails => 'Masquer le détail par situation';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Pas encore détecté : $situations. Ces situations de conduite n\'ont toujours aucun échantillon, la référence est donc incomplète.';
  }

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
  String get situationColdStart => 'Démarrage à froid';

  @override
  String get situationSustainedLoad => 'Charge soutenue / remorquage';

  @override
  String get situationPartialDecel => 'Décélération en roue libre';

  @override
  String get situationHardAccel => 'Accél. forte';

  @override
  String get situationFuelCut => 'Coupure — roue libre';

  @override
  String get tripSaveAsFillUp => 'Enregistrer comme plein';

  @override
  String get tripSaveRecording => 'Enregistrer le trajet';

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
  String get wizardProfileChoiceHint =>
      'Choisissez comment vous voulez utiliser l\'application. Vous pourrez modifier ce choix plus tard dans les Paramètres.';

  @override
  String get wizardProfileChoiceFooter =>
      'Vous pouvez changer votre choix à tout moment depuis Paramètres → Mode d\'utilisation.';

  @override
  String get wizardProfileBasicName => 'Basique';

  @override
  String get wizardProfileBasicDescription =>
      'Prix carburant et recharge électrique les moins chers à proximité. Favoris et alertes de prix.';

  @override
  String get wizardProfileMediumName => 'Moyen';

  @override
  String get wizardProfileMediumDescription =>
      'Tout du mode Basique, plus le suivi manuel de vos pleins et recharges électriques.';

  @override
  String get wizardProfileFullName => 'Complet';

  @override
  String get wizardProfileFullDescription =>
      'Tout du mode Moyen, plus l\'enregistrement automatique des trajets via OBD2, scores de conduite et cartes de fidélité.';

  @override
  String get wizardProfileCustomName => 'Personnalisé';

  @override
  String get wizardProfileCustomDescription =>
      'Votre propre combinaison de fonctionnalités. Ajustez chaque option ci-dessous.';

  @override
  String get useModeSectionHint =>
      'Adaptez l\'application à votre usage réel. Choisir un préréglage active l\'ensemble des fonctionnalités correspondant.';

  @override
  String get useModeCustomSettingsDescription =>
      'Votre combinaison de fonctionnalités ne correspond à aucun préréglage. Choisissez-en un ci-dessus pour l\'écraser, ou continuez à personnaliser les fonctionnalités ci-dessous.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Mode d\'utilisation : $profile.';
  }

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
  String get vehicleAdd => 'Ajouter un véhicule';

  @override
  String get vehicleAddTitle => 'Ajouter un véhicule';

  @override
  String get vehicleEditTitle => 'Modifier le véhicule';

  @override
  String get vehicleDeleteTitle => 'Supprimer le véhicule ?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Retirer « $name » de vos profils ?';
  }

  @override
  String get vehicleNameLabel => 'Nom';

  @override
  String get vehicleNameHint => 'ex. Ma Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Thermique';

  @override
  String get vehicleTypeHybrid => 'Hybride';

  @override
  String get vehicleTypeEv => 'Électrique';

  @override
  String get vehicleEvSectionTitle => 'Électrique';

  @override
  String get vehicleCombustionSectionTitle => 'Thermique';

  @override
  String get vehicleBatteryLabel => 'Capacité de la batterie (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Puissance de recharge maximale (kW)';

  @override
  String get vehicleConnectorsLabel => 'Connecteurs pris en charge';

  @override
  String get vehicleMinSocLabel => 'SoC min. %';

  @override
  String get vehicleMaxSocLabel => 'SoC max. %';

  @override
  String get vehicleTankLabel => 'Capacité du réservoir (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Carburant préféré';

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
  String get connectorThreePin => '3 broches';

  @override
  String get evShowOnMap => 'Afficher les bornes de recharge';

  @override
  String get evAvailableOnly => 'Disponibles uniquement';

  @override
  String get evMinPower => 'Puissance min.';

  @override
  String get evMaxPower => 'Puissance max.';

  @override
  String get evOperator => 'Opérateur';

  @override
  String get evLastUpdate => 'Dernière mise à jour';

  @override
  String get evStatusAvailable => 'Disponible';

  @override
  String get evStatusOccupied => 'Occupée';

  @override
  String get evStatusOutOfOrder => 'Hors service';

  @override
  String get evStatusPartial => 'Partiellement disponible';

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
  String get sectionSetupDataSources => 'Configuration et sources de données';

  @override
  String get sectionFeaturesUsage => 'Fonctionnalités et utilisation';

  @override
  String get sectionAccountSync => 'Compte et synchronisation';

  @override
  String get sectionAppearanceWidgets => 'Apparence et widgets';

  @override
  String get sectionPrivacyData => 'Confidentialité et données';

  @override
  String get sectionAdvancedDeveloper => 'Avancé et développeur';

  @override
  String get tooltipBack => 'Retour';

  @override
  String get tooltipClose => 'Fermer';

  @override
  String get tooltipShare => 'Partager';

  @override
  String get tooltipClearSearch => 'Effacer la recherche';

  @override
  String get minimalDriveInstantConsumption => 'Consommation instantanée';

  @override
  String get coachingShiftUp => 'Monter un rapport';

  @override
  String get coachingShiftDown => 'Rétrograder';

  @override
  String get coachingEasePedal => 'Lever le pied';

  @override
  String get coachingVoiceHardAcceleration => 'Doucement sur l\'accélérateur';

  @override
  String get coachingVoiceHarshBraking =>
      'Essayez de freiner plus progressivement';

  @override
  String get coachingVoiceShiftUp =>
      'Passez la vitesse supérieure pour économiser du carburant';

  @override
  String get coachingVoiceShiftDown => 'Rétrogradez, le moteur peine';

  @override
  String get coachingVoiceEasePedal =>
      'Relâchez la pédale pour réduire votre consommation';

  @override
  String get coachingVoiceLiftOff => 'Levez le pied et laissez rouler';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Regardez plus loin et levez le pied plus tôt';

  @override
  String get coachingVoiceSmoothAccel => 'Accélérez plus progressivement';

  @override
  String get voiceCoachingSettingTitle => 'Coaching vocal de conduite';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Recevez des conseils vocaux en conduisant — accélération brusque, freinage fort et conseils de changement de vitesse';

  @override
  String get tooltipUseGps => 'Utiliser la position GPS';

  @override
  String get tooltipShowPassword => 'Afficher le mot de passe';

  @override
  String get tooltipHidePassword => 'Masquer le mot de passe';

  @override
  String get evConnectorsLabel => 'Connecteurs disponibles';

  @override
  String get evConnectorsNone => 'Aucune information sur les connecteurs';

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
  String get iosAutoRecordOnboardingTitle =>
      'Restez en dehors de l\'application — mais ne la fermez pas.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Ouvrez Sparkilo une fois après chaque redémarrage.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple ne réveille Sparkilo qu\'après que vous l\'avez ouverte au moins une fois depuis le redémarrage du téléphone. Ensuite, vos trajets s\'enregistrent automatiquement.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Ne balayez pas Sparkilo pour la fermer dans le sélecteur d\'applications.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '« Forcer à quitter » indique à iOS d\'arrêter de relancer l\'application. Vos trajets cesseront d\'être enregistrés jusqu\'à ce que vous rouvriez Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Quand iOS demande la localisation « Toujours », veuillez accepter.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'La solution de secours qui enregistre votre trajet lorsque l\'adaptateur OBD2 est lent a besoin de la localisation en arrière-plan. Nous ne la partageons jamais.';

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
    return 'Le fournisseur de données ($host) présente un certificat TLS expiré ou invalide. L\'application ne peut pas charger les données de cette source tant que le fournisseur ne l\'a pas corrigé. Veuillez contacter $host.';
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
  String get alertsLoadErrorTitle => 'Impossible de charger vos alertes';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Échec de la vérification des alertes en arrière-plan';

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
  String get syncSchemaOutdated =>
      'Your TankSync schema is outdated — re-run the setup SQL below to enable the latest synced features.';

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
  String get syncModeCommunityTitle => 'Communauté Sparkilo';

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
      'Les prix des carburants au Luxembourg sont réglementés par l\'État et uniformes dans tout le pays.';

  @override
  String get luxembourgFuelUnleaded95 => 'Sans plomb 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Sans plomb 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'GPL';

  @override
  String get luxembourgPricesUnavailable =>
      'Les prix réglementés du Luxembourg sont indisponibles.';

  @override
  String get reportIssueTitle => 'Signaler un problème';

  @override
  String get enterCorrection => 'Veuillez saisir la correction';

  @override
  String get reportNoBackendAvailable =>
      'Le signalement n\'a pas pu être envoyé : aucun service de signalement n\'est configuré pour ce pays. Activez TankSync dans les Paramètres pour envoyer des signalements communautaires.';

  @override
  String get correctName => 'Corriger le nom de la station';

  @override
  String get correctAddress => 'Corriger l\'adresse';

  @override
  String get wrongE85Price => 'Prix E85 incorrect';

  @override
  String get wrongE98Price => 'Prix Super 98 incorrect';

  @override
  String get wrongLpgPrice => 'Prix GPL incorrect';

  @override
  String get wrongStationName => 'Nom de station incorrect';

  @override
  String get wrongStationAddress => 'Adresse incorrecte';

  @override
  String get independentStation => 'Station indépendante';

  @override
  String get serviceRemindersSection => 'Rappels d\'entretien';

  @override
  String get serviceRemindersEmpty =>
      'Aucun rappel — choisissez un préréglage ci-dessus.';

  @override
  String get addServiceReminder => 'Ajouter un rappel';

  @override
  String get serviceReminderPresetOil => 'Vidange (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Vidange';

  @override
  String get serviceReminderPresetTires => 'Pneus (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Pneus';

  @override
  String get serviceReminderPresetInspection =>
      'Contrôle technique (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Contrôle technique';

  @override
  String get serviceReminderLabel => 'Libellé';

  @override
  String get serviceReminderInterval => 'Intervalle (km)';

  @override
  String get serviceReminderLastService => 'Dernier entretien';

  @override
  String get serviceReminderMarkDone => 'Marquer comme effectué';

  @override
  String get serviceReminderDueTitle => 'Entretien à effectuer';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label à effectuer — $kmOver km au-delà de l\'intervalle.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Inscrivez-vous sur OPINET pour obtenir une clé API gratuite';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Inscrivez-vous sur CNE pour obtenir une clé API gratuite';

  @override
  String get chileApiProvider => 'CNE Bencina en Línea';

  @override
  String get vinConfirmTitle => 'Est-ce votre voiture ?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders cyl., $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Informations partielles (hors ligne). Vous pouvez modifier ci-dessous.';

  @override
  String get vinDecodeError => 'Impossible de décoder ce VIN';

  @override
  String get vinInvalidFormat => 'Format VIN invalide';

  @override
  String get obd2PauseBannerTitle =>
      'Connexion OBD2 perdue — enregistrement en pause';

  @override
  String get obd2PauseBannerResume => 'Reprendre l\'enregistrement';

  @override
  String get obd2PauseBannerEnd => 'Terminer l\'enregistrement';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Enregistrement via GPS — reconnexion OBD2';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Recording with GPS — waiting for the OBD2 adapter';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Étalonnage de la consommation mis à jour pour $vehicleName — précision améliorée de $percent %';
  }

  @override
  String get veResetConfirmTitle => 'Réinitialiser le rendement volumétrique ?';

  @override
  String get veResetConfirmBody =>
      'Cela supprimera le rendement volumétrique appris (η_v) et restaurera la valeur par défaut (0,85). Les estimations de débit de carburant par trajet retomberont sur la constante du constructeur jusqu\'à ce que le calibrateur collecte de nouveaux échantillons lors des prochains trajets.';

  @override
  String get alertsStationSectionTitle => 'Alertes de stations';

  @override
  String get alertsStationAdd => 'Ajouter une alerte de station';

  @override
  String get alertsRadiusSectionTitle => 'Alertes de zone';

  @override
  String get alertsRadiusAdd => 'Ajouter une alerte de zone';

  @override
  String get alertsRadiusEmptyTitle => 'Aucune alerte de zone pour l\'instant';

  @override
  String get alertsRadiusEmptyCta => 'Créer une alerte de zone';

  @override
  String get alertsRadiusCreateTitle => 'Créer une alerte de zone';

  @override
  String get alertsRadiusLabelHint => 'Libellé (ex. Diesel maison)';

  @override
  String get alertsRadiusFuelType => 'Type de carburant';

  @override
  String get alertsRadiusThreshold => 'Seuil (€/L)';

  @override
  String get alertsRadiusKm => 'Rayon (km)';

  @override
  String get alertsRadiusCenterGps => 'Utiliser ma position';

  @override
  String get alertsRadiusCenterPostalCode => 'Code postal';

  @override
  String get alertsRadiusSave => 'Enregistrer';

  @override
  String get alertsRadiusCancel => 'Annuler';

  @override
  String get alertsRadiusDeleteConfirm => 'Supprimer l\'alerte de zone ?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Alerte de rayon « $name » supprimée';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 connecté : $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Associer un adaptateur OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel en baisse dans les stations à proximité';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stations ont baissé jusqu\'à $maxDropCents ¢ durant la dernière heure';
  }

  @override
  String get fillUpSavedSnackbar => 'Plein enregistré';

  @override
  String get radiusAlertsEntryTitle => 'Alertes de zone et statistiques';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Soyez averti quand les prix baissent près de chez vous';

  @override
  String get notFoundTitle => 'Page introuvable';

  @override
  String notFoundBody(String location) {
    return '« $location » introuvable.';
  }

  @override
  String get notFoundHomeButton => 'Accueil';

  @override
  String get consumptionTabHiddenNotice =>
      'L\'onglet Consommation a été masqué par les réglages de votre profil.';

  @override
  String get swipeBetweenTabsHint =>
      'Astuce : balayez vers la gauche ou la droite pour changer d\'onglet.';

  @override
  String get discardChangesTitle => 'Abandonner les modifications ?';

  @override
  String get discardChangesBody =>
      'Vous avez des modifications non enregistrées. Quitter maintenant les supprimera.';

  @override
  String get discardChangesConfirm => 'Abandonner';

  @override
  String get discardChangesKeepEditing => 'Continuer la modification';

  @override
  String get tankSyncSectionSubtitle =>
      'Synchronisation cloud entre vos appareils';

  @override
  String get mapUnavailable => 'Carte indisponible';

  @override
  String get routeNameHintExample => 'p. ex. Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Actuel';

  @override
  String get tankerkoenigApiKeyLabel => 'Clé API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Clé API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition =>
      'Appuyez pour mettre à jour la position GPS';

  @override
  String get nameLabel => 'Nom';

  @override
  String get obd2ErrorPermissionDenied =>
      'L\'autorisation Bluetooth est nécessaire pour se connecter à un adaptateur OBD2.';

  @override
  String get obd2ErrorBluetoothOff => 'Activez le Bluetooth et réessayez.';

  @override
  String get obd2ErrorScanTimeout =>
      'Aucun adaptateur OBD2 trouvé à proximité. Vérifiez qu\'il est branché et allumé.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'L\'adaptateur OBD2 n\'a pas répondu. Mettez le contact et réessayez.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'L\'adaptateur OBD2 a envoyé une réponse non reconnue. Il est peut-être incompatible — essayez un autre adaptateur.';

  @override
  String get obd2ErrorDisconnected =>
      'L\'adaptateur OBD2 s\'est déconnecté. Reconnectez-le et réessayez.';

  @override
  String get onboardingExploreDemoData => 'Explorer avec des données de démo';

  @override
  String get achievementSmoothDriver => 'Série souple';

  @override
  String get achievementSmoothDriverDesc =>
      'Enchaînez 5 trajets avec un score de conduite souple supérieur ou égal à 80.';

  @override
  String get achievementColdStartAware => 'Démarrage à froid maîtrisé';

  @override
  String get achievementColdStartAwareDesc =>
      'Maintenez le surcoût de démarrage à froid sous 2 % de la consommation totale du mois — regroupez les trajets courts.';

  @override
  String get achievementHighwayMaster => 'Maître de l\'autoroute';

  @override
  String get achievementHighwayMasterDesc =>
      'Réalisez un trajet de 30 km ou plus à vitesse constante avec un score de conduite souple supérieur ou égal à 90.';

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
    return '$price $currency (objectif : $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel en baisse dans les stations proches';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count stations en baisse jusqu\'à $cents¢ au cours de la dernière heure';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label : $count stations ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count autres';
  }

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Prix cible ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Seuil ($currency/L)';
  }

  @override
  String get approachOverlaySection => 'Overlay à l\'approche d\'une station';

  @override
  String get approachRadiusLabel => 'Rayon';

  @override
  String approachRadiusCaption(String km) {
    return 'L\'overlay s\'agrandit et affiche le prix lorsque vous êtes à moins de $km km d\'une station';
  }

  @override
  String get approachPriceModeLabel => 'Afficher le prix de';

  @override
  String get approachPriceModeNearest => 'Station la plus proche';

  @override
  String get approachPriceModeCheapestInRadius => 'Moins cher du rayon';

  @override
  String get approachMinPollLabel => 'Rafraîchissement min.';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Plancher de la fréquence d\'actualisation de la station la plus proche (plus rapide à vitesse élevée, jamais plus serré que $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Tester l\'overlay d\'approche';

  @override
  String get approachTestStopButton => 'Arrêter le test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test actif — l\'overlay affiche le prix pour $station';
  }

  @override
  String get approachTestUnavailable =>
      'Ajoutez une station favorite pour tester l\'overlay d\'approche';

  @override
  String approachStationDistance(String meters) {
    return 'à $meters m';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return 'À $km km';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximité $percent%';
  }

  @override
  String get pipTapToRestore => 'Tap to open the full app';

  @override
  String get authErrorNoNetwork =>
      'Pas de connexion réseau. Veuillez réessayer plus tard.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail ou mot de passe incorrect. Veuillez vérifier vos identifiants.';

  @override
  String get authErrorUserAlreadyExists =>
      'Cette adresse e-mail est déjà enregistrée. Essayez de vous connecter.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Veuillez ouvrir l\'e-mail de confirmation pour activer votre compte.';

  @override
  String get authErrorGeneric => 'Échec de la connexion. Veuillez réessayer.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Localisation en arrière-plan — uniquement pour l\'enregistrement automatique';

  @override
  String get autoRecordConsentExplanationTitle =>
      'À propos de cette autorisation';

  @override
  String get autoRecordConsentExplanationBody =>
      'L\'enregistrement automatique a besoin de la localisation en arrière-plan pour détecter quand vous montez en voiture, même lorsque l\'application est fermée. Cette autorisation ne sert qu\'à ça — la recherche de stations et le centrage de la carte utilisent une autorisation de localisation séparée (au premier plan).';

  @override
  String get autoRecordConsentExplanationCloseButton => 'J\'ai compris';

  @override
  String get autoRecordConsentExplanationTooltip =>
      'Qu\'est-ce que cela signifie ?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Appuyez pour gérer dans les paramètres système';

  @override
  String get autoRecordSectionTitle => 'Enregistrement automatique';

  @override
  String get autoRecordToggleLabel => 'Enregistrer les trajets automatiquement';

  @override
  String get autoRecordStatusActiveLabel =>
      'L\'enregistrement automatique démarrera la prochaine fois que vous monterez en voiture.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Associez un adaptateur OBD2 pour activer l\'enregistrement automatique.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Autorisez la localisation en arrière-plan pour que l\'enregistrement automatique continue lorsque l\'écran est éteint.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Associer un adaptateur';

  @override
  String get autoRecordSpeedThresholdLabel => 'Vitesse de démarrage (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Délai de sauvegarde après déconnexion (secondes)';

  @override
  String get autoRecordPairedAdapterLabel => 'Adaptateur appairé';

  @override
  String get autoRecordPairedAdapterNone =>
      'Aucun adaptateur appairé. Pairez via l\'onboarding OBD2 d\'abord.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Localisation en arrière-plan autorisée';

  @override
  String get autoRecordBackgroundLocationRequest => 'Demander la permission';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Pourquoi \"Toujours autoriser\" ?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'L\'enregistrement automatique capte les coordonnées GPS via le service OBD-II en arrière-plan, même quand l\'écran est éteint, pour que votre trajet reste précis. Android exige l\'option « Toujours autoriser » pour que cela continue de fonctionner une fois l\'appareil verrouillé.';

  @override
  String get autoRecordBackgroundLocationOpenSettings =>
      'Ouvrir les paramètres';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'L\'autorisation de localisation est requise';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Impossible de demander la localisation en arrière-plan';

  @override
  String get autoRecordBadgeClearTooltip => 'Effacer le compteur';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Associez un adaptateur dans la section ci-dessous pour activer l\'enregistrement automatique';

  @override
  String get exportBackupTooltip => 'Exporter la sauvegarde';

  @override
  String get exportBackupReady =>
      'Sauvegarde prête — choisissez une destination';

  @override
  String get exportBackupFailed =>
      'Échec de l\'exportation — veuillez réessayer';

  @override
  String get backupExportProgress => 'Exportation de votre sauvegarde…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Enregistré dans Téléchargements sous $fileName';
  }

  @override
  String get restoreBackupTooltip => 'Restaurer la sauvegarde';

  @override
  String get restoreBackupDialogTitle => 'Restaurer la sauvegarde';

  @override
  String get restoreBackupDialogBody =>
      'Fusionner ajoute et met à jour les enregistrements de la sauvegarde tout en conservant tout ce qui se trouve déjà sur cet appareil. Remplacer supprime d\'abord toutes les données actuelles, puis restaure uniquement la sauvegarde — cette action est irréversible.';

  @override
  String get restoreBackupMergeAction => 'Fusionner';

  @override
  String get restoreBackupReplaceAction => 'Tout remplacer';

  @override
  String restoreBackupSuccess(int count) {
    return 'Sauvegarde restaurée — $count enregistrements importés';
  }

  @override
  String get restoreBackupEmpty =>
      'Sauvegarde restaurée — elle ne contenait aucun enregistrement';

  @override
  String get restoreBackupCorrupt =>
      'Échec de la restauration — ce fichier n\'est pas une sauvegarde Tankstellen valide';

  @override
  String get restoreBackupFailed =>
      'Échec de la restauration — le fichier n\'a pas pu être lu';

  @override
  String get backupImportProgress => 'Restauration de votre sauvegarde…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Fusionné $vehicles véhicules, $fillUps pleins, $trips trajets, $chargingLogs journaux de charge';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Toutes les données remplacées par $vehicles véhicules, $fillUps pleins, $trips trajets, $chargingLogs journaux de charge';
  }

  @override
  String get brokenMapChipVerifying => 'Vérification du capteur MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Lectures MAP suspectes';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Le capteur MAP donne des valeurs incorrectes — la consommation affichée peut être 50 à 80 % trop basse. Essayez un autre adaptateur.';

  @override
  String get brokenMapBannerHardDisable =>
      'Capteur MAP non fiable. Affichage de la moyenne par plein au lieu du débit en direct.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Capteur MAP : vérifié ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Capteur MAP : en cours de vérification ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Capteur MAP : suspect ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Capteur MAP : $posterior % ± $margin %';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Capteur MAP : $posterior % ± $margin % (vérifié)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostic du capteur MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Confiance capteur MAP défectueux : $posterior % ± $margin %';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observations enregistrées';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Vérifié conforme';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Le capteur MAP de ce véhicule n\'a pas encore été observé.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Adaptateurs sur liste noire';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Aucun adaptateur sur liste noire.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — signalé $percent % défectueux';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Effacer';

  @override
  String get brokenMapRevPromptTitle => 'Faites monter le régime moteur';

  @override
  String get brokenMapRevPromptBody =>
      'Donnez un bref coup d\'accélérateur pour que l\'application vérifie que le capteur MAP réagit.';

  @override
  String get brokenMapRevPromptConfirm => 'Terminé – régime monté';

  @override
  String get calibrationAdvancedTitle => 'Calibrage avancé';

  @override
  String get calibrationDisplacementLabel => 'Cylindrée (cm³)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Rendement volumétrique (η_v)';

  @override
  String get calibrationAfrLabel => 'Rapport air/carburant (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Densité du carburant (g/L)';

  @override
  String get calibrationSourceDetected => '(détecté depuis le VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catalogue : $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(par défaut)';

  @override
  String get calibrationSourceManual => '(manuel)';

  @override
  String get calibrationResetToDetected => 'Restaurer la valeur détectée';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v : $eta (calibré, $samples pleins)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v : $eta (apprentissage, $samples pleins)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v : 0.85 (par défaut — aucun plein complet)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v : $eta · $samples échantillons';
  }

  @override
  String get calibrationResetLearner => 'Réinitialiser l\'apprentissage';

  @override
  String get calibrationBasisAtkinson => 'cycle Atkinson';

  @override
  String get calibrationBasisVnt => 'diesel à turbo VGT + injection directe';

  @override
  String get calibrationBasisTurboDi => 'turbo + injection directe';

  @override
  String get calibrationBasisTurbo => 'turbo';

  @override
  String get calibrationBasisNaDi => 'atmosphérique + injection directe';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catalogue : $makeModel — valeur par défaut pour $basis)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Votre $makeModel est marqué comme diesel mais correspond à une entrée essence du catalogue. Touchez pour mettre à jour.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Mettre à jour';

  @override
  String get consumptionTabFuel => 'Carburant';

  @override
  String get consumptionTabCharging => 'Recharge';

  @override
  String get noChargingLogsTitle =>
      'Aucune session de recharge pour l\'instant';

  @override
  String get noChargingLogsSubtitle =>
      'Enregistrez votre première session de recharge pour suivre les EUR/100 km et kWh/100 km.';

  @override
  String get addChargingLog => 'Enregistrer une recharge';

  @override
  String get addChargingLogTitle => 'Enregistrer une session de recharge';

  @override
  String get chargingKwh => 'Énergie (kWh)';

  @override
  String get chargingCost => 'Coût total';

  @override
  String get chargingTimeMin => 'Durée de recharge (min)';

  @override
  String get chargingStationName => 'Station (facultatif)';

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
      'Un enregistrement précédent est nécessaire pour comparer';

  @override
  String get chargingLogButtonLabel => 'Enregistrer une recharge';

  @override
  String get chargingCostTrendTitle => 'Tendance du coût de recharge';

  @override
  String get chargingEfficiencyTitle => 'Efficacité (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Pas encore assez de données';

  @override
  String get chargingChartsMonthAxis => 'Mois';

  @override
  String get consoFeatureGroupTitle => 'Conso';

  @override
  String get consoFeatureGroupDescription =>
      'Suivez votre consommation — pleins manuels ou enregistrement OBD2 automatique des trajets.';

  @override
  String get consoModeOff => 'Désactivé';

  @override
  String get consoModeFuel => 'Carburant';

  @override
  String get consoModeFuelAndTrips => 'Carburant + Trajets';

  @override
  String get consoModeOffDescription =>
      'Aucun onglet Conso ni section Conso dans les paramètres.';

  @override
  String get consoModeFuelDescription =>
      'Pleins manuels uniquement. Utile sans adaptateur OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Ajoute l\'enregistrement OBD2 automatique des trajets. Nécessite un adaptateur appairé.';

  @override
  String get consoGroupVehicles => 'Véhicules';

  @override
  String get consoGroupCoaching => 'Coaching pendant la conduite';

  @override
  String get consoGroupRewards => 'Récompenses et économies';

  @override
  String get consoGroupTroubleshooting => 'Dépannage';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Précision : $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Élevée';

  @override
  String get consumptionAccuracyMedium => 'Moyenne';

  @override
  String get consumptionAccuracyLow => 'Faible';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Calibrage complet : pleins plus trajets enregistrés en OBD2. La valeur en L/100 km correspond à la réalité à quelques pour cent près.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Les pleins ont ancré le modèle de consommation, mais aucun trajet OBD2 n\'a encore alimenté la boucle. Enregistrez-en un avec l\'OBD2 connecté pour atteindre une précision élevée.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'GPS uniquement — aucun plein n\'a encore ancré le modèle de consommation. Ajoutez quelques pleins complets pour améliorer la précision.';

  @override
  String get moreActionsTooltip => 'Plus';

  @override
  String get exportBackupMenuLabel => 'Exporter la sauvegarde';

  @override
  String get restoreBackupMenuLabel => 'Restaurer la sauvegarde';

  @override
  String get carbonDashboardMenuLabel => 'Tableau de bord carbone';

  @override
  String get settingsMenuLabel => 'Paramètres';

  @override
  String get consumptionStatsPageTitle => 'Statistiques de consommation';

  @override
  String get consumptionStatsComparisonTitle => 'Ce mois-ci vs le mois dernier';

  @override
  String get consumptionStatsTrendsTitle => 'Évolution dans le temps';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Enregistrez des pleins sur au moins deux mois pour comparer.';

  @override
  String get consumptionStatsPricePerLiter => 'Prix moy./L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litres par mois';

  @override
  String get consumptionStatsChartSpend => 'Dépenses par mois';

  @override
  String get consumptionStatsChartPricePerLiter => 'Prix par litre';

  @override
  String get consumptionStatsChartConsumption => 'L/100km par mois';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ravitaillements partiels en attente du plein complet — non inclus dans la moyenne',
      one:
          '1 ravitaillement partiel en attente du plein complet — non inclus dans la moyenne',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% du carburant provient d\'auto-corrections — vérifier les entrées';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections : +$liters L';
  }

  @override
  String get fillUpCorrectionLabel => 'Auto-correction — appuyez pour modifier';

  @override
  String get fillUpCorrectionEditTitle => 'Modifier l\'auto-correction';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Cette entrée a été générée automatiquement pour combler l\'écart entre les trajets enregistrés et le carburant pompé. Ajustez les valeurs si vous connaissez les chiffres réels.';

  @override
  String get fillUpCorrectionDelete => 'Supprimer la correction';

  @override
  String get fillUpCorrectionStation => 'Nom de la station (facultatif)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grèce)';

  @override
  String get greeceCommunityApiNotice =>
      'Propulsé par l\'API communautaire fuelpricesgr';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Roumanie)';

  @override
  String get romaniaScrapingNotice =>
      'Propulsé par pretcarburant.ro (Conseil de la concurrence + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stations en $country à $km km — €$price/L moins cher';
  }

  @override
  String get crossBorderTapToSwitch => 'Touchez pour changer de pays';

  @override
  String get crossBorderDismissTooltip => 'Ignorer';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Ouvrir la source de données $source ($license) dans votre navigateur';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© les contributeurs $brand';
  }

  @override
  String get developerToolsSectionTitle => 'Outils de développement';

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
      'Diagnostics et outils de débogage — visibles uniquement en mode développeur / débogage.';

  @override
  String get developerToolsMenuSubtitle =>
      'Journal d\'erreurs, alertes de test, diagnostics';

  @override
  String get developerToolsErrorLogGroupTitle => 'Journal d\'erreurs';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Enregistrer le journal d\'erreurs ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Effacer le journal d\'erreurs';

  @override
  String get developerToolsViewErrorLog => 'Afficher le journal d\'erreurs';

  @override
  String get developerToolsErrorLogEmpty =>
      'Aucune trace d\'erreur enregistrée.';

  @override
  String get developerToolsAlertsGroupTitle => 'Alertes et notifications';

  @override
  String get developerToolsFireTestNotification =>
      'Envoyer une notification de test';

  @override
  String get developerToolsTestNotificationTitle => 'Notification de test';

  @override
  String get developerToolsTestNotificationBody =>
      'Si vous pouvez lire ceci, les notifications fonctionnent.';

  @override
  String get developerToolsTestNotificationSent =>
      'Notification de test envoyée.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Les notifications sont bloquées — activez-les dans les réglages système, puis réessayez.';

  @override
  String get developerToolsRunTestAlert =>
      'Lancer le pipeline d\'alerte de test';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Alerte de test déclenchée — le pipeline a généré $count notification(s).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Alerte de prix de test';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Correspondance synthétique : une station sous votre cible a été trouvée à proximité.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Recherchez d\'abord des stations, puis lancez l\'alerte de test pour que la notification puisse ouvrir une station réelle.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostics';

  @override
  String get developerToolsFeatureFlagDump =>
      'Inspecteur de drapeaux de fonctionnalités';

  @override
  String get developerToolsFlagOn => 'Activé';

  @override
  String get developerToolsFlagOff => 'Désactivé';

  @override
  String get developerToolsClearCaches => 'Vider les caches';

  @override
  String get developerToolsCachesCleared => 'Caches vidés.';

  @override
  String get developerToolsCopyDiagnostics => 'Copier les diagnostics';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostics copiés dans le presse-papiers.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Infos de build';

  @override
  String get developerToolsBuildVersion => 'Version de l\'application';

  @override
  String get developerToolsBuildChannel => 'Canal de build';

  @override
  String get insightCardTitle => 'Principaux comportements gaspilleurs';

  @override
  String get insightEmptyState =>
      'Aucune inefficacité notable — continuez ainsi !';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Moteur au-dessus de 3000 tr/min ($pctTime % du trajet) : $liters L gaspillés';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count accélérations brusques : $liters L gaspillés';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Ralenti ($pctTime % du trajet) : $liters L gaspillés';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime % du trajet';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Sous-régime en rapport bas ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Coupez le moteur lors des arrêts prolongés au lieu de le laisser tourner au ralenti.';

  @override
  String get lessonAdviceHighRpm =>
      'Passez les rapports plus tôt pour garder le moteur hors de la plage de régime élevé.';

  @override
  String get lessonAdviceHardAccel =>
      'Accélérez en douceur : une accélération progressive consomme moins de carburant.';

  @override
  String get lessonAdviceLowGear =>
      'Passez la vitesse supérieure plus tôt pour que le moteur tourne à un régime plus bas et plus économique.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Vitesse élevée prolongée ($pctTime % du trajet) : $liters L gaspillés';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Vitesse élevée prolongée ($pctTime % du trajet)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Levez le pied au-dessus de 110 km/h : la résistance de l\'air augmente fortement, rouler un peu moins vite économise beaucoup de carburant.';

  @override
  String get lessonSmoothDrivingTitle => 'Conduite souple – bien joué !';

  @override
  String get lessonAdviceSmoothDriving =>
      'Aucune accélération ni freinage brusque sur ce trajet : une conduite régulière maintient une faible consommation.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Plein gaz ($pctTime% du trajet) : $liters L gaspillés';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Appuyez progressivement sur la pédale — un enfoncement en douceur à 70 % vous permet d\'atteindre la vitesse souhaitée avec bien moins de carburant.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Mélange riche en charge ($pctTime% du trajet) : $liters L gaspillés';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Une charge lourde et prolongée enrichit le mélange — passez les vitesses tôt et réduisez l\'accélération dans les longues montées pour maintenir un mélange pauvre.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Montée à $gradePercent% de pente ($pctTime% du trajet) : $liters L gaspillés';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Prenez de l\'élan avant la côte et appuyez progressivement sur l\'accélérateur — accélérer en montée brûle du carburant supplémentaire.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count redémarrages stop-and-go : $liters L gaspillés';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticipez le trafic et laissez rouler vers les arrêts pour éviter de redémarrer — repartir d\'un arrêt complet est la phase la plus gourmande du stop-and-go.';

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
  String get drivingScoreCardTitle => 'Score de conduite';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Score composite basé sur le ralenti, les accélérations brusques, les freinages brusques et le temps à haut régime. Une comparaison « meilleur que X % des trajets passés » arrivera dans une prochaine version.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Score de conduite $score sur 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Ralenti';

  @override
  String get drivingScorePenaltyHardAccel => 'Accélérations brusques';

  @override
  String get drivingScorePenaltyHardBrake => 'Freinages brusques';

  @override
  String get drivingScorePenaltyHighRpm => 'Régime élevé';

  @override
  String get drivingScorePenaltyFullThrottle => 'Pleins gaz';

  @override
  String get drivingScoreClassVeryGood => 'Très bien';

  @override
  String get drivingScoreClassGood => 'Bien';

  @override
  String get drivingScoreClassAverage => 'Moyen';

  @override
  String get drivingScoreClassBad => 'À améliorer';

  @override
  String get drivingScorePenaltyLugging => 'Moteur calant';

  @override
  String get drivingScorePenaltySmoothness => 'Conduite saccadée';

  @override
  String get drivingScorePenaltyHighSpeed => 'Vitesse élevée';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Pédale agressive';

  @override
  String get drivingScorePenaltyLambda => 'Mélange riche';

  @override
  String get gpsKpiCardTitle => 'Efficacité GPS';

  @override
  String get gpsKpiRpa => 'Accélération positive (RPA)';

  @override
  String get gpsKpiPke => 'Demande d\'énergie cinétique (PKE)';

  @override
  String get gpsKpiVapos => 'Intensité d\'accélération (VAPOS)';

  @override
  String get gpsKpiCoast => 'Part en roue libre';

  @override
  String get gpsKpiClimbEnergy => 'Énergie de montée';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct par rapport à votre référence efficace';
  }

  @override
  String get drivingTraceCardTitle => 'Trace d\'analyse de conduite (dev)';

  @override
  String get drivingTraceCardBody =>
      'Exportez les KPI GPS, le score et les leçons de ce trajet en JSON, écrivez comment la conduite s\'est vraiment passée dans le champ commentaire, et partagez-les pour calibrer les seuils de style de conduite sur des trajets réels.';

  @override
  String get drivingTraceExportAction => 'Exporter la trace d\'analyse';

  @override
  String get drivingTraceExported =>
      'Trace d\'analyse enregistrée dans Téléchargements — ajoutez votre verdict dans le champ commentaire et partagez-la.';

  @override
  String get drivingTraceExportFailed =>
      'Impossible d\'exporter la trace d\'analyse.';

  @override
  String get ecoRouteOption => 'Éco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L économisés';
  }

  @override
  String get ecoRouteHint =>
      'Conduite plus intelligente — privilégie l\'autoroute régulière aux raccourcis en zigzag.';

  @override
  String get favoritesShareAction => 'Partager';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favoris du $date';
  }

  @override
  String get favoritesShareError => 'Impossible de générer l\'image';

  @override
  String get featureManagementSectionTitle => 'Gestion des fonctionnalités';

  @override
  String get featureManagementSectionSubtitle =>
      'Activez ou désactivez chaque fonctionnalité. Certaines dépendent d\'autres — leurs interrupteurs restent désactivés tant que les prérequis ne sont pas remplis.';

  @override
  String get featureLabel_obd2TripRecording =>
      'Enregistrement OBD2 des trajets';

  @override
  String get featureDescription_obd2TripRecording =>
      'Enregistre les trajets automatiquement via OBD2.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification =>
      'Scores de conduite et badges gagnés.';

  @override
  String get featureLabel_hapticEcoCoach => 'Éco-coach haptique';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Retour haptique en temps réel pendant la conduite.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synchronisation multi-appareils via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analyse de consommation';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Onglet d\'analyse des pleins et des trajets.';

  @override
  String get featureLabel_baselineSync => 'Synchronisation des références';

  @override
  String get featureDescription_baselineSync =>
      'Synchronise les références de conduite via TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Résultats de recherche unifiés';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Une seule liste combinant stations carburant et bornes de recharge.';

  @override
  String get featureLabel_priceAlerts => 'Alertes de prix';

  @override
  String get featureDescription_priceAlerts =>
      'Notifications quand un prix passe sous un seuil.';

  @override
  String get featureLabel_priceHistory => 'Historique des prix';

  @override
  String get featureDescription_priceHistory =>
      'Graphiques des prix sur 30 jours dans le détail station.';

  @override
  String get featureLabel_routePlanning => 'Planification d\'itinéraire';

  @override
  String get featureDescription_routePlanning =>
      'Arrêt le moins cher sur votre trajet.';

  @override
  String get featureLabel_evCharging => 'Recharge VE';

  @override
  String get featureDescription_evCharging =>
      'Bornes de recharge via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Conseils d\'éco-conduite à partir des feux OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Trace GPS des trajets';

  @override
  String get featureDescription_gpsTripPath =>
      'Conserve les points GPS de chaque trajet.';

  @override
  String get featureLabel_autoRecord => 'Enregistrement automatique';

  @override
  String get featureDescription_autoRecord =>
      'Démarre automatiquement un trajet dès que l\'adaptateur OBD2 se connecte à un véhicule en mouvement.';

  @override
  String get featureLabel_showFuel => 'Afficher les stations-service';

  @override
  String get featureDescription_showFuel =>
      'Afficher les stations essence/diesel dans la recherche et sur la carte.';

  @override
  String get featureLabel_showElectric => 'Afficher les bornes de recharge';

  @override
  String get featureDescription_showElectric =>
      'Afficher les bornes de recharge dans la recherche et sur la carte.';

  @override
  String get featureLabel_showConsumptionTab => 'Onglet Consommation';

  @override
  String get featureDescription_showConsumptionTab =>
      'Afficher l\'onglet d\'analyse de consommation dans la barre de navigation.';

  @override
  String get featureBlockedEnable_gamification =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureBlockedEnable_baselineSync => 'Activez d\'abord TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureBlockedEnable_showFuel =>
      'Conditions préalables non remplies';

  @override
  String get featureBlockedEnable_showElectric =>
      'Conditions préalables non remplies';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureLabel_tflitePricePrediction => 'Prédiction de prix TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Modèle de prévision de prix sur l\'appareil — l\'inférence s\'exécute localement ; les caractéristiques et les prédictions ne quittent jamais l\'appareil.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Activez d\'abord l\'historique des prix';

  @override
  String get featureLabel_fuelCalculator => 'Calculateur de coût de carburant';

  @override
  String get featureDescription_fuelCalculator =>
      'Calculateur de coût de carburant accessible depuis les résultats de recherche.';

  @override
  String get featureLabel_carbonDashboard => 'Tableau de bord carbone';

  @override
  String get featureDescription_carbonDashboard =>
      'Tableau de bord de l\'empreinte CO2 accessible depuis l\'onglet Consommation.';

  @override
  String get featureLabel_experimentalOemPids => 'PID OEM expérimentaux';

  @override
  String get featureDescription_experimentalOemPids =>
      'Lire le niveau exact du réservoir en litres via des PID spécifiques au constructeur sur les adaptateurs compatibles.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Activez d\'abord l\'enregistrement OBD2 des trajets';

  @override
  String get featureLabel_paymentQrScan => 'Scanner le QR de paiement';

  @override
  String get featureDescription_paymentQrScan =>
      'Lecteur de QR code de paiement sur la page détail de la station.';

  @override
  String get featureLabel_communityPriceReports =>
      'Signalements de prix communautaires';

  @override
  String get featureDescription_communityPriceReports =>
      'Signaler le prix d\'une station depuis la page détail de la station.';

  @override
  String get featureLabel_obd2Optional =>
      'Exiger OBD2 pour l\'enregistrement des trajets';

  @override
  String get featureDescription_obd2Optional =>
      'Quand désactivé, l\'app enregistre des trajets uniquement GPS sans avoir besoin d\'un adaptateur OBD2. Le coaching est réduit — pas de L/100 km instantanée, moins de signaux moteur.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR de l\'écran ticket';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Scannez un ticket imprimé sur l\'écran Ajouter un plein pour pré-remplir la date, les litres, le total et la station.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'OCR de l\'écran de pompe (expérimental)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Scannez l\'afficheur d\'une pompe à carburant pour pré-remplir le formulaire. La reconnaissance n\'est pas fiable aujourd\'hui — activez uniquement si vous voulez tester.';

  @override
  String get featureLabel_developerPatToken =>
      'Retour développeur (PAT GitHub)';

  @override
  String get featureDescription_developerPatToken =>
      'Active le panneau de retour pour les scans en échec qui crée automatiquement des issues GitHub à partir d\'un Personal Access Token. Fonction pour utilisateurs avancés / contributeurs.';

  @override
  String get featureLabel_debugMode => 'Mode développeur / débogage';

  @override
  String get featureDescription_debugMode =>
      'Affiche une section Outils de développement dans les réglages avec des diagnostics : export du journal d\'erreurs, notifications de test, exécution du pipeline d\'alerte de test, inspection des drapeaux de fonctionnalités, vidage des caches et copie des diagnostics.';

  @override
  String get featureLabel_approachOverlay => 'Radar de stations-service';

  @override
  String get featureDescription_approachOverlay =>
      'Transforme la vignette de trajet flottante en un radar de stations-service en direct — à l\'approche d\'une station, elle bascule vers la couleur du carburant et affiche le prix.';

  @override
  String get featureLabel_voiceAnnouncements => 'Annonces vocales';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Annonce à voix haute les stations bon marché à proximité pendant que vous conduisez, pour garder les yeux sur la route.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Activez d\'abord la superposition d\'approche';

  @override
  String get featureGroupTitle_finding => 'Recherche et carte';

  @override
  String get featureGroupDescription_finding =>
      'Où faire le plein ou se recharger — recherche, carte, itinéraire.';

  @override
  String get featureGroupTitle_prices => 'Prix et alertes';

  @override
  String get featureGroupDescription_prices =>
      'Baisses de prix, historique et signalement.';

  @override
  String get featureGroupTitle_radar => 'Radar de stations-service';

  @override
  String get featureGroupDescription_radar =>
      'Suggestions de prix en direct pendant la conduite.';

  @override
  String get featureGroupTitle_sync => 'Synchronisation et sauvegarde';

  @override
  String get featureGroupDescription_sync =>
      'Gardez vos données sur tous vos appareils.';

  @override
  String get featureGroupTitle_input => 'Saisie et scan';

  @override
  String get featureGroupDescription_input =>
      'Outils pour enregistrer les pleins.';

  @override
  String get featureGroupTitle_developer => 'Développeur et expérimental';

  @override
  String get featureGroupDescription_developer =>
      'Outils pour utilisateurs avancés et contributeurs.';

  @override
  String get feedbackConsentTitle => 'Envoyer le rapport à GitHub ?';

  @override
  String get feedbackConsentBody =>
      'Cela crée un ticket public sur notre dépôt GitHub avec votre photo et le texte OCR. Aucune donnée personnelle (localisation, identifiant) n\'est envoyée. Continuer ?';

  @override
  String get feedbackConsentContinue => 'Continuer';

  @override
  String get feedbackConsentCancel => 'Annuler';

  @override
  String get feedbackConsentLater => 'Plus tard';

  @override
  String get feedbackTokenSectionTitle => 'Retour scan raté (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Pour créer automatiquement un ticket GitHub à partir d\'un scan raté, collez un token PAT GitHub (scope `public_repo` sur le dépôt tankstellen). Sinon, le partage manuel reste disponible.';

  @override
  String get feedbackTokenStatusSet => 'Token configuré';

  @override
  String get feedbackTokenStatusUnset => 'Pas de token';

  @override
  String get feedbackTokenSet => 'Définir';

  @override
  String get feedbackTokenClear => 'Effacer';

  @override
  String get feedbackTokenDialogTitle => 'Token GitHub (PAT)';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

  @override
  String get fillUpMultiFuelHint =>
      'Ce véhicule peut utiliser différents carburants — enregistrez celui que vous avez réellement mis';

  @override
  String get fillUpGuidanceTitle => 'Meilleur moment pour faire le plein';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Le prix actuel est parmi les moins chers des $days derniers jours — c\'est le bon moment pour faire le plein.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Les prix sont proches de leur maximum sur $days jours. Ils sont habituellement moins chers $window — envisagez d\'attendre.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Les prix sont en hausse — envisagez de faire le plein rapidement.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Le prix d\'aujourd\'hui est proche de la moyenne sur $days jours.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Économie possible d\'environ $amount/L en choisissant le bon moment.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basé sur $count relevés de prix',
      one: 'Basé sur 1 relevé de prix',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'le $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'en $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'à d\'autres moments';

  @override
  String get fillUpGuidanceWeekday1 => 'le lundi';

  @override
  String get fillUpGuidanceWeekday2 => 'le mardi';

  @override
  String get fillUpGuidanceWeekday3 => 'le mercredi';

  @override
  String get fillUpGuidanceWeekday4 => 'le jeudi';

  @override
  String get fillUpGuidanceWeekday5 => 'le vendredi';

  @override
  String get fillUpGuidanceWeekday6 => 'le samedi';

  @override
  String get fillUpGuidanceWeekday7 => 'le dimanche';

  @override
  String get fillUpGuidancePartEarlyMorning => 'tôt le matin';

  @override
  String get fillUpGuidancePartMorning => 'le matin';

  @override
  String get fillUpGuidancePartAfternoon => 'l\'après-midi';

  @override
  String get fillUpGuidancePartEvening => 'le soir';

  @override
  String get fillUpGuidancePartNight => 'la nuit';

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
      'Vérifié par l\'adaptateur';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Ne correspond pas à l\'adaptateur';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Votre saisie : $userL L. L\'adaptateur indique : $adapterL L (différence entre les niveaux de carburant avant et après). Utiliser la valeur de l\'adaptateur ?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Garder ma saisie';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Utiliser la valeur de l\'adaptateur';

  @override
  String get scanReceiptNoData => 'Aucune donnée de reçu trouvée — réessayez';

  @override
  String get scanReceiptSuccess =>
      'Reçu scanné — vérifiez les valeurs. Touchez « Signaler une erreur de scan » ci-dessous si quelque chose ne va pas.';

  @override
  String scanReceiptFailed(String error) {
    return 'Échec du scan : $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Affichage de la pompe illisible — réessayez';

  @override
  String get scanPumpSuccess =>
      'Affichage de la pompe scanné — vérifiez les valeurs.';

  @override
  String get scanPumpGlare =>
      'Trop de reflets sur l\'afficheur — réessayez en vous plaçant légèrement de biais pour que les chiffres ne soient pas surexposés.';

  @override
  String get scanPumpInconsistent =>
      'Les valeurs scannées ne concordent pas — veuillez les saisir manuellement.';

  @override
  String scanPumpFailed(String error) {
    return 'Échec du scan de la pompe : $error';
  }

  @override
  String get badScanReportTitle => 'Signaler une erreur de scan';

  @override
  String get badScanReportTitleReceipt => 'Signaler une erreur de scan — Reçu';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Signaler une erreur de scan — Display de pompe';

  @override
  String get pumpScanFailureTitle => 'Display illisible';

  @override
  String get pumpScanFailureBody =>
      'Le scan n\'a pas pu lire le display. Que voulez-vous faire ?';

  @override
  String get pumpScanFailureCorrectManually => 'Corriger manuellement';

  @override
  String get pumpScanFailureReport => 'Signaler';

  @override
  String get pumpScanFailureRemove => 'Retirer la photo';

  @override
  String get badScanReportHint =>
      'Nous partagerons la photo du reçu et les deux ensembles de valeurs pour que la prochaine version apprenne cette mise en page.';

  @override
  String get badScanReportShareAction => 'Partager le rapport + la photo';

  @override
  String get badScanReportFieldBrandLayout => 'Mise en page de la marque';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Prix/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Carburant';

  @override
  String get badScanReportFieldDate => 'Date';

  @override
  String get badScanReportHeaderField => 'Champ';

  @override
  String get badScanReportHeaderScanned => 'Scanné';

  @override
  String get badScanReportHeaderYouTyped => 'Vous avez saisi';

  @override
  String get badScanReportCreateTicket => 'Créer un ticket';

  @override
  String get badScanReportOpenInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get badScanReportFallbackToShare =>
      'Échec de création — partage manuel';

  @override
  String get pumpCameraHint =>
      'Alignez les trois chiffres de l\'afficheur de la pompe dans le cadre';

  @override
  String get pumpCameraCapture => 'Capturer';

  @override
  String get pumpCameraPermissionDenied =>
      'L\'accès à la caméra est nécessaire pour scanner l\'afficheur de la pompe. Activez-le dans les réglages de l\'appareil.';

  @override
  String get pumpCameraError =>
      'La caméra n\'a pas pu démarrer. Réessayez ou saisissez les valeurs manuellement.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Passer en affichage horizontal';

  @override
  String get pumpCameraOrientationVertical => 'Passer en affichage vertical';

  @override
  String get pumpCameraGlareWarning =>
      'Trop de reflets — inclinez légèrement pour éviter les éblouissements';

  @override
  String get pumpCameraAlignHint =>
      'Alignez l\'afficheur dans le cadre, puis capturez';

  @override
  String get pumpCameraRotateToLandscape =>
      'Tournez votre téléphone en mode paysage — l\'affichage de la pompe est large, les chiffres s\'affichent ainsi plus grands et droits';

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
  String get fillUpSectionWhatTitle => 'Votre plein';

  @override
  String get fillUpSectionWhatSubtitle => 'Carburant, quantité, prix';

  @override
  String get fillUpSectionWhereTitle => 'Où vous étiez';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, compteur, notes';

  @override
  String get fillUpImportFromLabel => 'Importer depuis…';

  @override
  String get fillUpImportSheetTitle => 'Importer les données du plein';

  @override
  String get fillUpImportReceiptLabel => 'Reçu';

  @override
  String get fillUpImportReceiptDescription =>
      'Scanner un reçu papier avec l\'appareil photo';

  @override
  String get fillUpImportPumpLabel => 'Affichage de la pompe';

  @override
  String get fillUpImportPumpDescription =>
      'Lire le montant / prix sur l\'écran LCD de la pompe';

  @override
  String get fillUpImportObdLabel => 'Adaptateur OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Lire le compteur kilométrique via le port OBD-II en Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Prix par litre';

  @override
  String get vehicleHeaderPlateLabel => 'Plaque';

  @override
  String get vehicleHeaderUntitled => 'Nouveau véhicule';

  @override
  String get vehicleSectionIdentityTitle => 'Identité';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nom et VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Motorisation';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Comment ce véhicule se déplace';

  @override
  String get profileSectionDisplayStations => 'Affichage et stations';

  @override
  String get profileSectionRegion => 'Région';

  @override
  String get fuelEfficiencyCardTitle => 'Coût au kilomètre par carburant';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Quel carburant revient réellement le moins cher à rouler';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Le moins cher au km : $fuel ($costPerKm)';
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
  String get fuelEfficiencyColCostPerKm => 'Coût/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Total dépensé';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pleins',
      one: '1 plein',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyMixedFootnote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pleins mixtes attribués à leur carburant principal',
      one: '1 plein mixte attribué à son carburant principal',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Enregistrez au moins deux pleins complets par carburant pour désigner le moins cher.';

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
  String get fuelNameE85 => 'E85 Bioéthanol';

  @override
  String get fuelNameLpg => 'GPL';

  @override
  String get fuelNameCng => 'GNV';

  @override
  String get fuelNameHydrogen => 'Hydrogène';

  @override
  String get fuelNameElectric => 'Électrique';

  @override
  String get calibrationModeLabel => 'Mode de calibration';

  @override
  String get calibrationModeRule => 'Basé sur les règles';

  @override
  String get calibrationModeFuzzy => 'Flou';

  @override
  String get calibrationModeTooltip =>
      'Le mode basé sur les règles attribue chaque échantillon de conduite à une seule situation. Le mode flou le répartit entre toutes en fonction de la pertinence de chacune — plus stable autour de 60 km/h ou en cas de variations de pente, mais plus lent à remplir toutes les catégories.';

  @override
  String get profileGamificationToggleTitle => 'Afficher les succès et scores';

  @override
  String get profileGamificationToggleSubtitle =>
      'Désactivé, les badges, scores et trophées sont masqués dans toute l\'app.';

  @override
  String get coachingGpsLiftOff => 'Lever le pied';

  @override
  String get coachingGpsAnticipateBrake => 'Anticiper';

  @override
  String get coachingGpsSmoothAccel => 'Accélération douce';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostic d\'échantillonnage GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps lacunes',
      one: '1 lacune',
      zero: 'aucune lacune',
    );
    return '$count échantillons · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Intervalle médian : $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Capturé pendant l\'enregistrement pour vérifier la cadence GPS en veille.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Plus grand intervalle : $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'En cours';

  @override
  String get gpsLifecyclePaused => 'En pause';

  @override
  String get gpsLifecycleInactive => 'Inactif';

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
  String get gpsMatrixMaturityCold => 'Froide';

  @override
  String get gpsMatrixMaturityWarming => 'En chauffe';

  @override
  String get gpsMatrixMaturityConverged => 'Convergée';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'La matrice GPS chauffe encore ($count affinements jusqu\'ici). Les estimations sont provisoires.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'La matrice GPS converge ($count pleins). Les estimations sont utilisables mais peuvent dériver de quelques %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'La matrice GPS a convergé ($count pleins). Les estimations sont à ~2 % de la consommation réelle.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'Estimation GPS (~) — pas de capteur de carburant sur ce trajet. La valeur est modélisée à partir de la vitesse et de l\'étalonnage de votre véhicule ; la précision s\'améliore à mesure que la matrice évolue.';

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
  String get hapticEcoCoachSectionTitle => 'Conduite';

  @override
  String get hapticEcoCoachSettingTitle => 'Coaching éco en temps réel';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Vibration légère + conseil à l\'écran quand vous accélérez fort en vitesse de croisière';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Doucement sur l\'accélérateur — la roue libre économise plus';

  @override
  String semanticsNavigateTo(String name) {
    return 'Naviguer vers $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Retirer $name des favoris';
  }

  @override
  String get showOnMapSemanticLabel => 'Afficher les stations sur la carte';

  @override
  String get searchResultsSemanticLabel => 'Résultats de recherche';

  @override
  String get searchCriteriaSemanticLabel =>
      'Résumé des critères de recherche. Appuyez pour modifier.';

  @override
  String get noFavoritesSemanticLabel =>
      'Aucun favori pour l\'instant. Appuyez sur l\'étoile d\'une station pour l\'enregistrer en favori.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'La station est ouverte',
      'false': 'La station est fermée',
      'other': 'La station est fermée',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Pays $name, sélectionné',
      'false': 'Pays $name',
      'other': 'Pays $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Langue $name, sélectionné',
      'false': 'Langue $name',
      'other': 'Langue $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Trier par $option, sélectionné',
      'false': 'Trier par $option',
      'other': 'Trier par $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Carburant $type, sélectionné',
      'false': 'Carburant $type',
      'other': 'Carburant $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Borne de recharge $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Bouclier de confidentialité avec goutte de carburant';

  @override
  String get globeIllustrationSemantic =>
      'Globe avec marqueurs de stations-service';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Pompe à carburant avec ticker de prix';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, source de données : $provider, $keyRequirement, types de carburant : $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Clé API requise';

  @override
  String get countryInfoNoKeyNeeded => 'Gratuit, aucune clé nécessaire';

  @override
  String countryInfoDataSource(String provider) {
    return 'Données : $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Types de carburant : $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Démo';

  @override
  String get anonKeyLabel => 'Clé Anon';

  @override
  String get anonKeyHideTooltip => 'Masquer la clé';

  @override
  String get anonKeyShowTooltip => 'Afficher la clé pour vérifier';

  @override
  String anonKeyTooLong(int length) {
    return 'La clé est trop longue ($length car.) — vérifiez les caractères en trop';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'La clé semble correcte ($length car.)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'La clé doit être un JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'La clé est peut-être tronquée ($length sur ~208 car. attendus)';
  }

  @override
  String get anonKeyExceedsMax => 'La clé dépasse la longueur maximale';

  @override
  String get qrShareTitle => 'Partager votre base de données';

  @override
  String get qrShareSubtitle =>
      'Les autres peuvent scanner ce QR code pour se connecter';

  @override
  String get qrShareCopyAsText => 'Copier comme texte';

  @override
  String get authInfoTitle => 'Pourquoi créer un compte ?';

  @override
  String get authInfoBenefit1 =>
      '• Synchronisez favoris, alertes et itinéraires entre vos appareils';

  @override
  String get authInfoBenefit2 =>
      '• Préparez un itinéraire sur votre téléphone, utilisez-le en voiture';

  @override
  String get authInfoBenefit3 =>
      '• Aucune donnée n\'est partagée avec des tiers';

  @override
  String get authInfoBenefit4 =>
      '• Vous pouvez supprimer votre compte à tout moment';

  @override
  String get privacyLocalDataEmpty =>
      'Rien d\'enregistré pour l\'instant. Ajoutez un favori ou créez une alerte prix pour voir apparaître des entrées.';

  @override
  String get privacyHideEmptyRows => 'Masquer les lignes vides';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count lignes vides',
      one: 'Afficher $count ligne vide',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Configuration de la clé API (optionnel)';

  @override
  String get apiKeySetupDescription =>
      'Inscrivez-vous pour obtenir une clé API gratuite, ou passez pour explorer l\'application avec des données de démonstration.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Inscription $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'En saisissant une clé API, vous acceptez les conditions de $provider. La redistribution des données est interdite.';
  }

  @override
  String get calculatorDistanceHint => 'ex. 150';

  @override
  String get calculatorConsumptionHint => 'ex. 7,0';

  @override
  String get calculatorPriceHint => 'ex. 1,899';

  @override
  String get routeStrategyLabel => 'Stratégie :';

  @override
  String get routeStrategyUniform => 'Uniforme';

  @override
  String get routeStrategyBalanced => 'Équilibrée';

  @override
  String get glideCoachBetaTitle => 'Glide-coach bêta (expérimental)';

  @override
  String get glideCoachBetaSubtitle =>
      'Légère vibration au ralentissement avant un feu rouge. Désactivé par défaut — risque de distraction.';

  @override
  String get consentSyncTripsTitle => 'Synchroniser les trajets enregistrés';

  @override
  String get consentSyncTripsSubtitle =>
      'Sauvegardez les trajets OBD2 + GPS dans TankSync. Multi-appareil, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Activez Cloud Sync ci-dessus pour sauvegarder les trajets.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Connecte-toi avec un compte e-mail pour synchroniser les trajets entre appareils.';

  @override
  String get consentHideDetails => 'Masquer les détails';

  @override
  String get consentShowDetails => 'Afficher les détails';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Lien invalide';

  @override
  String invalidLinkBody(String path) {
    return 'Le lien « $path » n\'est pas valide.';
  }

  @override
  String get home => 'Accueil';

  @override
  String get accelBrakeCardTitle => 'Accélération et freinage';

  @override
  String get accelBrakeHardAccel => 'Accélérations brusques';

  @override
  String get accelBrakeHardBrake => 'Freinages brusques';

  @override
  String get accelBrakeSharpCorner => 'Virages serrés';

  @override
  String get accelBrakeSource =>
      'D\'après les capteurs de mouvement du téléphone';

  @override
  String lessonHardBrake(String count) {
    return '$count freinages brusques';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Anticipez les arrêts et levez le pied plus tôt — freiner brusquement gaspille le carburant dépensé pour atteindre la vitesse.';

  @override
  String lessonSharpCornering(String count) {
    return '$count virages serrés';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Ralentissez avant le virage, pas dans le virage — virer fort fait perdre de la vitesse qu\'il faudra ensuite regagner.';

  @override
  String get locationConsentTitle => 'Accès à la localisation';

  @override
  String get locationConsentSubtitle =>
      'Cette application souhaite utiliser votre position pour trouver les stations-service près de chez vous.';

  @override
  String get locationConsentWhatHappens =>
      'Ce qui se passe avec vos données de localisation :';

  @override
  String get locationConsentBulletApi =>
      'Vos coordonnées sont envoyées à l\'API de prix des carburants pour trouver les stations proches.';

  @override
  String get locationConsentBulletNoServer =>
      'Votre position n\'est stockée sur aucun serveur — il n\'y a pas de serveur.';

  @override
  String get locationConsentBulletNoTracking =>
      'Les données de localisation ne sont pas utilisées pour la publicité, l\'analyse ou le suivi.';

  @override
  String get locationConsentRevoke =>
      'Vous pouvez révoquer l\'accès à la localisation à tout moment dans les paramètres système. Vous pouvez aussi rechercher par code postal.';

  @override
  String get locationConsentLegalBasis =>
      'Base juridique : art. 6, §1, a) du RGPD (consentement)';

  @override
  String get locationConsentDecline => 'Refuser';

  @override
  String get locationConsentAccept => 'Accepter';

  @override
  String get loyaltySettingsTitle => 'Mes cartes de fidélité';

  @override
  String get loyaltySettingsSubtitle =>
      'Appliquer votre remise fidélité aux prix affichés';

  @override
  String get loyaltyMenuTitle => 'Cartes de fidélité';

  @override
  String get loyaltyMenuSubtitle => 'Remises par litre Total, Aral, Shell…';

  @override
  String get loyaltyAddCard => 'Ajouter une carte';

  @override
  String get loyaltyAddCardSheetTitle => 'Ajouter une carte de fidélité';

  @override
  String get loyaltyBrandLabel => 'Enseigne';

  @override
  String get loyaltyCardLabelLabel => 'Libellé (facultatif)';

  @override
  String get loyaltyDiscountLabel => 'Remise (par litre)';

  @override
  String get loyaltyDiscountInvalid => 'Saisissez un nombre positif';

  @override
  String get loyaltyDeleteConfirmTitle => 'Supprimer la carte ?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Cette carte n\'appliquera plus sa remise.';

  @override
  String get loyaltyEmptyTitle => 'Aucune carte de fidélité';

  @override
  String get loyaltyEmptyBody =>
      'Ajoutez une carte pour appliquer automatiquement votre remise par litre aux stations correspondantes.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Dérive du régime de ralenti détectée';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Le régime de ralenti a augmenté de $percent % sur vos $tripCount derniers trajets. Signe possible précoce d\'un filtre à air encrassé ou d\'une dérive de capteur.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Restriction d\'admission possible';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Le débit de carburant en croisière a baissé de $percent % sur vos $tripCount derniers trajets. Signe possible d\'un filtre à air encrassé ou d\'une admission restreinte — un contrôle est conseillé.';
  }

  @override
  String get maintenanceActionDismiss => 'Ignorer';

  @override
  String get maintenanceActionSnooze => 'Reporter de 30 jours';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Ce mois-ci vs. le mois dernier';

  @override
  String get consumptionMonthlyTripsLabel => 'Trajets';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Temps de conduite';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distance';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Conso. moyenne';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Au moins 3 trajets par mois sont nécessaires pour la comparaison';

  @override
  String get consumptionMonthlyClimbLabel => 'Dénivelé';

  @override
  String get obd2CapabilitySectionTitle => 'Capacités de l\'adaptateur';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'PID constructeur';

  @override
  String get obd2CapabilityFullCan => 'Accès CAN complet';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Pour un volume exact de carburant en litres sur Peugeot/Citroën, l\'application prend en charge OBDLink MX+/LX/CX (puce STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Superposition de diagnostic OBD2 activée';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Superposition de diagnostic OBD2 désactivée';

  @override
  String get obd2DebugOverlayClearButton => 'Effacer';

  @override
  String get obd2DebugOverlayCloseButton => 'Fermer';

  @override
  String get obd2DebugOverlayTitle => 'Traces OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Partager le journal de diagnostic';

  @override
  String get obd2DebugLoggingTitle => 'Journalisation de débogage OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Enregistrez chaque session OBD2 — connexion, handshake, pertes de données et reconnexions — dans un journal XML exportable. Désactivé par défaut.';

  @override
  String get obd2DebugSessionShareLabel =>
      'Partager le journal de session OBD2';

  @override
  String get obd2DiagnosticsTitle => 'Santé de la communication OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops coupures',
      one: '1 coupure',
      zero: 'aucune coupure',
    );
    return '$percent% complet · $duty% utilisation · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adaptateur';

  @override
  String get obd2DiagnosticsConnectionSection => 'Cycle de vie de la connexion';

  @override
  String get obd2DiagnosticsPidSection => 'Résultats par PID';

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
  String get obd2DiagnosticsSchedulerSection => 'Santé du planificateur';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Complétude';

  @override
  String get obd2DiagnosticsSupportSection => 'PIDs détectés comme supportés';

  @override
  String get obd2DiagnosticsFuelSection => 'Récapitulatif niveau carburant';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protocole $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts tentatives · $successes réussies · $drops coupures · temps de connexion p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Reconnexions : $silent silencieuses · $visible visibles';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz cadence · $skips sauts de contre-pression · $demotions rétrogradations';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Niveau Dynamique en manque — RPM / vitesse inférieurs au seuil du régulateur.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Global $percent% · utilisation active $duty%';
  }

  @override
  String obd2DiagnosticsTierLine(String tier, String percent) {
    return '$tier : $percent%';
  }

  @override
  String obd2DiagnosticsSupportLine(
    int supported,
    int unsupported,
    int unknown,
  ) {
    return '$supported supportés · $unsupported non supportés · $unknown inconnus';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return '$suspicious échantillons suspects sur $total';
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
    return '$pid : $polled interrogés · $ok ok · $noData ND · $timeout TO · $error err · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection =>
      'Transcription d\'initialisation du dongle';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protocole $protocol · $start · firmware $firmware · $tier · $pids PIDs';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'chaud';

  @override
  String get obd2DiagnosticsInitCold => 'froid';

  @override
  String get obd2HealthCopyInitTranscript =>
      'Copier uniquement la transcription d\'initialisation';

  @override
  String get obd2DiagnosticsEmpty =>
      'Aucune session OBD2 enregistrée — connectez un adaptateur et enregistrez un trajet avec le mode développeur activé.';

  @override
  String get obd2DiagnosticsExplain =>
      'Capturé pendant l\'enregistrement pour déboguer la communication dongle↔application — collecté uniquement en mode Développeur.';

  @override
  String get obd2HealthScreenTitle => 'Santé de la communication OBD2';

  @override
  String get obd2HealthNavLabel => 'Santé de la communication OBD2';

  @override
  String get obd2HealthLiveSection => 'Session en cours';

  @override
  String get obd2HealthHistorySection => 'Sessions récentes';

  @override
  String get obd2HealthCopyJson => 'Copier en JSON';

  @override
  String get obd2HealthCopied =>
      'Diagnostics OBD2 copiés dans le presse-papiers.';

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
  String get obd2TestRunTitle => 'Lancer le test de l\'adaptateur';

  @override
  String get obd2TestRunButton => 'Lancer le test de l\'adaptateur';

  @override
  String get obd2TestRunPassed => 'Test de l\'adaptateur réussi';

  @override
  String get obd2TestRunFailed => 'Test de l\'adaptateur échoué';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed sur $total étapes OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Arrêtez l\'enregistrement en cours avant de lancer le test de l\'adaptateur.';

  @override
  String get obd2TestStepScan => 'Rechercher l\'adaptateur';

  @override
  String get obd2TestStepConnect => 'Connexion et initialisation';

  @override
  String get obd2TestStepInfo => 'Informations sur l\'adaptateur';

  @override
  String get obd2TestStepSupportedPids => 'PIDs supportés';

  @override
  String get obd2TestStepSampleReads => 'Lectures d\'échantillon';

  @override
  String get obd2TestStepReconnect => 'Test de reconnexion';

  @override
  String get obd2TestStepDisconnect => 'Déconnexion';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Délai dépassé';

  @override
  String get obd2TestStatusGarbage => 'Réponse illisible';

  @override
  String get obd2TestStatusNoResponse => 'Aucune réponse';

  @override
  String get obd2TestStatusFail => 'Échec';

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
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Impossible de joindre \'$adapterName\' — choisissez un autre adaptateur';
  }

  @override
  String get ocrTesterTitle => 'Testeur OCR';

  @override
  String get ocrTesterNavLabel => 'Testeur OCR';

  @override
  String get ocrTesterExplain =>
      'Exécutez le pipeline OCR pompe/ticket sur une photo choisie et inspectez chaque étape — disponible uniquement en mode Développeur.';

  @override
  String get ocrTesterModePump => 'Pompe';

  @override
  String get ocrTesterModeReceipt => 'Ticket';

  @override
  String get ocrTesterCapture => 'Capturer';

  @override
  String get ocrTesterPickImage => 'Choisir une image';

  @override
  String get ocrTesterRun => 'Exécuter';

  @override
  String get ocrTesterCountry => 'Pays';

  @override
  String get ocrTesterCountryNone => 'Par défaut (sans profil)';

  @override
  String get ocrTesterNoImage =>
      'Choisissez ou capturez une image, puis appuyez sur Exécuter.';

  @override
  String get ocrTesterRunning => 'OCR en cours…';

  @override
  String get ocrTesterNoResult => 'L\'OCR n\'a produit aucun résultat lisible.';

  @override
  String get ocrTesterOverlaySection => 'Superposition de blocs';

  @override
  String get ocrTesterStepsSection => 'Étapes du pipeline';

  @override
  String get ocrTesterLegendLabel => 'Étiquette';

  @override
  String get ocrTesterLegendNumeric => 'Numérique';

  @override
  String get ocrTesterLegendNoise => 'Bruit';

  @override
  String get ocrTesterLegendDerived => 'Dérivé';

  @override
  String get ocrTesterStageGlare => 'Capture / reflet';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Classifier';

  @override
  String get ocrTesterStageAssemble => 'Assembler';

  @override
  String get ocrTesterStageAnchor => 'Ancrer';

  @override
  String get ocrTesterStageFallback => 'Repli';

  @override
  String get ocrTesterStageCrossCheck => 'Vérification croisée';

  @override
  String get ocrTesterStageConfidence => 'Confiance';

  @override
  String get ocrTesterStageGate => 'Filtre';

  @override
  String get ocrTesterStageBrand => 'Marque';

  @override
  String get ocrTesterStageOverrides => 'Remplacements';

  @override
  String get ocrTesterStageReconcile => 'Réconcilier';

  @override
  String get ocrTesterStageResult => 'Résultat';

  @override
  String get ocrTesterChipRead => 'LU';

  @override
  String get ocrTesterChipDerived => 'DÉRIVÉ';

  @override
  String get ocrTesterGateAccepted => 'Accepté';

  @override
  String get ocrTesterGateRejected => 'Rejeté';

  @override
  String get ocrTesterFallbackBanner =>
      'Un champ a été récupéré via le repli de magnitude — veuillez le vérifier.';

  @override
  String get ocrTesterStageNoData => 'L\'étape n\'a pas été exécutée.';

  @override
  String get ocrTesterCopyJson => 'Copier en JSON';

  @override
  String get ocrTesterExportPackage => 'Exporter le paquet';

  @override
  String get ocrTesterCopied => 'Trace OCR copiée dans le presse-papiers.';

  @override
  String get ocrTesterExported =>
      'Paquet OCR enregistré dans votre dossier Téléchargements.';

  @override
  String get ocrTesterSaveFixture => 'Enregistrer comme fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture enregistrée dans votre dossier Téléchargements. Déplacez-la sous test/fixtures et exécutez tool/promote_ocr_fixture.dart.';

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
  String get onboardingPickUseMode =>
      'Choisissez un mode d\'utilisation pour continuer.';

  @override
  String get openNow => 'Ouvert';

  @override
  String get openNowClosed => 'Fermé';

  @override
  String get openHoursUnknown => 'Horaires inconnus';

  @override
  String closesAt(String time) {
    return 'Ferme à $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Ouvre $day à $time';
  }

  @override
  String opensToday(String time) {
    return 'Ouvre à $time';
  }

  @override
  String get open24Hours => 'Ouvert 24h/24';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => 'Automatiser 24h/24 7j/7';

  @override
  String get dayMon => 'Lundi';

  @override
  String get dayTue => 'Mardi';

  @override
  String get dayWed => 'Mercredi';

  @override
  String get dayThu => 'Jeudi';

  @override
  String get dayFri => 'Vendredi';

  @override
  String get daySat => 'Samedi';

  @override
  String get daySun => 'Dimanche';

  @override
  String get dayShortMon => 'Lun';

  @override
  String get dayShortTue => 'Mar';

  @override
  String get dayShortWed => 'Mer';

  @override
  String get dayShortThu => 'Jeu';

  @override
  String get dayShortFri => 'Ven';

  @override
  String get dayShortSat => 'Sam';

  @override
  String get dayShortSun => 'Dim';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Jours fériés';

  @override
  String get closedLabel => 'Fermé';

  @override
  String get openingHoursNotAvailable =>
      'Horaires d\'ouverture non disponibles';

  @override
  String get showAllHours => 'Afficher tous les horaires';

  @override
  String get showLessHours => 'Afficher moins';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Valeur estimée (~) — pas de capteur de carburant sur ce trajet, la consommation en L/100 km est donc modélisée à partir de la vitesse GPS et de l\'étalonnage de votre véhicule. C\'est une approximation (typiquement ±10–30 %, qui s\'affine au fil de l\'étalonnage), pas une mesure directe.';

  @override
  String get tripRecordingPipElapsedCaption => 'écoulé';

  @override
  String get radarPinHelpTitle => 'À propos de l\'épingle';

  @override
  String get radarPinHelpBody =>
      'L\'épingle maintient l\'écran allumé et masque les barres système pour que l\'affichage de la station la plus proche reste lisible sur un support tableau de bord. Appuyez à nouveau pour désépingler. Se libère automatiquement à l\'arrêt du radar.';

  @override
  String get radarAutoPinTitle => 'Toujours épingler au démarrage du radar';

  @override
  String get radarAutoPinSubtitle =>
      'Épingler le radar automatiquement à chaque fois au lieu d\'appuyer à chaque fois. Consomme plus de batterie.';

  @override
  String get alertsRadiusFrequencyLabel => 'Fréquence de vérification';

  @override
  String get alertsRadiusFrequencyDaily => 'Une fois par jour';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Deux fois par jour';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Trois fois par jour';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Quatre fois par jour';

  @override
  String get radiusAlertPickOnMap => 'Choisir sur la carte';

  @override
  String get radiusAlertMapPickerTitle => 'Choisir le centre de l\'alerte';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirmer';

  @override
  String get radiusAlertMapPickerCancel => 'Annuler';

  @override
  String get radiusAlertMapPickerHint =>
      'Déplacez la carte pour positionner le centre de l\'alerte';

  @override
  String get radiusAlertCenterFromMap => 'Position sur la carte';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel près de $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Une station est à $price € (cible : $threshold €)';
  }

  @override
  String get reconcileWorkflowTitle => 'Réconcilier votre carburant';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Nous avons trouvé un écart de $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Vous avez pompé $pumped L, mais vos trajets enregistrés ne représentent que $consumed L. Il reste $gap L inexpliqués.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Cela signifie généralement qu\'un trajet n\'a pas été enregistré (l\'adaptateur était débranché ou l\'application était fermée), ou qu\'un plein est manquant ou mal saisi.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Tant que ce n\'est pas résolu, votre total de carburant et votre total de trajets ne correspondront pas.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Aidez-nous à attribuer l\'écart';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Tous vos pleins pour ce réservoir sont-ils complets et corrects ?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Tous vos trajets sont-ils enregistrés ?';

  @override
  String get reconcileWorkflowAnswerYes => 'Oui';

  @override
  String get reconcileWorkflowAnswerNo => 'Non';

  @override
  String get reconcileWorkflowPathAHint =>
      'Un plein est manquant ou incorrect — nous ajouterons une correction pour que vos pleins correspondent.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Vos pleins sont corrects et un trajet n\'a pas été enregistré — nous ajouterons un trajet virtuel pour la distance manquante.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Litres de correction';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Quelle distance faisait le trajet non enregistré ? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Décider plus tard';

  @override
  String get reconcileWorkflowBack => 'Retour';

  @override
  String get reconcileWorkflowNext => 'Suivant';

  @override
  String get reconcileWorkflowApply => 'Appliquer';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Trajet virtuel — appuyer pour modifier';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Modifier le trajet virtuel';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Ce trajet a été ajouté pour tenir compte du carburant consommé lors d\'un trajet non enregistré. Ajustez la distance ou le carburant, ou supprimez-le.';

  @override
  String get reconcileVirtualTrajetDelete => 'Supprimer le trajet virtuel';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Écart carburant/trajet non résolu de $gap L — appuyer pour résoudre';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Résoudre l\'écart non résolu entre carburant et trajets';

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/séance';

  @override
  String get shareReceiptImporting => 'Importation du ticket partagé…';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Ce type de fichier ne peut pas encore être importé — partagez plutôt une photo du ticket.';

  @override
  String get shareReceiptFailed =>
      'Impossible de lire le ticket partagé — réessayez de le partager ou ajoutez le plein manuellement.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Partager un ticket pour l\'importer';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Partagez une photo de ticket depuis une autre application pour pré-remplir un plein — date, litres, total et station sont lus sur l\'appareil.';

  @override
  String get speedConsumptionCardTitle => 'Consommation par vitesse';

  @override
  String get speedBandIdleJam => 'Ralenti / embouteillage';

  @override
  String get speedBandUrban => 'Urbain (10–50)';

  @override
  String get speedBandSuburban => 'Périurbain (50–80)';

  @override
  String get speedBandRural => 'Route (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-vitesse (100–115)';

  @override
  String get speedBandMotorway => 'Autoroute (115–130)';

  @override
  String get speedBandMotorwayFast => 'Autoroute rapide (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Enregistrez plus de 30 minutes de trajets avec l\'adaptateur OBD2 pour débloquer l\'analyse vitesse/consommation.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % de conduite';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Plus de données nécessaires';

  @override
  String get splashLoadingLabel => 'Chargement de Sparkilo';

  @override
  String get storageRecoveryTitle => 'Problème de stockage';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo n\'a pas pu ouvrir son stockage de données local. Le fichier de stockage semble endommagé.';

  @override
  String get storageRecoveryGuidance =>
      'Pour récupérer, videz le stockage de l\'application dans les réglages de l\'appareil ou réinstallez l\'application. Vos favoris et votre historique sont enregistrés uniquement sur cet appareil et ne peuvent pas être restaurés automatiquement.';

  @override
  String get tankLevelTitle => 'Niveau du réservoir';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km d\'autonomie';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Dernier plein : $date · $count trajet(s) depuis';
  }

  @override
  String get tankLevelMethodObd2 => 'mesuré par OBD2';

  @override
  String get tankLevelMethodDistanceFallback =>
      'estimation basée sur la distance';

  @override
  String get tankLevelMethodMixed => 'mesure mixte';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Enregistrez un plein pour voir le niveau du réservoir';

  @override
  String get tankLevelDetailSheetTitle => 'Trajets depuis le dernier plein';

  @override
  String get addFillUpIsFullTankLabel => 'Plein complet';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Réservoir rempli à ras bord — décochez s\'il s\'agissait d\'un plein partiel';

  @override
  String get themeCardTitle => 'Thème';

  @override
  String get themeCardSubtitleSystem => 'Système';

  @override
  String get themeCardSubtitleLight => 'Clair';

  @override
  String get themeCardSubtitleDark => 'Sombre';

  @override
  String get themeSettingsScreenTitle => 'Thème';

  @override
  String get themeSettingsSystemLabel => 'Suivre le système';

  @override
  String get themeSettingsLightLabel => 'Clair';

  @override
  String get themeSettingsDarkLabel => 'Sombre';

  @override
  String get themeSettingsSystemDescription =>
      'Utilise l\'apparence actuelle de l\'appareil.';

  @override
  String get themeSettingsLightDescription =>
      'Arrière-plans clairs — idéal en journée.';

  @override
  String get themeSettingsDarkDescription =>
      'Arrière-plans sombres — plus doux pour les yeux la nuit et économe en batterie sur les écrans OLED.';

  @override
  String get themeSettingsEcoLabel => 'Éco';

  @override
  String get themeSettingsEcoDescription =>
      'Le look vert emblématique de l\'application — clair et facile à lire, avec des arrière-plans légèrement teintés de vert.';

  @override
  String get throttleRpmHistogramTitle =>
      'Comment vous avez sollicité le moteur';

  @override
  String get throttleRpmHistogramThrottleSection =>
      'Position de l\'accélérateur';

  @override
  String get throttleRpmHistogramRpmSection => 'Régime moteur';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Roue libre (0–25 %)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Léger (25–50 %)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Ferme (50–75 %)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Pleins gaz (75–100 %)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Ralenti (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Croisière (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Dynamique (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Intensif (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Aucun échantillon d\'accélérateur ou de régime pour ce trajet.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct %';
  }

  @override
  String get trajetsTabLabel => 'Trajets';

  @override
  String get trajetsStartRecordingButton => 'Démarrer l\'enregistrement';

  @override
  String get trajetsResumeRecordingButton => 'Reprendre l\'enregistrement';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Connexion à l\'adaptateur OBD2…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Lecture des données du véhicule…';

  @override
  String get tripStartProgressStartingRecording =>
      'Démarrage de l\'enregistrement…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalisation du résumé…';

  @override
  String get tripSaveProgressSavingToHistory =>
      'Enregistrement dans l\'historique…';

  @override
  String get tripSaveProgressSyncingToCloud =>
      'Synchronisation en arrière-plan…';

  @override
  String get trajetsEmptyStateTitle => 'Aucun trajet pour l\'instant';

  @override
  String get trajetsEmptyStateBody =>
      'Touchez Démarrer l\'enregistrement pour commencer à enregistrer vos trajets.';

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
  String get trajetDetailSummaryTitle => 'Résumé';

  @override
  String get trajetDetailFieldDate => 'Date';

  @override
  String get trajetDetailFieldVehicle => 'Véhicule';

  @override
  String get trajetDetailFieldAdapter => 'Adaptateur OBD2';

  @override
  String get trajetDetailFieldDistance => 'Distance';

  @override
  String get trajetDetailFieldDuration => 'Durée';

  @override
  String get trajetDetailFieldAvgConsumption => 'Consommation moyenne';

  @override
  String get trajetDetailFieldFuelUsed => 'Carburant consommé';

  @override
  String get trajetDetailFieldFuelCost => 'Coût du carburant';

  @override
  String get trajetDetailFieldAvgSpeed => 'Vitesse moyenne';

  @override
  String get trajetDetailFieldMaxSpeed => 'Vitesse maximale';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Vitesse (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Débit de carburant (L/h)';

  @override
  String get trajetDetailChartRpm => 'Régime (tr/min)';

  @override
  String get trajetDetailChartEngineLoad => 'Charge moteur (%)';

  @override
  String get trajetDetailChartThrottle => 'Accélérateur / pédale (%)';

  @override
  String get trajetDetailChartCoolant => 'Liquide de refroidissement (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'λ commandé';

  @override
  String get trajetDetailChartsSection => 'Graphiques';

  @override
  String get trajetsRowColdStartChip => 'Démarrage à froid';

  @override
  String get trajetsRowColdStartTooltip =>
      'Le moteur n\'a pas atteint sa température de fonctionnement pendant ce trajet — la consommation a été plus élevée que d\'habitude.';

  @override
  String get trajetDetailChartEmpty => 'Aucun échantillon enregistré';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimé';

  @override
  String get trajetDetailShareAction => 'Partager';

  @override
  String get trajetDetailShareImageOption => 'Partager l\'image';

  @override
  String get trajetDetailShareGpxOption => 'Partager la trace GPS (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Aucune donnée GPS pour ce trajet';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — trajet du $date';
  }

  @override
  String get trajetDetailShareError =>
      'Impossible de générer l\'image à partager';

  @override
  String get trajetDetailDownloadCsvOption => 'Télécharger la télémétrie (CSV)';

  @override
  String get trajetDetailDownloadJsonOption =>
      'Télécharger la télémétrie (JSON)';

  @override
  String get trajetDetailDownloadError =>
      'Impossible d\'enregistrer le fichier';

  @override
  String get trajetDetailDeleteAction => 'Supprimer';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Supprimer ce trajet ?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ce trajet sera définitivement supprimé de votre historique.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Annuler';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Supprimer';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adaptateur OBD2 connecté mais ne renvoyant aucune donnée. Essayez un autre adaptateur ou vérifiez le protocole de diagnostic du véhicule.';

  @override
  String get trajetsViewAllOnMap => 'Tout voir sur la carte';

  @override
  String get trajetsMapTitle => 'Trajets sur la carte';

  @override
  String get trajetsMapShareGpx => 'Partager GPX';

  @override
  String get trajetsMapEmpty =>
      'Aucun des trajets sélectionnés ne contient de données GPS.';

  @override
  String get trajetsMapShareError => 'Impossible de partager le fichier GPX';

  @override
  String get tripLengthCardTitle => 'Consommation par longueur de trajet';

  @override
  String get tripLengthBucketShort => 'Court (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Moyen (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Long (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Plus de données nécessaires';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trajets',
      one: '1 trajet',
      zero: 'aucun trajet',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Trace du trajet';

  @override
  String get tripPathCardSubtitle => 'Itinéraire enregistré par GPS';

  @override
  String get tripPathLegendTitle => 'Consommation';

  @override
  String get tripPathLegendEfficient => 'Économe (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Modérée (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Excessive (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar de stations-service';

  @override
  String get tripRadarScanning => 'Recherche de stations à proximité';

  @override
  String get tripRadarNoStationNearby => 'Aucune station à proximité';

  @override
  String get fuelStationRadarNearer => 'Station plus proche';

  @override
  String get fuelStationRadarFarther => 'Station plus éloignée';

  @override
  String get fuelStationRadarStart => 'Démarrer le radar de stations-service';

  @override
  String get stopRadar => 'Arrêter le radar';

  @override
  String get fuelStationRadarResultBadge =>
      'Résultat du radar de stations-service';

  @override
  String get tripRecordingPinTooltip =>
      'L\'épinglage garde l\'écran allumé — consomme plus de batterie';

  @override
  String get tripRecordingPinSemanticOn =>
      'Désépingler le formulaire d\'enregistrement';

  @override
  String get tripRecordingPinSemanticOff =>
      'Épingler le formulaire d\'enregistrement';

  @override
  String get tripRecordingPinHelpTooltip => 'À quoi sert l\'épinglage ?';

  @override
  String get tripRecordingPinHelpTitle => 'À propos de l\'épinglage';

  @override
  String get tripRecordingPinHelpBody =>
      'L\'épinglage garde l\'écran allumé et masque les barres système pour que le formulaire reste lisible sur un support de tableau de bord. Touchez à nouveau pour le libérer. Se libère automatiquement à l\'arrêt du trajet.';

  @override
  String get tripRecordingResumeHintMessage =>
      'L\'enregistrement continue en arrière-plan. Touchez la bannière rouge en haut de n\'importe quel écran pour revenir.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Ouvrez le trajet actif depuis l\'onglet Conso';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Épinglez l\'écran pour garder le GPS actif pendant le trajet — Android peut limiter le GPS en veille.';

  @override
  String get tripRecordingMinimiseTooltip => 'Réduire en vignette flottante';

  @override
  String get tripRecordingAutoPinTitle =>
      'Toujours épingler au démarrage de l\'enregistrement';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Épingler le formulaire automatiquement à chaque trajet au lieu d\'appuyer à chaque fois. Consomme plus de batterie.';

  @override
  String get tripRecordingConnectingTitle => 'Démarrage de l\'enregistrement…';

  @override
  String get tripRecordingSavingTitle => 'Enregistrement du trajet…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Enregistrement annulé — aucun mouvement détecté';

  @override
  String get tripRecordingGpsNotificationTitle =>
      'Enregistrement du trajet en cours';

  @override
  String get tripRecordingGpsNotificationText =>
      'Suivi GPS de votre itinéraire';

  @override
  String get tripShareAction => 'Partager avec un autre compte';

  @override
  String get tripShareSheetTitle => 'Partager ce trajet';

  @override
  String get tripShareSheetSubtitle =>
      'Donnez à un autre compte TankSync un accès en lecture seule à ce trajet enregistré.';

  @override
  String get tripShareEmailLabel => 'E-mail du destinataire';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Partager';

  @override
  String get tripShareCreateLinkButton => 'Créer un lien de partage';

  @override
  String get tripShareLinkCreated =>
      'Lien de partage copié — transmettez-le au destinataire.';

  @override
  String get tripShareSuccess => 'Trajet partagé.';

  @override
  String get tripShareRecipientNotFound =>
      'Aucun compte TankSync n\'utilise cet e-mail.';

  @override
  String get tripShareError => 'Impossible de partager ce trajet. Réessayez.';

  @override
  String get tripShareExistingTitle => 'Partagé avec';

  @override
  String get tripShareExistingEmpty => 'Pas encore partagé avec personne.';

  @override
  String get tripShareDirectRecipient => 'Un compte';

  @override
  String get tripShareLinkRecipient => 'Lien de partage (non réclamé)';

  @override
  String get tripShareRevokeTooltip => 'Révoquer';

  @override
  String get tripShareRevoked => 'Partage révoqué.';

  @override
  String get trajetsSharedSectionTitle => 'Partagé avec moi';

  @override
  String get trajetsSharedBadge => 'Partagé';

  @override
  String get unifiedFilterFuel => 'Carburant';

  @override
  String get unifiedFilterEv => 'VE';

  @override
  String get unifiedFilterBoth => 'Les deux';

  @override
  String get unifiedNoResultsForFilter => 'Aucun résultat pour ce filtre';

  @override
  String get searchFailedSnackbar =>
      'Échec de la recherche — veuillez réessayer';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Mis à jour $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Aussi : $names';
  }

  @override
  String get favoriteAdd => 'Ajouter aux favoris';

  @override
  String get favoriteRemove => 'Retirer des favoris';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Brut : $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Unbranded station';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Je peux faire le plein avec différents carburants';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Détermine quel carburant est le moins cher au kilomètre';

  @override
  String get vinLabel => 'VIN (optionnel)';

  @override
  String get vinDecodeTooltip => 'Décoder le VIN';

  @override
  String get vinConfirmAction => 'Oui, remplir automatiquement';

  @override
  String get vinModifyAction => 'Modifier manuellement';

  @override
  String get veResetAction => 'Réinitialiser le rendement volumétrique';

  @override
  String get vehicleReadVinFromCarButton => 'Lire le VIN depuis la voiture';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Lire le VIN depuis l\'adaptateur OBD2 jumelé';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN indisponible (Mode 09 PID 02 non pris en charge avant 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Échec de la lecture du VIN — veuillez le saisir manuellement';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Couplez un adaptateur OBD2 pour lire la VIN automatiquement';

  @override
  String get pickerButtonLabel => 'Choisir dans le catalogue';

  @override
  String get pickerSearchHint => 'Rechercher marque ou modèle';

  @override
  String get pickerHelpText =>
      'Pré-remplir depuis 50+ véhicules pris en charge';

  @override
  String get pickerEmptyResults => 'Aucun résultat';

  @override
  String get pickerCancel => 'Annuler';

  @override
  String get pickerLoading => 'Chargement du catalogue…';

  @override
  String get vinInfoTooltip => 'Qu\'est-ce qu\'un VIN ?';

  @override
  String get vinInfoSectionWhatTitle => 'Qu\'est-ce qu\'un VIN ?';

  @override
  String get vinInfoSectionWhatBody =>
      'Le numéro d\'identification du véhicule (VIN) est un code unique de 17 caractères propre à votre voiture. Il est gravé sur le châssis et figure sur votre carte grise.';

  @override
  String get vinInfoSectionWhyTitle => 'Pourquoi nous le demandons';

  @override
  String get vinInfoSectionWhyBody =>
      'Décoder le VIN remplit automatiquement la cylindrée, le nombre de cylindres, l\'année du modèle, le carburant principal et le poids total — vous évitant de chercher les fiches techniques. Le calcul de débit carburant OBD2 utilise ces valeurs pour fournir des chiffres de consommation précis.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Confidentialité';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Votre VIN est stocké uniquement en local dans le stockage chiffré de l\'application — il n\'est jamais envoyé aux serveurs Sparkilo. La base de données NHTSA vPIC est interrogée avec le VIN mais ne renvoie que des spécifications techniques anonymes ; NHTSA n\'associe le VIN à aucune donnée personnelle. Sans réseau, une recherche hors ligne ne renvoie que le constructeur et le pays.';

  @override
  String get vinInfoSectionWhereTitle => 'Où le trouver';

  @override
  String get vinInfoSectionWhereBody =>
      'Regardez à travers le pare-brise dans le coin inférieur gauche côté conducteur, vérifiez l\'autocollant sur le montant de portière côté conducteur (porte ouverte), ou lisez-le sur votre carte grise.';

  @override
  String get vinInfoDismiss => 'Compris';

  @override
  String get vinConfirmPrivacyNote =>
      'Nous avons interrogé votre VIN dans la base de données gratuite NHTSA — rien n\'a été envoyé aux serveurs Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Décodage VIN en ligne';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Décoder le VIN via le service public gratuit de la NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Lorsque vous appairez un adaptateur, le VIN de votre véhicule est lu localement pour identifier la voiture. En activant cette option, le VIN à 17 caractères est envoyé au service vPIC gratuit de la NHTSA pour obtenir plus de détails (modèle, cylindrée, type de carburant). Seul le VIN est transmis — aucune autre donnée ne quitte votre appareil.';

  @override
  String get vehicleDetectedFromVinBadge => '(détecté)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Détecté à partir du VIN : $summary. Appliquer ?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Appliquer';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, à $distanceKm kilomètres, $fuelType $euros euros $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Widget d\'écran d\'accueil';

  @override
  String get widgetHelpIntro =>
      'Ajoutez le widget SparKilo à votre écran d\'accueil pour voir les prix des carburants et de la recharge en un coup d\'œil.';

  @override
  String get widgetHelpAdd =>
      'Ajoutez-le depuis le sélecteur de widgets de votre lanceur — appuyez longuement sur une zone vide de l\'écran d\'accueil, choisissez Widgets et trouvez SparKilo.';

  @override
  String get widgetHelpTap =>
      'Touchez une station dans le widget pour l\'ouvrir dans l\'application. Touchez l\'icône d\'actualisation pour mettre à jour les prix.';

  @override
  String get widgetHelpConfigure =>
      'Sur Android, appuyez longuement sur le widget et choisissez Reconfigurer pour changer le profil, la couleur et le contenu.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Les choix ci-dessous s\'appliquent à chaque widget installé lors de la prochaine actualisation.';

  @override
  String get widgetDefaultsColorLabel => 'Schéma de couleurs';

  @override
  String get widgetDefaultsVariantLabel => 'Variante de contenu';

  @override
  String get widgetColorSchemeSystem => 'Suivre le système';

  @override
  String get widgetColorSchemeLight => 'Clair';

  @override
  String get widgetColorSchemeDark => 'Sombre';

  @override
  String get widgetColorSchemeBlue => 'Bleu';

  @override
  String get widgetColorSchemeGreen => 'Vert';

  @override
  String get widgetColorSchemeOrange => 'Orange';

  @override
  String get widgetVariantDefault => 'Prix actuel uniquement';

  @override
  String get widgetVariantPredictive =>
      'Prédictif : meilleur moment pour faire le plein';

  @override
  String get widgetPredictiveNowPrefix => 'maintenant';
}
