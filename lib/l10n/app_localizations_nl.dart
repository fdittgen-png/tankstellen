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
}
