// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Søg';

  @override
  String get favorites => 'Favoritter';

  @override
  String get map => 'Kort';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Indstillinger';

  @override
  String get gpsLocation => 'GPS-position';

  @override
  String get zipCode => 'Postnummer';

  @override
  String get zipCodeHint => 'f.eks. 1000';

  @override
  String get fuelType => 'Brændstof';

  @override
  String get searchRadius => 'Radius';

  @override
  String get searchNearby => 'Tankstationer i nærheden';

  @override
  String get fabRunSearch => 'Kør søgning';

  @override
  String get routeSearchingChip => 'Søger på ruten…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Hver $km km';
  }

  @override
  String get searchCriteriaTitle => 'Søgekriterier';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Inden for $km km';
  }

  @override
  String get noResults => 'Ingen tankstationer fundet.';

  @override
  String get startSearch => 'Søg for at finde tankstationer.';

  @override
  String get open => 'Åben';

  @override
  String get closed => 'Lukket';

  @override
  String distance(String distance) {
    return '$distance væk';
  }

  @override
  String get price => 'Pris';

  @override
  String get prices => 'Priser';

  @override
  String get address => 'Adresse';

  @override
  String get openingHours => 'Åbningstider';

  @override
  String get open24h => 'Åben 24 timer';

  @override
  String get navigate => 'Navigér';

  @override
  String get retry => 'Prøv igen';

  @override
  String get apiKeySetup => 'API-nøgle';

  @override
  String get apiKeyLabel => 'API-nøgle';

  @override
  String get register => 'Registrering';

  @override
  String get continueButton => 'Fortsæt';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle => 'Find den billigste brændstof i nærheden.';

  @override
  String get profileName => 'Profilnavn';

  @override
  String get preferredFuel => 'Foretrukket brændstof';

  @override
  String get defaultRadius => 'Standard radius';

  @override
  String get landingScreen => 'Startskærm';

  @override
  String get homeZip => 'Hjemmepostnummer';

  @override
  String get newProfile => 'Ny profil';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get save => 'Gem';

  @override
  String get cancel => 'Annuller';

  @override
  String get countryChangeTitle => 'Skift land?';

  @override
  String countryChangeBody(String country) {
    return 'Skift til $country vil ændre:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Afstand';

  @override
  String get countryChangeVolume => 'Volumen';

  @override
  String get countryChangePricePerUnit => 'Prisformat';

  @override
  String get countryChangeNote =>
      'Eksisterende favoritter og tanklogger omskrives ikke; kun nye poster bruger de nye enheder.';

  @override
  String get countryChangeConfirm => 'Skift';

  @override
  String get delete => 'Slet';

  @override
  String get activate => 'Aktivér';

  @override
  String get configured => 'Konfigureret';

  @override
  String get notConfigured => 'Ikke konfigureret';

  @override
  String get about => 'Om';

  @override
  String get openSource => 'Open Source (MIT Licens)';

  @override
  String get sourceCode => 'Kildekode på GitHub';

  @override
  String get noFavorites => 'Ingen favoritter endnu';

  @override
  String get noFavoritesHint =>
      'Tryk på stjernen ved en tankstation for at gemme den som favorit.';

  @override
  String get language => 'Sprog';

  @override
  String get country => 'Land';

  @override
  String get freeNoKey => 'Gratis — ingen nøgle nødvendig';

  @override
  String get apiKeyRequired => 'API-nøgle påkrævet';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get storageAndCache => 'Lagring og cache';

  @override
  String get clearCache => 'Ryd cache';

  @override
  String stationsFound(int count) {
    return '$count tankstationer fundet';
  }

  @override
  String get storageUsage => 'Lagringsforbrug på denne enhed';

  @override
  String get settingsLabel => 'Indstillinger';

  @override
  String get profilesStored => 'profiler gemt';

  @override
  String get stationsMarked => 'stationer markeret';

  @override
  String get cachedResponses => 'cachelagrede svar';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Cacheadministration';

  @override
  String get cacheDescription =>
      'Cachen gemmer API-svar for hurtigere indlæsning og offline adgang.';

  @override
  String get cacheTtlGroupNetwork => 'Netværk';

  @override
  String get cacheTtlGroupData => 'Data';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodning';

  @override
  String get stationSearch => 'Stationssøgning';

  @override
  String get stationDetails => 'Stationsdetaljer';

  @override
  String get priceQuery => 'Prisforespørgsel';

  @override
  String get zipGeocoding => 'Postnummer-geokodning';

  @override
  String minutes(int n) {
    return '$n minutter';
  }

  @override
  String hours(int n) {
    return '$n timer';
  }

  @override
  String get clearCacheTitle => 'Ryd cache?';

  @override
  String get clearCacheBody =>
      'Cachelagrede søgeresultater og priser slettes. Profiler, favoritter og indstillinger bevares.';

  @override
  String get clearCacheButton => 'Ryd cache';

  @override
  String get deleteAllTitle => 'Slet alle data?';

  @override
  String get deleteAllBody =>
      'Dette sletter permanent alle profiler, favoritter, API-nøgle, indstillinger og cache. Appen nulstilles.';

  @override
  String get deleteAllButton => 'Slet alt';

  @override
  String get entries => 'poster';

  @override
  String get cacheEmpty => 'Cachen er tom';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data fra statslige pristransparensorganer.';

  @override
  String get apiKeyFormatError =>
      'Ugyldigt format — forventet UUID (8-4-4-4-12)';

  @override
  String get reportThisIssue => 'Rapporter dette problem';

  @override
  String get reportAlreadySent => 'Du har allerede rapporteret dette problem.';

  @override
  String get reportConsentTitle => 'Rapporter til GitHub?';

  @override
  String get reportConsentBody =>
      'Dette åbner et offentligt GitHub-issue med fejldetaljerne nedenfor. Ingen GPS-koordinater, API-nøgler eller personoplysninger inkluderes.';

  @override
  String get reportConsentConfirm => 'Åbn GitHub';

  @override
  String get reportConsentCancel => 'Annuller';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktiv profil';

  @override
  String get configPreferredFuel => 'Foretrukket brændstof';

  @override
  String get configCountry => 'Land';

  @override
  String get configRouteSegment => 'Rutesegment';

  @override
  String get configApiKeysSection => 'API-nøgler';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-nøgle';

  @override
  String get configApiKeyConfigured => 'Konfigureret';

  @override
  String get configApiKeyCommunity => 'Standard (fællesskabsnøgle)';

  @override
  String get searchLocationPlaceholder => 'Adresse, postnummer eller by';

  @override
  String get configEvKey => 'EV-opladnings-API-nøgle';

  @override
  String get configEvKeyCustom => 'Brugerdefineret nøgle';

  @override
  String get configEvKeyShared => 'Standard (delt)';

  @override
  String get configCloudSyncSection => 'Cloud-synkronisering';

  @override
  String get configTankSyncConnected => 'Tilsluttet';

  @override
  String get configTankSyncDisabled => 'Deaktiveret';

  @override
  String get configAuthMode => 'Godkendelsestilstand';

  @override
  String get configAuthEmail => 'E-mail (vedvarende)';

  @override
  String get configAuthAnonymous => 'Anonym (kun enhed)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Privatlivsoversigt';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoritter, advarsler og ignorerede stationer synkroniseres til din private database\n• GPS-position og API-nøgler forlader aldrig din enhed\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Alle data gemmes lokalt på denne enhed\n• Ingen data sendes til nogen server\n• API-nøgler krypteret i enhedens sikre lager';

  @override
  String get configAuthNoteEmail =>
      'E-mailkonto muliggør adgang fra flere enheder';

  @override
  String get configAuthNoteAnonymous =>
      'Anonym konto — data knyttet til denne enhed';

  @override
  String get configNone => 'Ingen';

  @override
  String get privacyPolicy => 'Privatlivspolitik';

  @override
  String get fuels => 'Brændstoffer';

  @override
  String get services => 'Tjenester';

  @override
  String get zone => 'Zone';

  @override
  String get highway => 'Motorvej';

  @override
  String get localStation => 'Lokal station';

  @override
  String get lastUpdate => 'Seneste opdatering';

  @override
  String get automate24h => '24t/24 — Automat';

  @override
  String get refreshPrices => 'Opdater priser';

  @override
  String get station => 'Tankstation';

  @override
  String get locationDenied =>
      'Placeringstilladelse nægtet. Du kan søge efter postnummer.';

  @override
  String get demoModeBanner =>
      'Demo-tilstand. Konfigurer API-nøgle i indstillinger.';

  @override
  String get demoModeBannerAction => 'Hent live-priser';

  @override
  String get sortDistance => 'Afstand';

  @override
  String get sortOpen24h => '24t';

  @override
  String get sortRating => 'Bedømmelse';

  @override
  String get sortPriceDistance => 'Pris/km';

  @override
  String get cheap => 'billig';

  @override
  String get expensive => 'dyr';

  @override
  String get reportPrice => 'Rapportér pris';

  @override
  String get whatsWrong => 'Hvad er galt?';

  @override
  String get correctPrice => 'Korrekt pris (f.eks. 15,79)';

  @override
  String get sendReport => 'Send rapport';

  @override
  String get reportSent => 'Rapport sendt. Tak!';

  @override
  String get enterValidPrice => 'Indtast venligst en gyldig pris';

  @override
  String get cacheCleared => 'Cache ryddet.';

  @override
  String get yourPosition => 'Din position';

  @override
  String get positionUnknown => 'Position ukendt';

  @override
  String get distancesFromCenter => 'Afstande fra søgecentrum';

  @override
  String get autoUpdatePosition => 'Opdater position automatisk';

  @override
  String get autoUpdateDescription => 'Opdater GPS-position før hver søgning';

  @override
  String get location => 'Placering';

  @override
  String get switchProfileTitle => 'Land ændret';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Du er nu i $country. Skift til profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Skiftet til profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ingen profil for dette land';

  @override
  String noProfileForCountry(String country) {
    return 'Du er i $country, men ingen profil er konfigureret. Opret en i Indstillinger.';
  }

  @override
  String get autoSwitchProfile => 'Automatisk profilskift';

  @override
  String get autoSwitchDescription =>
      'Skift profil automatisk ved grænseoverskridelse';

  @override
  String profileSwitchedTo(String profile) {
    return 'Skiftet til $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name oprettet';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Der findes allerede en profil for $country — rediger den i stedet.';
  }

  @override
  String get switchProfile => 'Skift';

  @override
  String get dismiss => 'Luk';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Sprog';

  @override
  String get settingsStorageDetail => 'API-nøgle, aktiv profil';

  @override
  String get allFuels => 'Alle';

  @override
  String get priceAlerts => 'Prisalarmer';

  @override
  String get noPriceAlerts => 'Ingen prisalarmer';

  @override
  String get noPriceAlertsHint => 'Opret en alarm fra en stations detaljeside.';

  @override
  String alertDeleted(String name) {
    return 'Alarm \"$name\" slettet';
  }

  @override
  String get createAlert => 'Opret prisalarm';

  @override
  String currentPrice(String price) {
    return 'Aktuel pris: $price';
  }

  @override
  String get targetPrice => 'Målpris (EUR)';

  @override
  String get enterPrice => 'Indtast en pris';

  @override
  String get invalidPrice => 'Ugyldig pris';

  @override
  String get priceTooHigh => 'Pris for høj';

  @override
  String get create => 'Opret';

  @override
  String get alertCreated => 'Prisalarm oprettet';

  @override
  String get wrongE5Price => 'Forkert Super E5 pris';

  @override
  String get wrongE10Price => 'Forkert Super E10 pris';

  @override
  String get wrongDieselPrice => 'Forkert Diesel pris';

  @override
  String get wrongStatusOpen => 'Vist som åben, men lukket';

  @override
  String get wrongStatusClosed => 'Vist som lukket, men åben';

  @override
  String get allStations => 'Alle stationer';

  @override
  String get bestStops => 'Bedste stop';

  @override
  String get openInMaps => 'Åbn i Kort';

  @override
  String get noStationsAlongRoute => 'Ingen stationer fundet langs ruten';

  @override
  String get evOperational => 'I drift';

  @override
  String get evStatusUnknown => 'Status ukendt';

  @override
  String evConnectors(int count) {
    return 'Stik ($count punkter)';
  }

  @override
  String get evNoConnectors => 'Ingen stikdetaljer tilgængelige';

  @override
  String get evUsageCost => 'Brugsomkostninger';

  @override
  String get evPricingUnavailable => 'Pris ikke tilgængelig fra udbyderen';

  @override
  String get evPriceFree => 'Gratis';

  @override
  String get evPricePayAtLocation => 'Betal på stedet';

  @override
  String get evPriceMembership => 'Medlemskab påkrævet';

  @override
  String get evPriceIndicative => 'Vejledende pris';

  @override
  String get evPriceDeclaredByOperator =>
      'Vejledende pris angivet af operatøren — verificer på stedet';

  @override
  String get evPriceFranceAttribution =>
      'Prissætning: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Best-effort-prissætning fra OpenChargeMap — sparsom og kan være ufuldstændig.';

  @override
  String get evLastUpdated => 'Sidst opdateret';

  @override
  String get evUnknown => 'Ukendt';

  @override
  String get evDataAttribution => 'Data fra OpenChargeMap (community-kilde)';

  @override
  String get evStatusDisclaimer =>
      'Status afspejler muligvis ikke tilgængeligheden i realtid. Tryk på opdater for at hente de seneste data.';

  @override
  String get evNavigateToStation => 'Navigér til station';

  @override
  String get evRefreshStatus => 'Opdater status';

  @override
  String get evStatusUpdated => 'Status opdateret';

  @override
  String get evStationNotFound =>
      'Kunne ikke opdatere — station ikke fundet i nærheden';

  @override
  String get addedToFavorites => 'Tilføjet til favoritter';

  @override
  String get removedFromFavorites => 'Fjernet fra favoritter';

  @override
  String get addFavorite => 'Tilføj til favoritter';

  @override
  String get removeFavorite => 'Fjern fra favoritter';

  @override
  String get currentLocation => 'Aktuel placering';

  @override
  String get gpsError => 'GPS-fejl';

  @override
  String get couldNotResolve => 'Kunne ikke bestemme start eller destination';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get cityAddressOrGps => 'By, adresse eller GPS';

  @override
  String get cityOrAddress => 'By eller adresse';

  @override
  String get useGps => 'Brug GPS';

  @override
  String get stop => 'Stop';

  @override
  String get addStop => 'Tilføj stop';

  @override
  String get searchAlongRoute => 'Søg langs ruten';

  @override
  String get cheapest => 'Billigste';

  @override
  String nStations(int count) {
    return '$count stationer';
  }

  @override
  String nBest(int count) {
    return '$count bedste';
  }

  @override
  String get fuelPricesTankerkoenig => 'Brændstofpriser (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Påkrævet til brændstofprissøgning i Tyskland';

  @override
  String get evChargingOpenChargeMap => 'EV-opladning (OpenChargeMap)';

  @override
  String get customKey => 'Brugerdefineret nøgle';

  @override
  String get appDefaultKey => 'App-standardnøgle';

  @override
  String get optionalOverrideKey =>
      'Valgfrit: erstat den indbyggede app-nøgle med din egen';

  @override
  String get edit => 'Rediger';

  @override
  String get fuelPricesApiKey => 'Brændstofpriser API-nøgle';

  @override
  String get evChargingApiKey => 'EV-opladning API-nøgle';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-nøgle';

  @override
  String get routePlanningSection => 'Ruteplanlægning';

  @override
  String get routeMinSaving => 'Minimal besparelse';

  @override
  String get routeMinSavingOff => 'Fra';

  @override
  String get routeMinSavingOffCaption =>
      'Viser alle stationer fundet langs ruten';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Kun stationer inden for $amount af den billigste på ruten';
  }

  @override
  String get routeDetourBudget => 'Maksimal omvej';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Vis stationer op til $km km fra din direkte rute';
  }

  @override
  String get routeSegment => 'Rutesegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Vis billigste station for hver $km km langs ruten';
  }

  @override
  String get avoidHighways => 'Undgå motorveje';

  @override
  String get avoidHighwaysDesc =>
      'Ruteberegning undgår betalingsveje og motorveje';

  @override
  String get showFuelStations => 'Vis tankstationer';

  @override
  String get showFuelStationsDesc =>
      'Inkluder benzin-, diesel-, LPG-, CNG-stationer';

  @override
  String get showEvStations => 'Vis ladestationer';

  @override
  String get showEvStationsDesc =>
      'Inkluder elektriske ladestationer i søgeresultater';

  @override
  String get noStationsAlongThisRoute =>
      'Ingen stationer fundet langs denne rute.';

  @override
  String get fuelCostCalculator => 'Brændstofomkostningsberegner';

  @override
  String get distanceKm => 'Afstand (km)';

  @override
  String get tripCost => 'Turomkostning';

  @override
  String get fuelNeeded => 'Nødvendigt brændstof';

  @override
  String get totalCost => 'Samlede omkostninger';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Afstand ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Forbrug ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Brændstofpris ($unit)';
  }

  @override
  String get calculatorUseMine => 'Brug';

  @override
  String get calculatorApplied => 'Anvendt';

  @override
  String get tripDetails => 'Turdetaljer';

  @override
  String get calculatorRoundTrip => 'Tur-retur';

  @override
  String get roundTripTotal => 'Tur-retur';

  @override
  String get costPerDistance => 'Pris pr. km';

  @override
  String get costPerMonth => 'Pris pr. måned';

  @override
  String get calculatorEstimateMonthly => 'Estimér månedlige omkostninger';

  @override
  String get calculatorTripsPerMonth => 'Ture pr. måned';

  @override
  String get calculatorTripsPerMonthHint => 'f.eks. 20';

  @override
  String get calculatorReset => 'Nulstil';

  @override
  String get calculatorResultPlaceholder =>
      'Udfyld afstand, forbrug og pris for at se din turpris';

  @override
  String get priceHistory => 'Prishistorik';

  @override
  String get ignoredStationsLabel => 'Ignorerede';

  @override
  String get ratingsLabel => 'Vurderinger';

  @override
  String get favoritesDataCache => 'Favoritdata';

  @override
  String get citySearchCache => 'Bysøgning';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count sporede stationer';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count konfigureret';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count skjulte stationer';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count vurderede stationer';
  }

  @override
  String get noPriceHistory => 'Ingen prishistorik endnu';

  @override
  String get noStatistics => 'Ingen statistikker tilgængelige';

  @override
  String get showAllFuelTypes => 'Vis alle brændstoftyper';

  @override
  String get connected => 'Forbundet';

  @override
  String get disconnectTankSync => 'Afbryd TankSync';

  @override
  String get viewMyData => 'Se mine data';

  @override
  String get deleteAllServerData => 'Slet alle serverdata';

  @override
  String get deleteServerDataConfirm => 'Slet alle serverdata?';

  @override
  String get deleteEverything => 'Slet alt';

  @override
  String get allDataDeleted => 'Alle serverdata slettet';

  @override
  String get forgetAllSyncedTripsButton => 'Glem alle synkroniserede ture';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Glem alle synkroniserede ture?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Alle turresuméer og detaljerede data fjernes fra serveren. Din lokale turhistorik på denne enhed påvirkes ikke.\n\nDenne handling kan ikke fortrydes.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Glem alle';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Alle synkroniserede ture fjernet fra serveren';

  @override
  String get disconnect => 'Afbryd';

  @override
  String get myServerData => 'Mine serverdata';

  @override
  String get anonymousUuid => 'Anonym UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synkroniserede data';

  @override
  String get pushTokens => 'Push-tokens';

  @override
  String get priceReports => 'Prisrapporter';

  @override
  String get syncedTrips => 'Ture';

  @override
  String get totalItems => 'Antal elementer';

  @override
  String get estimatedSize => 'Estimeret størrelse';

  @override
  String get viewRawJson => 'Se rådata som JSON';

  @override
  String get exportJson => 'Eksportér som JSON (udklipsholder)';

  @override
  String get jsonCopied => 'JSON kopieret til udklipsholder';

  @override
  String get rawDataJson => 'Rådata (JSON)';

  @override
  String get close => 'Luk';

  @override
  String get account => 'Konto';

  @override
  String get continueAsGuest => 'Fortsæt som gæst';

  @override
  String get createAccount => 'Opret konto';

  @override
  String get signIn => 'Log ind';

  @override
  String get savedRoutes => 'Gemte ruter';

  @override
  String get noSavedRoutes => 'Ingen gemte ruter';

  @override
  String get noSavedRoutesHint =>
      'Søg langs en rute og gem den til hurtig adgang senere.';

  @override
  String get saveRoute => 'Gem rute';

  @override
  String get routeName => 'Rutenavn';

  @override
  String itineraryDeleted(String name) {
    return '$name slettet';
  }

  @override
  String loadingRoute(String name) {
    return 'Indlæser rute: $name';
  }

  @override
  String get refreshFailed => 'Opdatering mislykkedes. Prøv igen.';

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
  String get onboardingWelcomeHint => 'Opsæt appen i nogle få hurtige trin.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrer dig for en gratis API-nøgle, eller spring over for at udforske appen med demodata.';

  @override
  String get onboardingComplete => 'Klar!';

  @override
  String get onboardingCompleteHint =>
      'Du kan ændre disse indstillinger til enhver tid i din profil.';

  @override
  String get onboardingBack => 'Tilbage';

  @override
  String get onboardingNext => 'Næste';

  @override
  String get onboardingSkip => 'Spring over';

  @override
  String get onboardingFinish => 'Kom i gang';

  @override
  String get switchToAllPricesView => 'Skift til alle-priser-visning';

  @override
  String get switchToCompactView => 'Skift til kompakt visning';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Ikke på lager';

  @override
  String get gdprTitle => 'Dit privatliv';

  @override
  String get gdprSubtitle =>
      'Denne app respekterer dit privatliv. Vælg hvilke data du ønsker at dele. Du kan ændre disse indstillinger til enhver tid.';

  @override
  String get gdprLocationTitle => 'Adgang til placering';

  @override
  String get gdprLocationDescription =>
      'Dine koordinater sendes til brændstofpris-API\'en for at finde nærliggende stationer. Placeringsdata gemmes aldrig på en server og bruges ikke til sporing.';

  @override
  String get gdprLocationShort =>
      'Find nærliggende tankstationer ved hjælp af din placering';

  @override
  String get gdprErrorReportingTitle => 'Fejlrapportering';

  @override
  String get gdprErrorReportingDescription =>
      'Anonyme nedbrudsrapporter hjælper med at forbedre appen. Ingen personoplysninger inkluderes. Rapporter sendes via Sentry kun når det er konfigureret.';

  @override
  String get gdprErrorReportingShort =>
      'Send anonyme nedbrudsrapporter for at forbedre appen';

  @override
  String get gdprCloudSyncTitle => 'Cloud-synkronisering';

  @override
  String get gdprCloudSyncDescription =>
      'Synkroniser favoritter og advarsler på tværs af enheder via TankSync. Bruger anonym godkendelse. Dine data er krypteret under overførsel.';

  @override
  String get gdprCloudSyncShort =>
      'Synkroniser favoritter og advarsler på tværs af enheder';

  @override
  String get gdprLegalBasis =>
      'Retsgrundlag: Art. 6(1)(a) GDPR (Samtykke). Du kan trække samtykke tilbage til enhver tid i Indstillinger.';

  @override
  String get gdprContinueAll => 'Fortsæt med alt';

  @override
  String get gdprContinueSelected => 'Fortsæt med det valgte';

  @override
  String get gdprSettingsHint =>
      'Du kan ændre dine privatlivsvalg til enhver tid.';

  @override
  String get routeSaved => 'Rute gemt!';

  @override
  String get routeSaveFailed => 'Kunne ikke gemme rute';

  @override
  String get sqlCopied => 'SQL kopieret til udklipsholder';

  @override
  String get connectionDataCopied => 'Forbindelsesdata kopieret';

  @override
  String get accountDeleted => 'Konto slettet. Lokale data bevaret.';

  @override
  String get switchedToAnonymous => 'Skiftet til anonym session';

  @override
  String failedToSwitch(String error) {
    return 'Skift mislykkedes: $error';
  }

  @override
  String get connectedAsGuest => 'Tilsluttet som gæst';

  @override
  String get accountCreated => 'Konto oprettet!';

  @override
  String get signedIn => 'Logget ind!';

  @override
  String stationHidden(String name) {
    return '$name skjult';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name fjernet fra favoritter';
  }

  @override
  String invalidApiKey(String error) {
    return 'Ugyldig API-nøgle: $error';
  }

  @override
  String get invalidQrCode => 'Ugyldigt QR-kodeformat';

  @override
  String get invalidQrCodeTankSync =>
      'Ugyldig QR-kode — forventet TankSync-format';

  @override
  String get tankSyncConnected => 'TankSync tilsluttet!';

  @override
  String get syncCompleted => 'Synkronisering fuldført — data opdateret';

  @override
  String get deviceCodeCopied => 'Enhedskode kopieret';

  @override
  String get undo => 'Fortryd';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Angiv et gyldigt $length-cifret $label';
  }

  @override
  String get freshnessAgo => 'siden';

  @override
  String get freshnessStale => 'Forældet';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Datafreshness: $age';
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
      other: 'Bedøm $count stjerner',
      one: 'Bedøm 1 stjerne',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Svag';

  @override
  String get passwordStrengthFair => 'Middel';

  @override
  String get passwordStrengthStrong => 'Stærk';

  @override
  String get passwordReqMinLength => 'Mindst 8 tegn';

  @override
  String get passwordReqUppercase => 'Mindst 1 stort bogstav';

  @override
  String get passwordReqLowercase => 'Mindst 1 lille bogstav';

  @override
  String get passwordReqDigit => 'Mindst 1 tal';

  @override
  String get passwordReqSpecial => 'Mindst 1 specialtegn';

  @override
  String get passwordTooWeak => 'Adgangskoden opfylder ikke alle krav';

  @override
  String get brandFilterAll => 'Alle';

  @override
  String get brandFilterNoHighway => 'Ingen motorvej';

  @override
  String get swipeTutorialMessage =>
      'Stryg til højre for at navigere, stryg til venstre for at fjerne';

  @override
  String get swipeTutorialDismiss => 'Forstået';

  @override
  String get alertStatsActive => 'Aktive';

  @override
  String get alertStatsToday => 'I dag';

  @override
  String get alertStatsThisWeek => 'Denne uge';

  @override
  String get privacyDashboardTitle => 'Privatlivsdashboard';

  @override
  String get privacyDashboardSubtitle => 'Se, eksporter eller slet dine data';

  @override
  String get privacyDashboardBanner =>
      'Dine data tilhører dig. Her kan du se alt, hvad denne app gemmer, eksportere det eller slette det.';

  @override
  String get privacyLocalData => 'Data på denne enhed';

  @override
  String get privacyIgnoredStations => 'Ignorerede stationer';

  @override
  String get privacyRatings => 'Stationsbedømmelser';

  @override
  String get privacyPriceHistory => 'Prishistorik-stationer';

  @override
  String get privacyProfiles => 'Søgeprofiler';

  @override
  String get privacyItineraries => 'Gemte ruter';

  @override
  String get privacyCacheEntries => 'Cache-poster';

  @override
  String get privacyApiKey => 'API-nøgle gemt';

  @override
  String get privacyEvApiKey => 'EV API-nøgle gemt';

  @override
  String get privacyEstimatedSize => 'Anslået lager';

  @override
  String get privacySyncedData => 'Cloud-sync (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Cloud-synkronisering er deaktiveret. Alle data forbliver kun på denne enhed.';

  @override
  String get privacySyncMode => 'Synkroniseringstilstand';

  @override
  String get privacySyncUserId => 'Bruger-ID';

  @override
  String get privacySyncDescription =>
      'Når sync er aktiveret, gemmes favoritter, advarsler, ignorerede stationer og bedømmelser også på TankSync-serveren.';

  @override
  String get privacyViewServerData => 'Vis serverdata';

  @override
  String get privacyExportButton => 'Eksporter alle data som JSON';

  @override
  String get privacyExportSuccess => 'Data eksporteret til udklipsholder';

  @override
  String get privacyExportCsvButton => 'Eksporter alle data som CSV';

  @override
  String get privacyExportCsvSuccess =>
      'CSV-data eksporteret til udklipsholder';

  @override
  String get savedToDownloadsFolder => 'Gemt i mappen Downloads';

  @override
  String get privacyDeleteButton => 'Slet alle data';

  @override
  String privacySaveErrorLog(int count) {
    return 'Gem fejllog ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Ryd fejllog';

  @override
  String get privacyErrorLogCleared => 'Fejllog ryddet';

  @override
  String get privacyDeleteTitle => 'Slet alle data?';

  @override
  String get privacyDeleteBody =>
      'Dette sletter permanent:\n\n- Alle favoritter og stationsdata\n- Alle søgeprofiler\n- Alle prisadvarsler\n- Al prishistorik\n- Alle cachedata\n- Din API-nøgle\n- Alle appindstillinger\n\nAppen nulstilles til sin begyndelsestilstand. Denne handling kan ikke fortrydes.';

  @override
  String get privacyDeleteConfirm => 'Slet alt';

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
  String get paymentMethods => 'Betalingsmetoder';

  @override
  String get paymentMethodCash => 'Kontant';

  @override
  String get paymentMethodCard => 'Kort';

  @override
  String get paymentMethodContactless => 'Kontaktløs';

  @override
  String get paymentMethodFuelCard => 'Brændstofkort';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Betal med $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Sammenlignet med det rullende gennemsnit over dine seneste 3 tankninger ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Forbrug $value L/100 km, $delta i forhold til dit rullende gennemsnit';
  }

  @override
  String get drivingMode => 'Køretilstand';

  @override
  String get drivingExit => 'Afslut';

  @override
  String get drivingNearestStation => 'Nærmeste';

  @override
  String get drivingTapToUnlock => 'Tryk for at låse op';

  @override
  String get drivingSafetyTitle => 'Sikkerhedsadvarsel';

  @override
  String get drivingSafetyMessage =>
      'Betjen ikke appen under kørslen. Hold ind til siden på et sikkert sted, inden du interagerer med skærmen. Føreren er altid ansvarlig for sikker betjening af køretøjet.';

  @override
  String get drivingSafetyAccept => 'Jeg forstår';

  @override
  String get voiceAnnouncementsTitle => 'Stemmemeddelelser';

  @override
  String get voiceAnnouncementsDescription =>
      'Annoncér nærliggende billige stationer under kørslen';

  @override
  String get voiceAnnouncementsEnabled => 'Aktivér stemmemeddelelser';

  @override
  String get voiceAnnouncementProximityRadius => 'Annonceradius';

  @override
  String get voiceAnnouncementCooldown => 'Gentagelsesinterval';

  @override
  String get voiceAnnouncementPriceLimit => 'Maksimumpris';

  @override
  String get consumptionStatsTitle => 'Forbrugsstatistik';

  @override
  String get addFillUp => 'Tilføj tankning';

  @override
  String get noFillUpsTitle => 'Ingen tankninger endnu';

  @override
  String get noFillUpsSubtitle =>
      'Log din første tankning for at begynde at spore forbruget.';

  @override
  String get fillUpDate => 'Dato';

  @override
  String get liters => 'Liter';

  @override
  String get odometerKm => 'Kilometertæller (km)';

  @override
  String get notesOptional => 'Noter (valgfrit)';

  @override
  String get stationPreFilled => 'Station udfyldt på forhånd';

  @override
  String get statAvgConsumption => 'Gns. L/100km';

  @override
  String get statAvgCostPerKm => 'Gns. pris/km';

  @override
  String get statTotalLiters => 'Liter i alt';

  @override
  String get statTotalSpent => 'Samlet forbrug';

  @override
  String get statFillUpCount => 'Tankninger';

  @override
  String get fieldRequired => 'Påkrævet';

  @override
  String get fieldInvalidNumber => 'Ugyldigt tal';

  @override
  String get carbonDashboardTitle => 'CO2-dashboard';

  @override
  String get carbonEmptyTitle => 'Ingen data endnu';

  @override
  String get carbonEmptySubtitle =>
      'Log tankninger for at se dit CO2-dashboard.';

  @override
  String get carbonSummaryTotalCost => 'Samlet pris';

  @override
  String get carbonSummaryTotalCo2 => 'Samlet CO2';

  @override
  String get monthlyCostsTitle => 'Månedlige udgifter';

  @override
  String get monthlyEmissionsTitle => 'Månedlige CO2-udledninger';

  @override
  String get vehiclesTitle => 'Mine køretøjer';

  @override
  String get vehiclesMenuTitle => 'Mine køretøjer';

  @override
  String get vehiclesMenuSubtitle => 'Batteri, stik, opladningspræferencer';

  @override
  String get vehiclesEmptyMessage =>
      'Tilføj din bil for at filtrere efter stiktype og estimere opladningsomkostninger.';

  @override
  String get vehiclesWizardTitle => 'Mine køretøjer (valgfrit)';

  @override
  String get vehiclesWizardSubtitle =>
      'Tilføj din bil for at forudfylde forbrugsloggen og aktivere EV-stikfiltre. Du kan springe dette over og tilføje køretøjer senere.';

  @override
  String get vehiclesWizardNoneYet => 'Ingen køretøjer konfigureret endnu.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count køretøjer',
      one: '1 køretøj',
    );
    return 'Du har $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Spring over for at afslutte opsætningen — du kan tilføje køretøjer når som helst fra Indstillinger.';

  @override
  String get fillUpVehicleLabel => 'Køretøj';

  @override
  String get fillUpVehicleRequired => 'Køretøj er påkrævet';

  @override
  String get reportScanError => 'Rapporter scanningsfejl';

  @override
  String get pickStationTitle => 'Vælg en station';

  @override
  String get pickStationHelper =>
      'Start tankningnen fra en kendt station, så priser, mærke og brændstoftype udfyldes automatisk.';

  @override
  String get pickStationEmpty =>
      'Ingen favoritstationer endnu — tilføj nogle fra Søg eller Favoritter, eller spring over og udfyld manuelt.';

  @override
  String get pickStationSkip => 'Spring over — tilføj uden station';

  @override
  String get scanPayment => 'Scan betalings-QR';

  @override
  String get qrPaymentBeneficiary => 'Modtager';

  @override
  String get qrPaymentAmount => 'Beløb';

  @override
  String get qrPaymentEpcTitle => 'SEPA-betaling';

  @override
  String get qrPaymentEpcEmpty => 'Ingen felter afkodet';

  @override
  String get qrPaymentOpenInBank => 'Åbn i bankapp';

  @override
  String get qrPaymentLaunchFailed =>
      'Ingen app tilgængelig til at åbne denne kode';

  @override
  String get qrPaymentUnknownTitle => 'Ukendt kode';

  @override
  String get qrPaymentCopyRaw => 'Kopiér rå tekst';

  @override
  String get qrPaymentCopiedRaw => 'Kopieret til udklipsholder';

  @override
  String get qrPaymentReport => 'Rapporter denne scanning';

  @override
  String get qrPaymentEpcCopied =>
      'Bankoplysninger kopieret — indsæt i din bankapp';

  @override
  String get qrScannerGuidance => 'Ret kameraet mod en QR-kode';

  @override
  String get qrScannerPermissionDenied =>
      'Kameraadgang kræves for at scanne QR-koder.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kameraadgang blev afvist. Åbn indstillinger for at tildele den.';

  @override
  String get qrScannerRetryPermission => 'Prøv igen';

  @override
  String get qrScannerOpenSettings => 'Åbn indstillinger';

  @override
  String get qrScannerTimeout =>
      'Ingen QR-kode registreret. Kom tættere på eller prøv igen.';

  @override
  String get qrScannerRetry => 'Prøv igen';

  @override
  String get torchOn => 'Tænd lommelygte';

  @override
  String get torchOff => 'Sluk lommelygte';

  @override
  String get obdPermissionDenied =>
      'Tildel Bluetooth-tilladelse i systemindstillinger';

  @override
  String get obdPickerTitle => 'Vælg en OBD2-adapter';

  @override
  String get obdPickerScanning => 'Søger efter adaptere…';

  @override
  String get obdPickerConnecting => 'Opretter forbindelse…';

  @override
  String get tripRecordingTitle => 'Optager tur';

  @override
  String get tripSummaryTitle => 'Turresumé';

  @override
  String get tripMetricDistance => 'Afstand';

  @override
  String get tripMetricSpeed => 'Hastighed';

  @override
  String get tripMetricFuelUsed => 'Brændstof brugt';

  @override
  String get tripMetricAvgConsumption => 'Gns.';

  @override
  String get tripMetricElapsed => 'Forløbet';

  @override
  String get tripMetricOdometer => 'Kilometertæller';

  @override
  String get tripStop => 'Stop optagelse';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Genoptag';

  @override
  String get tripBannerRecording => 'Optager tur';

  @override
  String get tripBannerPaused => 'Tur på pause — tryk for at genoptage';

  @override
  String get navConsumption => 'Forbrug';

  @override
  String get vehicleBaselineSectionTitle => 'Basisliniekalibrering';

  @override
  String get vehicleBaselineEmpty =>
      'Ingen prøver endnu — start en OBD2-tur for at begynde at lære dette køretøjs brændstofprofil.';

  @override
  String get vehicleBaselineProgress =>
      'Lært fra prøver på tværs af køresituationer.';

  @override
  String get vehicleBaselineReset => 'Nulstil køresituations-basislinje';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Nulstil køresituations-basislinje?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Dette sletter alle lærte prøver for dette køretøj. Du vender tilbage til kolstarts-standarderne, indtil nye ture genopretter profilen.';

  @override
  String get vehicleBaselineShowDetails => 'Vis situationsspecifik opdeling';

  @override
  String get vehicleBaselineHideDetails => 'Skjul situationsspecifik opdeling';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Ikke registreret endnu: $situations. Disse køresituationer har stadig 0 prøver, så basislinjen er ufuldstændig.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Ingen adapter parret. Par en, så appen kan genoprette forbindelsen automatisk næste gang.';

  @override
  String get vehicleAdapterUnnamed => 'Ukendt adapter';

  @override
  String get vehicleAdapterPair => 'Par adapter';

  @override
  String get vehicleAdapterForget => 'Glem adapter';

  @override
  String get achievementsTitle => 'Præstationer';

  @override
  String get achievementFirstTrip => 'Første tur';

  @override
  String get achievementFirstTripDesc => 'Optag din første OBD2-tur.';

  @override
  String get achievementFirstFillUp => 'Første tankning';

  @override
  String get achievementFirstFillUpDesc => 'Log din første tankning.';

  @override
  String get achievementTenTrips => '10 ture';

  @override
  String get achievementTenTripsDesc => 'Optag 10 OBD2-ture.';

  @override
  String get achievementZeroHarsh => 'Blød fører';

  @override
  String get achievementZeroHarshDesc =>
      'Gennemfør en tur på 10 km eller mere uden hård opbremsning eller acceleration.';

  @override
  String get achievementEcoWeek => 'Eco-uge';

  @override
  String get achievementEcoWeekDesc =>
      'Kør 7 dage i træk med mindst én blød tur hver dag.';

  @override
  String get achievementPriceWin => 'Prisvinder';

  @override
  String get achievementPriceWinDesc =>
      'Log en tankning, der slår stationens 30-dages gennemsnit med 5 % eller mere.';

  @override
  String get syncBaselinesToggleTitle => 'Del lærte køretøjsprofiler';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Upload forbrugsbasislinjer pr. køretøj, så en anden enhed kan genbruge dem.';

  @override
  String get obd2StatusConnected => 'OBD2-adapter: tilsluttet';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-tilladelse påkrævet';

  @override
  String get obd2StatusConnectedBody => 'Klar til at optage en tur.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Tildel Bluetooth-tilladelse i systemindstillinger for at genoprette forbindelsen automatisk.';

  @override
  String get obd2StatusNoAdapter => 'Ingen adapter parret';

  @override
  String get obd2StatusForget => 'Glem adapter';

  @override
  String get tripHistoryTitle => 'Turhistorik';

  @override
  String get tripHistoryEmptyTitle => 'Ingen ture endnu';

  @override
  String get tripHistoryUnknownDate => 'Ukendt dato';

  @override
  String get situationIdle => 'Tomgang';

  @override
  String get situationStopAndGo => 'Stop & kør';

  @override
  String get situationUrban => 'By';

  @override
  String get situationHighway => 'Motorvej';

  @override
  String get situationDecel => 'Decelererer';

  @override
  String get situationClimbing => 'Stigning / lastet';

  @override
  String get situationColdStart => 'Koldstart';

  @override
  String get situationSustainedLoad => 'Vedvarende belastning / bugsering';

  @override
  String get situationPartialDecel => 'Frihjul';

  @override
  String get situationHardAccel => 'Hård acceleration';

  @override
  String get situationFuelCut => 'Brændstofafskæring — kystning';

  @override
  String get tripSaveRecording => 'Gem tur';

  @override
  String get tripSummaryAutoSaved => 'Tur gemt automatisk';

  @override
  String get tripSummaryDone => 'Færdig';

  @override
  String get tripSummaryDelete => 'Slet denne tur';

  @override
  String get vehicleFuelNotSet => 'Ikke angivet';

  @override
  String get wizardVehicleDefaultBadge => 'Standard';

  @override
  String get wizardProfileChoiceHint =>
      'Vælg, hvordan du vil bruge appen. Du kan ændre dette senere i Indstillinger.';

  @override
  String get wizardProfileChoiceFooter =>
      'Du kan ændre dit valg til enhver tid fra Indstillinger → Brugstilstand.';

  @override
  String get wizardProfileBasicName => 'Basis';

  @override
  String get wizardProfileBasicDescription =>
      'Billigste brændstof- og EV-opladningspriser i nærheden. Favoritter og prisadvarsler.';

  @override
  String get wizardProfileMediumName => 'Mellem';

  @override
  String get wizardProfileMediumDescription =>
      'Alt i Basis, plus spor dine brændstoftankninger og EV-opladning manuelt.';

  @override
  String get wizardProfileFullName => 'Fuld';

  @override
  String get wizardProfileFullDescription =>
      'Alt i Mellem, plus automatisk OBD2-turoptagelse, kørscorer og loyalitetskort.';

  @override
  String get wizardProfileCustomName => 'Brugerdefineret';

  @override
  String get useModeSectionHint =>
      'Tilpas appen til den måde, du faktisk bruger den. Valg af en forudindstilling aktiverer det tilsvarende sæt funktioner.';

  @override
  String get useModeCustomSettingsDescription =>
      'Din funktionsmix matcher ingen forudindstilling. Vælg en ovenfor for at overskrive, eller bliv ved med at tilpasse individuelle funktioner i afsnittet nedenfor.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Brugstilstand sat til $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Standardkøretøj (valgfrit)';

  @override
  String get profileDefaultVehicleNone => 'Intet standard';

  @override
  String get profileFuelFromVehicleHint =>
      'Brændstoftype stammer fra dit standardkøretøj. Ryd køretøjet for at vælge brændstof direkte.';

  @override
  String get consumptionNoVehicleTitle => 'Tilføj et køretøj først';

  @override
  String get consumptionNoVehicleBody =>
      'Tankninger knyttes til et køretøj. Tilføj din bil for at begynde at logge forbrug.';

  @override
  String get vehicleAdd => 'Tilføj køretøj';

  @override
  String get vehicleAddTitle => 'Tilføj køretøj';

  @override
  String get vehicleEditTitle => 'Rediger køretøj';

  @override
  String get vehicleDeleteTitle => 'Slet køretøj?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Fjern \"$name\" fra dine profiler?';
  }

  @override
  String get vehicleNameLabel => 'Navn';

  @override
  String get vehicleNameHint => 'f.eks. Min Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Forbrænding';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Elektrisk';

  @override
  String get vehicleEvSectionTitle => 'Elektrisk';

  @override
  String get vehicleCombustionSectionTitle => 'Forbrænding';

  @override
  String get vehicleBatteryLabel => 'Batterikapacitet (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maks. opladningseffekt (kW)';

  @override
  String get vehicleConnectorsLabel => 'Understøttede stik';

  @override
  String get vehicleMinSocLabel => 'Min. SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks. SoC %';

  @override
  String get vehicleTankLabel => 'Tankkapacitet (L)';

  @override
  String get vehiclePowerLabel => 'Motoreffekt (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps hk';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Foretrukket brændstof';

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
  String get connectorThreePin => '3-benet';

  @override
  String get evShowOnMap => 'Vis EV-stationer';

  @override
  String get evAvailableOnly => 'Kun tilgængelige';

  @override
  String get evMinPower => 'Min. effekt';

  @override
  String get evStatusAvailable => 'Tilgængelig';

  @override
  String get evStatusOccupied => 'Optaget';

  @override
  String get evStatusOutOfOrder => 'Ude af drift';

  @override
  String get evStatusPartial => 'Delvist tilgængelig';

  @override
  String get openOnlyFilter => 'Kun åbne';

  @override
  String get saveAsDefaults => 'Gem som mine standarder';

  @override
  String get criteriaSavedToProfile => 'Gemt som standarder';

  @override
  String get updatingFavorites => 'Opdaterer dine favoritter...';

  @override
  String get fetchingLatestPrices => 'Henter de seneste priser';

  @override
  String get noDataAvailable => 'Ingen data';

  @override
  String get searchToSeeMap => 'Søg for at se stationer på kortet';

  @override
  String get evPowerAny => 'Alle';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Placering';

  @override
  String get sectionSetupDataSources => 'Opsætning og datakilder';

  @override
  String get sectionFeaturesUsage => 'Funktioner og brug';

  @override
  String get sectionAccountSync => 'Konto og synkronisering';

  @override
  String get sectionAppearanceWidgets => 'Udseende og widgets';

  @override
  String get sectionPrivacyData => 'Privatliv og data';

  @override
  String get sectionAdvancedDeveloper => 'Avanceret og udvikler';

  @override
  String get tooltipBack => 'Tilbage';

  @override
  String get tooltipClose => 'Luk';

  @override
  String get tooltipShare => 'Del';

  @override
  String get tooltipClearSearch => 'Ryd søgeinput';

  @override
  String get minimalDriveInstantConsumption => 'Aktuelt forbrug';

  @override
  String get minimalDriveBehaviour => 'Kørestil';

  @override
  String get coachingShiftUp => 'Skift op';

  @override
  String get coachingShiftDown => 'Skift ned';

  @override
  String get coachingEasePedal => 'Slip speederen';

  @override
  String get coachingVoiceHardAcceleration =>
      'Tag det roligt med speederpedaleren';

  @override
  String get coachingVoiceHarshBraking => 'Prøv at bremse blødere';

  @override
  String get coachingVoiceShiftUp => 'Skift op en gear for at spare brændstof';

  @override
  String get coachingVoiceShiftDown => 'Skift ned, motoren kæmper';

  @override
  String get coachingVoiceEasePedal =>
      'Løft lidt af pedalen for at reducere dit brændstofforbrug';

  @override
  String get coachingVoiceLiftOff => 'Slip speederpedaleren og frihjul';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Kig længere frem og løft af tidligere';

  @override
  String get coachingVoiceSmoothAccel => 'Accelerér mere jævnt';

  @override
  String get coachingVoiceSharpCorner => 'Tag svingene lidt blødere';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Det var en meget hård opbremsning — hold længere afstand';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Meget hård acceleration — det bruger for alvor brændstof';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Meget skarpt sving — langsomt ind, blødt ud';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount hårde manøvrer.',
      one: 'Én hård manøvre.',
      zero: 'Pænt og blødt — ingen hårde manøvrer.',
    );
    return 'Tur gemt: $distanceKm kilometer, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value liter per 100 kilometer';
  }

  @override
  String get voiceCoachingSettingTitle => 'Mundtlig kørecoaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hør talte tips under kørslen — hård acceleration, hård opbremsning og gear-hints';

  @override
  String get tooltipUseGps => 'Brug GPS-placering';

  @override
  String get tooltipShowPassword => 'Vis adgangskode';

  @override
  String get tooltipHidePassword => 'Skjul adgangskode';

  @override
  String get evConnectorsLabel => 'Tilgængelige stik';

  @override
  String get evConnectorsNone => 'Ingen stikoplysninger';

  @override
  String get switchToEmail => 'Skift til e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Behold data, tilføj login fra andre enheder';

  @override
  String get switchToAnonymousAction => 'Skift til anonym';

  @override
  String get switchToAnonymousSubtitle =>
      'Behold lokale data, brug ny anonym session';

  @override
  String get linkDevice => 'Tilknyt enhed';

  @override
  String get shareDatabase => 'Del database';

  @override
  String get disconnectAction => 'Afbryd';

  @override
  String get disconnectSubtitle => 'Stop synkronisering (lokale data bevares)';

  @override
  String get deleteAccountAction => 'Slet konto';

  @override
  String get deleteAccountSubtitle => 'Fjern alle serverdata permanent';

  @override
  String get localOnly => 'Kun lokalt';

  @override
  String get localOnlySubtitle =>
      'Valgfrit: synkroniser favoritter, advarsler og bedømmelser på tværs af enheder';

  @override
  String get tankSyncSchemaOutdatedTitle => 'Skydatabasen skal opdateres';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Dit selvhostede TankSync-skema er forældet — nogle data kan ikke synkroniseres. Åbn synkroniseringsguiden, og kør opdaterings-SQL\'en på dit Supabase-projekt.';

  @override
  String get setupCloudSync => 'Opsæt cloud-synkronisering';

  @override
  String get disconnectTitle => 'Afbryd TankSync?';

  @override
  String get disconnectBody =>
      'Cloud-synkronisering deaktiveres. Dine lokale data (favoritter, advarsler, historik) bevares på denne enhed. Serverdata slettes ikke.';

  @override
  String get deleteAccountTitle => 'Slet konto?';

  @override
  String get deleteAccountBody =>
      'Dette sletter permanent alle dine data fra serveren (favoritter, advarsler, bedømmelser, ruter). Lokale data på denne enhed bevares.\n\nDette kan ikke fortrydes.';

  @override
  String get switchToAnonymousTitle => 'Skift til anonym?';

  @override
  String get switchToAnonymousBody =>
      'Du logges ud af din e-mailkonto og fortsætter med en ny anonym session.\n\nDine lokale data (favoritter, advarsler) bevares på denne enhed og synkroniseres til den nye anonyme konto.';

  @override
  String get switchAction => 'Skift';

  @override
  String get helpBannerCriteria =>
      'Dine profilstandarder er forudfyldt. Juster kriterier nedenfor for at finjustere din søgning.';

  @override
  String get helpBannerAlerts =>
      'Angiv en pristærskel for en station. Du får besked, når prisen falder under den. Kontroller kører hvert 30. minut.';

  @override
  String get helpBannerConsumption =>
      'Log hver tankning for at spore dit virkelige forbrug og CO₂-aftryk. Stryg til venstre for at slette en post.';

  @override
  String get helpBannerVehicles =>
      'Tilføj dine køretøjer, så tankninger og brændstofpræferencer udfyldes korrekt som standard. Det første køretøj bliver dit standardkøretøj.';

  @override
  String get syncNow => 'Synkroniser nu';

  @override
  String get onboardingPreferencesTitle => 'Dine præferencer';

  @override
  String get onboardingZipHelper => 'Bruges når GPS ikke er tilgængeligt';

  @override
  String get onboardingRadiusHelper => 'Større radius = flere resultater';

  @override
  String get onboardingPrivacy =>
      'Disse indstillinger gemmes kun på din enhed og deles aldrig.';

  @override
  String get onboardingLandingTitle => 'Startskærm';

  @override
  String get onboardingLandingHint =>
      'Vælg hvilken skærm der åbnes, når du starter appen.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Lad appen være — men luk den ikke.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Åbn Sparkilo én gang efter hver genstart.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple vækker Sparkilo kun, når du har åbnet den mindst én gang siden telefonen blev genstartet. Derefter optages dine ture automatisk.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Stryg ikke Sparkilo væk i app-skifteren.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Tvangsluk\" fortæller iOS at stoppe med at genstarte appen. Dine ture stopper med at blive optaget, indtil du åbner Sparkilo igen.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Når iOS beder om \"Altid\" placering, sig ja.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Reserveløsningen, der optager din tur, når OBD2-adapteren er langsom, kræver baggrundslokation. Vi deler den aldrig.';

  @override
  String get scanReceipt => 'Scan kvittering';

  @override
  String get brandFilterHighway => 'Motorvej';

  @override
  String get ratingModeLocal => 'Lokal';

  @override
  String get ratingModePrivate => 'Privat';

  @override
  String get ratingModeShared => 'Delt';

  @override
  String get ratingDescLocal => 'Bedømmelser gemt kun på denne enhed';

  @override
  String get ratingDescPrivate =>
      'Synkroniseret med din database (ikke synlig for andre)';

  @override
  String get ratingDescShared => 'Synlig for alle brugere af din database';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API-nøgle ikke konfigureret. Tilføj en i Indstillinger for at søge efter EV-ladestationer.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Dataleverandøren ($host) serverer et udløbet eller ugyldigt TLS-certifikat. Appen kan ikke indlæse data fra denne kilde, indtil leverandøren retter det. Kontakt venligst $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed ikke tilgængelig. Bruger $current.';
  }

  @override
  String get errorTitleApiKey => 'API-nøgle påkrævet';

  @override
  String get errorTitleLocation => 'Placering ikke tilgængelig';

  @override
  String get errorHintNoStations =>
      'Prøv at øge søgeradius eller søg et andet sted.';

  @override
  String get errorHintApiKey => 'Konfigurér din API-nøgle i Indstillinger.';

  @override
  String get errorHintConnection =>
      'Tjek din internetforbindelse og prøv igen.';

  @override
  String get errorHintRouting =>
      'Ruteberegning mislykkedes. Tjek din internetforbindelse og prøv igen.';

  @override
  String get errorHintFallback =>
      'Prøv igen eller søg via postnummer / bynavn.';

  @override
  String get alertsLoadErrorTitle => 'Kunne ikke indlæse dine advarsler';

  @override
  String get detailsLabel => 'Detaljer';

  @override
  String get remove => 'Fjern';

  @override
  String get showKey => 'Vis nøgle';

  @override
  String get hideKey => 'Skjul nøgle';

  @override
  String get syncOptionalTitle => 'TankSync er valgfrit';

  @override
  String get syncOptionalDescription =>
      'Din app virker fuldt ud uden cloud-synkronisering. TankSync lader dig synkronisere favoritter, advarsler og bedømmelser på tværs af enheder via Supabase (gratis niveau tilgængeligt).';

  @override
  String get syncHowToConnectQuestion => 'Hvordan vil du oprette forbindelse?';

  @override
  String get syncCreateOwnTitle => 'Opret min egen database';

  @override
  String get syncCreateOwnSubtitle =>
      'Gratis Supabase-projekt — vi guider dig trin for trin';

  @override
  String get syncJoinExistingTitle => 'Tilslut en eksisterende database';

  @override
  String get syncJoinExistingSubtitle =>
      'Scan QR-kode fra databaseejeren eller indsæt legitimationsoplysninger';

  @override
  String get syncChooseAccountType => 'Vælg din kontotype';

  @override
  String get syncAccountTypeAnonymous => 'Anonym';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Øjeblikkelig, ingen e-mail nødvendig. Data knyttet til denne enhed.';

  @override
  String get syncAccountTypeEmail => 'E-mailkonto';

  @override
  String get syncAccountTypeEmailDesc =>
      'Log ind fra enhver enhed. Gendan data, hvis telefonen går tabt.';

  @override
  String get syncHaveAccountSignIn => 'Har du allerede en konto? Log ind';

  @override
  String get syncCreateNewAccount => 'Opret ny konto';

  @override
  String get syncTestConnection => 'Test forbindelse';

  @override
  String get syncTestingConnection => 'Tester...';

  @override
  String get syncConnectButton => 'Opret forbindelse';

  @override
  String get syncConnectingButton => 'Opretter forbindelse...';

  @override
  String get syncDatabaseReady => 'Database klar!';

  @override
  String get syncDatabaseNeedsSetup => 'Database kræver opsætning';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Mangler';

  @override
  String get syncSqlEditorInstructions =>
      'Kopiér SQL\'en nedenfor og kør den i din Supabase SQL-editor (Dashboard → SQL Editor → New Query → Indsæt → Kør)';

  @override
  String get syncCopySqlButton => 'Kopiér SQL til udklipsholder';

  @override
  String get syncRecheckSchemaButton => 'Tjek skema igen';

  @override
  String get syncSchemaOutdated =>
      'Dit TankSync-skema er forældet — kør opsætnings-SQL\'en nedenfor igen for at aktivere de nyeste synkroniserede funktioner.';

  @override
  String get syncDoneButton => 'Færdig';

  @override
  String syncSignedInAs(String email) {
    return 'Logget ind som $email';
  }

  @override
  String get syncEmailDescription =>
      'Dine data synkroniseres på tværs af alle enheder med denne e-mail.';

  @override
  String get syncSwitchToAnonymousTitle => 'Skift til anonym';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Fortsæt uden e-mail, ny anonym session';

  @override
  String get syncGuestDescription => 'Anonym, ingen e-mail nødvendig.';

  @override
  String get syncOrDivider => 'eller';

  @override
  String get syncHowToSyncQuestion => 'Hvordan vil du synkronisere?';

  @override
  String get syncOfflineDescription =>
      'Din app virker fuldt ud offline. Cloud-synkronisering er valgfrit.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Del favoritter og bedømmelser med alle brugere';

  @override
  String get syncModePrivateTitle => 'Privat database';

  @override
  String get syncModePrivateSubtitle => 'Din egen Supabase — fuld datakontrol';

  @override
  String get syncModeGroupTitle => 'Tilslut en gruppe';

  @override
  String get syncModeGroupSubtitle => 'Familie eller venners delte database';

  @override
  String get syncPrivacyShared => 'Delt';

  @override
  String get syncPrivacyPrivate => 'Privat';

  @override
  String get syncPrivacyGroup => 'Gruppe';

  @override
  String get syncStayOfflineButton => 'Forbliv offline';

  @override
  String get syncSuccessTitle => 'Forbindelsen oprettet!';

  @override
  String get syncSuccessDescription => 'Dine data synkroniseres nu automatisk.';

  @override
  String get syncWizardTitleConnect => 'Opret forbindelse til TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Din database';

  @override
  String get syncSetupTitleJoinGroup => 'Tilslut en gruppe';

  @override
  String get syncSetupTitleAccount => 'Din konto';

  @override
  String get syncWizardBack => 'Tilbage';

  @override
  String get syncWizardNext => 'Næste';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Trin $current af $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Opret et Supabase-projekt';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tryk på \"Åbn Supabase\" nedenfor\n2. Opret en gratis konto (hvis du ikke har en)\n3. Klik på \"New Project\"\n4. Vælg et navn og region\n5. Vent ~2 minutter på at det starter';

  @override
  String get syncWizardOpenSupabase => 'Åbn Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Aktivér anonyme logins';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. I dit Supabase-dashboard:\n   Authentication → Providers\n2. Find \"Anonymous Sign-ins\"\n3. Slå det TIL\n4. Klik \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Åbn godkendelsesindstillinger';

  @override
  String get syncWizardCopyCredentialsTitle =>
      'Kopiér dine legitimationsoplysninger';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Gå til Settings → API i dit dashboard\n2. Kopiér \"Project URL\"\n3. Kopiér \"anon public\"-nøglen\n4. Indsæt dem nedenfor';

  @override
  String get syncWizardOpenApiSettings => 'Åbn API-indstillinger';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Tilslut en eksisterende database';

  @override
  String get syncWizardScanQrCode => 'Scan QR-kode';

  @override
  String get syncWizardAskOwnerQr =>
      'Bed databaseejeren om at vise dig deres QR-kode\n(Indstillinger → TankSync → Del)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Bed databaseejeren om at vise deres QR-kode';

  @override
  String get syncWizardEnterManuallyTitle => 'Indtast manuelt';

  @override
  String get syncWizardOrEnterManually => 'eller indtast manuelt';

  @override
  String get syncWizardUrlHelperText =>
      'Mellemrum og linjeskift fjernes automatisk';

  @override
  String get syncCredentialsPrivateHint =>
      'Angiv dine Supabase-projektlegitimationsoplysninger. Du kan finde dem i dit dashboard under Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Database-URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Adgangsnøgle';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Adgangskode';

  @override
  String get authConfirmPasswordLabel => 'Bekræft adgangskode';

  @override
  String get authPleaseEnterEmail => 'Angiv din e-mail';

  @override
  String get authInvalidEmail => 'Ugyldig e-mailadresse';

  @override
  String get authPasswordsDoNotMatch => 'Adgangskoderne stemmer ikke overens';

  @override
  String get authConnectAnonymously => 'Opret forbindelse anonymt';

  @override
  String get authCreateAccountAndConnect => 'Opret konto og opret forbindelse';

  @override
  String get authSignInAndConnect => 'Log ind og opret forbindelse';

  @override
  String get authAnonymousSegment => 'Anonym';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Øjeblikkelig adgang, ingen e-mail nødvendig. Data knyttet til denne enhed.';

  @override
  String get authEmailDescription =>
      'Log ind fra enhver enhed. Gendan dine data, hvis din telefon går tabt.';

  @override
  String get authSyncAcrossDevices =>
      'Synkroniser data automatisk på tværs af alle dine enheder.';

  @override
  String get authNewHereCreateAccount => 'Ny her? Opret konto';

  @override
  String get linkDeviceScreenTitle => 'Tilknyt enhed';

  @override
  String get linkDeviceThisDeviceLabel => 'Denne enhed';

  @override
  String get linkDeviceShareCodeHint => 'Del denne kode med din anden enhed:';

  @override
  String get linkDeviceNotConnected => 'Ikke tilsluttet';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopiér kode';

  @override
  String get linkDeviceImportSectionTitle => 'Importér fra en anden enhed';

  @override
  String get linkDeviceImportDescription =>
      'Indtast enhedskoden fra din anden enhed for at importere dens favoritter, advarsler, køretøjer og forbrugslog. Hver enhed beholder sin egen profil og standarder.';

  @override
  String get linkDeviceCodeFieldLabel => 'Enhedskode';

  @override
  String get linkDeviceCodeFieldHint => 'Indsæt UUID fra den anden enhed';

  @override
  String get linkDeviceImportButton => 'Importér data';

  @override
  String get linkDeviceHowItWorksTitle => 'Sådan virker det';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. På enhed A: kopiér enhedskoden ovenfor\n2. På enhed B: indsæt den i feltet \"Enhedskode\"\n3. Tryk på \"Importér data\" for at flette favoritter, advarsler, køretøjer og forbrugslogs\n4. Begge enheder vil have alle kombinerede data\n\nHver enhed beholder sin egen anonyme identitet og sin egen profil (foretrukket brændstof, standardkøretøj, startskærm). Data flettes, ikke flyttes.';

  @override
  String get vehicleSetActive => 'Angiv som aktiv';

  @override
  String get swipeHide => 'Skjul';

  @override
  String get yourRating => 'Din bedømmelse';

  @override
  String get noStorageUsed => 'Intet lager brugt';

  @override
  String get aboutReportBug => 'Rapporter en fejl / Foreslå en funktion';

  @override
  String get aboutSupportProject => 'Støt dette projekt';

  @override
  String get aboutSupportDescription =>
      'Denne app er gratis, open source og har ingen annoncer. Hvis du finder den nyttig, kan du overveje at støtte udvikleren.';

  @override
  String get reportIssueTitle => 'Rapporter et problem';

  @override
  String get enterCorrection => 'Angiv venligst rettelsen';

  @override
  String get reportNoBackendAvailable =>
      'Rapporten kunne ikke sendes: ingen rapporteringstjeneste er konfigureret for dette land. Aktivér TankSync i Indstillinger for at sende fællesskabsrapporter.';

  @override
  String get correctName => 'Korrekt stationsnavn';

  @override
  String get correctAddress => 'Korrekt adresse';

  @override
  String get wrongE85Price => 'Forkert E85-pris';

  @override
  String get wrongE98Price => 'Forkert Super 98-pris';

  @override
  String get wrongLpgPrice => 'Forkert LPG-pris';

  @override
  String get wrongStationName => 'Forkert stationsnavn';

  @override
  String get wrongStationAddress => 'Forkert adresse';

  @override
  String get independentStation => 'Uafhængig station';

  @override
  String get serviceRemindersSection => 'Servicepåmindelser';

  @override
  String get serviceRemindersEmpty =>
      'Ingen påmindelser endnu — vælg en forudindstilling ovenfor.';

  @override
  String get addServiceReminder => 'Tilføj påmindelse';

  @override
  String get serviceReminderPresetOil => 'Olie (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Olieskift';

  @override
  String get serviceReminderPresetTires => 'Dæk (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Dæk';

  @override
  String get serviceReminderPresetInspection => 'Eftersyn (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Eftersyn';

  @override
  String get serviceReminderLabel => 'Mærkat';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Seneste service';

  @override
  String get serviceReminderMarkDone => 'Markér som udført';

  @override
  String get serviceReminderDueTitle => 'Service forfalden';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label er forfalden — $kmOver km over intervallet.';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '$label skal udføres nu.';
  }

  @override
  String get vinConfirmTitle => 'Er dette din bil?';

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
      'Delvis info (offline). Du kan redigere nedenfor.';

  @override
  String get vinDecodeError => 'Kunne ikke afkode dette VIN';

  @override
  String get vinInvalidFormat => 'Ugyldigt VIN-format';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2-forbindelse mistet — optagelse sat på pause';

  @override
  String get obd2PauseBannerResume => 'Genoptag optagelse';

  @override
  String get obd2PauseBannerEnd => 'Afslut optagelse';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Optager med GPS — OBD2 genforbinder';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Optager med GPS — venter på OBD2-adapteren';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Forbrugskalibrering opdateret for $vehicleName — nøjagtighed forbedret med $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Nulstil volumetrisk effektivitet?';

  @override
  String get veResetConfirmBody =>
      'Dette vil kassere den lærte volumetriske effektivitet (η_v) og gendanne standardværdien (0.85). Turbaserede brændstofstrømsestimater falder tilbage til fabrikantens konstant, indtil kalibroren indsamler nye prøver fra kommende ture.';

  @override
  String get alertsStationSectionTitle => 'Stationsalarmer';

  @override
  String get alertsStationAdd => 'Tilføj en stationsalarm';

  @override
  String get alertsRadiusSectionTitle => 'Radiusadvarsler';

  @override
  String get alertsRadiusAdd => 'Tilføj radiusadvarsel';

  @override
  String get alertsRadiusEmptyTitle => 'Ingen radiusadvarsler endnu';

  @override
  String get alertsRadiusEmptyCta => 'Opret en radiusadvarsel';

  @override
  String get alertsRadiusCreateTitle => 'Opret radiusadvarsel';

  @override
  String get alertsRadiusLabelHint => 'Mærkat (f.eks. Hjemme diesel)';

  @override
  String get alertsRadiusFuelType => 'Brændstoftype';

  @override
  String get alertsRadiusKm => 'Radius (km)';

  @override
  String get alertsRadiusCenterGps => 'Brug min placering';

  @override
  String get alertsRadiusCenterPostalCode => 'Postnummer';

  @override
  String get alertsRadiusSave => 'Gem';

  @override
  String get alertsRadiusCancel => 'Annuller';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radiusalarm \"$name\" slettet';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 tilsluttet: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Par en OBD2-adapter';

  @override
  String get fillUpSavedSnackbar => 'Tankning gemt';

  @override
  String get radiusAlertsEntryTitle => 'Radiusadvarsler og statistik';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Få besked, når priserne falder i nærheden';

  @override
  String get notFoundTitle => 'Side ikke fundet';

  @override
  String notFoundBody(String location) {
    return '\"$location\" ikke fundet.';
  }

  @override
  String get notFoundHomeButton => 'Hjem';

  @override
  String get consumptionTabHiddenNotice =>
      'Forbrugsfanen er skjult af dine profilindstillinger.';

  @override
  String get swipeBetweenTabsHint =>
      'Tip: stryg til venstre eller højre for at skifte mellem faner.';

  @override
  String get discardChangesTitle => 'Kassér ændringer?';

  @override
  String get discardChangesBody =>
      'Du har ikke-gemte ændringer. Hvis du forlader nu, kasseres de.';

  @override
  String get discardChangesConfirm => 'Kassér';

  @override
  String get discardChangesKeepEditing => 'Bliv ved med at redigere';

  @override
  String get tankSyncSectionSubtitle =>
      'Cloud-synkronisering på tværs af dine enheder';

  @override
  String get mapUnavailable => 'Kort utilgængeligt';

  @override
  String get routeNameHintExample => 'f.eks. Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Aktuel';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API-nøgle';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API-nøgle';

  @override
  String get tapToUpdateGpsPosition => 'Tryk for at opdatere GPS-position';

  @override
  String get nameLabel => 'Navn';

  @override
  String get obd2ErrorPermissionDenied =>
      'Bluetooth-tilladelse er påkrævet for at oprette forbindelse til en OBD2-adapter.';

  @override
  String get obd2ErrorBluetoothOff => 'Slå Bluetooth til, og prøv igen.';

  @override
  String get obd2ErrorScanTimeout =>
      'Ingen OBD2-adapter fundet i nærheden. Kontroller, at den er tilsluttet og tændt.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2-adapteren svarede ikke. Slå tændingen til, og prøv igen.';

  @override
  String get obd2ErrorEngineOff =>
      'Ingen data fra køretøjet — start motoren, og prøv igen.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2-adapteren sendte et ukendt svar. Den er muligvis inkompatibel — prøv en anden adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2-adapteren blev afbrudt. Tilslut igen, og prøv igen.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adapteren skal parres via Bluetooth. Træk adapteren ud, sæt den i igen, og prøv igen inden for 5 minutter.';

  @override
  String get onboardingExploreDemoData => 'Udforsk med demodata';

  @override
  String get achievementSmoothDriver => 'Blød stræk';

  @override
  String get achievementSmoothDriverDesc =>
      'Kør 5 ture i træk med en blød kørescore på 80 eller derover.';

  @override
  String get achievementColdStartAware => 'Koldstartsbevidst';

  @override
  String get achievementColdStartAwareDesc =>
      'Hold en hel måneds koldstartsbrændstofomkostning under 2 % af det samlede brændstof — kombiner korte ture.';

  @override
  String get achievementHighwayMaster => 'Motorvejsmester';

  @override
  String get achievementHighwayMasterDesc =>
      'Gennemfør en tur på 30 km+ i ensartet hastighed med en blød kørescore på 90 eller derover.';

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
    return '$fuelLabel faldet på tankstationer i nærheden';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count tankstationer faldet med op til $cents¢ inden for den seneste time';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count tankstationer ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count mere';
  }

  @override
  String alertsLastChecked(String when) {
    return 'Sidst tjekket: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Priserne er endnu ikke blevet tjekket i baggrunden';

  @override
  String get alertsIosBestEffortNote =>
      'På iPhone er tjek af alarmer efter bedste evne: iOS bestemmer, hvornår appen må tjekke priser i baggrunden, så en alarm kan komme for sent eller af og til slet ikke. Åbner du appen, køres der altid et nyt tjek.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Målpris ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Grænse ($currency/L)';
  }

  @override
  String get approachOverlaySection => 'Indflyvningsoverlay';

  @override
  String get approachRadiusLabel => 'Radius';

  @override
  String approachRadiusCaption(String km) {
    return 'Overlayet vokser og viser prisen, når du er inden for $km km fra en station';
  }

  @override
  String get approachPriceModeLabel => 'Vis pris for';

  @override
  String get approachPriceModeNearest => 'Nærmeste station';

  @override
  String get approachPriceModeCheapestInRadius => 'Billigste i radius';

  @override
  String get approachMinPollLabel => 'Min. opdatering';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Nedre grænse for hvor ofte overlayet opdaterer nærmeste station (hurtigere ved fart, aldrig tættere end $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Test af tilnærmelsesoverlay';

  @override
  String get approachTestStopButton => 'Stop test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktiv — overlay viser prisen for $station';
  }

  @override
  String get approachTestUnavailable =>
      'Tilføj en favoritstation for at teste tilnærmelsesoverlayet';

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Nærhed $percent%';
  }

  @override
  String get pipTapToRestore => 'Tryk for at åbne hele appen';

  @override
  String get authErrorNoNetwork =>
      'Ingen netværksforbindelse. Prøv igen senere.';

  @override
  String get authErrorInvalidCredentials =>
      'Ugyldig e-mail eller adgangskode. Tjek dine legitimationsoplysninger.';

  @override
  String get authErrorUserAlreadyExists =>
      'Denne e-mail er allerede registreret. Prøv at logge ind i stedet.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Tjek venligst din e-mail og bekræft din konto først.';

  @override
  String get authErrorGeneric => 'Login mislykkedes. Prøv igen.';

  @override
  String get authLinkEmailTitle => 'Tilknyt en e-mail';

  @override
  String get authLinkEmailSubtitle =>
      'Tilknyt en e-mail, så dine data synkroniseres på tværs af enheder. Dine nuværende favoritter og ture bliver på denne konto.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Du bruger en gæstekonto ($idPrefix…). Tilknyt en e-mail, så dine favoritter og ture synkroniseres til dine andre enheder.';
  }

  @override
  String get authConfirmationPending =>
      'Næsten færdig — tjek din e-mail, og klik på linket for at fuldføre tilknytningen. Dine data er allerede gemt på denne konto.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Baggrundslokation — kun til automatisk optagelse';

  @override
  String get autoRecordConsentExplanationTitle => 'Om denne tilladelse';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatisk optagelse kræver baggrundslokation for at registrere, når du begynder at køre, mens appen er lukket. Denne tilladelse bruges kun af automatisk optagelse — stationssøgning og kortcentrering bruger en separat forgrundslokationstilladelse.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Forstået';

  @override
  String get autoRecordConsentExplanationTooltip => 'Hvad betyder dette?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Tryk for at administrere i systemindstillinger';

  @override
  String get autoRecordSectionTitle => 'Automatisk optagelse';

  @override
  String get autoRecordToggleLabel => 'Optag ture automatisk';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatisk optagelse aktiveres næste gang du sætter dig ind i bilen.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Par en OBD2-adapter for at aktivere automatisk optagelse.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Tillad baggrundslokation, så automatisk optagelse fortsætter med skærmen slukket.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Par en adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Starthastighed (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Forsinkelse ved gem efter frakobling (sekunder)';

  @override
  String get autoRecordBackgroundLocationLabel => 'Baggrundslokation tilladt';

  @override
  String get autoRecordBackgroundLocationRequest => 'Anmod om tilladelse';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Hvorfor \"Tillad hele tiden\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatisk optagelse streamer GPS-koordinater fra OBD-II-forgrundsservicen, mens skærmen er slukket, så din turruté forbliver præcis. Android kræver indstillingen \"Tillad hele tiden\" for at det fortsat virker, efter enheden låser.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Åbn indstillinger';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Lokationstilladelse kræves';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Kunne ikke anmode om baggrundslokation';

  @override
  String get aclWakeNotificationTitle => 'Bilen er forbundet';

  @override
  String get aclWakeNotificationBody =>
      'Tryk for at åbne Sparkilo — turoptagelsen kan starte.';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Par en adapter i afsnittet nedenfor for at aktivere automatisk optagelse';

  @override
  String get exportBackupReady => 'Sikkerhedskopi klar — vælg en destination';

  @override
  String get exportBackupFailed =>
      'Eksport af sikkerhedskopi mislykkedes — prøv igen';

  @override
  String get backupExportProgress => 'Eksporterer din sikkerhedskopi…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Gemt i Downloads som $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Gendan sikkerhedskopi';

  @override
  String get restoreBackupDialogBody =>
      'Flet tilføjer og opdaterer poster fra sikkerhedskopien og beholder alt, der allerede findes på denne enhed. Erstat sletter alle nuværende data først og gendanner derefter kun sikkerhedskopien — dette kan ikke fortrydes.';

  @override
  String get restoreBackupMergeAction => 'Flet';

  @override
  String get restoreBackupReplaceAction => 'Erstat alt';

  @override
  String get restoreBackupEmpty =>
      'Sikkerhedskopi gendannet — den indeholdt ingen poster';

  @override
  String get restoreBackupCorrupt =>
      'Gendannelse mislykkedes — denne fil er ikke en gyldig Tankstellen-sikkerhedskopi';

  @override
  String get restoreBackupFailed =>
      'Gendannelse mislykkedes — filen kunne ikke læses';

  @override
  String get backupImportProgress => 'Gendanner din sikkerhedskopi…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Flettet $vehicles køretøjer, $fillUps tankninger, $trips ture, $chargingLogs opladningslogge';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Erstattet alle data med $vehicles køretøjer, $fillUps tankninger, $trips ture, $chargingLogs opladningslogge';
  }

  @override
  String get brokenMapChipDisclaimer => 'MAP-aflæsninger mistænkelige';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-sensor aflæser forkert — brændstofaflæsninger kan være 50–80% for lave. Prøv en anden adapter.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-sensor upålidelig. Viser tankningsgennemsnit i stedet for live brændstofrate.';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin% (verificeret)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-sensor-diagnostik';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Defekt-MAP-sandsynlighed: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observationer registreret';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verificeret ren';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Dette køretøjs MAP-sensor er endnu ikke observeret.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokerede adaptere';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Ingen adaptere er blokeret.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — markeret $percent% defekt';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Ryd';

  @override
  String get brokenMapRevPromptTitle => 'Giv gas';

  @override
  String get brokenMapRevPromptBody =>
      'Giv kort gas, så appen kan kontrollere, at MAP-sensoren reagerer.';

  @override
  String get brokenMapRevPromptConfirm => 'Færdig — jeg gav gas';

  @override
  String get calibrationAdvancedTitle => 'Avanceret kalibrering';

  @override
  String get calibrationDisplacementLabel => 'Motorvolumen (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrisk effektivitet (η_v)';

  @override
  String get calibrationAfrLabel => 'Luft-brændstof-forhold (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Brændstoftæthed (g/L)';

  @override
  String get calibrationSourceDetected => '(registreret fra VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(standard)';

  @override
  String get calibrationSourceManual => '(manuelt)';

  @override
  String get calibrationResetToDetected => 'Nulstil til registreret værdi';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibreret, $samples prøver)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (lærer, $samples prøver)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (standard — ingen fuldt fyld endnu)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples prøver';
  }

  @override
  String get calibrationResetLearner => 'Nulstil lærner';

  @override
  String get calibrationBasisAtkinson => 'Atkinson-cyklus';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turboladet + DI';

  @override
  String get calibrationBasisTurbo => 'Turboladet';

  @override
  String get calibrationBasisNaDi => 'Naturligt aspireret + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — $basis-standard)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'Dette køretøj rapporterer sit brændstofforbrug direkte (PID 5E), så kalibrering af volumetrisk virkningsgrad bruges ikke — dit forbrug måles, det modelleres ikke.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Din $makeModel er markeret som diesel, men matcher et benzinkatalogindgang. Tryk for at opdatere.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Opdatér';

  @override
  String get catalogResetAction => 'Nulstil fra køretøjsdatabasen';

  @override
  String get catalogResetConfirmTitle => 'Nulstil fra køretøjsdatabasen?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Dette erstatter tankstørrelse, motoreffekt og slagvolumen for dette køretøj med databasens værdier for $vehicle. Andre felter og din tankhistorik røres ikke.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'Ingen matchende post i køretøjsdatabasen for dette køretøj.';

  @override
  String get catalogResetDoneSnackbar =>
      'Køretøjsdata nulstillet fra databasen.';

  @override
  String get consumptionTabFuel => 'Brændstof';

  @override
  String get consumptionTabCharging => 'Opladning';

  @override
  String get noChargingLogsTitle => 'Ingen opladningslogs endnu';

  @override
  String get noChargingLogsSubtitle =>
      'Log din første opladningssession for at begynde at spore EUR/100 km og kWh/100 km.';

  @override
  String get addChargingLog => 'Log opladning';

  @override
  String get addChargingLogTitle => 'Log opladningssession';

  @override
  String get chargingKwh => 'Energi (kWh)';

  @override
  String get chargingCost => 'Samlet pris';

  @override
  String get chargingTimeMin => 'Opladningstid (min)';

  @override
  String get chargingStationName => 'Station (valgfrit)';

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
      'Kræver en tidligere log for at sammenligne';

  @override
  String get chargingLogButtonLabel => 'Log opladning';

  @override
  String get chargingCostTrendTitle => 'Opladningsomkostningstrend';

  @override
  String get chargingEfficiencyTitle => 'Effektivitet (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Ikke nok data endnu';

  @override
  String get confirmDeleteTitle => 'Slet?';

  @override
  String get confirmDeleteBody => 'Vil du virkelig slette dette?';

  @override
  String get consoFeatureGroupTitle => 'Forbrug';

  @override
  String get consoFeatureGroupDescription =>
      'Spor dit forbrug — manuelle tankninger eller automatisk OBD2-turoptagelse.';

  @override
  String get consoModeOff => 'Fra';

  @override
  String get consoModeFuel => 'Brændstof';

  @override
  String get consoModeFuelAndTrips => 'Brændstof + Ture';

  @override
  String get consoModeOffDescription =>
      'Ingen forbrugsfane og ingen forbrugsindstillingssektion.';

  @override
  String get consoModeFuelDescription =>
      'Kun manuelle tankninger. Nyttigt uden OBD2-adapter.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Tilføjer automatisk OBD2-turoptagelse. Kræver en parret adapter.';

  @override
  String get consoGroupVehicles => 'Køretøjer';

  @override
  String get consoGroupCoaching => 'Coaching under kørsel';

  @override
  String get consoGroupRewards => 'Belønninger og besparelser';

  @override
  String get consoGroupTroubleshooting => 'Fejlfinding';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Nøjagtighed: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Høj';

  @override
  String get consumptionAccuracyMedium => 'Middel';

  @override
  String get consumptionAccuracyLow => 'Lav';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Fuld kalibrering: optankninger plus ture optaget med OBD2. L/100 km-tallet følger virkeligheden inden for få procent.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Optankninger har forankret forbrugsmodellen, men ingen OBD2-tur er endnu indgået. Optag en med OBD2 tilsluttet for at nå høj nøjagtighed.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Kun GPS — ingen optankninger har endnu forankret forbrugsmodellen. Tilføj et par fulde optankninger for at forbedre nøjagtigheden.';

  @override
  String get moreActionsTooltip => 'Mere';

  @override
  String get exportBackupMenuLabel => 'Eksportér sikkerhedskopi';

  @override
  String get restoreBackupMenuLabel => 'Gendan sikkerhedskopi';

  @override
  String get carbonDashboardMenuLabel => 'CO₂-dashboard';

  @override
  String get settingsMenuLabel => 'Indstillinger';

  @override
  String get consumptionStatsPageTitle => 'Forbrugsstatistik';

  @override
  String get consumptionStatsComparisonTitle => 'Denne måned vs. sidste måned';

  @override
  String get consumptionStatsTrendsTitle => 'Udvikling over tid';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Registrér tankninger over mindst to måneder for at sammenligne.';

  @override
  String get consumptionStatsPricePerLiter => 'Gns. pris/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Liter pr. måned';

  @override
  String get consumptionStatsChartSpend => 'Udgifter pr. måned';

  @override
  String get consumptionStatsChartPricePerLiter => 'Pris pr. liter';

  @override
  String get consumptionStatsChartConsumption => 'L/100 km pr. måned';

  @override
  String get fuelCompareSectionTitle =>
      'Køreomkostninger, brændstof for brændstof';

  @override
  String get fuelComparePricePerLitre => 'Betalt pr. liter';

  @override
  String get fuelCompareCostPer100km => 'Pris pr. 100 km';

  @override
  String get fuelCompareDistance => 'Målt distance';

  @override
  String get fuelCompareLitres => 'Forbrugte liter';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner er dit billigste brændstof at køre på';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser koster $amount mere pr. 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel slår $rival under $price pr. liter';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Balancepunktet beregnes ud fra hvert brændstofs målte forbrug og flytter sig derfor med din kørsel.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Liter og pris kan pege hver sin vej: et brændstof kan bruge færre liter pr. 100 km og alligevel koste mere pr. kilometer, fordi literprisen er en anden. Prisen pr. kilometer afgør sagen.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fulde tanke',
      one: 'én fuld tank',
    );
    return 'Foreløbig — baseret på $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fulde tanke',
      one: 'én fuld tank',
    );
    return 'Baseret på $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 pr. 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner er dit brændstof med lavest udledning';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel koster $money mere pr. 1000 km, men udleder $co2 mindre CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel er både billigere og renere end $rival';
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
    return 'Dine $distance på $fuel udledte $actual i stedet for $alternative på $rival — $saved undgået';
  }

  @override
  String get fuelCompareCo2Source =>
      'CO2-tallene er well-to-wheel-estimater (EU JEC WTW v5) anvendt på dit målte forbrug — til overblik, ikke som certificeret klimaregnskab.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 vises kun for rene brændstoffer: en blandings emissionsfaktor afhænger af blandingsforholdet, som denne række ikke registrerer.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count delvise tankninger afventer fuldt fyld — ikke i gennemsnit',
      one: '1 delvis tankning afventer fuldt fyld — ikke i gennemsnit',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% af brændstof fra automatiske korrektioner — gennemgå poster';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Korrektioner: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Anmeld indhold';

  @override
  String get contentModerationBlockAction => 'Bloker ophavsmand';

  @override
  String get contentModerationReportDialogTitle => 'Anmeld dette indhold?';

  @override
  String get contentModerationReportDialogBody =>
      'En anmeldelse sendes til din TankSync-server til gennemsyn, og dette indhold skjules på din enhed.';

  @override
  String get contentModerationReportConfirmButton => 'Anmeld';

  @override
  String get contentModerationBlockDialogTitle => 'Bloker denne ophavsmand?';

  @override
  String get contentModerationBlockDialogBody =>
      'Alt, hvad denne konto deler med dig, bliver skjult på denne enhed.';

  @override
  String get contentModerationBlockConfirmButton => 'Bloker';

  @override
  String get contentModerationReportedSnack =>
      'Anmeldelse sendt — indholdet er skjult.';

  @override
  String get contentModerationReportFailedSnack =>
      'Anmeldelsen kunne ikke sendes. Prøv igen.';

  @override
  String get contentModerationBlockedSnack =>
      'Ophavsmand blokeret — det delte indhold er skjult.';

  @override
  String get fillUpCorrectionLabel =>
      'Automatisk korrektion — tryk for at redigere';

  @override
  String get fillUpCorrectionEditTitle => 'Rediger automatisk korrektion';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Denne post blev autogenereret for at lukke hullet mellem registrerede ture og tanket brændstof. Juster værdierne, hvis du kender de faktiske tal.';

  @override
  String get fillUpCorrectionDelete => 'Slet korrektion';

  @override
  String get fillUpCorrectionStation => 'Stationsnavn (valgfrit)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country-stationer $km km væk — €$price/L billigere';
  }

  @override
  String get crossBorderTapToSwitch => 'Tryk for at skifte land';

  @override
  String get crossBorderDismissTooltip => 'Afvis';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Åbn $source datakilden ($license) i din browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Udviklerværktøjer';

  @override
  String get dataAccessTracerExport => 'Eksportér dataadgangslog';

  @override
  String get dataAccessTracerExportSuccess =>
      'Dataadgangslog gemt i Overførsler.';

  @override
  String get dataAccessTracerExportFailure =>
      'Dataadgangsloggen kunne ikke eksporteres.';

  @override
  String get dataAccessTracerEmpty =>
      'Ingen dataadgangshændelser registreret endnu — søg eller åbn stationer først, og eksportér derefter.';

  @override
  String get developerToolsSubtitle =>
      'Diagnostik og fejlfindingsværktøjer — kun synlige i udvikler-/fejlfindingstilstand.';

  @override
  String get developerToolsMenuSubtitle => 'Fejllog, testadvarsler, diagnostik';

  @override
  String get developerToolsErrorLogGroupTitle => 'Fejllog';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Gem fejllog ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Ryd fejllog';

  @override
  String get developerToolsViewErrorLog => 'Vis fejllog';

  @override
  String get developerToolsErrorLogEmpty => 'Ingen fejlspor registreret.';

  @override
  String get developerToolsAlertsGroupTitle => 'Advarsler og notifikationer';

  @override
  String get developerToolsFireTestNotification => 'Send testnotifikation';

  @override
  String get developerToolsTestNotificationTitle => 'Testnotifikation';

  @override
  String get developerToolsTestNotificationBody =>
      'Hvis du kan læse dette, virker notifikationerne.';

  @override
  String get developerToolsTestNotificationSent => 'Testnotifikation sendt.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Notifikationer er blokeret — aktivér dem i systemindstillingerne, og prøv igen.';

  @override
  String get developerToolsRunTestAlert => 'Kør testadvarselsforløb';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testadvarsel udløst — forløbet leverede $count notifikation(er).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testprisadvarsel';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Syntetisk match: en station under dit mål blev fundet i nærheden.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Søg efter stationer først, og kør derefter testalerten, så notifikationen kan åbne en rigtig station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostik';

  @override
  String get developerToolsFeatureFlagDump => 'Inspektør for funktionsflag';

  @override
  String get developerToolsFlagOn => 'Til';

  @override
  String get developerToolsFlagOff => 'Fra';

  @override
  String get developerToolsClearCaches => 'Ryd cacher';

  @override
  String get developerToolsCachesCleared => 'Cacher ryddet.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopiér diagnostik';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostik kopieret til udklipsholderen.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Buildoplysninger';

  @override
  String get developerToolsBuildVersion => 'Appversion';

  @override
  String get developerToolsBuildChannel => 'Buildkanal';

  @override
  String get startupTraceSectionTitle => 'Initialiseringslog ved opstart';

  @override
  String get startupTraceExportButton => 'Eksportér opstartslog';

  @override
  String get startupTraceEmpty => 'Ingen opstartslog registreret endnu.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'I alt: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess => 'Opstartslog gemt i Overførsler.';

  @override
  String get startupTraceExportFailure =>
      'Opstartsloggen kunne ikke eksporteres.';

  @override
  String get distanceSourceOdometer => 'Kilometertæller';

  @override
  String get distanceSourceOdometerTooltip =>
      'Afstand aflæst fra bilens kilometertæller — en målt reference.';

  @override
  String get distanceSourceGps => 'GPS-spor';

  @override
  String get distanceSourceGpsTooltip =>
      'Afstand summeret fra det optagede GPS-spor — den faktiske vejafstand.';

  @override
  String get distanceSourceEstimated => 'Anslået';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Afstand integreret fra hastighedssensoren — et skøn; sensoren viser typisk lidt for meget.';

  @override
  String get insightCardTitle => 'Mest spildende adfærd';

  @override
  String get insightEmptyState =>
      'Ingen bemærkelsesværdig ineffektivitet — fortsæt sådan!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor over 3000 RPM ($pctTime% af turen): spildt $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count hårde accelerationer: spildt $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Tomgang ($pctTime% af turen): spildt $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% af turen';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Kørsel i lavt gear ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Sluk motoren ved lange stop i stedet for at lade den gå i tomgang.';

  @override
  String get lessonAdviceHighRpm =>
      'Skift tidligere op for at holde motoren uden for det høje omdrejningsområde.';

  @override
  String get lessonAdviceHardAccel =>
      'Giv blødt gas — jævn acceleration bruger mindre brændstof.';

  @override
  String get lessonAdviceLowGear =>
      'Skift op tidligere, så motoren falder til ro i et lavere, mere økonomisk gear.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Vedvarende høj fart ($pctTime% af turen): spildt $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Vedvarende høj fart ($pctTime% af turen)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Slip speederen over 110 km/t – luftmodstanden stiger kraftigt, så lidt langsommere sparer meget brændstof.';

  @override
  String get lessonSmoothDrivingTitle => 'Rolig kørsel – flot klaret!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Ingen hård acceleration eller opbremsning på denne tur – jævn kørsel holder forbruget lavt.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Fuld speeder ($pctTime% af turen): spildte $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Træd forsigtigt på pedalen — en blødere 70 % af gaspedalen bringer dig op i fart med langt mindre brændstof.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Fed blanding under belastning ($pctTime% af turen): spildte $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Kraftig, vedvarende belastning gør motoren fedkørende — skift op tidligt og lad op ved lange stigninger for at holde blandingen mager.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Kørsel op ad $gradePercent% stigning ($pctTime% af turen): spildte $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Bevar farten op ad bakken og giv jævnt gas — at surge på en stigning brænder ekstra brændstof.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stop-og-kør-genstarter: spildte $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Forudse trafikken og frihjul mod stop, så du ruller i stedet for at starte fra stilstand — at køre fra stillestående er den mest brændstofkrævende del af stop-og-kør.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Blandingen ser lidt mager ud — motoren tilførte brændstof ($pctTrim % korrektion) for at kompensere';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Blandingen ser mager ud — motoren fastholdt en stor brændstoftilførsel på $pctTrim %, en mulig ineffektivitet';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Blandingen ser lidt fed ud — motoren trak brændstof fra ($pctTrim % korrektion) for at kompensere';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Blandingen ser fed ud — motoren fastholdt en stor brændstofreduktion på $pctTrim %, en mulig ineffektivitet';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Motoren kørte fedt under belastning ($pctShare % af den varme kørsel) — muligt brændstofspild';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristisk sundhedssignal, ikke en diagnose';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'En vedvarende korrektion mod mager blanding kan betyde en luftlækage i indsugningen, svag brændstofforsyning eller en ældet sensor. Bliver forbruget eller motorgangen dårligere, kan en værkstedsdiagnose bekræfte det.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'En vedvarende korrektion mod fed blanding kan betyde en utæt indsprøjtningsdyse, for højt brændstoftryk eller en sensor, der viser for meget. Bliver forbruget eller motorgangen dårligere, kan en værkstedsdiagnose bekræfte det.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Fed blanding under høj belastning brænder ekstra brændstof. Skift op tidligt, og let på speederen ved lange accelerationer, så motoren kan holde sig tæt på en støkiometrisk blanding.';

  @override
  String get lessonTransportTitle =>
      'Motordata mangler for det meste af denne tur';

  @override
  String get lessonTransportAdvice =>
      'Motoren rapporterede ingen aktivitet på næsten hele strækningen. Enten svigtede OBD2-strømmen midt i turen, eller også blev bilen flyttet uden at blive kørt — forbrugstallet er upålideligt og udelukkes fra din statistik.';

  @override
  String get drivingScoreCardTitle => 'Kørescore';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Sammensat score fra tomgang, hårde accelerationer, hård opbremsning og høj-RPM-tid. En \'bedre end X% af tidligere ture\'-sammenligning kommer i en kommende udgivelse.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Kørescore $score ud af 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Tomgang';

  @override
  String get drivingScorePenaltyHardAccel => 'Hårde accelerationer';

  @override
  String get drivingScorePenaltyHardBrake => 'Hård opbremsning';

  @override
  String get drivingScorePenaltyHighRpm => 'Højt RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Fuld gas';

  @override
  String get drivingScoreClassVeryGood => 'Meget god';

  @override
  String get drivingScoreClassGood => 'God';

  @override
  String get drivingScoreClassAverage => 'Gennemsnitlig';

  @override
  String get drivingScoreClassBad => 'Kræver forbedring';

  @override
  String get drivingScorePenaltyLugging => 'Slæbende kørsel';

  @override
  String get drivingScorePenaltySmoothness => 'Rykkende kørsel';

  @override
  String get drivingScorePenaltyHighSpeed => 'Høj hastighed';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Aggressiv pedal';

  @override
  String get drivingScorePenaltyLambda => 'Fed blanding';

  @override
  String get gpsKpiCardTitle => 'GPS-effektivitet';

  @override
  String get gpsKpiRpa => 'Positiv acceleration (RPA)';

  @override
  String get gpsKpiPke => 'Kinetisk energibehov (PKE)';

  @override
  String get gpsKpiVapos => 'Accelerationsintensitet (VAPOS)';

  @override
  String get gpsKpiCoast => 'Frihjulsandel';

  @override
  String get gpsKpiClimbEnergy => 'Stigningsenergi';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs. din effektive basislinje';
  }

  @override
  String get drivingTraceCardTitle => 'Kørselsanalysespor (dev)';

  @override
  String get drivingTraceCardBody =>
      'Eksportér denne turs GPS KPI\'er, score og lektioner som JSON, skriv hvordan kørslen faktisk føltes i kommentarfeltet, og del den tilbage, så grænseværdierne for kørestil kan kalibreres mod rigtige ture.';

  @override
  String get drivingTraceExportAction => 'Eksportér analysspor';

  @override
  String get drivingTraceExported =>
      'Analysespor gemt i Downloads — tilføj din vurdering i kommentarfeltet og del det tilbage.';

  @override
  String get drivingTraceExportFailed => 'Kunne ikke eksportere analysesporet.';

  @override
  String get minimalDriveTripAverage => 'Turgennemsnit';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Jævn fart ved højt omdrejningstal ($pctTime % af turen): at skifte op tidligere kunne spare $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Skift op tidligere ved jævn fart — samme hastighed ved lavere omdrejninger bruger mærkbart mindre brændstof.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Rulning med brændstofafbrydelse ($pctTime % af turen): sparede cirka $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Godt forudset — at lette på speederen tidligt lader motoren afbryde brændstoffet helt, mens bilen ruller.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Hvor dit brændstof blev af';

  @override
  String get fuelBreakdownIdle => 'Tomgang';

  @override
  String get fuelBreakdownHarshAccel => 'Hårde accelerationer';

  @override
  String get fuelBreakdownHighRpmCruise => 'Jævn fart ved højt omdrejningstal';

  @override
  String get fuelBreakdownCoastingSaved => 'Sparet ved at rulle';

  @override
  String get fuelBreakdownEfficient => 'Normal kørsel';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Tomgang i et stykke tid — at slukke motoren sparer brændstof';

  @override
  String get ecoNudgeHarshAccel =>
      'Kraftig acceleration — en blødere speederfod sparer brændstof';

  @override
  String get ecoNudgeHighRpm =>
      'Højt omdrejningstal ved jævn fart — at skifte op tidligere sparer brændstof';

  @override
  String get obd2CoverageNoneNote =>
      'Der kom ingen motordata fra OBD2-adapteren på denne tur — brændstoftallene er GPS-baserede skøn.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Motordata stoppede $percent % inde i turen (forbindelsen røg) — brændstoftallene derefter er GPS-baserede skøn.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Motordata dækkede kun $percent % af turen — hullerne bruger GPS-baserede skøn.';
  }

  @override
  String get favoritesShareAction => 'Del';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favoritter den $date';
  }

  @override
  String get favoritesShareError => 'Kunne ikke generere delingsbillede';

  @override
  String get featureManagementSectionTitle => 'Funktionsstyring';

  @override
  String get featureManagementSectionSubtitle =>
      'Slå individuelle funktioner til eller fra. Nogle funktioner afhænger af andre — skifterne er deaktiverede, indtil forudsætningerne er opfyldt.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2-turoptagelse';

  @override
  String get featureDescription_obd2TripRecording =>
      'Optag ture automatisk via OBD2.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification => 'Kørscorer og optjente badges.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptisk eco-coach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Real-time haptisk feedback under en tur.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synkronisering på tværs af enheder via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Forbrugsanalyse';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Fane til tankning og turanalyse.';

  @override
  String get featureLabel_baselineSync => 'Basislinje-synkronisering';

  @override
  String get featureDescription_baselineSync =>
      'Synkroniser kørselsbasislinjer via TankSync.';

  @override
  String get featureLabel_priceAlerts => 'Prisadvarsler';

  @override
  String get featureDescription_priceAlerts =>
      'Tærskelbaserede prisfald-notifikationer.';

  @override
  String get featureLabel_priceHistory => 'Prishistorik';

  @override
  String get featureDescription_priceHistory =>
      '30-dages prisdiagrammer på stationsdetaljer.';

  @override
  String get featureLabel_routePlanning => 'Ruteplanlægning';

  @override
  String get featureDescription_routePlanning =>
      'Billigste stop langs din rute.';

  @override
  String get featureLabel_evCharging => 'EV-opladning';

  @override
  String get featureDescription_evCharging =>
      'Ladestationer via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling-vejledning ved hjælp af OSM-trafiklys.';

  @override
  String get featureLabel_gpsTripPath => 'GPS-tursti';

  @override
  String get featureDescription_gpsTripPath =>
      'Bevar GPS-stistykker sammen med hver tur.';

  @override
  String get featureLabel_autoRecord => 'Automatisk optagelse';

  @override
  String get featureDescription_autoRecord =>
      'Start automatisk en tur, når OBD2-adapteren opretter forbindelse til et kørende køretøj.';

  @override
  String get featureLabel_showFuel => 'Vis tankstationer';

  @override
  String get featureDescription_showFuel =>
      'Vis benzin/diesel-stationsresultater i søgningen og på kortet.';

  @override
  String get featureLabel_showElectric => 'Vis ladestationer';

  @override
  String get featureDescription_showElectric =>
      'Vis EV-ladestationer i søgningen og på kortet.';

  @override
  String get featureLabel_showConsumptionTab => 'Forbrugsfane';

  @override
  String get featureDescription_showConsumptionTab =>
      'Vis forbrugsanalysefanen i bundnavigationen.';

  @override
  String get featureBlockedEnable_gamification =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureBlockedEnable_baselineSync => 'Aktivér TankSync først';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite-prisprognose';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Prisforudsigelsesmodel på enheden — inferens kører lokalt; funktioner og forudsigelser forlader aldrig enheden.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Aktivér prishistorik først';

  @override
  String get featureLabel_fuelCalculator => 'Brændstofberegner';

  @override
  String get featureDescription_fuelCalculator =>
      'Tilgængelig brændstofprisberegner fra søgeresultaterne.';

  @override
  String get featureLabel_carbonDashboard => 'CO2-dashboard';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2-aftryk-dashboard tilgængeligt fra forbrugsfanen.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentelle OEM PID\'er';

  @override
  String get featureDescription_experimentalOemPids =>
      'Aflæs præcise litermål via producentspecifikke PID\'er på understøttede adaptere.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Aktivér OBD2-turoptagelse først';

  @override
  String get featureLabel_paymentQrScan => 'Scan betalings-QR';

  @override
  String get featureDescription_paymentQrScan =>
      'Scan-til-betal QR-læser på stationsdetalje-skærmen.';

  @override
  String get featureLabel_communityPriceReports => 'Fællesskabsprisrapporter';

  @override
  String get featureDescription_communityPriceReports =>
      'Rapporter en stationspris fra stationsdetalje-skærmen.';

  @override
  String get featureLabel_obd2Optional => 'Kræv OBD2 til turoptagelse';

  @override
  String get featureDescription_obd2Optional =>
      'Når slået fra optager appen ture med kun GPS uden en OBD2-adapter. Coaching er reduceret — ingen øjeblikkelig L/100 km, færre motorsignaler.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Kvittering OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Scan en udskrevet kvittering på skærmen Tilføj påfyldning for at forudfylde dato, liter, total og station.';

  @override
  String get featureLabel_developerPatToken => 'Udvikler-feedback (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Aktiverer feedback-panelet for fejlskanninger, der automatisk opretter GitHub-issues med en Personal Access Token. Funktion for avancerede brugere/bidragsydere.';

  @override
  String get featureLabel_debugMode => 'Udvikler-/fejlfindingstilstand';

  @override
  String get featureDescription_debugMode =>
      'Viser en sektion med udviklerværktøjer i indstillingerne med diagnostik: eksport af fejllog, testnotifikationer, kørsel af testadvarselsforløb, oversigt over funktionsflag, rydning af cacher og kopiering af diagnostik.';

  @override
  String get featureLabel_approachOverlay => 'Tankstationsradar';

  @override
  String get featureDescription_approachOverlay =>
      'Gør den flydende kørselsvisning til en live tankstationsradar — når du nærmer dig en tankstation, skifter den til brændstoftypenss farve og viser prisen.';

  @override
  String get featureLabel_voiceAnnouncements => 'Stemmemeddelelser';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Annoncér nærliggende billige tankstationer højt under kørslen, så du kan holde øjnene på vejen.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Aktivér tankstationsradaren først';

  @override
  String get featureGroupTitle_finding => 'Find og kort';

  @override
  String get featureGroupDescription_finding =>
      'Hvor du kan tanke eller lade — søg, kort, rutevalg.';

  @override
  String get featureGroupTitle_prices => 'Priser og alarmer';

  @override
  String get featureGroupDescription_prices =>
      'Prisfald, historik og rapportering.';

  @override
  String get featureGroupTitle_radar => 'Tankstationsradar';

  @override
  String get featureGroupDescription_radar => 'Live prisnudge under kørslen.';

  @override
  String get featureGroupTitle_sync => 'Synkronisering og sikkerhedskopi';

  @override
  String get featureGroupDescription_sync =>
      'Hold dine data på tværs af enheder.';

  @override
  String get featureGroupTitle_input => 'Input og scanning';

  @override
  String get featureGroupDescription_input =>
      'Hjælpere til at logge tankninger.';

  @override
  String get featureGroupTitle_developer => 'Udvikler og eksperimentel';

  @override
  String get featureGroupDescription_developer =>
      'Avancerede bruger- og bidragyderfunktioner.';

  @override
  String get featureLabel_voiceFeedback => 'Talt feedback (talesyntese)';

  @override
  String get featureDescription_voiceFeedback =>
      'Hovedafbryder for alt talt output — kørecoachen og stationsmeddelelserne. Slået fra åbner appen aldrig en talesyntesemotor.';

  @override
  String get feedbackConsentTitle => 'Send rapport til GitHub?';

  @override
  String get feedbackConsentBody =>
      'Dette opretter en offentlig sag i vores GitHub-repository med dit billede og OCR-teksten. Ingen personoplysninger (placering, konto-id) sendes. Fortsæt?';

  @override
  String get feedbackConsentContinue => 'Fortsæt';

  @override
  String get feedbackConsentCancel => 'Annuller';

  @override
  String get feedbackConsentLater => 'Senere';

  @override
  String get feedbackTokenSectionTitle =>
      'Feedback ved dårlig scanning (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'For automatisk at åbne et GitHub-issue fra en mislykket scanning, indsæt et GitHub PAT (`public_repo`-omfang på tankstellen-repositoryet). Ellers er manuel deling fortsat tilgængelig.';

  @override
  String get feedbackTokenStatusSet => 'Token konfigureret';

  @override
  String get feedbackTokenStatusUnset => 'Intet token';

  @override
  String get feedbackTokenSet => 'Angiv';

  @override
  String get feedbackTokenClear => 'Ryd';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personligt adgangstoken';

  @override
  String get fillUpMultiFuelHint =>
      'Dette køretøj kan bruge forskellige brændstoffer — registrér det, du faktisk tankede';

  @override
  String get fillUpGuidanceTitle => 'Bedste tidspunkt at tanke';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Den nuværende pris er blandt de billigste de seneste $days dage — et godt tidspunkt at tanke.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Priserne er tæt på deres $days-dages højde. De er normalt billigere $window — overvej at vente.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Priserne stiger — overvej at tanke snart.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Dagens pris er omkring $days-dages gennemsnittet.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Kan spare ca. $amount/L ved at time din tankning.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Baseret på $count prisaflæsninger',
      one: 'Baseret på 1 prisaflæsning',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'om $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'om $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'på andre tidspunkter';

  @override
  String get fillUpGuidanceWeekday1 => 'mandage';

  @override
  String get fillUpGuidanceWeekday2 => 'tirsdage';

  @override
  String get fillUpGuidanceWeekday3 => 'onsdage';

  @override
  String get fillUpGuidanceWeekday4 => 'torsdage';

  @override
  String get fillUpGuidanceWeekday5 => 'fredage';

  @override
  String get fillUpGuidanceWeekday6 => 'lørdage';

  @override
  String get fillUpGuidanceWeekday7 => 'søndage';

  @override
  String get fillUpGuidancePartEarlyMorning => 'tidlig morgen';

  @override
  String get fillUpGuidancePartMorning => 'om morgenen';

  @override
  String get fillUpGuidancePartAfternoon => 'om eftermiddagen';

  @override
  String get fillUpGuidancePartEvening => 'om aftenen';

  @override
  String get fillUpGuidancePartNight => 'om natten';

  @override
  String get fillUpImportPasteLabel => 'Indsæt tekst';

  @override
  String get pasteReceiptDialogTitle => 'Indsæt kvitteringstekst';

  @override
  String get pasteReceiptDialogHint =>
      'Indsæt teksten fra en brændstofkvittering — e-mail, sms eller en delt PDF. Liter, literpris, brændstoftype, total og station læses på enheden og bruges til at udfylde formularen på forhånd. Intet sendes til en server.';

  @override
  String get pasteReceiptFieldHint => 'Kvitteringstekst';

  @override
  String get pasteReceiptParseAction => 'Udfyld';

  @override
  String get pasteReceiptNoData =>
      'Kunne ikke læse brændstofdata ud af den tekst — tjek, at det er en brændstofkvittering, og prøv igen.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verificeret af adapter';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Stemmer ikke med adapteraflæsning';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Din post: $userL L. Adapteren siger: $adapterL L (delta fra brændstofniveauoptagelse før/efter). Brug adapterværdi?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Behold min post';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Brug adapterværdi';

  @override
  String get scanReceiptNoData => 'Ingen kvitteringsdata fundet — prøv igen';

  @override
  String get scanReceiptSuccess =>
      'Kvittering scannet — verificér værdier. Tryk \"Rapporter scanningsfejl\" nedenfor, hvis noget er forkert.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scanning mislykkedes: $error';
  }

  @override
  String get badScanReportTitleReceipt =>
      'Rapporter en scanningsfejl — Kvittering';

  @override
  String get badScanReportHint =>
      'Vi deler kvitteringsfotoet og begge sæt værdier, så den næste version kan lære dette layout.';

  @override
  String get badScanReportFieldBrandLayout => 'Mærkelayout';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Pris/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Brændstof';

  @override
  String get badScanReportFieldDate => 'Dato';

  @override
  String get badScanReportHeaderField => 'Felt';

  @override
  String get badScanReportHeaderScanned => 'Scannet';

  @override
  String get badScanReportHeaderYouTyped => 'Du tastede';

  @override
  String get badScanReportCreateTicket => 'Opret issue';

  @override
  String get badScanReportOpenInBrowser => 'Åbn i browser';

  @override
  String get badScanReportFallbackToShare =>
      'Indsendelse mislykkedes — manuel deling';

  @override
  String get fillUpWarningDialogTitle => 'Tjek denne tankning';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Du valgte $chosenFuel, men dette køretøj kører på $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Kilometerstanden $entered km er lavere end forrige tanknings $previous km — afstanden kan ikke gå baglæns.';
  }

  @override
  String get fillUpWarningGoBack => 'Gå tilbage og ret';

  @override
  String get fillUpWarningSaveAnyway => 'Gem alligevel';

  @override
  String get fillUpSectionWhatTitle => 'Hvad du tankede';

  @override
  String get fillUpSectionWhatSubtitle => 'Brændstof, mængde, pris';

  @override
  String get fillUpSectionWhereTitle => 'Hvor du var';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, kilometertæller, noter';

  @override
  String get fillUpImportReceiptLabel => 'Kvittering';

  @override
  String get fillUpPricePerLiterLabel => 'Pris pr. liter';

  @override
  String get vehicleHeaderUntitled => 'Nyt køretøj';

  @override
  String get vehicleSectionIdentityTitle => 'Identitet';

  @override
  String get vehicleSectionIdentitySubtitle => 'Navn og VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Drivlinje';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Hvordan dette køretøj bevæger sig';

  @override
  String get profileSectionDisplayStations => 'Visning og stationer';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get fuelEfficiencyCardTitle => 'Pris pr. kilometer efter brændstof';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Hvilken brændstofblanding der faktisk er billigst at køre på';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Billigst pr. km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Ren';

  @override
  String get fuelEfficiencyMixBadge => 'Blanding';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Mest $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Pris/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Brugt i alt';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tankninger',
      one: '1 tankning',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fulde tanke',
      one: '1 fuld tank',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Registrér mindst to fulde tanke pr. sammensætning for at kåre den billigste.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Tanke grupperes efter sammensætning: en tank er ren, når ét brændstof udgør mindst 85 % af den, ellers en blanding.';

  @override
  String get fuelNameE5 => 'Benzin 95';

  @override
  String get fuelNameE10 => 'Benzin 95 E10';

  @override
  String get fuelNameE98 => 'Benzin 98';

  @override
  String get fuelNameDiesel => 'Diesel';

  @override
  String get fuelNameDieselPremium => 'Diesel Premium';

  @override
  String get fuelNameE85 => 'Bioethanol E85';

  @override
  String get fuelNameLpg => 'Autogas (LPG)';

  @override
  String get fuelNameCng => 'Naturgas (CNG)';

  @override
  String get fuelNameHydrogen => 'Brint';

  @override
  String get fuelNameElectric => 'El';

  @override
  String get calibrationModeLabel => 'Kalibringstilstand';

  @override
  String get calibrationModeRule => 'Regelbaseret';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Regelbaseret tildeler hver køreprøve til præcis én situation. Fuzzy fordeler den på tværs af alle ud fra, hvor godt hver passer — glattere ved 60 km/h eller skiftende stigninger, men langsommere til at fylde alle spande.';

  @override
  String get profileGamificationToggleTitle => 'Vis præstationer og scorer';

  @override
  String get profileGamificationToggleSubtitle =>
      'Når slået fra, er badges, scorer og trofæikoner skjult i hele appen.';

  @override
  String get coachingGpsLiftOff => 'Slip gassen';

  @override
  String get coachingGpsAnticipateBrake => 'Forudse';

  @override
  String get coachingGpsSmoothAccel => 'Blød acceleration';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Sporet dækker $pct % — længste hul $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Sporet dækker $pct % — ingen huller fundet';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'appen i baggrunden';

  @override
  String get gpsCoverageAttrOsBatching =>
      'systemet samlede positioner i bundter';

  @override
  String get gpsCoverageAttrGateRejected => 'positioner filtreret fra';

  @override
  String get gpsCoverageAttrDeliveryStall => 'forsinket levering';

  @override
  String get gpsCoverageAttrSignalLoss => 'signaltab';

  @override
  String get gpsCoverageAttrUnknown => 'ukendt årsag';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Appen var i baggrunden uden en forgrundstjeneste, så systemet begrænsede GPS\'en. Hold skærmen tændt under optagelsen, eller slå baggrundsoptagelse til, når det er muligt.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Systemet leverede positionerne for sent og i bundter; sporet blev udfyldt bagefter, så der gik reelt kun få data tabt.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Støjfyldte positioner på denne strækning blev filtreret fra for at holde afstanden ærlig.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Positionerne blev beregnet til tiden, men nåede appen for sent — telefonen havde travlt (ofte en Bluetooth-genforbindelse). Modtagelsen var fin.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'GPS-modtagelsen faldt ud — det er som regel en tunnel, en parkeringskælder eller tæt bybebyggelse.';

  @override
  String get gpsCoverageHintUnknown =>
      'Turen indeholder ingen oplysninger om appens tilstand under hullet, så årsagen kan ikke fastslås.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'forstyrrelse fra OBD2-genforbindelse';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Hullet falder sammen med en OBD2-genforbindelse — adapterforbindelsen var ved at komme sig, mens GPS-modtagelsen gik i stå. Løser du adapterforbindelsen, løser du også sporet.';

  @override
  String get gpsDiagnosticsTitle => 'GPS-samplingdiagnostik';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps huller',
      one: '1 hul',
      zero: 'ingen huller',
    );
    return '$count prøver · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Medianinterval: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Optaget under optagelse for at verificere GPS-kadence under telefonsøvn.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Største gap: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Genoptaget';

  @override
  String get gpsLifecyclePaused => 'Sat på pause';

  @override
  String get gpsLifecycleInactive => 'Inaktiv';

  @override
  String get gpsKpiVerdictGood => 'Effektiv';

  @override
  String get gpsKpiVerdictModerate => 'Moderat';

  @override
  String get gpsKpiVerdictAggressive => 'Aggressiv';

  @override
  String get gpsKpiInterpretationGood =>
      'Blød, energibesparende kørsel — sådan ser effektivitet ud.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Ret typisk kørsel — lidt blødere på speederen ville spare mere.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energikrævende kørsel — at lette på speederen og rulle mere ville sænke brændstofforbruget.';

  @override
  String get gpsMatrixMaturityCold => 'Kold';

  @override
  String get gpsMatrixMaturityWarming => 'Varmer op';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergeret';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS-matrix varmer stadig op ($count forfininger indtil videre). Estimater er foreløbige.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS-matrix konvergerer ($count tankninger). Estimater er brugbare men kan afvige nogle få %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS-matrix er konvergeret ($count tankninger). Estimater inden for ~2 % af faktisk forbrug.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS-estimat (~) — ingen brændstofssensor på denne tur. Tallet er modelleret ud fra hastighed og dit køretøjs kalibrering; nøjagtigheden forbedres efterhånden som matricen modnes.';

  @override
  String get gpsRoadUseCardTitle => 'Sådan brugte du vejen';

  @override
  String get gpsRoadUseSpeedSection => 'Hvor du brugte din tid';

  @override
  String get gpsRoadUseSpeedIdle => 'Holder stille (<5 km/t)';

  @override
  String get gpsRoadUseSpeedLow => 'By (5–50 km/t)';

  @override
  String get gpsRoadUseSpeedCruise => 'Landevej (50–110 km/t)';

  @override
  String get gpsRoadUseSpeedHigh => 'Hurtigt (≥110 km/t)';

  @override
  String get gpsRoadUsePhaseSection => 'Sådan bevægede du dig';

  @override
  String get gpsRoadUsePhaseAccel => 'Accelererer';

  @override
  String get gpsRoadUsePhaseSteady => 'Jævn fart';

  @override
  String get gpsRoadUsePhaseCoast => 'Ruller';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Masser af rulning — at lade bilen rulle i stedet for at bremse sparer brændstof. Flot.';

  @override
  String get gpsRoadUseSource => 'Fra dit GPS-spor';

  @override
  String get hapticEcoCoachSettingTitle => 'Real-time eco-coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Blidt haptisk + skærmtip, når du giver fuld gas under krydsart';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Let på speederen — kystning sparer mere';

  @override
  String highwayViaExit(String ref, String km) {
    return 'via afkørsel $ref · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Naviger til $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Fjern $name fra favoritter';
  }

  @override
  String get showOnMapSemanticLabel => 'Vis stationer på kortet';

  @override
  String get searchResultsSemanticLabel => 'Søgeresultater';

  @override
  String get searchCriteriaSemanticLabel =>
      'Oversigt over søgekriterier. Tryk for at redigere.';

  @override
  String get noFavoritesSemanticLabel =>
      'Ingen favoritter endnu. Tryk på stjernen ved en station for at gemme den som favorit.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stationen er åben',
      'false': 'Stationen er lukket',
      'other': 'Stationen er lukket',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Land $name, valgt',
      'false': 'Land $name',
      'other': 'Land $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sprog $name, valgt',
      'false': 'Sprog $name',
      'other': 'Sprog $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sortér efter $option, valgt',
      'false': 'Sortér efter $option',
      'other': 'Sortér efter $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Brændstof $type, valgt',
      'false': 'Brændstof $type',
      'other': 'Brændstof $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Ladestation $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Privatlivsskjold med brændstofdråbe';

  @override
  String get globeIllustrationSemantic =>
      'Globus med markører for tankstationer';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Brændstofstander med prisindikator';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, datakilde: $provider, $keyRequirement, brændstoftyper: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'API-nøgle påkrævet';

  @override
  String get countryInfoNoKeyNeeded => 'Gratis, ingen nøgle nødvendig';

  @override
  String countryInfoDataSource(String provider) {
    return 'Data: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Brændstoftyper: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon-nøgle';

  @override
  String get anonKeyHideTooltip => 'Skjul nøgle';

  @override
  String get anonKeyShowTooltip => 'Vis nøgle for at verificere';

  @override
  String anonKeyTooLong(int length) {
    return 'Nøglen er for lang ($length tegn) — tjek for ekstra tekst';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Nøglen ser korrekt ud ($length tegn)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Nøglen skal være en JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Nøglen kan være afkortet ($length af ~208 forventede tegn)';
  }

  @override
  String get anonKeyExceedsMax => 'Nøglen overskrider maksimal længde';

  @override
  String get qrShareTitle => 'Del din database';

  @override
  String get qrShareSubtitle =>
      'Andre kan scanne denne QR-kode for at oprette forbindelse';

  @override
  String get qrShareCopyAsText => 'Kopiér som tekst';

  @override
  String get authInfoTitle => 'Hvorfor oprette en konto?';

  @override
  String get authInfoBenefit1 =>
      '• Synkroniser favoritter, advarsler og gemte ruter på tværs af enheder';

  @override
  String get authInfoBenefit2 =>
      '• Planlæg en rute på din telefon, brug den i din bil';

  @override
  String get authInfoBenefit3 => '• Ingen data deles med tredjepart';

  @override
  String get authInfoBenefit4 => '• Du kan slette din konto til enhver tid';

  @override
  String get privacyLocalDataEmpty =>
      'Intet gemt endnu. Tilføj en favorit eller angiv en prisadvarsel for at se poster her.';

  @override
  String get privacyHideEmptyRows => 'Skjul tomme rækker';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vis $count tomme rækker',
      one: 'Vis $count tom række',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-nøgleopsætning (valgfrit)';

  @override
  String get apiKeySetupDescription =>
      'Registrér dig for en gratis API-nøgle, eller spring over for at udforske appen med demodata.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider-registrering';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Ved at indtaste en API-nøgle accepterer du vilkårene for $provider. Videredistribution af data er forbudt.';
  }

  @override
  String get calculatorDistanceHint => 'f.eks. 150';

  @override
  String get calculatorConsumptionHint => 'f.eks. 7,0';

  @override
  String get calculatorPriceHint => 'f.eks. 1,899';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (eksperimentel)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtilt haptisk ved opbremsning foran rødt lys. Fra som standard — distraktionsrisiko.';

  @override
  String get consentSyncTripsTitle => 'Synkroniser turoptagelser';

  @override
  String get consentSyncTripsSubtitle =>
      'Sikkerhedskopier OBD2 + GPS-ture til TankSync. Tværenhed, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Aktivér Cloud-synkronisering ovenfor for at sikkerhedskopiere ture.';

  @override
  String get consentSyncTripsAnonymousHint =>
      'Ture sikkerhedskopieres under denne enheds anonyme konto. Log ind med en e-mail for at nå dem fra andre enheder.';

  @override
  String get consentHideDetails => 'Skjul detaljer';

  @override
  String get consentShowDetails => 'Vis detaljer';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Ugyldigt link';

  @override
  String invalidLinkBody(String path) {
    return 'Linket \"$path\" er ikke gyldigt.';
  }

  @override
  String get home => 'Hjem';

  @override
  String get accelBrakeCardTitle => 'Acceleration og opbremsning';

  @override
  String get accelBrakeHardAccel => 'Hård acceleration';

  @override
  String get accelBrakeHardBrake => 'Hård opbremsning';

  @override
  String get accelBrakeSharpCorner => 'Skarpe sving';

  @override
  String get accelBrakeSource => 'Fra telefonens bevægelsessensorer';

  @override
  String lessonHardBrake(String count) {
    return '$count hårde opbremsninger';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Forudse stop og løft af speederen tidligere — hård opbremsning kaster det brændstof væk, du netop brugte på at komme op i fart.';

  @override
  String lessonSharpCornering(String count) {
    return '$count skarpe sving';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Sæt farten ned før svingen, ikke i den — hård sving reducerer farten, som du derefter skal genopbygge.';

  @override
  String get locationConsentTitle => 'Placeringsadgang';

  @override
  String get locationConsentSubtitle =>
      'Denne app vil bruge din placering til at finde tankstationer i nærheden.';

  @override
  String get locationConsentWhatHappens =>
      'Hvad der sker med dine placeringsdata:';

  @override
  String get locationConsentBulletApi =>
      'Dine koordinater sendes til brændstofpris-API\'en for at finde tankstationer i nærheden.';

  @override
  String get locationConsentBulletNoServer =>
      'Din placering gemmes ikke på nogen server — der er ingen server.';

  @override
  String get locationConsentBulletNoTracking =>
      'Placeringsdata bruges ikke til reklame, analyse eller sporing.';

  @override
  String get locationConsentRevoke =>
      'Du kan til enhver tid tilbagekalde placeringsadgangen i systemindstillingerne. Alternativt kan du søge på postnummer.';

  @override
  String get locationConsentLegalBasis =>
      'Retsgrundlag: art. 6, stk. 1, litra a) i GDPR (samtykke)';

  @override
  String get loyaltySettingsTitle => 'Brændstofklubkort';

  @override
  String get loyaltySettingsSubtitle =>
      'Anvend din loyalitetsrabat på viste priser';

  @override
  String get loyaltyMenuTitle => 'Brændstofklubkort';

  @override
  String get loyaltyMenuSubtitle =>
      'Anvend pr.-liter-rabatter fra Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Tilføj kort';

  @override
  String get loyaltyAddCardSheetTitle => 'Tilføj brændstofklubkort';

  @override
  String get loyaltyBrandLabel => 'Mærke';

  @override
  String get loyaltyCardLabelLabel => 'Mærkat (valgfrit)';

  @override
  String get loyaltyDiscountLabel => 'Rabat (pr. liter)';

  @override
  String get loyaltyDiscountInvalid => 'Angiv et positivt tal';

  @override
  String get loyaltyDeleteConfirmTitle => 'Slet kort?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Dette kort stopper med at anvende sin rabat.';

  @override
  String get loyaltyEmptyTitle => 'Ingen brændstofklubkort endnu';

  @override
  String get loyaltyEmptyBody =>
      'Tilføj et kort for automatisk at anvende din pr.-liter-rabat på matchende stationer.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Tomgangs-RPM-stigning registreret';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Tomgangs-RPM er steget med $percent% over dine seneste $tripCount ture. Muligt tidligt tegn på tilstoppet luftfilter eller sensordrift.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Mulig indtagsbegrænsning';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Krydsartsbrændstofrate er faldet med $percent% over dine seneste $tripCount ture. Muligt tegn på tilstoppet luftfilter eller begrænset indtagning — værd at tjekke.';
  }

  @override
  String get maintenanceActionDismiss => 'Afvis';

  @override
  String get maintenanceActionSnooze => 'Udsæt 30 dage';

  @override
  String get consumptionMonthlyInsightsTitle => 'Denne måned vs. forrige måned';

  @override
  String get consumptionMonthlyTripsLabel => 'Ture';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Køretid';

  @override
  String get consumptionMonthlyDistanceLabel => 'Afstand';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Gns. forbrug';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Kræver mindst 3 ture pr. måned for sammenligning';

  @override
  String get consumptionMonthlyClimbLabel => 'Steget';

  @override
  String get obd2CapabilitySectionTitle => 'Adapterfunktioner';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'OEM PID\'er';

  @override
  String get obd2CapabilityFullCan => 'Fuld CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'For præcise litermål i tank på Peugeot/Citroën understøtter appen OBDLink MX+/LX/CX (STN-chip).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2-diagnostisk overlay aktiveret';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2-diagnostisk overlay deaktiveret';

  @override
  String get obd2DebugOverlayClearButton => 'Ryd';

  @override
  String get obd2DebugOverlayCloseButton => 'Luk';

  @override
  String get obd2DebugOverlayTitle => 'OBD2-brødkrummer';

  @override
  String get obd2DiagnosticShareLabel => 'Del diagnostiklog';

  @override
  String get obd2DebugLoggingTitle => 'OBD2-fejlfindingslog';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Optag hver OBD2-session — forbindelse, handshake, datahuller og genforbindelser — i en eksporterbar XML-log. Slået fra som standard.';

  @override
  String get obd2DebugSessionShareLabel => 'Del OBD2-sessionslog';

  @override
  String get obd2DiagnosticsTitle => 'OBD2 kommunikationssundhed';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops tab',
      one: '1 tab',
      zero: 'ingen tab',
    );
    return '$percent% fuldført · $duty% duty · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Forbindelseslivscyklus';

  @override
  String get obd2DiagnosticsPidSection => 'Per-PID-resultater';

  @override
  String get obd2DiagnosticsReconnectSection => 'Genforbindelsestelemetri';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts genforbindelsesforsøg · $successes lykkedes · $transitions overgange · $disconnects typede afbrydelser';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'Reserveløsning med kun GPS blev aktiveret i denne session.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Schedulersundhed';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Fuldstændighed';

  @override
  String get obd2DiagnosticsSupportSection => 'Opdagede understøttede PID\'er';

  @override
  String get obd2DiagnosticsFuelSection => 'Brændstofniveauoversigt';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protokol $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts forsøg · $successes ok · $drops tab · tid til forbindelse p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Genforbindelser: $silent lydløse · $visible synlige';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips bagtrykshop · $demotions degraderinger';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dynamikniveau udsultet — RPM/hastighed faldt under styregrænsen.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Samlet $percent% · aktiv duty $duty%';
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
    return '$supported understøttede · $unsupported ikke understøttede · $unknown ukendte';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Mistænkelige $suspicious af $total prøver';
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
    return '$pid: $polled forespurgt · $ok ok · $noData ND · $timeout TO · $error fejl · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Dongle-initieringstransskript';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokol $protocol · $start · firmware $firmware · $tier · $pids PID\'er';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'varm';

  @override
  String get obd2DiagnosticsInitCold => 'kold';

  @override
  String get obd2DiagnosticsEmpty =>
      'Ingen OBD2-session registreret endnu — tilslut en adapter og optag en tur med Udviklertilstand aktiveret.';

  @override
  String get obd2DiagnosticsExplain =>
      'Optaget under optagelse for at fejlfinde dongle↔app-kommunikationen — indsamles kun i Udviklertilstand.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 kommunikationssundhed';

  @override
  String get obd2HealthNavLabel => 'OBD2 kommunikationssundhed';

  @override
  String get obd2HealthLiveSection => 'Live-session';

  @override
  String get obd2HealthHistorySection => 'Seneste sessioner';

  @override
  String get obd2HealthDownloadJson => 'Hent som JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Hent kun initialiseringsudskriften';

  @override
  String get obd2HealthDownloadError => 'Diagnosefilen kunne ikke gemmes';

  @override
  String get obd2TestAdapterLabel => 'Adapter, der skal testes';

  @override
  String get obd2TestAdapterScanOption => 'Søg efter adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Forbinder til $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Kør adaptertest';

  @override
  String get obd2TestRunButton => 'Kør adaptertest';

  @override
  String get obd2TestRunPassed => 'Adaptertest bestået';

  @override
  String get obd2TestRunFailed => 'Adaptertest mislykkedes';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — motoren er slukket; start motoren for at læse livedata';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed af $total trin OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Stop den aktive optagelse, inden du kører adaptertesten.';

  @override
  String get obd2TestStepScan => 'Søg efter adapter';

  @override
  String get obd2TestStepBluetooth => 'Telefonens Bluetooth';

  @override
  String get obd2TestStepConnect => 'Tilslut og initiér';

  @override
  String get obd2TestStepInfo => 'Adapterinfo';

  @override
  String get obd2TestStepSupportedPids => 'Understøttede PID\'er';

  @override
  String get obd2TestStepProtocol => 'Køretøjsprotokol';

  @override
  String get obd2TestStepSampleReads => 'Prøveaflæsninger';

  @override
  String get obd2TestStepSoak => 'Vedvarende aflæsning';

  @override
  String get obd2TestStepReconnect => 'Genforbindelsestest';

  @override
  String get obd2TestStepDisconnect => 'Afbryd forbindelsen';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Timeout';

  @override
  String get obd2TestStatusGarbage => 'Ulæseligt svar';

  @override
  String get obd2TestStatusNoResponse => 'Intet svar';

  @override
  String get obd2TestStatusFail => 'Mislykkedes';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'ukendt — BLE som standard';

  @override
  String get obd2HealthConnectAttemptsSection => 'Seneste forbindelsesforsøg';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Ingen forbindelsesforsøg registreret endnu.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Hent forbindelseslog';

  @override
  String get obd2HealthDownloadAllConnectTraces => 'Hent alle forbindelseslogs';

  @override
  String get obd2HealthConnectOrigin => 'Oprindelse';

  @override
  String get obd2HealthConnectTransport => 'Transport';

  @override
  String get obd2HealthConnectOutcome => 'Resultat';

  @override
  String get obd2HealthConnectScanList => 'Fundne enheder';

  @override
  String get obd2HealthConnectSteps => 'Trin';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Ukendt adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Session optaget · $samples motormålinger · $percent % dækning';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection =>
      'Hvad denne tur registrerede';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples af $total målinger indeholdt motordata ($percent %)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Protokol-håndtryk: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Session afsluttet: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Sessionens længde: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Forbrugstallene kommer fra adapteren, ikke fra GPS-estimater.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Kommunikationsdetaljerne pr. PID blev ikke registreret for denne tur. Slå udviklertilstand til før optagelse for at indsamle dem.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Kunne ikke nå \'$adapterName\' — vælg en anden adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Andre Bluetooth-enheder';

  @override
  String get obd2PickerTapToTry => 'Ikke genkendt — tryk for at prøve';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone fungerer kun med Bluetooth LE-adaptere. En adapter, der kun understøtter Classic (f.eks. vLinker BM, Konnwei KW902), skal bruges på Android.';

  @override
  String get obd2PairingConfirmHint =>
      'Bekræft parringsanmodningen på din telefon';

  @override
  String get obd2ScanEmptyTitle => 'Ingen adapter fundet';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth er slået til, og tilladelserne er givet. Sørg for, at adapteren sidder i OBD2-stikket, og at tændingen er slået til, og søg så igen.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Denne enhed har ingen Bluetooth Low Energy-hardware og kan derfor ikke forbinde til en OBD2-adapter.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth er slået fra. Slå det til for at søge efter din adapter.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo skal have Bluetooth-tilladelse for at finde din adapter.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Bluetooth-tilladelsen blev afvist permanent. Giv den i systemindstillingerne for at søge efter din adapter.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Lokalitetstjenester er slået fra på denne enhed. Android kræver, at de er slået til, for at søge efter Bluetooth-adaptere — der registreres eller deles ingen placering.';

  @override
  String get obd2ScanOpenSettings => 'Åbn indstillinger';

  @override
  String get obd2ReconnectInProgress => 'Genforbinder til din OBD2-adapter…';

  @override
  String get obd2StatusEngineOff => 'OBD2 sat på pause — motoren er slukket';

  @override
  String get obd2StatusEngineOffBody =>
      'Adapteren kunne nås, men køretøjets bus forblev tavs, så automatisk genforbindelse er sat på pause. Den genoptages, når du kører eller åbner appen igen — eller genforbind nu.';

  @override
  String get obd2StatusReconnectNow => 'Genforbind nu';

  @override
  String get autoRecordNotificationTitle => 'Automatisk turoptagelse';

  @override
  String get autoRecordNotificationText => 'Holder øje med din OBD2-adapter';

  @override
  String get obd2ResetConnection => 'Nulstil forbindelsen';

  @override
  String get obd2ResetConnectionDone =>
      'Adapter nulstillet — forbindelsen er genoprettet';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapter nulstillet — genforbinder i baggrunden';

  @override
  String get ocrTesterTitle => 'OCR-tester';

  @override
  String get ocrTesterNavLabel => 'OCR-tester';

  @override
  String get ocrTesterExplain =>
      'Kør pumpe/kvitterings-OCR-processen på et valgt foto og undersøg hvert trin — kun tilgængeligt i Udviklertilstand.';

  @override
  String get ocrTesterCapture => 'Optag';

  @override
  String get ocrTesterPickImage => 'Vælg billede';

  @override
  String get ocrTesterRun => 'Kør';

  @override
  String get ocrTesterCountry => 'Land';

  @override
  String get ocrTesterCountryNone => 'Standard (ingen profil)';

  @override
  String get ocrTesterNoImage =>
      'Vælg eller optag et billede, og kør derefter.';

  @override
  String get ocrTesterRunning => 'Kører OCR…';

  @override
  String get ocrTesterOverlaySection => 'Blokoverlæg';

  @override
  String get ocrTesterStepsSection => 'Procestrin';

  @override
  String get ocrTesterLegendLabel => 'Etiket';

  @override
  String get ocrTesterLegendNumeric => 'Numerisk';

  @override
  String get ocrTesterLegendNoise => 'Støj';

  @override
  String get ocrTesterLegendDerived => 'Afledt';

  @override
  String get ocrTesterStageGlare => 'Optag / blænding';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klassificér';

  @override
  String get ocrTesterStageAssemble => 'Sammenbyg';

  @override
  String get ocrTesterStageAnchor => 'Anker';

  @override
  String get ocrTesterStageFallback => 'Fallback';

  @override
  String get ocrTesterStageCrossCheck => 'Krydstjek';

  @override
  String get ocrTesterStageConfidence => 'Confidence';

  @override
  String get ocrTesterStageGate => 'Gate';

  @override
  String get ocrTesterStageBrand => 'Brand';

  @override
  String get ocrTesterStageOverrides => 'Tilsidesættelser';

  @override
  String get ocrTesterStageReconcile => 'Afstem';

  @override
  String get ocrTesterStageResult => 'Resultat';

  @override
  String get ocrTesterChipRead => 'LÆST';

  @override
  String get ocrTesterChipDerived => 'AFLEDT';

  @override
  String get ocrTesterGateAccepted => 'Accepteret';

  @override
  String get ocrTesterGateRejected => 'Afvist';

  @override
  String get ocrTesterFallbackBanner =>
      'Et felt blev gendannet via størrelsesfallback — verificer det.';

  @override
  String get ocrTesterStageNoData => 'Trin kørte ikke.';

  @override
  String get ocrTesterCopyJson => 'Kopiér som JSON';

  @override
  String get ocrTesterExportPackage => 'Eksportér pakke';

  @override
  String get ocrTesterCopied => 'OCR-spor kopieret til udklipsholder.';

  @override
  String get ocrTesterExported => 'OCR-pakke gemt i mappen Downloads.';

  @override
  String get onboardingObd2StepTitle => 'Tilslut din OBD2-adapter';

  @override
  String get onboardingObd2StepBody =>
      'Sæt din OBD2-adapter i bilens port og tænd tændingen. Vi aflæser VIN\'en og udfylder motoroplysninger for dig.';

  @override
  String get onboardingObd2ConnectButton => 'Tilslut adapter';

  @override
  String get onboardingObd2SkipButton => 'Måske senere';

  @override
  String get onboardingObd2ReadingVin => 'Aflæser VIN…';

  @override
  String get onboardingObd2ConnectFailed =>
      'Kunne ikke oprette forbindelse til adapteren. Du kan prøve igen eller springe over.';

  @override
  String get onboardingPickUseMode => 'Vælg en brugstilstand for at fortsætte.';

  @override
  String get onboardingObd2LaterNote =>
      'Du kan til enhver tid parre en Bluetooth-OBD2-adapter senere fra køretøjsskærmen for at optage ture og læse motordata.';

  @override
  String get openNow => 'Åben';

  @override
  String get openNowClosed => 'Lukket';

  @override
  String get openHoursUnknown => 'Åbningstider ukendt';

  @override
  String closesAt(String time) {
    return 'Lukker $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Åbner $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Åbner $time';
  }

  @override
  String get open24Hours => 'Åben 24 timer';

  @override
  String get badge24h => '24t';

  @override
  String get openingHoursAutomate24h => '24/7 automatisér';

  @override
  String get dayMon => 'Mandag';

  @override
  String get dayTue => 'Tirsdag';

  @override
  String get dayWed => 'Onsdag';

  @override
  String get dayThu => 'Torsdag';

  @override
  String get dayFri => 'Fredag';

  @override
  String get daySat => 'Lørdag';

  @override
  String get daySun => 'Søndag';

  @override
  String get dayShortMon => 'Man';

  @override
  String get dayShortTue => 'Tir';

  @override
  String get dayShortWed => 'Ons';

  @override
  String get dayShortThu => 'Tor';

  @override
  String get dayShortFri => 'Fre';

  @override
  String get dayShortSat => 'Lør';

  @override
  String get dayShortSun => 'Søn';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Helligdage';

  @override
  String get closedLabel => 'Lukket';

  @override
  String get openingHoursNotAvailable => 'Åbningstider ikke tilgængelige';

  @override
  String get showAllHours => 'Vis alle tider';

  @override
  String get showLessHours => 'Vis færre';

  @override
  String get openStateUnknown => 'Ukendt';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stationen er åben',
      'false': 'Stationen er lukket',
      'other': 'Åbningsstatus ukendt',
    });
    return '$_temp0';
  }

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimeret værdi (~) — ingen brændstofssensor på denne tur, så L/100 km-tallet er modelleret ud fra GPS-hastighed og dit køretøjs kalibrering. Det er omtrentligt (typisk ±10–30 %, der strammes efterhånden som kalibreringen modnes), ikke en målt aflæsning.';

  @override
  String get tripRecordingPipElapsedCaption => 'forløbet';

  @override
  String get qrLaunchConfirmTitle => 'Åbn det scannede link?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Denne QR-kode peger på $host. Åbn kun links, du har tillid til.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Åbn link';

  @override
  String get qrLaunchConfirmCancel => 'Annuller';

  @override
  String get radarPinHelpTitle => 'Om fastgørelse';

  @override
  String get radarPinHelpBody =>
      'Fastgørelse holder skærmen tændt og skjuler systembjælker, så den nærmeste stations visning forbliver læsbar på et dashboardbeslag. Tryk igen for at frigøre. Frigøres automatisk, når radaren stopper.';

  @override
  String get radarAutoPinTitle => 'Fastgør altid, når radaren starter';

  @override
  String get radarAutoPinSubtitle =>
      'Fastgør radaren automatisk hver gang i stedet for at trykke hver gang. Bruger mere batteri.';

  @override
  String get radarScopeShowScope => 'Radarvisning';

  @override
  String get radarScopeShowList => 'Listevisning';

  @override
  String get alertsRadiusFrequencyLabel => 'Tjekfrekvens';

  @override
  String get alertsRadiusFrequencyDaily => 'Én gang om dagen';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'To gange om dagen';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tre gange om dagen';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Fire gange om dagen';

  @override
  String get radiusAlertPickOnMap => 'Vælg på kort';

  @override
  String get radiusAlertMapPickerTitle => 'Vælg advarselscentrum';

  @override
  String get radiusAlertMapPickerConfirm => 'Bekræft';

  @override
  String get radiusAlertMapPickerCancel => 'Annuller';

  @override
  String get radiusAlertMapPickerHint =>
      'Træk kortet for at placere advarselscentrum';

  @override
  String get radiusAlertCenterFromMap => 'Kortplacering';

  @override
  String get reconcileWorkflowTitle => 'Afstem dit brændstof';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Vi fandt et $gap L-mellemrum';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Du pumpede $pumped L, men dine registrerede ture tegner sig kun for $consumed L. Det efterlader $gap L uforklaret.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Det skyldes normalt, at en køretur ikke blev registreret (adapteren var frakoblet eller appen var lukket), eller at en tankning mangler eller er tastet forkert.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Indtil dette er løst, vil dit brændstofstotal og dit turerstotal ikke stemme overens.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Hjælp os med at henføre mellemrummet';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Er alle dine tankninger for denne tank komplette og korrekte?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Er alle dine kørsler registreret?';

  @override
  String get reconcileWorkflowAnswerYes => 'Ja';

  @override
  String get reconcileWorkflowAnswerNo => 'Nej';

  @override
  String get reconcileWorkflowPathAHint =>
      'En tankning mangler eller er forkert — vi tilføjer en korrektion, så dine tankninger stemmer.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Dine tankninger er korrekte, og en køretur gik uregistreret — vi tilføjer en virtuel tur for den manglende afstand.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Korrektionsliter';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Hvor langt var den uregistrerede køretur? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Beslut senere';

  @override
  String get reconcileWorkflowBack => 'Tilbage';

  @override
  String get reconcileWorkflowNext => 'Næste';

  @override
  String get reconcileWorkflowApply => 'Anvend';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtuel tur — tryk for at redigere';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Rediger virtuel tur';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Denne tur blev tilføjet for at redegøre for brændstof, du brugte under kørsel uden registrering. Juster afstanden eller brændstoffet, eller slet den.';

  @override
  String get reconcileVirtualTrajetDelete => 'Slet virtuel tur';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Uløst brændstof-/turgab på $gap L — tryk for at løse';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Løs uløst brændstof- og turgab';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/session';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Denne filtype kan ikke importeres endnu — del et foto af kvitteringen i stedet.';

  @override
  String get shareReceiptFailed =>
      'Kunne ikke læse den delte kvittering — prøv at dele den igen eller tilføj tankingen manuelt.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Del kvittering for import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Del et kvitteringsfoto fra en anden app for at forudfylde en tankning — dato, liter, total og station aflæses på enheden.';

  @override
  String get speedConsumptionCardTitle => 'Forbrug efter hastighed';

  @override
  String get speedBandIdleJam => 'Tomgang / kø';

  @override
  String get speedBandUrban => 'By (10–50)';

  @override
  String get speedBandSuburban => 'Forstad (50–80)';

  @override
  String get speedBandRural => 'Land (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-krydsart (100–115)';

  @override
  String get speedBandMotorway => 'Motorvej (115–130)';

  @override
  String get speedBandMotorwayFast => 'Hurtig motorvej (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Optag 30+ minutters ture med OBD2-adapteren for at låse op for hastighed/forbrugsanalysen.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % af kørslen';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Brug for mere data';

  @override
  String get splashLoadingLabel => 'Indlæser Sparkilo';

  @override
  String get storageRecoveryTitle => 'Lagerproblem';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo kunne ikke åbne sit lokale datalager. Lagerfilen ser ud til at være beskadiget.';

  @override
  String get storageRecoveryGuidance =>
      'For at gendanne skal du rydde appens lager i enhedens indstillinger eller geninstallere appen. Dine favoritter og din historik gemmes kun på denne enhed og kan ikke gendannes automatisk.';

  @override
  String syncAdoptTitle(String email) {
    return 'Tilslut dig kontoen $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Log ind med kontoens adgangskode for at dele dens data på begge enheder.';

  @override
  String get syncAdoptPasswordLabel => 'Kontoens adgangskode';

  @override
  String get syncAdoptJoinButton => 'Tilslut dig kontoen';

  @override
  String get syncAdoptUseDifferentAccount => 'Brug en anden konto i stedet';

  @override
  String get syncDeleteDataTitle => 'Slet synkroniserede data';

  @override
  String get syncDeleteDataSubtitle =>
      'Fjern dine ture, køretøjer eller tankninger fra synkroniseringsdatabasen';

  @override
  String get syncDeleteDataPickTitle =>
      'Hvilke synkroniserede data skal slettes?';

  @override
  String get syncDeleteDataCategoryTrips => 'Ture';

  @override
  String get syncDeleteDataCategoryVehicles => 'Køretøjer';

  @override
  String get syncDeleteDataCategoryFillUps => 'Tankninger';

  @override
  String get syncDeleteDataCategoryEverything => 'Alt';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Slet $category fra synkroniseringsdatabasen?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Dette fjerner de valgte data fra din synkroniseringsdatabase, og de synkroniseres ikke igen fra dine andre enheder. Data, der er gemt lokalt på denne enhed, bevares.';

  @override
  String get syncDeleteDataConfirmAction => 'Slet fra serveren';

  @override
  String get syncDeleteDataDone => 'Synkroniserede data slettet';

  @override
  String get syncDeleteDataFailed =>
      'Sletning af synkroniserede data mislykkedes — prøv igen';

  @override
  String get syncRelinkTitle => 'Skysynkronisering skal tilknyttes igen';

  @override
  String get syncRelinkBody =>
      'Denne enheds gemte synkroniseringsidentitet er logget ud. Log ind med din e-mail for at tilknytte dine synkroniserede data igen, eller start forfra med en ny identitet.';

  @override
  String get syncRelinkSignInAction => 'Log ind for at tilknytte igen';

  @override
  String get syncRelinkStartFreshAction => 'Start forfra';

  @override
  String get syncRelinkStartFreshTitle => 'Start forfra?';

  @override
  String get syncRelinkStartFreshBody =>
      'Der oprettes en ny anonym identitet til denne enhed. Data synkroniseret under den gamle identitet bliver på serveren, men kan ikke længere nås herfra, medmindre du logger ind med dens e-mailkonto.';

  @override
  String get syncRelinkStartFreshConfirm => 'Start forfra';

  @override
  String get tankLevelTitle => 'Tankniveau';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km rækkevidde';
  }

  @override
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km med din seneste tanks forbrug';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Langtidsgennemsnit: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Seneste tankning: $date · $count tur(e) siden';
  }

  @override
  String get tankLevelEmptyNoFillUp =>
      'Log en tankning for at se dit tankniveau';

  @override
  String get tankLevelDetailSheetTitle => 'Ture siden seneste tankning';

  @override
  String get addFillUpIsFullTankLabel => 'Fuld tank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tank fyldt til randen — fjern markeringen, hvis dette var en delfyldning';

  @override
  String tankLevelSourceFillUp(String date) {
    return 'Forankret ved seneste tankning: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'OBD2-tanksensor · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Tankblanding: $mix';
  }

  @override
  String get tankReportTitle => 'Tankrapport';

  @override
  String tankReportHeadline(String value) {
    return '$value L/100 km';
  }

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Siden forrige fulde tank: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km mere end forrige tank';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km mindre end forrige tank';
  }

  @override
  String get tankReportTrendFlat => 'På niveau med forrige tank';

  @override
  String get tankReportNoPrevious =>
      'Udviklingen vises efter din næste fulde tank.';

  @override
  String tankReportCoverage(String pct) {
    return 'Optagelserne dækker $pct % af denne tank';
  }

  @override
  String tankReportRecordedAvg(String value) {
    return 'Optaget del: $value L/100 km';
  }

  @override
  String get tankReportExplainHeader => 'Hvad optagelserne antyder';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Andel højt omdrejningstal $cur % (var $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Hårde manøvrer $cur/100 km (var $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Koldstarter $cur (var $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Andel tomgang $cur % (var $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Optagelserne er spontane og dækker kun en del af denne tank — disse hints er vejledende, ikke hele historien.';

  @override
  String tankReportCalibrationUnder(String pct) {
    return 'Optagede skøn ligger $pct % under standerens tal';
  }

  @override
  String tankReportCalibrationOver(String pct) {
    return 'Optagede skøn ligger $pct % over standerens tal';
  }

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'System';

  @override
  String get themeCardSubtitleLight => 'Lyst';

  @override
  String get themeCardSubtitleDark => 'Mørkt';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Følg system';

  @override
  String get themeSettingsLightLabel => 'Lyst';

  @override
  String get themeSettingsDarkLabel => 'Mørkt';

  @override
  String get themeSettingsSystemDescription =>
      'Match den aktuelle enhedsudseende.';

  @override
  String get themeSettingsLightDescription =>
      'Lyse baggrunde — bedst til brug om dagen.';

  @override
  String get themeSettingsDarkDescription =>
      'Mørke baggrunde — nemmere for øjnene om natten og sparer batteri på OLED-skærme.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'Appens karakteristiske grønne look — lyst og nemt at læse, med blidt grønttonede baggrunde.';

  @override
  String get throttleRpmHistogramTitle => 'Sådan brugte du motoren';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gasposition';

  @override
  String get throttleRpmHistogramRpmSection => 'Motor-RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Kyst (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Let (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Fast (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Fuld åbning (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Tomgang (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Krydsart (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Livlig (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Hård (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Ingen gas- eller RPM-prøver i denne tur.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Ture';

  @override
  String get trajetsStartRecordingButton => 'Start optagelse';

  @override
  String get trajetsResumeRecordingButton => 'Genoptag optagelse';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Opretter forbindelse til OBD2-adapter…';

  @override
  String get tripStartProgressReadingVehicleData => 'Aflæser køretøjsdata…';

  @override
  String get tripStartProgressStartingRecording => 'Starter optagelse…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Færdiggør oversigt…';

  @override
  String get tripSaveProgressSavingToHistory => 'Gemmer i historik…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Synkroniserer i baggrunden…';

  @override
  String get trajetsEmptyStateTitle => 'Ingen ture endnu';

  @override
  String get trajetsEmptyStateBody =>
      'Tryk Start optagelse for at begynde at logge dine køreture.';

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
  String get trajetDetailSummaryTitle => 'Resumé';

  @override
  String get trajetDetailFieldDate => 'Dato';

  @override
  String get trajetDetailFieldVehicle => 'Køretøj';

  @override
  String get trajetDetailFieldAdapter => 'OBD2-adapter';

  @override
  String get trajetDetailFieldDistance => 'Afstand';

  @override
  String get trajetDetailFieldDuration => 'Varighed';

  @override
  String get trajetDetailFieldAvgConsumption => 'Gns. forbrug';

  @override
  String get trajetDetailFieldFuelUsed => 'Brændstof brugt';

  @override
  String get trajetDetailFieldFuelCost => 'Brændstofpris';

  @override
  String get trajetDetailFieldAvgSpeed => 'Gns. hastighed';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maks. hastighed';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Hastighed (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Brændstofrate (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Motorbelastning (%)';

  @override
  String get trajetDetailChartThrottle => 'Gas / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Kølevand (°C)';

  @override
  String get trajetDetailChartAltitudeRelative => 'Højde (m, fra start)';

  @override
  String get trajetDetailChartLambda => 'Kommanderet λ';

  @override
  String get trajetDetailChartsSection => 'Diagrammer';

  @override
  String get trajetsRowColdStartChip => 'Koldstart';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motoren nåede ikke driftstemperatur under denne tur — brændstofforbruget var højere end normalt.';

  @override
  String get trajetDetailChartEmpty => 'Ingen prøver registreret';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimeret';

  @override
  String get trajetDetailShareAction => 'Del';

  @override
  String get trajetDetailShareImageOption => 'Del billede';

  @override
  String get trajetDetailShareGpxOption => 'Del GPS-spor (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Ingen GPS-data i denne tur';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — tur den $date';
  }

  @override
  String get trajetDetailShareError => 'Kunne ikke generere delingsbillede';

  @override
  String get trajetDetailDownloadCsvOption => 'Download telemetri (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetri (JSON)';

  @override
  String get trajetDetailDownloadError => 'Kunne ikke gemme filen';

  @override
  String get trajetDetailDeleteAction => 'Slet';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Slet denne tur?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Denne tur fjernes permanent fra din historik.';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Slet';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2-adapter tilsluttet, men returnerer ingen data. Prøv en anden adapter eller tjek køretøjets diagnostikprotokol.';

  @override
  String get trajetsViewAllOnMap => 'Vis alle på kort';

  @override
  String get trajetsMapTitle => 'Ture på kort';

  @override
  String get trajetsMapShareGpx => 'Del GPX';

  @override
  String get trajetsMapEmpty => 'Ingen af de valgte ture indeholder GPS-data.';

  @override
  String get trajetsMapShareError => 'GPX-filen kunne ikke deles';

  @override
  String get trajetDetailChartBoost => 'Ladetryk (MAP − omgivelser)';

  @override
  String get trajetDetailChartIat => 'Indsugningsluftens temperatur';

  @override
  String get trajetDetailChartTiming => 'Tændingsforstilling';

  @override
  String get trajetObd2Degraded =>
      'Startet med OBD2-adapteren, men optaget mest via GPS — motordata er ufuldstændige';

  @override
  String get tripLengthCardTitle => 'Forbrug efter turlængde';

  @override
  String get tripLengthBucketShort => 'Kort (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Mellem (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Lang (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Brug for mere data';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ture',
      one: '1 tur',
      zero: 'ingen ture',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Tursti';

  @override
  String get tripPathCardSubtitle => 'GPS-optaget rute';

  @override
  String get tripPathLegendEfficient => 'Effektivt (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Grænsetilfælde (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Spildt (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Tankstationsradar';

  @override
  String get tripRadarScanning => 'Søger efter nærliggende stationer';

  @override
  String get tripRadarNoStationNearby => 'Ingen station i nærheden';

  @override
  String get fuelStationRadarNearer => 'Nærmere station';

  @override
  String get fuelStationRadarFarther => 'Fjernere station';

  @override
  String get fuelStationRadarStart => 'Start tankstationsradar';

  @override
  String get stopRadar => 'Stop radar';

  @override
  String get fuelStationRadarResultBadge => 'Tankstationsradar-resultat';

  @override
  String get radarUpdatingLocation => 'Opdaterer din placering…';

  @override
  String get radarSearching => 'Søger…';

  @override
  String get highwayModeChip =>
      'Motorvejstilstand — viser stationer forude på din rute';

  @override
  String get tripRecordingPinTooltip =>
      'Fastgørelse holder skærmen tændt — bruger mere batteri';

  @override
  String get tripRecordingPinSemanticOn => 'Frigør optagelsesformular';

  @override
  String get tripRecordingPinSemanticOff => 'Fastgør optagelsesformular';

  @override
  String get tripRecordingPinHelpTooltip => 'Hvad gør fastgørelse?';

  @override
  String get tripRecordingPinHelpTitle => 'Om fastgørelse';

  @override
  String get tripRecordingPinHelpBody =>
      'Fastgørelse holder skærmen tændt og skjuler systembjælker, så formularen forbliver læsbar på en instrumentbrætmontering. Tryk igen for at frigøre. Frigøres automatisk, når turen stopper.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Optagelse fortsætter i baggrunden. Tryk på det røde banner øverst på en vilkårlig skærm for at vende tilbage.';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Fastgør skærmen for at holde GPS aktiv under turen — Android kan begrænse GPS under søvn.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimér til en svævende flise';

  @override
  String get tripRecordingAutoPinTitle =>
      'Fastgør altid, når optagelsen starter';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Fastgør formularen automatisk hver tur i stedet for at trykke hver gang. Bruger mere batteri.';

  @override
  String get tripRecordingConnectingTitle => 'Starter optagelse…';

  @override
  String get tripRecordingSavingTitle => 'Gemmer tur…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Optagelse kasseret — ingen bevægelse registreret';

  @override
  String get tripRecordingGpsNotificationTitle => 'Optager din tur';

  @override
  String get tripRecordingGpsNotificationText =>
      'Sporer din rute til brændstof- og kørestatistik';

  @override
  String get tripShareAction => 'Del med en anden konto';

  @override
  String get tripShareSheetTitle => 'Del denne tur';

  @override
  String get tripShareSheetSubtitle =>
      'Giv en anden TankSync-konto skrivebeskyttet adgang til denne registrerede tur.';

  @override
  String get tripShareEmailLabel => 'Modtagerens e-mail';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Del';

  @override
  String get tripShareCreateLinkButton => 'Opret delingslink';

  @override
  String get tripShareLinkCreated =>
      'Delingslink kopieret — indsæt det til modtageren.';

  @override
  String get tripShareSuccess => 'Tur delt.';

  @override
  String get tripShareRecipientNotFound =>
      'Ingen TankSync-konto bruger den e-mail.';

  @override
  String get tripShareError => 'Kunne ikke dele denne tur. Prøv igen.';

  @override
  String get tripShareExistingTitle => 'Delt med';

  @override
  String get tripShareExistingEmpty => 'Ikke delt med nogen endnu.';

  @override
  String get tripShareDirectRecipient => 'En konto';

  @override
  String get tripShareLinkRecipient => 'Delingslink (ikke indløst)';

  @override
  String get tripShareRevokeTooltip => 'Tilbagekald';

  @override
  String get tripShareRevoked => 'Deling tilbagekaldt.';

  @override
  String get trajetsSharedSectionTitle => 'Delt med mig';

  @override
  String get trajetsSharedBadge => 'Delt';

  @override
  String get tripVerdictPromptTitle => 'Hvordan føltes denne tur?';

  @override
  String get tripVerdictSmooth => 'Blød';

  @override
  String get tripVerdictModerate => 'Moderat';

  @override
  String get tripVerdictAggressive => 'Aggressiv';

  @override
  String get tripVerdictDismiss => 'Ikke nu';

  @override
  String get tripVerdictThanks =>
      'Tak — det hjælper med at kalibrere din køreanalyse.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Tankning slettet';

  @override
  String get trajetDeletedUndoSnackbar => 'Optagelse slettet';

  @override
  String get searchFailedSnackbar => 'Søgning mislykkedes — prøv igen';

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
    return 'Opdateret $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Også: $names';
  }

  @override
  String get favoriteAdd => 'Tilføj til favoritter';

  @override
  String get favoriteRemove => 'Fjern fra favoritter';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Råpris: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Station uden kæde';

  @override
  String get unsupportedRegionTitle => 'Endnu ikke tilgængelig i din region';

  @override
  String get unsupportedRegionBody =>
      'Vi har endnu ingen brændstofpriser for dit land, så resultaterne kan være tomme eller fra et andet land. Du kan stadig vælge et understøttet land i søgeindstillingerne.';

  @override
  String get unsupportedRegionDismiss => 'Forstået';

  @override
  String get configureCountryTitle => 'Vælg dit land';

  @override
  String get configureCountryBody =>
      'Dit land understøttes, men er ikke sat op endnu — så priserne kan være fra et andet land. Vælg dit land i søgeindstillingerne for at se lokale priser.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Jeg tanker muligvis forskellige brændstoftyper';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Holder styr på, hvilket brændstof der er billigst pr. kilometer';

  @override
  String get vinLabel => 'VIN (valgfrit)';

  @override
  String get vinDecodeTooltip => 'Afkod VIN';

  @override
  String get vinConfirmAction => 'Ja, udfyld automatisk';

  @override
  String get vinModifyAction => 'Rediger manuelt';

  @override
  String get veResetAction => 'Nulstil volumetrisk effektivitet';

  @override
  String get vehicleReadVinFromCarButton => 'Aflæs VIN fra bilen';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Aflæs VIN fra den parrede OBD2-adapter';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN ikke tilgængelig (Mode 09 PID 02 understøttes ikke på køretøjer fra før 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN-aflæsning mislykkedes — angiv manuelt';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Par en OBD2-adapter først for automatisk at aflæse VIN';

  @override
  String get pickerButtonLabel => 'Vælg fra katalog';

  @override
  String get pickerSearchHint => 'Søg mærke eller model';

  @override
  String get pickerHelpText => 'Forudfyld fra 50+ understøttede køretøjer';

  @override
  String get pickerEmptyResults => 'Ingen resultater';

  @override
  String get pickerCancel => 'Annuller';

  @override
  String get pickerLoading => 'Indlæser katalog…';

  @override
  String get vinInfoTooltip => 'Hvad er et VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Hvad er et VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Køretøjsidentifikationsnummeret er en 17-tegns kode, der er unik for din bil. Det er stemplet på chassiset og trykt på dit køretøjsregistreringsdokument.';

  @override
  String get vinInfoSectionWhyTitle => 'Hvorfor vi spørger';

  @override
  String get vinInfoSectionWhyBody =>
      'Afkodning af VIN udfylder automatisk motorvolumen, cylinderantal, modelår, primær brændstoftype og totalvægt — og sparer dig for at slå tekniske specifikationer op manuelt. OBD2-brændstofrate-beregningen bruger disse værdier til at give dig præcise forbrugsnumre.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privatliv';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Dit VIN gemmes kun lokalt i appens krypterede lager — det uploades aldrig til Sparkilo-servere. NHTSA vPIC-databasen forespørges med VIN\'et, men returnerer kun anonyme tekniske specifikationer; NHTSA knytter ikke VIN\'et til personoplysninger. Uden netværk returnerer en offline opslag kun fabrikant og land.';

  @override
  String get vinInfoSectionWhereTitle => 'Hvor du finder det';

  @override
  String get vinInfoSectionWhereBody =>
      'Kig gennem forruden i det nederste venstre hjørne på førerens side, tjek klistermærket på dörkarm på førersiden, når døren er åben, eller aflæs det fra dit køretøjsregistreringsdokument (kort / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Forstået';

  @override
  String get vinConfirmPrivacyNote =>
      'Vi slog dit VIN op i NHTSA\'s gratis køretøjsdatabase — intet sendt til Sparkilo-servere.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online-afkodning';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Afkod VIN via NHTSA\'s gratis offentlige tjeneste';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Når du parrer en adapter, aflæses dit køretøjs VIN lokalt for at identificere bilen. Aktivering af dette sender det 17-tegns VIN til NHTSA\'s gratis vPIC-tjeneste for at slå yderligere detaljer op (model, motorvolumen, brændstoftype). VIN\'et er de eneste data, der sendes — ingen andre oplysninger forlader din enhed.';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Registreret fra VIN: $summary. Anvend?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Anvend';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometer fremme, $fuelType $euros euro $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Startskærm-widget';

  @override
  String get widgetHelpIntro =>
      'Tilføj SparKilo-widgetten til din startskærm for at se brændstof- og opladningspriser med ét blik.';

  @override
  String get widgetHelpAdd =>
      'Tilføj den fra din launchers widget-vælger — langt tryk på et tomt område af startskærmen, vælg Widgets, og find SparKilo.';

  @override
  String get widgetHelpTap =>
      'Tryk på en station i widgetten for at åbne den i appen. Tryk på opdateringsikonet for at opdatere priser.';

  @override
  String get widgetHelpConfigure =>
      'På Android: langt tryk på widgetten og vælg Genkonfigurér for at ændre profil, farve og indhold.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Valgene nedenfor gælder for alle installerede widgets ved næste opdatering.';

  @override
  String get widgetDefaultsColorLabel => 'Farvetema';

  @override
  String get widgetDefaultsVariantLabel => 'Indholdsvariant';

  @override
  String get widgetColorSchemeSystem => 'Følg systemet';

  @override
  String get widgetColorSchemeLight => 'Lys';

  @override
  String get widgetColorSchemeDark => 'Mørk';

  @override
  String get widgetColorSchemeBlue => 'Blå';

  @override
  String get widgetColorSchemeGreen => 'Grøn';

  @override
  String get widgetColorSchemeOrange => 'Orange';

  @override
  String get widgetVariantDefault => 'Kun aktuel pris';

  @override
  String get widgetVariantPredictive => 'Prædiktiv: bedste tidspunkt at tanke';
}
