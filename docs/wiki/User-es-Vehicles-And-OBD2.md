# Vehículos y OBD2

Todo lo que la app sabe de *tu coche*. Esta página decide si las cifras de consumo de todas las demás son fiables.

---

## Por qué la app necesita un vehículo

Sin vehículo, Sparkilo es un buscador de precios. Con uno puede convertir litros y kilómetros en *tu* coste por kilómetro, estimar la autonomía y — con adaptador — modelar el caudal instantáneo de combustible.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Pantalla Vehículos y OBD2 con las fichas Mis vehículos y Adaptador OBD2">

*Ajustes → Vehículos y OBD2. Fíjate en la etiqueta de alcance de la ficha del adaptador: los adaptadores se emparejan **por vehículo**, no por teléfono.*

<img src="guide/my-vehicles.jpg" width="340" alt="Lista de vehículos con un vehículo activo">

*La marca verde indica el vehículo activo — al que se atribuyen los nuevos repostajes y viajes.*

---

## Identidad y motorización

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Editor de vehículo: nombre, VIN opcional, leer el VIN del coche, selector de motorización">

*Ponle el nombre con el que lo reconozcas. El VIN es opcional.*

### El VIN, y qué aporta

Introducir (o leer) el VIN permite a la app deducir cilindrada, número de cilindros, potencia y tipo de combustible, que son las entradas del modelo de consumo. **Leer el VIN del coche** lo recupera en un segundo por OBD2.

La decodificación en línea del VIN es un **consentimiento aparte** — la app pregunta antes de enviar nada, y la decodificación parcial sin conexión funciona aunque lo rechaces. Un VIN es un dato personal; trátalo como tal.

### Motorización

**Térmico / Híbrido / Eléctrico** cambia los campos de abajo. El térmico pide capacidad del depósito, potencia y combustible preferido; el eléctrico pide batería y conectores.

---

## Capacidad, potencia y flex-fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Bloque térmico: capacidad del depósito, potencia del motor, combustible preferido, interruptor multicombustible, adaptador emparejado">

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

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibración de referencia: adaptador emparejado, progreso 210/270, aviso de situaciones ausentes y barras por situación">

*210 muestras de 270. Dos situaciones de conducción siguen vacías, y la app lo dice en lugar de fingir integridad.*

Cada muestra OBD2 se archiva en una situación de conducción: **ralentí, stop & go, urbano, autopista, deceleración, cuesta / cargado, arranque en frío, carga sostenida / remolque, punto muerto**. Las medias por situación forman la referencia del vehículo — el modelo que produce un L/100 km plausible cuando falta el adaptador o un PID deja de responder.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Barras de muestras por situación, restablecer la referencia y el selector de modo de calibración">

*Las situaciones con cero muestras son las que caerán a valores por defecto. Aquí dos: deceleración y remolque.*

### Basado en reglas o difuso

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Modo de calibración basado en reglas o difuso, acciones de restablecimiento y recordatorios de mantenimiento">

*El modo difuso es el predeterminado y la mejor opción para casi todo el mundo.*

- **Basado en reglas** asigna cada muestra a exactamente una situación. Predecible, pero salta de una muestra a otra entre « urbano » y « autopista » cuando circulas cerca del límite — hacia los 60 km/h, por ejemplo.
- **Difuso** reparte cada muestra entre todas las situaciones según su grado de pertenencia. Suave justo donde el modo de reglas salta, a costa de ser más difícil de seguir muestra a muestra.

### Los botones de restablecimiento — y qué hacen de verdad

- **Restablecer el rendimiento volumétrico** descarta el η_v aprendido y restaura el valor por defecto 0,85. η_v es un parámetro del modelo speed-density que estima el caudal de aire sin caudalímetro. Restablécelo solo tras una intervención mecánica; un número raro suele ser un problema de cobertura. Los coches que publican el caudal directamente (PID 5E) no lo usan en absoluto.
- **Restablecer desde la base de vehículos** recarga cilindrada, potencia y valores por defecto del catálogo integrado, descartando tus valores manuales.
- **Restablecer la referencia por situación** (en la ficha de referencia) borra cada muestra aprendida y te devuelve a los valores de arranque en frío hasta que nuevos viajes llenen el perfil.

Ninguno de ellos toca la **ganancia de surtidor**, aprendida de las ventanas de depósito lleno a lleno y residente fuera del modelo OBD2 — ver [Cómo funciona Sparkilo → Cómo un litro se convierte en un número](User-es-How-It-Works#cómo-un-litro-se-convierte-en-un-número).

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

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Editor de vehículo completo ensamblado a partir de cinco capturas">

</details>

---

**Ver también:** [Viajes y eco-coaching](User-es-Trips-And-Coaching) · [Solución de problemas → OBD2](User-es-Troubleshooting-FAQ#el-adaptador-obd2-no-conecta)
**Siguiente:** [Registro de repostajes y consumo →](User-es-Fuel-And-Consumption)
