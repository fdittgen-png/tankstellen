# Planificación de ruta

No « el más barato cerca de mí » sino **el más barato en el camino** — la diferencia vale varios euros en cualquier viaje largo.

---

## Lanzar una búsqueda por ruta

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Criterios en modo ruta: salida, parada, destino, combustible, segmento, desvío, ahorro mínimo">

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

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Parte baja de los criterios de ruta: solo abiertas, servicios, marcas, guardar predeterminados">

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

**Necesitas un perfil por país** con la calidad preferida correcta, o el segundo tramo no tendrá nada que tarificar y mostrará `--`. Ver [Cómo funciona Sparkilo → Perfiles](User-es-How-It-Works#perfiles-un-contexto-un-juego-de-valores-por-defecto).

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

<img src="guide/profile-edit-2.jpg" width="340" alt="Parámetros de planificación de ruta en el editor de perfil">

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

**Ver también:** [Encontrar gasolineras](User-es-Finding-Stations) · [Referencia de ajustes](User-es-Settings-Reference#perfiles-y-región)
**Siguiente:** [Favoritos y alertas →](User-es-Favorites-And-Alerts)
