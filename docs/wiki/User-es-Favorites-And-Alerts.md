# Favoritos y alertas de precio

La pestaña ⭐ es tu lista corta, más los robots que la vigilan por ti.

---

## Favoritos

<img src="guide/favorites.jpg" width="340" alt="Pestaña Favoritos con dos estaciones guardadas, precios por combustible y la pestaña de alertas">

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

<img src="guide/price-alerts.jpg" width="340" alt="Pantalla de alertas: contadores activas/hoy/esta semana, alertas de estación y de zona">

*Tres contadores arriba — reglas activas, disparos hoy y esta semana — luego los dos tipos de alerta. El pie fecha la última comprobación en segundo plano.*

Hay dos tipos, que responden a preguntas distintas.

### Alerta de estación — « avísame cuando *este* surtidor baje »

Se crea desde la página de detalle de una estación (icono de campana). Elige el combustible, fija un umbral, guarda. Ideal para la estación que ya usas.

### Alerta de zona — « avísame cuando *por aquí* baje »

<img src="guide/price-alert-create.jpg" width="340" alt="Crear una alerta de zona: etiqueta, tipo de combustible, umbral, radio, frecuencia, posición o código postal">

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
- **Un efecto secundario útil:** la misma comprobación escribe un registro de precio en tu historial local. Una estación con alerta construye por tanto su historial de 30 días en horas en vez de semanas — y eso es lo que hace aparecer pronto el aviso *mejor momento para repostar*. Ver [Historial de precios](User-es-Price-History-And-Predictions#la-fase-de-aprendizaje).
- **Si las notificaciones están apagadas a nivel de sistema**, el interruptor de la app no puede disparar nada.

---

## Estadísticas

Los contadores de arriba muestran cuántas reglas están activas y cuántas veces han saltado hoy y esta semana — una prueba rápida de si la tarea de fondo se ejecuta de verdad. Una fila de ceros con varias alertas activas y un sello « última comprobación » viejo es el síntoma clásico de un ahorrador de batería matando la tarea.

---

## Detener alertas

Desactivar una alerta la pausa sin perder la regla; deslizar a la izquierda la elimina. Quitar la estación de favoritos **no** elimina sus alertas.

---

**Ver también:** [Historial y previsiones de precios](User-es-Price-History-And-Predictions) · [Referencia de ajustes → Precios y alertas](User-es-Settings-Reference#precios-y-alertas)
**Siguiente:** [Recarga eléctrica →](User-es-EV-Charging)
