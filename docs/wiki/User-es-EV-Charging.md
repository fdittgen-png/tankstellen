# Recarga eléctrica

Sparkilo no es solo para térmicos. Los puntos de recarga vienen de [OpenChargeMap](https://openchargemap.org), el mayor registro comunitario abierto del mundo.

---

## Activar

Dos interruptores independientes, ambos en **Ajustes → Funciones y modo de uso → Búsqueda y mapa**:

- **Recarga EV** — la función en sí (búsqueda, páginas de detalle, favoritos).
- **Mostrar los puntos de recarga** — si los puntos aparecen en resultados y mapa.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Interruptores del grupo Búsqueda y mapa incluidos Recarga EV y Mostrar puntos de recarga">

*Puedes mostrar gasolineras, puntos de recarga, o ambos. Quien conduce solo eléctrico suele desactivar **Mostrar gasolineras**.*

Luego crea un vehículo en **Ajustes → Vehículos y OBD2 → Mis vehículos → Añadir**, eligiendo **Eléctrico** como motorización. Un vehículo eléctrico lleva capacidad de batería (kWh), potencias máximas de carga AC y DC (kW) y sus conectores (Tipo 2, CCS, CHAdeMO, Tesla, Schuko, Tipo 1, enchufe doméstico). Las búsquedas se limitan entonces a los puntos que tu coche puede usar de verdad.

---

## Cómo funcionan los datos

<img src="guide/data-sources-location.jpg" width="340" alt="Campo de clave Recarga EV mostrando la clave compartida por defecto">

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

<img src="screenshots/map-ev-charging.png" width="340" alt="Mapa en modo EV con los chips de filtro por conector">

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

**Ver también:** [Encontrar gasolineras](User-es-Finding-Stations) · [Registro de repostajes y consumo](User-es-Fuel-And-Consumption)
**Siguiente:** [Vehículos y OBD2 →](User-es-Vehicles-And-OBD2)
