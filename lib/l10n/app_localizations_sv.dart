// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Sök';

  @override
  String get favorites => 'Favoriter';

  @override
  String get map => 'Karta';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Inställningar';

  @override
  String get gpsLocation => 'GPS-position';

  @override
  String get zipCode => 'Postnummer';

  @override
  String get zipCodeHint => 't.ex. 111 22';

  @override
  String get fuelType => 'Bränsle';

  @override
  String get searchRadius => 'Radie';

  @override
  String get searchNearby => 'Bensinstationer i närheten';

  @override
  String get searchButton => 'Sök';

  @override
  String get fabOpenCriteria => 'Öppna sökning';

  @override
  String get fabOpenResults => 'Öppna resultat';

  @override
  String get fabRunSearch => 'Kör sökning';

  @override
  String get fabRefineCriteria => 'Förfina sökning';

  @override
  String get routeSearchPartialBanner => 'Söker efter fler stationer…';

  @override
  String get searchCriteriaTitle => 'Sökkriterier';

  @override
  String get searchCriteriaOpen => 'Sök';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Inom $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tryck för att börja söka';

  @override
  String get noResults => 'Inga bensinstationer hittades.';

  @override
  String get startSearch => 'Sök för att hitta bensinstationer.';

  @override
  String get open => 'Öppen';

  @override
  String get closed => 'Stängd';

  @override
  String distance(String distance) {
    return '$distance bort';
  }

  @override
  String get price => 'Pris';

  @override
  String get prices => 'Priser';

  @override
  String get address => 'Adress';

  @override
  String get openingHours => 'Öppettider';

  @override
  String get open24h => 'Öppet 24 timmar';

  @override
  String get navigate => 'Navigera';

  @override
  String get retry => 'Försök igen';

  @override
  String get apiKeySetup => 'API-nyckel';

  @override
  String get apiKeyDescription =>
      'Registrera dig en gång för att få en gratis API-nyckel.';

  @override
  String get apiKeyLabel => 'API-nyckel';

  @override
  String get register => 'Registrering';

  @override
  String get continueButton => 'Fortsätt';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle => 'Hitta det billigaste bränslet nära dig.';

  @override
  String get profileName => 'Profilnamn';

  @override
  String get preferredFuel => 'Föredraget bränsle';

  @override
  String get defaultRadius => 'Standardradie';

  @override
  String get landingScreen => 'Startskärm';

  @override
  String get homeZip => 'Hempostnummer';

  @override
  String get newProfile => 'Ny profil';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get save => 'Spara';

  @override
  String get cancel => 'Avbryt';

  @override
  String get countryChangeTitle => 'Byta land?';

  @override
  String countryChangeBody(String country) {
    return 'Byte till $country ändrar:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Avstånd';

  @override
  String get countryChangeVolume => 'Volym';

  @override
  String get countryChangePricePerUnit => 'Prisformat';

  @override
  String get countryChangeNote =>
      'Befintliga favoriter och tankningsloggar skrivs inte om; bara nya poster använder de nya enheterna.';

  @override
  String get countryChangeConfirm => 'Byt';

  @override
  String get delete => 'Ta bort';

  @override
  String get activate => 'Aktivera';

  @override
  String get configured => 'Konfigurerad';

  @override
  String get notConfigured => 'Ej konfigurerad';

  @override
  String get about => 'Om';

  @override
  String get openSource => 'Öppen källkod (MIT-licens)';

  @override
  String get sourceCode => 'Källkod på GitHub';

  @override
  String get noFavorites => 'Inga favoriter ännu';

  @override
  String get noFavoritesHint =>
      'Tryck på stjärnan vid en bensinstation för att spara den som favorit.';

  @override
  String get language => 'Språk';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demoläge — exempeldata visas.';

  @override
  String get setupLiveData => 'Konfigurera för live-data';

  @override
  String get freeNoKey => 'Gratis — ingen nyckel behövs';

  @override
  String get apiKeyRequired => 'API-nyckel krävs';

  @override
  String get skipWithoutKey => 'Fortsätt utan nyckel';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get storageAndCache => 'Lagring och cache';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String get clearAllData => 'Ta bort all data';

  @override
  String get errorLog => 'Fellogg';

  @override
  String stationsFound(int count) {
    return '$count bensinstationer hittades';
  }

  @override
  String get whatIsShared => 'Vad delas — och med vem?';

  @override
  String get gpsCoordinates => 'GPS-koordinater';

  @override
  String get gpsReason =>
      'Skickas med varje sökning för att hitta närliggande stationer.';

  @override
  String get postalCodeData => 'Postnummer';

  @override
  String get postalReason =>
      'Konverteras till koordinater via geokodarens tjänst.';

  @override
  String get mapViewport => 'Kartvy';

  @override
  String get mapReason =>
      'Kartplattor laddas från servern. Inga personuppgifter överförs.';

  @override
  String get apiKeyData => 'API-nyckel';

  @override
  String get apiKeyReason =>
      'Din personliga nyckel skickas med varje API-förfrågan. Den är kopplad till din e-post.';

  @override
  String get notShared => 'Delas INTE:';

  @override
  String get searchHistory => 'Sökhistorik';

  @override
  String get favoritesData => 'Favoriter';

  @override
  String get profileNames => 'Profilnamn';

  @override
  String get homeZipData => 'Hempostnummer';

  @override
  String get usageData => 'Användningsdata';

  @override
  String get privacyBanner =>
      'Denna app har ingen server. All data stannar på din enhet. Ingen analys, ingen spårning, ingen reklam.';

  @override
  String get storageUsage => 'Lagringsanvändning på denna enhet';

  @override
  String get settingsLabel => 'Inställningar';

  @override
  String get profilesStored => 'profiler sparade';

  @override
  String get stationsMarked => 'stationer markerade';

  @override
  String get cachedResponses => 'cachade svar';

  @override
  String get total => 'Totalt';

  @override
  String get cacheManagement => 'Cachehantering';

  @override
  String get cacheDescription =>
      'Cachen lagrar API-svar för snabbare laddning och offlineåtkomst.';

  @override
  String get cacheTtlGroupNetwork => 'Nätverk';

  @override
  String get cacheTtlGroupData => 'Data';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodning';

  @override
  String get stationSearch => 'Stationssökning';

  @override
  String get stationDetails => 'Stationsdetaljer';

  @override
  String get priceQuery => 'Prisförfrågan';

  @override
  String get zipGeocoding => 'Postnummergeokning';

  @override
  String minutes(int n) {
    return '$n minuter';
  }

  @override
  String hours(int n) {
    return '$n timmar';
  }

  @override
  String get clearCacheTitle => 'Rensa cache?';

  @override
  String get clearCacheBody =>
      'Cachade sökresultat och priser raderas. Profiler, favoriter och inställningar bevaras.';

  @override
  String get clearCacheButton => 'Rensa cache';

  @override
  String get deleteAllTitle => 'Ta bort all data?';

  @override
  String get deleteAllBody =>
      'Detta raderar permanent alla profiler, favoriter, API-nyckel, inställningar och cache. Appen återställs.';

  @override
  String get deleteAllButton => 'Ta bort allt';

  @override
  String get entries => 'poster';

  @override
  String get cacheEmpty => 'Cachen är tom';

  @override
  String get noStorage => 'Ingen lagring använd';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data från statliga pristransparensorgan.';

  @override
  String get apiKeyFormatError =>
      'Ogiltigt format — UUID förväntat (8-4-4-4-12)';

  @override
  String get supportProject => 'Stöd detta projekt';

  @override
  String get supportDescription =>
      'Denna app är gratis, öppen källkod och utan reklam. Om du tycker den är användbar, överväg att stödja utvecklaren.';

  @override
  String get reportBug => 'Rapportera fel / Föreslå funktion';

  @override
  String get reportThisIssue => 'Rapportera detta problem';

  @override
  String get reportAlreadySent => 'Du har redan rapporterat det här problemet.';

  @override
  String get reportConsentTitle => 'Rapportera till GitHub?';

  @override
  String get reportConsentBody =>
      'Det här öppnar ett offentligt GitHub-ärende med felinformationen nedan. Inga GPS-koordinater, API-nycklar eller personuppgifter ingår.';

  @override
  String get reportConsentConfirm => 'Öppna GitHub';

  @override
  String get reportConsentCancel => 'Avbryt';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktiv profil';

  @override
  String get configPreferredFuel => 'Favoritbränsle';

  @override
  String get configCountry => 'Land';

  @override
  String get configRouteSegment => 'Ruttsegment';

  @override
  String get configApiKeysSection => 'API-nycklar';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-nyckel';

  @override
  String get configApiKeyConfigured => 'Konfigurerad';

  @override
  String get configApiKeyNotSet => 'Inte inställd (demoläge)';

  @override
  String get configApiKeyCommunity => 'Standard (community-nyckel)';

  @override
  String get searchLocationPlaceholder => 'Adress, postnummer eller ort';

  @override
  String get configEvKey => 'EV-laddnings-API-nyckel';

  @override
  String get configEvKeyCustom => 'Anpassad nyckel';

  @override
  String get configEvKeyShared => 'Standard (delad)';

  @override
  String get configCloudSyncSection => 'Molnsynkronisering';

  @override
  String get configTankSyncConnected => 'Ansluten';

  @override
  String get configTankSyncDisabled => 'Inaktiverad';

  @override
  String get configAuthMode => 'Autentiseringsläge';

  @override
  String get configAuthEmail => 'E-post (beständig)';

  @override
  String get configAuthAnonymous => 'Anonym (endast denna enhet)';

  @override
  String get configDatabase => 'Databas';

  @override
  String get configPrivacySummary => 'Integritetsöversikt';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoriter, aviseringar och ignorerade stationer synkas till din privata databas\n• GPS-position och API-nycklar lämnar aldrig din enhet\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• All data lagras lokalt på den här enheten\n• Ingen data skickas till någon server\n• API-nycklar krypterade i enhetens säkra lagring';

  @override
  String get configAuthNoteEmail =>
      'E-postkonto möjliggör åtkomst från flera enheter';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymt konto – data kopplad till den här enheten';

  @override
  String get configNone => 'Ingen';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get fuels => 'Bränslen';

  @override
  String get services => 'Tjänster';

  @override
  String get zone => 'Zon';

  @override
  String get highway => 'Motorväg';

  @override
  String get localStation => 'Lokal station';

  @override
  String get lastUpdate => 'Senaste uppdatering';

  @override
  String get automate24h => '24t/24 — Automat';

  @override
  String get refreshPrices => 'Uppdatera priser';

  @override
  String get station => 'Bensinstation';

  @override
  String get locationDenied =>
      'Platstillstånd nekades. Du kan söka med postnummer.';

  @override
  String get demoModeBanner =>
      'Demoläge. Konfigurera API-nyckel i inställningar.';

  @override
  String get demoModeBannerAction => 'Hämta riktiga priser';

  @override
  String get sortDistance => 'Avstånd';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Betyg';

  @override
  String get sortPriceDistance => 'Pris/km';

  @override
  String get cheap => 'billig';

  @override
  String get expensive => 'dyr';

  @override
  String stationsOnMap(int count) {
    return '$count stationer';
  }

  @override
  String get loadingFavorites =>
      'Laddar favoriter...\nSök efter stationer först för att spara data.';

  @override
  String get reportPrice => 'Rapportera pris';

  @override
  String get whatsWrong => 'Vad är fel?';

  @override
  String get correctPrice => 'Korrekt pris (t.ex. 15,79)';

  @override
  String get sendReport => 'Skicka rapport';

  @override
  String get reportSent => 'Rapport skickad. Tack!';

  @override
  String get enterValidPrice => 'Ange ett giltigt pris';

  @override
  String get cacheCleared => 'Cache rensad.';

  @override
  String get yourPosition => 'Din position';

  @override
  String get positionUnknown => 'Position okänd';

  @override
  String get routeModeBannerLabel => 'Ruttläge — avstånd är längs korridoren';

  @override
  String get distancesFromCenter => 'Avstånd från sökcentrum';

  @override
  String get autoUpdatePosition => 'Uppdatera position automatiskt';

  @override
  String get autoUpdateDescription =>
      'Uppdatera GPS-position före varje sökning';

  @override
  String get location => 'Plats';

  @override
  String get switchProfileTitle => 'Land ändrat';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Du är nu i $country. Byta till profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Bytt till profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ingen profil för detta land';

  @override
  String noProfileForCountry(String country) {
    return 'Du är i $country, men ingen profil är konfigurerad. Skapa en i Inställningar.';
  }

  @override
  String get autoSwitchProfile => 'Automatiskt profilbyte';

  @override
  String get autoSwitchDescription =>
      'Byt profil automatiskt vid gränsöverskridande';

  @override
  String get switchProfile => 'Byt';

  @override
  String get dismiss => 'Stäng';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Språk';

  @override
  String get settingsStorageDetail => 'API-nyckel, aktiv profil';

  @override
  String get allFuels => 'Alla';

  @override
  String get priceAlerts => 'Prisvarningar';

  @override
  String get noPriceAlerts => 'Inga prisvarningar';

  @override
  String get noPriceAlertsHint =>
      'Skapa en varning från en stations detaljsida.';

  @override
  String alertDeleted(String name) {
    return 'Varning \"$name\" borttagen';
  }

  @override
  String get createAlert => 'Skapa prisvarning';

  @override
  String currentPrice(String price) {
    return 'Aktuellt pris: $price';
  }

  @override
  String get targetPrice => 'Målpris (EUR)';

  @override
  String get enterPrice => 'Ange ett pris';

  @override
  String get invalidPrice => 'Ogiltigt pris';

  @override
  String get priceTooHigh => 'Priset för högt';

  @override
  String get create => 'Skapa';

  @override
  String get alertCreated => 'Prisvarning skapad';

  @override
  String get wrongE5Price => 'Fel Super E5 pris';

  @override
  String get wrongE10Price => 'Fel Super E10 pris';

  @override
  String get wrongDieselPrice => 'Fel Diesel pris';

  @override
  String get wrongStatusOpen => 'Visas öppen, men stängd';

  @override
  String get wrongStatusClosed => 'Visas stängd, men öppen';

  @override
  String get searchAlongRouteLabel => 'Längs rutten';

  @override
  String get searchEvStations => 'Sök laddstationer';

  @override
  String get allStations => 'Alla stationer';

  @override
  String get bestStops => 'Bästa stopp';

  @override
  String get openInMaps => 'Öppna i Kartor';

  @override
  String get noStationsAlongRoute => 'Inga stationer hittades längs rutten';

  @override
  String get evOperational => 'I drift';

  @override
  String get evStatusUnknown => 'Status okänd';

  @override
  String evConnectors(int count) {
    return 'Kontakter ($count punkter)';
  }

  @override
  String get evNoConnectors => 'Inga kontaktdetaljer tillgängliga';

  @override
  String get evUsageCost => 'Användningskostnad';

  @override
  String get evPricingUnavailable =>
      'Prissättning inte tillgänglig från leverantören';

  @override
  String get evLastUpdated => 'Senast uppdaterad';

  @override
  String get evUnknown => 'Okänd';

  @override
  String get evDataAttribution => 'Data från OpenChargeMap (community-källa)';

  @override
  String get evStatusDisclaimer =>
      'Status kanske inte återspeglar tillgänglighet i realtid. Tryck på uppdatera för att hämta senaste data.';

  @override
  String get evNavigateToStation => 'Navigera till station';

  @override
  String get evRefreshStatus => 'Uppdatera status';

  @override
  String get evStatusUpdated => 'Status uppdaterad';

  @override
  String get evStationNotFound =>
      'Kunde inte uppdatera — station hittades inte i närheten';

  @override
  String get addedToFavorites => 'Tillagd i favoriter';

  @override
  String get removedFromFavorites => 'Borttagen från favoriter';

  @override
  String get addFavorite => 'Lägg till i favoriter';

  @override
  String get removeFavorite => 'Ta bort från favoriter';

  @override
  String get currentLocation => 'Aktuell plats';

  @override
  String get gpsError => 'GPS-fel';

  @override
  String get couldNotResolve => 'Kunde inte avgöra start eller destination';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get cityAddressOrGps => 'Stad, adress eller GPS';

  @override
  String get cityOrAddress => 'Stad eller adress';

  @override
  String get useGps => 'Använd GPS';

  @override
  String get stop => 'Stopp';

  @override
  String stopN(int n) {
    return 'Stopp $n';
  }

  @override
  String get addStop => 'Lägg till stopp';

  @override
  String get searchAlongRoute => 'Sök längs rutten';

  @override
  String get cheapest => 'Billigast';

  @override
  String nStations(int count) {
    return '$count stationer';
  }

  @override
  String nBest(int count) {
    return '$count bästa';
  }

  @override
  String get fuelPricesTankerkoenig => 'Bränslepriser (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Krävs för bränsleprissökning i Tyskland';

  @override
  String get evChargingOpenChargeMap => 'EV-laddning (OpenChargeMap)';

  @override
  String get customKey => 'Egen nyckel';

  @override
  String get appDefaultKey => 'App-standardnyckel';

  @override
  String get optionalOverrideKey =>
      'Valfritt: ersätt den inbyggda appnyckeln med din egen';

  @override
  String get requiredForEvSearch => 'Krävs för sökning efter EV-laddstationer';

  @override
  String get edit => 'Redigera';

  @override
  String get fuelPricesApiKey => 'Bränslepriser API-nyckel';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-nyckel';

  @override
  String get evChargingApiKey => 'EV-laddning API-nyckel';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-nyckel';

  @override
  String get routePlanningSection => 'Ruttplanering';

  @override
  String get routeMinSaving => 'Minsta besparing';

  @override
  String get routeMinSavingOff => 'Av';

  @override
  String get routeMinSavingOffCaption => 'Visar alla stationer längs rutten';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Endast stationer inom $amount från den billigaste på rutten';
  }

  @override
  String get routeDetourBudget => 'Maximal omväg';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Visa stationer upp till $km km från din direkta rutt';
  }

  @override
  String get routeSegment => 'Ruttsegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Visa billigaste station var $km:e km längs rutten';
  }

  @override
  String get avoidHighways => 'Undvik motorvägar';

  @override
  String get avoidHighwaysDesc =>
      'Ruttberäkning undviker avgiftsvägar och motorvägar';

  @override
  String get showFuelStations => 'Visa bensinstationer';

  @override
  String get showFuelStationsDesc =>
      'Inkludera bensin-, diesel-, LPG-, CNG-stationer';

  @override
  String get showEvStations => 'Visa laddstationer';

  @override
  String get showEvStationsDesc =>
      'Inkludera elektriska laddstationer i sökresultat';

  @override
  String get noStationsAlongThisRoute =>
      'Inga stationer hittades längs denna rutt.';

  @override
  String get fuelCostCalculator => 'Bränslekostnadskalkylator';

  @override
  String get distanceKm => 'Avstånd (km)';

  @override
  String get consumptionL100km => 'Förbrukning (L/100km)';

  @override
  String get fuelPriceEurL => 'Bränslepris (EUR/L)';

  @override
  String get tripCost => 'Resekostnad';

  @override
  String get fuelNeeded => 'Bränsle som behövs';

  @override
  String get totalCost => 'Total kostnad';

  @override
  String get enterCalcValues =>
      'Ange avstånd, förbrukning och pris för att beräkna resekostnaden';

  @override
  String get priceHistory => 'Prishistorik';

  @override
  String get ignoredStationsLabel => 'Ignorerade';

  @override
  String get ratingsLabel => 'Betyg';

  @override
  String get favoritesDataCache => 'Favoritdata';

  @override
  String get citySearchCache => 'Stadsökning';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Radering av data är inte tillgänglig i Community-läge. Koppla från först eller använd en privat databas.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count bevakade stationer';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count konfigurerade';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count dolda stationer';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count betygsatta stationer';
  }

  @override
  String get noPriceHistory => 'Ingen prishistorik ännu';

  @override
  String get noHourlyData => 'Inga timdata';

  @override
  String get noStatistics => 'Ingen statistik tillgänglig';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Medel';

  @override
  String get showAllFuelTypes => 'Visa alla bränsletyper';

  @override
  String get connected => 'Ansluten';

  @override
  String get notConnected => 'Inte ansluten';

  @override
  String get connectTankSync => 'Anslut TankSync';

  @override
  String get disconnectTankSync => 'Koppla från TankSync';

  @override
  String get viewMyData => 'Visa mina data';

  @override
  String get optionalCloudSync =>
      'Valfri molnsynkronisering för varningar, favoriter och push-notiser';

  @override
  String get tapToUpdateGps => 'Tryck för att uppdatera GPS-position';

  @override
  String get gpsAutoUpdateHint =>
      'GPS-positionen hämtas automatiskt vid sökning. Du kan också uppdatera den manuellt här.';

  @override
  String get clearGpsConfirm =>
      'Rensa den sparade GPS-positionen? Du kan uppdatera den igen när som helst.';

  @override
  String get pageNotFound => 'Sidan hittades inte';

  @override
  String get deleteAllServerData => 'Ta bort all serverdata';

  @override
  String get deleteServerDataConfirm => 'Ta bort all serverdata?';

  @override
  String get deleteEverything => 'Ta bort allt';

  @override
  String get allDataDeleted => 'All serverdata borttagen';

  @override
  String get forgetAllSyncedTripsButton => 'Glöm alla synkade resor';

  @override
  String get forgetAllSyncedTripsConfirmTitle => 'Glöm alla synkade resor?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Alla resesammanfattningar och detaljblobbar tas bort från servern. Din lokala resehistorik på den här enheten påverkas inte.\n\nDen här åtgärden kan inte ångras.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Glöm alla';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Alla synkade resor borttagna från servern';

  @override
  String get disconnectConfirm => 'Koppla från TankSync?';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get myServerData => 'Min serverdata';

  @override
  String get anonymousUuid => 'Anonym UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synkroniserad data';

  @override
  String get pushTokens => 'Push-tokens';

  @override
  String get priceReports => 'Prisrapporter';

  @override
  String get syncedTrips => 'Resor';

  @override
  String get totalItems => 'Totalt antal';

  @override
  String get estimatedSize => 'Uppskattad storlek';

  @override
  String get viewRawJson => 'Visa rådata som JSON';

  @override
  String get exportJson => 'Exportera som JSON (urklipp)';

  @override
  String get jsonCopied => 'JSON kopierad till urklipp';

  @override
  String get rawDataJson => 'Rådata (JSON)';

  @override
  String get close => 'Stäng';

  @override
  String get account => 'Konto';

  @override
  String get continueAsGuest => 'Fortsätt som gäst';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get signIn => 'Logga in';

  @override
  String get upgradeToEmail => 'Skapa e-postkonto';

  @override
  String get savedRoutes => 'Sparade rutter';

  @override
  String get noSavedRoutes => 'Inga sparade rutter';

  @override
  String get noSavedRoutesHint =>
      'Sök längs en rutt och spara den för snabb åtkomst senare.';

  @override
  String get saveRoute => 'Spara rutt';

  @override
  String get routeName => 'Ruttnamn';

  @override
  String itineraryDeleted(String name) {
    return '$name raderad';
  }

  @override
  String loadingRoute(String name) {
    return 'Laddar rutt: $name';
  }

  @override
  String get refreshFailed => 'Uppdatering misslyckades. Försök igen.';

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
  String get onboardingWelcomeHint => 'Konfigurera appen i några snabba steg.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrera dig för en gratis API-nyckel, eller hoppa över för att utforska appen med demodata.';

  @override
  String get onboardingComplete => 'Klart!';

  @override
  String get onboardingCompleteHint =>
      'Du kan ändra dessa inställningar när som helst i din profil.';

  @override
  String get onboardingBack => 'Tillbaka';

  @override
  String get onboardingNext => 'Nästa';

  @override
  String get onboardingSkip => 'Hoppa över';

  @override
  String get onboardingFinish => 'Kom igång';

  @override
  String crossBorderNearby(String country) {
    return '$country är i närheten';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km till gränsen';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Snittpris här: $price EUR ($count stationer)';
  }

  @override
  String get allPricesView => 'Alla priser';

  @override
  String get compactView => 'Kompakt';

  @override
  String get switchToAllPricesView => 'Byt till alla priser-vy';

  @override
  String get switchToCompactView => 'Byt till kompaktvy';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Slut i lager';

  @override
  String get gdprTitle => 'Din integritet';

  @override
  String get gdprSubtitle =>
      'Den här appen respekterar din integritet. Välj vilken data du vill dela. Du kan ändra dessa inställningar när som helst.';

  @override
  String get gdprLocationTitle => 'Platsåtkomst';

  @override
  String get gdprLocationDescription =>
      'Dina koordinater skickas till bränslepris-API:et för att hitta närliggande stationer. Platsdata lagras aldrig på en server och används inte för spårning.';

  @override
  String get gdprLocationShort =>
      'Hitta närliggande bränslestationer med din plats';

  @override
  String get gdprErrorReportingTitle => 'Felrapportering';

  @override
  String get gdprErrorReportingDescription =>
      'Anonyma kraschrapporter hjälper till att förbättra appen. Inga personuppgifter ingår. Rapporter skickas via Sentry endast när det är konfigurerat.';

  @override
  String get gdprErrorReportingShort =>
      'Skicka anonyma kraschrapporter för att förbättra appen';

  @override
  String get gdprCloudSyncTitle => 'Molnsynkronisering';

  @override
  String get gdprCloudSyncDescription =>
      'Synka favoriter och aviseringar mellan enheter via TankSync. Använder anonym autentisering. Din data är krypterad under överföring.';

  @override
  String get gdprCloudSyncShort =>
      'Synka favoriter och aviseringar mellan enheter';

  @override
  String get gdprLegalBasis =>
      'Rättslig grund: Art. 6(1)(a) GDPR (Samtycke). Du kan återkalla samtycket när som helst i Inställningar.';

  @override
  String get gdprAcceptAll => 'Acceptera alla';

  @override
  String get gdprAcceptSelected => 'Acceptera valda';

  @override
  String get gdprSettingsHint =>
      'Du kan ändra dina integritetsinställningar när som helst.';

  @override
  String get routeSaved => 'Rutt sparad!';

  @override
  String get routeSaveFailed => 'Det gick inte att spara rutten';

  @override
  String get sqlCopied => 'SQL kopierat till urklipp';

  @override
  String get connectionDataCopied => 'Anslutningsdata kopierad';

  @override
  String get accountDeleted => 'Konto raderat. Lokal data bevarad.';

  @override
  String get switchedToAnonymous => 'Bytte till anonym session';

  @override
  String failedToSwitch(String error) {
    return 'Byte misslyckades: $error';
  }

  @override
  String get topicUrlCopied => 'Ämnes-URL kopierad';

  @override
  String get testNotificationSent => 'Testavisering skickad!';

  @override
  String get testNotificationFailed => 'Det gick inte att skicka testavisering';

  @override
  String get pushUpdateFailed =>
      'Det gick inte att uppdatera push-aviseringsinställning';

  @override
  String get connectedAsGuest => 'Ansluten som gäst';

  @override
  String get accountCreated => 'Konto skapat!';

  @override
  String get signedIn => 'Inloggad!';

  @override
  String stationHidden(String name) {
    return '$name dold';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name borttagen från favoriter';
  }

  @override
  String invalidApiKey(String error) {
    return 'Ogiltig API-nyckel: $error';
  }

  @override
  String get invalidQrCode => 'Ogiltigt QR-kodsformat';

  @override
  String get invalidQrCodeTankSync =>
      'Ogiltig QR-kod – förväntat TankSync-format';

  @override
  String get tankSyncConnected => 'TankSync ansluten!';

  @override
  String get syncCompleted => 'Synkronisering klar – data uppdaterad';

  @override
  String get deviceCodeCopied => 'Enhetskod kopierad';

  @override
  String get undo => 'Ångra';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Ange ett giltigt $length-siffrigt $label';
  }

  @override
  String get freshnessAgo => 'sedan';

  @override
  String get freshnessStale => 'Inaktuell';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Datafräschhet: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand-logotyp';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ge $count stjärnor',
      one: 'Ge 1 stjärna',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Svagt';

  @override
  String get passwordStrengthFair => 'Godkänt';

  @override
  String get passwordStrengthStrong => 'Starkt';

  @override
  String get passwordReqMinLength => 'Minst 8 tecken';

  @override
  String get passwordReqUppercase => 'Minst 1 versal';

  @override
  String get passwordReqLowercase => 'Minst 1 gemen';

  @override
  String get passwordReqDigit => 'Minst 1 siffra';

  @override
  String get passwordReqSpecial => 'Minst 1 specialtecken';

  @override
  String get passwordTooWeak => 'Lösenordet uppfyller inte alla krav';

  @override
  String get brandFilterAll => 'Alla';

  @override
  String get brandFilterNoHighway => 'Ingen motorväg';

  @override
  String get swipeTutorialMessage =>
      'Svep höger för att navigera, svep vänster för att ta bort';

  @override
  String get swipeTutorialDismiss => 'Förstått';

  @override
  String get alertStatsActive => 'Aktiva';

  @override
  String get alertStatsToday => 'Idag';

  @override
  String get alertStatsThisWeek => 'Denna vecka';

  @override
  String get privacyDashboardTitle => 'Integritetspanel';

  @override
  String get privacyDashboardSubtitle =>
      'Visa, exportera eller radera din data';

  @override
  String get privacyDashboardBanner =>
      'Din data tillhör dig. Här kan du se allt som appen lagrar, exportera det eller radera det.';

  @override
  String get privacyLocalData => 'Data på den här enheten';

  @override
  String get privacyIgnoredStations => 'Ignorerade stationer';

  @override
  String get privacyRatings => 'Stationsbetyg';

  @override
  String get privacyPriceHistory => 'Prishistorik-stationer';

  @override
  String get privacyProfiles => 'Sökprofiler';

  @override
  String get privacyItineraries => 'Sparade rutter';

  @override
  String get privacyCacheEntries => 'Cacheposter';

  @override
  String get privacyApiKey => 'API-nyckel lagrad';

  @override
  String get privacyEvApiKey => 'EV API-nyckel lagrad';

  @override
  String get privacyEstimatedSize => 'Uppskattad lagring';

  @override
  String get privacySyncedData => 'Molnsynk (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Molnsynkronisering är inaktiverad. All data stannar på den här enheten.';

  @override
  String get privacySyncMode => 'Synkläge';

  @override
  String get privacySyncUserId => 'Användar-ID';

  @override
  String get privacySyncDescription =>
      'När synkronisering är aktiverad lagras favoriter, aviseringar, ignorerade stationer och betyg även på TankSync-servern.';

  @override
  String get privacyViewServerData => 'Visa serverdata';

  @override
  String get privacyExportButton => 'Exportera all data som JSON';

  @override
  String get privacyExportSuccess => 'Data exporterad till urklipp';

  @override
  String get privacyExportCsvButton => 'Exportera all data som CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV-data exporterad till urklipp';

  @override
  String get savedToDownloadsFolder => 'Sparad i mappen Hämtningar';

  @override
  String get privacyDeleteButton => 'Radera all data';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopiera fellogg till urklipp ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Spara felloggen ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Rensa felloggen';

  @override
  String get privacyErrorLogCleared => 'Felloggen rensad';

  @override
  String get privacyDeleteTitle => 'Radera all data?';

  @override
  String get privacyDeleteBody =>
      'Det här raderar permanent:\n\n- Alla favoriter och stationsdata\n- Alla sökprofiler\n- Alla prisaviseringar\n- All prishistorik\n- All cachad data\n- Din API-nyckel\n- Alla appinställningar\n\nAppen återställs till ursprungligt läge. Den här åtgärden kan inte ångras.';

  @override
  String get privacyDeleteConfirm => 'Radera allt';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nej';

  @override
  String get amenities => 'Amenities';

  @override
  String get amenityShop => 'Shop';

  @override
  String get amenityCarWash => 'Car Wash';

  @override
  String get amenityAirPump => 'Air';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Food';

  @override
  String get amenityAtm => 'ATM';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'EV';

  @override
  String get paymentMethods => 'Betalningsmetoder';

  @override
  String get paymentMethodCash => 'Kontant';

  @override
  String get paymentMethodCard => 'Kort';

  @override
  String get paymentMethodContactless => 'Kontaktlös';

  @override
  String get paymentMethodFuelCard => 'Bränslekort';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Betala med $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Jämfört med det rullande snittet för dina senaste 3 tankningar ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Förbrukning $value L/100 km, $delta jämfört med ditt rullande snitt';
  }

  @override
  String get drivingMode => 'Körläge';

  @override
  String get drivingExit => 'Avsluta';

  @override
  String get drivingNearestStation => 'Närmast';

  @override
  String get drivingTapToUnlock => 'Tryck för att låsa upp';

  @override
  String get drivingSafetyTitle => 'Säkerhetsmeddelande';

  @override
  String get drivingSafetyMessage =>
      'Använd inte appen under körning. Kör av vägen till en säker plats innan du interagerar med skärmen. Föraren ansvarar alltid för säker körning.';

  @override
  String get drivingSafetyAccept => 'Jag förstår';

  @override
  String get voiceAnnouncementsTitle => 'Röstmeddelanden';

  @override
  String get voiceAnnouncementsDescription =>
      'Meddela om billiga stationer i närheten under körning';

  @override
  String get voiceAnnouncementsEnabled => 'Aktivera röstmeddelanden';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Endast under $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometer framåt, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Aviseringsradie';

  @override
  String get voiceAnnouncementCooldown => 'Upprepningsintervall';

  @override
  String get nearestStations => 'Narmaste stationer';

  @override
  String get nearestStationsHint =>
      'Hitta de narmaste stationerna med din nuvarande position';

  @override
  String get consumptionLogTitle => 'Bränsleförbrukning';

  @override
  String get consumptionLogMenuTitle => 'Förbrukningslogg';

  @override
  String get consumptionLogMenuSubtitle =>
      'Logga tankningar och beräkna L/100km';

  @override
  String get consumptionStatsTitle => 'Förbrukningsstatistik';

  @override
  String get addFillUp => 'Lägg till tankning';

  @override
  String get noFillUpsTitle => 'Inga tankningar ännu';

  @override
  String get noFillUpsSubtitle =>
      'Logga din första tankning för att börja spåra förbrukning.';

  @override
  String get fillUpDate => 'Datum';

  @override
  String get liters => 'Liter';

  @override
  String get odometerKm => 'Vägmätare (km)';

  @override
  String get notesOptional => 'Anteckningar (valfritt)';

  @override
  String get stationPreFilled => 'Station förifylld';

  @override
  String get statAvgConsumption => 'Sn. L/100km';

  @override
  String get statAvgCostPerKm => 'Sn. kostnad/km';

  @override
  String get statTotalLiters => 'Totalt liter';

  @override
  String get statTotalSpent => 'Totalt spenderat';

  @override
  String get statFillUpCount => 'Tankningar';

  @override
  String get fieldRequired => 'Obligatorisk';

  @override
  String get fieldInvalidNumber => 'Ogiltigt tal';

  @override
  String get carbonDashboardTitle => 'Koldioxidpanel';

  @override
  String get carbonEmptyTitle => 'Ingen data ännu';

  @override
  String get carbonEmptySubtitle =>
      'Logga tankningar för att se din koldioxidpanel.';

  @override
  String get carbonSummaryTotalCost => 'Total kostnad';

  @override
  String get carbonSummaryTotalCo2 => 'Total CO2';

  @override
  String get monthlyCostsTitle => 'Månadskostnader';

  @override
  String get monthlyEmissionsTitle => 'Månatliga CO2-utsläpp';

  @override
  String get vehiclesTitle => 'Mina fordon';

  @override
  String get vehiclesMenuTitle => 'Mina fordon';

  @override
  String get vehiclesMenuSubtitle =>
      'Batteri, kontakter, laddningsinställningar';

  @override
  String get vehiclesEmptyMessage =>
      'Lägg till din bil för att filtrera efter kontakttyp och uppskatta laddningskostnader.';

  @override
  String get vehiclesWizardTitle => 'Mina fordon (valfritt)';

  @override
  String get vehiclesWizardSubtitle =>
      'Lägg till din bil för att förifylla förbrukningsloggen och aktivera EV-kontaktfilter. Du kan hoppa över detta och lägga till fordon senare.';

  @override
  String get vehiclesWizardNoneYet => 'Inget fordon konfigurerat ännu.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fordon',
      one: '1 fordon',
    );
    return 'Du har $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Hoppa över för att slutföra konfiguration – du kan lägga till fordon när som helst från Inställningar.';

  @override
  String get fillUpVehicleLabel => 'Fordon';

  @override
  String get fillUpVehicleNone => 'Inget fordon';

  @override
  String get fillUpVehicleRequired => 'Fordon krävs';

  @override
  String get reportScanError => 'Rapportera skanningsfel';

  @override
  String get pickStationTitle => 'Välj en station';

  @override
  String get pickStationHelper =>
      'Starta tankningen från en känd station så fylls priser, märke och bränsletyp i automatiskt.';

  @override
  String get pickStationEmpty =>
      'Inga favoritstationer ännu – lägg till några från Sök eller Favoriter, eller hoppa över och fyll i manuellt.';

  @override
  String get pickStationSkip => 'Hoppa över – lägg till utan station';

  @override
  String get scanPump => 'Skanna pump';

  @override
  String get scanPayment => 'Skanna betalnings-QR';

  @override
  String get qrPaymentBeneficiary => 'Mottagare';

  @override
  String get qrPaymentAmount => 'Belopp';

  @override
  String get qrPaymentEpcTitle => 'SEPA-betalning';

  @override
  String get qrPaymentEpcEmpty => 'Inga fält avkodade';

  @override
  String get qrPaymentOpenInBank => 'Öppna i bankapp';

  @override
  String get qrPaymentLaunchFailed =>
      'Ingen app tillgänglig för att öppna den här koden';

  @override
  String get qrPaymentUnknownTitle => 'Okänd kod';

  @override
  String get qrPaymentCopyRaw => 'Kopiera råtext';

  @override
  String get qrPaymentCopiedRaw => 'Kopierat till urklipp';

  @override
  String get qrPaymentReport => 'Rapportera denna skanning';

  @override
  String get qrPaymentEpcCopied =>
      'Bankuppgifter kopierade – klistra in i din bankapp';

  @override
  String get qrScannerGuidance => 'Rikta kameran mot en QR-kod';

  @override
  String get qrScannerPermissionDenied =>
      'Kameraåtkomst krävs för att skanna QR-koder.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kameraåtkomst nekades. Öppna inställningar för att bevilja den.';

  @override
  String get qrScannerRetryPermission => 'Försök igen';

  @override
  String get qrScannerOpenSettings => 'Öppna inställningar';

  @override
  String get qrScannerTimeout =>
      'Ingen QR-kod hittades. Flytta närmare eller försök igen.';

  @override
  String get qrScannerRetry => 'Försök igen';

  @override
  String get torchOn => 'Slå på blixt';

  @override
  String get torchOff => 'Slå av blixt';

  @override
  String get obdNoAdapter => 'Ingen OBD2-adapter i närheten';

  @override
  String get obdOdometerUnavailable => 'Kunde inte läsa vägmätaren';

  @override
  String get obdPermissionDenied =>
      'Bevilja Bluetooth-behörighet i systeminställningarna';

  @override
  String get obdAdapterUnresponsive =>
      'Adaptern svarade inte – slå på tändningen och försök igen';

  @override
  String get obdPickerTitle => 'Välj en OBD2-adapter';

  @override
  String get obdPickerScanning => 'Söker efter adaptrar…';

  @override
  String get obdPickerConnecting => 'Ansluter…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Ljust';

  @override
  String get themeModeDark => 'Mörkt';

  @override
  String get themeModeSystem => 'Följ system';

  @override
  String get tripRecordingTitle => 'Spelar in resa';

  @override
  String get tripSummaryTitle => 'Resesammanfattning';

  @override
  String get tripMetricDistance => 'Sträcka';

  @override
  String get tripMetricSpeed => 'Hastighet';

  @override
  String get tripMetricFuelUsed => 'Bränsle använt';

  @override
  String get tripMetricAvgConsumption => 'Snitt';

  @override
  String get tripMetricElapsed => 'Förfluten tid';

  @override
  String get tripMetricOdometer => 'Vägmätare';

  @override
  String get tripStop => 'Stoppa inspelning';

  @override
  String get tripPause => 'Pausa';

  @override
  String get tripResume => 'Återuppta';

  @override
  String get tripBannerRecording => 'Spelar in resa';

  @override
  String get tripBannerPaused => 'Resa pausad – tryck för att återuppta';

  @override
  String get navConsumption => 'Förbrukning';

  @override
  String get vehicleBaselineSectionTitle => 'Grundkalibrering';

  @override
  String get vehicleBaselineEmpty =>
      'Inga prover ännu – starta en OBD2-resa för att börja lära känna fordonets bränsleprofil.';

  @override
  String get vehicleBaselineProgress =>
      'Lärt från prover över olika körsituationer.';

  @override
  String get vehicleBaselineReset => 'Återställ körsituationsgräns';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Återställ körsituationsgräns?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Det här raderar alla inlärda prover för detta fordon. Du faller tillbaka till kallstartsstandarderna tills nya resor fyller profilen igen.';

  @override
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Ingen adapter ihopparad. Para ihop en så att appen kan återansluta automatiskt nästa gång.';

  @override
  String get vehicleAdapterUnnamed => 'Okänd adapter';

  @override
  String get vehicleAdapterPair => 'Para ihop adapter';

  @override
  String get vehicleAdapterForget => 'Glöm adapter';

  @override
  String get achievementsTitle => 'Prestationer';

  @override
  String get achievementFirstTrip => 'Första resan';

  @override
  String get achievementFirstTripDesc => 'Spela in din första OBD2-resa.';

  @override
  String get achievementFirstFillUp => 'Första tankningen';

  @override
  String get achievementFirstFillUpDesc => 'Logga din första tankning.';

  @override
  String get achievementTenTrips => '10 resor';

  @override
  String get achievementTenTripsDesc => 'Spela in 10 OBD2-resor.';

  @override
  String get achievementZeroHarsh => 'Mjuk förare';

  @override
  String get achievementZeroHarshDesc =>
      'Genomför en resa på 10 km eller mer utan hård inbromsning eller acceleration.';

  @override
  String get achievementEcoWeek => 'Ekovecka';

  @override
  String get achievementEcoWeekDesc =>
      'Kör 7 dagar i rad med minst en mjuk resa varje dag.';

  @override
  String get achievementPriceWin => 'Prisvinst';

  @override
  String get achievementPriceWinDesc =>
      'Logga en tankning som slår stationens 30-dagarssnitt med 5 % eller mer.';

  @override
  String get syncBaselinesToggleTitle => 'Dela inlärda fordonsprofiler';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Ladda upp förbrukningsgränser per fordon så att en andra enhet kan återanvända dem.';

  @override
  String get obd2StatusConnected => 'OBD2-adapter: ansluten';

  @override
  String get obd2StatusAttempting => 'OBD2-adapter: ansluter';

  @override
  String get obd2StatusUnreachable => 'OBD2-adapter: onåbar';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-behörighet krävs';

  @override
  String get obd2StatusConnectedBody => 'Redo att spela in en resa.';

  @override
  String get obd2StatusAttemptingBody => 'Ansluter i bakgrunden…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter utom räckhåll eller används redan av en annan app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Bevilja Bluetooth-behörighet i systeminställningarna för att återansluta automatiskt.';

  @override
  String get obd2StatusNoAdapter => 'Ingen adapter ihopparad';

  @override
  String get obd2StatusForget => 'Glöm adapter';

  @override
  String get tripHistoryTitle => 'Resehistorik';

  @override
  String get tripHistoryEmptyTitle => 'Inga resor ännu';

  @override
  String get tripHistoryEmptySubtitle =>
      'Anslut en OBD2-adapter och spela in en resa för att börja bygga din körhistorik.';

  @override
  String get tripHistoryUnknownDate => 'Okänt datum';

  @override
  String get situationIdle => 'Tomgång';

  @override
  String get situationStopAndGo => 'Stopp och kör';

  @override
  String get situationUrban => 'Stadstrafik';

  @override
  String get situationHighway => 'Motorväg';

  @override
  String get situationDecel => 'Retarderar';

  @override
  String get situationClimbing => 'Backkörning / lastad';

  @override
  String get situationHardAccel => 'Hård acceleration';

  @override
  String get situationFuelCut => 'Bränslebrytare – frifart';

  @override
  String get tripSaveAsFillUp => 'Spara som tankning';

  @override
  String get tripSaveRecording => 'Spara resa';

  @override
  String get tripDiscard => 'Kasta';

  @override
  String obdOdometerRead(int km) {
    return 'Vägmätare avläst: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Ej inställt';

  @override
  String get wizardVehicleTapToEdit => 'Tryck för att redigera';

  @override
  String get wizardVehicleDefaultBadge => 'Standard';

  @override
  String get wizardProfileChoiceHint =>
      'Välj hur du vill använda appen. Du kan ändra detta senare i Inställningar.';

  @override
  String get wizardProfileChoiceFooter =>
      'Du kan ändra ditt val när som helst från Inställningar → Användningsläge.';

  @override
  String get wizardProfileBasicName => 'Grundläggande';

  @override
  String get wizardProfileBasicDescription =>
      'Billigaste bränsle och EV-laddningspriser i närheten. Favoriter och prisaviseringar.';

  @override
  String get wizardProfileMediumName => 'Mellannivå';

  @override
  String get wizardProfileMediumDescription =>
      'Allt i Grundläggande, plus spåra dina tankningar och EV-laddningar manuellt.';

  @override
  String get wizardProfileFullName => 'Full';

  @override
  String get wizardProfileFullDescription =>
      'Allt i Mellannivå, plus automatisk OBD2-reseinspelning, körpoäng och lojalitetskort.';

  @override
  String get wizardProfileCustomName => 'Anpassad';

  @override
  String get wizardProfileCustomDescription =>
      'Din egen kombination av funktioner. Justera varje reglage nedan.';

  @override
  String get useModeSectionHint =>
      'Anpassa appen efter hur du faktiskt använder den. Att välja en förinställning aktiverar den matchande uppsättningen funktioner.';

  @override
  String get useModeCustomSettingsDescription =>
      'Din funktionsmix matchar ingen förinställning. Välj en ovan för att skriva över, eller fortsätt anpassa enskilda funktioner i avsnittet nedan.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Användningsläge inställt på $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Standardfordon (valfritt)';

  @override
  String get profileDefaultVehicleNone => 'Inget standard';

  @override
  String get profileFuelFromVehicleHint =>
      'Bränsletyp hämtas från ditt standardfordon. Rensa fordonet för att välja bränsle direkt.';

  @override
  String get consumptionNoVehicleTitle => 'Lägg till ett fordon först';

  @override
  String get consumptionNoVehicleBody =>
      'Tankningar kopplas till ett fordon. Lägg till din bil för att börja logga förbrukning.';

  @override
  String get vehicleAdd => 'Lägg till fordon';

  @override
  String get vehicleAddTitle => 'Lägg till fordon';

  @override
  String get vehicleEditTitle => 'Redigera fordon';

  @override
  String get vehicleDeleteTitle => 'Radera fordon?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Ta bort \"$name\" från dina profiler?';
  }

  @override
  String get vehicleNameLabel => 'Namn';

  @override
  String get vehicleNameHint => 't.ex. Min Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Förbränning';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Elektrisk';

  @override
  String get vehicleEvSectionTitle => 'Elektrisk';

  @override
  String get vehicleCombustionSectionTitle => 'Förbränning';

  @override
  String get vehicleBatteryLabel => 'Batterikapacitet (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max laddeffekt (kW)';

  @override
  String get vehicleConnectorsLabel => 'Stödda kontakter';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max SoC %';

  @override
  String get vehicleTankLabel => 'Tankvolym (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Favoritbränsle';

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
  String get connectorThreePin => '3-stift';

  @override
  String get evShowOnMap => 'Visa EV-stationer';

  @override
  String get evAvailableOnly => 'Endast tillgängliga';

  @override
  String get evMinPower => 'Min effekt';

  @override
  String get evMaxPower => 'Max effekt';

  @override
  String get evOperator => 'Operatör';

  @override
  String get evLastUpdate => 'Senast uppdaterad';

  @override
  String get evStatusAvailable => 'Tillgänglig';

  @override
  String get evStatusOccupied => 'Upptagen';

  @override
  String get evStatusOutOfOrder => 'Ur funktion';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Endast öppna';

  @override
  String get saveAsDefaults => 'Spara som mina standardinställningar';

  @override
  String get criteriaSavedToProfile => 'Sparat som standardinställningar';

  @override
  String get profileNotFound => 'Ingen aktiv profil';

  @override
  String get updatingFavorites => 'Uppdaterar dina favoriter...';

  @override
  String get fetchingLatestPrices => 'Hämtar de senaste priserna';

  @override
  String get noDataAvailable => 'Ingen data';

  @override
  String get configAndPrivacy => 'Konfiguration och integritet';

  @override
  String get searchToSeeMap => 'Sök för att se stationer på kartan';

  @override
  String get evPowerAny => 'Valfri';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Plats';

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
  String get tooltipBack => 'Tillbaka';

  @override
  String get tooltipClose => 'Stäng';

  @override
  String get tooltipShare => 'Dela';

  @override
  String get tooltipClearSearch => 'Rensa sökinmatning';

  @override
  String get minimalDriveInstantConsumption => 'Momentanförbrukning';

  @override
  String get coachingShiftUp => 'Växla upp';

  @override
  String get coachingShiftDown => 'Växla ned';

  @override
  String get coachingEasePedal => 'Släpp gasen';

  @override
  String get tooltipUseGps => 'Använd GPS-plats';

  @override
  String get tooltipShowPassword => 'Visa lösenord';

  @override
  String get tooltipHidePassword => 'Dölj lösenord';

  @override
  String get evConnectorsLabel => 'Tillgängliga kontakter';

  @override
  String get evConnectorsNone => 'Ingen kontaktinformation';

  @override
  String get switchToEmail => 'Byt till e-post';

  @override
  String get switchToEmailSubtitle =>
      'Behåll data, lägg till inloggning från andra enheter';

  @override
  String get switchToAnonymousAction => 'Byt till anonym';

  @override
  String get switchToAnonymousSubtitle =>
      'Behåll lokal data, använd ny anonym session';

  @override
  String get linkDevice => 'Länka enhet';

  @override
  String get shareDatabase => 'Dela databas';

  @override
  String get disconnectAction => 'Koppla från';

  @override
  String get disconnectSubtitle => 'Stoppa synkronisering (lokal data bevaras)';

  @override
  String get deleteAccountAction => 'Radera konto';

  @override
  String get deleteAccountSubtitle => 'Ta bort all serverdata permanent';

  @override
  String get localOnly => 'Endast lokalt';

  @override
  String get localOnlySubtitle =>
      'Valfritt: synka favoriter, aviseringar och betyg mellan enheter';

  @override
  String get setupCloudSync => 'Konfigurera molnsynkronisering';

  @override
  String get disconnectTitle => 'Koppla från TankSync?';

  @override
  String get disconnectBody =>
      'Molnsynkronisering inaktiveras. Din lokala data (favoriter, aviseringar, historik) bevaras på den här enheten. Serverdata raderas inte.';

  @override
  String get deleteAccountTitle => 'Radera konto?';

  @override
  String get deleteAccountBody =>
      'Det här raderar permanent all din data från servern (favoriter, aviseringar, betyg, rutter). Lokal data på den här enheten bevaras.\n\nDet här kan inte ångras.';

  @override
  String get switchToAnonymousTitle => 'Byt till anonym?';

  @override
  String get switchToAnonymousBody =>
      'Du loggas ut från ditt e-postkonto och fortsätter med en ny anonym session.\n\nDin lokala data (favoriter, aviseringar) bevaras på den här enheten och synkas till det nya anonyma kontot.';

  @override
  String get switchAction => 'Byt';

  @override
  String get helpBannerCriteria =>
      'Dina profilstandarder är förifyllda. Justera kriterierna nedan för att förfina din sökning.';

  @override
  String get helpBannerAlerts =>
      'Ange ett prisgränsvärde för en station. Du aviseras när priserna sjunker under det. Kontroller sker var 30:e minut.';

  @override
  String get helpBannerConsumption =>
      'Logga varje tankning för att spåra din verkliga förbrukning och CO₂-avtryck. Svep vänster för att ta bort en post.';

  @override
  String get helpBannerVehicles =>
      'Lägg till dina fordon så att tankningar och bränslepreferenser fylls i korrekt. Det första fordonet blir ditt standardfordon.';

  @override
  String get syncNow => 'Synka nu';

  @override
  String get onboardingPreferencesTitle => 'Dina inställningar';

  @override
  String get onboardingZipHelper => 'Används när GPS inte är tillgänglig';

  @override
  String get onboardingRadiusHelper => 'Större radie = fler resultat';

  @override
  String get onboardingPrivacy =>
      'Dessa inställningar lagras bara på din enhet och delas aldrig.';

  @override
  String get onboardingLandingTitle => 'Startskärm';

  @override
  String get onboardingLandingHint =>
      'Välj vilken skärm som öppnas när du startar appen.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Håll dig utanför appen – men stäng den inte.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Öppna Sparkilo en gång efter varje omstart.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple väcker Sparkilo bara efter att du har öppnat den minst en gång sedan telefonen startades om. Sedan spelas dina resor in automatiskt.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Svep inte bort Sparkilo i appväxlaren.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Tvångsstäng\" säger åt iOS att sluta starta om appen. Dina resor slutar spelas in tills du öppnar Sparkilo igen.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'När iOS frågar om \"Alltid\" plats, säg ja.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Reservfunktionen som spelar in din resa när OBD2-adaptern är långsam behöver bakgrundsplats. Vi delar den aldrig.';

  @override
  String get scanReceipt => 'Skanna kvitto';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Bränsle';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Motorväg';

  @override
  String get ratingModeLocal => 'Lokal';

  @override
  String get ratingModePrivate => 'Privat';

  @override
  String get ratingModeShared => 'Delad';

  @override
  String get ratingDescLocal => 'Betyg sparas endast på den här enheten';

  @override
  String get ratingDescPrivate =>
      'Synkas med din databas (inte synlig för andra)';

  @override
  String get ratingDescShared => 'Synlig för alla användare av din databas';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API-nyckel är inte konfigurerad. Lägg till en i Inställningar för att söka EV-laddningsstationer.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Dataleverantören ($host) tillhandahåller ett utgånget eller ogiltigt TLS-certifikat. Appen kan inte ladda data från den här källan förrän leverantören åtgärdar det. Kontakta $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed otillgänglig. Använder $current.';
  }

  @override
  String get errorTitleApiKey => 'API-nyckel krävs';

  @override
  String get errorTitleLocation => 'Plats otillgänglig';

  @override
  String get errorHintNoStations =>
      'Prova att öka sökradien eller sök på en annan plats.';

  @override
  String get errorHintApiKey => 'Konfigurera din API-nyckel i Inställningar.';

  @override
  String get errorHintConnection =>
      'Kontrollera din internetanslutning och försök igen.';

  @override
  String get errorHintRouting =>
      'Ruttberäkning misslyckades. Kontrollera din internetanslutning och försök igen.';

  @override
  String get errorHintFallback =>
      'Försök igen eller sök med postnummer eller ortnamn.';

  @override
  String get alertsLoadErrorTitle => 'Det gick inte att ladda dina aviseringar';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Bakgrundskontroll av aviseringar misslyckades';

  @override
  String get detailsLabel => 'Detaljer';

  @override
  String get remove => 'Ta bort';

  @override
  String get showKey => 'Visa nyckel';

  @override
  String get hideKey => 'Dölj nyckel';

  @override
  String get syncOptionalTitle => 'TankSync är valfritt';

  @override
  String get syncOptionalDescription =>
      'Din app fungerar fullt ut utan molnsynkronisering. TankSync låter dig synka favoriter, aviseringar och betyg mellan enheter med Supabase (kostnadsfri nivå tillgänglig).';

  @override
  String get syncHowToConnectQuestion => 'Hur vill du ansluta?';

  @override
  String get syncCreateOwnTitle => 'Skapa min egen databas';

  @override
  String get syncCreateOwnSubtitle =>
      'Kostnadsfritt Supabase-projekt – vi guidar dig steg för steg';

  @override
  String get syncJoinExistingTitle => 'Gå med i en befintlig databas';

  @override
  String get syncJoinExistingSubtitle =>
      'Skanna QR-kod från databasägaren eller klistra in uppgifter';

  @override
  String get syncChooseAccountType => 'Välj din kontotyp';

  @override
  String get syncAccountTypeAnonymous => 'Anonym';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Direkt, ingen e-post krävs. Data kopplad till den här enheten.';

  @override
  String get syncAccountTypeEmail => 'E-postkonto';

  @override
  String get syncAccountTypeEmailDesc =>
      'Logga in från vilken enhet som helst. Återfå data om telefonen förloras.';

  @override
  String get syncHaveAccountSignIn => 'Har du redan ett konto? Logga in';

  @override
  String get syncCreateNewAccount => 'Skapa nytt konto';

  @override
  String get syncTestConnection => 'Testa anslutning';

  @override
  String get syncTestingConnection => 'Testar...';

  @override
  String get syncConnectButton => 'Anslut';

  @override
  String get syncConnectingButton => 'Ansluter...';

  @override
  String get syncDatabaseReady => 'Databasen är redo!';

  @override
  String get syncDatabaseNeedsSetup => 'Databasen behöver konfigureras';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Saknas';

  @override
  String get syncSqlEditorInstructions =>
      'Kopiera SQL:en nedan och kör den i din Supabase SQL-editor (Instrumentpanel → SQL-editor → Ny fråga → Klistra in → Kör)';

  @override
  String get syncCopySqlButton => 'Kopiera SQL till urklipp';

  @override
  String get syncRecheckSchemaButton => 'Kontrollera schema igen';

  @override
  String get syncDoneButton => 'Klar';

  @override
  String syncSignedInAs(String email) {
    return 'Inloggad som $email';
  }

  @override
  String get syncEmailDescription =>
      'Din data synkas på alla enheter med den här e-postadressen.';

  @override
  String get syncSwitchToAnonymousTitle => 'Byt till anonym';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Fortsätt utan e-post, ny anonym session';

  @override
  String get syncGuestDescription => 'Anonym, ingen e-post krävs.';

  @override
  String get syncOrDivider => 'eller';

  @override
  String get syncHowToSyncQuestion => 'Hur vill du synka?';

  @override
  String get syncOfflineDescription =>
      'Din app fungerar fullt ut offline. Molnsynkronisering är valfritt.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Dela favoriter och betyg med alla användare';

  @override
  String get syncModePrivateTitle => 'Privat databas';

  @override
  String get syncModePrivateSubtitle => 'Din egen Supabase – full datakontroll';

  @override
  String get syncModeGroupTitle => 'Gå med i en grupp';

  @override
  String get syncModeGroupSubtitle => 'Delad databas för familj eller vänner';

  @override
  String get syncPrivacyShared => 'Delad';

  @override
  String get syncPrivacyPrivate => 'Privat';

  @override
  String get syncPrivacyGroup => 'Grupp';

  @override
  String get syncStayOfflineButton => 'Fortsätt offline';

  @override
  String get syncSuccessTitle => 'Anslutningen lyckades!';

  @override
  String get syncSuccessDescription => 'Din data synkas nu automatiskt.';

  @override
  String get syncWizardTitleConnect => 'Anslut TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Din databas';

  @override
  String get syncSetupTitleJoinGroup => 'Gå med i en grupp';

  @override
  String get syncSetupTitleAccount => 'Ditt konto';

  @override
  String get syncWizardBack => 'Tillbaka';

  @override
  String get syncWizardNext => 'Nästa';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Steg $current av $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Skapa ett Supabase-projekt';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tryck på \"Öppna Supabase\" nedan\n2. Skapa ett kostnadsfritt konto (om du inte har ett)\n3. Klicka på \"Nytt projekt\"\n4. Välj ett namn och en region\n5. Vänta ~2 minuter på att det startar';

  @override
  String get syncWizardOpenSupabase => 'Öppna Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Aktivera anonyma inloggningar';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. I din Supabase-instrumentpanel:\n   Autentisering → Leverantörer\n2. Hitta \"Anonyma inloggningar\"\n3. Växla till PÅ\n4. Klicka på \"Spara\"';

  @override
  String get syncWizardOpenAuthSettings => 'Öppna autentiseringsinställningar';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopiera dina uppgifter';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Gå till Inställningar → API i din instrumentpanel\n2. Kopiera \"Projekt-URL\"\n3. Kopiera \"anon public\"-nyckeln\n4. Klistra in dem nedan';

  @override
  String get syncWizardOpenApiSettings => 'Öppna API-inställningar';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Gå med i en befintlig databas';

  @override
  String get syncWizardScanQrCode => 'Skanna QR-kod';

  @override
  String get syncWizardAskOwnerQr =>
      'Be databasägaren att visa sin QR-kod\n(Inställningar → TankSync → Dela)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Be databasägaren att visa sin QR-kod';

  @override
  String get syncWizardEnterManuallyTitle => 'Ange manuellt';

  @override
  String get syncWizardOrEnterManually => 'eller ange manuellt';

  @override
  String get syncWizardUrlHelperText =>
      'Blanksteg och radbrytningar tas bort automatiskt';

  @override
  String get syncCredentialsPrivateHint =>
      'Ange dina Supabase-projektuppgifter. Du hittar dem i din instrumentpanel under Inställningar > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Databas-URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Åtkomstnyckel';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-post';

  @override
  String get authPasswordLabel => 'Lösenord';

  @override
  String get authConfirmPasswordLabel => 'Bekräfta lösenord';

  @override
  String get authPleaseEnterEmail => 'Ange din e-postadress';

  @override
  String get authInvalidEmail => 'Ogiltig e-postadress';

  @override
  String get authPasswordsDoNotMatch => 'Lösenorden stämmer inte överens';

  @override
  String get authConnectAnonymously => 'Anslut anonymt';

  @override
  String get authCreateAccountAndConnect => 'Skapa konto och anslut';

  @override
  String get authSignInAndConnect => 'Logga in och anslut';

  @override
  String get authAnonymousSegment => 'Anonym';

  @override
  String get authEmailSegment => 'E-post';

  @override
  String get authAnonymousDescription =>
      'Direkt åtkomst, ingen e-post krävs. Data kopplad till den här enheten.';

  @override
  String get authEmailDescription =>
      'Logga in från vilken enhet som helst. Återfå din data om telefonen förloras.';

  @override
  String get authSyncAcrossDevices =>
      'Synka data automatiskt på alla dina enheter.';

  @override
  String get authNewHereCreateAccount => 'Ny här? Skapa konto';

  @override
  String get linkDeviceScreenTitle => 'Länka enhet';

  @override
  String get linkDeviceThisDeviceLabel => 'Den här enheten';

  @override
  String get linkDeviceShareCodeHint =>
      'Dela den här koden med din andra enhet:';

  @override
  String get linkDeviceNotConnected => 'Ej ansluten';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopiera kod';

  @override
  String get linkDeviceImportSectionTitle => 'Importera från en annan enhet';

  @override
  String get linkDeviceImportDescription =>
      'Ange enhetskoden från din andra enhet för att importera favoriter, aviseringar, fordon och förbrukningslogg. Varje enhet behåller sin egen profil och standardinställningar.';

  @override
  String get linkDeviceCodeFieldLabel => 'Enhetskod';

  @override
  String get linkDeviceCodeFieldHint => 'Klistra in UUID från annan enhet';

  @override
  String get linkDeviceImportButton => 'Importera data';

  @override
  String get linkDeviceHowItWorksTitle => 'Hur det fungerar';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. På Enhet A: kopiera enhetskoden ovan\n2. På Enhet B: klistra in den i fältet \"Enhetskod\"\n3. Tryck på \"Importera data\" för att slå samman favoriter, aviseringar, fordon och förbrukningsloggar\n4. Båda enheterna får all kombinerad data\n\nVarje enhet behåller sin egen anonyma identitet och sin egen profil (favoritbränsle, standardfordon, startskärm). Data slås samman, inte flyttas.';

  @override
  String get vehicleSetActive => 'Ange som aktiv';

  @override
  String get swipeHide => 'Dölj';

  @override
  String get evChargingSection => 'EV-laddning';

  @override
  String get fuelStationsSection => 'Bränslestationer';

  @override
  String get yourRating => 'Ditt betyg';

  @override
  String get noStorageUsed => 'Inget lagringsutrymme används';

  @override
  String get aboutReportBug => 'Rapportera ett fel / Föreslå en funktion';

  @override
  String get aboutSupportProject => 'Stöd det här projektet';

  @override
  String get aboutSupportDescription =>
      'Den här appen är gratis, öppen källkod och har inga annonser. Om du tycker den är användbar kan du överväga att stödja utvecklaren.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxemburgs bränslepriser är statligt reglerade och enhetliga i hela landet.';

  @override
  String get luxembourgFuelUnleaded95 => 'Blyfri 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Blyfri 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxemburgs reglerade priser är inte tillgängliga.';

  @override
  String get reportIssueTitle => 'Rapportera ett problem';

  @override
  String get enterCorrection => 'Ange korrigeringen';

  @override
  String get reportNoBackendAvailable =>
      'Rapporten kunde inte skickas: ingen rapporteringstjänst är konfigurerad för det här landet. Aktivera TankSync i Inställningar för att skicka community-rapporter.';

  @override
  String get correctName => 'Korrekt stationsnamn';

  @override
  String get correctAddress => 'Korrekt adress';

  @override
  String get wrongE85Price => 'Fel E85-pris';

  @override
  String get wrongE98Price => 'Fel Super 98-pris';

  @override
  String get wrongLpgPrice => 'Fel LPG-pris';

  @override
  String get wrongStationName => 'Fel stationsnamn';

  @override
  String get wrongStationAddress => 'Fel adress';

  @override
  String get independentStation => 'Oberoende station';

  @override
  String get serviceRemindersSection => 'Servicepåminnelser';

  @override
  String get serviceRemindersEmpty =>
      'Inga påminnelser ännu – välj en förinställning ovan.';

  @override
  String get addServiceReminder => 'Lägg till påminnelse';

  @override
  String get serviceReminderPresetOil => 'Olja (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Oljebyte';

  @override
  String get serviceReminderPresetTires => 'Däck (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Däck';

  @override
  String get serviceReminderPresetInspection => 'Besiktning (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Besiktning';

  @override
  String get serviceReminderLabel => 'Etikett';

  @override
  String get serviceReminderInterval => 'Intervall (km)';

  @override
  String get serviceReminderLastService => 'Senaste service';

  @override
  String get serviceReminderMarkDone => 'Markera som klar';

  @override
  String get serviceReminderDueTitle => 'Service förfaller';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label förfaller – $kmOver km förbi intervallet.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Registrera dig på OPINET för att få en gratis API-nyckel';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registrera dig på CNE för att få en gratis API-nyckel';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Är det här din bil?';

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
      'Partiell information (offline). Du kan redigera nedan.';

  @override
  String get vinDecodeError => 'Kunde inte avkoda detta VIN';

  @override
  String get vinInvalidFormat => 'Ogiltigt VIN-format';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2-anslutning förlorad – inspelning pausad';

  @override
  String get obd2PauseBannerResume => 'Återuppta inspelning';

  @override
  String get obd2PauseBannerEnd => 'Avsluta inspelning';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Förbrukningskalibrering uppdaterad för $vehicleName – noggrannheten förbättrad med $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Återställ volymetrisk effektivitet?';

  @override
  String get veResetConfirmBody =>
      'Det här kasserar den inlärda volymetriska effektiviteten (η_v) och återställer standardvärdet (0,85). Bränsleflödesuppskattningar på resenivå faller tillbaka på tillverkarens konstant tills kalibratorn samlar nya prover från kommande resor.';

  @override
  String get alertsRadiusSectionTitle => 'Radiebaserade aviseringar';

  @override
  String get alertsRadiusAdd => 'Lägg till radieavisering';

  @override
  String get alertsRadiusEmptyTitle => 'Inga radiebaserade aviseringar ännu';

  @override
  String get alertsRadiusEmptyCta => 'Skapa en radieavisering';

  @override
  String get alertsRadiusCreateTitle => 'Skapa radieavisering';

  @override
  String get alertsRadiusLabelHint => 'Etikett (t.ex. Hemma diesel)';

  @override
  String get alertsRadiusFuelType => 'Bränsletyp';

  @override
  String get alertsRadiusThreshold => 'Gränsvärde (€/L)';

  @override
  String get alertsRadiusKm => 'Radie (km)';

  @override
  String get alertsRadiusCenterGps => 'Använd min plats';

  @override
  String get alertsRadiusCenterPostalCode => 'Postnummer';

  @override
  String get alertsRadiusSave => 'Spara';

  @override
  String get alertsRadiusCancel => 'Avbryt';

  @override
  String get alertsRadiusDeleteConfirm => 'Radera radieavisering?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 ansluten: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Para ihop en OBD2-adapter';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel sjönk vid närliggande stationer';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stationer sjönk med upp till $maxDropCents¢ under den senaste timmen';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankning sparad';

  @override
  String get radiusAlertsEntryTitle =>
      'Radiebaserade aviseringar och statistik';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Bli aviserad när priserna sjunker nära dig';

  @override
  String get notFoundTitle => 'Sidan hittades inte';

  @override
  String notFoundBody(String location) {
    return '\"$location\" hittades inte.';
  }

  @override
  String get notFoundHomeButton => 'Hem';

  @override
  String get consumptionTabHiddenNotice =>
      'Förbrukningsfliken är dold av dina profilinställningar.';

  @override
  String get swipeBetweenTabsHint =>
      'Tips: svep vänster eller höger för att byta mellan flikar.';

  @override
  String get discardChangesTitle => 'Kasta ändringar?';

  @override
  String get discardChangesBody =>
      'Du har osparade ändringar. Om du lämnar nu kastas de.';

  @override
  String get discardChangesConfirm => 'Kasta';

  @override
  String get discardChangesKeepEditing => 'Fortsätt redigera';

  @override
  String get tankSyncSectionSubtitle =>
      'Molnsynkronisering på alla dina enheter';

  @override
  String get mapUnavailable => 'Kartan är inte tillgänglig';

  @override
  String get routeNameHintExample => 't.ex. Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Aktuell';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API-nyckel';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API-nyckel';

  @override
  String get tapToUpdateGpsPosition => 'Tryck för att uppdatera GPS-position';

  @override
  String get nameLabel => 'Namn';

  @override
  String get obd2ErrorPermissionDenied =>
      'Bluetooth-behörighet krävs för att ansluta till en OBD2-adapter.';

  @override
  String get obd2ErrorBluetoothOff => 'Slå på Bluetooth och försök igen.';

  @override
  String get obd2ErrorScanTimeout =>
      'Ingen OBD2-adapter hittades i närheten. Kontrollera att den är ansluten och påslagen.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2-adaptern svarade inte. Slå på tändningen och försök igen.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2-adaptern skickade ett okänt svar. Den kan vara inkompatibel — prova en annan adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2-adaptern kopplades från. Anslut igen och försök igen.';

  @override
  String get onboardingExploreDemoData => 'Utforska med demodata';

  @override
  String get achievementSmoothDriver => 'Mjukserie';

  @override
  String get achievementSmoothDriverDesc =>
      'Kör 5 resor i rad med ett mjukkörningspoäng på 80 eller högre.';

  @override
  String get achievementColdStartAware => 'Kallstartmedveten';

  @override
  String get achievementColdStartAwareDesc =>
      'Håll hela en månads kallstartsbränslekostnad under 2 % av totalt bränsle – kombinera korta resor.';

  @override
  String get achievementHighwayMaster => 'Motorvägsmästare';

  @override
  String get achievementHighwayMasterDesc =>
      'Genomför en resa på 30 km+ i jämn hastighet med ett mjukkörningspoäng på 90 eller högre.';

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
    return '$price $currency (mål: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel har sjunkit på stationer i närheten';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count stationer sjönk med upp till $cents¢ den senaste timmen';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count stationer ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count till';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Prislarm i bakgrunden fungerar för närvarande endast för bensinstationer i Tyskland. Det här larmet sparas, men kanske aldrig meddelar dig förrän larm mellan länder blir tillgängliga.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Radielarm kontrollerar för närvarande endast bensinstationer i Tyskland.';

  @override
  String get approachOverlaySection => 'Inflygningsöverlägg';

  @override
  String get approachRadiusLabel => 'Radie';

  @override
  String approachRadiusCaption(String km) {
    return 'Överlägget förstoras och visar priset när du är inom $km km från en station';
  }

  @override
  String get approachPriceModeLabel => 'Visa pris för';

  @override
  String get approachPriceModeNearest => 'Närmaste station';

  @override
  String get approachPriceModeCheapestInRadius => 'Billigaste i radien';

  @override
  String get approachMinPollLabel => 'Min. uppdatering';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Undre gräns för hur ofta överlägget uppdaterar närmaste station (snabbare i hastighet, aldrig oftare än $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testa närmandeöverlägg';

  @override
  String get approachTestStopButton => 'Stoppa test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktivt — överlägget visar priset för $station';
  }

  @override
  String get approachTestUnavailable =>
      'Lägg till en favoritstation för att testa närmandeöverlägget';

  @override
  String approachStationDistance(String meters) {
    return '$meters m bort';
  }

  @override
  String get authErrorNoNetwork =>
      'Ingen nätverksanslutning. Försök igen senare.';

  @override
  String get authErrorInvalidCredentials =>
      'Ogiltig e-post eller lösenord. Kontrollera dina uppgifter.';

  @override
  String get authErrorUserAlreadyExists =>
      'Den här e-postadressen är redan registrerad. Prova att logga in istället.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Kontrollera din e-post och bekräfta ditt konto först.';

  @override
  String get authErrorGeneric => 'Inloggningen misslyckades. Försök igen.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Bakgrundsplats – endast för autoinspelning';

  @override
  String get autoRecordConsentExplanationTitle => 'Om den här behörigheten';

  @override
  String get autoRecordConsentExplanationBody =>
      'Autoinspelning behöver bakgrundsplats för att identifiera när du börjar köra med appen stängd. Den här behörigheten används enbart av autoinspelning – stationssökning och kartcentrering använder en separat förgrundsbehörighet.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Förstått';

  @override
  String get autoRecordConsentExplanationTooltip => 'Vad betyder det här?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Tryck för att hantera i systeminställningar';

  @override
  String get autoRecordSectionTitle => 'Autoinspelning';

  @override
  String get autoRecordToggleLabel => 'Spela in resor automatiskt';

  @override
  String get autoRecordStatusActiveLabel =>
      'Autoinspelning aktiveras nästa gång du sätter dig i bilen.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Para ihop en OBD2-adapter för att aktivera autoinspelning.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Tillåt bakgrundsplats så att autoinspelning fortsätter köra med skärmen av.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Para ihop en adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Starthastighet (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Sparfördröjning efter frånkoppling (sekunder)';

  @override
  String get autoRecordPairedAdapterLabel => 'Ihopparad adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Ingen adapter ihopparad. Para ihop en via OBD2-introduktionen först.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Bakgrundsplats tillåten';

  @override
  String get autoRecordBackgroundLocationRequest => 'Begär behörighet';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Varför \"Tillåt alltid\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Autoinspelning strömmar GPS-koordinater från OBD-II-förgrundsservicen med skärmen av så att reserutten förblir korrekt. Android kräver alternativet \"Tillåt alltid\" för att det ska fortsätta fungera efter att enheten låses.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Öppna inställningar';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Platsbehörighet krävs';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Kunde inte begära bakgrundsplats';

  @override
  String get autoRecordBadgeClearTooltip => 'Rensa räknare';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Para ihop en adapter i avsnittet nedan för att aktivera autoinspelning';

  @override
  String get exportBackupTooltip => 'Exportera säkerhetskopia';

  @override
  String get exportBackupReady => 'Säkerhetskopia klar – välj ett mål';

  @override
  String get exportBackupFailed =>
      'Export av säkerhetskopia misslyckades – försök igen';

  @override
  String get brokenMapChipVerifying => 'MAP-sensor verifierar…';

  @override
  String get brokenMapChipDisclaimer => 'MAP-avläsningar misstänkta';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-sensor läser felaktigt – bränslevisningar kan vara 50–80 % för låga. Prova en annan adapter.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-sensor otillförlitlig. Visar tankningssnitt istället för direktbränsleflöde.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP-sensor: verifierad ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP-sensor: verifierar ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP-sensor: misstänkt ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin% (verifierad)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-sensordiagnostik';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Trasig-MAP-konfidens: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observationer registrerade';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verifierat ren';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Det här fordonets MAP-sensor har inte observerats ännu.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blocklistade adaptrar';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Inga adaptrar är blocklistade.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter – flaggad $percent% trasig';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Rensa';

  @override
  String get brokenMapRevPromptTitle => 'Varva motorn';

  @override
  String get brokenMapRevPromptBody =>
      'Tryck kort på gasen så att appen kan kontrollera att MAP-sensorn svarar.';

  @override
  String get brokenMapRevPromptConfirm => 'Klar – jag varvade';

  @override
  String get calibrationAdvancedTitle => 'Avancerad kalibrering';

  @override
  String get calibrationDisplacementLabel => 'Motorvolym (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volymetrisk effektivitet (η_v)';

  @override
  String get calibrationAfrLabel => 'Luft-bränsle-förhållande (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Bränsletäthet (g/L)';

  @override
  String get calibrationSourceDetected => '(detekterad från VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(standard)';

  @override
  String get calibrationSourceManual => '(manuell)';

  @override
  String get calibrationResetToDetected => 'Återställ till detekterat värde';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrerad, $samples prover)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (lär sig, $samples prover)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (standard – ingen full tankning ännu)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples prover';
  }

  @override
  String get calibrationResetLearner => 'Återställ inlärning';

  @override
  String get calibrationBasisAtkinson => 'Atkinson-cykel';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turboladdad + DI';

  @override
  String get calibrationBasisTurbo => 'Turboladdad';

  @override
  String get calibrationBasisNaDi => 'Naturligt aspirerad + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — $basis standard)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Din $makeModel är markerad som diesel men matchar en bensinpost i katalogen. Tryck för att uppdatera.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Uppdatera';

  @override
  String get consumptionTabFuel => 'Bränsle';

  @override
  String get consumptionTabCharging => 'Laddning';

  @override
  String get noChargingLogsTitle => 'Inga laddningsloggar ännu';

  @override
  String get noChargingLogsSubtitle =>
      'Logga din första laddningssession för att börja spåra EUR/100 km och kWh/100 km.';

  @override
  String get addChargingLog => 'Logga laddning';

  @override
  String get addChargingLogTitle => 'Logga laddningssession';

  @override
  String get chargingKwh => 'Energi (kWh)';

  @override
  String get chargingCost => 'Total kostnad';

  @override
  String get chargingTimeMin => 'Laddningstid (min)';

  @override
  String get chargingStationName => 'Station (valfritt)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Behöver en tidigare logg för jämförelse';

  @override
  String get chargingLogButtonLabel => 'Logga laddning';

  @override
  String get chargingCostTrendTitle => 'Laddningskostnadstrend';

  @override
  String get chargingEfficiencyTitle => 'Effektivitet (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Inte tillräckligt med data ännu';

  @override
  String get chargingChartsMonthAxis => 'Månad';

  @override
  String get consoFeatureGroupTitle => 'Förbrukning';

  @override
  String get consoFeatureGroupDescription =>
      'Spåra din förbrukning – manuella tankningar eller automatisk OBD2-reseinspelning.';

  @override
  String get consoModeOff => 'Av';

  @override
  String get consoModeFuel => 'Bränsle';

  @override
  String get consoModeFuelAndTrips => 'Bränsle + Resor';

  @override
  String get consoModeOffDescription =>
      'Ingen förbrukningsflik och inga förbrukningsinställningar.';

  @override
  String get consoModeFuelDescription =>
      'Endast manuella tankningar. Användbart utan OBD2-adapter.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Lägger till automatisk OBD2-reseinspelning. Kräver en ihopparad adapter.';

  @override
  String get consoSubsectionVehicles => 'Mina fordon';

  @override
  String get consoSubsectionTrajets => 'Resor (OBD2)';

  @override
  String get consoSubsectionToggles => 'Körning';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Noggrannhet: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Hög';

  @override
  String get consumptionAccuracyMedium => 'Medel';

  @override
  String get consumptionAccuracyLow => 'Låg';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Fullständig kalibrering: tankningar plus resor inspelade med OBD2. L/100 km-värdet följer verkligheten inom några få procent.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankningar har förankrat förbrukningsmodellen, men ingen OBD2-resa har ännu bearbetats. Spela in en med OBD2 anslutet för att nå hög noggrannhet.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Endast GPS — inga tankningar har ännu förankrat förbrukningsmodellen. Lägg till ett par fulla tankningar för att förbättra noggrannheten.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count deldel tankningar väntar på full tankning – inte i snittet',
      one: '1 deldel tankning väntar på full tankning – inte i snittet',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% av bränslet från autokorrigeringar – granska poster';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Autokorrigering – tryck för att redigera';

  @override
  String get fillUpCorrectionEditTitle => 'Redigera autokorrigering';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Den här posten genererades automatiskt för att stänga gapet mellan inspelade resor och tankat bränsle. Justera värdena om du känner till de faktiska siffrorna.';

  @override
  String get fillUpCorrectionDelete => 'Radera korrigering';

  @override
  String get fillUpCorrectionStation => 'Stationsnamn (valfritt)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grekland)';

  @override
  String get greeceCommunityApiNotice =>
      'Drivs av det communityunderhållna fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumänien)';

  @override
  String get romaniaScrapingNotice =>
      'Drivs av pretcarburant.ro (Konkurrensrådet + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country-stationer $km km bort – €$price/L billigare';
  }

  @override
  String get crossBorderTapToSwitch => 'Tryck för att byta land';

  @override
  String get crossBorderDismissTooltip => 'Avfärda';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Utvecklarverktyg';

  @override
  String get developerToolsSubtitle =>
      'Diagnostik och felsökningsverktyg — visas endast i utvecklar-/felsökningsläge.';

  @override
  String get developerToolsMenuSubtitle =>
      'Fellogg, testaviseringar, diagnostik';

  @override
  String get developerToolsErrorLogGroupTitle => 'Fellogg';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Spara fellogg ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Rensa fellogg';

  @override
  String get developerToolsViewErrorLog => 'Visa fellogg';

  @override
  String get developerToolsErrorLogEmpty => 'Inga felspår registrerade.';

  @override
  String get developerToolsAlertsGroupTitle => 'Varningar och aviseringar';

  @override
  String get developerToolsFireTestNotification => 'Skicka testavisering';

  @override
  String get developerToolsTestNotificationTitle => 'Testavisering';

  @override
  String get developerToolsTestNotificationBody =>
      'Om du kan läsa detta fungerar aviseringarna.';

  @override
  String get developerToolsTestNotificationSent => 'Testavisering skickad.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Aviseringar är blockerade — aktivera dem i systeminställningarna och försök igen.';

  @override
  String get developerToolsRunTestAlert => 'Kör testvarningsflöde';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testvarning utlöst — flödet levererade $count avisering(ar).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testprisvarning';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Syntetisk träff: en station under ditt mål hittades i närheten.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostik';

  @override
  String get developerToolsFeatureFlagDump => 'Inspektör för funktionsflaggor';

  @override
  String get developerToolsFlagOn => 'På';

  @override
  String get developerToolsFlagOff => 'Av';

  @override
  String get developerToolsClearCaches => 'Rensa cacheminnen';

  @override
  String get developerToolsCachesCleared => 'Cacheminnen rensade.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopiera diagnostik';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostik kopierad till urklipp.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Bygginformation';

  @override
  String get developerToolsBuildVersion => 'Appversion';

  @override
  String get developerToolsBuildChannel => 'Byggkanal';

  @override
  String get insightCardTitle => 'Mest slösaktiga beteenden';

  @override
  String get insightEmptyState =>
      'Inga anmärkningsvärda ineffektiviteter – fortsätt så!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor över 3000 RPM ($pctTime% av resan): slösade $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count hårda accelerationer: slösade $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Tomgång ($pctTime% av resan): slösade $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% av resan';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Kör tungt i låg växel ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Stäng av motorn vid långa stopp i stället för att låta den gå på tomgång.';

  @override
  String get lessonAdviceHighRpm =>
      'Växla upp tidigare för att hålla motorn utanför det höga varvtalsområdet.';

  @override
  String get lessonAdviceHardAccel =>
      'Ge mjukt gas — jämn acceleration drar mindre bränsle.';

  @override
  String get lessonAdviceLowGear =>
      'Växla upp tidigare så att motorn lägger sig på ett lägre och mer bränslesnålt varvtal.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Ihållande hög hastighet ($pctTime % av resan): slösade $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Ihållande hög hastighet ($pctTime % av resan)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Lätta på gasen över 110 km/h – luftmotståndet ökar kraftigt, så lite långsammare sparar mycket bränsle.';

  @override
  String get lessonSmoothDrivingTitle => 'Mjuk körning – bra jobbat!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Ingen hård acceleration eller inbromsning på den här resan – jämn körning håller förbrukningen låg.';

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
  String get drivingScoreCardTitle => 'Körpoäng';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Sammansatt poäng från tomgång, hårda accelerationer, hård inbromsning och tid vid högt RPM. En jämförelse \'bättre än X% av tidigare resor\' kommer i en kommande release.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Körpoäng $score av 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Tomgång';

  @override
  String get drivingScorePenaltyHardAccel => 'Hårda accelerationer';

  @override
  String get drivingScorePenaltyHardBrake => 'Hård inbromsning';

  @override
  String get drivingScorePenaltyHighRpm => 'Högt RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Fullgas';

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
    return '≈ $liters L sparade';
  }

  @override
  String get ecoRouteHint =>
      'Smartare körning – föredrar jämn motorväg framför slingrande genvägar.';

  @override
  String get favoritesShareAction => 'Dela';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favoriter den $date';
  }

  @override
  String get favoritesShareError => 'Kunde inte generera delningsbild';

  @override
  String get featureManagementSectionTitle => 'Funktionshantering';

  @override
  String get featureManagementSectionSubtitle =>
      'Slå på eller av enskilda funktioner. Vissa funktioner är beroende av andra – reglage är inaktiverade tills förutsättningarna är uppfyllda.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2-reseinspelning';

  @override
  String get featureDescription_obd2TripRecording =>
      'Registrera resor automatiskt via OBD2.';

  @override
  String get featureLabel_gamification => 'Spelifiering';

  @override
  String get featureDescription_gamification => 'Körpoäng och uppnådda märken.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptisk ecocoach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Realtids-haptisk feedback under en resa.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synkronisering mellan enheter via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Förbrukningsanalys';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Fliken för analys av tankningar och resor.';

  @override
  String get featureLabel_baselineSync => 'Grundsynk';

  @override
  String get featureDescription_baselineSync =>
      'Synka körningsgränser via TankSync.';

  @override
  String get featureLabel_unifiedSearchResults => 'Enhetliga sökresultat';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Enkel resultatlista som kombinerar bränsle- och EV-stationer.';

  @override
  String get featureLabel_priceAlerts => 'Prisaviseringar';

  @override
  String get featureDescription_priceAlerts =>
      'Tröskelbaserade aviseringar om prissänkningar.';

  @override
  String get featureLabel_priceHistory => 'Prishistorik';

  @override
  String get featureDescription_priceHistory =>
      '30-dagars prisdiagram på stationsdetaljer.';

  @override
  String get featureLabel_routePlanning => 'Ruttplanering';

  @override
  String get featureDescription_routePlanning =>
      'Billigaste stopp längs din rutt.';

  @override
  String get featureLabel_evCharging => 'EV-laddning';

  @override
  String get featureDescription_evCharging =>
      'Laddningsstationer via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling-vägledning med OSM-trafiksignaler.';

  @override
  String get featureLabel_gpsTripPath => 'GPS-resespår';

  @override
  String get featureDescription_gpsTripPath =>
      'Spara GPS-spårprover tillsammans med varje resa.';

  @override
  String get featureLabel_autoRecord => 'Autoinspelning';

  @override
  String get featureDescription_autoRecord =>
      'Starta automatiskt en resa när OBD2-adaptern ansluter till ett rörligt fordon.';

  @override
  String get featureLabel_showFuel => 'Visa bränslestationer';

  @override
  String get featureDescription_showFuel =>
      'Visa bensin-/dieselstationer i sökning och på kartan.';

  @override
  String get featureLabel_showElectric => 'Visa laddningsstationer';

  @override
  String get featureDescription_showElectric =>
      'Visa EV-laddningsstationer i sökning och på kartan.';

  @override
  String get featureLabel_showConsumptionTab => 'Förbrukningsflik';

  @override
  String get featureDescription_showConsumptionTab =>
      'Visa förbrukningsanalysfliken i bottennavigeringen.';

  @override
  String get featureBlockedEnable_gamification =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureBlockedEnable_baselineSync => 'Aktivera TankSync först';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureBlockedEnable_showFuel => 'Förutsättningar ej uppfyllda';

  @override
  String get featureBlockedEnable_showElectric =>
      'Förutsättningar ej uppfyllda';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite-prisprognoser';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Prismodell på enheten – slutledning sker lokalt; egenskaper och förutsägelser lämnar aldrig enheten.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Aktivera prishistorik först';

  @override
  String get featureLabel_fuelCalculator => 'Bränsleräknare';

  @override
  String get featureDescription_fuelCalculator =>
      'Räknare för bränslekostnad inom räckhåll från sökresultaten.';

  @override
  String get featureLabel_carbonDashboard => 'Koldioxidpanel';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2-avtryckspanel nåbar från förbrukningsfliken.';

  @override
  String get featureLabel_experimentalOemPids => 'Experimentella OEM PID:ar';

  @override
  String get featureDescription_experimentalOemPids =>
      'Läs exakta tankvolymer via tillverkarsspecifika PID:ar på stödda adaptrar.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Aktivera OBD2-reseinspelning först';

  @override
  String get featureLabel_paymentQrScan => 'Skanna betalnings-QR';

  @override
  String get featureDescription_paymentQrScan =>
      'QR-läsare för betalning på stationsdetaljskärmen.';

  @override
  String get featureLabel_communityPriceReports => 'Community-prisrapporter';

  @override
  String get featureDescription_communityPriceReports =>
      'Rapportera ett stationspris från stationsdetaljskärmen.';

  @override
  String get featureLabel_obd2Optional => 'Kräv OBD2 för ressparring';

  @override
  String get featureDescription_obd2Optional =>
      'När av spelar appen in resor med endast GPS utan OBD2-adapter. Coaching är begränsat — inget direkt L/100 km, färre motorsignaler.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Kvitto OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skanna ett tryckt kvitto på skärmen Lägg till tankning för att fylla i datum, liter, totalt och station i förväg.';

  @override
  String get featureLabel_addFillUpOcrPump => 'Pumpdisplay OCR (experimentell)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Skanna en bränslepumpsdisplay för att förfylla formuläret. Igenkänningen är opålitlig idag — aktivera endast om du vill testa.';

  @override
  String get featureLabel_developerPatToken => 'Utvecklarfeedback (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Aktiverar feedbackpanelen för misslyckade skanningar som automatiskt skapar GitHub-issues med en Personal Access Token. Funktion för avancerade användare / bidragsgivare.';

  @override
  String get featureLabel_debugMode => 'Utvecklar-/felsökningsläge';

  @override
  String get featureDescription_debugMode =>
      'Visar en sektion med utvecklarverktyg i inställningarna med diagnostik: export av fellogg, testaviseringar, körning av testvarningsflöde, lista över funktionsflaggor, rensning av cacheminnen och kopiering av diagnostik.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get feedbackConsentTitle => 'Skicka rapport till GitHub?';

  @override
  String get feedbackConsentBody =>
      'Det här skapar ett offentligt ärende på vårt GitHub-förråd med ditt foto och OCR-texten. Ingen persondata (plats, konto-id) skickas. Fortsätt?';

  @override
  String get feedbackConsentContinue => 'Fortsätt';

  @override
  String get feedbackConsentCancel => 'Avbryt';

  @override
  String get feedbackConsentLater => 'Senare';

  @override
  String get feedbackTokenSectionTitle => 'Feedback om dålig skanning (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'För att automatiskt öppna ett GitHub-ärende från en misslyckad skanning, klistra in en GitHub PAT (scope `public_repo` på tankstellen-förrådet). Annars finns manuell delning tillgänglig.';

  @override
  String get feedbackTokenStatusSet => 'Token konfigurerad';

  @override
  String get feedbackTokenStatusUnset => 'Ingen token';

  @override
  String get feedbackTokenSet => 'Ange';

  @override
  String get feedbackTokenClear => 'Rensa';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personlig åtkomsttoken';

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
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verifierad av adapter';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Stämmer inte med adapteravläsning';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Din post: $userL L. Adaptern säger: $adapterL L (delta från bränslenivå före/efter). Använd adaptervärdet?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Behåll min post';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Använd adaptervärde';

  @override
  String get scanReceiptNoData => 'Ingen kvittodata hittades – försök igen';

  @override
  String get scanReceiptSuccess =>
      'Kvitto skannat – kontrollera värdena. Tryck på \"Rapportera skanningsfel\" nedan om något är fel.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skanning misslyckades: $error';
  }

  @override
  String get scanPumpUnreadable => 'Pumpdisplayen är inte läsbar – försök igen';

  @override
  String get scanPumpSuccess => 'Pumpdisplay skannad – kontrollera värdena.';

  @override
  String get scanPumpGlare =>
      'För mycket reflexer på displayen — försök igen i en liten vinkel så att siffrorna inte bleks ut.';

  @override
  String scanPumpFailed(String error) {
    return 'Pumpskanning misslyckades: $error';
  }

  @override
  String get badScanReportTitle => 'Rapportera ett skanningsfel';

  @override
  String get badScanReportTitleReceipt =>
      'Rapportera ett skanningsfel – Kvitto';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Rapportera ett skanningsfel – Pumpdisplay';

  @override
  String get pumpScanFailureTitle => 'Display oläslig';

  @override
  String get pumpScanFailureBody =>
      'Skanningen kunde inte läsa pumpdisplayen. Vad vill du göra?';

  @override
  String get pumpScanFailureCorrectManually => 'Korrigera manuellt';

  @override
  String get pumpScanFailureReport => 'Rapportera';

  @override
  String get pumpScanFailureRemove => 'Ta bort foto';

  @override
  String get badScanReportHint =>
      'Vi delar kvittofotot och båda uppsättningarna av värden så att nästa version kan lära sig den här layouten.';

  @override
  String get badScanReportShareAction => 'Dela rapport + foto';

  @override
  String get badScanReportFieldBrandLayout => 'Märkeslayout';

  @override
  String get badScanReportFieldTotal => 'Totalt';

  @override
  String get badScanReportFieldPricePerLiter => 'Pris/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Bränsle';

  @override
  String get badScanReportFieldDate => 'Datum';

  @override
  String get badScanReportHeaderField => 'Fält';

  @override
  String get badScanReportHeaderScanned => 'Skannat';

  @override
  String get badScanReportHeaderYouTyped => 'Du skrev';

  @override
  String get badScanReportCreateTicket => 'Skapa ärende';

  @override
  String get badScanReportOpenInBrowser => 'Öppna i webbläsare';

  @override
  String get badScanReportFallbackToShare =>
      'Inlämning misslyckades – manuell delning';

  @override
  String get pumpCameraHint =>
      'Rikta in de tre siffrorna på pumpdisplayen inom ramen';

  @override
  String get pumpCameraCapture => 'Ta bild';

  @override
  String get pumpCameraPermissionDenied =>
      'Kameraåtkomst krävs för att skanna pumpdisplayen. Aktivera den i enhetens inställningar.';

  @override
  String get pumpCameraError =>
      'Kameran kunde inte startas. Försök igen eller ange värdena manuellt.';

  @override
  String get pumpCameraOrientationHorizontal => 'Byt till horisontell layout';

  @override
  String get pumpCameraOrientationVertical => 'Byt till vertikal layout';

  @override
  String get pumpCameraGlareWarning =>
      'För mycket bländning — luta något för att undvika reflexer';

  @override
  String get pumpCameraAlignHint =>
      'Rikta in displayen i ramen och ta sedan en bild';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Vad du tankade';

  @override
  String get fillUpSectionWhatSubtitle => 'Bränsle, mängd, pris';

  @override
  String get fillUpSectionWhereTitle => 'Var du var';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, vägmätare, anteckningar';

  @override
  String get fillUpImportFromLabel => 'Importera från…';

  @override
  String get fillUpImportSheetTitle => 'Importera tankningsdata';

  @override
  String get fillUpImportReceiptLabel => 'Kvitto';

  @override
  String get fillUpImportReceiptDescription =>
      'Skanna ett papperskvitto med kameran';

  @override
  String get fillUpImportPumpLabel => 'Pumpdisplay';

  @override
  String get fillUpImportPumpDescription =>
      'Läs Betrag / Preis från pump-LCD:n';

  @override
  String get fillUpImportObdLabel => 'OBD-II-adapter';

  @override
  String get fillUpImportObdDescription =>
      'Läs vägmätare från OBD-II-porten via Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Pris per liter';

  @override
  String get vehicleHeaderPlateLabel => 'Registreringsskylt';

  @override
  String get vehicleHeaderUntitled => 'Nytt fordon';

  @override
  String get vehicleSectionIdentityTitle => 'Identitet';

  @override
  String get vehicleSectionIdentitySubtitle => 'Namn och VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Drivlina';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Hur detta fordon drivs';

  @override
  String get calibrationModeLabel => 'Kalibreringsläge';

  @override
  String get calibrationModeRule => 'Regelbaserat';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Regelbaserat tilldelar varje körprov exakt en situation. Fuzzy sprider det över alla efter hur väl var och en passar – jämnare runt 60 km/h eller vid varierande lutningar, men långsammare att fylla alla hinkar.';

  @override
  String get profileGamificationToggleTitle => 'Visa prestationer och poäng';

  @override
  String get profileGamificationToggleSubtitle =>
      'När av döljs märken, poäng och troféikoner i hela appen.';

  @override
  String get coachingGpsLiftOff => 'Släpp gasen';

  @override
  String get coachingGpsAnticipateBrake => 'Förutse';

  @override
  String get coachingGpsSmoothAccel => 'Mjuk acceleration';

  @override
  String get gpsDiagnosticsTitle => 'GPS-samplingdiagnostik';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps luckor',
      one: '1 lucka',
      zero: 'inga luckor',
    );
    return '$count prover · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Medianintervall: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Inspelat under inspelning för att verifiera GPS-kadensen under telefonsömn.';

  @override
  String get gpsMatrixMaturityCold => 'Kall';

  @override
  String get gpsMatrixMaturityWarming => 'Värms upp';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergerad';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS-matrisen värms upp ($count förfiningar hittills). Uppskattningar är preliminära.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS-matrisen konvergerar ($count tankningar). Uppskattningar är användbara men kan avvika några %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS-matrisen har konvergerat ($count tankningar). Uppskattningar inom ~2 % av verklig förbrukning.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Körning';

  @override
  String get hapticEcoCoachSettingTitle => 'Realtids-ecocoachning';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Mjuk haptik + on-screen-tips när du gäspar under krysshastighet';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Varsamt med gasen – frihjul sparar mer';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigera till $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Ta bort $name från favoriter';
  }

  @override
  String get showOnMapSemanticLabel => 'Visa stationer på kartan';

  @override
  String get searchResultsSemanticLabel => 'Sökresultat';

  @override
  String get searchCriteriaSemanticLabel =>
      'Sammanfattning av sökkriterier. Tryck för att redigera.';

  @override
  String get noFavoritesSemanticLabel =>
      'Inga favoriter ännu. Tryck på stjärnan vid en station för att spara den som favorit.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stationen är öppen',
      'false': 'Stationen är stängd',
      'other': 'Stationen är stängd',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Land $name, vald',
      'false': 'Land $name',
      'other': 'Land $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Språk $name, vald',
      'false': 'Språk $name',
      'other': 'Språk $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sortera efter $option, vald',
      'false': 'Sortera efter $option',
      'other': 'Sortera efter $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Bränsle $type, vald',
      'false': 'Bränsle $type',
      'other': 'Bränsle $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Laddstation $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Integritetssköld med bränsledroppe';

  @override
  String get globeIllustrationSemantic =>
      'Jordglob med markörer för bensinstationer';

  @override
  String get fuelPumpIllustrationSemantic => 'Bränslepump med prisindikator';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, datakälla: $provider, $keyRequirement, bränsletyper: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'API-nyckel krävs';

  @override
  String get countryInfoNoKeyNeeded => 'Gratis, ingen nyckel behövs';

  @override
  String countryInfoDataSource(String provider) {
    return 'Data: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Bränsletyper: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon-nyckel';

  @override
  String get anonKeyHideTooltip => 'Dölj nyckel';

  @override
  String get anonKeyShowTooltip => 'Visa nyckel för verifiering';

  @override
  String anonKeyTooLong(int length) {
    return 'Nyckeln är för lång ($length tecken) – kontrollera om det finns extra text';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Nyckeln ser korrekt ut ($length tecken)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Nyckeln bör vara en JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Nyckeln kan vara trunkerad ($length av ~208 förväntade tecken)';
  }

  @override
  String get anonKeyExceedsMax => 'Nyckeln överstiger maximal längd';

  @override
  String get qrShareTitle => 'Dela din databas';

  @override
  String get qrShareSubtitle =>
      'Andra kan skanna den här QR-koden för att ansluta';

  @override
  String get qrShareCopyAsText => 'Kopiera som text';

  @override
  String get authInfoTitle => 'Varför skapa ett konto?';

  @override
  String get authInfoBenefit1 =>
      '• Synka favoriter, aviseringar och sparade rutter mellan enheter';

  @override
  String get authInfoBenefit2 =>
      '• Förbered en rutt på din telefon, använd den i bilen';

  @override
  String get authInfoBenefit3 => '• Ingen data delas med tredje part';

  @override
  String get authInfoBenefit4 => '• Du kan radera ditt konto när som helst';

  @override
  String get privacyLocalDataEmpty =>
      'Inget lagrat ännu. Lägg till en favorit eller ange en prisavisering för att se poster här.';

  @override
  String get privacyHideEmptyRows => 'Dölj tomma rader';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visa $count tomma rader',
      one: 'Visa $count tom rad',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-nyckelinställning (valfritt)';

  @override
  String get apiKeySetupDescription =>
      'Registrera dig för en gratis API-nyckel, eller hoppa över för att utforska appen med demodata.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider Registrering';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Genom att ange en API-nyckel accepterar du villkoren för $provider. Vidaredistribution av data är förbjuden.';
  }

  @override
  String get calculatorDistanceHint => 't.ex. 150';

  @override
  String get calculatorConsumptionHint => 't.ex. 7,0';

  @override
  String get calculatorPriceHint => 't.ex. 1,899';

  @override
  String get routeStrategyLabel => 'Strategi:';

  @override
  String get routeStrategyUniform => 'Enhetlig';

  @override
  String get routeStrategyBalanced => 'Balanserad';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (experimentell)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtil haptik vid inbromsning inför rött ljus. Av som standard – risk för distraktion.';

  @override
  String get consentSyncTripsTitle => 'Synka reseinspelningar';

  @override
  String get consentSyncTripsSubtitle =>
      'Säkerhetskopiera OBD2- och GPS-resor till TankSync. Mellan enheter, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Aktivera Molnsynkronisering ovan för att säkerhetskopiera resor.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Logga in med ett e-postkonto för att synkronisera resor mellan enheter.';

  @override
  String get consentHideDetails => 'Dölj detaljer';

  @override
  String get consentShowDetails => 'Visa detaljer';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Ogiltig länk';

  @override
  String invalidLinkBody(String path) {
    return 'Länken \"$path\" är inte giltig.';
  }

  @override
  String get home => 'Hem';

  @override
  String get locationConsentTitle => 'Platsåtkomst';

  @override
  String get locationConsentSubtitle =>
      'Den här appen vill använda din plats för att hitta bensinstationer i närheten.';

  @override
  String get locationConsentWhatHappens => 'Vad som händer med dina platsdata:';

  @override
  String get locationConsentBulletApi =>
      'Dina koordinater skickas till bränslepris-API:et för att hitta stationer i närheten.';

  @override
  String get locationConsentBulletNoServer =>
      'Din plats lagras inte på någon server — det finns ingen server.';

  @override
  String get locationConsentBulletNoTracking =>
      'Platsdata används inte för reklam, analys eller spårning.';

  @override
  String get locationConsentRevoke =>
      'Du kan när som helst återkalla platsåtkomsten i systeminställningarna. Du kan även söka på postnummer.';

  @override
  String get locationConsentLegalBasis =>
      'Rättslig grund: art. 6.1 a i GDPR (samtycke)';

  @override
  String get locationConsentDecline => 'Avböj';

  @override
  String get locationConsentAccept => 'Acceptera';

  @override
  String get loyaltySettingsTitle => 'Bränsleklubbskort';

  @override
  String get loyaltySettingsSubtitle =>
      'Tillämpa din lojalitetsrabatt på visade priser';

  @override
  String get loyaltyMenuTitle => 'Bränsleklubbskort';

  @override
  String get loyaltyMenuSubtitle =>
      'Tillämpa per-liters-rabatter från Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Lägg till kort';

  @override
  String get loyaltyAddCardSheetTitle => 'Lägg till bränsleklubbskort';

  @override
  String get loyaltyBrandLabel => 'Märke';

  @override
  String get loyaltyCardLabelLabel => 'Etikett (valfritt)';

  @override
  String get loyaltyDiscountLabel => 'Rabatt (per liter)';

  @override
  String get loyaltyDiscountInvalid => 'Ange ett positivt tal';

  @override
  String get loyaltyDeleteConfirmTitle => 'Radera kort?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Det här kortet slutar tillämpa sin rabatt.';

  @override
  String get loyaltyEmptyTitle => 'Inga bränsleklubbskort ännu';

  @override
  String get loyaltyEmptyBody =>
      'Lägg till ett kort för att automatiskt tillämpa din per-liters-rabatt på matchande stationer.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Krypande tomgångsvarv detekterat';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Tomgångsvarven har krypat upp med $percent% under dina senaste $tripCount resor. Möjligt tidigt tecken på igensatt luftfilter eller sensordrift.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Möjlig intagsbegränsning';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Bränsleflödet vid kryssning har sjunkit med $percent% under dina senaste $tripCount resor. Möjligt tecken på igensatt luftfilter eller begränsat intag – värt en genomgång.';
  }

  @override
  String get maintenanceActionDismiss => 'Avfärda';

  @override
  String get maintenanceActionSnooze => 'Snooze 30 dagar';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Den här månaden jämfört med förra månaden';

  @override
  String get consumptionMonthlyTripsLabel => 'Resor';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Körtid';

  @override
  String get consumptionMonthlyDistanceLabel => 'Sträcka';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Sn. förbrukning';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Behöver minst 3 resor per månad för jämförelse';

  @override
  String get obd2CapabilitySectionTitle => 'Adapterfunktioner';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'OEM PID:ar';

  @override
  String get obd2CapabilityFullCan => 'Full CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'För exakta liter i tanken på Peugeot/Citroën stöder appen OBDLink MX+/LX/CX (STN-chip).';

  @override
  String get obd2DebugOverlayEnabledSnack => 'OBD2-diagnostikoverlay aktiverad';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2-diagnostikoverlay inaktiverad';

  @override
  String get obd2DebugOverlayClearButton => 'Rensa';

  @override
  String get obd2DebugOverlayCloseButton => 'Stäng';

  @override
  String get obd2DebugOverlayTitle => 'OBD2-brödsmulor';

  @override
  String get obd2DiagnosticShareLabel => 'Dela diagnostiklogg';

  @override
  String get obd2DebugLoggingTitle => 'OBD2-felsökningslogg';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Spela in varje OBD2-session — anslutning, handskakning, dataluckor och återanslutningar — i en exporterbar XML-logg. Avstängd som standard.';

  @override
  String get obd2DebugSessionShareLabel => 'Dela OBD2-sessionslogg';

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
    return 'Kunde inte nå \'$adapterName\' – välj en annan adapter';
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
  String get onboardingObd2StepTitle => 'Anslut din OBD2-adapter';

  @override
  String get onboardingObd2StepBody =>
      'Koppla din OBD2-adapter till bilens port och slå på tändningen. Vi läser VIN och fyller i motordetaljer åt dig.';

  @override
  String get onboardingObd2ConnectButton => 'Anslut adapter';

  @override
  String get onboardingObd2SkipButton => 'Kanske senare';

  @override
  String get onboardingObd2ReadingVin => 'Läser VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Kunde inte läsa VIN – ange manuellt';

  @override
  String get onboardingObd2ConnectFailed =>
      'Kunde inte ansluta till adaptern. Du kan försöka igen eller hoppa över.';

  @override
  String get onboardingPickUseMode =>
      'Välj ett användningsläge för att fortsätta.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'förflutit';

  @override
  String get alertsRadiusFrequencyLabel => 'Kontrollfrekvens';

  @override
  String get alertsRadiusFrequencyDaily => 'En gång om dagen';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Två gånger om dagen';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tre gånger om dagen';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Fyra gånger om dagen';

  @override
  String get radiusAlertPickOnMap => 'Välj på kartan';

  @override
  String get radiusAlertMapPickerTitle => 'Välj aviseringscenter';

  @override
  String get radiusAlertMapPickerConfirm => 'Bekräfta';

  @override
  String get radiusAlertMapPickerCancel => 'Avbryt';

  @override
  String get radiusAlertMapPickerHint =>
      'Dra kartan för att placera aviseringscentret';

  @override
  String get radiusAlertCenterFromMap => 'Kartplats';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel nära $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'En station ligger på $price € (mål: $threshold €)';
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
  String get refuelUnitPerSession => '/session';

  @override
  String get speedConsumptionCardTitle => 'Förbrukning per hastighet';

  @override
  String get speedBandIdleJam => 'Tomgång / kö';

  @override
  String get speedBandUrban => 'Stad (10–50)';

  @override
  String get speedBandSuburban => 'Förort (50–80)';

  @override
  String get speedBandRural => 'Landsbygd (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-kryssning (100–115)';

  @override
  String get speedBandMotorway => 'Motorväg (115–130)';

  @override
  String get speedBandMotorwayFast => 'Motorväg snabb (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Spela in 30+ minuter resor med OBD2-adaptern för att låsa upp hastighets-/förbrukningsanalysen.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % av körningen';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Behöver mer data';

  @override
  String get splashLoadingLabel => 'Laddar Sparkilo';

  @override
  String get storageRecoveryTitle => 'Lagringsproblem';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo kunde inte öppna sitt lokala datalager. Lagringsfilen verkar vara skadad.';

  @override
  String get storageRecoveryGuidance =>
      'För att återställa rensar du appens lagring i enhetens inställningar eller installerar om appen. Dina favoriter och din historik sparas endast på den här enheten och kan därför inte återställas automatiskt.';

  @override
  String get tankLevelTitle => 'Tanknivå';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km räckvidd';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Senaste tankning: $date · $count resa(or) sedan';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2-mätt';

  @override
  String get tankLevelMethodDistanceFallback => 'distansbaserad uppskattning';

  @override
  String get tankLevelMethodMixed => 'blandad mätning';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Logga en tankning för att se din tanknivå';

  @override
  String get tankLevelDetailSheetTitle => 'Resor sedan senaste tankning';

  @override
  String get addFillUpIsFullTankLabel => 'Full tank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tanken fylld till brädden – avmarkera om det var en deltankning';

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'System';

  @override
  String get themeCardSubtitleLight => 'Ljust';

  @override
  String get themeCardSubtitleDark => 'Mörkt';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Följ system';

  @override
  String get themeSettingsLightLabel => 'Ljust';

  @override
  String get themeSettingsDarkLabel => 'Mörkt';

  @override
  String get themeSettingsSystemDescription =>
      'Matcha den aktuella enhetens utseende.';

  @override
  String get themeSettingsLightDescription =>
      'Ljusa bakgrunder – bäst för dagtidsanvändning.';

  @override
  String get themeSettingsDarkDescription =>
      'Mörka bakgrunder – skonsamt för ögonen på natten och sparar batteri på OLED-skärmar.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'Appens signaturgröna utseende – ljust och lättläst med mjukt gröntonade bakgrunder.';

  @override
  String get throttleRpmHistogramTitle => 'Hur du använde motorn';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gaspedalens position';

  @override
  String get throttleRpmHistogramRpmSection => 'Motorvarv';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Frihjul (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Lätt (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Fast (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Fullgas (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Tomgång (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Kryssning (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Livlig (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Hård (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Inga gas- eller RPM-prover i den här resan.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Resor';

  @override
  String get trajetsStartRecordingButton => 'Starta inspelning';

  @override
  String get trajetsResumeRecordingButton => 'Återuppta inspelning';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Ansluter till OBD2-adapter…';

  @override
  String get tripStartProgressReadingVehicleData => 'Läser fordonsdata…';

  @override
  String get tripStartProgressStartingRecording => 'Startar inspelning…';

  @override
  String get trajetsEmptyStateTitle => 'Inga resor ännu';

  @override
  String get trajetsEmptyStateBody =>
      'Tryck på Starta inspelning för att börja logga dina körningar.';

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
  String get trajetDetailSummaryTitle => 'Sammanfattning';

  @override
  String get trajetDetailFieldDate => 'Datum';

  @override
  String get trajetDetailFieldVehicle => 'Fordon';

  @override
  String get trajetDetailFieldAdapter => 'OBD2-adapter';

  @override
  String get trajetDetailFieldDistance => 'Sträcka';

  @override
  String get trajetDetailFieldDuration => 'Varaktighet';

  @override
  String get trajetDetailFieldAvgConsumption => 'Sn. förbrukning';

  @override
  String get trajetDetailFieldFuelUsed => 'Bränsle använt';

  @override
  String get trajetDetailFieldFuelCost => 'Bränslekostnad';

  @override
  String get trajetDetailFieldAvgSpeed => 'Sn. hastighet';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maxhastighet';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Hastighet (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Bränsleflöde (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Motorbelastning (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Diagram';

  @override
  String get trajetsRowColdStartChip => 'Kallstart';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motorn nådde inte driftstemperatur under den här resan – bränsleförbrukningen var högre än normalt.';

  @override
  String get trajetDetailChartEmpty => 'Inga prover inspelade';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Dela';

  @override
  String get trajetDetailShareImageOption => 'Dela bild';

  @override
  String get trajetDetailShareGpxOption => 'Dela GPS-spår (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Inga GPS-data i denna resa';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — resa den $date';
  }

  @override
  String get trajetDetailShareError => 'Kunde inte generera delningsbild';

  @override
  String get trajetDetailDeleteAction => 'Radera';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Radera den här resan?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Den här resan tas bort permanent från din historik.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Avbryt';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Radera';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2-adapter ansluten men returnerar ingen data. Prova en annan adapter eller kontrollera fordonets diagnostikprotokoll.';

  @override
  String get trajetsViewAllOnMap => 'Visa alla på karta';

  @override
  String get trajetsMapTitle => 'Resor på karta';

  @override
  String get trajetsMapShareGpx => 'Dela GPX';

  @override
  String get trajetsMapEmpty => 'Inga av de valda resorna har GPS-data.';

  @override
  String get trajetsMapShareError => 'Det gick inte att dela GPX-filen';

  @override
  String get tripLengthCardTitle => 'Förbrukning per reselängd';

  @override
  String get tripLengthBucketShort => 'Kort (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Medel (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Lång (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Behöver mer data';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resor',
      one: '1 resa',
      zero: 'inga resor',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Resespår';

  @override
  String get tripPathCardSubtitle => 'GPS-inspelad rutt';

  @override
  String get tripPathLegendTitle => 'Förbrukning';

  @override
  String get tripPathLegendEfficient => 'Effektiv (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Gränsvärde (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Slösaktigt (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get tripRecordingPinTooltip =>
      'Nålning håller skärmen på – förbrukar mer batteri';

  @override
  String get tripRecordingPinSemanticOn => 'Lossa inspelningsformulär';

  @override
  String get tripRecordingPinSemanticOff => 'Nåla inspelningsformulär';

  @override
  String get tripRecordingPinHelpTooltip => 'Vad gör nålning?';

  @override
  String get tripRecordingPinHelpTitle => 'Om nålning';

  @override
  String get tripRecordingPinHelpBody =>
      'Nålning håller skärmen på och döljer systemfält så att formuläret förblir läsbart på ett instrumentbordsfäste. Tryck igen för att lossa. Lossas automatiskt när resan slutar.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Inspelning fortsätter i bakgrunden. Tryck på det röda bandet längst upp på valfri skärm för att återgå.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Öppna den aktiva resan från förbrukningsfliken';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Nåla skärmen för att hålla GPS aktivt under resan – Android kan begränsa GPS under viloläge.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimera till en flytande ruta';

  @override
  String get tripRecordingAutoPinTitle =>
      'Fäst alltid när inspelningen startar';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Fäst formuläret automatiskt vid varje körning i stället för att trycka varje gång. Förbrukar mer batteri.';

  @override
  String get tripRecordingConnectingTitle => 'Startar inspelning…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripShareAction => 'Dela med ett annat konto';

  @override
  String get tripShareSheetTitle => 'Dela den här resan';

  @override
  String get tripShareSheetSubtitle =>
      'Ge ett annat TankSync-konto skrivskyddad åtkomst till den här inspelade resan.';

  @override
  String get tripShareEmailLabel => 'Mottagarens e-post';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Dela';

  @override
  String get tripShareCreateLinkButton => 'Skapa delningslänk';

  @override
  String get tripShareLinkCreated =>
      'Delningslänk kopierad — klistra in den till mottagaren.';

  @override
  String get tripShareSuccess => 'Resa delad.';

  @override
  String get tripShareRecipientNotFound =>
      'Inget TankSync-konto använder den e-postadressen.';

  @override
  String get tripShareError => 'Det gick inte att dela resan. Försök igen.';

  @override
  String get tripShareExistingTitle => 'Delad med';

  @override
  String get tripShareExistingEmpty => 'Inte delad med någon ännu.';

  @override
  String get tripShareDirectRecipient => 'Ett konto';

  @override
  String get tripShareLinkRecipient => 'Delningslänk (ej inlöst)';

  @override
  String get tripShareRevokeTooltip => 'Återkalla';

  @override
  String get tripShareRevoked => 'Delning återkallad.';

  @override
  String get trajetsSharedSectionTitle => 'Delad med mig';

  @override
  String get trajetsSharedBadge => 'Delad';

  @override
  String get unifiedFilterFuel => 'Bränsle';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Båda';

  @override
  String get unifiedNoResultsForFilter =>
      'Inga resultat matchar det här filtret';

  @override
  String get searchFailedSnackbar => 'Sökning misslyckades – försök igen';

  @override
  String get vinLabel => 'VIN (valfritt)';

  @override
  String get vinDecodeTooltip => 'Avkoda VIN';

  @override
  String get vinConfirmAction => 'Ja, fyll i automatiskt';

  @override
  String get vinModifyAction => 'Ändra manuellt';

  @override
  String get veResetAction => 'Återställ volymetrisk effektivitet';

  @override
  String get vehicleReadVinFromCarButton => 'Läs VIN från bilen';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Läs VIN från den ihopparade OBD2-adaptern';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN inte tillgängligt (Mode 09 PID 02 stöds inte på fordon tillverkade före 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN-läsning misslyckades – ange manuellt';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Para ihop en OBD2-adapter först för att läsa VIN automatiskt';

  @override
  String get pickerButtonLabel => 'Välj från katalog';

  @override
  String get pickerSearchHint => 'Sök märke eller modell';

  @override
  String get pickerHelpText => 'Förifylla från 50+ stödda fordon';

  @override
  String get pickerEmptyResults => 'Inga träffar';

  @override
  String get pickerCancel => 'Avbryt';

  @override
  String get pickerLoading => 'Laddar katalog…';

  @override
  String get vinInfoTooltip => 'Vad är ett VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Vad är ett VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Fordonets identifikationsnummer är en 17-teckens kod som är unik för din bil. Det är instämplat på chassit och tryckt på ditt fordonsregistreringsdokument.';

  @override
  String get vinInfoSectionWhyTitle => 'Varför vi frågar';

  @override
  String get vinInfoSectionWhyBody =>
      'Avkodning av VIN fyller automatiskt i motorvolym, cylinderantal, årsmodell, primär bränsletyp och totalvikt – vilket sparar dig från att manuellt leta upp tekniska specifikationer. OBD2-bränsleflödesberäkningen använder dessa värden för att ge dig korrekta förbrukningssiffror.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Integritet';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Ditt VIN lagras enbart lokalt i appens krypterade lagring – det laddas aldrig upp till Sparkilo-servrar. NHTSA vPIC-databasen söks med VIN men returnerar enbart anonyma tekniska specifikationer; NHTSA kopplar inte VIN till några personuppgifter. Utan nätverk returnerar en offline-sökning enbart tillverkare och land.';

  @override
  String get vinInfoSectionWhereTitle => 'Var du hittar det';

  @override
  String get vinInfoSectionWhereBody =>
      'Titta genom vindrutan i nedre vänstra hörnet på förarens sida, kontrollera dörramsklistermärket på förarsidan när dörren är öppen, eller läs av det på ditt fordonsregistreringsdokument (kort / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Förstått';

  @override
  String get vinConfirmPrivacyNote =>
      'Vi slog upp ditt VIN i NHTSA:s kostnadsfria fordonsregister – ingenting skickades till Sparkilo-servrar.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online-avkodning';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Avkoda VIN via NHTSA:s kostnadsfria offentliga tjänst';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'När du parar ihop en adapter läses ditt fordons VIN lokalt för att identifiera bilen. Aktivering av detta skickar det 17-teckens VIN till NHTSA:s kostnadsfria vPIC-tjänst för att slå upp ytterligare detaljer (modell, motorvolym, bränsletyp). VIN är den enda datan som skickas – ingen annan information lämnar din enhet.';

  @override
  String get vehicleDetectedFromVinBadge => '(detekterad)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detekterad från VIN: $summary. Tillämpa?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Tillämpa';

  @override
  String get widgetHelpSectionTitle => 'Hemskärmswidget';

  @override
  String get widgetHelpIntro =>
      'Lägg till SparKilo-widgeten på din hemskärm för att se bränsle- och laddningspriser snabbt.';

  @override
  String get widgetHelpAdd =>
      'Lägg till den från din launchers widgetväljare – håll länge på ett tomt område på hemskärmen, välj Widgets och hitta SparKilo.';

  @override
  String get widgetHelpTap =>
      'Tryck på en station i widgeten för att öppna den i appen. Tryck på uppdateringsikonen för att uppdatera priser.';

  @override
  String get widgetHelpConfigure =>
      'På Android, håll länge på widgeten och välj Konfigurera om för att ändra profil, färg och innehåll.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Valen nedan tillämpas på varje installerad widget vid nästa uppdatering.';

  @override
  String get widgetDefaultsColorLabel => 'Färgschema';

  @override
  String get widgetDefaultsVariantLabel => 'Innehållsvariant';

  @override
  String get widgetColorSchemeSystem => 'Följ systemet';

  @override
  String get widgetColorSchemeLight => 'Ljust';

  @override
  String get widgetColorSchemeDark => 'Mörkt';

  @override
  String get widgetColorSchemeBlue => 'Blått';

  @override
  String get widgetColorSchemeGreen => 'Grönt';

  @override
  String get widgetColorSchemeOrange => 'Orange';

  @override
  String get widgetVariantDefault => 'Endast aktuellt pris';

  @override
  String get widgetVariantPredictive => 'Prediktiv: bästa tid att tanka';

  @override
  String get widgetPredictiveNowPrefix => 'nu';
}
