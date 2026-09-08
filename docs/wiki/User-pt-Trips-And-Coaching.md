# Viagens e eco-coaching

O separador 🛣️ **Viagens** é um diário de bordo automático mais um treinador de condução. Aparece no modo **Completo**.

---

## O separador Viagens

<img src="guide/trips-tab.jpg" width="340" alt="Separador Viagens: comparação mensal, relatório do depósito e lista de viagens com o botão de gravação">

*Totais do mês, o último relatório do depósito, e depois a lista de viagens. O botão flutuante inicia uma gravação.*

A comparação mensal exige pelo menos três viagens por mês antes de comparar — com menos, a média é ruído, não tendência.

<img src="guide/trips-map.jpg" width="340" alt="Todas as viagens gravadas num mapa, coloridas por viagem">

*O ícone de mapa da barra desenha cada viagem gravada num só mapa — um ano de condução num relance, e uma forma fácil de detetar as rotas que vale a pena otimizar.*

---

## Duas formas de gravar

### Só com o telemóvel

Sem hardware. A aplicação regista rota, distância, duração e velocidade por GPS, e **modela** o consumo a partir da calibração do veículo e da sua condução. Assinalado em todo o lado com `~` e uma nota explícita de « estimativa GPS ».

A precisão começa má e melhora: cada janela de abastecimento fechada volta a ancorar o modelo à bomba, pelo que ao fim de um punhado de depósitos cheios uma viagem só com GPS costuma ficar dentro de alguns pontos percentuais. Até lá é rotulada como preliminar, não maquilhada.

### Com um adaptador OBD2

Dados do motor em vez de dedução: caudal real (medido onde o carro publica o PID 5E), rotação, carga, acelerador. Sem período de aprendizagem para o consumo, e o coaching acede a sinais que o GPS não vê — mudança, rotações, carga do motor. A configuração está em [Veículos e OBD2](User-pt-Vehicles-And-OBD2#o-adaptador-obd2).

> **Gravar nunca exige um adaptador.** Desative *Exigir OBD2 para a gravação de viagens* (Funcionalidades e modo de utilização → Consumo) para gravar só com GPS; o coaching é reduzido, não ausente.

---

## Enquanto conduz

### O número em direto

O número principal é a sua média **dos últimos segundos** — combustível queimado ÷ distância percorrida, a mesma grandeza de um computador de bordo — rotulado *« Últimos 5 s »*. Parado passa a L/h, porque L/100 km não faz sentido a velocidade zero.

Mude a janela em **Definições → Condução e consumo → Janela de consumo em direto** (3 / 5 / 10 / 30 s). Uma **janela longa é mais estável e legível a conduzir**; uma curta reage depressa o bastante para lhe ensinar quanto custa o pé direito. A unidade segue **Unidades e apresentação → Unidade de consumo** em todo o lado: faixa, miniatura sobreposta, Live Activity do iOS e média da viagem.

### A horizontal é a vista « no carro »

Vire o telemóvel na horizontal durante uma gravação e o ecrã torna-se uma disposição sem toques, legível de relance: à esquerda o grande número de consumo instantâneo com a indicação de coaching por baixo (*levante o pé* / *antecipe* / *acelere suave* com GPS, *suba de mudança* / *reduza* / *alivie* com OBD2) e uma grande velocidade; à direita o cartão de radar do posto mais próximo sobre uma grelha 2×2 — **Distância · Média · Duração · Combustível usado**.

Nada desliza e nada é pequeno. Telemóvel no suporte, e não volta a tocar-lhe.

### Imagem na imagem

Reduza a aplicação a uma miniatura flutuante e mantenha a navegação por cima. A miniatura adapta-se ao contexto:

| Situação | Número grande | Linha secundária |
|---|---|---|
| OBD2 ligado | L/100 km em direto (L/h parado) | distância · duração |
| Só GPS, em andamento | distância percorrida | duração |
| A arrancar | tempo decorrido | — |

### O overlay de aproximação

Ao entrar no raio configurado à volta de um posto, a miniatura muda para uma grande apresentação do **preço do combustível** — preço da sua qualidade, marca, distância, legíveis de relance.

Que posto é fixado define-se em **Definições → Condução e consumo → Overlay ao aproximar-se de um posto**: **o mais próximo** (o primeiro cujo raio atravessou) ou **o mais barato do raio**. Ao sair, a apresentação do preço fica cinco segundos de tolerância, para que passar ao lado não faça a miniatura piscar.

**Experimente sem conduzir:** Definições → Ferramentas de programador → **Testar o overlay de aproximação** força um estado sintético durante 30 segundos.

---

## Ler uma viagem

<img src="guide/trip-detail-1.jpg" width="340" alt="Resumo da viagem: data, veículo, adaptador, distância, duração, consumo, combustível, custo e velocidades">

*O resumo declara a sua própria proveniência — veículo, adaptador, e um distintivo **Rasto GPS** na distância para saber de onde vêm os quilómetros.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Mapa da rota colorido por eficiência com a sua legenda e o cartão dos principais comportamentos gastadores">

*A rota está colorida por eficiência — verde abaixo de 6 L/100 km, âmbar até 10, vermelho acima. Onde foi parar o combustível, geograficamente.*

Essa coloração é a vista mais acionável da aplicação: põe num mapa os troços caros do seu trajeto diário. Um troço vermelho que se repete todos os dias é um cruzamento, uma subida ou um hábito que vale a pena mudar.

<img src="guide/trip-detail-3.jpg" width="340" alt="Seletor « como correu a viagem », onde foi o combustível, distribuições de acelerador e rotação">

*Três blocos: o seu veredicto, a atribuição do combustível, e como solicitou realmente o motor.*

- **« Como correu esta viagem? »** — *Suave / Moderado / Agressivo*. A sua resposta serve para calibrar os limiares de estilo de condução com viagens reais, não para lhe dar nota.
- **Onde foi o seu combustível** — litros atribuídos a acelerações fortes face à condução normal. Números absolutos pequenos numa viagem curta; o que conta é a proporção.
- **Posição do acelerador** e **rotação do motor** como distribuições — a parte da viagem em ponto morto, carga leve, firme e a fundo, e em cada faixa de rotação. Uma parte alta acima das 3000 rpm no trajeto para o trabalho significa que engrena tarde demais, e isso custa.

<img src="guide/trip-detail-4.jpg" width="340" alt="Diagnóstico de amostragem GPS e cartão recolhido da saúde da comunicação OBD2">

*Dois diagnósticos: quão completo é o rasto GPS e como se portou o adaptador.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Saúde da comunicação OBD2 expandida: medições, cobertura, adaptador, protocolo, duração, fim de sessão">

*Expandido, o cartão OBD2 explica-se em claro.*

**Leia este cartão antes de duvidar de um número de consumo.** Indica quantas medições traziam dados do motor, a **percentagem de cobertura** resultante, o adaptador e o protocolo negociado, a duração da sessão, porque é que terminou (`userStopped`, uma desligação, uma morte do processo), e a linha decisiva: *« Os valores de consumo vêm do adaptador, não de estimativas GPS. »* Se a cobertura estiver bem abaixo de 100 %, as falhas foram preenchidas com estimativas GPS e a média da viagem é uma mistura.

<img src="guide/trip-detail-5.jpg" width="340" alt="Gráficos: velocidade, caudal de combustível e rotação do motor ao longo da viagem">

*Velocidade, caudal e rotação num eixo de tempo comum — as três curvas que explicam qualquer número de consumo.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Gráficos: rotação, carga do motor, posição do acelerador e temperatura do líquido">

*Carga do motor e acelerador lado a lado mostram a diferença entre fazer o motor trabalhar e limitar-se a fazê-lo subir de rotações.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Gráficos: líquido de refrigeração, altitude desde a partida, temperatura do ar de admissão e avanço da ignição">

*A altitude conta mais do que se pensa: uma subida explica um pico de consumo que de outro modo pareceria má condução.*

As ações **partilhar** e **eliminar** estão na barra superior. Partilhar exporta a viagem com o seu rasto GPX.

---

## Pontuação de condução e coaching

Com adaptador, cada viagem é pontuada em 100 — um composto de ralenti, acelerações fortes, travagens bruscas, tempo em rotação alta, plena carga, motor forçado a baixas rotações, solavancos, velocidade alta sustentada, agressividade no pedal e riqueza da mistura. O detalhe nomeia o comportamento mais caro: a pontuação é um diagnóstico, não um castigo.

O cartão **principais comportamentos gastadores** transforma isso em frases acionáveis — e mostra *« Nenhuma ineficiência notável — continue assim! »* quando não há nada a corrigir, em vez de inventar uma censura.

O coaching também pode acontecer em andamento:

- **Coaching eco em tempo real** — vibração ligeira e conselho no ecrã quando acelera com força em velocidade de cruzeiro.
- **Coaching de voz** — o mesmo conselho lido em voz alta, para manter os olhos na estrada.
- **Glide-coach (beta)** — vibração discreta quando convém levantar o pé antes de um vermelho, a partir dos semáforos do OpenStreetMap. **Desativado por omissão: risco de distração**, e precisa de rede para carregar os semáforos da sua zona.

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Interruptores de coaching, recompensas, cartões de fidelização, conquistas e registo de depuração OBD2">

*Definições → Condução e consumo. Conquistas e pontuações podem ser escondidas em toda a aplicação se a gamificação não for consigo.*

---

## O painel de carbono

<img src="screenshots/carbon-dashboard.png" width="340" alt="Painel de carbono: custo e CO2 por comprimento de viagem e faixa de velocidade">

*Custo e CO₂ a partir dos mesmos litros medidos, decompostos de duas formas.*

- **Por comprimento de viagem** — os trajetos curtos são normalmente os mais caros por quilómetro, porque um motor frio bebe. Vê-lo quantificado é o que leva a agrupar recados.
- **Por faixa de velocidade** — que parte do combustível se gasta a arrastar-se na cidade face a circular na autoestrada.

É construído inteiramente com dados do seu telemóvel, e ativa-se em Funcionalidades e modo de utilização → Consumo.

---

## Exportações e diagnósticos

- **Partilhar** uma viagem (resumo + GPX).
- **Exportar o rasto de análise de condução** — os KPI de GPS, a pontuação e as lições da viagem em JSON, com um campo livre para descrever como correu de facto. Voltar a partilhá-lo ajuda a calibrar os limiares de estilo com viagens reais. Funcionalidade do modo programador.
- **Exportar os meus dados → Arquivo ZIP** em Privacidade e dados → Exportar ou eliminar inclui cada viagem e um GPX por viagem.

---

<details>
<summary>Vista completa — detalhe de uma viagem, página inteira</summary>

<img src="guide/full/trip-detail.jpg" width="420" alt="Página completa do detalhe de viagem montada a partir de oito capturas">

</details>

---

**Ver também:** [Veículos e OBD2](User-pt-Vehicles-And-OBD2) · [Registo de abastecimentos e consumo](User-pt-Fuel-And-Consumption)
**Seguinte:** [Histórico e previsões de preços →](User-pt-Price-History-And-Predictions)
