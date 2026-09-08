# Referencia de ajustes

Cada pantalla del árbol de ajustes y — más útil — **cuánto te cuesta cada interruptor** en batería, datos, precisión o privacidad.

---

## La forma del conjunto

Los ajustes son un **árbol de dos niveles**: una raíz de fichas temáticas, una pantalla por tema, y una búsqueda por palabra clave sobre todas.

<img src="guide/settings-root-1.jpg" width="340" alt="Raíz de ajustes, mitad superior: campo de búsqueda y las seis primeras fichas">

*Escribe « radio », « OBD2 » o « tema » en el campo de búsqueda y la ficha correspondiente emerge — no hace falta recordar qué tema posee un parámetro.*

<img src="guide/settings-root-2.jpg" width="340" alt="Raíz de ajustes, mitad inferior: funciones, fuentes de datos, sincronización, privacidad, copia de seguridad, avanzado">

*Doce temas en total. Para llegar: el engranaje arriba a la derecha de las pantallas principales.*

Tres reglas de diseño hacen el árbol predecible:

1. **Una casa por parámetro.** Nada aparece dos veces; las referencias cruzadas apuntan al único propietario.
2. **Etiquetas de alcance.** Una ficha marcada *este perfil*, *todos los perfiles* o *este vehículo* dice de antemano hasta dónde llega un cambio.
3. **Estados vacíos honestos.** Una sección con la función apagada lo dice y enlaza al interruptor, en lugar de esconderse.

---

## Perfiles y región

*País, idioma, combustible, radio de búsqueda, rutas · alcance: este perfil*

<img src="guide/profile-edit-1.jpg" width="340" alt="Editor de perfil: nombre, combustible preferido, radio por defecto">

*El combustible preferido se deriva del vehículo por defecto. Para elegirlo directamente, quita el vehículo del perfil.*

| Ajuste | Impacto |
|---|---|
| **Nombre del perfil** | Cosmético, pero es lo que muestra el chip de perfil |
| **Combustible preferido** | El precio destacado de cada ficha; el predeterminado de las alertas; para qué optimiza la búsqueda de ruta |
| **Radio por defecto** | Mayor = más resultados y búsquedas más lentas |

<img src="guide/profile-edit-2.jpg" width="340" alt="Planificación de ruta: segmento, desvío máximo, ahorro mínimo, elección por segmento, candidatas">

*Valores por defecto de la ruta. **Candidatas por punto de muestreo** intercambia minuciosidad por velocidad en corredores largos.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Visualización y estaciones, visibilidad de las notas, pantalla de inicio, radio de la superposición">

*Tres cosas distintas que conviene conocer.*

- **Evitar autopistas** cambia la ruta calculada en sí: las áreas de servicio dejan de ser candidatas — en general un ahorro, ya que el combustible de autopista es el más caro de cualquier corredor.
- **Notas de estación** — *Local* (solo este dispositivo), *Privado* (sincronizado en tu cuenta) o *Compartido* (visible para otros usuarios). Es una decisión de privacidad, no de almacenamiento.
- **Pantalla de inicio** — con qué se abre la app: Cerca, Estación más cercana, Favoritos o Mapa.

<img src="guide/profile-edit-4.jpg" width="340" alt="Radio y modo de precio de la superposición, vehículo por defecto, región">

*El radio de la superposición y la regla **más cercana vs más barata del radio** viven en el perfil: un perfil « diario » y uno « vacaciones » pueden comportarse distinto.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Región: chips de país y de idioma">

*El país decide el proveedor de datos. Cambiarlo vacía los datos de estaciones en caché.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Chips de idioma y campo del código postal de casa">

*Un **código postal de casa** permite búsquedas por zona sin GPS alguno — la forma más limpia de usar la app si nunca quieres compartir tu ubicación.*

---

## Vehículos y OBD2

*Tus coches, capacidad del depósito, emparejamiento · alcance: este vehículo*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Pantalla Vehículos y OBD2">

*Los adaptadores se emparejan por vehículo: la ficha del adaptador te lleva dentro de un vehículo en lugar de a una pantalla global.*

El tratamiento completo — VIN, capacidad, flex-fuel, modos de calibración, referencia, umbrales de grabación automática, recordatorios — está en [Vehículos y OBD2](User-es-Vehicles-And-OBD2).

---

## Conducción y consumo

*Coaching, recompensas, radar, resolución de problemas · alcance: mixto*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Ventana de consumo en directo, superposición de aproximación, mis vehículos, interruptores de coaching">

*Las dos primeras entradas son las que ajustarás de verdad.*

| Ajuste | Impacto |
|---|---|
| **Ventana de consumo en directo** (3/5/10/30 s) | Más larga = más estable y legible al volante; más corta = lo bastante reactiva para enseñar lo que cuesta el pedal |
| **Superposición al acercarse** | Radio, modo de precio, suelo de consulta y anclado de pantalla para el perfil activo |
| **Coaching eco en tiempo real** | Vibración ligera + consejo en pantalla al acelerar fuerte en velocidad de crucero |
| **Coaching de voz** | El mismo consejo leído en voz alta — los ojos siguen en la carretera |
| **Glide-coach beta** | Aviso háptico antes de un rojo con los semáforos de OpenStreetMap. **Apagado por defecto — riesgo de distracción**, y necesita red |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, tarjetas de fidelidad, logros, registro de depuración OBD2">

*Recompensas y resolución de problemas.*

- **Tarjetas de fidelidad** — descuentos por litro aplicados en las comparaciones de precio, así una estación nominalmente más cara puede resultar correctamente más barata para ti.
- **Mostrar logros y puntuaciones** — apagado, insignias, puntuaciones y trofeos desaparecen de toda la app. Nada deja de medirse; deja de mostrarse.
- **Registro de depuración OBD2** — graba cada sesión (conexión, saludo, pérdidas de datos, reconexiones) en un registro XML exportable. **Apagado por defecto**: escribe continuamente y solo compensa mientras se persigue un problema del adaptador.

---

## Precios y alertas

*Alertas, anuncios de voz, historial, informes comunitarios*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Precios y alertas: entrada de alertas, nota sobre anuncios de voz, funciones de precio">

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

<img src="guide/units-and-display-1.jpg" width="340" alt="Tema, unidad de distancia y unidad de consumo">

*La **unidad de consumo** se propaga a todas partes de golpe — banner en vivo, miniatura, medias de viaje, estadísticas, widget.*

- **Unidad de distancia** sigue por defecto al país del perfil activo (km o millas).
- **Unidad de consumo**: *Automático* (mpg en Reino Unido y EE. UU., L/100 km en el resto), o explícitamente L/100 km, km/L o mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Widget de pantalla de inicio: esquema de color y variante de contenido">

*Las opciones del widget llevan la etiqueta **este perfil** y se aplican a todo widget instalado que muestre ese perfil, desde el siguiente refresco.*

**Variante de contenido** — *solo precio actual*, o *predictivo: mejor momento para repostar* (requiere la predicción TFLite).

---

## Funciones y modo de uso

*Preajustes y cada interruptor individual*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Preajustes Básico, Intermedio, Completo y el estado Personalizado">

*Elegir un preajuste **sobrescribe** cada interruptor individual. Si has ajustado a mano, quédate en Personalizado.*

Las dependencias se aplican, no se ocultan: un interruptor con el requisito apagado queda desactivado y nombra ese requisito.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Grupo Búsqueda y mapa: rutas, recarga EV, mostrar gasolineras, mostrar puntos, calculadora">

*Búsqueda y mapa — incluido si gasolineras y puntos de recarga aparecen siquiera.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Grupo Precios y alertas: alertas, historial, predicción TFLite, QR de pago, informes">

*Precios y alertas. El historial es la función padre de la predicción que le sigue.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Grupo Radar de gasolineras con anuncios de voz y el interruptor principal de síntesis de voz">

*El radar, sus anuncios de voz y el interruptor principal **Respuesta hablada** — apagado, la app nunca abre un motor de síntesis.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Grupo Consumo: selector de modo más análisis, gamificación, coach háptico, glide-coach, traza GPS, grabación automática">

*El selector **Apagado / Combustible / Combustible + Viajes** es la forma compacta de toda la pila de consumo.*

| Interruptor | Impacto |
|---|---|
| **Estadísticas de consumo** | La pestaña de análisis de repostajes y viajes |
| **Gamificación** | Puntuaciones de conducción e insignias ganadas |
| **Eco-coach háptico** | Respuesta vibratoria en tiempo real al volante |
| **Glide-coach** | Consejos eco desde los semáforos de OpenStreetMap — necesita red |
| **Traza GPS de viajes** | Guarda los puntos de ruta de cada viaje. Apagado = base más pequeña, sin mapas de viaje |
| **Grabación automática** | Inicia un viaje cuando el adaptador emparejado se conecta a un vehículo en movimiento |

<img src="guide/features-and-mode-6.jpg" width="340" alt="PID OEM experimentales, exigir OBD2, panel de carbono, TankSync, sincronización de referencias">

*Dos interruptores aquí cambian la calidad de los datos en vez de la interfaz.*

- **PID OEM experimentales** — lee el nivel exacto del depósito en litros mediante PID del fabricante en adaptadores compatibles. Mejores datos donde funciona; inofensivo donde no.
- **Exigir OBD2 para la grabación de viajes** — **apagado**, los viajes se graban solo con GPS. El coaching es reducido (sin L/100 km instantáneos, menos señales de motor) pero nada queda bloqueado.
- **Sincronización de referencias** — sube las referencias de consumo por vehículo para que un segundo dispositivo las reutilice. Requiere TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Entrada y escaneo: tarjetas de fidelidad, OCR de recibo, compartir recibo para importarlo">

*Entrada y escaneo. El reconocimiento es en el dispositivo; estos interruptores solo deciden si los atajos existen.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Desarrollador y experimental: informe vía PAT de GitHub, modo desarrollador, traza de arranque">

*Desarrollador y experimental — se puede dejar apagado salvo que informes de fallos.*

---

## Fuentes de datos y ubicación

*Claves API, GPS, cambio automático de perfil*

<img src="guide/data-sources-location.jpg" width="340" alt="Campos de clave API y bloque de ubicación">

*Una cruz roja en la clave de precios es el motivo habitual de una búsqueda alemana vacía.*

| Ajuste | Impacto |
|---|---|
| **Precios de combustible (Tankerkoenig)** | Necesaria solo para Alemania. Gratuita, por usuario, en la caja fuerte de hardware |
| **Recarga EV (OpenChargeMap)** | Opcional — sustituye la clave compartida por tu propia cuota |
| **Actualización automática** | Refresca la posición GPS antes de cada búsqueda. Apagado = búsquedas más rápidas, posición quizá antigua |
| **Cambio automático de perfil** | Conmuta el perfil al cruzar una frontera, para que proveedor y combustible sean correctos automáticamente |

---

## Sincronización y cuenta

<img src="guide/sync-and-account.jpg" width="340" alt="Estado de TankSync, aviso de esquema obsoleto, pasar al correo, consentimientos, ver mis datos">

*Esta pantalla también saca a la luz los problemas — aquí un esquema TankSync autoalojado obsoleto que, por eso, falla en silencio al sincronizar algunas tablas.*

Tratado por extenso en [Privacidad, datos y sincronización → TankSync](User-es-Privacy-Profiles-Sync#tanksync-sincronización-en-la-nube-opcional). Lo esencial:

- **Sparkilo Community / tu propia base / la base de un grupo** — tres formas de despliegue con tres responsables distintos.
- **Anónimo → correo** — *Pasar al correo* conserva tus datos y tu cuenta y añade una forma de iniciar sesión desde otro dispositivo. Una cuenta anónima solo existe en el dispositivo que la creó.
- **Esquema obsoleto** — tras una actualización, quien se autoaloja debe reejecutar el SQL de instalación, o las tablas nuevas fallan en silencio.

---

## Privacidad y datos

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Controles de privacidad: proxy de teselas y carga de logotipos">

*Dos decisiones de privacidad ligadas a la red, cada una expresada por lo que realmente revela.*

- **Cargar las teselas por el proxy Sparkilo** — *activado*: el servidor UE del desarrollador ve el área del mapa y tu IP y recupera las teselas por ti. *Apagado*: las teselas vienen de tile.openstreetmap.org, que entonces ve tu IP. Ninguna opción significa « sin red »; eliges por quién ser visto. La versión F-Droid nunca usa el proxy.
- **Cargar los logotipos de marca desde internet** — *apagado* por defecto; se usan logotipos genéricos incluidos. Activado, vienen de logo.clearbit.com, que ve tu IP.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Uso del almacenamiento desglosado por categoría con tamaños">

*El almacenamiento, desglosado. La caché es casi siempre la porción mayor y la única que se puede tirar sin riesgo.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Duraciones de caché por categoría y acción Vaciar la caché">

*Gestión de la caché, con la vida de cada clase: búsquedas 5 min, detalles de estación 15 min, consultas de precio 5 min, datos de favoritos 30 min, búsquedas de ciudad 30 min, geocodificación de código postal 24 h.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Diálogo de confirmación del vaciado de caché">

*Vaciar la caché borra solo resultados y precios almacenados — perfiles, favoritos y ajustes se conservan. Las siguientes búsquedas serán más lentas; no se pierde nada.*

---

## Copia de seguridad y restauración

<img src="guide/backup-restore.jpg" width="340" alt="Entradas Exportar copia y Restaurar copia">

*Un ZIP completo con vehículos, repostajes, viajes y registros de recarga.*

**Exportar copia** escribe el ZIP en tus Descargas. **Restaurar copia** ofrece *fusionar* o *reemplazar* — fusionar conserva lo que hay en el dispositivo y añade lo que falta; reemplazar borra primero. Úsalo antes de cambiar de teléfono o de un restablecimiento de fábrica. TankSync no es una copia de seguridad: replica categorías escogidas, no todo.

---

## Avanzado y desarrollador

<img src="guide/advanced-developer.jpg" width="340" alt="Campo del token PAT de GitHub y entrada Herramientas de desarrollo">

*El token de GitHub es opcional — sin él, un informe de escaneo fallido se comparte a mano en lugar de abrir automáticamente una incidencia.*

La entrada **Herramientas de desarrollo** solo aparece con el modo desarrollador activo (Funciones y modo de uso → Desarrollador y experimental).

<img src="guide/developer-tools-1.jpg" width="340" alt="Herramientas de desarrollo: registro de errores, notificación de prueba, canal de alerta de prueba, diagnóstico, probador OCR, vaciar cachés">

*Para un usuario normal el registro de errores es la parte útil: **Guardar el registro de errores** escribe trazas depuradas en Descargas, para adjuntar a un informe.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Copiar diagnóstico, exportar traza de acceso a datos, traza de inicialización al arranque">

*La traza de arranque es una cascada de las fases de inicialización — así se diagnostica un arranque lento en vez de adivinarlo.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Probar la superposición de aproximación e info de compilación con versión y canal">

***Probar la superposición de aproximación** fuerza un estado sintético durante 30 s para verificar la visualización de precio superpuesta sin salir a conducir.*

---

## Acerca de

<img src="guide/about-1.jpg" width="340" alt="Acerca de: versión y número de compilación, autor, licencia, política de privacidad, GitHub, informar de un fallo">

***Versión y número de compilación** — cítalos ambos en cualquier informe, y compruébalos primero cuando una corrección « no ha funcionado » (puede que el despliegue de la tienda no te haya llegado aún).*

<img src="guide/about-2.jpg" width="340" alt="Acerca de: enlaces de apoyo y atribuciones de datos">

*La app es gratuita, de código abierto y sin publicidad. Las atribuciones de los datos de precios y de mapa están al pie, como exigen las licencias.*

---

**Ver también:** [Cómo funciona Sparkilo](User-es-How-It-Works) · [Privacidad, datos y sincronización](User-es-Privacy-Profiles-Sync)
**Siguiente:** [Privacidad, datos y sincronización →](User-es-Privacy-Profiles-Sync)
