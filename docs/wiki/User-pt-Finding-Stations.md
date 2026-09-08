# Encontrar postos

Nível 1 dos [três níveis de poupança](User-pt-How-It-Works#os-três-níveis-de-poupança): pagar menos por litro.

---

## Um botão, um modelo mental

A barra inferior tem um único acionador de pesquisa — o botão verde elevado ao centro. É contextual, não modal:

- **A partir de qualquer separador** → abre a folha de critérios.
- **A partir dos resultados ou do mapa** → reabre a folha com os seus últimos valores.
- **Dentro da folha** → executa a pesquisa.

O rótulo diz o que vai fazer, e no modo itinerário fica desativado até haver destino. Deliberadamente não existem botões separados de « pesquisar perto » e « pesquisar no trajeto ».

---

## Definir os critérios

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Critérios: proximidade ou itinerário, morada, chips de combustível, raio, só abertos, serviços, marcas">

*A folha abre preenchida a partir do seu perfil ativo — normalmente só muda uma coisa.*

| Controlo | O que faz | Impacto operacional |
|---|---|---|
| **Por perto / Ao longo do trajeto** | Muda todo o modo de pesquisa | O modo itinerário exige um destino e consulta cada país do corredor |
| **Morada, código postal ou cidade** | Pesquisa num local em vez da sua posição GPS | Nada sobre a sua localização sai do telemóvel; o nome é geocodificado com OpenStreetMap Nominatim e guardado 24 h |
| **Chips de combustível** | A qualidade cujos preços vê | A lista adapta-se ao que o fornecedor do seu país publica de facto |
| **Raio** | Até onde procurar | Um raio grande num país denso devolve muitos postos e torna a pesquisa mais lenta |
| **Só abertos** | Esconde os postos fechados | Depende de o fornecedor publicar horários — alguns não o fazem |
| **Serviços** | Loja, lavagem, ar, WC… | Filtra apenas sobre dados declarados; um posto com campo vazio desaparece |
| **Marcas** | Limitar a certas cadeias | Contadas sobre o conjunto atual de resultados, por isso a lista muda com o raio |
| **Guardar como valores predefinidos** | Escreve estes critérios no perfil | Toda a pesquisa futura parte daqui |

### Como funciona de verdade

Uma pesquisa por perto envia **as suas coordenadas (ou um código de região) e um raio** ao fornecedor oficial do seu país — nunca a sua identidade. Os países que publicam um ficheiro diário (Espanha, Itália) são filtrados no dispositivo: essas pesquisas não precisam de qualquer chamada de rede depois de o ficheiro estar em cache.

---

## Ler um cartão de resultado

<img src="guide/search-results.jpg" width="340" alt="Lista de resultados com preço, seta de tendência, frescura, serviços, distância e estrela">

*Tudo o que é preciso para decidir, sem abrir nada.*

- **Preço** — do combustível procurado, na convenção do seu país (repare no décimo de cêntimo em expoente).
- **Seta de tendência** ▲▼▬ — para onde vai o preço desse posto ultimamente, segundo o *seu próprio* histórico local.
- **★** — toque para marcar favorito; cheia = já guardado.
- **Chips de serviços** — loja, lavagem, ar, multibanco, conforme declarado.
- **Distância** — em linha reta desde a sua posição.
- **« Atualizado 31/08 00:01 »** — o carimbo de frescura. **Leia-o antes do preço.**
- **Linha de ordenação** — Distância / Preço / A–Z / 24 h, mais um chip de aviso quando o preço mais recente da lista tem mais de uma hora.

### A frescura, mais importante do que o preço

| Distintivo | Idade | O que fazer |
|---|---|---|
| Verde | < 5 min | Confiar |
| Amarelo | 5–30 min | Suficiente para decidir |
| Laranja | horas | Plausível; o fornecedor pode publicar devagar |
| Contorno vermelho | > 1 dia | Tratar como indicativo — atualize antes de fazer um desvio |

A frescura é uma propriedade do **fornecedor do país**, não da aplicação. Um preço espanhol de 14 horas não é um erro: aquele país publica uma vez por dia. Ver [Como funciona o Sparkilo → Uma fonte por país](User-pt-How-It-Works#uma-fonte-de-dados-por-país).

### Gestos

- **Deslizar para a direita** — abrir na sua aplicação de navegação (Google Maps, Waze, OsmAnd, Organic Maps).
- **Deslizar para a esquerda** — esconder o posto de todos os resultados futuros. Repõe-se em **Privacidade e dados → Dados neste dispositivo → Postos ignorados**.

---

## Detalhe de um posto

<img src="guide/station-detail-1.jpg" width="340" alt="Detalhe do posto: tabela de preços por combustível, adicionar abastecimento, horários, zona">

*Toque num cartão. O cabeçalho recua de marca para nome e para rua, por isso um Intermarché sem campo de marca continua a mostrar « Intermarché ».*

O bloco de cima é a **tabela completa de preços** — cada qualidade que o fornecedor publica para esse posto, com `--` onde não publica nenhuma. É a forma mais rápida de ver se o posto de E85 barato também aguenta no gasóleo.

**Adicionar abastecimento** preenche posto, combustível e preço no formulário — a maior poupança de tempo da aplicação se registar os seus abastecimentos.

<img src="guide/station-detail-2.jpg" width="340" alt="Continuação do detalhe: zona, serviços, meios de pagamento, a sua avaliação, histórico de preços">

*Mais abaixo: serviços, meios de pagamento aceites, a sua avaliação privada em estrelas, e o histórico local de preços de 30 dias.*

As ações da barra superior são, da esquerda para a direita: **criar um alerta de preço**, **ler um QR de pagamento**, **reportar um preço errado** e **marcar como favorito**.

---

## O mapa

<img src="guide/map-view.jpg" width="340" alt="Mapa com pinos coloridos por preço, círculo de raio e legenda barato/caro">

*A cor é relativa ao que está no ecrã: verde o mais barato visível, vermelho o mais caro. O rodapé indica número de postos, raio e idade dos dados.*

- **Os marcadores de grupo** juntam pinos ao afastar; um toque aproxima.
- **Toque longo** em qualquer ponto para largar o seu marcador e pesquisar a partir dali.
- O **seletor EV** no canto superior direito muda o mapa para pontos de carregamento — ver [Carregamento elétrico](User-pt-EV-Charging).
- **Partilhar** envia a vista atual a alguém.

Os mosaicos vêm do OpenStreetMap. Por omissão passam pelo proxy UE do programador para que o OpenStreetMap nunca veja o seu IP; pode desligar o proxy em Definições → Privacidade e dados e carregar diretamente. A versão F-Droid nunca usa o proxy.

---

## O radar de postos de combustível

Uma varredura em direto à volta da sua posição, pensada para **conduzir**.

<img src="screenshots/radar-start.png" width="340" alt="A pastilha « Iniciar o radar de postos » no ecrã de resultados">

*Depois de qualquer pesquisa por perto surge uma pastilha flutuante em baixo à direita. Um toque inicia o radar.*

### Como funciona de verdade

O radar atualiza a sua posição GPS, obtém as **localizações** dos postos num amplo corredor de 60 km e funde um pedido direto dentro do raio: nunca pode mostrar menos do que uma pesquisa normal. Os postos não se movem, por isso essas localizações ficam em cache até uma hora e são reutilizadas; só o **preço** de um posto de que se está a aproximar é obtido na altura. É isso que torna barato em dados e bateria um radar sempre ligado.

<img src="screenshots/radar-active.png" width="340" alt="Radar em funcionamento: pinos de preço em direto e lista ordenada por distância com barras de proximidade">

*Em funcionamento: resultados por distância, cada um com uma barra que enche à medida que se aproxima.*

### Durante a gravação de uma viagem

O radar fixa um cartão **Posto mais próximo** no topo do ecrã de gravação — nome, preço do seu combustível, distância, e uma barra que chega a 100 % à chegada. Deslize para os lados para percorrer as candidatas. Ao entrar no raio de aproximação configurado, a miniatura sobreposta muda para uma grande apresentação de preço; ver [Viagens e eco-coaching → O overlay de aproximação](User-pt-Trips-And-Coaching#o-overlay-de-aproximação).

### Definições que mudam o seu comportamento

Todas em **Definições → Condução e consumo**: o **raio** a que o overlay aumenta, se mostra o posto **mais próximo** ou o **mais barato do raio**, o **intervalo mínimo de atualização** (um piso, não uma cadência fixa — consulta mais depressa a alta velocidade mas nunca mais apertado) e a **fixação automática**, que mantém o ecrã ligado e esconde as barras do sistema para um suporte de tablier, à custa de bateria.

---

## A calculadora de custo de combustível

Três números à entrada — distância, o seu consumo, o preço — e à saída litros queimados, custo total e custo por quilómetro. Preenche consumo e preço com os seus próprios dados, por isso muitas vezes só escreve a distância.

Responde honestamente a uma única pergunta: *o posto 12 km mais longe é realmente mais barato depois de lá ir?*

---

## Widget do ecrã inicial

- Mostra o seu favorito mais barato (ou o posto mais próximo) e o respetivo preço.
- **Tocar no widget** → abre o detalhe desse posto, estivesse a aplicação viva ou fechada.
- **Tocar no ícone de atualização** → recarrega os preços em segundo plano sem abrir a aplicação.
- Atualização de fundo a cada 30 min em carregamento, de hora a hora caso contrário, respeitando o modo Doze.

Aspeto e variante de conteúdo (*preço atual* ou *preditivo: melhor momento para abastecer*) definem-se por perfil em **Definições → Unidades e apresentação → Widget do ecrã inicial**.

---

## Android Auto

Ligada a uma unidade Android Auto, a aplicação oferece dois ecrãs seguros ao volante: **Pesquisar** (os postos da sua última pesquisa no telemóvel) e **Radar** (os mais baratos no seu percurso). Faça primeiro a pesquisa no telemóvel — o lado do carro é deliberadamente só de leitura, porque não há forma segura de escrever a conduzir. Só Android; não há versão CarPlay.

---

<details>
<summary>Vista completa — detalhe do posto, página inteira</summary>

<img src="guide/full/station-detail.jpg" width="420" alt="Página completa do detalhe do posto montada a partir de duas capturas">

</details>

---

**Ver também:** [Planeamento de itinerário](User-pt-Route-Planning) · [Favoritos e alertas](User-pt-Favorites-And-Alerts) · [Histórico de preços](User-pt-Price-History-And-Predictions)
**Seguinte:** [Planeamento de itinerário →](User-pt-Route-Planning)
