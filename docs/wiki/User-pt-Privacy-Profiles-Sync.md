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

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Controlos de privacidade: proxy de mosaicos do mapa e carregamento de logótipos de marcas">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Utilização de armazenamento repartida por categoria, com tamanhos">

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

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Tempos de vida da cache por categoria e a ação de limpar a cache">

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

<img src="guide/sync-and-account.jpg" width="340" alt="Sincronização e conta com o estado do TankSync, um aviso de esquema desatualizado e a entrada Consentimentos">

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

Para um instantâneo restaurável em vez de uma exportação de dados, use **Definições → Cópia de segurança e restauro** — ver [Referência de definições](User-pt-Settings-Reference#cópia-de-segurança-e-restauro).

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

**Ver também:** [Referência de definições](User-pt-Settings-Reference) · [Como funciona o Sparkilo → Onde vivem os seus dados](User-pt-How-It-Works#onde-vivem-os-seus-dados)
**Seguinte:** [Resolução de problemas e FAQ →](User-pt-Troubleshooting-FAQ)
