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
}
