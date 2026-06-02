// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get fabOpenCriteria => 'Abrir pesquisa';

  @override
  String get fabOpenResults => 'Abrir resultados';

  @override
  String get fabRunSearch => 'Executar pesquisa';

  @override
  String get fabRefineCriteria => 'Refinar pesquisa';

  @override
  String get routeSearchPartialBanner => 'A procurar mais estações…';

  @override
  String get routeSearchingChip => 'Searching the route…';

  @override
  String routeSegmentSummaryBadge(String km) {
    return 'Every $km km';
  }

  @override
  String get searchCriteriaTitle => 'Critérios de pesquisa';

  @override
  String get searchCriteriaOpen => 'Pesquisar';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'A $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Toque para iniciar a pesquisa';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Mudar de país?';

  @override
  String countryChangeBody(String country) {
    return 'Mudar para $country irá alterar:';
  }

  @override
  String get countryChangeCurrency => 'Moeda';

  @override
  String get countryChangeDistance => 'Distância';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Formato de preço';

  @override
  String get countryChangeNote =>
      'Os favoritos e registos de abastecimento existentes não são reescritos; apenas as novas entradas utilizam as novas unidades.';

  @override
  String get countryChangeConfirm => 'Mudar';

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
  String get cacheTtlGroupNetwork => 'Rede';

  @override
  String get cacheTtlGroupData => 'Dados';

  @override
  String get cacheTtlGroupGeocoding => 'Geocodificação';

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
  String get reportThisIssue => 'Reportar este problema';

  @override
  String get reportAlreadySent => 'Já reportou este problema.';

  @override
  String get reportConsentTitle => 'Reportar para o GitHub?';

  @override
  String get reportConsentBody =>
      'Isto irá abrir um problema público no GitHub com os detalhes do erro abaixo. Não são incluídas coordenadas GPS, chaves de API nem dados pessoais.';

  @override
  String get reportConsentConfirm => 'Abrir GitHub';

  @override
  String get reportConsentCancel => 'Cancelar';

  @override
  String get configProfileSection => 'Perfil';

  @override
  String get configActiveProfile => 'Perfil ativo';

  @override
  String get configPreferredFuel => 'Combustível preferido';

  @override
  String get configCountry => 'País';

  @override
  String get configRouteSegment => 'Segmento de rota';

  @override
  String get configApiKeysSection => 'Chaves de API';

  @override
  String get configTankerkoenigKey => 'Chave de API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Configurada';

  @override
  String get configApiKeyNotSet => 'Não definida (modo de demonstração)';

  @override
  String get configApiKeyCommunity => 'Predefinição (chave comunitária)';

  @override
  String get searchLocationPlaceholder => 'Morada, código postal ou cidade';

  @override
  String get configEvKey => 'Chave de API de carregamento elétrico';

  @override
  String get configEvKeyCustom => 'Chave personalizada';

  @override
  String get configEvKeyShared => 'Predefinição (partilhada)';

  @override
  String get configCloudSyncSection => 'Sincronização na nuvem';

  @override
  String get configTankSyncConnected => 'Ligado';

  @override
  String get configTankSyncDisabled => 'Desativado';

  @override
  String get configAuthMode => 'Modo de autenticação';

  @override
  String get configAuthEmail => 'E-mail (persistente)';

  @override
  String get configAuthAnonymous => 'Anónimo (apenas neste dispositivo)';

  @override
  String get configDatabase => 'Base de dados';

  @override
  String get configPrivacySummary => 'Resumo de privacidade';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoritos, alertas e postos ignorados são sincronizados na sua base de dados privada\n• A posição GPS e as chaves de API nunca saem do seu dispositivo\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Todos os dados são guardados localmente apenas neste dispositivo\n• Nenhum dado é enviado para qualquer servidor\n• Chaves de API encriptadas no armazenamento seguro do dispositivo';

  @override
  String get configAuthNoteEmail =>
      'A conta de e-mail permite acesso entre dispositivos';

  @override
  String get configAuthNoteAnonymous =>
      'Conta anónima — dados associados a este dispositivo';

  @override
  String get configNone => 'Nenhum';

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
  String get demoModeBannerAction => 'Obter preços em tempo real';

  @override
  String get sortDistance => 'Distância';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Avaliação';

  @override
  String get sortPriceDistance => 'Preço/km';

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
  String get routeModeBannerLabel =>
      'Modo rota — distâncias ao longo do corredor';

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
  String get routePlanningSection => 'Planejamento de rota';

  @override
  String get routeMinSaving => 'Economia mínima';

  @override
  String get routeMinSavingOff => 'Desativado';

  @override
  String get routeMinSavingOffCaption =>
      'Mostrando todos os postos encontrados na rota';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Apenas postos dentro de $amount do mais barato da rota';
  }

  @override
  String get routeDetourBudget => 'Desvio máximo';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Mostrar postos até $km km da sua rota direta';
  }

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
  String get priceHistory => 'Histórico de preços';

  @override
  String get ignoredStationsLabel => 'Ignoradas';

  @override
  String get ratingsLabel => 'Avaliações';

  @override
  String get favoritesDataCache => 'Dados de favoritos';

  @override
  String get citySearchCache => 'Pesquisa de cidade';

  @override
  String get dataDeletionNotAvailableCommunity =>
      'A exclusão de dados não está disponível no modo Comunidade. Desconecte-se primeiro ou use um banco de dados privado.';

  @override
  String priceHistoryStationsTracked(int count) {
    return '$count estações monitoradas';
  }

  @override
  String alertsConfiguredCount(int count) {
    return '$count configuradas';
  }

  @override
  String ignoredStationsHidden(int count) {
    return '$count estações ocultas';
  }

  @override
  String ratingsStationsRated(int count) {
    return '$count estações avaliadas';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Esquecer todas as viagens sincronizadas';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Esquecer todas as viagens sincronizadas?';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Todos os resumos e detalhes de viagens serão removidos do servidor. O histórico de viagens local neste dispositivo não será afetado.\n\nEsta ação não pode ser revertida.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Esquecer tudo';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Todas as viagens sincronizadas removidas do servidor';

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
  String get syncedTrips => 'Viagens';

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
  String get account => 'Conta';

  @override
  String get continueAsGuest => 'Continuar como convidado';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get signIn => 'Iniciar sessão';

  @override
  String get upgradeToEmail => 'Criar conta de e-mail';

  @override
  String get savedRoutes => 'Rotas guardadas';

  @override
  String get noSavedRoutes => 'Sem rotas guardadas';

  @override
  String get noSavedRoutesHint =>
      'Pesquise ao longo de uma rota e guarde-a para acesso rápido mais tarde.';

  @override
  String get saveRoute => 'Guardar rota';

  @override
  String get routeName => 'Nome da rota';

  @override
  String itineraryDeleted(String name) {
    return '$name eliminado';
  }

  @override
  String loadingRoute(String name) {
    return 'A carregar rota: $name';
  }

  @override
  String get refreshFailed => 'Falha na atualização. Tente novamente.';

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
      'Configure a aplicação em alguns passos rápidos.';

  @override
  String get onboardingApiKeyDescription =>
      'Registe-se para obter uma chave de API gratuita ou ignore para explorar a aplicação com dados de demonstração.';

  @override
  String get onboardingComplete => 'Tudo pronto!';

  @override
  String get onboardingCompleteHint =>
      'Pode alterar estas definições a qualquer momento no seu perfil.';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingSkip => 'Ignorar';

  @override
  String get onboardingFinish => 'Começar';

  @override
  String crossBorderNearby(String country) {
    return '$country está próximo';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km até à fronteira';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Média aqui: $price EUR ($count postos)';
  }

  @override
  String get allPricesView => 'Todos os preços';

  @override
  String get compactView => 'Compacto';

  @override
  String get switchToAllPricesView => 'Mudar para vista de todos os preços';

  @override
  String get switchToCompactView => 'Mudar para vista compacta';

  @override
  String get unavailable => 'N/D';

  @override
  String get outOfStock => 'Esgotado';

  @override
  String get gdprTitle => 'A sua privacidade';

  @override
  String get gdprSubtitle =>
      'Esta aplicação respeita a sua privacidade. Escolha quais os dados que pretende partilhar. Pode alterar estas definições a qualquer momento.';

  @override
  String get gdprLocationTitle => 'Acesso à localização';

  @override
  String get gdprLocationDescription =>
      'As suas coordenadas são enviadas para a API de preços de combustível para encontrar postos próximos. Os dados de localização nunca são guardados num servidor nem utilizados para rastreio.';

  @override
  String get gdprLocationShort =>
      'Encontrar postos de combustível próximos usando a sua localização';

  @override
  String get gdprErrorReportingTitle => 'Relatório de erros';

  @override
  String get gdprErrorReportingDescription =>
      'Os relatórios anónimos de falhas ajudam a melhorar a aplicação. Não são incluídos dados pessoais. Os relatórios são enviados via Sentry apenas quando configurado.';

  @override
  String get gdprErrorReportingShort =>
      'Enviar relatórios anónimos de falhas para melhorar a aplicação';

  @override
  String get gdprCloudSyncTitle => 'Sincronização na nuvem';

  @override
  String get gdprCloudSyncDescription =>
      'Sincronize favoritos e alertas entre dispositivos via TankSync. Utiliza autenticação anónima. Os seus dados são encriptados em trânsito.';

  @override
  String get gdprCloudSyncShort =>
      'Sincronizar favoritos e alertas entre dispositivos';

  @override
  String get gdprLegalBasis =>
      'Base legal: Art. 6.º, n.º 1, al. a) do RGPD (Consentimento). Pode retirar o consentimento a qualquer momento nas Definições.';

  @override
  String get gdprAcceptAll => 'Aceitar tudo';

  @override
  String get gdprAcceptSelected => 'Aceitar selecionados';

  @override
  String get gdprSettingsHint =>
      'Pode alterar as suas preferências de privacidade a qualquer momento.';

  @override
  String get routeSaved => 'Rota guardada!';

  @override
  String get routeSaveFailed => 'Falha ao guardar a rota';

  @override
  String get sqlCopied => 'SQL copiado para a área de transferência';

  @override
  String get connectionDataCopied => 'Dados de ligação copiados';

  @override
  String get accountDeleted => 'Conta eliminada. Dados locais preservados.';

  @override
  String get switchedToAnonymous => 'Mudado para sessão anónima';

  @override
  String failedToSwitch(String error) {
    return 'Falha ao mudar: $error';
  }

  @override
  String get topicUrlCopied => 'URL do tópico copiado';

  @override
  String get testNotificationSent => 'Notificação de teste enviada!';

  @override
  String get testNotificationFailed => 'Falha ao enviar notificação de teste';

  @override
  String get pushUpdateFailed =>
      'Falha ao atualizar definição de notificações push';

  @override
  String get connectedAsGuest => 'Ligado como convidado';

  @override
  String get accountCreated => 'Conta criada!';

  @override
  String get signedIn => 'Sessão iniciada!';

  @override
  String stationHidden(String name) {
    return '$name ocultado';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name removido dos favoritos';
  }

  @override
  String invalidApiKey(String error) {
    return 'Chave de API inválida: $error';
  }

  @override
  String get invalidQrCode => 'Formato de código QR inválido';

  @override
  String get invalidQrCodeTankSync =>
      'Código QR inválido — era esperado o formato TankSync';

  @override
  String get tankSyncConnected => 'TankSync ligado!';

  @override
  String get syncCompleted => 'Sincronização concluída — dados atualizados';

  @override
  String get deviceCodeCopied => 'Código do dispositivo copiado';

  @override
  String get undo => 'Desfazer';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Introduza um $label válido com $length dígitos';
  }

  @override
  String get freshnessAgo => 'atrás';

  @override
  String get freshnessStale => 'Desatualizado';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Atualidade dos dados: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Logótipo $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Avaliar $count estrelas',
      one: 'Avaliar 1 estrela',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Fraca';

  @override
  String get passwordStrengthFair => 'Razoável';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordReqMinLength => 'Pelo menos 8 caracteres';

  @override
  String get passwordReqUppercase => 'Pelo menos 1 letra maiúscula';

  @override
  String get passwordReqLowercase => 'Pelo menos 1 letra minúscula';

  @override
  String get passwordReqDigit => 'Pelo menos 1 número';

  @override
  String get passwordReqSpecial => 'Pelo menos 1 carácter especial';

  @override
  String get passwordTooWeak =>
      'A palavra-passe não cumpre todos os requisitos';

  @override
  String get brandFilterAll => 'Todos';

  @override
  String get brandFilterNoHighway => 'Sem autoestrada';

  @override
  String get swipeTutorialMessage =>
      'Deslize para a direita para navegar, deslize para a esquerda para remover';

  @override
  String get swipeTutorialDismiss => 'Percebido';

  @override
  String get alertStatsActive => 'Ativos';

  @override
  String get alertStatsToday => 'Hoje';

  @override
  String get alertStatsThisWeek => 'Esta semana';

  @override
  String get privacyDashboardTitle => 'Painel de privacidade';

  @override
  String get privacyDashboardSubtitle =>
      'Veja, exporte ou elimine os seus dados';

  @override
  String get privacyDashboardBanner =>
      'Os seus dados pertencem-lhe. Aqui pode ver tudo o que esta aplicação armazena, exportá-lo ou eliminá-lo.';

  @override
  String get privacyLocalData => 'Dados neste dispositivo';

  @override
  String get privacyIgnoredStations => 'Postos ignorados';

  @override
  String get privacyRatings => 'Avaliações de postos';

  @override
  String get privacyPriceHistory => 'Postos com histórico de preços';

  @override
  String get privacyProfiles => 'Perfis de pesquisa';

  @override
  String get privacyItineraries => 'Rotas guardadas';

  @override
  String get privacyCacheEntries => 'Entradas em cache';

  @override
  String get privacyApiKey => 'Chave de API guardada';

  @override
  String get privacyEvApiKey => 'Chave de API EV guardada';

  @override
  String get privacyEstimatedSize => 'Armazenamento estimado';

  @override
  String get privacySyncedData => 'Sincronização na nuvem (TankSync)';

  @override
  String get privacySyncDisabled =>
      'A sincronização na nuvem está desativada. Todos os dados ficam apenas neste dispositivo.';

  @override
  String get privacySyncMode => 'Modo de sincronização';

  @override
  String get privacySyncUserId => 'ID de utilizador';

  @override
  String get privacySyncDescription =>
      'Quando a sincronização está ativada, favoritos, alertas, postos ignorados e avaliações também são guardados no servidor TankSync.';

  @override
  String get privacyViewServerData => 'Ver dados no servidor';

  @override
  String get privacyExportButton => 'Exportar todos os dados como JSON';

  @override
  String get privacyExportSuccess =>
      'Dados exportados para a área de transferência';

  @override
  String get privacyExportCsvButton => 'Exportar todos os dados como CSV';

  @override
  String get privacyExportCsvSuccess =>
      'Dados CSV exportados para a área de transferência';

  @override
  String get savedToDownloadsFolder => 'Guardado na pasta Transferências';

  @override
  String get privacyDeleteButton => 'Eliminar todos os dados';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Copiar registo de erros ($count)';
  }

  @override
  String privacySaveErrorLog(int count) {
    return 'Guardar registo de erros ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Limpar registo de erros';

  @override
  String get privacyErrorLogCleared => 'Registo de erros limpo';

  @override
  String get privacyDeleteTitle => 'Eliminar todos os dados?';

  @override
  String get privacyDeleteBody =>
      'Isto irá eliminar permanentemente:\n\n- Todos os favoritos e dados de postos\n- Todos os perfis de pesquisa\n- Todos os alertas de preços\n- Todo o histórico de preços\n- Todos os dados em cache\n- A sua chave de API\n- Todas as definições da aplicação\n\nA aplicação será reposta no estado inicial. Esta ação não pode ser revertida.';

  @override
  String get privacyDeleteConfirm => 'Eliminar tudo';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

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
  String get paymentMethods => 'Métodos de pagamento';

  @override
  String get paymentMethodCash => 'Numerário';

  @override
  String get paymentMethodCard => 'Cartão';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Cartão de combustível';

  @override
  String get paymentMethodApp => 'Aplicação';

  @override
  String payWithApp(String app) {
    return 'Pagar com $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Comparado com a média dos seus últimos 3 abastecimentos ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumo $value L/100 km, $delta face à sua média';
  }

  @override
  String get drivingMode => 'Modo de condução';

  @override
  String get drivingExit => 'Sair';

  @override
  String get drivingNearestStation => 'Mais próximo';

  @override
  String get drivingTapToUnlock => 'Toque para desbloquear';

  @override
  String get drivingSafetyTitle => 'Aviso de segurança';

  @override
  String get drivingSafetyMessage =>
      'Não utilize a aplicação enquanto conduz. Pare num local seguro antes de interagir com o ecrã. O condutor é sempre responsável pela condução segura do veículo.';

  @override
  String get drivingSafetyAccept => 'Compreendo';

  @override
  String get voiceAnnouncementsTitle => 'Anúncios por voz';

  @override
  String get voiceAnnouncementsDescription =>
      'Anunciar postos baratos nas proximidades enquanto conduz';

  @override
  String get voiceAnnouncementsEnabled => 'Ativar anúncios por voz';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Apenas abaixo de $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, a $distance quilómetros, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Raio de anúncio';

  @override
  String get voiceAnnouncementCooldown => 'Intervalo de repetição';

  @override
  String get nearestStations => 'Postos mais proximos';

  @override
  String get nearestStationsHint =>
      'Encontre os postos mais proximos com a sua localizacao atual';

  @override
  String get consumptionLogTitle => 'Consumo de combustível';

  @override
  String get consumptionLogMenuTitle => 'Registo de consumo';

  @override
  String get consumptionLogMenuSubtitle =>
      'Registe abastecimentos e calcule L/100km';

  @override
  String get consumptionStatsTitle => 'Estatísticas de consumo';

  @override
  String get addFillUp => 'Adicionar abastecimento';

  @override
  String get noFillUpsTitle => 'Sem abastecimentos';

  @override
  String get noFillUpsSubtitle =>
      'Registe o seu primeiro abastecimento para começar a acompanhar o consumo.';

  @override
  String get fillUpDate => 'Data';

  @override
  String get liters => 'Litros';

  @override
  String get odometerKm => 'Odómetro (km)';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get stationPreFilled => 'Posto pré-preenchido';

  @override
  String get statAvgConsumption => 'Méd. L/100km';

  @override
  String get statAvgCostPerKm => 'Custo méd./km';

  @override
  String get statTotalLiters => 'Total de litros';

  @override
  String get statTotalSpent => 'Total gasto';

  @override
  String get statFillUpCount => 'Abastecimentos';

  @override
  String get fieldRequired => 'Obrigatório';

  @override
  String get fieldInvalidNumber => 'Número inválido';

  @override
  String get carbonDashboardTitle => 'Painel de carbono';

  @override
  String get carbonEmptyTitle => 'Sem dados';

  @override
  String get carbonEmptySubtitle =>
      'Registe abastecimentos para ver o seu painel de carbono.';

  @override
  String get carbonSummaryTotalCost => 'Custo total';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 total';

  @override
  String get monthlyCostsTitle => 'Custos mensais';

  @override
  String get monthlyEmissionsTitle => 'Emissões mensais de CO2';

  @override
  String get vehiclesTitle => 'Os meus veículos';

  @override
  String get vehiclesMenuTitle => 'Os meus veículos';

  @override
  String get vehiclesMenuSubtitle =>
      'Bateria, conectores, preferências de carregamento';

  @override
  String get vehiclesEmptyMessage =>
      'Adicione o seu carro para filtrar por conector e estimar custos de carregamento.';

  @override
  String get vehiclesWizardTitle => 'Os meus veículos (opcional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Adicione o seu carro para pré-preencher o registo de consumo e ativar filtros de conector EV. Pode ignorar e adicionar veículos mais tarde.';

  @override
  String get vehiclesWizardNoneYet => 'Nenhum veículo configurado ainda.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veículos',
      one: '1 veículo',
    );
    return 'Tem $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Ignore para concluir a configuração — pode adicionar veículos a qualquer momento nas Definições.';

  @override
  String get fillUpVehicleLabel => 'Veículo';

  @override
  String get fillUpVehicleNone => 'Sem veículo';

  @override
  String get fillUpVehicleRequired => 'O veículo é obrigatório';

  @override
  String get reportScanError => 'Reportar erro de leitura';

  @override
  String get pickStationTitle => 'Escolher um posto';

  @override
  String get pickStationHelper =>
      'Inicie o abastecimento a partir de um posto conhecido para que os preços, marca e tipo de combustível sejam preenchidos automaticamente.';

  @override
  String get pickStationEmpty =>
      'Ainda não tem postos favoritos — adicione alguns em Pesquisa ou Favoritos, ou ignore e preencha manualmente.';

  @override
  String get pickStationSkip => 'Ignorar — adicionar sem posto';

  @override
  String get scanPump => 'Ler bomba';

  @override
  String get scanPayment => 'Ler QR de pagamento';

  @override
  String get qrPaymentBeneficiary => 'Beneficiário';

  @override
  String get qrPaymentAmount => 'Montante';

  @override
  String get qrPaymentEpcTitle => 'Pagamento SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Nenhum campo descodificado';

  @override
  String get qrPaymentOpenInBank => 'Abrir na aplicação bancária';

  @override
  String get qrPaymentLaunchFailed =>
      'Nenhuma aplicação disponível para abrir este código';

  @override
  String get qrPaymentUnknownTitle => 'Código não reconhecido';

  @override
  String get qrPaymentCopyRaw => 'Copiar texto não processado';

  @override
  String get qrPaymentCopiedRaw => 'Copiado para a área de transferência';

  @override
  String get qrPaymentReport => 'Reportar esta leitura';

  @override
  String get qrPaymentEpcCopied =>
      'Dados bancários copiados — cole na sua aplicação bancária';

  @override
  String get qrScannerGuidance => 'Aponte a câmara para um código QR';

  @override
  String get qrScannerPermissionDenied =>
      'O acesso à câmara é necessário para ler códigos QR.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'O acesso à câmara foi negado. Abra as definições para o conceder.';

  @override
  String get qrScannerRetryPermission => 'Tentar novamente';

  @override
  String get qrScannerOpenSettings => 'Abrir definições';

  @override
  String get qrScannerTimeout =>
      'Nenhum código QR detetado. Aproxime-se ou tente novamente.';

  @override
  String get qrScannerRetry => 'Tentar novamente';

  @override
  String get torchOn => 'Ligar lanterna';

  @override
  String get torchOff => 'Desligar lanterna';

  @override
  String get obdNoAdapter => 'Nenhum adaptador OBD2 ao alcance';

  @override
  String get obdOdometerUnavailable => 'Não foi possível ler o odómetro';

  @override
  String get obdPermissionDenied =>
      'Conceda permissão de Bluetooth nas definições do sistema';

  @override
  String get obdAdapterUnresponsive =>
      'O adaptador não respondeu — ligue o contacto e tente novamente';

  @override
  String get obdPickerTitle => 'Escolher um adaptador OBD2';

  @override
  String get obdPickerScanning => 'A procurar adaptadores…';

  @override
  String get obdPickerConnecting => 'A ligar…';

  @override
  String get themeSettingTitle => 'Tema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get themeModeSystem => 'Seguir sistema';

  @override
  String get tripRecordingTitle => 'A gravar viagem';

  @override
  String get tripSummaryTitle => 'Resumo da viagem';

  @override
  String get tripMetricDistance => 'Distância';

  @override
  String get tripMetricSpeed => 'Velocidade';

  @override
  String get tripMetricFuelUsed => 'Combustível usado';

  @override
  String get tripMetricAvgConsumption => 'Méd.';

  @override
  String get tripMetricElapsed => 'Tempo decorrido';

  @override
  String get tripMetricOdometer => 'Odómetro';

  @override
  String get tripStop => 'Parar gravação';

  @override
  String get tripPause => 'Pausar';

  @override
  String get tripResume => 'Retomar';

  @override
  String get tripBannerRecording => 'A gravar viagem';

  @override
  String get tripBannerPaused => 'Viagem pausada — toque para retomar';

  @override
  String get navConsumption => 'Consumo';

  @override
  String get vehicleBaselineSectionTitle => 'Calibração de referência';

  @override
  String get vehicleBaselineEmpty =>
      'Sem amostras ainda — inicie uma viagem OBD2 para começar a aprender o perfil de combustível deste veículo.';

  @override
  String get vehicleBaselineProgress =>
      'Aprendido a partir de amostras em várias situações de condução.';

  @override
  String get vehicleBaselineReset =>
      'Repor referência de situações de condução';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Repor referência de situações de condução?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Isto apaga todas as amostras aprendidas para este veículo. O perfil voltará aos valores predefinidos de arranque a frio até que novas viagens o preencham.';

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
      'Nenhum adaptador emparelhado. Emparelhe um para que a aplicação se possa ligar automaticamente da próxima vez.';

  @override
  String get vehicleAdapterUnnamed => 'Adaptador desconhecido';

  @override
  String get vehicleAdapterPair => 'Emparelhar adaptador';

  @override
  String get vehicleAdapterForget => 'Esquecer adaptador';

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String get achievementFirstTrip => 'Primeira viagem';

  @override
  String get achievementFirstTripDesc => 'Grave a sua primeira viagem OBD2.';

  @override
  String get achievementFirstFillUp => 'Primeiro abastecimento';

  @override
  String get achievementFirstFillUpDesc =>
      'Registe o seu primeiro abastecimento.';

  @override
  String get achievementTenTrips => '10 viagens';

  @override
  String get achievementTenTripsDesc => 'Grave 10 viagens OBD2.';

  @override
  String get achievementZeroHarsh => 'Condutor suave';

  @override
  String get achievementZeroHarshDesc =>
      'Complete uma viagem de 10 km ou mais sem travagens ou acelerações bruscas.';

  @override
  String get achievementEcoWeek => 'Semana eco';

  @override
  String get achievementEcoWeekDesc =>
      'Conduza 7 dias consecutivos com pelo menos uma viagem suave por dia.';

  @override
  String get achievementPriceWin => 'Bom preço';

  @override
  String get achievementPriceWinDesc =>
      'Registe um abastecimento com um preço 5% ou mais abaixo da média dos últimos 30 dias do posto.';

  @override
  String get syncBaselinesToggleTitle =>
      'Partilhar perfis aprendidos do veículo';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Carregar referências de consumo por veículo para que um segundo dispositivo as possa reutilizar.';

  @override
  String get obd2StatusConnected => 'Adaptador OBD2: ligado';

  @override
  String get obd2StatusAttempting => 'Adaptador OBD2: a ligar';

  @override
  String get obd2StatusUnreachable => 'Adaptador OBD2: inacessível';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptador OBD2: permissão de Bluetooth necessária';

  @override
  String get obd2StatusConnectedBody => 'Pronto para gravar uma viagem.';

  @override
  String get obd2StatusAttemptingBody => 'A ligar em segundo plano…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adaptador fora de alcance ou já em uso por outra aplicação.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Conceda permissão de Bluetooth nas definições do sistema para ligar automaticamente.';

  @override
  String get obd2StatusNoAdapter => 'Nenhum adaptador emparelhado';

  @override
  String get obd2StatusForget => 'Esquecer adaptador';

  @override
  String get tripHistoryTitle => 'Histórico de viagens';

  @override
  String get tripHistoryEmptyTitle => 'Sem viagens';

  @override
  String get tripHistoryEmptySubtitle =>
      'Ligue um adaptador OBD2 e grave uma viagem para começar a construir o seu histórico de condução.';

  @override
  String get tripHistoryUnknownDate => 'Data desconhecida';

  @override
  String get situationIdle => 'Em marcha lenta';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urbano';

  @override
  String get situationHighway => 'Autoestrada';

  @override
  String get situationDecel => 'A desacelerar';

  @override
  String get situationClimbing => 'Subida / carregado';

  @override
  String get situationColdStart => 'Cold start';

  @override
  String get situationSustainedLoad => 'Sustained load / towing';

  @override
  String get situationPartialDecel => 'Coasting';

  @override
  String get situationHardAccel => 'Aceleração brusca';

  @override
  String get situationFuelCut => 'Corte de combustível — deslizar';

  @override
  String get tripSaveAsFillUp => 'Guardar como abastecimento';

  @override
  String get tripSaveRecording => 'Guardar viagem';

  @override
  String get tripDiscard => 'Descartar';

  @override
  String obdOdometerRead(int km) {
    return 'Odómetro lido: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Não definido';

  @override
  String get wizardVehicleTapToEdit => 'Toque para editar';

  @override
  String get wizardVehicleDefaultBadge => 'Predefinição';

  @override
  String get wizardProfileChoiceHint =>
      'Escolha como pretende utilizar a aplicação. Pode alterar mais tarde nas Definições.';

  @override
  String get wizardProfileChoiceFooter =>
      'Pode alterar a sua escolha a qualquer momento em Definições → Modo de uso.';

  @override
  String get wizardProfileBasicName => 'Básico';

  @override
  String get wizardProfileBasicDescription =>
      'Combustível mais barato e preços de carregamento EV nas proximidades. Favoritos e alertas de preços.';

  @override
  String get wizardProfileMediumName => 'Médio';

  @override
  String get wizardProfileMediumDescription =>
      'Tudo no Básico, mais o registo manual de abastecimentos e carregamentos EV.';

  @override
  String get wizardProfileFullName => 'Completo';

  @override
  String get wizardProfileFullDescription =>
      'Tudo no Médio, mais gravação automática de viagens OBD2, pontuações de condução e cartões de fidelidade.';

  @override
  String get wizardProfileCustomName => 'Personalizado';

  @override
  String get wizardProfileCustomDescription =>
      'A sua combinação de funcionalidades. Ajuste cada opção abaixo.';

  @override
  String get useModeSectionHint =>
      'Adapte a aplicação à forma como a utiliza. Escolher um preset ativa o conjunto correspondente de funcionalidades.';

  @override
  String get useModeCustomSettingsDescription =>
      'A sua combinação de funcionalidades não corresponde a nenhum preset. Escolha um acima para substituir, ou continue a personalizar as funcionalidades individualmente na secção abaixo.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Modo de uso definido para $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Veículo predefinido (opcional)';

  @override
  String get profileDefaultVehicleNone => 'Sem predefinição';

  @override
  String get profileFuelFromVehicleHint =>
      'O tipo de combustível é derivado do seu veículo predefinido. Limpe o veículo para escolher um combustível diretamente.';

  @override
  String get consumptionNoVehicleTitle => 'Adicione primeiro um veículo';

  @override
  String get consumptionNoVehicleBody =>
      'Os abastecimentos são atribuídos a um veículo. Adicione o seu carro para começar a registar o consumo.';

  @override
  String get vehicleAdd => 'Adicionar veículo';

  @override
  String get vehicleAddTitle => 'Adicionar veículo';

  @override
  String get vehicleEditTitle => 'Editar veículo';

  @override
  String get vehicleDeleteTitle => 'Eliminar veículo?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Remover \"$name\" dos seus perfis?';
  }

  @override
  String get vehicleNameLabel => 'Nome';

  @override
  String get vehicleNameHint => 'ex.: O meu Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustão';

  @override
  String get vehicleTypeHybrid => 'Híbrido';

  @override
  String get vehicleTypeEv => 'Elétrico';

  @override
  String get vehicleEvSectionTitle => 'Elétrico';

  @override
  String get vehicleCombustionSectionTitle => 'Combustão';

  @override
  String get vehicleBatteryLabel => 'Capacidade da bateria (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Potência máxima de carregamento (kW)';

  @override
  String get vehicleConnectorsLabel => 'Conectores suportados';

  @override
  String get vehicleMinSocLabel => 'SoC mín. %';

  @override
  String get vehicleMaxSocLabel => 'SoC máx. %';

  @override
  String get vehicleTankLabel => 'Capacidade do depósito (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Combustível preferido';

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
  String get connectorThreePin => '3 pinos';

  @override
  String get evShowOnMap => 'Mostrar postos EV';

  @override
  String get evAvailableOnly => 'Apenas disponíveis';

  @override
  String get evMinPower => 'Potência mín.';

  @override
  String get evMaxPower => 'Potência máx.';

  @override
  String get evOperator => 'Operador';

  @override
  String get evLastUpdate => 'Última atualização';

  @override
  String get evStatusAvailable => 'Disponível';

  @override
  String get evStatusOccupied => 'Ocupado';

  @override
  String get evStatusOutOfOrder => 'Avariado';

  @override
  String get evStatusPartial => 'Partly available';

  @override
  String get openOnlyFilter => 'Apenas abertos';

  @override
  String get saveAsDefaults => 'Guardar como predefinições';

  @override
  String get criteriaSavedToProfile => 'Guardado como predefinições';

  @override
  String get profileNotFound => 'Sem perfil ativo';

  @override
  String get updatingFavorites => 'A atualizar os seus favoritos...';

  @override
  String get fetchingLatestPrices => 'A obter os preços mais recentes';

  @override
  String get noDataAvailable => 'Sem dados';

  @override
  String get configAndPrivacy => 'Configuração e privacidade';

  @override
  String get searchToSeeMap => 'Pesquise para ver postos no mapa';

  @override
  String get evPowerAny => 'Qualquer';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Perfil';

  @override
  String get sectionLocation => 'Localização';

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
  String get tooltipBack => 'Voltar';

  @override
  String get tooltipClose => 'Fechar';

  @override
  String get tooltipShare => 'Partilhar';

  @override
  String get tooltipClearSearch => 'Limpar pesquisa';

  @override
  String get minimalDriveInstantConsumption => 'Consumo instantâneo';

  @override
  String get coachingShiftUp => 'Subir mudança';

  @override
  String get coachingShiftDown => 'Descer mudança';

  @override
  String get coachingEasePedal => 'Alivia o acelerador';

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
  String get tooltipUseGps => 'Usar localização GPS';

  @override
  String get tooltipShowPassword => 'Mostrar palavra-passe';

  @override
  String get tooltipHidePassword => 'Ocultar palavra-passe';

  @override
  String get evConnectorsLabel => 'Conectores disponíveis';

  @override
  String get evConnectorsNone => 'Sem informação de conectores';

  @override
  String get switchToEmail => 'Mudar para e-mail';

  @override
  String get switchToEmailSubtitle =>
      'Manter dados, adicionar acesso de outros dispositivos';

  @override
  String get switchToAnonymousAction => 'Mudar para anónimo';

  @override
  String get switchToAnonymousSubtitle =>
      'Manter dados locais, usar nova sessão anónima';

  @override
  String get linkDevice => 'Ligar dispositivo';

  @override
  String get shareDatabase => 'Partilhar base de dados';

  @override
  String get disconnectAction => 'Desligar';

  @override
  String get disconnectSubtitle =>
      'Parar sincronização (dados locais preservados)';

  @override
  String get deleteAccountAction => 'Eliminar conta';

  @override
  String get deleteAccountSubtitle =>
      'Remover todos os dados do servidor permanentemente';

  @override
  String get localOnly => 'Apenas local';

  @override
  String get localOnlySubtitle =>
      'Opcional: sincronizar favoritos, alertas e avaliações entre dispositivos';

  @override
  String get setupCloudSync => 'Configurar sincronização na nuvem';

  @override
  String get disconnectTitle => 'Desligar TankSync?';

  @override
  String get disconnectBody =>
      'A sincronização na nuvem será desativada. Os seus dados locais (favoritos, alertas, histórico) são preservados neste dispositivo. Os dados no servidor não são eliminados.';

  @override
  String get deleteAccountTitle => 'Eliminar conta?';

  @override
  String get deleteAccountBody =>
      'Isto elimina permanentemente todos os seus dados do servidor (favoritos, alertas, avaliações, rotas). Os dados locais neste dispositivo são preservados.\n\nEsta ação não pode ser revertida.';

  @override
  String get switchToAnonymousTitle => 'Mudar para anónimo?';

  @override
  String get switchToAnonymousBody =>
      'A sessão da sua conta de e-mail será terminada e continuará com uma nova sessão anónima.\n\nOs seus dados locais (favoritos, alertas) são mantidos neste dispositivo e serão sincronizados com a nova conta anónima.';

  @override
  String get switchAction => 'Mudar';

  @override
  String get helpBannerCriteria =>
      'As predefinições do seu perfil estão pré-preenchidas. Ajuste os critérios abaixo para refinar a pesquisa.';

  @override
  String get helpBannerAlerts =>
      'Defina um limite de preço para um posto. Será notificado quando os preços descerem abaixo dele. As verificações são feitas a cada 30 minutos.';

  @override
  String get helpBannerConsumption =>
      'Registe cada abastecimento para acompanhar o seu consumo real e pegada de CO₂. Deslize para a esquerda para eliminar uma entrada.';

  @override
  String get helpBannerVehicles =>
      'Adicione os seus veículos para que os abastecimentos e preferências de combustível fiquem predefinidos corretamente. O primeiro veículo torna-se o predefinido.';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get onboardingPreferencesTitle => 'As suas preferências';

  @override
  String get onboardingZipHelper =>
      'Utilizado quando o GPS não está disponível';

  @override
  String get onboardingRadiusHelper => 'Raio maior = mais resultados';

  @override
  String get onboardingPrivacy =>
      'Estas definições são guardadas apenas no seu dispositivo e nunca partilhadas.';

  @override
  String get onboardingLandingTitle => 'Ecrã inicial';

  @override
  String get onboardingLandingHint =>
      'Escolha o ecrã que abre quando inicia a aplicação.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Fique fora da aplicação — mas não a feche.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Abra o Sparkilo uma vez após cada reinício.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'A Apple apenas acorda o Sparkilo depois de o ter aberto pelo menos uma vez desde que o telemóvel reiniciou. Depois disso, as suas viagens são gravadas automaticamente.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Não deslize o Sparkilo no seletor de aplicações.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      '\"Forçar fecho\" diz ao iOS para parar de relançar a aplicação. As suas viagens deixarão de ser gravadas até abrir o Sparkilo novamente.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Quando o iOS pedir localização \"Sempre\", aceite.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'A função de reserva que grava a sua viagem quando o adaptador OBD2 está lento precisa de localização em segundo plano. Nunca a partilhamos.';

  @override
  String get scanReceipt => 'Ler recibo';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Combustível';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Autoestrada';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Privado';

  @override
  String get ratingModeShared => 'Partilhado';

  @override
  String get ratingDescLocal => 'Avaliações guardadas apenas neste dispositivo';

  @override
  String get ratingDescPrivate =>
      'Sincronizadas com a sua base de dados (não visíveis para outros)';

  @override
  String get ratingDescShared =>
      'Visíveis para todos os utilizadores da sua base de dados';

  @override
  String get errorNoEvApiKey =>
      'Chave de API OpenChargeMap não configurada. Adicione uma nas Definições para pesquisar postos de carregamento EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'O fornecedor de dados ($host) está a servir um certificado TLS expirado ou inválido. A aplicação não pode carregar dados desta fonte até o fornecedor o corrigir. Contacte $host.';
  }

  @override
  String get offlineLabel => 'Sem ligação';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed indisponível. A usar $current.';
  }

  @override
  String get errorTitleApiKey => 'Chave de API necessária';

  @override
  String get errorTitleLocation => 'Localização indisponível';

  @override
  String get errorHintNoStations =>
      'Tente aumentar o raio de pesquisa ou pesquise noutra localização.';

  @override
  String get errorHintApiKey => 'Configure a sua chave de API nas Definições.';

  @override
  String get errorHintConnection =>
      'Verifique a sua ligação à Internet e tente novamente.';

  @override
  String get errorHintRouting =>
      'Falha no cálculo da rota. Verifique a sua ligação à Internet e tente novamente.';

  @override
  String get errorHintFallback =>
      'Tente novamente ou pesquise por código postal / nome de cidade.';

  @override
  String get alertsLoadErrorTitle =>
      'Não foi possível carregar os seus alertas';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Falha na verificação de alertas em segundo plano';

  @override
  String get detailsLabel => 'Detalhes';

  @override
  String get remove => 'Remover';

  @override
  String get showKey => 'Mostrar chave';

  @override
  String get hideKey => 'Ocultar chave';

  @override
  String get syncOptionalTitle => 'TankSync é opcional';

  @override
  String get syncOptionalDescription =>
      'A sua aplicação funciona totalmente sem sincronização na nuvem. O TankSync permite-lhe sincronizar favoritos, alertas e avaliações entre dispositivos usando Supabase (plano gratuito disponível).';

  @override
  String get syncHowToConnectQuestion => 'Como pretende ligar?';

  @override
  String get syncCreateOwnTitle => 'Criar a minha própria base de dados';

  @override
  String get syncCreateOwnSubtitle =>
      'Projeto Supabase gratuito — guiaremos passo a passo';

  @override
  String get syncJoinExistingTitle => 'Entrar numa base de dados existente';

  @override
  String get syncJoinExistingSubtitle =>
      'Leia o código QR do proprietário da base de dados ou cole as credenciais';

  @override
  String get syncChooseAccountType => 'Escolha o tipo de conta';

  @override
  String get syncAccountTypeAnonymous => 'Anónimo';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Imediato, sem e-mail necessário. Dados associados a este dispositivo.';

  @override
  String get syncAccountTypeEmail => 'Conta de e-mail';

  @override
  String get syncAccountTypeEmailDesc =>
      'Inicie sessão em qualquer dispositivo. Recupere os dados se perder o telemóvel.';

  @override
  String get syncHaveAccountSignIn => 'Já tem conta? Inicie sessão';

  @override
  String get syncCreateNewAccount => 'Criar nova conta';

  @override
  String get syncTestConnection => 'Testar ligação';

  @override
  String get syncTestingConnection => 'A testar...';

  @override
  String get syncConnectButton => 'Ligar';

  @override
  String get syncConnectingButton => 'A ligar...';

  @override
  String get syncDatabaseReady => 'Base de dados pronta!';

  @override
  String get syncDatabaseNeedsSetup =>
      'A base de dados precisa de configuração';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Em falta';

  @override
  String get syncSqlEditorInstructions =>
      'Copie o SQL abaixo e execute-o no Editor SQL do Supabase (Painel → SQL Editor → Nova consulta → Colar → Executar)';

  @override
  String get syncCopySqlButton => 'Copiar SQL para a área de transferência';

  @override
  String get syncRecheckSchemaButton => 'Verificar esquema novamente';

  @override
  String get syncDoneButton => 'Concluído';

  @override
  String syncSignedInAs(String email) {
    return 'Sessão iniciada como $email';
  }

  @override
  String get syncEmailDescription =>
      'Os seus dados sincronizam em todos os dispositivos com este e-mail.';

  @override
  String get syncSwitchToAnonymousTitle => 'Mudar para anónimo';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continuar sem e-mail, nova sessão anónima';

  @override
  String get syncGuestDescription => 'Anónimo, sem e-mail necessário.';

  @override
  String get syncOrDivider => 'ou';

  @override
  String get syncHowToSyncQuestion => 'Como pretende sincronizar?';

  @override
  String get syncOfflineDescription =>
      'A sua aplicação funciona totalmente sem ligação. A sincronização na nuvem é opcional.';

  @override
  String get syncModeCommunityTitle => 'Comunidade Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Partilhe favoritos e avaliações com todos os utilizadores';

  @override
  String get syncModePrivateTitle => 'Base de dados privada';

  @override
  String get syncModePrivateSubtitle =>
      'O seu próprio Supabase — controlo total dos dados';

  @override
  String get syncModeGroupTitle => 'Entrar num grupo';

  @override
  String get syncModeGroupSubtitle =>
      'Base de dados partilhada com família ou amigos';

  @override
  String get syncPrivacyShared => 'Partilhado';

  @override
  String get syncPrivacyPrivate => 'Privado';

  @override
  String get syncPrivacyGroup => 'Grupo';

  @override
  String get syncStayOfflineButton => 'Ficar offline';

  @override
  String get syncSuccessTitle => 'Ligado com sucesso!';

  @override
  String get syncSuccessDescription =>
      'Os seus dados serão agora sincronizados automaticamente.';

  @override
  String get syncWizardTitleConnect => 'Ligar TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'A sua base de dados';

  @override
  String get syncSetupTitleJoinGroup => 'Entrar num grupo';

  @override
  String get syncSetupTitleAccount => 'A sua conta';

  @override
  String get syncWizardBack => 'Voltar';

  @override
  String get syncWizardNext => 'Seguinte';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Criar um projeto Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Toque em \"Abrir Supabase\" abaixo\n2. Crie uma conta gratuita (se ainda não tiver)\n3. Clique em \"New Project\"\n4. Escolha um nome e região\n5. Aguarde ~2 minutos para iniciar';

  @override
  String get syncWizardOpenSupabase => 'Abrir Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Ativar Inícios de Sessão Anónimos';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. No painel do Supabase:\n   Authentication → Providers\n2. Encontre \"Anonymous Sign-ins\"\n3. Ative o botão\n4. Clique em \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Abrir definições de autenticação';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copie as suas credenciais';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Vá a Settings → API no painel\n2. Copie o \"Project URL\"\n3. Copie a chave \"anon public\"\n4. Cole-as abaixo';

  @override
  String get syncWizardOpenApiSettings => 'Abrir definições de API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL do Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Entrar numa base de dados existente';

  @override
  String get syncWizardScanQrCode => 'Ler código QR';

  @override
  String get syncWizardAskOwnerQr =>
      'Peça ao proprietário da base de dados que lhe mostre o código QR\n(Definições → TankSync → Partilhar)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Peça ao proprietário da base de dados que mostre o código QR';

  @override
  String get syncWizardEnterManuallyTitle => 'Introduzir manualmente';

  @override
  String get syncWizardOrEnterManually => 'ou introduzir manualmente';

  @override
  String get syncWizardUrlHelperText =>
      'Espaços e quebras de linha removidos automaticamente';

  @override
  String get syncCredentialsPrivateHint =>
      'Introduza as credenciais do seu projeto Supabase. Pode encontrá-las no painel em Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL da base de dados';

  @override
  String get syncCredentialsAccessKeyLabel => 'Chave de acesso';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Palavra-passe';

  @override
  String get authConfirmPasswordLabel => 'Confirmar palavra-passe';

  @override
  String get authPleaseEnterEmail => 'Introduza o seu e-mail';

  @override
  String get authInvalidEmail => 'Endereço de e-mail inválido';

  @override
  String get authPasswordsDoNotMatch => 'As palavras-passe não coincidem';

  @override
  String get authConnectAnonymously => 'Ligar anonimamente';

  @override
  String get authCreateAccountAndConnect => 'Criar conta e ligar';

  @override
  String get authSignInAndConnect => 'Iniciar sessão e ligar';

  @override
  String get authAnonymousSegment => 'Anónimo';

  @override
  String get authEmailSegment => 'E-mail';

  @override
  String get authAnonymousDescription =>
      'Acesso imediato, sem e-mail necessário. Dados associados a este dispositivo.';

  @override
  String get authEmailDescription =>
      'Inicie sessão em qualquer dispositivo. Recupere os seus dados se perder o telemóvel.';

  @override
  String get authSyncAcrossDevices =>
      'Sincronize os dados automaticamente em todos os seus dispositivos.';

  @override
  String get authNewHereCreateAccount => 'É novo? Crie uma conta';

  @override
  String get linkDeviceScreenTitle => 'Ligar dispositivo';

  @override
  String get linkDeviceThisDeviceLabel => 'Este dispositivo';

  @override
  String get linkDeviceShareCodeHint =>
      'Partilhe este código com o seu outro dispositivo:';

  @override
  String get linkDeviceNotConnected => 'Não ligado';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copiar código';

  @override
  String get linkDeviceImportSectionTitle => 'Importar de outro dispositivo';

  @override
  String get linkDeviceImportDescription =>
      'Introduza o código do dispositivo do seu outro dispositivo para importar os seus favoritos, alertas, veículos e registo de consumo. Cada dispositivo mantém o seu próprio perfil e predefinições.';

  @override
  String get linkDeviceCodeFieldLabel => 'Código do dispositivo';

  @override
  String get linkDeviceCodeFieldHint => 'Cole o UUID do outro dispositivo';

  @override
  String get linkDeviceImportButton => 'Importar dados';

  @override
  String get linkDeviceHowItWorksTitle => 'Como funciona';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. No Dispositivo A: copie o código do dispositivo acima\n2. No Dispositivo B: cole-o no campo \"Código do dispositivo\"\n3. Toque em \"Importar dados\" para juntar favoritos, alertas, veículos e registos de consumo\n4. Ambos os dispositivos terão todos os dados combinados\n\nCada dispositivo mantém a sua identidade anónima e o seu próprio perfil (combustível preferido, veículo predefinido, ecrã inicial). Os dados são fundidos, não transferidos.';

  @override
  String get vehicleSetActive => 'Definir como ativo';

  @override
  String get swipeHide => 'Ocultar';

  @override
  String get evChargingSection => 'Carregamento EV';

  @override
  String get fuelStationsSection => 'Postos de combustível';

  @override
  String get yourRating => 'A sua avaliação';

  @override
  String get noStorageUsed => 'Sem armazenamento utilizado';

  @override
  String get aboutReportBug => 'Reportar um erro / Sugerir uma funcionalidade';

  @override
  String get aboutSupportProject => 'Apoiar este projeto';

  @override
  String get aboutSupportDescription =>
      'Esta aplicação é gratuita, de código aberto e sem anúncios. Se a achar útil, considere apoiar o programador.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Os preços de combustível no Luxemburgo são regulados pelo governo e uniformes em todo o país.';

  @override
  String get luxembourgFuelUnleaded95 => 'Gasolina sem chumbo 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Gasolina sem chumbo 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'GPL';

  @override
  String get luxembourgPricesUnavailable =>
      'Os preços regulados do Luxemburgo estão indisponíveis.';

  @override
  String get reportIssueTitle => 'Reportar um problema';

  @override
  String get enterCorrection => 'Introduza a correção';

  @override
  String get reportNoBackendAvailable =>
      'O relatório não pôde ser enviado: nenhum serviço de reporte está configurado para este país. Ative o TankSync nas Definições para enviar relatórios comunitários.';

  @override
  String get correctName => 'Nome correto do posto';

  @override
  String get correctAddress => 'Endereço correto';

  @override
  String get wrongE85Price => 'Preço E85 errado';

  @override
  String get wrongE98Price => 'Preço Super 98 errado';

  @override
  String get wrongLpgPrice => 'Preço GPL errado';

  @override
  String get wrongStationName => 'Nome do posto errado';

  @override
  String get wrongStationAddress => 'Endereço errado';

  @override
  String get independentStation => 'Posto independente';

  @override
  String get serviceRemindersSection => 'Lembretes de manutenção';

  @override
  String get serviceRemindersEmpty =>
      'Sem lembretes ainda — escolha um preset acima.';

  @override
  String get addServiceReminder => 'Adicionar lembrete';

  @override
  String get serviceReminderPresetOil => 'Óleo (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Mudança de óleo';

  @override
  String get serviceReminderPresetTires => 'Pneus (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Pneus';

  @override
  String get serviceReminderPresetInspection => 'Inspeção (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Inspeção';

  @override
  String get serviceReminderLabel => 'Etiqueta';

  @override
  String get serviceReminderInterval => 'Intervalo (km)';

  @override
  String get serviceReminderLastService => 'Última manutenção';

  @override
  String get serviceReminderMarkDone => 'Marcar como feito';

  @override
  String get serviceReminderDueTitle => 'Manutenção prevista';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label está prevista — $kmOver km após o intervalo.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Registe-se no OPINET para obter uma chave de API gratuita';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired =>
      'Registe-se no CNE para obter uma chave de API gratuita';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'É este o seu carro?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders cilindros, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Informação parcial (offline). Pode editar abaixo.';

  @override
  String get vinDecodeError => 'Não foi possível descodificar este VIN';

  @override
  String get vinInvalidFormat => 'Formato de VIN inválido';

  @override
  String get obd2PauseBannerTitle => 'Ligação OBD2 perdida — gravação pausada';

  @override
  String get obd2PauseBannerResume => 'Retomar gravação';

  @override
  String get obd2PauseBannerEnd => 'Terminar gravação';

  @override
  String get obd2GpsDegradedBannerTitle =>
      'Recording with GPS — OBD2 reconnecting';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Calibração de consumo atualizada para $vehicleName — precisão melhorada em $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Repor eficiência volumétrica?';

  @override
  String get veResetConfirmBody =>
      'Isto irá descartar a eficiência volumétrica aprendida (η_v) e restaurar o valor predefinido (0,85). As estimativas de caudal de combustível por viagem voltarão à constante do fabricante até o calibrador recolher novas amostras de próximas viagens.';

  @override
  String get alertsRadiusSectionTitle => 'Alertas de raio';

  @override
  String get alertsRadiusAdd => 'Adicionar alerta de raio';

  @override
  String get alertsRadiusEmptyTitle => 'Sem alertas de raio ainda';

  @override
  String get alertsRadiusEmptyCta => 'Criar um alerta de raio';

  @override
  String get alertsRadiusCreateTitle => 'Criar alerta de raio';

  @override
  String get alertsRadiusLabelHint => 'Etiqueta (ex.: Diesel em casa)';

  @override
  String get alertsRadiusFuelType => 'Tipo de combustível';

  @override
  String get alertsRadiusThreshold => 'Limite (€/L)';

  @override
  String get alertsRadiusKm => 'Raio (km)';

  @override
  String get alertsRadiusCenterGps => 'Usar a minha localização';

  @override
  String get alertsRadiusCenterPostalCode => 'Código postal';

  @override
  String get alertsRadiusSave => 'Guardar';

  @override
  String get alertsRadiusCancel => 'Cancelar';

  @override
  String get alertsRadiusDeleteConfirm => 'Eliminar alerta de raio?';

  @override
  String radiusAlertDeleted(String name) {
    return 'Radius alert \"$name\" deleted';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 ligado: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Emparelhar um adaptador OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel desceu em postos próximos';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount postos desceram até $maxDropCents¢ na última hora';
  }

  @override
  String get fillUpSavedSnackbar => 'Abastecimento guardado';

  @override
  String get radiusAlertsEntryTitle => 'Alertas de raio e estatísticas';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Seja notificado quando os preços descerem perto de si';

  @override
  String get notFoundTitle => 'Página não encontrada';

  @override
  String notFoundBody(String location) {
    return '\"$location\" não encontrado.';
  }

  @override
  String get notFoundHomeButton => 'Início';

  @override
  String get consumptionTabHiddenNotice =>
      'O separador Consumo está oculto pelas definições do seu perfil.';

  @override
  String get swipeBetweenTabsHint =>
      'Dica: deslize para a esquerda ou direita para mudar de separador.';

  @override
  String get discardChangesTitle => 'Descartar alterações?';

  @override
  String get discardChangesBody =>
      'Tem alterações não guardadas. Sair agora irá descartá-las.';

  @override
  String get discardChangesConfirm => 'Descartar';

  @override
  String get discardChangesKeepEditing => 'Continuar a editar';

  @override
  String get tankSyncSectionSubtitle =>
      'Sincronização na nuvem entre os seus dispositivos';

  @override
  String get mapUnavailable => 'Mapa indisponível';

  @override
  String get routeNameHintExample => 'ex.: Paris → Lyon';

  @override
  String get priceStatsCurrent => 'Atual';

  @override
  String get tankerkoenigApiKeyLabel => 'Chave de API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Chave de API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Toque para atualizar a posição de GPS';

  @override
  String get nameLabel => 'Nome';

  @override
  String get obd2ErrorPermissionDenied =>
      'É necessária permissão de Bluetooth para ligar a um adaptador OBD2.';

  @override
  String get obd2ErrorBluetoothOff => 'Ative o Bluetooth e tente novamente.';

  @override
  String get obd2ErrorScanTimeout =>
      'Nenhum adaptador OBD2 encontrado por perto. Verifique se está ligado e com energia.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'O adaptador OBD2 não respondeu. Ligue a ignição e tente novamente.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'O adaptador OBD2 enviou uma resposta não reconhecida. Pode ser incompatível — experimente outro adaptador.';

  @override
  String get obd2ErrorDisconnected =>
      'O adaptador OBD2 desligou-se. Volte a ligar e tente novamente.';

  @override
  String get onboardingExploreDemoData => 'Explorar com dados de demonstração';

  @override
  String get achievementSmoothDriver => 'Sequência suave';

  @override
  String get achievementSmoothDriverDesc =>
      'Conduza 5 viagens seguidas com uma pontuação de condução suave de 80 ou superior.';

  @override
  String get achievementColdStartAware => 'Consciente do arranque a frio';

  @override
  String get achievementColdStartAwareDesc =>
      'Mantenha o custo de combustível de arranque a frio de um mês inteiro abaixo de 2% do total — combine viagens curtas.';

  @override
  String get achievementHighwayMaster => 'Mestre da autoestrada';

  @override
  String get achievementHighwayMasterDesc =>
      'Complete uma viagem de 30 km+ a velocidade constante com uma pontuação de condução suave de 90 ou superior.';

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
    return '$fuelLabel desceu em postos próximos';
  }

  @override
  String velocityAlertNotificationBody(String count, String cents) {
    return '$count postos desceram até $cents¢ na última hora';
  }

  @override
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  ) {
    return '$label: $count postos ≤ $threshold $currency';
  }

  @override
  String radiusAlertGroupedMore(String count) {
    return '+ $count mais';
  }

  @override
  String get alertGatingNonDeStationWarning =>
      'Os alertas de preço em segundo plano atualmente só funcionam para postos na Alemanha. Este alerta será guardado, mas poderá nunca o notificar até que cheguem os alertas entre países.';

  @override
  String get alertGatingRadiusGermanyOnlyNote =>
      'Os alertas por raio atualmente só verificam postos na Alemanha.';

  @override
  String get approachOverlaySection => 'Overlay ao aproximar-se de um posto';

  @override
  String get approachRadiusLabel => 'Raio';

  @override
  String approachRadiusCaption(String km) {
    return 'O overlay aumenta e mostra o preço quando estás a menos de $km km de um posto';
  }

  @override
  String get approachPriceModeLabel => 'Mostrar preço de';

  @override
  String get approachPriceModeNearest => 'Posto mais próximo';

  @override
  String get approachPriceModeCheapestInRadius => 'Mais barato no raio';

  @override
  String get approachMinPollLabel => 'Atualização mín.';

  @override
  String approachMinPollCaption(int seconds) {
    return 'Limite mínimo de atualização do posto mais próximo (mais rápido em velocidade, nunca menos de $seconds s)';
  }

  @override
  String get approachTestSimulateButton => 'Testar sobreposição de aproximação';

  @override
  String get approachTestStopButton => 'Parar teste';

  @override
  String approachTestActiveCaption(String station) {
    return 'Teste ativo — sobreposição mostra o preço de $station';
  }

  @override
  String get approachTestUnavailable =>
      'Adicione um posto favorito para testar a sobreposição de aproximação';

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
  String get authErrorNoNetwork =>
      'Sem ligação à rede. Tente novamente mais tarde.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail ou palavra-passe inválidos. Verifique as suas credenciais.';

  @override
  String get authErrorUserAlreadyExists =>
      'Este e-mail já está registado. Tente iniciar sessão.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Verifique o seu e-mail e confirme a sua conta primeiro.';

  @override
  String get authErrorGeneric => 'Falha no início de sessão. Tente novamente.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Localização em segundo plano — apenas para gravação automática';

  @override
  String get autoRecordConsentExplanationTitle => 'Sobre esta permissão';

  @override
  String get autoRecordConsentExplanationBody =>
      'A gravação automática precisa de localização em segundo plano para detetar quando começa a conduzir com a aplicação fechada. Esta permissão é usada apenas pela gravação automática — a pesquisa de postos e o centramento do mapa usam uma permissão de localização em primeiro plano separada.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Percebido';

  @override
  String get autoRecordConsentExplanationTooltip => 'O que significa isto?';

  @override
  String get autoRecordConsentRevokeAction =>
      'Toque para gerir nas definições do sistema';

  @override
  String get autoRecordSectionTitle => 'Gravação automática';

  @override
  String get autoRecordToggleLabel => 'Gravar viagens automaticamente';

  @override
  String get autoRecordStatusActiveLabel =>
      'A gravação automática será ativada da próxima vez que entrar no carro.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Emparelhe um adaptador OBD2 para ativar a gravação automática.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Permita a localização em segundo plano para que a gravação automática continue com o ecrã desligado.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Emparelhar um adaptador';

  @override
  String get autoRecordSpeedThresholdLabel => 'Velocidade de início (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Atraso para guardar após desligar (segundos)';

  @override
  String get autoRecordPairedAdapterLabel => 'Adaptador emparelhado';

  @override
  String get autoRecordPairedAdapterNone =>
      'Nenhum adaptador emparelhado. Emparelhe um primeiro através do OBD2 no onboarding.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Localização em segundo plano permitida';

  @override
  String get autoRecordBackgroundLocationRequest => 'Solicitar permissão';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Porquê \"Permitir sempre\"?';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'A gravação automática transmite coordenadas GPS do serviço em primeiro plano OBD-II com o ecrã desligado para que a rota da viagem se mantenha precisa. O Android requer a opção \"Permitir sempre\" para que isso continue a funcionar após o dispositivo bloquear.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Abrir definições';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Permissão de localização necessária';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Não foi possível solicitar localização em segundo plano';

  @override
  String get autoRecordBadgeClearTooltip => 'Limpar contador';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Emparelhe um adaptador na secção abaixo para ativar a gravação automática';

  @override
  String get exportBackupTooltip => 'Exportar cópia de segurança';

  @override
  String get exportBackupReady =>
      'Cópia de segurança pronta — escolha um destino';

  @override
  String get exportBackupFailed =>
      'Falha na exportação da cópia de segurança — tente novamente';

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
  String get brokenMapChipVerifying => 'A verificar sensor MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Leituras MAP suspeitas';

  @override
  String get brokenMapSnackbarUnreliable =>
      'O sensor MAP lê incorretamente — as leituras de combustível podem estar 50–80% abaixo do real. Tente um adaptador diferente.';

  @override
  String get brokenMapBannerHardDisable =>
      'Sensor MAP não fiável. A mostrar médias de abastecimento em vez de caudal em tempo real.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Sensor MAP: verificado ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Sensor MAP: a verificar ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Sensor MAP: suspeito ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Sensor MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Sensor MAP: $posterior% ± $margin% (verificado)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Diagnóstico do sensor MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Confiança em MAP avariado: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count observações registadas';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Verificado como correto';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'O sensor MAP deste veículo ainda não foi observado.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Adaptadores em lista de bloqueio';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Nenhum adaptador está em lista de bloqueio.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — sinalizado $percent% avariado';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Limpar';

  @override
  String get brokenMapRevPromptTitle => 'Acelere o motor';

  @override
  String get brokenMapRevPromptBody =>
      'Pise brevemente o acelerador para que a aplicação possa verificar se o sensor MAP responde.';

  @override
  String get brokenMapRevPromptConfirm => 'Feito — aceleei';

  @override
  String get calibrationAdvancedTitle => 'Calibração avançada';

  @override
  String get calibrationDisplacementLabel => 'Cilindrada do motor (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Eficiência volumétrica (η_v)';

  @override
  String get calibrationAfrLabel => 'Relação ar/combustível (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Densidade do combustível (g/L)';

  @override
  String get calibrationSourceDetected => '(detetado do VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(catálogo: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(predefinição)';

  @override
  String get calibrationSourceManual => '(manual)';

  @override
  String get calibrationResetToDetected => 'Repor para valor detetado';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (calibrado, $samples amostras)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (a aprender, $samples amostras)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0,85 (predefinição — ainda sem tanque cheio)';

  @override
  String calibrationLearnerEtaCompact(String eta, int samples) {
    return 'η_v: $eta · $samples amostras';
  }

  @override
  String get calibrationResetLearner => 'Repor calibração';

  @override
  String get calibrationBasisAtkinson => 'Ciclo Atkinson';

  @override
  String get calibrationBasisVnt => 'Diesel VNT + DI';

  @override
  String get calibrationBasisTurboDi => 'Turbo + DI';

  @override
  String get calibrationBasisTurbo => 'Turbinado';

  @override
  String get calibrationBasisNaDi => 'Aspiração natural + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(catálogo: $makeModel — predefinição $basis)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'O seu $makeModel está marcado como diesel mas corresponde a uma entrada de catálogo de gasolina. Toque para atualizar.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Atualizar';

  @override
  String get consumptionTabFuel => 'Combustível';

  @override
  String get consumptionTabCharging => 'Carregamento';

  @override
  String get noChargingLogsTitle => 'Sem registos de carregamento';

  @override
  String get noChargingLogsSubtitle =>
      'Registe a sua primeira sessão de carregamento para começar a acompanhar EUR/100 km e kWh/100 km.';

  @override
  String get addChargingLog => 'Registar carregamento';

  @override
  String get addChargingLogTitle => 'Registar sessão de carregamento';

  @override
  String get chargingKwh => 'Energia (kWh)';

  @override
  String get chargingCost => 'Custo total';

  @override
  String get chargingTimeMin => 'Tempo de carregamento (min)';

  @override
  String get chargingStationName => 'Posto (opcional)';

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
      'É necessário um registo anterior para comparar';

  @override
  String get chargingLogButtonLabel => 'Registar carregamento';

  @override
  String get chargingCostTrendTitle => 'Tendência de custos de carregamento';

  @override
  String get chargingEfficiencyTitle => 'Eficiência (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Ainda não há dados suficientes';

  @override
  String get chargingChartsMonthAxis => 'Mês';

  @override
  String get consoFeatureGroupTitle => 'Conso';

  @override
  String get consoFeatureGroupDescription =>
      'Acompanhe o seu consumo — abastecimentos manuais ou gravação automática de viagens OBD2.';

  @override
  String get consoModeOff => 'Desligado';

  @override
  String get consoModeFuel => 'Combustível';

  @override
  String get consoModeFuelAndTrips => 'Combustível + Viagens';

  @override
  String get consoModeOffDescription =>
      'Sem separador Conso nem secção de definições Conso.';

  @override
  String get consoModeFuelDescription =>
      'Apenas abastecimentos manuais. Útil sem adaptador OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Adiciona gravação automática de viagens OBD2. Requer adaptador emparelhado.';

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
    return 'Precisão: $level · $band';
  }

  @override
  String get consumptionAccuracyHigh => 'Alta';

  @override
  String get consumptionAccuracyMedium => 'Média';

  @override
  String get consumptionAccuracyLow => 'Baixa';

  @override
  String get consumptionAccuracyTooltipHigh =>
      'Calibração completa: abastecimentos mais viagens registadas com OBD2. O valor de L/100 km acompanha a realidade dentro de alguns pontos percentuais.';

  @override
  String get consumptionAccuracyTooltipMedium =>
      'Os abastecimentos ancoraram o modelo de consumo, mas ainda nenhuma viagem OBD2 foi processada. Registe uma com OBD2 ligado para atingir a precisão alta.';

  @override
  String get consumptionAccuracyTooltipLow =>
      'Apenas GPS — nenhum abastecimento ancorou ainda o modelo de consumo. Adicione alguns abastecimentos completos para melhorar a precisão.';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count abastecimentos parciais pendentes de tanque cheio — não incluídos na média',
      one:
          '1 abastecimento parcial pendente de tanque cheio — não incluído na média',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% de combustível de correções automáticas — reveja as entradas';
  }

  @override
  String statCorrectionLiters(String liters) {
    return 'Corrections: +$liters L';
  }

  @override
  String get fillUpCorrectionLabel => 'Correção automática — toque para editar';

  @override
  String get fillUpCorrectionEditTitle => 'Editar correção automática';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Esta entrada foi gerada automaticamente para fechar a diferença entre viagens gravadas e combustível abastecido. Ajuste os valores se conhecer as cifras reais.';

  @override
  String get fillUpCorrectionDelete => 'Eliminar correção';

  @override
  String get fillUpCorrectionStation => 'Nome do posto (opcional)';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Grécia)';

  @override
  String get greeceCommunityApiNotice =>
      'Com tecnologia da API fuelpricesgr mantida pela comunidade';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Roménia)';

  @override
  String get romaniaScrapingNotice =>
      'Com tecnologia de pretcarburant.ro (Conselho de Concorrência + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Postos em $country a $km km — €$price/L mais barato';
  }

  @override
  String get crossBorderTapToSwitch => 'Toque para mudar de país';

  @override
  String get crossBorderDismissTooltip => 'Ignorar';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Open the $source data source ($license) in your browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© $brand contributors';
  }

  @override
  String get developerToolsSectionTitle => 'Ferramentas de programador';

  @override
  String get developerToolsSubtitle =>
      'Diagnósticos e ferramentas de depuração — visíveis apenas no modo programador / depuração.';

  @override
  String get developerToolsMenuSubtitle =>
      'Registo de erros, alertas de teste, diagnósticos';

  @override
  String get developerToolsErrorLogGroupTitle => 'Registo de erros';

  @override
  String developerToolsExportErrorLog(int count) {
    return 'Guardar registo de erros ($count)';
  }

  @override
  String get developerToolsClearErrorLog => 'Limpar registo de erros';

  @override
  String get developerToolsViewErrorLog => 'Ver registo de erros';

  @override
  String get developerToolsErrorLogEmpty => 'Nenhum rasto de erro registado.';

  @override
  String get developerToolsAlertsGroupTitle => 'Alertas e notificações';

  @override
  String get developerToolsFireTestNotification =>
      'Enviar notificação de teste';

  @override
  String get developerToolsTestNotificationTitle => 'Notificação de teste';

  @override
  String get developerToolsTestNotificationBody =>
      'Se consegue ler isto, as notificações estão a funcionar.';

  @override
  String get developerToolsTestNotificationSent =>
      'Notificação de teste enviada.';

  @override
  String get developerToolsTestNotificationBlocked =>
      'As notificações estão bloqueadas — ative-as nas definições do sistema e tente novamente.';

  @override
  String get developerToolsRunTestAlert =>
      'Executar pipeline de alerta de teste';

  @override
  String developerToolsTestAlertFired(int count) {
    return 'Alerta de teste acionado — o pipeline entregou $count notificação(ões).';
  }

  @override
  String get developerToolsTestAlertTitle => 'Alerta de preço de teste';

  @override
  String developerToolsTestAlertBody(String station) {
    return 'Correspondência sintética: foi encontrada nas proximidades uma estação abaixo do seu objetivo.';
  }

  @override
  String get developerToolsTestAlertNoStation =>
      'Search for stations first, then run the test alert so the notification can open a real station.';

  @override
  String get developerToolsDiagnosticsGroupTitle => 'Diagnósticos';

  @override
  String get developerToolsFeatureFlagDump =>
      'Inspetor de sinalizadores de funcionalidades';

  @override
  String get developerToolsFlagOn => 'Ativado';

  @override
  String get developerToolsFlagOff => 'Desativado';

  @override
  String get developerToolsClearCaches => 'Limpar caches';

  @override
  String get developerToolsCachesCleared => 'Caches limpas.';

  @override
  String get developerToolsCopyDiagnostics => 'Copiar diagnósticos';

  @override
  String get developerToolsDiagnosticsCopied =>
      'Diagnósticos copiados para a área de transferência.';

  @override
  String get developerToolsBuildInfoGroupTitle => 'Informação da compilação';

  @override
  String get developerToolsBuildVersion => 'Versão da aplicação';

  @override
  String get developerToolsBuildChannel => 'Canal de compilação';

  @override
  String get insightCardTitle => 'Comportamentos mais desperdiçadores';

  @override
  String get insightEmptyState =>
      'Sem ineficiências notáveis — continue assim!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Motor acima de 3000 RPM ($pctTime% da viagem): desperdiçou $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count acelerações bruscas: desperdiçou $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Marcha lenta ($pctTime% da viagem): desperdiçou $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% da viagem';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'A forçar numa mudança baixa ($minutes min)';
  }

  @override
  String get lessonAdviceIdling =>
      'Desligue o motor em paragens longas em vez de o deixar ao ralenti.';

  @override
  String get lessonAdviceHighRpm =>
      'Mude de mudança mais cedo para manter o motor fora da faixa de rotações altas.';

  @override
  String get lessonAdviceHardAccel =>
      'Acelere suavemente — uma aceleração gradual gasta menos combustível.';

  @override
  String get lessonAdviceLowGear =>
      'Suba de mudança mais cedo para que o motor fique em rotações mais baixas e económicas.';

  @override
  String insightHighSpeedBand(String pctTime, String liters) {
    return 'Velocidade alta prolongada ($pctTime% da viagem): desperdiçados $liters L';
  }

  @override
  String insightHighSpeedBandNoFuel(String pctTime) {
    return 'Velocidade alta prolongada ($pctTime% da viagem)';
  }

  @override
  String get lessonAdviceHighSpeedBand =>
      'Acima de 110 km/h alivie o acelerador – a resistência do ar sobe muito, ir um pouco mais devagar poupa bastante combustível.';

  @override
  String get lessonSmoothDrivingTitle => 'Condução suave – bom trabalho!';

  @override
  String get lessonAdviceSmoothDriving =>
      'Sem acelerações ou travagens bruscas nesta viagem – uma condução constante mantém o consumo baixo.';

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
  String get drivingScoreCardTitle => 'Pontuação de condução';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Pontuação composta de marcha lenta, acelerações bruscas, travagens bruscas e tempo em RPM alto. Uma comparação \'melhor do que X% das viagens anteriores\' será incluída numa versão futura.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Pontuação de condução $score de 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Marcha lenta';

  @override
  String get drivingScorePenaltyHardAccel => 'Acelerações bruscas';

  @override
  String get drivingScorePenaltyHardBrake => 'Travagens bruscas';

  @override
  String get drivingScorePenaltyHighRpm => 'RPM alto';

  @override
  String get drivingScorePenaltyFullThrottle => 'Acelerador a fundo';

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
  String get ecoRouteOption => 'Eco';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L poupados';
  }

  @override
  String get ecoRouteHint =>
      'Condução mais inteligente — favorece autoestrada estável em detrimento de atalhos em ziguezague.';

  @override
  String get favoritesShareAction => 'Partilhar';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — favoritos a $date';
  }

  @override
  String get favoritesShareError =>
      'Não foi possível gerar imagem para partilha';

  @override
  String get featureManagementSectionTitle => 'Gestão de funcionalidades';

  @override
  String get featureManagementSectionSubtitle =>
      'Ative ou desative funcionalidades individualmente. Algumas funcionalidades dependem de outras — os botões ficam desativados até os pré-requisitos serem cumpridos.';

  @override
  String get featureLabel_obd2TripRecording => 'Gravação de viagens OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Capturar viagens automaticamente via OBD2.';

  @override
  String get featureLabel_gamification => 'Gamificação';

  @override
  String get featureDescription_gamification =>
      'Pontuações de condução e conquistas.';

  @override
  String get featureLabel_hapticEcoCoach => 'Eco-coach háptico';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Feedback háptico em tempo real durante uma viagem.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Sincronização entre dispositivos via Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Análise de consumo';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Separador de análise de abastecimentos e viagens.';

  @override
  String get featureLabel_baselineSync => 'Sincronização de referências';

  @override
  String get featureDescription_baselineSync =>
      'Sincronizar referências de condução via TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Resultados de pesquisa unificados';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Lista de resultados única combinando postos de combustível e EV.';

  @override
  String get featureLabel_priceAlerts => 'Alertas de preços';

  @override
  String get featureDescription_priceAlerts =>
      'Notificações de descida de preço baseadas em limites.';

  @override
  String get featureLabel_priceHistory => 'Histórico de preços';

  @override
  String get featureDescription_priceHistory =>
      'Gráficos de preços dos últimos 30 dias nos detalhes do posto.';

  @override
  String get featureLabel_routePlanning => 'Planeamento de rotas';

  @override
  String get featureDescription_routePlanning =>
      'Paragem mais barata ao longo da sua rota.';

  @override
  String get featureLabel_evCharging => 'Carregamento EV';

  @override
  String get featureDescription_evCharging =>
      'Postos de carregamento via OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Glide-coach';

  @override
  String get featureDescription_glideCoach =>
      'Orientação hypermiling usando semáforos OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Percurso GPS da viagem';

  @override
  String get featureDescription_gpsTripPath =>
      'Guardar amostras de percurso GPS junto a cada viagem.';

  @override
  String get featureLabel_autoRecord => 'Gravação automática';

  @override
  String get featureDescription_autoRecord =>
      'Iniciar automaticamente uma viagem quando o adaptador OBD2 se liga a um veículo em movimento.';

  @override
  String get featureLabel_showFuel => 'Mostrar postos de combustível';

  @override
  String get featureDescription_showFuel =>
      'Mostrar resultados de postos de gasolina/diesel na pesquisa e no mapa.';

  @override
  String get featureLabel_showElectric => 'Mostrar postos de carregamento';

  @override
  String get featureDescription_showElectric =>
      'Mostrar postos de carregamento EV na pesquisa e no mapa.';

  @override
  String get featureLabel_showConsumptionTab => 'Separador de consumo';

  @override
  String get featureDescription_showConsumptionTab =>
      'Mostrar o separador de análise de consumo na navegação inferior.';

  @override
  String get featureBlockedEnable_gamification =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureBlockedEnable_baselineSync => 'Ative primeiro o TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureBlockedEnable_showFuel => 'Pré-requisitos não cumpridos';

  @override
  String get featureBlockedEnable_showElectric =>
      'Pré-requisitos não cumpridos';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Previsão de preços TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Modelo de previsão de preços no dispositivo — a inferência é local; funcionalidades e previsões nunca saem do dispositivo.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Ative primeiro o histórico de preços';

  @override
  String get featureLabel_fuelCalculator => 'Calculadora de combustível';

  @override
  String get featureDescription_fuelCalculator =>
      'Calculadora de custo de combustível acessível nos resultados de pesquisa.';

  @override
  String get featureLabel_carbonDashboard => 'Painel de carbono';

  @override
  String get featureDescription_carbonDashboard =>
      'Painel de pegada de CO2 acessível no separador de consumo.';

  @override
  String get featureLabel_experimentalOemPids => 'PIDs OEM experimentais';

  @override
  String get featureDescription_experimentalOemPids =>
      'Leia os litros exatos do depósito através de PIDs específicos do fabricante em adaptadores compatíveis.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Ative primeiro a gravação de viagens OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Ler QR de pagamento';

  @override
  String get featureDescription_paymentQrScan =>
      'Leitor QR de pagamento no ecrã de detalhes do posto.';

  @override
  String get featureLabel_communityPriceReports =>
      'Relatórios comunitários de preços';

  @override
  String get featureDescription_communityPriceReports =>
      'Reportar o preço de um posto no ecrã de detalhes.';

  @override
  String get featureLabel_obd2Optional => 'Exigir OBD2 para gravar viagens';

  @override
  String get featureDescription_obd2Optional =>
      'Quando desligado, a app grava viagens só com GPS sem precisar de um adaptador OBD2. O coaching é reduzido — sem L/100 km instantânea, menos sinais do motor.';

  @override
  String get featureLabel_addFillUpOcrReceipt => 'OCR de recibo';

  @override
  String get featureDescription_addFillUpOcrReceipt =>
      'Digitalize um recibo impresso na tela Adicionar abastecimento para preencher data, litros, total e estação.';

  @override
  String get featureLabel_addFillUpOcrPump =>
      'OCR do display da bomba (experimental)';

  @override
  String get featureDescription_addFillUpOcrPump =>
      'Digitalize o display de uma bomba de combustível para preencher o formulário. O reconhecimento é hoje pouco confiável — ative apenas se quiser testar.';

  @override
  String get featureLabel_developerPatToken =>
      'Feedback de desenvolvedor (GitHub PAT)';

  @override
  String get featureDescription_developerPatToken =>
      'Ativa o painel de feedback para scans com falha que cria automaticamente issues no GitHub com um Personal Access Token. Função para usuários avançados / colaboradores.';

  @override
  String get featureLabel_debugMode => 'Modo programador / depuração';

  @override
  String get featureDescription_debugMode =>
      'Mostra uma secção Ferramentas de programador nas definições com diagnósticos: exportação do registo de erros, notificações de teste, execução do pipeline de alerta de teste, despejo de sinalizadores de funcionalidades, limpeza de caches e cópia de diagnósticos.';

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
  String get feedbackConsentTitle => 'Enviar relatório para o GitHub?';

  @override
  String get feedbackConsentBody =>
      'Isto cria um ticket público no nosso repositório GitHub com a sua foto e o texto OCR. Não são enviados dados pessoais (localização, ID de conta). Continuar?';

  @override
  String get feedbackConsentContinue => 'Continuar';

  @override
  String get feedbackConsentCancel => 'Cancelar';

  @override
  String get feedbackConsentLater => 'Mais tarde';

  @override
  String get feedbackTokenSectionTitle =>
      'Feedback de leitura falhada (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Para abrir automaticamente um ticket no GitHub a partir de uma leitura falhada, cole um PAT do GitHub (âmbito `public_repo` no repositório tankstellen). Caso contrário, a partilha manual continua disponível.';

  @override
  String get feedbackTokenStatusSet => 'Token configurado';

  @override
  String get feedbackTokenStatusUnset => 'Sem token';

  @override
  String get feedbackTokenSet => 'Definir';

  @override
  String get feedbackTokenClear => 'Limpar';

  @override
  String get feedbackTokenDialogTitle => 'PAT do GitHub';

  @override
  String get feedbackTokenFieldLabel => 'Token de acesso pessoal';

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
      'Verificado pelo adaptador';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Não coincide com a leitura do adaptador';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'A sua entrada: $userL L. O adaptador indica: $adapterL L (diferença da captura do nível de combustível antes/depois). Usar o valor do adaptador?';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Manter a minha entrada';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Usar o valor do adaptador';

  @override
  String get scanReceiptNoData =>
      'Nenhum dado de recibo encontrado — tente novamente';

  @override
  String get scanReceiptSuccess =>
      'Recibo lido — verifique os valores. Toque em \"Reportar erro de leitura\" abaixo se algo estiver errado.';

  @override
  String scanReceiptFailed(String error) {
    return 'Leitura falhada: $error';
  }

  @override
  String get scanPumpUnreadable => 'Visor da bomba ilegível — tente novamente';

  @override
  String get scanPumpSuccess => 'Visor da bomba lido — verifique os valores.';

  @override
  String get scanPumpGlare =>
      'Reflexo em excesso no visor — tente novamente num ângulo ligeiro para que os números não fiquem apagados.';

  @override
  String scanPumpFailed(String error) {
    return 'Leitura da bomba falhada: $error';
  }

  @override
  String get badScanReportTitle => 'Reportar um erro de leitura';

  @override
  String get badScanReportTitleReceipt =>
      'Reportar um erro de leitura — Recibo';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Reportar um erro de leitura — Visor da bomba';

  @override
  String get pumpScanFailureTitle => 'Visor ilegível';

  @override
  String get pumpScanFailureBody =>
      'A leitura não conseguiu ler o visor da bomba. O que pretende fazer?';

  @override
  String get pumpScanFailureCorrectManually => 'Corrigir manualmente';

  @override
  String get pumpScanFailureReport => 'Reportar';

  @override
  String get pumpScanFailureRemove => 'Remover foto';

  @override
  String get badScanReportHint =>
      'Vamos partilhar a foto do recibo e ambos os conjuntos de valores para que a próxima versão aprenda este layout.';

  @override
  String get badScanReportShareAction => 'Partilhar relatório + foto';

  @override
  String get badScanReportFieldBrandLayout => 'Layout de marca';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Preço/L';

  @override
  String get badScanReportFieldStation => 'Posto';

  @override
  String get badScanReportFieldFuel => 'Combustível';

  @override
  String get badScanReportFieldDate => 'Data';

  @override
  String get badScanReportHeaderField => 'Campo';

  @override
  String get badScanReportHeaderScanned => 'Lido';

  @override
  String get badScanReportHeaderYouTyped => 'Introduzido por si';

  @override
  String get badScanReportCreateTicket => 'Criar problema';

  @override
  String get badScanReportOpenInBrowser => 'Abrir no browser';

  @override
  String get badScanReportFallbackToShare => 'Envio falhado — partilha manual';

  @override
  String get pumpCameraHint =>
      'Alinhe os três números do visor da bomba dentro do quadro';

  @override
  String get pumpCameraCapture => 'Capturar';

  @override
  String get pumpCameraPermissionDenied =>
      'É necessário acesso à câmera para digitalizar o visor da bomba. Ative-o nas configurações do dispositivo.';

  @override
  String get pumpCameraError =>
      'A câmera não pôde iniciar. Tente novamente ou insira os valores manualmente.';

  @override
  String get pumpCameraOrientationHorizontal => 'Mudar para layout horizontal';

  @override
  String get pumpCameraOrientationVertical => 'Mudar para layout vertical';

  @override
  String get pumpCameraGlareWarning =>
      'Muito brilho — incline levemente para evitar reflexos';

  @override
  String get pumpCameraAlignHint =>
      'Alinhe o visor dentro da moldura e capture';

  @override
  String get pumpCameraRotateToLandscape =>
      'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright';

  @override
  String get fillUpSectionWhatTitle => 'O que abasteceu';

  @override
  String get fillUpSectionWhatSubtitle => 'Combustível, quantidade, preço';

  @override
  String get fillUpSectionWhereTitle => 'Onde estava';

  @override
  String get fillUpSectionWhereSubtitle => 'Posto, odómetro, notas';

  @override
  String get fillUpImportFromLabel => 'Importar de…';

  @override
  String get fillUpImportSheetTitle => 'Importar dados de abastecimento';

  @override
  String get fillUpImportReceiptLabel => 'Recibo';

  @override
  String get fillUpImportReceiptDescription =>
      'Ler um recibo em papel com a câmara';

  @override
  String get fillUpImportPumpLabel => 'Visor da bomba';

  @override
  String get fillUpImportPumpDescription =>
      'Ler Betrag / Preis no LCD da bomba';

  @override
  String get fillUpImportObdLabel => 'Adaptador OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Ler odómetro via porta OBD-II por Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Preço por litro';

  @override
  String get vehicleHeaderPlateLabel => 'Matrícula';

  @override
  String get vehicleHeaderUntitled => 'Novo veículo';

  @override
  String get vehicleSectionIdentityTitle => 'Identidade';

  @override
  String get vehicleSectionIdentitySubtitle => 'Nome e VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Transmissão';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'Como este veículo se move';

  @override
  String get profileSectionDisplayStations => 'Display & stations';

  @override
  String get profileSectionRegion => 'Region';

  @override
  String get calibrationModeLabel => 'Modo de calibração';

  @override
  String get calibrationModeRule => 'Baseado em regras';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'O modo baseado em regras atribui cada amostra de condução a exatamente uma situação. O modo fuzzy distribui-a por todas de acordo com o grau de adequação — mais suave em torno de 60 km/h ou gradientes variáveis, mas mais lento a preencher todos os intervalos.';

  @override
  String get profileGamificationToggleTitle =>
      'Mostrar conquistas e pontuações';

  @override
  String get profileGamificationToggleSubtitle =>
      'Quando desativado, as conquistas, pontuações e ícones de troféu ficam ocultos em toda a aplicação.';

  @override
  String get coachingGpsLiftOff => 'Soltar gás';

  @override
  String get coachingGpsAnticipateBrake => 'Antecipar';

  @override
  String get coachingGpsSmoothAccel => 'Aceleração suave';

  @override
  String get gpsDiagnosticsTitle => 'Diagnóstico de amostras GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps interrupções',
      one: '1 interrupção',
      zero: 'sem interrupções',
    );
    return '$count amostras · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Intervalo mediano: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Capturado durante a gravação para verificar a cadência GPS com o telemóvel em repouso.';

  @override
  String get gpsMatrixMaturityCold => 'Fria';

  @override
  String get gpsMatrixMaturityWarming => 'Aquecendo';

  @override
  String get gpsMatrixMaturityConverged => 'Convergente';

  @override
  String gpsMatrixMaturityColdTooltip(int count) {
    return 'Matriz GPS ainda aquecendo ($count refinamentos até agora). Estimativas provisórias.';
  }

  @override
  String gpsMatrixMaturityWarmingTooltip(int count) {
    return 'Matriz GPS convergindo ($count abastecimentos). Estimativas utilizáveis com possível variação de alguns %.';
  }

  @override
  String gpsMatrixMaturityConvergedTooltip(int count) {
    return 'Matriz GPS convergiu ($count abastecimentos). Estimativas dentro de ~2 % do consumo real.';
  }

  @override
  String get tripAvgGpsEstimateTooltip =>
      'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.';

  @override
  String get hapticEcoCoachSectionTitle => 'Condução';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco-coaching em tempo real';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Toque háptico suave + dica no ecrã quando pisa fundo em velocidade de cruzeiro';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Devagar no acelerador — deslizar poupa mais';

  @override
  String semanticsNavigateTo(String name) {
    return 'Navegar até $name';
  }

  @override
  String semanticsRemoveFromFavorites(String name) {
    return 'Remover $name dos favoritos';
  }

  @override
  String get showOnMapSemanticLabel => 'Mostrar estações no mapa';

  @override
  String get searchResultsSemanticLabel => 'Resultados da pesquisa';

  @override
  String get searchCriteriaSemanticLabel =>
      'Resumo dos critérios de pesquisa. Toque para editar.';

  @override
  String get noFavoritesSemanticLabel =>
      'Ainda não há favoritos. Toque na estrela de uma estação para guardá-la como favorita.';

  @override
  String stationStatusSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'A estação está aberta',
      'false': 'A estação está fechada',
      'other': 'A estação está fechada',
    });
    return '$_temp0';
  }

  @override
  String countryChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'País $name, selecionado',
      'false': 'País $name',
      'other': 'País $name',
    });
    return '$_temp0';
  }

  @override
  String languageChipSemantic(String name, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Idioma $name, selecionado',
      'false': 'Idioma $name',
      'other': 'Idioma $name',
    });
    return '$_temp0';
  }

  @override
  String sortBySemantic(String option, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Ordenar por $option, selecionado',
      'false': 'Ordenar por $option',
      'other': 'Ordenar por $option',
    });
    return '$_temp0';
  }

  @override
  String fuelTypeSemantic(String type, String selected) {
    String _temp0 = intl.Intl.selectLogic(selected, {
      'true': 'Combustível $type, selecionado',
      'false': 'Combustível $type',
      'other': 'Combustível $type',
    });
    return '$_temp0';
  }

  @override
  String evChargingStationSemantic(String name, int power) {
    return 'Estação de carregamento $name, $power kW';
  }

  @override
  String get shieldIllustrationSemantic =>
      'Escudo de privacidade com gota de combustível';

  @override
  String get globeIllustrationSemantic =>
      'Globo com marcadores de postos de combustível';

  @override
  String get fuelPumpIllustrationSemantic =>
      'Bomba de combustível com indicador de preços';

  @override
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  ) {
    return '$name, fonte de dados: $provider, $keyRequirement, tipos de combustível: $fuelTypes';
  }

  @override
  String get countryInfoApiKeyRequired => 'Chave API necessária';

  @override
  String get countryInfoNoKeyNeeded => 'Grátis, sem chave';

  @override
  String countryInfoDataSource(String provider) {
    return 'Dados: $provider';
  }

  @override
  String countryInfoFuelTypes(String fuelTypes) {
    return 'Tipos de combustível: $fuelTypes';
  }

  @override
  String get countryInfoDemoSource => 'Demo';

  @override
  String get anonKeyLabel => 'Chave Anon';

  @override
  String get anonKeyHideTooltip => 'Ocultar chave';

  @override
  String get anonKeyShowTooltip => 'Mostrar chave para verificar';

  @override
  String anonKeyTooLong(int length) {
    return 'A chave é demasiado longa ($length caracteres) — verifique se há texto extra';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'A chave parece correta ($length caracteres)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'A chave deve ser um JWT (cabeçalho.payload.assinatura)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'A chave pode estar truncada ($length de ~208 caracteres esperados)';
  }

  @override
  String get anonKeyExceedsMax => 'A chave excede o comprimento máximo';

  @override
  String get qrShareTitle => 'Partilhar a sua base de dados';

  @override
  String get qrShareSubtitle =>
      'Outros podem ler este código QR para se ligarem';

  @override
  String get qrShareCopyAsText => 'Copiar como texto';

  @override
  String get authInfoTitle => 'Porque criar uma conta?';

  @override
  String get authInfoBenefit1 =>
      '• Sincronize favoritos, alertas e rotas guardadas entre dispositivos';

  @override
  String get authInfoBenefit2 =>
      '• Prepare uma rota no telemóvel, use-a no carro';

  @override
  String get authInfoBenefit3 => '• Nenhum dado é partilhado com terceiros';

  @override
  String get authInfoBenefit4 =>
      '• Pode eliminar a sua conta a qualquer momento';

  @override
  String get privacyLocalDataEmpty =>
      'Nada guardado ainda. Adicione um favorito ou defina um alerta de preço para ver entradas aqui.';

  @override
  String get privacyHideEmptyRows => 'Ocultar linhas vazias';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count linhas vazias',
      one: 'Mostrar $count linha vazia',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Configuração da chave de API (opcional)';

  @override
  String get apiKeySetupDescription =>
      'Registe-se para obter uma chave de API gratuita ou ignore para explorar a aplicação com dados de demonstração.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Registo $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Ao introduzir uma chave de API, aceita os termos de $provider. A redistribuição de dados é proibida.';
  }

  @override
  String get calculatorDistanceHint => 'ex.: 150';

  @override
  String get calculatorConsumptionHint => 'ex.: 7,0';

  @override
  String get calculatorPriceHint => 'ex.: 1,899';

  @override
  String get routeStrategyLabel => 'Estratégia:';

  @override
  String get routeStrategyUniform => 'Uniforme';

  @override
  String get routeStrategyBalanced => 'Equilibrada';

  @override
  String get glideCoachBetaTitle => 'Glide-coach beta (experimental)';

  @override
  String get glideCoachBetaSubtitle =>
      'Toque háptico subtil ao abrandar antes de um semáforo vermelho. Desativado por predefinição — risco de distração.';

  @override
  String get consentSyncTripsTitle => 'Sincronizar gravações de viagens';

  @override
  String get consentSyncTripsSubtitle =>
      'Fazer cópia de segurança das viagens OBD2 + GPS no TankSync. Entre dispositivos, opcional.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Ative a Sincronização na Nuvem acima para fazer cópia de segurança das viagens.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Inicia sessão com uma conta de e-mail para sincronizar as viagens entre dispositivos.';

  @override
  String get consentHideDetails => 'Ocultar detalhes';

  @override
  String get consentShowDetails => 'Mostrar detalhes';

  @override
  String get dialogOk => 'OK';

  @override
  String get invalidLinkTitle => 'Ligação inválida';

  @override
  String invalidLinkBody(String path) {
    return 'A ligação \"$path\" não é válida.';
  }

  @override
  String get home => 'Início';

  @override
  String get locationConsentTitle => 'Acesso à localização';

  @override
  String get locationConsentSubtitle =>
      'Esta aplicação gostaria de usar a sua localização para encontrar postos de combustível perto de si.';

  @override
  String get locationConsentWhatHappens =>
      'O que acontece com os seus dados de localização:';

  @override
  String get locationConsentBulletApi =>
      'As suas coordenadas são enviadas para a API de preços de combustível para encontrar postos próximos.';

  @override
  String get locationConsentBulletNoServer =>
      'A sua localização não é armazenada em nenhum servidor — não existe servidor.';

  @override
  String get locationConsentBulletNoTracking =>
      'Os dados de localização não são usados para publicidade, análise ou rastreio.';

  @override
  String get locationConsentRevoke =>
      'Pode revogar o acesso à localização a qualquer momento nas definições do sistema. Em alternativa, pesquise por código postal.';

  @override
  String get locationConsentLegalBasis =>
      'Base jurídica: art. 6.º, n.º 1, al. a) do RGPD (consentimento)';

  @override
  String get locationConsentDecline => 'Recusar';

  @override
  String get locationConsentAccept => 'Aceitar';

  @override
  String get loyaltySettingsTitle => 'Cartões de clube de combustível';

  @override
  String get loyaltySettingsSubtitle =>
      'Aplique o seu desconto de fidelidade aos preços apresentados';

  @override
  String get loyaltyMenuTitle => 'Cartões de clube de combustível';

  @override
  String get loyaltyMenuSubtitle =>
      'Aplique descontos por litro de Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Adicionar cartão';

  @override
  String get loyaltyAddCardSheetTitle =>
      'Adicionar cartão de clube de combustível';

  @override
  String get loyaltyBrandLabel => 'Marca';

  @override
  String get loyaltyCardLabelLabel => 'Etiqueta (opcional)';

  @override
  String get loyaltyDiscountLabel => 'Desconto (por litro)';

  @override
  String get loyaltyDiscountInvalid => 'Introduza um número positivo';

  @override
  String get loyaltyDeleteConfirmTitle => 'Eliminar cartão?';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Este cartão deixará de aplicar o seu desconto.';

  @override
  String get loyaltyEmptyTitle => 'Sem cartões de clube de combustível';

  @override
  String get loyaltyEmptyBody =>
      'Adicione um cartão para aplicar automaticamente o seu desconto por litro nos postos correspondentes.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Aumento de RPM em marcha lenta detetado';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'O RPM em marcha lenta aumentou $percent% nas últimas $tripCount viagens. Possível sinal precoce de filtro de ar entupido ou deriva do sensor.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Possível restrição de admissão';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'O caudal de combustível em cruzeiro desceu $percent% nas últimas $tripCount viagens. Possível sinal de filtro de ar entupido ou admissão restrita — vale a pena uma verificação.';
  }

  @override
  String get maintenanceActionDismiss => 'Ignorar';

  @override
  String get maintenanceActionSnooze => 'Adiar 30 dias';

  @override
  String get consumptionMonthlyInsightsTitle => 'Este mês vs mês passado';

  @override
  String get consumptionMonthlyTripsLabel => 'Viagens';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Tempo de condução';

  @override
  String get consumptionMonthlyDistanceLabel => 'Distância';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Consumo médio';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'São necessárias pelo menos 3 viagens por mês para comparação';

  @override
  String get consumptionMonthlyClimbLabel => 'Climbed';

  @override
  String get obd2CapabilitySectionTitle => 'Capacidades do adaptador';

  @override
  String get obd2CapabilityStandardOnly => 'Padrão';

  @override
  String get obd2CapabilityOemPids => 'PIDs OEM';

  @override
  String get obd2CapabilityFullCan => 'CAN completo';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Para litros exatos no depósito em Peugeot/Citroën, a aplicação suporta OBDLink MX+/LX/CX (chip STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Overlay de diagnóstico OBD2 ativado';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Overlay de diagnóstico OBD2 desativado';

  @override
  String get obd2DebugOverlayClearButton => 'Limpar';

  @override
  String get obd2DebugOverlayCloseButton => 'Fechar';

  @override
  String get obd2DebugOverlayTitle => 'Breadcrumbs OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Partilhar registo de diagnóstico';

  @override
  String get obd2DebugLoggingTitle => 'Registo de depuração OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Registe cada sessão OBD2 — ligação, handshake, falhas de dados e reconexões — num registo XML exportável. Desativado por predefinição.';

  @override
  String get obd2DebugSessionShareLabel => 'Partilhar registo da sessão OBD2';

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
    return 'Não foi possível alcançar \'$adapterName\' — escolha outro adaptador';
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
  String get onboardingObd2StepTitle => 'Ligue o seu adaptador OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Ligue o adaptador OBD2 à porta do carro e ligue o contacto. Vamos ler o VIN e preencher os detalhes do motor por si.';

  @override
  String get onboardingObd2ConnectButton => 'Ligar adaptador';

  @override
  String get onboardingObd2SkipButton => 'Talvez mais tarde';

  @override
  String get onboardingObd2ReadingVin => 'A ler VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Não foi possível ler o VIN — introduza manualmente';

  @override
  String get onboardingObd2ConnectFailed =>
      'Não foi possível ligar ao adaptador. Pode tentar novamente ou ignorar.';

  @override
  String get onboardingPickUseMode => 'Escolha um modo de uso para continuar.';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.';

  @override
  String get tripRecordingPipElapsedCaption => 'decorrido';

  @override
  String get alertsRadiusFrequencyLabel => 'Frequência de verificação';

  @override
  String get alertsRadiusFrequencyDaily => 'Uma vez por dia';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Duas vezes por dia';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Três vezes por dia';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Quatro vezes por dia';

  @override
  String get radiusAlertPickOnMap => 'Escolher no mapa';

  @override
  String get radiusAlertMapPickerTitle => 'Escolher centro do alerta';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirmar';

  @override
  String get radiusAlertMapPickerCancel => 'Cancelar';

  @override
  String get radiusAlertMapPickerHint =>
      'Arraste o mapa para posicionar o centro do alerta';

  @override
  String get radiusAlertCenterFromMap => 'Localização no mapa';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel perto de $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Um posto está a $price € (objetivo: $threshold €)';
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
  String get refuelUnitPerSession => '/sessão';

  @override
  String get speedConsumptionCardTitle => 'Consumo por velocidade';

  @override
  String get speedBandIdleJam => 'Marcha lenta / engarrafamento';

  @override
  String get speedBandUrban => 'Urbano (10–50)';

  @override
  String get speedBandSuburban => 'Suburbano (50–80)';

  @override
  String get speedBandRural => 'Rural (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Cruzeiro eco (100–115)';

  @override
  String get speedBandMotorway => 'Autoestrada (115–130)';

  @override
  String get speedBandMotorwayFast => 'Autoestrada rápida (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Grave 30+ minutos de viagens com o adaptador OBD2 para desbloquear a análise velocidade/consumo.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % do tempo de condução';
  }

  @override
  String get speedConsumptionNeedMoreData => 'São necessários mais dados';

  @override
  String get splashLoadingLabel => 'A carregar Sparkilo';

  @override
  String get storageRecoveryTitle => 'Problema de armazenamento';

  @override
  String get storageRecoveryMessage =>
      'O Sparkilo não conseguiu abrir o seu armazenamento de dados local. O ficheiro de armazenamento parece estar danificado.';

  @override
  String get storageRecoveryGuidance =>
      'Para recuperar, limpe o armazenamento da aplicação nas definições do dispositivo ou reinstale a aplicação. Os seus favoritos e o histórico são guardados apenas neste dispositivo, pelo que não podem ser restaurados automaticamente.';

  @override
  String get tankLevelTitle => 'Nível do depósito';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km de autonomia';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Último abastecimento: $date · $count viagem(ns) desde então';
  }

  @override
  String get tankLevelMethodObd2 => 'Medido por OBD2';

  @override
  String get tankLevelMethodDistanceFallback =>
      'estimativa baseada na distância';

  @override
  String get tankLevelMethodMixed => 'medição mista';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Registe um abastecimento para ver o nível do depósito';

  @override
  String get tankLevelDetailSheetTitle =>
      'Viagens desde o último abastecimento';

  @override
  String get addFillUpIsFullTankLabel => 'Tanque cheio';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Depósito cheio até à boca — desmarque se foi um abastecimento parcial';

  @override
  String get themeCardTitle => 'Tema';

  @override
  String get themeCardSubtitleSystem => 'Sistema';

  @override
  String get themeCardSubtitleLight => 'Claro';

  @override
  String get themeCardSubtitleDark => 'Escuro';

  @override
  String get themeSettingsScreenTitle => 'Tema';

  @override
  String get themeSettingsSystemLabel => 'Seguir sistema';

  @override
  String get themeSettingsLightLabel => 'Claro';

  @override
  String get themeSettingsDarkLabel => 'Escuro';

  @override
  String get themeSettingsSystemDescription =>
      'Corresponde ao aspeto atual do dispositivo.';

  @override
  String get themeSettingsLightDescription =>
      'Fundos claros — ideal para uso diurno.';

  @override
  String get themeSettingsDarkDescription =>
      'Fundos escuros — mais confortável para os olhos à noite e poupa bateria em ecrãs OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'O aspeto verde característico da aplicação — brilhante e fácil de ler, com fundos subtilmente esverdeados.';

  @override
  String get throttleRpmHistogramTitle => 'Como usou o motor';

  @override
  String get throttleRpmHistogramThrottleSection => 'Posição do acelerador';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM do motor';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Deslizamento (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Leve (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Moderado (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Fundo (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Marcha lenta (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Cruzeiro (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Animado (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Forçado (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Sem amostras de acelerador ou RPM nesta viagem.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Viagens';

  @override
  String get trajetsStartRecordingButton => 'Iniciar gravação';

  @override
  String get trajetsResumeRecordingButton => 'Retomar gravação';

  @override
  String get tripStartProgressConnectingAdapter => 'A ligar ao adaptador OBD2…';

  @override
  String get tripStartProgressReadingVehicleData => 'A ler dados do veículo…';

  @override
  String get tripStartProgressStartingRecording => 'A iniciar gravação…';

  @override
  String get tripSaveProgressFinalizingSummary => 'Finalizing summary…';

  @override
  String get tripSaveProgressSavingToHistory => 'Saving to history…';

  @override
  String get tripSaveProgressSyncingToCloud => 'Syncing in background…';

  @override
  String get trajetsEmptyStateTitle => 'Sem viagens ainda';

  @override
  String get trajetsEmptyStateBody =>
      'Toque em Iniciar gravação para começar a registar as suas conduções.';

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
  String get trajetDetailSummaryTitle => 'Resumo';

  @override
  String get trajetDetailFieldDate => 'Data';

  @override
  String get trajetDetailFieldVehicle => 'Veículo';

  @override
  String get trajetDetailFieldAdapter => 'Adaptador OBD2';

  @override
  String get trajetDetailFieldDistance => 'Distância';

  @override
  String get trajetDetailFieldDuration => 'Duração';

  @override
  String get trajetDetailFieldAvgConsumption => 'Consumo médio';

  @override
  String get trajetDetailFieldFuelUsed => 'Combustível usado';

  @override
  String get trajetDetailFieldFuelCost => 'Custo de combustível';

  @override
  String get trajetDetailFieldAvgSpeed => 'Velocidade média';

  @override
  String get trajetDetailFieldMaxSpeed => 'Velocidade máxima';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Velocidade (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Caudal de combustível (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Carga do motor (%)';

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
  String get trajetsRowColdStartChip => 'Arranque a frio';

  @override
  String get trajetsRowColdStartTooltip =>
      'O motor não atingiu a temperatura de funcionamento durante esta viagem — o consumo de combustível foi superior ao normal.';

  @override
  String get trajetDetailChartEmpty => 'Sem amostras gravadas';

  @override
  String get trajetDetailChartEstimatedBadge => 'estimated';

  @override
  String get trajetDetailShareAction => 'Partilhar';

  @override
  String get trajetDetailShareImageOption => 'Partilhar imagem';

  @override
  String get trajetDetailShareGpxOption => 'Partilhar traço GPS (GPX)';

  @override
  String get trajetDetailShareGpxEmpty => 'Sem dados GPS nesta viagem';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — viagem a $date';
  }

  @override
  String get trajetDetailShareError =>
      'Não foi possível gerar imagem para partilha';

  @override
  String get trajetDetailDownloadCsvOption => 'Download telemetry (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Download telemetry (JSON)';

  @override
  String get trajetDetailDownloadError => 'Couldn\'t save the file';

  @override
  String get trajetDetailDeleteAction => 'Eliminar';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Eliminar esta viagem?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Esta viagem será permanentemente removida do seu histórico.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Cancelar';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Eliminar';

  @override
  String get tripRecordingObd2NotResponding =>
      'Adaptador OBD2 ligado mas sem devolver dados. Tente um adaptador diferente ou verifique o protocolo de diagnóstico do veículo.';

  @override
  String get trajetsViewAllOnMap => 'Ver todos no mapa';

  @override
  String get trajetsMapTitle => 'Viagens no mapa';

  @override
  String get trajetsMapShareGpx => 'Partilhar GPX';

  @override
  String get trajetsMapEmpty =>
      'Nenhuma das viagens selecionadas tem dados GPS.';

  @override
  String get trajetsMapShareError =>
      'Não foi possível partilhar o ficheiro GPX';

  @override
  String get tripLengthCardTitle => 'Consumo por duração da viagem';

  @override
  String get tripLengthBucketShort => 'Curta (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Média (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Longa (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'São necessários mais dados';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viagens',
      one: '1 viagem',
      zero: 'sem viagens',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Percurso da viagem';

  @override
  String get tripPathCardSubtitle => 'Rota registada por GPS';

  @override
  String get tripPathLegendTitle => 'Consumo';

  @override
  String get tripPathLegendEfficient => 'Eficiente (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Aceitável (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Dispendioso (≥ 10 L/100km)';

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
  String get fuelStationRadarResultBadge => 'Fuel Station Radar result';

  @override
  String get tripRecordingPinTooltip =>
      'Fixar mantém o ecrã ligado — usa mais bateria';

  @override
  String get tripRecordingPinSemanticOn => 'Desafixar formulário de gravação';

  @override
  String get tripRecordingPinSemanticOff => 'Fixar formulário de gravação';

  @override
  String get tripRecordingPinHelpTooltip => 'O que faz o fixar?';

  @override
  String get tripRecordingPinHelpTitle => 'Sobre fixar';

  @override
  String get tripRecordingPinHelpBody =>
      'Fixar mantém o ecrã ligado e oculta as barras do sistema para que o formulário permaneça legível num suporte de painel. Toque novamente para libertar. Liberta automaticamente quando a viagem para.';

  @override
  String get tripRecordingResumeHintMessage =>
      'A gravação continua em segundo plano. Toque na faixa vermelha no topo de qualquer ecrã para voltar.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Abra a viagem ativa no separador Conso';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Fixe o ecrã para manter o GPS ativo durante a viagem — o Android pode limitar o GPS durante o repouso.';

  @override
  String get tripRecordingMinimiseTooltip =>
      'Minimizar para um mosaico flutuante';

  @override
  String get tripRecordingAutoPinTitle => 'Fixar sempre ao iniciar a gravação';

  @override
  String get tripRecordingAutoPinSubtitle =>
      'Fixa o formulário automaticamente em cada viagem em vez de tocar todas as vezes. Consome mais bateria.';

  @override
  String get tripRecordingConnectingTitle => 'A iniciar a gravação…';

  @override
  String get tripRecordingSavingTitle => 'Saving trip…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Recording discarded — no movement detected';

  @override
  String get tripShareAction => 'Partilhar com outra conta';

  @override
  String get tripShareSheetTitle => 'Partilhar este trajeto';

  @override
  String get tripShareSheetSubtitle =>
      'Dê a outra conta TankSync acesso só de leitura a este trajeto registado.';

  @override
  String get tripShareEmailLabel => 'E-mail do destinatário';

  @override
  String get tripShareEmailHint => 'name@example.com';

  @override
  String get tripShareSendButton => 'Partilhar';

  @override
  String get tripShareCreateLinkButton => 'Criar link de partilha';

  @override
  String get tripShareLinkCreated =>
      'Link de partilha copiado — cole-o ao destinatário.';

  @override
  String get tripShareSuccess => 'Trajeto partilhado.';

  @override
  String get tripShareRecipientNotFound =>
      'Nenhuma conta TankSync usa esse e-mail.';

  @override
  String get tripShareError =>
      'Não foi possível partilhar o trajeto. Tente novamente.';

  @override
  String get tripShareExistingTitle => 'Partilhado com';

  @override
  String get tripShareExistingEmpty => 'Ainda não partilhado com ninguém.';

  @override
  String get tripShareDirectRecipient => 'Uma conta';

  @override
  String get tripShareLinkRecipient => 'Link de partilha (não reclamado)';

  @override
  String get tripShareRevokeTooltip => 'Revogar';

  @override
  String get tripShareRevoked => 'Partilha revogada.';

  @override
  String get trajetsSharedSectionTitle => 'Partilhado comigo';

  @override
  String get trajetsSharedBadge => 'Partilhado';

  @override
  String get unifiedFilterFuel => 'Combustível';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Ambos';

  @override
  String get unifiedNoResultsForFilter =>
      'Nenhum resultado corresponde a este filtro';

  @override
  String get searchFailedSnackbar => 'Pesquisa falhada — tente novamente';

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
  String get vinDecodeTooltip => 'Descodificar VIN';

  @override
  String get vinConfirmAction => 'Sim, preencher automaticamente';

  @override
  String get vinModifyAction => 'Modificar manualmente';

  @override
  String get veResetAction => 'Repor eficiência volumétrica';

  @override
  String get vehicleReadVinFromCarButton => 'Ler VIN do carro';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Ler VIN do adaptador OBD2 emparelhado';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN não disponível (Mode 09 PID 02 não suportado em veículos anteriores a 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Leitura do VIN falhada — introduza manualmente';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Emparelhe primeiro um adaptador OBD2 para ler o VIN automaticamente';

  @override
  String get pickerButtonLabel => 'Escolher do catálogo';

  @override
  String get pickerSearchHint => 'Pesquisar marca ou modelo';

  @override
  String get pickerHelpText =>
      'Pré-preencher a partir de 50+ veículos suportados';

  @override
  String get pickerEmptyResults => 'Sem correspondências';

  @override
  String get pickerCancel => 'Cancelar';

  @override
  String get pickerLoading => 'A carregar catálogo…';

  @override
  String get vinInfoTooltip => 'O que é um VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'O que é um VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'O Número de Identificação do Veículo é um código de 17 caracteres único do seu carro. Está gravado no chassis e impresso no seu documento de identificação do veículo.';

  @override
  String get vinInfoSectionWhyTitle => 'Porque pedimos';

  @override
  String get vinInfoSectionWhyBody =>
      'Descodificar o VIN preenche automaticamente a cilindrada do motor, número de cilindros, ano do modelo, tipo de combustível principal e peso bruto — poupando-lhe a consulta manual de especificações técnicas. O cálculo do caudal de combustível OBD2 usa estes valores para lhe dar números de consumo precisos.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacidade';

  @override
  String get vinInfoSectionPrivacyBody =>
      'O seu VIN é guardado apenas localmente no armazenamento encriptado da aplicação — nunca é enviado para os servidores Sparkilo. A base de dados NHTSA vPIC é consultada com o VIN, mas devolve apenas especificações técnicas anónimas; a NHTSA não associa o VIN a dados pessoais. Sem rede, uma consulta offline devolve apenas o fabricante e o país.';

  @override
  String get vinInfoSectionWhereTitle => 'Onde encontrá-lo';

  @override
  String get vinInfoSectionWhereBody =>
      'Veja através do para-brisas no canto inferior esquerdo do lado do condutor, verifique o autocolante na jamba da porta do condutor quando aberta, ou leia-o no seu documento de identificação do veículo (cartão / Carta de Circulação).';

  @override
  String get vinInfoDismiss => 'Percebido';

  @override
  String get vinConfirmPrivacyNote =>
      'Consultámos o seu VIN na base de dados gratuita NHTSA — nada enviado para os servidores Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Descodificação online do VIN';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Descodificar o VIN via serviço público gratuito da NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Quando emparelha um adaptador, o VIN do seu veículo é lido localmente para identificar o carro. Ativar isto envia o VIN de 17 caracteres para o serviço vPIC gratuito da NHTSA para obter detalhes adicionais (modelo, cilindrada, tipo de combustível). O VIN é o único dado enviado — nenhuma outra informação sai do seu dispositivo.';

  @override
  String get vehicleDetectedFromVinBadge => '(detetado)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detetado a partir do VIN: $summary. Aplicar?';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Aplicar';

  @override
  String get widgetHelpSectionTitle => 'Widget no ecrã inicial';

  @override
  String get widgetHelpIntro =>
      'Adicione o widget SparKilo ao seu ecrã inicial para ver os preços de combustível e carregamento de relance.';

  @override
  String get widgetHelpAdd =>
      'Adicione-o no seletor de widgets do seu launcher — pressione longamente uma área vazia do ecrã inicial, escolha Widgets e encontre SparKilo.';

  @override
  String get widgetHelpTap =>
      'Toque num posto no widget para abri-lo na aplicação. Toque no ícone de atualização para atualizar os preços.';

  @override
  String get widgetHelpConfigure =>
      'No Android, pressione longamente o widget e escolha Reconfigurar para alterar o perfil, cor e conteúdo.';

  @override
  String get widgetDefaultsApplyToAllHint =>
      'As escolhas abaixo aplicam-se a cada widget instalado na próxima atualização.';

  @override
  String get widgetDefaultsColorLabel => 'Esquema de cores';

  @override
  String get widgetDefaultsVariantLabel => 'Variante de conteúdo';

  @override
  String get widgetColorSchemeSystem => 'Seguir sistema';

  @override
  String get widgetColorSchemeLight => 'Claro';

  @override
  String get widgetColorSchemeDark => 'Escuro';

  @override
  String get widgetColorSchemeBlue => 'Azul';

  @override
  String get widgetColorSchemeGreen => 'Verde';

  @override
  String get widgetColorSchemeOrange => 'Laranja';

  @override
  String get widgetVariantDefault => 'Apenas preço atual';

  @override
  String get widgetVariantPredictive =>
      'Preditivo: melhor altura para abastecer';

  @override
  String get widgetPredictiveNowPrefix => 'agora';
}
