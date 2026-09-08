# Carregamento elétrico

O Sparkilo não é só para térmicos. Os pontos de carregamento vêm do [OpenChargeMap](https://openchargemap.org), o maior registo comunitário aberto do mundo.

---

## Ativar

Dois interruptores independentes, ambos em **Definições → Funcionalidades e modo de utilização → Pesquisa e mapa**:

- **Carregamento EV** — a funcionalidade em si (pesquisa, páginas de detalhe, favoritos).
- **Mostrar os pontos de carregamento** — se os pontos aparecem nos resultados e no mapa.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Interruptores do grupo Pesquisa e mapa incluindo Carregamento EV e Mostrar pontos">

*Pode mostrar postos, pontos de carregamento, ou ambos. Quem conduz só elétrico costuma desligar **Mostrar postos de combustível**.*

Depois crie um veículo em **Definições → Veículos e OBD2 → Os meus veículos → Adicionar**, escolhendo **Elétrico** como motorização. Um veículo elétrico traz capacidade da bateria (kWh), potências máximas de carga AC e DC (kW) e os seus conectores (Tipo 2, CCS, CHAdeMO, Tesla, Schuko, Tipo 1, ficha doméstica). As pesquisas limitam-se então aos pontos que o seu carro pode mesmo usar.

---

## Como funcionam os dados

<img src="guide/data-sources-location.jpg" width="340" alt="Campo de chave Carregamento EV a mostrar a chave partilhada por omissão">

*Definições → Fontes de dados e localização. O campo **Carregamento EV (OpenChargeMap)** já contém uma chave partilhada: o carregamento funciona sem configuração.*

A aplicação consulta em direto a API POI do OpenChargeMap para a área que está a ver, e guarda o resultado em cache para sobreviver offline.

### Porque poderá querer a sua própria chave

A chave integrada é partilhada por todos os utilizadores do Sparkilo e está por isso limitada como um fundo comum. Uma chave pessoal dá-lhe a sua quota e permite ao OpenChargeMap ver uso real dos seus dados. É gratuita:

1. Registe-se em [openchargemap.org](https://openchargemap.org).
2. Abra **My Profile → My Apps**.
3. **Register an Application**, descreva brevemente, e a chave API (um UUID) é emitida de imediato.

Cole-a no campo Carregamento EV. Fica no mesmo cofre de hardware da chave alemã, nunca sai do dispositivo e só é enviada ao OpenChargeMap. Esvazie o campo para voltar à chave partilhada.

### O recurso que parece um erro

Se o OpenChargeMap estiver totalmente inacessível, a aplicação desenha um pequeno **conjunto de dados de demonstração integrado** em vez de um mapa vazio. Se vir o mesmo punhado de pontos genéricos em todas as cidades, é esse recurso a dizer-lhe que o pedido em direto falhou — verifique ligação ou chave, e não confie nesses pinos.

### Contribuir

O OpenChargeMap é mantido pela sua comunidade. Um ponto em falta ou errado corrige-se em [openchargemap.org](https://openchargemap.org), não nesta aplicação — e a correção chega depois a todas as aplicações baseadas em OCM, incluindo esta, no pedido seguinte.

---

## Pesquisar

<img src="screenshots/map-ev-charging.png" width="340" alt="Mapa em modo EV com os chips de filtro por conector">

*O seletor EV da barra do mapa muda os pinos de combustível para carregamento. A cor segue a potência: azul claro em AC, azul escuro em DC.*

Na folha de critérios escolha o tipo **EV** e lance uma pesquisa por raio. Filtros disponíveis: tipos de conector, kW mínimos, e só os pontos atualmente livres onde o operador publica estado em direto.

---

## A página de detalhe de um ponto

- **Conectores** — tipo, quantidade e potência máxima de cada um
- **Tarifa** — por kWh quando o operador a publica (muitos não o fazem)
- **Rede** — Ionity, Fastned, Tesla…
- **Disponibilidade** — em tempo real quando declarada
- **Serviços** — comida, sanitários, lojas (contam mais se ficar parado 30 minutos)
- **Horários** — 24/7 ou conforme o operador
- **Avaliações** — de colaboradores do OpenChargeMap

---

## Favoritos e registo

Os pontos marcam-se como favoritos tal como os postos; na horizontal e em tablet, favoritos e alertas ficam lado a lado. O cartão favorito mostra os **kW por conector**, **quantos estão livres** e os **tipos de conector**.

Os alertas de preço servem de pouco no carregamento, já que a maioria dos operadores aplica tarifas fixas por kWh. As sessões de carregamento registam-se como abastecimentos: **separador Combustível → Adicionar**, com kWh em vez de litros — alimentam as mesmas estatísticas de custo por quilómetro dos abastecimentos térmicos.

---

## Atravessar fronteiras

No carregamento não existe deliberadamente **qualquer filtro por país**. Ao ir da Alemanha para França vê ambas as infraestruturas no mesmo mapa. Os preços dos combustíveis são conjuntos nacionais; o carregamento é um único conjunto mundial, por isso a regra « um perfil por país » não se aplica aqui.

---

**Ver também:** [Encontrar postos](User-pt-Finding-Stations) · [Registo de abastecimentos e consumo](User-pt-Fuel-And-Consumption)
**Seguinte:** [Veículos e OBD2 →](User-pt-Vehicles-And-OBD2)
