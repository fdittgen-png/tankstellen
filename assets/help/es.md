# Sparkilo — Guía de usuario (Español)

> *Pagar menos por litro. Quemar menos litros por kilómetro. Ver exactamente lo que costó.*

Sparkilo es una aplicación libre y gratuita que **reduce el coste de uso de tu coche**. Sin cuenta, sin publicidad, sin rastreadores, sin Google Play Services. Todo lo que la app sabe de ti se queda en el teléfono hasta que actives otra cosa.

*La pantalla que más usarás: precios en vivo cerca de ti, los más baratos primero, con la fuente oficial de datos abiertos indicada arriba.*

---

## Los tres niveles de ahorro

Toda la aplicación se articula en torno a una idea: **un coche cuesta dinero de tres formas independientes, y cada una necesita una herramienta distinta.**

| Nivel | La pregunta que responde | Dónde vive |
|---|---|---|
| **1. El precio** | *¿Dónde está el combustible más barato ahora mismo?* | Búsqueda, Mapa, Favoritos, Alertas, Rutas |
| **2. El consumo** | *¿Cuántos litros a los 100 km, y por qué?* | Viajes, eco-coaching, OBD2 |
| **3. La verdad** | *¿Cuánto pagué realmente, y la estimación de la app es honesta?* | Pestaña Combustible, repostajes, estadísticas de consumo |

El nivel 1 ya hace ahorrar y no necesita nada más que la app. Los niveles 2 y 3 necesitan tus repostajes; el nivel 2 gana mucha precisión con un adaptador OBD2 barato. Hasta dónde llegar lo decides tú — ver Cómo funciona Sparkilo.

---

## Qué contiene esta guía

**Empezar aquí**

| Página | Qué aprenderás |
|---|---|
| Primeros pasos | Instalación, consentimiento en el primer arranque, país e idioma, modo de uso, primera búsqueda |
| Cómo funciona Sparkilo | Los conceptos detrás de todo: perfiles, modos de uso, una fuente por país, dónde viven tus datos, cómo un litro se convierte en un número |

**Encontrar combustible barato (nivel 1)**

| Página | Qué aprenderás |
|---|---|
| Encontrar gasolineras | El botón Buscar central, los criterios, leer una ficha, el detalle, el mapa, el radar de gasolineras |
| Planificación de ruta | Las paradas más baratas del trayecto, los corredores transfronterizos, las cuatro estrategias |
| Favoritos y alertas | Estaciones guardadas, alertas de estación y de zona, cómo se comporta de verdad la comprobación en segundo plano |
| Recarga eléctrica | Puntos de recarga vía OpenChargeMap, conectores, filtros de potencia |
| Historial y previsiones de precios | El historial local de 30 días, el « mejor momento para repostar » y lo que el algoritmo deliberadamente *no* hace |

**Consumir menos y saber lo que costó (niveles 2 y 3)**

| Página | Qué aprenderás |
|---|---|
| Vehículos y OBD2 | El modelo de vehículo, la capacidad del depósito, el flex-fuel, el emparejamiento, la calibración de referencia, reglas vs difuso |
| Registro de repostajes y consumo | Repostajes, nivel del depósito, informe del depósito, niveles de precisión, coste por km por combustible |
| Viajes y eco-coaching | Grabación GPS u OBD2, detalle de un viaje, puntuación de conducción, panel de carbono |

**Referencia**

| Página | Qué aprenderás |
|---|---|
| Referencia de ajustes | Cada pantalla del árbol de dos niveles, con el impacto operativo de cada interruptor |
| Privacidad, datos y sincronización | Consentimientos, los temas de Privacidad y datos, TankSync, copia de seguridad, tus derechos RGPD |
| Solución de problemas y FAQ | ¿Nada encontrado? ¿El adaptador no conecta? ¿Widget congelado? |

---

## Los 17 países admitidos

🇩🇪 Alemania · 🇫🇷 Francia · 🇦🇹 Austria · 🇪🇸 España · 🇮🇹 Italia · 🇩🇰 Dinamarca · 🇵🇹 Portugal · 🇱🇺 Luxemburgo · 🇸🇮 Eslovenia · 🇬🇧 Reino Unido · 🇦🇷 Argentina · 🇦🇺 Australia · 🇲🇽 México · 🇰🇷 Corea del Sur · 🇨🇱 Chile · 🇬🇷 Grecia · 🇷🇴 Rumanía

Cada país se sirve de **su propia fuente pública oficial en datos abiertos** — nunca de un agregador único. Alemania exige una clave API gratuita de [tankerkoenig.de](https://creativecommons.tankerkoenig.de/); el resto funciona al instante. Por qué eso importa para lo que ves en pantalla: Cómo funciona Sparkilo.

La interfaz está traducida a **23 idiomas** (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) y sigue el idioma del sistema.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Disponible en Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/es_badge_web_generic.png" height="80"/>
</a>

---

**Siguiente:** Primeros pasos →

> **Sobre las capturas.** Todas las capturas de esta guía provienen de un dispositivo con la app en **francés**, contra la fuente de precios francesa en vivo. La interfaz está totalmente localizada — tus pantallas tienen la misma disposición con las palabras de tu idioma.

---

# Primeros pasos

Diez minutos desde la instalación hasta el primer euro ahorrado. Si después lees una sola página más, que sea Cómo funciona Sparkilo.

---

## 1. Instalar

### Google Play (Android)

Instala desde **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — la versión pública de producción.

> **¿Vienes de la beta?** Play sigue sirviendo compilaciones beta una vez inscrito en la prueba abierta (la ficha muestra una etiqueta *(beta)*). Para pasar a producción: abre la [ficha de Play](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Salir del programa** → desinstalar → reinstalar.
>
> **¿Quieres las novedades antes?** Quédate en la beta — cada compilación llega al canal beta antes que a producción.

### F-Droid (Android, sin Google)

Una compilación totalmente **sin GMS** se distribuye desde su propio repositorio F-Droid (mapas OpenStreetMap, ningún servicio de Google). En F-Droid: **Ajustes → Repositorios → +** y añade:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Luego busca **Sparkilo**. Si tienes la versión de Play instalada, desinstálala primero — clave de firma distinta, así que no puede actualizar por encima.

### Otras vías

- **APK** — desde las [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — beta de TestFlight; pide una invitación en [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) mientras la ficha de App Store no esté publicada.

**Android mínimo** 7.0 (API 24), objetivo Android 15. **iOS mínimo** 15.5, objetivo iOS 18.

Sin cuenta, sin registro, sin correo. La app es plenamente utilizable en cuanto termina la instalación.

---

## 2. Primer arranque — el consentimiento

Antes de cualquier otra pantalla, la app muestra una **pantalla de consentimiento RGPD**. No es un aviso de cookies: enumera cada finalidad de tratamiento, y la app solo continúa si aceptas.

*Cada consentimiento mostrado aquí reaparece luego en Ajustes → Privacidad y datos, con la fecha y la versión de la política que viste.*

| Elemento | Para qué | Si rechazas |
|---|---|---|
| **Ubicación** *(mientras se usa)* | Búsqueda cercana, inicio de ruta, grabación de viajes | Buscar por código postal o elegir un punto en el mapa |
| **Notificaciones** | Solo para las alertas de precio | Las alertas nunca saltan |
| **Diagnóstico** | Trazas de fallo hacia Sentry — **desactivado por defecto** | No se envía nada; puedes guardar tú el registro de errores |

Antes de cada solicitud *del sistema* (cámara, Bluetooth, notificaciones) la app muestra primero su propia explicación, para que sepas a qué consientes antes de que Android lo pregunte.

Texto completo: **[Política de privacidad v3, 29 de agosto de 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. País, idioma y tu zona

Ambos se detectan del idioma del sistema, y ambos viven **en el perfil** — ver Cómo funciona Sparkilo → Perfiles.

*Ajustes → Perfiles y región → editar perfil. El código postal de casa permite buscar en una zona fija sin ceder nunca el GPS.*

Cambiar de país **vacía los datos de estaciones en caché**, porque los precios del proveedor anterior no valen para el nuevo país. La siguiente búsqueda tardará un instante más.

---

## 4. Elegir un modo de uso

Es el ajuste de mayores consecuencias, porque decide cuánta aplicación obtienes.

*Ajustes → Funciones y modo de uso. Empieza en **Básico** si solo quieres combustible más barato; sube cuando quieras saber por qué tu coche bebe.*

- **Básico** — encontrar combustible y recarga, favoritos, alertas, rutas.
- **Intermedio** — añade la pestaña **Combustible**: registrar repostajes, ver consumo y coste reales. Sin hardware.
- **Completo** — añade la pestaña **Viajes**: grabación automática, puntuaciones, tarjetas de fidelidad. Un adaptador OBD2 sigue siendo opcional incluso aquí — los viajes se graban solo con GPS.

Puedes cambiar cuando quieras, y cualquier interruptor que toques después te pone en **Personalizado**. La lista completa, y lo que cada uno cuesta en batería, datos o privacidad: Referencia de ajustes → Funciones y modo de uso.

---

## 5. Solo Alemania: la clave API gratuita

16 de los 17 países funcionan al instante. El servicio oficial **alemán** emite una clave por usuario.

*Ajustes → Fuentes de datos y ubicación. Una cruz roja aquí es la razón de que una búsqueda alemana no devuelva nada.*

1. Abre [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) y pide una clave (formulario corto, gratis).
2. Cópiala — es un UUID como `00000000-0000-0000-0000-000000000002`.
3. Pégala en el campo **Precios de combustible (Tankerkoenig)**.

La clave se guarda en la caja fuerte de hardware (Android Keystore / Llavero de iOS) y solo se envía al servicio alemán. El campo **Recarga EV** de abajo ya contiene una clave compartida: los datos de recarga funcionan sin configuración.

---

## 6. La barra inferior

*El botón verde **Buscar** elevado en el centro es el único disparador de búsqueda de toda la app.*

- ⭐ **Favoritos** — estaciones guardadas y alertas de precio
- 🗺️ **Mapa** — cada estación cercana como chincheta coloreada por precio
- 🔍 **Buscar** *(centro)* — cerca o a lo largo de una ruta
- ⛽ **Combustible** — depósito, consumo, repostajes *(desde Intermedio)*
- 🛣️ **Viajes** — cuaderno de bitácora y coaching *(Completo)*

Los ajustes **no** son una pestaña: es el engranaje arriba a la derecha de las pantallas principales. En tableta, o teléfono en horizontal, la app se divide en dos columnas para ver lista y mapa (o detalle) a la vez.

---

## 7. Tu primera búsqueda

*Toca **Buscar** → la hoja de criterios se abre rellenada desde tu perfil. Ajusta y vuelve a tocar **Buscar**.*

Obtienes una lista ordenada del más barato (o por distancia — tú eliges), cada ficha con precio, tendencia, distancia y frescura. Un toque abre el detalle. El recorrido completo: Encontrar gasolineras.

**Consejo:** toca **Guardar como valores predeterminados** al pie de la hoja una vez fijados tus criterios habituales — toda búsqueda futura partirá de ahí.

---

## 8. Dos ajustes que cambiar el primer día

*Ajustes → Unidades y visualización. La **unidad de consumo** está en *Automático* por defecto (mpg en Reino Unido, L/100 km en el resto); elige explícitamente L/100 km, km/L o mpg si lo prefieres.*

El segundo es **Ajustes → Conducción y consumo → Ventana de consumo en directo** (3 / 5 / 10 / 30 s). Gobierna el gran número en vivo de la pantalla de grabación: una ventana larga es más estable de leer conduciendo, una corta reacciona más rápido a tu pie derecho.

---

## 9. Elige con qué se abre la app

**Ajustes → Perfiles y región → Pantalla de inicio**: *Cerca* (búsqueda inmediata con tus últimos criterios), *Estación más cercana*, *Favoritos* o *Mapa*. Toma la que corresponda al motivo por el que abres la app.

---

## 10. Dónde está todo

Los ajustes son un árbol de dos niveles con una búsqueda por palabra clave arriba — escribe « radio », « OBD2 » o « tema » y la ficha correspondiente emerge.

*Doce temas, una casa por parámetro. El mapa completo es la Referencia de ajustes.*

---

**Siguiente:** Cómo funciona Sparkilo →

---

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

*Ajustes → Perfiles y región → editar. El combustible preferido se **deriva de tu vehículo por defecto** — quita el vehículo si quieres elegirlo tú.*

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

*Ajustes → Privacidad y datos → Datos en este dispositivo muestra cada categoría con un contador real: nada de tus datos te resulta invisible.*

Solo cuatro cosas salen del teléfono, y tres son opcionales:

| Qué sale | Cuándo | ¿Opcional? |
|---|---|---|
| Coordenadas de búsqueda o código de región | En cada búsqueda, a la fuente de precios del país | Necesario para precios en vivo |
| Área del mapa + tu IP | Carga de teselas vía el proxy UE del desarrollador | Sí — proxy apagado, las teselas vienen directas de OpenStreetMap |
| Trazas de fallo | Solo con *Informe de errores* activado | Sí — desactivado por defecto |
| Tus filas sincronizadas | Solo con *TankSync* activado | Sí — desactivado por defecto |

**Tu identidad nunca forma parte de una consulta de precios.** El recuento completo: Privacidad, datos y sincronización.

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
- **Si conduces sin grabar, las cuentas no cuadrarán** — y la app lo dice en lugar de apañarlo. Ver la reconciliación en Registro de repostajes y consumo.

---

## Cómo aprende la app tu conducción

Aparte de la ganancia de surtidor, un vehículo lleva una **referencia por situación de conducción**: lo que tu coche consume al ralentí, en stop & go, en ciudad, en autopista, decelerando, en cuesta o cargado, en frío, bajo carga sostenida y en punto muerto.

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

*Cada parámetro tiene exactamente una casa. Si recuerdas el tema, nunca tienes que desplazarte.*

Mapa completo de todas las pantallas: Referencia de ajustes.

---

**Siguiente:** Encontrar gasolineras →

---

# Encontrar gasolineras

Nivel 1 de los tres niveles de ahorro: pagar menos por litro.

---

## Un botón, un modelo mental

La barra inferior tiene un solo disparador de búsqueda — el botón verde elevado en el centro. Es contextual, no modal:

- **Desde cualquier pestaña** → abre la hoja de criterios.
- **Desde los resultados o el mapa** → reabre la hoja con tus últimos valores.
- **Dentro de la hoja** → ejecuta la búsqueda.

Su etiqueta dice lo que hará, y en modo ruta permanece desactivado hasta que haya un destino. Deliberadamente no hay botones separados de « buscar cerca » y « buscar en ruta ».

---

## Fijar los criterios

*La hoja se abre rellenada desde tu perfil activo — normalmente solo cambias una cosa.*

| Control | Qué hace | Impacto operativo |
|---|---|---|
| **Cerca / A lo largo de la ruta** | Cambia todo el modo de búsqueda | El modo ruta exige un destino y consulta cada país del corredor |
| **Dirección, código postal o ciudad** | Busca en un lugar en vez de tu posición GPS | Nada sobre tu ubicación sale del teléfono; el nombre se geocodifica con OpenStreetMap Nominatim y se cachea 24 h |
| **Chips de combustible** | La calidad cuyos precios ves | La lista se adapta a lo que el proveedor de tu país publica realmente |
| **Radio** | Hasta dónde buscar | Un radio amplio en un país denso devuelve muchas estaciones y ralentiza la búsqueda |
| **Solo abiertas** | Oculta las estaciones cerradas | Depende de que el proveedor publique horarios — algunos no lo hacen |
| **Servicios** | Tienda, lavado, aire, aseos… | Filtra solo sobre datos declarados; una estación con campo vacío desaparece |
| **Marcas** | Limitar a ciertas cadenas | Se cuentan sobre el conjunto actual de resultados, así que la lista cambia con el radio |
| **Guardar como valores predeterminados** | Escribe estos criterios en el perfil | Toda búsqueda futura parte de aquí |

### El botón de búsqueda

El botón elevado en el centro de la barra inferior es el único
disparador de búsqueda. Desde cualquier pestaña abre esta hoja; desde
los resultados o el mapa la reabre con lo último que usó; dentro de la
hoja, lanza la búsqueda.

### Cerca o a lo largo de una ruta

Dos preguntas distintas. **Cerca** busca alrededor de su posición o de
una dirección. **A lo largo de la ruta** necesita un destino y mide la
distancia a lo largo del corredor, no en línea recta: una estación a 2 km
por una calle lateral queda detrás de una que está de camino.

### Tipo de combustible

Para qué combustible son los precios. Los chips se adaptan a lo que
publica realmente el proveedor de su país — un combustible ausente de la
lista falta en los datos, no en la app.

### Radio

Hasta dónde buscar. Un radio amplio en un país denso devuelve muchísimas
estaciones y una búsqueda más lenta, y las estaciones de más suelen estar
más lejos de lo que vale el ahorro.

### Solo abiertas ahora

Oculta las estaciones cerradas. Depende de que el proveedor publique
horarios, y algunos no lo hacen — cuando faltan, la estación se conserva
en vez de adivinarse.

### Servicios

Tienda, lavado, aire, WC. Estos filtros actúan sobre datos
**declarados**: una estación que no publica nada sobre sus servicios
desaparece de una lista filtrada aunque los tenga todos.

### Estaciones de autopista

Las estaciones de autopista suelen ser el combustible más caro del país:
excluirlas es el filtro que más a menudo cambia lo que paga.
Consérvelas cuando no pueda salir de la autopista.

### Guardar como mis valores por defecto

Escribe estos criterios en su perfil, de modo que cada búsqueda posterior
empiece aquí y no en los valores de la app. Es el ajuste que convierte la
hoja en una confirmación de un toque en vez de un formulario.

### Cómo funciona de verdad

Una búsqueda cercana envía **tus coordenadas (o un código de región) y un radio** al proveedor oficial de tu país — nunca tu identidad. Los países que publican un fichero diario (España, Italia) se filtran en el dispositivo: esas búsquedas no necesitan ninguna llamada de red una vez cacheado el fichero.

---

## Leer una ficha de resultado

*Todo lo necesario para decidir, sin abrir nada.*

- **Precio** — del combustible buscado, en la convención de tu país (fíjate en la décima de céntimo en superíndice).
- **Flecha de tendencia** ▲▼▬ — hacia dónde va el precio de esa estación últimamente, según *tu propio* historial local.
- **★** — toca para marcar favorito; rellena = ya guardada.
- **Chips de servicios** — tienda, lavado, aire, cajero, según lo declarado.
- **Distancia** — en línea recta desde tu posición.
- **« Actualizado 31/08 00:01 »** — el sello de frescura. **Léelo antes que el precio.**
- **Fila de orden** — Distancia / Precio / A–Z / 24 h, más un chip de aviso cuando el precio más reciente de la lista supera la hora.

### La frescura, más importante que el precio

| Insignia | Antigüedad | Qué hacer |
|---|---|---|
| Verde | < 5 min | Fiarse |
| Amarillo | 5–30 min | Suficiente para decidir |
| Naranja | horas | Plausible; el proveedor puede publicar despacio |
| Borde rojo | > 1 día | Tratarlo como orientativo — actualiza antes de desviarte |

La frescura es una propiedad del **proveedor del país**, no de la app. Un precio español de 14 horas no es un fallo: ese país publica una vez al día. Ver Cómo funciona Sparkilo → Una fuente por país.

### Gestos de deslizamiento

- **Deslizar a la derecha** — abrir en tu app de navegación (Google Maps, Waze, OsmAnd, Organic Maps).
- **Deslizar a la izquierda** — ocultar la estación de todos los resultados futuros. Se restaura desde **Privacidad y datos → Datos en este dispositivo → Estaciones ignoradas**.

---

## Detalle de una estación

*Toca una ficha. La cabecera cae de marca a nombre y a calle, así que un Intermarché sin campo de marca sigue mostrando « Intermarché ».*

El bloque superior es la **tabla completa de precios** — cada calidad que el proveedor publica para esa estación, con `--` donde no publica ninguna. Es la forma más rápida de ver si la estación de E85 barata también aguanta con el diésel.

**Añadir repostaje** rellena estación, combustible y precio en el formulario — el mayor ahorro de tiempo de la app si registras tus repostajes.

*Más abajo: servicios, medios de pago aceptados, tu valoración privada en estrellas, y el historial local de precios de 30 días.*

Las acciones de la barra superior son, de izquierda a derecha: **crear una alerta de precio**, **escanear un QR de pago**, **informar de un precio erróneo** y **marcar como favorita**.

---

## El mapa

*El color es relativo a lo que está en pantalla: verde la más barata visible, rojo la más cara. El pie indica número de estaciones, radio y antigüedad de los datos.*

- **Los marcadores de grupo** juntan chinchetas al alejar; un toque acerca.
- **Pulsación larga** en cualquier punto para dejar tu marcador y buscar desde ahí.
- El **selector EV** arriba a la derecha cambia el mapa a puntos de recarga — ver Recarga eléctrica.
- **Compartir** envía la vista actual a alguien.

Las teselas vienen de OpenStreetMap. Por defecto pasan por el proxy UE del desarrollador para que OpenStreetMap nunca vea tu IP; puedes desactivar el proxy en Ajustes → Privacidad y datos y cargar directamente. La versión F-Droid nunca usa el proxy.

---

## El radar de gasolineras

Un barrido en vivo alrededor de tu posición, pensado para **conducir**.

*Tras cualquier búsqueda cercana aparece una píldora flotante abajo a la derecha. Un toque inicia el radar.*

### Cómo funciona de verdad

El radar refresca tu posición GPS, recupera las **ubicaciones** de estaciones en un amplio corredor de 60 km y fusiona una consulta directa dentro del radio: nunca puede mostrar menos que una búsqueda normal. Las estaciones no se mueven, así que esas ubicaciones se cachean hasta una hora y se reutilizan; solo el **precio** de una estación a la que te acercas se pide en el momento. Eso es lo que hace barato en datos y batería un radar siempre activo.

*En marcha: resultados por distancia, cada uno con una barra que se llena al acercarte.*

### Durante la grabación de un viaje

El radar fija una ficha **Estación más cercana** arriba en la pantalla de grabación — nombre, precio de tu combustible, distancia, y una barra que llega al 100 % al llegar. Desliza a izquierda/derecha para recorrer las candidatas. Al entrar en el radio configurado, la miniatura superpuesta cambia a una gran visualización de precio; ver Viajes y eco-coaching → La superposición de aproximación.

### Ajustes que cambian su comportamiento

Todos en **Ajustes → Conducción y consumo**: el **radio** al que la superposición se agranda, si muestra la estación **más cercana** o la **más barata del radio**, el **intervalo mínimo de refresco** (un suelo, no una cadencia fija — consulta más rápido a alta velocidad pero nunca más apretado) y el **anclado automático**, que mantiene la pantalla encendida y oculta las barras del sistema para un soporte de salpicadero, a costa de batería.

---

## La calculadora de coste de combustible

Tres números de entrada — distancia, tu consumo, el precio — y de salida litros quemados, coste total y coste por kilómetro. Rellena consumo y precio con tus propios datos, así que a menudo solo tecleas la distancia.

Responde honestamente a una sola pregunta: *¿la estación 12 km más lejos es realmente más barata una vez que he ido?*

---

## Widget de pantalla de inicio

- Muestra tu favorito más barato (o la estación más cercana) y su precio.
- **Tocar el widget** → abre el detalle de esa estación, estuviera la app viva o cerrada.
- **Tocar el icono de refresco** → recarga los precios en segundo plano sin abrir la app.
- Refresco de fondo cada 30 min con el móvil cargando, cada hora si no, respetando el modo Doze.

Aspecto y variante de contenido (*precio actual* o *predictivo: mejor momento para repostar*) se fijan por perfil en **Ajustes → Unidades y visualización → Widget de pantalla de inicio**.

---

## Android Auto

Conectada a una unidad Android Auto, la app ofrece dos pantallas seguras al volante: **Buscar** (las estaciones de tu última búsqueda en el teléfono) y **Radar** (las más baratas en tu ruta). Lanza primero la búsqueda en el teléfono — el lado del coche es deliberadamente de solo lectura, porque no hay forma segura de teclear conduciendo. Solo Android; no hay versión CarPlay.

---

<details>
<summary>Vista completa — detalle de estación, página entera</summary>

</details>

---

**Ver también:** Planificación de ruta · Favoritos y alertas · Historial de precios
**Siguiente:** Planificación de ruta →

---

# Planificación de ruta

No « el más barato cerca de mí » sino **el más barato en el camino** — la diferencia vale varios euros en cualquier viaje largo.

---

## Lanzar una búsqueda por ruta

*Toca **Buscar** → cambia a **Buscar a lo largo de la ruta**. El botón sigue desactivado hasta que haya destino y combustible.*

| Campo | Significado |
|---|---|
| **Salida** | Tu posición actual, o una ciudad / código postal escritos |
| **Añadir una parada** | Puntos intermedios — el corredor los sigue |
| **Destino** | Ciudad, código postal o coordenadas |
| **Combustible** | La calidad tarificada a lo largo del corredor |
| **Segmento de ruta** | Mostrar la estación más barata cada *n* km (50–1000 km) |
| **Desvío máximo** | A qué distancia de la línea directa puede estar una estación |
| **Ahorro mínimo** | Oculta las paradas que no baten la media del corredor al menos por esa cantidad; *Desactivado* muestra todo |

*Los mismos filtros de apertura, servicios y marcas de una búsqueda cercana valen para el corredor.*

### Cómo funciona de verdad

1. La app llama al servicio público de rutas **OSRM** y obtiene la polilínea vial del trayecto.
2. Coloca puntos candidatos a lo largo de esa línea, separados según tu **segmento de ruta**.
3. En torno a cada punto consulta al proveedor de precios **del país donde está ese punto**, con la calidad del perfil de ese país.
4. Ordena las candidatas de cada segmento según tu estrategia y el límite de **desvío máximo**.

### Qué cambia en la práctica

- **La longitud de segmento es el verdadero mando.** 50 km sobre 600 km da doce listas; 200 km da tres. Elígela según lo a menudo que pares de verdad.
- **El desvío máximo se mide desde la ruta directa**, no desde ti. 5 km significa « hasta 5 km de camino extra ».
- **Las rutas largas tardan más.** Un corredor de 600 km muestrea muchos puntos, quizá en varios proveedores.
- Si la salida es « GPS automático » y pierdes señal, la búsqueda recurre a la última posición conocida.

---

## Corredores transfronterizos

Cuando una ruta cruza una frontera, **cada país del corredor se consulta con su propio proveedor**, y la cabecera los cita todos:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Como las calidades difieren por país, un resultado transfronterizo muestra legítimamente E85 en el tramo francés y Gasolina 95/E5 en el español. Cada uno está tarificado correctamente para su lado, nunca promediado.

**Necesitas un perfil por país** con la calidad preferida correcta, o el segundo tramo no tendrá nada que tarificar y mostrará `--`. Ver Cómo funciona Sparkilo → Perfiles.

---

## Los resultados llegan por partes

Una API nacional lenta no debe bloquear el resto del corredor: los resultados llegan **progresivamente**, apareciendo las estaciones de cada país en cuanto ese proveedor responde, con un aviso que nombra las fuentes pendientes. Puedes tocar un resultado barato en cuanto llega.

---

## Las cuatro estrategias

### 🏆 Mejores paradas *(por defecto)*
Sube arriba las 3–5 estaciones más baratas realmente alcanzables como chips ordenados. Los desvíos se mantienen cortos. Es lo que quiere la mayoría de conductores.

### 🎯 La más barata
La única estación con el precio más bajo de toda la ruta. Ideal si repostas una vez y quieres el máximo ahorro por litro.

### ⚖️ Equilibrada
Puntúa cada candidata por precio *y* cercanía a la línea. Una estación a 5 km pero 10 cts/L más barata gana; una a 50 km debe ser mucho más barata.

### 📏 Uniforme
Divide la ruta en segmentos iguales y propone una parada por segmento. Ideal para viajes largos transfronterizos con varios repostajes.

La estrategia por defecto, la longitud de segmento, el desvío máximo, el ahorro mínimo y el número de candidatas por punto de muestreo se guardan **por perfil**:

*Ajustes → Perfiles y región → editar → Planificación de ruta. Se fija una vez aquí en lugar de retocar la hoja en cada viaje.*

---

## Leer los resultados

Cada fila añade dos números que una búsqueda cercana no tiene:

- **Distancia desde la salida** — dónde está la estación en la ruta, para casarla con el momento en que el depósito estará bajo.
- **Desvío** — los kilómetros extra frente a la línea directa.
- **Ahorro respecto a la media** — frente a la media del corredor, no una nacional.

Cambia a **Todas las estaciones** para ver cada estación de la ruta en vez de la selección. El mapa traza la polilínea con todas las chinchetas.

---

## Evitar autopistas

**Ajustes → Perfiles y región → Visualización y estaciones → Evitar autopistas** hace que el enrutador prefiera carreteras secundarias. Eso cambia la *polilínea*, y por tanto qué estaciones son candidatas: las áreas de servicio desaparecen del corredor en vez de solo bajar de puesto. Útil precisamente porque el combustible de autopista suele ser el más caro de cualquier ruta.

---

## Itinerarios guardados

Toca **Guardar ruta** en la pantalla de resultados. Los itinerarios guardados aparecen arriba en el formulario; un toque reejecuta el mismo corredor con **precios frescos**. Se guarda la geometría, no los precios.

---

**Ver también:** Encontrar gasolineras · Referencia de ajustes
**Siguiente:** Favoritos y alertas →

---

# Recarga eléctrica

Sparkilo no es solo para térmicos. Los puntos de recarga vienen de [OpenChargeMap](https://openchargemap.org), el mayor registro comunitario abierto del mundo.

---

## Activar

Dos interruptores independientes, ambos en **Ajustes → Funciones y modo de uso → Búsqueda y mapa**:

- **Recarga EV** — la función en sí (búsqueda, páginas de detalle, favoritos).
- **Mostrar los puntos de recarga** — si los puntos aparecen en resultados y mapa.

*Puedes mostrar gasolineras, puntos de recarga, o ambos. Quien conduce solo eléctrico suele desactivar **Mostrar gasolineras**.*

Luego crea un vehículo en **Ajustes → Vehículos y OBD2 → Mis vehículos → Añadir**, eligiendo **Eléctrico** como motorización. Un vehículo eléctrico lleva capacidad de batería (kWh), potencias máximas de carga AC y DC (kW) y sus conectores (Tipo 2, CCS, CHAdeMO, Tesla, Schuko, Tipo 1, enchufe doméstico). Las búsquedas se limitan entonces a los puntos que tu coche puede usar de verdad.

---

## Cómo funcionan los datos

*Ajustes → Fuentes de datos y ubicación. El campo **Recarga EV (OpenChargeMap)** ya contiene una clave compartida: la recarga funciona sin configuración.*

La app consulta en vivo la API POI de OpenChargeMap para la zona que miras, y guarda el resultado en caché para que sobreviva sin conexión.

### Por qué querrías tu propia clave

La clave integrada la comparten todos los usuarios de Sparkilo y por tanto está limitada como un fondo común. Una clave personal te da tu propia cuota y permite a OpenChargeMap ver un uso real de sus datos. Es gratis:

1. Regístrate en [openchargemap.org](https://openchargemap.org).
2. Abre **My Profile → My Apps**.
3. **Register an Application**, describe brevemente, y la clave API (un UUID) se emite al instante.

Pégala en el campo Recarga EV. Se guarda en la misma caja fuerte de hardware que la clave alemana, nunca sale del dispositivo y solo se envía a OpenChargeMap. Vacía el campo para volver a la clave compartida.

### El recurso que parece un fallo

Si OpenChargeMap resulta inalcanzable, la app dibuja un pequeño **conjunto de datos de demostración integrado** en vez de un mapa vacío. Si ves el mismo puñado de puntos genéricos en todas las ciudades, es ese recurso diciéndote que la consulta en vivo falló — revisa conexión o clave, y no te fíes de esas chinchetas.

### Contribuir

OpenChargeMap la mantiene su comunidad. Un punto ausente o erróneo se corrige en [openchargemap.org](https://openchargemap.org), no en esta app — y la corrección llega luego a toda app basada en OCM, esta incluida, en la siguiente consulta.

---

## Buscar

*El selector EV de la barra del mapa pasa las chinchetas de combustible a recarga. El color sigue la potencia: azul claro en AC, azul oscuro en DC.*

En la hoja de criterios elige el tipo **EV** y lanza una búsqueda por radio. Filtros disponibles: tipos de conector, kW mínimos, y solo los puntos actualmente libres donde el operador publica estado en vivo.

---

## La página de detalle de un punto

- **Conectores** — tipo, cantidad y potencia máxima de cada uno
- **Tarifa** — por kWh cuando el operador la publica (muchos no)
- **Red** — Ionity, Fastned, Tesla…
- **Disponibilidad** — en tiempo real cuando se declara
- **Servicios** — comida, aseos, tiendas (cuentan más si estás parado 30 minutos)
- **Horarios** — 24/7 o según el operador
- **Reseñas** — de colaboradores de OpenChargeMap

---

## Favoritos y registro

Los puntos se marcan como favoritos igual que las gasolineras; en horizontal y en tableta, favoritos y alertas van lado a lado. La ficha favorita muestra los **kW por conector**, **cuántos están libres** y los **tipos de conector**.

Las alertas de precio sirven de poco en recarga, ya que la mayoría de operadores aplica tarifas planas por kWh. Las sesiones de recarga se registran como repostajes: **pestaña Combustible → Añadir**, con kWh en vez de litros — alimentan las mismas estadísticas de coste por kilómetro que los repostajes térmicos.

---

## Cruzar fronteras

En la recarga no hay deliberadamente **ningún filtro por país**. Al ir de Alemania a Francia ves ambas infraestructuras en el mismo mapa. Los precios de combustible son conjuntos nacionales; la recarga es un único conjunto mundial, así que la regla « un perfil por país » no aplica aquí.

---

**Ver también:** Encontrar gasolineras · Registro de repostajes y consumo
**Siguiente:** Vehículos y OBD2 →

---

# Favoritos y alertas de precio

La pestaña ⭐ es tu lista corta, más los robots que la vigilan por ti.

---

## Favoritos

*Dos pestañas arriba: **Favoritos** y **Alertas de precio**. Cada ficha lleva todas las calidades declaradas, no solo la tuya.*

Marca una estación con la ★ en cualquier ficha de resultado o en su pantalla de detalle.

### Qué se guarda de verdad

Un favorito no es un marcador, es una **copia local completa** de la estación: identificador, dirección, servicios, medios de pago, horarios y los últimos precios vistos. Por eso la pestaña funciona sin red: ves los últimos precios conocidos, claramente marcados por su sello de frescura.

### Qué cambia en la práctica

- **Los favoritos funcionan sin conexión**; las búsquedas no. Antes de un viaje sin cobertura, abre la pestaña una vez con Wi-Fi.
- Los precios se refrescan al abrir la pestaña, no continuamente.
- Los favoritos son de las categorías que **TankSync** replica entre tus dispositivos, si lo activas.

### Orden y gestos

Orden por precio (más barato primero, por defecto), distancia o alfabético. **Deslizar a la derecha** abre la navegación; **deslizar a la izquierda** quita el favorito, con opción de deshacer.

### Puntos de recarga

Los puntos de recarga también se pueden marcar, y la ficha muestra lo que necesita quien conduce eléctrico: **potencia por conector en kW**, cuántos están **libres ahora**, y los **tipos de conector**.

### Horizontal y tabletas

En teléfonos en horizontal y en cualquier pantalla de más de 600 dp, favoritos y alertas se muestran **lado a lado** con un separador en vez de tras un selector. Al estar ambos visibles, en esa disposición no hay conmutador.

---

## Alertas de precio

*Tres contadores arriba — reglas activas, disparos hoy y esta semana — luego los dos tipos de alerta. El pie fecha la última comprobación en segundo plano.*

Hay dos tipos, que responden a preguntas distintas.

### Alerta de estación — « avísame cuando *este* surtidor baje »

Se crea desde la página de detalle de una estación (icono de campana). Elige el combustible, fija un umbral, guarda. Ideal para la estación que ya usas.

### Alerta de zona — « avísame cuando *por aquí* baje »

*Ajustes → Precios y alertas → Alertas de precio → **Crear una alerta de zona**.*

| Campo | Qué hace |
|---|---|
| **Etiqueta** | Texto libre para que una lista de alertas siga siendo legible (« Diésel casa ») |
| **Tipo de combustible** | Una calidad por alerta — una estación puede tener varias |
| **Umbral (€/L)** | Salta cuando una estación de la zona baja **por debajo** |
| **Radio (km)** | La zona vigilada alrededor del punto central |
| **Frecuencia de comprobación** | Cada cuánto mira la tarea de fondo — ver abajo |
| **Mi posición / Elegir en el mapa / Código postal** | Tres formas de fijar el centro; un código postal nunca toca el GPS |

Ideal para « avísame cuando el diésel baje de 1,60 € en 5 km alrededor de casa », cuando la estación concreta da igual.

---

## Cómo funciona de verdad la comprobación

Una tarea de fondo programada por el sistema despierta y:

1. Recupera los precios en vivo de las estaciones implicadas.
2. Compara cada uno con su umbral.
3. Lanza una **notificación local** si algún precio está por debajo. El toque abre la estación.

La cadencia es **cada 30 minutos cargando, cada hora si no**, y solo con conexión. Tu frecuencia por alerta es un techo dentro de eso: « una vez al día » hace que la tarea la salte casi siempre.

### Qué cambia en la práctica

- **Las alertas son de mejor esfuerzo, no en tiempo real.** El sistema decide cuándo se ejecuta la tarea; los ahorradores agresivos la retrasan o la matan. Si el horario importa, saca la app de la optimización de batería.
- **No se usa GPS.** Las alertas trabajan sobre las coordenadas guardadas de las estaciones: una alerta alrededor de casa sigue funcionando a 500 km.
- **El coste en batería es despreciable** — unos pocos KB por despertar, en una ventana gestionada por el sistema, compatible con Doze. Muy por debajo del 0,5 % diario.
- **Un efecto secundario útil:** la misma comprobación escribe un registro de precio en tu historial local. Una estación con alerta construye por tanto su historial de 30 días en horas en vez de semanas — y eso es lo que hace aparecer pronto el aviso *mejor momento para repostar*. Ver Historial de precios.
- **Si las notificaciones están apagadas a nivel de sistema**, el interruptor de la app no puede disparar nada.

---

## Estadísticas

Los contadores de arriba muestran cuántas reglas están activas y cuántas veces han saltado hoy y esta semana — una prueba rápida de si la tarea de fondo se ejecuta de verdad. Una fila de ceros con varias alertas activas y un sello « última comprobación » viejo es el síntoma clásico de un ahorrador de batería matando la tarea.

---

## Detener alertas

Desactivar una alerta la pausa sin perder la regla; deslizar a la izquierda la elimina. Quitar la estación de favoritos **no** elimina sus alertas.

---

**Ver también:** Historial y previsiones de precios · Referencia de ajustes → Precios y alertas
**Siguiente:** Recarga eléctrica →

---

# Historial y previsiones de precios

La app construye una imagen **privada y local** de cómo se mueven los precios a tu alrededor, y saca de ella una recomendación honesta.

---

## Qué se registra, y dónde

Cada vez que el precio de una estación pasa por la app — una búsqueda, un refresco de favoritos o una comprobación de alertas en segundo plano — la app escribe **en tu teléfono** un registro: estación, combustible, precio, marca de tiempo. Nada se sube, y no se descargan datos de nadie más.

- **Deduplicado a un registro por estación y hora.** Cinco búsquedas en diez minutos dan una entrada.
- **Conservado 30 días.** Los registros más antiguos se borran automáticamente.
- **Habilitado por** *Funciones y modo de uso → Precios y alertas → Historial de precios*. Apagado, no se escribe ningún registro.

*Ajustes → Precios y alertas. El **historial de precios** es el requisito de la predicción de abajo — sin historial no tiene con qué trabajar.*

---

## Consultar el historial de una estación

Abre la página de detalle de una estación y baja hasta **Historial de precios**:

- **Gráfico horario** — precio medio por cada hora del día en los últimos 30 días.
- **Gráfico por día de la semana** — media por día.
- **Mín / máx / media / tendencia** en resumen.

La hora o el día más barato se resalta en verde, el más caro en rojo.

---

## « Mejor momento para repostar »

En cuanto hay suficiente historial, la estación muestra un aviso:

> 💡 **Los precios suelen bajar el martes 18:00–20:00** — ahorra ~3,2 cts/L

### Qué es — y qué no es

Es un **resumen de lo que ya ha ocurrido en esa estación en los últimos 30 días**, en *tus* datos. Deliberadamente **no** es:

- una previsión del precio de mañana,
- consciente del mercado del petróleo, de impuestos ni del tiempo,
- construido con datos de otros usuarios.

Esa contención es lo importante. Un recargo regional del lunes por la mañana es un patrón local real y repetible sobre el que se puede actuar; una previsión de mercado hecha por un teléfono, no.

### La fase de aprendizaje

El aviso permanece oculto hasta que haya al menos **10 registros de esa estación en los últimos 30 días**. Cuánto tarda depende solo de con qué frecuencia el precio pasa por la app:

| Situación | Tiempo hasta el aviso |
|---|---|
| La estación tiene una **alerta de precio** | Unas horas — la comprobación de fondo registra cada 30–60 min |
| La estación es un **favorito** que abres a diario | Unos diez días |
| Ninguna de las dos — búsquedas ocasionales | Semanas, quizá nunca |

**El truco práctico:** pon una alerta en la estación que usas de verdad. La alerta rinde doble — te avisa de la bajada y llena el historial que produce la recomendación.

### Por qué tu favorito aún no tiene aviso

1. **Aún no hay suficientes registros** (ver arriba).
2. **El precio apenas se ha movido.** Si el recorrido en 30 días es inferior a 0,1 cts/L no hay nada sobre lo que actuar, así que no se muestra nada.
3. **Solo un combustible tiene muestras.** El umbral es por tipo de combustible, no por estación.

---

## Predicción de precios en el dispositivo

*Funciones y modo de uso → Precios y alertas → **Mejor momento para repostar*** activa un pequeño modelo TensorFlow Lite que se ejecuta **enteramente en el dispositivo**. Sus características y sus predicciones nunca salen del teléfono. Es lo que alimenta la variante *predictiva* del widget de pantalla de inicio (**Ajustes → Unidades y visualización → Widget de pantalla de inicio → Variante de contenido**), que muestra el mejor momento para repostar en vez de solo el precio actual.

Si prefieres que no se infiera nada, desactívalo: historial y aviso de patrón siguen funcionando.

---

## Informes de precio de la comunidad

*Funciones y modo de uso → Precios y alertas → **Informes de precio comunitarios*** añade una acción de aviso al detalle de la estación, para corregir un precio que la fuente oficial tiene mal. Los informes van a la base TankSync compartida bajo tu cuenta seudónima y son visibles para otros usuarios conectados — es por tanto la única función de precios que **no** es puramente local. Requiere TankSync y está apagada hasta que la actives.

---

## Exportar

**Ajustes → Privacidad y datos → Exportar o eliminar → Exportar mis datos → CSV** escribe un CSV — su tabla de historial de precios contiene estación, combustible, precio, marca de tiempo — en tu carpeta pública de Descargas.

---

**Ver también:** Favoritos y alertas · Encontrar gasolineras → La frescura
**Siguiente:** Referencia de ajustes →

---

# Registro de repostajes y consumo

Niveles 2 y 3 de los tres niveles de ahorro: cuánto quemas, y cuánto costó de verdad. La pestaña ⛽ **Combustible** aparece en los modos **Intermedio** y **Completo**.

---

## La pestaña Combustible de un vistazo

*Tres bloques: qué hay en el depósito, cuánto cuesta tu conducción, y qué has puesto de verdad.*

### Nivel del depósito y autonomía

El indicador está **anclado a tu último depósito lleno**, y luego se descuenta el combustible consumido por los viajes grabados. El sello bajo la barra indica a qué repostaje está anclado.

Se muestran dos autonomías a propósito:

- **« ≈ 548 km al consumo de tu último depósito »** — el comportamiento reciente, útil hoy.
- **« Media a largo plazo: ≈ 611 km »** — tu media histórica, útil para planificar.

Si divergen mucho, algo ha cambiado recientemente: un cofre de techo, el invierno, otra mezcla de vías, o un cambio de combustible.

> Cuando hay un adaptador OBD2 conectado y el coche publica el PID de nivel de combustible, el indicador pasa al **sensor del depósito** y lo declara. Ese valor es una medida, no una deducción, y sobrevive a los viajes no grabados.

### La ficha de estadísticas

Las tres insignias son la capa de honestidad:

| Insignia | Significado |
|---|---|
| **Precisión: Alta · ±3-7 %** | Repostajes y viajes OBD2 alimentan ambos el modelo |
| **Precisión: Media** | Los repostajes lo anclan, pero ningún viaje OBD2 ha alimentado aún el bucle |
| **Precisión: Baja** | Solo GPS, nada anclado — añade un par de depósitos llenos |
| **η_v : 0,93 · 6 muestras** | El rendimiento volumétrico aprendido del modelo speed-density y sus muestras |

Debajo: media L/100 km, coste medio por km, litros totales, gasto total, número de repostajes. Un toque abre las [estadísticas completas](#estadísticas-de-consumo).

---

## Registrar un repostaje

Toca **➕ Añadir repostaje** — o mucho más rápido: **Añadir repostaje** directamente en la página de detalle de una estación, que rellena estación, combustible y precio.

*Desde una estación, tres campos ya son correctos — tecleas litros, total y cuentakilómetros.*

| Campo | Por qué importa |
|---|---|
| **Fecha** | Ordena las ventanas de depósito |
| **Vehículo** | Atribuye el repostaje y la calibración |
| **Tipo de combustible** | En un flex-fuel toda la comparación depende de este campo |
| **Litros** | El numerador de la verdad del surtidor |
| **Coste total** | Coste por km, gasto mensual |
| **Cuentakilómetros** | **El campo más importante del formulario** |
| **Depósito lleno** | Cierra una ventana de calibración — ver abajo |
| Estación, notas | Opcionales |

### Por qué el cuentakilómetros es el campo crítico

El consumo es litros ÷ kilómetros. Los litros vienen del recibo y son exactos. Los kilómetros vienen de *tus dos lecturas del cuentakilómetros*. Un error de 20 km en un depósito de 600 km es un 3 % de error — y como ese resultado recalibra el estimador, el error se propaga a toda estimación futura. El formulario rechaza un cuentakilómetros inferior al del repostaje anterior, porque la distancia no retrocede.

### La casilla « Depósito lleno »

Márcala siempre que llenes hasta arriba. Es lo que convierte dos repostajes en una **ventana cerrada** con un consumo físicamente verdadero.

Los repostajes parciales se registran igualmente, cuentan para el coste y salen en la lista — simplemente no pueden cerrar una ventana. La pantalla de estadísticas muestra un aviso que cuenta los *« repostajes parciales pendientes de un depósito lleno — fuera de la media »*, para que siempre sepas qué hay en los números.

### Escanear en vez de teclear

- **Escanear la pantalla del surtidor** — apunta la cámara al display; la app lee litros, total y precio.
- **Escanear el recibo** — lo mismo desde el ticket impreso.
- **Compartir una foto de recibo** desde otra app directamente al formulario.

El reconocimiento se ejecuta **en el dispositivo**; la imagen nunca se sube. Echa siempre un vistazo a los valores antes de guardar — un escaneo es una ventaja, no un oráculo. Si se equivoca, *Informar de error de escaneo* abre una incidencia con el recorte para mejorar el reconocimiento.

> **Versión F-Droid:** el reconocimiento de texto en el dispositivo solo existe en las versiones de Play / App Store. La versión F-Droid sin GMS no tiene escaneo — allí los repostajes se teclean a mano. Todo lo demás es idéntico.

---

## El informe del depósito — el momento de la verdad

Cada vez que un depósito lleno se cierra, la app publica un informe. En la pestaña Viajes aparece así:

*Una ficha, cuatro afirmaciones distintas — y deliberadamente no son el mismo número.*

| Línea | Qué es |
|---|---|
| **6,4 L/100 km** | La **verdad del surtidor** de este depósito: litros repostados ÷ kilómetros del cuentakilómetros |
| **1,5 L/100 km menos que el repostaje anterior** | Tendencia frente al último depósito cerrado |
| **559 km · 35,7 L · 32,12 €** | La ventana en bruto |
| **Las grabaciones cubren el 81 % de este depósito** | Qué parte de esos kilómetros grabaste de verdad |
| **Parte grabada: 10,5 L/100 km** | Lo que dieron por sí solos los kilómetros grabados |
| **Las estimaciones grabadas están un 39 % por encima de la verdad del surtidor** | El veredicto de calibración — el estimador iba alto y acaba de corregirse |

### Leerlo bien

La parte grabada y la verdad del surtidor **pueden diferir**, por dos motivos distintos que es fácil confundir:

1. **La selección.** Grabas los viajes que grabas. Si tu 81 % es sobre todo urbano corto y el 19 % ausente es un tramo de autopista, la parte grabada es legítimamente más alta que la media del depósito. Nada está roto.
2. **La calibración.** El propio estimador puede estar sesgado. Eso es lo que mide la última línea, comparando ambos **por kilómetro**, de modo que la cobertura se cancela y solo determina el peso de la ventana.

Tras una corrección como esta, espera que las estimaciones de viaje bajen notablemente en el siguiente trayecto y luego se estabilicen. El mecanismo completo: Cómo funciona Sparkilo → Cómo un litro se convierte en un número.

La ficha también puede señalar *qué cambió* — proporción de alto régimen, eventos bruscos por 100 km, arranques en frío, proporción de ralentí, cada uno frente al depósito anterior — con la salvedad explícita de que las grabaciones son espontáneas y solo cubren parte del depósito.

---

## Estadísticas de consumo

Toca la ficha de estadísticas, o **Combustible → Estadísticas de consumo**.

*Los chips de arriba restringen todo lo de abajo a un combustible — imprescindible en un flex-fuel, donde una media combinada no significa nada.*

La tabla mensual muestra litros, gasto, precio medio por litro, consumo medio, coste por km y número de repostajes, cada uno con su diferencia. Las flechas rojas no son un juicio — un *gasto* en alza tras un *precio por litro* en alza es el mercado, no tu pie derecho. La cifra a vigilar para la conducción es **L/100 km**.

### Coste por kilómetro por combustible

*La verdadera pregunta de quien conduce flex-fuel, resuelta: no qué combustible cuesta menos por litro, sino cuál cuesta menos por kilómetro.*

Cada combustible tiene una fila construida solo sobre **ventanas de depósito cerradas**: L/100 km medidos, precio realmente pagado por litro, coste por 100 km, gasto total, distancia medida, litros consumidos, CO₂ por 100 km, y cuántos depósitos llenos hay detrás. Una fila apoyada en un solo depósito se marca **Provisional**.

*La ficha de veredicto anuncia el ganador, la diferencia por 1000 km y — lo más útil — el **precio de equilibrio**.*

La línea de equilibrio (« E5 pasa a ser mejor que E85 por debajo de 0,75 €/L ») se calcula a partir de **tu propio consumo medido de cada combustible**: se mueve por tanto con tu conducción. Es una regla de decisión utilizable en el surtidor; una proporción genérica de internet no lo es.

Las cifras de CO₂ son estimaciones de pozo a rueda (EU JEC WTW v5) aplicadas a tu consumo medido — concienciación, no contabilidad certificada. Las mezclas quedan fuera del CO₂ porque el factor de emisión depende de la mezcla, que la fila no registra.

*Los gráficos de tendencia apilan por combustible: un cambio aparece como un color que sustituye a otro, no como un salto misterioso.*

*Precio por litro y L/100 km son dos gráficos distintos a propósito — uno es el mercado, el otro eres tú.*

**Exportar** escribe todo en CSV en tu carpeta pública de Descargas.

---

## Eco-puntuación por repostaje

Cada repostaje recibe una insignia comparada con la media móvil de tus tres últimos repostajes del mismo combustible:

| Diferencia | Insignia | Cómo leerlo |
|---|---|---|
| ≥ 3 % mejor | 🟢 Mejorando | Notablemente menos que tu propia referencia |
| dentro de ±3 % | ⚪ Estable | Variación normal |
| ≥ 3 % peor | 🟠 Empeorando | Revisa presión de neumáticos, cofre, frío, mezcla de vías |

La insignia sigue oculta hasta que tengas cuatro repostajes de ese combustible, para que la referencia sea real.

---

## Cuando las cuentas no cuadran

Antes o después repostarás más litros de los que tus viajes grabados pueden explicar — condujo otra persona, el adaptador estaba desenchufado, la app cerrada. En lugar de absorber la diferencia en silencio, la app muestra un **aviso de desfase** y propone una breve reconciliación:

> *Hemos encontrado un desfase de 4,2 L. Repostaste 35,7 L, pero tus viajes grabados solo explican 31,5 L.*

Hace dos preguntas:

1. **¿Están todos los repostajes de este depósito completos y correctos?** — No significa que falta uno o está mal tecleado, y la app añade un **repostaje de corrección** para que los litros cuadren.
2. **¿Están todos tus trayectos grabados?** — No significa que falta un trayecto, y la app añade un **viaje virtual** para la distancia que falta.

Ambos elementos son luego editables y borrables, y ambos están marcados como generados automáticamente para que nunca los confundas con datos reales. También puedes elegir **Decidir más tarde** — el aviso permanece hasta que lo resuelvas.

**Por qué importa:** un desfase sin resolver sesga en silencio la ventana de calibración. Resolverlo (o borrar la entrada errónea) mantiene fiable el anclaje al surtidor.

---

## Tarjetas de fidelidad

**Ajustes → Conducción y consumo → Tarjetas de fidelidad** guarda los descuentos por litro de las cadenas que usas. El descuento se aplica luego en las comparaciones de precio, así que una estación aparentemente 2 cts/L más cara puede resultar correctamente la más barata para ti. La función se activa en Funciones y modo de uso → Entrada y escaneo.

---

<details>
<summary>Vista completa — estadísticas de consumo, página entera</summary>

</details>

---

**Ver también:** Vehículos y OBD2 · Viajes y eco-coaching
**Siguiente:** Viajes y eco-coaching →

---

# Combustible, viajes y conducción *(movido)*

Esta página se ha dividido en tres, para que cada tema tenga sus propios anclajes de cara a una futura ayuda dentro de la app:

- **Vehículos y OBD2** — tu coche, capacidad del depósito, flex-fuel, emparejamiento, calibración de referencia, grabación automática.
- **Registro de repostajes y consumo** — repostajes, nivel del depósito, informe del depósito, precisión, coste por kilómetro por combustible.
- **Viajes y eco-coaching** — grabación, detalle de un viaje, puntuación de conducción, panel de carbono.

Empieza por **Cómo funciona Sparkilo** si quieres los conceptos detrás de los tres.

---

# Vehículos y OBD2

Todo lo que la app sabe de *tu coche*. Esta página decide si las cifras de consumo de todas las demás son fiables.

---

## Por qué la app necesita un vehículo

Sin vehículo, Sparkilo es un buscador de precios. Con uno puede convertir litros y kilómetros en *tu* coste por kilómetro, estimar la autonomía y — con adaptador — modelar el caudal instantáneo de combustible.

*Ajustes → Vehículos y OBD2. Fíjate en la etiqueta de alcance de la ficha del adaptador: los adaptadores se emparejan **por vehículo**, no por teléfono.*

*La marca verde indica el vehículo activo — al que se atribuyen los nuevos repostajes y viajes.*

---

## Identidad y motorización

*Ponle el nombre con el que lo reconozcas. El VIN es opcional.*

### El VIN, y qué aporta

Introducir (o leer) el VIN permite a la app deducir cilindrada, número de cilindros, potencia y tipo de combustible, que son las entradas del modelo de consumo. **Leer el VIN del coche** lo recupera en un segundo por OBD2.

La decodificación en línea del VIN es un **consentimiento aparte** — la app pregunta antes de enviar nada, y la decodificación parcial sin conexión funciona aunque lo rechaces. Un VIN es un dato personal; trátalo como tal.

### Motorización

**Térmico / Híbrido / Eléctrico** cambia los campos de abajo. El térmico pide capacidad del depósito, potencia y combustible preferido; el eléctrico pide batería y conectores.

---

## Capacidad, potencia y flex-fuel

*La capacidad del depósito es el número que más peso soporta de esta pantalla.*

### Por qué la capacidad del depósito importa tanto

Es el denominador del indicador de nivel y de la estimación de autonomía, y acota lo que la app considera un repostaje plausible. Una capacidad errónea produce durante meses una autonomía creíble pero equivocada. Tómala del manual, no de memoria — los fabricantes indican a menudo una capacidad útil un par de litros por debajo de la nominal.

### « Puedo repostar con distintos combustibles »

Actívalo para un coche flex-fuel (E85/E10, o cualquier cosa que realmente alternes). Cambian dos cosas:

- El formulario de repostaje **pregunta cada vez qué combustible has puesto de verdad**, en lugar de asumir el preferido.
- La pantalla de estadísticas gana la comparación **coste por kilómetro por combustible**, la única forma honesta de enfrentar un combustible barato pero sediento a uno caro pero sobrio.

Déjalo apagado si siempre pones la misma calidad — solo añade un campo.

---

## El adaptador OBD2

Un adaptador OBD2 es un pequeño dongle Bluetooth en la toma de diagnóstico del coche (normalmente bajo el salpicadero). **Es totalmente opcional.** Todo funciona solo con GPS; el adaptador convierte estimaciones en medidas.

### Qué cambia

| Sin adaptador | Con adaptador |
|---|---|
| Distancia y duración por GPS | Igual, más datos de motor |
| Consumo **modelado** desde tu calibración | Consumo **medido** (o modelado mucho mejor) |
| Coaching desde velocidad y aceleración | Coaching desde régimen, acelerador, carga, marcha |
| Techo de precisión: Media | Techo de precisión: Alta (±3–7 %) |
| Inicio manual del viaje | Grabación automática posible |

### Qué lee la app

Velocidad, régimen, carga del motor %, posición del acelerador %, temperaturas de refrigerante y de aire de admisión, avance de encendido, nivel de combustible %, cuentakilómetros (PID estándar A6, con respaldo en PID 31 y modo 22 del fabricante), y el caudal instantáneo de combustible — directamente del **PID 5E** donde el coche lo publica, o derivado del caudalímetro de aire.

> **La distinción importante:** si tu coche responde al PID 5E, tu consumo está *medido* y no se le aplica calibración alguna. Si no, la cifra está *modelada* a partir del caudal de aire y de parámetros del motor, y ese modelo es el que la ganancia de surtidor corrige. La pantalla del vehículo te dice en qué caso estás.

### Adaptadores admitidos

16 modelos se reconocen por su nombre Bluetooth, cada uno con un nivel de compatibilidad:

- ✅ **Probado** — confirmado en hardware real por el mantenedor.
- 👤 **Verificado por un usuario** — al menos un usuario informa de que funciona.
- ⚠️ **Teórico** — perfil y transporte correctos, pero sin verificación de extremo a extremo.

| Adaptador | Transporte | Notas | Nivel |
|---|---|---|---|
| vLinker FS | BT clásico | Modelo dominante en Europa; recomendado | ✅ |
| vLinker BM-Android | BT clásico | Hermano SPP clásico del BM+ | ✅ |
| SmartOBD (BLE) | BLE | Clon ELM327 v1.5 genérico | 👤 |
| SmartOBD (Classic) | BT clásico | Misma marca, variante SPP | 👤 |
| vLinker FD / MC | BLE | Familia Nordic UART FFF0 | ⚠️ |
| OBDLink MX+ | BLE | Gama alta de Scantool | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | Clon ELM327 v2.1 BLE | ⚠️ |
| vLinker BM+ | BLE | Hermano solo BLE | ⚠️ |
| Konnwei KW902 | BT clásico | Clon ELM327 v1.5 | ⚠️ |
| Vgate iCar Pro | BLE | Solo variante BLE | ⚠️ |
| Panlong WiFi | — | Solo WiFi, listado para etiquetar emparejamientos erróneos | ⚠️ |
| BAFX 34t5 | BT clásico | ELM327 v1.5 antiguo | ⚠️ |
| Generic ELM327 (BLE) | BLE | Perfil comodín para clones BLE FFF0 | ⚠️ |
| Generic ELM327 (Classic) | BT clásico | Perfil comodín para clones SPP | ⚠️ |

Los adaptadores no listados caen al perfil ELM327 genérico y suelen funcionar. Si el tuyo funciona — o no — [abre una incidencia](https://github.com/fdittgen-png/tankstellen/issues) para corregir el nivel.

### Emparejar

1. Contacto **puesto** (motor en marcha vale, contacto quitado no).
2. Enchufa el adaptador; su LED debe estar fijo.
3. Abre el vehículo y toca la sección del adaptador, o inicia un viaje.
4. Concede **Búsqueda Bluetooth** y **Conexión Bluetooth** (Android 12+). Hasta Android 11 el sistema exige en su lugar la **ubicación** para escanear en Bluetooth — regla del sistema, no una decisión de rastreo.
5. Espera unos 8 segundos al barrido y toca tu adaptador. La app ejecuta el saludo ELM327 y confirma.

Una vez emparejado, el adaptador pertenece a ese vehículo. **Restablecer la conexión** repite el saludo sin olvidar el dispositivo — lo primero que probar tras un corte en marcha. **Olvidar el adaptador** borra el emparejamiento por completo.

---

## Calibración de referencia — enseñarle tu coche a la app

*210 muestras de 270. Dos situaciones de conducción siguen vacías, y la app lo dice en lugar de fingir integridad.*

Cada muestra OBD2 se archiva en una situación de conducción: **ralentí, stop & go, urbano, autopista, deceleración, cuesta / cargado, arranque en frío, carga sostenida / remolque, punto muerto**. Las medias por situación forman la referencia del vehículo — el modelo que produce un L/100 km plausible cuando falta el adaptador o un PID deja de responder.

*Las situaciones con cero muestras son las que caerán a valores por defecto. Aquí dos: deceleración y remolque.*

### Basado en reglas o difuso

*El modo difuso es el predeterminado y la mejor opción para casi todo el mundo.*

- **Basado en reglas** asigna cada muestra a exactamente una situación. Predecible, pero salta de una muestra a otra entre « urbano » y « autopista » cuando circulas cerca del límite — hacia los 60 km/h, por ejemplo.
- **Difuso** reparte cada muestra entre todas las situaciones según su grado de pertenencia. Suave justo donde el modo de reglas salta, a costa de ser más difícil de seguir muestra a muestra.

### Los botones de restablecimiento — y qué hacen de verdad

- **Restablecer el rendimiento volumétrico** descarta el η_v aprendido y restaura el valor por defecto 0,85. η_v es un parámetro del modelo speed-density que estima el caudal de aire sin caudalímetro. Restablécelo solo tras una intervención mecánica; un número raro suele ser un problema de cobertura. Los coches que publican el caudal directamente (PID 5E) no lo usan en absoluto.
- **Restablecer desde la base de vehículos** recarga cilindrada, potencia y valores por defecto del catálogo integrado, descartando tus valores manuales.
- **Restablecer la referencia por situación** (en la ficha de referencia) borra cada muestra aprendida y te devuelve a los valores de arranque en frío hasta que nuevos viajes llenen el perfil.

Ninguno de ellos toca la **ganancia de surtidor**, aprendida de las ventanas de depósito lleno a lleno y residente fuera del modelo OBD2 — ver Cómo funciona Sparkilo → Cómo un litro se convierte en un número.

---

## Recordatorios de mantenimiento

Al pie del editor de vehículo: preajustes de **cambio de aceite (15 000 km)**, **neumáticos (20 000 km)** e **ITV (30 000 km)**, más recordatorios propios. Cuentan sobre los kilometrajes que introduces con tus repostajes: solo avanzan si anotas el cuentakilómetros — que es lo que la calibración necesita de todos modos. Un hábito, dos beneficios.

---

## Grabación automática

Con un adaptador emparejado, la grabación puede prescindir de ti:

- **Emparejamiento automático** — el primer emparejamiento manual crea la asociación adaptador ↔ vehículo.
- **Conexión automática** — en cuanto el sistema ve al adaptador emparejado emitir, la app se reconecta en segundo plano.
- **Inicio automático** — conectado y por encima del umbral de velocidad, el viaje empieza.
- **Guardado automático** — el adaptador pierde alimentación con el contacto, y tras el retardo configurado el viaje se cierra y se guarda.

La grabación automática exige el permiso de ubicación **« Permitir siempre »**, porque Android solo deja a un servicio en segundo plano emitir GPS con él. Ese permiso solo sirve para eso; la búsqueda y el centrado del mapa usan el permiso normal en primer plano.

> **Nota de plataforma.** La grabación automática está verificada en **Android**. En iOS el despertar de sistema necesario para « conectar en cuanto el adaptador se enciende » aún no existe ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); en iOS los viajes se inician a mano.

Los umbrales (velocidad de inicio, retardo de guardado tras desconexión) están en el editor de vehículo: un coche de trayectos cortos puede dispararse de forma distinta a uno de diario.

---

<details>
<summary>Vista completa — editor de vehículo, página entera</summary>

</details>

---

**Ver también:** Viajes y eco-coaching · Solución de problemas → OBD2
**Siguiente:** Registro de repostajes y consumo →

---

# Viajes y eco-coaching

La pestaña 🛣️ **Viajes** es un cuaderno de bitácora automático más un entrenador de conducción. Aparece en el modo **Completo**.

---

## La pestaña Viajes

*Totales del mes, el último informe del depósito, y luego la lista de viajes. El botón flotante inicia una grabación.*

La comparación mensual exige al menos tres viajes al mes antes de comparar — con menos, la media es ruido, no tendencia.

*El icono de mapa de la barra dibuja cada viaje grabado en un solo mapa — un año de conducción de un vistazo, y una forma fácil de detectar las rutas que merece la pena optimizar.*

---

## Dos formas de grabar

### Solo con el teléfono

Sin hardware. La app registra ruta, distancia, duración y velocidad por GPS, y **modela** el consumo desde la calibración del vehículo y tu conducción. Marcado en todas partes con `~` y una nota explícita de « estimación GPS ».

La precisión empieza mal y mejora: cada ventana de repostaje cerrada reancla el modelo al surtidor, así que tras un puñado de depósitos llenos un viaje solo con GPS suele quedar dentro de unos pocos puntos porcentuales. Hasta entonces se etiqueta como preliminar, no se maquilla.

### Con un adaptador OBD2

Datos de motor en vez de deducción: caudal real (medido donde el coche publica el PID 5E), régimen, carga, acelerador. Sin periodo de aprendizaje para el consumo, y el coaching accede a señales que el GPS no ve — marcha, revoluciones, carga del motor. La configuración está en Vehículos y OBD2.

> **Grabar nunca exige un adaptador.** Desactiva *Exigir OBD2 para la grabación de viajes* (Funciones y modo de uso → Consumo) para grabar solo con GPS; el coaching es reducido, no ausente.

---

## Mientras conduces

### La cifra en vivo

La cifra principal es tu media **de los últimos segundos** — combustible quemado ÷ distancia recorrida, la misma magnitud que un ordenador de a bordo — etiquetada *« Últimos 5 s »*. Parado pasa a L/h, porque los L/100 km no tienen sentido a velocidad cero.

Cambia la ventana en **Ajustes → Conducción y consumo → Ventana de consumo en directo** (3 / 5 / 10 / 30 s). Una **ventana larga es más estable y legible conduciendo**; una corta reacciona lo bastante rápido para enseñarte lo que cuesta tu pie derecho. La unidad sigue a **Unidades y visualización → Unidad de consumo** en todas partes: banner, miniatura superpuesta, Live Activity de iOS y media del viaje.

### El horizontal es la vista « en coche »

Gira el teléfono en horizontal durante una grabación y la pantalla se convierte en una disposición sin toques, legible de un vistazo: a la izquierda la gran cifra de consumo instantáneo con la indicación de coaching debajo (*levanta el pie* / *anticipa* / *acelera suave* con GPS, *sube marcha* / *reduce* / *afloja* con OBD2) y una gran velocidad; a la derecha la ficha de radar de la estación más cercana sobre una cuadrícula 2×2 — **Distancia · Media · Tiempo · Combustible usado**.

Nada se desplaza y nada es pequeño. Teléfono en el soporte, y no lo vuelves a tocar.

### Imagen en imagen

Reduce la app a una miniatura flotante y mantén encima tu navegación. La miniatura se adapta al contexto:

| Situación | Cifra grande | Línea secundaria |
|---|---|---|
| OBD2 conectado | L/100 km en vivo (L/h parado) | distancia · tiempo |
| Solo GPS, en marcha | distancia recorrida | tiempo |
| Arrancando | tiempo transcurrido | — |

### La superposición de aproximación

Al entrar en el radio configurado alrededor de una estación, la miniatura cambia a una gran visualización del **precio del combustible** — precio de tu calidad, marca, distancia, legibles de un vistazo.

Qué estación se fija se decide en **Ajustes → Conducción y consumo → Superposición al acercarse a una estación**: **la más cercana** (la primera cuyo radio has cruzado) o **la más barata del radio**. Al salir, la visualización del precio permanece cinco segundos de gracia, para que pasar cerca no haga parpadear la miniatura.

**Pruébalo sin conducir:** Ajustes → Herramientas de desarrollo → **Probar la superposición de aproximación** fuerza un estado sintético durante 30 segundos.

---

## Leer un viaje

*El resumen declara su propia procedencia — vehículo, adaptador, y una insignia **Traza GPS** en la distancia para saber de dónde salen los kilómetros.*

*La ruta está coloreada por eficiencia — verde por debajo de 6 L/100 km, ámbar hasta 10, rojo por encima. Dónde se fue el combustible, geográficamente.*

Ese coloreado es la vista más accionable de la app: pone sobre un mapa los tramos caros de tu trayecto diario. Un tramo rojo que se repite todos los días es un cruce, una cuesta o un hábito que merece la pena cambiar.

*Tres bloques: tu veredicto, la atribución del combustible, y cómo has exigido de verdad al motor.*

- **« ¿Cómo fue este viaje? »** — *Suave / Moderado / Agresivo*. Tu respuesta sirve para calibrar los umbrales de estilo de conducción con viajes reales, no para puntuarte.
- **Dónde se fue tu combustible** — litros atribuidos a aceleraciones fuertes frente a conducción normal. Números absolutos pequeños en un viaje corto; lo que cuenta es la proporción.
- **Posición del acelerador** y **régimen del motor** como distribuciones — la parte del viaje en punto muerto, carga ligera, firme y a fondo, y en cada banda de revoluciones. Una parte alta por encima de 3000 rpm en el trayecto al trabajo significa que subes marchas demasiado tarde, y eso cuesta.

*Dos diagnósticos: lo completa que es la traza GPS y cómo se ha portado el adaptador.*

*Desplegada, la ficha OBD2 se explica en claro.*

**Lee esta ficha antes de dudar de una cifra de consumo.** Indica cuántas muestras llevaban datos de motor, el **porcentaje de cobertura** resultante, el adaptador y el protocolo negociado, la duración de la sesión, por qué terminó (`userStopped`, una desconexión, una muerte del proceso), y la línea decisiva: *« Los valores de consumo vienen del adaptador, no de estimaciones GPS. »* Si la cobertura está muy por debajo del 100 %, los huecos se rellenaron con estimaciones GPS y la media del viaje es una mezcla.

*Velocidad, caudal y régimen sobre un eje de tiempo común — las tres curvas que explican cualquier cifra de consumo.*

*Carga del motor y acelerador uno al lado del otro muestran la diferencia entre hacer trabajar al motor y limitarse a subirlo de vueltas.*

*La altitud importa más de lo que se cree: una subida explica un pico de consumo que si no parecería mala conducción.*

Las acciones **compartir** y **eliminar** están en la barra superior. Compartir exporta el viaje con su traza GPX.

---

## Puntuación de conducción y coaching

Con adaptador, cada viaje se puntúa sobre 100 — un compuesto de ralentí, aceleraciones fuertes, frenadas bruscas, tiempo a alto régimen, plena carga, motor forzado a bajas vueltas, tirones, alta velocidad sostenida, agresividad en el pedal y riqueza de mezcla. El desglose nombra la conducta más cara: la puntuación es un diagnóstico, no un castigo.

La ficha **principales conductas derrochadoras** lo convierte en frases accionables — y muestra *« Ninguna ineficiencia notable — ¡sigue así! »* cuando no hay nada que corregir, en lugar de inventar un reproche.

El coaching también puede darse en marcha:

- **Coaching eco en tiempo real** — vibración ligera y consejo en pantalla cuando aceleras fuerte a velocidad de crucero.
- **Coaching de voz** — el mismo consejo leído en voz alta, para mantener los ojos en la carretera.
- **Glide-coach (beta)** — vibración discreta cuando conviene levantar el pie antes de un semáforo en rojo, con los semáforos de OpenStreetMap. **Desactivado por defecto: riesgo de distracción**, y necesita red para cargar los semáforos de tu zona.

*Ajustes → Conducción y consumo. Logros y puntuaciones se pueden ocultar en toda la app si la gamificación no es lo tuyo.*

---

## El panel de carbono

*Coste y CO₂ a partir de los mismos litros medidos, desglosados de dos formas.*

- **Por longitud de viaje** — los trayectos cortos suelen ser los más caros por kilómetro, porque un motor frío bebe. Verlo cuantificado es lo que lleva a agrupar recados.
- **Por banda de velocidad** — qué parte del combustible se va arrastrándose por la ciudad frente a rodar por autopista.

Está construido enteramente con datos de tu teléfono, y se activa en Funciones y modo de uso → Consumo.

---

## Exportaciones y diagnóstico

- **Compartir** un viaje concreto (resumen + GPX).
- **Exportar la traza de análisis de conducción** — los KPI de GPS, la puntuación y las lecciones del viaje en JSON, con un campo libre para describir cómo fue de verdad. Recompartirla ayuda a calibrar los umbrales de estilo con viajes reales. Función del modo desarrollador.
- **Exportar mis datos → Archivo ZIP** en Privacidad y datos → Exportar o eliminar incluye cada viaje y un GPX por viaje.

---

<details>
<summary>Vista completa — detalle de un viaje, página entera</summary>

</details>

---

**Ver también:** Vehículos y OBD2 · Registro de repostajes y consumo
**Siguiente:** Historial y previsiones de precios →

---

# Privacidad, datos y sincronización

Las promesas de privacidad de Sparkilo son comprobables, y esta es la página donde las compruebas.

---

## Privacidad por defecto

En concreto:

- **Sin Google Play Services. Sin Firebase. Sin Google Analytics. Sin identificadores publicitarios.**
- **Sin SDK de rastreo de terceros** — el `pubspec.yaml` público no tiene dependencias de analítica.
- **Sin cuenta necesaria.** La app es plenamente funcional sin ella.
- **Local-first.** Todo se queda en el teléfono hasta que actives algo.
- **Consentimiento antes del tratamiento**, más una explicación en lenguaje claro *antes* de cada solicitud del sistema.
- **Código abierto, MIT.** Las propias pruebas del proyecto fallan si la política y el código divergen.

### Qué sale realmente del teléfono

| Dato | A quién | Cuándo | ¿Evitable? |
|---|---|---|---|
| Coordenadas de búsqueda o código de región | El proveedor oficial de tu país | En cada búsqueda en vivo | Buscar por código postal en vez de GPS |
| Área del mapa + IP | El proxy UE de teselas del desarrollador, que recupera de OpenStreetMap | Uso del mapa | Desactivar el proxy — entonces OpenStreetMap ve tu IP directamente |
| Tu IP | logo.clearbit.com | Solo si activas los logotipos en línea | Dejarlo apagado (por defecto) |
| Trazas de fallo depuradas | Sentry | Solo con *Informes de errores* activado | Apagado por defecto |
| Tus filas sincronizadas | La base TankSync que hayas elegido | Solo con TankSync activo | Apagado por defecto |

**Tu identidad nunca forma parte de una consulta de precios**, y el desarrollador no opera ningún servidor que almacene tus búsquedas.

---

## Quién es el responsable del tratamiento

Depende enteramente de cómo uses TankSync:

| Modo | Responsable |
|---|---|
| **Sin TankSync** *(por defecto)* | **Solo tú.** Nada reside en ningún servidor operado por el desarrollador |
| **Tu proyecto Supabase** | **Tú** — el desarrollador nunca lo ve |
| **La base de un grupo** | **El propietario del grupo** que opera ese proyecto |
| **Sparkilo Community** | **El desarrollador, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. es el encargado; alojado en la UE (AWS eu-central-1, Fráncfort) |

La app indica el caso aplicable **antes** de conectar, y de nuevo en la fila *Modo de sincronización* de **Sincronización y cuenta**.

---

## La pantalla Privacidad y datos

**Ajustes → Privacidad y datos** es el único punto de entrada. Se abre con una tarjeta de resumen seguida de cuatro fichas temáticas:

| Línea o ficha | Qué te dice |
|---|---|
| *Tus datos se quedan en este dispositivo* / *Tus datos también se sincronizan con TankSync* | Dónde residen físicamente tus datos ahora mismo |
| *Sincronización: desactivada* / *Sincronización: activada · cuenta anónima* / *Sincronización: activada · cuenta de correo* | Si TankSync está conectado, y con qué tipo de cuenta |
| *… almacenados en este dispositivo* | El almacenamiento total que la app ocupa ahora |
| **Tus opciones** — *n de 5 activados* | Los cinco consentimientos y los dos controles de red |
| **Datos en este dispositivo** — *tamaño · n categorías* | Cada categoría guardada localmente, con tamaño y recuento |
| **Sincronización y cuenta** | Estado de TankSync, cuenta, base de datos y las acciones de sincronización |
| **Exportar o eliminar** — *ZIP, JSON, CSV · registro de errores (n)* | Las exportaciones, el registro de errores y la zona de peligro |

El antiguo *Panel de privacidad* ya no existe: sus contadores, sus datos de sincronización, sus exportaciones y su botón de borrado viven ahora bajo estos cuatro temas. Los enlaces antiguos y los widgets de pantalla de inicio que apuntaban al panel abren **Privacidad y datos** en su lugar.

---

## Tus opciones

*Los dos controles de red, cada uno descrito por lo que realmente filtra. Los cinco consentimientos están encima, en la misma tarjeta.*

Cada fila es un interruptor — *« Puedes cambiar tus opciones de privacidad en cualquier momento. »*

| Fila | Qué decide |
|---|---|
| **Acceso a la ubicación** | Encuentra estaciones de servicio cercanas usando tu ubicación. Desactivado: buscas por código postal |
| **Informes de errores** | Envía informes de fallos anónimos para mejorar la app. Desactivado por defecto — sin él nunca se sube nada |
| **Sincronización en la nube** | Sincroniza favoritos y alertas entre dispositivos — el consentimiento detrás de TankSync |
| **Decodificación de VIN en línea** | Decodifica el VIN mediante el servicio público gratuito de la NHTSA. Desactivado: tecleas tú los datos del vehículo |
| **Sincronizar grabaciones de viajes** | Haz una copia de seguridad de los viajes OBD2 + GPS en TankSync. En gris hasta que *Sincronización en la nube* esté activada |
| **Cargar los mosaicos del mapa a través del proxy de Sparkilo** | Activado: la zona visible del mapa y tu dirección IP llegan al servidor de la UE del desarrollador, que obtiene los mosaicos de OpenStreetMap. Desactivado: los mosaicos se cargan directamente desde tile.openstreetmap.org, que entonces ve tu IP |
| **Cargar logos de marcas desde internet** | Desactivado por defecto: se muestran marcadores de posición incluidos en la app. Activado: los logos se obtienen de logo.clearbit.com, que ve tu dirección IP |

Los dos controles de red llevan un botón de información (*Más información*) con la explicación completa. El pie registra *Consentimiento otorgado el … · versión … de la política* — la traza de auditoría que exige el RGPD — y enlaza a la **Política de privacidad** en tu idioma. Retirar un consentimiento detiene ese tratamiento de inmediato; los tratamientos anteriores siguen siendo lícitos.

---

## Datos en este dispositivo

*Almacenamiento detallado: una barra por categoría y luego una fila por categoría con su tamaño, su recuento y un punto del color de la barra. Las categorías vacías aparecen en gris, no se ocultan.*

Las filas bajo **Uso de almacenamiento en este dispositivo**: **Favoritos** · **Valoraciones de estaciones** · **Perfiles de búsqueda** · **Alertas de precio** · **Estaciones con historial de precios** · **Estaciones ignoradas** · **Usuarios bloqueados** · **Rutas guardadas** · **Cache** · **Ajustes** (*Clave API, perfil activo*) · **Total**.

Todo reside en **bases Hive cifradas**; la clave está en el Android Keystore / Llavero de iOS.

| Caja | Contenido |
|---|---|
| `settings` | Configuración, país, idioma, unidades |
| `profiles` | Tus perfiles de búsqueda |
| `favorites` | Estaciones guardadas con todos sus datos |
| `cache` | Respuestas de API e itinerarios en caché |
| `priceHistory` | Los registros locales de precios de 30 días |
| `price_snapshots` | Instantáneas para el uso sin conexión y el widget |
| `alerts` | Tus reglas de alerta |
| `service_reminders` | Recordatorios de mantenimiento |
| `obd2Baselines` | Referencias de consumo por vehículo |
| `obd2TripHistory` | Viajes: ruta, velocidad, sensores |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Cachés de capacidades del adaptador |

Las claves API, el token de GitHub y la sesión de TankSync viven en la caja fuerte de hardware, no en Hive.

### Detalles de la caché

*La ficha **Detalles de la caché** despliega la vida útil de cada clase en caché — búsquedas 5 min, detalles de estación 15 min, consultas de precios 5 min, datos de favoritos 30 min, búsquedas de ciudad 30 min, geocodificación de código postal 24 h — y el botón **Limpiar caché**.*

La caché almacena respuestas API para una carga más rápida y acceso sin conexión. Limpiarla borra solo los resultados y precios en caché — perfiles, favoritos y ajustes quedan intactos; las siguientes búsquedas son más lentas, nada se pierde. El botón muestra *La caché está vacía* y queda desactivado cuando no hay nada que limpiar.

### Usuarios bloqueados

**Usuarios bloqueados** es la única fila pulsable: abre la lista de cuentas que bloqueaste, cada una con un botón **Desbloquear**. El contenido compartido por esas cuentas se oculta en este dispositivo; el bloqueo es local — no denuncia la cuenta.

---

## Permisos

| Permiso | Para qué | ¿Rechazable? |
|---|---|---|
| **Ubicación** *(mientras se usa)* | Búsqueda cercana, inicio de ruta, grabación | Sí — usar un código postal |
| **Ubicación** *(« Permitir siempre »)* | **Solo** la grabación automática OBD2, para que la ruta siga con la pantalla apagada | Sí — iniciar los viajes a mano |
| **Búsqueda + conexión Bluetooth** | Emparejamiento del adaptador | Sí — el OBD2 es opcional |
| **Notificaciones** | Alertas de precio | Sí — las alertas no saltarán |
| **Cámara** | OCR en el dispositivo de surtidores, recibos y QR | Sí — teclear a mano |
| **Internet** | Llamadas de precios y mapa | Necesario |

Hasta Android 11 el sistema exige la **ubicación** para cualquier barrido Bluetooth — regla de plataforma, no una decisión de rastreo. Cualquier permiso se revoca luego en los ajustes del sistema; la función correspondiente simplemente se detiene.

---

## Sincronización y cuenta

*Accesible desde la ficha Privacidad y datos y directamente desde la raíz de Ajustes. La pantalla también saca a la luz los problemas — aquí un esquema autoalojado obsoleto que, por tanto, deja de sincronizar algunas tablas en silencio.*

Bajo activación. *Desactivado* significa que nada se guarda en ningún servidor, en ningún sitio. La tarjeta de resumen de arriba expone los hechos:

| Fila | Valor |
|---|---|
| **Estado** | *Conectado* o *Desactivado* |
| **Modo de sincronización** | *Comunidad Sparkilo: el servidor del desarrollador en la UE* · *Grupo compartido: una base de datos a la que te has unido* · *Autoalojado: tu propio Supabase* |
| **Cuenta** | *Cuenta anónima, vinculada a este dispositivo* o *Cuenta de correo: …* |
| **ID de usuario** | Tu UUID, con un botón de copia — cítalo en una solicitud de soporte |
| **Servidor de la base de datos** | El nombre de host de la base a la que sincronizas; la clave nunca se muestra |
| **Compartir perfiles de vehículo aprendidos** | Sube las referencias de consumo por vehículo para que un segundo dispositivo pueda reutilizarlas |

### Tres formas de despliegue

1. **Sparkilo Community** — la base compartida que opera el desarrollador (Supabase, UE/Fráncfort). Tu cuenta es un UUID aleatorio; puedes vincular un correo para alcanzarla desde otro dispositivo. Los informes comunitarios y las valoraciones compartidas públicamente son legibles por cualquier usuario conectado.
2. **Tu proyecto Supabase** — el esquema SQL y las Edge Functions están en el repositorio. Tú eres el responsable y conservas la plena propiedad.
3. **La base de un grupo** — conéctate al proyecto de familiares o amigos. Esa persona es la responsable.

### Configuración

**Sincronización y cuenta → Configurar la sincronización en la nube.** Para Community, escanea el QR del wiki o pega URL y clave anon; para un proyecto propio o de grupo, pega URL del proyecto y clave anon. Ambos se guardan en la caja fuerte de hardware, y los endpoints en HTTP simple se rechazan.

> **Quien se autoaloja:** tras una actualización la pantalla puede avisar de que tu **esquema está obsoleto**. Reejecuta el SQL de instalación que ofrece — de lo contrario la sincronización de las tablas nuevas falla **en silencio**, lo que es mucho peor que un error visible.

### Acciones una vez conectado

- **Cambiar a correo electrónico** — conserva los datos y añade el inicio de sesión desde otros dispositivos; el UUID no cambia. **Cambiar a anónimo** hace lo contrario.
- **Consentimientos** — un enlace cruzado a *Tus opciones*: los consentimientos de sincronización en la nube y de viajes viven allí, no aquí.
- **Ver mis datos** — la pantalla *Transparencia de datos* lista las filas que el servidor guarda de ti; su botón **Olvidar todos los viajes sincronizados** limpia solo las filas de viajes.
- **Vincular dispositivo** — incorpora un segundo teléfono a la misma cuenta.
- **Eliminar datos sincronizados** — elige *Viajes*, *Vehículos*, *Repostajes* o *Todo* para quitarlos de la base de sincronización; las copias locales se conservan.
- **Compartir base de datos** — un código QR para que familiares o amigos se unan a tu propia base o a la de un grupo (no se ofrece en Community).
- **Desconectar** — deja de sincronizar; los datos locales se conservan.
- **Eliminar cuenta** — borra todos los datos del servidor de forma permanente y luego la propia identidad de la cuenta, correo vinculado incluido. Se ofrece para las bases propias y de grupo; en Community usa *Eliminar datos sincronizados → Todo* o la zona de peligro descrita más abajo.

### Qué se sincroniza

Favoritos · alertas de precio · estaciones ignoradas · valoraciones (con indicador de privacidad por valoración: local / privada sincronizada / compartida públicamente) · itinerarios · vehículos incluidos VIN e identificador del adaptador · repostajes y registros de recarga · referencias de consumo · informes comunitarios y de contenido que envíes.

**Los viajes van aparte.** Su sincronización sigue siendo opcional *incluso después* de activar la Sincronización en la nube — el interruptor *Sincronizar grabaciones de viajes* permanece en gris hasta entonces. En el servidor los resúmenes permanecen hasta que los borres; las muestras GPS detalladas se purgan a los 90 días.

Cada tabla está protegida por seguridad a nivel de fila: una cuenta solo puede leer o borrar sus propias filas. Las valoraciones compartidas y los informes comunitarios son las únicas filas visibles para otros usuarios conectados.

### Conflictos

**Lo local siempre gana.** La sincronización añade y actualiza, pero nunca borra en silencio — solo tu borrado explícito provoca un borrado en el servidor, que luego se propaga a tus otros dispositivos.

---

## Exportar o eliminar

Un botón, una hoja de formatos, una zona roja. **Exportar mis datos** abre *Elige un formato*:

| Formato | Pista en la hoja | Qué obtienes |
|---|---|---|
| **Archivo ZIP** | *Todo, adjuntos incluidos: para una copia de seguridad completa* | `sparkilo-my-data-<fecha>.zip`: un JSON legible por máquina por categoría — favoritos, alertas, perfiles, rutas, historial de precios, vehículos, repostajes, viajes con muestras GPS y un GPX por viaje, referencias, recordatorios de mantenimiento, registros de recarga, logros y tu traza de consentimiento — más cada tabla del servidor si TankSync está conectado |
| **JSON** | *Legible por máquinas: para otra app* | `tankstellen-data.json`: las categorías del dispositivo en un solo fichero plano, copiado también al portapapeles |
| **CSV** | *Hoja de cálculo: una tabla por categoría* | `tankstellen-data.csv`: un bloque `# table` por categoría — favoritos, alertas, historial de precios y el resto — copiado también al portapapeles |

Todas las exportaciones aterrizan en tu carpeta **pública de Descargas** (*Guardado en la carpeta Descargas*), para que cualquier gestor de archivos las encuentre.

**Registro de errores** muestra cuántas trazas depuradas guarda la app (*Sin entradas* … *n entradas*). **Guardar** las escribe en Descargas para un informe de fallo — sin correos, coordenadas, claves ni tokens dentro, y nunca se sube nada automáticamente; **Borrar** vacía el registro.

**Zona de peligro** — *Elimina de forma permanente todo lo que la app guarda en este dispositivo. Con la sincronización activada, tus datos en el servidor de TankSync también se borran.* **Eliminar todos mis datos** pide confirmación y lista lo que se va: favoritos y datos de estaciones, perfiles de búsqueda, alertas de precios, historial de precios, datos en caché, tu clave de API, todos los ajustes de la app. Con TankSync conectado borra primero tus filas del servidor; si alguna tabla no pudo borrarse, la app **te dice cuál** en lugar de proclamar el éxito. Después la app vuelve a la configuración de primer arranque. Irreversible.

Para una instantánea restaurable en vez de una exportación de datos, usa **Ajustes → Copia de seguridad y restauración** — ver Referencia de ajustes.

---

## Tus derechos según el RGPD

Cada derecho de los artículos 15–22 tiene un botón. Sin necesidad de solicitud de soporte.

- **Acceso** — *Datos en este dispositivo* lista cada categoría del dispositivo; *Ver mis datos* lista cada fila de tu base TankSync.
- **Portabilidad** — *Exportar mis datos* como archivo ZIP.
- **Rectificación** — edita cualquier entrada en el sitio; el cambio se sincroniza si TankSync está activo.
- **Supresión**
  - *Dispositivo:* **Exportar o eliminar → Eliminar todos mis datos**.
  - *Servidor:* **Sincronización y cuenta → Eliminar cuenta** borra cada fila de tu propiedad **en una transacción** — favoritos, alertas, estaciones ignoradas, informes de precio y contenido, vehículos, repostajes, itinerarios, referencias, valoraciones, viajes, compartidos de viaje dados y recibidos, ajustes de sincronización, trazas de borrado y tu fila de usuario — y luego la propia identidad de la cuenta, correo vinculado incluido. Si alguna tabla no pudo borrarse, la app **te dice cuál** en lugar de proclamar el éxito.
  - *Elementos sueltos:* todo es borrable por separado; **Eliminar datos sincronizados** quita viajes, vehículos o repostajes del servidor, y **Olvidar todos los viajes sincronizados** limpia solo las filas de viajes.
- **Retirada del consentimiento** — Privacidad y datos → Tus opciones; el tratamiento cesa de inmediato.
- **Limitación / oposición** — desactiva TankSync, la sincronización de viajes, el proxy de teselas o el diagnóstico; revoca permisos en los ajustes del sistema.
- **Reclamación** — ante una autoridad de control, en particular la de tu residencia, lugar de trabajo o de la supuesta infracción. Al desarrollador le gustaría poder resolverlo antes: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

Si ya no puedes abrir la app, pide la supresión por correo desde la dirección vinculada a la cuenta. **Una cuenta anónima nunca vinculada a un correo no puede ser identificada por nadie — ni por el desarrollador — sin el dispositivo que la creó.** Es el precio de no pedirte registro.

Texto completo: **[Política de privacidad v3, 29 de agosto de 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**, disponible en los 23 idiomas de la app ([Deutsch](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/), [Français](https://fdittgen-png.github.io/tankstellen/privacy-policy/fr/), …). La app recuerda a qué versión consentiste y la vuelve a mostrar cuando cambia.

---

**Ver también:** Referencia de ajustes · Cómo funciona Sparkilo → Dónde viven tus datos
**Siguiente:** Solución de problemas y FAQ →

---

# Referencia de ajustes

Cada pantalla del árbol de ajustes y — más útil — **cuánto te cuesta cada interruptor** en batería, datos, precisión o privacidad.

---

## La forma del conjunto

Los ajustes son un **árbol de dos niveles**: una raíz de fichas temáticas, una pantalla por tema, y una búsqueda por palabra clave sobre todas.

*Escribe « radio », « OBD2 » o « tema » en el campo de búsqueda y la ficha correspondiente emerge — no hace falta recordar qué tema posee un parámetro.*

*Doce temas en total. Para llegar: el engranaje arriba a la derecha de las pantallas principales.*

Tres reglas de diseño hacen el árbol predecible:

1. **Una casa por parámetro.** Nada aparece dos veces; las referencias cruzadas apuntan al único propietario.
2. **Etiquetas de alcance.** Una ficha marcada *este perfil*, *todos los perfiles* o *este vehículo* dice de antemano hasta dónde llega un cambio.
3. **Estados vacíos honestos.** Una sección con la función apagada lo dice y enlaza al interruptor, en lugar de esconderse.

---

## Perfiles y región

*País, idioma, combustible, radio de búsqueda, rutas · alcance: este perfil*

*El combustible preferido se deriva del vehículo por defecto. Para elegirlo directamente, quita el vehículo del perfil.*

| Ajuste | Impacto |
|---|---|
| **Nombre del perfil** | Cosmético, pero es lo que muestra el chip de perfil |
| **Combustible preferido** | El precio destacado de cada ficha; el predeterminado de las alertas; para qué optimiza la búsqueda de ruta |
| **Radio por defecto** | Mayor = más resultados y búsquedas más lentas |

*Valores por defecto de la ruta. **Candidatas por punto de muestreo** intercambia minuciosidad por velocidad en corredores largos.*

*Tres cosas distintas que conviene conocer.*

- **Evitar autopistas** cambia la ruta calculada en sí: las áreas de servicio dejan de ser candidatas — en general un ahorro, ya que el combustible de autopista es el más caro de cualquier corredor.
- **Notas de estación** — *Local* (solo este dispositivo), *Privado* (sincronizado en tu cuenta) o *Compartido* (visible para otros usuarios). Es una decisión de privacidad, no de almacenamiento.
- **Pantalla de inicio** — con qué se abre la app: Cerca, Estación más cercana, Favoritos o Mapa.

*El radio de la superposición y la regla **más cercana vs más barata del radio** viven en el perfil: un perfil « diario » y uno « vacaciones » pueden comportarse distinto.*

*El país decide el proveedor de datos. Cambiarlo vacía los datos de estaciones en caché.*

*Un **código postal de casa** permite búsquedas por zona sin GPS alguno — la forma más limpia de usar la app si nunca quieres compartir tu ubicación.*

---

## Vehículos y OBD2

*Tus coches, capacidad del depósito, emparejamiento · alcance: este vehículo*

*Los adaptadores se emparejan por vehículo: la ficha del adaptador te lleva dentro de un vehículo en lugar de a una pantalla global.*

El tratamiento completo — VIN, capacidad, flex-fuel, modos de calibración, referencia, umbrales de grabación automática, recordatorios — está en Vehículos y OBD2.

---

## Conducción y consumo

*Coaching, recompensas, radar, resolución de problemas · alcance: mixto*

*Las dos primeras entradas son las que ajustarás de verdad.*

| Ajuste | Impacto |
|---|---|
| **Ventana de consumo en directo** (3/5/10/30 s) | Más larga = más estable y legible al volante; más corta = lo bastante reactiva para enseñar lo que cuesta el pedal |
| **Superposición al acercarse** | Radio, modo de precio, suelo de consulta y anclado de pantalla para el perfil activo |
| **Coaching eco en tiempo real** | Vibración ligera + consejo en pantalla al acelerar fuerte en velocidad de crucero |
| **Coaching de voz** | El mismo consejo leído en voz alta — los ojos siguen en la carretera |
| **Glide-coach beta** | Aviso háptico antes de un rojo con los semáforos de OpenStreetMap. **Apagado por defecto — riesgo de distracción**, y necesita red |

*Recompensas y resolución de problemas.*

- **Tarjetas de fidelidad** — descuentos por litro aplicados en las comparaciones de precio, así una estación nominalmente más cara puede resultar correctamente más barata para ti.
- **Mostrar logros y puntuaciones** — apagado, insignias, puntuaciones y trofeos desaparecen de toda la app. Nada deja de medirse; deja de mostrarse.
- **Registro de depuración OBD2** — graba cada sesión (conexión, saludo, pérdidas de datos, reconexiones) en un registro XML exportable. **Apagado por defecto**: escribe continuamente y solo compensa mientras se persigue un problema del adaptador.

---

## Precios y alertas

*Alertas, anuncios de voz, historial, informes comunitarios*

*El bloque gris de los anuncios de voz es un estado vacío honesto: nombra los dos interruptores necesarios y dónde están.*

| Ajuste | Impacto |
|---|---|
| **Alertas de precio** | Abre la lista; la funcionalidad es un interruptor en Funciones y modo de uso |
| **Historial de precios** | Registro local de 30 días. Apagado = sin gráficos, sin « mejor momento » |
| **Predicción de precios TFLite** | Modelo en el dispositivo; características y predicciones nunca salen del teléfono |
| **Informes de precio comunitarios** | Requiere TankSync; tus informes son visibles para otros usuarios conectados |
| **Escanear el QR de pago** | Añade el lector de QR al detalle de las estaciones |

---

## Unidades y visualización

*Tema, unidad de distancia, unidad de consumo, widget · alcance: mixto*

*La **unidad de consumo** se propaga a todas partes de golpe — banner en vivo, miniatura, medias de viaje, estadísticas, widget.*

- **Unidad de distancia** sigue por defecto al país del perfil activo (km o millas).
- **Unidad de consumo**: *Automático* (mpg en Reino Unido y EE. UU., L/100 km en el resto), o explícitamente L/100 km, km/L o mpg.

*Las opciones del widget llevan la etiqueta **este perfil** y se aplican a todo widget instalado que muestre ese perfil, desde el siguiente refresco.*

**Variante de contenido** — *solo precio actual*, o *predictivo: mejor momento para repostar* (requiere la predicción TFLite).

---

## Funciones y modo de uso

*Preajustes y cada interruptor individual*

*Elegir un preajuste **sobrescribe** cada interruptor individual. Si has ajustado a mano, quédate en Personalizado.*

Las dependencias se aplican, no se ocultan: un interruptor con el requisito apagado queda desactivado y nombra ese requisito.

*Búsqueda y mapa — incluido si gasolineras y puntos de recarga aparecen siquiera.*

*Precios y alertas. El historial es la función padre de la predicción que le sigue.*

*El radar, sus anuncios de voz y el interruptor principal **Respuesta hablada** — apagado, la app nunca abre un motor de síntesis.*

*El selector **Apagado / Combustible / Combustible + Viajes** es la forma compacta de toda la pila de consumo.*

| Interruptor | Impacto |
|---|---|
| **Estadísticas de consumo** | La pestaña de análisis de repostajes y viajes |
| **Gamificación** | Puntuaciones de conducción e insignias ganadas |
| **Eco-coach háptico** | Respuesta vibratoria en tiempo real al volante |
| **Glide-coach** | Consejos eco desde los semáforos de OpenStreetMap — necesita red |
| **Traza GPS de viajes** | Guarda los puntos de ruta de cada viaje. Apagado = base más pequeña, sin mapas de viaje |
| **Grabación automática** | Inicia un viaje cuando el adaptador emparejado se conecta a un vehículo en movimiento |

*Dos interruptores aquí cambian la calidad de los datos en vez de la interfaz.*

- **PID OEM experimentales** — lee el nivel exacto del depósito en litros mediante PID del fabricante en adaptadores compatibles. Mejores datos donde funciona; inofensivo donde no.
- **Exigir OBD2 para la grabación de viajes** — **apagado**, los viajes se graban solo con GPS. El coaching es reducido (sin L/100 km instantáneos, menos señales de motor) pero nada queda bloqueado.
- **Sincronización de referencias** — sube las referencias de consumo por vehículo para que un segundo dispositivo las reutilice. Requiere TankSync.

*Entrada y escaneo. El reconocimiento es en el dispositivo; estos interruptores solo deciden si los atajos existen.*

*Desarrollador y experimental — se puede dejar apagado salvo que informes de fallos.*

---

## Fuentes de datos y ubicación

*Claves API, GPS, cambio automático de perfil*

*Una cruz roja en la clave de precios es el motivo habitual de una búsqueda alemana vacía.*

| Ajuste | Impacto |
|---|---|
| **Precios de combustible (Tankerkoenig)** | Necesaria solo para Alemania. Gratuita, por usuario, en la caja fuerte de hardware |
| **Recarga EV (OpenChargeMap)** | Opcional — sustituye la clave compartida por tu propia cuota |
| **Actualización automática** | Refresca la posición GPS antes de cada búsqueda. Apagado = búsquedas más rápidas, posición quizá antigua |
| **Cambio automático de perfil** | Conmuta el perfil al cruzar una frontera, para que proveedor y combustible sean correctos automáticamente |

---

## Sincronización y cuenta

*Esta pantalla también saca a la luz los problemas — aquí un esquema TankSync autoalojado obsoleto que, por eso, falla en silencio al sincronizar algunas tablas.*

Tratado por extenso en Privacidad, datos y sincronización → TankSync. Lo esencial:

- **Sparkilo Community / tu propia base / la base de un grupo** — tres formas de despliegue con tres responsables distintos.
- **Anónimo → correo** — *Pasar al correo* conserva tus datos y tu cuenta y añade una forma de iniciar sesión desde otro dispositivo. Una cuenta anónima solo existe en el dispositivo que la creó.
- **Esquema obsoleto** — tras una actualización, quien se autoaloja debe reejecutar el SQL de instalación, o las tablas nuevas fallan en silencio.

---

## Privacidad y datos

*Dos decisiones de privacidad ligadas a la red, cada una expresada por lo que realmente revela.*

- **Cargar las teselas por el proxy Sparkilo** — *activado*: el servidor UE del desarrollador ve el área del mapa y tu IP y recupera las teselas por ti. *Apagado*: las teselas vienen de tile.openstreetmap.org, que entonces ve tu IP. Ninguna opción significa « sin red »; eliges por quién ser visto. La versión F-Droid nunca usa el proxy.
- **Cargar los logotipos de marca desde internet** — *apagado* por defecto; se usan logotipos genéricos incluidos. Activado, vienen de logo.clearbit.com, que ve tu IP.

*El almacenamiento, desglosado. La caché es casi siempre la porción mayor y la única que se puede tirar sin riesgo.*

*Gestión de la caché, con la vida de cada clase: búsquedas 5 min, detalles de estación 15 min, consultas de precio 5 min, datos de favoritos 30 min, búsquedas de ciudad 30 min, geocodificación de código postal 24 h.*

*Vaciar la caché borra solo resultados y precios almacenados — perfiles, favoritos y ajustes se conservan. Las siguientes búsquedas serán más lentas; no se pierde nada.*

---

## Copia de seguridad y restauración

*Un ZIP completo con vehículos, repostajes, viajes y registros de recarga.*

**Exportar copia** escribe el ZIP en tus Descargas. **Restaurar copia** ofrece *fusionar* o *reemplazar* — fusionar conserva lo que hay en el dispositivo y añade lo que falta; reemplazar borra primero. Úsalo antes de cambiar de teléfono o de un restablecimiento de fábrica. TankSync no es una copia de seguridad: replica categorías escogidas, no todo.

---

## Avanzado y desarrollador

*El token de GitHub es opcional — sin él, un informe de escaneo fallido se comparte a mano en lugar de abrir automáticamente una incidencia.*

La entrada **Herramientas de desarrollo** solo aparece con el modo desarrollador activo (Funciones y modo de uso → Desarrollador y experimental).

*Para un usuario normal el registro de errores es la parte útil: **Guardar el registro de errores** escribe trazas depuradas en Descargas, para adjuntar a un informe.*

*La traza de arranque es una cascada de las fases de inicialización — así se diagnostica un arranque lento en vez de adivinarlo.*

***Probar la superposición de aproximación** fuerza un estado sintético durante 30 s para verificar la visualización de precio superpuesta sin salir a conducir.*

---

## Acerca de

***Versión y número de compilación** — cítalos ambos en cualquier informe, y compruébalos primero cuando una corrección « no ha funcionado » (puede que el despliegue de la tienda no te haya llegado aún).*

*La app es gratuita, de código abierto y sin publicidad. Las atribuciones de los datos de precios y de mapa están al pie, como exigen las licencias.*

---

**Ver también:** Cómo funciona Sparkilo · Privacidad, datos y sincronización
**Siguiente:** Privacidad, datos y sincronización →

---

# Solución de problemas y FAQ

Ordenado aproximadamente por frecuencia real.

---

## Antes de nada: comprueba tu versión

*Ajustes → Acerca de. Cita **ambos** en cualquier informe.*

Buena parte de los « sigue sin funcionar » es un despliegue de tienda que aún no ha llegado al dispositivo. Si el número de compilación es anterior a la versión con la corrección, no hay nada que depurar.

---

## « No se han encontrado precios »

1. **Comprueba el país del perfil.** Un perfil alemán llama a la API alemana; en España no encontrará nada. Ajustes → Perfiles y región → Región.
2. **Alemania: ¿está puesta la clave API?** Ajustes → Fuentes de datos y ubicación — una cruz roja en *Precios de combustible (Tankerkoenig)* es la respuesta.
3. **¿Estás sin conexión?** Los precios en vivo requieren una llamada de red. Los precios en caché siguen visibles, marcados como obsoletos.
4. **Caída del proveedor.** Los servicios públicos de datos abiertos se caen a veces. Reinténtalo en unos minutos.
5. **Caché obsoleta.** Tira para actualizar, o toca el icono de refresco.

---

## Alemania: « Falta la clave API » o « Clave no válida »

- Consigue una clave gratuita en [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); es un UUID.
- Pégala en **Ajustes → Fuentes de datos y ubicación → Precios de combustible (Tankerkoenig)**.
- ¿Sigue fallando? La clave puede estar limitada. Las claves son personales — no las publiques nunca.

---

## No encuentro el botón de búsqueda

Solo hay uno: el botón verde elevado en el centro de la barra inferior. Desde cualquier pestaña abre la hoja de criterios; dentro de la hoja, un segundo toque ejecuta la búsqueda. Si parece atenuado, estás en **modo ruta sin destino**.

---

## La ubicación es « desconocida » o el GPS no engancha

- La ubicación del sistema debe estar activa, con **Mientras se usa** concedido a la app.
- El GPS no engancha en interiores. Sal fuera, o define un **código postal de casa** en el perfil y busca por zona.
- « Solo ubicación aproximada » — activa la ubicación precisa en los permisos del sistema.

---

## El cálculo de ruta es lento o falla

- OSRM es un servicio público gratuito y a veces lento.
- Un corredor multipaís **transmite resultados parciales**; el aviso nombra los proveedores pendientes, y puedes tocar un resultado antes de que lleguen los demás.
- Reinténtalo — la polilínea está en caché, el segundo intento suele ser inmediato.

---

## El adaptador OBD2 no conecta

**No encuentra nada al buscar**

- El contacto debe estar **puesto** (accesorios o marcha). Motor en marcha vale, contacto quitado no.
- El LED del adaptador debe estar fijo. Parpadeante o apagado → vuelve a enchufarlo.
- Bluetooth activo en el teléfono.
- Android 12+: concede **Búsqueda Bluetooth** y **Conexión Bluetooth**.
- Hasta Android 11: el sistema exige la **ubicación** para enumerar dispositivos Bluetooth. Regla de plataforma, no rastreo.

**Lo encuentra, pero la conexión falla**

- *« No responde »* — clon barato. Espera 30 s y reinténtalo; arrancar brevemente el motor suele ayudar.
- *« Fallo de inicialización del protocolo »* — chip ELM327 falsificado. Prueba otro modelo; el vLinker FS es la opción barata fiable.
- *« Permiso denegado »* — vuelve a concederlo en los ajustes del sistema; algunas versiones de Android olvidan los permisos Bluetooth tras un reinicio.

**Conecta y luego se cae en marcha**

Usa **Restablecer la conexión** en la ficha del adaptador del vehículo — repite el saludo sin olvidar el emparejamiento. Si persiste, activa **Ajustes → Conducción y consumo → Registro de depuración OBD2**, haz un viaje, exporta el registro XML y adjúntalo a una incidencia. Luego desactiva el registro.

**El cuentakilómetros marca 0 o está mal**

Tu coche puede no publicar el PID A6. La app reintenta con el PID 31 y el modo 22 del fabricante. Algunos europeos anteriores a 2008 no publican cuentakilómetros por OBD2 — entonces tecléalo en cada repostaje.

---

## La grabación automática no ha saltado

Necesita todo esto:

1. Un adaptador **emparejado a un vehículo**.
2. **Grabación automática** activa para ese vehículo.
3. El permiso de ubicación **« Permitir siempre »**.
4. Bluetooth activo y ninguna optimización de batería que mate la app.

Comprueba también el **umbral de velocidad de inicio** en el editor de vehículo — una salida al paso desde un aparcamiento puede no alcanzarlo nunca.

> **iOS:** el despertar de sistema para « conectar en cuanto el adaptador se enciende » aún no existe ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). En iOS inicia los viajes a mano.

---

## Mi consumo parece equivocado

Ve en este orden:

1. **Abre el viaje y lee la ficha de salud de la comunicación OBD2.** Si la cobertura está muy por debajo del 100 %, los huecos se rellenaron con estimaciones GPS y la media es una mezcla, no una medida.
2. **Mira el informe del depósito en la pestaña Viajes.** Si dice que las estimaciones están un *n* % por encima o por debajo de la verdad del surtidor, la app ya lo sabe y acaba de corregirse — espera movimiento en los próximos viajes.
3. **Comprueba la capacidad del depósito** en el vehículo. Una capacidad errónea produce durante meses autonomías creíbles pero equivocadas.
4. **Comprueba tus kilometrajes.** El consumo es litros ÷ kilómetros, y los kilómetros vienen enteramente de lo que tecleas.
5. **Comprueba si marcaste « Depósito lleno ».** Solo las ventanas de lleno a lleno pueden calibrar algo.
6. **Mira la insignia de precisión** en la pestaña Combustible. *Baja* significa que nada ha anclado aún el modelo — la cifra es una salida de modelo, y lo declara.

Contexto: Cómo funciona Sparkilo → Cómo un litro se convierte en un número.

---

## « Hemos encontrado un desfase de X litros »

Has repostado más de lo que tus viajes grabados explican. Responde a las dos preguntas de la reconciliación: un repostaje ausente o mal tecleado recibe una **entrada de corrección**, un trayecto no grabado recibe un **viaje virtual**. Ambos siguen siendo editables. Dejarlo sin resolver sesga la calibración, así que dos toques valen la pena. Ver Registro de repostajes y consumo.

---

## La miniatura superpuesta no muestra un precio

La superposición de aproximación solo salta mientras **se graba un viaje** *y* estás dentro del radio. Para verificar la presentación sin conducir: **Ajustes → Herramientas de desarrollo → Probar la superposición de aproximación** fuerza un estado sintético durante 30 segundos.

---

## Las notificaciones de alerta no llegan

- ¿Están permitidas las notificaciones del sistema para la app?
- Ahorro de batería: los modos agresivos de Android matan el trabajo de fondo. Pon la app en **sin restricciones**.
- El teléfono pudo estar sin conexión en la franja prevista; la comprobación se retoma en la siguiente ventana de red.
- El precio quizá simplemente no ha cruzado el umbral.
- El sello **Última comprobación** al pie de la pantalla de alertas dice si la tarea se ejecuta. Sello viejo + cero disparos = el sistema la está matando.

---

## El widget de pantalla de inicio está congelado

- Android limita las actualizaciones de widget a una cada 30 minutos aproximadamente; es política del sistema.
- Toca el **icono de refresco del propio widget** — recarga los precios sin abrir la app.
- Aspecto y variante de contenido se fijan por perfil en **Ajustes → Unidades y visualización**.

---

## El mapa muestra teselas grises o vacías

- Suele ser una conexión débil; desliza para refrescar.
- Si persiste, los servidores de teselas pueden estar limitando — reinténtalo en unos minutos.
- Prueba a conmutar **Ajustes → Privacidad y datos → Cargar las teselas por el proxy Sparkilo**; los dos caminos fallan de forma independiente.

---

## El escaneo de surtidor o recibo no lee nada

- La versión **F-Droid** no tiene escaneo alguno — el reconocimiento de texto en el dispositivo solo existe en las versiones de Play / App Store. Teclea el repostaje a mano.
- El reflejo en el display del surtidor es la causa más común. Haz sombra, colócate de frente, llena el encuadre con las cifras.
- Si lee las etiquetas pero no los números, usa **Informar de error de escaneo** para que el recorte sirva para mejorar el reconocimiento.

---

## La app tarda mucho en arrancar

Activa **Traza de inicialización al arranque** (Funciones y modo de uso → Desarrollador y experimental), reinicia y abre las **Herramientas de desarrollo**. La cascada nombra la fase lenta; expórtala y adjúntala a una incidencia.

*Cada barra es una fase de inicialización con su duración — un arranque lento deja de ser una suposición.*

---

## La app se cierra al arrancar

- Vacía la caché desde los ajustes de aplicaciones del dispositivo.
- Si persiste, abre una incidencia con la versión de Android, el modelo del teléfono, la versión **y el número de compilación** de Ajustes → Acerca de, y el registro de errores guardado (la app lo ofrece en el siguiente arranque; el archivo va a Descargas).

---

## ¿Cómo hago copia de seguridad?

**Ajustes → Copia de seguridad y restauración → Exportar copia** escribe un ZIP en Descargas; la restauración ofrece fusionar o reemplazar. Para una exportación legible por máquina, usa en su lugar **Privacidad y datos → Exportar o eliminar → Exportar mis datos → Archivo ZIP**.

TankSync **no** es una copia de seguridad — replica categorías escogidas, y los viajes solo si también activaste su sincronización.

---

## ¿Cómo lo borro todo?

- **Dispositivo:** Privacidad y datos → Exportar o eliminar → **Eliminar todos mis datos**. Irreversible.
- **Servidor (TankSync):** borra primero el lado servidor — Sincronización y cuenta → Transparencia de datos → **Eliminar cuenta** quita cada fila de tu propiedad en una transacción y nombra cualquier tabla que no se haya podido borrar.

Detalles: Privacidad, datos y sincronización → Tus derechos.

---

## ¿Puedo usar la app sin conexión?

En parte. Los favoritos muestran sus últimos precios conocidos, las teselas vistas recientemente están en caché, y repostajes y viajes son enteramente locales. Descubrir estaciones nuevas requiere una llamada de red.

---

## ¿Dónde se ha ido la pestaña Combustible o Viajes?

Pertenecen a los modos **Intermedio** y **Completo**. Si una ha desaparecido, un preajuste o un interruptor la ha apagado: Ajustes → Funciones y modo de uso → Consumo.

---

## Más ayuda

- **Fallos:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — usa la plantilla Bug Report y adjunta el registro de errores guardado.
- **Ideas:** la plantilla Feature Request, o primero las [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Dudas de privacidad:** la [política de privacidad](https://fdittgen-png.github.io/tankstellen/privacy-policy/), o fdittgen@gmail.com.

---

**Volver a:** la portada de la guía
