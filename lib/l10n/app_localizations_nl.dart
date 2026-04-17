// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Brandstofprijzen';

  @override
  String get search => 'Zoeken';

  @override
  String get favorites => 'Favorieten';

  @override
  String get map => 'Kaart';

  @override
  String get profile => 'Profiel';

  @override
  String get settings => 'Instellingen';

  @override
  String get gpsLocation => 'GPS-locatie';

  @override
  String get zipCode => 'Postcode';

  @override
  String get zipCodeHint => 'bijv. 1011';

  @override
  String get fuelType => 'Brandstof';

  @override
  String get searchRadius => 'Straal';

  @override
  String get searchNearby => 'Tankstations in de buurt';

  @override
  String get searchButton => 'Zoeken';

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
  String get noResults => 'Geen tankstations gevonden.';

  @override
  String get startSearch => 'Zoek om tankstations te vinden.';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Gesloten';

  @override
  String distance(String distance) {
    return '$distance verderop';
  }

  @override
  String get price => 'Prijs';

  @override
  String get prices => 'Prijzen';

  @override
  String get address => 'Adres';

  @override
  String get openingHours => 'Openingstijden';

  @override
  String get open24h => '24 uur open';

  @override
  String get navigate => 'Navigeren';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get apiKeySetup => 'API-sleutel';

  @override
  String get apiKeyDescription =>
      'Registreer eenmalig voor een gratis API-sleutel.';

  @override
  String get apiKeyLabel => 'API-sleutel';

  @override
  String get register => 'Registratie';

  @override
  String get continueButton => 'Doorgaan';

  @override
  String get welcome => 'Brandstofprijzen';

  @override
  String get welcomeSubtitle =>
      'Vind de goedkoopste brandstof bij jou in de buurt.';

  @override
  String get profileName => 'Profielnaam';

  @override
  String get preferredFuel => 'Voorkeursbrandstof';

  @override
  String get defaultRadius => 'Standaard straal';

  @override
  String get landingScreen => 'Startscherm';

  @override
  String get homeZip => 'Postcode thuis';

  @override
  String get newProfile => 'Nieuw profiel';

  @override
  String get editProfile => 'Profiel bewerken';

  @override
  String get save => 'Opslaan';

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get activate => 'Activeren';

  @override
  String get configured => 'Geconfigureerd';

  @override
  String get notConfigured => 'Niet geconfigureerd';

  @override
  String get about => 'Over';

  @override
  String get openSource => 'Open Source (MIT Licentie)';

  @override
  String get sourceCode => 'Broncode op GitHub';

  @override
  String get noFavorites => 'Nog geen favorieten';

  @override
  String get noFavoritesHint =>
      'Tik op de ster bij een tankstation om het als favoriet op te slaan.';

  @override
  String get language => 'Taal';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demomodus — voorbeeldgegevens.';

  @override
  String get setupLiveData => 'Instellen voor live gegevens';

  @override
  String get freeNoKey => 'Gratis — geen sleutel nodig';

  @override
  String get apiKeyRequired => 'API-sleutel vereist';

  @override
  String get skipWithoutKey => 'Doorgaan zonder sleutel';

  @override
  String get dataTransparency => 'Gegevenstransparantie';

  @override
  String get storageAndCache => 'Opslag en cache';

  @override
  String get clearCache => 'Cache wissen';

  @override
  String get clearAllData => 'Alle gegevens verwijderen';

  @override
  String get errorLog => 'Foutenlogboek';

  @override
  String stationsFound(int count) {
    return '$count tankstations gevonden';
  }

  @override
  String get whatIsShared => 'Wat wordt gedeeld — en met wie?';

  @override
  String get gpsCoordinates => 'GPS-coördinaten';

  @override
  String get gpsReason =>
      'Worden bij elke zoekopdracht verstuurd om nabijgelegen stations te vinden.';

  @override
  String get postalCodeData => 'Postcode';

  @override
  String get postalReason =>
      'Wordt omgezet in coördinaten via de geocoderingsservice.';

  @override
  String get mapViewport => 'Kaartweergave';

  @override
  String get mapReason =>
      'Kaarttegels worden geladen vanaf de server. Er worden geen persoonlijke gegevens verzonden.';

  @override
  String get apiKeyData => 'API-sleutel';

  @override
  String get apiKeyReason =>
      'Uw persoonlijke sleutel wordt bij elke API-aanvraag meegezonden. Deze is gekoppeld aan uw e-mail.';

  @override
  String get notShared => 'Wordt NIET gedeeld:';

  @override
  String get searchHistory => 'Zoekgeschiedenis';

  @override
  String get favoritesData => 'Favorieten';

  @override
  String get profileNames => 'Profielnamen';

  @override
  String get homeZipData => 'Postcode thuis';

  @override
  String get usageData => 'Gebruiksgegevens';

  @override
  String get privacyBanner =>
      'Deze app heeft geen server. Alle gegevens blijven op uw apparaat. Geen analyse, geen tracking, geen advertenties.';

  @override
  String get storageUsage => 'Opslaggebruik op dit apparaat';

  @override
  String get settingsLabel => 'Instellingen';

  @override
  String get profilesStored => 'profielen opgeslagen';

  @override
  String get stationsMarked => 'stations gemarkeerd';

  @override
  String get cachedResponses => 'gecachte antwoorden';

  @override
  String get total => 'Totaal';

  @override
  String get cacheManagement => 'Cachebeheer';

  @override
  String get cacheDescription =>
      'De cache slaat API-antwoorden op voor sneller laden en offline toegang.';

  @override
  String get stationSearch => 'Stations zoeken';

  @override
  String get stationDetails => 'Stationsdetails';

  @override
  String get priceQuery => 'Prijsopvraag';

  @override
  String get zipGeocoding => 'Postcode-geocodering';

  @override
  String minutes(int n) {
    return '$n minuten';
  }

  @override
  String hours(int n) {
    return '$n uur';
  }

  @override
  String get clearCacheTitle => 'Cache wissen?';

  @override
  String get clearCacheBody =>
      'Gecachte zoekresultaten en prijzen worden verwijderd. Profielen, favorieten en instellingen blijven bewaard.';

  @override
  String get clearCacheButton => 'Cache wissen';

  @override
  String get deleteAllTitle => 'Alle gegevens verwijderen?';

  @override
  String get deleteAllBody =>
      'Dit verwijdert permanent alle profielen, favorieten, API-sleutel, instellingen en cache. De app wordt gereset.';

  @override
  String get deleteAllButton => 'Alles verwijderen';

  @override
  String get entries => 'items';

  @override
  String get cacheEmpty => 'De cache is leeg';

  @override
  String get noStorage => 'Geen opslag gebruikt';

  @override
  String get apiKeyNote =>
      'Gratis registratie. Gegevens van overheidsinstanties voor prijstransparantie.';

  @override
  String get apiKeyFormatError =>
      'Ongeldig formaat — UUID verwacht (8-4-4-4-12)';

  @override
  String get supportProject => 'Steun dit project';

  @override
  String get supportDescription =>
      'Deze app is gratis, open source en zonder advertenties. Als u het nuttig vindt, overweeg de ontwikkelaar te steunen.';

  @override
  String get reportBug => 'Bug melden / Functie voorstellen';

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
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get fuels => 'Brandstoffen';

  @override
  String get services => 'Diensten';

  @override
  String get zone => 'Zone';

  @override
  String get highway => 'Snelweg';

  @override
  String get localStation => 'Lokaal station';

  @override
  String get lastUpdate => 'Laatste update';

  @override
  String get automate24h => '24u/24 — Automaat';

  @override
  String get refreshPrices => 'Prijzen vernieuwen';

  @override
  String get station => 'Tankstation';

  @override
  String get locationDenied =>
      'Locatietoestemming geweigerd. U kunt zoeken op postcode.';

  @override
  String get demoModeBanner =>
      'Demomodus. Configureer API-sleutel in instellingen.';

  @override
  String get sortDistance => 'Afstand';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'goedkoop';

  @override
  String get expensive => 'duur';

  @override
  String stationsOnMap(int count) {
    return '$count stations';
  }

  @override
  String get loadingFavorites =>
      'Favorieten laden...\nZoek eerst naar stations om gegevens op te slaan.';

  @override
  String get reportPrice => 'Prijs melden';

  @override
  String get whatsWrong => 'Wat klopt er niet?';

  @override
  String get correctPrice => 'Correcte prijs (bijv. 1,459)';

  @override
  String get sendReport => 'Melding versturen';

  @override
  String get reportSent => 'Melding verstuurd. Bedankt!';

  @override
  String get enterValidPrice => 'Voer een geldige prijs in';

  @override
  String get cacheCleared => 'Cache gewist.';

  @override
  String get yourPosition => 'Uw positie';

  @override
  String get positionUnknown => 'Positie onbekend';

  @override
  String get distancesFromCenter => 'Afstanden vanaf zoekcentrum';

  @override
  String get autoUpdatePosition => 'Positie automatisch bijwerken';

  @override
  String get autoUpdateDescription =>
      'GPS-positie bijwerken voor elke zoekopdracht';

  @override
  String get location => 'Locatie';

  @override
  String get switchProfileTitle => 'Land gewijzigd';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'U bent nu in $country. Overschakelen naar profiel \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Overgeschakeld naar profiel \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Geen profiel voor dit land';

  @override
  String noProfileForCountry(String country) {
    return 'U bent in $country, maar er is geen profiel geconfigureerd. Maak er een aan in Instellingen.';
  }

  @override
  String get autoSwitchProfile => 'Automatisch profiel wisselen';

  @override
  String get autoSwitchDescription =>
      'Profiel automatisch wisselen bij grensovergang';

  @override
  String get switchProfile => 'Wisselen';

  @override
  String get dismiss => 'Sluiten';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Taal';

  @override
  String get settingsStorageDetail => 'API-sleutel, actief profiel';

  @override
  String get allFuels => 'Alle';

  @override
  String get priceAlerts => 'Prijswaarschuwingen';

  @override
  String get noPriceAlerts => 'Geen prijswaarschuwingen';

  @override
  String get noPriceAlertsHint =>
      'Maak een waarschuwing aan vanaf de detailpagina van een station.';

  @override
  String alertDeleted(String name) {
    return 'Waarschuwing \"$name\" verwijderd';
  }

  @override
  String get createAlert => 'Prijswaarschuwing aanmaken';

  @override
  String currentPrice(String price) {
    return 'Huidige prijs: $price';
  }

  @override
  String get targetPrice => 'Doelprijs (EUR)';

  @override
  String get enterPrice => 'Voer een prijs in';

  @override
  String get invalidPrice => 'Ongeldige prijs';

  @override
  String get priceTooHigh => 'Prijs te hoog';

  @override
  String get create => 'Aanmaken';

  @override
  String get alertCreated => 'Prijswaarschuwing aangemaakt';

  @override
  String get wrongE5Price => 'Verkeerde Super E5 prijs';

  @override
  String get wrongE10Price => 'Verkeerde Super E10 prijs';

  @override
  String get wrongDieselPrice => 'Verkeerde Diesel prijs';

  @override
  String get wrongStatusOpen => 'Getoond als open, maar gesloten';

  @override
  String get wrongStatusClosed => 'Getoond als gesloten, maar open';

  @override
  String get searchAlongRouteLabel => 'Langs de route';

  @override
  String get searchEvStations => 'Zoek laadstations';

  @override
  String get allStations => 'Alle stations';

  @override
  String get bestStops => 'Beste stops';

  @override
  String get openInMaps => 'Openen in Kaarten';

  @override
  String get noStationsAlongRoute => 'Geen stations gevonden langs de route';

  @override
  String get evOperational => 'Operationeel';

  @override
  String get evStatusUnknown => 'Status onbekend';

  @override
  String evConnectors(int count) {
    return 'Connectoren ($count punten)';
  }

  @override
  String get evNoConnectors => 'Geen connectordetails beschikbaar';

  @override
  String get evUsageCost => 'Gebruikskosten';

  @override
  String get evPricingUnavailable =>
      'Prijsinformatie niet beschikbaar van aanbieder';

  @override
  String get evLastUpdated => 'Laatst bijgewerkt';

  @override
  String get evUnknown => 'Onbekend';

  @override
  String get evDataAttribution => 'Gegevens van OpenChargeMap (community-bron)';

  @override
  String get evStatusDisclaimer =>
      'De status weerspiegelt mogelijk niet de real-time beschikbaarheid. Tik op vernieuwen voor de laatste gegevens.';

  @override
  String get evNavigateToStation => 'Navigeer naar station';

  @override
  String get evRefreshStatus => 'Status vernieuwen';

  @override
  String get evStatusUpdated => 'Status bijgewerkt';

  @override
  String get evStationNotFound =>
      'Kan niet vernieuwen — station niet in de buurt gevonden';

  @override
  String get addedToFavorites => 'Toegevoegd aan favorieten';

  @override
  String get removedFromFavorites => 'Verwijderd uit favorieten';

  @override
  String get addFavorite => 'Toevoegen aan favorieten';

  @override
  String get removeFavorite => 'Verwijderen uit favorieten';

  @override
  String get currentLocation => 'Huidige locatie';

  @override
  String get gpsError => 'GPS-fout';

  @override
  String get couldNotResolve => 'Kan start of bestemming niet bepalen';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Bestemming';

  @override
  String get cityAddressOrGps => 'Stad, adres of GPS';

  @override
  String get cityOrAddress => 'Stad of adres';

  @override
  String get useGps => 'GPS gebruiken';

  @override
  String get stop => 'Stop';

  @override
  String stopN(int n) {
    return 'Stop $n';
  }

  @override
  String get addStop => 'Stop toevoegen';

  @override
  String get searchAlongRoute => 'Zoek langs de route';

  @override
  String get cheapest => 'Goedkoopste';

  @override
  String nStations(int count) {
    return '$count stations';
  }

  @override
  String nBest(int count) {
    return '$count beste';
  }

  @override
  String get fuelPricesTankerkoenig => 'Brandstofprijzen (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Vereist voor brandstofprijzen zoeken in Duitsland';

  @override
  String get evChargingOpenChargeMap => 'EV-laden (OpenChargeMap)';

  @override
  String get customKey => 'Eigen sleutel';

  @override
  String get appDefaultKey => 'Standaard app-sleutel';

  @override
  String get optionalOverrideKey =>
      'Optioneel: de ingebouwde app-sleutel vervangen door uw eigen';

  @override
  String get requiredForEvSearch =>
      'Vereist voor het zoeken naar EV-laadstations';

  @override
  String get edit => 'Bewerken';

  @override
  String get fuelPricesApiKey => 'Brandstofprijzen API-sleutel';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-sleutel';

  @override
  String get evChargingApiKey => 'EV-laden API-sleutel';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-sleutel';

  @override
  String get routeSegment => 'Routesegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Toon goedkoopste station elke $km km langs de route';
  }

  @override
  String get avoidHighways => 'Snelwegen vermijden';

  @override
  String get avoidHighwaysDesc =>
      'Routeberekening vermijdt tolwegen en snelwegen';

  @override
  String get showFuelStations => 'Tankstations tonen';

  @override
  String get showFuelStationsDesc =>
      'Inclusief benzine-, diesel-, LPG-, CNG-stations';

  @override
  String get showEvStations => 'Laadstations tonen';

  @override
  String get showEvStationsDesc =>
      'Elektrische laadstations opnemen in zoekresultaten';

  @override
  String get noStationsAlongThisRoute =>
      'Geen stations gevonden langs deze route.';

  @override
  String get fuelCostCalculator => 'Brandstofkostencalculator';

  @override
  String get distanceKm => 'Afstand (km)';

  @override
  String get consumptionL100km => 'Verbruik (L/100km)';

  @override
  String get fuelPriceEurL => 'Brandstofprijs (EUR/L)';

  @override
  String get tripCost => 'Ritkosten';

  @override
  String get fuelNeeded => 'Benodigde brandstof';

  @override
  String get totalCost => 'Totale kosten';

  @override
  String get enterCalcValues =>
      'Voer afstand, verbruik en prijs in om de ritkosten te berekenen';

  @override
  String get priceHistory => 'Prijsgeschiedenis';

  @override
  String get noPriceHistory => 'Nog geen prijsgeschiedenis';

  @override
  String get noHourlyData => 'Geen uurgegevens';

  @override
  String get noStatistics => 'Geen statistieken beschikbaar';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Gem';

  @override
  String get showAllFuelTypes => 'Alle brandstofsoorten tonen';

  @override
  String get connected => 'Verbonden';

  @override
  String get notConnected => 'Niet verbonden';

  @override
  String get connectTankSync => 'TankSync verbinden';

  @override
  String get disconnectTankSync => 'TankSync loskoppelen';

  @override
  String get viewMyData => 'Mijn gegevens bekijken';

  @override
  String get optionalCloudSync =>
      'Optionele cloudsynchronisatie voor waarschuwingen, favorieten en pushmeldingen';

  @override
  String get tapToUpdateGps => 'Tik om GPS-positie bij te werken';

  @override
  String get gpsAutoUpdateHint =>
      'De GPS-positie wordt automatisch verkregen bij het zoeken. U kunt deze hier ook handmatig bijwerken.';

  @override
  String get clearGpsConfirm =>
      'Opgeslagen GPS-positie wissen? U kunt deze op elk moment opnieuw bijwerken.';

  @override
  String get pageNotFound => 'Pagina niet gevonden';

  @override
  String get deleteAllServerData => 'Alle servergegevens verwijderen';

  @override
  String get deleteServerDataConfirm => 'Alle servergegevens verwijderen?';

  @override
  String get deleteEverything => 'Alles verwijderen';

  @override
  String get allDataDeleted => 'Alle servergegevens verwijderd';

  @override
  String get disconnectConfirm => 'TankSync loskoppelen?';

  @override
  String get disconnect => 'Loskoppelen';

  @override
  String get myServerData => 'Mijn servergegevens';

  @override
  String get anonymousUuid => 'Anonieme UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Gesynchroniseerde gegevens';

  @override
  String get pushTokens => 'Push-tokens';

  @override
  String get priceReports => 'Prijsmeldingen';

  @override
  String get totalItems => 'Totaal items';

  @override
  String get estimatedSize => 'Geschatte grootte';

  @override
  String get viewRawJson => 'Ruwe gegevens als JSON bekijken';

  @override
  String get exportJson => 'Exporteren als JSON (klembord)';

  @override
  String get jsonCopied => 'JSON gekopieerd naar klembord';

  @override
  String get rawDataJson => 'Ruwe gegevens (JSON)';

  @override
  String get close => 'Sluiten';

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
  String get alertStatsActive => 'Actief';

  @override
  String get alertStatsToday => 'Vandaag';

  @override
  String get alertStatsThisWeek => 'Deze week';

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
  String get amenities => 'Voorzieningen';

  @override
  String get amenityShop => 'Winkel';

  @override
  String get amenityCarWash => 'Wasstraat';

  @override
  String get amenityAirPump => 'Lucht';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Eten';

  @override
  String get amenityAtm => 'Pinautomaat';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'Oplaadpunt';

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
  String get nearestStations => 'Dichtstbijzijnde stations';

  @override
  String get nearestStationsHint =>
      'Vind de dichtstbijzijnde stations met uw huidige locatie';

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
