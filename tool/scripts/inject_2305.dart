// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// One-shot helper for issue #2305: inject the new audit-2 semantic keys
// into every non-en/de/en_XA locale ARB with real localized phrasing.
// en + de come from fragments; en_XA from the pseudo generator. Delete
// after the keys land — kept tiny and deterministic.

import 'dart:convert';
import 'dart:io';

const _l10nDir = 'lib/l10n';

// Per-locale translations for the 20 new keys. `{...}` placeholders and
// the ICU `select` skeleton are preserved verbatim across all locales.
const Map<String, Map<String, String>> _translations = {
  'fr': {
    'semanticsNavigateTo': 'Naviguer vers {name}',
    'semanticsRemoveFromFavorites': 'Retirer {name} des favoris',
    'showOnMapSemanticLabel': 'Afficher les stations sur la carte',
    'searchResultsSemanticLabel': 'Résultats de recherche',
    'searchCriteriaSemanticLabel':
        'Résumé des critères de recherche. Appuyez pour modifier.',
    'noFavoritesSemanticLabel':
        'Aucun favori pour l\'instant. Appuyez sur l\'étoile d\'une station pour l\'enregistrer en favori.',
    'stationStatusSemantic':
        '{open, select, true{La station est ouverte} false{La station est fermée} other{La station est fermée}}',
    'countryChipSemantic':
        '{selected, select, true{Pays {name}, sélectionné} false{Pays {name}} other{Pays {name}}}',
    'sortBySemantic':
        '{selected, select, true{Trier par {option}, sélectionné} false{Trier par {option}} other{Trier par {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Carburant {type}, sélectionné} false{Carburant {type}} other{Carburant {type}}}',
    'evChargingStationSemantic': 'Borne de recharge {name}, {power} kW',
    'shieldIllustrationSemantic': 'Bouclier de confidentialité avec goutte de carburant',
    'globeIllustrationSemantic': 'Globe avec marqueurs de stations-service',
    'fuelPumpIllustrationSemantic': 'Pompe à carburant avec ticker de prix',
    'countryInfoSemantic':
        '{name}, source de données : {provider}, {keyRequirement}, types de carburant : {fuelTypes}',
    'countryInfoApiKeyRequired': 'Clé API requise',
    'countryInfoNoKeyNeeded': 'Gratuit, aucune clé nécessaire',
    'countryInfoDataSource': 'Données : {provider}',
    'countryInfoFuelTypes': 'Types de carburant : {fuelTypes}',
    'countryInfoDemoSource': 'Démo',
  },
  'es': {
    'semanticsNavigateTo': 'Navegar a {name}',
    'semanticsRemoveFromFavorites': 'Eliminar {name} de favoritos',
    'showOnMapSemanticLabel': 'Mostrar estaciones en el mapa',
    'searchResultsSemanticLabel': 'Resultados de búsqueda',
    'searchCriteriaSemanticLabel':
        'Resumen de los criterios de búsqueda. Toca para editar.',
    'noFavoritesSemanticLabel':
        'Aún no hay favoritos. Toca la estrella de una estación para guardarla como favorita.',
    'stationStatusSemantic':
        '{open, select, true{La estación está abierta} false{La estación está cerrada} other{La estación está cerrada}}',
    'countryChipSemantic':
        '{selected, select, true{País {name}, seleccionado} false{País {name}} other{País {name}}}',
    'sortBySemantic':
        '{selected, select, true{Ordenar por {option}, seleccionado} false{Ordenar por {option}} other{Ordenar por {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Combustible {type}, seleccionado} false{Combustible {type}} other{Combustible {type}}}',
    'evChargingStationSemantic': 'Estación de carga {name}, {power} kW',
    'shieldIllustrationSemantic': 'Escudo de privacidad con gota de combustible',
    'globeIllustrationSemantic': 'Globo con marcadores de estaciones de servicio',
    'fuelPumpIllustrationSemantic': 'Surtidor con indicador de precios',
    'countryInfoSemantic':
        '{name}, fuente de datos: {provider}, {keyRequirement}, tipos de combustible: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Se requiere clave API',
    'countryInfoNoKeyNeeded': 'Gratis, sin clave',
    'countryInfoDataSource': 'Datos: {provider}',
    'countryInfoFuelTypes': 'Tipos de combustible: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'it': {
    'semanticsNavigateTo': 'Naviga verso {name}',
    'semanticsRemoveFromFavorites': 'Rimuovi {name} dai preferiti',
    'showOnMapSemanticLabel': 'Mostra le stazioni sulla mappa',
    'searchResultsSemanticLabel': 'Risultati della ricerca',
    'searchCriteriaSemanticLabel':
        'Riepilogo dei criteri di ricerca. Tocca per modificare.',
    'noFavoritesSemanticLabel':
        'Ancora nessun preferito. Tocca la stella di una stazione per salvarla tra i preferiti.',
    'stationStatusSemantic':
        '{open, select, true{La stazione è aperta} false{La stazione è chiusa} other{La stazione è chiusa}}',
    'countryChipSemantic':
        '{selected, select, true{Paese {name}, selezionato} false{Paese {name}} other{Paese {name}}}',
    'sortBySemantic':
        '{selected, select, true{Ordina per {option}, selezionato} false{Ordina per {option}} other{Ordina per {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Carburante {type}, selezionato} false{Carburante {type}} other{Carburante {type}}}',
    'evChargingStationSemantic': 'Stazione di ricarica {name}, {power} kW',
    'shieldIllustrationSemantic': 'Scudo per la privacy con goccia di carburante',
    'globeIllustrationSemantic': 'Globo con indicatori delle stazioni di servizio',
    'fuelPumpIllustrationSemantic': 'Pompa di carburante con ticker dei prezzi',
    'countryInfoSemantic':
        '{name}, fonte dati: {provider}, {keyRequirement}, tipi di carburante: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Chiave API richiesta',
    'countryInfoNoKeyNeeded': 'Gratis, nessuna chiave necessaria',
    'countryInfoDataSource': 'Dati: {provider}',
    'countryInfoFuelTypes': 'Tipi di carburante: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'nl': {
    'semanticsNavigateTo': 'Navigeer naar {name}',
    'semanticsRemoveFromFavorites': '{name} uit favorieten verwijderen',
    'showOnMapSemanticLabel': 'Toon stations op de kaart',
    'searchResultsSemanticLabel': 'Zoekresultaten',
    'searchCriteriaSemanticLabel':
        'Samenvatting van zoekcriteria. Tik om te bewerken.',
    'noFavoritesSemanticLabel':
        'Nog geen favorieten. Tik op de ster van een station om het als favoriet op te slaan.',
    'stationStatusSemantic':
        '{open, select, true{Station is open} false{Station is gesloten} other{Station is gesloten}}',
    'countryChipSemantic':
        '{selected, select, true{Land {name}, geselecteerd} false{Land {name}} other{Land {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sorteren op {option}, geselecteerd} false{Sorteren op {option}} other{Sorteren op {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Brandstof {type}, geselecteerd} false{Brandstof {type}} other{Brandstof {type}}}',
    'evChargingStationSemantic': 'Laadstation {name}, {power} kW',
    'shieldIllustrationSemantic': 'Privacyschild met brandstofdruppel',
    'globeIllustrationSemantic': 'Wereldbol met tankstationmarkeringen',
    'fuelPumpIllustrationSemantic': 'Benzinepomp met prijsticker',
    'countryInfoSemantic':
        '{name}, gegevensbron: {provider}, {keyRequirement}, brandstoftypes: {fuelTypes}',
    'countryInfoApiKeyRequired': 'API-sleutel vereist',
    'countryInfoNoKeyNeeded': 'Gratis, geen sleutel nodig',
    'countryInfoDataSource': 'Gegevens: {provider}',
    'countryInfoFuelTypes': 'Brandstoftypes: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'pt': {
    'semanticsNavigateTo': 'Navegar até {name}',
    'semanticsRemoveFromFavorites': 'Remover {name} dos favoritos',
    'showOnMapSemanticLabel': 'Mostrar estações no mapa',
    'searchResultsSemanticLabel': 'Resultados da pesquisa',
    'searchCriteriaSemanticLabel':
        'Resumo dos critérios de pesquisa. Toque para editar.',
    'noFavoritesSemanticLabel':
        'Ainda não há favoritos. Toque na estrela de uma estação para guardá-la como favorita.',
    'stationStatusSemantic':
        '{open, select, true{A estação está aberta} false{A estação está fechada} other{A estação está fechada}}',
    'countryChipSemantic':
        '{selected, select, true{País {name}, selecionado} false{País {name}} other{País {name}}}',
    'sortBySemantic':
        '{selected, select, true{Ordenar por {option}, selecionado} false{Ordenar por {option}} other{Ordenar por {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Combustível {type}, selecionado} false{Combustível {type}} other{Combustível {type}}}',
    'evChargingStationSemantic': 'Estação de carregamento {name}, {power} kW',
    'shieldIllustrationSemantic': 'Escudo de privacidade com gota de combustível',
    'globeIllustrationSemantic': 'Globo com marcadores de postos de combustível',
    'fuelPumpIllustrationSemantic': 'Bomba de combustível com indicador de preços',
    'countryInfoSemantic':
        '{name}, fonte de dados: {provider}, {keyRequirement}, tipos de combustível: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Chave API necessária',
    'countryInfoNoKeyNeeded': 'Grátis, sem chave',
    'countryInfoDataSource': 'Dados: {provider}',
    'countryInfoFuelTypes': 'Tipos de combustível: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'pl': {
    'semanticsNavigateTo': 'Nawiguj do {name}',
    'semanticsRemoveFromFavorites': 'Usuń {name} z ulubionych',
    'showOnMapSemanticLabel': 'Pokaż stacje na mapie',
    'searchResultsSemanticLabel': 'Wyniki wyszukiwania',
    'searchCriteriaSemanticLabel':
        'Podsumowanie kryteriów wyszukiwania. Dotknij, aby edytować.',
    'noFavoritesSemanticLabel':
        'Brak ulubionych. Dotknij gwiazdki przy stacji, aby zapisać ją jako ulubioną.',
    'stationStatusSemantic':
        '{open, select, true{Stacja jest otwarta} false{Stacja jest zamknięta} other{Stacja jest zamknięta}}',
    'countryChipSemantic':
        '{selected, select, true{Kraj {name}, wybrano} false{Kraj {name}} other{Kraj {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sortuj według {option}, wybrano} false{Sortuj według {option}} other{Sortuj według {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Paliwo {type}, wybrano} false{Paliwo {type}} other{Paliwo {type}}}',
    'evChargingStationSemantic': 'Stacja ładowania {name}, {power} kW',
    'shieldIllustrationSemantic': 'Tarcza prywatności z kroplą paliwa',
    'globeIllustrationSemantic': 'Globus ze znacznikami stacji paliw',
    'fuelPumpIllustrationSemantic': 'Dystrybutor paliwa ze wskaźnikiem cen',
    'countryInfoSemantic':
        '{name}, źródło danych: {provider}, {keyRequirement}, rodzaje paliwa: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Wymagany klucz API',
    'countryInfoNoKeyNeeded': 'Bezpłatnie, bez klucza',
    'countryInfoDataSource': 'Dane: {provider}',
    'countryInfoFuelTypes': 'Rodzaje paliwa: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'cs': {
    'semanticsNavigateTo': 'Navigovat na {name}',
    'semanticsRemoveFromFavorites': 'Odebrat {name} z oblíbených',
    'showOnMapSemanticLabel': 'Zobrazit stanice na mapě',
    'searchResultsSemanticLabel': 'Výsledky vyhledávání',
    'searchCriteriaSemanticLabel':
        'Souhrn kritérií vyhledávání. Klepnutím upravíte.',
    'noFavoritesSemanticLabel':
        'Zatím žádné oblíbené. Klepnutím na hvězdičku u stanice ji uložíte jako oblíbenou.',
    'stationStatusSemantic':
        '{open, select, true{Stanice je otevřená} false{Stanice je zavřená} other{Stanice je zavřená}}',
    'countryChipSemantic':
        '{selected, select, true{Země {name}, vybráno} false{Země {name}} other{Země {name}}}',
    'sortBySemantic':
        '{selected, select, true{Seřadit podle {option}, vybráno} false{Seřadit podle {option}} other{Seřadit podle {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Palivo {type}, vybráno} false{Palivo {type}} other{Palivo {type}}}',
    'evChargingStationSemantic': 'Nabíjecí stanice {name}, {power} kW',
    'shieldIllustrationSemantic': 'Štít soukromí s kapkou paliva',
    'globeIllustrationSemantic': 'Globus se značkami čerpacích stanic',
    'fuelPumpIllustrationSemantic': 'Čerpací stojan s cenovým tickerem',
    'countryInfoSemantic':
        '{name}, zdroj dat: {provider}, {keyRequirement}, druhy paliva: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Vyžadován klíč API',
    'countryInfoNoKeyNeeded': 'Zdarma, bez klíče',
    'countryInfoDataSource': 'Data: {provider}',
    'countryInfoFuelTypes': 'Druhy paliva: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'sk': {
    'semanticsNavigateTo': 'Navigovať na {name}',
    'semanticsRemoveFromFavorites': 'Odstrániť {name} z obľúbených',
    'showOnMapSemanticLabel': 'Zobraziť stanice na mape',
    'searchResultsSemanticLabel': 'Výsledky vyhľadávania',
    'searchCriteriaSemanticLabel':
        'Súhrn kritérií vyhľadávania. Ťuknutím upravíte.',
    'noFavoritesSemanticLabel':
        'Zatiaľ žiadne obľúbené. Ťuknutím na hviezdičku pri stanici ju uložíte ako obľúbenú.',
    'stationStatusSemantic':
        '{open, select, true{Stanica je otvorená} false{Stanica je zatvorená} other{Stanica je zatvorená}}',
    'countryChipSemantic':
        '{selected, select, true{Krajina {name}, vybraté} false{Krajina {name}} other{Krajina {name}}}',
    'sortBySemantic':
        '{selected, select, true{Zoradiť podľa {option}, vybraté} false{Zoradiť podľa {option}} other{Zoradiť podľa {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Palivo {type}, vybraté} false{Palivo {type}} other{Palivo {type}}}',
    'evChargingStationSemantic': 'Nabíjacia stanica {name}, {power} kW',
    'shieldIllustrationSemantic': 'Štít súkromia s kvapkou paliva',
    'globeIllustrationSemantic': 'Glóbus so značkami čerpacích staníc',
    'fuelPumpIllustrationSemantic': 'Čerpací stojan s cenovým tickerom',
    'countryInfoSemantic':
        '{name}, zdroj údajov: {provider}, {keyRequirement}, druhy paliva: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Vyžaduje sa kľúč API',
    'countryInfoNoKeyNeeded': 'Zadarmo, bez kľúča',
    'countryInfoDataSource': 'Údaje: {provider}',
    'countryInfoFuelTypes': 'Druhy paliva: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'hu': {
    'semanticsNavigateTo': 'Navigálás ide: {name}',
    'semanticsRemoveFromFavorites': '{name} eltávolítása a kedvencekből',
    'showOnMapSemanticLabel': 'Állomások megjelenítése a térképen',
    'searchResultsSemanticLabel': 'Keresési eredmények',
    'searchCriteriaSemanticLabel':
        'Keresési feltételek összegzése. Koppintson a szerkesztéshez.',
    'noFavoritesSemanticLabel':
        'Még nincsenek kedvencek. Koppintson egy állomás csillagára, hogy kedvencként mentse.',
    'stationStatusSemantic':
        '{open, select, true{Az állomás nyitva van} false{Az állomás zárva van} other{Az állomás zárva van}}',
    'countryChipSemantic':
        '{selected, select, true{Ország: {name}, kiválasztva} false{Ország: {name}} other{Ország: {name}}}',
    'sortBySemantic':
        '{selected, select, true{Rendezés: {option}, kiválasztva} false{Rendezés: {option}} other{Rendezés: {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Üzemanyag: {type}, kiválasztva} false{Üzemanyag: {type}} other{Üzemanyag: {type}}}',
    'evChargingStationSemantic': 'Töltőállomás: {name}, {power} kW',
    'shieldIllustrationSemantic': 'Adatvédelmi pajzs üzemanyagcseppel',
    'globeIllustrationSemantic': 'Földgömb töltőállomás-jelölőkkel',
    'fuelPumpIllustrationSemantic': 'Üzemanyagtöltő árkijelzővel',
    'countryInfoSemantic':
        '{name}, adatforrás: {provider}, {keyRequirement}, üzemanyagtípusok: {fuelTypes}',
    'countryInfoApiKeyRequired': 'API-kulcs szükséges',
    'countryInfoNoKeyNeeded': 'Ingyenes, kulcs nélkül',
    'countryInfoDataSource': 'Adatok: {provider}',
    'countryInfoFuelTypes': 'Üzemanyagtípusok: {fuelTypes}',
    'countryInfoDemoSource': 'Demó',
  },
  'ro': {
    'semanticsNavigateTo': 'Navighează către {name}',
    'semanticsRemoveFromFavorites': 'Elimină {name} din favorite',
    'showOnMapSemanticLabel': 'Afișează stațiile pe hartă',
    'searchResultsSemanticLabel': 'Rezultatele căutării',
    'searchCriteriaSemanticLabel':
        'Rezumatul criteriilor de căutare. Atinge pentru a edita.',
    'noFavoritesSemanticLabel':
        'Încă nu există favorite. Atinge steaua unei stații pentru a o salva ca favorită.',
    'stationStatusSemantic':
        '{open, select, true{Stația este deschisă} false{Stația este închisă} other{Stația este închisă}}',
    'countryChipSemantic':
        '{selected, select, true{Țară {name}, selectat} false{Țară {name}} other{Țară {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sortează după {option}, selectat} false{Sortează după {option}} other{Sortează după {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Carburant {type}, selectat} false{Carburant {type}} other{Carburant {type}}}',
    'evChargingStationSemantic': 'Stație de încărcare {name}, {power} kW',
    'shieldIllustrationSemantic': 'Scut de confidențialitate cu picătură de carburant',
    'globeIllustrationSemantic': 'Glob cu marcaje pentru benzinării',
    'fuelPumpIllustrationSemantic': 'Pompă de carburant cu indicator de prețuri',
    'countryInfoSemantic':
        '{name}, sursă de date: {provider}, {keyRequirement}, tipuri de carburant: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Cheie API necesară',
    'countryInfoNoKeyNeeded': 'Gratuit, fără cheie',
    'countryInfoDataSource': 'Date: {provider}',
    'countryInfoFuelTypes': 'Tipuri de carburant: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'bg': {
    'semanticsNavigateTo': 'Навигация до {name}',
    'semanticsRemoveFromFavorites': 'Премахни {name} от любими',
    'showOnMapSemanticLabel': 'Показване на станциите на картата',
    'searchResultsSemanticLabel': 'Резултати от търсенето',
    'searchCriteriaSemanticLabel':
        'Обобщение на критериите за търсене. Докоснете за редактиране.',
    'noFavoritesSemanticLabel':
        'Все още няма любими. Докоснете звездата на станция, за да я запазите като любима.',
    'stationStatusSemantic':
        '{open, select, true{Станцията е отворена} false{Станцията е затворена} other{Станцията е затворена}}',
    'countryChipSemantic':
        '{selected, select, true{Държава {name}, избрана} false{Държава {name}} other{Държава {name}}}',
    'sortBySemantic':
        '{selected, select, true{Сортиране по {option}, избрано} false{Сортиране по {option}} other{Сортиране по {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Гориво {type}, избрано} false{Гориво {type}} other{Гориво {type}}}',
    'evChargingStationSemantic': 'Зарядна станция {name}, {power} kW',
    'shieldIllustrationSemantic': 'Щит за поверителност с капка гориво',
    'globeIllustrationSemantic': 'Глобус с маркери за бензиностанции',
    'fuelPumpIllustrationSemantic': 'Колонка за гориво с ценови индикатор',
    'countryInfoSemantic':
        '{name}, източник на данни: {provider}, {keyRequirement}, видове гориво: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Изисква се API ключ',
    'countryInfoNoKeyNeeded': 'Безплатно, без ключ',
    'countryInfoDataSource': 'Данни: {provider}',
    'countryInfoFuelTypes': 'Видове гориво: {fuelTypes}',
    'countryInfoDemoSource': 'Демо',
  },
  'el': {
    'semanticsNavigateTo': 'Πλοήγηση προς {name}',
    'semanticsRemoveFromFavorites': 'Κατάργηση {name} από τα αγαπημένα',
    'showOnMapSemanticLabel': 'Εμφάνιση σταθμών στον χάρτη',
    'searchResultsSemanticLabel': 'Αποτελέσματα αναζήτησης',
    'searchCriteriaSemanticLabel':
        'Σύνοψη κριτηρίων αναζήτησης. Πατήστε για επεξεργασία.',
    'noFavoritesSemanticLabel':
        'Δεν υπάρχουν ακόμη αγαπημένα. Πατήστε το αστέρι ενός σταθμού για να τον αποθηκεύσετε στα αγαπημένα.',
    'stationStatusSemantic':
        '{open, select, true{Ο σταθμός είναι ανοιχτός} false{Ο σταθμός είναι κλειστός} other{Ο σταθμός είναι κλειστός}}',
    'countryChipSemantic':
        '{selected, select, true{Χώρα {name}, επιλεγμένη} false{Χώρα {name}} other{Χώρα {name}}}',
    'sortBySemantic':
        '{selected, select, true{Ταξινόμηση κατά {option}, επιλεγμένο} false{Ταξινόμηση κατά {option}} other{Ταξινόμηση κατά {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Καύσιμο {type}, επιλεγμένο} false{Καύσιμο {type}} other{Καύσιμο {type}}}',
    'evChargingStationSemantic': 'Σταθμός φόρτισης {name}, {power} kW',
    'shieldIllustrationSemantic': 'Ασπίδα απορρήτου με σταγόνα καυσίμου',
    'globeIllustrationSemantic': 'Υδρόγειος με δείκτες πρατηρίων καυσίμων',
    'fuelPumpIllustrationSemantic': 'Αντλία καυσίμου με δείκτη τιμών',
    'countryInfoSemantic':
        '{name}, πηγή δεδομένων: {provider}, {keyRequirement}, τύποι καυσίμου: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Απαιτείται κλειδί API',
    'countryInfoNoKeyNeeded': 'Δωρεάν, χωρίς κλειδί',
    'countryInfoDataSource': 'Δεδομένα: {provider}',
    'countryInfoFuelTypes': 'Τύποι καυσίμου: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'sv': {
    'semanticsNavigateTo': 'Navigera till {name}',
    'semanticsRemoveFromFavorites': 'Ta bort {name} från favoriter',
    'showOnMapSemanticLabel': 'Visa stationer på kartan',
    'searchResultsSemanticLabel': 'Sökresultat',
    'searchCriteriaSemanticLabel':
        'Sammanfattning av sökkriterier. Tryck för att redigera.',
    'noFavoritesSemanticLabel':
        'Inga favoriter ännu. Tryck på stjärnan vid en station för att spara den som favorit.',
    'stationStatusSemantic':
        '{open, select, true{Stationen är öppen} false{Stationen är stängd} other{Stationen är stängd}}',
    'countryChipSemantic':
        '{selected, select, true{Land {name}, vald} false{Land {name}} other{Land {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sortera efter {option}, vald} false{Sortera efter {option}} other{Sortera efter {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Bränsle {type}, vald} false{Bränsle {type}} other{Bränsle {type}}}',
    'evChargingStationSemantic': 'Laddstation {name}, {power} kW',
    'shieldIllustrationSemantic': 'Integritetssköld med bränsledroppe',
    'globeIllustrationSemantic': 'Jordglob med markörer för bensinstationer',
    'fuelPumpIllustrationSemantic': 'Bränslepump med prisindikator',
    'countryInfoSemantic':
        '{name}, datakälla: {provider}, {keyRequirement}, bränsletyper: {fuelTypes}',
    'countryInfoApiKeyRequired': 'API-nyckel krävs',
    'countryInfoNoKeyNeeded': 'Gratis, ingen nyckel behövs',
    'countryInfoDataSource': 'Data: {provider}',
    'countryInfoFuelTypes': 'Bränsletyper: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'da': {
    'semanticsNavigateTo': 'Naviger til {name}',
    'semanticsRemoveFromFavorites': 'Fjern {name} fra favoritter',
    'showOnMapSemanticLabel': 'Vis stationer på kortet',
    'searchResultsSemanticLabel': 'Søgeresultater',
    'searchCriteriaSemanticLabel':
        'Oversigt over søgekriterier. Tryk for at redigere.',
    'noFavoritesSemanticLabel':
        'Ingen favoritter endnu. Tryk på stjernen ved en station for at gemme den som favorit.',
    'stationStatusSemantic':
        '{open, select, true{Stationen er åben} false{Stationen er lukket} other{Stationen er lukket}}',
    'countryChipSemantic':
        '{selected, select, true{Land {name}, valgt} false{Land {name}} other{Land {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sortér efter {option}, valgt} false{Sortér efter {option}} other{Sortér efter {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Brændstof {type}, valgt} false{Brændstof {type}} other{Brændstof {type}}}',
    'evChargingStationSemantic': 'Ladestation {name}, {power} kW',
    'shieldIllustrationSemantic': 'Privatlivsskjold med brændstofdråbe',
    'globeIllustrationSemantic': 'Globus med markører for tankstationer',
    'fuelPumpIllustrationSemantic': 'Brændstofstander med prisindikator',
    'countryInfoSemantic':
        '{name}, datakilde: {provider}, {keyRequirement}, brændstoftyper: {fuelTypes}',
    'countryInfoApiKeyRequired': 'API-nøgle påkrævet',
    'countryInfoNoKeyNeeded': 'Gratis, ingen nøgle nødvendig',
    'countryInfoDataSource': 'Data: {provider}',
    'countryInfoFuelTypes': 'Brændstoftyper: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'nb': {
    'semanticsNavigateTo': 'Naviger til {name}',
    'semanticsRemoveFromFavorites': 'Fjern {name} fra favoritter',
    'showOnMapSemanticLabel': 'Vis stasjoner på kartet',
    'searchResultsSemanticLabel': 'Søkeresultater',
    'searchCriteriaSemanticLabel':
        'Sammendrag av søkekriterier. Trykk for å redigere.',
    'noFavoritesSemanticLabel':
        'Ingen favoritter ennå. Trykk på stjernen ved en stasjon for å lagre den som favoritt.',
    'stationStatusSemantic':
        '{open, select, true{Stasjonen er åpen} false{Stasjonen er stengt} other{Stasjonen er stengt}}',
    'countryChipSemantic':
        '{selected, select, true{Land {name}, valgt} false{Land {name}} other{Land {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sorter etter {option}, valgt} false{Sorter etter {option}} other{Sorter etter {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Drivstoff {type}, valgt} false{Drivstoff {type}} other{Drivstoff {type}}}',
    'evChargingStationSemantic': 'Ladestasjon {name}, {power} kW',
    'shieldIllustrationSemantic': 'Personvernskjold med drivstoffdråpe',
    'globeIllustrationSemantic': 'Globus med markører for bensinstasjoner',
    'fuelPumpIllustrationSemantic': 'Drivstoffpumpe med prisindikator',
    'countryInfoSemantic':
        '{name}, datakilde: {provider}, {keyRequirement}, drivstofftyper: {fuelTypes}',
    'countryInfoApiKeyRequired': 'API-nøkkel kreves',
    'countryInfoNoKeyNeeded': 'Gratis, ingen nøkkel nødvendig',
    'countryInfoDataSource': 'Data: {provider}',
    'countryInfoFuelTypes': 'Drivstofftyper: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'fi': {
    'semanticsNavigateTo': 'Navigoi kohteeseen {name}',
    'semanticsRemoveFromFavorites': 'Poista {name} suosikeista',
    'showOnMapSemanticLabel': 'Näytä asemat kartalla',
    'searchResultsSemanticLabel': 'Hakutulokset',
    'searchCriteriaSemanticLabel':
        'Hakuehtojen yhteenveto. Muokkaa napauttamalla.',
    'noFavoritesSemanticLabel':
        'Ei vielä suosikkeja. Napauta aseman tähteä tallentaaksesi sen suosikiksi.',
    'stationStatusSemantic':
        '{open, select, true{Asema on auki} false{Asema on suljettu} other{Asema on suljettu}}',
    'countryChipSemantic':
        '{selected, select, true{Maa {name}, valittu} false{Maa {name}} other{Maa {name}}}',
    'sortBySemantic':
        '{selected, select, true{Lajittele: {option}, valittu} false{Lajittele: {option}} other{Lajittele: {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Polttoaine {type}, valittu} false{Polttoaine {type}} other{Polttoaine {type}}}',
    'evChargingStationSemantic': 'Latausasema {name}, {power} kW',
    'shieldIllustrationSemantic': 'Tietosuojakilpi polttoainepisaralla',
    'globeIllustrationSemantic': 'Maapallo huoltoasemamerkinnöillä',
    'fuelPumpIllustrationSemantic': 'Polttoainepumppu hintanäytöllä',
    'countryInfoSemantic':
        '{name}, tietolähde: {provider}, {keyRequirement}, polttoainetyypit: {fuelTypes}',
    'countryInfoApiKeyRequired': 'API-avain vaaditaan',
    'countryInfoNoKeyNeeded': 'Ilmainen, ei avainta',
    'countryInfoDataSource': 'Tiedot: {provider}',
    'countryInfoFuelTypes': 'Polttoainetyypit: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'et': {
    'semanticsNavigateTo': 'Navigeeri sihtkohta {name}',
    'semanticsRemoveFromFavorites': 'Eemalda {name} lemmikutest',
    'showOnMapSemanticLabel': 'Näita jaamu kaardil',
    'searchResultsSemanticLabel': 'Otsingutulemused',
    'searchCriteriaSemanticLabel':
        'Otsingukriteeriumide kokkuvõte. Puudutage muutmiseks.',
    'noFavoritesSemanticLabel':
        'Lemmikuid pole veel. Puudutage jaama tärni, et salvestada see lemmikuks.',
    'stationStatusSemantic':
        '{open, select, true{Jaam on avatud} false{Jaam on suletud} other{Jaam on suletud}}',
    'countryChipSemantic':
        '{selected, select, true{Riik {name}, valitud} false{Riik {name}} other{Riik {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sortimine: {option}, valitud} false{Sortimine: {option}} other{Sortimine: {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Kütus {type}, valitud} false{Kütus {type}} other{Kütus {type}}}',
    'evChargingStationSemantic': 'Laadimisjaam {name}, {power} kW',
    'shieldIllustrationSemantic': 'Privaatsuskilp kütusepiisaga',
    'globeIllustrationSemantic': 'Maakera tanklatähistega',
    'fuelPumpIllustrationSemantic': 'Kütusepump hinnanäidikuga',
    'countryInfoSemantic':
        '{name}, andmeallikas: {provider}, {keyRequirement}, kütuseliigid: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Vajalik on API võti',
    'countryInfoNoKeyNeeded': 'Tasuta, võtit pole vaja',
    'countryInfoDataSource': 'Andmed: {provider}',
    'countryInfoFuelTypes': 'Kütuseliigid: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'lv': {
    'semanticsNavigateTo': 'Navigēt uz {name}',
    'semanticsRemoveFromFavorites': 'Noņemt {name} no izlases',
    'showOnMapSemanticLabel': 'Rādīt stacijas kartē',
    'searchResultsSemanticLabel': 'Meklēšanas rezultāti',
    'searchCriteriaSemanticLabel':
        'Meklēšanas kritēriju kopsavilkums. Pieskarieties, lai rediģētu.',
    'noFavoritesSemanticLabel':
        'Vēl nav izlases. Pieskarieties stacijas zvaigznītei, lai saglabātu to izlasē.',
    'stationStatusSemantic':
        '{open, select, true{Stacija ir atvērta} false{Stacija ir slēgta} other{Stacija ir slēgta}}',
    'countryChipSemantic':
        '{selected, select, true{Valsts {name}, atlasīta} false{Valsts {name}} other{Valsts {name}}}',
    'sortBySemantic':
        '{selected, select, true{Kārtot pēc {option}, atlasīts} false{Kārtot pēc {option}} other{Kārtot pēc {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Degviela {type}, atlasīta} false{Degviela {type}} other{Degviela {type}}}',
    'evChargingStationSemantic': 'Uzlādes stacija {name}, {power} kW',
    'shieldIllustrationSemantic': 'Konfidencialitātes vairogs ar degvielas pilienu',
    'globeIllustrationSemantic': 'Globuss ar degvielas uzpildes staciju marķieriem',
    'fuelPumpIllustrationSemantic': 'Degvielas sūknis ar cenu rādītāju',
    'countryInfoSemantic':
        '{name}, datu avots: {provider}, {keyRequirement}, degvielas veidi: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Nepieciešama API atslēga',
    'countryInfoNoKeyNeeded': 'Bez maksas, atslēga nav vajadzīga',
    'countryInfoDataSource': 'Dati: {provider}',
    'countryInfoFuelTypes': 'Degvielas veidi: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'lt': {
    'semanticsNavigateTo': 'Nuvykti į {name}',
    'semanticsRemoveFromFavorites': 'Pašalinti {name} iš parankinių',
    'showOnMapSemanticLabel': 'Rodyti stoteles žemėlapyje',
    'searchResultsSemanticLabel': 'Paieškos rezultatai',
    'searchCriteriaSemanticLabel':
        'Paieškos kriterijų santrauka. Bakstelėkite norėdami redaguoti.',
    'noFavoritesSemanticLabel':
        'Parankinių dar nėra. Bakstelėkite stotelės žvaigždutę, kad išsaugotumėte ją kaip parankinę.',
    'stationStatusSemantic':
        '{open, select, true{Stotelė atidaryta} false{Stotelė uždaryta} other{Stotelė uždaryta}}',
    'countryChipSemantic':
        '{selected, select, true{Šalis {name}, pasirinkta} false{Šalis {name}} other{Šalis {name}}}',
    'sortBySemantic':
        '{selected, select, true{Rūšiuoti pagal {option}, pasirinkta} false{Rūšiuoti pagal {option}} other{Rūšiuoti pagal {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Kuras {type}, pasirinktas} false{Kuras {type}} other{Kuras {type}}}',
    'evChargingStationSemantic': 'Įkrovimo stotelė {name}, {power} kW',
    'shieldIllustrationSemantic': 'Privatumo skydas su kuro lašu',
    'globeIllustrationSemantic': 'Gaublys su degalinių žymekliais',
    'fuelPumpIllustrationSemantic': 'Degalų kolonėlė su kainų rodikliu',
    'countryInfoSemantic':
        '{name}, duomenų šaltinis: {provider}, {keyRequirement}, kuro tipai: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Reikalingas API raktas',
    'countryInfoNoKeyNeeded': 'Nemokama, rakto nereikia',
    'countryInfoDataSource': 'Duomenys: {provider}',
    'countryInfoFuelTypes': 'Kuro tipai: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'sl': {
    'semanticsNavigateTo': 'Navigiraj do {name}',
    'semanticsRemoveFromFavorites': 'Odstrani {name} iz priljubljenih',
    'showOnMapSemanticLabel': 'Prikaži postaje na zemljevidu',
    'searchResultsSemanticLabel': 'Rezultati iskanja',
    'searchCriteriaSemanticLabel':
        'Povzetek meril iskanja. Tapnite za urejanje.',
    'noFavoritesSemanticLabel':
        'Še ni priljubljenih. Tapnite zvezdico postaje, da jo shranite med priljubljene.',
    'stationStatusSemantic':
        '{open, select, true{Postaja je odprta} false{Postaja je zaprta} other{Postaja je zaprta}}',
    'countryChipSemantic':
        '{selected, select, true{Država {name}, izbrano} false{Država {name}} other{Država {name}}}',
    'sortBySemantic':
        '{selected, select, true{Razvrsti po {option}, izbrano} false{Razvrsti po {option}} other{Razvrsti po {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Gorivo {type}, izbrano} false{Gorivo {type}} other{Gorivo {type}}}',
    'evChargingStationSemantic': 'Polnilna postaja {name}, {power} kW',
    'shieldIllustrationSemantic': 'Ščit zasebnosti s kapljico goriva',
    'globeIllustrationSemantic': 'Globus z oznakami bencinskih črpalk',
    'fuelPumpIllustrationSemantic': 'Točilna naprava s cenovnim prikazom',
    'countryInfoSemantic':
        '{name}, vir podatkov: {provider}, {keyRequirement}, vrste goriva: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Zahtevan je ključ API',
    'countryInfoNoKeyNeeded': 'Brezplačno, ključ ni potreben',
    'countryInfoDataSource': 'Podatki: {provider}',
    'countryInfoFuelTypes': 'Vrste goriva: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
  'hr': {
    'semanticsNavigateTo': 'Navigiraj do {name}',
    'semanticsRemoveFromFavorites': 'Ukloni {name} iz favorita',
    'showOnMapSemanticLabel': 'Prikaži postaje na karti',
    'searchResultsSemanticLabel': 'Rezultati pretraživanja',
    'searchCriteriaSemanticLabel':
        'Sažetak kriterija pretraživanja. Dodirnite za uređivanje.',
    'noFavoritesSemanticLabel':
        'Još nema favorita. Dodirnite zvjezdicu postaje da biste je spremili kao favorit.',
    'stationStatusSemantic':
        '{open, select, true{Postaja je otvorena} false{Postaja je zatvorena} other{Postaja je zatvorena}}',
    'countryChipSemantic':
        '{selected, select, true{Država {name}, odabrano} false{Država {name}} other{Država {name}}}',
    'sortBySemantic':
        '{selected, select, true{Sortiraj po {option}, odabrano} false{Sortiraj po {option}} other{Sortiraj po {option}}}',
    'fuelTypeSemantic':
        '{selected, select, true{Gorivo {type}, odabrano} false{Gorivo {type}} other{Gorivo {type}}}',
    'evChargingStationSemantic': 'Stanica za punjenje {name}, {power} kW',
    'shieldIllustrationSemantic': 'Štit privatnosti s kapljicom goriva',
    'globeIllustrationSemantic': 'Globus s oznakama benzinskih postaja',
    'fuelPumpIllustrationSemantic': 'Crpka za gorivo s prikazom cijena',
    'countryInfoSemantic':
        '{name}, izvor podataka: {provider}, {keyRequirement}, vrste goriva: {fuelTypes}',
    'countryInfoApiKeyRequired': 'Potreban je API ključ',
    'countryInfoNoKeyNeeded': 'Besplatno, ključ nije potreban',
    'countryInfoDataSource': 'Podaci: {provider}',
    'countryInfoFuelTypes': 'Vrste goriva: {fuelTypes}',
    'countryInfoDemoSource': 'Demo',
  },
};

// `languageChipSemantic` per-locale "Language {name}" wording. Added in a
// second pass so the big map above stays untouched.
const Map<String, String> _languageChip = {
  'fr': 'Langue {name}',
  'es': 'Idioma {name}',
  'it': 'Lingua {name}',
  'nl': 'Taal {name}',
  'pt': 'Idioma {name}',
  'pl': 'Język {name}',
  'cs': 'Jazyk {name}',
  'sk': 'Jazyk {name}',
  'hu': 'Nyelv: {name}',
  'ro': 'Limbă {name}',
  'bg': 'Език {name}',
  'el': 'Γλώσσα {name}',
  'sv': 'Språk {name}',
  'da': 'Sprog {name}',
  'nb': 'Språk {name}',
  'fi': 'Kieli {name}',
  'et': 'Keel {name}',
  'lv': 'Valoda {name}',
  'lt': 'Kalba {name}',
  'sl': 'Jezik {name}',
  'hr': 'Jezik {name}',
};

// Per-locale "selected" word, to fill the ICU `select` true-branch suffix.
const Map<String, String> _selectedWord = {
  'fr': 'sélectionné',
  'es': 'seleccionado',
  'it': 'selezionato',
  'nl': 'geselecteerd',
  'pt': 'selecionado',
  'pl': 'wybrano',
  'cs': 'vybráno',
  'sk': 'vybraté',
  'hu': 'kiválasztva',
  'ro': 'selectat',
  'bg': 'избрано',
  'el': 'επιλεγμένο',
  'sv': 'vald',
  'da': 'valgt',
  'nb': 'valgt',
  'fi': 'valittu',
  'et': 'valitud',
  'lv': 'atlasīts',
  'lt': 'pasirinkta',
  'sl': 'izbrano',
  'hr': 'odabrano',
};

void main() {
  // Source of truth for the key list + insertion order: the en fragment.
  final enFragment = File('$_l10nDir/_fragments/i18n_audit2_en.arb');
  final enJson =
      jsonDecode(enFragment.readAsStringSync()) as Map<String, dynamic>;
  final keys = enJson.keys
      .where((k) => !k.startsWith('@') && k != 'languageChipSemantic')
      .toList();

  for (final entry in _translations.entries) {
    final locale = entry.key;
    final map = entry.value;
    final file = File('$_l10nDir/app_$locale.arb');
    if (!file.existsSync()) {
      stderr.writeln('ERROR: missing $file');
      exit(1);
    }
    final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        stderr.writeln('ERROR: $locale missing translation for `$key`');
        exit(1);
      }
      arb[key] = value;
    }
    // languageChipSemantic — built from the per-locale noun + selected word.
    final langNoun = _languageChip[locale];
    final sel = _selectedWord[locale];
    if (langNoun == null || sel == null) {
      stderr.writeln('ERROR: $locale missing languageChip/selected word');
      exit(1);
    }
    arb['languageChipSemantic'] =
        '{selected, select, true{$langNoun, $sel} false{$langNoun} other{$langNoun}}';
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(arb)}\n',
    );
    stdout.writeln('  injected ${keys.length + 1} keys into $locale');
  }
  stdout.writeln('Done — ${_translations.length} locales.');
}
