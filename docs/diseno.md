# Diseño del paquete `MCPServer`

Plan de estructura, jerarquías, abstracciones y responsabilidades. Escrito antes
de implementar, para decidir la forma y no descubrirla escribiendo.

## 1. Principios

1. **Composición sobre herencia.** La herencia se usa sólo donde hay polimorfismo
   genuino: mismo protocolo, distinto comportamiento, y más de un implementador
   real (hoy o en la fase siguiente). En todo lo demás, colaboradores inyectados.
2. **La interfaz es el protocolo, no la superclase.** En Smalltalk se programa
   contra un protocolo. Una clase abstracta con un solo implementador es
   ceremonia y un lugar donde esconder código compartido. Por eso el árbol es
   chato: no hay `MCPAbstractTool` ni `MCPBaseServer`. Hay protocolos, y están
   documentados en el comentario de cada clase.
3. **Una responsabilidad por clase** (SRP). El protocolo no sabe de herramientas;
   las herramientas no saben de HTTP; el transporte no sabe de Smalltalk.
4. **Dependencias hacia adentro.** La imagen no sabe que existimos; la capa de
   protocolo no conoce las herramientas; las herramientas usan la imagen.
5. **Inmutabilidad donde se pueda.** El catálogo de herramientas se construye una
   vez y no cambia. El estado compartido inmutable elimina la necesidad de locks:
   lo único mutable es la imagen, que es asunto del entorno (y el compare-and-set
   que decide el humano).
6. **Semántica Smalltalk.** Los nombres de las herramientas son selectores de la
   imagen (decisión 3) y la declaración vive junto al código, en un pragma.
7. **Reusar lo que la imagen ya trae** (decisión 10): `Pragma` y
   `AdditionalMethodState`, `MethodReference`, `ProcessBrowser class>>rulesFor:`,
   `ChangeSet`, `WebServer`, `Json`, `UISupervisor whenUIinSafeState:`.
8. **No se parchea Cuis.** Ninguna clase de la imagen se modifica. Todo lo nuestro
   vive en el paquete; las herramientas son métodos de nuestras fachadas.

## 2. Capas

```
   HTTP  (WebServer de Cuis)                    ← adaptador de entrada
     ↓
   Sesión MCP + framing JSON-RPC                ← protocolo; no conoce herramientas
     ↓
   Catálogo de herramientas (inmutable)         ← declarativo, construido del pragma
     ↓
   Invocación + guardas (decoradores)           ← comando + preocupaciones transversales
     ↓
   Fachadas por ventana (dominio)               ← los mensajes reales de Cuis
     ↓
   La imagen de Cuis                            ← el entorno
```

## 3. El árbol

A la derecha, la responsabilidad en una línea.

```
Object
│
├─ MCPServer ──────────────────── raíz de composición: arma catálogo, endpoint y sesiones;
│                                  es el objeto que el usuario crea y destruye
├─ MCPHttpEndpoint ────────────── adaptador: WebRequest de WebServer ↔ mensaje JSON-RPC
├─ MCPTransport (protocolo) ───── cómo se reciben y envían mensajes
│   └─ MCPHttpTransport ───────── implementación HTTP (futuro: stdio por puente)
├─ MCPDispatcher ──────────────── registro inmutable: nombre de método del protocolo → comando
├─ MCPProtocolCommand (protocolo)─ un método del protocolo MCP
│   ├─ MCPInitializeCommand ───── handshake: negocia versión y capacidades
│   ├─ MCPListToolsCommand ────── arma `tools/list` desde el catálogo
│   ├─ MCPCallToolCommand ─────── busca la herramienta, coacciona argumentos, ejecuta
│   ├─ MCPPingCommand ─────────── liveness
│   └─ MCPCancelCommand ───────── `notifications/cancelled`: corta el proceso del pedido
├─ MCPSession ─────────────────── estado por conexión: versión, initialized, clientInfo,
│                                  y el registro de pedidos en vuelo (id → Process)
├─ MCPToolCatalogue ───────────── inmutable: nombre → herramienta. Read-only ⇒ sin locks
├─ MCPCatalogueBuilder ────────── [Builder] lee pragmas de las fachadas y arma el catálogo
├─ MCPToolDescriptor ──────────── [Value Object] lo que el pragma declara: nombre, ventana,
│                                  argumentos, comentario, y el MethodReference
├─ MCPTool ────────────────────── [Command] el descriptor + saber ejecutarse
├─ MCPToolDecorator (protocolo) ─ [Decorator] misma interfaz que MCPTool, envuelve a otra
│   └─ MCPVersionGuardDecorator ─ compare-and-set: verifica el token antes de escribir
│                                  (a futuro: visibilidad, blancos privilegiados)
├─ MCPToolInvocation ──────────── [Value Object] herramienta + argumentos ya coercionados
├─ MCPArguments ───────────────── [Value Object] argumentos nombrados y validados
├─ MCPArgumentCoercion ────────── [Strategy] tabla: tipo declarado → cómo convertir el JSON
├─ MCPResult ──────────────────── [Value Object] contenido + isError
├─ MCPValueRenderer ───────────── [Strategy] objeto de Smalltalk → valor JSON-safe
├─ MCPRenderPolicy ────────────── [Value Object] límites: profundidad, cantidad, tamaño
├─ MCPErrorMapper ─────────────── [Strategy] excepción de Smalltalk → MCPResult con isError
├─ MCPVersionToken ────────────── [Value Object / Memento] el token que devuelve la lectura
├─ MCPVersioning ──────────────── calcula el token y verifica el conflicto
├─ MCPWindowProjection ────────── [Adapter] proyecta un resultado en la herramienta visual real
├─ MCPEnvironment ─────────────── acceso a la imagen (clases, categorías, fuentes, procesos);
│                                  colaborador inyectado ⇒ las fachadas se testean con un fake
│
└─ Fachadas (sin estado, sin herencia entre ellas, una por ventana)
    ├─ MCPBrowserTools ────────── System Browser
    ├─ MCPWorkspaceTools ──────── Workspace (`evaluate`)
    ├─ MCPInspectorTools ──────── Inspector
    ├─ MCPTestingTools ────────── Test Runner
    ├─ MCPProcessTools ────────── Process Browser
    └─ MCPDebuggerTools ───────── Debugger (fase 3)
```

Sólo tres jerarquías tienen más de un nivel, y las tres por polimorfismo real:
`MCPTransport` (HTTP hoy, stdio después), `MCPProtocolCommand` (cinco mensajes con
la misma interfaz) y `MCPToolDecorator` (envolver sin que el catálogo lo note).
Todo lo demás cuelga de `Object` y se relaciona por composición.

## 4. Patrones, y por qué cada uno está

| Patrón | Dónde | Por qué |
| --- | --- | --- |
| **Command** | `MCPTool`, `MCPProtocolCommand` | Pedido como objeto: uniforma la ejecución, permite registrar, decorar y cancelar |
| **Memento** | `MCPVersionToken` | La lectura entrega un recuerdo del estado; la escritura lo verifica antes de pisar |
| **Strategy** | `MCPValueRenderer`, `MCPArgumentCoercion`, `MCPErrorMapper`, `MCPTransport` | Familias de algoritmos intercambiables, sin cadenas de `caseOf:` y abiertas a extensión |
| **Decorator** | `MCPVersionGuardDecorator` | Preocupación transversal (compare-and-set) sin ensuciar las herramientas ni el catálogo |
| **Builder** | `MCPCatalogueBuilder` | Construcción paso a paso de un objeto complejo e inmutable |
| **Adapter** | `MCPHttpEndpoint`, `MCPWindowProjection` | Traducir entre dos interfaces que no deben conocerse |
| **Facade** | Las fachadas por ventana | Una interfaz por herramienta visual, delegando en la imagen |
| **Registry** | `MCPDispatcher`, `MCPToolCatalogue` | Búsqueda por nombre con sustitución de la implementación |
| **Value Object** | Descriptor, Arguments, Result, Token, RenderPolicy | Sin identidad, inmutables, comparables: el estado que no necesita cuidado |
| **Null Object** | Proyección "sin display" | Evita chequear `nil` en el camino normal |
| **Template Method** | *no se usa* | Sería herencia para reusar código: lo hacemos con composición |

Explícitamente no usamos Singleton para el servidor: el usuario crea el objeto con
sus parámetros y lo destruye. Un singleton global nos ataría a una imagen con un
solo servidor y a un estado que nadie controla.

## 5. Flujos

**Arranque.** `MCPServer on: 8765 tools: { MCPBrowserTools. MCPWorkspaceTools }`.
El constructor arma el `MCPCatalogueBuilder`, éste recorre las fachadas, lee los
pragmas y produce un `MCPToolCatalogue` inmutable. Después el servidor crea su
`MCPHttpEndpoint`, que levanta el `WebServer` de Cuis en 127.0.0.1 y registra el
servicio `/mcp`. Devuelve el servidor: el usuario lo apaga con `destroy`.

**Handshake.** `WebRequest` → `MCPHttpEndpoint` (extrae el cuerpo JSON) →
`MCPDispatcher` → `MCPInitializeCommand` → crea/actualiza la `MCPSession` con
versión y capacidades → respuesta.

**`tools/list`.** `MCPListToolsCommand` → catálogo → descriptores → renderer →
JSON. La lista sale de los pragmas: no hay dos lugares donde esté declarada una
herramienta.

**`tools/call`.** `MCPCallToolCommand` → busca en el catálogo (si no existe:
error de protocolo) → coercion de argumentos según el descriptor → el decorador de
versión verifica el token si la herramienta lo exige → `MCPTool` ejecuta el
`MethodReference` → `MCPResult` → renderer con política de límites.

**Cancelación.** `notifications/cancelled` → `MCPCancelCommand` → la sesión sabe
qué `Process` atiende ese id (registro de pedidos en vuelo) → `terminate`. Es el
reemplazo decidido del vigilante: el pedido lo corta quien lo pidió.

**Ver en pantalla.** Si el humano pide ver, `MCPWindowProjection` instancia la
herramienta real de Cuis (`MethodSet`, `Browser`, `Debugger`) y la abre. El estado
de ventana lo maneja Cuis.

## 6. La declaración de una herramienta (verificado en la imagen)

```smalltalk
browseAllCallsOn: aSymbol
	"Answer the senders of aSymbol, so the agent can see who calls what
	before changing anything."
	<mcpTool: #browse_all_calls_on system: 'System Browser' arguments: #('selector')>
	^ self environment allCallsOn: aSymbol
```

Lo verificado: el pragma se guarda y se recupera con `pragmaAt:` usando el
**selector completo** (`#mcpTool:system:arguments:`); sus argumentos deben ser
**literales**; `Pragma` conoce su `methodClass` y su `selector`, así que el
builder no necesita adivinar de dónde salió. El builder recorre los pragmas de
cada método (filtrando por prefijo `mcpTool`) y arma el descriptor con el
`MethodReference` correspondiente.

## 7. Lo que deliberadamente no hacemos

- **Singleton** del servidor ni de la sesión.
- **Superclase base** para compartir código entre herramientas.
- **Estado de ventana** en nuestras clases (decisión 9).
- **Parchear** clases de Cuis.
- **`caseOf:` largos**: se resuelven con tablas de estrategias.
- **Abstracciones por adelantado**: la clase abstracta aparece cuando aparece el
  segundo implementador.

## 8. Testeo (consecuencia del diseño)

Cada pieza se puede probar sin arrancar el servidor ni tocar la imagen:
`MCPServer` con un catálogo falso; `MCPTool` y las fachadas con un
`MCPEnvironment` falso; `MCPValueRenderer` con objetos comunes; el dispatcher con
comandos falsos; el endpoint con un `WebRequest` armado a mano. La cuenta y la
cancelación se prueban con procesos de mentira.

## 9. Estado y concurrencia

- **Inmutable**: catálogo, descriptores, valores. Sin locks.
- **Por conexión**: `MCPSession` (versión, initialized, pedidos en vuelo). Una
  sesión no ve a las otras.
- **Del entorno**: la imagen. Ahí no hay transacciones: el compare-and-set de la
  capa de invocación avisa en vez de bloquear.
- **Un proceso por pedido**: lo aporta el `WebServer`. Sobre eso, la ejecución de
  cada herramienta corre en un **proceso trabajador propio con prioridad menor que
  la UI** (decidido): el handler espera su resultado. Así el humano nunca pierde el
  CPU frente al agente, y la cancelación tiene un destinatario claro (se termina el
  trabajador y se registra en la sesión para `notifications/cancelled`).
