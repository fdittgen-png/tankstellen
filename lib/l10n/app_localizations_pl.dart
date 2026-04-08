// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Ceny Paliw';

  @override
  String get search => 'Szukaj';

  @override
  String get favorites => 'Ulubione';

  @override
  String get map => 'Mapa';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ustawienia';

  @override
  String get gpsLocation => 'Lokalizacja GPS';

  @override
  String get zipCode => 'Kod pocztowy';

  @override
  String get zipCodeHint => 'np. 00-001';

  @override
  String get fuelType => 'Paliwo';

  @override
  String get searchRadius => 'Promień';

  @override
  String get searchNearby => 'Stacje w pobliżu';

  @override
  String get searchButton => 'Szukaj';

  @override
  String get noResults => 'Nie znaleziono stacji.';

  @override
  String get startSearch => 'Wyszukaj, aby znaleźć stacje paliw.';

  @override
  String get open => 'Otwarte';

  @override
  String get closed => 'Zamknięte';

  @override
  String distance(String distance) {
    return '$distance stąd';
  }

  @override
  String get price => 'Cena';

  @override
  String get prices => 'Ceny';

  @override
  String get address => 'Adres';

  @override
  String get openingHours => 'Godziny otwarcia';

  @override
  String get open24h => 'Otwarte 24 godziny';

  @override
  String get navigate => 'Nawiguj';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get apiKeySetup => 'Klucz API';

  @override
  String get apiKeyDescription =>
      'Zarejestruj się raz, aby uzyskać bezpłatny klucz API.';

  @override
  String get apiKeyLabel => 'Klucz API';

  @override
  String get register => 'Rejestracja';

  @override
  String get continueButton => 'Kontynuuj';

  @override
  String get welcome => 'Ceny Paliw';

  @override
  String get welcomeSubtitle => 'Znajdź najtańsze paliwo w pobliżu.';

  @override
  String get profileName => 'Nazwa profilu';

  @override
  String get preferredFuel => 'Preferowane paliwo';

  @override
  String get defaultRadius => 'Domyślny promień';

  @override
  String get landingScreen => 'Ekran startowy';

  @override
  String get homeZip => 'Kod pocztowy domu';

  @override
  String get newProfile => 'Nowy profil';

  @override
  String get editProfile => 'Edytuj profil';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get activate => 'Aktywuj';

  @override
  String get configured => 'Skonfigurowano';

  @override
  String get notConfigured => 'Nie skonfigurowano';

  @override
  String get about => 'O aplikacji';

  @override
  String get openSource => 'Otwarte źródło (Licencja MIT)';

  @override
  String get sourceCode => 'Kod źródłowy na GitHub';

  @override
  String get noFavorites => 'Brak ulubionych';

  @override
  String get noFavoritesHint =>
      'Dotknij gwiazdki przy stacji, aby zapisać ją jako ulubioną.';

  @override
  String get language => 'Język';

  @override
  String get country => 'Kraj';

  @override
  String get demoMode => 'Tryb demo — wyświetlane dane przykładowe.';

  @override
  String get setupLiveData => 'Skonfiguruj dane na żywo';

  @override
  String get freeNoKey => 'Bezpłatnie — klucz nie jest wymagany';

  @override
  String get apiKeyRequired => 'Wymagany klucz API';

  @override
  String get skipWithoutKey => 'Kontynuuj bez klucza';

  @override
  String get dataTransparency => 'Przejrzystość danych';

  @override
  String get storageAndCache => 'Pamięć i pamięć podręczna';

  @override
  String get clearCache => 'Wyczyść pamięć podręczną';

  @override
  String get clearAllData => 'Usuń wszystkie dane';

  @override
  String get errorLog => 'Dziennik błędów';

  @override
  String stationsFound(int count) {
    return 'Znaleziono $count stacji';
  }

  @override
  String get whatIsShared => 'Co jest udostępniane — i komu?';

  @override
  String get gpsCoordinates => 'Współrzędne GPS';

  @override
  String get gpsReason =>
      'Wysyłane przy każdym wyszukiwaniu, aby znaleźć pobliskie stacje.';

  @override
  String get postalCodeData => 'Kod pocztowy';

  @override
  String get postalReason =>
      'Konwertowany na współrzędne przez usługę geokodowania.';

  @override
  String get mapViewport => 'Widok mapy';

  @override
  String get mapReason =>
      'Kafelki mapy są ładowane z serwera. Żadne dane osobowe nie są przesyłane.';

  @override
  String get apiKeyData => 'Klucz API';

  @override
  String get apiKeyReason =>
      'Twój osobisty klucz jest wysyłany z każdym żądaniem API. Jest powiązany z Twoim adresem e-mail.';

  @override
  String get notShared => 'NIE jest udostępniane:';

  @override
  String get searchHistory => 'Historia wyszukiwania';

  @override
  String get favoritesData => 'Ulubione';

  @override
  String get profileNames => 'Nazwy profili';

  @override
  String get homeZipData => 'Kod pocztowy domu';

  @override
  String get usageData => 'Dane o użytkowaniu';

  @override
  String get privacyBanner =>
      'Ta aplikacja nie ma serwera. Wszystkie dane pozostają na Twoim urządzeniu. Bez analityki, bez śledzenia, bez reklam.';

  @override
  String get storageUsage => 'Wykorzystanie pamięci na tym urządzeniu';

  @override
  String get settingsLabel => 'Ustawienia';

  @override
  String get profilesStored => 'profili zapisanych';

  @override
  String get stationsMarked => 'stacji oznaczonych';

  @override
  String get cachedResponses => 'odpowiedzi w pamięci podręcznej';

  @override
  String get total => 'Razem';

  @override
  String get cacheManagement => 'Zarządzanie pamięcią podręczną';

  @override
  String get cacheDescription =>
      'Pamięć podręczna przechowuje odpowiedzi API dla szybszego ładowania i dostępu offline.';

  @override
  String get stationSearch => 'Wyszukiwanie stacji';

  @override
  String get stationDetails => 'Szczegóły stacji';

  @override
  String get priceQuery => 'Zapytanie o cenę';

  @override
  String get zipGeocoding => 'Geokodowanie kodu pocztowego';

  @override
  String minutes(int n) {
    return '$n minut';
  }

  @override
  String hours(int n) {
    return '$n godzin';
  }

  @override
  String get clearCacheTitle => 'Wyczyścić pamięć podręczną?';

  @override
  String get clearCacheBody =>
      'Zapisane wyniki wyszukiwania i ceny zostaną usunięte. Profile, ulubione i ustawienia zostaną zachowane.';

  @override
  String get clearCacheButton => 'Wyczyść pamięć podręczną';

  @override
  String get deleteAllTitle => 'Usunąć wszystkie dane?';

  @override
  String get deleteAllBody =>
      'To trwale usunie wszystkie profile, ulubione, klucz API, ustawienia i pamięć podręczną. Aplikacja zostanie zresetowana.';

  @override
  String get deleteAllButton => 'Usuń wszystko';

  @override
  String get entries => 'wpisów';

  @override
  String get cacheEmpty => 'Pamięć podręczna jest pusta';

  @override
  String get noStorage => 'Brak wykorzystanej pamięci';

  @override
  String get apiKeyNote =>
      'Bezpłatna rejestracja. Dane od rządowych agencji przejrzystości cen.';

  @override
  String get apiKeyFormatError =>
      'Nieprawidłowy format — oczekiwany UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Wesprzyj ten projekt';

  @override
  String get supportDescription =>
      'Ta aplikacja jest darmowa, open source i bez reklam. Jeśli jest przydatna, rozważ wsparcie dewelopera.';

  @override
  String get reportBug => 'Zgłoś błąd / Zaproponuj funkcję';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get fuels => 'Paliwa';

  @override
  String get services => 'Usługi';

  @override
  String get zone => 'Strefa';

  @override
  String get highway => 'Autostrada';

  @override
  String get localStation => 'Lokalna stacja';

  @override
  String get lastUpdate => 'Ostatnia aktualizacja';

  @override
  String get automate24h => '24h/24 — Automat';

  @override
  String get refreshPrices => 'Odśwież ceny';

  @override
  String get station => 'Stacja paliw';

  @override
  String get locationDenied =>
      'Odmowa dostępu do lokalizacji. Możesz szukać po kodzie pocztowym.';

  @override
  String get demoModeBanner =>
      'Tryb demo. Skonfiguruj klucz API w ustawieniach.';

  @override
  String get sortDistance => 'Odległość';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'tanio';

  @override
  String get expensive => 'drogo';

  @override
  String stationsOnMap(int count) {
    return '$count stacji';
  }

  @override
  String get loadingFavorites =>
      'Ładowanie ulubionych...\nNajpierw wyszukaj stacje, aby zapisać dane.';

  @override
  String get reportPrice => 'Zgłoś cenę';

  @override
  String get whatsWrong => 'Co jest nie tak?';

  @override
  String get correctPrice => 'Prawidłowa cena (np. 1,459)';

  @override
  String get sendReport => 'Wyślij zgłoszenie';

  @override
  String get reportSent => 'Zgłoszenie wysłane. Dziękujemy!';

  @override
  String get enterValidPrice => 'Wprowadź prawidłową cenę';

  @override
  String get cacheCleared => 'Pamięć podręczna wyczyszczona.';

  @override
  String get yourPosition => 'Twoja pozycja';

  @override
  String get positionUnknown => 'Pozycja nieznana';

  @override
  String get distancesFromCenter => 'Odległości od centrum wyszukiwania';

  @override
  String get autoUpdatePosition => 'Aktualizuj pozycję automatycznie';

  @override
  String get autoUpdateDescription =>
      'Aktualizuj GPS przed każdym wyszukiwaniem';

  @override
  String get location => 'Lokalizacja';

  @override
  String get switchProfileTitle => 'Kraj zmieniony';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Jesteś teraz w $country. Przełączyć na profil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Przełączono na profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Brak profilu dla tego kraju';

  @override
  String noProfileForCountry(String country) {
    return 'Jesteś w $country, ale nie ma skonfigurowanego profilu. Utwórz go w Ustawieniach.';
  }

  @override
  String get autoSwitchProfile => 'Automatyczna zmiana profilu';

  @override
  String get autoSwitchDescription =>
      'Automatycznie zmień profil po przekroczeniu granicy';

  @override
  String get switchProfile => 'Zmień';

  @override
  String get dismiss => 'Zamknij';

  @override
  String get profileCountry => 'Kraj';

  @override
  String get profileLanguage => 'Język';

  @override
  String get settingsStorageDetail => 'Klucz API, aktywny profil';

  @override
  String get allFuels => 'Wszystkie';

  @override
  String get priceAlerts => 'Alerty cenowe';

  @override
  String get noPriceAlerts => 'Brak alertów cenowych';

  @override
  String get noPriceAlertsHint => 'Utwórz alert na stronie szczegółów stacji.';

  @override
  String alertDeleted(String name) {
    return 'Alert \"$name\" usunięty';
  }

  @override
  String get createAlert => 'Utwórz alert cenowy';

  @override
  String currentPrice(String price) {
    return 'Aktualna cena: $price';
  }

  @override
  String get targetPrice => 'Cena docelowa (EUR)';

  @override
  String get enterPrice => 'Wprowadź cenę';

  @override
  String get invalidPrice => 'Nieprawidłowa cena';

  @override
  String get priceTooHigh => 'Cena zbyt wysoka';

  @override
  String get create => 'Utwórz';

  @override
  String get alertCreated => 'Alert cenowy utworzony';

  @override
  String get wrongE5Price => 'Błędna cena Super E5';

  @override
  String get wrongE10Price => 'Błędna cena Super E10';

  @override
  String get wrongDieselPrice => 'Błędna cena Diesel';

  @override
  String get wrongStatusOpen => 'Pokazana jako otwarta, ale zamknięta';

  @override
  String get wrongStatusClosed => 'Pokazana jako zamknięta, ale otwarta';

  @override
  String get searchAlongRouteLabel => 'Wzdłuż trasy';

  @override
  String get searchEvStations => 'Szukaj stacji ładowania';

  @override
  String get allStations => 'Wszystkie stacje';

  @override
  String get bestStops => 'Najlepsze przystanki';

  @override
  String get openInMaps => 'Otwórz w Mapach';

  @override
  String get noStationsAlongRoute => 'Nie znaleziono stacji wzdłuż trasy';

  @override
  String get evOperational => 'Czynna';

  @override
  String get evStatusUnknown => 'Status nieznany';

  @override
  String evConnectors(int count) {
    return 'Złącza ($count punktów)';
  }

  @override
  String get evNoConnectors => 'Brak szczegółów złączy';

  @override
  String get evUsageCost => 'Koszt użytkowania';

  @override
  String get evPricingUnavailable => 'Cennik niedostępny u dostawcy';

  @override
  String get evLastUpdated => 'Ostatnia aktualizacja';

  @override
  String get evUnknown => 'Nieznany';

  @override
  String get evDataAttribution =>
      'Dane z OpenChargeMap (źródło społecznościowe)';

  @override
  String get evStatusDisclaimer =>
      'Status może nie odzwierciedlać dostępności w czasie rzeczywistym. Dotknij odśwież, aby pobrać najnowsze dane.';

  @override
  String get evNavigateToStation => 'Nawiguj do stacji';

  @override
  String get evRefreshStatus => 'Odśwież status';

  @override
  String get evStatusUpdated => 'Status zaktualizowany';

  @override
  String get evStationNotFound =>
      'Nie udało się odświeżyć — stacja nie znaleziona w pobliżu';

  @override
  String get addedToFavorites => 'Dodano do ulubionych';

  @override
  String get removedFromFavorites => 'Usunięto z ulubionych';

  @override
  String get addFavorite => 'Dodaj do ulubionych';

  @override
  String get removeFavorite => 'Usuń z ulubionych';

  @override
  String get currentLocation => 'Bieżąca lokalizacja';

  @override
  String get gpsError => 'Błąd GPS';

  @override
  String get couldNotResolve => 'Nie udało się ustalić startu lub celu';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Cel';

  @override
  String get cityAddressOrGps => 'Miasto, adres lub GPS';

  @override
  String get cityOrAddress => 'Miasto lub adres';

  @override
  String get useGps => 'Użyj GPS';

  @override
  String get stop => 'Przystanek';

  @override
  String stopN(int n) {
    return 'Przystanek $n';
  }

  @override
  String get addStop => 'Dodaj przystanek';

  @override
  String get searchAlongRoute => 'Szukaj wzdłuż trasy';

  @override
  String get cheapest => 'Najtańsza';

  @override
  String nStations(int count) {
    return '$count stacji';
  }

  @override
  String nBest(int count) {
    return '$count najlepszych';
  }

  @override
  String get fuelPricesTankerkoenig => 'Ceny paliw (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Wymagane do wyszukiwania cen paliw w Niemczech';

  @override
  String get evChargingOpenChargeMap => 'Ładowanie EV (OpenChargeMap)';

  @override
  String get customKey => 'Własny klucz';

  @override
  String get appDefaultKey => 'Domyślny klucz aplikacji';

  @override
  String get optionalOverrideKey =>
      'Opcjonalnie: zastąp wbudowany klucz aplikacji własnym';

  @override
  String get requiredForEvSearch =>
      'Wymagane do wyszukiwania stacji ładowania EV';

  @override
  String get edit => 'Edytuj';

  @override
  String get fuelPricesApiKey => 'Klucz API cen paliw';

  @override
  String get tankerkoenigApiKey => 'Klucz API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Klucz API ładowania EV';

  @override
  String get openChargeMapApiKey => 'Klucz API OpenChargeMap';

  @override
  String get routeSegment => 'Segment trasy';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Pokaż najtańszą stację co $km km wzdłuż trasy';
  }

  @override
  String get avoidHighways => 'Unikaj autostrad';

  @override
  String get avoidHighwaysDesc =>
      'Obliczanie trasy omija drogi płatne i autostrady';

  @override
  String get showFuelStations => 'Pokaż stacje paliw';

  @override
  String get showFuelStationsDesc =>
      'Uwzględnij stacje benzynowe, diesel, LPG, CNG';

  @override
  String get showEvStations => 'Pokaż stacje ładowania';

  @override
  String get showEvStationsDesc =>
      'Uwzględnij stacje ładowania w wynikach wyszukiwania';

  @override
  String get noStationsAlongThisRoute =>
      'Nie znaleziono stacji wzdłuż tej trasy.';

  @override
  String get fuelCostCalculator => 'Kalkulator kosztów paliwa';

  @override
  String get distanceKm => 'Odległość (km)';

  @override
  String get consumptionL100km => 'Zużycie (L/100km)';

  @override
  String get fuelPriceEurL => 'Cena paliwa (EUR/L)';

  @override
  String get tripCost => 'Koszt podróży';

  @override
  String get fuelNeeded => 'Potrzebne paliwo';

  @override
  String get totalCost => 'Koszt całkowity';

  @override
  String get enterCalcValues =>
      'Wprowadź odległość, zużycie i cenę, aby obliczyć koszt podróży';

  @override
  String get priceHistory => 'Historia cen';

  @override
  String get noPriceHistory => 'Brak historii cen';

  @override
  String get noHourlyData => 'Brak danych godzinowych';

  @override
  String get noStatistics => 'Brak dostępnych statystyk';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Śr';

  @override
  String get showAllFuelTypes => 'Pokaż wszystkie typy paliw';

  @override
  String get connected => 'Połączono';

  @override
  String get notConnected => 'Niepołączono';

  @override
  String get connectTankSync => 'Połącz TankSync';

  @override
  String get disconnectTankSync => 'Odłącz TankSync';

  @override
  String get viewMyData => 'Zobacz moje dane';

  @override
  String get optionalCloudSync =>
      'Opcjonalna synchronizacja w chmurze dla alertów, ulubionych i powiadomień push';

  @override
  String get tapToUpdateGps => 'Dotknij, aby zaktualizować pozycję GPS';

  @override
  String get gpsAutoUpdateHint =>
      'Pozycja GPS jest pobierana automatycznie podczas wyszukiwania. Możesz ją też zaktualizować ręcznie tutaj.';

  @override
  String get clearGpsConfirm =>
      'Wyczyścić zapisaną pozycję GPS? Możesz ją zaktualizować ponownie w dowolnym momencie.';

  @override
  String get pageNotFound => 'Strona nie znaleziona';

  @override
  String get deleteAllServerData => 'Usuń wszystkie dane serwera';

  @override
  String get deleteServerDataConfirm => 'Usunąć wszystkie dane serwera?';

  @override
  String get deleteEverything => 'Usuń wszystko';

  @override
  String get allDataDeleted => 'Wszystkie dane serwera usunięte';

  @override
  String get disconnectConfirm => 'Odłączyć TankSync?';

  @override
  String get disconnect => 'Odłącz';

  @override
  String get myServerData => 'Moje dane serwera';

  @override
  String get anonymousUuid => 'Anonimowy UUID';

  @override
  String get server => 'Serwer';

  @override
  String get syncedData => 'Zsynchronizowane dane';

  @override
  String get pushTokens => 'Tokeny push';

  @override
  String get priceReports => 'Zgłoszenia cen';

  @override
  String get totalItems => 'Łącznie pozycji';

  @override
  String get estimatedSize => 'Szacowany rozmiar';

  @override
  String get viewRawJson => 'Zobacz surowe dane jako JSON';

  @override
  String get exportJson => 'Eksportuj jako JSON (schowek)';

  @override
  String get jsonCopied => 'JSON skopiowany do schowka';

  @override
  String get rawDataJson => 'Surowe dane (JSON)';

  @override
  String get close => 'Zamknij';

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
  String get alertStatsActive => 'Aktywne';

  @override
  String get alertStatsToday => 'Dzisiaj';

  @override
  String get alertStatsThisWeek => 'W tym tygodniu';

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
}
