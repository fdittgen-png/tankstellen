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
  String privacyCopyErrorLog(int count) {
    return 'Copy error log to clipboard ($count)';
  }

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
  String get fillUpVehicleLabel => 'Vehicle';

  @override
  String get fillUpVehicleNone => 'No vehicle';

  @override
  String get fillUpVehicleRequired => 'Vehicle is required';

  @override
  String get reportScanError => 'Report scan error';

  @override
  String get pickStationTitle => 'Pick a station';

  @override
  String get pickStationHelper =>
      'Start the fill-up from a known station so prices, brand and fuel type fill themselves in.';

  @override
  String get pickStationEmpty =>
      'No favorite stations yet — add some from Search or Favorites, or skip and fill in manually.';

  @override
  String get pickStationSkip => 'Skip — add without a station';

  @override
  String get scanPump => 'Scan pump';

  @override
  String get scanPayment => 'Scan payment QR';

  @override
  String get qrPaymentBeneficiary => 'Beneficiary';

  @override
  String get qrPaymentAmount => 'Amount';

  @override
  String get qrPaymentEpcTitle => 'SEPA payment';

  @override
  String get qrPaymentEpcEmpty => 'No fields decoded';

  @override
  String get qrPaymentOpenInBank => 'Open in bank app';

  @override
  String get qrPaymentLaunchFailed => 'No app available to open this code';

  @override
  String get qrPaymentUnknownTitle => 'Unrecognised code';

  @override
  String get qrPaymentCopyRaw => 'Copy raw text';

  @override
  String get qrPaymentCopiedRaw => 'Copied to clipboard';

  @override
  String get qrPaymentReport => 'Report this scan';

  @override
  String get qrPaymentEpcCopied =>
      'Bank details copied — paste into your banking app';

  @override
  String get qrScannerGuidance => 'Point the camera at a QR code';

  @override
  String get qrScannerPermissionDenied =>
      'Camera access is needed to scan QR codes.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Camera access was denied. Open settings to grant it.';

  @override
  String get qrScannerRetryPermission => 'Try again';

  @override
  String get qrScannerOpenSettings => 'Open settings';

  @override
  String get qrScannerTimeout =>
      'No QR code detected. Move closer or try again.';

  @override
  String get qrScannerRetry => 'Try again';

  @override
  String get torchOn => 'Turn flash on';

  @override
  String get torchOff => 'Turn flash off';

  @override
  String get obdNoAdapter => 'No OBD2 adapter in range';

  @override
  String get obdOdometerUnavailable => 'Could not read odometer';

  @override
  String get obdPermissionDenied =>
      'Grant Bluetooth permission in system settings';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter didn\'t answer — turn the ignition on and retry';

  @override
  String get obdPickerTitle => 'Pick an OBD2 adapter';

  @override
  String get obdPickerScanning => 'Scanning for adapters…';

  @override
  String get obdPickerConnecting => 'Connecting…';

  @override
  String get themeSettingTitle => 'Theme';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'Follow system';

  @override
  String get tripRecordingTitle => 'Recording trip';

  @override
  String get tripSummaryTitle => 'Trip summary';

  @override
  String get tripMetricDistance => 'Distance';

  @override
  String get tripMetricSpeed => 'Speed';

  @override
  String get tripMetricFuelUsed => 'Fuel used';

  @override
  String get tripMetricAvgConsumption => 'Avg';

  @override
  String get tripMetricElapsed => 'Elapsed';

  @override
  String get tripMetricOdometer => 'Odometer';

  @override
  String get tripStop => 'Stop recording';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Resume';

  @override
  String get tripBannerRecording => 'Recording trip';

  @override
  String get tripBannerPaused => 'Trip paused — tap to resume';

  @override
  String get navConsumption => 'Consumption';

  @override
  String get vehicleBaselineSectionTitle => 'Baseline calibration';

  @override
  String get vehicleBaselineEmpty =>
      'No samples yet — start an OBD2 trip to begin learning this vehicle\'s fuel profile.';

  @override
  String get vehicleBaselineProgress =>
      'Learned from samples across driving situations.';

  @override
  String get vehicleBaselineReset => 'Reset driving-situation baseline';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Reset driving-situation baseline?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'This wipes every learned sample for this vehicle. You\'ll drift back to the cold-start defaults until new trips refill the profile.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapter';

  @override
  String get vehicleAdapterEmpty =>
      'No adapter paired. Pair one so the app can reconnect automatically next time.';

  @override
  String get vehicleAdapterUnnamed => 'Unknown adapter';

  @override
  String get vehicleAdapterPair => 'Pair adapter';

  @override
  String get vehicleAdapterForget => 'Forget adapter';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFirstTrip => 'First trip';

  @override
  String get achievementFirstTripDesc => 'Record your first OBD2 trip.';

  @override
  String get achievementFirstFillUp => 'First fill-up';

  @override
  String get achievementFirstFillUpDesc => 'Log your first fill-up.';

  @override
  String get achievementTenTrips => '10 trips';

  @override
  String get achievementTenTripsDesc => 'Record 10 OBD2 trips.';

  @override
  String get achievementZeroHarsh => 'Smooth driver';

  @override
  String get achievementZeroHarshDesc =>
      'Complete a trip of 10 km or more with no harsh braking or acceleration.';

  @override
  String get achievementEcoWeek => 'Eco week';

  @override
  String get achievementEcoWeekDesc =>
      'Drive 7 consecutive days with at least one smooth trip each day.';

  @override
  String get achievementPriceWin => 'Price win';

  @override
  String get achievementPriceWinDesc =>
      'Log a fill-up that beats the station\'s 30-day average by 5 % or more.';

  @override
  String get syncBaselinesToggleTitle => 'Share learned vehicle profiles';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Upload per-vehicle consumption baselines so a second device can reuse them.';

  @override
  String get obd2StatusConnected => 'OBD2 adapter: connected';

  @override
  String get obd2StatusAttempting => 'OBD2 adapter: connecting';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapter: unreachable';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: Bluetooth permission needed';

  @override
  String get obd2StatusConnectedBody => 'Ready to record a trip.';

  @override
  String get obd2StatusAttemptingBody => 'Connecting in the background…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter out of range or already in use by another app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Grant Bluetooth permission in system settings to reconnect automatically.';

  @override
  String get obd2StatusNoAdapter => 'No adapter paired';

  @override
  String get obd2StatusForget => 'Forget adapter';

  @override
  String get tripHistoryTitle => 'Trip history';

  @override
  String get tripHistoryEmptyTitle => 'No trips yet';

  @override
  String get tripHistoryEmptySubtitle =>
      'Connect an OBD2 adapter and record a trip to start building your driving history.';

  @override
  String get tripHistoryUnknownDate => 'Unknown date';

  @override
  String get situationIdle => 'Idle';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urban';

  @override
  String get situationHighway => 'Highway';

  @override
  String get situationDecel => 'Decelerating';

  @override
  String get situationClimbing => 'Climbing / loaded';

  @override
  String get situationHardAccel => 'Hard accel';

  @override
  String get situationFuelCut => 'Fuel cut — coast';

  @override
  String get tripSaveAsFillUp => 'Save as fill-up';

  @override
  String get tripSaveRecording => 'Save trip';

  @override
  String get tripDiscard => 'Discard';

  @override
  String obdOdometerRead(int km) {
    return 'Odometer read: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Not set';

  @override
  String get wizardVehicleTapToEdit => 'Tap to edit';

  @override
  String get wizardVehicleDefaultBadge => 'Default';

  @override
  String get profileDefaultVehicleLabel => 'Default vehicle (optional)';

  @override
  String get profileDefaultVehicleNone => 'No default';

  @override
  String get profileFuelFromVehicleHint =>
      'Fuel type is derived from your default vehicle. Clear the vehicle to pick a fuel directly.';

  @override
  String get consumptionNoVehicleTitle => 'Add a vehicle first';

  @override
  String get consumptionNoVehicleBody =>
      'Fill-ups are attributed to a vehicle. Add your car to start logging consumption.';

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
  String get helpBannerConsumption =>
      'Log every fill-up to track your real-world consumption and CO₂ footprint. Swipe left to delete an entry.';

  @override
  String get helpBannerVehicles =>
      'Add your vehicles so fill-ups and fuel preferences default correctly. The first vehicle becomes your default.';

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
  String errorUpstreamCertExpired(String host) {
    return 'The data provider ($host) is serving an expired or invalid TLS certificate. The app cannot load data from this source until the provider fixes it. Please contact $host.';
  }

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
  String get alertsLoadErrorTitle => 'Couldn\'t load your alerts';

  @override
  String get alertsBackgroundCheckErrorTitle => 'Alert background check failed';

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
      'Enter the device code from your other device to import its favorites, alerts, vehicles, and consumption log. Each device keeps its own profile and defaults.';

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
      '1. On Device A: copy the device code above\n2. On Device B: paste it in the \"Device code\" field\n3. Tap \"Import data\" to merge favorites, alerts, vehicles, and consumption logs\n4. Both devices will have all combined data\n\nEach device keeps its own anonymous identity and its own profile (preferred fuel, default vehicle, landing screen). Data is merged, not moved.';

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
  String get veResetConfirmTitle => 'Reset volumetric efficiency?';

  @override
  String get veResetConfirmBody =>
      'This will discard the learned volumetric efficiency (η_v) and restore the default value (0.85). Trip-level fuel-flow estimates will fall back to the manufacturer constant until the calibrator collects new samples from upcoming trips.';

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
  String get achievementSmoothDriver => 'Smooth streak';

  @override
  String get achievementSmoothDriverDesc =>
      'Drive 5 trips in a row with a smooth-driving score of 80 or higher.';

  @override
  String get achievementColdStartAware => 'Cold-start aware';

  @override
  String get achievementColdStartAwareDesc =>
      'Keep a whole month\'s cold-start fuel cost under 2 % of total fuel — combine short trips.';

  @override
  String get achievementHighwayMaster => 'Highway master';

  @override
  String get achievementHighwayMasterDesc =>
      'Complete a 30 km+ trip at consistent speed with a smooth-driving score of 90 or higher.';

  @override
  String get authErrorNoNetwork => 'No network connection. Try again later.';

  @override
  String get authErrorInvalidCredentials =>
      'Invalid email or password. Check your credentials.';

  @override
  String get authErrorUserAlreadyExists =>
      'This email is already registered. Try signing in instead.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please check your email and confirm your account first.';

  @override
  String get authErrorGeneric => 'Sign-in failed. Please try again.';

  @override
  String get autoRecordSectionTitle => 'Auto-record';

  @override
  String get autoRecordToggleLabel => 'Auto-record trips';

  @override
  String get autoRecordStatusActiveLabel =>
      'Auto-record will activate the next time you enter the car.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Pair an OBD2 adapter to enable auto-record.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Allow background location so auto-record keeps running with the screen off.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Pair an adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Start speed (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Save delay after disconnect (seconds)';

  @override
  String get autoRecordPairedAdapterLabel => 'Paired adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'No adapter paired. Pair one via the OBD2 onboarding first.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Background location allowed';

  @override
  String get autoRecordBackgroundLocationRequest => 'Request permission';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Why \"Allow all the time\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Auto-record streams GPS coordinates from the OBD-II foreground service while the screen is off so your trip route stays accurate. Android requires the \"Allow all the time\" option for that to keep working after the device locks.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Open settings';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Location permission required';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Could not request background location';

  @override
  String get autoRecordBadgeClearTooltip => 'Clear counter';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Pair an adapter in the section below to enable auto-recording';

  @override
  String get exportBackupTooltip => 'Export backup';

  @override
  String get exportBackupReady => 'Backup ready — pick a destination';

  @override
  String get exportBackupFailed => 'Backup export failed — please try again';

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
  String get gdprCommunityWaitTimeTitle => 'Community Wait Times';

  @override
  String get gdprCommunityWaitTimeShort =>
      'Anonymously share station wait times';

  @override
  String get gdprCommunityWaitTimeDescription =>
      'Anonymously share when you arrive at and leave a fuel station so the app can show typical wait times. No location coordinates are uploaded — only the station ID.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partial fills pending plein complet — not in average',
      one: '1 partial fill pending plein complet — not in average',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% of fuel from auto-corrections — review entries';
  }

  @override
  String get fillUpCorrectionLabel => 'Auto-correction — tap to edit';

  @override
  String get fillUpCorrectionEditTitle => 'Edit auto-correction';

  @override
  String get fillUpCorrectionEditExplainer =>
      'This entry was auto-generated to close the gap between recorded trips and pumped fuel. Adjust the values if you know the actual figures.';

  @override
  String get fillUpCorrectionDelete => 'Delete correction';

  @override
  String get fillUpCorrectionStation => 'Station name (optional)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Greece)';

  @override
  String get greeceCommunityApiNotice =>
      'Powered by the community-maintained fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Powered by pretcarburant.ro (Competition Council + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country stations $km km away — €$price/L cheaper';
  }

  @override
  String get crossBorderTapToSwitch => 'Tap to switch country';

  @override
  String get crossBorderDismissTooltip => 'Dismiss';

  @override
  String get insightCardTitle => 'Top wasteful behaviours';

  @override
  String get insightEmptyState => 'No notable inefficiencies — keep it up!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Engine over 3000 RPM ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count hard accelerations: wasted $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Idling ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% of trip';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Labouring in low gear ($minutes min)';
  }

  @override
  String get drivingScoreCardTitle => 'Driving score';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Composite score from idling, hard accelerations, hard braking, and high-RPM time. A \'better than X% of past trips\' comparison will land in a follow-up release.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Driving score $score out of 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Idling';

  @override
  String get drivingScorePenaltyHardAccel => 'Hard accelerations';

  @override
  String get drivingScorePenaltyHardBrake => 'Hard braking';

  @override
  String get drivingScorePenaltyHighRpm => 'High RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Full throttle';

  @override
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L saved';
  }

  @override
  String get ecoRouteHint =>
      'Smarter drive — favours steady highway over zigzag shortcuts.';

  @override
  String get favoritesShareAction => 'Share';

  @override
  String favoritesShareSubject(String date) {
    return 'Tankstellen — favourites on $date';
  }

  @override
  String get favoritesShareError => 'Couldn\'t generate share image';

  @override
  String get featureManagementSectionTitle => 'Feature management';

  @override
  String get featureManagementSectionSubtitle =>
      'Turn individual features on or off. Some features depend on others — switches are disabled until prerequisites are met.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2 trip recording';

  @override
  String get featureDescription_obd2TripRecording =>
      'Capture trips automatically over OBD2.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification =>
      'Driving scores and earned badges.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptic eco-coach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Real-time haptic feedback during a trip.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync => 'Cross-device sync via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Consumption analytics';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Fill-up and trip analysis tab.';

  @override
  String get featureLabel_baselineSync => 'Baseline sync';

  @override
  String get featureDescription_baselineSync =>
      'Sync driving baselines via TankSync.';

  @override
  String get featureLabel_unifiedSearchResults => 'Unified search results';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Single result list combining fuel and EV stations.';

  @override
  String get featureLabel_priceAlerts => 'Price alerts';

  @override
  String get featureDescription_priceAlerts =>
      'Threshold-based price-drop notifications.';

  @override
  String get featureLabel_priceHistory => 'Price history';

  @override
  String get featureDescription_priceHistory =>
      '30-day price charts on station details.';

  @override
  String get featureLabel_routePlanning => 'Route planning';

  @override
  String get featureDescription_routePlanning =>
      'Cheapest stop along your route.';

  @override
  String get featureLabel_evCharging => 'EV charging';

  @override
  String get featureDescription_evCharging =>
      'Charging stations via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling guidance using OSM traffic signals.';

  @override
  String get featureLabel_gpsTripPath => 'GPS trip path';

  @override
  String get featureDescription_gpsTripPath =>
      'Persist GPS path samples alongside each trip.';

  @override
  String get featureBlockedEnable_gamification =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_baselineSync => 'Enable TankSync first';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Enable OBD2 trip recording first';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Enable OBD2 trip recording first';

  @override
  String featureBlockedDisable_obd2TripRecording(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String featureBlockedDisable_tankSync(String dependents) {
    return 'Disable dependent features first: $dependents';
  }

  @override
  String get feedbackConsentTitle => 'Send report to GitHub?';

  @override
  String get feedbackConsentBody =>
      'This creates a public ticket on our GitHub repository with your photo and the OCR text. No personal data (location, account id) is sent. Continue?';

  @override
  String get feedbackConsentContinue => 'Continue';

  @override
  String get feedbackConsentCancel => 'Cancel';

  @override
  String get feedbackConsentLater => 'Later';

  @override
  String get feedbackTokenSectionTitle => 'Bad-scan feedback (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'To automatically open a GitHub ticket from a failed scan, paste a GitHub PAT (`public_repo` scope on the tankstellen repository). Otherwise manual sharing remains available.';

  @override
  String get feedbackTokenStatusSet => 'Token configured';

  @override
  String get feedbackTokenStatusUnset => 'No token';

  @override
  String get feedbackTokenSet => 'Set';

  @override
  String get feedbackTokenClear => 'Clear';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

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
  String get badScanReportTitleReceipt => 'Report a scan error — Receipt';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Report a scan error — Pump display';

  @override
  String get pumpScanFailureTitle => 'Display unreadable';

  @override
  String get pumpScanFailureBody =>
      'The scan couldn\'t read the pump display. What would you like to do?';

  @override
  String get pumpScanFailureCorrectManually => 'Correct manually';

  @override
  String get pumpScanFailureReport => 'Report';

  @override
  String get pumpScanFailureRemove => 'Remove photo';

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
  String get badScanReportCreateTicket => 'Create issue';

  @override
  String get badScanReportOpenInBrowser => 'Open in browser';

  @override
  String get badScanReportFallbackToShare => 'Submission failed — manual share';

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
  String get calibrationModeLabel => 'Calibration mode';

  @override
  String get calibrationModeRule => 'Rule-based';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Rule-based assigns each driving sample to exactly one situation. Fuzzy spreads it across all of them by how well each fits — smoother around 60 km/h or changing gradients, but slower to fill all buckets.';

  @override
  String get profileGamificationToggleTitle => 'Show achievements & scores';

  @override
  String get profileGamificationToggleSubtitle =>
      'When off, badges, scores and trophy icons are hidden across the app.';

  @override
  String get hapticEcoCoachSectionTitle => 'Driving';

  @override
  String get hapticEcoCoachSettingTitle => 'Real-time eco coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Gentle haptic + on-screen tip when you floor it during cruise';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Easy on the throttle — coasting saves more';

  @override
  String get loyaltySettingsTitle => 'Fuel club cards';

  @override
  String get loyaltySettingsSubtitle =>
      'Apply your loyalty discount to displayed prices';

  @override
  String get loyaltyMenuTitle => 'Fuel club cards';

  @override
  String get loyaltyMenuSubtitle =>
      'Apply per-litre discounts from Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Add card';

  @override
  String get loyaltyAddCardSheetTitle => 'Add fuel club card';

  @override
  String get loyaltyBrandLabel => 'Brand';

  @override
  String get loyaltyCardLabelLabel => 'Label (optional)';

  @override
  String get loyaltyDiscountLabel => 'Discount (per litre)';

  @override
  String get loyaltyDiscountInvalid => 'Enter a positive number';

  @override
  String get loyaltyDeleteConfirmTitle => 'Delete card?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'This card will stop applying its discount.';

  @override
  String get loyaltyEmptyTitle => 'No fuel club cards yet';

  @override
  String get loyaltyEmptyBody =>
      'Add a card to apply your per-litre discount to matching stations automatically.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle => 'Idle RPM creep detected';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Idle RPM has crept up by $percent% over your last $tripCount trips. Possible early sign of a clogged air filter or sensor drift.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Possible intake restriction';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Cruise fuel rate has dropped by $percent% over your last $tripCount trips. Possible sign of a clogged air filter or restricted intake — worth a check-up.';
  }

  @override
  String get maintenanceActionDismiss => 'Dismiss';

  @override
  String get maintenanceActionSnooze => 'Snooze 30 days';

  @override
  String get mapDebugOverlayEnabledSnack => 'Map debug overlay enabled';

  @override
  String get mapDebugOverlayDisabledSnack => 'Map debug overlay disabled';

  @override
  String get mapDebugOverlayClearButton => 'Clear';

  @override
  String get mapDebugOverlayCloseButton => 'Close';

  @override
  String get mapDebugOverlayTitle => 'Map breadcrumbs';

  @override
  String get consumptionMonthlyInsightsTitle => 'This month vs last month';

  @override
  String get consumptionMonthlyTripsLabel => 'Trips';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Drive time';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distance';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Avg consumption';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Need at least 3 trips per month for comparison';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Couldn\'t reach \'$adapterName\' — pick another adapter';
  }

  @override
  String get onboardingObd2StepTitle => 'Connect your OBD2 adapter';

  @override
  String get onboardingObd2StepBody =>
      'Plug your OBD2 adapter into the car\'s port and turn the ignition on. We\'ll read the VIN and fill in engine details for you.';

  @override
  String get onboardingObd2ConnectButton => 'Connect adapter';

  @override
  String get onboardingObd2SkipButton => 'Maybe later';

  @override
  String get onboardingObd2ReadingVin => 'Reading VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Couldn\'t read VIN — enter manually';

  @override
  String get onboardingObd2ConnectFailed =>
      'Couldn\'t connect to the adapter. You can retry or skip.';

  @override
  String get alertsRadiusFrequencyLabel => 'Check frequency';

  @override
  String get alertsRadiusFrequencyDaily => 'Once a day';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Twice a day';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Three times a day';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Four times a day';

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
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/session';

  @override
  String get speedConsumptionCardTitle => 'Consumption by speed';

  @override
  String get speedBandIdleJam => 'Idle / jam';

  @override
  String get speedBandUrban => 'Urban (10–50)';

  @override
  String get speedBandSuburban => 'Suburban (50–80)';

  @override
  String get speedBandRural => 'Rural (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-cruise (100–115)';

  @override
  String get speedBandMotorway => 'Motorway (115–130)';

  @override
  String get speedBandMotorwayFast => 'Motorway fast (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Record 30+ minutes of trips with the OBD2 adapter to unlock the speed/consumption analysis.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % of driving';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Need more data';

  @override
  String get splashLoadingLabel => 'Loading Tankstellen';

  @override
  String get tankLevelTitle => 'Tank level';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km of range';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Last fill-up: $date · $count trip(s) since';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 measured';

  @override
  String get tankLevelMethodDistanceFallback => 'distance-based estimate';

  @override
  String get tankLevelMethodMixed => 'mixed measurement';

  @override
  String get tankLevelEmptyNoFillUp => 'Log a fill-up to see your tank level';

  @override
  String get tankLevelDetailSheetTitle => 'Trips since last fill-up';

  @override
  String get addFillUpIsFullTankLabel => 'Full tank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tank filled to the brim — uncheck if this was a partial fill';

  @override
  String get themeCardTitle => 'Theme';

  @override
  String get themeCardSubtitleSystem => 'System';

  @override
  String get themeCardSubtitleLight => 'Light';

  @override
  String get themeCardSubtitleDark => 'Dark';

  @override
  String get themeSettingsScreenTitle => 'Theme';

  @override
  String get themeSettingsSystemLabel => 'Follow system';

  @override
  String get themeSettingsLightLabel => 'Light';

  @override
  String get themeSettingsDarkLabel => 'Dark';

  @override
  String get themeSettingsSystemDescription =>
      'Match the current device appearance.';

  @override
  String get themeSettingsLightDescription =>
      'Bright backgrounds — best for daytime use.';

  @override
  String get themeSettingsDarkDescription =>
      'Dark backgrounds — easier on the eyes at night and saves battery on OLED screens.';

  @override
  String get throttleRpmHistogramTitle => 'How you used the engine';

  @override
  String get throttleRpmHistogramThrottleSection => 'Throttle position';

  @override
  String get throttleRpmHistogramRpmSection => 'Engine RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Coast (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Light (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Firm (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Wide-open (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Idle (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Cruise (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Spirited (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Hard (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'No throttle or RPM samples in this trip.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Trips';

  @override
  String get trajetsStartRecordingButton => 'Start recording';

  @override
  String get trajetsResumeRecordingButton => 'Resume recording';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Connecting to OBD2 adapter…';

  @override
  String get tripStartProgressReadingVehicleData => 'Reading vehicle data…';

  @override
  String get tripStartProgressStartingRecording => 'Starting recording…';

  @override
  String get trajetsEmptyStateTitle => 'No trips yet';

  @override
  String get trajetsEmptyStateBody =>
      'Tap Start recording to begin logging your drives.';

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
  String get trajetDetailSummaryTitle => 'Summary';

  @override
  String get trajetDetailFieldDate => 'Date';

  @override
  String get trajetDetailFieldVehicle => 'Vehicle';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adapter';

  @override
  String get trajetDetailFieldDistance => 'Distance';

  @override
  String get trajetDetailFieldDuration => 'Duration';

  @override
  String get trajetDetailFieldAvgConsumption => 'Avg consumption';

  @override
  String get trajetDetailFieldFuelUsed => 'Fuel used';

  @override
  String get trajetDetailFieldFuelCost => 'Fuel cost';

  @override
  String get trajetDetailFieldAvgSpeed => 'Avg speed';

  @override
  String get trajetDetailFieldMaxSpeed => 'Max speed';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Speed (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Fuel rate (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Engine load (%)';

  @override
  String get trajetsRowColdStartChip => 'Cold start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Engine didn\'t reach operating temperature during this trip — fuel consumption was higher than usual.';

  @override
  String get trajetDetailChartEmpty => 'No samples recorded';

  @override
  String get trajetDetailShareAction => 'Share';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Tankstellen — trip on $date';
  }

  @override
  String get trajetDetailShareError => 'Couldn\'t generate share image';

  @override
  String get trajetDetailDeleteAction => 'Delete';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Delete this trip?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'This trip will be permanently removed from your history.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Cancel';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Delete';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapter connected but not returning data. Try a different adapter or check the vehicle\'s diagnostic protocol.';

  @override
  String get tripLengthCardTitle => 'Consumption by trip length';

  @override
  String get tripLengthBucketShort => 'Short (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Medium (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Long (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Need more data';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
      zero: 'no trips',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Trip path';

  @override
  String get tripPathCardSubtitle => 'GPS-recorded route';

  @override
  String get tripPathLegendTitle => 'Consumption';

  @override
  String get tripPathLegendEfficient => 'Efficient (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Borderline (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Wasteful (≥ 10 L/100km)';

  @override
  String get tripRecordingPinTooltip =>
      'Pinning keeps the screen on — uses more battery';

  @override
  String get tripRecordingPinSemanticOn => 'Unpin recording form';

  @override
  String get tripRecordingPinSemanticOff => 'Pin recording form';

  @override
  String get tripRecordingPinHelpTooltip => 'What does pin do?';

  @override
  String get tripRecordingPinHelpTitle => 'About pin';

  @override
  String get tripRecordingPinHelpBody =>
      'Pin keeps the screen on and hides system bars so the form stays readable on a dashboard mount. Tap again to release. Auto-releases when the trip stops.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Recording continues in the background. Tap the red banner at the top of any screen to return.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Open the active trip from the Conso tab';

  @override
  String get unifiedFilterFuel => 'Fuel';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Both';

  @override
  String get unifiedNoResultsForFilter => 'No results match this filter';

  @override
  String get vinLabel => 'VIN (optional)';

  @override
  String get vinDecodeTooltip => 'Decode VIN';

  @override
  String get vinConfirmAction => 'Yes, auto-fill';

  @override
  String get vinModifyAction => 'Modify manually';

  @override
  String get veResetAction => 'Reset volumetric efficiency';

  @override
  String get vehicleReadVinFromCarButton => 'Read VIN from car';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Read VIN from the paired OBD2 adapter';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN not available (Mode 09 PID 02 unsupported on pre-2005 vehicles)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN read failed — please enter manually';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Pair an OBD2 adapter first to read VIN automatically';

  @override
  String get vinInfoTooltip => 'What is a VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'What is a VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'The Vehicle Identification Number is a 17-character code unique to your car. It\'s stamped on the chassis and printed on your vehicle registration document.';

  @override
  String get vinInfoSectionWhyTitle => 'Why we ask';

  @override
  String get vinInfoSectionWhyBody =>
      'Decoding the VIN auto-fills engine displacement, cylinder count, model year, primary fuel type, and gross weight — saving you from looking up technical specs manually. The OBD2 fuel-rate calculation uses these values to give you accurate consumption numbers.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacy';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Your VIN is stored only locally in the app\'s encrypted storage — it\'s never uploaded to Tankstellen servers. The NHTSA vPIC database is queried with the VIN but returns only anonymous technical specs; NHTSA does not link the VIN to any personal data. Without network, an offline lookup returns manufacturer and country only.';

  @override
  String get vinInfoSectionWhereTitle => 'Where to find it';

  @override
  String get vinInfoSectionWhereBody =>
      'Look through the windshield at the lower-left corner on the driver\'s side, check the driver-side door-frame sticker when the door is open, or read it off your vehicle registration document (card / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Got it';

  @override
  String get vinConfirmPrivacyNote =>
      'We looked up your VIN on NHTSA\'s free vehicle database — nothing sent to Tankstellen servers.';

  @override
  String get widgetVariantDefault => 'Current price only';

  @override
  String get widgetVariantPredictive => 'Predictive: best time to fill';

  @override
  String get widgetPredictiveNowPrefix => 'now';
}
