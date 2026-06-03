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
  String get evPriceFree => 'Free';

  @override
  String get evPricePayAtLocation => 'Pay at location';

  @override
  String get evPriceMembership => 'Membership required';

  @override
  String get evPriceIndicative => 'Indicative price';

  @override
  String get evPriceDeclaredByOperator =>
      'Indicative price declared by the operator — verify on site';

  @override
  String get evPriceFranceAttribution =>
      'Pricing: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Best-effort pricing from OpenChargeMap — sparse and may be incomplete.';

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
    return 'Consumption ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Fuel price ($unit)';
  }

  @override
  String get calculatorUseMine => 'Use';

  @override
  String get calculatorApplied => 'Applied';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get calculatorRoundTrip => 'Round trip';

  @override
  String get roundTripTotal => 'Round trip';

  @override
  String get costPerDistance => 'Cost per km';

  @override
  String get costPerMonth => 'Cost per month';

  @override
  String get calculatorEstimateMonthly => 'Estimate monthly cost';

  @override
  String get calculatorTripsPerMonth => 'Trips per month';

  @override
  String get calculatorTripsPerMonthHint => 'e.g. 20';

  @override
  String get calculatorReset => 'Reset';

  @override
  String get calculatorResultPlaceholder =>
      'Fill in distance, consumption and price to see your trip cost';

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
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
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
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

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
  String get evStatusPartial => 'Partly available';

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
  String get sectionSetupDataSources => 'Setup & data sources';

  @override
  String get sectionFeaturesUsage => 'Features & usage';

  @override
  String get sectionAccountSync => 'Account & sync';

  @override
  String get sectionAppearanceWidgets => 'Appearance & widgets';

  @override
  String get sectionPrivacyData => 'Privacy & data';

  @override
  String get sectionAdvancedDeveloper => 'Advanced & developer';

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
  String get coachingVoiceHardAcceleration => 'Easy on the accelerator';

  @override
  String get coachingVoiceHarshBraking => 'Try to brake more gently';

  @override
  String get coachingVoiceShiftUp => 'Shift up a gear to save fuel';

  @override
  String get coachingVoiceShiftDown => 'Shift down, the engine is labouring';

  @override
  String get coachingVoiceEasePedal =>
      'Ease off the pedal to cut your fuel use';

  @override
  String get coachingVoiceLiftOff => 'Lift off the accelerator and coast';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Look further ahead and lift off earlier';

  @override
  String get coachingVoiceSmoothAccel => 'Accelerate more smoothly';

  @override
  String get voiceCoachingSettingTitle => 'Spoken driving coaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hear spoken tips while you drive — hard acceleration, harsh braking and gear hints';

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
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Étalonnage de la consommation mis à jour pour $vehicleName — précision améliorée de $percent %';
  }

  @override
  String get veResetConfirmTitle => 'Réinitialiser le rendement volumétrique ?';

  @override
  String get veResetConfirmBody =>
      'Cela supprimera le rendement volumétrique appris (η_v) et restaurera la valeur par défaut (0,85). Les estimations de débit de carburant par trajet retomberont sur la constante du constructeur jusqu\'à ce que le calibrateur collecte de nouveaux échantillons lors des prochains trajets.';

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
    return 'Radius alert \"$name\" deleted';
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
  String get alertGatingNonDeStationWarning =>
      'Les alertes de prix en arrière-plan ne fonctionnent actuellement que pour les stations en Allemagne. Cette alerte sera enregistrée, mais elle pourrait ne jamais vous notifier tant que les alertes transfrontalières ne sont pas disponibles.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Les alertes de zone ne vérifient actuellement que les stations en Allemagne.';

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
    return '$km km away';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximity $percent%';
  }

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
  String get consumptionStatsPageTitle => 'Consumption statistics';

  @override
  String get consumptionStatsComparisonTitle => 'This month vs last month';

  @override
  String get consumptionStatsTrendsTitle => 'Evolution over time';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Log fill-ups across at least two months to compare.';

  @override
  String get consumptionStatsPricePerLiter => 'Avg price/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litres per month';

  @override
  String get consumptionStatsChartSpend => 'Spend per month';

  @override
  String get consumptionStatsChartPricePerLiter => 'Price per litre';

  @override
  String get consumptionStatsChartConsumption => 'L/100km per month';

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
    return 'Corrections: +$liters L';
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
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© les contributeurs $brand';
  }

  @override
  String get developerToolsSectionTitle => 'Outils de développement';

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
      'Search for stations first, then run the test alert so the notification can open a real station.';

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
    return 'Full throttle ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Ease onto the pedal — a gentler 70 % of the throttle gets you up to speed on far less fuel.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Rich mixture under load ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Heavy, sustained load makes the engine run rich — short-shift and back off on long climbs to keep the mixture lean.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Climbing at $gradePercent% grade ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Carry momentum into a hill and feed the throttle smoothly — surging on a climb burns extra fuel.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stop-and-go restarts: wasted $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticipate traffic and coast toward stops so you roll rather than restart — pulling away from a dead stop is the thirstiest part of stop-and-go.';

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
  String get drivingScoreClassVeryGood => 'Very good';

  @override
  String get drivingScoreClassGood => 'Good';

  @override
  String get drivingScoreClassAverage => 'Average';

  @override
  String get drivingScoreClassBad => 'Needs work';

  @override
  String get drivingScorePenaltyLugging => 'Lugging';

  @override
  String get drivingScorePenaltySmoothness => 'Jerky driving';

  @override
  String get drivingScorePenaltyHighSpeed => 'High speed';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Aggressive pedal';

  @override
  String get drivingScorePenaltyLambda => 'Rich mixture';

  @override
  String get gpsKpiCardTitle => 'GPS efficiency';

  @override
  String get gpsKpiRpa => 'Positive acceleration (RPA)';

  @override
  String get gpsKpiPke => 'Kinetic energy demand (PKE)';

  @override
  String get gpsKpiVapos => 'Acceleration intensity (VAPOS)';

  @override
  String get gpsKpiCoast => 'Coasting share';

  @override
  String get gpsKpiClimbEnergy => 'Climb energy';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs your efficient baseline';
  }

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
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get featureLabel_voiceAnnouncements => 'Annonces vocales';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Annonce à voix haute les stations bon marché à proximité pendant que vous conduisez, pour garder les yeux sur la route.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Activez d\'abord la superposition d\'approche';

  @override
  String get featureGroupTitle_finding => 'Finding & map';

  @override
  String get featureGroupDescription_finding =>
      'Where to fuel up or charge — search, map, routing.';

  @override
  String get featureGroupTitle_prices => 'Prices & alerts';

  @override
  String get featureGroupDescription_prices =>
      'Price drops, history, and reporting.';

  @override
  String get featureGroupTitle_radar => 'Fuel Station Radar';

  @override
  String get featureGroupDescription_radar => 'Live price nudges as you drive.';

  @override
  String get featureGroupTitle_sync => 'Sync & backup';

  @override
  String get featureGroupDescription_sync => 'Keep your data across devices.';

  @override
  String get featureGroupTitle_input => 'Input & scanning';

  @override
  String get featureGroupDescription_input => 'Helpers for logging fill-ups.';

  @override
  String get featureGroupTitle_developer => 'Developer & experimental';

  @override
  String get featureGroupDescription_developer =>
      'Power-user and contributor tools.';

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
  String get fillUpGuidanceTitle => 'Best time to fill up';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'The current price is among the cheapest of the last $days days — a good time to fill up.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Prices are near their $days-day high. They are usually cheaper $window — consider waiting.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Prices are trending up — consider filling up soon.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Today\'s price is around the $days-day average.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Could save about $amount/L by timing your fill-up.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count price readings',
      one: 'Based on 1 price reading',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'on $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'in the $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'at other times';

  @override
  String get fillUpGuidanceWeekday1 => 'Mondays';

  @override
  String get fillUpGuidanceWeekday2 => 'Tuesdays';

  @override
  String get fillUpGuidanceWeekday3 => 'Wednesdays';

  @override
  String get fillUpGuidanceWeekday4 => 'Thursdays';

  @override
  String get fillUpGuidanceWeekday5 => 'Fridays';

  @override
  String get fillUpGuidanceWeekday6 => 'Saturdays';

  @override
  String get fillUpGuidanceWeekday7 => 'Sundays';

  @override
  String get fillUpGuidancePartEarlyMorning => 'early mornings';

  @override
  String get fillUpGuidancePartMorning => 'mornings';

  @override
  String get fillUpGuidancePartAfternoon => 'afternoons';

  @override
  String get fillUpGuidancePartEvening => 'evenings';

  @override
  String get fillUpGuidancePartNight => 'nights';

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
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

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
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

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
      'Estimation GPS (~) — aucun capteur de carburant sur ce trajet. La valeur est modélisée à partir de la vitesse et de l\'étalonnage de votre véhicule ; la précision s\'améliore à mesure que la matrice mûrit.';

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
  String get consumptionMonthlyClimbLabel => 'Climbed';

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
  String get obd2DiagnosticsTitle => 'OBD2 communication health';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops drops',
      one: '1 drop',
      zero: 'no drops',
    );
    return '$percent% complete · $duty% duty · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Connection lifecycle';

  @override
  String get obd2DiagnosticsPidSection => 'Per-PID outcomes';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Scheduler health';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Completeness';

  @override
  String get obd2DiagnosticsSupportSection => 'Discovered-supported PIDs';

  @override
  String get obd2DiagnosticsFuelSection => 'Fuel-tier rollup';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protocol $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts attempts · $successes ok · $drops drops · time-to-connect p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Reconnects: $silent silent · $visible visible';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips back-pressure skips · $demotions demotions';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dynamics tier starved — RPM / speed fell below the governor floor.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Overall $percent% · active duty $duty%';
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
    return '$supported supported · $unsupported unsupported · $unknown unknown';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Suspicious $suspicious of $total samples';
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
    return '$pid: $polled polled · $ok ok · $noData ND · $timeout TO · $error err · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Dongle init transcript';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protocol $protocol · $start · firmware $firmware · $tier · $pids PIDs';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'warm';

  @override
  String get obd2DiagnosticsInitCold => 'cold';

  @override
  String get obd2HealthCopyInitTranscript => 'Copy init transcript only';

  @override
  String get obd2DiagnosticsEmpty =>
      'No OBD2 session recorded yet — connect an adapter and record a trip with Developer mode on.';

  @override
  String get obd2DiagnosticsExplain =>
      'Captured while recording to debug the dongle↔app communication — only collected in Developer mode.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 communication health';

  @override
  String get obd2HealthNavLabel => 'OBD2 communication health';

  @override
  String get obd2HealthLiveSection => 'Live session';

  @override
  String get obd2HealthHistorySection => 'Recent sessions';

  @override
  String get obd2HealthCopyJson => 'Copy as JSON';

  @override
  String get obd2HealthCopied => 'OBD2 diagnostics copied to clipboard.';

  @override
  String get obd2TestRunTitle => 'Run adapter test';

  @override
  String get obd2TestRunButton => 'Run adapter test';

  @override
  String get obd2TestRunPassed => 'Adapter test passed';

  @override
  String get obd2TestRunFailed => 'Adapter test failed';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed of $total steps OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Stop the active recording before running the adapter test.';

  @override
  String get obd2TestStepScan => 'Scan for adapter';

  @override
  String get obd2TestStepConnect => 'Connect & init';

  @override
  String get obd2TestStepInfo => 'Adapter info';

  @override
  String get obd2TestStepSupportedPids => 'Supported PIDs';

  @override
  String get obd2TestStepSampleReads => 'Sample reads';

  @override
  String get obd2TestStepReconnect => 'Reconnect test';

  @override
  String get obd2TestStepDisconnect => 'Disconnect';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Timed out';

  @override
  String get obd2TestStatusGarbage => 'Unreadable reply';

  @override
  String get obd2TestStatusNoResponse => 'No response';

  @override
  String get obd2TestStatusFail => 'Failed';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Impossible de joindre \'$adapterName\' — choisissez un autre adaptateur';
  }

  @override
  String get ocrTesterTitle => 'OCR tester';

  @override
  String get ocrTesterNavLabel => 'OCR tester';

  @override
  String get ocrTesterExplain =>
      'Run the pump / receipt OCR pipeline on a chosen photo and inspect every step — only available in Developer mode.';

  @override
  String get ocrTesterModePump => 'Pump';

  @override
  String get ocrTesterModeReceipt => 'Receipt';

  @override
  String get ocrTesterCapture => 'Capture';

  @override
  String get ocrTesterPickImage => 'Pick image';

  @override
  String get ocrTesterRun => 'Run';

  @override
  String get ocrTesterCountry => 'Country';

  @override
  String get ocrTesterCountryNone => 'Default (no profile)';

  @override
  String get ocrTesterNoImage => 'Pick or capture an image, then Run.';

  @override
  String get ocrTesterRunning => 'Running OCR…';

  @override
  String get ocrTesterNoResult => 'OCR produced no readable result.';

  @override
  String get ocrTesterOverlaySection => 'Block overlay';

  @override
  String get ocrTesterStepsSection => 'Pipeline steps';

  @override
  String get ocrTesterLegendLabel => 'Label';

  @override
  String get ocrTesterLegendNumeric => 'Numeric';

  @override
  String get ocrTesterLegendNoise => 'Noise';

  @override
  String get ocrTesterLegendDerived => 'Derived';

  @override
  String get ocrTesterStageGlare => 'Capture / glare';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Classify';

  @override
  String get ocrTesterStageAssemble => 'Assemble';

  @override
  String get ocrTesterStageAnchor => 'Anchor';

  @override
  String get ocrTesterStageFallback => 'Fallback';

  @override
  String get ocrTesterStageCrossCheck => 'Cross-check';

  @override
  String get ocrTesterStageConfidence => 'Confidence';

  @override
  String get ocrTesterStageGate => 'Gate';

  @override
  String get ocrTesterStageBrand => 'Brand';

  @override
  String get ocrTesterStageOverrides => 'Overrides';

  @override
  String get ocrTesterStageReconcile => 'Reconcile';

  @override
  String get ocrTesterStageResult => 'Result';

  @override
  String get ocrTesterChipRead => 'READ';

  @override
  String get ocrTesterChipDerived => 'DERIVED';

  @override
  String get ocrTesterGateAccepted => 'Accepted';

  @override
  String get ocrTesterGateRejected => 'Rejected';

  @override
  String get ocrTesterFallbackBanner =>
      'A field was recovered via magnitude fallback — verify it.';

  @override
  String get ocrTesterStageNoData => 'Stage did not run.';

  @override
  String get ocrTesterCopyJson => 'Copy as JSON';

  @override
  String get ocrTesterExportPackage => 'Export package';

  @override
  String get ocrTesterCopied => 'OCR trace copied to clipboard.';

  @override
  String get ocrTesterExported => 'OCR package saved to your Downloads folder.';

  @override
  String get ocrTesterSaveFixture => 'Save as fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture saved to your Downloads folder. Move it under test/fixtures and run tool/promote_ocr_fixture.dart.';

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
  String get openNow => 'Open';

  @override
  String get openNowClosed => 'Closed';

  @override
  String get openHoursUnknown => 'Hours unknown';

  @override
  String closesAt(String time) {
    return 'Closes $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Opens $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Opens $time';
  }

  @override
  String get open24Hours => 'Open 24 hours';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => '24/7 automate';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Public holidays';

  @override
  String get closedLabel => 'Closed';

  @override
  String get openingHoursNotAvailable => 'Opening hours not available';

  @override
  String get showAllHours => 'Show all hours';

  @override
  String get showLessHours => 'Show less';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'écoulé';

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
  String get reconcileWorkflowTitle => 'Reconcile your fuel';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'We found a $gap L gap';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'You pumped $pumped L, but your recorded trips only account for $consumed L. That leaves $gap L unexplained.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'This usually means a drive wasn\'t recorded (the adapter was unplugged or the app was closed), or a fill-up is missing or mistyped.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Until this is resolved, your fuel total and your trips total won\'t match.';

  @override
  String get reconcileWorkflowAttributeQuestion => 'Help us attribute the gap';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Are all your fill-ups for this tank complete and correct?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Are all your drives recorded?';

  @override
  String get reconcileWorkflowAnswerYes => 'Yes';

  @override
  String get reconcileWorkflowAnswerNo => 'No';

  @override
  String get reconcileWorkflowPathAHint =>
      'A fill-up is missing or wrong — we\'ll add a correction so your fill-ups add up.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Your fill-ups are right and a drive went unrecorded — we\'ll add a virtual trip for the missing distance.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Correction litres';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'How far was the unrecorded drive? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Decide later';

  @override
  String get reconcileWorkflowBack => 'Back';

  @override
  String get reconcileWorkflowNext => 'Next';

  @override
  String get reconcileWorkflowApply => 'Apply';

  @override
  String get reconcileVirtualTrajetLabel => 'Virtual trip — tap to edit';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Edit virtual trip';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'This trip was added to account for fuel you used while driving without recording. Adjust the distance or fuel, or delete it.';

  @override
  String get reconcileVirtualTrajetDelete => 'Delete virtual trip';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Unresolved fuel/trip gap of $gap L — tap to resolve';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Resolve unresolved fuel and trip gap';

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/séance';

  @override
  String get shareReceiptImporting => 'Importing shared receipt…';

  @override
  String get shareReceiptUnsupportedFormat =>
      'That file type can\'t be imported yet — share a photo of the receipt instead.';

  @override
  String get shareReceiptFailed =>
      'Couldn\'t read the shared receipt — try sharing it again or add the fill-up manually.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Share receipt to import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Share a receipt photo from another app to pre-fill a fill-up — date, litres, total, and station are read on-device.';

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
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

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
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

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
  String get trajetDetailChartEstimatedBadge => 'estimated';

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
  String get trajetDetailDownloadCsvOption => 'Download telemetry (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetry (JSON)';

  @override
  String get trajetDetailDownloadError => 'Couldn\'t save the file';

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
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get fuelStationRadarNearer => 'Nearer station';

  @override
  String get fuelStationRadarFarther => 'Farther station';

  @override
  String get fuelStationRadarStart => 'Start fuel station radar';

  @override
  String get stopRadar => 'Arrêter le radar';

  @override
  String get fuelStationRadarResultBadge => 'Fuel Station Radar result';

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
  String get tripRecordingSavingTitle => 'Saving trip…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

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
    return 'Updated $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Also: $names';
  }

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Raw: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

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
