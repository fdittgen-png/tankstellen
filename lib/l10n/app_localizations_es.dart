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
  String get searchButton => 'Buscar';

  @override
  String get fabOpenCriteria => 'Abrir búsqueda';

  @override
  String get fabOpenResults => 'Abrir resultados';

  @override
  String get fabRunSearch => 'Ejecutar búsqueda';

  @override
  String get fabRefineCriteria => 'Refinar búsqueda';

  @override
  String get routeSearchPartialBanner => 'Buscando más estaciones…';

  @override
  String get routeSearchingChip => 'Searching the route…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Every $km km';
  }

  @override
  String get searchCriteriaTitle => 'Criterios de búsqueda';

  @override
  String get searchCriteriaOpen => 'Buscar';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'En un radio de $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Toca para empezar a buscar';

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
  String get configApiKeyNotSet => 'Sin configurar (modo demo)';

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
  String get routeModeBannerLabel =>
      'Modo ruta — las distancias son a lo largo del corredor';

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
    return 'Switched to $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Profile $name created';
  }

  @override
  String profileCountryTaken(String country) {
    return 'A profile for $country already exists — edit it instead.';
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
  String get evPriceFree => 'Free';

  @override
  String get evPricePayAtLocation => 'Pay at location';

  @override
  String get evPriceMembership => 'Membership required';

  @override
  String get evPriceIndicative => 'Indicative price';

  @override
  String get evPriceDeclaredByOperator =>
      'Indicative price declared by the operator — verify on site';

  @override
  String get evPriceFranceAttribution =>
      'Pricing: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Best-effort pricing from OpenChargeMap — sparse and may be incomplete.';

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
  String calculatorDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consumption ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Fuel price ($unit)';
  }

  @override
  String get calculatorUseMine => 'Use';

  @override
  String get calculatorApplied => 'Applied';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get calculatorRoundTrip => 'Round trip';

  @override
  String get roundTripTotal => 'Round trip';

  @override
  String get costPerDistance => 'Cost per km';

  @override
  String get costPerMonth => 'Cost per month';

  @override
  String get calculatorEstimateMonthly => 'Estimate monthly cost';

  @override
  String get calculatorTripsPerMonth => 'Trips per month';

  @override
  String get calculatorTripsPerMonthHint => 'e.g. 20';

  @override
  String get calculatorReset => 'Reset';

  @override
  String get calculatorResultPlaceholder =>
      'Fill in distance, consumption and price to see your trip cost';

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
  String get dataDeletionNotAvailableCommunity =>
      'La eliminación de datos no está disponible en el modo Comunidad. Desconéctese primero o utilice una base de datos privada.';

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
  String crossBorderNearby(String country) {
    return '$country está cerca';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km hasta la frontera';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Media aquí: $price EUR ($count estaciones)';
  }

  @override
  String get allPricesView => 'Todos los precios';

  @override
  String get compactView => 'Compacta';

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
  String get gdprAcceptAll => 'Aceptar todo';

  @override
  String get gdprAcceptSelected => 'Aceptar selección';

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
  String get topicUrlCopied => 'URL del tema copiada';

  @override
  String get testNotificationSent => '¡Notificación de prueba enviada!';

  @override
  String get testNotificationFailed =>
      'Error al enviar la notificación de prueba';

  @override
  String get pushUpdateFailed =>
      'Error al actualizar el ajuste de notificaciones push';

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
  String privacyCopyErrorLog(int count) {
    return 'Copiar registro de errores al portapapeles ($count)';
  }

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
  String voiceAnnouncementThreshold(String price) {
    return 'Solo por debajo de $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, a $distance kilómetros, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Radio de anuncio';

  @override
  String get voiceAnnouncementCooldown => 'Intervalo de repetición';

  @override
  String get nearestStations => 'Estaciones cercanas';

  @override
  String get nearestStationsHint =>
      'Encontrar las estaciones mas cercanas con su ubicacion actual';

  @override
  String get consumptionLogTitle => 'Consumo de combustible';

  @override
  String get consumptionLogMenuTitle => 'Registro de consumo';

  @override
  String get consumptionLogMenuSubtitle =>
      'Registra los repostajes y calcula L/100 km';

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
  String get stationPreFilled => 'Estación rellenada automáticamente';

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
  String get fillUpVehicleNone => 'Sin vehículo';

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
  String get scanPump => 'Escanear surtidor';

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
  String get obdNoAdapter => 'No hay ningún adaptador OBD2 al alcance';

  @override
  String get obdOdometerUnavailable => 'No se pudo leer el cuentakilómetros';

  @override
  String get obdPermissionDenied =>
      'Concede el permiso de Bluetooth en los ajustes del sistema';

  @override
  String get obdAdapterUnresponsive =>
      'El adaptador no respondió: enciende el contacto y reinténtalo';

  @override
  String get obdPickerTitle => 'Elige un adaptador OBD2';

  @override
  String get obdPickerScanning => 'Buscando adaptadores…';

  @override
  String get obdPickerConnecting => 'Conectando…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get themeModeSystem => 'Según el sistema';

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
  String get navConsumption => 'Consumo';

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
  String get vehicleBaselineShowDetails => 'Show per-situation breakdown';

  @override
  String get vehicleBaselineHideDetails => 'Hide per-situation breakdown';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Not detected yet: $situations. These driving situations still read 0 samples, so the baseline is incomplete.';
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
  String get obd2StatusAttempting => 'Adaptador OBD2: conectando';

  @override
  String get obd2StatusUnreachable => 'Adaptador OBD2: no accesible';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptador OBD2: se necesita el permiso de Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Listo para grabar un viaje.';

  @override
  String get obd2StatusAttemptingBody => 'Conectando en segundo plano…';

  @override
  String get obd2StatusUnreachableBody =>
      'El adaptador está fuera de alcance o ya lo está usando otra app.';

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
  String get tripHistoryEmptySubtitle =>
      'Conecta un adaptador OBD2 y graba un viaje para empezar a crear tu historial de conducción.';

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
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

  @override
  String get situationHardAccel => 'Aceleración fuerte';

  @override
  String get situationFuelCut => 'Corte de combustible: deceleración';

  @override
  String get tripSaveAsFillUp => 'Guardar como repostaje';

  @override
  String get tripSaveRecording => 'Guardar viaje';

  @override
  String get tripDiscard => 'Descartar';

  @override
  String obdOdometerRead(int km) {
    return 'Lectura del cuentakilómetros: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Sin definir';

  @override
  String get wizardVehicleTapToEdit => 'Toca para editar';

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
  String get wizardProfileCustomDescription =>
      'Tu propia combinación de funciones. Ajusta cada interruptor abajo.';

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
  String get evMaxPower => 'Potencia máx.';

  @override
  String get evOperator => 'Operador';

  @override
  String get evLastUpdate => 'Última actualización';

  @override
  String get evStatusAvailable => 'Disponible';

  @override
  String get evStatusOccupied => 'Ocupado';

  @override
  String get evStatusOutOfOrder => 'Fuera de servicio';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Solo abiertas';

  @override
  String get saveAsDefaults => 'Guardar como mis valores predeterminados';

  @override
  String get criteriaSavedToProfile => 'Guardado como valores predeterminados';

  @override
  String get profileNotFound => 'No hay ningún perfil activo';

  @override
  String get updatingFavorites => 'Actualizando tus favoritos...';

  @override
  String get fetchingLatestPrices => 'Obteniendo los últimos precios';

  @override
  String get noDataAvailable => 'Sin datos';

  @override
  String get configAndPrivacy => 'Configuración y privacidad';

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
  String get sectionSetupDataSources => 'Setup & data sources';

  @override
  String get sectionFeaturesUsage => 'Features & usage';

  @override
  String get sectionAccountSync => 'Account & sync';

  @override
  String get sectionAppearanceWidgets => 'Appearance & widgets';

  @override
  String get sectionPrivacyData => 'Privacy & data';

  @override
  String get sectionAdvancedDeveloper => 'Advanced & developer';

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
  String get coachingShiftUp => 'Subir marcha';

  @override
  String get coachingShiftDown => 'Bajar marcha';

  @override
  String get coachingEasePedal => 'Suelta acelerador';

  @override
  String get coachingVoiceHardAcceleration => 'Easy on the accelerator';

  @override
  String get coachingVoiceHarshBraking => 'Try to brake more gently';

  @override
  String get coachingVoiceShiftUp => 'Shift up a gear to save fuel';

  @override
  String get coachingVoiceShiftDown => 'Shift down, the engine is labouring';

  @override
  String get coachingVoiceEasePedal =>
      'Ease off the pedal to cut your fuel use';

  @override
  String get coachingVoiceLiftOff => 'Lift off the accelerator and coast';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Look further ahead and lift off earlier';

  @override
  String get coachingVoiceSmoothAccel => 'Accelerate more smoothly';

  @override
  String get voiceCoachingSettingTitle => 'Spoken driving coaching';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Hear spoken tips while you drive — hard acceleration, harsh braking and gear hints';

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
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Combustible';

  @override
  String get stationTypeEv => 'VE';

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
  String get alertsBackgroundCheckErrorTitle =>
      'Error en la comprobación de alertas en segundo plano';

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
      'Comparte favoritos y valoraciones con todos los usuarios';

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
  String get evChargingSection => 'Carga de VE';

  @override
  String get fuelStationsSection => 'Estaciones de servicio';

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
  String get luxembourgRegulatedPricesNotice =>
      'Los precios del combustible en Luxemburgo están regulados por el gobierno y son uniformes en todo el país.';

  @override
  String get luxembourgFuelUnleaded95 => 'Sin plomo 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Sin plomo 98';

  @override
  String get luxembourgFuelDiesel => 'Diésel';

  @override
  String get luxembourgFuelLpg => 'GLP';

  @override
  String get luxembourgPricesUnavailable =>
      'Los precios regulados de Luxemburgo no están disponibles.';

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
  String get southKoreaApiKeyRequired =>
      'Regístrate en OPINET para obtener una clave de API gratuita';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Regístrate en CNE para obtener una clave de API gratuita';

  @override
  String get chileApiProvider => 'CNE Bencina en Línea';

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
      'Recording with GPS — OBD2 reconnecting';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Calibración de consumo actualizada para $vehicleName: precisión mejorada en un $percent %';
  }

  @override
  String get veResetConfirmTitle => '¿Restablecer la eficiencia volumétrica?';

  @override
  String get veResetConfirmBody =>
      'Esto descartará la eficiencia volumétrica aprendida (η_v) y restaurará el valor predeterminado (0,85). Las estimaciones de flujo de combustible por viaje volverán a la constante del fabricante hasta que el calibrador recopile nuevas muestras de los próximos viajes.';

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
  String get alertsRadiusThreshold => 'Umbral (€/L)';

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
  String get alertsRadiusDeleteConfirm => '¿Eliminar la alerta por radio?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 conectado: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Emparejar un adaptador OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel ha bajado en estaciones cercanas';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount estaciones han bajado hasta $maxDropCents ¢ en la última hora';
  }

  @override
  String get fillUpSavedSnackbar => 'Repostaje guardado';

  @override
  String get radiusAlertsEntryTitle => 'Alertas por radio y estadísticas';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Recibe un aviso cuando los precios bajen cerca de ti';

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
  String get obd2ErrorProtocolInitFailed =>
      'El adaptador OBD2 envió una respuesta no reconocida. Puede ser incompatible: prueba con otro adaptador.';

  @override
  String get obd2ErrorDisconnected =>
      'El adaptador OBD2 se desconectó. Vuelve a conectarlo e inténtalo de nuevo.';

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
  String get alertGatingNonDeStationWarning =>
      'Las alertas de precio en segundo plano actualmente solo funcionan para estaciones en Alemania. Esta alerta se guardará, pero puede que nunca te notifique hasta que lleguen las alertas entre países.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Las alertas por radio actualmente solo comprueban estaciones en Alemania.';

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
  String approachStationDistance(String meters) {
    return 'a $meters m';
  }

  @override
  String fuelStationRadarDistanceKm(String km) {
    return '$km km away';
  }

  @override
  String fuelStationRadarProximity(int percent) {
    return 'Proximity $percent%';
  }

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
  String get autoRecordPairedAdapterLabel => 'Adaptador emparejado';

  @override
  String get autoRecordPairedAdapterNone =>
      'No hay ningún adaptador emparejado. Empareja uno primero mediante la configuración inicial de OBD2.';

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
  String get autoRecordBadgeClearTooltip => 'Borrar contador';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Empareja un adaptador en la sección de abajo para activar la grabación automática';

  @override
  String get exportBackupTooltip => 'Exportar copia de seguridad';

  @override
  String get exportBackupReady => 'Copia de seguridad lista: elige un destino';

  @override
  String get exportBackupFailed =>
      'Error al exportar la copia de seguridad: inténtalo de nuevo';

  @override
  String get backupExportProgress => 'Exporting your backup…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Saved to Downloads as $fileName';
  }

  @override
  String get restoreBackupTooltip => 'Restore backup';

  @override
  String get restoreBackupDialogTitle => 'Restore backup';

  @override
  String get restoreBackupDialogBody =>
      'Merge adds and updates records from the backup and keeps everything already on this device. Replace deletes all current data first, then restores only the backup — this cannot be undone.';

  @override
  String get restoreBackupMergeAction => 'Merge';

  @override
  String get restoreBackupReplaceAction => 'Replace all';

  @override
  String restoreBackupSuccess(int count) {
    return 'Backup restored — $count records imported';
  }

  @override
  String get restoreBackupEmpty => 'Backup restored — it contained no records';

  @override
  String get restoreBackupCorrupt =>
      'Restore failed — this file is not a valid Tankstellen backup';

  @override
  String get restoreBackupFailed =>
      'Restore failed — the file could not be read';

  @override
  String get backupImportProgress => 'Restoring your backup…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Merged $vehicles vehicles, $fillUps fill-ups, $trips trips, $chargingLogs charging logs';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Replaced all data with $vehicles vehicles, $fillUps fill-ups, $trips trips, $chargingLogs charging logs';
  }

  @override
  String get brokenMapChipVerifying => 'Verificando sensor MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Lecturas del MAP sospechosas';

  @override
  String get brokenMapSnackbarUnreliable =>
      'El sensor MAP da lecturas incorrectas: las lecturas de combustible pueden ser entre un 50 y un 80 % demasiado bajas. Prueba con otro adaptador.';

  @override
  String get brokenMapBannerHardDisable =>
      'Sensor MAP poco fiable. Se muestran las medias de repostaje en lugar del caudal de combustible en directo.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Sensor MAP: verificado ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Sensor MAP: verificando ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Sensor MAP: sospechoso ($confidence)';
  }

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
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (calibrado, $samples muestras)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (aprendiendo, $samples muestras)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (predeterminado: aún sin lleno completo)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples muestras';
  }

  @override
  String get calibrationResetLearner => 'Restablecer el aprendizaje';

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
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Tu $makeModel está marcado como diésel pero coincide con una entrada de gasolina del catálogo. Toca para actualizar.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Actualizar';

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
  String get chargingChartsMonthAxis => 'Mes';

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
  String get consoGroupVehicles => 'Vehicles';

  @override
  String get consoGroupCoaching => 'Coaching while driving';

  @override
  String get consoGroupRewards => 'Rewards & savings';

  @override
  String get consoGroupTroubleshooting => 'Troubleshooting';

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
  String get moreActionsTooltip => 'More';

  @override
  String get exportBackupMenuLabel => 'Export backup';

  @override
  String get restoreBackupMenuLabel => 'Restore backup';

  @override
  String get carbonDashboardMenuLabel => 'Carbon dashboard';

  @override
  String get settingsMenuLabel => 'Settings';

  @override
  String get consumptionStatsPageTitle => 'Consumption statistics';

  @override
  String get consumptionStatsComparisonTitle => 'This month vs last month';

  @override
  String get consumptionStatsTrendsTitle => 'Evolution over time';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Log fill-ups across at least two months to compare.';

  @override
  String get consumptionStatsPricePerLiter => 'Avg price/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litres per month';

  @override
  String get consumptionStatsChartSpend => 'Spend per month';

  @override
  String get consumptionStatsChartPricePerLiter => 'Price per litre';

  @override
  String get consumptionStatsChartConsumption => 'L/100km per month';

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
    return 'Corrections: +$liters L';
  }

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
  String get greeceApiProvider => 'Paratiritirio Timon (Grecia)';

  @override
  String get greeceCommunityApiNotice =>
      'Con la tecnología de la API fuelpricesgr mantenida por la comunidad';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Rumanía)';

  @override
  String get romaniaScrapingNotice =>
      'Con la tecnología de pretcarburant.ro (Consejo de Competencia + ANPC)';

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
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Herramientas de desarrollo';

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
      'Search for stations first, then run the test alert so the notification can open a real station.';

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
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Climbing at $gradePercent% grade ($pctTime% of trip): wasted $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Carry momentum into a hill and feed the throttle smoothly — surging on a climb burns extra fuel.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count stop-and-go restarts: wasted $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Anticipate traffic and coast toward stops so you roll rather than restart — pulling away from a dead stop is the thirstiest part of stop-and-go.';

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
  String get gpsKpiCardTitle => 'GPS efficiency';

  @override
  String get gpsKpiRpa => 'Positive acceleration (RPA)';

  @override
  String get gpsKpiPke => 'Kinetic energy demand (PKE)';

  @override
  String get gpsKpiVapos => 'Acceleration intensity (VAPOS)';

  @override
  String get gpsKpiCoast => 'Coasting share';

  @override
  String get gpsKpiClimbEnergy => 'Climb energy';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs your efficient baseline';
  }

  @override
  String get drivingTraceCardTitle => 'Driving-analysis trace (dev)';

  @override
  String get drivingTraceCardBody =>
      'Export this trip\'s GPS KPIs, score and lessons as JSON, write how the drive actually felt in the comment field, and share it back so the driving-style thresholds can be calibrated against real trips.';

  @override
  String get drivingTraceExportAction => 'Export analysis trace';

  @override
  String get drivingTraceExported =>
      'Analysis trace saved to Downloads — add your verdict in the comment field and share it back.';

  @override
  String get drivingTraceExportFailed => 'Couldn\'t export the analysis trace.';

  @override
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L ahorrados';
  }

  @override
  String get ecoRouteHint =>
      'Conducción más inteligente: prioriza la autopista estable frente a los atajos en zigzag.';

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
  String get featureLabel_unifiedSearchResults =>
      'Resultados de búsqueda unificados';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Una sola lista de resultados que combina estaciones de combustible y de VE.';

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
  String get featureBlockedEnable_showFuel =>
      'No se cumplen los requisitos previos';

  @override
  String get featureBlockedEnable_showElectric =>
      'No se cumplen los requisitos previos';

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
  String get featureLabel_addFillUpOcrPump =>
      'OCR de pantalla de surtidor (experimental)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Escanea la pantalla de un surtidor para rellenar el formulario. El reconocimiento no es fiable hoy — actívalo solo si quieres probarlo.';

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
  String get featureLabel_approachOverlay => 'Approach overlay';

  @override
  String get featureDescription_approachOverlay =>
      'During a recorded trip, flip the floating tile to the fuel type\'s colour and show the price as you near a fuel station.';

  @override
  String get featureLabel_voiceAnnouncements => 'Voice announcements';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Speak nearby cheap fuel stations aloud as you drive, so you can keep your eyes on the road.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Enable the approach overlay first';

  @override
  String get featureGroupTitle_finding => 'Finding & map';

  @override
  String get featureGroupDescription_finding =>
      'Where to fuel up or charge — search, map, routing.';

  @override
  String get featureGroupTitle_prices => 'Prices & alerts';

  @override
  String get featureGroupDescription_prices =>
      'Price drops, history, and reporting.';

  @override
  String get featureGroupTitle_radar => 'Fuel Station Radar';

  @override
  String get featureGroupDescription_radar => 'Live price nudges as you drive.';

  @override
  String get featureGroupTitle_sync => 'Sync & backup';

  @override
  String get featureGroupDescription_sync => 'Keep your data across devices.';

  @override
  String get featureGroupTitle_input => 'Input & scanning';

  @override
  String get featureGroupDescription_input => 'Helpers for logging fill-ups.';

  @override
  String get featureGroupTitle_developer => 'Developer & experimental';

  @override
  String get featureGroupDescription_developer =>
      'Power-user and contributor tools.';

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
  String get scanPumpUnreadable =>
      'No se puede leer la pantalla del surtidor: inténtalo de nuevo';

  @override
  String get scanPumpSuccess =>
      'Pantalla del surtidor escaneada: verifica los valores.';

  @override
  String get scanPumpGlare =>
      'Demasiado reflejo en la pantalla — inténtalo de nuevo desde un ángulo ligeramente distinto para que los números no se vean lavados.';

  @override
  String scanPumpFailed(String error) {
    return 'Error al escanear el surtidor: $error';
  }

  @override
  String get badScanReportTitle => 'Informar de un error de escaneo';

  @override
  String get badScanReportTitleReceipt =>
      'Informar de un error de escaneo: recibo';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Informar de un error de escaneo: pantalla del surtidor';

  @override
  String get pumpScanFailureTitle => 'Pantalla ilegible';

  @override
  String get pumpScanFailureBody =>
      'El escaneo no pudo leer la pantalla del surtidor. ¿Qué quieres hacer?';

  @override
  String get pumpScanFailureCorrectManually => 'Corregir manualmente';

  @override
  String get pumpScanFailureReport => 'Informar';

  @override
  String get pumpScanFailureRemove => 'Quitar foto';

  @override
  String get badScanReportHint =>
      'Compartiremos la foto del recibo y ambos conjuntos de valores para que la próxima versión pueda aprender este formato.';

  @override
  String get badScanReportShareAction => 'Compartir informe + foto';

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
  String get pumpCameraHint =>
      'Alinea los tres números del surtidor dentro del marco';

  @override
  String get pumpCameraCapture => 'Capturar';

  @override
  String get pumpCameraPermissionDenied =>
      'Se necesita acceso a la cámara para escanear el surtidor. Actívalo en los ajustes del dispositivo.';

  @override
  String get pumpCameraError =>
      'La cámara no pudo iniciarse. Inténtalo de nuevo o introduce los valores a mano.';

  @override
  String get pumpCameraOrientationHorizontal =>
      'Cambiar a disposición horizontal';

  @override
  String get pumpCameraOrientationVertical => 'Cambiar a disposición vertical';

  @override
  String get pumpCameraGlareWarning =>
      'Demasiado brillo — inclina ligeramente para evitar reflejos';

  @override
  String get pumpCameraAlignHint => 'Alinea el surtidor en el marco y captura';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'Qué repostaste';

  @override
  String get fillUpSectionWhatSubtitle => 'Combustible, cantidad, precio';

  @override
  String get fillUpSectionWhereTitle => 'Dónde estabas';

  @override
  String get fillUpSectionWhereSubtitle => 'Estación, cuentakilómetros, notas';

  @override
  String get fillUpImportFromLabel => 'Importar desde…';

  @override
  String get fillUpImportSheetTitle => 'Importar datos de repostaje';

  @override
  String get fillUpImportReceiptLabel => 'Recibo';

  @override
  String get fillUpImportReceiptDescription =>
      'Escanea un recibo de papel con la cámara';

  @override
  String get fillUpImportPumpLabel => 'Pantalla del surtidor';

  @override
  String get fillUpImportPumpDescription =>
      'Lee el importe y el precio de la pantalla LCD del surtidor';

  @override
  String get fillUpImportObdLabel => 'Adaptador OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Lee el cuentakilómetros del puerto OBD-II por Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Precio por litro';

  @override
  String get vehicleHeaderPlateLabel => 'Matrícula';

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
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

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
  String get coachingGpsLiftOff => 'Soltar gas';

  @override
  String get coachingGpsAnticipateBrake => 'Anticipar';

  @override
  String get coachingGpsSmoothAccel => 'Aceleración suave';

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
    return 'Largest gap: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Resumed';

  @override
  String get gpsLifecyclePaused => 'Paused';

  @override
  String get gpsLifecycleInactive => 'Inactive';

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
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Conducción';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco-coaching en tiempo real';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Vibración háptica suave y consejo en pantalla cuando pisas a fondo durante la conducción de crucero';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Suave con el acelerador: dejarse llevar ahorra más';

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
  String get routeStrategyLabel => 'Estrategia:';

  @override
  String get routeStrategyUniform => 'Uniforme';

  @override
  String get routeStrategyBalanced => 'Equilibrada';

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
  String get consentSyncTripsNeedsEmailHint =>
      'Inicia sesión con una cuenta de correo para sincronizar los viajes entre dispositivos.';

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
  String get accelBrakeCardTitle => 'Acceleration & braking';

  @override
  String get accelBrakeHardAccel => 'Hard accelerations';

  @override
  String get accelBrakeHardBrake => 'Hard braking';

  @override
  String get accelBrakeSharpCorner => 'Sharp corners';

  @override
  String get accelBrakeSource => 'From the phone\'s motion sensors';

  @override
  String lessonHardBrake(String count) {
    return '$count hard braking events';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Anticipate stops and ease off the accelerator earlier — hard braking throws away the fuel you just spent getting up to speed.';

  @override
  String lessonSharpCornering(String count) {
    return '$count sharp corners';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Slow before the bend, not in it — hard cornering scrubs off speed you then have to rebuild.';

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
  String get locationConsentDecline => 'Rechazar';

  @override
  String get locationConsentAccept => 'Aceptar';

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
  String get consumptionMonthlyClimbLabel => 'Climbed';

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
  String get obd2DiagnosticsInitSection => 'Dongle init transcript';

  @override
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  ) {
    return 'Protocol $protocol · $start · firmware $firmware · $tier · $pids PIDs';
  }

  @override
  String obd2DiagnosticsInitLine(String cmd, String response, int latency) {
    return '$cmd → $response ($latency ms)';
  }

  @override
  String get obd2DiagnosticsInitWarm => 'warm';

  @override
  String get obd2DiagnosticsInitCold => 'cold';

  @override
  String get obd2HealthCopyInitTranscript => 'Copy init transcript only';

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
  String get obd2TestRunTitle => 'Run adapter test';

  @override
  String get obd2TestRunButton => 'Run adapter test';

  @override
  String get obd2TestRunPassed => 'Adapter test passed';

  @override
  String get obd2TestRunFailed => 'Adapter test failed';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed of $total steps OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Stop the active recording before running the adapter test.';

  @override
  String get obd2TestStepScan => 'Scan for adapter';

  @override
  String get obd2TestStepConnect => 'Connect & init';

  @override
  String get obd2TestStepInfo => 'Adapter info';

  @override
  String get obd2TestStepSupportedPids => 'Supported PIDs';

  @override
  String get obd2TestStepSampleReads => 'Sample reads';

  @override
  String get obd2TestStepReconnect => 'Reconnect test';

  @override
  String get obd2TestStepDisconnect => 'Disconnect';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Timed out';

  @override
  String get obd2TestStatusGarbage => 'Unreadable reply';

  @override
  String get obd2TestStatusNoResponse => 'No response';

  @override
  String get obd2TestStatusFail => 'Failed';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'No se pudo contactar con «$adapterName»: elige otro adaptador';
  }

  @override
  String get ocrTesterTitle => 'OCR tester';

  @override
  String get ocrTesterNavLabel => 'OCR tester';

  @override
  String get ocrTesterExplain =>
      'Run the pump / receipt OCR pipeline on a chosen photo and inspect every step — only available in Developer mode.';

  @override
  String get ocrTesterModePump => 'Pump';

  @override
  String get ocrTesterModeReceipt => 'Receipt';

  @override
  String get ocrTesterCapture => 'Capture';

  @override
  String get ocrTesterPickImage => 'Pick image';

  @override
  String get ocrTesterRun => 'Run';

  @override
  String get ocrTesterCountry => 'Country';

  @override
  String get ocrTesterCountryNone => 'Default (no profile)';

  @override
  String get ocrTesterNoImage => 'Pick or capture an image, then Run.';

  @override
  String get ocrTesterRunning => 'Running OCR…';

  @override
  String get ocrTesterNoResult => 'OCR produced no readable result.';

  @override
  String get ocrTesterOverlaySection => 'Block overlay';

  @override
  String get ocrTesterStepsSection => 'Pipeline steps';

  @override
  String get ocrTesterLegendLabel => 'Label';

  @override
  String get ocrTesterLegendNumeric => 'Numeric';

  @override
  String get ocrTesterLegendNoise => 'Noise';

  @override
  String get ocrTesterLegendDerived => 'Derived';

  @override
  String get ocrTesterStageGlare => 'Capture / glare';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Classify';

  @override
  String get ocrTesterStageAssemble => 'Assemble';

  @override
  String get ocrTesterStageAnchor => 'Anchor';

  @override
  String get ocrTesterStageFallback => 'Fallback';

  @override
  String get ocrTesterStageCrossCheck => 'Cross-check';

  @override
  String get ocrTesterStageConfidence => 'Confidence';

  @override
  String get ocrTesterStageGate => 'Gate';

  @override
  String get ocrTesterStageBrand => 'Brand';

  @override
  String get ocrTesterStageOverrides => 'Overrides';

  @override
  String get ocrTesterStageReconcile => 'Reconcile';

  @override
  String get ocrTesterStageResult => 'Result';

  @override
  String get ocrTesterChipRead => 'READ';

  @override
  String get ocrTesterChipDerived => 'DERIVED';

  @override
  String get ocrTesterGateAccepted => 'Accepted';

  @override
  String get ocrTesterGateRejected => 'Rejected';

  @override
  String get ocrTesterFallbackBanner =>
      'A field was recovered via magnitude fallback — verify it.';

  @override
  String get ocrTesterStageNoData => 'Stage did not run.';

  @override
  String get ocrTesterCopyJson => 'Copy as JSON';

  @override
  String get ocrTesterExportPackage => 'Export package';

  @override
  String get ocrTesterCopied => 'OCR trace copied to clipboard.';

  @override
  String get ocrTesterExported => 'OCR package saved to your Downloads folder.';

  @override
  String get ocrTesterSaveFixture => 'Save as fixture';

  @override
  String get ocrTesterFixtureSaved =>
      'Fixture saved to your Downloads folder. Move it under test/fixtures and run tool/promote_ocr_fixture.dart.';

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
  String get onboardingObd2VinReadFailed =>
      'No se pudo leer el VIN: introdúcelo manualmente';

  @override
  String get onboardingObd2ConnectFailed =>
      'No se pudo conectar con el adaptador. Puedes reintentarlo u omitir este paso.';

  @override
  String get onboardingPickUseMode => 'Elige un modo de uso para continuar.';

  @override
  String get openNow => 'Open';

  @override
  String get openNowClosed => 'Closed';

  @override
  String get openHoursUnknown => 'Hours unknown';

  @override
  String closesAt(String time) {
    return 'Closes $time';
  }

  @override
  String opensAt(String day, String time) {
    return 'Opens $day $time';
  }

  @override
  String opensToday(String time) {
    return 'Opens $time';
  }

  @override
  String get open24Hours => 'Open 24 hours';

  @override
  String get badge24h => '24h';

  @override
  String get openingHoursAutomate24h => '24/7 automate';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Public holidays';

  @override
  String get closedLabel => 'Closed';

  @override
  String get openingHoursNotAvailable => 'Opening hours not available';

  @override
  String get showAllHours => 'Show all hours';

  @override
  String get showLessHours => 'Show less';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'transcurrido';

  @override
  String get radarPinHelpTitle => 'About pin';

  @override
  String get radarPinHelpBody =>
      'Pin keeps the screen on and hides system bars so the closest-station readout stays readable on a dashboard mount. Tap again to release. Auto-releases when the radar stops.';

  @override
  String get radarAutoPinTitle => 'Always pin when the radar starts';

  @override
  String get radarAutoPinSubtitle =>
      'Pin the radar automatically every time instead of tapping each time. Uses more battery.';

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
  String get radiusAlertCenterFromMap => 'Ubicación del mapa';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel cerca de $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Hay una estación a $price € (objetivo: $threshold €)';
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
  String get refuelUnitPerSession => '/sesión';

  @override
  String get shareReceiptImporting => 'Importing shared receipt…';

  @override
  String get shareReceiptUnsupportedFormat =>
      'That file type can\'t be imported yet — share a photo of the receipt instead.';

  @override
  String get shareReceiptFailed =>
      'Couldn\'t read the shared receipt — try sharing it again or add the fill-up manually.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Share receipt to import';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Share a receipt photo from another app to pre-fill a fill-up — date, litres, total, and station are read on-device.';

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
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Último repostaje: $date · $count viaje(s) desde entonces';
  }

  @override
  String get tankLevelMethodObd2 => 'medido por OBD2';

  @override
  String get tankLevelMethodDistanceFallback =>
      'estimación basada en la distancia';

  @override
  String get tankLevelMethodMixed => 'medición mixta';

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
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

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
  String get trajetDetailChartThrottle => 'Throttle / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Coolant (°C)';

  @override
  String get trajetDetailChartAltitude => 'Altitude (m)';

  @override
  String get trajetDetailChartLambda => 'Commanded λ';

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
  String get trajetDetailChartEstimatedBadge => 'estimated';

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
  String get trajetDetailDownloadCsvOption => 'Download telemetry (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetry (JSON)';

  @override
  String get trajetDetailDownloadError => 'Couldn\'t save the file';

  @override
  String get trajetDetailDeleteAction => 'Eliminar';

  @override
  String get trajetDetailDeleteConfirmTitle => '¿Eliminar este viaje?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Este viaje se eliminará de forma permanente de tu historial.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Cancelar';

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
  String get tripPathLegendTitle => 'Consumo';

  @override
  String get tripPathLegendEfficient => 'Eficiente (< 6 L/100 km)';

  @override
  String get tripPathLegendBorderline => 'Justo (6-10 L/100 km)';

  @override
  String get tripPathLegendWasteful => 'Derrochador (≥ 10 L/100 km)';

  @override
  String get tripRadarClosestStation => 'Closest station';

  @override
  String get tripRadarScanning => 'Scanning for nearby stations';

  @override
  String get tripRadarNoStationNearby => 'No station nearby';

  @override
  String get fuelStationRadarNearer => 'Nearer station';

  @override
  String get fuelStationRadarFarther => 'Farther station';

  @override
  String get fuelStationRadarStart => 'Start fuel station radar';

  @override
  String get stopRadar => 'Stop radar';

  @override
  String get fuelStationRadarResultBadge => 'Fuel Station Radar result';

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
  String get tripBannerOpenFromConsumptionTab =>
      'Abre el viaje activo desde la pestaña Consumo';

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
  String get tripRecordingSavingTitle => 'Saving trip…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripRecordingGpsNotificationTitle => 'Recording your trip';

  @override
  String get tripRecordingGpsNotificationText =>
      'Tracking your route for fuel & driving stats';

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
  String get unifiedFilterFuel => 'Combustible';

  @override
  String get unifiedFilterEv => 'VE';

  @override
  String get unifiedFilterBoth => 'Ambos';

  @override
  String get unifiedNoResultsForFilter =>
      'Ningún resultado coincide con este filtro';

  @override
  String get searchFailedSnackbar => 'Error en la búsqueda: inténtalo de nuevo';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Updated $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Also: $names';
  }

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Raw: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get vinLabel => 'VIN (opcional)';

  @override
  String get vinDecodeTooltip => 'Decodificar VIN';

  @override
  String get vinConfirmAction => 'Sí, rellenar automáticamente';

  @override
  String get vinModifyAction => 'Modificar manualmente';

  @override
  String get veResetAction => 'Restablecer la eficiencia volumétrica';

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
  String get vehicleDetectedFromVinBadge => '(detectado)';

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
    return '$name, $distanceKm kilometers ahead, $fuelType $euros euros $cents';
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
  String get widgetDefaultsApplyToAllHint =>
      'Las opciones de abajo se aplican a cada widget instalado en la próxima actualización.';

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

  @override
  String get widgetPredictiveNowPrefix => 'ahora';
}
