# Favoritos e alertas de preço

O separador ⭐ é a sua lista curta, mais os robôs que a vigiam por si.

---

## Favoritos

<img src="guide/favorites.jpg" width="340" alt="Separador Favoritos com dois postos guardados, preços por combustível e o separador de alertas">

*Dois separadores no topo: **Favoritos** e **Alertas de preço**. Cada cartão traz todas as qualidades declaradas, não só a sua.*

Marque um posto com a ★ em qualquer cartão de resultado ou no seu ecrã de detalhe.

### O que é realmente guardado

Um favorito não é um marcador, é uma **cópia local completa** do posto: identificador, morada, serviços, meios de pagamento, horários e os últimos preços vistos. Por isso o separador funciona sem rede: vê os últimos preços conhecidos, claramente marcados pelo seu carimbo de frescura.

### O que muda na prática

- **Os favoritos funcionam offline**; as pesquisas não. Antes de uma viagem sem cobertura, abra o separador uma vez em Wi-Fi.
- Os preços atualizam-se ao abrir o separador, não continuamente.
- Os favoritos estão entre as categorias que o **TankSync** replica entre os seus dispositivos, se o ativar.

### Ordenação e gestos

Ordenar por preço (mais barato primeiro, por omissão), distância ou alfabeticamente. **Deslizar para a direita** abre a navegação; **deslizar para a esquerda** remove o favorito, com opção de anular.

### Pontos de carregamento

Também se podem marcar pontos de carregamento, e o cartão mostra o que quem conduz elétrico precisa: **potência por conector em kW**, quantos estão **livres agora**, e os **tipos de conector**.

### Horizontal e tablets

Em telemóveis na horizontal e em qualquer ecrã acima de 600 dp, favoritos e alertas aparecem **lado a lado** com um separador em vez de atrás de um seletor. Estando ambos visíveis, nessa disposição não há comutador.

---

## Alertas de preço

<img src="guide/price-alerts.jpg" width="340" alt="Ecrã de alertas: contadores ativos/hoje/esta semana, alertas de posto e de zona">

*Três contadores no topo — regras ativas, disparos hoje e esta semana — depois os dois tipos de alerta. O rodapé data a última verificação em segundo plano.*

Há dois tipos, que respondem a perguntas diferentes.

### Alerta de posto — « avisa-me quando *esta* bomba baixar »

Criado a partir da página de detalhe de um posto (ícone de sino). Escolha o combustível, defina um limiar, guarde. Ideal para o posto que já usa.

### Alerta de zona — « avisa-me quando *por aqui* baixar »

<img src="guide/price-alert-create.jpg" width="340" alt="Criar um alerta de zona: rótulo, tipo de combustível, limiar, raio, frequência, posição ou código postal">

*Definições → Preços e alertas → Alertas de preço → **Criar um alerta de zona**.*

| Campo | O que faz |
|---|---|
| **Rótulo** | Texto livre para que uma lista de alertas continue legível (« Gasóleo casa ») |
| **Tipo de combustível** | Uma qualidade por alerta — um posto pode ter vários |
| **Limiar (€/L)** | Dispara quando um posto da zona desce **abaixo** |
| **Raio (km)** | A área vigiada em redor do ponto central |
| **Frequência de verificação** | De quanto em quanto a tarefa de fundo olha — ver abaixo |
| **A minha posição / Escolher no mapa / Código postal** | Três formas de fixar o centro; um código postal nunca toca no GPS |

Ideal para « avisa-me quando o gasóleo descer abaixo de 1,60 € num raio de 5 km de casa », quando o posto concreto é indiferente.

---

## Como funciona realmente a verificação

Uma tarefa de fundo agendada pelo sistema acorda e:

1. Obtém os preços em direto dos postos envolvidos.
2. Compara cada um com o seu limiar.
3. Dispara uma **notificação local** se algum preço estiver abaixo. O toque abre o posto.

A cadência é **de 30 em 30 minutos a carregar, de hora a hora caso contrário**, e só com ligação. A sua frequência por alerta é um teto dentro disso: « uma vez por dia » faz a tarefa saltar o alerta quase sempre.

### O que muda na prática

- **Os alertas são de melhor esforço, não em tempo real.** É o sistema que decide quando a tarefa corre; os poupadores agressivos atrasam-na ou matam-na. Se o horário importa, retire a aplicação da otimização de bateria.
- **Não é usado GPS.** Os alertas trabalham sobre as coordenadas guardadas dos postos: um alerta à volta de casa continua a funcionar a 500 km.
- **O custo em bateria é desprezável** — alguns KB por acordar, numa janela gerida pelo sistema, compatível com Doze. Bem abaixo de 0,5 % por dia.
- **Um efeito secundário útil:** a mesma verificação escreve um registo de preço no seu histórico local. Um posto sob alerta constrói assim o seu histórico de 30 dias em horas em vez de semanas — e é isso que faz aparecer cedo o aviso *melhor momento para abastecer*. Ver [Histórico de preços](User-pt-Price-History-And-Predictions#a-fase-de-aprendizagem).
- **Se as notificações estiverem desligadas ao nível do sistema**, o interruptor da aplicação não dispara nada.

---

## Estatísticas

Os contadores do topo mostram quantas regras estão ativas e quantas vezes dispararam hoje e esta semana — um teste rápido para saber se a tarefa de fundo corre de facto. Uma fila de zeros com vários alertas ativos e um carimbo « última verificação » antigo é o sintoma clássico de um poupador de bateria a matar a tarefa.

---

## Parar alertas

Desativar um alerta põe-no em pausa sem perder a regra; deslizar para a esquerda elimina-o. Retirar o posto dos favoritos **não** elimina os seus alertas.

---

**Ver também:** [Histórico e previsões de preços](User-pt-Price-History-And-Predictions) · [Referência de definições → Preços e alertas](User-pt-Settings-Reference#preços-e-alertas)
**Seguinte:** [Carregamento elétrico →](User-pt-EV-Charging)
