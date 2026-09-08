# Resolução de problemas e FAQ

Ordenado aproximadamente por frequência real.

---

## Antes de tudo: verifique a sua versão

<img src="guide/about-1.jpg" width="340" alt="Ecrã Acerca com a versão e o número de compilação">

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

Contexto: [Como funciona o Sparkilo → Como um litro se torna um número](User-pt-How-It-Works#como-um-litro-se-torna-um-número).

---

## « Encontrámos um desvio de X litros »

Abasteceu mais do que as suas viagens gravadas explicam. Responda às duas perguntas da reconciliação: um abastecimento em falta ou mal escrito recebe uma **entrada de correção**, uma viagem não gravada recebe uma **viagem virtual**. Ambas continuam editáveis. Deixá-lo por resolver enviesa a calibração, por isso dois toques valem a pena. Ver [Registo de abastecimentos e consumo](User-pt-Fuel-And-Consumption#quando-as-contas-não-batem-certo).

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

<img src="guide/developer-tools-2.jpg" width="340" alt="Rasto de inicialização no arranque em cascata com os tempos por fase">

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

Detalhes: [Privacidade, dados e sincronização → Os seus direitos](User-pt-Privacy-Profiles-Sync#os-seus-direitos-ao-abrigo-do-rgpd).

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

**Voltar a:** [a página inicial do guia](User-pt-Home)
