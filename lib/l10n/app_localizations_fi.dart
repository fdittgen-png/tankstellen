// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'Polttoainehinnat';

  @override
  String get search => 'Haku';

  @override
  String get favorites => 'Suosikit';

  @override
  String get map => 'Kartta';

  @override
  String get profile => 'Profiili';

  @override
  String get settings => 'Asetukset';

  @override
  String get gpsLocation => 'GPS-sijainti';

  @override
  String get zipCode => 'Postinumero';

  @override
  String get zipCodeHint => 'esim. 00100';

  @override
  String get fuelType => 'Polttoaine';

  @override
  String get searchRadius => 'Säde';

  @override
  String get searchNearby => 'Lähellä olevat asemat';

  @override
  String get searchButton => 'Hae';

  @override
  String get noResults => 'Asemia ei löytynyt.';

  @override
  String get startSearch => 'Hae löytääksesi huoltoasemia.';

  @override
  String get open => 'Auki';

  @override
  String get closed => 'Suljettu';

  @override
  String distance(String distance) {
    return '$distance päässä';
  }

  @override
  String get price => 'Hinta';

  @override
  String get prices => 'Hinnat';

  @override
  String get address => 'Osoite';

  @override
  String get openingHours => 'Aukioloajat';

  @override
  String get open24h => 'Auki 24 tuntia';

  @override
  String get navigate => 'Navigoi';

  @override
  String get retry => 'Yritä uudelleen';

  @override
  String get apiKeySetup => 'API-avain';

  @override
  String get apiKeyDescription =>
      'Rekisteröidy kerran saadaksesi ilmaisen API-avaimen.';

  @override
  String get apiKeyLabel => 'API-avain';

  @override
  String get register => 'Rekisteröinti';

  @override
  String get continueButton => 'Jatka';

  @override
  String get welcome => 'Polttoainehinnat';

  @override
  String get welcomeSubtitle => 'Löydä edullisin polttoaine läheltäsi.';

  @override
  String get profileName => 'Profiilin nimi';

  @override
  String get preferredFuel => 'Ensisijainen polttoaine';

  @override
  String get defaultRadius => 'Oletussäde';

  @override
  String get landingScreen => 'Aloitusnäyttö';

  @override
  String get homeZip => 'Kotiosoitteen postinumero';

  @override
  String get newProfile => 'Uusi profiili';

  @override
  String get editProfile => 'Muokkaa profiilia';

  @override
  String get save => 'Tallenna';

  @override
  String get cancel => 'Peruuta';

  @override
  String get delete => 'Poista';

  @override
  String get activate => 'Aktivoi';

  @override
  String get configured => 'Määritetty';

  @override
  String get notConfigured => 'Ei määritetty';

  @override
  String get about => 'Tietoja';

  @override
  String get openSource => 'Avoin lähdekoodi (MIT-lisenssi)';

  @override
  String get sourceCode => 'Lähdekoodi GitHubissa';

  @override
  String get noFavorites => 'Ei suosikkeja vielä';

  @override
  String get noFavoritesHint =>
      'Napauta aseman tähteä tallentaaksesi sen suosikiksi.';

  @override
  String get language => 'Kieli';

  @override
  String get country => 'Maa';

  @override
  String get demoMode => 'Demotila — esimerkkitiedot näytetään.';

  @override
  String get setupLiveData => 'Määritä live-dataa varten';

  @override
  String get freeNoKey => 'Ilmainen — avainta ei tarvita';

  @override
  String get apiKeyRequired => 'API-avain vaaditaan';

  @override
  String get skipWithoutKey => 'Jatka ilman avainta';

  @override
  String get dataTransparency => 'Tietojen läpinäkyvyys';

  @override
  String get storageAndCache => 'Tallennus ja välimuisti';

  @override
  String get clearCache => 'Tyhjennä välimuisti';

  @override
  String get clearAllData => 'Poista kaikki tiedot';

  @override
  String get errorLog => 'Virheloki';

  @override
  String stationsFound(int count) {
    return '$count asemaa löytyi';
  }

  @override
  String get whatIsShared => 'Mitä jaetaan — ja kenen kanssa?';

  @override
  String get gpsCoordinates => 'GPS-koordinaatit';

  @override
  String get gpsReason =>
      'Lähetetään jokaisessa haussa lähellä olevien asemien löytämiseksi.';

  @override
  String get postalCodeData => 'Postinumero';

  @override
  String get postalReason =>
      'Muunnetaan koordinaateiksi geokoodauspalvelun kautta.';

  @override
  String get mapViewport => 'Karttanäkymä';

  @override
  String get mapReason =>
      'Karttaruudut ladataan palvelimelta. Henkilötietoja ei lähetetä.';

  @override
  String get apiKeyData => 'API-avain';

  @override
  String get apiKeyReason =>
      'Henkilökohtainen avaimesi lähetetään jokaisen API-pyynnön mukana. Se on yhdistetty sähköpostiisi.';

  @override
  String get notShared => 'EI jaeta:';

  @override
  String get searchHistory => 'Hakuhistoria';

  @override
  String get favoritesData => 'Suosikit';

  @override
  String get profileNames => 'Profiilinimet';

  @override
  String get homeZipData => 'Kotiosoitteen postinumero';

  @override
  String get usageData => 'Käyttötiedot';

  @override
  String get privacyBanner =>
      'Tällä sovelluksella ei ole palvelinta. Kaikki tiedot pysyvät laitteellasi. Ei analytiikkaa, ei seurantaa, ei mainoksia.';

  @override
  String get storageUsage => 'Tallennustilan käyttö tällä laitteella';

  @override
  String get settingsLabel => 'Asetukset';

  @override
  String get profilesStored => 'profiilia tallennettu';

  @override
  String get stationsMarked => 'asemaa merkitty';

  @override
  String get cachedResponses => 'välimuistissa olevaa vastausta';

  @override
  String get total => 'Yhteensä';

  @override
  String get cacheManagement => 'Välimuistin hallinta';

  @override
  String get cacheDescription =>
      'Välimuisti tallentaa API-vastaukset nopeampaa latausta ja offline-käyttöä varten.';

  @override
  String get stationSearch => 'Asemahaku';

  @override
  String get stationDetails => 'Aseman tiedot';

  @override
  String get priceQuery => 'Hintakysely';

  @override
  String get zipGeocoding => 'Postinumeron geokoodaus';

  @override
  String minutes(int n) {
    return '$n minuuttia';
  }

  @override
  String hours(int n) {
    return '$n tuntia';
  }

  @override
  String get clearCacheTitle => 'Tyhjennä välimuisti?';

  @override
  String get clearCacheBody =>
      'Välimuistissa olevat hakutulokset ja hinnat poistetaan. Profiilit, suosikit ja asetukset säilytetään.';

  @override
  String get clearCacheButton => 'Tyhjennä välimuisti';

  @override
  String get deleteAllTitle => 'Poista kaikki tiedot?';

  @override
  String get deleteAllBody =>
      'Tämä poistaa pysyvästi kaikki profiilit, suosikit, API-avaimen, asetukset ja välimuistin. Sovellus palautetaan.';

  @override
  String get deleteAllButton => 'Poista kaikki';

  @override
  String get entries => 'merkintää';

  @override
  String get cacheEmpty => 'Välimuisti on tyhjä';

  @override
  String get noStorage => 'Ei tallennustilaa käytössä';

  @override
  String get apiKeyNote =>
      'Ilmainen rekisteröinti. Tiedot valtion hintatransparenssitoimistoilta.';

  @override
  String get apiKeyFormatError =>
      'Virheellinen muoto — odotettu UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Tue tätä projektia';

  @override
  String get supportDescription =>
      'Tämä sovellus on ilmainen, avoimen lähdekoodin ja mainokseton. Jos se on hyödyllinen, harkitse kehittäjän tukemista.';

  @override
  String get reportBug => 'Ilmoita virheestä / Ehdota ominaisuutta';

  @override
  String get privacyPolicy => 'Tietosuojakäytäntö';

  @override
  String get fuels => 'Polttoaineet';

  @override
  String get services => 'Palvelut';

  @override
  String get zone => 'Alue';

  @override
  String get highway => 'Moottoritie';

  @override
  String get localStation => 'Paikallinen asema';

  @override
  String get lastUpdate => 'Viimeisin päivitys';

  @override
  String get automate24h => '24t/24 — Automaatti';

  @override
  String get refreshPrices => 'Päivitä hinnat';

  @override
  String get station => 'Huoltoasema';

  @override
  String get locationDenied =>
      'Sijaintilupa evätty. Voit hakea postinumerolla.';

  @override
  String get demoModeBanner => 'Demotila. Määritä API-avain asetuksissa.';

  @override
  String get sortDistance => 'Etäisyys';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'halpa';

  @override
  String get expensive => 'kallis';

  @override
  String stationsOnMap(int count) {
    return '$count asemaa';
  }

  @override
  String get loadingFavorites =>
      'Ladataan suosikkeja...\nHae asemia ensin tietojen tallentamiseksi.';

  @override
  String get reportPrice => 'Ilmoita hinta';

  @override
  String get whatsWrong => 'Mikä on vialla?';

  @override
  String get correctPrice => 'Oikea hinta (esim. 1,459)';

  @override
  String get sendReport => 'Lähetä ilmoitus';

  @override
  String get reportSent => 'Ilmoitus lähetetty. Kiitos!';

  @override
  String get enterValidPrice => 'Syötä kelvollinen hinta';

  @override
  String get cacheCleared => 'Välimuisti tyhjennetty.';

  @override
  String get yourPosition => 'Sijaintisi';

  @override
  String get positionUnknown => 'Sijainti tuntematon';

  @override
  String get distancesFromCenter => 'Etäisyydet hakukeskuksesta';

  @override
  String get autoUpdatePosition => 'Päivitä sijainti automaattisesti';

  @override
  String get autoUpdateDescription =>
      'Päivitä GPS-sijainti ennen jokaista hakua';

  @override
  String get location => 'Sijainti';

  @override
  String get switchProfileTitle => 'Maa vaihtui';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Olet nyt maassa $country. Vaihda profiiliin \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Vaihdettu profiiliin \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Ei profiilia tälle maalle';

  @override
  String noProfileForCountry(String country) {
    return 'Olet maassa $country, mutta profiilia ei ole määritetty. Luo sellainen Asetuksissa.';
  }

  @override
  String get autoSwitchProfile => 'Automaattinen profiilivaihto';

  @override
  String get autoSwitchDescription =>
      'Vaihda profiilia automaattisesti rajan ylittyessä';

  @override
  String get switchProfile => 'Vaihda';

  @override
  String get dismiss => 'Sulje';

  @override
  String get profileCountry => 'Maa';

  @override
  String get profileLanguage => 'Kieli';

  @override
  String get settingsStorageDetail => 'API-avain, aktiivinen profiili';

  @override
  String get allFuels => 'Kaikki';

  @override
  String get priceAlerts => 'Hintahälytykset';

  @override
  String get noPriceAlerts => 'Ei hintahälytyksiä';

  @override
  String get noPriceAlertsHint => 'Luo hälytys aseman tietosivulta.';

  @override
  String alertDeleted(String name) {
    return 'Hälytys \"$name\" poistettu';
  }

  @override
  String get createAlert => 'Luo hintahälytys';

  @override
  String currentPrice(String price) {
    return 'Nykyinen hinta: $price';
  }

  @override
  String get targetPrice => 'Tavoitehinta (EUR)';

  @override
  String get enterPrice => 'Anna hinta';

  @override
  String get invalidPrice => 'Virheellinen hinta';

  @override
  String get priceTooHigh => 'Hinta liian korkea';

  @override
  String get create => 'Luo';

  @override
  String get alertCreated => 'Hintahälytys luotu';

  @override
  String get wrongE5Price => 'Väärä Super E5 hinta';

  @override
  String get wrongE10Price => 'Väärä Super E10 hinta';

  @override
  String get wrongDieselPrice => 'Väärä Diesel hinta';

  @override
  String get wrongStatusOpen => 'Näytetään avoimena, mutta suljettu';

  @override
  String get wrongStatusClosed => 'Näytetään suljettuna, mutta avoinna';

  @override
  String get searchAlongRouteLabel => 'Reitin varrella';

  @override
  String get searchEvStations => 'Etsi latausasemia';

  @override
  String get allStations => 'Kaikki asemat';

  @override
  String get bestStops => 'Parhaat pysähdykset';

  @override
  String get openInMaps => 'Avaa Kartoissa';

  @override
  String get noStationsAlongRoute => 'Ei asemia reitin varrella';

  @override
  String get evOperational => 'Toiminnassa';

  @override
  String get evStatusUnknown => 'Tila tuntematon';

  @override
  String evConnectors(int count) {
    return 'Liittimet ($count pistettä)';
  }

  @override
  String get evNoConnectors => 'Ei liitintietoja saatavilla';

  @override
  String get evUsageCost => 'Käyttökustannus';

  @override
  String get evPricingUnavailable =>
      'Hintatietoa ei saatavilla palveluntarjoajalta';

  @override
  String get evLastUpdated => 'Viimeksi päivitetty';

  @override
  String get evUnknown => 'Tuntematon';

  @override
  String get evDataAttribution => 'Tiedot OpenChargeMapista (yhteisölähde)';

  @override
  String get evStatusDisclaimer =>
      'Tila ei välttämättä vastaa reaaliaikaista saatavuutta. Napauta päivitä saadaksesi uusimmat tiedot.';

  @override
  String get evNavigateToStation => 'Navigoi asemalle';

  @override
  String get evRefreshStatus => 'Päivitä tila';

  @override
  String get evStatusUpdated => 'Tila päivitetty';

  @override
  String get evStationNotFound =>
      'Päivitys epäonnistui — asemaa ei löytynyt läheltä';

  @override
  String get addedToFavorites => 'Lisätty suosikkeihin';

  @override
  String get removedFromFavorites => 'Poistettu suosikeista';

  @override
  String get addFavorite => 'Lisää suosikkeihin';

  @override
  String get removeFavorite => 'Poista suosikeista';

  @override
  String get currentLocation => 'Nykyinen sijainti';

  @override
  String get gpsError => 'GPS-virhe';

  @override
  String get couldNotResolve =>
      'Lähtöpaikkaa tai määränpäätä ei voitu selvittää';

  @override
  String get start => 'Lähtö';

  @override
  String get destination => 'Määränpää';

  @override
  String get cityAddressOrGps => 'Kaupunki, osoite tai GPS';

  @override
  String get cityOrAddress => 'Kaupunki tai osoite';

  @override
  String get useGps => 'Käytä GPS:ää';

  @override
  String get stop => 'Pysähdys';

  @override
  String stopN(int n) {
    return 'Pysähdys $n';
  }

  @override
  String get addStop => 'Lisää pysähdys';

  @override
  String get searchAlongRoute => 'Hae reitin varrelta';

  @override
  String get cheapest => 'Halvin';

  @override
  String nStations(int count) {
    return '$count asemaa';
  }

  @override
  String nBest(int count) {
    return '$count parasta';
  }

  @override
  String get fuelPricesTankerkoenig => 'Polttoainehinnat (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Vaaditaan polttoainehintahakuun Saksassa';

  @override
  String get evChargingOpenChargeMap => 'Sähköauton lataus (OpenChargeMap)';

  @override
  String get customKey => 'Oma avain';

  @override
  String get appDefaultKey => 'Sovelluksen oletusavain';

  @override
  String get optionalOverrideKey =>
      'Valinnainen: korvaa sovelluksen sisäänrakennettu avain omallasi';

  @override
  String get requiredForEvSearch => 'Vaaditaan sähköauton latausasemien hakuun';

  @override
  String get edit => 'Muokkaa';

  @override
  String get fuelPricesApiKey => 'Polttoainehinnat API-avain';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-avain';

  @override
  String get evChargingApiKey => 'Sähköauton lataus API-avain';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-avain';

  @override
  String get routeSegment => 'Reittisegmentti';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Näytä halvin asema joka $km km reitin varrella';
  }

  @override
  String get avoidHighways => 'Vältä moottoriteitä';

  @override
  String get avoidHighwaysDesc =>
      'Reitinlaskenta välttää maksullisia teitä ja moottoriteitä';

  @override
  String get showFuelStations => 'Näytä huoltoasemat';

  @override
  String get showFuelStationsDesc =>
      'Sisällytä bensiini-, diesel-, LPG-, CNG-asemat';

  @override
  String get showEvStations => 'Näytä latausasemat';

  @override
  String get showEvStationsDesc =>
      'Sisällytä sähköauton latausasemat hakutuloksiin';

  @override
  String get noStationsAlongThisRoute => 'Ei asemia tämän reitin varrella.';

  @override
  String get fuelCostCalculator => 'Polttoainekustannuslaskin';

  @override
  String get distanceKm => 'Matka (km)';

  @override
  String get consumptionL100km => 'Kulutus (L/100km)';

  @override
  String get fuelPriceEurL => 'Polttoaineen hinta (EUR/L)';

  @override
  String get tripCost => 'Matkan kustannus';

  @override
  String get fuelNeeded => 'Tarvittava polttoaine';

  @override
  String get totalCost => 'Kokonaiskustannus';

  @override
  String get enterCalcValues =>
      'Syötä matka, kulutus ja hinta laskeaksesi matkan kustannuksen';

  @override
  String get priceHistory => 'Hintahistoria';

  @override
  String get noPriceHistory => 'Ei hintahistoriaa vielä';

  @override
  String get noHourlyData => 'Ei tuntidataa';

  @override
  String get noStatistics => 'Tilastoja ei saatavilla';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Ka';

  @override
  String get showAllFuelTypes => 'Näytä kaikki polttoainetyypit';

  @override
  String get connected => 'Yhdistetty';

  @override
  String get notConnected => 'Ei yhdistetty';

  @override
  String get connectTankSync => 'Yhdistä TankSync';

  @override
  String get disconnectTankSync => 'Katkaise TankSync';

  @override
  String get viewMyData => 'Näytä omat tiedot';

  @override
  String get optionalCloudSync =>
      'Valinnainen pilvisynkronointi hälytyksille, suosikeille ja push-ilmoituksille';

  @override
  String get tapToUpdateGps => 'Napauta päivittääksesi GPS-sijainnin';

  @override
  String get gpsAutoUpdateHint =>
      'GPS-sijainti haetaan automaattisesti hakiessa. Voit myös päivittää sen manuaalisesti täällä.';

  @override
  String get clearGpsConfirm =>
      'Tyhjennä tallennettu GPS-sijainti? Voit päivittää sen uudelleen milloin tahansa.';

  @override
  String get pageNotFound => 'Sivua ei löytynyt';

  @override
  String get deleteAllServerData => 'Poista kaikki palvelintiedot';

  @override
  String get deleteServerDataConfirm => 'Poista kaikki palvelintiedot?';

  @override
  String get deleteEverything => 'Poista kaikki';

  @override
  String get allDataDeleted => 'Kaikki palvelintiedot poistettu';

  @override
  String get disconnectConfirm => 'Katkaise TankSync?';

  @override
  String get disconnect => 'Katkaise';

  @override
  String get myServerData => 'Omat palvelintiedot';

  @override
  String get anonymousUuid => 'Anonyymi UUID';

  @override
  String get server => 'Palvelin';

  @override
  String get syncedData => 'Synkronoidut tiedot';

  @override
  String get pushTokens => 'Push-tunnisteet';

  @override
  String get priceReports => 'Hintailmoitukset';

  @override
  String get totalItems => 'Kohteita yhteensä';

  @override
  String get estimatedSize => 'Arvioitu koko';

  @override
  String get viewRawJson => 'Näytä raakadata JSON-muodossa';

  @override
  String get exportJson => 'Vie JSON-muodossa (leikepöytä)';

  @override
  String get jsonCopied => 'JSON kopioitu leikepöydälle';

  @override
  String get rawDataJson => 'Raakadata (JSON)';

  @override
  String get close => 'Sulje';

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
  String get alertStatsActive => 'Aktiiviset';

  @override
  String get alertStatsToday => 'Tänään';

  @override
  String get alertStatsThisWeek => 'Tällä viikolla';

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
