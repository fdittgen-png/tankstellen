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
  String get fabRunSearch => 'Uruchom wyszukiwanie';

  @override
  String get routeSearchingChip => 'Wyszukiwanie trasy…';

  @override
  String get searchCriteriaTitle => 'Kryteria wyszukiwania';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'W promieniu $km km';
  }

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
  String get freeNoKey => 'Bezpłatnie — klucz nie jest wymagany';

  @override
  String get apiKeyRequired => 'Wymagany klucz API';

  @override
  String get dataTransparency => 'Przejrzystość danych';

  @override
  String get clearCache => 'Wyczyść pamięć podręczną';

  @override
  String stationsFound(int count) {
    return 'Znaleziono $count stacji';
  }

  @override
  String get storageUsage => 'Wykorzystanie pamięci na tym urządzeniu';

  @override
  String get settingsLabel => 'Ustawienia';

  @override
  String get total => 'Razem';

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
  String get deleteAllButton => 'Usuń wszystko';

  @override
  String get cacheEmpty => 'Pamięć podręczna jest pusta';

  @override
  String get apiKeyNote =>
      'Bezpłatna rejestracja. Dane od rządowych agencji przejrzystości cen.';

  @override
  String get apiKeyFormatError =>
      'Nieprawidłowy format — oczekiwany UUID (8-4-4-4-12)';

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
  String get searchLocationPlaceholder => 'Adres, kod pocztowy lub miasto';

  @override
  String get configTankSyncConnected => 'Połączono';

  @override
  String get configTankSyncDisabled => 'Wyłączono';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get fuels => 'Paliwa';

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
  String profileSwitchedTo(String profile) {
    return 'Przełączono na $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profil $name utworzony';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Profil dla $country już istnieje — zamiast tego edytuj go.';
  }

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
  String get evPriceFree => 'Bezpłatnie';

  @override
  String get evPricePayAtLocation => 'Płatność na miejscu';

  @override
  String get evPriceMembership => 'Wymagane członkostwo';

  @override
  String get evPriceIndicative => 'Cena orientacyjna';

  @override
  String get evPriceDeclaredByOperator =>
      'Orientacyjna cena zadeklarowana przez operatora — zweryfikuj na miejscu';

  @override
  String get evPriceFranceAttribution =>
      'Ceny: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Ceny z OpenChargeMap według najlepszych starań — mogą być niepełne.';

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
  String get edit => 'Edytuj';

  @override
  String get fuelPricesApiKey => 'Klucz API cen paliw';

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
  String get noStationsAlongThisRoute =>
      'Nie znaleziono stacji wzdłuż tej trasy.';

  @override
  String get fuelCostCalculator => 'Kalkulator kosztów paliwa';

  @override
  String get distanceKm => 'Odległość (km)';

  @override
  String get tripCost => 'Koszt podróży';

  @override
  String get fuelNeeded => 'Potrzebne paliwo';

  @override
  String get totalCost => 'Koszt całkowity';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Dystans ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Zużycie ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Cena paliwa ($unit)';
  }

  @override
  String get calculatorUseMine => 'Użyj';

  @override
  String get calculatorApplied => 'Zastosowano';

  @override
  String get tripDetails => 'Szczegóły trasy';

  @override
  String get calculatorRoundTrip => 'W obie strony';

  @override
  String get roundTripTotal => 'Łącznie w obie strony';

  @override
  String get costPerDistance => 'Koszt na km';

  @override
  String get costPerMonth => 'Koszt miesięczny';

  @override
  String get calculatorEstimateMonthly => 'Szacuj koszt miesięczny';

  @override
  String get calculatorTripsPerMonth => 'Trasy miesięcznie';

  @override
  String get calculatorTripsPerMonthHint => 'np. 20';

  @override
  String get calculatorReset => 'Resetuj';

  @override
  String get calculatorResultPlaceholder =>
      'Wypełnij dystans, zużycie i cenę, aby zobaczyć koszt trasy';

  @override
  String get priceHistory => 'Historia cen';

  @override
  String get favoritesDataCache => 'Dane ulubionych';

  @override
  String get citySearchCache => 'Wyszukiwanie miasta';

  @override
  String get noPriceHistory => 'Brak historii cen';

  @override
  String get noStatistics => 'Brak dostępnych statystyk';

  @override
  String get showAllFuelTypes => 'Pokaż wszystkie typy paliw';

  @override
  String get connected => 'Połączono';

  @override
  String get disconnectTankSync => 'Odłącz TankSync';

  @override
  String get viewMyData => 'Zobacz moje dane';

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
  String get gdprContinueAll => 'Kontynuuj ze wszystkimi';

  @override
  String get gdprContinueSelected => 'Kontynuuj z wybranymi';

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
  String get privacySyncMode => 'Tryb synchronizacji';

  @override
  String get privacySyncUserId => 'ID użytkownika';

  @override
  String get privacySyncDescription =>
      'Gdy synchronizacja jest włączona, ulubione, alerty, ukryte stacje i oceny są również przechowywane na serwerze TankSync.';

  @override
  String get privacyExportSuccess => 'Dane wyeksportowane do schowka';

  @override
  String get privacyExportCsvSuccess => 'Dane CSV wyeksportowane do schowka';

  @override
  String get savedToDownloadsFolder => 'Zapisano w folderze Pobrane';

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
  String get voiceAnnouncementProximityRadius => 'Promień ogłoszeń';

  @override
  String get voiceAnnouncementCooldown => 'Interwał powtórzeń';

  @override
  String get voiceAnnouncementPriceLimit => 'Cena maksymalna';

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
  String get obdPermissionDenied =>
      'Przyznaj uprawnienie Bluetooth w ustawieniach systemowych';

  @override
  String get obdPickerTitle => 'Wybierz adapter OBD2';

  @override
  String get obdPickerScanning => 'Skanowanie w poszukiwaniu adapterów…';

  @override
  String get obdPickerConnecting => 'Łączenie…';

  @override
  String get tripSummaryTitle => 'Podsumowanie trasy';

  @override
  String get tripMetricDistance => 'Dystans';

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
  String get vehicleBaselineShowDetails => 'Pokaż podział według sytuacji';

  @override
  String get vehicleBaselineHideDetails => 'Ukryj podział według sytuacji';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Jeszcze nie wykryto: $situations. Te sytuacje jazdy nadal mają 0 próbek, więc linia bazowa jest niekompletna.';
  }

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
  String get obd2StatusPermissionDenied =>
      'Adapter OBD2: wymagane uprawnienie Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Gotowy do nagrywania trasy.';

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
  String get situationColdStart => 'Zimny rozruch';

  @override
  String get situationSustainedLoad => 'Długotrwałe obciążenie / holowanie';

  @override
  String get situationPartialDecel => 'Jazda na biegu jałowym';

  @override
  String get situationHardAccel => 'Gwałtowne przyspieszenie';

  @override
  String get situationFuelCut => 'Odcięcie paliwa — wybieg';

  @override
  String get tripSaveRecording => 'Zapisz trasę';

  @override
  String get tripSummaryAutoSaved => 'Podróż zapisana automatycznie';

  @override
  String get tripSummaryDone => 'Gotowe';

  @override
  String get tripSummaryDelete => 'Usuń tę podróż';

  @override
  String get vehicleFuelNotSet => 'Nie ustawiono';

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
  String get vehiclePowerLabel => 'Moc silnika (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps KM';
  }

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
  String get evStatusAvailable => 'Dostępna';

  @override
  String get evStatusOccupied => 'Zajęta';

  @override
  String get evStatusOutOfOrder => 'Awaria';

  @override
  String get evStatusPartial => 'Częściowo dostępne';

  @override
  String get openOnlyFilter => 'Tylko otwarte';

  @override
  String get saveAsDefaults => 'Zapisz jako moje domyślne';

  @override
  String get criteriaSavedToProfile => 'Zapisano jako domyślne';

  @override
  String get updatingFavorites => 'Aktualizowanie ulubionych...';

  @override
  String get fetchingLatestPrices => 'Pobieranie najnowszych cen';

  @override
  String get noDataAvailable => 'Brak danych';

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
  String get sectionPrivacyData => 'Prywatność i dane';

  @override
  String get sectionAdvancedDeveloper => 'Zaawansowane i deweloperskie';

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
  String get minimalDriveBehaviour => 'Styl jazdy';

  @override
  String get coachingShiftUp => 'Zmień bieg w górę';

  @override
  String get coachingShiftDown => 'Zmień bieg w dół';

  @override
  String get coachingEasePedal => 'Puść gaz';

  @override
  String get coachingVoiceHardAcceleration => 'Łagodniej na gazie';

  @override
  String get coachingVoiceHarshBraking => 'Staraj się hamować łagodniej';

  @override
  String get coachingVoiceShiftUp => 'Wrzuć wyższy bieg i zaoszczędź paliwo';

  @override
  String get coachingVoiceShiftDown =>
      'Zredukuj bieg, silnik pracuje z wysiłkiem';

  @override
  String get coachingVoiceEasePedal =>
      'Zdejmij nogę z gazu, by zmniejszyć zużycie paliwa';

  @override
  String get coachingVoiceLiftOff => 'Zdejmij nogę z gazu i jedź na wybiegu';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Patrz dalej do przodu i wcześniej zdejmij nogę z gazu';

  @override
  String get coachingVoiceSmoothAccel => 'Przyspieszaj płynniej';

  @override
  String get coachingVoiceSharpCorner => 'Bierz zakręty trochę łagodniej';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Bardzo gwałtowne hamowanie — zachowaj większy odstęp';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Bardzo gwałtowne przyspieszenie — to naprawdę spala paliwo';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Bardzo ostry zakręt — wolno wejdź, płynnie wyjdź';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount gwałtownego manewru.',
      many: '$harshCount gwałtownych manewrów.',
      few: '$harshCount gwałtowne manewry.',
      one: 'Jeden gwałtowny manewr.',
      zero: 'Płynnie i bez gwałtownych manewrów.',
    );
    return 'Podróż zapisana: $distanceKm kilometrów, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litra na 100 kilometrów';
  }

  @override
  String get voiceCoachingSettingTitle => 'Głosowy coaching jazdy';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Słuchaj mówionych wskazówek podczas jazdy — gwałtowne przyspieszanie, ostre hamowanie i podpowiedzi dotyczące biegów';

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
  String get tankSyncSchemaOutdatedTitle =>
      'Baza w chmurze wymaga aktualizacji';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Twój samodzielnie hostowany schemat TankSync jest nieaktualny — część danych nie może się synchronizować. Otwórz kreator synchronizacji i uruchom SQL aktualizacji w swoim projekcie Supabase.';

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
  String get syncSchemaOutdated =>
      'Twój schemat TankSync jest nieaktualny — uruchom ponownie poniższy SQL konfiguracyjny, aby włączyć najnowsze funkcje synchronizacji.';

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
      'Współdzielona baza danych prowadzona przez dewelopera — poniżej zobaczysz, co jest synchronizowane';

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
  String serviceReminderDueNowBody(String label) {
    return '$label — termin właśnie nadszedł.';
  }

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
  String get obd2GpsDegradedBannerTitle =>
      'Nagrywanie z GPS — OBD2 wznawia połączenie';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Nagrywanie z GPS — oczekiwanie na adapter OBD2';

  @override
  String get alertsStationSectionTitle => 'Alerty stacji';

  @override
  String get alertsStationAdd => 'Dodaj alert stacji';

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
  String radiusAlertDeleted(String name) {
    return 'Alert zasięgu \"$name\" usunięty';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 połączony: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Sparuj adapter OBD2';

  @override
  String get fillUpSavedSnackbar => 'Tankowanie zapisane';

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
  String get obd2ErrorEngineOff =>
      'Brak danych z pojazdu — uruchom silnik i spróbuj ponownie.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Adapter OBD2 wysłał nierozpoznaną odpowiedź. Może być niekompatybilny — wypróbuj inny adapter.';

  @override
  String get obd2ErrorDisconnected =>
      'Adapter OBD2 został odłączony. Połącz ponownie i spróbuj jeszcze raz.';

  @override
  String get obd2ErrorPairingRequired =>
      'Adapter wymaga parowania Bluetooth. Odłącz adapter, podłącz go ponownie i spróbuj jeszcze raz w ciągu 5 minut.';

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
  String alertsLastChecked(String when) {
    return 'Ostatnie sprawdzenie: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Ceny nie zostały jeszcze sprawdzone w tle';

  @override
  String get alertsIosBestEffortNote =>
      'Na iPhonie sprawdzanie alertów odbywa się w miarę możliwości: to iOS decyduje, kiedy aplikacja może sprawdzić ceny w tle, więc alert może przyjść z opóźnieniem lub czasem wcale. Otwarcie aplikacji zawsze uruchamia nowe sprawdzenie.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Cena docelowa ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Próg ($currency/L)';
  }

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
  String fuelStationRadarProximity(int percent) {
    return 'Bliskość $percent%';
  }

  @override
  String get pipTapToRestore => 'Dotknij, aby otworzyć pełną aplikację';

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
  String get authLinkEmailTitle => 'Powiąż adres e-mail';

  @override
  String get authLinkEmailSubtitle =>
      'Powiąż adres e-mail, aby dane synchronizowały się między urządzeniami. Obecne ulubione i podróże pozostaną na tym koncie.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Używasz konta gościa ($idPrefix…). Powiąż adres e-mail, aby ulubione i podróże synchronizowały się z innymi urządzeniami.';
  }

  @override
  String get authConfirmationPending =>
      'Prawie gotowe — sprawdź pocztę i kliknij link, aby dokończyć powiązanie. Twoje dane są już zapisane na tym koncie.';

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
  String get aclWakeNotificationTitle => 'Samochód połączony';

  @override
  String get aclWakeNotificationBody =>
      'Dotknij, aby otworzyć Sparkilo — można rozpocząć nagrywanie podróży.';

  @override
  String get exportBackupReady => 'Kopia zapasowa gotowa — wybierz lokalizację';

  @override
  String get exportBackupFailed =>
      'Eksport kopii zapasowej nie powiódł się — spróbuj ponownie';

  @override
  String get backupExportProgress => 'Eksportowanie kopii zapasowej…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Zapisano w folderze Pobrane jako $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Przywróć kopię zapasową';

  @override
  String get restoreBackupDialogBody =>
      'Scalanie dodaje i aktualizuje rekordy z kopii zapasowej, zachowując wszystko, co jest już na tym urządzeniu. Zastąpienie usuwa wszystkie bieżące dane, a następnie przywraca wyłącznie kopię zapasową — tej operacji nie można cofnąć.';

  @override
  String get restoreBackupMergeAction => 'Scal';

  @override
  String get restoreBackupReplaceAction => 'Zastąp wszystko';

  @override
  String get restoreBackupEmpty =>
      'Kopia zapasowa przywrócona — nie zawierała żadnych rekordów';

  @override
  String get restoreBackupCorrupt =>
      'Przywracanie nie powiodło się — ten plik nie jest prawidłową kopią zapasową Tankstellen';

  @override
  String get restoreBackupFailed =>
      'Przywracanie nie powiodło się — nie można odczytać pliku';

  @override
  String get backupImportProgress => 'Przywracanie kopii zapasowej…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Scalono $vehicles pojazdów, $fillUps tankowań, $trips tras, $chargingLogs dzienników ładowania';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Zastąpiono wszystkie dane: $vehicles pojazdów, $fillUps tankowań, $trips tras, $chargingLogs dzienników ładowania';
  }

  @override
  String get brokenMapChipDisclaimer => 'Podejrzane odczyty MAP';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Czujnik MAP odczytuje błędnie — odczyty paliwa mogą być o 50–80% za niskie. Spróbuj innego adaptera.';

  @override
  String get brokenMapBannerHardDisable =>
      'Czujnik MAP zawodny. Wyświetlam średnie tankowania zamiast aktualnego zużycia paliwa.';

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
  String get calibrationDirectFuelRateNote =>
      'Ten pojazd podaje zużycie paliwa bezpośrednio (PID 5E), więc kalibracja sprawności wolumetrycznej nie jest używana — Twoje spalanie jest mierzone, a nie modelowane.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Twój $makeModel jest oznaczony jako diesel, ale pasuje do katalogowej pozycji benzynowej. Dotknij, aby zaktualizować.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Aktualizuj';

  @override
  String get catalogResetAction => 'Przywróć z bazy pojazdów';

  @override
  String get catalogResetConfirmTitle => 'Przywrócić z bazy pojazdów?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Zastępuje pojemność baku, moc silnika i pojemność skokową tego pojazdu wartościami z bazy dla $vehicle. Pozostałe pola i historia tankowań pozostają bez zmian.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'Brak pasującego wpisu w bazie pojazdów dla tego pojazdu.';

  @override
  String get catalogResetDoneSnackbar => 'Dane pojazdu przywrócone z bazy.';

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
  String get confirmDeleteTitle => 'Usunąć?';

  @override
  String get confirmDeleteBody => 'Czy na pewno chcesz to usunąć?';

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
  String get consoGroupVehicles => 'Pojazdy';

  @override
  String get consoGroupCoaching => 'Coaching podczas jazdy';

  @override
  String get consoGroupRewards => 'Nagrody i oszczędności';

  @override
  String get consoGroupTroubleshooting => 'Rozwiązywanie problemów';

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
  String get moreActionsTooltip => 'Więcej';

  @override
  String get exportBackupMenuLabel => 'Eksportuj kopię zapasową';

  @override
  String get restoreBackupMenuLabel => 'Przywróć kopię zapasową';

  @override
  String get carbonDashboardMenuLabel => 'Panel emisji CO2';

  @override
  String get settingsMenuLabel => 'Ustawienia';

  @override
  String get consumptionStatsPageTitle => 'Statystyki zużycia';

  @override
  String get consumptionStatsComparisonTitle =>
      'Ten miesiąc vs poprzedni miesiąc';

  @override
  String get consumptionStatsTrendsTitle => 'Ewolucja w czasie';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Rejestruj tankowania przez co najmniej dwa miesiące, aby porównać.';

  @override
  String get consumptionStatsPricePerLiter => 'Śr. cena/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litry miesięcznie';

  @override
  String get consumptionStatsChartSpend => 'Wydatki miesięcznie';

  @override
  String get consumptionStatsChartPricePerLiter => 'Cena za litr';

  @override
  String get consumptionStatsChartConsumption => 'L/100km miesięcznie';

  @override
  String get fuelCompareSectionTitle => 'Koszt jazdy według paliwa';

  @override
  String get fuelComparePricePerLitre => 'Zapłacono za litr';

  @override
  String get fuelCompareCostPer100km => 'Koszt na 100 km';

  @override
  String get fuelCompareDistance => 'Zmierzony dystans';

  @override
  String get fuelCompareLitres => 'Zużyte litry';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner to Twoje najtańsze paliwo w jeździe';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser kosztuje o $amount więcej na 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel wygrywa z $rival poniżej $price za litr';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'Próg opłacalności liczony jest ze zmierzonego zużycia każdego paliwa, więc zmienia się wraz z Twoim stylem jazdy.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litry i koszt mogą się rozmijać: paliwo może spalać mniej litrów na 100 km, a i tak kosztować więcej za kilometr, bo cena za litr jest inna. Rozstrzyga koszt na kilometr.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pełnych baków',
      one: 'jednego pełnego baku',
    );
    return 'Wstępnie — na podstawie $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pełnych baków',
      one: 'jednego pełnego baku',
    );
    return 'Na podstawie $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 na 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner to Twoje paliwo o najniższej emisji';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel kosztuje o $money więcej na 1000 km, ale emituje o $co2 mniej CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel jest jednocześnie tańsze i czystsze niż $rival';
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
    return 'Twoje $distance na $fuel wyemitowało $actual zamiast $alternative na $rival — uniknięto $saved';
  }

  @override
  String get fuelCompareCo2Source =>
      'Wartości CO2 to szacunki „od źródła do koła” (EU JEC WTW v5) zastosowane do Twojego zmierzonego zużycia — orientacyjne, nie certyfikowana ewidencja.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'CO2 pokazujemy tylko dla paliw czystych: współczynnik emisji mieszanki zależy od jej składu, którego ten wiersz nie zapisuje.';

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
    return 'Korekty: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Zgłoś treść';

  @override
  String get contentModerationBlockAction => 'Zablokuj autora';

  @override
  String get contentModerationReportDialogTitle => 'Zgłosić tę treść?';

  @override
  String get contentModerationReportDialogBody =>
      'Zgłoszenie zostanie wysłane do Twojego serwera TankSync do weryfikacji, a ta treść zostanie ukryta na Twoim urządzeniu.';

  @override
  String get contentModerationReportConfirmButton => 'Zgłoś';

  @override
  String get contentModerationBlockDialogTitle => 'Zablokować tego autora?';

  @override
  String get contentModerationBlockDialogBody =>
      'Wszystko, co to konto Ci udostępnia, zostanie ukryte na tym urządzeniu.';

  @override
  String get contentModerationBlockConfirmButton => 'Zablokuj';

  @override
  String get contentModerationReportedSnack =>
      'Zgłoszenie wysłane — treść ukryta.';

  @override
  String get contentModerationReportFailedSnack =>
      'Nie udało się wysłać zgłoszenia. Spróbuj ponownie.';

  @override
  String get contentModerationBlockedSnack =>
      'Autor zablokowany — udostępniane treści są ukryte.';

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
  String crossBorderCheaper(String country, String km, String price) {
    return 'Stacje w $country $km km stąd — €$price/L taniej';
  }

  @override
  String get crossBorderTapToSwitch => 'Dotknij, aby zmienić kraj';

  @override
  String get crossBorderDismissTooltip => 'Odrzuć';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Otwórz źródło danych $source ($license) w przeglądarce';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© autorzy $brand';
  }

  @override
  String get developerToolsSectionTitle => 'Narzędzia programisty';

  @override
  String get dataAccessTracerExport => 'Eksportuj dziennik dostępu do danych';

  @override
  String get dataAccessTracerExportSuccess =>
      'Dziennik dostępu do danych zapisany w Pobranych.';

  @override
  String get dataAccessTracerExportFailure =>
      'Nie udało się wyeksportować dziennika dostępu do danych.';

  @override
  String get dataAccessTracerEmpty =>
      'Brak zarejestrowanych zdarzeń dostępu do danych — najpierw wyszukaj lub otwórz stacje, potem eksportuj.';

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
      'Najpierw wyszukaj stacje, a następnie uruchom testowe powiadomienie, aby mogło otworzyć prawdziwą stację.';

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
  String get startupTraceSectionTitle =>
      'Dziennik inicjalizacji przy uruchomieniu';

  @override
  String get startupTraceExportButton => 'Eksportuj dziennik uruchamiania';

  @override
  String get startupTraceEmpty =>
      'Nie zarejestrowano jeszcze dziennika uruchamiania.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Łącznie: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Dziennik uruchamiania zapisany w Pobranych.';

  @override
  String get startupTraceExportFailure =>
      'Nie udało się wyeksportować dziennika uruchamiania.';

  @override
  String get distanceSourceOdometer => 'Licznik';

  @override
  String get distanceSourceOdometerTooltip =>
      'Dystans odczytany z licznika samochodu — zmierzony punkt odniesienia.';

  @override
  String get distanceSourceGps => 'Ślad GPS';

  @override
  String get distanceSourceGpsTooltip =>
      'Dystans zsumowany z zarejestrowanego śladu GPS — rzeczywista odległość drogowa.';

  @override
  String get distanceSourceEstimated => 'Szacowany';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Dystans scałkowany z czujnika prędkości — szacunek; czujnik zwykle nieco zawyża.';

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
    return 'Pełny gaz ($pctTime% trasy): zmarnowano $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Naciskaj pedał delikatnie — łagodne 70 % gazu wystarczy, aby rozpędzić się przy znacznie mniejszym zużyciu paliwa.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Bogata mieszanka pod obciążeniem ($pctTime% trasy): zmarnowano $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Duże, długotrwałe obciążenie powoduje wzbogacenie mieszanki — zmieniaj biegi wcześniej i zmniejsz obciążenie na długich podjazdach, aby mieszanka pozostała uboga.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Jazda pod górę przy $gradePercent% nachyleniu ($pctTime% trasy): zmarnowano $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Wejdź w wzniesienie z impetu i płynnie dawaj gaz — gwałtowne przyspieszanie pod górę zużywa dodatkowe paliwo.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count zatrzymań i ruszeń: zmarnowano $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Przewiduj ruch i jedź na wybiegu do zatrzymań, by toczyć się zamiast ruszać od zera — ruszenie z miejsca to najbardziej paliwożerny element jazdy w korkach.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Mieszanka wygląda na nieco ubogą — silnik dodał paliwa (korekta $pctTrim %), aby to skompensować';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Mieszanka wygląda na ubogą — silnik utrzymywał dużą, $pctTrim % korektę wzbogacającą; możliwa nieefektywność';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Mieszanka wygląda na nieco bogatą — silnik odjął paliwa (korekta $pctTrim %), aby to skompensować';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Mieszanka wygląda na bogatą — silnik utrzymywał dużą, $pctTrim % korektę zubażającą; możliwa nieefektywność';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Silnik pracował na bogatej mieszance pod obciążeniem ($pctShare % jazdy na ciepłym silniku) — możliwa strata paliwa';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heurystyczny sygnał stanu, nie diagnoza';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Utrzymująca się korekta w stronę ubogiej mieszanki może oznaczać nieszczelność dolotu, słabe zasilanie paliwem lub starzejący się czujnik. Jeśli spalanie lub praca silnika się pogorszą, diagnostyka w warsztacie może to potwierdzić.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Utrzymująca się korekta w stronę bogatej mieszanki może oznaczać nieszczelny wtryskiwacz, zbyt wysokie ciśnienie paliwa lub zawyżający czujnik. Jeśli spalanie lub praca silnika się pogorszą, diagnostyka w warsztacie może to potwierdzić.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Bogata mieszanka pod dużym obciążeniem spala dodatkowe paliwo. Zmieniaj biegi wcześniej i odpuszczaj gaz przy długich przyspieszeniach, aby silnik pozostał blisko mieszanki stechiometrycznej.';

  @override
  String get lessonTransportTitle =>
      'Brak danych z silnika przez większość tej podróży';

  @override
  String get lessonTransportAdvice =>
      'Silnik nie zgłaszał aktywności przez niemal cały dystans. Albo strumień OBD2 urwał się w trakcie podróży, albo samochód przemieszczono bez jazdy — wartość spalania jest niewiarygodna i wykluczona ze statystyk.';

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
  String get drivingScoreClassVeryGood => 'Bardzo dobry';

  @override
  String get drivingScoreClassGood => 'Dobry';

  @override
  String get drivingScoreClassAverage => 'Przeciętny';

  @override
  String get drivingScoreClassBad => 'Wymaga poprawy';

  @override
  String get drivingScorePenaltyLugging => 'Ciągnięcie silnika';

  @override
  String get drivingScorePenaltySmoothness => 'Szarpana jazda';

  @override
  String get drivingScorePenaltyHighSpeed => 'Wysoka prędkość';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Agresywny pedał';

  @override
  String get drivingScorePenaltyLambda => 'Bogata mieszanka';

  @override
  String get gpsKpiCardTitle => 'Efektywność GPS';

  @override
  String get gpsKpiRpa => 'Pozytywne przyspieszenie (RPA)';

  @override
  String get gpsKpiPke => 'Zapotrzebowanie na energię kinetyczną (PKE)';

  @override
  String get gpsKpiVapos => 'Intensywność przyspieszenia (VAPOS)';

  @override
  String get gpsKpiCoast => 'Udział jazdy na wybiegu';

  @override
  String get gpsKpiClimbEnergy => 'Energia podjazdów';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs Twoja efektywna linia bazowa';
  }

  @override
  String get drivingTraceCardTitle => 'Ślad analizy jazdy (dev)';

  @override
  String get drivingTraceCardBody =>
      'Eksportuj GPS KPI tej trasy, wynik i wnioski jako JSON, opisz jak przebiegała jazda w polu komentarza i wyślij to z powrotem, aby progi stylu jazdy mogły być skalibrowane względem rzeczywistych tras.';

  @override
  String get drivingTraceExportAction => 'Eksportuj ślad analizy';

  @override
  String get drivingTraceExported =>
      'Ślad analizy zapisany w folderze Pobrane — dodaj swój werdykt w polu komentarza i wyślij z powrotem.';

  @override
  String get drivingTraceExportFailed =>
      'Nie udało się wyeksportować śladu analizy.';

  @override
  String get minimalDriveTripAverage => 'Średnia trasy';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Jazda na wysokich obrotach ($pctTime % podróży): wcześniejsza zmiana biegu mogłaby zaoszczędzić $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Zmieniaj bieg wyżej wcześniej przy stałej prędkości — ta sama prędkość na niższych obrotach spala zauważalnie mniej.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Toczenie z odcięciem paliwa ($pctTime % podróży): zaoszczędzono ok. $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Dobrze przewidziane — wczesne odpuszczenie gazu pozwala silnikowi całkowicie odciąć paliwo podczas toczenia.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Na co poszło Twoje paliwo';

  @override
  String get fuelBreakdownIdle => 'Bieg jałowy';

  @override
  String get fuelBreakdownHarshAccel => 'Gwałtowne przyspieszenia';

  @override
  String get fuelBreakdownHighRpmCruise => 'Jazda na wysokich obrotach';

  @override
  String get fuelBreakdownCoastingSaved => 'Zaoszczędzone na wybiegu';

  @override
  String get fuelBreakdownEfficient => 'Normalna jazda';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Silnik pracuje na biegu jałowym już jakiś czas — wyłączenie go oszczędza paliwo';

  @override
  String get ecoNudgeHarshAccel =>
      'Mocne przyspieszenie — lżejsza noga oszczędza paliwo';

  @override
  String get ecoNudgeHighRpm =>
      'Wysokie obroty przy stałej prędkości — wcześniejsza zmiana biegu oszczędza paliwo';

  @override
  String get obd2CoverageNoneNote =>
      'W tej podróży nie napłynęły żadne dane z silnika przez adapter OBD2 — wartości paliwa to szacunki z GPS.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Dane z silnika urwały się po $percent % podróży (utracono połączenie) — dalsze wartości paliwa to szacunki z GPS.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Dane z silnika objęły tylko $percent % tej podróży — luki wypełniono szacunkami z GPS.';
  }

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
  String get featureLabel_approachOverlay => 'Radar stacji paliw';

  @override
  String get featureDescription_approachOverlay =>
      'Zamień pływającą miniaturę trasy w żywy radar stacji paliw — gdy zbliżasz się do stacji, zmienia kolor na charakterystyczny dla rodzaju paliwa i pokazuje cenę.';

  @override
  String get featureLabel_voiceAnnouncements => 'Ogłoszenia głosowe';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Głośne ogłaszanie pobliskich tanich stacji paliw podczas jazdy, dzięki czemu możesz skupić wzrok na drodze.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Najpierw włącz radar stacji paliw';

  @override
  String get featureGroupTitle_finding => 'Wyszukiwanie i mapa';

  @override
  String get featureGroupDescription_finding =>
      'Gdzie zatankować lub naładować — wyszukiwanie, mapa, nawigacja.';

  @override
  String get featureGroupTitle_prices => 'Ceny i alerty';

  @override
  String get featureGroupDescription_prices =>
      'Spadki cen, historia i raportowanie.';

  @override
  String get featureGroupTitle_radar => 'Radar stacji paliw';

  @override
  String get featureGroupDescription_radar =>
      'Aktywne podpowiedzi cenowe podczas jazdy.';

  @override
  String get featureGroupTitle_sync => 'Synchronizacja i kopia zapasowa';

  @override
  String get featureGroupDescription_sync =>
      'Przechowuj dane na różnych urządzeniach.';

  @override
  String get featureGroupTitle_input => 'Wprowadzanie i skanowanie';

  @override
  String get featureGroupDescription_input =>
      'Pomocniki do rejestrowania tankowań.';

  @override
  String get featureGroupTitle_developer => 'Deweloperskie i eksperymentalne';

  @override
  String get featureGroupDescription_developer =>
      'Narzędzia dla zaawansowanych użytkowników i współtwórców.';

  @override
  String get featureLabel_voiceFeedback => 'Komunikaty głosowe (synteza mowy)';

  @override
  String get featureDescription_voiceFeedback =>
      'Główny przełącznik wszystkich komunikatów głosowych — trenera jazdy i zapowiedzi stacji. Po wyłączeniu aplikacja nigdy nie uruchamia silnika syntezy mowy.';

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
  String get fillUpMultiFuelHint =>
      'Ten pojazd może używać różnych paliw — zapisz to, które faktycznie zatankowano';

  @override
  String get fillUpGuidanceTitle => 'Najlepszy moment na tankowanie';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Obecna cena należy do najtańszych z ostatnich $days dni — dobry moment na tankowanie.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Ceny są bliskie maksimum z ostatnich $days dni. Zwykle są tańsze $window — rozważ poczekanie.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Ceny rosną — rozważ tankowanie wkrótce.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Dzisiejsza cena jest zbliżona do średniej z ostatnich $days dni.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Można zaoszczędzić około $amount/L, wybierając odpowiedni moment na tankowanie.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na podstawie $count odczytów ceny',
      one: 'Na podstawie 1 odczytu ceny',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'w $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'w innych porach';

  @override
  String get fillUpGuidanceWeekday1 => 'poniedziałki';

  @override
  String get fillUpGuidanceWeekday2 => 'wtorki';

  @override
  String get fillUpGuidanceWeekday3 => 'środy';

  @override
  String get fillUpGuidanceWeekday4 => 'czwartki';

  @override
  String get fillUpGuidanceWeekday5 => 'piątki';

  @override
  String get fillUpGuidanceWeekday6 => 'soboty';

  @override
  String get fillUpGuidanceWeekday7 => 'niedziele';

  @override
  String get fillUpGuidancePartEarlyMorning => 'wczesnym rankiem';

  @override
  String get fillUpGuidancePartMorning => 'rano';

  @override
  String get fillUpGuidancePartAfternoon => 'po południu';

  @override
  String get fillUpGuidancePartEvening => 'wieczorem';

  @override
  String get fillUpGuidancePartNight => 'nocą';

  @override
  String get fillUpOdometerFromCarJustNow => 'Z Twojego auta · przed chwilą';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Z Twojego auta · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Oszacowano na podstawie ostatniego odczytu z auta i przejechanego od tego czasu dystansu ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Wklej tekst';

  @override
  String get pasteReceiptDialogTitle => 'Wklej tekst paragonu';

  @override
  String get pasteReceiptDialogHint =>
      'Wklej tekst paragonu za paliwo — e-mail, SMS lub udostępniony PDF. Litry, cena za litr, rodzaj paliwa, suma i stacja są odczytywane na urządzeniu i wstępnie wypełniają formularz. Nic nie jest wysyłane na serwer.';

  @override
  String get pasteReceiptFieldHint => 'Tekst paragonu';

  @override
  String get pasteReceiptParseAction => 'Wypełnij';

  @override
  String get pasteReceiptNoData =>
      'Nie udało się odczytać danych o paliwie z tego tekstu — sprawdź, czy to paragon za paliwo, i spróbuj ponownie.';

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
  String get badScanReportTitleReceipt => 'Zgłoś błąd skanowania — paragon';

  @override
  String get badScanReportHint =>
      'Udostępnimy zdjęcie paragonu i obie zestawy wartości, aby następna wersja mogła nauczyć się tego układu.';

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
  String get fillUpWarningDialogTitle => 'Sprawdź to tankowanie';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Wybrano $chosenFuel, ale ten pojazd jeździ na $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Stan licznika $entered km jest niższy niż $previous km z poprzedniego tankowania — dystans nie może się cofać.';
  }

  @override
  String get fillUpWarningGoBack => 'Wróć i popraw';

  @override
  String get fillUpWarningSaveAnyway => 'Zapisz mimo to';

  @override
  String get fillUpSectionWhatTitle => 'Co zatankowałeś';

  @override
  String get fillUpSectionWhatSubtitle => 'Paliwo, ilość, cena';

  @override
  String get fillUpSectionWhereTitle => 'Gdzie byłeś';

  @override
  String get fillUpSectionWhereSubtitle => 'Stacja, licznik, notatki';

  @override
  String get fillUpImportReceiptLabel => 'Paragon';

  @override
  String get fillUpPricePerLiterLabel => 'Cena za litr';

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
  String get profileSectionDisplayStations => 'Wyświetlanie i stacje';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get fuelEfficiencyCardTitle => 'Koszt kilometra według paliwa';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Która mieszanka paliw jest naprawdę najtańsza w jeździe';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Najtaniej na km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Czyste';

  @override
  String get fuelEfficiencyMixBadge => 'Mieszanka';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Głównie $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Koszt/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Wydano łącznie';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tankowania',
      many: '$count tankowań',
      few: '$count tankowania',
      one: '1 tankowanie',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pełnego baku',
      many: '$count pełnych baków',
      few: '$count pełne baki',
      one: '1 pełny bak',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Zapisz co najmniej dwa pełne baki na każdy skład, aby wyłonić najtańszy.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Baki są grupowane według składu: bak jest czysty, gdy jedno paliwo stanowi co najmniej 85 %; w przeciwnym razie to mieszanka.';

  @override
  String get fuelNameE5 => 'Benzyna 95';

  @override
  String get fuelNameE10 => 'Benzyna 95 E10';

  @override
  String get fuelNameE98 => 'Benzyna 98';

  @override
  String get fuelNameDiesel => 'Diesel';

  @override
  String get fuelNameDieselPremium => 'Diesel Premium';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'LPG';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Wodór';

  @override
  String get fuelNameElectric => 'Elektryczny';

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
  String gdprPolicyLink(int version) {
    return 'Polityka prywatności (wersja $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Zgoda udzielona $date · wersja polityki $version';
  }

  @override
  String get consentNotRecorded => 'Nie zarejestrowano jeszcze zgody';

  @override
  String serverErasurePartial(String tables) {
    return 'Nie udało się usunąć części danych z serwera: $tables. Spróbuj ponownie lub skontaktuj się z deweloperem, podając tę listę.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Nie udało się usunąć części danych lokalnych: $steps. Uruchom aplikację ponownie i spróbuj jeszcze raz.';
  }

  @override
  String get myCommunityReportsTitle => 'Moje zgłoszenia społeczności';

  @override
  String get myCommunityReportsEmpty => 'Nie wysłano jeszcze żadnych zgłoszeń';

  @override
  String get deleteReportTooltip => 'Usuń to zgłoszenie';

  @override
  String get reportDeleted => 'Zgłoszenie usunięte';

  @override
  String get reportDeleteFailed => 'Nie udało się usunąć zgłoszenia';

  @override
  String get tileProxyToggleTitle => 'Ładuj kafelki mapy przez proxy Sparkilo';

  @override
  String get tileProxyToggleSubtitle =>
      'Wł.: widoczny obszar mapy i Twój adres IP trafiają na serwer dewelopera w UE, który pobiera kafelki z OpenStreetMap. Wył.: kafelki są ładowane bezpośrednio z tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle => 'Ładuj logo marek z internetu';

  @override
  String get remoteLogosToggleSubtitle =>
      'Domyślnie wył.: wyświetlane są wbudowane symbole zastępcze. Wł.: logo są pobierane z logo.clearbit.com, które widzi Twój adres IP.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return 'Zapisano $fileName w folderze Pobrane — $count plików w środku';
  }

  @override
  String get privacyExportAllFailed => 'Nie udało się zapisać pliku eksportu';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Obsługiwane przez $operator · Supabase, UE (Frankfurt) · synchronizuje ulubione, alerty, pojazdy wraz z VIN, tankowania, oceny, zgłoszenia oraz — jeśli to włączysz — trasy z GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'To Ty jesteś administratorem danych — Twój własny projekt Supabase, my nigdy go nie widzimy';

  @override
  String get syncModeJoinControllerNotice =>
      'Właściciel współdzielonej bazy danych jest administratorem Twoich danych';

  @override
  String get ugcPublicNoticeTitle => 'Udostępnione innym użytkownikom';

  @override
  String get ugcPublicNoticeBody =>
      'Jest to przechowywane w bazie synchronizacji pod Twoim pseudonimowym identyfikatorem użytkownika. W Społeczności Sparkilo może to odczytać każdy zalogowany użytkownik. Możesz to usunąć w dowolnym momencie w TankSync → Przejrzystość danych.';

  @override
  String get blockedAuthorsTitle => 'Zablokowani użytkownicy';

  @override
  String get blockedAuthorsDescription =>
      'Treści udostępnione przez tych użytkowników są ukryte na tym urządzeniu. Odblokuj, aby znów je zobaczyć.';

  @override
  String get blockedAuthorsEmpty => 'Brak zablokowanych użytkowników';

  @override
  String get blockedAuthorsUnblock => 'Odblokuj';

  @override
  String get coachingGpsLiftOff => 'Puść gaz';

  @override
  String get coachingGpsAnticipateBrake => 'Przewiduj';

  @override
  String get coachingGpsSmoothAccel => 'Płynne przyspieszanie';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'Ślad pokrywa $pct % — najdłuższa luka $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'Ślad pokrywa $pct % — nie wykryto luk';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'aplikacja w tle';

  @override
  String get gpsCoverageAttrOsBatching => 'system grupował pozycje';

  @override
  String get gpsCoverageAttrGateRejected => 'pozycje odfiltrowane';

  @override
  String get gpsCoverageAttrDeliveryStall => 'opóźnione dostarczenie';

  @override
  String get gpsCoverageAttrSignalLoss => 'utrata sygnału';

  @override
  String get gpsCoverageAttrUnknown => 'nieznana przyczyna';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'Aplikacja była w tle bez usługi pierwszoplanowej, więc system ograniczył GPS. Trzymaj ekran włączony podczas nagrywania lub włącz nagrywanie w tle, gdy będzie dostępne.';

  @override
  String get gpsCoverageHintOsBatching =>
      'System dostarczył pozycje z opóźnieniem, w paczkach; ślad został potem uzupełniony, więc faktycznie utracono niewiele danych.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Zaszumione pozycje na tym odcinku zostały odfiltrowane, aby dystans pozostał wiarygodny.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Pozycje zostały wyznaczone na czas, ale dotarły do aplikacji z opóźnieniem — telefon był zajęty (często ponowne łączenie Bluetooth). Odbiór był dobry.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Utracono odbiór GPS — zwykle tunel, parking podziemny lub gęsta zabudowa miejska.';

  @override
  String get gpsCoverageHintUnknown =>
      'Ta podróż nie zawiera informacji o stanie aplikacji podczas luki, więc nie można ustalić przyczyny.';

  @override
  String get gpsCoverageAttrLinkRecovery =>
      'zakłócenie przez ponowne łączenie OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'Luka pokrywa się z ponownym łączeniem OBD2 — połączenie z adapterem wracało do normy, gdy odbiór GPS się zatrzymał. Naprawa połączenia z adapterem naprawia też ślad.';

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
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Największa przerwa: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Wznowiono';

  @override
  String get gpsLifecyclePaused => 'Wstrzymano';

  @override
  String get gpsLifecycleInactive => 'Nieaktywne';

  @override
  String get gpsKpiVerdictGood => 'Efektywna';

  @override
  String get gpsKpiVerdictModerate => 'Umiarkowana';

  @override
  String get gpsKpiVerdictAggressive => 'Agresywna';

  @override
  String get gpsKpiInterpretationGood =>
      'Płynna, oszczędna jazda — tak wygląda efektywność.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Dość typowa jazda — nieco łagodniejsze operowanie gazem dałoby większe oszczędności.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energochłonna jazda — odpuszczenie gazu i częstsze toczenie się obniżyłyby zużycie paliwa.';

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
      'Szacowanie GPS (~) — brak czujnika paliwa na tej trasie. Wartość jest modelowana na podstawie prędkości i kalibracji pojazdu; dokładność poprawia się wraz z dojrzewaniem modelu.';

  @override
  String get gpsRoadUseCardTitle => 'Jak korzystałeś z drogi';

  @override
  String get gpsRoadUseSpeedSection => 'Gdzie spędzono czas';

  @override
  String get gpsRoadUseSpeedIdle => 'Postój (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Miasto (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Trasa (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Szybko (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Jak się poruszałeś';

  @override
  String get gpsRoadUsePhaseAccel => 'Przyspieszanie';

  @override
  String get gpsRoadUsePhaseSteady => 'Stała prędkość';

  @override
  String get gpsRoadUsePhaseCoast => 'Toczenie się';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Dużo toczenia się — pozwalanie autu jechać zamiast hamowania oszczędza paliwo. Brawo.';

  @override
  String get gpsRoadUseSource => 'Z Twojego śladu GPS';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco-coaching w czasie rzeczywistym';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Delikatne wibracje + wskazówka na ekranie gdy wciśniesz gaz podczas jazdy';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Łagodniej z gazem — wybieg oszczędza więcej';

  @override
  String highwayViaExit(String ref, String km) {
    return 'przez zjazd $ref · +$km km';
  }

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
  String get consentSyncTripsAnonymousHint =>
      'Podróże są zapisywane na anonimowym koncie tego urządzenia. Zaloguj się adresem e-mail, aby mieć do nich dostęp z innych urządzeń.';

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
  String get accelBrakeCardTitle => 'Przyspieszanie i hamowanie';

  @override
  String get accelBrakeHardAccel => 'Gwałtowne przyspieszenia';

  @override
  String get accelBrakeHardBrake => 'Gwałtowne hamowanie';

  @override
  String get accelBrakeSharpCorner => 'Ostre zakręty';

  @override
  String get accelBrakeSource => 'Z czujników ruchu telefonu';

  @override
  String lessonHardBrake(String count) {
    return '$count przypadków gwałtownego hamowania';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Przewiduj zatrzymania i wcześniej zdejmij nogę z gazu — gwałtowne hamowanie marnuje paliwo zużyte na rozpędzenie się.';

  @override
  String lessonSharpCornering(String count) {
    return '$count ostrych zakrętów';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Zwalniaj przed zakrętem, a nie w nim — gwałtowne pokonywanie zakrętów traci prędkość, którą trzeba odbudować.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Ostatnie $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Jednostka zużycia paliwa';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Jak zużycie paliwa jest pokazywane w całej aplikacji';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automatycznie ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Okno zużycia na żywo';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Uśrednia wartość na żywo z ostatnich sekund — dłuższe jest stabilniejsze, krótsze reaguje szybciej';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'szac. $unit';
  }

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
  String get consumptionMonthlyClimbLabel => 'Wspięte';

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
  String get obd2DiagnosticsTitle => 'Stan komunikacji OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops spadków',
      one: '1 spadek',
      zero: 'brak spadków',
    );
    return '$percent% kompletne · $duty% duty · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adapter';

  @override
  String get obd2DiagnosticsConnectionSection => 'Cykl życia połączenia';

  @override
  String get obd2DiagnosticsPidSection => 'Wyniki dla poszczególnych PID';

  @override
  String get obd2DiagnosticsReconnectSection => 'Telemetria ponownego łączenia';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts prób ponownego łączenia · $successes udanych · $transitions przejść · $disconnects rozłączeń sklasyfikowanych';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'W tej sesji uruchomiono tryb awaryjny tylko z GPS.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Stan harmonogramu';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Kompletność';

  @override
  String get obd2DiagnosticsSupportSection => 'Wykryte obsługiwane PID';

  @override
  String get obd2DiagnosticsFuelSection => 'Zestawienie poziomu paliwa';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protokół $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts prób · $successes ok · $drops spadków · czas połączenia p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Ponowne połączenia: $silent ciche · $visible widoczne';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz takt · $skips pominięć back-pressure · $demotions degradacji';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Poziom dynamiki niedożywiony — RPM / prędkość spadły poniżej progu regulatora.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Ogółem $percent% · aktywny duty $duty%';
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
    return '$supported obsługiwanych · $unsupported nieobsługiwanych · $unknown nieznanych';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Podejrzane $suspicious z $total próbek';
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
    return '$pid: $polled odpytanych · $ok ok · $noData ND · $timeout TO · $error błędów · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection =>
      'Transkrypt inicjalizacji urządzenia';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protokół $protocol · $start · firmware $firmware · $tier · $pids PID';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'ciepły';

  @override
  String get obd2DiagnosticsInitCold => 'zimny';

  @override
  String get obd2DiagnosticsEmpty =>
      'Nie zarejestrowano jeszcze żadnej sesji OBD2 — podłącz adapter i nagraj trasę z włączonym trybem deweloperskim.';

  @override
  String get obd2DiagnosticsExplain =>
      'Rejestrowane podczas nagrywania w celu debugowania komunikacji klucz↔aplikacja — zbierane wyłącznie w trybie deweloperskim.';

  @override
  String get obd2HealthScreenTitle => 'Stan komunikacji OBD2';

  @override
  String get obd2HealthNavLabel => 'Stan komunikacji OBD2';

  @override
  String get obd2HealthLiveSection => 'Sesja na żywo';

  @override
  String get obd2HealthHistorySection => 'Ostatnie sesje';

  @override
  String get obd2HealthDownloadJson => 'Pobierz jako JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Pobierz tylko zapis inicjalizacji';

  @override
  String get obd2HealthDownloadError =>
      'Nie udało się zapisać pliku diagnostycznego';

  @override
  String get obd2TestAdapterLabel => 'Adapter do testu';

  @override
  String get obd2TestAdapterScanOption => 'Wyszukaj adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Łączenie z $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Uruchom test adaptera';

  @override
  String get obd2TestRunButton => 'Uruchom test adaptera';

  @override
  String get obd2TestRunPassed => 'Test adaptera zakończony pomyślnie';

  @override
  String get obd2TestRunFailed => 'Test adaptera zakończony niepowodzeniem';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — silnik wyłączony; uruchom silnik, aby odczytać dane na żywo';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed z $total kroków OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Zatrzymaj aktywne nagrywanie przed uruchomieniem testu adaptera.';

  @override
  String get obd2TestStepScan => 'Skanuj w poszukiwaniu adaptera';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth telefonu';

  @override
  String get obd2TestStepConnect => 'Połącz i zainicjuj';

  @override
  String get obd2TestStepInfo => 'Informacje o adapterze';

  @override
  String get obd2TestStepSupportedPids => 'Obsługiwane PID';

  @override
  String get obd2TestStepProtocol => 'Protokół pojazdu';

  @override
  String get obd2TestStepSampleReads => 'Przykładowe odczyty';

  @override
  String get obd2TestStepSoak => 'Ciągłe odpytywanie';

  @override
  String get obd2TestStepReconnect => 'Test ponownego połączenia';

  @override
  String get obd2TestStepDisconnect => 'Rozłącz';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Przekroczono czas';

  @override
  String get obd2TestStatusGarbage => 'Nieczytelna odpowiedź';

  @override
  String get obd2TestStatusNoResponse => 'Brak odpowiedzi';

  @override
  String get obd2TestStatusFail => 'Niepowodzenie';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'nieznany — domyślnie BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Ostatnie próby połączenia';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Nie zarejestrowano jeszcze prób połączenia.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Pobierz dziennik połączenia';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Pobierz wszystkie dzienniki połączeń';

  @override
  String get obd2HealthConnectOrigin => 'Źródło';

  @override
  String get obd2HealthConnectTransport => 'Transport';

  @override
  String get obd2HealthConnectOutcome => 'Wynik';

  @override
  String get obd2HealthConnectScanList => 'Wykryte urządzenia';

  @override
  String get obd2HealthConnectSteps => 'Kroki';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Nieznany adapter';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Sesja zarejestrowana · $samples próbek silnika · $percent% pokrycia';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'Co zarejestrowała ta trasa';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples z $total próbek zawierało dane silnika ($percent%)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adapter: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Uzgodnienie protokołu: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Sesja zakończona: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Długość sesji: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Dane o zużyciu pochodzą z adaptera, a nie z szacunków GPS.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'Szczegóły komunikacji dla poszczególnych PID nie zostały zarejestrowane dla tej trasy. Włącz tryb dewelopera przed nagrywaniem, aby je zebrać.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Nie można było dotrzeć do \'$adapterName\' — wybierz inny adapter';
  }

  @override
  String get obd2PickerOtherDevices => 'Inne urządzenia Bluetooth';

  @override
  String get obd2PickerTapToTry => 'Nierozpoznany — dotknij, aby spróbować';

  @override
  String get obd2PickerBleOnlyNotice =>
      'iPhone działa tylko z adapterami Bluetooth LE. Adapter obsługujący wyłącznie Classic (np. vLinker BM, Konnwei KW902) trzeba używać na Androidzie.';

  @override
  String get obd2PairingConfirmHint =>
      'Potwierdź prośbę o parowanie na telefonie';

  @override
  String get obd2ScanEmptyTitle => 'Nie znaleziono adaptera';

  @override
  String get obd2ScanEmptyReady =>
      'Bluetooth jest włączony, a uprawnienia przyznane. Upewnij się, że adapter jest podłączony do gniazda OBD2, a zapłon włączony, i wyszukaj ponownie.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'To urządzenie nie ma modułu Bluetooth Low Energy, więc nie może połączyć się z adapterem OBD2.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'Bluetooth jest wyłączony. Włącz go, aby wyszukać adapter.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo potrzebuje uprawnienia Bluetooth, aby znaleźć adapter.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'Uprawnienie Bluetooth zostało trwale odrzucone. Przyznaj je w ustawieniach systemu, aby wyszukać adapter.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Usługi lokalizacji są wyłączone na tym urządzeniu. Android wymaga ich włączenia do wyszukiwania adapterów Bluetooth — żadna lokalizacja nie jest zapisywana ani udostępniana.';

  @override
  String get obd2ScanOpenSettings => 'Otwórz ustawienia';

  @override
  String get obd2WaitingForEngineBanner =>
      'Oczekiwanie na silnik — nagrywanie z GPS';

  @override
  String get obd2StartEngineToReconnect =>
      'Uruchom silnik, aby połączyć ponownie';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Silnik wyłączony — uruchom go, aby połączyć ponownie';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Silnik wyłączony od $minutes min — zakończyć nagrywanie?';
  }

  @override
  String get obd2ParkedPromptStop => 'Zakończ';

  @override
  String get obd2ParkedPromptKeep => 'Kontynuuj';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Silnik wyłączony przez pierwsze $head i ostatnie $tail tej podróży — pokrycie jest mierzone przy pracującym silniku.';
  }

  @override
  String get obd2ReconnectInProgress => 'Ponowne łączenie z adapterem OBD2…';

  @override
  String get obd2StatusEngineOff => 'OBD2 wstrzymane — silnik wyłączony';

  @override
  String get obd2StatusEngineOffBody =>
      'Adapter był osiągalny, ale magistrala pojazdu milczała, więc automatyczne ponowne łączenie zostało wstrzymane. Wznowi się, gdy ruszysz lub ponownie otworzysz aplikację — albo połącz ponownie teraz.';

  @override
  String get obd2StatusReconnectNow => 'Połącz ponownie teraz';

  @override
  String get autoRecordNotificationTitle => 'Automatyczne nagrywanie podróży';

  @override
  String get autoRecordNotificationText => 'Oczekiwanie na adapter OBD2';

  @override
  String get obd2ResetConnection => 'Zresetuj połączenie';

  @override
  String get obd2ResetConnectionDone =>
      'Adapter zresetowany — połączenie przywrócone';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adapter zresetowany — ponowne łączenie w tle';

  @override
  String get ocrTesterTitle => 'Tester OCR';

  @override
  String get ocrTesterNavLabel => 'Tester OCR';

  @override
  String get ocrTesterExplain =>
      'Uruchom potok OCR dystrybutora / paragonu na wybranym zdjęciu i sprawdź każdy krok — dostępne tylko w trybie deweloperskim.';

  @override
  String get ocrTesterCapture => 'Zrób zdjęcie';

  @override
  String get ocrTesterPickImage => 'Wybierz obraz';

  @override
  String get ocrTesterRun => 'Uruchom';

  @override
  String get ocrTesterCountry => 'Kraj';

  @override
  String get ocrTesterCountryNone => 'Domyślny (brak profilu)';

  @override
  String get ocrTesterNoImage =>
      'Wybierz lub zrób zdjęcie, a następnie kliknij Uruchom.';

  @override
  String get ocrTesterRunning => 'Trwa OCR…';

  @override
  String get ocrTesterOverlaySection => 'Nakładka bloków';

  @override
  String get ocrTesterStepsSection => 'Kroki potoku';

  @override
  String get ocrTesterLegendLabel => 'Etykieta';

  @override
  String get ocrTesterLegendNumeric => 'Numeryczne';

  @override
  String get ocrTesterLegendNoise => 'Szum';

  @override
  String get ocrTesterLegendDerived => 'Pochodne';

  @override
  String get ocrTesterStageGlare => 'Zdjęcie / odblask';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Klasyfikacja';

  @override
  String get ocrTesterStageAssemble => 'Składanie';

  @override
  String get ocrTesterStageAnchor => 'Zakotwiczenie';

  @override
  String get ocrTesterStageFallback => 'Awaryjne';

  @override
  String get ocrTesterStageCrossCheck => 'Weryfikacja krzyżowa';

  @override
  String get ocrTesterStageConfidence => 'Ufność';

  @override
  String get ocrTesterStageGate => 'Bramka';

  @override
  String get ocrTesterStageBrand => 'Marka';

  @override
  String get ocrTesterStageOverrides => 'Nadpisania';

  @override
  String get ocrTesterStageReconcile => 'Uzgodnienie';

  @override
  String get ocrTesterStageResult => 'Wynik';

  @override
  String get ocrTesterChipRead => 'ODCZYT';

  @override
  String get ocrTesterChipDerived => 'POCHODNE';

  @override
  String get ocrTesterGateAccepted => 'Zaakceptowano';

  @override
  String get ocrTesterGateRejected => 'Odrzucono';

  @override
  String get ocrTesterFallbackBanner =>
      'Pole zostało odzyskane przez awaryjne dopasowanie skali — sprawdź je.';

  @override
  String get ocrTesterStageNoData => 'Etap nie został uruchomiony.';

  @override
  String get ocrTesterCopyJson => 'Kopiuj jako JSON';

  @override
  String get ocrTesterExportPackage => 'Eksportuj pakiet';

  @override
  String get ocrTesterCopied => 'Ślad OCR skopiowany do schowka.';

  @override
  String get ocrTesterExported => 'Pakiet OCR zapisany w folderze Pobrane.';

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
  String get onboardingObd2ConnectFailed =>
      'Nie można połączyć się z adapterem. Możesz spróbować ponownie lub pominąć.';

  @override
  String get onboardingPickUseMode =>
      'Wybierz tryb użytkowania, aby kontynuować.';

  @override
  String get onboardingObd2LaterNote =>
      'Adapter Bluetooth OBD2 możesz sparować w dowolnym momencie później z ekranu pojazdu, aby nagrywać podróże i odczytywać dane z silnika.';

  @override
  String get openHoursUnknown => 'Godziny nieznane';

  @override
  String get open24Hours => 'Otwarte całą dobę';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Poniedziałek';

  @override
  String get dayTue => 'Wtorek';

  @override
  String get dayWed => 'Środa';

  @override
  String get dayThu => 'Czwartek';

  @override
  String get dayFri => 'Piątek';

  @override
  String get daySat => 'Sobota';

  @override
  String get daySun => 'Niedziela';

  @override
  String get dayShortMon => 'Pon';

  @override
  String get dayShortTue => 'Wt';

  @override
  String get dayShortWed => 'Śr';

  @override
  String get dayShortThu => 'Czw';

  @override
  String get dayShortFri => 'Pt';

  @override
  String get dayShortSat => 'Sob';

  @override
  String get dayShortSun => 'Nd';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Święta publiczne';

  @override
  String get closedLabel => 'Zamknięte';

  @override
  String get openingHoursNotAvailable => 'Godziny otwarcia niedostępne';

  @override
  String get showAllHours => 'Pokaż wszystkie godziny';

  @override
  String get showLessHours => 'Pokaż mniej';

  @override
  String get openStateUnknown => 'Nieznany';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Stacja jest otwarta',
      'false': 'Stacja jest zamknięta',
      'other': 'Stan otwarcia nieznany',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Dostęp do aparatu';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Ta aplikacja chce użyć Twojego aparatu, aby odczytywać paragony, wyświetlacze dystrybutorów i kody QR.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Co dzieje się z obrazem z aparatu:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'Obraz jest używany wyłącznie do odczytu paragonu, wyświetlacza dystrybutora lub kodu QR — rozpoznawanie odbywa się na Twoim urządzeniu.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'Zdjęcie jest usuwane po zakończeniu skanowania.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Nic nie jest przesyłane, chyba że zgłosisz błędny skan i to potwierdzisz.';

  @override
  String get permissionRationaleBluetoothTitle => 'Dostęp do Bluetooth';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Ta aplikacja chce użyć Bluetooth, aby połączyć się z Twoim adapterem OBD2.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Co dzieje się z Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth jest używany wyłącznie do wyszukiwania Twojego adaptera OBD2 i komunikacji z nim.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'Identyfikator adaptera pozostaje na Twoim urządzeniu — jest synchronizowany wyłącznie przez TankSync jako część profilu pojazdu.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'W systemie Android 11 i starszych system prosi także o lokalizację, ponieważ skanowanie Bluetooth jest tam traktowane jako uprawnienie lokalizacyjne.';

  @override
  String get permissionRationaleNotificationsTitle => 'Powiadomienia';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Ta aplikacja chce wysyłać Ci powiadomienia o alertach cenowych i stanie rejestrowania trasy.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Co dzieje się z powiadomieniami:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Powiadomienia są używane do lokalnych alertów cenowych i stanu rejestrowania trasy.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Są generowane na Twoim urządzeniu — nic nie opuszcza urządzenia.';

  @override
  String get permissionRationaleRevoke =>
      'Możesz to cofnąć w dowolnym momencie w ustawieniach urządzenia.';

  @override
  String get permissionRationaleLegalBasis =>
      'Podstawa prawna: art. 6 ust. 1 lit. a) RODO (zgoda)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'szac. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Wartość szacunkowa (~) — brak czujnika paliwa na tej trasie, więc wskaźnik L/100 km jest modelowany na podstawie prędkości GPS i kalibracji pojazdu. Jest przybliżony (zazwyczaj ±10–30 %, poprawia się wraz z dojrzewaniem kalibracji) i nie stanowi rzeczywistego odczytu.';

  @override
  String get tripRecordingPipElapsedCaption => 'upłynęło';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: szacunki zużycia ponownie dopasowane do dystrybutora ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Otworzyć zeskanowany link?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Ten kod QR prowadzi do $host. Otwieraj tylko zaufane linki.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Otwórz link';

  @override
  String get qrLaunchConfirmCancel => 'Anuluj';

  @override
  String get radarPinHelpTitle => 'O przypinaniu';

  @override
  String get radarPinHelpBody =>
      'Przypięcie utrzymuje ekran włączony i ukrywa paski systemowe, dzięki czemu odczyt najbliższej stacji pozostaje czytelny na uchwycie do deski rozdzielczej. Dotknij ponownie, aby odpiąć. Automatycznie odpina się po zatrzymaniu radaru.';

  @override
  String get radarAutoPinTitle => 'Zawsze przypinaj przy uruchomieniu radaru';

  @override
  String get radarAutoPinSubtitle =>
      'Przypinaj radar automatycznie za każdym razem zamiast klikać za każdym razem. Zużywa więcej baterii.';

  @override
  String get radarScopeShowScope => 'Widok radaru';

  @override
  String get radarScopeShowList => 'Widok listy';

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
  String get reconcileWorkflowTitle => 'Uzgodnij zużycie paliwa';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Wykryto rozbieżność $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Zatankowałeś $pumped L, ale Twoje zarejestrowane trasy uwzględniają jedynie $consumed L. Brakuje wyjaśnienia dla $gap L.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Zazwyczaj oznacza to, że jakiś przejazd nie został zarejestrowany (adapter był odłączony lub aplikacja zamknięta), bądź brakuje lub jest niepoprawnie wpisane tankowanie.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Dopóki to nie zostanie rozwiązane, łączne zużycie paliwa i suma tras nie będą się zgadzać.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Pomóż nam przypisać rozbieżność';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Czy wszystkie tankowania dla tego zbiornika są kompletne i poprawne?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Czy wszystkie przejazdy są zarejestrowane?';

  @override
  String get reconcileWorkflowAnswerYes => 'Tak';

  @override
  String get reconcileWorkflowAnswerNo => 'Nie';

  @override
  String get reconcileWorkflowPathAHint =>
      'Brakuje lub jest błędne tankowanie — dodamy korektę, aby tankowania się sumowały poprawnie.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Tankowania są prawidłowe, a jakiś przejazd nie został zarejestrowany — dodamy wirtualną trasę dla brakującego dystansu.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Litry korekty';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Jak daleko był niezarejestrowany przejazd? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Zdecyduj później';

  @override
  String get reconcileWorkflowBack => 'Wstecz';

  @override
  String get reconcileWorkflowNext => 'Dalej';

  @override
  String get reconcileWorkflowApply => 'Zastosuj';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Wirtualna trasa — dotknij, aby edytować';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Edytuj wirtualną trasę';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Ta trasa została dodana, aby uwzględnić paliwo zużyte podczas jazdy bez rejestrowania. Dostosuj dystans lub paliwo albo usuń ją.';

  @override
  String get reconcileVirtualTrajetDelete => 'Usuń wirtualną trasę';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Nierozwiązana rozbieżność paliwa/tras: $gap L — dotknij, aby rozwiązać';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Rozwiąż nierozwiązaną rozbieżność paliwa i tras';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesja';

  @override
  String get settingsSearchHint => 'Szukaj w ustawieniach';

  @override
  String settingsSearchNoResults(String query) {
    return 'Brak ustawień pasujących do „$query”';
  }

  @override
  String get settingsTopicProfilesTitle => 'Profile i region';

  @override
  String get settingsTopicProfilesSubtitle =>
      'Kraj, język, paliwo, promień wyszukiwania, planowanie trasy';

  @override
  String get settingsTopicProfilesKeywords =>
      'profil, kraj, język, paliwo, promień, kod pocztowy, trasa, dom, ocena, ekran startowy, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Pojazdy i OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Twoje samochody, pojemność baku, parowanie adaptera OBD2';

  @override
  String get settingsTopicVehiclesKeywords =>
      'pojazd, samochód, auto, obd, obd2, adapter, bluetooth, bak, silnik, vin, kalibracja, vehicle, car, tank, engine, calibration';

  @override
  String get settingsTopicDrivingTitle => 'Jazda i zużycie paliwa';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, nagrody, radar stacji, rozwiązywanie problemów';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, eko, haptyczny, głos, grywalizacja, radar, wybieg, podróż, zużycie, klub paliwowy, lojalność, log obd2, przypnij, eco, haptic, voice, gamification, glide, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Ceny i alerty';

  @override
  String get settingsTopicPricesSubtitle =>
      'Alerty cenowe, komunikaty głosowe, historia cen, zgłoszenia społeczności';

  @override
  String get settingsTopicPricesKeywords =>
      'alert, powiadomienie, cena, historia, prognoza, najlepszy moment, społeczność, zgłoszenie, qr, płatność, głos, komunikat, notification, price, history, prediction, community, report, payment, voice, announcement';

  @override
  String get settingsTopicUnitsTitle => 'Jednostki i wygląd';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Motyw, jednostka odległości, widżet ekranu głównego';

  @override
  String get settingsTopicUnitsKeywords =>
      'motyw, ciemny, jasny, eko, jednostka, km, mile, widżet, kolor, wygląd, theme, dark, light, eco, unit, miles, widget, colour, display, appearance';

  @override
  String get settingsTopicFeaturesTitle => 'Funkcje i tryb użycia';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Zestawy trybu użycia i każdy przełącznik funkcji';

  @override
  String get settingsTopicFeaturesKeywords =>
      'funkcja, tryb, podstawowy, średni, pełny, własny, przełącznik, typy stacji, stacje paliw, ładowarki, ładowanie, feature, mode, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Źródła danych i lokalizacja';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'Klucze API, pozycja GPS, automatyczne przełączanie profilu';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, klucz, gps, lokalizacja, pozycja, źródło danych, tankerkoenig, opencharge, key, location, data source';

  @override
  String get settingsTopicSyncTitle => 'Synchronizacja i konto';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, chmura, konto, e-mail, połącz urządzenie, synchronizacja, udostępnij bazę, anonimowy, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'prywatność, zgoda, rodo, usuń, wymaż, pamięć, cache, dane, raportowanie błędów, vin, privacy, consent, gdpr, delete, erase, storage, data, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Kopia zapasowa i przywracanie';

  @override
  String get settingsTopicBackupSubtitle =>
      'Eksportuj lub przywróć pełną kopię zapasową swoich danych';

  @override
  String get settingsTopicBackupKeywords =>
      'kopia zapasowa, eksport, przywróć, import, zip, xml, przeniesienie, backup, export, restore, transfer';

  @override
  String get settingsTopicAdvancedSubtitle =>
      'Token GitHub, narzędzia deweloperskie';

  @override
  String get settingsTopicAdvancedKeywords =>
      'deweloper, debugowanie, token, pat, github, diagnostyka, dziennik błędów, ślad, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Wersja, licencje, linki';

  @override
  String get settingsTopicAboutKeywords =>
      'o aplikacji, wersja, licencja, wesprzyj, github, autorstwo, about, version, license, donate, attribution';

  @override
  String get settingsConsumptionOffHint =>
      'Włącz śledzenie zużycia paliwa w sekcji Funkcje i tryb użycia, aby skonfigurować pojazdy, coaching i nagrody.';

  @override
  String get settingsOpenFeaturesLink => 'Otwórz Funkcje i tryb użycia';

  @override
  String get settingsRadarTileSubtitle =>
      'Promień, tryb cen, odpytywanie i przypinanie ekranu dla aktywnego profilu';

  @override
  String get settingsRadarNoProfileHint =>
      'Najpierw utwórz profil — ustawienia radaru są zapisywane dla każdego profilu.';

  @override
  String get settingsRadarPinHeader => 'Przypinanie ekranu';

  @override
  String get settingsAlertsTileSubtitle =>
      'Alerty dla stacji i promienia powiadamiające o spadkach cen';

  @override
  String get settingsPriceFeaturesHeader => 'Funkcje cenowe';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Komunikaty głosowe są wyłączone. Włącz Informacje głosowe i Komunikaty głosowe w sekcji Funkcje i tryb użycia, aby słyszeć o tanim paliwie w pobliżu podczas jazdy.';

  @override
  String get settingsDistanceUnitTitle => 'Jednostka odległości';

  @override
  String get settingsDistanceUnitSubtitle => 'Z kraju aktywnego profilu';

  @override
  String get settingsObd2AdapterTitle => 'Adapter OBD2';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Adaptery są parowane dla każdego pojazdu — otwórz pojazd, aby sparować lub zmienić jego adapter';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Zgody';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Zgody na Cloud Sync i synchronizację podróży znajdziesz w sekcji Prywatność i dane';

  @override
  String get settingsBackupExportSubtitle =>
      'Pojazdy, tankowania, podróże i dzienniki ładowania jako plik ZIP';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Scal lub zastąp swoje dane z wcześniejszej kopii zapasowej ZIP';

  @override
  String get settingsStationTypesLink =>
      'Typy stacji ustawia się w sekcji Funkcje i tryb użycia';

  @override
  String get routeSearchCriterionLabel => 'Wybór stacji na odcinek trasy';

  @override
  String get routeSearchCriterionCheapest => 'Najtańsza';

  @override
  String get routeSearchCriterionNearest => 'Najbliżej trasy';

  @override
  String get routeSearchTopNLabel => 'Kandydatów na punkt próbkowania';

  @override
  String routeSearchTopNCaption(int count) {
    return 'W każdym punkcie wzdłuż trasy uwzględnianych jest do $count stacji.';
  }

  @override
  String get hybridFuelChoiceLabel => 'Paliwo do wyszukiwania cen (hybryda)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Domyślne pojazdu';

  @override
  String get scopeThisProfile => 'Ten profil';

  @override
  String get scopeAllProfiles => 'Wszystkie profile';

  @override
  String get scopeThisVehicle => 'Ten pojazd';

  @override
  String get featureLabel_manualConsumption => 'Ręczne rejestrowanie zużycia';

  @override
  String get featureDescription_manualConsumption =>
      'Rejestruj tankowania i sesje ładowania ręcznie (adapter OBD2 nie jest wymagany).';

  @override
  String get featureLabel_loyaltyCards => 'Karty lojalnościowe';

  @override
  String get featureDescription_loyaltyCards =>
      'Karty klubów paliwowych / lojalnościowe z rabatem za litr w porównaniach cen.';

  @override
  String get featureLabel_startupTrace =>
      'Ślad inicjalizacji przy uruchomieniu';

  @override
  String get featureDescription_startupTrace =>
      'Rejestruje mierzone czasowo fazy uruchamiania aplikacji, pokazuje je jako wykres kaskadowy i eksportuje — diagnostyka dla deweloperów.';

  @override
  String get locationGpsAutoHint =>
      'Pozycja GPS jest pobierana automatycznie podczas wyszukiwania. Możesz też zaktualizować ją tutaj ręcznie.';

  @override
  String get locationClearGpsBody =>
      'Wyczyścić zapisaną pozycję GPS? Możesz ją zaktualizować ponownie w dowolnym momencie.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Ten typ pliku nie może być jeszcze zaimportowany — zamiast tego udostępnij zdjęcie paragonu.';

  @override
  String get shareReceiptFailed =>
      'Nie udało się odczytać udostępnionego paragonu — spróbuj udostępnić go ponownie lub dodaj tankowanie ręcznie.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Udostępnij paragon do importu';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Udostępnij zdjęcie paragonu z innej aplikacji, aby wstępnie wypełnić tankowanie — data, litry, suma i stacja odczytywane na urządzeniu.';

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
  String syncAdoptTitle(String email) {
    return 'Dołącz do konta $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Zaloguj się hasłem do tego konta, aby współdzielić jego dane na obu urządzeniach.';

  @override
  String get syncAdoptPasswordLabel => 'Hasło do konta';

  @override
  String get syncAdoptJoinButton => 'Dołącz do konta';

  @override
  String get syncAdoptUseDifferentAccount => 'Użyj innego konta';

  @override
  String get syncDeleteDataTitle => 'Usuń zsynchronizowane dane';

  @override
  String get syncDeleteDataSubtitle =>
      'Usuń podróże, pojazdy lub tankowania z bazy synchronizacji';

  @override
  String get syncDeleteDataPickTitle => 'Które zsynchronizowane dane usunąć?';

  @override
  String get syncDeleteDataCategoryTrips => 'Podróże';

  @override
  String get syncDeleteDataCategoryVehicles => 'Pojazdy';

  @override
  String get syncDeleteDataCategoryFillUps => 'Tankowania';

  @override
  String get syncDeleteDataCategoryEverything => 'Wszystko';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Usunąć $category z bazy synchronizacji?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Usuwa wybrane dane z bazy synchronizacji; nie zostaną one ponownie zsynchronizowane z innych urządzeń. Dane zapisane lokalnie na tym urządzeniu pozostają.';

  @override
  String get syncDeleteDataConfirmAction => 'Usuń z serwera';

  @override
  String get syncDeleteDataDone => 'Zsynchronizowane dane usunięte';

  @override
  String get syncDeleteDataFailed =>
      'Usuwanie zsynchronizowanych danych nie powiodło się — spróbuj ponownie';

  @override
  String get syncRelinkTitle =>
      'Synchronizacja w chmurze wymaga ponownego powiązania';

  @override
  String get syncRelinkBody =>
      'Zapisana tożsamość synchronizacji tego urządzenia została wylogowana. Zaloguj się adresem e-mail, aby ponownie powiązać zsynchronizowane dane, lub zacznij od nowa z nową tożsamością.';

  @override
  String get syncRelinkSignInAction => 'Zaloguj się, aby powiązać ponownie';

  @override
  String get syncRelinkStartFreshAction => 'Zacznij od nowa';

  @override
  String get syncRelinkStartFreshTitle => 'Zacząć od nowa?';

  @override
  String get syncRelinkStartFreshBody =>
      'Dla tego urządzenia zostanie utworzona nowa anonimowa tożsamość. Dane zsynchronizowane pod starą tożsamością pozostaną na serwerze, ale nie będą już dostępne stąd, chyba że zalogujesz się jej kontem e-mail.';

  @override
  String get syncRelinkStartFreshConfirm => 'Zacznij od nowa';

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
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km przy spalaniu z ostatniego baku';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Średnia długoterminowa: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Ostatnie tankowanie: $date · $count trasa(y) od tamtej pory';
  }

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
  String tankLevelSourceFillUp(String date) {
    return 'Zakotwiczone na ostatnim tankowaniu: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'Czujnik baku OBD2 · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Mieszanka w baku: $mix';
  }

  @override
  String get tankReportTitle => 'Raport z baku';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Od poprzedniego pełnego baku: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return 'O $delta L/100 km więcej niż poprzedni bak';
  }

  @override
  String tankReportTrendDown(String delta) {
    return 'O $delta L/100 km mniej niż poprzedni bak';
  }

  @override
  String get tankReportTrendFlat => 'Na poziomie poprzedniego baku';

  @override
  String get tankReportNoPrevious =>
      'Zmiana pojawi się po następnym pełnym baku.';

  @override
  String get tankReportExplainHeader => 'Co sugerują nagrania';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Udział wysokich obrotów $cur % (było $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Gwałtowne manewry $cur/100 km (było $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Zimne rozruchy $cur (było $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Udział biegu jałowego $cur % (było $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Nagrania są spontaniczne i obejmują tylko część tego baku — te wskazówki są orientacyjne, nie pełnym obrazem.';

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
  String get tripSaveProgressFinalizingSummary => 'Finalizowanie podsumowania…';

  @override
  String get tripSaveProgressSavingToHistory => 'Zapisywanie w historii…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Synchronizacja w tle…';

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
  String get trajetDetailChartThrottle => 'Przepustnica / pedał (%)';

  @override
  String get trajetDetailChartCoolant => 'Czynnik chłodzący (°C)';

  @override
  String get trajetDetailChartAltitudeRelative => 'Wysokość (m, od startu)';

  @override
  String get trajetDetailChartLambda => 'Zadana wartość λ';

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
  String get trajetDetailChartEstimatedBadge => 'szacowane';

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
  String get trajetDetailDownloadCsvOption => 'Pobierz telemetrię (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Pobierz telemetrię (JSON)';

  @override
  String get trajetDetailDownloadError => 'Nie udało się zapisać pliku';

  @override
  String get trajetDetailDeleteAction => 'Usuń';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Usunąć tę trasę?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Ta trasa zostanie trwale usunięta z historii.';

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
  String get trajetDetailChartBoost =>
      'Ciśnienie doładowania (MAP − otoczenie)';

  @override
  String get trajetDetailChartIat => 'Temperatura powietrza dolotowego';

  @override
  String get trajetDetailChartTiming => 'Wyprzedzenie zapłonu';

  @override
  String get trajetObd2Degraded =>
      'Rozpoczęto z adapterem OBD2, ale zapisano głównie z GPS — dane silnika są niepełne';

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
  String get tripPathLegendEfficient => 'Efektywne (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Graniczne (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Nieefektywne (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar stacji paliw';

  @override
  String get tripRadarScanning => 'Skanowanie pobliskich stacji';

  @override
  String get tripRadarNoStationNearby => 'Brak pobliskiej stacji';

  @override
  String get fuelStationRadarNearer => 'Bliższa stacja';

  @override
  String get fuelStationRadarFarther => 'Dalsza stacja';

  @override
  String get fuelStationRadarStart => 'Uruchom radar stacji paliw';

  @override
  String get stopRadar => 'Zatrzymaj radar';

  @override
  String get fuelStationRadarResultBadge => 'Wynik radaru stacji paliw';

  @override
  String get radarUpdatingLocation => 'Aktualizowanie lokalizacji…';

  @override
  String get radarSearching => 'Wyszukiwanie…';

  @override
  String get highwayModeChip =>
      'Tryb autostrady — pokazuje stacje przed Tobą na trasie';

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
  String get tripRecordingSavingTitle => 'Zapisywanie trasy…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Nagrywanie odrzucone — nie wykryto ruchu';

  @override
  String get tripRecordingGpsNotificationTitle => 'Nagrywanie Twojej trasy';

  @override
  String get tripRecordingGpsNotificationText =>
      'Śledzenie trasy dla statystyk paliwa i jazdy';

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
  String get tripVerdictPromptTitle => 'Jak oceniasz tę podróż?';

  @override
  String get tripVerdictSmooth => 'Płynna';

  @override
  String get tripVerdictModerate => 'Umiarkowana';

  @override
  String get tripVerdictAggressive => 'Agresywna';

  @override
  String get tripVerdictDismiss => 'Nie teraz';

  @override
  String get tripVerdictThanks =>
      'Dziękujemy — to pomaga skalibrować analizę Twojej jazdy.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Tankowanie usunięte';

  @override
  String get trajetDeletedUndoSnackbar => 'Nagranie usunięte';

  @override
  String get searchFailedSnackbar =>
      'Wyszukiwanie nie powiodło się — spróbuj ponownie';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stacji',
      one: '1 stacja',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Zaktualizowano $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Również: $names';
  }

  @override
  String get favoriteAdd => 'Dodaj do ulubionych';

  @override
  String get favoriteRemove => 'Usuń z ulubionych';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Cena brutto: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Stacja bez marki';

  @override
  String get unsupportedRegionTitle => 'Jeszcze niedostępne w Twoim regionie';

  @override
  String get unsupportedRegionBody =>
      'Nie mamy jeszcze cen paliw dla Twojego kraju, więc wyniki mogą być puste lub pochodzić z innego kraju. Nadal możesz wybrać obsługiwany kraj w ustawieniach wyszukiwania.';

  @override
  String get unsupportedRegionDismiss => 'Rozumiem';

  @override
  String get configureCountryTitle => 'Ustaw swój kraj';

  @override
  String get configureCountryBody =>
      'Twój kraj jest obsługiwany, ale nie został jeszcze ustawiony — ceny mogą więc pochodzić z innego kraju. Wybierz swój kraj w ustawieniach wyszukiwania, aby zobaczyć lokalne ceny.';

  @override
  String get stalePriceBadge => 'Old price';

  @override
  String get radiusAlertCenterChipGps => 'My position';

  @override
  String get radiusAlertCenterChipMap => 'Map point';

  @override
  String radiusAlertCenterChipPostal(String postalCode) {
    return 'Postal code $postalCode';
  }

  @override
  String get radiusAlertCenterClear => 'Clear location';

  @override
  String get radiusAlertBlockerLabel => 'Enter a label';

  @override
  String get radiusAlertBlockerThreshold => 'Enter a threshold above 0';

  @override
  String get radiusAlertBlockerLocation => 'Choose a location';

  @override
  String get allPricesNoPriceMask => '—';

  @override
  String get allPricesBestMarker => 'best';

  @override
  String allPricesDelta(String amount) {
    return '+$amount';
  }

  @override
  String allPricesCostPer100km(String cost) {
    return '$cost/100 km';
  }

  @override
  String allPricesVerdictHere(String fuel, String cost) {
    return 'Cheapest here: $fuel at $cost';
  }

  @override
  String get allPricesVerdictWinsResults => 'cheapest of the results';

  @override
  String allPricesMoreFuels(int count) {
    return '+$count';
  }

  @override
  String allPricesMoreFuelsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more fuels',
      one: 'Show 1 more fuel',
    );
    return '$_temp0';
  }

  @override
  String get allPricesFewerFuelsTooltip => 'Hide the extra fuels';

  @override
  String allPricesCellPriceSemantics(String fuel, String price) {
    return '$fuel $price';
  }

  @override
  String allPricesCellCostSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '$fuel $price, $cost per 100 km at $consumption';
  }

  @override
  String allPricesCellNoPriceSemantics(String fuel) {
    return '$fuel, no price';
  }

  @override
  String allPricesCellUnavailableSemantics(String fuel) {
    return '$fuel, out of stock';
  }

  @override
  String allPricesCellUnusableSemantics(String fuel) {
    return '$fuel, not usable by your vehicle';
  }

  @override
  String get brandMarkFuelGeneric => 'Fuel station';

  @override
  String get brandMarkEvGeneric => 'Charging point';

  @override
  String get fillInventoryTitle => 'Fill-up summary';

  @override
  String fillInventorySubtitleFull(String date, String fuel) {
    return 'Full tank on $date · $fuel';
  }

  @override
  String fillInventorySubtitlePartial(String date, String fuel) {
    return 'Partial fill on $date · $fuel';
  }

  @override
  String fillInventoryKmSinceLastFull(String km) {
    return '$km km since the last full tank';
  }

  @override
  String fillInventoryPumpLiters(String liters) {
    return '$liters L pumped';
  }

  @override
  String fillInventoryPumpConsumption(String value) {
    return 'Pump consumption: $value';
  }

  @override
  String fillInventoryRecordedTrips(int coverage, String value) {
    return 'Recorded trips: $coverage % of the tank · $value raw';
  }

  @override
  String get fillInventoryNoRecordedTrips => 'No recorded trip in this tank';

  @override
  String fillInventoryTankNow(String liters, String km) {
    return 'Tank now: $liters L · ≈ $km km at pump consumption';
  }

  @override
  String fillInventoryTankNowNoRange(String liters) {
    return 'Tank now: $liters L';
  }

  @override
  String fillInventoryCalibrationApplied(
    String before,
    String after,
    String percent,
  ) {
    return 'Pump calibration: ×$before → ×$after ($percent %)';
  }

  @override
  String fillInventoryCalibrationSkipped(String reason) {
    return 'Pump calibration: skipped — $reason';
  }

  @override
  String get fillInventorySkipNotFullTank =>
      'partial fill (the tank window stays open)';

  @override
  String get fillInventorySkipCorrection =>
      'correction entry, not a pumped fill';

  @override
  String get fillInventorySkipNoVehicle => 'no vehicle on this fill';

  @override
  String get fillInventorySkipNoWindow =>
      'first full tank (no window closed yet)';

  @override
  String fillInventorySkipCoverageTooLow(int coverage) {
    return 'recorded trips cover $coverage % of the tank (60 % needed)';
  }

  @override
  String fillInventorySkipRecordedTooShort(String km) {
    return 'only $km recorded km (40 km needed)';
  }

  @override
  String get fillInventorySkipNoRecordedFuel =>
      'the recorded trips carry no fuel figure';

  @override
  String get fillInventorySkipImplausible =>
      'pump and recordings disagree too much — check the receipt';

  @override
  String get fillInventoryDismiss => 'Got it';

  @override
  String tankReportResidualAfterCalibration(String percent) {
    return 'Gap after calibration: $percent %';
  }

  @override
  String get tripFuelSourceMeasured => 'Measured';

  @override
  String get tripFuelSourceEstimatedCalibrated => 'Estimated · calibrated';

  @override
  String get tripFuelSourceEstimated => 'Estimated';

  @override
  String get tripFuelSourceGps => 'GPS';

  @override
  String get tripFuelSourceMeasuredTooltip =>
      'Fuel rate reported by the engine (PID 5E / 9D / A2) — never rescaled';

  @override
  String get tripFuelSourceEstimatedTooltip =>
      'Fuel estimated from air mass — rescaled by the pump calibration';

  @override
  String get tripFuelSourceGpsTooltip =>
      'GPS-physics estimate — no engine data';

  @override
  String get tripFuelSourceRecalculated => 'recalculated';

  @override
  String tripDetailGainApplied(String percent) {
    return 'Pump gain applied: $percent %';
  }

  @override
  String tripDetailRecalculatedAfterFill(String date) {
    return 'Recalculated after the fill-up of $date';
  }

  @override
  String get criteriaModeNearby => 'Nearby';

  @override
  String get criteriaModeRoute => 'Route';

  @override
  String get criteriaSubmit => 'Search';

  @override
  String get criteriaReset => 'Reset';

  @override
  String get criteriaResetDone => 'Criteria reset to your defaults';

  @override
  String get criteriaSubmitDisabledRoute => 'Enter a start and a destination';

  @override
  String get criteriaSubmitDisabledSearching => 'Search in progress…';

  @override
  String criteriaShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get criteriaShowLess => 'Show less';

  @override
  String get criteriaBrands => 'Brands';

  @override
  String get criteriaRouteOptions => 'Route options';

  @override
  String criteriaRouteOptionsSummary(
    int segmentKm,
    int detourKm,
    String saving,
  ) {
    return 'Every $segmentKm km · $detourKm km detour · $saving';
  }

  @override
  String get criteriaSwapEndpoints => 'Swap start and destination';

  @override
  String get fillUpOdometerFromLastFillUp =>
      'Pre-filled from your last fill-up';

  @override
  String get fillUpStationLabel => 'Station';

  @override
  String get fillUpStationChange => 'Change';

  @override
  String get pickStationSectionLast => 'Last station';

  @override
  String get pickStationSectionFavorites => 'Favorites';

  @override
  String get pickStationSectionNearby => 'Nearby';

  @override
  String get pickStationNearbyEmpty =>
      'No recent search — search for stations on the Search tab and the nearest ones will appear here.';

  @override
  String pickStationLastFillUpAt(String date) {
    return 'Last fill-up: $date';
  }

  @override
  String get helpBubblePreviousTip => 'Previous tip';

  @override
  String get helpBubbleNextTip => 'Next tip';

  @override
  String helpBubbleTipPosition(int index, int total) {
    return '$index/$total';
  }

  @override
  String helpBubbleTipPositionSemantic(int index, int total) {
    return 'Tip $index of $total';
  }

  @override
  String get helpSearchTipSummaryBar =>
      'Tap the grey bar above the results to change your fuel, your radius and every other search criterion.';

  @override
  String get helpSearchTipFillEmphasis =>
      'In the comparison table, a filled cell marks the cheapest price for that fuel among the stations you are looking at.';

  @override
  String get helpSearchTipSecondFigure =>
      'The smaller second figure in a cell is what 100 km on that fuel costs in your vehicle.';

  @override
  String get helpSearchTipPriceArrows =>
      'The arrow beside a price ranks it inside this list — cheapest, middle or dearest third of these results. It is not a price trend over time.';

  @override
  String get helpSearchTipViewToggle =>
      'The view button switches between the compact cards and the table that compares every fuel at once.';

  @override
  String searchSummaryFuelTooltip(String fuel) {
    return 'Fuel: $fuel';
  }

  @override
  String searchSummaryRadiusValue(String km) {
    return '$km km';
  }

  @override
  String get searchSummaryAgeJustNow => 'now';

  @override
  String searchSummaryAgeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String searchSummaryAgeHours(int hours) {
    return '$hours h';
  }

  @override
  String searchSummaryAgeDays(int days) {
    return '$days d';
  }

  @override
  String get logoCreditsTitle => 'Logo credits';

  @override
  String logoCreditsAboutSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brand logos from Wikimedia Commons',
      one: '1 brand logo from Wikimedia Commons',
    );
    return '$_temp0';
  }

  @override
  String get logoCreditsIntro =>
      'These station and charging-network logos are bundled with the app. Every file was taken from Wikimedia Commons and is public domain or published under a Creative Commons licence — nothing is downloaded while you browse.';

  @override
  String get logoCreditsMonogramNote =>
      'Brands whose logo is not available under a free licence keep the lettered mark in the app\'s own colours.';

  @override
  String get logoCreditsTrademarkNotice =>
      'All trademarks are the property of their respective owners and are shown only to identify the station or the charging network.';

  @override
  String logoCreditsEntryDetails(String licence, String author) {
    return '$licence · $author';
  }

  @override
  String get logoCreditsOpenFilePage =>
      'Open the file page on Wikimedia Commons';

  @override
  String get privacyTopicSubtitle =>
      'Your choices, data on this device, sync, export or delete';

  @override
  String get privacyDataLocationLocal => 'Your data stays on this device';

  @override
  String get privacyDataLocationSynced =>
      'Your data is also synced to TankSync';

  @override
  String get privacySyncLineEnabledAnonymous => 'Sync: on · anonymous account';

  @override
  String get privacySyncLineEnabledEmail => 'Sync: on · email account';

  @override
  String get privacySyncLineDisabled => 'Sync: off';

  @override
  String privacyStorageLine(String size) {
    return '$size stored on this device';
  }

  @override
  String get privacyTopicChoicesTitle => 'Your choices';

  @override
  String privacyChoicesStatus(int on, int total) {
    return '$on of $total enabled';
  }

  @override
  String privacyDeviceDataStatus(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$size · $_temp0';
  }

  @override
  String get privacyTopicExportDeleteTitle => 'Export or delete';

  @override
  String privacyExportDeleteStatus(int count) {
    return 'ZIP, JSON, CSV · error log ($count)';
  }

  @override
  String get privacyLearnMore => 'Learn more';

  @override
  String get tileProxyToggleShort =>
      'Tiles come via the developer\'s EU proxy, not straight from OpenStreetMap';

  @override
  String get remoteLogosToggleShort =>
      'Fetch brand logos from logo.clearbit.com instead of bundled placeholders';

  @override
  String get privacyCacheDetails => 'Cache details';

  @override
  String privacyCacheResponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cached responses',
      one: '1 cached response',
    );
    return '$_temp0';
  }

  @override
  String privacyClearCacheEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'Clear cache ($_temp0)';
  }

  @override
  String get privacySyncStatusLabel => 'Status';

  @override
  String get privacySyncModeCommunity =>
      'Sparkilo Community — the developer\'s EU server';

  @override
  String get privacySyncModeSelfHosted => 'Self-hosted — your own Supabase';

  @override
  String get privacySyncModeSharedGroup =>
      'Shared group — a database you joined';

  @override
  String get privacySyncAccountLabel => 'Account';

  @override
  String get privacySyncAccountAnonymous =>
      'Anonymous account, tied to this device';

  @override
  String privacySyncAccountEmail(String email) {
    return 'Email account: $email';
  }

  @override
  String get privacyCopyUserId => 'Copy user ID';

  @override
  String get privacyUserIdCopied => 'User ID copied';

  @override
  String get privacySyncDatabaseHost => 'Database host';

  @override
  String get privacyExportSectionTitle => 'Export';

  @override
  String get privacyExportMyData => 'Export my data';

  @override
  String get privacyExportSheetTitle => 'Choose a format';

  @override
  String get privacyExportZipTitle => 'ZIP archive';

  @override
  String get privacyExportZipSubtitle =>
      'Everything, attachments included — for a complete backup';

  @override
  String get privacyExportJsonTitle => 'JSON';

  @override
  String get privacyExportJsonSubtitle => 'Machine-readable — for another app';

  @override
  String get privacyExportCsvTitle => 'CSV';

  @override
  String get privacyExportCsvSubtitle => 'Spreadsheet — one table per category';

  @override
  String get privacyErrorLogTitle => 'Error log';

  @override
  String privacyErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get privacyErrorLogSave => 'Save';

  @override
  String get privacyErrorLogClear => 'Clear';

  @override
  String get privacyDangerZoneTitle => 'Danger zone';

  @override
  String get privacyDangerZoneBody =>
      'Permanently deletes everything the app stores on this device. With sync on, your data on the TankSync server is erased too.';

  @override
  String get privacyDeleteAllMyData => 'Delete all my data';

  @override
  String get tripRecordingScreenTitle => 'Trip in progress';

  @override
  String get recordingObd2ChipLive => 'Live';

  @override
  String recordingObd2ChipLiveRate(int rate) {
    return 'Live · $rate PID/s';
  }

  @override
  String get recordingObd2ChipReconnecting => 'Reconnecting…';

  @override
  String recordingObd2ChipReconnectingAttempt(int attempt) {
    return 'Reconnecting… (try $attempt)';
  }

  @override
  String get recordingObd2ChipGpsOnly => 'GPS only';

  @override
  String get recordingObd2ChipEngineOff => 'Engine off — waiting';

  @override
  String get recordingObd2ChipNoAdapter => 'No adapter';

  @override
  String get recordingObd2SheetTitle => 'OBD2 link';

  @override
  String get recordingObd2SheetLive =>
      'The adapter is delivering engine data, so consumption is measured from the car. Nothing to do — keep driving.';

  @override
  String get recordingObd2SheetReconnecting =>
      'The Bluetooth link is being re-established; meanwhile the recording continues on GPS. No action needed — a reset only helps if it stays like this for minutes.';

  @override
  String get recordingObd2SheetGpsOnly =>
      'The adapter has not answered for a while, so the app waits for it to reappear and records on GPS. Consumption is estimated until it is back.';

  @override
  String get recordingObd2SheetEngineOff =>
      'The engine is off, so there is nothing to read. The recording continues on GPS and picks the adapter up again as soon as the engine runs.';

  @override
  String get recordingObd2SheetNoAdapter =>
      'This trip is recorded without an OBD2 adapter. Speed and distance come from GPS; consumption is a physics estimate calibrated by your fill-ups.';

  @override
  String recordingGpsChipPrecise(int meters) {
    return 'Precise fix (±$meters m)';
  }

  @override
  String recordingGpsChipApprox(int meters) {
    return 'Approximate fix (±$meters m)';
  }

  @override
  String get recordingGpsChipNoFix => 'No fix';

  @override
  String get recordingGpsChipFixUnknownAccuracy => 'Fix (accuracy unknown)';

  @override
  String recordingGpsChipWithCoverage(String fix, int percent) {
    return '$fix · $percent %';
  }

  @override
  String get recordingGpsSheetTitle => 'GPS signal';

  @override
  String get recordingGpsSheetPrecise =>
      'The position is accurate to a few metres, so distance and the trace are reliable.';

  @override
  String get recordingGpsSheetApprox =>
      'The position is only accurate to tens of metres — typical in cities, tunnels or under trees. Distance may drift slightly until the fix improves.';

  @override
  String get recordingGpsSheetNoFix =>
      'No position has arrived recently. Check that location is allowed and the phone can see the sky; the recording resumes with the next fix.';

  @override
  String recordingGpsSheetCoverage(int percent) {
    return 'Coverage so far: $percent % of the seconds had a fix.';
  }

  @override
  String get recordingSheetClose => 'Got it';

  @override
  String get fuelSourceMeasured => 'Measured (ECU fuel flow)';

  @override
  String fuelSourceEstimatedCalibrated(int percent) {
    return 'Estimated · pump-calibrated ±$percent %';
  }

  @override
  String get fuelSourceEstimatedUncalibrated => 'Estimated · not calibrated';

  @override
  String get fuelSourceGpsEstimate => 'GPS estimate';

  @override
  String get recordingTileScore => 'Driving score';

  @override
  String searchSummaryAlongRoute(String km) {
    return 'Along the route · every $km km';
  }

  @override
  String get searchSummaryPricesJustNow => 'Prices from just now';

  @override
  String searchSummaryPricesMinutes(int minutes) {
    return 'Prices from $minutes min ago';
  }

  @override
  String searchSummaryPricesHours(int hours) {
    return 'Prices from $hours h ago';
  }

  @override
  String searchSummaryPricesDays(int days) {
    return 'Prices from $days d ago';
  }

  @override
  String get searchResultsFilterTooltip => 'Filters';

  @override
  String searchResultsFilterActiveSemantic(int count) {
    return 'Filters, $count active';
  }

  @override
  String get searchResultsMoreActionsTooltip => 'More actions';

  @override
  String get searchPriceArrowLegend =>
      '↓ and ↑ compare each price with the other stations in this list.';

  @override
  String get searchPriceArrowCheapTooltip =>
      'Among the lowest prices in this list';

  @override
  String get searchPriceArrowAverageTooltip => 'A mid-range price in this list';

  @override
  String get searchPriceArrowExpensiveTooltip =>
      'Among the highest prices in this list';

  @override
  String get searchRefreshTooltip => 'Update position and refresh prices';

  @override
  String priceHistoryFirstSeen(String date) {
    return 'First seen on $date — the history builds up with every visit';
  }

  @override
  String priceHistoryCurrentPriceLine(String price) {
    return 'Current price: $price';
  }

  @override
  String priceHistoryDeltaSince(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String priceHistoryUnchangedSince(String date) {
    return 'Unchanged since $date';
  }

  @override
  String get priceStatsMin => 'Min';

  @override
  String get priceStatsMax => 'Max';

  @override
  String get priceStatsAvg => 'Avg';

  @override
  String get amenitiesAndServices => 'Amenities & services';

  @override
  String amenitiesServicesShowMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get amenitiesServicesShowLess => 'Show less';

  @override
  String stationStatusWithFreshness(String status, String ago) {
    return '$status · updated $ago ago';
  }

  @override
  String pricesNotSoldHere(String fuels) {
    return 'Not sold here: $fuels';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return 'Recorded trips cover $pct % of this tank';
  }

  @override
  String tankReportRecordedTripsAvg(String value) {
    return 'Recorded trips: $value';
  }

  @override
  String tankReportRecordedTripsOverestimate(String pct) {
    return 'Your recorded trips overestimate consumption by $pct %';
  }

  @override
  String tankReportRecordedTripsUnderestimate(String pct) {
    return 'Your recorded trips underestimate consumption by $pct %';
  }

  @override
  String get trajetObd2DegradedSubtitle => 'No engine data — GPS estimate';

  @override
  String get vehicleTopicAdapterNone => 'None';

  @override
  String get vehicleTopicCalibrationTitle => 'Calibration';

  @override
  String get vehicleTopicAdvancedBadge => 'Advanced';

  @override
  String vehicleTopicCalibrationStatus(int coverage, String mode) {
    return 'Baseline $coverage % · $mode';
  }

  @override
  String vehicleTopicRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
      zero: 'No reminders',
    );
    return '$_temp0';
  }

  @override
  String get vehicleTopicAutoRecordOn => 'On';

  @override
  String get vehicleTopicAutoRecordOff => 'Off';

  @override
  String get vehicleTopicAutoRecordPairLinkText =>
      'Pair an adapter under “OBD2 adapter” to enable auto-recording';

  @override
  String vehicleBaselineCoverageSamples(int covered, int max) {
    return '$covered / $max samples';
  }

  @override
  String vehicleBaselineRawSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get calibrationModeRuleDescription =>
      'Sorts each driving sample into one situation using fixed speed and load thresholds.';

  @override
  String get calibrationModeFuzzyDescription =>
      'Splits each sample across neighbouring situations by how well it fits each one — smoother estimates around the boundaries.';

  @override
  String get pumpGainChipNotCalibrated => 'Not pump-calibrated yet';

  @override
  String pumpGainChipCalibrated(int fills, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      fills,
      locale: localeName,
      other: 'Pump-calibrated · $fills fill-ups · ±$percent %',
      one: 'Pump-calibrated · 1 fill-up · ±$percent %',
    );
    return '$_temp0';
  }

  @override
  String get pumpGainResetAction => 'Reset pump calibration';

  @override
  String get pumpGainResetConfirmTitle => 'Reset pump calibration?';

  @override
  String get pumpGainResetConfirmBody =>
      'This discards the fuel gain learned from your fill-ups. OBD2 consumption estimates fall back to the uncorrected figure until the next full-to-full tank window re-learns it.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Mogę tankować różne rodzaje paliwa';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Śledzi, które paliwo jest najtańsze na kilometr';

  @override
  String get vinLabel => 'VIN (opcjonalnie)';

  @override
  String get vinDecodeTooltip => 'Dekoduj VIN';

  @override
  String get vinConfirmAction => 'Tak, uzupełnij automatycznie';

  @override
  String get vinModifyAction => 'Zmień ręcznie';

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
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Wykryto z VIN: $summary. Zastosować?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Zastosuj';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm kilometry do przodu, $fuelType $euros euro $cents';
  }

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
  String get widgetDefaultsThisProfileHint =>
      'Poniższe wybory dotyczą każdego zainstalowanego widżetu pokazującego ten profil, przy następnym odświeżeniu.';

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
}
