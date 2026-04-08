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
}
