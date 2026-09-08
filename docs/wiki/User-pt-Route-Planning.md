# Planeamento de itinerário

Não « o mais barato perto de mim » mas **o mais barato no caminho** — a diferença vale vários euros em qualquer viagem longa.

---

## Lançar uma pesquisa por itinerário

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Critérios em modo itinerário: partida, paragem, destino, combustível, segmento, desvio, poupança mínima">

*Toque em **Pesquisar** → mude para **Pesquisar ao longo do trajeto**. O botão fica desativado até haver destino e combustível.*

| Campo | Significado |
|---|---|
| **Partida** | A sua posição atual, ou uma cidade / código postal escritos |
| **Adicionar uma paragem** | Pontos intermédios — o corredor segue-os |
| **Destino** | Cidade, código postal ou coordenadas |
| **Combustível** | A qualidade cotada ao longo do corredor |
| **Segmento do trajeto** | Mostrar o posto mais barato a cada *n* km (50–1000 km) |
| **Desvio máximo** | A que distância da linha direta pode estar um posto |
| **Poupança mínima** | Esconde as paragens que não batem a média do corredor pelo menos nesse valor; *Desativado* mostra tudo |

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Parte de baixo dos critérios de itinerário: só abertos, serviços, marcas, guardar predefinições">

*Os mesmos filtros de abertura, serviços e marcas de uma pesquisa por perto aplicam-se ao corredor.*

### Como funciona de verdade

1. A aplicação chama o serviço público de rotas **OSRM** e obtém a polilinha rodoviária do trajeto.
2. Coloca pontos candidatos ao longo dessa linha, espaçados conforme o seu **segmento do trajeto**.
3. À volta de cada ponto consulta o fornecedor de preços **do país onde está esse ponto**, com a qualidade do perfil desse país.
4. Ordena as candidatas de cada segmento conforme a sua estratégia e o limite de **desvio máximo**.

### O que muda na prática

- **O comprimento do segmento é o verdadeiro comando.** 50 km em 600 km dá doze listas; 200 km dá três. Escolha-o conforme a frequência com que realmente para.
- **O desvio máximo mede-se a partir do trajeto direto**, não de si. 5 km significa « até 5 km de estrada extra ».
- **Os trajetos longos demoram mais.** Um corredor de 600 km amostra muitos pontos, talvez em vários fornecedores.
- Se a partida for « GPS automático » e perder sinal, a pesquisa recorre à última posição conhecida.

---

## Corredores transfronteiriços

Quando um trajeto atravessa uma fronteira, **cada país do corredor é consultado com o seu próprio fornecedor**, e o cabeçalho cita-os todos:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Como as qualidades diferem por país, um resultado transfronteiriço mostra legitimamente E85 no troço francês e Gasolina 95/E5 no espanhol. Cada um está cotado corretamente para o seu lado, nunca em média.

**Precisa de um perfil por país** com a qualidade preferida certa, senão o segundo troço não tem nada para cotar e mostra `--`. Ver [Como funciona o Sparkilo → Perfis](User-pt-How-It-Works#perfis-um-contexto-um-conjunto-de-valores-predefinidos).

---

## Os resultados chegam por partes

Uma API nacional lenta não deve bloquear o resto do corredor: os resultados chegam **progressivamente**, aparecendo os postos de cada país assim que esse fornecedor responde, com um aviso a nomear as fontes ainda em falta. Pode tocar num resultado barato assim que ele chega.

---

## As quatro estratégias

### 🏆 Melhores paragens *(por omissão)*
Traz ao topo os 3–5 postos mais baratos realisticamente alcançáveis como chips ordenados. Os desvios ficam curtos. É o que a maioria dos condutores quer.

### 🎯 O mais barato
O único posto com o preço mais baixo de todo o trajeto. Ideal se abastece uma vez e quer a poupança máxima por litro.

### ⚖️ Equilibrada
Pontua cada candidato por preço *e* proximidade à linha. Um posto a 5 km mas 10 cts/L mais barato ganha; um a 50 km tem de ser muito mais barato.

### 📏 Uniforme
Divide o trajeto em segmentos iguais e propõe uma paragem por segmento. Ideal para viagens longas transfronteiriças com vários abastecimentos.

A estratégia por omissão, o comprimento do segmento, o desvio máximo, a poupança mínima e o número de candidatos por ponto de amostragem são guardados **por perfil**:

<img src="guide/profile-edit-2.jpg" width="340" alt="Parâmetros de planeamento de itinerário no editor de perfil">

*Definições → Perfis e região → editar → Planeamento de itinerário. Define-se uma vez aqui em vez de ajustar a folha em cada viagem.*

---

## Ler os resultados

Cada linha acrescenta dois números que uma pesquisa por perto não tem:

- **Distância desde a partida** — onde está o posto no trajeto, para o casar com o momento em que o depósito estará baixo.
- **Desvio** — os quilómetros extra face à linha direta.
- **Poupança face à média** — face à média do corredor, não a uma nacional.

Passe a **Todos os postos** para ver cada posto do trajeto em vez da seleção. O mapa traça a polilinha com todos os pinos.

---

## Evitar autoestradas

**Definições → Perfis e região → Apresentação e postos → Evitar autoestradas** faz o calculador preferir estradas secundárias. Isso muda a *polilinha*, e portanto que postos são candidatos: as áreas de serviço desaparecem do corredor em vez de apenas descerem na ordem. Útil precisamente porque o combustível de autoestrada é normalmente o mais caro de qualquer trajeto.

---

## Itinerários guardados

Toque em **Guardar itinerário** no ecrã de resultados. Os itinerários guardados aparecem no topo do formulário; um toque volta a correr o mesmo corredor com **preços frescos**. Guarda-se a geometria, não os preços.

---

**Ver também:** [Encontrar postos](User-pt-Finding-Stations) · [Referência de definições](User-pt-Settings-Reference#perfis-e-região)
**Seguinte:** [Favoritos e alertas →](User-pt-Favorites-And-Alerts)
