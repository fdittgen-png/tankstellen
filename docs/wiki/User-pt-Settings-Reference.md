# Referência de definições

Cada ecrã da árvore de definições e — mais útil — **quanto lhe custa cada interruptor** em bateria, dados, precisão ou privacidade.

---

## A forma do conjunto

As definições são uma **árvore de dois níveis**: uma raiz de mosaicos temáticos, um ecrã por tema, e uma pesquisa por palavra-chave sobre todos.

<img src="guide/settings-root-1.jpg" width="340" alt="Raiz das definições, metade de cima: campo de pesquisa e os seis primeiros mosaicos">

*Escreva « raio », « OBD2 » ou « tema » no campo de pesquisa e o mosaico certo aparece — não é preciso lembrar-se de que tema detém um parâmetro.*

<img src="guide/settings-root-2.jpg" width="340" alt="Raiz das definições, metade de baixo: funcionalidades, fontes de dados, sincronização, privacidade, cópia, avançado">

*Doze temas no total. Para lá chegar: a engrenagem no canto superior direito dos ecrãs principais.*

Três regras de desenho tornam a árvore previsível:

1. **Uma casa por parâmetro.** Nada aparece duas vezes; as remissões apontam para o único dono.
2. **Etiquetas de âmbito.** Um mosaico marcado *este perfil*, *todos os perfis* ou *este veículo* diz de antemão até onde vai uma alteração.
3. **Estados vazios honestos.** Uma secção com a funcionalidade desligada di-lo e liga ao interruptor, em vez de se esconder.

---

## Perfis e região

*País, idioma, combustível, raio de pesquisa, itinerários · âmbito: este perfil*

<img src="guide/profile-edit-1.jpg" width="340" alt="Editor de perfil: nome, combustível preferido, raio predefinido">

*O combustível preferido é derivado do veículo predefinido. Para o escolher diretamente, retire o veículo do perfil.*

| Definição | Impacto |
|---|---|
| **Nome do perfil** | Cosmético, mas é o que o chip de perfil mostra |
| **Combustível preferido** | O preço em destaque em cada cartão; o predefinido dos alertas; para o que a pesquisa de itinerário otimiza |
| **Raio predefinido** | Maior = mais resultados e pesquisas mais lentas |

<img src="guide/profile-edit-2.jpg" width="340" alt="Planeamento de itinerário: segmento, desvio máximo, poupança mínima, escolha por segmento, candidatos">

*Valores predefinidos do itinerário. **Candidatos por ponto de amostragem** troca minúcia por velocidade em corredores longos.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Apresentação e postos, visibilidade das notas, ecrã inicial, raio do overlay">

*Três coisas distintas que convém conhecer.*

- **Evitar autoestradas** muda o próprio itinerário calculado: as áreas de serviço deixam de ser candidatas — em geral uma poupança, já que o combustível de autoestrada é o mais caro de qualquer corredor.
- **Notas dos postos** — *Local* (só este dispositivo), *Privado* (sincronizado na sua conta) ou *Partilhado* (visível a outros utilizadores). É uma decisão de privacidade, não de armazenamento.
- **Ecrã inicial** — com o que a aplicação abre: Por perto, Posto mais próximo, Favoritos ou Mapa.

<img src="guide/profile-edit-4.jpg" width="340" alt="Raio e modo de preço do overlay, veículo predefinido, região">

*O raio do overlay e a regra **mais próximo vs mais barato do raio** vivem no perfil: um perfil « diário » e um « férias » podem comportar-se de forma diferente.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Região: chips de país e de idioma">

*O país decide o fornecedor de dados. Alterá-lo esvazia os dados de postos em cache.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Chips de idioma e campo do código postal de casa">

*Um **código postal de casa** permite pesquisas por zona sem qualquer GPS — a forma mais limpa de usar a aplicação se nunca quiser partilhar a sua localização.*

---

## Veículos e OBD2

*Os seus carros, capacidade do depósito, emparelhamento · âmbito: este veículo*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Ecrã Veículos e OBD2">

*Os adaptadores emparelham-se por veículo: o mosaico do adaptador leva-o para dentro de um veículo em vez de um ecrã global.*

O tratamento completo — VIN, capacidade, flex-fuel, modos de calibração, referência, limiares de gravação automática, lembretes — está em [Veículos e OBD2](User-pt-Vehicles-And-OBD2).

---

## Condução e consumo

*Coaching, recompensas, radar, resolução de problemas · âmbito: misto*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Janela de consumo em direto, overlay de aproximação, os meus veículos, interruptores de coaching">

*As duas primeiras entradas são as que vai mesmo afinar.*

| Definição | Impacto |
|---|---|
| **Janela de consumo em direto** (3/5/10/30 s) | Mais longa = mais estável e legível ao volante; mais curta = reativa o bastante para ensinar quanto custa o pedal |
| **Overlay ao aproximar-se** | Raio, modo de preço, piso de consulta e fixação de ecrã para o perfil ativo |
| **Coaching eco em tempo real** | Vibração ligeira + conselho no ecrã ao acelerar com força em velocidade de cruzeiro |
| **Coaching de voz** | O mesmo conselho lido em voz alta — os olhos ficam na estrada |
| **Glide-coach beta** | Aviso tátil antes de um vermelho a partir dos semáforos do OpenStreetMap. **Desligado por omissão — risco de distração**, e precisa de rede |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, cartões de fidelização, conquistas, registo de depuração OBD2">

*Recompensas e resolução de problemas.*

- **Cartões de fidelização** — descontos por litro aplicados nas comparações de preço, para que um posto nominalmente mais caro possa aparecer corretamente como mais barato para si.
- **Mostrar conquistas e pontuações** — desligado, distintivos, pontuações e troféus desaparecem de toda a aplicação. Nada deixa de ser medido; deixa de ser mostrado.
- **Registo de depuração OBD2** — grava cada sessão (ligação, handshake, perdas de dados, reconexões) num registo XML exportável. **Desligado por omissão**: escreve continuamente e só compensa enquanto se persegue um problema do adaptador.

---

## Preços e alertas

*Alertas, anúncios de voz, histórico, relatos comunitários*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Preços e alertas: entrada de alertas, nota sobre anúncios de voz, funcionalidades de preço">

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

<img src="guide/units-and-display-1.jpg" width="340" alt="Tema, unidade de distância e unidade de consumo">

*A **unidade de consumo** propaga-se a todo o lado de uma vez — faixa em direto, miniatura, médias de viagem, estatísticas, widget.*

- **Unidade de distância** segue por omissão o país do perfil ativo (km ou milhas).
- **Unidade de consumo**: *Automático* (mpg no Reino Unido e EUA, L/100 km no resto), ou explicitamente L/100 km, km/L ou mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Widget do ecrã inicial: esquema de cores e variante de conteúdo">

*As escolhas do widget trazem a etiqueta **este perfil** e aplicam-se a todos os widgets instalados que mostrem esse perfil, a partir da próxima atualização.*

**Variante de conteúdo** — *só preço atual*, ou *preditivo: melhor momento para abastecer* (requer a previsão TFLite).

---

## Funcionalidades e modo de utilização

*Predefinições e cada interruptor individual*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Predefinições Básico, Médio, Completo e o estado Personalizado">

*Escolher uma predefinição **sobrepõe-se** a cada interruptor individual. Se afinou à mão, fique em Personalizado.*

As dependências são aplicadas, não escondidas: um interruptor com o pré-requisito desligado fica desativado e nomeia esse pré-requisito.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Grupo Pesquisa e mapa: itinerários, carregamento EV, mostrar postos, mostrar pontos, calculadora">

*Pesquisa e mapa — incluindo se postos e pontos de carregamento aparecem sequer.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Grupo Preços e alertas: alertas, histórico, previsão TFLite, QR de pagamento, relatos">

*Preços e alertas. O histórico é a funcionalidade-mãe da previsão que se lhe segue.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Grupo Radar de postos com anúncios de voz e o interruptor principal de síntese de voz">

*O radar, os seus anúncios de voz e o interruptor principal **Retorno falado** — desligado, a aplicação nunca abre um motor de síntese.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Grupo Consumo: seletor de modo mais análise, gamificação, coach tátil, glide-coach, rasto GPS, gravação automática">

*O seletor **Desligado / Combustível / Combustível + Viagens** é a forma compacta de toda a pilha de consumo.*

| Interruptor | Impacto |
|---|---|
| **Estatísticas de consumo** | O separador de análise de abastecimentos e viagens |
| **Gamificação** | Pontuações de condução e distintivos ganhos |
| **Eco-coach tátil** | Retorno vibratório em tempo real ao volante |
| **Glide-coach** | Conselhos eco a partir dos semáforos do OpenStreetMap — precisa de rede |
| **Rasto GPS das viagens** | Guarda os pontos de rota de cada viagem. Desligado = base mais pequena, sem mapas de viagem |
| **Gravação automática** | Inicia uma viagem quando o adaptador emparelhado se liga a um veículo em movimento |

<img src="guide/features-and-mode-6.jpg" width="340" alt="PID OEM experimentais, exigir OBD2, painel de carbono, TankSync, sincronização de referências">

*Dois interruptores aqui mudam a qualidade dos dados em vez da interface.*

- **PID OEM experimentais** — lê o nível exato do depósito em litros através de PID do fabricante em adaptadores compatíveis. Melhores dados onde funciona; inofensivo onde não.
- **Exigir OBD2 para a gravação de viagens** — **desligado**, as viagens gravam-se só com GPS. O coaching é reduzido (sem L/100 km instantâneos, menos sinais do motor) mas nada fica bloqueado.
- **Sincronização de referências** — envia as referências de consumo por veículo para um segundo dispositivo as reutilizar. Requer TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Introdução e digitalização: cartões de fidelização, OCR de talão, partilhar talão para importar">

*Introdução e digitalização. O reconhecimento é no dispositivo; estes interruptores só decidem se os atalhos existem.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Programador e experimental: retorno via PAT do GitHub, modo programador, rasto de arranque">

*Programador e experimental — pode ficar desligado a menos que reporte erros.*

---

## Fontes de dados e localização

*Chaves API, GPS, mudança automática de perfil*

<img src="guide/data-sources-location.jpg" width="340" alt="Campos de chave API e bloco de localização">

*Uma cruz vermelha na chave de preços é a razão habitual de uma pesquisa alemã vazia.*

| Definição | Impacto |
|---|---|
| **Preços de combustível (Tankerkoenig)** | Necessária só para a Alemanha. Gratuita, por utilizador, no cofre de hardware |
| **Carregamento EV (OpenChargeMap)** | Opcional — substitui a chave partilhada pela sua própria quota |
| **Atualização automática** | Atualiza a posição GPS antes de cada pesquisa. Desligado = pesquisas mais rápidas, posição talvez antiga |
| **Mudança automática de perfil** | Comuta o perfil ao atravessar uma fronteira, para que fornecedor e combustível fiquem corretos automaticamente |

---

## Sincronização e conta

<img src="guide/sync-and-account.jpg" width="340" alt="Estado do TankSync, aviso de esquema desatualizado, mudar para e-mail, consentimentos, ver os meus dados">

*Este ecrã também revela problemas — aqui um esquema TankSync auto-alojado desatualizado que, por isso, falha em silêncio a sincronizar algumas tabelas.*

Tratado em detalhe em [Privacidade, dados e sincronização → TankSync](User-pt-Privacy-Profiles-Sync#tanksync-sincronização-na-nuvem-opcional). O essencial:

- **Sparkilo Community / a sua própria base / a base de um grupo** — três formas de implantação com três responsáveis diferentes.
- **Anónimo → e-mail** — *Passar ao e-mail* conserva os seus dados e a conta e acrescenta uma forma de iniciar sessão a partir de outro dispositivo. Uma conta anónima só existe no dispositivo que a criou.
- **Esquema desatualizado** — após uma atualização, quem se auto-aloja tem de voltar a correr o SQL de instalação, ou as tabelas novas falham em silêncio.

---

## Privacidade e dados

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Controlos de privacidade: proxy de mosaicos e carregamento dos logótipos">

*Duas decisões de privacidade ligadas à rede, cada uma formulada pelo que realmente revela.*

- **Carregar os mosaicos pelo proxy Sparkilo** — *ativado*: o servidor UE do programador vê a área do mapa e o seu IP e obtém os mosaicos por si. *Desligado*: os mosaicos vêm de tile.openstreetmap.org, que passa a ver o seu IP. Nenhuma opção significa « sem rede »; escolhe por quem ser visto. A versão F-Droid nunca usa o proxy.
- **Carregar os logótipos das marcas da Internet** — *desligado* por omissão; usam-se logótipos genéricos incluídos. Ativado, vêm de logo.clearbit.com, que vê o seu IP.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Utilização do armazenamento por categoria com tamanhos">

*O armazenamento, discriminado. A cache é quase sempre a maior fatia e a única que se pode deitar fora sem risco.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Durações da cache por categoria e ação Limpar a cache">

*Gestão da cache, com a duração de cada classe: pesquisas 5 min, detalhes de posto 15 min, consultas de preço 5 min, dados de favoritos 30 min, pesquisas de cidade 30 min, geocodificação de código postal 24 h.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Caixa de confirmação da limpeza da cache">

*Limpar a cache apaga apenas resultados e preços guardados — perfis, favoritos e definições mantêm-se. As pesquisas seguintes serão mais lentas; nada se perde.*

---

## Cópia de segurança e restauro

<img src="guide/backup-restore.jpg" width="340" alt="Entradas Exportar cópia e Restaurar cópia">

*Um ZIP completo com veículos, abastecimentos, viagens e registos de carregamento.*

**Exportar cópia** escreve o ZIP nas suas Transferências. **Restaurar cópia** oferece *fundir* ou *substituir* — fundir mantém o que está no dispositivo e acrescenta o que falta; substituir apaga primeiro. Use-o antes de mudar de telemóvel ou de uma reposição de fábrica. O TankSync não é uma cópia de segurança: replica categorias escolhidas, não tudo.

---

## Avançado e programador

<img src="guide/advanced-developer.jpg" width="340" alt="Campo do token PAT do GitHub e entrada Ferramentas de programador">

*O token do GitHub é opcional — sem ele, um relato de leitura falhada partilha-se à mão em vez de abrir automaticamente uma questão.*

A entrada **Ferramentas de programador** só aparece com o modo programador ativo (Funcionalidades e modo de utilização → Programador e experimental).

<img src="guide/developer-tools-1.jpg" width="340" alt="Ferramentas de programador: registo de erros, notificação de teste, pipeline de alerta de teste, diagnósticos, testador OCR, limpar caches">

*Para um utilizador comum o registo de erros é a parte útil: **Guardar o registo de erros** escreve rastos expurgados nas Transferências, para anexar a um relatório.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Copiar diagnósticos, exportar rasto de acesso a dados, rasto de inicialização no arranque">

*O rasto de arranque é uma cascata das fases de inicialização — é assim que um arranque lento se diagnostica em vez de se adivinhar.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Testar o overlay de aproximação e informação de compilação com versão e canal">

***Testar o overlay de aproximação** força um estado sintético durante 30 s para verificar a apresentação do preço sobreposto sem sair a conduzir.*

---

## Acerca

<img src="guide/about-1.jpg" width="340" alt="Acerca: versão e número de compilação, autor, licença, política de privacidade, GitHub, reportar um erro">

***Versão e número de compilação** — cite ambos em qualquer relatório, e verifique-os primeiro quando uma correção « não funcionou » (o lançamento na loja pode ainda não o ter alcançado).*

<img src="guide/about-2.jpg" width="340" alt="Acerca: ligações de apoio e atribuições de dados">

*A aplicação é gratuita, de código aberto e sem publicidade. As atribuições dos dados de preços e de mapa estão no fim, como as licenças exigem.*

---

**Ver também:** [Como funciona o Sparkilo](User-pt-How-It-Works) · [Privacidade, dados e sincronização](User-pt-Privacy-Profiles-Sync)
**Seguinte:** [Privacidade, dados e sincronização →](User-pt-Privacy-Profiles-Sync)
