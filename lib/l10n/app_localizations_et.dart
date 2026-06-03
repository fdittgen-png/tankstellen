// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

  @override
  String get search => 'Otsi';

  @override
  String get favorites => 'Lemmikud';

  @override
  String get map => 'Kaart';

  @override
  String get profile => 'Profiil';

  @override
  String get settings => 'Seaded';

  @override
  String get gpsLocation => 'GPS asukoht';

  @override
  String get zipCode => 'Postiindeks';

  @override
  String get zipCodeHint => 'nt. 10111';

  @override
  String get fuelType => 'Kütus';

  @override
  String get searchRadius => 'Raadius';

  @override
  String get searchNearby => 'Lähedalolevad tankla';

  @override
  String get searchButton => 'Otsi';

  @override
  String get fabOpenCriteria => 'Ava otsing';

  @override
  String get fabOpenResults => 'Ava tulemused';

  @override
  String get fabRunSearch => 'Käivita otsing';

  @override
  String get fabRefineCriteria => 'Täpsusta otsingut';

  @override
  String get routeSearchPartialBanner => 'Otsitakse rohkem jaamu…';

  @override
  String get routeSearchingChip => 'Searching the route…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Every $km km';
  }

  @override
  String get searchCriteriaTitle => 'Otsinguparameetrid';

  @override
  String get searchCriteriaOpen => 'Otsi';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km raadiuses';
  }

  @override
  String get searchCriteriaTapToSearch => 'Puuduta otsimise alustamiseks';

  @override
  String get noResults => 'Tanklasid ei leitud.';

  @override
  String get startSearch => 'Otsige tanklasid.';

  @override
  String get open => 'Avatud';

  @override
  String get closed => 'Suletud';

  @override
  String distance(String distance) {
    return '$distance kaugusel';
  }

  @override
  String get price => 'Hind';

  @override
  String get prices => 'Hinnad';

  @override
  String get address => 'Aadress';

  @override
  String get openingHours => 'Lahtiolekuajad';

  @override
  String get open24h => 'Avatud 24 tundi';

  @override
  String get navigate => 'Navigeeri';

  @override
  String get retry => 'Proovi uuesti';

  @override
  String get apiKeySetup => 'API võti';

  @override
  String get apiKeyDescription =>
      'Registreeruge üks kord tasuta API võtme saamiseks.';

  @override
  String get apiKeyLabel => 'API võti';

  @override
  String get register => 'Registreerumine';

  @override
  String get continueButton => 'Jätka';

  @override
  String get welcome => 'Sparkilo';

  @override
  String get welcomeSubtitle => 'Leidke lähim odavaim kütus.';

  @override
  String get profileName => 'Profiili nimi';

  @override
  String get preferredFuel => 'Eelistatud kütus';

  @override
  String get defaultRadius => 'Vaikimisi raadius';

  @override
  String get landingScreen => 'Avakuva';

  @override
  String get homeZip => 'Kodu postiindeks';

  @override
  String get newProfile => 'Uus profiil';

  @override
  String get editProfile => 'Muuda profiili';

  @override
  String get save => 'Salvesta';

  @override
  String get cancel => 'Tühista';

  @override
  String get countryChangeTitle => 'Vaheta riiki?';

  @override
  String countryChangeBody(String country) {
    return 'Riigi vahetamine ($country) muudab:';
  }

  @override
  String get countryChangeCurrency => 'Valuuta';

  @override
  String get countryChangeDistance => 'Vahemaa';

  @override
  String get countryChangeVolume => 'Maht';

  @override
  String get countryChangePricePerUnit => 'Hinna formaat';

  @override
  String get countryChangeNote =>
      'Olemasolevaid lemmikuid ja tankimiskirjeid ei kirjutata ümber; ainult uued kanded kasutavad uusi ühikuid.';

  @override
  String get countryChangeConfirm => 'Vaheta';

  @override
  String get delete => 'Kustuta';

  @override
  String get activate => 'Aktiveeri';

  @override
  String get configured => 'Seadistatud';

  @override
  String get notConfigured => 'Seadistamata';

  @override
  String get about => 'Teave';

  @override
  String get openSource => 'Avatud lähtekood (MIT litsents)';

  @override
  String get sourceCode => 'Lähtekood GitHubis';

  @override
  String get noFavorites => 'Lemmikuid pole';

  @override
  String get noFavoritesHint =>
      'Puudutage tankla tähte, et salvestada see lemmikuks.';

  @override
  String get language => 'Keel';

  @override
  String get country => 'Riik';

  @override
  String get demoMode => 'Demorežiim — näidisandmed.';

  @override
  String get setupLiveData => 'Seadista reaalajas andmed';

  @override
  String get freeNoKey => 'Tasuta — võtit pole vaja';

  @override
  String get apiKeyRequired => 'API võti nõutud';

  @override
  String get skipWithoutKey => 'Jätka ilma võtmeta';

  @override
  String get dataTransparency => 'Andmete läbipaistvus';

  @override
  String get storageAndCache => 'Salvestusruum ja vahemälu';

  @override
  String get clearCache => 'Tühjenda vahemälu';

  @override
  String get clearAllData => 'Kustuta kõik andmed';

  @override
  String get errorLog => 'Vigade logi';

  @override
  String stationsFound(int count) {
    return 'Leiti $count tanklat';
  }

  @override
  String get whatIsShared => 'Mida jagatakse — ja kellega?';

  @override
  String get gpsCoordinates => 'GPS koordinaadid';

  @override
  String get gpsReason =>
      'Saadetakse iga otsinguga lähedalolevate jaamade leidmiseks.';

  @override
  String get postalCodeData => 'Postiindeks';

  @override
  String get postalReason =>
      'Teisendatakse koordinaatideks geokodeerimise teenuse kaudu.';

  @override
  String get mapViewport => 'Kaardi vaade';

  @override
  String get mapReason =>
      'Kaardi paanid laaditakse serverist. Isikuandmeid ei edastata.';

  @override
  String get apiKeyData => 'API võti';

  @override
  String get apiKeyReason =>
      'Teie isiklik võti saadetakse iga API päringuga. See on seotud teie e-postiga.';

  @override
  String get notShared => 'EI jagata:';

  @override
  String get searchHistory => 'Otsinguajalugu';

  @override
  String get favoritesData => 'Lemmikud';

  @override
  String get profileNames => 'Profiilide nimed';

  @override
  String get homeZipData => 'Kodu postiindeks';

  @override
  String get usageData => 'Kasutusandmed';

  @override
  String get privacyBanner =>
      'Sellel rakendusel pole serverit. Kõik andmed jäävad teie seadmesse. Pole analüütikat, jälgimist ega reklaame.';

  @override
  String get storageUsage => 'Salvestusruumi kasutus selles seadmes';

  @override
  String get settingsLabel => 'Seaded';

  @override
  String get profilesStored => 'salvestatud profiili';

  @override
  String get stationsMarked => 'märgitud tanklat';

  @override
  String get cachedResponses => 'vahemällu salvestatud vastust';

  @override
  String get total => 'Kokku';

  @override
  String get cacheManagement => 'Vahemälu haldus';

  @override
  String get cacheDescription =>
      'Vahemälu salvestab API vastuseid kiiremaks laadimiseks ja võrguühenduseta juurdepääsuks.';

  @override
  String get cacheTtlGroupNetwork => 'Võrk';

  @override
  String get cacheTtlGroupData => 'Andmed';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodeerimine';

  @override
  String get stationSearch => 'Jaamade otsing';

  @override
  String get stationDetails => 'Jaama üksikasjad';

  @override
  String get priceQuery => 'Hinnapäring';

  @override
  String get zipGeocoding => 'Postiindeksi geokodeerimine';

  @override
  String minutes(int n) {
    return '$n minutit';
  }

  @override
  String hours(int n) {
    return '$n tundi';
  }

  @override
  String get clearCacheTitle => 'Tühjenda vahemälu?';

  @override
  String get clearCacheBody =>
      'Vahemällu salvestatud otsingutulemused ja hinnad kustutatakse. Profiilid, lemmikud ja seaded säilitatakse.';

  @override
  String get clearCacheButton => 'Tühjenda vahemälu';

  @override
  String get deleteAllTitle => 'Kustuta kõik andmed?';

  @override
  String get deleteAllBody =>
      'See kustutab jäädavalt kõik profiilid, lemmikud, API võtme, seaded ja vahemälu. Rakendus lähtestatakse.';

  @override
  String get deleteAllButton => 'Kustuta kõik';

  @override
  String get entries => 'kirjet';

  @override
  String get cacheEmpty => 'Vahemälu on tühi';

  @override
  String get noStorage => 'Salvestusruum pole kasutuses';

  @override
  String get apiKeyNote =>
      'Tasuta registreerumine. Andmed riiklike hinnaläbipaistvuse asutuste käest.';

  @override
  String get apiKeyFormatError => 'Vigane vorming — oodatav UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Toetage seda projekti';

  @override
  String get supportDescription =>
      'See rakendus on tasuta, avatud lähtekoodiga ja reklaamivaba. Kui leiate selle kasulikuks, kaaluge arendaja toetamist.';

  @override
  String get reportBug => 'Teata veast / Soovita funktsiooni';

  @override
  String get reportThisIssue => 'Teata probleemist';

  @override
  String get reportAlreadySent => 'Oled sellest probleemist juba teatanud.';

  @override
  String get reportConsentTitle => 'Teata GitHubis?';

  @override
  String get reportConsentBody =>
      'See avab avaliku GitHubi vearaporti allpool toodud tõrke üksikasjadega. GPS-koordinaate, API-võtmeid ega isikuandmeid ei kaasata.';

  @override
  String get reportConsentConfirm => 'Ava GitHub';

  @override
  String get reportConsentCancel => 'Tühista';

  @override
  String get configProfileSection => 'Profiil';

  @override
  String get configActiveProfile => 'Aktiivne profiil';

  @override
  String get configPreferredFuel => 'Eelistatud kütus';

  @override
  String get configCountry => 'Riik';

  @override
  String get configRouteSegment => 'Marsruudi lõik';

  @override
  String get configApiKeysSection => 'API-võtmed';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-võti';

  @override
  String get configApiKeyConfigured => 'Seadistatud';

  @override
  String get configApiKeyNotSet => 'Määramata (demorežiim)';

  @override
  String get configApiKeyCommunity => 'Vaikimisi (ühenduse võti)';

  @override
  String get searchLocationPlaceholder => 'Aadress, sihtnumber või linn';

  @override
  String get configEvKey => 'EV laadimise API-võti';

  @override
  String get configEvKeyCustom => 'Kohandatud võti';

  @override
  String get configEvKeyShared => 'Vaikimisi (jagatud)';

  @override
  String get configCloudSyncSection => 'Pilvsünkroonimine';

  @override
  String get configTankSyncConnected => 'Ühendatud';

  @override
  String get configTankSyncDisabled => 'Keelatud';

  @override
  String get configAuthMode => 'Autentimisrežiim';

  @override
  String get configAuthEmail => 'E-post (püsiv)';

  @override
  String get configAuthAnonymous => 'Anonüümne (ainult seade)';

  @override
  String get configDatabase => 'Andmebaas';

  @override
  String get configPrivacySummary => 'Privaatsuse kokkuvõte';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Lemmikud, teatised ja ignoreeritud jaamad sünkroonitakse sinu privaatse andmebaasiga\n• GPS-asukoht ja API-võtmed ei lahku kunagi sinu seadmest\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Kõik andmed talletatakse ainult sellesse seadmesse\n• Serverisse ei saadeta ühtegi andmet\n• API-võtmed on krüpteeritud seadme turvalises salvestusruumis';

  @override
  String get configAuthNoteEmail =>
      'E-postkonto võimaldab juurdepääsu mitmest seadmest';

  @override
  String get configAuthNoteAnonymous =>
      'Anonüümne konto — andmed on seotud selle seadmega';

  @override
  String get configNone => 'Puudub';

  @override
  String get privacyPolicy => 'Privaatsuspoliitika';

  @override
  String get fuels => 'Kütused';

  @override
  String get services => 'Teenused';

  @override
  String get zone => 'Tsoon';

  @override
  String get highway => 'Kiirtee';

  @override
  String get localStation => 'Kohalik tankla';

  @override
  String get lastUpdate => 'Viimane uuendus';

  @override
  String get automate24h => '24t/24 — Automaat';

  @override
  String get refreshPrices => 'Uuenda hindu';

  @override
  String get station => 'Tankla';

  @override
  String get locationDenied =>
      'Asukoha luba keelatud. Saate otsida postiindeksi järgi.';

  @override
  String get demoModeBanner => 'Demorežiim. Seadistage API võti seadetes.';

  @override
  String get demoModeBannerAction => 'Hangi reaalajas hinnad';

  @override
  String get sortDistance => 'Kaugus';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Hinnang';

  @override
  String get sortPriceDistance => 'Hind/km';

  @override
  String get cheap => 'odav';

  @override
  String get expensive => 'kallis';

  @override
  String stationsOnMap(int count) {
    return '$count tanklat';
  }

  @override
  String get loadingFavorites =>
      'Lemmikute laadimine...\nOtsige kõigepealt tanklasid andmete salvestamiseks.';

  @override
  String get reportPrice => 'Teata hinnast';

  @override
  String get whatsWrong => 'Mis on valesti?';

  @override
  String get correctPrice => 'Õige hind (nt. 1,459)';

  @override
  String get sendReport => 'Saada teade';

  @override
  String get reportSent => 'Teade saadetud. Aitäh!';

  @override
  String get enterValidPrice => 'Sisestage kehtiv hind';

  @override
  String get cacheCleared => 'Vahemälu tühjendatud.';

  @override
  String get yourPosition => 'Teie asukoht';

  @override
  String get positionUnknown => 'Asukoht teadmata';

  @override
  String get routeModeBannerLabel =>
      'Marsruudi režiim — vahemaad on piki koridori';

  @override
  String get distancesFromCenter => 'Kaugused otsingu keskpunktist';

  @override
  String get autoUpdatePosition => 'Uuenda asukohta automaatselt';

  @override
  String get autoUpdateDescription => 'Uuenda GPS asukohta enne iga otsingut';

  @override
  String get location => 'Asukoht';

  @override
  String get switchProfileTitle => 'Riik muutus';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Olete nüüd riigis $country. Lülituda profiilile \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Lülitatud profiilile \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Selle riigi jaoks pole profiili';

  @override
  String noProfileForCountry(String country) {
    return 'Olete riigis $country, kuid profiili pole seadistatud. Looge see Seadetes.';
  }

  @override
  String get autoSwitchProfile => 'Automaatne profiili vahetamine';

  @override
  String get autoSwitchDescription =>
      'Vaheta profiili automaatselt piiri ületamisel';

  @override
  String profileSwitchedTo(String profile) {
    return 'Switched to $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profile $name created';
  }

  @override
  String profileCountryTaken(String country) {
    return 'A profile for $country already exists — edit it instead.';
  }

  @override
  String get switchProfile => 'Vaheta';

  @override
  String get dismiss => 'Sulge';

  @override
  String get profileCountry => 'Riik';

  @override
  String get profileLanguage => 'Keel';

  @override
  String get settingsStorageDetail => 'API võti, aktiivne profiil';

  @override
  String get allFuels => 'Kõik';

  @override
  String get priceAlerts => 'Hinnahoiatused';

  @override
  String get noPriceAlerts => 'Hinnahoiatusi pole';

  @override
  String get noPriceAlertsHint => 'Looge hoiatus jaama üksikasjade lehelt.';

  @override
  String alertDeleted(String name) {
    return 'Hoiatus \"$name\" kustutatud';
  }

  @override
  String get createAlert => 'Loo hinnahoiatus';

  @override
  String currentPrice(String price) {
    return 'Praegune hind: $price';
  }

  @override
  String get targetPrice => 'Sihthind (EUR)';

  @override
  String get enterPrice => 'Sisestage hind';

  @override
  String get invalidPrice => 'Kehtetu hind';

  @override
  String get priceTooHigh => 'Hind liiga kõrge';

  @override
  String get create => 'Loo';

  @override
  String get alertCreated => 'Hinnahoiatus loodud';

  @override
  String get wrongE5Price => 'Vale Super E5 hind';

  @override
  String get wrongE10Price => 'Vale Super E10 hind';

  @override
  String get wrongDieselPrice => 'Vale diiselkütuse hind';

  @override
  String get wrongStatusOpen => 'Näidatud avatuna, kuid suletud';

  @override
  String get wrongStatusClosed => 'Näidatud suletuna, kuid avatud';

  @override
  String get searchAlongRouteLabel => 'Marsruudi ääres';

  @override
  String get searchEvStations => 'Otsi laadimisjaamu';

  @override
  String get allStations => 'Kõik jaamad';

  @override
  String get bestStops => 'Parimad peatused';

  @override
  String get openInMaps => 'Ava Kaartides';

  @override
  String get noStationsAlongRoute => 'Marsruudi ääres jaamu ei leitud';

  @override
  String get evOperational => 'Töökorras';

  @override
  String get evStatusUnknown => 'Olek teadmata';

  @override
  String evConnectors(int count) {
    return 'Pistikud ($count punkti)';
  }

  @override
  String get evNoConnectors => 'Pistiku üksikasjad pole saadaval';

  @override
  String get evUsageCost => 'Kasutuskulu';

  @override
  String get evPricingUnavailable =>
      'Hinnateave teenusepakkujalt pole saadaval';

  @override
  String get evPriceFree => 'Free';

  @override
  String get evPricePayAtLocation => 'Pay at location';

  @override
  String get evPriceMembership => 'Membership required';

  @override
  String get evPriceIndicative => 'Indicative price';

  @override
  String get evPriceDeclaredByOperator =>
      'Indicative price declared by the operator — verify on site';

  @override
  String get evPriceFranceAttribution =>
      'Pricing: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Best-effort pricing from OpenChargeMap — sparse and may be incomplete.';

  @override
  String get evLastUpdated => 'Viimati uuendatud';

  @override
  String get evUnknown => 'Teadmata';

  @override
  String get evDataAttribution => 'Andmed OpenChargeMapist (kogukonnaallikas)';

  @override
  String get evStatusDisclaimer =>
      'Olek ei pruugi kajastada reaalajas saadavust. Puudutage uuenda, et saada uusimaid andmeid.';

  @override
  String get evNavigateToStation => 'Navigeeri jaama';

  @override
  String get evRefreshStatus => 'Uuenda olekut';

  @override
  String get evStatusUpdated => 'Olek uuendatud';

  @override
  String get evStationNotFound =>
      'Ei saanud uuendada — jaama ei leitud lähedusest';

  @override
  String get addedToFavorites => 'Lisatud lemmikutesse';

  @override
  String get removedFromFavorites => 'Eemaldatud lemmikutest';

  @override
  String get addFavorite => 'Lisa lemmikutesse';

  @override
  String get removeFavorite => 'Eemalda lemmikutest';

  @override
  String get currentLocation => 'Praegune asukoht';

  @override
  String get gpsError => 'GPS viga';

  @override
  String get couldNotResolve => 'Algus- või sihtpunkti ei saanud määrata';

  @override
  String get start => 'Algus';

  @override
  String get destination => 'Sihtkoht';

  @override
  String get cityAddressOrGps => 'Linn, aadress või GPS';

  @override
  String get cityOrAddress => 'Linn või aadress';

  @override
  String get useGps => 'Kasuta GPS-i';

  @override
  String get stop => 'Peatus';

  @override
  String stopN(int n) {
    return 'Peatus $n';
  }

  @override
  String get addStop => 'Lisa peatus';

  @override
  String get searchAlongRoute => 'Otsi marsruudi äärest';

  @override
  String get cheapest => 'Odavaim';

  @override
  String nStations(int count) {
    return '$count tanklat';
  }

  @override
  String nBest(int count) {
    return '$count parimat';
  }

  @override
  String get fuelPricesTankerkoenig => 'Kütusehinnad (Tankerkoenig)';

  @override
  String get requiredForFuelSearch => 'Vajalik kütusehinnaotsingurks Saksamaal';

  @override
  String get evChargingOpenChargeMap => 'EV laadimine (OpenChargeMap)';

  @override
  String get customKey => 'Kohandatud võti';

  @override
  String get appDefaultKey => 'Rakenduse vaikevõti';

  @override
  String get optionalOverrideKey =>
      'Valikuline: asendage sisseehitatud rakenduse võti enda omaga';

  @override
  String get requiredForEvSearch => 'Vajalik EV laadimisjaamade otsinguks';

  @override
  String get edit => 'Muuda';

  @override
  String get fuelPricesApiKey => 'Kütusehindade API võti';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API võti';

  @override
  String get evChargingApiKey => 'EV laadimise API võti';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API võti';

  @override
  String get routePlanningSection => 'Marsruudi planeerimine';

  @override
  String get routeMinSaving => 'Minimaalne kokkuhoid';

  @override
  String get routeMinSavingOff => 'Väljas';

  @override
  String get routeMinSavingOffCaption =>
      'Kuvatakse kõik marsruudilt leitud jaamad';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Ainult jaamad $amount piires marsruudi odavaimast';
  }

  @override
  String get routeDetourBudget => 'Maksimaalne ümbersõit';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Kuva jaamad kuni $km km kaugusel otseteest';
  }

  @override
  String get routeSegment => 'Marsruudi segment';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Näita odavaimat tanklat iga $km km tagant marsruudil';
  }

  @override
  String get avoidHighways => 'Väldi kiirteid';

  @override
  String get avoidHighwaysDesc =>
      'Marsruudi arvutus väldib tasulisi teid ja kiirteid';

  @override
  String get showFuelStations => 'Näita tanklasid';

  @override
  String get showFuelStationsDesc =>
      'Kaasa bensiini-, diisli-, LPG-, CNG-jaamad';

  @override
  String get showEvStations => 'Näita laadimisjaamu';

  @override
  String get showEvStationsDesc =>
      'Kaasa elektrilaadimise jaamad otsingutulemustes';

  @override
  String get noStationsAlongThisRoute =>
      'Selle marsruudi äärest jaamu ei leitud.';

  @override
  String get fuelCostCalculator => 'Kütusekulude kalkulaator';

  @override
  String get distanceKm => 'Kaugus (km)';

  @override
  String get consumptionL100km => 'Tarbimine (L/100km)';

  @override
  String get fuelPriceEurL => 'Kütuse hind (EUR/L)';

  @override
  String get tripCost => 'Reisikulu';

  @override
  String get fuelNeeded => 'Vajalik kütus';

  @override
  String get totalCost => 'Kogukulu';

  @override
  String get enterCalcValues =>
      'Sisestage kaugus, tarbimine ja hind reisikulu arvutamiseks';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consumption ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Fuel price ($unit)';
  }

  @override
  String get calculatorUseMine => 'Use';

  @override
  String get calculatorApplied => 'Applied';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get calculatorRoundTrip => 'Round trip';

  @override
  String get roundTripTotal => 'Round trip';

  @override
  String get costPerDistance => 'Cost per km';

  @override
  String get costPerMonth => 'Cost per month';

  @override
  String get calculatorEstimateMonthly => 'Estimate monthly cost';

  @override
  String get calculatorTripsPerMonth => 'Trips per month';

  @override
  String get calculatorTripsPerMonthHint => 'e.g. 20';

  @override
  String get calculatorReset => 'Reset';

  @override
  String get calculatorResultPlaceholder =>
      'Fill in distance, consumption and price to see your trip cost';

  @override
  String get priceHistory => 'Hinnaajalugu';

  @override
  String get ignoredStationsLabel => 'Ignoreeritud';

  @override
  String get ratingsLabel => 'Hinnangud';

  @override
  String get favoritesDataCache => 'Lemmikute andmed';

  @override
  String get citySearchCache => 'Linna otsing';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Andmete kustutamine ei ole kogukonna režiimis saadaval. Esmalt katkestage ühendus või kasutage privaatset andmebaasi.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count jälitatud tanklat';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count konfigureeritud';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count peidetud tanklat';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count hinnatud tanklat';
  }

  @override
  String get noPriceHistory => 'Hinnaajalugu puudub';

  @override
  String get noHourlyData => 'Tunniandmed puuduvad';

  @override
  String get noStatistics => 'Statistika pole saadaval';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Kesk';

  @override
  String get showAllFuelTypes => 'Näita kõiki kütuseliike';

  @override
  String get connected => 'Ühendatud';

  @override
  String get notConnected => 'Ühendamata';

  @override
  String get connectTankSync => 'Ühenda TankSync';

  @override
  String get disconnectTankSync => 'Katkesta TankSync';

  @override
  String get viewMyData => 'Vaata minu andmeid';

  @override
  String get optionalCloudSync =>
      'Valikuline pilvsünkroniseerimine hoiatuste, lemmikute ja tõuketeadete jaoks';

  @override
  String get tapToUpdateGps => 'Puudutage GPS asukoha uuendamiseks';

  @override
  String get gpsAutoUpdateHint =>
      'GPS asukoht hangitakse automaatselt otsimisel. Saate seda ka käsitsi siin uuendada.';

  @override
  String get clearGpsConfirm =>
      'Kustutada salvestatud GPS asukoht? Saate seda igal ajal uuendada.';

  @override
  String get pageNotFound => 'Lehte ei leitud';

  @override
  String get deleteAllServerData => 'Kustuta kõik serveriandmed';

  @override
  String get deleteServerDataConfirm => 'Kustutada kõik serveriandmed?';

  @override
  String get deleteEverything => 'Kustuta kõik';

  @override
  String get allDataDeleted => 'Kõik serveriandmed kustutatud';

  @override
  String get forgetAllSyncedTripsButton => 'Unusta kõik sünkroonitud reisid';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Unustada kõik sünkroonitud reisid?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Kõik reisikokkuvõtted ja üksikasjaandmed eemaldatakse serverist. Selle seadme kohalik reisiajalugu ei mõjutata.\n\nSeda toimingut ei saa tagasi võtta.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Unusta kõik';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Kõik sünkroonitud reisid eemaldati serverist';

  @override
  String get disconnectConfirm => 'Katkestada TankSync?';

  @override
  String get disconnect => 'Katkesta';

  @override
  String get myServerData => 'Minu serveriandmed';

  @override
  String get anonymousUuid => 'Anonüümne UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Sünkroniseeritud andmed';

  @override
  String get pushTokens => 'Tõukelubad';

  @override
  String get priceReports => 'Hinnateated';

  @override
  String get syncedTrips => 'Sõidud';

  @override
  String get totalItems => 'Kokku üksusi';

  @override
  String get estimatedSize => 'Hinnanguline suurus';

  @override
  String get viewRawJson => 'Vaata toorandmeid JSON-ina';

  @override
  String get exportJson => 'Ekspordi JSON-ina (lõikelaud)';

  @override
  String get jsonCopied => 'JSON kopeeritud lõikelauale';

  @override
  String get rawDataJson => 'Toorandmed (JSON)';

  @override
  String get close => 'Sulge';

  @override
  String get account => 'Konto';

  @override
  String get continueAsGuest => 'Jätka külalisena';

  @override
  String get createAccount => 'Loo konto';

  @override
  String get signIn => 'Logi sisse';

  @override
  String get upgradeToEmail => 'Loo e-postiga konto';

  @override
  String get savedRoutes => 'Salvestatud marsruudid';

  @override
  String get noSavedRoutes => 'Salvestatud marsruute pole';

  @override
  String get noSavedRoutesHint =>
      'Otsi mööda marsruuti ja salvesta see hilisemaks kiirjuurdepääsuks.';

  @override
  String get saveRoute => 'Salvesta marsruut';

  @override
  String get routeName => 'Marsruudi nimi';

  @override
  String itineraryDeleted(String name) {
    return '$name kustutatud';
  }

  @override
  String loadingRoute(String name) {
    return 'Laen marsruuti: $name';
  }

  @override
  String get refreshFailed => 'Värskendamine ebaõnnestus. Proovi uuesti.';

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
  String get onboardingWelcomeHint => 'Seadista rakendus mõne kiire sammuga.';

  @override
  String get onboardingApiKeyDescription =>
      'Registreeru tasuta API-võtme saamiseks või jäta vahele, et uurida rakendust demoandmetega.';

  @override
  String get onboardingComplete => 'Kõik valmis!';

  @override
  String get onboardingCompleteHint =>
      'Neid seadeid saad igal ajal oma profiilis muuta.';

  @override
  String get onboardingBack => 'Tagasi';

  @override
  String get onboardingNext => 'Edasi';

  @override
  String get onboardingSkip => 'Jäta vahele';

  @override
  String get onboardingFinish => 'Alusta';

  @override
  String crossBorderNearby(String country) {
    return '$country on lähedal';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km piirini';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Keskmine siin: $price EUR ($count jaama)';
  }

  @override
  String get allPricesView => 'Kõik hinnad';

  @override
  String get compactView => 'Kompaktne';

  @override
  String get switchToAllPricesView => 'Lülitu kõigi hindade vaatesse';

  @override
  String get switchToCompactView => 'Lülitu kompaktsesse vaatesse';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Laost otsas';

  @override
  String get gdprTitle => 'Sinu privaatsus';

  @override
  String get gdprSubtitle =>
      'See rakendus austab sinu privaatsust. Vali, milliseid andmeid soovid jagada. Neid seadeid saad igal ajal muuta.';

  @override
  String get gdprLocationTitle => 'Asukoha juurdepääs';

  @override
  String get gdprLocationDescription =>
      'Sinu koordinaadid saadetakse kütusehinna API-le lähedalasuvate jaamade leidmiseks. Asukohta ei salvestata kunagi serverisse ega kasutata jälgimiseks.';

  @override
  String get gdprLocationShort =>
      'Leia lähedased kütusejaamad sinu asukoha abil';

  @override
  String get gdprErrorReportingTitle => 'Veateated';

  @override
  String get gdprErrorReportingDescription =>
      'Anonüümsed krahiraportid aitavad rakendust täiustada. Isikuandmeid ei kaasata. Raportid saadetakse Sentry kaudu ainult siis, kui see on seadistatud.';

  @override
  String get gdprErrorReportingShort =>
      'Saada anonüümsed krahiraportid rakenduse täiustamiseks';

  @override
  String get gdprCloudSyncTitle => 'Pilvsünkroonimine';

  @override
  String get gdprCloudSyncDescription =>
      'Sünkrooni lemmikud ja teatised seadmete vahel TankSync kaudu. Kasutab anonüümset autentimist. Sinu andmed on edastamisel krüpteeritud.';

  @override
  String get gdprCloudSyncShort =>
      'Sünkrooni lemmikud ja teatised seadmete vahel';

  @override
  String get gdprLegalBasis =>
      'Õiguslik alus: art. 6(1)(a) GDPR (nõusolek). Nõusoleku saad igal ajal seadetes tagasi võtta.';

  @override
  String get gdprAcceptAll => 'Nõustu kõigega';

  @override
  String get gdprAcceptSelected => 'Nõustu valitutega';

  @override
  String get gdprSettingsHint => 'Oma privaatsusvalikuid saad igal ajal muuta.';

  @override
  String get routeSaved => 'Marsruut salvestatud!';

  @override
  String get routeSaveFailed => 'Marsruudi salvestamine ebaõnnestus';

  @override
  String get sqlCopied => 'SQL kopeeritud lõikelauale';

  @override
  String get connectionDataCopied => 'Ühenduse andmed kopeeritud';

  @override
  String get accountDeleted => 'Konto kustutatud. Kohalikud andmed säilitatud.';

  @override
  String get switchedToAnonymous => 'Lülituti anonüümsele sessioonile';

  @override
  String failedToSwitch(String error) {
    return 'Lülitumine ebaõnnestus: $error';
  }

  @override
  String get topicUrlCopied => 'Teema URL kopeeritud';

  @override
  String get testNotificationSent => 'Testteatise saatmine õnnestus!';

  @override
  String get testNotificationFailed => 'Testteatise saatmine ebaõnnestus';

  @override
  String get pushUpdateFailed => 'Tõuketeate seade uuendamine ebaõnnestus';

  @override
  String get connectedAsGuest => 'Ühendatud külalisena';

  @override
  String get accountCreated => 'Konto loodud!';

  @override
  String get signedIn => 'Sisse logitud!';

  @override
  String stationHidden(String name) {
    return '$name peidetud';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name eemaldati lemmikutest';
  }

  @override
  String invalidApiKey(String error) {
    return 'Vigane API-võti: $error';
  }

  @override
  String get invalidQrCode => 'Vigane QR-koodi formaat';

  @override
  String get invalidQrCodeTankSync =>
      'Vigane QR-kood — oodati TankSync formaati';

  @override
  String get tankSyncConnected => 'TankSync ühendatud!';

  @override
  String get syncCompleted => 'Sünkroonimine lõpetatud — andmed uuendatud';

  @override
  String get deviceCodeCopied => 'Seadme kood kopeeritud';

  @override
  String get undo => 'Võta tagasi';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Sisesta kehtiv $length-kohaline $label';
  }

  @override
  String get freshnessAgo => 'tagasi';

  @override
  String get freshnessStale => 'Aegunud';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Andmete värskus: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return '$brand logo';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hinda $count tärniga',
      one: 'Hinda 1 tärniga',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Nõrk';

  @override
  String get passwordStrengthFair => 'Keskmine';

  @override
  String get passwordStrengthStrong => 'Tugev';

  @override
  String get passwordReqMinLength => 'Vähemalt 8 tähemärki';

  @override
  String get passwordReqUppercase => 'Vähemalt 1 suurtäht';

  @override
  String get passwordReqLowercase => 'Vähemalt 1 väiketäht';

  @override
  String get passwordReqDigit => 'Vähemalt 1 number';

  @override
  String get passwordReqSpecial => 'Vähemalt 1 erimärk';

  @override
  String get passwordTooWeak => 'Parool ei vasta kõigile nõuetele';

  @override
  String get brandFilterAll => 'Kõik';

  @override
  String get brandFilterNoHighway => 'Ilma kiirteeta';

  @override
  String get swipeTutorialMessage =>
      'Pühkige paremale navigeerimiseks, vasakule eemaldamiseks';

  @override
  String get swipeTutorialDismiss => 'Selge';

  @override
  String get alertStatsActive => 'Aktiivsed';

  @override
  String get alertStatsToday => 'Täna';

  @override
  String get alertStatsThisWeek => 'Sel nädalal';

  @override
  String get privacyDashboardTitle => 'Privaatsuse armatuurlaud';

  @override
  String get privacyDashboardSubtitle =>
      'Vaata, ekspordi või kustuta oma andmeid';

  @override
  String get privacyDashboardBanner =>
      'Sinu andmed kuuluvad sulle. Siin näed kõike, mida rakendus salvestab, saad seda eksportida või kustutada.';

  @override
  String get privacyLocalData => 'Andmed sellel seadmel';

  @override
  String get privacyIgnoredStations => 'Ignoreeritud jaamad';

  @override
  String get privacyRatings => 'Jaamade hinnangud';

  @override
  String get privacyPriceHistory => 'Hinnaloo jaamad';

  @override
  String get privacyProfiles => 'Otsinguprofiilid';

  @override
  String get privacyItineraries => 'Salvestatud marsruudid';

  @override
  String get privacyCacheEntries => 'Vahemälu kirjed';

  @override
  String get privacyApiKey => 'API-võti salvestatud';

  @override
  String get privacyEvApiKey => 'EV API-võti salvestatud';

  @override
  String get privacyEstimatedSize => 'Hinnanguline salvestusmaht';

  @override
  String get privacySyncedData => 'Pilvsünkroonimine (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Pilvsünkroonimine on keelatud. Kõik andmed jäävad ainult sellesse seadmesse.';

  @override
  String get privacySyncMode => 'Sünkroonimisrežiim';

  @override
  String get privacySyncUserId => 'Kasutaja ID';

  @override
  String get privacySyncDescription =>
      'Kui sünkroonimine on lubatud, salvestatakse lemmikud, teatised, ignoreeritud jaamad ja hinnangud ka TankSync serverisse.';

  @override
  String get privacyViewServerData => 'Vaata serveri andmeid';

  @override
  String get privacyExportButton => 'Ekspordi kõik andmed JSON-ina';

  @override
  String get privacyExportSuccess => 'Andmed eksporditi lõikelauale';

  @override
  String get privacyExportCsvButton => 'Ekspordi kõik andmed CSV-na';

  @override
  String get privacyExportCsvSuccess => 'CSV-andmed eksporditi lõikelauale';

  @override
  String get savedToDownloadsFolder => 'Salvestatud Allalaadimiste kausta';

  @override
  String get privacyDeleteButton => 'Kustuta kõik andmed';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopeeri tõrkepäevik lõikelauale ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Salvesta tõrkelogi ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Tühjenda vealogi';

  @override
  String get privacyErrorLogCleared => 'Vealogi tühjendatud';

  @override
  String get privacyDeleteTitle => 'Kustutada kõik andmed?';

  @override
  String get privacyDeleteBody =>
      'See kustutab jäädavalt:\n\n- Kõik lemmikud ja jaamaandmed\n- Kõik otsinguprofiilid\n- Kõik hinnateatised\n- Kogu hinnaloo\n- Kõik vahemälu andmed\n- Sinu API-võtme\n- Kõik rakenduse seaded\n\nRakendus lähtestatakse algsesse olekusse. Seda toimingut ei saa tagasi võtta.';

  @override
  String get privacyDeleteConfirm => 'Kustuta kõik';

  @override
  String get yes => 'Jah';

  @override
  String get no => 'Ei';

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
  String get paymentMethods => 'Makseviisid';

  @override
  String get paymentMethodCash => 'Sularaha';

  @override
  String get paymentMethodCard => 'Kaart';

  @override
  String get paymentMethodContactless => 'Kontaktivaba';

  @override
  String get paymentMethodFuelCard => 'Kütuskaart';

  @override
  String get paymentMethodApp => 'Rakendus';

  @override
  String payWithApp(String app) {
    return 'Maksa $app-ga';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Võrrelduna liikuva keskmisega sinu viimase 3 tankimise põhjal ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Tarbimine $value L/100 km, $delta võrreldes sinu liikuva keskmisega';
  }

  @override
  String get drivingMode => 'Sõiturežiim';

  @override
  String get drivingExit => 'Välju';

  @override
  String get drivingNearestStation => 'Lähim';

  @override
  String get drivingTapToUnlock => 'Puuduta avamiseks';

  @override
  String get drivingSafetyTitle => 'Ohutusteade';

  @override
  String get drivingSafetyMessage =>
      'Ära kasuta rakendust sõitmise ajal. Peatu ohutusse kohta enne ekraaniga suhtlemist. Juht vastutab alati sõiduki ohutu käitamise eest.';

  @override
  String get drivingSafetyAccept => 'Saan aru';

  @override
  String get voiceAnnouncementsTitle => 'Häälteated';

  @override
  String get voiceAnnouncementsDescription =>
      'Teata lähedalolevatest odavatest jaamadest sõitmise ajal';

  @override
  String get voiceAnnouncementsEnabled => 'Luba häälteated';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Ainult alla $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilomeetrit ees, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Teate raadius';

  @override
  String get voiceAnnouncementCooldown => 'Kordamise intervall';

  @override
  String get nearestStations => 'Lahimad jaamad';

  @override
  String get nearestStationsHint =>
      'Leidke lahimad jaamad oma praeguse asukoha jargi';

  @override
  String get consumptionLogTitle => 'Kütusekulu';

  @override
  String get consumptionLogMenuTitle => 'Kulupäevik';

  @override
  String get consumptionLogMenuSubtitle => 'Jälgi tankimisi ja arvuta L/100km';

  @override
  String get consumptionStatsTitle => 'Kulu statistika';

  @override
  String get addFillUp => 'Lisa tankimine';

  @override
  String get noFillUpsTitle => 'Tankimisi pole veel';

  @override
  String get noFillUpsSubtitle =>
      'Lisa oma esimene tankimine kulu jälgimise alustamiseks.';

  @override
  String get fillUpDate => 'Kuupäev';

  @override
  String get liters => 'Liitrid';

  @override
  String get odometerKm => 'Läbisõidumõõdik (km)';

  @override
  String get notesOptional => 'Märkmed (vabatahtlik)';

  @override
  String get stationPreFilled => 'Jaam eeltäidetud';

  @override
  String get statAvgConsumption => 'Kesk. L/100km';

  @override
  String get statAvgCostPerKm => 'Kesk. kulu/km';

  @override
  String get statTotalLiters => 'Kokku liitrid';

  @override
  String get statTotalSpent => 'Kokku kulutatud';

  @override
  String get statFillUpCount => 'Tankimisi';

  @override
  String get fieldRequired => 'Kohustuslik';

  @override
  String get fieldInvalidNumber => 'Vigane number';

  @override
  String get carbonDashboardTitle => 'CO2 armatuurlaud';

  @override
  String get carbonEmptyTitle => 'Andmed puuduvad';

  @override
  String get carbonEmptySubtitle =>
      'Lisa tankimisi, et näha CO2 armatuurlauda.';

  @override
  String get carbonSummaryTotalCost => 'Kogukulu';

  @override
  String get carbonSummaryTotalCo2 => 'Kokku CO2';

  @override
  String get monthlyCostsTitle => 'Igakuised kulud';

  @override
  String get monthlyEmissionsTitle => 'Igakuised CO2 heitmed';

  @override
  String get vehiclesTitle => 'Minu sõidukid';

  @override
  String get vehiclesMenuTitle => 'Minu sõidukid';

  @override
  String get vehiclesMenuSubtitle => 'Aku, pistikud, laadimiseelistused';

  @override
  String get vehiclesEmptyMessage =>
      'Lisa oma auto, et filtreerida pistiku järgi ja hinnata laadimiskulusid.';

  @override
  String get vehiclesWizardTitle => 'Minu sõidukid (vabatahtlik)';

  @override
  String get vehiclesWizardSubtitle =>
      'Lisa oma auto, et eeltäita kulupäevik ja lubada EV pistikufiltrid. Võid selle vahele jätta ja sõidukeid hiljem lisada.';

  @override
  String get vehiclesWizardNoneYet => 'Ühtegi sõidukit pole veel seadistatud.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sõidukit',
      one: '1 sõiduk',
    );
    return 'Sul on $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Jäta vahele seadistuse lõpetamiseks — sõidukeid saad igal ajal Seadetest lisada.';

  @override
  String get fillUpVehicleLabel => 'Sõiduk';

  @override
  String get fillUpVehicleNone => 'Sõiduk puudub';

  @override
  String get fillUpVehicleRequired => 'Sõiduk on kohustuslik';

  @override
  String get reportScanError => 'Teata skaneerimisveast';

  @override
  String get pickStationTitle => 'Vali jaam';

  @override
  String get pickStationHelper =>
      'Alusta tankimist teadaoleva jaama juurest, et hinnad, bränd ja kütuse liik täituksid automaatselt.';

  @override
  String get pickStationEmpty =>
      'Lemmikjaamu pole veel — lisa neid Otsingust või Lemmikutest, või jäta vahele ja sisesta käsitsi.';

  @override
  String get pickStationSkip => 'Jäta vahele — lisa ilma jaamata';

  @override
  String get scanPump => 'Skaneeri pump';

  @override
  String get scanPayment => 'Skaneeri makse QR';

  @override
  String get qrPaymentBeneficiary => 'Saaja';

  @override
  String get qrPaymentAmount => 'Summa';

  @override
  String get qrPaymentEpcTitle => 'SEPA makse';

  @override
  String get qrPaymentEpcEmpty => 'Ühtegi välja ei dekodeeritud';

  @override
  String get qrPaymentOpenInBank => 'Ava pangarakenduses';

  @override
  String get qrPaymentLaunchFailed =>
      'Ühtegi rakendust pole selle koodi avamiseks';

  @override
  String get qrPaymentUnknownTitle => 'Tundmatu kood';

  @override
  String get qrPaymentCopyRaw => 'Kopeeri toortekst';

  @override
  String get qrPaymentCopiedRaw => 'Kopeeritud lõikelauale';

  @override
  String get qrPaymentReport => 'Teata sellest skaneerimisest';

  @override
  String get qrPaymentEpcCopied =>
      'Pangatoimiku andmed kopeeritud — kleebi oma pangarakendusse';

  @override
  String get qrScannerGuidance => 'Suuna kaamera QR-koodile';

  @override
  String get qrScannerPermissionDenied =>
      'QR-koodide skaneerimiseks on vaja kaamera juurdepääsu.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kaamera juurdepääs keelati. Ava seaded, et see lubada.';

  @override
  String get qrScannerRetryPermission => 'Proovi uuesti';

  @override
  String get qrScannerOpenSettings => 'Ava seaded';

  @override
  String get qrScannerTimeout =>
      'QR-koodi ei tuvastatud. Liigu lähemale või proovi uuesti.';

  @override
  String get qrScannerRetry => 'Proovi uuesti';

  @override
  String get torchOn => 'Lülita välk sisse';

  @override
  String get torchOff => 'Lülita välk välja';

  @override
  String get obdNoAdapter => 'OBD2 adapterit ei leitud';

  @override
  String get obdOdometerUnavailable => 'Läbisõidumõõdikut ei saanud lugeda';

  @override
  String get obdPermissionDenied => 'Anna Bluetooth\'i luba süsteemiseadetes';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter ei vastanud — lülita süütevool sisse ja proovi uuesti';

  @override
  String get obdPickerTitle => 'Vali OBD2 adapter';

  @override
  String get obdPickerScanning => 'Otsin adaptereid…';

  @override
  String get obdPickerConnecting => 'Ühendan…';

  @override
  String get themeSettingTitle => 'Teema';

  @override
  String get themeModeLight => 'Hele';

  @override
  String get themeModeDark => 'Tume';

  @override
  String get themeModeSystem => 'Järgi süsteemi';

  @override
  String get tripRecordingTitle => 'Reisi salvestamine';

  @override
  String get tripSummaryTitle => 'Reisi kokkuvõte';

  @override
  String get tripMetricDistance => 'Vahemaa';

  @override
  String get tripMetricSpeed => 'Kiirus';

  @override
  String get tripMetricFuelUsed => 'Kasutatud kütus';

  @override
  String get tripMetricAvgConsumption => 'Kesk.';

  @override
  String get tripMetricElapsed => 'Kulunud aeg';

  @override
  String get tripMetricOdometer => 'Läbisõidumõõdik';

  @override
  String get tripStop => 'Peata salvestamine';

  @override
  String get tripPause => 'Peata';

  @override
  String get tripResume => 'Jätka';

  @override
  String get tripBannerRecording => 'Salvestatakse reisi';

  @override
  String get tripBannerPaused => 'Reis peatatud — puuduta jätkamiseks';

  @override
  String get navConsumption => 'Kulu';

  @override
  String get vehicleBaselineSectionTitle => 'Baasjooné kalibreerimine';

  @override
  String get vehicleBaselineEmpty =>
      'Näidiseid pole veel — alusta OBD2 reisi, et hakata selle sõiduki kütuseprofiili õppima.';

  @override
  String get vehicleBaselineProgress =>
      'Õpitud näidistest erinevates sõitusituatsioonides.';

  @override
  String get vehicleBaselineReset => 'Lähtesta sõitusituatsiooni baasjoon';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Lähtestada sõitusituatsiooni baasjoon?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'See kustutab kõik selle sõiduki õpitud näidised. Naased külmkäivituse vaikeväärtuste juurde, kuni uued reisid profiili täidavad.';

  @override
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Adapterit pole ühendatud. Ühenda üks, et rakendus saaks järgmine kord automaatselt uuesti ühendada.';

  @override
  String get vehicleAdapterUnnamed => 'Tundmatu adapter';

  @override
  String get vehicleAdapterPair => 'Ühenda adapter';

  @override
  String get vehicleAdapterForget => 'Unusta adapter';

  @override
  String get achievementsTitle => 'Saavutused';

  @override
  String get achievementFirstTrip => 'Esimene reis';

  @override
  String get achievementFirstTripDesc => 'Salvesta oma esimene OBD2 reis.';

  @override
  String get achievementFirstFillUp => 'Esimene tankimine';

  @override
  String get achievementFirstFillUpDesc => 'Lisa oma esimene tankimine.';

  @override
  String get achievementTenTrips => '10 reisi';

  @override
  String get achievementTenTripsDesc => 'Salvesta 10 OBD2 reisi.';

  @override
  String get achievementZeroHarsh => 'Sujuv sõitja';

  @override
  String get achievementZeroHarshDesc =>
      'Lõpeta 10 km või pikem reis ilma järsu pidurduse või kiirenduseta.';

  @override
  String get achievementEcoWeek => 'Ökonädal';

  @override
  String get achievementEcoWeekDesc =>
      'Sõida 7 järjestikusel päeval vähemalt ühe sujuva reisiga päevas.';

  @override
  String get achievementPriceWin => 'Hinnavõit';

  @override
  String get achievementPriceWinDesc =>
      'Lisa tankimine, mis ületab jaama 30-päeva keskmist 5% või rohkem.';

  @override
  String get syncBaselinesToggleTitle => 'Jaga õpitud sõidukiprofiile';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Laadi üles sõiduki kulubaasjoon, et teine seade saaks seda kasutada.';

  @override
  String get obd2StatusConnected => 'OBD2 adapter: ühendatud';

  @override
  String get obd2StatusAttempting => 'OBD2 adapter: ühendub';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapter: kättesaamatu';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: Bluetooth\'i luba vajalik';

  @override
  String get obd2StatusConnectedBody => 'Valmis reisi salvestama.';

  @override
  String get obd2StatusAttemptingBody => 'Ühendan taustal…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter on levialast väljas või kasutusel teises rakenduses.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Anna Bluetooth\'i luba süsteemiseadetes automaatseks uuesti ühendamiseks.';

  @override
  String get obd2StatusNoAdapter => 'Adapterit pole ühendatud';

  @override
  String get obd2StatusForget => 'Unusta adapter';

  @override
  String get tripHistoryTitle => 'Reisiajalugu';

  @override
  String get tripHistoryEmptyTitle => 'Reise pole veel';

  @override
  String get tripHistoryEmptySubtitle =>
      'Ühenda OBD2 adapter ja salvesta reis, et hakata sõitmisajalugu koostama.';

  @override
  String get tripHistoryUnknownDate => 'Teadmata kuupäev';

  @override
  String get situationIdle => 'Tühikäik';

  @override
  String get situationStopAndGo => 'Stopp ja mine';

  @override
  String get situationUrban => 'Linn';

  @override
  String get situationHighway => 'Kiirtee';

  @override
  String get situationDecel => 'Aeglustumine';

  @override
  String get situationClimbing => 'Tõus / koormatud';

  @override
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

  @override
  String get situationHardAccel => 'Järsk kiirendus';

  @override
  String get situationFuelCut => 'Kütuse katkestus — libisemine';

  @override
  String get tripSaveAsFillUp => 'Salvesta tankimisena';

  @override
  String get tripSaveRecording => 'Salvesta reis';

  @override
  String get tripDiscard => 'Hülga';

  @override
  String obdOdometerRead(int km) {
    return 'Läbisõidumõõdik loetud: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Määramata';

  @override
  String get wizardVehicleTapToEdit => 'Puuduta muutmiseks';

  @override
  String get wizardVehicleDefaultBadge => 'Vaikimisi';

  @override
  String get wizardProfileChoiceHint =>
      'Vali, kuidas soovid rakendust kasutada. Seda saab hiljem Seadetes muuta.';

  @override
  String get wizardProfileChoiceFooter =>
      'Valikut saab igal ajal muuta Seaded → Kasutusrežiim alt.';

  @override
  String get wizardProfileBasicName => 'Põhi';

  @override
  String get wizardProfileBasicDescription =>
      'Odavaim kütus ja EV laadimishinnad lähedal. Lemmikud ja hinnateatised.';

  @override
  String get wizardProfileMediumName => 'Kesktase';

  @override
  String get wizardProfileMediumDescription =>
      'Kõik Põhitasemest, pluss kütusetankimiste ja EV laadimise käsitsi jälgimine.';

  @override
  String get wizardProfileFullName => 'Täis';

  @override
  String get wizardProfileFullDescription =>
      'Kõik Kesktasemest, pluss automaatne OBD2 reisi salvestamine, sõiduhinded ja lojaalsuskaardid.';

  @override
  String get wizardProfileCustomName => 'Kohandatud';

  @override
  String get wizardProfileCustomDescription =>
      'Sinu enda funktsioonide kombinatsioon. Kohanda iga lülitit allpool.';

  @override
  String get useModeSectionHint =>
      'Kohanda rakendust oma tegelikule kasutusele vastavaks. Eelseadistuse valimine lubab vastavad funktsioonid.';

  @override
  String get useModeCustomSettingsDescription =>
      'Sinu funktsioonide valik ei vasta ühelegi eelseadistusele. Vali eelseadistus ülalt ülekirjutamiseks või jätka individuaalsete funktsioonide kohandamist allpool.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Kasutusrežiim seatud: $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Vaikimisi sõiduk (vabatahtlik)';

  @override
  String get profileDefaultVehicleNone => 'Vaikimisi puudub';

  @override
  String get profileFuelFromVehicleHint =>
      'Kütuse liik tuleneb sinu vaikimisi sõidukist. Tühjenda sõiduk, et valida kütus otse.';

  @override
  String get consumptionNoVehicleTitle => 'Lisa esmalt sõiduk';

  @override
  String get consumptionNoVehicleBody =>
      'Tankimised seostatakse sõidukiga. Lisa oma auto kulu logimise alustamiseks.';

  @override
  String get vehicleAdd => 'Lisa sõiduk';

  @override
  String get vehicleAddTitle => 'Lisa sõiduk';

  @override
  String get vehicleEditTitle => 'Muuda sõidukit';

  @override
  String get vehicleDeleteTitle => 'Kustuta sõiduk?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Eemalda \"$name\" sinu profiilidest?';
  }

  @override
  String get vehicleNameLabel => 'Nimi';

  @override
  String get vehicleNameHint => 'nt Minu Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Sisepõlemismootor';

  @override
  String get vehicleTypeHybrid => 'Hübriid';

  @override
  String get vehicleTypeEv => 'Elektriline';

  @override
  String get vehicleEvSectionTitle => 'Elektriline';

  @override
  String get vehicleCombustionSectionTitle => 'Sisepõlemismootor';

  @override
  String get vehicleBatteryLabel => 'Aku mahtuvus (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maksimaalne laadimise võimsus (kW)';

  @override
  String get vehicleConnectorsLabel => 'Toetatud pistikud';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Paagi mahtuvus (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Eelistatud kütus';

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
  String get connectorThreePin => '3-kontaktiline';

  @override
  String get evShowOnMap => 'Näita EV jaamu';

  @override
  String get evAvailableOnly => 'Ainult saadaolevad';

  @override
  String get evMinPower => 'Min võimsus';

  @override
  String get evMaxPower => 'Maks võimsus';

  @override
  String get evOperator => 'Operaator';

  @override
  String get evLastUpdate => 'Viimane uuendus';

  @override
  String get evStatusAvailable => 'Saadaval';

  @override
  String get evStatusOccupied => 'Hõivatud';

  @override
  String get evStatusOutOfOrder => 'Rikkes';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Ainult avatud';

  @override
  String get saveAsDefaults => 'Salvesta vaikimisi sätetena';

  @override
  String get criteriaSavedToProfile => 'Salvestatud vaikimisi sätetena';

  @override
  String get profileNotFound => 'Aktiivset profiili pole';

  @override
  String get updatingFavorites => 'Uuendan sinu lemmikuid...';

  @override
  String get fetchingLatestPrices => 'Hangin uusimaid hindu';

  @override
  String get noDataAvailable => 'Andmed puuduvad';

  @override
  String get configAndPrivacy => 'Seaded ja privaatsus';

  @override
  String get searchToSeeMap => 'Otsi jaamade kuvamiseks kaardil';

  @override
  String get evPowerAny => 'Kõik';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profiil';

  @override
  String get sectionLocation => 'Asukoht';

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
  String get tooltipBack => 'Tagasi';

  @override
  String get tooltipClose => 'Sulge';

  @override
  String get tooltipShare => 'Jaga';

  @override
  String get tooltipClearSearch => 'Tühjenda otsingusisestus';

  @override
  String get minimalDriveInstantConsumption => 'Hetketarbimine';

  @override
  String get coachingShiftUp => 'Vaheta üles';

  @override
  String get coachingShiftDown => 'Vaheta alla';

  @override
  String get coachingEasePedal => 'Lase gaas';

  @override
  String get coachingVoiceHardAcceleration => 'Easy on the accelerator';

  @override
  String get coachingVoiceHarshBraking => 'Try to brake more gently';

  @override
  String get coachingVoiceShiftUp => 'Shift up a gear to save fuel';

  @override
  String get coachingVoiceShiftDown => 'Shift down, the engine is labouring';

  @override
  String get coachingVoiceEasePedal =>
      'Ease off the pedal to cut your fuel use';

  @override
  String get coachingVoiceLiftOff => 'Lift off the accelerator and coast';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Look further ahead and lift off earlier';

  @override
  String get coachingVoiceSmoothAccel => 'Accelerate more smoothly';

  @override
  String get voiceCoachingSettingTitle => 'Spoken driving coaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hear spoken tips while you drive — hard acceleration, harsh braking and gear hints';

  @override
  String get tooltipUseGps => 'Kasuta GPS-asukohta';

  @override
  String get tooltipShowPassword => 'Kuva parool';

  @override
  String get tooltipHidePassword => 'Peida parool';

  @override
  String get evConnectorsLabel => 'Saadaolevad pistikud';

  @override
  String get evConnectorsNone => 'Pistiku teave puudub';

  @override
  String get switchToEmail => 'Lülitu e-postile';

  @override
  String get switchToEmailSubtitle =>
      'Säilita andmed, lisa sisselogimine teistest seadmetest';

  @override
  String get switchToAnonymousAction => 'Lülitu anonüümseks';

  @override
  String get switchToAnonymousSubtitle =>
      'Säilita kohalikud andmed, kasuta uut anonüümset sessiooni';

  @override
  String get linkDevice => 'Ühenda seade';

  @override
  String get shareDatabase => 'Jaga andmebaasi';

  @override
  String get disconnectAction => 'Katkesta ühendus';

  @override
  String get disconnectSubtitle =>
      'Lõpeta sünkroonimine (kohalikud andmed säilivad)';

  @override
  String get deleteAccountAction => 'Kustuta konto';

  @override
  String get deleteAccountSubtitle => 'Eemalda kõik serveriandmed jäädavalt';

  @override
  String get localOnly => 'Ainult kohalik';

  @override
  String get localOnlySubtitle =>
      'Vabatahtlik: sünkrooni lemmikud, teatised ja hinnangud seadmete vahel';

  @override
  String get setupCloudSync => 'Seadista pilvsünkroonimine';

  @override
  String get disconnectTitle => 'Katkestada TankSync ühendus?';

  @override
  String get disconnectBody =>
      'Pilvsünkroonimine keelatakse. Sinu kohalikud andmed (lemmikud, teatised, ajalugu) säilivad sellel seadmel. Serveri andmeid ei kustutata.';

  @override
  String get deleteAccountTitle => 'Kustutada konto?';

  @override
  String get deleteAccountBody =>
      'See kustutab jäädavalt kõik sinu andmed serverist (lemmikud, teatised, hinnangud, marsruudid). Kohalikud andmed sellel seadmel säilivad.\n\nSeda ei saa tagasi võtta.';

  @override
  String get switchToAnonymousTitle => 'Lülituda anonüümseks?';

  @override
  String get switchToAnonymousBody =>
      'Logitakse välja sinu e-postkontolt ja jätkatakse uue anonüümse sessiooniga.\n\nSinu kohalikud andmed (lemmikud, teatised) jäävad sellele seadmele ja sünkroonitakse uue anonüümse kontoga.';

  @override
  String get switchAction => 'Vaheta';

  @override
  String get helpBannerCriteria =>
      'Sinu profiili vaikimisi sätted on eeltäidetud. Otsingut täpsustamiseks muuda allpool olevaid kriteeriume.';

  @override
  String get helpBannerAlerts =>
      'Sea jaama jaoks hinnakünnis. Saad teatise, kui hinnad langevad alla selle. Kontroll toimub iga 30 minuti tagant.';

  @override
  String get helpBannerConsumption =>
      'Logi iga tankimine, et jälgida oma tegelikku kütusekulu ja CO₂ jalajälge. Pühkige kirje kustutamiseks vasakule.';

  @override
  String get helpBannerVehicles =>
      'Lisa oma sõidukid, et tankimised ja kütuseelistused täituksid vaikimisi õigesti. Esimene sõiduk saab sinu vaikimisi sõidukiks.';

  @override
  String get syncNow => 'Sünkrooni kohe';

  @override
  String get onboardingPreferencesTitle => 'Sinu eelistused';

  @override
  String get onboardingZipHelper => 'Kasutatakse, kui GPS pole saadaval';

  @override
  String get onboardingRadiusHelper => 'Suurem raadius = rohkem tulemusi';

  @override
  String get onboardingPrivacy =>
      'Neid seadeid talletatakse ainult sinu seadmes ja neid ei jagata kunagi.';

  @override
  String get onboardingLandingTitle => 'Avakuvar';

  @override
  String get onboardingLandingHint =>
      'Vali, milline ekraan avaneb rakenduse käivitamisel.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Ära ole rakenduses — aga ära ka sulge seda.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Ava Sparkilo kord pärast igat taaskäivitust.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple äratab Sparkilo üles alles pärast seda, kui oled selle pärast telefoni taaskäivitamist vähemalt korra avanud. Pärast seda salvestatakse sinu reisid automaatselt.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Ära pühki Sparkilo rakenduste vahetajas ära.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Sunniviiisiline sulgemine\" käsib iOS-il rakenduse taaskäivitamist lõpetada. Reisid lõpetavad salvestamise, kuni avad Sparkilo uuesti.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Kui iOS küsib \"Alati\" asukohta, palun ütle jah.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Varuvariант, mis salvestab sinu reisi, kui OBD2 adapter on aeglane, vajab taustaasukoht. Me ei jaga seda kunagi.';

  @override
  String get scanReceipt => 'Skaneeri kviitung';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Kütus';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Kiirtee';

  @override
  String get ratingModeLocal => 'Kohalik';

  @override
  String get ratingModePrivate => 'Privaatne';

  @override
  String get ratingModeShared => 'Jagatud';

  @override
  String get ratingDescLocal =>
      'Hinnangud salvestatud ainult sellesse seadmesse';

  @override
  String get ratingDescPrivate =>
      'Sünkroonitud sinu andmebaasiga (teistele nähtamatu)';

  @override
  String get ratingDescShared => 'Nähtav kõigile sinu andmebaasi kasutajatele';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API-võti pole seadistatud. Lisa see Seadetes EV laadimisjaamu otsimiseks.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Andmepakkuja ($host) edastab aegunud või kehtetut TLS-sertifikaati. Rakendus ei saa sellest allikast andmeid laadida, kuni pakkuja selle parandab. Palun võta ühendust $host-ga.';
  }

  @override
  String get offlineLabel => 'Võrguühenduseta';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed pole saadaval. Kasutatakse $current.';
  }

  @override
  String get errorTitleApiKey => 'API-võti vajalik';

  @override
  String get errorTitleLocation => 'Asukoht pole saadaval';

  @override
  String get errorHintNoStations =>
      'Proovi suurendada otsinguala raadiust või otsi teist asukohta.';

  @override
  String get errorHintApiKey => 'Seadista oma API-võti Seadetes.';

  @override
  String get errorHintConnection =>
      'Kontrolli internetiühendust ja proovi uuesti.';

  @override
  String get errorHintRouting =>
      'Marsruudi arvutamine ebaõnnestus. Kontrolli internetiühendust ja proovi uuesti.';

  @override
  String get errorHintFallback =>
      'Proovi uuesti või otsi sihtnumbri / linna nime järgi.';

  @override
  String get alertsLoadErrorTitle => 'Teatiste laadimine ebaõnnestus';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Teatiste taustakonkroll ebaõnnestus';

  @override
  String get detailsLabel => 'Üksikasjad';

  @override
  String get remove => 'Eemalda';

  @override
  String get showKey => 'Kuva võti';

  @override
  String get hideKey => 'Peida võti';

  @override
  String get syncOptionalTitle => 'TankSync on vabatahtlik';

  @override
  String get syncOptionalDescription =>
      'Sinu rakendus töötab täielikult ilma pilvsünkroonimiseta. TankSync võimaldab sünkroonida lemmikuid, teatisi ja hinnanguid seadmete vahel Supabase abil (tasuta pakett saadaval).';

  @override
  String get syncHowToConnectQuestion => 'Kuidas soovid ühendada?';

  @override
  String get syncCreateOwnTitle => 'Loo oma andmebaas';

  @override
  String get syncCreateOwnSubtitle =>
      'Tasuta Supabase projekt — juhendame sind samm-sammult';

  @override
  String get syncJoinExistingTitle => 'Liitu olemasoleva andmebaasiga';

  @override
  String get syncJoinExistingSubtitle =>
      'Skaneeri QR-kood andmebaasi omanikult või kleebi mandaadid';

  @override
  String get syncChooseAccountType => 'Vali konto tüüp';

  @override
  String get syncAccountTypeAnonymous => 'Anonüümne';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Kohene, e-posti pole vaja. Andmed seotud selle seadmega.';

  @override
  String get syncAccountTypeEmail => 'E-postkonto';

  @override
  String get syncAccountTypeEmailDesc =>
      'Logi sisse mis tahes seadmest. Taasta andmed, kui telefon kaob.';

  @override
  String get syncHaveAccountSignIn => 'On juba konto? Logi sisse';

  @override
  String get syncCreateNewAccount => 'Loo uus konto';

  @override
  String get syncTestConnection => 'Testi ühendust';

  @override
  String get syncTestingConnection => 'Testin...';

  @override
  String get syncConnectButton => 'Ühenda';

  @override
  String get syncConnectingButton => 'Ühendan...';

  @override
  String get syncDatabaseReady => 'Andmebaas valmis!';

  @override
  String get syncDatabaseNeedsSetup => 'Andmebaas vajab seadistamist';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Puudub';

  @override
  String get syncSqlEditorInstructions =>
      'Kopeeri allolev SQL ja käivita see oma Supabase SQL redaktoris (Armatuurlaud → SQL redaktor → Uus päring → Kleebi → Käivita)';

  @override
  String get syncCopySqlButton => 'Kopeeri SQL lõikelauale';

  @override
  String get syncRecheckSchemaButton => 'Kontrolli skeemi uuesti';

  @override
  String get syncDoneButton => 'Valmis';

  @override
  String syncSignedInAs(String email) {
    return 'Sisse logitud: $email';
  }

  @override
  String get syncEmailDescription =>
      'Sinu andmed sünkroonitakse kõikides seadmetes selle e-postiga.';

  @override
  String get syncSwitchToAnonymousTitle => 'Lülitu anonüümseks';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Jätka ilma e-postita, uus anonüümne sessioon';

  @override
  String get syncGuestDescription => 'Anonüümne, e-posti pole vaja.';

  @override
  String get syncOrDivider => 'või';

  @override
  String get syncHowToSyncQuestion => 'Kuidas soovid sünkroonida?';

  @override
  String get syncOfflineDescription =>
      'Sinu rakendus töötab täielikult võrguühenduseta. Pilvsünkroonimine on vabatahtlik.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo kogukond';

  @override
  String get syncModeCommunitySubtitle =>
      'Jaga lemmikuid ja hinnanguid kõigi kasutajatega';

  @override
  String get syncModePrivateTitle => 'Privaatne andmebaas';

  @override
  String get syncModePrivateSubtitle =>
      'Sinu oma Supabase — täielik andmekontroll';

  @override
  String get syncModeGroupTitle => 'Liitu grupiga';

  @override
  String get syncModeGroupSubtitle => 'Pere või sõprade jagatud andmebaas';

  @override
  String get syncPrivacyShared => 'Jagatud';

  @override
  String get syncPrivacyPrivate => 'Privaatne';

  @override
  String get syncPrivacyGroup => 'Grupp';

  @override
  String get syncStayOfflineButton => 'Jää võrguühenduseta';

  @override
  String get syncSuccessTitle => 'Edukalt ühendatud!';

  @override
  String get syncSuccessDescription =>
      'Sinu andmed sünkroonitakse nüüd automaatselt.';

  @override
  String get syncWizardTitleConnect => 'Ühenda TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Sinu andmebaas';

  @override
  String get syncSetupTitleJoinGroup => 'Liitu grupiga';

  @override
  String get syncSetupTitleAccount => 'Sinu konto';

  @override
  String get syncWizardBack => 'Tagasi';

  @override
  String get syncWizardNext => 'Edasi';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Samm $current / $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Loo Supabase projekt';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Puuduta allpool „Ava Supabase\"\n2. Loo tasuta konto (kui sul seda pole)\n3. Klõpsa „Uus projekt\"\n4. Vali nimi ja regioon\n5. Oota ~2 minutit käivitumist';

  @override
  String get syncWizardOpenSupabase => 'Ava Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Luba anonüümne sisselogimine';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Oma Supabase armatuurlaual:\n   Autentimine → Pakkujad\n2. Leia „Anonüümne sisselogimine\"\n3. Lülita SISSE\n4. Klõpsa „Salvesta\"';

  @override
  String get syncWizardOpenAuthSettings => 'Ava autentimisseaded';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopeeri oma mandaadid';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Mine Seaded → API oma armatuurlaual\n2. Kopeeri „Projekti URL\"\n3. Kopeeri „anon public\" võti\n4. Kleebi need allpool';

  @override
  String get syncWizardOpenApiSettings => 'Ava API seaded';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Liitu olemasoleva andmebaasiga';

  @override
  String get syncWizardScanQrCode => 'Skaneeri QR-kood';

  @override
  String get syncWizardAskOwnerQr =>
      'Palu andmebaasi omanikul näidata oma QR-koodi\n(Seaded → TankSync → Jaga)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Palu andmebaasi omanikul näidata oma QR-koodi';

  @override
  String get syncWizardEnterManuallyTitle => 'Sisesta käsitsi';

  @override
  String get syncWizardOrEnterManually => 'või sisesta käsitsi';

  @override
  String get syncWizardUrlHelperText =>
      'Tühikud ja reavahetused eemaldatakse automaatselt';

  @override
  String get syncCredentialsPrivateHint =>
      'Sisesta oma Supabase projekti mandaadid. Need leiad armatuurlaual Seaded > API alt.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Andmebaasi URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Juurdepääsuvõti';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-post';

  @override
  String get authPasswordLabel => 'Parool';

  @override
  String get authConfirmPasswordLabel => 'Kinnita parool';

  @override
  String get authPleaseEnterEmail => 'Palun sisesta oma e-post';

  @override
  String get authInvalidEmail => 'Kehtetu e-posti aadress';

  @override
  String get authPasswordsDoNotMatch => 'Paroolid ei ühti';

  @override
  String get authConnectAnonymously => 'Ühenda anonüümselt';

  @override
  String get authCreateAccountAndConnect => 'Loo konto ja ühenda';

  @override
  String get authSignInAndConnect => 'Logi sisse ja ühenda';

  @override
  String get authAnonymousSegment => 'Anonüümne';

  @override
  String get authEmailSegment => 'E-post';

  @override
  String get authAnonymousDescription =>
      'Kohene juurdepääs, e-posti pole vaja. Andmed seotud selle seadmega.';

  @override
  String get authEmailDescription =>
      'Logi sisse mis tahes seadmest. Taasta andmed, kui telefon kaob.';

  @override
  String get authSyncAcrossDevices =>
      'Sünkrooni andmed automaatselt kõikides sinu seadmetes.';

  @override
  String get authNewHereCreateAccount => 'Uus kasutaja? Loo konto';

  @override
  String get linkDeviceScreenTitle => 'Seadme linkimine';

  @override
  String get linkDeviceThisDeviceLabel => 'See seade';

  @override
  String get linkDeviceShareCodeHint => 'Jaga seda koodi oma teise seadmega:';

  @override
  String get linkDeviceNotConnected => 'Ühendamata';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopeeri kood';

  @override
  String get linkDeviceImportSectionTitle => 'Impordi teisest seadmest';

  @override
  String get linkDeviceImportDescription =>
      'Sisesta oma teise seadme kood, et importida selle lemmikud, teatised, sõidukid ja kulupäevik. Iga seade hoiab oma profiili ja vaikimisi sätted.';

  @override
  String get linkDeviceCodeFieldLabel => 'Seadme kood';

  @override
  String get linkDeviceCodeFieldHint => 'Kleebi UUID teisest seadmest';

  @override
  String get linkDeviceImportButton => 'Impordi andmed';

  @override
  String get linkDeviceHowItWorksTitle => 'Kuidas see töötab';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Seadmel A: kopeeri ülal olev seadme kood\n2. Seadmel B: kleebi see „Seadme kood\" väljale\n3. Puuduta „Impordi andmed\", et ühendada lemmikud, teatised, sõidukid ja kulupäevikud\n4. Mõlemal seadmel on kõik kombineeritud andmed\n\nIga seade hoiab oma anonüümset identiteeti ja profiili (eelistatud kütus, vaikimisi sõiduk, avakuvar). Andmed ühendatakse, ei teisaldata.';

  @override
  String get vehicleSetActive => 'Sea aktiivseks';

  @override
  String get swipeHide => 'Peida';

  @override
  String get evChargingSection => 'EV laadimine';

  @override
  String get fuelStationsSection => 'Kütusejaamad';

  @override
  String get yourRating => 'Sinu hinnang';

  @override
  String get noStorageUsed => 'Salvestusruumi pole kasutatud';

  @override
  String get aboutReportBug => 'Teata veast / Tee ettepanek';

  @override
  String get aboutSupportProject => 'Toeta seda projekti';

  @override
  String get aboutSupportDescription =>
      'See rakendus on tasuta, avatud lähtekoodiga ja reklaamivaba. Kui leiad selle kasulikuks, kaalu arendaja toetamist.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luksemburgi kütushinnad on riiklikult reguleeritud ja ühtlased kogu riigis.';

  @override
  String get luxembourgFuelUnleaded95 => 'Pliivabal 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Pliivabal 98';

  @override
  String get luxembourgFuelDiesel => 'Diisel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luksemburgi reguleeritud hinnad pole saadaval.';

  @override
  String get reportIssueTitle => 'Teata probleemist';

  @override
  String get enterCorrection => 'Palun sisesta parandus';

  @override
  String get reportNoBackendAvailable =>
      'Raportit ei saanud saata: selle riigi jaoks pole raporteerimisteenus seadistatud. Luba TankSync Seadetes kogukonna raportite saatmiseks.';

  @override
  String get correctName => 'Õige jaama nimi';

  @override
  String get correctAddress => 'Õige aadress';

  @override
  String get wrongE85Price => 'Vale E85 hind';

  @override
  String get wrongE98Price => 'Vale Super 98 hind';

  @override
  String get wrongLpgPrice => 'Vale LPG hind';

  @override
  String get wrongStationName => 'Vale jaama nimi';

  @override
  String get wrongStationAddress => 'Vale aadress';

  @override
  String get independentStation => 'Iseseisev jaam';

  @override
  String get serviceRemindersSection => 'Hooldustuletused';

  @override
  String get serviceRemindersEmpty =>
      'Tuletusi pole veel — vali eelseadistus ülalt.';

  @override
  String get addServiceReminder => 'Lisa tuletis';

  @override
  String get serviceReminderPresetOil => 'Õli (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Õlivahetus';

  @override
  String get serviceReminderPresetTires => 'Rehvid (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Rehvid';

  @override
  String get serviceReminderPresetInspection => 'Ülevaatus (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Ülevaatus';

  @override
  String get serviceReminderLabel => 'Silt';

  @override
  String get serviceReminderInterval => 'Intervall (km)';

  @override
  String get serviceReminderLastService => 'Viimane hooldus';

  @override
  String get serviceReminderMarkDone => 'Märgi tehtuks';

  @override
  String get serviceReminderDueTitle => 'Hooldus tähtaeg';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label on tähtaeg — $kmOver km üle intervalli.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Registreeru OPINETis tasuta API-võtme saamiseks';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registreeru CNEs tasuta API-võtme saamiseks';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Kas see on sinu auto?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders silindrit, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Osaline teave (võrguühenduseta). Saad allpool muuta.';

  @override
  String get vinDecodeError => 'Ei suutnud seda VIN-koodi dekodeerida';

  @override
  String get vinInvalidFormat => 'Kehtetu VIN-koodi formaat';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2 ühendus kadunud — salvestamine peatatud';

  @override
  String get obd2PauseBannerResume => 'Jätka salvestamist';

  @override
  String get obd2PauseBannerEnd => 'Lõpeta salvestamine';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Recording with GPS — OBD2 reconnecting';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Kulukalibreerimine uuendatud sõidukile $vehicleName — täpsus paranes $percent% võrra';
  }

  @override
  String get veResetConfirmTitle => 'Lähtestada mahuline efektiivsus?';

  @override
  String get veResetConfirmBody =>
      'See hülgab õpitud mahulise efektiivsuse (η_v) ja taastab vaikeväärtuse (0,85). Reisitaseme kütusevoo hinnangud lähevad tagasi tootja konstandile, kuni kalibreerimistööriist kogub tulevaste reiside uued näidised.';

  @override
  String get alertsRadiusSectionTitle => 'Raadiusteteatised';

  @override
  String get alertsRadiusAdd => 'Lisa raadiusteatis';

  @override
  String get alertsRadiusEmptyTitle => 'Raadiusteatiseid pole veel';

  @override
  String get alertsRadiusEmptyCta => 'Loo raadiusteatis';

  @override
  String get alertsRadiusCreateTitle => 'Loo raadiusteatis';

  @override
  String get alertsRadiusLabelHint => 'Silt (nt Kodu diisel)';

  @override
  String get alertsRadiusFuelType => 'Kütuse liik';

  @override
  String get alertsRadiusThreshold => 'Künnis (€/L)';

  @override
  String get alertsRadiusKm => 'Raadius (km)';

  @override
  String get alertsRadiusCenterGps => 'Kasuta minu asukohta';

  @override
  String get alertsRadiusCenterPostalCode => 'Sihtnumber';

  @override
  String get alertsRadiusSave => 'Salvesta';

  @override
  String get alertsRadiusCancel => 'Tühista';

  @override
  String get alertsRadiusDeleteConfirm => 'Kustutada raadiusteatis?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 ühendatud: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Ühenda OBD2 adapter';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel langes lähedalasuvates jaamades';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount jaamas langes kuni $maxDropCents¢ viimase tunni jooksul';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankimine salvestatud';

  @override
  String get radiusAlertsEntryTitle => 'Raadiusteatised ja statistika';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Saa teadet, kui hinnad langevad sinu lähedal';

  @override
  String get notFoundTitle => 'Lehte ei leitud';

  @override
  String notFoundBody(String location) {
    return '\"$location\" ei leitud.';
  }

  @override
  String get notFoundHomeButton => 'Avaleht';

  @override
  String get consumptionTabHiddenNotice =>
      'Kulu kaart on sinu profiiliseadetega peidetud.';

  @override
  String get swipeBetweenTabsHint =>
      'Nipp: pühkige vasakule või paremale kaartide vahel lülitumiseks.';

  @override
  String get discardChangesTitle => 'Hüljata muudatused?';

  @override
  String get discardChangesBody =>
      'Sul on salvestamata muudatused. Lahkumine nüüd hüljab need.';

  @override
  String get discardChangesConfirm => 'Hülga';

  @override
  String get discardChangesKeepEditing => 'Jätka muutmist';

  @override
  String get tankSyncSectionSubtitle => 'Pilvsünkroonimine sinu seadmetes';

  @override
  String get mapUnavailable => 'Kaart pole saadaval';

  @override
  String get routeNameHintExample => 'nt Pariis → Lyon';

  @override
  String get priceStatsCurrent => 'Praegune';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenigi API-võti';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMapi API-võti';

  @override
  String get tapToUpdateGpsPosition => 'Puudutage GPS-asukoha värskendamiseks';

  @override
  String get nameLabel => 'Nimi';

  @override
  String get obd2ErrorPermissionDenied =>
      'OBD2-adapteriga ühenduse loomiseks on vaja Bluetoothi luba.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Lülitage Bluetooth sisse ja proovige uuesti.';

  @override
  String get obd2ErrorScanTimeout =>
      'Läheduses ei leitud OBD2-adapterit. Veenduge, et see on ühendatud ja sisse lülitatud.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2-adapter ei vastanud. Lülitage süüde sisse ja proovige uuesti.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2-adapter saatis tundmatu vastuse. See võib olla ühildumatu — proovige teist adapterit.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2-adapter katkestas ühenduse. Ühendage uuesti ja proovige uuesti.';

  @override
  String get onboardingExploreDemoData => 'Tutvu demoandmetega';

  @override
  String get achievementSmoothDriver => 'Sujuv seeria';

  @override
  String get achievementSmoothDriverDesc =>
      'Sõida 5 reisi järjest sujuva sõiduga 80 või kõrgema tulemusega.';

  @override
  String get achievementColdStartAware => 'Külmkäivituse teadlik';

  @override
  String get achievementColdStartAwareDesc =>
      'Hoia terve kuu külmkäivituse kütusekulud alla 2% kogu kütusest — ühenda lühireisid.';

  @override
  String get achievementHighwayMaster => 'Kiirtee meister';

  @override
  String get achievementHighwayMasterDesc =>
      'Lõpeta 30 km+ reis ühtlase kiirusega ja sujuva sõidu tulemusega 90 või rohkem.';

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
    return '$price $currency (eesmärk: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel langes lähedalasuvates tanklates';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count tanklat langes viimase tunni jooksul kuni $cents¢';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count tanklat ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count veel';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Tausta hinnateavitused töötavad praegu ainult Saksamaa tanklate puhul. See teavitus salvestatakse, kuid ei pruugi teid kunagi teavitada, kuni riikidevahelised teavitused saabuvad.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Raadiuse teavitused kontrollivad praegu ainult Saksamaa tanklaid.';

  @override
  String get approachOverlaySection => 'Tankla lähenemise ülekate';

  @override
  String get approachRadiusLabel => 'Raadius';

  @override
  String approachRadiusCaption(String km) {
    return 'Ülekate suureneb ja kuvab hinda, kui olete tanklast vähem kui $km km kaugusel';
  }

  @override
  String get approachPriceModeLabel => 'Kuva hind';

  @override
  String get approachPriceModeNearest => 'Lähim tankla';

  @override
  String get approachPriceModeCheapestInRadius => 'Odavaim raadiuses';

  @override
  String get approachMinPollLabel => 'Min. värskendus';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Lähima tankla värskendamise alampiir (kiirem suurel kiirusel, mitte kunagi sagedamini kui $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testi lähenemise ülekatet';

  @override
  String get approachTestStopButton => 'Peata test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktiivne — ülekate näitab hinda jaamale $station';
  }

  @override
  String get approachTestUnavailable =>
      'Lisage lemmikjaam, et lähenemise ülekatet testida';

  @override
  String approachStationDistance(String meters) {
    return '$meters m kaugusel';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return '$km km away';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximity $percent%';
  }

  @override
  String get authErrorNoNetwork => 'Võrguühendus puudub. Proovi hiljem uuesti.';

  @override
  String get authErrorInvalidCredentials =>
      'Vale e-post või parool. Kontrolli oma mandaate.';

  @override
  String get authErrorUserAlreadyExists =>
      'See e-post on juba registreeritud. Proovi sisselogimist.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Palun kontrolli oma e-posti ja kinnita oma konto esmalt.';

  @override
  String get authErrorGeneric =>
      'Sisselogimine ebaõnnestus. Palun proovi uuesti.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Taustakoht — ainult automaatretseptimiseks';

  @override
  String get autoRecordConsentExplanationTitle => 'Selle loa kohta';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automaatsalvestamiseks on vaja taustaasukoha, et tuvastada, millal hakkad sõitma, kui rakendus on suletud. Seda luba kasutab ainult automaatsalvestamine — jaama otsing ja kaardi tsentreerimine kasutavad eraldi esiplaani asukohta.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Selge';

  @override
  String get autoRecordConsentExplanationTooltip => 'Mida see tähendab?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Puuduta süsteemiseadetes haldamiseks';

  @override
  String get autoRecordSectionTitle => 'Automaatsalvestamine';

  @override
  String get autoRecordToggleLabel => 'Automaatsalvesta reisid';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automaatsalvestamine aktiveerub järgmine kord, kui sisenete autosse.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Ühenda OBD2 adapter automaatsalvestamise lubamiseks.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Luba taustakoht, et automaatsalvestamine töötaks ka ekraan väljas.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Ühenda adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Käivituskiirus (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Salvestuse viivitus pärast katkestust (sekundid)';

  @override
  String get autoRecordPairedAdapterLabel => 'Ühendatud adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Adapterit pole ühendatud. Ühenda esmalt OBD2 seadistuse kaudu.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Taustakoht lubatud';

  @override
  String get autoRecordBackgroundLocationRequest => 'Taotle luba';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Miks „Alati lubada\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automaatsalvestamine voogedastatab GPS-koordinaate OBD-II esiplaaniteenusest ka siis, kui ekraan on väljas, et marsruut jääks täpseks. Android nõuab selle toimimiseks pärast seadme lukustamist valikut „Alati lubada\".';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Ava seaded';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Asukohaluba vajalik';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Taustaasukoha taotlemine ebaõnnestus';

  @override
  String get autoRecordBadgeClearTooltip => 'Tühjenda loendur';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Ühenda adapter allolevas jaotises automaatsalvestamise lubamiseks';

  @override
  String get exportBackupTooltip => 'Ekspordi varukoopia';

  @override
  String get exportBackupReady => 'Varukoopia valmis — vali sihtkoht';

  @override
  String get exportBackupFailed =>
      'Varukoopia eksportimine ebaõnnestus — palun proovi uuesti';

  @override
  String get restoreBackupTooltip => 'Restore backup';

  @override
  String get restoreBackupDialogTitle => 'Restore backup';

  @override
  String get restoreBackupDialogBody =>
      'Merge adds and updates records from the backup and keeps everything already on this device. Replace deletes all current data first, then restores only the backup — this cannot be undone.';

  @override
  String get restoreBackupMergeAction => 'Merge';

  @override
  String get restoreBackupReplaceAction => 'Replace all';

  @override
  String restoreBackupSuccess(int count) {
    return 'Backup restored — $count records imported';
  }

  @override
  String get restoreBackupEmpty => 'Backup restored — it contained no records';

  @override
  String get restoreBackupCorrupt =>
      'Restore failed — this file is not a valid Tankstellen backup';

  @override
  String get restoreBackupFailed =>
      'Restore failed — the file could not be read';

  @override
  String get brokenMapChipVerifying => 'MAP-sensor kontrollib…';

  @override
  String get brokenMapChipDisclaimer => 'MAP-näidud kahtlased';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-sensor loeb valesti — kütuse näidud võivad olla 50–80% liiga madalad. Proovi teist adapterit.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-sensor ebausaldusväärsetu. Kuvab tankimise keskmised reaalajas kütusemäära asemel.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP-sensor: kontrollitud ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP-sensor: kontrollimine ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP-sensor: kahtlane ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-sensor: $posterior% ± $margin% (kontrollitud)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-sensori diagnostika';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Katkise MAP tõenäosus: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count vaatlust salvestatud';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Kinnitatud puhas';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Selle sõiduki MAP-sensorit pole veel täheldatud.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Blokeeritud adapterid';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Adaptereid pole blokeeritud.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — märgitud $percent% katkisena';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Tühjenda';

  @override
  String get brokenMapRevPromptTitle => 'Kiirendage mootorit';

  @override
  String get brokenMapRevPromptBody =>
      'Vajutage lühidalt gaasipedaalile, et rakendus saaks kontrollida, kas MAP-sensor reageerib.';

  @override
  String get brokenMapRevPromptConfirm => 'Valmis — kiirendasin';

  @override
  String get calibrationAdvancedTitle => 'Täiustatud kalibreerimine';

  @override
  String get calibrationDisplacementLabel => 'Mootori töömaht (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Mahuline efektiivsus (η_v)';

  @override
  String get calibrationAfrLabel => 'Õhu-kütuse suhe (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Kütuse tihedus (g/L)';

  @override
  String get calibrationSourceDetected => '(tuvastatud VIN-koodist)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(kataloog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(vaikimisi)';

  @override
  String get calibrationSourceManual => '(käsitsi)';

  @override
  String get calibrationResetToDetected => 'Lähtesta tuvastatud väärtusele';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibreeritud, $samples näidist)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (õppib, $samples näidist)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (vaikimisi — plein-complet\'i pole veel)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples valimit';
  }

  @override
  String get calibrationResetLearner => 'Lähtesta õppija';

  @override
  String get calibrationBasisAtkinson => 'Atkinson tsükkel';

  @override
  String get calibrationBasisVnt => 'VNT diisel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbokompressor + DI';

  @override
  String get calibrationBasisTurbo => 'Turbokompressor';

  @override
  String get calibrationBasisNaDi => 'Loomuliku imemisega + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(kataloog: $makeModel — $basis vaikimisi)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Sinu $makeModel on märgitud diislikütuseks, kuid vastab bensiinikataloogi kirjele. Puuduta uuendamiseks.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Uuenda';

  @override
  String get consumptionTabFuel => 'Kütus';

  @override
  String get consumptionTabCharging => 'Laadimine';

  @override
  String get noChargingLogsTitle => 'Laadimislogisid pole veel';

  @override
  String get noChargingLogsSubtitle =>
      'Lisa oma esimene laadimissessioon EUR/100 km ja kWh/100 km jälgimise alustamiseks.';

  @override
  String get addChargingLog => 'Logi laadimine';

  @override
  String get addChargingLogTitle => 'Logi laadimissessioon';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Kogumaksumus';

  @override
  String get chargingTimeMin => 'Laadimisaeg (min)';

  @override
  String get chargingStationName => 'Jaam (vabatahtlik)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Võrdlemiseks on vaja eelmist logi';

  @override
  String get chargingLogButtonLabel => 'Logi laadimine';

  @override
  String get chargingCostTrendTitle => 'Laadimiskulu trend';

  @override
  String get chargingEfficiencyTitle => 'Efektiivsus (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Andmeid pole veel piisavalt';

  @override
  String get chargingChartsMonthAxis => 'Kuu';

  @override
  String get consoFeatureGroupTitle => 'Kulu';

  @override
  String get consoFeatureGroupDescription =>
      'Jälgi oma kütusekulu — käsitsi tankimised või automaatne OBD2 reisalvestamine.';

  @override
  String get consoModeOff => 'Väljas';

  @override
  String get consoModeFuel => 'Kütus';

  @override
  String get consoModeFuelAndTrips => 'Kütus + reisid';

  @override
  String get consoModeOffDescription =>
      'Kulu kaarti ega Kulu seadete jaotist pole.';

  @override
  String get consoModeFuelDescription =>
      'Ainult käsitsi tankimised. Kasulik ilma OBD2 adapterita.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Lisab automaatse OBD2 reisalvestamise. Vajalik ühendatud adapter.';

  @override
  String get consoGroupVehicles => 'Vehicles';

  @override
  String get consoGroupCoaching => 'Coaching while driving';

  @override
  String get consoGroupRewards => 'Rewards & savings';

  @override
  String get consoGroupTroubleshooting => 'Troubleshooting';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Täpsus: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Kõrge';

  @override
  String get consumptionAccuracyMedium => 'Keskmine';

  @override
  String get consumptionAccuracyLow => 'Madal';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Täielik kalibreerimine: tankimised pluss OBD2-ga salvestatud sõidud. L/100 km näit vastab tegelikkusele mõne protsendi täpsusega.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankimised on kütusekulu mudeli ankurdanud, kuid ühtegi OBD2-sõitu pole veel arvestatud. Salvesta üks ühendatud OBD2-ga, et jõuda kõrge täpsuseni.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Ainult GPS — ükski tankimine pole veel kütusekulu mudelit ankurdanud. Lisa paar täistankimist, et täpsust parandada.';

  @override
  String get moreActionsTooltip => 'More';

  @override
  String get exportBackupMenuLabel => 'Export backup';

  @override
  String get restoreBackupMenuLabel => 'Restore backup';

  @override
  String get carbonDashboardMenuLabel => 'Carbon dashboard';

  @override
  String get settingsMenuLabel => 'Settings';

  @override
  String get consumptionStatsPageTitle => 'Consumption statistics';

  @override
  String get consumptionStatsComparisonTitle => 'This month vs last month';

  @override
  String get consumptionStatsTrendsTitle => 'Evolution over time';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Log fill-ups across at least two months to compare.';

  @override
  String get consumptionStatsPricePerLiter => 'Avg price/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litres per month';

  @override
  String get consumptionStatsChartSpend => 'Spend per month';

  @override
  String get consumptionStatsChartPricePerLiter => 'Price per litre';

  @override
  String get consumptionStatsChartConsumption => 'L/100km per month';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count osalist tankimist ootavad plein complet\'i — pole keskmises',
      one: '1 osaline tankimine ootab plein complet\'i — pole keskmises',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% kütusest autokorrektsiooni kaudu — vaata kirjeid üle';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel => 'Autokorrektsioon — puuduta muutmiseks';

  @override
  String get fillUpCorrectionEditTitle => 'Muuda autokorrektsiooni';

  @override
  String get fillUpCorrectionEditExplainer =>
      'See kirje loodi automaatselt salvestatud reiside ja pumbatava kütuse vahe sulgemiseks. Muuda väärtusi, kui tead tegelikke numbreid.';

  @override
  String get fillUpCorrectionDelete => 'Kustuta korrektsioon';

  @override
  String get fillUpCorrectionStation => 'Jaama nimi (vabatahtlik)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Kreeka)';

  @override
  String get greeceCommunityApiNotice =>
      'Põhineb kogukonna hallatava fuelpricesgr API-l';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumeenia)';

  @override
  String get romaniaScrapingNotice =>
      'Põhineb pretcarburant.ro andmetel (Konkurentsiamet + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country jaamad $km km kaugusel — €$price/L odavam';
  }

  @override
  String get crossBorderTapToSwitch => 'Puuduta riigi vahetamiseks';

  @override
  String get crossBorderDismissTooltip => 'Sulge';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Arendaja tööriistad';

  @override
  String get developerToolsSubtitle =>
      'Diagnostika ja silumistööriistad — nähtavad ainult arendaja/silumisrežiimis.';

  @override
  String get developerToolsMenuSubtitle => 'Vealogi, testteatised, diagnostika';

  @override
  String get developerToolsErrorLogGroupTitle => 'Vealogi';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Salvesta vealogi ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Tühjenda vealogi';

  @override
  String get developerToolsViewErrorLog => 'Vaata vealogi';

  @override
  String get developerToolsErrorLogEmpty => 'Veajälgi pole salvestatud.';

  @override
  String get developerToolsAlertsGroupTitle => 'Hoiatused ja teatised';

  @override
  String get developerToolsFireTestNotification => 'Saada testteatis';

  @override
  String get developerToolsTestNotificationTitle => 'Testteatis';

  @override
  String get developerToolsTestNotificationBody =>
      'Kui sa seda loed, siis teatised töötavad.';

  @override
  String get developerToolsTestNotificationSent => 'Testteatis saadetud.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Teatised on blokeeritud — luba need süsteemiseadetes ja proovi uuesti.';

  @override
  String get developerToolsRunTestAlert => 'Käivita testhoiatuse konveier';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testhoiatus käivitatud — konveier edastas $count teatist.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testhinnahoiatus';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Sünteetiline vaste: läheduses leiti sinu sihist odavam jaam.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostika';

  @override
  String get developerToolsFeatureFlagDump => 'Funktsioonilippude inspektor';

  @override
  String get developerToolsFlagOn => 'Sees';

  @override
  String get developerToolsFlagOff => 'Väljas';

  @override
  String get developerToolsClearCaches => 'Tühjenda vahemälud';

  @override
  String get developerToolsCachesCleared => 'Vahemälud tühjendatud.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopeeri diagnostika';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostika kopeeritud lõikelauale.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Järgu teave';

  @override
  String get developerToolsBuildVersion => 'Rakenduse versioon';

  @override
  String get developerToolsBuildChannel => 'Järgu kanal';

  @override
  String get insightCardTitle => 'Kõige raiskavamad käitumised';

  @override
  String get insightEmptyState =>
      'Märkimisväärseid ebaefektiivsusi pole — nii hoiad edasi!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Mootor üle 3000 RPM ($pctTime% reisist): raisati $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count järsku kiirendust: raisati $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Tühikäik ($pctTime% reisist): raisati $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% reisist';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Madala käiguga pingutamine ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Pikkadel peatustel lülita mootor välja, selle asemel et seda tühikäigul töötada lasta.';

  @override
  String get lessonAdviceHighRpm =>
      'Vaheta varem kõrgemale käigule, et hoida mootor kõrgete pöörete tsoonist eemal.';

  @override
  String get lessonAdviceHardAccel =>
      'Vajuta gaasi sujuvalt — ühtlane kiirendus kulutab vähem kütust.';

  @override
  String get lessonAdviceLowGear =>
      'Vaheta varem kõrgemale käigule, et mootor töötaks madalamatel ja säästlikumatel pööretel.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Püsiv suur kiirus ($pctTime% sõidust): raisatud $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Püsiv suur kiirus ($pctTime% sõidust)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Üle 110 km/h võta gaasi maha – õhutakistus kasvab järsult, veidi aeglasemalt säästab palju kütust.';

  @override
  String get lessonSmoothDrivingTitle => 'Sujuv sõit – tubli töö!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Sellel sõidul polnud järsku kiirendamist ega pidurdamist – ühtlane sõit hoiab kulu madalal.';

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
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Climbing at $gradePercent% grade ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Carry momentum into a hill and feed the throttle smoothly — surging on a climb burns extra fuel.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stop-and-go restarts: wasted $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticipate traffic and coast toward stops so you roll rather than restart — pulling away from a dead stop is the thirstiest part of stop-and-go.';

  @override
  String get drivingScoreCardTitle => 'Sõiduhinnang';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Koondhinne tühikäigu, järsu kiirenduse, järsu pidurduse ja kõrge RPM aja põhjal. „Parem kui X% varasematest reisidest\" võrdlus lisatakse järgmises versioonis.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Sõiduhinnang $score 100-st';
  }

  @override
  String get drivingScorePenaltyIdling => 'Tühikäik';

  @override
  String get drivingScorePenaltyHardAccel => 'Järsk kiirendus';

  @override
  String get drivingScorePenaltyHardBrake => 'Järsk pidurdus';

  @override
  String get drivingScorePenaltyHighRpm => 'Kõrge RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Täisgaas';

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
  String get gpsKpiCardTitle => 'GPS efficiency';

  @override
  String get gpsKpiRpa => 'Positive acceleration (RPA)';

  @override
  String get gpsKpiPke => 'Kinetic energy demand (PKE)';

  @override
  String get gpsKpiVapos => 'Acceleration intensity (VAPOS)';

  @override
  String get gpsKpiCoast => 'Coasting share';

  @override
  String get gpsKpiClimbEnergy => 'Climb energy';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs your efficient baseline';
  }

  @override
  String get ecoRouteOption => 'Öko';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L säästetud';
  }

  @override
  String get ecoRouteHint =>
      'Targem sõit — eelistab ühtlast kiirteed sika-saka otseteedele.';

  @override
  String get favoritesShareAction => 'Jaga';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — lemmikud $date';
  }

  @override
  String get favoritesShareError => 'Jagatava pildi loomine ebaõnnestus';

  @override
  String get featureManagementSectionTitle => 'Funktsioonide haldus';

  @override
  String get featureManagementSectionSubtitle =>
      'Lülita üksikuid funktsioone sisse või välja. Mõned funktsioonid sõltuvad teistest — lülitid on keelatud, kuni eeltingimused on täidetud.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2 reisi salvestamine';

  @override
  String get featureDescription_obd2TripRecording =>
      'Salvesta reisid automaatselt OBD2 kaudu.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification =>
      'Sõiduhinded ja teenitud märgid.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptilise ökokoach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Reaalajas haptiliseid tagasiside reisi ajal.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Seadmetevaheline sünkroonimine Supabase kaudu.';

  @override
  String get featureLabel_consumptionAnalytics => 'Kuluanalüütika';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Tankimise ja reisi analüüsi kaart.';

  @override
  String get featureLabel_baselineSync => 'Baasjoone sünkroonimine';

  @override
  String get featureDescription_baselineSync =>
      'Sünkrooni sõitmise baasjoon TankSync kaudu.';

  @override
  String get featureLabel_unifiedSearchResults => 'Ühendatud otsingutulemused';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Üks tulemuste loend, mis ühendab kütuse ja EV jaamad.';

  @override
  String get featureLabel_priceAlerts => 'Hinnateatised';

  @override
  String get featureDescription_priceAlerts =>
      'Lävisepõhised hinnalanguse teatised.';

  @override
  String get featureLabel_priceHistory => 'Hinnaloo';

  @override
  String get featureDescription_priceHistory =>
      '30-päeva hinnagrafaafikud jaama üksikasjades.';

  @override
  String get featureLabel_routePlanning => 'Marsruudi planeerimine';

  @override
  String get featureDescription_routePlanning =>
      'Odavaim peatus sinu marsruudil.';

  @override
  String get featureLabel_evCharging => 'EV laadimine';

  @override
  String get featureDescription_evCharging =>
      'Laadimisjaamu OpenChargeMap kaudu.';

  @override
  String get featureLabel_glideCoach => 'Libisemise juhendaja';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling juhendamine OSM liiklussignaalide abil.';

  @override
  String get featureLabel_gpsTripPath => 'GPS reisi marsruut';

  @override
  String get featureDescription_gpsTripPath =>
      'Salvesta GPS marsruudinäidised iga reisi kõrvale.';

  @override
  String get featureLabel_autoRecord => 'Automaatsalvestamine';

  @override
  String get featureDescription_autoRecord =>
      'Alusta reis automaatselt, kui OBD2 adapter ühendub liikuva sõidukiga.';

  @override
  String get featureLabel_showFuel => 'Kuva kütusejaamad';

  @override
  String get featureDescription_showFuel =>
      'Kuva bensiin/diisli jaamatulemused otsingus ja kaardil.';

  @override
  String get featureLabel_showElectric => 'Kuva laadimisajamad';

  @override
  String get featureDescription_showElectric =>
      'Kuva EV laadimisjaamu otsingus ja kaardil.';

  @override
  String get featureLabel_showConsumptionTab => 'Kulu kaart';

  @override
  String get featureDescription_showConsumptionTab =>
      'Kuva kuluanalüütika kaart põhinavigatsioonis.';

  @override
  String get featureBlockedEnable_gamification =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureBlockedEnable_baselineSync => 'Luba esmalt TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureBlockedEnable_showFuel => 'Eeltingimused pole täidetud';

  @override
  String get featureBlockedEnable_showElectric => 'Eeltingimused pole täidetud';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite hinnprognoos';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Seadmes töötav hinnaprognoosi mudel — tuletamine toimub lokaalselt; funktsioonid ja prognoosid ei lahku seadmest.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Luba esmalt hinnaloo';

  @override
  String get featureLabel_fuelCalculator => 'Kütusekalkulator';

  @override
  String get featureDescription_fuelCalculator =>
      'Ligipääsetav kütusekulu kalkulaator otsingutulemuste kaudu.';

  @override
  String get featureLabel_carbonDashboard => 'CO2 armatuurlaud';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2 jalajälje armatuurlaud, ligipääsetav Kulu kaardil.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperimentaalsed OEM PID-id';

  @override
  String get featureDescription_experimentalOemPids =>
      'Loe täpset paagiliitrite arvu tootjaspetsiifiliste PID-ide kaudu toetatud adapteritel.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Luba esmalt OBD2 reisi salvestamine';

  @override
  String get featureLabel_paymentQrScan => 'Skaneeri makse QR';

  @override
  String get featureDescription_paymentQrScan =>
      'Skaneeri-et-maksa QR-lugeja jaama üksikasjade ekraanil.';

  @override
  String get featureLabel_communityPriceReports => 'Kogukonna hinnaaruanded';

  @override
  String get featureDescription_communityPriceReports =>
      'Teata jaama hinnast jaama üksikasjade ekraanil.';

  @override
  String get featureLabel_obd2Optional => 'Nõua OBD2 sõitude salvestamiseks';

  @override
  String get featureDescription_obd2Optional =>
      'Kui välja lülitatud, salvestab rakendus sõite ainult GPS-iga ilma OBD2-adapterita. Coaching on piiratud — pole hetkelist L/100 km, vähem mootori signaale.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Tšeki OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skannige trükitud tšekk lehel Lisa tankimine, et eeltäita kuupäev, liitrid, kogusumma ja tankla.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'Tankuri ekraani OCR (eksperimentaalne)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Skannige tankuri ekraani, et eeltäita vorm. Tuvastus pole tänapäeval usaldusväärne — aktiveerige ainult siis, kui soovite testida.';

  @override
  String get featureLabel_developerPatToken =>
      'Arendaja tagasiside (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Lubab vigaste skannimiste tagasisidepaneeli, mis loob isikliku juurdepääsuvõtmega automaatselt GitHubi probleeme. Edasijõudnud kasutajate / kaastöötajate funktsioon.';

  @override
  String get featureLabel_debugMode => 'Arendaja/silumisrežiim';

  @override
  String get featureDescription_debugMode =>
      'Kuvab seadetes jaotise Arendaja tööriistad koos diagnostikaga: vealogi eksport, testteatised, testhoiatuse konveieri käivitamine, funktsioonilippude loend, vahemälude tühjendamine ja diagnostika kopeerimine.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get featureLabel_voiceAnnouncements => 'Voice announcements';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Speak nearby cheap fuel stations aloud as you drive, so you can keep your eyes on the road.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Enable the approach overlay first';

  @override
  String get featureGroupTitle_finding => 'Finding & map';

  @override
  String get featureGroupDescription_finding =>
      'Where to fuel up or charge — search, map, routing.';

  @override
  String get featureGroupTitle_prices => 'Prices & alerts';

  @override
  String get featureGroupDescription_prices =>
      'Price drops, history, and reporting.';

  @override
  String get featureGroupTitle_radar => 'Fuel Station Radar';

  @override
  String get featureGroupDescription_radar => 'Live price nudges as you drive.';

  @override
  String get featureGroupTitle_sync => 'Sync & backup';

  @override
  String get featureGroupDescription_sync => 'Keep your data across devices.';

  @override
  String get featureGroupTitle_input => 'Input & scanning';

  @override
  String get featureGroupDescription_input => 'Helpers for logging fill-ups.';

  @override
  String get featureGroupTitle_developer => 'Developer & experimental';

  @override
  String get featureGroupDescription_developer =>
      'Power-user and contributor tools.';

  @override
  String get feedbackConsentTitle => 'Saata raport GitHubile?';

  @override
  String get feedbackConsentBody =>
      'See loob avaliku pileti meie GitHubi hoidlasse koos sinu fotoga ja OCR tekstiga. Isikuandmeid (asukoht, konto ID) ei saadeta. Jätkata?';

  @override
  String get feedbackConsentContinue => 'Jätka';

  @override
  String get feedbackConsentCancel => 'Tühista';

  @override
  String get feedbackConsentLater => 'Hiljem';

  @override
  String get feedbackTokenSectionTitle =>
      'Halva skaneerimise tagasiside (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Ebaõnnestunud skaneerimisest automaatse GitHubi pileti avamiseks kleebi GitHub PAT (hoidla `tankstellen` juures `public_repo` ulatus). Muidu jääb käsitsi jagamine saadavaks.';

  @override
  String get feedbackTokenStatusSet => 'Tunnus seadistatud';

  @override
  String get feedbackTokenStatusUnset => 'Tunnust pole';

  @override
  String get feedbackTokenSet => 'Seadista';

  @override
  String get feedbackTokenClear => 'Tühjenda';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personaalse juurdepääsu tunnus';

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
      'Kontrollitud adapteri poolt';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Ei vasta adapteri näidule';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Sinu kirje: $userL L. Adapter ütleb: $adapterL L (enne/pärast kütuse taseme mõõtmist). Kasutada adapteri väärtust?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Hoia minu kirje';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Kasuta adapteri väärtust';

  @override
  String get scanReceiptNoData => 'Kviitungiandmeid ei leitud — proovi uuesti';

  @override
  String get scanReceiptSuccess =>
      'Kviitung skaneeritud — kontrolli väärtusi. Puuduta allpool „Teata skaneerimisveast\", kui midagi on vale.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skaneeriminen ebaõnnestus: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Pumba kuvarit ei saa lugeda — proovi uuesti';

  @override
  String get scanPumpSuccess => 'Pumba kuvar skaneeritud — kontrolli väärtusi.';

  @override
  String get scanPumpGlare =>
      'Ekraanil on liiga palju peegeldust — proovige uuesti väikese nurga alt, et numbrid ei oleks ülevalgustatud.';

  @override
  String scanPumpFailed(String error) {
    return 'Pumba skaneerimineen ebaõnnestus: $error';
  }

  @override
  String get badScanReportTitle => 'Teata skaneerimisveast';

  @override
  String get badScanReportTitleReceipt => 'Teata skaneerimisveast — kviitung';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Teata skaneerimisveast — pumba kuvar';

  @override
  String get pumpScanFailureTitle => 'Kuvar loetamatu';

  @override
  String get pumpScanFailureBody =>
      'Skaneeriminen ei suutnud pumba kuvarit lugeda. Mida soovid teha?';

  @override
  String get pumpScanFailureCorrectManually => 'Paranda käsitsi';

  @override
  String get pumpScanFailureReport => 'Teata';

  @override
  String get pumpScanFailureRemove => 'Eemalda foto';

  @override
  String get badScanReportHint =>
      'Jagame kviitungifoto ja mõlemad väärtuste komplektid, et järgmine versioon õpiks selle paigutust.';

  @override
  String get badScanReportShareAction => 'Jaga raportit + fotot';

  @override
  String get badScanReportFieldBrandLayout => 'Brändi paigutus';

  @override
  String get badScanReportFieldTotal => 'Kokku';

  @override
  String get badScanReportFieldPricePerLiter => 'Hind/L';

  @override
  String get badScanReportFieldStation => 'Jaam';

  @override
  String get badScanReportFieldFuel => 'Kütus';

  @override
  String get badScanReportFieldDate => 'Kuupäev';

  @override
  String get badScanReportHeaderField => 'Väli';

  @override
  String get badScanReportHeaderScanned => 'Skaneeritud';

  @override
  String get badScanReportHeaderYouTyped => 'Sinu sisestus';

  @override
  String get badScanReportCreateTicket => 'Loo pilet';

  @override
  String get badScanReportOpenInBrowser => 'Ava brauseris';

  @override
  String get badScanReportFallbackToShare =>
      'Saatmine ebaõnnestus — käsitsi jagamine';

  @override
  String get pumpCameraHint => 'Joonda tankla ekraani kolm numbrit raami sisse';

  @override
  String get pumpCameraCapture => 'Pildista';

  @override
  String get pumpCameraPermissionDenied =>
      'Tankla ekraani skannimiseks on vaja kaamera juurdepääsu. Lubage see seadme seadetes.';

  @override
  String get pumpCameraError =>
      'Kaamerat ei õnnestunud käivitada. Proovige uuesti või sisestage väärtused käsitsi.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Lülitu horisontaalsele paigutusele';

  @override
  String get pumpCameraOrientationVertical =>
      'Lülitu vertikaalsele paigutusele';

  @override
  String get pumpCameraGlareWarning =>
      'Liiga palju läiget — kallutage veidi, et vältida peegeldusi';

  @override
  String get pumpCameraAlignHint =>
      'Joondage ekraan raami sisse ja seejärel tehke foto';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Mida täitsid';

  @override
  String get fillUpSectionWhatSubtitle => 'Kütus, kogus, hind';

  @override
  String get fillUpSectionWhereTitle => 'Kus olid';

  @override
  String get fillUpSectionWhereSubtitle => 'Jaam, läbisõidumõõdik, märkmed';

  @override
  String get fillUpImportFromLabel => 'Impordi…';

  @override
  String get fillUpImportSheetTitle => 'Impordi tankimise andmed';

  @override
  String get fillUpImportReceiptLabel => 'Kviitung';

  @override
  String get fillUpImportReceiptDescription =>
      'Skaneeri paberist kviitung kaameraga';

  @override
  String get fillUpImportPumpLabel => 'Pumba kuvar';

  @override
  String get fillUpImportPumpDescription => 'Loe Betrag / Preis pumba LCD-lt';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Loe läbisõidumõõdik OBD-II pordilt Bluetooth\'i kaudu';

  @override
  String get fillUpPricePerLiterLabel => 'Hind liitri kohta';

  @override
  String get vehicleHeaderPlateLabel => 'Registreerimisnumber';

  @override
  String get vehicleHeaderUntitled => 'Uus sõiduk';

  @override
  String get vehicleSectionIdentityTitle => 'Identiteet';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nimi ja VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Jõuülekanne';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Kuidas see sõiduk liigub';

  @override
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get calibrationModeLabel => 'Kalibreerimisrežiim';

  @override
  String get calibrationModeRule => 'Reeglipõhine';

  @override
  String get calibrationModeFuzzy => 'Hämar';

  @override
  String get calibrationModeTooltip =>
      'Reeglipõhine määrab iga sõitmisnäidise täpselt ühele olukorrale. Hämar jagab selle kõigi vahel vastavalt sobivusele — sujuvam 60 km/h lähedal või muutuvatel kallakutel, kuid täidab kõik ämrid aeglasemalt.';

  @override
  String get profileGamificationToggleTitle => 'Kuva saavutused ja hinded';

  @override
  String get profileGamificationToggleSubtitle =>
      'Kui väljas, on märgid, hinded ja trofee ikoonid kogu rakenduses peidetud.';

  @override
  String get coachingGpsLiftOff => 'Vabasta gaas';

  @override
  String get coachingGpsAnticipateBrake => 'Ennakoi';

  @override
  String get coachingGpsSmoothAccel => 'Sujuv kiirendus';

  @override
  String get gpsDiagnosticsTitle => 'GPS näidiste diagnostika';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps tühikut',
      one: '1 tühik',
      zero: 'tühikuid pole',
    );
    return '$count näidist · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Mediaanintervall: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Salvestatud salvestamise ajal, et kontrollida GPS sagedust telefoni une ajal.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Largest gap: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Resumed';

  @override
  String get gpsLifecyclePaused => 'Paused';

  @override
  String get gpsLifecycleInactive => 'Inactive';

  @override
  String get gpsMatrixMaturityCold => 'Külm';

  @override
  String get gpsMatrixMaturityWarming => 'Soojeneb';

  @override
  String get gpsMatrixMaturityConverged => 'Koondunud';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS-maatriks veel soojeneb ($count täpsustust seni). Hinnangud on esialgsed.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS-maatriks koondub ($count tankimist). Hinnangud kasutatavad, võivad erineda mõne %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS-maatriks on koondunud ($count tankimist). Hinnangud ~2 % piires tegelikust kulust.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Sõitmine';

  @override
  String get hapticEcoCoachSettingTitle => 'Reaalajas ökonõustamine';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Õrn haptika + ekraanivihje, kui lähed täisgaasiga kriisi ajal';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Kerge gaasiga — libisemine säästab rohkem';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigeeri sihtkohta $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Eemalda $name lemmikutest';
  }

  @override
  String get showOnMapSemanticLabel => 'Näita jaamu kaardil';

  @override
  String get searchResultsSemanticLabel => 'Otsingutulemused';

  @override
  String get searchCriteriaSemanticLabel =>
      'Otsingukriteeriumide kokkuvõte. Puudutage muutmiseks.';

  @override
  String get noFavoritesSemanticLabel =>
      'Lemmikuid pole veel. Puudutage jaama tärni, et salvestada see lemmikuks.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Jaam on avatud',
      'false': 'Jaam on suletud',
      'other': 'Jaam on suletud',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Riik $name, valitud',
      'false': 'Riik $name',
      'other': 'Riik $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Keel $name, valitud',
      'false': 'Keel $name',
      'other': 'Keel $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sortimine: $option, valitud',
      'false': 'Sortimine: $option',
      'other': 'Sortimine: $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Kütus $type, valitud',
      'false': 'Kütus $type',
      'other': 'Kütus $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Laadimisjaam $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Privaatsuskilp kütusepiisaga';

  @override
  String get globeIllustrationSemantic => 'Maakera tanklatähistega';

  @override
  String get fuelPumpIllustrationSemantic => 'Kütusepump hinnanäidikuga';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, andmeallikas: $provider, $keyRequirement, kütuseliigid: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Vajalik on API võti';

  @override
  String get countryInfoNoKeyNeeded => 'Tasuta, võtit pole vaja';

  @override
  String countryInfoDataSource(String provider) {
    return 'Andmed: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Kütuseliigid: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anon võti';

  @override
  String get anonKeyHideTooltip => 'Peida võti';

  @override
  String get anonKeyShowTooltip => 'Kuva võti kontrollimiseks';

  @override
  String anonKeyTooLong(int length) {
    return 'Võti on liiga pikk ($length tähemärki) — kontrolli lisateksti';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Võti näib õige ($length tähemärki)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Võti peaks olema JWT (päis.kasulik koormus.allkiri)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Võti võib olla kärpitud ($length / ~208 oodatavast tähemärgist)';
  }

  @override
  String get anonKeyExceedsMax => 'Võti ületab maksimaalse pikkuse';

  @override
  String get qrShareTitle => 'Jaga oma andmebaasi';

  @override
  String get qrShareSubtitle =>
      'Teised saavad skannida seda QR-koodi ühendumiseks';

  @override
  String get qrShareCopyAsText => 'Kopeeri tekstina';

  @override
  String get authInfoTitle => 'Miks luua konto?';

  @override
  String get authInfoBenefit1 =>
      '• Sünkrooni lemmikud, teatised ja salvestatud marsruudid seadmete vahel';

  @override
  String get authInfoBenefit2 =>
      '• Valmista marsruut ette telefonil, kasuta seda autos';

  @override
  String get authInfoBenefit3 => '• Andmeid ei jagata kolmandate osapooltega';

  @override
  String get authInfoBenefit4 => '• Saad konto igal ajal kustutada';

  @override
  String get privacyLocalDataEmpty =>
      'Midagi pole veel salvestatud. Lisa lemmik või sea hinnahoiatus, et näha kirjeid siin.';

  @override
  String get privacyHideEmptyRows => 'Peida tühjad read';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kuva $count tühja rida',
      one: 'Kuva $count tühi rida',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-võtme seadistus (vabatahtlik)';

  @override
  String get apiKeySetupDescription =>
      'Registreeru tasuta API-võtme saamiseks või jäta vahele, et uurida rakendust demoandmetega.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider registreerimine';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'API-võtme sisestamisega nõustud $provider tingimustega. Andmete edasijagamine on keelatud.';
  }

  @override
  String get calculatorDistanceHint => 'nt 150';

  @override
  String get calculatorConsumptionHint => 'nt 7,0';

  @override
  String get calculatorPriceHint => 'nt 1,899';

  @override
  String get routeStrategyLabel => 'Strateegia:';

  @override
  String get routeStrategyUniform => 'Ühtlane';

  @override
  String get routeStrategyBalanced => 'Tasakaalustatud';

  @override
  String get glideCoachBetaTitle =>
      'Libisemise juhendaja beeta (eksperimentaalne)';

  @override
  String get glideCoachBetaSubtitle =>
      'Õrn haptika punase tule ees aeglustudes. Vaikimisi väljas — tähelepanu häirimise oht.';

  @override
  String get consentSyncTripsTitle => 'Sünkrooni reisi salvestisi';

  @override
  String get consentSyncTripsSubtitle =>
      'Varunda OBD2 + GPS reisid TankSync\'i. Seadmeteülene, vabatahtlik.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Luba ülal Pilvsünkroonimine reiside varundamiseks.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Logige sisse e-posti kontoga, et sõite seadmete vahel sünkroonida.';

  @override
  String get consentHideDetails => 'Peida üksikasjad';

  @override
  String get consentShowDetails => 'Kuva üksikasjad';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Kehtetu link';

  @override
  String invalidLinkBody(String path) {
    return 'Link \"$path\" ei kehti.';
  }

  @override
  String get home => 'Avaleht';

  @override
  String get locationConsentTitle => 'Asukoha juurdepääs';

  @override
  String get locationConsentSubtitle =>
      'See rakendus soovib kasutada teie asukohta, et leida läheduses asuvaid tanklaid.';

  @override
  String get locationConsentWhatHappens => 'Mis juhtub teie asukohaandmetega:';

  @override
  String get locationConsentBulletApi =>
      'Teie koordinaadid saadetakse kütusehindade API-le, et leida lähedalasuvad tanklad.';

  @override
  String get locationConsentBulletNoServer =>
      'Teie asukohta ei salvestata ühessegi serverisse — serverit ei ole.';

  @override
  String get locationConsentBulletNoTracking =>
      'Asukohaandmeid ei kasutata reklaami, analüütika ega jälgimise jaoks.';

  @override
  String get locationConsentRevoke =>
      'Saate asukoha juurdepääsu igal ajal süsteemiseadetes tühistada. Teise võimalusena otsige sihtnumbri järgi.';

  @override
  String get locationConsentLegalBasis =>
      'Õiguslik alus: isikuandmete kaitse üldmääruse art 6 lg 1 p a (nõusolek)';

  @override
  String get locationConsentDecline => 'Keeldu';

  @override
  String get locationConsentAccept => 'Nõustu';

  @override
  String get loyaltySettingsTitle => 'Kütuseklubi kaardid';

  @override
  String get loyaltySettingsSubtitle =>
      'Rakenda oma lojaalsusskonto kuvatavate hindadele';

  @override
  String get loyaltyMenuTitle => 'Kütuseklubi kaardid';

  @override
  String get loyaltyMenuSubtitle =>
      'Rakenda liitri soodustused Total, Aral, Shell, … jaamadele';

  @override
  String get loyaltyAddCard => 'Lisa kaart';

  @override
  String get loyaltyAddCardSheetTitle => 'Lisa kütuseklubi kaart';

  @override
  String get loyaltyBrandLabel => 'Bränd';

  @override
  String get loyaltyCardLabelLabel => 'Silt (vabatahtlik)';

  @override
  String get loyaltyDiscountLabel => 'Soodustus (liitri kohta)';

  @override
  String get loyaltyDiscountInvalid => 'Sisesta positiivne number';

  @override
  String get loyaltyDeleteConfirmTitle => 'Kustuta kaart?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'See kaart lõpetab soodustuse rakendamise.';

  @override
  String get loyaltyEmptyTitle => 'Kütuseklubi kaarte pole veel';

  @override
  String get loyaltyEmptyBody =>
      'Lisa kaart, et rakenda liitri soodustus sobivates jaamades automaatselt.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Tühikäigu RPM kõikumist tuvastatud';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Tühikäigu RPM on tõusnud $percent% sinu viimase $tripCount reisi jooksul. Võimalik varajane märk ummistunud õhufiltrist või sensori triivimisest.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Võimalik imemispiiramine';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Sõidukiirus kütusekulu on langenud $percent% sinu viimase $tripCount reisi jooksul. Võimalik märk ummistunud õhufiltrist või piiratud imemisest — tasub üle vaadata.';
  }

  @override
  String get maintenanceActionDismiss => 'Sulge';

  @override
  String get maintenanceActionSnooze => 'Lükka 30 päevaks edasi';

  @override
  String get consumptionMonthlyInsightsTitle => 'See kuu vs eelmine kuu';

  @override
  String get consumptionMonthlyTripsLabel => 'Reisid';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Sõiduaeg';

  @override
  String get consumptionMonthlyDistanceLabel => 'Vahemaa';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Kesk. tarbimine';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Võrdluseks on vaja vähemalt 3 reisi kuus';

  @override
  String get consumptionMonthlyClimbLabel => 'Climbed';

  @override
  String get obd2CapabilitySectionTitle => 'Adapteri võimalused';

  @override
  String get obd2CapabilityStandardOnly => 'Standardne';

  @override
  String get obd2CapabilityOemPids => 'OEM PID-id';

  @override
  String get obd2CapabilityFullCan => 'Täis CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Peugeot/Citroën täpsete liitrite paagis saamiseks toetab rakendus OBDLink MX+/LX/CX (STN kiip).';

  @override
  String get obd2DebugOverlayEnabledSnack => 'OBD2 diagnostika ülekat lubatud';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 diagnostika ülekat keelatud';

  @override
  String get obd2DebugOverlayClearButton => 'Tühjenda';

  @override
  String get obd2DebugOverlayCloseButton => 'Sulge';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 leivaraasud';

  @override
  String get obd2DiagnosticShareLabel => 'Jaga diagnostikalogi';

  @override
  String get obd2DebugLoggingTitle => 'OBD2 silumislogi';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Salvestage iga OBD2 seanss — ühendus, käepigistus, andmelüngad ja taasühendused — eksporditavasse XML-logisse. Vaikimisi välja lülitatud.';

  @override
  String get obd2DebugSessionShareLabel => 'Jaga OBD2 seansilogi';

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
  String get obd2TestRunTitle => 'Run adapter test';

  @override
  String get obd2TestRunButton => 'Run adapter test';

  @override
  String get obd2TestRunPassed => 'Adapter test passed';

  @override
  String get obd2TestRunFailed => 'Adapter test failed';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed of $total steps OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Stop the active recording before running the adapter test.';

  @override
  String get obd2TestStepScan => 'Scan for adapter';

  @override
  String get obd2TestStepConnect => 'Connect & init';

  @override
  String get obd2TestStepInfo => 'Adapter info';

  @override
  String get obd2TestStepSupportedPids => 'Supported PIDs';

  @override
  String get obd2TestStepSampleReads => 'Sample reads';

  @override
  String get obd2TestStepReconnect => 'Reconnect test';

  @override
  String get obd2TestStepDisconnect => 'Disconnect';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Timed out';

  @override
  String get obd2TestStatusGarbage => 'Unreadable reply';

  @override
  String get obd2TestStatusNoResponse => 'No response';

  @override
  String get obd2TestStatusFail => 'Failed';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Ei suutnud jõuda \'$adapterName\' — vali teine adapter';
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
  String get onboardingObd2StepTitle => 'Ühenda oma OBD2 adapter';

  @override
  String get onboardingObd2StepBody =>
      'Ühenda oma OBD2 adapter auto porti ja lülita süütevool sisse. Loeme VIN-koodi ja täidame mootori andmed sinu eest.';

  @override
  String get onboardingObd2ConnectButton => 'Ühenda adapter';

  @override
  String get onboardingObd2SkipButton => 'Ehk hiljem';

  @override
  String get onboardingObd2ReadingVin => 'Loen VIN-koodi…';

  @override
  String get onboardingObd2VinReadFailed =>
      'VIN-koodi ei saanud lugeda — sisesta käsitsi';

  @override
  String get onboardingObd2ConnectFailed =>
      'Ei suutnud adapteriga ühendada. Saad uuesti proovida või vahele jätta.';

  @override
  String get onboardingPickUseMode => 'Jätkamiseks vali kasutusrežiim.';

  @override
  String get openNow => 'Open';

  @override
  String get openNowClosed => 'Closed';

  @override
  String get openHoursUnknown => 'Hours unknown';

  @override
  String closesAt(String time) {
    return 'Closes $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Opens $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Opens $time';
  }

  @override
  String get open24Hours => 'Open 24 hours';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => '24/7 automate';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Public holidays';

  @override
  String get closedLabel => 'Closed';

  @override
  String get openingHoursNotAvailable => 'Opening hours not available';

  @override
  String get showAllHours => 'Show all hours';

  @override
  String get showLessHours => 'Show less';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'möödunud';

  @override
  String get alertsRadiusFrequencyLabel => 'Kontrollimissagedus';

  @override
  String get alertsRadiusFrequencyDaily => 'Kord päevas';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Kaks korda päevas';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Kolm korda päevas';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Neli korda päevas';

  @override
  String get radiusAlertPickOnMap => 'Vali kaardilt';

  @override
  String get radiusAlertMapPickerTitle => 'Vali teatise kese';

  @override
  String get radiusAlertMapPickerConfirm => 'Kinnita';

  @override
  String get radiusAlertMapPickerCancel => 'Tühista';

  @override
  String get radiusAlertMapPickerHint =>
      'Lohista kaarti teatise kese paigutamiseks';

  @override
  String get radiusAlertCenterFromMap => 'Kaardi asukoht';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel lähedal $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Jaam on $price € (eesmärk: $threshold €)';
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
  String get refuelUnitPerSession => '/sessioon';

  @override
  String get shareReceiptImporting => 'Importing shared receipt…';

  @override
  String get shareReceiptUnsupportedFormat =>
      'That file type can\'t be imported yet — share a photo of the receipt instead.';

  @override
  String get shareReceiptFailed =>
      'Couldn\'t read the shared receipt — try sharing it again or add the fill-up manually.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Share receipt to import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Share a receipt photo from another app to pre-fill a fill-up — date, litres, total, and station are read on-device.';

  @override
  String get speedConsumptionCardTitle => 'Tarbimine kiiruse järgi';

  @override
  String get speedBandIdleJam => 'Tühikäik / ummik';

  @override
  String get speedBandUrban => 'Linnas (10–50)';

  @override
  String get speedBandSuburban => 'Äärelinnas (50–80)';

  @override
  String get speedBandRural => 'Maapiirkonnas (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Öko-kruiis (100–115)';

  @override
  String get speedBandMotorway => 'Maanteel (115–130)';

  @override
  String get speedBandMotorwayFast => 'Maanteel kiire (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Salvesta 30+ minutit reise OBD2 adapteriga, et avada kiiruse/tarbimise analüüs.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % sõitmisest';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Andmeid on vaja rohkem';

  @override
  String get splashLoadingLabel => 'Laen Sparkilo';

  @override
  String get storageRecoveryTitle => 'Salvestusprobleem';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo ei suutnud avada oma kohalikku andmehoidlat. Salvestusfail näib olevat kahjustatud.';

  @override
  String get storageRecoveryGuidance =>
      'Taastamiseks tühjenda rakenduse salvestusruum seadme seadetes või installi rakendus uuesti. Sinu lemmikud ja ajalugu salvestatakse ainult selles seadmes, mistõttu neid ei saa automaatselt taastada.';

  @override
  String get tankLevelTitle => 'Paagi tase';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km läbisõiduvaru';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Viimane tankimine: $date · $count reis(i) sellest saadik';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2 mõõdetud';

  @override
  String get tankLevelMethodDistanceFallback => 'vahemaapõhine hinnang';

  @override
  String get tankLevelMethodMixed => 'segamõõtmine';

  @override
  String get tankLevelEmptyNoFillUp => 'Lisa tankimine paagi taseme nägemiseks';

  @override
  String get tankLevelDetailSheetTitle => 'Reisid alates viimasest tankimisest';

  @override
  String get addFillUpIsFullTankLabel => 'Täistank';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Paak täidetud äärmiseni — tühjenda, kui see oli osaline tankimine';

  @override
  String get themeCardTitle => 'Teema';

  @override
  String get themeCardSubtitleSystem => 'Süsteem';

  @override
  String get themeCardSubtitleLight => 'Hele';

  @override
  String get themeCardSubtitleDark => 'Tume';

  @override
  String get themeSettingsScreenTitle => 'Teema';

  @override
  String get themeSettingsSystemLabel => 'Järgi süsteemi';

  @override
  String get themeSettingsLightLabel => 'Hele';

  @override
  String get themeSettingsDarkLabel => 'Tume';

  @override
  String get themeSettingsSystemDescription =>
      'Sobita seadme praeguse välimusega.';

  @override
  String get themeSettingsLightDescription =>
      'Heledad tastad — parim päevakasutuseks.';

  @override
  String get themeSettingsDarkDescription =>
      'Tumedad tastad — õhtul silmadele kergem ja säästab akut OLED-ekraanidel.';

  @override
  String get themeSettingsEcoLabel => 'Öko';

  @override
  String get themeSettingsEcoDescription =>
      'Rakenduse omapärane roheline välimus — hele ja hästi loetav, pehme rohelise tooniga taustaga.';

  @override
  String get throttleRpmHistogramTitle => 'Kuidas mootorit kasutasid';

  @override
  String get throttleRpmHistogramThrottleSection => 'Gaasipedaali asend';

  @override
  String get throttleRpmHistogramRpmSection => 'Mootori RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Libisemine (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Kerge (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Tugev (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Täisgaas (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Tühikäik (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Kruiis (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Elav (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Kõrge (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Sellel reisil pole gaasipedaali ega RPM näidiseid.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Reisid';

  @override
  String get trajetsStartRecordingButton => 'Alusta salvestamist';

  @override
  String get trajetsResumeRecordingButton => 'Jätka salvestamist';

  @override
  String get tripStartProgressConnectingAdapter => 'Ühendan OBD2 adapteriga…';

  @override
  String get tripStartProgressReadingVehicleData => 'Loen sõiduki andmeid…';

  @override
  String get tripStartProgressStartingRecording => 'Alustan salvestamist…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

  @override
  String get trajetsEmptyStateTitle => 'Reise pole veel';

  @override
  String get trajetsEmptyStateBody =>
      'Puuduta Alusta salvestamist, et hakata oma sõite logima.';

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
  String get trajetDetailSummaryTitle => 'Kokkuvõte';

  @override
  String get trajetDetailFieldDate => 'Kuupäev';

  @override
  String get trajetDetailFieldVehicle => 'Sõiduk';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 adapter';

  @override
  String get trajetDetailFieldDistance => 'Vahemaa';

  @override
  String get trajetDetailFieldDuration => 'Kestus';

  @override
  String get trajetDetailFieldAvgConsumption => 'Kesk. tarbimine';

  @override
  String get trajetDetailFieldFuelUsed => 'Kasutatud kütus';

  @override
  String get trajetDetailFieldFuelCost => 'Kütusekulu';

  @override
  String get trajetDetailFieldAvgSpeed => 'Kesk. kiirus';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maksimaalne kiirus';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Kiirus (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Kütusemäär (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Mootori koormus (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Graafikud';

  @override
  String get trajetsRowColdStartChip => 'Külmkäivitus';

  @override
  String get trajetsRowColdStartTooltip =>
      'Mootor ei jõudnud selle reisi jooksul töötemperatuurini — kütusekulu oli tavalisest kõrgem.';

  @override
  String get trajetDetailChartEmpty => 'Näidiseid pole salvestatud';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Jaga';

  @override
  String get trajetDetailShareImageOption => 'Jaga pilti';

  @override
  String get trajetDetailShareGpxOption => 'Jaga GPS-rada (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Pole GPS-andmeid sellel sõidul';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — reis $date';
  }

  @override
  String get trajetDetailShareError => 'Jagatava pildi loomine ebaõnnestus';

  @override
  String get trajetDetailDownloadCsvOption => 'Download telemetry (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetry (JSON)';

  @override
  String get trajetDetailDownloadError => 'Couldn\'t save the file';

  @override
  String get trajetDetailDeleteAction => 'Kustuta';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Kustutada see reis?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'See reis eemaldatakse jäädavalt sinu ajaloost.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Tühista';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Kustuta';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 adapter ühendatud, kuid ei tagasta andmeid. Proovi teist adapterit või kontrolli sõiduki diagnostikaprotokolli.';

  @override
  String get trajetsViewAllOnMap => 'Näita kõik kaardil';

  @override
  String get trajetsMapTitle => 'Sõidud kaardil';

  @override
  String get trajetsMapShareGpx => 'Jaga GPX';

  @override
  String get trajetsMapEmpty => 'Üheski valitud sõidus pole GPS-andmeid.';

  @override
  String get trajetsMapShareError => 'GPX-faili ei õnnestunud jagada';

  @override
  String get tripLengthCardTitle => 'Tarbimine reisi pikkuse järgi';

  @override
  String get tripLengthBucketShort => 'Lühike (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Keskmine (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Pikk (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Andmeid on vaja rohkem';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reisi',
      one: '1 reis',
      zero: 'reise pole',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Reisi marsruut';

  @override
  String get tripPathCardSubtitle => 'GPS-salvestatud marsruut';

  @override
  String get tripPathLegendTitle => 'Tarbimine';

  @override
  String get tripPathLegendEfficient => 'Efektiivne (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Piiripeal (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Raiskav (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get fuelStationRadarNearer => 'Nearer station';

  @override
  String get fuelStationRadarFarther => 'Farther station';

  @override
  String get fuelStationRadarStart => 'Start fuel station radar';

  @override
  String get stopRadar => 'Stop radar';

  @override
  String get fuelStationRadarResultBadge => 'Fuel Station Radar result';

  @override
  String get tripRecordingPinTooltip =>
      'Kinnitamine hoiab ekraani peal — kasutab rohkem akut';

  @override
  String get tripRecordingPinSemanticOn => 'Eemalda salvestusvormi kinnitus';

  @override
  String get tripRecordingPinSemanticOff => 'Kinnita salvestusvorm';

  @override
  String get tripRecordingPinHelpTooltip => 'Mida kinnitus teeb?';

  @override
  String get tripRecordingPinHelpTitle => 'Kinnituse kohta';

  @override
  String get tripRecordingPinHelpBody =>
      'Kinnitus hoiab ekraani peal ja peidab süsteemiribad, et vorm jääks armatuurlauale kinnituna loetavaks. Puuduta uuesti vabastamiseks. Vabastub automaatselt, kui reis peatub.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Salvestamine jätkub taustal. Puuduta punast ribareklaam ekraani ülaosas, et naasta.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Ava aktiivne reis Kulu kaardilt';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Kinnita ekraan, et GPS oleks aktiivne reisi ajal — Android võib GPS-i une ajal piirata.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimeeri hõljuvaks paaniks';

  @override
  String get tripRecordingAutoPinTitle =>
      'Salvestuse alustamisel alati kinnita';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Kinnita vorm igal sõidul automaatselt, selle asemel et iga kord puudutada. Kasutab rohkem akut.';

  @override
  String get tripRecordingConnectingTitle => 'Salvestuse alustamine…';

  @override
  String get tripRecordingSavingTitle => 'Saving trip…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripRecordingGpsNotificationTitle => 'Recording your trip';

  @override
  String get tripRecordingGpsNotificationText =>
      'Tracking your route for fuel & driving stats';

  @override
  String get tripShareAction => 'Jaga teise kontoga';

  @override
  String get tripShareSheetTitle => 'Jaga seda sõitu';

  @override
  String get tripShareSheetSubtitle =>
      'Anna teisele TankSynci kontole sellele salvestatud sõidule kirjutuskaitstud juurdepääs.';

  @override
  String get tripShareEmailLabel => 'Saaja e-post';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Jaga';

  @override
  String get tripShareCreateLinkButton => 'Loo jagamislink';

  @override
  String get tripShareLinkCreated =>
      'Jagamislink kopeeritud — kleebi see saajale.';

  @override
  String get tripShareSuccess => 'Sõit jagatud.';

  @override
  String get tripShareRecipientNotFound =>
      'Ükski TankSynci konto ei kasuta seda e-posti.';

  @override
  String get tripShareError => 'Sõitu ei õnnestunud jagada. Proovi uuesti.';

  @override
  String get tripShareExistingTitle => 'Jagatud kasutajaga';

  @override
  String get tripShareExistingEmpty => 'Pole veel kellegagi jagatud.';

  @override
  String get tripShareDirectRecipient => 'Konto';

  @override
  String get tripShareLinkRecipient => 'Jagamislink (lunastamata)';

  @override
  String get tripShareRevokeTooltip => 'Tühista';

  @override
  String get tripShareRevoked => 'Jagamine tühistatud.';

  @override
  String get trajetsSharedSectionTitle => 'Minuga jagatud';

  @override
  String get trajetsSharedBadge => 'Jagatud';

  @override
  String get unifiedFilterFuel => 'Kütus';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Mõlemad';

  @override
  String get unifiedNoResultsForFilter => 'Selle filtri jaoks pole tulemusi';

  @override
  String get searchFailedSnackbar => 'Otsing ebaõnnestus — palun proovi uuesti';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Updated $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Also: $names';
  }

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Raw: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get vinLabel => 'VIN (vabatahtlik)';

  @override
  String get vinDecodeTooltip => 'Dekodeeri VIN';

  @override
  String get vinConfirmAction => 'Jah, täida automaatselt';

  @override
  String get vinModifyAction => 'Muuda käsitsi';

  @override
  String get veResetAction => 'Lähtesta mahuline efektiivsus';

  @override
  String get vehicleReadVinFromCarButton => 'Loe VIN autost';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Loe VIN ühendatud OBD2 adapterist';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN pole saadaval (Režiim 09 PID 02 ei toetata enne 2005. aastat valmistatud sõidukitel)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN lugemine ebaõnnestus — palun sisesta käsitsi';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Ühenda esmalt OBD2 adapter VIN automaatseks lugemiseks';

  @override
  String get pickerButtonLabel => 'Vali kataloogist';

  @override
  String get pickerSearchHint => 'Otsi marki või mudelit';

  @override
  String get pickerHelpText => 'Eeltäida 50+ toetatud sõiduki hulgast';

  @override
  String get pickerEmptyResults => 'Tulemusi pole';

  @override
  String get pickerCancel => 'Tühista';

  @override
  String get pickerLoading => 'Laen kataloogi…';

  @override
  String get vinInfoTooltip => 'Mis on VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Mis on VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Sõiduki identifitseerimisnumber on 17-kohaline kood, mis on sinu auto jaoks unikaalne. See on stantsitud šassiile ja trükitud sinu sõiduki registreerimisdokumendile.';

  @override
  String get vinInfoSectionWhyTitle => 'Miks me küsime';

  @override
  String get vinInfoSectionWhyBody =>
      'VIN-koodi dekodeerimine täidab automaatselt mootori töömaht, silindrite arv, mudeli aasta, peamine kütuse liik ja kogumass — säästes sind tehniliste andmete käsitsi otsimisest. OBD2 kütusemäära arvutus kasutab neid väärtusi täpsete kulunäitajate andmiseks.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privaatsus';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Sinu VIN on salvestatud ainult lokaalselt rakenduse krüpteeritud salvestusruumis — seda ei laadita kunagi Sparkilo serveritesse. NHTSA vPIC andmebaasi päritakse VIN-koodiga, kuid see tagastab ainult anonüümsed tehnilised andmed; NHTSA ei seo VIN-i isikuandmetega. Ilma võrguühenduseta tagastab otsing ainult tootja ja riigi.';

  @override
  String get vinInfoSectionWhereTitle => 'Kust leida';

  @override
  String get vinInfoSectionWhereBody =>
      'Vaata esiklaasi kaudu vasakul allnurgas juhi poolel, kontrolli juhi poolel ukse raami kleebist ukse avamisel või loe see sinu sõiduki registreerimisdokumendilt (kaart / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Selge';

  @override
  String get vinConfirmPrivacyNote =>
      'Otsisime sinu VIN-koodi NHTSA tasuta sõidukiandmebaasist — Sparkilo serveritesse midagi ei saadetud.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN veebidekodeerimine';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekodeeri VIN NHTSA tasuta avaliku teenuse kaudu';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Kui ühendate adapteri, loetakse sinu sõiduki VIN lokaalselt auto tuvastamiseks. Selle lubamine saadab 17-kohalise VIN-i NHTSA tasuta vPIC teenusesse täiendavate andmete (mudel, mootori töömaht, kütuse liik) otsimiseks. VIN on ainus saadetav andmestik — muud teave ei lahku sinu seadmest.';

  @override
  String get vehicleDetectedFromVinBadge => '(tuvastatud)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Tuvastatud VIN-koodist: $summary. Rakenda?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Rakenda';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometers ahead, $fuelType $euros euros $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Avaekraani vidin';

  @override
  String get widgetHelpIntro =>
      'Lisa SparKilo vidin oma avaekraanile, et näha kütuse ja laadimishindu kiiresti.';

  @override
  String get widgetHelpAdd =>
      'Lisa see oma käivitaja vidinate valijast — hoia pikalt all avaekraani tühja ala, vali Vidinad ja leia SparKilo.';

  @override
  String get widgetHelpTap =>
      'Puuduta vidinat jaama avamiseks rakenduses. Puuduta värskendamise ikooni hindade uuendamiseks.';

  @override
  String get widgetHelpConfigure =>
      'Androidis hoia vidinat pikalt all ja vali Konfigureeri uuesti, et muuta profiili, värvi ja sisu.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Valikud allpool kehtivad kõikidele paigaldatud vidinatele järgmisel värskendamisel.';

  @override
  String get widgetDefaultsColorLabel => 'Värviskeem';

  @override
  String get widgetDefaultsVariantLabel => 'Sisuvariant';

  @override
  String get widgetColorSchemeSystem => 'Süsteem';

  @override
  String get widgetColorSchemeLight => 'Hele';

  @override
  String get widgetColorSchemeDark => 'Tume';

  @override
  String get widgetColorSchemeBlue => 'Sinine';

  @override
  String get widgetColorSchemeGreen => 'Roheline';

  @override
  String get widgetColorSchemeOrange => 'Oranž';

  @override
  String get widgetVariantDefault => 'Ainult praegune hind';

  @override
  String get widgetVariantPredictive => 'Ennustav: parim tankimisaeg';

  @override
  String get widgetPredictiveNowPrefix => 'praegu';
}
