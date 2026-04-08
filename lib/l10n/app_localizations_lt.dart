// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Degalų kainos';

  @override
  String get search => 'Ieškoti';

  @override
  String get favorites => 'Mėgstami';

  @override
  String get map => 'Žemėlapis';

  @override
  String get profile => 'Profilis';

  @override
  String get settings => 'Nustatymai';

  @override
  String get gpsLocation => 'GPS vieta';

  @override
  String get zipCode => 'Pašto kodas';

  @override
  String get zipCodeHint => 'pvz. 01100';

  @override
  String get fuelType => 'Degalai';

  @override
  String get searchRadius => 'Spindulys';

  @override
  String get searchNearby => 'Degalinės netoliese';

  @override
  String get searchButton => 'Ieškoti';

  @override
  String get noResults => 'Degalinių nerasta.';

  @override
  String get startSearch => 'Ieškokite degalinių.';

  @override
  String get open => 'Atidaryta';

  @override
  String get closed => 'Uždaryta';

  @override
  String distance(String distance) {
    return '$distance atstumu';
  }

  @override
  String get price => 'Kaina';

  @override
  String get prices => 'Kainos';

  @override
  String get address => 'Adresas';

  @override
  String get openingHours => 'Darbo laikas';

  @override
  String get open24h => 'Atidaryta 24 valandas';

  @override
  String get navigate => 'Navigacija';

  @override
  String get retry => 'Bandyti dar kartą';

  @override
  String get apiKeySetup => 'API raktas';

  @override
  String get apiKeyDescription =>
      'Užsiregistruokite vieną kartą nemokamam API raktui gauti.';

  @override
  String get apiKeyLabel => 'API raktas';

  @override
  String get register => 'Registracija';

  @override
  String get continueButton => 'Tęsti';

  @override
  String get welcome => 'Degalų kainos';

  @override
  String get welcomeSubtitle => 'Raskite pigiausius degalus netoliese.';

  @override
  String get profileName => 'Profilio pavadinimas';

  @override
  String get preferredFuel => 'Pageidaujami degalai';

  @override
  String get defaultRadius => 'Numatytasis spindulys';

  @override
  String get landingScreen => 'Pradinis ekranas';

  @override
  String get homeZip => 'Namų pašto kodas';

  @override
  String get newProfile => 'Naujas profilis';

  @override
  String get editProfile => 'Redaguoti profilį';

  @override
  String get save => 'Išsaugoti';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get delete => 'Ištrinti';

  @override
  String get activate => 'Aktyvuoti';

  @override
  String get configured => 'Sukonfigūruota';

  @override
  String get notConfigured => 'Nesukonfigūruota';

  @override
  String get about => 'Apie';

  @override
  String get openSource => 'Atviras kodas (MIT licencija)';

  @override
  String get sourceCode => 'Šaltinio kodas GitHub';

  @override
  String get noFavorites => 'Nėra mėgstamų';

  @override
  String get noFavoritesHint =>
      'Bakstelėkite žvaigždutę prie degalinės, kad ją išsaugotumėte kaip mėgstamą.';

  @override
  String get language => 'Kalba';

  @override
  String get country => 'Šalis';

  @override
  String get demoMode => 'Demo režimas — rodomi pavyzdiniai duomenys.';

  @override
  String get setupLiveData => 'Nustatyti gyvus duomenis';

  @override
  String get freeNoKey => 'Nemokama — raktas nereikalingas';

  @override
  String get apiKeyRequired => 'Reikalingas API raktas';

  @override
  String get skipWithoutKey => 'Tęsti be rakto';

  @override
  String get dataTransparency => 'Duomenų skaidrumas';

  @override
  String get storageAndCache => 'Saugykla ir podėlis';

  @override
  String get clearCache => 'Išvalyti podėlį';

  @override
  String get clearAllData => 'Ištrinti visus duomenis';

  @override
  String get errorLog => 'Klaidų žurnalas';

  @override
  String stationsFound(int count) {
    return 'Rasta $count degalinių';
  }

  @override
  String get whatIsShared => 'Kas dalijama — ir su kuo?';

  @override
  String get gpsCoordinates => 'GPS koordinatės';

  @override
  String get gpsReason =>
      'Siunčiamos su kiekviena paieška netoliese esančių stočių radimui.';

  @override
  String get postalCodeData => 'Pašto kodas';

  @override
  String get postalReason =>
      'Konvertuojamas į koordinates per geokodavimo paslaugą.';

  @override
  String get mapViewport => 'Žemėlapio vaizdas';

  @override
  String get mapReason =>
      'Žemėlapio plytelės įkeliamos iš serverio. Asmeniniai duomenys neperduodami.';

  @override
  String get apiKeyData => 'API raktas';

  @override
  String get apiKeyReason =>
      'Jūsų asmeninis raktas siunčiamas su kiekviena API užklausa. Jis susietas su jūsų el. paštu.';

  @override
  String get notShared => 'NĖRA dalijama:';

  @override
  String get searchHistory => 'Paieškos istorija';

  @override
  String get favoritesData => 'Mėgstami';

  @override
  String get profileNames => 'Profilių pavadinimai';

  @override
  String get homeZipData => 'Namų pašto kodas';

  @override
  String get usageData => 'Naudojimo duomenys';

  @override
  String get privacyBanner =>
      'Ši programa neturi serverio. Visi duomenys lieka jūsų įrenginyje. Jokios analitikos, sekimo ar reklamų.';

  @override
  String get storageUsage => 'Saugyklos naudojimas šiame įrenginyje';

  @override
  String get settingsLabel => 'Nustatymai';

  @override
  String get profilesStored => 'išsaugotų profilių';

  @override
  String get stationsMarked => 'pažymėtų stočių';

  @override
  String get cachedResponses => 'podėlyje esančių atsakymų';

  @override
  String get total => 'Iš viso';

  @override
  String get cacheManagement => 'Podėlio valdymas';

  @override
  String get cacheDescription =>
      'Podėlis saugo API atsakymus greitesniam įkėlimui ir prieigai neprisijungus.';

  @override
  String get stationSearch => 'Stočių paieška';

  @override
  String get stationDetails => 'Stoties informacija';

  @override
  String get priceQuery => 'Kainos užklausa';

  @override
  String get zipGeocoding => 'Pašto kodo geokodavimas';

  @override
  String minutes(int n) {
    return '$n minučių';
  }

  @override
  String hours(int n) {
    return '$n valandų';
  }

  @override
  String get clearCacheTitle => 'Išvalyti podėlį?';

  @override
  String get clearCacheBody =>
      'Podėlyje esantys paieškos rezultatai ir kainos bus ištrinti. Profiliai, mėgstami ir nustatymai išsaugomi.';

  @override
  String get clearCacheButton => 'Išvalyti podėlį';

  @override
  String get deleteAllTitle => 'Ištrinti visus duomenis?';

  @override
  String get deleteAllBody =>
      'Tai visam laikui ištrina visus profilius, mėgstamus, API raktą, nustatymus ir podėlį. Programa bus atstatyta.';

  @override
  String get deleteAllButton => 'Ištrinti viską';

  @override
  String get entries => 'įrašų';

  @override
  String get cacheEmpty => 'Podėlis tuščias';

  @override
  String get noStorage => 'Saugykla nenaudojama';

  @override
  String get apiKeyNote =>
      'Nemokama registracija. Duomenys iš vyriausybinių kainų skaidrumo agentūrų.';

  @override
  String get apiKeyFormatError =>
      'Netinkamas formatas — tikėtinas UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Palaikykite šį projektą';

  @override
  String get supportDescription =>
      'Ši programa yra nemokama, atviro kodo ir be reklamų. Jei manote, kad ji naudinga, apsvarstykite galimybę paremti kūrėją.';

  @override
  String get reportBug => 'Pranešti apie klaidą / Pasiūlyti funkciją';

  @override
  String get privacyPolicy => 'Privatumo politika';

  @override
  String get fuels => 'Degalai';

  @override
  String get services => 'Paslaugos';

  @override
  String get zone => 'Zona';

  @override
  String get highway => 'Greitkelis';

  @override
  String get localStation => 'Vietinė stotis';

  @override
  String get lastUpdate => 'Paskutinis atnaujinimas';

  @override
  String get automate24h => '24val/24 — Automatas';

  @override
  String get refreshPrices => 'Atnaujinti kainas';

  @override
  String get station => 'Degalinė';

  @override
  String get locationDenied =>
      'Vietos leidimas atmestas. Galite ieškoti pagal pašto kodą.';

  @override
  String get demoModeBanner =>
      'Demo režimas. Nustatykite API raktą nustatymuose.';

  @override
  String get sortDistance => 'Atstumas';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'pigu';

  @override
  String get expensive => 'brangu';

  @override
  String stationsOnMap(int count) {
    return '$count stočių';
  }

  @override
  String get loadingFavorites =>
      'Įkeliami mėgstami...\nPirmiausia ieškokite stočių duomenims išsaugoti.';

  @override
  String get reportPrice => 'Pranešti apie kainą';

  @override
  String get whatsWrong => 'Kas negerai?';

  @override
  String get correctPrice => 'Teisinga kaina (pvz. 1,459)';

  @override
  String get sendReport => 'Siųsti pranešimą';

  @override
  String get reportSent => 'Pranešimas išsiųstas. Ačiū!';

  @override
  String get enterValidPrice => 'Įveskite galiojančią kainą';

  @override
  String get cacheCleared => 'Podėlis išvalytas.';

  @override
  String get yourPosition => 'Jūsų pozicija';

  @override
  String get positionUnknown => 'Pozicija nežinoma';

  @override
  String get distancesFromCenter => 'Atstumai nuo paieškos centro';

  @override
  String get autoUpdatePosition => 'Automatiškai atnaujinti poziciją';

  @override
  String get autoUpdateDescription =>
      'Atnaujinti GPS poziciją prieš kiekvieną paiešką';

  @override
  String get location => 'Vieta';

  @override
  String get switchProfileTitle => 'Šalis pasikeitė';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Dabar esate $country. Perjungti į profilį \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Perjungta į profilį \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Nėra profilio šiai šaliai';

  @override
  String noProfileForCountry(String country) {
    return 'Esate $country, bet profilis nesukonfigūruotas. Sukurkite jį Nustatymuose.';
  }

  @override
  String get autoSwitchProfile => 'Automatinis profilio perjungimas';

  @override
  String get autoSwitchDescription =>
      'Automatiškai perjungti profilį kertant sieną';

  @override
  String get switchProfile => 'Perjungti';

  @override
  String get dismiss => 'Uždaryti';

  @override
  String get profileCountry => 'Šalis';

  @override
  String get profileLanguage => 'Kalba';

  @override
  String get settingsStorageDetail => 'API raktas, aktyvus profilis';

  @override
  String get allFuels => 'Visi';

  @override
  String get priceAlerts => 'Kainų įspėjimai';

  @override
  String get noPriceAlerts => 'Nėra kainų įspėjimų';

  @override
  String get noPriceAlertsHint =>
      'Sukurkite įspėjimą iš stoties informacijos puslapio.';

  @override
  String alertDeleted(String name) {
    return 'Įspėjimas \"$name\" ištrintas';
  }

  @override
  String get createAlert => 'Sukurti kainos įspėjimą';

  @override
  String currentPrice(String price) {
    return 'Dabartinė kaina: $price';
  }

  @override
  String get targetPrice => 'Tikslinė kaina (EUR)';

  @override
  String get enterPrice => 'Įveskite kainą';

  @override
  String get invalidPrice => 'Neteisinga kaina';

  @override
  String get priceTooHigh => 'Kaina per didelė';

  @override
  String get create => 'Sukurti';

  @override
  String get alertCreated => 'Kainos įspėjimas sukurtas';

  @override
  String get wrongE5Price => 'Neteisinga Super E5 kaina';

  @override
  String get wrongE10Price => 'Neteisinga Super E10 kaina';

  @override
  String get wrongDieselPrice => 'Neteisinga dyzelino kaina';

  @override
  String get wrongStatusOpen => 'Rodoma kaip atidaryta, bet uždaryta';

  @override
  String get wrongStatusClosed => 'Rodoma kaip uždaryta, bet atidaryta';

  @override
  String get searchAlongRouteLabel => 'Palei maršrutą';

  @override
  String get searchEvStations => 'Ieškoti įkrovimo stočių';

  @override
  String get allStations => 'Visos stotys';

  @override
  String get bestStops => 'Geriausios stotelės';

  @override
  String get openInMaps => 'Atidaryti Žemėlapiuose';

  @override
  String get noStationsAlongRoute => 'Stočių palei maršrutą nerasta';

  @override
  String get evOperational => 'Veikianti';

  @override
  String get evStatusUnknown => 'Būsena nežinoma';

  @override
  String evConnectors(int count) {
    return 'Jungtys ($count taškų)';
  }

  @override
  String get evNoConnectors => 'Nėra jungčių informacijos';

  @override
  String get evUsageCost => 'Naudojimo kaina';

  @override
  String get evPricingUnavailable => 'Kainodara neprieinama iš teikėjo';

  @override
  String get evLastUpdated => 'Paskutinį kartą atnaujinta';

  @override
  String get evUnknown => 'Nežinoma';

  @override
  String get evDataAttribution =>
      'Duomenys iš OpenChargeMap (bendruomenės šaltinis)';

  @override
  String get evStatusDisclaimer =>
      'Būsena gali neatspindėti prieinamumo realiuoju laiku. Bakstelėkite atnaujinti naujausiems duomenims gauti.';

  @override
  String get evNavigateToStation => 'Navigacija iki stoties';

  @override
  String get evRefreshStatus => 'Atnaujinti būseną';

  @override
  String get evStatusUpdated => 'Būsena atnaujinta';

  @override
  String get evStationNotFound =>
      'Nepavyko atnaujinti — stotis nerasta netoliese';

  @override
  String get addedToFavorites => 'Pridėta prie mėgstamų';

  @override
  String get removedFromFavorites => 'Pašalinta iš mėgstamų';

  @override
  String get addFavorite => 'Pridėti prie mėgstamų';

  @override
  String get removeFavorite => 'Pašalinti iš mėgstamų';

  @override
  String get currentLocation => 'Dabartinė vieta';

  @override
  String get gpsError => 'GPS klaida';

  @override
  String get couldNotResolve => 'Nepavyko nustatyti pradžios ar tikslo';

  @override
  String get start => 'Pradžia';

  @override
  String get destination => 'Tikslas';

  @override
  String get cityAddressOrGps => 'Miestas, adresas arba GPS';

  @override
  String get cityOrAddress => 'Miestas arba adresas';

  @override
  String get useGps => 'Naudoti GPS';

  @override
  String get stop => 'Stotelė';

  @override
  String stopN(int n) {
    return 'Stotelė $n';
  }

  @override
  String get addStop => 'Pridėti stotelę';

  @override
  String get searchAlongRoute => 'Ieškoti palei maršrutą';

  @override
  String get cheapest => 'Pigiausia';

  @override
  String nStations(int count) {
    return '$count stočių';
  }

  @override
  String nBest(int count) {
    return '$count geriausių';
  }

  @override
  String get fuelPricesTankerkoenig => 'Degalų kainos (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Reikalingas degalų kainų paieškai Vokietijoje';

  @override
  String get evChargingOpenChargeMap => 'EV įkrovimas (OpenChargeMap)';

  @override
  String get customKey => 'Pasirinktinis raktas';

  @override
  String get appDefaultKey => 'Numatytasis programos raktas';

  @override
  String get optionalOverrideKey =>
      'Pasirinktinai: pakeiskite integruotą programos raktą savu';

  @override
  String get requiredForEvSearch => 'Reikalingas EV įkrovimo stočių paieškai';

  @override
  String get edit => 'Redaguoti';

  @override
  String get fuelPricesApiKey => 'Degalų kainų API raktas';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API raktas';

  @override
  String get evChargingApiKey => 'EV įkrovimo API raktas';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API raktas';

  @override
  String get routeSegment => 'Maršruto segmentas';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Rodyti pigiausią stotį kas $km km palei maršrutą';
  }

  @override
  String get avoidHighways => 'Vengti greitkelių';

  @override
  String get avoidHighwaysDesc =>
      'Maršruto skaičiavimas vengia mokamų kelių ir greitkelių';

  @override
  String get showFuelStations => 'Rodyti degalines';

  @override
  String get showFuelStationsDesc =>
      'Įtraukti benzino, dyzelino, LPG, CNG stotis';

  @override
  String get showEvStations => 'Rodyti įkrovimo stotis';

  @override
  String get showEvStationsDesc =>
      'Įtraukti elektrinius įkrovimo stotis į rezultatus';

  @override
  String get noStationsAlongThisRoute => 'Stočių palei šį maršrutą nerasta.';

  @override
  String get fuelCostCalculator => 'Degalų kaštų skaičiuoklė';

  @override
  String get distanceKm => 'Atstumas (km)';

  @override
  String get consumptionL100km => 'Sąnaudos (L/100km)';

  @override
  String get fuelPriceEurL => 'Degalų kaina (EUR/L)';

  @override
  String get tripCost => 'Kelionės kaina';

  @override
  String get fuelNeeded => 'Reikalingi degalai';

  @override
  String get totalCost => 'Bendra kaina';

  @override
  String get enterCalcValues =>
      'Įveskite atstumą, sąnaudas ir kainą kelionės kainos apskaičiavimui';

  @override
  String get priceHistory => 'Kainų istorija';

  @override
  String get noPriceHistory => 'Kainų istorijos dar nėra';

  @override
  String get noHourlyData => 'Nėra valandinių duomenų';

  @override
  String get noStatistics => 'Nėra prieinamų statistikų';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Maks';

  @override
  String get statAvg => 'Vid';

  @override
  String get showAllFuelTypes => 'Rodyti visus degalų tipus';

  @override
  String get connected => 'Prisijungta';

  @override
  String get notConnected => 'Neprisijungta';

  @override
  String get connectTankSync => 'Prijungti TankSync';

  @override
  String get disconnectTankSync => 'Atjungti TankSync';

  @override
  String get viewMyData => 'Peržiūrėti mano duomenis';

  @override
  String get optionalCloudSync =>
      'Pasirenkama debesų sinchronizacija įspėjimams, mėgstamiems ir push pranešimams';

  @override
  String get tapToUpdateGps => 'Bakstelėkite GPS pozicijos atnaujinimui';

  @override
  String get gpsAutoUpdateHint =>
      'GPS pozicija gaunama automatiškai ieškant. Čia galite ją atnaujinti ir rankiniu būdu.';

  @override
  String get clearGpsConfirm =>
      'Išvalyti išsaugotą GPS poziciją? Galite ją bet kada atnaujinti iš naujo.';

  @override
  String get pageNotFound => 'Puslapis nerastas';

  @override
  String get deleteAllServerData => 'Ištrinti visus serverio duomenis';

  @override
  String get deleteServerDataConfirm => 'Ištrinti visus serverio duomenis?';

  @override
  String get deleteEverything => 'Ištrinti viską';

  @override
  String get allDataDeleted => 'Visi serverio duomenys ištrinti';

  @override
  String get disconnectConfirm => 'Atjungti TankSync?';

  @override
  String get disconnect => 'Atjungti';

  @override
  String get myServerData => 'Mano serverio duomenys';

  @override
  String get anonymousUuid => 'Anoniminis UUID';

  @override
  String get server => 'Serveris';

  @override
  String get syncedData => 'Sinchronizuoti duomenys';

  @override
  String get pushTokens => 'Push žetonai';

  @override
  String get priceReports => 'Kainų pranešimai';

  @override
  String get totalItems => 'Iš viso elementų';

  @override
  String get estimatedSize => 'Numatomas dydis';

  @override
  String get viewRawJson => 'Peržiūrėti neapdorotus duomenis kaip JSON';

  @override
  String get exportJson => 'Eksportuoti kaip JSON (iškarpinė)';

  @override
  String get jsonCopied => 'JSON nukopijuotas į iškarpinę';

  @override
  String get rawDataJson => 'Neapdoroti duomenys (JSON)';

  @override
  String get close => 'Uždaryti';

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
  String get alertStatsActive => 'Aktyvūs';

  @override
  String get alertStatsToday => 'Šiandien';

  @override
  String get alertStatsThisWeek => 'Šią savaitę';

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
}
