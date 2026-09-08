# Solución de problemas y FAQ

Ordenado aproximadamente por frecuencia real.

---

## Antes de nada: comprueba tu versión

<img src="guide/about-1.jpg" width="340" alt="Pantalla Acerca de con la versión y el número de compilación">

*Ajustes → Acerca de. Cita **ambos** en cualquier informe.*

Buena parte de los « sigue sin funcionar » es un despliegue de tienda que aún no ha llegado al dispositivo. Si el número de compilación es anterior a la versión con la corrección, no hay nada que depurar.

---

## « No se han encontrado precios »

1. **Comprueba el país del perfil.** Un perfil alemán llama a la API alemana; en España no encontrará nada. Ajustes → Perfiles y región → Región.
2. **Alemania: ¿está puesta la clave API?** Ajustes → Fuentes de datos y ubicación — una cruz roja en *Precios de combustible (Tankerkoenig)* es la respuesta.
3. **¿Estás sin conexión?** Los precios en vivo requieren una llamada de red. Los precios en caché siguen visibles, marcados como obsoletos.
4. **Caída del proveedor.** Los servicios públicos de datos abiertos se caen a veces. Reinténtalo en unos minutos.
5. **Caché obsoleta.** Tira para actualizar, o toca el icono de refresco.

---

## Alemania: « Falta la clave API » o « Clave no válida »

- Consigue una clave gratuita en [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); es un UUID.
- Pégala en **Ajustes → Fuentes de datos y ubicación → Precios de combustible (Tankerkoenig)**.
- ¿Sigue fallando? La clave puede estar limitada. Las claves son personales — no las publiques nunca.

---

## No encuentro el botón de búsqueda

Solo hay uno: el botón verde elevado en el centro de la barra inferior. Desde cualquier pestaña abre la hoja de criterios; dentro de la hoja, un segundo toque ejecuta la búsqueda. Si parece atenuado, estás en **modo ruta sin destino**.

---

## La ubicación es « desconocida » o el GPS no engancha

- La ubicación del sistema debe estar activa, con **Mientras se usa** concedido a la app.
- El GPS no engancha en interiores. Sal fuera, o define un **código postal de casa** en el perfil y busca por zona.
- « Solo ubicación aproximada » — activa la ubicación precisa en los permisos del sistema.

---

## El cálculo de ruta es lento o falla

- OSRM es un servicio público gratuito y a veces lento.
- Un corredor multipaís **transmite resultados parciales**; el aviso nombra los proveedores pendientes, y puedes tocar un resultado antes de que lleguen los demás.
- Reinténtalo — la polilínea está en caché, el segundo intento suele ser inmediato.

---

## El adaptador OBD2 no conecta

**No encuentra nada al buscar**

- El contacto debe estar **puesto** (accesorios o marcha). Motor en marcha vale, contacto quitado no.
- El LED del adaptador debe estar fijo. Parpadeante o apagado → vuelve a enchufarlo.
- Bluetooth activo en el teléfono.
- Android 12+: concede **Búsqueda Bluetooth** y **Conexión Bluetooth**.
- Hasta Android 11: el sistema exige la **ubicación** para enumerar dispositivos Bluetooth. Regla de plataforma, no rastreo.

**Lo encuentra, pero la conexión falla**

- *« No responde »* — clon barato. Espera 30 s y reinténtalo; arrancar brevemente el motor suele ayudar.
- *« Fallo de inicialización del protocolo »* — chip ELM327 falsificado. Prueba otro modelo; el vLinker FS es la opción barata fiable.
- *« Permiso denegado »* — vuelve a concederlo en los ajustes del sistema; algunas versiones de Android olvidan los permisos Bluetooth tras un reinicio.

**Conecta y luego se cae en marcha**

Usa **Restablecer la conexión** en la ficha del adaptador del vehículo — repite el saludo sin olvidar el emparejamiento. Si persiste, activa **Ajustes → Conducción y consumo → Registro de depuración OBD2**, haz un viaje, exporta el registro XML y adjúntalo a una incidencia. Luego desactiva el registro.

**El cuentakilómetros marca 0 o está mal**

Tu coche puede no publicar el PID A6. La app reintenta con el PID 31 y el modo 22 del fabricante. Algunos europeos anteriores a 2008 no publican cuentakilómetros por OBD2 — entonces tecléalo en cada repostaje.

---

## La grabación automática no ha saltado

Necesita todo esto:

1. Un adaptador **emparejado a un vehículo**.
2. **Grabación automática** activa para ese vehículo.
3. El permiso de ubicación **« Permitir siempre »**.
4. Bluetooth activo y ninguna optimización de batería que mate la app.

Comprueba también el **umbral de velocidad de inicio** en el editor de vehículo — una salida al paso desde un aparcamiento puede no alcanzarlo nunca.

> **iOS:** el despertar de sistema para « conectar en cuanto el adaptador se enciende » aún no existe ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). En iOS inicia los viajes a mano.

---

## Mi consumo parece equivocado

Ve en este orden:

1. **Abre el viaje y lee la ficha de salud de la comunicación OBD2.** Si la cobertura está muy por debajo del 100 %, los huecos se rellenaron con estimaciones GPS y la media es una mezcla, no una medida.
2. **Mira el informe del depósito en la pestaña Viajes.** Si dice que las estimaciones están un *n* % por encima o por debajo de la verdad del surtidor, la app ya lo sabe y acaba de corregirse — espera movimiento en los próximos viajes.
3. **Comprueba la capacidad del depósito** en el vehículo. Una capacidad errónea produce durante meses autonomías creíbles pero equivocadas.
4. **Comprueba tus kilometrajes.** El consumo es litros ÷ kilómetros, y los kilómetros vienen enteramente de lo que tecleas.
5. **Comprueba si marcaste « Depósito lleno ».** Solo las ventanas de lleno a lleno pueden calibrar algo.
6. **Mira la insignia de precisión** en la pestaña Combustible. *Baja* significa que nada ha anclado aún el modelo — la cifra es una salida de modelo, y lo declara.

Contexto: [Cómo funciona Sparkilo → Cómo un litro se convierte en un número](User-es-How-It-Works#cómo-un-litro-se-convierte-en-un-número).

---

## « Hemos encontrado un desfase de X litros »

Has repostado más de lo que tus viajes grabados explican. Responde a las dos preguntas de la reconciliación: un repostaje ausente o mal tecleado recibe una **entrada de corrección**, un trayecto no grabado recibe un **viaje virtual**. Ambos siguen siendo editables. Dejarlo sin resolver sesga la calibración, así que dos toques valen la pena. Ver [Registro de repostajes y consumo](User-es-Fuel-And-Consumption#cuando-las-cuentas-no-cuadran).

---

## La miniatura superpuesta no muestra un precio

La superposición de aproximación solo salta mientras **se graba un viaje** *y* estás dentro del radio. Para verificar la presentación sin conducir: **Ajustes → Herramientas de desarrollo → Probar la superposición de aproximación** fuerza un estado sintético durante 30 segundos.

---

## Las notificaciones de alerta no llegan

- ¿Están permitidas las notificaciones del sistema para la app?
- Ahorro de batería: los modos agresivos de Android matan el trabajo de fondo. Pon la app en **sin restricciones**.
- El teléfono pudo estar sin conexión en la franja prevista; la comprobación se retoma en la siguiente ventana de red.
- El precio quizá simplemente no ha cruzado el umbral.
- El sello **Última comprobación** al pie de la pantalla de alertas dice si la tarea se ejecuta. Sello viejo + cero disparos = el sistema la está matando.

---

## El widget de pantalla de inicio está congelado

- Android limita las actualizaciones de widget a una cada 30 minutos aproximadamente; es política del sistema.
- Toca el **icono de refresco del propio widget** — recarga los precios sin abrir la app.
- Aspecto y variante de contenido se fijan por perfil en **Ajustes → Unidades y visualización**.

---

## El mapa muestra teselas grises o vacías

- Suele ser una conexión débil; desliza para refrescar.
- Si persiste, los servidores de teselas pueden estar limitando — reinténtalo en unos minutos.
- Prueba a conmutar **Ajustes → Privacidad y datos → Cargar las teselas por el proxy Sparkilo**; los dos caminos fallan de forma independiente.

---

## El escaneo de surtidor o recibo no lee nada

- La versión **F-Droid** no tiene escaneo alguno — el reconocimiento de texto en el dispositivo solo existe en las versiones de Play / App Store. Teclea el repostaje a mano.
- El reflejo en el display del surtidor es la causa más común. Haz sombra, colócate de frente, llena el encuadre con las cifras.
- Si lee las etiquetas pero no los números, usa **Informar de error de escaneo** para que el recorte sirva para mejorar el reconocimiento.

---

## La app tarda mucho en arrancar

Activa **Traza de inicialización al arranque** (Funciones y modo de uso → Desarrollador y experimental), reinicia y abre las **Herramientas de desarrollo**. La cascada nombra la fase lenta; expórtala y adjúntala a una incidencia.

<img src="guide/developer-tools-2.jpg" width="340" alt="Traza de inicialización al arranque en cascada con los tiempos por fase">

*Cada barra es una fase de inicialización con su duración — un arranque lento deja de ser una suposición.*

---

## La app se cierra al arrancar

- Vacía la caché desde los ajustes de aplicaciones del dispositivo.
- Si persiste, abre una incidencia con la versión de Android, el modelo del teléfono, la versión **y el número de compilación** de Ajustes → Acerca de, y el registro de errores guardado (la app lo ofrece en el siguiente arranque; el archivo va a Descargas).

---

## ¿Cómo hago copia de seguridad?

**Ajustes → Copia de seguridad y restauración → Exportar copia** escribe un ZIP en Descargas; la restauración ofrece fusionar o reemplazar. Para una exportación legible por máquina, usa en su lugar **Privacidad y datos → Exportar o eliminar → Exportar mis datos → Archivo ZIP**.

TankSync **no** es una copia de seguridad — replica categorías escogidas, y los viajes solo si también activaste su sincronización.

---

## ¿Cómo lo borro todo?

- **Dispositivo:** Privacidad y datos → Exportar o eliminar → **Eliminar todos mis datos**. Irreversible.
- **Servidor (TankSync):** borra primero el lado servidor — Sincronización y cuenta → Transparencia de datos → **Eliminar cuenta** quita cada fila de tu propiedad en una transacción y nombra cualquier tabla que no se haya podido borrar.

Detalles: [Privacidad, datos y sincronización → Tus derechos](User-es-Privacy-Profiles-Sync#tus-derechos-según-el-rgpd).

---

## ¿Puedo usar la app sin conexión?

En parte. Los favoritos muestran sus últimos precios conocidos, las teselas vistas recientemente están en caché, y repostajes y viajes son enteramente locales. Descubrir estaciones nuevas requiere una llamada de red.

---

## ¿Dónde se ha ido la pestaña Combustible o Viajes?

Pertenecen a los modos **Intermedio** y **Completo**. Si una ha desaparecido, un preajuste o un interruptor la ha apagado: Ajustes → Funciones y modo de uso → Consumo.

---

## Más ayuda

- **Fallos:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — usa la plantilla Bug Report y adjunta el registro de errores guardado.
- **Ideas:** la plantilla Feature Request, o primero las [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Dudas de privacidad:** la [política de privacidad](https://fdittgen-png.github.io/tankstellen/privacy-policy/), o fdittgen@gmail.com.

---

**Volver a:** [la portada de la guía](User-es-Home)
