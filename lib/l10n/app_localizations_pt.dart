// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Preços de Combustível';

  @override
  String get search => 'Pesquisar';

  @override
  String get favorites => 'Favoritos';

  @override
  String get map => 'Mapa';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Definições';

  @override
  String get gpsLocation => 'Localização GPS';

  @override
  String get zipCode => 'Código postal';

  @override
  String get zipCodeHint => 'ex. 1000-001';

  @override
  String get fuelType => 'Combustível';

  @override
  String get searchRadius => 'Raio';

  @override
  String get searchNearby => 'Postos próximos';

  @override
  String get searchButton => 'Pesquisar';

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
  String get noResults => 'Nenhum posto encontrado.';

  @override
  String get startSearch => 'Pesquise para encontrar postos de combustível.';

  @override
  String get open => 'Aberto';

  @override
  String get closed => 'Fechado';

  @override
  String distance(String distance) {
    return 'a $distance';
  }

  @override
  String get price => 'Preço';

  @override
  String get prices => 'Preços';

  @override
  String get address => 'Morada';

  @override
  String get openingHours => 'Horário';

  @override
  String get open24h => 'Aberto 24 horas';

  @override
  String get navigate => 'Navegar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get apiKeySetup => 'Chave API';

  @override
  String get apiKeyDescription =>
      'Registe-se uma vez para obter uma chave API gratuita.';

  @override
  String get apiKeyLabel => 'Chave API';

  @override
  String get register => 'Registo';

  @override
  String get continueButton => 'Continuar';

  @override
  String get welcome => 'Preços de Combustível';

  @override
  String get welcomeSubtitle =>
      'Encontre o combustível mais barato perto de si.';

  @override
  String get profileName => 'Nome do perfil';

  @override
  String get preferredFuel => 'Combustível preferido';

  @override
  String get defaultRadius => 'Raio predefinido';

  @override
  String get landingScreen => 'Ecrã inicial';

  @override
  String get homeZip => 'Código postal de casa';

  @override
  String get newProfile => 'Novo perfil';

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
  String get activate => 'Ativar';

  @override
  String get configured => 'Configurado';

  @override
  String get notConfigured => 'Não configurado';

  @override
  String get about => 'Sobre';

  @override
  String get openSource => 'Código aberto (Licença MIT)';

  @override
  String get sourceCode => 'Código fonte no GitHub';

  @override
  String get noFavorites => 'Sem favoritos';

  @override
  String get noFavoritesHint =>
      'Toque na estrela de um posto para o guardar como favorito.';

  @override
  String get language => 'Idioma';

  @override
  String get country => 'País';

  @override
  String get demoMode => 'Modo de demonstração — dados de exemplo.';

  @override
  String get setupLiveData => 'Configurar dados em tempo real';

  @override
  String get freeNoKey => 'Grátis — sem chave necessária';

  @override
  String get apiKeyRequired => 'Chave API necessária';

  @override
  String get skipWithoutKey => 'Continuar sem chave';

  @override
  String get dataTransparency => 'Transparência de dados';

  @override
  String get storageAndCache => 'Armazenamento e cache';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get clearAllData => 'Eliminar todos os dados';

  @override
  String get errorLog => 'Registo de erros';

  @override
  String stationsFound(int count) {
    return '$count postos encontrados';
  }

  @override
  String get whatIsShared => 'O que é partilhado — e com quem?';

  @override
  String get gpsCoordinates => 'Coordenadas GPS';

  @override
  String get gpsReason =>
      'Enviadas em cada pesquisa para encontrar postos próximos.';

  @override
  String get postalCodeData => 'Código postal';

  @override
  String get postalReason =>
      'Convertido em coordenadas através do serviço de geocodificação.';

  @override
  String get mapViewport => 'Área do mapa';

  @override
  String get mapReason =>
      'Os mosaicos do mapa são carregados do servidor. Nenhum dado pessoal é transmitido.';

  @override
  String get apiKeyData => 'Chave API';

  @override
  String get apiKeyReason =>
      'A sua chave pessoal é enviada com cada pedido API. Está ligada ao seu e-mail.';

  @override
  String get notShared => 'NÃO partilhado:';

  @override
  String get searchHistory => 'Histórico de pesquisa';

  @override
  String get favoritesData => 'Favoritos';

  @override
  String get profileNames => 'Nomes de perfil';

  @override
  String get homeZipData => 'Código postal de casa';

  @override
  String get usageData => 'Dados de utilização';

  @override
  String get privacyBanner =>
      'Esta app não tem servidor. Todos os dados ficam no seu dispositivo. Sem análises, sem rastreamento, sem publicidade.';

  @override
  String get storageUsage => 'Utilização de armazenamento neste dispositivo';

  @override
  String get settingsLabel => 'Definições';

  @override
  String get profilesStored => 'perfis guardados';

  @override
  String get stationsMarked => 'postos marcados';

  @override
  String get cachedResponses => 'respostas em cache';

  @override
  String get total => 'Total';

  @override
  String get cacheManagement => 'Gestão de cache';

  @override
  String get cacheDescription =>
      'A cache armazena respostas API para carregamento mais rápido e acesso offline.';

  @override
  String get stationSearch => 'Pesquisa de postos';

  @override
  String get stationDetails => 'Detalhes do posto';

  @override
  String get priceQuery => 'Consulta de preços';

  @override
  String get zipGeocoding => 'Geocodificação de código postal';

  @override
  String minutes(int n) {
    return '$n minutos';
  }

  @override
  String hours(int n) {
    return '$n horas';
  }

  @override
  String get clearCacheTitle => 'Limpar cache?';

  @override
  String get clearCacheBody =>
      'Os resultados de pesquisa e preços em cache serão eliminados. Perfis, favoritos e definições são preservados.';

  @override
  String get clearCacheButton => 'Limpar cache';

  @override
  String get deleteAllTitle => 'Eliminar todos os dados?';

  @override
  String get deleteAllBody =>
      'Isto elimina permanentemente todos os perfis, favoritos, chave API, definições e cache. A app será reiniciada.';

  @override
  String get deleteAllButton => 'Eliminar tudo';

  @override
  String get entries => 'entradas';

  @override
  String get cacheEmpty => 'A cache está vazia';

  @override
  String get noStorage => 'Sem armazenamento utilizado';

  @override
  String get apiKeyNote =>
      'Registo gratuito. Dados de agências governamentais de transparência de preços.';

  @override
  String get apiKeyFormatError =>
      'Formato inválido — UUID esperado (8-4-4-4-12)';

  @override
  String get supportProject => 'Apoiar este projeto';

  @override
  String get supportDescription =>
      'Esta app é gratuita, de código aberto e sem publicidade. Se a achar útil, considere apoiar o programador.';

  @override
  String get reportBug => 'Reportar erro / Sugerir funcionalidade';

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
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get fuels => 'Combustíveis';

  @override
  String get services => 'Serviços';

  @override
  String get zone => 'Zona';

  @override
  String get highway => 'Autoestrada';

  @override
  String get localStation => 'Posto local';

  @override
  String get lastUpdate => 'Última atualização';

  @override
  String get automate24h => '24h/24 — Automático';

  @override
  String get refreshPrices => 'Atualizar preços';

  @override
  String get station => 'Posto';

  @override
  String get locationDenied =>
      'Permissão de localização negada. Pode pesquisar por código postal.';

  @override
  String get demoModeBanner =>
      'Modo de demonstração. Configure a chave API nas definições.';

  @override
  String get sortDistance => 'Distância';

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
    return '$count postos';
  }

  @override
  String get loadingFavorites =>
      'A carregar favoritos...\nPesquise postos primeiro para guardar dados.';

  @override
  String get reportPrice => 'Reportar preço';

  @override
  String get whatsWrong => 'O que está errado?';

  @override
  String get correctPrice => 'Preço correto (ex. 1,459)';

  @override
  String get sendReport => 'Enviar relatório';

  @override
  String get reportSent => 'Relatório enviado. Obrigado!';

  @override
  String get enterValidPrice => 'Introduza um preço válido';

  @override
  String get cacheCleared => 'Cache limpa.';

  @override
  String get yourPosition => 'A sua posição';

  @override
  String get positionUnknown => 'Posição desconhecida';

  @override
  String get distancesFromCenter => 'Distâncias do centro de pesquisa';

  @override
  String get autoUpdatePosition => 'Atualizar posição automaticamente';

  @override
  String get autoUpdateDescription =>
      'Atualizar posição GPS antes de cada pesquisa';

  @override
  String get location => 'Localização';

  @override
  String get switchProfileTitle => 'País alterado';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Está agora em $country. Mudar para o perfil \"$profile\"?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Mudou para o perfil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Sem perfil para este país';

  @override
  String noProfileForCountry(String country) {
    return 'Está em $country, mas não há perfil configurado. Crie um nas Definições.';
  }

  @override
  String get autoSwitchProfile => 'Mudança automática de perfil';

  @override
  String get autoSwitchDescription =>
      'Mudar perfil automaticamente ao cruzar fronteiras';

  @override
  String get switchProfile => 'Mudar';

  @override
  String get dismiss => 'Fechar';

  @override
  String get profileCountry => 'País';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get settingsStorageDetail => 'Chave API, perfil ativo';

  @override
  String get allFuels => 'Todos';

  @override
  String get priceAlerts => 'Alertas de preço';

  @override
  String get noPriceAlerts => 'Sem alertas de preço';

  @override
  String get noPriceAlertsHint =>
      'Crie um alerta a partir da página de detalhes de um posto.';

  @override
  String alertDeleted(String name) {
    return 'Alerta \"$name\" eliminado';
  }

  @override
  String get createAlert => 'Criar alerta de preço';

  @override
  String currentPrice(String price) {
    return 'Preço atual: $price';
  }

  @override
  String get targetPrice => 'Preço alvo (EUR)';

  @override
  String get enterPrice => 'Introduza um preço';

  @override
  String get invalidPrice => 'Preço inválido';

  @override
  String get priceTooHigh => 'Preço demasiado alto';

  @override
  String get create => 'Criar';

  @override
  String get alertCreated => 'Alerta de preço criado';

  @override
  String get wrongE5Price => 'Preço Super E5 incorreto';

  @override
  String get wrongE10Price => 'Preço Super E10 incorreto';

  @override
  String get wrongDieselPrice => 'Preço Diesel incorreto';

  @override
  String get wrongStatusOpen => 'Mostrado como aberto, mas fechado';

  @override
  String get wrongStatusClosed => 'Mostrado como fechado, mas aberto';

  @override
  String get searchAlongRouteLabel => 'Ao longo da rota';

  @override
  String get searchEvStations => 'Pesquisar postos de carregamento';

  @override
  String get allStations => 'Todos os postos';

  @override
  String get bestStops => 'Melhores paragens';

  @override
  String get openInMaps => 'Abrir em Mapas';

  @override
  String get noStationsAlongRoute => 'Nenhum posto encontrado ao longo da rota';

  @override
  String get evOperational => 'Operacional';

  @override
  String get evStatusUnknown => 'Estado desconhecido';

  @override
  String evConnectors(int count) {
    return 'Conectores ($count pontos)';
  }

  @override
  String get evNoConnectors => 'Sem detalhes de conectores disponíveis';

  @override
  String get evUsageCost => 'Custo de utilização';

  @override
  String get evPricingUnavailable => 'Preço não disponível do fornecedor';

  @override
  String get evLastUpdated => 'Última atualização';

  @override
  String get evUnknown => 'Desconhecido';

  @override
  String get evDataAttribution => 'Dados do OpenChargeMap (fonte comunitária)';

  @override
  String get evStatusDisclaimer =>
      'O estado pode não refletir a disponibilidade em tempo real. Toque em atualizar para obter os dados mais recentes.';

  @override
  String get evNavigateToStation => 'Navegar para o posto';

  @override
  String get evRefreshStatus => 'Atualizar estado';

  @override
  String get evStatusUpdated => 'Estado atualizado';

  @override
  String get evStationNotFound =>
      'Não foi possível atualizar — posto não encontrado nas proximidades';

  @override
  String get addedToFavorites => 'Adicionado aos favoritos';

  @override
  String get removedFromFavorites => 'Removido dos favoritos';

  @override
  String get addFavorite => 'Adicionar aos favoritos';

  @override
  String get removeFavorite => 'Remover dos favoritos';

  @override
  String get currentLocation => 'Localização atual';

  @override
  String get gpsError => 'Erro GPS';

  @override
  String get couldNotResolve => 'Não foi possível resolver início ou destino';

  @override
  String get start => 'Início';

  @override
  String get destination => 'Destino';

  @override
  String get cityAddressOrGps => 'Cidade, morada ou GPS';

  @override
  String get cityOrAddress => 'Cidade ou morada';

  @override
  String get useGps => 'Usar GPS';

  @override
  String get stop => 'Paragem';

  @override
  String stopN(int n) {
    return 'Paragem $n';
  }

  @override
  String get addStop => 'Adicionar paragem';

  @override
  String get searchAlongRoute => 'Pesquisar ao longo da rota';

  @override
  String get cheapest => 'Mais barato';

  @override
  String nStations(int count) {
    return '$count postos';
  }

  @override
  String nBest(int count) {
    return '$count melhores';
  }

  @override
  String get fuelPricesTankerkoenig => 'Preços de combustível (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Necessário para pesquisa de preços de combustível na Alemanha';

  @override
  String get evChargingOpenChargeMap => 'Carregamento EV (OpenChargeMap)';

  @override
  String get customKey => 'Chave personalizada';

  @override
  String get appDefaultKey => 'Chave predefinida da app';

  @override
  String get optionalOverrideKey =>
      'Opcional: substituir a chave integrada pela sua';

  @override
  String get requiredForEvSearch =>
      'Necessário para pesquisa de postos de carregamento EV';

  @override
  String get edit => 'Editar';

  @override
  String get fuelPricesApiKey => 'Chave API preços de combustível';

  @override
  String get tankerkoenigApiKey => 'Chave API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Chave API carregamento EV';

  @override
  String get openChargeMapApiKey => 'Chave API OpenChargeMap';

  @override
  String get routeSegment => 'Segmento da rota';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Mostrar posto mais barato a cada $km km ao longo da rota';
  }

  @override
  String get avoidHighways => 'Evitar autoestradas';

  @override
  String get avoidHighwaysDesc =>
      'O cálculo da rota evita portagens e autoestradas';

  @override
  String get showFuelStations => 'Mostrar postos de combustível';

  @override
  String get showFuelStationsDesc =>
      'Incluir postos de gasolina, gasóleo, GPL, GNC';

  @override
  String get showEvStations => 'Mostrar postos de carregamento';

  @override
  String get showEvStationsDesc =>
      'Incluir postos de carregamento elétrico nos resultados';

  @override
  String get noStationsAlongThisRoute =>
      'Nenhum posto encontrado ao longo desta rota.';

  @override
  String get fuelCostCalculator => 'Calculadora de custo de combustível';

  @override
  String get distanceKm => 'Distância (km)';

  @override
  String get consumptionL100km => 'Consumo (L/100km)';

  @override
  String get fuelPriceEurL => 'Preço combustível (EUR/L)';

  @override
  String get tripCost => 'Custo da viagem';

  @override
  String get fuelNeeded => 'Combustível necessário';

  @override
  String get totalCost => 'Custo total';

  @override
  String get enterCalcValues =>
      'Introduza distância, consumo e preço para calcular o custo da viagem';

  @override
  String get priceHistory => 'Histórico de preços';

  @override
  String get noPriceHistory => 'Sem histórico de preços ainda';

  @override
  String get noHourlyData => 'Sem dados horários';

  @override
  String get noStatistics => 'Sem estatísticas disponíveis';

  @override
  String get statMin => 'Mín';

  @override
  String get statMax => 'Máx';

  @override
  String get statAvg => 'Méd';

  @override
  String get showAllFuelTypes => 'Mostrar todos os tipos de combustível';

  @override
  String get connected => 'Ligado';

  @override
  String get notConnected => 'Não ligado';

  @override
  String get connectTankSync => 'Ligar TankSync';

  @override
  String get disconnectTankSync => 'Desligar TankSync';

  @override
  String get viewMyData => 'Ver os meus dados';

  @override
  String get optionalCloudSync =>
      'Sincronização na nuvem opcional para alertas, favoritos e notificações push';

  @override
  String get tapToUpdateGps => 'Toque para atualizar a posição GPS';

  @override
  String get gpsAutoUpdateHint =>
      'A posição GPS é obtida automaticamente ao pesquisar. Também pode atualizá-la manualmente aqui.';

  @override
  String get clearGpsConfirm =>
      'Limpar a posição GPS guardada? Pode atualizá-la novamente a qualquer momento.';

  @override
  String get pageNotFound => 'Página não encontrada';

  @override
  String get deleteAllServerData => 'Eliminar todos os dados do servidor';

  @override
  String get deleteServerDataConfirm => 'Eliminar todos os dados do servidor?';

  @override
  String get deleteEverything => 'Eliminar tudo';

  @override
  String get allDataDeleted => 'Todos os dados do servidor eliminados';

  @override
  String get disconnectConfirm => 'Desligar TankSync?';

  @override
  String get disconnect => 'Desligar';

  @override
  String get myServerData => 'Os meus dados do servidor';

  @override
  String get anonymousUuid => 'UUID anónimo';

  @override
  String get server => 'Servidor';

  @override
  String get syncedData => 'Dados sincronizados';

  @override
  String get pushTokens => 'Tokens push';

  @override
  String get priceReports => 'Relatórios de preços';

  @override
  String get totalItems => 'Total de itens';

  @override
  String get estimatedSize => 'Tamanho estimado';

  @override
  String get viewRawJson => 'Ver dados brutos como JSON';

  @override
  String get exportJson => 'Exportar como JSON (área de transferência)';

  @override
  String get jsonCopied => 'JSON copiado para a área de transferência';

  @override
  String get rawDataJson => 'Dados brutos (JSON)';

  @override
  String get close => 'Fechar';

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
  String get alertStatsActive => 'Ativos';

  @override
  String get alertStatsToday => 'Hoje';

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
  String privacyCopyErrorLog(int count) {
    return 'Copy error log to clipboard ($count)';
  }

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
  String get amenities => 'Comodidades';

  @override
  String get amenityShop => 'Loja';

  @override
  String get amenityCarWash => 'Lavagem';

  @override
  String get amenityAirPump => 'Ar';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Comida';

  @override
  String get amenityAtm => 'Multibanco';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'Recarga';

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
  String get nearestStations => 'Postos mais proximos';

  @override
  String get nearestStationsHint =>
      'Encontre os postos mais proximos com a sua localizacao atual';

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
  String get qrScannerPermissionDenied =>
      'Camera access is needed to scan QR codes.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Camera access was denied. Open settings to grant it.';

  @override
  String get qrScannerRetryPermission => 'Try again';

  @override
  String get qrScannerOpenSettings => 'Open settings';

  @override
  String get qrScannerTimeout =>
      'No QR code detected. Move closer or try again.';

  @override
  String get qrScannerRetry => 'Try again';

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
  String get navConsumption => 'Consumption';

  @override
  String get vehicleBaselineSectionTitle => 'Baseline calibration';

  @override
  String get vehicleBaselineEmpty =>
      'No samples yet — start an OBD2 trip to begin learning this vehicle\'s fuel profile.';

  @override
  String get vehicleBaselineProgress =>
      'Learned from samples across driving situations.';

  @override
  String get vehicleBaselineReset => 'Reset baseline';

  @override
  String get vehicleBaselineResetConfirmTitle => 'Reset baseline?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'This wipes every learned sample for this vehicle. You\'ll drift back to the cold-start defaults until new trips refill the profile.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapter';

  @override
  String get vehicleAdapterEmpty =>
      'No adapter paired. Pair one so the app can reconnect automatically next time.';

  @override
  String get vehicleAdapterUnnamed => 'Unknown adapter';

  @override
  String get vehicleAdapterPair => 'Pair adapter';

  @override
  String get vehicleAdapterForget => 'Forget adapter';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFirstTrip => 'First trip';

  @override
  String get achievementFirstTripDesc => 'Record your first OBD2 trip.';

  @override
  String get achievementFirstFillUp => 'First fill-up';

  @override
  String get achievementFirstFillUpDesc => 'Log your first fill-up.';

  @override
  String get achievementTenTrips => '10 trips';

  @override
  String get achievementTenTripsDesc => 'Record 10 OBD2 trips.';

  @override
  String get achievementZeroHarsh => 'Smooth driver';

  @override
  String get achievementZeroHarshDesc =>
      'Complete a trip of 10 km or more with no harsh braking or acceleration.';

  @override
  String get achievementEcoWeek => 'Eco week';

  @override
  String get achievementEcoWeekDesc =>
      'Drive 7 consecutive days with at least one smooth trip each day.';

  @override
  String get achievementPriceWin => 'Price win';

  @override
  String get achievementPriceWinDesc =>
      'Log a fill-up that beats the station\'s 30-day average by 5 % or more.';

  @override
  String get syncBaselinesToggleTitle => 'Share learned vehicle profiles';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Upload per-vehicle consumption baselines so a second device can reuse them.';

  @override
  String get obd2StatusConnected => 'OBD2 adapter: connected';

  @override
  String get obd2StatusAttempting => 'OBD2 adapter: connecting';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapter: unreachable';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: Bluetooth permission needed';

  @override
  String get obd2StatusConnectedBody => 'Ready to record a trip.';

  @override
  String get obd2StatusAttemptingBody => 'Connecting in the background…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter out of range or already in use by another app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Grant Bluetooth permission in system settings to reconnect automatically.';

  @override
  String get obd2StatusNoAdapter => 'No adapter paired';

  @override
  String get obd2StatusForget => 'Forget adapter';

  @override
  String get tripHistoryTitle => 'Trip history';

  @override
  String get tripHistoryEmptyTitle => 'No trips yet';

  @override
  String get tripHistoryEmptySubtitle =>
      'Connect an OBD2 adapter and record a trip to start building your driving history.';

  @override
  String get tripHistoryUnknownDate => 'Unknown date';

  @override
  String get situationIdle => 'Idle';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urban';

  @override
  String get situationHighway => 'Highway';

  @override
  String get situationDecel => 'Decelerating';

  @override
  String get situationClimbing => 'Climbing / loaded';

  @override
  String get situationHardAccel => 'Hard accel';

  @override
  String get situationFuelCut => 'Fuel cut — coast';

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
  String errorUpstreamCertExpired(String host) {
    return 'The data provider ($host) is serving an expired or invalid TLS certificate. The app cannot load data from this source until the provider fixes it. Please contact $host.';
  }

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
  String get alertsLoadErrorTitle => 'Couldn\'t load your alerts';

  @override
  String get alertsBackgroundCheckErrorTitle => 'Alert background check failed';

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

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxembourg fuel prices are government-regulated and uniform nationwide.';

  @override
  String get luxembourgFuelUnleaded95 => 'Unleaded 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Unleaded 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxembourg regulated prices are unavailable.';

  @override
  String get reportIssueTitle => 'Report a problem';

  @override
  String get enterCorrection => 'Please enter the correction';

  @override
  String get reportNoBackendAvailable =>
      'The report could not be sent: no reporting service is configured for this country. Enable TankSync in Settings to send community reports.';

  @override
  String get correctName => 'Correct station name';

  @override
  String get correctAddress => 'Correct address';

  @override
  String get wrongE85Price => 'Wrong E85 price';

  @override
  String get wrongE98Price => 'Wrong Super 98 price';

  @override
  String get wrongLpgPrice => 'Wrong LPG price';

  @override
  String get wrongStationName => 'Wrong station name';

  @override
  String get wrongStationAddress => 'Wrong address';

  @override
  String get independentStation => 'Independent station';

  @override
  String get serviceRemindersSection => 'Service reminders';

  @override
  String get serviceRemindersEmpty => 'No reminders yet — pick a preset above.';

  @override
  String get addServiceReminder => 'Add reminder';

  @override
  String get serviceReminderPresetOil => 'Oil (15,000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Oil change';

  @override
  String get serviceReminderPresetTires => 'Tires (20,000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Tires';

  @override
  String get serviceReminderPresetInspection => 'Inspection (30,000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Inspection';

  @override
  String get serviceReminderLabel => 'Label';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Last service';

  @override
  String get serviceReminderMarkDone => 'Mark as done';

  @override
  String get serviceReminderDueTitle => 'Service due';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label is due — $kmOver km past the interval.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Register at OPINET to get a free API key';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired => 'Register at CNE to get a free API key';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinLabel => 'VIN (optional)';

  @override
  String get vinDecodeTooltip => 'Decode VIN';

  @override
  String get vinConfirmTitle => 'Is this your car?';

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
  String get vinConfirmAction => 'Yes, auto-fill';

  @override
  String get vinModifyAction => 'Modify manually';

  @override
  String get vinPartialInfoNote =>
      'Partial info (offline). You can edit below.';

  @override
  String get vinDecodeError => 'Couldn\'t decode this VIN';

  @override
  String get vinInvalidFormat => 'Invalid VIN format';

  @override
  String get obd2PauseBannerTitle => 'OBD2 connection lost — recording paused';

  @override
  String get obd2PauseBannerResume => 'Resume recording';

  @override
  String get obd2PauseBannerEnd => 'End recording';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Consumption calibration updated for $vehicleName — accuracy improved by $percent%';
  }

  @override
  String get veResetAction => 'Reset calibration';

  @override
  String get veResetConfirmTitle => 'Reset calibration?';

  @override
  String get veResetConfirmBody =>
      'This will discard the learned per-vehicle calibration and restore the default value (0.85).';
}
