# Encontrar gasolineras

Nivel 1 de los [tres niveles de ahorro](User-es-How-It-Works#los-tres-niveles-de-ahorro): pagar menos por litro.

---

## Un botón, un modelo mental

La barra inferior tiene un solo disparador de búsqueda — el botón verde elevado en el centro. Es contextual, no modal:

- **Desde cualquier pestaña** → abre la hoja de criterios.
- **Desde los resultados o el mapa** → reabre la hoja con tus últimos valores.
- **Dentro de la hoja** → ejecuta la búsqueda.

Su etiqueta dice lo que hará, y en modo ruta permanece desactivado hasta que haya un destino. Deliberadamente no hay botones separados de « buscar cerca » y « buscar en ruta ».

---

## Fijar los criterios

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Criterios: cercanía o ruta, dirección, chips de combustible, radio, solo abiertas, servicios, marcas">

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

<!-- anchor: search.criteria.button -->
### El botón de búsqueda

El botón elevado en el centro de la barra inferior es el único
disparador de búsqueda. Desde cualquier pestaña abre esta hoja; desde
los resultados o el mapa la reabre con lo último que usó; dentro de la
hoja, lanza la búsqueda.

<!-- anchor: search.criteria.mode -->
### Cerca o a lo largo de una ruta

Dos preguntas distintas. **Cerca** busca alrededor de su posición o de
una dirección. **A lo largo de la ruta** necesita un destino y mide la
distancia a lo largo del corredor, no en línea recta: una estación a 2 km
por una calle lateral queda detrás de una que está de camino.

<!-- anchor: search.criteria.fuel-type -->
### Tipo de combustible

Para qué combustible son los precios. Los chips se adaptan a lo que
publica realmente el proveedor de su país — un combustible ausente de la
lista falta en los datos, no en la app.

<!-- anchor: search.criteria.radius -->
### Radio

Hasta dónde buscar. Un radio amplio en un país denso devuelve muchísimas
estaciones y una búsqueda más lenta, y las estaciones de más suelen estar
más lejos de lo que vale el ahorro.

<!-- anchor: search.criteria.open-only -->
### Solo abiertas ahora

Oculta las estaciones cerradas. Depende de que el proveedor publique
horarios, y algunos no lo hacen — cuando faltan, la estación se conserva
en vez de adivinarse.

<!-- anchor: search.criteria.amenities -->
### Servicios

Tienda, lavado, aire, WC. Estos filtros actúan sobre datos
**declarados**: una estación que no publica nada sobre sus servicios
desaparece de una lista filtrada aunque los tenga todos.

<!-- anchor: search.criteria.highway -->
### Estaciones de autopista

Las estaciones de autopista suelen ser el combustible más caro del país:
excluirlas es el filtro que más a menudo cambia lo que paga.
Consérvelas cuando no pueda salir de la autopista.

<!-- anchor: search.criteria.defaults -->
### Guardar como mis valores por defecto

Escribe estos criterios en su perfil, de modo que cada búsqueda posterior
empiece aquí y no en los valores de la app. Es el ajuste que convierte la
hoja en una confirmación de un toque en vez de un formulario.

### Cómo funciona de verdad

Una búsqueda cercana envía **tus coordenadas (o un código de región) y un radio** al proveedor oficial de tu país — nunca tu identidad. Los países que publican un fichero diario (España, Italia) se filtran en el dispositivo: esas búsquedas no necesitan ninguna llamada de red una vez cacheado el fichero.

---

## Leer una ficha de resultado

<img src="guide/search-results.jpg" width="340" alt="Lista de resultados con precio, flecha de tendencia, frescura, servicios, distancia y estrella">

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

La frescura es una propiedad del **proveedor del país**, no de la app. Un precio español de 14 horas no es un fallo: ese país publica una vez al día. Ver [Cómo funciona Sparkilo → Una fuente por país](User-es-How-It-Works#una-fuente-de-datos-por-país).

### Gestos de deslizamiento

- **Deslizar a la derecha** — abrir en tu app de navegación (Google Maps, Waze, OsmAnd, Organic Maps).
- **Deslizar a la izquierda** — ocultar la estación de todos los resultados futuros. Se restaura desde **Privacidad y datos → Datos en este dispositivo → Estaciones ignoradas**.

---

## Detalle de una estación

<img src="guide/station-detail-1.jpg" width="340" alt="Detalle de estación: tabla de precios por combustible, añadir repostaje, horarios, zona">

*Toca una ficha. La cabecera cae de marca a nombre y a calle, así que un Intermarché sin campo de marca sigue mostrando « Intermarché ».*

El bloque superior es la **tabla completa de precios** — cada calidad que el proveedor publica para esa estación, con `--` donde no publica ninguna. Es la forma más rápida de ver si la estación de E85 barata también aguanta con el diésel.

**Añadir repostaje** rellena estación, combustible y precio en el formulario — el mayor ahorro de tiempo de la app si registras tus repostajes.

<img src="guide/station-detail-2.jpg" width="340" alt="Continúa el detalle: zona, servicios, medios de pago, tu valoración, historial de precios">

*Más abajo: servicios, medios de pago aceptados, tu valoración privada en estrellas, y el historial local de precios de 30 días.*

Las acciones de la barra superior son, de izquierda a derecha: **crear una alerta de precio**, **escanear un QR de pago**, **informar de un precio erróneo** y **marcar como favorita**.

---

## El mapa

<img src="guide/map-view.jpg" width="340" alt="Mapa con chinchetas coloreadas por precio, círculo de radio y leyenda barato/caro">

*El color es relativo a lo que está en pantalla: verde la más barata visible, rojo la más cara. El pie indica número de estaciones, radio y antigüedad de los datos.*

- **Los marcadores de grupo** juntan chinchetas al alejar; un toque acerca.
- **Pulsación larga** en cualquier punto para dejar tu marcador y buscar desde ahí.
- El **selector EV** arriba a la derecha cambia el mapa a puntos de recarga — ver [Recarga eléctrica](User-es-EV-Charging).
- **Compartir** envía la vista actual a alguien.

Las teselas vienen de OpenStreetMap. Por defecto pasan por el proxy UE del desarrollador para que OpenStreetMap nunca vea tu IP; puedes desactivar el proxy en Ajustes → Privacidad y datos y cargar directamente. La versión F-Droid nunca usa el proxy.

---

## El radar de gasolineras

Un barrido en vivo alrededor de tu posición, pensado para **conducir**.

<img src="screenshots/radar-start.png" width="340" alt="La píldora « Iniciar el radar de gasolineras » en la pantalla de resultados">

*Tras cualquier búsqueda cercana aparece una píldora flotante abajo a la derecha. Un toque inicia el radar.*

### Cómo funciona de verdad

El radar refresca tu posición GPS, recupera las **ubicaciones** de estaciones en un amplio corredor de 60 km y fusiona una consulta directa dentro del radio: nunca puede mostrar menos que una búsqueda normal. Las estaciones no se mueven, así que esas ubicaciones se cachean hasta una hora y se reutilizan; solo el **precio** de una estación a la que te acercas se pide en el momento. Eso es lo que hace barato en datos y batería un radar siempre activo.

<img src="screenshots/radar-active.png" width="340" alt="Radar en marcha: chinchetas de precio en vivo y lista ordenada por distancia con barras de proximidad">

*En marcha: resultados por distancia, cada uno con una barra que se llena al acercarte.*

### Durante la grabación de un viaje

El radar fija una ficha **Estación más cercana** arriba en la pantalla de grabación — nombre, precio de tu combustible, distancia, y una barra que llega al 100 % al llegar. Desliza a izquierda/derecha para recorrer las candidatas. Al entrar en el radio configurado, la miniatura superpuesta cambia a una gran visualización de precio; ver [Viajes y eco-coaching → La superposición de aproximación](User-es-Trips-And-Coaching#la-superposición-de-aproximación).

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

<img src="guide/full/station-detail.jpg" width="420" alt="Página completa del detalle de estación ensamblada a partir de dos capturas">

</details>

---

**Ver también:** [Planificación de ruta](User-es-Route-Planning) · [Favoritos y alertas](User-es-Favorites-And-Alerts) · [Historial de precios](User-es-Price-History-And-Predictions)
**Siguiente:** [Planificación de ruta →](User-es-Route-Planning)
