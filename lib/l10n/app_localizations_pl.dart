// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Otwórz wyszukiwanie';

  @override
  String get fabOpenResults => 'Otwórz wyniki';

  @override
  String get fabRunSearch => 'Uruchom wyszukiwanie';

  @override
  String get fabRefineCriteria => 'Zawęź wyszukiwanie';

  @override
  String get routeSearchPartialBanner => 'Wyszukiwanie kolejnych stacji…';

  @override
  String get searchCriteriaTitle => 'Kryteria wyszukiwania';

  @override
  String get searchCriteriaOpen => 'Szukaj';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'W promieniu $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Dotknij, aby rozpocząć wyszukiwanie';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Zmienić kraj?';

  @override
  String countryChangeBody(String country) {
    return 'Przełączenie na $country zmieni:';
  }

  @override
  String get countryChangeCurrency => 'Waluta';

  @override
  String get countryChangeDistance => 'Odległość';

  @override
  String get countryChangeVolume => 'Objętość';

  @override
  String get countryChangePricePerUnit => 'Format ceny';

  @override
  String get countryChangeNote =>
      'Istniejące ulubione i dzienniki tankowań nie są przepisywane — nowe wpisy używają nowych jednostek.';

  @override
  String get countryChangeConfirm => 'Zmień';

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
  String get cacheTtlGroupNetwork => 'Sieć';

  @override
  String get cacheTtlGroupData => 'Dane';

  @override
  String get cacheTtlGroupGeocoding => 'Geokodowanie';

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
  String get reportThisIssue => 'Zgłoś problem';

  @override
  String get reportAlreadySent => 'Ten problem został już zgłoszony.';

  @override
  String get reportConsentTitle => 'Zgłosić do GitHub?';

  @override
  String get reportConsentBody =>
      'Spowoduje to otwarcie publicznego zgłoszenia na GitHub ze szczegółami błędu poniżej. Nie są dołączane współrzędne GPS, klucze API ani dane osobowe.';

  @override
  String get reportConsentConfirm => 'Otwórz GitHub';

  @override
  String get reportConsentCancel => 'Anuluj';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktywny profil';

  @override
  String get configPreferredFuel => 'Preferowane paliwo';

  @override
  String get configCountry => 'Kraj';

  @override
  String get configRouteSegment => 'Odcinek trasy';

  @override
  String get configApiKeysSection => 'Klucze API';

  @override
  String get configTankerkoenigKey => 'Klucz API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Skonfigurowany';

  @override
  String get configApiKeyNotSet => 'Nie ustawiony (tryb demo)';

  @override
  String get configApiKeyCommunity => 'Domyślny (klucz społecznościowy)';

  @override
  String get searchLocationPlaceholder => 'Adres, kod pocztowy lub miasto';

  @override
  String get configEvKey => 'Klucz API stacji EV';

  @override
  String get configEvKeyCustom => 'Własny klucz';

  @override
  String get configEvKeyShared => 'Domyślny (współdzielony)';

  @override
  String get configCloudSyncSection => 'Synchronizacja w chmurze';

  @override
  String get configTankSyncConnected => 'Połączono';

  @override
  String get configTankSyncDisabled => 'Wyłączono';

  @override
  String get configAuthMode => 'Tryb uwierzytelnienia';

  @override
  String get configAuthEmail => 'E-mail (trwały)';

  @override
  String get configAuthAnonymous => 'Anonimowy (tylko urządzenie)';

  @override
  String get configDatabase => 'Baza danych';

  @override
  String get configPrivacySummary => 'Podsumowanie prywatności';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Ulubione, alerty i ukryte stacje są synchronizowane z Twoją prywatną bazą danych\n• Pozycja GPS i klucze API nigdy nie opuszczają urządzenia\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Wszystkie dane są przechowywane wyłącznie lokalnie na tym urządzeniu\n• Żadne dane nie są wysyłane na serwer\n• Klucze API szyfrowane w bezpiecznym magazynie urządzenia';

  @override
  String get configAuthNoteEmail =>
      'Konto e-mail umożliwia dostęp z wielu urządzeń';

  @override
  String get configAuthNoteAnonymous =>
      'Konto anonimowe — dane powiązane z tym urządzeniem';

  @override
  String get configNone => 'Brak';

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
  String get demoModeBannerAction => 'Pobierz ceny na żywo';

  @override
  String get sortDistance => 'Odległość';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Ocena';

  @override
  String get sortPriceDistance => 'Cena/km';

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
  String get routeModeBannerLabel => 'Tryb trasy — odległości wzdłuż korytarza';

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
  String get routePlanningSection => 'Planowanie trasy';

  @override
  String get routeMinSaving => 'Minimalna oszczędność';

  @override
  String get routeMinSavingOff => 'Wyłączone';

  @override
  String get routeMinSavingOffCaption =>
      'Pokazywanie wszystkich stacji znalezionych na trasie';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Tylko stacje w zakresie $amount od najtańszej na trasie';
  }

  @override
  String get routeDetourBudget => 'Maksymalny objazd';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Pokaż stacje do $km km od trasy bezpośredniej';
  }

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
  String get ignoredStationsLabel => 'Ignorowane';

  @override
  String get ratingsLabel => 'Oceny';

  @override
  String get favoritesDataCache => 'Dane ulubionych';

  @override
  String get citySearchCache => 'Wyszukiwanie miasta';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Usuwanie danych nie jest dostępne w trybie Społeczności. Najpierw rozłącz się lub użyj prywatnej bazy danych.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count śledzonych stacji';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count skonfigurowanych';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count ukrytych stacji';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count ocenionych stacji';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Usuń wszystkie zsynchronizowane trasy';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Usunąć wszystkie zsynchronizowane trasy?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Wszystkie podsumowania tras i szczegółowe dane zostaną usunięte z serwera. Lokalna historia tras na tym urządzeniu nie zostanie naruszona.\n\nTej operacji nie można cofnąć.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Usuń wszystkie';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Wszystkie zsynchronizowane trasy usunięte z serwera';

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
  String get syncedTrips => 'Podróże';

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
  String get account => 'Konto';

  @override
  String get continueAsGuest => 'Kontynuuj jako gość';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get upgradeToEmail => 'Utwórz konto e-mail';

  @override
  String get savedRoutes => 'Zapisane trasy';

  @override
  String get noSavedRoutes => 'Brak zapisanych tras';

  @override
  String get noSavedRoutesHint =>
      'Wyszukaj wzdłuż trasy i zapisz ją, aby mieć szybki dostęp później.';

  @override
  String get saveRoute => 'Zapisz trasę';

  @override
  String get routeName => 'Nazwa trasy';

  @override
  String itineraryDeleted(String name) {
    return '$name usunięto';
  }

  @override
  String loadingRoute(String name) {
    return 'Ładowanie trasy: $name';
  }

  @override
  String get refreshFailed => 'Odświeżanie nie powiodło się. Spróbuj ponownie.';

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
      'Skonfiguruj aplikację w kilku prostych krokach.';

  @override
  String get onboardingApiKeyDescription =>
      'Zarejestruj się, aby uzyskać bezpłatny klucz API, lub pomiń, aby eksplorować aplikację z danymi demo.';

  @override
  String get onboardingComplete => 'Gotowe!';

  @override
  String get onboardingCompleteHint =>
      'Możesz zmienić te ustawienia w dowolnym momencie w swoim profilu.';

  @override
  String get onboardingBack => 'Wstecz';

  @override
  String get onboardingNext => 'Dalej';

  @override
  String get onboardingSkip => 'Pomiń';

  @override
  String get onboardingFinish => 'Rozpocznij';

  @override
  String crossBorderNearby(String country) {
    return '$country w pobliżu';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km do granicy';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Śr. tutaj: $price EUR ($count stacji)';
  }

  @override
  String get allPricesView => 'Wszystkie ceny';

  @override
  String get compactView => 'Kompaktowy';

  @override
  String get switchToAllPricesView => 'Przełącz na widok wszystkich cen';

  @override
  String get switchToCompactView => 'Przełącz na widok kompaktowy';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'Brak w magazynie';

  @override
  String get gdprTitle => 'Twoja prywatność';

  @override
  String get gdprSubtitle =>
      'Ta aplikacja szanuje Twoją prywatność. Wybierz, jakie dane chcesz udostępniać. Możesz zmienić te ustawienia w dowolnym momencie.';

  @override
  String get gdprLocationTitle => 'Dostęp do lokalizacji';

  @override
  String get gdprLocationDescription =>
      'Twoje współrzędne są wysyłane do API cen paliw, aby znaleźć pobliskie stacje. Dane lokalizacji nigdy nie są przechowywane na serwerze i nie są używane do śledzenia.';

  @override
  String get gdprLocationShort =>
      'Znajdź pobliskie stacje paliw używając lokalizacji';

  @override
  String get gdprErrorReportingTitle => 'Raportowanie błędów';

  @override
  String get gdprErrorReportingDescription =>
      'Anonimowe raporty o awariach pomagają ulepszać aplikację. Żadne dane osobowe nie są dołączane. Raporty są wysyłane przez Sentry tylko gdy jest skonfigurowany.';

  @override
  String get gdprErrorReportingShort =>
      'Wysyłaj anonimowe raporty o awariach, aby ulepszyć aplikację';

  @override
  String get gdprCloudSyncTitle => 'Synchronizacja w chmurze';

  @override
  String get gdprCloudSyncDescription =>
      'Synchronizuj ulubione i alerty między urządzeniami przez TankSync. Używa uwierzytelniania anonimowego. Twoje dane są szyfrowane podczas przesyłania.';

  @override
  String get gdprCloudSyncShort =>
      'Synchronizuj ulubione i alerty między urządzeniami';

  @override
  String get gdprLegalBasis =>
      'Podstawa prawna: art. 6 ust. 1 lit. a RODO (zgoda). Możesz wycofać zgodę w dowolnym momencie w Ustawieniach.';

  @override
  String get gdprAcceptAll => 'Akceptuj wszystko';

  @override
  String get gdprAcceptSelected => 'Akceptuj wybrane';

  @override
  String get gdprSettingsHint =>
      'Możesz zmienić swoje ustawienia prywatności w dowolnym momencie.';

  @override
  String get routeSaved => 'Trasa zapisana!';

  @override
  String get routeSaveFailed => 'Nie udało się zapisać trasy';

  @override
  String get sqlCopied => 'SQL skopiowany do schowka';

  @override
  String get connectionDataCopied => 'Dane połączenia skopiowane';

  @override
  String get accountDeleted => 'Konto usunięte. Dane lokalne zachowane.';

  @override
  String get switchedToAnonymous => 'Przełączono na sesję anonimową';

  @override
  String failedToSwitch(String error) {
    return 'Przełączenie nie powiodło się: $error';
  }

  @override
  String get topicUrlCopied => 'URL tematu skopiowany';

  @override
  String get testNotificationSent => 'Testowe powiadomienie wysłane!';

  @override
  String get testNotificationFailed =>
      'Nie udało się wysłać testowego powiadomienia';

  @override
  String get pushUpdateFailed =>
      'Nie udało się zaktualizować ustawień powiadomień push';

  @override
  String get connectedAsGuest => 'Połączono jako gość';

  @override
  String get accountCreated => 'Konto utworzone!';

  @override
  String get signedIn => 'Zalogowano!';

  @override
  String stationHidden(String name) {
    return '$name ukryta';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name usunięta z ulubionych';
  }

  @override
  String invalidApiKey(String error) {
    return 'Nieprawidłowy klucz API: $error';
  }

  @override
  String get invalidQrCode => 'Nieprawidłowy format kodu QR';

  @override
  String get invalidQrCodeTankSync =>
      'Nieprawidłowy kod QR — oczekiwany format TankSync';

  @override
  String get tankSyncConnected => 'TankSync połączony!';

  @override
  String get syncCompleted => 'Synchronizacja zakończona — dane odświeżone';

  @override
  String get deviceCodeCopied => 'Kod urządzenia skopiowany';

  @override
  String get undo => 'Cofnij';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Wprowadź prawidłowy $length-cyfrowy $label';
  }

  @override
  String get freshnessAgo => 'temu';

  @override
  String get freshnessStale => 'Nieaktualne';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Aktualność danych: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Logo $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oceń $count gwiazdkami',
      one: 'Oceń 1 gwiazdką',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Słabe';

  @override
  String get passwordStrengthFair => 'Średnie';

  @override
  String get passwordStrengthStrong => 'Silne';

  @override
  String get passwordReqMinLength => 'Co najmniej 8 znaków';

  @override
  String get passwordReqUppercase => 'Co najmniej 1 wielka litera';

  @override
  String get passwordReqLowercase => 'Co najmniej 1 mała litera';

  @override
  String get passwordReqDigit => 'Co najmniej 1 cyfra';

  @override
  String get passwordReqSpecial => 'Co najmniej 1 znak specjalny';

  @override
  String get passwordTooWeak => 'Hasło nie spełnia wszystkich wymagań';

  @override
  String get brandFilterAll => 'Wszystkie';

  @override
  String get brandFilterNoHighway => 'Bez autostrad';

  @override
  String get swipeTutorialMessage =>
      'Przesuń w prawo, aby nawigować, przesuń w lewo, aby usunąć';

  @override
  String get swipeTutorialDismiss => 'Rozumiem';

  @override
  String get alertStatsActive => 'Aktywne';

  @override
  String get alertStatsToday => 'Dzisiaj';

  @override
  String get alertStatsThisWeek => 'W tym tygodniu';

  @override
  String get privacyDashboardTitle => 'Panel prywatności';

  @override
  String get privacyDashboardSubtitle =>
      'Przeglądaj, eksportuj lub usuń swoje dane';

  @override
  String get privacyDashboardBanner =>
      'Twoje dane należą do Ciebie. Tutaj możesz zobaczyć wszystko, co ta aplikacja przechowuje, wyeksportować to lub usunąć.';

  @override
  String get privacyLocalData => 'Dane na tym urządzeniu';

  @override
  String get privacyIgnoredStations => 'Ukryte stacje';

  @override
  String get privacyRatings => 'Oceny stacji';

  @override
  String get privacyPriceHistory => 'Stacje historii cen';

  @override
  String get privacyProfiles => 'Profile wyszukiwania';

  @override
  String get privacyItineraries => 'Zapisane trasy';

  @override
  String get privacyCacheEntries => 'Wpisy w pamięci podręcznej';

  @override
  String get privacyApiKey => 'Klucz API zapisany';

  @override
  String get privacyEvApiKey => 'Klucz API EV zapisany';

  @override
  String get privacyEstimatedSize => 'Szacowany rozmiar';

  @override
  String get privacySyncedData => 'Synchronizacja w chmurze (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Synchronizacja w chmurze jest wyłączona. Wszystkie dane pozostają wyłącznie na tym urządzeniu.';

  @override
  String get privacySyncMode => 'Tryb synchronizacji';

  @override
  String get privacySyncUserId => 'ID użytkownika';

  @override
  String get privacySyncDescription =>
      'Gdy synchronizacja jest włączona, ulubione, alerty, ukryte stacje i oceny są również przechowywane na serwerze TankSync.';

  @override
  String get privacyViewServerData => 'Wyświetl dane serwera';

  @override
  String get privacyExportButton => 'Eksportuj wszystkie dane jako JSON';

  @override
  String get privacyExportSuccess => 'Dane wyeksportowane do schowka';

  @override
  String get privacyExportCsvButton => 'Eksportuj wszystkie dane jako CSV';

  @override
  String get privacyExportCsvSuccess => 'Dane CSV wyeksportowane do schowka';

  @override
  String get savedToDownloadsFolder => 'Zapisano w folderze Pobrane';

  @override
  String get privacyDeleteButton => 'Usuń wszystkie dane';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Skopiuj dziennik błędów do schowka ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Zapisz dziennik błędów ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Wyczyść dziennik błędów';

  @override
  String get privacyErrorLogCleared => 'Dziennik błędów wyczyszczony';

  @override
  String get privacyDeleteTitle => 'Usunąć wszystkie dane?';

  @override
  String get privacyDeleteBody =>
      'Spowoduje to trwałe usunięcie:\n\n- Wszystkich ulubionych i danych stacji\n- Wszystkich profili wyszukiwania\n- Wszystkich alertów cenowych\n- Całej historii cen\n- Wszystkich danych w pamięci podręcznej\n- Twojego klucza API\n- Wszystkich ustawień aplikacji\n\nAplikacja zostanie zresetowana do stanu początkowego. Tej operacji nie można cofnąć.';

  @override
  String get privacyDeleteConfirm => 'Usuń wszystko';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

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
  String get paymentMethods => 'Metody płatności';

  @override
  String get paymentMethodCash => 'Gotówka';

  @override
  String get paymentMethodCard => 'Karta';

  @override
  String get paymentMethodContactless => 'Zbliżeniowo';

  @override
  String get paymentMethodFuelCard => 'Karta paliwowa';

  @override
  String get paymentMethodApp => 'Aplikacja';

  @override
  String payWithApp(String app) {
    return 'Płać przez $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'W porównaniu do średniej kroczącej z ostatnich 3 tankowań ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Zużycie $value L/100 km, $delta względem Twojej średniej kroczącej';
  }

  @override
  String get drivingMode => 'Tryb jazdy';

  @override
  String get drivingExit => 'Wyjdź';

  @override
  String get drivingNearestStation => 'Najbliższa';

  @override
  String get drivingTapToUnlock => 'Dotknij, aby odblokować';

  @override
  String get drivingSafetyTitle => 'Ostrzeżenie o bezpieczeństwie';

  @override
  String get drivingSafetyMessage =>
      'Nie obsługuj aplikacji podczas jazdy. Zatrzymaj się w bezpiecznym miejscu przed interakcją z ekranem. Kierowca ponosi pełną odpowiedzialność za bezpieczne prowadzenie pojazdu.';

  @override
  String get drivingSafetyAccept => 'Rozumiem';

  @override
  String get voiceAnnouncementsTitle => 'Komunikaty głosowe';

  @override
  String get voiceAnnouncementsDescription =>
      'Ogłaszaj pobliskie tanie stacje podczas jazdy';

  @override
  String get voiceAnnouncementsEnabled => 'Włącz komunikaty głosowe';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Tylko poniżej $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometrów przed Tobą, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Promień ogłoszeń';

  @override
  String get voiceAnnouncementCooldown => 'Interwał powtórzeń';

  @override
  String get nearestStations => 'Najblizsze stacje';

  @override
  String get nearestStationsHint =>
      'Znajdz najblizsze stacje na podstawie Twojej lokalizacji';

  @override
  String get consumptionLogTitle => 'Zużycie paliwa';

  @override
  String get consumptionLogMenuTitle => 'Dziennik zużycia';

  @override
  String get consumptionLogMenuSubtitle =>
      'Śledź tankowania i obliczaj L/100km';

  @override
  String get consumptionStatsTitle => 'Statystyki zużycia';

  @override
  String get addFillUp => 'Dodaj tankowanie';

  @override
  String get noFillUpsTitle => 'Brak tankowań';

  @override
  String get noFillUpsSubtitle =>
      'Zapisz pierwsze tankowanie, aby rozpocząć śledzenie zużycia.';

  @override
  String get fillUpDate => 'Data';

  @override
  String get liters => 'Litry';

  @override
  String get odometerKm => 'Licznik (km)';

  @override
  String get notesOptional => 'Notatki (opcjonalne)';

  @override
  String get stationPreFilled => 'Stacja uzupełniona automatycznie';

  @override
  String get statAvgConsumption => 'Śr. L/100km';

  @override
  String get statAvgCostPerKm => 'Śr. koszt/km';

  @override
  String get statTotalLiters => 'Łącznie litrów';

  @override
  String get statTotalSpent => 'Łącznie wydano';

  @override
  String get statFillUpCount => 'Tankowania';

  @override
  String get fieldRequired => 'Wymagane';

  @override
  String get fieldInvalidNumber => 'Nieprawidłowa liczba';

  @override
  String get carbonDashboardTitle => 'Panel emisji CO2';

  @override
  String get carbonEmptyTitle => 'Brak danych';

  @override
  String get carbonEmptySubtitle =>
      'Zapisuj tankowania, aby zobaczyć panel emisji CO2.';

  @override
  String get carbonSummaryTotalCost => 'Łączny koszt';

  @override
  String get carbonSummaryTotalCo2 => 'Łączne CO2';

  @override
  String get monthlyCostsTitle => 'Miesięczne koszty';

  @override
  String get monthlyEmissionsTitle => 'Miesięczne emisje CO2';

  @override
  String get vehiclesTitle => 'Moje pojazdy';

  @override
  String get vehiclesMenuTitle => 'Moje pojazdy';

  @override
  String get vehiclesMenuSubtitle =>
      'Akumulator, złącza, preferencje ładowania';

  @override
  String get vehiclesEmptyMessage =>
      'Dodaj swój samochód, aby filtrować po złączu i szacować koszty ładowania.';

  @override
  String get vehiclesWizardTitle => 'Moje pojazdy (opcjonalne)';

  @override
  String get vehiclesWizardSubtitle =>
      'Dodaj swój samochód, aby wstępnie wypełnić dziennik zużycia i włączyć filtry złączy EV. Możesz pominąć i dodać pojazdy później.';

  @override
  String get vehiclesWizardNoneYet => 'Brak skonfigurowanego pojazdu.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pojazdy/pojazdów',
      one: '1 pojazd',
    );
    return 'Masz $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Pomiń, aby zakończyć konfigurację — pojazdy możesz dodać w dowolnym momencie z Ustawień.';

  @override
  String get fillUpVehicleLabel => 'Pojazd';

  @override
  String get fillUpVehicleNone => 'Brak pojazdu';

  @override
  String get fillUpVehicleRequired => 'Pojazd jest wymagany';

  @override
  String get reportScanError => 'Zgłoś błąd skanowania';

  @override
  String get pickStationTitle => 'Wybierz stację';

  @override
  String get pickStationHelper =>
      'Rozpocznij tankowanie z wybranej stacji, aby ceny, marka i rodzaj paliwa zostały uzupełnione automatycznie.';

  @override
  String get pickStationEmpty =>
      'Brak ulubionych stacji — dodaj je z Wyszukiwania lub Ulubionych, albo pomiń i wypełnij ręcznie.';

  @override
  String get pickStationSkip => 'Pomiń — dodaj bez stacji';

  @override
  String get scanPump => 'Skanuj dystrybutor';

  @override
  String get scanPayment => 'Skanuj QR płatności';

  @override
  String get qrPaymentBeneficiary => 'Odbiorca';

  @override
  String get qrPaymentAmount => 'Kwota';

  @override
  String get qrPaymentEpcTitle => 'Płatność SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Nie zdekodowano żadnych pól';

  @override
  String get qrPaymentOpenInBank => 'Otwórz w aplikacji bankowej';

  @override
  String get qrPaymentLaunchFailed => 'Brak aplikacji do otwarcia tego kodu';

  @override
  String get qrPaymentUnknownTitle => 'Nierozpoznany kod';

  @override
  String get qrPaymentCopyRaw => 'Kopiuj tekst surowy';

  @override
  String get qrPaymentCopiedRaw => 'Skopiowano do schowka';

  @override
  String get qrPaymentReport => 'Zgłoś to skanowanie';

  @override
  String get qrPaymentEpcCopied =>
      'Dane bankowe skopiowane — wklej do aplikacji bankowej';

  @override
  String get qrScannerGuidance => 'Skieruj kamerę na kod QR';

  @override
  String get qrScannerPermissionDenied =>
      'Dostęp do kamery jest potrzebny do skanowania kodów QR.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Dostęp do kamery został odmówiony. Otwórz ustawienia, aby go przyznać.';

  @override
  String get qrScannerRetryPermission => 'Spróbuj ponownie';

  @override
  String get qrScannerOpenSettings => 'Otwórz ustawienia';

  @override
  String get qrScannerTimeout =>
      'Nie wykryto kodu QR. Przybliż lub spróbuj ponownie.';

  @override
  String get qrScannerRetry => 'Spróbuj ponownie';

  @override
  String get torchOn => 'Włącz latarkę';

  @override
  String get torchOff => 'Wyłącz latarkę';

  @override
  String get obdNoAdapter => 'Brak adaptera OBD2 w zasięgu';

  @override
  String get obdOdometerUnavailable => 'Nie można odczytać licznika';

  @override
  String get obdPermissionDenied =>
      'Przyznaj uprawnienie Bluetooth w ustawieniach systemowych';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter nie odpowiada — włącz zapłon i spróbuj ponownie';

  @override
  String get obdPickerTitle => 'Wybierz adapter OBD2';

  @override
  String get obdPickerScanning => 'Skanowanie w poszukiwaniu adapterów…';

  @override
  String get obdPickerConnecting => 'Łączenie…';

  @override
  String get themeSettingTitle => 'Motyw';

  @override
  String get themeModeLight => 'Jasny';

  @override
  String get themeModeDark => 'Ciemny';

  @override
  String get themeModeSystem => 'Zgodnie z systemem';

  @override
  String get tripRecordingTitle => 'Nagrywanie trasy';

  @override
  String get tripSummaryTitle => 'Podsumowanie trasy';

  @override
  String get tripMetricDistance => 'Dystans';

  @override
  String get tripMetricSpeed => 'Prędkość';

  @override
  String get tripMetricFuelUsed => 'Zużyte paliwo';

  @override
  String get tripMetricAvgConsumption => 'Śr.';

  @override
  String get tripMetricElapsed => 'Czas';

  @override
  String get tripMetricOdometer => 'Licznik';

  @override
  String get tripStop => 'Zatrzymaj nagrywanie';

  @override
  String get tripPause => 'Pauza';

  @override
  String get tripResume => 'Wznów';

  @override
  String get tripBannerRecording => 'Nagrywanie trasy';

  @override
  String get tripBannerPaused => 'Trasa wstrzymana — dotknij, aby wznowić';

  @override
  String get navConsumption => 'Zużycie';

  @override
  String get vehicleBaselineSectionTitle => 'Kalibracja bazowa';

  @override
  String get vehicleBaselineEmpty =>
      'Brak próbek — rozpocznij trasę OBD2, aby zacząć poznawać profil paliwowy tego pojazdu.';

  @override
  String get vehicleBaselineProgress =>
      'Nauczono z próbek z różnych sytuacji jazdy.';

  @override
  String get vehicleBaselineReset => 'Resetuj bazę sytuacji jazdy';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Resetować bazę sytuacji jazdy?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Spowoduje to usunięcie wszystkich nauczonych próbek dla tego pojazdu. Powrócisz do domyślnych ustawień zimnego startu, dopóki nowe trasy nie wypełnią profilu.';

  @override
  String get vehicleAdapterSectionTitle => 'Adapter OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Brak sparowanego adaptera. Sparuj go, aby aplikacja mogła automatycznie ponownie połączyć się następnym razem.';

  @override
  String get vehicleAdapterUnnamed => 'Nieznany adapter';

  @override
  String get vehicleAdapterPair => 'Sparuj adapter';

  @override
  String get vehicleAdapterForget => 'Zapomnij adapter';

  @override
  String get achievementsTitle => 'Osiągnięcia';

  @override
  String get achievementFirstTrip => 'Pierwsza trasa';

  @override
  String get achievementFirstTripDesc => 'Nagraj swoją pierwszą trasę OBD2.';

  @override
  String get achievementFirstFillUp => 'Pierwsze tankowanie';

  @override
  String get achievementFirstFillUpDesc => 'Zapisz swoje pierwsze tankowanie.';

  @override
  String get achievementTenTrips => '10 tras';

  @override
  String get achievementTenTripsDesc => 'Nagraj 10 tras OBD2.';

  @override
  String get achievementZeroHarsh => 'Płynna jazda';

  @override
  String get achievementZeroHarshDesc =>
      'Przejedź trasę 10 km lub więcej bez gwałtownego hamowania ani przyspieszania.';

  @override
  String get achievementEcoWeek => 'Eco tydzień';

  @override
  String get achievementEcoWeekDesc =>
      'Jedź 7 kolejnych dni z co najmniej jedną płynną trasą każdego dnia.';

  @override
  String get achievementPriceWin => 'Trafna cena';

  @override
  String get achievementPriceWinDesc =>
      'Zapisz tankowanie o co najmniej 5% poniżej 30-dniowej średniej stacji.';

  @override
  String get syncBaselinesToggleTitle => 'Udostępnij nauczone profile pojazdu';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Prześlij bazowe zużycie paliwa per pojazd, aby drugie urządzenie mogło z nich korzystać.';

  @override
  String get obd2StatusConnected => 'Adapter OBD2: połączony';

  @override
  String get obd2StatusAttempting => 'Adapter OBD2: łączenie';

  @override
  String get obd2StatusUnreachable => 'Adapter OBD2: nieosiągalny';

  @override
  String get obd2StatusPermissionDenied =>
      'Adapter OBD2: wymagane uprawnienie Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Gotowy do nagrywania trasy.';

  @override
  String get obd2StatusAttemptingBody => 'Łączenie w tle…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter poza zasięgiem lub używany przez inną aplikację.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Przyznaj uprawnienie Bluetooth w ustawieniach systemowych, aby automatycznie ponownie łączyć.';

  @override
  String get obd2StatusNoAdapter => 'Brak sparowanego adaptera';

  @override
  String get obd2StatusForget => 'Zapomnij adapter';

  @override
  String get tripHistoryTitle => 'Historia tras';

  @override
  String get tripHistoryEmptyTitle => 'Brak tras';

  @override
  String get tripHistoryEmptySubtitle =>
      'Podłącz adapter OBD2 i nagraj trasę, aby rozpocząć budowanie historii jazdy.';

  @override
  String get tripHistoryUnknownDate => 'Nieznana data';

  @override
  String get situationIdle => 'Bieg jałowy';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Miejski';

  @override
  String get situationHighway => 'Autostrada';

  @override
  String get situationDecel => 'Hamowanie';

  @override
  String get situationClimbing => 'Podjazd / obciążenie';

  @override
  String get situationHardAccel => 'Gwałtowne przyspieszenie';

  @override
  String get situationFuelCut => 'Odcięcie paliwa — wybieg';

  @override
  String get tripSaveAsFillUp => 'Zapisz jako tankowanie';

  @override
  String get tripSaveRecording => 'Zapisz trasę';

  @override
  String get tripDiscard => 'Odrzuć';

  @override
  String obdOdometerRead(int km) {
    return 'Odczytany licznik: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nie ustawiono';

  @override
  String get wizardVehicleTapToEdit => 'Dotknij, aby edytować';

  @override
  String get wizardVehicleDefaultBadge => 'Domyślny';

  @override
  String get wizardProfileChoiceHint =>
      'Wybierz, jak chcesz korzystać z aplikacji. Możesz to zmienić później w Ustawieniach.';

  @override
  String get wizardProfileChoiceFooter =>
      'Możesz zmienić swój wybór w dowolnym momencie w Ustawienia → Tryb użytkowania.';

  @override
  String get wizardProfileBasicName => 'Podstawowy';

  @override
  String get wizardProfileBasicDescription =>
      'Najtańsze paliwo i ceny ładowania EV w pobliżu. Ulubione i alerty cenowe.';

  @override
  String get wizardProfileMediumName => 'Średni';

  @override
  String get wizardProfileMediumDescription =>
      'Wszystko z Podstawowego, plus śledzenie tankowań i ładowania EV ręcznie.';

  @override
  String get wizardProfileFullName => 'Pełny';

  @override
  String get wizardProfileFullDescription =>
      'Wszystko ze Średniego, plus automatyczne nagrywanie tras OBD2, wyniki jazdy i karty lojalnościowe.';

  @override
  String get wizardProfileCustomName => 'Własny';

  @override
  String get wizardProfileCustomDescription =>
      'Własna kombinacja funkcji. Dostosuj każdy przełącznik poniżej.';

  @override
  String get useModeSectionHint =>
      'Dopasuj aplikację do swojego stylu użytkowania. Wybór predefiniowanego zestawu włącza odpowiedni zestaw funkcji.';

  @override
  String get useModeCustomSettingsDescription =>
      'Twój zestaw funkcji nie pasuje do żadnego predefiniowanego. Wybierz jeden powyżej, aby nadpisać, lub kontynuuj dostosowywanie poszczególnych funkcji w sekcji poniżej.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Tryb użytkowania ustawiony na $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Domyślny pojazd (opcjonalnie)';

  @override
  String get profileDefaultVehicleNone => 'Brak domyślnego';

  @override
  String get profileFuelFromVehicleHint =>
      'Rodzaj paliwa jest określany na podstawie domyślnego pojazdu. Usuń pojazd, aby wybrać paliwo bezpośrednio.';

  @override
  String get consumptionNoVehicleTitle => 'Najpierw dodaj pojazd';

  @override
  String get consumptionNoVehicleBody =>
      'Tankowania są przypisywane do pojazdu. Dodaj swój samochód, aby zacząć rejestrować zużycie.';

  @override
  String get vehicleAdd => 'Dodaj pojazd';

  @override
  String get vehicleAddTitle => 'Dodaj pojazd';

  @override
  String get vehicleEditTitle => 'Edytuj pojazd';

  @override
  String get vehicleDeleteTitle => 'Usunąć pojazd?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Usunąć \"$name\" z Twoich profili?';
  }

  @override
  String get vehicleNameLabel => 'Nazwa';

  @override
  String get vehicleNameHint => 'np. Moja Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Spalinowy';

  @override
  String get vehicleTypeHybrid => 'Hybrydowy';

  @override
  String get vehicleTypeEv => 'Elektryczny';

  @override
  String get vehicleEvSectionTitle => 'Elektryczny';

  @override
  String get vehicleCombustionSectionTitle => 'Spalinowy';

  @override
  String get vehicleBatteryLabel => 'Pojemność akumulatora (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Maksymalna moc ładowania (kW)';

  @override
  String get vehicleConnectorsLabel => 'Obsługiwane złącza';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Maks SoC %';

  @override
  String get vehicleTankLabel => 'Pojemność baku (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Preferowane paliwo';

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
  String get connectorThreePin => '3-pin';

  @override
  String get evShowOnMap => 'Pokaż stacje EV';

  @override
  String get evAvailableOnly => 'Tylko dostępne';

  @override
  String get evMinPower => 'Min moc';

  @override
  String get evMaxPower => 'Maks moc';

  @override
  String get evOperator => 'Operator';

  @override
  String get evLastUpdate => 'Ostatnia aktualizacja';

  @override
  String get evStatusAvailable => 'Dostępna';

  @override
  String get evStatusOccupied => 'Zajęta';

  @override
  String get evStatusOutOfOrder => 'Awaria';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Tylko otwarte';

  @override
  String get saveAsDefaults => 'Zapisz jako moje domyślne';

  @override
  String get criteriaSavedToProfile => 'Zapisano jako domyślne';

  @override
  String get profileNotFound => 'Brak aktywnego profilu';

  @override
  String get updatingFavorites => 'Aktualizowanie ulubionych...';

  @override
  String get fetchingLatestPrices => 'Pobieranie najnowszych cen';

  @override
  String get noDataAvailable => 'Brak danych';

  @override
  String get configAndPrivacy => 'Konfiguracja i prywatność';

  @override
  String get searchToSeeMap => 'Wyszukaj, aby zobaczyć stacje na mapie';

  @override
  String get evPowerAny => 'Dowolna';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Lokalizacja';

  @override
  String get tooltipBack => 'Wstecz';

  @override
  String get tooltipClose => 'Zamknij';

  @override
  String get tooltipShare => 'Udostępnij';

  @override
  String get tooltipClearSearch => 'Wyczyść wyszukiwanie';

  @override
  String get minimalDriveInstantConsumption => 'Chwilowe zużycie';

  @override
  String get coachingShiftUp => 'Zmień bieg w górę';

  @override
  String get coachingShiftDown => 'Zmień bieg w dół';

  @override
  String get coachingEasePedal => 'Puść gaz';

  @override
  String get tooltipUseGps => 'Użyj lokalizacji GPS';

  @override
  String get tooltipShowPassword => 'Pokaż hasło';

  @override
  String get tooltipHidePassword => 'Ukryj hasło';

  @override
  String get evConnectorsLabel => 'Dostępne złącza';

  @override
  String get evConnectorsNone => 'Brak informacji o złączach';

  @override
  String get switchToEmail => 'Przełącz na e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Zachowaj dane, zaloguj się z innych urządzeń';

  @override
  String get switchToAnonymousAction => 'Przełącz na anonimowy';

  @override
  String get switchToAnonymousSubtitle =>
      'Zachowaj dane lokalne, użyj nowej sesji anonimowej';

  @override
  String get linkDevice => 'Połącz urządzenie';

  @override
  String get shareDatabase => 'Udostępnij bazę danych';

  @override
  String get disconnectAction => 'Rozłącz';

  @override
  String get disconnectSubtitle =>
      'Zatrzymaj synchronizację (dane lokalne zachowane)';

  @override
  String get deleteAccountAction => 'Usuń konto';

  @override
  String get deleteAccountSubtitle => 'Trwale usuń wszystkie dane z serwera';

  @override
  String get localOnly => 'Tylko lokalnie';

  @override
  String get localOnlySubtitle =>
      'Opcjonalne: synchronizuj ulubione, alerty i oceny między urządzeniami';

  @override
  String get setupCloudSync => 'Skonfiguruj synchronizację w chmurze';

  @override
  String get disconnectTitle => 'Odłączyć TankSync?';

  @override
  String get disconnectBody =>
      'Synchronizacja w chmurze zostanie wyłączona. Twoje dane lokalne (ulubione, alerty, historia) są zachowane na tym urządzeniu. Dane serwera nie są usuwane.';

  @override
  String get deleteAccountTitle => 'Usunąć konto?';

  @override
  String get deleteAccountBody =>
      'Spowoduje to trwałe usunięcie wszystkich Twoich danych z serwera (ulubione, alerty, oceny, trasy). Dane lokalne na tym urządzeniu są zachowane.\n\nTej operacji nie można cofnąć.';

  @override
  String get switchToAnonymousTitle => 'Przełączyć na anonimowy?';

  @override
  String get switchToAnonymousBody =>
      'Zostaniesz wylogowany z konta e-mail i będziesz kontynuować z nową sesją anonimową.\n\nTwoje dane lokalne (ulubione, alerty) są zachowane na tym urządzeniu i zostaną zsynchronizowane z nowym kontem anonimowym.';

  @override
  String get switchAction => 'Przełącz';

  @override
  String get helpBannerCriteria =>
      'Domyślne wartości profilu są wstępnie wypełnione. Dostosuj kryteria poniżej, aby doprecyzować wyszukiwanie.';

  @override
  String get helpBannerAlerts =>
      'Ustaw próg cenowy dla stacji. Otrzymasz powiadomienie, gdy ceny spadną poniżej niego. Sprawdzanie odbywa się co 30 minut.';

  @override
  String get helpBannerConsumption =>
      'Zapisuj każde tankowanie, aby śledzić realne zużycie paliwa i ślad CO₂. Przesuń w lewo, aby usunąć wpis.';

  @override
  String get helpBannerVehicles =>
      'Dodaj swoje pojazdy, aby tankowania i preferencje paliwa były wypełniane poprawnie domyślnie. Pierwszy pojazd staje się domyślnym.';

  @override
  String get syncNow => 'Synchronizuj teraz';

  @override
  String get onboardingPreferencesTitle => 'Twoje preferencje';

  @override
  String get onboardingZipHelper => 'Używane gdy GPS jest niedostępny';

  @override
  String get onboardingRadiusHelper => 'Większy promień = więcej wyników';

  @override
  String get onboardingPrivacy =>
      'Te ustawienia są przechowywane tylko na Twoim urządzeniu i nigdy nie są udostępniane.';

  @override
  String get onboardingLandingTitle => 'Ekran główny';

  @override
  String get onboardingLandingHint =>
      'Wybierz, który ekran otwiera się po uruchomieniu aplikacji.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Nie wychodź z aplikacji — ale jej nie zamykaj.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Otwórz Sparkilo raz po każdym restarcie.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple uruchamia Sparkilo tylko po tym, jak otworzyłeś go co najmniej raz od czasu ponownego uruchomienia telefonu. Potem Twoje trasy są nagrywane automatycznie.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Nie usuwaj Sparkilo z przełącznika aplikacji.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      'Opcja \'Wymuś zamknięcie\' powoduje, że iOS przestaje uruchamiać aplikację ponownie. Nagrywanie tras zostanie wstrzymane, dopóki ponownie nie otworzysz Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Gdy iOS pyta o dostęp do lokalizacji \'Zawsze\', prosimy odpowiedzieć tak.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Mechanizm zapasowy nagrywający Twoją trasę, gdy adapter OBD2 jest wolny, potrzebuje lokalizacji w tle. Nigdy jej nie udostępniamy.';

  @override
  String get scanReceipt => 'Skanuj paragon';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Paliwo';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Autostrada';

  @override
  String get ratingModeLocal => 'Lokalny';

  @override
  String get ratingModePrivate => 'Prywatny';

  @override
  String get ratingModeShared => 'Udostępniony';

  @override
  String get ratingDescLocal => 'Oceny zapisane tylko na tym urządzeniu';

  @override
  String get ratingDescPrivate =>
      'Zsynchronizowane z Twoją bazą danych (niewidoczne dla innych)';

  @override
  String get ratingDescShared =>
      'Widoczne dla wszystkich użytkowników Twojej bazy danych';

  @override
  String get errorNoEvApiKey =>
      'Klucz API OpenChargeMap nie jest skonfigurowany. Dodaj go w Ustawieniach, aby wyszukiwać stacje ładowania EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Dostawca danych ($host) udostępnia wygasły lub nieprawidłowy certyfikat TLS. Aplikacja nie może załadować danych z tego źródła, dopóki dostawca to nie naprawi. Skontaktuj się z $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed niedostępne. Używam $current.';
  }

  @override
  String get errorTitleApiKey => 'Wymagany klucz API';

  @override
  String get errorTitleLocation => 'Lokalizacja niedostępna';

  @override
  String get errorHintNoStations =>
      'Spróbuj zwiększyć promień wyszukiwania lub szukaj w innej lokalizacji.';

  @override
  String get errorHintApiKey => 'Skonfiguruj klucz API w Ustawieniach.';

  @override
  String get errorHintConnection =>
      'Sprawdź połączenie z internetem i spróbuj ponownie.';

  @override
  String get errorHintRouting =>
      'Obliczenie trasy nie powiodło się. Sprawdź połączenie z internetem i spróbuj ponownie.';

  @override
  String get errorHintFallback =>
      'Spróbuj ponownie lub wyszukaj wg kodu pocztowego / nazwy miasta.';

  @override
  String get alertsLoadErrorTitle => 'Nie można załadować alertów';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Błąd sprawdzania alertów w tle';

  @override
  String get detailsLabel => 'Szczegóły';

  @override
  String get remove => 'Usuń';

  @override
  String get showKey => 'Pokaż klucz';

  @override
  String get hideKey => 'Ukryj klucz';

  @override
  String get syncOptionalTitle => 'TankSync jest opcjonalny';

  @override
  String get syncOptionalDescription =>
      'Aplikacja działa w pełni bez synchronizacji w chmurze. TankSync pozwala synchronizować ulubione, alerty i oceny między urządzeniami za pomocą Supabase (dostępny bezpłatny plan).';

  @override
  String get syncHowToConnectQuestion => 'Jak chcesz się połączyć?';

  @override
  String get syncCreateOwnTitle => 'Utwórz własną bazę danych';

  @override
  String get syncCreateOwnSubtitle =>
      'Bezpłatny projekt Supabase — przeprowadzimy Cię krok po kroku';

  @override
  String get syncJoinExistingTitle => 'Dołącz do istniejącej bazy danych';

  @override
  String get syncJoinExistingSubtitle =>
      'Zeskanuj kod QR od właściciela bazy lub wklej dane logowania';

  @override
  String get syncChooseAccountType => 'Wybierz typ konta';

  @override
  String get syncAccountTypeAnonymous => 'Anonimowy';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Natychmiastowy, bez e-maila. Dane powiązane z tym urządzeniem.';

  @override
  String get syncAccountTypeEmail => 'Konto e-mail';

  @override
  String get syncAccountTypeEmailDesc =>
      'Zaloguj się z dowolnego urządzenia. Odzyskaj dane w razie utraty telefonu.';

  @override
  String get syncHaveAccountSignIn => 'Masz już konto? Zaloguj się';

  @override
  String get syncCreateNewAccount => 'Utwórz nowe konto';

  @override
  String get syncTestConnection => 'Testuj połączenie';

  @override
  String get syncTestingConnection => 'Testowanie...';

  @override
  String get syncConnectButton => 'Połącz';

  @override
  String get syncConnectingButton => 'Łączenie...';

  @override
  String get syncDatabaseReady => 'Baza danych gotowa!';

  @override
  String get syncDatabaseNeedsSetup => 'Baza danych wymaga konfiguracji';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Brak';

  @override
  String get syncSqlEditorInstructions =>
      'Skopiuj poniższy SQL i uruchom go w edytorze SQL Supabase (Panel → Edytor SQL → Nowe zapytanie → Wklej → Uruchom)';

  @override
  String get syncCopySqlButton => 'Kopiuj SQL do schowka';

  @override
  String get syncRecheckSchemaButton => 'Sprawdź ponownie schemat';

  @override
  String get syncDoneButton => 'Gotowe';

  @override
  String syncSignedInAs(String email) {
    return 'Zalogowano jako $email';
  }

  @override
  String get syncEmailDescription =>
      'Twoje dane są synchronizowane na wszystkich urządzeniach z tym e-mailem.';

  @override
  String get syncSwitchToAnonymousTitle => 'Przełącz na anonimowy';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Kontynuuj bez e-maila, nowa sesja anonimowa';

  @override
  String get syncGuestDescription => 'Anonimowy, bez e-maila.';

  @override
  String get syncOrDivider => 'lub';

  @override
  String get syncHowToSyncQuestion => 'Jak chcesz synchronizować?';

  @override
  String get syncOfflineDescription =>
      'Aplikacja działa w pełni offline. Synchronizacja w chmurze jest opcjonalna.';

  @override
  String get syncModeCommunityTitle => 'Społeczność Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Udostępnij ulubione i oceny wszystkim użytkownikom';

  @override
  String get syncModePrivateTitle => 'Prywatna baza danych';

  @override
  String get syncModePrivateSubtitle =>
      'Twój własny Supabase — pełna kontrola nad danymi';

  @override
  String get syncModeGroupTitle => 'Dołącz do grupy';

  @override
  String get syncModeGroupSubtitle =>
      'Współdzielona baza danych rodziny lub znajomych';

  @override
  String get syncPrivacyShared => 'Udostępniony';

  @override
  String get syncPrivacyPrivate => 'Prywatny';

  @override
  String get syncPrivacyGroup => 'Grupa';

  @override
  String get syncStayOfflineButton => 'Pozostań offline';

  @override
  String get syncSuccessTitle => 'Połączono pomyślnie!';

  @override
  String get syncSuccessDescription =>
      'Twoje dane będą teraz synchronizowane automatycznie.';

  @override
  String get syncWizardTitleConnect => 'Połącz TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Twoja baza danych';

  @override
  String get syncSetupTitleJoinGroup => 'Dołącz do grupy';

  @override
  String get syncSetupTitleAccount => 'Twoje konto';

  @override
  String get syncWizardBack => 'Wstecz';

  @override
  String get syncWizardNext => 'Dalej';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Utwórz projekt Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Dotknij «Otwórz Supabase» poniżej\n2. Utwórz bezpłatne konto (jeśli go nie masz)\n3. Kliknij «Nowy projekt»\n4. Wybierz nazwę i region\n5. Poczekaj ~2 minuty na uruchomienie';

  @override
  String get syncWizardOpenSupabase => 'Otwórz Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Włącz logowanie anonimowe';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. W panelu Supabase:\n   Uwierzytelnianie → Dostawcy\n2. Znajdź «Logowanie anonimowe»\n3. Włącz przełącznik\n4. Kliknij «Zapisz»';

  @override
  String get syncWizardOpenAuthSettings => 'Otwórz ustawienia uwierzytelniania';

  @override
  String get syncWizardCopyCredentialsTitle => 'Skopiuj dane logowania';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Przejdź do Ustawienia → API w panelu\n2. Skopiuj «Adres URL projektu»\n3. Skopiuj klucz «anon public»\n4. Wklej je poniżej';

  @override
  String get syncWizardOpenApiSettings => 'Otwórz ustawienia API';

  @override
  String get syncWizardSupabaseUrlLabel => 'Adres URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://twoj-projekt.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Dołącz do istniejącej bazy danych';

  @override
  String get syncWizardScanQrCode => 'Skanuj kod QR';

  @override
  String get syncWizardAskOwnerQr =>
      'Poproś właściciela bazy, aby pokazał Ci swój kod QR\n(Ustawienia → TankSync → Udostępnij)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Poproś właściciela bazy o pokazanie kodu QR';

  @override
  String get syncWizardEnterManuallyTitle => 'Wprowadź ręcznie';

  @override
  String get syncWizardOrEnterManually => 'lub wprowadź ręcznie';

  @override
  String get syncWizardUrlHelperText =>
      'Spacje i podziały wierszy są usuwane automatycznie';

  @override
  String get syncCredentialsPrivateHint =>
      'Wprowadź dane logowania projektu Supabase. Znajdziesz je w panelu w Ustawienia > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Adres URL bazy danych';

  @override
  String get syncCredentialsAccessKeyLabel => 'Klucz dostępu';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Hasło';

  @override
  String get authConfirmPasswordLabel => 'Potwierdź hasło';

  @override
  String get authPleaseEnterEmail => 'Wprowadź adres e-mail';

  @override
  String get authInvalidEmail => 'Nieprawidłowy adres e-mail';

  @override
  String get authPasswordsDoNotMatch => 'Hasła nie są zgodne';

  @override
  String get authConnectAnonymously => 'Połącz anonimowo';

  @override
  String get authCreateAccountAndConnect => 'Utwórz konto i połącz';

  @override
  String get authSignInAndConnect => 'Zaloguj się i połącz';

  @override
  String get authAnonymousSegment => 'Anonimowy';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Natychmiastowy dostęp, bez e-maila. Dane powiązane z tym urządzeniem.';

  @override
  String get authEmailDescription =>
      'Zaloguj się z dowolnego urządzenia. Odzyskaj dane w razie utraty telefonu.';

  @override
  String get authSyncAcrossDevices =>
      'Automatycznie synchronizuj dane na wszystkich swoich urządzeniach.';

  @override
  String get authNewHereCreateAccount => 'Nowy użytkownik? Utwórz konto';

  @override
  String get linkDeviceScreenTitle => 'Połącz urządzenie';

  @override
  String get linkDeviceThisDeviceLabel => 'To urządzenie';

  @override
  String get linkDeviceShareCodeHint =>
      'Udostępnij ten kod na swoim innym urządzeniu:';

  @override
  String get linkDeviceNotConnected => 'Niepołączone';

  @override
  String get linkDeviceCopyCodeTooltip => 'Kopiuj kod';

  @override
  String get linkDeviceImportSectionTitle => 'Importuj z innego urządzenia';

  @override
  String get linkDeviceImportDescription =>
      'Wprowadź kod urządzenia z innego urządzenia, aby zaimportować jego ulubione, alerty, pojazdy i dziennik zużycia. Każde urządzenie zachowuje własny profil i ustawienia domyślne.';

  @override
  String get linkDeviceCodeFieldLabel => 'Kod urządzenia';

  @override
  String get linkDeviceCodeFieldHint => 'Wklej UUID z innego urządzenia';

  @override
  String get linkDeviceImportButton => 'Importuj dane';

  @override
  String get linkDeviceHowItWorksTitle => 'Jak to działa';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Na Urządzeniu A: skopiuj powyższy kod urządzenia\n2. Na Urządzeniu B: wklej go w pole «Kod urządzenia»\n3. Dotknij «Importuj dane», aby połączyć ulubione, alerty, pojazdy i dzienniki zużycia\n4. Oba urządzenia będą miały wszystkie połączone dane\n\nKażde urządzenie zachowuje własną tożsamość anonimową i własny profil (preferowane paliwo, domyślny pojazd, ekran startowy). Dane są łączone, nie przenoszone.';

  @override
  String get vehicleSetActive => 'Ustaw jako aktywny';

  @override
  String get swipeHide => 'Ukryj';

  @override
  String get evChargingSection => 'Ładowanie EV';

  @override
  String get fuelStationsSection => 'Stacje paliw';

  @override
  String get yourRating => 'Twoja ocena';

  @override
  String get noStorageUsed => 'Brak zużytego miejsca';

  @override
  String get aboutReportBug => 'Zgłoś błąd / Zasugeruj funkcję';

  @override
  String get aboutSupportProject => 'Wesprzyj ten projekt';

  @override
  String get aboutSupportDescription =>
      'Ta aplikacja jest bezpłatna, open source i nie zawiera reklam. Jeśli uważasz ją za przydatną, rozważ wsparcie dewelopera.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Ceny paliw w Luksemburgu są regulowane przez rząd i jednolite w całym kraju.';

  @override
  String get luxembourgFuelUnleaded95 => 'Bezołowiowa 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Bezołowiowa 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Regulowane ceny paliw w Luksemburgu są niedostępne.';

  @override
  String get reportIssueTitle => 'Zgłoś problem';

  @override
  String get enterCorrection => 'Wprowadź korektę';

  @override
  String get reportNoBackendAvailable =>
      'Nie można wysłać zgłoszenia: dla tego kraju nie skonfigurowano usługi raportowania. Włącz TankSync w Ustawieniach, aby wysyłać zgłoszenia społecznościowe.';

  @override
  String get correctName => 'Popraw nazwę stacji';

  @override
  String get correctAddress => 'Popraw adres';

  @override
  String get wrongE85Price => 'Błędna cena E85';

  @override
  String get wrongE98Price => 'Błędna cena Super 98';

  @override
  String get wrongLpgPrice => 'Błędna cena LPG';

  @override
  String get wrongStationName => 'Błędna nazwa stacji';

  @override
  String get wrongStationAddress => 'Błędny adres';

  @override
  String get independentStation => 'Niezależna stacja';

  @override
  String get serviceRemindersSection => 'Przypomnienia serwisowe';

  @override
  String get serviceRemindersEmpty =>
      'Brak przypomnień — wybierz szablon powyżej.';

  @override
  String get addServiceReminder => 'Dodaj przypomnienie';

  @override
  String get serviceReminderPresetOil => 'Olej (15 000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Wymiana oleju';

  @override
  String get serviceReminderPresetTires => 'Opony (20 000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Opony';

  @override
  String get serviceReminderPresetInspection => 'Przegląd (30 000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Przegląd';

  @override
  String get serviceReminderLabel => 'Etykieta';

  @override
  String get serviceReminderInterval => 'Interwał (km)';

  @override
  String get serviceReminderLastService => 'Ostatni serwis';

  @override
  String get serviceReminderMarkDone => 'Oznacz jako wykonane';

  @override
  String get serviceReminderDueTitle => 'Czas na serwis';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return 'Nadszedł czas na: $label — $kmOver km po interwale.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Zarejestruj się w OPINET, aby uzyskać bezpłatny klucz API';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Zarejestruj się w CNE, aby uzyskać bezpłatny klucz API';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Czy to Twój samochód?';

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
      'Częściowe informacje (offline). Możesz edytować poniżej.';

  @override
  String get vinDecodeError => 'Nie można zdekodować tego VIN';

  @override
  String get vinInvalidFormat => 'Nieprawidłowy format VIN';

  @override
  String get obd2PauseBannerTitle =>
      'Połączenie OBD2 utracone — nagrywanie wstrzymane';

  @override
  String get obd2PauseBannerResume => 'Wznów nagrywanie';

  @override
  String get obd2PauseBannerEnd => 'Zakończ nagrywanie';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Aktualizacja kalibracji zużycia dla $vehicleName — dokładność poprawiona o $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Resetować sprawność objętościową?';

  @override
  String get veResetConfirmBody =>
      'Spowoduje to odrzucenie nauczonych wartości sprawności objętościowej (η_v) i przywrócenie wartości domyślnej (0,85). Szacunki przepływu paliwa na poziomie trasy powrócą do stałej producenta, dopóki kalibracja nie zbierze nowych próbek z kolejnych tras.';

  @override
  String get alertsRadiusSectionTitle => 'Alerty radiusowe';

  @override
  String get alertsRadiusAdd => 'Dodaj alert radiusowy';

  @override
  String get alertsRadiusEmptyTitle => 'Brak alertów radiusowych';

  @override
  String get alertsRadiusEmptyCta => 'Utwórz alert radiusowy';

  @override
  String get alertsRadiusCreateTitle => 'Utwórz alert radiusowy';

  @override
  String get alertsRadiusLabelHint => 'Etykieta (np. Dom diesel)';

  @override
  String get alertsRadiusFuelType => 'Rodzaj paliwa';

  @override
  String get alertsRadiusThreshold => 'Próg (€/L)';

  @override
  String get alertsRadiusKm => 'Promień (km)';

  @override
  String get alertsRadiusCenterGps => 'Użyj mojej lokalizacji';

  @override
  String get alertsRadiusCenterPostalCode => 'Kod pocztowy';

  @override
  String get alertsRadiusSave => 'Zapisz';

  @override
  String get alertsRadiusCancel => 'Anuluj';

  @override
  String get alertsRadiusDeleteConfirm => 'Usunąć alert radiusowy?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 połączony: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Sparuj adapter OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel potaniało w pobliskich stacjach';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stacji obniżyło ceny o $maxDropCents¢ w ostatniej godzinie';
  }

  @override
  String get fillUpSavedSnackbar => 'Tankowanie zapisane';

  @override
  String get radiusAlertsEntryTitle => 'Alerty radiusowe i statystyki';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Otrzymuj powiadomienia, gdy ceny spadną w pobliżu';

  @override
  String get notFoundTitle => 'Strona nie znaleziona';

  @override
  String notFoundBody(String location) {
    return '«$location» nie znaleziono.';
  }

  @override
  String get notFoundHomeButton => 'Strona główna';

  @override
  String get consumptionTabHiddenNotice =>
      'Karta Zużycie jest ukryta przez ustawienia profilu.';

  @override
  String get swipeBetweenTabsHint =>
      'Wskazówka: przesuń w lewo lub prawo, aby przełączać karty.';

  @override
  String get discardChangesTitle => 'Odrzucić zmiany?';

  @override
  String get discardChangesBody =>
      'Masz niezapisane zmiany. Wyjście spowoduje ich utratę.';

  @override
  String get discardChangesConfirm => 'Odrzuć';

  @override
  String get discardChangesKeepEditing => 'Kontynuuj edycję';

  @override
  String get tankSyncSectionSubtitle =>
      'Synchronizacja w chmurze na Twoich urządzeniach';

  @override
  String get mapUnavailable => 'Mapa niedostępna';

  @override
  String get routeNameHintExample => 'np. Paryż → Lyon';

  @override
  String get priceStatsCurrent => 'Aktualna';

  @override
  String get tankerkoenigApiKeyLabel => 'Klucz API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Klucz API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Dotknij, aby zaktualizować pozycję GPS';

  @override
  String get nameLabel => 'Nazwa';

  @override
  String get obd2ErrorPermissionDenied =>
      'Do połączenia z adapterem OBD2 wymagane jest uprawnienie Bluetooth.';

  @override
  String get obd2ErrorBluetoothOff => 'Włącz Bluetooth i spróbuj ponownie.';

  @override
  String get obd2ErrorScanTimeout =>
      'Nie znaleziono adaptera OBD2 w pobliżu. Upewnij się, że jest podłączony i włączony.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Adapter OBD2 nie odpowiedział. Włącz zapłon i spróbuj ponownie.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adapter OBD2 wysłał nierozpoznaną odpowiedź. Może być niekompatybilny — wypróbuj inny adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'Adapter OBD2 został odłączony. Połącz ponownie i spróbuj jeszcze raz.';

  @override
  String get onboardingExploreDemoData => 'Przeglądaj z danymi demo';

  @override
  String get achievementSmoothDriver => 'Seria płynnej jazdy';

  @override
  String get achievementSmoothDriverDesc =>
      'Jedź 5 tras z rzędu z wynikiem płynnej jazdy 80 lub więcej.';

  @override
  String get achievementColdStartAware => 'Świadomość zimnego startu';

  @override
  String get achievementColdStartAwareDesc =>
      'Utrzymaj koszt paliwa podczas zimnego startu poniżej 2% całkowitego paliwa przez cały miesiąc — łącz krótkie trasy.';

  @override
  String get achievementHighwayMaster => 'Mistrz autostrady';

  @override
  String get achievementHighwayMasterDesc =>
      'Przejedź trasę 30 km+ ze stałą prędkością z wynikiem płynnej jazdy 90 lub więcej.';

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
    return '$price $currency (cel: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel spadło na pobliskich stacjach';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count stacji potaniało nawet o $cents¢ w ciągu ostatniej godziny';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count stacji ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count więcej';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Powiadomienia o cenach w tle działają obecnie tylko dla stacji w Niemczech. To powiadomienie zostanie zapisane, ale może nigdy Cię nie powiadomić, dopóki nie pojawią się powiadomienia międzynarodowe.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Alerty radiusowe sprawdzają obecnie tylko stacje w Niemczech.';

  @override
  String get approachOverlaySection =>
      'Nakładka podczas zbliżania się do stacji';

  @override
  String get approachRadiusLabel => 'Promień';

  @override
  String approachRadiusCaption(String km) {
    return 'Nakładka powiększa się i pokazuje cenę, gdy jesteś w odległości do $km km od stacji';
  }

  @override
  String get approachPriceModeLabel => 'Pokaż cenę dla';

  @override
  String get approachPriceModeNearest => 'Najbliższa stacja';

  @override
  String get approachPriceModeCheapestInRadius => 'Najtańsza w promieniu';

  @override
  String get approachMinPollLabel => 'Min. odświeżanie';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Minimalna częstotliwość odświeżania najbliższej stacji (szybciej przy prędkości, nigdy częściej niż $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testuj nakładkę zbliżania się';

  @override
  String get approachTestStopButton => 'Zatrzymaj test';

  @override
  String approachTestActiveCaption(String station) {
    return 'Test aktywny — nakładka pokazuje cenę dla $station';
  }

  @override
  String get approachTestUnavailable =>
      'Dodaj ulubioną stację, aby przetestować nakładkę zbliżania się';

  @override
  String approachStationDistance(String meters) {
    return '$meters m dalej';
  }

  @override
  String get authErrorNoNetwork =>
      'Brak połączenia z siecią. Spróbuj ponownie później.';

  @override
  String get authErrorInvalidCredentials =>
      'Nieprawidłowy e-mail lub hasło. Sprawdź dane logowania.';

  @override
  String get authErrorUserAlreadyExists =>
      'Ten adres e-mail jest już zarejestrowany. Spróbuj się zalogować.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Sprawdź skrzynkę e-mail i najpierw potwierdź swoje konto.';

  @override
  String get authErrorGeneric =>
      'Logowanie nie powiodło się. Spróbuj ponownie.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Lokalizacja w tle — tylko do automatycznego nagrywania';

  @override
  String get autoRecordConsentExplanationTitle => 'O tym uprawnieniu';

  @override
  String get autoRecordConsentExplanationBody =>
      'Automatyczne nagrywanie potrzebuje lokalizacji w tle, aby wykryć, kiedy zaczynasz jechać, gdy aplikacja jest zamknięta. To uprawnienie jest używane tylko przez automatyczne nagrywanie — wyszukiwanie stacji i centrowanie mapy używają oddzielnego uprawnienia do lokalizacji na pierwszym planie.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Rozumiem';

  @override
  String get autoRecordConsentExplanationTooltip => 'Co to oznacza?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Dotknij, aby zarządzać w ustawieniach systemowych';

  @override
  String get autoRecordSectionTitle => 'Automatyczne nagrywanie';

  @override
  String get autoRecordToggleLabel => 'Automatycznie nagrywaj trasy';

  @override
  String get autoRecordStatusActiveLabel =>
      'Automatyczne nagrywanie uruchomi się następnym razem, gdy wsiądziesz do samochodu.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Sparuj adapter OBD2, aby włączyć automatyczne nagrywanie.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Zezwól na lokalizację w tle, aby automatyczne nagrywanie działało przy wyłączonym ekranie.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Sparuj adapter';

  @override
  String get autoRecordSpeedThresholdLabel => 'Prędkość startowa (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Opóźnienie zapisu po rozłączeniu (sekundy)';

  @override
  String get autoRecordPairedAdapterLabel => 'Sparowany adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'Brak sparowanego adaptera. Najpierw sparuj go przez konfigurację OBD2.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Lokalizacja w tle dozwolona';

  @override
  String get autoRecordBackgroundLocationRequest => 'Poproś o uprawnienie';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Dlaczego «Zawsze zezwalaj»?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Automatyczne nagrywanie przesyła współrzędne GPS z usługi OBD-II na pierwszym planie, gdy ekran jest wyłączony, aby trasa pozostała dokładna. Android wymaga opcji «Zawsze zezwalaj» do pracy po zablokowaniu urządzenia.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Otwórz ustawienia';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Wymagane uprawnienie do lokalizacji';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Nie można było poprosić o lokalizację w tle';

  @override
  String get autoRecordBadgeClearTooltip => 'Wyczyść licznik';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Sparuj adapter w sekcji poniżej, aby włączyć automatyczne nagrywanie';

  @override
  String get exportBackupTooltip => 'Eksportuj kopię zapasową';

  @override
  String get exportBackupReady => 'Kopia zapasowa gotowa — wybierz lokalizację';

  @override
  String get exportBackupFailed =>
      'Eksport kopii zapasowej nie powiódł się — spróbuj ponownie';

  @override
  String get brokenMapChipVerifying => 'Weryfikacja czujnika MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Podejrzane odczyty MAP';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Czujnik MAP odczytuje błędnie — odczyty paliwa mogą być o 50–80% za niskie. Spróbuj innego adaptera.';

  @override
  String get brokenMapBannerHardDisable =>
      'Czujnik MAP zawodny. Wyświetlam średnie tankowania zamiast aktualnego zużycia paliwa.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Czujnik MAP: zweryfikowany ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Czujnik MAP: weryfikacja ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Czujnik MAP: podejrzany ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Czujnik MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Czujnik MAP: $posterior% ± $margin% (zweryfikowany)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnostyka czujnika MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Pewność uszkodzenia MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return 'Zarejestrowano $count obserwacji';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Zweryfikowany jako sprawny';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Czujnik MAP tego pojazdu nie został jeszcze zaobserwowany.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Zablokowane adaptery';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Brak zablokowanych adapterów.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — oznaczony jako $percent% uszkodzony';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Wyczyść';

  @override
  String get brokenMapRevPromptTitle => 'Zwiększ obroty silnika';

  @override
  String get brokenMapRevPromptBody =>
      'Krótko zwiększ obroty silnika, aby aplikacja mogła sprawdzić, czy czujnik MAP reaguje.';

  @override
  String get brokenMapRevPromptConfirm => 'Gotowe — zwiększyłem obroty';

  @override
  String get calibrationAdvancedTitle => 'Zaawansowana kalibracja';

  @override
  String get calibrationDisplacementLabel => 'Pojemność silnika (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Sprawność objętościowa (η_v)';

  @override
  String get calibrationAfrLabel => 'Stosunek powietrza do paliwa (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Gęstość paliwa (g/L)';

  @override
  String get calibrationSourceDetected => '(wykryto z VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(katalog: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(domyślna)';

  @override
  String get calibrationSourceManual => '(ręczna)';

  @override
  String get calibrationResetToDetected => 'Resetuj do wykrytej wartości';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (skalibrowana, $samples próbek)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (nauka, $samples próbek)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (domyślna — brak pełnego tankowania)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples próbek';
  }

  @override
  String get calibrationResetLearner => 'Resetuj kalibrację';

  @override
  String get calibrationBasisAtkinson => 'Cykl Atkinsona';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbodoładowany + DI';

  @override
  String get calibrationBasisTurbo => 'Turbodoładowany';

  @override
  String get calibrationBasisNaDi => 'Wolnossący + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(katalog: $makeModel — domyślny $basis)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Twój $makeModel jest oznaczony jako diesel, ale pasuje do katalogowej pozycji benzynowej. Dotknij, aby zaktualizować.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aktualizuj';

  @override
  String get consumptionTabFuel => 'Paliwo';

  @override
  String get consumptionTabCharging => 'Ładowanie';

  @override
  String get noChargingLogsTitle => 'Brak dzienników ładowania';

  @override
  String get noChargingLogsSubtitle =>
      'Zapisz pierwszą sesję ładowania, aby zacząć śledzić EUR/100 km i kWh/100 km.';

  @override
  String get addChargingLog => 'Zapisz ładowanie';

  @override
  String get addChargingLogTitle => 'Zapisz sesję ładowania';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Całkowity koszt';

  @override
  String get chargingTimeMin => 'Czas ładowania (min)';

  @override
  String get chargingStationName => 'Stacja (opcjonalnie)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Potrzebny poprzedni wpis do porównania';

  @override
  String get chargingLogButtonLabel => 'Zapisz ładowanie';

  @override
  String get chargingCostTrendTitle => 'Trend kosztów ładowania';

  @override
  String get chargingEfficiencyTitle => 'Efektywność (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Za mało danych';

  @override
  String get chargingChartsMonthAxis => 'Miesiąc';

  @override
  String get consoFeatureGroupTitle => 'Zużycie';

  @override
  String get consoFeatureGroupDescription =>
      'Śledź swoje zużycie — ręczne tankowania lub automatyczne nagrywanie tras OBD2.';

  @override
  String get consoModeOff => 'Wyłączone';

  @override
  String get consoModeFuel => 'Paliwo';

  @override
  String get consoModeFuelAndTrips => 'Paliwo + Trasy';

  @override
  String get consoModeOffDescription =>
      'Brak karty Zużycie i sekcji ustawień Zużycia.';

  @override
  String get consoModeFuelDescription =>
      'Tylko ręczne tankowania. Przydatne bez adaptera OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Dodaje automatyczne nagrywanie tras OBD2. Wymaga sparowanego adaptera.';

  @override
  String get consoSubsectionVehicles => 'Moje pojazdy';

  @override
  String get consoSubsectionTrajets => 'Trasy (OBD2)';

  @override
  String get consoSubsectionToggles => 'Jazda';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Dokładność: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Wysoka';

  @override
  String get consumptionAccuracyMedium => 'Średnia';

  @override
  String get consumptionAccuracyLow => 'Niska';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Pełna kalibracja: tankowania oraz przejazdy zarejestrowane przez OBD2. Wartość L/100 km odpowiada rzeczywistości z dokładnością do kilku procent.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Tankowania zakotwiczyły model zużycia, ale żaden przejazd OBD2 nie został jeszcze przetworzony. Zarejestruj jeden z podłączonym OBD2, aby osiągnąć wysoką dokładność.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Tylko GPS — żadne tankowanie nie zakotwiczyło jeszcze modelu zużycia. Dodaj kilka pełnych tankowań, aby poprawić dokładność.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count częściowe tankowania oczekujące na pełne tankowanie — nie wliczone do średniej',
      one:
          '1 częściowe tankowanie oczekujące na pełne tankowanie — nie wliczone do średniej',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% paliwa z automatycznych korekt — sprawdź wpisy';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Automatyczna korekta — dotknij, aby edytować';

  @override
  String get fillUpCorrectionEditTitle => 'Edytuj automatyczną korektę';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Ten wpis został automatycznie wygenerowany, aby zamknąć lukę między nagranymi trasami a zatankowanym paliwem. Dostosuj wartości, jeśli znasz rzeczywiste dane.';

  @override
  String get fillUpCorrectionDelete => 'Usuń korektę';

  @override
  String get fillUpCorrectionStation => 'Nazwa stacji (opcjonalnie)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grecja)';

  @override
  String get greeceCommunityApiNotice =>
      'Zasilane przez utrzymywane przez społeczność API fuelpricesgr';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumunia)';

  @override
  String get romaniaScrapingNotice =>
      'Zasilane przez pretcarburant.ro (Rada Konkurencji + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stacje w $country $km km stąd — €$price/L taniej';
  }

  @override
  String get crossBorderTapToSwitch => 'Dotknij, aby zmienić kraj';

  @override
  String get crossBorderDismissTooltip => 'Odrzuć';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Narzędzia programisty';

  @override
  String get developerToolsSubtitle =>
      'Diagnostyka i narzędzia do debugowania — widoczne tylko w trybie programisty / debugowania.';

  @override
  String get developerToolsMenuSubtitle =>
      'Dziennik błędów, alerty testowe, diagnostyka';

  @override
  String get developerToolsErrorLogGroupTitle => 'Dziennik błędów';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Zapisz dziennik błędów ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Wyczyść dziennik błędów';

  @override
  String get developerToolsViewErrorLog => 'Pokaż dziennik błędów';

  @override
  String get developerToolsErrorLogEmpty =>
      'Nie zarejestrowano żadnych śladów błędów.';

  @override
  String get developerToolsAlertsGroupTitle => 'Alerty i powiadomienia';

  @override
  String get developerToolsFireTestNotification =>
      'Wyślij powiadomienie testowe';

  @override
  String get developerToolsTestNotificationTitle => 'Powiadomienie testowe';

  @override
  String get developerToolsTestNotificationBody =>
      'Jeśli to czytasz, powiadomienia działają.';

  @override
  String get developerToolsTestNotificationSent =>
      'Wysłano powiadomienie testowe.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Powiadomienia są zablokowane — włącz je w ustawieniach systemu i spróbuj ponownie.';

  @override
  String get developerToolsRunTestAlert => 'Uruchom potok alertu testowego';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Wyzwolono alert testowy — potok dostarczył $count powiadomień.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Testowy alert cenowy';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Dopasowanie syntetyczne: w pobliżu znaleziono stację poniżej Twojego celu.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnostyka';

  @override
  String get developerToolsFeatureFlagDump => 'Inspektor flag funkcji';

  @override
  String get developerToolsFlagOn => 'Wł.';

  @override
  String get developerToolsFlagOff => 'Wył.';

  @override
  String get developerToolsClearCaches => 'Wyczyść pamięci podręczne';

  @override
  String get developerToolsCachesCleared => 'Wyczyszczono pamięci podręczne.';

  @override
  String get developerToolsCopyDiagnostics => 'Kopiuj diagnostykę';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Skopiowano diagnostykę do schowka.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Informacje o kompilacji';

  @override
  String get developerToolsBuildVersion => 'Wersja aplikacji';

  @override
  String get developerToolsBuildChannel => 'Kanał kompilacji';

  @override
  String get insightCardTitle => 'Najczęstsze marnotrawstwa';

  @override
  String get insightEmptyState =>
      'Brak istotnych nieefektywności — tak trzymaj!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Silnik powyżej 3000 RPM ($pctTime% trasy): zmarnowano $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count gwałtownych przyspieszeń: zmarnowano $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Bieg jałowy ($pctTime% trasy): zmarnowano $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% trasy';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Jazda na niskim biegu ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Podczas dłuższych postojów wyłączaj silnik, zamiast pozostawiać go na biegu jałowym.';

  @override
  String get lessonAdviceHighRpm =>
      'Zmieniaj na wyższy bieg wcześniej, aby utrzymać silnik poza zakresem wysokich obrotów.';

  @override
  String get lessonAdviceHardAccel =>
      'Naciskaj gaz płynnie — równomierne przyspieszanie zużywa mniej paliwa.';

  @override
  String get lessonAdviceLowGear =>
      'Zmieniaj na wyższy bieg wcześniej, aby silnik pracował na niższych, oszczędniejszych obrotach.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Utrzymująca się wysoka prędkość ($pctTime% trasy): zmarnowano $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Utrzymująca się wysoka prędkość ($pctTime% trasy)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Powyżej 110 km/h zdejmij nogę z gazu – opór powietrza gwałtownie rośnie, nieco wolniej oszczędza dużo paliwa.';

  @override
  String get lessonSmoothDrivingTitle => 'Płynna jazda – dobra robota!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Brak gwałtownego przyspieszania i hamowania na tej trasie – równa jazda utrzymuje niskie zużycie.';

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
  String get drivingScoreCardTitle => 'Wynik jazdy';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Wynik złożony z biegu jałowego, gwałtownych przyspieszeń, gwałtownego hamowania i czasu przy wysokich obrotach. Porównanie \'lepszy niż X% poprzednich tras\' pojawi się w przyszłej wersji.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Wynik jazdy $score na 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Bieg jałowy';

  @override
  String get drivingScorePenaltyHardAccel => 'Gwałtowne przyspieszenia';

  @override
  String get drivingScorePenaltyHardBrake => 'Gwałtowne hamowanie';

  @override
  String get drivingScorePenaltyHighRpm => 'Wysokie obroty';

  @override
  String get drivingScorePenaltyFullThrottle => 'Pełny gaz';

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
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L oszczędności';
  }

  @override
  String get ecoRouteHint =>
      'Inteligentniejsza trasa — preferuje stałą prędkość na autostradzie zamiast skrótów przez miasto.';

  @override
  String get favoritesShareAction => 'Udostępnij';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — ulubione z dnia $date';
  }

  @override
  String get favoritesShareError =>
      'Nie można wygenerować obrazu do udostępnienia';

  @override
  String get featureManagementSectionTitle => 'Zarządzanie funkcjami';

  @override
  String get featureManagementSectionSubtitle =>
      'Włączaj i wyłączaj poszczególne funkcje. Niektóre zależą od innych — przełączniki są wyłączone, dopóki warunki wstępne nie są spełnione.';

  @override
  String get featureLabel_obd2TripRecording => 'Nagrywanie tras OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Automatyczne rejestrowanie tras przez OBD2.';

  @override
  String get featureLabel_gamification => 'Grywalizacja';

  @override
  String get featureDescription_gamification =>
      'Wyniki jazdy i zdobyte odznaki.';

  @override
  String get featureLabel_hapticEcoCoach => 'Haptyczny eco-coach';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Haptyczny feedback w czasie rzeczywistym podczas trasy.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Synchronizacja między urządzeniami przez Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Analityka zużycia';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Karta analizy tankowań i tras.';

  @override
  String get featureLabel_baselineSync => 'Synchronizacja bazy';

  @override
  String get featureDescription_baselineSync =>
      'Synchronizuj bazy jazdy przez TankSync.';

  @override
  String get featureLabel_unifiedSearchResults => 'Ujednolicone wyniki';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Jedna lista wyników łącząca stacje paliw i EV.';

  @override
  String get featureLabel_priceAlerts => 'Alerty cenowe';

  @override
  String get featureDescription_priceAlerts =>
      'Powiadomienia o spadkach cen przy przekroczeniu progu.';

  @override
  String get featureLabel_priceHistory => 'Historia cen';

  @override
  String get featureDescription_priceHistory =>
      '30-dniowe wykresy cen w szczegółach stacji.';

  @override
  String get featureLabel_routePlanning => 'Planowanie trasy';

  @override
  String get featureDescription_routePlanning =>
      'Najtańszy przystanek na Twojej trasie.';

  @override
  String get featureLabel_evCharging => 'Ładowanie EV';

  @override
  String get featureDescription_evCharging =>
      'Stacje ładowania przez OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Wskazówki hypermilingu z sygnalizacją OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Ścieżka GPS trasy';

  @override
  String get featureDescription_gpsTripPath =>
      'Zapisuj próbki ścieżki GPS przy każdej trasie.';

  @override
  String get featureLabel_autoRecord => 'Automatyczne nagrywanie';

  @override
  String get featureDescription_autoRecord =>
      'Automatyczne rozpoczęcie trasy gdy adapter OBD2 połączy się z jadącym pojazdem.';

  @override
  String get featureLabel_showFuel => 'Pokaż stacje paliw';

  @override
  String get featureDescription_showFuel =>
      'Wyświetlaj wyniki stacji benzyny/diesla w wyszukiwaniu i na mapie.';

  @override
  String get featureLabel_showElectric => 'Pokaż stacje ładowania';

  @override
  String get featureDescription_showElectric =>
      'Wyświetlaj stacje ładowania EV w wyszukiwaniu i na mapie.';

  @override
  String get featureLabel_showConsumptionTab => 'Karta Zużycie';

  @override
  String get featureDescription_showConsumptionTab =>
      'Pokaż kartę analityki zużycia w dolnej nawigacji.';

  @override
  String get featureBlockedEnable_gamification =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Najpierw włącz TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureBlockedEnable_showFuel => 'Wymagania wstępne nie spełnione';

  @override
  String get featureBlockedEnable_showElectric =>
      'Wymagania wstępne nie spełnione';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Prognoza cen TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Model prognozy cen na urządzeniu — wnioskowanie lokalne; dane i prognozy nie opuszczają urządzenia.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Najpierw włącz historię cen';

  @override
  String get featureLabel_fuelCalculator => 'Kalkulator paliwa';

  @override
  String get featureDescription_fuelCalculator =>
      'Kalkulator kosztów paliwa dostępny z wyników wyszukiwania.';

  @override
  String get featureLabel_carbonDashboard => 'Panel CO2';

  @override
  String get featureDescription_carbonDashboard =>
      'Panel śladu CO2 dostępny z karty Zużycie.';

  @override
  String get featureLabel_experimentalOemPids => 'Eksperymentalne PID OEM';

  @override
  String get featureDescription_experimentalOemPids =>
      'Odczyt dokładnej ilości litrów w baku przez PID producenta na obsługiwanych adapterach.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Najpierw włącz nagrywanie tras OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Skanuj QR płatności';

  @override
  String get featureDescription_paymentQrScan =>
      'Czytnik QR do płatności na ekranie szczegółów stacji.';

  @override
  String get featureLabel_communityPriceReports =>
      'Zgłoszenia cen społeczności';

  @override
  String get featureDescription_communityPriceReports =>
      'Zgłoś cenę stacji z ekranu szczegółów stacji.';

  @override
  String get featureLabel_obd2Optional => 'Wymagaj OBD2 do nagrywania tras';

  @override
  String get featureDescription_obd2Optional =>
      'Gdy wyłączone, aplikacja nagrywa trasy tylko z GPS bez adaptera OBD2. Coaching jest ograniczony — brak chwilowego L/100 km, mniej sygnałów z silnika.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR paragonu';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Zeskanuj wydrukowany paragon na ekranie Dodaj tankowanie, aby wypełnić datę, litry, sumę i stację.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'OCR wyświetlacza dystrybutora (eksperymentalne)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Zeskanuj wyświetlacz dystrybutora paliwa, aby wstępnie wypełnić formularz. Rozpoznawanie jest dziś nierzetelne — włącz tylko, jeśli chcesz przetestować.';

  @override
  String get featureLabel_developerPatToken => 'Opinia dewelopera (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Włącza panel opinii o nieudanych skanowaniach, który automatycznie tworzy issue na GitHubie z Personal Access Token. Funkcja dla zaawansowanych użytkowników / współtwórców.';

  @override
  String get featureLabel_debugMode => 'Tryb programisty / debugowania';

  @override
  String get featureDescription_debugMode =>
      'Wyświetla w ustawieniach sekcję Narzędzia programisty z diagnostyką: eksport dziennika błędów, powiadomienia testowe, uruchomienie potoku alertu testowego, zrzut flag funkcji, czyszczenie pamięci podręcznych i kopiowanie diagnostyki.';

  @override
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get feedbackConsentTitle => 'Wysłać zgłoszenie do GitHub?';

  @override
  String get feedbackConsentBody =>
      'Spowoduje to utworzenie publicznego zgłoszenia na naszym repozytorium GitHub ze zdjęciem i tekstem OCR. Żadne dane osobowe (lokalizacja, ID konta) nie są wysyłane. Kontynuować?';

  @override
  String get feedbackConsentContinue => 'Kontynuuj';

  @override
  String get feedbackConsentCancel => 'Anuluj';

  @override
  String get feedbackConsentLater => 'Później';

  @override
  String get feedbackTokenSectionTitle =>
      'Opinie o błędach skanowania (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Aby automatycznie otworzyć zgłoszenie GitHub po nieudanym skanowaniu, wklej GitHub PAT (zakres `public_repo` w repozytorium tankstellen). Inaczej dostępne pozostaje ręczne udostępnianie.';

  @override
  String get feedbackTokenStatusSet => 'Token skonfigurowany';

  @override
  String get feedbackTokenStatusUnset => 'Brak tokena';

  @override
  String get feedbackTokenSet => 'Ustaw';

  @override
  String get feedbackTokenClear => 'Wyczyść';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

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
      'Zweryfikowane przez adapter';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Niezgodność z odczytem adaptera';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Twój wpis: $userL L. Adapter wskazuje: $adapterL L (różnica z pomiaru przed/po tankowaniu). Użyć wartości adaptera?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Zachowaj mój wpis';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Użyj wartości adaptera';

  @override
  String get scanReceiptNoData =>
      'Nie znaleziono danych paragonu — spróbuj ponownie';

  @override
  String get scanReceiptSuccess =>
      'Paragon zeskanowany — sprawdź wartości. Dotknij «Zgłoś błąd skanowania» poniżej, jeśli coś jest nie tak.';

  @override
  String scanReceiptFailed(String error) {
    return 'Skanowanie nie powiodło się: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Wyświetlacz dystrybutora nieczytelny — spróbuj ponownie';

  @override
  String get scanPumpSuccess =>
      'Wyświetlacz dystrybutora zeskanowany — sprawdź wartości.';

  @override
  String get scanPumpGlare =>
      'Zbyt duże odbicie na wyświetlaczu — spróbuj ponownie pod lekkim kątem, aby cyfry nie były prześwietlone.';

  @override
  String scanPumpFailed(String error) {
    return 'Skanowanie dystrybutora nie powiodło się: $error';
  }

  @override
  String get badScanReportTitle => 'Zgłoś błąd skanowania';

  @override
  String get badScanReportTitleReceipt => 'Zgłoś błąd skanowania — paragon';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Zgłoś błąd skanowania — wyświetlacz dystrybutora';

  @override
  String get pumpScanFailureTitle => 'Wyświetlacz nieczytelny';

  @override
  String get pumpScanFailureBody =>
      'Skanowanie nie mogło odczytać wyświetlacza dystrybutora. Co chcesz zrobić?';

  @override
  String get pumpScanFailureCorrectManually => 'Popraw ręcznie';

  @override
  String get pumpScanFailureReport => 'Zgłoś';

  @override
  String get pumpScanFailureRemove => 'Usuń zdjęcie';

  @override
  String get badScanReportHint =>
      'Udostępnimy zdjęcie paragonu i obie zestawy wartości, aby następna wersja mogła nauczyć się tego układu.';

  @override
  String get badScanReportShareAction => 'Udostępnij raport + zdjęcie';

  @override
  String get badScanReportFieldBrandLayout => 'Układ marki';

  @override
  String get badScanReportFieldTotal => 'Łącznie';

  @override
  String get badScanReportFieldPricePerLiter => 'Cena/L';

  @override
  String get badScanReportFieldStation => 'Stacja';

  @override
  String get badScanReportFieldFuel => 'Paliwo';

  @override
  String get badScanReportFieldDate => 'Data';

  @override
  String get badScanReportHeaderField => 'Pole';

  @override
  String get badScanReportHeaderScanned => 'Zeskanowane';

  @override
  String get badScanReportHeaderYouTyped => 'Wpisałeś';

  @override
  String get badScanReportCreateTicket => 'Utwórz zgłoszenie';

  @override
  String get badScanReportOpenInBrowser => 'Otwórz w przeglądarce';

  @override
  String get badScanReportFallbackToShare =>
      'Przesyłanie nie powiodło się — ręczne udostępnienie';

  @override
  String get pumpCameraHint =>
      'Ustaw trzy liczby z wyświetlacza dystrybutora w ramce';

  @override
  String get pumpCameraCapture => 'Zrób zdjęcie';

  @override
  String get pumpCameraPermissionDenied =>
      'Dostęp do aparatu jest potrzebny do zeskanowania wyświetlacza dystrybutora. Włącz go w ustawieniach urządzenia.';

  @override
  String get pumpCameraError =>
      'Nie udało się uruchomić aparatu. Spróbuj ponownie lub wprowadź wartości ręcznie.';

  @override
  String get pumpCameraOrientationHorizontal => 'Przełącz na układ poziomy';

  @override
  String get pumpCameraOrientationVertical => 'Przełącz na układ pionowy';

  @override
  String get pumpCameraGlareWarning =>
      'Zbyt duże odblaski — lekko przechyl, aby uniknąć odblasków';

  @override
  String get pumpCameraAlignHint =>
      'Ustaw wyświetlacz w ramce, a następnie zrób zdjęcie';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Co zatankowałeś';

  @override
  String get fillUpSectionWhatSubtitle => 'Paliwo, ilość, cena';

  @override
  String get fillUpSectionWhereTitle => 'Gdzie byłeś';

  @override
  String get fillUpSectionWhereSubtitle => 'Stacja, licznik, notatki';

  @override
  String get fillUpImportFromLabel => 'Importuj z…';

  @override
  String get fillUpImportSheetTitle => 'Importuj dane tankowania';

  @override
  String get fillUpImportReceiptLabel => 'Paragon';

  @override
  String get fillUpImportReceiptDescription =>
      'Skanuj paragon papierowy kamerą';

  @override
  String get fillUpImportPumpLabel => 'Wyświetlacz dystrybutora';

  @override
  String get fillUpImportPumpDescription =>
      'Odczytaj Betrag / Preis z wyświetlacza LCD dystrybutora';

  @override
  String get fillUpImportObdLabel => 'Adapter OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Odczytaj licznik przez port OBD-II przez Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Cena za litr';

  @override
  String get vehicleHeaderPlateLabel => 'Tablica';

  @override
  String get vehicleHeaderUntitled => 'Nowy pojazd';

  @override
  String get vehicleSectionIdentityTitle => 'Identyfikacja';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nazwa i VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Napęd';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Jak porusza się ten pojazd';

  @override
  String get calibrationModeLabel => 'Tryb kalibracji';

  @override
  String get calibrationModeRule => 'Oparty na regułach';

  @override
  String get calibrationModeFuzzy => 'Rozmyty';

  @override
  String get calibrationModeTooltip =>
      'Oparty na regułach przypisuje każdą próbkę jazdy dokładnie do jednej sytuacji. Rozmyty rozkłada ją na wszystkie proporcjonalnie do dopasowania — płynniej przy 60 km/h lub zmiennych gradientach, ale wolniej wypełnia wszystkie segmenty.';

  @override
  String get profileGamificationToggleTitle => 'Pokaż osiągnięcia i wyniki';

  @override
  String get profileGamificationToggleSubtitle =>
      'Gdy wyłączone, odznaki, wyniki i ikony pucharów są ukryte w całej aplikacji.';

  @override
  String get coachingGpsLiftOff => 'Puść gaz';

  @override
  String get coachingGpsAnticipateBrake => 'Przewiduj';

  @override
  String get coachingGpsSmoothAccel => 'Płynne przyspieszanie';

  @override
  String get gpsDiagnosticsTitle => 'Diagnostyka próbkowania GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps przerwy/przerw',
      one: '1 przerwa',
      zero: 'bez przerw',
    );
    return '$count próbek · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Mediana interwału: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Zebrane podczas nagrywania w celu weryfikacji kadencji GPS przy uśpionym telefonie.';

  @override
  String get gpsMatrixMaturityCold => 'Zimna';

  @override
  String get gpsMatrixMaturityWarming => 'Rozgrzewa się';

  @override
  String get gpsMatrixMaturityConverged => 'Zbieżna';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'Matryca GPS się jeszcze rozgrzewa ($count korekt). Oszacowania tymczasowe.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'Matryca GPS zbiega się ($count tankowań). Użyteczne, mogą się różnić o kilka %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'Matryca GPS jest zbieżna ($count tankowań). Oszacowania w granicach ~2 % rzeczywistego zużycia.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Jazda';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco-coaching w czasie rzeczywistym';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Delikatne wibracje + wskazówka na ekranie gdy wciśniesz gaz podczas jazdy';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Łagodniej z gazem — wybieg oszczędza więcej';

  @override
  String semanticsNavigateTo(String name) {
    return 'Nawiguj do $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Usuń $name z ulubionych';
  }

  @override
  String get showOnMapSemanticLabel => 'Pokaż stacje na mapie';

  @override
  String get searchResultsSemanticLabel => 'Wyniki wyszukiwania';

  @override
  String get searchCriteriaSemanticLabel =>
      'Podsumowanie kryteriów wyszukiwania. Dotknij, aby edytować.';

  @override
  String get noFavoritesSemanticLabel =>
      'Brak ulubionych. Dotknij gwiazdki przy stacji, aby zapisać ją jako ulubioną.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stacja jest otwarta',
      'false': 'Stacja jest zamknięta',
      'other': 'Stacja jest zamknięta',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Kraj $name, wybrano',
      'false': 'Kraj $name',
      'other': 'Kraj $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Język $name, wybrano',
      'false': 'Język $name',
      'other': 'Język $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Sortuj według $option, wybrano',
      'false': 'Sortuj według $option',
      'other': 'Sortuj według $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Paliwo $type, wybrano',
      'false': 'Paliwo $type',
      'other': 'Paliwo $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Stacja ładowania $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic => 'Tarcza prywatności z kroplą paliwa';

  @override
  String get globeIllustrationSemantic => 'Globus ze znacznikami stacji paliw';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Dystrybutor paliwa ze wskaźnikiem cen';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, źródło danych: $provider, $keyRequirement, rodzaje paliwa: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Wymagany klucz API';

  @override
  String get countryInfoNoKeyNeeded => 'Bezpłatnie, bez klucza';

  @override
  String countryInfoDataSource(String provider) {
    return 'Dane: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Rodzaje paliwa: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Klucz anonimowy';

  @override
  String get anonKeyHideTooltip => 'Ukryj klucz';

  @override
  String get anonKeyShowTooltip => 'Pokaż klucz do weryfikacji';

  @override
  String anonKeyTooLong(int length) {
    return 'Klucz jest za długi ($length znaków) — sprawdź czy nie ma dodatkowego tekstu';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Klucz wygląda poprawnie ($length znaków)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Klucz powinien być JWT (nagłówek.ładunek.podpis)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Klucz może być obcięty ($length z ~208 oczekiwanych znaków)';
  }

  @override
  String get anonKeyExceedsMax => 'Klucz przekracza maksymalną długość';

  @override
  String get qrShareTitle => 'Udostępnij swoją bazę danych';

  @override
  String get qrShareSubtitle =>
      'Inni mogą zeskanować ten kod QR, aby się połączyć';

  @override
  String get qrShareCopyAsText => 'Kopiuj jako tekst';

  @override
  String get authInfoTitle => 'Dlaczego warto założyć konto?';

  @override
  String get authInfoBenefit1 =>
      '• Synchronizuj ulubione, alerty i zapisane trasy między urządzeniami';

  @override
  String get authInfoBenefit2 =>
      '• Zaplanuj trasę na telefonie, użyj jej w samochodzie';

  @override
  String get authInfoBenefit3 =>
      '• Żadne dane nie są udostępniane stronom trzecim';

  @override
  String get authInfoBenefit4 =>
      '• Możesz usunąć swoje konto w dowolnym momencie';

  @override
  String get privacyLocalDataEmpty =>
      'Nic jeszcze nie zapisano. Dodaj ulubioną stację lub ustaw alert cenowy, aby zobaczyć wpisy.';

  @override
  String get privacyHideEmptyRows => 'Ukryj puste wiersze';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pokaż $count puste wiersze',
      one: 'Pokaż $count pusty wiersz',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Konfiguracja klucza API (opcjonalne)';

  @override
  String get apiKeySetupDescription =>
      'Zarejestruj się, aby uzyskać bezpłatny klucz API, lub pomiń, aby eksplorować aplikację z danymi demo.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Rejestracja $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Wpisując klucz API akceptujesz warunki korzystania z $provider. Redystrybucja danych jest zabroniona.';
  }

  @override
  String get calculatorDistanceHint => 'np. 150';

  @override
  String get calculatorConsumptionHint => 'np. 7,0';

  @override
  String get calculatorPriceHint => 'np. 1,899';

  @override
  String get routeStrategyLabel => 'Strategia:';

  @override
  String get routeStrategyUniform => 'Jednolita';

  @override
  String get routeStrategyBalanced => 'Zrównoważona';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (eksperymentalne)';

  @override
  String get glideCoachBetaSubtitle =>
      'Subtelne wibracje przy zwalnianiu przed czerwonym światłem. Domyślnie wyłączone — ryzyko rozproszenia uwagi.';

  @override
  String get consentSyncTripsTitle => 'Synchronizuj nagrania tras';

  @override
  String get consentSyncTripsSubtitle =>
      'Twórz kopię zapasową tras OBD2 + GPS w TankSync. Między urządzeniami, opt-in.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Włącz Synchronizację w chmurze powyżej, aby tworzyć kopię tras.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Zaloguj się przy użyciu konta e-mail, aby synchronizować trasy między urządzeniami.';

  @override
  String get consentHideDetails => 'Ukryj szczegóły';

  @override
  String get consentShowDetails => 'Pokaż szczegóły';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Nieprawidłowy link';

  @override
  String invalidLinkBody(String path) {
    return 'Link \"$path\" jest nieprawidłowy.';
  }

  @override
  String get home => 'Strona główna';

  @override
  String get locationConsentTitle => 'Dostęp do lokalizacji';

  @override
  String get locationConsentSubtitle =>
      'Ta aplikacja chce użyć Twojej lokalizacji, aby znaleźć stacje paliw w pobliżu.';

  @override
  String get locationConsentWhatHappens =>
      'Co dzieje się z danymi o Twojej lokalizacji:';

  @override
  String get locationConsentBulletApi =>
      'Twoje współrzędne są wysyłane do API cen paliw w celu znalezienia pobliskich stacji.';

  @override
  String get locationConsentBulletNoServer =>
      'Twoja lokalizacja nie jest przechowywana na żadnym serwerze — nie ma serwera.';

  @override
  String get locationConsentBulletNoTracking =>
      'Dane o lokalizacji nie są wykorzystywane do reklam, analiz ani śledzenia.';

  @override
  String get locationConsentRevoke =>
      'Dostęp do lokalizacji możesz cofnąć w dowolnym momencie w ustawieniach systemu. Możesz też wyszukiwać według kodu pocztowego.';

  @override
  String get locationConsentLegalBasis =>
      'Podstawa prawna: art. 6 ust. 1 lit. a) RODO (zgoda)';

  @override
  String get locationConsentDecline => 'Odmów';

  @override
  String get locationConsentAccept => 'Akceptuj';

  @override
  String get loyaltySettingsTitle => 'Karty paliwowe';

  @override
  String get loyaltySettingsSubtitle =>
      'Zastosuj zniżkę lojalnościową do wyświetlanych cen';

  @override
  String get loyaltyMenuTitle => 'Karty paliwowe';

  @override
  String get loyaltyMenuSubtitle =>
      'Zastosuj zniżki za litr od Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Dodaj kartę';

  @override
  String get loyaltyAddCardSheetTitle => 'Dodaj kartę paliwową';

  @override
  String get loyaltyBrandLabel => 'Marka';

  @override
  String get loyaltyCardLabelLabel => 'Etykieta (opcjonalnie)';

  @override
  String get loyaltyDiscountLabel => 'Zniżka (za litr)';

  @override
  String get loyaltyDiscountInvalid => 'Wprowadź liczbę dodatnią';

  @override
  String get loyaltyDeleteConfirmTitle => 'Usunąć kartę?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Ta karta przestanie stosować swoją zniżkę.';

  @override
  String get loyaltyEmptyTitle => 'Brak kart paliwowych';

  @override
  String get loyaltyEmptyBody =>
      'Dodaj kartę, aby automatycznie stosować zniżkę za litr do pasujących stacji.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Wykryto pełzanie obrotów biegu jałowego';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Obroty biegu jałowego wzrosły o $percent% przez ostatnie $tripCount tras. Możliwy wczesny sygnał zatkanego filtra powietrza lub dryftu czujnika.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Możliwe ograniczenie przepływu powietrza';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Zużycie paliwa podczas jazdy ze stałą prędkością spadło o $percent% przez ostatnie $tripCount tras. Możliwy sygnał zatkanego filtra powietrza lub ograniczonego wlotu — warto sprawdzić.';
  }

  @override
  String get maintenanceActionDismiss => 'Odrzuć';

  @override
  String get maintenanceActionSnooze => 'Przypomnij za 30 dni';

  @override
  String get consumptionMonthlyInsightsTitle => 'Ten miesiąc vs poprzedni';

  @override
  String get consumptionMonthlyTripsLabel => 'Trasy';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Czas jazdy';

  @override
  String get consumptionMonthlyDistanceLabel => 'Dystans';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Śr. zużycie';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Potrzeba co najmniej 3 tras na miesiąc do porównania';

  @override
  String get obd2CapabilitySectionTitle => 'Możliwości adaptera';

  @override
  String get obd2CapabilityStandardOnly => 'Standard';

  @override
  String get obd2CapabilityOemPids => 'OEM PIDs';

  @override
  String get obd2CapabilityFullCan => 'Full CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Dla dokładnego odczytu litrów w baku na Peugeot/Citroën, aplikacja obsługuje OBDLink MX+/LX/CX (chip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Nakładka diagnostyczna OBD2 włączona';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Nakładka diagnostyczna OBD2 wyłączona';

  @override
  String get obd2DebugOverlayClearButton => 'Wyczyść';

  @override
  String get obd2DebugOverlayCloseButton => 'Zamknij';

  @override
  String get obd2DebugOverlayTitle => 'Breadcrumbs OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Udostępnij dziennik diagnostyczny';

  @override
  String get obd2DebugLoggingTitle => 'Rejestrowanie debugowania OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Rejestruj każdą sesję OBD2 — połączenie, uzgadnianie, przerwy w danych i ponowne połączenia — w eksportowalnym dzienniku XML. Domyślnie wyłączone.';

  @override
  String get obd2DebugSessionShareLabel => 'Udostępnij dziennik sesji OBD2';

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
    return 'Nie można było dotrzeć do \'$adapterName\' — wybierz inny adapter';
  }

  @override
  String get onboardingObd2StepTitle => 'Podłącz adapter OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Podłącz adapter OBD2 do portu diagnostycznego samochodu i włącz zapłon. Odczytamy VIN i uzupełnimy dane silnika.';

  @override
  String get onboardingObd2ConnectButton => 'Połącz adapter';

  @override
  String get onboardingObd2SkipButton => 'Może później';

  @override
  String get onboardingObd2ReadingVin => 'Odczytywanie VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Nie można odczytać VIN — wprowadź ręcznie';

  @override
  String get onboardingObd2ConnectFailed =>
      'Nie można połączyć się z adapterem. Możesz spróbować ponownie lub pominąć.';

  @override
  String get onboardingPickUseMode =>
      'Wybierz tryb użytkowania, aby kontynuować.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'upłynęło';

  @override
  String get alertsRadiusFrequencyLabel => 'Częstotliwość sprawdzania';

  @override
  String get alertsRadiusFrequencyDaily => 'Raz dziennie';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Dwa razy dziennie';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Trzy razy dziennie';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Cztery razy dziennie';

  @override
  String get radiusAlertPickOnMap => 'Wybierz na mapie';

  @override
  String get radiusAlertMapPickerTitle => 'Wybierz centrum alertu';

  @override
  String get radiusAlertMapPickerConfirm => 'Potwierdź';

  @override
  String get radiusAlertMapPickerCancel => 'Anuluj';

  @override
  String get radiusAlertMapPickerHint =>
      'Przeciągnij mapę, aby ustawić centrum alertu';

  @override
  String get radiusAlertCenterFromMap => 'Lokalizacja z mapy';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel w pobliżu $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Stacja oferuje $price € (cel: $threshold €)';
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
  String get refuelUnitPerSession => '/sesja';

  @override
  String get speedConsumptionCardTitle => 'Zużycie wg prędkości';

  @override
  String get speedBandIdleJam => 'Bieg jałowy / korek';

  @override
  String get speedBandUrban => 'Miasto (10–50)';

  @override
  String get speedBandSuburban => 'Podmiejski (50–80)';

  @override
  String get speedBandRural => 'Zamiejski (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Eco-prędkość (100–115)';

  @override
  String get speedBandMotorway => 'Autostrada (115–130)';

  @override
  String get speedBandMotorwayFast => 'Szybka autostrada (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Nagraj 30+ minut tras z adapterem OBD2, aby odblokować analizę prędkości/zużycia.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % czasu jazdy';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Potrzeba więcej danych';

  @override
  String get splashLoadingLabel => 'Ładowanie Sparkilo';

  @override
  String get storageRecoveryTitle => 'Problem z pamięcią';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo nie mogło otworzyć lokalnej pamięci danych. Plik pamięci wydaje się uszkodzony.';

  @override
  String get storageRecoveryGuidance =>
      'Aby odzyskać dane, wyczyść pamięć aplikacji w ustawieniach urządzenia lub zainstaluj aplikację ponownie. Twoje ulubione i historia są przechowywane tylko na tym urządzeniu, więc nie można ich automatycznie przywrócić.';

  @override
  String get tankLevelTitle => 'Poziom paliwa w baku';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km zasięgu';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Ostatnie tankowanie: $date · $count trasa(y) od tamtej pory';
  }

  @override
  String get tankLevelMethodObd2 => 'Pomiar OBD2';

  @override
  String get tankLevelMethodDistanceFallback =>
      'szacowanie na podstawie dystansu';

  @override
  String get tankLevelMethodMixed => 'pomiar mieszany';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Zapisz tankowanie, aby zobaczyć poziom paliwa';

  @override
  String get tankLevelDetailSheetTitle => 'Trasy od ostatniego tankowania';

  @override
  String get addFillUpIsFullTankLabel => 'Pełny bak';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Bak napełniony do pełna — odznacz, jeśli to było częściowe tankowanie';

  @override
  String get themeCardTitle => 'Motyw';

  @override
  String get themeCardSubtitleSystem => 'System';

  @override
  String get themeCardSubtitleLight => 'Jasny';

  @override
  String get themeCardSubtitleDark => 'Ciemny';

  @override
  String get themeSettingsScreenTitle => 'Motyw';

  @override
  String get themeSettingsSystemLabel => 'Zgodnie z systemem';

  @override
  String get themeSettingsLightLabel => 'Jasny';

  @override
  String get themeSettingsDarkLabel => 'Ciemny';

  @override
  String get themeSettingsSystemDescription => 'Dopasuj do wyglądu urządzenia.';

  @override
  String get themeSettingsLightDescription =>
      'Jasne tło — najlepsze do użytku w ciągu dnia.';

  @override
  String get themeSettingsDarkDescription =>
      'Ciemne tło — mniej obciąża oczy w nocy i oszczędza baterię na ekranach OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'Charakterystyczny zielony wygląd aplikacji — jasny i czytelny, z delikatnie zielonymi tłami.';

  @override
  String get throttleRpmHistogramTitle => 'Jak używałeś silnika';

  @override
  String get throttleRpmHistogramThrottleSection => 'Pozycja przepustnicy';

  @override
  String get throttleRpmHistogramRpmSection => 'Obroty silnika';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Wybieg (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Lekki (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Umiarkowany (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Pełny (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Bieg jałowy (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Prędkość przelotowa (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Dynamiczny (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Wysoki (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Brak próbek przepustnicy lub obrotów w tej trasie.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Trasy';

  @override
  String get trajetsStartRecordingButton => 'Rozpocznij nagrywanie';

  @override
  String get trajetsResumeRecordingButton => 'Wznów nagrywanie';

  @override
  String get tripStartProgressConnectingAdapter => 'Łączenie z adapterem OBD2…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Odczytywanie danych pojazdu…';

  @override
  String get tripStartProgressStartingRecording => 'Uruchamianie nagrywania…';

  @override
  String get trajetsEmptyStateTitle => 'Brak tras';

  @override
  String get trajetsEmptyStateBody =>
      'Dotknij Rozpocznij nagrywanie, aby zacząć rejestrować jazdy.';

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
  String get trajetDetailSummaryTitle => 'Podsumowanie';

  @override
  String get trajetDetailFieldDate => 'Data';

  @override
  String get trajetDetailFieldVehicle => 'Pojazd';

  @override
  String get trajetDetailFieldAdapter => 'Adapter OBD2';

  @override
  String get trajetDetailFieldDistance => 'Dystans';

  @override
  String get trajetDetailFieldDuration => 'Czas trwania';

  @override
  String get trajetDetailFieldAvgConsumption => 'Śr. zużycie';

  @override
  String get trajetDetailFieldFuelUsed => 'Zużyte paliwo';

  @override
  String get trajetDetailFieldFuelCost => 'Koszt paliwa';

  @override
  String get trajetDetailFieldAvgSpeed => 'Śr. prędkość';

  @override
  String get trajetDetailFieldMaxSpeed => 'Maks. prędkość';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Prędkość (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Przepływ paliwa (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Obciążenie silnika (%)';

  @override
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

  @override
  String get trajetDetailChartsSection => 'Wykresy';

  @override
  String get trajetsRowColdStartChip => 'Zimny start';

  @override
  String get trajetsRowColdStartTooltip =>
      'Silnik nie osiągnął temperatury roboczej podczas tej trasy — zużycie paliwa było wyższe niż zwykle.';

  @override
  String get trajetDetailChartEmpty => 'Brak zarejestrowanych próbek';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Udostępnij';

  @override
  String get trajetDetailShareImageOption => 'Udostępnij obraz';

  @override
  String get trajetDetailShareGpxOption => 'Udostępnij ścieżkę GPS (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Brak danych GPS w tym przejazdzie';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — trasa z dnia $date';
  }

  @override
  String get trajetDetailShareError =>
      'Nie można wygenerować obrazu do udostępnienia';

  @override
  String get trajetDetailDeleteAction => 'Usuń';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Usunąć tę trasę?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ta trasa zostanie trwale usunięta z historii.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Anuluj';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Usuń';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adapter OBD2 połączony, ale nie zwraca danych. Spróbuj innego adaptera lub sprawdź protokół diagnostyczny pojazdu.';

  @override
  String get trajetsViewAllOnMap => 'Pokaż wszystkie na mapie';

  @override
  String get trajetsMapTitle => 'Trasy na mapie';

  @override
  String get trajetsMapShareGpx => 'Udostępnij GPX';

  @override
  String get trajetsMapEmpty =>
      'Żaden z wybranych przejazdów nie ma danych GPS.';

  @override
  String get trajetsMapShareError => 'Nie udało się udostępnić pliku GPX';

  @override
  String get tripLengthCardTitle => 'Zużycie wg długości trasy';

  @override
  String get tripLengthBucketShort => 'Krótka (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Średnia (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Długa (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Potrzeba więcej danych';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trasy/tras',
      one: '1 trasa',
      zero: 'brak tras',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Ścieżka trasy';

  @override
  String get tripPathCardSubtitle => 'Trasa nagrana przez GPS';

  @override
  String get tripPathLegendTitle => 'Zużycie';

  @override
  String get tripPathLegendEfficient => 'Efektywne (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Graniczne (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Nieefektywne (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get tripRecordingPinTooltip =>
      'Przypięcie utrzymuje ekran włączony — zużywa więcej baterii';

  @override
  String get tripRecordingPinSemanticOn => 'Odepnij formularz nagrywania';

  @override
  String get tripRecordingPinSemanticOff => 'Przypnij formularz nagrywania';

  @override
  String get tripRecordingPinHelpTooltip => 'Co robi przypięcie?';

  @override
  String get tripRecordingPinHelpTitle => 'O przypięciu';

  @override
  String get tripRecordingPinHelpBody =>
      'Przypięcie utrzymuje ekran włączony i ukrywa paski systemowe, aby formularz był czytelny na uchwycie samochodowym. Dotknij ponownie, aby zwolnić. Automatycznie zwalnia po zakończeniu trasy.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Nagrywanie trwa w tle. Dotknij czerwonego baneru na górze dowolnego ekranu, aby wrócić.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Otwórz aktywną trasę z karty Zużycie';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Przypnij ekran, aby utrzymać GPS aktywny podczas trasy — Android może ograniczać GPS podczas uśpienia.';

  @override
  String get tripRecordingMinimiseTooltip =>
      'Zminimalizuj do pływającego kafelka';

  @override
  String get tripRecordingAutoPinTitle =>
      'Zawsze przypnij przy starcie nagrywania';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Przypnij formularz automatycznie podczas każdej jazdy, zamiast dotykać za każdym razem. Zużywa więcej baterii.';

  @override
  String get tripRecordingConnectingTitle => 'Rozpoczynanie nagrywania…';

  @override
  String get tripShareAction => 'Udostępnij innemu kontu';

  @override
  String get tripShareSheetTitle => 'Udostępnij tę trasę';

  @override
  String get tripShareSheetSubtitle =>
      'Daj innemu kontu TankSync dostęp tylko do odczytu do tej zarejestrowanej trasy.';

  @override
  String get tripShareEmailLabel => 'E-mail odbiorcy';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Udostępnij';

  @override
  String get tripShareCreateLinkButton => 'Utwórz link udostępniania';

  @override
  String get tripShareLinkCreated =>
      'Link udostępniania skopiowano — wklej go odbiorcy.';

  @override
  String get tripShareSuccess => 'Trasa udostępniona.';

  @override
  String get tripShareRecipientNotFound =>
      'Żadne konto TankSync nie używa tego e-maila.';

  @override
  String get tripShareError =>
      'Nie udało się udostępnić trasy. Spróbuj ponownie.';

  @override
  String get tripShareExistingTitle => 'Udostępniono';

  @override
  String get tripShareExistingEmpty => 'Jeszcze nikomu nie udostępniono.';

  @override
  String get tripShareDirectRecipient => 'Konto';

  @override
  String get tripShareLinkRecipient => 'Link udostępniania (nieodebrany)';

  @override
  String get tripShareRevokeTooltip => 'Cofnij';

  @override
  String get tripShareRevoked => 'Udostępnianie cofnięte.';

  @override
  String get trajetsSharedSectionTitle => 'Udostępnione mnie';

  @override
  String get trajetsSharedBadge => 'Udostępnione';

  @override
  String get unifiedFilterFuel => 'Paliwo';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Oba';

  @override
  String get unifiedNoResultsForFilter =>
      'Brak wyników pasujących do tego filtra';

  @override
  String get searchFailedSnackbar =>
      'Wyszukiwanie nie powiodło się — spróbuj ponownie';

  @override
  String get vinLabel => 'VIN (opcjonalnie)';

  @override
  String get vinDecodeTooltip => 'Dekoduj VIN';

  @override
  String get vinConfirmAction => 'Tak, uzupełnij automatycznie';

  @override
  String get vinModifyAction => 'Zmień ręcznie';

  @override
  String get veResetAction => 'Resetuj sprawność objętościową';

  @override
  String get vehicleReadVinFromCarButton => 'Odczytaj VIN z samochodu';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Odczytaj VIN ze sparowanego adaptera OBD2';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN niedostępny (Tryb 09 PID 02 nieobsługiwany w pojazdach sprzed 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Odczyt VIN nie powiódł się — wprowadź ręcznie';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Najpierw sparuj adapter OBD2, aby automatycznie odczytać VIN';

  @override
  String get pickerButtonLabel => 'Wybierz z katalogu';

  @override
  String get pickerSearchHint => 'Szukaj marki lub modelu';

  @override
  String get pickerHelpText =>
      'Wstępnie uzupełnij z 50+ obsługiwanych pojazdów';

  @override
  String get pickerEmptyResults => 'Brak wyników';

  @override
  String get pickerCancel => 'Anuluj';

  @override
  String get pickerLoading => 'Ładowanie katalogu…';

  @override
  String get vinInfoTooltip => 'Co to jest VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Co to jest VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Numer identyfikacyjny pojazdu to 17-znakowy kod unikalny dla Twojego samochodu. Jest wybity na nadwoziu i wydrukowany w dowodzie rejestracyjnym.';

  @override
  String get vinInfoSectionWhyTitle => 'Dlaczego pytamy';

  @override
  String get vinInfoSectionWhyBody =>
      'Dekodowanie VIN automatycznie wypełnia pojemność silnika, liczbę cylindrów, rok produkcji, główny rodzaj paliwa i masę całkowitą — oszczędzając Ci szukania danych technicznych. Obliczenie zużycia paliwa OBD2 używa tych wartości do podawania dokładnych wyników.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Prywatność';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Twój VIN jest przechowywany tylko lokalnie w zaszyfrowanym magazynie aplikacji — nigdy nie jest przesyłany na serwery Sparkilo. Baza danych NHTSA vPIC jest zapytywana o VIN, ale zwraca tylko anonimowe dane techniczne; NHTSA nie łączy VIN z danymi osobowymi. Bez sieci, wyszukiwanie offline zwraca tylko producenta i kraj.';

  @override
  String get vinInfoSectionWhereTitle => 'Gdzie go znaleźć';

  @override
  String get vinInfoSectionWhereBody =>
      'Spójrz przez przednią szybę w dolny lewy róg po stronie kierowcy, sprawdź naklejkę na ramie drzwi po stronie kierowcy gdy drzwi są otwarte lub odczytaj go z dowodu rejestracyjnego pojazdu (karta / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Rozumiem';

  @override
  String get vinConfirmPrivacyNote =>
      'Wyszukaliśmy Twój VIN w bezpłatnej bazie danych NHTSA — nic nie zostało wysłane na serwery Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Dekodowanie VIN online';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Dekoduj VIN przez bezpłatną usługę publiczną NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Gdy paryujesz adapter, VIN pojazdu jest odczytywany lokalnie w celu identyfikacji samochodu. Włączenie tego wysyła 17-znakowy VIN do bezpłatnej usługi NHTSA vPIC w celu wyszukania dodatkowych szczegółów (model, pojemność silnika, rodzaj paliwa). VIN to jedyne wysyłane dane — żadne inne informacje nie opuszczają urządzenia.';

  @override
  String get vehicleDetectedFromVinBadge => '(wykryto)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Wykryto z VIN: $summary. Zastosować?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Zastosuj';

  @override
  String get widgetHelpSectionTitle => 'Widget ekranu głównego';

  @override
  String get widgetHelpIntro =>
      'Dodaj widget SparKilo do ekranu głównego, aby zobaczyć ceny paliwa i ładowania na pierwszy rzut oka.';

  @override
  String get widgetHelpAdd =>
      'Dodaj go z selektora widgetów programu uruchamiającego — naciśnij i przytrzymaj pusty obszar ekranu głównego, wybierz Widgety i znajdź SparKilo.';

  @override
  String get widgetHelpTap =>
      'Dotknij stacji w widgecie, aby otworzyć ją w aplikacji. Dotknij ikony odświeżania, aby zaktualizować ceny.';

  @override
  String get widgetHelpConfigure =>
      'Na Androidzie naciśnij i przytrzymaj widget i wybierz Skonfiguruj ponownie, aby zmienić profil, kolor i zawartość.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Poniższe wybory zostaną zastosowane do każdego zainstalowanego widżetu przy następnym odświeżeniu.';

  @override
  String get widgetDefaultsColorLabel => 'Schemat kolorów';

  @override
  String get widgetDefaultsVariantLabel => 'Wariant zawartości';

  @override
  String get widgetColorSchemeSystem => 'Według systemu';

  @override
  String get widgetColorSchemeLight => 'Jasny';

  @override
  String get widgetColorSchemeDark => 'Ciemny';

  @override
  String get widgetColorSchemeBlue => 'Niebieski';

  @override
  String get widgetColorSchemeGreen => 'Zielony';

  @override
  String get widgetColorSchemeOrange => 'Pomarańczowy';

  @override
  String get widgetVariantDefault => 'Tylko aktualna cena';

  @override
  String get widgetVariantPredictive =>
      'Prognoza: najlepszy czas na tankowanie';

  @override
  String get widgetPredictiveNowPrefix => 'teraz';
}
