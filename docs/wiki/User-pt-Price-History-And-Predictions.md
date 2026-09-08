# Histórico e previsões de preços

A aplicação constrói uma imagem **privada e local** de como os preços se movem à sua volta, e daí tira uma recomendação honesta.

---

## O que é registado, e onde

Sempre que o preço de um posto passa pela aplicação — uma pesquisa, uma atualização de favoritos ou uma verificação de alertas em segundo plano — a aplicação escreve **no seu telemóvel** um registo: posto, combustível, preço, data e hora. Nada é enviado, e não se descarregam dados de mais ninguém.

- **Desduplicado a um registo por posto e por hora.** Cinco pesquisas em dez minutos dão uma entrada.
- **Conservado 30 dias.** Os registos mais antigos são apagados automaticamente.
- **Ativado por** *Funcionalidades e modo de utilização → Preços e alertas → Histórico de preços*. Desligado, não se escreve nenhum registo.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Preços e alertas: histórico, previsão TFLite, relatos comunitários, QR de pagamento">

*Definições → Preços e alertas. O **histórico de preços** é o pré-requisito da previsão abaixo — sem histórico não tem com que trabalhar.*

---

## Consultar o histórico de um posto

Abra a página de detalhe de um posto e desça até **Histórico de preços**:

- **Gráfico horário** — preço médio para cada hora do dia nos últimos 30 dias.
- **Gráfico por dia da semana** — média por dia.
- **Mín / máx / média / tendência** em resumo.

A hora ou o dia mais barato aparece a verde, o mais caro a vermelho.

---

## « Melhor momento para abastecer »

Assim que houver histórico suficiente, o posto mostra um aviso:

> 💡 **Os preços costumam descer à terça-feira 18:00–20:00** — poupe ~3,2 cts/L

### O que é — e o que não é

É um **resumo do que já aconteceu naquele posto nos últimos 30 dias**, nos *seus* dados. Deliberadamente **não** é:

- uma previsão do preço de amanhã,
- consciente do mercado do petróleo, de impostos ou do tempo,
- construído com dados de outros utilizadores.

Essa contenção é o ponto. Um agravamento regional de segunda-feira de manhã é um padrão local real e repetível sobre o qual se pode agir; uma previsão de mercado feita por um telemóvel, não.

### A fase de aprendizagem

O aviso fica escondido até haver pelo menos **10 registos desse posto nos últimos 30 dias**. Quanto demora depende só da frequência com que o preço passa pela aplicação:

| Situação | Tempo até ao aviso |
|---|---|
| O posto tem um **alerta de preço** | Poucas horas — a verificação de fundo regista de 30 em 30 a 60 min |
| O posto é um **favorito** que abre todos os dias | Uns dez dias |
| Nenhum dos dois — pesquisas ocasionais | Semanas, talvez nunca |

**O truque prático:** ponha um alerta no posto que usa mesmo. O alerta rende a dobrar — avisa-o da descida e enche o histórico que produz a recomendação.

### Porque é que o seu favorito ainda não tem aviso

1. **Ainda não há registos suficientes** (ver acima).
2. **O preço quase não se moveu.** Se a amplitude em 30 dias for inferior a 0,1 cts/L não há nada sobre que agir, por isso nada é mostrado.
3. **Só um combustível tem amostras.** O limiar é por tipo de combustível, não por posto.

---

## Previsão de preços no dispositivo

*Funcionalidades e modo de utilização → Preços e alertas → **Melhor momento para abastecer*** ativa um pequeno modelo TensorFlow Lite que corre **inteiramente no dispositivo**. As suas características e previsões nunca saem do telemóvel. É o que alimenta a variante *preditiva* do widget do ecrã inicial (**Definições → Unidades e apresentação → Widget do ecrã inicial → Variante de conteúdo**), que mostra o melhor momento para abastecer em vez do simples preço atual.

Se preferir que nada seja inferido, desative-o: histórico e aviso de padrão continuam a funcionar.

---

## Relatos de preço da comunidade

*Funcionalidades e modo de utilização → Preços e alertas → **Relatos de preço comunitários*** acrescenta uma ação de reporte ao detalhe do posto, para corrigir um preço que a fonte oficial tem errado. Os relatos vão para a base TankSync partilhada sob a sua conta pseudónima e são visíveis a outros utilizadores autenticados — é portanto a única funcionalidade de preços que **não** é puramente local. Requer TankSync e está desligada até a ativar.

---

## Exportar

**Definições → Privacidade e dados → Exportar ou eliminar → Exportar os meus dados → CSV** escreve um CSV — a sua tabela de histórico de preços contém posto, combustível, preço, data e hora — na sua pasta pública de Transferências.

---

**Ver também:** [Favoritos e alertas](User-pt-Favorites-And-Alerts) · [Encontrar postos → A frescura](User-pt-Finding-Stations#a-frescura-mais-importante-do-que-o-preço)
**Seguinte:** [Referência de definições →](User-pt-Settings-Reference)
