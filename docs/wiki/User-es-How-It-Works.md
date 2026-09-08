# Cómo funciona Sparkilo

Esta página es el modelo mental. Todo lo demás en la guía describe recorridos de clic; aquí se explica *por qué* esos recorridos tienen esta forma. Diez minutos aquí te ahorrarán una hora rebuscando en los ajustes.

---

## Los tres niveles de ahorro

Un coche cuesta dinero de tres formas independientes, y bajar una no hace nada por las otras:

1. **El precio por litro** — el surtidor que eliges. Lo fijan la geografía y el mercado; el papel de la app es mostrarte el más barato al que realmente puedes llegar.
2. **Los litros por kilómetro** — cómo conduces y qué conduces. El papel de la app es medirlo con honestidad y mostrar qué hábito cuesta más.
3. **Lo que pagaste de verdad** — la traza de auditoría. El papel de la app es mantener sus propias estimaciones ancladas a la realidad en lugar de dejarlas derivar.

El nivel 1 funciona desde la instalación. Los niveles 2 y 3 necesitan datos tuyos: como mínimo tus repostajes, idealmente también viajes grabados. **La app nunca finge saber más de lo que se le ha dicho** — de ahí las insignias de precisión, los porcentajes de cobertura y las etiquetas « provisional » en lugar de números redondos y seguros.

---

## Modos de uso: la app a tu medida

Sparkilo puede ser un buscador de precios de dos pantallas o un ordenador de a bordo completo. En lugar de imponer todos los interruptores a todo el mundo, la app agrupa las funciones en **preajustes de modo de uso**.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Gestión de funciones con los preajustes Básico, Intermedio, Completo y Personalizado">

*Ajustes → Funciones y modo de uso. Elegir un preajuste conmuta de golpe todo el conjunto correspondiente; tocar después un interruptor individual te lleva a **Personalizado**.*

| Preajuste | Obtienes | Barra inferior |
|---|---|---|
| **Básico** | Combustible y recarga más baratos cerca, favoritos, alertas, rutas | Favoritos · Mapa · **Buscar** |
| **Intermedio** | Todo lo de Básico + registro manual de repostajes, consumo y coste reales | + Combustible |
| **Completo** | Todo lo de Intermedio + grabación OBD2 automática de viajes, puntuaciones, tarjetas de fidelidad | + Viajes |
| **Personalizado** | Tu propia mezcla — en cuanto tocas un interruptor | según el caso |

### Cómo funciona de verdad

Un preajuste no es un modo en el que la app se ejecuta — es un **conjunto de indicadores de función con nombre**. Cada indicador muestra u oculta una función de forma independiente, y algunos declaran requisitos previos: *Sincronización de referencias* sigue desactivada mientras *TankSync* esté apagado, *Anuncios de voz* mientras *Respuesta hablada* lo esté, *Grabación automática* mientras no haya un adaptador emparejado. La tarjeta explica por qué un interruptor está bloqueado en vez de ignorar tu toque en silencio.

### Qué cambia en la práctica

- **Desactivar una función la retira de la app, no solo de la vista** — también se detiene su trabajo en segundo plano. *Alertas de precio* apagadas detienen la comprobación periódica; *Traza GPS de viajes* apagada detiene el guardado de puntos de ruta.
- **Los preajustes sobrescriben tu mezcla.** Tocar *Intermedio* reescribe cada interruptor. Si has ajustado a mano, quédate en Personalizado.
- **La barra inferior cambia de forma.** Si la pestaña Combustible o Viajes ha desaparecido, tú (o un preajuste) has apagado *Estadísticas de consumo* o *Grabación OBD2 de viajes* — no es un fallo.

---

## Perfiles: un contexto, un juego de valores por defecto

Un **perfil** agrupa todo lo que depende de *dónde y cómo conduces ahora*: país, idioma, combustible preferido, radio de búsqueda por defecto, código postal de casa, parámetros de ruta, pantalla de inicio, visibilidad de las notas, los ajustes del radar y el vehículo por defecto.

<img src="guide/profile-edit-1.jpg" width="340" alt="Editar perfil — nombre, combustible derivado del vehículo, radio por defecto">

*Ajustes → Perfiles y región → editar. El combustible preferido se **deriva de tu vehículo por defecto** — quita el vehículo si quieres elegirlo tú.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Sección Región del perfil — selectores de país e idioma">

*País e idioma están dentro del perfil: por eso cambiar de perfil puede cambiar de un toque la fuente de datos y el idioma de la interfaz.*

### Cómo funciona de verdad

El país guardado en el perfil activo decide **a qué proveedor nacional de datos abiertos llama la app**. Cambiarlo vacía los datos de estaciones en caché, porque los precios del proveedor anterior no significan nada para el nuevo país. El combustible preferido decide qué precio encabeza cada ficha, sobre qué se crea una alerta por defecto y para qué optimiza una búsqueda de ruta.

### Qué cambia en la práctica

- **Un perfil por cada país donde conduces.** « Casa — España, Gasolina 95, 10 km » y « Vacaciones — Francia, E85, mapa » son dos perfiles, no dos sesiones de ajustes.
- **Las búsquedas transfronterizas usan el combustible del perfil de cada país.** Sin perfil para el segundo país, ese tramo no tiene calidad que tarificar y sus estaciones muestran `--`.
- **El cambio automático de perfil** (Ajustes → Fuentes de datos y ubicación) puede conmutar el perfil cuando el GPS detecta una frontera.
- Las fichas de ajustes llevan una **etiqueta de alcance** — *este perfil*, *todos los perfiles* o *este vehículo* — para que siempre sepas hasta dónde llega un cambio.

---

## Una fuente de datos por país

Sparkilo no agrega. Cada país se consulta a través de su propia fuente oficial, y la cabecera de resultados la nombra.

<img src="guide/search-results.jpg" width="340" alt="Cabecera de resultados nombrando la fuente oficial francesa de precios">

*La línea bajo la barra no es decoración — dice qué autoridad publicó esos precios, y enlaza a ella.*

### Cómo funciona de verdad

| País | Fuente | Cadencia |
|---|---|---|
| Alemania | Tankerkönig (clave gratuita propia) | ~5 minutos |
| Francia | Prix-Carburants (gouv.fr) | continua, por estación |
| España | Geoportal Gasolineras (MITECO) | fichero diario, filtrado en el dispositivo |
| Italia | Fichero MIMIT | fichero diario, filtrado en el dispositivo |
| …y 13 más | el portal de datos abiertos de cada país | variable |

### Qué cambia en la práctica

- **Las calidades cambian al cruzar la frontera.** España vende E5 y raramente E10; Francia destaca el SP95-E10; Alemania publica E5, E10 y Diésel. El mismo combustible físico lleva tres nombres en tres países.
- **La frescura cambia.** Un precio alemán puede tener cinco minutos, uno español ser la publicación de ayer. La insignia de frescura de cada ficha te dice cuál miras — fíate más de ella que del número.
- **La densidad cambia.** Un conjunto de datos nacional escaso devuelve menos estaciones en el mismo radio. Son los datos del país, no una búsqueda fallida.
- **Un `--` en lugar de un precio significa « ese proveedor no publica esa calidad para esta estación »** — no « la estación no la vende ».

---

## Dónde viven tus datos

Sparkilo es **local-first**. Todo lo que sabe está en bases cifradas en tu teléfono; la clave está en el Android Keystore / Llavero de iOS.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Datos en este dispositivo: cada categoría de datos guardada localmente, con tamaño y recuento">

*Ajustes → Privacidad y datos → Datos en este dispositivo muestra cada categoría con un contador real: nada de tus datos te resulta invisible.*

Solo cuatro cosas salen del teléfono, y tres son opcionales:

| Qué sale | Cuándo | ¿Opcional? |
|---|---|---|
| Coordenadas de búsqueda o código de región | En cada búsqueda, a la fuente de precios del país | Necesario para precios en vivo |
| Área del mapa + tu IP | Carga de teselas vía el proxy UE del desarrollador | Sí — proxy apagado, las teselas vienen directas de OpenStreetMap |
| Trazas de fallo | Solo con *Informe de errores* activado | Sí — desactivado por defecto |
| Tus filas sincronizadas | Solo con *TankSync* activado | Sí — desactivado por defecto |

**Tu identidad nunca forma parte de una consulta de precios.** El recuento completo: [Privacidad, datos y sincronización](User-es-Privacy-Profiles-Sync).

---

## Cómo un litro se convierte en un número

Es la parte que la mayoría de las apps de combustible falla en silencio, así que vale la pena entenderla.

### El surtidor es la verdad

El único número físicamente cierto que la app obtiene es **litros repostados ÷ kilómetros recorridos entre dos depósitos llenos**. Todo lo demás — estimaciones GPS, caudal derivado del caudalímetro, modelo speed-density — es un modelo que puede derivar.

Por eso la app trata cada **ventana de depósito lleno a lleno** como un evento de calibración:

1. Registras un repostaje y marcas **Depósito lleno**. Eso cierra la ventana anterior.
2. La app calcula la *verdad del surtidor*: litros repostados ÷ kilómetros del cuentakilómetros × 100.
3. La compara con lo que su propio estimador produjo en los kilómetros realmente grabados, quitando cada corrección ya aplicada.
4. La razón entre ambos se convierte en la **ganancia de surtidor** del vehículo, fundida con las ventanas anteriores y acotada a un rango razonable.
5. Esa ganancia multiplica luego **cada rama estimada del caudal de combustible** — speed-density y MAF — en el siguiente viaje.

El combustible que el coche *declara por sí mismo* por OBD2 (PID 5E / 9D) está medido, no modelado: la ganancia nunca lo toca.

<img src="guide/trips-tab.jpg" width="340" alt="Informe del depósito con la cobertura y la desviación de calibración">

*El informe del depósito hace visible la calibración: este depósito fue a 6,4 L/100 km en el surtidor, las grabaciones cubrían el 81 %, y el estimador iba un 39 % alto antes de que esta ventana lo corrigiera.*

### Por qué la cobertura no sesga

Comparar ambos números **por kilómetro** hace que los kilómetros no grabados simplemente no pesen. Un depósito del que solo grabaste una quinta parte da igualmente una razón insesgada — solo cuenta menos en la mezcla. Por eso la app muestra el porcentaje de cobertura en lugar de ocultarlo: dice cuánto fiarse de *esa* ventana, no si la calibración es válida.

### La escala de precisión

| Insignia | Qué hay detrás | Rango típico |
|---|---|---|
| **Baja** | Solo GPS — ningún repostaje ha anclado nada todavía | ±15 % o peor |
| **Media** | Los repostajes han anclado el modelo, pero ningún viaje OBD2 ha alimentado el bucle | ±7–15 % |
| **Alta** | Repostajes *y* viajes grabados con OBD2 | ±3–7 % |

### Qué cambia en la práctica

- **Marca siempre « Depósito lleno » cuando llenes hasta arriba.** Un repostaje parcial se registra igualmente y cuenta para el coste, pero no puede cerrar una ventana de calibración. Los parciales pendientes aparecen como aviso en las estadísticas.
- **La precisión del cuentakilómetros importa más que la de los litros.** Un error de tecleo del 2 % envenena la ventana; 0,2 L de redondeo no.
- **La primera ventana se toma al pie de la letra, las siguientes suavizan.** Espera un salto y luego estabilidad.
- **Si conduces sin grabar, las cuentas no cuadrarán** — y la app lo dice en lugar de apañarlo. Ver la reconciliación en [Registro de repostajes y consumo](User-es-Fuel-And-Consumption#cuando-las-cuentas-no-cuadran).

---

## Cómo aprende la app tu conducción

Aparte de la ganancia de surtidor, un vehículo lleva una **referencia por situación de conducción**: lo que tu coche consume al ralentí, en stop & go, en ciudad, en autopista, decelerando, en cuesta o cargado, en frío, bajo carga sostenida y en punto muerto.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibración de referencia con muestras por situación y aviso de situaciones ausentes">

*Cada situación se llena de forma independiente. El aviso es honesto: dos situaciones aún no tienen muestras, así que la referencia está incompleta.*

### Cómo funciona de verdad

Cada muestra OBD2 se clasifica en una situación de conducción y se añade a ese cesto. Existen dos modos de clasificación:

- **Basado en reglas** — cada muestra pertenece a exactamente una situación. Nítido, pero un coche a 60 km/h salta de una muestra a otra entre « urbano » y « autopista ».
- **Difuso** *(por defecto)* — cada muestra se reparte entre todas las situaciones según lo bien que encaje. Suave justo donde el modo de reglas salta.

### Qué cambia en la práctica

- **Una referencia pertenece al vehículo, no al teléfono.** Cambiar de coche implica empezar otra; *Sincronización de referencias* (requiere TankSync) la lleva a un segundo dispositivo.
- **Las situaciones ausentes son lagunas honestas, no errores.** Si nunca remolcas, « Carga sostenida / remolque » quedará en 0 para siempre y la app seguirá diciendo que el perfil está incompleto. Está bien así.
- **Restablecer la referencia te devuelve a los valores de arranque en frío** hasta que nuevos viajes la llenen — hazlo tras una intervención mecánica, no porque un número pareciera raro.

---

## La única regla de ajustes que conviene memorizar

Los ajustes son un **árbol de dos niveles**: una raíz de fichas temáticas, una pantalla por tema, y un campo de búsqueda que filtra las fichas por palabra clave.

<img src="guide/settings-root-1.jpg" width="340" alt="Raíz de ajustes con fichas temáticas y campo de búsqueda">

*Cada parámetro tiene exactamente una casa. Si recuerdas el tema, nunca tienes que desplazarte.*

Mapa completo de todas las pantallas: [Referencia de ajustes](User-es-Settings-Reference).

---

**Siguiente:** [Encontrar gasolineras →](User-es-Finding-Stations)
