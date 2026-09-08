# Como funciona o Sparkilo

Esta página é o modelo mental. Todo o resto do guia descreve percursos de clique; aqui explica-se *porquê* esses percursos têm esta forma. Dez minutos aqui poupam-lhe uma hora a vasculhar as definições.

---

## Os três níveis de poupança

Um carro custa dinheiro de três formas independentes, e baixar uma não faz nada pelas outras:

1. **O preço por litro** — a bomba que escolhe. Definido pela geografia e pelo mercado; o papel da aplicação é mostrar-lhe a mais barata a que consegue realmente chegar.
2. **Os litros por quilómetro** — como conduz e o que conduz. O papel da aplicação é medi-lo com honestidade e mostrar que hábito custa mais.
3. **O que pagou de facto** — o registo de auditoria. O papel da aplicação é manter as suas próprias estimativas ancoradas à realidade em vez de as deixar derivar.

O nível 1 funciona desde a instalação. Os níveis 2 e 3 precisam de dados seus: no mínimo os abastecimentos, idealmente também viagens gravadas. **A aplicação nunca finge saber mais do que lhe disseram** — daí os distintivos de precisão, as percentagens de cobertura e as etiquetas « provisório » em vez de números redondos e confiantes.

---

## Modos de utilização: a aplicação à sua medida

O Sparkilo pode ser um procurador de preços de dois ecrãs ou um computador de bordo completo. Em vez de impor todos os interruptores a toda a gente, a aplicação agrupa as funções em **predefinições de modo de utilização**.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Gestão de funcionalidades com as predefinições Básico, Médio, Completo e Personalizado">

*Definições → Funcionalidades e modo de utilização. Escolher uma predefinição comuta de uma vez todo o conjunto correspondente; tocar depois num interruptor individual leva-o a **Personalizado**.*

| Predefinição | Obtém | Barra inferior |
|---|---|---|
| **Básico** | Combustível e carregamento mais baratos por perto, favoritos, alertas, itinerários | Favoritos · Mapa · **Pesquisar** |
| **Médio** | Tudo o de Básico + registo manual dos abastecimentos, consumo e custo reais | + Combustível |
| **Completo** | Tudo o de Médio + gravação OBD2 automática das viagens, pontuações, cartões de fidelização | + Viagens |
| **Personalizado** | A sua própria mistura — assim que toca num interruptor | conforme o caso |

### Como funciona de verdade

Uma predefinição não é um modo em que a aplicação corre — é um **conjunto de sinalizadores de funcionalidade com nome**. Cada sinalizador mostra ou esconde uma função de forma independente, e alguns declaram pré-requisitos: *Sincronização de referências* fica desativada enquanto o *TankSync* estiver desligado, *Anúncios de voz* enquanto o *Retorno falado* estiver, *Gravação automática* enquanto não houver adaptador emparelhado. O cartão explica porque é que um interruptor está bloqueado, em vez de ignorar o seu toque em silêncio.

### O que muda na prática

- **Desativar uma função retira-a da aplicação, não apenas da vista** — o seu trabalho em segundo plano também para. *Alertas de preço* desligados param a verificação periódica; *Rasto GPS das viagens* desligado para de guardar os pontos de rota.
- **As predefinições sobrepõem-se à sua mistura.** Tocar em *Médio* reescreve cada interruptor. Se afinou à mão, fique em Personalizado.
- **A barra inferior muda de forma.** Se o separador Combustível ou Viagens desapareceu, você (ou uma predefinição) desligou *Estatísticas de consumo* ou *Gravação OBD2 das viagens* — não é um erro.

---

## Perfis: um contexto, um conjunto de valores predefinidos

Um **perfil** agrupa tudo o que depende de *onde e como conduz agora*: país, idioma, combustível preferido, raio de pesquisa predefinido, código postal de casa, parâmetros de itinerário, ecrã inicial, visibilidade das notas, as definições do radar e o veículo predefinido.

<img src="guide/profile-edit-1.jpg" width="340" alt="Editar perfil — nome, combustível derivado do veículo, raio predefinido">

*Definições → Perfis e região → editar. O combustível preferido é **derivado do seu veículo predefinido** — retire o veículo se quiser escolhê-lo você.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Secção Região do perfil — seletores de país e idioma">

*País e idioma estão dentro do perfil: por isso mudar de perfil pode mudar num toque a fonte de dados e o idioma da interface.*

### Como funciona de verdade

O país guardado no perfil ativo decide **que fornecedor nacional de dados abertos a aplicação chama**. Alterá-lo esvazia os dados de postos em cache, porque os preços do fornecedor anterior não significam nada para o novo país. O combustível preferido decide que preço encabeça cada cartão, sobre o que incide um alerta por omissão e para o que otimiza uma pesquisa de itinerário.

### O que muda na prática

- **Um perfil por cada país onde conduz.** « Casa — Portugal, Gasolina 95, 10 km » e « Férias — Espanha, E5, mapa » são dois perfis, não duas sessões de definições.
- **As pesquisas transfronteiriças usam o combustível do perfil de cada país.** Sem perfil para o segundo país, esse troço não tem qualidade para cotar e os seus postos mostram `--`.
- **A mudança automática de perfil** (Definições → Fontes de dados e localização) pode comutar o perfil quando o GPS deteta uma fronteira.
- Os mosaicos de definições trazem uma **etiqueta de âmbito** — *este perfil*, *todos os perfis* ou *este veículo* — para saber sempre até onde chega uma alteração.

---

## Uma fonte de dados por país

O Sparkilo não agrega. Cada país é consultado através da sua própria fonte oficial, e o cabeçalho de resultados nomeia-a.

<img src="guide/search-results.jpg" width="340" alt="Cabeçalho de resultados nomeando a fonte oficial francesa de preços">

*A linha por baixo da barra não é decoração — diz que autoridade publicou aqueles preços, e liga para ela.*

### Como funciona de verdade

| País | Fonte | Cadência |
|---|---|---|
| Alemanha | Tankerkönig (chave gratuita própria) | ~5 minutos |
| França | Prix-Carburants (gouv.fr) | contínua, por posto |
| Espanha | Geoportal Gasolineras (MITECO) | ficheiro diário, filtrado no dispositivo |
| Itália | Ficheiro MIMIT | ficheiro diário, filtrado no dispositivo |
| …e mais 13 | o portal de dados abertos de cada país | variável |

### O que muda na prática

- **As qualidades mudam ao atravessar a fronteira.** A Espanha vende E5 e raramente E10; a França destaca o SP95-E10; a Alemanha publica E5, E10 e Gasóleo. O mesmo combustível físico traz três nomes em três países.
- **A frescura muda.** Um preço alemão pode ter cinco minutos, um espanhol ser a publicação de ontem. O distintivo de frescura de cada cartão diz-lhe qual está a ver — confie mais nele do que no número.
- **A densidade muda.** Um conjunto de dados nacional escasso devolve menos postos no mesmo raio. São os dados do país, não uma pesquisa falhada.
- **Um `--` em vez de um preço significa « esse fornecedor não publica essa qualidade para este posto »** — não « o posto não a vende ».

---

## Onde vivem os seus dados

O Sparkilo é **local-first**. Tudo o que sabe está em bases cifradas no seu telemóvel; a chave está no Android Keystore / Porta-chaves do iOS.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Dados neste dispositivo: cada categoria de dados guardada localmente, com tamanho e contagem">

*Definições → Privacidade e dados → Dados neste dispositivo mostra cada categoria com um contador real: nada dos seus dados lhe é invisível.*

Só quatro coisas saem do telemóvel, e três são opcionais:

| O que sai | Quando | Opcional? |
|---|---|---|
| Coordenadas de pesquisa ou código de região | Em cada pesquisa, para a fonte de preços do país | Necessário para preços em direto |
| Área do mapa + o seu IP | Carregamento de mosaicos via o proxy UE do programador | Sim — proxy desligado, os mosaicos vêm diretamente do OpenStreetMap |
| Rastos de falha | Só com *Relatório de erros* ativado | Sim — desativado por omissão |
| As suas linhas sincronizadas | Só com *TankSync* ativado | Sim — desativado por omissão |

**A sua identidade nunca faz parte de um pedido de preços.** A contabilidade completa: [Privacidade, dados e sincronização](User-pt-Privacy-Profiles-Sync).

---

## Como um litro se torna um número

É a parte que a maioria das aplicações de combustível erra em silêncio, por isso vale a pena compreendê-la.

### A bomba é a verdade

O único número fisicamente certo que a aplicação obtém é **litros abastecidos ÷ quilómetros percorridos entre dois depósitos cheios**. Todo o resto — estimativas GPS, caudal derivado do medidor de massa de ar, modelo speed-density — é um modelo que pode derivar.

Por isso a aplicação trata cada **janela de depósito cheio a cheio** como um evento de calibração:

1. Regista um abastecimento e marca **Tanque cheio**. Isso fecha a janela anterior.
2. A aplicação calcula a *verdade da bomba*: litros abastecidos ÷ quilómetros do conta-quilómetros × 100.
3. Compara-a com o que o seu próprio estimador produziu nos quilómetros realmente gravados, retirando cada correção já aplicada.
4. A razão entre os dois torna-se o **ganho de bomba** do veículo, fundido com as janelas anteriores e limitado a um intervalo razoável.
5. Esse ganho multiplica depois **cada ramo estimado do caudal de combustível** — speed-density e MAF — na viagem seguinte.

O combustível que o carro *declara por si* via OBD2 (PID 5E / 9D) é medido, não modelado: o ganho nunca lhe toca.

<img src="guide/trips-tab.jpg" width="340" alt="Relatório do depósito com a cobertura e o desvio de calibração">

*O relatório do depósito torna visível a calibração: este depósito fez 6,4 L/100 km na bomba, as gravações cobriam 81 %, e o estimador estava 39 % alto antes de esta janela o corrigir.*

### Porque é que a cobertura não enviesa

Comparar os dois números **por quilómetro** faz com que os quilómetros não gravados simplesmente não pesem. Um depósito de que só gravou um quinto dá na mesma uma razão não enviesada — apenas conta menos na mistura. Por isso a aplicação mostra a percentagem de cobertura em vez de a esconder: diz quanto confiar *naquela* janela, não se a calibração é válida.

### A escala de precisão

| Distintivo | O que está por trás | Faixa típica |
|---|---|---|
| **Baixa** | Só GPS — nenhum abastecimento ancorou ainda nada | ±15 % ou pior |
| **Média** | Os abastecimentos ancoraram o modelo, mas nenhuma viagem OBD2 alimentou o ciclo | ±7–15 % |
| **Alta** | Abastecimentos *e* viagens gravadas com OBD2 | ±3–7 % |

### O que muda na prática

- **Marque sempre « Tanque cheio » quando encher até acima.** Um abastecimento parcial é registado na mesma e conta para o custo, mas não pode fechar uma janela de calibração. Os parciais pendentes aparecem como aviso nas estatísticas.
- **A precisão do conta-quilómetros importa mais do que a dos litros.** Um erro de digitação de 2 % envenena a janela; 0,2 L de arredondamento não.
- **A primeira janela é levada à letra, as seguintes suavizam.** Espere um salto e depois estabilidade.
- **Se conduzir sem gravar, as contas não vão bater certo** — e a aplicação di-lo em vez de disfarçar. Ver a reconciliação em [Registo de abastecimentos e consumo](User-pt-Fuel-And-Consumption#quando-as-contas-não-batem-certo).

---

## Como a aplicação aprende a sua condução

Independentemente do ganho de bomba, um veículo traz uma **referência por situação de condução**: o que o seu carro consome ao ralenti, em stop & go, na cidade, na autoestrada, a desacelerar, em subida ou carregado, a frio, sob carga sustentada e em ponto morto.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibração de referência com amostras por situação e aviso de situações em falta">

*Cada situação enche-se de forma independente. O aviso é honesto: duas situações ainda não têm amostras, logo a referência está incompleta.*

### Como funciona de verdade

Cada amostra OBD2 é classificada numa situação de condução e somada a esse cesto. Existem dois modos de classificação:

- **Baseado em regras** — cada amostra pertence a exatamente uma situação. Nítido, mas um carro a 60 km/h salta de amostra em amostra entre « urbano » e « autoestrada ».
- **Fuzzy** *(predefinido)* — cada amostra é repartida por todas as situações consoante o quanto encaixa em cada uma. Suave precisamente onde o modo de regras salta.

### O que muda na prática

- **Uma referência pertence ao veículo, não ao telemóvel.** Mudar de carro significa começar outra; *Sincronização de referências* (requer TankSync) leva-a para um segundo dispositivo.
- **As situações em falta são lacunas honestas, não erros.** Se nunca reboca, « Carga sustentada / reboque » ficará a 0 para sempre e a aplicação continuará a dizer que o perfil está incompleto. Está tudo bem.
- **Repor a referência devolve-o aos valores de arranque a frio** até novas viagens a encherem — faça-o após uma intervenção mecânica, não porque um número pareceu estranho.

---

## A única regra de definições que vale a pena memorizar

As definições são uma **árvore de dois níveis**: uma raiz de mosaicos temáticos, um ecrã por tema, e um campo de pesquisa que filtra os mosaicos por palavra-chave.

<img src="guide/settings-root-1.jpg" width="340" alt="Raiz das definições com mosaicos temáticos e campo de pesquisa">

*Cada parâmetro tem exatamente uma casa. Se se lembrar do tema, nunca precisa de percorrer.*

Mapa completo de todos os ecrãs: [Referência de definições](User-pt-Settings-Reference).

---

**Seguinte:** [Encontrar postos →](User-pt-Finding-Stations)
