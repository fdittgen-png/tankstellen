# Registro de repostajes y consumo

Niveles 2 y 3 de los [tres niveles de ahorro](User-es-How-It-Works#los-tres-niveles-de-ahorro): cuánto quemas, y cuánto costó de verdad. La pestaña ⛽ **Combustible** aparece en los modos **Intermedio** y **Completo**.

---

## La pestaña Combustible de un vistazo

<img src="guide/fuel-tab.jpg" width="340" alt="Pestaña Combustible: nivel del depósito con autonomía, ficha de estadísticas con insignia de precisión, lista de repostajes">

*Tres bloques: qué hay en el depósito, cuánto cuesta tu conducción, y qué has puesto de verdad.*

### Nivel del depósito y autonomía

El indicador está **anclado a tu último depósito lleno**, y luego se descuenta el combustible consumido por los viajes grabados. El sello bajo la barra indica a qué repostaje está anclado.

Se muestran dos autonomías a propósito:

- **« ≈ 548 km al consumo de tu último depósito »** — el comportamiento reciente, útil hoy.
- **« Media a largo plazo: ≈ 611 km »** — tu media histórica, útil para planificar.

Si divergen mucho, algo ha cambiado recientemente: un cofre de techo, el invierno, otra mezcla de vías, o un cambio de combustible.

> Cuando hay un adaptador OBD2 conectado y el coche publica el PID de nivel de combustible, el indicador pasa al **sensor del depósito** y lo declara. Ese valor es una medida, no una deducción, y sobrevive a los viajes no grabados.

### La ficha de estadísticas

Las tres insignias son la capa de honestidad:

| Insignia | Significado |
|---|---|
| **Precisión: Alta · ±3-7 %** | Repostajes y viajes OBD2 alimentan ambos el modelo |
| **Precisión: Media** | Los repostajes lo anclan, pero ningún viaje OBD2 ha alimentado aún el bucle |
| **Precisión: Baja** | Solo GPS, nada anclado — añade un par de depósitos llenos |
| **η_v : 0,93 · 6 muestras** | El rendimiento volumétrico aprendido del modelo speed-density y sus muestras |

Debajo: media L/100 km, coste medio por km, litros totales, gasto total, número de repostajes. Un toque abre las [estadísticas completas](#estadísticas-de-consumo).

---

## Registrar un repostaje

Toca **➕ Añadir repostaje** — o mucho más rápido: **Añadir repostaje** directamente en la página de detalle de una estación, que rellena estación, combustible y precio.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Formulario de repostaje rellenado con marca, combustible y precio de una búsqueda reciente">

*Desde una estación, tres campos ya son correctos — tecleas litros, total y cuentakilómetros.*

| Campo | Por qué importa |
|---|---|
| **Fecha** | Ordena las ventanas de depósito |
| **Vehículo** | Atribuye el repostaje y la calibración |
| **Tipo de combustible** | En un flex-fuel toda la comparación depende de este campo |
| **Litros** | El numerador de la verdad del surtidor |
| **Coste total** | Coste por km, gasto mensual |
| **Cuentakilómetros** | **El campo más importante del formulario** |
| **Depósito lleno** | Cierra una ventana de calibración — ver abajo |
| Estación, notas | Opcionales |

### Por qué el cuentakilómetros es el campo crítico

El consumo es litros ÷ kilómetros. Los litros vienen del recibo y son exactos. Los kilómetros vienen de *tus dos lecturas del cuentakilómetros*. Un error de 20 km en un depósito de 600 km es un 3 % de error — y como ese resultado recalibra el estimador, el error se propaga a toda estimación futura. El formulario rechaza un cuentakilómetros inferior al del repostaje anterior, porque la distancia no retrocede.

### La casilla « Depósito lleno »

Márcala siempre que llenes hasta arriba. Es lo que convierte dos repostajes en una **ventana cerrada** con un consumo físicamente verdadero.

Los repostajes parciales se registran igualmente, cuentan para el coste y salen en la lista — simplemente no pueden cerrar una ventana. La pantalla de estadísticas muestra un aviso que cuenta los *« repostajes parciales pendientes de un depósito lleno — fuera de la media »*, para que siempre sepas qué hay en los números.

### Escanear en vez de teclear

- **Escanear la pantalla del surtidor** — apunta la cámara al display; la app lee litros, total y precio.
- **Escanear el recibo** — lo mismo desde el ticket impreso.
- **Compartir una foto de recibo** desde otra app directamente al formulario.

El reconocimiento se ejecuta **en el dispositivo**; la imagen nunca se sube. Echa siempre un vistazo a los valores antes de guardar — un escaneo es una ventaja, no un oráculo. Si se equivoca, *Informar de error de escaneo* abre una incidencia con el recorte para mejorar el reconocimiento.

> **Versión F-Droid:** el reconocimiento de texto en el dispositivo solo existe en las versiones de Play / App Store. La versión F-Droid sin GMS no tiene escaneo — allí los repostajes se teclean a mano. Todo lo demás es idéntico.

---

## El informe del depósito — el momento de la verdad

Cada vez que un depósito lleno se cierra, la app publica un informe. En la pestaña Viajes aparece así:

<img src="guide/trips-tab.jpg" width="340" alt="Informe del depósito: 6,4 L/100 km, diferencia con el anterior, barra de cobertura y veredicto de calibración">

*Una ficha, cuatro afirmaciones distintas — y deliberadamente no son el mismo número.*

| Línea | Qué es |
|---|---|
| **6,4 L/100 km** | La **verdad del surtidor** de este depósito: litros repostados ÷ kilómetros del cuentakilómetros |
| **1,5 L/100 km menos que el repostaje anterior** | Tendencia frente al último depósito cerrado |
| **559 km · 35,7 L · 32,12 €** | La ventana en bruto |
| **Las grabaciones cubren el 81 % de este depósito** | Qué parte de esos kilómetros grabaste de verdad |
| **Parte grabada: 10,5 L/100 km** | Lo que dieron por sí solos los kilómetros grabados |
| **Las estimaciones grabadas están un 39 % por encima de la verdad del surtidor** | El veredicto de calibración — el estimador iba alto y acaba de corregirse |

### Leerlo bien

La parte grabada y la verdad del surtidor **pueden diferir**, por dos motivos distintos que es fácil confundir:

1. **La selección.** Grabas los viajes que grabas. Si tu 81 % es sobre todo urbano corto y el 19 % ausente es un tramo de autopista, la parte grabada es legítimamente más alta que la media del depósito. Nada está roto.
2. **La calibración.** El propio estimador puede estar sesgado. Eso es lo que mide la última línea, comparando ambos **por kilómetro**, de modo que la cobertura se cancela y solo determina el peso de la ventana.

Tras una corrección como esta, espera que las estimaciones de viaje bajen notablemente en el siguiente trayecto y luego se estabilicen. El mecanismo completo: [Cómo funciona Sparkilo → Cómo un litro se convierte en un número](User-es-How-It-Works#cómo-un-litro-se-convierte-en-un-número).

La ficha también puede señalar *qué cambió* — proporción de alto régimen, eventos bruscos por 100 km, arranques en frío, proporción de ralentí, cada uno frente al depósito anterior — con la salvedad explícita de que las grabaciones son espontáneas y solo cubren parte del depósito.

---

## Estadísticas de consumo

Toca la ficha de estadísticas, o **Combustible → Estadísticas de consumo**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="Cabecera de estadísticas: chips de filtro por combustible, totales y tabla este mes vs mes pasado">

*Los chips de arriba restringen todo lo de abajo a un combustible — imprescindible en un flex-fuel, donde una media combinada no significa nada.*

La tabla mensual muestra litros, gasto, precio medio por litro, consumo medio, coste por km y número de repostajes, cada uno con su diferencia. Las flechas rojas no son un juicio — un *gasto* en alza tras un *precio por litro* en alza es el mercado, no tu pie derecho. La cifra a vigilar para la conducción es **L/100 km**.

### Coste por kilómetro por combustible

<img src="guide/consumption-stats-2.jpg" width="340" alt="Coste por kilómetro por combustible: filas E85 y E5 con coste/km, L/100 km, precio pagado y CO2">

*La verdadera pregunta de quien conduce flex-fuel, resuelta: no qué combustible cuesta menos por litro, sino cuál cuesta menos por kilómetro.*

Cada combustible tiene una fila construida solo sobre **ventanas de depósito cerradas**: L/100 km medidos, precio realmente pagado por litro, coste por 100 km, gasto total, distancia medida, litros consumidos, CO₂ por 100 km, y cuántos depósitos llenos hay detrás. Una fila apoyada en un solo depósito se marca **Provisional**.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Ficha de veredicto sobre el coste de uso con el ganador, el punto de equilibrio y la nota de CO2">

*La ficha de veredicto anuncia el ganador, la diferencia por 1000 km y — lo más útil — el **precio de equilibrio**.*

La línea de equilibrio (« E5 pasa a ser mejor que E85 por debajo de 0,75 €/L ») se calcula a partir de **tu propio consumo medido de cada combustible**: se mueve por tanto con tu conducción. Es una regla de decisión utilizable en el surtidor; una proporción genérica de internet no lo es.

Las cifras de CO₂ son estimaciones de pozo a rueda (EU JEC WTW v5) aplicadas a tu consumo medido — concienciación, no contabilidad certificada. Las mezclas quedan fuera del CO₂ porque el factor de emisión depende de la mezcla, que la fila no registra.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Evolución en el tiempo: litros por mes y gasto por mes, apilados por combustible">

*Los gráficos de tendencia apilan por combustible: un cambio aparece como un color que sustituye a otro, no como un salto misterioso.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Precio por litro y L/100 km por mes">

*Precio por litro y L/100 km son dos gráficos distintos a propósito — uno es el mercado, el otro eres tú.*

**Exportar** escribe todo en CSV en tu carpeta pública de Descargas.

---

## Eco-puntuación por repostaje

Cada repostaje recibe una insignia comparada con la media móvil de tus tres últimos repostajes del mismo combustible:

| Diferencia | Insignia | Cómo leerlo |
|---|---|---|
| ≥ 3 % mejor | 🟢 Mejorando | Notablemente menos que tu propia referencia |
| dentro de ±3 % | ⚪ Estable | Variación normal |
| ≥ 3 % peor | 🟠 Empeorando | Revisa presión de neumáticos, cofre, frío, mezcla de vías |

La insignia sigue oculta hasta que tengas cuatro repostajes de ese combustible, para que la referencia sea real.

---

## Cuando las cuentas no cuadran

Antes o después repostarás más litros de los que tus viajes grabados pueden explicar — condujo otra persona, el adaptador estaba desenchufado, la app cerrada. En lugar de absorber la diferencia en silencio, la app muestra un **aviso de desfase** y propone una breve reconciliación:

> *Hemos encontrado un desfase de 4,2 L. Repostaste 35,7 L, pero tus viajes grabados solo explican 31,5 L.*

Hace dos preguntas:

1. **¿Están todos los repostajes de este depósito completos y correctos?** — No significa que falta uno o está mal tecleado, y la app añade un **repostaje de corrección** para que los litros cuadren.
2. **¿Están todos tus trayectos grabados?** — No significa que falta un trayecto, y la app añade un **viaje virtual** para la distancia que falta.

Ambos elementos son luego editables y borrables, y ambos están marcados como generados automáticamente para que nunca los confundas con datos reales. También puedes elegir **Decidir más tarde** — el aviso permanece hasta que lo resuelvas.

**Por qué importa:** un desfase sin resolver sesga en silencio la ventana de calibración. Resolverlo (o borrar la entrada errónea) mantiene fiable el anclaje al surtidor.

---

## Tarjetas de fidelidad

**Ajustes → Conducción y consumo → Tarjetas de fidelidad** guarda los descuentos por litro de las cadenas que usas. El descuento se aplica luego en las comparaciones de precio, así que una estación aparentemente 2 cts/L más cara puede resultar correctamente la más barata para ti. La función se activa en Funciones y modo de uso → Entrada y escaneo.

---

<details>
<summary>Vista completa — estadísticas de consumo, página entera</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Estadísticas de consumo completas ensambladas a partir de cinco capturas">

</details>

---

**Ver también:** [Vehículos y OBD2](User-es-Vehicles-And-OBD2) · [Viajes y eco-coaching](User-es-Trips-And-Coaching)
**Siguiente:** [Viajes y eco-coaching →](User-es-Trips-And-Coaching)
