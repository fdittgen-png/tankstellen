// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Atidaryti paiešką';

  @override
  String get fabOpenResults => 'Atidaryti rezultatus';

  @override
  String get fabRunSearch => 'Vykdyti paiešką';

  @override
  String get fabRefineCriteria => 'Tikslinti paiešką';

  @override
  String get routeSearchPartialBanner => 'Ieškoma daugiau stočių…';

  @override
  String get searchCriteriaTitle => 'Paieškos kriterijai';

  @override
  String get searchCriteriaOpen => 'Ieškoti';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km spinduliu';
  }

  @override
  String get searchCriteriaTapToSearch => 'Palieskite, kad pradėtumėte paiešką';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Pakeisti šalį?';

  @override
  String countryChangeBody(String country) {
    return 'Perjungus į $country pasikeis:';
  }

  @override
  String get countryChangeCurrency => 'Valiuta';

  @override
  String get countryChangeDistance => 'Atstumas';

  @override
  String get countryChangeVolume => 'Tūris';

  @override
  String get countryChangePricePerUnit => 'Kainos formatas';

  @override
  String get countryChangeNote =>
      'Esami mėgstami ir tankinimo įrašai nėra perrašomi; tik nauji įrašai naudoja naujus vienetus.';

  @override
  String get countryChangeConfirm => 'Perjungti';

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
  String get cacheTtlGroupNetwork => 'Tinklas';

  @override
  String get cacheTtlGroupData => 'Duomenys';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodavimas';

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
  String get reportThisIssue => 'Pranešti apie problemą';

  @override
  String get reportAlreadySent => 'Jūs jau pranešėte apie šią problemą.';

  @override
  String get reportConsentTitle => 'Pranešti GitHub?';

  @override
  String get reportConsentBody =>
      'Bus atidarytas viešas GitHub pranešimas su žemiau pateikta klaidos informacija. GPS koordinatės, API raktai ar asmeniniai duomenys neįtraukiami.';

  @override
  String get reportConsentConfirm => 'Atidaryti GitHub';

  @override
  String get reportConsentCancel => 'Atšaukti';

  @override
  String get configProfileSection => 'Profilis';

  @override
  String get configActiveProfile => 'Aktyvus profilis';

  @override
  String get configPreferredFuel => 'Pageidaujamas kuras';

  @override
  String get configCountry => 'Šalis';

  @override
  String get configRouteSegment => 'Maršruto atkarpa';

  @override
  String get configApiKeysSection => 'API raktai';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API raktas';

  @override
  String get configApiKeyConfigured => 'Sukonfigūruotas';

  @override
  String get configApiKeyNotSet => 'Nenustatytas (demo režimas)';

  @override
  String get configApiKeyCommunity => 'Numatytasis (bendruomenės raktas)';

  @override
  String get searchLocationPlaceholder => 'Adresas, pašto kodas arba miestas';

  @override
  String get configEvKey => 'EV įkrovimo API raktas';

  @override
  String get configEvKeyCustom => 'Pasirinktinis raktas';

  @override
  String get configEvKeyShared => 'Numatytasis (bendrinamas)';

  @override
  String get configCloudSyncSection => 'Debesų sinchronizavimas';

  @override
  String get configTankSyncConnected => 'Prisijungta';

  @override
  String get configTankSyncDisabled => 'Išjungta';

  @override
  String get configAuthMode => 'Autentifikacijos režimas';

  @override
  String get configAuthEmail => 'El. paštas (nuolatinis)';

  @override
  String get configAuthAnonymous => 'Anoniminis (tik įrenginyje)';

  @override
  String get configDatabase => 'Duomenų bazė';

  @override
  String get configPrivacySummary => 'Privatumo santrauka';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Mėgstami, įspėjimai ir nepaisomi stoteliai sinchronizuojami su jūsų privačia duomenų baze\n• GPS vieta ir API raktai niekada nepalieka jūsų įrenginio\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Visi duomenys saugomi tik šiame įrenginyje\n• Jokie duomenys neišsiunčiami į serverį\n• API raktai šifruojami įrenginio saugiojoje saugykloje';

  @override
  String get configAuthNoteEmail =>
      'El. pašto paskyra suteikia prieigą iš kelių įrenginių';

  @override
  String get configAuthNoteAnonymous =>
      'Anoniminė paskyra — duomenys susieti su šiuo įrenginiu';

  @override
  String get configNone => 'Nėra';

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
  String get demoModeBannerAction => 'Gauti tiesiogines kainas';

  @override
  String get sortDistance => 'Atstumas';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Įvertinimas';

  @override
  String get sortPriceDistance => 'Kaina/km';

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
  String get routeModeBannerLabel =>
      'Maršruto režimas — atstumai išilgai koridoriaus';

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
  String get routePlanningSection => 'Maršruto planavimas';

  @override
  String get routeMinSaving => 'Minimalus sutaupymas';

  @override
  String get routeMinSavingOff => 'Išjungta';

  @override
  String get routeMinSavingOffCaption =>
      'Rodomos visos maršrute rastos stotelės';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Tik stotelės $amount ribose nuo pigiausios maršrute';
  }

  @override
  String get routeDetourBudget => 'Didžiausias apylankas';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Rodyti stoteles iki $km km nuo tiesioginio maršruto';
  }

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
  String get ignoredStationsLabel => 'Ignoruojama';

  @override
  String get ratingsLabel => 'Įvertinimai';

  @override
  String get favoritesDataCache => 'Mėgstamiausių duomenys';

  @override
  String get citySearchCache => 'Miesto paieška';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Duomenų ištrynimas nepasiekiamas Bendruomenės režime. Pirmiausia atsijunkite arba naudokite privačią duomenų bazę.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count stebimų stočių';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count sukonfigūruota';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count paslėptų stočių';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count įvertintų stočių';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Ištrinti visas sinchronizuotas keliones';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Ištrinti visas sinchronizuotas keliones?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Kiekvienas kelionės santraukos ir detalių blokas bus pašalintas iš serverio. Vietinė kelionių istorija šiame įrenginyje nebus paveikta.\n\nŠio veiksmo negalima atšaukti.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Ištrinti viską';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Visos sinchronizuotos kelionės pašalintos iš serverio';

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
  String get syncedTrips => 'Kelionės';

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
  String get account => 'Paskyra';

  @override
  String get continueAsGuest => 'Tęsti kaip svečias';

  @override
  String get createAccount => 'Sukurti paskyrą';

  @override
  String get signIn => 'Prisijungti';

  @override
  String get upgradeToEmail => 'Sukurti el. pašto paskyrą';

  @override
  String get savedRoutes => 'Išsaugoti maršrutai';

  @override
  String get noSavedRoutes => 'Nėra išsaugotų maršrutų';

  @override
  String get noSavedRoutesHint =>
      'Ieškokite palei maršrutą ir išsaugokite jį greitai prieigai vėliau.';

  @override
  String get saveRoute => 'Išsaugoti maršrutą';

  @override
  String get routeName => 'Maršruto pavadinimas';

  @override
  String itineraryDeleted(String name) {
    return '$name ištrintas';
  }

  @override
  String loadingRoute(String name) {
    return 'Kraunamas maršrutas: $name';
  }

  @override
  String get refreshFailed => 'Atnaujinti nepavyko. Bandykite dar kartą.';

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
  String get onboardingWelcomeHint =>
      'Nustatykite programą per kelis greitus žingsnius.';

  @override
  String get onboardingApiKeyDescription =>
      'Užsiregistruokite nemokamai gauti API raktą arba praleiskite ir tyrinėkite programą su demonstraciniais duomenimis.';

  @override
  String get onboardingComplete => 'Viskas paruošta!';

  @override
  String get onboardingCompleteHint =>
      'Šiuos nustatymus galite keisti bet kada savo profilyje.';

  @override
  String get onboardingBack => 'Atgal';

  @override
  String get onboardingNext => 'Toliau';

  @override
  String get onboardingSkip => 'Praleisti';

  @override
  String get onboardingFinish => 'Pradėti';

  @override
  String crossBorderNearby(String country) {
    return '$country yra netoliese';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km iki sienos';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Vid. čia: $price EUR ($count stotelės)';
  }

  @override
  String get allPricesView => 'Visos kainos';

  @override
  String get compactView => 'Kompaktiškas';

  @override
  String get switchToAllPricesView => 'Perjungti į visų kainų rodinį';

  @override
  String get switchToCompactView => 'Perjungti į kompaktišką rodinį';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Neturime';

  @override
  String get gdprTitle => 'Jūsų privatumas';

  @override
  String get gdprSubtitle =>
      'Ši programa gerbia jūsų privatumą. Pasirinkite, kokiais duomenimis norite dalintis. Šiuos nustatymus galite keisti bet kada.';

  @override
  String get gdprLocationTitle => 'Prieiga prie vietos';

  @override
  String get gdprLocationDescription =>
      'Jūsų koordinatės siunčiamos kuro kainų API, kad rastų artimas stotelinas. Vietos duomenys niekada nesaugomi serveryje ir nenaudojami stebėjimui.';

  @override
  String get gdprLocationShort => 'Raskite artimas degalines pagal savo vietą';

  @override
  String get gdprErrorReportingTitle => 'Klaidų pranešimas';

  @override
  String get gdprErrorReportingDescription =>
      'Anoniminės gedimų ataskaitos padeda tobulinti programą. Asmeniniai duomenys neįtraukiami. Ataskaitos siunčiamos per Sentry tik sukonfigūravus.';

  @override
  String get gdprErrorReportingShort =>
      'Siųsti anonimines gedimų ataskaitas programai tobulinti';

  @override
  String get gdprCloudSyncTitle => 'Debesų sinchronizavimas';

  @override
  String get gdprCloudSyncDescription =>
      'Sinchronizuokite mėgstamus ir įspėjimus įvairiuose įrenginiuose per TankSync. Naudojama anoniminė autentifikacija. Jūsų duomenys šifruojami siunčiant.';

  @override
  String get gdprCloudSyncShort =>
      'Sinchronizuoti mėgstamus ir įspėjimus įvairiuose įrenginiuose';

  @override
  String get gdprLegalBasis =>
      'Teisinis pagrindas: BDAR 6 str. 1 d. a p. (Sutikimas). Sutikimą galite atšaukti bet kada Nustatymuose.';

  @override
  String get gdprAcceptAll => 'Priimti viską';

  @override
  String get gdprAcceptSelected => 'Priimti pasirinktus';

  @override
  String get gdprSettingsHint =>
      'Savo privatumo pasirinkimus galite keisti bet kada.';

  @override
  String get routeSaved => 'Maršrutas išsaugotas!';

  @override
  String get routeSaveFailed => 'Nepavyko išsaugoti maršruto';

  @override
  String get sqlCopied => 'SQL nukopijuotas į iškarpinę';

  @override
  String get connectionDataCopied => 'Prisijungimo duomenys nukopijuoti';

  @override
  String get accountDeleted =>
      'Paskyra ištrinta. Vietiniai duomenys išsaugoti.';

  @override
  String get switchedToAnonymous => 'Perjungta į anoniminę sesiją';

  @override
  String failedToSwitch(String error) {
    return 'Nepavyko perjungti: $error';
  }

  @override
  String get topicUrlCopied => 'Temos URL nukopijuotas';

  @override
  String get testNotificationSent => 'Bandomasis pranešimas išsiųstas!';

  @override
  String get testNotificationFailed => 'Nepavyko išsiųsti bandomojo pranešimo';

  @override
  String get pushUpdateFailed =>
      'Nepavyko atnaujinti stumtiamojo pranešimo nustatymo';

  @override
  String get connectedAsGuest => 'Prisijungta kaip svečias';

  @override
  String get accountCreated => 'Paskyra sukurta!';

  @override
  String get signedIn => 'Prisijungta!';

  @override
  String stationHidden(String name) {
    return '$name paslėpta';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name pašalinta iš mėgstamų';
  }

  @override
  String invalidApiKey(String error) {
    return 'Neteisingas API raktas: $error';
  }

  @override
  String get invalidQrCode => 'Neteisingas QR kodo formatas';

  @override
  String get invalidQrCodeTankSync =>
      'Neteisingas QR kodas — laukiamas TankSync formatas';

  @override
  String get tankSyncConnected => 'TankSync prijungtas!';

  @override
  String get syncCompleted => 'Sinchronizavimas baigtas — duomenys atnaujinti';

  @override
  String get deviceCodeCopied => 'Įrenginio kodas nukopijuotas';

  @override
  String get undo => 'Atšaukti';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Įveskite teisingą $length skaitmenų $label';
  }

  @override
  String get freshnessAgo => 'prieš';

  @override
  String get freshnessStale => 'Pasenę';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Duomenų aktualumas: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand logotipas';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Įvertinti $count žvaigždutėmis',
      one: 'Įvertinti 1 žvaigžde',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Silpnas';

  @override
  String get passwordStrengthFair => 'Vidutinis';

  @override
  String get passwordStrengthStrong => 'Stiprus';

  @override
  String get passwordReqMinLength => 'Bent 8 simboliai';

  @override
  String get passwordReqUppercase => 'Bent 1 didžioji raidė';

  @override
  String get passwordReqLowercase => 'Bent 1 mažoji raidė';

  @override
  String get passwordReqDigit => 'Bent 1 skaičius';

  @override
  String get passwordReqSpecial => 'Bent 1 specialusis simbolis';

  @override
  String get passwordTooWeak => 'Slaptažodis neatitinka visų reikalavimų';

  @override
  String get brandFilterAll => 'Visi';

  @override
  String get brandFilterNoHighway => 'Be greitkelio';

  @override
  String get swipeTutorialMessage =>
      'Braukite dešinėn naršyti, kairėn — šalinti';

  @override
  String get swipeTutorialDismiss => 'Supratau';

  @override
  String get alertStatsActive => 'Aktyvūs';

  @override
  String get alertStatsToday => 'Šiandien';

  @override
  String get alertStatsThisWeek => 'Šią savaitę';

  @override
  String get privacyDashboardTitle => 'Privatumo prietaisų skydelis';

  @override
  String get privacyDashboardSubtitle =>
      'Peržiūrėkite, eksportuokite arba ištrinkite savo duomenis';

  @override
  String get privacyDashboardBanner =>
      'Jūsų duomenys priklauso jums. Čia galite pamatyti viską, ką programa saugo, eksportuoti arba ištrinti.';

  @override
  String get privacyLocalData => 'Duomenys šiame įrenginyje';

  @override
  String get privacyIgnoredStations => 'Ignoruojamos stotelės';

  @override
  String get privacyRatings => 'Stotelių įvertinimai';

  @override
  String get privacyPriceHistory => 'Kainų istorijos stotelės';

  @override
  String get privacyProfiles => 'Paieškos profiliai';

  @override
  String get privacyItineraries => 'Išsaugoti maršrutai';

  @override
  String get privacyCacheEntries => 'Talpyklos įrašai';

  @override
  String get privacyApiKey => 'Saugomas API raktas';

  @override
  String get privacyEvApiKey => 'Saugomas EV API raktas';

  @override
  String get privacyEstimatedSize => 'Apytikslis saugyklos dydis';

  @override
  String get privacySyncedData => 'Debesų sinchronizavimas (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Debesų sinchronizavimas išjungtas. Visi duomenys lieka tik šiame įrenginyje.';

  @override
  String get privacySyncMode => 'Sinchronizavimo režimas';

  @override
  String get privacySyncUserId => 'Naudotojo ID';

  @override
  String get privacySyncDescription =>
      'Kai sinchronizavimas įjungtas, mėgstami, įspėjimai, ignoruojamos stotelės ir įvertinimai taip pat saugomi TankSync serveryje.';

  @override
  String get privacyViewServerData => 'Peržiūrėti serverio duomenis';

  @override
  String get privacyExportButton => 'Eksportuoti visus duomenis kaip JSON';

  @override
  String get privacyExportSuccess => 'Duomenys eksportuoti į iškarpinę';

  @override
  String get privacyExportCsvButton => 'Eksportuoti visus duomenis kaip CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV duomenys eksportuoti į iškarpinę';

  @override
  String get savedToDownloadsFolder => 'Išsaugota aplanke Atsisiuntimai';

  @override
  String get privacyDeleteButton => 'Ištrinti visus duomenis';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopijuoti klaidų žurnalą į iškarpinę ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Įrašyti klaidų žurnalą ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Išvalyti klaidų žurnalą';

  @override
  String get privacyErrorLogCleared => 'Klaidų žurnalas išvalytas';

  @override
  String get privacyDeleteTitle => 'Ištrinti visus duomenis?';

  @override
  String get privacyDeleteBody =>
      'Bus visam laikui ištrinta:\n\n- Visi mėgstami ir stotelių duomenys\n- Visi paieškos profiliai\n- Visi kainų įspėjimai\n- Visa kainų istorija\n- Visi talpykloje esantys duomenys\n- Jūsų API raktas\n- Visi programos nustatymai\n\nPrograma bus atstatyta į pradinę būseną. Šio veiksmo negalima atšaukti.';

  @override
  String get privacyDeleteConfirm => 'Ištrinti viską';

  @override
  String get yes => 'Taip';

  @override
  String get no => 'Ne';

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
  String get paymentMethods => 'Mokėjimo būdai';

  @override
  String get paymentMethodCash => 'Grynieji';

  @override
  String get paymentMethodCard => 'Kortelė';

  @override
  String get paymentMethodContactless => 'Bekontaktis';

  @override
  String get paymentMethodFuelCard => 'Degalų kortelė';

  @override
  String get paymentMethodApp => 'Programa';

  @override
  String payWithApp(String app) {
    return 'Mokėti su $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Palyginti su slankiuoju vidurkiu per paskutines 3 tankavimus ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Suvartojimas $value L/100 km, $delta palyginti su jūsų slankiuoju vidurkiu';
  }

  @override
  String get drivingMode => 'Vairavimo režimas';

  @override
  String get drivingExit => 'Išeiti';

  @override
  String get drivingNearestStation => 'Artimiausia';

  @override
  String get drivingTapToUnlock => 'Palieskite, kad atblokuotumėte';

  @override
  String get drivingSafetyTitle => 'Saugos pranešimas';

  @override
  String get drivingSafetyMessage =>
      'Nevaldykite programos vairuodami. Prieš naudodami ekraną sustokite saugioje vietoje. Vairuotojas visada atsako už saugų transporto priemonės valdymą.';

  @override
  String get drivingSafetyAccept => 'Suprantu';

  @override
  String get voiceAnnouncementsTitle => 'Balso pranešimai';

  @override
  String get voiceAnnouncementsDescription =>
      'Pranešti apie artimas pigias degalines vairuojant';

  @override
  String get voiceAnnouncementsEnabled => 'Įjungti balso pranešimus';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Tik žemiau $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometrų pirmyn, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Pranešimų spindulys';

  @override
  String get voiceAnnouncementCooldown => 'Kartojimo intervalas';

  @override
  String get nearestStations => 'Artimiausios degalines';

  @override
  String get nearestStationsHint =>
      'Raskite artimiausias degalines pagal jusu dabartine vieta';

  @override
  String get consumptionLogTitle => 'Kuro suvartojimas';

  @override
  String get consumptionLogMenuTitle => 'Suvartojimo žurnalas';

  @override
  String get consumptionLogMenuSubtitle =>
      'Sekite tankavimus ir skaičiuokite L/100km';

  @override
  String get consumptionStatsTitle => 'Suvartojimo statistika';

  @override
  String get addFillUp => 'Pridėti tankavimą';

  @override
  String get noFillUpsTitle => 'Dar nėra tankavimų';

  @override
  String get noFillUpsSubtitle =>
      'Įveskite pirmą tankavimą, kad pradėtumėte sekti suvartojimą.';

  @override
  String get fillUpDate => 'Data';

  @override
  String get liters => 'Litrai';

  @override
  String get odometerKm => 'Odometras (km)';

  @override
  String get notesOptional => 'Pastabos (neprivaloma)';

  @override
  String get stationPreFilled => 'Stotelė iš anksto užpildyta';

  @override
  String get statAvgConsumption => 'Vid. L/100km';

  @override
  String get statAvgCostPerKm => 'Vid. kaina/km';

  @override
  String get statTotalLiters => 'Iš viso litrų';

  @override
  String get statTotalSpent => 'Iš viso išleista';

  @override
  String get statFillUpCount => 'Tankavimai';

  @override
  String get fieldRequired => 'Privaloma';

  @override
  String get fieldInvalidNumber => 'Neteisingas skaičius';

  @override
  String get carbonDashboardTitle => 'CO2 prietaisų skydelis';

  @override
  String get carbonEmptyTitle => 'Dar nėra duomenų';

  @override
  String get carbonEmptySubtitle =>
      'Įveskite tankavimus, kad matytumėte CO2 prietaisų skydelį.';

  @override
  String get carbonSummaryTotalCost => 'Bendra kaina';

  @override
  String get carbonSummaryTotalCo2 => 'Iš viso CO2';

  @override
  String get monthlyCostsTitle => 'Mėnesio išlaidos';

  @override
  String get monthlyEmissionsTitle => 'Mėnesio CO2 emisijos';

  @override
  String get vehiclesTitle => 'Mano transporto priemonės';

  @override
  String get vehiclesMenuTitle => 'Mano transporto priemonės';

  @override
  String get vehiclesMenuSubtitle => 'Baterija, jungtys, įkrovimo nuostatos';

  @override
  String get vehiclesEmptyMessage =>
      'Pridėkite savo automobilį, kad filtruotumėte pagal jungtis ir įvertintumėte įkrovimo išlaidas.';

  @override
  String get vehiclesWizardTitle => 'Mano transporto priemonės (neprivaloma)';

  @override
  String get vehiclesWizardSubtitle =>
      'Pridėkite savo automobilį, kad iš anksto užpildytumėte suvartojimo žurnalą ir įjungtumėte EV jungčių filtrus. Galite praleisti ir pridėti transporto priemones vėliau.';

  @override
  String get vehiclesWizardNoneYet =>
      'Dar nėra sukonfigūruotos transporto priemonės.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transporto priemones',
      one: '1 transporto priemonę',
    );
    return 'Turite $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Praleiskite, kad baigtumėte sąranką — transporto priemones galite pridėti bet kada iš Nustatymų.';

  @override
  String get fillUpVehicleLabel => 'Transporto priemonė';

  @override
  String get fillUpVehicleNone => 'Nėra transporto priemonės';

  @override
  String get fillUpVehicleRequired => 'Transporto priemonė būtina';

  @override
  String get reportScanError => 'Pranešti apie nuskaitymo klaidą';

  @override
  String get pickStationTitle => 'Pasirinkite stotelę';

  @override
  String get pickStationHelper =>
      'Pradėkite tankavimą iš žinomos stotelės, kad kainos, prekinis ženklas ir kuro tipas būtų užpildyti automatiškai.';

  @override
  String get pickStationEmpty =>
      'Dar nėra mėgstamų stotelių — pridėkite iš Paieškos arba Mėgstamų, arba praleiskite ir užpildykite rankiniu būdu.';

  @override
  String get pickStationSkip => 'Praleisti — pridėti be stotelės';

  @override
  String get scanPump => 'Nuskaityti siurblį';

  @override
  String get scanPayment => 'Nuskaityti mokėjimo QR';

  @override
  String get qrPaymentBeneficiary => 'Gavėjas';

  @override
  String get qrPaymentAmount => 'Suma';

  @override
  String get qrPaymentEpcTitle => 'SEPA mokėjimas';

  @override
  String get qrPaymentEpcEmpty => 'Nerasta laukų';

  @override
  String get qrPaymentOpenInBank => 'Atidaryti banko programoje';

  @override
  String get qrPaymentLaunchFailed => 'Nėra programos šiam kodui atidaryti';

  @override
  String get qrPaymentUnknownTitle => 'Neatpažintas kodas';

  @override
  String get qrPaymentCopyRaw => 'Kopijuoti neapdorotą tekstą';

  @override
  String get qrPaymentCopiedRaw => 'Nukopijuota į iškarpinę';

  @override
  String get qrPaymentReport => 'Pranešti apie šį nuskaitymą';

  @override
  String get qrPaymentEpcCopied =>
      'Banko duomenys nukopijuoti — įklijuokite į savo bankininkystės programą';

  @override
  String get qrScannerGuidance => 'Nukreipkite kamerą į QR kodą';

  @override
  String get qrScannerPermissionDenied =>
      'Norint nuskaityti QR kodus reikalinga prieiga prie kameros.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Prieiga prie kameros buvo uždrausta. Atidarykite nustatymus, kad suteiktumėte.';

  @override
  String get qrScannerRetryPermission => 'Bandyti dar kartą';

  @override
  String get qrScannerOpenSettings => 'Atidaryti nustatymus';

  @override
  String get qrScannerTimeout =>
      'QR kodas neaptiktas. Priartinkite arba bandykite dar kartą.';

  @override
  String get qrScannerRetry => 'Bandyti dar kartą';

  @override
  String get torchOn => 'Įjungti blykstę';

  @override
  String get torchOff => 'Išjungti blykstę';

  @override
  String get obdNoAdapter => 'Nėra OBD2 adapterio ryšio zonoje';

  @override
  String get obdOdometerUnavailable => 'Nepavyko nuskaityti odometro';

  @override
  String get obdPermissionDenied =>
      'Suteikite Bluetooth leidimą sistemos nustatymuose';

  @override
  String get obdAdapterUnresponsive =>
      'Adapteris neatsako — įjunkite uždegimą ir bandykite dar kartą';

  @override
  String get obdPickerTitle => 'Pasirinkite OBD2 adapterį';

  @override
  String get obdPickerScanning => 'Ieškoma adapterių…';

  @override
  String get obdPickerConnecting => 'Jungiamasi…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Šviesi';

  @override
  String get themeModeDark => 'Tamsi';

  @override
  String get themeModeSystem => 'Pagal sistemą';

  @override
  String get tripRecordingTitle => 'Kelionės įrašymas';

  @override
  String get tripSummaryTitle => 'Kelionės santrauka';

  @override
  String get tripMetricDistance => 'Atstumas';

  @override
  String get tripMetricSpeed => 'Greitis';

  @override
  String get tripMetricFuelUsed => 'Sunaudotas kuras';

  @override
  String get tripMetricAvgConsumption => 'Vid.';

  @override
  String get tripMetricElapsed => 'Praėjo';

  @override
  String get tripMetricOdometer => 'Odometras';

  @override
  String get tripStop => 'Sustabdyti įrašymą';

  @override
  String get tripPause => 'Pristabdyti';

  @override
  String get tripResume => 'Tęsti';

  @override
  String get tripBannerRecording => 'Įrašoma kelionė';

  @override
  String get tripBannerPaused =>
      'Kelionė pristabdyta — palieskite, kad tęstumėte';

  @override
  String get navConsumption => 'Suvartojimas';

  @override
  String get vehicleBaselineSectionTitle => 'Bazinė kalibracija';

  @override
  String get vehicleBaselineEmpty =>
      'Dar nėra pavyzdžių — pradėkite OBD2 kelionę, kad galėtumėte mokytis šios transporto priemonės kuro profilį.';

  @override
  String get vehicleBaselineProgress =>
      'Išmokta iš pavyzdžių įvairiose vairavimo situacijose.';

  @override
  String get vehicleBaselineReset => 'Atstatyti vairavimo situacijos bazę';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Atstatyti vairavimo situacijos bazę?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Tai ištrina visus išmokytus šios transporto priemonės pavyzdžius. Grįšite prie šaltojo paleidimo numatytųjų reikšmių, kol naujos kelionės vėl užpildys profilį.';

  @override
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapteris';

  @override
  String get vehicleAdapterEmpty =>
      'Nėra suporuoto adapterio. Suporuokite vieną, kad programa galėtų automatiškai prisijungti kitą kartą.';

  @override
  String get vehicleAdapterUnnamed => 'Nežinomas adapteris';

  @override
  String get vehicleAdapterPair => 'Suporuoti adapterį';

  @override
  String get vehicleAdapterForget => 'Pašalinti adapterį';

  @override
  String get achievementsTitle => 'Pasiekimai';

  @override
  String get achievementFirstTrip => 'Pirmoji kelionė';

  @override
  String get achievementFirstTripDesc => 'Įrašykite pirmą OBD2 kelionę.';

  @override
  String get achievementFirstFillUp => 'Pirmasis tankavimas';

  @override
  String get achievementFirstFillUpDesc => 'Įveskite pirmą tankavimą.';

  @override
  String get achievementTenTrips => '10 kelionių';

  @override
  String get achievementTenTripsDesc => 'Įrašykite 10 OBD2 kelionių.';

  @override
  String get achievementZeroHarsh => 'Sklandus vairuotojas';

  @override
  String get achievementZeroHarshDesc =>
      'Įveikite 10 km ar ilgesnę kelionę be staigaus stabdymo ar greitinimo.';

  @override
  String get achievementEcoWeek => 'Eko savaitė';

  @override
  String get achievementEcoWeekDesc =>
      'Vairuokite 7 dienas iš eilės, kiekvieną dieną turint bent vieną sklandų reisą.';

  @override
  String get achievementPriceWin => 'Kainų laimėjimas';

  @override
  String get achievementPriceWinDesc =>
      'Įveskite tankavimą, kuris yra 5% ar daugiau žemiau stotelės 30 dienų vidurkio.';

  @override
  String get syncBaselinesToggleTitle =>
      'Bendrinti išmokytus transporto priemonių profilius';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Įkelti kiekvienos transporto priemonės suvartojimo bazes, kad kitas įrenginys galėtų jas pakartotinai naudoti.';

  @override
  String get obd2StatusConnected => 'OBD2 adapteris: prijungtas';

  @override
  String get obd2StatusAttempting => 'OBD2 adapteris: jungiamasi';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapteris: nepasiekiamas';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapteris: reikalingas Bluetooth leidimas';

  @override
  String get obd2StatusConnectedBody => 'Paruošta įrašyti kelionę.';

  @override
  String get obd2StatusAttemptingBody => 'Jungiamasi fone…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapteris už ryšio zonos ribų arba jau naudojamas kitos programos.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Suteikite Bluetooth leidimą sistemos nustatymuose, kad prisijungtumėte automatiškai.';

  @override
  String get obd2StatusNoAdapter => 'Nėra suporuoto adapterio';

  @override
  String get obd2StatusForget => 'Pašalinti adapterį';

  @override
  String get tripHistoryTitle => 'Kelionių istorija';

  @override
  String get tripHistoryEmptyTitle => 'Dar nėra kelionių';

  @override
  String get tripHistoryEmptySubtitle =>
      'Prijunkite OBD2 adapterį ir įrašykite kelionę, kad pradėtumėte kaupti vairavimo istoriją.';

  @override
  String get tripHistoryUnknownDate => 'Nežinoma data';

  @override
  String get situationIdle => 'Tuščioji eiga';

  @override
  String get situationStopAndGo => 'Trūkčiojantis eismas';

  @override
  String get situationUrban => 'Miestas';

  @override
  String get situationHighway => 'Greitkelis';

  @override
  String get situationDecel => 'Lėtėjimas';

  @override
  String get situationClimbing => 'Kalimas / pakrovimas';

  @override
  String get situationHardAccel => 'Staigus greitinimas';

  @override
  String get situationFuelCut => 'Kuro atjungimas — inercinė eiga';

  @override
  String get tripSaveAsFillUp => 'Išsaugoti kaip tankavimą';

  @override
  String get tripSaveRecording => 'Išsaugoti kelionę';

  @override
  String get tripDiscard => 'Atmesti';

  @override
  String obdOdometerRead(int km) {
    return 'Odometras nuskaitytas: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nenustatyta';

  @override
  String get wizardVehicleTapToEdit => 'Palieskite, kad redaguotumėte';

  @override
  String get wizardVehicleDefaultBadge => 'Numatytasis';

  @override
  String get wizardProfileChoiceHint =>
      'Pasirinkite, kaip norite naudoti programą. Tai galite keisti vėliau Nustatymuose.';

  @override
  String get wizardProfileChoiceFooter =>
      'Savo pasirinkimą galite keisti bet kada Nustatymai → Naudojimo režimas.';

  @override
  String get wizardProfileBasicName => 'Pagrindinis';

  @override
  String get wizardProfileBasicDescription =>
      'Pigiausias kuras ir EV įkrovimo kainos netoliese. Mėgstami ir kainų įspėjimai.';

  @override
  String get wizardProfileMediumName => 'Vidutinis';

  @override
  String get wizardProfileMediumDescription =>
      'Viskas iš Pagrindinio, plius rankiniu būdu sekite kuro tankavimus ir EV įkrovimą.';

  @override
  String get wizardProfileFullName => 'Pilnas';

  @override
  String get wizardProfileFullDescription =>
      'Viskas iš Vidutinio, plius automatinis OBD2 kelionių įrašymas, vairavimo balai ir lojalumo kortelės.';

  @override
  String get wizardProfileCustomName => 'Pasirinktinis';

  @override
  String get wizardProfileCustomDescription =>
      'Jūsų paties funkcijų derinys. Sureguliuokite kiekvieną jungiklį žemiau.';

  @override
  String get useModeSectionHint =>
      'Pritaikykite programą prie tikrojo naudojimo. Pasirinkus išankstinį nustatymą, įjungiamas atitinkamas funkcijų rinkinys.';

  @override
  String get useModeCustomSettingsDescription =>
      'Jūsų funkcijų derinys neatitinka jokio išankstinio nustatymo. Pasirinkite vieną aukščiau, kad perrašytumėte, arba toliau tinkinkite atskiras funkcijas žemiau esančiame skyriuje.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Naudojimo režimas nustatytas į $profile.';
  }

  @override
  String get profileDefaultVehicleLabel =>
      'Numatytoji transporto priemonė (neprivaloma)';

  @override
  String get profileDefaultVehicleNone => 'Nėra numatytosios';

  @override
  String get profileFuelFromVehicleHint =>
      'Kuro tipas paimamas iš jūsų numatytosios transporto priemonės. Ištrinkite transporto priemonę, kad pasirinktumėte kurą tiesiogiai.';

  @override
  String get consumptionNoVehicleTitle =>
      'Pirmiausia pridėkite transporto priemonę';

  @override
  String get consumptionNoVehicleBody =>
      'Tankavimai priskiriami transporto priemonei. Pridėkite savo automobilį, kad pradėtumėte įrašinėti suvartojimą.';

  @override
  String get vehicleAdd => 'Pridėti transporto priemonę';

  @override
  String get vehicleAddTitle => 'Pridėti transporto priemonę';

  @override
  String get vehicleEditTitle => 'Redaguoti transporto priemonę';

  @override
  String get vehicleDeleteTitle => 'Ištrinti transporto priemonę?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Pašalinti \"$name\" iš jūsų profilių?';
  }

  @override
  String get vehicleNameLabel => 'Pavadinimas';

  @override
  String get vehicleNameHint => 'pvz. Mano Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Vidaus degimo';

  @override
  String get vehicleTypeHybrid => 'Hibridas';

  @override
  String get vehicleTypeEv => 'Elektra';

  @override
  String get vehicleEvSectionTitle => 'Elektra';

  @override
  String get vehicleCombustionSectionTitle => 'Vidaus degimas';

  @override
  String get vehicleBatteryLabel => 'Baterijos talpa (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maks. įkrovimo galia (kW)';

  @override
  String get vehicleConnectorsLabel => 'Palaikomos jungtys';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Bako talpa (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Pageidaujamas kuras';

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
  String get connectorThreePin => '3 kontaktai';

  @override
  String get evShowOnMap => 'Rodyti EV stoteles';

  @override
  String get evAvailableOnly => 'Tik laisvos';

  @override
  String get evMinPower => 'Min galia';

  @override
  String get evMaxPower => 'Maks galia';

  @override
  String get evOperator => 'Operatorius';

  @override
  String get evLastUpdate => 'Paskutinis atnaujinimas';

  @override
  String get evStatusAvailable => 'Laisva';

  @override
  String get evStatusOccupied => 'Užimta';

  @override
  String get evStatusOutOfOrder => 'Neveikia';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Tik atidarytos';

  @override
  String get saveAsDefaults => 'Išsaugoti kaip numatytuosius';

  @override
  String get criteriaSavedToProfile => 'Išsaugota kaip numatytieji';

  @override
  String get profileNotFound => 'Nėra aktyvaus profilio';

  @override
  String get updatingFavorites => 'Atnaujinami jūsų mėgstami...';

  @override
  String get fetchingLatestPrices => 'Gaunamos naujausios kainos';

  @override
  String get noDataAvailable => 'Nėra duomenų';

  @override
  String get configAndPrivacy => 'Konfigūracija ir privatumas';

  @override
  String get searchToSeeMap => 'Ieškokite, kad matytumėte stoteles žemėlapyje';

  @override
  String get evPowerAny => 'Bet kokia';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profilis';

  @override
  String get sectionLocation => 'Vieta';

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
  String get tooltipBack => 'Atgal';

  @override
  String get tooltipClose => 'Uždaryti';

  @override
  String get tooltipShare => 'Bendrinti';

  @override
  String get tooltipClearSearch => 'Išvalyti paieškos lauką';

  @override
  String get minimalDriveInstantConsumption => 'Momentinės sąnaudos';

  @override
  String get coachingShiftUp => 'Aukštyn pavarą';

  @override
  String get coachingShiftDown => 'Žemyn pavarą';

  @override
  String get coachingEasePedal => 'Atleisk akceleratorių';

  @override
  String get tooltipUseGps => 'Naudoti GPS vietą';

  @override
  String get tooltipShowPassword => 'Rodyti slaptažodį';

  @override
  String get tooltipHidePassword => 'Slėpti slaptažodį';

  @override
  String get evConnectorsLabel => 'Prieinamos jungtys';

  @override
  String get evConnectorsNone => 'Nėra informacijos apie jungtis';

  @override
  String get switchToEmail => 'Perjungti į el. paštą';

  @override
  String get switchToEmailSubtitle =>
      'Išsaugokite duomenis, pridėkite prisijungimą iš kitų įrenginių';

  @override
  String get switchToAnonymousAction => 'Perjungti į anoniminį';

  @override
  String get switchToAnonymousSubtitle =>
      'Išsaugokite vietinius duomenis, naudokite naują anoniminę sesiją';

  @override
  String get linkDevice => 'Susieti įrenginį';

  @override
  String get shareDatabase => 'Bendrinti duomenų bazę';

  @override
  String get disconnectAction => 'Atjungti';

  @override
  String get disconnectSubtitle =>
      'Sustabdyti sinchronizavimą (vietiniai duomenys išsaugomi)';

  @override
  String get deleteAccountAction => 'Ištrinti paskyrą';

  @override
  String get deleteAccountSubtitle =>
      'Visam laikui pašalinti visus serverio duomenis';

  @override
  String get localOnly => 'Tik vietinis';

  @override
  String get localOnlySubtitle =>
      'Neprivaloma: sinchronizuokite mėgstamus, įspėjimus ir įvertinimus įvairiuose įrenginiuose';

  @override
  String get setupCloudSync => 'Nustatyti debesų sinchronizavimą';

  @override
  String get disconnectTitle => 'Atjungti TankSync?';

  @override
  String get disconnectBody =>
      'Debesų sinchronizavimas bus išjungtas. Jūsų vietiniai duomenys (mėgstami, įspėjimai, istorija) išsaugomi šiame įrenginyje. Serverio duomenys nėra ištrinami.';

  @override
  String get deleteAccountTitle => 'Ištrinti paskyrą?';

  @override
  String get deleteAccountBody =>
      'Tai visam laikui ištrina visus jūsų duomenis iš serverio (mėgstami, įspėjimai, įvertinimai, maršrutai). Vietiniai duomenys šiame įrenginyje išsaugomi.\n\nŠio veiksmo negalima atšaukti.';

  @override
  String get switchToAnonymousTitle => 'Perjungti į anoniminį?';

  @override
  String get switchToAnonymousBody =>
      'Būsite atsijungę nuo el. pašto paskyros ir tęsite su nauja anonimine sesija.\n\nJūsų vietiniai duomenys (mėgstami, įspėjimai) išsaugomi šiame įrenginyje ir bus sinchronizuojami su nauja anonimine paskyra.';

  @override
  String get switchAction => 'Perjungti';

  @override
  String get helpBannerCriteria =>
      'Jūsų profilio numatytieji duomenys iš anksto užpildyti. Sureguliuokite kriterijus žemiau, kad patikslintumėte paiešką.';

  @override
  String get helpBannerAlerts =>
      'Nustatykite kainų ribą stotelei. Gausite pranešimą, kai kainos nukris žemiau jos. Patikrinimas vykdomas kas 30 minučių.';

  @override
  String get helpBannerConsumption =>
      'Įveskite kiekvieną tankavimą, kad sektumėte realų suvartojimą ir CO₂ pėdsaką. Braukite kairėn, kad ištrintumėte įrašą.';

  @override
  String get helpBannerVehicles =>
      'Pridėkite savo transporto priemones, kad tankavimai ir kuro nuostatos būtų nustatomi teisingai. Pirmoji transporto priemonė tampa jūsų numatytąja.';

  @override
  String get syncNow => 'Sinchronizuoti dabar';

  @override
  String get onboardingPreferencesTitle => 'Jūsų nuostatos';

  @override
  String get onboardingZipHelper => 'Naudojama, kai GPS nepasiekiamas';

  @override
  String get onboardingRadiusHelper => 'Didesnis spindulys = daugiau rezultatų';

  @override
  String get onboardingPrivacy =>
      'Šie nustatymai saugomi tik jūsų įrenginyje ir niekada nėra bendrinama.';

  @override
  String get onboardingLandingTitle => 'Pradinis ekranas';

  @override
  String get onboardingLandingHint =>
      'Pasirinkite, kuris ekranas atsidaro paleidus programą.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Neišeikite iš programos — bet jos neuždarykite.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Atidarykite Sparkilo kartą po kiekvieno perkrovimo.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple pažadina Sparkilo tik tada, kai ją bent kartą atidarėte po telefono perkrovimo. Po to jūsų kelionės įrašomos automatiškai.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Neišmeskite Sparkilo iš programų perjungiklio.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Priverstinis uždarymas\" nurodo iOS nustoti iš naujo paleisti programą. Kelionės nustos įsirašyti, kol vėl atidarysite Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Kai iOS prašo \"Visada\" vietos leidimo, prašome sutikti.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Atsarginė sistema, kuri įrašo jūsų kelionę, kai OBD2 adapteris lėtas, reikalauja foninės vietos. Mes jos niekada nebendrinsime.';

  @override
  String get scanReceipt => 'Nuskaityti kvitą';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Degalinė';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Greitkelis';

  @override
  String get ratingModeLocal => 'Vietinis';

  @override
  String get ratingModePrivate => 'Privatus';

  @override
  String get ratingModeShared => 'Bendrinamas';

  @override
  String get ratingDescLocal => 'Įvertinimai išsaugoti tik šiame įrenginyje';

  @override
  String get ratingDescPrivate =>
      'Sinchronizuota su jūsų duomenų baze (kitiems nematoma)';

  @override
  String get ratingDescShared =>
      'Matoma visiems jūsų duomenų bazės naudotojams';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API raktas nesukonfigūruotas. Pridėkite jį Nustatymuose, kad ieškotumėte EV įkrovimo stotelių.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Duomenų tiekėjas ($host) naudoja pasibaigusį arba neteisingą TLS sertifikatą. Programa negali įkelti duomenų iš šio šaltinio, kol tiekėjas to nepataisys. Susisiekite su $host.';
  }

  @override
  String get offlineLabel => 'Neprisijungęs';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nepasiekiama. Naudojama $current.';
  }

  @override
  String get errorTitleApiKey => 'Reikalingas API raktas';

  @override
  String get errorTitleLocation => 'Vieta nepasiekiama';

  @override
  String get errorHintNoStations =>
      'Pabandykite padidinti paieškos spindulį arba ieškokite kitoje vietoje.';

  @override
  String get errorHintApiKey => 'Sukonfigūruokite savo API raktą Nustatymuose.';

  @override
  String get errorHintConnection =>
      'Patikrinkite interneto ryšį ir bandykite dar kartą.';

  @override
  String get errorHintRouting =>
      'Maršruto skaičiavimas nepavyko. Patikrinkite interneto ryšį ir bandykite dar kartą.';

  @override
  String get errorHintFallback =>
      'Bandykite dar kartą arba ieškokite pagal pašto kodą / miesto pavadinimą.';

  @override
  String get alertsLoadErrorTitle => 'Nepavyko įkelti jūsų įspėjimų';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Foninė įspėjimų patikra nepavyko';

  @override
  String get detailsLabel => 'Detalės';

  @override
  String get remove => 'Pašalinti';

  @override
  String get showKey => 'Rodyti raktą';

  @override
  String get hideKey => 'Slėpti raktą';

  @override
  String get syncOptionalTitle => 'TankSync yra neprivalomas';

  @override
  String get syncOptionalDescription =>
      'Jūsų programa veikia visapusiškai be debesų sinchronizavimo. TankSync leidžia sinchronizuoti mėgstamus, įspėjimus ir įvertinimus įvairiuose įrenginiuose naudojant Supabase (galima nemokama versija).';

  @override
  String get syncHowToConnectQuestion => 'Kaip norėtumėte prisijungti?';

  @override
  String get syncCreateOwnTitle => 'Sukurti savo duomenų bazę';

  @override
  String get syncCreateOwnSubtitle =>
      'Nemokamas Supabase projektas — paimsime per žingsnius';

  @override
  String get syncJoinExistingTitle => 'Prisijungti prie esamos duomenų bazės';

  @override
  String get syncJoinExistingSubtitle =>
      'Nuskaitykite QR kodą iš duomenų bazės savininko arba įklijuokite prisijungimo duomenis';

  @override
  String get syncChooseAccountType => 'Pasirinkite paskyros tipą';

  @override
  String get syncAccountTypeAnonymous => 'Anoniminis';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Momentinis, nereikia el. pašto. Duomenys susieti su šiuo įrenginiu.';

  @override
  String get syncAccountTypeEmail => 'El. pašto paskyra';

  @override
  String get syncAccountTypeEmailDesc =>
      'Prisijunkite iš bet kurio įrenginio. Atkurkite duomenis, jei prarasite telefoną.';

  @override
  String get syncHaveAccountSignIn => 'Jau turite paskyrą? Prisijunkite';

  @override
  String get syncCreateNewAccount => 'Sukurti naują paskyrą';

  @override
  String get syncTestConnection => 'Patikrinti ryšį';

  @override
  String get syncTestingConnection => 'Tikrinama...';

  @override
  String get syncConnectButton => 'Prisijungti';

  @override
  String get syncConnectingButton => 'Jungiamasi...';

  @override
  String get syncDatabaseReady => 'Duomenų bazė paruošta!';

  @override
  String get syncDatabaseNeedsSetup => 'Duomenų bazė reikalauja sąrankos';

  @override
  String get syncTableStatusOk => 'Gerai';

  @override
  String get syncTableStatusMissing => 'Trūksta';

  @override
  String get syncSqlEditorInstructions =>
      'Nukopijuokite žemiau esantį SQL ir paleiskite jį savo Supabase SQL Redaktoriuje (Prietaisų skydelis → SQL Redaktorius → Nauja užklausa → Įklijuoti → Paleisti)';

  @override
  String get syncCopySqlButton => 'Kopijuoti SQL į iškarpinę';

  @override
  String get syncRecheckSchemaButton => 'Pakartotinai patikrinti schemą';

  @override
  String get syncDoneButton => 'Atlikta';

  @override
  String syncSignedInAs(String email) {
    return 'Prisijungta kaip $email';
  }

  @override
  String get syncEmailDescription =>
      'Jūsų duomenys sinchronizuojami visuose įrenginiuose su šiuo el. paštu.';

  @override
  String get syncSwitchToAnonymousTitle => 'Perjungti į anoniminį';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Tęsti be el. pašto, nauja anoniminė sesija';

  @override
  String get syncGuestDescription => 'Anoniminis, nereikia el. pašto.';

  @override
  String get syncOrDivider => 'arba';

  @override
  String get syncHowToSyncQuestion => 'Kaip norėtumėte sinchronizuoti?';

  @override
  String get syncOfflineDescription =>
      'Jūsų programa veikia visapusiškai neprisijungus. Debesų sinchronizavimas yra neprivalomas.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo bendruomenė';

  @override
  String get syncModeCommunitySubtitle =>
      'Bendrinkite mėgstamus ir įvertinimus su visais naudotojais';

  @override
  String get syncModePrivateTitle => 'Privati duomenų bazė';

  @override
  String get syncModePrivateSubtitle =>
      'Jūsų paties Supabase — visiškas duomenų valdymas';

  @override
  String get syncModeGroupTitle => 'Prisijungti prie grupės';

  @override
  String get syncModeGroupSubtitle =>
      'Šeimos ar draugų bendrinama duomenų bazė';

  @override
  String get syncPrivacyShared => 'Bendrinama';

  @override
  String get syncPrivacyPrivate => 'Privatu';

  @override
  String get syncPrivacyGroup => 'Grupė';

  @override
  String get syncStayOfflineButton => 'Likti neprisijungus';

  @override
  String get syncSuccessTitle => 'Sėkmingai prisijungta!';

  @override
  String get syncSuccessDescription =>
      'Jūsų duomenys dabar bus sinchronizuojami automatiškai.';

  @override
  String get syncWizardTitleConnect => 'Prijungti TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Jūsų duomenų bazė';

  @override
  String get syncSetupTitleJoinGroup => 'Prisijungti prie grupės';

  @override
  String get syncSetupTitleAccount => 'Jūsų paskyra';

  @override
  String get syncWizardBack => 'Atgal';

  @override
  String get syncWizardNext => 'Toliau';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return '$current žingsnis iš $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Sukurti Supabase projektą';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Palieskite \"Atidaryti Supabase\" žemiau\n2. Sukurkite nemokamą paskyrą (jei neturite)\n3. Spauskite \"Naujas projektas\"\n4. Pasirinkite pavadinimą ir regioną\n5. Palaukite ~2 minutes, kol bus paleistas';

  @override
  String get syncWizardOpenSupabase => 'Atidaryti Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Įjungti anoniminius prisijungimus';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Savo Supabase prietaisų skydelyje:\n   Autentifikacija → Tiekėjai\n2. Raskite \"Anoniminiai prisijungimai\"\n3. Įjunkite jungiklį\n4. Spauskite \"Išsaugoti\"';

  @override
  String get syncWizardOpenAuthSettings =>
      'Atidaryti autentifikacijos nustatymus';

  @override
  String get syncWizardCopyCredentialsTitle =>
      'Nukopijuokite savo prisijungimo duomenis';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Eikite į Nustatymai → API savo prietaisų skydelyje\n2. Nukopijuokite \"Projekto URL\"\n3. Nukopijuokite \"anon public\" raktą\n4. Įklijuokite juos žemiau';

  @override
  String get syncWizardOpenApiSettings => 'Atidaryti API nustatymus';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://jūsų-projektas.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Prisijungti prie esamos duomenų bazės';

  @override
  String get syncWizardScanQrCode => 'Nuskaityti QR kodą';

  @override
  String get syncWizardAskOwnerQr =>
      'Paprašykite duomenų bazės savininko parodyti savo QR kodą\n(Nustatymai → TankSync → Bendrinti)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Paprašykite duomenų bazės savininko parodyti savo QR kodą';

  @override
  String get syncWizardEnterManuallyTitle => 'Įvesti rankiniu būdu';

  @override
  String get syncWizardOrEnterManually => 'arba įveskite rankiniu būdu';

  @override
  String get syncWizardUrlHelperText =>
      'Tarpai ir eilučių pertraukos pašalinami automatiškai';

  @override
  String get syncCredentialsPrivateHint =>
      'Įveskite savo Supabase projekto prisijungimo duomenis. Juos rasite savo prietaisų skydelyje Nustatymai > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Duomenų bazės URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Prieigos raktas';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'El. paštas';

  @override
  String get authPasswordLabel => 'Slaptažodis';

  @override
  String get authConfirmPasswordLabel => 'Patvirtinti slaptažodį';

  @override
  String get authPleaseEnterEmail => 'Įveskite savo el. paštą';

  @override
  String get authInvalidEmail => 'Neteisingas el. pašto adresas';

  @override
  String get authPasswordsDoNotMatch => 'Slaptažodžiai nesutampa';

  @override
  String get authConnectAnonymously => 'Prisijungti anonimiškai';

  @override
  String get authCreateAccountAndConnect => 'Sukurti paskyrą ir prisijungti';

  @override
  String get authSignInAndConnect => 'Prisijungti ir sujungti';

  @override
  String get authAnonymousSegment => 'Anoniminis';

  @override
  String get authEmailSegment => 'El. paštas';

  @override
  String get authAnonymousDescription =>
      'Momentinė prieiga, nereikia el. pašto. Duomenys susieti su šiuo įrenginiu.';

  @override
  String get authEmailDescription =>
      'Prisijunkite iš bet kurio įrenginio. Atkurkite duomenis, jei prarasite telefoną.';

  @override
  String get authSyncAcrossDevices =>
      'Automatiškai sinchronizuokite duomenis visuose savo įrenginiuose.';

  @override
  String get authNewHereCreateAccount => 'Naujas čia? Sukurti paskyrą';

  @override
  String get linkDeviceScreenTitle => 'Susieti įrenginį';

  @override
  String get linkDeviceThisDeviceLabel => 'Šis įrenginys';

  @override
  String get linkDeviceShareCodeHint =>
      'Bendrinkite šį kodą su kitu įrenginiu:';

  @override
  String get linkDeviceNotConnected => 'Neprisijungta';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopijuoti kodą';

  @override
  String get linkDeviceImportSectionTitle => 'Importuoti iš kito įrenginio';

  @override
  String get linkDeviceImportDescription =>
      'Įveskite įrenginio kodą iš kito įrenginio, kad importuotumėte jo mėgstamus, įspėjimus, transporto priemones ir suvartojimo žurnalą. Kiekvienas įrenginys turi savo profilį ir numatytuosius nustatymus.';

  @override
  String get linkDeviceCodeFieldLabel => 'Įrenginio kodas';

  @override
  String get linkDeviceCodeFieldHint => 'Įklijuokite UUID iš kito įrenginio';

  @override
  String get linkDeviceImportButton => 'Importuoti duomenis';

  @override
  String get linkDeviceHowItWorksTitle => 'Kaip tai veikia';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Įrenginyje A: nukopijuokite įrenginio kodą aukščiau\n2. Įrenginyje B: įklijuokite jį į lauką \"Įrenginio kodas\"\n3. Palieskite \"Importuoti duomenis\", kad sujungtumėte mėgstamus, įspėjimus, transporto priemones ir suvartojimo žurnalus\n4. Abu įrenginiai turės visus sujungtus duomenis\n\nKiekvienas įrenginys turi savo anoniminę tapatybę ir savo profilį (pageidaujamas kuras, numatytoji transporto priemonė, pradinis ekranas). Duomenys sujungiami, o ne perkeliami.';

  @override
  String get vehicleSetActive => 'Nustatyti aktyvų';

  @override
  String get swipeHide => 'Slėpti';

  @override
  String get evChargingSection => 'EV įkrovimas';

  @override
  String get fuelStationsSection => 'Degalinės';

  @override
  String get yourRating => 'Jūsų įvertinimas';

  @override
  String get noStorageUsed => 'Saugykla nenaudojama';

  @override
  String get aboutReportBug => 'Pranešti apie klaidą / Pasiūlyti funkciją';

  @override
  String get aboutSupportProject => 'Palaikyti šį projektą';

  @override
  String get aboutSupportDescription =>
      'Ši programa yra nemokama, atvirojo kodo ir be reklamos. Jei ji jums naudinga, apsvarstykite galimybę palaikyti kūrėją.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Liuksemburgo kuro kainos yra valstybės reguliuojamos ir vienodos visoje šalyje.';

  @override
  String get luxembourgFuelUnleaded95 => '95 be švino';

  @override
  String get luxembourgFuelUnleaded98 => '98 be švino';

  @override
  String get luxembourgFuelDiesel => 'Dyzelis';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Liuksemburgo reguliuojamos kainos nepasiekiamos.';

  @override
  String get reportIssueTitle => 'Pranešti apie problemą';

  @override
  String get enterCorrection => 'Įveskite pataisymą';

  @override
  String get reportNoBackendAvailable =>
      'Pranešimo išsiųsti nepavyko: šiai šaliai nėra sukonfigūruotos pranešimų tarnybos. Įjunkite TankSync Nustatymuose, kad siųstumėte bendruomenės pranešimus.';

  @override
  String get correctName => 'Teisingas stotelės pavadinimas';

  @override
  String get correctAddress => 'Teisingas adresas';

  @override
  String get wrongE85Price => 'Neteisinga E85 kaina';

  @override
  String get wrongE98Price => 'Neteisinga Super 98 kaina';

  @override
  String get wrongLpgPrice => 'Neteisinga LPG kaina';

  @override
  String get wrongStationName => 'Neteisingas stotelės pavadinimas';

  @override
  String get wrongStationAddress => 'Neteisingas adresas';

  @override
  String get independentStation => 'Nepriklausoma stotelė';

  @override
  String get serviceRemindersSection => 'Techninės priežiūros priminimai';

  @override
  String get serviceRemindersEmpty =>
      'Dar nėra priminimų — pasirinkite išankstinį nustatymą aukščiau.';

  @override
  String get addServiceReminder => 'Pridėti priminimą';

  @override
  String get serviceReminderPresetOil => 'Alyva (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Alyvos keitimas';

  @override
  String get serviceReminderPresetTires => 'Padangos (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Padangos';

  @override
  String get serviceReminderPresetInspection => 'Apžiūra (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Apžiūra';

  @override
  String get serviceReminderLabel => 'Etiketė';

  @override
  String get serviceReminderInterval => 'Intervalas (km)';

  @override
  String get serviceReminderLastService => 'Paskutinė priežiūra';

  @override
  String get serviceReminderMarkDone => 'Pažymėti kaip atliktą';

  @override
  String get serviceReminderDueTitle => 'Laikas priežiūrai';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label laikas — $kmOver km praėjo intervalą.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Užsiregistruokite OPINET, kad gautumėte nemokamą API raktą';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Užsiregistruokite CNE, kad gautumėte nemokamą API raktą';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Ar tai jūsų automobilis?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders cilindrai, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Dalinė informacija (neprisijungus). Galite redaguoti žemiau.';

  @override
  String get vinDecodeError => 'Nepavyko iššifruoti šio VIN';

  @override
  String get vinInvalidFormat => 'Neteisingas VIN formatas';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2 ryšys prarastas — įrašymas pristabdytas';

  @override
  String get obd2PauseBannerResume => 'Tęsti įrašymą';

  @override
  String get obd2PauseBannerEnd => 'Baigti įrašymą';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Suvartojimo kalibracija atnaujinta $vehicleName — tikslumas pagerintas $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Atstatyti tūrinį efektyvumą?';

  @override
  String get veResetConfirmBody =>
      'Tai atmes išmoktą tūrinį efektyvumą (η_v) ir atkurs numatytąją reikšmę (0,85). Kelionės lygio kuro srauto įverčiai grįš prie gamintojo konstantos, kol kalibravimo priemonė surinks naujų pavyzdžių iš būsimų kelionių.';

  @override
  String get alertsRadiusSectionTitle => 'Spindulio įspėjimai';

  @override
  String get alertsRadiusAdd => 'Pridėti spindulio įspėjimą';

  @override
  String get alertsRadiusEmptyTitle => 'Dar nėra spindulio įspėjimų';

  @override
  String get alertsRadiusEmptyCta => 'Sukurti spindulio įspėjimą';

  @override
  String get alertsRadiusCreateTitle => 'Sukurti spindulio įspėjimą';

  @override
  String get alertsRadiusLabelHint => 'Etiketė (pvz. Namų dyzelis)';

  @override
  String get alertsRadiusFuelType => 'Kuro tipas';

  @override
  String get alertsRadiusThreshold => 'Riba (€/L)';

  @override
  String get alertsRadiusKm => 'Spindulys (km)';

  @override
  String get alertsRadiusCenterGps => 'Naudoti mano vietą';

  @override
  String get alertsRadiusCenterPostalCode => 'Pašto kodas';

  @override
  String get alertsRadiusSave => 'Išsaugoti';

  @override
  String get alertsRadiusCancel => 'Atšaukti';

  @override
  String get alertsRadiusDeleteConfirm => 'Ištrinti spindulio įspėjimą?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 prijungtas: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Suporuoti OBD2 adapterį';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel nukrito artimose stotelėse';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stotelių kaina nukrito iki $maxDropCents¢ per paskutinę valandą';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankavimas išsaugotas';

  @override
  String get radiusAlertsEntryTitle => 'Spindulio įspėjimai ir statistika';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Gaukite pranešimą, kai kainos nukris netoliese';

  @override
  String get notFoundTitle => 'Puslapis nerastas';

  @override
  String notFoundBody(String location) {
    return '\"$location\" nerasta.';
  }

  @override
  String get notFoundHomeButton => 'Pradžia';

  @override
  String get consumptionTabHiddenNotice =>
      'Suvartojimo skirtukas paslėptas jūsų profilio nustatymais.';

  @override
  String get swipeBetweenTabsHint =>
      'Patarimas: braukite kairėn arba dešinėn, kad perjungtumėte skirtukus.';

  @override
  String get discardChangesTitle => 'Atmesti pakeitimus?';

  @override
  String get discardChangesBody =>
      'Turite neišsaugotų pakeitimų. Išeinant dabar jie bus atmesti.';

  @override
  String get discardChangesConfirm => 'Atmesti';

  @override
  String get discardChangesKeepEditing => 'Tęsti redagavimą';

  @override
  String get tankSyncSectionSubtitle =>
      'Debesų sinchronizavimas visuose įrenginiuose';

  @override
  String get mapUnavailable => 'Žemėlapis nepasiekiamas';

  @override
  String get routeNameHintExample => 'pvz. Paryžius → Lionas';

  @override
  String get priceStatsCurrent => 'Dabartinė';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig API raktas';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap API raktas';

  @override
  String get tapToUpdateGpsPosition =>
      'Bakstelėkite, kad atnaujintumėte GPS padėtį';

  @override
  String get nameLabel => 'Pavadinimas';

  @override
  String get obd2ErrorPermissionDenied =>
      'Norint prisijungti prie OBD2 adapterio, reikia „Bluetooth“ leidimo.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Įjunkite „Bluetooth“ ir bandykite dar kartą.';

  @override
  String get obd2ErrorScanTimeout =>
      'Netoliese nerasta OBD2 adapterio. Įsitikinkite, kad jis prijungtas ir įjungtas.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2 adapteris neatsakė. Įjunkite degimą ir bandykite dar kartą.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2 adapteris išsiuntė neatpažintą atsakymą. Jis gali būti nesuderinamas — pabandykite kitą adapterį.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2 adapteris atsijungė. Prisijunkite iš naujo ir bandykite dar kartą.';

  @override
  String get onboardingExploreDemoData =>
      'Naršyti su demonstraciniais duomenimis';

  @override
  String get achievementSmoothDriver => 'Sklandaus vairavimo serija';

  @override
  String get achievementSmoothDriverDesc =>
      'Vairuokite 5 keliones iš eilės su sklandaus vairavimo balu 80 ar daugiau.';

  @override
  String get achievementColdStartAware => 'Šaltojo paleidimo sąmoningumas';

  @override
  String get achievementColdStartAwareDesc =>
      'Išlaikykite visą mėnesio šaltojo paleidimo kuro kainą žemiau 2% viso kuro — sujunkite trumpas keliones.';

  @override
  String get achievementHighwayMaster => 'Greitkelio meistras';

  @override
  String get achievementHighwayMasterDesc =>
      'Įvykdykite 30 km+ kelionę pastoviu greičiu su sklandaus vairavimo balu 90 ar daugiau.';

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
    return '$price $currency (tikslas: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel atpigo netoliese esančiose degalinėse';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count degalinės atpigo iki $cents¢ per pastarąją valandą';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count degalinės ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ dar $count';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Foninės kainų perspėjimai šiuo metu veikia tik Vokietijos degalinėms. Šis perspėjimas bus išsaugotas, bet jis gali niekada jūsų neįspėti, kol bus prieinami tarptautiniai perspėjimai.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Spindulio perspėjimai šiuo metu tikrina tik Vokietijos degalines.';

  @override
  String get approachOverlaySection => 'Užklotis artėjant prie degalinės';

  @override
  String get approachRadiusLabel => 'Spindulys';

  @override
  String approachRadiusCaption(String km) {
    return 'Užklotis padidėja ir rodo kainą, kai esate $km km atstumu nuo degalinės';
  }

  @override
  String get approachPriceModeLabel => 'Rodyti kainą';

  @override
  String get approachPriceModeNearest => 'Artimiausia degalinė';

  @override
  String get approachPriceModeCheapestInRadius => 'Pigiausia spindulyje';

  @override
  String get approachMinPollLabel => 'Min. atnaujinimas';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Artimiausios degalinės atnaujinimo apatinė riba (greičiau esant didesniam greičiui, niekada dažniau nei $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testuoti artėjimo perdangą';

  @override
  String get approachTestStopButton => 'Sustabdyti testą';

  @override
  String approachTestActiveCaption(String station) {
    return 'Testas aktyvus — perdanga rodo kainą stoteliai $station';
  }

  @override
  String get approachTestUnavailable =>
      'Pridėkite mėgstamą stotelę, kad galėtumėte testuoti artėjimo perdangą';

  @override
  String approachStationDistance(String meters) {
    return '$meters m atstumu';
  }

  @override
  String get authErrorNoNetwork => 'Nėra tinklo ryšio. Bandykite vėliau.';

  @override
  String get authErrorInvalidCredentials =>
      'Neteisingas el. paštas arba slaptažodis. Patikrinkite savo prisijungimo duomenis.';

  @override
  String get authErrorUserAlreadyExists =>
      'Šis el. paštas jau užregistruotas. Pabandykite prisijungti.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Patikrinkite savo el. paštą ir pirmiausia patvirtinkite savo paskyrą.';

  @override
  String get authErrorGeneric => 'Prisijungti nepavyko. Bandykite dar kartą.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Foninė vieta — tik automatiniam įrašymui';

  @override
  String get autoRecordConsentExplanationTitle => 'Apie šį leidimą';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatiniam įrašymui reikia foninės vietos, kad aptiktų, kai pradedas vairuoti, kol programa uždaryta. Šis leidimas naudojamas tik automatiniam įrašymui — stotelių paieška ir žemėlapio centravimas naudoja atskirą pirminės vietos leidimą.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Supratau';

  @override
  String get autoRecordConsentExplanationTooltip => 'Ką tai reiškia?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Palieskite, kad valdytumėte sistemos nustatymuose';

  @override
  String get autoRecordSectionTitle => 'Automatinis įrašymas';

  @override
  String get autoRecordToggleLabel => 'Automatiškai įrašyti keliones';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatinis įrašymas įsijungs kitą kartą, kai sėsite į automobilį.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Suporuokite OBD2 adapterį, kad įjungtumėte automatinį įrašymą.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Leiskite foninę vietą, kad automatinis įrašymas veiktų, kai ekranas išjungtas.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Suporuoti adapterį';

  @override
  String get autoRecordSpeedThresholdLabel => 'Paleidimo greitis (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Išsaugojimo delsimas po atsijungimo (sekundės)';

  @override
  String get autoRecordPairedAdapterLabel => 'Suporuotas adapteris';

  @override
  String get autoRecordPairedAdapterNone =>
      'Nėra suporuoto adapterio. Pirmiausia suporuokite per OBD2 diegimą.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Foninė vieta leista';

  @override
  String get autoRecordBackgroundLocationRequest => 'Prašyti leidimo';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Kodėl \"Visada leisti\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatinis įrašymas transliuoja GPS koordinates iš OBD-II priekinio plano paslaugos, kai ekranas išjungtas, kad jūsų kelionės maršrutas išliktų tikslus. Android reikalauja parinkties \"Visada leisti\", kad tai veiktų po įrenginio užblokavimo.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Atidaryti nustatymus';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Reikalingas vietos leidimas';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nepavyko prašyti foninės vietos';

  @override
  String get autoRecordBadgeClearTooltip => 'Išvalyti skaitiklį';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Suporuokite adapterį žemiau esančiame skyriuje, kad įjungtumėte automatinį įrašymą';

  @override
  String get exportBackupTooltip => 'Eksportuoti atsarginę kopiją';

  @override
  String get exportBackupReady =>
      'Atsarginė kopija paruošta — pasirinkite paskirties vietą';

  @override
  String get exportBackupFailed =>
      'Atsarginės kopijos eksportas nepavyko — bandykite dar kartą';

  @override
  String get brokenMapChipVerifying => 'MAP jutiklis tikrinamas…';

  @override
  String get brokenMapChipDisclaimer => 'MAP rodymai įtartini';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP jutiklis rodo neteisingai — kuro rodmenys gali būti 50–80% per maži. Išbandykite kitą adapterį.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP jutiklis nepatikimas. Rodomi tankavimo vidurkiai vietoj tiesioginės kuro normos.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP jutiklis: patikrintas ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP jutiklis: tikrinamas ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP jutiklis: įtartinas ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP jutiklis: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP jutiklis: $posterior% ± $margin% (patikrintas)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP jutiklio diagnostika';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Sugadinto MAP tikimybė: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count stebėjimai įrašyti';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Patikrinta švaru';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Šios transporto priemonės MAP jutiklis dar nestebėtas.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokuoti adapteriai';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Nėra blokuotų adapterių.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — pažymėta $percent% sugadinta';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Išvalyti';

  @override
  String get brokenMapRevPromptTitle => 'Padidinkite variklio apsukimų skaičių';

  @override
  String get brokenMapRevPromptBody =>
      'Trumpai paspauskite akceleratorių, kad programa galėtų patikrinti, ar MAP jutiklis reaguoja.';

  @override
  String get brokenMapRevPromptConfirm => 'Atlikta — padidinau apsukimų';

  @override
  String get calibrationAdvancedTitle => 'Išplėstinė kalibracija';

  @override
  String get calibrationDisplacementLabel => 'Variklio darbinis tūris (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Tūrinis efektyvumas (η_v)';

  @override
  String get calibrationAfrLabel => 'Oro ir kuro santykis (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Kuro tankis (g/L)';

  @override
  String get calibrationSourceDetected => '(aptikta iš VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalogas: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(numatytasis)';

  @override
  String get calibrationSourceManual => '(rankinis)';

  @override
  String get calibrationResetToDetected => 'Atstatyti į aptiktą reikšmę';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (sukalibruota, $samples pavyzdžiai)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (mokoma, $samples pavyzdžiai)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (numatytasis — dar nėra baigto tankavimo)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples pavyzdžių';
  }

  @override
  String get calibrationResetLearner => 'Atstatyti mokymosi algoritmą';

  @override
  String get calibrationBasisAtkinson => 'Atkinsono ciklas';

  @override
  String get calibrationBasisVnt => 'VNT dyzelis + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbokompresinis + DI';

  @override
  String get calibrationBasisTurbo => 'Turbokompresinis';

  @override
  String get calibrationBasisNaDi => 'Natūraliai įsiurbiantis + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalogas: $makeModel — $basis numatytasis)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Jūsų $makeModel pažymėtas kaip dyzelinis, bet atitinka benzininio katalogo įrašą. Palieskite, kad atnaujintumėte.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Atnaujinti';

  @override
  String get consumptionTabFuel => 'Kuras';

  @override
  String get consumptionTabCharging => 'Įkrovimas';

  @override
  String get noChargingLogsTitle => 'Dar nėra įkrovimo žurnalų';

  @override
  String get noChargingLogsSubtitle =>
      'Įveskite pirmą įkrovimo sesiją, kad pradėtumėte sekti EUR/100 km ir kWh/100 km.';

  @override
  String get addChargingLog => 'Įvesti įkrovimą';

  @override
  String get addChargingLogTitle => 'Įvesti įkrovimo sesiją';

  @override
  String get chargingKwh => 'Energija (kWh)';

  @override
  String get chargingCost => 'Bendra kaina';

  @override
  String get chargingTimeMin => 'Įkrovimo laikas (min)';

  @override
  String get chargingStationName => 'Stotelė (neprivaloma)';

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
      'Reikalingas ankstesnis žurnalas palyginimui';

  @override
  String get chargingLogButtonLabel => 'Įvesti įkrovimą';

  @override
  String get chargingCostTrendTitle => 'Įkrovimo kainos tendencija';

  @override
  String get chargingEfficiencyTitle => 'Efektyvumas (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Dar nepakanka duomenų';

  @override
  String get chargingChartsMonthAxis => 'Mėnuo';

  @override
  String get consoFeatureGroupTitle => 'Suvartojimas';

  @override
  String get consoFeatureGroupDescription =>
      'Sekite suvartojimą — rankinis tankavimas arba automatinis OBD2 kelionių įrašymas.';

  @override
  String get consoModeOff => 'Išjungta';

  @override
  String get consoModeFuel => 'Kuras';

  @override
  String get consoModeFuelAndTrips => 'Kuras + Kelionės';

  @override
  String get consoModeOffDescription =>
      'Nėra Suvartojimo skirtuko ir Suvartojimo nustatymų skyriaus.';

  @override
  String get consoModeFuelDescription =>
      'Tik rankinis tankavimas. Tinka be OBD2 adapterio.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Prideda automatinį OBD2 kelionių įrašymą. Reikalingas suporuotas adapteris.';

  @override
  String get consoSubsectionVehicles => 'Mano transporto priemonės';

  @override
  String get consoSubsectionTrajets => 'Kelionės (OBD2)';

  @override
  String get consoSubsectionToggles => 'Vairavimas';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Tikslumas: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Aukštas';

  @override
  String get consumptionAccuracyMedium => 'Vidutinis';

  @override
  String get consumptionAccuracyLow => 'Žemas';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Visiškas kalibravimas: pildymai ir per OBD2 įrašytos kelionės. L/100 km reikšmė atitinka tikrovę kelių procentų tikslumu.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Pildymai įtvirtino sąnaudų modelį, bet dar nebuvo apdorota nė viena OBD2 kelionė. Įrašykite vieną su prijungtu OBD2, kad pasiektumėte aukštą tikslumą.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Tik GPS — joks pildymas dar neįtvirtino sąnaudų modelio. Pridėkite kelis pilnus pildymus, kad pagerintumėte tikslumą.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count daliniai tankavimai laukia baigto tankavimo — neįskaičiuoti į vidurkį',
      one:
          '1 dalinis tankavimas laukia baigto tankavimo — neįskaičiuotas į vidurkį',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% kuro iš automatinių pataisymų — peržiūrėkite įrašus';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Automatinis pataisymas — palieskite, kad redaguotumėte';

  @override
  String get fillUpCorrectionEditTitle => 'Redaguoti automatinį pataisymą';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Šis įrašas buvo automatiškai sugeneruotas, kad užpildytų skirtumą tarp įrašytų kelionių ir supilto kuro. Sureguliuokite reikšmes, jei žinote tikruosius duomenis.';

  @override
  String get fillUpCorrectionDelete => 'Ištrinti pataisymą';

  @override
  String get fillUpCorrectionStation => 'Stotelės pavadinimas (neprivaloma)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Graikija)';

  @override
  String get greeceCommunityApiNotice =>
      'Veikia bendruomenės palaikomu fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumunija)';

  @override
  String get romaniaScrapingNotice =>
      'Veikia pretcarburant.ro (Konkurencijos taryba + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country stotelės $km km atstumu — €$price/L pigiau';
  }

  @override
  String get crossBorderTapToSwitch => 'Palieskite, kad perjungtumėte šalį';

  @override
  String get crossBorderDismissTooltip => 'Atmesti';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Kūrėjo įrankiai';

  @override
  String get developerToolsSubtitle =>
      'Diagnostika ir derinimo įrankiai — matomi tik kūrėjo / derinimo režimu.';

  @override
  String get developerToolsMenuSubtitle =>
      'Klaidų žurnalas, bandomieji įspėjimai, diagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Klaidų žurnalas';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Įrašyti klaidų žurnalą ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Išvalyti klaidų žurnalą';

  @override
  String get developerToolsViewErrorLog => 'Peržiūrėti klaidų žurnalą';

  @override
  String get developerToolsErrorLogEmpty => 'Klaidų pėdsakų neužregistruota.';

  @override
  String get developerToolsAlertsGroupTitle => 'Įspėjimai ir pranešimai';

  @override
  String get developerToolsFireTestNotification => 'Siųsti bandomąjį pranešimą';

  @override
  String get developerToolsTestNotificationTitle => 'Bandomasis pranešimas';

  @override
  String get developerToolsTestNotificationBody =>
      'Jei tai skaitote, pranešimai veikia.';

  @override
  String get developerToolsTestNotificationSent =>
      'Bandomasis pranešimas išsiųstas.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Pranešimai užblokuoti — įjunkite juos sistemos nustatymuose ir bandykite dar kartą.';

  @override
  String get developerToolsRunTestAlert => 'Vykdyti bandomąją įspėjimų giją';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Bandomasis įspėjimas suaktyvintas — gija pristatė $count pranešimų.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Bandomasis kainos įspėjimas';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Sintetinis atitikmuo: netoliese rasta stotelė, mažesnė už jūsų tikslą.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostika';

  @override
  String get developerToolsFeatureFlagDump =>
      'Funkcijų vėliavėlių inspektorius';

  @override
  String get developerToolsFlagOn => 'Įjungta';

  @override
  String get developerToolsFlagOff => 'Išjungta';

  @override
  String get developerToolsClearCaches => 'Išvalyti talpyklas';

  @override
  String get developerToolsCachesCleared => 'Talpyklos išvalytos.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopijuoti diagnostiką';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostika nukopijuota į iškarpinę.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Versijos informacija';

  @override
  String get developerToolsBuildVersion => 'Programos versija';

  @override
  String get developerToolsBuildChannel => 'Versijos kanalas';

  @override
  String get insightCardTitle => 'Didžiausias kuro švaistymas';

  @override
  String get insightEmptyState => 'Nėra pastebimų neefektyvumų — taip toliau!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Variklis virš 3000 RPM ($pctTime% kelionės): švaisyta $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count staigūs greitinimai: švaisyta $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Tuščioji eiga ($pctTime% kelionės): švaisyta $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% kelionės';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Važiavimas žemoje pavaros ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Ilgų sustojimų metu išjunkite variklį, užuot palikę jį veikti tuščiąja eiga.';

  @override
  String get lessonAdviceHighRpm =>
      'Anksčiau perjunkite aukštesnę pavarą, kad variklis liktų ne aukštų apsukų zonoje.';

  @override
  String get lessonAdviceHardAccel =>
      'Spauskite akceleratorių tolygiai — sklandus įsibėgėjimas naudoja mažiau degalų.';

  @override
  String get lessonAdviceLowGear =>
      'Perjunkite aukštesnę pavarą anksčiau, kad variklis suktųsi mažesnėmis ir ekonomiškesnėmis apsukomis.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Ilgalaikis didelis greitis ($pctTime% kelionės): iššvaistyta $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Ilgalaikis didelis greitis ($pctTime% kelionės)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Viršijus 110 km/h atleiskite akceleratorių – oro pasipriešinimas smarkiai auga, šiek tiek lėčiau sutaupysite daug kuro.';

  @override
  String get lessonSmoothDrivingTitle => 'Tolygus vairavimas – puiku!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Šioje kelionėje nebuvo staigaus greitėjimo ar stabdymo – tolygus vairavimas išlaiko mažas sąnaudas.';

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
  String get drivingScoreCardTitle => 'Vairavimo balas';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Sudėtinis balas iš tuščiosios eigos, staigių greitinimų, staigaus stabdymo ir laiko su dideliais apsukimais. Lyginimas \"geriau nei X% ankstesnių kelionių\" bus įtrauktas vėlesnėje versijoje.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Vairavimo balas $score iš 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Tuščioji eiga';

  @override
  String get drivingScorePenaltyHardAccel => 'Staigūs greitinimai';

  @override
  String get drivingScorePenaltyHardBrake => 'Staigus stabdymas';

  @override
  String get drivingScorePenaltyHighRpm => 'Dideli apsukimai';

  @override
  String get drivingScorePenaltyFullThrottle => 'Pilnas akseleratorius';

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
  String get ecoRouteOption => 'Eko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L sutaupyta';
  }

  @override
  String get ecoRouteHint =>
      'Protingesnis maršrutas — teikia pirmenybę tolygiam greitkeliui prieš vingiuotus kelius.';

  @override
  String get favoritesShareAction => 'Bendrinti';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — mėgstami $date';
  }

  @override
  String get favoritesShareError => 'Nepavyko sugeneruoti bendrinimo vaizdo';

  @override
  String get featureManagementSectionTitle => 'Funkcijų valdymas';

  @override
  String get featureManagementSectionSubtitle =>
      'Įjunkite arba išjunkite atskiras funkcijas. Kai kurios funkcijos priklauso nuo kitų — jungikliai išjungiami, kol neįvykdytos sąlygos.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2 kelionių įrašymas';

  @override
  String get featureDescription_obd2TripRecording =>
      'Automatiškai fiksuoti keliones per OBD2.';

  @override
  String get featureLabel_gamification => 'Žaidybinimas';

  @override
  String get featureDescription_gamification =>
      'Vairavimo balai ir uždirbti ženkleliai.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptinis eko treneris';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Realaus laiko haptinis grįžtamasis ryšys kelionės metu.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sinchronizavimas tarp įrenginių per Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Suvartojimo analizė';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Tankavimų ir kelionių analizės skirtukas.';

  @override
  String get featureLabel_baselineSync => 'Bazių sinchronizavimas';

  @override
  String get featureDescription_baselineSync =>
      'Sinchronizuoti vairavimo bazes per TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Suvienodyti paieškos rezultatai';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Vienas rezultatų sąrašas, jungiantis degalines ir EV stotelės.';

  @override
  String get featureLabel_priceAlerts => 'Kainų įspėjimai';

  @override
  String get featureDescription_priceAlerts =>
      'Pranešimai apie kainos kritimą pagal ribą.';

  @override
  String get featureLabel_priceHistory => 'Kainų istorija';

  @override
  String get featureDescription_priceHistory =>
      '30 dienų kainų grafikai stotelės detalėse.';

  @override
  String get featureLabel_routePlanning => 'Maršruto planavimas';

  @override
  String get featureDescription_routePlanning =>
      'Pigiausias sustojimas jūsų maršrute.';

  @override
  String get featureLabel_evCharging => 'EV įkrovimas';

  @override
  String get featureDescription_evCharging =>
      'Įkrovimo stotelės per OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Slydimo treneris';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling gairės naudojant OSM eismo signalus.';

  @override
  String get featureLabel_gpsTripPath => 'GPS kelionės maršrutas';

  @override
  String get featureDescription_gpsTripPath =>
      'Išsaugoti GPS kelio pavyzdžius kartu su kiekviena kelione.';

  @override
  String get featureLabel_autoRecord => 'Automatinis įrašymas';

  @override
  String get featureDescription_autoRecord =>
      'Automatiškai pradėti kelionę, kai OBD2 adapteris prisijungia prie judančios transporto priemonės.';

  @override
  String get featureLabel_showFuel => 'Rodyti degalines';

  @override
  String get featureDescription_showFuel =>
      'Rodyti benzino/dyzelio stotelių rezultatus paieškoje ir žemėlapyje.';

  @override
  String get featureLabel_showElectric => 'Rodyti įkrovimo stoteles';

  @override
  String get featureDescription_showElectric =>
      'Rodyti EV įkrovimo stoteles paieškoje ir žemėlapyje.';

  @override
  String get featureLabel_showConsumptionTab => 'Suvartojimo skirtukas';

  @override
  String get featureDescription_showConsumptionTab =>
      'Rodyti suvartojimo analizės skirtuką apatinėje naršymo juostoje.';

  @override
  String get featureBlockedEnable_gamification =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureBlockedEnable_baselineSync =>
      'Pirmiausia įjunkite TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureBlockedEnable_showFuel => 'Sąlygos neįvykdytos';

  @override
  String get featureBlockedEnable_showElectric => 'Sąlygos neįvykdytos';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite kainų prognozavimas';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Įrenginyje esantis kainų prognozavimo modelis — išvados vykdomos vietiškai; funkcijos ir prognozės nepalieka įrenginio.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Pirmiausia įjunkite kainų istoriją';

  @override
  String get featureLabel_fuelCalculator => 'Kuro skaičiuoklė';

  @override
  String get featureDescription_fuelCalculator =>
      'Pasiekiamų kuro išlaidų skaičiuoklė iš paieškos rezultatų.';

  @override
  String get featureLabel_carbonDashboard => 'CO2 prietaisų skydelis';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2 pėdsako prietaisų skydelis pasiekiamas iš Suvartojimo skirtuko.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentiniai OEM PID';

  @override
  String get featureDescription_experimentalOemPids =>
      'Nuskaityti tikslų bako kiekį litrais per gamintojo specifinius PID palaikomuose adapteriuose.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Pirmiausia įjunkite OBD2 kelionių įrašymą';

  @override
  String get featureLabel_paymentQrScan => 'Nuskaityti mokėjimo QR';

  @override
  String get featureDescription_paymentQrScan =>
      'QR nuskaitymo mokėjimui skaitytuvas stotelės detalių ekrane.';

  @override
  String get featureLabel_communityPriceReports =>
      'Bendruomenės kainų pranešimai';

  @override
  String get featureDescription_communityPriceReports =>
      'Pranešti apie stotelės kainą iš stotelės detalių ekrano.';

  @override
  String get featureLabel_obd2Optional => 'Reikalauti OBD2 kelionių įrašymui';

  @override
  String get featureDescription_obd2Optional =>
      'Kai išjungta, programa įrašo keliones tik su GPS be OBD2 adapterio. Vairavimo patarimai sumažėjo — nėra momentinio L/100 km, mažiau variklio signalų.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Kvito OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Nuskaitykite atspausdintą kvitą Pridėti pildymą ekrane, kad iš anksto užpildytumėte datą, litrus, sumą ir stotį.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'Siurblio ekrano OCR (eksperimentinis)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Nuskaitykite degalų siurblio ekraną, kad iš anksto užpildytumėte formą. Atpažinimas šiandien nepatikimas — įjunkite tik jei norite išbandyti.';

  @override
  String get featureLabel_developerPatToken =>
      'Kūrėjo atsiliepimai (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Įjungia nepavykusio nuskaitymo atsiliepimų skydelį, kuris su Personal Access Token automatiškai sukuria GitHub problemas. Pažangių vartotojų / talkininkų funkcija.';

  @override
  String get featureLabel_debugMode => 'Kūrėjo / derinimo režimas';

  @override
  String get featureDescription_debugMode =>
      'Nustatymuose parodo skiltį Kūrėjo įrankiai su diagnostika: klaidų žurnalo eksportas, bandomieji pranešimai, bandomosios įspėjimų gijos vykdymas, funkcijų vėliavėlių sąrašas, talpyklų išvalymas ir diagnostikos kopijavimas.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get feedbackConsentTitle => 'Siųsti ataskaitą į GitHub?';

  @override
  String get feedbackConsentBody =>
      'Tai sukurs viešą bilietą mūsų GitHub saugykloje su jūsų nuotrauka ir OCR tekstu. Asmeniniai duomenys (vieta, paskyros ID) neišsiunčiami. Tęsti?';

  @override
  String get feedbackConsentContinue => 'Tęsti';

  @override
  String get feedbackConsentCancel => 'Atšaukti';

  @override
  String get feedbackConsentLater => 'Vėliau';

  @override
  String get feedbackTokenSectionTitle =>
      'Blogų nuskaitymų grįžtamasis ryšys (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Norėdami automatiškai atidaryti GitHub bilietą dėl nepavykusio nuskaitymo, įklijuokite GitHub PAT (`public_repo` apimtis tankstellen saugyklai). Priešingu atveju rankinis bendrinimas lieka prieinamas.';

  @override
  String get feedbackTokenStatusSet => 'Prieigos raktas sukonfigūruotas';

  @override
  String get feedbackTokenStatusUnset => 'Nėra prieigos rakto';

  @override
  String get feedbackTokenSet => 'Nustatyti';

  @override
  String get feedbackTokenClear => 'Išvalyti';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Asmeninis prieigos raktas';

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
  String get fillUpReconciliationVerifiedBadgeLabel => 'Patvirtinta adapteriu';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Nesutampa su adapterio rodymu';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Jūsų įrašas: $userL L. Adapteris rodo: $adapterL L (skirtumas iš prieš/po kuro lygio fiksavimo). Naudoti adapterio reikšmę?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Palikti mano įrašą';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Naudoti adapterio reikšmę';

  @override
  String get scanReceiptNoData => 'Kvito duomenų nerasta — bandykite dar kartą';

  @override
  String get scanReceiptSuccess =>
      'Kvitas nuskaitytas — patikrinkite reikšmes. Palieskite \"Pranešti apie nuskaitymo klaidą\" žemiau, jei kas nors negerai.';

  @override
  String scanReceiptFailed(String error) {
    return 'Nuskaitymas nepavyko: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Siurblio ekranas neįskaitomas — bandykite dar kartą';

  @override
  String get scanPumpSuccess =>
      'Siurblio ekranas nuskaitytas — patikrinkite reikšmes.';

  @override
  String get scanPumpGlare =>
      'Per daug atspindžių ekrane — bandykite dar kartą šiek tiek kampu, kad skaičiai nebūtų peršviesti.';

  @override
  String scanPumpFailed(String error) {
    return 'Siurblio nuskaitymas nepavyko: $error';
  }

  @override
  String get badScanReportTitle => 'Pranešti apie nuskaitymo klaidą';

  @override
  String get badScanReportTitleReceipt =>
      'Pranešti apie nuskaitymo klaidą — Kvitas';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Pranešti apie nuskaitymo klaidą — Siurblio ekranas';

  @override
  String get pumpScanFailureTitle => 'Ekranas neįskaitomas';

  @override
  String get pumpScanFailureBody =>
      'Nuskaitymu nepavyko nuskaityti siurblio ekrano. Ką norėtumėte daryti?';

  @override
  String get pumpScanFailureCorrectManually => 'Taisyti rankiniu būdu';

  @override
  String get pumpScanFailureReport => 'Pranešti';

  @override
  String get pumpScanFailureRemove => 'Pašalinti nuotrauką';

  @override
  String get badScanReportHint =>
      'Bendrinsime kvito nuotrauką ir abi reikšmių rinkinius, kad kitas versijos variantas galėtų išmokti šį išdėstymą.';

  @override
  String get badScanReportShareAction => 'Bendrinti ataskaitą + nuotrauką';

  @override
  String get badScanReportFieldBrandLayout => 'Prekinio ženklo išdėstymas';

  @override
  String get badScanReportFieldTotal => 'Iš viso';

  @override
  String get badScanReportFieldPricePerLiter => 'Kaina/L';

  @override
  String get badScanReportFieldStation => 'Stotelė';

  @override
  String get badScanReportFieldFuel => 'Kuras';

  @override
  String get badScanReportFieldDate => 'Data';

  @override
  String get badScanReportHeaderField => 'Laukas';

  @override
  String get badScanReportHeaderScanned => 'Nuskaityta';

  @override
  String get badScanReportHeaderYouTyped => 'Jūs įvedėte';

  @override
  String get badScanReportCreateTicket => 'Sukurti problemą';

  @override
  String get badScanReportOpenInBrowser => 'Atidaryti naršyklėje';

  @override
  String get badScanReportFallbackToShare =>
      'Pateikimas nepavyko — rankinis bendrinimas';

  @override
  String get pumpCameraHint =>
      'Sulygiuokite tris degalinės ekrano skaičius rėmelyje';

  @override
  String get pumpCameraCapture => 'Fotografuoti';

  @override
  String get pumpCameraPermissionDenied =>
      'Norint nuskaityti degalinės ekraną, reikia prieigos prie kameros. Įjunkite ją įrenginio nustatymuose.';

  @override
  String get pumpCameraError =>
      'Nepavyko paleisti kameros. Bandykite dar kartą arba įveskite reikšmes rankiniu būdu.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Perjungti į horizontalų išdėstymą';

  @override
  String get pumpCameraOrientationVertical => 'Perjungti į vertikalų išdėstymą';

  @override
  String get pumpCameraGlareWarning =>
      'Per daug atspindžių — šiek tiek pakreipkite, kad išvengtumėte atspindžių';

  @override
  String get pumpCameraAlignHint =>
      'Sulygiuokite ekraną rėme ir tada fotografuokite';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Ką pildėte';

  @override
  String get fillUpSectionWhatSubtitle => 'Kuras, kiekis, kaina';

  @override
  String get fillUpSectionWhereTitle => 'Kur buvote';

  @override
  String get fillUpSectionWhereSubtitle => 'Stotelė, odometras, pastabos';

  @override
  String get fillUpImportFromLabel => 'Importuoti iš…';

  @override
  String get fillUpImportSheetTitle => 'Importuoti tankavimo duomenis';

  @override
  String get fillUpImportReceiptLabel => 'Kvitas';

  @override
  String get fillUpImportReceiptDescription =>
      'Nuskaitykite popieriaus kvitą su kamera';

  @override
  String get fillUpImportPumpLabel => 'Siurblio ekranas';

  @override
  String get fillUpImportPumpDescription =>
      'Nuskaityti sumą / kainą iš siurblio LCD';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapteris';

  @override
  String get fillUpImportObdDescription =>
      'Nuskaityti odometrą iš OBD-II prievado per Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Kaina už litrą';

  @override
  String get vehicleHeaderPlateLabel => 'Numeriai';

  @override
  String get vehicleHeaderUntitled => 'Nauja transporto priemonė';

  @override
  String get vehicleSectionIdentityTitle => 'Tapatybė';

  @override
  String get vehicleSectionIdentitySubtitle => 'Pavadinimas ir VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Pavara';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Kaip juda ši transporto priemonė';

  @override
  String get calibrationModeLabel => 'Kalibravimo režimas';

  @override
  String get calibrationModeRule => 'Taisyklėmis pagrįstas';

  @override
  String get calibrationModeFuzzy => 'Neapibrėžtas';

  @override
  String get calibrationModeTooltip =>
      'Taisyklėmis pagrįstas kiekvieną vairavimo pavyzdį priskiria lygiai vienai situacijai. Neapibrėžtas paskirsto jį po visas pagal tai, kiek kiekviena tinka — sklandžiau ties 60 km/h ar kintančiais nuolydžiais, bet lėčiau užpildo visus segmentus.';

  @override
  String get profileGamificationToggleTitle => 'Rodyti pasiekimus ir balus';

  @override
  String get profileGamificationToggleSubtitle =>
      'Kai išjungta, ženkleliai, balai ir trofėjaus piktogramos slepiamos visoje programoje.';

  @override
  String get coachingGpsLiftOff => 'Atleisk dujas';

  @override
  String get coachingGpsAnticipateBrake => 'Numatyk';

  @override
  String get coachingGpsSmoothAccel => 'Sklandus greitėjimas';

  @override
  String get gpsDiagnosticsTitle => 'GPS mėginių diagnostika';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps spragos',
      one: '1 spraga',
      zero: 'nėra spragų',
    );
    return '$count mėginiai · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Medianinis intervalas: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Fiksuota įrašymo metu, siekiant patikrinti GPS ritmiką telefono miego režimo metu.';

  @override
  String get gpsMatrixMaturityCold => 'Šalta';

  @override
  String get gpsMatrixMaturityWarming => 'Šyla';

  @override
  String get gpsMatrixMaturityConverged => 'Suderinta';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS matrica vis dar šyla ($count patikslinimai iki šiol). Įverčiai yra laikini.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS matrica derinasi ($count pildymai). Įverčiai naudotini, gali skirtis keliais %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS matrica suderinta ($count pildymai). Įverčiai ~2 % ribose faktinio sąnaudų.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Vairavimas';

  @override
  String get hapticEcoCoachSettingTitle => 'Realaus laiko eko mokymas';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Švelnus haptikas ir ekrane rodomas patarimas, kai pilnai spaudžiate pedalą kruizinio valdymo metu';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Atsargiau su akseleratoriumi — inercinė eiga taupo daugiau';

  @override
  String semanticsNavigateTo(String name) {
    return 'Nuvykti į $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Pašalinti $name iš parankinių';
  }

  @override
  String get showOnMapSemanticLabel => 'Rodyti stoteles žemėlapyje';

  @override
  String get searchResultsSemanticLabel => 'Paieškos rezultatai';

  @override
  String get searchCriteriaSemanticLabel =>
      'Paieškos kriterijų santrauka. Bakstelėkite norėdami redaguoti.';

  @override
  String get noFavoritesSemanticLabel =>
      'Parankinių dar nėra. Bakstelėkite stotelės žvaigždutę, kad išsaugotumėte ją kaip parankinę.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stotelė atidaryta',
      'false': 'Stotelė uždaryta',
      'other': 'Stotelė uždaryta',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Šalis $name, pasirinkta',
      'false': 'Šalis $name',
      'other': 'Šalis $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Kalba $name, pasirinkta',
      'false': 'Kalba $name',
      'other': 'Kalba $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Rūšiuoti pagal $option, pasirinkta',
      'false': 'Rūšiuoti pagal $option',
      'other': 'Rūšiuoti pagal $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Kuras $type, pasirinktas',
      'false': 'Kuras $type',
      'other': 'Kuras $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Įkrovimo stotelė $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Privatumo skydas su kuro lašu';

  @override
  String get globeIllustrationSemantic => 'Gaublys su degalinių žymekliais';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Degalų kolonėlė su kainų rodikliu';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, duomenų šaltinis: $provider, $keyRequirement, kuro tipai: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Reikalingas API raktas';

  @override
  String get countryInfoNoKeyNeeded => 'Nemokama, rakto nereikia';

  @override
  String countryInfoDataSource(String provider) {
    return 'Duomenys: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Kuro tipai: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anoniminis raktas';

  @override
  String get anonKeyHideTooltip => 'Slėpti raktą';

  @override
  String get anonKeyShowTooltip => 'Rodyti raktą patikrinimui';

  @override
  String anonKeyTooLong(int length) {
    return 'Raktas per ilgas ($length simboliai) — patikrinkite, ar nėra papildomo teksto';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Raktas atrodo teisingas ($length simboliai)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Raktas turėtų būti JWT (antraštė.naudingoji apkrova.parašas)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Raktas gali būti sutrumpintas ($length iš ~208 laukiamų simbolių)';
  }

  @override
  String get anonKeyExceedsMax => 'Raktas viršija maksimalų ilgį';

  @override
  String get qrShareTitle => 'Bendrinti savo duomenų bazę';

  @override
  String get qrShareSubtitle =>
      'Kiti gali nuskaityti šį QR kodą, kad prisijungtų';

  @override
  String get qrShareCopyAsText => 'Kopijuoti kaip tekstą';

  @override
  String get authInfoTitle => 'Kodėl sukurti paskyrą?';

  @override
  String get authInfoBenefit1 =>
      '• Sinchronizuokite mėgstamus, įspėjimus ir išsaugotus maršrutus visuose įrenginiuose';

  @override
  String get authInfoBenefit2 =>
      '• Paruoškite maršrutą telefone, naudokite automobilyje';

  @override
  String get authInfoBenefit3 =>
      '• Duomenys nebendrinsimi su trečiosiomis šalimis';

  @override
  String get authInfoBenefit4 => '• Galite bet kada ištrinti savo paskyrą';

  @override
  String get privacyLocalDataEmpty =>
      'Dar nieko nesaugoma. Pridėkite mėgstamą arba nustatykite kainų įspėjimą, kad matytumėte įrašus čia.';

  @override
  String get privacyHideEmptyRows => 'Slėpti tuščias eilutes';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rodyti $count tuščias eilutes',
      one: 'Rodyti $count tuščią eilutę',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API rakto sąranka (neprivaloma)';

  @override
  String get apiKeySetupDescription =>
      'Užsiregistruokite nemokamai gauti API raktą arba praleiskite ir tyrinėkite programą su demonstraciniais duomenimis.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider registracija';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Įvesdami API raktą sutinkate su $provider sąlygomis. Duomenų perskirstymas draudžiamas.';
  }

  @override
  String get calculatorDistanceHint => 'pvz. 150';

  @override
  String get calculatorConsumptionHint => 'pvz. 7,0';

  @override
  String get calculatorPriceHint => 'pvz. 1,899';

  @override
  String get routeStrategyLabel => 'Strategija:';

  @override
  String get routeStrategyUniform => 'Vienoda';

  @override
  String get routeStrategyBalanced => 'Subalansuota';

  @override
  String get glideCoachBetaTitle =>
      'Slydimo trenerio beta versija (eksperimentinė)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtilus haptikas lėtėjant prieš raudoną šviesą. Numatytai išjungtas — blaškymosi pavojus.';

  @override
  String get consentSyncTripsTitle => 'Sinchronizuoti kelionių įrašus';

  @override
  String get consentSyncTripsSubtitle =>
      'Kurti atsargines OBD2 + GPS kelionių kopijas TankSync. Tarpįrengininis, pasirenkamas.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Įjunkite debesų sinchronizavimą aukščiau, kad kurti atsargines kelionių kopijas.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Prisijunkite naudodami el. pašto paskyrą, kad sinchronizuotumėte keliones tarp įrenginių.';

  @override
  String get consentHideDetails => 'Slėpti detales';

  @override
  String get consentShowDetails => 'Rodyti detales';

  @override
  String get dialogOk => 'Gerai';

  @override
  String get invalidLinkTitle => 'Neteisingas nuoroda';

  @override
  String invalidLinkBody(String path) {
    return 'Nuoroda \"$path\" neteisinga.';
  }

  @override
  String get home => 'Pradžia';

  @override
  String get locationConsentTitle => 'Vietos prieiga';

  @override
  String get locationConsentSubtitle =>
      'Ši programa nori naudoti jūsų vietą, kad rastų netoliese esančias degalines.';

  @override
  String get locationConsentWhatHappens =>
      'Kas vyksta su jūsų vietos duomenimis:';

  @override
  String get locationConsentBulletApi =>
      'Jūsų koordinatės siunčiamos į degalų kainų API, kad būtų rastos netoliese esančios degalinės.';

  @override
  String get locationConsentBulletNoServer =>
      'Jūsų vieta nesaugoma jokiame serveryje — serverio nėra.';

  @override
  String get locationConsentBulletNoTracking =>
      'Vietos duomenys nenaudojami reklamai, analitikai ar sekimui.';

  @override
  String get locationConsentRevoke =>
      'Vietos prieigą galite bet kada atšaukti sistemos nustatymuose. Taip pat galite ieškoti pagal pašto kodą.';

  @override
  String get locationConsentLegalBasis =>
      'Teisinis pagrindas: BDAR 6 str. 1 d. a punktas (sutikimas)';

  @override
  String get locationConsentDecline => 'Atmesti';

  @override
  String get locationConsentAccept => 'Sutikti';

  @override
  String get loyaltySettingsTitle => 'Degalų klubo kortelės';

  @override
  String get loyaltySettingsSubtitle =>
      'Taikykite lojalumo nuolaidą rodomoms kainoms';

  @override
  String get loyaltyMenuTitle => 'Degalų klubo kortelės';

  @override
  String get loyaltyMenuSubtitle =>
      'Taikykite nuolaidas litrui iš Total, Aral, Shell ir kt.';

  @override
  String get loyaltyAddCard => 'Pridėti kortelę';

  @override
  String get loyaltyAddCardSheetTitle => 'Pridėti degalų klubo kortelę';

  @override
  String get loyaltyBrandLabel => 'Prekinis ženklas';

  @override
  String get loyaltyCardLabelLabel => 'Etiketė (neprivaloma)';

  @override
  String get loyaltyDiscountLabel => 'Nuolaida (už litrą)';

  @override
  String get loyaltyDiscountInvalid => 'Įveskite teigiamą skaičių';

  @override
  String get loyaltyDeleteConfirmTitle => 'Ištrinti kortelę?';

  @override
  String get loyaltyDeleteConfirmBody => 'Ši kortelė nustos taikyti nuolaidą.';

  @override
  String get loyaltyEmptyTitle => 'Dar nėra degalų klubo kortelių';

  @override
  String get loyaltyEmptyBody =>
      'Pridėkite kortelę, kad nuolaida litrui būtų taikoma atitinkamoms stotelėms automatiškai.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Aptiktas tuščiosios eigos apsukimų didėjimas';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Tuščiosios eigos apsukimai padidėjo $percent% per paskutines $tripCount keliones. Galimas ankstyvas oro filtro užsikimšimo ar jutiklio dreifo požymis.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Galimas įsiurbimo apribojimas';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Kruizinio vairavimo kuro norma sumažėjo $percent% per paskutines $tripCount keliones. Galimas oro filtro užsikimšimo ar apriboto įsiurbimo požymis — verta patikrinti.';
  }

  @override
  String get maintenanceActionDismiss => 'Atmesti';

  @override
  String get maintenanceActionSnooze => 'Priminti po 30 dienų';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Šis mėnuo palyginti su praėjusiu';

  @override
  String get consumptionMonthlyTripsLabel => 'Kelionės';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Vairavimo laikas';

  @override
  String get consumptionMonthlyDistanceLabel => 'Atstumas';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Vid. suvartojimas';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Palyginimui reikia bent 3 kelionių per mėnesį';

  @override
  String get obd2CapabilitySectionTitle => 'Adapterio galimybės';

  @override
  String get obd2CapabilityStandardOnly => 'Standartinis';

  @override
  String get obd2CapabilityOemPids => 'OEM PID';

  @override
  String get obd2CapabilityFullCan => 'Pilnas CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Norint tiksliai matyti baką litrais Peugeot/Citroën, programa palaiko OBDLink MX+/LX/CX (STN lustas).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2 diagnostikos perdanga įjungta';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 diagnostikos perdanga išjungta';

  @override
  String get obd2DebugOverlayClearButton => 'Išvalyti';

  @override
  String get obd2DebugOverlayCloseButton => 'Uždaryti';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 sekos žurnalai';

  @override
  String get obd2DiagnosticShareLabel => 'Bendrinti diagnostikos žurnalą';

  @override
  String get obd2DebugLoggingTitle => 'OBD2 derinimo žurnalas';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Įrašykite kiekvieną OBD2 seansą — prisijungimą, rankų paspaudimą, duomenų spragas ir pakartotinius prisijungimus — į eksportuojamą XML žurnalą. Pagal numatytuosius nustatymus išjungta.';

  @override
  String get obd2DebugSessionShareLabel => 'Bendrinti OBD2 seanso žurnalą';

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
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nepavyko pasiekti \"$adapterName\" — pasirinkite kitą adapterį';
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
  String get onboardingObd2StepTitle => 'Prijunkite savo OBD2 adapterį';

  @override
  String get onboardingObd2StepBody =>
      'Įkiškite OBD2 adapterį į automobilio lizdą ir įjunkite uždegimą. Nuskaitysime VIN ir užpildysime variklio detales už jus.';

  @override
  String get onboardingObd2ConnectButton => 'Prijungti adapterį';

  @override
  String get onboardingObd2SkipButton => 'Gal vėliau';

  @override
  String get onboardingObd2ReadingVin => 'Nuskaitomas VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Nepavyko nuskaityti VIN — įveskite rankiniu būdu';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nepavyko prisijungti prie adapterio. Galite bandyti dar kartą arba praleisti.';

  @override
  String get onboardingPickUseMode =>
      'Norėdami tęsti, pasirinkite naudojimo režimą.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'praėjo';

  @override
  String get alertsRadiusFrequencyLabel => 'Patikrinimo dažnis';

  @override
  String get alertsRadiusFrequencyDaily => 'Kartą per dieną';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Du kartus per dieną';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tris kartus per dieną';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Keturis kartus per dieną';

  @override
  String get radiusAlertPickOnMap => 'Pasirinkti žemėlapyje';

  @override
  String get radiusAlertMapPickerTitle => 'Pasirinkite įspėjimo centrą';

  @override
  String get radiusAlertMapPickerConfirm => 'Patvirtinti';

  @override
  String get radiusAlertMapPickerCancel => 'Atšaukti';

  @override
  String get radiusAlertMapPickerHint =>
      'Vilkite žemėlapį, kad nustatytumėte įspėjimo centrą';

  @override
  String get radiusAlertCenterFromMap => 'Žemėlapio vieta';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel prie $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Stotelė kainuoja $price € (tikslas: $threshold €)';
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
  String get refuelUnitPerSession => '/sesija';

  @override
  String get speedConsumptionCardTitle => 'Suvartojimas pagal greitį';

  @override
  String get speedBandIdleJam => 'Tuščioji / spūstis';

  @override
  String get speedBandUrban => 'Miestas (10–50)';

  @override
  String get speedBandSuburban => 'Priemiestis (50–80)';

  @override
  String get speedBandRural => 'Kaimas (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eko kruizas (100–115)';

  @override
  String get speedBandMotorway => 'Greitkelis (115–130)';

  @override
  String get speedBandMotorwayFast => 'Greitkelis greitas (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Įrašykite 30+ minučių kelionių su OBD2 adapteriu, kad atrakintumėte greičio/suvartojimo analizę.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % vairavimo';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Reikia daugiau duomenų';

  @override
  String get splashLoadingLabel => 'Kraunamas Sparkilo';

  @override
  String get storageRecoveryTitle => 'Saugyklos problema';

  @override
  String get storageRecoveryMessage =>
      '„Sparkilo“ nepavyko atidaryti vietinės duomenų saugyklos. Atrodo, kad saugyklos failas pažeistas.';

  @override
  String get storageRecoveryGuidance =>
      'Norėdami atkurti, įrenginio nustatymuose išvalykite programos saugyklą arba iš naujo įdiekite programą. Jūsų mėgstamiausi ir istorija saugomi tik šiame įrenginyje, todėl jų negalima atkurti automatiškai.';

  @override
  String get tankLevelTitle => 'Bako lygis';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km rida';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Paskutinis tankavimas: $date · $count kelionė(s) nuo tada';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 matuojamas';

  @override
  String get tankLevelMethodDistanceFallback => 'atstumo pagrįstas įvertis';

  @override
  String get tankLevelMethodMixed => 'mišrus matavimas';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Įveskite tankavimą, kad matytumėte bako lygį';

  @override
  String get tankLevelDetailSheetTitle => 'Kelionės nuo paskutinio tankavimo';

  @override
  String get addFillUpIsFullTankLabel => 'Pilnas bakas';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Bakas užpildytas iki kraštų — atžymėkite, jei tai buvo dalinis tankavimas';

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'Sistema';

  @override
  String get themeCardSubtitleLight => 'Šviesi';

  @override
  String get themeCardSubtitleDark => 'Tamsi';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Pagal sistemą';

  @override
  String get themeSettingsLightLabel => 'Šviesi';

  @override
  String get themeSettingsDarkLabel => 'Tamsi';

  @override
  String get themeSettingsSystemDescription =>
      'Atitikti dabartinę įrenginio išvaizdą.';

  @override
  String get themeSettingsLightDescription =>
      'Šviesūs fonai — geriausiai dieną.';

  @override
  String get themeSettingsDarkDescription =>
      'Tamsūs fonai — mažiau vargina akis naktį ir taupo bateriją OLED ekranuose.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Programos firminė žalia išvaizda — ryški ir lengvai skaitoma, su švelniai žaliai atspalvintais fonais.';

  @override
  String get throttleRpmHistogramTitle => 'Kaip naudojote variklį';

  @override
  String get throttleRpmHistogramThrottleSection => 'Akseleratoriaus padėtis';

  @override
  String get throttleRpmHistogramRpmSection => 'Variklio apsukimai';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Inercinė eiga (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Lengva (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Vidutinė (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Visu pedimu (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Tuščioji eiga (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Kruizas (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Sportinis (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Kietai (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Šioje kelionėje nėra akseleratoriaus ar apsukimų mėginių.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Kelionės';

  @override
  String get trajetsStartRecordingButton => 'Pradėti įrašymą';

  @override
  String get trajetsResumeRecordingButton => 'Tęsti įrašymą';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Jungiamasi prie OBD2 adapterio…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Skaitomi transporto priemonės duomenys…';

  @override
  String get tripStartProgressStartingRecording => 'Pradedamas įrašymas…';

  @override
  String get trajetsEmptyStateTitle => 'Dar nėra kelionių';

  @override
  String get trajetsEmptyStateBody =>
      'Palieskite Pradėti įrašymą, kad pradėtumėte fiksuoti savo reisus.';

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
  String get trajetDetailSummaryTitle => 'Santrauka';

  @override
  String get trajetDetailFieldDate => 'Data';

  @override
  String get trajetDetailFieldVehicle => 'Transporto priemonė';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adapteris';

  @override
  String get trajetDetailFieldDistance => 'Atstumas';

  @override
  String get trajetDetailFieldDuration => 'Trukmė';

  @override
  String get trajetDetailFieldAvgConsumption => 'Vid. suvartojimas';

  @override
  String get trajetDetailFieldFuelUsed => 'Sunaudotas kuras';

  @override
  String get trajetDetailFieldFuelCost => 'Kuro kaina';

  @override
  String get trajetDetailFieldAvgSpeed => 'Vid. greitis';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maks. greitis';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Greitis (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Kuro norma (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Variklio apkrova (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Diagramos';

  @override
  String get trajetsRowColdStartChip => 'Šaltasis paleidimas';

  @override
  String get trajetsRowColdStartTooltip =>
      'Variklis nepasiekė darbinės temperatūros šios kelionės metu — kuro suvartojimas buvo didesnis nei įprastai.';

  @override
  String get trajetDetailChartEmpty => 'Nėra įrašytų mėginių';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Bendrinti';

  @override
  String get trajetDetailShareImageOption => 'Bendrinti vaizdą';

  @override
  String get trajetDetailShareGpxOption => 'Bendrinti GPS pėdsaką (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Šioje kelionėje GPS duomenų nėra';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — kelionė $date';
  }

  @override
  String get trajetDetailShareError => 'Nepavyko sugeneruoti bendrinimo vaizdo';

  @override
  String get trajetDetailDeleteAction => 'Ištrinti';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Ištrinti šią kelionę?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ši kelionė bus visam laikui pašalinta iš jūsų istorijos.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Atšaukti';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Ištrinti';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapteris prijungtas, bet negrąžina duomenų. Išbandykite kitą adapterį arba patikrinkite transporto priemonės diagnostikos protokolą.';

  @override
  String get trajetsViewAllOnMap => 'Rodyti visus žemėlapyje';

  @override
  String get trajetsMapTitle => 'Kelionės žemėlapyje';

  @override
  String get trajetsMapShareGpx => 'Bendrinti GPX';

  @override
  String get trajetsMapEmpty => 'Pasirinktose kelionėse nėra GPS duomenų.';

  @override
  String get trajetsMapShareError => 'Nepavyko bendrinti GPX failo';

  @override
  String get tripLengthCardTitle => 'Suvartojimas pagal kelionės ilgį';

  @override
  String get tripLengthBucketShort => 'Trumpa (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Vidutinė (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Ilga (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Reikia daugiau duomenų';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelionės',
      one: '1 kelionė',
      zero: 'nėra kelionių',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Kelionės maršrutas';

  @override
  String get tripPathCardSubtitle => 'GPS įrašytas maršrutas';

  @override
  String get tripPathLegendTitle => 'Suvartojimas';

  @override
  String get tripPathLegendEfficient => 'Efektyvus (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Ribinis (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Švaistymas (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get tripRecordingPinTooltip =>
      'Prisegimas palaiko ekraną įjungtą — naudoja daugiau baterijos';

  @override
  String get tripRecordingPinSemanticOn => 'Atsegti įrašymo formą';

  @override
  String get tripRecordingPinSemanticOff => 'Prisegti įrašymo formą';

  @override
  String get tripRecordingPinHelpTooltip => 'Ką daro prisegimas?';

  @override
  String get tripRecordingPinHelpTitle => 'Apie prisegimą';

  @override
  String get tripRecordingPinHelpBody =>
      'Prisegimas palaiko ekraną įjungtą ir slepia sistemos juosteles, kad forma išliktų skaitoma, montuojant prietaisų skydelyje. Palieskite dar kartą, kad atleistumėte. Automatiškai atleidžiama, kai kelionė sustabdoma.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Įrašymas tęsiamas fone. Palieskite raudoną juostą bet kurio ekrano viršuje, kad grįžtumėte.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Atidarykite aktyvią kelionę iš suvartojimo skirtuko';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Prisekite ekraną, kad GPS veiktų kelionės metu — Android gali riboti GPS miego režimo metu.';

  @override
  String get tripRecordingMinimiseTooltip => 'Sumažinti į slankųjį langelį';

  @override
  String get tripRecordingAutoPinTitle => 'Visada prisegti pradedant įrašymą';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Automatiškai prisegti formą kiekvienos kelionės metu, užuot lietus kiekvieną kartą. Naudoja daugiau baterijos.';

  @override
  String get tripRecordingConnectingTitle => 'Pradedamas įrašymas…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripShareAction => 'Bendrinti su kita paskyra';

  @override
  String get tripShareSheetTitle => 'Bendrinti šią kelionę';

  @override
  String get tripShareSheetSubtitle =>
      'Suteikite kitai „TankSync“ paskyrai tik skaitymo prieigą prie šios įrašytos kelionės.';

  @override
  String get tripShareEmailLabel => 'Gavėjo el. paštas';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Bendrinti';

  @override
  String get tripShareCreateLinkButton => 'Sukurti bendrinimo nuorodą';

  @override
  String get tripShareLinkCreated =>
      'Bendrinimo nuoroda nukopijuota — įklijuokite ją gavėjui.';

  @override
  String get tripShareSuccess => 'Kelionė bendrinama.';

  @override
  String get tripShareRecipientNotFound =>
      'Jokia „TankSync“ paskyra nenaudoja šio el. pašto.';

  @override
  String get tripShareError =>
      'Nepavyko bendrinti kelionės. Bandykite dar kartą.';

  @override
  String get tripShareExistingTitle => 'Bendrinama su';

  @override
  String get tripShareExistingEmpty => 'Dar su niekuo nebendrinama.';

  @override
  String get tripShareDirectRecipient => 'Paskyra';

  @override
  String get tripShareLinkRecipient => 'Bendrinimo nuoroda (neatsiimta)';

  @override
  String get tripShareRevokeTooltip => 'Atšaukti';

  @override
  String get tripShareRevoked => 'Bendrinimas atšauktas.';

  @override
  String get trajetsSharedSectionTitle => 'Bendrinama su manimi';

  @override
  String get trajetsSharedBadge => 'Bendrinama';

  @override
  String get unifiedFilterFuel => 'Kuras';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Abu';

  @override
  String get unifiedNoResultsForFilter =>
      'Nėra rezultatų, atitinkančių šį filtrą';

  @override
  String get searchFailedSnackbar => 'Paieška nepavyko — bandykite dar kartą';

  @override
  String get vinLabel => 'VIN (neprivaloma)';

  @override
  String get vinDecodeTooltip => 'Iššifruoti VIN';

  @override
  String get vinConfirmAction => 'Taip, užpildyti automatiškai';

  @override
  String get vinModifyAction => 'Keisti rankiniu būdu';

  @override
  String get veResetAction => 'Atstatyti tūrinį efektyvumą';

  @override
  String get vehicleReadVinFromCarButton => 'Nuskaityti VIN iš automobilio';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Nuskaityti VIN iš suporuoto OBD2 adapterio';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN neprieinamas (9 režimo PID 02 nepalaikomas iki 2005 m. transporto priemonėse)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN nuskaitymas nepavyko — įveskite rankiniu būdu';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Pirmiausia suporuokite OBD2 adapterį, kad automatiškai nuskaitytumėte VIN';

  @override
  String get pickerButtonLabel => 'Pasirinkti iš katalogo';

  @override
  String get pickerSearchHint => 'Ieškoti gamintojo arba modelio';

  @override
  String get pickerHelpText =>
      'Iš anksto užpildyti iš 50+ palaikomų transporto priemonių';

  @override
  String get pickerEmptyResults => 'Nėra atitikmenų';

  @override
  String get pickerCancel => 'Atšaukti';

  @override
  String get pickerLoading => 'Kraunamas katalogas…';

  @override
  String get vinInfoTooltip => 'Kas yra VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Kas yra VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Transporto priemonės identifikavimo numeris — tai unikalus 17 simbolių kodas jūsų automobiliui. Jis išspaustas ant šasijos ir atspausdintas jūsų transporto priemonės registracijos dokumente.';

  @override
  String get vinInfoSectionWhyTitle => 'Kodėl klausiame';

  @override
  String get vinInfoSectionWhyBody =>
      'VIN iššifravimas automatiškai užpildo variklio darbinį tūrį, cilindrų skaičių, modelio metus, pagrindinį kuro tipą ir bendrąją masę — taupydamas jus nuo techninių duomenų paieškos. OBD2 kuro srauto skaičiavimas naudoja šias reikšmes, kad pateiktų tikslias suvartojimo skaitines reikšmes.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privatumas';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Jūsų VIN saugomas tik vietiškai programos šifruotoje saugykloje — jis niekada neįkeliamas į Sparkilo serverius. NHTSA vPIC duomenų bazė užklausos su VIN, tačiau grąžina tik anoniminių techninių specifikacijų duomenis; NHTSA nesusieja VIN su jokiais asmeniniais duomenimis. Be tinklo, neprisijungęs paieška grąžina tik gamintojo ir šalies informaciją.';

  @override
  String get vinInfoSectionWhereTitle => 'Kur jį rasti';

  @override
  String get vinInfoSectionWhereBody =>
      'Žiūrėkite pro priekinį stiklą į apatinį kairįjį kampą vairuotojo pusėje, patikrinkite vairuotojo durų rėmo lipduką, kai durys atidarytos, arba skaitykite jį iš savo transporto priemonės registracijos dokumento (kortelė / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Supratau';

  @override
  String get vinConfirmPrivacyNote =>
      'Paieškojome jūsų VIN NHTSA nemokamoje transporto priemonių duomenų bazėje — niekas neišsiųsta į Sparkilo serverius.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN interneto iššifravimas';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Iššifruoti VIN per NHTSA nemokamą viešą paslaugą';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Kai suporuojate adapterį, jūsų transporto priemonės VIN nuskaitomas vietiškai automobiliui identifikuoti. Įjungus tai, 17 simbolių VIN išsiunčiamas į NHTSA nemokamą vPIC paslaugą papildomoms detalėms peržiūrėti (modelis, variklio darbinis tūris, kuro tipas). VIN yra vieninteliai išsiunčiami duomenys — jokia kita informacija nepalieka jūsų įrenginio.';

  @override
  String get vehicleDetectedFromVinBadge => '(aptikta)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Aptikta iš VIN: $summary. Taikyti?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Taikyti';

  @override
  String get widgetHelpSectionTitle => 'Pradinio ekrano valdiklis';

  @override
  String get widgetHelpIntro =>
      'Pridėkite SparKilo valdiklį prie savo pradinio ekrano, kad vienu žvilgsniu matytumėte degalų ir įkrovimo kainas.';

  @override
  String get widgetHelpAdd =>
      'Pridėkite jį iš savo paleistuvo valdiklių parinkiklio — ilgai paspauskite tuščią pradinio ekrano sritį, pasirinkite Valdikliai ir raskite SparKilo.';

  @override
  String get widgetHelpTap =>
      'Palieskite stotelę valdiklyje, kad atidarytumėte ją programoje. Palieskite atnaujinimo piktogramą, kad atnaujintumėte kainas.';

  @override
  String get widgetHelpConfigure =>
      'Android aplinkoje ilgai spauskite valdiklį ir pasirinkite Konfigūruoti iš naujo, kad pakeistumėte profilį, spalvą ir turinį.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Toliau pateikti pasirinkimai taikomi kiekvienam įdiegtam valdikliui kito atnaujinimo metu.';

  @override
  String get widgetDefaultsColorLabel => 'Spalvų schema';

  @override
  String get widgetDefaultsVariantLabel => 'Turinio variantas';

  @override
  String get widgetColorSchemeSystem => 'Pagal sistemą';

  @override
  String get widgetColorSchemeLight => 'Šviesi';

  @override
  String get widgetColorSchemeDark => 'Tamsi';

  @override
  String get widgetColorSchemeBlue => 'Mėlyna';

  @override
  String get widgetColorSchemeGreen => 'Žalia';

  @override
  String get widgetColorSchemeOrange => 'Oranžinė';

  @override
  String get widgetVariantDefault => 'Tik dabartinė kaina';

  @override
  String get widgetVariantPredictive =>
      'Prognozuojama: geriausias laikas tankuoti';

  @override
  String get widgetPredictiveNowPrefix => 'dabar';
}
