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

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Controles de privacidad: proxy de mosaicos del mapa y carga de logos de marcas">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Uso de almacenamiento desglosado por categoría con tamaños">

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

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Vida útil de la caché por categoría y la acción de limpiar la caché">

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

<img src="guide/sync-and-account.jpg" width="340" alt="Sincronización y cuenta con el estado de TankSync, un aviso de esquema obsoleto y la entrada Consentimientos">

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

Para una instantánea restaurable en vez de una exportación de datos, usa **Ajustes → Copia de seguridad y restauración** — ver [Referencia de ajustes](User-es-Settings-Reference#copia-de-seguridad-y-restauración).

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

**Ver también:** [Referencia de ajustes](User-es-Settings-Reference) · [Cómo funciona Sparkilo → Dónde viven tus datos](User-es-How-It-Works#dónde-viven-tus-datos)
**Siguiente:** [Solución de problemas y FAQ →](User-es-Troubleshooting-FAQ)
