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
  String get fabRunSearch => 'Vykdyti paiešką';

  @override
  String get routeSearchingChip => 'Ieškoma maršrute…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Kas $km km';
  }

  @override
  String get searchCriteriaTitle => 'Paieškos kriterijai';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km spinduliu';
  }

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
  String get freeNoKey => 'Nemokama — raktas nereikalingas';

  @override
  String get apiKeyRequired => 'Reikalingas API raktas';

  @override
  String get dataTransparency => 'Duomenų skaidrumas';

  @override
  String get storageAndCache => 'Saugykla ir podėlis';

  @override
  String get clearCache => 'Išvalyti podėlį';

  @override
  String stationsFound(int count) {
    return 'Rasta $count degalinių';
  }

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
  String get apiKeyNote =>
      'Nemokama registracija. Duomenys iš vyriausybinių kainų skaidrumo agentūrų.';

  @override
  String get apiKeyFormatError =>
      'Netinkamas formatas — tikėtinas UUID (8-4-4-4-12)';

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
  String profileSwitchedTo(String profile) {
    return 'Persijungta į $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profilis $name sukurtas';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Profilis šaliai $country jau egzistuoja — vietoj to redaguokite jį.';
  }

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
  String get evPriceFree => 'Nemokama';

  @override
  String get evPricePayAtLocation => 'Mokėti vietoje';

  @override
  String get evPriceMembership => 'Reikalinga narystė';

  @override
  String get evPriceIndicative => 'Orientacinė kaina';

  @override
  String get evPriceDeclaredByOperator =>
      'Orientacinė kaina, deklaruota operatoriaus — patikrinkite vietoje';

  @override
  String get evPriceFranceAttribution =>
      'Kainos: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Orientacinės kainos iš OpenChargeMap — negausios ir gali būti neišsamios.';

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
  String get edit => 'Redaguoti';

  @override
  String get fuelPricesApiKey => 'Degalų kainų API raktas';

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
  String get tripCost => 'Kelionės kaina';

  @override
  String get fuelNeeded => 'Reikalingi degalai';

  @override
  String get totalCost => 'Bendra kaina';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Atstumas ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Sąnaudos ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Kuro kaina ($unit)';
  }

  @override
  String get calculatorUseMine => 'Naudoti';

  @override
  String get calculatorApplied => 'Pritaikyta';

  @override
  String get tripDetails => 'Kelionės informacija';

  @override
  String get calculatorRoundTrip => 'Pirmyn ir atgal';

  @override
  String get roundTripTotal => 'Pirmyn ir atgal';

  @override
  String get costPerDistance => 'Kaina už km';

  @override
  String get costPerMonth => 'Kaina per mėnesį';

  @override
  String get calculatorEstimateMonthly => 'Apskaičiuoti mėnesines išlaidas';

  @override
  String get calculatorTripsPerMonth => 'Kelionės per mėnesį';

  @override
  String get calculatorTripsPerMonthHint => 'pvz. 20';

  @override
  String get calculatorReset => 'Atstatyti';

  @override
  String get calculatorResultPlaceholder =>
      'Užpildykite atstumą, sąnaudas ir kainą, kad pamatytumėte kelionės kainą';

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
  String get noStatistics => 'Nėra prieinamų statistikų';

  @override
  String get showAllFuelTypes => 'Rodyti visus degalų tipus';

  @override
  String get connected => 'Prisijungta';

  @override
  String get disconnectTankSync => 'Atjungti TankSync';

  @override
  String get viewMyData => 'Peržiūrėti mano duomenis';

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
  String get gdprContinueAll => 'Tęsti su viskuo';

  @override
  String get gdprContinueSelected => 'Tęsti su pasirinktais';

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
  String get voiceAnnouncementProximityRadius => 'Pranešimų spindulys';

  @override
  String get voiceAnnouncementCooldown => 'Kartojimo intervalas';

  @override
  String get voiceAnnouncementPriceLimit => 'Didžiausia kaina';

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
  String get obdPermissionDenied =>
      'Suteikite Bluetooth leidimą sistemos nustatymuose';

  @override
  String get obdPickerTitle => 'Pasirinkite OBD2 adapterį';

  @override
  String get obdPickerScanning => 'Ieškoma adapterių…';

  @override
  String get obdPickerConnecting => 'Jungiamasi…';

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
  String get vehicleBaselineShowDetails => 'Rodyti išskaidymą pagal situaciją';

  @override
  String get vehicleBaselineHideDetails => 'Slėpti išskaidymą pagal situaciją';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Dar neaptikta: $situations. Šiose vairavimo situacijose vis dar yra 0 pavyzdžių, todėl bazinis lygis neišbaigtas.';
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
  String get obd2StatusPermissionDenied =>
      'OBD2 adapteris: reikalingas Bluetooth leidimas';

  @override
  String get obd2StatusConnectedBody => 'Paruošta įrašyti kelionę.';

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
  String get situationColdStart => 'Šaltas paleidimas';

  @override
  String get situationSustainedLoad => 'Ilgalaikė apkrova / vilkimas';

  @override
  String get situationPartialDecel => 'Riedėjimas';

  @override
  String get situationHardAccel => 'Staigus greitinimas';

  @override
  String get situationFuelCut => 'Kuro atjungimas — inercinė eiga';

  @override
  String get tripSaveRecording => 'Išsaugoti kelionę';

  @override
  String get tripSummaryAutoSaved => 'Kelionė išsaugota automatiškai';

  @override
  String get tripSummaryDone => 'Atlikta';

  @override
  String get tripSummaryDelete => 'Ištrinti šią kelionę';

  @override
  String get vehicleFuelNotSet => 'Nenustatyta';

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
  String get vehiclePowerLabel => 'Variklio galia (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps AG';
  }

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
  String get evStatusAvailable => 'Laisva';

  @override
  String get evStatusOccupied => 'Užimta';

  @override
  String get evStatusOutOfOrder => 'Neveikia';

  @override
  String get evStatusPartial => 'Dalinai prieinama';

  @override
  String get openOnlyFilter => 'Tik atidarytos';

  @override
  String get saveAsDefaults => 'Išsaugoti kaip numatytuosius';

  @override
  String get criteriaSavedToProfile => 'Išsaugota kaip numatytieji';

  @override
  String get updatingFavorites => 'Atnaujinami jūsų mėgstami...';

  @override
  String get fetchingLatestPrices => 'Gaunamos naujausios kainos';

  @override
  String get noDataAvailable => 'Nėra duomenų';

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
  String get sectionSetupDataSources => 'Sąranka ir duomenų šaltiniai';

  @override
  String get sectionFeaturesUsage => 'Funkcijos ir naudojimas';

  @override
  String get sectionAccountSync => 'Paskyra ir sinchronizavimas';

  @override
  String get sectionAppearanceWidgets => 'Išvaizda ir valdikliai';

  @override
  String get sectionPrivacyData => 'Privatumas ir duomenys';

  @override
  String get sectionAdvancedDeveloper => 'Išplėstiniai ir kūrėjo nustatymai';

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
  String get minimalDriveBehaviour => 'Vairavimo stilius';

  @override
  String get coachingShiftUp => 'Aukštyn pavarą';

  @override
  String get coachingShiftDown => 'Žemyn pavarą';

  @override
  String get coachingEasePedal => 'Atleisk akceleratorių';

  @override
  String get coachingVoiceHardAcceleration =>
      'Švelniau spauskite akceleratorių';

  @override
  String get coachingVoiceHarshBraking => 'Stabdykite švelniau';

  @override
  String get coachingVoiceShiftUp =>
      'Perjunkite į aukštesnę pavarą, kad sutaupytumėte kuro';

  @override
  String get coachingVoiceShiftDown =>
      'Perjunkite į žemesnę pavarą — variklis perkrautas';

  @override
  String get coachingVoiceEasePedal =>
      'Atlaisvinkite pedalą, kad sumažintumėte kuro sąnaudas';

  @override
  String get coachingVoiceLiftOff =>
      'Pakelkite koją nuo akceleratoriaus ir riedėkite';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Žiūrėkite toliau į priekį ir anksčiau pakelkite koją';

  @override
  String get coachingVoiceSmoothAccel => 'Greičiau įsibėgėkite sklandžiau';

  @override
  String get coachingVoiceSharpCorner => 'Posūkius įveikite šiek tiek švelniau';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Tai buvo labai staigus stabdymas — laikykite didesnį atstumą';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Labai staigus greitėjimas — tai tikrai degina degalus';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Labai staigus posūkis — lėtai į jį, sklandžiai iš jo';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount staigių manevrų.',
      few: '$harshCount staigūs manevrai.',
      one: '$harshCount staigus manevras.',
      zero: 'Sklandžiai — jokių staigių manevrų.',
    );
    return 'Kelionė išsaugota: $distanceKm kilometrų, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litro šimtui kilometrų';
  }

  @override
  String get voiceCoachingSettingTitle => 'Balsinis vairavimo mokymas';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Gaukite balsinius patarimus vairuodami — stiprus greičio didinimas, staigus stabdymas ir pavarų užuominos';

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
  String get tankSyncSchemaOutdatedTitle =>
      'Debesies duomenų bazę reikia atnaujinti';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Jūsų savarankiškai talpinama „TankSync“ schema pasenusi — kai kurių duomenų negalima sinchronizuoti. Atidarykite sinchronizavimo vedlį ir paleiskite atnaujinimo SQL savo „Supabase“ projekte.';

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
  String get syncSchemaOutdated =>
      'Jūsų „TankSync“ schema pasenusi — dar kartą paleiskite toliau pateiktą sąrankos SQL, kad įjungtumėte naujausias sinchronizuojamas funkcijas.';

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
  String serviceReminderDueNowBody(String label) {
    return '$label — laikas dabar.';
  }

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
  String get obd2GpsDegradedBannerTitle =>
      'Įrašoma su GPS — OBD2 jungiasi iš naujo';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Įrašoma su GPS — laukiama OBD2 adapterio';

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
  String get alertsStationSectionTitle => 'Degalinės įspėjimai';

  @override
  String get alertsStationAdd => 'Pridėti degalinės įspėjimą';

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
  String radiusAlertDeleted(String name) {
    return 'Spindulio įspėjimas „$name“ ištrintas';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 prijungtas: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Suporuoti OBD2 adapterį';

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
  String get obd2ErrorEngineOff =>
      'Iš automobilio nėra duomenų — užveskite variklį ir bandykite dar kartą.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2 adapteris išsiuntė neatpažintą atsakymą. Jis gali būti nesuderinamas — pabandykite kitą adapterį.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2 adapteris atsijungė. Prisijunkite iš naujo ir bandykite dar kartą.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adapterį reikia susieti per „Bluetooth“. Atjunkite adapterį, vėl prijunkite ir per 5 minutes bandykite dar kartą.';

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
  String alertsLastChecked(String when) {
    return 'Paskutinį kartą tikrinta: $when';
  }

  @override
  String get alertsLastCheckedNever => 'Kainos fone dar netikrintos';

  @override
  String get alertsIosBestEffortNote =>
      '„iPhone“ įspėjimai tikrinami pagal galimybes: „iOS“ sprendžia, kada programa gali tikrinti kainas fone, todėl įspėjimas gali vėluoti arba kartais visai neateiti. Atidarius programą visada atliekama nauja patikra.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Tikslinė kaina ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Slenkstis ($currency/L)';
  }

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
  String fuelStationRadarProximity(int percent) {
    return 'Artumas $percent%';
  }

  @override
  String get pipTapToRestore => 'Bakstelėkite, kad atidarytumėte visą programą';

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
  String get authLinkEmailTitle => 'Susieti el. paštą';

  @override
  String get authLinkEmailSubtitle =>
      'Susiekite el. paštą, kad duomenys būtų sinchronizuojami tarp įrenginių. Dabartinės mėgstamiausios degalinės ir kelionės lieka šioje paskyroje.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Naudojate svečio paskyrą ($idPrefix…). Susiekite el. paštą, kad mėgstamiausios degalinės ir kelionės būtų sinchronizuojamos su kitais įrenginiais.';
  }

  @override
  String get authConfirmationPending =>
      'Beveik baigta — patikrinkite el. paštą ir spustelėkite nuorodą, kad užbaigtumėte susiejimą. Jūsų duomenys šioje paskyroje jau išsaugoti.';

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
  String get aclWakeNotificationTitle => 'Automobilis prijungtas';

  @override
  String get aclWakeNotificationBody =>
      'Bakstelėkite, kad atidarytumėte „Sparkilo“ — galima pradėti kelionės įrašymą.';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Suporuokite adapterį žemiau esančiame skyriuje, kad įjungtumėte automatinį įrašymą';

  @override
  String get exportBackupReady =>
      'Atsarginė kopija paruošta — pasirinkite paskirties vietą';

  @override
  String get exportBackupFailed =>
      'Atsarginės kopijos eksportas nepavyko — bandykite dar kartą';

  @override
  String get backupExportProgress => 'Eksportuojama jūsų atsarginė kopija…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Išsaugota atsisiuntimų aplanke kaip $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Atkurti atsarginę kopiją';

  @override
  String get restoreBackupDialogBody =>
      'Sujungimas prideda ir atnaujina atsarginės kopijos įrašus bei išsaugo viską, kas jau yra šiame įrenginyje. Keitimas pirmiausia ištrina visus esamus duomenis, tada atkuria tik atsarginę kopiją — to negalima atšaukti.';

  @override
  String get restoreBackupMergeAction => 'Sujungti';

  @override
  String get restoreBackupReplaceAction => 'Pakeisti viską';

  @override
  String get restoreBackupEmpty =>
      'Atsarginė kopija atkurta — joje nebuvo įrašų';

  @override
  String get restoreBackupCorrupt =>
      'Atkūrimas nepavyko — šis failas nėra galiojanti Tankstellen atsarginė kopija';

  @override
  String get restoreBackupFailed =>
      'Atkūrimas nepavyko — failo nepavyko perskaityti';

  @override
  String get backupImportProgress => 'Atkuriama jūsų atsarginė kopija…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Sujungta $vehicles transporto priemonių, $fillUps papildymų, $trips kelionių, $chargingLogs įkrovimo žurnalų';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Visi duomenys pakeisti: $vehicles transporto priemonės, $fillUps papildymai, $trips kelionės, $chargingLogs įkrovimo žurnalai';
  }

  @override
  String get brokenMapChipDisclaimer => 'MAP rodymai įtartini';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP jutiklis rodo neteisingai — kuro rodmenys gali būti 50–80% per maži. Išbandykite kitą adapterį.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP jutiklis nepatikimas. Rodomi tankavimo vidurkiai vietoj tiesioginės kuro normos.';

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
  String get calibrationDirectFuelRateNote =>
      'Šis automobilis degalų sąnaudas praneša tiesiogiai (PID 5E), todėl tūrinio efektyvumo kalibravimas nenaudojamas — jūsų sąnaudos matuojamos, o ne modeliuojamos.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Jūsų $makeModel pažymėtas kaip dyzelinis, bet atitinka benzininio katalogo įrašą. Palieskite, kad atnaujintumėte.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Atnaujinti';

  @override
  String get catalogResetAction =>
      'Atkurti iš transporto priemonių duomenų bazės';

  @override
  String get catalogResetConfirmTitle =>
      'Atkurti iš transporto priemonių duomenų bazės?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Šio automobilio bako talpa, variklio galia ir darbinis tūris bus pakeisti duomenų bazės reikšmėmis ($vehicle). Kiti laukai ir degalų pildymo istorija nekeičiami.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'Duomenų bazėje nėra šį automobilį atitinkančio įrašo.';

  @override
  String get catalogResetDoneSnackbar =>
      'Automobilio duomenys atkurti iš duomenų bazės.';

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
  String get confirmDeleteTitle => 'Ištrinti?';

  @override
  String get confirmDeleteBody => 'Ar tikrai norite tai ištrinti?';

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
  String get consoGroupVehicles => 'Transporto priemonės';

  @override
  String get consoGroupCoaching => 'Mokymas vairuojant';

  @override
  String get consoGroupRewards => 'Atlygiai ir sutaupymai';

  @override
  String get consoGroupTroubleshooting => 'Trikčių šalinimas';

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
  String get moreActionsTooltip => 'Daugiau';

  @override
  String get exportBackupMenuLabel => 'Eksportuoti atsarginę kopiją';

  @override
  String get restoreBackupMenuLabel => 'Atkurti atsarginę kopiją';

  @override
  String get carbonDashboardMenuLabel => 'Anglies suvestinė';

  @override
  String get settingsMenuLabel => 'Nustatymai';

  @override
  String get consumptionStatsPageTitle => 'Sąnaudų statistika';

  @override
  String get consumptionStatsComparisonTitle => 'Šis mėnuo vs praėjęs mėnuo';

  @override
  String get consumptionStatsTrendsTitle => 'Raida laikui bėgant';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Registruokite papildymus bent du mėnesius, kad galėtumėte palyginti.';

  @override
  String get consumptionStatsPricePerLiter => 'Vid. kaina/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litrai per mėnesį';

  @override
  String get consumptionStatsChartSpend => 'Išlaidos per mėnesį';

  @override
  String get consumptionStatsChartPricePerLiter => 'Kaina už litrą';

  @override
  String get consumptionStatsChartConsumption => 'L/100km per mėnesį';

  @override
  String get fuelCompareSectionTitle => 'Važiavimo kaina pagal degalus';

  @override
  String get fuelComparePricePerLitre => 'Sumokėta už litrą';

  @override
  String get fuelCompareCostPer100km => 'Kaina 100 km';

  @override
  String get fuelCompareDistance => 'Išmatuotas atstumas';

  @override
  String get fuelCompareLitres => 'Sunaudoti litrai';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner yra pigiausi degalai važiuoti';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser kainuoja $amount daugiau 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel pranoksta $rival, kai litras pigesnis nei $price';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Lūžio taškas skaičiuojamas pagal kiekvienų degalų išmatuotas sąnaudas, todėl jis kinta kartu su tavo vairavimu.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litrai ir kaina gali nesutapti: degalai gali sunaudoti mažiau litrų 100 km ir vis tiek kainuoti daugiau už kilometrą, nes skiriasi litro kaina. Lemia kaina už kilometrą.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pilnais bakais',
      one: 'vienu pilnu baku',
    );
    return 'Preliminaru — remiantis $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pilnais bakais',
      one: 'vienu pilnu baku',
    );
    return 'Remiantis $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner yra maziausiai teršiantys tavo degalai';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel kainuoja $money daugiau 1000 km, bet išmeta $co2 mažiau CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel yra ir pigesni, ir švaresni nei $rival';
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
    return 'Tavo $distance su $fuel išmetė $actual, o ne $alternative su $rival — $saved išvengta';
  }

  @override
  String get fuelCompareCo2Source =>
      'CO2 skaičiai yra viso ciklo (EU JEC WTW v5) įverčiai, pritaikyti tavo išmatuotoms sąnaudoms — orientaciniai, ne sertifikuota apskaita.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 rodomas tik grynoms degalų rūšims: mišinio taršos koeficientas priklauso nuo sudėties, kurios ši eilutė nefiksuoja.';

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
    return 'Pataisymai: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Pranešti apie turinį';

  @override
  String get contentModerationBlockAction => 'Blokuoti autorių';

  @override
  String get contentModerationReportDialogTitle => 'Pranešti apie šį turinį?';

  @override
  String get contentModerationReportDialogBody =>
      'Pranešimas siunčiamas į jūsų „TankSync“ serverį peržiūrėti, o šis turinys jūsų įrenginyje paslepiamas.';

  @override
  String get contentModerationReportConfirmButton => 'Pranešti';

  @override
  String get contentModerationBlockDialogTitle => 'Blokuoti šį autorių?';

  @override
  String get contentModerationBlockDialogBody =>
      'Viskas, kuo ši paskyra su jumis dalijasi, šiame įrenginyje bus paslėpta.';

  @override
  String get contentModerationBlockConfirmButton => 'Blokuoti';

  @override
  String get contentModerationReportedSnack =>
      'Pranešimas išsiųstas — turinys paslėptas.';

  @override
  String get contentModerationReportFailedSnack =>
      'Nepavyko išsiųsti pranešimo. Bandykite dar kartą.';

  @override
  String get contentModerationBlockedSnack =>
      'Autorius užblokuotas — jo bendrinamas turinys paslėptas.';

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
  String crossBorderCheaper(String country, String km, String price) {
    return '$country stotelės $km km atstumu — €$price/L pigiau';
  }

  @override
  String get crossBorderTapToSwitch => 'Palieskite, kad perjungtumėte šalį';

  @override
  String get crossBorderDismissTooltip => 'Atmesti';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Atidaryti $source duomenų šaltinį ($license) naršyklėje';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Kūrėjo įrankiai';

  @override
  String get dataAccessTracerExport => 'Eksportuoti duomenų prieigos žurnalą';

  @override
  String get dataAccessTracerExportSuccess =>
      'Duomenų prieigos žurnalas išsaugotas aplanke „Atsisiuntimai“.';

  @override
  String get dataAccessTracerExportFailure =>
      'Nepavyko eksportuoti duomenų prieigos žurnalo.';

  @override
  String get dataAccessTracerEmpty =>
      'Duomenų prieigos įvykių dar neužfiksuota — pirmiausia ieškokite arba atidarykite degalines, tada eksportuokite.';

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
      'Pirmiausia ieškokite degalinių, tada paleiskite bandomąjį įspėjimą, kad pranešimas galėtų atidaryti tikrą degalinę.';

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
  String get startupTraceSectionTitle => 'Paleidimo inicijavimo žurnalas';

  @override
  String get startupTraceExportButton => 'Eksportuoti paleidimo žurnalą';

  @override
  String get startupTraceEmpty => 'Paleidimo žurnalas dar neįrašytas.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Iš viso: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Paleidimo žurnalas išsaugotas aplanke „Atsisiuntimai“.';

  @override
  String get startupTraceExportFailure =>
      'Nepavyko eksportuoti paleidimo žurnalo.';

  @override
  String get distanceSourceOdometer => 'Odometras';

  @override
  String get distanceSourceOdometerTooltip =>
      'Atstumas nuskaitytas iš automobilio odometro — išmatuota atskaitos reikšmė.';

  @override
  String get distanceSourceGps => 'GPS pėdsakas';

  @override
  String get distanceSourceGpsTooltip =>
      'Atstumas susumuotas iš įrašyto GPS pėdsako — tikrasis kelio atstumas.';

  @override
  String get distanceSourceEstimated => 'Apytikslis';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Atstumas integruotas iš greičio jutiklio — apytikslis; jutiklis paprastai rodo šiek tiek per daug.';

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
    return 'Pilnas dujas ($pctTime% kelionės): iššvaistyta $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Švelniau spauskite pedalą — švelnesnis 70 % akceleravimas leidžia įsibėgėti sunaudojant žymiai mažiau kuro.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Praturtinta mišinio dalis apkrovos metu ($pctTime% kelionės): iššvaistyta $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Sunki ilgalaikė apkrova priverčia variklį veikti praturtinto mišinio režimu — keiskite pavaras anksčiau ir mažinkite apkrovą ilgose pakiluose, kad mišinys liktų liesas.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Kilimas $gradePercent% nuolydžiu ($pctTime% kelionės): iššvaistyta $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Įgaukite pagreitį prieš kalną ir sklandžiai atidarykite dujas — staigus spaudimas kalnagūbryje padidina kuro sąnaudas.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count sustok-pajudek paleidimų: iššvaistyta $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Numatykite eismą ir riedėkite link sustojimų, kad ridėtumėtės, o ne startuotumėte iš naujo — pajudėjimas iš vietos yra brangiausia sustok-pajudek dalis.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Mišinys atrodo šiek tiek liesas — variklis pridėjo degalų ($pctTrim % korekcija), kad kompensuotų';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Mišinys atrodo liesas — variklis nuolat pridėjo daug degalų ($pctTrim %), galimas neefektyvumas';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Mišinys atrodo šiek tiek riebus — variklis sumažino degalų ($pctTrim % korekcija), kad kompensuotų';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Mišinys atrodo riebus — variklis nuolat gerokai mažino degalų ($pctTrim %), galimas neefektyvumas';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Variklis esant apkrovai dirbo riebiu mišiniu ($pctShare % važiavimo įšilus) — galimai iššvaistyti degalai';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Euristinis būklės signalas, ne diagnozė';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Ilgalaikė korekcija link liesos mišinio gali reikšti oro nuotėkį įsiurbime, silpną degalų tiekimą arba senstantį jutiklį. Jei sąnaudos ar variklio darbas blogėja, servisas diagnostika gali tai patvirtinti.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Ilgalaikė korekcija link riebaus mišinio gali reikšti nesandarų purkštuką, per aukštą degalų slėgį arba per daug rodantį jutiklį. Jei sąnaudos ar variklio darbas blogėja, serviso diagnostika gali tai patvirtinti.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Riebus mišinys esant didelei apkrovai degina papildomus degalus. Anksčiau perjunkite aukštesnę pavarą ir ilgai greitėdami atleiskite akceleratorių, kad variklis išliktų arti stechiometrinio mišinio.';

  @override
  String get lessonTransportTitle =>
      'Didžiąją šios kelionės dalį trūksta variklio duomenų';

  @override
  String get lessonTransportAdvice =>
      'Variklis beveik visą atstumą nepranešė jokios veiklos. Arba OBD2 duomenų srautas nutrūko kelionės viduryje, arba automobilis buvo perkeltas nevažiuojant — sąnaudų rodmuo nepatikimas ir neįtraukiamas į jūsų statistiką.';

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
  String get drivingScoreClassVeryGood => 'Labai gerai';

  @override
  String get drivingScoreClassGood => 'Gerai';

  @override
  String get drivingScoreClassAverage => 'Vidutiniškai';

  @override
  String get drivingScoreClassBad => 'Reikia tobulinti';

  @override
  String get drivingScorePenaltyLugging => 'Variklio perkrovimas';

  @override
  String get drivingScorePenaltySmoothness => 'Trūkčiojantis vairavimas';

  @override
  String get drivingScorePenaltyHighSpeed => 'Didelis greitis';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresyvus pedalas';

  @override
  String get drivingScorePenaltyLambda => 'Praturtintas mišinys';

  @override
  String get gpsKpiCardTitle => 'GPS efektyvumas';

  @override
  String get gpsKpiRpa => 'Teigiamas pagreitis (RPA)';

  @override
  String get gpsKpiPke => 'Kinetinės energijos poreikis (PKE)';

  @override
  String get gpsKpiVapos => 'Pagreičio intensyvumas (VAPOS)';

  @override
  String get gpsKpiCoast => 'Riedėjimo dalis';

  @override
  String get gpsKpiClimbEnergy => 'Kilimo energija';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct palyginti su jūsų efektyvumo baze';
  }

  @override
  String get drivingTraceCardTitle => 'Vairavimo analizės sekimas (kūrėjo)';

  @override
  String get drivingTraceCardBody =>
      'Eksportuokite šios kelionės GPS KPI, rezultatą ir pamokas kaip JSON, komentarų lauke aprašykite, kaip iš tikrųjų jautėsi važiavimas, ir bendrinkite atgal, kad vairavimo stiliaus ribinės reikšmės galėtų būti kalibruotos pagal tikras keliones.';

  @override
  String get drivingTraceExportAction => 'Eksportuoti analizės seką';

  @override
  String get drivingTraceExported =>
      'Analizės seka išsaugota atsisiuntimų aplanke — komentarų lauke pridėkite savo nuomonę ir bendrinkite atgal.';

  @override
  String get drivingTraceExportFailed => 'Nepavyko eksportuoti analizės sekos.';

  @override
  String get minimalDriveTripAverage => 'Kelionės vidurkis';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Važiavimas aukštomis apsukomis ($pctTime % kelionės): anksčiau įjungus aukštesnę pavarą būtų galima sutaupyti $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Važiuodami pastoviu greičiu aukštesnę pavarą įjunkite anksčiau — tas pats greitis žemesnėmis apsukomis degina pastebimai mažiau.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Riedėjimas su nutrauktu degalų tiekimu ($pctTime % kelionės): sutaupyta apie $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Gerai numatyta — anksti atleidus akceleratorių variklis riedant gali visiškai nutraukti degalų tiekimą.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Kur dingo jūsų degalai';

  @override
  String get fuelBreakdownIdle => 'Tuščioji eiga';

  @override
  String get fuelBreakdownHarshAccel => 'Staigūs greitėjimai';

  @override
  String get fuelBreakdownHighRpmCruise => 'Važiavimas aukštomis apsukomis';

  @override
  String get fuelBreakdownCoastingSaved => 'Sutaupyta riedant';

  @override
  String get fuelBreakdownEfficient => 'Įprastas važiavimas';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Variklis jau kurį laiką veikia tuščiąja eiga — jį išjungus sutaupoma degalų';

  @override
  String get ecoNudgeHarshAccel =>
      'Staigus greitėjimas — švelnesnė koja ant pedalo taupo degalus';

  @override
  String get ecoNudgeHighRpm =>
      'Aukštos apsukos važiuojant pastoviu greičiu — ankstesnis aukštesnės pavaros įjungimas taupo degalus';

  @override
  String get obd2CoverageNoneNote =>
      'Per šią kelionę iš OBD2 adapterio negauta jokių variklio duomenų — degalų rodmenys yra GPS pagrindu apskaičiuoti įverčiai.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Variklio duomenys nutrūko ties $percent % kelionės (nutrūko ryšys) — vėlesni degalų rodmenys yra GPS pagrindu apskaičiuoti įverčiai.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Variklio duomenys apėmė tik $percent % šios kelionės — spragose naudojami GPS pagrindu apskaičiuoti įverčiai.';
  }

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
  String get featureLabel_approachOverlay => 'Degalinių radaras';

  @override
  String get featureDescription_approachOverlay =>
      'Plūduriuojantis kelionės langelis virsta gyvuoju degalinių radaru — artėjant prie degalinės jis persijungia į kuro tipo spalvą ir rodo kainą.';

  @override
  String get featureLabel_voiceAnnouncements => 'Balso pranešimai';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Garsiai skelbia netoliese esančias pigias degalines važiuojant, kad galėtumėte laikyti akis kelyje.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Pirmiausia įjunkite Degalinių radarą';

  @override
  String get featureGroupTitle_finding => 'Paieška ir žemėlapis';

  @override
  String get featureGroupDescription_finding =>
      'Kur papildyti degalų ar įkrauti — paieška, žemėlapis, maršruto planavimas.';

  @override
  String get featureGroupTitle_prices => 'Kainos ir įspėjimai';

  @override
  String get featureGroupDescription_prices =>
      'Kainų kritimai, istorija ir pranešimai.';

  @override
  String get featureGroupTitle_radar => 'Degalinių radaras';

  @override
  String get featureGroupDescription_radar =>
      'Gyvi kainų patarimai vairuojant.';

  @override
  String get featureGroupTitle_sync => 'Sinchronizavimas ir atsarginė kopija';

  @override
  String get featureGroupDescription_sync =>
      'Saugokite savo duomenis visuose įrenginiuose.';

  @override
  String get featureGroupTitle_input => 'Įvestis ir nuskaitymas';

  @override
  String get featureGroupDescription_input =>
      'Pagalbinės priemonės papildymams registruoti.';

  @override
  String get featureGroupTitle_developer => 'Kūrėjo ir eksperimentiniai';

  @override
  String get featureGroupDescription_developer =>
      'Patyrusiems naudotojams ir prisidedantiems skirtos priemonės.';

  @override
  String get featureLabel_voiceFeedback => 'Balso atsakas (kalbos sintezė)';

  @override
  String get featureDescription_voiceFeedback =>
      'Pagrindinis visų balso pranešimų jungiklis — vairavimo balso trenerio ir degalinių pranešimų. Išjungus programa niekada nepaleidžia kalbos sintezės.';

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
  String get fillUpMultiFuelHint =>
      'Šis automobilis gali naudoti skirtingus degalus — įrašykite tuos, kuriuos iš tikrųjų pylėte';

  @override
  String get fillUpGuidanceTitle => 'Geriausias laikas papildyti baką';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Dabartinė kaina yra tarp pigiausių per paskutines $days dienas — geras laikas pilti degalus.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Kainos artimos $days dienų aukštumoms. Jos paprastai pigesnės $window — apsvarstykite laukimą.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Kainos auga — apsvarstykite galimybę piltis degalus netrukus.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Šiandienos kaina artima $days dienų vidurkiui.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Galima sutaupyti apie $amount/L tinkamai pasirinkus laiką.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remiantis $count kainų nuskaitymais',
      one: 'Remiantis 1 kainų nuskaitymu',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return '$day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'kitais laikais';

  @override
  String get fillUpGuidanceWeekday1 => 'pirmadieniais';

  @override
  String get fillUpGuidanceWeekday2 => 'antradieniais';

  @override
  String get fillUpGuidanceWeekday3 => 'trečiadieniais';

  @override
  String get fillUpGuidanceWeekday4 => 'ketvirtadieniais';

  @override
  String get fillUpGuidanceWeekday5 => 'penktadieniais';

  @override
  String get fillUpGuidanceWeekday6 => 'šeštadieniais';

  @override
  String get fillUpGuidanceWeekday7 => 'sekmadieniais';

  @override
  String get fillUpGuidancePartEarlyMorning => 'anksti ryte';

  @override
  String get fillUpGuidancePartMorning => 'rytais';

  @override
  String get fillUpGuidancePartAfternoon => 'popietėmis';

  @override
  String get fillUpGuidancePartEvening => 'vakarais';

  @override
  String get fillUpGuidancePartNight => 'naktimis';

  @override
  String get fillUpImportPasteLabel => 'Įklijuoti tekstą';

  @override
  String get pasteReceiptDialogTitle => 'Įklijuoti kvito tekstą';

  @override
  String get pasteReceiptDialogHint =>
      'Įklijuokite degalų kvito tekstą — el. laišką, SMS arba bendrintą PDF. Litrai, litro kaina, degalų rūšis, suma ir degalinė nuskaitomi įrenginyje ir iš anksto užpildo formą. Niekas nesiunčiama į serverį.';

  @override
  String get pasteReceiptFieldHint => 'Kvito tekstas';

  @override
  String get pasteReceiptParseAction => 'Užpildyti';

  @override
  String get pasteReceiptNoData =>
      'Iš šio teksto nepavyko nuskaityti degalų duomenų — patikrinkite, ar tai degalų kvitas, ir bandykite dar kartą.';

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
  String get badScanReportTitleReceipt =>
      'Pranešti apie nuskaitymo klaidą — Kvitas';

  @override
  String get badScanReportHint =>
      'Bendrinsime kvito nuotrauką ir abi reikšmių rinkinius, kad kitas versijos variantas galėtų išmokti šį išdėstymą.';

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
  String get fillUpWarningDialogTitle => 'Patikrinkite šį pildymą';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Pasirinkote $chosenFuel, bet šis automobilis važiuoja su $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Odometro rodmuo $entered km yra mažesnis nei ankstesnio pildymo $previous km — atstumas negali mažėti.';
  }

  @override
  String get fillUpWarningGoBack => 'Grįžti ir pataisyti';

  @override
  String get fillUpWarningSaveAnyway => 'Vis tiek išsaugoti';

  @override
  String get fillUpSectionWhatTitle => 'Ką pildėte';

  @override
  String get fillUpSectionWhatSubtitle => 'Kuras, kiekis, kaina';

  @override
  String get fillUpSectionWhereTitle => 'Kur buvote';

  @override
  String get fillUpSectionWhereSubtitle => 'Stotelė, odometras, pastabos';

  @override
  String get fillUpImportReceiptLabel => 'Kvitas';

  @override
  String get fillUpPricePerLiterLabel => 'Kaina už litrą';

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
  String get profileSectionDisplayStations => 'Rodymas ir degalinės';

  @override
  String get profileSectionRegion => 'Regionas';

  @override
  String get fuelEfficiencyCardTitle => 'Kilometro kaina pagal degalus';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Su kokiu degalų mišiniu važiuoti iš tikrųjų pigiausia';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Pigiausia už km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Gryni';

  @override
  String get fuelEfficiencyMixBadge => 'Mišinys';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Daugiausia $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Kaina/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Iš viso išleista';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pildymų',
      few: '$count pildymai',
      one: '$count pildymas',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pilnų bakų',
      few: '$count pilni bakai',
      one: '$count pilnas bakas',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Įrašykite bent du pilnus bakus kiekvienai sudėčiai, kad būtų nustatyti pigiausi degalai.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Bakai grupuojami pagal sudėtį: bakas grynas, kai vieni degalai sudaro bent 85 %, kitaip tai mišinys.';

  @override
  String get fuelNameE5 => 'Benzinas 95';

  @override
  String get fuelNameE10 => 'Benzinas 95 E10';

  @override
  String get fuelNameE98 => 'Benzinas 98';

  @override
  String get fuelNameDiesel => 'Dyzelinas';

  @override
  String get fuelNameDieselPremium => 'Dyzelinas Premium';

  @override
  String get fuelNameE85 => 'Bioetanolis E85';

  @override
  String get fuelNameLpg => 'SND (LPG)';

  @override
  String get fuelNameCng => 'SGD (CNG)';

  @override
  String get fuelNameHydrogen => 'Vandenilis';

  @override
  String get fuelNameElectric => 'Elektra';

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
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Pėdsakas apima $pct % — ilgiausia spraga $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Pėdsakas apima $pct % — spragų neaptikta';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'programa fone';

  @override
  String get gpsCoverageAttrOsBatching => 'sistema grupavo pozicijas';

  @override
  String get gpsCoverageAttrGateRejected => 'pozicijos išfiltruotos';

  @override
  String get gpsCoverageAttrDeliveryStall => 'vėluojantis pateikimas';

  @override
  String get gpsCoverageAttrSignalLoss => 'signalo praradimas';

  @override
  String get gpsCoverageAttrUnknown => 'nežinoma priežastis';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Programa veikė fone be priekinio plano paslaugos, todėl sistema apribojo GPS. Įrašydami laikykite ekraną įjungtą arba įjunkite įrašymą fone, kai jis bus pasiekiamas.';

  @override
  String get gpsCoverageHintOsBatching =>
      'Sistema pozicijas pateikė vėluodama ir grupėmis; pėdsakas buvo užpildytas vėliau, todėl iš tikrųjų prarasta nedaug duomenų.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Triukšmingos šios atkarpos pozicijos buvo išfiltruotos, kad atstumo rodmuo liktų sąžiningas.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Pozicijos buvo nustatytos laiku, bet programą pasiekė vėluodamos — telefonas buvo užimtas (dažnai „Bluetooth“ pakartotinis prisijungimas). Priėmimas buvo geras.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Dingo GPS priėmimas — paprastai tunelis, dengta aikštelė arba tankus miesto kanjonas.';

  @override
  String get gpsCoverageHintUnknown =>
      'Šioje kelionėje nėra informacijos apie programos būseną spragos metu, todėl priežasties nustatyti negalima.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'OBD2 pakartotinio prisijungimo trikdžiai';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Spraga sutampa su OBD2 pakartotinio prisijungimo epizodu — adapterio ryšys atsistatinėjo, o GPS priėmimas sustojo. Sutvarkius adapterio ryšį sutvarkomas ir pėdsakas.';

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
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Didžiausia spraga: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Atnaujinta';

  @override
  String get gpsLifecyclePaused => 'Pristabdyta';

  @override
  String get gpsLifecycleInactive => 'Neaktyvi';

  @override
  String get gpsKpiVerdictGood => 'Efektyvus';

  @override
  String get gpsKpiVerdictModerate => 'Vidutinis';

  @override
  String get gpsKpiVerdictAggressive => 'Agresyvus';

  @override
  String get gpsKpiInterpretationGood =>
      'Sklandus, energiją taupantis važiavimas — taip atrodo efektyvumas.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Gana įprastas važiavimas — šiek tiek švelniau spaudžiant akceleratorių būtų sutaupyta daugiau.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Daug energijos reikalaujantis važiavimas — atleidus akceleratorių ir daugiau riedant sumažėtų degalų sąnaudos.';

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
      'GPS įvertinimas (~) — šioje kelionėje nėra kuro jutiklio. Skaičius modeliuojamas pagal greitį ir jūsų transporto priemonės kalibravimą; tikslumas gerėja matricai brendant.';

  @override
  String get gpsRoadUseCardTitle => 'Kaip naudojote kelią';

  @override
  String get gpsRoadUseSpeedSection => 'Kur praleidote laiką';

  @override
  String get gpsRoadUseSpeedIdle => 'Stovima (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Miestas (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Užmiestis (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Greitai (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Kaip judėjote';

  @override
  String get gpsRoadUsePhaseAccel => 'Greitėjimas';

  @override
  String get gpsRoadUsePhaseSteady => 'Pastovus greitis';

  @override
  String get gpsRoadUsePhaseCoast => 'Riedėjimas';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Daug riedėjimo — leisti automobiliui riedėti užuot stabdžius taupo degalus. Puiku.';

  @override
  String get gpsRoadUseSource => 'Iš jūsų GPS pėdsako';

  @override
  String get hapticEcoCoachSettingTitle => 'Realaus laiko eko mokymas';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Švelnus haptikas ir ekrane rodomas patarimas, kai pilnai spaudžiate pedalą kruizinio valdymo metu';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Atsargiau su akseleratoriumi — inercinė eiga taupo daugiau';

  @override
  String highwayViaExit(String ref, String km) {
    return 'per išvažiavimą $ref · +$km km';
  }

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
  String get consentSyncTripsAnonymousHint =>
      'Kelionių atsarginės kopijos saugomos šio įrenginio anoniminėje paskyroje. Prisijunkite el. paštu, kad jas pasiektumėte iš kitų įrenginių.';

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
  String get accelBrakeCardTitle => 'Greičio didinimas ir stabdymas';

  @override
  String get accelBrakeHardAccel => 'Staigūs greičio didinimo įvykiai';

  @override
  String get accelBrakeHardBrake => 'Staigūs stabdymai';

  @override
  String get accelBrakeSharpCorner => 'Staigūs posūkiai';

  @override
  String get accelBrakeSource => 'Iš telefono judesio jutiklių';

  @override
  String lessonHardBrake(String count) {
    return '$count staigaus stabdymo įvykiai';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Numatykite sustojimus ir anksčiau pakelkite koją nuo akceleratoriaus — staigus stabdymas išeikvoja kurą, kurį ką tik sunaudojote greičiui įgauti.';

  @override
  String lessonSharpCornering(String count) {
    return '$count staigių posūkių';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Lėtinkite prieš posūkį, o ne jame — staigus posūkis sumažina greitį, kurį tada reikia atgauti.';

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
  String get consumptionMonthlyClimbLabel => 'Pakopyta';

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
  String get obd2DiagnosticsTitle => 'OBD2 ryšio sveikata';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops nutrūkimų',
      one: '1 nutrūkimas',
      zero: 'be nutrūkimų',
    );
    return '$percent% baigta · $duty% darbo ciklas · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapteris';

  @override
  String get obd2DiagnosticsConnectionSection => 'Ryšio gyvavimo ciklas';

  @override
  String get obd2DiagnosticsPidSection => 'PID rezultatai';

  @override
  String get obd2DiagnosticsReconnectSection =>
      'Pakartotinio prisijungimo telemetrija';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts pakartotinio prisijungimo bandymai · $successes sėkmingi · $transitions perėjimai · $disconnects klasifikuoti atsijungimai';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'Šioje sesijoje įjungtas atsarginis tik GPS režimas.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Planuotojo sveikata';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Pilnumas';

  @override
  String get obd2DiagnosticsSupportSection => 'Aptikti palaikomi PID';

  @override
  String get obd2DiagnosticsFuelSection => 'Kuro lygmens suvestinė';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protokolas $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts bandymai · $successes sėkmingi · $drops nutrūkimai · prisijungimo laikas p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Pakartotiniai prisijungimai: $silent tylūs · $visible matomi';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz dažnis · $skips praleidimai · $demotions žeminimai';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Dinamikos lygmuo išsekęs — RPM / greitis nukrito žemiau ribos.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Iš viso $percent% · aktyvus darbo ciklas $duty%';
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
    return '$supported palaikoma · $unsupported nepalaikoma · $unknown nežinoma';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Įtartina $suspicious iš $total pavyzdžių';
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
    return '$pid: $polled apklausta · $ok gerai · $noData ND · $timeout TO · $error kl. · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Donglo inicijavimo stenograma';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokolas $protocol · $start · programinė įranga $firmware · $tier · $pids PID';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'šiltas';

  @override
  String get obd2DiagnosticsInitCold => 'šaltas';

  @override
  String get obd2DiagnosticsEmpty =>
      'OBD2 sesija dar neįrašyta — prijunkite adapterį ir įrašykite kelionę su įjungtu kūrėjo režimu.';

  @override
  String get obd2DiagnosticsExplain =>
      'Užfiksuota įrašymo metu, siekiant derinti donglo↔programos ryšį — renkama tik kūrėjo režimu.';

  @override
  String get obd2HealthScreenTitle => 'OBD2 ryšio sveikata';

  @override
  String get obd2HealthNavLabel => 'OBD2 ryšio sveikata';

  @override
  String get obd2HealthLiveSection => 'Gyva sesija';

  @override
  String get obd2HealthHistorySection => 'Paskutinės sesijos';

  @override
  String get obd2HealthDownloadJson => 'Atsisiųsti kaip JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Atsisiųsti tik inicijavimo išrašą';

  @override
  String get obd2HealthDownloadError => 'Nepavyko išsaugoti diagnostikos failo';

  @override
  String get obd2TestAdapterLabel => 'Tikrinamas adapteris';

  @override
  String get obd2TestAdapterScanOption => 'Ieškoti adapterio';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Jungiamasi prie $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Paleisti adapterio testą';

  @override
  String get obd2TestRunButton => 'Paleisti adapterio testą';

  @override
  String get obd2TestRunPassed => 'Adapterio testas praėjo';

  @override
  String get obd2TestRunFailed => 'Adapterio testas nepavyko';

  @override
  String get obd2TestRunEngineOff =>
      'Adapteris veikia — variklis išjungtas; užveskite variklį, kad nuskaitytumėte tiesioginius duomenis';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed iš $total žingsnių gerai · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Sustabdykite aktyvų įrašymą prieš paleisdami adapterio testą.';

  @override
  String get obd2TestStepScan => 'Ieškoti adapterio';

  @override
  String get obd2TestStepBluetooth => 'Telefono „Bluetooth“';

  @override
  String get obd2TestStepConnect => 'Prisijungti ir inicijuoti';

  @override
  String get obd2TestStepInfo => 'Adapterio informacija';

  @override
  String get obd2TestStepSupportedPids => 'Palaikomi PID';

  @override
  String get obd2TestStepProtocol => 'Automobilio protokolas';

  @override
  String get obd2TestStepSampleReads => 'Bandomieji nuskaitymai';

  @override
  String get obd2TestStepSoak => 'Ilgalaikė apklausa';

  @override
  String get obd2TestStepReconnect => 'Pakartotinio prisijungimo testas';

  @override
  String get obd2TestStepDisconnect => 'Atjungti';

  @override
  String get obd2TestStatusOk => 'Gerai';

  @override
  String get obd2TestStatusTimeout => 'Baigėsi laikas';

  @override
  String get obd2TestStatusGarbage => 'Neįskaitomas atsakymas';

  @override
  String get obd2TestStatusNoResponse => 'Nėra atsakymo';

  @override
  String get obd2TestStatusFail => 'Nepavyko';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown =>
      'nežinoma — pagal numatytuosius BLE';

  @override
  String get obd2HealthConnectAttemptsSection =>
      'Paskutiniai prisijungimo bandymai';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Prisijungimo bandymų dar neužfiksuota.';

  @override
  String get obd2HealthDownloadConnectTrace =>
      'Atsisiųsti prisijungimo žurnalą';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Atsisiųsti visus prisijungimo žurnalus';

  @override
  String get obd2HealthConnectOrigin => 'Šaltinis';

  @override
  String get obd2HealthConnectTransport => 'Perdavimas';

  @override
  String get obd2HealthConnectOutcome => 'Rezultatas';

  @override
  String get obd2HealthConnectScanList => 'Aptikti įrenginiai';

  @override
  String get obd2HealthConnectSteps => 'Žingsniai';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Nežinomas adapteris';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Sesija įrašyta · $samples variklio matavimų · $percent% aprėptis';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'Ką ši kelionė įrašė';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples iš $total matavimų turėjo variklio duomenų ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapteris: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Protokolo suderinimas: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Sesija baigėsi: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Sesijos trukmė: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Sąnaudų duomenys gauti iš adapterio, o ne iš GPS įverčių.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Ryšio detalės pagal PID šiai kelionei nebuvo užfiksuotos. Kad jas surinktum, prieš įrašymą įjunk kūrėjo režimą.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nepavyko pasiekti \"$adapterName\" — pasirinkite kitą adapterį';
  }

  @override
  String get obd2PickerOtherDevices => 'Kiti „Bluetooth“ įrenginiai';

  @override
  String get obd2PickerTapToTry =>
      'Neatpažintas — bakstelėkite, kad išbandytumėte';

  @override
  String get obd2PickerBleOnlyNotice =>
      '„iPhone“ veikia tik su „Bluetooth LE“ adapteriais. Tik „Classic“ palaikantį adapterį (pvz., „vLinker BM“, „Konnwei KW902“) reikia naudoti su „Android“.';

  @override
  String get obd2PairingConfirmHint =>
      'Patvirtinkite susiejimo užklausą telefone';

  @override
  String get obd2ScanEmptyTitle => 'Adapteris nerastas';

  @override
  String get obd2ScanEmptyReady =>
      '„Bluetooth“ įjungtas ir leidimai suteikti. Įsitikinkite, kad adapteris įjungtas į OBD2 lizdą ir įjungtas degimas, tada ieškokite dar kartą.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Šis įrenginys neturi „Bluetooth Low Energy“ aparatinės įrangos, todėl negali prisijungti prie OBD2 adapterio.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      '„Bluetooth“ išjungtas. Įjunkite jį, kad ieškotumėte adapterio.';

  @override
  String get obd2ScanBlockedPermission =>
      '„Sparkilo“ reikia „Bluetooth“ leidimo, kad rastų jūsų adapterį.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      '„Bluetooth“ leidimas atmestas visam laikui. Suteikite jį sistemos nustatymuose, kad ieškotumėte adapterio.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Šiame įrenginyje vietos paslaugos išjungtos. „Android“ reikalauja jas įjungti ieškant „Bluetooth“ adapterių — jokia vieta neįrašoma ir nebendrinama.';

  @override
  String get obd2ScanOpenSettings => 'Atidaryti nustatymus';

  @override
  String get obd2WaitingForEngineBanner => 'Laukiama variklio — įrašoma GPS';

  @override
  String get obd2StartEngineToReconnect =>
      'Užveskite variklį, kad prisijungtumėte iš naujo';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Variklis išjungtas — užveskite jį, kad prisijungtumėte iš naujo';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Variklis išjungtas jau $minutes min — sustabdyti įrašymą?';
  }

  @override
  String get obd2ParkedPromptStop => 'Sustabdyti';

  @override
  String get obd2ParkedPromptKeep => 'Tęsti';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Variklis buvo išjungtas pirmąsias $head ir paskutines $tail šios kelionės — aprėptis matuojama varikliui veikiant.';
  }

  @override
  String get obd2ReconnectInProgress =>
      'Iš naujo jungiamasi prie OBD2 adapterio…';

  @override
  String get obd2StatusEngineOff => 'OBD2 pristabdytas — variklis išjungtas';

  @override
  String get obd2StatusEngineOffBody =>
      'Adapteris buvo pasiekiamas, bet automobilio magistralė tylėjo, todėl automatinis pakartotinis prisijungimas pristabdytas. Jis atsinaujina, kai važiuojate arba vėl atidarote programą — arba prisijunkite iš naujo dabar.';

  @override
  String get obd2StatusReconnectNow => 'Prisijungti iš naujo dabar';

  @override
  String get autoRecordNotificationTitle => 'Automatinis kelionių įrašymas';

  @override
  String get autoRecordNotificationText => 'Laukiama jūsų OBD2 adapterio';

  @override
  String get obd2ResetConnection => 'Atstatyti ryšį';

  @override
  String get obd2ResetConnectionDone => 'Adapteris atstatytas — ryšys atkurtas';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapteris atstatytas — iš naujo jungiamasi fone';

  @override
  String get ocrTesterTitle => 'OCR testeris';

  @override
  String get ocrTesterNavLabel => 'OCR testeris';

  @override
  String get ocrTesterExplain =>
      'Paleiskite degalų skaitiklio / kvito OCR vamzdyną ant pasirinktos nuotraukos ir tikrinkite kiekvieną žingsnį — tik kūrėjo režimu.';

  @override
  String get ocrTesterCapture => 'Fotografuoti';

  @override
  String get ocrTesterPickImage => 'Pasirinkti vaizdą';

  @override
  String get ocrTesterRun => 'Paleisti';

  @override
  String get ocrTesterCountry => 'Šalis';

  @override
  String get ocrTesterCountryNone => 'Numatytasis (be profilio)';

  @override
  String get ocrTesterNoImage =>
      'Pasirinkite arba fotografuokite vaizdą, tada paleiskite.';

  @override
  String get ocrTesterRunning => 'Vykdomas OCR…';

  @override
  String get ocrTesterOverlaySection => 'Bloko perdanga';

  @override
  String get ocrTesterStepsSection => 'Vamzdyno žingsniai';

  @override
  String get ocrTesterLegendLabel => 'Etiketė';

  @override
  String get ocrTesterLegendNumeric => 'Skaitinis';

  @override
  String get ocrTesterLegendNoise => 'Triukšmas';

  @override
  String get ocrTesterLegendDerived => 'Išvestinis';

  @override
  String get ocrTesterStageGlare => 'Fotografavimas / atspindys';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klasifikuoti';

  @override
  String get ocrTesterStageAssemble => 'Surinkti';

  @override
  String get ocrTesterStageAnchor => 'Inkaras';

  @override
  String get ocrTesterStageFallback => 'Atsarginė priemonė';

  @override
  String get ocrTesterStageCrossCheck => 'Kryžminis patikrinimas';

  @override
  String get ocrTesterStageConfidence => 'Pasitikėjimas';

  @override
  String get ocrTesterStageGate => 'Vartai';

  @override
  String get ocrTesterStageBrand => 'Prekės ženklas';

  @override
  String get ocrTesterStageOverrides => 'Nepaisymai';

  @override
  String get ocrTesterStageReconcile => 'Derinimas';

  @override
  String get ocrTesterStageResult => 'Rezultatas';

  @override
  String get ocrTesterChipRead => 'NUSKAITYTAS';

  @override
  String get ocrTesterChipDerived => 'IŠVESTINIS';

  @override
  String get ocrTesterGateAccepted => 'Priimta';

  @override
  String get ocrTesterGateRejected => 'Atmesta';

  @override
  String get ocrTesterFallbackBanner =>
      'Laukas atkurtas naudojant atsarginę dydžio priemonę — patikrinkite.';

  @override
  String get ocrTesterStageNoData => 'Etapas nebuvo vykdytas.';

  @override
  String get ocrTesterCopyJson => 'Kopijuoti kaip JSON';

  @override
  String get ocrTesterExportPackage => 'Eksportuoti paketą';

  @override
  String get ocrTesterCopied => 'OCR sekimas nukopijuotas į iškarpinę.';

  @override
  String get ocrTesterExported =>
      'OCR paketas išsaugotas jūsų atsisiuntimų aplanke.';

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
  String get onboardingObd2ConnectFailed =>
      'Nepavyko prisijungti prie adapterio. Galite bandyti dar kartą arba praleisti.';

  @override
  String get onboardingPickUseMode =>
      'Norėdami tęsti, pasirinkite naudojimo režimą.';

  @override
  String get onboardingObd2LaterNote =>
      '„Bluetooth“ OBD2 adapterį galite susieti bet kada vėliau automobilio ekrane, kad įrašytumėte keliones ir skaitytumėte variklio duomenis.';

  @override
  String get openNow => 'Atidaryta';

  @override
  String get openNowClosed => 'Uždaryta';

  @override
  String get openHoursUnknown => 'Darbo laikas nežinomas';

  @override
  String closesAt(String time) {
    return 'Uždaroma $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Atidaroma $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Atidaroma $time';
  }

  @override
  String get open24Hours => 'Atidaryta 24 val.';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => '24/7 automatizuoti';

  @override
  String get dayMon => 'Pirmadienis';

  @override
  String get dayTue => 'Antradienis';

  @override
  String get dayWed => 'Trečiadienis';

  @override
  String get dayThu => 'Ketvirtadienis';

  @override
  String get dayFri => 'Penktadienis';

  @override
  String get daySat => 'Šeštadienis';

  @override
  String get daySun => 'Sekmadienis';

  @override
  String get dayShortMon => 'Pr';

  @override
  String get dayShortTue => 'An';

  @override
  String get dayShortWed => 'Tr';

  @override
  String get dayShortThu => 'Kt';

  @override
  String get dayShortFri => 'Pn';

  @override
  String get dayShortSat => 'Št';

  @override
  String get dayShortSun => 'Sk';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Valstybinės šventės';

  @override
  String get closedLabel => 'Uždaryta';

  @override
  String get openingHoursNotAvailable => 'Darbo laikas neprieinamas';

  @override
  String get showAllHours => 'Rodyti visą darbo laiką';

  @override
  String get showLessHours => 'Rodyti mažiau';

  @override
  String get openStateUnknown => 'Nežinoma';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Degalinė atidaryta',
      'false': 'Degalinė uždaryta',
      'other': 'Darbo būsena nežinoma',
    });
    return '$_temp0';
  }

  @override
  String get tripRecordingPipEstConsumptionCaption => 'įvert. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Įvertinta reikšmė (~) — šioje kelionėje nėra kuro jutiklio, todėl L/100 km skaičius modeliuojamas pagal GPS greitį ir jūsų transporto priemonės kalibravimą. Tai apytikslis dydis (paprastai ±10–30 %, tikslėjantis kalibravimui brendant), o ne išmatuota reikšmė.';

  @override
  String get tripRecordingPipElapsedCaption => 'praėjo';

  @override
  String get qrLaunchConfirmTitle => 'Atidaryti nuskaitytą nuorodą?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Šis QR kodas nukreipia į $host. Atidarykite tik nuorodas, kuriomis pasitikite.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Atidaryti nuorodą';

  @override
  String get qrLaunchConfirmCancel => 'Atšaukti';

  @override
  String get radarPinHelpTitle => 'Apie prisegimą';

  @override
  String get radarPinHelpBody =>
      'Prisegimu ekranas lieka įjungtas ir slepiami sistemos juosteliai, kad artimiausios degalinės duomenys liktų matomi ant prietaisų skydelio. Palieskite dar kartą, kad atleistumėte. Automatiškai atleidžiama sustabdžius radarą.';

  @override
  String get radarAutoPinTitle => 'Visada prisegti radaro paleidimo metu';

  @override
  String get radarAutoPinSubtitle =>
      'Radarą prisegti automatiškai kiekvieną kartą, o ne liesti kiekvieną kartą. Naudoja daugiau akumuliatoriaus.';

  @override
  String get radarScopeShowScope => 'Radaro rodinys';

  @override
  String get radarScopeShowList => 'Sąrašo rodinys';

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
  String get reconcileWorkflowTitle => 'Suderinkite savo kurą';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Aptikome $gap L skirtumą';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Jūs pripylėte $pumped L, tačiau jūsų užregistruotos kelionės paaiškina tik $consumed L. Lieka $gap L nepaaiškintų.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Dažniausiai tai reiškia, kad vienas vairavimas nebuvo užregistruotas (adapteris buvo atjungtas arba programa uždaryta) arba trūksta ar neteisingai įvesti papildymo duomenys.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Kol tai neišspręsta, jūsų kuro suma ir kelionių suma nesutaps.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Padėkite priskirti skirtumą';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Ar visi šio bako papildymai yra pilni ir teisingi?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Ar visi jūsų važiavimai yra užregistruoti?';

  @override
  String get reconcileWorkflowAnswerYes => 'Taip';

  @override
  String get reconcileWorkflowAnswerNo => 'Ne';

  @override
  String get reconcileWorkflowPathAHint =>
      'Trūksta papildymo arba jis neteisingas — pridėsime pataisymą, kad jūsų papildymai sutaptų.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Jūsų papildymai teisingi, o vienas važiavimas nebuvo užregistruotas — pridėsime virtualią kelionę trūkstamam atstumui.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Pataisymo litrai';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Koks buvo neužregistruoto važiavimo atstumas? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Nuspręsti vėliau';

  @override
  String get reconcileWorkflowBack => 'Atgal';

  @override
  String get reconcileWorkflowNext => 'Toliau';

  @override
  String get reconcileWorkflowApply => 'Taikyti';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Virtuali kelionė — palieskite norėdami redaguoti';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Redaguoti virtualią kelionę';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Ši kelionė pridėta norint atsiskaityti už kurą, sunaudotą važiuojant be įrašymo. Pakoreguokite atstumą ar kurą arba ištrinkite.';

  @override
  String get reconcileVirtualTrajetDelete => 'Ištrinti virtualią kelionę';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Neišspręstas $gap L kuro/kelionių skirtumas — palieskite norėdami išspręsti';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Išspręsti neišspręstą kuro ir kelionių skirtumą';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesija';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Šis failo tipas dar negali būti importuotas — vietoj to bendrinkite kvito nuotrauką.';

  @override
  String get shareReceiptFailed =>
      'Nepavyko perskaityti bendrinamo kvito — bandykite bendrinti dar kartą arba pridėkite papildymą rankiniu būdu.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Bendrinkite kvitą importuoti';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Bendrinkite kvito nuotrauką iš kitos programos, kad iš anksto užpildytumėte papildymą — data, litrai, suma ir degalinė nuskaitomi įrenginyje.';

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
  String syncAdoptTitle(String email) {
    return 'Prisijungti prie $email paskyros';
  }

  @override
  String get syncAdoptSubtitle =>
      'Prisijunkite šios paskyros slaptažodžiu, kad jos duomenys būtų bendrinami abiejuose įrenginiuose.';

  @override
  String get syncAdoptPasswordLabel => 'Paskyros slaptažodis';

  @override
  String get syncAdoptJoinButton => 'Prisijungti prie paskyros';

  @override
  String get syncAdoptUseDifferentAccount => 'Naudoti kitą paskyrą';

  @override
  String get syncDeleteDataTitle => 'Ištrinti sinchronizuotus duomenis';

  @override
  String get syncDeleteDataSubtitle =>
      'Pašalinkite savo keliones, transporto priemones arba pildymus iš sinchronizavimo duomenų bazės';

  @override
  String get syncDeleteDataPickTitle =>
      'Kuriuos sinchronizuotus duomenis ištrinti?';

  @override
  String get syncDeleteDataCategoryTrips => 'Kelionės';

  @override
  String get syncDeleteDataCategoryVehicles => 'Transporto priemonės';

  @override
  String get syncDeleteDataCategoryFillUps => 'Pildymai';

  @override
  String get syncDeleteDataCategoryEverything => 'Viską';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Ištrinti $category iš sinchronizavimo duomenų bazės?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Pasirinkti duomenys bus pašalinti iš jūsų sinchronizavimo duomenų bazės ir nebebus sinchronizuojami iš kitų įrenginių. Šiame įrenginyje vietoje saugomi duomenys išlieka.';

  @override
  String get syncDeleteDataConfirmAction => 'Ištrinti iš serverio';

  @override
  String get syncDeleteDataDone => 'Sinchronizuoti duomenys ištrinti';

  @override
  String get syncDeleteDataFailed =>
      'Nepavyko ištrinti sinchronizuotų duomenų — bandykite dar kartą';

  @override
  String get syncRelinkTitle =>
      'Debesies sinchronizavimą reikia susieti iš naujo';

  @override
  String get syncRelinkBody =>
      'Šio įrenginio išsaugota sinchronizavimo tapatybė atsijungusi. Prisijunkite el. paštu, kad iš naujo susietumėte sinchronizuotus duomenis, arba pradėkite iš naujo su nauja tapatybe.';

  @override
  String get syncRelinkSignInAction => 'Prisijungti ir susieti iš naujo';

  @override
  String get syncRelinkStartFreshAction => 'Pradėti iš naujo';

  @override
  String get syncRelinkStartFreshTitle => 'Pradėti iš naujo?';

  @override
  String get syncRelinkStartFreshBody =>
      'Šiam įrenginiui bus sukurta nauja anoniminė tapatybė. Su senąja tapatybe sinchronizuoti duomenys lieka serveryje, bet iš čia nebebus pasiekiami, nebent prisijungsite jos el. pašto paskyra.';

  @override
  String get syncRelinkStartFreshConfirm => 'Pradėti iš naujo';

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
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km pagal paskutinio bako sąnaudas';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Ilgalaikis vidurkis: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Paskutinis tankavimas: $date · $count kelionė(s) nuo tada';
  }

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
  String tankLevelSourceFillUp(String date) {
    return 'Pririšta prie paskutinio pildymo: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'OBD2 bako jutiklis · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Bako mišinys: $mix';
  }

  @override
  String get tankReportTitle => 'Bako ataskaita';

  @override
  String tankReportHeadline(String value) {
    return '$value L/100 km';
  }

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Nuo ankstesnio pilno bako: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km daugiau nei ankstesnis bakas';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km mažiau nei ankstesnis bakas';
  }

  @override
  String get tankReportTrendFlat => 'Tiek pat, kiek ankstesnis bakas';

  @override
  String get tankReportNoPrevious => 'Pokytis bus rodomas po kito pilno bako.';

  @override
  String tankReportCoverage(String pct) {
    return 'Įrašai apima $pct % šio bako';
  }

  @override
  String tankReportRecordedAvg(String value) {
    return 'Įrašyta dalis: $value L/100 km';
  }

  @override
  String get tankReportExplainHeader => 'Ką rodo įrašai';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Aukštų apsukų dalis $cur % (buvo $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Staigūs manevrai $cur/100 km (buvo $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Šalti paleidimai $cur (buvo $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Tuščiosios eigos dalis $cur % (buvo $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Įrašai atsitiktiniai ir apima tik dalį šio bako — šios užuominos orientacinės, ne visa istorija.';

  @override
  String tankReportCalibrationUnder(String pct) {
    return 'Įrašyti įverčiai $pct % mažesni už kolonėlės rodmenį';
  }

  @override
  String tankReportCalibrationOver(String pct) {
    return 'Įrašyti įverčiai $pct % viršija kolonėlės rodmenį';
  }

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
  String get tripSaveProgressFinalizingSummary => 'Baigiama suvestinė…';

  @override
  String get tripSaveProgressSavingToHistory => 'Išsaugoma istorijoje…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Sinchronizuojama fone…';

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
  String get trajetDetailChartThrottle => 'Dujų pedalas (%)';

  @override
  String get trajetDetailChartCoolant => 'Aušinimo skystis (°C)';

  @override
  String get trajetDetailChartAltitudeRelative => 'Aukštis (m, nuo starto)';

  @override
  String get trajetDetailChartLambda => 'Nurodytas λ';

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
  String get trajetDetailChartEstimatedBadge => 'įvertinta';

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
  String get trajetDetailDownloadCsvOption => 'Atsisiųsti telemetriją (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Atsisiųsti telemetriją (JSON)';

  @override
  String get trajetDetailDownloadError => 'Nepavyko išsaugoti failo';

  @override
  String get trajetDetailDeleteAction => 'Ištrinti';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Ištrinti šią kelionę?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ši kelionė bus visam laikui pašalinta iš jūsų istorijos.';

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
  String get trajetDetailChartBoost => 'Pripūtimo slėgis (MAP − aplinkos)';

  @override
  String get trajetDetailChartIat => 'Įsiurbiamo oro temperatūra';

  @override
  String get trajetDetailChartTiming => 'Uždegimo paankstinimas';

  @override
  String get trajetObd2Degraded =>
      'Pradėta su OBD2 adapteriu, bet įrašyta daugiausia per GPS — variklio duomenys nepilni';

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
  String get tripPathLegendEfficient => 'Efektyvus (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Ribinis (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Švaistymas (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Degalinių radaras';

  @override
  String get tripRadarScanning => 'Ieškoma netoliese esančių degalinių';

  @override
  String get tripRadarNoStationNearby => 'Netoliese nėra degalinių';

  @override
  String get fuelStationRadarNearer => 'Artimesnė degalinė';

  @override
  String get fuelStationRadarFarther => 'Tolimesnė degalinė';

  @override
  String get fuelStationRadarStart => 'Paleisti degalinių radarą';

  @override
  String get stopRadar => 'Sustabdyti radarą';

  @override
  String get fuelStationRadarResultBadge => 'Degalinių radaro rezultatas';

  @override
  String get radarUpdatingLocation => 'Atnaujinama jūsų vieta…';

  @override
  String get radarSearching => 'Ieškoma…';

  @override
  String get highwayModeChip =>
      'Greitkelio režimas — rodomos degalinės priešais jus maršrute';

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
  String get tripRecordingSavingTitle => 'Išsaugoma kelionė…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Įrašas atmestas — judėjimas neaptiktas';

  @override
  String get tripRecordingGpsNotificationTitle => 'Įrašoma jūsų kelionė';

  @override
  String get tripRecordingGpsNotificationText =>
      'Sekamas jūsų maršrutas degalų ir vairavimo statistikai';

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
  String get tripVerdictPromptTitle => 'Kokia buvo ši kelionė?';

  @override
  String get tripVerdictSmooth => 'Sklandi';

  @override
  String get tripVerdictModerate => 'Vidutinė';

  @override
  String get tripVerdictAggressive => 'Agresyvi';

  @override
  String get tripVerdictDismiss => 'Ne dabar';

  @override
  String get tripVerdictThanks =>
      'Ačiū — tai padeda kalibruoti jūsų vairavimo analizę.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Pildymas ištrintas';

  @override
  String get trajetDeletedUndoSnackbar => 'Įrašas ištrintas';

  @override
  String get searchFailedSnackbar => 'Paieška nepavyko — bandykite dar kartą';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count degalinių',
      one: '1 degalinė',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Atnaujinta $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Taip pat: $names';
  }

  @override
  String get favoriteAdd => 'Pridėti prie mėgstamų';

  @override
  String get favoriteRemove => 'Pašalinti iš mėgstamų';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Pradinė: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Degalinė be prekės ženklo';

  @override
  String get unsupportedRegionTitle => 'Jūsų regione dar nepasiekiama';

  @override
  String get unsupportedRegionBody =>
      'Jūsų šalies degalų kainų dar neturime, todėl rezultatai gali būti tušti arba iš kitos šalies. Vis tiek galite pasirinkti palaikomą šalį paieškos nustatymuose.';

  @override
  String get unsupportedRegionDismiss => 'Supratau';

  @override
  String get configureCountryTitle => 'Nustatykite savo šalį';

  @override
  String get configureCountryBody =>
      'Jūsų šalis palaikoma, bet dar nenustatyta — todėl kainos gali būti iš kitos šalies. Pasirinkite savo šalį paieškos nustatymuose, kad matytumėte vietines kainas.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Galiu pilti skirtingų rūšių degalus';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Seka, kurie degalai pigiausi už kilometrą';

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
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Aptikta iš VIN: $summary. Taikyti?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Taikyti';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometrų į priekį, $fuelType $euros eurai $cents';
  }

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
}
