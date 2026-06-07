// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Отвори търсене';

  @override
  String get fabOpenResults => 'Отвори резултати';

  @override
  String get fabRunSearch => 'Стартирай търсене';

  @override
  String get fabRefineCriteria => 'Прецизирай търсене';

  @override
  String get routeSearchPartialBanner => 'Търсене на още станции…';

  @override
  String get routeSearchingChip => 'Търсене по маршрута…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'На всеки $km km';
  }

  @override
  String get searchCriteriaTitle => 'Критерии за търсене';

  @override
  String get searchCriteriaOpen => 'Търсене';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'В радиус $km км';
  }

  @override
  String get searchCriteriaTapToSearch =>
      'Докоснете, за да започнете търсенето';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Смяна на държава?';

  @override
  String countryChangeBody(String country) {
    return 'Превключването към $country ще промени:';
  }

  @override
  String get countryChangeCurrency => 'Валута';

  @override
  String get countryChangeDistance => 'Разстояние';

  @override
  String get countryChangeVolume => 'Обем';

  @override
  String get countryChangePricePerUnit => 'Формат на цената';

  @override
  String get countryChangeNote =>
      'Съществуващите любими и записи за зареждане не се презаписват; само новите записи използват новите единици.';

  @override
  String get countryChangeConfirm => 'Смяна';

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
  String get cacheTtlGroupNetwork => 'Мрежа';

  @override
  String get cacheTtlGroupData => 'Данни';

  @override
  String get cacheTtlGroupGeocoding => 'Геокодиране';

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
  String get reportThisIssue => 'Докладвай проблема';

  @override
  String get reportAlreadySent => 'Вече сте докладвали този проблем.';

  @override
  String get reportConsentTitle => 'Докладване в GitHub?';

  @override
  String get reportConsentBody =>
      'Ще се отвори публичен проблем в GitHub с подробности за грешката по-долу. Не се включват GPS координати, API ключове или лични данни.';

  @override
  String get reportConsentConfirm => 'Отвори GitHub';

  @override
  String get reportConsentCancel => 'Отказ';

  @override
  String get configProfileSection => 'Профил';

  @override
  String get configActiveProfile => 'Активен профил';

  @override
  String get configPreferredFuel => 'Предпочитано гориво';

  @override
  String get configCountry => 'Държава';

  @override
  String get configRouteSegment => 'Участък от маршрута';

  @override
  String get configApiKeysSection => 'API ключове';

  @override
  String get configTankerkoenigKey => 'API ключ за Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Конфигуриран';

  @override
  String get configApiKeyNotSet => 'Не е зададен (демо режим)';

  @override
  String get configApiKeyCommunity => 'По подразбиране (общностен ключ)';

  @override
  String get searchLocationPlaceholder => 'Адрес, пощенски код или град';

  @override
  String get configEvKey => 'API ключ за EV зареждане';

  @override
  String get configEvKeyCustom => 'Персонален ключ';

  @override
  String get configEvKeyShared => 'По подразбиране (споделен)';

  @override
  String get configCloudSyncSection => 'Облачна синхронизация';

  @override
  String get configTankSyncConnected => 'Свързан';

  @override
  String get configTankSyncDisabled => 'Деактивиран';

  @override
  String get configAuthMode => 'Режим на удостоверяване';

  @override
  String get configAuthEmail => 'Имейл (постоянен)';

  @override
  String get configAuthAnonymous => 'Анонимен (само устройство)';

  @override
  String get configDatabase => 'База данни';

  @override
  String get configPrivacySummary => 'Обобщение за поверителност';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Любими, сигнали и игнорирани станции се синхронизират с вашата лична база данни\n• GPS позицията и API ключовете никога не напускат устройството ви\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Всички данни се съхраняват само локално на това устройство\n• Никакви данни не се изпращат към сървър\n• API ключовете са криптирани в защитеното хранилище на устройството';

  @override
  String get configAuthNoteEmail =>
      'Имейл акаунтът позволява достъп от различни устройства';

  @override
  String get configAuthNoteAnonymous =>
      'Анонимен акаунт — данните са обвързани с това устройство';

  @override
  String get configNone => 'Няма';

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
  String get demoModeBannerAction => 'Вземи актуални цени';

  @override
  String get sortDistance => 'Разстояние';

  @override
  String get sortOpen24h => '24ч';

  @override
  String get sortRating => 'Оценка';

  @override
  String get sortPriceDistance => 'Цена/км';

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
  String get routeModeBannerLabel =>
      'Режим на маршрута — разстоянията са по коридора';

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
  String profileSwitchedTo(String profile) {
    return 'Превключено към $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Профил $name е създаден';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Вече съществува профил за $country — редактирайте го вместо това.';
  }

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
  String get evPriceFree => 'Безплатно';

  @override
  String get evPricePayAtLocation => 'Плащане на място';

  @override
  String get evPriceMembership => 'Необходимо е членство';

  @override
  String get evPriceIndicative => 'Ориентировъчна цена';

  @override
  String get evPriceDeclaredByOperator =>
      'Ориентировъчна цена, обявена от оператора — проверете на място';

  @override
  String get evPriceFranceAttribution =>
      'Цени: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Приблизителни цени от OpenChargeMap — оскъдни и може да са непълни.';

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
  String get routePlanningSection => 'Планиране на маршрут';

  @override
  String get routeMinSaving => 'Минимална икономия';

  @override
  String get routeMinSavingOff => 'Изключено';

  @override
  String get routeMinSavingOffCaption =>
      'Показват се всички станции, намерени по маршрута';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Само станции в рамките на $amount от най-евтината по маршрута';
  }

  @override
  String get routeDetourBudget => 'Максимално отклонение';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Показване на станции до $km км от прекия маршрут';
  }

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
  String calculatorDistanceLabel(String unit) {
    return 'Разстояние ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Разход ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Цена на горивото ($unit)';
  }

  @override
  String get calculatorUseMine => 'Използвай';

  @override
  String get calculatorApplied => 'Приложено';

  @override
  String get tripDetails => 'Детайли за пътуването';

  @override
  String get calculatorRoundTrip => 'Отиване и връщане';

  @override
  String get roundTripTotal => 'Отиване и връщане';

  @override
  String get costPerDistance => 'Цена на km';

  @override
  String get costPerMonth => 'Цена на месец';

  @override
  String get calculatorEstimateMonthly => 'Изчисли месечните разходи';

  @override
  String get calculatorTripsPerMonth => 'Пътувания на месец';

  @override
  String get calculatorTripsPerMonthHint => 'напр. 20';

  @override
  String get calculatorReset => 'Нулирай';

  @override
  String get calculatorResultPlaceholder =>
      'Попълнете разстояние, разход и цена, за да видите стойността на пътуването';

  @override
  String get priceHistory => 'Ценова история';

  @override
  String get ignoredStationsLabel => 'Игнорирани';

  @override
  String get ratingsLabel => 'Оценки';

  @override
  String get favoritesDataCache => 'Данни за любими';

  @override
  String get citySearchCache => 'Търсене на град';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'Изтриването на данни не е достъпно в режим Общност. Първо прекъснете връзката или използвайте частна база данни.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count проследени станции';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count конфигурирани';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count скрити станции';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count оценени станции';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Изтрий всички синхронизирани пътувания';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Изтриване на всички синхронизирани пътувания?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Всяко резюме на пътуване и детайлен запис ще бъдат премахнати от сървъра. Локалната история на пътуванията на това устройство няма да бъде засегната.\n\nТова действие не може да бъде отменено.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Изтрий всички';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Всички синхронизирани пътувания са премахнати от сървъра';

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
  String get syncedTrips => 'Пътувания';

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
  String get account => 'Акаунт';

  @override
  String get continueAsGuest => 'Продължи като гост';

  @override
  String get createAccount => 'Създай акаунт';

  @override
  String get signIn => 'Вход';

  @override
  String get upgradeToEmail => 'Създай имейл акаунт';

  @override
  String get savedRoutes => 'Запазени маршрути';

  @override
  String get noSavedRoutes => 'Няма запазени маршрути';

  @override
  String get noSavedRoutesHint =>
      'Търсете по маршрут и го запазете за бърз достъп по-късно.';

  @override
  String get saveRoute => 'Запази маршрута';

  @override
  String get routeName => 'Име на маршрута';

  @override
  String itineraryDeleted(String name) {
    return '$name е изтрит';
  }

  @override
  String loadingRoute(String name) {
    return 'Зареждане на маршрут: $name';
  }

  @override
  String get refreshFailed => 'Обновяването не успя. Моля, опитайте отново.';

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
      'Настройте приложението за няколко бързи стъпки.';

  @override
  String get onboardingApiKeyDescription =>
      'Регистрирайте се за безплатен API ключ или пропуснете, за да разгледате приложението с демо данни.';

  @override
  String get onboardingComplete => 'Готово!';

  @override
  String get onboardingCompleteHint =>
      'Можете да промените тези настройки по всяко време в профила си.';

  @override
  String get onboardingBack => 'Назад';

  @override
  String get onboardingNext => 'Напред';

  @override
  String get onboardingSkip => 'Пропусни';

  @override
  String get onboardingFinish => 'Начало';

  @override
  String crossBorderNearby(String country) {
    return '$country е наблизо';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km км до границата';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Средна цена тук: $price EUR ($count станции)';
  }

  @override
  String get allPricesView => 'Всички цени';

  @override
  String get compactView => 'Компактен';

  @override
  String get switchToAllPricesView => 'Превключи към изглед с всички цени';

  @override
  String get switchToCompactView => 'Превключи към компактен изглед';

  @override
  String get unavailable => 'Н/Д';

  @override
  String get outOfStock => 'Изчерпано';

  @override
  String get gdprTitle => 'Вашата поверителност';

  @override
  String get gdprSubtitle =>
      'Това приложение зачита поверителността ви. Изберете какви данни искате да споделяте. Можете да промените тези настройки по всяко време.';

  @override
  String get gdprLocationTitle => 'Достъп до местоположение';

  @override
  String get gdprLocationDescription =>
      'Координатите ви се изпращат към API за цени на гориво, за да намери близки станции. Данните за местоположение никога не се съхраняват на сървър и не се използват за проследяване.';

  @override
  String get gdprLocationShort =>
      'Намиране на близки горивни станции чрез местоположението ви';

  @override
  String get gdprErrorReportingTitle => 'Докладване на грешки';

  @override
  String get gdprErrorReportingDescription =>
      'Анонимните отчети за сривове помагат за подобряването на приложението. Не се включват лични данни. Отчетите се изпращат само чрез Sentry, когато е конфигуриран.';

  @override
  String get gdprErrorReportingShort =>
      'Изпращане на анонимни отчети за сривове за подобряване на приложението';

  @override
  String get gdprCloudSyncTitle => 'Облачна синхронизация';

  @override
  String get gdprCloudSyncDescription =>
      'Синхронизирайте любими и сигнали между устройствата чрез TankSync. Използва анонимно удостоверяване. Данните ви са криптирани при пренос.';

  @override
  String get gdprCloudSyncShort =>
      'Синхронизиране на любими и сигнали между устройства';

  @override
  String get gdprLegalBasis =>
      'Правно основание: Чл. 6(1)(а) GDPR (Съгласие). Можете да оттеглите съгласието си по всяко време в Настройки.';

  @override
  String get gdprAcceptAll => 'Приеми всички';

  @override
  String get gdprAcceptSelected => 'Приеми избраните';

  @override
  String get gdprSettingsHint =>
      'Можете да промените предпочитанията си за поверителност по всяко време.';

  @override
  String get routeSaved => 'Маршрутът е запазен!';

  @override
  String get routeSaveFailed => 'Неуспешно запазване на маршрута';

  @override
  String get sqlCopied => 'SQL е копиран в клипборда';

  @override
  String get connectionDataCopied => 'Данните за връзка са копирани';

  @override
  String get accountDeleted =>
      'Акаунтът е изтрит. Локалните данни са запазени.';

  @override
  String get switchedToAnonymous => 'Превключено към анонимна сесия';

  @override
  String failedToSwitch(String error) {
    return 'Неуспешно превключване: $error';
  }

  @override
  String get topicUrlCopied => 'URL на темата е копиран';

  @override
  String get testNotificationSent => 'Тестово известие е изпратено!';

  @override
  String get testNotificationFailed =>
      'Неуспешно изпращане на тестово известие';

  @override
  String get pushUpdateFailed =>
      'Неуспешно актуализиране на настройката за push известия';

  @override
  String get connectedAsGuest => 'Свързан като гост';

  @override
  String get accountCreated => 'Акаунтът е създаден!';

  @override
  String get signedIn => 'Влязохте!';

  @override
  String stationHidden(String name) {
    return '$name е скрита';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name е премахната от любими';
  }

  @override
  String invalidApiKey(String error) {
    return 'Невалиден API ключ: $error';
  }

  @override
  String get invalidQrCode => 'Невалиден формат на QR код';

  @override
  String get invalidQrCodeTankSync =>
      'Невалиден QR код — очакван формат TankSync';

  @override
  String get tankSyncConnected => 'TankSync е свързан!';

  @override
  String get syncCompleted =>
      'Синхронизацията е завършена — данните са обновени';

  @override
  String get deviceCodeCopied => 'Кодът на устройството е копиран';

  @override
  String get undo => 'Отмени';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Моля, въведете валиден $length-цифрен $label';
  }

  @override
  String get freshnessAgo => 'преди';

  @override
  String get freshnessStale => 'Остарели';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Актуалност на данните: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Лого на $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Оцени с $count звезди',
      one: 'Оцени с 1 звезда',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Слаба';

  @override
  String get passwordStrengthFair => 'Средна';

  @override
  String get passwordStrengthStrong => 'Силна';

  @override
  String get passwordReqMinLength => 'Поне 8 символа';

  @override
  String get passwordReqUppercase => 'Поне 1 главна буква';

  @override
  String get passwordReqLowercase => 'Поне 1 малка буква';

  @override
  String get passwordReqDigit => 'Поне 1 цифра';

  @override
  String get passwordReqSpecial => 'Поне 1 специален символ';

  @override
  String get passwordTooWeak => 'Паролата не отговаря на всички изисквания';

  @override
  String get brandFilterAll => 'Всички';

  @override
  String get brandFilterNoHighway => 'Без магистрала';

  @override
  String get swipeTutorialMessage =>
      'Плъзнете надясно за навигация, наляво за премахване';

  @override
  String get swipeTutorialDismiss => 'Разбрах';

  @override
  String get alertStatsActive => 'Активни';

  @override
  String get alertStatsToday => 'Днес';

  @override
  String get alertStatsThisWeek => 'Тази седмица';

  @override
  String get privacyDashboardTitle => 'Табло за поверителност';

  @override
  String get privacyDashboardSubtitle =>
      'Преглед, експортиране или изтриване на данните ви';

  @override
  String get privacyDashboardBanner =>
      'Данните ви са ваши. Тук можете да видите всичко, което приложението съхранява, да го експортирате или изтриете.';

  @override
  String get privacyLocalData => 'Данни на това устройство';

  @override
  String get privacyIgnoredStations => 'Игнорирани станции';

  @override
  String get privacyRatings => 'Оценки на станции';

  @override
  String get privacyPriceHistory => 'Станции с история на цените';

  @override
  String get privacyProfiles => 'Профили за търсене';

  @override
  String get privacyItineraries => 'Запазени маршрути';

  @override
  String get privacyCacheEntries => 'Записи в кеша';

  @override
  String get privacyApiKey => 'Съхранен API ключ';

  @override
  String get privacyEvApiKey => 'Съхранен EV API ключ';

  @override
  String get privacyEstimatedSize => 'Приблизително хранилище';

  @override
  String get privacySyncedData => 'Облачна синхронизация (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Облачната синхронизация е деактивирана. Всички данни остават само на това устройство.';

  @override
  String get privacySyncMode => 'Режим на синхронизация';

  @override
  String get privacySyncUserId => 'Потребителски ID';

  @override
  String get privacySyncDescription =>
      'Когато синхронизацията е активирана, любими, сигнали, игнорирани станции и оценки се съхраняват и на сървъра на TankSync.';

  @override
  String get privacyViewServerData => 'Преглед на сървърни данни';

  @override
  String get privacyExportButton => 'Експортирай всички данни като JSON';

  @override
  String get privacyExportSuccess => 'Данните са експортирани в клипборда';

  @override
  String get privacyExportCsvButton => 'Експортирай всички данни като CSV';

  @override
  String get privacyExportCsvSuccess =>
      'CSV данните са експортирани в клипборда';

  @override
  String get savedToDownloadsFolder => 'Запазено в папката Изтегляния';

  @override
  String get privacyDeleteButton => 'Изтрий всички данни';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Копирай журнала с грешки в клипборда ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Запази дневник на грешки ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Изчистване на дневника с грешки';

  @override
  String get privacyErrorLogCleared => 'Дневникът с грешки е изчистен';

  @override
  String get privacyDeleteTitle => 'Изтриване на всички данни?';

  @override
  String get privacyDeleteBody =>
      'Това ще изтрие окончателно:\n\n- Всички любими и данни за станции\n- Всички профили за търсене\n- Всички ценови сигнали\n- Цялата история на цените\n- Всички кеширани данни\n- Вашия API ключ\n- Всички настройки на приложението\n\nПриложението ще се нулира до първоначалното си състояние. Това действие не може да бъде отменено.';

  @override
  String get privacyDeleteConfirm => 'Изтрий всичко';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Не';

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
  String get paymentMethods => 'Начини на плащане';

  @override
  String get paymentMethodCash => 'В брой';

  @override
  String get paymentMethodCard => 'Карта';

  @override
  String get paymentMethodContactless => 'Безконтактно';

  @override
  String get paymentMethodFuelCard => 'Горивна карта';

  @override
  String get paymentMethodApp => 'Приложение';

  @override
  String payWithApp(String app) {
    return 'Плати с $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value л/100 км';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Спрямо плъзгащата средна стойност за последните ви 3 зареждания ($avg л/100 км).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Разход $value л/100 км, $delta спрямо плъзгащата ви средна стойност';
  }

  @override
  String get drivingMode => 'Режим на шофиране';

  @override
  String get drivingExit => 'Изход';

  @override
  String get drivingNearestStation => 'Най-близка';

  @override
  String get drivingTapToUnlock => 'Докоснете за отключване';

  @override
  String get drivingSafetyTitle => 'Предупреждение за безопасност';

  @override
  String get drivingSafetyMessage =>
      'Не работете с приложението по време на шофиране. Спрете на безопасно място преди да взаимодействате с екрана. Шофьорът е отговорен за безопасното управление на превозното средство по всяко време.';

  @override
  String get drivingSafetyAccept => 'Разбирам';

  @override
  String get voiceAnnouncementsTitle => 'Гласови съобщения';

  @override
  String get voiceAnnouncementsDescription =>
      'Обявяване на близки евтини станции по време на шофиране';

  @override
  String get voiceAnnouncementsEnabled => 'Активирай гласови съобщения';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Само под $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance километра напред, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Радиус на съобщенията';

  @override
  String get voiceAnnouncementCooldown => 'Интервал на повторение';

  @override
  String get voiceAnnouncementPriceLimit => 'Maximum price';

  @override
  String get nearestStations => 'Nai-blizki stantsii';

  @override
  String get nearestStationsHint =>
      'Namerete nai-blizkite stantsii chrez vashata aktualna pozitsiya';

  @override
  String get consumptionLogTitle => 'Разход на гориво';

  @override
  String get consumptionLogMenuTitle => 'Журнал на разхода';

  @override
  String get consumptionLogMenuSubtitle =>
      'Проследявайте зарежданията и изчислявайте л/100км';

  @override
  String get consumptionStatsTitle => 'Статистика на разхода';

  @override
  String get addFillUp => 'Добави зареждане';

  @override
  String get noFillUpsTitle => 'Все още няма зареждания';

  @override
  String get noFillUpsSubtitle =>
      'Запишете първото си зареждане, за да започнете да проследявате разхода.';

  @override
  String get fillUpDate => 'Дата';

  @override
  String get liters => 'Литри';

  @override
  String get odometerKm => 'Одометър (км)';

  @override
  String get notesOptional => 'Бележки (по избор)';

  @override
  String get stationPreFilled => 'Станцията е попълнена предварително';

  @override
  String get statAvgConsumption => 'Средно л/100км';

  @override
  String get statAvgCostPerKm => 'Средна цена/км';

  @override
  String get statTotalLiters => 'Общо литри';

  @override
  String get statTotalSpent => 'Общо изразходвано';

  @override
  String get statFillUpCount => 'Зареждания';

  @override
  String get fieldRequired => 'Задължително';

  @override
  String get fieldInvalidNumber => 'Невалидно число';

  @override
  String get carbonDashboardTitle => 'Въглероден показател';

  @override
  String get carbonEmptyTitle => 'Все още няма данни';

  @override
  String get carbonEmptySubtitle =>
      'Записвайте зареждания, за да видите въглеродния си показател.';

  @override
  String get carbonSummaryTotalCost => 'Обща цена';

  @override
  String get carbonSummaryTotalCo2 => 'Общо CO2';

  @override
  String get monthlyCostsTitle => 'Месечни разходи';

  @override
  String get monthlyEmissionsTitle => 'Месечни CO2 емисии';

  @override
  String get vehiclesTitle => 'Моите превозни средства';

  @override
  String get vehiclesMenuTitle => 'Моите превозни средства';

  @override
  String get vehiclesMenuSubtitle =>
      'Батерия, конектори, предпочитания за зареждане';

  @override
  String get vehiclesEmptyMessage =>
      'Добавете колата си, за да филтрирате по конектор и да изчислявате разходите за зареждане.';

  @override
  String get vehiclesWizardTitle => 'Моите превозни средства (по избор)';

  @override
  String get vehiclesWizardSubtitle =>
      'Добавете колата си, за да попълните предварително журнала за разход и да активирате EV филтри за конектори. Можете да пропуснете това и да добавите превозни средства по-късно.';

  @override
  String get vehiclesWizardNoneYet =>
      'Все още не е конфигурирано превозно средство.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Имате $count превозни средства',
      one: 'Имате 1 превозно средство',
    );
    return '$_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Пропуснете, за да завършите настройката — можете да добавяте превозни средства по всяко време от Настройки.';

  @override
  String get fillUpVehicleLabel => 'Превозно средство';

  @override
  String get fillUpVehicleNone => 'Без превозно средство';

  @override
  String get fillUpVehicleRequired => 'Превозното средство е задължително';

  @override
  String get reportScanError => 'Докладвай грешка при сканиране';

  @override
  String get pickStationTitle => 'Изберете станция';

  @override
  String get pickStationHelper =>
      'Започнете зареждането от известна станция, така че цените, марката и вида гориво да се попълнят автоматично.';

  @override
  String get pickStationEmpty =>
      'Все още няма любими станции — добавете от Търсене или Любими, или пропуснете и попълнете ръчно.';

  @override
  String get pickStationSkip => 'Пропусни — добави без станция';

  @override
  String get scanPump => 'Сканирай помпа';

  @override
  String get scanPayment => 'Сканирай QR за плащане';

  @override
  String get qrPaymentBeneficiary => 'Получател';

  @override
  String get qrPaymentAmount => 'Сума';

  @override
  String get qrPaymentEpcTitle => 'SEPA плащане';

  @override
  String get qrPaymentEpcEmpty => 'Няма декодирани полета';

  @override
  String get qrPaymentOpenInBank => 'Отвори в банково приложение';

  @override
  String get qrPaymentLaunchFailed =>
      'Няма налично приложение за отваряне на този код';

  @override
  String get qrPaymentUnknownTitle => 'Неразпознат код';

  @override
  String get qrPaymentCopyRaw => 'Копирай необработения текст';

  @override
  String get qrPaymentCopiedRaw => 'Копирано в клипборда';

  @override
  String get qrPaymentReport => 'Докладвай това сканиране';

  @override
  String get qrPaymentEpcCopied =>
      'Банковите данни са копирани — поставете ги в банковото си приложение';

  @override
  String get qrScannerGuidance => 'Насочете камерата към QR код';

  @override
  String get qrScannerPermissionDenied =>
      'Необходим е достъп до камерата за сканиране на QR кодове.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Достъпът до камерата е отказан. Отворете настройките, за да го разрешите.';

  @override
  String get qrScannerRetryPermission => 'Опитай отново';

  @override
  String get qrScannerOpenSettings => 'Отвори настройки';

  @override
  String get qrScannerTimeout =>
      'Не е открит QR код. Приближете се или опитайте отново.';

  @override
  String get qrScannerRetry => 'Опитай отново';

  @override
  String get torchOn => 'Включи светкавица';

  @override
  String get torchOff => 'Изключи светкавица';

  @override
  String get obdNoAdapter => 'Няма OBD2 адаптер в обхват';

  @override
  String get obdOdometerUnavailable => 'Неуспешно четене на одометъра';

  @override
  String get obdPermissionDenied =>
      'Разрешете Bluetooth в системните настройки';

  @override
  String get obdAdapterUnresponsive =>
      'Адаптерът не отговори — включете запалването и опитайте отново';

  @override
  String get obdPickerTitle => 'Изберете OBD2 адаптер';

  @override
  String get obdPickerScanning => 'Търсене на адаптери...';

  @override
  String get obdPickerConnecting => 'Свързване...';

  @override
  String get themeSettingTitle => 'Тема';

  @override
  String get themeModeLight => 'Светла';

  @override
  String get themeModeDark => 'Тъмна';

  @override
  String get themeModeSystem => 'Следвай системата';

  @override
  String get tripRecordingTitle => 'Запис на пътуване';

  @override
  String get tripSummaryTitle => 'Резюме на пътуването';

  @override
  String get tripMetricDistance => 'Разстояние';

  @override
  String get tripMetricSpeed => 'Скорост';

  @override
  String get tripMetricFuelUsed => 'Изразходвано гориво';

  @override
  String get tripMetricAvgConsumption => 'Средно';

  @override
  String get tripMetricElapsed => 'Изминало';

  @override
  String get tripMetricOdometer => 'Одометър';

  @override
  String get tripStop => 'Спри записа';

  @override
  String get tripPause => 'Пауза';

  @override
  String get tripResume => 'Продължи';

  @override
  String get tripBannerRecording => 'Записване на пътуване';

  @override
  String get tripBannerPaused =>
      'Пътуването е на пауза — докоснете за продължаване';

  @override
  String get navConsumption => 'Разход';

  @override
  String get vehicleBaselineSectionTitle => 'Базова калибровка';

  @override
  String get vehicleBaselineEmpty =>
      'Все още няма примери — започнете OBD2 пътуване, за да научите горивния профил на превозното средство.';

  @override
  String get vehicleBaselineProgress =>
      'Научено от примери в различни ситуации на шофиране.';

  @override
  String get vehicleBaselineReset =>
      'Нулирай базовите стойности за ситуациите на шофиране';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Нулиране на базовите стойности за ситуациите на шофиране?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Това ще изтрие всички научени примери за това превозно средство. Ще се върнете към стандартните стойности при студен старт, докато нови пътувания не попълнят профила.';

  @override
  String get vehicleBaselineShowDetails => 'Покажи разбивка по ситуации';

  @override
  String get vehicleBaselineHideDetails => 'Скрий разбивка по ситуации';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Все още не е открито: $situations. За тези ситуации при шофиране все още има 0 проби, така базовата стойност е непълна.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 адаптер';

  @override
  String get vehicleAdapterEmpty =>
      'Няма сдвоен адаптер. Сдвоете един, за да може приложението да се свързва автоматично следващия път.';

  @override
  String get vehicleAdapterUnnamed => 'Неизвестен адаптер';

  @override
  String get vehicleAdapterPair => 'Сдвои адаптер';

  @override
  String get vehicleAdapterForget => 'Забрави адаптера';

  @override
  String get achievementsTitle => 'Постижения';

  @override
  String get achievementFirstTrip => 'Първо пътуване';

  @override
  String get achievementFirstTripDesc => 'Запишете първото си OBD2 пътуване.';

  @override
  String get achievementFirstFillUp => 'Първо зареждане';

  @override
  String get achievementFirstFillUpDesc => 'Запишете първото си зареждане.';

  @override
  String get achievementTenTrips => '10 пътувания';

  @override
  String get achievementTenTripsDesc => 'Запишете 10 OBD2 пътувания.';

  @override
  String get achievementZeroHarsh => 'Плавен шофьор';

  @override
  String get achievementZeroHarshDesc =>
      'Завършете пътуване от 10 км или повече без рязко спиране или ускоряване.';

  @override
  String get achievementEcoWeek => 'Еко седмица';

  @override
  String get achievementEcoWeekDesc =>
      'Карайте 7 последователни дни с поне едно плавно пътуване всеки ден.';

  @override
  String get achievementPriceWin => 'Ценова победа';

  @override
  String get achievementPriceWinDesc =>
      'Запишете зареждане, което е с 5% или повече под 30-дневната средна цена на станцията.';

  @override
  String get syncBaselinesToggleTitle =>
      'Споделяй научени профили на превозни средства';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Качвайте базови стойности за разход по превозни средства, така че второ устройство да може да ги ползва.';

  @override
  String get obd2StatusConnected => 'OBD2 адаптер: свързан';

  @override
  String get obd2StatusAttempting => 'OBD2 адаптер: свързване';

  @override
  String get obd2StatusUnreachable => 'OBD2 адаптер: недостъпен';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 адаптер: необходимо е разрешение за Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Готов за запис на пътуване.';

  @override
  String get obd2StatusAttemptingBody => 'Свързване на заден план...';

  @override
  String get obd2StatusUnreachableBody =>
      'Адаптерът е извън обхват или вече се използва от друго приложение.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Разрешете Bluetooth в системните настройки за автоматично свързване.';

  @override
  String get obd2StatusNoAdapter => 'Няма сдвоен адаптер';

  @override
  String get obd2StatusForget => 'Забрави адаптера';

  @override
  String get tripHistoryTitle => 'История на пътуванията';

  @override
  String get tripHistoryEmptyTitle => 'Все още няма пътувания';

  @override
  String get tripHistoryEmptySubtitle =>
      'Свържете OBD2 адаптер и запишете пътуване, за да започнете да изграждате историята на шофирането си.';

  @override
  String get tripHistoryUnknownDate => 'Неизвестна дата';

  @override
  String get situationIdle => 'Празен ход';

  @override
  String get situationStopAndGo => 'Спри и тръгни';

  @override
  String get situationUrban => 'Градско';

  @override
  String get situationHighway => 'Магистрала';

  @override
  String get situationDecel => 'Забавяне';

  @override
  String get situationClimbing => 'Изкачване / натоварен';

  @override
  String get situationColdStart => 'Студен старт';

  @override
  String get situationSustainedLoad => 'Продължително натоварване / теглене';

  @override
  String get situationPartialDecel => 'Изкатерване на инерция';

  @override
  String get situationHardAccel => 'Рязко ускорение';

  @override
  String get situationFuelCut => 'Отрязване на гориво — инерция';

  @override
  String get tripSaveAsFillUp => 'Запази като зареждане';

  @override
  String get tripSaveRecording => 'Запази пътуване';

  @override
  String get tripDiscard => 'Отхвърли';

  @override
  String obdOdometerRead(int km) {
    return 'Одометърът е прочетен: $km км';
  }

  @override
  String get vehicleFuelNotSet => 'Не е зададено';

  @override
  String get wizardVehicleTapToEdit => 'Докоснете за редактиране';

  @override
  String get wizardVehicleDefaultBadge => 'По подразбиране';

  @override
  String get wizardProfileChoiceHint =>
      'Изберете как искате да използвате приложението. Можете да промените това по-късно в Настройки.';

  @override
  String get wizardProfileChoiceFooter =>
      'Можете да промените избора си по всяко време от Настройки > Режим на използване.';

  @override
  String get wizardProfileBasicName => 'Основен';

  @override
  String get wizardProfileBasicDescription =>
      'Най-евтино гориво и EV зарядни цени наблизо. Любими и ценови сигнали.';

  @override
  String get wizardProfileMediumName => 'Среден';

  @override
  String get wizardProfileMediumDescription =>
      'Всичко от Основен, плюс ръчно проследяване на зарежданията с гориво и EV.';

  @override
  String get wizardProfileFullName => 'Пълен';

  @override
  String get wizardProfileFullDescription =>
      'Всичко от Среден, плюс автоматичен запис на OBD2 пътувания, резултати за шофиране и карти за лоялност.';

  @override
  String get wizardProfileCustomName => 'Персонален';

  @override
  String get wizardProfileCustomDescription =>
      'Ваша собствена комбинация от функции. Настройте всеки превключвател по-долу.';

  @override
  String get useModeSectionHint =>
      'Пригодете приложението към начина, по който действително го използвате. Избирането на предварително зададен режим активира съответния набор от функции.';

  @override
  String get useModeCustomSettingsDescription =>
      'Вашата комбинация от функции не съответства на нито един предварително зададен режим. Изберете такъв по-горе, за да го презапишете, или продължете да персонализирате отделните функции в секцията по-долу.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Режимът на използване е зададен на $profile.';
  }

  @override
  String get profileDefaultVehicleLabel =>
      'Превозно средство по подразбиране (по избор)';

  @override
  String get profileDefaultVehicleNone => 'Без подразбиране';

  @override
  String get profileFuelFromVehicleHint =>
      'Видът гориво е производен от вашето превозно средство по подразбиране. Изчистете превозното средство, за да изберете гориво директно.';

  @override
  String get consumptionNoVehicleTitle => 'Първо добавете превозно средство';

  @override
  String get consumptionNoVehicleBody =>
      'Зарежданията се приписват на превозно средство. Добавете колата си, за да започнете да записвате разхода.';

  @override
  String get vehicleAdd => 'Добави превозно средство';

  @override
  String get vehicleAddTitle => 'Добавяне на превозно средство';

  @override
  String get vehicleEditTitle => 'Редактиране на превозно средство';

  @override
  String get vehicleDeleteTitle => 'Изтриване на превозно средство?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Премахване на \"$name\" от профилите ви?';
  }

  @override
  String get vehicleNameLabel => 'Име';

  @override
  String get vehicleNameHint => 'напр. Моят Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'С двигател с вътрешно горене';

  @override
  String get vehicleTypeHybrid => 'Хибрид';

  @override
  String get vehicleTypeEv => 'Електрически';

  @override
  String get vehicleEvSectionTitle => 'Електрически';

  @override
  String get vehicleCombustionSectionTitle => 'С вътрешно горене';

  @override
  String get vehicleBatteryLabel => 'Капацитет на батерията (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Макс. мощност на зареждане (kW)';

  @override
  String get vehicleConnectorsLabel => 'Поддържани конектори';

  @override
  String get vehicleMinSocLabel => 'Мин. SoC %';

  @override
  String get vehicleMaxSocLabel => 'Макс. SoC %';

  @override
  String get vehicleTankLabel => 'Капацитет на резервоара (л)';

  @override
  String get vehiclePowerLabel => 'Engine power (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps PS';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Предпочитано гориво';

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
  String get connectorThreePin => '3-пинов';

  @override
  String get evShowOnMap => 'Покажи EV станции';

  @override
  String get evAvailableOnly => 'Само налични';

  @override
  String get evMinPower => 'Мин. мощност';

  @override
  String get evMaxPower => 'Макс. мощност';

  @override
  String get evOperator => 'Оператор';

  @override
  String get evLastUpdate => 'Последна актуализация';

  @override
  String get evStatusAvailable => 'Налично';

  @override
  String get evStatusOccupied => 'Заето';

  @override
  String get evStatusOutOfOrder => 'Извън строя';

  @override
  String get evStatusPartial => 'Частично налично';

  @override
  String get openOnlyFilter => 'Само отворени';

  @override
  String get saveAsDefaults => 'Запази като мои настройки по подразбиране';

  @override
  String get criteriaSavedToProfile =>
      'Запазено като настройки по подразбиране';

  @override
  String get profileNotFound => 'Няма активен профил';

  @override
  String get updatingFavorites => 'Актуализиране на любимите ви...';

  @override
  String get fetchingLatestPrices => 'Извличане на последните цени';

  @override
  String get noDataAvailable => 'Няма данни';

  @override
  String get configAndPrivacy => 'Конфигурация и поверителност';

  @override
  String get searchToSeeMap => 'Търсете, за да видите станциите на картата';

  @override
  String get evPowerAny => 'Всякаква';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Профил';

  @override
  String get sectionLocation => 'Местоположение';

  @override
  String get sectionSetupDataSources => 'Настройка и източници на данни';

  @override
  String get sectionFeaturesUsage => 'Функции и използване';

  @override
  String get sectionAccountSync => 'Акаунт и синхронизация';

  @override
  String get sectionAppearanceWidgets => 'Изглед и джаджи';

  @override
  String get sectionPrivacyData => 'Поверителност и данни';

  @override
  String get sectionAdvancedDeveloper => 'Разширени и разработчик';

  @override
  String get tooltipBack => 'Назад';

  @override
  String get tooltipClose => 'Затвори';

  @override
  String get tooltipShare => 'Споделяне';

  @override
  String get tooltipClearSearch => 'Изчисти полето за търсене';

  @override
  String get minimalDriveInstantConsumption => 'Моментен разход';

  @override
  String get coachingShiftUp => 'Превключи нагоре';

  @override
  String get coachingShiftDown => 'Превключи надолу';

  @override
  String get coachingEasePedal => 'Намали газта';

  @override
  String get coachingVoiceHardAcceleration => 'Внимавайте с акселератора';

  @override
  String get coachingVoiceHarshBraking => 'Опитайте се да спирате по-плавно';

  @override
  String get coachingVoiceShiftUp =>
      'Превключете на по-висока предавка за по-малко гориво';

  @override
  String get coachingVoiceShiftDown =>
      'Превключете на по-ниска предавка, двигателят се претоварва';

  @override
  String get coachingVoiceEasePedal =>
      'Намалете натиска на педала за по-малко гориво';

  @override
  String get coachingVoiceLiftOff =>
      'Пуснете акселератора и се движете по инерция';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Гледайте по-напред и вдигнете крак по-рано';

  @override
  String get coachingVoiceSmoothAccel => 'Ускорявайте по-плавно';

  @override
  String get voiceCoachingSettingTitle => 'Говорим коучинг при шофиране';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Чуйте гласови съвети по време на шофиране — силно ускоряване, рязко спиране и подсказки за предавките';

  @override
  String get tooltipUseGps => 'Използвай GPS местоположение';

  @override
  String get tooltipShowPassword => 'Покажи паролата';

  @override
  String get tooltipHidePassword => 'Скрий паролата';

  @override
  String get evConnectorsLabel => 'Налични конектори';

  @override
  String get evConnectorsNone => 'Няма информация за конектори';

  @override
  String get switchToEmail => 'Превключи към имейл';

  @override
  String get switchToEmailSubtitle =>
      'Запазете данните, добавете вход от други устройства';

  @override
  String get switchToAnonymousAction => 'Превключи към анонимен';

  @override
  String get switchToAnonymousSubtitle =>
      'Запазете локалните данни, използвайте нова анонимна сесия';

  @override
  String get linkDevice => 'Свържи устройство';

  @override
  String get shareDatabase => 'Сподели база данни';

  @override
  String get disconnectAction => 'Прекъсни';

  @override
  String get disconnectSubtitle =>
      'Спрете синхронизацията (локалните данни се запазват)';

  @override
  String get deleteAccountAction => 'Изтрий акаунта';

  @override
  String get deleteAccountSubtitle =>
      'Премахнете всички сървърни данни окончателно';

  @override
  String get localOnly => 'Само локално';

  @override
  String get localOnlySubtitle =>
      'По избор: синхронизирайте любими, сигнали и оценки между устройства';

  @override
  String get setupCloudSync => 'Настрой облачна синхронизация';

  @override
  String get disconnectTitle => 'Прекъсване на TankSync?';

  @override
  String get disconnectBody =>
      'Облачната синхронизация ще бъде деактивирана. Локалните ви данни (любими, сигнали, история) се запазват на това устройство. Сървърните данни не се изтриват.';

  @override
  String get deleteAccountTitle => 'Изтриване на акаунта?';

  @override
  String get deleteAccountBody =>
      'Това окончателно изтрива всички ваши данни от сървъра (любими, сигнали, оценки, маршрути). Локалните данни на това устройство се запазват.\n\nТова не може да бъде отменено.';

  @override
  String get switchToAnonymousTitle => 'Превключване към анонимен?';

  @override
  String get switchToAnonymousBody =>
      'Ще бъдете изписани от имейл акаунта и ще продължите с нова анонимна сесия.\n\nЛокалните ви данни (любими, сигнали) се запазват на това устройство и ще бъдат синхронизирани с новия анонимен акаунт.';

  @override
  String get switchAction => 'Превключи';

  @override
  String get helpBannerCriteria =>
      'Настройките по подразбиране на профила са предварително попълнени. Регулирайте критериите по-долу, за да прецизирате търсенето.';

  @override
  String get helpBannerAlerts =>
      'Задайте ценови праг за станция. Ще получите известие, когато цените паднат под него. Проверките се извършват на всеки 30 минути.';

  @override
  String get helpBannerConsumption =>
      'Записвайте всяко зареждане, за да проследявате реалния разход и CO₂ отпечатък. Плъзнете наляво, за да изтриете запис.';

  @override
  String get helpBannerVehicles =>
      'Добавете превозните си средства, така че зарежданията и предпочитанията за гориво да се попълват правилно по подразбиране. Първото превозно средство става ваше по подразбиране.';

  @override
  String get syncNow => 'Синхронизирай сега';

  @override
  String get onboardingPreferencesTitle => 'Вашите предпочитания';

  @override
  String get onboardingZipHelper => 'Използва се когато GPS е недостъпен';

  @override
  String get onboardingRadiusHelper => 'По-голям радиус = повече резултати';

  @override
  String get onboardingPrivacy =>
      'Тези настройки се съхраняват само на вашето устройство и никога не се споделят.';

  @override
  String get onboardingLandingTitle => 'Начален екран';

  @override
  String get onboardingLandingHint =>
      'Изберете кой екран се отваря при стартиране на приложението.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Оставайте извън приложението — но не го затваряйте.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Отворете Sparkilo веднъж след всяко рестартиране.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple събужда Sparkilo само след като сте го отворили поне веднъж от последното рестартиране на телефона. След това пътуванията ви се записват автоматично.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Не плъзгайте Sparkilo в превключвача на приложения.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      'Принудителното затваряне казва на iOS да спре да рестартира приложението. Пътуванията ви ще спрат да се записват, докато не отворите Sparkilo отново.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Когато iOS поиска местоположение \"Винаги\", моля кажете да.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Резервният механизъм, който записва пътуването ви когато OBD2 адаптерът е бавен, се нуждае от фоново местоположение. Никога не го споделяме.';

  @override
  String get scanReceipt => 'Сканирай касова бележка';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Горивна';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Магистрала';

  @override
  String get ratingModeLocal => 'Локален';

  @override
  String get ratingModePrivate => 'Личен';

  @override
  String get ratingModeShared => 'Споделен';

  @override
  String get ratingDescLocal => 'Оценките се запазват само на това устройство';

  @override
  String get ratingDescPrivate =>
      'Синхронизирани с вашата база данни (не са видими за другите)';

  @override
  String get ratingDescShared =>
      'Видими за всички потребители на вашата база данни';

  @override
  String get errorNoEvApiKey =>
      'API ключът за OpenChargeMap не е конфигуриран. Добавете такъв в Настройки, за да търсите EV зарядни станции.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Доставчикът на данни ($host) предоставя изтекъл или невалиден TLS сертификат. Приложението не може да зарежда данни от този източник, докато доставчикът не го коригира. Свържете се с $host.';
  }

  @override
  String get offlineLabel => 'Офлайн';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed недостъпен. Използва се $current.';
  }

  @override
  String get errorTitleApiKey => 'Необходим е API ключ';

  @override
  String get errorTitleLocation => 'Местоположението е недостъпно';

  @override
  String get errorHintNoStations =>
      'Опитайте да увеличите радиуса на търсене или потърсете на различно място.';

  @override
  String get errorHintApiKey => 'Конфигурирайте API ключа си в Настройки.';

  @override
  String get errorHintConnection =>
      'Проверете интернет връзката си и опитайте отново.';

  @override
  String get errorHintRouting =>
      'Изчисляването на маршрута не успя. Проверете интернет връзката си и опитайте отново.';

  @override
  String get errorHintFallback =>
      'Опитайте отново или търсете по пощенски код / наименование на град.';

  @override
  String get alertsLoadErrorTitle => 'Сигналите не можаха да бъдат заредени';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Неуспешна фонова проверка на сигналите';

  @override
  String get detailsLabel => 'Подробности';

  @override
  String get remove => 'Премахни';

  @override
  String get showKey => 'Покажи ключа';

  @override
  String get hideKey => 'Скрий ключа';

  @override
  String get syncOptionalTitle => 'TankSync е незадължителен';

  @override
  String get syncOptionalDescription =>
      'Приложението работи напълно без облачна синхронизация. TankSync ви позволява да синхронизирате любими, сигнали и оценки между устройства чрез Supabase (наличен безплатен план).';

  @override
  String get syncHowToConnectQuestion => 'Как искате да се свържете?';

  @override
  String get syncCreateOwnTitle => 'Създай собствена база данни';

  @override
  String get syncCreateOwnSubtitle =>
      'Безплатен Supabase проект — ще ви водим стъпка по стъпка';

  @override
  String get syncJoinExistingTitle =>
      'Присъедини се към съществуваща база данни';

  @override
  String get syncJoinExistingSubtitle =>
      'Сканирайте QR код от собственика на базата данни или поставете данни';

  @override
  String get syncChooseAccountType => 'Изберете вид акаунт';

  @override
  String get syncAccountTypeAnonymous => 'Анонимен';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Незабавно, без имейл. Данните са обвързани с това устройство.';

  @override
  String get syncAccountTypeEmail => 'Имейл акаунт';

  @override
  String get syncAccountTypeEmailDesc =>
      'Влизайте от всяко устройство. Възстановете данните, ако телефонът се изгуби.';

  @override
  String get syncHaveAccountSignIn => 'Вече имате акаунт? Влезте';

  @override
  String get syncCreateNewAccount => 'Създай нов акаунт';

  @override
  String get syncTestConnection => 'Тествай връзката';

  @override
  String get syncTestingConnection => 'Тестване...';

  @override
  String get syncConnectButton => 'Свържи';

  @override
  String get syncConnectingButton => 'Свързване...';

  @override
  String get syncDatabaseReady => 'Базата данни е готова!';

  @override
  String get syncDatabaseNeedsSetup => 'Базата данни се нуждае от настройка';

  @override
  String get syncTableStatusOk => 'ОК';

  @override
  String get syncTableStatusMissing => 'Липсва';

  @override
  String get syncSqlEditorInstructions =>
      'Копирайте SQL по-долу и го стартирайте в Supabase SQL Editor (Табло > SQL Editor > Нова заявка > Поставете > Стартирайте)';

  @override
  String get syncCopySqlButton => 'Копирай SQL в клипборда';

  @override
  String get syncRecheckSchemaButton => 'Провери схемата отново';

  @override
  String get syncSchemaOutdated =>
      'Your TankSync schema is outdated — re-run the setup SQL below to enable the latest synced features.';

  @override
  String get syncDoneButton => 'Готово';

  @override
  String syncSignedInAs(String email) {
    return 'Влязохте като $email';
  }

  @override
  String get syncEmailDescription =>
      'Данните ви се синхронизират между всички устройства с този имейл.';

  @override
  String get syncSwitchToAnonymousTitle => 'Превключи към анонимен';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Продължете без имейл, нова анонимна сесия';

  @override
  String get syncGuestDescription => 'Анонимен, без нужда от имейл.';

  @override
  String get syncOrDivider => 'или';

  @override
  String get syncHowToSyncQuestion => 'Как искате да синхронизирате?';

  @override
  String get syncOfflineDescription =>
      'Приложението работи напълно офлайн. Облачната синхронизация е незадължителна.';

  @override
  String get syncModeCommunityTitle => 'Sparkilo общност';

  @override
  String get syncModeCommunitySubtitle =>
      'Споделяйте любими и оценки с всички потребители';

  @override
  String get syncModePrivateTitle => 'Частна база данни';

  @override
  String get syncModePrivateSubtitle =>
      'Ваш собствен Supabase — пълен контрол върху данните';

  @override
  String get syncModeGroupTitle => 'Присъедини се към група';

  @override
  String get syncModeGroupSubtitle =>
      'Споделена база данни за семейство или приятели';

  @override
  String get syncPrivacyShared => 'Споделена';

  @override
  String get syncPrivacyPrivate => 'Частна';

  @override
  String get syncPrivacyGroup => 'Група';

  @override
  String get syncStayOfflineButton => 'Остани офлайн';

  @override
  String get syncSuccessTitle => 'Успешно свързване!';

  @override
  String get syncSuccessDescription =>
      'Данните ви вече ще се синхронизират автоматично.';

  @override
  String get syncWizardTitleConnect => 'Свържи TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Вашата база данни';

  @override
  String get syncSetupTitleJoinGroup => 'Присъединяване към група';

  @override
  String get syncSetupTitleAccount => 'Вашият акаунт';

  @override
  String get syncWizardBack => 'Назад';

  @override
  String get syncWizardNext => 'Напред';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Стъпка $current от $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Създайте Supabase проект';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Докоснете Отвори Supabase по-долу\n2. Създайте безплатен акаунт (ако нямате такъв)\n3. Кликнете New Project\n4. Изберете име и регион\n5. Изчакайте ~2 минути за стартиране';

  @override
  String get syncWizardOpenSupabase => 'Отвори Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Активирайте анонимни входове';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. В таблото на Supabase:\n   Authentication > Providers\n2. Намерете Anonymous Sign-ins\n3. Включете го\n4. Кликнете Save';

  @override
  String get syncWizardOpenAuthSettings => 'Отвори настройки за Auth';

  @override
  String get syncWizardCopyCredentialsTitle => 'Копирайте данните си';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Отидете в Settings > API в таблото\n2. Копирайте Project URL\n3. Копирайте ключа anon public\n4. Поставете ги по-долу';

  @override
  String get syncWizardOpenApiSettings => 'Отвори настройки на API';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Присъединяване към съществуваща база данни';

  @override
  String get syncWizardScanQrCode => 'Сканирай QR код';

  @override
  String get syncWizardAskOwnerQr =>
      'Помолете собственика на базата данни да ви покаже QR кода\n(Настройки > TankSync > Сподели)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Помолете собственика на базата данни да покаже QR кода';

  @override
  String get syncWizardEnterManuallyTitle => 'Въведете ръчно';

  @override
  String get syncWizardOrEnterManually => 'или въведете ръчно';

  @override
  String get syncWizardUrlHelperText =>
      'Интервалите и нови редове се премахват автоматично';

  @override
  String get syncCredentialsPrivateHint =>
      'Въведете данните за Supabase проекта. Можете да ги намерите в таблото под Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL на базата данни';

  @override
  String get syncCredentialsAccessKeyLabel => 'Ключ за достъп';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Имейл';

  @override
  String get authPasswordLabel => 'Парола';

  @override
  String get authConfirmPasswordLabel => 'Потвърди паролата';

  @override
  String get authPleaseEnterEmail => 'Моля, въведете имейл адрес';

  @override
  String get authInvalidEmail => 'Невалиден имейл адрес';

  @override
  String get authPasswordsDoNotMatch => 'Паролите не съвпадат';

  @override
  String get authConnectAnonymously => 'Свържи се анонимно';

  @override
  String get authCreateAccountAndConnect => 'Създай акаунт и свържи';

  @override
  String get authSignInAndConnect => 'Влез и свържи';

  @override
  String get authAnonymousSegment => 'Анонимен';

  @override
  String get authEmailSegment => 'Имейл';

  @override
  String get authAnonymousDescription =>
      'Незабавен достъп, без нужда от имейл. Данните са обвързани с това устройство.';

  @override
  String get authEmailDescription =>
      'Влизайте от всяко устройство. Възстановете данните, ако телефонът се изгуби.';

  @override
  String get authSyncAcrossDevices =>
      'Синхронизирайте данни автоматично между всички ваши устройства.';

  @override
  String get authNewHereCreateAccount => 'Нов потребител? Създайте акаунт';

  @override
  String get linkDeviceScreenTitle => 'Свърза устройство';

  @override
  String get linkDeviceThisDeviceLabel => 'Това устройство';

  @override
  String get linkDeviceShareCodeHint =>
      'Споделете този код с другото си устройство:';

  @override
  String get linkDeviceNotConnected => 'Не е свързано';

  @override
  String get linkDeviceCopyCodeTooltip => 'Копирай код';

  @override
  String get linkDeviceImportSectionTitle => 'Импортиране от друго устройство';

  @override
  String get linkDeviceImportDescription =>
      'Въведете кода на устройство от другото си устройство, за да импортирате неговите любими, сигнали, превозни средства и журнал на разхода. Всяко устройство запазва собствения си профил и настройки по подразбиране.';

  @override
  String get linkDeviceCodeFieldLabel => 'Код на устройството';

  @override
  String get linkDeviceCodeFieldHint => 'Поставете UUID от другото устройство';

  @override
  String get linkDeviceImportButton => 'Импортирай данни';

  @override
  String get linkDeviceHowItWorksTitle => 'Как работи';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. На устройство А: копирайте кода на устройство по-горе\n2. На устройство Б: поставете го в полето Код на устройството\n3. Докоснете Импортирай данни, за да обедините любими, сигнали, превозни средства и журнали за разход\n4. И двете устройства ще имат всички обединени данни\n\nВсяко устройство запазва собствената си анонимна идентичност и профил (предпочитано гориво, превозно средство по подразбиране, начален екран). Данните се обединяват, не се преместват.';

  @override
  String get vehicleSetActive => 'Задай като активно';

  @override
  String get swipeHide => 'Скрий';

  @override
  String get evChargingSection => 'EV зареждане';

  @override
  String get fuelStationsSection => 'Горивни станции';

  @override
  String get yourRating => 'Вашата оценка';

  @override
  String get noStorageUsed => 'Не се използва хранилище';

  @override
  String get aboutReportBug => 'Докладвай грешка / Предложи функция';

  @override
  String get aboutSupportProject => 'Подкрепи проекта';

  @override
  String get aboutSupportDescription =>
      'Това приложение е безплатно, с отворен код и без реклами. Ако го намирате за полезно, обмислете да подкрепите разработчика.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Цените на горивото в Люксембург са регулирани от правителството и са еднакви в цялата страна.';

  @override
  String get luxembourgFuelUnleaded95 => 'Безоловен 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Безоловен 98';

  @override
  String get luxembourgFuelDiesel => 'Дизел';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Регулираните цени на горивото в Люксембург са недостъпни.';

  @override
  String get reportIssueTitle => 'Докладвай проблем';

  @override
  String get enterCorrection => 'Моля, въведете корекцията';

  @override
  String get reportNoBackendAvailable =>
      'Докладът не можа да бъде изпратен: не е конфигурирана услуга за докладване за тази държава. Активирайте TankSync в Настройки, за да изпращате доклади от общността.';

  @override
  String get correctName => 'Правилно наименование на станцията';

  @override
  String get correctAddress => 'Правилен адрес';

  @override
  String get wrongE85Price => 'Грешна цена на E85';

  @override
  String get wrongE98Price => 'Грешна цена на Super 98';

  @override
  String get wrongLpgPrice => 'Грешна цена на LPG';

  @override
  String get wrongStationName => 'Грешно наименование на станцията';

  @override
  String get wrongStationAddress => 'Грешен адрес';

  @override
  String get independentStation => 'Независима станция';

  @override
  String get serviceRemindersSection => 'Напомняния за обслужване';

  @override
  String get serviceRemindersEmpty =>
      'Все още няма напомняния — изберете предварително зададено по-горе.';

  @override
  String get addServiceReminder => 'Добави напомняне';

  @override
  String get serviceReminderPresetOil => 'Масло (15 000 км)';

  @override
  String get serviceReminderPresetOilLabel => 'Смяна на масло';

  @override
  String get serviceReminderPresetTires => 'Гуми (20 000 км)';

  @override
  String get serviceReminderPresetTiresLabel => 'Гуми';

  @override
  String get serviceReminderPresetInspection =>
      'Технически преглед (30 000 км)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Технически преглед';

  @override
  String get serviceReminderLabel => 'Етикет';

  @override
  String get serviceReminderInterval => 'Интервал (км)';

  @override
  String get serviceReminderLastService => 'Последно обслужване';

  @override
  String get serviceReminderMarkDone => 'Отбележи като изпълнено';

  @override
  String get serviceReminderDueTitle => 'Предстои обслужване';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label е просрочено — $kmOver км след интервала.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Регистрирайте се в OPINET за безплатен API ключ';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Регистрирайте се в CNE за безплатен API ключ';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Това ли е колата ви?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — $displacementл, $cylinders-цил., $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Частична информация (офлайн). Можете да редактирате по-долу.';

  @override
  String get vinDecodeError => 'Неуспешно декодиране на VIN';

  @override
  String get vinInvalidFormat => 'Невалиден формат на VIN';

  @override
  String get obd2PauseBannerTitle =>
      'OBD2 връзката е прекъсната — записът е на пауза';

  @override
  String get obd2PauseBannerResume => 'Продължи записа';

  @override
  String get obd2PauseBannerEnd => 'Спри записа';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Запис с GPS — OBD2 се свързва отново';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Recording with GPS — waiting for the OBD2 adapter';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Калибровката на разхода е актуализирана за $vehicleName — точността е подобрена с $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Нулиране на обемната ефективност?';

  @override
  String get veResetConfirmBody =>
      'Това ще отхвърли научената обемна ефективност (η_v) и ще възстанови стойността по подразбиране (0.85). Оценките на горивния поток на ниво пътуване ще се върнат към производствената константа, докато калибраторът не събере нови примери от предстоящи пътувания.';

  @override
  String get alertsStationSectionTitle => 'Станционни сигнали';

  @override
  String get alertsStationAdd => 'Добави станционен сигнал';

  @override
  String get alertsRadiusSectionTitle => 'Радиусни сигнали';

  @override
  String get alertsRadiusAdd => 'Добави радиусен сигнал';

  @override
  String get alertsRadiusEmptyTitle => 'Все още няма радиусни сигнали';

  @override
  String get alertsRadiusEmptyCta => 'Създай радиусен сигнал';

  @override
  String get alertsRadiusCreateTitle => 'Създай радиусен сигнал';

  @override
  String get alertsRadiusLabelHint => 'Етикет (напр. Домашен дизел)';

  @override
  String get alertsRadiusFuelType => 'Вид гориво';

  @override
  String get alertsRadiusThreshold => 'Праг (€/л)';

  @override
  String get alertsRadiusKm => 'Радиус (км)';

  @override
  String get alertsRadiusCenterGps => 'Използвай местоположението ми';

  @override
  String get alertsRadiusCenterPostalCode => 'Пощенски код';

  @override
  String get alertsRadiusSave => 'Запази';

  @override
  String get alertsRadiusCancel => 'Отказ';

  @override
  String get alertsRadiusDeleteConfirm => 'Изтрий радиусния сигнал?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Радиус-сигналът „$name“ е изтрит';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 свързан: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Сдвои OBD2 адаптер';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel поевтиня в близките станции';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount станции са намалили с до $maxDropCents¢ в последния час';
  }

  @override
  String get fillUpSavedSnackbar => 'Зареждането е запазено';

  @override
  String get radiusAlertsEntryTitle => 'Радиусни сигнали и статистики';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Получавайте известия при спад на цените наблизо';

  @override
  String get notFoundTitle => 'Страницата не е намерена';

  @override
  String notFoundBody(String location) {
    return '\"$location\" не е намерен.';
  }

  @override
  String get notFoundHomeButton => 'Начало';

  @override
  String get consumptionTabHiddenNotice =>
      'Разделът Разход е скрит от настройките на профила ви.';

  @override
  String get swipeBetweenTabsHint =>
      'Съвет: плъзнете наляво или надясно, за да превключвате между разделите.';

  @override
  String get discardChangesTitle => 'Отхвърляне на промените?';

  @override
  String get discardChangesBody =>
      'Имате незапазени промени. Излизането сега ще ги отхвърли.';

  @override
  String get discardChangesConfirm => 'Отхвърли';

  @override
  String get discardChangesKeepEditing => 'Продължи редактирането';

  @override
  String get tankSyncSectionSubtitle =>
      'Облачна синхронизация между устройствата ви';

  @override
  String get mapUnavailable => 'Картата е недостъпна';

  @override
  String get routeNameHintExample => 'напр. Париж → Лион';

  @override
  String get priceStatsCurrent => 'Текуща';

  @override
  String get tankerkoenigApiKeyLabel => 'API ключ за Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'API ключ за OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition =>
      'Докоснете, за да актуализирате GPS позицията';

  @override
  String get nameLabel => 'Име';

  @override
  String get obd2ErrorPermissionDenied =>
      'Необходимо е разрешение за Bluetooth, за да се свържете с OBD2 адаптер.';

  @override
  String get obd2ErrorBluetoothOff => 'Включете Bluetooth и опитайте отново.';

  @override
  String get obd2ErrorScanTimeout =>
      'Наблизо не е намерен OBD2 адаптер. Уверете се, че е включен и захранен.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'OBD2 адаптерът не отговори. Включете запалването и опитайте отново.';

  @override
  String get obd2ErrorEngineOff =>
      'No data from the vehicle — start the engine and try again.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'OBD2 адаптерът изпрати неразпознат отговор. Възможно е да е несъвместим — опитайте друг адаптер.';

  @override
  String get obd2ErrorDisconnected =>
      'OBD2 адаптерът се изключи. Свържете се отново и опитайте пак.';

  @override
  String get onboardingExploreDemoData => 'Разгледай с демоданни';

  @override
  String get achievementSmoothDriver => 'Серия от плавно шофиране';

  @override
  String get achievementSmoothDriverDesc =>
      'Карайте 5 пътувания подред с резултат за плавно шофиране 80 или повече.';

  @override
  String get achievementColdStartAware => 'Осъзнат студен старт';

  @override
  String get achievementColdStartAwareDesc =>
      'Поддържайте разхода за студен старт за целия месец под 2% от общото гориво — комбинирайте кратките пътувания.';

  @override
  String get achievementHighwayMaster => 'Магистрален майстор';

  @override
  String get achievementHighwayMasterDesc =>
      'Завършете пътуване от 30+ км с постоянна скорост и резултат за плавно шофиране 90 или повече.';

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
    return '$price $currency (цел: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel поевтиня в близки бензиностанции';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count бензиностанции поевтиняха с до $cents¢ през последния час';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count бензиностанции ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ още $count';
  }

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Целева цена ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Праг ($currency/L)';
  }

  @override
  String get approachOverlaySection =>
      'Наложение при приближаване до бензиностанция';

  @override
  String get approachRadiusLabel => 'Радиус';

  @override
  String approachRadiusCaption(String km) {
    return 'Наложението се увеличава и показва цената, когато сте на по-малко от $km км от бензиностанция';
  }

  @override
  String get approachPriceModeLabel => 'Показване на цена за';

  @override
  String get approachPriceModeNearest => 'Най-близка бензиностанция';

  @override
  String get approachPriceModeCheapestInRadius => 'Най-евтината в радиуса';

  @override
  String get approachMinPollLabel => 'Мин. опресняване';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Долна граница на опресняване на най-близката бензиностанция (по-бързо при скорост, никога по-често от $seconds сек)';
  }

  @override
  String get approachTestSimulateButton =>
      'Тест на наслагване при приближаване';

  @override
  String get approachTestStopButton => 'Спрете теста';

  @override
  String approachTestActiveCaption(String station) {
    return 'Тестът е активен — наслагването показва цената за $station';
  }

  @override
  String get approachTestUnavailable =>
      'Добавете любима станция, за да тествате наслагването при приближаване';

  @override
  String approachStationDistance(String meters) {
    return 'на $meters м';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return '$km km разстояние';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Близост $percent%';
  }

  @override
  String get pipTapToRestore => 'Tap to open the full app';

  @override
  String get authErrorNoNetwork => 'Няма мрежова връзка. Опитайте по-късно.';

  @override
  String get authErrorInvalidCredentials =>
      'Невалиден имейл или парола. Проверете данните си.';

  @override
  String get authErrorUserAlreadyExists =>
      'Този имейл е вече регистриран. Опитайте да влезете.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Моля, проверете имейла си и потвърдете акаунта си първо.';

  @override
  String get authErrorGeneric => 'Входът не успя. Моля, опитайте отново.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Фоново местоположение — само за автоматичен запис';

  @override
  String get autoRecordConsentExplanationTitle => 'За това разрешение';

  @override
  String get autoRecordConsentExplanationBody =>
      'Автоматичният запис се нуждае от фоново местоположение, за да открие кога започвате да шофирате, докато приложението е затворено. Това разрешение се използва само от автоматичния запис — търсенето на станции и центрирането на картата използват отделно разрешение за местоположение на преден план.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Разбрах';

  @override
  String get autoRecordConsentExplanationTooltip => 'Какво означава това?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Докоснете за управление в системните настройки';

  @override
  String get autoRecordSectionTitle => 'Автоматичен запис';

  @override
  String get autoRecordToggleLabel => 'Автоматичен запис на пътувания';

  @override
  String get autoRecordStatusActiveLabel =>
      'Автоматичният запис ще се активира следващия път, когато влезете в колата.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Сдвоете OBD2 адаптер, за да активирате автоматичния запис.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Разрешете фоново местоположение, за да продължи автоматичният запис с изключен екран.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Сдвои адаптер';

  @override
  String get autoRecordSpeedThresholdLabel => 'Начална скорост (км/ч)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Забавяне на запазване след прекъсване (секунди)';

  @override
  String get autoRecordPairedAdapterLabel => 'Сдвоен адаптер';

  @override
  String get autoRecordPairedAdapterNone =>
      'Няма сдвоен адаптер. Сдвоете такъв чрез OBD2 въвеждащия екран.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Разрешено фоново местоположение';

  @override
  String get autoRecordBackgroundLocationRequest => 'Поискай разрешение';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Защо \"Разрешаване по всяко време\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Автоматичният запис предава GPS координати от OBD-II услугата на преден план, докато екранът е изключен, за да остане маршрутът на пътуването точен. Android изисква опцията \"Разрешаване по всяко време\", за да продължи работата след заключване на устройството.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Отвори настройки';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Необходимо е разрешение за местоположение';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Не може да се поиска фоново местоположение';

  @override
  String get autoRecordBadgeClearTooltip => 'Изчисти брояча';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Сдвоете адаптер в секцията по-долу, за да активирате автоматичния запис';

  @override
  String get exportBackupTooltip => 'Експортирай резервно копие';

  @override
  String get exportBackupReady =>
      'Резервното копие е готово — изберете дестинация';

  @override
  String get exportBackupFailed =>
      'Неуспешен експорт на резервно копие — моля, опитайте отново';

  @override
  String get backupExportProgress => 'Изнасяне на резервното копие…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Записан в Downloads като $fileName';
  }

  @override
  String get restoreBackupTooltip => 'Възстанови резервно копие';

  @override
  String get restoreBackupDialogTitle => 'Възстанови резервно копие';

  @override
  String get restoreBackupDialogBody =>
      'Обединяването добавя и актуализира записи от резервното копие и запазва всичко вече на устройството. Замяната изтрива всички текущи данни, след което възстановява само резервното копие — това не може да се отмени.';

  @override
  String get restoreBackupMergeAction => 'Обедини';

  @override
  String get restoreBackupReplaceAction => 'Замени всичко';

  @override
  String restoreBackupSuccess(int count) {
    return 'Резервното копие е възстановено — $count записа импортирани';
  }

  @override
  String get restoreBackupEmpty =>
      'Резервното копие е възстановено — не съдържаше записи';

  @override
  String get restoreBackupCorrupt =>
      'Възстановяването е неуспешно — файлът не е валидно резервно копие на Tankstellen';

  @override
  String get restoreBackupFailed =>
      'Възстановяването е неуспешно — файлът не можа да бъде прочетен';

  @override
  String get backupImportProgress => 'Възстановяване на резервното копие…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Обединени $vehicles превозни средства, $fillUps зареждания, $trips пътувания, $chargingLogs журнала за зарежданe';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Всички данни заменени с $vehicles превозни средства, $fillUps зареждания, $trips пътувания, $chargingLogs журнала за зареждане';
  }

  @override
  String get brokenMapChipVerifying => 'MAP сензорът се проверява...';

  @override
  String get brokenMapChipDisclaimer => 'Подозрителни MAP показания';

  @override
  String get brokenMapSnackbarUnreliable =>
      'MAP сензорът чете неправилно — показанията за гориво може да са с 50–80% по-ниски. Опитайте друг адаптер.';

  @override
  String get brokenMapBannerHardDisable =>
      'MAP сензорът е ненадежден. Показват се средни стойности от зареждания вместо живия горивен поток.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'MAP сензор: потвърден ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'MAP сензор: проверява се ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'MAP сензор: подозрителен ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'MAP сензор: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'MAP сензор: $posterior% ± $margin% (потвърден)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Диагностика на MAP сензора';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Вероятност за повреден MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count наблюдения записани';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Потвърдено чист';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'MAP сензорът на това превозно средство все още не е наблюдаван.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading => 'Блокирани адаптери';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty => 'Няма блокирани адаптери.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — маркиран $percent% повреден';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Изчисти';

  @override
  String get brokenMapRevPromptTitle => 'Натиснете педала';

  @override
  String get brokenMapRevPromptBody =>
      'Натиснете педала за газ за кратко, за да може приложението да провери дали MAP сензорът реагира.';

  @override
  String get brokenMapRevPromptConfirm => 'Готово — натиснах педала';

  @override
  String get calibrationAdvancedTitle => 'Разширена калибровка';

  @override
  String get calibrationDisplacementLabel => 'Обем на двигателя (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel => 'Обемна ефективност (η_v)';

  @override
  String get calibrationAfrLabel => 'Съотношение въздух-гориво (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Плътност на горивото (g/L)';

  @override
  String get calibrationSourceDetected => '(открит от VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(каталог: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(по подразбиране)';

  @override
  String get calibrationSourceManual => '(ръчно)';

  @override
  String get calibrationResetToDetected => 'Нулирай до открита стойност';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (калибрирано, $samples примера)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (обучение, $samples примера)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (по подразбиране — все още няма пълно зареждане)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples проби';
  }

  @override
  String get calibrationResetLearner => 'Нулирай обучението';

  @override
  String get calibrationBasisAtkinson => 'Цикъл Atkinson';

  @override
  String get calibrationBasisVnt => 'VNT дизел + DI';

  @override
  String get calibrationBasisTurboDi => 'Турбо + DI';

  @override
  String get calibrationBasisTurbo => 'Турбо';

  @override
  String get calibrationBasisNaDi => 'Атмосферен + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(каталог: $makeModel — по подразбиране $basis)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Вашият $makeModel е маркиран като дизел, но съответства на каталожен запис за бензин. Докоснете за актуализиране.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Актуализирай';

  @override
  String get consumptionTabFuel => 'Гориво';

  @override
  String get consumptionTabCharging => 'Зареждане';

  @override
  String get noChargingLogsTitle => 'Все още няма записи за зареждане';

  @override
  String get noChargingLogsSubtitle =>
      'Запишете първата си сесия за зареждане, за да започнете да проследявате EUR/100 км и kWh/100 км.';

  @override
  String get addChargingLog => 'Запиши зареждане';

  @override
  String get addChargingLogTitle => 'Запиши сесия за зареждане';

  @override
  String get chargingKwh => 'Енергия (kWh)';

  @override
  String get chargingCost => 'Обща цена';

  @override
  String get chargingTimeMin => 'Време за зареждане (мин)';

  @override
  String get chargingStationName => 'Станция (по избор)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 км';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 км';
  }

  @override
  String get chargingDerivedHelper => 'Необходим е предишен запис за сравнение';

  @override
  String get chargingLogButtonLabel => 'Запиши зареждане';

  @override
  String get chargingCostTrendTitle => 'Тенденция в разходите за зареждане';

  @override
  String get chargingEfficiencyTitle => 'Ефективност (kWh/100 км)';

  @override
  String get chargingChartsEmpty => 'Все още няма достатъчно данни';

  @override
  String get chargingChartsMonthAxis => 'Месец';

  @override
  String get consoFeatureGroupTitle => 'Разход';

  @override
  String get consoFeatureGroupDescription =>
      'Проследявайте разхода — ръчни зареждания или автоматичен OBD2 запис на пътувания.';

  @override
  String get consoModeOff => 'Изкл.';

  @override
  String get consoModeFuel => 'Гориво';

  @override
  String get consoModeFuelAndTrips => 'Гориво + Пътувания';

  @override
  String get consoModeOffDescription =>
      'Без раздел Разход и без секция за настройки на разхода.';

  @override
  String get consoModeFuelDescription =>
      'Само ръчни зареждания. Полезно без OBD2 адаптер.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Добавя автоматичен OBD2 запис на пътувания. Изисква сдвоен адаптер.';

  @override
  String get consoGroupVehicles => 'Превозни средства';

  @override
  String get consoGroupCoaching => 'Коучинг при шофиране';

  @override
  String get consoGroupRewards => 'Награди и спестявания';

  @override
  String get consoGroupTroubleshooting => 'Отстраняване на проблеми';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Точност: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Висока';

  @override
  String get consumptionAccuracyMedium => 'Средна';

  @override
  String get consumptionAccuracyLow => 'Ниска';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Пълна калибрация: зареждания плюс пътувания, записани с OBD2. Стойността L/100 km съответства на реалността с точност до няколко процента.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Зарежданията са фиксирали модела на разход, но все още не е подавано OBD2 пътуване. Запишете едно със свързан OBD2, за да достигнете висока точност.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Само GPS — все още няма зареждания, които да фиксират модела на разход. Добавете няколко пълни зареждания, за да подобрите точността.';

  @override
  String get moreActionsTooltip => 'Още';

  @override
  String get exportBackupMenuLabel => 'Експортирай резервно копие';

  @override
  String get restoreBackupMenuLabel => 'Възстанови резервно копие';

  @override
  String get carbonDashboardMenuLabel => 'Въглероден табло';

  @override
  String get settingsMenuLabel => 'Настройки';

  @override
  String get consumptionStatsPageTitle => 'Статистика на разхода';

  @override
  String get consumptionStatsComparisonTitle => 'Този месец спрямо миналия';

  @override
  String get consumptionStatsTrendsTitle => 'Развитие с времето';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Записвайте зареждания поне два месеца, за да сравните.';

  @override
  String get consumptionStatsPricePerLiter => 'Средна цена/л';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Литри на месец';

  @override
  String get consumptionStatsChartSpend => 'Разходи на месец';

  @override
  String get consumptionStatsChartPricePerLiter => 'Цена на литър';

  @override
  String get consumptionStatsChartConsumption => 'л/100 km на месец';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count частични зареждания чакат пълно зареждане — не са включени в средната стойност',
      one:
          '1 частично зареждане чака пълно зареждане — не е включено в средната стойност',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% от горивото е от авто-корекции — прегледайте записите';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Корекции: +$liters л';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Авто-корекция — докоснете за редактиране';

  @override
  String get fillUpCorrectionEditTitle => 'Редактирай авто-корекцията';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Този запис е генериран автоматично, за да запълни разликата между записаните пътувания и заредено гориво. Коригирайте стойностите, ако знаете действителните данни.';

  @override
  String get fillUpCorrectionDelete => 'Изтрий корекцията';

  @override
  String get fillUpCorrectionStation => 'Наименование на станция (по избор)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Гърция)';

  @override
  String get greeceCommunityApiNotice =>
      'Работи с поддържания от общността fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Румъния)';

  @override
  String get romaniaScrapingNotice =>
      'Работи с pretcarburant.ro (Съвет за конкуренция + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Станции в $country на $km км разстояние — €$price/л по-евтино';
  }

  @override
  String get crossBorderTapToSwitch => 'Докоснете за смяна на държава';

  @override
  String get crossBorderDismissTooltip => 'Затвори';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Отвори източника на данни $source ($license) в браузъра';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Инструменти за разработчици';

  @override
  String get dataAccessTracerExport => 'Export data-access trace';

  @override
  String get dataAccessTracerExportSuccess =>
      'Data-access trace saved to Downloads.';

  @override
  String get dataAccessTracerExportFailure =>
      'Couldn\'t export the data-access trace.';

  @override
  String get dataAccessTracerEmpty =>
      'No data-access events recorded yet — search or open stations first, then export.';

  @override
  String get developerToolsSubtitle =>
      'Диагностика и инструменти за отстраняване на грешки — видими само в режим за разработчици / отстраняване на грешки.';

  @override
  String get developerToolsMenuSubtitle =>
      'Дневник на грешките, тестови сигнали, диагностика';

  @override
  String get developerToolsErrorLogGroupTitle => 'Дневник на грешките';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Запазване на дневника с грешки ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Изчистване на дневника с грешки';

  @override
  String get developerToolsViewErrorLog => 'Преглед на дневника с грешки';

  @override
  String get developerToolsErrorLogEmpty => 'Няма записани следи от грешки.';

  @override
  String get developerToolsAlertsGroupTitle => 'Сигнали и известия';

  @override
  String get developerToolsFireTestNotification =>
      'Изпращане на тестово известие';

  @override
  String get developerToolsTestNotificationTitle => 'Тестово известие';

  @override
  String get developerToolsTestNotificationBody =>
      'Ако можете да прочетете това, известията работят.';

  @override
  String get developerToolsTestNotificationSent =>
      'Тестовото известие е изпратено.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Известията са блокирани — активирайте ги от системните настройки и опитайте отново.';

  @override
  String get developerToolsRunTestAlert =>
      'Изпълнение на тестов поток за сигнали';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Тестовият сигнал е задействан — потокът достави $count известия.';
  }

  @override
  String get developerToolsTestAlertTitle => 'Тестов ценови сигнал';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Синтетично съвпадение: наблизо е намерена станция под вашата цел.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Първо потърсете станции, след което стартирайте тестовото известие, за да може то да отвори реална станция.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Диагностика';

  @override
  String get developerToolsFeatureFlagDump =>
      'Инспектор на флаговете за функции';

  @override
  String get developerToolsFlagOn => 'Вкл.';

  @override
  String get developerToolsFlagOff => 'Изкл.';

  @override
  String get developerToolsClearCaches => 'Изчистване на кешовете';

  @override
  String get developerToolsCachesCleared => 'Кешовете са изчистени.';

  @override
  String get developerToolsCopyDiagnostics => 'Копиране на диагностиката';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Диагностиката е копирана в клипборда.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Информация за компилацията';

  @override
  String get developerToolsBuildVersion => 'Версия на приложението';

  @override
  String get developerToolsBuildChannel => 'Канал на компилацията';

  @override
  String get insightCardTitle => 'Най-разточителни поведения';

  @override
  String get insightEmptyState =>
      'Няма забележими неефективности — продължавайте така!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Двигател над 3000 RPM ($pctTime% от пътуването): изразходвано $liters л';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count рязки ускорения: изразходвано $liters л';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Празен ход ($pctTime% от пътуването): изразходвано $liters л';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% от пътуването';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters л';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Работа на ниска предавка ($minutes мин)';
  }

  @override
  String get lessonAdviceIdling =>
      'Изключвайте двигателя при дълги престои, вместо да го оставяте на празен ход.';

  @override
  String get lessonAdviceHighRpm =>
      'Превключвайте по-рано нагоре, за да държите двигателя извън зоната на високите обороти.';

  @override
  String get lessonAdviceHardAccel =>
      'Натискайте газта плавно — равномерното ускоряване изразходва по-малко гориво.';

  @override
  String get lessonAdviceLowGear =>
      'Превключвайте нагоре по-рано, за да влезе двигателят в по-нисък и по-икономичен режим.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Продължително висока скорост ($pctTime% от пътуването): пропилени $liters л';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Продължително висока скорост ($pctTime% от пътуването)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Над 110 км/ч отпуснете газта – въздушното съпротивление рязко нараства, малко по-бавно спестява много гориво.';

  @override
  String get lessonSmoothDrivingTitle => 'Плавно шофиране – браво!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Това пътуване без резки ускорения и спирания – равномерното шофиране държи разхода нисък.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Пълен газ ($pctTime% от пътуването): похарчено $liters л';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Натискайте педала плавно — при 70% газ достигате скоростта с много по-малко гориво.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Богата смес под товар ($pctTime% от пътуването): похарчено $liters л';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Тежкото, продължително натоварване обогатява сместа — превключвайте рано и намалете при дълги изкачвания.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Изкачване при $gradePercent% наклон ($pctTime% от пътуването): похарчено $liters л';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Натрупайте инерция преди изкачването и подавайте газ плавно — рязкото газуване при изкачване изразходва допълнително гориво.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count спирания и тръгвания: похарчено $liters л';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Предвиждайте трафика и се движете по инерция към спиранията, за да се търкаляте, а не да тръгвате от нула — тръгването от мъртво место е най-прожорливата część от задръстването.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'Mixture looks a little lean — the engine added fuel ($pctTrim% trim) to compensate';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'Mixture looks lean — the engine sustained a large $pctTrim% fuel addition, a possible inefficiency';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'Mixture looks a little rich — the engine pulled fuel ($pctTrim% trim) to compensate';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'Mixture looks rich — the engine sustained a large $pctTrim% fuel cut, a possible inefficiency';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'Engine ran rich under load ($pctShare% of the warm drive) — possible wasted fuel';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Heuristic health signal, not a diagnosis';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'A sustained lean-correcting trim can mean an intake-air leak, a weak fuel supply, or an ageing sensor. If consumption or running quality worsens, a workshop scan can confirm.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'A sustained rich-correcting trim can mean a leaking injector, high fuel pressure, or an over-reading sensor. If consumption or running quality worsens, a workshop scan can confirm.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Running rich under heavy load burns extra fuel. Short-shift and ease off on long pulls so the engine can stay near a stoichiometric mixture.';

  @override
  String get drivingScoreCardTitle => 'Резултат за шофиране';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Съставен резултат от празен ход, рязки ускорения, рязко спиране и работа при високи RPM. Сравнение \'по-добре от X% от минали пътувания\' ще бъде добавено в следващо издание.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Резултат за шофиране $score от 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Празен ход';

  @override
  String get drivingScorePenaltyHardAccel => 'Рязки ускорения';

  @override
  String get drivingScorePenaltyHardBrake => 'Рязко спиране';

  @override
  String get drivingScorePenaltyHighRpm => 'Високи RPM';

  @override
  String get drivingScorePenaltyFullThrottle => 'Пълен газ';

  @override
  String get drivingScoreClassVeryGood => 'Много добро';

  @override
  String get drivingScoreClassGood => 'Добро';

  @override
  String get drivingScoreClassAverage => 'Средно';

  @override
  String get drivingScoreClassBad => 'Нуждае се от подобрение';

  @override
  String get drivingScorePenaltyLugging => 'Претоварване на двигателя';

  @override
  String get drivingScorePenaltySmoothness => 'Некомфортно шофиране';

  @override
  String get drivingScorePenaltyHighSpeed => 'Висока скорост';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Агресивен педал';

  @override
  String get drivingScorePenaltyLambda => 'Богата смес';

  @override
  String get gpsKpiCardTitle => 'GPS ефективност';

  @override
  String get gpsKpiRpa => 'Положително ускорение (RPA)';

  @override
  String get gpsKpiPke => 'Кинетична енергия (PKE)';

  @override
  String get gpsKpiVapos => 'Интензивност на ускорението (VAPOS)';

  @override
  String get gpsKpiCoast => 'Движение по инерция';

  @override
  String get gpsKpiClimbEnergy => 'Енергия за изкачване';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct спрямо вашата ефективна базова стойност';
  }

  @override
  String get drivingTraceCardTitle =>
      'Трасиращ запис за анализ на шофирането (разработчик)';

  @override
  String get drivingTraceCardBody =>
      'Експортирайте GPS KPI, резултата и поуките за това пътуване като JSON, опишете в полето за коментар как реално е протекло шофирането и го споделете обратно, за да могат праговете за стил на шофиране да се калибрират спрямо реални пътувания.';

  @override
  String get drivingTraceExportAction => 'Експортирай трасиращ запис';

  @override
  String get drivingTraceExported =>
      'Трасиращият запис е записан в Downloads — добавете вашата оценка в полето за коментар и го споделете обратно.';

  @override
  String get drivingTraceExportFailed =>
      'Трасиращият запис не можа да се експортира.';

  @override
  String get ecoRouteOption => 'Еко';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters л спестени';
  }

  @override
  String get ecoRouteHint =>
      'По-интелигентно пътуване — предпочита постоянна магистрала пред зигзагообразни преки пътища.';

  @override
  String get favoritesShareAction => 'Сподели';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — любими на $date';
  }

  @override
  String get favoritesShareError =>
      'Неуспешно генериране на изображение за споделяне';

  @override
  String get featureManagementSectionTitle => 'Управление на функции';

  @override
  String get featureManagementSectionSubtitle =>
      'Включвайте или изключвайте отделни функции. Някои функции зависят от други — превключвателите са деактивирани, докато предпоставките не са изпълнени.';

  @override
  String get featureLabel_obd2TripRecording => 'Запис на OBD2 пътувания';

  @override
  String get featureDescription_obd2TripRecording =>
      'Автоматично записване на пътувания чрез OBD2.';

  @override
  String get featureLabel_gamification => 'Геймификация';

  @override
  String get featureDescription_gamification =>
      'Резултати за шофиране и спечелени значки.';

  @override
  String get featureLabel_hapticEcoCoach => 'Хаптичен еко-коуч';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Хаптична обратна връзка в реално време по време на пътуване.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Синхронизация между устройства чрез Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Анализ на разхода';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Раздел за анализ на зарежданията и пътуванията.';

  @override
  String get featureLabel_baselineSync => 'Синхронизация на базови стойности';

  @override
  String get featureDescription_baselineSync =>
      'Синхронизиране на базови стойности за шофиране чрез TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Обединени резултати от търсенето';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Единен списък с резултати, комбиниращ горивни и EV станции.';

  @override
  String get featureLabel_priceAlerts => 'Ценови сигнали';

  @override
  String get featureDescription_priceAlerts =>
      'Известия за спад на цените на базата на зададен праг.';

  @override
  String get featureLabel_priceHistory => 'История на цените';

  @override
  String get featureDescription_priceHistory =>
      '30-дневни графики на цените в детайлите на станциите.';

  @override
  String get featureLabel_routePlanning => 'Планиране на маршрут';

  @override
  String get featureDescription_routePlanning =>
      'Най-евтина спирка по маршрута ви.';

  @override
  String get featureLabel_evCharging => 'EV зареждане';

  @override
  String get featureDescription_evCharging =>
      'Зарядни станции чрез OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Ръководство за хипермайлинг с OSM светофари.';

  @override
  String get featureLabel_gpsTripPath => 'GPS маршрут на пътуването';

  @override
  String get featureDescription_gpsTripPath =>
      'Запазване на GPS точки заедно с всяко пътуване.';

  @override
  String get featureLabel_autoRecord => 'Автоматичен запис';

  @override
  String get featureDescription_autoRecord =>
      'Автоматично стартиране на пътуване, когато OBD2 адаптерът се свързва с движещо се превозно средство.';

  @override
  String get featureLabel_showFuel => 'Покажи горивни станции';

  @override
  String get featureDescription_showFuel =>
      'Показване на резултати с бензинови/дизелови станции в търсенето и на картата.';

  @override
  String get featureLabel_showElectric => 'Покажи зарядни станции';

  @override
  String get featureDescription_showElectric =>
      'Показване на EV зарядни станции в търсенето и на картата.';

  @override
  String get featureLabel_showConsumptionTab => 'Раздел Разход';

  @override
  String get featureDescription_showConsumptionTab =>
      'Показване на раздела за анализ на разхода в долната навигация.';

  @override
  String get featureBlockedEnable_gamification =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureBlockedEnable_baselineSync => 'Първо активирайте TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureBlockedEnable_showFuel => 'Предпоставките не са изпълнени';

  @override
  String get featureBlockedEnable_showElectric =>
      'Предпоставките не са изпълнени';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureLabel_tflitePricePrediction => 'TFLite прогноза на цените';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Модел за прогнозиране на цените на устройството — изводите се изпълняват локално; функциите и прогнозите никога не напускат устройството.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Първо активирайте историята на цените';

  @override
  String get featureLabel_fuelCalculator => 'Калкулатор за гориво';

  @override
  String get featureDescription_fuelCalculator =>
      'Калкулатор за разходи за гориво, достъпен от резултатите от търсенето.';

  @override
  String get featureLabel_carbonDashboard => 'Въглероден показател';

  @override
  String get featureDescription_carbonDashboard =>
      'Табло за CO2 отпечатък, достъпно от раздела Разход.';

  @override
  String get featureLabel_experimentalOemPids => 'Експериментални OEM PIDs';

  @override
  String get featureDescription_experimentalOemPids =>
      'Четене на точните литри в резервоара чрез производствено-специфични PIDs на поддържани адаптери.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Първо активирайте записа на OBD2 пътувания';

  @override
  String get featureLabel_paymentQrScan => 'Сканиране на QR за плащане';

  @override
  String get featureDescription_paymentQrScan =>
      'Четец за QR плащане на екрана с детайли на станцията.';

  @override
  String get featureLabel_communityPriceReports =>
      'Доклади за цени от общността';

  @override
  String get featureDescription_communityPriceReports =>
      'Докладване на цена на станция от екрана с детайли.';

  @override
  String get featureLabel_obd2Optional =>
      'Изискване на OBD2 за запис на пътувания';

  @override
  String get featureDescription_obd2Optional =>
      'Когато е изключено, приложението записва пътувания само с GPS без OBD2 адаптер. Коучингът е ограничен — без моментен L/100 km, по-малко сигнали от двигателя.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR за касова бележка';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Сканирайте отпечатана касова бележка на екрана за добавяне на зареждане, за да попълните автоматично дата, литри, обща сума и станция.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'OCR на дисплея на колонката (експериментално)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Сканирайте дисплея на колонката, за да попълните формуляра. Разпознаването е ненадеждно днес — активирайте само ако искате да тествате.';

  @override
  String get featureLabel_developerPatToken => 'Разработчик: GitHub PAT';

  @override
  String get featureDescription_developerPatToken =>
      'Активира панела за обратна връзка при неуспешен скан, който автоматично създава GitHub issues с Personal Access Token. За опитни потребители/сътрудници.';

  @override
  String get featureLabel_debugMode =>
      'Режим за разработчици / отстраняване на грешки';

  @override
  String get featureDescription_debugMode =>
      'Показва раздел Инструменти за разработчици в настройките с диагностика: експорт на дневника с грешки, тестови известия, изпълнение на тестов поток за сигнали, списък на флаговете за функции, изчистване на кешовете и копиране на диагностиката.';

  @override
  String get featureLabel_approachOverlay => 'Радар за бензиностанции';

  @override
  String get featureDescription_approachOverlay =>
      'Превърнете плаващото табло за пътуване в жив радар за бензиностанции — при приближаване то се превключва в цвета на горивния тип и показва цената.';

  @override
  String get featureLabel_voiceAnnouncements => 'Гласови обявявания';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Обявявайте близки евтини бензиностанции гласово по време на шофиране, за да държите очите си на пътя.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Първо активирайте Радара за бензиностанции';

  @override
  String get featureGroupTitle_finding => 'Намиране и карта';

  @override
  String get featureGroupDescription_finding =>
      'Откъде да заредите гориво или да заредите — търсене, карта, маршрутизация.';

  @override
  String get featureGroupTitle_prices => 'Цени и сигнали';

  @override
  String get featureGroupDescription_prices =>
      'Спадове в цените, история и докладване.';

  @override
  String get featureGroupTitle_radar => 'Радар за бензиностанции';

  @override
  String get featureGroupDescription_radar =>
      'Актуални ценови известия по време на шофиране.';

  @override
  String get featureGroupTitle_sync => 'Синхронизация и резервно копие';

  @override
  String get featureGroupDescription_sync =>
      'Пазете данните си на всички устройства.';

  @override
  String get featureGroupTitle_input => 'Въвеждане и сканиране';

  @override
  String get featureGroupDescription_input =>
      'Помощни инструменти за записване на зареждания.';

  @override
  String get featureGroupTitle_developer => 'Разработчик и експериментални';

  @override
  String get featureGroupDescription_developer =>
      'Инструменти за опитни потребители и сътрудници.';

  @override
  String get feedbackConsentTitle => 'Изпращане на доклад в GitHub?';

  @override
  String get feedbackConsentBody =>
      'Това създава публичен тикет в GitHub хранилището ни с вашата снимка и OCR текста. Не се изпращат лични данни (местоположение, ID на акаунт). Продължавате?';

  @override
  String get feedbackConsentContinue => 'Продължи';

  @override
  String get feedbackConsentCancel => 'Отказ';

  @override
  String get feedbackConsentLater => 'По-късно';

  @override
  String get feedbackTokenSectionTitle =>
      'Обратна връзка за лошо сканиране (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'За автоматично отваряне на GitHub тикет при неуспешно сканиране, поставете GitHub PAT (обхват `public_repo` на хранилището tankstellen). В противен случай ръчното споделяне остава налично.';

  @override
  String get feedbackTokenStatusSet => 'Токенът е конфигуриран';

  @override
  String get feedbackTokenStatusUnset => 'Няма токен';

  @override
  String get feedbackTokenSet => 'Задай';

  @override
  String get feedbackTokenClear => 'Изчисти';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Личен токен за достъп';

  @override
  String get fillUpMultiFuelHint =>
      'This vehicle can use different fuels — log the one you actually pumped';

  @override
  String get fillUpGuidanceTitle => 'Най-добро време за зареждане';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'Текущата цена е сред най-ниските за последните $days дни — добър момент за зареждане.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Цените са близо до максимума за $days дни. Обикновено са по-евтини $window — обмислете изчакване.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Цените растат — обмислете зареждане скоро.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'Днешната цена е около средната за $days дни.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Може да спестите около $amount/л, като изберете правилния момент за зареждане.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Въз основа на $count отчетени цени',
      one: 'Въз основа на 1 отчетена цена',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'в $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'в $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'в друго време';

  @override
  String get fillUpGuidanceWeekday1 => 'понеделници';

  @override
  String get fillUpGuidanceWeekday2 => 'вторници';

  @override
  String get fillUpGuidanceWeekday3 => 'сряди';

  @override
  String get fillUpGuidanceWeekday4 => 'четвъртъци';

  @override
  String get fillUpGuidanceWeekday5 => 'петъци';

  @override
  String get fillUpGuidanceWeekday6 => 'събоди';

  @override
  String get fillUpGuidanceWeekday7 => 'недели';

  @override
  String get fillUpGuidancePartEarlyMorning => 'рано сутринта';

  @override
  String get fillUpGuidancePartMorning => 'сутринта';

  @override
  String get fillUpGuidancePartAfternoon => 'следобед';

  @override
  String get fillUpGuidancePartEvening => 'вечерта';

  @override
  String get fillUpGuidancePartNight => 'нощем';

  @override
  String get fillUpImportPasteLabel => 'Paste text';

  @override
  String get pasteReceiptDialogTitle => 'Paste receipt text';

  @override
  String get pasteReceiptDialogHint =>
      'Paste the text of a fuel receipt — e-mail, SMS, or a shared PDF. The litres, price per litre, fuel grade, total and station are read on-device and used to pre-fill the form. Nothing is sent to a server.';

  @override
  String get pasteReceiptFieldHint => 'Receipt text';

  @override
  String get pasteReceiptParseAction => 'Pre-fill';

  @override
  String get pasteReceiptNoData =>
      'Couldn\'t read any fuel data from that text — check it\'s a fuel receipt and try again.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel => 'Потвърдено от адаптера';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Не съответства на показанието на адаптера';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Вашият запис: $userL л. Адаптерът показва: $adapterL л (разлика от преди/след заснемане на нивото на горивото). Да се използва стойността на адаптера?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine => 'Запази моя запис';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Използвай стойността на адаптера';

  @override
  String get scanReceiptNoData =>
      'Не са намерени данни от касовата бележка — опитайте отново';

  @override
  String get scanReceiptSuccess =>
      'Касовата бележка е сканирана — проверете стойностите. Докоснете Докладвай грешка при сканиране по-долу, ако нещо е грешно.';

  @override
  String scanReceiptFailed(String error) {
    return 'Сканирането не успя: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Дисплеят на помпата не е четим — опитайте отново';

  @override
  String get scanPumpSuccess =>
      'Дисплеят на помпата е сканиран — проверете стойностите.';

  @override
  String get scanPumpGlare =>
      'Твърде много отблясъци по дисплея — опитайте отново под лек ъгъл, за да не са преекспонирани цифрите.';

  @override
  String get scanPumpInconsistent =>
      'Сканираните стойности не се събират — моля, въведете ги ръчно.';

  @override
  String scanPumpFailed(String error) {
    return 'Сканирането на помпата не успя: $error';
  }

  @override
  String get badScanReportTitle => 'Докладвай грешка при сканиране';

  @override
  String get badScanReportTitleReceipt =>
      'Докладвай грешка при сканиране — Касова бележка';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Докладвай грешка при сканиране — Дисплей на помпата';

  @override
  String get pumpScanFailureTitle => 'Дисплеят не е четим';

  @override
  String get pumpScanFailureBody =>
      'Сканирането не успя да прочете дисплея на помпата. Какво искате да направите?';

  @override
  String get pumpScanFailureCorrectManually => 'Коригирай ръчно';

  @override
  String get pumpScanFailureReport => 'Докладвай';

  @override
  String get pumpScanFailureRemove => 'Премахни снимката';

  @override
  String get badScanReportHint =>
      'Ще споделим снимката на касовата бележка и двата набора стойности, за да може следващата версия да научи това оформление.';

  @override
  String get badScanReportShareAction => 'Сподели доклад + снимка';

  @override
  String get badScanReportFieldBrandLayout => 'Оформление на марката';

  @override
  String get badScanReportFieldTotal => 'Общо';

  @override
  String get badScanReportFieldPricePerLiter => 'Цена/л';

  @override
  String get badScanReportFieldStation => 'Станция';

  @override
  String get badScanReportFieldFuel => 'Гориво';

  @override
  String get badScanReportFieldDate => 'Дата';

  @override
  String get badScanReportHeaderField => 'Поле';

  @override
  String get badScanReportHeaderScanned => 'Сканирано';

  @override
  String get badScanReportHeaderYouTyped => 'Въведено от вас';

  @override
  String get badScanReportCreateTicket => 'Създай тикет';

  @override
  String get badScanReportOpenInBrowser => 'Отвори в браузъра';

  @override
  String get badScanReportFallbackToShare =>
      'Изпращането не успя — ръчно споделяне';

  @override
  String get pumpCameraHint =>
      'Подравнете трите цифри от дисплея на колонката в рамката';

  @override
  String get pumpCameraCapture => 'Заснемане';

  @override
  String get pumpCameraPermissionDenied =>
      'Необходим е достъп до камерата за сканиране на дисплея на колонката. Активирайте го в настройките на устройството.';

  @override
  String get pumpCameraError =>
      'Камерата не можа да се стартира. Опитайте отново или въведете стойностите ръчно.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Превключете към хоризонтално оформление';

  @override
  String get pumpCameraOrientationVertical =>
      'Превключете към вертикално оформление';

  @override
  String get pumpCameraGlareWarning =>
      'Прекалено много отблясъци — наклонете леко, за да избегнете отражения';

  @override
  String get pumpCameraAlignHint =>
      'Наредете дисплея в рамката и след това заснемете';

  @override
  String get pumpCameraRotateToLandscape =>
      'Завъртете телефона хоризонтално — дисплеят на помпата е широк, така числата ще се виждат по-едро и изправено';

  @override
  String get fillUpWarningDialogTitle => 'Check this fill-up';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'You picked $chosenFuel, but this vehicle runs on $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'Odometer $entered km is below the previous fill-up\'s $previous km — distance can\'t go backwards.';
  }

  @override
  String get fillUpWarningGoBack => 'Go back and fix';

  @override
  String get fillUpWarningSaveAnyway => 'Save anyway';

  @override
  String get fillUpSectionWhatTitle => 'Какво сте заредили';

  @override
  String get fillUpSectionWhatSubtitle => 'Гориво, количество, цена';

  @override
  String get fillUpSectionWhereTitle => 'Къде сте били';

  @override
  String get fillUpSectionWhereSubtitle => 'Станция, одометър, бележки';

  @override
  String get fillUpImportFromLabel => 'Импортирай от...';

  @override
  String get fillUpImportSheetTitle => 'Импортиране на данни за зареждане';

  @override
  String get fillUpImportReceiptLabel => 'Касова бележка';

  @override
  String get fillUpImportReceiptDescription =>
      'Сканирайте хартиена касова бележка с камерата';

  @override
  String get fillUpImportPumpLabel => 'Дисплей на помпата';

  @override
  String get fillUpImportPumpDescription =>
      'Прочетете Betrag / Preis от LCD на помпата';

  @override
  String get fillUpImportObdLabel => 'OBD-II адаптер';

  @override
  String get fillUpImportObdDescription =>
      'Прочетете одометъра от OBD-II порта по Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Цена на литър';

  @override
  String get vehicleHeaderPlateLabel => 'Регистрационен номер';

  @override
  String get vehicleHeaderUntitled => 'Ново превозно средство';

  @override
  String get vehicleSectionIdentityTitle => 'Идентификация';

  @override
  String get vehicleSectionIdentitySubtitle => 'Наименование и VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Задвижване';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Как се движи превозното средство';

  @override
  String get profileSectionDisplayStations => 'Дисплей и станции';

  @override
  String get profileSectionRegion => 'Регион';

  @override
  String get fuelEfficiencyCardTitle => 'Cost per kilometre by fuel';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Which fuel is actually cheapest to drive on';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Cheapest per km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Pure';

  @override
  String get fuelEfficiencyMixBadge => 'Blend';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Mostly $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Cost/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Total spent';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills',
      one: '1 fill',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyMixedFootnote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mixed tanks counted toward their main fuel',
      one: '1 mixed tank counted toward its main fuel',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Log at least two full tanks per fuel to crown the cheapest.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Tanks are grouped by composition: a tank is pure when one fuel is at least 85% of it, otherwise a blend.';

  @override
  String get fuelNameE5 => 'Super E5';

  @override
  String get fuelNameE10 => 'Super E10';

  @override
  String get fuelNameE98 => 'Super 98';

  @override
  String get fuelNameDiesel => 'Diesel';

  @override
  String get fuelNameDieselPremium => 'Diesel Premium';

  @override
  String get fuelNameE85 => 'E85 Bioethanol';

  @override
  String get fuelNameLpg => 'LPG';

  @override
  String get fuelNameCng => 'CNG';

  @override
  String get fuelNameHydrogen => 'Hydrogen';

  @override
  String get fuelNameElectric => 'Electric';

  @override
  String get calibrationModeLabel => 'Режим на калибровка';

  @override
  String get calibrationModeRule => 'На база правила';

  @override
  String get calibrationModeFuzzy => 'Нечеткa';

  @override
  String get calibrationModeTooltip =>
      'Режимът на база правила приписва всеки пример за шофиране точно на една ситуация. Нечеткият го разпределя между всички ситуации според степента на съответствие — по-плавен около 60 км/ч или при промяна на наклони, но по-бавно попълва всички кофи.';

  @override
  String get profileGamificationToggleTitle =>
      'Показвай постижения и резултати';

  @override
  String get profileGamificationToggleSubtitle =>
      'При изключване, значките, резултатите и иконите за трофеи са скрити навсякъде в приложението.';

  @override
  String get coachingGpsLiftOff => 'Освободи газта';

  @override
  String get coachingGpsAnticipateBrake => 'Предвиди';

  @override
  String get coachingGpsSmoothAccel => 'Плавно ускорение';

  @override
  String get gpsDiagnosticsTitle => 'GPS диагностика на вземане на проби';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps прекъсвания',
      one: '1 прекъсване',
      zero: 'без прекъсвания',
    );
    return '$count проби · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Медианен интервал: $ms мс';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Заснето по време на записа за проверка на GPS честотата при заспал телефон.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Най-голяма пропаст: $seconds с';
  }

  @override
  String get gpsLifecycleResumed => 'Възобновено';

  @override
  String get gpsLifecyclePaused => 'На пауза';

  @override
  String get gpsLifecycleInactive => 'Неактивно';

  @override
  String get gpsKpiVerdictGood => 'Efficient';

  @override
  String get gpsKpiVerdictModerate => 'Moderate';

  @override
  String get gpsKpiVerdictAggressive => 'Aggressive';

  @override
  String get gpsKpiInterpretationGood =>
      'Smooth, energy-light driving — this is what efficient looks like.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Fairly typical driving — a little smoother on the throttle would save more.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Energy-heavy driving — easing off the accelerator and coasting more would cut fuel use.';

  @override
  String get gpsMatrixMaturityCold => 'Студена';

  @override
  String get gpsMatrixMaturityWarming => 'Загрява се';

  @override
  String get gpsMatrixMaturityConverged => 'Сходяща';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'GPS матрицата още се загрява ($count прецизирания засега). Оценките са временни.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'GPS матрицата се сходи ($count зареждания). Оценките са използваеми с възможно отклонение от няколко %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'GPS матрицата се сходи ($count зареждания). Оценките са в рамките на ~2 % от реалния разход.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS оценка (~) — без горивен сензор за това пътуване. Стойността е изчислена от скоростта и калибровката на превозното средство; точността се подобрява с натрупването на данни.';

  @override
  String get gpsRoadUseCardTitle => 'How you used the road';

  @override
  String get gpsRoadUseSpeedSection => 'Where you spent your time';

  @override
  String get gpsRoadUseSpeedIdle => 'Stopped (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Town (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Cruise (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Fast (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'How you moved';

  @override
  String get gpsRoadUsePhaseAccel => 'Accelerating';

  @override
  String get gpsRoadUsePhaseSteady => 'Holding speed';

  @override
  String get gpsRoadUsePhaseCoast => 'Coasting';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct%';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Lots of coasting — letting the car roll instead of braking saves fuel. Nice.';

  @override
  String get gpsRoadUseSource => 'From your GPS track';

  @override
  String get hapticEcoCoachSectionTitle => 'Шофиране';

  @override
  String get hapticEcoCoachSettingTitle => 'Еко-коучинг в реално време';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Леко хаптично + екранен съвет при рязко газуване по магистрала';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'По-леко с педала — инерцията спестява повече';

  @override
  String semanticsNavigateTo(String name) {
    return 'Навигация до $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Премахни $name от любими';
  }

  @override
  String get showOnMapSemanticLabel => 'Показване на станциите на картата';

  @override
  String get searchResultsSemanticLabel => 'Резултати от търсенето';

  @override
  String get searchCriteriaSemanticLabel =>
      'Обобщение на критериите за търсене. Докоснете за редактиране.';

  @override
  String get noFavoritesSemanticLabel =>
      'Все още няма любими. Докоснете звездата на станция, за да я запазите като любима.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Станцията е отворена',
      'false': 'Станцията е затворена',
      'other': 'Станцията е затворена',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Държава $name, избрана',
      'false': 'Държава $name',
      'other': 'Държава $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Език $name, избрано',
      'false': 'Език $name',
      'other': 'Език $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Сортиране по $option, избрано',
      'false': 'Сортиране по $option',
      'other': 'Сортиране по $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Гориво $type, избрано',
      'false': 'Гориво $type',
      'other': 'Гориво $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Зарядна станция $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Щит за поверителност с капка гориво';

  @override
  String get globeIllustrationSemantic => 'Глобус с маркери за бензиностанции';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Колонка за гориво с ценови индикатор';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, източник на данни: $provider, $keyRequirement, видове гориво: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Изисква се API ключ';

  @override
  String get countryInfoNoKeyNeeded => 'Безплатно, без ключ';

  @override
  String countryInfoDataSource(String provider) {
    return 'Данни: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Видове гориво: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Демо';

  @override
  String get anonKeyLabel => 'Анонимен ключ';

  @override
  String get anonKeyHideTooltip => 'Скрий ключа';

  @override
  String get anonKeyShowTooltip => 'Покажи ключа за проверка';

  @override
  String anonKeyTooLong(int length) {
    return 'Ключът е твърде дълъг ($length символа) — проверете за допълнителен текст';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Ключът изглежда правилен ($length символа)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Ключът трябва да е JWT (заглавие.полезен товар.подпис)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Ключът може да е съкратен ($length от ~208 очаквани символа)';
  }

  @override
  String get anonKeyExceedsMax => 'Ключът надвишава максималната дължина';

  @override
  String get qrShareTitle => 'Споделете базата данни';

  @override
  String get qrShareSubtitle =>
      'Другите могат да сканират този QR код за свързване';

  @override
  String get qrShareCopyAsText => 'Копирай като текст';

  @override
  String get authInfoTitle => 'Защо да създадете акаунт?';

  @override
  String get authInfoBenefit1 =>
      '• Синхронизирайте любими, сигнали и запазени маршрути между устройства';

  @override
  String get authInfoBenefit2 =>
      '• Подгответе маршрут на телефона, използвайте го в колата';

  @override
  String get authInfoBenefit3 =>
      '• Никакви данни не се споделят с трети страни';

  @override
  String get authInfoBenefit4 =>
      '• Можете да изтриете акаунта си по всяко време';

  @override
  String get privacyLocalDataEmpty =>
      'Все още не е запазено нищо. Добавете любима или задайте ценови сигнал, за да видите записи тук.';

  @override
  String get privacyHideEmptyRows => 'Скрий празните редове';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Покажи $count празни реда',
      one: 'Покажи $count празен ред',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Настройка на API ключ (по избор)';

  @override
  String get apiKeySetupDescription =>
      'Регистрирайте се за безплатен API ключ или пропуснете, за да разгледате приложението с демо данни.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Регистрация в $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'С въвеждането на API ключ приемате условията на $provider. Преразпределението на данни е забранено.';
  }

  @override
  String get calculatorDistanceHint => 'напр. 150';

  @override
  String get calculatorConsumptionHint => 'напр. 7.0';

  @override
  String get calculatorPriceHint => 'напр. 1.899';

  @override
  String get routeStrategyLabel => 'Стратегия:';

  @override
  String get routeStrategyUniform => 'Равномерна';

  @override
  String get routeStrategyBalanced => 'Балансирана';

  @override
  String get glideCoachBetaTitle => 'Glide-coach бета (експериментален)';

  @override
  String get glideCoachBetaSubtitle =>
      'Лека хаптика при забавяне преди червена светлина. Изключено по подразбиране — риск от разсейване.';

  @override
  String get consentSyncTripsTitle => 'Синхронизиране на записи на пътувания';

  @override
  String get consentSyncTripsSubtitle =>
      'Резервно копие на OBD2 + GPS пътувания в TankSync. Между устройства, по избор.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Активирайте облачната синхронизация по-горе за резервно копие на пътуванията.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Влезте с имейл акаунт, за да синхронизирате пътуванията между устройства.';

  @override
  String get consentHideDetails => 'Скрий подробностите';

  @override
  String get consentShowDetails => 'Покажи подробностите';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Невалидна връзка';

  @override
  String invalidLinkBody(String path) {
    return 'Връзката \"$path\" не е валидна.';
  }

  @override
  String get home => 'Начало';

  @override
  String get accelBrakeCardTitle => 'Ускоряване и спиране';

  @override
  String get accelBrakeHardAccel => 'Рязко ускорявания';

  @override
  String get accelBrakeHardBrake => 'Рязко спиране';

  @override
  String get accelBrakeSharpCorner => 'Остри завои';

  @override
  String get accelBrakeSource => 'От сензорите за движение на телефона';

  @override
  String lessonHardBrake(String count) {
    return '$count рязко спиране';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Предвиждайте спиранията и вдигайте крак по-рано — рязкото спиране пропилява горивото, похарчено за набиране на скорост.';

  @override
  String lessonSharpCornering(String count) {
    return '$count остри завои';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Намалете преди завоя, не в него — рязкото вземане на завои губи скоростта, която после трябва да наберете отново.';

  @override
  String get locationConsentTitle => 'Достъп до местоположението';

  @override
  String get locationConsentSubtitle =>
      'Това приложение иска да използва местоположението ви, за да намери бензиностанции близо до вас.';

  @override
  String get locationConsentWhatHappens =>
      'Какво се случва с данните за местоположението ви:';

  @override
  String get locationConsentBulletApi =>
      'Координатите ви се изпращат към API-то за цени на горивата, за да се намерят близки бензиностанции.';

  @override
  String get locationConsentBulletNoServer =>
      'Местоположението ви не се съхранява на нито един сървър — няма сървър.';

  @override
  String get locationConsentBulletNoTracking =>
      'Данните за местоположението не се използват за реклама, анализ или проследяване.';

  @override
  String get locationConsentRevoke =>
      'Можете да отмените достъпа до местоположението по всяко време в системните настройки. Като алтернатива търсете по пощенски код.';

  @override
  String get locationConsentLegalBasis =>
      'Правно основание: чл. 6, пар. 1, б. „а“ от ОРЗД (съгласие)';

  @override
  String get locationConsentDecline => 'Откажи';

  @override
  String get locationConsentAccept => 'Приеми';

  @override
  String get loyaltySettingsTitle => 'Карти за горивни клубове';

  @override
  String get loyaltySettingsSubtitle =>
      'Прилагайте отстъпката за лоялност към показаните цени';

  @override
  String get loyaltyMenuTitle => 'Карти за горивни клубове';

  @override
  String get loyaltyMenuSubtitle =>
      'Прилагайте отстъпки на литър от Total, Aral, Shell, ...';

  @override
  String get loyaltyAddCard => 'Добави карта';

  @override
  String get loyaltyAddCardSheetTitle => 'Добавяне на карта за горивен клуб';

  @override
  String get loyaltyBrandLabel => 'Марка';

  @override
  String get loyaltyCardLabelLabel => 'Етикет (по избор)';

  @override
  String get loyaltyDiscountLabel => 'Отстъпка (на литър)';

  @override
  String get loyaltyDiscountInvalid => 'Въведете положително число';

  @override
  String get loyaltyDeleteConfirmTitle => 'Изтриване на картата?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Тази карта ще спре да прилага отстъпката си.';

  @override
  String get loyaltyEmptyTitle => 'Все още няма карти за горивни клубове';

  @override
  String get loyaltyEmptyBody =>
      'Добавете карта, за да прилагате автоматично отстъпката на литър към съответстващите станции.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Открито постепенно нарастване на RPM на празен ход';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'RPM на празен ход е нараснал с $percent% в последните ви $tripCount пътувания. Възможен ранен признак на запушен въздушен филтър или отклонение на сензор.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Възможно ограничение на всмукването';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Горивният разход при крейсерска скорост е намалял с $percent% в последните ви $tripCount пътувания. Възможен признак на запушен въздушен филтър или ограничено всмукване — струва си проверка.';
  }

  @override
  String get maintenanceActionDismiss => 'Затвори';

  @override
  String get maintenanceActionSnooze => 'Отложи за 30 дни';

  @override
  String get consumptionMonthlyInsightsTitle => 'Този месец спрямо миналия';

  @override
  String get consumptionMonthlyTripsLabel => 'Пътувания';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Време на шофиране';

  @override
  String get consumptionMonthlyDistanceLabel => 'Разстояние';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Среден разход';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Необходими са поне 3 пътувания на месец за сравнение';

  @override
  String get consumptionMonthlyClimbLabel => 'Изкачено';

  @override
  String get obd2CapabilitySectionTitle => 'Възможности на адаптера';

  @override
  String get obd2CapabilityStandardOnly => 'Стандартен';

  @override
  String get obd2CapabilityOemPids => 'OEM PIDs';

  @override
  String get obd2CapabilityFullCan => 'Пълен CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'За точни литри в резервоара на Peugeot/Citroën, приложението поддържа OBDLink MX+/LX/CX (STN чип).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'OBD2 диагностичният overlay е активиран';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'OBD2 диагностичният overlay е деактивиран';

  @override
  String get obd2DebugOverlayClearButton => 'Изчисти';

  @override
  String get obd2DebugOverlayCloseButton => 'Затвори';

  @override
  String get obd2DebugOverlayTitle => 'OBD2 следи';

  @override
  String get obd2DiagnosticShareLabel => 'Споделяне на диагностичния дневник';

  @override
  String get obd2DebugLoggingTitle => 'OBD2 дебъг журналиране';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Записвайте всяка OBD2 сесия — свързване, handshake, пропуски в данните и повторни свързвания — в експортируем XML журнал. Изключено по подразбиране.';

  @override
  String get obd2DebugSessionShareLabel =>
      'Споделяне на журнала на OBD2 сесията';

  @override
  String get obd2DiagnosticsTitle => 'Комуникационно здраве на OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops прекъсвания',
      one: '1 прекъсване',
      zero: 'без прекъсвания',
    );
    return '$percent% завършено · $duty% натоварване · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Адаптер';

  @override
  String get obd2DiagnosticsConnectionSection => 'Жизнен цикъл на връзката';

  @override
  String get obd2DiagnosticsPidSection => 'Резултати по PID';

  @override
  String get obd2DiagnosticsReconnectSection => 'Reconnect telemetry';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts reconnect attempts · $successes ok · $transitions transitions · $disconnects typed drops';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'GPS-only fallback activated this session.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Здраве на планировчика';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Пълнота';

  @override
  String get obd2DiagnosticsSupportSection => 'Открити поддържани PID';

  @override
  String get obd2DiagnosticsFuelSection => 'Обобщение за горивния слой';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · протокол $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts опита · $successes успешни · $drops прекъсвания · време за свързване p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Преповторни връзки: $silent тихи · $visible видими';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz такт · $skips пропуска при натиск · $demotions понижения';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Динамичният слой е изгладнял — RPM / скоростта паднаха под прага на управителя.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Обща $percent% · активно натоварване $duty%';
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
    return '$supported поддържани · $unsupported неподдържани · $unknown неизвестни';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Подозрителни $suspicious от $total проби';
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
    return '$pid: $polled заявки · $ok ok · $noData ND · $timeout TO · $error грешки · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection =>
      'Протокол за инициализация на донгъла';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Протокол $protocol · $start · фърмуер $firmware · $tier · $pids PID';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'топло';

  @override
  String get obd2DiagnosticsInitCold => 'студено';

  @override
  String get obd2HealthCopyInitTranscript =>
      'Копирай само протокола за инициализация';

  @override
  String get obd2DiagnosticsEmpty =>
      'Все още няма записана OBD2 сесия — свържете адаптер и запишете пътуване с включен режим на разработчик.';

  @override
  String get obd2DiagnosticsExplain =>
      'Събрано по време на запис за отстраняване на грешки в комуникацията донгъл↔приложение — събира се само в режим на разработчик.';

  @override
  String get obd2HealthScreenTitle => 'Комуникационно здраве на OBD2';

  @override
  String get obd2HealthNavLabel => 'Комуникационно здраве на OBD2';

  @override
  String get obd2HealthLiveSection => 'Активна сесия';

  @override
  String get obd2HealthHistorySection => 'Последни сесии';

  @override
  String get obd2HealthCopyJson => 'Копирай като JSON';

  @override
  String get obd2HealthCopied => 'OBD2 диагностиката е копирана в клипборда.';

  @override
  String get obd2HealthDownloadJson => 'Download as JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Download init transcript only';

  @override
  String get obd2HealthDownloadError => 'Couldn\'t save the diagnostics file';

  @override
  String get obd2TestAdapterLabel => 'Adapter to test';

  @override
  String get obd2TestAdapterScanOption => 'Scan for adapter';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Connect to $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Стартирай тест на адаптера';

  @override
  String get obd2TestRunButton => 'Стартирай тест на адаптера';

  @override
  String get obd2TestRunPassed => 'Тестът на адаптера е успешен';

  @override
  String get obd2TestRunFailed => 'Тестът на адаптера е неуспешен';

  @override
  String get obd2TestRunEngineOff =>
      'Adapter OK — engine off; start the engine to read live data';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed от $total стъпки OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Спрете активния запис преди да стартирате теста на адаптера.';

  @override
  String get obd2TestStepScan => 'Сканиране за адаптер';

  @override
  String get obd2TestStepConnect => 'Свързване и инициализация';

  @override
  String get obd2TestStepInfo => 'Информация за адаптера';

  @override
  String get obd2TestStepSupportedPids => 'Поддържани PID';

  @override
  String get obd2TestStepSampleReads => 'Примерни четения';

  @override
  String get obd2TestStepReconnect => 'Тест за повторно свързване';

  @override
  String get obd2TestStepDisconnect => 'Прекъсване';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Изтекло време';

  @override
  String get obd2TestStatusGarbage => 'Нечетлив отговор';

  @override
  String get obd2TestStatusNoResponse => 'Без отговор';

  @override
  String get obd2TestStatusFail => 'Неуспешно';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'unknown — defaulting to BLE';

  @override
  String get obd2HealthConnectAttemptsSection => 'Recent connect attempts';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'No connect attempts recorded yet.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Download connect trace';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Download all connect traces';

  @override
  String get obd2HealthConnectOrigin => 'Origin';

  @override
  String get obd2HealthConnectTransport => 'Transport';

  @override
  String get obd2HealthConnectOutcome => 'Outcome';

  @override
  String get obd2HealthConnectScanList => 'Scanned devices';

  @override
  String get obd2HealthConnectSteps => 'Steps';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Unknown adapter';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Не може да се достигне до \'$adapterName\' — изберете друг адаптер';
  }

  @override
  String get ocrTesterTitle => 'OCR тестер';

  @override
  String get ocrTesterNavLabel => 'OCR тестер';

  @override
  String get ocrTesterExplain =>
      'Изпълнете OCR конвейера за помпа/касова бележка върху избрана снимка и прегледайте всяка стъпка — достъпно само в режим на разработчик.';

  @override
  String get ocrTesterModePump => 'Помпа';

  @override
  String get ocrTesterModeReceipt => 'Касова бележка';

  @override
  String get ocrTesterCapture => 'Снимай';

  @override
  String get ocrTesterPickImage => 'Избери изображение';

  @override
  String get ocrTesterRun => 'Стартирай';

  @override
  String get ocrTesterCountry => 'Държава';

  @override
  String get ocrTesterCountryNone => 'По подразбиране (без профил)';

  @override
  String get ocrTesterNoImage =>
      'Изберете или заснемете изображение, след което натиснете Стартирай.';

  @override
  String get ocrTesterRunning => 'Изпълнява се OCR…';

  @override
  String get ocrTesterNoResult => 'OCR не даде четлив резултат.';

  @override
  String get ocrTesterOverlaySection => 'Блоков преглед';

  @override
  String get ocrTesterStepsSection => 'Стъпки на конвейера';

  @override
  String get ocrTesterLegendLabel => 'Етикет';

  @override
  String get ocrTesterLegendNumeric => 'Числово';

  @override
  String get ocrTesterLegendNoise => 'Шум';

  @override
  String get ocrTesterLegendDerived => 'Изведено';

  @override
  String get ocrTesterStageGlare => 'Снимане / отблясъци';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Класификация';

  @override
  String get ocrTesterStageAssemble => 'Сглобяване';

  @override
  String get ocrTesterStageAnchor => 'Котва';

  @override
  String get ocrTesterStageFallback => 'Резервна стъпка';

  @override
  String get ocrTesterStageCrossCheck => 'Кръстосана проверка';

  @override
  String get ocrTesterStageConfidence => 'Достоверност';

  @override
  String get ocrTesterStageGate => 'Порта';

  @override
  String get ocrTesterStageBrand => 'Марка';

  @override
  String get ocrTesterStageOverrides => 'Замени';

  @override
  String get ocrTesterStageReconcile => 'Изравняване';

  @override
  String get ocrTesterStageResult => 'Резултат';

  @override
  String get ocrTesterChipRead => 'ПРОЧЕТЕНО';

  @override
  String get ocrTesterChipDerived => 'ИЗВЕДЕНО';

  @override
  String get ocrTesterGateAccepted => 'Прието';

  @override
  String get ocrTesterGateRejected => 'Отхвърлено';

  @override
  String get ocrTesterFallbackBanner =>
      'Едно поле е възстановено чрез резервна стъпка — проверете го.';

  @override
  String get ocrTesterStageNoData => 'Стъпката не е изпълнена.';

  @override
  String get ocrTesterCopyJson => 'Копирай като JSON';

  @override
  String get ocrTesterExportPackage => 'Експортирай пакет';

  @override
  String get ocrTesterCopied => 'OCR проследяването е копирано в клипборда.';

  @override
  String get ocrTesterExported => 'OCR пакетът е записан в папката Downloads.';

  @override
  String get ocrTesterSaveFixture => 'Запази като fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture е записан в папката Downloads. Преместете го в test/fixtures и стартирайте tool/promote_ocr_fixture.dart.';

  @override
  String get onboardingObd2StepTitle => 'Свържете OBD2 адаптера';

  @override
  String get onboardingObd2StepBody =>
      'Включете OBD2 адаптера в порта на автомобила и включете запалването. Ще прочетем VIN и ще попълним данните за двигателя вместо вас.';

  @override
  String get onboardingObd2ConnectButton => 'Свържи адаптер';

  @override
  String get onboardingObd2SkipButton => 'Може би по-късно';

  @override
  String get onboardingObd2ReadingVin => 'Четене на VIN...';

  @override
  String get onboardingObd2VinReadFailed =>
      'Неуспешно четене на VIN — въведете ръчно';

  @override
  String get onboardingObd2ConnectFailed =>
      'Неуспешно свързване с адаптера. Можете да опитате отново или да пропуснете.';

  @override
  String get onboardingPickUseMode =>
      'Изберете режим на използване за да продължите.';

  @override
  String get openNow => 'Отворено';

  @override
  String get openNowClosed => 'Затворено';

  @override
  String get openHoursUnknown => 'Работното време е неизвестно';

  @override
  String closesAt(String time) {
    return 'Затваря $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Отваря $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Отваря $time';
  }

  @override
  String get open24Hours => 'Отворено 24 часа';

  @override
  String get badge24h => '24ч';

  @override
  String get openingHoursAutomate24h => 'Автоматизация 24/7';

  @override
  String get dayMon => 'Понеделник';

  @override
  String get dayTue => 'Вторник';

  @override
  String get dayWed => 'Сряда';

  @override
  String get dayThu => 'Четвъртък';

  @override
  String get dayFri => 'Петък';

  @override
  String get daySat => 'Събота';

  @override
  String get daySun => 'Неделя';

  @override
  String get dayShortMon => 'Пон';

  @override
  String get dayShortTue => 'Вт';

  @override
  String get dayShortWed => 'Ср';

  @override
  String get dayShortThu => 'Чет';

  @override
  String get dayShortFri => 'Пет';

  @override
  String get dayShortSat => 'Съб';

  @override
  String get dayShortSun => 'Нед';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Официални празници';

  @override
  String get closedLabel => 'Затворено';

  @override
  String get openingHoursNotAvailable => 'Работното време не е налично';

  @override
  String get showAllHours => 'Покажи всички часове';

  @override
  String get showLessHours => 'Покажи по-малко';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'прибл. л/100 км';

  @override
  String get tripRecordingEstimatedInfo =>
      'Приблизителна стойност (~) — без горивен сензор за това пътуване; стойността л/100 км е изчислена от GPS скоростта и калибровката на превозното средство. Тя е приблизителна (обикновено ±10–30 %, намалява при зряла калибровка), а не измерена.';

  @override
  String get tripRecordingPipElapsedCaption => 'изминало';

  @override
  String get radarPinHelpTitle => 'За закрепването';

  @override
  String get radarPinHelpBody =>
      'Закрепването задържа екрана включен и скрива системните ленти, така че показаното за най-близката станция остава четливо при монтаж на таблото. Докоснете отново за освобождаване. Автоматично се освобождава при спиране на радара.';

  @override
  String get radarAutoPinTitle => 'Винаги закрепвай при стартиране на радара';

  @override
  String get radarAutoPinSubtitle =>
      'Закрепвайте радара автоматично всеки път вместо да докосвате. Изразходва повече батерия.';

  @override
  String get alertsRadiusFrequencyLabel => 'Честота на проверка';

  @override
  String get alertsRadiusFrequencyDaily => 'Веднъж дневно';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Два пъти дневно';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Три пъти дневно';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Четири пъти дневно';

  @override
  String get radiusAlertPickOnMap => 'Избери на картата';

  @override
  String get radiusAlertMapPickerTitle => 'Избери център на сигнала';

  @override
  String get radiusAlertMapPickerConfirm => 'Потвърди';

  @override
  String get radiusAlertMapPickerCancel => 'Отказ';

  @override
  String get radiusAlertMapPickerHint =>
      'Плъзгайте картата, за да позиционирате центъра на сигнала';

  @override
  String get radiusAlertCenterFromMap => 'Местоположение от картата';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel близо до $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Станция е на цена $price € (цел: $threshold €)';
  }

  @override
  String get reconcileWorkflowTitle => 'Изравняване на горивото';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Открихме разлика от $gap л';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Заредихте $pumped л, но записаните пътувания отчитат само $consumed л. Остават $gap л необяснени.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Обикновено това означава, че дадено пътуване не е записано (адаптерът е бил изключен или приложението е затворено), или дадено зареждане липсва или е въведено грешно.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Докато това не се реши, общото количество гориво и общото за пътуванията няма да съвпадат.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Помогнете ни да определим разликата';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Всички зареждания за този резервоар ли са пълни и правилни?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Всички пътувания ли са записани?';

  @override
  String get reconcileWorkflowAnswerYes => 'Да';

  @override
  String get reconcileWorkflowAnswerNo => 'Не';

  @override
  String get reconcileWorkflowPathAHint =>
      'Едно зареждане липсва или е грешно — ще добавим корекция, за да се изравнят зарежданията.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Зарежданията са верни, но едно пътуване не е записано — ще добавим виртуално пътуване за изминатото разстояние.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Корекция в литри';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Колко km беше незаписаното пътуване? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Реши по-късно';

  @override
  String get reconcileWorkflowBack => 'Назад';

  @override
  String get reconcileWorkflowNext => 'Напред';

  @override
  String get reconcileWorkflowApply => 'Приложи';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Виртуално пътуване — докоснете за редактиране';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Редактирай виртуално пътуване';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Това пътуване е добавено, за да отчете горивото, използвано при шофиране без запис. Коригирайте разстоянието или горивото, или го изтрийте.';

  @override
  String get reconcileVirtualTrajetDelete => 'Изтрий виртуалното пътуване';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Неразрешена разлика гориво/пътуване от $gap л — докоснете за решаване';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Разреши неизравнената разлика между гориво и пътувания';

  @override
  String get refuelUnitPerLiter => '/л';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/сесия';

  @override
  String get shareReceiptImporting =>
      'Импортиране на споделената касова бележка…';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Този тип файл все още не може да се импортира — споделете снимка на касовата бележка.';

  @override
  String get shareReceiptFailed =>
      'Споделената касова бележка не можа да се прочете — опитайте да я споделите отново или добавете зареждането ръчно.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Споделяне на касова бележка за импортиране';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Споделете снимка на касова бележка от друго приложение за предварително попълване на зареждане — дата, литри, сума и станция се разпознават на устройството.';

  @override
  String get speedConsumptionCardTitle => 'Разход по скорост';

  @override
  String get speedBandIdleJam => 'Празен ход / задръстване';

  @override
  String get speedBandUrban => 'Градско (10–50)';

  @override
  String get speedBandSuburban => 'Крайградско (50–80)';

  @override
  String get speedBandRural => 'Извънградско (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Еко-крейсерско (100–115)';

  @override
  String get speedBandMotorway => 'Магистрала (115–130)';

  @override
  String get speedBandMotorwayFast => 'Бърза магистрала (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Записвайте 30+ минути пътувания с OBD2 адаптер, за да отключите анализа на скорост/разход.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % от шофирането';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Необходими са повече данни';

  @override
  String get splashLoadingLabel => 'Зареждане на Sparkilo';

  @override
  String get storageRecoveryTitle => 'Проблем със съхранението';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo не можа да отвори локалното си хранилище за данни. Файлът изглежда повреден.';

  @override
  String get storageRecoveryGuidance =>
      'За възстановяване изчистете хранилището на приложението в настройките на устройството или преинсталирайте приложението. Любимите и историята ви се съхраняват само на това устройство и не могат да бъдат възстановени автоматично.';

  @override
  String get tankLevelTitle => 'Ниво на резервоара';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres л';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres км обхват';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Последно зареждане: $date · $count пътуване(ия) оттогава';
  }

  @override
  String get tankLevelMethodObd2 => 'Измерено от OBD2';

  @override
  String get tankLevelMethodDistanceFallback =>
      'приблизителна оценка по разстояние';

  @override
  String get tankLevelMethodMixed => 'смесено измерване';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Запишете зареждане, за да видите нивото на резервоара';

  @override
  String get tankLevelDetailSheetTitle => 'Пътувания след последното зареждане';

  @override
  String get addFillUpIsFullTankLabel => 'Пълен резервоар';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Резервоарът е напълнен до горе — премахнете отметката, ако е частично зареждане';

  @override
  String get themeCardTitle => 'Тема';

  @override
  String get themeCardSubtitleSystem => 'Системна';

  @override
  String get themeCardSubtitleLight => 'Светла';

  @override
  String get themeCardSubtitleDark => 'Тъмна';

  @override
  String get themeSettingsScreenTitle => 'Тема';

  @override
  String get themeSettingsSystemLabel => 'Следвай системата';

  @override
  String get themeSettingsLightLabel => 'Светла';

  @override
  String get themeSettingsDarkLabel => 'Тъмна';

  @override
  String get themeSettingsSystemDescription =>
      'Съответства на текущия вид на устройството.';

  @override
  String get themeSettingsLightDescription =>
      'Светли фонове — най-добре за дневна употреба.';

  @override
  String get themeSettingsDarkDescription =>
      'Тъмни фонове — по-щадящо за очите нощем и пести батерия на OLED екрани.';

  @override
  String get themeSettingsEcoLabel => 'Еко';

  @override
  String get themeSettingsEcoDescription =>
      'Характерният зелен вид на приложението — ярък и лесен за четене, с леко зелено оцветени фонове.';

  @override
  String get throttleRpmHistogramTitle => 'Как сте използвали двигателя';

  @override
  String get throttleRpmHistogramThrottleSection => 'Позиция на педала за газ';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM на двигателя';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Инерция (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Леко (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Умерено (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Пълен газ (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Празен ход (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Крейсерско (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Динамично (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Интензивно (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Няма проби за педал или RPM в това пътуване.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Пътувания';

  @override
  String get trajetsStartRecordingButton => 'Започни запис';

  @override
  String get trajetsResumeRecordingButton => 'Продължи записа';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Свързване с OBD2 адаптер...';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Четене на данни за превозното средство...';

  @override
  String get tripStartProgressStartingRecording => 'Стартиране на запис...';

  @override
  String get tripSaveProgressFinalizingSummary =>
      'Финализиране на обобщението…';

  @override
  String get tripSaveProgressSavingToHistory => 'Записване в историята…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Синхронизиране на заден план…';

  @override
  String get trajetsEmptyStateTitle => 'Все още няма пътувания';

  @override
  String get trajetsEmptyStateBody =>
      'Докоснете Започни запис, за да започнете да записвате пътуванията си.';

  @override
  String trajetsRowDistance(String km) {
    return '$km км';
  }

  @override
  String trajetsRowDuration(String minutes) {
    return '$minutes мин';
  }

  @override
  String trajetsRowAvgConsumption(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get trajetDetailSummaryTitle => 'Резюме';

  @override
  String get trajetDetailFieldDate => 'Дата';

  @override
  String get trajetDetailFieldVehicle => 'Превозно средство';

  @override
  String get trajetDetailFieldAdapter => 'OBD2 адаптер';

  @override
  String get trajetDetailFieldDistance => 'Разстояние';

  @override
  String get trajetDetailFieldDuration => 'Продължителност';

  @override
  String get trajetDetailFieldAvgConsumption => 'Среден разход';

  @override
  String get trajetDetailFieldFuelUsed => 'Изразходвано гориво';

  @override
  String get trajetDetailFieldFuelCost => 'Разход за гориво';

  @override
  String get trajetDetailFieldAvgSpeed => 'Средна скорост';

  @override
  String get trajetDetailFieldMaxSpeed => 'Максимална скорост';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Скорост (км/ч)';

  @override
  String get trajetDetailChartFuelRate => 'Горивен поток (л/ч)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Натоварване на двигателя (%)';

  @override
  String get trajetDetailChartThrottle => 'Газ / педал (%)';

  @override
  String get trajetDetailChartCoolant => 'Охладителна течност (°C)';

  @override
  String get trajetDetailChartAltitude => 'Височина (m)';

  @override
  String get trajetDetailChartLambda => 'Командвано λ';

  @override
  String get trajetDetailChartsSection => 'Графики';

  @override
  String get trajetsRowColdStartChip => 'Студен старт';

  @override
  String get trajetsRowColdStartTooltip =>
      'Двигателят не достигна работна температура по време на пътуването — разходът на гориво е бил по-висок от обичайното.';

  @override
  String get trajetDetailChartEmpty => 'Не са записани проби';

  @override
  String get trajetDetailChartEstimatedBadge => 'прибл.';

  @override
  String get trajetDetailShareAction => 'Сподели';

  @override
  String get trajetDetailShareImageOption => 'Споделяне на изображение';

  @override
  String get trajetDetailShareGpxOption => 'Споделяне на GPS трасе (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Няма GPS данни в това пътуване';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — пътуване на $date';
  }

  @override
  String get trajetDetailShareError =>
      'Неуспешно генериране на изображение за споделяне';

  @override
  String get trajetDetailDownloadCsvOption => 'Изтегли телеметрия (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Изтегли телеметрия (JSON)';

  @override
  String get trajetDetailDownloadError => 'Файлът не можа да се запише';

  @override
  String get trajetDetailDeleteAction => 'Изтрий';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Изтриване на пътуването?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Това пътуване ще бъде окончателно премахнато от историята ви.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Отказ';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Изтрий';

  @override
  String get tripRecordingObd2NotResponding =>
      'OBD2 адаптерът е свързан, но не връща данни. Опитайте друг адаптер или проверете диагностичния протокол на превозното средство.';

  @override
  String get trajetsViewAllOnMap => 'Виж всички на картата';

  @override
  String get trajetsMapTitle => 'Пътувания на картата';

  @override
  String get trajetsMapShareGpx => 'Споделяне на GPX';

  @override
  String get trajetsMapEmpty => 'Никое от избраните пътувания няма GPS данни.';

  @override
  String get trajetsMapShareError => 'GPX файлът не може да бъде споделен';

  @override
  String get tripLengthCardTitle => 'Разход по дължина на пътуването';

  @override
  String get tripLengthBucketShort => 'Кратко (<5 км)';

  @override
  String get tripLengthBucketMedium => 'Средно (5–25 км)';

  @override
  String get tripLengthBucketLong => 'Дълго (>25 км)';

  @override
  String get tripLengthBucketNeedMoreData => 'Необходими са повече данни';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пътувания',
      one: '1 пътуване',
      zero: 'няма пътувания',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Маршрут на пътуването';

  @override
  String get tripPathCardSubtitle => 'GPS-записан маршрут';

  @override
  String get tripPathLegendTitle => 'Разход';

  @override
  String get tripPathLegendEfficient => 'Ефективен (< 6 л/100км)';

  @override
  String get tripPathLegendBorderline => 'Граничен (6–10 л/100км)';

  @override
  String get tripPathLegendWasteful => 'Разточителен (≥ 10 л/100км)';

  @override
  String get tripRadarClosestStation => 'Радар за бензиностанции';

  @override
  String get tripRadarScanning => 'Търсене на близки станции';

  @override
  String get tripRadarNoStationNearby => 'Няма близка станция';

  @override
  String get fuelStationRadarNearer => 'По-близка станция';

  @override
  String get fuelStationRadarFarther => 'По-далечна станция';

  @override
  String get fuelStationRadarStart => 'Стартирай радара за бензиностанции';

  @override
  String get stopRadar => 'Спри радара';

  @override
  String get fuelStationRadarResultBadge =>
      'Резултат от радара за бензиностанции';

  @override
  String get tripRecordingPinTooltip =>
      'Закачането задържа екрана включен — изразходва повече батерия';

  @override
  String get tripRecordingPinSemanticOn => 'Откачи формата за запис';

  @override
  String get tripRecordingPinSemanticOff => 'Закачи формата за запис';

  @override
  String get tripRecordingPinHelpTooltip => 'Какво прави закачането?';

  @override
  String get tripRecordingPinHelpTitle => 'За закачане';

  @override
  String get tripRecordingPinHelpBody =>
      'Закачането задържа екрана включен и скрива системните ленти, така че формата остава четима на таблото. Докоснете отново за освобождаване. Автоматично се освобождава при спиране на пътуването.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Записването продължава на заден план. Докоснете червения банер в горната част на всеки екран за връщане.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Отвори активното пътуване от раздела Разход';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Закачете екрана, за да поддържате GPS активен по време на пътуването — Android може да ограничи GPS при заспиване.';

  @override
  String get tripRecordingMinimiseTooltip => 'Минимизиране в плаваща плочка';

  @override
  String get tripRecordingAutoPinTitle => 'Винаги фиксирай при старт на записа';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Фиксирай формуляра автоматично при всяко пътуване, вместо да докосваш всеки път. Изразходва повече батерия.';

  @override
  String get tripRecordingConnectingTitle => 'Стартиране на записа…';

  @override
  String get tripRecordingSavingTitle => 'Записване на пътуването…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Записът е отхвърлен — не е засечено движение';

  @override
  String get tripRecordingGpsNotificationTitle => 'Записва се вашето пътуване';

  @override
  String get tripRecordingGpsNotificationText =>
      'Проследяване на маршрута за горивна и шофьорска статистика';

  @override
  String get tripShareAction => 'Споделяне с друг акаунт';

  @override
  String get tripShareSheetTitle => 'Споделяне на това пътуване';

  @override
  String get tripShareSheetSubtitle =>
      'Дайте на друг акаунт в TankSync достъп само за четене до това записано пътуване.';

  @override
  String get tripShareEmailLabel => 'Имейл на получателя';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Сподели';

  @override
  String get tripShareCreateLinkButton => 'Създаване на връзка за споделяне';

  @override
  String get tripShareLinkCreated =>
      'Връзката за споделяне е копирана — изпратете я на получателя.';

  @override
  String get tripShareSuccess => 'Пътуването е споделено.';

  @override
  String get tripShareRecipientNotFound =>
      'Няма акаунт в TankSync с този имейл.';

  @override
  String get tripShareError =>
      'Пътуването не може да бъде споделено. Опитайте отново.';

  @override
  String get tripShareExistingTitle => 'Споделено с';

  @override
  String get tripShareExistingEmpty => 'Все още не е споделено с никого.';

  @override
  String get tripShareDirectRecipient => 'Акаунт';

  @override
  String get tripShareLinkRecipient => 'Връзка за споделяне (неизползвана)';

  @override
  String get tripShareRevokeTooltip => 'Отмяна';

  @override
  String get tripShareRevoked => 'Споделянето е отменено.';

  @override
  String get trajetsSharedSectionTitle => 'Споделено с мен';

  @override
  String get trajetsSharedBadge => 'Споделено';

  @override
  String get unifiedFilterFuel => 'Гориво';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'И двете';

  @override
  String get unifiedNoResultsForFilter => 'Няма резултати за този филтър';

  @override
  String get searchFailedSnackbar =>
      'Търсенето не успя — моля, опитайте отново';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count станции',
      one: '1 станция',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Актуализирано $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Също: $names';
  }

  @override
  String get favoriteAdd => 'Добави към любими';

  @override
  String get favoriteRemove => 'Премахни от любими';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Без отстъпка: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Unbranded station';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'I may fill up with different fuel types';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Tracks which fuel is cheapest per kilometre';

  @override
  String get vinLabel => 'VIN (по избор)';

  @override
  String get vinDecodeTooltip => 'Декодирай VIN';

  @override
  String get vinConfirmAction => 'Да, попълни автоматично';

  @override
  String get vinModifyAction => 'Промени ръчно';

  @override
  String get veResetAction => 'Нулирай обемната ефективност';

  @override
  String get vehicleReadVinFromCarButton => 'Прочети VIN от колата';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Прочети VIN от сдвоения OBD2 адаптер';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN не е наличен (Mode 09 PID 02 не се поддържа на превозни средства преди 2005 г.)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Неуспешно четене на VIN — въведете ръчно';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Сдвоете OBD2 адаптер, за да четете VIN автоматично';

  @override
  String get pickerButtonLabel => 'Избери от каталога';

  @override
  String get pickerSearchHint => 'Търси марка или модел';

  @override
  String get pickerHelpText =>
      'Попълни предварително от 50+ поддържани превозни средства';

  @override
  String get pickerEmptyResults => 'Няма съвпадения';

  @override
  String get pickerCancel => 'Отказ';

  @override
  String get pickerLoading => 'Зареждане на каталога...';

  @override
  String get vinInfoTooltip => 'Какво е VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'Какво е VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'Идентификационният номер на превозното средство е 17-символен код, уникален за вашия автомобил. Той е щампован върху шасито и отпечатан в документа за регистрация.';

  @override
  String get vinInfoSectionWhyTitle => 'Защо питаме';

  @override
  String get vinInfoSectionWhyBody =>
      'Декодирането на VIN автоматично попълва обема на двигателя, броя на цилиндрите, годината на модела, основния вид гориво и грубото тегло — спестявайки ви ръчното търсене на технически спецификации. OBD2 изчислението на горивния разход използва тези стойности, за да ви даде точни данни за разхода.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Поверителност';

  @override
  String get vinInfoSectionPrivacyBody =>
      'VIN номерът ви се съхранява само локално в криптираното хранилище на приложението — никога не се качва на сървърите на Sparkilo. Базата данни NHTSA vPIC се заявява с VIN, но връща само анонимни технически спецификации; NHTSA не свързва VIN с лични данни. Без мрежа, офлайн справката връща само производител и държава.';

  @override
  String get vinInfoSectionWhereTitle => 'Къде да го намерите';

  @override
  String get vinInfoSectionWhereBody =>
      'Вижте през предното стъкло в долния ляв ъгъл от страната на шофьора, проверете стикера на рамката на вратата от страната на шофьора при отворена врата, или го прочетете от документа за регистрация на превозното средство.';

  @override
  String get vinInfoDismiss => 'Разбрах';

  @override
  String get vinConfirmPrivacyNote =>
      'Потърсихме VIN номера ви в безплатната база данни на NHTSA — нищо не е изпратено до сървърите на Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Онлайн декодиране на VIN';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Декодиране на VIN чрез безплатната публична услуга на NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'При сдвояване с адаптер, VIN номерът на превозното средство се чете локално за идентификация на автомобила. Активирането изпраща 17-символния VIN до безплатната услуга vPIC на NHTSA за търсене на допълнителни детайли (модел, обем на двигателя, вид гориво). VIN е единствените данни, изпратени — никакви други данни не напускат устройството.';

  @override
  String get vehicleDetectedFromVinBadge => '(открито)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Открито от VIN: $summary. Да се приложи?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Приложи';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, $distanceKm километра напред, $fuelType $euros евро $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Джаджа на начален екран';

  @override
  String get widgetHelpIntro =>
      'Добавете джаджата SparKilo на началния екран, за да виждате цените на гориво и зареждане с един поглед.';

  @override
  String get widgetHelpAdd =>
      'Добавете я от избирача на джаджи на launcher-а — задръжте върху празна зона на началния екран, изберете Джаджи и намерете SparKilo.';

  @override
  String get widgetHelpTap =>
      'Докоснете станция в джаджата, за да я отворите в приложението. Докоснете иконата за обновяване за актуализиране на цените.';

  @override
  String get widgetHelpConfigure =>
      'На Android, задръжте върху джаджата и изберете Преконфигурирай за промяна на профила, цвета и съдържанието.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'Изборите по-долу се прилагат за всеки инсталиран уиджет при следващото обновяване.';

  @override
  String get widgetDefaultsColorLabel => 'Цветова схема';

  @override
  String get widgetDefaultsVariantLabel => 'Вариант на съдържанието';

  @override
  String get widgetColorSchemeSystem => 'Системна';

  @override
  String get widgetColorSchemeLight => 'Светла';

  @override
  String get widgetColorSchemeDark => 'Тъмна';

  @override
  String get widgetColorSchemeBlue => 'Синя';

  @override
  String get widgetColorSchemeGreen => 'Зелена';

  @override
  String get widgetColorSchemeOrange => 'Оранжева';

  @override
  String get widgetVariantDefault => 'Само текуща цена';

  @override
  String get widgetVariantPredictive =>
      'Прогностична: най-добро време за зареждане';

  @override
  String get widgetPredictiveNowPrefix => 'сега';
}
