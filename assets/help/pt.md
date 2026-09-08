# Sparkilo — Guia do utilizador (Português)

> *Pagar menos por litro. Queimar menos litros por quilómetro. Ver exatamente quanto custou.*

Sparkilo é uma aplicação livre e gratuita que **reduz o custo de utilização do seu carro**. Sem conta, sem publicidade, sem rastreadores, sem Google Play Services. Tudo o que a aplicação sabe sobre si fica no telemóvel até ativar outra coisa.

*O ecrã que mais vai usar: preços em direto perto de si, os mais baratos primeiro, com a fonte oficial de dados abertos indicada em cima.*

---

## Os três níveis de poupança

Toda a aplicação assenta numa ideia: **um carro custa dinheiro de três formas independentes, e cada uma exige uma ferramenta diferente.**

| Nível | A pergunta que responde | Onde vive |
|---|---|---|
| **1. O preço** | *Onde é que o combustível está mais barato agora?* | Pesquisa, Mapa, Favoritos, Alertas, Itinerários |
| **2. O consumo** | *Quantos litros aos 100 km, e porquê?* | Viagens, eco-coaching, OBD2 |
| **3. A verdade** | *Quanto paguei de facto, e a estimativa da aplicação é honesta?* | Separador Combustível, abastecimentos, estatísticas de consumo |

O nível 1 já poupa e não precisa de nada além da aplicação. Os níveis 2 e 3 precisam dos seus abastecimentos; o nível 2 fica muito mais preciso com um adaptador OBD2 barato. Até onde ir decide você — ver Como funciona o Sparkilo.

---

## O que contém este guia

**Começar aqui**

| Página | O que vai aprender |
|---|---|
| Primeiros passos | Instalação, consentimento no primeiro arranque, país e idioma, modo de utilização, primeira pesquisa |
| Como funciona o Sparkilo | Os conceitos por trás de tudo: perfis, modos de utilização, uma fonte por país, onde vivem os seus dados, como um litro se torna um número |

**Encontrar combustível barato (nível 1)**

| Página | O que vai aprender |
|---|---|
| Encontrar postos | O botão Pesquisar central, os critérios, ler um cartão, o detalhe, o mapa, o radar de postos |
| Planeamento de itinerário | As paragens mais baratas do trajeto, os corredores transfronteiriços, as quatro estratégias |
| Favoritos e alertas | Postos guardados, alertas de posto e de zona, como se comporta realmente a verificação em segundo plano |
| Carregamento elétrico | Pontos de carregamento via OpenChargeMap, conectores, filtros de potência |
| Histórico e previsões de preços | O histórico local de 30 dias, o « melhor momento para abastecer » e o que o algoritmo deliberadamente *não* faz |

**Consumir menos e saber quanto custou (níveis 2 e 3)**

| Página | O que vai aprender |
|---|---|
| Veículos e OBD2 | O modelo do veículo, a capacidade do depósito, o flex-fuel, o emparelhamento, a calibração de referência, regras vs difuso |
| Registo de abastecimentos e consumo | Abastecimentos, nível do depósito, relatório do depósito, níveis de precisão, custo por km por combustível |
| Viagens e eco-coaching | Gravação GPS ou OBD2, detalhe de uma viagem, pontuação de condução, painel de carbono |

**Referência**

| Página | O que vai aprender |
|---|---|
| Referência de definições | Cada ecrã da árvore de dois níveis, com o impacto operacional de cada interruptor |
| Privacidade, dados e sincronização | Consentimentos, os temas de Privacidade e dados, TankSync, cópia de segurança, os seus direitos RGPD |
| Resolução de problemas e FAQ | Nada encontrado? O adaptador não liga? Widget parado? |

---

## Os 17 países suportados

🇩🇪 Alemanha · 🇫🇷 França · 🇦🇹 Áustria · 🇪🇸 Espanha · 🇮🇹 Itália · 🇩🇰 Dinamarca · 🇵🇹 Portugal · 🇱🇺 Luxemburgo · 🇸🇮 Eslovénia · 🇬🇧 Reino Unido · 🇦🇷 Argentina · 🇦🇺 Austrália · 🇲🇽 México · 🇰🇷 Coreia do Sul · 🇨🇱 Chile · 🇬🇷 Grécia · 🇷🇴 Roménia

Cada país é servido pela **sua própria fonte pública oficial em dados abertos** — nunca por um agregador único. A Alemanha exige uma chave API gratuita de [tankerkoenig.de](https://creativecommons.tankerkoenig.de/); os restantes funcionam de imediato. Porque é que isso importa para o que vê no ecrã: Como funciona o Sparkilo.

A interface está traduzida em **23 idiomas** (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) e segue o idioma do sistema.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Disponível no Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/pt-br_badge_web_generic.png" height="80"/>
</a>

---

**Seguinte:** Primeiros passos →

> **Sobre as capturas.** Todas as capturas deste guia vêm de um dispositivo com a aplicação em **francês**, contra a fonte de preços francesa em direto. A interface está totalmente localizada — os seus ecrãs têm a mesma disposição com as palavras do seu idioma.

---

# Primeiros passos

Dez minutos entre a instalação e o primeiro euro poupado. Se depois ler apenas mais uma página, que seja Como funciona o Sparkilo.

---

## 1. Instalar

### Google Play (Android)

Instale a partir da **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — a versão pública de produção.

> **Vem da beta?** O Play continua a servir compilações beta depois de se inscrever no teste aberto (a ficha mostra uma etiqueta *(beta)*). Para passar a produção: abra a [ficha do Play](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Sair do programa** → desinstalar → reinstalar.
>
> **Quer as novidades primeiro?** Fique na beta — cada compilação chega ao canal beta antes da produção.

### F-Droid (Android, sem Google)

Uma compilação totalmente **sem GMS** é distribuída pelo seu próprio repositório F-Droid (mapas OpenStreetMap, nenhum serviço Google). No F-Droid: **Definições → Repositórios → +** e adicione:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Depois procure **Sparkilo**. Se tiver a versão do Play instalada, desinstale-a primeiro — chave de assinatura diferente, logo não atualiza por cima.

### Outras vias

- **APK** — a partir das [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — beta TestFlight; peça um convite via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) enquanto a ficha da App Store não estiver publicada.

**Android mínimo** 7.0 (API 24), alvo Android 15. **iOS mínimo** 15.5, alvo iOS 18.

Sem conta, sem registo, sem e-mail. A aplicação fica plenamente utilizável assim que a instalação termina.

---

## 2. Primeiro arranque — o consentimento

Antes de qualquer outro ecrã, a aplicação mostra um **ecrã de consentimento RGPD**. Não é um aviso de cookies: enumera cada finalidade de tratamento, e a aplicação só prossegue se aceitar.

*Cada consentimento aqui mostrado reaparece depois em Definições → Privacidade e dados, com a data e a versão da política que viu.*

| Item | Para quê | Se recusar |
|---|---|---|
| **Localização** *(durante a utilização)* | Pesquisa por perto, início de itinerário, gravação de viagens | Pesquisar por código postal ou escolher um ponto no mapa |
| **Notificações** | Apenas para os alertas de preço | Os alertas nunca disparam |
| **Diagnóstico** | Rastos de falha para o Sentry — **desativado por omissão** | Nada é enviado; pode guardar você o registo de erros |

Antes de cada pedido *do sistema* (câmara, Bluetooth, notificações) a aplicação mostra primeiro a sua própria explicação, para saber a que consente antes de o Android perguntar.

Texto integral: **[Política de privacidade v3, 29 de agosto de 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. País, idioma e a sua zona

Ambos são detetados a partir do idioma do sistema, e ambos vivem **no perfil** — ver Como funciona o Sparkilo → Perfis.

*Definições → Perfis e região → editar perfil. O código postal de casa permite pesquisar numa zona fixa sem nunca ceder o GPS.*

Mudar de país **esvazia os dados de postos em cache**, porque os preços do fornecedor anterior não valem para o novo país. A pesquisa seguinte demorará um instante a mais.

---

## 4. Escolher um modo de utilização

É a definição de maiores consequências, porque decide quanta aplicação obtém.

*Definições → Funcionalidades e modo de utilização. Comece em **Básico** se só quiser combustível mais barato; suba quando quiser saber porque é que o seu carro bebe.*

- **Básico** — encontrar combustível e carregamento, favoritos, alertas, itinerários.
- **Médio** — acrescenta o separador **Combustível**: registar abastecimentos, ver consumo e custo reais. Sem hardware.
- **Completo** — acrescenta o separador **Viagens**: gravação automática, pontuações, cartões de fidelização. Um adaptador OBD2 continua opcional mesmo aqui — as viagens gravam-se só com GPS.

Pode mudar quando quiser, e qualquer interruptor que toque depois coloca-o em **Personalizado**. A lista completa, e o que cada um custa em bateria, dados ou privacidade: Referência de definições → Funcionalidades e modo de utilização.

---

## 5. Só Alemanha: a chave API gratuita

16 dos 17 países funcionam de imediato. O serviço oficial **alemão** emite uma chave por utilizador.

*Definições → Fontes de dados e localização. Uma cruz vermelha aqui é a razão de uma pesquisa alemã não devolver nada.*

1. Abra [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) e peça uma chave (formulário curto, gratuito).
2. Copie-a — é um UUID como `00000000-0000-0000-0000-000000000002`.
3. Cole-a no campo **Preços de combustível (Tankerkoenig)**.

A chave fica no cofre de hardware (Android Keystore / Porta-chaves do iOS) e só é enviada ao serviço alemão. O campo **Carregamento EV** abaixo já contém uma chave partilhada: os dados de carregamento funcionam sem configuração.

---

## 6. A barra inferior

*O botão verde **Pesquisar** elevado ao centro é o único acionador de pesquisa de toda a aplicação.*

- ⭐ **Favoritos** — postos guardados e alertas de preço
- 🗺️ **Mapa** — cada posto próximo como pino colorido por preço
- 🔍 **Pesquisar** *(centro)* — por perto ou ao longo de um itinerário
- ⛽ **Combustível** — depósito, consumo, abastecimentos *(a partir de Médio)*
- 🛣️ **Viagens** — diário de bordo e coaching *(Completo)*

As definições **não** são um separador: é a engrenagem no canto superior direito dos ecrãs principais. Em tablet, ou telemóvel na horizontal, a aplicação divide-se em duas colunas para ver lista e mapa (ou detalhe) ao mesmo tempo.

---

## 7. A sua primeira pesquisa

*Toque em **Pesquisar** → a folha de critérios abre preenchida a partir do seu perfil. Ajuste e toque de novo em **Pesquisar**.*

Obtém uma lista do mais barato (ou por distância — à sua escolha), cada cartão com preço, tendência, distância e frescura. Um toque abre o detalhe. A visita completa: Encontrar postos.

**Dica:** toque em **Guardar como valores predefinidos** no fim da folha assim que fixar os seus critérios habituais — toda a pesquisa futura partirá daí.

---

## 8. Duas definições a mudar no primeiro dia

*Definições → Unidades e apresentação. A **unidade de consumo** está em *Automático* por omissão (mpg no Reino Unido, L/100 km no resto); escolha explicitamente L/100 km, km/L ou mpg se preferir.*

A segunda é **Definições → Condução e consumo → Janela de consumo em direto** (3 / 5 / 10 / 30 s). Controla o grande número em direto do ecrã de gravação: uma janela longa é mais estável de ler a conduzir, uma curta reage mais depressa ao seu pé direito.

---

## 9. Escolha com o que a aplicação abre

**Definições → Perfis e região → Ecrã inicial**: *Por perto* (pesquisa imediata com os seus últimos critérios), *Posto mais próximo*, *Favoritos* ou *Mapa*. Escolha o que corresponde à razão por que abre a aplicação.

---

## 10. Onde está tudo

As definições são uma árvore de dois níveis com pesquisa por palavra-chave no topo — escreva « raio », « OBD2 » ou « tema » e o mosaico certo aparece.

*Doze temas, uma casa por parâmetro. O mapa completo é a Referência de definições.*

---

**Seguinte:** Como funciona o Sparkilo →

---

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

*Definições → Perfis e região → editar. O combustível preferido é **derivado do seu veículo predefinido** — retire o veículo se quiser escolhê-lo você.*

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

*Definições → Privacidade e dados → Dados neste dispositivo mostra cada categoria com um contador real: nada dos seus dados lhe é invisível.*

Só quatro coisas saem do telemóvel, e três são opcionais:

| O que sai | Quando | Opcional? |
|---|---|---|
| Coordenadas de pesquisa ou código de região | Em cada pesquisa, para a fonte de preços do país | Necessário para preços em direto |
| Área do mapa + o seu IP | Carregamento de mosaicos via o proxy UE do programador | Sim — proxy desligado, os mosaicos vêm diretamente do OpenStreetMap |
| Rastos de falha | Só com *Relatório de erros* ativado | Sim — desativado por omissão |
| As suas linhas sincronizadas | Só com *TankSync* ativado | Sim — desativado por omissão |

**A sua identidade nunca faz parte de um pedido de preços.** A contabilidade completa: Privacidade, dados e sincronização.

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
- **Se conduzir sem gravar, as contas não vão bater certo** — e a aplicação di-lo em vez de disfarçar. Ver a reconciliação em Registo de abastecimentos e consumo.

---

## Como a aplicação aprende a sua condução

Independentemente do ganho de bomba, um veículo traz uma **referência por situação de condução**: o que o seu carro consome ao ralenti, em stop & go, na cidade, na autoestrada, a desacelerar, em subida ou carregado, a frio, sob carga sustentada e em ponto morto.

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

*Cada parâmetro tem exatamente uma casa. Se se lembrar do tema, nunca precisa de percorrer.*

Mapa completo de todos os ecrãs: Referência de definições.

---

**Seguinte:** Encontrar postos →

---

# Encontrar postos

Nível 1 dos três níveis de poupança: pagar menos por litro.

---

## Um botão, um modelo mental

A barra inferior tem um único acionador de pesquisa — o botão verde elevado ao centro. É contextual, não modal:

- **A partir de qualquer separador** → abre a folha de critérios.
- **A partir dos resultados ou do mapa** → reabre a folha com os seus últimos valores.
- **Dentro da folha** → executa a pesquisa.

O rótulo diz o que vai fazer, e no modo itinerário fica desativado até haver destino. Deliberadamente não existem botões separados de « pesquisar perto » e « pesquisar no trajeto ».

---

## Definir os critérios

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

### O botão de pesquisa

O botão em relevo no meio da barra inferior é o único disparador de
pesquisa. A partir de qualquer separador abre esta folha; a partir dos
resultados ou do mapa reabre-a com o que usou por último; dentro da
folha, lança a pesquisa.

### Por perto ou ao longo de uma rota

Duas perguntas diferentes. **Por perto** procura à volta da sua posição
ou de uma morada. **Ao longo da rota** precisa de um destino e mede a
distância ao longo do corredor e não em linha reta: um posto a 2 km numa
rua lateral fica atrás de um que está no seu caminho.

### Tipo de combustível

Para que combustível são os preços. Os chips adaptam-se ao que o
fornecedor do seu país publica de facto — um combustível ausente da lista
falta nos dados, não na aplicação.

### Raio

Até onde procurar. Um raio amplo num país denso devolve muitíssimos
postos e uma pesquisa mais lenta, e os postos a mais estão normalmente
mais longe do que vale a poupança.

### Apenas abertos agora

Esconde os postos fechados. Depende de o fornecedor publicar horários, e
alguns não publicam — quando faltam, o posto é mantido em vez de
adivinhado.

### Serviços

Loja, lavagem, ar, WC. Estes filtros agem sobre dados **declarados**: um
posto que não publica nada sobre os seus serviços desaparece de uma lista
filtrada mesmo que os tenha todos.

### Postos de autoestrada

Os postos de autoestrada são normalmente o combustível mais caro do país:
excluí-los é o filtro que mais vezes muda o que paga. Mantenha-os quando
não puder sair da autoestrada.

### Guardar como os meus valores predefinidos

Escreve estes critérios no seu perfil, para que cada pesquisa seguinte
comece aqui e não nos valores da aplicação. É a definição que torna a
folha uma confirmação num toque em vez de um formulário.

### Como funciona de verdade

Uma pesquisa por perto envia **as suas coordenadas (ou um código de região) e um raio** ao fornecedor oficial do seu país — nunca a sua identidade. Os países que publicam um ficheiro diário (Espanha, Itália) são filtrados no dispositivo: essas pesquisas não precisam de qualquer chamada de rede depois de o ficheiro estar em cache.

---

## Ler um cartão de resultado

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

A frescura é uma propriedade do **fornecedor do país**, não da aplicação. Um preço espanhol de 14 horas não é um erro: aquele país publica uma vez por dia. Ver Como funciona o Sparkilo → Uma fonte por país.

### Gestos

- **Deslizar para a direita** — abrir na sua aplicação de navegação (Google Maps, Waze, OsmAnd, Organic Maps).
- **Deslizar para a esquerda** — esconder o posto de todos os resultados futuros. Repõe-se em **Privacidade e dados → Dados neste dispositivo → Postos ignorados**.

---

## Detalhe de um posto

*Toque num cartão. O cabeçalho recua de marca para nome e para rua, por isso um Intermarché sem campo de marca continua a mostrar « Intermarché ».*

O bloco de cima é a **tabela completa de preços** — cada qualidade que o fornecedor publica para esse posto, com `--` onde não publica nenhuma. É a forma mais rápida de ver se o posto de E85 barato também aguenta no gasóleo.

**Adicionar abastecimento** preenche posto, combustível e preço no formulário — a maior poupança de tempo da aplicação se registar os seus abastecimentos.

*Mais abaixo: serviços, meios de pagamento aceites, a sua avaliação privada em estrelas, e o histórico local de preços de 30 dias.*

As ações da barra superior são, da esquerda para a direita: **criar um alerta de preço**, **ler um QR de pagamento**, **reportar um preço errado** e **marcar como favorito**.

---

## O mapa

*A cor é relativa ao que está no ecrã: verde o mais barato visível, vermelho o mais caro. O rodapé indica número de postos, raio e idade dos dados.*

- **Os marcadores de grupo** juntam pinos ao afastar; um toque aproxima.
- **Toque longo** em qualquer ponto para largar o seu marcador e pesquisar a partir dali.
- O **seletor EV** no canto superior direito muda o mapa para pontos de carregamento — ver Carregamento elétrico.
- **Partilhar** envia a vista atual a alguém.

Os mosaicos vêm do OpenStreetMap. Por omissão passam pelo proxy UE do programador para que o OpenStreetMap nunca veja o seu IP; pode desligar o proxy em Definições → Privacidade e dados e carregar diretamente. A versão F-Droid nunca usa o proxy.

---

## O radar de postos de combustível

Uma varredura em direto à volta da sua posição, pensada para **conduzir**.

*Depois de qualquer pesquisa por perto surge uma pastilha flutuante em baixo à direita. Um toque inicia o radar.*

### Como funciona de verdade

O radar atualiza a sua posição GPS, obtém as **localizações** dos postos num amplo corredor de 60 km e funde um pedido direto dentro do raio: nunca pode mostrar menos do que uma pesquisa normal. Os postos não se movem, por isso essas localizações ficam em cache até uma hora e são reutilizadas; só o **preço** de um posto de que se está a aproximar é obtido na altura. É isso que torna barato em dados e bateria um radar sempre ligado.

*Em funcionamento: resultados por distância, cada um com uma barra que enche à medida que se aproxima.*

### Durante a gravação de uma viagem

O radar fixa um cartão **Posto mais próximo** no topo do ecrã de gravação — nome, preço do seu combustível, distância, e uma barra que chega a 100 % à chegada. Deslize para os lados para percorrer as candidatas. Ao entrar no raio de aproximação configurado, a miniatura sobreposta muda para uma grande apresentação de preço; ver Viagens e eco-coaching → O overlay de aproximação.

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

</details>

---

**Ver também:** Planeamento de itinerário · Favoritos e alertas · Histórico de preços
**Seguinte:** Planeamento de itinerário →

---

# Planeamento de itinerário

Não « o mais barato perto de mim » mas **o mais barato no caminho** — a diferença vale vários euros em qualquer viagem longa.

---

## Lançar uma pesquisa por itinerário

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

**Precisa de um perfil por país** com a qualidade preferida certa, senão o segundo troço não tem nada para cotar e mostra `--`. Ver Como funciona o Sparkilo → Perfis.

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

**Ver também:** Encontrar postos · Referência de definições
**Seguinte:** Favoritos e alertas →

---

# Carregamento elétrico

O Sparkilo não é só para térmicos. Os pontos de carregamento vêm do [OpenChargeMap](https://openchargemap.org), o maior registo comunitário aberto do mundo.

---

## Ativar

Dois interruptores independentes, ambos em **Definições → Funcionalidades e modo de utilização → Pesquisa e mapa**:

- **Carregamento EV** — a funcionalidade em si (pesquisa, páginas de detalhe, favoritos).
- **Mostrar os pontos de carregamento** — se os pontos aparecem nos resultados e no mapa.

*Pode mostrar postos, pontos de carregamento, ou ambos. Quem conduz só elétrico costuma desligar **Mostrar postos de combustível**.*

Depois crie um veículo em **Definições → Veículos e OBD2 → Os meus veículos → Adicionar**, escolhendo **Elétrico** como motorização. Um veículo elétrico traz capacidade da bateria (kWh), potências máximas de carga AC e DC (kW) e os seus conectores (Tipo 2, CCS, CHAdeMO, Tesla, Schuko, Tipo 1, ficha doméstica). As pesquisas limitam-se então aos pontos que o seu carro pode mesmo usar.

---

## Como funcionam os dados

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

**Ver também:** Encontrar postos · Registo de abastecimentos e consumo
**Seguinte:** Veículos e OBD2 →

---

# Favoritos e alertas de preço

O separador ⭐ é a sua lista curta, mais os robôs que a vigiam por si.

---

## Favoritos

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

*Três contadores no topo — regras ativas, disparos hoje e esta semana — depois os dois tipos de alerta. O rodapé data a última verificação em segundo plano.*

Há dois tipos, que respondem a perguntas diferentes.

### Alerta de posto — « avisa-me quando *esta* bomba baixar »

Criado a partir da página de detalhe de um posto (ícone de sino). Escolha o combustível, defina um limiar, guarde. Ideal para o posto que já usa.

### Alerta de zona — « avisa-me quando *por aqui* baixar »

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
- **Um efeito secundário útil:** a mesma verificação escreve um registo de preço no seu histórico local. Um posto sob alerta constrói assim o seu histórico de 30 dias em horas em vez de semanas — e é isso que faz aparecer cedo o aviso *melhor momento para abastecer*. Ver Histórico de preços.
- **Se as notificações estiverem desligadas ao nível do sistema**, o interruptor da aplicação não dispara nada.

---

## Estatísticas

Os contadores do topo mostram quantas regras estão ativas e quantas vezes dispararam hoje e esta semana — um teste rápido para saber se a tarefa de fundo corre de facto. Uma fila de zeros com vários alertas ativos e um carimbo « última verificação » antigo é o sintoma clássico de um poupador de bateria a matar a tarefa.

---

## Parar alertas

Desativar um alerta põe-no em pausa sem perder a regra; deslizar para a esquerda elimina-o. Retirar o posto dos favoritos **não** elimina os seus alertas.

---

**Ver também:** Histórico e previsões de preços · Referência de definições → Preços e alertas
**Seguinte:** Carregamento elétrico →

---

# Histórico e previsões de preços

A aplicação constrói uma imagem **privada e local** de como os preços se movem à sua volta, e daí tira uma recomendação honesta.

---

## O que é registado, e onde

Sempre que o preço de um posto passa pela aplicação — uma pesquisa, uma atualização de favoritos ou uma verificação de alertas em segundo plano — a aplicação escreve **no seu telemóvel** um registo: posto, combustível, preço, data e hora. Nada é enviado, e não se descarregam dados de mais ninguém.

- **Desduplicado a um registo por posto e por hora.** Cinco pesquisas em dez minutos dão uma entrada.
- **Conservado 30 dias.** Os registos mais antigos são apagados automaticamente.
- **Ativado por** *Funcionalidades e modo de utilização → Preços e alertas → Histórico de preços*. Desligado, não se escreve nenhum registo.

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

**Ver também:** Favoritos e alertas · Encontrar postos → A frescura
**Seguinte:** Referência de definições →

---

# Registo de abastecimentos e consumo

Níveis 2 e 3 dos três níveis de poupança: quanto queima, e quanto custou de facto. O separador ⛽ **Combustível** aparece nos modos **Médio** e **Completo**.

---

## O separador Combustível num relance

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

Depois de uma correção como esta, espere que as estimativas de viagem desçam nitidamente na próxima viagem e depois estabilizem. O mecanismo completo: Como funciona o Sparkilo → Como um litro se torna um número.

O cartão também pode apontar *o que mudou* — parte de rotação alta, eventos bruscos por 100 km, arranques a frio, parte de ralenti, cada um face ao depósito anterior — com a ressalva explícita de que as gravações são espontâneas e cobrem apenas parte do depósito.

---

## Estatísticas de consumo

Toque no cartão de estatísticas, ou **Combustível → Estatísticas de consumo**.

*Os chips do topo restringem tudo o que se segue a um combustível — indispensável num flex-fuel, onde uma média combinada não significa nada.*

A tabela mensal mostra litros, gasto, preço médio por litro, consumo médio, custo por km e número de abastecimentos, cada um com a sua diferença. As setas vermelhas não são um juízo — um *gasto* a subir depois de um *preço por litro* a subir é o mercado, não o seu pé direito. O número a vigiar para a condução é **L/100 km**.

### Custo por quilómetro por combustível

*A verdadeira pergunta de quem conduz flex-fuel, respondida: não que combustível custa menos por litro, mas qual custa menos por quilómetro.*

Cada combustível tem uma linha construída apenas sobre **janelas de depósito fechadas**: L/100 km medidos, preço realmente pago por litro, custo por 100 km, gasto total, distância medida, litros consumidos, CO₂ por 100 km, e quantos depósitos cheios estão por trás. Uma linha apoiada num único depósito é marcada **Provisória**.

*O cartão de veredicto anuncia o vencedor, a diferença por 1000 km e — o mais útil — o **preço de equilíbrio**.*

A linha de equilíbrio (« E5 passa a ser melhor do que E85 abaixo de 0,75 €/L ») é calculada a partir do **seu próprio consumo medido de cada combustível**: move-se portanto com a sua condução. É uma regra de decisão utilizável na bomba; um rácio genérico da internet não é.

Os valores de CO₂ são estimativas do poço à roda (EU JEC WTW v5) aplicadas ao seu consumo medido — sensibilização, não contabilidade certificada. As misturas ficam fora do CO₂ porque o fator de emissão depende da mistura, que a linha não regista.

*Os gráficos de tendência empilham por combustível: uma troca aparece como uma cor a substituir outra, não como um salto misterioso.*

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

</details>

---

**Ver também:** Veículos e OBD2 · Viagens e eco-coaching
**Seguinte:** Viagens e eco-coaching →

---

# Combustível, viagens e condução *(movido)*

Esta página foi dividida em três, para que cada tema tenha as suas próprias âncoras com vista a uma futura ajuda dentro da aplicação:

- **Veículos e OBD2** — o seu carro, capacidade do depósito, flex-fuel, emparelhamento, calibração de referência, gravação automática.
- **Registo de abastecimentos e consumo** — abastecimentos, nível do depósito, relatório do depósito, precisão, custo por quilómetro por combustível.
- **Viagens e eco-coaching** — gravação, detalhe de uma viagem, pontuação de condução, painel de carbono.

Comece por **Como funciona o Sparkilo** se quiser os conceitos por trás dos três.

---

# Veículos e OBD2

Tudo o que a aplicação sabe sobre *o seu carro*. É esta página que decide se os números de consumo de todas as outras são de confiança.

---

## Porque é que a aplicação precisa de um veículo

Sem veículo, o Sparkilo é um procurador de preços. Com um, pode converter litros e quilómetros no *seu* custo por quilómetro, estimar a autonomia e — com adaptador — modelar o caudal instantâneo de combustível.

*Definições → Veículos e OBD2. Repare na etiqueta de âmbito do mosaico do adaptador: os adaptadores emparelham-se **por veículo**, não por telemóvel.*

*O visto verde marca o veículo ativo — aquele a que são atribuídos novos abastecimentos e viagens.*

---

## Identidade e motorização

*Dê-lhe o nome pelo qual o reconhece. O VIN é opcional.*

### O VIN, e o que traz

Introduzir (ou ler) o VIN permite à aplicação obter cilindrada, número de cilindros, potência e tipo de combustível, que são as entradas do modelo de consumo. **Ler o VIN do carro** obtém-no num segundo via OBD2.

A descodificação online do VIN é um **consentimento separado** — a aplicação pergunta antes de enviar seja o que for, e a descodificação parcial offline funciona mesmo que recuse. Um VIN é um dado pessoal; trate-o como tal.

### Motorização

**Térmico / Híbrido / Elétrico** muda os campos abaixo. O térmico pede capacidade do depósito, potência e combustível preferido; o elétrico pede bateria e conectores.

---

## Capacidade, potência e flex-fuel

*A capacidade do depósito é o número que mais peso carrega neste ecrã.*

### Porque é que a capacidade do depósito importa tanto

É o denominador do indicador de nível e da estimativa de autonomia, e limita o que a aplicação considera um abastecimento plausível. Uma capacidade errada produz durante meses uma autonomia credível mas errada. Tire-a do manual, não da memória — os fabricantes indicam muitas vezes uma capacidade útil dois litros abaixo da nominal.

### « Posso abastecer com combustíveis diferentes »

Ative para um carro flex-fuel (E85/E10, ou o que alterne de facto). Mudam duas coisas:

- O formulário de abastecimento **pergunta de cada vez que combustível meteu mesmo**, em vez de assumir o preferido.
- O ecrã de estatísticas ganha a comparação **custo por quilómetro por combustível**, a única forma honesta de opor um combustível barato mas sedento a um caro mas sóbrio.

Deixe desligado se mete sempre a mesma qualidade — só acrescenta um campo.

---

## O adaptador OBD2

Um adaptador OBD2 é um pequeno dongle Bluetooth na tomada de diagnóstico do carro (normalmente por baixo do tablier). **É totalmente opcional.** Tudo funciona só com GPS; o adaptador transforma estimativas em medições.

### O que muda

| Sem adaptador | Com adaptador |
|---|---|
| Distância e duração por GPS | Idem, mais dados do motor |
| Consumo **modelado** a partir da sua calibração | Consumo **medido** (ou modelado muito melhor) |
| Coaching a partir de velocidade e aceleração | Coaching a partir de rotação, acelerador, carga, mudança |
| Teto de precisão: Média | Teto de precisão: Alta (±3–7 %) |
| Início manual da viagem | Gravação automática possível |

### O que a aplicação lê

Velocidade, rotação, carga do motor %, posição do acelerador %, temperaturas do líquido de refrigeração e do ar de admissão, avanço da ignição, nível de combustível %, conta-quilómetros (PID padrão A6, com recurso ao PID 31 e ao modo 22 do fabricante), e o caudal instantâneo de combustível — diretamente do **PID 5E** onde o carro o publica, ou derivado do medidor de massa de ar.

> **A distinção importante:** se o seu carro responde ao PID 5E, o consumo é *medido* e não lhe é aplicada calibração alguma. Se não responde, o valor é *modelado* a partir do caudal de ar e de parâmetros do motor, e é esse modelo que o ganho de bomba corrige. O ecrã do veículo diz-lhe em que caso está.

### Adaptadores suportados

16 modelos são reconhecidos pelo nome Bluetooth, cada um com um nível de compatibilidade:

- ✅ **Testado** — confirmado em hardware real pelo mantenedor.
- 👤 **Verificado por um utilizador** — pelo menos um utilizador diz que funciona.
- ⚠️ **Teórico** — perfil e transporte corretos, mas sem verificação ponta a ponta.

| Adaptador | Transporte | Notas | Nível |
|---|---|---|---|
| vLinker FS | BT clássico | Modelo dominante na Europa; recomendado | ✅ |
| vLinker BM-Android | BT clássico | Irmão SPP clássico do BM+ | ✅ |
| SmartOBD (BLE) | BLE | Clone ELM327 v1.5 genérico | 👤 |
| SmartOBD (Classic) | BT clássico | Mesma marca, variante SPP | 👤 |
| vLinker FD / MC | BLE | Família Nordic UART FFF0 | ⚠️ |
| OBDLink MX+ | BLE | Topo de gama Scantool | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | Clone ELM327 v2.1 BLE | ⚠️ |
| vLinker BM+ | BLE | Irmão só BLE | ⚠️ |
| Konnwei KW902 | BT clássico | Clone ELM327 v1.5 | ⚠️ |
| Vgate iCar Pro | BLE | Só variante BLE | ⚠️ |
| Panlong WiFi | — | Só WiFi, listado para rotular emparelhamentos errados | ⚠️ |
| BAFX 34t5 | BT clássico | ELM327 v1.5 antigo | ⚠️ |
| Generic ELM327 (BLE) | BLE | Perfil genérico para clones BLE FFF0 | ⚠️ |
| Generic ELM327 (Classic) | BT clássico | Perfil genérico para clones SPP | ⚠️ |

Os adaptadores não listados recaem no perfil ELM327 genérico e costumam funcionar. Se o seu funciona — ou não — [abra uma questão](https://github.com/fdittgen-png/tankstellen/issues) para corrigir o nível.

### Emparelhar

1. Ignição **ligada** (motor a trabalhar serve, ignição desligada não).
2. Ligue o adaptador; o LED deve ficar fixo.
3. Abra o veículo e toque na secção do adaptador, ou inicie uma viagem.
4. Conceda **Pesquisa Bluetooth** e **Ligação Bluetooth** (Android 12+). Até ao Android 11 o sistema exige a **localização** para procurar por Bluetooth — regra do sistema, não uma decisão de rastreio.
5. Espere cerca de 8 segundos pela varredura e toque no seu adaptador. A aplicação corre o handshake ELM327 e confirma.

Depois de emparelhado, o adaptador pertence a esse veículo. **Reiniciar a ligação** repete o handshake sem esquecer o dispositivo — a primeira coisa a tentar após uma quebra em andamento. **Esquecer o adaptador** apaga por completo o emparelhamento.

---

## Calibração de referência — ensinar o seu carro à aplicação

*210 amostras de 270. Duas situações de condução continuam vazias, e a aplicação di-lo em vez de fingir completude.*

Cada amostra OBD2 é arquivada numa situação de condução: **ralenti, stop & go, urbano, autoestrada, desaceleração, subida / carregado, arranque a frio, carga sustentada / reboque, ponto morto**. As médias por situação formam a referência do veículo — o modelo que produz um L/100 km plausível quando falta o adaptador ou um PID deixa de responder.

*As situações com zero amostras são as que recairão em valores por omissão. Aqui duas: desaceleração e reboque.*

### Baseado em regras ou fuzzy

*O modo fuzzy é o predefinido e a melhor escolha para quase toda a gente.*

- **Baseado em regras** atribui cada amostra a exatamente uma situação. Previsível, mas salta de amostra em amostra entre « urbano » e « autoestrada » quando circula perto da fronteira — por volta dos 60 km/h, por exemplo.
- **Fuzzy** reparte cada amostra por todas as situações consoante o grau de pertença. Suave precisamente onde o modo de regras salta, ao custo de ser mais difícil de seguir amostra a amostra.

### Os botões de reposição — e o que fazem de facto

- **Repor o rendimento volumétrico** descarta o η_v aprendido e restaura o valor por omissão 0,85. η_v é um parâmetro do modelo speed-density que estima o caudal de ar sem medidor. Reponha-o só após uma intervenção mecânica; um número estranho é mais vezes um problema de cobertura. Os carros que publicam o caudal diretamente (PID 5E) não o usam de todo.
- **Repor a partir da base de veículos** recarrega cilindrada, potência e valores por omissão do catálogo integrado, descartando os seus valores manuais.
- **Repor a referência por situação** (no cartão de referência) apaga cada amostra aprendida e devolve-o aos valores de arranque a frio até novas viagens encherem o perfil.

Nenhum deles toca no **ganho de bomba**, aprendido das janelas de depósito cheio a cheio e residente fora do modelo OBD2 — ver Como funciona o Sparkilo → Como um litro se torna um número.

---

## Lembretes de manutenção

No fim do editor de veículo: predefinições de **mudança de óleo (15 000 km)**, **pneus (20 000 km)** e **inspeção (30 000 km)**, mais lembretes próprios. Contam sobre as quilometragens que introduz com os abastecimentos: só avançam se anotar o conta-quilómetros — que é o que a calibração precisa de qualquer forma. Um hábito, dois benefícios.

---

## Gravação automática

Com um adaptador emparelhado, a gravação pode dispensá-lo por completo:

- **Emparelhamento automático** — o primeiro emparelhamento manual cria a associação adaptador ↔ veículo.
- **Ligação automática** — assim que o sistema vê o adaptador emparelhado a emitir, a aplicação volta a ligar em segundo plano.
- **Início automático** — ligado e acima do limiar de velocidade, a viagem começa.
- **Gravação automática ao parar** — o adaptador perde alimentação com a ignição, e após o atraso configurado a viagem é finalizada e guardada.

A gravação automática exige a permissão de localização **« Permitir sempre »**, porque o Android só deixa um serviço em segundo plano emitir GPS com ela. Essa permissão serve só para isso; a pesquisa e a centragem do mapa usam a permissão normal em primeiro plano.

> **Nota de plataforma.** A gravação automática está verificada em **Android**. No iOS o despertar de sistema necessário a « ligar assim que o adaptador arranca » ainda não existe ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); no iOS as viagens iniciam-se à mão.

Os limiares (velocidade de arranque, atraso de gravação após desligar) estão no editor de veículo: um carro de trajetos curtos pode disparar de forma diferente de um de todos os dias.

---

<details>
<summary>Vista completa — editor de veículo, página inteira</summary>

</details>

---

**Ver também:** Viagens e eco-coaching · Resolução de problemas → OBD2
**Seguinte:** Registo de abastecimentos e consumo →

---

# Viagens e eco-coaching

O separador 🛣️ **Viagens** é um diário de bordo automático mais um treinador de condução. Aparece no modo **Completo**.

---

## O separador Viagens

*Totais do mês, o último relatório do depósito, e depois a lista de viagens. O botão flutuante inicia uma gravação.*

A comparação mensal exige pelo menos três viagens por mês antes de comparar — com menos, a média é ruído, não tendência.

*O ícone de mapa da barra desenha cada viagem gravada num só mapa — um ano de condução num relance, e uma forma fácil de detetar as rotas que vale a pena otimizar.*

---

## Duas formas de gravar

### Só com o telemóvel

Sem hardware. A aplicação regista rota, distância, duração e velocidade por GPS, e **modela** o consumo a partir da calibração do veículo e da sua condução. Assinalado em todo o lado com `~` e uma nota explícita de « estimativa GPS ».

A precisão começa má e melhora: cada janela de abastecimento fechada volta a ancorar o modelo à bomba, pelo que ao fim de um punhado de depósitos cheios uma viagem só com GPS costuma ficar dentro de alguns pontos percentuais. Até lá é rotulada como preliminar, não maquilhada.

### Com um adaptador OBD2

Dados do motor em vez de dedução: caudal real (medido onde o carro publica o PID 5E), rotação, carga, acelerador. Sem período de aprendizagem para o consumo, e o coaching acede a sinais que o GPS não vê — mudança, rotações, carga do motor. A configuração está em Veículos e OBD2.

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

*O resumo declara a sua própria proveniência — veículo, adaptador, e um distintivo **Rasto GPS** na distância para saber de onde vêm os quilómetros.*

*A rota está colorida por eficiência — verde abaixo de 6 L/100 km, âmbar até 10, vermelho acima. Onde foi parar o combustível, geograficamente.*

Essa coloração é a vista mais acionável da aplicação: põe num mapa os troços caros do seu trajeto diário. Um troço vermelho que se repete todos os dias é um cruzamento, uma subida ou um hábito que vale a pena mudar.

*Três blocos: o seu veredicto, a atribuição do combustível, e como solicitou realmente o motor.*

- **« Como correu esta viagem? »** — *Suave / Moderado / Agressivo*. A sua resposta serve para calibrar os limiares de estilo de condução com viagens reais, não para lhe dar nota.
- **Onde foi o seu combustível** — litros atribuídos a acelerações fortes face à condução normal. Números absolutos pequenos numa viagem curta; o que conta é a proporção.
- **Posição do acelerador** e **rotação do motor** como distribuições — a parte da viagem em ponto morto, carga leve, firme e a fundo, e em cada faixa de rotação. Uma parte alta acima das 3000 rpm no trajeto para o trabalho significa que engrena tarde demais, e isso custa.

*Dois diagnósticos: quão completo é o rasto GPS e como se portou o adaptador.*

*Expandido, o cartão OBD2 explica-se em claro.*

**Leia este cartão antes de duvidar de um número de consumo.** Indica quantas medições traziam dados do motor, a **percentagem de cobertura** resultante, o adaptador e o protocolo negociado, a duração da sessão, porque é que terminou (`userStopped`, uma desligação, uma morte do processo), e a linha decisiva: *« Os valores de consumo vêm do adaptador, não de estimativas GPS. »* Se a cobertura estiver bem abaixo de 100 %, as falhas foram preenchidas com estimativas GPS e a média da viagem é uma mistura.

*Velocidade, caudal e rotação num eixo de tempo comum — as três curvas que explicam qualquer número de consumo.*

*Carga do motor e acelerador lado a lado mostram a diferença entre fazer o motor trabalhar e limitar-se a fazê-lo subir de rotações.*

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

*Definições → Condução e consumo. Conquistas e pontuações podem ser escondidas em toda a aplicação se a gamificação não for consigo.*

---

## O painel de carbono

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

</details>

---

**Ver também:** Veículos e OBD2 · Registo de abastecimentos e consumo
**Seguinte:** Histórico e previsões de preços →

---

# Privacidade, dados e sincronização

As promessas de privacidade do Sparkilo são verificáveis, e esta é a página onde as verifica.

---

## Privacidade por omissão

Em concreto:

- **Sem Google Play Services. Sem Firebase. Sem Google Analytics. Sem identificadores publicitários.**
- **Sem SDK de rastreio de terceiros** — o `pubspec.yaml` público não tem dependências de analítica.
- **Sem conta necessária.** A aplicação é plenamente funcional sem ela.
- **Local-first.** Tudo fica no telemóvel até ativar algo.
- **Consentimento antes do tratamento**, mais uma explicação em linguagem clara *antes* de cada pedido do sistema.
- **Código aberto, MIT.** Os próprios testes do projeto falham se a política e o código divergirem.

### O que sai realmente do telemóvel

| Dado | Para quem | Quando | Evitável? |
|---|---|---|---|
| Coordenadas de pesquisa ou código de região | O fornecedor oficial do seu país | Em cada pesquisa em direto | Pesquisar por código postal em vez de GPS |
| Área do mapa + IP | O proxy UE de mosaicos do programador, que obtém do OpenStreetMap | Uso do mapa | Desligar o proxy — o OpenStreetMap passa a ver o seu IP diretamente |
| O seu IP | logo.clearbit.com | Só se ativar os logótipos online | Deixar desligado (omissão) |
| Rastos de falha expurgados | Sentry | Só com *Relatório de erros* ativado | Desligado por omissão |
| As suas linhas sincronizadas | A base TankSync que escolheu | Só com TankSync ativo | Desligado por omissão |

**A sua identidade nunca faz parte de um pedido de preços**, e o programador não opera qualquer servidor que guarde as suas pesquisas.

---

## Quem é o responsável pelo tratamento

Depende inteiramente de como usa o TankSync:

| Modo | Responsável |
|---|---|
| **Sem TankSync** *(omissão)* | **Só você.** Nada reside em qualquer servidor operado pelo programador |
| **O seu projeto Supabase** | **Você** — o programador nunca o vê |
| **A base de um grupo** | **O proprietário do grupo** que opera esse projeto |
| **Sparkilo Community** | **O programador, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. é subcontratante; alojado na UE (AWS eu-central-1, Frankfurt) |

A aplicação indica o caso aplicável **antes** de ligar, e de novo na linha *Modo de sincronização* de **Sincronização e conta**.

---

## O ecrã Privacidade e dados

**Definições → Privacidade e dados** é o único ponto de entrada. Abre com um cartão de resumo seguido de quatro mosaicos de tópico:

| Linha ou mosaico | O que lhe diz |
|---|---|
| *Os seus dados ficam neste dispositivo* / *Os seus dados são também sincronizados com o TankSync* | Onde os seus dados vivem fisicamente neste momento |
| *Sincronização: desligada* / *Sincronização: ligada · conta anónima* / *Sincronização: ligada · conta de e-mail* | Se o TankSync está ligado, e com que tipo de conta |
| *… armazenados neste dispositivo* | O armazenamento total que a aplicação usa atualmente |
| **As suas escolhas** — *n de 5 ativadas* | Os cinco consentimentos e os dois controlos de rede |
| **Dados neste dispositivo** — *tamanho · n categorias* | Cada categoria guardada localmente, com tamanho e contagem |
| **Sincronização e conta** | Estado do TankSync, conta, base de dados e as ações de sincronização |
| **Exportar ou eliminar** — *ZIP, JSON, CSV · registo de erros (n)* | As exportações, o registo de erros e a zona de perigo |

O antigo *Painel de privacidade* deixou de existir: os seus contadores, factos de sincronização, exportações e botão de apagamento vivem agora sob estes quatro tópicos. As ligações antigas e os widgets do ecrã inicial que apontavam para o painel abrem antes **Privacidade e dados**.

---

## As suas escolhas

*Os dois controlos de rede, cada um descrito pelo que realmente deixa sair. Os cinco consentimentos ficam acima deles, no mesmo cartão.*

Cada linha é um interruptor — *« Pode alterar as suas preferências de privacidade a qualquer momento. »*

| Linha | O que decide |
|---|---|
| **Acesso à localização** | Encontrar postos de combustível próximos usando a sua localização. Desligado: pesquisa por código postal |
| **Relatório de erros** | Enviar relatórios anónimos de falhas para melhorar a aplicação. Desligado por omissão — nada é enviado sem ele |
| **Sincronização na nuvem** | Sincronizar favoritos e alertas entre dispositivos — o consentimento por trás do TankSync |
| **Descodificação online do VIN** | Descodificar o VIN via serviço público gratuito da NHTSA. Desligado: escreva você mesmo os dados do veículo |
| **Sincronizar gravações de viagens** | Fazer cópia de segurança das viagens OBD2 + GPS no TankSync. Fica a cinzento até a *Sincronização na nuvem* estar ativa |
| **Carregar os mosaicos do mapa através do proxy Sparkilo** | Ligado: a área do mapa e o seu endereço IP chegam ao servidor UE do programador, que obtém os mosaicos do OpenStreetMap. Desligado: os mosaicos carregam diretamente de tile.openstreetmap.org, que passa então a ver o seu IP |
| **Carregar logótipos de marcas da internet** | Desligado por omissão: mostram-se os marcadores incluídos na aplicação. Ligado: os logótipos são obtidos de logo.clearbit.com, que vê o seu endereço IP |

Os dois controlos de rede têm um botão de informação (*Saber mais*) com a explicação completa. O rodapé regista *Consentimento dado em … · versão … da política* — o registo de auditoria que o RGPD exige — e liga à **Política de privacidade** no seu idioma. Retirar um consentimento para imediatamente esse tratamento; os tratamentos anteriores continuam lícitos.

---

## Dados neste dispositivo

*Armazenamento discriminado: uma barra por categoria e, depois, uma linha por categoria com o seu tamanho, a sua contagem e um ponto na cor da barra. As categorias vazias aparecem a cinzento, não escondidas.*

As linhas sob **Utilização de armazenamento neste dispositivo**: **Favoritos** · **Avaliações de postos** · **Perfis de pesquisa** · **Alertas de preço** · **Postos com histórico de preços** · **Postos ignorados** · **Utilizadores bloqueados** · **Rotas guardadas** · **Cache** · **Definições** (*Chave API, perfil ativo*) · **Total**.

Tudo reside em **bases Hive cifradas**; a chave está no Android Keystore / Porta-chaves do iOS.

| Caixa | Conteúdo |
|---|---|
| `settings` | Configuração, país, idioma, unidades |
| `profiles` | Os seus perfis de pesquisa |
| `favorites` | Postos guardados com todos os seus dados |
| `cache` | Respostas de API e itinerários em cache |
| `priceHistory` | Os registos locais de preços de 30 dias |
| `price_snapshots` | Instantâneos para uso offline e para o widget |
| `alerts` | As suas regras de alerta |
| `service_reminders` | Lembretes de manutenção |
| `obd2Baselines` | Referências de consumo por veículo |
| `obd2TripHistory` | Viagens: rota, velocidade, sensores |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Caches das capacidades do adaptador |

As chaves API, o token do GitHub e a sessão TankSync vivem no cofre de hardware, não no Hive.

### Detalhes da cache

*O mosaico **Detalhes da cache** expande-se para mostrar o tempo de vida de cada classe em cache — pesquisas 5 min, detalhes de postos 15 min, consultas de preços 5 min, dados de favoritos 30 min, pesquisas de cidades 30 min, geocodificação de códigos postais 24 h — e o botão **Limpar cache**.*

A cache guarda respostas de API para carregamentos mais rápidos e acesso offline. Limpá-la apaga apenas resultados e preços em cache — perfis, favoritos e definições ficam intactos; as pesquisas seguintes são mais lentas, nada se perde. O botão indica *A cache está vazia* e fica desativado quando não há nada a limpar.

### Utilizadores bloqueados

**Utilizadores bloqueados** é a única linha tocável: abre a lista das contas que bloqueou, cada uma com um botão **Desbloquear**. O conteúdo partilhado por estes utilizadores fica escondido neste dispositivo; o bloqueio é local — não denuncia a conta.

---

## Permissões

| Permissão | Para quê | Recusável? |
|---|---|---|
| **Localização** *(durante a utilização)* | Pesquisa por perto, início de itinerário, gravação | Sim — usar um código postal |
| **Localização** *(« Permitir sempre »)* | **Só** a gravação automática OBD2, para a rota continuar com o ecrã apagado | Sim — iniciar as viagens à mão |
| **Pesquisa + ligação Bluetooth** | Emparelhamento do adaptador | Sim — o OBD2 é opcional |
| **Notificações** | Alertas de preço | Sim — os alertas não disparam |
| **Câmara** | OCR no dispositivo de bombas, talões e QR | Sim — escrever à mão |
| **Internet** | Chamadas de preços e mapa | Necessária |

Até ao Android 11 o sistema exige a **localização** para qualquer varredura Bluetooth — regra da plataforma, não uma decisão de rastreio. Qualquer permissão pode depois ser revogada nas definições do sistema; a funcionalidade correspondente simplesmente para.

---

## Sincronização e conta

*Acessível a partir do mosaico Privacidade e dados e diretamente da raiz das Definições. O ecrã também expõe problemas — aqui um esquema auto-alojado desatualizado, que por isso falha em silêncio a sincronização de algumas tabelas.*

Mediante ativação. *Desativado* significa que nada é guardado em servidor algum, em lado algum. O cartão de resumo no topo enuncia os factos:

| Linha | Valor |
|---|---|
| **Estado** | *Ligado* ou *Desativado* |
| **Modo de sincronização** | *Comunidade Sparkilo — o servidor da UE do programador* · *Grupo partilhado — uma base de dados a que aderiu* · *Auto-alojado — o seu próprio Supabase* |
| **Conta** | *Conta anónima, associada a este dispositivo* ou *Conta de e-mail: …* |
| **ID de utilizador** | O seu UUID, com um botão de cópia — cite-o num pedido de apoio |
| **Anfitrião da base de dados** | O nome do anfitrião da base de dados com que sincroniza; a chave nunca é mostrada |
| **Partilhar perfis aprendidos do veículo** | Envia as referências de consumo por veículo para que um segundo dispositivo as possa reutilizar |

### Três formas de implantação

1. **Sparkilo Community** — a base partilhada operada pelo programador (Supabase, UE/Frankfurt). A sua conta é um UUID aleatório; pode associar um e-mail para lhe aceder de outro dispositivo. Os relatos comunitários e as avaliações partilhadas publicamente são legíveis por qualquer utilizador autenticado.
2. **O seu projeto Supabase** — o esquema SQL e as Edge Functions estão no repositório. É você o responsável e mantém a propriedade plena.
3. **A base de um grupo** — ligue-se ao projeto de familiares ou amigos. Essa pessoa é a responsável.

### Configuração

**Sincronização e conta → Configurar sincronização na nuvem.** Para Community, leia o QR do wiki ou cole URL e chave anon; para um projeto próprio ou de grupo, cole URL do projeto e chave anon. Ambos ficam no cofre de hardware, e os endpoints em HTTP simples são recusados.

> **Quem se auto-aloja:** após uma atualização o ecrã pode avisar que o seu **esquema está desatualizado**. Volte a correr o SQL de instalação oferecido — caso contrário a sincronização das novas tabelas falha **em silêncio**, o que é bem pior do que um erro visível.

### Ações uma vez ligado

- **Mudar para e-mail** — mantém os dados e acrescenta o início de sessão a partir de outros dispositivos; o UUID não muda. **Mudar para anónimo** faz o inverso.
- **Consentimentos** — uma ligação cruzada para *As suas escolhas*: os consentimentos de Sincronização na nuvem e de viagens vivem lá, não aqui.
- **Ver os meus dados** — o ecrã *Transparência de dados* lista as linhas que o servidor guarda sobre si; o seu botão **Esquecer todas as viagens sincronizadas** limpa só as linhas de viagens.
- **Ligar dispositivo** — traga um segundo telemóvel para a mesma conta.
- **Eliminar dados sincronizados** — escolha *Viagens*, *Veículos*, *Abastecimentos* ou *Tudo* para os remover da base de sincronização; as cópias locais ficam.
- **Partilhar base de dados** — um código QR para que familiares ou amigos entrem na sua base ou na de um grupo (não oferecido na Community).
- **Desligar** — deixa de sincronizar; os dados locais são mantidos.
- **Eliminar conta** — remove permanentemente todos os dados do servidor e, depois, a própria identidade da conta, e-mail associado incluído. Oferecido para bases próprias e de grupo; na Community use *Eliminar dados sincronizados → Tudo* ou a zona de perigo descrita abaixo.

### O que é sincronizado

Favoritos · alertas de preço · postos ignorados · avaliações (com indicador de privacidade por avaliação: local / privada sincronizada / partilhada publicamente) · itinerários · veículos incluindo VIN e identificador do adaptador · abastecimentos e registos de carregamento · referências de consumo · relatos comunitários e de conteúdo que submeta.

**As viagens são à parte.** A sua sincronização continua opcional *mesmo depois* de ativar a Sincronização na nuvem — o interruptor *Sincronizar gravações de viagens* fica a cinzento até lá. No servidor os resumos ficam até os apagar; as amostras GPS detalhadas são purgadas ao fim de 90 dias.

Cada tabela é protegida por segurança ao nível da linha: uma conta só pode ler ou apagar as suas próprias linhas. As avaliações partilhadas e os relatos comunitários são as únicas linhas visíveis a outros utilizadores autenticados.

### Conflitos

**O local ganha sempre.** A sincronização acrescenta e atualiza, mas nunca apaga em silêncio — só o seu apagamento explícito provoca um apagamento no servidor, que depois se propaga aos seus outros dispositivos.

---

## Exportar ou eliminar

Um botão, uma folha de formatos, uma zona vermelha. **Exportar os meus dados** abre *Escolha um formato*:

| Formato | Dica na folha | O que obtém |
|---|---|---|
| **Arquivo ZIP** | *Tudo, anexos incluídos — para uma cópia de segurança completa* | `sparkilo-my-data-<date>.zip`: um JSON legível por máquina por categoria — favoritos, alertas, perfis, rotas, histórico de preços, veículos, abastecimentos, viagens com amostras GPS e um GPX por viagem, referências, lembretes de manutenção, registos de carregamento, conquistas e o seu registo de consentimento — mais cada tabela do servidor se o TankSync estiver ligado |
| **JSON** | *Legível por máquina — para outra aplicação* | `tankstellen-data.json`: as categorias do dispositivo num único ficheiro plano, também copiado para a área de transferência |
| **CSV** | *Folha de cálculo — uma tabela por categoria* | `tankstellen-data.csv`: um bloco `# table` por categoria — favoritos, alertas, histórico de preços e os restantes — também copiado para a área de transferência |

Todas as exportações vão para a pasta **pública de Transferências** (*Guardado na pasta Transferências*), para que qualquer gestor de ficheiros as encontre.

**Registo de erros** mostra quantos rastos expurgados a aplicação guarda (*Sem entradas* … *n entradas*). **Guardar** escreve-os nas Transferências para um relatório de erro — sem e-mails, coordenadas, chaves ou tokens, e nada é enviado automaticamente; **Limpar** esvazia o registo.

**Zona de perigo** — *Elimina permanentemente tudo o que a aplicação armazena neste dispositivo. Com a sincronização ligada, os seus dados no servidor TankSync são igualmente apagados.* **Eliminar todos os meus dados** pede confirmação e lista o que desaparece: favoritos e dados de postos, perfis de pesquisa, alertas de preços, histórico de preços, dados em cache, a sua chave de API, todas as definições da aplicação. Com o TankSync ligado apaga primeiro as suas linhas no servidor; se alguma tabela não puder ser apagada, a aplicação **diz-lhe qual** em vez de proclamar sucesso. A aplicação regressa depois à configuração de primeiro arranque. Irreversível.

Para um instantâneo restaurável em vez de uma exportação de dados, use **Definições → Cópia de segurança e restauro** — ver Referência de definições.

---

## Os seus direitos ao abrigo do RGPD

Cada direito dos artigos 15.º a 22.º tem um botão. Sem necessidade de pedido de apoio.

- **Acesso** — *Dados neste dispositivo* lista cada categoria no dispositivo; *Ver os meus dados* lista cada linha da sua base TankSync.
- **Portabilidade** — *Exportar os meus dados* em arquivo ZIP.
- **Retificação** — edite qualquer entrada no local; a alteração sincroniza se o TankSync estiver ativo.
- **Apagamento**
  - *Dispositivo:* **Exportar ou eliminar → Eliminar todos os meus dados**.
  - *Servidor:* **Sincronização e conta → Eliminar conta** apaga cada linha sua **numa transação** — favoritos, alertas, postos ignorados, relatos de preço e conteúdo, veículos, abastecimentos, itinerários, referências, avaliações, viagens, partilhas de viagem dadas e recebidas, definições de sincronização, registos de apagamento e a sua linha de utilizador — e depois a própria identidade da conta, e-mail associado incluído. Se alguma tabela não puder ser apagada, a aplicação **diz-lhe qual** em vez de proclamar sucesso.
  - *Itens isolados:* tudo é apagável individualmente; **Eliminar dados sincronizados** remove viagens, veículos ou abastecimentos do servidor, e **Esquecer todas as viagens sincronizadas** limpa só as linhas de viagens.
- **Retirada do consentimento** — Privacidade e dados → As suas escolhas; o tratamento cessa de imediato.
- **Limitação / oposição** — desligue o TankSync, a sincronização de viagens, o proxy de mosaicos ou os diagnósticos; revogue permissões nas definições do sistema.
- **Reclamação** — junto de uma autoridade de controlo, em particular a da sua residência, local de trabalho ou da alegada infração. O programador gostaria de poder resolver primeiro: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

Se já não conseguir abrir a aplicação, peça o apagamento por e-mail a partir do endereço associado à conta. **Uma conta anónima nunca associada a um e-mail não pode ser identificada por ninguém — nem pelo programador — sem o dispositivo que a criou.** É o preço de não lhe pedirem registo.

Texto integral: **[Política de privacidade v3, 29 de agosto de 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**, disponível nos 23 idiomas da aplicação. A aplicação regista a que versão consentiu e volta a mostrá-la sempre que mudar.

---

**Ver também:** Referência de definições · Como funciona o Sparkilo → Onde vivem os seus dados
**Seguinte:** Resolução de problemas e FAQ →

---

# Referência de definições

Cada ecrã da árvore de definições e — mais útil — **quanto lhe custa cada interruptor** em bateria, dados, precisão ou privacidade.

---

## A forma do conjunto

As definições são uma **árvore de dois níveis**: uma raiz de mosaicos temáticos, um ecrã por tema, e uma pesquisa por palavra-chave sobre todos.

*Escreva « raio », « OBD2 » ou « tema » no campo de pesquisa e o mosaico certo aparece — não é preciso lembrar-se de que tema detém um parâmetro.*

*Doze temas no total. Para lá chegar: a engrenagem no canto superior direito dos ecrãs principais.*

Três regras de desenho tornam a árvore previsível:

1. **Uma casa por parâmetro.** Nada aparece duas vezes; as remissões apontam para o único dono.
2. **Etiquetas de âmbito.** Um mosaico marcado *este perfil*, *todos os perfis* ou *este veículo* diz de antemão até onde vai uma alteração.
3. **Estados vazios honestos.** Uma secção com a funcionalidade desligada di-lo e liga ao interruptor, em vez de se esconder.

---

## Perfis e região

*País, idioma, combustível, raio de pesquisa, itinerários · âmbito: este perfil*

*O combustível preferido é derivado do veículo predefinido. Para o escolher diretamente, retire o veículo do perfil.*

| Definição | Impacto |
|---|---|
| **Nome do perfil** | Cosmético, mas é o que o chip de perfil mostra |
| **Combustível preferido** | O preço em destaque em cada cartão; o predefinido dos alertas; para o que a pesquisa de itinerário otimiza |
| **Raio predefinido** | Maior = mais resultados e pesquisas mais lentas |

*Valores predefinidos do itinerário. **Candidatos por ponto de amostragem** troca minúcia por velocidade em corredores longos.*

*Três coisas distintas que convém conhecer.*

- **Evitar autoestradas** muda o próprio itinerário calculado: as áreas de serviço deixam de ser candidatas — em geral uma poupança, já que o combustível de autoestrada é o mais caro de qualquer corredor.
- **Notas dos postos** — *Local* (só este dispositivo), *Privado* (sincronizado na sua conta) ou *Partilhado* (visível a outros utilizadores). É uma decisão de privacidade, não de armazenamento.
- **Ecrã inicial** — com o que a aplicação abre: Por perto, Posto mais próximo, Favoritos ou Mapa.

*O raio do overlay e a regra **mais próximo vs mais barato do raio** vivem no perfil: um perfil « diário » e um « férias » podem comportar-se de forma diferente.*

*O país decide o fornecedor de dados. Alterá-lo esvazia os dados de postos em cache.*

*Um **código postal de casa** permite pesquisas por zona sem qualquer GPS — a forma mais limpa de usar a aplicação se nunca quiser partilhar a sua localização.*

---

## Veículos e OBD2

*Os seus carros, capacidade do depósito, emparelhamento · âmbito: este veículo*

*Os adaptadores emparelham-se por veículo: o mosaico do adaptador leva-o para dentro de um veículo em vez de um ecrã global.*

O tratamento completo — VIN, capacidade, flex-fuel, modos de calibração, referência, limiares de gravação automática, lembretes — está em Veículos e OBD2.

---

## Condução e consumo

*Coaching, recompensas, radar, resolução de problemas · âmbito: misto*

*As duas primeiras entradas são as que vai mesmo afinar.*

| Definição | Impacto |
|---|---|
| **Janela de consumo em direto** (3/5/10/30 s) | Mais longa = mais estável e legível ao volante; mais curta = reativa o bastante para ensinar quanto custa o pedal |
| **Overlay ao aproximar-se** | Raio, modo de preço, piso de consulta e fixação de ecrã para o perfil ativo |
| **Coaching eco em tempo real** | Vibração ligeira + conselho no ecrã ao acelerar com força em velocidade de cruzeiro |
| **Coaching de voz** | O mesmo conselho lido em voz alta — os olhos ficam na estrada |
| **Glide-coach beta** | Aviso tátil antes de um vermelho a partir dos semáforos do OpenStreetMap. **Desligado por omissão — risco de distração**, e precisa de rede |

*Recompensas e resolução de problemas.*

- **Cartões de fidelização** — descontos por litro aplicados nas comparações de preço, para que um posto nominalmente mais caro possa aparecer corretamente como mais barato para si.
- **Mostrar conquistas e pontuações** — desligado, distintivos, pontuações e troféus desaparecem de toda a aplicação. Nada deixa de ser medido; deixa de ser mostrado.
- **Registo de depuração OBD2** — grava cada sessão (ligação, handshake, perdas de dados, reconexões) num registo XML exportável. **Desligado por omissão**: escreve continuamente e só compensa enquanto se persegue um problema do adaptador.

---

## Preços e alertas

*Alertas, anúncios de voz, histórico, relatos comunitários*

*O bloco cinzento dos anúncios de voz é um estado vazio honesto: nomeia os dois interruptores necessários e onde estão.*

| Definição | Impacto |
|---|---|
| **Alertas de preço** | Abre a lista; a funcionalidade é um interruptor em Funcionalidades e modo de utilização |
| **Histórico de preços** | Registo local de 30 dias. Desligado = sem gráficos, sem « melhor momento » |
| **Previsão de preços TFLite** | Modelo no dispositivo; características e previsões nunca saem do telemóvel |
| **Relatos de preço comunitários** | Requer TankSync; os seus relatos são visíveis a outros utilizadores autenticados |
| **Ler o QR de pagamento** | Acrescenta o leitor de QR ao detalhe dos postos |

---

## Unidades e apresentação

*Tema, unidade de distância, unidade de consumo, widget · âmbito: misto*

*A **unidade de consumo** propaga-se a todo o lado de uma vez — faixa em direto, miniatura, médias de viagem, estatísticas, widget.*

- **Unidade de distância** segue por omissão o país do perfil ativo (km ou milhas).
- **Unidade de consumo**: *Automático* (mpg no Reino Unido e EUA, L/100 km no resto), ou explicitamente L/100 km, km/L ou mpg.

*As escolhas do widget trazem a etiqueta **este perfil** e aplicam-se a todos os widgets instalados que mostrem esse perfil, a partir da próxima atualização.*

**Variante de conteúdo** — *só preço atual*, ou *preditivo: melhor momento para abastecer* (requer a previsão TFLite).

---

## Funcionalidades e modo de utilização

*Predefinições e cada interruptor individual*

*Escolher uma predefinição **sobrepõe-se** a cada interruptor individual. Se afinou à mão, fique em Personalizado.*

As dependências são aplicadas, não escondidas: um interruptor com o pré-requisito desligado fica desativado e nomeia esse pré-requisito.

*Pesquisa e mapa — incluindo se postos e pontos de carregamento aparecem sequer.*

*Preços e alertas. O histórico é a funcionalidade-mãe da previsão que se lhe segue.*

*O radar, os seus anúncios de voz e o interruptor principal **Retorno falado** — desligado, a aplicação nunca abre um motor de síntese.*

*O seletor **Desligado / Combustível / Combustível + Viagens** é a forma compacta de toda a pilha de consumo.*

| Interruptor | Impacto |
|---|---|
| **Estatísticas de consumo** | O separador de análise de abastecimentos e viagens |
| **Gamificação** | Pontuações de condução e distintivos ganhos |
| **Eco-coach tátil** | Retorno vibratório em tempo real ao volante |
| **Glide-coach** | Conselhos eco a partir dos semáforos do OpenStreetMap — precisa de rede |
| **Rasto GPS das viagens** | Guarda os pontos de rota de cada viagem. Desligado = base mais pequena, sem mapas de viagem |
| **Gravação automática** | Inicia uma viagem quando o adaptador emparelhado se liga a um veículo em movimento |

*Dois interruptores aqui mudam a qualidade dos dados em vez da interface.*

- **PID OEM experimentais** — lê o nível exato do depósito em litros através de PID do fabricante em adaptadores compatíveis. Melhores dados onde funciona; inofensivo onde não.
- **Exigir OBD2 para a gravação de viagens** — **desligado**, as viagens gravam-se só com GPS. O coaching é reduzido (sem L/100 km instantâneos, menos sinais do motor) mas nada fica bloqueado.
- **Sincronização de referências** — envia as referências de consumo por veículo para um segundo dispositivo as reutilizar. Requer TankSync.

*Introdução e digitalização. O reconhecimento é no dispositivo; estes interruptores só decidem se os atalhos existem.*

*Programador e experimental — pode ficar desligado a menos que reporte erros.*

---

## Fontes de dados e localização

*Chaves API, GPS, mudança automática de perfil*

*Uma cruz vermelha na chave de preços é a razão habitual de uma pesquisa alemã vazia.*

| Definição | Impacto |
|---|---|
| **Preços de combustível (Tankerkoenig)** | Necessária só para a Alemanha. Gratuita, por utilizador, no cofre de hardware |
| **Carregamento EV (OpenChargeMap)** | Opcional — substitui a chave partilhada pela sua própria quota |
| **Atualização automática** | Atualiza a posição GPS antes de cada pesquisa. Desligado = pesquisas mais rápidas, posição talvez antiga |
| **Mudança automática de perfil** | Comuta o perfil ao atravessar uma fronteira, para que fornecedor e combustível fiquem corretos automaticamente |

---

## Sincronização e conta

*Este ecrã também revela problemas — aqui um esquema TankSync auto-alojado desatualizado que, por isso, falha em silêncio a sincronizar algumas tabelas.*

Tratado em detalhe em Privacidade, dados e sincronização → TankSync. O essencial:

- **Sparkilo Community / a sua própria base / a base de um grupo** — três formas de implantação com três responsáveis diferentes.
- **Anónimo → e-mail** — *Passar ao e-mail* conserva os seus dados e a conta e acrescenta uma forma de iniciar sessão a partir de outro dispositivo. Uma conta anónima só existe no dispositivo que a criou.
- **Esquema desatualizado** — após uma atualização, quem se auto-aloja tem de voltar a correr o SQL de instalação, ou as tabelas novas falham em silêncio.

---

## Privacidade e dados

*Duas decisões de privacidade ligadas à rede, cada uma formulada pelo que realmente revela.*

- **Carregar os mosaicos pelo proxy Sparkilo** — *ativado*: o servidor UE do programador vê a área do mapa e o seu IP e obtém os mosaicos por si. *Desligado*: os mosaicos vêm de tile.openstreetmap.org, que passa a ver o seu IP. Nenhuma opção significa « sem rede »; escolhe por quem ser visto. A versão F-Droid nunca usa o proxy.
- **Carregar os logótipos das marcas da Internet** — *desligado* por omissão; usam-se logótipos genéricos incluídos. Ativado, vêm de logo.clearbit.com, que vê o seu IP.

*O armazenamento, discriminado. A cache é quase sempre a maior fatia e a única que se pode deitar fora sem risco.*

*Gestão da cache, com a duração de cada classe: pesquisas 5 min, detalhes de posto 15 min, consultas de preço 5 min, dados de favoritos 30 min, pesquisas de cidade 30 min, geocodificação de código postal 24 h.*

*Limpar a cache apaga apenas resultados e preços guardados — perfis, favoritos e definições mantêm-se. As pesquisas seguintes serão mais lentas; nada se perde.*

---

## Cópia de segurança e restauro

*Um ZIP completo com veículos, abastecimentos, viagens e registos de carregamento.*

**Exportar cópia** escreve o ZIP nas suas Transferências. **Restaurar cópia** oferece *fundir* ou *substituir* — fundir mantém o que está no dispositivo e acrescenta o que falta; substituir apaga primeiro. Use-o antes de mudar de telemóvel ou de uma reposição de fábrica. O TankSync não é uma cópia de segurança: replica categorias escolhidas, não tudo.

---

## Avançado e programador

*O token do GitHub é opcional — sem ele, um relato de leitura falhada partilha-se à mão em vez de abrir automaticamente uma questão.*

A entrada **Ferramentas de programador** só aparece com o modo programador ativo (Funcionalidades e modo de utilização → Programador e experimental).

*Para um utilizador comum o registo de erros é a parte útil: **Guardar o registo de erros** escreve rastos expurgados nas Transferências, para anexar a um relatório.*

*O rasto de arranque é uma cascata das fases de inicialização — é assim que um arranque lento se diagnostica em vez de se adivinhar.*

***Testar o overlay de aproximação** força um estado sintético durante 30 s para verificar a apresentação do preço sobreposto sem sair a conduzir.*

---

## Acerca

***Versão e número de compilação** — cite ambos em qualquer relatório, e verifique-os primeiro quando uma correção « não funcionou » (o lançamento na loja pode ainda não o ter alcançado).*

*A aplicação é gratuita, de código aberto e sem publicidade. As atribuições dos dados de preços e de mapa estão no fim, como as licenças exigem.*

---

**Ver também:** Como funciona o Sparkilo · Privacidade, dados e sincronização
**Seguinte:** Privacidade, dados e sincronização →

---

# Resolução de problemas e FAQ

Ordenado aproximadamente por frequência real.

---

## Antes de tudo: verifique a sua versão

*Definições → Acerca. Cite **ambos** em qualquer relatório.*

Boa parte dos « continua a não funcionar » é um lançamento na loja que ainda não chegou ao dispositivo. Se o número de compilação for anterior à versão com a correção, não há nada para depurar.

---

## « Nenhum preço encontrado »

1. **Verifique o país do perfil.** Um perfil alemão chama a API alemã; em Portugal não encontrará nada. Definições → Perfis e região → Região.
2. **Alemanha: a chave API está definida?** Definições → Fontes de dados e localização — uma cruz vermelha em *Preços de combustível (Tankerkoenig)* é a resposta.
3. **Está offline?** Os preços em direto exigem uma chamada de rede. Os preços em cache continuam visíveis, marcados como antigos.
4. **Falha do fornecedor.** Os serviços públicos de dados abertos caem por vezes. Tente de novo daqui a alguns minutos.
5. **Cache antiga.** Puxe para atualizar, ou toque no ícone de atualização.

---

## Alemanha: « Falta a chave API » ou « Chave inválida »

- Obtenha uma chave gratuita em [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); é um UUID.
- Cole-a em **Definições → Fontes de dados e localização → Preços de combustível (Tankerkoenig)**.
- Continua a falhar? A chave pode estar limitada. As chaves são pessoais — nunca as publique.

---

## Não encontro o botão de pesquisa

Só existe um: o botão verde elevado ao centro da barra inferior. A partir de qualquer separador abre a folha de critérios; dentro da folha, um segundo toque executa a pesquisa. Se parecer esbatido, está em **modo itinerário sem destino**.

---

## A localização é « desconhecida » ou o GPS não fixa

- A localização do sistema tem de estar ligada, com **Durante a utilização** concedido à aplicação.
- O GPS não fixa dentro de casa. Vá lá fora, ou defina um **código postal de casa** no perfil e pesquise por zona.
- « Só localização aproximada » — ative a localização precisa nas permissões do sistema.

---

## O cálculo de itinerário é lento ou falha

- O OSRM é um serviço público gratuito e por vezes lento.
- Um corredor multipaís **transmite resultados parciais**; o aviso nomeia os fornecedores em falta, e pode tocar num resultado antes de os outros chegarem.
- Tente de novo — a polilinha está em cache, a segunda tentativa costuma ser imediata.

---

## O adaptador OBD2 não liga

**Não encontra nada na varredura**

- A ignição tem de estar **ligada** (acessórios ou marcha). Motor a trabalhar serve, ignição desligada não.
- O LED do adaptador deve estar aceso fixo. A piscar ou apagado → volte a ligá-lo.
- Bluetooth ligado no telemóvel.
- Android 12+: conceda **Pesquisa Bluetooth** e **Ligação Bluetooth**.
- Até ao Android 11: o sistema exige a **localização** para enumerar dispositivos Bluetooth. Regra da plataforma, não rastreio.

**Encontra, mas a ligação falha**

- *« Não responde »* — clone barato. Espere 30 s e tente de novo; arrancar brevemente o motor costuma ajudar.
- *« Falha de inicialização do protocolo »* — chip ELM327 falsificado. Experimente outro modelo; o vLinker FS é a opção barata fiável.
- *« Permissão negada »* — volte a conceder nas definições do sistema; algumas versões do Android esquecem as permissões Bluetooth após um reinício.

**Liga e depois cai em andamento**

Use **Reiniciar a ligação** no cartão do adaptador do veículo — repete o handshake sem esquecer o emparelhamento. Se persistir, ative **Definições → Condução e consumo → Registo de depuração OBD2**, faça uma viagem, exporte o registo XML e anexe-o a uma questão. Depois desligue o registo.

**O conta-quilómetros marca 0 ou está errado**

O seu carro pode não publicar o PID A6. A aplicação tenta o PID 31 e o modo 22 do fabricante. Alguns europeus anteriores a 2008 não publicam conta-quilómetros por OBD2 — escreva-o então em cada abastecimento.

---

## A gravação automática não disparou

Precisa de tudo isto:

1. Um adaptador **emparelhado a um veículo**.
2. **Gravação automática** ativa para esse veículo.
3. A permissão de localização **« Permitir sempre »**.
4. Bluetooth ligado e nenhuma otimização de bateria a matar a aplicação.

Verifique também o **limiar de velocidade de arranque** no editor de veículo — uma saída ao passo de um parque pode nunca o atingir.

> **iOS:** o despertar de sistema para « ligar assim que o adaptador arranca » ainda não existe ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). No iOS inicie as viagens à mão.

---

## O meu consumo parece errado

Siga esta ordem:

1. **Abra a viagem e leia o cartão de saúde da comunicação OBD2.** Se a cobertura estiver bem abaixo de 100 %, as falhas foram preenchidas com estimativas GPS e a média é uma mistura, não uma medição.
2. **Veja o relatório do depósito no separador Viagens.** Se disser que as estimativas estão *n* % acima ou abaixo da verdade da bomba, a aplicação já sabe e acabou de se corrigir — espere movimento nas próximas viagens.
3. **Verifique a capacidade do depósito** no veículo. Uma capacidade errada produz durante meses autonomias credíveis mas erradas.
4. **Verifique as suas quilometragens.** O consumo é litros ÷ quilómetros, e os quilómetros vêm inteiramente do que escreve.
5. **Verifique se marcou « Tanque cheio ».** Só as janelas de cheio a cheio podem calibrar seja o que for.
6. **Veja o distintivo de precisão** no separador Combustível. *Baixa* significa que nada ancorou ainda o modelo — o valor é uma saída de modelo, e di-lo.

Contexto: Como funciona o Sparkilo → Como um litro se torna um número.

---

## « Encontrámos um desvio de X litros »

Abasteceu mais do que as suas viagens gravadas explicam. Responda às duas perguntas da reconciliação: um abastecimento em falta ou mal escrito recebe uma **entrada de correção**, uma viagem não gravada recebe uma **viagem virtual**. Ambas continuam editáveis. Deixá-lo por resolver enviesa a calibração, por isso dois toques valem a pena. Ver Registo de abastecimentos e consumo.

---

## A miniatura sobreposta não mostra um preço

O overlay de aproximação só dispara enquanto **se grava uma viagem** *e* se está dentro do raio. Para verificar a apresentação sem conduzir: **Definições → Ferramentas de programador → Testar o overlay de aproximação** força um estado sintético durante 30 segundos.

---

## As notificações de alerta não chegam

- As notificações do sistema estão permitidas para a aplicação?
- Poupança de bateria: os modos agressivos do Android matam o trabalho de fundo. Ponha a aplicação em **sem restrições**.
- O telemóvel pode ter estado offline na janela prevista; a verificação retoma na próxima janela de rede.
- O preço pode simplesmente não ter cruzado o limiar.
- O carimbo **Última verificação** no fim do ecrã de alertas diz se a tarefa corre. Carimbo antigo + zero disparos = o sistema está a matá-la.

---

## O widget do ecrã inicial está parado

- O Android limita as atualizações de widget a cerca de uma a cada 30 minutos; é política do sistema.
- Toque no **ícone de atualização do próprio widget** — recarrega os preços sem abrir a aplicação.
- Aspeto e variante de conteúdo definem-se por perfil em **Definições → Unidades e apresentação**.

---

## O mapa mostra mosaicos cinzentos ou vazios

- Costuma ser uma ligação fraca; deslize para atualizar.
- Se persistir, os servidores de mosaicos podem estar a limitar — tente daqui a alguns minutos.
- Experimente comutar **Definições → Privacidade e dados → Carregar os mosaicos pelo proxy Sparkilo**; os dois caminhos falham de forma independente.

---

## A leitura de bomba ou talão não lê nada

- A versão **F-Droid** não tem qualquer leitura — o reconhecimento de texto no dispositivo só existe nas versões Play / App Store. Escreva o abastecimento à mão.
- O reflexo no visor da bomba é a causa mais comum. Faça sombra, coloque-se de frente, encha o enquadramento com os dígitos.
- Se ler as etiquetas mas não os números, use **Reportar erro de leitura** para que o recorte sirva para melhorar o reconhecimento.

---

## A aplicação demora muito a arrancar

Ative **Rasto de inicialização no arranque** (Funcionalidades e modo de utilização → Programador e experimental), reinicie e abra as **Ferramentas de programador**. A cascata nomeia a fase lenta; exporte-a e anexe-a a uma questão.

*Cada barra é uma fase de inicialização com a sua duração — um arranque lento deixa de ser uma suposição.*

---

## A aplicação falha ao arrancar

- Limpe a cache a partir das definições de aplicações do dispositivo.
- Se persistir, abra uma questão com a versão do Android, o modelo do telemóvel, a versão **e o número de compilação** de Definições → Acerca, e o registo de erros guardado (a aplicação oferece-o no arranque seguinte; o ficheiro vai para Transferências).

---

## Como faço cópia de segurança dos meus dados?

**Definições → Cópia de segurança e restauro → Exportar cópia** escreve um ZIP nas Transferências; o restauro oferece fundir ou substituir. Para uma exportação legível por máquina, use antes **Privacidade e dados → Exportar ou eliminar → Exportar os meus dados → Arquivo ZIP**.

O TankSync **não** é uma cópia de segurança — replica categorias escolhidas, e as viagens só se também tiver ativado a sua sincronização.

---

## Como apago tudo?

- **Dispositivo:** Privacidade e dados → Exportar ou eliminar → **Eliminar todos os meus dados**. Irreversível.
- **Servidor (TankSync):** apague primeiro o lado servidor — Sincronização e conta → Transparência de dados → **Eliminar conta** remove cada linha sua numa transação e nomeia qualquer tabela que não tenha sido possível apagar.

Detalhes: Privacidade, dados e sincronização → Os seus direitos.

---

## Posso usar a aplicação offline?

Em parte. Os favoritos mostram os últimos preços conhecidos, os mosaicos vistos recentemente estão em cache, e abastecimentos e viagens são inteiramente locais. Descobrir postos novos exige uma chamada de rede.

---

## Onde foi parar o separador Combustível ou Viagens?

Pertencem aos modos **Médio** e **Completo**. Se um desapareceu, uma predefinição ou um interruptor desligou-o: Definições → Funcionalidades e modo de utilização → Consumo.

---

## Mais ajuda

- **Erros:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — use o modelo Bug Report e anexe o registo de erros guardado.
- **Ideias:** o modelo Feature Request, ou primeiro as [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Dúvidas de privacidade:** a [política de privacidade](https://fdittgen-png.github.io/tankstellen/privacy-policy/), ou fdittgen@gmail.com.

---

**Voltar a:** a página inicial do guia
