# Primeiros passos

Dez minutos entre a instalação e o primeiro euro poupado. Se depois ler apenas mais uma página, que seja [Como funciona o Sparkilo](User-pt-How-It-Works).

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

<img src="screenshots/privacy-consent.png" width="340" alt="Ecrã de consentimento do primeiro arranque com cada finalidade">

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

Ambos são detetados a partir do idioma do sistema, e ambos vivem **no perfil** — ver [Como funciona o Sparkilo → Perfis](User-pt-How-It-Works#perfis-um-contexto-um-conjunto-de-valores-predefinidos).

<img src="guide/profile-edit-6.jpg" width="340" alt="Seletor de idioma e código postal de casa no editor de perfil">

*Definições → Perfis e região → editar perfil. O código postal de casa permite pesquisar numa zona fixa sem nunca ceder o GPS.*

Mudar de país **esvazia os dados de postos em cache**, porque os preços do fornecedor anterior não valem para o novo país. A pesquisa seguinte demorará um instante a mais.

---

## 4. Escolher um modo de utilização

É a definição de maiores consequências, porque decide quanta aplicação obtém.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Predefinições Básico, Médio, Completo, Personalizado">

*Definições → Funcionalidades e modo de utilização. Comece em **Básico** se só quiser combustível mais barato; suba quando quiser saber porque é que o seu carro bebe.*

- **Básico** — encontrar combustível e carregamento, favoritos, alertas, itinerários.
- **Médio** — acrescenta o separador **Combustível**: registar abastecimentos, ver consumo e custo reais. Sem hardware.
- **Completo** — acrescenta o separador **Viagens**: gravação automática, pontuações, cartões de fidelização. Um adaptador OBD2 continua opcional mesmo aqui — as viagens gravam-se só com GPS.

Pode mudar quando quiser, e qualquer interruptor que toque depois coloca-o em **Personalizado**. A lista completa, e o que cada um custa em bateria, dados ou privacidade: [Referência de definições → Funcionalidades e modo de utilização](User-pt-Settings-Reference#funcionalidades-e-modo-de-utilização).

---

## 5. Só Alemanha: a chave API gratuita

16 dos 17 países funcionam de imediato. O serviço oficial **alemão** emite uma chave por utilizador.

<img src="guide/data-sources-location.jpg" width="340" alt="Ecrã de fontes de dados com os campos de chave Tankerkönig e OpenChargeMap">

*Definições → Fontes de dados e localização. Uma cruz vermelha aqui é a razão de uma pesquisa alemã não devolver nada.*

1. Abra [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) e peça uma chave (formulário curto, gratuito).
2. Copie-a — é um UUID como `00000000-0000-0000-0000-000000000002`.
3. Cole-a no campo **Preços de combustível (Tankerkoenig)**.

A chave fica no cofre de hardware (Android Keystore / Porta-chaves do iOS) e só é enviada ao serviço alemão. O campo **Carregamento EV** abaixo já contém uma chave partilhada: os dados de carregamento funcionam sem configuração.

---

## 6. A barra inferior

<img src="guide/favorites.jpg" width="340" alt="Separador Favoritos com a barra inferior e o botão Pesquisar central">

*O botão verde **Pesquisar** elevado ao centro é o único acionador de pesquisa de toda a aplicação.*

- ⭐ **Favoritos** — postos guardados e alertas de preço
- 🗺️ **Mapa** — cada posto próximo como pino colorido por preço
- 🔍 **Pesquisar** *(centro)* — por perto ou ao longo de um itinerário
- ⛽ **Combustível** — depósito, consumo, abastecimentos *(a partir de Médio)*
- 🛣️ **Viagens** — diário de bordo e coaching *(Completo)*

As definições **não** são um separador: é a engrenagem no canto superior direito dos ecrãs principais. Em tablet, ou telemóvel na horizontal, a aplicação divide-se em duas colunas para ver lista e mapa (ou detalhe) ao mesmo tempo.

---

## 7. A sua primeira pesquisa

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Folha de critérios para uma pesquisa por perto">

*Toque em **Pesquisar** → a folha de critérios abre preenchida a partir do seu perfil. Ajuste e toque de novo em **Pesquisar**.*

Obtém uma lista do mais barato (ou por distância — à sua escolha), cada cartão com preço, tendência, distância e frescura. Um toque abre o detalhe. A visita completa: [Encontrar postos](User-pt-Finding-Stations).

**Dica:** toque em **Guardar como valores predefinidos** no fim da folha assim que fixar os seus critérios habituais — toda a pesquisa futura partirá daí.

---

## 8. Duas definições a mudar no primeiro dia

<img src="guide/units-and-display-1.jpg" width="340" alt="Unidades e apresentação com tema, unidade de distância e unidade de consumo">

*Definições → Unidades e apresentação. A **unidade de consumo** está em *Automático* por omissão (mpg no Reino Unido, L/100 km no resto); escolha explicitamente L/100 km, km/L ou mpg se preferir.*

A segunda é **Definições → Condução e consumo → Janela de consumo em direto** (3 / 5 / 10 / 30 s). Controla o grande número em direto do ecrã de gravação: uma janela longa é mais estável de ler a conduzir, uma curta reage mais depressa ao seu pé direito.

---

## 9. Escolha com o que a aplicação abre

**Definições → Perfis e região → Ecrã inicial**: *Por perto* (pesquisa imediata com os seus últimos critérios), *Posto mais próximo*, *Favoritos* ou *Mapa*. Escolha o que corresponde à razão por que abre a aplicação.

---

## 10. Onde está tudo

As definições são uma árvore de dois níveis com pesquisa por palavra-chave no topo — escreva « raio », « OBD2 » ou « tema » e o mosaico certo aparece.

<img src="guide/settings-root-1.jpg" width="340" alt="Raiz das definições: mosaicos temáticos com campo de pesquisa">

*Doze temas, uma casa por parâmetro. O mapa completo é a [Referência de definições](User-pt-Settings-Reference).*

---

**Seguinte:** [Como funciona o Sparkilo →](User-pt-How-It-Works)
