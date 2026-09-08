# Viajes y eco-coaching

La pestaña 🛣️ **Viajes** es un cuaderno de bitácora automático más un entrenador de conducción. Aparece en el modo **Completo**.

---

## La pestaña Viajes

<img src="guide/trips-tab.jpg" width="340" alt="Pestaña Viajes: comparación mensual, informe del depósito y lista de viajes con el botón de grabación">

*Totales del mes, el último informe del depósito, y luego la lista de viajes. El botón flotante inicia una grabación.*

La comparación mensual exige al menos tres viajes al mes antes de comparar — con menos, la media es ruido, no tendencia.

<img src="guide/trips-map.jpg" width="340" alt="Todos los viajes grabados en un mapa, coloreados por viaje">

*El icono de mapa de la barra dibuja cada viaje grabado en un solo mapa — un año de conducción de un vistazo, y una forma fácil de detectar las rutas que merece la pena optimizar.*

---

## Dos formas de grabar

### Solo con el teléfono

Sin hardware. La app registra ruta, distancia, duración y velocidad por GPS, y **modela** el consumo desde la calibración del vehículo y tu conducción. Marcado en todas partes con `~` y una nota explícita de « estimación GPS ».

La precisión empieza mal y mejora: cada ventana de repostaje cerrada reancla el modelo al surtidor, así que tras un puñado de depósitos llenos un viaje solo con GPS suele quedar dentro de unos pocos puntos porcentuales. Hasta entonces se etiqueta como preliminar, no se maquilla.

### Con un adaptador OBD2

Datos de motor en vez de deducción: caudal real (medido donde el coche publica el PID 5E), régimen, carga, acelerador. Sin periodo de aprendizaje para el consumo, y el coaching accede a señales que el GPS no ve — marcha, revoluciones, carga del motor. La configuración está en [Vehículos y OBD2](User-es-Vehicles-And-OBD2#el-adaptador-obd2).

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

<img src="guide/trip-detail-1.jpg" width="340" alt="Resumen del viaje: fecha, vehículo, adaptador, distancia, duración, consumo, combustible, coste y velocidades">

*El resumen declara su propia procedencia — vehículo, adaptador, y una insignia **Traza GPS** en la distancia para saber de dónde salen los kilómetros.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Mapa de la ruta coloreado por eficiencia con su leyenda y la ficha de principales conductas derrochadoras">

*La ruta está coloreada por eficiencia — verde por debajo de 6 L/100 km, ámbar hasta 10, rojo por encima. Dónde se fue el combustible, geográficamente.*

Ese coloreado es la vista más accionable de la app: pone sobre un mapa los tramos caros de tu trayecto diario. Un tramo rojo que se repite todos los días es un cruce, una cuesta o un hábito que merece la pena cambiar.

<img src="guide/trip-detail-3.jpg" width="340" alt="Selector « cómo fue el viaje », dónde se fue el combustible, distribuciones de acelerador y régimen">

*Tres bloques: tu veredicto, la atribución del combustible, y cómo has exigido de verdad al motor.*

- **« ¿Cómo fue este viaje? »** — *Suave / Moderado / Agresivo*. Tu respuesta sirve para calibrar los umbrales de estilo de conducción con viajes reales, no para puntuarte.
- **Dónde se fue tu combustible** — litros atribuidos a aceleraciones fuertes frente a conducción normal. Números absolutos pequeños en un viaje corto; lo que cuenta es la proporción.
- **Posición del acelerador** y **régimen del motor** como distribuciones — la parte del viaje en punto muerto, carga ligera, firme y a fondo, y en cada banda de revoluciones. Una parte alta por encima de 3000 rpm en el trayecto al trabajo significa que subes marchas demasiado tarde, y eso cuesta.

<img src="guide/trip-detail-4.jpg" width="340" alt="Diagnóstico de muestreo GPS y ficha plegada de salud de la comunicación OBD2">

*Dos diagnósticos: lo completa que es la traza GPS y cómo se ha portado el adaptador.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Salud de la comunicación OBD2 desplegada: muestras, cobertura, adaptador, protocolo, duración, fin de sesión">

*Desplegada, la ficha OBD2 se explica en claro.*

**Lee esta ficha antes de dudar de una cifra de consumo.** Indica cuántas muestras llevaban datos de motor, el **porcentaje de cobertura** resultante, el adaptador y el protocolo negociado, la duración de la sesión, por qué terminó (`userStopped`, una desconexión, una muerte del proceso), y la línea decisiva: *« Los valores de consumo vienen del adaptador, no de estimaciones GPS. »* Si la cobertura está muy por debajo del 100 %, los huecos se rellenaron con estimaciones GPS y la media del viaje es una mezcla.

<img src="guide/trip-detail-5.jpg" width="340" alt="Gráficos: velocidad, caudal de combustible y régimen del motor a lo largo del viaje">

*Velocidad, caudal y régimen sobre un eje de tiempo común — las tres curvas que explican cualquier cifra de consumo.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Gráficos: régimen, carga del motor, posición del acelerador y temperatura de refrigerante">

*Carga del motor y acelerador uno al lado del otro muestran la diferencia entre hacer trabajar al motor y limitarse a subirlo de vueltas.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Gráficos: refrigerante, altitud desde la salida, temperatura de aire de admisión y avance de encendido">

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

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Interruptores de coaching, recompensas, tarjetas de fidelidad, logros y registro de depuración OBD2">

*Ajustes → Conducción y consumo. Logros y puntuaciones se pueden ocultar en toda la app si la gamificación no es lo tuyo.*

---

## El panel de carbono

<img src="screenshots/carbon-dashboard.png" width="340" alt="Panel de carbono: coste y CO2 por longitud de viaje y banda de velocidad">

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

<img src="guide/full/trip-detail.jpg" width="420" alt="Página completa del detalle de viaje ensamblada a partir de ocho capturas">

</details>

---

**Ver también:** [Vehículos y OBD2](User-es-Vehicles-And-OBD2) · [Registro de repostajes y consumo](User-es-Fuel-And-Consumption)
**Siguiente:** [Historial y previsiones de precios →](User-es-Price-History-And-Predictions)
