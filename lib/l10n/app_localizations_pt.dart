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
  String get fabRunSearch => 'Executar pesquisa';

  @override
  String get routeSearchingChip => 'A pesquisar na rota…';

  @override
  String get searchCriteriaTitle => 'Critérios de pesquisa';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'A $km km';
  }

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
  String get landingScreenFavorites => 'Favoritos';

  @override
  String get landingScreenMap => 'Mapa';

  @override
  String get landingScreenCheapest => 'Mais barato perto';

  @override
  String get landingScreenNearest => 'Postos mais próximos';

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
  String get dataTransparency => 'Transparência de dados';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get storageUsage => 'Utilização de armazenamento neste dispositivo';

  @override
  String get settingsLabel => 'Definições';

  @override
  String get total => 'Total';

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
  String get deleteAllButton => 'Eliminar tudo';

  @override
  String get cacheEmpty => 'A cache está vazia';

  @override
  String get apiKeyNote =>
      'Registo gratuito. Dados de agências governamentais de transparência de preços.';

  @override
  String get apiKeyFormatError =>
      'Formato inválido — UUID esperado (8-4-4-4-12)';

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
  String get searchLocationPlaceholder => 'Morada, código postal ou cidade';

  @override
  String get configTankSyncConnected => 'Ligado';

  @override
  String get configTankSyncDisabled => 'Desativado';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get fuels => 'Combustíveis';

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
  String get sortRating => 'Avaliação';

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
  String profileSwitchedTo(String profile) {
    return 'Mudado para $profile';
  }

  @override
  String profileCreatedNamed(String name) {
    return 'Perfil $name criado';
  }

  @override
  String profileCountryTaken(String country) {
    return 'Já existe um perfil para $country — edite-o antes.';
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
  String get refuelPlanTab => 'Plan';

  @override
  String get refuelPlanCheapestTitle => 'Cheapest trip';

  @override
  String get refuelPlanFastestTitle => 'Fastest trip';

  @override
  String refuelPlanStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
      zero: 'No stop needed',
    );
    return '$_temp0';
  }

  @override
  String refuelPlanTotal(String cost, String perKm) {
    return '$cost total · $perKm/km';
  }

  @override
  String refuelPlanGap(String from, String to) {
    return 'No station in range between $from and $to';
  }

  @override
  String get refuelPlanNeedsConsumption =>
      'Add a few fill-ups and Sparkilo can plan your stops';

  @override
  String get refuelPlanNeedsTank =>
      'Set your tank size to plan refuelling stops';

  @override
  String get refuelPlanNeedsPrices =>
      'No station on this route has a price for your fuel';

  @override
  String get decisionConfidentLead => 'Best stop for you';

  @override
  String get decisionConfidentWhy =>
      'Open now, price from the last day, and measured on your own consumption';

  @override
  String get savingsTitle => 'Against your usual price';

  @override
  String savingsNet(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills',
      one: '1 fill',
    );
    return '$amount net over $_temp0';
  }

  @override
  String savingsReference(String price, String litres) {
    return 'Your usual: $price per litre, $litres per fill';
  }

  @override
  String get savingsNeedsHistory =>
      'A few more fill-ups and Sparkilo can tell you what you are saving';

  @override
  String criteriaMoreFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'More filters ($count)',
      zero: 'More filters',
    );
    return '$_temp0';
  }

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
  String get evPriceFree => 'Gratuito';

  @override
  String get evPricePayAtLocation => 'Pagar no local';

  @override
  String get evPriceMembership => 'Requer adesão';

  @override
  String get evPriceIndicative => 'Preço indicativo';

  @override
  String get evPriceDeclaredByOperator =>
      'Preço indicativo declarado pelo operador — verifique no local';

  @override
  String get evPriceFranceAttribution =>
      'Preços: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ';

  @override
  String get evPriceBestEffortOcm =>
      'Preços OpenChargeMap por melhor esforço — escassos e possivelmente incompletos.';

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
  String get edit => 'Editar';

  @override
  String get fuelPricesApiKey => 'Chave API preços de combustível';

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
  String get noStationsAlongThisRoute =>
      'Nenhum posto encontrado ao longo desta rota.';

  @override
  String get fuelCostCalculator => 'Calculadora de custo de combustível';

  @override
  String get distanceKm => 'Distância (km)';

  @override
  String get tripCost => 'Custo da viagem';

  @override
  String get fuelNeeded => 'Combustível necessário';

  @override
  String get totalCost => 'Custo total';

  @override
  String calculatorDistanceLabel(String unit) {
    return 'Distância ($unit)';
  }

  @override
  String calculatorConsumptionLabel(String unit) {
    return 'Consumo ($unit)';
  }

  @override
  String calculatorPriceLabel(String unit) {
    return 'Preço do combustível ($unit)';
  }

  @override
  String get calculatorUseMine => 'Usar';

  @override
  String get calculatorApplied => 'Aplicado';

  @override
  String get tripDetails => 'Detalhes da viagem';

  @override
  String get calculatorRoundTrip => 'Ida e volta';

  @override
  String get roundTripTotal => 'Ida e volta';

  @override
  String get costPerDistance => 'Custo por km';

  @override
  String get costPerMonth => 'Custo por mês';

  @override
  String get calculatorEstimateMonthly => 'Estimar custo mensal';

  @override
  String get calculatorTripsPerMonth => 'Viagens por mês';

  @override
  String get calculatorTripsPerMonthHint => 'ex.: 20';

  @override
  String get calculatorReset => 'Repor';

  @override
  String get calculatorResultPlaceholder =>
      'Preencha a distância, o consumo e o preço para ver o custo da viagem';

  @override
  String get priceHistory => 'Histórico de preços';

  @override
  String get favoritesDataCache => 'Dados de favoritos';

  @override
  String get citySearchCache => 'Pesquisa de cidade';

  @override
  String get noPriceHistory => 'Sem histórico de preços ainda';

  @override
  String get showAllFuelTypes => 'Mostrar todos os tipos de combustível';

  @override
  String get connected => 'Ligado';

  @override
  String get disconnectTankSync => 'Desligar TankSync';

  @override
  String get viewMyData => 'Ver os meus dados';

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
  String loyaltyCardDeleted(String card) {
    return 'Deleted $card';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get positionAgeUnderMinute => '< 1 min';

  @override
  String positionAgeHours(int hours) {
    return '$hours h';
  }

  @override
  String positionAgeDays(int days) {
    return '$days d';
  }

  @override
  String durationHoursMinutesCompact(int hours, String minutes) {
    return '${hours}h $minutes';
  }

  @override
  String durationSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get savedRoutesLoading => 'Loading your saved routes…';

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
  String activeCountryChangedTo(String country) {
    return 'Active country is now $country';
  }

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String aboutVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String referenceVehicleLoadFailed(String reason) {
    return 'Couldn\'t load the vehicle catalog: $reason';
  }

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
  String get gdprContinueAll => 'Continuar com tudo';

  @override
  String get gdprContinueSelected => 'Continuar com a seleção';

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
  String get privacySyncMode => 'Modo de sincronização';

  @override
  String get privacySyncUserId => 'ID de utilizador';

  @override
  String get privacySyncDescription =>
      'Quando a sincronização está ativada, favoritos, alertas, postos ignorados e avaliações também são guardados no servidor TankSync.';

  @override
  String get privacyExportSuccess =>
      'Dados exportados para a área de transferência';

  @override
  String get privacyExportCsvSuccess =>
      'Dados CSV exportados para a área de transferência';

  @override
  String get savedToDownloadsFolder => 'Guardado na pasta Transferências';

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
  String get voiceAnnouncementProximityRadius => 'Raio de anúncio';

  @override
  String get voiceAnnouncementCooldown => 'Intervalo de repetição';

  @override
  String get voiceAnnouncementPriceLimit => 'Preço máximo';

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
  String get qrPaymentUnknownBody =>
      'This isn\'t a payment code SparKilo knows — it may be a loyalty or receipt code, or a payment scheme we haven\'t added yet. Nothing is wrong with your scan.';

  @override
  String get qrPaymentUnknownAction =>
      'Report it and we\'ll try to add the scheme in a future release.';

  @override
  String get qrPaymentRawHeading => 'What the code contains';

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
  String get obdPermissionDenied =>
      'Conceda permissão de Bluetooth nas definições do sistema';

  @override
  String get obdPickerTitle => 'Escolher um adaptador OBD2';

  @override
  String get obdPickerScanning => 'A procurar adaptadores…';

  @override
  String get obdPickerConnecting => 'A ligar…';

  @override
  String get tripMetricDistance => 'Distância';

  @override
  String get tripMetricFuelUsed => 'Combustível usado';

  @override
  String get tripMetricAvgConsumption => 'Méd.';

  @override
  String get tripMetricElapsed => 'Tempo decorrido';

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
  String get vehicleBaselineShowDetails => 'Mostrar detalhe por situação';

  @override
  String get vehicleBaselineHideDetails => 'Ocultar detalhe por situação';

  @override
  String vehicleBaselineMissingWarning(String situations) {
    return 'Ainda não detetado: $situations. Estas situações de condução ainda têm 0 amostras, pelo que a linha de base está incompleta.';
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
  String get syncBaselinesToggleTitle =>
      'Partilhar perfis aprendidos do veículo';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Carregar referências de consumo por veículo para que um segundo dispositivo as possa reutilizar.';

  @override
  String get obd2StatusConnected => 'Adaptador OBD2: ligado';

  @override
  String get obd2StatusPermissionDenied =>
      'Adaptador OBD2: permissão de Bluetooth necessária';

  @override
  String get obd2StatusConnectedBody => 'Pronto para gravar uma viagem.';

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
  String get situationColdStart => 'Arranque a frio';

  @override
  String get situationSustainedLoad => 'Carga sustentada / reboque';

  @override
  String get situationPartialDecel => 'Desaceleração por inércia';

  @override
  String get situationHardAccel => 'Aceleração brusca';

  @override
  String get situationFuelCut => 'Corte de combustível — deslizar';

  @override
  String get tripSummaryAutoSaved => 'Viagem guardada automaticamente';

  @override
  String get tripSummaryDelete => 'Eliminar esta viagem';

  @override
  String get vehicleFuelNotSet => 'Não definido';

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
  String get vehiclePowerLabel => 'Potência do motor (kW)';

  @override
  String vehiclePowerHelper(String ps) {
    return '≈ $ps cv';
  }

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
  String get evStatusAvailable => 'Disponível';

  @override
  String get evStatusOccupied => 'Ocupado';

  @override
  String get evStatusOutOfOrder => 'Avariado';

  @override
  String get evStatusPartial => 'Parcialmente disponível';

  @override
  String get openOnlyFilter => 'Apenas abertos';

  @override
  String get saveAsDefaults => 'Guardar como predefinições';

  @override
  String get criteriaSavedToProfile => 'Guardado como predefinições';

  @override
  String get updatingFavorites => 'A atualizar os seus favoritos...';

  @override
  String get fetchingLatestPrices => 'A obter os preços mais recentes';

  @override
  String get noDataAvailable => 'Sem dados';

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
  String get sectionPrivacyData => 'Privacidade e dados';

  @override
  String get sectionAdvancedDeveloper => 'Avançado e programador';

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
  String get minimalDriveBehaviour => 'Estilo de condução';

  @override
  String get coachingShiftUp => 'Subir mudança';

  @override
  String get coachingShiftDown => 'Descer mudança';

  @override
  String get coachingEasePedal => 'Alivia o acelerador';

  @override
  String get coachingVoiceHardAcceleration => 'Devagar no acelerador';

  @override
  String get coachingVoiceHarshBraking => 'Tente travar com mais suavidade';

  @override
  String get coachingVoiceShiftUp =>
      'Mude para uma mudança superior para poupar combustível';

  @override
  String get coachingVoiceShiftDown =>
      'Mude para uma mudança inferior, o motor está a forçar';

  @override
  String get coachingVoiceEasePedal => 'Alivie o pedal para reduzir o consumo';

  @override
  String get coachingVoiceLiftOff =>
      'Levante o pé do acelerador e circule por inércia';

  @override
  String get coachingVoiceAnticipateBrake =>
      'Olhe mais à frente e levante o pé mais cedo';

  @override
  String get coachingVoiceSmoothAccel => 'Acelere de forma mais suave';

  @override
  String get coachingVoiceSharpCorner =>
      'Faça as curvas com um pouco mais de suavidade';

  @override
  String get coachingVoiceHarshBrakingStrong =>
      'Travagem muito brusca — deixe mais distância';

  @override
  String get coachingVoiceHardAccelerationStrong =>
      'Aceleração muito forte — isso gasta mesmo combustível';

  @override
  String get coachingVoiceSharpCornerStrong =>
      'Curva muito apertada — entre devagar, saia com suavidade';

  @override
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      harshCount,
      locale: localeName,
      other: '$harshCount manobras bruscas.',
      one: 'Uma manobra brusca.',
      zero: 'Suave e sem manobras bruscas.',
    );
    return 'Viagem guardada: $distanceKm quilómetros, $consumption. $_temp0';
  }

  @override
  String coachingVoiceConsumptionPhrase(String value) {
    return '$value litros aos 100 quilómetros';
  }

  @override
  String get voiceCoachingSettingTitle => 'Coaching de condução por voz';

  @override
  String get voiceCoachingSettingSubtitle =>
      'Ouça dicas em voz alta enquanto conduz — aceleração brusca, travagem forte e sugestões de mudança de velocidade';

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
  String get tankSyncSchemaOutdatedTitle =>
      'A base de dados na nuvem precisa de uma atualização';

  @override
  String get tankSyncSchemaOutdatedSubtitle =>
      'O seu esquema TankSync auto-alojado está desatualizado — alguns dados não conseguem sincronizar. Abra o assistente de sincronização e execute o SQL de atualização no seu projeto Supabase.';

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
  String get syncSchemaOutdated =>
      'O seu esquema TankSync está desatualizado — volte a executar o SQL de configuração abaixo para ativar as funcionalidades sincronizadas mais recentes.';

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
      'Base de dados partilhada gerida pelo programador — veja abaixo o que é sincronizado';

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
  String get yourRating => 'A sua avaliação';

  @override
  String get noStorageUsed => 'Sem armazenamento utilizado';

  @override
  String storageSegmentSemantics(String category, String size, int percent) {
    return '$category: $size, $percent% of the total';
  }

  @override
  String get aboutReportBug => 'Reportar um erro / Sugerir uma funcionalidade';

  @override
  String get aboutSupportProject => 'Apoiar este projeto';

  @override
  String get aboutSupportDescription =>
      'Esta aplicação é gratuita, de código aberto e sem anúncios. Se a achar útil, considere apoiar o programador.';

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
  String serviceReminderDueNowBody(String label) {
    return '$label está previsto para agora.';
  }

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
      'A gravar com GPS — OBD2 a reconectar';

  @override
  String get obd2GpsDegradedPassiveWaitingBanner =>
      'A gravar com GPS — à espera do adaptador OBD2';

  @override
  String get alertsStationSectionTitle => 'Alertas de postos';

  @override
  String get alertsStationAdd => 'Adicionar alerta de posto';

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
  String radiusAlertDeleted(String name) {
    return 'Alerta de raio \"$name\" eliminado';
  }

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 ligado: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Emparelhar um adaptador OBD2';

  @override
  String get fillUpSavedSnackbar => 'Abastecimento guardado';

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
  String stationSourceFlagTooltip(String country, String source) {
    return 'Prices from $country — $source';
  }

  @override
  String get decisionBestValue => 'Best value';

  @override
  String get decisionCheapest => 'Cheapest';

  @override
  String get decisionClosest => 'Closest';

  @override
  String get decisionReasonBestValue => 'Best balance of price and detour';

  @override
  String decisionReasonSaves(String amount, String volume, String distance) {
    return 'Saves $amount on $volume · $distance more driving';
  }

  @override
  String decisionReasonBreakEven(String volume) {
    return 'Only worth the detour from $volume up';
  }

  @override
  String get decisionValueUnavailable =>
      'Record a fill-up and the detour can be priced, not just the pump';

  @override
  String decisionShowAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show all $count stations',
      one: 'Show the one station',
    );
    return '$_temp0';
  }

  @override
  String decisionAssumption(String consumption, String volume) {
    return 'Based on $consumption and $volume';
  }

  @override
  String get priceFreshnessFresh => 'Fresh price';

  @override
  String get priceFreshnessRecent => 'Recent price';

  @override
  String get priceFreshnessAging => 'Aging price';

  @override
  String get priceFreshnessStale => 'Old price';

  @override
  String get priceFreshnessUnknown => 'Price age unknown';

  @override
  String priceFreshnessTooltip(String band, String stamp) {
    return '$band · $stamp';
  }

  @override
  String get priceLabel => 'Price';

  @override
  String get priceFreshnessLabel => 'Price freshness';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get availabilityNotReported => 'Not reported';

  @override
  String get refuelQuantityTitle => 'How much do you usually buy?';

  @override
  String get refuelQuantityExplainer =>
      'Best value compares what a refuel really costs, so it needs a rough volume. Sparkilo uses the median of your own fill-ups until you say otherwise.';

  @override
  String get refuelQuantityMeasured => 'Use my fill-up history';

  @override
  String get refuelQuantityFullTank => 'A full tank';

  @override
  String get refuelQuantityChange => 'Change';

  @override
  String refuelQuantityMeasuredValue(String volume) {
    return '$volume (from your fill-ups)';
  }

  @override
  String refuelConsumptionMeasured(String consumption) {
    return '$consumption (measured)';
  }

  @override
  String get refuelConsumptionMissing => 'No consumption yet';

  @override
  String get mapSheetViewDetails => 'View station details';

  @override
  String get startupFailureTitle => 'Sparkilo couldn\'t start';

  @override
  String get startupFailureMessage =>
      'Sparkilo could not finish starting up. Your saved data has not been touched.';

  @override
  String get startupFailureGuidance =>
      'Close the app and open it again. If it keeps happening, check for an update: this is almost always a fault in the app rather than in your data. Do not clear the app\'s storage — that would delete your favourites and history without fixing anything.';

  @override
  String priceIsForFuel(String fuel) {
    return 'This price is for $fuel — not the fuel you selected, which this station does not sell';
  }

  @override
  String get shellSwipeCoachMark =>
      'Swipe down to hide the bars and use the whole screen';

  @override
  String get shellBarHiddenAnnounce =>
      'Navigation hidden. Swipe up from the bottom, or long-press the button, to bring it back.';

  @override
  String get shellBarShownAnnounce => 'Navigation shown.';

  @override
  String get shellBarToggleHint => 'Long-press to hide or show the navigation';

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
  String get obd2ErrorEngineOff =>
      'Sem dados do veículo — ligue o motor e tente novamente.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'O adaptador OBD2 enviou uma resposta não reconhecida. Pode ser incompatível — experimente outro adaptador.';

  @override
  String get obd2ErrorDisconnected =>
      'O adaptador OBD2 desligou-se. Volte a ligar e tente novamente.';

  @override
  String get obd2ErrorPairingRequired =>
      'O adaptador precisa de emparelhamento Bluetooth. Desligue o adaptador, volte a ligá-lo e tente novamente dentro de 5 minutos.';

  @override
  String get onboardingExploreDemoData => 'Explorar com dados de demonstração';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpOpenGuide => 'Open the guide';

  @override
  String helpUnavailable(String asset) {
    return 'The guide could not be loaded ($asset).';
  }

  @override
  String get linkDeviceInvalidCode => 'Please enter a valid device code';

  @override
  String linkDeviceFailed(String error) {
    return 'Link failed: $error';
  }

  @override
  String linkDeviceLinked(
    int favorites,
    int alerts,
    int vehicles,
    int fillUps,
  ) {
    return 'Linked! Imported $favorites favourites, $alerts alerts, $vehicles vehicles, $fillUps fill-ups.';
  }

  @override
  String syncConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get showFewerFuelTypes => 'Show fewer fuel types';

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
  String get alertsNotificationsOffTitle => 'Notifications are off';

  @override
  String get alertsNotificationsOffPermissionBody =>
      'Your price alerts are still checked, but they can\'t notify you: notifications for this app are turned off in your phone\'s settings.';

  @override
  String get alertsNotificationsOffChannelBody =>
      'Your price alerts are still checked, but they can\'t notify you: price alert notifications are turned off in your phone\'s settings.';

  @override
  String get alertsNotificationsOffOpenSettings => 'Open settings';

  @override
  String alertReasonNetSaving(String amount) {
    return 'About $amount on your usual fill';
  }

  @override
  String alertReasonBelowThreshold(String delta) {
    return '$delta/L below the price you set';
  }

  @override
  String alertReasonBelowYourMedian(String delta) {
    return '$delta/L below what you usually pay';
  }

  @override
  String alertReasonBelowLocalMedian(String delta) {
    return '$delta/L below the local average';
  }

  @override
  String alertReasonBelowEarlier(String delta) {
    return '$delta/L cheaper than earlier';
  }

  @override
  String alertReasonBelowCheapestOnRoute(String delta) {
    return '$delta/L below the best on your route';
  }

  @override
  String alertReasonBelowCheapestNearby(String delta) {
    return '$delta/L below the best nearby';
  }

  @override
  String alertReasonDistance(String distance) {
    return '$distance away';
  }

  @override
  String alertReasonPriceAge(String age) {
    return 'Price updated $age ago';
  }

  @override
  String get alertReasonPriceAgeUnknown =>
      'This data source doesn\'t say when the price was set';

  @override
  String get alertReasonSourceMedium =>
      'This country\'s data refreshes less often';

  @override
  String get alertReasonSourceLow =>
      'This country\'s data is incomplete or slow to refresh';

  @override
  String get alertConfidenceMediumPrefix => 'Potential saving';

  @override
  String alertsLastChecked(String when) {
    return 'Última verificação: $when';
  }

  @override
  String get alertsLastCheckedNever =>
      'Os preços ainda não foram verificados em segundo plano';

  @override
  String get alertsIosBestEffortNote =>
      'No iPhone, a verificação de alertas é feita da melhor forma possível: o iOS decide quando a app pode verificar preços em segundo plano, pelo que um alerta pode chegar atrasado ou, ocasionalmente, não chegar. Abrir a app executa sempre uma verificação nova.';

  @override
  String alertTargetPriceWithCurrency(String currency) {
    return 'Preço-alvo ($currency)';
  }

  @override
  String alertThresholdWithCurrency(String currency) {
    return 'Limite ($currency/L)';
  }

  @override
  String get alertsEmptyTitle => 'No price alerts yet';

  @override
  String get alertsEmptySubtitle =>
      'Get notified when a station, or any station in a zone, drops below your target price.';

  @override
  String get favoritesLoadErrorTitle => 'Favorites';

  @override
  String allPricesEstimatedCost(String cost) {
    return '≈ $cost';
  }

  @override
  String allPricesCellEstimatedSemantics(
    String fuel,
    String price,
    String cost,
    String consumption,
  ) {
    return '$fuel $price, about $cost per 100 km, estimated at $consumption from your vehicle\'s measured consumption and the fuel\'s energy content';
  }

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
  String fuelStationRadarProximity(int percent) {
    return 'Proximidade $percent%';
  }

  @override
  String get pipTapToRestore => 'Toque para abrir a app completa';

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
  String get authLinkEmailTitle => 'Associar um e-mail';

  @override
  String get authLinkEmailSubtitle =>
      'Associe um e-mail para sincronizar os seus dados entre dispositivos. Os seus favoritos e viagens atuais permanecem nesta conta.';

  @override
  String authGuestLinkPrompt(String idPrefix) {
    return 'Está a usar uma conta de convidado ($idPrefix…). Associe um e-mail para sincronizar os seus favoritos e viagens com os seus outros dispositivos.';
  }

  @override
  String get authConfirmationPending =>
      'Quase pronto — consulte o seu e-mail e toque na ligação para concluir a associação. Os seus dados já estão guardados nesta conta.';

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
  String get aclWakeNotificationTitle => 'Carro ligado';

  @override
  String get aclWakeNotificationBody =>
      'Toque para abrir o Sparkilo — a gravação da viagem pode começar.';

  @override
  String get exportBackupReady =>
      'Cópia de segurança pronta — escolha um destino';

  @override
  String get exportBackupFailed =>
      'Falha na exportação da cópia de segurança — tente novamente';

  @override
  String get backupExportProgress => 'A exportar a sua cópia de segurança…';

  @override
  String exportBackupSavedAs(String fileName) {
    return 'Guardado em Transferências como $fileName';
  }

  @override
  String get restoreBackupDialogTitle => 'Restaurar cópia de segurança';

  @override
  String get restoreBackupDialogBody =>
      'A fusão adiciona e atualiza registos da cópia de segurança e mantém tudo o que já está neste dispositivo. Substituir apaga todos os dados atuais primeiro e depois restaura apenas a cópia de segurança — esta ação não pode ser revertida.';

  @override
  String get restoreBackupMergeAction => 'Fundir';

  @override
  String get restoreBackupReplaceAction => 'Substituir tudo';

  @override
  String get restoreBackupEmpty =>
      'Cópia de segurança restaurada — não continha registos';

  @override
  String get restoreBackupCorrupt =>
      'Restauro falhado — este ficheiro não é uma cópia de segurança Tankstellen válida';

  @override
  String get restoreBackupFailed =>
      'Restauro falhado — não foi possível ler o ficheiro';

  @override
  String get backupImportProgress => 'A restaurar a sua cópia de segurança…';

  @override
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Fundidos $vehicles veículos, $fillUps abastecimentos, $trips viagens, $chargingLogs registos de carregamento';
  }

  @override
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  ) {
    return 'Todos os dados substituídos por $vehicles veículos, $fillUps abastecimentos, $trips viagens, $chargingLogs registos de carregamento';
  }

  @override
  String get brokenMapChipDisclaimer => 'Leituras MAP suspeitas';

  @override
  String get brokenMapSnackbarUnreliable =>
      'O sensor MAP lê incorretamente — as leituras de combustível podem estar 50–80% abaixo do real. Tente um adaptador diferente.';

  @override
  String get brokenMapBannerHardDisable =>
      'Sensor MAP não fiável. A mostrar médias de abastecimento em vez de caudal em tempo real.';

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
  String get brokenMapDiagnosticsExplainer =>
      'Live fuel use is worked out from the engine air-pressure reading (the MAP sensor) your car reports over OBD2. Some adapters report it wrong, which makes live fuel use look far too low — when that happens SparKilo shows your fill-up averages instead.';

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
  String get calibrationDirectFuelRateNote =>
      'Este veículo comunica diretamente o caudal de combustível (PID 5E), pelo que a calibração da eficiência volumétrica não é usada — o seu consumo é medido, não modelado.';

  @override
  String get carbonCo2ScopeWellToWheel => 'Well-to-wheel';

  @override
  String carbonCo2FactorSource(String source) {
    return 'Factors: $source';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'O seu $makeModel está marcado como diesel mas corresponde a uma entrada de catálogo de gasolina. Toque para atualizar.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Atualizar';

  @override
  String get catalogResetAction =>
      'Repor a partir da base de dados de veículos';

  @override
  String get catalogResetConfirmTitle =>
      'Repor a partir da base de dados de veículos?';

  @override
  String catalogResetConfirmBody(String vehicle) {
    return 'Substitui a capacidade do depósito, a potência e a cilindrada deste veículo pelos valores da base de dados para $vehicle. Os restantes campos e o seu histórico de abastecimentos não são alterados.';
  }

  @override
  String get catalogResetNoMatchSnackbar =>
      'Não há nenhuma entrada correspondente a este veículo na base de dados.';

  @override
  String get catalogResetDoneSnackbar =>
      'Dados do veículo repostos a partir da base de dados.';

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
  String get chargingLogDeletedUndoSnackbar => 'Charging session deleted';

  @override
  String get confirmDeleteTitle => 'Eliminar?';

  @override
  String get confirmDeleteBody => 'Quer mesmo eliminar isto?';

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
  String get consoGroupVehicles => 'Veículos';

  @override
  String get consoGroupCoaching => 'Coaching durante a condução';

  @override
  String get consoGroupRewards => 'Recompensas e poupanças';

  @override
  String get consoGroupTroubleshooting => 'Resolução de problemas';

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
  String get moreActionsTooltip => 'Mais';

  @override
  String get exportBackupMenuLabel => 'Exportar cópia de segurança';

  @override
  String get restoreBackupMenuLabel => 'Restaurar cópia de segurança';

  @override
  String get carbonDashboardMenuLabel => 'Painel de carbono';

  @override
  String get settingsMenuLabel => 'Definições';

  @override
  String get consumptionMetricLitres => 'Litres';

  @override
  String get consumptionMetricSpend => 'Spend';

  @override
  String get consumptionMetricPricePerLitre => 'Price/L';

  @override
  String get consumptionMetricPerHundred => 'L/100 km';

  @override
  String get consumptionStatsPageTitle => 'Estatísticas de consumo';

  @override
  String get consumptionStatsComparisonTitle => 'Este mês vs mês passado';

  @override
  String get consumptionStatsTrendsTitle => 'Evolução ao longo do tempo';

  @override
  String get consumptionStatsNeedTwoMonths =>
      'Registe abastecimentos em pelo menos dois meses para comparar.';

  @override
  String get consumptionStatsPricePerLiter => 'Preço médio/L';

  @override
  String consumptionStatsDeltaPercent(String pct) {
    return '$pct%';
  }

  @override
  String get consumptionStatsChartLiters => 'Litros por mês';

  @override
  String get consumptionStatsChartSpend => 'Despesa por mês';

  @override
  String get consumptionStatsChartPricePerLiter => 'Preço por litro';

  @override
  String get consumptionStatsChartConsumption => 'L/100km por mês';

  @override
  String get fuelCompareSectionTitle =>
      'Custo de circular, combustível a combustível';

  @override
  String get fuelComparePricePerLitre => 'Pago por litro';

  @override
  String get fuelCompareCostPer100km => 'Custo por 100 km';

  @override
  String get fuelCompareDistance => 'Distância medida';

  @override
  String get fuelCompareLitres => 'Litros consumidos';

  @override
  String fuelCompareVerdictCheaper(String winner) {
    return 'O $winner é o seu combustível mais barato para circular';
  }

  @override
  String fuelCompareVerdictDelta(String loser, String amount) {
    return 'O $loser custa mais $amount por cada 1000 km';
  }

  @override
  String fuelCompareBreakEven(String fuel, String rival, String price) {
    return 'O $fuel bate o $rival abaixo de $price por litro';
  }

  @override
  String get fuelCompareBreakEvenExplain =>
      'O ponto de equilíbrio é calculado a partir do consumo medido de cada combustível, por isso muda conforme a sua condução.';

  @override
  String get fuelCompareLitresVsCostNote =>
      'Litros e custo podem divergir: um combustível pode gastar menos litros aos 100 km e ainda assim custar mais por quilómetro, porque o preço na bomba é diferente. O que decide é o custo por quilómetro.';

  @override
  String fuelCompareProvisional(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depósitos cheios',
      one: 'um depósito cheio',
    );
    return 'Provisório — com base em $_temp0';
  }

  @override
  String fuelCompareBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depósitos cheios',
      one: 'um depósito cheio',
    );
    return 'Com base em $_temp0';
  }

  @override
  String get fuelCompareCo2Per100km => 'CO2 por 100 km';

  @override
  String fuelCompareCleanest(String winner) {
    return 'O $winner é o seu combustível com menos emissões';
  }

  @override
  String fuelCompareTradeoff(String fuel, String money, String co2) {
    return 'O $fuel custa mais $money por 1000 km mas emite menos $co2 de CO2';
  }

  @override
  String fuelCompareTradeoffBoth(String fuel, String rival) {
    return 'O $fuel é ao mesmo tempo mais barato e mais limpo do que o $rival';
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
    return 'Os seus $distance com $fuel emitiram $actual em vez de $alternative com $rival — $saved evitados';
  }

  @override
  String get fuelCompareCo2Source =>
      'Os valores de CO2 são estimativas do poço à roda (EU JEC WTW v5) aplicadas ao seu consumo medido — servem de orientação, não são uma contabilidade certificada.';

  @override
  String get fuelCompareCo2BlendOmitted =>
      'O CO2 só é apresentado para combustíveis puros: o fator de emissão de uma mistura depende da composição, que esta linha não regista.';

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
    return 'Correções: +$liters L';
  }

  @override
  String get contentModerationReportAction => 'Denunciar conteúdo';

  @override
  String get contentModerationBlockAction => 'Bloquear autor';

  @override
  String get contentModerationReportDialogTitle => 'Denunciar este conteúdo?';

  @override
  String get contentModerationReportDialogBody =>
      'É enviada uma denúncia ao seu servidor TankSync para análise e este conteúdo fica oculto no seu dispositivo.';

  @override
  String get contentModerationReportConfirmButton => 'Denunciar';

  @override
  String get contentModerationBlockDialogTitle => 'Bloquear este autor?';

  @override
  String get contentModerationBlockDialogBody =>
      'Tudo o que esta conta partilhar consigo ficará oculto neste dispositivo.';

  @override
  String get contentModerationBlockConfirmButton => 'Bloquear';

  @override
  String get contentModerationReportedSnack =>
      'Denúncia enviada — conteúdo oculto.';

  @override
  String get contentModerationReportFailedSnack =>
      'Não foi possível enviar a denúncia. Tente novamente.';

  @override
  String get contentModerationBlockedSnack =>
      'Autor bloqueado — o conteúdo partilhado por ele está oculto.';

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
  String crossBorderCheaper(String country, String km, String price) {
    return 'Postos em $country a $km km — €$price/L mais barato';
  }

  @override
  String get crossBorderTapToSwitch => 'Toque para mudar de país';

  @override
  String get crossBorderDismissTooltip => 'Ignorar';

  @override
  String dataSourceLinkSemantic(String source, String license) {
    return 'Abrir a fonte de dados $source ($license) no browser';
  }

  @override
  String mapAttributionOsm(String brand) {
    return '© contribuidores $brand';
  }

  @override
  String dataApproximate(String value) {
    return '≈ $value';
  }

  @override
  String dataStale(String value, String age) {
    return '$value ($age old)';
  }

  @override
  String dataLastSeen(String age) {
    return 'Last seen $age ago';
  }

  @override
  String get dataUnknownProvider => 'This data source doesn\'t publish it';

  @override
  String get dataUnknownItem => 'Not published for this station';

  @override
  String get dataUnknownNotMeasured => 'Not measured yet';

  @override
  String get dataUnknownVehicle => 'Missing from your vehicle';

  @override
  String get dataUnknownUnreadable =>
      'The data source sent something unreadable';

  @override
  String get dataBasisCatalog => 'Manufacturer figure';

  @override
  String get dataBasisFleetAverage => 'Class average';

  @override
  String get dataBasisDerived => 'Derived from other figures';

  @override
  String get decisionLeadCaveatHours =>
      'opening hours aren\'t published for this country';

  @override
  String get decisionLeadCaveatPriceAge =>
      'this source doesn\'t say when the price was set';

  @override
  String get decisionLeadCaveatSeparator => ' · ';

  @override
  String get developerToolsSectionTitle => 'Ferramentas de programador';

  @override
  String get dataAccessTracerExport => 'Exportar registo de acesso a dados';

  @override
  String get dataAccessTracerExportSuccess =>
      'Registo de acesso a dados guardado em Transferências.';

  @override
  String get dataAccessTracerExportFailure =>
      'Não foi possível exportar o registo de acesso a dados.';

  @override
  String get dataAccessTracerEmpty =>
      'Ainda não há eventos de acesso a dados registados — pesquise ou abra postos primeiro e depois exporte.';

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
      'Procure postos primeiro e depois execute o alerta de teste para que a notificação possa abrir um posto real.';

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
  String get startupTraceSectionTitle => 'Registo de inicialização no arranque';

  @override
  String get startupTraceExportButton => 'Exportar registo de arranque';

  @override
  String get startupTraceEmpty => 'Ainda não há nenhum registo de arranque.';

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
      'Registo de arranque guardado em Transferências.';

  @override
  String get startupTraceExportFailure =>
      'Não foi possível exportar o registo de arranque.';

  @override
  String get distanceSourceOdometer => 'Conta-quilómetros';

  @override
  String get distanceSourceOdometerTooltip =>
      'Distância lida no conta-quilómetros do carro — uma referência medida.';

  @override
  String get distanceSourceGps => 'Trajeto GPS';

  @override
  String get distanceSourceGpsTooltip =>
      'Distância somada a partir do trajeto GPS gravado — a verdadeira distância por estrada.';

  @override
  String get distanceSourceEstimated => 'Estimada';

  @override
  String get distanceSourceEstimatedTooltip =>
      'Distância integrada a partir do sensor de velocidade — uma estimativa; o sensor costuma ler ligeiramente por excesso.';

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
    return 'Aceleração total ($pctTime% da viagem): desperdiçou $liters L';
  }

  @override
  String get lessonAdviceFullThrottle =>
      'Prima o acelerador de forma gradual — uma pressão suave de 70 % acelera com muito menos combustível.';

  @override
  String insightLambdaEnrichment(String pctTime, String liters) {
    return 'Mistura rica sob carga ($pctTime% da viagem): desperdiçou $liters L';
  }

  @override
  String get lessonAdviceLambdaEnrichment =>
      'Uma carga pesada e sustentada faz o motor funcionar com mistura rica — mude de velocidade cedo e reduza a carga em subidas longas para manter a mistura magra.';

  @override
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  ) {
    return 'Subida a $gradePercent% de inclinação ($pctTime% da viagem): desperdiçou $liters L';
  }

  @override
  String get lessonAdviceClimbingCost =>
      'Leve impulso para a subida e pressione o acelerador de forma suave — acelerar num sobe consome combustível extra.';

  @override
  String insightRestartCost(String count, String liters) {
    return '$count arranques parado-andar: desperdiçou $liters L';
  }

  @override
  String get lessonAdviceRestartCost =>
      'Antecipe o trânsito e aproxime-se das paragens por inércia para rolar em vez de arrancar — partir do ponto morto é a parte que mais consome no stop-and-go.';

  @override
  String lessonCombustionHealthLeanBorderline(String pctTrim) {
    return 'A mistura parece um pouco pobre — o motor adicionou combustível (correção de $pctTrim %) para compensar';
  }

  @override
  String lessonCombustionHealthLeanMarked(String pctTrim) {
    return 'A mistura parece pobre — o motor manteve uma adição de combustível elevada de $pctTrim %, uma possível ineficiência';
  }

  @override
  String lessonCombustionHealthRichBorderline(String pctTrim) {
    return 'A mistura parece um pouco rica — o motor retirou combustível (correção de $pctTrim %) para compensar';
  }

  @override
  String lessonCombustionHealthRichMarked(String pctTrim) {
    return 'A mistura parece rica — o motor manteve um corte de combustível elevado de $pctTrim %, uma possível ineficiência';
  }

  @override
  String lessonCombustionHealthEnrichment(String pctShare) {
    return 'O motor andou rico sob carga ($pctShare % da condução a quente) — possível combustível desperdiçado';
  }

  @override
  String get lessonCombustionHealthSubtitle =>
      'Sinal heurístico de saúde, não um diagnóstico';

  @override
  String get lessonAdviceCombustionHealthLean =>
      'Uma correção prolongada para mistura pobre pode indicar uma entrada de ar na admissão, um fornecimento de combustível fraco ou um sensor envelhecido. Se o consumo ou o funcionamento piorarem, um diagnóstico em oficina pode confirmar.';

  @override
  String get lessonAdviceCombustionHealthRich =>
      'Uma correção prolongada para mistura rica pode indicar um injetor com fuga, pressão de combustível elevada ou um sensor a ler por excesso. Se o consumo ou o funcionamento piorarem, um diagnóstico em oficina pode confirmar.';

  @override
  String get lessonAdviceCombustionHealthEnrichment =>
      'Andar com mistura rica sob carga elevada gasta combustível extra. Suba de mudança mais cedo e alivie o pé nas acelerações longas para que o motor se mantenha perto de uma mistura estequiométrica.';

  @override
  String get lessonTransportTitle =>
      'Dados do motor em falta na maior parte desta viagem';

  @override
  String get lessonTransportAdvice =>
      'O motor não reportou atividade em quase toda a distância. Ou o fluxo OBD2 falhou a meio da viagem, ou o carro foi deslocado sem ser conduzido — o valor de consumo não é fiável e fica excluído das suas estatísticas.';

  @override
  String insightHighRpmShare(String pctTime) {
    return 'Engine over 3000 RPM ($pctTime% of trip)';
  }

  @override
  String insightHardAccelEvents(String count) {
    return '$count hard accelerations';
  }

  @override
  String insightIdlingLong(String minutes) {
    return 'Long idling with the engine running ($minutes min)';
  }

  @override
  String insightFullThrottleShare(String pctTime) {
    return 'Full throttle ($pctTime% of trip)';
  }

  @override
  String insightLambdaEnrichmentShare(String pctTime) {
    return 'Rich mixture under load ($pctTime% of trip)';
  }

  @override
  String insightClimbingShare(String gradePercent, String pctTime) {
    return 'Climbing at $gradePercent% grade ($pctTime% of trip)';
  }

  @override
  String insightRestartEvents(String count) {
    return '$count stop-and-go restarts';
  }

  @override
  String insightTrailingLitersApprox(String liters) {
    return '≈ +$liters L';
  }

  @override
  String get drivingPatternComparisonTitle => 'Driving patterns';

  @override
  String get drivingPatternComparisonSubtitle =>
      'What was observed at the wheel, with the driving each figure rests on.';

  @override
  String get drivingPatternNotFuelNote =>
      'Behaviour observations only. No litres and no money are attributed to them here — that would need its own validated comparison.';

  @override
  String get drivingPatternInsufficient =>
      'Not enough recorded driving to compare patterns yet.';

  @override
  String drivingPatternMatchedOn(String criteria) {
    return 'Matched on: $criteria';
  }

  @override
  String get drivingPatternUnmatchedNotice =>
      'No trip conditions in common, so the figures below are descriptive observations over unequal routes.';

  @override
  String drivingPatternMatchCounts(int matched, int unmatched) {
    return '$matched trips matched, $unmatched outside the matched conditions';
  }

  @override
  String drivingPatternUnassignedExcluded(int count) {
    return '$count recorded trips belong to no vehicle and are counted for none.';
  }

  @override
  String get drivingPatternNoAdjustedRanking =>
      'No condition-adjusted ranking: expected consumption per trip is not recorded, so route, terrain and traffic cannot be taken out of these figures.';

  @override
  String get drivingPatternContextNote =>
      'A higher figure here can be the road rather than the driver — necessary braking, a climb, or an engine that simply turns faster.';

  @override
  String get drivingPatternDifferencesTitle => 'Largest observed differences';

  @override
  String drivingPatternDifferenceLine(
    String measure,
    String higher,
    String higherVehicle,
    String lower,
    String lowerVehicle,
  ) {
    return '$measure: $higher for $higherVehicle, $lower for $lowerVehicle';
  }

  @override
  String get drivingPatternUnavailableNoSignal =>
      'Not recorded — these trips carry no such signal';

  @override
  String get drivingPatternUnavailableTooLittle =>
      'Too little driving to state a figure';

  @override
  String drivingMeasureEventsPer100Km(String value) {
    return '$value per 100 km';
  }

  @override
  String drivingMeasureSharePercent(String value) {
    return '$value %';
  }

  @override
  String drivingPatternEvidenceCaption(
    String numerator,
    String denominator,
    int trips,
  ) {
    return '$numerator over $denominator · $trips trips';
  }

  @override
  String drivingPatternCountEvents(String count) {
    return '$count events';
  }

  @override
  String drivingPatternCountMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String drivingPatternCountKm(String km) {
    return '$km km';
  }

  @override
  String get drivingMeasureHardAccelRate => 'Hard accelerations';

  @override
  String get drivingMeasureFullThrottleShare => 'Full-throttle time';

  @override
  String get drivingMeasureHardBrakeRate => 'Hard braking';

  @override
  String get drivingMeasureAvoidableBrakeShare => 'Avoidable hard braking';

  @override
  String get drivingMeasureEngineIdleShare => 'Engine idling';

  @override
  String get drivingMeasureHighRpmShare => 'High engine speed';

  @override
  String get drivingMeasureSustainedHighSpeedShare => 'Sustained high speed';

  @override
  String get drivingMeasureEnergyOscillationRate =>
      'Accelerate and brake cycles';

  @override
  String get drivingMeasureCoastingFuelCutShare => 'Coasting without fuel';

  @override
  String get drivingMeasureLateCurveShare => 'Late braking into curves';

  @override
  String get drivingMeasureClimbFullThrottleShare => 'Full throttle climbing';

  @override
  String get drivingMeasureFlatFullThrottleShare => 'Full throttle on the flat';

  @override
  String get drivingPatternQualUncontrolled => 'conditions not controlled';

  @override
  String get drivingPatternQualPartialConditions =>
      'only cold starts were evaluated';

  @override
  String get drivingPatternQualUnequalEvidence =>
      'very unequal amounts of evidence';

  @override
  String get drivingPatternQualExcluded => 'some records were excluded';

  @override
  String get drivingPatternBandShort => 'trips under 5 km';

  @override
  String get drivingPatternBandMedium => 'trips of 5 to 30 km';

  @override
  String get drivingPatternBandLong => 'trips over 30 km';

  @override
  String get drivingPatternStartCold => 'cold start';

  @override
  String get drivingPatternStartWarm => 'warm start';

  @override
  String get drivingPatternStartUnknown => 'start temperature not recorded';

  @override
  String drivingPatternCohortLabel(String band, String start) {
    return '$band, $start';
  }

  @override
  String drivingPatternMeasureSemantics(
    String measure,
    String vehicle,
    String value,
    String evidence,
  ) {
    return '$measure for $vehicle: $value, $evidence';
  }

  @override
  String drivingPatternUnavailableSemantics(
    String measure,
    String vehicle,
    String reason,
  ) {
    return '$measure for $vehicle: $reason';
  }

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
  String get drivingScoreClassVeryGood => 'Muito bom';

  @override
  String get drivingScoreClassGood => 'Bom';

  @override
  String get drivingScoreClassAverage => 'Razoável';

  @override
  String get drivingScoreClassBad => 'A melhorar';

  @override
  String get drivingScorePenaltyLugging => 'Motor a puxar';

  @override
  String get drivingScorePenaltySmoothness => 'Condução brusca';

  @override
  String get drivingScorePenaltyHighSpeed => 'Alta velocidade';

  @override
  String get drivingScorePenaltyPedalVelocity => 'Pedal agressivo';

  @override
  String get drivingScorePenaltyLambda => 'Mistura rica';

  @override
  String get gpsKpiCardTitle => 'Eficiência GPS';

  @override
  String get gpsKpiRpa => 'Aceleração positiva (RPA)';

  @override
  String get gpsKpiPke => 'Procura de energia cinética (PKE)';

  @override
  String get gpsKpiVapos => 'Intensidade de aceleração (VAPOS)';

  @override
  String get gpsKpiCoast => 'Quota de inércia';

  @override
  String get gpsKpiClimbEnergy => 'Energia de subida';

  @override
  String drivingScoreBaselineDelta(String pct) {
    return '$pct vs a sua linha de base eficiente';
  }

  @override
  String get drivingTraceCardTitle => 'Rastreio de análise de condução (dev)';

  @override
  String get drivingTraceCardBody =>
      'Exporte os KPIs GPS desta viagem, pontuação e lições como JSON, escreva como a condução realmente se sentiu no campo de comentários, e partilhe-o de volta para que os limiares do estilo de condução possam ser calibrados com viagens reais.';

  @override
  String get drivingTraceExportAction => 'Exportar rastreio de análise';

  @override
  String get drivingTraceExported =>
      'Rastreio de análise guardado em Transferências — adicione o seu veredicto no campo de comentários e partilhe-o de volta.';

  @override
  String get drivingTraceExportFailed =>
      'Não foi possível exportar o rastreio de análise.';

  @override
  String get minimalDriveTripAverage => 'Média da viagem';

  @override
  String insightUpshiftCruise(String pctTime, String liters) {
    return 'Cruzeiro a rotações altas ($pctTime % da viagem): subir de mudança mais cedo poderia poupar $liters L';
  }

  @override
  String get lessonAdviceUpshiftCruise =>
      'Suba de mudança mais cedo em cruzeiro — a mesma velocidade a rotações mais baixas gasta claramente menos.';

  @override
  String insightCoastingFuelCut(String pctTime, String liters) {
    return 'A rolar com corte de injeção ($pctTime % da viagem): poupou cerca de $liters L';
  }

  @override
  String get lessonAdviceCoastingFuelCut =>
      'Bem antecipado — aliviar o pé cedo deixa o motor cortar completamente a injeção enquanto rola.';

  @override
  String insightTrailingLitersSaved(String liters) {
    return '−$liters L';
  }

  @override
  String get fuelBreakdownTitle => 'Para onde foi o seu combustível';

  @override
  String get fuelBreakdownIdle => 'Ralenti';

  @override
  String get fuelBreakdownHarshAccel => 'Acelerações fortes';

  @override
  String get fuelBreakdownHighRpmCruise => 'Cruzeiro a rotações altas';

  @override
  String get fuelBreakdownCoastingSaved => 'Poupado em ponto-morto';

  @override
  String get fuelBreakdownEfficient => 'Condução normal';

  @override
  String fuelBreakdownLiters(String liters) {
    return '$liters L';
  }

  @override
  String get ecoNudgeIdle =>
      'Ao ralenti há algum tempo — desligar o motor poupa combustível';

  @override
  String get ecoNudgeHarshAccel =>
      'Aceleração forte — um pé mais leve poupa combustível';

  @override
  String get ecoNudgeHighRpm =>
      'Rotações altas em cruzeiro — subir de mudança mais cedo poupa combustível';

  @override
  String insightUpshiftCruiseShare(String pctTime) {
    return 'High-RPM cruising ($pctTime% of trip): shifting up earlier uses less fuel';
  }

  @override
  String get obd2CoverageNoneNote =>
      'Não chegaram dados do motor do adaptador OBD2 nesta viagem — os valores de combustível são estimativas por GPS.';

  @override
  String obd2CoverageDroppedNote(int percent) {
    return 'Os dados do motor pararam aos $percent % da viagem (ligação perdida) — os valores de combustível a partir daí são estimativas por GPS.';
  }

  @override
  String obd2CoveragePartialNote(int percent) {
    return 'Os dados do motor cobriram apenas $percent % desta viagem — as falhas usam estimativas por GPS.';
  }

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
  String get featureLabel_approachOverlay => 'Radar de Postos de Combustível';

  @override
  String get featureDescription_approachOverlay =>
      'Transforma o mosaico de viagem flutuante num Radar de Postos de Combustível ao vivo — ao aproximar-se de um posto, o mosaico muda para a cor do combustível e mostra o preço.';

  @override
  String get featureLabel_voiceAnnouncements => 'Anúncios por voz';

  @override
  String get featureDescription_voiceAnnouncements =>
      'Anuncie em voz alta os postos de combustível baratos próximos enquanto conduz, para poder manter os olhos na estrada.';

  @override
  String get featureBlockedEnable_voiceAnnouncements =>
      'Ative primeiro o Radar de Postos de Combustível';

  @override
  String get featureGroupTitle_finding => 'Pesquisa e mapa';

  @override
  String get featureGroupDescription_finding =>
      'Onde abastecer ou carregar — pesquisa, mapa, rotas.';

  @override
  String get featureGroupTitle_prices => 'Preços e alertas';

  @override
  String get featureGroupDescription_prices =>
      'Descidas de preço, histórico e denúncias.';

  @override
  String get featureGroupTitle_radar => 'Radar de Postos de Combustível';

  @override
  String get featureGroupDescription_radar =>
      'Sugestões de preço ao vivo enquanto conduz.';

  @override
  String get featureGroupTitle_sync => 'Sincronização e cópia de segurança';

  @override
  String get featureGroupDescription_sync =>
      'Mantenha os seus dados em todos os dispositivos.';

  @override
  String get featureGroupTitle_input => 'Entrada e digitalização';

  @override
  String get featureGroupDescription_input =>
      'Auxiliares para registar abastecimentos.';

  @override
  String get featureGroupTitle_developer => 'Programador e experimental';

  @override
  String get featureGroupDescription_developer =>
      'Ferramentas para utilizadores avançados e contribuidores.';

  @override
  String get featureLabel_voiceFeedback => 'Feedback falado (síntese de voz)';

  @override
  String get featureDescription_voiceFeedback =>
      'Interruptor geral de toda a saída de voz — o treinador de condução falado e os anúncios de postos. Desligado, a app nunca abre um motor de síntese de voz.';

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
  String get fillUpMultiFuelHint =>
      'Este veículo pode usar combustíveis diferentes — registe o que realmente abasteceu';

  @override
  String get fillUpGuidanceTitle => 'Melhor hora para abastecer';

  @override
  String fillUpGuidanceGoodTimeNow(int days) {
    return 'O preço atual está entre os mais baratos dos últimos $days dias — é uma boa hora para abastecer.';
  }

  @override
  String fillUpGuidanceWaitCheaper(int days, String window) {
    return 'Os preços estão perto da máxima dos últimos $days dias. Costumam ser mais baratos $window — considere esperar.';
  }

  @override
  String get fillUpGuidanceFillSoon =>
      'Os preços estão a subir — considere abastecer em breve.';

  @override
  String fillUpGuidanceNeutral(int days) {
    return 'O preço de hoje está próximo da média dos últimos $days dias.';
  }

  @override
  String fillUpGuidanceSaving(String amount) {
    return 'Poderia poupar cerca de $amount/L ao escolher o momento certo para abastecer.';
  }

  @override
  String fillUpGuidanceSampleNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Com base em $count leituras de preço',
      one: 'Com base em 1 leitura de preço',
    );
    return '$_temp0';
  }

  @override
  String fillUpGuidanceWindowDayAndPart(String day, String part) {
    return '$day $part';
  }

  @override
  String fillUpGuidanceWindowDayOnly(String day) {
    return 'às $day';
  }

  @override
  String fillUpGuidanceWindowPartOnly(String part) {
    return '$part';
  }

  @override
  String get fillUpGuidanceWindowGeneric => 'noutras horas';

  @override
  String get fillUpGuidanceWeekday1 => 'segundas-feiras';

  @override
  String get fillUpGuidanceWeekday2 => 'terças-feiras';

  @override
  String get fillUpGuidanceWeekday3 => 'quartas-feiras';

  @override
  String get fillUpGuidanceWeekday4 => 'quintas-feiras';

  @override
  String get fillUpGuidanceWeekday5 => 'sextas-feiras';

  @override
  String get fillUpGuidanceWeekday6 => 'sábados';

  @override
  String get fillUpGuidanceWeekday7 => 'domingos';

  @override
  String get fillUpGuidancePartEarlyMorning => 'de madrugada';

  @override
  String get fillUpGuidancePartMorning => 'de manhã';

  @override
  String get fillUpGuidancePartAfternoon => 'à tarde';

  @override
  String get fillUpGuidancePartEvening => 'ao início da noite';

  @override
  String get fillUpGuidancePartNight => 'à noite';

  @override
  String get fillUpOdometerFromCarJustNow => 'Do seu carro · agora mesmo';

  @override
  String fillUpOdometerFromCarAt(String when) {
    return 'Do seu carro · $when';
  }

  @override
  String fillUpOdometerEstimatedAt(String when) {
    return 'Estimado a partir da última leitura do seu carro mais a distância percorrida desde então ($when)';
  }

  @override
  String get fillUpImportPasteLabel => 'Colar texto';

  @override
  String get pasteReceiptDialogTitle => 'Colar texto do recibo';

  @override
  String get pasteReceiptDialogHint =>
      'Cole o texto de um recibo de combustível — e-mail, SMS ou um PDF partilhado. Os litros, o preço por litro, o tipo de combustível, o total e o posto são lidos no dispositivo e usados para pré-preencher o formulário. Nada é enviado para um servidor.';

  @override
  String get pasteReceiptFieldHint => 'Texto do recibo';

  @override
  String get pasteReceiptParseAction => 'Pré-preencher';

  @override
  String get pasteReceiptNoData =>
      'Não foi possível ler dados de combustível nesse texto — confirme que é um recibo de combustível e tente novamente.';

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
  String get badScanReportTitleReceipt =>
      'Reportar um erro de leitura — Recibo';

  @override
  String get badScanReportHint =>
      'Vamos partilhar a foto do recibo e ambos os conjuntos de valores para que a próxima versão aprenda este layout.';

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
  String get fillUpWarningDialogTitle => 'Verifique este abastecimento';

  @override
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel) {
    return 'Escolheu $chosenFuel, mas este veículo funciona a $vehicleFuel.';
  }

  @override
  String fillUpWarningOdometerBelowPrevious(String entered, String previous) {
    return 'O conta-quilómetros $entered km está abaixo dos $previous km do abastecimento anterior — a distância não pode andar para trás.';
  }

  @override
  String get fillUpWarningGoBack => 'Voltar e corrigir';

  @override
  String get fillUpWarningSaveAnyway => 'Guardar mesmo assim';

  @override
  String get featureLabel_fleetMode => 'Fleet mode';

  @override
  String get featureDescription_fleetMode =>
      'Company-vehicle mode: your fleet assignment, the org vehicle directory, and an explicit current-vehicle switcher.';

  @override
  String get featureBlockedEnable_fleetMode =>
      'Turn TankSync on first — a fleet lives in your own database.';

  @override
  String get featureLabel_fleetManagerTools => 'Fleet manager tools';

  @override
  String get featureDescription_fleetManagerTools =>
      'Aggregate fleet cost and efficiency views for a manager — totals and exceptions, never per-employee journeys.';

  @override
  String get featureBlockedEnable_fleetManagerTools =>
      'Turn fleet mode on first.';

  @override
  String get featureGroupTitle_fleet => 'Fleet';

  @override
  String get featureGroupDescription_fleet =>
      'Company vehicles, assignments and manager reporting.';

  @override
  String get fleetExpensesTitle => 'Fuel expenses';

  @override
  String get fleetExpensesEmptyTitle => 'No expenses yet';

  @override
  String get fleetExpensesEmptyBody =>
      'Scan a fuel receipt and it appears here as a candidate you can check before submitting it.';

  @override
  String get fleetExpenseStatusDraft => 'Draft';

  @override
  String get fleetExpenseStatusNeedsReview => 'Needs review';

  @override
  String get fleetExpenseStatusSubmitted => 'Submitted';

  @override
  String get fleetExpenseStatusApproved => 'Approved';

  @override
  String get fleetExpenseStatusRejected => 'Rejected';

  @override
  String get fleetExpenseStatusExported => 'Exported';

  @override
  String get fleetExpenseStatusArchived => 'Archived';

  @override
  String get fleetExpenseUnknownStation => 'Station not read';

  @override
  String get fleetExpenseReviewTitle => 'Check this receipt';

  @override
  String get fleetExpenseNotFound => 'This expense is not on this device.';

  @override
  String get fleetExpenseArithmeticOk =>
      'Litres × price per litre matches the printed total.';

  @override
  String get fleetExpenseArithmeticMismatch =>
      'Litres × price per litre does not match the printed total. Check the numbers before you submit.';

  @override
  String get fleetExpenseArithmeticIncomplete =>
      'A number is missing, so the total cannot be checked.';

  @override
  String get fleetExpenseNeedsConfirmationTitle => 'Needs your confirmation';

  @override
  String get fleetExpenseReadTitle => 'Read from the document';

  @override
  String get fleetExpenseFieldStation => 'Station';

  @override
  String get fleetExpenseFieldDate => 'Date';

  @override
  String get fleetExpenseFieldFuel => 'Fuel grade';

  @override
  String get fleetExpenseFieldLitres => 'Volume';

  @override
  String get fleetExpenseFieldPricePerLitre => 'Price per litre';

  @override
  String get fleetExpenseFieldTotal => 'Total';

  @override
  String get fleetExpenseFieldVat => 'VAT';

  @override
  String get fleetExpenseFieldVatRate => 'VAT rate';

  @override
  String get fleetExpenseFieldPaymentReference => 'Payment reference';

  @override
  String get fleetExpenseFieldOdometer => 'Odometer';

  @override
  String get fleetExpenseValueMissing => 'Not read';

  @override
  String get fleetExpenseDocumentTitle => 'Document';

  @override
  String get fleetExpenseSourceOcrPhoto => 'Photographed receipt';

  @override
  String get fleetExpenseSourceOcrPdf => 'PDF receipt';

  @override
  String get fleetExpenseSourceEReceipt => 'Digital receipt';

  @override
  String get fleetExpenseSourceStructuredInvoice => 'Electronic invoice';

  @override
  String get fleetExpenseNotAuthoritative =>
      'A photograph is not an authoritative document, however well it was read.';

  @override
  String get fleetExpenseAuthoritative =>
      'The company treats this document as an authoritative record.';

  @override
  String get fleetExpenseAttachedToFillUp =>
      'Attached to a fill-up you already logged.';

  @override
  String fleetExpenseCorrections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields corrected',
      one: '1 field corrected',
      zero: 'No corrections',
    );
    return '$_temp0';
  }

  @override
  String get fleetExpenseNotAnAccountingRecord =>
      'Submitting hands this to your company as a claim. It is not an accounting record, and it does not decide whether you are reimbursed.';

  @override
  String get fleetExpenseConfirmAndSubmit => 'Confirm and submit';

  @override
  String get fleetExpenseFixFirst => 'Confirm the highlighted fields first';

  @override
  String get fleetExpenseAlreadySubmitted => 'Already submitted';

  @override
  String get fleetExpenseSubmitFailed => 'Could not submit this expense.';

  @override
  String get fleetManagerOverviewTitle => 'Fleet overview';

  @override
  String get fleetManagerNoFleetTitle => 'No fleet on this device';

  @override
  String get fleetManagerNoFleetBody =>
      'Join an organisation to see its vehicles, costs and expenses here.';

  @override
  String get fleetManagerUnavailableTitle => 'Figures not loaded';

  @override
  String get fleetManagerUnavailableBody =>
      'The organisation\'s figures could not be read. Check your connection and try again.';

  @override
  String get fleetManagerEmptyPeriodTitle => 'Nothing reported in this period';

  @override
  String get fleetManagerEmptyPeriodBody =>
      'No confirmed expenses fall inside the selected dates.';

  @override
  String get fleetManagerAttentionTitle => 'Needs attention';

  @override
  String get fleetManagerAttentionNone =>
      'Nothing needs attention in this period.';

  @override
  String fleetManagerAttentionCostOutlier(String vehicle) {
    return '$vehicle: cost per km well above the fleet\'s own median';
  }

  @override
  String fleetManagerAttentionLowCoverage(String vehicle) {
    return '$vehicle: less than half its fuel is backed by measured distance';
  }

  @override
  String fleetManagerAttentionNoDistance(String vehicle) {
    return '$vehicle: no odometer readings, so cost per km cannot be stated';
  }

  @override
  String fleetManagerAttentionCo2(String vehicle) {
    return '$vehicle: CO₂e not calculated — a grade in this period has no published factor';
  }

  @override
  String get fleetManagerAttentionMixedCurrency =>
      'This period mixes currencies, so there is no single total';

  @override
  String fleetManagerAttentionSuppressed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles are hidden: too few expenses to report',
      one: '1 vehicle is hidden: too few expenses to report',
    );
    return '$_temp0';
  }

  @override
  String get fleetManagerKpiSpend => 'Fuel spend';

  @override
  String get fleetManagerKpiCostPerKm => 'Cost per km';

  @override
  String get fleetManagerKpiConsumption => 'Consumption';

  @override
  String get fleetManagerKpiCo2 => 'CO₂e';

  @override
  String get fleetManagerKpiMeasuredCoverage => 'Measured coverage';

  @override
  String get fleetManagerKpiLitres => 'Fuel volume';

  @override
  String get fleetManagerKpiDistance => 'Distance';

  @override
  String fleetManagerSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
      zero: 'no expenses',
    );
    return '$_temp0';
  }

  @override
  String get fleetManagerNotCalculated => 'Not calculated';

  @override
  String get fleetManagerMultiCurrencyTotals => 'Totals by currency';

  @override
  String get fleetManagerVehiclesTitle => 'Vehicles';

  @override
  String fleetManagerVehicleSuppressed(int threshold) {
    return 'Fewer than $threshold expenses — hidden to protect the people behind the numbers';
  }

  @override
  String fleetManagerVehicleUnnamed(String code) {
    return 'Vehicle $code';
  }

  @override
  String get fleetManagerVehicleTitle => 'Vehicle';

  @override
  String get fleetManagerVehicleNotInPeriod =>
      'This vehicle reported nothing in the selected period.';

  @override
  String get fleetManagerNoJourneys =>
      'Journeys are not shown here. Fleet reporting reads confirmed expenses only — never GPS traces or engine telemetry.';

  @override
  String get fleetManagerQueueTitle => 'Expense queue';

  @override
  String get fleetManagerQueueEmptyTitle => 'Nothing to review';

  @override
  String get fleetManagerQueueEmptyBody =>
      'Submitted expenses appear here. Drafts stay with the employee.';

  @override
  String get fleetManagerQueueApprove => 'Approve';

  @override
  String get fleetManagerQueueReject => 'Reject';

  @override
  String get fleetManagerQueueDecisionFailed =>
      'The decision was not recorded. Nothing has changed.';

  @override
  String get fleetManagerQueueApproved => 'Approved';

  @override
  String get fleetManagerQueueRejected => 'Rejected';

  @override
  String get fleetManagerQueueNotAnApproval =>
      'Approval is a company decision, not an accounting record.';

  @override
  String get fleetManagerReportsTitle => 'Reports';

  @override
  String get fleetManagerCo2ScopeLabel => 'Scope';

  @override
  String get fleetManagerCo2ScopeWtw =>
      'Well-to-wheel (production, distribution and combustion)';

  @override
  String get fleetManagerCo2FactorLabel => 'Factor';

  @override
  String get fleetManagerCo2NotCalculatedBody =>
      'A fuel grade in this period has no published emission factor, so no figure is given. No undocumented factor is substituted.';

  @override
  String get fleetManagerCo2MixedVersions =>
      'This period used more than one factor version. Two methodologies are never added together.';

  @override
  String get fleetManagerExport => 'Export CSV';

  @override
  String get fleetManagerExportAudited =>
      'Exports are recorded in your organisation\'s audit log. Location and telemetry are never included.';

  @override
  String get fleetManagerExportFailed =>
      'The export was not recorded, so no file was produced.';

  @override
  String get fleetManagerExportReady => 'Export ready';

  @override
  String fleetManagerPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get fleetManagerClaimMeasured => 'Measured';

  @override
  String get fleetManagerClaimCalculated => 'Calculated';

  @override
  String get fleetManagerClaimEstimate => 'Estimate';

  @override
  String get fleetManagerClaimEnvironmental => 'Environmental estimate';

  @override
  String get fleetManagerOpenReports => 'Reports';

  @override
  String get fleetManagerOpenQueue => 'Expenses';

  @override
  String get wizardProfileFleetName => 'Company or fleet vehicle';

  @override
  String get wizardProfileFleetDescription =>
      'I drive my employer\'s car. Fleet assignment, expenses, and a clear view of what my manager can see.';

  @override
  String get fleetIdentityTitle => 'Your fleet';

  @override
  String get fleetIdentityIntro =>
      'Enter the invite code your fleet administrator gave you. If you are setting the fleet up yourself, create it below instead.';

  @override
  String get fleetInviteCodeLabel => 'Invite code';

  @override
  String get fleetScanQrCode => 'Scan QR code';

  @override
  String get fleetJoinButton => 'Join fleet';

  @override
  String get fleetCreateSectionTitle => 'I am setting up this fleet';

  @override
  String get fleetOrgNameLabel => 'Fleet name';

  @override
  String get fleetCreateButton => 'Create fleet';

  @override
  String get fleetIdentityLater =>
      'You can also do this later under Settings, then Fleet.';

  @override
  String fleetMemberOf(String org) {
    return 'You are in $org.';
  }

  @override
  String fleetYourRole(String role) {
    return 'Your role: $role';
  }

  @override
  String get fleetRoleEmployee => 'Employee';

  @override
  String get fleetRoleManager => 'Fleet manager';

  @override
  String get fleetRoleAdmin => 'Fleet administrator';

  @override
  String get fleetBlockedIdentityRequired =>
      'Joining a fleet needs an account with an e-mail address. This device still uses an anonymous account, which nobody can assign to a company — add an e-mail address in Settings, then Sync, first.';

  @override
  String get fleetBlockedCommunityBackend =>
      'A fleet cannot live on the shared community database. Your employer\'s own database, or one you were invited to, is required.';

  @override
  String get fleetBlockedSyncDisabled =>
      'Cloud sync is switched off. Set up your employer\'s database in Settings, then Sync, before joining a fleet.';

  @override
  String get fleetBlockedEnterCode =>
      'Enter the invite code your fleet administrator gave you.';

  @override
  String get fleetBlockedEnterName => 'Enter a name for the fleet.';

  @override
  String get fleetJoinErrorInvalidCode =>
      'That invite code is not valid or has expired. Ask your fleet administrator for a new one.';

  @override
  String get fleetJoinErrorAlreadyMember =>
      'This account already belongs to a fleet. Leave it before joining another one.';

  @override
  String get fleetJoinErrorNotSupported =>
      'This database does not offer fleet joining. Your administrator has to enable fleet mode on it first.';

  @override
  String get fleetJoinErrorUnavailable =>
      'The fleet could not be reached. Check your connection and try again.';

  @override
  String get fleetPrivacyTitle => 'What is shared, and what is not';

  @override
  String get fleetPrivacyDeviceTitle => 'Stays on this device';

  @override
  String get fleetPrivacyDeviceBody =>
      'Your journeys, your position and the raw data read from the adapter never leave this phone for your fleet. They are yours, for your own consumption figures and coaching.';

  @override
  String get fleetPrivacySyncTitle => 'Goes to your fleet\'s database';

  @override
  String get fleetPrivacySyncBody =>
      'Which company vehicle you are assigned to and when, plus the fill-ups and expenses you submit yourself. Nothing is sent while fleet sharing is switched off.';

  @override
  String get fleetPrivacyManagerTitle => 'What your manager can see';

  @override
  String get fleetPrivacyManagerBody =>
      'Vehicles and assignments, submitted expenses, and cost and consumption figures as fleet totals. Not your journeys, not your live position, and never a driving-style ranking of individual employees.';

  @override
  String get fleetPrivacyRetentionTitle =>
      'How long it is kept, and your controls';

  @override
  String get fleetPrivacyRetentionBody =>
      'Your employer configures how long expenses and assignment history are kept. You can export everything, switch sharing off, and delete your own data at any time in Settings, then Privacy and data.';

  @override
  String get settingsTopicFleetTitle => 'Fleet';

  @override
  String get settingsTopicFleetSubtitle =>
      'Your organisation, your role and what your manager can see.';

  @override
  String get settingsTopicFleetKeywords =>
      'fleet, company car, employer, organisation, manager, assignment, expenses';

  @override
  String get fleetSettingsNoFleet =>
      'You are not in a fleet yet. Join one with an invite code, or create one if you administer it.';

  @override
  String get fleetSettingsOrgLabel => 'Fleet';

  @override
  String get fleetSettingsRoleLabel => 'Your role';

  @override
  String get fleetSettingsSharingLabel => 'Sharing with your fleet';

  @override
  String get fleetSettingsSharingOn =>
      'On. The fill-ups and expenses you submit reach your fleet.';

  @override
  String get fleetSettingsSharingOff =>
      'Off. Nothing fleet-related leaves this device.';

  @override
  String get fleetSettingsManagerSeesTitle => 'What my manager can see';

  @override
  String get fleetVisibilityVehicle =>
      'Which company vehicle you are assigned to, and for which period.';

  @override
  String get fleetVisibilityExpenses =>
      'The fill-ups and expenses you submit yourself.';

  @override
  String get fleetVisibilityCosts =>
      'Cost per kilometre and consumption, as part of fleet totals.';

  @override
  String get fleetVisibilityNeverJourneys =>
      'Never your journeys, your live position or raw adapter data.';

  @override
  String get fleetVisibilityNeverBehaviour =>
      'Never a driving-style ranking of individual employees.';

  @override
  String get fleetSettingsStale =>
      'These fleet details could not be refreshed recently.';

  @override
  String get fleetSettingsExpired =>
      'These fleet details are out of date. Reconnect so they can be refreshed before you choose a vehicle.';

  @override
  String get fleetVehicleCurrentLabel => 'Current vehicle';

  @override
  String get fleetVehicleNoneAssigned => 'No vehicle assigned';

  @override
  String get fleetVehicleSwitchTitle => 'Choose your vehicle';

  @override
  String get fleetVehicleSwitchHelper =>
      'Switching applies from now on. Everything you already logged keeps the vehicle it was logged with.';

  @override
  String get fleetVehicleSearchLabel => 'Fleet code, model or registration';

  @override
  String get fleetVehicleSearchEmpty =>
      'No assigned vehicle matches your search.';

  @override
  String get fleetVehicleCurrentBadge => 'Current';

  @override
  String get fleetVehicleStaleBadge => 'Offline copy';

  @override
  String get fleetVehicleStaleNotice =>
      'This is the vehicle list your device downloaded last. It may not show a very recent handover.';

  @override
  String get fleetVehicleExpiredNotice =>
      'Your vehicle list is too old to switch safely. Connect to your fleet to refresh it.';

  @override
  String get fleetVehicleNeedsConfirmationTitle => 'Vehicle needs confirmation';

  @override
  String get fleetVehicleNeedsConfirmationBody =>
      'The adapter and the vehicle data point at different cars. Pick the right one — nothing is attributed until you do.';

  @override
  String fleetVehicleSemanticsCurrent(String vehicle) {
    return 'Current vehicle: $vehicle';
  }

  @override
  String get fleetVehicleSemanticsChange => 'Change current vehicle';

  @override
  String get fillUpSectionWhatTitle => 'O que abasteceu';

  @override
  String get fillUpSectionWhatSubtitle => 'Combustível, quantidade, preço';

  @override
  String get fillUpSectionWhereTitle => 'Onde estava';

  @override
  String get fillUpSectionWhereSubtitle => 'Posto, odómetro, notas';

  @override
  String get fillUpImportReceiptLabel => 'Recibo';

  @override
  String get fillUpPricePerLiterLabel => 'Preço por litro';

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
  String get profileSectionDisplayStations => 'Visualização e postos';

  @override
  String get profileSectionRegion => 'Região';

  @override
  String get fuelAndTankTitle => 'Fuel & Tank';

  @override
  String get fuelAndTankOpenAction => 'What\'s in my tank?';

  @override
  String get fuelAndTankNoVehicle =>
      'Select a vehicle that runs on liquid fuel to see its tank and how it behaves on each fuel.';

  @override
  String get fuelAndTankMixTitle => 'In your tank now';

  @override
  String fuelAndTankMixFocalAtLeast(String percent) {
    return '≥ $percent %';
  }

  @override
  String fuelAndTankMixFocalExact(String percent) {
    return '$percent %';
  }

  @override
  String fuelAndTankMixShareAtLeast(String percent, String fuel) {
    return '≥ $percent % $fuel';
  }

  @override
  String fuelAndTankMixShareExact(String percent, String fuel) {
    return '$percent % $fuel';
  }

  @override
  String fuelAndTankMixUnknownShare(String percent) {
    return '$percent % unknown';
  }

  @override
  String get fuelAndTankMixExplainPartial =>
      'The shares are guaranteed minimums. The unknown part could be any of these fuels — it grows with fill-ups logged without a tank level.';

  @override
  String get fuelAndTankMixExplainExact =>
      'Every litre is accounted for by your fill-up history.';

  @override
  String get fuelAndTankMixUnknownTitle => 'Mix unknown';

  @override
  String get fuelAndTankMixUnknownBody =>
      'Your fill-up history can\'t tell what is in the tank yet. A fill-up to a full tank makes the mix known again.';

  @override
  String fuelAndTankMixVolumeExact(String litres) {
    return '$litres in the tank';
  }

  @override
  String fuelAndTankMixVolumeRange(String min, String max) {
    return 'Between $min and $max in the tank';
  }

  @override
  String fuelAndTankMixVolumeAtLeast(String min) {
    return 'At least $min in the tank';
  }

  @override
  String fuelAndTankMixBarSemantics(String summary) {
    return 'Tank mix: $summary';
  }

  @override
  String get fuelAndTankCompatTitle => 'Fuels for this vehicle';

  @override
  String get fuelAndTankCompatApproved => 'Approved in your vehicle settings';

  @override
  String get fuelAndTankCompatUnconfirmed =>
      'Fit, but not confirmed for this vehicle';

  @override
  String get fuelAndTankCompatUnknown =>
      'This vehicle has no fuel set, so its approved fuels are unknown. Set its fuel in the vehicle settings.';

  @override
  String get fuelAndTankCompatHint =>
      'Only your vehicle settings count as approval — a fuel that fits the filler neck is not necessarily approved.';

  @override
  String get fuelAndTankBehaviourTitle => 'How your car behaves';

  @override
  String get fuelAndTankObservedBadge => 'Your car';

  @override
  String get fuelAndTankMetricConsumption => 'Consumption';

  @override
  String get fuelAndTankMetricCostPerKm => 'Cost per km';

  @override
  String get fuelAndTankMetricRange => 'Range per tank';

  @override
  String get fuelAndTankMetricCo2e => 'CO2e per km';

  @override
  String fuelAndTankCostPerKmValue(String amount, String currency) {
    return '$amount $currency/km';
  }

  @override
  String fuelAndTankCo2eValue(String grams) {
    return '$grams g/km';
  }

  @override
  String get fuelAndTankNotEnoughEvidence => 'Not enough evidence yet';

  @override
  String get fuelAndTankProvenanceMeasured => 'Measured';

  @override
  String get fuelAndTankProvenanceEstimated => 'Estimated';

  @override
  String get fuelAndTankProvenanceGeneral => 'General information';

  @override
  String fuelAndTankSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get fuelAndTankConfidenceLow => 'low confidence';

  @override
  String get fuelAndTankConfidenceMedium => 'medium confidence';

  @override
  String get fuelAndTankConfidenceHigh => 'high confidence';

  @override
  String fuelAndTankInterval(String low, String high) {
    return '95 % range $low – $high';
  }

  @override
  String get fuelAndTankInsufficientNoEvidence => 'No data on this fuel yet';

  @override
  String get fuelAndTankInsufficientTooFewSamples => 'Too few samples so far';

  @override
  String get fuelAndTankInsufficientTooLittleDistance =>
      'Not enough distance driven yet';

  @override
  String get fuelAndTankInsufficientCapacityUnknown =>
      'Needs the tank capacity in your vehicle settings';

  @override
  String get fuelAndTankInsufficientNoCo2eFactor =>
      'No CO2e factor on record for this fuel';

  @override
  String get fuelAndTankInsufficientContextNotPure =>
      'Not available for a mixed tank';

  @override
  String get fuelAndTankInsufficientTooUncertain => 'Too uncertain to show';

  @override
  String get fuelAndTankInsufficientConditionCoverage =>
      'Can\'t be adjusted for conditions yet — hills and traffic aren\'t recorded';

  @override
  String get fuelAndTankInsufficientMixedCurrencies =>
      'Several currencies — no single figure';

  @override
  String get fuelAndTankUncontrolled =>
      'Not adjusted for driving conditions yet — hills, cold starts and traffic are still in these figures.';

  @override
  String get fuelAndTankBasisReferenceWindows =>
      'From full-tank to full-tank fill-ups';

  @override
  String get fuelAndTankBasisMeasuredTrips =>
      'From engine readings on your trips';

  @override
  String get fuelAndTankBasisEstimatedTrips => 'Estimated from your trips';

  @override
  String get fuelAndTankBasisMeasuredResiduals =>
      'From engine readings, adjusted for driving conditions';

  @override
  String get fuelAndTankBasisEstimatedResiduals =>
      'Estimated, adjusted for driving conditions';

  @override
  String get fuelAndTankBasisDerived => 'Calculated from your other figures';

  @override
  String fuelAndTankMixedContext(String first, String second) {
    return 'Mixed $first + $second';
  }

  @override
  String get fuelAndTankNoEvidenceRow => 'Not driven on this fuel yet';

  @override
  String get fuelAndTankDetailsToggle => 'How these figures are made';

  @override
  String fuelAndTankModelVersions(String profile, String blend) {
    return 'Behaviour model v$profile · blend model v$blend';
  }

  @override
  String fuelAndTankCompareMore(String fuel, String percent, String other) {
    return '$fuel uses $percent % more than $other';
  }

  @override
  String fuelAndTankCompareLess(String fuel, String percent, String other) {
    return '$fuel uses $percent % less than $other';
  }

  @override
  String fuelAndTankCompareSame(String fuel, String other) {
    return '$fuel and $other use about the same';
  }

  @override
  String fuelAndTankCompareInsufficient(String fuel, String other) {
    return 'Not enough evidence yet to compare $fuel with $other';
  }

  @override
  String get fuelAndTankCompareWithinUncertainty =>
      'The difference is still within the uncertainty.';

  @override
  String get fuelAndTankCompareAdjusted => 'Adjusted for driving conditions.';

  @override
  String get fuelAndTankCompareNeedsTwo =>
      'Drive on two different fuels to compare them.';

  @override
  String get fuelAndTankFactsTitle => 'General fuel facts';

  @override
  String get fuelAndTankFactsSubtitle =>
      'From the fuel standards — not measured on your car.';

  @override
  String fuelAndTankFactPetrol(String fuel, String petrol, String open) {
    return '$fuel: at least $petrol % petrol; up to $open % can be ethanol.';
  }

  @override
  String fuelAndTankFactEthanol(String fuel, String ethanol) {
    return '$fuel: at least $ethanol % ethanol; the rest varies with the season.';
  }

  @override
  String fuelAndTankFactDiesel(String fuel, String diesel, String open) {
    return '$fuel: at least $diesel % diesel; up to $open % can be biodiesel.';
  }

  @override
  String fuelAndTankFactLpg(String fuel) {
    return '$fuel: liquefied petroleum gas, a fuel of its own.';
  }

  @override
  String fuelAndTankFactOctane(String fuel) {
    return '$fuel names the octane rating, not the ethanol content.';
  }

  @override
  String get fuelAndTankObjectiveTitle => 'Optimise the next fill for';

  @override
  String get fuelAndTankObjectiveCost => 'Lowest cost per km';

  @override
  String get fuelAndTankObjectiveConsumption => 'Lowest consumption';

  @override
  String get fuelAndTankObjectiveCo2e => 'Lowest CO2e';

  @override
  String get fuelAndTankObjectiveBalanced => 'Cost and CO2e';

  @override
  String get fuelAndTankObjectiveRange => 'Longest range';

  @override
  String get fuelAndTankNextFillTitle => 'Next fill';

  @override
  String fuelAndTankOutcomeRecommend(String fuel) {
    return 'Fill $fuel next';
  }

  @override
  String get fuelAndTankOutcomeNoAdvantage =>
      'No fuel is clearly better right now';

  @override
  String get fuelAndTankOutcomeInsufficient =>
      'Not enough evidence to recommend a fuel yet';

  @override
  String get fuelAndTankOutcomeTradeOff =>
      'A trade-off: one fuel is cheaper, another emits less';

  @override
  String get fuelAndTankOutcomeNoCompatible =>
      'No priced fuel is confirmed for this vehicle';

  @override
  String get fuelAndTankOutcomeCompatibilityUnknown =>
      'Approved fuels unknown — no recommendation';

  @override
  String fuelAndTankDecisionConfidence(String confidence) {
    return 'Decision made with $confidence';
  }

  @override
  String get fuelAndTankNoPricesTitle => 'No price comparison possible';

  @override
  String get fuelAndTankNoPricesBody =>
      'None of your favourite stations has a current price for a fuel this vehicle can take. Add stations to your favourites to compare.';

  @override
  String fuelAndTankPricesSource(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cheapest prices for $count fuels among your favourite stations',
      one: 'Cheapest price for 1 fuel among your favourite stations',
    );
    return '$_temp0';
  }

  @override
  String get fuelAndTankReasonCapabilityUnknown =>
      'This vehicle\'s approved fuels aren\'t set, so nothing can be recommended.';

  @override
  String get fuelAndTankReasonGradeNotApproved =>
      'Not confirmed as approved in your vehicle settings.';

  @override
  String get fuelAndTankReasonFillVolumeUnknown =>
      'The size of the next fill is unknown — set the tank capacity and log a full-tank fill-up.';

  @override
  String get fuelAndTankReasonResultingBlendUnknown =>
      'The tank mix after this fill can\'t be determined.';

  @override
  String get fuelAndTankReasonNoBehaviourEvidence =>
      'No consumption on record for this mix yet.';

  @override
  String get fuelAndTankReasonInterpolated =>
      'Estimated from how your car burns each fuel on its own.';

  @override
  String get fuelAndTankReasonConfoundersUncontrolled =>
      'Not adjusted for driving conditions yet.';

  @override
  String get fuelAndTankReasonNoCo2eFactor =>
      'No CO2e factor on record for this fuel mix.';

  @override
  String get fuelAndTankReasonCapacityUnknown =>
      'Range needs the tank capacity in your vehicle settings.';

  @override
  String get fuelAndTankReasonDetourNotPriced =>
      'The detour to the station isn\'t priced in.';

  @override
  String get fuelAndTankReasonDetourIncluded =>
      'The detour to the station is priced in.';

  @override
  String get fuelAndTankReasonOnlyOneCandidate =>
      'Only one fuel has a price, so there is nothing to compare.';

  @override
  String get fuelAndTankReasonUnevaluatedAlternatives =>
      'Some fuels couldn\'t be evaluated yet.';

  @override
  String get fuelAndTankReasonUncertaintyDominates =>
      'The difference is smaller than the uncertainty in your data.';

  @override
  String get fuelAndTankReasonBelowMaterialThreshold =>
      'The difference is too small to be worth switching.';

  @override
  String get fuelAndTankCandidatesToggle => 'Compare the fuels';

  @override
  String fuelAndTankCandidatePrice(String price) {
    return 'Pump price $price';
  }

  @override
  String fuelAndTankCandidateFill(String litres) {
    return 'Filling $litres';
  }

  @override
  String fuelAndTankCandidateResultingMix(String mix) {
    return 'Tank after this fill: $mix';
  }

  @override
  String fuelAndTankExcludedLine(String fuel, String reason) {
    return '$fuel — $reason';
  }

  @override
  String fuelAndTankTradeOffCheaper(
    String amount,
    String currency,
    String other,
  ) {
    return '$amount $currency/km cheaper than $other';
  }

  @override
  String fuelAndTankTradeOffDearer(
    String amount,
    String currency,
    String other,
  ) {
    return '$amount $currency/km dearer than $other';
  }

  @override
  String fuelAndTankTradeOffCo2eLess(String grams, String other) {
    return '$grams g CO2e/km less than $other';
  }

  @override
  String fuelAndTankTradeOffCo2eMore(String grams, String other) {
    return '$grams g CO2e/km more than $other';
  }

  @override
  String fuelAndTankBreakEvenPrice(String fuel, String price, String other) {
    return 'Break-even: $fuel at $price costs the same per km as $other';
  }

  @override
  String fuelAndTankBreakEvenConsumption(String other, String consumption) {
    return 'At today\'s prices it ties with $other at $consumption';
  }

  @override
  String fuelAndTankCostPerKgCo2e(String fuel, String amount) {
    return '$fuel avoids CO2e at $amount per kg';
  }

  @override
  String fuelAndTankConvergenceAlready(String percent, String fuel) {
    return 'The tank already holds at least $percent % $fuel.';
  }

  @override
  String fuelAndTankConvergenceReachable(
    int count,
    String fuel,
    String percent,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills of $fuel bring the tank to at least $percent %.',
      one: '1 fill of $fuel brings the tank to at least $percent %.',
    );
    return '$_temp0';
  }

  @override
  String fuelAndTankConvergenceUnreachable(
    String fuel,
    String percent,
    String count,
  ) {
    return '$fuel can\'t reach $percent % within $count fills.';
  }

  @override
  String get fuelAndTankConvergenceNotComputable =>
      'How quickly the tank changes over can\'t be computed yet.';

  @override
  String get fuelAndTankExcludedTitle => 'Left out';

  @override
  String fuelAndTankPricesSourceNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cheapest prices for $count fuels among the stations of your last search, detour included',
      one:
          'Cheapest price for 1 fuel among the stations of your last search, detour included',
    );
    return '$_temp0';
  }

  @override
  String fuelAndTankConvergenceTolerance(String tolerance, String target) {
    return 'Counted as reached within $tolerance points of the $target % target.';
  }

  @override
  String fuelAndTankMaterialThreshold(String percent) {
    return 'A fuel is only suggested when it is at least $percent % better.';
  }

  @override
  String get vehicleFlexFuelApprovedLabel => 'Approved for E85 (flex-fuel)';

  @override
  String get vehicleFlexFuelApprovedHelper =>
      'Only if the manufacturer approves E85. Fuel & Tank then compares E85 even when you usually fill another fuel.';

  @override
  String get fuelEfficiencyCardTitle => 'Custo por quilómetro por combustível';

  @override
  String get fuelEfficiencyCardSubtitle =>
      'Qual a mistura de combustível realmente mais barata para conduzir';

  @override
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm) {
    return 'Mais barato por km: $fuel ($costPerKm)';
  }

  @override
  String get fuelEfficiencyPureBadge => 'Puro';

  @override
  String get fuelEfficiencyMixBadge => 'Mistura';

  @override
  String fuelEfficiencyMixDominant(String fuel) {
    return 'Sobretudo $fuel';
  }

  @override
  String get fuelEfficiencyColL100km => 'L/100 km';

  @override
  String get fuelEfficiencyColCostPerKm => 'Custo/km';

  @override
  String get fuelEfficiencyColTotalSpent => 'Total gasto';

  @override
  String fuelEfficiencyFillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abastecimentos',
      one: '1 abastecimento',
    );
    return '$_temp0';
  }

  @override
  String fuelEfficiencyIntervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depósitos cheios',
      one: '1 depósito cheio',
    );
    return '$_temp0';
  }

  @override
  String get fuelEfficiencyInsufficientData =>
      'Registe pelo menos dois depósitos cheios por composição para eleger o mais barato.';

  @override
  String get fuelEfficiencyCompositionFootnote =>
      'Os depósitos são agrupados por composição: um depósito é puro quando um combustível representa pelo menos 85 % dele; caso contrário, é uma mistura.';

  @override
  String get fuelNameE5 => 'Gasolina 95';

  @override
  String get fuelNameE10 => 'Gasolina 95 E10';

  @override
  String get fuelNameE98 => 'Gasolina 98';

  @override
  String get fuelNameDiesel => 'Gasóleo';

  @override
  String get fuelNameDieselPremium => 'Gasóleo Premium';

  @override
  String get fuelNameE85 => 'Bioetanol E85';

  @override
  String get fuelNameLpg => 'GPL';

  @override
  String get fuelNameCng => 'GNC';

  @override
  String get fuelNameHydrogen => 'Hidrogénio';

  @override
  String get fuelNameElectric => 'Elétrico';

  @override
  String tankReportRecordedSummary(String pct, String value, String residual) {
    return 'Recorded trips cover $pct % of this tank and average $value · $residual % gap after calibration';
  }

  @override
  String tankReportRecordedSummaryNoResidual(String pct, String value) {
    return 'Recorded trips cover $pct % of this tank and average $value';
  }

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
  String gdprPolicyLink(int version) {
    return 'Política de privacidade (versão $version)';
  }

  @override
  String consentRecordedAt(String date, int version) {
    return 'Consentimento dado em $date · versão $version da política';
  }

  @override
  String get consentNotRecorded =>
      'Ainda não foi registado nenhum consentimento';

  @override
  String serverErasurePartial(String tables) {
    return 'Alguns dados do servidor não puderam ser apagados: $tables. Tente novamente ou contacte o programador com esta lista.';
  }

  @override
  String localErasurePartial(String steps) {
    return 'Alguns dados locais não puderam ser apagados: $steps. Reinicie a aplicação e tente novamente.';
  }

  @override
  String get myCommunityReportsTitle => 'Os meus relatórios da comunidade';

  @override
  String get myCommunityReportsEmpty => 'Ainda não enviou nenhum relatório';

  @override
  String get deleteReportTooltip => 'Eliminar este relatório';

  @override
  String get reportDeleted => 'Relatório eliminado';

  @override
  String get reportDeleteFailed => 'Não foi possível eliminar o relatório';

  @override
  String get tileProxyToggleTitle =>
      'Carregar os mosaicos do mapa através do proxy Sparkilo';

  @override
  String get tileProxyToggleSubtitle =>
      'Ligado: a área do mapa visível e o seu endereço IP chegam ao servidor da UE do programador, que obtém os mosaicos do OpenStreetMap. Desligado: os mosaicos são carregados diretamente de tile.openstreetmap.org.';

  @override
  String get remoteLogosToggleTitle =>
      'Carregar logótipos de marcas da internet';

  @override
  String get remoteLogosToggleSubtitle =>
      'Desligado por predefinição: são mostrados marcadores incluídos na aplicação. Ligado: os logótipos são obtidos de logo.clearbit.com, que vê o seu endereço IP.';

  @override
  String privacyExportAllSuccess(String fileName, int count) {
    return '$fileName guardado em Transferências — $count ficheiros incluídos';
  }

  @override
  String get privacyExportAllFailed =>
      'Não foi possível escrever o ficheiro de exportação';

  @override
  String syncModeCommunityControllerNotice(String operator) {
    return 'Operado por $operator · Supabase, UE (Frankfurt) · sincroniza favoritos, alertas, veículos incl. VIN, abastecimentos, avaliações, relatórios e — se o ativar — viagens com GPS';
  }

  @override
  String get syncModePrivateControllerNotice =>
      'O responsável pelo tratamento é você — o seu próprio projeto Supabase, nós nunca o vemos';

  @override
  String get syncModeJoinControllerNotice =>
      'Quem detém a base de dados partilhada é o responsável pelo tratamento dos seus dados';

  @override
  String get ugcPublicNoticeTitle => 'Partilhado com outros utilizadores';

  @override
  String get ugcPublicNoticeBody =>
      'Isto é guardado na base de dados de sincronização sob o seu ID de utilizador pseudónimo. Na Comunidade Sparkilo, qualquer utilizador com sessão iniciada pode lê-lo. Pode eliminá-lo a qualquer momento em TankSync → Transparência de dados.';

  @override
  String get blockedAuthorsTitle => 'Utilizadores bloqueados';

  @override
  String get blockedAuthorsDescription =>
      'O conteúdo partilhado por estes utilizadores está oculto neste dispositivo. Desbloqueie-os para o voltar a ver.';

  @override
  String get blockedAuthorsEmpty => 'Nenhum utilizador bloqueado';

  @override
  String get blockedAuthorsUnblock => 'Desbloquear';

  @override
  String get coachingGpsLiftOff => 'Soltar gás';

  @override
  String get coachingGpsAnticipateBrake => 'Antecipar';

  @override
  String get coachingGpsSmoothAccel => 'Aceleração suave';

  @override
  String gpsCoverageSummary(int pct, String gap, String cause) {
    return 'O trajeto cobre $pct % — falha mais longa $gap ($cause)';
  }

  @override
  String gpsCoverageSummaryNoGaps(int pct) {
    return 'O trajeto cobre $pct % — sem falhas detetadas';
  }

  @override
  String get gpsCoverageAttrBackgroundThrottle => 'app em segundo plano';

  @override
  String get gpsCoverageAttrOsBatching =>
      'agrupamento de posições pelo sistema';

  @override
  String get gpsCoverageAttrGateRejected => 'posições filtradas';

  @override
  String get gpsCoverageAttrDeliveryStall => 'entrega atrasada';

  @override
  String get gpsCoverageAttrSignalLoss => 'perda de sinal';

  @override
  String get gpsCoverageAttrUnknown => 'causa desconhecida';

  @override
  String get gpsCoverageHintBackgroundThrottle =>
      'A app estava em segundo plano sem um serviço em primeiro plano, pelo que o sistema limitou o GPS. Mantenha o ecrã ligado durante a gravação ou ative a gravação em segundo plano quando disponível.';

  @override
  String get gpsCoverageHintOsBatching =>
      'O sistema entregou as posições atrasadas e em lotes; o trajeto foi preenchido depois, pelo que na realidade se perderam poucos dados.';

  @override
  String get gpsCoverageHintGateRejected =>
      'As posições com ruído neste troço foram filtradas para manter a distância honesta.';

  @override
  String get gpsCoverageHintDeliveryStall =>
      'As posições foram produzidas a tempo mas chegaram tarde à app — o telemóvel estava ocupado (muitas vezes uma reconexão Bluetooth). A receção estava boa.';

  @override
  String get gpsCoverageHintSignalLoss =>
      'A receção GPS caiu — normalmente um túnel, um parque coberto ou um corredor urbano denso.';

  @override
  String get gpsCoverageHintUnknown =>
      'Esta viagem não contém informação sobre o estado da app durante a falha, pelo que a causa não pode ser determinada.';

  @override
  String get gpsCoverageAttrLinkRecovery => 'interferência da reconexão OBD2';

  @override
  String get gpsCoverageHintLinkRecovery =>
      'A falha coincide com um episódio de reconexão OBD2 — a ligação ao adaptador estava a recuperar enquanto a receção GPS parou. Corrigir a ligação do adaptador corrige também o trajeto.';

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
  String gpsDiagnosticsLargestGap(int seconds) {
    return 'Maior intervalo: $seconds s';
  }

  @override
  String get gpsLifecycleResumed => 'Retomado';

  @override
  String get gpsLifecyclePaused => 'Pausado';

  @override
  String get gpsLifecycleInactive => 'Inativo';

  @override
  String get gpsKpiVerdictGood => 'Eficiente';

  @override
  String get gpsKpiVerdictModerate => 'Moderada';

  @override
  String get gpsKpiVerdictAggressive => 'Agressiva';

  @override
  String get gpsKpiInterpretationGood =>
      'Condução suave e económica — é assim que a eficiência se parece.';

  @override
  String get gpsKpiInterpretationModerate =>
      'Condução bastante típica — um pouco mais de suavidade no acelerador pouparia mais.';

  @override
  String get gpsKpiInterpretationAggressive =>
      'Condução com muito gasto de energia — aliviar o acelerador e deixar o carro rolar mais reduziria o consumo.';

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
      'Estimativa GPS (~) — sem sensor de combustível nesta viagem. O valor é calculado a partir da velocidade e da calibração do seu veículo; a precisão melhora à medida que a matriz amadurece.';

  @override
  String get gpsRoadUseCardTitle => 'Como usou a estrada';

  @override
  String get gpsRoadUseSpeedSection => 'Onde passou o seu tempo';

  @override
  String get gpsRoadUseSpeedIdle => 'Parado (<5 km/h)';

  @override
  String get gpsRoadUseSpeedLow => 'Cidade (5–50 km/h)';

  @override
  String get gpsRoadUseSpeedCruise => 'Estrada (50–110 km/h)';

  @override
  String get gpsRoadUseSpeedHigh => 'Rápido (≥110 km/h)';

  @override
  String get gpsRoadUsePhaseSection => 'Como se deslocou';

  @override
  String get gpsRoadUsePhaseAccel => 'A acelerar';

  @override
  String get gpsRoadUsePhaseSteady => 'Velocidade constante';

  @override
  String get gpsRoadUsePhaseCoast => 'A rolar';

  @override
  String gpsRoadUseShare(String pct) {
    return '$pct %';
  }

  @override
  String get gpsRoadUseCoastPraise =>
      'Muito ponto-morto — deixar o carro rolar em vez de travar poupa combustível. Muito bem.';

  @override
  String get gpsRoadUseSource => 'A partir do seu trajeto GPS';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco-coaching em tempo real';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Toque háptico suave + dica no ecrã quando pisa fundo em velocidade de cruzeiro';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Devagar no acelerador — deslizar poupa mais';

  @override
  String highwayViaExit(String ref, String km) {
    return 'pela saída $ref · +$km km';
  }

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
  String get consentSyncTripsAnonymousHint =>
      'As viagens são guardadas na conta anónima deste dispositivo. Inicie sessão com um e-mail para as alcançar a partir de outros dispositivos.';

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
  String get accelBrakeCardTitle => 'Aceleração e travagem';

  @override
  String get accelBrakeHardAccel => 'Acelerações bruscas';

  @override
  String get accelBrakeHardBrake => 'Travagens bruscas';

  @override
  String get accelBrakeSharpCorner => 'Curvas apertadas';

  @override
  String get accelBrakeSource => 'Dos sensores de movimento do telemóvel';

  @override
  String lessonHardBrake(String count) {
    return '$count eventos de travagem brusca';
  }

  @override
  String get lessonAdviceHardBrake =>
      'Antecipe as paragens e alivie o acelerador mais cedo — travar com força deita fora o combustível que gastou a ganhar velocidade.';

  @override
  String lessonSharpCornering(String count) {
    return '$count curvas apertadas';
  }

  @override
  String get lessonAdviceSharpCornering =>
      'Reduza antes da curva, não durante — fazer curvas bruscas perde velocidade que terá de recuperar.';

  @override
  String liveConsumptionWindowLabel(int seconds) {
    return 'Últimos $seconds s';
  }

  @override
  String get consumptionUnitSettingTitle => 'Unidade de consumo';

  @override
  String get consumptionUnitSettingSubtitle =>
      'Como o consumo de combustível é mostrado em toda a app';

  @override
  String consumptionUnitAuto(String unit) {
    return 'Automático ($unit)';
  }

  @override
  String get consumptionWindowSettingTitle => 'Janela de consumo em direto';

  @override
  String get consumptionWindowSettingSubtitle =>
      'Faz a média do valor em direto nos últimos segundos — mais longa é mais estável, mais curta reage mais depressa';

  @override
  String consumptionWindowOption(int seconds) {
    return '$seconds s';
  }

  @override
  String tripRecordingPipEstConsumptionCaptionUnit(String unit) {
    return 'est. $unit';
  }

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
  String mapMarkerLimitNotice(int shown, int total) {
    return 'Showing $shown of $total — zoom in for the rest';
  }

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
  String get consumptionMonthlyClimbLabel => 'Subida';

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
  String get obd2DiagnosticsTitle => 'Saúde da comunicação OBD2';

  @override
  String obd2DiagnosticsHeader(String percent, String duty, int drops) {
    String _temp0 = intl.Intl.pluralLogic(
      drops,
      locale: localeName,
      other: '$drops falhas',
      one: '1 falha',
      zero: 'sem falhas',
    );
    return '$percent% completo · $duty% de uso · $_temp0';
  }

  @override
  String get obd2DiagnosticsAdapterSection => 'Adaptador';

  @override
  String get obd2DiagnosticsConnectionSection => 'Ciclo de vida da ligação';

  @override
  String get obd2DiagnosticsPidSection => 'Resultados por PID';

  @override
  String get obd2DiagnosticsReconnectSection => 'Telemetria de reconexão';

  @override
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  ) {
    return '$attempts tentativas de reconexão · $successes com sucesso · $transitions transições · $disconnects desconexões tipificadas';
  }

  @override
  String obd2DiagnosticsReconnectReasonLine(String reason, int count) {
    return '$reason: $count';
  }

  @override
  String get obd2DiagnosticsFallbackLine =>
      'Recurso só GPS ativado nesta sessão.';

  @override
  String get obd2DiagnosticsSchedulerSection => 'Saúde do agendador';

  @override
  String get obd2DiagnosticsCompletenessSection => 'Completude';

  @override
  String get obd2DiagnosticsSupportSection => 'PIDs descobertos e suportados';

  @override
  String get obd2DiagnosticsFuelSection => 'Resumo de nível de combustível';

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
    return '$attempts tentativas · $successes ok · $drops falhas · tempo de ligação p50 $p50 / p95 $p95';
  }

  @override
  String obd2DiagnosticsReconnectLine(int silent, int visible) {
    return 'Reconexões: $silent silenciosas · $visible visíveis';
  }

  @override
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  ) {
    return '$tickRate Hz tick · $skips saltos de contrapressão · $demotions despromoções';
  }

  @override
  String get obd2DiagnosticsStarved =>
      'Nível dinâmico sem dados — RPM / velocidade abaixo do piso do regulador.';

  @override
  String obd2DiagnosticsCompletenessLine(String percent, String duty) {
    return 'Geral $percent% · ciclo de serviço ativo $duty%';
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
    return '$supported suportados · $unsupported não suportados · $unknown desconhecidos';
  }

  @override
  String obd2DiagnosticsFuelLine(int suspicious, int total) {
    return 'Suspeitos: $suspicious de $total amostras';
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
    return '$pid: $polled consultados · $ok ok · $noData SD · $timeout TO · $error err · p50 $p50 / p95 $p95 ms · $effectiveHz/$targetHz Hz';
  }

  @override
  String get obd2DiagnosticsInitSection =>
      'Transcrição de inicialização do dongle';

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
  String get obd2DiagnosticsInitWarm => 'morno';

  @override
  String get obd2DiagnosticsInitCold => 'frio';

  @override
  String get obd2DiagnosticsEmpty =>
      'Ainda não há sessões OBD2 registadas — ligue um adaptador e registe uma viagem com o modo Programador ativo.';

  @override
  String get obd2DiagnosticsExplain =>
      'Capturado durante a gravação para depurar a comunicação dongle↔app — apenas recolhido em modo Programador.';

  @override
  String get obd2HealthScreenTitle => 'Saúde da comunicação OBD2';

  @override
  String get obd2HealthNavLabel => 'Saúde da comunicação OBD2';

  @override
  String get obd2HealthLiveSection => 'Sessão em direto';

  @override
  String get obd2HealthHistorySection => 'Sessões recentes';

  @override
  String get obd2HealthDownloadJson => 'Transferir como JSON';

  @override
  String get obd2HealthDownloadInitTranscript =>
      'Transferir apenas a transcrição de inicialização';

  @override
  String get obd2HealthDownloadError =>
      'Não foi possível guardar o ficheiro de diagnóstico';

  @override
  String get obd2TestAdapterLabel => 'Adaptador a testar';

  @override
  String get obd2TestAdapterScanOption => 'Procurar adaptador';

  @override
  String obd2TestStepConnectTo(String adapter) {
    return 'Ligar a $adapter';
  }

  @override
  String get obd2TestRunTitle => 'Executar teste do adaptador';

  @override
  String get obd2TestRunButton => 'Executar teste do adaptador';

  @override
  String get obd2TestRunPassed => 'Teste do adaptador aprovado';

  @override
  String get obd2TestRunFailed => 'Teste do adaptador falhado';

  @override
  String get obd2TestRunEngineOff =>
      'Adaptador OK — motor desligado; ligue o motor para ler dados em tempo real';

  @override
  String obd2TestRunSummary(int passed, int total, int elapsed) {
    return '$passed de $total passos OK · $elapsed ms';
  }

  @override
  String get obd2TestRunCannotWhileRecording =>
      'Pare a gravação ativa antes de executar o teste do adaptador.';

  @override
  String get obd2TestStepScan => 'Procurar adaptador';

  @override
  String get obd2TestStepBluetooth => 'Bluetooth do telemóvel';

  @override
  String get obd2TestStepConnect => 'Ligar e inicializar';

  @override
  String get obd2TestStepInfo => 'Informação do adaptador';

  @override
  String get obd2TestStepSupportedPids => 'PIDs suportados';

  @override
  String get obd2TestStepProtocol => 'Protocolo do veículo';

  @override
  String get obd2TestStepSampleReads => 'Leituras de amostra';

  @override
  String get obd2TestStepSoak => 'Consulta prolongada';

  @override
  String get obd2TestStepReconnect => 'Teste de reconexão';

  @override
  String get obd2TestStepDisconnect => 'Desligar';

  @override
  String get obd2TestStatusOk => 'OK';

  @override
  String get obd2TestStatusTimeout => 'Tempo esgotado';

  @override
  String get obd2TestStatusGarbage => 'Resposta ilegível';

  @override
  String get obd2TestStatusNoResponse => 'Sem resposta';

  @override
  String get obd2TestStatusFail => 'Falhado';

  @override
  String get obd2TestAdapterTransportClassic => 'Classic (SPP)';

  @override
  String get obd2TestAdapterTransportBle => 'Bluetooth LE';

  @override
  String get obd2TestAdapterTransportUnknown =>
      'desconhecido — BLE por predefinição';

  @override
  String get obd2HealthConnectAttemptsSection =>
      'Tentativas de ligação recentes';

  @override
  String get obd2HealthConnectAttemptsEmpty =>
      'Ainda não há tentativas de ligação registadas.';

  @override
  String get obd2HealthDownloadConnectTrace => 'Transferir registo de ligação';

  @override
  String get obd2HealthDownloadAllConnectTraces =>
      'Transferir todos os registos de ligação';

  @override
  String get obd2HealthConnectOrigin => 'Origem';

  @override
  String get obd2HealthConnectTransport => 'Transporte';

  @override
  String get obd2HealthConnectOutcome => 'Resultado';

  @override
  String get obd2HealthConnectScanList => 'Dispositivos detetados';

  @override
  String get obd2HealthConnectSteps => 'Passos';

  @override
  String get obd2HealthConnectUnknownAdapter => 'Adaptador desconhecido';

  @override
  String obd2DiagnosticsTripRecordedHeader(int samples, int percent) {
    return 'Sessão registada · $samples amostras do motor · $percent % de cobertura';
  }

  @override
  String get obd2DiagnosticsTripEvidenceSection => 'O que esta viagem registou';

  @override
  String obd2DiagnosticsTripSamplesLine(int samples, int total, int percent) {
    return '$samples de $total amostras traziam dados do motor ($percent %)';
  }

  @override
  String obd2DiagnosticsTripAdapterLine(String adapter) {
    return 'Adaptador: $adapter';
  }

  @override
  String obd2DiagnosticsTripProtocolLine(String verdict) {
    return 'Negociação do protocolo: $verdict';
  }

  @override
  String obd2DiagnosticsTripEndedLine(String reason) {
    return 'Sessão terminada: $reason';
  }

  @override
  String obd2DiagnosticsTripDurationLine(String duration) {
    return 'Duração da sessão: $duration';
  }

  @override
  String get obd2DiagnosticsTripFuelMeasured =>
      'Os valores de consumo vieram do adaptador, não de estimativas por GPS.';

  @override
  String get obd2DiagnosticsTripNoPidDetail =>
      'O detalhe de comunicação por PID não foi captado nesta viagem. Ative o modo de programador antes de gravar para o recolher.';

  @override
  String obd2DiagnosticsImplausibleFramesLine(int voltage, int odometer) {
    return 'Implausible frames: $voltage battery voltage · $odometer odometer';
  }

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Não foi possível alcançar \'$adapterName\' — escolha outro adaptador';
  }

  @override
  String get obd2PickerOtherDevices => 'Outros dispositivos Bluetooth';

  @override
  String get obd2PickerTapToTry => 'Não reconhecido — toque para experimentar';

  @override
  String get obd2PickerBleOnlyNotice =>
      'O iPhone só funciona com adaptadores Bluetooth LE. Um adaptador apenas Classic (p. ex. vLinker BM, Konnwei KW902) tem de ser usado em Android.';

  @override
  String get obd2PairingConfirmHint =>
      'Confirme o pedido de emparelhamento no seu telemóvel';

  @override
  String get obd2ScanEmptyTitle => 'Nenhum adaptador encontrado';

  @override
  String get obd2ScanEmptyReady =>
      'O Bluetooth está ligado e as permissões concedidas. Certifique-se de que o adaptador está ligado à porta OBD2 e a ignição ligada, depois procure novamente.';

  @override
  String get obd2ScanBlockedUnsupported =>
      'Este dispositivo não tem hardware Bluetooth Low Energy, pelo que não consegue ligar-se a um adaptador OBD2.';

  @override
  String get obd2ScanBlockedBluetoothOff =>
      'O Bluetooth está desligado. Ligue-o para procurar o seu adaptador.';

  @override
  String get obd2ScanBlockedPermission =>
      'O Sparkilo precisa da permissão Bluetooth para encontrar o seu adaptador.';

  @override
  String get obd2ScanBlockedPermissionSettings =>
      'A permissão Bluetooth foi recusada permanentemente. Conceda-a nas definições do sistema para procurar o seu adaptador.';

  @override
  String get obd2ScanBlockedLocationServices =>
      'Os serviços de localização estão desligados neste dispositivo. O Android precisa deles ativados para procurar adaptadores Bluetooth — nenhuma localização é registada ou partilhada.';

  @override
  String get obd2ScanOpenSettings => 'Abrir definições';

  @override
  String get obd2WaitingForEngineBanner =>
      'À espera do motor — a gravar com GPS';

  @override
  String get obd2AdapterNotRespondingBanner =>
      'Adapter not responding — still recording with GPS';

  @override
  String get obd2StartEngineToReconnect => 'Ligue o motor para reconectar';

  @override
  String get obd2ResetConnectionEngineOff =>
      'Motor desligado — ligue-o para reconectar';

  @override
  String obd2ParkedPromptTitle(int minutes) {
    return 'Motor desligado há $minutes min — parar a gravação?';
  }

  @override
  String get obd2ParkedPromptStop => 'Parar';

  @override
  String get obd2ParkedPromptKeep => 'Manter';

  @override
  String obd2CoverageEngineOffEnvelopeNote(String head, String tail) {
    return 'Motor desligado nos primeiros $head e nos últimos $tail desta viagem — a cobertura é medida com o motor a trabalhar.';
  }

  @override
  String get obd2ReconnectInProgress => 'A reconectar ao seu adaptador OBD2…';

  @override
  String get obd2StatusEngineOff => 'OBD2 em pausa — motor desligado';

  @override
  String get obd2StatusEngineOffBody =>
      'O adaptador estava acessível, mas o barramento do veículo ficou em silêncio, pelo que a reconexão automática está em pausa. Retoma quando conduzir ou reabrir a app — ou reconecte agora.';

  @override
  String get obd2StatusReconnectNow => 'Reconectar agora';

  @override
  String get autoRecordNotificationTitle => 'Gravação automática de viagens';

  @override
  String get autoRecordNotificationText => 'A vigiar o seu adaptador OBD2';

  @override
  String get obd2ResetConnection => 'Repor ligação';

  @override
  String get obd2ResetConnectionDone =>
      'Adaptador reposto — ligação restabelecida';

  @override
  String get obd2ResetConnectionNoLink =>
      'Adaptador reposto — a reconectar em segundo plano';

  @override
  String get obd2ResetConnectionAuto =>
      'Reconnecting the adapter automatically…';

  @override
  String get ocrTesterTitle => 'Testador OCR';

  @override
  String get ocrTesterNavLabel => 'Testador OCR';

  @override
  String get ocrTesterExplain =>
      'Execute o pipeline OCR da bomba/recibo numa foto escolhida e inspecione cada passo — apenas disponível em modo Programador.';

  @override
  String get ocrTesterCapture => 'Capturar';

  @override
  String get ocrTesterPickImage => 'Escolher imagem';

  @override
  String get ocrTesterRun => 'Executar';

  @override
  String get ocrTesterCountry => 'País';

  @override
  String get ocrTesterCountryNone => 'Predefinição (sem perfil)';

  @override
  String get ocrTesterNoImage =>
      'Escolha ou capture uma imagem e depois toque em Executar.';

  @override
  String get ocrTesterRunning => 'A executar OCR…';

  @override
  String get ocrTesterOverlaySection => 'Sobreposição de blocos';

  @override
  String get ocrTesterStepsSection => 'Passos do pipeline';

  @override
  String get ocrTesterLegendLabel => 'Etiqueta';

  @override
  String get ocrTesterLegendNumeric => 'Numérico';

  @override
  String get ocrTesterLegendNoise => 'Ruído';

  @override
  String get ocrTesterLegendDerived => 'Derivado';

  @override
  String get ocrTesterStageGlare => 'Captura / reflexo';

  @override
  String get ocrTesterStageMlkit => 'ML Kit';

  @override
  String get ocrTesterStageClassify => 'Classificar';

  @override
  String get ocrTesterStageAssemble => 'Montar';

  @override
  String get ocrTesterStageAnchor => 'Ancorar';

  @override
  String get ocrTesterStageFallback => 'Alternativa';

  @override
  String get ocrTesterStageCrossCheck => 'Verificação cruzada';

  @override
  String get ocrTesterStageConfidence => 'Confiança';

  @override
  String get ocrTesterStageGate => 'Portão';

  @override
  String get ocrTesterStageBrand => 'Marca';

  @override
  String get ocrTesterStageOverrides => 'Substituições';

  @override
  String get ocrTesterStageReconcile => 'Reconciliar';

  @override
  String get ocrTesterStageResult => 'Resultado';

  @override
  String get ocrTesterChipRead => 'LIDO';

  @override
  String get ocrTesterChipDerived => 'DERIVADO';

  @override
  String get ocrTesterGateAccepted => 'Aceite';

  @override
  String get ocrTesterGateRejected => 'Rejeitado';

  @override
  String get ocrTesterFallbackBanner =>
      'Um campo foi recuperado via alternativa de magnitude — verifique-o.';

  @override
  String get ocrTesterStageNoData => 'Esta etapa não foi executada.';

  @override
  String get ocrTesterCopyJson => 'Copiar como JSON';

  @override
  String get ocrTesterExportPackage => 'Exportar pacote';

  @override
  String get ocrTesterCopied =>
      'Rastreio OCR copiado para a área de transferência.';

  @override
  String get ocrTesterExported =>
      'Pacote OCR guardado na pasta Transferências.';

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
  String get onboardingObd2ConnectFailed =>
      'Não foi possível ligar ao adaptador. Pode tentar novamente ou ignorar.';

  @override
  String get onboardingPickUseMode => 'Escolha um modo de uso para continuar.';

  @override
  String get onboardingObd2LaterNote =>
      'Pode emparelhar um adaptador OBD2 Bluetooth mais tarde a partir do ecrã do veículo para gravar viagens e ler dados do motor.';

  @override
  String get onboardingTitle => 'Set up Sparkilo';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get openHoursUnknown => 'Horário desconhecido';

  @override
  String get open24Hours => 'Aberto 24 horas';

  @override
  String get openingHoursAutomate24h =>
      'Bomba automática 24 h/24 (pagamento com cartão)';

  @override
  String get dayMon => 'Segunda-feira';

  @override
  String get dayTue => 'Terça-feira';

  @override
  String get dayWed => 'Quarta-feira';

  @override
  String get dayThu => 'Quinta-feira';

  @override
  String get dayFri => 'Sexta-feira';

  @override
  String get daySat => 'Sábado';

  @override
  String get daySun => 'Domingo';

  @override
  String get dayShortMon => 'Seg';

  @override
  String get dayShortTue => 'Ter';

  @override
  String get dayShortWed => 'Qua';

  @override
  String get dayShortThu => 'Qui';

  @override
  String get dayShortFri => 'Sex';

  @override
  String get dayShortSat => 'Sáb';

  @override
  String get dayShortSun => 'Dom';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get publicHolidays => 'Feriados';

  @override
  String get closedLabel => 'Fechado';

  @override
  String get openingHoursNotAvailable =>
      'Horário de funcionamento não disponível';

  @override
  String get showAllHours => 'Ver todos os horários';

  @override
  String get showLessHours => 'Ver menos';

  @override
  String get openStateUnknown => 'Desconhecido';

  @override
  String stationOpenStateSemantic(String open) {
    String _temp0 = intl.Intl.selectLogic(open, {
      'true': 'Posto aberto',
      'false': 'Posto fechado',
      'other': 'Estado de abertura desconhecido',
    });
    return '$_temp0';
  }

  @override
  String get opportunitiesSectionTitle => 'Opportunities';

  @override
  String get opportunitiesEmptyTitle => 'Nothing worth telling you about yet';

  @override
  String get opportunitiesEmptyBody =>
      'SparKilo checks your stations and your area in the background. A stop worth the detour, a price unusual for your area, or one below what you normally pay will appear here — whether or not it was worth a notification.';

  @override
  String get opportunityNotSentLabel => 'Not sent';

  @override
  String get opportunityKindBestStopNow => 'Best stop nearby';

  @override
  String get opportunityKindBestStopOnRoute => 'Best stop on your route';

  @override
  String get opportunityKindRefuelSoon => 'You will need fuel';

  @override
  String get opportunityKindExceptionalLocalPrice => 'Unusual price nearby';

  @override
  String get opportunityKindPersonalBaseline => 'Below what you usually pay';

  @override
  String get opportunityKindLocalMovement => 'Prices moving nearby';

  @override
  String get opportunityKindFavouriteStation => 'Your price alert';

  @override
  String get opportunityRefusalDailyCap =>
      'You had already had today\'s alerts';

  @override
  String get opportunityRefusalTooSoon => 'Another alert had just gone out';

  @override
  String get opportunityRefusalBelowFloor =>
      'Not enough to be worth interrupting you';

  @override
  String get opportunityRefusalAlreadyTold =>
      'You were told about this station recently';

  @override
  String get opportunityRefusalOutranked => 'A better one went out instead';

  @override
  String get opportunityRefusalConfidenceTooLow =>
      'Too weakly supported to arrive uninvited';

  @override
  String get opportunityRefusalIneligible =>
      'It stopped being true before we could send it';

  @override
  String get opportunityRefusalNotWatched => 'You are not watching for this';

  @override
  String get opportunitiesScreenTitle => 'Opportunities';

  @override
  String get opportunitiesWatchHeader => 'What to watch for';

  @override
  String get opportunitiesWatchHint =>
      'Everything the engine finds appears in Opportunities. These switches decide what may interrupt you.';

  @override
  String get usualStationTitle => 'Your usual station';

  @override
  String usualStationCandidate(Object fills, Object station) {
    return '$station — $fills fill-ups';
  }

  @override
  String get usualStationConfirm => 'Set as usual';

  @override
  String get usualStationClear => 'Not my usual';

  @override
  String get usualStationNone =>
      'Add a few fill-ups and SparKilo can suggest one';

  @override
  String opportunityBestStopNowTitle(String fuelType) {
    return 'Cheapest $fuelType nearby';
  }

  @override
  String opportunityBestStopNowBody(
    String price,
    String currency,
    String station,
    String distance,
  ) {
    return '$price $currency at $station · $distance km';
  }

  @override
  String opportunityBestStopOnRouteTitle(String fuelType) {
    return 'Cheapest $fuelType on your route';
  }

  @override
  String opportunityBestStopOnRouteBody(
    String price,
    String currency,
    String station,
    String distance,
  ) {
    return '$price $currency at $station · $distance km ahead';
  }

  @override
  String get opportunityRefuelSoonTitle => 'Time to refuel';

  @override
  String opportunityRefuelSoonBody(
    String station,
    String distance,
    String price,
    String currency,
  ) {
    return '$station · $distance km ahead · $price $currency';
  }

  @override
  String opportunityPersonalBaselineTitle(String fuelType) {
    return '$fuelType below your usual price';
  }

  @override
  String opportunityPersonalBaselineBody(
    String price,
    String currency,
    String station,
  ) {
    return '$price $currency at $station';
  }

  @override
  String get permissionRationaleCameraTitle => 'Acesso à câmara';

  @override
  String get permissionRationaleCameraSubtitle =>
      'Esta aplicação gostaria de usar a sua câmara para ler recibos, visores de bombas e códigos QR.';

  @override
  String get permissionRationaleCameraWhatHappens =>
      'O que acontece com a imagem da câmara:';

  @override
  String get permissionRationaleCameraBulletOnDevice =>
      'A imagem é usada apenas para ler o recibo, o visor da bomba ou o código QR — o reconhecimento é executado no seu dispositivo.';

  @override
  String get permissionRationaleCameraBulletDiscarded =>
      'A fotografia é descartada após a leitura.';

  @override
  String get permissionRationaleCameraBulletNoUpload =>
      'Nada é carregado, a menos que envie um relatório de leitura errada e o confirme.';

  @override
  String get permissionRationaleBluetoothTitle => 'Acesso ao Bluetooth';

  @override
  String get permissionRationaleBluetoothSubtitle =>
      'Esta aplicação gostaria de usar o Bluetooth para se ligar ao seu adaptador OBD2.';

  @override
  String get permissionRationaleBluetoothWhatHappens =>
      'O que acontece com o Bluetooth:';

  @override
  String get permissionRationaleBluetoothBulletAdapterOnly =>
      'O Bluetooth é usado apenas para encontrar o seu adaptador OBD2 e comunicar com ele.';

  @override
  String get permissionRationaleBluetoothBulletIdentifierLocal =>
      'O identificador do adaptador permanece no seu dispositivo — é sincronizado apenas através do TankSync, como parte do perfil do veículo.';

  @override
  String get permissionRationaleBluetoothBulletLegacyLocation =>
      'No Android 11 e anteriores, o sistema também pede a localização, porque aí a procura por Bluetooth é considerada uma permissão de localização.';

  @override
  String get permissionRationaleNotificationsTitle => 'Notificações';

  @override
  String get permissionRationaleNotificationsSubtitle =>
      'Esta aplicação gostaria de lhe enviar notificações sobre alertas de preços e o estado da gravação de viagens.';

  @override
  String get permissionRationaleNotificationsWhatHappens =>
      'O que acontece com as notificações:';

  @override
  String get permissionRationaleNotificationsBulletLocal =>
      'As notificações são usadas para alertas de preços locais e para o estado da gravação de viagens.';

  @override
  String get permissionRationaleNotificationsBulletNothingLeaves =>
      'São geradas no seu dispositivo — nada sai do dispositivo.';

  @override
  String get permissionRationaleRevoke =>
      'Pode revogar isto a qualquer momento nas definições do dispositivo.';

  @override
  String get permissionRationaleLegalBasis =>
      'Base jurídica: art. 6.º, n.º 1, al. a) do RGPD (consentimento)';

  @override
  String get tripRecordingPipEstConsumptionCaption => 'est. L/100 km';

  @override
  String get tripRecordingEstimatedInfo =>
      'Valor estimado (~) — sem sensor de combustível nesta viagem, pelo que o valor L/100 km é calculado a partir da velocidade GPS e da calibração do seu veículo. É aproximado (tipicamente ±10–30 %, melhorando à medida que a calibração amadurece), não uma leitura real.';

  @override
  String get tripRecordingPipElapsedCaption => 'decorrido';

  @override
  String get processWorkflowsDriving => 'Record and understand driving';

  @override
  String get processWorkflowsRecordDescription =>
      'Record journeys and review them in your driving history.';

  @override
  String get processWorkflowsEnabled => 'Workflow enabled';

  @override
  String get processWorkflowsNotEnabled => 'Workflow not enabled';

  @override
  String get processWorkflowsDetails => 'Why is this enabled?';

  @override
  String get processWorkflowsEnable => 'Enable workflow';

  @override
  String get processWorkflowsRequired =>
      'Required capabilities — enabled together';

  @override
  String get processWorkflowsNeeds =>
      'Before recording, choose a vehicle and configure its recording mode and required permissions. Enabling this workflow may resume automatic recording if you previously enabled it for a vehicle.';

  @override
  String get processWorkflowsImpact =>
      'Capabilities that will become active (including saved preferences)';

  @override
  String get processWorkflowsUsedBy => 'Used by these optional capabilities';

  @override
  String get processWorkflowsConfirm => 'Confirm activation';

  @override
  String get processWorkflowsActivated => 'Workflow enabled.';

  @override
  String get processWorkflowsChanged =>
      'Your settings changed during review. Open the preview again.';

  @override
  String get processWorkflowsFailed =>
      'Could not finish updating the workflow. Check its current state and try again.';

  @override
  String pumpGainCalibratedTitle(String vehicleName, String percent) {
    return '$vehicleName: estimativas de consumo reancoradas na bomba ($percent %)';
  }

  @override
  String get qrLaunchConfirmTitle => 'Abrir a ligação digitalizada?';

  @override
  String qrLaunchConfirmBody(String host) {
    return 'Este código QR aponta para $host. Abra apenas ligações em que confie.';
  }

  @override
  String get qrLaunchConfirmOpen => 'Abrir ligação';

  @override
  String get qrLaunchConfirmCancel => 'Cancelar';

  @override
  String get radarPinHelpTitle => 'Sobre fixar';

  @override
  String get radarPinHelpBody =>
      'Fixar mantém o ecrã ligado e oculta as barras do sistema para que a leitura do posto mais próximo fique legível num suporte de painel. Toque novamente para soltar. Solta automaticamente quando o radar para.';

  @override
  String get radarAutoPinTitle => 'Fixar sempre quando o radar inicia';

  @override
  String get radarAutoPinSubtitle =>
      'Fixa o radar automaticamente de cada vez em vez de tocar cada vez. Usa mais bateria.';

  @override
  String get radarScopeShowScope => 'Vista de radar';

  @override
  String get radarScopeShowList => 'Vista de lista';

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
  String get reconcileWorkflowTitle => 'Reconciliar o seu combustível';

  @override
  String reconcileWorkflowExplainHeadline(String gap) {
    return 'Encontrámos uma diferença de $gap L';
  }

  @override
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  ) {
    return 'Abasteceu $pumped L, mas as suas viagens registadas apenas contabilizam $consumed L. Ficam $gap L por explicar.';
  }

  @override
  String get reconcileWorkflowExplainCauses =>
      'Isto acontece normalmente quando uma condução não foi registada (o adaptador foi desligado ou a aplicação foi fechada), ou quando falta um abastecimento ou está introduzido incorretamente.';

  @override
  String get reconcileWorkflowExplainConsequence =>
      'Até que isso seja resolvido, o total de combustível e o total de viagens não vão coincidir.';

  @override
  String get reconcileWorkflowAttributeQuestion =>
      'Ajude-nos a atribuir a diferença';

  @override
  String get reconcileWorkflowFillUpsCompleteQuestion =>
      'Todos os abastecimentos deste depósito estão completos e corretos?';

  @override
  String get reconcileWorkflowDrivesRecordedQuestion =>
      'Todas as suas conduções estão registadas?';

  @override
  String get reconcileWorkflowAnswerYes => 'Sim';

  @override
  String get reconcileWorkflowAnswerNo => 'Não';

  @override
  String get reconcileWorkflowPathAHint =>
      'Falta um abastecimento ou está errado — adicionaremos uma correção para que os abastecimentos fiquem corretos.';

  @override
  String get reconcileWorkflowPathBHint =>
      'Os seus abastecimentos estão corretos e uma condução não foi registada — adicionaremos uma viagem virtual pela distância em falta.';

  @override
  String get reconcileWorkflowCorrectionLitersLabel => 'Litros de correção';

  @override
  String get reconcileWorkflowVirtualDistanceLabel =>
      'Qual a distância da condução não registada? (km)';

  @override
  String get reconcileWorkflowDecideLater => 'Decidir depois';

  @override
  String get reconcileWorkflowBack => 'Voltar';

  @override
  String get reconcileWorkflowNext => 'Seguinte';

  @override
  String get reconcileWorkflowApply => 'Aplicar';

  @override
  String get reconcileVirtualTrajetLabel =>
      'Viagem virtual — toque para editar';

  @override
  String get reconcileVirtualTrajetEditTitle => 'Editar viagem virtual';

  @override
  String get reconcileVirtualTrajetEditExplainer =>
      'Esta viagem foi adicionada para contabilizar o combustível utilizado enquanto conduzia sem registo. Ajuste a distância ou o combustível, ou elimine-a.';

  @override
  String get reconcileVirtualTrajetDelete => 'Eliminar viagem virtual';

  @override
  String reconcileResolveGapBanner(String gap) {
    return 'Diferença combustível/viagem não resolvida de $gap L — toque para resolver';
  }

  @override
  String get reconcileResolveGapSemanticLabel =>
      'Resolver diferença não resolvida entre combustível e viagens';

  @override
  String get recoveryStillWorksNoStations =>
      'Nothing is wrong — the search simply came back empty.';

  @override
  String get recoveryStillWorksApiKey =>
      'Saved stations and your fill-up history still work.';

  @override
  String get recoveryStillWorksLocation =>
      'You can still search by postal code or city.';

  @override
  String get recoveryStillWorksConnection =>
      'Prices you have already loaded are still shown.';

  @override
  String get recoveryStillWorksRouting =>
      'Nearby search still works — only the route is unavailable.';

  @override
  String get recoveryStillWorksFallback =>
      'Saved stations and your fill-up history still work.';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/sessão';

  @override
  String get refuelCompareAdd => 'Compare';

  @override
  String get refuelCompareRemove => 'Remove from comparison';

  @override
  String get refuelComparePickStations => 'Compare stations';

  @override
  String get refuelComparePickingActive => 'Compare stations, picking is on';

  @override
  String get refuelComparePickPrompt =>
      'Tap the compare button on any station to add it to this comparison.';

  @override
  String get refuelCompareTitle => 'Your comparison';

  @override
  String refuelCompareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String get refuelCompareClear => 'Clear';

  @override
  String refuelCompareFull(int max) {
    return 'You can compare up to $max stations';
  }

  @override
  String refuelCompareContextLine(
    String fuel,
    String quantity,
    String consumption,
  ) {
    return '$fuel · buying $quantity · $consumption';
  }

  @override
  String refuelCompareConsumptionEstimated(String consumption) {
    return '$consumption (estimated)';
  }

  @override
  String get refuelCompareConsumptionMissing =>
      'no consumption yet — add a few fill-ups to see costs';

  @override
  String get refuelCompareQuantityEdit => 'Change the quantity';

  @override
  String get refuelCompareOriginMissing =>
      'Distances are straight-line until a search sets where you are.';

  @override
  String refuelCompareRowCost(String litres, String cash, String distance) {
    return 'Buy $litres · $cash · $distance there and back';
  }

  @override
  String refuelCompareRowStopCost(String litres, String cash, String distance) {
    return 'Buy $litres · $cash · $distance off your route';
  }

  @override
  String get refuelCompareBaseline => 'Cheapest for this quantity';

  @override
  String refuelCompareCostsMore(String amount, String station) {
    return '$amount more than $station';
  }

  @override
  String get refuelCompareDistanceApproximate =>
      'straight-line distance, estimated';

  @override
  String get refuelCompareDistancePending => 'road distance on its way';

  @override
  String refuelCompareNoPrice(String fuel) {
    return 'No price for $fuel here';
  }

  @override
  String get refuelCompareOutOfRange => 'Out of reach on what is in the tank';

  @override
  String get refuelCompareExceedsCapacity =>
      'That quantity would not fit in the tank';

  @override
  String get refuelCompareNotCosted =>
      'Cannot be costed with the current inputs';

  @override
  String get refuelCompareCurrencyWithheld =>
      'Prices are in different currencies and no exchange rate is available, so no cheapest is named.';

  @override
  String get refuelPlanApply => 'Add stops to route';

  @override
  String refuelPlanApplyOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops added to your route',
      one: '1 stop added to your route',
    );
    return '$_temp0';
  }

  @override
  String get refuelPlanApplyRefusedReference =>
      'A reference price is not a place to stop at, so this plan cannot be sent to navigation.';

  @override
  String get refuelPlanApplyRefusedUnavailable =>
      'This country\'s price source is unavailable, so its stops cannot be sent to navigation.';

  @override
  String get refuelPlanApplyFailed => 'Could not open navigation';

  @override
  String get refuelPlanNeedsExchangeRate =>
      'These prices are in another currency and no exchange rate is available, so no comparable total can be shown.';

  @override
  String get refuelPlanLeastDrivingTitle => 'Least extra driving';

  @override
  String refuelPlanStopNamed(int position, String station) {
    return '$position. $station';
  }

  @override
  String refuelPlanStopDetail(String litres, String cost, String arrival) {
    return 'Buy $litres for $cost · arrive with $arrival';
  }

  @override
  String refuelPlanStopNativePrice(String price) {
    return '$price at the pump';
  }

  @override
  String refuelPlanJourneyTotals(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String refuelPlanTradeOff(String cost, String minutes, String distance) {
    return 'Against the cheapest: $cost · $minutes · $distance';
  }

  @override
  String refuelPlanNoStopSummary(String litres) {
    return 'Your tank covers this journey — about $litres used, nothing to buy.';
  }

  @override
  String get refuelPlanDetourTimeApproximate =>
      'Detour times are estimated from the route\'s average speed.';

  @override
  String get refuelPlanSearchBounded =>
      'The best of the itineraries compared — this route has more stations than the planner combines.';

  @override
  String get refuelPlanEvidenceIncomplete =>
      'Some stations were left out — hidden by you, or not listed by this country\'s source — so this is the best among the rest.';

  @override
  String refuelPlanReferencePricesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count reference prices for this area are not places you can stop at',
      one: '1 reference price for this area is not a place you can stop at',
    );
    return '$_temp0';
  }

  @override
  String routeOriginStaleCurrentLocation(String age) {
    return 'Current position ($age ago)';
  }

  @override
  String routeStopOffRoute(String distance) {
    return '$distance from the route';
  }

  @override
  String get routeStopOffRouteQualifier => 'geometric estimate';

  @override
  String get routeStopOffRouteTooltip =>
      'Straight-line distance from this route to the station. Not the distance from you, and not the extra driving a stop would cost.';

  @override
  String stationCardPriceUnit(String currency) {
    return '$currency/L';
  }

  @override
  String stationCardStatus24h(String status) {
    return '$status · 24 h';
  }

  @override
  String mapStationCountTooltip(int count) {
    return '$count stations in the current result set';
  }

  @override
  String get settingsSearchHint => 'Pesquisar definições';

  @override
  String settingsSearchNoResults(String query) {
    return 'Nenhuma definição corresponde a \"$query\"';
  }

  @override
  String get settingsTopicProfilesTitle => 'Perfis e região';

  @override
  String get settingsTopicProfilesSubtitle =>
      'País, idioma, combustível, raio de pesquisa, planeamento de rotas';

  @override
  String get settingsTopicProfilesKeywords =>
      'perfil, país, idioma, combustível, raio, código postal, rota, casa, avaliação, ecrã inicial, profile, country, language, fuel, radius, route, home, rating';

  @override
  String get settingsTopicVehiclesTitle => 'Veículos e OBD2';

  @override
  String get settingsTopicVehiclesSubtitle =>
      'Os seus carros, capacidade do depósito, emparelhamento do adaptador OBD2';

  @override
  String get settingsTopicVehiclesKeywords =>
      'veículo, carro, obd, obd2, adaptador, bluetooth, depósito, motor, vin, calibração, vehicle, car, adapter, tank, engine';

  @override
  String get settingsTopicDrivingTitle => 'Condução e consumo';

  @override
  String get settingsTopicDrivingSubtitle =>
      'Coaching, recompensas, radar de postos, resolução de problemas';

  @override
  String get settingsTopicDrivingKeywords =>
      'coach, eco, háptico, voz, gamificação, radar, deslize, viagem, consumo, clube de combustível, fidelidade, registo obd2, fixar, haptic, voice, trip, consumption, loyalty, pin';

  @override
  String get settingsTopicPricesTitle => 'Preços e alertas';

  @override
  String get settingsTopicPricesSubtitle =>
      'Alertas de preço, anúncios por voz, histórico de preços, relatos da comunidade';

  @override
  String get settingsTopicPricesKeywords =>
      'alerta, notificação, preço, histórico, previsão, melhor altura, comunidade, relato, qr, pagamento, voz, anúncio, alert, price, history, prediction, report, payment, voice';

  @override
  String get settingsTopicUnitsTitle => 'Unidades e apresentação';

  @override
  String get settingsTopicUnitsSubtitle =>
      'Tema, unidade de distância, widget do ecrã inicial';

  @override
  String get settingsTopicUnitsKeywords =>
      'tema, escuro, claro, eco, unidade, km, milhas, widget, cor, apresentação, aspeto, theme, dark, light, unit, miles, display';

  @override
  String get settingsTopicFeaturesTitle =>
      'Funcionalidades e modo de utilização';

  @override
  String get settingsTopicFeaturesSubtitle =>
      'Predefinições do modo de utilização e todos os interruptores de funcionalidades';

  @override
  String get settingsTopicFeaturesKeywords =>
      'funcionalidade, modo, básico, médio, completo, personalizado, interruptor, tipos de posto, postos, carregadores, carregamento, feature, basic, medium, full, custom, switch, toggle, charging';

  @override
  String get settingsTopicDataSourcesTitle => 'Fontes de dados e localização';

  @override
  String get settingsTopicDataSourcesSubtitle =>
      'Chaves API, posição GPS, mudança automática de perfil';

  @override
  String get settingsTopicDataSourcesKeywords =>
      'api, chave, gps, localização, posição, fonte de dados, tankerkoenig, opencharge, key, location';

  @override
  String get settingsTopicSyncTitle => 'Sincronização e conta';

  @override
  String get settingsTopicSyncKeywords =>
      'tanksync, nuvem, conta, e-mail, associar dispositivo, sincronização, partilhar base de dados, anónimo, cloud, account, email, link device, sync, share database, anonymous';

  @override
  String get settingsTopicPrivacyKeywords =>
      'privacidade, consentimento, rgpd, apagar, eliminar, armazenamento, cache, dados, relatório de erros, vin, privacy, consent, gdpr, delete, erase, storage, data, error reporting';

  @override
  String get settingsTopicBackupTitle => 'Cópia de segurança e restauro';

  @override
  String get settingsTopicBackupSubtitle =>
      'Exportar ou restaurar uma cópia de segurança completa dos seus dados';

  @override
  String get settingsTopicBackupKeywords =>
      'cópia de segurança, exportar, restaurar, importar, zip, xml, transferir, backup, export, restore, import, transfer';

  @override
  String get settingsTopicAdvancedSubtitle =>
      'Token do GitHub, ferramentas de programador';

  @override
  String get settingsTopicAdvancedKeywords =>
      'programador, depuração, token, pat, github, diagnóstico, registo de erros, rastreio, developer, debug, diagnostics, error log, trace';

  @override
  String get settingsTopicAboutSubtitle => 'Versão, licenças, ligações';

  @override
  String get settingsTopicAboutKeywords =>
      'acerca, versão, licença, doar, github, atribuição, about, version, license, donate';

  @override
  String get settingsConsumptionOffHint =>
      'Ative o registo de consumo em Funcionalidades e modo de utilização para configurar veículos, coaching e recompensas.';

  @override
  String get settingsOpenFeaturesLink =>
      'Abrir Funcionalidades e modo de utilização';

  @override
  String get settingsRadarTileSubtitle =>
      'Raio, modo de preço, consulta e fixação de ecrã para o perfil ativo';

  @override
  String get settingsRadarNoProfileHint =>
      'Crie primeiro um perfil — as definições do radar são guardadas por perfil.';

  @override
  String get settingsRadarPinHeader => 'Fixação de ecrã';

  @override
  String get settingsAlertsTileSubtitle =>
      'Alertas de posto e de raio que o avisam de descidas de preço';

  @override
  String get settingsPriceFeaturesHeader => 'Funcionalidades de preços';

  @override
  String get settingsVoiceAnnouncementsOffHint =>
      'Os anúncios por voz estão desativados. Ative Feedback por voz e Anúncios por voz em Funcionalidades e modo de utilização para ouvir combustível barato por perto enquanto conduz.';

  @override
  String get settingsDistanceUnitTitle => 'Unidade de distância';

  @override
  String get settingsDistanceUnitSubtitle => 'Do país do perfil ativo';

  @override
  String get settingsObd2AdapterTitle => 'Adaptador OBD2';

  @override
  String get settingsObd2AdapterSubtitle =>
      'Os adaptadores são emparelhados por veículo — abra um veículo para emparelhar ou mudar o seu adaptador';

  @override
  String get settingsPrivacyCrossLinkTitle => 'Consentimentos';

  @override
  String get settingsPrivacyCrossLinkSubtitle =>
      'Os consentimentos de Cloud Sync e de sincronização de viagens estão em Privacidade e dados';

  @override
  String get settingsBackupExportSubtitle =>
      'Veículos, abastecimentos, viagens e registos de carregamento num ficheiro ZIP';

  @override
  String get settingsBackupRestoreSubtitle =>
      'Combine ou substitua os seus dados a partir de um ZIP de cópia de segurança anterior';

  @override
  String get settingsStationTypesLink =>
      'Os tipos de posto definem-se em Funcionalidades e modo de utilização';

  @override
  String get routeSearchCriterionLabel => 'Escolha do posto por troço de rota';

  @override
  String get routeSearchCriterionCheapest => 'Mais barato';

  @override
  String get routeSearchCriterionNearest => 'Mais próximo da rota';

  @override
  String get routeSearchTopNLabel => 'Candidatos por ponto de amostragem';

  @override
  String routeSearchTopNCaption(int count) {
    return 'São considerados até $count postos em cada ponto ao longo da rota.';
  }

  @override
  String get hybridFuelChoiceLabel =>
      'Combustível para a pesquisa de preços (híbrido)';

  @override
  String get hybridFuelChoiceVehicleDefault => 'Predefinição do veículo';

  @override
  String get scopeThisProfile => 'Este perfil';

  @override
  String get scopeAllProfiles => 'Todos os perfis';

  @override
  String get scopeThisVehicle => 'Este veículo';

  @override
  String get featureLabel_manualConsumption => 'Registo manual do consumo';

  @override
  String get featureDescription_manualConsumption =>
      'Registe abastecimentos e sessões de carregamento à mão (não é preciso adaptador OBD2).';

  @override
  String get featureLabel_loyaltyCards => 'Cartões de fidelidade';

  @override
  String get featureDescription_loyaltyCards =>
      'Cartões de clube de combustível / fidelidade com descontos por litro nas comparações de preços.';

  @override
  String get featureLabel_startupTrace =>
      'Rastreio de inicialização no arranque';

  @override
  String get featureDescription_startupTrace =>
      'Regista as fases cronometradas do arranque da app, mostra-as em cascata e exporta-as — um diagnóstico para programadores.';

  @override
  String get locationGpsAutoHint =>
      'A posição GPS é obtida automaticamente ao pesquisar. Também pode atualizá-la manualmente aqui.';

  @override
  String get locationClearGpsBody =>
      'Apagar a posição GPS guardada? Pode atualizá-la novamente a qualquer momento.';

  @override
  String get shareReceiptUnsupportedFormat =>
      'Este tipo de ficheiro ainda não pode ser importado — partilhe uma foto do recibo.';

  @override
  String get shareReceiptFailed =>
      'Não foi possível ler o recibo partilhado — tente partilhá-lo novamente ou adicione o abastecimento manualmente.';

  @override
  String get featureLabel_addFillUpShareIntentReceipt =>
      'Partilhar recibo para importar';

  @override
  String get featureDescription_addFillUpShareIntentReceipt =>
      'Partilhe uma foto de um recibo de outra app para pré-preencher um abastecimento — data, litros, total e posto são lidos no dispositivo.';

  @override
  String get shellTabFind => 'Find';

  @override
  String get shellTabCost => 'Cost';

  @override
  String get shellTabDrive => 'Drive';

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
  String get stationReferencePriceNotice =>
      'Reference price for this area, not a station location — there is nowhere to navigate to.';

  @override
  String get decisionPartialCoverageNote =>
      'This country\'s source lists only some stations, so these picks are the best among the stations shown.';

  @override
  String get errorTitleProviderUnavailable => 'No prices for this country';

  @override
  String get errorProviderUnavailable =>
      'This country\'s price source publishes no live prices at the moment. Retrying will not change that.';

  @override
  String get recoveryStillWorksProviderUnavailable =>
      'Your favorites, fill-ups and searches in other countries still work.';

  @override
  String get storageRecoveryTitle => 'Problema de armazenamento';

  @override
  String get storageRecoveryMessage =>
      'O Sparkilo não conseguiu abrir o seu armazenamento de dados local. O ficheiro de armazenamento parece estar danificado.';

  @override
  String get storageRecoveryGuidance =>
      'Para recuperar, limpe o armazenamento da aplicação nas definições do dispositivo ou reinstale a aplicação. Os seus favoritos e o histórico são guardados apenas neste dispositivo, pelo que não podem ser restaurados automaticamente.';

  @override
  String get storageKeyLostTitle => 'Restored data cannot be read';

  @override
  String get storageKeyLostMessage =>
      'This install was restored from a backup, which brought back Sparkilo\'s data but not the key that unlocks it. Android keeps that key in the phone\'s secure hardware, and it cannot be copied to another device or restored from a backup.';

  @override
  String get storageKeyLostGuidance =>
      'The restored history cannot be recovered. Clear the app’s storage in your device settings to start fresh — then sign in to TankSync and everything you had synced comes back.';

  @override
  String syncAdoptTitle(String email) {
    return 'Juntar-se à conta de $email';
  }

  @override
  String get syncAdoptSubtitle =>
      'Inicie sessão com a palavra-passe desta conta para partilhar os seus dados entre os dois dispositivos.';

  @override
  String get syncAdoptPasswordLabel => 'Palavra-passe da conta';

  @override
  String get syncAdoptJoinButton => 'Juntar-se à conta';

  @override
  String get syncAdoptUseDifferentAccount => 'Usar outra conta';

  @override
  String get syncDeleteDataTitle => 'Eliminar dados sincronizados';

  @override
  String get syncDeleteDataSubtitle =>
      'Remover as suas viagens, veículos ou abastecimentos da base de dados de sincronização';

  @override
  String get syncDeleteDataPickTitle => 'Que dados sincronizados eliminar?';

  @override
  String get syncDeleteDataCategoryTrips => 'Viagens';

  @override
  String get syncDeleteDataCategoryVehicles => 'Veículos';

  @override
  String get syncDeleteDataCategoryFillUps => 'Abastecimentos';

  @override
  String get syncDeleteDataCategoryEverything => 'Tudo';

  @override
  String syncDeleteDataConfirmTitle(String category) {
    return 'Eliminar $category da base de dados de sincronização?';
  }

  @override
  String get syncDeleteDataConfirmBody =>
      'Remove os dados selecionados da sua base de dados de sincronização e estes não voltarão a sincronizar a partir dos seus outros dispositivos. Os dados guardados localmente neste dispositivo são mantidos.';

  @override
  String get syncDeleteDataConfirmAction => 'Eliminar do servidor';

  @override
  String get syncDeleteDataDone => 'Dados sincronizados eliminados';

  @override
  String get syncDeleteDataDonePending =>
      'Deleted. Your other devices will drop it the next time this device syncs.';

  @override
  String get syncDeleteDataDoneSchemaOutdated =>
      'Deleted on the server — but your sync database is outdated, so another device could re-upload it. Re-run the setup SQL.';

  @override
  String get syncDeleteDataFailed =>
      'A eliminação dos dados sincronizados falhou — tente novamente';

  @override
  String get syncRelinkTitle =>
      'A sincronização na nuvem precisa de ser reassociada';

  @override
  String get syncRelinkBody =>
      'A identidade de sincronização guardada neste dispositivo tem a sessão terminada. Inicie sessão com o seu e-mail para voltar a associar os seus dados sincronizados, ou comece de novo com uma identidade nova.';

  @override
  String get syncRelinkSignInAction => 'Iniciar sessão para voltar a associar';

  @override
  String get syncRelinkStartFreshAction => 'Começar de novo';

  @override
  String get syncRelinkStartFreshTitle => 'Começar de novo?';

  @override
  String get syncRelinkStartFreshBody =>
      'Será criada uma nova identidade anónima para este dispositivo. Os dados sincronizados com a identidade antiga permanecem no servidor, mas deixarão de estar acessíveis a partir daqui, a menos que inicie sessão com a respetiva conta de e-mail.';

  @override
  String get syncRelinkStartFreshConfirm => 'Começar de novo';

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
  String tankLevelRangeLastIntervalFormat(String kilometres) {
    return '≈ $kilometres km com o consumo do seu último depósito';
  }

  @override
  String tankLevelRangeLongRunFormat(String kilometres) {
    return 'Média de longo prazo: ≈ $kilometres km';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Último abastecimento: $date · $count viagem(ns) desde então';
  }

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
  String tankLevelSourceFillUp(String date) {
    return 'Ancorado no último abastecimento: $date';
  }

  @override
  String tankLevelSourceObd2(String date) {
    return 'Sensor do depósito OBD2 · $date';
  }

  @override
  String tankMixCaption(String mix) {
    return 'Mistura no depósito: $mix';
  }

  @override
  String get tankReportTitle => 'Relatório do depósito';

  @override
  String tankReportSincePrevious(String km, String liters, String cost) {
    return 'Desde o depósito cheio anterior: $km km · $liters L · $cost';
  }

  @override
  String tankReportTrendUp(String delta) {
    return '$delta L/100 km a mais do que o depósito anterior';
  }

  @override
  String tankReportTrendDown(String delta) {
    return '$delta L/100 km a menos do que o depósito anterior';
  }

  @override
  String get tankReportTrendFlat => 'Ao nível do depósito anterior';

  @override
  String get tankReportNoPrevious =>
      'A evolução aparece após o seu próximo depósito cheio.';

  @override
  String get tankReportExplainHeader => 'O que as gravações sugerem';

  @override
  String tankReportFactorHighRpm(String cur, String prev) {
    return 'Quota a rotações altas $cur % (antes $prev %)';
  }

  @override
  String tankReportFactorHarsh(String cur, String prev) {
    return 'Manobras bruscas $cur/100 km (antes $prev)';
  }

  @override
  String tankReportFactorColdStarts(String cur, String prev) {
    return 'Arranques a frio $cur (antes $prev)';
  }

  @override
  String tankReportFactorIdle(String cur, String prev) {
    return 'Quota ao ralenti $cur % (antes $prev %)';
  }

  @override
  String get tankReportCaveat =>
      'As gravações são espontâneas e cobrem apenas parte deste depósito — estas pistas são indicativas, não a história completa.';

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
  String get tripStartStepAdapter => 'OBD2 adapter';

  @override
  String get tripStartStepVehicle => 'Vehicle data';

  @override
  String get tripStartStepRecording => 'Recording';

  @override
  String tripStartSlowHint(String action) {
    return 'Reaching the adapter usually takes a few seconds. If it stays here, pick \"$action\" from the menu above.';
  }

  @override
  String get tripStartProgressConnectingAdapter => 'A ligar ao adaptador OBD2…';

  @override
  String get tripStartProgressReadingVehicleData => 'A ler dados do veículo…';

  @override
  String get tripStartProgressStartingRecording => 'A iniciar gravação…';

  @override
  String get tripSaveProgressFinalizingSummary => 'A finalizar resumo…';

  @override
  String get tripSaveProgressSavingToHistory => 'A guardar no histórico…';

  @override
  String get tripSaveProgressSyncingToCloud =>
      'A sincronizar em segundo plano…';

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
  String get trajetDetailChartThrottle => 'Acelerador / pedal (%)';

  @override
  String get trajetDetailChartCoolant => 'Refrigerante (°C)';

  @override
  String get trajetDetailChartAltitudeRelative =>
      'Altitude (m, desde o início)';

  @override
  String get trajetDetailChartLambda => 'λ comandado';

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
  String get trajetDetailChartEstimatedBadge => 'estimado';

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
  String get trajetDetailDownloadCsvOption => 'Transferir telemetria (CSV)';

  @override
  String get trajetDetailDownloadJsonOption => 'Transferir telemetria (JSON)';

  @override
  String get trajetDetailDownloadError => 'Não foi possível guardar o ficheiro';

  @override
  String get trajetDetailDeleteAction => 'Eliminar';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Eliminar esta viagem?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Esta viagem será permanentemente removida do seu histórico.';

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
  String get trajetDetailChartBoost =>
      'Pressão de sobrealimentação (MAP − ambiente)';

  @override
  String get trajetDetailChartIat => 'Temperatura do ar de admissão';

  @override
  String get trajetDetailChartTiming => 'Avanço de ignição';

  @override
  String get trajetObd2Degraded =>
      'Iniciado com o adaptador OBD2 mas gravado sobretudo por GPS — os dados do motor estão incompletos';

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
  String get tripPathLegendEfficient => 'Eficiente (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Aceitável (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Dispendioso (≥ 10 L/100km)';

  @override
  String get tripRadarClosestStation => 'Radar de Postos de Combustível';

  @override
  String get tripRadarScanning => 'À procura de postos próximos';

  @override
  String get tripRadarNoStationNearby => 'Nenhum posto nas proximidades';

  @override
  String get fuelStationRadarNearer => 'Posto mais próximo';

  @override
  String get fuelStationRadarFarther => 'Posto mais afastado';

  @override
  String get fuelStationRadarStart => 'Iniciar radar de postos de combustível';

  @override
  String get stopRadar => 'Parar radar';

  @override
  String get fuelStationRadarResultBadge =>
      'Resultado do Radar de Postos de Combustível';

  @override
  String get radarUpdatingLocation => 'A atualizar a sua localização…';

  @override
  String get radarSearching => 'A pesquisar…';

  @override
  String get highwayModeChip =>
      'Modo autoestrada — a mostrar os postos à sua frente na rota';

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
  String get tripRecordingSavingTitle => 'A guardar viagem…';

  @override
  String get tripRecordingDiscardedNoMovement =>
      'Gravação descartada — nenhum movimento detetado';

  @override
  String get tripRecordingGpsNotificationTitle => 'A gravar a sua viagem';

  @override
  String get tripRecordingGpsNotificationText =>
      'A monitorizar o seu percurso para estatísticas de combustível e condução';

  @override
  String get tripSaveFailedKept =>
      'Couldn\'t save this trip — it\'s kept and will be retried';

  @override
  String get tripSaveRetryAction => 'Retry';

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
  String get tripShareNotSyncedYet =>
      'This trip hasn\'t reached your sync database yet — try again in a moment.';

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
  String get tripVerdictPromptTitle => 'Como correu esta viagem?';

  @override
  String get tripVerdictSmooth => 'Suave';

  @override
  String get tripVerdictModerate => 'Moderada';

  @override
  String get tripVerdictAggressive => 'Agressiva';

  @override
  String get tripVerdictDismiss => 'Agora não';

  @override
  String get tripVerdictThanks =>
      'Obrigado — isto ajuda a calibrar a análise da sua condução.';

  @override
  String get fillUpDeletedUndoSnackbar => 'Abastecimento eliminado';

  @override
  String get trajetDeletedUndoSnackbar => 'Gravação eliminada';

  @override
  String get searchFailedSnackbar => 'Pesquisa falhada — tente novamente';

  @override
  String routeStationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postos',
      one: '1 posto',
    );
    return '$_temp0';
  }

  @override
  String stationUpdatedLabel(String time) {
    return 'Atualizado $time';
  }

  @override
  String amenityMoreTooltip(String names) {
    return 'Também: $names';
  }

  @override
  String get favoriteAdd => 'Adicionar aos favoritos';

  @override
  String get favoriteRemove => 'Remover dos favoritos';

  @override
  String loyaltyRawPriceTooltip(String price) {
    return 'Preço base: $price';
  }

  @override
  String routeDataSourceMulti(String sources) {
    return '$sources';
  }

  @override
  String get stationUnbrandedTitle => 'Posto sem marca';

  @override
  String get unsupportedRegionTitle => 'Ainda não disponível na sua região';

  @override
  String get unsupportedRegionBody =>
      'Ainda não temos preços de combustível para o seu país, pelo que os resultados podem estar vazios ou ser de outro país. Pode, mesmo assim, escolher um país suportado nas definições de pesquisa.';

  @override
  String get unsupportedRegionDismiss => 'Entendido';

  @override
  String get configureCountryTitle => 'Defina o seu país';

  @override
  String get configureCountryBody =>
      'O seu país é suportado, mas ainda não está configurado — por isso os preços podem ser de outro país. Escolha o seu país nas definições de pesquisa para ver os preços locais.';

  @override
  String get radiusAlertCenterChipGps => 'A minha posição';

  @override
  String get radiusAlertCenterChipMap => 'Ponto no mapa';

  @override
  String radiusAlertCenterChipPostal(String postalCode) {
    return 'Código postal $postalCode';
  }

  @override
  String get radiusAlertCenterClear => 'Limpar localização';

  @override
  String get radiusAlertBlockerLabel => 'Introduza uma etiqueta';

  @override
  String get radiusAlertBlockerThreshold => 'Introduza um limite acima de 0';

  @override
  String get radiusAlertBlockerLocation => 'Escolha uma localização';

  @override
  String get allPricesNoPriceMask => '—';

  @override
  String get allPricesBestMarker => 'best';

  @override
  String allPricesDelta(String amount) {
    return '+$amount';
  }

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
  String get fillInventoryTitle => 'Balanço do abastecimento';

  @override
  String fillInventorySubtitleFull(String date, String fuel) {
    return 'Depósito cheio em $date · $fuel';
  }

  @override
  String fillInventorySubtitlePartial(String date, String fuel) {
    return 'Abastecimento parcial em $date · $fuel';
  }

  @override
  String fillInventoryKmSinceLastFull(String km) {
    return '$km km desde o último depósito cheio';
  }

  @override
  String fillInventoryPumpLiters(String liters) {
    return '$liters L abastecidos';
  }

  @override
  String fillInventoryPumpConsumption(String value) {
    return 'Consumo na bomba: $value';
  }

  @override
  String fillInventoryRecordedTrips(int coverage, String value) {
    return 'Viagens gravadas: $coverage % do depósito · $value em bruto';
  }

  @override
  String get fillInventoryNoRecordedTrips =>
      'Nenhuma viagem gravada neste depósito';

  @override
  String fillInventoryTankNow(String liters, String km) {
    return 'Depósito agora: $liters L · ≈ $km km ao consumo da bomba';
  }

  @override
  String fillInventoryTankNowNoRange(String liters) {
    return 'Depósito agora: $liters L';
  }

  @override
  String fillInventoryCalibrationApplied(
    String before,
    String after,
    String percent,
  ) {
    return 'Calibração da bomba: ×$before → ×$after ($percent %)';
  }

  @override
  String fillInventoryCalibrationSkipped(String reason) {
    return 'Calibração da bomba: ignorada — $reason';
  }

  @override
  String get fillInventorySkipNotFullTank =>
      'abastecimento parcial (a janela do depósito continua aberta)';

  @override
  String get fillInventorySkipCorrection =>
      'entrada de correção, não um abastecimento na bomba';

  @override
  String get fillInventorySkipNoVehicle => 'sem veículo neste abastecimento';

  @override
  String get fillInventorySkipNoWindow =>
      'primeiro depósito cheio (ainda nenhuma janela fechada)';

  @override
  String get fillInventorySkipMixedFuel =>
      'the tank held a mix of grades, so it cannot calibrate one';

  @override
  String fillInventorySkipCoverageTooLow(int coverage) {
    return 'as viagens gravadas cobrem $coverage % do depósito (são necessários 60 %)';
  }

  @override
  String fillInventorySkipRecordedTooShort(String km) {
    return 'apenas $km km gravados (são necessários 40 km)';
  }

  @override
  String get fillInventorySkipNoRecordedFuel =>
      'as viagens gravadas não têm valor de combustível';

  @override
  String get fillInventorySkipImplausible =>
      'a bomba e as gravações divergem demasiado — verifique o recibo';

  @override
  String get fillInventoryDismiss => 'Percebido';

  @override
  String get tripFuelSourceMeasured => 'Medido';

  @override
  String get tripFuelSourceEstimatedCalibrated => 'Estimado · calibrado';

  @override
  String get tripFuelSourceEstimated => 'Estimado';

  @override
  String get tripFuelSourceGps => 'GPS';

  @override
  String get tripFuelSourceMeasuredTooltip =>
      'Caudal de combustível comunicado pelo motor (PID 5E / 9D / A2) — nunca reescalado';

  @override
  String get tripFuelSourceEstimatedTooltip =>
      'Combustível estimado a partir da massa de ar — reescalado pela calibração da bomba';

  @override
  String get tripFuelSourceGpsTooltip =>
      'Estimativa física por GPS — sem dados do motor';

  @override
  String get tripFuelSourceRecalculated => 'recalculado';

  @override
  String tripDetailGainApplied(String percent) {
    return 'Ganho da bomba aplicado: $percent %';
  }

  @override
  String tripDetailRecalculatedAfterFill(String date) {
    return 'Recalculado após o abastecimento de $date';
  }

  @override
  String get criteriaModeNearby => 'Nearby';

  @override
  String get criteriaModeRoute => 'Route';

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
  String get criteriaRadiusCustom => 'Custom';

  @override
  String get criteriaIntentHeader => 'What are you looking for?';

  @override
  String get criteriaIntentCheapestNearby => 'Cheapest nearby';

  @override
  String get criteriaIntentBestStop => 'Best stop';

  @override
  String get criteriaIntentOnMyRoute => 'On my route';

  @override
  String get criteriaIntentFastest => 'Fastest';

  @override
  String get criteriaIntentFavourite => 'A favourite';

  @override
  String get criteriaIntentCustom => 'Custom';

  @override
  String get criteriaIntentNeedsConsumption =>
      'Add a fill-up first so we know your consumption';

  @override
  String get fillUpOdometerFromLastFillUp =>
      'Pré-preenchido a partir do seu último abastecimento';

  @override
  String get fillUpStationLabel => 'Posto';

  @override
  String get fillUpStationChange => 'Alterar';

  @override
  String get pickStationSectionLast => 'Último posto';

  @override
  String get pickStationSectionFavorites => 'Favoritos';

  @override
  String get pickStationSectionNearby => 'Nas proximidades';

  @override
  String get pickStationNearbyEmpty =>
      'Sem pesquisa recente — pesquise postos no separador Pesquisa e os mais próximos aparecerão aqui.';

  @override
  String pickStationLastFillUpAt(String date) {
    return 'Último abastecimento: $date';
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
  String get homeNextStopTitle => 'Your next fuel stop';

  @override
  String get homeVehicleTitle => 'Your car';

  @override
  String get homeVehicleCostPerKm => 'per km';

  @override
  String get homeVehicleConsumption => 'L/100 km';

  @override
  String get homeVehicleFromFillUps => 'Measured from your fill-ups';

  @override
  String get homeSavingsTitle => 'You\'ve saved';

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
      'As suas escolhas, dados neste dispositivo, sincronização, exportar ou eliminar';

  @override
  String get privacyDataLocationLocal =>
      'Os seus dados ficam neste dispositivo';

  @override
  String get privacyDataLocationSynced =>
      'Os seus dados são também sincronizados com o TankSync';

  @override
  String get privacySyncLineEnabledAnonymous =>
      'Sincronização: ligada · conta anónima';

  @override
  String get privacySyncLineEnabledEmail =>
      'Sincronização: ligada · conta de e-mail';

  @override
  String get privacySyncLineDisabled => 'Sincronização: desligada';

  @override
  String privacyStorageLine(String size) {
    return '$size armazenados neste dispositivo';
  }

  @override
  String get privacyTopicChoicesTitle => 'As suas escolhas';

  @override
  String privacyChoicesStatus(int on, int total) {
    return '$on de $total ativadas';
  }

  @override
  String privacyDeviceDataStatus(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorias',
      one: '1 categoria',
    );
    return '$size · $_temp0';
  }

  @override
  String get privacyTopicExportDeleteTitle => 'Exportar ou eliminar';

  @override
  String privacyExportDeleteStatus(int count) {
    return 'ZIP, JSON, CSV · registo de erros ($count)';
  }

  @override
  String get privacyLearnMore => 'Saber mais';

  @override
  String get tileProxyToggleShort =>
      'Os mosaicos chegam através do proxy da UE do programador, não diretamente do OpenStreetMap';

  @override
  String get remoteLogosToggleShort =>
      'Obter logótipos de marcas de logo.clearbit.com em vez dos marcadores incluídos na aplicação';

  @override
  String get privacyCacheDetails => 'Detalhes da cache';

  @override
  String privacyCacheResponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas em cache',
      one: '1 resposta em cache',
    );
    return '$_temp0';
  }

  @override
  String privacyClearCacheEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return 'Limpar cache ($_temp0)';
  }

  @override
  String get privacySyncStatusLabel => 'Estado';

  @override
  String get privacySyncModeCommunity =>
      'Comunidade Sparkilo — o servidor da UE do programador';

  @override
  String get privacySyncModeSelfHosted =>
      'Auto-alojado — o seu próprio Supabase';

  @override
  String get privacySyncModeSharedGroup =>
      'Grupo partilhado — uma base de dados a que aderiu';

  @override
  String get privacySyncAccountLabel => 'Conta';

  @override
  String get privacySyncAccountAnonymous =>
      'Conta anónima, associada a este dispositivo';

  @override
  String privacySyncAccountEmail(String email) {
    return 'Conta de e-mail: $email';
  }

  @override
  String get privacyCopyUserId => 'Copiar ID de utilizador';

  @override
  String get privacyUserIdCopied => 'ID de utilizador copiado';

  @override
  String get privacySyncDatabaseHost => 'Anfitrião da base de dados';

  @override
  String get privacyExportSectionTitle => 'Exportar';

  @override
  String get privacyExportMyData => 'Exportar os meus dados';

  @override
  String get privacyExportSheetTitle => 'Escolha um formato';

  @override
  String get privacyExportZipTitle => 'Arquivo ZIP';

  @override
  String get privacyExportZipSubtitle =>
      'Tudo, anexos incluídos — para uma cópia de segurança completa';

  @override
  String get privacyExportJsonTitle => 'JSON';

  @override
  String get privacyExportJsonSubtitle =>
      'Legível por máquina — para outra aplicação';

  @override
  String get privacyExportCsvTitle => 'CSV';

  @override
  String get privacyExportCsvSubtitle =>
      'Folha de cálculo — uma tabela por categoria';

  @override
  String get privacyErrorLogTitle => 'Registo de erros';

  @override
  String privacyErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
      zero: 'Sem entradas',
    );
    return '$_temp0';
  }

  @override
  String get privacyErrorLogSave => 'Guardar';

  @override
  String get privacyErrorLogClear => 'Limpar';

  @override
  String get privacyDangerZoneTitle => 'Zona de perigo';

  @override
  String get privacyDangerZoneBody =>
      'Elimina permanentemente tudo o que a aplicação armazena neste dispositivo. Com a sincronização ligada, os seus dados no servidor TankSync são igualmente apagados.';

  @override
  String get privacyDeleteAllMyData => 'Eliminar todos os meus dados';

  @override
  String get tripRecordingScreenTitle => 'Viagem em curso';

  @override
  String get recordingObd2ChipLive => 'Em direto';

  @override
  String recordingObd2ChipLiveRate(int rate) {
    return 'Em direto · $rate PID/s';
  }

  @override
  String get recordingObd2ChipReconnecting => 'A reconectar…';

  @override
  String recordingObd2ChipReconnectingAttempt(int attempt) {
    return 'A reconectar… (tentativa $attempt)';
  }

  @override
  String get recordingObd2ChipGpsOnly => 'Apenas GPS';

  @override
  String get recordingObd2ChipEngineOff => 'Motor desligado — à espera';

  @override
  String get recordingObd2ChipNoAdapter => 'Sem adaptador';

  @override
  String get recordingObd2SheetTitle => 'Ligação OBD2';

  @override
  String get recordingObd2SheetLive =>
      'O adaptador está a fornecer dados do motor, pelo que o consumo é medido a partir do carro. Nada a fazer — continue a conduzir.';

  @override
  String get recordingObd2SheetReconnecting =>
      'A ligação Bluetooth está a ser restabelecida; entretanto, a gravação continua por GPS. Não é necessária qualquer ação — uma reposição só ajuda se ficar assim durante minutos.';

  @override
  String get recordingObd2SheetGpsOnly =>
      'O adaptador não responde há algum tempo, pelo que a aplicação aguarda que reapareça e grava por GPS. O consumo é estimado até que volte.';

  @override
  String get recordingObd2SheetEngineOff =>
      'O motor está desligado, pelo que não há nada para ler. A gravação continua por GPS e retoma o adaptador assim que o motor trabalhar.';

  @override
  String get recordingObd2SheetNoAdapter =>
      'Esta viagem é gravada sem adaptador OBD2. A velocidade e a distância vêm do GPS; o consumo é uma estimativa física calibrada pelos seus abastecimentos.';

  @override
  String recordingGpsChipPrecise(int meters) {
    return 'Posição precisa (±$meters m)';
  }

  @override
  String recordingGpsChipApprox(int meters) {
    return 'Posição aproximada (±$meters m)';
  }

  @override
  String get recordingGpsChipNoFix => 'Sem posição';

  @override
  String get recordingGpsChipFixUnknownAccuracy =>
      'Posição (precisão desconhecida)';

  @override
  String recordingGpsChipWithCoverage(String fix, int percent) {
    return '$fix · $percent %';
  }

  @override
  String get recordingGpsSheetTitle => 'Sinal GPS';

  @override
  String get recordingGpsSheetPrecise =>
      'A posição tem uma precisão de poucos metros, pelo que a distância e o traçado são fiáveis.';

  @override
  String get recordingGpsSheetApprox =>
      'A posição só tem uma precisão de dezenas de metros — típico em cidades, túneis ou debaixo de árvores. A distância pode desviar-se ligeiramente até a posição melhorar.';

  @override
  String get recordingGpsSheetNoFix =>
      'Não chegou nenhuma posição recentemente. Verifique se a localização está permitida e se o telemóvel tem vista para o céu; a gravação retoma com a próxima posição.';

  @override
  String recordingGpsSheetCoverage(int percent) {
    return 'Cobertura até agora: $percent % dos segundos tiveram posição.';
  }

  @override
  String get recordingSheetClose => 'Percebido';

  @override
  String get fuelSourceMeasured => 'Medido (caudal de combustível da ECU)';

  @override
  String fuelSourceEstimatedCalibrated(int percent) {
    return 'Estimado · calibrado pela bomba ±$percent %';
  }

  @override
  String get fuelSourceEstimatedUncalibrated => 'Estimado · não calibrado';

  @override
  String get fuelSourceGpsEstimate => 'Estimativa GPS';

  @override
  String get recordingTileScore => 'Pontuação de condução';

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
  String get sortMenuByName => 'Sort by name (A–Z)';

  @override
  String get sortMenuOpen24h => '24-hour stations first';

  @override
  String get sortMenuPriceDistance => 'Sort by price per kilometre';

  @override
  String sortMenuActiveSemantic(String option) {
    return '$option, current sort';
  }

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
  String pricesNotSoldHere(String fuels) {
    return 'Não vendido aqui: $fuels';
  }

  @override
  String tankReportRecordedTripsCoverage(String pct) {
    return 'As viagens gravadas cobrem $pct % deste depósito';
  }

  @override
  String tankReportRecordedTripsOverestimate(String pct) {
    return 'As suas viagens gravadas sobrestimam o consumo em $pct %';
  }

  @override
  String tankReportRecordedTripsUnderestimate(String pct) {
    return 'As suas viagens gravadas subestimam o consumo em $pct %';
  }

  @override
  String get trajetObd2DegradedSubtitle =>
      'Sem dados do motor — estimativa GPS';

  @override
  String get vehicleTopicAdapterNone => 'Nenhum';

  @override
  String get vehicleTopicCalibrationTitle => 'Calibração';

  @override
  String get vehicleTopicAdvancedBadge => 'Avançado';

  @override
  String vehicleTopicCalibrationStatus(int coverage, String mode) {
    return 'Referência $coverage % · $mode';
  }

  @override
  String vehicleTopicRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lembretes',
      one: '1 lembrete',
      zero: 'Sem lembretes',
    );
    return '$_temp0';
  }

  @override
  String get vehicleTopicAutoRecordOn => 'Ligada';

  @override
  String get vehicleTopicAutoRecordOff => 'Desligada';

  @override
  String get vehicleTopicAutoRecordPairLinkText =>
      'Emparelhe um adaptador em “Adaptador OBD2” para ativar a gravação automática';

  @override
  String vehicleBaselineCoverageSamples(int covered, int max) {
    return '$covered / $max amostras';
  }

  @override
  String vehicleBaselineRawSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amostras',
      one: '1 amostra',
    );
    return '$_temp0';
  }

  @override
  String get calibrationModeRuleDescription =>
      'Atribui cada amostra de condução a uma única situação usando limiares fixos de velocidade e carga.';

  @override
  String get calibrationModeFuzzyDescription =>
      'Distribui cada amostra pelas situações vizinhas de acordo com o grau de adequação a cada uma — estimativas mais suaves em torno dos limites.';

  @override
  String get pumpGainChipNotCalibrated => 'Ainda não calibrado pela bomba';

  @override
  String pumpGainChipCalibrated(int fills, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      fills,
      locale: localeName,
      other: 'Calibrado pela bomba · $fills abastecimentos · ±$percent %',
      one: 'Calibrado pela bomba · 1 abastecimento · ±$percent %',
    );
    return '$_temp0';
  }

  @override
  String get pumpGainResetAction => 'Repor calibração da bomba';

  @override
  String get pumpGainResetConfirmTitle => 'Repor calibração da bomba?';

  @override
  String get pumpGainResetConfirmBody =>
      'Isto descarta o ganho de combustível aprendido a partir dos seus abastecimentos. As estimativas de consumo OBD2 voltam ao valor não corrigido até que a próxima janela de depósito cheio a cheio o reaprenda.';

  @override
  String get vehCompareTitle => 'Compare vehicles';

  @override
  String get vehCompareOpenTooltip => 'Compare vehicles';

  @override
  String get vehCompareSelectHint => 'Pick at least two vehicles to compare.';

  @override
  String get vehCompareNotEnoughVehicles =>
      'Add a second vehicle profile before comparing histories.';

  @override
  String get vehCompareHonestyNote =>
      'These figures come from your own records, at the prices you actually paid. They do not measure how efficient a vehicle is in itself, they do not predict what a future trip will cost, and they are not savings against a price this app never saw.';

  @override
  String get vehComparePeriodLabel => 'Period';

  @override
  String get vehComparePeriodAll => 'All history';

  @override
  String get vehComparePeriodYear => 'Last 12 months';

  @override
  String get vehComparePeriodQuarter => 'Last 90 days';

  @override
  String get vehCompareBoundaryPolicyLabel => 'Tanks crossing the period edge';

  @override
  String get vehCompareBoundaryClosing => 'Count the whole tank it ended in';

  @override
  String get vehCompareBoundaryContained => 'Only tanks entirely inside';

  @override
  String get vehCompareBoundaryNote =>
      'A tank is never split at a date. Its litres were measured over the whole tank, so the whole tank is counted or none of it is.';

  @override
  String vehCompareReferenceLabel(String vehicle) {
    return 'Differences shown against $vehicle';
  }

  @override
  String get vehCompareSetReference => 'Use as reference';

  @override
  String get vehCompareEvidenceTitle => 'Evidence';

  @override
  String vehCompareWindowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count closed tanks',
      one: '1 closed tank',
      zero: 'No closed tank',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareMatchedDistance => 'Matched distance';

  @override
  String get vehCompareRecordedDistance => 'Recorded distance';

  @override
  String vehCompareTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorded drives',
      one: '1 recorded drive',
      zero: 'No recorded drive',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareConsumptionTitle => 'Observed consumption';

  @override
  String get vehCompareCostTitle => 'Cost';

  @override
  String get vehCompareCostPerKmLabel => 'Per km, tank purchases';

  @override
  String get vehCompareConsumedFuelLabel => 'Per km, fuel burned (modelled)';

  @override
  String get vehCompareRecordedSpendLabel => 'Paid at the pump';

  @override
  String get vehComparePricePerUnitLabel => 'Average price paid';

  @override
  String get vehCompareRefuellingTitle => 'Refuelling';

  @override
  String get vehCompareFillCountLabel => 'Pump visits';

  @override
  String get vehCompareTotalQuantityLabel => 'Total pumped';

  @override
  String get vehCompareTypicalQuantityLabel => 'Typical fill';

  @override
  String get vehCompareFullPartialLabel => 'Full / partial';

  @override
  String vehCompareFullPartialValue(int full, int partial) {
    return '$full full, $partial partial';
  }

  @override
  String get vehCompareBetweenFillsLabel => 'Between refuels';

  @override
  String vehCompareBetweenFillsDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareCorrectionsLabel => 'Corrections';

  @override
  String get vehCompareStationsTitle => 'Stations';

  @override
  String vehCompareStationUnnamed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fills with no station recorded',
      one: '1 fill with no station recorded',
    );
    return '$_temp0';
  }

  @override
  String vehCompareStationVisits(String station, int count) {
    return '$station: $count';
  }

  @override
  String get vehCompareRangeLabel => 'Estimated range';

  @override
  String vehCompareFuelShare(String fuel, String share) {
    return '$fuel: $share';
  }

  @override
  String vehCompareBoundaryIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanks opened before this period and were counted whole.',
      one: '1 tank opened before this period and was counted whole.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareBoundaryExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanks crossed the period edge and were left out.',
      one: '1 tank crossed the period edge and was left out.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareOpeningCarried(String date) {
    return 'The first counted tank was filled on $date, before this period — its fuel is carried forward, not re-counted.';
  }

  @override
  String get vehCompareMissingVehicle =>
      'This vehicle is no longer on record, so its figures cannot be recomputed. The selection is kept so you can restore it.';

  @override
  String get vehCompareRemoveFromSelection => 'Remove from the comparison';

  @override
  String vehCompareUnassignedFills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fill-ups belong to no vehicle and count for none of these columns.',
      one:
          '1 fill-up belongs to no vehicle and counts for none of these columns.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareAmbiguousFills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fill-ups could belong to more than one of these vehicles and count for none.',
      one:
          '1 fill-up could belong to more than one of these vehicles and counts for none.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareUnassignedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorded drives belong to no vehicle.',
      one: '1 recorded drive belongs to no vehicle.',
    );
    return '$_temp0';
  }

  @override
  String vehCompareWinnerConsumption(String vehicle) {
    return 'Lowest observed consumption: $vehicle';
  }

  @override
  String vehCompareWinnerCost(String vehicle) {
    return 'Lowest observed cost per km: $vehicle';
  }

  @override
  String vehCompareNoWinner(String reason) {
    return 'No vehicle can be named here: $reason';
  }

  @override
  String get vehCompareSourcesAction => 'Show the records';

  @override
  String get vehCompareSourcesTitle => 'Records behind this figure';

  @override
  String vehCompareSourcesFills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fill-ups',
      one: '1 fill-up',
      zero: 'No fill-up',
    );
    return '$_temp0';
  }

  @override
  String vehCompareSourcesWindows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count closed tanks',
      one: '1 closed tank',
      zero: 'No closed tank',
    );
    return '$_temp0';
  }

  @override
  String vehCompareSourcesTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drives',
      one: '1 drive',
      zero: 'No drive',
    );
    return '$_temp0';
  }

  @override
  String get vehCompareUnavailableShort => 'Not comparable';

  @override
  String get vehCompareEstimateBadge => 'Estimate';

  @override
  String vehCompareSemanticsColumn(String vehicle, int index, int total) {
    return '$vehicle, vehicle $index of $total';
  }

  @override
  String vehCompareSemanticsMetric(String label, String value, String vehicle) {
    return '$label: $value, $vehicle';
  }

  @override
  String get vehCompareReasonNoEvidence => 'Nothing on record for this figure.';

  @override
  String get vehCompareReasonTooFewSamples =>
      'Too few closed tanks to compare.';

  @override
  String get vehCompareReasonNoMatchedDistance =>
      'No matched distance to divide by.';

  @override
  String get vehCompareReasonMixedCurrencies =>
      'Amounts in more than one currency, and no conversion was chosen.';

  @override
  String get vehCompareReasonUnknownCurrency =>
      'Some amounts have no recorded currency.';

  @override
  String get vehCompareReasonExchangeRateUnavailable =>
      'No exchange rate relates these currencies.';

  @override
  String get vehCompareReasonExchangeRateStale =>
      'The exchange rate is too old to decide this.';

  @override
  String get vehCompareReasonIncompatibleUnits =>
      'These quantities are measured in different units.';

  @override
  String get vehCompareReasonUnsupportedUnit =>
      'This fuel is not sold by the litre, so there is no L/100 km figure.';

  @override
  String get vehCompareReasonAmbiguousAttribution =>
      'These records cannot be attributed to exactly one vehicle.';

  @override
  String get vehCompareReasonMissingPrices =>
      'Some fills in the counted tanks carry no price.';

  @override
  String get vehCompareReasonNoExpectedConsumption =>
      'No expected consumption is recorded, so nothing can be adjusted against it.';

  @override
  String get vehCompareReasonIncompleteConditionCoverage =>
      'Not every driving condition was evaluated.';

  @override
  String get vehCompareQualUncontrolledConditions =>
      'Hills, cold and traffic are not accounted for.';

  @override
  String get vehCompareQualPartialConditionCoverage =>
      'Only cold starts are recorded; gradient and stop-and-go are not.';

  @override
  String get vehCompareQualUnequalSampleSizes =>
      'The vehicles rest on very different amounts of evidence.';

  @override
  String get vehCompareQualEstimatedBasis => 'Modelled, not measured.';

  @override
  String get vehCompareQualStaleBasis =>
      'Measured, but too old to read as current.';

  @override
  String get vehCompareQualMixedProvenance =>
      'Measured and modelled evidence both exist; they are reported apart.';

  @override
  String get vehCompareQualConvertedCurrency =>
      'Converted at a named, dated rate — a valuation, not the amount paid.';

  @override
  String get vehCompareQualExcludedRecords =>
      'Some records were left out of this total.';

  @override
  String get vehCompareQualOpenWindowExcluded =>
      'The tank in progress is not counted.';

  @override
  String get vehCompareQualUnknownBlendShare =>
      'Part of the tank cannot be attributed to one grade.';

  @override
  String get vehCompareQualReconstructedValuation =>
      'A reconstructed valuation of the fuel burned, not money paid.';

  @override
  String get vehicleMultiFuelCapableLabel =>
      'Posso abastecer com tipos de combustível diferentes';

  @override
  String get vehicleMultiFuelCapableHelper =>
      'Acompanha qual o combustível mais barato por quilómetro';

  @override
  String get vinLabel => 'VIN (opcional)';

  @override
  String get vinDecodeTooltip => 'Descodificar VIN';

  @override
  String get vinConfirmAction => 'Sim, preencher automaticamente';

  @override
  String get vinModifyAction => 'Modificar manualmente';

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
  String get vehTripTitle => 'Compare this trip';

  @override
  String get vehTripOpenTooltip => 'Compare this trip across vehicles';

  @override
  String get vehTripNoRoute =>
      'Plan a route first — there is no journey to compare yet.';

  @override
  String get vehTripNotEnoughVehicles =>
      'Pick at least two vehicles to compare this trip.';

  @override
  String get vehTripForecastNote =>
      'These are estimates for a journey you have not driven yet, built from each vehicle\'s own consumption evidence, tank and compatible fuel. They are a forecast, not the history you recorded.';

  @override
  String get vehTripScopeNote =>
      'Fuel and refuelling only. Maintenance, depreciation and insurance are in no total on this screen.';

  @override
  String get vehTripObjectiveLabel => 'Compare on';

  @override
  String get vehTripObjectiveCost => 'Lowest total cost';

  @override
  String get vehTripObjectiveTime => 'Shortest expected time';

  @override
  String get vehTripObjectiveDistance => 'Least extra driving';

  @override
  String get vehTripFuelUsedLabel => 'Fuel this trip burns';

  @override
  String get vehTripCostToDriveLabel => 'Fuel cost to drive';

  @override
  String get vehTripCostToDriveNote =>
      'The fuel the journey burns, valued at the best price for this vehicle\'s fuel on this route. It does not change with what is already in the tank.';

  @override
  String get vehTripCashRequiredLabel => 'Cash at the pump';

  @override
  String get vehTripCashRequiredNote =>
      'What you would pay on this trip with the tank as it is now, known stop charges included. A full tank is cheaper to refuel, not cheaper to drive.';

  @override
  String get vehTripStopsLabel => 'Refuelling stops';

  @override
  String get vehTripExtraKmLabel => 'Extra kilometres';

  @override
  String get vehTripTimeLabel => 'Expected time';

  @override
  String get vehTripStartTankLabel => 'Tank at departure';

  @override
  String get vehTripEndTankLabel => 'Tank at arrival';

  @override
  String get vehTripConsumptionLabel => 'Consumption assumed';

  @override
  String get vehTripNoStops => 'No refuelling stop needed.';

  @override
  String vehTripStopLine(String station, String litres, String cost) {
    return '$station: buy $litres for $cost';
  }

  @override
  String get vehTripSourceMeasured => 'from your records';

  @override
  String get vehTripSourceManual => 'your own assumption';

  @override
  String get vehTripSourceEstimated => 'estimated';

  @override
  String get vehTripSourceUnknown => 'not known';

  @override
  String vehTripGap(String fromKm, String toKm) {
    return 'This vehicle cannot cross from $fromKm to $toKm on one tank.';
  }

  @override
  String vehTripWinnerCost(String vehicle) {
    return '$vehicle costs the least to drive';
  }

  @override
  String vehTripWinnerCash(String vehicle) {
    return '$vehicle needs the least cash at the pump';
  }

  @override
  String vehTripWinnerTime(String vehicle) {
    return '$vehicle is expected to arrive first';
  }

  @override
  String get vehTripWinnerWithheld =>
      'No single winner: not every selected vehicle could be compared on this figure.';

  @override
  String get vehTripApply => 'Use this plan';

  @override
  String vehTripApplied(String vehicle) {
    return 'Navigation started for $vehicle.';
  }

  @override
  String get vehTripApplyRefused =>
      'This plan could not be handed to navigation.';

  @override
  String get vehTripBoundedSearch =>
      'The best of the stations searched, not proof that nothing better exists.';

  @override
  String get vehTripCurrencyWithheld =>
      'Some stations on this route quote a currency this trip cannot be expressed in. Their prices stay as quoted.';

  @override
  String get vehTripIncompleteEvidence =>
      'Some stations were left out of this vehicle\'s plan, so it speaks only for the ones searched.';

  @override
  String get vehTripAssumptionLabel => 'Consumption for this trip';

  @override
  String get vehTripAssumptionClear => 'Use my records again';

  @override
  String vehTripSemanticsColumn(String vehicle, int index, int total) {
    return '$vehicle, vehicle $index of $total';
  }

  @override
  String get vehTripNoPriceForFuel =>
      'No station on this route sells this vehicle\'s fuel, so there is no fuel cost to show.';

  @override
  String get vehTripUnavailableShort => 'Not comparable';

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
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Detetado a partir do VIN: $summary. Aplicar?';
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
    return '$name, a $distanceKm quilómetros, $fuelType $euros euros $cents';
  }

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
  String get widgetDefaultsThisProfileHint =>
      'As escolhas abaixo aplicam-se a todos os widgets instalados que mostrem este perfil, na próxima atualização.';

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
}
