// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Precios Combustible';

  @override
  String get search => 'Buscar';

  @override
  String get favorites => 'Favoritos';

  @override
  String get map => 'Mapa';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Ajustes';

  @override
  String get gpsLocation => 'Ubicación GPS';

  @override
  String get zipCode => 'Código postal';

  @override
  String get zipCodeHint => 'ej. 28001';

  @override
  String get fuelType => 'Combustible';

  @override
  String get searchRadius => 'Radio';

  @override
  String get searchNearby => 'Gasolineras cercanas';

  @override
  String get searchButton => 'Buscar';

  @override
  String get searchCriteriaTitle => 'Search criteria';

  @override
  String get searchCriteriaOpen => 'Search';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Within $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tap to start searching';

  @override
  String get noResults => 'No se encontraron gasolineras.';

  @override
  String get startSearch => 'Busca para encontrar gasolineras.';

  @override
  String get open => 'Abierto';

  @override
  String get closed => 'Cerrado';

  @override
  String distance(String distance) {
    return 'a $distance';
  }

  @override
  String get price => 'Precio';

  @override
  String get prices => 'Precios';

  @override
  String get address => 'Dirección';

  @override
  String get openingHours => 'Horario';

  @override
  String get open24h => 'Abierto 24 horas';

  @override
  String get navigate => 'Navegar';

  @override
  String get retry => 'Reintentar';

  @override
  String get apiKeySetup => 'Clave API';

  @override
  String get apiKeyDescription =>
      'Regístrate una vez para obtener una clave API gratuita.';

  @override
  String get apiKeyLabel => 'Clave API';

  @override
  String get register => 'Registro';

  @override
  String get continueButton => 'Continuar';

  @override
  String get welcome => 'Precios Combustible';

  @override
  String get welcomeSubtitle =>
      'Encuentra el combustible más barato cerca de ti.';

  @override
  String get profileName => 'Nombre del perfil';

  @override
  String get preferredFuel => 'Combustible preferido';

  @override
  String get defaultRadius => 'Radio predeterminado';

  @override
  String get landingScreen => 'Pantalla de inicio';

  @override
  String get homeZip => 'Código postal de casa';

  @override
  String get newProfile => 'Nuevo perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get countryChangeTitle => 'Switch country?';

  @override
  String countryChangeBody(String country) {
    return 'Switching to $country will change:';
  }

  @override
  String get countryChangeCurrency => 'Currency';

  @override
  String get countryChangeDistance => 'Distance';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Price format';

  @override
  String get countryChangeNote =>
      'Existing favorites and fill-up logs are not rewritten; only new entries use the new units.';

  @override
  String get countryChangeConfirm => 'Switch';

  @override
  String get delete => 'Eliminar';

  @override
  String get activate => 'Activar';

  @override
  String get configured => 'Configurado';

  @override
  String get notConfigured => 'No configurado';

  @override
  String get about => 'Acerca de';

  @override
  String get openSource => 'Código abierto (Licencia MIT)';

  @override
  String get sourceCode => 'Código fuente en GitHub';

  @override
  String get noFavorites => 'Sin favoritos';

  @override
  String get noFavoritesHint =>
      'Toca la estrella de una gasolinera para guardarla como favorita.';

  @override
  String get language => 'Idioma';

  @override
  String get country => 'País';

  @override
  String get demoMode => 'Modo demo — datos de ejemplo.';

  @override
  String get setupLiveData => 'Configurar datos en vivo';

  @override
  String get freeNoKey => 'Gratis — sin clave necesaria';

  @override
  String get apiKeyRequired => 'Clave API necesaria';

  @override
  String get skipWithoutKey => 'Continuar sin clave';

  @override
  String get dataTransparency => 'Transparencia de datos';

  @override
  String get storageAndCache => 'Almacenamiento y caché';

  @override
  String get clearCache => 'Limpiar caché';

  @override
  String get clearAllData => 'Eliminar todos los datos';

  @override
  String get errorLog => 'Registro de errores';

  @override
  String stationsFound(int count) {
    return '$count gasolineras encontradas';
  }

  @override
  String get whatIsShared => '¿Qué se comparte — y con quién?';

  @override
  String get gpsCoordinates => 'Coordenadas GPS';

  @override
  String get gpsReason =>
      'Se envían en cada búsqueda para encontrar las estaciones cercanas.';

  @override
  String get postalCodeData => 'Código postal';

  @override
  String get postalReason =>
      'Se convierte en coordenadas mediante el servicio de geocodificación.';

  @override
  String get mapViewport => 'Vista del mapa';

  @override
  String get mapReason =>
      'Los mosaicos del mapa se cargan desde el servidor. No se transmiten datos personales.';

  @override
  String get apiKeyData => 'Clave API';

  @override
  String get apiKeyReason =>
      'Su clave personal se envía con cada solicitud API. Está vinculada a su correo electrónico.';

  @override
  String get notShared => 'NO se comparte:';

  @override
  String get searchHistory => 'Historial de búsqueda';

  @override
  String get favoritesData => 'Favoritos';

  @override
  String get profileNames => 'Nombres de perfil';

  @override
  String get homeZipData => 'Código postal de casa';

  @override
  String get usageData => 'Datos de uso';

  @override
  String get privacyBanner =>
      'Esta app no tiene servidor. Todos los datos permanecen en su dispositivo. Sin análisis, sin seguimiento, sin publicidad.';

  @override
  String get storageUsage => 'Uso de almacenamiento en este dispositivo';

  @override
  String get settingsLabel => 'Ajustes';

  @override
  String get profilesStored => 'perfiles guardados';

  @override
  String get stationsMarked => 'estaciones marcadas';

  @override
  String get cachedResponses => 'respuestas en caché';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Gestión de caché';

  @override
  String get cacheDescription =>
      'La caché almacena respuestas API para una carga más rápida y acceso sin conexión.';

  @override
  String get stationSearch => 'Búsqueda de estaciones';

  @override
  String get stationDetails => 'Detalles de estación';

  @override
  String get priceQuery => 'Consulta de precios';

  @override
  String get zipGeocoding => 'Geocodificación de código postal';

  @override
  String minutes(int n) {
    return '$n minutos';
  }

  @override
  String hours(int n) {
    return '$n horas';
  }

  @override
  String get clearCacheTitle => '¿Limpiar caché?';

  @override
  String get clearCacheBody =>
      'Los resultados de búsqueda y precios en caché se eliminarán. Los perfiles, favoritos y ajustes se conservan.';

  @override
  String get clearCacheButton => 'Limpiar caché';

  @override
  String get deleteAllTitle => '¿Eliminar todos los datos?';

  @override
  String get deleteAllBody =>
      'Esto elimina permanentemente todos los perfiles, favoritos, clave API, ajustes y caché. La app se reiniciará.';

  @override
  String get deleteAllButton => 'Eliminar todo';

  @override
  String get entries => 'entradas';

  @override
  String get cacheEmpty => 'La caché está vacía';

  @override
  String get noStorage => 'Sin almacenamiento utilizado';

  @override
  String get apiKeyNote =>
      'Registro gratuito. Datos de las agencias gubernamentales de transparencia de precios.';

  @override
  String get apiKeyFormatError =>
      'Formato inválido — se espera UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Apoyar este proyecto';

  @override
  String get supportDescription =>
      'Esta app es gratuita, de código abierto y sin publicidad. Si le resulta útil, considere apoyar al desarrollador.';

  @override
  String get reportBug => 'Reportar error / Sugerir función';

  @override
  String get reportThisIssue => 'Report this issue';

  @override
  String get reportConsentTitle => 'Report to GitHub?';

  @override
  String get reportConsentBody =>
      'This will open a public GitHub issue with the error details below. No GPS coordinates, API keys, or personal data are included.';

  @override
  String get reportConsentConfirm => 'Open GitHub';

  @override
  String get reportConsentCancel => 'Cancel';

  @override
  String get configProfileSection => 'Profile';

  @override
  String get configActiveProfile => 'Active profile';

  @override
  String get configPreferredFuel => 'Preferred fuel';

  @override
  String get configCountry => 'Country';

  @override
  String get configRouteSegment => 'Route segment';

  @override
  String get configApiKeysSection => 'API keys';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API key';

  @override
  String get configApiKeyConfigured => 'Configured';

  @override
  String get configApiKeyNotSet => 'Not set (demo mode)';

  @override
  String get configApiKeyCommunity => 'Default (community key)';

  @override
  String get searchLocationPlaceholder => 'Address, postal code or city';

  @override
  String get configEvKey => 'EV charging API key';

  @override
  String get configEvKeyCustom => 'Custom key';

  @override
  String get configEvKeyShared => 'Default (shared)';

  @override
  String get configCloudSyncSection => 'Cloud Sync';

  @override
  String get configTankSyncConnected => 'Connected';

  @override
  String get configTankSyncDisabled => 'Disabled';

  @override
  String get configAuthMode => 'Auth mode';

  @override
  String get configAuthEmail => 'Email (persistent)';

  @override
  String get configAuthAnonymous => 'Anonymous (device-only)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Privacy summary';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favorites, alerts, and ignored stations are synced to your private database\n• GPS position and API keys never leave your device\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• All data is stored locally on this device only\n• No data is sent to any server\n• API keys encrypted in device secure storage';

  @override
  String get configAuthNoteEmail => 'Email account enables cross-device access';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymous account — data tied to this device';

  @override
  String get configNone => 'None';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get fuels => 'Combustibles';

  @override
  String get services => 'Servicios';

  @override
  String get zone => 'Zona';

  @override
  String get highway => 'Autopista';

  @override
  String get localStation => 'Estación local';

  @override
  String get lastUpdate => 'Última actualización';

  @override
  String get automate24h => '24h/24 — Automático';

  @override
  String get refreshPrices => 'Actualizar precios';

  @override
  String get station => 'Estación';

  @override
  String get locationDenied =>
      'Permiso de ubicación denegado. Puede buscar por código postal.';

  @override
  String get demoModeBanner => 'Modo demo. Configure la clave API en ajustes.';

  @override
  String get sortDistance => 'Distancia';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'barato';

  @override
  String get expensive => 'caro';

  @override
  String stationsOnMap(int count) {
    return '$count estaciones';
  }

  @override
  String get loadingFavorites =>
      'Cargando favoritos...\nBusque estaciones primero para guardar datos.';

  @override
  String get reportPrice => 'Reportar precio';

  @override
  String get whatsWrong => '¿Qué está mal?';

  @override
  String get correctPrice => 'Precio correcto (ej. 1,459)';

  @override
  String get sendReport => 'Enviar reporte';

  @override
  String get reportSent => 'Reporte enviado. ¡Gracias!';

  @override
  String get enterValidPrice => 'Ingrese un precio válido';

  @override
  String get cacheCleared => 'Caché vaciado.';

  @override
  String get yourPosition => 'Su posición';

  @override
  String get positionUnknown => 'Posición desconocida';

  @override
  String get distancesFromCenter => 'Distancias desde el centro de búsqueda';

  @override
  String get autoUpdatePosition => 'Actualizar posición automáticamente';

  @override
  String get autoUpdateDescription => 'Actualizar GPS antes de cada búsqueda';

  @override
  String get location => 'Ubicación';

  @override
  String get switchProfileTitle => 'País cambiado';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Estás en $country. ¿Cambiar al perfil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Cambiado al perfil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Sin perfil para este país';

  @override
  String noProfileForCountry(String country) {
    return 'Estás en $country, pero no hay un perfil configurado. Crea uno en Ajustes.';
  }

  @override
  String get autoSwitchProfile => 'Cambio automático de perfil';

  @override
  String get autoSwitchDescription =>
      'Cambiar perfil automáticamente al cruzar fronteras';

  @override
  String get switchProfile => 'Cambiar';

  @override
  String get dismiss => 'Cerrar';

  @override
  String get profileCountry => 'País';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get settingsStorageDetail => 'Clave API, perfil activo';

  @override
  String get allFuels => 'Todos';

  @override
  String get priceAlerts => 'Alertas de precio';

  @override
  String get noPriceAlerts => 'Sin alertas de precio';

  @override
  String get noPriceAlertsHint =>
      'Crea una alerta desde la página de detalle de una gasolinera.';

  @override
  String alertDeleted(String name) {
    return 'Alerta \"$name\" eliminada';
  }

  @override
  String get createAlert => 'Crear alerta de precio';

  @override
  String currentPrice(String price) {
    return 'Precio actual: $price';
  }

  @override
  String get targetPrice => 'Precio objetivo (EUR)';

  @override
  String get enterPrice => 'Introduzca un precio';

  @override
  String get invalidPrice => 'Precio no válido';

  @override
  String get priceTooHigh => 'Precio demasiado alto';

  @override
  String get create => 'Crear';

  @override
  String get alertCreated => 'Alerta de precio creada';

  @override
  String get wrongE5Price => 'Precio Super E5 incorrecto';

  @override
  String get wrongE10Price => 'Precio Super E10 incorrecto';

  @override
  String get wrongDieselPrice => 'Precio Diésel incorrecto';

  @override
  String get wrongStatusOpen => 'Aparece abierto, pero cerrado';

  @override
  String get wrongStatusClosed => 'Aparece cerrado, pero abierto';

  @override
  String get searchAlongRouteLabel => 'A lo largo de la ruta';

  @override
  String get searchEvStations => 'Buscar estaciones de carga';

  @override
  String get allStations => 'Todas las estaciones';

  @override
  String get bestStops => 'Mejores paradas';

  @override
  String get openInMaps => 'Abrir en Mapas';

  @override
  String get noStationsAlongRoute =>
      'No se encontraron estaciones a lo largo de la ruta';

  @override
  String get evOperational => 'Operativa';

  @override
  String get evStatusUnknown => 'Estado desconocido';

  @override
  String evConnectors(int count) {
    return 'Conectores ($count puntos)';
  }

  @override
  String get evNoConnectors => 'Sin detalles de conectores disponibles';

  @override
  String get evUsageCost => 'Coste de uso';

  @override
  String get evPricingUnavailable => 'Precio no disponible del proveedor';

  @override
  String get evLastUpdated => 'Última actualización';

  @override
  String get evUnknown => 'Desconocido';

  @override
  String get evDataAttribution => 'Datos de OpenChargeMap (fuente comunitaria)';

  @override
  String get evStatusDisclaimer =>
      'El estado puede no reflejar la disponibilidad en tiempo real. Toque actualizar para obtener los datos más recientes.';

  @override
  String get evNavigateToStation => 'Navegar a la estación';

  @override
  String get evRefreshStatus => 'Actualizar estado';

  @override
  String get evStatusUpdated => 'Estado actualizado';

  @override
  String get evStationNotFound =>
      'No se pudo actualizar — estación no encontrada cerca';

  @override
  String get addedToFavorites => 'Añadido a favoritos';

  @override
  String get removedFromFavorites => 'Eliminado de favoritos';

  @override
  String get addFavorite => 'Añadir a favoritos';

  @override
  String get removeFavorite => 'Eliminar de favoritos';

  @override
  String get currentLocation => 'Ubicación actual';

  @override
  String get gpsError => 'Error GPS';

  @override
  String get couldNotResolve => 'No se pudo resolver el inicio o el destino';

  @override
  String get start => 'Inicio';

  @override
  String get destination => 'Destino';

  @override
  String get cityAddressOrGps => 'Ciudad, dirección o GPS';

  @override
  String get cityOrAddress => 'Ciudad o dirección';

  @override
  String get useGps => 'Usar GPS';

  @override
  String get stop => 'Parada';

  @override
  String stopN(int n) {
    return 'Parada $n';
  }

  @override
  String get addStop => 'Añadir parada';

  @override
  String get searchAlongRoute => 'Buscar a lo largo de la ruta';

  @override
  String get cheapest => 'Más barata';

  @override
  String nStations(int count) {
    return '$count estaciones';
  }

  @override
  String nBest(int count) {
    return '$count mejores';
  }

  @override
  String get fuelPricesTankerkoenig => 'Precios de combustible (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Requerido para buscar precios de combustible en Alemania';

  @override
  String get evChargingOpenChargeMap => 'Carga EV (OpenChargeMap)';

  @override
  String get customKey => 'Clave personalizada';

  @override
  String get appDefaultKey => 'Clave predeterminada de la app';

  @override
  String get optionalOverrideKey =>
      'Opcional: reemplazar la clave integrada con la suya';

  @override
  String get requiredForEvSearch =>
      'Requerido para buscar estaciones de carga EV';

  @override
  String get edit => 'Editar';

  @override
  String get fuelPricesApiKey => 'Clave API precios de combustible';

  @override
  String get tankerkoenigApiKey => 'Clave API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Clave API carga EV';

  @override
  String get openChargeMapApiKey => 'Clave API OpenChargeMap';

  @override
  String get routeSegment => 'Segmento de ruta';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Mostrar estación más barata cada $km km a lo largo de la ruta';
  }

  @override
  String get avoidHighways => 'Evitar autopistas';

  @override
  String get avoidHighwaysDesc =>
      'El cálculo de ruta evita carreteras de peaje y autopistas';

  @override
  String get showFuelStations => 'Mostrar gasolineras';

  @override
  String get showFuelStationsDesc =>
      'Incluir estaciones de gasolina, diésel, GLP, GNC';

  @override
  String get showEvStations => 'Mostrar estaciones de carga';

  @override
  String get showEvStationsDesc =>
      'Incluir estaciones de carga eléctrica en los resultados';

  @override
  String get noStationsAlongThisRoute =>
      'No se encontraron estaciones a lo largo de esta ruta.';

  @override
  String get fuelCostCalculator => 'Calculadora de coste de combustible';

  @override
  String get distanceKm => 'Distancia (km)';

  @override
  String get consumptionL100km => 'Consumo (L/100km)';

  @override
  String get fuelPriceEurL => 'Precio combustible (EUR/L)';

  @override
  String get tripCost => 'Coste del viaje';

  @override
  String get fuelNeeded => 'Combustible necesario';

  @override
  String get totalCost => 'Coste total';

  @override
  String get enterCalcValues =>
      'Introduzca distancia, consumo y precio para calcular el coste del viaje';

  @override
  String get priceHistory => 'Historial de precios';

  @override
  String get noPriceHistory => 'Aún no hay historial de precios';

  @override
  String get noHourlyData => 'Sin datos por hora';

  @override
  String get noStatistics => 'No hay estadísticas disponibles';

  @override
  String get statMin => 'Mín';

  @override
  String get statMax => 'Máx';

  @override
  String get statAvg => 'Prom';

  @override
  String get showAllFuelTypes => 'Mostrar todos los tipos de combustible';

  @override
  String get connected => 'Conectado';

  @override
  String get notConnected => 'No conectado';

  @override
  String get connectTankSync => 'Conectar TankSync';

  @override
  String get disconnectTankSync => 'Desconectar TankSync';

  @override
  String get viewMyData => 'Ver mis datos';

  @override
  String get optionalCloudSync =>
      'Sincronización en la nube opcional para alertas, favoritos y notificaciones push';

  @override
  String get tapToUpdateGps => 'Toque para actualizar la posición GPS';

  @override
  String get gpsAutoUpdateHint =>
      'La posición GPS se adquiere automáticamente al buscar. También puede actualizarla manualmente aquí.';

  @override
  String get clearGpsConfirm =>
      '¿Borrar la posición GPS almacenada? Puede actualizarla en cualquier momento.';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get deleteAllServerData => 'Eliminar todos los datos del servidor';

  @override
  String get deleteServerDataConfirm =>
      '¿Eliminar todos los datos del servidor?';

  @override
  String get deleteEverything => 'Eliminar todo';

  @override
  String get allDataDeleted => 'Todos los datos del servidor eliminados';

  @override
  String get disconnectConfirm => '¿Desconectar TankSync?';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get myServerData => 'Mis datos del servidor';

  @override
  String get anonymousUuid => 'UUID anónimo';

  @override
  String get server => 'Servidor';

  @override
  String get syncedData => 'Datos sincronizados';

  @override
  String get pushTokens => 'Tokens push';

  @override
  String get priceReports => 'Reportes de precios';

  @override
  String get totalItems => 'Total de elementos';

  @override
  String get estimatedSize => 'Tamaño estimado';

  @override
  String get viewRawJson => 'Ver datos brutos como JSON';

  @override
  String get exportJson => 'Exportar como JSON (portapapeles)';

  @override
  String get jsonCopied => 'JSON copiado al portapapeles';

  @override
  String get rawDataJson => 'Datos brutos (JSON)';

  @override
  String get close => 'Cerrar';

  @override
  String get account => 'Cuenta';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get upgradeToEmail => 'Crear cuenta de correo';

  @override
  String get savedRoutes => 'Rutas guardadas';

  @override
  String get noSavedRoutes => 'Sin rutas guardadas';

  @override
  String get noSavedRoutesHint =>
      'Busca a lo largo de una ruta y guárdala para acceso rápido.';

  @override
  String get saveRoute => 'Guardar ruta';

  @override
  String get routeName => 'Nombre de la ruta';

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
  String get alertStatsActive => 'Activas';

  @override
  String get alertStatsToday => 'Hoy';

  @override
  String get alertStatsThisWeek => 'Esta semana';

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
  String get privacyExportCsvButton => 'Export all data as CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV data exported to clipboard';

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
  String get amenities => 'Servicios';

  @override
  String get amenityShop => 'Tienda';

  @override
  String get amenityCarWash => 'Lavado';

  @override
  String get amenityAirPump => 'Aire';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Comida';

  @override
  String get amenityAtm => 'Cajero';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'Carga EV';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Fuel Card';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Pay with $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Compared to the rolling average over your last 3 fill-ups ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumption $value L/100 km, $delta versus your rolling average';
  }

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

  @override
  String get voiceAnnouncementsTitle => 'Voice Announcements';

  @override
  String get voiceAnnouncementsDescription =>
      'Announce nearby cheap stations while driving';

  @override
  String get voiceAnnouncementsEnabled => 'Enable voice announcements';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Only below $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometers ahead, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Announcement radius';

  @override
  String get voiceAnnouncementCooldown => 'Repeat interval';

  @override
  String get nearestStations => 'Estaciones cercanas';

  @override
  String get nearestStationsHint =>
      'Encontrar las estaciones mas cercanas con su ubicacion actual';

  @override
  String get consumptionLogTitle => 'Fuel consumption';

  @override
  String get consumptionLogMenuTitle => 'Consumption log';

  @override
  String get consumptionLogMenuSubtitle =>
      'Track fill-ups and calculate L/100km';

  @override
  String get consumptionStatsTitle => 'Consumption stats';

  @override
  String get addFillUp => 'Add fill-up';

  @override
  String get noFillUpsTitle => 'No fill-ups yet';

  @override
  String get noFillUpsSubtitle =>
      'Log your first fill-up to start tracking consumption.';

  @override
  String get fillUpDate => 'Date';

  @override
  String get liters => 'Liters';

  @override
  String get odometerKm => 'Odometer (km)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get stationPreFilled => 'Station pre-filled';

  @override
  String get statAvgConsumption => 'Avg L/100km';

  @override
  String get statAvgCostPerKm => 'Avg cost/km';

  @override
  String get statTotalLiters => 'Total liters';

  @override
  String get statTotalSpent => 'Total spent';

  @override
  String get statFillUpCount => 'Fill-ups';

  @override
  String get fieldRequired => 'Required';

  @override
  String get fieldInvalidNumber => 'Invalid number';

  @override
  String get carbonDashboardTitle => 'Carbon dashboard';

  @override
  String get carbonTabCharts => 'Charts';

  @override
  String get carbonTabAchievements => 'Achievements';

  @override
  String get carbonEmptyTitle => 'No data yet';

  @override
  String get carbonEmptySubtitle =>
      'Log fill-ups to see your carbon dashboard.';

  @override
  String get carbonSummaryTotalCost => 'Total cost';

  @override
  String get carbonSummaryTotalCo2 => 'Total CO2';

  @override
  String get monthlyCostsTitle => 'Monthly costs';

  @override
  String get monthlyEmissionsTitle => 'Monthly CO2 emissions';

  @override
  String get milestonesTitle => 'Milestones';

  @override
  String get milestoneFirstFillUp => 'First fill-up logged';

  @override
  String get milestoneTenFillUps => '10 fill-ups tracked';

  @override
  String get milestoneFiftyFillUps => '50 fill-ups tracked';

  @override
  String get milestoneHundredLiters => '100 L tracked';

  @override
  String get milestoneThousandLiters => '1000 L tracked';

  @override
  String get milestoneHundredKgCo2 => '100 kg CO2 tracked';

  @override
  String get milestoneOneTonneCo2 => '1 tonne CO2 tracked';

  @override
  String get milestoneThousandKm => '1000 km driven';

  @override
  String get milestoneTenThousandKm => '10,000 km driven';

  @override
  String get fuelVsEvTitle => 'Fuel vs EV';

  @override
  String get fuelVsEvSubtitle => 'CO2 comparison for the same distance driven';

  @override
  String get fuelVsEvYourFuel => 'Your fuel';

  @override
  String get fuelVsEvEquivalent => 'Equivalent EV';

  @override
  String get fuelVsEvDistance => 'Distance';

  @override
  String get fuelVsEvDifference => 'Difference';

  @override
  String get shareProgress => 'Share';

  @override
  String get shareCopied => 'Copied to clipboard';

  @override
  String shareCo2Message(String kg) {
    return 'I tracked $kg kg CO2 with Tankstellen.';
  }

  @override
  String get vehiclesTitle => 'My vehicles';

  @override
  String get vehiclesMenuTitle => 'My vehicles';

  @override
  String get vehiclesMenuSubtitle =>
      'Battery, connectors, charging preferences';

  @override
  String get vehiclesEmptyMessage =>
      'Add your car to filter by connector and estimate charging costs.';

  @override
  String get vehiclesWizardTitle => 'My vehicles (optional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Add your car to pre-fill the consumption log and enable EV connector filters. You can skip this and add vehicles later.';

  @override
  String get vehiclesWizardNoneYet => 'No vehicle configured yet.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles',
      one: '1 vehicle',
    );
    return 'You have $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Skip to finish setup — you can add vehicles anytime from Settings.';

  @override
  String get fillUpVehicleLabel => 'Vehicle';

  @override
  String get fillUpVehicleNone => 'No vehicle';

  @override
  String get fillUpVehicleRequired => 'Vehicle is required';

  @override
  String get reportScanError => 'Report scan error';

  @override
  String get pickStationTitle => 'Pick a station';

  @override
  String get pickStationHelper =>
      'Start the fill-up from a known station so prices, brand and fuel type fill themselves in.';

  @override
  String get pickStationEmpty =>
      'No favorite stations yet — add some from Search or Favorites, or skip and fill in manually.';

  @override
  String get pickStationSkip => 'Skip — add without a station';

  @override
  String get scanPump => 'Scan pump';

  @override
  String get scanPayment => 'Scan payment QR';

  @override
  String get qrPaymentBeneficiary => 'Beneficiary';

  @override
  String get qrPaymentAmount => 'Amount';

  @override
  String get qrPaymentEpcTitle => 'SEPA payment';

  @override
  String get qrPaymentEpcEmpty => 'No fields decoded';

  @override
  String get qrPaymentOpenInBank => 'Open in bank app';

  @override
  String get qrPaymentLaunchFailed => 'No app available to open this code';

  @override
  String get qrPaymentUnknownTitle => 'Unrecognised code';

  @override
  String get qrPaymentCopyRaw => 'Copy raw text';

  @override
  String get qrPaymentCopiedRaw => 'Copied to clipboard';

  @override
  String get qrPaymentReport => 'Report this scan';

  @override
  String get qrPaymentEpcCopied =>
      'Bank details copied — paste into your banking app';

  @override
  String get qrScannerGuidance => 'Point the camera at a QR code';

  @override
  String get torchOn => 'Turn flash on';

  @override
  String get torchOff => 'Turn flash off';

  @override
  String get obdNoAdapter => 'No OBD2 adapter in range';

  @override
  String get obdOdometerUnavailable => 'Could not read odometer';

  @override
  String get obdPermissionDenied =>
      'Grant Bluetooth permission in system settings';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter didn\'t answer — turn the ignition on and retry';

  @override
  String get obdPickerTitle => 'Pick an OBD2 adapter';

  @override
  String get obdPickerScanning => 'Scanning for adapters…';

  @override
  String get obdPickerConnecting => 'Connecting…';

  @override
  String get themeSettingTitle => 'Theme';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'Follow system';

  @override
  String get tripRecordingTitle => 'Recording trip';

  @override
  String get tripSummaryTitle => 'Trip summary';

  @override
  String get tripMetricDistance => 'Distance';

  @override
  String get tripMetricSpeed => 'Speed';

  @override
  String get tripMetricFuelUsed => 'Fuel used';

  @override
  String get tripMetricAvgConsumption => 'Avg';

  @override
  String get tripMetricElapsed => 'Elapsed';

  @override
  String get tripMetricOdometer => 'Odometer';

  @override
  String get tripStop => 'Stop recording';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Resume';

  @override
  String get tripBannerRecording => 'Recording trip';

  @override
  String get tripBannerPaused => 'Trip paused — tap to resume';

  @override
  String get tripSaveAsFillUp => 'Save as fill-up';

  @override
  String get tripDiscard => 'Discard';

  @override
  String obdOdometerRead(int km) {
    return 'Odometer read: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Not set';

  @override
  String get wizardVehicleTapToEdit => 'Tap to edit';

  @override
  String get wizardVehicleDefaultBadge => 'Default';

  @override
  String get profileDefaultVehicleLabel => 'Default vehicle (optional)';

  @override
  String get profileDefaultVehicleNone => 'No default';

  @override
  String get profileFuelFromVehicleHint =>
      'Fuel type is derived from your default vehicle. Clear the vehicle to pick a fuel directly.';

  @override
  String get consumptionNoVehicleTitle => 'Add a vehicle first';

  @override
  String get consumptionNoVehicleBody =>
      'Fill-ups are attributed to a vehicle. Add your car to start logging consumption.';

  @override
  String get vehicleAdd => 'Add vehicle';

  @override
  String get vehicleAddTitle => 'Add vehicle';

  @override
  String get vehicleEditTitle => 'Edit vehicle';

  @override
  String get vehicleDeleteTitle => 'Delete vehicle?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Remove \"$name\" from your profiles?';
  }

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameHint => 'e.g. My Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustion';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Electric';

  @override
  String get vehicleEvSectionTitle => 'Electric';

  @override
  String get vehicleCombustionSectionTitle => 'Combustion';

  @override
  String get vehicleBatteryLabel => 'Battery capacity (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max charging power (kW)';

  @override
  String get vehicleConnectorsLabel => 'Supported connectors';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max SoC %';

  @override
  String get vehicleTankLabel => 'Tank capacity (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Preferred fuel';

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
  String get evShowOnMap => 'Show EV stations';

  @override
  String get evAvailableOnly => 'Available only';

  @override
  String get evMinPower => 'Min power';

  @override
  String get evMaxPower => 'Max power';

  @override
  String get evOperator => 'Operator';

  @override
  String get evLastUpdate => 'Last update';

  @override
  String get evStatusAvailable => 'Available';

  @override
  String get evStatusOccupied => 'Occupied';

  @override
  String get evStatusOutOfOrder => 'Out of order';

  @override
  String get openOnlyFilter => 'Open only';

  @override
  String get saveAsDefaults => 'Save as my defaults';

  @override
  String get criteriaSavedToProfile => 'Saved as defaults';

  @override
  String get profileNotFound => 'No active profile';

  @override
  String get updatingFavorites => 'Updating your favorites...';

  @override
  String get fetchingLatestPrices => 'Fetching the latest prices';

  @override
  String get noDataAvailable => 'No data';

  @override
  String get configAndPrivacy => 'Configuration & Privacy';

  @override
  String get searchToSeeMap => 'Search to see stations on the map';

  @override
  String get evPowerAny => 'Any';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profile';

  @override
  String get sectionLocation => 'Location';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipClose => 'Close';

  @override
  String get tooltipClearSearch => 'Clear search input';

  @override
  String get tooltipUseGps => 'Use GPS location';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get evConnectorsLabel => 'Available connectors';

  @override
  String get evConnectorsNone => 'No connector information';

  @override
  String get switchToEmail => 'Switch to email';

  @override
  String get switchToEmailSubtitle =>
      'Keep data, add sign-in from other devices';

  @override
  String get switchToAnonymousAction => 'Switch to anonymous';

  @override
  String get switchToAnonymousSubtitle =>
      'Keep local data, use new anonymous session';

  @override
  String get linkDevice => 'Link device';

  @override
  String get shareDatabase => 'Share database';

  @override
  String get disconnectAction => 'Disconnect';

  @override
  String get disconnectSubtitle => 'Stop syncing (local data kept)';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Remove all server data permanently';

  @override
  String get localOnly => 'Local only';

  @override
  String get localOnlySubtitle =>
      'Optional: sync favorites, alerts, and ratings across devices';

  @override
  String get setupCloudSync => 'Set up cloud sync';

  @override
  String get disconnectTitle => 'Disconnect TankSync?';

  @override
  String get disconnectBody =>
      'Cloud sync will be disabled. Your local data (favorites, alerts, history) is preserved on this device. Server data is not deleted.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes all your data from the server (favorites, alerts, ratings, routes). Local data on this device is preserved.\n\nThis cannot be undone.';

  @override
  String get switchToAnonymousTitle => 'Switch to anonymous?';

  @override
  String get switchToAnonymousBody =>
      'You will be signed out of your email account and continue with a new anonymous session.\n\nYour local data (favorites, alerts) is kept on this device and will be synced to the new anonymous account.';

  @override
  String get switchAction => 'Switch';

  @override
  String get helpBannerCriteria =>
      'Your profile defaults are pre-filled. Adjust criteria below to refine your search.';

  @override
  String get helpBannerAlerts =>
      'Set a price threshold for a station. You\'ll be notified when prices drop below it. Checks run every 30 minutes.';

  @override
  String get helpBannerConsumption =>
      'Log every fill-up to track your real-world consumption and CO₂ footprint. Swipe left to delete an entry.';

  @override
  String get helpBannerVehicles =>
      'Add your vehicles so fill-ups and fuel preferences default correctly. The first vehicle becomes your default.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get onboardingPreferencesTitle => 'Your preferences';

  @override
  String get onboardingZipHelper => 'Used when GPS is unavailable';

  @override
  String get onboardingRadiusHelper => 'Larger radius = more results';

  @override
  String get onboardingPrivacy =>
      'These settings are stored only on your device and never shared.';

  @override
  String get onboardingLandingTitle => 'Home screen';

  @override
  String get onboardingLandingHint =>
      'Choose which screen opens when you launch the app.';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Fuel';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Highway';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Private';

  @override
  String get ratingModeShared => 'Shared';

  @override
  String get ratingDescLocal => 'Ratings saved on this device only';

  @override
  String get ratingDescPrivate =>
      'Synced with your database (not visible to others)';

  @override
  String get ratingDescShared => 'Visible to all users of your database';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API key not configured. Add one in Settings to search EV charging stations.';

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed unavailable. Using $current.';
  }

  @override
  String get errorTitleApiKey => 'API key required';

  @override
  String get errorTitleLocation => 'Location unavailable';

  @override
  String get errorHintNoStations =>
      'Try increasing the search radius or search a different location.';

  @override
  String get errorHintApiKey => 'Configure your API key in Settings.';

  @override
  String get errorHintConnection =>
      'Check your internet connection and try again.';

  @override
  String get errorHintRouting =>
      'Route calculation failed. Check your internet connection and try again.';

  @override
  String get errorHintFallback =>
      'Try again or search by postal code / city name.';

  @override
  String get detailsLabel => 'Details';

  @override
  String get remove => 'Remove';

  @override
  String get showKey => 'Show key';

  @override
  String get hideKey => 'Hide key';

  @override
  String get syncOptionalTitle => 'TankSync is optional';

  @override
  String get syncOptionalDescription =>
      'Your app works fully without cloud sync. TankSync lets you sync favorites, alerts, and ratings across devices using Supabase (free tier available).';

  @override
  String get syncHowToConnectQuestion => 'How would you like to connect?';

  @override
  String get syncCreateOwnTitle => 'Create my own database';

  @override
  String get syncCreateOwnSubtitle =>
      'Free Supabase project — we\'ll guide you step by step';

  @override
  String get syncJoinExistingTitle => 'Join an existing database';

  @override
  String get syncJoinExistingSubtitle =>
      'Scan QR code from the database owner or paste credentials';

  @override
  String get syncChooseAccountType => 'Choose your account type';

  @override
  String get syncAccountTypeAnonymous => 'Anonymous';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Instant, no email needed. Data tied to this device.';

  @override
  String get syncAccountTypeEmail => 'Email Account';

  @override
  String get syncAccountTypeEmailDesc =>
      'Sign in from any device. Recover data if phone is lost.';

  @override
  String get syncHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get syncCreateNewAccount => 'Create new account';

  @override
  String get syncTestConnection => 'Test Connection';

  @override
  String get syncTestingConnection => 'Testing...';

  @override
  String get syncConnectButton => 'Connect';

  @override
  String get syncConnectingButton => 'Connecting...';

  @override
  String get syncDatabaseReady => 'Database ready!';

  @override
  String get syncDatabaseNeedsSetup => 'Database needs setup';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Missing';

  @override
  String get syncSqlEditorInstructions =>
      'Copy the SQL below and run it in your Supabase SQL Editor (Dashboard → SQL Editor → New Query → Paste → Run)';

  @override
  String get syncCopySqlButton => 'Copy SQL to clipboard';

  @override
  String get syncRecheckSchemaButton => 'Re-check schema';

  @override
  String get syncDoneButton => 'Done';

  @override
  String syncSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get syncEmailDescription =>
      'Your data syncs across all devices with this email.';

  @override
  String get syncSwitchToAnonymousTitle => 'Switch to anonymous';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continue without email, new anonymous session';

  @override
  String get syncGuestDescription => 'Anonymous, no email needed.';

  @override
  String get syncOrDivider => 'or';

  @override
  String get syncHowToSyncQuestion => 'How would you like to sync?';

  @override
  String get syncOfflineDescription =>
      'Your app works fully offline. Cloud sync is optional.';

  @override
  String get syncModeCommunityTitle => 'Tankstellen Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Share favorites & ratings with all users';

  @override
  String get syncModePrivateTitle => 'Private Database';

  @override
  String get syncModePrivateSubtitle => 'Your own Supabase — full data control';

  @override
  String get syncModeGroupTitle => 'Join a Group';

  @override
  String get syncModeGroupSubtitle => 'Family or friends shared database';

  @override
  String get syncPrivacyShared => 'Shared';

  @override
  String get syncPrivacyPrivate => 'Private';

  @override
  String get syncPrivacyGroup => 'Group';

  @override
  String get syncStayOfflineButton => 'Stay offline';

  @override
  String get syncSuccessTitle => 'Successfully connected!';

  @override
  String get syncSuccessDescription => 'Your data will now sync automatically.';

  @override
  String get syncWizardTitleConnect => 'Connect TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Your database';

  @override
  String get syncSetupTitleJoinGroup => 'Join a group';

  @override
  String get syncSetupTitleAccount => 'Your account';

  @override
  String get syncWizardBack => 'Back';

  @override
  String get syncWizardNext => 'Next';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Create a Supabase project';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tap \"Open Supabase\" below\n2. Create a free account (if you don\'t have one)\n3. Click \"New Project\"\n4. Choose a name and region\n5. Wait ~2 minutes for it to start';

  @override
  String get syncWizardOpenSupabase => 'Open Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Enable Anonymous Sign-ins';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. In your Supabase dashboard:\n   Authentication → Providers\n2. Find \"Anonymous Sign-ins\"\n3. Toggle it ON\n4. Click \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Open Auth Settings';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copy your credentials';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Go to Settings → API in your dashboard\n2. Copy the \"Project URL\"\n3. Copy the \"anon public\" key\n4. Paste them below';

  @override
  String get syncWizardOpenApiSettings => 'Open API Settings';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Join an existing database';

  @override
  String get syncWizardScanQrCode => 'Scan QR Code';

  @override
  String get syncWizardAskOwnerQr =>
      'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Ask the database owner to show their QR code';

  @override
  String get syncWizardEnterManuallyTitle => 'Enter manually';

  @override
  String get syncWizardOrEnterManually => 'or enter manually';

  @override
  String get syncWizardUrlHelperText =>
      'Whitespace and line breaks removed automatically';

  @override
  String get syncCredentialsPrivateHint =>
      'Enter your Supabase project credentials. You can find them in your dashboard under Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Database URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Access Key';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPleaseEnterEmail => 'Please enter your email';

  @override
  String get authInvalidEmail => 'Invalid email address';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authConnectAnonymously => 'Connect anonymously';

  @override
  String get authCreateAccountAndConnect => 'Create account & connect';

  @override
  String get authSignInAndConnect => 'Sign in & connect';

  @override
  String get authAnonymousSegment => 'Anonymous';

  @override
  String get authEmailSegment => 'Email';

  @override
  String get authAnonymousDescription =>
      'Instant access, no email needed. Data tied to this device.';

  @override
  String get authEmailDescription =>
      'Sign in from any device. Recover your data if your phone is lost.';

  @override
  String get authSyncAcrossDevices =>
      'Sync data automatically across all your devices.';

  @override
  String get authNewHereCreateAccount => 'New here? Create account';

  @override
  String get ntfyCardTitle => 'Push Notifications (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Enable ntfy.sh push';

  @override
  String get ntfyEnableSubtitle => 'Receive price alerts via ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'Topic URL';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Copy topic URL';

  @override
  String get ntfySendTestButton => 'Send test notification';

  @override
  String get ntfyFdroidHint =>
      'Install the ntfy app from F-Droid to receive push notifications on your device.';

  @override
  String get ntfyConnectFirstHint =>
      'Connect TankSync first to enable push notifications.';

  @override
  String get linkDeviceScreenTitle => 'Link Device';

  @override
  String get linkDeviceThisDeviceLabel => 'This device';

  @override
  String get linkDeviceShareCodeHint =>
      'Share this code with your other device:';

  @override
  String get linkDeviceNotConnected => 'Not connected';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copy code';

  @override
  String get linkDeviceImportSectionTitle => 'Import from another device';

  @override
  String get linkDeviceImportDescription =>
      'Enter the device code from your other device to import its favorites, alerts, vehicles, and consumption log. Each device keeps its own profile and defaults.';

  @override
  String get linkDeviceCodeFieldLabel => 'Device code';

  @override
  String get linkDeviceCodeFieldHint => 'Paste the UUID from other device';

  @override
  String get linkDeviceImportButton => 'Import data';

  @override
  String get linkDeviceHowItWorksTitle => 'How it works';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. On Device A: copy the device code above\n2. On Device B: paste it in the \"Device code\" field\n3. Tap \"Import data\" to merge favorites, alerts, vehicles, and consumption logs\n4. Both devices will have all combined data\n\nEach device keeps its own anonymous identity and its own profile (preferred fuel, default vehicle, landing screen). Data is merged, not moved.';

  @override
  String get vehicleSetActive => 'Set active';

  @override
  String get swipeHide => 'Hide';

  @override
  String get evChargingSection => 'EV Charging';

  @override
  String get fuelStationsSection => 'Fuel Stations';

  @override
  String get yourRating => 'Your rating';

  @override
  String get noStorageUsed => 'No storage used';

  @override
  String get aboutReportBug => 'Report a bug / Suggest a feature';

  @override
  String get aboutSupportProject => 'Support this project';

  @override
  String get aboutSupportDescription =>
      'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.';
}
