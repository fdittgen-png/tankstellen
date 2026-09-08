# Veículos e OBD2

Tudo o que a aplicação sabe sobre *o seu carro*. É esta página que decide se os números de consumo de todas as outras são de confiança.

---

## Porque é que a aplicação precisa de um veículo

Sem veículo, o Sparkilo é um procurador de preços. Com um, pode converter litros e quilómetros no *seu* custo por quilómetro, estimar a autonomia e — com adaptador — modelar o caudal instantâneo de combustível.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Ecrã Veículos e OBD2 com os mosaicos Os meus veículos e Adaptador OBD2">

*Definições → Veículos e OBD2. Repare na etiqueta de âmbito do mosaico do adaptador: os adaptadores emparelham-se **por veículo**, não por telemóvel.*

<img src="guide/my-vehicles.jpg" width="340" alt="Lista de veículos com um veículo ativo">

*O visto verde marca o veículo ativo — aquele a que são atribuídos novos abastecimentos e viagens.*

---

## Identidade e motorização

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Editor de veículo: nome, VIN opcional, ler o VIN do carro, seletor de motorização">

*Dê-lhe o nome pelo qual o reconhece. O VIN é opcional.*

### O VIN, e o que traz

Introduzir (ou ler) o VIN permite à aplicação obter cilindrada, número de cilindros, potência e tipo de combustível, que são as entradas do modelo de consumo. **Ler o VIN do carro** obtém-no num segundo via OBD2.

A descodificação online do VIN é um **consentimento separado** — a aplicação pergunta antes de enviar seja o que for, e a descodificação parcial offline funciona mesmo que recuse. Um VIN é um dado pessoal; trate-o como tal.

### Motorização

**Térmico / Híbrido / Elétrico** muda os campos abaixo. O térmico pede capacidade do depósito, potência e combustível preferido; o elétrico pede bateria e conectores.

---

## Capacidade, potência e flex-fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Bloco térmico: capacidade do depósito, potência do motor, combustível preferido, interruptor multicombustível, adaptador emparelhado">

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

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibração de referência: adaptador emparelhado, progresso 210/270, aviso de situações em falta e barras por situação">

*210 amostras de 270. Duas situações de condução continuam vazias, e a aplicação di-lo em vez de fingir completude.*

Cada amostra OBD2 é arquivada numa situação de condução: **ralenti, stop & go, urbano, autoestrada, desaceleração, subida / carregado, arranque a frio, carga sustentada / reboque, ponto morto**. As médias por situação formam a referência do veículo — o modelo que produz um L/100 km plausível quando falta o adaptador ou um PID deixa de responder.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Barras de amostras por situação, repor a referência e o seletor de modo de calibração">

*As situações com zero amostras são as que recairão em valores por omissão. Aqui duas: desaceleração e reboque.*

### Baseado em regras ou fuzzy

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Modo de calibração baseado em regras ou fuzzy, ações de reposição e lembretes de manutenção">

*O modo fuzzy é o predefinido e a melhor escolha para quase toda a gente.*

- **Baseado em regras** atribui cada amostra a exatamente uma situação. Previsível, mas salta de amostra em amostra entre « urbano » e « autoestrada » quando circula perto da fronteira — por volta dos 60 km/h, por exemplo.
- **Fuzzy** reparte cada amostra por todas as situações consoante o grau de pertença. Suave precisamente onde o modo de regras salta, ao custo de ser mais difícil de seguir amostra a amostra.

### Os botões de reposição — e o que fazem de facto

- **Repor o rendimento volumétrico** descarta o η_v aprendido e restaura o valor por omissão 0,85. η_v é um parâmetro do modelo speed-density que estima o caudal de ar sem medidor. Reponha-o só após uma intervenção mecânica; um número estranho é mais vezes um problema de cobertura. Os carros que publicam o caudal diretamente (PID 5E) não o usam de todo.
- **Repor a partir da base de veículos** recarrega cilindrada, potência e valores por omissão do catálogo integrado, descartando os seus valores manuais.
- **Repor a referência por situação** (no cartão de referência) apaga cada amostra aprendida e devolve-o aos valores de arranque a frio até novas viagens encherem o perfil.

Nenhum deles toca no **ganho de bomba**, aprendido das janelas de depósito cheio a cheio e residente fora do modelo OBD2 — ver [Como funciona o Sparkilo → Como um litro se torna um número](User-pt-How-It-Works#como-um-litro-se-torna-um-número).

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

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Editor de veículo completo montado a partir de cinco capturas">

</details>

---

**Ver também:** [Viagens e eco-coaching](User-pt-Trips-And-Coaching) · [Resolução de problemas → OBD2](User-pt-Troubleshooting-FAQ#o-adaptador-obd2-não-liga)
**Seguinte:** [Registo de abastecimentos e consumo →](User-pt-Fuel-And-Consumption)
