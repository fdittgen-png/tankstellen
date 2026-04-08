// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'Цени на горива';

  @override
  String get search => 'Търсене';

  @override
  String get favorites => 'Любими';

  @override
  String get map => 'Карта';

  @override
  String get profile => 'Профил';

  @override
  String get settings => 'Настройки';

  @override
  String get gpsLocation => 'GPS местоположение';

  @override
  String get zipCode => 'Пощенски код';

  @override
  String get zipCodeHint => 'напр. 1000';

  @override
  String get fuelType => 'Гориво';

  @override
  String get searchRadius => 'Радиус';

  @override
  String get searchNearby => 'Близки бензиностанции';

  @override
  String get searchButton => 'Търсене';

  @override
  String get noResults => 'Не са намерени бензиностанции.';

  @override
  String get startSearch => 'Потърсете, за да намерите бензиностанции.';

  @override
  String get open => 'Отворено';

  @override
  String get closed => 'Затворено';

  @override
  String distance(String distance) {
    return 'на $distance';
  }

  @override
  String get price => 'Цена';

  @override
  String get prices => 'Цени';

  @override
  String get address => 'Адрес';

  @override
  String get openingHours => 'Работно време';

  @override
  String get open24h => 'Отворено 24 часа';

  @override
  String get navigate => 'Навигация';

  @override
  String get retry => 'Опитайте отново';

  @override
  String get apiKeySetup => 'API ключ';

  @override
  String get apiKeyDescription =>
      'Регистрирайте се веднъж за безплатен API ключ.';

  @override
  String get apiKeyLabel => 'API ключ';

  @override
  String get register => 'Регистрация';

  @override
  String get continueButton => 'Продължи';

  @override
  String get welcome => 'Цени на горива';

  @override
  String get welcomeSubtitle => 'Намерете най-евтиното гориво наблизо.';

  @override
  String get profileName => 'Име на профила';

  @override
  String get preferredFuel => 'Предпочитано гориво';

  @override
  String get defaultRadius => 'Радиус по подразбиране';

  @override
  String get landingScreen => 'Начален екран';

  @override
  String get homeZip => 'Домашен пощенски код';

  @override
  String get newProfile => 'Нов профил';

  @override
  String get editProfile => 'Редактиране на профил';

  @override
  String get save => 'Запази';

  @override
  String get cancel => 'Отказ';

  @override
  String get delete => 'Изтрий';

  @override
  String get activate => 'Активирай';

  @override
  String get configured => 'Конфигурирано';

  @override
  String get notConfigured => 'Не е конфигурирано';

  @override
  String get about => 'За приложението';

  @override
  String get openSource => 'Отворен код (MIT лиценз)';

  @override
  String get sourceCode => 'Изходен код в GitHub';

  @override
  String get noFavorites => 'Няма любими';

  @override
  String get noFavoritesHint =>
      'Докоснете звездата на бензиностанция, за да я запазите в любими.';

  @override
  String get language => 'Език';

  @override
  String get country => 'Държава';

  @override
  String get demoMode => 'Демо режим — показани са примерни данни.';

  @override
  String get setupLiveData => 'Настройка за реални данни';

  @override
  String get freeNoKey => 'Безплатно — не е необходим ключ';

  @override
  String get apiKeyRequired => 'Необходим е API ключ';

  @override
  String get skipWithoutKey => 'Продължи без ключ';

  @override
  String get dataTransparency => 'Прозрачност на данните';

  @override
  String get storageAndCache => 'Съхранение и кеш';

  @override
  String get clearCache => 'Изчистване на кеша';

  @override
  String get clearAllData => 'Изтриване на всички данни';

  @override
  String get errorLog => 'Дневник на грешките';

  @override
  String stationsFound(int count) {
    return 'Намерени $count бензиностанции';
  }

  @override
  String get whatIsShared => 'Какво се споделя — и с кого?';

  @override
  String get gpsCoordinates => 'GPS координати';

  @override
  String get gpsReason =>
      'Изпращат се при всяко търсене за намиране на близки станции.';

  @override
  String get postalCodeData => 'Пощенски код';

  @override
  String get postalReason =>
      'Преобразува се в координати чрез услуга за геокодиране.';

  @override
  String get mapViewport => 'Изглед на картата';

  @override
  String get mapReason =>
      'Плочките на картата се зареждат от сървъра. Не се предават лични данни.';

  @override
  String get apiKeyData => 'API ключ';

  @override
  String get apiKeyReason =>
      'Вашият личен ключ се изпраща с всяка API заявка. Свързан е с вашия имейл.';

  @override
  String get notShared => 'НЕ се споделя:';

  @override
  String get searchHistory => 'История на търсенето';

  @override
  String get favoritesData => 'Любими';

  @override
  String get profileNames => 'Имена на профили';

  @override
  String get homeZipData => 'Домашен пощенски код';

  @override
  String get usageData => 'Данни за използване';

  @override
  String get privacyBanner =>
      'Това приложение няма сървър. Всички данни остават на вашето устройство. Без анализи, проследяване или реклами.';

  @override
  String get storageUsage => 'Използване на паметта на това устройство';

  @override
  String get settingsLabel => 'Настройки';

  @override
  String get profilesStored => 'запазени профила';

  @override
  String get stationsMarked => 'маркирани станции';

  @override
  String get cachedResponses => 'кеширани отговора';

  @override
  String get total => 'Общо';

  @override
  String get cacheManagement => 'Управление на кеша';

  @override
  String get cacheDescription =>
      'Кешът съхранява API отговори за по-бързо зареждане и офлайн достъп.';

  @override
  String get stationSearch => 'Търсене на станции';

  @override
  String get stationDetails => 'Детайли за станцията';

  @override
  String get priceQuery => 'Запитване за цена';

  @override
  String get zipGeocoding => 'Геокодиране на пощенски код';

  @override
  String minutes(int n) {
    return '$n минути';
  }

  @override
  String hours(int n) {
    return '$n часа';
  }

  @override
  String get clearCacheTitle => 'Изчистване на кеша?';

  @override
  String get clearCacheBody =>
      'Кешираните резултати от търсене и цени ще бъдат изтрити. Профилите, любимите и настройките се запазват.';

  @override
  String get clearCacheButton => 'Изчисти кеша';

  @override
  String get deleteAllTitle => 'Изтриване на всички данни?';

  @override
  String get deleteAllBody =>
      'Това ще изтрие завинаги всички профили, любими, API ключ, настройки и кеш. Приложението ще се нулира.';

  @override
  String get deleteAllButton => 'Изтрий всичко';

  @override
  String get entries => 'записа';

  @override
  String get cacheEmpty => 'Кешът е празен';

  @override
  String get noStorage => 'Няма използвана памет';

  @override
  String get apiKeyNote =>
      'Безплатна регистрация. Данни от държавни агенции за ценова прозрачност.';

  @override
  String get apiKeyFormatError =>
      'Невалиден формат — очакван UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Подкрепете този проект';

  @override
  String get supportDescription =>
      'Това приложение е безплатно, с отворен код и без реклами. Ако го намирате за полезно, помислете да подкрепите разработчика.';

  @override
  String get reportBug => 'Докладване на грешка / Предложение за функция';

  @override
  String get privacyPolicy => 'Политика за поверителност';

  @override
  String get fuels => 'Горива';

  @override
  String get services => 'Услуги';

  @override
  String get zone => 'Зона';

  @override
  String get highway => 'Магистрала';

  @override
  String get localStation => 'Местна станция';

  @override
  String get lastUpdate => 'Последна актуализация';

  @override
  String get automate24h => '24ч/24 — Автомат';

  @override
  String get refreshPrices => 'Обновяване на цените';

  @override
  String get station => 'Бензиностанция';

  @override
  String get locationDenied =>
      'Разрешението за местоположение е отказано. Можете да търсите по пощенски код.';

  @override
  String get demoModeBanner => 'Демо режим. Настройте API ключа в настройките.';

  @override
  String get sortDistance => 'Разстояние';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'евтино';

  @override
  String get expensive => 'скъпо';

  @override
  String stationsOnMap(int count) {
    return '$count станции';
  }

  @override
  String get loadingFavorites =>
      'Зареждане на любими...\nПърво потърсете станции, за да запазите данни.';

  @override
  String get reportPrice => 'Докладване на цена';

  @override
  String get whatsWrong => 'Какво не е наред?';

  @override
  String get correctPrice => 'Правилна цена (напр. 1,459)';

  @override
  String get sendReport => 'Изпрати доклада';

  @override
  String get reportSent => 'Докладът е изпратен. Благодарим!';

  @override
  String get enterValidPrice => 'Въведете валидна цена';

  @override
  String get cacheCleared => 'Кешът е изчистен.';

  @override
  String get yourPosition => 'Вашата позиция';

  @override
  String get positionUnknown => 'Позицията е неизвестна';

  @override
  String get distancesFromCenter => 'Разстояния от центъра на търсенето';

  @override
  String get autoUpdatePosition => 'Автоматично обновяване на позицията';

  @override
  String get autoUpdateDescription =>
      'Обновяване на GPS позицията преди всяко търсене';

  @override
  String get location => 'Местоположение';

  @override
  String get switchProfileTitle => 'Държавата е сменена';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Сега сте в $country. Превключване към профил \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Превключено към профил \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Няма профил за тази държава';

  @override
  String noProfileForCountry(String country) {
    return 'Намирате се в $country, но няма конфигуриран профил. Създайте един в Настройки.';
  }

  @override
  String get autoSwitchProfile => 'Автоматично превключване на профил';

  @override
  String get autoSwitchDescription =>
      'Автоматично превключване на профила при преминаване на граница';

  @override
  String get switchProfile => 'Превключи';

  @override
  String get dismiss => 'Затвори';

  @override
  String get profileCountry => 'Държава';

  @override
  String get profileLanguage => 'Език';

  @override
  String get settingsStorageDetail => 'API ключ, активен профил';

  @override
  String get allFuels => 'Всички';

  @override
  String get priceAlerts => 'Ценови сигнали';

  @override
  String get noPriceAlerts => 'Няма ценови сигнали';

  @override
  String get noPriceAlertsHint =>
      'Създайте сигнал от страницата с детайли на станция.';

  @override
  String alertDeleted(String name) {
    return 'Сигнал \"$name\" изтрит';
  }

  @override
  String get createAlert => 'Създаване на ценови сигнал';

  @override
  String currentPrice(String price) {
    return 'Текуща цена: $price';
  }

  @override
  String get targetPrice => 'Целева цена (EUR)';

  @override
  String get enterPrice => 'Въведете цена';

  @override
  String get invalidPrice => 'Невалидна цена';

  @override
  String get priceTooHigh => 'Цената е твърде висока';

  @override
  String get create => 'Създай';

  @override
  String get alertCreated => 'Ценовият сигнал е създаден';

  @override
  String get wrongE5Price => 'Грешна цена Super E5';

  @override
  String get wrongE10Price => 'Грешна цена Super E10';

  @override
  String get wrongDieselPrice => 'Грешна цена на дизела';

  @override
  String get wrongStatusOpen => 'Показано като отворено, но затворено';

  @override
  String get wrongStatusClosed => 'Показано като затворено, но отворено';

  @override
  String get searchAlongRouteLabel => 'По маршрута';

  @override
  String get searchEvStations => 'Търсене на зарядни станции';

  @override
  String get allStations => 'Всички станции';

  @override
  String get bestStops => 'Най-добри спирки';

  @override
  String get openInMaps => 'Отвори в Карти';

  @override
  String get noStationsAlongRoute => 'Не са намерени станции по маршрута';

  @override
  String get evOperational => 'В експлоатация';

  @override
  String get evStatusUnknown => 'Състояние неизвестно';

  @override
  String evConnectors(int count) {
    return 'Конектори ($count точки)';
  }

  @override
  String get evNoConnectors => 'Няма налични детайли за конекторите';

  @override
  String get evUsageCost => 'Разходи за ползване';

  @override
  String get evPricingUnavailable =>
      'Ценова информация не е налична от доставчика';

  @override
  String get evLastUpdated => 'Последна актуализация';

  @override
  String get evUnknown => 'Неизвестно';

  @override
  String get evDataAttribution => 'Данни от OpenChargeMap (обществен източник)';

  @override
  String get evStatusDisclaimer =>
      'Състоянието може да не отразява наличността в реално време. Натиснете обновяване за най-новите данни.';

  @override
  String get evNavigateToStation => 'Навигация към станцията';

  @override
  String get evRefreshStatus => 'Обновяване на състоянието';

  @override
  String get evStatusUpdated => 'Състоянието е обновено';

  @override
  String get evStationNotFound =>
      'Не може да се обнови — станцията не е намерена наблизо';

  @override
  String get addedToFavorites => 'Добавено в любими';

  @override
  String get removedFromFavorites => 'Премахнато от любими';

  @override
  String get addFavorite => 'Добави в любими';

  @override
  String get removeFavorite => 'Премахни от любими';

  @override
  String get currentLocation => 'Текущо местоположение';

  @override
  String get gpsError => 'GPS грешка';

  @override
  String get couldNotResolve => 'Не може да се определи начало или дестинация';

  @override
  String get start => 'Начало';

  @override
  String get destination => 'Дестинация';

  @override
  String get cityAddressOrGps => 'Град, адрес или GPS';

  @override
  String get cityOrAddress => 'Град или адрес';

  @override
  String get useGps => 'Използвай GPS';

  @override
  String get stop => 'Спирка';

  @override
  String stopN(int n) {
    return 'Спирка $n';
  }

  @override
  String get addStop => 'Добави спирка';

  @override
  String get searchAlongRoute => 'Търсене по маршрута';

  @override
  String get cheapest => 'Най-евтина';

  @override
  String nStations(int count) {
    return '$count станции';
  }

  @override
  String nBest(int count) {
    return '$count най-добри';
  }

  @override
  String get fuelPricesTankerkoenig => 'Цени на горива (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Необходим за търсене на цени на горива в Германия';

  @override
  String get evChargingOpenChargeMap => 'EV зареждане (OpenChargeMap)';

  @override
  String get customKey => 'Персонализиран ключ';

  @override
  String get appDefaultKey => 'Ключ по подразбиране на приложението';

  @override
  String get optionalOverrideKey =>
      'По избор: заменете вградения ключ с ваш собствен';

  @override
  String get requiredForEvSearch =>
      'Необходим за търсене на EV зарядни станции';

  @override
  String get edit => 'Редактиране';

  @override
  String get fuelPricesApiKey => 'API ключ за цени на горива';

  @override
  String get tankerkoenigApiKey => 'API ключ Tankerkoenig';

  @override
  String get evChargingApiKey => 'API ключ за EV зареждане';

  @override
  String get openChargeMapApiKey => 'API ключ OpenChargeMap';

  @override
  String get routeSegment => 'Сегмент на маршрута';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Показвай най-евтината станция на всеки $km км по маршрута';
  }

  @override
  String get avoidHighways => 'Избягвай магистрали';

  @override
  String get avoidHighwaysDesc =>
      'Изчисляването на маршрута избягва платени пътища и магистрали';

  @override
  String get showFuelStations => 'Показвай бензиностанции';

  @override
  String get showFuelStationsDesc =>
      'Включи бензинови, дизелови, LPG, CNG станции';

  @override
  String get showEvStations => 'Показвай зарядни станции';

  @override
  String get showEvStationsDesc =>
      'Включи електрически зарядни станции в резултатите';

  @override
  String get noStationsAlongThisRoute =>
      'Не са намерени станции по този маршрут.';

  @override
  String get fuelCostCalculator => 'Калкулатор за разход на гориво';

  @override
  String get distanceKm => 'Разстояние (км)';

  @override
  String get consumptionL100km => 'Разход (L/100км)';

  @override
  String get fuelPriceEurL => 'Цена на гориво (EUR/L)';

  @override
  String get tripCost => 'Разход за пътуването';

  @override
  String get fuelNeeded => 'Необходимо гориво';

  @override
  String get totalCost => 'Общ разход';

  @override
  String get enterCalcValues =>
      'Въведете разстояние, разход и цена за изчисляване на разхода за пътуването';

  @override
  String get priceHistory => 'Ценова история';

  @override
  String get noPriceHistory => 'Все още няма ценова история';

  @override
  String get noHourlyData => 'Няма почасови данни';

  @override
  String get noStatistics => 'Няма налични статистики';

  @override
  String get statMin => 'Мин';

  @override
  String get statMax => 'Макс';

  @override
  String get statAvg => 'Ср';

  @override
  String get showAllFuelTypes => 'Показване на всички видове горива';

  @override
  String get connected => 'Свързано';

  @override
  String get notConnected => 'Не е свързано';

  @override
  String get connectTankSync => 'Свързване с TankSync';

  @override
  String get disconnectTankSync => 'Прекъсване на TankSync';

  @override
  String get viewMyData => 'Преглед на моите данни';

  @override
  String get optionalCloudSync =>
      'По избор облачна синхронизация за сигнали, любими и push известия';

  @override
  String get tapToUpdateGps => 'Натиснете за обновяване на GPS позицията';

  @override
  String get gpsAutoUpdateHint =>
      'GPS позицията се получава автоматично при търсене. Можете също да я обновите ръчно тук.';

  @override
  String get clearGpsConfirm =>
      'Изтриване на запазената GPS позиция? Можете да я обновите отново по всяко време.';

  @override
  String get pageNotFound => 'Страницата не е намерена';

  @override
  String get deleteAllServerData => 'Изтриване на всички данни от сървъра';

  @override
  String get deleteServerDataConfirm => 'Изтриване на всички данни от сървъра?';

  @override
  String get deleteEverything => 'Изтрий всичко';

  @override
  String get allDataDeleted => 'Всички данни от сървъра са изтрити';

  @override
  String get disconnectConfirm => 'Прекъсване на TankSync?';

  @override
  String get disconnect => 'Прекъсни';

  @override
  String get myServerData => 'Моите данни на сървъра';

  @override
  String get anonymousUuid => 'Анонимен UUID';

  @override
  String get server => 'Сървър';

  @override
  String get syncedData => 'Синхронизирани данни';

  @override
  String get pushTokens => 'Push токени';

  @override
  String get priceReports => 'Ценови доклади';

  @override
  String get totalItems => 'Общо елементи';

  @override
  String get estimatedSize => 'Приблизителен размер';

  @override
  String get viewRawJson => 'Преглед на необработени данни като JSON';

  @override
  String get exportJson => 'Експорт като JSON (клипборд)';

  @override
  String get jsonCopied => 'JSON копиран в клипборда';

  @override
  String get rawDataJson => 'Необработени данни (JSON)';

  @override
  String get close => 'Затвори';

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
}
