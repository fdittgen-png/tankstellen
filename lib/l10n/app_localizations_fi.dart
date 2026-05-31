// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Avaa haku';

  @override
  String get fabOpenResults => 'Avaa tulokset';

  @override
  String get fabRunSearch => 'Suorita haku';

  @override
  String get fabRefineCriteria => 'Tarkenna hakua';

  @override
  String get routeSearchPartialBanner => 'Etsitään lisää asemia…';

  @override
  String get searchCriteriaTitle => 'Hakukriteerit';

  @override
  String get searchCriteriaOpen => 'Haku';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return '$km km säteellä';
  }

  @override
  String get searchCriteriaTapToSearch => 'Aloita haku napauttamalla';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Vaihda maa?';

  @override
  String countryChangeBody(String country) {
    return 'Vaihtaminen maahan $country muuttaa:';
  }

  @override
  String get countryChangeCurrency => 'Valuutta';

  @override
  String get countryChangeDistance => 'Etäisyys';

  @override
  String get countryChangeVolume => 'Tilavuus';

  @override
  String get countryChangePricePerUnit => 'Hintamuoto';

  @override
  String get countryChangeNote =>
      'Olemassa olevia suosikkeja ja tankkauslokeja ei kirjoiteta uudelleen; vain uudet merkinnät käyttävät uusia yksiköitä.';

  @override
  String get countryChangeConfirm => 'Vaihda';

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
  String get cacheTtlGroupNetwork => 'Verkko';

  @override
  String get cacheTtlGroupData => 'Tiedot';

  @override
  String get cacheTtlGroupGeocoding => 'Geokoodaus';

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
  String get reportThisIssue => 'Ilmoita ongelmasta';

  @override
  String get reportAlreadySent => 'Olet jo ilmoittanut tästä ongelmasta.';

  @override
  String get reportConsentTitle => 'Ilmoita GitHubiin?';

  @override
  String get reportConsentBody =>
      'Tämä avaa julkisen GitHub-ilmoituksen alla olevilla virhetiedoilla. Mitään GPS-koordinaatteja, API-avaimia tai henkilötietoja ei sisällytetä.';

  @override
  String get reportConsentConfirm => 'Avaa GitHub';

  @override
  String get reportConsentCancel => 'Peruuta';

  @override
  String get configProfileSection => 'Profiili';

  @override
  String get configActiveProfile => 'Aktiivinen profiili';

  @override
  String get configPreferredFuel => 'Ensisijainen polttoaine';

  @override
  String get configCountry => 'Maa';

  @override
  String get configRouteSegment => 'Reittijakso';

  @override
  String get configApiKeysSection => 'API-avaimet';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API-avain';

  @override
  String get configApiKeyConfigured => 'Määritetty';

  @override
  String get configApiKeyNotSet => 'Ei asetettu (demotila)';

  @override
  String get configApiKeyCommunity => 'Oletus (yhteisöavain)';

  @override
  String get searchLocationPlaceholder => 'Osoite, postinumero tai kaupunki';

  @override
  String get configEvKey => 'Sähköautojen lataus API-avain';

  @override
  String get configEvKeyCustom => 'Mukautettu avain';

  @override
  String get configEvKeyShared => 'Oletus (jaettu)';

  @override
  String get configCloudSyncSection => 'Pilvisynkronointi';

  @override
  String get configTankSyncConnected => 'Yhdistetty';

  @override
  String get configTankSyncDisabled => 'Poistettu käytöstä';

  @override
  String get configAuthMode => 'Todennustapa';

  @override
  String get configAuthEmail => 'Sähköposti (pysyvä)';

  @override
  String get configAuthAnonymous => 'Anonyymi (vain laite)';

  @override
  String get configDatabase => 'Tietokanta';

  @override
  String get configPrivacySummary => 'Tietosuojayhteenveto';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Suosikit, hälytykset ja ohitetut asemat synkronoidaan yksityiseen tietokantaasi\n• GPS-sijainti ja API-avaimet eivät koskaan poistu laitteeltasi\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Kaikki tiedot tallennetaan vain paikallisesti tälle laitteelle\n• Mitään tietoja ei lähetetä palvelimelle\n• API-avaimet salattu laitteen suojatussa tallennustilassa';

  @override
  String get configAuthNoteEmail =>
      'Sähköpostitili mahdollistaa pääsyn useilta laitteilta';

  @override
  String get configAuthNoteAnonymous =>
      'Anonyymi tili — tiedot sidottu tähän laitteeseen';

  @override
  String get configNone => 'Ei mitään';

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
  String get demoModeBannerAction => 'Hanki live-hinnat';

  @override
  String get sortDistance => 'Etäisyys';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Arvosana';

  @override
  String get sortPriceDistance => 'Hinta/km';

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
  String get routeModeBannerLabel =>
      'Reittitila — etäisyydet ovat reitin varrelta';

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
  String get routePlanningSection => 'Reittisuunnittelu';

  @override
  String get routeMinSaving => 'Vähimmäissäästö';

  @override
  String get routeMinSavingOff => 'Pois';

  @override
  String get routeMinSavingOffCaption =>
      'Näytetään kaikki reitin varrelta löytyneet asemat';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Vain asemat $amount päässä reitin halvimmasta';
  }

  @override
  String get routeDetourBudget => 'Suurin kiertotie';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Näytä asemat enintään $km km päässä suorasta reitistä';
  }

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
  String get ignoredStationsLabel => 'Ohitetut';

  @override
  String get ratingsLabel => 'Arvioinnit';

  @override
  String get favoritesDataCache => 'Suosikkien tiedot';

  @override
  String get citySearchCache => 'Kaupunkihaku';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Tietojen poisto ei ole käytettävissä Yhteisö-tilassa. Katkaise ensin yhteys tai käytä yksityistä tietokantaa.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count seurattua asemaa';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count määritetty';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count piilotettua asemaa';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count arvioitua asemaa';
  }

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
  String get forgetAllSyncedTripsButton => 'Unohda kaikki synkronoidut matkat';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Unohda kaikki synkronoidut matkat?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Jokainen matkayhteenveto ja yksityiskohtainen tiedosto poistetaan palvelimelta. Laitteellasi oleva paikallinen matkahistoria ei muutu.\n\nTätä toimintoa ei voi peruuttaa.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Unohda kaikki';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Kaikki synkronoidut matkat poistettu palvelimelta';

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
  String get syncedTrips => 'Matkat';

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
  String get account => 'Tili';

  @override
  String get continueAsGuest => 'Jatka vieraana';

  @override
  String get createAccount => 'Luo tili';

  @override
  String get signIn => 'Kirjaudu sisään';

  @override
  String get upgradeToEmail => 'Luo sähköpostitili';

  @override
  String get savedRoutes => 'Tallennetut reitit';

  @override
  String get noSavedRoutes => 'Ei tallennettuja reittejä';

  @override
  String get noSavedRoutesHint =>
      'Hae reitin varrelta ja tallenna se myöhempää käyttöä varten.';

  @override
  String get saveRoute => 'Tallenna reitti';

  @override
  String get routeName => 'Reitin nimi';

  @override
  String itineraryDeleted(String name) {
    return '$name poistettu';
  }

  @override
  String loadingRoute(String name) {
    return 'Ladataan reitti: $name';
  }

  @override
  String get refreshFailed => 'Päivitys epäonnistui. Yritä uudelleen.';

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
      'Määritä sovellus muutamassa nopeassa vaiheessa.';

  @override
  String get onboardingApiKeyDescription =>
      'Rekisteröidy ilmaiseksi API-avaimelle tai ohita ja tutustu sovellukseen esimerkkitiedoilla.';

  @override
  String get onboardingComplete => 'Kaikki valmista!';

  @override
  String get onboardingCompleteHint =>
      'Voit muuttaa näitä asetuksia milloin tahansa profiilissasi.';

  @override
  String get onboardingBack => 'Takaisin';

  @override
  String get onboardingNext => 'Seuraava';

  @override
  String get onboardingSkip => 'Ohita';

  @override
  String get onboardingFinish => 'Aloita';

  @override
  String crossBorderNearby(String country) {
    return '$country on lähellä';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km rajalle';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Keskim. täällä: $price EUR ($count asemaa)';
  }

  @override
  String get allPricesView => 'Kaikki hinnat';

  @override
  String get compactView => 'Kompakti';

  @override
  String get switchToAllPricesView => 'Vaihda kaikkien hintojen näkymään';

  @override
  String get switchToCompactView => 'Vaihda kompaktiin näkymään';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Ei varastossa';

  @override
  String get gdprTitle => 'Tietosuojasi';

  @override
  String get gdprSubtitle =>
      'Tämä sovellus kunnioittaa yksityisyyttäsi. Valitse, mitä tietoja haluat jakaa. Voit muuttaa näitä asetuksia milloin tahansa.';

  @override
  String get gdprLocationTitle => 'Sijaintioikeus';

  @override
  String get gdprLocationDescription =>
      'Koordinaattisi lähetetään polttoainehinta-API:lle lähellä olevien asemien löytämiseksi. Sijaintitietoja ei koskaan tallenneta palvelimelle eikä niitä käytetä seurantaan.';

  @override
  String get gdprLocationShort =>
      'Etsi lähellä olevia polttoaineasemia sijaintisi avulla';

  @override
  String get gdprErrorReportingTitle => 'Virheraportointi';

  @override
  String get gdprErrorReportingDescription =>
      'Anonyymiset kaatumisraportit auttavat parantamaan sovellusta. Henkilötietoja ei sisällytetä. Raportit lähetetään Sentryyn vain kun se on määritetty.';

  @override
  String get gdprErrorReportingShort =>
      'Lähetä anonyymiset kaatumisraportit sovelluksen parantamiseksi';

  @override
  String get gdprCloudSyncTitle => 'Pilvisynkronointi';

  @override
  String get gdprCloudSyncDescription =>
      'Synkronoi suosikit ja hälytykset laitteiden välillä TankSyncin avulla. Käyttää anonyymiä todennusta. Tietosi salataan siirrossa.';

  @override
  String get gdprCloudSyncShort =>
      'Synkronoi suosikit ja hälytykset laitteiden välillä';

  @override
  String get gdprLegalBasis =>
      'Oikeusperuste: Art. 6(1)(a) GDPR (Suostumus). Voit peruuttaa suostumuksen milloin tahansa Asetuksissa.';

  @override
  String get gdprAcceptAll => 'Hyväksy kaikki';

  @override
  String get gdprAcceptSelected => 'Hyväksy valitut';

  @override
  String get gdprSettingsHint =>
      'Voit muuttaa tietosuojavalintojasi milloin tahansa.';

  @override
  String get routeSaved => 'Reitti tallennettu!';

  @override
  String get routeSaveFailed => 'Reitin tallennus epäonnistui';

  @override
  String get sqlCopied => 'SQL kopioitu leikepöydälle';

  @override
  String get connectionDataCopied => 'Yhteystiedot kopioitu';

  @override
  String get accountDeleted => 'Tili poistettu. Paikalliset tiedot säilytetty.';

  @override
  String get switchedToAnonymous => 'Vaihdettu anonyymiin istuntoon';

  @override
  String failedToSwitch(String error) {
    return 'Vaihto epäonnistui: $error';
  }

  @override
  String get topicUrlCopied => 'Aiheen URL kopioitu';

  @override
  String get testNotificationSent => 'Testipush lähetetty!';

  @override
  String get testNotificationFailed => 'Testipushin lähetys epäonnistui';

  @override
  String get pushUpdateFailed => 'Push-ilmoituksen päivitys epäonnistui';

  @override
  String get connectedAsGuest => 'Yhdistetty vieraana';

  @override
  String get accountCreated => 'Tili luotu!';

  @override
  String get signedIn => 'Kirjauduttu sisään!';

  @override
  String stationHidden(String name) {
    return '$name piilotettu';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name poistettu suosikeista';
  }

  @override
  String invalidApiKey(String error) {
    return 'Virheellinen API-avain: $error';
  }

  @override
  String get invalidQrCode => 'Virheellinen QR-koodimuoto';

  @override
  String get invalidQrCodeTankSync =>
      'Virheellinen QR-koodi — odotettiin TankSync-muotoa';

  @override
  String get tankSyncConnected => 'TankSync yhdistetty!';

  @override
  String get syncCompleted => 'Synkronointi valmis — tiedot päivitetty';

  @override
  String get deviceCodeCopied => 'Laitekoodi kopioitu';

  @override
  String get undo => 'Kumoa';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Anna kelvollinen $length-numeroinen $label';
  }

  @override
  String get freshnessAgo => 'sitten';

  @override
  String get freshnessStale => 'Vanhentunut';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Tietojen tuoreus: $age';
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
      other: 'Anna $count tähteä',
      one: 'Anna 1 tähti',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Heikko';

  @override
  String get passwordStrengthFair => 'Kohtalainen';

  @override
  String get passwordStrengthStrong => 'Vahva';

  @override
  String get passwordReqMinLength => 'Vähintään 8 merkkiä';

  @override
  String get passwordReqUppercase => 'Vähintään 1 iso kirjain';

  @override
  String get passwordReqLowercase => 'Vähintään 1 pieni kirjain';

  @override
  String get passwordReqDigit => 'Vähintään 1 numero';

  @override
  String get passwordReqSpecial => 'Vähintään 1 erikoismerkki';

  @override
  String get passwordTooWeak => 'Salasana ei täytä kaikkia vaatimuksia';

  @override
  String get brandFilterAll => 'Kaikki';

  @override
  String get brandFilterNoHighway => 'Ei moottoritietä';

  @override
  String get swipeTutorialMessage =>
      'Pyyhkäise oikealle navigoidaksesi, vasemmalle poistaaksesi';

  @override
  String get swipeTutorialDismiss => 'Selvä';

  @override
  String get alertStatsActive => 'Aktiiviset';

  @override
  String get alertStatsToday => 'Tänään';

  @override
  String get alertStatsThisWeek => 'Tällä viikolla';

  @override
  String get privacyDashboardTitle => 'Tietosuojanäkymä';

  @override
  String get privacyDashboardSubtitle => 'Katso, vie tai poista tietosi';

  @override
  String get privacyDashboardBanner =>
      'Tietosi kuuluvat sinulle. Täällä voit nähdä kaiken, mitä tämä sovellus tallentaa, viedä sen tai poistaa sen.';

  @override
  String get privacyLocalData => 'Tiedot tällä laitteella';

  @override
  String get privacyIgnoredStations => 'Ohitetut asemat';

  @override
  String get privacyRatings => 'Asemien arvostelut';

  @override
  String get privacyPriceHistory => 'Hintahistoria-asemat';

  @override
  String get privacyProfiles => 'Hakuprofiilit';

  @override
  String get privacyItineraries => 'Tallennetut reitit';

  @override
  String get privacyCacheEntries => 'Välimuistimerkinnät';

  @override
  String get privacyApiKey => 'API-avain tallennettu';

  @override
  String get privacyEvApiKey => 'Sähköauto-API-avain tallennettu';

  @override
  String get privacyEstimatedSize => 'Arvioitu tallennustila';

  @override
  String get privacySyncedData => 'Pilvisynkronointi (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Pilvisynkronointi on poistettu käytöstä. Kaikki tiedot pysyvät vain tällä laitteella.';

  @override
  String get privacySyncMode => 'Synkronointitapa';

  @override
  String get privacySyncUserId => 'Käyttäjätunnus';

  @override
  String get privacySyncDescription =>
      'Kun synkronointi on käytössä, suosikit, hälytykset, ohitetut asemat ja arvostelut tallennetaan myös TankSync-palvelimelle.';

  @override
  String get privacyViewServerData => 'Tarkastele palvelintietoja';

  @override
  String get privacyExportButton => 'Vie kaikki tiedot JSON-muodossa';

  @override
  String get privacyExportSuccess => 'Tiedot viety leikepöydälle';

  @override
  String get privacyExportCsvButton => 'Vie kaikki tiedot CSV-muodossa';

  @override
  String get privacyExportCsvSuccess => 'CSV-tiedot viety leikepöydälle';

  @override
  String get savedToDownloadsFolder => 'Tallennettu Lataukset-kansioon';

  @override
  String get privacyDeleteButton => 'Poista kaikki tiedot';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Kopioi virheloki leikepöydälle ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Tallenna virheloki ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Tyhjennä virheloki';

  @override
  String get privacyErrorLogCleared => 'Virheloki tyhjennetty';

  @override
  String get privacyDeleteTitle => 'Poistetaanko kaikki tiedot?';

  @override
  String get privacyDeleteBody =>
      'Tämä poistaa pysyvästi:\n\n- Kaikki suosikit ja asematiedot\n- Kaikki hakuprofiilit\n- Kaikki hintahälytykset\n- Kaikki hintahistoriat\n- Kaikki välimuistin tiedot\n- API-avaimesi\n- Kaikki sovelluksen asetukset\n\nSovellus palautuu alkutilaan. Tätä toimintoa ei voi peruuttaa.';

  @override
  String get privacyDeleteConfirm => 'Poista kaikki';

  @override
  String get yes => 'Kyllä';

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
  String get paymentMethods => 'Maksutavat';

  @override
  String get paymentMethodCash => 'Käteinen';

  @override
  String get paymentMethodCard => 'Kortti';

  @override
  String get paymentMethodContactless => 'Lähimaksu';

  @override
  String get paymentMethodFuelCard => 'Polttoainekortti';

  @override
  String get paymentMethodApp => 'Sovellus';

  @override
  String payWithApp(String app) {
    return 'Maksa sovelluksella $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Verrattuna viimeisten 3 tankkauksen liukuvaan keskiarvoon ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Kulutus $value L/100 km, $delta suhteessa liukuvaan keskiarvoosi';
  }

  @override
  String get drivingMode => 'Ajotila';

  @override
  String get drivingExit => 'Poistu';

  @override
  String get drivingNearestStation => 'Lähin';

  @override
  String get drivingTapToUnlock => 'Napauta lukituksen avaamiseksi';

  @override
  String get drivingSafetyTitle => 'Turvallisuushuomio';

  @override
  String get drivingSafetyMessage =>
      'Älä käytä sovellusta ajon aikana. Pysähdy turvalliseen paikkaan ennen ruudun käyttöä. Kuljettaja on aina vastuussa ajoneuvon turvallisesta käytöstä.';

  @override
  String get drivingSafetyAccept => 'Ymmärrän';

  @override
  String get voiceAnnouncementsTitle => 'Äänilmoitukset';

  @override
  String get voiceAnnouncementsDescription =>
      'Ilmoita lähellä olevista edullisista asemista ajon aikana';

  @override
  String get voiceAnnouncementsEnabled => 'Ota äänilmoitukset käyttöön';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Vain alle $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometriä edessä, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Ilmoitussäde';

  @override
  String get voiceAnnouncementCooldown => 'Toistumisväli';

  @override
  String get nearestStations => 'Lahimmat asemat';

  @override
  String get nearestStationsHint =>
      'Loyda lahimmat asemat nykyisella sijainnillasi';

  @override
  String get consumptionLogTitle => 'Polttoainekulutus';

  @override
  String get consumptionLogMenuTitle => 'Kulutuskirjanpito';

  @override
  String get consumptionLogMenuSubtitle =>
      'Seuraa tankkauksia ja laske L/100km';

  @override
  String get consumptionStatsTitle => 'Kulutustilastot';

  @override
  String get addFillUp => 'Lisää tankkaus';

  @override
  String get noFillUpsTitle => 'Ei vielä tankkauksia';

  @override
  String get noFillUpsSubtitle =>
      'Kirjaa ensimmäinen tankkauksesi aloittaaksesi kulutuksen seurannan.';

  @override
  String get fillUpDate => 'Päivämäärä';

  @override
  String get liters => 'Litrat';

  @override
  String get odometerKm => 'Matkamittari (km)';

  @override
  String get notesOptional => 'Muistiinpanot (valinnainen)';

  @override
  String get stationPreFilled => 'Asema esitäytetty';

  @override
  String get statAvgConsumption => 'Keskim. L/100km';

  @override
  String get statAvgCostPerKm => 'Keskim. kustannus/km';

  @override
  String get statTotalLiters => 'Yhteensä litraa';

  @override
  String get statTotalSpent => 'Yhteensä käytetty';

  @override
  String get statFillUpCount => 'Tankkaukset';

  @override
  String get fieldRequired => 'Pakollinen';

  @override
  String get fieldInvalidNumber => 'Virheellinen numero';

  @override
  String get carbonDashboardTitle => 'Hiilijalanjälkinäkymä';

  @override
  String get carbonEmptyTitle => 'Ei vielä tietoja';

  @override
  String get carbonEmptySubtitle =>
      'Kirjaa tankkauksia nähdäksesi hiilijalanjälkinäkymän.';

  @override
  String get carbonSummaryTotalCost => 'Kokonaiskustannus';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 yhteensä';

  @override
  String get monthlyCostsTitle => 'Kuukausittaiset kustannukset';

  @override
  String get monthlyEmissionsTitle => 'Kuukausittaiset CO2-päästöt';

  @override
  String get vehiclesTitle => 'Omat ajoneuvot';

  @override
  String get vehiclesMenuTitle => 'Omat ajoneuvot';

  @override
  String get vehiclesMenuSubtitle => 'Akku, liittimet, latausasetukset';

  @override
  String get vehiclesEmptyMessage =>
      'Lisää autosi suodattaaksesi liittimen mukaan ja arvioidaksesi latauskulut.';

  @override
  String get vehiclesWizardTitle => 'Omat ajoneuvot (valinnainen)';

  @override
  String get vehiclesWizardSubtitle =>
      'Lisää autosi kulutuskirjanpidon esitäyttöä ja sähköauton liitisuodattimia varten. Voit ohittaa tämän ja lisätä ajoneuvoja myöhemmin.';

  @override
  String get vehiclesWizardNoneYet => 'Ei vielä yhtään ajoneuvoa.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajoneuvoa',
      one: '1 ajoneuvo',
    );
    return 'Sinulla on $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Ohita ja viimeistele asennus — voit lisätä ajoneuvoja milloin tahansa Asetuksista.';

  @override
  String get fillUpVehicleLabel => 'Ajoneuvo';

  @override
  String get fillUpVehicleNone => 'Ei ajoneuvoa';

  @override
  String get fillUpVehicleRequired => 'Ajoneuvo vaaditaan';

  @override
  String get reportScanError => 'Ilmoita skannauksesta';

  @override
  String get pickStationTitle => 'Valitse asema';

  @override
  String get pickStationHelper =>
      'Aloita tankkaus tunnetulta asemalta, jotta hinnat, merkki ja polttoainetyyppi täyttyvät automaattisesti.';

  @override
  String get pickStationEmpty =>
      'Ei vielä suosikkiasemia — lisää niitä Hausta tai Suosikeista, tai ohita ja täytä manuaalisesti.';

  @override
  String get pickStationSkip => 'Ohita — lisää ilman asemaa';

  @override
  String get scanPump => 'Skannaa pumppu';

  @override
  String get scanPayment => 'Skannaa maksu-QR';

  @override
  String get qrPaymentBeneficiary => 'Saaja';

  @override
  String get qrPaymentAmount => 'Summa';

  @override
  String get qrPaymentEpcTitle => 'SEPA-maksu';

  @override
  String get qrPaymentEpcEmpty => 'Ei dekoodattuja kenttiä';

  @override
  String get qrPaymentOpenInBank => 'Avaa pankkisovelluksessa';

  @override
  String get qrPaymentLaunchFailed => 'Ei sovellusta tämän koodin avaamiseen';

  @override
  String get qrPaymentUnknownTitle => 'Tuntematon koodi';

  @override
  String get qrPaymentCopyRaw => 'Kopioi raakoteksti';

  @override
  String get qrPaymentCopiedRaw => 'Kopioitu leikepöydälle';

  @override
  String get qrPaymentReport => 'Ilmoita skannauksesta';

  @override
  String get qrPaymentEpcCopied =>
      'Pankkitiedot kopioitu — liitä pankkisovellukseesi';

  @override
  String get qrScannerGuidance => 'Osoita kamera QR-koodiin';

  @override
  String get qrScannerPermissionDenied =>
      'QR-koodien skannaukseen tarvitaan kameraluupa.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kameraluupa evättiin. Avaa asetukset myöntääksesi sen.';

  @override
  String get qrScannerRetryPermission => 'Yritä uudelleen';

  @override
  String get qrScannerOpenSettings => 'Avaa asetukset';

  @override
  String get qrScannerTimeout =>
      'QR-koodia ei havaittu. Mene lähemmäs tai yritä uudelleen.';

  @override
  String get qrScannerRetry => 'Yritä uudelleen';

  @override
  String get torchOn => 'Ota salama käyttöön';

  @override
  String get torchOff => 'Poista salama käytöstä';

  @override
  String get obdNoAdapter => 'Ei OBD2-sovitinta kantaman sisällä';

  @override
  String get obdOdometerUnavailable => 'Matkamittaria ei voitu lukea';

  @override
  String get obdPermissionDenied =>
      'Myönnä Bluetooth-lupa järjestelmäasetuksissa';

  @override
  String get obdAdapterUnresponsive =>
      'Sovitin ei vastannut — käynnistä sytytin ja yritä uudelleen';

  @override
  String get obdPickerTitle => 'Valitse OBD2-sovitin';

  @override
  String get obdPickerScanning => 'Etsitään sovittimia…';

  @override
  String get obdPickerConnecting => 'Yhdistetään…';

  @override
  String get themeSettingTitle => 'Teema';

  @override
  String get themeModeLight => 'Vaalea';

  @override
  String get themeModeDark => 'Tumma';

  @override
  String get themeModeSystem => 'Seuraa järjestelmää';

  @override
  String get tripRecordingTitle => 'Tallennetaan matkaa';

  @override
  String get tripSummaryTitle => 'Matkan yhteenveto';

  @override
  String get tripMetricDistance => 'Etäisyys';

  @override
  String get tripMetricSpeed => 'Nopeus';

  @override
  String get tripMetricFuelUsed => 'Polttoainetta käytetty';

  @override
  String get tripMetricAvgConsumption => 'Keskim.';

  @override
  String get tripMetricElapsed => 'Kulunut aika';

  @override
  String get tripMetricOdometer => 'Matkamittari';

  @override
  String get tripStop => 'Lopeta tallennus';

  @override
  String get tripPause => 'Keskeytä';

  @override
  String get tripResume => 'Jatka';

  @override
  String get tripBannerRecording => 'Tallennetaan matkaa';

  @override
  String get tripBannerPaused => 'Matka keskeytetty — napauta jatkaaksesi';

  @override
  String get navConsumption => 'Kulutus';

  @override
  String get vehicleBaselineSectionTitle => 'Perusarvojen kalibrointi';

  @override
  String get vehicleBaselineEmpty =>
      'Ei näytteitä vielä — aloita OBD2-matka oppiaksesi tämän ajoneuvon polttoaineprofiilin.';

  @override
  String get vehicleBaselineProgress => 'Opittu näytteistä eri ajotilanteissa.';

  @override
  String get vehicleBaselineReset => 'Nollaa ajotilanteen perusarvo';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Nollatako ajotilanteen perusarvo?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Tämä poistaa kaikki opitut näytteet tälle ajoneuvolle. Palataan kylmäkäynnistyksen oletusarvoihin, kunnes uudet matkat täyttävät profiilin uudelleen.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-sovitin';

  @override
  String get vehicleAdapterEmpty =>
      'Ei paritettu sovitinta. Paritse yksi, jotta sovellus voi yhdistää automaattisesti seuraavalla kerralla.';

  @override
  String get vehicleAdapterUnnamed => 'Tuntematon sovitin';

  @override
  String get vehicleAdapterPair => 'Paritetaan sovitin';

  @override
  String get vehicleAdapterForget => 'Unohda sovitin';

  @override
  String get achievementsTitle => 'Saavutukset';

  @override
  String get achievementFirstTrip => 'Ensimmäinen matka';

  @override
  String get achievementFirstTripDesc => 'Tallenna ensimmäinen OBD2-matkasi.';

  @override
  String get achievementFirstFillUp => 'Ensimmäinen tankkaus';

  @override
  String get achievementFirstFillUpDesc => 'Kirjaa ensimmäinen tankkauksesi.';

  @override
  String get achievementTenTrips => '10 matkaa';

  @override
  String get achievementTenTripsDesc => 'Tallenna 10 OBD2-matkaa.';

  @override
  String get achievementZeroHarsh => 'Tasainen kuljettaja';

  @override
  String get achievementZeroHarshDesc =>
      'Suorita vähintään 10 km matka ilman äkillistä jarrutusta tai kiihdytystä.';

  @override
  String get achievementEcoWeek => 'Eko-viikko';

  @override
  String get achievementEcoWeekDesc =>
      'Aja 7 peräkkäistä päivää vähintään yksi tasainen matka päivässä.';

  @override
  String get achievementPriceWin => 'Hintavoitto';

  @override
  String get achievementPriceWinDesc =>
      'Kirjaa tankkaus, joka alittaa aseman 30 päivän keskiarvon 5 % tai enemmän.';

  @override
  String get syncBaselinesToggleTitle => 'Jaa opitut ajoneuvoprofiilit';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Lataa ajoneuvokohtaiset kulutusperusarvot, jotta toinen laite voi käyttää niitä.';

  @override
  String get obd2StatusConnected => 'OBD2-sovitin: yhdistetty';

  @override
  String get obd2StatusAttempting => 'OBD2-sovitin: yhdistetään';

  @override
  String get obd2StatusUnreachable => 'OBD2-sovitin: ei tavoitettavissa';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-sovitin: Bluetooth-lupa tarvitaan';

  @override
  String get obd2StatusConnectedBody => 'Valmis tallentamaan matkan.';

  @override
  String get obd2StatusAttemptingBody => 'Yhdistetään taustalla…';

  @override
  String get obd2StatusUnreachableBody =>
      'Sovitin kantaman ulkopuolella tai jo käytössä toisessa sovelluksessa.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Myönnä Bluetooth-lupa järjestelmäasetuksissa yhdistääksesi automaattisesti.';

  @override
  String get obd2StatusNoAdapter => 'Ei paritettu sovitinta';

  @override
  String get obd2StatusForget => 'Unohda sovitin';

  @override
  String get tripHistoryTitle => 'Matkahistoria';

  @override
  String get tripHistoryEmptyTitle => 'Ei vielä matkoja';

  @override
  String get tripHistoryEmptySubtitle =>
      'Yhdistä OBD2-sovitin ja tallenna matka aloittaaksesi ajohistorian rakentamisen.';

  @override
  String get tripHistoryUnknownDate => 'Tuntematon päivämäärä';

  @override
  String get situationIdle => 'Tyhjäkäynti';

  @override
  String get situationStopAndGo => 'Pysähtele-jatka';

  @override
  String get situationUrban => 'Kaupunki';

  @override
  String get situationHighway => 'Moottoritie';

  @override
  String get situationDecel => 'Hidastuu';

  @override
  String get situationClimbing => 'Nousu / kuorma';

  @override
  String get situationHardAccel => 'Voimakas kiihdytys';

  @override
  String get situationFuelCut => 'Polttoaineen katkaisu — liuku';

  @override
  String get tripSaveAsFillUp => 'Tallenna tankkauksena';

  @override
  String get tripSaveRecording => 'Tallenna matka';

  @override
  String get tripDiscard => 'Hylkää';

  @override
  String obdOdometerRead(int km) {
    return 'Matkamittari luettu: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Ei asetettu';

  @override
  String get wizardVehicleTapToEdit => 'Napauta muokataksesi';

  @override
  String get wizardVehicleDefaultBadge => 'Oletus';

  @override
  String get wizardProfileChoiceHint =>
      'Valitse, miten haluat käyttää sovellusta. Voit muuttaa tätä myöhemmin Asetuksissa.';

  @override
  String get wizardProfileChoiceFooter =>
      'Voit muuttaa valintaasi milloin tahansa Asetukset → Käyttötapa.';

  @override
  String get wizardProfileBasicName => 'Perus';

  @override
  String get wizardProfileBasicDescription =>
      'Lähimmät edulliset polttoaine- ja sähkölataushinnat. Suosikit ja hintahälytykset.';

  @override
  String get wizardProfileMediumName => 'Keski';

  @override
  String get wizardProfileMediumDescription =>
      'Kaikki Perustasolta, lisäksi manuaalinen polttoaine- ja lataustankkausten seuranta.';

  @override
  String get wizardProfileFullName => 'Täysi';

  @override
  String get wizardProfileFullDescription =>
      'Kaikki Keskitasolta, lisäksi automaattinen OBD2-matkojen tallennus, ajopisteet ja kanta-asiakaskortit.';

  @override
  String get wizardProfileCustomName => 'Mukautettu';

  @override
  String get wizardProfileCustomDescription =>
      'Oma yhdistelmäsi ominaisuuksia. Säädä kutakin kytkintä alla.';

  @override
  String get useModeSectionHint =>
      'Mitoita sovellus todelliseen käyttöön. Esiasetusten valinta aktivoi vastaavan ominaisuusjoukon.';

  @override
  String get useModeCustomSettingsDescription =>
      'Ominaisuusyhdistelmäsi ei vastaa mitään esiasetusta. Valitse yksi yllä ylikirjoittaaksesi tai jatka yksittäisten ominaisuuksien mukauttamista alla.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Käyttötavaksi asetettu $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Oletusajoneuvo (valinnainen)';

  @override
  String get profileDefaultVehicleNone => 'Ei oletusta';

  @override
  String get profileFuelFromVehicleHint =>
      'Polttoainetyyppi on johdettu oletusajoneuvostasi. Tyhjennä ajoneuvo valitaksesi polttoaineen suoraan.';

  @override
  String get consumptionNoVehicleTitle => 'Lisää ensin ajoneuvo';

  @override
  String get consumptionNoVehicleBody =>
      'Tankkaukset liitetään ajoneuvoon. Lisää autosi aloittaaksesi kulutuksen kirjaamisen.';

  @override
  String get vehicleAdd => 'Lisää ajoneuvo';

  @override
  String get vehicleAddTitle => 'Lisää ajoneuvo';

  @override
  String get vehicleEditTitle => 'Muokkaa ajoneuvoa';

  @override
  String get vehicleDeleteTitle => 'Poistetaanko ajoneuvo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Poistetaanko \"$name\" profiileistasi?';
  }

  @override
  String get vehicleNameLabel => 'Nimi';

  @override
  String get vehicleNameHint => 'esim. Oma Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Polttomoottori';

  @override
  String get vehicleTypeHybrid => 'Hybridi';

  @override
  String get vehicleTypeEv => 'Sähköinen';

  @override
  String get vehicleEvSectionTitle => 'Sähköinen';

  @override
  String get vehicleCombustionSectionTitle => 'Polttomoottori';

  @override
  String get vehicleBatteryLabel => 'Akun kapasiteetti (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maksimilataustehо (kW)';

  @override
  String get vehicleConnectorsLabel => 'Tuetut liittimet';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max SoC %';

  @override
  String get vehicleTankLabel => 'Tankin kapasiteetti (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Ensisijainen polttoaine';

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
  String get connectorThreePin => '3-nastainen';

  @override
  String get evShowOnMap => 'Näytä sähköasemat';

  @override
  String get evAvailableOnly => 'Vain vapaat';

  @override
  String get evMinPower => 'Minimitehо';

  @override
  String get evMaxPower => 'Maksimitehо';

  @override
  String get evOperator => 'Operaattori';

  @override
  String get evLastUpdate => 'Viimeisin päivitys';

  @override
  String get evStatusAvailable => 'Vapaa';

  @override
  String get evStatusOccupied => 'Varattu';

  @override
  String get evStatusOutOfOrder => 'Epäkunnossa';

  @override
  String get openOnlyFilter => 'Vain avoinna';

  @override
  String get saveAsDefaults => 'Tallenna oletuksiksi';

  @override
  String get criteriaSavedToProfile => 'Tallennettu oletuksiksi';

  @override
  String get profileNotFound => 'Ei aktiivista profiilia';

  @override
  String get updatingFavorites => 'Päivitetään suosikkejasi...';

  @override
  String get fetchingLatestPrices => 'Haetaan uusimmat hinnat';

  @override
  String get noDataAvailable => 'Ei tietoja';

  @override
  String get configAndPrivacy => 'Asetukset ja tietosuoja';

  @override
  String get searchToSeeMap => 'Hae nähdäksesi asemat kartalla';

  @override
  String get evPowerAny => 'Mikä tahansa';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profiili';

  @override
  String get sectionLocation => 'Sijainti';

  @override
  String get tooltipBack => 'Takaisin';

  @override
  String get tooltipClose => 'Sulje';

  @override
  String get tooltipShare => 'Jaa';

  @override
  String get tooltipClearSearch => 'Tyhjennä hakukenttä';

  @override
  String get minimalDriveInstantConsumption => 'Hetkellinen kulutus';

  @override
  String get coachingShiftUp => 'Vaihda ylös';

  @override
  String get coachingShiftDown => 'Vaihda alas';

  @override
  String get coachingEasePedal => 'Hellitä kaasua';

  @override
  String get tooltipUseGps => 'Käytä GPS-sijaintia';

  @override
  String get tooltipShowPassword => 'Näytä salasana';

  @override
  String get tooltipHidePassword => 'Piilota salasana';

  @override
  String get evConnectorsLabel => 'Saatavilla olevat liittimet';

  @override
  String get evConnectorsNone => 'Ei liitintietoja';

  @override
  String get switchToEmail => 'Vaihda sähköpostiin';

  @override
  String get switchToEmailSubtitle =>
      'Säilytä tiedot, lisää sisäänkirjautuminen muista laitteista';

  @override
  String get switchToAnonymousAction => 'Vaihda anonyymiksi';

  @override
  String get switchToAnonymousSubtitle =>
      'Säilytä paikalliset tiedot, käytä uutta anonyymiä istuntoa';

  @override
  String get linkDevice => 'Linkitä laite';

  @override
  String get shareDatabase => 'Jaa tietokanta';

  @override
  String get disconnectAction => 'Katkaise yhteys';

  @override
  String get disconnectSubtitle =>
      'Lopeta synkronointi (paikalliset tiedot säilytetään)';

  @override
  String get deleteAccountAction => 'Poista tili';

  @override
  String get deleteAccountSubtitle => 'Poista kaikki palvelintiedot pysyvästi';

  @override
  String get localOnly => 'Vain paikallinen';

  @override
  String get localOnlySubtitle =>
      'Valinnainen: synkronoi suosikit, hälytykset ja arvostelut laitteiden välillä';

  @override
  String get setupCloudSync => 'Määritä pilvisynkronointi';

  @override
  String get disconnectTitle => 'Katkaistako TankSync?';

  @override
  String get disconnectBody =>
      'Pilvisynkronointi poistetaan käytöstä. Paikalliset tietosi (suosikit, hälytykset, historia) säilytetään tällä laitteella. Palvelintietoja ei poisteta.';

  @override
  String get deleteAccountTitle => 'Poistetaanko tili?';

  @override
  String get deleteAccountBody =>
      'Tämä poistaa pysyvästi kaikki tietosi palvelimelta (suosikit, hälytykset, arvostelut, reitit). Paikalliset tiedot tällä laitteella säilytetään.\n\nTätä ei voi peruuttaa.';

  @override
  String get switchToAnonymousTitle => 'Vaihdettaanko anonyymiksi?';

  @override
  String get switchToAnonymousBody =>
      'Sinut kirjataan ulos sähköpostitililtäsi ja jatkat uudella anonyymillä istunnolla.\n\nPaikalliset tietosi (suosikit, hälytykset) pysyvät tällä laitteella ja synkronoidaan uudelle anonyymille tilille.';

  @override
  String get switchAction => 'Vaihda';

  @override
  String get helpBannerCriteria =>
      'Profiilisi oletukset on esitäytetty. Tarkenna hakua alla olevilla kriteereillä.';

  @override
  String get helpBannerAlerts =>
      'Aseta hintaraja asemalle. Saat ilmoituksen kun hinnat laskevat sen alle. Tarkistukset tehdään 30 minuutin välein.';

  @override
  String get helpBannerConsumption =>
      'Kirjaa jokainen tankkaus seurataksesi todellista kulutustasi ja CO₂-jalanjälkeäsi. Poista merkintä pyyhkäisemällä vasemmalle.';

  @override
  String get helpBannerVehicles =>
      'Lisää ajoneuvosi, jotta tankkaukset ja polttoainevalinnat täyttyvät oikein. Ensimmäisestä ajoneuvosta tulee oletuksesi.';

  @override
  String get syncNow => 'Synkronoi nyt';

  @override
  String get onboardingPreferencesTitle => 'Asetuksesi';

  @override
  String get onboardingZipHelper => 'Käytetään kun GPS ei ole käytettävissä';

  @override
  String get onboardingRadiusHelper => 'Suurempi säde = enemmän tuloksia';

  @override
  String get onboardingPrivacy =>
      'Nämä asetukset tallennetaan vain laitteellesi eikä niitä koskaan jaeta.';

  @override
  String get onboardingLandingTitle => 'Aloitusnäyttö';

  @override
  String get onboardingLandingHint =>
      'Valitse, mikä näyttö avautuu kun käynnistät sovelluksen.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Pysy poissa sovelluksesta — mutta älä lopeta sitä.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Avaa Sparkilo kerran jokaisen uudelleenkäynnistyksen jälkeen.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple käynnistää Sparkilon vasta kun olet avannut sen ainakin kerran puhelimen käynnistymisen jälkeen. Sen jälkeen matkasi tallentuvat automaattisesti.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Älä pyyhkäise Sparkiloa pois sovelluksenvaihtonäkymästä.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Pakko-sulkeminen\" käskee iOS:a lopettamaan sovelluksen uudelleenkäynnistyksen. Matkojesi tallennus pysähtyy kunnes avaat Sparkilon uudelleen.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Kun iOS pyytää \"Aina\"-sijaintia, sano kyllä.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Varajärjestelmä, joka tallentaa matkasi kun OBD2-sovitin on hidas, tarvitsee taustasijainnin. Emme koskaan jaa sitä.';

  @override
  String get scanReceipt => 'Skannaa kuitti';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Polttoaine';

  @override
  String get stationTypeEv => 'Sähköauto';

  @override
  String get brandFilterHighway => 'Moottoritie';

  @override
  String get ratingModeLocal => 'Paikallinen';

  @override
  String get ratingModePrivate => 'Yksityinen';

  @override
  String get ratingModeShared => 'Jaettu';

  @override
  String get ratingDescLocal => 'Arvostelut tallennettu vain tälle laitteelle';

  @override
  String get ratingDescPrivate =>
      'Synkronoitu tietokantasi kanssa (ei näkyvissä muille)';

  @override
  String get ratingDescShared => 'Näkyvissä kaikille tietokantasi käyttäjille';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API-avain ei ole määritetty. Lisää se Asetuksissa etsiäksesi sähköautojen latauspisteitä.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Tietopalveluntarjoaja ($host) käyttää vanhentunutta tai virheellistä TLS-sertifikaattia. Sovellus ei voi ladata tietoja tästä lähteestä ennen kuin palveluntarjoaja korjaa sen. Ota yhteyttä $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed ei käytettävissä. Käytetään $current.';
  }

  @override
  String get errorTitleApiKey => 'API-avain vaaditaan';

  @override
  String get errorTitleLocation => 'Sijainti ei käytettävissä';

  @override
  String get errorHintNoStations =>
      'Kokeile kasvattaa hakusädettä tai hae eri sijainnista.';

  @override
  String get errorHintApiKey => 'Määritä API-avaimesi Asetuksissa.';

  @override
  String get errorHintConnection =>
      'Tarkista internet-yhteys ja yritä uudelleen.';

  @override
  String get errorHintRouting =>
      'Reittilaskenta epäonnistui. Tarkista internet-yhteys ja yritä uudelleen.';

  @override
  String get errorHintFallback =>
      'Yritä uudelleen tai hae postinumerolla tai kaupungin nimellä.';

  @override
  String get alertsLoadErrorTitle => 'Hälytysten lataaminen epäonnistui';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Hälytysten taustatarkistus epäonnistui';

  @override
  String get detailsLabel => 'Tiedot';

  @override
  String get remove => 'Poista';

  @override
  String get showKey => 'Näytä avain';

  @override
  String get hideKey => 'Piilota avain';

  @override
  String get syncOptionalTitle => 'TankSync on valinnainen';

  @override
  String get syncOptionalDescription =>
      'Sovellus toimii täysin ilman pilvisynkronointia. TankSync mahdollistaa suosikkien, hälytysten ja arvostelujen synkronoinnin laitteiden välillä Supabase-palvelun avulla (ilmainen taso saatavilla).';

  @override
  String get syncHowToConnectQuestion => 'Miten haluaisit yhdistää?';

  @override
  String get syncCreateOwnTitle => 'Luo oma tietokanta';

  @override
  String get syncCreateOwnSubtitle =>
      'Ilmainen Supabase-projekti — opastamme sinua vaihe vaiheelta';

  @override
  String get syncJoinExistingTitle => 'Liity olemassa olevaan tietokantaan';

  @override
  String get syncJoinExistingSubtitle =>
      'Skannaa QR-koodi tietokannan omistajalta tai liitä tunnistetiedot';

  @override
  String get syncChooseAccountType => 'Valitse tilin tyyppi';

  @override
  String get syncAccountTypeAnonymous => 'Anonyymi';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Välitön, ei sähköpostia tarvita. Tiedot sidottu tähän laitteeseen.';

  @override
  String get syncAccountTypeEmail => 'Sähköpostitili';

  @override
  String get syncAccountTypeEmailDesc =>
      'Kirjaudu sisään mistä laitteesta tahansa. Palauta tiedot puhelimen katoamisen jälkeen.';

  @override
  String get syncHaveAccountSignIn => 'Onko sinulla jo tili? Kirjaudu sisään';

  @override
  String get syncCreateNewAccount => 'Luo uusi tili';

  @override
  String get syncTestConnection => 'Testaa yhteys';

  @override
  String get syncTestingConnection => 'Testataan...';

  @override
  String get syncConnectButton => 'Yhdistä';

  @override
  String get syncConnectingButton => 'Yhdistetään...';

  @override
  String get syncDatabaseReady => 'Tietokanta valmis!';

  @override
  String get syncDatabaseNeedsSetup => 'Tietokanta tarvitsee määrityksen';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Puuttuu';

  @override
  String get syncSqlEditorInstructions =>
      'Kopioi alla oleva SQL ja aja se Supabase SQL-editorissa (Kojelauta → SQL Editor → Uusi kysely → Liitä → Aja)';

  @override
  String get syncCopySqlButton => 'Kopioi SQL leikepöydälle';

  @override
  String get syncRecheckSchemaButton => 'Tarkista skeema uudelleen';

  @override
  String get syncDoneButton => 'Valmis';

  @override
  String syncSignedInAs(String email) {
    return 'Kirjautunut: $email';
  }

  @override
  String get syncEmailDescription =>
      'Tietosi synkronoituvat kaikille laitteille tällä sähköpostilla.';

  @override
  String get syncSwitchToAnonymousTitle => 'Vaihda anonyymiksi';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Jatka ilman sähköpostia, uusi anonyymi istunto';

  @override
  String get syncGuestDescription => 'Anonyymi, ei sähköpostia tarvita.';

  @override
  String get syncOrDivider => 'tai';

  @override
  String get syncHowToSyncQuestion => 'Miten haluaisit synkronoida?';

  @override
  String get syncOfflineDescription =>
      'Sovelluksesi toimii täysin offline-tilassa. Pilvisynkronointi on valinnainen.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo-yhteisö';

  @override
  String get syncModeCommunitySubtitle =>
      'Jaa suosikit ja arvostelut kaikkien käyttäjien kanssa';

  @override
  String get syncModePrivateTitle => 'Yksityinen tietokanta';

  @override
  String get syncModePrivateSubtitle =>
      'Oma Supabase — täysi hallinta tietoihin';

  @override
  String get syncModeGroupTitle => 'Liity ryhmään';

  @override
  String get syncModeGroupSubtitle =>
      'Perhe tai ystävät jaetulla tietokannalla';

  @override
  String get syncPrivacyShared => 'Jaettu';

  @override
  String get syncPrivacyPrivate => 'Yksityinen';

  @override
  String get syncPrivacyGroup => 'Ryhmä';

  @override
  String get syncStayOfflineButton => 'Pysy offline-tilassa';

  @override
  String get syncSuccessTitle => 'Yhdistäminen onnistui!';

  @override
  String get syncSuccessDescription =>
      'Tietosi synkronoituvat nyt automaattisesti.';

  @override
  String get syncWizardTitleConnect => 'Yhdistä TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Tietokantasi';

  @override
  String get syncSetupTitleJoinGroup => 'Liity ryhmään';

  @override
  String get syncSetupTitleAccount => 'Tilisi';

  @override
  String get syncWizardBack => 'Takaisin';

  @override
  String get syncWizardNext => 'Seuraava';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Vaihe $current/$total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Luo Supabase-projekti';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Napauta alla olevaa \"Avaa Supabase\"\n2. Luo ilmainen tili (jos sinulla ei ole sitä)\n3. Klikkaa \"New Project\"\n4. Valitse nimi ja alue\n5. Odota ~2 minuuttia sen käynnistymistä';

  @override
  String get syncWizardOpenSupabase => 'Avaa Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Ota anonyymi kirjautuminen käyttöön';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Supabase-kojelaudassasi:\n   Authentication → Providers\n2. Etsi \"Anonymous Sign-ins\"\n3. Kytke se PÄÄLLE\n4. Klikkaa \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Avaa todennusasetukset';

  @override
  String get syncWizardCopyCredentialsTitle => 'Kopioi tunnistetiedot';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Mene kojelaudassasi Settings → API\n2. Kopioi \"Project URL\"\n3. Kopioi \"anon public\" -avain\n4. Liitä ne alle';

  @override
  String get syncWizardOpenApiSettings => 'Avaa API-asetukset';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Liity olemassa olevaan tietokantaan';

  @override
  String get syncWizardScanQrCode => 'Skannaa QR-koodi';

  @override
  String get syncWizardAskOwnerQr =>
      'Pyydä tietokannan omistajaa näyttämään QR-koodi\n(Asetukset → TankSync → Jaa)';

  @override
  String get syncWizardAskOwnerQrShort => 'Pyydä omistajaa näyttämään QR-koodi';

  @override
  String get syncWizardEnterManuallyTitle => 'Syötä manuaalisesti';

  @override
  String get syncWizardOrEnterManually => 'tai syötä manuaalisesti';

  @override
  String get syncWizardUrlHelperText =>
      'Välilyönnit ja rivinvaihdot poistetaan automaattisesti';

  @override
  String get syncCredentialsPrivateHint =>
      'Anna Supabase-projektisi tunnistetiedot. Löydät ne kojelaudastasi kohdasta Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Tietokannan URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Pääsyavain';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Sähköposti';

  @override
  String get authPasswordLabel => 'Salasana';

  @override
  String get authConfirmPasswordLabel => 'Vahvista salasana';

  @override
  String get authPleaseEnterEmail => 'Anna sähköpostiosoitteesi';

  @override
  String get authInvalidEmail => 'Virheellinen sähköpostiosoite';

  @override
  String get authPasswordsDoNotMatch => 'Salasanat eivät täsmää';

  @override
  String get authConnectAnonymously => 'Yhdistä anonyymisti';

  @override
  String get authCreateAccountAndConnect => 'Luo tili ja yhdistä';

  @override
  String get authSignInAndConnect => 'Kirjaudu sisään ja yhdistä';

  @override
  String get authAnonymousSegment => 'Anonyymi';

  @override
  String get authEmailSegment => 'Sähköposti';

  @override
  String get authAnonymousDescription =>
      'Välitön pääsy, ei sähköpostia tarvita. Tiedot sidottu tähän laitteeseen.';

  @override
  String get authEmailDescription =>
      'Kirjaudu sisään mistä laitteesta tahansa. Palauta tietosi puhelimen katoamisen jälkeen.';

  @override
  String get authSyncAcrossDevices =>
      'Synkronoi tiedot automaattisesti kaikilla laitteillasi.';

  @override
  String get authNewHereCreateAccount => 'Uusi käyttäjä? Luo tili';

  @override
  String get linkDeviceScreenTitle => 'Linkitä laite';

  @override
  String get linkDeviceThisDeviceLabel => 'Tämä laite';

  @override
  String get linkDeviceShareCodeHint => 'Jaa tämä koodi toiselle laitteellesi:';

  @override
  String get linkDeviceNotConnected => 'Ei yhdistetty';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopioi koodi';

  @override
  String get linkDeviceImportSectionTitle => 'Tuo toisesta laitteesta';

  @override
  String get linkDeviceImportDescription =>
      'Anna toisen laitteesi laitekoodi tuodaksesi sen suosikit, hälytykset, ajoneuvot ja kulutuskirjanpidon. Kukin laite säilyttää oman profiilинsa ja oletuksensa.';

  @override
  String get linkDeviceCodeFieldLabel => 'Laitekoodi';

  @override
  String get linkDeviceCodeFieldHint => 'Liitä UUID toiselta laitteelta';

  @override
  String get linkDeviceImportButton => 'Tuo tiedot';

  @override
  String get linkDeviceHowItWorksTitle => 'Miten se toimii';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Laitteella A: kopioi yllä oleva laitekoodi\n2. Laitteella B: liitä se \"Laitekoodi\"-kenttään\n3. Napauta \"Tuo tiedot\" yhdistääksesi suosikit, hälytykset, ajoneuvot ja kulutuslokit\n4. Molemmilla laitteilla on kaikki yhdistetyt tiedot\n\nKukin laite säilyttää oman anonyymiidentiteettinsä ja oman profiilинsa (ensisijainen polttoaine, oletusajoneuvo, aloitusnäyttö). Tiedot yhdistetään, ei siirretä.';

  @override
  String get vehicleSetActive => 'Aseta aktiiviseksi';

  @override
  String get swipeHide => 'Piilota';

  @override
  String get evChargingSection => 'Sähköautojen lataus';

  @override
  String get fuelStationsSection => 'Polttoaineasema';

  @override
  String get yourRating => 'Arvostelusi';

  @override
  String get noStorageUsed => 'Ei tallennustilaa käytetty';

  @override
  String get aboutReportBug => 'Ilmoita virheestä / Ehdota ominaisuutta';

  @override
  String get aboutSupportProject => 'Tue tätä projektia';

  @override
  String get aboutSupportDescription =>
      'Tämä sovellus on ilmainen, avoimen lähdekoodin eikä siinä ole mainoksia. Jos pidät siitä hyödyllisenä, harkitse kehittäjän tukemista.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxemburgin polttoainehinnat ovat valtion sääntelemiä ja yhtenäiset koko maassa.';

  @override
  String get luxembourgFuelUnleaded95 => 'Lyijytön 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Lyijytön 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxemburgin säännellyt hinnat eivät ole saatavilla.';

  @override
  String get reportIssueTitle => 'Ilmoita ongelmasta';

  @override
  String get enterCorrection => 'Anna korjaus';

  @override
  String get reportNoBackendAvailable =>
      'Raporttia ei voitu lähettää: tälle maalle ei ole määritetty raportointipalvelua. Ota TankSync käyttöön Asetuksissa lähettääksesi yhteisöraportteja.';

  @override
  String get correctName => 'Oikea aseman nimi';

  @override
  String get correctAddress => 'Oikea osoite';

  @override
  String get wrongE85Price => 'Virheellinen E85-hinta';

  @override
  String get wrongE98Price => 'Virheellinen Super 98 -hinta';

  @override
  String get wrongLpgPrice => 'Virheellinen LPG-hinta';

  @override
  String get wrongStationName => 'Virheellinen aseman nimi';

  @override
  String get wrongStationAddress => 'Virheellinen osoite';

  @override
  String get independentStation => 'Riippumaton asema';

  @override
  String get serviceRemindersSection => 'Huoltоmuistutukset';

  @override
  String get serviceRemindersEmpty =>
      'Ei vielä muistutuksia — valitse esiasetus yllä.';

  @override
  String get addServiceReminder => 'Lisää muistutus';

  @override
  String get serviceReminderPresetOil => 'Öljy (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Öljynvaihto';

  @override
  String get serviceReminderPresetTires => 'Renkaat (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Renkaat';

  @override
  String get serviceReminderPresetInspection => 'Katsastus (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Katsastus';

  @override
  String get serviceReminderLabel => 'Nimike';

  @override
  String get serviceReminderInterval => 'Välimatka (km)';

  @override
  String get serviceReminderLastService => 'Viimeisin huolto';

  @override
  String get serviceReminderMarkDone => 'Merkitse tehdyksi';

  @override
  String get serviceReminderDueTitle => 'Huolto erääntynyt';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label on erääntynyt — $kmOver km yli välimatkan.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Rekisteröidy OPINETissä saadaksesi ilmaisen API-avaimen';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Rekisteröidy CNE:ssä saadaksesi ilmaisen API-avaimen';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Onko tämä autosi?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-syl, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Osittaiset tiedot (offline). Voit muokata alla.';

  @override
  String get vinDecodeError => 'VIN-koodia ei voitu purkaa';

  @override
  String get vinInvalidFormat => 'Virheellinen VIN-muoto';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2-yhteys katkesi — tallennus keskeytetty';

  @override
  String get obd2PauseBannerResume => 'Jatka tallennusta';

  @override
  String get obd2PauseBannerEnd => 'Lopeta tallennus';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Kulutuskalibrointi päivitetty ajoneuvolle $vehicleName — tarkkuus parani $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Nollatako tilavuushyötysuhde?';

  @override
  String get veResetConfirmBody =>
      'Tämä hylkää opitun tilavuushyötysuhteen (η_v) ja palauttaa oletusarvon (0,85). Matkakohtaiset polttoainevirta-arviot palaavat valmistajan vakioon kunnes kalibraattori kerää uusia näytteitä tulevista matkoista.';

  @override
  String get alertsRadiusSectionTitle => 'Säde-hälytykset';

  @override
  String get alertsRadiusAdd => 'Lisää säde-hälytys';

  @override
  String get alertsRadiusEmptyTitle => 'Ei vielä säde-hälytyksiä';

  @override
  String get alertsRadiusEmptyCta => 'Luo säde-hälytys';

  @override
  String get alertsRadiusCreateTitle => 'Luo säde-hälytys';

  @override
  String get alertsRadiusLabelHint => 'Nimike (esim. Koti diesel)';

  @override
  String get alertsRadiusFuelType => 'Polttoainetyyppi';

  @override
  String get alertsRadiusThreshold => 'Raja (€/L)';

  @override
  String get alertsRadiusKm => 'Säde (km)';

  @override
  String get alertsRadiusCenterGps => 'Käytä sijaintiasi';

  @override
  String get alertsRadiusCenterPostalCode => 'Postinumero';

  @override
  String get alertsRadiusSave => 'Tallenna';

  @override
  String get alertsRadiusCancel => 'Peruuta';

  @override
  String get alertsRadiusDeleteConfirm => 'Poistetaanko säde-hälytys?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 yhdistetty: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Paritetaan OBD2-sovitin';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel laski lähellä olevilla asemilla';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount asemalla hinta laski jopa $maxDropCents ¢ viimeisen tunnin aikana';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankkaus tallennettu';

  @override
  String get radiusAlertsEntryTitle => 'Säde-hälytykset ja tilastot';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Saat ilmoituksen kun hinnat laskevat lähellä sinua';

  @override
  String get notFoundTitle => 'Sivua ei löydy';

  @override
  String notFoundBody(String location) {
    return '\"$location\" ei löydy.';
  }

  @override
  String get notFoundHomeButton => 'Etusivu';

  @override
  String get consumptionTabHiddenNotice =>
      'Kulutus-välilehti on piilotettu profiiliasetuksillasi.';

  @override
  String get swipeBetweenTabsHint =>
      'Vinkki: vaihda välilehtien välillä pyyhkäisemällä vasemmalle tai oikealle.';

  @override
  String get discardChangesTitle => 'Hylätäänkö muutokset?';

  @override
  String get discardChangesBody =>
      'Sinulla on tallentamattomia muutoksia. Poistuminen nyt hylkää ne.';

  @override
  String get discardChangesConfirm => 'Hylkää';

  @override
  String get discardChangesKeepEditing => 'Jatka muokkaamista';

  @override
  String get tankSyncSectionSubtitle => 'Pilvisynkronointi laitteidesi välillä';

  @override
  String get mapUnavailable => 'Kartta ei käytettävissä';

  @override
  String get routeNameHintExample => 'esim. Pariisi → Lyon';

  @override
  String get priceStatsCurrent => 'Nykyinen';

  @override
  String get tankerkoenigApiKeyLabel => 'Tankerkoenig-API-avain';

  @override
  String get openChargeMapApiKeyLabel => 'OpenChargeMap-API-avain';

  @override
  String get tapToUpdateGpsPosition => 'Päivitä GPS-sijainti napauttamalla';

  @override
  String get nameLabel => 'Nimi';

  @override
  String get obd2ErrorPermissionDenied =>
      'OBD2-sovittimeen yhdistäminen edellyttää Bluetooth-lupaa.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Ota Bluetooth käyttöön ja yritä uudelleen.';

  @override
  String get obd2ErrorScanTimeout =>
      'Lähistöltä ei löytynyt OBD2-sovitinta. Varmista, että se on kytkettynä ja päällä.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2-sovitin ei vastannut. Kytke virta päälle ja yritä uudelleen.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2-sovitin lähetti tunnistamattoman vastauksen. Se voi olla yhteensopimaton — kokeile toista sovitinta.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2-sovittimen yhteys katkesi. Yhdistä uudelleen ja yritä uudelleen.';

  @override
  String get onboardingExploreDemoData => 'Tutustu esittelytiedoilla';

  @override
  String get achievementSmoothDriver => 'Tasainen putki';

  @override
  String get achievementSmoothDriverDesc =>
      'Aja 5 peräkkäistä matkaa tasaisen ajon pisteet 80 tai enemmän.';

  @override
  String get achievementColdStartAware => 'Kylmäkäynnistystietoinen';

  @override
  String get achievementColdStartAwareDesc =>
      'Pidä koko kuukauden kylmäkäynnistyksen polttoainekustannus alle 2 % kokonaispolttoaineesta — yhdistä lyhyet matkat.';

  @override
  String get achievementHighwayMaster => 'Moottoritieammattilainen';

  @override
  String get achievementHighwayMasterDesc =>
      'Suorita vähintään 30 km matka tasaisella nopeudella ja tasaisen ajon pisteet 90 tai enemmän.';

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
    return '$price $currency (tavoite: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel laski lähistön asemilla';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count asemaa laski jopa $cents¢ viimeisen tunnin aikana';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count asemaa ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count lisää';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Taustahintahälytykset toimivat tällä hetkellä vain Saksan huoltoasemilla. Tämä hälytys tallennetaan, mutta se ei välttämättä ilmoita sinulle ennen kuin maiden väliset hälytykset ovat käytettävissä.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Sädehälytykset tarkistavat tällä hetkellä vain Saksan huoltoasemat.';

  @override
  String get approachOverlaySection => 'Aseman lähestymisilmoitus';

  @override
  String get approachRadiusLabel => 'Säde';

  @override
  String approachRadiusCaption(String km) {
    return 'Ilmoitus suurenee ja näyttää hinnan, kun olet alle $km km päässä huoltoasemasta';
  }

  @override
  String get approachPriceModeLabel => 'Näytä hinta';

  @override
  String get approachPriceModeNearest => 'Lähin asema';

  @override
  String get approachPriceModeCheapestInRadius => 'Halvin säteen sisällä';

  @override
  String get approachMinPollLabel => 'Päivitysväli vähint.';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Lähimmän aseman päivitysvälin alaraja (nopeampi suuremmilla nopeuksilla, ei koskaan tiheämmin kuin $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testaa lähestymispeitto';

  @override
  String get approachTestStopButton => 'Pysäytä testi';

  @override
  String approachTestActiveCaption(String station) {
    return 'Testi aktiivinen — peitto näyttää hinnan asemalle $station';
  }

  @override
  String get approachTestUnavailable =>
      'Lisää suosikkiasema testataksesi lähestymispeittoa';

  @override
  String approachStationDistance(String meters) {
    return '$meters m päässä';
  }

  @override
  String get authErrorNoNetwork =>
      'Ei verkkoyhteyttä. Yritä myöhemmin uudelleen.';

  @override
  String get authErrorInvalidCredentials =>
      'Virheellinen sähköposti tai salasana. Tarkista tunnistetietosi.';

  @override
  String get authErrorUserAlreadyExists =>
      'Tämä sähköpostiosoite on jo rekisteröity. Kokeile kirjautua sisään.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Tarkista sähköpostisi ja vahvista tilisi ensin.';

  @override
  String get authErrorGeneric => 'Kirjautuminen epäonnistui. Yritä uudelleen.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Taustanäkymäsijainti — vain automaattiseen tallennukseen';

  @override
  String get autoRecordConsentExplanationTitle => 'Tietoa tästä luvasta';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automaattinen tallennus tarvitsee taustasijainnin havaitakseen ajon aloituksen sovelluksen ollessa suljettu. Tätä lupaa käytetään vain automaattiseen tallennukseen — asemahaku ja kartan keskittäminen käyttävät erillistä etusijainnin lupaa.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Selvä';

  @override
  String get autoRecordConsentExplanationTooltip => 'Mitä tämä tarkoittaa?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Napauta hallitaksesi järjestelmäasetuksissa';

  @override
  String get autoRecordSectionTitle => 'Automaattinen tallennus';

  @override
  String get autoRecordToggleLabel => 'Tallenna matkat automaattisesti';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automaattinen tallennus aktivoituu seuraavan kerran kun menet autoon.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Paritetaan OBD2-sovitin automaattisen tallennuksen käyttöönottoon.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Salli taustasijainti jotta automaattinen tallennus toimii näytön ollessa pois päältä.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Paritetaan sovitin';

  @override
  String get autoRecordSpeedThresholdLabel => 'Aloitusnopeus (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Tallennusviive yhteyden katkaistua (sekuntia)';

  @override
  String get autoRecordPairedAdapterLabel => 'Paritettu sovitin';

  @override
  String get autoRecordPairedAdapterNone =>
      'Ei paritettu sovitinta. Paritetaan ensin OBD2-perehdytyksen kautta.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Taustanäkymäsijainti sallittu';

  @override
  String get autoRecordBackgroundLocationRequest => 'Pyydä lupaa';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Miksi \"Aina sallittu\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automaattinen tallennus virtaa GPS-koordinaatteja OBD-II:n etualustan palvelusta näytön ollessa pois päältä, jotta matkareittiisi pysyy tarkkana. Android vaatii \"Aina sallittu\" -vaihtoehdon jotta se toimii laitteen lukittua.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Avaa asetukset';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Sijaintilupa vaaditaan';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Taustasijainnin pyytäminen epäonnistui';

  @override
  String get autoRecordBadgeClearTooltip => 'Tyhjennä laskuri';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Paritetaan sovitin alla olevassa osiossa automaattisen tallennuksen ottamiseksi käyttöön';

  @override
  String get exportBackupTooltip => 'Vie varmuuskopio';

  @override
  String get exportBackupReady => 'Varmuuskopio valmis — valitse kohde';

  @override
  String get exportBackupFailed =>
      'Varmuuskopion vienti epäonnistui — yritä uudelleen';

  @override
  String get brokenMapChipVerifying => 'MAP-anturi tarkistaa…';

  @override
  String get brokenMapChipDisclaimer => 'MAP-lukema epäilyttävä';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP-anturi lukee väärin — polttoainelukemat voivat olla 50–80 % liian pienet. Kokeile eri sovitinta.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP-anturi epäluotettava. Näytetään tankkauskeskiarvot live-polttoaineprosentin sijaan.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP-anturi: tarkistettu ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP-anturi: tarkistetaan ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP-anturi: epäilyttävä ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP-anturi: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP-anturi: $posterior% ± $margin% (tarkistettu)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'MAP-anturin diagnostiikka';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Rikkinäinen MAP-luottamus: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count havaintoa tallennettu';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Tarkistettu puhtaaksi';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Tämän ajoneuvon MAP-anturia ei ole vielä havaittu.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Estetyt sovitimet';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Ei estettyjä sovittimia.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — merkitty $percent% rikkinäiseksi';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Tyhjennä';

  @override
  String get brokenMapRevPromptTitle => 'Kaasuta moottori';

  @override
  String get brokenMapRevPromptBody =>
      'Paina lyhyesti kaasua jotta sovellus voi tarkistaa MAP-anturin reagoinnin.';

  @override
  String get brokenMapRevPromptConfirm => 'Valmis — kaasutus tehty';

  @override
  String get calibrationAdvancedTitle => 'Edistynyt kalibrointi';

  @override
  String get calibrationDisplacementLabel => 'Moottorin tilavuus (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel => 'Tilavuushyötysuhde (η_v)';

  @override
  String get calibrationAfrLabel => 'Ilma-polttoainesuhde (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Polttoaineen tiheys (g/L)';

  @override
  String get calibrationSourceDetected => '(havaittu VIN:stä)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalogi: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(oletus)';

  @override
  String get calibrationSourceManual => '(manuaalinen)';

  @override
  String get calibrationResetToDetected => 'Nollaa havaittuun arvoon';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (kalibroitu, $samples näytettä)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (oppii, $samples näytettä)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (oletus — ei plein-complet-tankkausta vielä)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples näytettä';
  }

  @override
  String get calibrationResetLearner => 'Nollaa oppija';

  @override
  String get calibrationBasisAtkinson => 'Atkinson-sykli';

  @override
  String get calibrationBasisVnt => 'VNT-diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turboahdettu + DI';

  @override
  String get calibrationBasisTurbo => 'Turboahdettu';

  @override
  String get calibrationBasisNaDi => 'Luonnollisesti imuttu + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalogi: $makeModel — $basis oletus)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return '$makeModel on merkitty dieseliksi mutta vastaa bensiinimerkinnän katalogiin. Napauta päivittääksesi.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Päivitä';

  @override
  String get consumptionTabFuel => 'Polttoaine';

  @override
  String get consumptionTabCharging => 'Lataus';

  @override
  String get noChargingLogsTitle => 'Ei vielä latauslokeja';

  @override
  String get noChargingLogsSubtitle =>
      'Kirjaa ensimmäinen lataustilaisuutesi aloittaaksesi EUR/100 km ja kWh/100 km seurannan.';

  @override
  String get addChargingLog => 'Kirjaa lataus';

  @override
  String get addChargingLogTitle => 'Kirjaa lataustilaisuus';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Kokonaiskustannus';

  @override
  String get chargingTimeMin => 'Latausaika (min)';

  @override
  String get chargingStationName => 'Asema (valinnainen)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Tarvitaan aiempi loki vertailuun';

  @override
  String get chargingLogButtonLabel => 'Kirjaa lataus';

  @override
  String get chargingCostTrendTitle => 'Latauskulujen kehitys';

  @override
  String get chargingEfficiencyTitle => 'Tehokkuus (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Ei vielä riittävästi tietoja';

  @override
  String get chargingChartsMonthAxis => 'Kuukausi';

  @override
  String get consoFeatureGroupTitle => 'Kulutus';

  @override
  String get consoFeatureGroupDescription =>
      'Seuraa kulutustasi — manuaaliset tankkaukset tai automaattinen OBD2-matkojen tallennus.';

  @override
  String get consoModeOff => 'Pois';

  @override
  String get consoModeFuel => 'Polttoaine';

  @override
  String get consoModeFuelAndTrips => 'Polttoaine + Matkat';

  @override
  String get consoModeOffDescription =>
      'Ei Kulutus-välilehteä eikä Kulutus-asetusosioita.';

  @override
  String get consoModeFuelDescription =>
      'Vain manuaaliset tankkaukset. Hyödyllinen ilman OBD2-sovitinta.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Lisää automaattinen OBD2-matkojen tallennus. Vaatii paritetun sovittimen.';

  @override
  String get consoSubsectionVehicles => 'Omat ajoneuvot';

  @override
  String get consoSubsectionTrajets => 'Matkat (OBD2)';

  @override
  String get consoSubsectionToggles => 'Ajaminen';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Tarkkuus: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Korkea';

  @override
  String get consumptionAccuracyMedium => 'Keskitaso';

  @override
  String get consumptionAccuracyLow => 'Matala';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Täysi kalibrointi: tankkaukset sekä OBD2:lla tallennetut matkat. L/100 km -luku vastaa todellisuutta muutaman prosentin tarkkuudella.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankkaukset ovat ankkuroineet kulutusmallin, mutta yhtäkään OBD2-matkaa ei ole vielä syötetty. Tallenna yksi OBD2 yhdistettynä saavuttaaksesi korkean tarkkuuden.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Vain GPS — yksikään tankkaus ei ole vielä ankkuroinut kulutusmallia. Lisää pari täyttä tankkausta parantaaksesi tarkkuutta.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count osittaista tankkausta odottaa plein complet — ei mukana keskiarvossa',
      one:
          '1 osittainen tankkaus odottaa plein complet — ei mukana keskiarvossa',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% polttoaineesta automaattikorjauksista — tarkista merkinnät';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Automaattikorjaus — napauta muokataksesi';

  @override
  String get fillUpCorrectionEditTitle => 'Muokkaa automaattikorjausta';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Tämä merkintä luotiin automaattisesti kuromaan umpeen tallennettujen matkojen ja pumpatun polttoaineen välinen ero. Muuta arvoja jos tiedät todelliset luvut.';

  @override
  String get fillUpCorrectionDelete => 'Poista korjaus';

  @override
  String get fillUpCorrectionStation => 'Aseman nimi (valinnainen)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Kreikka)';

  @override
  String get greeceCommunityApiNotice => 'Yhteisön ylläpitämä fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Toteutettu pretcarburant.ro:n avulla (kilpailuneuvosto + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return '$country:n asemat $km km päässä — €$price/L halvempi';
  }

  @override
  String get crossBorderTapToSwitch => 'Napauta vaihtaaksesi maata';

  @override
  String get crossBorderDismissTooltip => 'Sulje';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Kehittäjätyökalut';

  @override
  String get developerToolsSubtitle =>
      'Diagnostiikka ja virheenkorjaustyökalut — näkyvät vain kehittäjä-/virheenkorjaustilassa.';

  @override
  String get developerToolsMenuSubtitle =>
      'Virheloki, testihälytykset, diagnostiikka';

  @override
  String get developerToolsErrorLogGroupTitle => 'Virheloki';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Tallenna virheloki ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Tyhjennä virheloki';

  @override
  String get developerToolsViewErrorLog => 'Näytä virheloki';

  @override
  String get developerToolsErrorLogEmpty => 'Virhejälkiä ei ole tallennettu.';

  @override
  String get developerToolsAlertsGroupTitle => 'Hälytykset ja ilmoitukset';

  @override
  String get developerToolsFireTestNotification => 'Lähetä testi-ilmoitus';

  @override
  String get developerToolsTestNotificationTitle => 'Testi-ilmoitus';

  @override
  String get developerToolsTestNotificationBody =>
      'Jos voit lukea tämän, ilmoitukset toimivat.';

  @override
  String get developerToolsTestNotificationSent => 'Testi-ilmoitus lähetetty.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Ilmoitukset on estetty — ota ne käyttöön järjestelmäasetuksissa ja yritä uudelleen.';

  @override
  String get developerToolsRunTestAlert => 'Suorita testihälytysputki';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Testihälytys laukaistu — putki toimitti $count ilmoitusta.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testihintahälytys';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Synteettinen osuma: lähistöltä löytyi tavoitettasi halvempi asema.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostiikka';

  @override
  String get developerToolsFeatureFlagDump => 'Ominaisuuslippujen tarkastelu';

  @override
  String get developerToolsFlagOn => 'Päällä';

  @override
  String get developerToolsFlagOff => 'Pois';

  @override
  String get developerToolsClearCaches => 'Tyhjennä välimuistit';

  @override
  String get developerToolsCachesCleared => 'Välimuistit tyhjennetty.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopioi diagnostiikka';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnostiikka kopioitu leikepöydälle.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Koontitiedot';

  @override
  String get developerToolsBuildVersion => 'Sovelluksen versio';

  @override
  String get developerToolsBuildChannel => 'Koontikanava';

  @override
  String get insightCardTitle => 'Pahimmat tuhlaukset';

  @override
  String get insightEmptyState =>
      'Ei merkittäviä tehottomuuksia — jatka samaan tapaan!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Moottori yli 3000 RPM ($pctTime% matkasta): hukattu $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count voimakasta kiihdytystä: hukattu $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Tyhjäkäynti ($pctTime% matkasta): hukattu $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% matkasta';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Kynsi alhaisella vaihteella ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Sammuta moottori pitkien pysähdysten ajaksi sen sijaan, että annat sen käydä tyhjäkäynnillä.';

  @override
  String get lessonAdviceHighRpm =>
      'Vaihda aiemmin suuremmalle vaihteelle pitääksesi moottorin pois korkean kierrosluvun alueelta.';

  @override
  String get lessonAdviceHardAccel =>
      'Paina kaasua pehmeästi — tasainen kiihdytys kuluttaa vähemmän polttoainetta.';

  @override
  String get lessonAdviceLowGear =>
      'Vaihda aiemmin suuremmalle, jotta moottori asettuu matalammille ja taloudellisemmille kierroksille.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Jatkuva suuri nopeus ($pctTime % matkasta): hukattu $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Jatkuva suuri nopeus ($pctTime % matkasta)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Päästä kaasusta yli 110 km/h – ilmanvastus kasvaa jyrkästi, joten hieman hitaammin säästää paljon polttoainetta.';

  @override
  String get lessonSmoothDrivingTitle => 'Tasaista ajoa – hyvin tehty!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Ei rajuja kiihdytyksiä tai jarrutuksia tällä matkalla – tasainen ajo pitää kulutuksen alhaisena.';

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
  String get drivingScoreCardTitle => 'Ajopisteet';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Yhdistelmäpisteet tyhjäkäynnistä, voimakkaista kiihdytyksistä, kovasta jarrutuksesta ja korkean RPM:n ajasta. \"Parempi kuin X% aiemmista matkoista\" -vertailu tulee seuraavassa julkaisussa.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Ajopisteet $score/100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Tyhjäkäynti';

  @override
  String get drivingScorePenaltyHardAccel => 'Voimakkaat kiihdytykset';

  @override
  String get drivingScorePenaltyHardBrake => 'Kova jarrutus';

  @override
  String get drivingScorePenaltyHighRpm => 'Korkea RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Täysi kaasu';

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
    return '≈ $liters L säästöä';
  }

  @override
  String get ecoRouteHint =>
      'Älykkäämpi ajo — suosii tasaista moottoritietä kiemurtelevien oikoteiden sijaan.';

  @override
  String get favoritesShareAction => 'Jaa';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — suosikit $date';
  }

  @override
  String get favoritesShareError => 'Jaettavan kuvan luominen epäonnistui';

  @override
  String get featureManagementSectionTitle => 'Ominaisuuksien hallinta';

  @override
  String get featureManagementSectionSubtitle =>
      'Ota yksittäisiä ominaisuuksia käyttöön tai poista ne. Jotkin ominaisuudet riippuvat muista — kytkimet ovat pois käytöstä kunnes edellytykset täyttyvät.';

  @override
  String get featureLabel_obd2TripRecording => 'OBD2-matkojen tallennus';

  @override
  String get featureDescription_obd2TripRecording =>
      'Tallenna matkat automaattisesti OBD2:n kautta.';

  @override
  String get featureLabel_gamification => 'Pelillistäminen';

  @override
  String get featureDescription_gamification =>
      'Ajopisteet ja ansaitut palkinnot.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptinen eko-valmentaja';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Reaaliaikainen haptinen palaute matkan aikana.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Laitteiden välinen synkronointi Supabasen kautta.';

  @override
  String get featureLabel_consumptionAnalytics => 'Kulutusanalytiikka';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Tankkaus- ja matka-analyysivälilehti.';

  @override
  String get featureLabel_baselineSync => 'Perusarvojen synkronointi';

  @override
  String get featureDescription_baselineSync =>
      'Synkronoi ajon perusarvot TankSyncin kautta.';

  @override
  String get featureLabel_unifiedSearchResults => 'Yhdistetyt hakutulokset';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Yksittäinen tulosluettelo yhdistellen polttoaine- ja sähköasemia.';

  @override
  String get featureLabel_priceAlerts => 'Hintahälytykset';

  @override
  String get featureDescription_priceAlerts =>
      'Rajapohjaiset hintamuutosilmoitukset.';

  @override
  String get featureLabel_priceHistory => 'Hintahistoria';

  @override
  String get featureDescription_priceHistory =>
      '30 päivän hintakäyrät aseman tiedoissa.';

  @override
  String get featureLabel_routePlanning => 'Reitin suunnittelu';

  @override
  String get featureDescription_routePlanning =>
      'Edullisin pysäkki reitillesi.';

  @override
  String get featureLabel_evCharging => 'Sähköautojen lataus';

  @override
  String get featureDescription_evCharging =>
      'Latausasemat OpenChargeMapin kautta.';

  @override
  String get featureLabel_glideCoach => 'Liukuluekovalmentaja';

  @override
  String get featureDescription_glideCoach =>
      'Hypermiling-ohjaus OSM-liikennevaloilla.';

  @override
  String get featureLabel_gpsTripPath => 'GPS-matkapolku';

  @override
  String get featureDescription_gpsTripPath =>
      'Tallenna GPS-polun näytteet jokaisen matkan yhteydessä.';

  @override
  String get featureLabel_autoRecord => 'Automaattinen tallennus';

  @override
  String get featureDescription_autoRecord =>
      'Aloita matka automaattisesti kun OBD2-sovitin yhdistää liikkuvaan ajoneuvoon.';

  @override
  String get featureLabel_showFuel => 'Näytä polttoaineasemia';

  @override
  String get featureDescription_showFuel =>
      'Näytä bensiini-/dieselasemia haussa ja kartalla.';

  @override
  String get featureLabel_showElectric => 'Näytä latauspisteitä';

  @override
  String get featureDescription_showElectric =>
      'Näytä sähköautojen latauspisteitä haussa ja kartalla.';

  @override
  String get featureLabel_showConsumptionTab => 'Kulutus-välilehti';

  @override
  String get featureDescription_showConsumptionTab =>
      'Näytä kulutusanalytiikkavälilehti alanavigaatiossa.';

  @override
  String get featureBlockedEnable_gamification =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureBlockedEnable_baselineSync => 'Ota ensin TankSync käyttöön';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureBlockedEnable_showFuel => 'Edellytykset eivät täyty';

  @override
  String get featureBlockedEnable_showElectric => 'Edellytykset eivät täyty';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite-hintaennuste';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Laitteella toimiva hintaennustemalli — päätelmät ajetaan paikallisesti; ominaisuudet ja ennusteet eivät koskaan poistu laitteelta.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Ota ensin hintahistoria käyttöön';

  @override
  String get featureLabel_fuelCalculator => 'Polttoainelaskin';

  @override
  String get featureDescription_fuelCalculator =>
      'Saavutettavissa oleva polttoainekustannuslaskin hakutuloksista.';

  @override
  String get featureLabel_carbonDashboard => 'Hiilijalanjälkinäkymä';

  @override
  String get featureDescription_carbonDashboard =>
      'CO2-jalanjälkinäkymä Kulutus-välilehdeltä saavutettavissa.';

  @override
  String get featureLabel_experimentalOemPids => 'Kokeelliset OEM-PID:t';

  @override
  String get featureDescription_experimentalOemPids =>
      'Lue tarkka tankin litramäärä valmistajan omien PID-koodien kautta tuetuilla sovittimilla.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Ota ensin OBD2-matkojen tallennus käyttöön';

  @override
  String get featureLabel_paymentQrScan => 'Skannaa maksu-QR';

  @override
  String get featureDescription_paymentQrScan =>
      'QR-maksujen lukija aseman tietosivulla.';

  @override
  String get featureLabel_communityPriceReports => 'Yhteisön hintaraportit';

  @override
  String get featureDescription_communityPriceReports =>
      'Ilmoita aseman hinta aseman tietosivulta.';

  @override
  String get featureLabel_obd2Optional => 'Vaadi OBD2 matkojen tallentamiseen';

  @override
  String get featureDescription_obd2Optional =>
      'Kun pois päältä, sovellus tallentaa matkoja vain GPS:llä ilman OBD2-sovitinta. Valmennus on rajallisempaa — ei välitöntä L/100 km, vähemmän moottorisignaaleja.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'Kuitin OCR';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Skannaa painettu kuitti Lisää tankkaus -näytöllä esitäyttääksesi päivämäärän, litrat, kokonaissumman ja aseman.';

  @override
  String get featureLabel_addFillUpOcrPump => 'Pumpun näytön OCR (kokeellinen)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Skannaa polttoainepumpun näyttö esitäyttääksesi lomakkeen. Tunnistus on epäluotettavaa tänään — aktivoi vain, jos haluat testata.';

  @override
  String get featureLabel_developerPatToken => 'Kehittäjäpalaute (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Ottaa käyttöön epäonnistuneiden skannausten palautepaneelin, joka luo automaattisesti GitHub-issueja Personal Access Tokenilla. Edistyneiden käyttäjien / avustajien ominaisuus.';

  @override
  String get featureLabel_debugMode => 'Kehittäjä-/virheenkorjaustila';

  @override
  String get featureDescription_debugMode =>
      'Näyttää asetuksissa Kehittäjätyökalut-osion, jossa on diagnostiikkaa: virhelokin vienti, testi-ilmoitukset, testihälytysputken suoritus, ominaisuuslippujen luettelo, välimuistien tyhjennys ja diagnostiikan kopiointi.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get feedbackConsentTitle => 'Lähetetäänkö raportti GitHubiin?';

  @override
  String get feedbackConsentBody =>
      'Tämä luo julkisen lipun GitHub-repositorioomme kuvasi ja OCR-tekstisi kanssa. Henkilötietoja (sijainti, tilin tunnus) ei lähetetä. Jatketaanko?';

  @override
  String get feedbackConsentContinue => 'Jatka';

  @override
  String get feedbackConsentCancel => 'Peruuta';

  @override
  String get feedbackConsentLater => 'Myöhemmin';

  @override
  String get feedbackTokenSectionTitle => 'Huono skannaus -palaute (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Avataksesi GitHub-liput automaattisesti epäonnistuneista skannauksista, liitä GitHub PAT (`public_repo`-laajuus tankstellen-repositorioon). Muutoin manuaalinen jakaminen on edelleen käytettävissä.';

  @override
  String get feedbackTokenStatusSet => 'Token määritetty';

  @override
  String get feedbackTokenStatusUnset => 'Ei tokenia';

  @override
  String get feedbackTokenSet => 'Aseta';

  @override
  String get feedbackTokenClear => 'Poista';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Henkilökohtainen pääsytoken';

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
  String get fillUpReconciliationVerifiedBadgeLabel => 'Sovittimen tarkistama';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Ei vastaa sovittimen lukemaa';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Merkintäsi: $userL L. Sovitin sanoo: $adapterL L (delta ennen/jälkeen polttoainetason mittauksen). Käytetäänkö sovittimen arvoa?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Pidä oma merkintäni';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Käytä sovittimen arvoa';

  @override
  String get scanReceiptNoData => 'Kuitista ei löydy tietoja — yritä uudelleen';

  @override
  String get scanReceiptSuccess =>
      'Kuitti skannattu — tarkista arvot. Napauta alla \"Ilmoita skannauksesta\" jos jokin on pielessä.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skannaus epäonnistui: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Pumpun näyttöä ei voida lukea — yritä uudelleen';

  @override
  String get scanPumpSuccess => 'Pumpun näyttö skannattu — tarkista arvot.';

  @override
  String get scanPumpGlare =>
      'Näytössä on liikaa heijastusta — yritä uudelleen hieman vinosta kulmasta, jotta numerot eivät pala puhki.';

  @override
  String scanPumpFailed(String error) {
    return 'Pumpun skannaus epäonnistui: $error';
  }

  @override
  String get badScanReportTitle => 'Ilmoita skannauksesta';

  @override
  String get badScanReportTitleReceipt => 'Ilmoita skannauksesta — Kuitti';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Ilmoita skannauksesta — Pumpun näyttö';

  @override
  String get pumpScanFailureTitle => 'Näyttöä ei voida lukea';

  @override
  String get pumpScanFailureBody =>
      'Skannaus ei voinut lukea pumpun näyttöä. Mitä haluaisit tehdä?';

  @override
  String get pumpScanFailureCorrectManually => 'Korjaa manuaalisesti';

  @override
  String get pumpScanFailureReport => 'Ilmoita';

  @override
  String get pumpScanFailureRemove => 'Poista kuva';

  @override
  String get badScanReportHint =>
      'Jaamme kuitin kuvan ja molemmat arvojoukot, jotta seuraava versio voi oppia tämän asettelun.';

  @override
  String get badScanReportShareAction => 'Jaa raportti + kuva';

  @override
  String get badScanReportFieldBrandLayout => 'Merkin asettelu';

  @override
  String get badScanReportFieldTotal => 'Yhteensä';

  @override
  String get badScanReportFieldPricePerLiter => 'Hinta/L';

  @override
  String get badScanReportFieldStation => 'Asema';

  @override
  String get badScanReportFieldFuel => 'Polttoaine';

  @override
  String get badScanReportFieldDate => 'Päivämäärä';

  @override
  String get badScanReportHeaderField => 'Kenttä';

  @override
  String get badScanReportHeaderScanned => 'Skannattu';

  @override
  String get badScanReportHeaderYouTyped => 'Kirjoitit';

  @override
  String get badScanReportCreateTicket => 'Luo ilmoitus';

  @override
  String get badScanReportOpenInBrowser => 'Avaa selaimessa';

  @override
  String get badScanReportFallbackToShare =>
      'Lähetys epäonnistui — manuaalinen jakaminen';

  @override
  String get pumpCameraHint =>
      'Aseta mittarin näytön kolme numeroa kehyksen sisään';

  @override
  String get pumpCameraCapture => 'Ota kuva';

  @override
  String get pumpCameraPermissionDenied =>
      'Kameran käyttöoikeus tarvitaan mittarin näytön skannaamiseen. Ota se käyttöön laitteen asetuksista.';

  @override
  String get pumpCameraError =>
      'Kameraa ei voitu käynnistää. Yritä uudelleen tai syötä arvot käsin.';

  @override
  String get pumpCameraOrientationHorizontal => 'Vaihda vaakaasetteluun';

  @override
  String get pumpCameraOrientationVertical => 'Vaihda pystyasetteluun';

  @override
  String get pumpCameraGlareWarning =>
      'Liikaa heijastusta — kallista hieman välttääksesi heijastukset';

  @override
  String get pumpCameraAlignHint =>
      'Kohdista näyttö kehykseen ja ota sitten kuva';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Mitä tankkasite';

  @override
  String get fillUpSectionWhatSubtitle => 'Polttoaine, määrä, hinta';

  @override
  String get fillUpSectionWhereTitle => 'Missä olitte';

  @override
  String get fillUpSectionWhereSubtitle => 'Asema, matkamittari, muistiinpanot';

  @override
  String get fillUpImportFromLabel => 'Tuo kohteesta…';

  @override
  String get fillUpImportSheetTitle => 'Tuo tankkauksen tiedot';

  @override
  String get fillUpImportReceiptLabel => 'Kuitti';

  @override
  String get fillUpImportReceiptDescription => 'Skannaa paperikuitti kameralla';

  @override
  String get fillUpImportPumpLabel => 'Pumpun näyttö';

  @override
  String get fillUpImportPumpDescription =>
      'Lue Betrag / Preis pumpun LCD-näytöltä';

  @override
  String get fillUpImportObdLabel => 'OBD-II-sovitin';

  @override
  String get fillUpImportObdDescription =>
      'Lue matkamittari OBD-II-portista Bluetoothin kautta';

  @override
  String get fillUpPricePerLiterLabel => 'Hinta litralta';

  @override
  String get vehicleHeaderPlateLabel => 'Rekisteri';

  @override
  String get vehicleHeaderUntitled => 'Uusi ajoneuvo';

  @override
  String get vehicleSectionIdentityTitle => 'Tunnistetiedot';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nimi ja VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Voimansiirto';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Miten ajoneuvo liikkuu';

  @override
  String get calibrationModeLabel => 'Kalibrointitapa';

  @override
  String get calibrationModeRule => 'Sääntöpohjainen';

  @override
  String get calibrationModeFuzzy => 'Sumea';

  @override
  String get calibrationModeTooltip =>
      'Sääntöpohjainen kohdistaa jokaisen ajonäytteen täsmälleen yhteen tilanteeseen. Sumea jakaa sen kaikkiin niiden sopivuuden mukaan — tasaisempi noin 60 km/h tai muuttuvissa gradienteissa, mutta täyttää kaikki ämpärit hitaammin.';

  @override
  String get profileGamificationToggleTitle => 'Näytä saavutukset ja pisteet';

  @override
  String get profileGamificationToggleSubtitle =>
      'Kun pois päältä, palkinnot, pisteet ja trofeekuvakkeet piilotetaan koko sovelluksesta.';

  @override
  String get coachingGpsLiftOff => 'Päästä kaasusta';

  @override
  String get coachingGpsAnticipateBrake => 'Ennakoi';

  @override
  String get coachingGpsSmoothAccel => 'Pehmeä kiihdytys';

  @override
  String get gpsDiagnosticsTitle => 'GPS-näytteenoton diagnostiikka';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps katkosta',
      one: '1 katkos',
      zero: 'ei katkoksia',
    );
    return '$count näytettä · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Mediaaniväli: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Kerätty tallennuksen aikana GPS-tahdin tarkistamiseksi puhelimen nukkuessa.';

  @override
  String get gpsMatrixMaturityCold => 'Kylmä';

  @override
  String get gpsMatrixMaturityWarming => 'Lämpenee';

  @override
  String get gpsMatrixMaturityConverged => 'Vakautunut';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS-matriisi vielä lämpenee ($count hienosäätöä toistaiseksi). Arviot ovat alustavia.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS-matriisi vakautuu ($count tankkausta). Arviot ovat käyttökelpoisia mutta voivat poiketa muutaman %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS-matriisi on vakautunut ($count tankkausta). Arviot ~2 %:n sisällä todellisesta kulutuksesta.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Ajaminen';

  @override
  String get hapticEcoCoachSettingTitle => 'Reaaliaikainen eko-valmennus';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Kevyt haptiikka + näyttövinkki kun poljet kaasun pohjaan tasaajossa';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Pehmeästi kaasulla — liuku säästää enemmän';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navigoi kohteeseen $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Poista $name suosikeista';
  }

  @override
  String get showOnMapSemanticLabel => 'Näytä asemat kartalla';

  @override
  String get searchResultsSemanticLabel => 'Hakutulokset';

  @override
  String get searchCriteriaSemanticLabel =>
      'Hakuehtojen yhteenveto. Muokkaa napauttamalla.';

  @override
  String get noFavoritesSemanticLabel =>
      'Ei vielä suosikkeja. Napauta aseman tähteä tallentaaksesi sen suosikiksi.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Asema on auki',
      'false': 'Asema on suljettu',
      'other': 'Asema on suljettu',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Maa $name, valittu',
      'false': 'Maa $name',
      'other': 'Maa $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Kieli $name, valittu',
      'false': 'Kieli $name',
      'other': 'Kieli $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Lajittele: $option, valittu',
      'false': 'Lajittele: $option',
      'other': 'Lajittele: $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Polttoaine $type, valittu',
      'false': 'Polttoaine $type',
      'other': 'Polttoaine $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Latausasema $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Tietosuojakilpi polttoainepisaralla';

  @override
  String get globeIllustrationSemantic => 'Maapallo huoltoasemamerkinnöillä';

  @override
  String get fuelPumpIllustrationSemantic => 'Polttoainepumppu hintanäytöllä';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, tietolähde: $provider, $keyRequirement, polttoainetyypit: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'API-avain vaaditaan';

  @override
  String get countryInfoNoKeyNeeded => 'Ilmainen, ei avainta';

  @override
  String countryInfoDataSource(String provider) {
    return 'Tiedot: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Polttoainetyypit: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Anonyymi avain';

  @override
  String get anonKeyHideTooltip => 'Piilota avain';

  @override
  String get anonKeyShowTooltip => 'Näytä avain tarkistukseen';

  @override
  String anonKeyTooLong(int length) {
    return 'Avain on liian pitkä ($length merkkiä) — tarkista ylimääräinen teksti';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Avain näyttää oikealta ($length merkkiä)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Avaimen pitäisi olla JWT (otsikko.hyötykuorma.allekirjoitus)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Avain voi olla katkaistu ($length/~208 odotettua merkkiä)';
  }

  @override
  String get anonKeyExceedsMax => 'Avain ylittää maksimipituuden';

  @override
  String get qrShareTitle => 'Jaa tietokantasi';

  @override
  String get qrShareSubtitle =>
      'Muut voivat skannata tämän QR-koodin yhdistääkseen';

  @override
  String get qrShareCopyAsText => 'Kopioi tekstinä';

  @override
  String get authInfoTitle => 'Miksi luoda tili?';

  @override
  String get authInfoBenefit1 =>
      '• Synkronoi suosikit, hälytykset ja tallennetut reitit laitteiden välillä';

  @override
  String get authInfoBenefit2 =>
      '• Suunnittele reitti puhelimella, käytä sitä autossasi';

  @override
  String get authInfoBenefit3 => '• Tietoja ei jaeta kolmansille osapuolille';

  @override
  String get authInfoBenefit4 => '• Voit poistaa tilisi milloin tahansa';

  @override
  String get privacyLocalDataEmpty =>
      'Ei vielä tallennettua. Lisää suosikki tai aseta hintahälytys nähdäksesi merkinnät täällä.';

  @override
  String get privacyHideEmptyRows => 'Piilota tyhjät rivit';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Näytä $count tyhjää riviä',
      one: 'Näytä $count tyhjä rivi',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'API-avaimen asetukset (valinnainen)';

  @override
  String get apiKeySetupDescription =>
      'Rekisteröidy ilmaiseksi API-avaimelle tai ohita ja tutustu sovellukseen esimerkkitiedoilla.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return '$provider-rekisteröinti';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Antamalla API-avaimen hyväksyt $provider:n käyttöehdot. Tietojen uudelleenjakelu on kielletty.';
  }

  @override
  String get calculatorDistanceHint => 'esim. 150';

  @override
  String get calculatorConsumptionHint => 'esim. 7,0';

  @override
  String get calculatorPriceHint => 'esim. 1,899';

  @override
  String get routeStrategyLabel => 'Strategia:';

  @override
  String get routeStrategyUniform => 'Yhtenäinen';

  @override
  String get routeStrategyBalanced => 'Tasapainoinen';

  @override
  String get glideCoachBetaTitle => 'Liukuluekovalmentaja beta (kokeellinen)';

  @override
  String get glideCoachBetaSubtitle =>
      'Hienovarainen haptiikka jarrutettaessa punaisia valoja kohti. Oletuksena pois — hajautumisriski.';

  @override
  String get consentSyncTripsTitle => 'Synkronoi matkatallenteet';

  @override
  String get consentSyncTripsSubtitle =>
      'Varmuuskopioi OBD2- ja GPS-matkat TankSynciin. Laitteiden välinen, valinnainen.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Ota pilvisynkronointi käyttöön yllä varmuuskopioidaksesi matkat.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Kirjaudu sähköpostitilillä, jotta voit synkronoida matkat laitteiden välillä.';

  @override
  String get consentHideDetails => 'Piilota tiedot';

  @override
  String get consentShowDetails => 'Näytä tiedot';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Virheellinen linkki';

  @override
  String invalidLinkBody(String path) {
    return 'Linkki \"$path\" ei ole kelvollinen.';
  }

  @override
  String get home => 'Etusivu';

  @override
  String get locationConsentTitle => 'Sijainnin käyttö';

  @override
  String get locationConsentSubtitle =>
      'Tämä sovellus haluaa käyttää sijaintiasi löytääkseen huoltoasemia läheltäsi.';

  @override
  String get locationConsentWhatHappens => 'Mitä sijaintitiedoillesi tapahtuu:';

  @override
  String get locationConsentBulletApi =>
      'Koordinaattisi lähetetään polttoaineen hinta-API:lle lähistön asemien löytämiseksi.';

  @override
  String get locationConsentBulletNoServer =>
      'Sijaintiasi ei tallenneta millekään palvelimelle — palvelinta ei ole.';

  @override
  String get locationConsentBulletNoTracking =>
      'Sijaintitietoja ei käytetä mainontaan, analytiikkaan tai seurantaan.';

  @override
  String get locationConsentRevoke =>
      'Voit peruuttaa sijainnin käyttöoikeuden milloin tahansa järjestelmäasetuksista. Vaihtoehtoisesti voit hakea postinumerolla.';

  @override
  String get locationConsentLegalBasis =>
      'Oikeusperuste: yleisen tietosuoja-asetuksen 6 artiklan 1 kohdan a alakohta (suostumus)';

  @override
  String get locationConsentDecline => 'Hylkää';

  @override
  String get locationConsentAccept => 'Hyväksy';

  @override
  String get loyaltySettingsTitle => 'Polttoainekortit';

  @override
  String get loyaltySettingsSubtitle =>
      'Lisää kanta-asiakasalennuksesi näytettäviin hintoihin';

  @override
  String get loyaltyMenuTitle => 'Polttoainekortit';

  @override
  String get loyaltyMenuSubtitle =>
      'Lisää litrahinta-alennukset Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Lisää kortti';

  @override
  String get loyaltyAddCardSheetTitle => 'Lisää polttoainekortti';

  @override
  String get loyaltyBrandLabel => 'Merkki';

  @override
  String get loyaltyCardLabelLabel => 'Nimike (valinnainen)';

  @override
  String get loyaltyDiscountLabel => 'Alennus (per litra)';

  @override
  String get loyaltyDiscountInvalid => 'Anna positiivinen luku';

  @override
  String get loyaltyDeleteConfirmTitle => 'Poistetaanko kortti?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Tämä kortti lopettaa alennuksen soveltamisen.';

  @override
  String get loyaltyEmptyTitle => 'Ei vielä polttoainekortteja';

  @override
  String get loyaltyEmptyBody =>
      'Lisää kortti soveltaaksesi litrahinta-alennustasi vastaaviin asemiin automaattisesti.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Tyhjäkäynti-RPM-nousu havaittu';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Tyhjäkäynti-RPM on noussut $percent% viimeisten $tripCount matkan aikana. Mahdollinen varhainen merkki tukkeutuneesta ilmansuodattimesta tai anturin ajautumisesta.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle => 'Mahdollinen imurajoitus';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Tasainen polttoaineen kulutus on laskenut $percent% viimeisten $tripCount matkan aikana. Mahdollinen merkki tukkeutuneesta ilmansuodattimesta tai rajoittuneesta imusta — kannattaa tarkistaa.';
  }

  @override
  String get maintenanceActionDismiss => 'Sulje';

  @override
  String get maintenanceActionSnooze => 'Lykkää 30 päivää';

  @override
  String get consumptionMonthlyInsightsTitle =>
      'Tämä kuukausi vs. viime kuukausi';

  @override
  String get consumptionMonthlyTripsLabel => 'Matkat';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Ajoaika';

  @override
  String get consumptionMonthlyDistanceLabel => 'Etäisyys';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Keskim. kulutus';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Vertailuun tarvitaan vähintään 3 matkaa kuukaudessa';

  @override
  String get obd2CapabilitySectionTitle => 'Sovittimen ominaisuudet';

  @override
  String get obd2CapabilityStandardOnly => 'Standardi';

  @override
  String get obd2CapabilityOemPids => 'OEM-PID:t';

  @override
  String get obd2CapabilityFullCan => 'Täysi CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Peugeot/Citroën-mallien tarkkaan litramäärään tankissa sovellus tukee OBDLink MX+/LX/CX (STN-siru).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2-diagnostiikkanäyttö käytössä';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2-diagnostiikkanäyttö pois käytöstä';

  @override
  String get obd2DebugOverlayClearButton => 'Tyhjennä';

  @override
  String get obd2DebugOverlayCloseButton => 'Sulje';

  @override
  String get obd2DebugOverlayTitle => 'OBD2-jäljet';

  @override
  String get obd2DiagnosticShareLabel => 'Jaa diagnostiikkaloki';

  @override
  String get obd2DebugLoggingTitle => 'OBD2-virheenkorjausloki';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Tallenna jokainen OBD2-istunto — yhteys, kättely, datakatkot ja uudelleenyhteydet — vietävään XML-lokiin. Oletuksena pois käytöstä.';

  @override
  String get obd2DebugSessionShareLabel => 'Jaa OBD2-istuntoloki';

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
    return 'Ei voitu tavoittaa \'$adapterName\' — valitse toinen sovitin';
  }

  @override
  String get onboardingObd2StepTitle => 'Yhdistä OBD2-sovitin';

  @override
  String get onboardingObd2StepBody =>
      'Kytke OBD2-sovitin auton porttiin ja käynnistä sytytin. Luemme VIN-koodin ja täytämme moottorin tiedot puolestasi.';

  @override
  String get onboardingObd2ConnectButton => 'Yhdistä sovitin';

  @override
  String get onboardingObd2SkipButton => 'Ehkä myöhemmin';

  @override
  String get onboardingObd2ReadingVin => 'Luetaan VIN-koodia…';

  @override
  String get onboardingObd2VinReadFailed =>
      'VIN-koodia ei voitu lukea — syötä manuaalisesti';

  @override
  String get onboardingObd2ConnectFailed =>
      'Sovittimeen ei saatu yhteyttä. Voit yrittää uudelleen tai ohittaa.';

  @override
  String get onboardingPickUseMode => 'Valitse käyttötapa jatkaaksesi.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'kulunut';

  @override
  String get alertsRadiusFrequencyLabel => 'Tarkistustiheys';

  @override
  String get alertsRadiusFrequencyDaily => 'Kerran päivässä';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Kaksi kertaa päivässä';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Kolme kertaa päivässä';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Neljä kertaa päivässä';

  @override
  String get radiusAlertPickOnMap => 'Valitse kartalta';

  @override
  String get radiusAlertMapPickerTitle => 'Valitse hälytyksen keskipiste';

  @override
  String get radiusAlertMapPickerConfirm => 'Vahvista';

  @override
  String get radiusAlertMapPickerCancel => 'Peruuta';

  @override
  String get radiusAlertMapPickerHint =>
      'Vedä karttaa asettaaksesi hälytyksen keskipiste';

  @override
  String get radiusAlertCenterFromMap => 'Karttasijainti';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel lähellä $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Asema on hintaan $price € (tavoite: $threshold €)';
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
  String get refuelUnitPerSession => '/lataus';

  @override
  String get speedConsumptionCardTitle => 'Kulutus nopeuden mukaan';

  @override
  String get speedBandIdleJam => 'Tyhjäkäynti / ruuhka';

  @override
  String get speedBandUrban => 'Kaupunki (10–50)';

  @override
  String get speedBandSuburban => 'Esikaupunki (50–80)';

  @override
  String get speedBandRural => 'Maaseutu (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Ekokruising (100–115)';

  @override
  String get speedBandMotorway => 'Moottoritie (115–130)';

  @override
  String get speedBandMotorwayFast => 'Moottoritie nopea (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Tallenna yli 30 minuutin matkat OBD2-sovittimella avataksesi nopeus/kulutus-analyysin.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % ajosta';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Tarvitaan lisää tietoja';

  @override
  String get splashLoadingLabel => 'Ladataan Sparkilo';

  @override
  String get storageRecoveryTitle => 'Tallennustila-ongelma';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo ei voinut avata paikallista tietovarastoaan. Tallennustiedosto vaikuttaa vioittuneelta.';

  @override
  String get storageRecoveryGuidance =>
      'Palauta tilanne tyhjentämällä sovelluksen tallennustila laitteen asetuksista tai asentamalla sovellus uudelleen. Suosikkisi ja historiasi tallennetaan vain tähän laitteeseen, joten niitä ei voi palauttaa automaattisesti.';

  @override
  String get tankLevelTitle => 'Tankin taso';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km kantama';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Viimeisin tankkaus: $date · $count matka(a) sen jälkeen';
  }

  @override
  String get tankLevelMethodObd2 => 'OBD2-mitattu';

  @override
  String get tankLevelMethodDistanceFallback => 'etäisyyspohjainen arvio';

  @override
  String get tankLevelMethodMixed => 'yhdistelmämittaus';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Kirjaa tankkaus nähdäksesi tankin tason';

  @override
  String get tankLevelDetailSheetTitle =>
      'Matkat viimeisen tankkauksen jälkeen';

  @override
  String get addFillUpIsFullTankLabel => 'Täysi tankki';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Tankki täytetty laitaan — poista valinta jos kyseessä oli osittainen tankkaus';

  @override
  String get themeCardTitle => 'Teema';

  @override
  String get themeCardSubtitleSystem => 'Järjestelmä';

  @override
  String get themeCardSubtitleLight => 'Vaalea';

  @override
  String get themeCardSubtitleDark => 'Tumma';

  @override
  String get themeSettingsScreenTitle => 'Teema';

  @override
  String get themeSettingsSystemLabel => 'Seuraa järjestelmää';

  @override
  String get themeSettingsLightLabel => 'Vaalea';

  @override
  String get themeSettingsDarkLabel => 'Tumma';

  @override
  String get themeSettingsSystemDescription =>
      'Seuraa laitteen nykyistä ulkoasua.';

  @override
  String get themeSettingsLightDescription =>
      'Vaaleat taustat — parhaimmillaan päiväkäytössä.';

  @override
  String get themeSettingsDarkDescription =>
      'Tummat taustat — helpompi silmille yöllä ja säästää akkua OLED-näytöillä.';

  @override
  String get themeSettingsEcoLabel => 'Eko';

  @override
  String get themeSettingsEcoDescription =>
      'Sovelluksen tunnusomainen vihreä ilme — kirkas ja helppolukuinen, pehmeästi vihersävytteiset taustat.';

  @override
  String get throttleRpmHistogramTitle => 'Miten käytit moottoria';

  @override
  String get throttleRpmHistogramThrottleSection => 'Kaasupoljinasento';

  @override
  String get throttleRpmHistogramRpmSection => 'Moottorin RPM';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Liuku (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Kevyt (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Luja (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Täysauki (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Tyhjäkäynti (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Kruising (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Voimakas (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Kova (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Ei kaasupoljin- tai RPM-näytteitä tällä matkalla.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Matkat';

  @override
  String get trajetsStartRecordingButton => 'Aloita tallennus';

  @override
  String get trajetsResumeRecordingButton => 'Jatka tallennusta';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Yhdistetään OBD2-sovittimeen…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Luetaan ajoneuvon tietoja…';

  @override
  String get tripStartProgressStartingRecording => 'Aloitetaan tallennus…';

  @override
  String get trajetsEmptyStateTitle => 'Ei vielä matkoja';

  @override
  String get trajetsEmptyStateBody =>
      'Napauta Aloita tallennus aloittaaksesi ajojen kirjaamisen.';

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
  String get trajetDetailSummaryTitle => 'Yhteenveto';

  @override
  String get trajetDetailFieldDate => 'Päivämäärä';

  @override
  String get trajetDetailFieldVehicle => 'Ajoneuvo';

  @override
  String get trajetDetailFieldAdapter => 'OBD2-sovitin';

  @override
  String get trajetDetailFieldDistance => 'Etäisyys';

  @override
  String get trajetDetailFieldDuration => 'Kesto';

  @override
  String get trajetDetailFieldAvgConsumption => 'Keskim. kulutus';

  @override
  String get trajetDetailFieldFuelUsed => 'Polttoainetta käytetty';

  @override
  String get trajetDetailFieldFuelCost => 'Polttoainekustannus';

  @override
  String get trajetDetailFieldAvgSpeed => 'Keskim. nopeus';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maks. nopeus';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Nopeus (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Polttoaineen kulutus (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Moottorin kuorma (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Kaaviot';

  @override
  String get trajetsRowColdStartChip => 'Kylmäkäynnistys';

  @override
  String get trajetsRowColdStartTooltip =>
      'Moottori ei saavuttanut käyntölämpöä tällä matkalla — polttoaineen kulutus oli tavallista suurempi.';

  @override
  String get trajetDetailChartEmpty => 'Ei tallennettuja näytteitä';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Jaa';

  @override
  String get trajetDetailShareImageOption => 'Jaa kuva';

  @override
  String get trajetDetailShareGpxOption => 'Jaa GPS-jälki (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Ei GPS-tietoja tällä matkalla';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — matka $date';
  }

  @override
  String get trajetDetailShareError => 'Jaettavan kuvan luominen epäonnistui';

  @override
  String get trajetDetailDeleteAction => 'Poista';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Poistetaanko tämä matka?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Tämä matka poistetaan pysyvästi historiastasi.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Peruuta';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Poista';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2-sovitin yhdistetty mutta ei palauta tietoja. Kokeile toista sovitinta tai tarkista ajoneuvon diagnostiikkaprotokolla.';

  @override
  String get trajetsViewAllOnMap => 'Näytä kaikki kartalla';

  @override
  String get trajetsMapTitle => 'Matkat kartalla';

  @override
  String get trajetsMapShareGpx => 'Jaa GPX';

  @override
  String get trajetsMapEmpty =>
      'Yhdelläkään valitusta matkasta ei ole GPS-tietoja.';

  @override
  String get trajetsMapShareError => 'GPX-tiedostoa ei voitu jakaa';

  @override
  String get tripLengthCardTitle => 'Kulutus matkan pituuden mukaan';

  @override
  String get tripLengthBucketShort => 'Lyhyt (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Keski (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Pitkä (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Tarvitaan lisää tietoja';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matkaa',
      one: '1 matka',
      zero: 'ei matkoja',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Matkapolku';

  @override
  String get tripPathCardSubtitle => 'GPS-tallennettu reitti';

  @override
  String get tripPathLegendTitle => 'Kulutus';

  @override
  String get tripPathLegendEfficient => 'Tehokas (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Rajoilla (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Tuhlaava (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get tripRecordingPinTooltip =>
      'Kiinnittäminen pitää näytön päällä — kuluttaa enemmän akkua';

  @override
  String get tripRecordingPinSemanticOn => 'Irrota tallennuslomake';

  @override
  String get tripRecordingPinSemanticOff => 'Kiinnitä tallennuslomake';

  @override
  String get tripRecordingPinHelpTooltip => 'Mitä kiinnittäminen tekee?';

  @override
  String get tripRecordingPinHelpTitle => 'Tietoa kiinnittämisestä';

  @override
  String get tripRecordingPinHelpBody =>
      'Kiinnittäminen pitää näytön päällä ja piilottaa järjestelmäpalkit jotta lomake pysyy luettavana kojelauta-asennuksessa. Napauta uudelleen vapauttaaksesi. Vapautuu automaattisesti matkan päättyessä.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Tallennus jatkuu taustalla. Napauta yläosan punaista banneria millä tahansa näytöllä palataksesi.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Avaa aktiivinen matka Kulutus-välilehdeltä';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Kiinnitä näyttö pitääksesi GPS aktiivisena matkan aikana — Android voi rajoittaa GPS:ää nukkuessa.';

  @override
  String get tripRecordingMinimiseTooltip => 'Pienennä kelluvaksi ruuduksi';

  @override
  String get tripRecordingAutoPinTitle => 'Kiinnitä aina tallennuksen alkaessa';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Kiinnitä lomake automaattisesti joka ajolla sen sijaan, että napautat joka kerta. Kuluttaa enemmän akkua.';

  @override
  String get tripRecordingConnectingTitle => 'Aloitetaan tallennusta…';

  @override
  String get tripShareAction => 'Jaa toiselle tilille';

  @override
  String get tripShareSheetTitle => 'Jaa tämä matka';

  @override
  String get tripShareSheetSubtitle =>
      'Anna toiselle TankSync-tilille vain luku -oikeus tähän tallennettuun matkaan.';

  @override
  String get tripShareEmailLabel => 'Vastaanottajan sähköposti';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Jaa';

  @override
  String get tripShareCreateLinkButton => 'Luo jakolinkki';

  @override
  String get tripShareLinkCreated =>
      'Jakolinkki kopioitu — liitä se vastaanottajalle.';

  @override
  String get tripShareSuccess => 'Matka jaettu.';

  @override
  String get tripShareRecipientNotFound =>
      'Mikään TankSync-tili ei käytä tätä sähköpostia.';

  @override
  String get tripShareError => 'Matkan jakaminen epäonnistui. Yritä uudelleen.';

  @override
  String get tripShareExistingTitle => 'Jaettu käyttäjälle';

  @override
  String get tripShareExistingEmpty => 'Ei vielä jaettu kenellekään.';

  @override
  String get tripShareDirectRecipient => 'Tili';

  @override
  String get tripShareLinkRecipient => 'Jakolinkki (lunastamaton)';

  @override
  String get tripShareRevokeTooltip => 'Peruuta';

  @override
  String get tripShareRevoked => 'Jakaminen peruutettu.';

  @override
  String get trajetsSharedSectionTitle => 'Jaettu kanssani';

  @override
  String get trajetsSharedBadge => 'Jaettu';

  @override
  String get unifiedFilterFuel => 'Polttoaine';

  @override
  String get unifiedFilterEv => 'Sähköauto';

  @override
  String get unifiedFilterBoth => 'Molemmat';

  @override
  String get unifiedNoResultsForFilter => 'Ei tuloksia tälle suodattimelle';

  @override
  String get searchFailedSnackbar => 'Haku epäonnistui — yritä uudelleen';

  @override
  String get vinLabel => 'VIN (valinnainen)';

  @override
  String get vinDecodeTooltip => 'Pura VIN-koodi';

  @override
  String get vinConfirmAction => 'Kyllä, esitäytä';

  @override
  String get vinModifyAction => 'Muokkaa manuaalisesti';

  @override
  String get veResetAction => 'Nollaa tilavuushyötysuhde';

  @override
  String get vehicleReadVinFromCarButton => 'Lue VIN autosta';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Lue VIN paritetulta OBD2-sovittimelta';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN ei saatavilla (Mode 09 PID 02 ei tuettu ennen 2005 ajoneuvoja)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'VIN-lukeminen epäonnistui — syötä manuaalisesti';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Paritetaan ensin OBD2-sovitin lukeaksesi VIN:n automaattisesti';

  @override
  String get pickerButtonLabel => 'Valitse katalogista';

  @override
  String get pickerSearchHint => 'Hae merkkiä tai mallia';

  @override
  String get pickerHelpText => 'Esitäytä yli 50 tuetulta ajoneuvolta';

  @override
  String get pickerEmptyResults => 'Ei osumia';

  @override
  String get pickerCancel => 'Peruuta';

  @override
  String get pickerLoading => 'Ladataan katalogi…';

  @override
  String get vinInfoTooltip => 'Mikä on VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Mikä on VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Ajoneuvon tunnistenumero on 17-merkkinen koodi, joka on yksilöllinen autollesi. Se on leimattu alustaan ja tulostettu ajoneuvon rekisteröintiasiakirjaan.';

  @override
  String get vinInfoSectionWhyTitle => 'Miksi kysymme';

  @override
  String get vinInfoSectionWhyBody =>
      'VIN-koodin purkaminen täyttää automaattisesti moottorin tilavuuden, sylinteriluvun, mallivuoden, pääpolttoainetyypin ja kokonaismassan — säästäen sinut teknisten tietojen manuaaliselta etsimiseltä. OBD2-polttoaineen kulutuksen laskenta käyttää näitä arvoja tarkan kulutuksen laskemiseksi.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Tietosuoja';

  @override
  String get vinInfoSectionPrivacyBody =>
      'VIN-koodisi tallennetaan vain paikallisesti sovelluksen salatussa tallennustilassa — sitä ei koskaan ladata Sparkilo-palvelimille. NHTSA vPIC -tietokantaan tehdään kysely VIN:llä mutta se palauttaa vain anonyymiä teknistä tietoa; NHTSA ei yhdistä VIN-koodia henkilötietoihin. Ilman verkkoyhteyttä offline-haku palauttaa vain valmistajan ja maan.';

  @override
  String get vinInfoSectionWhereTitle => 'Mistä löydät sen';

  @override
  String get vinInfoSectionWhereBody =>
      'Katso tuulilasin läpi kuljettajan puolen vasempaan alakulmaan, tarkista kuljettajan puolen ovenkarmin tarra oven ollessa auki tai lue se ajoneuvon rekisteröintiasiakirjasta (kortti / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Selvä';

  @override
  String get vinConfirmPrivacyNote =>
      'Haimme VIN-koodisi NHTSA:n ilmaisesta ajoneuvotietokannasta — Sparkilo-palvelimille ei lähetetty mitään.';

  @override
  String get gdprVinOnlineDecodeTitle => 'VIN-verkkopurku';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Pura VIN NHTSA:n ilmaisella julkisella palvelulla';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Kun paritat sovittimen, ajoneuvosi VIN luetaan paikallisesti auton tunnistamiseksi. Tämän ottaminen käyttöön lähettää 17-merkkisen VIN-koodin NHTSA:n ilmaiseen vPIC-palveluun lisätietojen hakemiseksi (malli, moottorin tilavuus, polttoainetyyppi). VIN on ainoa lähetetty tieto — muuta tietoa ei poistu laitteeltasi.';

  @override
  String get vehicleDetectedFromVinBadge => '(havaittu)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Havaittu VIN:stä: $summary. Sovelletaanko?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Sovella';

  @override
  String get widgetHelpSectionTitle => 'Aloitusnäytön widget';

  @override
  String get widgetHelpIntro =>
      'Lisää SparKilo-widget aloitusnäytölle nähdäksesi polttoaine- ja lataushinnat yhdellä silmäyksellä.';

  @override
  String get widgetHelpAdd =>
      'Lisää se käynnistyssovelluksen widget-valitsimesta — paina pitkään aloitusnäytön tyhjää kohtaa, valitse Widgetit ja etsi SparKilo.';

  @override
  String get widgetHelpTap =>
      'Napauta asemaa widgetissä avataksesi sen sovelluksessa. Napauta päivityskuvaketta päivittääksesi hinnat.';

  @override
  String get widgetHelpConfigure =>
      'Androidilla paina widgetiä pitkään ja valitse Määritä uudelleen muuttaaksesi profiilia, väriä ja sisältöä.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Alla olevat valinnat koskevat kaikkia asennettuja widgettejä seuraavalla päivityksellä.';

  @override
  String get widgetDefaultsColorLabel => 'Värimaailma';

  @override
  String get widgetDefaultsVariantLabel => 'Sisältövaihtoehto';

  @override
  String get widgetColorSchemeSystem => 'Järjestelmä';

  @override
  String get widgetColorSchemeLight => 'Vaalea';

  @override
  String get widgetColorSchemeDark => 'Tumma';

  @override
  String get widgetColorSchemeBlue => 'Sininen';

  @override
  String get widgetColorSchemeGreen => 'Vihreä';

  @override
  String get widgetColorSchemeOrange => 'Oranssi';

  @override
  String get widgetVariantDefault => 'Vain nykyinen hinta';

  @override
  String get widgetVariantPredictive => 'Ennustava: paras tankkausaika';

  @override
  String get widgetPredictiveNowPrefix => 'nyt';
}
