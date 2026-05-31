// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Zoeken openen';

  @override
  String get fabOpenResults => 'Resultaten openen';

  @override
  String get fabRunSearch => 'Zoekopdracht uitvoeren';

  @override
  String get fabRefineCriteria => 'Zoekopdracht verfijnen';

  @override
  String get routeSearchPartialBanner => 'Zoekt naar meer stations…';

  @override
  String get searchCriteriaTitle => 'Zoekcriteria';

  @override
  String get searchCriteriaOpen => 'Zoeken';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Binnen $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tik om te zoeken';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Van land wisselen?';

  @override
  String countryChangeBody(String country) {
    return 'Overschakelen naar $country wijzigt:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Afstand';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Prijsindeling';

  @override
  String get countryChangeNote =>
      'Bestaande favorieten en tankbeurten worden niet herschreven; alleen nieuwe invoer gebruikt de nieuwe eenheden.';

  @override
  String get countryChangeConfirm => 'Wisselen';

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
  String get cacheTtlGroupNetwork => 'Netwerk';

  @override
  String get cacheTtlGroupData => 'Gegevens';

  @override
  String get cacheTtlGroupGeocoding => 'Geocodering';

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
  String get reportThisIssue => 'Probleem melden';

  @override
  String get reportAlreadySent => 'Je hebt dit probleem al gemeld.';

  @override
  String get reportConsentTitle => 'Melden via GitHub?';

  @override
  String get reportConsentBody =>
      'Hiermee wordt een openbaar GitHub-issue aangemaakt met de onderstaande foutdetails. Er worden geen GPS-coördinaten, API-sleutels of persoonsgegevens meegestuurd.';

  @override
  String get reportConsentConfirm => 'GitHub openen';

  @override
  String get reportConsentCancel => 'Annuleren';

  @override
  String get configProfileSection => 'Profiel';

  @override
  String get configActiveProfile => 'Actief profiel';

  @override
  String get configPreferredFuel => 'Voorkeursbrandstof';

  @override
  String get configCountry => 'Land';

  @override
  String get configRouteSegment => 'Routegedeelte';

  @override
  String get configApiKeysSection => 'API-sleutels';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-sleutel';

  @override
  String get configApiKeyConfigured => 'Geconfigureerd';

  @override
  String get configApiKeyNotSet => 'Niet ingesteld (demomodus)';

  @override
  String get configApiKeyCommunity => 'Standaard (communitysleutel)';

  @override
  String get searchLocationPlaceholder => 'Adres, postcode of stad';

  @override
  String get configEvKey => 'EV-laad API-sleutel';

  @override
  String get configEvKeyCustom => 'Eigen sleutel';

  @override
  String get configEvKeyShared => 'Standaard (gedeeld)';

  @override
  String get configCloudSyncSection => 'Cloudsynchronisatie';

  @override
  String get configTankSyncConnected => 'Verbonden';

  @override
  String get configTankSyncDisabled => 'Uitgeschakeld';

  @override
  String get configAuthMode => 'Verificatiemodus';

  @override
  String get configAuthEmail => 'E-mail (permanent)';

  @override
  String get configAuthAnonymous => 'Anoniem (alleen apparaat)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Privacyoverzicht';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favorieten, meldingen en verborgen stations worden gesynchroniseerd naar je privédatabase\n• GPS-positie en API-sleutels verlaten je apparaat nooit\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Alle gegevens worden alleen lokaal op dit apparaat opgeslagen\n• Er worden geen gegevens naar een server gestuurd\n• API-sleutels versleuteld in beveiligde apparaatopslag';

  @override
  String get configAuthNoteEmail =>
      'E-mailaccount maakt toegang via meerdere apparaten mogelijk';

  @override
  String get configAuthNoteAnonymous =>
      'Anoniem account — gegevens gekoppeld aan dit apparaat';

  @override
  String get configNone => 'Geen';

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
  String get demoModeBannerAction => 'Actuele prijzen ophalen';

  @override
  String get sortDistance => 'Afstand';

  @override
  String get sortOpen24h => '24u';

  @override
  String get sortRating => 'Beoordeling';

  @override
  String get sortPriceDistance => 'Prijs/km';

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
  String get routeModeBannerLabel =>
      'Routemodus — afstanden zijn langs het traject';

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
  String get routePlanningSection => 'Routeplanning';

  @override
  String get routeMinSaving => 'Minimale besparing';

  @override
  String get routeMinSavingOff => 'Uit';

  @override
  String get routeMinSavingOffCaption =>
      'Toont alle gevonden stations langs de route';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Alleen stations binnen $amount van de goedkoopste op de route';
  }

  @override
  String get routeDetourBudget => 'Maximale omweg';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Toon stations tot $km km van je directe route';
  }

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
  String get ignoredStationsLabel => 'Genegeerd';

  @override
  String get ratingsLabel => 'Beoordelingen';

  @override
  String get favoritesDataCache => 'Favorietengegevens';

  @override
  String get citySearchCache => 'Plaatszoeken';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Gegevens verwijderen is niet beschikbaar in de Community-modus. Verbreek eerst de verbinding of gebruik een privédatabase.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count gevolgde stations';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count geconfigureerd';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count verborgen stations';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count beoordeelde stations';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Alle gesynchroniseerde ritten verwijderen';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Alle gesynchroniseerde ritten verwijderen?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Alle ritoverzichten en detailgegevens worden van de server verwijderd. Je lokale ritgeschiedenis op dit apparaat wordt niet beïnvloed.\n\nDeze actie kan niet ongedaan worden gemaakt.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Alles verwijderen';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Alle gesynchroniseerde ritten van server verwijderd';

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
  String get syncedTrips => 'Ritten';

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
  String get continueAsGuest => 'Doorgaan als gast';

  @override
  String get createAccount => 'Account aanmaken';

  @override
  String get signIn => 'Aanmelden';

  @override
  String get upgradeToEmail => 'E-mailaccount aanmaken';

  @override
  String get savedRoutes => 'Opgeslagen routes';

  @override
  String get noSavedRoutes => 'Geen opgeslagen routes';

  @override
  String get noSavedRoutesHint =>
      'Zoek langs een route en sla hem op voor snelle toegang later.';

  @override
  String get saveRoute => 'Route opslaan';

  @override
  String get routeName => 'Routenaam';

  @override
  String itineraryDeleted(String name) {
    return '$name verwijderd';
  }

  @override
  String loadingRoute(String name) {
    return 'Route laden: $name';
  }

  @override
  String get refreshFailed => 'Vernieuwen mislukt. Probeer het opnieuw.';

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
  String get onboardingWelcomeHint => 'Stel de app in een paar stappen in.';

  @override
  String get onboardingApiKeyDescription =>
      'Registreer voor een gratis API-sleutel, of sla dit over om de app met demogegevens te verkennen.';

  @override
  String get onboardingComplete => 'Klaar!';

  @override
  String get onboardingCompleteHint =>
      'Je kunt deze instellingen altijd aanpassen in je profiel.';

  @override
  String get onboardingBack => 'Terug';

  @override
  String get onboardingNext => 'Volgende';

  @override
  String get onboardingSkip => 'Overslaan';

  @override
  String get onboardingFinish => 'Aan de slag';

  @override
  String crossBorderNearby(String country) {
    return '$country is dichtbij';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km tot grens';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Gemiddeld hier: $price EUR ($count stations)';
  }

  @override
  String get allPricesView => 'Alle prijzen';

  @override
  String get compactView => 'Compact';

  @override
  String get switchToAllPricesView => 'Overschakelen naar alle-prijzenweergave';

  @override
  String get switchToCompactView => 'Overschakelen naar compacte weergave';

  @override
  String get unavailable => 'N.v.t.';

  @override
  String get outOfStock => 'Niet beschikbaar';

  @override
  String get gdprTitle => 'Jouw privacy';

  @override
  String get gdprSubtitle =>
      'Deze app respecteert je privacy. Kies welke gegevens je wilt delen. Je kunt deze instellingen altijd wijzigen.';

  @override
  String get gdprLocationTitle => 'Locatietoegang';

  @override
  String get gdprLocationDescription =>
      'Je coördinaten worden naar de brandstofprijs-API gestuurd om nabijgelegen stations te vinden. Locatiegegevens worden nooit op een server opgeslagen en worden niet gebruikt voor tracking.';

  @override
  String get gdprLocationShort =>
      'Zoek nabijgelegen tankstations op basis van je locatie';

  @override
  String get gdprErrorReportingTitle => 'Foutrapportage';

  @override
  String get gdprErrorReportingDescription =>
      'Anonieme crashrapporten helpen de app te verbeteren. Er worden geen persoonsgegevens meegestuurd. Rapporten worden alleen via Sentry verstuurd als dit geconfigureerd is.';

  @override
  String get gdprErrorReportingShort =>
      'Anonieme crashrapporten versturen om de app te verbeteren';

  @override
  String get gdprCloudSyncTitle => 'Cloudsynchronisatie';

  @override
  String get gdprCloudSyncDescription =>
      'Synchroniseer favorieten en meldingen via TankSync. Maakt gebruik van anonieme verificatie. Je gegevens zijn versleuteld in transit.';

  @override
  String get gdprCloudSyncShort =>
      'Favorieten en meldingen synchroniseren via apparaten';

  @override
  String get gdprLegalBasis =>
      'Rechtsgrond: art. 6 lid 1 sub a AVG (toestemming). Je kunt toestemming te allen tijde intrekken via Instellingen.';

  @override
  String get gdprAcceptAll => 'Alles accepteren';

  @override
  String get gdprAcceptSelected => 'Selectie accepteren';

  @override
  String get gdprSettingsHint =>
      'Je kunt je privacykeuzes op elk moment wijzigen.';

  @override
  String get routeSaved => 'Route opgeslagen!';

  @override
  String get routeSaveFailed => 'Route opslaan mislukt';

  @override
  String get sqlCopied => 'SQL gekopieerd naar klembord';

  @override
  String get connectionDataCopied => 'Verbindingsgegevens gekopieerd';

  @override
  String get accountDeleted => 'Account verwijderd. Lokale gegevens bewaard.';

  @override
  String get switchedToAnonymous => 'Overgeschakeld naar anonieme sessie';

  @override
  String failedToSwitch(String error) {
    return 'Overschakelen mislukt: $error';
  }

  @override
  String get topicUrlCopied => 'Onderwerp-URL gekopieerd';

  @override
  String get testNotificationSent => 'Testmelding verzonden!';

  @override
  String get testNotificationFailed => 'Testmelding versturen mislukt';

  @override
  String get pushUpdateFailed =>
      'Instelling voor pushmeldingen bijwerken mislukt';

  @override
  String get connectedAsGuest => 'Verbonden als gast';

  @override
  String get accountCreated => 'Account aangemaakt!';

  @override
  String get signedIn => 'Aangemeld!';

  @override
  String stationHidden(String name) {
    return '$name verborgen';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name verwijderd uit favorieten';
  }

  @override
  String invalidApiKey(String error) {
    return 'Ongeldige API-sleutel: $error';
  }

  @override
  String get invalidQrCode => 'Ongeldig QR-codeformaat';

  @override
  String get invalidQrCodeTankSync =>
      'Ongeldige QR-code — TankSync-formaat verwacht';

  @override
  String get tankSyncConnected => 'TankSync verbonden!';

  @override
  String get syncCompleted => 'Synchronisatie voltooid — gegevens vernieuwd';

  @override
  String get deviceCodeCopied => 'Apparaatcode gekopieerd';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Voer een geldige $length-cijferige $label in';
  }

  @override
  String get freshnessAgo => 'geleden';

  @override
  String get freshnessStale => 'Verouderd';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Gegevensversheid: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand-logo';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Geef $count sterren',
      one: 'Geef 1 ster',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Zwak';

  @override
  String get passwordStrengthFair => 'Matig';

  @override
  String get passwordStrengthStrong => 'Sterk';

  @override
  String get passwordReqMinLength => 'Minimaal 8 tekens';

  @override
  String get passwordReqUppercase => 'Minimaal 1 hoofdletter';

  @override
  String get passwordReqLowercase => 'Minimaal 1 kleine letter';

  @override
  String get passwordReqDigit => 'Minimaal 1 cijfer';

  @override
  String get passwordReqSpecial => 'Minimaal 1 speciaal teken';

  @override
  String get passwordTooWeak => 'Wachtwoord voldoet niet aan alle vereisten';

  @override
  String get brandFilterAll => 'Alle';

  @override
  String get brandFilterNoHighway => 'Geen snelweg';

  @override
  String get swipeTutorialMessage =>
      'Veeg rechts om te navigeren, veeg links om te verwijderen';

  @override
  String get swipeTutorialDismiss => 'Begrepen';

  @override
  String get alertStatsActive => 'Actief';

  @override
  String get alertStatsToday => 'Vandaag';

  @override
  String get alertStatsThisWeek => 'Deze week';

  @override
  String get privacyDashboardTitle => 'Privacydashboard';

  @override
  String get privacyDashboardSubtitle =>
      'Bekijk, exporteer of verwijder je gegevens';

  @override
  String get privacyDashboardBanner =>
      'Je gegevens zijn van jou. Hier zie je alles wat de app opslaat — je kunt het exporteren of verwijderen.';

  @override
  String get privacyLocalData => 'Gegevens op dit apparaat';

  @override
  String get privacyIgnoredStations => 'Verborgen stations';

  @override
  String get privacyRatings => 'Stationbeoordelingen';

  @override
  String get privacyPriceHistory => 'Prijsgeschiedenisstations';

  @override
  String get privacyProfiles => 'Zoekprofielen';

  @override
  String get privacyItineraries => 'Opgeslagen routes';

  @override
  String get privacyCacheEntries => 'Cachegegevens';

  @override
  String get privacyApiKey => 'API-sleutel opgeslagen';

  @override
  String get privacyEvApiKey => 'EV API-sleutel opgeslagen';

  @override
  String get privacyEstimatedSize => 'Geschatte opslag';

  @override
  String get privacySyncedData => 'Cloudsync (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Cloudsync is uitgeschakeld. Alle gegevens blijven alleen op dit apparaat.';

  @override
  String get privacySyncMode => 'Synchronisatiemodus';

  @override
  String get privacySyncUserId => 'Gebruikers-ID';

  @override
  String get privacySyncDescription =>
      'Als synchronisatie is ingeschakeld, worden favorieten, meldingen, verborgen stations en beoordelingen ook op de TankSync-server opgeslagen.';

  @override
  String get privacyViewServerData => 'Servergegevens bekijken';

  @override
  String get privacyExportButton => 'Alle gegevens exporteren als JSON';

  @override
  String get privacyExportSuccess => 'Gegevens geëxporteerd naar klembord';

  @override
  String get privacyExportCsvButton => 'Alle gegevens exporteren als CSV';

  @override
  String get privacyExportCsvSuccess =>
      'CSV-gegevens geëxporteerd naar klembord';

  @override
  String get savedToDownloadsFolder => 'Opgeslagen in de map Downloads';

  @override
  String get privacyDeleteButton => 'Alle gegevens verwijderen';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Foutlogboek kopiëren naar klembord ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Foutenlogboek opslaan ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Foutenlogboek wissen';

  @override
  String get privacyErrorLogCleared => 'Foutenlogboek gewist';

  @override
  String get privacyDeleteTitle => 'Alle gegevens verwijderen?';

  @override
  String get privacyDeleteBody =>
      'Dit verwijdert permanent:\n\n- Alle favorieten en stationgegevens\n- Alle zoekprofielen\n- Alle prijsmeldingen\n- Alle prijsgeschiedenis\n- Alle gecachede gegevens\n- Je API-sleutel\n- Alle app-instellingen\n\nDe app wordt teruggezet naar de beginstatus. Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get privacyDeleteConfirm => 'Alles verwijderen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nee';

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
  String get paymentMethods => 'Betaalmethoden';

  @override
  String get paymentMethodCash => 'Contant';

  @override
  String get paymentMethodCard => 'Kaart';

  @override
  String get paymentMethodContactless => 'Contactloos';

  @override
  String get paymentMethodFuelCard => 'Tankpas';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Betalen met $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Vergeleken met het voortschrijdend gemiddelde van je laatste 3 tankbeurten ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Verbruik $value L/100 km, $delta ten opzichte van je voortschrijdend gemiddelde';
  }

  @override
  String get drivingMode => 'Rijmodus';

  @override
  String get drivingExit => 'Verlaten';

  @override
  String get drivingNearestStation => 'Dichtstbijzijnde';

  @override
  String get drivingTapToUnlock => 'Tik om te ontgrendelen';

  @override
  String get drivingSafetyTitle => 'Veiligheidswaarschuwing';

  @override
  String get drivingSafetyMessage =>
      'Bedien de app niet tijdens het rijden. Parkeer op een veilige plek voordat je het scherm gebruikt. De bestuurder is altijd verantwoordelijk voor de veilige bediening van het voertuig.';

  @override
  String get drivingSafetyAccept => 'Ik begrijp het';

  @override
  String get voiceAnnouncementsTitle => 'Gesproken aankondigingen';

  @override
  String get voiceAnnouncementsDescription =>
      'Goedkope stations in de buurt aankondigen tijdens het rijden';

  @override
  String get voiceAnnouncementsEnabled =>
      'Gesproken aankondigingen inschakelen';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Alleen onder $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometer verderop, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Aankondigingsstraal';

  @override
  String get voiceAnnouncementCooldown => 'Herhalingsinterval';

  @override
  String get nearestStations => 'Dichtstbijzijnde stations';

  @override
  String get nearestStationsHint =>
      'Vind de dichtstbijzijnde stations met uw huidige locatie';

  @override
  String get consumptionLogTitle => 'Brandstofverbruik';

  @override
  String get consumptionLogMenuTitle => 'Verbruikslogboek';

  @override
  String get consumptionLogMenuSubtitle =>
      'Tankbeurten bijhouden en L/100km berekenen';

  @override
  String get consumptionStatsTitle => 'Verbruiksstatistieken';

  @override
  String get addFillUp => 'Tankbeurt toevoegen';

  @override
  String get noFillUpsTitle => 'Nog geen tankbeurten';

  @override
  String get noFillUpsSubtitle =>
      'Registreer je eerste tankbeurt om het verbruik bij te houden.';

  @override
  String get fillUpDate => 'Datum';

  @override
  String get liters => 'Liters';

  @override
  String get odometerKm => 'Kilometerstand (km)';

  @override
  String get notesOptional => 'Notities (optioneel)';

  @override
  String get stationPreFilled => 'Station vooringevuld';

  @override
  String get statAvgConsumption => 'Gem. L/100km';

  @override
  String get statAvgCostPerKm => 'Gem. kosten/km';

  @override
  String get statTotalLiters => 'Totaal liters';

  @override
  String get statTotalSpent => 'Totaal uitgegeven';

  @override
  String get statFillUpCount => 'Tankbeurten';

  @override
  String get fieldRequired => 'Verplicht';

  @override
  String get fieldInvalidNumber => 'Ongeldig getal';

  @override
  String get carbonDashboardTitle => 'CO2-dashboard';

  @override
  String get carbonEmptyTitle => 'Nog geen gegevens';

  @override
  String get carbonEmptySubtitle =>
      'Registreer tankbeurten om je CO2-dashboard te zien.';

  @override
  String get carbonSummaryTotalCost => 'Totale kosten';

  @override
  String get carbonSummaryTotalCo2 => 'Totale CO2';

  @override
  String get monthlyCostsTitle => 'Maandelijkse kosten';

  @override
  String get monthlyEmissionsTitle => 'Maandelijkse CO2-uitstoot';

  @override
  String get vehiclesTitle => 'Mijn voertuigen';

  @override
  String get vehiclesMenuTitle => 'Mijn voertuigen';

  @override
  String get vehiclesMenuSubtitle => 'Accu, connectoren, laadvoorkeuren';

  @override
  String get vehiclesEmptyMessage =>
      'Voeg je auto toe om te filteren op connector en laadkosten te berekenen.';

  @override
  String get vehiclesWizardTitle => 'Mijn voertuigen (optioneel)';

  @override
  String get vehiclesWizardSubtitle =>
      'Voeg je auto toe om het verbruikslogboek voor te vullen en EV-connectorfilters in te schakelen. Je kunt dit overslaan en later voertuigen toevoegen.';

  @override
  String get vehiclesWizardNoneYet => 'Nog geen voertuig geconfigureerd.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voertuigen',
      one: '1 voertuig',
    );
    return 'Je hebt $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Overslaan om de setup te voltooien — je kunt voertuigen altijd toevoegen via Instellingen.';

  @override
  String get fillUpVehicleLabel => 'Voertuig';

  @override
  String get fillUpVehicleNone => 'Geen voertuig';

  @override
  String get fillUpVehicleRequired => 'Voertuig is verplicht';

  @override
  String get reportScanError => 'Scanfout melden';

  @override
  String get pickStationTitle => 'Kies een station';

  @override
  String get pickStationHelper =>
      'Start de tankbeurt vanuit een bekend station zodat prijzen, merk en brandstoftype automatisch worden ingevuld.';

  @override
  String get pickStationEmpty =>
      'Nog geen favoriete stations — voeg ze toe via Zoeken of Favorieten, of sla dit over en vul handmatig in.';

  @override
  String get pickStationSkip => 'Overslaan — toevoegen zonder station';

  @override
  String get scanPump => 'Pomp scannen';

  @override
  String get scanPayment => 'Betaal-QR scannen';

  @override
  String get qrPaymentBeneficiary => 'Begunstigde';

  @override
  String get qrPaymentAmount => 'Bedrag';

  @override
  String get qrPaymentEpcTitle => 'SEPA-betaling';

  @override
  String get qrPaymentEpcEmpty => 'Geen velden gedecodeerd';

  @override
  String get qrPaymentOpenInBank => 'Openen in bank-app';

  @override
  String get qrPaymentLaunchFailed =>
      'Geen app beschikbaar om deze code te openen';

  @override
  String get qrPaymentUnknownTitle => 'Niet-herkende code';

  @override
  String get qrPaymentCopyRaw => 'Ruwe tekst kopiëren';

  @override
  String get qrPaymentCopiedRaw => 'Gekopieerd naar klembord';

  @override
  String get qrPaymentReport => 'Deze scan melden';

  @override
  String get qrPaymentEpcCopied =>
      'Bankgegevens gekopieerd — plak in je bank-app';

  @override
  String get qrScannerGuidance => 'Richt de camera op een QR-code';

  @override
  String get qrScannerPermissionDenied =>
      'Cameratoegang is nodig om QR-codes te scannen.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Cameratoegang is geweigerd. Open instellingen om het te verlenen.';

  @override
  String get qrScannerRetryPermission => 'Opnieuw proberen';

  @override
  String get qrScannerOpenSettings => 'Instellingen openen';

  @override
  String get qrScannerTimeout =>
      'Geen QR-code gedetecteerd. Ga dichter bij of probeer opnieuw.';

  @override
  String get qrScannerRetry => 'Opnieuw proberen';

  @override
  String get torchOn => 'Flits inschakelen';

  @override
  String get torchOff => 'Flits uitschakelen';

  @override
  String get obdNoAdapter => 'Geen OBD2-adapter bereikbaar';

  @override
  String get obdOdometerUnavailable => 'Kilometerstand niet uitlesbaar';

  @override
  String get obdPermissionDenied =>
      'Geef Bluetooth-toestemming in systeeminstellingen';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter reageert niet — zet het contact aan en probeer opnieuw';

  @override
  String get obdPickerTitle => 'Kies een OBD2-adapter';

  @override
  String get obdPickerScanning => 'Zoeken naar adapters…';

  @override
  String get obdPickerConnecting => 'Verbinden…';

  @override
  String get themeSettingTitle => 'Thema';

  @override
  String get themeModeLight => 'Licht';

  @override
  String get themeModeDark => 'Donker';

  @override
  String get themeModeSystem => 'Systeem volgen';

  @override
  String get tripRecordingTitle => 'Rit opnemen';

  @override
  String get tripSummaryTitle => 'Ritoverzicht';

  @override
  String get tripMetricDistance => 'Afstand';

  @override
  String get tripMetricSpeed => 'Snelheid';

  @override
  String get tripMetricFuelUsed => 'Gebruikt brandstof';

  @override
  String get tripMetricAvgConsumption => 'Gem.';

  @override
  String get tripMetricElapsed => 'Verstreken';

  @override
  String get tripMetricOdometer => 'Kilometerstand';

  @override
  String get tripStop => 'Opname stoppen';

  @override
  String get tripPause => 'Pauzeren';

  @override
  String get tripResume => 'Hervatten';

  @override
  String get tripBannerRecording => 'Rit wordt opgenomen';

  @override
  String get tripBannerPaused => 'Rit gepauzeerd — tik om te hervatten';

  @override
  String get navConsumption => 'Verbruik';

  @override
  String get vehicleBaselineSectionTitle => 'Basiskalibratie';

  @override
  String get vehicleBaselineEmpty =>
      'Nog geen steekproeven — start een OBD2-rit om het brandstofprofiel van dit voertuig te leren.';

  @override
  String get vehicleBaselineProgress =>
      'Geleerd uit steekproeven in verschillende rijsituaties.';

  @override
  String get vehicleBaselineReset => 'Rijsituatie-baseline resetten';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Rijsituatie-baseline resetten?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Dit wist alle geleerde steekproeven voor dit voertuig. Je valt terug op de standaardwaarden bij koude start totdat nieuwe ritten het profiel aanvullen.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Geen adapter gekoppeld. Koppel een adapter zodat de app automatisch opnieuw verbinding maakt.';

  @override
  String get vehicleAdapterUnnamed => 'Onbekende adapter';

  @override
  String get vehicleAdapterPair => 'Adapter koppelen';

  @override
  String get vehicleAdapterForget => 'Adapter vergeten';

  @override
  String get achievementsTitle => 'Prestaties';

  @override
  String get achievementFirstTrip => 'Eerste rit';

  @override
  String get achievementFirstTripDesc => 'Neem je eerste OBD2-rit op.';

  @override
  String get achievementFirstFillUp => 'Eerste tankbeurt';

  @override
  String get achievementFirstFillUpDesc => 'Registreer je eerste tankbeurt.';

  @override
  String get achievementTenTrips => '10 ritten';

  @override
  String get achievementTenTripsDesc => 'Neem 10 OBD2-ritten op.';

  @override
  String get achievementZeroHarsh => 'Soepele rijder';

  @override
  String get achievementZeroHarshDesc =>
      'Voltooi een rit van 10 km of meer zonder hard remmen of hard optrekken.';

  @override
  String get achievementEcoWeek => 'Ecoweek';

  @override
  String get achievementEcoWeekDesc =>
      'Rij 7 opeenvolgende dagen met elke dag minstens één soepele rit.';

  @override
  String get achievementPriceWin => 'Prijsvoordeel';

  @override
  String get achievementPriceWinDesc =>
      'Registreer een tankbeurt die 5% of meer onder het 30-daags gemiddelde van het station ligt.';

  @override
  String get syncBaselinesToggleTitle => 'Geleerde voertuigprofielen delen';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Upload verbruiksbaselines per voertuig zodat een tweede apparaat ze kan hergebruiken.';

  @override
  String get obd2StatusConnected => 'OBD2-adapter: verbonden';

  @override
  String get obd2StatusAttempting => 'OBD2-adapter: verbinden';

  @override
  String get obd2StatusUnreachable => 'OBD2-adapter: niet bereikbaar';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-toestemming vereist';

  @override
  String get obd2StatusConnectedBody => 'Klaar om een rit op te nemen.';

  @override
  String get obd2StatusAttemptingBody => 'Verbinden op de achtergrond…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter buiten bereik of al in gebruik door een andere app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Geef Bluetooth-toestemming in systeeminstellingen om automatisch opnieuw te verbinden.';

  @override
  String get obd2StatusNoAdapter => 'Geen adapter gekoppeld';

  @override
  String get obd2StatusForget => 'Adapter vergeten';

  @override
  String get tripHistoryTitle => 'Ritgeschiedenis';

  @override
  String get tripHistoryEmptyTitle => 'Nog geen ritten';

  @override
  String get tripHistoryEmptySubtitle =>
      'Verbind een OBD2-adapter en neem een rit op om je rijgeschiedenis op te bouwen.';

  @override
  String get tripHistoryUnknownDate => 'Datum onbekend';

  @override
  String get situationIdle => 'Stationair';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Stedelijk';

  @override
  String get situationHighway => 'Snelweg';

  @override
  String get situationDecel => 'Afremmen';

  @override
  String get situationClimbing => 'Klimmen / zwaar beladen';

  @override
  String get situationHardAccel => 'Hard optrekken';

  @override
  String get situationFuelCut => 'Brandstofonderbreking — uitrollen';

  @override
  String get tripSaveAsFillUp => 'Opslaan als tankbeurt';

  @override
  String get tripSaveRecording => 'Rit opslaan';

  @override
  String get tripDiscard => 'Verwerpen';

  @override
  String obdOdometerRead(int km) {
    return 'Kilometerstand gelezen: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Niet ingesteld';

  @override
  String get wizardVehicleTapToEdit => 'Tik om te bewerken';

  @override
  String get wizardVehicleDefaultBadge => 'Standaard';

  @override
  String get wizardProfileChoiceHint =>
      'Kies hoe je de app wilt gebruiken. Je kunt dit later aanpassen in Instellingen.';

  @override
  String get wizardProfileChoiceFooter =>
      'Je kunt je keuze altijd wijzigen via Instellingen → Gebruiksmodus.';

  @override
  String get wizardProfileBasicName => 'Basis';

  @override
  String get wizardProfileBasicDescription =>
      'Goedkoopste brandstof en EV-laadprijzen in de buurt. Favorieten en prijsmeldingen.';

  @override
  String get wizardProfileMediumName => 'Gemiddeld';

  @override
  String get wizardProfileMediumDescription =>
      'Alles uit Basis, plus handmatig bijhouden van tankbeurten en EV-laadsessies.';

  @override
  String get wizardProfileFullName => 'Volledig';

  @override
  String get wizardProfileFullDescription =>
      'Alles uit Gemiddeld, plus automatische OBD2-ritopname, rijscores en loyaliteitskaarten.';

  @override
  String get wizardProfileCustomName => 'Aangepast';

  @override
  String get wizardProfileCustomDescription =>
      'Jouw eigen combinatie van functies. Pas elke schakelaar hieronder aan.';

  @override
  String get useModeSectionHint =>
      'Pas de app aan je gebruik aan. Door een preset te kiezen, worden de bijbehorende functies ingeschakeld.';

  @override
  String get useModeCustomSettingsDescription =>
      'Je functiemix komt niet overeen met een preset. Kies er een hierboven om te overschrijven, of blijf individuele functies hieronder aanpassen.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Gebruiksmodus ingesteld op $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Standaardvoertuig (optioneel)';

  @override
  String get profileDefaultVehicleNone => 'Geen standaard';

  @override
  String get profileFuelFromVehicleHint =>
      'Brandstoftype wordt afgeleid van je standaardvoertuig. Verwijder het voertuig om direct een brandstof te kiezen.';

  @override
  String get consumptionNoVehicleTitle => 'Voeg eerst een voertuig toe';

  @override
  String get consumptionNoVehicleBody =>
      'Tankbeurten worden aan een voertuig gekoppeld. Voeg je auto toe om het verbruik bij te houden.';

  @override
  String get vehicleAdd => 'Voertuig toevoegen';

  @override
  String get vehicleAddTitle => 'Voertuig toevoegen';

  @override
  String get vehicleEditTitle => 'Voertuig bewerken';

  @override
  String get vehicleDeleteTitle => 'Voertuig verwijderen?';

  @override
  String vehicleDeleteMessage(String name) {
    return '\"$name\" verwijderen uit je profielen?';
  }

  @override
  String get vehicleNameLabel => 'Naam';

  @override
  String get vehicleNameHint => 'bijv. Mijn Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Verbrandingsmotor';

  @override
  String get vehicleTypeHybrid => 'Hybride';

  @override
  String get vehicleTypeEv => 'Elektrisch';

  @override
  String get vehicleEvSectionTitle => 'Elektrisch';

  @override
  String get vehicleCombustionSectionTitle => 'Verbrandingsmotor';

  @override
  String get vehicleBatteryLabel => 'Accucapaciteit (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max. laadvermogen (kW)';

  @override
  String get vehicleConnectorsLabel => 'Ondersteunde connectoren';

  @override
  String get vehicleMinSocLabel => 'Min. SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max. SoC %';

  @override
  String get vehicleTankLabel => 'Tankinhoud (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Voorkeursbrandstof';

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
  String get connectorThreePin => '3-polig';

  @override
  String get evShowOnMap => 'EV-stations tonen';

  @override
  String get evAvailableOnly => 'Alleen beschikbaar';

  @override
  String get evMinPower => 'Min. vermogen';

  @override
  String get evMaxPower => 'Max. vermogen';

  @override
  String get evOperator => 'Exploitant';

  @override
  String get evLastUpdate => 'Laatste update';

  @override
  String get evStatusAvailable => 'Beschikbaar';

  @override
  String get evStatusOccupied => 'Bezet';

  @override
  String get evStatusOutOfOrder => 'Buiten gebruik';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Alleen geopend';

  @override
  String get saveAsDefaults => 'Opslaan als standaard';

  @override
  String get criteriaSavedToProfile => 'Opgeslagen als standaard';

  @override
  String get profileNotFound => 'Geen actief profiel';

  @override
  String get updatingFavorites => 'Favorieten bijwerken...';

  @override
  String get fetchingLatestPrices => 'Actuele prijzen ophalen';

  @override
  String get noDataAvailable => 'Geen gegevens';

  @override
  String get configAndPrivacy => 'Configuratie & Privacy';

  @override
  String get searchToSeeMap => 'Zoek om stations op de kaart te zien';

  @override
  String get evPowerAny => 'Willekeurig';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profiel';

  @override
  String get sectionLocation => 'Locatie';

  @override
  String get tooltipBack => 'Terug';

  @override
  String get tooltipClose => 'Sluiten';

  @override
  String get tooltipShare => 'Delen';

  @override
  String get tooltipClearSearch => 'Zoekinvoer wissen';

  @override
  String get minimalDriveInstantConsumption => 'Direct verbruik';

  @override
  String get coachingShiftUp => 'Schakel op';

  @override
  String get coachingShiftDown => 'Schakel terug';

  @override
  String get coachingEasePedal => 'Gas loslaten';

  @override
  String get tooltipUseGps => 'GPS-locatie gebruiken';

  @override
  String get tooltipShowPassword => 'Wachtwoord tonen';

  @override
  String get tooltipHidePassword => 'Wachtwoord verbergen';

  @override
  String get evConnectorsLabel => 'Beschikbare connectoren';

  @override
  String get evConnectorsNone => 'Geen connectorinformatie';

  @override
  String get switchToEmail => 'Overschakelen naar e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Gegevens bewaren, aanmelden vanaf andere apparaten';

  @override
  String get switchToAnonymousAction => 'Overschakelen naar anoniem';

  @override
  String get switchToAnonymousSubtitle =>
      'Lokale gegevens bewaren, nieuwe anonieme sessie gebruiken';

  @override
  String get linkDevice => 'Apparaat koppelen';

  @override
  String get shareDatabase => 'Database delen';

  @override
  String get disconnectAction => 'Verbreken';

  @override
  String get disconnectSubtitle =>
      'Synchronisatie stoppen (lokale gegevens bewaard)';

  @override
  String get deleteAccountAction => 'Account verwijderen';

  @override
  String get deleteAccountSubtitle =>
      'Alle servergegevens permanent verwijderen';

  @override
  String get localOnly => 'Alleen lokaal';

  @override
  String get localOnlySubtitle =>
      'Optioneel: favorieten, meldingen en beoordelingen synchroniseren via apparaten';

  @override
  String get setupCloudSync => 'Cloudsync instellen';

  @override
  String get disconnectTitle => 'TankSync verbreken?';

  @override
  String get disconnectBody =>
      'Cloudsync wordt uitgeschakeld. Je lokale gegevens (favorieten, meldingen, geschiedenis) blijven op dit apparaat bewaard. Servergegevens worden niet verwijderd.';

  @override
  String get deleteAccountTitle => 'Account verwijderen?';

  @override
  String get deleteAccountBody =>
      'Hiermee worden alle je gegevens permanent van de server verwijderd (favorieten, meldingen, beoordelingen, routes). Lokale gegevens op dit apparaat blijven bewaard.\n\nDit kan niet ongedaan worden gemaakt.';

  @override
  String get switchToAnonymousTitle => 'Overschakelen naar anoniem?';

  @override
  String get switchToAnonymousBody =>
      'Je wordt uitgelogd van je e-mailaccount en gaat verder met een nieuwe anonieme sessie.\n\nJe lokale gegevens (favorieten, meldingen) blijven op dit apparaat staan en worden gesynchroniseerd naar het nieuwe anonieme account.';

  @override
  String get switchAction => 'Wisselen';

  @override
  String get helpBannerCriteria =>
      'Je profielstandaarden zijn vooringevuld. Pas de criteria hieronder aan om je zoekopdracht te verfijnen.';

  @override
  String get helpBannerAlerts =>
      'Stel een prijsdrempel in voor een station. Je ontvangt een melding als de prijs eronder daalt. Controles worden elke 30 minuten uitgevoerd.';

  @override
  String get helpBannerConsumption =>
      'Registreer elke tankbeurt om je werkelijke verbruik en CO₂-voetafdruk bij te houden. Veeg links om een invoer te verwijderen.';

  @override
  String get helpBannerVehicles =>
      'Voeg je voertuigen toe zodat tankbeurten en brandstofvoorkeuren automatisch correct worden ingevuld. Het eerste voertuig wordt je standaard.';

  @override
  String get syncNow => 'Nu synchroniseren';

  @override
  String get onboardingPreferencesTitle => 'Jouw voorkeuren';

  @override
  String get onboardingZipHelper => 'Gebruikt als GPS niet beschikbaar is';

  @override
  String get onboardingRadiusHelper => 'Grotere straal = meer resultaten';

  @override
  String get onboardingPrivacy =>
      'Deze instellingen worden alleen op je apparaat opgeslagen en nooit gedeeld.';

  @override
  String get onboardingLandingTitle => 'Startscherm';

  @override
  String get onboardingLandingHint =>
      'Kies welk scherm opent als je de app start.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Blijf uit de app — maar sluit hem niet.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Open Sparkilo één keer na elke herstart.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple wekt Sparkilo alleen op nadat je het minstens één keer hebt geopend na de herstart van de telefoon. Daarna worden je ritten automatisch opgenomen.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Veeg Sparkilo niet weg in de app-switcher.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Geforceerd afsluiten\" vertelt iOS om de app niet meer opnieuw te starten. Je ritten worden niet meer opgenomen totdat je Sparkilo opnieuw opent.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Als iOS vraagt om \"Altijd\" locatie, zeg dan ja.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'De reservemethode die je rit opneemt als de OBD2-adapter traag is, heeft achtergrondlocatie nodig. We delen het nooit.';

  @override
  String get scanReceipt => 'Bon scannen';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Brandstof';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Snelweg';

  @override
  String get ratingModeLocal => 'Lokaal';

  @override
  String get ratingModePrivate => 'Privé';

  @override
  String get ratingModeShared => 'Gedeeld';

  @override
  String get ratingDescLocal => 'Beoordelingen opgeslagen op dit apparaat';

  @override
  String get ratingDescPrivate =>
      'Gesynchroniseerd met je database (niet zichtbaar voor anderen)';

  @override
  String get ratingDescShared =>
      'Zichtbaar voor alle gebruikers van je database';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API-sleutel niet geconfigureerd. Voeg er een toe in Instellingen om EV-laadstations te zoeken.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'De dataprovider ($host) geeft een verlopen of ongeldig TLS-certificaat. De app kan geen gegevens van deze bron laden totdat de provider het oplost. Neem contact op met $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed niet beschikbaar. $current wordt gebruikt.';
  }

  @override
  String get errorTitleApiKey => 'API-sleutel vereist';

  @override
  String get errorTitleLocation => 'Locatie niet beschikbaar';

  @override
  String get errorHintNoStations =>
      'Probeer de zoekstraal te vergroten of zoek op een andere locatie.';

  @override
  String get errorHintApiKey => 'Configureer je API-sleutel in Instellingen.';

  @override
  String get errorHintConnection =>
      'Controleer je internetverbinding en probeer opnieuw.';

  @override
  String get errorHintRouting =>
      'Routeberekening mislukt. Controleer je internetverbinding en probeer opnieuw.';

  @override
  String get errorHintFallback =>
      'Probeer opnieuw of zoek op postcode / plaatsnaam.';

  @override
  String get alertsLoadErrorTitle => 'Meldingen konden niet worden geladen';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Achtergrondcontrole meldingen mislukt';

  @override
  String get detailsLabel => 'Details';

  @override
  String get remove => 'Verwijderen';

  @override
  String get showKey => 'Sleutel tonen';

  @override
  String get hideKey => 'Sleutel verbergen';

  @override
  String get syncOptionalTitle => 'TankSync is optioneel';

  @override
  String get syncOptionalDescription =>
      'Je app werkt volledig zonder cloudsync. TankSync laat je favorieten, meldingen en beoordelingen synchroniseren via apparaten met Supabase (gratis versie beschikbaar).';

  @override
  String get syncHowToConnectQuestion => 'Hoe wil je verbinding maken?';

  @override
  String get syncCreateOwnTitle => 'Mijn eigen database aanmaken';

  @override
  String get syncCreateOwnSubtitle =>
      'Gratis Supabase-project — we begeleiden je stap voor stap';

  @override
  String get syncJoinExistingTitle => 'Bestaande database joinen';

  @override
  String get syncJoinExistingSubtitle =>
      'Scan QR-code van de database-eigenaar of plak inloggegevens';

  @override
  String get syncChooseAccountType => 'Kies je accounttype';

  @override
  String get syncAccountTypeAnonymous => 'Anoniem';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Direct, geen e-mail nodig. Gegevens gekoppeld aan dit apparaat.';

  @override
  String get syncAccountTypeEmail => 'E-mailaccount';

  @override
  String get syncAccountTypeEmailDesc =>
      'Aanmelden vanaf elk apparaat. Gegevens herstellen als je telefoon verloren gaat.';

  @override
  String get syncHaveAccountSignIn => 'Al een account? Aanmelden';

  @override
  String get syncCreateNewAccount => 'Nieuw account aanmaken';

  @override
  String get syncTestConnection => 'Verbinding testen';

  @override
  String get syncTestingConnection => 'Testen...';

  @override
  String get syncConnectButton => 'Verbinden';

  @override
  String get syncConnectingButton => 'Verbinden...';

  @override
  String get syncDatabaseReady => 'Database klaar!';

  @override
  String get syncDatabaseNeedsSetup => 'Database vereist instelling';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Ontbreekt';

  @override
  String get syncSqlEditorInstructions =>
      'Kopieer de onderstaande SQL en voer het uit in je Supabase SQL-editor (Dashboard → SQL Editor → Nieuwe query → Plakken → Uitvoeren)';

  @override
  String get syncCopySqlButton => 'SQL kopiëren naar klembord';

  @override
  String get syncRecheckSchemaButton => 'Schema opnieuw controleren';

  @override
  String get syncDoneButton => 'Gereed';

  @override
  String syncSignedInAs(String email) {
    return 'Aangemeld als $email';
  }

  @override
  String get syncEmailDescription =>
      'Je gegevens worden gesynchroniseerd op alle apparaten met dit e-mailadres.';

  @override
  String get syncSwitchToAnonymousTitle => 'Overschakelen naar anoniem';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Doorgaan zonder e-mail, nieuwe anonieme sessie';

  @override
  String get syncGuestDescription => 'Anoniem, geen e-mail nodig.';

  @override
  String get syncOrDivider => 'of';

  @override
  String get syncHowToSyncQuestion => 'Hoe wil je synchroniseren?';

  @override
  String get syncOfflineDescription =>
      'Je app werkt volledig offline. Cloudsync is optioneel.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Favorieten & beoordelingen delen met alle gebruikers';

  @override
  String get syncModePrivateTitle => 'Privédatabase';

  @override
  String get syncModePrivateSubtitle =>
      'Je eigen Supabase — volledige controle over gegevens';

  @override
  String get syncModeGroupTitle => 'Groep joinen';

  @override
  String get syncModeGroupSubtitle =>
      'Gedeelde database voor familie of vrienden';

  @override
  String get syncPrivacyShared => 'Gedeeld';

  @override
  String get syncPrivacyPrivate => 'Privé';

  @override
  String get syncPrivacyGroup => 'Groep';

  @override
  String get syncStayOfflineButton => 'Offline blijven';

  @override
  String get syncSuccessTitle => 'Succesvol verbonden!';

  @override
  String get syncSuccessDescription =>
      'Je gegevens worden nu automatisch gesynchroniseerd.';

  @override
  String get syncWizardTitleConnect => 'TankSync verbinden';

  @override
  String get syncSetupTitleYourDatabase => 'Jouw database';

  @override
  String get syncSetupTitleJoinGroup => 'Groep joinen';

  @override
  String get syncSetupTitleAccount => 'Jouw account';

  @override
  String get syncWizardBack => 'Terug';

  @override
  String get syncWizardNext => 'Volgende';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Stap $current van $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Een Supabase-project aanmaken';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tik hieronder op \"Supabase openen\"\n2. Maak een gratis account aan (als je dat nog niet hebt)\n3. Klik op \"Nieuw project\"\n4. Kies een naam en regio\n5. Wacht ~2 minuten tot het klaar is';

  @override
  String get syncWizardOpenSupabase => 'Supabase openen';

  @override
  String get syncWizardEnableAnonTitle => 'Anoniem aanmelden inschakelen';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. In je Supabase-dashboard:\n   Verificatie → Providers\n2. Zoek \"Anoniem aanmelden\"\n3. Zet het AAN\n4. Klik op \"Opslaan\"';

  @override
  String get syncWizardOpenAuthSettings => 'Verificatie-instellingen openen';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopieer je inloggegevens';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Ga naar Instellingen → API in je dashboard\n2. Kopieer de \"Project URL\"\n3. Kopieer de \"anon public\"-sleutel\n4. Plak ze hieronder';

  @override
  String get syncWizardOpenApiSettings => 'API-instellingen openen';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Bestaande database joinen';

  @override
  String get syncWizardScanQrCode => 'QR-code scannen';

  @override
  String get syncWizardAskOwnerQr =>
      'Vraag de database-eigenaar om zijn QR-code te tonen\n(Instellingen → TankSync → Delen)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Vraag de database-eigenaar om zijn QR-code te tonen';

  @override
  String get syncWizardEnterManuallyTitle => 'Handmatig invoeren';

  @override
  String get syncWizardOrEnterManually => 'of handmatig invoeren';

  @override
  String get syncWizardUrlHelperText =>
      'Witruimte en regeleinden worden automatisch verwijderd';

  @override
  String get syncCredentialsPrivateHint =>
      'Voer je Supabase-projectinloggegevens in. Je vindt ze in je dashboard onder Instellingen > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Database-URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Toegangssleutel';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Wachtwoord';

  @override
  String get authConfirmPasswordLabel => 'Wachtwoord bevestigen';

  @override
  String get authPleaseEnterEmail => 'Voer je e-mailadres in';

  @override
  String get authInvalidEmail => 'Ongeldig e-mailadres';

  @override
  String get authPasswordsDoNotMatch => 'Wachtwoorden komen niet overeen';

  @override
  String get authConnectAnonymously => 'Anoniem verbinden';

  @override
  String get authCreateAccountAndConnect => 'Account aanmaken & verbinden';

  @override
  String get authSignInAndConnect => 'Aanmelden & verbinden';

  @override
  String get authAnonymousSegment => 'Anoniem';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Direct toegang, geen e-mail nodig. Gegevens gekoppeld aan dit apparaat.';

  @override
  String get authEmailDescription =>
      'Aanmelden vanaf elk apparaat. Herstel je gegevens als je telefoon verloren gaat.';

  @override
  String get authSyncAcrossDevices =>
      'Gegevens automatisch synchroniseren op al je apparaten.';

  @override
  String get authNewHereCreateAccount => 'Nieuw hier? Account aanmaken';

  @override
  String get linkDeviceScreenTitle => 'Apparaat koppelen';

  @override
  String get linkDeviceThisDeviceLabel => 'Dit apparaat';

  @override
  String get linkDeviceShareCodeHint =>
      'Deel deze code met je andere apparaat:';

  @override
  String get linkDeviceNotConnected => 'Niet verbonden';

  @override
  String get linkDeviceCopyCodeTooltip => 'Code kopiëren';

  @override
  String get linkDeviceImportSectionTitle =>
      'Importeren van een ander apparaat';

  @override
  String get linkDeviceImportDescription =>
      'Voer de apparaatcode van je andere apparaat in om favorieten, meldingen, voertuigen en verbruikslogboek te importeren. Elk apparaat behoudt zijn eigen profiel en standaarden.';

  @override
  String get linkDeviceCodeFieldLabel => 'Apparaatcode';

  @override
  String get linkDeviceCodeFieldHint => 'Plak de UUID van het andere apparaat';

  @override
  String get linkDeviceImportButton => 'Gegevens importeren';

  @override
  String get linkDeviceHowItWorksTitle => 'Hoe het werkt';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Op apparaat A: kopieer de apparaatcode hierboven\n2. Op apparaat B: plak hem in het veld \"Apparaatcode\"\n3. Tik op \"Gegevens importeren\" om favorieten, meldingen, voertuigen en verbruikslogboeken samen te voegen\n4. Beide apparaten hebben alle gecombineerde gegevens\n\nElk apparaat behoudt zijn eigen anonieme identiteit en profiel (voorkeursbrandstof, standaardvoertuig, startscherm). Gegevens worden samengevoegd, niet verplaatst.';

  @override
  String get vehicleSetActive => 'Instellen als actief';

  @override
  String get swipeHide => 'Verbergen';

  @override
  String get evChargingSection => 'EV-laden';

  @override
  String get fuelStationsSection => 'Tankstations';

  @override
  String get yourRating => 'Jouw beoordeling';

  @override
  String get noStorageUsed => 'Geen opslag in gebruik';

  @override
  String get aboutReportBug => 'Bug melden / Functie voorstellen';

  @override
  String get aboutSupportProject => 'Project ondersteunen';

  @override
  String get aboutSupportDescription =>
      'Deze app is gratis, open source en heeft geen advertenties. Als je hem nuttig vindt, overweeg dan de ontwikkelaar te ondersteunen.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxemburgse brandstofprijzen zijn door de overheid gereguleerd en overal in het land gelijk.';

  @override
  String get luxembourgFuelUnleaded95 => 'Loodvrij 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Loodvrij 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxemburgse gereguleerde prijzen zijn niet beschikbaar.';

  @override
  String get reportIssueTitle => 'Probleem melden';

  @override
  String get enterCorrection => 'Voer de correctie in';

  @override
  String get reportNoBackendAvailable =>
      'Het rapport kon niet worden verzonden: er is geen rapportageservice geconfigureerd voor dit land. Schakel TankSync in via Instellingen om communityrapports te versturen.';

  @override
  String get correctName => 'Juiste stationsnaam';

  @override
  String get correctAddress => 'Juist adres';

  @override
  String get wrongE85Price => 'Verkeerde E85-prijs';

  @override
  String get wrongE98Price => 'Verkeerde Super 98-prijs';

  @override
  String get wrongLpgPrice => 'Verkeerde LPG-prijs';

  @override
  String get wrongStationName => 'Verkeerde stationsnaam';

  @override
  String get wrongStationAddress => 'Verkeerd adres';

  @override
  String get independentStation => 'Onafhankelijk station';

  @override
  String get serviceRemindersSection => 'Onderhoudsmeldingen';

  @override
  String get serviceRemindersEmpty =>
      'Nog geen meldingen — kies hierboven een preset.';

  @override
  String get addServiceReminder => 'Melding toevoegen';

  @override
  String get serviceReminderPresetOil => 'Olie (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Olieverversing';

  @override
  String get serviceReminderPresetTires => 'Banden (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Banden';

  @override
  String get serviceReminderPresetInspection => 'APK (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'APK';

  @override
  String get serviceReminderLabel => 'Label';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Laatste beurt';

  @override
  String get serviceReminderMarkDone => 'Als gedaan markeren';

  @override
  String get serviceReminderDueTitle => 'Onderhoud verschuldigd';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label is verschuldigd — $kmOver km over het interval.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Registreer bij OPINET voor een gratis API-sleutel';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registreer bij CNE voor een gratis API-sleutel';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Is dit jouw auto?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-cil., $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Gedeeltelijke info (offline). Je kunt dit hieronder bewerken.';

  @override
  String get vinDecodeError => 'Kon dit VIN niet decoderen';

  @override
  String get vinInvalidFormat => 'Ongeldig VIN-formaat';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2-verbinding verbroken — opname gepauzeerd';

  @override
  String get obd2PauseBannerResume => 'Opname hervatten';

  @override
  String get obd2PauseBannerEnd => 'Opname beëindigen';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Verbruikskalibratie bijgewerkt voor $vehicleName — nauwkeurigheid verbeterd met $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Volumetrisch rendement resetten?';

  @override
  String get veResetConfirmBody =>
      'Dit verwijdert het geleerde volumetrisch rendement (η_v) en herstelt de standaardwaarde (0.85). Brandstofstroominschattingen per rit vallen terug op de fabrikantconstante totdat de kalibratie nieuwe steekproeven uit aankomende ritten heeft verzameld.';

  @override
  String get alertsRadiusSectionTitle => 'Straalwaarschuwingen';

  @override
  String get alertsRadiusAdd => 'Straalwaarschuwing toevoegen';

  @override
  String get alertsRadiusEmptyTitle => 'Nog geen straalwaarschuwingen';

  @override
  String get alertsRadiusEmptyCta => 'Straalwaarschuwing aanmaken';

  @override
  String get alertsRadiusCreateTitle => 'Straalwaarschuwing aanmaken';

  @override
  String get alertsRadiusLabelHint => 'Label (bijv. Thuis diesel)';

  @override
  String get alertsRadiusFuelType => 'Brandstoftype';

  @override
  String get alertsRadiusThreshold => 'Drempelwaarde (€/L)';

  @override
  String get alertsRadiusKm => 'Straal (km)';

  @override
  String get alertsRadiusCenterGps => 'Mijn locatie gebruiken';

  @override
  String get alertsRadiusCenterPostalCode => 'Postcode';

  @override
  String get alertsRadiusSave => 'Opslaan';

  @override
  String get alertsRadiusCancel => 'Annuleren';

  @override
  String get alertsRadiusDeleteConfirm => 'Straalwaarschuwing verwijderen?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 verbonden: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Een OBD2-adapter koppelen';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel gedaald bij nabijgelegen stations';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stations daalden tot $maxDropCents¢ in het afgelopen uur';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankbeurt opgeslagen';

  @override
  String get radiusAlertsEntryTitle => 'Straalwaarschuwingen & statistieken';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Ontvang een melding als prijzen in de buurt dalen';

  @override
  String get notFoundTitle => 'Pagina niet gevonden';

  @override
  String notFoundBody(String location) {
    return '\"$location\" niet gevonden.';
  }

  @override
  String get notFoundHomeButton => 'Home';

  @override
  String get consumptionTabHiddenNotice =>
      'Het tabblad Verbruik is verborgen door je profielinstellingen.';

  @override
  String get swipeBetweenTabsHint =>
      'Tip: veeg links of rechts om tussen tabbladen te wisselen.';

  @override
  String get discardChangesTitle => 'Wijzigingen verwerpen?';

  @override
  String get discardChangesBody =>
      'Je hebt niet-opgeslagen wijzigingen. Als je nu verlaat, worden ze verworpen.';

  @override
  String get discardChangesConfirm => 'Verwerpen';

  @override
  String get discardChangesKeepEditing => 'Doorgaan met bewerken';

  @override
  String get tankSyncSectionSubtitle => 'Cloudsync op al je apparaten';

  @override
  String get mapUnavailable => 'Kaart niet beschikbaar';

  @override
  String get routeNameHintExample => 'bijv. Parijs → Lyon';

  @override
  String get priceStatsCurrent => 'Huidig';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API-sleutel';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API-sleutel';

  @override
  String get tapToUpdateGpsPosition => 'Tik om GPS-positie bij te werken';

  @override
  String get nameLabel => 'Naam';

  @override
  String get obd2ErrorPermissionDenied =>
      'Bluetooth-toestemming is vereist om verbinding te maken met een OBD2-adapter.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Schakel Bluetooth in en probeer het opnieuw.';

  @override
  String get obd2ErrorScanTimeout =>
      'Geen OBD2-adapter in de buurt gevonden. Controleer of deze is aangesloten en ingeschakeld.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'De OBD2-adapter reageerde niet. Zet het contact aan en probeer het opnieuw.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'De OBD2-adapter stuurde een niet-herkend antwoord. Mogelijk is deze incompatibel — probeer een andere adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'De OBD2-adapter is losgekoppeld. Maak opnieuw verbinding en probeer het opnieuw.';

  @override
  String get onboardingExploreDemoData => 'Verken met demogegevens';

  @override
  String get achievementSmoothDriver => 'Soepele reeks';

  @override
  String get achievementSmoothDriverDesc =>
      'Rij 5 ritten op rij met een soepele rijscore van 80 of hoger.';

  @override
  String get achievementColdStartAware => 'Koudestartbewust';

  @override
  String get achievementColdStartAwareDesc =>
      'Houd de koudestartbrandstofkosten van een hele maand onder 2% van de totale brandstof — combineer korte ritten.';

  @override
  String get achievementHighwayMaster => 'Snelwegmeester';

  @override
  String get achievementHighwayMasterDesc =>
      'Voltooi een rit van 30 km of meer op constante snelheid met een soepele rijscore van 90 of hoger.';

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
    return '$price $currency (doel: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel gedaald bij tankstations in de buurt';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count tankstations gedaald met tot wel $cents¢ in het afgelopen uur';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count tankstations ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count meer';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Prijswaarschuwingen op de achtergrond werken momenteel alleen voor tankstations in Duitsland. Deze waarschuwing wordt opgeslagen, maar geeft je mogelijk nooit een melding totdat grensoverschrijdende waarschuwingen beschikbaar zijn.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Straalwaarschuwingen controleren momenteel alleen tankstations in Duitsland.';

  @override
  String get approachOverlaySection =>
      'Overlay bij nadering van een tankstation';

  @override
  String get approachRadiusLabel => 'Radius';

  @override
  String approachRadiusCaption(String km) {
    return 'De overlay groeit en toont de prijs wanneer je binnen $km km van een tankstation bent';
  }

  @override
  String get approachPriceModeLabel => 'Toon prijs van';

  @override
  String get approachPriceModeNearest => 'Dichtstbijzijnde station';

  @override
  String get approachPriceModeCheapestInRadius => 'Goedkoopste in radius';

  @override
  String get approachMinPollLabel => 'Min. ververs.';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Ondergrens voor hoe vaak de overlay het dichtstbijzijnde station ververst (sneller bij snelheid, nooit korter dan $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testen van naderingsoverlay';

  @override
  String get approachTestStopButton => 'Stop test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test actief — overlay toont de prijs voor $station';
  }

  @override
  String get approachTestUnavailable =>
      'Voeg een favoriete tankstation toe om de naderingsoverlay te testen';

  @override
  String approachStationDistance(String meters) {
    return '$meters m verderop';
  }

  @override
  String get authErrorNoNetwork =>
      'Geen netwerkverbinding. Probeer het later opnieuw.';

  @override
  String get authErrorInvalidCredentials =>
      'Ongeldig e-mailadres of wachtwoord. Controleer je gegevens.';

  @override
  String get authErrorUserAlreadyExists =>
      'Dit e-mailadres is al geregistreerd. Probeer in te loggen.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Controleer je e-mail en bevestig je account eerst.';

  @override
  String get authErrorGeneric => 'Aanmelden mislukt. Probeer het opnieuw.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Achtergrondlocatie — alleen voor automatische opname';

  @override
  String get autoRecordConsentExplanationTitle => 'Over deze toestemming';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatische opname heeft achtergrondlocatie nodig om te detecteren wanneer je gaat rijden terwijl de app gesloten is. Deze toestemming wordt alleen gebruikt door automatische opname — stationszoeken en kaartcentrering gebruiken een aparte voorgrondlocatietoestemming.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Begrepen';

  @override
  String get autoRecordConsentExplanationTooltip => 'Wat betekent dit?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Tik om te beheren in systeeminstellingen';

  @override
  String get autoRecordSectionTitle => 'Automatisch opnemen';

  @override
  String get autoRecordToggleLabel => 'Ritten automatisch opnemen';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatisch opnemen wordt geactiveerd de volgende keer dat je in de auto stapt.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Koppel een OBD2-adapter om automatisch opnemen in te schakelen.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Sta achtergrondlocatie toe zodat automatisch opnemen blijft werken als het scherm uit is.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Een adapter koppelen';

  @override
  String get autoRecordSpeedThresholdLabel => 'Startsnelheid (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Opslagvertraging na verbreken (seconden)';

  @override
  String get autoRecordPairedAdapterLabel => 'Gekoppelde adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Geen adapter gekoppeld. Koppel er eerst een via de OBD2-inrichting.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Achtergrondlocatie toegestaan';

  @override
  String get autoRecordBackgroundLocationRequest => 'Toestemming aanvragen';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Waarom \"Altijd toestaan\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatisch opnemen streamt GPS-coördinaten vanuit de OBD-II voorgrondservice terwijl het scherm uit is, zodat je ritroute nauwkeurig blijft. Android vereist de optie \"Altijd toestaan\" zodat dit blijft werken nadat het apparaat vergrendeld is.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Instellingen openen';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Locatietoestemming vereist';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Achtergrondlocatie kon niet worden aangevraagd';

  @override
  String get autoRecordBadgeClearTooltip => 'Teller wissen';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Koppel een adapter in de onderstaande sectie om automatisch opnemen in te schakelen';

  @override
  String get exportBackupTooltip => 'Back-up exporteren';

  @override
  String get exportBackupReady => 'Back-up klaar — kies een bestemming';

  @override
  String get exportBackupFailed =>
      'Back-up exporteren mislukt — probeer het opnieuw';

  @override
  String get brokenMapChipVerifying => 'MAP-sensor wordt geverifieerd…';

  @override
  String get brokenMapChipDisclaimer => 'MAP-meetwaarden verdacht';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-sensor leest onjuist — brandstofmetingen kunnen 50–80% te laag zijn. Probeer een andere adapter.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-sensor onbetrouwbaar. Tankbeurtgemiddelden worden getoond in plaats van live brandstofverbruik.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP-sensor: geverifieerd ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP-sensor: verificatie bezig ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP-sensor: verdacht ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin% (geverifieerd)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-sensor diagnostiek';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Defecte-MAP betrouwbaarheid: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count waarnemingen geregistreerd';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Geverifieerd schoon';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'De MAP-sensor van dit voertuig is nog niet waargenomen.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Geblokkeerde adapters';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Geen adapters geblokkeerd.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — als $percent% defect gemarkeerd';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Wissen';

  @override
  String get brokenMapRevPromptTitle => 'Geef gas';

  @override
  String get brokenMapRevPromptBody =>
      'Geef kort gas zodat de app kan controleren of de MAP-sensor reageert.';

  @override
  String get brokenMapRevPromptConfirm => 'Klaar — ik heb gas gegeven';

  @override
  String get calibrationAdvancedTitle => 'Geavanceerde kalibratie';

  @override
  String get calibrationDisplacementLabel => 'Motorinhoud (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrisch rendement (η_v)';

  @override
  String get calibrationAfrLabel => 'Lucht-brandstofverhouding (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Brandstofde nsiteit (g/L)';

  @override
  String get calibrationSourceDetected => '(gedetecteerd via VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catalogus: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(standaard)';

  @override
  String get calibrationSourceManual => '(handmatig)';

  @override
  String get calibrationResetToDetected => 'Resetten naar gedetecteerde waarde';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (gekalibreerd, $samples steekproeven)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (aan het leren, $samples steekproeven)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (standaard — nog geen volledige tank)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples samples';
  }

  @override
  String get calibrationResetLearner => 'Leermodule resetten';

  @override
  String get calibrationBasisAtkinson => 'Atkinson-cyclus';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbocharged + DI';

  @override
  String get calibrationBasisTurbo => 'Turbocharged';

  @override
  String get calibrationBasisNaDi => 'Atmosferisch + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catalogus: $makeModel — $basis standaard)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Je $makeModel staat als diesel gemarkeerd maar komt overeen met een benzine-catalogusinvoer. Tik om bij te werken.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Bijwerken';

  @override
  String get consumptionTabFuel => 'Brandstof';

  @override
  String get consumptionTabCharging => 'Laden';

  @override
  String get noChargingLogsTitle => 'Nog geen laadlogboeken';

  @override
  String get noChargingLogsSubtitle =>
      'Registreer je eerste laadsessie om EUR/100 km en kWh/100 km bij te houden.';

  @override
  String get addChargingLog => 'Laadsessie registreren';

  @override
  String get addChargingLogTitle => 'Laadsessie registreren';

  @override
  String get chargingKwh => 'Energie (kWh)';

  @override
  String get chargingCost => 'Totale kosten';

  @override
  String get chargingTimeMin => 'Laadtijd (min)';

  @override
  String get chargingStationName => 'Station (optioneel)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Vorig logboek nodig om te vergelijken';

  @override
  String get chargingLogButtonLabel => 'Laadsessie registreren';

  @override
  String get chargingCostTrendTitle => 'Trend laadkosten';

  @override
  String get chargingEfficiencyTitle => 'Efficiëntie (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Nog niet genoeg gegevens';

  @override
  String get chargingChartsMonthAxis => 'Maand';

  @override
  String get consoFeatureGroupTitle => 'Verbruik';

  @override
  String get consoFeatureGroupDescription =>
      'Bijhouden van je verbruik — handmatige tankbeurten of automatische OBD2-ritopname.';

  @override
  String get consoModeOff => 'Uit';

  @override
  String get consoModeFuel => 'Brandstof';

  @override
  String get consoModeFuelAndTrips => 'Brandstof + Ritten';

  @override
  String get consoModeOffDescription =>
      'Geen tabblad Verbruik en geen sectie Verbruiksinstellingen.';

  @override
  String get consoModeFuelDescription =>
      'Alleen handmatige tankbeurten. Handig zonder OBD2-adapter.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Voegt automatische OBD2-ritopname toe. Vereist een gekoppelde adapter.';

  @override
  String get consoSubsectionVehicles => 'Mijn voertuigen';

  @override
  String get consoSubsectionTrajets => 'Ritten (OBD2)';

  @override
  String get consoSubsectionToggles => 'Rijden';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Nauwkeurigheid: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Hoog';

  @override
  String get consumptionAccuracyMedium => 'Gemiddeld';

  @override
  String get consumptionAccuracyLow => 'Laag';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Volledige kalibratie: tankbeurten plus ritten opgenomen met OBD2. De L/100 km-waarde volgt de werkelijkheid tot op enkele procenten.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankbeurten hebben het verbruiksmodel verankerd, maar er is nog geen OBD2-rit verwerkt. Neem er een op met OBD2 verbonden om hoge nauwkeurigheid te bereiken.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Alleen GPS — nog geen tankbeurten hebben het verbruiksmodel verankerd. Voeg een paar volle tankbeurten toe om de nauwkeurigheid te verbeteren.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count gedeeltelijke tankbeurten wachten op volledige tank — niet meegenomen in gemiddelde',
      one:
          '1 gedeeltelijke tankbeurt wacht op volledige tank — niet meegenomen in gemiddelde',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% van brandstof uit auto-correcties — bekijk invoer';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel => 'Auto-correctie — tik om te bewerken';

  @override
  String get fillUpCorrectionEditTitle => 'Auto-correctie bewerken';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Deze invoer werd automatisch aangemaakt om het verschil tussen geregistreerde ritten en getankte brandstof te overbruggen. Pas de waarden aan als je de werkelijke cijfers kent.';

  @override
  String get fillUpCorrectionDelete => 'Correctie verwijderen';

  @override
  String get fillUpCorrectionStation => 'Stationsnaam (optioneel)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Griekenland)';

  @override
  String get greeceCommunityApiNotice =>
      'Mogelijk gemaakt door de door de community onderhouden fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Roemenië)';

  @override
  String get romaniaScrapingNotice =>
      'Mogelijk gemaakt door pretcarburant.ro (Mededingingsraad + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country-stations $km km verderop — €$price/L goedkoper';
  }

  @override
  String get crossBorderTapToSwitch => 'Tik om van land te wisselen';

  @override
  String get crossBorderDismissTooltip => 'Sluiten';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Ontwikkelaarstools';

  @override
  String get developerToolsSubtitle =>
      'Diagnostiek en hulpmiddelen om te debuggen — alleen zichtbaar in ontwikkelaars-/foutopsporingsmodus.';

  @override
  String get developerToolsMenuSubtitle =>
      'Foutenlogboek, testmeldingen, diagnostiek';

  @override
  String get developerToolsErrorLogGroupTitle => 'Foutenlogboek';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Foutenlogboek opslaan ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Foutenlogboek wissen';

  @override
  String get developerToolsViewErrorLog => 'Foutenlogboek bekijken';

  @override
  String get developerToolsErrorLogEmpty => 'Geen fouttraces geregistreerd.';

  @override
  String get developerToolsAlertsGroupTitle => 'Waarschuwingen en meldingen';

  @override
  String get developerToolsFireTestNotification => 'Testmelding versturen';

  @override
  String get developerToolsTestNotificationTitle => 'Testmelding';

  @override
  String get developerToolsTestNotificationBody =>
      'Als je dit kunt lezen, werken meldingen.';

  @override
  String get developerToolsTestNotificationSent => 'Testmelding verzonden.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Meldingen zijn geblokkeerd — schakel ze in via de systeeminstellingen en probeer het opnieuw.';

  @override
  String get developerToolsRunTestAlert =>
      'Testwaarschuwingspijplijn uitvoeren';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testwaarschuwing geactiveerd — pijplijn leverde $count melding(en).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testprijswaarschuwing';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Synthetische match: er is in de buurt een station onder je doel gevonden.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostiek';

  @override
  String get developerToolsFeatureFlagDump => 'Inspecteur voor functievlaggen';

  @override
  String get developerToolsFlagOn => 'Aan';

  @override
  String get developerToolsFlagOff => 'Uit';

  @override
  String get developerToolsClearCaches => 'Caches wissen';

  @override
  String get developerToolsCachesCleared => 'Caches gewist.';

  @override
  String get developerToolsCopyDiagnostics => 'Diagnostiek kopiëren';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostiek gekopieerd naar klembord.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Build-informatie';

  @override
  String get developerToolsBuildVersion => 'App-versie';

  @override
  String get developerToolsBuildChannel => 'Build-kanaal';

  @override
  String get insightCardTitle => 'Meest verspillende rijgedrag';

  @override
  String get insightEmptyState =>
      'Geen noemenswaardige inefficiënties — ga zo door!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor boven 3000 RPM ($pctTime% van rit): $liters L verspild';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count keer hard opgetrokken: $liters L verspild';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Stationair draaien ($pctTime% van rit): $liters L verspild';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% van rit';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Te laag toerental ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Zet de motor uit bij lange stops in plaats van hem stationair te laten draaien.';

  @override
  String get lessonAdviceHighRpm =>
      'Schakel eerder op om de motor uit het hoge toerenbereik te houden.';

  @override
  String get lessonAdviceHardAccel =>
      'Geef rustig gas — soepel accelereren verbruikt minder brandstof.';

  @override
  String get lessonAdviceLowGear =>
      'Schakel eerder op zodat de motor in een lager, zuiniger toerental komt.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Aanhoudend hoge snelheid ($pctTime% van de rit): $liters L verspild';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Aanhoudend hoge snelheid ($pctTime% van de rit)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Laat boven 110 km/u het gas los – de luchtweerstand neemt sterk toe, iets langzamer bespaart veel brandstof.';

  @override
  String get lessonSmoothDrivingTitle => 'Soepel rijden – goed gedaan!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Geen hard optrekken of remmen deze rit – gelijkmatig rijden houdt het verbruik laag.';

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
  String get drivingScoreCardTitle => 'Rijscore';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Samengestelde score op basis van stationair draaien, hard optrekken, hard remmen en hoog-toerental tijd. Een vergelijking \'beter dan X% van eerdere ritten\' volgt in een toekomstige release.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Rijscore $score van 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Stationair draaien';

  @override
  String get drivingScorePenaltyHardAccel => 'Hard optrekken';

  @override
  String get drivingScorePenaltyHardBrake => 'Hard remmen';

  @override
  String get drivingScorePenaltyHighRpm => 'Hoog toerental';

  @override
  String get drivingScorePenaltyFullThrottle => 'Vol gas';

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
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L bespaard';
  }

  @override
  String get ecoRouteHint =>
      'Slimmere rit — geeft voorkeur aan rustige snelweg boven zigzag-snelkoppelingen.';

  @override
  String get favoritesShareAction => 'Delen';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favorieten op $date';
  }

  @override
  String get favoritesShareError =>
      'Deelafbeelding kon niet worden gegenereerd';

  @override
  String get featureManagementSectionTitle => 'Functiebeheer';

  @override
  String get featureManagementSectionSubtitle =>
      'Schakel individuele functies in of uit. Sommige functies zijn afhankelijk van andere — schakelaars zijn uitgeschakeld totdat aan de vereisten is voldaan.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2-ritopname';

  @override
  String get featureDescription_obd2TripRecording =>
      'Ritten automatisch vastleggen via OBD2.';

  @override
  String get featureLabel_gamification => 'Gamificatie';

  @override
  String get featureDescription_gamification =>
      'Rijscores en verdiende badges.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptische ecocoach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Realtime haptische feedback tijdens een rit.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync => 'Cross-device sync via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Verbruiksanalyse';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Tabblad voor tankbeurt- en ritanalyse.';

  @override
  String get featureLabel_baselineSync => 'Baselinesynchro nisatie';

  @override
  String get featureDescription_baselineSync =>
      'Rijbaselines synchroniseren via TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Gecombineerde zoekresultaten';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Enkele resultatenlijst met brandstof- en EV-stations gecombineerd.';

  @override
  String get featureLabel_priceAlerts => 'Prijsmeldingen';

  @override
  String get featureDescription_priceAlerts =>
      'Meldingen bij prijsdaling op basis van drempelwaarde.';

  @override
  String get featureLabel_priceHistory => 'Prijsgeschiedenis';

  @override
  String get featureDescription_priceHistory =>
      'Prijsgrafieken van 30 dagen op stationsdetails.';

  @override
  String get featureLabel_routePlanning => 'Routeplanning';

  @override
  String get featureDescription_routePlanning =>
      'Goedkoopste stop langs je route.';

  @override
  String get featureLabel_evCharging => 'EV-laden';

  @override
  String get featureDescription_evCharging => 'Laadstations via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling-begeleiding met OSM-verkeerslichten.';

  @override
  String get featureLabel_gpsTripPath => 'GPS-ritpad';

  @override
  String get featureDescription_gpsTripPath =>
      'GPS-padsteekproeven opslaan bij elke rit.';

  @override
  String get featureLabel_autoRecord => 'Automatisch opnemen';

  @override
  String get featureDescription_autoRecord =>
      'Automatisch een rit starten als de OBD2-adapter verbinding maakt met een rijdend voertuig.';

  @override
  String get featureLabel_showFuel => 'Tankstations tonen';

  @override
  String get featureDescription_showFuel =>
      'Benzine/diesel-stationsresultaten weergeven in zoeken en op de kaart.';

  @override
  String get featureLabel_showElectric => 'Laadstations tonen';

  @override
  String get featureDescription_showElectric =>
      'EV-laadstations weergeven in zoeken en op de kaart.';

  @override
  String get featureLabel_showConsumptionTab => 'Tabblad Verbruik';

  @override
  String get featureDescription_showConsumptionTab =>
      'Het tabblad Verbruiksanalyse tonen in de onderste navigatie.';

  @override
  String get featureBlockedEnable_gamification =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureBlockedEnable_baselineSync => 'Schakel eerst TankSync in';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureBlockedEnable_showFuel => 'Vereisten niet voldaan';

  @override
  String get featureBlockedEnable_showElectric => 'Vereisten niet voldaan';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite-prijsvoorspelling';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Prijsvoorspellingsmodel op het apparaat — inferentie draait lokaal; kenmerken en voorspellingen verlaten het apparaat nooit.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Schakel eerst prijsgeschiedenis in';

  @override
  String get featureLabel_fuelCalculator => 'Brandstofrekenmachine';

  @override
  String get featureDescription_fuelCalculator =>
      'Bereikbare brandstofkostenrekenmachine vanuit de zoekresultaten.';

  @override
  String get featureLabel_carbonDashboard => 'CO2-dashboard';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2-voetafdrukdashboard bereikbaar via het tabblad Verbruik.';

  @override
  String get featureLabel_experimentalOemPids => 'Experimentele OEM PIDs';

  @override
  String get featureDescription_experimentalOemPids =>
      'Exacte tankliters uitlezen via fabrikantspecifieke PIDs op ondersteunde adapters.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Schakel eerst OBD2-ritopname in';

  @override
  String get featureLabel_paymentQrScan => 'Betaal-QR scannen';

  @override
  String get featureDescription_paymentQrScan =>
      'QR-scan-to-pay op het stationsdetailscherm.';

  @override
  String get featureLabel_communityPriceReports => 'Community-prijsrapporten';

  @override
  String get featureDescription_communityPriceReports =>
      'Een stationsprijs melden via het stationsdetailscherm.';

  @override
  String get featureLabel_obd2Optional => 'OBD2 vereisen voor ritopname';

  @override
  String get featureDescription_obd2Optional =>
      'Indien uit, neemt de app alleen-GPS-ritten op zonder OBD2-adapter. Coaching is beperkt — geen direct L/100 km, minder motorgegevens.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Bon OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Scan een gedrukte bon op het scherm Tankbeurt toevoegen om datum, liters, totaal en station automatisch in te vullen.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'Pomp-display OCR (experimenteel)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Scan een tankpompdisplay om het formulier vooraf in te vullen. Herkenning is vandaag onbetrouwbaar — schakel alleen in als je wilt testen.';

  @override
  String get featureLabel_developerPatToken =>
      'Ontwikkelaarsfeedback (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Schakelt het feedbackpaneel voor mislukte scans in dat met een Personal Access Token automatisch GitHub-issues aanmaakt. Functie voor gevorderde gebruikers / bijdragers.';

  @override
  String get featureLabel_debugMode => 'Ontwikkelaars-/foutopsporingsmodus';

  @override
  String get featureDescription_debugMode =>
      'Toont een sectie Ontwikkelaarstools in de instellingen met diagnostiek: export van het foutenlogboek, testmeldingen, een testwaarschuwingspijplijn, een functievlag-overzicht, caches wissen en diagnostiek kopiëren.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get feedbackConsentTitle => 'Rapport versturen naar GitHub?';

  @override
  String get feedbackConsentBody =>
      'Hiermee wordt een openbaar ticket aangemaakt op onze GitHub-repository met je foto en de OCR-tekst. Er worden geen persoonsgegevens (locatie, account-id) meegestuurd. Doorgaan?';

  @override
  String get feedbackConsentContinue => 'Doorgaan';

  @override
  String get feedbackConsentCancel => 'Annuleren';

  @override
  String get feedbackConsentLater => 'Later';

  @override
  String get feedbackTokenSectionTitle => 'Feedback over slechte scan (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Om automatisch een GitHub-ticket te openen bij een mislukte scan, plak je een GitHub PAT (`public_repo`-scope op de tankstellen-repository). Anders blijft handmatig delen beschikbaar.';

  @override
  String get feedbackTokenStatusSet => 'Token geconfigureerd';

  @override
  String get feedbackTokenStatusUnset => 'Geen token';

  @override
  String get feedbackTokenSet => 'Instellen';

  @override
  String get feedbackTokenClear => 'Wissen';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Persoonlijk toegangstoken';

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
      'Geverifieerd door adapter';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Komt niet overeen met adapteraflezing';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Jouw invoer: $userL L. Adapter zegt: $adapterL L (delta van voor/na brandstofniveaumeting). Adapterwaarde gebruiken?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Mijn invoer bewaren';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Adapterwaarde gebruiken';

  @override
  String get scanReceiptNoData => 'Geen bongegevens gevonden — probeer opnieuw';

  @override
  String get scanReceiptSuccess =>
      'Bon gescand — verifieer de waarden. Tik hieronder op \"Scanfout melden\" als er iets niet klopt.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scan mislukt: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Pompdisplay niet leesbaar — probeer opnieuw';

  @override
  String get scanPumpSuccess => 'Pompdisplay gescand — verifieer de waarden.';

  @override
  String get scanPumpGlare =>
      'Te veel weerschijn op het display — probeer het opnieuw onder een lichte hoek zodat de cijfers niet overstraald zijn.';

  @override
  String scanPumpFailed(String error) {
    return 'Pompscan mislukt: $error';
  }

  @override
  String get badScanReportTitle => 'Scanfout melden';

  @override
  String get badScanReportTitleReceipt => 'Scanfout melden — Bon';

  @override
  String get badScanReportTitlePumpDisplay => 'Scanfout melden — Pompdisplay';

  @override
  String get pumpScanFailureTitle => 'Display niet leesbaar';

  @override
  String get pumpScanFailureBody =>
      'De scan kon het pompdisplay niet lezen. Wat wil je doen?';

  @override
  String get pumpScanFailureCorrectManually => 'Handmatig corrigeren';

  @override
  String get pumpScanFailureReport => 'Melden';

  @override
  String get pumpScanFailureRemove => 'Foto verwijderen';

  @override
  String get badScanReportHint =>
      'We delen de bonfoto en beide sets waarden zodat de volgende versie deze indeling kan leren.';

  @override
  String get badScanReportShareAction => 'Rapport + foto delen';

  @override
  String get badScanReportFieldBrandLayout => 'Merkindeling';

  @override
  String get badScanReportFieldTotal => 'Totaal';

  @override
  String get badScanReportFieldPricePerLiter => 'Prijs/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Brandstof';

  @override
  String get badScanReportFieldDate => 'Datum';

  @override
  String get badScanReportHeaderField => 'Veld';

  @override
  String get badScanReportHeaderScanned => 'Gescand';

  @override
  String get badScanReportHeaderYouTyped => 'Ingetypt';

  @override
  String get badScanReportCreateTicket => 'Issue aanmaken';

  @override
  String get badScanReportOpenInBrowser => 'Openen in browser';

  @override
  String get badScanReportFallbackToShare =>
      'Verzending mislukt — handmatig delen';

  @override
  String get pumpCameraHint =>
      'Lijn de drie cijfers van het pompdisplay uit binnen het kader';

  @override
  String get pumpCameraCapture => 'Vastleggen';

  @override
  String get pumpCameraPermissionDenied =>
      'Cameratoegang is nodig om het pompdisplay te scannen. Schakel het in bij de apparaatinstellingen.';

  @override
  String get pumpCameraError =>
      'De camera kon niet starten. Probeer opnieuw of voer de waarden handmatig in.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Schakel naar horizontale weergave';

  @override
  String get pumpCameraOrientationVertical => 'Schakel naar verticale weergave';

  @override
  String get pumpCameraGlareWarning =>
      'Te veel glans — kantel iets om reflecties te vermijden';

  @override
  String get pumpCameraAlignHint =>
      'Lijn het scherm uit in het kader en maak een foto';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Wat je getankt hebt';

  @override
  String get fillUpSectionWhatSubtitle => 'Brandstof, hoeveelheid, prijs';

  @override
  String get fillUpSectionWhereTitle => 'Waar je was';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, kilometerstand, notities';

  @override
  String get fillUpImportFromLabel => 'Importeren uit…';

  @override
  String get fillUpImportSheetTitle => 'Tankbeurtgegevens importeren';

  @override
  String get fillUpImportReceiptLabel => 'Bon';

  @override
  String get fillUpImportReceiptDescription =>
      'Scan een papieren bon met de camera';

  @override
  String get fillUpImportPumpLabel => 'Pompdisplay';

  @override
  String get fillUpImportPumpDescription =>
      'Bedrag/Prijs aflezen van het pomp-LCD';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Kilometerstand uitlezen via de OBD-II poort over Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Prijs per liter';

  @override
  String get vehicleHeaderPlateLabel => 'Kenteken';

  @override
  String get vehicleHeaderUntitled => 'Nieuw voertuig';

  @override
  String get vehicleSectionIdentityTitle => 'Identiteit';

  @override
  String get vehicleSectionIdentitySubtitle => 'Naam & VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Aandrijflijn';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Hoe dit voertuig rijdt';

  @override
  String get calibrationModeLabel => 'Kalibratiemodus';

  @override
  String get calibrationModeRule => 'Regelgebaseerd';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Regelgebaseerd wijst elke rijsteekproef toe aan precies één situatie. Fuzzy verdeelt het over alle situaties op basis van hoe goed elk past — soepeler rond 60 km/h of wisselende hellingen, maar langzamer om alle bakken te vullen.';

  @override
  String get profileGamificationToggleTitle => 'Prestaties en scores tonen';

  @override
  String get profileGamificationToggleSubtitle =>
      'Als uitgeschakeld, zijn badges, scores en trofee-iconen overal in de app verborgen.';

  @override
  String get coachingGpsLiftOff => 'Loslaten';

  @override
  String get coachingGpsAnticipateBrake => 'Anticiperen';

  @override
  String get coachingGpsSmoothAccel => 'Soepel optrekken';

  @override
  String get gpsDiagnosticsTitle => 'GPS-steekproefdiagnostiek';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps hiaten',
      one: '1 hiaat',
      zero: 'geen hiaten',
    );
    return '$count steekproeven · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Mediaan interval: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Vastgelegd tijdens opname om GPS-cadans te verifiëren tijdens telefoonscherm-uit.';

  @override
  String get gpsMatrixMaturityCold => 'Koud';

  @override
  String get gpsMatrixMaturityWarming => 'Opwarmen';

  @override
  String get gpsMatrixMaturityConverged => 'Geconvergeerd';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS-matrix warmt nog op ($count verfijningen tot nu toe). Schattingen zijn voorlopig.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS-matrix convergeert ($count tankbeurten). Schattingen bruikbaar maar kunnen enkele % afwijken.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS-matrix is geconvergeerd ($count tankbeurten). Schattingen binnen ~2 % van werkelijk verbruik.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Rijden';

  @override
  String get hapticEcoCoachSettingTitle => 'Realtime eco-coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Zachte trilling + tip op het scherm als je vol gas geeft tijdens het cruisen';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Rustig aan het gas — uitrollen bespaart meer';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigeer naar $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return '$name uit favorieten verwijderen';
  }

  @override
  String get showOnMapSemanticLabel => 'Toon stations op de kaart';

  @override
  String get searchResultsSemanticLabel => 'Zoekresultaten';

  @override
  String get searchCriteriaSemanticLabel =>
      'Samenvatting van zoekcriteria. Tik om te bewerken.';

  @override
  String get noFavoritesSemanticLabel =>
      'Nog geen favorieten. Tik op de ster van een station om het als favoriet op te slaan.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Station is open',
      'false': 'Station is gesloten',
      'other': 'Station is gesloten',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Land $name, geselecteerd',
      'false': 'Land $name',
      'other': 'Land $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Taal $name, geselecteerd',
      'false': 'Taal $name',
      'other': 'Taal $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sorteren op $option, geselecteerd',
      'false': 'Sorteren op $option',
      'other': 'Sorteren op $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Brandstof $type, geselecteerd',
      'false': 'Brandstof $type',
      'other': 'Brandstof $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Laadstation $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Privacyschild met brandstofdruppel';

  @override
  String get globeIllustrationSemantic =>
      'Wereldbol met tankstationmarkeringen';

  @override
  String get fuelPumpIllustrationSemantic => 'Benzinepomp met prijsticker';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, gegevensbron: $provider, $keyRequirement, brandstoftypes: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'API-sleutel vereist';

  @override
  String get countryInfoNoKeyNeeded => 'Gratis, geen sleutel nodig';

  @override
  String countryInfoDataSource(String provider) {
    return 'Gegevens: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Brandstoftypes: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anonieme sleutel';

  @override
  String get anonKeyHideTooltip => 'Sleutel verbergen';

  @override
  String get anonKeyShowTooltip => 'Sleutel tonen om te verifiëren';

  @override
  String anonKeyTooLong(int length) {
    return 'Sleutel is te lang ($length tekens) — controleer op extra tekst';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Sleutel ziet er correct uit ($length tekens)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Sleutel moet een JWT zijn (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Sleutel is mogelijk afgekapt ($length van ~208 verwachte tekens)';
  }

  @override
  String get anonKeyExceedsMax => 'Sleutel overschrijdt de maximale lengte';

  @override
  String get qrShareTitle => 'Je database delen';

  @override
  String get qrShareSubtitle =>
      'Anderen kunnen deze QR-code scannen om verbinding te maken';

  @override
  String get qrShareCopyAsText => 'Kopiëren als tekst';

  @override
  String get authInfoTitle => 'Waarom een account aanmaken?';

  @override
  String get authInfoBenefit1 =>
      '• Favorieten, meldingen en opgeslagen routes synchroniseren via apparaten';

  @override
  String get authInfoBenefit2 =>
      '• Bereid een route voor op je telefoon, gebruik hem in je auto';

  @override
  String get authInfoBenefit3 => '• Er worden geen gegevens gedeeld met derden';

  @override
  String get authInfoBenefit4 =>
      '• Je kunt je account op elk moment verwijderen';

  @override
  String get privacyLocalDataEmpty =>
      'Nog niets opgeslagen. Voeg een favoriet toe of stel een prijsmelding in om hier vermeldingen te zien.';

  @override
  String get privacyHideEmptyRows => 'Lege rijen verbergen';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toon $count lege rijen',
      one: 'Toon $count lege rij',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-sleutelinstellingen (optioneel)';

  @override
  String get apiKeySetupDescription =>
      'Registreer voor een gratis API-sleutel, of sla dit over om de app met demogegevens te verkennen.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider registratie';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Door een API-sleutel in te voeren, accepteer je de voorwaarden van $provider. Herverdeling van gegevens is verboden.';
  }

  @override
  String get calculatorDistanceHint => 'bijv. 150';

  @override
  String get calculatorConsumptionHint => 'bijv. 7.0';

  @override
  String get calculatorPriceHint => 'bijv. 1.899';

  @override
  String get routeStrategyLabel => 'Strategie:';

  @override
  String get routeStrategyUniform => 'Uniform';

  @override
  String get routeStrategyBalanced => 'Gebalanceerd';

  @override
  String get glideCoachBetaTitle => 'Glide-coach bèta (experimenteel)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtiele trilling bij het afremmen voor een rood licht. Standaard uit — afleiding risico.';

  @override
  String get consentSyncTripsTitle => 'Ritopnames synchroniseren';

  @override
  String get consentSyncTripsSubtitle =>
      'OBD2 + GPS-ritten back-uppen naar TankSync. Cross-device, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Schakel hierboven Cloudsync in om ritten te back-uppen.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Meld je aan met een e-mailaccount om ritten tussen apparaten te synchroniseren.';

  @override
  String get consentHideDetails => 'Details verbergen';

  @override
  String get consentShowDetails => 'Details tonen';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Ongeldige koppeling';

  @override
  String invalidLinkBody(String path) {
    return 'De koppeling \"$path\" is niet geldig.';
  }

  @override
  String get home => 'Home';

  @override
  String get locationConsentTitle => 'Locatietoegang';

  @override
  String get locationConsentSubtitle =>
      'Deze app wil je locatie gebruiken om tankstations in de buurt te vinden.';

  @override
  String get locationConsentWhatHappens =>
      'Wat er met je locatiegegevens gebeurt:';

  @override
  String get locationConsentBulletApi =>
      'Je coördinaten worden naar de brandstofprijs-API gestuurd om tankstations in de buurt te vinden.';

  @override
  String get locationConsentBulletNoServer =>
      'Je locatie wordt op geen enkele server opgeslagen — er is geen server.';

  @override
  String get locationConsentBulletNoTracking =>
      'Locatiegegevens worden niet gebruikt voor advertenties, analyse of tracking.';

  @override
  String get locationConsentRevoke =>
      'Je kunt de locatietoegang op elk moment intrekken in de systeeminstellingen. Je kunt ook zoeken op postcode.';

  @override
  String get locationConsentLegalBasis =>
      'Rechtsgrondslag: art. 6, lid 1, onder a) AVG (toestemming)';

  @override
  String get locationConsentDecline => 'Weigeren';

  @override
  String get locationConsentAccept => 'Accepteren';

  @override
  String get loyaltySettingsTitle => 'Tankpaskaarten';

  @override
  String get loyaltySettingsSubtitle =>
      'Pas je loyaliteitskorting toe op weergegeven prijzen';

  @override
  String get loyaltyMenuTitle => 'Tankpaskaarten';

  @override
  String get loyaltyMenuSubtitle =>
      'Kortingen per liter toepassen van Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Kaart toevoegen';

  @override
  String get loyaltyAddCardSheetTitle => 'Tankpas toevoegen';

  @override
  String get loyaltyBrandLabel => 'Merk';

  @override
  String get loyaltyCardLabelLabel => 'Label (optioneel)';

  @override
  String get loyaltyDiscountLabel => 'Korting (per liter)';

  @override
  String get loyaltyDiscountInvalid => 'Voer een positief getal in';

  @override
  String get loyaltyDeleteConfirmTitle => 'Kaart verwijderen?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Deze kaart past zijn korting niet meer toe.';

  @override
  String get loyaltyEmptyTitle => 'Nog geen tankpaskaarten';

  @override
  String get loyaltyEmptyBody =>
      'Voeg een kaart toe om je korting per liter automatisch toe te passen op overeenkomende stations.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Toenemend stationair toerental gedetecteerd';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Het stationair toerental is met $percent% gestegen over je laatste $tripCount ritten. Mogelijke vroeg teken van een verstopt luchtfilter of sensordrift.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Mogelijke inlaatbeperking';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Het cruisebrandstofverbruik is met $percent% gedaald over je laatste $tripCount ritten. Mogelijk teken van een verstopt luchtfilter of beperkte inlaat — een controle is de moeite waard.';
  }

  @override
  String get maintenanceActionDismiss => 'Sluiten';

  @override
  String get maintenanceActionSnooze => '30 dagen uitstellen';

  @override
  String get consumptionMonthlyInsightsTitle => 'Deze maand vs. vorige maand';

  @override
  String get consumptionMonthlyTripsLabel => 'Ritten';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Rijtijd';

  @override
  String get consumptionMonthlyDistanceLabel => 'Afstand';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Gem. verbruik';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Minimaal 3 ritten per maand nodig voor vergelijking';

  @override
  String get obd2CapabilitySectionTitle => 'Adaptermogelijkheden';

  @override
  String get obd2CapabilityStandardOnly => 'Standaard';

  @override
  String get obd2CapabilityOemPids => 'OEM PIDs';

  @override
  String get obd2CapabilityFullCan => 'Volledig CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Voor exacte liters-in-tank bij Peugeot/Citroën ondersteunt de app OBDLink MX+/LX/CX (STN-chip).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2-diagnostiekoverlay ingeschakeld';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2-diagnostiekoverlay uitgeschakeld';

  @override
  String get obd2DebugOverlayClearButton => 'Wissen';

  @override
  String get obd2DebugOverlayCloseButton => 'Sluiten';

  @override
  String get obd2DebugOverlayTitle => 'OBD2-breadcrumbs';

  @override
  String get obd2DiagnosticShareLabel => 'Diagnoselogboek delen';

  @override
  String get obd2DebugLoggingTitle => 'OBD2-foutopsporingslogboek';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Leg elke OBD2-sessie vast — verbinding, handshake, gegevensonderbrekingen en herverbindingen — in een exporteerbaar XML-logboek. Standaard uitgeschakeld.';

  @override
  String get obd2DebugSessionShareLabel => 'OBD2-sessielogboek delen';

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
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Kon \'$adapterName\' niet bereiken — kies een andere adapter';
  }

  @override
  String get onboardingObd2StepTitle => 'Verbind je OBD2-adapter';

  @override
  String get onboardingObd2StepBody =>
      'Sluit je OBD2-adapter aan op de poort van de auto en zet het contact aan. We lezen het VIN en vullen de motorgegevens voor je in.';

  @override
  String get onboardingObd2ConnectButton => 'Adapter verbinden';

  @override
  String get onboardingObd2SkipButton => 'Misschien later';

  @override
  String get onboardingObd2ReadingVin => 'VIN uitlezen…';

  @override
  String get onboardingObd2VinReadFailed =>
      'VIN kon niet worden uitgelezen — voer handmatig in';

  @override
  String get onboardingObd2ConnectFailed =>
      'Verbinding met adapter mislukt. Je kunt opnieuw proberen of overslaan.';

  @override
  String get onboardingPickUseMode => 'Kies een gebruiksmodus om door te gaan.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'verstreken';

  @override
  String get alertsRadiusFrequencyLabel => 'Controlefrequentie';

  @override
  String get alertsRadiusFrequencyDaily => 'Eén keer per dag';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Twee keer per dag';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Drie keer per dag';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Vier keer per dag';

  @override
  String get radiusAlertPickOnMap => 'Op kaart kiezen';

  @override
  String get radiusAlertMapPickerTitle => 'Centrum van melding kiezen';

  @override
  String get radiusAlertMapPickerConfirm => 'Bevestigen';

  @override
  String get radiusAlertMapPickerCancel => 'Annuleren';

  @override
  String get radiusAlertMapPickerHint =>
      'Sleep de kaart om het centrum van de melding te positioneren';

  @override
  String get radiusAlertCenterFromMap => 'Kaartlocatie';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel bij $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Een station heeft $price € (doel: $threshold €)';
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
  String get refuelUnitPerSession => '/sessie';

  @override
  String get speedConsumptionCardTitle => 'Verbruik per snelheid';

  @override
  String get speedBandIdleJam => 'Stationair / file';

  @override
  String get speedBandUrban => 'Stedelijk (10–50)';

  @override
  String get speedBandSuburban => 'Voorstedelijk (50–80)';

  @override
  String get speedBandRural => 'Landelijk (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-cruise (100–115)';

  @override
  String get speedBandMotorway => 'Snelweg (115–130)';

  @override
  String get speedBandMotorwayFast => 'Snelweg snel (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Neem 30+ minuten ritten op met de OBD2-adapter om de snelheid/verbruiksanalyse te ontgrendelen.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % van rijden';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Meer gegevens nodig';

  @override
  String get splashLoadingLabel => 'Sparkilo laden';

  @override
  String get storageRecoveryTitle => 'Opslagprobleem';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo kon zijn lokale gegevensopslag niet openen. Het opslagbestand lijkt beschadigd te zijn.';

  @override
  String get storageRecoveryGuidance =>
      'Wis voor herstel de opslag van de app in de apparaatinstellingen of installeer de app opnieuw. Je favorieten en geschiedenis worden alleen op dit apparaat opgeslagen en kunnen daarom niet automatisch worden hersteld.';

  @override
  String get tankLevelTitle => 'Tankinhoud';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km bereik';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Laatste tankbeurt: $date · $count rit(ten) daarna';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2-meting';

  @override
  String get tankLevelMethodDistanceFallback => 'afstandsgebaseerde schatting';

  @override
  String get tankLevelMethodMixed => 'gemengde meting';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Registreer een tankbeurt om je tankinhoud te zien';

  @override
  String get tankLevelDetailSheetTitle => 'Ritten na laatste tankbeurt';

  @override
  String get addFillUpIsFullTankLabel => 'Volle tank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tank helemaal vol — vink uit als dit een gedeeltelijke tankbeurt was';

  @override
  String get themeCardTitle => 'Thema';

  @override
  String get themeCardSubtitleSystem => 'Systeem';

  @override
  String get themeCardSubtitleLight => 'Licht';

  @override
  String get themeCardSubtitleDark => 'Donker';

  @override
  String get themeSettingsScreenTitle => 'Thema';

  @override
  String get themeSettingsSystemLabel => 'Systeem volgen';

  @override
  String get themeSettingsLightLabel => 'Licht';

  @override
  String get themeSettingsDarkLabel => 'Donker';

  @override
  String get themeSettingsSystemDescription =>
      'Volg de huidige apparaatweergave.';

  @override
  String get themeSettingsLightDescription =>
      'Lichte achtergronden — het beste voor gebruik overdag.';

  @override
  String get themeSettingsDarkDescription =>
      'Donkere achtergronden — aangenamer voor de ogen \'s nachts en bespaart batterij op OLED-schermen.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'De kenmerkende groene look van de app — helder en makkelijk leesbaar, met zachtgroene achtergronden.';

  @override
  String get throttleRpmHistogramTitle => 'Hoe je de motor hebt gebruikt';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gaspedaalpositie';

  @override
  String get throttleRpmHistogramRpmSection => 'Motor-RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Uitrollen (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Licht (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Stevig (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Volledig open (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Stationair (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Cruisen (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Sportief (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Hard (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Geen gaspeaal- of RPM-steekproeven in deze rit.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Ritten';

  @override
  String get trajetsStartRecordingButton => 'Opname starten';

  @override
  String get trajetsResumeRecordingButton => 'Opname hervatten';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Verbinden met OBD2-adapter…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Voertuiggegevens uitlezen…';

  @override
  String get tripStartProgressStartingRecording => 'Opname starten…';

  @override
  String get trajetsEmptyStateTitle => 'Nog geen ritten';

  @override
  String get trajetsEmptyStateBody =>
      'Tik op Opname starten om je ritten te registreren.';

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
  String get trajetDetailSummaryTitle => 'Overzicht';

  @override
  String get trajetDetailFieldDate => 'Datum';

  @override
  String get trajetDetailFieldVehicle => 'Voertuig';

  @override
  String get trajetDetailFieldAdapter => 'OBD2-adapter';

  @override
  String get trajetDetailFieldDistance => 'Afstand';

  @override
  String get trajetDetailFieldDuration => 'Duur';

  @override
  String get trajetDetailFieldAvgConsumption => 'Gem. verbruik';

  @override
  String get trajetDetailFieldFuelUsed => 'Gebruikte brandstof';

  @override
  String get trajetDetailFieldFuelCost => 'Brandstofkosten';

  @override
  String get trajetDetailFieldAvgSpeed => 'Gem. snelheid';

  @override
  String get trajetDetailFieldMaxSpeed => 'Max. snelheid';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Snelheid (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Brandstofverbruik (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Motorbelasting (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Grafieken';

  @override
  String get trajetsRowColdStartChip => 'Koude start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motor bereikte de bedrijfstemperatuur niet tijdens deze rit — brandstofverbruik was hoger dan normaal.';

  @override
  String get trajetDetailChartEmpty => 'Geen steekproeven geregistreerd';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Delen';

  @override
  String get trajetDetailShareImageOption => 'Afbeelding delen';

  @override
  String get trajetDetailShareGpxOption => 'GPS-spoor (GPX) delen';

  @override
  String get trajetDetailShareGpxEmpty => 'Geen GPS-gegevens in deze rit';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — rit op $date';
  }

  @override
  String get trajetDetailShareError =>
      'Deelafbeelding kon niet worden gegenereerd';

  @override
  String get trajetDetailDeleteAction => 'Verwijderen';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Deze rit verwijderen?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Deze rit wordt permanent verwijderd uit je geschiedenis.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Annuleren';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Verwijderen';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2-adapter verbonden maar geeft geen gegevens terug. Probeer een andere adapter of controleer het diagnostische protocol van het voertuig.';

  @override
  String get trajetsViewAllOnMap => 'Alles op kaart tonen';

  @override
  String get trajetsMapTitle => 'Ritten op kaart';

  @override
  String get trajetsMapShareGpx => 'GPX delen';

  @override
  String get trajetsMapEmpty =>
      'Geen van de geselecteerde ritten bevat GPS-gegevens.';

  @override
  String get trajetsMapShareError => 'Kon het GPX-bestand niet delen';

  @override
  String get tripLengthCardTitle => 'Verbruik per ritlengte';

  @override
  String get tripLengthBucketShort => 'Kort (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Middellang (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Lang (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Meer gegevens nodig';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ritten',
      one: '1 rit',
      zero: 'geen ritten',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Ritpad';

  @override
  String get tripPathCardSubtitle => 'GPS-opgenomen route';

  @override
  String get tripPathLegendTitle => 'Verbruik';

  @override
  String get tripPathLegendEfficient => 'Efficiënt (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Grenswaarde (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Verspillend (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get tripRecordingPinTooltip =>
      'Vastpinnen houdt het scherm aan — verbruikt meer batterij';

  @override
  String get tripRecordingPinSemanticOn => 'Opnameformulier losmaken';

  @override
  String get tripRecordingPinSemanticOff => 'Opnameformulier vastpinnen';

  @override
  String get tripRecordingPinHelpTooltip => 'Wat doet vastzetten?';

  @override
  String get tripRecordingPinHelpTitle => 'Over vastzetten';

  @override
  String get tripRecordingPinHelpBody =>
      'Vastzetten houdt het scherm aan en verbergt de systeembalk zodat het formulier leesbaar blijft op een dashboardhouder. Tik opnieuw om te ontgrendelen. Wordt automatisch vrijgegeven als de rit stopt.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Opname gaat door op de achtergrond. Tik op de rode balk boven aan elk scherm om terug te keren.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Open de actieve rit via het tabblad Verbruik';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Zet het scherm vast om GPS actief te houden tijdens de rit — Android kan GPS beperken tijdens slaapstand.';

  @override
  String get tripRecordingMinimiseTooltip =>
      'Minimaliseren tot een zwevende tegel';

  @override
  String get tripRecordingAutoPinTitle =>
      'Altijd vastzetten bij start van de opname';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Zet het formulier automatisch vast bij elke rit in plaats van elke keer te tikken. Verbruikt meer batterij.';

  @override
  String get tripRecordingConnectingTitle => 'Opname starten…';

  @override
  String get tripShareAction => 'Delen met een ander account';

  @override
  String get tripShareSheetTitle => 'Deze rit delen';

  @override
  String get tripShareSheetSubtitle =>
      'Geef een ander TankSync-account alleen-lezentoegang tot deze opgenomen rit.';

  @override
  String get tripShareEmailLabel => 'E-mail van ontvanger';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Delen';

  @override
  String get tripShareCreateLinkButton => 'Deellink maken';

  @override
  String get tripShareLinkCreated =>
      'Deellink gekopieerd — plak hem voor de ontvanger.';

  @override
  String get tripShareSuccess => 'Rit gedeeld.';

  @override
  String get tripShareRecipientNotFound =>
      'Geen TankSync-account gebruikt dat e-mailadres.';

  @override
  String get tripShareError => 'Kan deze rit niet delen. Probeer het opnieuw.';

  @override
  String get tripShareExistingTitle => 'Gedeeld met';

  @override
  String get tripShareExistingEmpty => 'Nog met niemand gedeeld.';

  @override
  String get tripShareDirectRecipient => 'Een account';

  @override
  String get tripShareLinkRecipient => 'Deellink (niet geclaimd)';

  @override
  String get tripShareRevokeTooltip => 'Intrekken';

  @override
  String get tripShareRevoked => 'Delen ingetrokken.';

  @override
  String get trajetsSharedSectionTitle => 'Met mij gedeeld';

  @override
  String get trajetsSharedBadge => 'Gedeeld';

  @override
  String get unifiedFilterFuel => 'Brandstof';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Beide';

  @override
  String get unifiedNoResultsForFilter => 'Geen resultaten voor dit filter';

  @override
  String get searchFailedSnackbar => 'Zoeken mislukt — probeer het opnieuw';

  @override
  String get vinLabel => 'VIN (optioneel)';

  @override
  String get vinDecodeTooltip => 'VIN decoderen';

  @override
  String get vinConfirmAction => 'Ja, automatisch invullen';

  @override
  String get vinModifyAction => 'Handmatig aanpassen';

  @override
  String get veResetAction => 'Volumetrisch rendement resetten';

  @override
  String get vehicleReadVinFromCarButton => 'VIN van auto uitlezen';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'VIN uitlezen via de gekoppelde OBD2-adapter';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN niet beschikbaar (Modus 09 PID 02 niet ondersteund op voertuigen van vóór 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN uitlezen mislukt — voer handmatig in';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Koppel eerst een OBD2-adapter om het VIN automatisch uit te lezen';

  @override
  String get pickerButtonLabel => 'Uit catalogus kiezen';

  @override
  String get pickerSearchHint => 'Zoek merk of model';

  @override
  String get pickerHelpText => 'Voorinvullen uit 50+ ondersteunde voertuigen';

  @override
  String get pickerEmptyResults => 'Geen overeenkomsten';

  @override
  String get pickerCancel => 'Annuleren';

  @override
  String get pickerLoading => 'Catalogus laden…';

  @override
  String get vinInfoTooltip => 'Wat is een VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Wat is een VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Het voertuigidentificatienummer is een 17-tekens code die uniek is voor jouw auto. Het is ingeslagen op het chassis en staat op je kentekenbewijs.';

  @override
  String get vinInfoSectionWhyTitle => 'Waarom we ernaar vragen';

  @override
  String get vinInfoSectionWhyBody =>
      'Door het VIN te decoderen worden motorinhoud, cilindertelling, bouwjaar, primair brandstoftype en totaalgewicht automatisch ingevuld — zodat je geen technische specificaties hoeft op te zoeken. De OBD2-brandstofverbruikberekening gebruikt deze waarden voor nauwkeurige verbruikscijfers.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacy';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Je VIN wordt alleen lokaal opgeslagen in de versleutelde opslag van de app — het wordt nooit geüpload naar Sparkilo-servers. De NHTSA vPIC-database wordt bevraagd met het VIN maar geeft alleen anonieme technische specificaties terug; NHTSA koppelt het VIN niet aan persoonsgegevens. Zonder netwerk geeft een offline zoekopdracht alleen fabrikant en land terug.';

  @override
  String get vinInfoSectionWhereTitle => 'Waar je het kunt vinden';

  @override
  String get vinInfoSectionWhereBody =>
      'Kijk door de voorruit naar de linkeronderhoek aan de bestuurderszijde, controleer de sticker op het deurportaal aan de bestuurderszijde als de deur open is, of lees het af van je kentekenbewijs.';

  @override
  String get vinInfoDismiss => 'Begrepen';

  @override
  String get vinConfirmPrivacyNote =>
      'We hebben je VIN opgezocht in de gratis voertuigdatabase van NHTSA — er is niets naar Sparkilo-servers gestuurd.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online decoderen';

  @override
  String get gdprVinOnlineDecodeShort =>
      'VIN decoderen via de gratis openbare dienst van NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Als je een adapter koppelt, wordt het VIN van je voertuig lokaal uitgelezen om de auto te identificeren. Als je dit inschakelt, wordt het 17-tekens VIN naar de gratis vPIC-dienst van NHTSA gestuurd om extra details op te zoeken (model, motorinhoud, brandstoftype). Het VIN is de enige verzonden data — geen andere informatie verlaat je apparaat.';

  @override
  String get vehicleDetectedFromVinBadge => '(gedetecteerd)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Gedetecteerd via VIN: $summary. Toepassen?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Toepassen';

  @override
  String get widgetHelpSectionTitle => 'Widget voor startscherm';

  @override
  String get widgetHelpIntro =>
      'Voeg de SparKilo-widget toe aan je startscherm om brandstof- en laadprijzen in één oogopslag te zien.';

  @override
  String get widgetHelpAdd =>
      'Voeg hem toe via de widgetkiezer van je launcher — houd een leeg gedeelte van het startscherm ingedrukt, kies Widgets en zoek SparKilo.';

  @override
  String get widgetHelpTap =>
      'Tik op een station in de widget om het in de app te openen. Tik op het vernieuwicoon om prijzen bij te werken.';

  @override
  String get widgetHelpConfigure =>
      'Op Android: houd de widget ingedrukt en kies Herconfigueren om het profiel, de kleur en de inhoud te wijzigen.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'De keuzes hieronder gelden bij de volgende verversing voor elke geïnstalleerde widget.';

  @override
  String get widgetDefaultsColorLabel => 'Kleurenschema';

  @override
  String get widgetDefaultsVariantLabel => 'Inhoudsvariant';

  @override
  String get widgetColorSchemeSystem => 'Volg systeem';

  @override
  String get widgetColorSchemeLight => 'Licht';

  @override
  String get widgetColorSchemeDark => 'Donker';

  @override
  String get widgetColorSchemeBlue => 'Blauw';

  @override
  String get widgetColorSchemeGreen => 'Groen';

  @override
  String get widgetColorSchemeOrange => 'Oranje';

  @override
  String get widgetVariantDefault => 'Alleen huidige prijs';

  @override
  String get widgetVariantPredictive => 'Voorspellend: beste tijd om te tanken';

  @override
  String get widgetPredictiveNowPrefix => 'nu';
}
