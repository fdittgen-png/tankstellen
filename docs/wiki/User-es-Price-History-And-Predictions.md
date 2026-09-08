# Historial y previsiones de precios

La app construye una imagen **privada y local** de cómo se mueven los precios a tu alrededor, y saca de ella una recomendación honesta.

---

## Qué se registra, y dónde

Cada vez que el precio de una estación pasa por la app — una búsqueda, un refresco de favoritos o una comprobación de alertas en segundo plano — la app escribe **en tu teléfono** un registro: estación, combustible, precio, marca de tiempo. Nada se sube, y no se descargan datos de nadie más.

- **Deduplicado a un registro por estación y hora.** Cinco búsquedas en diez minutos dan una entrada.
- **Conservado 30 días.** Los registros más antiguos se borran automáticamente.
- **Habilitado por** *Funciones y modo de uso → Precios y alertas → Historial de precios*. Apagado, no se escribe ningún registro.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Precios y alertas: historial, predicción TFLite, informes comunitarios, QR de pago">

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

**Ver también:** [Favoritos y alertas](User-es-Favorites-And-Alerts) · [Encontrar gasolineras → La frescura](User-es-Finding-Stations#la-frescura-más-importante-que-el-precio)
**Siguiente:** [Referencia de ajustes →](User-es-Settings-Reference)
