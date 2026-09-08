# Primeros pasos

Diez minutos desde la instalación hasta el primer euro ahorrado. Si después lees una sola página más, que sea [Cómo funciona Sparkilo](User-es-How-It-Works).

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

<img src="screenshots/privacy-consent.png" width="340" alt="Pantalla de consentimiento del primer arranque con cada finalidad">

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

Ambos se detectan del idioma del sistema, y ambos viven **en el perfil** — ver [Cómo funciona Sparkilo → Perfiles](User-es-How-It-Works#perfiles-un-contexto-un-juego-de-valores-por-defecto).

<img src="guide/profile-edit-6.jpg" width="340" alt="Selector de idioma y código postal de casa en el editor de perfil">

*Ajustes → Perfiles y región → editar perfil. El código postal de casa permite buscar en una zona fija sin ceder nunca el GPS.*

Cambiar de país **vacía los datos de estaciones en caché**, porque los precios del proveedor anterior no valen para el nuevo país. La siguiente búsqueda tardará un instante más.

---

## 4. Elegir un modo de uso

Es el ajuste de mayores consecuencias, porque decide cuánta aplicación obtienes.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Preajustes Básico, Intermedio, Completo, Personalizado">

*Ajustes → Funciones y modo de uso. Empieza en **Básico** si solo quieres combustible más barato; sube cuando quieras saber por qué tu coche bebe.*

- **Básico** — encontrar combustible y recarga, favoritos, alertas, rutas.
- **Intermedio** — añade la pestaña **Combustible**: registrar repostajes, ver consumo y coste reales. Sin hardware.
- **Completo** — añade la pestaña **Viajes**: grabación automática, puntuaciones, tarjetas de fidelidad. Un adaptador OBD2 sigue siendo opcional incluso aquí — los viajes se graban solo con GPS.

Puedes cambiar cuando quieras, y cualquier interruptor que toques después te pone en **Personalizado**. La lista completa, y lo que cada uno cuesta en batería, datos o privacidad: [Referencia de ajustes → Funciones y modo de uso](User-es-Settings-Reference#funciones-y-modo-de-uso).

---

## 5. Solo Alemania: la clave API gratuita

16 de los 17 países funcionan al instante. El servicio oficial **alemán** emite una clave por usuario.

<img src="guide/data-sources-location.jpg" width="340" alt="Pantalla de fuentes de datos con los campos de clave Tankerkönig y OpenChargeMap">

*Ajustes → Fuentes de datos y ubicación. Una cruz roja aquí es la razón de que una búsqueda alemana no devuelva nada.*

1. Abre [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) y pide una clave (formulario corto, gratis).
2. Cópiala — es un UUID como `00000000-0000-0000-0000-000000000002`.
3. Pégala en el campo **Precios de combustible (Tankerkoenig)**.

La clave se guarda en la caja fuerte de hardware (Android Keystore / Llavero de iOS) y solo se envía al servicio alemán. El campo **Recarga EV** de abajo ya contiene una clave compartida: los datos de recarga funcionan sin configuración.

---

## 6. La barra inferior

<img src="guide/favorites.jpg" width="340" alt="Pestaña Favoritos con la barra inferior y el botón Buscar central">

*El botón verde **Buscar** elevado en el centro es el único disparador de búsqueda de toda la app.*

- ⭐ **Favoritos** — estaciones guardadas y alertas de precio
- 🗺️ **Mapa** — cada estación cercana como chincheta coloreada por precio
- 🔍 **Buscar** *(centro)* — cerca o a lo largo de una ruta
- ⛽ **Combustible** — depósito, consumo, repostajes *(desde Intermedio)*
- 🛣️ **Viajes** — cuaderno de bitácora y coaching *(Completo)*

Los ajustes **no** son una pestaña: es el engranaje arriba a la derecha de las pantallas principales. En tableta, o teléfono en horizontal, la app se divide en dos columnas para ver lista y mapa (o detalle) a la vez.

---

## 7. Tu primera búsqueda

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Hoja de criterios para una búsqueda cercana">

*Toca **Buscar** → la hoja de criterios se abre rellenada desde tu perfil. Ajusta y vuelve a tocar **Buscar**.*

Obtienes una lista ordenada del más barato (o por distancia — tú eliges), cada ficha con precio, tendencia, distancia y frescura. Un toque abre el detalle. El recorrido completo: [Encontrar gasolineras](User-es-Finding-Stations).

**Consejo:** toca **Guardar como valores predeterminados** al pie de la hoja una vez fijados tus criterios habituales — toda búsqueda futura partirá de ahí.

---

## 8. Dos ajustes que cambiar el primer día

<img src="guide/units-and-display-1.jpg" width="340" alt="Unidades y visualización con tema, unidad de distancia y unidad de consumo">

*Ajustes → Unidades y visualización. La **unidad de consumo** está en *Automático* por defecto (mpg en Reino Unido, L/100 km en el resto); elige explícitamente L/100 km, km/L o mpg si lo prefieres.*

El segundo es **Ajustes → Conducción y consumo → Ventana de consumo en directo** (3 / 5 / 10 / 30 s). Gobierna el gran número en vivo de la pantalla de grabación: una ventana larga es más estable de leer conduciendo, una corta reacciona más rápido a tu pie derecho.

---

## 9. Elige con qué se abre la app

**Ajustes → Perfiles y región → Pantalla de inicio**: *Cerca* (búsqueda inmediata con tus últimos criterios), *Estación más cercana*, *Favoritos* o *Mapa*. Toma la que corresponda al motivo por el que abres la app.

---

## 10. Dónde está todo

Los ajustes son un árbol de dos niveles con una búsqueda por palabra clave arriba — escribe « radio », « OBD2 » o « tema » y la ficha correspondiente emerge.

<img src="guide/settings-root-1.jpg" width="340" alt="Raíz de ajustes: fichas temáticas con campo de búsqueda">

*Doce temas, una casa por parámetro. El mapa completo es la [Referencia de ajustes](User-es-Settings-Reference).*

---

**Siguiente:** [Cómo funciona Sparkilo →](User-es-How-It-Works)
