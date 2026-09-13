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

## La firma de los cambios del agente (ciclo 28)

Un servidor MCP no puede contestar diálogos, y el primer diálogo de toda imagen nueva es
el autor: la primera vez que alguien cambia código, Cuis lo pide (`Utilities>>setAuthor`,
que se queda esperando para siempre). Documentarlo no alcanza: nos mordió dos veces el
mismo día.

Ahora, al arrancar, el servidor firma los cambios del agente. `start` llama a
`MCPServerEnvironment useAgentSignature`, que compone la firma con el autor que ya tenga
la imagen, para poder distinguir lo que escribió el agente de lo que escribió su dueño:

```
!MCPServerBrowserToolsScratch methodsFor: 'test' stamp: 'MCP(S.V.) 13/Sep/2026 20:01:17'!
!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:41:59'!
```

| # | Test | Rojo | Verde | Qué se implementó |
| --- | --- | --- | --- | --- |
| 28 | la firma del agente: conserva las iniciales del dueño, sin autor es sólo el agente y no se compone sobre sí misma; y arrancar el servidor firma | `MCPServerEnvironment class>>authorSignature`, y después el test del arranque | 43/43 | `agentInitials`, `agentName`, `authorSignature` y `useAgentSignature` en el entorno; `MCPServer>>start` la usa |

Dos detalles que vinieron del entorno:

- **`Utilities authorInitials` pregunta si no hay autor** (y ese es justo el diálogo que
  cuelga el pedido). El que lee sin preguntar es **`authorInitialsPerSe`**, que contesta
  el valor crudo, vacío o nil. Con eso, componer la firma no puede colgarse.
- **La composición se fija si la firma ya es del agente** antes de armarla, así que nunca
  queda `MCP(MCP(S.V.))`. Efecto lateral útil: si el dueño cambia su autor después, la
  próxima escritura del agente se compone con el nuevo.

## File out

Quedaron `src/MCPServer.pck.st` (10 clases de producción) y
`src/MCPServerTest.pck.st` (9 clases de test: una por clase bajo prueba, más la clase
de trabajo de los tests). El paquete declara su dependencia
como los de Cuis: `!requires: 'JSON' 1 0 nil!`, más su descripción. Dos detalles:
`writeStreamDo:` no pisa un archivo existente (hay que borrarlo antes de
regenerar), y `MCPServerTest` (la clase) tuvo que moverse a la categoría
`MCPServerTest` para que el file out la llevara al paquete de tests.

## Lo que falta

1. **Cancelación** (`notifications/cancelled`): decidida, sin implementar.
2. **Guarda de versión (compare-and-set) en las herramientas que escriben**:
   **descartada a propósito** por alcance (13/09/2026, decisión de Sebastian). Las dos
   que escriben (`compile_method_in_class_classified` y `remove_method_in_class`) usan
   el mismo camino que las demás: sin token, sin conflicto y sin reintento. En un
   contexto real haría falta; acá complica la interfaz y no aporta a la demo.
3. **Proceso trabajador de prioridad baja**: decidido, sin implementar.
4. **Sesiones MCP**: hoy el servidor es sin estado, no recuerda el `protocolVersion`
   negociado (alcanza para el Inspector; no para sesiones con estado).
5. **`annotations`** (hints) y la **lista dinámica de herramientas**: anotados para después.
6. **Instalación limpia**: verificado a medias — una imagen nueva carga el paquete desde
   `Packages/Features` con `Feature require: 'MCPServer'` (y se trae JSON solo). Falta
   probar el ciclo completo con el servidor arrancando desde el arranque de Cuis.
7. **Que la imagen arranque el servidor sola**, en vez de pegarlo a mano en un Workspace.8. **Herramientas del Browser que faltan**: listar y buscar clases, renombrar (método o
   clase, actualizando los remitentes), crear y borrar clases, buscar texto en el código.
