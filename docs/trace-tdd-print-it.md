# Traza TDD: la herramienta `print_it`

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

## File out

Quedaron `src/MCPServer.pck.st` (9 clases de producción) y
`src/MCPServerTest.pck.st` (7 clases de test). El paquete declara su dependencia
como los de Cuis: `!requires: 'JSON' 1 0 nil!`, más su descripción. Dos detalles:
`writeStreamDo:` no pisa un archivo existente (hay que borrarlo antes de
regenerar), y `MCPServerTest` (la clase) tuvo que moverse a la categoría
`MCPServerTest` para que el file out la llevara al paquete de tests.

## Lo que falta

1. **Cancelación** (`notifications/cancelled`): decidida, sin implementar.
2. **Decorador de versión** (compare-and-set) en las herramientas que escriben.
3. **Proceso trabajador de prioridad baja**: decidido, sin implementar.
4. **Sesiones MCP**: hoy el servidor es sin estado, no recuerda el `protocolVersion`
   negociado (alcanza para el Inspector; no para sesiones con estado).
5. **`annotations`** (hints) y la **lista dinámica de herramientas**: anotados para después.
6. **Instalación limpia**: cargar el `.pck.st` en una imagen limpia para verificar
   el ciclo completo de `Feature require: 'MCPServer'`.
