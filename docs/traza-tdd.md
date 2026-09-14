# Traza TDD

La traza de los ciclos: rojo, verde y qué quedó implementado. Empieza con `print_it`
y sigue con el flujo MCP y las herramientas del Browser.

Registro del orden en que se escribieron los tests y qué se implementó en cada
paso. Trabajo hecho **sobre la imagen viva** (Cuis 7.8, categoría `MCPServer`),
enviando código por el endpoint HTTP que ya estaba corriendo.

Regla seguida: un test mínimo que agrega funcionalidad nueva y **no pasa**;
implementar lo mínimo para que pase; siguiente test.

## La herramienta

`print_it` es la análoga al **print it** del Workspace: recibe código, lo evalúa
y responde la representación impresa del resultado. El original está en
`SmalltalkEditor>>printIt`, que evalúa la selección y usa
`printTextLimitedTo: 10000`; nuestro `printIt:` usa el mismo límite.

Su declaración, en la fachada:

```smalltalk
printIt: aCodeString
	"Evaluate aCodeString and answer the printed representation of the result, the
	way the Workspace print-it does. The output is limited to 10000 characters,
	as in the editor."
	<mcpTool: #print_it system: 'Workspace' arguments: #('code')>
	^ (Compiler evaluate: aCodeString) printStringLimitedTo: 10000
```

## Los ciclos

| # | Test | Rojo (evidencia) | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 1 | `test01PrintItEvaluatesAndAnswersThePrintedResult` | `ERROR MessageNotUnderstood: UndefinedObject>>new` | `run=1 passed=1` | `MCPServerWorkspaceTools` + `printIt:` (la operación) |
| 2 | `test02TheToolDeclaresItselfWithAPragma` | `passed=0 failures=1` | `passed=1` | el pragma `<mcpTool: #print_it system: 'Workspace' arguments: #('code')>` |
| 3 | `test03TheDescriptorIsBuiltFromThePragma` | `ERROR ... UndefinedObject>>forMethod:` | `passed=1` | `MCPServerToolDescriptor` + su fábrica `forMethod:` |
| 4 | `test04TheDescriptionComesFromTheMethodComment` | `ERROR ... UndefinedObject>>fromSource:` | `passed=1` | `MCPServerMethodComment` + `description` en el descriptor |
| 5 | `test05TheToolExecutesAndAnswersAResult` | `ERROR ... UndefinedObject>>on:` | `passed=1` | `MCPServerToolResult` (valor) y `MCPServerTool` (comando) |
| 6 | `test06TheCatalogueIsBuiltFromTheDeclarations` | `ERROR ... UndefinedObject>>buildFrom:` | `passed=1` | `MCPServerToolCatalogue` (inmutable) y `MCPServerCatalogueBuilder` |
| 7 | `test07AFailingExpressionAnswersAnErrorResult` | `ERROR MessageNotUnderstood: SmallInteger>>zork` (la excepción se escapaba: justo lo que el test cambia) | `passed=1` | mapeo del error a un resultado con `isError` |

**Suite completa: 7 tests, 7 en verde, 0 fallos, 0 errores.**

## Cosas del entorno que marcaron el ritmo

- **SUnit en Cuis captura sólo `UnhandledError`** (`TestResult>>runCase:`), y el
  handler del endpoint atrapa `Error`. Consecuencia: un test que *levanta* una
  excepción en vez de fallar una aserción no se registra como error del test: la
  excepción llega al endpoint y la respuesta es un texto `ERROR ...`. Los rojos
  de los ciclos 1, 3, 4, 5, 6 y 7 son de ese tipo (clase que todavía no existe), y
  se leen como rojo igual, pero sin contar como error.
- Por eso el corredor de tests **no** envuelve la corrida en `on: Error do:`:
  envolverla le rompe la captura a SUnit.
- Un error de **sintaxis** en un doit enviado por el endpoint no avisa: el
  `Compiler` falla en silencio y devuelve `nil` (pasó en el primer intento del
  ciclo 1: las temporales estaban en el medio del doit y el script no hizo nada).
- Las comillas dentro de una cadena que a su vez es fuente hay que **duplicarlas**;
  olvidarlo corta la cadena externa y aparecen errores raros (`String>>:`).

## Errores propios del trabajo (y cómo se detectaron)

| Error | Cómo se detectó |
| --- | --- |
| `self isQuote: ch or: [...]` parseado como el mensaje `#isQuote:or:` | el test falló con `MCPServerMethodComment class>>isQuote:or:` |
| `self isQuote: ch ifTrue: [...]` parseado como `#isQuote:ifTrue:ifFalse:` | ídem, con el selector completo |
| comillas sin duplicar en la fuente de un método | el compilado no cambió y el error fue `String>>:` |
| temporales en el medio del doit | el script no hizo nada y devolvió `nil` |
| `removeSelector:ifAbsent:` (no existe en Cuis) | `MCPServerTest class>>removeSelector:ifAbsent:` |

## Clases creadas, con su responsabilidad

Todas en la categoría `MCPServer`, con la responsabilidad escrita en el comentario
de clase.

| Clase | Responsabilidad |
| --- | --- |
| `MCPServerWorkspaceTools` | La fachada del Workspace: sus operaciones expuestas como herramientas. Sin estado y sin estado de ventana. |
| `MCPServerToolDescriptor` | Lo que la declaración dice, como dato: nombre expuesto, ventana, nombres de argumentos, y la referencia al método. Objeto de valor; se crea con `forMethod:`. |
| `MCPServerMethodComment` | Lee el comentario de un método desde su fuente (el comentario vive en el archivo de fuentes, el pragma en la imagen). |
| `MCPServerToolResult` | Lo que una herramienta responde: texto y si es error. Objeto de valor. |
| `MCPServerTool` | La herramienta como comando: el descriptor más saber ejecutarse. No guarda el receptor: la fachada no tiene estado, así que una instancia nueva por llamada alcanza. |
| `MCPServerToolCatalogue` | El conjunto de herramientas, como búsqueda por nombre. Inmutable una vez construido: por eso se puede compartir entre conexiones sin locks. |
| `MCPServerCatalogueBuilder` | Construye el catálogo leyendo los pragmas. La declaración y la implementación son el mismo método, así que no pueden desincronizarse. |

`MCPServer` (la raíz de composición del diseño) y `MCPServerTest` ya existían en
la imagen; los tests nuevos viven en `MCPServerTest`. Se quitó el placeholder
`test01`, que devolvía un símbolo y no afirmaba nada.

## Reorganización de los tests (a pedido)

Los tests vivían todos en `MCPServerTest`, que es la clase de test de `MCPServer`.
Ahora hay una clase de test por clase bajo prueba, todas en la categoría
`MCPServerTest`, y `MCPServerTest` quedó para la clase homónima:

| Clase de test | Clase bajo prueba |
| --- | --- |
| `MCPServerWorkspaceToolsTest` | `MCPServerWorkspaceTools` |
| `MCPServerMethodCommentTest` | `MCPServerMethodComment` |
| `MCPServerToolDescriptorTest` | `MCPServerToolDescriptor` |
| `MCPServerToolTest` | `MCPServerTool` |
| `MCPServerToolCatalogueTest` | `MCPServerToolCatalogue` |
| `MCPServerProtocolTest` | `MCPServerProtocol` |
| `MCPServerTest` | `MCPServer` |

Los nombres y los comentarios de los tests quedaron en inglés, y `MCPServerTest` se
movió a la categoría de tests (es un TestCase, no producción).

## El flujo MCP (ciclos 8 a 16)

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 8-13 | `MCPServerProtocolTest`: initialize, tools/list, tools/call, herramienta desconocida, error de la herramienta, notificación (6 tests) | `UndefinedObject>>on:` | 6/6 | `MCPServerProtocol`: los métodos del protocolo, el esquema de argumentos y las formas de respuesta |
| 14-16 | `MCPServerTest`: catálogo propio, cuerpo JSON-RPC de ida y vuelta, notificación sin respuesta (3 tests) | `MCPServer class>>on:tools:` | 3/3 | `MCPServer`: raíz de composición, endpoint `/mcp` en loopback, JSON adentro y afuera |

## Verificación de punta a punta (contra la imagen viva)

Levantado con `MCPServer on: 8790 tools: { MCPServerWorkspaceTools }` y `start`, y
hablándole MCP por HTTP en `/mcp`:

| Pedido | Respuesta |
| --- | --- |
| `initialize` | `{"jsonrpc":"2.0","id":1,"result":{"capabilities":{"tools":{}},"serverInfo":{"name":"MCPServer","version":"0.1"},"protocolVersion":"2025-06-18"}}` |
| `notifications/initialized` | HTTP 200, cuerpo vacío |
| `tools/list` | `print_it`, con la descripción tomada del comentario del método y el `inputSchema` del pragma |
| `tools/call` con `(1 to: 10) inject: 0 into: [:a :b | a + b]` | `{"isError":false,"content":[{"type":"text","text":"55"}]}` |
| herramienta desconocida | error JSON-RPC `-32602` |
| expresión que falla (`1 zork`) | `{"isError":true,"content":[{"type":"text","text":"MessageNotUnderstood: SmallInteger>>zork"}]}` |

**Lo que encontró el e2e y no los tests:** `MCPServer>>handleRequest:` usaba
`body ifNil: [...] ifFalse: [...]`, que no es un mensaje de `Object` (es de `nil`),
así que el endpoint devolvía 500. Los tests unitarios no lo cubrían porque llaman a
`handleRequestBody:` directo, sin pasar por el pedido HTTP. Se arregló con
`isNil ifTrue:ifFalse:`.

## Las herramientas del Browser (ciclos 17 a 21)

Con `print_it` andando, el paso siguiente fue el Browser: las operaciones que un
programador hace desde sus paneles. La fachada es `MCPServerBrowserTools`, y sus
herramientas escriben en la imagen, así que los tests compilan y borran métodos en una
clase de trabajo (`MCPServerBrowserToolsScratch`), nunca en el código real.

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 17 | los selectores de una clase (los dos lados, por categoría de método), la fuente de un método y el lado de clase dicho con el nombre (`Foo class`) | la clase no existía (`UndefinedObject>>new`) | 3/3 | `selectorsOfClass:`, `sourceOfMethod:inClass:` |
| 18 | el comentario de clase, los remitentes de un selector y las guardas de error (clase o selector que no existen) | `MCPServerBrowserTools>>commentOfClass:` | 7/7 | `commentOfClass:`, `allCallsOn:` |
| 19 | compilar y remover un método | `MCPServerBrowserTools>>compileMethod:inClass:classified:` | 11/11 | `compileMethod:inClass:classified:`, `removeMethod:inClass:` |
| 20 | el lado sin métodos no dice `as yet unclassified` (lo encontró el e2e) | 1 fallo | 12/12 | el lado vacío dice `no methods` |
| 21 | dos servidores no comparten el estado (lo encontró el e2e) | 1 fallo | 31/31 | las variables de instancia de `MCPServer`, declaradas y recompiladas |

Y las siete herramientas, con la ventana de la que vienen (el `system` del pragma):

| Tool | Ventana | Qué hace |
| --- | --- | --- |
| `print_it` | Workspace | evalúa el código y contesta el resultado impreso |
| `selectors_of_class` | Browser | los selectores de la clase, por categoría de método, los dos lados |
| `source_of_method_in_class` | Browser | la fuente del método, con su comentario y sus pragmas |
| `comment_of_class` | Browser | el comentario de la clase |
| `all_calls_on` | Browser | quién manda ese selector, escrito como `Clase>>selector` |
| `compile_method_in_class_classified` | Browser | compila la fuente en la clase, bajo esa categoría |
| `remove_method_in_class` | Browser | saca el método de la clase |

### Lo que encontró el e2e (y los tests no)

1. **`MCPServer` no tenía variables de instancia.** Los ocho métodos de la clase
   asignaban `port`, `catalogue` y `webServer` como variables *no declaradas*, y el
   compilador las mandó a `Undeclared`: eran globales, compartidas por todas las
   instancias. Por eso el servidor de demo terminaba contestando con el catálogo del
   último servidor creado (`tools/list` devolvía una sola herramienta después de correr
   los tests). Los tests no lo veían porque cada uno crea un servidor y nunca compara
   dos. Se arregló declarando las variables, recompilando los métodos de la clase y
   borrando los bindings viejos de `Undeclared`; el test que lo cubre es el 21.
   El síntoma parecía un problema del `WebServer`; era un `instanceVariableNames: ''`
   en la definición de la clase.
2. **El lado sin métodos decía `as yet unclassified`**: la imagen deja esa categoría
   vacía en el lado de clase sin métodos (ciclo 20).

### Hallazgos del entorno (los nuevos)

- **Un error inesperado dentro de un test escapa del runner de SUnit**: los ciclos
  rojos no dan `errors=1`, abortan la corrida entera — da igual si es un
  `MessageNotUnderstood` o un `Error: key: '_meta' not found` (los fallos de aserción,
  en cambio, sí se cuentan). Por eso las corridas en rojo se envuelven en un
  `on: Error do:`.
- **`listenOn:interface:` avisa cuando el puerto está tomado** (`Error: Failed to
  listen(interface: #(127 0 0 1) port: 8792 )`); no falla en silencio.
- **`destroy` libera el puerto**: se puede volver a levantar el servidor en el mismo puerto.
- **`MethodReference>>actualClass name` del lado de clase ya dice `Foo class`**, así que
  las referencias se escriben como las escribe el Browser, sin armar el nombre a mano.

## La ventana de origen en el protocolo (ciclo 22)

Cada herramienta es el análogo de una operación que el programador hace en una ventana
de la imagen, y eso se declara en el pragma (`system: 'Workspace'`, `system: 'Browser'`).
Ese dato estaba en el descriptor desde el primer día, pero `tools/list` no lo mandaba:
ahora cada herramienta lo lleva en su `_meta`, que es donde el protocolo deja los datos
propios del servidor.

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 22 | cada herramienta dice de qué ventana viene | `Error: key: '_meta' not found` | 32/32 | `_meta.system` en `MCPServerProtocol>>descriptionOf:` |

Un cliente lo puede usar para agrupar o para mostrar de dónde sale cada herramienta (el
panel de `demo/` lo muestra al lado del nombre).

## El Test Runner y exportar (ciclos 25 a 27)

Para cerrar el ciclo de trabajo faltaban dos cosas: correr los tests y sacar el código
fuera de la imagen. Y una tercera que apareció en el camino: el acceso a la imagen
estaba duplicado en la fachada del Browser, y el Test Runner necesitaba lo mismo.

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 25 | (refactor) el acceso a la imagen pasa a `MCPServerEnvironment`, compartido por las fachadas | — | 35/35 | `MCPServerEnvironment` con `classNamed:` del lado de clase; las ocho llamadas de la fachada del Browser pasan a usarlo |
| 26 | el Test Runner: correr los tests de una clase, y tomar las clases de test de una categoría | `UndefinedObject>>new` (la fachada no existía) | 38/38 | `MCPServerTestingTools`: `runTestsInClass:` y `runTestsInCategory:`, con el resumen de la corrida y cada defecto |
| 27 | el file out de una categoría a un archivo | `MCPServerBrowserTools>>fileOutPackage:to:` | 39/39 | `fileOutPackage:to:` en la fachada del Browser |

El ciclo de 25 fue un refactor: el comportamiento ya estaba cubierto por los tests del
Browser, así que no hubo rojo, y quedó verde igual.

### Lo que encontró este tramo

1. **Un test de tests:** el primer test del Test Runner corría la categoría que contiene
al propio test, y la suite se llamaba a sí misma. Recursión infinita: la imagen quedó
trabada (100% de CPU, sin contestar por ningún puerto) y el VM terminó saliendo al
intentarlo interrumpir desde afuera. No se perdió código: el paquete estaba en `src/` y
todas las fuentes del día en el `.changes`. El test quedó tomando las clases de una
categoría **sin correrlas** (la corrida real se prueba desde afuera, con
`run_tests_in_category`, que es el uso de verdad).
2. **Una imagen nueva pide autor:** la primera vez que se cambia código, Cuis pide el
autor con un diálogo (`Utilities>>setAuthor`, que se cuelga esperando), y con eso el
script de arranque nunca termina. Se arregla antes que nada con
`Utilities setAuthorName: 'Sebastian' initials: 'S.V.'`.
3. **Rearmar el servidor pide una pausa:** destruirlo y crearlo en el mismo pedido deja
el puerto tomado y el nuevo no escucha. Hay que esperar entre `destroy` y `start`
(por eso el script de arranque destruye, espera y recién después crea).
4. **Los requisitos que faltaban:** el paquete usaba `WebServer` (de `WebClient`) y no
lo declaraba, y el de tests no declaraba que necesita `MCPServer`. Ahora sí.

## La firma de los cambios del agente: se probó y se descartó (ciclos 28 y 29)

Un servidor MCP no puede contestar diálogos, y el primer diálogo de toda imagen nueva es
el autor: la primera vez que alguien cambia código, Cuis lo pide (`Utilities>>setAuthor`,
que se queda esperando para siempre). Documentarlo no alcanza: nos mordió dos veces el
mismo día.

El primer intento fue **firmar los cambios del agente**: al arrancar, el servidor se ponía
de autor `MCP(<iniciales del dueño>)`, y se verificó que el stamp sale así, al lado del
del dueño:

```
!MCPServerBrowserToolsScratch methodsFor: 'test' stamp: 'MCP(S.V.) 13/Sep/2026 20:01:17'!
!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:41:59'!
```

**Y se descartó**, por una razón de fondo que trajo Sebastian: el autor significa
**responsabilidad**, y la responsabilidad es de quien autoriza el cambio, escriba con la
herramienta que escriba. Firmar distinto es desligarse: es la misma convención que git,
donde el commit lleva el nombre del humano aunque lo haya escrito con una herramienta, y
la ayuda de la herramienta se anota en el mensaje, no en el autor.

La decisión quedó así:

- **El paquete no firma ni inventa un autor.** Lo que el agente escribe queda a nombre de
  quien es dueño de la imagen.
- **Al arrancar, el servidor exige que haya autor**: lo lee con `authorInitialsPerSe` (que
  no pregunta) y, si falta, no arranca y lo dice. El cuelgue silencioso se convierte en un
  error explícito, al arrancar.
- **La actividad del agente es información, no firma**: va al log del servidor.

### Lo que se aprendió en el camino

- **`Utilities authorInitials` abre el diálogo** si no hay autor; el que lee sin preguntar
  es **`authorInitialsPerSe`**. Con eso, verificar el autor no puede colgarse.
- **Firmar alrededor de cada llamada (en `executeWith:`) es un punto único de falla**: un
  error ahí rompe todas las herramientas, incluidas las puertas con las que uno se repara.
  Se descartó el enfoque, pero la lección queda: una preocupación transversal no puede
  tener el poder de romper la operación. (Si algún día vuelve, va *best effort*.)
- **El stamp se hornea al compilar** (nace con el autor del momento y queda en el
  `.changes`): no se puede reescribir después. La atribución por firma exige decidir
  *antes* de ejecutar; la atribución por log, no.
- **Compilar un test con otro nombre no reemplaza al anterior**: quedaron tres `test06` y
  el más viejo llamaba a código ya borrado, así que la suite no corría. El nombre del test
  es su identidad.

## El rearme del servidor: sin `restart` (ciclos 30 y 31)

**El problema.** `start` sobre un puerto tomado avisaba bien (`Failed to listen`), pero
quedaba el caso peor: un socket que escucha y no contesta, con el servidor *pareciendo*
vivo. Rearmarlo era un ritual manual —destruir, esperar, crear— que se olvida fácil.

**El primer intento** agregó un `restart` que soltaba el puerto a la fuerza (destruyendo lo
que estuviera escuchando ahí) y un `start` idempotente. **Se descartó**, por una razón de
fondo que trajo Sebastian: el puerto es un recurso del sistema operativo, y quien lo tomó lo
tiene; el que llega segundo falla y el que administra mira qué pasa. Ningún servidor serio
mata al otro para quedarse con el puerto, y menos un servidor MCP, que no debe tomar
recursos del host en nombre del cliente.

**Lo que quedó:**

- **`isListening`**: si *este* servidor está escuchando de verdad. Es el que no miente: un
  servidor guardado contesta su puerto y su catálogo aunque nadie escuche (Problema 7).
- **`start` falla si ya está escuchando**: `Already listening on port 8790`. Arrancar dos
  veces es un error que se dice, no una operación que se repite en silencio.
- **Puerto tomado por otro**: el error es distinto y trae el puerto
  (`Could not listen on port 8790: Failed to listen(...)`).
- **No hay `restart`**: mover el servidor es decisión de quien es dueño de la imagen, no algo
  que el servidor haga por sí mismo.

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 30-31 | arrancar dos veces lo dice, y no hay `restart` | el segundo `start` tiraba `Failed to listen`; después, el test nuevo fallaba | 41/41 | `isListening`, `listenOnThePort`, `start` que falla si ya escucha, y el borrado de `restart` y `releasePort:` |

### El fantasma, reproducido (tres experimentos)

1. **La vía mínima**: parar el listener dejando el socket abierto (`stopListener`). El puerto
   queda en LISTEN, el cliente **no** recibe `connection refused` y se cuelga.
2. **La vía realista, que es la que nos pasó**: **destruir el servidor desde un pedido que
   él mismo está atendiendo**. `destroy` mata las conexiones en curso —incluida la del
   pedido— y el socket queda escuchando sin nadie aceptando.
3. **Lo que no lo produce**: que la imagen se muera (el sistema operativo cierra sus sockets
   y el puerto queda libre) y destruir y crear en el mismo pedido desde *otro* servidor
   (anda bien).

Consecuencia práctica: **no autodestruirse desde un pedido**, y si pasa, el rearme es una
decisión desde la imagen (mirar qué `WebServer` está escuchando en ese puerto y destruirlo),
no algo que el servidor haga por su cuenta.

Y una lección de método que ya se repitió dos veces: **compilar un test con otro nombre no
reemplaza al anterior**. Cuando la expectativa cambia, el test tiene que cambiar de cuerpo y
conservar su selector.

## Listar, buscar y refactorizar (ciclos 32 a 34)

Las herramientas que faltaban para completar el catálogo del Browser.

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 32 | las clases de una categoría, la búsqueda de clases y la búsqueda de texto en los métodos | `MCPServerBrowserTools>>classesInCategory:` | 44/44 | `classesInCategory:`, `classesMatching:` y `methodsContaining:`; y el listado acotado, que ya estaba duplicado en dos métodos, se extrajo a `writeLinesFor:labelled:on:` |

| 33 | crear una clase (y negarse a redefinir), borrarla y renombrarla | `MCPServerBrowserTools>>defineClass:subclassOf:variables:category:` | 48/48 | `defineClass:subclassOf:variables:category:`, `removeClass:` y `renameClass:to:` |

De paso se midió lo que cuesta la búsqueda de texto: **18.224 métodos en 2,5 segundos**, con las
fuentes leídas una por una. Es aceptable para una herramienta y para un test, y es el dato que
fija el techo de esa búsqueda.

### El renombre de un método: no hay herramienta, y por qué

Renombrar una **clase** sí se puede en Cuis (`Smalltalk renameClassNamed:as:`, que actualiza las
referencias al global). Renombrar un **selector** no tiene API sin interfaz: la implementación
vive en `Browser>>renameSelector` y en el editor, y pasa por `RefactoringApplier` con el texto del
editor. El objeto `RenameSelector` es sólo una mezcla de ayuda.

Hacerlo a mano significa reescribir las fuentes de todos los remitentes, y eso, con selectores de
varios keywords, envíos anidados y literales con texto adentro, se rompe en silencio.

**Y son dos problemas, no uno** (quedaron como Problema 8 del README):

1. **La revisión necesita estado.** El flujo del Browser es proponer, mostrar el diff, esperar la
   aprobación y aplicar todo junto; ese "esperando aprobación" vive en la ventana. Nuestro servidor
   es sin estado a propósito, así que no puede sostener ese flujo entre pedidos. Es la misma
   familia que el debugger: los dos necesitan una sesión con estado, ya decidida y diferida.
2. **No hay transacción.** En la imagen no hay "todo o nada": si un remitente no compila, el
   cambio queda a medias. La mitigación propuesta es validar antes de tocar, calculando y
   compilando en el aire la fuente nueva de cada remitente con el parser de Cuis; si algo falla, se
   aborta sin haber cambiado nada.

**Decisión: no se implementa por ahora.** El renombre con remitentes queda en el Browser, con el
humano viendo el diff, que es donde Cuis lo hace bien. Sin remitentes, la receta con lo que ya
existe alcanza: compilar el método nuevo con el mismo cuerpo y remover el viejo, y `all_calls_on`
dice si tiene remitentes antes de empezar. Cuando llegue la sesión con estado, este problema y el
del debugger se resuelven juntos.

### Los tests se escriben en archivos

Los cuerpos de los tests van a **archivos** que la imagen lee tal cual (`compile: source`), en vez
de ir como texto anidado dentro de un pedido. Dos veces hoy me mordieron las comillas dobles al
anidar: un test se compiló a medias y el pedido contestó `nil` sin decir nada. El archivo evita el
problema de raíz, y de paso deja los tests en algo que se puede leer y revisar.

## UTF-8 en el borde (ciclos 34 y 35)

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 34 | un cuerpo con bytes UTF-8 llega entero al tool, y la respuesta sale como bytes UTF-8 | el pedido con `café` devolvía cinco caracteres | 50/50 | `textFromWire:` y `wireStringFor:` en el adaptador (`MCPServer`), usadas por `handleRequestBody:` |
| 35 | el file out escribe UTF-8 | pasó en verde de entrada: ya lo era | 50/50 | nada; los archivos ya se escriben UTF-8 porque el VM se lanza con `-encoding UTF-8`, y queda la guarda |

Hallazgos del entorno:

- La capa HTTP de Cuis es de bytes en los dos sentidos: `content` viene con un carácter por byte, y
  `sendResponse:content:` usa `aString size` como tamaño en bytes. Por eso la traducción va en el
  adaptador y no adentro del protocolo.
- **`String>>asUtf8BytesOrByteString` está rota en esta imagen** (`SmallInteger>>isSeparator`); la
  conversión explícita, byte por byte, es la que funciona.
- El file out depende del `-encoding UTF-8` con el que se lanza el VM.

## El handshake le cuenta al cliente (ciclo 36)

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 36 | el `initialize` trae `instructions`, y el texto habla de la imagen viva, compartida y del autor | el test nuevo fallaba: el campo no existía | 52/52 | `MCPServerProtocol>>instructions` (ahí vive el texto) y `initializeResult` lo agrega al handshake |

Qué dice el texto, y qué no:

- **Qué dice** (texto final, escrito por Sebastian): que conecta a un entorno Smalltalk vivo; que
  uno no está editando archivos estáticos en aislamiento sino colaborando dentro de un sistema en
  marcha junto a un humano, y que cada cambio está vivo y presente en su mundo; que el sistema no
  esconde nada y que la libertad de redefinirlo es absoluta, con la contracara de que un descuido
  puede romper el entorno; y que cada modificación lleva la firma del humano, que está poniendo su
  nombre en el trabajo.
- **Qué no dice**, por decisión de Sebastian: no nombra las ventanas. La separación entre Workspace,
  Browser y Test Runner es nuestra, nos sirve para mapear la interfaz, y a un agente no le aporta
  nada. Tampoco enuncia consecuencias concretas ("podría estar editando al mismo tiempo"): es
  **filosofía, no implementación**. Un test lo sostiene: el texto no puede contener la palabra
  "Workspace".

Ver la decisión 5 del README, con su evaluación y su resolución.

## El trabajo del agente, por debajo de la UI (ciclo 37)

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 37 | una herramienta corre a una prioridad menor que la de la UI | la herramienta contestaba 60, la del handler | 53/53 | `MCPServerTool>>executeWith:` lanza un trabajador propio (`workerPriority`: `userInterruptPriority - 10`) y espera su resultado con un semáforo |

Sólo el trabajador: el handler del `WebServer` y todo lo demás quedan con las prioridades de Cuis,
porque en la imagen puede haber otro servidor que no es nuestro. Y ese trabajador es el destinatario
de la cancelación que falta.

### Lo que se aprendió a golpes, en este mismo ciclo

- **`[ ... ] ensure: [ ... ]` no arma el cuerpo de un proceso: evalúa el bloque y contesta su valor.**
  Lo escribí creyendo que sí, así que el bloque corrió en el handler y después le mandé `priority:`
  al resultado. Para envolver el cuerpo de un proceso van **dos bloques anidados**: el de afuera es
  el del proceso, y el `ensure:` va en el de adentro.
- **Un script se compila entero antes de correr**: un error de sintaxis en cualquier parte hace que
  no corra nada, y el pedido contesta `nil` sin decir por qué.
- **El cuerpo de una herramienta corre antes de que falle su resultado**: mientras `executeWith:`
  estaba roto, escribir un archivo desde `print_it` seguía funcionando, y eso fue la puerta para
  repararlo sin ayuda de nadie.
- **No adivinar el estado de un proceso**: creí que `suspendedContext isNil` significaba "muerto" y
  terminé matando el trabajador de mi propio pedido. Un proceso que está corriendo también puede
  tener el contexto en nil.
- Y la de siempre, otra vez: **un test con un número adentro envejece**. El del Test Runner esperaba
  "2 tests" de `MCPServerToolTest` y ahora son tres, así que el número pasó a salir de la clase.

## La cancelación (ciclos 38 a 42)

La otra mitad del problema 1: el trabajador ya tenía prioridad baja, y ahora tiene a quién cortar.

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 38 | el registro de los pedidos en vuelo (7 tests) | `MCPServerInFlightRequests>>isEmpty` no existía | 7/7 | `MCPServerInFlightRequests`: alta bajo el id con **handle**, baja por handle, `cancel:` con la regla del id ambiguo, todo bajo su candado |
| 39 | el alta pasa antes del `resume`, y la baja es de la llamada (3 tests) | `MCPServerTool>>executeWith:under:in:` no existía | 6/6 | la costura en `MCPServerTool`: registro antes de arrancar el trabajador, y baja con el handle en el `ensure:` |
| 40 | la notificación de cancelación (4 tests) | `MCPServerProtocol class>>on:inFlight:` no existía | 12/12 | la rama en `handleMessage:`, `cancelRequestedBy:`, el motivo al Transcript, y el servidor con su propio registro |
| 41 | el `202` de lo que no tiene respuesta | no hubo rojo: la guarda se escribió después | 61/61 | `handleRequest:` contesta `202` sin cuerpo; un pedido cancelado no manda respuesta |
| 42 | cancelar por HTTP, con dos clientes | no hubo rojo: es el e2e que cierra el ciclo | 69/69 | el pedido colgado, la notificación en otro pedido, el `202`, el registro vacío y el servidor que sigue andando |

Los dos últimos se escribieron después de la implementación, y quedan anotados así: el `202` y el
e2e son guardas de lo que ya estaba, no ciclos rojo-verde.

Y al probarlo contra el servidor que estaba vivo apareció un caso más, con su test (el 13): un
servidor que ya existía cuando el registro apareció no tiene ninguno, y una cancelación se le
**ignora** en vez de contestarle un error. Con eso, **70 tests en verde**.

### Lo que se aprendió, y casi todo fue del instrumento

- **Medir con un instrumento sin probarlo es medir cualquier cosa.** Mi primer experimento dijo que
  el `ensure:` no despertaba al que esperaba. Era falso: en esta imagen
  `Semaphore>>waitTimeoutMSecs:` contesta **al revés** de lo que yo suponía (con una señal pendiente
  da `false`; vencido, `true`). Lo descubrí probando el instrumento solo. Si una medición
  contradice a la fuente, primero dudá de la medición.
- **`(Semaphore new) critical:` no entra: espera.** Un semáforo nuevo no tiene señales, así que el
  bloque nunca corre y el pedido queda colgado (dos trabajadores míos quedaron así). El idioma es
  `Semaphore forMutualExclusion`, que nace con una. Casi le echo la culpa a `Transcript`, que no
  tenía nada que ver: `Transcript show:` desde un trabajador vuelve sin bloquear.
- **Lo que la imagen contesta sobre los procesos**: `isSuspended` (un proceso recién creado sí,
  después del `resume` no), `isTerminated`, y `terminate` corriendo los `ensure:` **antes** de
  volver. Eso último es lo que sostiene todo el diseño, y está medido: el archivo que escribe el
  `ensure:` ya estaba en disco cuando el `terminate` retornó.
- **Un proceso terminado antes de correr no ejecuta su `ensure:`**: el desenrollado arranca de la
  pila que tiene, y si el `ensure:` todavía no se envió, no hay nada que desenrollar. Consecuencia
  de diseño: `cancel:` saca la entrada del registro él mismo, en vez de dejar esa tarea al
  trabajador. Salió de razonar el caso, y quedó fijado por el test 07.
- **Una variable de instancia tapa al método del mismo nombre.** Quise que el registro naciera la
  primera vez que se lo pidiera (un lector perezoso `inFlight`), y no funcionó: dentro de
  `protocol`, `inFlight` se compila como **acceso a la variable**, no como envío de mensaje, así que
  el lector nunca corría y el protocolo recibía `nil`. El arreglo terminó donde correspondía: el
  protocolo **ignora** la cancelación cuando no hay registro que mirar, que es lo que la spec dice
  de una cancelación que no se puede atender. Y el servidor que estaba vivo en ese momento dejó de
  contestar `500` y contesta `202`, sin rearmarlo.
- **`pkill -f <patrón>` mató mi propia shell**, porque el patrón coincidía con mi línea de comando.
  Si hay que matar por patrón, se lo encierra: `[m]cp-correr`.
- Y la de siempre, otra vez: el test que corre la categoría que lo contiene, el número que envejece
  adentro de una aserción, el cuerpo del test que va a un archivo, y —esta vez de nuevo— el test que
  se **renombra** y no se borra: el 13 quedó duplicado y el viejo fallaba por afirmar lo que ya no
  era cierto.

## File out

Quedaron `src/MCPServer.pck.st` (10 clases de producción) y
`src/MCPServerTest.pck.st` (9 clases de test: una por clase bajo prueba, más la clase
de trabajo de los tests). El paquete declara su dependencia
como los de Cuis: `!requires: 'JSON' 1 0 nil!`, más su descripción. Dos detalles:
`writeStreamDo:` no pisa un archivo existente (hay que borrarlo antes de
regenerar), y `MCPServerTest` (la clase) tuvo que moverse a la categoría
`MCPServerTest` para que el file out la llevara al paquete de tests.

## Lo que falta

1. **Cancelación** (`notifications/cancelled`): **implementada** (ciclos 38 a 42). De este tema
   quedan las **sesiones MCP** (`Mcp-Session-Id`), que vuelven exacto el alcance del registro de
   pedidos en vuelo, y dos de los tres bordes del adaptador: el `405` en el GET y la validación de
   `Origin` (el `202` ya está).
2. **Guarda de versión (compare-and-set) en las herramientas que escriben**:
   **descartada a propósito** por alcance (13/09/2026, decisión de Sebastian). Las dos
   que escriben (`compile_method_in_class_classified` y `remove_method_in_class`) usan
   el mismo camino que las demás: sin token, sin conflicto y sin reintento. En un
   contexto real haría falta; acá complica la interfaz y no aporta a la demo.
3. **Proceso trabajador de prioridad baja**: **implementado** (ciclo 37).
4. **Sesiones MCP**: hoy el servidor es sin estado, no recuerda el `protocolVersion`
   negociado (alcanza para el Inspector; no para sesiones con estado).
5. **`annotations`** (hints) y la **lista dinámica de herramientas**: anotados para después.
6. **Instalación limpia**: verificado a medias — una imagen nueva carga el paquete desde
   `Packages/Features` con `Feature require: 'MCPServer'` (y se trae JSON solo). Falta
   probar el ciclo completo con el servidor arrancando desde el arranque de Cuis.
7. **Que la imagen arranque el servidor sola**, en vez de pegarlo a mano en un Workspace.8. **Herramientas del Browser que faltan**: listar y buscar clases, renombrar (método o
   clase, actualizando los remitentes), crear y borrar clases, buscar texto en el código.
