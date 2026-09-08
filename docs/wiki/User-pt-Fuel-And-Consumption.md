# Registo de abastecimentos e consumo

Níveis 2 e 3 dos [três níveis de poupança](User-pt-How-It-Works#os-três-níveis-de-poupança): quanto queima, e quanto custou de facto. O separador ⛽ **Combustível** aparece nos modos **Médio** e **Completo**.

---

## O separador Combustível num relance

<img src="guide/fuel-tab.jpg" width="340" alt="Separador Combustível: nível do depósito com autonomia, cartão de estatísticas com distintivo de precisão, lista de abastecimentos">

*Três blocos: o que está no depósito, quanto custa a sua condução, e o que meteu de facto.*

### Nível do depósito e autonomia

O indicador está **ancorado ao seu último depósito cheio**, e depois debitado do combustível consumido pelas viagens gravadas. O carimbo sob a barra indica a que abastecimento está ancorado.

São mostradas duas autonomias de propósito:

- **« ≈ 548 km ao consumo do seu último depósito »** — o comportamento recente, útil hoje.
- **« Média a longo prazo: ≈ 611 km »** — a sua média histórica, útil para planear.

Se divergirem muito, algo mudou recentemente: uma caixa de tejadilho, o inverno, outra mistura de estradas, ou uma troca de combustível.

> Quando há um adaptador OBD2 ligado e o carro publica o PID de nível de combustível, o indicador passa ao **sensor do depósito** e declara-o. Esse valor é uma medição, não uma dedução, e sobrevive às viagens não gravadas.

### O cartão de estatísticas

Os três distintivos são a camada de honestidade:

| Distintivo | Significado |
|---|---|
| **Precisão: Alta · ±3-7 %** | Abastecimentos e viagens OBD2 alimentam ambos o modelo |
| **Precisão: Média** | Os abastecimentos ancoram-no, mas nenhuma viagem OBD2 alimentou ainda o ciclo |
| **Precisão: Baixa** | Só GPS, nada ancorado — acrescente um par de depósitos cheios |
| **η_v : 0,93 · 6 amostras** | O rendimento volumétrico aprendido do modelo speed-density e as suas amostras |

Abaixo: média L/100 km, custo médio por km, litros totais, gasto total, número de abastecimentos. Um toque abre as [estatísticas completas](#estatísticas-de-consumo).

---

## Registar um abastecimento

Toque em **➕ Adicionar abastecimento** — ou muito mais rápido: **Adicionar abastecimento** diretamente na página de detalhe de um posto, que preenche posto, combustível e preço.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Formulário de abastecimento preenchido com marca, combustível e preço de uma pesquisa recente">

*A partir de um posto, três campos já estão certos — escreve litros, total e conta-quilómetros.*

| Campo | Porque importa |
|---|---|
| **Data** | Ordena as janelas de depósito |
| **Veículo** | Atribui o abastecimento e a calibração |
| **Tipo de combustível** | Num flex-fuel toda a comparação depende deste campo |
| **Litros** | O numerador da verdade da bomba |
| **Custo total** | Custo por km, gasto mensal |
| **Conta-quilómetros** | **O campo mais importante do formulário** |
| **Tanque cheio** | Fecha uma janela de calibração — ver abaixo |
| Posto, notas | Opcionais |

### Porque é que o conta-quilómetros é o campo crítico

O consumo é litros ÷ quilómetros. Os litros vêm do talão e são exatos. Os quilómetros vêm das *suas duas leituras do conta-quilómetros*. Um erro de 20 km num depósito de 600 km é 3 % de erro — e como esse resultado recalibra o estimador, o erro propaga-se a toda a estimativa futura. O formulário recusa um conta-quilómetros inferior ao do abastecimento anterior, porque a distância não anda para trás.

### A caixa « Tanque cheio »

Marque-a sempre que encher até acima. É isso que transforma dois abastecimentos numa **janela fechada** com um consumo fisicamente verdadeiro.

Os abastecimentos parciais são registados na mesma, contam para o custo e aparecem na lista — apenas não podem fechar uma janela. O ecrã de estatísticas mostra um aviso a contar os *« abastecimentos parciais à espera de um depósito cheio — fora da média »*, para saber sempre o que está nos números.

### Digitalizar em vez de escrever

- **Digitalizar o visor da bomba** — aponte a câmara ao visor; a aplicação lê litros, total e preço.
- **Digitalizar o talão** — o mesmo a partir do recibo impresso.
- **Partilhar uma foto de talão** de outra aplicação diretamente para o formulário.

O reconhecimento corre **no dispositivo**; a imagem nunca é enviada. Dê sempre uma olhada aos valores antes de guardar — uma digitalização é um avanço, não um oráculo. Se errar, *Reportar erro de leitura* abre uma questão com o recorte para melhorar o reconhecimento.

> **Versão F-Droid:** o reconhecimento de texto no dispositivo só existe nas versões Play / App Store. A versão F-Droid sem GMS não tem digitalização — aí os abastecimentos escrevem-se à mão. Todo o resto é idêntico.

---

## O relatório do depósito — o momento da verdade

Sempre que um depósito cheio fecha, a aplicação publica um relatório. No separador Viagens aparece assim:

<img src="guide/trips-tab.jpg" width="340" alt="Relatório do depósito: 6,4 L/100 km, diferença face ao anterior, barra de cobertura e veredicto de calibração">

*Um cartão, quatro afirmações diferentes — e de propósito não são o mesmo número.*

| Linha | O que é |
|---|---|
| **6,4 L/100 km** | A **verdade da bomba** deste depósito: litros abastecidos ÷ quilómetros do conta-quilómetros |
| **1,5 L/100 km menos do que o abastecimento anterior** | Tendência face ao último depósito fechado |
| **559 km · 35,7 L · 32,12 €** | A janela em bruto |
| **As gravações cobrem 81 % deste depósito** | Que parte desses quilómetros gravou de facto |
| **Parte gravada: 10,5 L/100 km** | O que só os quilómetros gravados deram |
| **As estimativas gravadas estão 39 % acima da verdade da bomba** | O veredicto de calibração — o estimador lia alto e acaba de ser corrigido |

### Lê-lo corretamente

A parte gravada e a verdade da bomba **podem diferir**, por duas razões distintas que é fácil confundir:

1. **A seleção.** Grava as viagens que grava. Se os seus 81 % forem sobretudo urbano curto e os 19 % em falta um troço de autoestrada, a parte gravada é legitimamente mais alta do que a média do depósito. Nada está avariado.
2. **A calibração.** O próprio estimador pode estar enviesado. É isso que a última linha mede, comparando os dois **por quilómetro**, de modo que a cobertura se anula e apenas determina o peso da janela.

Depois de uma correção como esta, espere que as estimativas de viagem desçam nitidamente na próxima viagem e depois estabilizem. O mecanismo completo: [Como funciona o Sparkilo → Como um litro se torna um número](User-pt-How-It-Works#como-um-litro-se-torna-um-número).

O cartão também pode apontar *o que mudou* — parte de rotação alta, eventos bruscos por 100 km, arranques a frio, parte de ralenti, cada um face ao depósito anterior — com a ressalva explícita de que as gravações são espontâneas e cobrem apenas parte do depósito.

---

## Estatísticas de consumo

Toque no cartão de estatísticas, ou **Combustível → Estatísticas de consumo**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="Cabeçalho das estatísticas: chips de filtro por combustível, totais e tabela este mês vs mês passado">

*Os chips do topo restringem tudo o que se segue a um combustível — indispensável num flex-fuel, onde uma média combinada não significa nada.*

A tabela mensal mostra litros, gasto, preço médio por litro, consumo médio, custo por km e número de abastecimentos, cada um com a sua diferença. As setas vermelhas não são um juízo — um *gasto* a subir depois de um *preço por litro* a subir é o mercado, não o seu pé direito. O número a vigiar para a condução é **L/100 km**.

### Custo por quilómetro por combustível

<img src="guide/consumption-stats-2.jpg" width="340" alt="Custo por quilómetro por combustível: linhas E85 e E5 com custo/km, L/100 km, preço pago e CO2">

*A verdadeira pergunta de quem conduz flex-fuel, respondida: não que combustível custa menos por litro, mas qual custa menos por quilómetro.*

Cada combustível tem uma linha construída apenas sobre **janelas de depósito fechadas**: L/100 km medidos, preço realmente pago por litro, custo por 100 km, gasto total, distância medida, litros consumidos, CO₂ por 100 km, e quantos depósitos cheios estão por trás. Uma linha apoiada num único depósito é marcada **Provisória**.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Cartão de veredicto sobre o custo de utilização com o vencedor, o ponto de equilíbrio e a nota de CO2">

*O cartão de veredicto anuncia o vencedor, a diferença por 1000 km e — o mais útil — o **preço de equilíbrio**.*

A linha de equilíbrio (« E5 passa a ser melhor do que E85 abaixo de 0,75 €/L ») é calculada a partir do **seu próprio consumo medido de cada combustível**: move-se portanto com a sua condução. É uma regra de decisão utilizável na bomba; um rácio genérico da internet não é.

Os valores de CO₂ são estimativas do poço à roda (EU JEC WTW v5) aplicadas ao seu consumo medido — sensibilização, não contabilidade certificada. As misturas ficam fora do CO₂ porque o fator de emissão depende da mistura, que a linha não regista.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Evolução no tempo: litros por mês e gasto por mês, empilhados por combustível">

*Os gráficos de tendência empilham por combustível: uma troca aparece como uma cor a substituir outra, não como um salto misterioso.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Preço por litro e L/100 km por mês">

*Preço por litro e L/100 km são dois gráficos distintos de propósito — um é o mercado, o outro é você.*

**Exportar** escreve tudo em CSV na sua pasta pública de Transferências.

---

## Eco-pontuação por abastecimento

Cada abastecimento recebe um distintivo comparado com a média móvel dos seus três últimos abastecimentos do mesmo combustível:

| Diferença | Distintivo | Como ler |
|---|---|---|
| ≥ 3 % melhor | 🟢 A melhorar | Nitidamente menos do que a sua própria referência |
| dentro de ±3 % | ⚪ Estável | Variação normal |
| ≥ 3 % pior | 🟠 A piorar | Verifique pressão dos pneus, caixa de tejadilho, frio, mistura de estradas |

O distintivo fica escondido até ter quatro abastecimentos desse combustível, para que a referência seja real.

---

## Quando as contas não batem certo

Mais cedo ou mais tarde vai abastecer mais litros do que as suas viagens gravadas conseguem explicar — conduziu outra pessoa, o adaptador estava desligado, a aplicação fechada. Em vez de absorver a diferença em silêncio, a aplicação mostra um **aviso de desvio** e propõe uma breve reconciliação:

> *Encontrámos um desvio de 4,2 L. Abasteceu 35,7 L, mas as suas viagens gravadas só explicam 31,5 L.*

Faz duas perguntas:

1. **Estão todos os abastecimentos deste depósito completos e corretos?** — Não significa que falta um ou está mal escrito, e a aplicação acrescenta um **abastecimento de correção** para os litros baterem certo.
2. **Estão todas as suas viagens gravadas?** — Não significa que falta uma viagem, e a aplicação acrescenta uma **viagem virtual** para a distância em falta.

Ambos os elementos são depois editáveis e apagáveis, e ambos estão marcados como gerados automaticamente para que nunca os confunda com dados reais. Também pode escolher **Decidir mais tarde** — o aviso fica até resolver.

**Porque importa:** um desvio por resolver enviesa em silêncio a janela de calibração. Resolvê-lo (ou apagar a entrada errada) mantém fiável a ancoragem à bomba.

---

## Cartões de fidelização

**Definições → Condução e consumo → Cartões de fidelização** guarda os descontos por litro das cadeias que usa. O desconto é depois aplicado nas comparações de preço, para que um posto aparentemente 2 cts/L mais caro possa corretamente aparecer como o mais barato para si. A funcionalidade ativa-se em Funcionalidades e modo de utilização → Introdução e digitalização.

---

<details>
<summary>Vista completa — estatísticas de consumo, página inteira</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Estatísticas de consumo completas montadas a partir de cinco capturas">

</details>

---

**Ver também:** [Veículos e OBD2](User-pt-Vehicles-And-OBD2) · [Viagens e eco-coaching](User-pt-Trips-And-Coaching)
**Seguinte:** [Viagens e eco-coaching →](User-pt-Trips-And-Coaching)
