// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabRunSearch => 'Ejecutar búsqueda';

  @override
  String get routeSearchingChip => 'Buscando la ruta…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Cada $km km';
  }

  @override
  String get searchCriteriaTitle => 'Criterios de búsqueda';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'En un radio de $km km';
  }

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
  String get apiKeyLabel => 'Clave API';

  @override
  String get register => 'Registro';

  @override
  String get continueButton => 'Continuar';

  @override
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => '¿Cambiar de país?';

  @override
  String countryChangeBody(String country) {
    return 'Cambiar a $country modificará:';
  }

  @override
  String get countryChangeCurrency => 'Moneda';

  @override
  String get countryChangeDistance => 'Distancia';

  @override
  String get countryChangeVolume => 'Volumen';

  @override
  String get countryChangePricePerUnit => 'Formato de precio';

  @override
  String get countryChangeNote =>
      'Los favoritos y registros de repostaje existentes no se reescriben; solo las nuevas entradas usan las nuevas unidades.';

  @override
  String get countryChangeConfirm => 'Cambiar';

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
  String get freeNoKey => 'Gratis — sin clave necesaria';

  @override
  String get apiKeyRequired => 'Clave API necesaria';

  @override
  String get dataTransparency => 'Transparencia de datos';

  @override
  String get storageAndCache => 'Almacenamiento y caché';

  @override
  String get clearCache => 'Limpiar caché';

  @override
  String stationsFound(int count) {
    return '$count gasolineras encontradas';
  }

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
  String get cacheTtlGroupNetwork => 'Red';

  @override
  String get cacheTtlGroupData => 'Datos';

  @override
  String get cacheTtlGroupGeocoding => 'Geocodificación';

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
  String get deleteAllButton => 'Eliminar todo';

  @override
  String get entries => 'entradas';

  @override
  String get cacheEmpty => 'La caché está vacía';

  @override
  String get apiKeyNote =>
      'Registro gratuito. Datos de las agencias gubernamentales de transparencia de precios.';

  @override
  String get apiKeyFormatError =>
      'Formato inválido — se espera UUID (8-4-4-4-12)';

  @override
  String get reportThisIssue => 'Informar de este problema';

  @override
  String get reportAlreadySent => 'Ya has informado de este problema.';

  @override
  String get reportConsentTitle => '¿Informar a GitHub?';

  @override
  String get reportConsentBody =>
      'Esto abrirá una incidencia pública en GitHub con los detalles del error que se muestran abajo. No se incluyen coordenadas GPS, claves de API ni datos personales.';

  @override
  String get reportConsentConfirm => 'Abrir GitHub';

  @override
  String get reportConsentCancel => 'Cancelar';

  @override
  String get configProfileSection => 'Perfil';

  @override
  String get configActiveProfile => 'Perfil activo';

  @override
  String get configPreferredFuel => 'Combustible preferido';

  @override
  String get configCountry => 'País';

  @override
  String get configRouteSegment => 'Tramo de ruta';

  @override
  String get configApiKeysSection => 'Claves de API';

  @override
  String get configTankerkoenigKey => 'Clave de API de Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Configurada';

  @override
  String get configApiKeyCommunity => 'Predeterminada (clave de la comunidad)';

  @override
  String get searchLocationPlaceholder => 'Dirección, código postal o ciudad';

  @override
  String get configEvKey => 'Clave de API de carga de VE';

  @override
  String get configEvKeyCustom => 'Clave personalizada';

  @override
  String get configEvKeyShared => 'Predeterminada (compartida)';

  @override
  String get configCloudSyncSection => 'Sincronización en la nube';

  @override
  String get configTankSyncConnected => 'Conectado';

  @override
  String get configTankSyncDisabled => 'Desactivado';

  @override
  String get configAuthMode => 'Modo de autenticación';

  @override
  String get configAuthEmail => 'Correo electrónico (persistente)';

  @override
  String get configAuthAnonymous => 'Anónimo (solo en este dispositivo)';

  @override
  String get configDatabase => 'Base de datos';

  @override
  String get configPrivacySummary => 'Resumen de privacidad';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Los favoritos, las alertas y las estaciones ignoradas se sincronizan con tu base de datos privada\n• La posición GPS y las claves de API nunca salen de tu dispositivo\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Todos los datos se almacenan localmente solo en este dispositivo\n• No se envía ningún dato a ningún servidor\n• Las claves de API se cifran en el almacenamiento seguro del dispositivo';

  @override
  String get configAuthNoteEmail =>
      'La cuenta de correo permite el acceso desde varios dispositivos';

  @override
  String get configAuthNoteAnonymous =>
      'Cuenta anónima: los datos están vinculados a este dispositivo';

  @override
  String get configNone => 'Ninguno';

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
  String get demoModeBannerAction => 'Obtener precios en directo';

  @override
  String get sortDistance => 'Distancia';

  @override
  String get sortOpen24h => '24 h';

  @override
  String get sortRating => 'Valoración';

  @override
  String get sortPriceDistance => 'Precio/km';

  @override
  String get cheap => 'barato';

  @override
  String get expensive => 'caro';

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
  String profileSwitchedTo(String profile) {
    return 'Cambiado a $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Perfil $name creado';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Ya existe un perfil para $country — edítalo en su lugar.';
  }

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
  String get evPriceFree => 'Gratis';

  @override
  String get evPricePayAtLocation => 'Pago en el lugar';

  @override
  String get evPriceMembership => 'Se requiere membresía';

  @override
  String get evPriceIndicative => 'Precio orientativo';

  @override
  String get evPriceDeclaredByOperator =>
      'Precio orientativo declarado por el operador — verifica in situ';

  @override
  String get evPriceFranceAttribution =>
      'Precios: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Precios de OpenChargeMap sin garantía de completitud — pueden ser escasos o incompletos.';

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
  String get edit => 'Editar';

  @override
  String get fuelPricesApiKey => 'Clave API precios de combustible';

  @override
  String get evChargingApiKey => 'Clave API carga EV';

  @override
  String get openChargeMapApiKey => 'Clave API OpenChargeMap';

  @override
  String get routePlanningSection => 'Planificación de ruta';

  @override
  String get routeMinSaving => 'Ahorro mínimo';

  @override
  String get routeMinSavingOff => 'Desactivado';

  @override
  String get routeMinSavingOffCaption =>
      'Mostrando todas las estaciones encontradas en la ruta';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Solo estaciones dentro de $amount de la más barata de la ruta';
  }

  @override
  String get routeDetourBudget => 'Desvío máximo';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Mostrar estaciones hasta $km km de tu ruta directa';
  }

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
  String get noStationsAlongThisRoute =>
      'No se encontraron estaciones a lo largo de esta ruta.';

  @override
  String get fuelCostCalculator => 'Calculadora de coste de combustible';

  @override
  String get distanceKm => 'Distancia (km)';

  @override
  String get tripCost => 'Coste del viaje';

  @override
  String get fuelNeeded => 'Combustible necesario';

  @override
  String get totalCost => 'Coste total';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Distancia ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consumo ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Precio del combustible ($unit)';
  }

  @override
  String get calculatorUseMine => 'Usar';

  @override
  String get calculatorApplied => 'Aplicado';

  @override
  String get tripDetails => 'Detalles del viaje';

  @override
  String get calculatorRoundTrip => 'Ida y vuelta';

  @override
  String get roundTripTotal => 'Ida y vuelta';

  @override
  String get costPerDistance => 'Coste por km';

  @override
  String get costPerMonth => 'Coste mensual';

  @override
  String get calculatorEstimateMonthly => 'Estimar coste mensual';

  @override
  String get calculatorTripsPerMonth => 'Viajes por mes';

  @override
  String get calculatorTripsPerMonthHint => 'p. ej. 20';

  @override
  String get calculatorReset => 'Restablecer';

  @override
  String get calculatorResultPlaceholder =>
      'Introduce distancia, consumo y precio para ver el coste de tu viaje';

  @override
  String get priceHistory => 'Historial de precios';

  @override
  String get ignoredStationsLabel => 'Ignoradas';

  @override
  String get ratingsLabel => 'Valoraciones';

  @override
  String get favoritesDataCache => 'Datos de favoritos';

  @override
  String get citySearchCache => 'Búsqueda de ciudad';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count estaciones seguidas';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count configuradas';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count estaciones ocultas';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count estaciones valoradas';
  }

  @override
  String get noPriceHistory => 'Aún no hay historial de precios';

  @override
  String get noStatistics => 'No hay estadísticas disponibles';

  @override
  String get showAllFuelTypes => 'Mostrar todos los tipos de combustible';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnectTankSync => 'Desconectar TankSync';

  @override
  String get viewMyData => 'Ver mis datos';

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
  String get forgetAllSyncedTripsButton =>
      'Olvidar todos los viajes sincronizados';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      '¿Olvidar todos los viajes sincronizados?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Se eliminarán del servidor todos los resúmenes y detalles de viajes. Tu historial local de viajes en este dispositivo no se verá afectado.\n\nEsta acción no se puede deshacer.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Olvidar todos';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Todos los viajes sincronizados se han eliminado del servidor';

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
  String get syncedTrips => 'Viajes';

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
    return '$name eliminada';
  }

  @override
  String loadingRoute(String name) {
    return 'Cargando ruta: $name';
  }

  @override
  String get refreshFailed => 'Error al actualizar. Inténtalo de nuevo.';

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
      'Configura la app en unos pocos pasos rápidos.';

  @override
  String get onboardingApiKeyDescription =>
      'Regístrate para obtener una clave de API gratuita u omite este paso para explorar la app con datos de demostración.';

  @override
  String get onboardingComplete => '¡Todo listo!';

  @override
  String get onboardingCompleteHint =>
      'Puedes cambiar estos ajustes en cualquier momento desde tu perfil.';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingFinish => 'Empezar';

  @override
  String get switchToAllPricesView => 'Cambiar a la vista de todos los precios';

  @override
  String get switchToCompactView => 'Cambiar a la vista compacta';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'Sin existencias';

  @override
  String get gdprTitle => 'Tu privacidad';

  @override
  String get gdprSubtitle =>
      'Esta app respeta tu privacidad. Elige qué datos quieres compartir. Puedes cambiar estos ajustes en cualquier momento.';

  @override
  String get gdprLocationTitle => 'Acceso a la ubicación';

  @override
  String get gdprLocationDescription =>
      'Tus coordenadas se envían a la API de precios de combustible para encontrar estaciones cercanas. Los datos de ubicación nunca se almacenan en un servidor ni se usan para seguimiento.';

  @override
  String get gdprLocationShort =>
      'Encuentra estaciones de servicio cercanas usando tu ubicación';

  @override
  String get gdprErrorReportingTitle => 'Informes de errores';

  @override
  String get gdprErrorReportingDescription =>
      'Los informes de fallos anónimos ayudan a mejorar la app. No se incluye ningún dato personal. Los informes se envían a través de Sentry solo cuando está configurado.';

  @override
  String get gdprErrorReportingShort =>
      'Envía informes de fallos anónimos para mejorar la app';

  @override
  String get gdprCloudSyncTitle => 'Sincronización en la nube';

  @override
  String get gdprCloudSyncDescription =>
      'Sincroniza favoritos y alertas entre dispositivos mediante TankSync. Usa autenticación anónima. Tus datos se cifran durante la transmisión.';

  @override
  String get gdprCloudSyncShort =>
      'Sincroniza favoritos y alertas entre dispositivos';

  @override
  String get gdprLegalBasis =>
      'Base jurídica: art. 6(1)(a) del RGPD (consentimiento). Puedes retirar tu consentimiento en cualquier momento en Ajustes.';

  @override
  String get gdprContinueAll => 'Continuar con todo';

  @override
  String get gdprContinueSelected => 'Continuar con la selección';

  @override
  String get gdprSettingsHint =>
      'Puedes cambiar tus opciones de privacidad en cualquier momento.';

  @override
  String get routeSaved => '¡Ruta guardada!';

  @override
  String get routeSaveFailed => 'Error al guardar la ruta';

  @override
  String get sqlCopied => 'SQL copiado al portapapeles';

  @override
  String get connectionDataCopied => 'Datos de conexión copiados';

  @override
  String get accountDeleted => 'Cuenta eliminada. Datos locales conservados.';

  @override
  String get switchedToAnonymous => 'Se ha cambiado a una sesión anónima';

  @override
  String failedToSwitch(String error) {
    return 'Error al cambiar: $error';
  }

  @override
  String get connectedAsGuest => 'Conectado como invitado';

  @override
  String get accountCreated => '¡Cuenta creada!';

  @override
  String get signedIn => '¡Sesión iniciada!';

  @override
  String stationHidden(String name) {
    return '$name oculta';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name eliminada de favoritos';
  }

  @override
  String invalidApiKey(String error) {
    return 'Clave de API no válida: $error';
  }

  @override
  String get invalidQrCode => 'Formato de código QR no válido';

  @override
  String get invalidQrCodeTankSync =>
      'Código QR no válido: se esperaba el formato de TankSync';

  @override
  String get tankSyncConnected => '¡TankSync conectado!';

  @override
  String get syncCompleted => 'Sincronización completada: datos actualizados';

  @override
  String get deviceCodeCopied => 'Código del dispositivo copiado';

  @override
  String get undo => 'Deshacer';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Introduce un $label válido de $length dígitos';
  }

  @override
  String get freshnessAgo => 'atrás';

  @override
  String get freshnessStale => 'Obsoleto';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Actualidad de los datos: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Logotipo de $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Valorar con $count estrellas',
      one: 'Valorar con 1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordStrengthFair => 'Aceptable';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get passwordReqMinLength => 'Al menos 8 caracteres';

  @override
  String get passwordReqUppercase => 'Al menos 1 letra mayúscula';

  @override
  String get passwordReqLowercase => 'Al menos 1 letra minúscula';

  @override
  String get passwordReqDigit => 'Al menos 1 número';

  @override
  String get passwordReqSpecial => 'Al menos 1 carácter especial';

  @override
  String get passwordTooWeak => 'La contraseña no cumple todos los requisitos';

  @override
  String get brandFilterAll => 'Todas';

  @override
  String get brandFilterNoHighway => 'Sin autopista';

  @override
  String get swipeTutorialMessage =>
      'Desliza a la derecha para navegar, desliza a la izquierda para eliminar';

  @override
  String get swipeTutorialDismiss => 'Entendido';

  @override
  String get alertStatsActive => 'Activas';

  @override
  String get alertStatsToday => 'Hoy';

  @override
  String get alertStatsThisWeek => 'Esta semana';

  @override
  String get privacyDashboardTitle => 'Panel de privacidad';

  @override
  String get privacyDashboardSubtitle =>
      'Consulta, exporta o elimina tus datos';

  @override
  String get privacyDashboardBanner =>
      'Tus datos te pertenecen. Aquí puedes ver todo lo que esta app almacena, exportarlo o eliminarlo.';

  @override
  String get privacyLocalData => 'Datos en este dispositivo';

  @override
  String get privacyIgnoredStations => 'Estaciones ignoradas';

  @override
  String get privacyRatings => 'Valoraciones de estaciones';

  @override
  String get privacyPriceHistory => 'Estaciones con historial de precios';

  @override
  String get privacyProfiles => 'Perfiles de búsqueda';

  @override
  String get privacyItineraries => 'Rutas guardadas';

  @override
  String get privacyCacheEntries => 'Entradas en caché';

  @override
  String get privacyApiKey => 'Clave de API almacenada';

  @override
  String get privacyEvApiKey => 'Clave de API de VE almacenada';

  @override
  String get privacyEstimatedSize => 'Almacenamiento estimado';

  @override
  String get privacySyncedData => 'Sincronización en la nube (TankSync)';

  @override
  String get privacySyncDisabled =>
      'La sincronización en la nube está desactivada. Todos los datos permanecen solo en este dispositivo.';

  @override
  String get privacySyncMode => 'Modo de sincronización';

  @override
  String get privacySyncUserId => 'ID de usuario';

  @override
  String get privacySyncDescription =>
      'Cuando la sincronización está activada, los favoritos, las alertas, las estaciones ignoradas y las valoraciones también se almacenan en el servidor de TankSync.';

  @override
  String get privacyViewServerData => 'Ver datos del servidor';

  @override
  String get privacyExportButton => 'Exportar todos los datos como JSON';

  @override
  String get privacyExportSuccess => 'Datos exportados al portapapeles';

  @override
  String get privacyExportCsvButton => 'Exportar todos los datos como CSV';

  @override
  String get privacyExportCsvSuccess => 'Datos CSV exportados al portapapeles';

  @override
  String get savedToDownloadsFolder => 'Guardado en la carpeta Descargas';

  @override
  String get privacyDeleteButton => 'Eliminar todos los datos';

  @override
  String privacySaveErrorLog(int count) {
    return 'Guardar registro de errores ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Borrar registro de errores';

  @override
  String get privacyErrorLogCleared => 'Registro de errores borrado';

  @override
  String get privacyDeleteTitle => '¿Eliminar todos los datos?';

  @override
  String get privacyDeleteBody =>
      'Esto eliminará de forma permanente:\n\n- Todos los favoritos y datos de estaciones\n- Todos los perfiles de búsqueda\n- Todas las alertas de precios\n- Todo el historial de precios\n- Todos los datos en caché\n- Tu clave de API\n- Todos los ajustes de la app\n\nLa app se restablecerá a su estado inicial. Esta acción no se puede deshacer.';

  @override
  String get privacyDeleteConfirm => 'Eliminar todo';

  @override
  String get yes => 'Sí';

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
  String get paymentMethods => 'Métodos de pago';

  @override
  String get paymentMethodCash => 'Efectivo';

  @override
  String get paymentMethodCard => 'Tarjeta';

  @override
  String get paymentMethodContactless => 'Sin contacto';

  @override
  String get paymentMethodFuelCard => 'Tarjeta de combustible';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Pagar con $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Comparado con la media móvil de tus últimos 3 repostajes ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumo de $value L/100 km, $delta respecto a tu media móvil';
  }

  @override
  String get drivingMode => 'Modo conducción';

  @override
  String get drivingExit => 'Salir';

  @override
  String get drivingNearestStation => 'Más cercana';

  @override
  String get drivingTapToUnlock => 'Toca para desbloquear';

  @override
  String get drivingSafetyTitle => 'Aviso de seguridad';

  @override
  String get drivingSafetyMessage =>
      'No utilices la app mientras conduces. Detente en un lugar seguro antes de interactuar con la pantalla. El conductor es responsable en todo momento de la conducción segura del vehículo.';

  @override
  String get drivingSafetyAccept => 'Lo entiendo';

  @override
  String get voiceAnnouncementsTitle => 'Anuncios por voz';

  @override
  String get voiceAnnouncementsDescription =>
      'Anuncia estaciones baratas cercanas mientras conduces';

  @override
  String get voiceAnnouncementsEnabled => 'Activar anuncios por voz';

  @override
  String get voiceAnnouncementProximityRadius => 'Radio de anuncio';

  @override
  String get voiceAnnouncementCooldown => 'Intervalo de repetición';

  @override
  String get voiceAnnouncementPriceLimit => 'Precio máximo';

  @override
  String get consumptionStatsTitle => 'Estadísticas de consumo';

  @override
  String get addFillUp => 'Añadir repostaje';

  @override
  String get noFillUpsTitle => 'Aún no hay repostajes';

  @override
  String get noFillUpsSubtitle =>
      'Registra tu primer repostaje para empezar a controlar el consumo.';

  @override
  String get fillUpDate => 'Fecha';

  @override
  String get liters => 'Litros';

  @override
  String get odometerKm => 'Cuentakilómetros (km)';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get statAvgConsumption => 'Media L/100 km';

  @override
  String get statAvgCostPerKm => 'Coste medio/km';

  @override
  String get statTotalLiters => 'Litros totales';

  @override
  String get statTotalSpent => 'Gasto total';

  @override
  String get statFillUpCount => 'Repostajes';

  @override
  String get fieldRequired => 'Obligatorio';

  @override
  String get fieldInvalidNumber => 'Número no válido';

  @override
  String get carbonDashboardTitle => 'Panel de emisiones';

  @override
  String get carbonEmptyTitle => 'Aún no hay datos';

  @override
  String get carbonEmptySubtitle =>
      'Registra repostajes para ver tu panel de emisiones.';

  @override
  String get carbonSummaryTotalCost => 'Coste total';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 total';

  @override
  String get monthlyCostsTitle => 'Costes mensuales';

  @override
  String get monthlyEmissionsTitle => 'Emisiones mensuales de CO2';

  @override
  String get vehiclesTitle => 'Mis vehículos';

  @override
  String get vehiclesMenuTitle => 'Mis vehículos';

  @override
  String get vehiclesMenuSubtitle =>
      'Batería, conectores, preferencias de carga';

  @override
  String get vehiclesEmptyMessage =>
      'Añade tu coche para filtrar por conector y estimar los costes de carga.';

  @override
  String get vehiclesWizardTitle => 'Mis vehículos (opcional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Añade tu coche para rellenar automáticamente el registro de consumo y activar los filtros de conectores de VE. Puedes omitir este paso y añadir vehículos más tarde.';

  @override
  String get vehiclesWizardNoneYet => 'Aún no hay ningún vehículo configurado.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tienes $count vehículos',
      one: 'Tienes 1 vehículo',
    );
    return '$_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Omite este paso para finalizar la configuración: puedes añadir vehículos en cualquier momento desde Ajustes.';

  @override
  String get fillUpVehicleLabel => 'Vehículo';

  @override
  String get fillUpVehicleRequired => 'El vehículo es obligatorio';

  @override
  String get reportScanError => 'Informar de error de escaneo';

  @override
  String get pickStationTitle => 'Elige una estación';

  @override
  String get pickStationHelper =>
      'Empieza el repostaje desde una estación conocida para que los precios, la marca y el tipo de combustible se rellenen solos.';

  @override
  String get pickStationEmpty =>
      'Aún no tienes estaciones favoritas: añade algunas desde Buscar o Favoritos, u omite este paso y rellénalo manualmente.';

  @override
  String get pickStationSkip => 'Omitir: añadir sin estación';

  @override
  String get scanPayment => 'Escanear QR de pago';

  @override
  String get qrPaymentBeneficiary => 'Beneficiario';

  @override
  String get qrPaymentAmount => 'Importe';

  @override
  String get qrPaymentEpcTitle => 'Pago SEPA';

  @override
  String get qrPaymentEpcEmpty => 'No se ha decodificado ningún campo';

  @override
  String get qrPaymentOpenInBank => 'Abrir en la app del banco';

  @override
  String get qrPaymentLaunchFailed =>
      'No hay ninguna app disponible para abrir este código';

  @override
  String get qrPaymentUnknownTitle => 'Código no reconocido';

  @override
  String get qrPaymentCopyRaw => 'Copiar texto sin procesar';

  @override
  String get qrPaymentCopiedRaw => 'Copiado al portapapeles';

  @override
  String get qrPaymentReport => 'Informar de este escaneo';

  @override
  String get qrPaymentEpcCopied =>
      'Datos bancarios copiados: pégalos en tu app bancaria';

  @override
  String get qrScannerGuidance => 'Apunta la cámara a un código QR';

  @override
  String get qrScannerPermissionDenied =>
      'Se necesita acceso a la cámara para escanear códigos QR.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Se denegó el acceso a la cámara. Abre los ajustes para concederlo.';

  @override
  String get qrScannerRetryPermission => 'Reintentar';

  @override
  String get qrScannerOpenSettings => 'Abrir ajustes';

  @override
  String get qrScannerTimeout =>
      'No se detectó ningún código QR. Acércate o inténtalo de nuevo.';

  @override
  String get qrScannerRetry => 'Reintentar';

  @override
  String get torchOn => 'Encender el flash';

  @override
  String get torchOff => 'Apagar el flash';

  @override
  String get obdPermissionDenied =>
      'Concede el permiso de Bluetooth en los ajustes del sistema';

  @override
  String get obdPickerTitle => 'Elige un adaptador OBD2';

  @override
  String get obdPickerScanning => 'Buscando adaptadores…';

  @override
  String get obdPickerConnecting => 'Conectando…';

  @override
  String get tripRecordingTitle => 'Grabando viaje';

  @override
  String get tripSummaryTitle => 'Resumen del viaje';

  @override
  String get tripMetricDistance => 'Distancia';

  @override
  String get tripMetricSpeed => 'Velocidad';

  @override
  String get tripMetricFuelUsed => 'Combustible usado';

  @override
  String get tripMetricAvgConsumption => 'Media';

  @override
  String get tripMetricElapsed => 'Transcurrido';

  @override
  String get tripMetricOdometer => 'Cuentakilómetros';

  @override
  String get tripStop => 'Detener grabación';

  @override
  String get tripPause => 'Pausar';

  @override
  String get tripResume => 'Reanudar';

  @override
  String get tripBannerRecording => 'Grabando viaje';

  @override
  String get tripBannerPaused => 'Viaje en pausa: toca para reanudar';

  @override
  String get vehicleBaselineSectionTitle => 'Calibración de referencia';

  @override
  String get vehicleBaselineEmpty =>
      'Aún no hay muestras: inicia un viaje OBD2 para empezar a aprender el perfil de combustible de este vehículo.';

  @override
  String get vehicleBaselineProgress =>
      'Aprendido a partir de muestras en distintas situaciones de conducción.';

  @override
  String get vehicleBaselineReset =>
      'Restablecer la referencia de situaciones de conducción';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      '¿Restablecer la referencia de situaciones de conducción?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Esto borra todas las muestras aprendidas de este vehículo. Volverás a los valores predeterminados de arranque en frío hasta que nuevos viajes vuelvan a llenar el perfil.';

  @override
  String get vehicleBaselineShowDetails => 'Mostrar desglose por situación';

  @override
  String get vehicleBaselineHideDetails => 'Ocultar desglose por situación';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Aún no detectado: $situations. Estas situaciones de conducción todavía tienen 0 muestras, por lo que la línea base está incompleta.';
  }

  @override
  String get vehicleAdapterSectionTitle => 'Adaptador OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'No hay ningún adaptador emparejado. Empareja uno para que la app pueda volver a conectarse automáticamente la próxima vez.';

  @override
  String get vehicleAdapterUnnamed => 'Adaptador desconocido';

  @override
  String get vehicleAdapterPair => 'Emparejar adaptador';

  @override
  String get vehicleAdapterForget => 'Olvidar adaptador';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String get achievementFirstTrip => 'Primer viaje';

  @override
  String get achievementFirstTripDesc => 'Graba tu primer viaje OBD2.';

  @override
  String get achievementFirstFillUp => 'Primer repostaje';

  @override
  String get achievementFirstFillUpDesc => 'Registra tu primer repostaje.';

  @override
  String get achievementTenTrips => '10 viajes';

  @override
  String get achievementTenTripsDesc => 'Graba 10 viajes OBD2.';

  @override
  String get achievementZeroHarsh => 'Conducción suave';

  @override
  String get achievementZeroHarshDesc =>
      'Completa un viaje de 10 km o más sin frenadas ni acelerones bruscos.';

  @override
  String get achievementEcoWeek => 'Semana ecológica';

  @override
  String get achievementEcoWeekDesc =>
      'Conduce 7 días seguidos con al menos un viaje suave cada día.';

  @override
  String get achievementPriceWin => 'Buen precio';

  @override
  String get achievementPriceWinDesc =>
      'Registra un repostaje que mejore en un 5 % o más la media de 30 días de la estación.';

  @override
  String get syncBaselinesToggleTitle =>
      'Compartir perfiles de vehículo aprendidos';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Sube las referencias de consumo por vehículo para que un segundo dispositivo pueda reutilizarlas.';

  @override
  String get obd2StatusConnected => 'Adaptador OBD2: conectado';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptador OBD2: se necesita el permiso de Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Listo para grabar un viaje.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Concede el permiso de Bluetooth en los ajustes del sistema para reconectar automáticamente.';

  @override
  String get obd2StatusNoAdapter => 'No hay ningún adaptador emparejado';

  @override
  String get obd2StatusForget => 'Olvidar adaptador';

  @override
  String get tripHistoryTitle => 'Historial de viajes';

  @override
  String get tripHistoryEmptyTitle => 'Aún no hay viajes';

  @override
  String get tripHistoryUnknownDate => 'Fecha desconocida';

  @override
  String get situationIdle => 'Ralentí';

  @override
  String get situationStopAndGo => 'Parada y arranque';

  @override
  String get situationUrban => 'Urbano';

  @override
  String get situationHighway => 'Autopista';

  @override
  String get situationDecel => 'Desacelerando';

  @override
  String get situationClimbing => 'Subiendo / con carga';

  @override
  String get situationColdStart => 'Arranque en frío';

  @override
  String get situationSustainedLoad => 'Carga sostenida / remolque';

  @override
  String get situationPartialDecel => 'Inercia / deceleración';

  @override
  String get situationHardAccel => 'Aceleración fuerte';

  @override
  String get situationFuelCut => 'Corte de combustible: deceleración';

  @override
  String get tripSaveRecording => 'Guardar viaje';

  @override
  String get tripSummaryAutoSaved => 'Viaje guardado automáticamente';

  @override
  String get tripSummaryDone => 'Hecho';

  @override
  String get tripSummaryDelete => 'Eliminar este viaje';

  @override
  String get vehicleFuelNotSet => 'Sin definir';

  @override
  String get wizardVehicleDefaultBadge => 'Predeterminado';

  @override
  String get wizardProfileChoiceHint =>
      'Elige cómo quieres usar la app. Puedes cambiarlo más tarde en Ajustes.';

  @override
  String get wizardProfileChoiceFooter =>
      'Puedes cambiar tu elección en cualquier momento desde Ajustes → Modo de uso.';

  @override
  String get wizardProfileBasicName => 'Básico';

  @override
  String get wizardProfileBasicDescription =>
      'Los precios de combustible y carga de VE más baratos cerca de ti. Favoritos y alertas de precios.';

  @override
  String get wizardProfileMediumName => 'Intermedio';

  @override
  String get wizardProfileMediumDescription =>
      'Todo lo del modo Básico, además del seguimiento manual de tus repostajes de combustible y cargas de VE.';

  @override
  String get wizardProfileFullName => 'Completo';

  @override
  String get wizardProfileFullDescription =>
      'Todo lo del modo Intermedio, además de la grabación automática de viajes por OBD2, las puntuaciones de conducción y las tarjetas de fidelización.';

  @override
  String get wizardProfileCustomName => 'Personalizado';

  @override
  String get useModeSectionHint =>
      'Adapta la app a cómo la usas realmente. Al elegir un preajuste se activa el conjunto de funciones correspondiente.';

  @override
  String get useModeCustomSettingsDescription =>
      'Tu combinación de funciones no coincide con ningún preajuste. Elige uno arriba para sobrescribirla o sigue personalizando funciones individuales en la sección de abajo.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Modo de uso definido como $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Vehículo predeterminado (opcional)';

  @override
  String get profileDefaultVehicleNone => 'Sin predeterminado';

  @override
  String get profileFuelFromVehicleHint =>
      'El tipo de combustible se deriva de tu vehículo predeterminado. Quita el vehículo para elegir un combustible directamente.';

  @override
  String get consumptionNoVehicleTitle => 'Añade primero un vehículo';

  @override
  String get consumptionNoVehicleBody =>
      'Los repostajes se atribuyen a un vehículo. Añade tu coche para empezar a registrar el consumo.';

  @override
  String get vehicleAdd => 'Añadir vehículo';

  @override
  String get vehicleAddTitle => 'Añadir vehículo';

  @override
  String get vehicleEditTitle => 'Editar vehículo';

  @override
  String get vehicleDeleteTitle => '¿Eliminar vehículo?';

  @override
  String vehicleDeleteMessage(String name) {
    return '¿Quitar «$name» de tus perfiles?';
  }

  @override
  String get vehicleNameLabel => 'Nombre';

  @override
  String get vehicleNameHint => 'p. ej. Mi Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustión';

  @override
  String get vehicleTypeHybrid => 'Híbrido';

  @override
  String get vehicleTypeEv => 'Eléctrico';

  @override
  String get vehicleEvSectionTitle => 'Eléctrico';

  @override
  String get vehicleCombustionSectionTitle => 'Combustión';

  @override
  String get vehicleBatteryLabel => 'Capacidad de la batería (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Potencia máxima de carga (kW)';

  @override
  String get vehicleConnectorsLabel => 'Conectores compatibles';

  @override
  String get vehicleMinSocLabel => 'SoC mín. %';

  @override
  String get vehicleMaxSocLabel => 'SoC máx. %';

  @override
  String get vehicleTankLabel => 'Capacidad del depósito (L)';

  @override
  String get vehiclePowerLabel => 'Potencia del motor (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps CV';
  }

  @override
  String get vehiclePreferredFuelLabel => 'Combustible preferido';

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
  String get connectorThreePin => '3 clavijas';

  @override
  String get evShowOnMap => 'Mostrar estaciones de VE';

  @override
  String get evAvailableOnly => 'Solo disponibles';

  @override
  String get evMinPower => 'Potencia mín.';

  @override
  String get evStatusAvailable => 'Disponible';

  @override
  String get evStatusOccupied => 'Ocupado';

  @override
  String get evStatusOutOfOrder => 'Fuera de servicio';

  @override
  String get evStatusPartial => 'Disponibilidad parcial';

  @override
  String get openOnlyFilter => 'Solo abiertas';

  @override
  String get saveAsDefaults => 'Guardar como mis valores predeterminados';

  @override
  String get criteriaSavedToProfile => 'Guardado como valores predeterminados';

  @override
  String get updatingFavorites => 'Actualizando tus favoritos...';

  @override
  String get fetchingLatestPrices => 'Obteniendo los últimos precios';

  @override
  String get noDataAvailable => 'Sin datos';

  @override
  String get searchToSeeMap => 'Busca para ver estaciones en el mapa';

  @override
  String get evPowerAny => 'Cualquiera';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Perfil';

  @override
  String get sectionLocation => 'Ubicación';

  @override
  String get sectionPrivacyData => 'Privacidad y datos';

  @override
  String get sectionAdvancedDeveloper => 'Avanzado y desarrollador';

  @override
  String get tooltipBack => 'Atrás';

  @override
  String get tooltipClose => 'Cerrar';

  @override
  String get tooltipShare => 'Compartir';

  @override
  String get tooltipClearSearch => 'Borrar el texto de búsqueda';

  @override
  String get minimalDriveInstantConsumption => 'Consumo instantáneo';

  @override
  String get minimalDriveBehaviour => 'Estilo de conducción';

  @override
  String get coachingShiftUp => 'Subir marcha';

  @override
  String get coachingShiftDown => 'Bajar marcha';

  @override
  String get coachingEasePedal => 'Suelta acelerador';

  @override
  String get coachingVoiceHardAcceleration => 'Suaviza el acelerador';

  @override
  String get coachingVoiceHarshBraking => 'Intenta frenar con más suavidad';

  @override
  String get coachingVoiceShiftUp => 'Sube una marcha para ahorrar combustible';

  @override
  String get coachingVoiceShiftDown =>
      'Baja una marcha, el motor está forzando';

  @override
  String get coachingVoiceEasePedal =>
      'Suelta el pedal para reducir el consumo';

  @override
  String get coachingVoiceLiftOff => 'Suelta el acelerador y rueda por inercia';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Mira más adelante y levanta el pie antes';

  @override
  String get coachingVoiceSmoothAccel => 'Acelera con más suavidad';

  @override
  String get coachingVoiceSharpCorner => 'Toma las curvas un poco más suave';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Frenazo muy fuerte: deja más distancia';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Aceleración muy brusca: eso quema combustible de verdad';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Curva muy cerrada: entra despacio, sal con suavidad';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount maniobras bruscas.',
      one: 'Una maniobra brusca.',
      zero: 'Suave y sin brusquedades.',
    );
    return 'Viaje guardado: $distanceKm kilómetros, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litros a los 100 kilómetros';
  }

  @override
  String get voiceCoachingSettingTitle => 'Asistencia de conducción por voz';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Recibe consejos en voz alta mientras conduces — aceleración brusca, frenada fuerte y sugerencias de cambio de marcha';

  @override
  String get tooltipUseGps => 'Usar la ubicación GPS';

  @override
  String get tooltipShowPassword => 'Mostrar contraseña';

  @override
  String get tooltipHidePassword => 'Ocultar contraseña';

  @override
  String get evConnectorsLabel => 'Conectores disponibles';

  @override
  String get evConnectorsNone => 'Sin información de conectores';

  @override
  String get switchToEmail => 'Cambiar a correo electrónico';

  @override
  String get switchToEmailSubtitle =>
      'Conserva los datos y añade el inicio de sesión desde otros dispositivos';

  @override
  String get switchToAnonymousAction => 'Cambiar a anónimo';

  @override
  String get switchToAnonymousSubtitle =>
      'Conserva los datos locales y usa una nueva sesión anónima';

  @override
  String get linkDevice => 'Vincular dispositivo';

  @override
  String get shareDatabase => 'Compartir base de datos';

  @override
  String get disconnectAction => 'Desconectar';

  @override
  String get disconnectSubtitle =>
      'Detener la sincronización (se conservan los datos locales)';

  @override
  String get deleteAccountAction => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle =>
      'Elimina todos los datos del servidor de forma permanente';

  @override
  String get localOnly => 'Solo local';

  @override
  String get localOnlySubtitle =>
      'Opcional: sincroniza favoritos, alertas y valoraciones entre dispositivos';

  @override
  String get tankSyncSchemaOutdatedTitle =>
      'La base de datos en la nube necesita una actualización';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'Tu esquema de TankSync autoalojado está desactualizado y algunos datos no pueden sincronizarse. Abre el asistente de sincronización y ejecuta el SQL de actualización en tu proyecto de Supabase.';

  @override
  String get setupCloudSync => 'Configurar la sincronización en la nube';

  @override
  String get disconnectTitle => '¿Desconectar TankSync?';

  @override
  String get disconnectBody =>
      'La sincronización en la nube se desactivará. Tus datos locales (favoritos, alertas, historial) se conservan en este dispositivo. Los datos del servidor no se eliminan.';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountBody =>
      'Esto elimina de forma permanente todos tus datos del servidor (favoritos, alertas, valoraciones, rutas). Los datos locales de este dispositivo se conservan.\n\nEsto no se puede deshacer.';

  @override
  String get switchToAnonymousTitle => '¿Cambiar a anónimo?';

  @override
  String get switchToAnonymousBody =>
      'Se cerrará tu sesión de la cuenta de correo y continuarás con una nueva sesión anónima.\n\nTus datos locales (favoritos, alertas) se conservan en este dispositivo y se sincronizarán con la nueva cuenta anónima.';

  @override
  String get switchAction => 'Cambiar';

  @override
  String get helpBannerCriteria =>
      'Los valores predeterminados de tu perfil ya están rellenados. Ajusta los criterios de abajo para afinar tu búsqueda.';

  @override
  String get helpBannerAlerts =>
      'Define un umbral de precio para una estación. Recibirás un aviso cuando los precios bajen por debajo de él. Las comprobaciones se ejecutan cada 30 minutos.';

  @override
  String get helpBannerConsumption =>
      'Registra cada repostaje para controlar tu consumo real y tu huella de CO₂. Desliza a la izquierda para eliminar una entrada.';

  @override
  String get helpBannerVehicles =>
      'Añade tus vehículos para que los repostajes y las preferencias de combustible se rellenen correctamente. El primer vehículo pasa a ser el predeterminado.';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get onboardingPreferencesTitle => 'Tus preferencias';

  @override
  String get onboardingZipHelper => 'Se usa cuando el GPS no está disponible';

  @override
  String get onboardingRadiusHelper => 'Mayor radio = más resultados';

  @override
  String get onboardingPrivacy =>
      'Estos ajustes se almacenan solo en tu dispositivo y nunca se comparten.';

  @override
  String get onboardingLandingTitle => 'Pantalla de inicio';

  @override
  String get onboardingLandingHint =>
      'Elige qué pantalla se abre al iniciar la app.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Mantente fuera de la app, pero no la cierres.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Abre Sparkilo una vez después de cada reinicio.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Apple activa Sparkilo solo después de que la hayas abierto al menos una vez desde que el teléfono se reinició. A partir de entonces, tus viajes se graban automáticamente.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'No deslices Sparkilo para cerrarla en el selector de apps.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '«Forzar el cierre» le indica a iOS que deje de reiniciar la app. Tus viajes dejarán de grabarse hasta que vuelvas a abrir Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Cuando iOS te pida la ubicación «Siempre», acéptala.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'El sistema de respaldo que graba tu viaje cuando el adaptador OBD2 va lento necesita la ubicación en segundo plano. Nunca la compartimos.';

  @override
  String get scanReceipt => 'Escanear recibo';

  @override
  String get brandFilterHighway => 'Autopista';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Privado';

  @override
  String get ratingModeShared => 'Compartido';

  @override
  String get ratingDescLocal =>
      'Valoraciones guardadas solo en este dispositivo';

  @override
  String get ratingDescPrivate =>
      'Sincronizadas con tu base de datos (no visibles para otros)';

  @override
  String get ratingDescShared =>
      'Visibles para todos los usuarios de tu base de datos';

  @override
  String get errorNoEvApiKey =>
      'No se ha configurado la clave de API de OpenChargeMap. Añade una en Ajustes para buscar estaciones de carga de VE.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'El proveedor de datos ($host) está usando un certificado TLS caducado o no válido. La app no puede cargar datos de esta fuente hasta que el proveedor lo solucione. Ponte en contacto con $host.';
  }

  @override
  String get offlineLabel => 'Sin conexión';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed no disponible. Usando $current.';
  }

  @override
  String get errorTitleApiKey => 'Se requiere clave de API';

  @override
  String get errorTitleLocation => 'Ubicación no disponible';

  @override
  String get errorHintNoStations =>
      'Prueba a aumentar el radio de búsqueda o busca en otra ubicación.';

  @override
  String get errorHintApiKey => 'Configura tu clave de API en Ajustes.';

  @override
  String get errorHintConnection =>
      'Comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get errorHintRouting =>
      'Error al calcular la ruta. Comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get errorHintFallback =>
      'Inténtalo de nuevo o busca por código postal o nombre de ciudad.';

  @override
  String get alertsLoadErrorTitle => 'No se pudieron cargar tus alertas';

  @override
  String get detailsLabel => 'Detalles';

  @override
  String get remove => 'Eliminar';

  @override
  String get showKey => 'Mostrar clave';

  @override
  String get hideKey => 'Ocultar clave';

  @override
  String get syncOptionalTitle => 'TankSync es opcional';

  @override
  String get syncOptionalDescription =>
      'Tu app funciona por completo sin sincronización en la nube. TankSync te permite sincronizar favoritos, alertas y valoraciones entre dispositivos mediante Supabase (con plan gratuito disponible).';

  @override
  String get syncHowToConnectQuestion => '¿Cómo quieres conectarte?';

  @override
  String get syncCreateOwnTitle => 'Crear mi propia base de datos';

  @override
  String get syncCreateOwnSubtitle =>
      'Proyecto gratuito de Supabase: te guiaremos paso a paso';

  @override
  String get syncJoinExistingTitle => 'Unirse a una base de datos existente';

  @override
  String get syncJoinExistingSubtitle =>
      'Escanea el código QR del propietario de la base de datos o pega las credenciales';

  @override
  String get syncChooseAccountType => 'Elige tu tipo de cuenta';

  @override
  String get syncAccountTypeAnonymous => 'Anónima';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Instantánea, sin necesidad de correo. Los datos están vinculados a este dispositivo.';

  @override
  String get syncAccountTypeEmail => 'Cuenta de correo';

  @override
  String get syncAccountTypeEmailDesc =>
      'Inicia sesión desde cualquier dispositivo. Recupera tus datos si pierdes el teléfono.';

  @override
  String get syncHaveAccountSignIn => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get syncCreateNewAccount => 'Crear cuenta nueva';

  @override
  String get syncTestConnection => 'Probar conexión';

  @override
  String get syncTestingConnection => 'Probando...';

  @override
  String get syncConnectButton => 'Conectar';

  @override
  String get syncConnectingButton => 'Conectando...';

  @override
  String get syncDatabaseReady => '¡Base de datos lista!';

  @override
  String get syncDatabaseNeedsSetup =>
      'La base de datos necesita configuración';

  @override
  String get syncTableStatusOk => 'Correcto';

  @override
  String get syncTableStatusMissing => 'Falta';

  @override
  String get syncSqlEditorInstructions =>
      'Copia el SQL de abajo y ejecútalo en tu editor SQL de Supabase (Dashboard → SQL Editor → New Query → Pegar → Run)';

  @override
  String get syncCopySqlButton => 'Copiar SQL al portapapeles';

  @override
  String get syncRecheckSchemaButton => 'Volver a comprobar el esquema';

  @override
  String get syncSchemaOutdated =>
      'Tu esquema de TankSync está desactualizado: vuelve a ejecutar el SQL de configuración de abajo para activar las últimas funciones sincronizadas.';

  @override
  String get syncDoneButton => 'Hecho';

  @override
  String syncSignedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get syncEmailDescription =>
      'Tus datos se sincronizan en todos los dispositivos con este correo.';

  @override
  String get syncSwitchToAnonymousTitle => 'Cambiar a anónimo';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continúa sin correo, con una nueva sesión anónima';

  @override
  String get syncGuestDescription => 'Anónima, sin necesidad de correo.';

  @override
  String get syncOrDivider => 'o';

  @override
  String get syncHowToSyncQuestion => '¿Cómo quieres sincronizar?';

  @override
  String get syncOfflineDescription =>
      'Tu app funciona por completo sin conexión. La sincronización en la nube es opcional.';

  @override
  String get syncModeCommunityTitle => 'Comunidad Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Base de datos compartida gestionada por el desarrollador — abajo ves qué se sincroniza';

  @override
  String get syncModePrivateTitle => 'Base de datos privada';

  @override
  String get syncModePrivateSubtitle =>
      'Tu propio Supabase: control total de los datos';

  @override
  String get syncModeGroupTitle => 'Unirse a un grupo';

  @override
  String get syncModeGroupSubtitle =>
      'Base de datos compartida con familia o amigos';

  @override
  String get syncPrivacyShared => 'Compartido';

  @override
  String get syncPrivacyPrivate => 'Privado';

  @override
  String get syncPrivacyGroup => 'Grupo';

  @override
  String get syncStayOfflineButton => 'Seguir sin conexión';

  @override
  String get syncSuccessTitle => '¡Conexión correcta!';

  @override
  String get syncSuccessDescription =>
      'Tus datos se sincronizarán automáticamente a partir de ahora.';

  @override
  String get syncWizardTitleConnect => 'Conectar TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Tu base de datos';

  @override
  String get syncSetupTitleJoinGroup => 'Unirse a un grupo';

  @override
  String get syncSetupTitleAccount => 'Tu cuenta';

  @override
  String get syncWizardBack => 'Atrás';

  @override
  String get syncWizardNext => 'Siguiente';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Crear un proyecto de Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Toca «Abrir Supabase» abajo\n2. Crea una cuenta gratuita (si no tienes una)\n3. Haz clic en «New Project»\n4. Elige un nombre y una región\n5. Espera ~2 minutos a que arranque';

  @override
  String get syncWizardOpenSupabase => 'Abrir Supabase';

  @override
  String get syncWizardEnableAnonTitle =>
      'Activar los inicios de sesión anónimos';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. En tu panel de Supabase:\n   Authentication → Providers\n2. Busca «Anonymous Sign-ins»\n3. Actívalo\n4. Haz clic en «Save»';

  @override
  String get syncWizardOpenAuthSettings => 'Abrir los ajustes de autenticación';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copia tus credenciales';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Ve a Settings → API en tu panel\n2. Copia la «Project URL»\n3. Copia la clave «anon public»\n4. Pégalas abajo';

  @override
  String get syncWizardOpenApiSettings => 'Abrir los ajustes de la API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL de Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://tu-proyecto.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Unirse a una base de datos existente';

  @override
  String get syncWizardScanQrCode => 'Escanear código QR';

  @override
  String get syncWizardAskOwnerQr =>
      'Pide al propietario de la base de datos que te muestre su código QR\n(Ajustes → TankSync → Compartir)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Pide al propietario de la base de datos que muestre su código QR';

  @override
  String get syncWizardEnterManuallyTitle => 'Introducir manualmente';

  @override
  String get syncWizardOrEnterManually => 'o introdúcelas manualmente';

  @override
  String get syncWizardUrlHelperText =>
      'Los espacios y saltos de línea se eliminan automáticamente';

  @override
  String get syncCredentialsPrivateHint =>
      'Introduce las credenciales de tu proyecto de Supabase. Las encontrarás en tu panel, en Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL de la base de datos';

  @override
  String get syncCredentialsAccessKeyLabel => 'Clave de acceso';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authPleaseEnterEmail => 'Introduce tu correo electrónico';

  @override
  String get authInvalidEmail => 'Dirección de correo no válida';

  @override
  String get authPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get authConnectAnonymously => 'Conectar de forma anónima';

  @override
  String get authCreateAccountAndConnect => 'Crear cuenta y conectar';

  @override
  String get authSignInAndConnect => 'Iniciar sesión y conectar';

  @override
  String get authAnonymousSegment => 'Anónima';

  @override
  String get authEmailSegment => 'Correo';

  @override
  String get authAnonymousDescription =>
      'Acceso instantáneo, sin necesidad de correo. Los datos están vinculados a este dispositivo.';

  @override
  String get authEmailDescription =>
      'Inicia sesión desde cualquier dispositivo. Recupera tus datos si pierdes el teléfono.';

  @override
  String get authSyncAcrossDevices =>
      'Sincroniza los datos automáticamente en todos tus dispositivos.';

  @override
  String get authNewHereCreateAccount => '¿Eres nuevo? Crea una cuenta';

  @override
  String get linkDeviceScreenTitle => 'Vincular dispositivo';

  @override
  String get linkDeviceThisDeviceLabel => 'Este dispositivo';

  @override
  String get linkDeviceShareCodeHint =>
      'Comparte este código con tu otro dispositivo:';

  @override
  String get linkDeviceNotConnected => 'Sin conexión';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copiar código';

  @override
  String get linkDeviceImportSectionTitle => 'Importar desde otro dispositivo';

  @override
  String get linkDeviceImportDescription =>
      'Introduce el código del dispositivo de tu otro dispositivo para importar sus favoritos, alertas, vehículos y registro de consumo. Cada dispositivo conserva su propio perfil y valores predeterminados.';

  @override
  String get linkDeviceCodeFieldLabel => 'Código del dispositivo';

  @override
  String get linkDeviceCodeFieldHint => 'Pega el UUID del otro dispositivo';

  @override
  String get linkDeviceImportButton => 'Importar datos';

  @override
  String get linkDeviceHowItWorksTitle => 'Cómo funciona';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. En el dispositivo A: copia el código del dispositivo de arriba\n2. En el dispositivo B: pégalo en el campo «Código del dispositivo»\n3. Toca «Importar datos» para combinar favoritos, alertas, vehículos y registros de consumo\n4. Ambos dispositivos tendrán todos los datos combinados\n\nCada dispositivo conserva su propia identidad anónima y su propio perfil (combustible preferido, vehículo predeterminado, pantalla de inicio). Los datos se combinan, no se transfieren.';

  @override
  String get vehicleSetActive => 'Marcar como activo';

  @override
  String get swipeHide => 'Ocultar';

  @override
  String get yourRating => 'Tu valoración';

  @override
  String get noStorageUsed => 'No se usa almacenamiento';

  @override
  String get aboutReportBug => 'Informar de un error / Sugerir una función';

  @override
  String get aboutSupportProject => 'Apoya este proyecto';

  @override
  String get aboutSupportDescription =>
      'Esta app es gratuita, de código abierto y sin anuncios. Si te resulta útil, considera apoyar al desarrollador.';

  @override
  String get reportIssueTitle => 'Informar de un problema';

  @override
  String get enterCorrection => 'Introduce la corrección';

  @override
  String get reportNoBackendAvailable =>
      'No se pudo enviar el informe: no hay ningún servicio de informes configurado para este país. Activa TankSync en Ajustes para enviar informes de la comunidad.';

  @override
  String get correctName => 'Corregir el nombre de la estación';

  @override
  String get correctAddress => 'Corregir la dirección';

  @override
  String get wrongE85Price => 'Precio de E85 incorrecto';

  @override
  String get wrongE98Price => 'Precio de Super 98 incorrecto';

  @override
  String get wrongLpgPrice => 'Precio de GLP incorrecto';

  @override
  String get wrongStationName => 'Nombre de la estación incorrecto';

  @override
  String get wrongStationAddress => 'Dirección incorrecta';

  @override
  String get independentStation => 'Estación independiente';

  @override
  String get serviceRemindersSection => 'Recordatorios de mantenimiento';

  @override
  String get serviceRemindersEmpty =>
      'Aún no hay recordatorios: elige un preajuste arriba.';

  @override
  String get addServiceReminder => 'Añadir recordatorio';

  @override
  String get serviceReminderPresetOil => 'Aceite (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Cambio de aceite';

  @override
  String get serviceReminderPresetTires => 'Neumáticos (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Neumáticos';

  @override
  String get serviceReminderPresetInspection => 'Revisión (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Revisión';

  @override
  String get serviceReminderLabel => 'Etiqueta';

  @override
  String get serviceReminderInterval => 'Intervalo (km)';

  @override
  String get serviceReminderLastService => 'Último mantenimiento';

  @override
  String get serviceReminderMarkDone => 'Marcar como hecho';

  @override
  String get serviceReminderDueTitle => 'Mantenimiento pendiente';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label toca hacerlo: $kmOver km por encima del intervalo.';
  }

  @override
  String serviceReminderDueNowBody(String label) {
    return '$label toca ahora.';
  }

  @override
  String get vinConfirmTitle => '¿Es este tu coche?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$make $model $year — $displacement L, $cylinders cil., $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Información parcial (sin conexión). Puedes editarla abajo.';

  @override
  String get vinDecodeError => 'No se pudo decodificar este VIN';

  @override
  String get vinInvalidFormat => 'Formato de VIN no válido';

  @override
  String get obd2PauseBannerTitle =>
      'Conexión OBD2 perdida: grabación en pausa';

  @override
  String get obd2PauseBannerResume => 'Reanudar grabación';

  @override
  String get obd2PauseBannerEnd => 'Finalizar grabación';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Grabando con GPS — OBD2 reconectando';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'Grabando con GPS: esperando al adaptador OBD2';

  @override
  String get alertsStationSectionTitle => 'Alertas de gasolinera';

  @override
  String get alertsStationAdd => 'Añadir una alerta de gasolinera';

  @override
  String get alertsRadiusSectionTitle => 'Alertas por radio';

  @override
  String get alertsRadiusAdd => 'Añadir alerta por radio';

  @override
  String get alertsRadiusEmptyTitle => 'Aún no hay alertas por radio';

  @override
  String get alertsRadiusEmptyCta => 'Crear una alerta por radio';

  @override
  String get alertsRadiusCreateTitle => 'Crear alerta por radio';

  @override
  String get alertsRadiusLabelHint => 'Etiqueta (p. ej. Diésel casa)';

  @override
  String get alertsRadiusFuelType => 'Tipo de combustible';

  @override
  String get alertsRadiusKm => 'Radio (km)';

  @override
  String get alertsRadiusCenterGps => 'Usar mi ubicación';

  @override
  String get alertsRadiusCenterPostalCode => 'Código postal';

  @override
  String get alertsRadiusSave => 'Guardar';

  @override
  String get alertsRadiusCancel => 'Cancelar';

  @override
  String radiusAlertDeleted(String name) {
    return 'Alerta de radio \"$name\" eliminada';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 conectado: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Emparejar un adaptador OBD2';

  @override
  String get fillUpSavedSnackbar => 'Repostaje guardado';

  @override
  String get notFoundTitle => 'Página no encontrada';

  @override
  String notFoundBody(String location) {
    return 'No se ha encontrado «$location».';
  }

  @override
  String get notFoundHomeButton => 'Inicio';

  @override
  String get consumptionTabHiddenNotice =>
      'La pestaña de Consumo se ha ocultado según los ajustes de tu perfil.';

  @override
  String get swipeBetweenTabsHint =>
      'Consejo: desliza a la izquierda o a la derecha para cambiar de pestaña.';

  @override
  String get discardChangesTitle => '¿Descartar los cambios?';

  @override
  String get discardChangesBody =>
      'Tienes cambios sin guardar. Si sales ahora, se descartarán.';

  @override
  String get discardChangesConfirm => 'Descartar';

  @override
  String get discardChangesKeepEditing => 'Seguir editando';

  @override
  String get tankSyncSectionSubtitle =>
      'Sincronización en la nube entre tus dispositivos';

  @override
  String get mapUnavailable => 'Mapa no disponible';

  @override
  String get routeNameHintExample => 'p. ej. París → Lyon';

  @override
  String get priceStatsCurrent => 'Actual';

  @override
  String get tankerkoenigApiKeyLabel => 'Clave de API de Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Clave de API de OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Toca para actualizar la posición GPS';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get obd2ErrorPermissionDenied =>
      'Se requiere permiso de Bluetooth para conectar con un adaptador OBD2.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Activa el Bluetooth e inténtalo de nuevo.';

  @override
  String get obd2ErrorScanTimeout =>
      'No se encontró ningún adaptador OBD2 cerca. Asegúrate de que esté conectado y encendido.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'El adaptador OBD2 no respondió. Pon el contacto e inténtalo de nuevo.';

  @override
  String get obd2ErrorEngineOff =>
      'Sin datos del vehículo: arranca el motor e inténtalo de nuevo.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'El adaptador OBD2 envió una respuesta no reconocida. Puede ser incompatible: prueba con otro adaptador.';

  @override
  String get obd2ErrorDisconnected =>
      'El adaptador OBD2 se desconectó. Vuelve a conectarlo e inténtalo de nuevo.';

  @override
  String get obd2ErrorPairingRequired =>
      'El adaptador necesita emparejamiento Bluetooth. Desconéctalo, vuelve a conectarlo y reintenta antes de 5 minutos.';

  @override
  String get onboardingExploreDemoData => 'Explorar con datos de demostración';

  @override
  String get achievementSmoothDriver => 'Racha suave';

  @override
  String get achievementSmoothDriverDesc =>
      'Conduce 5 viajes seguidos con una puntuación de conducción suave de 80 o más.';

  @override
  String get achievementColdStartAware => 'Consciente del arranque en frío';

  @override
  String get achievementColdStartAwareDesc =>
      'Mantén el coste de combustible de arranque en frío de todo un mes por debajo del 2 % del total: combina los trayectos cortos.';

  @override
  String get achievementHighwayMaster => 'Maestro de autopista';

  @override
  String get achievementHighwayMasterDesc =>
      'Completa un viaje de más de 30 km a velocidad constante con una puntuación de conducción suave de 90 o más.';

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
    return '$price $currency (objetivo: $target $currency)';
  }

  @override
  String velocityAlertNotificationTitle(String fuelLabel) {
    return '$fuelLabel bajó en gasolineras cercanas';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count gasolineras bajaron hasta $cents¢ en la última hora';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count gasolineras ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count más';
  }

  @override
  String alertsLastChecked(String when) {
    return 'Última comprobación: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Los precios aún no se han comprobado en segundo plano';

  @override
  String get alertsIosBestEffortNote =>
      'En iPhone, la comprobación de alertas es de mejor esfuerzo: iOS decide cuándo la app puede consultar precios en segundo plano, así que una alerta puede llegar tarde o, a veces, no llegar. Abrir la app siempre ejecuta una comprobación nueva.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Precio objetivo ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Umbral ($currency/L)';
  }

  @override
  String get approachOverlaySection =>
      'Superposición al acercarse a una estación';

  @override
  String get approachRadiusLabel => 'Radio';

  @override
  String approachRadiusCaption(String km) {
    return 'La superposición crece y muestra el precio cuando estás a menos de $km km de una gasolinera';
  }

  @override
  String get approachPriceModeLabel => 'Mostrar precio de';

  @override
  String get approachPriceModeNearest => 'Estación más cercana';

  @override
  String get approachPriceModeCheapestInRadius => 'Más barata del radio';

  @override
  String get approachMinPollLabel => 'Actualización mín.';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Mínimo entre actualizaciones de la estación más cercana (más rápido a velocidad, nunca menor que $seconds s)';
  }

  @override
  String get approachTestSimulateButton =>
      'Probar superposición de aproximación';

  @override
  String get approachTestStopButton => 'Detener prueba';

  @override
  String approachTestActiveCaption(String station) {
    return 'Prueba activa — la superposición muestra el precio de $station';
  }

  @override
  String get approachTestUnavailable =>
      'Añade una gasolinera favorita para probar la superposición de aproximación';

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximidad $percent%';
  }

  @override
  String get pipTapToRestore => 'Toca para abrir la app completa';

  @override
  String get authErrorNoNetwork => 'Sin conexión de red. Inténtalo más tarde.';

  @override
  String get authErrorInvalidCredentials =>
      'Correo o contraseña no válidos. Comprueba tus credenciales.';

  @override
  String get authErrorUserAlreadyExists =>
      'Este correo ya está registrado. Prueba a iniciar sesión.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Revisa tu correo y confirma tu cuenta primero.';

  @override
  String get authErrorGeneric => 'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authLinkEmailTitle => 'Vincular un correo';

  @override
  String get authLinkEmailSubtitle =>
      'Vincula un correo para que tus datos se sincronicen entre dispositivos. Tus favoritos y viajes actuales se quedan en esta cuenta.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Estás usando una cuenta de invitado ($idPrefix…). Vincula un correo para que tus favoritos y viajes se sincronicen con tus otros dispositivos.';
  }

  @override
  String get authConfirmationPending =>
      'Casi listo: revisa tu correo y pulsa el enlace para terminar de vincularlo. Tus datos ya están guardados en esta cuenta.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Ubicación en segundo plano: solo para la grabación automática';

  @override
  String get autoRecordConsentExplanationTitle => 'Acerca de este permiso';

  @override
  String get autoRecordConsentExplanationBody =>
      'La grabación automática necesita la ubicación en segundo plano para detectar cuándo empiezas a conducir con la app cerrada. Este permiso lo usa solo la grabación automática: la búsqueda de estaciones y el centrado del mapa usan un permiso de ubicación en primer plano independiente.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Entendido';

  @override
  String get autoRecordConsentExplanationTooltip => '¿Qué significa esto?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Toca para gestionarlo en los ajustes del sistema';

  @override
  String get autoRecordSectionTitle => 'Grabación automática';

  @override
  String get autoRecordToggleLabel => 'Grabar viajes automáticamente';

  @override
  String get autoRecordStatusActiveLabel =>
      'La grabación automática se activará la próxima vez que entres en el coche.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Empareja un adaptador OBD2 para activar la grabación automática.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Permite la ubicación en segundo plano para que la grabación automática siga funcionando con la pantalla apagada.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Emparejar un adaptador';

  @override
  String get autoRecordSpeedThresholdLabel => 'Velocidad de inicio (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Retardo de guardado tras la desconexión (segundos)';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Ubicación en segundo plano permitida';

  @override
  String get autoRecordBackgroundLocationRequest => 'Solicitar permiso';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      '¿Por qué «Permitir todo el tiempo»?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'La grabación automática transmite las coordenadas GPS desde el servicio en primer plano de OBD-II con la pantalla apagada para que la ruta de tu viaje siga siendo precisa. Android requiere la opción «Permitir todo el tiempo» para que esto siga funcionando después de que el dispositivo se bloquee.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Abrir ajustes';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Se requiere el permiso de ubicación';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'No se pudo solicitar la ubicación en segundo plano';

  @override
  String get aclWakeNotificationTitle => 'Coche conectado';

  @override
  String get aclWakeNotificationBody =>
      'Toca para abrir Sparkilo: la grabación del viaje puede empezar.';

  @override
  String get exportBackupReady => 'Copia de seguridad lista: elige un destino';

  @override
  String get exportBackupFailed =>
      'Error al exportar la copia de seguridad: inténtalo de nuevo';

  @override
  String get backupExportProgress => 'Exportando tu copia de seguridad…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Guardado en Descargas como $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Restaurar copia de seguridad';

  @override
  String get restoreBackupDialogBody =>
      'La fusión añade y actualiza los registros de la copia de seguridad y conserva todo lo que ya hay en este dispositivo. Reemplazar elimina todos los datos actuales y luego restaura solo la copia de seguridad — esta acción no se puede deshacer.';

  @override
  String get restoreBackupMergeAction => 'Fusionar';

  @override
  String get restoreBackupReplaceAction => 'Reemplazar todo';

  @override
  String get restoreBackupEmpty =>
      'Copia de seguridad restaurada — no contenía ningún registro';

  @override
  String get restoreBackupCorrupt =>
      'Error al restaurar — este archivo no es una copia de seguridad válida de Tankstellen';

  @override
  String get restoreBackupFailed =>
      'Error al restaurar — no se pudo leer el archivo';

  @override
  String get backupImportProgress => 'Restaurando tu copia de seguridad…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Fusionados $vehicles vehículos, $fillUps repostajes, $trips viajes, $chargingLogs registros de carga';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Todos los datos reemplazados por $vehicles vehículos, $fillUps repostajes, $trips viajes, $chargingLogs registros de carga';
  }

  @override
  String get brokenMapChipDisclaimer => 'Lecturas del MAP sospechosas';

  @override
  String get brokenMapSnackbarUnreliable =>
      'El sensor MAP da lecturas incorrectas: las lecturas de combustible pueden ser entre un 50 y un 80 % demasiado bajas. Prueba con otro adaptador.';

  @override
  String get brokenMapBannerHardDisable =>
      'Sensor MAP poco fiable. Se muestran las medias de repostaje en lugar del caudal de combustible en directo.';

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Sensor MAP: $posterior % ± $margin %';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Sensor MAP: $posterior % ± $margin % (verificado)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnóstico del sensor MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Confianza de MAP averiado: $posterior % ± $margin %';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observaciones registradas';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verificado correcto';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'El sensor MAP de este vehículo aún no se ha observado.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Adaptadores en la lista de bloqueo';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'No hay adaptadores en la lista de bloqueo.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter: marcado como averiado un $percent %';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Borrar';

  @override
  String get brokenMapRevPromptTitle => 'Acelera el motor';

  @override
  String get brokenMapRevPromptBody =>
      'Da un breve acelerón para que la app pueda comprobar que el sensor MAP responde.';

  @override
  String get brokenMapRevPromptConfirm => 'Hecho: he acelerado';

  @override
  String get calibrationAdvancedTitle => 'Calibración avanzada';

  @override
  String get calibrationDisplacementLabel => 'Cilindrada del motor (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Eficiencia volumétrica (η_v)';

  @override
  String get calibrationAfrLabel => 'Relación aire-combustible (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Densidad del combustible (g/L)';

  @override
  String get calibrationSourceDetected => '(detectado del VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catálogo: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(predeterminado)';

  @override
  String get calibrationSourceManual => '(manual)';

  @override
  String get calibrationResetToDetected => 'Restablecer al valor detectado';

  @override
  String get calibrationBasisAtkinson => 'Ciclo Atkinson';

  @override
  String get calibrationBasisVnt => 'Diésel VNT + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbo + DI';

  @override
  String get calibrationBasisTurbo => 'Turboalimentado';

  @override
  String get calibrationBasisNaDi => 'Aspiración natural + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catálogo: $makeModel — predeterminado de $basis)';
  }

  @override
  String get calibrationDirectFuelRateNote =>
      'Este vehículo informa directamente de su caudal de combustible (PID 5E), así que no se usa la calibración de eficiencia volumétrica: tu consumo se mide, no se modela.';

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Tu $makeModel está marcado como diésel pero coincide con una entrada de gasolina del catálogo. Toca para actualizar.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Actualizar';

  @override
  String get catalogResetAction =>
      'Restablecer desde la base de datos de vehículos';

  @override
  String get catalogResetConfirmTitle =>
      '¿Restablecer desde la base de datos de vehículos?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Esto sustituye la capacidad del depósito, la potencia y la cilindrada de este vehículo por los valores de la base de datos para $vehicle. Los demás campos y tu historial de repostajes no se tocan.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'No hay ninguna entrada que coincida con este vehículo en la base de datos.';

  @override
  String get catalogResetDoneSnackbar =>
      'Datos del vehículo restablecidos desde la base de datos.';

  @override
  String get consumptionTabFuel => 'Combustible';

  @override
  String get consumptionTabCharging => 'Carga';

  @override
  String get noChargingLogsTitle => 'Aún no hay registros de carga';

  @override
  String get noChargingLogsSubtitle =>
      'Registra tu primera sesión de carga para empezar a controlar EUR/100 km y kWh/100 km.';

  @override
  String get addChargingLog => 'Registrar carga';

  @override
  String get addChargingLogTitle => 'Registrar sesión de carga';

  @override
  String get chargingKwh => 'Energía (kWh)';

  @override
  String get chargingCost => 'Coste total';

  @override
  String get chargingTimeMin => 'Tiempo de carga (min)';

  @override
  String get chargingStationName => 'Estación (opcional)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper =>
      'Se necesita un registro anterior para comparar';

  @override
  String get chargingLogButtonLabel => 'Registrar carga';

  @override
  String get chargingCostTrendTitle => 'Tendencia del coste de carga';

  @override
  String get chargingEfficiencyTitle => 'Eficiencia (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Aún no hay datos suficientes';

  @override
  String get confirmDeleteTitle => '¿Eliminar?';

  @override
  String get confirmDeleteBody => '¿Seguro que quieres eliminar esto?';

  @override
  String get consoFeatureGroupTitle => 'Consumo';

  @override
  String get consoFeatureGroupDescription =>
      'Controla tu consumo: repostajes manuales o grabación automática de viajes por OBD2.';

  @override
  String get consoModeOff => 'Desactivado';

  @override
  String get consoModeFuel => 'Combustible';

  @override
  String get consoModeFuelAndTrips => 'Combustible + viajes';

  @override
  String get consoModeOffDescription =>
      'Sin pestaña de Consumo ni sección de ajustes de Consumo.';

  @override
  String get consoModeFuelDescription =>
      'Solo repostajes manuales. Útil sin un adaptador OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Añade la grabación automática de viajes por OBD2. Requiere un adaptador emparejado.';

  @override
  String get consoGroupVehicles => 'Vehículos';

  @override
  String get consoGroupCoaching => 'Asistencia mientras conduces';

  @override
  String get consoGroupRewards => 'Recompensas y ahorros';

  @override
  String get consoGroupTroubleshooting => 'Resolución de problemas';

  @override
  String consumptionAccuracyLabel(String level, String band) {
    return 'Precisión: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Alta';

  @override
  String get consumptionAccuracyMedium => 'Media';

  @override
  String get consumptionAccuracyLow => 'Baja';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Calibración completa: repostajes más viajes registrados con OBD2. La cifra de L/100 km sigue la realidad con un margen de pocos puntos porcentuales.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Los repostajes han anclado el modelo de consumo, pero aún no se ha procesado ningún viaje con OBD2. Registra uno con OBD2 conectado para alcanzar la precisión alta.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Solo GPS — ningún repostaje ha anclado todavía el modelo de consumo. Añade un par de repostajes completos para mejorar la precisión.';

  @override
  String get moreActionsTooltip => 'Más';

  @override
  String get exportBackupMenuLabel => 'Exportar copia de seguridad';

  @override
  String get restoreBackupMenuLabel => 'Restaurar copia de seguridad';

  @override
  String get carbonDashboardMenuLabel => 'Panel de carbono';

  @override
  String get settingsMenuLabel => 'Ajustes';

  @override
  String get consumptionStatsPageTitle => 'Estadísticas de consumo';

  @override
  String get consumptionStatsComparisonTitle => 'Este mes vs el mes pasado';

  @override
  String get consumptionStatsTrendsTitle => 'Evolución a lo largo del tiempo';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Registra repostajes durante al menos dos meses para comparar.';

  @override
  String get consumptionStatsPricePerLiter => 'Precio medio/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litros por mes';

  @override
  String get consumptionStatsChartSpend => 'Gasto por mes';

  @override
  String get consumptionStatsChartPricePerLiter => 'Precio por litro';

  @override
  String get consumptionStatsChartConsumption => 'L/100km por mes';

  @override
  String get fuelCompareSectionTitle =>
      'Coste de circular, combustible por combustible';

  @override
  String get fuelComparePricePerLitre => 'Pagado por litro';

  @override
  String get fuelCompareCostPer100km => 'Coste por 100 km';

  @override
  String get fuelCompareDistance => 'Distancia medida';

  @override
  String get fuelCompareLitres => 'Litros consumidos';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return '$winner es tu combustible más barato para circular';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return '$loser cuesta $amount más por cada 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return '$fuel supera a $rival por debajo de $price el litro';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'El punto de equilibrio se calcula con el consumo medido de cada combustible, así que cambia con tu forma de conducir.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litros y coste pueden no coincidir: un combustible puede gastar menos litros por 100 km y aun así costar más por kilómetro, porque el precio del surtidor es distinto. El coste por kilómetro es lo que decide.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depósitos llenos',
      one: 'un depósito lleno',
    );
    return 'Provisional — basado en $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depósitos llenos',
      one: 'un depósito lleno',
    );
    return 'Basado en $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 por 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return '$winner es tu combustible con menos emisiones';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return '$fuel cuesta $money más por 1000 km pero emite $co2 menos de CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return '$fuel es más barato y más limpio que $rival';
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
    return 'Tus $distance con $fuel emitieron $actual en lugar de $alternative con $rival — $saved evitados';
  }

  @override
  String get fuelCompareCo2Source =>
      'Las cifras de CO2 son estimaciones del pozo a la rueda (EU JEC WTW v5) aplicadas a tu consumo medido: son orientativas, no una contabilidad certificada.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'El CO2 solo se muestra para combustibles puros: el factor de emisión de una mezcla depende de su composición, que esta fila no registra.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repostajes parciales pendientes de lleno completo: no se incluyen en la media',
      one:
          '1 repostaje parcial pendiente de lleno completo: no se incluye en la media',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return 'El $percent % del combustible procede de autocorrecciones: revisa las entradas';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Correcciones: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Denunciar contenido';

  @override
  String get contentModerationBlockAction => 'Bloquear autor';

  @override
  String get contentModerationReportDialogTitle => '¿Denunciar este contenido?';

  @override
  String get contentModerationReportDialogBody =>
      'Se envía una denuncia a tu servidor TankSync para su revisión y este contenido se oculta en tu dispositivo.';

  @override
  String get contentModerationReportConfirmButton => 'Denunciar';

  @override
  String get contentModerationBlockDialogTitle => '¿Bloquear a este autor?';

  @override
  String get contentModerationBlockDialogBody =>
      'Todo lo que esta cuenta comparta contigo quedará oculto en este dispositivo.';

  @override
  String get contentModerationBlockConfirmButton => 'Bloquear';

  @override
  String get contentModerationReportedSnack =>
      'Denuncia enviada: contenido oculto.';

  @override
  String get contentModerationReportFailedSnack =>
      'No se pudo enviar la denuncia. Inténtalo de nuevo.';

  @override
  String get contentModerationBlockedSnack =>
      'Autor bloqueado: su contenido compartido está oculto.';

  @override
  String get fillUpCorrectionLabel => 'Autocorrección: toca para editar';

  @override
  String get fillUpCorrectionEditTitle => 'Editar autocorrección';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Esta entrada se generó automáticamente para cerrar la diferencia entre los viajes registrados y el combustible repostado. Ajusta los valores si conoces las cifras reales.';

  @override
  String get fillUpCorrectionDelete => 'Eliminar corrección';

  @override
  String get fillUpCorrectionStation => 'Nombre de la estación (opcional)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Estaciones de $country a $km km: $price €/L más baratas';
  }

  @override
  String get crossBorderTapToSwitch => 'Toca para cambiar de país';

  @override
  String get crossBorderDismissTooltip => 'Descartar';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Abrir la fuente de datos $source ($license) en el navegador';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© contribuidores de $brand';
  }

  @override
  String get developerToolsSectionTitle => 'Herramientas de desarrollo';

  @override
  String get dataAccessTracerExport => 'Exportar traza de acceso a datos';

  @override
  String get dataAccessTracerExportSuccess =>
      'Traza de acceso a datos guardada en Descargas.';

  @override
  String get dataAccessTracerExportFailure =>
      'No se pudo exportar la traza de acceso a datos.';

  @override
  String get dataAccessTracerEmpty =>
      'Aún no hay eventos de acceso a datos: busca o abre gasolineras primero y luego exporta.';

  @override
  String get developerToolsSubtitle =>
      'Diagnósticos y herramientas de depuración: solo visibles en modo desarrollador / depuración.';

  @override
  String get developerToolsMenuSubtitle =>
      'Registro de errores, alertas de prueba, diagnósticos';

  @override
  String get developerToolsErrorLogGroupTitle => 'Registro de errores';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Guardar registro de errores ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Borrar registro de errores';

  @override
  String get developerToolsViewErrorLog => 'Ver registro de errores';

  @override
  String get developerToolsErrorLogEmpty =>
      'No hay trazas de error registradas.';

  @override
  String get developerToolsAlertsGroupTitle => 'Alertas y notificaciones';

  @override
  String get developerToolsFireTestNotification =>
      'Enviar notificación de prueba';

  @override
  String get developerToolsTestNotificationTitle => 'Notificación de prueba';

  @override
  String get developerToolsTestNotificationBody =>
      'Si puedes leer esto, las notificaciones funcionan.';

  @override
  String get developerToolsTestNotificationSent =>
      'Notificación de prueba enviada.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'Las notificaciones están bloqueadas: actívalas en los ajustes del sistema y vuelve a intentarlo.';

  @override
  String get developerToolsRunTestAlert =>
      'Ejecutar canalización de alerta de prueba';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Alerta de prueba activada: la canalización generó $count notificación(es).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Alerta de precio de prueba';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Coincidencia sintética: se encontró cerca una estación por debajo de tu objetivo.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Busca gasolineras primero y luego ejecuta la alerta de prueba para que la notificación pueda abrir una gasolinera real.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnósticos';

  @override
  String get developerToolsFeatureFlagDump =>
      'Inspector de indicadores de funciones';

  @override
  String get developerToolsFlagOn => 'Activado';

  @override
  String get developerToolsFlagOff => 'Desactivado';

  @override
  String get developerToolsClearCaches => 'Vaciar cachés';

  @override
  String get developerToolsCachesCleared => 'Cachés vaciadas.';

  @override
  String get developerToolsCopyDiagnostics => 'Copiar diagnósticos';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnósticos copiados al portapapeles.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Información de compilación';

  @override
  String get developerToolsBuildVersion => 'Versión de la aplicación';

  @override
  String get developerToolsBuildChannel => 'Canal de compilación';

  @override
  String get startupTraceSectionTitle => 'Traza de inicialización al arrancar';

  @override
  String get startupTraceExportButton => 'Exportar traza de arranque';

  @override
  String get startupTraceEmpty =>
      'Aún no hay ninguna traza de arranque registrada.';

  @override
  String startupTraceTotalMs(int ms) {
    return 'Total: $ms ms';
  }

  @override
  String startupTraceMs(int ms) {
    return '$ms ms';
  }

  @override
  String get startupTraceExportSuccess =>
      'Traza de arranque guardada en Descargas.';

  @override
  String get startupTraceExportFailure =>
      'No se pudo exportar la traza de arranque.';

  @override
  String get distanceSourceOdometer => 'Cuentakilómetros';

  @override
  String get distanceSourceOdometerTooltip =>
      'Distancia leída del cuentakilómetros del coche: una referencia medida.';

  @override
  String get distanceSourceGps => 'Traza GPS';

  @override
  String get distanceSourceGpsTooltip =>
      'Distancia sumada a partir de la traza GPS grabada: la distancia real por carretera.';

  @override
  String get distanceSourceEstimated => 'Estimada';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Distancia integrada a partir del sensor de velocidad: una estimación; el sensor suele leer un poco de más.';

  @override
  String get insightCardTitle => 'Principales comportamientos derrochadores';

  @override
  String get insightEmptyState => 'Sin ineficiencias destacables: ¡sigue así!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor por encima de 3000 RPM ($pctTime % del viaje): $liters L desperdiciados';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count aceleraciones bruscas: $liters L desperdiciados';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Ralentí ($pctTime % del viaje): $liters L desperdiciados';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime % del viaje';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Forzando una marcha corta ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Apaga el motor en las paradas largas en lugar de dejarlo al ralentí.';

  @override
  String get lessonAdviceHighRpm =>
      'Cambia antes a una marcha más larga para mantener el motor fuera de la banda de altas revoluciones.';

  @override
  String get lessonAdviceHardAccel =>
      'Acelera suavemente: una aceleración progresiva consume menos combustible.';

  @override
  String get lessonAdviceLowGear =>
      'Sube de marcha antes para que el motor gire a menos revoluciones y consuma menos.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Velocidad alta sostenida ($pctTime% del trayecto): desperdiciados $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Velocidad alta sostenida ($pctTime% del trayecto)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Levanta el pie por encima de 110 km/h: la resistencia del aire sube mucho, así que ir algo más despacio ahorra mucho combustible.';

  @override
  String get lessonSmoothDrivingTitle => 'Conducción suave: ¡bien hecho!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Sin aceleraciones ni frenadas bruscas en este trayecto: una conducción constante mantiene bajo el consumo.';

  @override
  String insightFullThrottle(String pctTime, String liters) {
    return 'Aceleración a fondo ($pctTime% del viaje): malgastados $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Acelera con suavidad — un 70 % del acelerador te lleva a velocidad con mucho menos combustible.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Mezcla rica bajo carga ($pctTime% del viaje): malgastados $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Una carga pesada y sostenida enriquece la mezcla — cambia de marcha pronto y afloja en subidas largas para mantener la mezcla estequiométrica.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Subida al $gradePercent% de pendiente ($pctTime% del viaje): malgastados $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Toma impulso antes de la subida y alimenta el acelerador con suavidad — acelerar a fondo en una cuesta quema combustible extra.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count arranques en stop-and-go: malgastados $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticípate al tráfico y rueda por inercia hacia las paradas para rodar en lugar de arrancar — arrancar desde parado es la parte que más combustible consume.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'La mezcla parece algo pobre: el motor añadió combustible (corrección del $pctTrim %) para compensar';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'La mezcla parece pobre: el motor mantuvo una adición de combustible grande, del $pctTrim %, una posible ineficiencia';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'La mezcla parece algo rica: el motor quitó combustible (corrección del $pctTrim %) para compensar';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'La mezcla parece rica: el motor mantuvo un recorte de combustible grande, del $pctTrim %, una posible ineficiencia';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'El motor fue con mezcla rica bajo carga ($pctShare % del viaje en caliente): posible combustible desperdiciado';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Señal heurística de salud, no un diagnóstico';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Una corrección sostenida hacia mezcla pobre puede indicar una entrada de aire en la admisión, un suministro de combustible débil o un sensor envejecido. Si el consumo o el funcionamiento empeoran, un diagnóstico en taller puede confirmarlo.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Una corrección sostenida hacia mezcla rica puede indicar un inyector con fugas, una presión de combustible alta o un sensor que lee de más. Si el consumo o el funcionamiento empeoran, un diagnóstico en taller puede confirmarlo.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Ir con mezcla rica bajo mucha carga quema combustible extra. Sube de marcha antes y levanta el pie en las aceleraciones largas para que el motor se mantenga cerca de una mezcla estequiométrica.';

  @override
  String get lessonTransportTitle =>
      'Faltan datos del motor en la mayor parte de este viaje';

  @override
  String get lessonTransportAdvice =>
      'El motor no registró actividad durante casi toda la distancia. O el flujo OBD2 falló a mitad del viaje o el coche se movió sin conducirlo: el dato de consumo no es fiable y se excluye de tus estadísticas.';

  @override
  String get drivingScoreCardTitle => 'Puntuación de conducción';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Puntuación compuesta a partir del ralentí, las aceleraciones bruscas, las frenadas bruscas y el tiempo a altas RPM. Una comparación de tipo «mejor que el X % de los viajes anteriores» llegará en una versión posterior.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Puntuación de conducción $score sobre 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Ralentí';

  @override
  String get drivingScorePenaltyHardAccel => 'Aceleraciones bruscas';

  @override
  String get drivingScorePenaltyHardBrake => 'Frenadas bruscas';

  @override
  String get drivingScorePenaltyHighRpm => 'RPM altas';

  @override
  String get drivingScorePenaltyFullThrottle => 'Acelerador a fondo';

  @override
  String get drivingScoreClassVeryGood => 'Muy bueno';

  @override
  String get drivingScoreClassGood => 'Bueno';

  @override
  String get drivingScoreClassAverage => 'Regular';

  @override
  String get drivingScoreClassBad => 'Mejorable';

  @override
  String get drivingScorePenaltyLugging => 'Motor ahogado';

  @override
  String get drivingScorePenaltySmoothness => 'Conducción brusca';

  @override
  String get drivingScorePenaltyHighSpeed => 'Alta velocidad';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Pedal agresivo';

  @override
  String get drivingScorePenaltyLambda => 'Mezcla rica';

  @override
  String get gpsKpiCardTitle => 'Eficiencia GPS';

  @override
  String get gpsKpiRpa => 'Aceleración positiva (RPA)';

  @override
  String get gpsKpiPke => 'Demanda de energía cinética (PKE)';

  @override
  String get gpsKpiVapos => 'Intensidad de aceleración (VAPOS)';

  @override
  String get gpsKpiCoast => 'Porcentaje en inercia';

  @override
  String get gpsKpiClimbEnergy => 'Energía en subida';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct respecto a tu línea base eficiente';
  }

  @override
  String get drivingTraceCardTitle => 'Traza de análisis de conducción (dev)';

  @override
  String get drivingTraceCardBody =>
      'Exporta los KPIs GPS, la puntuación y las lecciones de este viaje como JSON, escribe cómo se sintió realmente la conducción en el campo de comentarios y compártelo para calibrar los umbrales de estilo de conducción con viajes reales.';

  @override
  String get drivingTraceExportAction => 'Exportar traza de análisis';

  @override
  String get drivingTraceExported =>
      'Traza de análisis guardada en Descargas — añade tu valoración en el campo de comentarios y compártela.';

  @override
  String get drivingTraceExportFailed =>
      'No se pudo exportar la traza de análisis.';

  @override
  String get minimalDriveTripAverage => 'Media del trayecto';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Crucero a altas revoluciones ($pctTime % del viaje): subir de marcha antes podría ahorrar $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Sube de marcha antes en crucero: la misma velocidad a menos revoluciones consume bastante menos.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'Inercia con corte de inyección ($pctTime % del viaje): ahorrados unos $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Bien anticipado: levantar el pie pronto permite que el motor corte por completo la inyección mientras rueda.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Adónde fue tu combustible';

  @override
  String get fuelBreakdownIdle => 'Ralentí';

  @override
  String get fuelBreakdownHarshAccel => 'Aceleraciones fuertes';

  @override
  String get fuelBreakdownHighRpmCruise => 'Crucero a altas revoluciones';

  @override
  String get fuelBreakdownCoastingSaved => 'Ahorrado a vela';

  @override
  String get fuelBreakdownEfficient => 'Conducción normal';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Llevas un rato al ralentí: apagar el motor ahorra combustible';

  @override
  String get ecoNudgeHarshAccel =>
      'Aceleración fuerte: un pie más suave ahorra combustible';

  @override
  String get ecoNudgeHighRpm =>
      'Revoluciones altas en crucero: subir de marcha antes ahorra combustible';

  @override
  String get obd2CoverageNoneNote =>
      'No llegaron datos del motor desde el adaptador OBD2 en este viaje: las cifras de combustible son estimaciones por GPS.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Los datos del motor se detuvieron al $percent % del viaje (conexión perdida): las cifras de combustible posteriores son estimaciones por GPS.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Los datos del motor solo cubrieron el $percent % de este viaje: los huecos usan estimaciones por GPS.';
  }

  @override
  String get favoritesShareAction => 'Compartir';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo: favoritos del $date';
  }

  @override
  String get favoritesShareError =>
      'No se pudo generar la imagen para compartir';

  @override
  String get featureManagementSectionTitle => 'Gestión de funciones';

  @override
  String get featureManagementSectionSubtitle =>
      'Activa o desactiva funciones individuales. Algunas funciones dependen de otras: los interruptores están desactivados hasta que se cumplan los requisitos previos.';

  @override
  String get featureLabel_obd2TripRecording => 'Grabación de viajes por OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Captura viajes automáticamente por OBD2.';

  @override
  String get featureLabel_gamification => 'Gamificación';

  @override
  String get featureDescription_gamification =>
      'Puntuaciones de conducción e insignias conseguidas.';

  @override
  String get featureLabel_hapticEcoCoach => 'Eco-coach háptico';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Respuesta háptica en tiempo real durante un viaje.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sincronización entre dispositivos mediante Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Análisis de consumo';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Pestaña de análisis de repostajes y viajes.';

  @override
  String get featureLabel_baselineSync => 'Sincronización de referencias';

  @override
  String get featureDescription_baselineSync =>
      'Sincroniza las referencias de conducción mediante TankSync.';

  @override
  String get featureLabel_priceAlerts => 'Alertas de precios';

  @override
  String get featureDescription_priceAlerts =>
      'Notificaciones de bajada de precio basadas en umbrales.';

  @override
  String get featureLabel_priceHistory => 'Historial de precios';

  @override
  String get featureDescription_priceHistory =>
      'Gráficos de precios de 30 días en los detalles de la estación.';

  @override
  String get featureLabel_routePlanning => 'Planificación de rutas';

  @override
  String get featureDescription_routePlanning =>
      'La parada más barata a lo largo de tu ruta.';

  @override
  String get featureLabel_evCharging => 'Carga de VE';

  @override
  String get featureDescription_evCharging =>
      'Estaciones de carga mediante OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Orientación de conducción eficiente usando los semáforos de OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Ruta GPS del viaje';

  @override
  String get featureDescription_gpsTripPath =>
      'Conserva las muestras de la ruta GPS junto a cada viaje.';

  @override
  String get featureLabel_autoRecord => 'Grabación automática';

  @override
  String get featureDescription_autoRecord =>
      'Inicia un viaje automáticamente cuando el adaptador OBD2 se conecta a un vehículo en movimiento.';

  @override
  String get featureLabel_showFuel => 'Mostrar estaciones de servicio';

  @override
  String get featureDescription_showFuel =>
      'Muestra resultados de estaciones de gasolina/diésel en la búsqueda y en el mapa.';

  @override
  String get featureLabel_showElectric => 'Mostrar estaciones de carga';

  @override
  String get featureDescription_showElectric =>
      'Muestra estaciones de carga de VE en la búsqueda y en el mapa.';

  @override
  String get featureLabel_showConsumptionTab => 'Pestaña de consumo';

  @override
  String get featureDescription_showConsumptionTab =>
      'Muestra la pestaña de análisis de consumo en la navegación inferior.';

  @override
  String get featureBlockedEnable_gamification =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Activa primero TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureLabel_tflitePricePrediction =>
      'Predicción de precios con TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Modelo de previsión de precios en el dispositivo: la inferencia se ejecuta localmente; las características y predicciones nunca salen del dispositivo.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Activa primero el historial de precios';

  @override
  String get featureLabel_fuelCalculator => 'Calculadora de combustible';

  @override
  String get featureDescription_fuelCalculator =>
      'Calculadora de coste de combustible accesible desde los resultados de búsqueda.';

  @override
  String get featureLabel_carbonDashboard => 'Panel de emisiones';

  @override
  String get featureDescription_carbonDashboard =>
      'Panel de huella de CO2 accesible desde la pestaña de Consumo.';

  @override
  String get featureLabel_experimentalOemPids => 'PID OEM experimentales';

  @override
  String get featureDescription_experimentalOemPids =>
      'Lee los litros exactos del depósito mediante PID específicos del fabricante en adaptadores compatibles.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Activa primero la grabación de viajes por OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Escanear QR de pago';

  @override
  String get featureDescription_paymentQrScan =>
      'Lector de QR de pago en la pantalla de detalles de la estación.';

  @override
  String get featureLabel_communityPriceReports =>
      'Informes de precios de la comunidad';

  @override
  String get featureDescription_communityPriceReports =>
      'Informa del precio de una estación desde la pantalla de detalles de la estación.';

  @override
  String get featureLabel_obd2Optional => 'Requerir OBD2 para grabar viajes';

  @override
  String get featureDescription_obd2Optional =>
      'Cuando está apagado, la app graba viajes solo con GPS sin necesitar un adaptador OBD2. El coaching se reduce — sin L/100 km al instante, menos señales del motor.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR de tique';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Escanea un tique impreso en la pantalla Añadir repostaje para rellenar fecha, litros, total y estación.';

  @override
  String get featureLabel_developerPatToken =>
      'Feedback de desarrollador (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Activa el panel de feedback para escaneos fallidos que crea automáticamente issues de GitHub con un Personal Access Token. Función para usuarios avanzados/colaboradores.';

  @override
  String get featureLabel_debugMode => 'Modo desarrollador / depuración';

  @override
  String get featureDescription_debugMode =>
      'Muestra una sección Herramientas de desarrollo en los ajustes con diagnósticos: exportación del registro de errores, notificaciones de prueba, ejecución de la canalización de alerta de prueba, volcado de indicadores de funciones, vaciado de cachés y copia de diagnósticos.';

  @override
  String get featureLabel_approachOverlay => 'Radar de gasolineras';

  @override
  String get featureDescription_approachOverlay =>
      'Convierte el panel de viaje flotante en un radar de gasolineras en directo — al acercarte a una gasolinera, cambia al color del tipo de combustible y muestra el precio.';

  @override
  String get featureLabel_voiceAnnouncements => 'Avisos de voz';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Anuncia en voz alta las gasolineras baratas cercanas mientras conduces, para que puedas mantener los ojos en la carretera.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Activa primero el Radar de gasolineras';

  @override
  String get featureGroupTitle_finding => 'Búsqueda y mapa';

  @override
  String get featureGroupDescription_finding =>
      'Dónde repostar o cargar — búsqueda, mapa y rutas.';

  @override
  String get featureGroupTitle_prices => 'Precios y alertas';

  @override
  String get featureGroupDescription_prices =>
      'Bajadas de precio, historial e informes.';

  @override
  String get featureGroupTitle_radar => 'Radar de gasolineras';

  @override
  String get featureGroupDescription_radar =>
      'Avisos de precio en directo mientras conduces.';

  @override
  String get featureGroupTitle_sync => 'Sincronización y copia de seguridad';

  @override
  String get featureGroupDescription_sync =>
      'Mantén tus datos en todos los dispositivos.';

  @override
  String get featureGroupTitle_input => 'Entrada y escaneado';

  @override
  String get featureGroupDescription_input =>
      'Ayudas para registrar repostajes.';

  @override
  String get featureGroupTitle_developer => 'Desarrollador y experimental';

  @override
  String get featureGroupDescription_developer =>
      'Herramientas para usuarios avanzados y colaboradores.';

  @override
  String get featureLabel_voiceFeedback =>
      'Respuesta hablada (síntesis de voz)';

  @override
  String get featureDescription_voiceFeedback =>
      'Interruptor general de toda salida de voz: el coach de conducción hablado y los anuncios de gasolineras. Desactivado, la app nunca abre un motor de síntesis de voz.';

  @override
  String get feedbackConsentTitle => '¿Enviar el informe a GitHub?';

  @override
  String get feedbackConsentBody =>
      'Esto crea un ticket público en nuestro repositorio de GitHub con tu foto y el texto del OCR. No se envía ningún dato personal (ubicación, ID de cuenta). ¿Continuar?';

  @override
  String get feedbackConsentContinue => 'Continuar';

  @override
  String get feedbackConsentCancel => 'Cancelar';

  @override
  String get feedbackConsentLater => 'Más tarde';

  @override
  String get feedbackTokenSectionTitle =>
      'Comentarios de escaneo erróneo (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Para abrir automáticamente un ticket de GitHub desde un escaneo fallido, pega un PAT de GitHub (ámbito `public_repo` en el repositorio tankstellen). De lo contrario, sigue disponible el uso compartido manual.';

  @override
  String get feedbackTokenStatusSet => 'Token configurado';

  @override
  String get feedbackTokenStatusUnset => 'Sin token';

  @override
  String get feedbackTokenSet => 'Definir';

  @override
  String get feedbackTokenClear => 'Borrar';

  @override
  String get feedbackTokenDialogTitle => 'PAT de GitHub';

  @override
  String get feedbackTokenFieldLabel => 'Token de acceso personal';

  @override
  String get fillUpMultiFuelHint =>
      'Este vehículo puede usar distintos combustibles: registra el que realmente has echado';

  @override
  String get fillUpGuidanceTitle => 'El mejor momento para repostar';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'El precio actual está entre los más baratos de los últimos $days días — es un buen momento para repostar.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Los precios están cerca de su máximo de los últimos $days días. Suelen ser más baratos $window — considera esperar.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Los precios están subiendo — considera repostar pronto.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'El precio de hoy está en torno a la media de los últimos $days días.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Podrías ahorrar unos $amount/L eligiendo bien el momento.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basado en $count lecturas de precio',
      one: 'Basado en 1 lectura de precio',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'los $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return 'por las $part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'en otros momentos';

  @override
  String get fillUpGuidanceWeekday1 => 'Los lunes';

  @override
  String get fillUpGuidanceWeekday2 => 'Los martes';

  @override
  String get fillUpGuidanceWeekday3 => 'Los miércoles';

  @override
  String get fillUpGuidanceWeekday4 => 'Los jueves';

  @override
  String get fillUpGuidanceWeekday5 => 'Los viernes';

  @override
  String get fillUpGuidanceWeekday6 => 'Los sábados';

  @override
  String get fillUpGuidanceWeekday7 => 'Los domingos';

  @override
  String get fillUpGuidancePartEarlyMorning => 'madrugadas';

  @override
  String get fillUpGuidancePartMorning => 'mañanas';

  @override
  String get fillUpGuidancePartAfternoon => 'tardes';

  @override
  String get fillUpGuidancePartEvening => 'primeras horas de la noche';

  @override
  String get fillUpGuidancePartNight => 'noches';

  @override
  String get fillUpOdometerFromCarJustNow => 'De tu coche · ahora mismo';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'De tu coche · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Estimado a partir de la última lectura de tu coche más la distancia recorrida desde entonces ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Pegar texto';

  @override
  String get pasteReceiptDialogTitle => 'Pegar texto del tique';

  @override
  String get pasteReceiptDialogHint =>
      'Pega el texto de un tique de combustible: correo, SMS o un PDF compartido. Los litros, el precio por litro, el tipo de combustible, el total y la gasolinera se leen en el dispositivo y rellenan el formulario. No se envía nada a ningún servidor.';

  @override
  String get pasteReceiptFieldHint => 'Texto del tique';

  @override
  String get pasteReceiptParseAction => 'Rellenar';

  @override
  String get pasteReceiptNoData =>
      'No se pudo leer ningún dato de combustible en ese texto: comprueba que es un tique de combustible e inténtalo de nuevo.';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel =>
      'Verificado por el adaptador';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'No coincide con la lectura del adaptador';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Tu entrada: $userL L. El adaptador indica: $adapterL L (diferencia entre la captura del nivel de combustible antes y después). ¿Usar el valor del adaptador?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Conservar mi entrada';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Usar el valor del adaptador';

  @override
  String get scanReceiptNoData =>
      'No se encontraron datos del recibo: inténtalo de nuevo';

  @override
  String get scanReceiptSuccess =>
      'Recibo escaneado: verifica los valores. Toca «Informar de error de escaneo» abajo si algo no cuadra.';

  @override
  String scanReceiptFailed(String error) {
    return 'Error de escaneo: $error';
  }

  @override
  String get badScanReportTitleReceipt =>
      'Informar de un error de escaneo: recibo';

  @override
  String get badScanReportHint =>
      'Compartiremos la foto del recibo y ambos conjuntos de valores para que la próxima versión pueda aprender este formato.';

  @override
  String get badScanReportFieldBrandLayout => 'Diseño de la marca';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Precio/L';

  @override
  String get badScanReportFieldStation => 'Estación';

  @override
  String get badScanReportFieldFuel => 'Combustible';

  @override
  String get badScanReportFieldDate => 'Fecha';

  @override
  String get badScanReportHeaderField => 'Campo';

  @override
  String get badScanReportHeaderScanned => 'Escaneado';

  @override
  String get badScanReportHeaderYouTyped => 'Lo que escribiste';

  @override
  String get badScanReportCreateTicket => 'Crear incidencia';

  @override
  String get badScanReportOpenInBrowser => 'Abrir en el navegador';

  @override
  String get badScanReportFallbackToShare =>
      'Error al enviar: uso compartido manual';

  @override
  String get fillUpWarningDialogTitle => 'Revisa este repostaje';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Has elegido $chosenFuel, pero este vehículo funciona con $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'El cuentakilómetros $entered km está por debajo de los $previous km del repostaje anterior: la distancia no puede ir hacia atrás.';
  }

  @override
  String get fillUpWarningGoBack => 'Volver y corregir';

  @override
  String get fillUpWarningSaveAnyway => 'Guardar de todos modos';

  @override
  String get fillUpSectionWhatTitle => 'Qué repostaste';

  @override
  String get fillUpSectionWhatSubtitle => 'Combustible, cantidad, precio';

  @override
  String get fillUpSectionWhereTitle => 'Dónde estabas';

  @override
  String get fillUpSectionWhereSubtitle => 'Estación, cuentakilómetros, notas';

  @override
  String get fillUpImportReceiptLabel => 'Recibo';

  @override
  String get fillUpPricePerLiterLabel => 'Precio por litro';

  @override
  String get vehicleHeaderUntitled => 'Vehículo nuevo';

  @override
  String get vehicleSectionIdentityTitle => 'Identidad';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nombre y VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Grupo motopropulsor';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Cómo se mueve este vehículo';

  @override
  String get profileSectionDisplayStations => 'Pantalla y gasolineras';

  @override
  String get profileSectionRegion => 'Región';

  @override
  String get fuelEfficiencyCardTitle =>
      'Coste por kilómetro según el combustible';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Qué mezcla de combustible sale realmente más barata al conducir';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Más barato por km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Puro';

  @override
  String get fuelEfficiencyMixBadge => 'Mezcla';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Sobre todo $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Coste/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Total gastado';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repostajes',
      one: '1 repostaje',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depósitos llenos',
      one: '1 depósito lleno',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Registra al menos dos depósitos llenos por composición para coronar el más barato.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Los depósitos se agrupan por composición: un depósito es puro cuando un combustible supone al menos el 85 %; si no, es una mezcla.';

  @override
  String get fuelNameE5 => 'Gasolina 95';

  @override
  String get fuelNameE10 => 'Gasolina 95 E10';

  @override
  String get fuelNameE98 => 'Gasolina 98';

  @override
  String get fuelNameDiesel => 'Diésel';

  @override
  String get fuelNameDieselPremium => 'Diésel Premium';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'GLP';

  @override
  String get fuelNameCng => 'GNC';

  @override
  String get fuelNameHydrogen => 'Hidrógeno';

  @override
  String get fuelNameElectric => 'Eléctrico';

  @override
  String get calibrationModeLabel => 'Modo de calibración';

  @override
  String get calibrationModeRule => 'Basado en reglas';

  @override
  String get calibrationModeFuzzy => 'Difuso';

  @override
  String get calibrationModeTooltip =>
      'El modo basado en reglas asigna cada muestra de conducción a una única situación. El modo difuso la reparte entre todas según lo bien que encaje en cada una: más suave en torno a 60 km/h o con pendientes cambiantes, pero más lento para llenar todos los grupos.';

  @override
  String get profileGamificationToggleTitle => 'Mostrar logros y puntuaciones';

  @override
  String get profileGamificationToggleSubtitle =>
      'Cuando está desactivado, las insignias, las puntuaciones y los iconos de trofeo se ocultan en toda la app.';

  @override
  String gdprPolicyLink(int version) {
    return 'Política de privacidad (versión $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Consentimiento otorgado el $date · versión $version de la política';
  }

  @override
  String get consentNotRecorded =>
      'Aún no se ha registrado ningún consentimiento';

  @override
  String serverErasurePartial(String tables) {
    return 'No se pudieron borrar algunos datos del servidor: $tables. Reintenta o contacta con el desarrollador con esta lista.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'No se pudieron borrar algunos datos locales: $steps. Reinicia la app y reintenta.';
  }

  @override
  String get myCommunityReportsTitle => 'Mis reportes a la comunidad';

  @override
  String get myCommunityReportsEmpty => 'No has enviado ningún reporte';

  @override
  String get deleteReportTooltip => 'Eliminar este reporte';

  @override
  String get reportDeleted => 'Reporte eliminado';

  @override
  String get reportDeleteFailed => 'No se pudo eliminar el reporte';

  @override
  String get privacyControlsTitle => 'Controles de privacidad';

  @override
  String get tileProxyToggleTitle =>
      'Cargar los mosaicos del mapa a través del proxy de Sparkilo';

  @override
  String get tileProxyToggleSubtitle =>
      'Activado: la zona visible del mapa y tu dirección IP llegan al servidor de la UE del desarrollador, que obtiene los mosaicos de OpenStreetMap. Desactivado: los mosaicos se cargan directamente desde tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle => 'Cargar logos de marcas desde internet';

  @override
  String get remoteLogosToggleSubtitle =>
      'Desactivado por defecto: se muestran marcadores de posición incluidos en la app. Activado: los logos se obtienen de logo.clearbit.com, que ve tu dirección IP.';

  @override
  String get privacyExportAllButton => 'Exportar todos mis datos (ZIP)';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName guardado en Descargas — $count archivos dentro';
  }

  @override
  String get privacyExportAllFailed =>
      'No se pudo escribir el archivo de exportación';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Operado por $operator · Supabase, UE (Frankfurt) · sincroniza favoritos, alertas, vehículos incl. VIN, repostajes, valoraciones, reportes y — si lo activas — viajes con GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'Tú eres el responsable del tratamiento — tu propio proyecto de Supabase, nosotros nunca lo vemos';

  @override
  String get syncModeJoinControllerNotice =>
      'Quien posee la base de datos compartida es el responsable del tratamiento de tus datos';

  @override
  String get ugcPublicNoticeTitle => 'Compartido con otros usuarios';

  @override
  String get ugcPublicNoticeBody =>
      'Esto se guarda en la base de datos de sincronización bajo tu ID de usuario seudónimo. En la Comunidad Sparkilo, cualquier usuario con sesión iniciada puede leerlo. Puedes eliminarlo en cualquier momento desde TankSync → Transparencia de datos.';

  @override
  String get blockedAuthorsTitle => 'Usuarios bloqueados';

  @override
  String get blockedAuthorsDescription =>
      'El contenido compartido por estos usuarios se oculta en este dispositivo. Desbloquéalos para volver a verlo.';

  @override
  String get blockedAuthorsEmpty => 'No hay usuarios bloqueados';

  @override
  String get blockedAuthorsUnblock => 'Desbloquear';

  @override
  String get coachingGpsLiftOff => 'Soltar gas';

  @override
  String get coachingGpsAnticipateBrake => 'Anticipar';

  @override
  String get coachingGpsSmoothAccel => 'Aceleración suave';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'La traza cubre el $pct %: hueco más largo $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'La traza cubre el $pct %: sin huecos detectados';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'app en segundo plano';

  @override
  String get gpsCoverageAttrOsBatching =>
      'agrupación de posiciones por el sistema';

  @override
  String get gpsCoverageAttrGateRejected => 'posiciones filtradas';

  @override
  String get gpsCoverageAttrDeliveryStall => 'entrega retrasada';

  @override
  String get gpsCoverageAttrSignalLoss => 'pérdida de señal';

  @override
  String get gpsCoverageAttrUnknown => 'causa desconocida';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'La app estaba en segundo plano sin un servicio en primer plano, así que el sistema limitó el GPS. Mantén la pantalla encendida mientras grabas o activa la grabación en segundo plano cuando esté disponible.';

  @override
  String get gpsCoverageHintOsBatching =>
      'El sistema entregó las posiciones tarde y por lotes; la traza se rellenó después, así que en realidad se perdieron pocos datos.';

  @override
  String get gpsCoverageHintGateRejected =>
      'Las posiciones con ruido de este tramo se filtraron para mantener honesta la cifra de distancia.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'Las posiciones se generaron a tiempo pero llegaron tarde a la app: el teléfono estaba ocupado (a menudo una reconexión Bluetooth). La recepción fue buena.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'Se perdió la recepción GPS: normalmente un túnel, un aparcamiento cubierto o un cañón urbano denso.';

  @override
  String get gpsCoverageHintUnknown =>
      'Este viaje no tiene información del ciclo de vida de la app durante el hueco, así que la causa no se puede determinar.';

  @override
  String get gpsCoverageAttrLinkRecovery => 'interferencia por reconexión OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'El hueco coincide con un episodio de reconexión OBD2: el enlace con el adaptador se estaba recuperando mientras la recepción GPS se detuvo. Arreglar la conexión del adaptador también arregla la traza.';

  @override
  String get gpsDiagnosticsTitle => 'Diagnóstico del muestreo GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps huecos',
      one: '1 hueco',
      zero: 'sin huecos',
    );
    return '$count muestras · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Intervalo mediano: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Capturado durante la grabación para verificar la cadencia del GPS con el teléfono en reposo.';

  @override
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Mayor intervalo: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Reanudado';

  @override
  String get gpsLifecyclePaused => 'Pausado';

  @override
  String get gpsLifecycleInactive => 'Inactivo';

  @override
  String get gpsKpiVerdictGood => 'Eficiente';

  @override
  String get gpsKpiVerdictModerate => 'Moderada';

  @override
  String get gpsKpiVerdictAggressive => 'Agresiva';

  @override
  String get gpsKpiInterpretationGood =>
      'Conducción suave y de bajo consumo: así es la eficiencia.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Conducción bastante típica: un poco más de suavidad con el acelerador ahorraría más.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Conducción con mucho gasto de energía: levantar el pie y dejar rodar más el coche reduciría el consumo.';

  @override
  String get gpsMatrixMaturityCold => 'Fría';

  @override
  String get gpsMatrixMaturityWarming => 'Calentando';

  @override
  String get gpsMatrixMaturityConverged => 'Convergida';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'La matriz GPS está calentando ($count refinamientos hasta ahora). Estimaciones provisionales.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'La matriz GPS está convergiendo ($count llenados). Estimaciones utilizables pero pueden desviarse unos %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'La matriz GPS ha convergido ($count llenados). Estimaciones dentro de ~2 % del consumo real.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'Estimación GPS (~) — sin sensor de combustible en este viaje. La cifra se modela a partir de la velocidad y la calibración de tu vehículo; la precisión mejora a medida que la matriz madura.';

  @override
  String get gpsRoadUseCardTitle => 'Cómo has usado la carretera';

  @override
  String get gpsRoadUseSpeedSection => 'Dónde has pasado el tiempo';

  @override
  String get gpsRoadUseSpeedIdle => 'Parado (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Ciudad (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Carretera (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Rápido (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Cómo te has movido';

  @override
  String get gpsRoadUsePhaseAccel => 'Acelerando';

  @override
  String get gpsRoadUsePhaseSteady => 'Velocidad constante';

  @override
  String get gpsRoadUsePhaseCoast => 'A vela';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Mucha inercia: dejar rodar el coche en vez de frenar ahorra combustible. Bien hecho.';

  @override
  String get gpsRoadUseSource => 'De tu traza GPS';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco-coaching en tiempo real';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Vibración háptica suave y consejo en pantalla cuando pisas a fondo durante la conducción de crucero';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Suave con el acelerador: dejarse llevar ahorra más';

  @override
  String highwayViaExit(String ref, String km) {
    return 'por la salida $ref · +$km km';
  }

  @override
  String semanticsNavigateTo(String name) {
    return 'Navegar a $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Eliminar $name de favoritos';
  }

  @override
  String get showOnMapSemanticLabel => 'Mostrar estaciones en el mapa';

  @override
  String get searchResultsSemanticLabel => 'Resultados de búsqueda';

  @override
  String get searchCriteriaSemanticLabel =>
      'Resumen de los criterios de búsqueda. Toca para editar.';

  @override
  String get noFavoritesSemanticLabel =>
      'Aún no hay favoritos. Toca la estrella de una estación para guardarla como favorita.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'La estación está abierta',
      'false': 'La estación está cerrada',
      'other': 'La estación está cerrada',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'País $name, seleccionado',
      'false': 'País $name',
      'other': 'País $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Idioma $name, seleccionado',
      'false': 'Idioma $name',
      'other': 'Idioma $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Ordenar por $option, seleccionado',
      'false': 'Ordenar por $option',
      'other': 'Ordenar por $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Combustible $type, seleccionado',
      'false': 'Combustible $type',
      'other': 'Combustible $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Estación de carga $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Escudo de privacidad con gota de combustible';

  @override
  String get globeIllustrationSemantic =>
      'Globo con marcadores de estaciones de servicio';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Surtidor con indicador de precios';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, fuente de datos: $provider, $keyRequirement, tipos de combustible: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Se requiere clave API';

  @override
  String get countryInfoNoKeyNeeded => 'Gratis, sin clave';

  @override
  String countryInfoDataSource(String provider) {
    return 'Datos: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Tipos de combustible: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Clave anónima';

  @override
  String get anonKeyHideTooltip => 'Ocultar clave';

  @override
  String get anonKeyShowTooltip => 'Mostrar la clave para verificarla';

  @override
  String anonKeyTooLong(int length) {
    return 'La clave es demasiado larga ($length caracteres): comprueba si hay texto de más';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'La clave parece correcta ($length caracteres)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'La clave debería ser un JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'La clave puede estar truncada ($length de los ~208 caracteres esperados)';
  }

  @override
  String get anonKeyExceedsMax => 'La clave supera la longitud máxima';

  @override
  String get qrShareTitle => 'Comparte tu base de datos';

  @override
  String get qrShareSubtitle =>
      'Otros pueden escanear este código QR para conectarse';

  @override
  String get qrShareCopyAsText => 'Copiar como texto';

  @override
  String get authInfoTitle => '¿Por qué crear una cuenta?';

  @override
  String get authInfoBenefit1 =>
      '• Sincroniza favoritos, alertas y rutas guardadas entre dispositivos';

  @override
  String get authInfoBenefit2 =>
      '• Prepara una ruta en el teléfono y úsala en el coche';

  @override
  String get authInfoBenefit3 => '• No se comparte ningún dato con terceros';

  @override
  String get authInfoBenefit4 =>
      '• Puedes eliminar tu cuenta en cualquier momento';

  @override
  String get privacyLocalDataEmpty =>
      'Aún no hay nada almacenado. Añade un favorito o define una alerta de precio para ver entradas aquí.';

  @override
  String get privacyHideEmptyRows => 'Ocultar las filas vacías';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count filas vacías',
      one: 'Mostrar $count fila vacía',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Configuración de la clave de API (opcional)';

  @override
  String get apiKeySetupDescription =>
      'Regístrate para obtener una clave de API gratuita u omite este paso para explorar la app con datos de demostración.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Registro de $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Al introducir una clave de API aceptas las condiciones de $provider. Está prohibida la redistribución de datos.';
  }

  @override
  String get calculatorDistanceHint => 'p. ej. 150';

  @override
  String get calculatorConsumptionHint => 'p. ej. 7,0';

  @override
  String get calculatorPriceHint => 'p. ej. 1,899';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (experimental)';

  @override
  String get glideCoachBetaSubtitle =>
      'Vibración háptica sutil al frenar antes de un semáforo en rojo. Desactivado por defecto: riesgo de distracción.';

  @override
  String get consentSyncTripsTitle => 'Sincronizar grabaciones de viajes';

  @override
  String get consentSyncTripsSubtitle =>
      'Haz una copia de seguridad de los viajes OBD2 + GPS en TankSync. Entre dispositivos, opcional.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Activa la sincronización en la nube arriba para hacer copias de seguridad de los viajes.';

  @override
  String get consentSyncTripsAnonymousHint =>
      'Los viajes se guardan bajo la cuenta anónima de este dispositivo. Inicia sesión con un correo para acceder a ellos desde otros dispositivos.';

  @override
  String get consentHideDetails => 'Ocultar detalles';

  @override
  String get consentShowDetails => 'Mostrar detalles';

  @override
  String get dialogOk => 'Aceptar';

  @override
  String get invalidLinkTitle => 'Enlace no válido';

  @override
  String invalidLinkBody(String path) {
    return 'El enlace «$path» no es válido.';
  }

  @override
  String get home => 'Inicio';

  @override
  String get accelBrakeCardTitle => 'Aceleración y frenada';

  @override
  String get accelBrakeHardAccel => 'Aceleraciones bruscas';

  @override
  String get accelBrakeHardBrake => 'Frenadas bruscas';

  @override
  String get accelBrakeSharpCorner => 'Curvas cerradas';

  @override
  String get accelBrakeSource => 'De los sensores de movimiento del teléfono';

  @override
  String lessonHardBrake(String count) {
    return '$count eventos de frenada brusca';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Anticípate a las paradas y suelta el acelerador antes — la frenada brusca desperdicia el combustible que acabas de gastar para coger velocidad.';

  @override
  String lessonSharpCornering(String count) {
    return '$count curvas cerradas';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Frena antes de la curva, no en ella — tomar las curvas con fuerza reduce la velocidad que luego hay que recuperar.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Últimos $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Unidad de consumo';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Cómo se muestra el consumo de combustible en toda la app';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automático ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Ventana de consumo en directo';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Promedia el valor en directo sobre los últimos segundos: más largo es más estable, más corto reacciona antes';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'est. $unit';
  }

  @override
  String get locationConsentTitle => 'Acceso a la ubicación';

  @override
  String get locationConsentSubtitle =>
      'Esta aplicación quiere usar tu ubicación para encontrar gasolineras cerca de ti.';

  @override
  String get locationConsentWhatHappens =>
      'Qué pasa con tus datos de ubicación:';

  @override
  String get locationConsentBulletApi =>
      'Tus coordenadas se envían a la API de precios de combustible para encontrar gasolineras cercanas.';

  @override
  String get locationConsentBulletNoServer =>
      'Tu ubicación no se almacena en ningún servidor — no hay servidor.';

  @override
  String get locationConsentBulletNoTracking =>
      'Los datos de ubicación no se usan para publicidad, análisis ni seguimiento.';

  @override
  String get locationConsentRevoke =>
      'Puedes revocar el acceso a la ubicación en cualquier momento en los ajustes del sistema. También puedes buscar por código postal.';

  @override
  String get locationConsentLegalBasis =>
      'Base jurídica: art. 6.1.a) del RGPD (consentimiento)';

  @override
  String get loyaltySettingsTitle => 'Tarjetas de club de combustible';

  @override
  String get loyaltySettingsSubtitle =>
      'Aplica tu descuento de fidelización a los precios mostrados';

  @override
  String get loyaltyMenuTitle => 'Tarjetas de club de combustible';

  @override
  String get loyaltyMenuSubtitle =>
      'Aplica descuentos por litro de Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Añadir tarjeta';

  @override
  String get loyaltyAddCardSheetTitle =>
      'Añadir tarjeta de club de combustible';

  @override
  String get loyaltyBrandLabel => 'Marca';

  @override
  String get loyaltyCardLabelLabel => 'Etiqueta (opcional)';

  @override
  String get loyaltyDiscountLabel => 'Descuento (por litro)';

  @override
  String get loyaltyDiscountInvalid => 'Introduce un número positivo';

  @override
  String get loyaltyDeleteConfirmTitle => '¿Eliminar la tarjeta?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Esta tarjeta dejará de aplicar su descuento.';

  @override
  String get loyaltyEmptyTitle => 'Aún no hay tarjetas de club de combustible';

  @override
  String get loyaltyEmptyBody =>
      'Añade una tarjeta para aplicar automáticamente tu descuento por litro en las estaciones correspondientes.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Detectado aumento de las RPM en ralentí';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Las RPM en ralentí han subido un $percent % en tus últimos $tripCount viajes. Posible señal temprana de un filtro de aire obstruido o de una deriva del sensor.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Posible restricción en la admisión';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'El caudal de combustible en crucero ha bajado un $percent % en tus últimos $tripCount viajes. Posible señal de un filtro de aire obstruido o de una admisión restringida: conviene una revisión.';
  }

  @override
  String get maintenanceActionDismiss => 'Descartar';

  @override
  String get maintenanceActionSnooze => 'Posponer 30 días';

  @override
  String get consumptionMonthlyInsightsTitle => 'Este mes frente al mes pasado';

  @override
  String get consumptionMonthlyTripsLabel => 'Viajes';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Tiempo de conducción';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distancia';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Consumo medio';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Se necesitan al menos 3 viajes por mes para comparar';

  @override
  String get consumptionMonthlyClimbLabel => 'Desnivel acumulado';

  @override
  String get obd2CapabilitySectionTitle => 'Capacidades del adaptador';

  @override
  String get obd2CapabilityStandardOnly => 'Estándar';

  @override
  String get obd2CapabilityOemPids => 'PID OEM';

  @override
  String get obd2CapabilityFullCan => 'CAN completo';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Para conocer los litros exactos del depósito en Peugeot/Citroën, la app es compatible con OBDLink MX+/LX/CX (chip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Superposición de diagnóstico OBD2 activada';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Superposición de diagnóstico OBD2 desactivada';

  @override
  String get obd2DebugOverlayClearButton => 'Borrar';

  @override
  String get obd2DebugOverlayCloseButton => 'Cerrar';

  @override
  String get obd2DebugOverlayTitle => 'Rastro de OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Compartir registro de diagnóstico';

  @override
  String get obd2DebugLoggingTitle => 'Registro de depuración OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Registra cada sesión OBD2 — conexión, handshake, interrupciones de datos y reconexiones — en un registro XML exportable. Desactivado de forma predeterminada.';

  @override
  String get obd2DebugSessionShareLabel => 'Compartir registro de sesión OBD2';

  @override
  String get obd2DiagnosticsTitle => 'Estado de comunicación OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops cortes',
      one: '1 corte',
      zero: 'sin cortes',
    );
    return '$percent% completo · $duty% de actividad · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adaptador';

  @override
  String get obd2DiagnosticsConnectionSection => 'Ciclo de vida de la conexión';

  @override
  String get obd2DiagnosticsPidSection => 'Resultados por PID';

  @override
  String get obd2DiagnosticsReconnectSection => 'Telemetría de reconexión';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts intentos de reconexión · $successes correctos · $transitions transiciones · $disconnects desconexiones tipificadas';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'Respaldo solo GPS activado en esta sesión.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Estado del planificador';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Completitud';

  @override
  String get obd2DiagnosticsSupportSection => 'PIDs descubiertos y soportados';

  @override
  String get obd2DiagnosticsFuelSection => 'Resumen de nivel de combustible';

  @override
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  ) {
    return '$mac · $firmware · protocolo $protocol · MTU $mtu';
  }

  @override
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  ) {
    return '$attempts intentos · $successes correctos · $drops cortes · tiempo de conexión p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Reconexiones: $silent silenciosas · $visible visibles';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips saltos por contrapresión · $demotions degradaciones';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Nivel dinámico sin datos — RPM / velocidad cayeron por debajo del umbral del regulador.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Global $percent% · actividad efectiva $duty%';
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
    return '$supported soportados · $unsupported no soportados · $unknown desconocidos';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return '$suspicious muestras sospechosas de $total';
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
    return '$pid: $polled consultados · $ok correctos · $noData SD · $timeout TO · $error err · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection => 'Transcripción de inicio del dongle';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protocolo $protocol · $start · firmware $firmware · $tier · $pids PIDs';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'caliente';

  @override
  String get obd2DiagnosticsInitCold => 'frío';

  @override
  String get obd2DiagnosticsEmpty =>
      'No hay ninguna sesión OBD2 registrada — conecta un adaptador y graba un viaje con el modo Desarrollador activado.';

  @override
  String get obd2DiagnosticsExplain =>
      'Capturado durante la grabación para depurar la comunicación dongle↔app — solo se recopila en modo Desarrollador.';

  @override
  String get obd2HealthScreenTitle => 'Estado de comunicación OBD2';

  @override
  String get obd2HealthNavLabel => 'Estado de comunicación OBD2';

  @override
  String get obd2HealthLiveSection => 'Sesión en directo';

  @override
  String get obd2HealthHistorySection => 'Sesiones recientes';

  @override
  String get obd2HealthDownloadJson => 'Descargar como JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Descargar solo la transcripción de inicialización';

  @override
  String get obd2HealthDownloadError =>
      'No se pudo guardar el archivo de diagnóstico';

  @override
  String get obd2TestAdapterLabel => 'Adaptador a probar';

  @override
  String get obd2TestAdapterScanOption => 'Buscar adaptador';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Conectar con $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Ejecutar prueba del adaptador';

  @override
  String get obd2TestRunButton => 'Ejecutar prueba del adaptador';

  @override
  String get obd2TestRunPassed => 'Prueba del adaptador superada';

  @override
  String get obd2TestRunFailed => 'Prueba del adaptador fallida';

  @override
  String get obd2TestRunEngineOff =>
      'Adaptador OK, motor apagado: arranca el motor para leer datos en vivo';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed de $total pasos correctos · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Detén la grabación activa antes de ejecutar la prueba del adaptador.';

  @override
  String get obd2TestStepScan => 'Buscar adaptador';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth del teléfono';

  @override
  String get obd2TestStepConnect => 'Conectar e iniciar';

  @override
  String get obd2TestStepInfo => 'Info del adaptador';

  @override
  String get obd2TestStepSupportedPids => 'PIDs soportados';

  @override
  String get obd2TestStepProtocol => 'Protocolo del vehículo';

  @override
  String get obd2TestStepSampleReads => 'Lecturas de muestra';

  @override
  String get obd2TestStepSoak => 'Sondeo sostenido';

  @override
  String get obd2TestStepReconnect => 'Prueba de reconexión';

  @override
  String get obd2TestStepDisconnect => 'Desconectar';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Tiempo agotado';

  @override
  String get obd2TestStatusGarbage => 'Respuesta ilegible';

  @override
  String get obd2TestStatusNoResponse => 'Sin respuesta';

  @override
  String get obd2TestStatusFail => 'Fallido';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown => 'desconocido: BLE por defecto';

  @override
  String get obd2HealthConnectAttemptsSection =>
      'Intentos de conexión recientes';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Aún no hay intentos de conexión registrados.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Descargar traza de conexión';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Descargar todas las trazas de conexión';

  @override
  String get obd2HealthConnectOrigin => 'Origen';

  @override
  String get obd2HealthConnectTransport => 'Transporte';

  @override
  String get obd2HealthConnectOutcome => 'Resultado';

  @override
  String get obd2HealthConnectScanList => 'Dispositivos detectados';

  @override
  String get obd2HealthConnectSteps => 'Pasos';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Adaptador desconocido';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Sesión registrada · $samples muestras del motor · $percent % de cobertura';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection =>
      'Lo que registró este trayecto';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples de $total muestras traían datos del motor ($percent %)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adaptador: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Negociación del protocolo: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Sesión finalizada: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Duración de la sesión: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Las cifras de consumo vienen del adaptador, no de estimaciones por GPS.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'El desglose de comunicación por PID no se capturó en este trayecto. Activa el modo desarrollador antes de grabar para recogerlo.';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'No se pudo contactar con «$adapterName»: elige otro adaptador';
  }

  @override
  String get obd2PickerOtherDevices => 'Otros dispositivos Bluetooth';

  @override
  String get obd2PickerTapToTry => 'No reconocido: toca para probar';

  @override
  String get obd2PickerBleOnlyNotice =>
      'El iPhone solo funciona con adaptadores Bluetooth LE. Un adaptador solo Classic (p. ej. vLinker BM, Konnwei KW902) debe usarse en Android.';

  @override
  String get obd2PairingConfirmHint =>
      'Confirma la solicitud de emparejamiento en tu teléfono';

  @override
  String get obd2ScanEmptyTitle => 'No se encontró ningún adaptador';

  @override
  String get obd2ScanEmptyReady =>
      'El Bluetooth está encendido y los permisos concedidos. Asegúrate de que el adaptador está enchufado al puerto OBD2 y el contacto dado, y vuelve a buscar.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Este dispositivo no tiene hardware Bluetooth Low Energy, así que no puede conectarse a un adaptador OBD2.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'El Bluetooth está apagado. Enciéndelo para buscar tu adaptador.';

  @override
  String get obd2ScanBlockedPermission =>
      'Sparkilo necesita el permiso de Bluetooth para encontrar tu adaptador.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'El permiso de Bluetooth se denegó de forma permanente. Concédelo en los ajustes del sistema para buscar tu adaptador.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Los servicios de ubicación están desactivados en este dispositivo. Android necesita que estén activados para buscar adaptadores Bluetooth; no se registra ni se comparte ninguna ubicación.';

  @override
  String get obd2ScanOpenSettings => 'Abrir ajustes';

  @override
  String get obd2WaitingForEngineBanner =>
      'Esperando al motor: grabando con GPS';

  @override
  String get obd2StartEngineToReconnect => 'Arranca el motor para reconectar';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motor apagado: arráncalo para reconectar';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motor apagado desde hace $minutes min: ¿detener la grabación?';
  }

  @override
  String get obd2ParkedPromptStop => 'Detener';

  @override
  String get obd2ParkedPromptKeep => 'Seguir';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motor apagado durante los primeros $head y los últimos $tail de este viaje: la cobertura se mide con el motor en marcha.';
  }

  @override
  String get obd2ReconnectInProgress => 'Reconectando con tu adaptador OBD2…';

  @override
  String get obd2StatusEngineOff => 'OBD2 en pausa: motor apagado';

  @override
  String get obd2StatusEngineOffBody =>
      'El adaptador estaba accesible pero el bus del vehículo permaneció en silencio, así que la reconexión automática está en pausa. Se reanuda cuando conduces o vuelves a abrir la app, o reconecta ahora.';

  @override
  String get obd2StatusReconnectNow => 'Reconectar ahora';

  @override
  String get autoRecordNotificationTitle => 'Grabación automática de viajes';

  @override
  String get autoRecordNotificationText => 'Vigilando tu adaptador OBD2';

  @override
  String get obd2ResetConnection => 'Restablecer conexión';

  @override
  String get obd2ResetConnectionDone =>
      'Adaptador restablecido: conexión recuperada';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adaptador restablecido: reconectando en segundo plano';

  @override
  String get ocrTesterTitle => 'Probador OCR';

  @override
  String get ocrTesterNavLabel => 'Probador OCR';

  @override
  String get ocrTesterExplain =>
      'Ejecuta el proceso OCR de surtidor/ticket en una foto seleccionada e inspecciona cada paso — solo disponible en modo Desarrollador.';

  @override
  String get ocrTesterCapture => 'Capturar';

  @override
  String get ocrTesterPickImage => 'Seleccionar imagen';

  @override
  String get ocrTesterRun => 'Ejecutar';

  @override
  String get ocrTesterCountry => 'País';

  @override
  String get ocrTesterCountryNone => 'Predeterminado (sin perfil)';

  @override
  String get ocrTesterNoImage =>
      'Selecciona o captura una imagen y luego ejecuta.';

  @override
  String get ocrTesterRunning => 'Ejecutando OCR…';

  @override
  String get ocrTesterOverlaySection => 'Superposición de bloques';

  @override
  String get ocrTesterStepsSection => 'Pasos del proceso';

  @override
  String get ocrTesterLegendLabel => 'Etiqueta';

  @override
  String get ocrTesterLegendNumeric => 'Numérico';

  @override
  String get ocrTesterLegendNoise => 'Ruido';

  @override
  String get ocrTesterLegendDerived => 'Derivado';

  @override
  String get ocrTesterStageGlare => 'Captura / deslumbramiento';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Clasificar';

  @override
  String get ocrTesterStageAssemble => 'Ensamblar';

  @override
  String get ocrTesterStageAnchor => 'Ancla';

  @override
  String get ocrTesterStageFallback => 'Alternativa';

  @override
  String get ocrTesterStageCrossCheck => 'Verificación cruzada';

  @override
  String get ocrTesterStageConfidence => 'Confianza';

  @override
  String get ocrTesterStageGate => 'Filtro';

  @override
  String get ocrTesterStageBrand => 'Marca';

  @override
  String get ocrTesterStageOverrides => 'Sobreescrituras';

  @override
  String get ocrTesterStageReconcile => 'Reconciliar';

  @override
  String get ocrTesterStageResult => 'Resultado';

  @override
  String get ocrTesterChipRead => 'LEÍDO';

  @override
  String get ocrTesterChipDerived => 'DERIVADO';

  @override
  String get ocrTesterGateAccepted => 'Aceptado';

  @override
  String get ocrTesterGateRejected => 'Rechazado';

  @override
  String get ocrTesterFallbackBanner =>
      'Un campo se recuperó mediante el método alternativo de magnitud — verifícalo.';

  @override
  String get ocrTesterStageNoData => 'La etapa no se ejecutó.';

  @override
  String get ocrTesterCopyJson => 'Copiar como JSON';

  @override
  String get ocrTesterExportPackage => 'Exportar paquete';

  @override
  String get ocrTesterCopied => 'Traza OCR copiada al portapapeles.';

  @override
  String get ocrTesterExported =>
      'Paquete OCR guardado en la carpeta Descargas.';

  @override
  String get onboardingObd2StepTitle => 'Conecta tu adaptador OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Conecta tu adaptador OBD2 al puerto del coche y enciende el contacto. Leeremos el VIN y rellenaremos por ti los detalles del motor.';

  @override
  String get onboardingObd2ConnectButton => 'Conectar adaptador';

  @override
  String get onboardingObd2SkipButton => 'Quizás más tarde';

  @override
  String get onboardingObd2ReadingVin => 'Leyendo el VIN…';

  @override
  String get onboardingObd2ConnectFailed =>
      'No se pudo conectar con el adaptador. Puedes reintentarlo u omitir este paso.';

  @override
  String get onboardingPickUseMode => 'Elige un modo de uso para continuar.';

  @override
  String get onboardingObd2LaterNote =>
      'Puedes emparejar un adaptador OBD2 Bluetooth más adelante desde la pantalla del vehículo para grabar viajes y leer datos del motor.';

  @override
  String get openHoursUnknown => 'Horario desconocido';

  @override
  String get open24Hours => 'Abierto 24 horas';

  @override
  String get openingHoursAutomate24h => 'Self-service pump 24/7 (card payment)';

  @override
  String get dayMon => 'Lunes';

  @override
  String get dayTue => 'Martes';

  @override
  String get dayWed => 'Miércoles';

  @override
  String get dayThu => 'Jueves';

  @override
  String get dayFri => 'Viernes';

  @override
  String get daySat => 'Sábado';

  @override
  String get daySun => 'Domingo';

  @override
  String get dayShortMon => 'Lun';

  @override
  String get dayShortTue => 'Mar';

  @override
  String get dayShortWed => 'Mié';

  @override
  String get dayShortThu => 'Jue';

  @override
  String get dayShortFri => 'Vie';

  @override
  String get dayShortSat => 'Sáb';

  @override
  String get dayShortSun => 'Dom';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Festivos';

  @override
  String get closedLabel => 'Cerrado';

  @override
  String get openingHoursNotAvailable => 'Horario no disponible';

  @override
  String get showAllHours => 'Mostrar todo el horario';

  @override
  String get showLessHours => 'Mostrar menos';

  @override
  String get openStateUnknown => 'Desconocido';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Gasolinera abierta',
      'false': 'Gasolinera cerrada',
      'other': 'Estado de apertura desconocido',
    });
    return '$_temp0';
  }

  @override
  String get permissionRationaleCameraTitle => 'Acceso a la cámara';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Esta aplicación quiere usar tu cámara para leer recibos, pantallas de surtidor y códigos QR.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'Qué pasa con la imagen de la cámara:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'La imagen se usa solo para leer el recibo, la pantalla del surtidor o el código QR — el reconocimiento se ejecuta en tu dispositivo.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'La foto se descarta después del escaneo.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'No se sube nada a menos que envíes un informe de escaneo erróneo y lo confirmes.';

  @override
  String get permissionRationaleBluetoothTitle => 'Acceso a Bluetooth';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Esta aplicación quiere usar Bluetooth para conectarse a tu adaptador OBD2.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'Qué pasa con Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'Bluetooth se usa solo para encontrar tu adaptador OBD2 y comunicarse con él.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'El identificador del adaptador permanece en tu dispositivo — solo se sincroniza mediante TankSync, como parte del perfil del vehículo.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'En Android 11 y versiones anteriores el sistema también pide la ubicación, porque allí la búsqueda por Bluetooth se considera un permiso de ubicación.';

  @override
  String get permissionRationaleNotificationsTitle => 'Notificaciones';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Esta aplicación quiere enviarte notificaciones sobre alertas de precios y el estado de la grabación de trayectos.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'Qué pasa con las notificaciones:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'Las notificaciones se usan para alertas de precios locales y el estado de la grabación de trayectos.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'Se generan en tu dispositivo — nada sale del dispositivo.';

  @override
  String get permissionRationaleRevoke =>
      'Puedes revocar esto en cualquier momento en los ajustes de tu dispositivo.';

  @override
  String get permissionRationaleLegalBasis =>
      'Base jurídica: art. 6.1.a) del RGPD (consentimiento)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Valor estimado (~) — sin sensor de combustible en este viaje, por lo que la cifra de L/100 km se modela a partir de la velocidad GPS y la calibración de tu vehículo. Es aproximada (típicamente ±10–30 %, mejorando con la calibración), no una lectura medida.';

  @override
  String get tripRecordingPipElapsedCaption => 'transcurrido';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: estimaciones de consumo reajustadas al surtidor ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => '¿Abrir el enlace escaneado?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Este código QR apunta a $host. Abre solo enlaces de confianza.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Abrir enlace';

  @override
  String get qrLaunchConfirmCancel => 'Cancelar';

  @override
  String get radarPinHelpTitle => 'Acerca de fijar';

  @override
  String get radarPinHelpBody =>
      'Fijar mantiene la pantalla encendida y oculta las barras del sistema para que la lectura de la gasolinera más cercana sea legible en el soporte del salpicadero. Toca de nuevo para soltar. Se libera automáticamente cuando el radar se detiene.';

  @override
  String get radarAutoPinTitle => 'Fijar siempre al iniciar el radar';

  @override
  String get radarAutoPinSubtitle =>
      'Fija el radar automáticamente cada vez en lugar de tocar cada vez. Consume más batería.';

  @override
  String get radarScopeShowScope => 'Vista de radar';

  @override
  String get radarScopeShowList => 'Vista de lista';

  @override
  String get alertsRadiusFrequencyLabel => 'Frecuencia de comprobación';

  @override
  String get alertsRadiusFrequencyDaily => 'Una vez al día';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Dos veces al día';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Tres veces al día';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Cuatro veces al día';

  @override
  String get radiusAlertPickOnMap => 'Elegir en el mapa';

  @override
  String get radiusAlertMapPickerTitle => 'Elige el centro de la alerta';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirmar';

  @override
  String get radiusAlertMapPickerCancel => 'Cancelar';

  @override
  String get radiusAlertMapPickerHint =>
      'Arrastra el mapa para situar el centro de la alerta';

  @override
  String get reconcileWorkflowTitle => 'Reconciliar tu combustible';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Encontramos una diferencia de $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Repostaste $pumped L, pero tus viajes registrados solo acumulan $consumed L. Quedan $gap L sin explicar.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Normalmente significa que un trayecto no se grabó (el adaptador estaba desconectado o la app estaba cerrada), o falta un repostaje o está mal introducido.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Hasta que se resuelva, el total de combustible y el total de viajes no coincidirán.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Ayúdanos a atribuir la diferencia';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      '¿Están completos y correctos todos tus repostajes de este depósito?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      '¿Están registrados todos tus trayectos?';

  @override
  String get reconcileWorkflowAnswerYes => 'Sí';

  @override
  String get reconcileWorkflowAnswerNo => 'No';

  @override
  String get reconcileWorkflowPathAHint =>
      'Falta un repostaje o está mal — añadiremos una corrección para que los repostajes cuadren.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Tus repostajes son correctos y falta un trayecto grabado — añadiremos un viaje virtual para la distancia que falta.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Litros de corrección';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      '¿Cuánto fue el trayecto no registrado? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Decidir más tarde';

  @override
  String get reconcileWorkflowBack => 'Atrás';

  @override
  String get reconcileWorkflowNext => 'Siguiente';

  @override
  String get reconcileWorkflowApply => 'Aplicar';

  @override
  String get reconcileVirtualTrajetLabel => 'Viaje virtual — toca para editar';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Editar viaje virtual';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Este viaje se añadió para compensar el combustible usado mientras conducías sin grabar. Ajusta la distancia o el combustible, o elimínalo.';

  @override
  String get reconcileVirtualTrajetDelete => 'Eliminar viaje virtual';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Diferencia de combustible/viaje sin resolver de $gap L — toca para resolver';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Resolver la diferencia de combustible y viajes sin resolver';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sesión';

  @override
  String get settingsSearchHint => 'Buscar ajustes';

  @override
  String settingsSearchNoResults(String query) {
    return 'Ningún ajuste coincide con «$query»';
  }

  @override
  String get settingsTopicProfilesTitle => 'Perfiles y región';

  @override
  String get settingsTopicProfilesSubtitle =>
      'País, idioma, combustible, radio de búsqueda, planificación de rutas';

  @override
  String get settingsTopicProfilesKeywords =>
      'perfil, país, idioma, combustible, radio, código postal, ruta, casa, valoración, pantalla de inicio, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Vehículos y OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Tus coches, tamaño del depósito, emparejamiento del adaptador OBD2';

  @override
  String get settingsTopicVehiclesKeywords =>
      'vehículo, coche, obd, obd2, adaptador, bluetooth, depósito, motor, vin, calibración, vehicle, car, adapter, tank, engine';

  @override
  String get settingsTopicDrivingTitle => 'Conducción y consumo';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, recompensas, radar de gasolineras, solución de problemas';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, eco, háptico, voz, gamificación, radar, inercia, viaje, consumo, club de combustible, fidelidad, registro obd2, fijar, haptic, voice, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Precios y alertas';

  @override
  String get settingsTopicPricesSubtitle =>
      'Alertas de precio, avisos por voz, historial de precios, reportes de la comunidad';

  @override
  String get settingsTopicPricesKeywords =>
      'alerta, notificación, precio, historial, predicción, mejor momento, comunidad, reporte, qr, pago, voz, aviso, alert, price, history, prediction, community, report, payment, voice';

  @override
  String get settingsTopicUnitsTitle => 'Unidades y visualización';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Tema, unidad de distancia, widget de pantalla de inicio';

  @override
  String get settingsTopicUnitsKeywords =>
      'tema, oscuro, claro, eco, unidad, km, millas, widget, color, visualización, apariencia, theme, dark, light, unit, miles, display';

  @override
  String get settingsTopicFeaturesTitle => 'Funciones y modo de uso';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Ajustes predefinidos del modo de uso y todos los interruptores de funciones';

  @override
  String get settingsTopicFeaturesKeywords =>
      'función, modo, básico, medio, completo, personalizado, interruptor, tipos de estación, gasolineras, cargadores, carga, feature, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Fuentes de datos y ubicación';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'Claves API, posición GPS, cambio automático de perfil';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, clave, gps, ubicación, posición, fuente de datos, tankerkoenig, opencharge, key, location';

  @override
  String get settingsTopicSyncTitle => 'Sincronización y cuenta';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, nube, cuenta, correo, vincular dispositivo, sincronización, compartir base de datos, anónimo, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacySubtitle =>
      'Consentimientos, panel de privacidad, almacenamiento y caché';

  @override
  String get settingsTopicPrivacyKeywords =>
      'privacidad, consentimiento, rgpd, borrar, eliminar, almacenamiento, caché, datos, informe de errores, vin, privacy, consent, gdpr, delete, erase, storage, data, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Copia de seguridad y restauración';

  @override
  String get settingsTopicBackupSubtitle =>
      'Exportar o restaurar una copia completa de tus datos';

  @override
  String get settingsTopicBackupKeywords =>
      'copia de seguridad, exportar, restaurar, importar, zip, xml, transferir, backup, export, restore, import, transfer';

  @override
  String get settingsTopicAdvancedSubtitle =>
      'Token de GitHub, herramientas de desarrollo';

  @override
  String get settingsTopicAdvancedKeywords =>
      'desarrollador, depuración, token, pat, github, diagnóstico, registro de errores, traza, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Versión, licencias, enlaces';

  @override
  String get settingsTopicAboutKeywords =>
      'acerca de, versión, licencia, donar, github, atribución, about, version, license, donate';

  @override
  String get settingsConsumptionOffHint =>
      'Activa el seguimiento del consumo en Funciones y modo de uso para configurar vehículos, coaching y recompensas.';

  @override
  String get settingsOpenFeaturesLink => 'Abrir Funciones y modo de uso';

  @override
  String get settingsRadarTileSubtitle =>
      'Radio, modo de precio, sondeo y fijación de pantalla para el perfil activo';

  @override
  String get settingsRadarNoProfileHint =>
      'Crea primero un perfil: los ajustes del radar se guardan por perfil.';

  @override
  String get settingsRadarPinHeader => 'Fijación de pantalla';

  @override
  String get settingsAlertsTileSubtitle =>
      'Alertas de gasolinera y de radio que te avisan de bajadas de precio';

  @override
  String get settingsPriceFeaturesHeader => 'Funciones de precios';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Los avisos por voz están desactivados. Activa Respuesta por voz y Avisos por voz en Funciones y modo de uso para oír combustible barato cercano mientras conduces.';

  @override
  String get settingsDistanceUnitTitle => 'Unidad de distancia';

  @override
  String get settingsDistanceUnitSubtitle => 'Según el país del perfil activo';

  @override
  String get settingsObd2AdapterTitle => 'Adaptador OBD2';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Los adaptadores se emparejan por vehículo: abre un vehículo para emparejar o cambiar su adaptador';

  @override
  String get settingsStorageDeleteHint =>
      'Todos los datos locales se eliminan desde el panel de privacidad.';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Consentimientos';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Los consentimientos de Cloud Sync y de sincronización de viajes están en Privacidad y datos';

  @override
  String get settingsBackupExportSubtitle =>
      'Vehículos, repostajes, viajes y registros de carga en un archivo ZIP';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Combina o reemplaza tus datos desde un ZIP de copia de seguridad anterior';

  @override
  String get settingsStationTypesLink =>
      'Los tipos de estación se configuran en Funciones y modo de uso';

  @override
  String get routeSearchCriterionLabel =>
      'Elección de gasolinera por tramo de ruta';

  @override
  String get routeSearchCriterionCheapest => 'La más barata';

  @override
  String get routeSearchCriterionNearest => 'La más cercana a la ruta';

  @override
  String get routeSearchTopNLabel => 'Candidatas por punto de muestreo';

  @override
  String routeSearchTopNCaption(int count) {
    return 'Se consideran hasta $count gasolineras en cada punto a lo largo de la ruta.';
  }

  @override
  String get hybridFuelChoiceLabel =>
      'Combustible para la búsqueda de precios (híbrido)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Predeterminado del vehículo';

  @override
  String get scopeThisProfile => 'Este perfil';

  @override
  String get scopeAllProfiles => 'Todos los perfiles';

  @override
  String get scopeThisVehicle => 'Este vehículo';

  @override
  String get featureLabel_manualConsumption => 'Registro manual del consumo';

  @override
  String get featureDescription_manualConsumption =>
      'Registra repostajes y sesiones de carga a mano (no se necesita adaptador OBD2).';

  @override
  String get featureLabel_loyaltyCards => 'Tarjetas de fidelidad';

  @override
  String get featureDescription_loyaltyCards =>
      'Tarjetas de club de combustible / fidelidad con descuentos por litro en las comparaciones de precios.';

  @override
  String get featureLabel_startupTrace => 'Traza de inicialización al arrancar';

  @override
  String get featureDescription_startupTrace =>
      'Registra las fases cronometradas del arranque de la app, las muestra en cascada y las exporta: un diagnóstico para desarrolladores.';

  @override
  String get locationGpsAutoHint =>
      'La posición GPS se obtiene automáticamente al buscar. También puedes actualizarla manualmente aquí.';

  @override
  String get locationClearGpsBody =>
      '¿Borrar la posición GPS guardada? Puedes actualizarla de nuevo en cualquier momento.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Este tipo de archivo no puede importarse todavía — comparte una foto del ticket.';

  @override
  String get shareReceiptFailed =>
      'No se pudo leer el ticket compartido — inténtalo de nuevo o añade el repostaje manualmente.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Compartir ticket para importar';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Comparte una foto del ticket desde otra app para rellenar automáticamente un repostaje — fecha, litros, total y gasolinera se leen en el dispositivo.';

  @override
  String get speedConsumptionCardTitle => 'Consumo por velocidad';

  @override
  String get speedBandIdleJam => 'Ralentí / atasco';

  @override
  String get speedBandUrban => 'Urbano (10-50)';

  @override
  String get speedBandSuburban => 'Periurbano (50-80)';

  @override
  String get speedBandRural => 'Rural (80-100)';

  @override
  String get speedBandMotorwaySlow => 'Crucero eco (100-115)';

  @override
  String get speedBandMotorway => 'Autopista (115-130)';

  @override
  String get speedBandMotorwayFast => 'Autopista rápida (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Graba más de 30 minutos de viajes con el adaptador OBD2 para desbloquear el análisis de velocidad/consumo.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % de la conducción';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Se necesitan más datos';

  @override
  String get splashLoadingLabel => 'Cargando Sparkilo';

  @override
  String get storageRecoveryTitle => 'Problema de almacenamiento';

  @override
  String get storageRecoveryMessage =>
      'Sparkilo no pudo abrir su almacén de datos local. El archivo de almacenamiento parece estar dañado.';

  @override
  String get storageRecoveryGuidance =>
      'Para recuperarlo, borra el almacenamiento de la aplicación en los ajustes del dispositivo o reinstala la aplicación. Tus favoritos y tu historial se guardan solo en este dispositivo, por lo que no se pueden restaurar automáticamente.';

  @override
  String syncAdoptTitle(String email) {
    return 'Unirse a la cuenta de $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Inicia sesión con la contraseña de esta cuenta para compartir sus datos entre los dos dispositivos.';

  @override
  String get syncAdoptPasswordLabel => 'Contraseña de la cuenta';

  @override
  String get syncAdoptJoinButton => 'Unirse a la cuenta';

  @override
  String get syncAdoptUseDifferentAccount => 'Usar otra cuenta';

  @override
  String get syncDeleteDataTitle => 'Eliminar datos sincronizados';

  @override
  String get syncDeleteDataSubtitle =>
      'Eliminar tus viajes, vehículos o repostajes de la base de datos de sincronización';

  @override
  String get syncDeleteDataPickTitle =>
      '¿Qué datos sincronizados quieres eliminar?';

  @override
  String get syncDeleteDataCategoryTrips => 'Viajes';

  @override
  String get syncDeleteDataCategoryVehicles => 'Vehículos';

  @override
  String get syncDeleteDataCategoryFillUps => 'Repostajes';

  @override
  String get syncDeleteDataCategoryEverything => 'Todo';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return '¿Eliminar $category de la base de datos de sincronización?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Esto elimina los datos seleccionados de tu base de datos de sincronización y no volverán a sincronizarse desde tus otros dispositivos. Los datos guardados localmente en este dispositivo se conservan.';

  @override
  String get syncDeleteDataConfirmAction => 'Eliminar del servidor';

  @override
  String get syncDeleteDataDone => 'Datos sincronizados eliminados';

  @override
  String get syncDeleteDataFailed =>
      'No se pudieron eliminar los datos sincronizados: inténtalo de nuevo';

  @override
  String get syncRelinkTitle =>
      'La sincronización en la nube necesita volver a vincularse';

  @override
  String get syncRelinkBody =>
      'La identidad de sincronización guardada en este dispositivo ha cerrado sesión. Inicia sesión con tu correo para volver a vincular tus datos sincronizados, o empieza de cero con una identidad nueva.';

  @override
  String get syncRelinkSignInAction => 'Iniciar sesión para volver a vincular';

  @override
  String get syncRelinkStartFreshAction => 'Empezar de cero';

  @override
  String get syncRelinkStartFreshTitle => '¿Empezar de cero?';

  @override
  String get syncRelinkStartFreshBody =>
      'Se creará una identidad anónima nueva para este dispositivo. Los datos sincronizados con la identidad anterior permanecen en el servidor, pero ya no serán accesibles desde aquí a menos que inicies sesión con su cuenta de correo.';

  @override
  String get syncRelinkStartFreshConfirm => 'Empezar de cero';

  @override
  String get tankLevelTitle => 'Nivel del depósito';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km de autonomía';
  }

  @override
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km con el consumo de tu último depósito';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Media a largo plazo: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Último repostaje: $date · $count viaje(s) desde entonces';
  }

  @override
  String get tankLevelEmptyNoFillUp =>
      'Registra un repostaje para ver el nivel de tu depósito';

  @override
  String get tankLevelDetailSheetTitle => 'Viajes desde el último repostaje';

  @override
  String get addFillUpIsFullTankLabel => 'Depósito lleno';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Depósito lleno hasta el tope: desmárcalo si fue un repostaje parcial';

  @override
  String tankLevelSourceFillUp(String date) {
    return 'Anclado al último repostaje: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'Sensor de depósito OBD2 · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Mezcla del depósito: $mix';
  }

  @override
  String get tankReportTitle => 'Informe del depósito';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Desde el depósito lleno anterior: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km más que el depósito anterior';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km menos que el depósito anterior';
  }

  @override
  String get tankReportTrendFlat => 'Igual que el depósito anterior';

  @override
  String get tankReportNoPrevious =>
      'La evolución aparecerá tras tu próximo depósito lleno.';

  @override
  String get tankReportExplainHeader => 'Lo que sugieren las grabaciones';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Cuota a altas revoluciones $cur % (antes $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Maniobras bruscas $cur/100 km (antes $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Arranques en frío $cur (antes $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Cuota al ralentí $cur % (antes $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'Las grabaciones son espontáneas y cubren solo parte de este depósito: estas pistas son orientativas, no la historia completa.';

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'Sistema';

  @override
  String get themeCardSubtitleLight => 'Claro';

  @override
  String get themeCardSubtitleDark => 'Oscuro';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Según el sistema';

  @override
  String get themeSettingsLightLabel => 'Claro';

  @override
  String get themeSettingsDarkLabel => 'Oscuro';

  @override
  String get themeSettingsSystemDescription =>
      'Coincide con la apariencia actual del dispositivo.';

  @override
  String get themeSettingsLightDescription =>
      'Fondos claros: ideal para el uso diurno.';

  @override
  String get themeSettingsDarkDescription =>
      'Fondos oscuros: más agradables para la vista de noche y ahorran batería en pantallas OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'El aspecto verde característico de la app: luminoso y fácil de leer, con fondos teñidos de un verde suave.';

  @override
  String get throttleRpmHistogramTitle => 'Cómo usaste el motor';

  @override
  String get throttleRpmHistogramThrottleSection => 'Posición del acelerador';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM del motor';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Sin acelerar (0-25 %)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Suave (25-50 %)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Firme (50-75 %)';

  @override
  String get throttleRpmHistogramThrottleWide => 'A fondo (75-100 %)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Ralentí (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Crucero (901-2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Animado (2001-3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Fuerte (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'No hay muestras de acelerador ni de RPM en este viaje.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct %';
  }

  @override
  String get trajetsTabLabel => 'Viajes';

  @override
  String get trajetsStartRecordingButton => 'Iniciar grabación';

  @override
  String get trajetsResumeRecordingButton => 'Reanudar grabación';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Conectando con el adaptador OBD2…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Leyendo los datos del vehículo…';

  @override
  String get tripStartProgressStartingRecording => 'Iniciando la grabación…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalizando resumen…';

  @override
  String get tripSaveProgressSavingToHistory => 'Guardando en el historial…';

  @override
  String get tripSaveProgressSyncingToCloud =>
      'Sincronizando en segundo plano…';

  @override
  String get trajetsEmptyStateTitle => 'Aún no hay viajes';

  @override
  String get trajetsEmptyStateBody =>
      'Toca Iniciar grabación para empezar a registrar tus trayectos.';

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
  String get trajetDetailSummaryTitle => 'Resumen';

  @override
  String get trajetDetailFieldDate => 'Fecha';

  @override
  String get trajetDetailFieldVehicle => 'Vehículo';

  @override
  String get trajetDetailFieldAdapter => 'Adaptador OBD2';

  @override
  String get trajetDetailFieldDistance => 'Distancia';

  @override
  String get trajetDetailFieldDuration => 'Duración';

  @override
  String get trajetDetailFieldAvgConsumption => 'Consumo medio';

  @override
  String get trajetDetailFieldFuelUsed => 'Combustible usado';

  @override
  String get trajetDetailFieldFuelCost => 'Coste del combustible';

  @override
  String get trajetDetailFieldAvgSpeed => 'Velocidad media';

  @override
  String get trajetDetailFieldMaxSpeed => 'Velocidad máxima';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Velocidad (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Caudal de combustible (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Carga del motor (%)';

  @override
  String get trajetDetailChartThrottle => 'Acelerador / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Refrigerante (°C)';

  @override
  String get trajetDetailChartAltitudeRelative =>
      'Altitud (m, desde el inicio)';

  @override
  String get trajetDetailChartLambda => 'λ demandada';

  @override
  String get trajetDetailChartsSection => 'Gráficos';

  @override
  String get trajetsRowColdStartChip => 'Arranque en frío';

  @override
  String get trajetsRowColdStartTooltip =>
      'El motor no alcanzó la temperatura de funcionamiento durante este viaje: el consumo de combustible fue mayor de lo habitual.';

  @override
  String get trajetDetailChartEmpty => 'No se han registrado muestras';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimado';

  @override
  String get trajetDetailShareAction => 'Compartir';

  @override
  String get trajetDetailShareImageOption => 'Compartir imagen';

  @override
  String get trajetDetailShareGpxOption => 'Compartir traza GPS (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Sin datos GPS en este viaje';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo: viaje del $date';
  }

  @override
  String get trajetDetailShareError =>
      'No se pudo generar la imagen para compartir';

  @override
  String get trajetDetailDownloadCsvOption => 'Descargar telemetría (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Descargar telemetría (JSON)';

  @override
  String get trajetDetailDownloadError => 'No se pudo guardar el archivo';

  @override
  String get trajetDetailDeleteAction => 'Eliminar';

  @override
  String get trajetDetailDeleteConfirmTitle => '¿Eliminar este viaje?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Este viaje se eliminará de forma permanente de tu historial.';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Eliminar';

  @override
  String get tripRecordingObd2NotResponding =>
      'El adaptador OBD2 está conectado pero no devuelve datos. Prueba con otro adaptador o comprueba el protocolo de diagnóstico del vehículo.';

  @override
  String get trajetsViewAllOnMap => 'Ver todos en el mapa';

  @override
  String get trajetsMapTitle => 'Viajes en el mapa';

  @override
  String get trajetsMapShareGpx => 'Compartir GPX';

  @override
  String get trajetsMapEmpty =>
      'Ninguno de los viajes seleccionados tiene datos GPS.';

  @override
  String get trajetsMapShareError => 'No se pudo compartir el archivo GPX';

  @override
  String get trajetDetailChartBoost =>
      'Presión de sobrealimentación (MAP − ambiente)';

  @override
  String get trajetDetailChartIat => 'Temperatura del aire de admisión';

  @override
  String get trajetDetailChartTiming => 'Avance de encendido';

  @override
  String get trajetObd2Degraded =>
      'Iniciado con el adaptador OBD2 pero grabado sobre todo por GPS: los datos del motor están incompletos';

  @override
  String get tripLengthCardTitle => 'Consumo por longitud del viaje';

  @override
  String get tripLengthBucketShort => 'Corto (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Medio (5-25 km)';

  @override
  String get tripLengthBucketLong => 'Largo (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Se necesitan más datos';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '1 viaje',
      zero: 'sin viajes',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Ruta del viaje';

  @override
  String get tripPathCardSubtitle => 'Ruta registrada por GPS';

  @override
  String get tripPathLegendEfficient => 'Eficiente (< 6 L/100 km)';

  @override
  String get tripPathLegendBorderline => 'Justo (6-10 L/100 km)';

  @override
  String get tripPathLegendWasteful => 'Derrochador (≥ 10 L/100 km)';

  @override
  String get tripRadarClosestStation => 'Radar de gasolineras';

  @override
  String get tripRadarScanning => 'Buscando gasolineras cercanas';

  @override
  String get tripRadarNoStationNearby => 'No hay ninguna gasolinera cerca';

  @override
  String get fuelStationRadarNearer => 'Gasolinera más cercana';

  @override
  String get fuelStationRadarFarther => 'Gasolinera más lejana';

  @override
  String get fuelStationRadarStart => 'Iniciar radar de gasolineras';

  @override
  String get stopRadar => 'Detener radar';

  @override
  String get fuelStationRadarResultBadge =>
      'Resultado del Radar de gasolineras';

  @override
  String get radarUpdatingLocation => 'Actualizando tu ubicación…';

  @override
  String get radarSearching => 'Buscando…';

  @override
  String get highwayModeChip =>
      'Modo autopista: mostrando las gasolineras que tienes por delante en tu ruta';

  @override
  String get tripRecordingPinTooltip =>
      'Fijar mantiene la pantalla encendida: consume más batería';

  @override
  String get tripRecordingPinSemanticOn =>
      'Dejar de fijar el formulario de grabación';

  @override
  String get tripRecordingPinSemanticOff => 'Fijar el formulario de grabación';

  @override
  String get tripRecordingPinHelpTooltip => '¿Qué hace fijar?';

  @override
  String get tripRecordingPinHelpTitle => 'Acerca de fijar';

  @override
  String get tripRecordingPinHelpBody =>
      'Fijar mantiene la pantalla encendida y oculta las barras del sistema para que el formulario siga siendo legible en un soporte de salpicadero. Toca de nuevo para soltarlo. Se suelta automáticamente cuando el viaje se detiene.';

  @override
  String get tripRecordingResumeHintMessage =>
      'La grabación continúa en segundo plano. Toca el banner rojo de la parte superior de cualquier pantalla para volver.';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Fija la pantalla para mantener el GPS activo durante el viaje: Android puede limitar el GPS durante el reposo.';

  @override
  String get tripRecordingMinimiseTooltip => 'Minimizar a un mosaico flotante';

  @override
  String get tripRecordingAutoPinTitle =>
      'Fijar siempre al iniciar la grabación';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Fija el formulario automáticamente en cada trayecto en lugar de tocar cada vez. Consume más batería.';

  @override
  String get tripRecordingConnectingTitle => 'Iniciando grabación…';

  @override
  String get tripRecordingSavingTitle => 'Guardando viaje…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Grabación descartada — no se detectó movimiento';

  @override
  String get tripRecordingGpsNotificationTitle => 'Grabando tu viaje';

  @override
  String get tripRecordingGpsNotificationText =>
      'Rastreando tu ruta para las estadísticas de combustible y conducción';

  @override
  String get tripShareAction => 'Compartir con otra cuenta';

  @override
  String get tripShareSheetTitle => 'Compartir este trayecto';

  @override
  String get tripShareSheetSubtitle =>
      'Da a otra cuenta de TankSync acceso de solo lectura a este trayecto registrado.';

  @override
  String get tripShareEmailLabel => 'Correo del destinatario';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Compartir';

  @override
  String get tripShareCreateLinkButton => 'Crear enlace para compartir';

  @override
  String get tripShareLinkCreated =>
      'Enlace para compartir copiado: pégaselo al destinatario.';

  @override
  String get tripShareSuccess => 'Trayecto compartido.';

  @override
  String get tripShareRecipientNotFound =>
      'Ninguna cuenta de TankSync usa ese correo.';

  @override
  String get tripShareError =>
      'No se pudo compartir el trayecto. Inténtalo de nuevo.';

  @override
  String get tripShareExistingTitle => 'Compartido con';

  @override
  String get tripShareExistingEmpty => 'Aún no se ha compartido con nadie.';

  @override
  String get tripShareDirectRecipient => 'Una cuenta';

  @override
  String get tripShareLinkRecipient => 'Enlace para compartir (sin reclamar)';

  @override
  String get tripShareRevokeTooltip => 'Revocar';

  @override
  String get tripShareRevoked => 'Uso compartido revocado.';

  @override
  String get trajetsSharedSectionTitle => 'Compartido conmigo';

  @override
  String get trajetsSharedBadge => 'Compartido';

  @override
  String get tripVerdictPromptTitle => '¿Cómo ha ido este viaje?';

  @override
  String get tripVerdictSmooth => 'Suave';

  @override
  String get tripVerdictModerate => 'Moderado';

  @override
  String get tripVerdictAggressive => 'Agresivo';

  @override
  String get tripVerdictDismiss => 'Ahora no';

  @override
  String get tripVerdictThanks =>
      'Gracias: esto ayuda a calibrar el análisis de tu conducción.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Repostaje eliminado';

  @override
  String get trajetDeletedUndoSnackbar => 'Grabación eliminada';

  @override
  String get searchFailedSnackbar => 'Error en la búsqueda: inténtalo de nuevo';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gasolineras',
      one: '1 gasolinera',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Actualizado $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'También: $names';
  }

  @override
  String get favoriteAdd => 'Añadir a favoritos';

  @override
  String get favoriteRemove => 'Eliminar de favoritos';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Precio bruto: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Gasolinera sin marca';

  @override
  String get unsupportedRegionTitle => 'Aún no disponible en tu región';

  @override
  String get unsupportedRegionBody =>
      'Aún no tenemos precios de combustible para tu país, así que los resultados pueden estar vacíos o ser de otro país. Aun así puedes elegir un país compatible en los ajustes de búsqueda.';

  @override
  String get unsupportedRegionDismiss => 'Entendido';

  @override
  String get configureCountryTitle => 'Elige tu país';

  @override
  String get configureCountryBody =>
      'Tu país es compatible, pero aún no está configurado, así que los precios pueden ser de otro país. Elige tu país en los ajustes de búsqueda para ver los precios locales.';

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
      'Puedo repostar distintos tipos de combustible';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Registra qué combustible es más barato por kilómetro';

  @override
  String get vinLabel => 'VIN (opcional)';

  @override
  String get vinDecodeTooltip => 'Decodificar VIN';

  @override
  String get vinConfirmAction => 'Sí, rellenar automáticamente';

  @override
  String get vinModifyAction => 'Modificar manualmente';

  @override
  String get vehicleReadVinFromCarButton => 'Leer el VIN del coche';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Leer el VIN del adaptador OBD2 emparejado';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN no disponible (Modo 09 PID 02 no compatible en vehículos anteriores a 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Error al leer el VIN: introdúcelo manualmente';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Empareja primero un adaptador OBD2 para leer el VIN automáticamente';

  @override
  String get pickerButtonLabel => 'Elegir del catálogo';

  @override
  String get pickerSearchHint => 'Busca por marca o modelo';

  @override
  String get pickerHelpText =>
      'Rellena a partir de más de 50 vehículos compatibles';

  @override
  String get pickerEmptyResults => 'Sin coincidencias';

  @override
  String get pickerCancel => 'Cancelar';

  @override
  String get pickerLoading => 'Cargando el catálogo…';

  @override
  String get vinInfoTooltip => '¿Qué es un VIN?';

  @override
  String get vinInfoSectionWhatTitle => '¿Qué es un VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'El número de identificación del vehículo es un código de 17 caracteres único de tu coche. Está grabado en el chasis e impreso en el permiso de circulación de tu vehículo.';

  @override
  String get vinInfoSectionWhyTitle => 'Por qué lo pedimos';

  @override
  String get vinInfoSectionWhyBody =>
      'Al decodificar el VIN se rellenan automáticamente la cilindrada del motor, el número de cilindros, el año del modelo, el tipo de combustible principal y el peso bruto, lo que te ahorra tener que buscar las especificaciones técnicas manualmente. El cálculo del caudal de combustible por OBD2 usa estos valores para darte cifras de consumo precisas.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacidad';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Tu VIN se almacena solo localmente en el almacenamiento cifrado de la app: nunca se sube a los servidores de Sparkilo. La base de datos vPIC de la NHTSA se consulta con el VIN, pero solo devuelve especificaciones técnicas anónimas; la NHTSA no vincula el VIN a ningún dato personal. Sin red, una consulta sin conexión devuelve solo el fabricante y el país.';

  @override
  String get vinInfoSectionWhereTitle => 'Dónde encontrarlo';

  @override
  String get vinInfoSectionWhereBody =>
      'Mira a través del parabrisas, en la esquina inferior izquierda del lado del conductor; comprueba la pegatina del marco de la puerta del conductor con la puerta abierta; o léelo en el permiso de circulación de tu vehículo (tarjeta / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Entendido';

  @override
  String get vinConfirmPrivacyNote =>
      'Hemos consultado tu VIN en la base de datos gratuita de vehículos de la NHTSA: no se ha enviado nada a los servidores de Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Decodificación de VIN en línea';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Decodifica el VIN mediante el servicio público gratuito de la NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Cuando emparejas un adaptador, el VIN de tu vehículo se lee localmente para identificar el coche. Al activar esta opción se envía el VIN de 17 caracteres al servicio gratuito vPIC de la NHTSA para buscar detalles adicionales (modelo, cilindrada del motor, tipo de combustible). El VIN es el único dato que se envía: ninguna otra información sale de tu dispositivo.';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detectado a partir del VIN: $summary. ¿Aplicar?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Aplicar';

  @override
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  ) {
    return '$name, a $distanceKm kilómetros, $fuelType $euros euros con $cents';
  }

  @override
  String get widgetHelpSectionTitle => 'Widget de pantalla de inicio';

  @override
  String get widgetHelpIntro =>
      'Añade el widget de SparKilo a tu pantalla de inicio para ver los precios del combustible y la carga de un vistazo.';

  @override
  String get widgetHelpAdd =>
      'Añádelo desde el selector de widgets de tu launcher: mantén pulsada una zona vacía de la pantalla de inicio, elige Widgets y busca SparKilo.';

  @override
  String get widgetHelpTap =>
      'Toca una estación en el widget para abrirla en la app. Toca el icono de actualizar para actualizar los precios.';

  @override
  String get widgetHelpConfigure =>
      'En Android, mantén pulsado el widget y elige Reconfigurar para cambiar el perfil, el color y el contenido.';

  @override
  String get widgetDefaultsThisProfileHint =>
      'Las opciones siguientes se aplican a todos los widgets instalados que muestren este perfil, en la próxima actualización.';

  @override
  String get widgetDefaultsColorLabel => 'Esquema de color';

  @override
  String get widgetDefaultsVariantLabel => 'Variante de contenido';

  @override
  String get widgetColorSchemeSystem => 'Seguir sistema';

  @override
  String get widgetColorSchemeLight => 'Claro';

  @override
  String get widgetColorSchemeDark => 'Oscuro';

  @override
  String get widgetColorSchemeBlue => 'Azul';

  @override
  String get widgetColorSchemeGreen => 'Verde';

  @override
  String get widgetColorSchemeOrange => 'Naranja';

  @override
  String get widgetVariantDefault => 'Solo el precio actual';

  @override
  String get widgetVariantPredictive =>
      'Predictivo: mejor momento para repostar';
}
