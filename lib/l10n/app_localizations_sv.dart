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
  String get fabRunSearch => 'Kör sökning';

  @override
  String get routeSearchingChip => 'Söker rutten…';

  @override
  String get searchCriteriaTitle => 'Sökkriterier';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Inom $km km';
  }

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
  String get freeNoKey => 'Gratis — ingen nyckel behövs';

  @override
  String get apiKeyRequired => 'API-nyckel krävs';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String stationsFound(int count) {
    return '$count bensinstationer hittades';
  }

  @override
  String get storageUsage => 'Lagringsanvändning på denna enhet';

  @override
  String get settingsLabel => 'Inställningar';

  @override
  String get total => 'Totalt';

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
  String get deleteAllButton => 'Ta bort allt';

  @override
  String get cacheEmpty => 'Cachen är tom';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data från statliga pristransparensorgan.';

  @override
  String get apiKeyFormatError =>
      'Ogiltigt format — UUID förväntat (8-4-4-4-12)';

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
  String get searchLocationPlaceholder => 'Adress, postnummer eller ort';

  @override
  String get configTankSyncConnected => 'Ansluten';

  @override
  String get configTankSyncDisabled => 'Inaktiverad';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get fuels => 'Bränslen';

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
  String profileSwitchedTo(String profile) {
    return 'Bytte till $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profilen $name skapad';
  }

  @override
  String profileCountryTaken(String country) {
    return 'En profil för $country finns redan — redigera den istället.';
  }

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
  String get evPriceFree => 'Gratis';

  @override
  String get evPricePayAtLocation => 'Betalning på plats';

  @override
  String get evPriceMembership => 'Medlemskap krävs';

  @override
  String get evPriceIndicative => 'Vägledande pris';

  @override
  String get evPriceDeclaredByOperator =>
      'Vägledande pris uppgivet av operatören — kontrollera på plats';

  @override
  String get evPriceFranceAttribution =>
      'Prissättning: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Bästa möjliga prissättning från OpenChargeMap — sparsam och kan vara ofullständig.';

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
  String get edit => 'Redigera';

  @override
  String get fuelPricesApiKey => 'Bränslepriser API-nyckel';

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
  String get noStationsAlongThisRoute =>
      'Inga stationer hittades längs denna rutt.';

  @override
  String get fuelCostCalculator => 'Bränslekostnadskalkylator';

  @override
  String get distanceKm => 'Avstånd (km)';

  @override
  String get tripCost => 'Resekostnad';

  @override
  String get fuelNeeded => 'Bränsle som behövs';

  @override
  String get totalCost => 'Total kostnad';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Sträcka ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Förbrukning ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Bränslepris ($unit)';
  }

  @override
  String get calculatorUseMine => 'Använd';

  @override
  String get calculatorApplied => 'Tillämpad';

  @override
  String get tripDetails => 'Reseinformation';

  @override
  String get calculatorRoundTrip => 'Tur och retur';

  @override
  String get roundTripTotal => 'Tur och retur';

  @override
  String get costPerDistance => 'Kostnad per km';

  @override
  String get costPerMonth => 'Kostnad per månad';

  @override
  String get calculatorEstimateMonthly => 'Uppskatta månadskostnad';

  @override
  String get calculatorTripsPerMonth => 'Resor per månad';

  @override
  String get calculatorTripsPerMonthHint => 't.ex. 20';

  @override
  String get calculatorReset => 'Återställ';

  @override
  String get calculatorResultPlaceholder =>
      'Fyll i sträcka, förbrukning och pris för att se din resekostnad';

  @override
  String get priceHistory => 'Prishistorik';

  @override
  String get favoritesDataCache => 'Favoritdata';

  @override
  String get citySearchCache => 'Stadsökning';

  @override
  String get noPriceHistory => 'Ingen prishistorik ännu';

  @override
  String get noStatistics => 'Ingen statistik tillgänglig';

  @override
  String get showAllFuelTypes => 'Visa alla bränsletyper';

  @override
  String get connected => 'Ansluten';

  @override
  String get disconnectTankSync => 'Koppla från TankSync';

  @override
  String get viewMyData => 'Visa mina data';

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
  String get gdprContinueAll => 'Fortsätt med allt';

  @override
  String get gdprContinueSelected => 'Fortsätt med valda';

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
  String get privacySyncMode => 'Synkläge';

  @override
  String get privacySyncUserId => 'Användar-ID';

  @override
  String get privacySyncDescription =>
      'När synkronisering är aktiverad lagras favoriter, aviseringar, ignorerade stationer och betyg även på TankSync-servern.';

  @override
  String get privacyExportSuccess => 'Data exporterad till urklipp';

  @override
  String get privacyExportCsvSuccess => 'CSV-data exporterad till urklipp';

  @override
  String get savedToDownloadsFolder => 'Sparad i mappen Hämtningar';

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
  String get voiceAnnouncementProximityRadius => 'Aviseringsradie';

  @override
  String get voiceAnnouncementCooldown => 'Upprepningsintervall';

  @override
  String get voiceAnnouncementPriceLimit => 'Maxpris';

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
  String get obdPermissionDenied =>
      'Bevilja Bluetooth-behörighet i systeminställningarna';

  @override
  String get obdPickerTitle => 'Välj en OBD2-adapter';

  @override
  String get obdPickerScanning => 'Söker efter adaptrar…';

  @override
  String get obdPickerConnecting => 'Ansluter…';

  @override
  String get tripSummaryTitle => 'Resesammanfattning';

  @override
  String get tripMetricDistance => 'Sträcka';

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
  String get vehicleBaselineShowDetails => 'Visa uppdelning per situation';

  @override
  String get vehicleBaselineHideDetails => 'Dölj uppdelning per situation';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Ej registrerat ännu: $situations. Dessa körsituationer har fortfarande 0 prover, så basvärdet är ofullständigt.';
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
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-behörighet krävs';

  @override
  String get obd2StatusConnectedBody => 'Redo att spela in en resa.';

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
  String get situationColdStart => 'Kallstart';

  @override
  String get situationSustainedLoad => 'Ihållande belastning / bogserande';

  @override
  String get situationPartialDecel => 'Frihjuling';

  @override
  String get situationHardAccel => 'Hård acceleration';

  @override
  String get situationFuelCut => 'Bränslebrytare – frifart';

  @override
  String get tripSaveRecording => 'Spara resa';

  @override
  String get tripSummaryAutoSaved => 'Resan sparades automatiskt';

  @override
  String get tripSummaryDone => 'Klar';

  @override
  String get tripSummaryDelete => 'Ta bort den här resan';

  @override
  String get vehicleFuelNotSet => 'Ej inställt';

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
  String get vehiclePowerLabel => 'Motoreffekt (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps hk';
  }

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
  String get evStatusAvailable => 'Tillgänglig';

  @override
  String get evStatusOccupied => 'Upptagen';

  @override
  String get evStatusOutOfOrder => 'Ur funktion';

  @override
  String get evStatusPartial => 'Delvis tillgänglig';

  @override
  String get openOnlyFilter => 'Endast öppna';

  @override
  String get saveAsDefaults => 'Spara som mina standardinställningar';

  @override
  String get criteriaSavedToProfile => 'Sparat som standardinställningar';

  @override
  String get updatingFavorites => 'Uppdaterar dina favoriter...';

  @override
  String get fetchingLatestPrices => 'Hämtar de senaste priserna';

  @override
  String get noDataAvailable => 'Ingen data';

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
  String get sectionPrivacyData => 'Integritet och data';

  @override
  String get sectionAdvancedDeveloper => 'Avancerat och utvecklare';

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
  String get minimalDriveBehaviour => 'Körstil';

  @override
  String get coachingShiftUp => 'Växla upp';

  @override
  String get coachingShiftDown => 'Växla ned';

  @override
  String get coachingEasePedal => 'Släpp gasen';

  @override
  String get coachingVoiceHardAcceleration => 'Lugn med gaspedalen';

  @override
  String get coachingVoiceHarshBraking => 'Försök bromsa mjukare';

  @override
  String get coachingVoiceShiftUp => 'Växla upp för att spara bränsle';

  @override
  String get coachingVoiceShiftDown => 'Växla ner, motorn anstränger sig';

  @override
  String get coachingVoiceEasePedal =>
      'Lätta på pedalen för att minska bränsleförbrukningen';

  @override
  String get coachingVoiceLiftOff => 'Lyft foten från gaspedalen och frihjula';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Titta längre fram och lyft foten tidigare';

  @override
  String get coachingVoiceSmoothAccel => 'Accelerera mjukare';

  @override
  String get coachingVoiceSharpCorner => 'Ta kurvorna lite mjukare';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Det var en mycket hård inbromsning — håll längre avstånd';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Mycket hård acceleration — det drar rejält med bränsle';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Mycket skarp kurva — sakta in före, mjukt ut';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount häftiga manövrar.',
      one: 'En häftig manöver.',
      zero: 'Mjukt och fint — inga häftiga manövrar.',
    );
    return 'Resa sparad: $distanceKm kilometer, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value liter per 100 kilometer';
  }

  @override
  String get voiceCoachingSettingTitle => 'Talad körcoachning';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hör talade tips medan du kör — hård acceleration, hård bromsning och växlingstips';

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
  String get tankSyncSchemaOutdatedTitle => 'Molndatabasen behöver uppdateras';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Ditt självhostade TankSync-schema är föråldrat — vissa data kan inte synkas. Öppna synkguiden och kör uppdaterings-SQL:en på ditt Supabase-projekt.';

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
  String get syncSchemaOutdated =>
      'Ditt TankSync-schema är föråldrat — kör installations-SQL:en nedan igen för att aktivera de senaste synkfunktionerna.';

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
      'Delad databas som drivs av utvecklaren — se nedan vad som synkroniseras';

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
  String serviceReminderDueNowBody(String label) {
    return '$label ska göras nu.';
  }

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
  String get obd2GpsDegradedBannerTitle =>
      'Spelar in med GPS — OBD2 återansluter';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Registrerar med GPS — väntar på OBD2-adaptern';

  @override
  String get alertsStationSectionTitle => 'Stationsaviseringar';

  @override
  String get alertsStationAdd => 'Lägg till en stationsavisering';

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
  String radiusAlertDeleted(String name) {
    return 'Radiusavisering \"$name\" raderad';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 ansluten: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Para ihop en OBD2-adapter';

  @override
  String get fillUpSavedSnackbar => 'Tankning sparad';

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
  String get obd2ErrorEngineOff =>
      'Inga data från fordonet — starta motorn och försök igen.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2-adaptern skickade ett okänt svar. Den kan vara inkompatibel — prova en annan adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2-adaptern kopplades från. Anslut igen och försök igen.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adaptern behöver Bluetooth-parkoppling. Dra ur adaptern, sätt i den igen och försök på nytt inom 5 minuter.';

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
  String alertsLastChecked(String when) {
    return 'Senast kontrollerat: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Priserna har inte kontrollerats i bakgrunden ännu';

  @override
  String get alertsIosBestEffortNote =>
      'På iPhone sker aviseringskontroller efter bästa förmåga: iOS avgör när appen får kontrollera priser i bakgrunden, så en avisering kan komma sent eller ibland inte alls. Att öppna appen kör alltid en ny kontroll.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Målpris ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Tröskel ($currency/L)';
  }

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
  String fuelStationRadarProximity(int percent) {
    return 'Närhet $percent%';
  }

  @override
  String get pipTapToRestore => 'Tryck för att öppna hela appen';

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
  String get authLinkEmailTitle => 'Koppla en e-postadress';

  @override
  String get authLinkEmailSubtitle =>
      'Koppla en e-postadress så synkas dina data mellan enheter. Dina nuvarande favoriter och resor stannar på det här kontot.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Du använder ett gästkonto ($idPrefix…). Koppla en e-postadress så synkas dina favoriter och resor till dina andra enheter.';
  }

  @override
  String get authConfirmationPending =>
      'Nästan klart — kolla din e-post och klicka på länken för att slutföra kopplingen. Dina data är redan sparade på det här kontot.';

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
  String get aclWakeNotificationTitle => 'Bilen är ansluten';

  @override
  String get aclWakeNotificationBody =>
      'Tryck för att öppna Sparkilo — resregistreringen kan starta.';

  @override
  String get exportBackupReady => 'Säkerhetskopia klar – välj ett mål';

  @override
  String get exportBackupFailed =>
      'Export av säkerhetskopia misslyckades – försök igen';

  @override
  String get backupExportProgress => 'Exporterar din säkerhetskopia…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Sparad i Hämtningar som $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Återställ säkerhetskopia';

  @override
  String get restoreBackupDialogBody =>
      'Sammanfoga lägger till och uppdaterar poster från säkerhetskopian och behåller allt som redan finns på enheten. Ersätt raderar all nuvarande data först och återställer sedan bara säkerhetskopian — detta kan inte ångras.';

  @override
  String get restoreBackupMergeAction => 'Sammanfoga';

  @override
  String get restoreBackupReplaceAction => 'Ersätt allt';

  @override
  String get restoreBackupEmpty =>
      'Säkerhetskopia återställd — den innehöll inga poster';

  @override
  String get restoreBackupCorrupt =>
      'Återställning misslyckades — den här filen är inte en giltig Tankstellen-säkerhetskopia';

  @override
  String get restoreBackupFailed =>
      'Återställning misslyckades — filen kunde inte läsas';

  @override
  String get backupImportProgress => 'Återställer din säkerhetskopia…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Sammanfogade $vehicles fordon, $fillUps tankningar, $trips resor, $chargingLogs laddningsloggar';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Ersatte all data med $vehicles fordon, $fillUps tankningar, $trips resor, $chargingLogs laddningsloggar';
  }

  @override
  String get brokenMapChipDisclaimer => 'MAP-avläsningar misstänkta';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-sensor läser felaktigt – bränslevisningar kan vara 50–80 % för låga. Prova en annan adapter.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-sensor otillförlitlig. Visar tankningssnitt istället för direktbränsleflöde.';

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
  String get calibrationDirectFuelRateNote =>
      'Det här fordonet rapporterar sin bränsleförbrukning direkt (PID 5E), så kalibrering av volymetrisk verkningsgrad används inte — din förbrukning mäts, den modelleras inte.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Din $makeModel är markerad som diesel men matchar en bensinpost i katalogen. Tryck för att uppdatera.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Uppdatera';

  @override
  String get catalogResetAction => 'Återställ från fordonsdatabasen';

  @override
  String get catalogResetConfirmTitle => 'Återställa från fordonsdatabasen?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Detta ersätter tankvolym, motoreffekt och slagvolym för fordonet med databasens värden för $vehicle. Övriga fält och din tankningshistorik påverkas inte.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'Ingen matchande post i fordonsdatabasen för det här fordonet.';

  @override
  String get catalogResetDoneSnackbar =>
      'Fordonsdata återställda från databasen.';

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
  String get confirmDeleteTitle => 'Ta bort?';

  @override
  String get confirmDeleteBody => 'Vill du verkligen ta bort det här?';

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
  String get consoGroupVehicles => 'Fordon';

  @override
  String get consoGroupCoaching => 'Körcoachning';

  @override
  String get consoGroupRewards => 'Belöningar och besparingar';

  @override
  String get consoGroupTroubleshooting => 'Felsökning';

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
  String get moreActionsTooltip => 'Mer';

  @override
  String get exportBackupMenuLabel => 'Exportera säkerhetskopia';

  @override
  String get restoreBackupMenuLabel => 'Återställ säkerhetskopia';

  @override
  String get carbonDashboardMenuLabel => 'Koldioxidöversikt';

  @override
  String get settingsMenuLabel => 'Inställningar';

  @override
  String get consumptionStatsPageTitle => 'Förbrukningsstatistik';

  @override
  String get consumptionStatsComparisonTitle => 'Denna månad vs förra månaden';

  @override
  String get consumptionStatsTrendsTitle => 'Utveckling över tid';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Logga tankningar under minst två månader för att jämföra.';

  @override
  String get consumptionStatsPricePerLiter => 'Snittpris/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Liter per månad';

  @override
  String get consumptionStatsChartSpend => 'Utgifter per månad';

  @override
  String get consumptionStatsChartPricePerLiter => 'Pris per liter';

  @override
  String get consumptionStatsChartConsumption => 'L/100km per månad';

  @override
  String get fuelCompareSectionTitle => 'Körkostnad, bränsle för bränsle';

  @override
  String get fuelComparePricePerLitre => 'Betalt per liter';

  @override
  String get fuelCompareCostPer100km => 'Kostnad per 100 km';

  @override
  String get fuelCompareDistance => 'Uppmätt sträcka';

  @override
  String get fuelCompareLitres => 'Förbrukade liter';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner är ditt billigaste bränsle att köra på';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser kostar $amount mer per 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel slår $rival under $price per liter';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Brytpunkten räknas fram från varje bränsles uppmätta förbrukning och flyttar sig därför med din körning.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Liter och kostnad kan peka åt olika håll: ett bränsle kan dra färre liter per 100 km och ändå kosta mer per kilometer, eftersom literpriset skiljer sig. Det är kostnaden per kilometer som avgör.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fulla tankar',
      one: 'en full tank',
    );
    return 'Preliminärt — baserat på $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fulla tankar',
      one: 'en full tank',
    );
    return 'Baserat på $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 per 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner är ditt bränsle med lägst utsläpp';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel kostar $money mer per 1000 km men släpper ut $co2 mindre CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel är både billigare och renare än $rival';
  }

  @override
  String fuelCompareCo2Avoided(
    String distance,
    String fuel,
    String actual,
    String alternative,
    String rival,
    String saved,
  ) {
    return 'Dina $distance på $fuel släppte ut $actual i stället för $alternative på $rival — $saved undvikna';
  }

  @override
  String get fuelCompareCo2Source =>
      'CO2-siffrorna är well-to-wheel-uppskattningar (EU JEC WTW v5) tillämpade på din uppmätta förbrukning — för överblick, inte som certifierad redovisning.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 visas bara för rena bränslen: en blandnings emissionsfaktor beror på blandningen, som den här raden inte registrerar.';

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
    return 'Korrigeringar: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Anmäl innehåll';

  @override
  String get contentModerationBlockAction => 'Blockera upphovsperson';

  @override
  String get contentModerationReportDialogTitle => 'Anmäla det här innehållet?';

  @override
  String get contentModerationReportDialogBody =>
      'En anmälan skickas till din TankSync-server för granskning, och innehållet döljs på din enhet.';

  @override
  String get contentModerationReportConfirmButton => 'Anmäl';

  @override
  String get contentModerationBlockDialogTitle =>
      'Blockera den här upphovspersonen?';

  @override
  String get contentModerationBlockDialogBody =>
      'Allt som det här kontot delar med dig döljs på den här enheten.';

  @override
  String get contentModerationBlockConfirmButton => 'Blockera';

  @override
  String get contentModerationReportedSnack =>
      'Anmälan skickad — innehållet är dolt.';

  @override
  String get contentModerationReportFailedSnack =>
      'Anmälan kunde inte skickas. Försök igen.';

  @override
  String get contentModerationBlockedSnack =>
      'Upphovsperson blockerad — delat innehåll är dolt.';

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
  String crossBorderCheaper(String country, String km, String price) {
    return '$country-stationer $km km bort – €$price/L billigare';
  }

  @override
  String get crossBorderTapToSwitch => 'Tryck för att byta land';

  @override
  String get crossBorderDismissTooltip => 'Avfärda';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Öppna datakällan $source ($license) i din webbläsare';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Utvecklarverktyg';

  @override
  String get dataAccessTracerExport => 'Exportera dataåtkomstlogg';

  @override
  String get dataAccessTracerExportSuccess =>
      'Dataåtkomstloggen sparades i Hämtade filer.';

  @override
  String get dataAccessTracerExportFailure =>
      'Dataåtkomstloggen kunde inte exporteras.';

  @override
  String get dataAccessTracerEmpty =>
      'Inga dataåtkomsthändelser registrerade ännu — sök eller öppna stationer först, exportera sedan.';

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
      'Sök efter stationer först, kör sedan testalerten så att notisen kan öppna en riktig station.';

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
  String get startupTraceSectionTitle => 'Initieringslogg vid start';

  @override
  String get startupTraceExportButton => 'Exportera startlogg';

  @override
  String get startupTraceEmpty => 'Ingen startlogg registrerad ännu.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Totalt: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Startloggen sparades i Hämtade filer.';

  @override
  String get startupTraceExportFailure => 'Startloggen kunde inte exporteras.';

  @override
  String get distanceSourceOdometer => 'Vägmätare';

  @override
  String get distanceSourceOdometerTooltip =>
      'Sträcka avläst från bilens vägmätare — ett uppmätt referensvärde.';

  @override
  String get distanceSourceGps => 'GPS-spår';

  @override
  String get distanceSourceGpsTooltip =>
      'Sträcka summerad från det registrerade GPS-spåret — den verkliga vägsträckan.';

  @override
  String get distanceSourceEstimated => 'Uppskattad';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Sträcka integrerad från hastighetssensorn — en uppskattning; sensorn visar vanligen något för mycket.';

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
    return 'Fullt gas ($pctTime% av resan): slösade $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Tryck varsamt på pedalen — ett mjukare tryck på 70 % av gasen tar dig upp i fart med mycket mindre bränsle.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Fet blandning under belastning ($pctTime% av resan): slösade $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Tung, ihållande belastning gör att motorn kör med fet blandning — korta upp och dra av vid långa uppförsbackar för att hålla blandningen mager.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Klättring i $gradePercent% stigning ($pctTime% av resan): slösade $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Ta med fart in i en backe och tryck varsamt på gasen — att rusa i en uppförsbacke bränner extra bränsle.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stopp-och-körningar: slösade $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Förutse trafiken och frihjula mot stoppen så att du rullar istället för att starta om — att köra iväg från stillastående är den mest bränsletörstiga delen av stopp-och-körning.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Blandningen verkar lite mager — motorn tillförde bränsle ($pctTrim % korrigering) för att kompensera';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Blandningen verkar mager — motorn höll ett stort bränsletillskott på $pctTrim %, en möjlig ineffektivitet';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Blandningen verkar lite fet — motorn drog bort bränsle ($pctTrim % korrigering) för att kompensera';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Blandningen verkar fet — motorn höll en stor bränsleminskning på $pctTrim %, en möjlig ineffektivitet';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Motorn gick fett under belastning ($pctShare % av den varma körningen) — möjligt bränsleslöseri';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristisk hälsosignal, ingen diagnos';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'En ihållande korrigering mot mager blandning kan tyda på ett luftläckage i insuget, svag bränsletillförsel eller en åldrad sensor. Om förbrukningen eller gången försämras kan en verkstadsdiagnos bekräfta det.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'En ihållande korrigering mot fet blandning kan tyda på en läckande insprutare, för högt bränsletryck eller en sensor som visar för mycket. Om förbrukningen eller gången försämras kan en verkstadsdiagnos bekräfta det.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Fet blandning under hög belastning bränner extra bränsle. Växla upp tidigt och lätta på gasen vid långa accelerationer så att motorn kan hålla sig nära en stökiometrisk blandning.';

  @override
  String get lessonTransportTitle =>
      'Motordata saknas för större delen av resan';

  @override
  String get lessonTransportAdvice =>
      'Motorn rapporterade ingen aktivitet under nästan hela sträckan. Antingen bröts OBD2-strömmen mitt i resan eller så flyttades bilen utan att köras — förbrukningssiffran är opålitlig och utesluts ur din statistik.';

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
  String get drivingScoreClassVeryGood => 'Mycket bra';

  @override
  String get drivingScoreClassGood => 'Bra';

  @override
  String get drivingScoreClassAverage => 'Genomsnittlig';

  @override
  String get drivingScoreClassBad => 'Behöver förbättras';

  @override
  String get drivingScorePenaltyLugging => 'Motorstressning';

  @override
  String get drivingScorePenaltySmoothness => 'Ryckig körning';

  @override
  String get drivingScorePenaltyHighSpeed => 'Hög hastighet';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Aggressiv gaspedal';

  @override
  String get drivingScorePenaltyLambda => 'Fet blandning';

  @override
  String get gpsKpiCardTitle => 'GPS-effektivitet';

  @override
  String get gpsKpiRpa => 'Positiv acceleration (RPA)';

  @override
  String get gpsKpiPke => 'Kinetisk energiefterfrågan (PKE)';

  @override
  String get gpsKpiVapos => 'Accelerationsintensitet (VAPOS)';

  @override
  String get gpsKpiCoast => 'Frihjulingsandel';

  @override
  String get gpsKpiClimbEnergy => 'Klättringsenergi';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct jämfört med ditt effektiva basvärde';
  }

  @override
  String get drivingTraceCardTitle => 'Köranalys-spårning (dev)';

  @override
  String get drivingTraceCardBody =>
      'Exportera den här resans GPS-KPI:er, poäng och lärdomar som JSON, skriv hur körningen faktiskt kändes i kommentarsfältet och dela tillbaka det så att tröskelvärdena för körstil kan kalibreras mot riktiga resor.';

  @override
  String get drivingTraceExportAction => 'Exportera analysspårning';

  @override
  String get drivingTraceExported =>
      'Analysspårning sparad i Hämtningar — lägg till ditt omdöme i kommentarsfältet och dela tillbaka det.';

  @override
  String get drivingTraceExportFailed =>
      'Kunde inte exportera analysspårningen.';

  @override
  String get minimalDriveTripAverage => 'Resegenomsnitt';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Jämn fart på högt varvtal ($pctTime % av resan): att växla upp tidigare kunde spara $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Växla upp tidigare vid jämn fart — samma hastighet på lägre varvtal drar märkbart mindre bränsle.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Rullning med bränsleavstängning ($pctTime % av resan): sparade cirka $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Bra förutseende — att släppa gasen tidigt låter motorn stänga av bränslet helt under rullningen.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Vart ditt bränsle tog vägen';

  @override
  String get fuelBreakdownIdle => 'Tomgång';

  @override
  String get fuelBreakdownHarshAccel => 'Hårda accelerationer';

  @override
  String get fuelBreakdownHighRpmCruise => 'Jämn fart på högt varvtal';

  @override
  String get fuelBreakdownCoastingSaved => 'Sparat genom rullning';

  @override
  String get fuelBreakdownEfficient => 'Normal körning';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Tomgång en stund nu — att stänga av motorn sparar bränsle';

  @override
  String get ecoNudgeHarshAccel =>
      'Kraftig acceleration — en mjukare gasfot sparar bränsle';

  @override
  String get ecoNudgeHighRpm =>
      'Högt varvtal vid jämn fart — att växla upp tidigare sparar bränsle';

  @override
  String get obd2CoverageNoneNote =>
      'Inga motordata kom från OBD2-adaptern under resan — bränslesiffrorna är GPS-baserade uppskattningar.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Motordata upphörde $percent % in i resan (anslutningen bröts) — bränslesiffrorna därefter är GPS-baserade uppskattningar.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Motordata täckte bara $percent % av resan — luckorna använder GPS-baserade uppskattningar.';
  }

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
  String get featureLabel_approachOverlay => 'Bensinmack-radar';

  @override
  String get featureDescription_approachOverlay =>
      'Förvandlar den flytande resepanelen till en live-bensinmack-radar — när du närmar dig en bensinstation byter den färg till bränsletypens färg och visar priset.';

  @override
  String get featureLabel_voiceAnnouncements => 'Röstmeddelanden';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Tala om billiga bensinstationer i närheten när du kör, så att du kan hålla blicken på vägen.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Aktivera bensinmack-radarn först';

  @override
  String get featureGroupTitle_finding => 'Hitta och karta';

  @override
  String get featureGroupDescription_finding =>
      'Var man tankar eller laddar — sökning, karta, ruttplanering.';

  @override
  String get featureGroupTitle_prices => 'Priser och aviseringar';

  @override
  String get featureGroupDescription_prices =>
      'Prissänkningar, historik och rapportering.';

  @override
  String get featureGroupTitle_radar => 'Bensinmack-radar';

  @override
  String get featureGroupDescription_radar => 'Live-prisnudgar när du kör.';

  @override
  String get featureGroupTitle_sync => 'Synkronisering och säkerhetskopiering';

  @override
  String get featureGroupDescription_sync => 'Håll din data på alla enheter.';

  @override
  String get featureGroupTitle_input => 'Inmatning och skanning';

  @override
  String get featureGroupDescription_input =>
      'Hjälpmedel för att logga tankningar.';

  @override
  String get featureGroupTitle_developer => 'Utvecklare och experimentellt';

  @override
  String get featureGroupDescription_developer =>
      'Verktyg för avancerade användare och bidragsgivare.';

  @override
  String get featureLabel_voiceFeedback => 'Talad återkoppling (talsyntes)';

  @override
  String get featureDescription_voiceFeedback =>
      'Huvudbrytare för allt talat — körcoachen och stationsmeddelandena. Avstängd öppnar appen aldrig någon talsyntesmotor.';

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
  String get fillUpMultiFuelHint =>
      'Fordonet kan köras på olika bränslen — registrera det du faktiskt tankade';

  @override
  String get fillUpGuidanceTitle => 'Bästa tid att tanka';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Nuvarande pris tillhör de billigaste de senaste $days dagarna — ett bra tillfälle att tanka.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Priserna ligger nära sitt $days-dagarsmaximum. De brukar vara billigare $window — överväg att vänta.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Priserna stiger — överväg att tanka snart.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Dagens pris ligger runt $days-dagarssnittet.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Kan spara ungefär $amount/L genom att tajma tankningen.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Baserat på $count prisavläsningar',
      one: 'Baserat på 1 prisavläsning',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'på $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'på $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'vid andra tider';

  @override
  String get fillUpGuidanceWeekday1 => 'Måndagar';

  @override
  String get fillUpGuidanceWeekday2 => 'Tisdagar';

  @override
  String get fillUpGuidanceWeekday3 => 'Onsdagar';

  @override
  String get fillUpGuidanceWeekday4 => 'Torsdagar';

  @override
  String get fillUpGuidanceWeekday5 => 'Fredagar';

  @override
  String get fillUpGuidanceWeekday6 => 'Lördagar';

  @override
  String get fillUpGuidanceWeekday7 => 'Söndagar';

  @override
  String get fillUpGuidancePartEarlyMorning => 'tidigt på morgonen';

  @override
  String get fillUpGuidancePartMorning => 'på morgnarna';

  @override
  String get fillUpGuidancePartAfternoon => 'på eftermiddagarna';

  @override
  String get fillUpGuidancePartEvening => 'på kvällarna';

  @override
  String get fillUpGuidancePartNight => 'på nätterna';

  @override
  String get fillUpOdometerFromCarJustNow => 'Från din bil · nyss';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Från din bil · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Uppskattat från bilens senaste avläsning plus sträckan som körts sedan dess ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Klistra in text';

  @override
  String get pasteReceiptDialogTitle => 'Klistra in kvittotext';

  @override
  String get pasteReceiptDialogHint =>
      'Klistra in texten från ett bränslekvitto — e-post, sms eller en delad PDF. Liter, literpris, bränsletyp, totalsumma och station läses på enheten och fyller i formuläret i förväg. Inget skickas till någon server.';

  @override
  String get pasteReceiptFieldHint => 'Kvittotext';

  @override
  String get pasteReceiptParseAction => 'Fyll i';

  @override
  String get pasteReceiptNoData =>
      'Inga bränsleuppgifter kunde läsas ur texten — kontrollera att det är ett bränslekvitto och försök igen.';

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
  String get badScanReportTitleReceipt =>
      'Rapportera ett skanningsfel – Kvitto';

  @override
  String get badScanReportHint =>
      'Vi delar kvittofotot och båda uppsättningarna av värden så att nästa version kan lära sig den här layouten.';

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
  String get fillUpWarningDialogTitle => 'Kontrollera den här tankningen';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Du valde $chosenFuel, men fordonet körs på $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Mätarställningen $entered km är lägre än förra tankningens $previous km — sträckan kan inte gå bakåt.';
  }

  @override
  String get fillUpWarningGoBack => 'Gå tillbaka och rätta';

  @override
  String get fillUpWarningSaveAnyway => 'Spara ändå';

  @override
  String get fillUpSectionWhatTitle => 'Vad du tankade';

  @override
  String get fillUpSectionWhatSubtitle => 'Bränsle, mängd, pris';

  @override
  String get fillUpSectionWhereTitle => 'Var du var';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, vägmätare, anteckningar';

  @override
  String get fillUpImportReceiptLabel => 'Kvitto';

  @override
  String get fillUpPricePerLiterLabel => 'Pris per liter';

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
  String get profileSectionDisplayStations => 'Visning och stationer';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get fuelEfficiencyCardTitle => 'Kostnad per kilometer per bränsle';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Vilken bränsleblandning som faktiskt är billigast att köra på';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Billigast per km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Ren';

  @override
  String get fuelEfficiencyMixBadge => 'Blandning';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Mest $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Kostnad/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Totalt spenderat';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tankningar',
      one: '1 tankning',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fulla tankar',
      one: '1 full tank',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Registrera minst två fulla tankar per sammansättning för att utse den billigaste.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Tankar grupperas efter sammansättning: en tank är ren när ett bränsle utgör minst 85 % av den, annars en blandning.';

  @override
  String get fuelNameE5 => 'Bensin 95';

  @override
  String get fuelNameE10 => 'Bensin 95 E10';

  @override
  String get fuelNameE98 => 'Bensin 98';

  @override
  String get fuelNameDiesel => 'Diesel';

  @override
  String get fuelNameDieselPremium => 'Diesel Premium';

  @override
  String get fuelNameE85 => 'Etanol E85';

  @override
  String get fuelNameLpg => 'Gasol (LPG)';

  @override
  String get fuelNameCng => 'Fordonsgas (CNG)';

  @override
  String get fuelNameHydrogen => 'Vätgas';

  @override
  String get fuelNameElectric => 'El';

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
  String gdprPolicyLink(int version) {
    return 'Integritetspolicy (version $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Samtycke lämnat $date · policyversion $version';
  }

  @override
  String get consentNotRecorded => 'Inget samtycke registrerat ännu';

  @override
  String serverErasurePartial(String tables) {
    return 'Vissa serverdata kunde inte raderas: $tables. Försök igen eller kontakta utvecklaren med den här listan.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Vissa lokala data kunde inte raderas: $steps. Starta om appen och försök igen.';
  }

  @override
  String get myCommunityReportsTitle => 'Mina communityrapporter';

  @override
  String get myCommunityReportsEmpty =>
      'Du har inte skickat in några rapporter';

  @override
  String get deleteReportTooltip => 'Radera den här rapporten';

  @override
  String get reportDeleted => 'Rapport raderad';

  @override
  String get reportDeleteFailed => 'Det gick inte att radera rapporten';

  @override
  String get tileProxyToggleTitle => 'Hämta kartrutor via Sparkilo-proxyn';

  @override
  String get tileProxyToggleSubtitle =>
      'På: det visade kartutsnittet och din IP-adress når utvecklarens EU-server, som hämtar rutorna från OpenStreetMap. Av: rutorna hämtas direkt från tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle =>
      'Hämta varumärkeslogotyper från internet';

  @override
  String get remoteLogosToggleSubtitle =>
      'Av som standard: medföljande platshållare visas. På: logotyper hämtas från logo.clearbit.com, som ser din IP-adress.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName sparad i Hämtningar — $count filer inuti';
  }

  @override
  String get privacyExportAllFailed => 'Det gick inte att skriva exportfilen';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Drivs av $operator · Supabase, EU (Frankfurt) · synkroniserar favoriter, aviseringar, fordon inkl. VIN, tankningar, betyg, rapporter och — om du aktiverar det — resor med GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Du är personuppgiftsansvarig — ditt eget Supabase-projekt, vi ser det aldrig';

  @override
  String get syncModeJoinControllerNotice =>
      'Den som äger den delade databasen är personuppgiftsansvarig för dina data';

  @override
  String get ugcPublicNoticeTitle => 'Delas med andra användare';

  @override
  String get ugcPublicNoticeBody =>
      'Detta lagras i synkroniseringsdatabasen under ditt pseudonyma användar-ID. I Sparkilo Community kan alla inloggade användare läsa det. Du kan när som helst radera det under TankSync → Datatransparens.';

  @override
  String get blockedAuthorsTitle => 'Blockerade användare';

  @override
  String get blockedAuthorsDescription =>
      'Innehåll som delas av dessa användare döljs på den här enheten. Avblockera för att se det igen.';

  @override
  String get blockedAuthorsEmpty => 'Inga blockerade användare';

  @override
  String get blockedAuthorsUnblock => 'Avblockera';

  @override
  String get coachingGpsLiftOff => 'Släpp gasen';

  @override
  String get coachingGpsAnticipateBrake => 'Förutse';

  @override
  String get coachingGpsSmoothAccel => 'Mjuk acceleration';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Spåret täcker $pct % — längsta lucka $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Spåret täcker $pct % — inga luckor hittades';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'appen i bakgrunden';

  @override
  String get gpsCoverageAttrOsBatching => 'systemet buntade positioner';

  @override
  String get gpsCoverageAttrGateRejected => 'positioner filtrerade';

  @override
  String get gpsCoverageAttrDeliveryStall => 'fördröjd leverans';

  @override
  String get gpsCoverageAttrSignalLoss => 'signalbortfall';

  @override
  String get gpsCoverageAttrUnknown => 'okänd orsak';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Appen låg i bakgrunden utan förgrundstjänst, så systemet stryptes GPS:en. Håll skärmen tänd under registreringen, eller slå på bakgrundsregistrering när det finns.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Systemet levererade positionerna sent och i buntar; spåret fylldes i efteråt, så lite data gick faktiskt förlorad.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Brusiga positioner på den här sträckan filtrerades bort för att hålla sträckan ärlig.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Positionerna togs fram i tid men nådde appen sent — telefonen var upptagen (ofta en Bluetooth-återanslutning). Mottagningen var bra.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'GPS-mottagningen försvann — oftast en tunnel, ett parkeringsgarage eller tät stadsbebyggelse.';

  @override
  String get gpsCoverageHintUnknown =>
      'Resan saknar information om appens tillstånd under luckan, så orsaken kan inte avgöras.';

  @override
  String get gpsCoverageAttrLinkRecovery => 'störning från OBD2-återanslutning';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Luckan sammanfaller med en OBD2-återanslutning — adapterlänken höll på att återhämta sig medan GPS-intaget stannade. Löser du adapteranslutningen löser du också spåret.';

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
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Största lucka: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Återupptagen';

  @override
  String get gpsLifecyclePaused => 'Pausad';

  @override
  String get gpsLifecycleInactive => 'Inaktiv';

  @override
  String get gpsKpiVerdictGood => 'Effektiv';

  @override
  String get gpsKpiVerdictModerate => 'Måttlig';

  @override
  String get gpsKpiVerdictAggressive => 'Aggressiv';

  @override
  String get gpsKpiInterpretationGood =>
      'Mjuk, energisnål körning — så här ser effektivitet ut.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Ganska typisk körning — lite mjukare på gasen skulle spara mer.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energikrävande körning — att släppa gasen och rulla mer skulle sänka bränsleförbrukningen.';

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
      'GPS-uppskattning (~) — ingen bränslesensor på denna resa. Värdet modelleras utifrån hastighet och ditt fordons kalibrering; noggrannheten förbättras allteftersom matrisen mognar.';

  @override
  String get gpsRoadUseCardTitle => 'Så använde du vägen';

  @override
  String get gpsRoadUseSpeedSection => 'Var du tillbringade tiden';

  @override
  String get gpsRoadUseSpeedIdle => 'Stillastående (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Tätort (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Landsväg (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Snabbt (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Hur du rörde dig';

  @override
  String get gpsRoadUsePhaseAccel => 'Accelererar';

  @override
  String get gpsRoadUsePhaseSteady => 'Jämn fart';

  @override
  String get gpsRoadUsePhaseCoast => 'Rullar';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Mycket rullning — att låta bilen rulla i stället för att bromsa sparar bränsle. Snyggt.';

  @override
  String get gpsRoadUseSource => 'Från ditt GPS-spår';

  @override
  String get hapticEcoCoachSettingTitle => 'Realtids-ecocoachning';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Mjuk haptik + on-screen-tips när du gäspar under krysshastighet';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Varsamt med gasen – frihjul sparar mer';

  @override
  String highwayViaExit(String ref, String km) {
    return 'via avfart $ref · +$km km';
  }

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
  String get consentSyncTripsAnonymousHint =>
      'Resor säkerhetskopieras under enhetens anonyma konto. Logga in med en e-postadress för att nå dem från andra enheter.';

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
  String get accelBrakeCardTitle => 'Acceleration och bromsning';

  @override
  String get accelBrakeHardAccel => 'Hård acceleration';

  @override
  String get accelBrakeHardBrake => 'Hård bromsning';

  @override
  String get accelBrakeSharpCorner => 'Skarpa kurvor';

  @override
  String get accelBrakeSource => 'Från telefonens rörelsesensorer';

  @override
  String lessonHardBrake(String count) {
    return '$count hårda bromshändelser';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Förutse stopp och lyft foten från gaspedalen tidigare — hård bromsning kastar bort det bränsle du just spenderade på att komma upp i fart.';

  @override
  String lessonSharpCornering(String count) {
    return '$count skarpa kurvor';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Sakta ner före kurvan, inte i den — hård kurvtagning skrapar av fart som du sedan måste bygga upp igen.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Senaste $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Förbrukningsenhet';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Så visas bränsleförbrukningen överallt i appen';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automatisk ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Fönster för liveförbrukning';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Medelvärde av livevärdet över de senaste sekunderna – längre är lugnare, kortare reagerar snabbare';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'uppsk. $unit';
  }

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
  String get consumptionMonthlyClimbLabel => 'Klättrat';

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
  String get obd2DiagnosticsTitle => 'OBD2-kommunikationshälsa';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops avbrott',
      one: '1 avbrott',
      zero: 'inga avbrott',
    );
    return '$percent% färdig · $duty% aktiv · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Anslutningslivscykel';

  @override
  String get obd2DiagnosticsPidSection => 'Utfall per PID';

  @override
  String get obd2DiagnosticsReconnectSection => 'Återanslutningstelemetri';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts återanslutningsförsök · $successes lyckade · $transitions övergångar · $disconnects typade avbrott';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'Reservläge med enbart GPS aktiverades under sessionen.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Schemaläggarhälsa';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Fullständighet';

  @override
  String get obd2DiagnosticsSupportSection => 'Upptäckta stödda PID:ar';

  @override
  String get obd2DiagnosticsFuelSection => 'Bränslenivåöversikt';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protokoll $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts försök · $successes ok · $drops avbrott · tid-till-anslutning p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Återanslutningar: $silent tysta · $visible synliga';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips bakåttryckshoppningar · $demotions degraderingar';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dynamiksnivån utsvulten — RPM/hastighet sjönk under regleratorsgolvet.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Totalt $percent% · aktiv tjänstgöring $duty%';
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
    return '$supported stödda · $unsupported ej stödda · $unknown okända';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Misstänkta $suspicious av $total prover';
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
    return '$pid: $polled pollad · $ok ok · $noData ND · $timeout TO · $error fel · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Dongel-initieringsutskrift';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokoll $protocol · $start · firmware $firmware · $tier · $pids PID:ar';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'varm';

  @override
  String get obd2DiagnosticsInitCold => 'kall';

  @override
  String get obd2DiagnosticsEmpty =>
      'Ingen OBD2-session inspelad ännu — anslut en adapter och spela in en resa med Utvecklarläge aktivt.';

  @override
  String get obd2DiagnosticsExplain =>
      'Insamlat under inspelning för att felsöka dongel↔app-kommunikationen — samlas bara in i Utvecklarläge.';

  @override
  String get obd2HealthScreenTitle => 'OBD2-kommunikationshälsa';

  @override
  String get obd2HealthNavLabel => 'OBD2-kommunikationshälsa';

  @override
  String get obd2HealthLiveSection => 'Live-session';

  @override
  String get obd2HealthHistorySection => 'Senaste sessioner';

  @override
  String get obd2HealthDownloadJson => 'Hämta som JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Hämta endast initieringsutskriften';

  @override
  String get obd2HealthDownloadError => 'Diagnostikfilen kunde inte sparas';

  @override
  String get obd2TestAdapterLabel => 'Adapter att testa';

  @override
  String get obd2TestAdapterScanOption => 'Sök efter adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Ansluter till $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Kör adaptertest';

  @override
  String get obd2TestRunButton => 'Kör adaptertest';

  @override
  String get obd2TestRunPassed => 'Adaptertest godkänt';

  @override
  String get obd2TestRunFailed => 'Adaptertest misslyckades';

  @override
  String get obd2TestRunEngineOff =>
      'Adaptern OK — motorn av; starta motorn för att läsa livedata';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed av $total steg OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Stoppa aktiv inspelning innan du kör adaptertestet.';

  @override
  String get obd2TestStepScan => 'Sök efter adapter';

  @override
  String get obd2TestStepBluetooth => 'Telefonens Bluetooth';

  @override
  String get obd2TestStepConnect => 'Anslut och initiera';

  @override
  String get obd2TestStepInfo => 'Adapterinfo';

  @override
  String get obd2TestStepSupportedPids => 'Stödda PID:ar';

  @override
  String get obd2TestStepProtocol => 'Fordonsprotokoll';

  @override
  String get obd2TestStepSampleReads => 'Provavläsningar';

  @override
  String get obd2TestStepSoak => 'Långvarig avläsning';

  @override
  String get obd2TestStepReconnect => 'Återanslutningstest';

  @override
  String get obd2TestStepDisconnect => 'Koppla från';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Timeout';

  @override
  String get obd2TestStatusGarbage => 'Oläsbart svar';

  @override
  String get obd2TestStatusNoResponse => 'Inget svar';

  @override
  String get obd2TestStatusFail => 'Misslyckades';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'okänd — BLE som standard';

  @override
  String get obd2HealthConnectAttemptsSection => 'Senaste anslutningsförsök';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Inga anslutningsförsök registrerade ännu.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Hämta anslutningslogg';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Hämta alla anslutningsloggar';

  @override
  String get obd2HealthConnectOrigin => 'Ursprung';

  @override
  String get obd2HealthConnectTransport => 'Transport';

  @override
  String get obd2HealthConnectOutcome => 'Utfall';

  @override
  String get obd2HealthConnectScanList => 'Hittade enheter';

  @override
  String get obd2HealthConnectSteps => 'Steg';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Okänd adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Session inspelad · $samples motormätningar · $percent % täckning';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection =>
      'Vad den här resan spelade in';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples av $total mätningar innehöll motordata ($percent %)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Protokollhandskakning: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Sessionen avslutades: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Sessionens längd: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Förbrukningssiffrorna kommer från adaptern, inte från GPS-uppskattningar.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Kommunikationsdetaljerna per PID fångades inte för den här resan. Slå på utvecklarläget före inspelning för att samla in dem.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Kunde inte nå \'$adapterName\' – välj en annan adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Andra Bluetooth-enheter';

  @override
  String get obd2PickerTapToTry => 'Okänd — tryck för att prova';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone fungerar bara med Bluetooth LE-adaptrar. En adapter med enbart Classic (t.ex. vLinker BM, Konnwei KW902) måste användas på Android.';

  @override
  String get obd2PairingConfirmHint =>
      'Bekräfta parkopplingsbegäran på telefonen';

  @override
  String get obd2ScanEmptyTitle => 'Ingen adapter hittades';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth är på och behörigheter är beviljade. Kontrollera att adaptern sitter i OBD2-uttaget och att tändningen är på, sök sedan igen.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Enheten saknar Bluetooth Low Energy-maskinvara och kan därför inte ansluta till en OBD2-adapter.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth är avstängt. Slå på det för att söka efter din adapter.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo behöver Bluetooth-behörighet för att hitta din adapter.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Bluetooth-behörigheten nekades permanent. Bevilja den i systeminställningarna för att söka efter din adapter.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Platstjänster är avstängda på enheten. Android kräver att de är på för att söka efter Bluetooth-adaptrar — ingen plats registreras eller delas.';

  @override
  String get obd2ScanOpenSettings => 'Öppna inställningar';

  @override
  String get obd2WaitingForEngineBanner =>
      'Väntar på motorn — registrerar med GPS';

  @override
  String get obd2StartEngineToReconnect => 'Starta motorn för att återansluta';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motorn är av — starta den för att återansluta';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motorn har varit av i $minutes min — stoppa registreringen?';
  }

  @override
  String get obd2ParkedPromptStop => 'Stoppa';

  @override
  String get obd2ParkedPromptKeep => 'Fortsätt';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motorn var av under de första $head och de sista $tail av resan — täckningen mäts medan motorn går.';
  }

  @override
  String get obd2ReconnectInProgress => 'Återansluter till din OBD2-adapter…';

  @override
  String get obd2StatusEngineOff => 'OBD2 pausad — motorn av';

  @override
  String get obd2StatusEngineOffBody =>
      'Adaptern gick att nå men fordonsbussen förblev tyst, så automatisk återanslutning är pausad. Den återupptas när du kör eller öppnar appen igen — eller återanslut nu.';

  @override
  String get obd2StatusReconnectNow => 'Återanslut nu';

  @override
  String get autoRecordNotificationTitle => 'Automatisk resregistrering';

  @override
  String get autoRecordNotificationText => 'Väntar på din OBD2-adapter';

  @override
  String get obd2ResetConnection => 'Återställ anslutningen';

  @override
  String get obd2ResetConnectionDone =>
      'Adaptern återställd — anslutningen är återupprättad';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adaptern återställd — återansluter i bakgrunden';

  @override
  String get ocrTesterTitle => 'OCR-testare';

  @override
  String get ocrTesterNavLabel => 'OCR-testare';

  @override
  String get ocrTesterExplain =>
      'Kör pump-/kvitto-OCR-pipelinen på ett valt foto och granska varje steg — endast tillgänglig i Utvecklarläge.';

  @override
  String get ocrTesterCapture => 'Ta bild';

  @override
  String get ocrTesterPickImage => 'Välj bild';

  @override
  String get ocrTesterRun => 'Kör';

  @override
  String get ocrTesterCountry => 'Land';

  @override
  String get ocrTesterCountryNone => 'Standard (ingen profil)';

  @override
  String get ocrTesterNoImage => 'Välj eller ta en bild, kör sedan.';

  @override
  String get ocrTesterRunning => 'Kör OCR…';

  @override
  String get ocrTesterOverlaySection => 'Blocköverlager';

  @override
  String get ocrTesterStepsSection => 'Pipelinesteg';

  @override
  String get ocrTesterLegendLabel => 'Etikett';

  @override
  String get ocrTesterLegendNumeric => 'Numerisk';

  @override
  String get ocrTesterLegendNoise => 'Brus';

  @override
  String get ocrTesterLegendDerived => 'Härledd';

  @override
  String get ocrTesterStageGlare => 'Fotografering / bländning';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klassificera';

  @override
  String get ocrTesterStageAssemble => 'Sammanfoga';

  @override
  String get ocrTesterStageAnchor => 'Ankarpunkt';

  @override
  String get ocrTesterStageFallback => 'Reservalternativ';

  @override
  String get ocrTesterStageCrossCheck => 'Korskontroll';

  @override
  String get ocrTesterStageConfidence => 'Konfidensgrad';

  @override
  String get ocrTesterStageGate => 'Grind';

  @override
  String get ocrTesterStageBrand => 'Varumärke';

  @override
  String get ocrTesterStageOverrides => 'Överskridanden';

  @override
  String get ocrTesterStageReconcile => 'Stämning';

  @override
  String get ocrTesterStageResult => 'Resultat';

  @override
  String get ocrTesterChipRead => 'LÄST';

  @override
  String get ocrTesterChipDerived => 'HÄRLEDD';

  @override
  String get ocrTesterGateAccepted => 'Godkänd';

  @override
  String get ocrTesterGateRejected => 'Avvisad';

  @override
  String get ocrTesterFallbackBanner =>
      'Ett fält återställdes via storleksreserv — kontrollera det.';

  @override
  String get ocrTesterStageNoData => 'Steget kördes inte.';

  @override
  String get ocrTesterCopyJson => 'Kopiera som JSON';

  @override
  String get ocrTesterExportPackage => 'Exportera paket';

  @override
  String get ocrTesterCopied => 'OCR-spårning kopierad till urklipp.';

  @override
  String get ocrTesterExported => 'OCR-paket sparat i Hämtningar.';

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
  String get onboardingObd2ConnectFailed =>
      'Kunde inte ansluta till adaptern. Du kan försöka igen eller hoppa över.';

  @override
  String get onboardingPickUseMode =>
      'Välj ett användningsläge för att fortsätta.';

  @override
  String get onboardingObd2LaterNote =>
      'Du kan parkoppla en Bluetooth-OBD2-adapter när som helst senare från fordonsskärmen för att registrera resor och läsa motordata.';

  @override
  String get openHoursUnknown => 'Okända öppettider';

  @override
  String get open24Hours => 'Öppen dygnet runt';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Måndag';

  @override
  String get dayTue => 'Tisdag';

  @override
  String get dayWed => 'Onsdag';

  @override
  String get dayThu => 'Torsdag';

  @override
  String get dayFri => 'Fredag';

  @override
  String get daySat => 'Lördag';

  @override
  String get daySun => 'Söndag';

  @override
  String get dayShortMon => 'Mån';

  @override
  String get dayShortTue => 'Tis';

  @override
  String get dayShortWed => 'Ons';

  @override
  String get dayShortThu => 'Tor';

  @override
  String get dayShortFri => 'Fre';

  @override
  String get dayShortSat => 'Lör';

  @override
  String get dayShortSun => 'Sön';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Helgdagar';

  @override
  String get closedLabel => 'Stängd';

  @override
  String get openingHoursNotAvailable => 'Öppettider ej tillgängliga';

  @override
  String get showAllHours => 'Visa alla öppettider';

  @override
  String get showLessHours => 'Visa mindre';

  @override
  String get openStateUnknown => 'Okänt';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stationen är öppen',
      'false': 'Stationen är stängd',
      'other': 'Öppetstatus okänd',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Kameraåtkomst';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Den här appen vill använda din kamera för att läsa kvitton, pumpdisplayer och QR-koder.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Vad som händer med kamerabilden:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'Bilden används bara för att läsa kvittot, pumpdisplayen eller QR-koden — igenkänningen körs på din enhet.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'Fotot kastas efter skanningen.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Inget laddas upp om du inte skickar en rapport om felaktig skanning och bekräftar den.';

  @override
  String get permissionRationaleBluetoothTitle => 'Bluetooth-åtkomst';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Den här appen vill använda Bluetooth för att ansluta till din OBD2-adapter.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Vad som händer med Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth används bara för att hitta och kommunicera med din OBD2-adapter.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Adapterns identifierare stannar på din enhet — den synkroniseras bara via TankSync, som en del av fordonsprofilen.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'På Android 11 och äldre ber systemet även om plats, eftersom Bluetooth-sökning räknas som en platsbehörighet där.';

  @override
  String get permissionRationaleNotificationsTitle => 'Aviseringar';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Den här appen vill skicka aviseringar till dig om prisvarningar och status för resinspelningen.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Vad som händer med aviseringar:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Aviseringar används för lokala prisvarningar och status för resinspelningen.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'De skapas på din enhet — inget lämnar enheten.';

  @override
  String get permissionRationaleRevoke =>
      'Du kan när som helst återkalla detta i enhetens inställningar.';

  @override
  String get permissionRationaleLegalBasis =>
      'Rättslig grund: art. 6.1 a i GDPR (samtycke)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'uppsk. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Uppskattat värde (~) — ingen bränslesensor på denna resa, så L/100 km-värdet modelleras utifrån GPS-hastighet och ditt fordons kalibrering. Det är ungefärligt (vanligtvis ±10–30 %, förbättras när kalibreringen mognar), inte en uppmätt avläsning.';

  @override
  String get tripRecordingPipElapsedCaption => 'förflutit';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: förbrukningsuppskattningar förankrade mot pumpen ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Öppna den skannade länken?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Den här QR-koden pekar på $host. Öppna bara länkar du litar på.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Öppna länk';

  @override
  String get qrLaunchConfirmCancel => 'Avbryt';

  @override
  String get radarPinHelpTitle => 'Om nålning';

  @override
  String get radarPinHelpBody =>
      'Nålning håller skärmen på och döljer systemfälten så att avläsningen av närmaste station förblir läsbar på en instrumentbrädemontering. Tryck igen för att frigöra. Frigörs automatiskt när radarn stannar.';

  @override
  String get radarAutoPinTitle => 'Nåla alltid när radarn startar';

  @override
  String get radarAutoPinSubtitle =>
      'Nåla radarn automatiskt varje gång istället för att trycka varje gång. Använder mer batteri.';

  @override
  String get radarScopeShowScope => 'Radarvy';

  @override
  String get radarScopeShowList => 'Listvy';

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
  String get reconcileWorkflowTitle => 'Stäm av ditt bränsle';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Vi hittade en lucka på $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Du pumpade $pumped L, men dina registrerade resor redovisar bara $consumed L. Det lämnar $gap L oförklarade.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Det beror vanligtvis på att en körning inte registrerades (adaptern kopplades ur eller appen stängdes), eller att en tankning saknas eller är felinmatad.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Tills detta är löst kommer ditt bränsletotal och ditt resetotal inte att stämma.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Hjälp oss att fördela luckan';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Är alla dina tankningar för denna tank fullständiga och korrekta?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Är alla dina körningar registrerade?';

  @override
  String get reconcileWorkflowAnswerYes => 'Ja';

  @override
  String get reconcileWorkflowAnswerNo => 'Nej';

  @override
  String get reconcileWorkflowPathAHint =>
      'En tankning saknas eller är felaktig — vi lägger till en korrigering så att dina tankningar stämmer.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Dina tankningar stämmer och en körning inte registrerades — vi lägger till en virtuell resa för den saknade sträckan.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Korrigeringsliter';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Hur lång var den oregistrerade körningen? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Bestäm senare';

  @override
  String get reconcileWorkflowBack => 'Tillbaka';

  @override
  String get reconcileWorkflowNext => 'Nästa';

  @override
  String get reconcileWorkflowApply => 'Tillämpa';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtuell resa — tryck för att redigera';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Redigera virtuell resa';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Den här resan lades till för att redovisa bränsle du använde under körning utan inspelning. Justera sträckan eller bränslet, eller ta bort den.';

  @override
  String get reconcileVirtualTrajetDelete => 'Ta bort virtuell resa';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Olöst bränsle-/reselucka på $gap L — tryck för att lösa';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Lös olöst bränsle- och reselucka';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/session';

  @override
  String get settingsSearchHint => 'Sök inställningar';

  @override
  String settingsSearchNoResults(String query) {
    return 'Inga inställningar matchar \"$query\"';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profiler & region';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Land, språk, bränsle, sökradie, ruttplanering';

  @override
  String get settingsTopicProfilesKeywords =>
      'profil, land, språk, bränsle, radie, postnummer, rutt, hem, betyg, startskärm, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Fordon & OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Dina bilar, tankstorlek, parkoppling av OBD2-adapter';

  @override
  String get settingsTopicVehiclesKeywords =>
      'fordon, bil, obd, obd2, adapter, bluetooth, tank, motor, vin, kalibrering, vehicle, car, engine, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Körning & förbrukning';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, belöningar, bensinstationsradar, felsökning';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, eco, haptisk, röst, gamification, radar, glid, resa, förbrukning, bränsleklubb, lojalitet, obd2-logg, fäst, haptic, voice, glide, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Priser & aviseringar';

  @override
  String get settingsTopicPricesSubtitle =>
      'Prisaviseringar, röstmeddelanden, prishistorik, communityrapporter';

  @override
  String get settingsTopicPricesKeywords =>
      'avisering, notis, pris, historik, prognos, bästa tidpunkt, community, rapport, qr, betalning, röst, meddelande, alert, notification, price, history, prediction, report, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Enheter & visning';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Tema, avståndsenhet, widget på startskärmen';

  @override
  String get settingsTopicUnitsKeywords =>
      'tema, mörkt, ljust, eco, enhet, km, miles, widget, färg, visning, utseende, theme, dark, light, unit, colour, display';

  @override
  String get settingsTopicFeaturesTitle => 'Funktioner & användningsläge';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Förinställningar för användningsläge och varje funktionsväxel';

  @override
  String get settingsTopicFeaturesKeywords =>
      'funktion, läge, bas, medel, full, anpassad, växel, stationstyper, bensinstationer, laddstationer, laddning, feature, mode, basic, medium, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Datakällor & plats';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'API-nycklar, GPS-position, automatiskt profilbyte';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, nyckel, gps, plats, position, datakälla, tankerkoenig, opencharge, key, location, data source';

  @override
  String get settingsTopicSyncTitle => 'Synkronisering & konto';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, moln, konto, e-post, länka enhet, synkronisering, dela databas, anonym, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'integritet, samtycke, gdpr, radera, rensa, lagring, cache, data, felrapportering, vin, privacy, consent, delete, erase, storage, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Säkerhetskopiering & återställning';

  @override
  String get settingsTopicBackupSubtitle =>
      'Exportera eller återställ en fullständig säkerhetskopia av dina data';

  @override
  String get settingsTopicBackupKeywords =>
      'säkerhetskopia, export, återställ, import, zip, xml, överföring, backup, restore, transfer';

  @override
  String get settingsTopicAdvancedSubtitle => 'GitHub-token, utvecklarverktyg';

  @override
  String get settingsTopicAdvancedKeywords =>
      'utvecklare, felsökning, token, pat, github, diagnostik, fellogg, spårning, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Version, licenser, länkar';

  @override
  String get settingsTopicAboutKeywords =>
      'om, version, licens, donera, github, erkännande, about, license, donate, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Slå på förbrukningsregistrering under Funktioner & användningsläge för att konfigurera fordon, coaching och belöningar.';

  @override
  String get settingsOpenFeaturesLink => 'Öppna Funktioner & användningsläge';

  @override
  String get settingsRadarTileSubtitle =>
      'Radie, prisläge, avfrågning och skärmfästning för den aktiva profilen';

  @override
  String get settingsRadarNoProfileHint =>
      'Skapa en profil först — radarinställningarna sparas per profil.';

  @override
  String get settingsRadarPinHeader => 'Skärmfästning';

  @override
  String get settingsAlertsTileSubtitle =>
      'Stations- och radieaviseringar som meddelar dig om prissänkningar';

  @override
  String get settingsPriceFeaturesHeader => 'Prisfunktioner';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Röstmeddelanden är av. Slå på Röståterkoppling och Röstmeddelanden under Funktioner & användningsläge för att höra billigt bränsle i närheten när du kör.';

  @override
  String get settingsDistanceUnitTitle => 'Avståndsenhet';

  @override
  String get settingsDistanceUnitSubtitle => 'Från den aktiva profilens land';

  @override
  String get settingsObd2AdapterTitle => 'OBD2-adapter';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Adaptrar parkopplas per fordon — öppna ett fordon för att parkoppla eller byta dess adapter';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Samtycken';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Samtycken för Cloud Sync och resesynkronisering finns under Integritet & data';

  @override
  String get settingsBackupExportSubtitle =>
      'Fordon, tankningar, resor och laddningsloggar som ZIP-fil';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Slå ihop eller ersätt dina data från en tidigare säkerhetskopia (ZIP)';

  @override
  String get settingsStationTypesLink =>
      'Stationstyper ställs in under Funktioner & användningsläge';

  @override
  String get routeSearchCriterionLabel => 'Stationsval per ruttsegment';

  @override
  String get routeSearchCriterionCheapest => 'Billigast';

  @override
  String get routeSearchCriterionNearest => 'Närmast rutten';

  @override
  String get routeSearchTopNLabel => 'Kandidater per mätpunkt';

  @override
  String routeSearchTopNCaption(int count) {
    return 'Upp till $count stationer övervägs vid varje punkt längs rutten.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Bränsle för prissökning (hybrid)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Fordonets standard';

  @override
  String get scopeThisProfile => 'Den här profilen';

  @override
  String get scopeAllProfiles => 'Alla profiler';

  @override
  String get scopeThisVehicle => 'Det här fordonet';

  @override
  String get featureLabel_manualConsumption =>
      'Manuell förbrukningsregistrering';

  @override
  String get featureDescription_manualConsumption =>
      'Registrera tankningar och laddningar för hand (ingen OBD2-adapter krävs).';

  @override
  String get featureLabel_loyaltyCards => 'Lojalitetskort';

  @override
  String get featureDescription_loyaltyCards =>
      'Bränsleklubb-/lojalitetskort med rabatt per liter i prisjämförelser.';

  @override
  String get featureLabel_startupTrace => 'Spårning av startinitiering';

  @override
  String get featureDescription_startupTrace =>
      'Registrerar de tidsatta faserna i appens start, visar dem som ett vattenfall och exporterar dem — en utvecklardiagnostik.';

  @override
  String get locationGpsAutoHint =>
      'GPS-positionen hämtas automatiskt när du söker. Du kan också uppdatera den manuellt här.';

  @override
  String get locationClearGpsBody =>
      'Rensa den sparade GPS-positionen? Du kan uppdatera den igen när som helst.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Den filtypen kan inte importeras ännu — dela ett foto av kvittot istället.';

  @override
  String get shareReceiptFailed =>
      'Kunde inte läsa det delade kvittot — försök dela det igen eller lägg till tankningen manuellt.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Dela kvitto för import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Dela ett kvittofoto från en annan app för att förifyll en tankning — datum, liter, totalt och station läses på enheten.';

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
  String syncAdoptTitle(String email) {
    return 'Gå med i kontot $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Logga in med kontots lösenord för att dela dess data mellan båda enheterna.';

  @override
  String get syncAdoptPasswordLabel => 'Kontots lösenord';

  @override
  String get syncAdoptJoinButton => 'Gå med i kontot';

  @override
  String get syncAdoptUseDifferentAccount => 'Använd ett annat konto i stället';

  @override
  String get syncDeleteDataTitle => 'Ta bort synkade data';

  @override
  String get syncDeleteDataSubtitle =>
      'Ta bort dina resor, fordon eller tankningar från synkdatabasen';

  @override
  String get syncDeleteDataPickTitle => 'Vilka synkade data ska tas bort?';

  @override
  String get syncDeleteDataCategoryTrips => 'Resor';

  @override
  String get syncDeleteDataCategoryVehicles => 'Fordon';

  @override
  String get syncDeleteDataCategoryFillUps => 'Tankningar';

  @override
  String get syncDeleteDataCategoryEverything => 'Allt';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Ta bort $category från synkdatabasen?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Detta tar bort de valda uppgifterna från din synkdatabas, och de synkas inte tillbaka från dina andra enheter. Data som lagras lokalt på den här enheten behålls.';

  @override
  String get syncDeleteDataConfirmAction => 'Ta bort från servern';

  @override
  String get syncDeleteDataDone => 'Synkade data borttagna';

  @override
  String get syncDeleteDataFailed =>
      'Det gick inte att ta bort synkade data — försök igen';

  @override
  String get syncRelinkTitle => 'Molnsynken behöver kopplas på nytt';

  @override
  String get syncRelinkBody =>
      'Enhetens sparade synkidentitet är utloggad. Logga in med din e-post för att koppla dina synkade data på nytt, eller börja om med en ny identitet.';

  @override
  String get syncRelinkSignInAction => 'Logga in för att koppla på nytt';

  @override
  String get syncRelinkStartFreshAction => 'Börja om';

  @override
  String get syncRelinkStartFreshTitle => 'Börja om?';

  @override
  String get syncRelinkStartFreshBody =>
      'En ny anonym identitet skapas för den här enheten. Data som synkats under den gamla identiteten finns kvar på servern men går inte längre att nå härifrån, om du inte loggar in med dess e-postkonto.';

  @override
  String get syncRelinkStartFreshConfirm => 'Börja om';

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
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km med din senaste tanks förbrukning';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Långtidsgenomsnitt: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Senaste tankning: $date · $count resa(or) sedan';
  }

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
  String tankLevelSourceFillUp(String date) {
    return 'Förankrad vid senaste tankningen: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'OBD2-tanksensor · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Tankblandning: $mix';
  }

  @override
  String get tankReportTitle => 'Tankrapport';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Sedan förra fulla tanken: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km mer än förra tanken';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km mindre än förra tanken';
  }

  @override
  String get tankReportTrendFlat => 'I nivå med förra tanken';

  @override
  String get tankReportNoPrevious =>
      'Utvecklingen visas efter din nästa fulla tank.';

  @override
  String get tankReportExplainHeader => 'Vad registreringarna antyder';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Andel högt varvtal $cur % (var $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Häftiga manövrar $cur/100 km (var $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Kallstarter $cur (var $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Andel tomgång $cur % (var $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Registreringarna är spontana och täcker bara en del av den här tanken — ledtrådarna är vägledande, inte hela bilden.';

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
  String get tripSaveProgressFinalizingSummary => 'Slutför sammanfattning…';

  @override
  String get tripSaveProgressSavingToHistory => 'Sparar till historik…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Synkroniserar i bakgrunden…';

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
  String get trajetDetailChartThrottle => 'Gas/pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Kylvätska (°C)';

  @override
  String get trajetDetailChartAltitudeRelative => 'Höjd (m, från start)';

  @override
  String get trajetDetailChartLambda => 'Kommanderad λ';

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
  String get trajetDetailChartEstimatedBadge => 'uppskattat';

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
  String get trajetDetailDownloadCsvOption => 'Ladda ner telemetri (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Ladda ner telemetri (JSON)';

  @override
  String get trajetDetailDownloadError => 'Kunde inte spara filen';

  @override
  String get trajetDetailDeleteAction => 'Radera';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Radera den här resan?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Den här resan tas bort permanent från din historik.';

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
  String get trajetDetailChartBoost => 'Laddtryck (MAP − omgivning)';

  @override
  String get trajetDetailChartIat => 'Insugsluftens temperatur';

  @override
  String get trajetDetailChartTiming => 'Tändförställning';

  @override
  String get trajetObd2Degraded =>
      'Startades med OBD2-adaptern men spelades mest in via GPS — motordata är ofullständiga';

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
  String get tripPathLegendEfficient => 'Effektiv (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Gränsvärde (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Slösaktigt (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Bensinmack-radar';

  @override
  String get tripRadarScanning => 'Söker efter närliggande stationer';

  @override
  String get tripRadarNoStationNearby => 'Ingen station i närheten';

  @override
  String get fuelStationRadarNearer => 'Närmre station';

  @override
  String get fuelStationRadarFarther => 'Längre bort station';

  @override
  String get fuelStationRadarStart => 'Starta bensinmack-radar';

  @override
  String get stopRadar => 'Stoppa radar';

  @override
  String get fuelStationRadarResultBadge => 'Bensinmack-radarresultat';

  @override
  String get radarUpdatingLocation => 'Uppdaterar din plats…';

  @override
  String get radarSearching => 'Söker…';

  @override
  String get highwayModeChip =>
      'Motorvägsläge — visar stationer längre fram längs din rutt';

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
  String get tripRecordingSavingTitle => 'Sparar resa…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Inspelning avbruten — ingen rörelse registrerades';

  @override
  String get tripRecordingGpsNotificationTitle => 'Spelar in din resa';

  @override
  String get tripRecordingGpsNotificationText =>
      'Spårar din rutt för bränsle- och körstatistik';

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
  String get tripVerdictPromptTitle => 'Hur kändes den här resan?';

  @override
  String get tripVerdictSmooth => 'Mjuk';

  @override
  String get tripVerdictModerate => 'Måttlig';

  @override
  String get tripVerdictAggressive => 'Aggressiv';

  @override
  String get tripVerdictDismiss => 'Inte nu';

  @override
  String get tripVerdictThanks =>
      'Tack — det hjälper till att kalibrera din köranalys.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Tankning borttagen';

  @override
  String get trajetDeletedUndoSnackbar => 'Registrering borttagen';

  @override
  String get searchFailedSnackbar => 'Sökning misslyckades – försök igen';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stationer',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Uppdaterad $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Även: $names';
  }

  @override
  String get favoriteAdd => 'Lägg till i favoriter';

  @override
  String get favoriteRemove => 'Ta bort från favoriter';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Rå: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Station utan varumärke';

  @override
  String get unsupportedRegionTitle => 'Inte tillgängligt i din region ännu';

  @override
  String get unsupportedRegionBody =>
      'Vi har inga bränslepriser för ditt land ännu, så resultaten kan vara tomma eller komma från ett annat land. Du kan ändå välja ett land som stöds i sökinställningarna.';

  @override
  String get unsupportedRegionDismiss => 'Uppfattat';

  @override
  String get configureCountryTitle => 'Ange ditt land';

  @override
  String get configureCountryBody =>
      'Ditt land stöds men är inte inställt ännu — priserna kan därför komma från ett annat land. Välj ditt land i sökinställningarna för att se lokala priser.';

  @override
  String get stalePriceBadge => 'Old price';

  @override
  String get radiusAlertCenterChipGps => 'My position';

  @override
  String get radiusAlertCenterChipMap => 'Map point';

  @override
  String radiusAlertCenterChipPostal(String postalCode) {
    return 'Postal code $postalCode';
  }

  @override
  String get radiusAlertCenterClear => 'Clear location';

  @override
  String get radiusAlertBlockerLabel => 'Enter a label';

  @override
  String get radiusAlertBlockerThreshold => 'Enter a threshold above 0';

  @override
  String get radiusAlertBlockerLocation => 'Choose a location';

  @override
  String get allPricesNoPriceMask => '—';

  @override
  String get allPricesBestMarker => 'best';

  @override
  String allPricesDelta(String amount) {
    return '+$amount';
  }

  @override
  String allPricesCostPer100km(String cost) {
    return '$cost/100 km';
  }

  @override
  String allPricesVerdictHere(String fuel, String cost) {
    return 'Cheapest here: $fuel at $cost';
  }

  @override
  String get allPricesVerdictWinsResults => 'cheapest of the results';

  @override
  String allPricesMoreFuels(int count) {
    return '+$count';
  }

  @override
  String allPricesMoreFuelsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more fuels',
      one: 'Show 1 more fuel',
    );
    return '$_temp0';
  }

  @override
  String get allPricesFewerFuelsTooltip => 'Hide the extra fuels';

  @override
  String allPricesCellPriceSemantics(String fuel, String price) {
    return '$fuel $price';
  }

  @override
  String allPricesCellCostSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '$fuel $price, $cost per 100 km at $consumption';
  }

  @override
  String allPricesCellNoPriceSemantics(String fuel) {
    return '$fuel, no price';
  }

  @override
  String allPricesCellUnavailableSemantics(String fuel) {
    return '$fuel, out of stock';
  }

  @override
  String allPricesCellUnusableSemantics(String fuel) {
    return '$fuel, not usable by your vehicle';
  }

  @override
  String get brandMarkFuelGeneric => 'Fuel station';

  @override
  String get brandMarkEvGeneric => 'Charging point';

  @override
  String get fillInventoryTitle => 'Fill-up summary';

  @override
  String fillInventorySubtitleFull(String date, String fuel) {
    return 'Full tank on $date · $fuel';
  }

  @override
  String fillInventorySubtitlePartial(String date, String fuel) {
    return 'Partial fill on $date · $fuel';
  }

  @override
  String fillInventoryKmSinceLastFull(String km) {
    return '$km km since the last full tank';
  }

  @override
  String fillInventoryPumpLiters(String liters) {
    return '$liters L pumped';
  }

  @override
  String fillInventoryPumpConsumption(String value) {
    return 'Pump consumption: $value';
  }

  @override
  String fillInventoryRecordedTrips(int coverage, String value) {
    return 'Recorded trips: $coverage % of the tank · $value raw';
  }

  @override
  String get fillInventoryNoRecordedTrips => 'No recorded trip in this tank';

  @override
  String fillInventoryTankNow(String liters, String km) {
    return 'Tank now: $liters L · ≈ $km km at pump consumption';
  }

  @override
  String fillInventoryTankNowNoRange(String liters) {
    return 'Tank now: $liters L';
  }

  @override
  String fillInventoryCalibrationApplied(
    String before,
    String after,
    String percent,
  ) {
    return 'Pump calibration: ×$before → ×$after ($percent %)';
  }

  @override
  String fillInventoryCalibrationSkipped(String reason) {
    return 'Pump calibration: skipped — $reason';
  }

  @override
  String get fillInventorySkipNotFullTank =>
      'partial fill (the tank window stays open)';

  @override
  String get fillInventorySkipCorrection =>
      'correction entry, not a pumped fill';

  @override
  String get fillInventorySkipNoVehicle => 'no vehicle on this fill';

  @override
  String get fillInventorySkipNoWindow =>
      'first full tank (no window closed yet)';

  @override
  String fillInventorySkipCoverageTooLow(int coverage) {
    return 'recorded trips cover $coverage % of the tank (60 % needed)';
  }

  @override
  String fillInventorySkipRecordedTooShort(String km) {
    return 'only $km recorded km (40 km needed)';
  }

  @override
  String get fillInventorySkipNoRecordedFuel =>
      'the recorded trips carry no fuel figure';

  @override
  String get fillInventorySkipImplausible =>
      'pump and recordings disagree too much — check the receipt';

  @override
  String get fillInventoryDismiss => 'Got it';

  @override
  String tankReportResidualAfterCalibration(String percent) {
    return 'Gap after calibration: $percent %';
  }

  @override
  String get tripFuelSourceMeasured => 'Measured';

  @override
  String get tripFuelSourceEstimatedCalibrated => 'Estimated · calibrated';

  @override
  String get tripFuelSourceEstimated => 'Estimated';

  @override
  String get tripFuelSourceGps => 'GPS';

  @override
  String get tripFuelSourceMeasuredTooltip =>
      'Fuel rate reported by the engine (PID 5E / 9D / A2) — never rescaled';

  @override
  String get tripFuelSourceEstimatedTooltip =>
      'Fuel estimated from air mass — rescaled by the pump calibration';

  @override
  String get tripFuelSourceGpsTooltip =>
      'GPS-physics estimate — no engine data';

  @override
  String get tripFuelSourceRecalculated => 'recalculated';

  @override
  String tripDetailGainApplied(String percent) {
    return 'Pump gain applied: $percent %';
  }

  @override
  String tripDetailRecalculatedAfterFill(String date) {
    return 'Recalculated after the fill-up of $date';
  }

  @override
  String get criteriaModeNearby => 'Nearby';

  @override
  String get criteriaModeRoute => 'Route';

  @override
  String get criteriaSubmit => 'Search';

  @override
  String get criteriaReset => 'Reset';

  @override
  String get criteriaResetDone => 'Criteria reset to your defaults';

  @override
  String get criteriaSubmitDisabledRoute => 'Enter a start and a destination';

  @override
  String get criteriaSubmitDisabledSearching => 'Search in progress…';

  @override
  String criteriaShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get criteriaShowLess => 'Show less';

  @override
  String get criteriaBrands => 'Brands';

  @override
  String get criteriaRouteOptions => 'Route options';

  @override
  String criteriaRouteOptionsSummary(
    int segmentKm,
    int detourKm,
    String saving,
  ) {
    return 'Every $segmentKm km · $detourKm km detour · $saving';
  }

  @override
  String get criteriaSwapEndpoints => 'Swap start and destination';

  @override
  String get fillUpOdometerFromLastFillUp =>
      'Pre-filled from your last fill-up';

  @override
  String get fillUpStationLabel => 'Station';

  @override
  String get fillUpStationChange => 'Change';

  @override
  String get pickStationSectionLast => 'Last station';

  @override
  String get pickStationSectionFavorites => 'Favorites';

  @override
  String get pickStationSectionNearby => 'Nearby';

  @override
  String get pickStationNearbyEmpty =>
      'No recent search — search for stations on the Search tab and the nearest ones will appear here.';

  @override
  String pickStationLastFillUpAt(String date) {
    return 'Last fill-up: $date';
  }

  @override
  String get helpBubblePreviousTip => 'Previous tip';

  @override
  String get helpBubbleNextTip => 'Next tip';

  @override
  String helpBubbleTipPosition(int index, int total) {
    return '$index/$total';
  }

  @override
  String helpBubbleTipPositionSemantic(int index, int total) {
    return 'Tip $index of $total';
  }

  @override
  String get helpSearchTipSummaryBar =>
      'Tap the grey bar above the results to change your fuel, your radius and every other search criterion.';

  @override
  String get helpSearchTipFillEmphasis =>
      'In the comparison table, a filled cell marks the cheapest price for that fuel among the stations you are looking at.';

  @override
  String get helpSearchTipSecondFigure =>
      'The smaller second figure in a cell is what 100 km on that fuel costs in your vehicle.';

  @override
  String get helpSearchTipPriceArrows =>
      'The arrow beside a price ranks it inside this list — cheapest, middle or dearest third of these results. It is not a price trend over time.';

  @override
  String get helpSearchTipViewToggle =>
      'The view button switches between the compact cards and the table that compares every fuel at once.';

  @override
  String searchSummaryFuelTooltip(String fuel) {
    return 'Fuel: $fuel';
  }

  @override
  String searchSummaryRadiusValue(String km) {
    return '$km km';
  }

  @override
  String get searchSummaryAgeJustNow => 'now';

  @override
  String searchSummaryAgeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String searchSummaryAgeHours(int hours) {
    return '$hours h';
  }

  @override
  String searchSummaryAgeDays(int days) {
    return '$days d';
  }

  @override
  String get privacyTopicSubtitle =>
      'Your choices, data on this device, sync, export or delete';

  @override
  String get privacyDataLocationLocal => 'Your data stays on this device';

  @override
  String get privacyDataLocationSynced =>
      'Your data is also synced to TankSync';

  @override
  String get privacySyncLineEnabledAnonymous => 'Sync: on · anonymous account';

  @override
  String get privacySyncLineEnabledEmail => 'Sync: on · email account';

  @override
  String get privacySyncLineDisabled => 'Sync: off';

  @override
  String privacyStorageLine(String size) {
    return '$size stored on this device';
  }

  @override
  String get privacyTopicChoicesTitle => 'Your choices';

  @override
  String privacyChoicesStatus(int on, int total) {
    return '$on of $total enabled';
  }

  @override
  String privacyDeviceDataStatus(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$size · $_temp0';
  }

  @override
  String get privacyTopicExportDeleteTitle => 'Export or delete';

  @override
  String privacyExportDeleteStatus(int count) {
    return 'ZIP, JSON, CSV · error log ($count)';
  }

  @override
  String get privacyLearnMore => 'Learn more';

  @override
  String get tileProxyToggleShort =>
      'Tiles come via the developer\'s EU proxy, not straight from OpenStreetMap';

  @override
  String get remoteLogosToggleShort =>
      'Fetch brand logos from logo.clearbit.com instead of bundled placeholders';

  @override
  String get privacyCacheDetails => 'Cache details';

  @override
  String privacyCacheResponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cached responses',
      one: '1 cached response',
    );
    return '$_temp0';
  }

  @override
  String privacyClearCacheEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'Clear cache ($_temp0)';
  }

  @override
  String get privacySyncStatusLabel => 'Status';

  @override
  String get privacySyncModeCommunity =>
      'Sparkilo Community — the developer\'s EU server';

  @override
  String get privacySyncModeSelfHosted => 'Self-hosted — your own Supabase';

  @override
  String get privacySyncModeSharedGroup =>
      'Shared group — a database you joined';

  @override
  String get privacySyncAccountLabel => 'Account';

  @override
  String get privacySyncAccountAnonymous =>
      'Anonymous account, tied to this device';

  @override
  String privacySyncAccountEmail(String email) {
    return 'Email account: $email';
  }

  @override
  String get privacyCopyUserId => 'Copy user ID';

  @override
  String get privacyUserIdCopied => 'User ID copied';

  @override
  String get privacySyncDatabaseHost => 'Database host';

  @override
  String get privacyExportSectionTitle => 'Export';

  @override
  String get privacyExportMyData => 'Export my data';

  @override
  String get privacyExportSheetTitle => 'Choose a format';

  @override
  String get privacyExportZipTitle => 'ZIP archive';

  @override
  String get privacyExportZipSubtitle =>
      'Everything, attachments included — for a complete backup';

  @override
  String get privacyExportJsonTitle => 'JSON';

  @override
  String get privacyExportJsonSubtitle => 'Machine-readable — for another app';

  @override
  String get privacyExportCsvTitle => 'CSV';

  @override
  String get privacyExportCsvSubtitle => 'Spreadsheet — one table per category';

  @override
  String get privacyErrorLogTitle => 'Error log';

  @override
  String privacyErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get privacyErrorLogSave => 'Save';

  @override
  String get privacyErrorLogClear => 'Clear';

  @override
  String get privacyDangerZoneTitle => 'Danger zone';

  @override
  String get privacyDangerZoneBody =>
      'Permanently deletes everything the app stores on this device. With sync on, your data on the TankSync server is erased too.';

  @override
  String get privacyDeleteAllMyData => 'Delete all my data';

  @override
  String get tripRecordingScreenTitle => 'Trip in progress';

  @override
  String get recordingObd2ChipLive => 'Live';

  @override
  String recordingObd2ChipLiveRate(int rate) {
    return 'Live · $rate PID/s';
  }

  @override
  String get recordingObd2ChipReconnecting => 'Reconnecting…';

  @override
  String recordingObd2ChipReconnectingAttempt(int attempt) {
    return 'Reconnecting… (try $attempt)';
  }

  @override
  String get recordingObd2ChipGpsOnly => 'GPS only';

  @override
  String get recordingObd2ChipEngineOff => 'Engine off — waiting';

  @override
  String get recordingObd2ChipNoAdapter => 'No adapter';

  @override
  String get recordingObd2SheetTitle => 'OBD2 link';

  @override
  String get recordingObd2SheetLive =>
      'The adapter is delivering engine data, so consumption is measured from the car. Nothing to do — keep driving.';

  @override
  String get recordingObd2SheetReconnecting =>
      'The Bluetooth link is being re-established; meanwhile the recording continues on GPS. No action needed — a reset only helps if it stays like this for minutes.';

  @override
  String get recordingObd2SheetGpsOnly =>
      'The adapter has not answered for a while, so the app waits for it to reappear and records on GPS. Consumption is estimated until it is back.';

  @override
  String get recordingObd2SheetEngineOff =>
      'The engine is off, so there is nothing to read. The recording continues on GPS and picks the adapter up again as soon as the engine runs.';

  @override
  String get recordingObd2SheetNoAdapter =>
      'This trip is recorded without an OBD2 adapter. Speed and distance come from GPS; consumption is a physics estimate calibrated by your fill-ups.';

  @override
  String recordingGpsChipPrecise(int meters) {
    return 'Precise fix (±$meters m)';
  }

  @override
  String recordingGpsChipApprox(int meters) {
    return 'Approximate fix (±$meters m)';
  }

  @override
  String get recordingGpsChipNoFix => 'No fix';

  @override
  String get recordingGpsChipFixUnknownAccuracy => 'Fix (accuracy unknown)';

  @override
  String recordingGpsChipWithCoverage(String fix, int percent) {
    return '$fix · $percent %';
  }

  @override
  String get recordingGpsSheetTitle => 'GPS signal';

  @override
  String get recordingGpsSheetPrecise =>
      'The position is accurate to a few metres, so distance and the trace are reliable.';

  @override
  String get recordingGpsSheetApprox =>
      'The position is only accurate to tens of metres — typical in cities, tunnels or under trees. Distance may drift slightly until the fix improves.';

  @override
  String get recordingGpsSheetNoFix =>
      'No position has arrived recently. Check that location is allowed and the phone can see the sky; the recording resumes with the next fix.';

  @override
  String recordingGpsSheetCoverage(int percent) {
    return 'Coverage so far: $percent % of the seconds had a fix.';
  }

  @override
  String get recordingSheetClose => 'Got it';

  @override
  String get fuelSourceMeasured => 'Measured (ECU fuel flow)';

  @override
  String fuelSourceEstimatedCalibrated(int percent) {
    return 'Estimated · pump-calibrated ±$percent %';
  }

  @override
  String get fuelSourceEstimatedUncalibrated => 'Estimated · not calibrated';

  @override
  String get fuelSourceGpsEstimate => 'GPS estimate';

  @override
  String get recordingTileScore => 'Driving score';

  @override
  String searchSummaryAlongRoute(String km) {
    return 'Along the route · every $km km';
  }

  @override
  String get searchSummaryPricesJustNow => 'Prices from just now';

  @override
  String searchSummaryPricesMinutes(int minutes) {
    return 'Prices from $minutes min ago';
  }

  @override
  String searchSummaryPricesHours(int hours) {
    return 'Prices from $hours h ago';
  }

  @override
  String searchSummaryPricesDays(int days) {
    return 'Prices from $days d ago';
  }

  @override
  String get searchResultsFilterTooltip => 'Filters';

  @override
  String searchResultsFilterActiveSemantic(int count) {
    return 'Filters, $count active';
  }

  @override
  String get searchResultsMoreActionsTooltip => 'More actions';

  @override
  String get searchPriceArrowLegend =>
      '↓ and ↑ compare each price with the other stations in this list.';

  @override
  String get searchPriceArrowCheapTooltip =>
      'Among the lowest prices in this list';

  @override
  String get searchPriceArrowAverageTooltip => 'A mid-range price in this list';

  @override
  String get searchPriceArrowExpensiveTooltip =>
      'Among the highest prices in this list';

  @override
  String get searchRefreshTooltip => 'Update position and refresh prices';

  @override
  String priceHistoryFirstSeen(String date) {
    return 'First seen on $date — the history builds up with every visit';
  }

  @override
  String priceHistoryCurrentPriceLine(String price) {
    return 'Current price: $price';
  }

  @override
  String priceHistoryDeltaSince(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String priceHistoryUnchangedSince(String date) {
    return 'Unchanged since $date';
  }

  @override
  String get priceStatsMin => 'Min';

  @override
  String get priceStatsMax => 'Max';

  @override
  String get priceStatsAvg => 'Avg';

  @override
  String get amenitiesAndServices => 'Amenities & services';

  @override
  String amenitiesServicesShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get amenitiesServicesShowLess => 'Show less';

  @override
  String stationStatusWithFreshness(String status, String ago) {
    return '$status · updated $ago ago';
  }

  @override
  String pricesNotSoldHere(String fuels) {
    return 'Not sold here: $fuels';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return 'Recorded trips cover $pct % of this tank';
  }

  @override
  String tankReportRecordedTripsAvg(String value) {
    return 'Recorded trips: $value';
  }

  @override
  String tankReportRecordedTripsOverestimate(String pct) {
    return 'Your recorded trips overestimate consumption by $pct %';
  }

  @override
  String tankReportRecordedTripsUnderestimate(String pct) {
    return 'Your recorded trips underestimate consumption by $pct %';
  }

  @override
  String get trajetObd2DegradedSubtitle => 'No engine data — GPS estimate';

  @override
  String get vehicleTopicAdapterNone => 'None';

  @override
  String get vehicleTopicCalibrationTitle => 'Calibration';

  @override
  String get vehicleTopicAdvancedBadge => 'Advanced';

  @override
  String vehicleTopicCalibrationStatus(int coverage, String mode) {
    return 'Baseline $coverage % · $mode';
  }

  @override
  String vehicleTopicRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
      zero: 'No reminders',
    );
    return '$_temp0';
  }

  @override
  String get vehicleTopicAutoRecordOn => 'On';

  @override
  String get vehicleTopicAutoRecordOff => 'Off';

  @override
  String get vehicleTopicAutoRecordPairLinkText =>
      'Pair an adapter under “OBD2 adapter” to enable auto-recording';

  @override
  String vehicleBaselineCoverageSamples(int covered, int max) {
    return '$covered / $max samples';
  }

  @override
  String vehicleBaselineRawSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get calibrationModeRuleDescription =>
      'Sorts each driving sample into one situation using fixed speed and load thresholds.';

  @override
  String get calibrationModeFuzzyDescription =>
      'Splits each sample across neighbouring situations by how well it fits each one — smoother estimates around the boundaries.';

  @override
  String get pumpGainChipNotCalibrated => 'Not pump-calibrated yet';

  @override
  String pumpGainChipCalibrated(int fills, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      fills,
      locale: localeName,
      other: 'Pump-calibrated · $fills fill-ups · ±$percent %',
      one: 'Pump-calibrated · 1 fill-up · ±$percent %',
    );
    return '$_temp0';
  }

  @override
  String get pumpGainResetAction => 'Reset pump calibration';

  @override
  String get pumpGainResetConfirmTitle => 'Reset pump calibration?';

  @override
  String get pumpGainResetConfirmBody =>
      'This discards the fuel gain learned from your fill-ups. OBD2 consumption estimates fall back to the uncorrected figure until the next full-to-full tank window re-learns it.';

  @override
  String get vehicleMultiFuelCapableLabel => 'Jag kan tanka olika bränsletyper';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Håller koll på vilket bränsle som är billigast per kilometer';

  @override
  String get vinLabel => 'VIN (valfritt)';

  @override
  String get vinDecodeTooltip => 'Avkoda VIN';

  @override
  String get vinConfirmAction => 'Ja, fyll i automatiskt';

  @override
  String get vinModifyAction => 'Ändra manuellt';

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
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detekterad från VIN: $summary. Tillämpa?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Tillämpa';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometer framåt, $fuelType $euros euro $cents';
  }

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
  String get widgetDefaultsThisProfileHint =>
      'Valen nedan gäller för alla installerade widgetar som visar den här profilen, vid nästa uppdatering.';

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
}
