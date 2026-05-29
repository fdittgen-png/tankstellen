// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Søk';

  @override
  String get favorites => 'Favoritter';

  @override
  String get map => 'Kart';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Innstillinger';

  @override
  String get gpsLocation => 'GPS-posisjon';

  @override
  String get zipCode => 'Postnummer';

  @override
  String get zipCodeHint => 'f.eks. 0101';

  @override
  String get fuelType => 'Drivstoff';

  @override
  String get searchRadius => 'Radius';

  @override
  String get searchNearby => 'Bensinstasjoner i nærheten';

  @override
  String get searchButton => 'Søk';

  @override
  String get fabOpenCriteria => 'Åpne søk';

  @override
  String get fabOpenResults => 'Åpne resultater';

  @override
  String get fabRunSearch => 'Kjør søk';

  @override
  String get fabRefineCriteria => 'Avgrens søk';

  @override
  String get routeSearchPartialBanner => 'Søker etter flere stasjoner…';

  @override
  String get searchCriteriaTitle => 'Søkekriterier';

  @override
  String get searchCriteriaOpen => 'Søk';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Innenfor $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Trykk for å starte søk';

  @override
  String get noResults => 'Ingen bensinstasjoner funnet.';

  @override
  String get startSearch => 'Søk for å finne bensinstasjoner.';

  @override
  String get open => 'Åpen';

  @override
  String get closed => 'Stengt';

  @override
  String distance(String distance) {
    return '$distance unna';
  }

  @override
  String get price => 'Pris';

  @override
  String get prices => 'Priser';

  @override
  String get address => 'Adresse';

  @override
  String get openingHours => 'Åpningstider';

  @override
  String get open24h => 'Åpent 24 timer';

  @override
  String get navigate => 'Naviger';

  @override
  String get retry => 'Prøv igjen';

  @override
  String get apiKeySetup => 'API-nøkkel';

  @override
  String get apiKeyDescription =>
      'Registrer deg én gang for å få en gratis API-nøkkel.';

  @override
  String get apiKeyLabel => 'API-nøkkel';

  @override
  String get register => 'Registrering';

  @override
  String get continueButton => 'Fortsett';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle => 'Finn det billigste drivstoffet i nærheten.';

  @override
  String get profileName => 'Profilnavn';

  @override
  String get preferredFuel => 'Foretrukket drivstoff';

  @override
  String get defaultRadius => 'Standard radius';

  @override
  String get landingScreen => 'Startskjerm';

  @override
  String get homeZip => 'Hjemmepostnummer';

  @override
  String get newProfile => 'Ny profil';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get save => 'Lagre';

  @override
  String get cancel => 'Avbryt';

  @override
  String get countryChangeTitle => 'Bytt land?';

  @override
  String countryChangeBody(String country) {
    return 'Bytte til $country vil endre:';
  }

  @override
  String get countryChangeCurrency => 'Valuta';

  @override
  String get countryChangeDistance => 'Avstand';

  @override
  String get countryChangeVolume => 'Volum';

  @override
  String get countryChangePricePerUnit => 'Prisformat';

  @override
  String get countryChangeNote =>
      'Eksisterende favoritter og tanklogg skrives ikke om; kun nye oppføringer bruker de nye enhetene.';

  @override
  String get countryChangeConfirm => 'Bytt';

  @override
  String get delete => 'Slett';

  @override
  String get activate => 'Aktiver';

  @override
  String get configured => 'Konfigurert';

  @override
  String get notConfigured => 'Ikke konfigurert';

  @override
  String get about => 'Om';

  @override
  String get openSource => 'Åpen kildekode (MIT-lisens)';

  @override
  String get sourceCode => 'Kildekode på GitHub';

  @override
  String get noFavorites => 'Ingen favoritter ennå';

  @override
  String get noFavoritesHint =>
      'Trykk på stjernen ved en bensinstasjon for å lagre den som favoritt.';

  @override
  String get language => 'Språk';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demomodus — eksempeldata vises.';

  @override
  String get setupLiveData => 'Konfigurer for sanntidsdata';

  @override
  String get freeNoKey => 'Gratis — ingen nøkkel nødvendig';

  @override
  String get apiKeyRequired => 'API-nøkkel kreves';

  @override
  String get skipWithoutKey => 'Fortsett uten nøkkel';

  @override
  String get dataTransparency => 'Datatransparens';

  @override
  String get storageAndCache => 'Lagring og hurtigbuffer';

  @override
  String get clearCache => 'Tøm hurtigbuffer';

  @override
  String get clearAllData => 'Slett alle data';

  @override
  String get errorLog => 'Feillogg';

  @override
  String stationsFound(int count) {
    return '$count bensinstasjoner funnet';
  }

  @override
  String get whatIsShared => 'Hva deles — og med hvem?';

  @override
  String get gpsCoordinates => 'GPS-koordinater';

  @override
  String get gpsReason =>
      'Sendes med hvert søk for å finne nærliggende stasjoner.';

  @override
  String get postalCodeData => 'Postnummer';

  @override
  String get postalReason =>
      'Konverteres til koordinater via geokodingstjenesten.';

  @override
  String get mapViewport => 'Kartutsnitt';

  @override
  String get mapReason =>
      'Kartfliser lastes fra serveren. Ingen personlige data overføres.';

  @override
  String get apiKeyData => 'API-nøkkel';

  @override
  String get apiKeyReason =>
      'Din personlige nøkkel sendes med hver API-forespørsel. Den er knyttet til din e-post.';

  @override
  String get notShared => 'Deles IKKE:';

  @override
  String get searchHistory => 'Søkehistorikk';

  @override
  String get favoritesData => 'Favoritter';

  @override
  String get profileNames => 'Profilnavn';

  @override
  String get homeZipData => 'Hjemmepostnummer';

  @override
  String get usageData => 'Bruksdata';

  @override
  String get privacyBanner =>
      'Denne appen har ingen server. Alle data forblir på enheten din. Ingen analyse, sporing eller reklame.';

  @override
  String get storageUsage => 'Lagringsbruk på denne enheten';

  @override
  String get settingsLabel => 'Innstillinger';

  @override
  String get profilesStored => 'profiler lagret';

  @override
  String get stationsMarked => 'stasjoner merket';

  @override
  String get cachedResponses => 'hurtigbufrede svar';

  @override
  String get total => 'Totalt';

  @override
  String get cacheManagement => 'Hurtigbufferadministrasjon';

  @override
  String get cacheDescription =>
      'Hurtigbufferen lagrer API-svar for raskere lasting og frakoblet tilgang.';

  @override
  String get cacheTtlGroupNetwork => 'Nettverk';

  @override
  String get cacheTtlGroupData => 'Data';

  @override
  String get cacheTtlGroupGeocoding => 'Geokoding';

  @override
  String get stationSearch => 'Stasjonssøk';

  @override
  String get stationDetails => 'Stasjonsdetaljer';

  @override
  String get priceQuery => 'Prisforespørsel';

  @override
  String get zipGeocoding => 'Postnummer-geokoding';

  @override
  String minutes(int n) {
    return '$n minutter';
  }

  @override
  String hours(int n) {
    return '$n timer';
  }

  @override
  String get clearCacheTitle => 'Tøm hurtigbuffer?';

  @override
  String get clearCacheBody =>
      'Hurtigbufrede søkeresultater og priser slettes. Profiler, favoritter og innstillinger beholdes.';

  @override
  String get clearCacheButton => 'Tøm hurtigbuffer';

  @override
  String get deleteAllTitle => 'Slette alle data?';

  @override
  String get deleteAllBody =>
      'Dette sletter permanent alle profiler, favoritter, API-nøkkel, innstillinger og hurtigbuffer. Appen tilbakestilles.';

  @override
  String get deleteAllButton => 'Slett alt';

  @override
  String get entries => 'oppføringer';

  @override
  String get cacheEmpty => 'Hurtigbufferen er tom';

  @override
  String get noStorage => 'Ingen lagring brukt';

  @override
  String get apiKeyNote =>
      'Gratis registrering. Data fra statlige pristransparensorganer.';

  @override
  String get apiKeyFormatError =>
      'Ugyldig format — forventet UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Støtt dette prosjektet';

  @override
  String get supportDescription =>
      'Denne appen er gratis, åpen kildekode og uten reklame. Hvis du finner den nyttig, vurder å støtte utvikleren.';

  @override
  String get reportBug => 'Rapporter feil / Foreslå funksjon';

  @override
  String get reportThisIssue => 'Rapporter dette problemet';

  @override
  String get reportAlreadySent => 'Du har allerede rapportert dette problemet.';

  @override
  String get reportConsentTitle => 'Rapporter til GitHub?';

  @override
  String get reportConsentBody =>
      'Dette åpner et offentlig GitHub-problem med feildetaljene nedenfor. Ingen GPS-koordinater, API-nøkler eller personopplysninger er inkludert.';

  @override
  String get reportConsentConfirm => 'Åpne GitHub';

  @override
  String get reportConsentCancel => 'Avbryt';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktiv profil';

  @override
  String get configPreferredFuel => 'Foretrukket drivstoff';

  @override
  String get configCountry => 'Land';

  @override
  String get configRouteSegment => 'Rutestrekning';

  @override
  String get configApiKeysSection => 'API-nøkler';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-nøkkel';

  @override
  String get configApiKeyConfigured => 'Konfigurert';

  @override
  String get configApiKeyNotSet => 'Ikke angitt (demomodus)';

  @override
  String get configApiKeyCommunity => 'Standard (fellesskapsnøkkel)';

  @override
  String get searchLocationPlaceholder => 'Adresse, postnummer eller by';

  @override
  String get configEvKey => 'EV-lading API-nøkkel';

  @override
  String get configEvKeyCustom => 'Egendefinert nøkkel';

  @override
  String get configEvKeyShared => 'Standard (delt)';

  @override
  String get configCloudSyncSection => 'Skysynkronisering';

  @override
  String get configTankSyncConnected => 'Tilkoblet';

  @override
  String get configTankSyncDisabled => 'Deaktivert';

  @override
  String get configAuthMode => 'Autentiseringsmodus';

  @override
  String get configAuthEmail => 'E-post (vedvarende)';

  @override
  String get configAuthAnonymous => 'Anonym (kun denne enheten)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Personvernoversikt';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoritter, varsler og ignorerte stasjoner synkroniseres til din private database\n• GPS-posisjon og API-nøkler forlater aldri enheten din\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Alle data lagres kun lokalt på denne enheten\n• Ingen data sendes til noen server\n• API-nøkler kryptert i enhetens sikre lagring';

  @override
  String get configAuthNoteEmail => 'E-postkonto gir tilgang fra flere enheter';

  @override
  String get configAuthNoteAnonymous =>
      'Anonym konto – data er knyttet til denne enheten';

  @override
  String get configNone => 'Ingen';

  @override
  String get privacyPolicy => 'Personvernerklæring';

  @override
  String get fuels => 'Drivstoff';

  @override
  String get services => 'Tjenester';

  @override
  String get zone => 'Sone';

  @override
  String get highway => 'Motorvei';

  @override
  String get localStation => 'Lokal stasjon';

  @override
  String get lastUpdate => 'Siste oppdatering';

  @override
  String get automate24h => '24t/24 — Automat';

  @override
  String get refreshPrices => 'Oppdater priser';

  @override
  String get station => 'Bensinstasjon';

  @override
  String get locationDenied =>
      'Plasseringstillatelse nektet. Du kan søke etter postnummer.';

  @override
  String get demoModeBanner =>
      'Demomodus. Konfigurer API-nøkkel i innstillinger.';

  @override
  String get demoModeBannerAction => 'Få live-priser';

  @override
  String get sortDistance => 'Avstand';

  @override
  String get sortOpen24h => '24t';

  @override
  String get sortRating => 'Vurdering';

  @override
  String get sortPriceDistance => 'Pris/km';

  @override
  String get cheap => 'billig';

  @override
  String get expensive => 'dyr';

  @override
  String stationsOnMap(int count) {
    return '$count stasjoner';
  }

  @override
  String get loadingFavorites =>
      'Laster favoritter...\nSøk etter stasjoner først for å lagre data.';

  @override
  String get reportPrice => 'Rapporter pris';

  @override
  String get whatsWrong => 'Hva er galt?';

  @override
  String get correctPrice => 'Korrekt pris (f.eks. 15,79)';

  @override
  String get sendReport => 'Send rapport';

  @override
  String get reportSent => 'Rapport sendt. Takk!';

  @override
  String get enterValidPrice => 'Vennligst oppgi en gyldig pris';

  @override
  String get cacheCleared => 'Hurtigbuffer tømt.';

  @override
  String get yourPosition => 'Din posisjon';

  @override
  String get positionUnknown => 'Posisjon ukjent';

  @override
  String get routeModeBannerLabel =>
      'Rutemodus — avstander er langs korridoren';

  @override
  String get distancesFromCenter => 'Avstander fra søkesentrum';

  @override
  String get autoUpdatePosition => 'Oppdater posisjon automatisk';

  @override
  String get autoUpdateDescription => 'Oppdater GPS-posisjon før hvert søk';

  @override
  String get location => 'Plassering';

  @override
  String get switchProfileTitle => 'Land endret';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Du er nå i $country. Bytte til profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Byttet til profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ingen profil for dette landet';

  @override
  String noProfileForCountry(String country) {
    return 'Du er i $country, men ingen profil er konfigurert. Opprett en i Innstillinger.';
  }

  @override
  String get autoSwitchProfile => 'Automatisk profilbytte';

  @override
  String get autoSwitchDescription =>
      'Bytt profil automatisk ved grensepassering';

  @override
  String get switchProfile => 'Bytt';

  @override
  String get dismiss => 'Lukk';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Språk';

  @override
  String get settingsStorageDetail => 'API-nøkkel, aktiv profil';

  @override
  String get allFuels => 'Alle';

  @override
  String get priceAlerts => 'Prisalarmer';

  @override
  String get noPriceAlerts => 'Ingen prisalarmer';

  @override
  String get noPriceAlertsHint =>
      'Opprett en alarm fra en stasjons detaljside.';

  @override
  String alertDeleted(String name) {
    return 'Alarm \"$name\" slettet';
  }

  @override
  String get createAlert => 'Opprett prisalarm';

  @override
  String currentPrice(String price) {
    return 'Nåværende pris: $price';
  }

  @override
  String get targetPrice => 'Målpris (EUR)';

  @override
  String get enterPrice => 'Oppgi en pris';

  @override
  String get invalidPrice => 'Ugyldig pris';

  @override
  String get priceTooHigh => 'Prisen er for høy';

  @override
  String get create => 'Opprett';

  @override
  String get alertCreated => 'Prisalarm opprettet';

  @override
  String get wrongE5Price => 'Feil Super E5-pris';

  @override
  String get wrongE10Price => 'Feil Super E10-pris';

  @override
  String get wrongDieselPrice => 'Feil dieselpris';

  @override
  String get wrongStatusOpen => 'Vist som åpen, men stengt';

  @override
  String get wrongStatusClosed => 'Vist som stengt, men åpen';

  @override
  String get searchAlongRouteLabel => 'Langs ruten';

  @override
  String get searchEvStations => 'Søk ladestasjoner';

  @override
  String get allStations => 'Alle stasjoner';

  @override
  String get bestStops => 'Beste stopp';

  @override
  String get openInMaps => 'Åpne i Kart';

  @override
  String get noStationsAlongRoute => 'Ingen stasjoner funnet langs ruten';

  @override
  String get evOperational => 'I drift';

  @override
  String get evStatusUnknown => 'Status ukjent';

  @override
  String evConnectors(int count) {
    return 'Kontakter ($count punkter)';
  }

  @override
  String get evNoConnectors => 'Ingen kontaktdetaljer tilgjengelig';

  @override
  String get evUsageCost => 'Brukskostnad';

  @override
  String get evPricingUnavailable => 'Prising ikke tilgjengelig fra leverandør';

  @override
  String get evLastUpdated => 'Sist oppdatert';

  @override
  String get evUnknown => 'Ukjent';

  @override
  String get evDataAttribution => 'Data fra OpenChargeMap (felleskilde)';

  @override
  String get evStatusDisclaimer =>
      'Status gjenspeiler kanskje ikke tilgjengelighet i sanntid. Trykk oppdater for å hente siste data.';

  @override
  String get evNavigateToStation => 'Naviger til stasjon';

  @override
  String get evRefreshStatus => 'Oppdater status';

  @override
  String get evStatusUpdated => 'Status oppdatert';

  @override
  String get evStationNotFound =>
      'Kunne ikke oppdatere — stasjon ikke funnet i nærheten';

  @override
  String get addedToFavorites => 'Lagt til i favoritter';

  @override
  String get removedFromFavorites => 'Fjernet fra favoritter';

  @override
  String get addFavorite => 'Legg til i favoritter';

  @override
  String get removeFavorite => 'Fjern fra favoritter';

  @override
  String get currentLocation => 'Nåværende posisjon';

  @override
  String get gpsError => 'GPS-feil';

  @override
  String get couldNotResolve => 'Kunne ikke bestemme start eller destinasjon';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destinasjon';

  @override
  String get cityAddressOrGps => 'By, adresse eller GPS';

  @override
  String get cityOrAddress => 'By eller adresse';

  @override
  String get useGps => 'Bruk GPS';

  @override
  String get stop => 'Stopp';

  @override
  String stopN(int n) {
    return 'Stopp $n';
  }

  @override
  String get addStop => 'Legg til stopp';

  @override
  String get searchAlongRoute => 'Søk langs ruten';

  @override
  String get cheapest => 'Billigst';

  @override
  String nStations(int count) {
    return '$count stasjoner';
  }

  @override
  String nBest(int count) {
    return '$count beste';
  }

  @override
  String get fuelPricesTankerkoenig => 'Drivstoffpriser (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Påkrevd for drivstoffprissøk i Tyskland';

  @override
  String get evChargingOpenChargeMap => 'EV-lading (OpenChargeMap)';

  @override
  String get customKey => 'Egendefinert nøkkel';

  @override
  String get appDefaultKey => 'Standard app-nøkkel';

  @override
  String get optionalOverrideKey =>
      'Valgfritt: erstatt den innebygde app-nøkkelen med din egen';

  @override
  String get requiredForEvSearch => 'Påkrevd for søk etter EV-ladestasjoner';

  @override
  String get edit => 'Rediger';

  @override
  String get fuelPricesApiKey => 'Drivstoffpriser API-nøkkel';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-nøkkel';

  @override
  String get evChargingApiKey => 'EV-lading API-nøkkel';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-nøkkel';

  @override
  String get routePlanningSection => 'Ruteplanlegging';

  @override
  String get routeMinSaving => 'Minste besparelse';

  @override
  String get routeMinSavingOff => 'Av';

  @override
  String get routeMinSavingOffCaption =>
      'Viser alle stasjoner funnet langs ruten';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Bare stasjoner innenfor $amount av den billigste på ruten';
  }

  @override
  String get routeDetourBudget => 'Maksimal omvei';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Vis stasjoner opptil $km km fra den direkte ruten';
  }

  @override
  String get routeSegment => 'Rutesegment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Vis billigste stasjon for hver $km km langs ruten';
  }

  @override
  String get avoidHighways => 'Unngå motorveier';

  @override
  String get avoidHighwaysDesc =>
      'Ruteberegning unngår bompenger og motorveier';

  @override
  String get showFuelStations => 'Vis bensinstasjoner';

  @override
  String get showFuelStationsDesc =>
      'Inkluder bensin-, diesel-, LPG-, CNG-stasjoner';

  @override
  String get showEvStations => 'Vis ladestasjoner';

  @override
  String get showEvStationsDesc =>
      'Inkluder elektriske ladestasjoner i søkeresultater';

  @override
  String get noStationsAlongThisRoute =>
      'Ingen stasjoner funnet langs denne ruten.';

  @override
  String get fuelCostCalculator => 'Drivstoffkostnadsberegner';

  @override
  String get distanceKm => 'Avstand (km)';

  @override
  String get consumptionL100km => 'Forbruk (L/100km)';

  @override
  String get fuelPriceEurL => 'Drivstoffpris (EUR/L)';

  @override
  String get tripCost => 'Turkostnad';

  @override
  String get fuelNeeded => 'Nødvendig drivstoff';

  @override
  String get totalCost => 'Totalkostnad';

  @override
  String get enterCalcValues =>
      'Oppgi avstand, forbruk og pris for å beregne turkostnaden';

  @override
  String get priceHistory => 'Prishistorikk';

  @override
  String get ignoredStationsLabel => 'Ignorert';

  @override
  String get ratingsLabel => 'Vurderinger';

  @override
  String get favoritesDataCache => 'Favorittdata';

  @override
  String get citySearchCache => 'Bysøk';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Sletting av data er ikke tilgjengelig i Fellesskap-modus. Koble fra først, eller bruk en privat database.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count sporede stasjoner';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count konfigurert';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count skjulte stasjoner';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count vurderte stasjoner';
  }

  @override
  String get noPriceHistory => 'Ingen prishistorikk ennå';

  @override
  String get noHourlyData => 'Ingen timedata';

  @override
  String get noStatistics => 'Ingen statistikk tilgjengelig';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Snitt';

  @override
  String get showAllFuelTypes => 'Vis alle drivstofftyper';

  @override
  String get connected => 'Tilkoblet';

  @override
  String get notConnected => 'Ikke tilkoblet';

  @override
  String get connectTankSync => 'Koble til TankSync';

  @override
  String get disconnectTankSync => 'Koble fra TankSync';

  @override
  String get viewMyData => 'Se mine data';

  @override
  String get optionalCloudSync =>
      'Valgfri skysynkronisering for alarmer, favoritter og push-varsler';

  @override
  String get tapToUpdateGps => 'Trykk for å oppdatere GPS-posisjon';

  @override
  String get gpsAutoUpdateHint =>
      'GPS-posisjonen hentes automatisk ved søk. Du kan også oppdatere den manuelt her.';

  @override
  String get clearGpsConfirm =>
      'Tøm lagret GPS-posisjon? Du kan oppdatere den igjen når som helst.';

  @override
  String get pageNotFound => 'Siden ble ikke funnet';

  @override
  String get deleteAllServerData => 'Slett alle serverdata';

  @override
  String get deleteServerDataConfirm => 'Slette alle serverdata?';

  @override
  String get deleteEverything => 'Slett alt';

  @override
  String get allDataDeleted => 'Alle serverdata slettet';

  @override
  String get forgetAllSyncedTripsButton => 'Glem alle synkroniserte turer';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Glem alle synkroniserte turer?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Alle tursammendrag og detaljer vil bli fjernet fra serveren. Din lokale turhistorikk på denne enheten påvirkes ikke.\n\nDenne handlingen kan ikke angres.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Glem alle';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Alle synkroniserte turer fjernet fra server';

  @override
  String get disconnectConfirm => 'Koble fra TankSync?';

  @override
  String get disconnect => 'Koble fra';

  @override
  String get myServerData => 'Mine serverdata';

  @override
  String get anonymousUuid => 'Anonym UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synkroniserte data';

  @override
  String get pushTokens => 'Push-tokener';

  @override
  String get priceReports => 'Prisrapporter';

  @override
  String get syncedTrips => 'Turer';

  @override
  String get totalItems => 'Totalt antall';

  @override
  String get estimatedSize => 'Estimert størrelse';

  @override
  String get viewRawJson => 'Se rådata som JSON';

  @override
  String get exportJson => 'Eksporter som JSON (utklippstavle)';

  @override
  String get jsonCopied => 'JSON kopiert til utklippstavlen';

  @override
  String get rawDataJson => 'Rådata (JSON)';

  @override
  String get close => 'Lukk';

  @override
  String get account => 'Konto';

  @override
  String get continueAsGuest => 'Fortsett som gjest';

  @override
  String get createAccount => 'Opprett konto';

  @override
  String get signIn => 'Logg inn';

  @override
  String get upgradeToEmail => 'Opprett e-postkonto';

  @override
  String get savedRoutes => 'Lagrede ruter';

  @override
  String get noSavedRoutes => 'Ingen lagrede ruter';

  @override
  String get noSavedRoutesHint =>
      'Søk langs en rute og lagre den for rask tilgang senere.';

  @override
  String get saveRoute => 'Lagre rute';

  @override
  String get routeName => 'Rutenavn';

  @override
  String itineraryDeleted(String name) {
    return '$name slettet';
  }

  @override
  String loadingRoute(String name) {
    return 'Laster rute: $name';
  }

  @override
  String get refreshFailed => 'Oppdatering mislyktes. Prøv igjen.';

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
  String get onboardingWelcomeHint => 'Sett opp appen i noen enkle steg.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrer deg for en gratis API-nøkkel, eller hopp over for å utforske appen med demodata.';

  @override
  String get onboardingComplete => 'Alt klart!';

  @override
  String get onboardingCompleteHint =>
      'Du kan endre disse innstillingene når som helst i profilen din.';

  @override
  String get onboardingBack => 'Tilbake';

  @override
  String get onboardingNext => 'Neste';

  @override
  String get onboardingSkip => 'Hopp over';

  @override
  String get onboardingFinish => 'Kom i gang';

  @override
  String crossBorderNearby(String country) {
    return '$country er i nærheten';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km til grensen';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Snitt her: $price EUR ($count stasjoner)';
  }

  @override
  String get allPricesView => 'Alle priser';

  @override
  String get compactView => 'Kompakt';

  @override
  String get switchToAllPricesView => 'Bytt til visning med alle priser';

  @override
  String get switchToCompactView => 'Bytt til kompakt visning';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Ikke på lager';

  @override
  String get gdprTitle => 'Ditt personvern';

  @override
  String get gdprSubtitle =>
      'Denne appen respekterer personvernet ditt. Velg hvilke data du vil dele. Du kan endre disse innstillingene når som helst.';

  @override
  String get gdprLocationTitle => 'Tilgang til posisjon';

  @override
  String get gdprLocationDescription =>
      'Koordinatene dine sendes til drivstoffpris-API for å finne nærliggende stasjoner. Posisjonsdata lagres aldri på en server og brukes ikke til sporing.';

  @override
  String get gdprLocationShort =>
      'Finn nærliggende drivstoffstasjoner ved hjelp av posisjonen din';

  @override
  String get gdprErrorReportingTitle => 'Feilrapportering';

  @override
  String get gdprErrorReportingDescription =>
      'Anonyme krasjrapporter bidrar til å forbedre appen. Ingen personopplysninger er inkludert. Rapporter sendes via Sentry kun når det er konfigurert.';

  @override
  String get gdprErrorReportingShort =>
      'Send anonyme krasjrapporter for å forbedre appen';

  @override
  String get gdprCloudSyncTitle => 'Skysynkronisering';

  @override
  String get gdprCloudSyncDescription =>
      'Synkroniser favoritter og varsler på tvers av enheter via TankSync. Bruker anonym autentisering. Dataene dine er kryptert under overføring.';

  @override
  String get gdprCloudSyncShort =>
      'Synkroniser favoritter og varsler på tvers av enheter';

  @override
  String get gdprLegalBasis =>
      'Rettslig grunnlag: Art. 6(1)(a) GDPR (Samtykke). Du kan trekke tilbake samtykket når som helst i Innstillinger.';

  @override
  String get gdprAcceptAll => 'Godta alle';

  @override
  String get gdprAcceptSelected => 'Godta valgte';

  @override
  String get gdprSettingsHint =>
      'Du kan endre personvernvalgene dine når som helst.';

  @override
  String get routeSaved => 'Rute lagret!';

  @override
  String get routeSaveFailed => 'Lagring av rute mislyktes';

  @override
  String get sqlCopied => 'SQL kopiert til utklippstavle';

  @override
  String get connectionDataCopied => 'Tilkoblingsdata kopiert';

  @override
  String get accountDeleted => 'Konto slettet. Lokale data bevart.';

  @override
  String get switchedToAnonymous => 'Byttet til anonym økt';

  @override
  String failedToSwitch(String error) {
    return 'Bytte mislyktes: $error';
  }

  @override
  String get topicUrlCopied => 'Emne-URL kopiert';

  @override
  String get testNotificationSent => 'Testvarsling sendt!';

  @override
  String get testNotificationFailed => 'Sending av testvarsling mislyktes';

  @override
  String get pushUpdateFailed => 'Oppdatering av push-varsling mislyktes';

  @override
  String get connectedAsGuest => 'Tilkoblet som gjest';

  @override
  String get accountCreated => 'Konto opprettet!';

  @override
  String get signedIn => 'Logget inn!';

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
    return 'Ugyldig API-nøkkel: $error';
  }

  @override
  String get invalidQrCode => 'Ugyldig QR-kodeformat';

  @override
  String get invalidQrCodeTankSync =>
      'Ugyldig QR-kode – forventet TankSync-format';

  @override
  String get tankSyncConnected => 'TankSync tilkoblet!';

  @override
  String get syncCompleted => 'Synkronisering fullført – data oppdatert';

  @override
  String get deviceCodeCopied => 'Enhetskode kopiert';

  @override
  String get undo => 'Angre';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Skriv inn et gyldig $length-sifret $label';
  }

  @override
  String get freshnessAgo => 'siden';

  @override
  String get freshnessStale => 'Utdatert';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Dataferskhet: $age';
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
      other: 'Gi $count stjerner',
      one: 'Gi 1 stjerne',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Svakt';

  @override
  String get passwordStrengthFair => 'Middels';

  @override
  String get passwordStrengthStrong => 'Sterkt';

  @override
  String get passwordReqMinLength => 'Minst 8 tegn';

  @override
  String get passwordReqUppercase => 'Minst 1 stor bokstav';

  @override
  String get passwordReqLowercase => 'Minst 1 liten bokstav';

  @override
  String get passwordReqDigit => 'Minst 1 tall';

  @override
  String get passwordReqSpecial => 'Minst 1 spesialtegn';

  @override
  String get passwordTooWeak => 'Passordet oppfyller ikke alle kravene';

  @override
  String get brandFilterAll => 'Alle';

  @override
  String get brandFilterNoHighway => 'Ingen motorvei';

  @override
  String get swipeTutorialMessage =>
      'Sveip høyre for å navigere, sveip venstre for å fjerne';

  @override
  String get swipeTutorialDismiss => 'Skjønt';

  @override
  String get alertStatsActive => 'Aktive';

  @override
  String get alertStatsToday => 'I dag';

  @override
  String get alertStatsThisWeek => 'Denne uken';

  @override
  String get privacyDashboardTitle => 'Personvernoversikt';

  @override
  String get privacyDashboardSubtitle =>
      'Vis, eksporter eller slett dataene dine';

  @override
  String get privacyDashboardBanner =>
      'Dataene dine tilhører deg. Her kan du se alt denne appen lagrer, eksportere det eller slette det.';

  @override
  String get privacyLocalData => 'Data på denne enheten';

  @override
  String get privacyIgnoredStations => 'Ignorerte stasjoner';

  @override
  String get privacyRatings => 'Stasjonsanmeldelser';

  @override
  String get privacyPriceHistory => 'Prishistorikk-stasjoner';

  @override
  String get privacyProfiles => 'Søkeprofiler';

  @override
  String get privacyItineraries => 'Lagrede ruter';

  @override
  String get privacyCacheEntries => 'Bufferposter';

  @override
  String get privacyApiKey => 'API-nøkkel lagret';

  @override
  String get privacyEvApiKey => 'EV API-nøkkel lagret';

  @override
  String get privacyEstimatedSize => 'Estimert lagring';

  @override
  String get privacySyncedData => 'Skysynk (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Skysynkronisering er deaktivert. Alle data forblir kun på denne enheten.';

  @override
  String get privacySyncMode => 'Synkmodus';

  @override
  String get privacySyncUserId => 'Bruker-ID';

  @override
  String get privacySyncDescription =>
      'Når synkronisering er aktivert, lagres favoritter, varsler, ignorerte stasjoner og vurderinger også på TankSync-serveren.';

  @override
  String get privacyViewServerData => 'Vis serverdata';

  @override
  String get privacyExportButton => 'Eksporter alle data som JSON';

  @override
  String get privacyExportSuccess => 'Data eksportert til utklippstavle';

  @override
  String get privacyExportCsvButton => 'Eksporter alle data som CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV-data eksportert til utklippstavle';

  @override
  String get savedToDownloadsFolder => 'Lagret i Nedlastinger-mappen';

  @override
  String get privacyDeleteButton => 'Slett alle data';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopier feillogg til utklippstavle ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Lagre feillogg ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Tøm feilloggen';

  @override
  String get privacyErrorLogCleared => 'Feilloggen tømt';

  @override
  String get privacyDeleteTitle => 'Slette alle data?';

  @override
  String get privacyDeleteBody =>
      'Dette vil permanent slette:\n\n- Alle favoritter og stasjonsdata\n- Alle søkeprofiler\n- Alle prisvarsler\n- All prishistorikk\n- Alle bufferdata\n- API-nøkkelen din\n- Alle appinnstillinger\n\nAppen vil tilbakestilles til opprinnelig tilstand. Denne handlingen kan ikke angres.';

  @override
  String get privacyDeleteConfirm => 'Slett alt';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nei';

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
  String get paymentMethodFuelCard => 'Drivstoffkort';

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
    return 'Sammenlignet med det rullende gjennomsnittet over dine siste 3 tankinger ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Forbruk $value L/100 km, $delta mot ditt rullende gjennomsnitt';
  }

  @override
  String get drivingMode => 'Kjøremodus';

  @override
  String get drivingExit => 'Avslutt';

  @override
  String get drivingNearestStation => 'Nærmeste';

  @override
  String get drivingTapToUnlock => 'Trykk for å låse opp';

  @override
  String get drivingSafetyTitle => 'Sikkerhetsmelding';

  @override
  String get drivingSafetyMessage =>
      'Ikke bruk appen under kjøring. Parker på et trygt sted før du samhandler med skjermen. Sjåføren er alltid ansvarlig for trygg kjøring.';

  @override
  String get drivingSafetyAccept => 'Jeg forstår';

  @override
  String get voiceAnnouncementsTitle => 'Taleannonsering';

  @override
  String get voiceAnnouncementsDescription =>
      'Annonser nærliggende billige stasjoner under kjøring';

  @override
  String get voiceAnnouncementsEnabled => 'Aktiver taleannonsering';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Kun under $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometer fremover, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Annonseringsradius';

  @override
  String get voiceAnnouncementCooldown => 'Gjentakelsesintervall';

  @override
  String get nearestStations => 'Naermeste stasjoner';

  @override
  String get nearestStationsHint =>
      'Finn de naermeste stasjonene med din navaerende posisjon';

  @override
  String get consumptionLogTitle => 'Drivstofforbruk';

  @override
  String get consumptionLogMenuTitle => 'Forbrukslogg';

  @override
  String get consumptionLogMenuSubtitle => 'Spor tankinger og beregn L/100km';

  @override
  String get consumptionStatsTitle => 'Forbruksstatistikk';

  @override
  String get addFillUp => 'Legg til tanking';

  @override
  String get noFillUpsTitle => 'Ingen tankinger ennå';

  @override
  String get noFillUpsSubtitle =>
      'Logg den første tankingen for å starte forbrukssporing.';

  @override
  String get fillUpDate => 'Dato';

  @override
  String get liters => 'Liter';

  @override
  String get odometerKm => 'Kilometerstand (km)';

  @override
  String get notesOptional => 'Notater (valgfritt)';

  @override
  String get stationPreFilled => 'Stasjon forhåndsutfylt';

  @override
  String get statAvgConsumption => 'Snitt L/100km';

  @override
  String get statAvgCostPerKm => 'Snittkostand/km';

  @override
  String get statTotalLiters => 'Totalt antall liter';

  @override
  String get statTotalSpent => 'Totalt brukt';

  @override
  String get statFillUpCount => 'Tankinger';

  @override
  String get fieldRequired => 'Påkrevd';

  @override
  String get fieldInvalidNumber => 'Ugyldig tall';

  @override
  String get carbonDashboardTitle => 'Karbondashbord';

  @override
  String get carbonEmptyTitle => 'Ingen data ennå';

  @override
  String get carbonEmptySubtitle =>
      'Logg tankinger for å se karbondashbordet ditt.';

  @override
  String get carbonSummaryTotalCost => 'Total kostnad';

  @override
  String get carbonSummaryTotalCo2 => 'Total CO2';

  @override
  String get monthlyCostsTitle => 'Månedlige kostnader';

  @override
  String get monthlyEmissionsTitle => 'Månedlige CO2-utslipp';

  @override
  String get vehiclesTitle => 'Mine kjøretøy';

  @override
  String get vehiclesMenuTitle => 'Mine kjøretøy';

  @override
  String get vehiclesMenuSubtitle => 'Batteri, kontakter, ladepreferanser';

  @override
  String get vehiclesEmptyMessage =>
      'Legg til bilen din for å filtrere etter kontakt og estimere ladekostnader.';

  @override
  String get vehiclesWizardTitle => 'Mine kjøretøy (valgfritt)';

  @override
  String get vehiclesWizardSubtitle =>
      'Legg til bilen din for å forhåndsutfylle forbruksloggen og aktivere EV-kontaktfiltre. Du kan hoppe over dette og legge til kjøretøy senere.';

  @override
  String get vehiclesWizardNoneYet => 'Ingen kjøretøy konfigurert ennå.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kjøretøy',
      one: '1 kjøretøy',
    );
    return 'Du har $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Hopp over for å fullføre oppsett – du kan legge til kjøretøy når som helst fra Innstillinger.';

  @override
  String get fillUpVehicleLabel => 'Kjøretøy';

  @override
  String get fillUpVehicleNone => 'Ingen kjøretøy';

  @override
  String get fillUpVehicleRequired => 'Kjøretøy er påkrevd';

  @override
  String get reportScanError => 'Rapporter skanningsfeil';

  @override
  String get pickStationTitle => 'Velg en stasjon';

  @override
  String get pickStationHelper =>
      'Start tankingen fra en kjent stasjon slik at priser, merke og drivstofftype fylles ut automatisk.';

  @override
  String get pickStationEmpty =>
      'Ingen favorittstasjoner ennå – legg til noen fra Søk eller Favoritter, eller hopp over og fyll inn manuelt.';

  @override
  String get pickStationSkip => 'Hopp over – legg til uten stasjon';

  @override
  String get scanPump => 'Skann pumpe';

  @override
  String get scanPayment => 'Skann betalings-QR';

  @override
  String get qrPaymentBeneficiary => 'Mottaker';

  @override
  String get qrPaymentAmount => 'Beløp';

  @override
  String get qrPaymentEpcTitle => 'SEPA-betaling';

  @override
  String get qrPaymentEpcEmpty => 'Ingen felt dekodert';

  @override
  String get qrPaymentOpenInBank => 'Åpne i bankapp';

  @override
  String get qrPaymentLaunchFailed =>
      'Ingen app tilgjengelig for å åpne denne koden';

  @override
  String get qrPaymentUnknownTitle => 'Ikke gjenkjent kode';

  @override
  String get qrPaymentCopyRaw => 'Kopier rå tekst';

  @override
  String get qrPaymentCopiedRaw => 'Kopiert til utklippstavle';

  @override
  String get qrPaymentReport => 'Rapporter denne skanningen';

  @override
  String get qrPaymentEpcCopied =>
      'Bankdetaljer kopiert – lim inn i bankappen din';

  @override
  String get qrScannerGuidance => 'Pek kameraet mot en QR-kode';

  @override
  String get qrScannerPermissionDenied =>
      'Kameratilgang er nødvendig for å skanne QR-koder.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kameratilgang ble nektet. Åpne innstillinger for å gi tillatelse.';

  @override
  String get qrScannerRetryPermission => 'Prøv igjen';

  @override
  String get qrScannerOpenSettings => 'Åpne innstillinger';

  @override
  String get qrScannerTimeout =>
      'Ingen QR-kode oppdaget. Flytt nærmere eller prøv igjen.';

  @override
  String get qrScannerRetry => 'Prøv igjen';

  @override
  String get torchOn => 'Slå på blits';

  @override
  String get torchOff => 'Slå av blits';

  @override
  String get obdNoAdapter => 'Ingen OBD2-adapter innenfor rekkevidde';

  @override
  String get obdOdometerUnavailable => 'Kunne ikke lese kilometerstand';

  @override
  String get obdPermissionDenied =>
      'Gi Bluetooth-tillatelse i systeminnstillinger';

  @override
  String get obdAdapterUnresponsive =>
      'Adapteren svarte ikke – slå på tenningen og prøv igjen';

  @override
  String get obdPickerTitle => 'Velg en OBD2-adapter';

  @override
  String get obdPickerScanning => 'Skanner etter adaptere…';

  @override
  String get obdPickerConnecting => 'Kobler til…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Lyst';

  @override
  String get themeModeDark => 'Mørkt';

  @override
  String get themeModeSystem => 'Følg system';

  @override
  String get tripRecordingTitle => 'Tar opp tur';

  @override
  String get tripSummaryTitle => 'Tursammendrag';

  @override
  String get tripMetricDistance => 'Avstand';

  @override
  String get tripMetricSpeed => 'Hastighet';

  @override
  String get tripMetricFuelUsed => 'Drivstoff brukt';

  @override
  String get tripMetricAvgConsumption => 'Snitt';

  @override
  String get tripMetricElapsed => 'Medgått tid';

  @override
  String get tripMetricOdometer => 'Kilometerstand';

  @override
  String get tripStop => 'Stopp opptak';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Fortsett';

  @override
  String get tripBannerRecording => 'Tar opp tur';

  @override
  String get tripBannerPaused => 'Tur på pause – trykk for å fortsette';

  @override
  String get navConsumption => 'Forbruk';

  @override
  String get vehicleBaselineSectionTitle => 'Grunnleggende kalibrering';

  @override
  String get vehicleBaselineEmpty =>
      'Ingen prøver ennå – start en OBD2-tur for å begynne å lære dette kjøretøyets drivstoffprofil.';

  @override
  String get vehicleBaselineProgress =>
      'Lært fra prøver på tvers av kjøresituasjoner.';

  @override
  String get vehicleBaselineReset =>
      'Tilbakestill grunnleggende kjøresituasjon';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Tilbakestille grunnleggende kjøresituasjon?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Dette sletter alle innlærte prøver for dette kjøretøyet. Du vil falle tilbake til standardinnstillingene for kaldstart inntil nye turer fyller profilen igjen.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Ingen adapter tilknyttet. Legg til en slik at appen kan koble til automatisk neste gang.';

  @override
  String get vehicleAdapterUnnamed => 'Ukjent adapter';

  @override
  String get vehicleAdapterPair => 'Legg til adapter';

  @override
  String get vehicleAdapterForget => 'Glem adapter';

  @override
  String get achievementsTitle => 'Prestasjoner';

  @override
  String get achievementFirstTrip => 'Første tur';

  @override
  String get achievementFirstTripDesc => 'Registrer din første OBD2-tur.';

  @override
  String get achievementFirstFillUp => 'Første tanking';

  @override
  String get achievementFirstFillUpDesc => 'Logg din første tanking.';

  @override
  String get achievementTenTrips => '10 turer';

  @override
  String get achievementTenTripsDesc => 'Registrer 10 OBD2-turer.';

  @override
  String get achievementZeroHarsh => 'Jevn sjåfør';

  @override
  String get achievementZeroHarshDesc =>
      'Fullfør en tur på 10 km eller mer uten hard bremsing eller akselerasjon.';

  @override
  String get achievementEcoWeek => 'Økouke';

  @override
  String get achievementEcoWeekDesc =>
      'Kjør 7 påfølgende dager med minst én jevn tur hver dag.';

  @override
  String get achievementPriceWin => 'Prisgevinst';

  @override
  String get achievementPriceWinDesc =>
      'Logg en tanking som slår stasjonens 30-dagers gjennomsnitt med 5 % eller mer.';

  @override
  String get syncBaselinesToggleTitle => 'Del innlærte kjøretøyprofiler';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Last opp drivstoffbaseline per kjøretøy slik at en annen enhet kan gjenbruke dem.';

  @override
  String get obd2StatusConnected => 'OBD2-adapter: tilkoblet';

  @override
  String get obd2StatusAttempting => 'OBD2-adapter: kobler til';

  @override
  String get obd2StatusUnreachable => 'OBD2-adapter: ikke tilgjengelig';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-adapter: Bluetooth-tillatelse påkrevd';

  @override
  String get obd2StatusConnectedBody => 'Klar til å ta opp en tur.';

  @override
  String get obd2StatusAttemptingBody => 'Kobler til i bakgrunnen…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapteren er utenfor rekkevidde eller allerede i bruk av en annen app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Gi Bluetooth-tillatelse i systeminnstillingene for å koble til automatisk.';

  @override
  String get obd2StatusNoAdapter => 'Ingen adapter tilknyttet';

  @override
  String get obd2StatusForget => 'Glem adapter';

  @override
  String get tripHistoryTitle => 'Turhistorikk';

  @override
  String get tripHistoryEmptyTitle => 'Ingen turer ennå';

  @override
  String get tripHistoryEmptySubtitle =>
      'Koble til en OBD2-adapter og ta opp en tur for å bygge kjørehistorikken din.';

  @override
  String get tripHistoryUnknownDate => 'Ukjent dato';

  @override
  String get situationIdle => 'Tomgang';

  @override
  String get situationStopAndGo => 'Kø';

  @override
  String get situationUrban => 'Bykjøring';

  @override
  String get situationHighway => 'Motorvei';

  @override
  String get situationDecel => 'Bremser';

  @override
  String get situationClimbing => 'Stigning / last';

  @override
  String get situationHardAccel => 'Hard akselerasjon';

  @override
  String get situationFuelCut => 'Drivstoffstopp – frihjul';

  @override
  String get tripSaveAsFillUp => 'Lagre som tanking';

  @override
  String get tripSaveRecording => 'Lagre tur';

  @override
  String get tripDiscard => 'Forkast';

  @override
  String obdOdometerRead(int km) {
    return 'Kilometerstand lest: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Ikke angitt';

  @override
  String get wizardVehicleTapToEdit => 'Trykk for å redigere';

  @override
  String get wizardVehicleDefaultBadge => 'Standard';

  @override
  String get wizardProfileChoiceHint =>
      'Velg hvordan du vil bruke appen. Du kan endre dette senere i Innstillinger.';

  @override
  String get wizardProfileChoiceFooter =>
      'Du kan endre valget ditt når som helst fra Innstillinger → Bruksmodus.';

  @override
  String get wizardProfileBasicName => 'Grunnleggende';

  @override
  String get wizardProfileBasicDescription =>
      'Billigste drivstoff og EV-ladingspriser i nærheten. Favoritter og prisvarsler.';

  @override
  String get wizardProfileMediumName => 'Middels';

  @override
  String get wizardProfileMediumDescription =>
      'Alt i Grunnleggende, pluss spor drivstofftankinger og EV-lading manuelt.';

  @override
  String get wizardProfileFullName => 'Full';

  @override
  String get wizardProfileFullDescription =>
      'Alt i Middels, pluss automatisk OBD2-turregistrering, kjørepoeng og lojalitetskort.';

  @override
  String get wizardProfileCustomName => 'Egendefinert';

  @override
  String get wizardProfileCustomDescription =>
      'Din egen kombinasjon av funksjoner. Juster hver bryter nedenfor.';

  @override
  String get useModeSectionHint =>
      'Tilpass appen til hvordan du faktisk bruker den. Å velge en forhåndsinnstilling aktiverer det matchende settet med funksjoner.';

  @override
  String get useModeCustomSettingsDescription =>
      'Funksjonskombinasjonen din passer ikke til noen forhåndsinnstilling. Velg en ovenfor for å overskrive, eller fortsett å tilpasse individuelle funksjoner i seksjonen nedenfor.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Bruksmodus satt til $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Standard kjøretøy (valgfritt)';

  @override
  String get profileDefaultVehicleNone => 'Ingen standard';

  @override
  String get profileFuelFromVehicleHint =>
      'Drivstofftype er hentet fra ditt standard kjøretøy. Fjern kjøretøyet for å velge drivstoff direkte.';

  @override
  String get consumptionNoVehicleTitle => 'Legg til et kjøretøy først';

  @override
  String get consumptionNoVehicleBody =>
      'Tankinger knyttes til et kjøretøy. Legg til bilen din for å begynne å logge forbruk.';

  @override
  String get vehicleAdd => 'Legg til kjøretøy';

  @override
  String get vehicleAddTitle => 'Legg til kjøretøy';

  @override
  String get vehicleEditTitle => 'Rediger kjøretøy';

  @override
  String get vehicleDeleteTitle => 'Slette kjøretøy?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Fjerne «$name» fra profilene dine?';
  }

  @override
  String get vehicleNameLabel => 'Navn';

  @override
  String get vehicleNameHint => 'f.eks. Min Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Forbrenning';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Elektrisk';

  @override
  String get vehicleEvSectionTitle => 'Elektrisk';

  @override
  String get vehicleCombustionSectionTitle => 'Forbrenning';

  @override
  String get vehicleBatteryLabel => 'Batterikapasitet (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maks ladeeffekt (kW)';

  @override
  String get vehicleConnectorsLabel => 'Støttede kontakter';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Tankkapasitet (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Foretrukket drivstoff';

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
  String get connectorThreePin => '3-pinners';

  @override
  String get evShowOnMap => 'Vis EV-stasjoner';

  @override
  String get evAvailableOnly => 'Kun tilgjengelige';

  @override
  String get evMinPower => 'Min effekt';

  @override
  String get evMaxPower => 'Maks effekt';

  @override
  String get evOperator => 'Operatør';

  @override
  String get evLastUpdate => 'Siste oppdatering';

  @override
  String get evStatusAvailable => 'Tilgjengelig';

  @override
  String get evStatusOccupied => 'Opptatt';

  @override
  String get evStatusOutOfOrder => 'Ute av drift';

  @override
  String get openOnlyFilter => 'Kun åpne';

  @override
  String get saveAsDefaults => 'Lagre som mine standarder';

  @override
  String get criteriaSavedToProfile => 'Lagret som standarder';

  @override
  String get profileNotFound => 'Ingen aktiv profil';

  @override
  String get updatingFavorites => 'Oppdaterer favorittene dine...';

  @override
  String get fetchingLatestPrices => 'Henter siste priser';

  @override
  String get noDataAvailable => 'Ingen data';

  @override
  String get configAndPrivacy => 'Konfigurasjon og personvern';

  @override
  String get searchToSeeMap => 'Søk for å se stasjoner på kartet';

  @override
  String get evPowerAny => 'Alle';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Posisjon';

  @override
  String get tooltipBack => 'Tilbake';

  @override
  String get tooltipClose => 'Lukk';

  @override
  String get tooltipShare => 'Del';

  @override
  String get tooltipClearSearch => 'Tøm søkefelt';

  @override
  String get minimalDriveInstantConsumption => 'Øyeblikksforbruk';

  @override
  String get coachingShiftUp => 'Gir opp';

  @override
  String get coachingShiftDown => 'Gir ned';

  @override
  String get coachingEasePedal => 'Slipp gassen';

  @override
  String get tooltipUseGps => 'Bruk GPS-posisjon';

  @override
  String get tooltipShowPassword => 'Vis passord';

  @override
  String get tooltipHidePassword => 'Skjul passord';

  @override
  String get evConnectorsLabel => 'Tilgjengelige kontakter';

  @override
  String get evConnectorsNone => 'Ingen kontaktinformasjon';

  @override
  String get switchToEmail => 'Bytt til e-post';

  @override
  String get switchToEmailSubtitle =>
      'Behold data, legg til innlogging fra andre enheter';

  @override
  String get switchToAnonymousAction => 'Bytt til anonym';

  @override
  String get switchToAnonymousSubtitle =>
      'Behold lokale data, bruk ny anonym økt';

  @override
  String get linkDevice => 'Koble til enhet';

  @override
  String get shareDatabase => 'Del database';

  @override
  String get disconnectAction => 'Koble fra';

  @override
  String get disconnectSubtitle =>
      'Stopp synkronisering (lokale data beholdes)';

  @override
  String get deleteAccountAction => 'Slett konto';

  @override
  String get deleteAccountSubtitle => 'Fjern alle serverdata permanent';

  @override
  String get localOnly => 'Kun lokalt';

  @override
  String get localOnlySubtitle =>
      'Valgfritt: synkroniser favoritter, varsler og vurderinger på tvers av enheter';

  @override
  String get setupCloudSync => 'Sett opp skysynkronisering';

  @override
  String get disconnectTitle => 'Koble fra TankSync?';

  @override
  String get disconnectBody =>
      'Skysynkronisering vil deaktiveres. Lokale data (favoritter, varsler, historikk) beholdes på denne enheten. Serverdata slettes ikke.';

  @override
  String get deleteAccountTitle => 'Slette konto?';

  @override
  String get deleteAccountBody =>
      'Dette sletter permanent alle dataene dine fra serveren (favoritter, varsler, vurderinger, ruter). Lokale data på denne enheten beholdes.\n\nDette kan ikke angres.';

  @override
  String get switchToAnonymousTitle => 'Bytte til anonym?';

  @override
  String get switchToAnonymousBody =>
      'Du vil logges ut av e-postkontoen og fortsette med en ny anonym økt.\n\nLokale data (favoritter, varsler) beholdes på denne enheten og vil synkroniseres til den nye anonyme kontoen.';

  @override
  String get switchAction => 'Bytt';

  @override
  String get helpBannerCriteria =>
      'Profil-standardene dine er forhåndsutfylt. Juster kriteriene nedenfor for å finjustere søket.';

  @override
  String get helpBannerAlerts =>
      'Sett en prisgrense for en stasjon. Du vil bli varslet når prisene faller under den. Sjekker kjøres hvert 30. minutt.';

  @override
  String get helpBannerConsumption =>
      'Logg hver tanking for å spore faktisk forbruk og CO₂-avtrykk. Sveip venstre for å slette en oppføring.';

  @override
  String get helpBannerVehicles =>
      'Legg til kjøretøyene dine slik at tankinger og drivstoffpreferanser fylles ut korrekt. Det første kjøretøyet blir standarden din.';

  @override
  String get syncNow => 'Synkroniser nå';

  @override
  String get onboardingPreferencesTitle => 'Dine preferanser';

  @override
  String get onboardingZipHelper => 'Brukes når GPS ikke er tilgjengelig';

  @override
  String get onboardingRadiusHelper => 'Større radius = flere resultater';

  @override
  String get onboardingPrivacy =>
      'Disse innstillingene lagres kun på enheten din og deles aldri.';

  @override
  String get onboardingLandingTitle => 'Startskjerm';

  @override
  String get onboardingLandingHint =>
      'Velg hvilken skjerm som åpnes når du starter appen.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Vær ute av appen – men ikke lukk den.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Åpne Sparkilo én gang etter hver omstart.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple vekker Sparkilo bare etter at du har åpnet den minst én gang siden telefonen ble startet på nytt. Etter det registreres turene dine automatisk.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Ikke sveip Sparkilo bort i appbytteren.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '«Tvangsavslutting» forteller iOS å slutte å starte appen på nytt. Turene dine slutter å bli registrert til du åpner Sparkilo igjen.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Når iOS ber om «Alltid»-posisjon, si gjerne ja.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Reservemetoden som registrerer turen din når OBD2-adapteren er treg, trenger bakgrunnsposisjon. Vi deler den aldri.';

  @override
  String get scanReceipt => 'Skann kvittering';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Drivstoff';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Motorvei';

  @override
  String get ratingModeLocal => 'Lokal';

  @override
  String get ratingModePrivate => 'Privat';

  @override
  String get ratingModeShared => 'Delt';

  @override
  String get ratingDescLocal => 'Vurderinger lagret kun på denne enheten';

  @override
  String get ratingDescPrivate =>
      'Synkronisert med databasen din (ikke synlig for andre)';

  @override
  String get ratingDescShared => 'Synlig for alle brukere av databasen din';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API-nøkkel er ikke konfigurert. Legg til en i Innstillinger for å søke etter EV-ladestasjoner.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Dataleverandøren ($host) leverer et utløpt eller ugyldig TLS-sertifikat. Appen kan ikke laste data fra denne kilden før leverandøren fikser det. Ta kontakt med $host.';
  }

  @override
  String get offlineLabel => 'Frakoblet';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed ikke tilgjengelig. Bruker $current.';
  }

  @override
  String get errorTitleApiKey => 'API-nøkkel påkrevd';

  @override
  String get errorTitleLocation => 'Posisjon ikke tilgjengelig';

  @override
  String get errorHintNoStations =>
      'Prøv å øke søkeradiusen eller søk på et annet sted.';

  @override
  String get errorHintApiKey => 'Konfigurer API-nøkkelen din i Innstillinger.';

  @override
  String get errorHintConnection =>
      'Sjekk internettforbindelsen og prøv igjen.';

  @override
  String get errorHintRouting =>
      'Ruteberegning mislyktes. Sjekk internettforbindelsen og prøv igjen.';

  @override
  String get errorHintFallback =>
      'Prøv igjen eller søk med postnummer / stedsnavn.';

  @override
  String get alertsLoadErrorTitle => 'Kunne ikke laste varslene dine';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Bakgrunnssjekk av varsel mislyktes';

  @override
  String get detailsLabel => 'Detaljer';

  @override
  String get remove => 'Fjern';

  @override
  String get showKey => 'Vis nøkkel';

  @override
  String get hideKey => 'Skjul nøkkel';

  @override
  String get syncOptionalTitle => 'TankSync er valgfritt';

  @override
  String get syncOptionalDescription =>
      'Appen fungerer fullt ut uten skysynkronisering. TankSync lar deg synkronisere favoritter, varsler og vurderinger på tvers av enheter ved hjelp av Supabase (gratisnivå tilgjengelig).';

  @override
  String get syncHowToConnectQuestion => 'Hvordan vil du koble til?';

  @override
  String get syncCreateOwnTitle => 'Opprett min egen database';

  @override
  String get syncCreateOwnSubtitle =>
      'Gratis Supabase-prosjekt – vi veileder deg steg for steg';

  @override
  String get syncJoinExistingTitle => 'Bli med i en eksisterende database';

  @override
  String get syncJoinExistingSubtitle =>
      'Skann QR-kode fra databaseeieren eller lim inn legitimasjon';

  @override
  String get syncChooseAccountType => 'Velg kontotype';

  @override
  String get syncAccountTypeAnonymous => 'Anonym';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Umiddelbar tilgang, ingen e-post nødvendig. Data knyttet til denne enheten.';

  @override
  String get syncAccountTypeEmail => 'E-postkonto';

  @override
  String get syncAccountTypeEmailDesc =>
      'Logg inn fra hvilken som helst enhet. Gjenopprett data hvis telefonen går tapt.';

  @override
  String get syncHaveAccountSignIn => 'Har du allerede en konto? Logg inn';

  @override
  String get syncCreateNewAccount => 'Opprett ny konto';

  @override
  String get syncTestConnection => 'Test tilkobling';

  @override
  String get syncTestingConnection => 'Tester...';

  @override
  String get syncConnectButton => 'Koble til';

  @override
  String get syncConnectingButton => 'Kobler til...';

  @override
  String get syncDatabaseReady => 'Database klar!';

  @override
  String get syncDatabaseNeedsSetup => 'Database trenger oppsett';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Mangler';

  @override
  String get syncSqlEditorInstructions =>
      'Kopier SQL-en nedenfor og kjør den i Supabase SQL Editor (Dashbord → SQL Editor → Ny spørring → Lim inn → Kjør)';

  @override
  String get syncCopySqlButton => 'Kopier SQL til utklippstavle';

  @override
  String get syncRecheckSchemaButton => 'Sjekk skjema på nytt';

  @override
  String get syncDoneButton => 'Ferdig';

  @override
  String syncSignedInAs(String email) {
    return 'Logget inn som $email';
  }

  @override
  String get syncEmailDescription =>
      'Dataene dine synkroniseres på tvers av alle enheter med denne e-posten.';

  @override
  String get syncSwitchToAnonymousTitle => 'Bytt til anonym';

  @override
  String get syncSwitchToAnonymousDesc => 'Fortsett uten e-post, ny anonym økt';

  @override
  String get syncGuestDescription => 'Anonym, ingen e-post nødvendig.';

  @override
  String get syncOrDivider => 'eller';

  @override
  String get syncHowToSyncQuestion => 'Hvordan vil du synkronisere?';

  @override
  String get syncOfflineDescription =>
      'Appen fungerer fullt ut frakoblet. Skysynkronisering er valgfritt.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo-fellesskap';

  @override
  String get syncModeCommunitySubtitle =>
      'Del favoritter og vurderinger med alle brukere';

  @override
  String get syncModePrivateTitle => 'Privat database';

  @override
  String get syncModePrivateSubtitle => 'Din egen Supabase – full datakontroll';

  @override
  String get syncModeGroupTitle => 'Bli med i en gruppe';

  @override
  String get syncModeGroupSubtitle => 'Delt database for familie eller venner';

  @override
  String get syncPrivacyShared => 'Delt';

  @override
  String get syncPrivacyPrivate => 'Privat';

  @override
  String get syncPrivacyGroup => 'Gruppe';

  @override
  String get syncStayOfflineButton => 'Forbli frakoblet';

  @override
  String get syncSuccessTitle => 'Koblet til!';

  @override
  String get syncSuccessDescription =>
      'Dataene dine vil nå synkroniseres automatisk.';

  @override
  String get syncWizardTitleConnect => 'Koble til TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Din database';

  @override
  String get syncSetupTitleJoinGroup => 'Bli med i en gruppe';

  @override
  String get syncSetupTitleAccount => 'Din konto';

  @override
  String get syncWizardBack => 'Tilbake';

  @override
  String get syncWizardNext => 'Neste';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Steg $current av $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Opprett et Supabase-prosjekt';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Trykk «Åpne Supabase» nedenfor\n2. Opprett en gratis konto (hvis du ikke har en)\n3. Klikk «Nytt prosjekt»\n4. Velg et navn og region\n5. Vent ~2 minutter til det starter';

  @override
  String get syncWizardOpenSupabase => 'Åpne Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Aktiver anonym innlogging';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. I Supabase-dashbordet ditt:\n   Autentisering → Leverandører\n2. Finn «Anonym innlogging»\n3. Slå det PÅ\n4. Klikk «Lagre»';

  @override
  String get syncWizardOpenAuthSettings => 'Åpne autentiseringsinnstillinger';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopier legitimasjonen din';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Gå til Innstillinger → API i dashbordet ditt\n2. Kopier «Prosjekt-URL»\n3. Kopier «anon public»-nøkkelen\n4. Lim dem inn nedenfor';

  @override
  String get syncWizardOpenApiSettings => 'Åpne API-innstillinger';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Bli med i en eksisterende database';

  @override
  String get syncWizardScanQrCode => 'Skann QR-kode';

  @override
  String get syncWizardAskOwnerQr =>
      'Be databaseeieren vise deg QR-koden sin\n(Innstillinger → TankSync → Del)';

  @override
  String get syncWizardAskOwnerQrShort => 'Be databaseeieren vise QR-koden sin';

  @override
  String get syncWizardEnterManuallyTitle => 'Skriv inn manuelt';

  @override
  String get syncWizardOrEnterManually => 'eller skriv inn manuelt';

  @override
  String get syncWizardUrlHelperText =>
      'Mellomrom og linjeskift fjernes automatisk';

  @override
  String get syncCredentialsPrivateHint =>
      'Skriv inn Supabase-prosjektlegitimasjonen din. Du finner den i dashbordet under Innstillinger > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Database URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Tilgangsnøkkel';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-post';

  @override
  String get authPasswordLabel => 'Passord';

  @override
  String get authConfirmPasswordLabel => 'Bekreft passord';

  @override
  String get authPleaseEnterEmail => 'Skriv inn e-postadressen din';

  @override
  String get authInvalidEmail => 'Ugyldig e-postadresse';

  @override
  String get authPasswordsDoNotMatch => 'Passordene stemmer ikke overens';

  @override
  String get authConnectAnonymously => 'Koble til anonymt';

  @override
  String get authCreateAccountAndConnect => 'Opprett konto og koble til';

  @override
  String get authSignInAndConnect => 'Logg inn og koble til';

  @override
  String get authAnonymousSegment => 'Anonym';

  @override
  String get authEmailSegment => 'E-post';

  @override
  String get authAnonymousDescription =>
      'Umiddelbar tilgang, ingen e-post nødvendig. Data knyttet til denne enheten.';

  @override
  String get authEmailDescription =>
      'Logg inn fra hvilken som helst enhet. Gjenopprett dataene dine hvis telefonen går tapt.';

  @override
  String get authSyncAcrossDevices =>
      'Synkroniser data automatisk på tvers av alle enhetene dine.';

  @override
  String get authNewHereCreateAccount => 'Ny her? Opprett konto';

  @override
  String get linkDeviceScreenTitle => 'Koble til enhet';

  @override
  String get linkDeviceThisDeviceLabel => 'Denne enheten';

  @override
  String get linkDeviceShareCodeHint =>
      'Del denne koden med den andre enheten din:';

  @override
  String get linkDeviceNotConnected => 'Ikke tilkoblet';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopier kode';

  @override
  String get linkDeviceImportSectionTitle => 'Importer fra en annen enhet';

  @override
  String get linkDeviceImportDescription =>
      'Skriv inn enhetskoden fra den andre enheten din for å importere favoritter, varsler, kjøretøy og forbrukslogg. Hver enhet beholder sin egen profil og standarder.';

  @override
  String get linkDeviceCodeFieldLabel => 'Enhetskode';

  @override
  String get linkDeviceCodeFieldHint => 'Lim inn UUID fra den andre enheten';

  @override
  String get linkDeviceImportButton => 'Importer data';

  @override
  String get linkDeviceHowItWorksTitle => 'Slik fungerer det';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. På enhet A: kopier enhetskoden ovenfor\n2. På enhet B: lim den inn i «Enhetskode»-feltet\n3. Trykk «Importer data» for å slå sammen favoritter, varsler, kjøretøy og forbrukslogger\n4. Begge enheter vil ha alle kombinerte data\n\nHver enhet beholder sin egen anonyme identitet og profil (foretrukket drivstoff, standard kjøretøy, startskjerm). Data slås sammen, ikke flyttes.';

  @override
  String get vehicleSetActive => 'Sett som aktiv';

  @override
  String get swipeHide => 'Skjul';

  @override
  String get evChargingSection => 'EV-lading';

  @override
  String get fuelStationsSection => 'Drivstoffstasjoner';

  @override
  String get yourRating => 'Din vurdering';

  @override
  String get noStorageUsed => 'Ingen lagring brukt';

  @override
  String get aboutReportBug => 'Rapporter en feil / Foreslå en funksjon';

  @override
  String get aboutSupportProject => 'Støtt dette prosjektet';

  @override
  String get aboutSupportDescription =>
      'Denne appen er gratis, åpen kildekode og uten reklame. Hvis du finner den nyttig, vurder å støtte utvikleren.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxembourgs drivstoffpriser er statsregulerte og like over hele landet.';

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
      'Luxembourgs regulerte priser er ikke tilgjengelige.';

  @override
  String get reportIssueTitle => 'Rapporter et problem';

  @override
  String get enterCorrection => 'Skriv inn rettelsen';

  @override
  String get reportNoBackendAvailable =>
      'Rapporten kunne ikke sendes: ingen rapporteringstjeneste er konfigurert for dette landet. Aktiver TankSync i Innstillinger for å sende fellesskapsrapporter.';

  @override
  String get correctName => 'Riktig stasjonsnavn';

  @override
  String get correctAddress => 'Riktig adresse';

  @override
  String get wrongE85Price => 'Feil E85-pris';

  @override
  String get wrongE98Price => 'Feil Super 98-pris';

  @override
  String get wrongLpgPrice => 'Feil LPG-pris';

  @override
  String get wrongStationName => 'Feil stasjonsnavn';

  @override
  String get wrongStationAddress => 'Feil adresse';

  @override
  String get independentStation => 'Uavhengig stasjon';

  @override
  String get serviceRemindersSection => 'Servicepåminnelser';

  @override
  String get serviceRemindersEmpty =>
      'Ingen påminnelser ennå – velg en forhåndsinnstilling ovenfor.';

  @override
  String get addServiceReminder => 'Legg til påminnelse';

  @override
  String get serviceReminderPresetOil => 'Olje (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Oljeskift';

  @override
  String get serviceReminderPresetTires => 'Dekk (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Dekk';

  @override
  String get serviceReminderPresetInspection => 'Kontroll (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Kontroll';

  @override
  String get serviceReminderLabel => 'Etikett';

  @override
  String get serviceReminderInterval => 'Intervall (km)';

  @override
  String get serviceReminderLastService => 'Siste service';

  @override
  String get serviceReminderMarkDone => 'Merk som utført';

  @override
  String get serviceReminderDueTitle => 'Service forfalt';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label er forfalt – $kmOver km over intervallet.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Registrer deg på OPINET for å få en gratis API-nøkkel';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registrer deg på CNE for å få en gratis API-nøkkel';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Er dette bilen din?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-syl., $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Delvis info (frakoblet). Du kan redigere nedenfor.';

  @override
  String get vinDecodeError => 'Kunne ikke dekode dette VIN-nummeret';

  @override
  String get vinInvalidFormat => 'Ugyldig VIN-format';

  @override
  String get obd2PauseBannerTitle => 'OBD2-tilkobling tapt – opptak pauset';

  @override
  String get obd2PauseBannerResume => 'Gjenoppta opptak';

  @override
  String get obd2PauseBannerEnd => 'Avslutt opptak';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Forbrukskalibrering oppdatert for $vehicleName – nøyaktighet forbedret med $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Tilbakestille volumetrisk effektivitet?';

  @override
  String get veResetConfirmBody =>
      'Dette vil forkaste den innlærte volumetriske effektiviteten (η_v) og gjenopprette standardverdien (0.85). Drivstoffstrømsestimater på turoppdrag vil falle tilbake til produsentkonstanten til kalibratoren samler nye prøver fra kommende turer.';

  @override
  String get alertsRadiusSectionTitle => 'Radiusvarsler';

  @override
  String get alertsRadiusAdd => 'Legg til radiusvarsel';

  @override
  String get alertsRadiusEmptyTitle => 'Ingen radiusvarsler ennå';

  @override
  String get alertsRadiusEmptyCta => 'Opprett et radiusvarsel';

  @override
  String get alertsRadiusCreateTitle => 'Opprett radiusvarsel';

  @override
  String get alertsRadiusLabelHint => 'Etikett (f.eks. Hjemme diesel)';

  @override
  String get alertsRadiusFuelType => 'Drivstofftype';

  @override
  String get alertsRadiusThreshold => 'Grenseverdi (€/L)';

  @override
  String get alertsRadiusKm => 'Radius (km)';

  @override
  String get alertsRadiusCenterGps => 'Bruk posisjonen min';

  @override
  String get alertsRadiusCenterPostalCode => 'Postnummer';

  @override
  String get alertsRadiusSave => 'Lagre';

  @override
  String get alertsRadiusCancel => 'Avbryt';

  @override
  String get alertsRadiusDeleteConfirm => 'Slett radiusvarsel?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 tilkoblet: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Legg til en OBD2-adapter';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel falt ved nærliggende stasjoner';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stasjoner falt med opptil $maxDropCents¢ den siste timen';
  }

  @override
  String get fillUpSavedSnackbar => 'Tanking lagret';

  @override
  String get radiusAlertsEntryTitle => 'Radiusvarsler og statistikk';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Bli varslet når priser faller nær deg';

  @override
  String get notFoundTitle => 'Side ikke funnet';

  @override
  String notFoundBody(String location) {
    return '«$location» ble ikke funnet.';
  }

  @override
  String get notFoundHomeButton => 'Hjem';

  @override
  String get consumptionTabHiddenNotice =>
      'Forbruksfanen er skjult av profilinnstillingene dine.';

  @override
  String get swipeBetweenTabsHint =>
      'Tips: sveip til venstre eller høyre for å bytte mellom faner.';

  @override
  String get discardChangesTitle => 'Forkaste endringer?';

  @override
  String get discardChangesBody =>
      'Du har ulagrede endringer. Hvis du går nå, vil de forkastes.';

  @override
  String get discardChangesConfirm => 'Forkast';

  @override
  String get discardChangesKeepEditing => 'Fortsett å redigere';

  @override
  String get tankSyncSectionSubtitle =>
      'Skysynkronisering på tvers av enhetene dine';

  @override
  String get mapUnavailable => 'Kart utilgjengelig';

  @override
  String get routeNameHintExample => 'f.eks. Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Nåværende';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API-nøkkel';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API-nøkkel';

  @override
  String get tapToUpdateGpsPosition => 'Trykk for å oppdatere GPS-posisjon';

  @override
  String get nameLabel => 'Navn';

  @override
  String get obd2ErrorPermissionDenied =>
      'Bluetooth-tillatelse kreves for å koble til en OBD2-adapter.';

  @override
  String get obd2ErrorBluetoothOff => 'Slå på Bluetooth og prøv igjen.';

  @override
  String get obd2ErrorScanTimeout =>
      'Fant ingen OBD2-adapter i nærheten. Kontroller at den er koblet til og slått på.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2-adapteren svarte ikke. Slå på tenningen og prøv igjen.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2-adapteren sendte et ukjent svar. Den er kanskje ikke kompatibel — prøv en annen adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2-adapteren ble frakoblet. Koble til på nytt og prøv igjen.';

  @override
  String get onboardingExploreDemoData => 'Utforsk med demodata';

  @override
  String get achievementSmoothDriver => 'Jevn kjørerekke';

  @override
  String get achievementSmoothDriverDesc =>
      'Kjør 5 turer på rad med kjørescore på 80 eller høyere.';

  @override
  String get achievementColdStartAware => 'Kaldstartbevisst';

  @override
  String get achievementColdStartAwareDesc =>
      'Hold en hel måneds kaldstartdrivstoffkostnad under 2 % av totalt drivstoff – kombiner korte turer.';

  @override
  String get achievementHighwayMaster => 'Motorveimester';

  @override
  String get achievementHighwayMasterDesc =>
      'Fullfør en tur på 30+ km med konstant hastighet og kjørescore på 90 eller høyere.';

  @override
  String get alertGatingNonDeStationWarning =>
      'Prisvarsler i bakgrunnen fungerer foreløpig bare for bensinstasjoner i Tyskland. Dette varselet lagres, men varsler deg kanskje aldri før varsler på tvers av land blir tilgjengelige.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Radiusvarsler sjekker foreløpig bare bensinstasjoner i Tyskland.';

  @override
  String get approachOverlaySection => 'Innflygingsoverlegg';

  @override
  String get approachRadiusLabel => 'Radius';

  @override
  String approachRadiusCaption(String km) {
    return 'Overlegget vokser og viser prisen når du er innenfor $km km fra en stasjon';
  }

  @override
  String get approachPriceModeLabel => 'Vis pris for';

  @override
  String get approachPriceModeNearest => 'Nærmeste stasjon';

  @override
  String get approachPriceModeCheapestInRadius => 'Billigste i radius';

  @override
  String get approachMinPollLabel => 'Min. oppdatering';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Nedre grense for hvor ofte overlegget oppdaterer nærmeste stasjon (raskere ved fart, aldri tettere enn $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Test nærmingsoverlegg';

  @override
  String get approachTestStopButton => 'Stopp test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktiv — overlegget viser prisen for $station';
  }

  @override
  String get approachTestUnavailable =>
      'Legg til en favorittstasjon for å teste nærmingsoverlegget';

  @override
  String approachStationDistance(String meters) {
    return '$meters m unna';
  }

  @override
  String get authErrorNoNetwork =>
      'Ingen nettverkstilkobling. Prøv igjen senere.';

  @override
  String get authErrorInvalidCredentials =>
      'Ugyldig e-post eller passord. Sjekk legitimasjonen din.';

  @override
  String get authErrorUserAlreadyExists =>
      'Denne e-posten er allerede registrert. Prøv å logge inn i stedet.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Sjekk e-posten din og bekreft kontoen din først.';

  @override
  String get authErrorGeneric => 'Innlogging mislyktes. Prøv igjen.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Bakgrunnsposisjon – kun for autoregistrering';

  @override
  String get autoRecordConsentExplanationTitle => 'Om denne tillatelsen';

  @override
  String get autoRecordConsentExplanationBody =>
      'Autoregistrering trenger bakgrunnsposisjon for å oppdage når du begynner å kjøre mens appen er lukket. Denne tillatelsen brukes kun av autoregistrering – stasjonssøk og kartsentrering bruker en separat forgrunnstillatelse.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Skjønt';

  @override
  String get autoRecordConsentExplanationTooltip => 'Hva betyr dette?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Trykk for å administrere i systeminnstillinger';

  @override
  String get autoRecordSectionTitle => 'Autoregistrering';

  @override
  String get autoRecordToggleLabel => 'Autoregistrer turer';

  @override
  String get autoRecordStatusActiveLabel =>
      'Autoregistrering aktiveres neste gang du setter deg i bilen.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Legg til en OBD2-adapter for å aktivere autoregistrering.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Tillat bakgrunnsposisjon slik at autoregistrering fortsetter med skjermen av.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Legg til en adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Starthastighet (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Lagringsforsinkelse etter frakobling (sekunder)';

  @override
  String get autoRecordPairedAdapterLabel => 'Tilknyttet adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Ingen adapter tilknyttet. Legg til en via OBD2-oppsettet først.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Bakgrunnsposisjon tillatt';

  @override
  String get autoRecordBackgroundLocationRequest => 'Be om tillatelse';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Hvorfor «Tillat alltid»?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Autoregistrering strømmer GPS-koordinater fra OBD-II-forgrunntjenesten mens skjermen er av, slik at turruten forblir nøyaktig. Android krever alternativet «Tillat alltid» for at dette skal fortsette å fungere etter at enheten låses.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Åpne innstillinger';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Posisjonstillatelse påkrevd';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Kunne ikke be om bakgrunnsposisjon';

  @override
  String get autoRecordBadgeClearTooltip => 'Nullstill teller';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Legg til en adapter i seksjonen nedenfor for å aktivere autoregistrering';

  @override
  String get exportBackupTooltip => 'Eksporter sikkerhetskopi';

  @override
  String get exportBackupReady => 'Sikkerhetskopi klar – velg et mål';

  @override
  String get exportBackupFailed =>
      'Eksport av sikkerhetskopi mislyktes – prøv igjen';

  @override
  String get brokenMapChipVerifying => 'MAP-sensor verifiserer…';

  @override
  String get brokenMapChipDisclaimer => 'MAP-avlesninger mistenkelige';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-sensoren leser feil – drivstoffavlesninger kan være 50–80 % for lave. Prøv en annen adapter.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-sensor upålitelig. Viser tankingsgjennomsnitt i stedet for live drivstoffrate.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP-sensor: verifisert ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP-sensor: verifiserer ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP-sensor: mistenkelig ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin% (verifisert)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-sensor-diagnostikk';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Defekt MAP-konfidens: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observasjoner registrert';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verifisert ren';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Dette kjøretøyets MAP-sensor er ikke observert ennå.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokkerte adaptere';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Ingen adaptere er blokkert.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter – flagget $percent% defekt';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Tøm';

  @override
  String get brokenMapRevPromptTitle => 'Rev motoren';

  @override
  String get brokenMapRevPromptBody =>
      'Gi kort gass slik at appen kan sjekke at MAP-sensoren reagerer.';

  @override
  String get brokenMapRevPromptConfirm => 'Ferdig – jeg ga gass';

  @override
  String get calibrationAdvancedTitle => 'Avansert kalibrering';

  @override
  String get calibrationDisplacementLabel => 'Motorvolum (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Volumetrisk effektivitet (η_v)';

  @override
  String get calibrationAfrLabel => 'Luft-drivstoff-forhold (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Drivstofftetthet (g/L)';

  @override
  String get calibrationSourceDetected => '(oppdaget fra VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(standard)';

  @override
  String get calibrationSourceManual => '(manuell)';

  @override
  String get calibrationResetToDetected => 'Tilbakestill til oppdaget verdi';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibrert, $samples prøver)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (lærer, $samples prøver)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (standard – ingen full tanking ennå)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples prøver';
  }

  @override
  String get calibrationResetLearner => 'Tilbakestill innlæring';

  @override
  String get calibrationBasisAtkinson => 'Atkinson-syklus';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbomatet + DI';

  @override
  String get calibrationBasisTurbo => 'Turbomatet';

  @override
  String get calibrationBasisNaDi => 'Atmosfærisk + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — $basis standard)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return '$makeModel er merket som diesel, men samsvarer med en bensinoppføring i katalogen. Trykk for å oppdatere.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Oppdater';

  @override
  String get consumptionTabFuel => 'Drivstoff';

  @override
  String get consumptionTabCharging => 'Lading';

  @override
  String get noChargingLogsTitle => 'Ingen ladelogger ennå';

  @override
  String get noChargingLogsSubtitle =>
      'Logg den første ladeøkten for å starte sporing av EUR/100 km og kWh/100 km.';

  @override
  String get addChargingLog => 'Logg lading';

  @override
  String get addChargingLogTitle => 'Logg ladeøkt';

  @override
  String get chargingKwh => 'Energi (kWh)';

  @override
  String get chargingCost => 'Total kostnad';

  @override
  String get chargingTimeMin => 'Ladetid (min)';

  @override
  String get chargingStationName => 'Stasjon (valgfritt)';

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
      'Trenger en tidligere logg for å sammenligne';

  @override
  String get chargingLogButtonLabel => 'Logg lading';

  @override
  String get chargingCostTrendTitle => 'Kostnadstrend for lading';

  @override
  String get chargingEfficiencyTitle => 'Effektivitet (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Ikke nok data ennå';

  @override
  String get chargingChartsMonthAxis => 'Måned';

  @override
  String get consoFeatureGroupTitle => 'Forbruk';

  @override
  String get consoFeatureGroupDescription =>
      'Spor forbruket ditt – manuelle tankinger eller automatisk OBD2-turregistrering.';

  @override
  String get consoModeOff => 'Av';

  @override
  String get consoModeFuel => 'Drivstoff';

  @override
  String get consoModeFuelAndTrips => 'Drivstoff + turer';

  @override
  String get consoModeOffDescription =>
      'Ingen Forbruk-fane og ingen Forbruk-innstillingseksjon.';

  @override
  String get consoModeFuelDescription =>
      'Kun manuelle tankinger. Nyttig uten OBD2-adapter.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Legger til automatisk OBD2-turregistrering. Krever en tilknyttet adapter.';

  @override
  String get consoSubsectionVehicles => 'Mine kjøretøy';

  @override
  String get consoSubsectionTrajets => 'Turer (OBD2)';

  @override
  String get consoSubsectionToggles => 'Kjøring';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count delvise tankinger venter på full tanking – ikke i gjennomsnitt',
      one: '1 delvis tanking venter på full tanking – ikke i gjennomsnitt',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% av drivstoff fra autokorreksjoner – gå gjennom oppføringer';
  }

  @override
  String get fillUpCorrectionLabel => 'Autokorreksjon – trykk for å redigere';

  @override
  String get fillUpCorrectionEditTitle => 'Rediger autokorreksjon';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Denne oppføringen ble generert automatisk for å lukke gapet mellom registrerte turer og pumpet drivstoff. Juster verdiene hvis du kjenner de faktiske tallene.';

  @override
  String get fillUpCorrectionDelete => 'Slett korreksjon';

  @override
  String get fillUpCorrectionStation => 'Stasjonsnavn (valgfritt)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Hellas)';

  @override
  String get greeceCommunityApiNotice =>
      'Drevet av det fellesskapsvedigeholdne fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Drevet av pretcarburant.ro (Konkurranserådet + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country-stasjoner $km km unna — €$price/L billigere';
  }

  @override
  String get crossBorderTapToSwitch => 'Trykk for å bytte land';

  @override
  String get crossBorderDismissTooltip => 'Lukk';

  @override
  String get developerToolsSectionTitle => 'Utviklerverktøy';

  @override
  String get developerToolsSubtitle =>
      'Diagnostikk og feilsøkingsverktøy — vises bare i utvikler-/feilsøkingsmodus.';

  @override
  String get developerToolsMenuSubtitle => 'Feillogg, testvarsler, diagnostikk';

  @override
  String get developerToolsErrorLogGroupTitle => 'Feillogg';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Lagre feillogg ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Tøm feillogg';

  @override
  String get developerToolsViewErrorLog => 'Vis feillogg';

  @override
  String get developerToolsErrorLogEmpty => 'Ingen feilspor registrert.';

  @override
  String get developerToolsAlertsGroupTitle => 'Varsler og meldinger';

  @override
  String get developerToolsFireTestNotification => 'Send testvarsel';

  @override
  String get developerToolsTestNotificationTitle => 'Testvarsel';

  @override
  String get developerToolsTestNotificationBody =>
      'Hvis du kan lese dette, fungerer varslene.';

  @override
  String get developerToolsTestNotificationSent => 'Testvarsel sendt.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Varsler er blokkert — aktiver dem i systeminnstillingene, og prøv på nytt.';

  @override
  String get developerToolsRunTestAlert => 'Kjør testvarselflyt';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testvarsel utløst — flyten leverte $count varsel/varsler.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testprisvarsel';

  @override
  String get developerToolsTestAlertBody =>
      'Syntetisk treff: en stasjon under målet ditt ble funnet i nærheten.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostikk';

  @override
  String get developerToolsFeatureFlagDump => 'Inspektør for funksjonsflagg';

  @override
  String get developerToolsFlagOn => 'På';

  @override
  String get developerToolsFlagOff => 'Av';

  @override
  String get developerToolsClearCaches => 'Tøm hurtigbuffere';

  @override
  String get developerToolsCachesCleared => 'Hurtigbuffere tømt.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopier diagnostikk';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostikk kopiert til utklippstavlen.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Build-informasjon';

  @override
  String get developerToolsBuildVersion => 'Appversjon';

  @override
  String get developerToolsBuildChannel => 'Build-kanal';

  @override
  String get insightCardTitle => 'Topp ineffektive vaner';

  @override
  String get insightEmptyState =>
      'Ingen merkbare ineffektiviteter – fortsett slik!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor over 3000 RPM ($pctTime% av turen): bortkastet $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count harde akselerasjoner: bortkastet $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Tomgang ($pctTime% av turen): bortkastet $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% av turen';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Sliter i lavt gir ($minutes min)';
  }

  @override
  String get drivingScoreCardTitle => 'Kjørescore';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Sammensatt score fra tomgang, harde akselerasjoner, hard bremsing og høy RPM-tid. En «bedre enn X% av tidligere turer»-sammenligning kommer i en fremtidig versjon.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Kjørescore $score av 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Tomgang';

  @override
  String get drivingScorePenaltyHardAccel => 'Harde akselerasjoner';

  @override
  String get drivingScorePenaltyHardBrake => 'Hard bremsing';

  @override
  String get drivingScorePenaltyHighRpm => 'Høy RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Full gass';

  @override
  String get ecoRouteOption => 'Øko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L spart';
  }

  @override
  String get ecoRouteHint =>
      'Smartere kjøring – foretrekker jevn motorvei fremfor svingte snarveier.';

  @override
  String get favoritesShareAction => 'Del';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favoritter den $date';
  }

  @override
  String get favoritesShareError => 'Kunne ikke generere delbart bilde';

  @override
  String get featureManagementSectionTitle => 'Funksjonsstyring';

  @override
  String get featureManagementSectionSubtitle =>
      'Slå individuelle funksjoner av og på. Noen funksjoner er avhengige av andre – bryterne er deaktivert inntil forutsetningene er oppfylt.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2-turregistrering';

  @override
  String get featureDescription_obd2TripRecording =>
      'Ta opp turer automatisk via OBD2.';

  @override
  String get featureLabel_gamification => 'Gamifisering';

  @override
  String get featureDescription_gamification =>
      'Kjørepoeng og opptjente merker.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptisk øko-coach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Sanntids haptisk tilbakemelding under en tur.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synkronisering på tvers av enheter via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Forbruksanalyse';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Analyse-fane for tankinger og turer.';

  @override
  String get featureLabel_baselineSync => 'Baselinesynkronisering';

  @override
  String get featureDescription_baselineSync =>
      'Synkroniser kjørebaselines via TankSync.';

  @override
  String get featureLabel_unifiedSearchResults => 'Samlet søkeresultat';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Én resultatliste som kombinerer drivstoff- og EV-stasjoner.';

  @override
  String get featureLabel_priceAlerts => 'Prisvarsler';

  @override
  String get featureDescription_priceAlerts =>
      'Prisfall-varsler basert på grenseverdi.';

  @override
  String get featureLabel_priceHistory => 'Prishistorikk';

  @override
  String get featureDescription_priceHistory =>
      '30-dagers prisdiagrammer i stasjonsdetaljer.';

  @override
  String get featureLabel_routePlanning => 'Ruteplanlegging';

  @override
  String get featureDescription_routePlanning =>
      'Billigste stopp langs ruten din.';

  @override
  String get featureLabel_evCharging => 'EV-lading';

  @override
  String get featureDescription_evCharging =>
      'Ladestasjoner via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling-veiledning ved hjelp av OSM-trafikklys.';

  @override
  String get featureLabel_gpsTripPath => 'GPS-turrute';

  @override
  String get featureDescription_gpsTripPath =>
      'Lagre GPS-ruteprøver sammen med hver tur.';

  @override
  String get featureLabel_autoRecord => 'Autoregistrering';

  @override
  String get featureDescription_autoRecord =>
      'Start automatisk en tur når OBD2-adapteren kobler til et kjørende kjøretøy.';

  @override
  String get featureLabel_showFuel => 'Vis drivstoffstasjoner';

  @override
  String get featureDescription_showFuel =>
      'Vis bensin/diesel-stasjonresultater i søk og på kartet.';

  @override
  String get featureLabel_showElectric => 'Vis ladestasjoner';

  @override
  String get featureDescription_showElectric =>
      'Vis EV-ladestasjoner i søk og på kartet.';

  @override
  String get featureLabel_showConsumptionTab => 'Forbruksfane';

  @override
  String get featureDescription_showConsumptionTab =>
      'Vis forbruksanalyse-fanen i bunnnavigasjonen.';

  @override
  String get featureBlockedEnable_gamification =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureBlockedEnable_baselineSync => 'Aktiver TankSync først';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureBlockedEnable_showFuel => 'Forutsetninger ikke oppfylt';

  @override
  String get featureBlockedEnable_showElectric => 'Forutsetninger ikke oppfylt';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite prispreduksjon';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Prisforutsigelsesmodell på enheten – inferens kjøres lokalt; funksjoner og preduksjoner forlater aldri enheten.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Aktiver prishistorikk først';

  @override
  String get featureLabel_fuelCalculator => 'Drivstoffkalkulator';

  @override
  String get featureDescription_fuelCalculator =>
      'Rekkevidde-drivstoffkostnadskalkulator fra søkeresultatene.';

  @override
  String get featureLabel_carbonDashboard => 'Karbondashbord';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2-avtrykk-dashbord tilgjengelig fra Forbruk-fanen.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentelle OEM PID-er';

  @override
  String get featureDescription_experimentalOemPids =>
      'Les eksakte tankliter via produsentspesifikke PID-er på støttede adaptere.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Aktiver OBD2-turregistrering først';

  @override
  String get featureLabel_paymentQrScan => 'Skann betalings-QR';

  @override
  String get featureDescription_paymentQrScan =>
      'Skann-til-betal QR-leser på stasjonsdetalj-skjermen.';

  @override
  String get featureLabel_communityPriceReports => 'Fellesskapsprisrapporter';

  @override
  String get featureDescription_communityPriceReports =>
      'Rapporter en stasjonspris fra stasjonsdetalj-skjermen.';

  @override
  String get featureLabel_obd2Optional => 'Krev OBD2 for turopptak';

  @override
  String get featureDescription_obd2Optional =>
      'Når av tar appen opp turer med kun GPS uten en OBD2-adapter. Coaching er redusert — ingen umiddelbar L/100 km, færre motorsignaler.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Kvittering OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skann en utskrevet kvittering på skjermen Legg til fylling for å forhåndsutfylle dato, liter, totalt og stasjon.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'Pumpedisplay OCR (eksperimentell)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Skann en drivstoffpumpedisplay for å forhåndsutfylle skjemaet. Gjenkjenningen er upålitelig i dag — aktiver kun hvis du vil teste.';

  @override
  String get featureLabel_developerPatToken =>
      'Utviklertilbakemelding (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Aktiverer tilbakemeldingspanelet for mislykkede skanninger som automatisk oppretter GitHub-issues med et Personal Access Token. Funksjon for avanserte brukere / bidragsytere.';

  @override
  String get featureLabel_debugMode => 'Utvikler-/feilsøkingsmodus';

  @override
  String get featureDescription_debugMode =>
      'Viser en seksjon med utviklerverktøy i innstillingene med diagnostikk: eksport av feillogg, testvarsler, kjøring av testvarselflyt, oversikt over funksjonsflagg, tømming av hurtigbuffere og kopiering av diagnostikk.';

  @override
  String get feedbackConsentTitle => 'Send rapport til GitHub?';

  @override
  String get feedbackConsentBody =>
      'Dette oppretter en offentlig sak på GitHub-depotet vårt med bildet og OCR-teksten. Ingen personopplysninger (posisjon, konto-ID) sendes. Fortsett?';

  @override
  String get feedbackConsentContinue => 'Fortsett';

  @override
  String get feedbackConsentCancel => 'Avbryt';

  @override
  String get feedbackConsentLater => 'Senere';

  @override
  String get feedbackTokenSectionTitle =>
      'Tilbakemelding om mislykket skanning (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'For å automatisk åpne en GitHub-sak fra en mislykket skanning, lim inn et GitHub PAT (`public_repo`-omfang på tankstellen-depotet). Ellers er manuell deling fremdeles tilgjengelig.';

  @override
  String get feedbackTokenStatusSet => 'Token konfigurert';

  @override
  String get feedbackTokenStatusUnset => 'Ingen token';

  @override
  String get feedbackTokenSet => 'Angi';

  @override
  String get feedbackTokenClear => 'Tøm';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personlig tilgangstoken';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Verifisert av adapter';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Samsvarer ikke med adapteravlesning';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Din oppføring: $userL L. Adapteren sier: $adapterL L (delta fra drivstoffnivåfangst før/etter). Bruke adapterverdi?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Behold min oppføring';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Bruk adapterverdi';

  @override
  String get scanReceiptNoData => 'Ingen kvitteringsdata funnet – prøv igjen';

  @override
  String get scanReceiptSuccess =>
      'Kvittering skannet – verifiser verdiene. Trykk «Rapporter skanningsfeil» nedenfor hvis noe er feil.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skanning mislyktes: $error';
  }

  @override
  String get scanPumpUnreadable => 'Pumpevisning ikke lesbar – prøv igjen';

  @override
  String get scanPumpSuccess => 'Pumpevisning skannet – verifiser verdiene.';

  @override
  String scanPumpFailed(String error) {
    return 'Pumpeskanning mislyktes: $error';
  }

  @override
  String get badScanReportTitle => 'Rapporter en skanningsfeil';

  @override
  String get badScanReportTitleReceipt =>
      'Rapporter en skanningsfeil – Kvittering';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Rapporter en skanningsfeil – Pumpevisning';

  @override
  String get pumpScanFailureTitle => 'Visning ulesbar';

  @override
  String get pumpScanFailureBody =>
      'Skanningen kunne ikke lese pumpevisningen. Hva vil du gjøre?';

  @override
  String get pumpScanFailureCorrectManually => 'Korriger manuelt';

  @override
  String get pumpScanFailureReport => 'Rapporter';

  @override
  String get pumpScanFailureRemove => 'Fjern bilde';

  @override
  String get badScanReportHint =>
      'Vi deler kvitteringsbildet og begge sett med verdier slik at neste versjon kan lære dette oppsettet.';

  @override
  String get badScanReportShareAction => 'Del rapport + bilde';

  @override
  String get badScanReportFieldBrandLayout => 'Merkevisning';

  @override
  String get badScanReportFieldTotal => 'Totalt';

  @override
  String get badScanReportFieldPricePerLiter => 'Pris/L';

  @override
  String get badScanReportFieldStation => 'Stasjon';

  @override
  String get badScanReportFieldFuel => 'Drivstoff';

  @override
  String get badScanReportFieldDate => 'Dato';

  @override
  String get badScanReportHeaderField => 'Felt';

  @override
  String get badScanReportHeaderScanned => 'Skannet';

  @override
  String get badScanReportHeaderYouTyped => 'Du tastet';

  @override
  String get badScanReportCreateTicket => 'Opprett sak';

  @override
  String get badScanReportOpenInBrowser => 'Åpne i nettleser';

  @override
  String get badScanReportFallbackToShare =>
      'Innsending mislyktes – manuell deling';

  @override
  String get pumpCameraHint =>
      'Plasser de tre tallene fra pumpedisplayet innenfor rammen';

  @override
  String get pumpCameraCapture => 'Ta bilde';

  @override
  String get pumpCameraPermissionDenied =>
      'Kameratilgang trengs for å skanne pumpedisplayet. Aktiver det i enhetsinnstillingene.';

  @override
  String get pumpCameraError =>
      'Kameraet kunne ikke startes. Prøv igjen, eller skriv inn verdiene manuelt.';

  @override
  String get fillUpSectionWhatTitle => 'Hva du fylte';

  @override
  String get fillUpSectionWhatSubtitle => 'Drivstoff, mengde, pris';

  @override
  String get fillUpSectionWhereTitle => 'Hvor du var';

  @override
  String get fillUpSectionWhereSubtitle => 'Stasjon, kilometerstand, notater';

  @override
  String get fillUpImportFromLabel => 'Importer fra…';

  @override
  String get fillUpImportSheetTitle => 'Importer tankingsdata';

  @override
  String get fillUpImportReceiptLabel => 'Kvittering';

  @override
  String get fillUpImportReceiptDescription =>
      'Skann en papirkvittering med kameraet';

  @override
  String get fillUpImportPumpLabel => 'Pumpevisning';

  @override
  String get fillUpImportPumpDescription => 'Les Betrag / Preis fra pumpe-LCD';

  @override
  String get fillUpImportObdLabel => 'OBD-II-adapter';

  @override
  String get fillUpImportObdDescription =>
      'Les kilometerstand fra OBD-II-porten via Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Pris per liter';

  @override
  String get vehicleHeaderPlateLabel => 'Skilt';

  @override
  String get vehicleHeaderUntitled => 'Nytt kjøretøy';

  @override
  String get vehicleSectionIdentityTitle => 'Identitet';

  @override
  String get vehicleSectionIdentitySubtitle => 'Navn og VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Drivverk';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Hvordan dette kjøretøyet beveger seg';

  @override
  String get calibrationModeLabel => 'Kalibreringsmodus';

  @override
  String get calibrationModeRule => 'Regelbasert';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Regelbasert tildeler hver kjøreprøve til nøyaktig én situasjon. Fuzzy fordeler den på tvers av alle basert på hvor godt hver passer – jevnere rundt 60 km/h eller skiftende stigning, men tregere til å fylle alle bøtter.';

  @override
  String get profileGamificationToggleTitle => 'Vis prestasjoner og poeng';

  @override
  String get profileGamificationToggleSubtitle =>
      'Når av, er merker, poeng og trofé-ikoner skjult i hele appen.';

  @override
  String get coachingGpsLiftOff => 'Slipp gassen';

  @override
  String get coachingGpsAnticipateBrake => 'Forutse';

  @override
  String get coachingGpsSmoothAccel => 'Myk akselerasjon';

  @override
  String get gpsDiagnosticsTitle => 'GPS-prøvetakingsdiagnostikk';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps gap',
      one: '1 gap',
      zero: 'ingen gap',
    );
    return '$count prøver · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Median-intervall: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Fanget under opptak for å verifisere GPS-kadense under telefon-dvale.';

  @override
  String get gpsMatrixMaturityCold => 'Kald';

  @override
  String get gpsMatrixMaturityWarming => 'Varmes opp';

  @override
  String get gpsMatrixMaturityConverged => 'Konvergert';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS-matrisen varmes opp ($count forbedringer så langt). Estimater er foreløpige.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS-matrisen konvergerer ($count fyllinger). Estimater er brukbare men kan avvike noen %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS-matrisen har konvergert ($count fyllinger). Estimater innen ~2 % av faktisk forbruk.';
  }

  @override
  String get hapticEcoCoachSectionTitle => 'Kjøring';

  @override
  String get hapticEcoCoachSettingTitle => 'Sanntids øko-coaching';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Svak haptikk + skjermtips når du trår ned gassen under cruise';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Slipp opp for gassen – frihjuling sparer mer';

  @override
  String get anonKeyLabel => 'Anon-nøkkel';

  @override
  String get anonKeyHideTooltip => 'Skjul nøkkel';

  @override
  String get anonKeyShowTooltip => 'Vis nøkkel for å verifisere';

  @override
  String anonKeyTooLong(int length) {
    return 'Nøkkelen er for lang ($length tegn) – sjekk for ekstra tekst';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Nøkkelen ser korrekt ut ($length tegn)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Nøkkelen skal være en JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Nøkkelen kan være avkortet ($length av ~208 forventede tegn)';
  }

  @override
  String get anonKeyExceedsMax => 'Nøkkelen overskrider maksimal lengde';

  @override
  String get qrShareTitle => 'Del databasen din';

  @override
  String get qrShareSubtitle =>
      'Andre kan skanne denne QR-koden for å koble til';

  @override
  String get qrShareCopyAsText => 'Kopier som tekst';

  @override
  String get authInfoTitle => 'Hvorfor opprette en konto?';

  @override
  String get authInfoBenefit1 =>
      '• Synkroniser favoritter, varsler og lagrede ruter på tvers av enheter';

  @override
  String get authInfoBenefit2 =>
      '• Planlegg en rute på telefonen, bruk den i bilen';

  @override
  String get authInfoBenefit3 => '• Ingen data deles med tredjeparter';

  @override
  String get authInfoBenefit4 => '• Du kan slette kontoen din når som helst';

  @override
  String get privacyLocalDataEmpty =>
      'Ingenting lagret ennå. Legg til en favoritt eller sett et prisvarsel for å se oppføringer her.';

  @override
  String get privacyHideEmptyRows => 'Skjul tomme rader';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vis $count tomme rader',
      one: 'Vis $count tom rad',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-nøkkeloppsett (valgfritt)';

  @override
  String get apiKeySetupDescription =>
      'Registrer deg for en gratis API-nøkkel, eller hopp over for å utforske appen med demodata.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider-registrering';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Ved å angi en API-nøkkel godtar du vilkårene til $provider. Videredistribusjon av data er forbudt.';
  }

  @override
  String get calculatorDistanceHint => 'f.eks. 150';

  @override
  String get calculatorConsumptionHint => 'f.eks. 7.0';

  @override
  String get calculatorPriceHint => 'f.eks. 1.899';

  @override
  String get routeStrategyLabel => 'Strategi:';

  @override
  String get routeStrategyUniform => 'Jevn';

  @override
  String get routeStrategyBalanced => 'Balansert';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (eksperimentell)';

  @override
  String get glideCoachBetaSubtitle =>
      'Svak haptikk ved nedbremse foran rødt lys. Av som standard – distraksjonsrisiko.';

  @override
  String get consentSyncTripsTitle => 'Synkroniser turopptak';

  @override
  String get consentSyncTripsSubtitle =>
      'Sikkerhetskopier OBD2 + GPS-turer til TankSync. På tvers av enheter, valgfritt.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Aktiver Skysynkronisering ovenfor for å sikkerhetskopiere turer.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Logg på med en e-postkonto for å synkronisere turer mellom enheter.';

  @override
  String get consentHideDetails => 'Skjul detaljer';

  @override
  String get consentShowDetails => 'Vis detaljer';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Ugyldig lenke';

  @override
  String invalidLinkBody(String path) {
    return 'Lenken «$path» er ikke gyldig.';
  }

  @override
  String get home => 'Hjem';

  @override
  String get loyaltySettingsTitle => 'Drivstoffklubbkort';

  @override
  String get loyaltySettingsSubtitle =>
      'Bruk lojalitetsrabatten din på viste priser';

  @override
  String get loyaltyMenuTitle => 'Drivstoffklubbkort';

  @override
  String get loyaltyMenuSubtitle =>
      'Bruk per-liter-rabatter fra Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Legg til kort';

  @override
  String get loyaltyAddCardSheetTitle => 'Legg til drivstoffklubbkort';

  @override
  String get loyaltyBrandLabel => 'Merke';

  @override
  String get loyaltyCardLabelLabel => 'Etikett (valgfritt)';

  @override
  String get loyaltyDiscountLabel => 'Rabatt (per liter)';

  @override
  String get loyaltyDiscountInvalid => 'Skriv inn et positivt tall';

  @override
  String get loyaltyDeleteConfirmTitle => 'Slette kort?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Dette kortet vil slutte å bruke rabatten.';

  @override
  String get loyaltyEmptyTitle => 'Ingen drivstoffklubbkort ennå';

  @override
  String get loyaltyEmptyBody =>
      'Legg til et kort for å automatisk bruke per-liter-rabatten på samsvarende stasjoner.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Tomgangs-RPM-økning oppdaget';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Tomgangs-RPM har økt med $percent% over dine siste $tripCount turer. Mulig tidlig tegn på tilstoppet luftfilter eller sensordrift.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Mulig innsugsrestriksjon';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Cruisedrivstoffrate har falt med $percent% over dine siste $tripCount turer. Mulig tegn på tilstoppet luftfilter eller begrenset inntak – verdt en sjekk.';
  }

  @override
  String get maintenanceActionDismiss => 'Avvis';

  @override
  String get maintenanceActionSnooze => 'Utsett 30 dager';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Denne måneden vs forrige måned';

  @override
  String get consumptionMonthlyTripsLabel => 'Turer';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Kjøretid';

  @override
  String get consumptionMonthlyDistanceLabel => 'Avstand';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Snittforbruk';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Trenger minst 3 turer per måned for sammenligning';

  @override
  String get obd2CapabilitySectionTitle => 'Adapter-kapabiliteter';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'OEM PID-er';

  @override
  String get obd2CapabilityFullCan => 'Full CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'For eksakte liter-i-tank på Peugeot/Citroën støtter appen OBDLink MX+/LX/CX (STN-chip).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2-diagnostikkoverlegg aktivert';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2-diagnostikkoverlegg deaktivert';

  @override
  String get obd2DebugOverlayClearButton => 'Tøm';

  @override
  String get obd2DebugOverlayCloseButton => 'Lukk';

  @override
  String get obd2DebugOverlayTitle => 'OBD2-brødkrummer';

  @override
  String get obd2DiagnosticShareLabel => 'Del diagnoselogg';

  @override
  String get obd2DebugLoggingTitle => 'OBD2-feilsøkingslogg';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Registrer hver OBD2-økt — tilkobling, håndtrykk, datahull og gjentilkoblinger — i en eksporterbar XML-logg. Av som standard.';

  @override
  String get obd2DebugSessionShareLabel => 'Del OBD2-øktlogg';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Kunne ikke nå \'$adapterName\' – velg en annen adapter';
  }

  @override
  String get onboardingObd2StepTitle => 'Koble til OBD2-adapteren din';

  @override
  String get onboardingObd2StepBody =>
      'Sett OBD2-adapteren i bilens port og slå på tenningen. Vi leser VIN-nummeret og fyller inn motordetaljer for deg.';

  @override
  String get onboardingObd2ConnectButton => 'Koble til adapter';

  @override
  String get onboardingObd2SkipButton => 'Kanskje senere';

  @override
  String get onboardingObd2ReadingVin => 'Leser VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Kunne ikke lese VIN – skriv inn manuelt';

  @override
  String get onboardingObd2ConnectFailed =>
      'Kunne ikke koble til adapteren. Du kan prøve igjen eller hoppe over.';

  @override
  String get onboardingPickUseMode => 'Velg en bruksmodus for å fortsette.';

  @override
  String get tripRecordingPipElapsedCaption => 'forløpt';

  @override
  String get alertsRadiusFrequencyLabel => 'Sjekkhyppighet';

  @override
  String get alertsRadiusFrequencyDaily => 'En gang om dagen';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'To ganger om dagen';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tre ganger om dagen';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Fire ganger om dagen';

  @override
  String get radiusAlertPickOnMap => 'Velg på kart';

  @override
  String get radiusAlertMapPickerTitle => 'Velg varselsenter';

  @override
  String get radiusAlertMapPickerConfirm => 'Bekreft';

  @override
  String get radiusAlertMapPickerCancel => 'Avbryt';

  @override
  String get radiusAlertMapPickerHint =>
      'Dra kartet for å plassere varselsenteret';

  @override
  String get radiusAlertCenterFromMap => 'Kartposisjon';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel nær $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'En stasjon er på $price € (mål: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/økt';

  @override
  String get speedConsumptionCardTitle => 'Forbruk etter hastighet';

  @override
  String get speedBandIdleJam => 'Tomgang / kø';

  @override
  String get speedBandUrban => 'By (10–50)';

  @override
  String get speedBandSuburban => 'Forstads (50–80)';

  @override
  String get speedBandRural => 'Land (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Øko-cruise (100–115)';

  @override
  String get speedBandMotorway => 'Motorvei (115–130)';

  @override
  String get speedBandMotorwayFast => 'Motorvei rask (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Registrer 30+ minutters turer med OBD2-adapteren for å låse opp hastighet/forbruk-analysen.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % av kjøretid';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Trenger mer data';

  @override
  String get splashLoadingLabel => 'Laster Sparkilo';

  @override
  String get tankLevelTitle => 'Tanknivå';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km rekkevidde';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Siste tanking: $date · $count tur(er) siden';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2-målt';

  @override
  String get tankLevelMethodDistanceFallback => 'avstandsbasert estimat';

  @override
  String get tankLevelMethodMixed => 'blandet måling';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Logg en tanking for å se tanknivået ditt';

  @override
  String get tankLevelDetailSheetTitle => 'Turer siden siste tanking';

  @override
  String get addFillUpIsFullTankLabel => 'Full tank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tank fylt til randen – fjern avkrysning hvis dette var en delvis fylling';

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
  String get themeSettingsSystemDescription => 'Match gjeldende enhetsstil.';

  @override
  String get themeSettingsLightDescription =>
      'Lyse bakgrunner – best for dagbruk.';

  @override
  String get themeSettingsDarkDescription =>
      'Mørke bakgrunner – skånsomt for øynene om natten og sparer batteri på OLED-skjermer.';

  @override
  String get themeSettingsEcoLabel => 'Øko';

  @override
  String get themeSettingsEcoDescription =>
      'Appens karakteristiske grønne utseende – lyst og lettlest, med myk grønntonet bakgrunn.';

  @override
  String get throttleRpmHistogramTitle => 'Slik brukte du motoren';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gassposisjon';

  @override
  String get throttleRpmHistogramRpmSection => 'Motor-RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Frihjul (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Lett (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Moderat (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Full gass (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Tomgang (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Cruise (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Sportslig (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Hardt (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Ingen gass- eller RPM-prøver i denne turen.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Turer';

  @override
  String get trajetsStartRecordingButton => 'Start opptak';

  @override
  String get trajetsResumeRecordingButton => 'Gjenoppta opptak';

  @override
  String get tripStartProgressConnectingAdapter => 'Kobler til OBD2-adapter…';

  @override
  String get tripStartProgressReadingVehicleData => 'Leser kjøretøydata…';

  @override
  String get tripStartProgressStartingRecording => 'Starter opptak…';

  @override
  String get trajetsEmptyStateTitle => 'Ingen turer ennå';

  @override
  String get trajetsEmptyStateBody =>
      'Trykk Start opptak for å begynne å logge kjøreturene dine.';

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
  String get trajetDetailSummaryTitle => 'Sammendrag';

  @override
  String get trajetDetailFieldDate => 'Dato';

  @override
  String get trajetDetailFieldVehicle => 'Kjøretøy';

  @override
  String get trajetDetailFieldAdapter => 'OBD2-adapter';

  @override
  String get trajetDetailFieldDistance => 'Avstand';

  @override
  String get trajetDetailFieldDuration => 'Varighet';

  @override
  String get trajetDetailFieldAvgConsumption => 'Snittforbruk';

  @override
  String get trajetDetailFieldFuelUsed => 'Drivstoff brukt';

  @override
  String get trajetDetailFieldFuelCost => 'Drivstoffkostnad';

  @override
  String get trajetDetailFieldAvgSpeed => 'Snittfart';

  @override
  String get trajetDetailFieldMaxSpeed => 'Topphastighet';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Hastighet (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Drivstoffrate (L/t)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Motorbelastning (%)';

  @override
  String get trajetDetailChartsSection => 'Diagrammer';

  @override
  String get trajetsRowColdStartChip => 'Kaldstart';

  @override
  String get trajetsRowColdStartTooltip =>
      'Motoren nådde ikke driftstemperatur under denne turen – drivstofforbruket var høyere enn vanlig.';

  @override
  String get trajetDetailChartEmpty => 'Ingen prøver registrert';

  @override
  String get trajetDetailShareAction => 'Del';

  @override
  String get trajetDetailShareImageOption => 'Del bilde';

  @override
  String get trajetDetailShareGpxOption => 'Del GPS-spor (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Ingen GPS-data i denne turen';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — tur den $date';
  }

  @override
  String get trajetDetailShareError => 'Kunne ikke generere delbart bilde';

  @override
  String get trajetDetailDeleteAction => 'Slett';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Slette denne turen?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Denne turen vil bli permanent fjernet fra historikken din.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Avbryt';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Slett';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2-adapter tilkoblet, men returnerer ingen data. Prøv en annen adapter eller sjekk kjøretøyets diagnostikkprotokoll.';

  @override
  String get trajetsViewAllOnMap => 'Vis alle på kart';

  @override
  String get trajetsMapTitle => 'Turer på kart';

  @override
  String get trajetsMapShareGpx => 'Del GPX';

  @override
  String get trajetsMapEmpty => 'Ingen av de valgte turene har GPS-data.';

  @override
  String get trajetsMapShareError => 'Kunne ikke dele GPX-filen';

  @override
  String get tripLengthCardTitle => 'Forbruk etter turlengde';

  @override
  String get tripLengthBucketShort => 'Kort (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Middels (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Lang (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Trenger mer data';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turer',
      one: '1 tur',
      zero: 'ingen turer',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Turrute';

  @override
  String get tripPathCardSubtitle => 'GPS-registrert rute';

  @override
  String get tripPathLegendTitle => 'Forbruk';

  @override
  String get tripPathLegendEfficient => 'Effektivt (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Grenseverdi (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Ineffektivt (≥ 10 L/100km)';

  @override
  String get tripRecordingPinTooltip =>
      'Festing holder skjermen på – bruker mer batteri';

  @override
  String get tripRecordingPinSemanticOn => 'Løsne opptaksskjema';

  @override
  String get tripRecordingPinSemanticOff => 'Fest opptaksskjema';

  @override
  String get tripRecordingPinHelpTooltip => 'Hva gjør festing?';

  @override
  String get tripRecordingPinHelpTitle => 'Om festing';

  @override
  String get tripRecordingPinHelpBody =>
      'Festing holder skjermen på og skjuler systemlinjene slik at skjemaet forblir lesbart på et dashbordfeste. Trykk igjen for å løsne. Løsnes automatisk når turen stopper.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Opptaket fortsetter i bakgrunnen. Trykk på det røde banneret øverst på en skjerm for å returnere.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Åpne den aktive turen fra Forbruk-fanen';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Fest skjermen for å holde GPS aktiv under turen – Android kan begrense GPS under dvale.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimer til en flytende rute';

  @override
  String get unifiedFilterFuel => 'Drivstoff';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Begge';

  @override
  String get unifiedNoResultsForFilter =>
      'Ingen resultater passer dette filteret';

  @override
  String get searchFailedSnackbar => 'Søk mislyktes – prøv igjen';

  @override
  String get vinLabel => 'VIN (valgfritt)';

  @override
  String get vinDecodeTooltip => 'Dekod VIN';

  @override
  String get vinConfirmAction => 'Ja, autoutfyll';

  @override
  String get vinModifyAction => 'Endre manuelt';

  @override
  String get veResetAction => 'Tilbakestill volumetrisk effektivitet';

  @override
  String get vehicleReadVinFromCarButton => 'Les VIN fra bil';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Les VIN fra den tilknyttede OBD2-adapteren';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN ikke tilgjengelig (Mode 09 PID 02 støttes ikke på kjøretøy eldre enn 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN-lesing mislyktes – skriv inn manuelt';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Legg til en OBD2-adapter først for å lese VIN automatisk';

  @override
  String get pickerButtonLabel => 'Velg fra katalog';

  @override
  String get pickerSearchHint => 'Søk merke eller modell';

  @override
  String get pickerHelpText => 'Forhåndsutfyll fra 50+ støttede kjøretøy';

  @override
  String get pickerEmptyResults => 'Ingen treff';

  @override
  String get pickerCancel => 'Avbryt';

  @override
  String get pickerLoading => 'Laster katalog…';

  @override
  String get vinInfoTooltip => 'Hva er et VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Hva er et VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Kjøretøyidentifikasjonsnummeret er en 17-tegns kode som er unik for bilen din. Det er stemplet på chassiset og trykt på kjøretøyets registreringsdokument.';

  @override
  String get vinInfoSectionWhyTitle => 'Hvorfor vi spør';

  @override
  String get vinInfoSectionWhyBody =>
      'Dekoding av VIN fyller automatisk ut motorvolum, sylindertall, modellår, primær drivstofftype og tillatt totalvekt – slik at du slipper å slå opp tekniske spesifikasjoner manuelt. OBD2-drivstoffrate-beregningen bruker disse verdiene for å gi deg nøyaktige forbrukstall.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Personvern';

  @override
  String get vinInfoSectionPrivacyBody =>
      'VIN-nummeret ditt lagres kun lokalt i appens krypterte lagring – det lastes aldri opp til Sparkilo-servere. NHTSA vPIC-databasen spørres med VIN, men returnerer kun anonyme tekniske spesifikasjoner; NHTSA kobler ikke VIN til personopplysninger. Uten nett returnerer et frakoblet oppslag kun produsent og land.';

  @override
  String get vinInfoSectionWhereTitle => 'Hvor du finner det';

  @override
  String get vinInfoSectionWhereBody =>
      'Se gjennom frontruten i nedre venstre hjørne på førersiden, sjekk klistremerket på dørkarmen på førersiden når døren er åpen, eller les det av kjøretøyets registreringsdokument (kort / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Skjønt';

  @override
  String get vinConfirmPrivacyNote =>
      'Vi slo opp VIN-nummeret ditt i NHTSA sin gratis kjøretøydatabase – ingenting sendt til Sparkilo-servere.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN online-dekoding';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekod VIN via NHTSA sin gratis offentlige tjeneste';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Når du legger til en adapter, leses kjøretøyets VIN lokalt for å identifisere bilen. Aktivering av dette sender de 17 tegnene i VIN til NHTSA sin gratis vPIC-tjeneste for å slå opp tilleggsdetaljer (modell, motorvolum, drivstofftype). VIN er de eneste dataene som sendes – ingen annen informasjon forlater enheten din.';

  @override
  String get vehicleDetectedFromVinBadge => '(oppdaget)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Oppdaget fra VIN: $summary. Bruke?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Bruk';

  @override
  String get widgetHelpSectionTitle => 'Startskjerm-widget';

  @override
  String get widgetHelpIntro =>
      'Legg til SparKilo-widgeten på startskjermen for å se drivstoff- og ladepriser på et øyeblikk.';

  @override
  String get widgetHelpAdd =>
      'Legg den til fra launcherens widget-velger – trykk og hold et tomt område på startskjermen, velg Widgets, og finn SparKilo.';

  @override
  String get widgetHelpTap =>
      'Trykk på en stasjon i widgeten for å åpne den i appen. Trykk på oppdateringsikonet for å oppdatere priser.';

  @override
  String get widgetHelpConfigure =>
      'På Android, trykk og hold widgeten og velg Konfigurer for å endre profil, farge og innhold.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Valgene under gjelder for alle installerte widgeter ved neste oppdatering.';

  @override
  String get widgetDefaultsColorLabel => 'Fargevalg';

  @override
  String get widgetDefaultsVariantLabel => 'Innholdsvariant';

  @override
  String get widgetColorSchemeSystem => 'Følg systemet';

  @override
  String get widgetColorSchemeLight => 'Lys';

  @override
  String get widgetColorSchemeDark => 'Mørk';

  @override
  String get widgetColorSchemeBlue => 'Blå';

  @override
  String get widgetColorSchemeGreen => 'Grønn';

  @override
  String get widgetColorSchemeOrange => 'Oransje';

  @override
  String get widgetVariantDefault => 'Kun gjeldende pris';

  @override
  String get widgetVariantPredictive => 'Prediktiv: beste tidspunkt å tanke';

  @override
  String get widgetPredictiveNowPrefix => 'nå';
}
