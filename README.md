# CMP-Cuis-Smalltalk

Servidor MCP para Cuis Smalltalk. El paquete se va a llamar `MCPServer`.

## La idea

Llevar la IA **dentro** del entorno Smalltalk, no usar Smalltalk como un
intérprete al que se le piden cosas.

El usuario abre **su** imagen: la de siempre, con su UI, su estado, su trabajo
sin guardar. Carga el paquete `MCPServer`, crea un objeto con parámetros, y un
agente se conecta y trabaja **dentro de esa imagen**: navega clases, lee código,
compila métodos, corre tests. El humano ve todo en vivo — las ventanas, los
cambios, los tests — y puede seguir trabajando en paralelo, corregir o deshacer.

La diferencia con "una IA que usa Smalltalk como intérprete" es de fondo: acá la
imagen es el lugar de trabajo compartido entre el humano y el agente, no una
caja negra que devuelve resultados. El foco es el entorno.

**Decisión filosófica: el agente está expuesto a los mismos riesgos que el
programador.** No se lo trata como algo distinto ni se lo protege de lo que el
humano tampoco está protegido. Si el agente puede escribir un bucle que congele
la imagen, el humano puede escribir el mismo bucle en un Workspace. Si el
agente puede romper una clase del núcleo, el humano también. Lo que el diseño
tiene que garantizar no es la imposibilidad de romper sino la
**visibilidad** (que se vea qué hizo), la **atribución** (saber que fue el
agente) y la **reversibilidad** (poder deshacerlo), que es exactamente la
relación que un programador tiene con su imagen.

## Cómo se usa (objetivo)

1. Abrís tu imagen de Cuis.
2. Cargás el paquete `MCPServer`.
3. Creás el servidor con sus parámetros (puerto, qué herramientas expone, qué
   permisos tiene).
4. El agente se conecta y trabaja en tu imagen; vos ves todo en vivo.

El transporte decidido es HTTP: el servidor vive dentro de la imagen y expone un
endpoint (MCP sobre HTTP). No hace falta ningún proceso puente ni una imagen
headless aparte.

## Estado

- **El paquete existe**: `src/MCPServer.pck.st` (12 clases de producción) y
  `src/MCPServerTest.pck.st` (9 clases de test, más la clase de trabajo de los tests),
  con **trece herramientas** en tres fachadas:
  - *Workspace*: `print_it`.
  - *Browser*: `selectors_of_class`, `source_of_method_in_class`, `comment_of_class`,
    `all_calls_on`, `all_implementors_of`, `hierarchy_of_class`,
    `compile_method_in_class_classified`, `remove_method_in_class`,
    `classify_method_in_class_under` y `file_out_package_to`.
  - *Test Runner*: `run_tests_in_class` y `run_tests_in_category`.

  Cada herramienta se declara con un pragma, su descripción es el comentario del método
  que la implementa, y en su `_meta` dice de qué ventana de la imagen viene.
- **Flujo MCP funcionando**: `initialize`, `tools/list` y `tools/call` sobre HTTP en
  `/mcp`, verificado contra la imagen viva. Para levantarlo: `MCPServer on: 8790 tools:
  { MCPServerWorkspaceTools. MCPServerBrowserTools. MCPServerTestingTools }` y `start`;
  se apaga con `destroy`, que libera el puerto.
- **Dependencias declaradas**: `MCPServer` pide `WebClient` y `JSON`, y el paquete de
  tests pide `MCPServer`, así que `Feature require: 'MCPServer'` trae todo.
- **El autor de los cambios es de quien autoriza**: el paquete no firma distinto ni
  inventa un autor. Lo que el agente escribe queda a nombre del dueño de la imagen, que es
  de quien es la responsabilidad, y **al arrancar el servidor exige que haya un autor**: si
  falta, no arranca y lo dice. La actividad del agente es información, no firma: va al log
  del servidor.
- **El ciclo de trabajo se hace por MCP**: leer, escribir, correr los tests y exportar,
  todo a través del servidor. No hace falta ningún endpoint aparte en la imagen.
- La traza del trabajo TDD (los 21 ciclos, los rojos y verdes, lo que encontró el
  e2e) está en `docs/traza-tdd.md`.
- Para probarlo a mano hay un panel chico en `demo/` (lista las herramientas y las
  corre con un formulario, estilo Swagger): `python3 demo/panel-mcp.py`. Detalles en
  `demo/README.md`.
- El spike y las notas de trabajo viven en `~/OpenClawWorkshop/cmp-cuis-notas/`
  (fuera de este repo).
- Para mirar los resultados a mano usamos el **MCP Inspector** oficial: se conecta
  al servidor, lista las herramientas y permite invocarlas desde una UI web.

## Decisiones de diseño

1. **La interfaz tiene que ser la analogía más perfecta posible a las
   herramientas visuales que el sistema ya ofrece.** Cada herramienta que
   expongamos tiene que existir de verdad en una ventana de Cuis: System Browser,
   Debugger, Inspector, Workspace, Test Runner, Process Browser,
   Changes/Versions, Transcript, File List, Profiler. No inventamos operaciones
   que un programador no tenga a mano: traducimos, sin ventanas, lo que esas
   ventanas ofrecen.
2. **Todo en inglés**: nombres, descripciones y documentación.
3. **El nombre de cada herramienta es la forma snake_case del selector
   Smalltalk que ejecuta la operación.** Regla mecánica: camelCase pasa a
   snake_case y cada `:` se convierte en `_`. Ejemplos verificados en la imagen:
   `spyOn:` → `spy_on`, `browseAllCallsOn:` → `browse_all_calls_on`,
   `removeSelector:` → `remove_selector`, `createInstVarAccessors` →
   `create_inst_var_accessors`, `toggleBreakOnEntry` → `toggle_break_on_entry`,
   `terminateProcess` → `terminate_process`. El nombre no puede llevar `:`
   porque los clientes validan el identificador de la herramienta.
4. **`_meta.system` dice en qué ventana vive la herramienta**, incluido
   Workspace para `evaluate`. Si la misma operación está en más de una ventana,
   se listan todas.
5. **`evaluate` es el Workspace.** Se expone, pero la interfaz expresa que lo
   esperable es pasar por las herramientas específicas; `evaluate` es la
   particularidad, no la puerta principal.
6. **Futuro, no ahora:** `annotations` (`readOnlyHint`, `destructiveHint`,
   `idempotentHint`, `openWorldHint`) y la lista dinámica de herramientas
   (`notifications/tools/list_changed`) para expresar permisos. Se anota para
   definir más adelante.
7. **La herramienta se ancla en la capa lógica, no en el mensaje de la ventana.**
   El nombre y la semántica salen del mensaje que *hace* el trabajo sobre el
   modelo, no del menú que lo dispara. Ejemplos verificados: borrar un método es
   `removeSelector:` (comportamiento de la clase), no `removeMessage` del Browser;
   compilar es `compile:classified:`; los senders son `allCallsOn:` (los datos),
   no `browseAllCallsOn:` (que abre la ventana). La ventana queda como
   procedencia (`_meta.system`) y el pragma anota también el mensaje lógico, así
   la cadena completa queda registrada: herramienta → mensaje lógico → modelo →
   ventana.
   **Excepción razonada:** en el Debugger el vocabulario del programador es el del
   propio Debugger (`step`, `stepIntoBlock`, `send`, `restart`, `proceed`), así que
   ahí se usa ese vocabulario y el pragma anota los mensajes de proceso que
   ejecuta (`completeStep:`, `stepToSendOrReturn`, `restartTop`, `popTo:`).

   La separación modelo/vista en Cuis, verificada en la imagen:

   | Modelo | Categoría | Superclase | Ventana |
   | --- | --- | --- | --- |
   | `Browser` | `Tools-Browser` | `CodeProvider` | `BrowserWindow` < `CodeWindow` |
   | `MethodSet`, `MethodReference` | `Tools-Browser` | `CodeProvider` / `Object` | `MethodSetWindow` |
   | `Debugger` | `Tools-Debugger` | `CodeProvider` | `DebuggerWindow` < `CodeWindow` |
   | `Inspector` | `Tools-Inspector` | `TextProvider` | `InspectorWindow` |
   | `TestRunner` | `Tools-Testing` | `ActiveModel` | `TestRunnerWindow` |
   | `ProcessBrowser` | `Tools-Profiling` | `ActiveModel` | `ProcessBrowserWindow` |
   | `Workspace` | `System-Text` | `TextModel` | `WorkspaceWindow` |

   Todas las ventanas viven en `Morphic-Tool Windows`. Y el detalle fino:
   `CodeProvider` (en `System-Text`) es el protocolo que las ventanas de código
   consumen, y tanto `Browser` como `Debugger` son `CodeProvider` — por eso
   comparten ventana (`CodeWindow`).

   **Agrupación:** usamos como grupo la categoría `Tools-*` del modelo
   (`Tools-Browser`, `Tools-Debugger`, `Tools-Inspector`, `Tools-Testing`,
   `Tools-Profiling`). Es la taxonomía que la imagen ya tiene, no una inventada.
   Los casos raros se respetan: `Workspace` está en `System-Text`.
8. **La documentación humana se genera desde el mismo pragma.** Un catálogo en
   markdown dentro del repo, y un documento **OpenAPI 3.1** que se puede leer con
   Swagger UI o Redoc: los schemas de MCP ya son JSON Schema, así que la
   conversión es directa (el precedente `open-webui/mcpo` hace exactamente ese
   mapeo). Para probar el servidor a mano, el **MCP Inspector** oficial de
   Anthropic. Una sola fuente de verdad, tres vistas: MCP para el agente,
   markdown y OpenAPI para el humano.
9. **La interfaz se para en la capa del dominio y no maneja estado de ventana.**
   Los modelos `Tools-*` mezclan los comandos con el estado de la interacción: en
   Cuis `Browser>>removeMessage` no recibe argumentos, porque saca la clase y el
   selector de su propia selección (`selectedClass`, `selectedMessageName`). Eso
   es lo que una interfaz visual necesita y lo que una API no: nuestras
   herramientas reciben siempre sus argumentos explícitos y no mantienen
   selección, panel activo, índice de lista ni posición del cursor.
   Lo que sí hay es el estado del entorno (la imagen es un mundo mutable: una
   llamada afecta a la siguiente) y **una sola sesión con estado propio, la de
   depuración**, porque un proceso detenido y su pila tienen que sobrevivir entre
   llamadas. Se modela con handles explícitos, como hace el protocolo DAP
   (sesión, `threadId`, `frameId`, `variablesReference`), no con estado implícito.
   El estado de ventana de `Tools-*` no se copia: se delega en Cuis,
   instanciando sus propias herramientas cuando el humano pide ver algo
   (`display`).

10. **Reusamos las reglas del entorno en vez de inventar las nuestras.** Para
    los procesos, Cuis ya tiene la lista de cuáles no se tocan:
    `ProcessBrowser class>>rulesFor: aProcess` responde `{se puede suspender, se
    puede depurar}` y protege el proceso activo (la UI), el low-space watcher,
    el proceso de finalización, el `backgroundProcess`, los vigilantes de
    entrada y el timer de `Delay`. Las herramientas de procesos del agente
    respetan esa misma regla. Igual que con los change sets para la auditoría:
    antes de inventar mecanismo, miramos qué trae la imagen.

## Fases

1. **Núcleo**: explorar, leer, editar, correr tests, `evaluate` y Transcript. Con
   esto el agente trabaja como un programador.
2. **Inspector y procesos.**
3. **Debugger.** Está decidido y nos interesa, pero no por ahora: es lo más
   delicado (maneja procesos y el estado de la pila) y su forma sigue a DAP, una
   sesión con handles explícitos (proceso, frame, variables) en vez de estado
   implícito.
4. **Auditoría y reversión**, junto con la política de escrituras.

## Problemas

Acá se anotan los problemas que vamos encontrando, con la evidencia que los
respalda. Los que ya tienen decisión la llevan anotada, pero **ninguna está
implementada todavía**.

### 1. Concurrencia: el trabajo del agente puede tomar la imagen entera

**Qué medimos** (servidor dentro de una imagen Cuis 7.8):

| Caso | Resultado |
| --- | --- |
| Evaluación que **espera** (un `Delay` de 5 s) + otro pedido en paralelo | El otro respondió en 19 ms |
| Evaluación que **calcula** (un bucle, 6 s) + otro pedido en paralelo | El otro tardó 5,01 s: esperó a que terminara la primera |
| Prioridades medidas dentro de la imagen | handler del pedido: 60 · listener: 60 · UI: 50 · highIO: 70 · timing: 80 |
| Un bucle ocupado de 6 segundos | 387.532.240 iteraciones (≈64 millones por segundo) |

**Por qué pasa.** Cuis es un solo VM sobre un solo hilo del sistema operativo.
Los procesos se turnan únicamente cuando *esperan* algo; uno que calcula no cede
nunca, y no puede ser interrumpido por otro de prioridad igual o menor. Como
todos los handlers de pedidos corren en prioridad 60 y la UI en 50, un pedido
con cálculo pesado bloquea todo: los demás pedidos y la interfaz del humano. No
es un servidor "mal hecho": es que no hay paralelismo real.

**Decidido (sin implementar):**

1. Correr el trabajo del agente **por debajo de la UI**. La UI corre en
   `Processor userInterruptPriority` (50) y el handler del `WebServer` en 60, así
   que la ejecución de una herramienta se hace en un **proceso trabajador** propio,
   con prioridad menor (por ejemplo 40), y el handler espera su resultado. Doble
   ventaja: la interfaz del humano siempre gana el CPU, y la cancelación tiene a
   quién cortar (se termina el trabajador, no el handler).

**Descartado:** el **vigilante con timeout** como policía del servidor. Se
descartó a propósito: el humano puede congelar la imagen igual que el agente, así
que no se le pone al agente una regla que al humano no se le pone (ver la decisión
filosófica en "La idea").

**Decidido en su lugar (sin implementar): cancelación.** El servidor implementa
`notifications/cancelled`: al recibir la cancelación de un pedido en curso,
interrumpe el proceso que lo está ejecutando, libera lo que corresponda y **no
responde** ese pedido. El timeout queda del lado del cliente que pide, que es
donde la spec de MCP lo pone. Falta definir el plazo del lado del cliente y cómo
se interrumpe un proceso en Cuis.

**Lo que no se puede salvar.** Si la evaluación bloquea el VM entero (por
ejemplo una lectura de stdin bloqueante, que ya medimos), ni el vigilante la
desengancha. La única salida es matar el VM desde afuera, y se pierde el estado
no guardado (el código evaluado sí queda en el archivo de cambios).

### 2. Codificación de caracteres (encontrado, sin decidir)

El cuerpo de los pedidos se lee como bytes, sin decodificar UTF-8: un "í" llegó
como "Ã" a la ventana de la imagen. En MCP esto no es opcional, porque JSON es
UTF-8 por definición. Cuis trae las piezas para resolverlo
(`Utf8EncodedWriteStream`, `asUtf8Bytes`, UnicodeData).

### 3. Condiciones de carrera entre el humano y el agente (una decidida, otra pendiente)

El humano edita en el Browser mientras el agente compila por HTTP. Verificado en
la imagen: **Cuis no protege de esto**. `CodeProvider>>okayToAccept`, el último
control antes de aceptar un método, sólo chequea que no estés viendo bytecodes o
diffs: **no compara si el método cambió abajo**. Si el agente compila `Foo>>bar`
mientras el humano lo tiene en el panel de edición, y el humano acepta después, la
versión del humano gana en silencio y el cambio del agente se pierde. Y al revés:
el panel del humano queda con texto viejo sin que nadie avise.

Son conflictos distintos y no se resuelven igual:

- **Mismo método**: humano con el texto abierto y agente compilando → concurrencia
  optimista.
- **Estructura**: borrar o renombrar una clase que el humano tiene abierta, o
  recompilar una clase mientras hay un frame apuntando a ella → regla de
  procesos (decisión 10).
- **Recursos del sistema** (compilador, `SystemOrganizer`, `ChangeSet`,
  `Preferences`): no hay merge posible → política de blancos.

Opciones y estado de cada una:

- **Concurrencia optimista (compare-and-set)**: leer devuelve un token de versión;
  escribir lo exige de vuelta; si no coincide, error de conflicto con la fuente
  actual, para que el agente relea y reintente. **Descartada deliberadamente
  (13/09/2026)**: en un contexto real hace falta, pero complica la interfaz del agente
  (token de ida y vuelta, conflicto, reintento) y el alcance del proyecto es una demo
  creativa, no un producto en producción. Queda anotada como problema conocido e
  ignorado a propósito, no por descuido.
- **Visibilidad, atribución y revert** (el change set del agente, anuncios en el
  Transcript, marca en el `stamp`): **fuera de alcance** por la misma razón. El revert a
  mano ya existe igual: la imagen trae `ChangeSet` y `VersionsBrowser`.
- **Serializar las escrituras del agente** con un mutex, para que dos clientes MCP
  no se entrelacen: **fuera de alcance** (en la demo hay un solo cliente).
- **Checkpoints** con `saveAs:` a un archivo aparte: **fuera de alcance** (es caro y la
  demo no lo necesita).
- **Descartado**: bloquear al humano o parchear su camino de edición, que sería
  ponerle al humano una regla que al agente no.

Lo de los procesos no va acá: es de las herramientas de procesos y del debugger
(ver la decisión 10 y la fase 3).

### 4. Acciones de UI desde el proceso del pedido (sin decidir)

Abrir ventanas desde el handler funciona, pero el handler corre en prioridad 60,
no en el proceso de la UI. El patrón correcto en Cuis es marshallar esas
acciones al proceso de la UI (`UISupervisor whenUIinSafeState:`). Hoy funciona;
es el tipo de cosa que rompe de forma sutil.

### 5. Anomalía sin explicar: un proceso de fondo dejó de correr al principal

En pruebas propias, un `fork` de un bucle `whileTrue` con un `Delay` adentro
dejaba al proceso principal sin ejecutarse nunca más, aunque los dos tenían la
misma prioridad (40). No está explicado. Es el mismo mecanismo en el que se
apoya el servidor, así que conviene entenderlo antes de construir encima.

### 6. Crecimiento (sin decidir)

Cada pedido crea un proceso, y cada cambio que hace el agente engorda los change
sets de la imagen. Falta decidir si el paquete ofrece "descartar los cambios del
agente" y qué pasa con el guardado.

### 7. El manejador del servidor queda viejo al guardar y reabrir la imagen

Un servidor MCP no sobrevive a un guardado: la imagen se acuerda del *objeto* (lo que
haya en un global, como `Smalltalk at: #MCPDemo put: server`), pero no del socket ni
del proceso que escucha. Después de reabrir, ese global apunta a un servidor **muerto
que igual parece vivo**: contesta su `port`, su `catalogue` y hasta su lista de
herramientas, porque son datos del objeto, no del socket.

Nos pasó el 13/09 y costó un rato entenderlo: el servidor de demo parecía contestar
cosas viejas porque el global apuntaba a un objeto que no era el que estaba escuchando
(encima, el bug de las variables compartidas lo disimulaba).

Opciones (sin decidir):

- **Limpiar los globals al arrancar**: al iniciar la imagen, buscar los globals que
  sean servidores y ponerlos en nil. Barato y evita la confusión, pero hay que
  engancharse al arranque de Cuis.
- **No usar un global**: dejar el servidor en una variable del Workspace, o dentro de un
  objeto que se cree de nuevo al arrancar. Menos magia, menos alcance.
- **Que el servidor sepa que está muerto**: que `start` sea idempotente y que preguntarle
  el estado a un servidor guardado diga que ya no escucha (hoy no hay forma de
  distinguirlo mirando el objeto).

## Precedentes

Quién ya enfrentó lo mismo: exponer un entorno vivo a un agente, con
modificación en caliente y concurrencia.

| Proyecto | Qué es | Qué nos enseña |
| --- | --- | --- |
| `KentBeck/SmalltalkGenie` (Pharo) | 26 herramientas sobre una imagen viva, por loopback | Sus nombres de herramienta son los del **System Browser**: `list_classes`, `list_methods`, `get_class_source`, `get_method_source`, `search_classes_like`, `search_implementors`, `search_references`, más `eval`, `define_class`, `define_method`, `run_test`. Y concluyen explícitamente que **las herramientas no son un sandbox**: "the 'go only through the tools' rule is guidance to a cooperating agent, not a sandbox. So the real job is containing *who can reach the server*" (loopback, chequeo de `Origin`, token opcional, gating de herramientas peligrosas). Detalle: es *headless*, sin Morphic — justo la dimensión que nosotros queremos conservar. |
| `CorporateSmalltalkConsultingLtd/ClaudeSmalltalk` (Squeak) | 14 herramientas por TCP | Otra superficie tipo Browser: evaluar, navegar jerarquías, leer y escribir métodos, y **guardar la imagen**. |
| `mumez/smalltalk-interop-mcp-server` (Pharo/Squeak) | Servidor MCP afuera + un servidor dentro de la imagen (SIS) | El puente por socket hacia la imagen, con parámetros como la profundidad del stack trace de los errores. |
| `quasi/cl-mcp-server` (Common Lisp, 37 herramientas) | REPL persistente | `evaluate-lisp`, **`compile-form`** (compilar sin ejecutar), `validate-syntax`, `describe-symbol`, `apropos-search`, `who-calls`, y **`configure-limits`** (timeout de evaluación y límite de salida configurables). |
| `ctford/mcp-nrepl` y `JohanCodinha/nrepl-mcp-server` (Clojure) | Acceso a un nREPL vivo | Misma postura que la nuestra: "grants full REPL access… the same level of access you have when typing at a REPL prompt". Y un dato de diseño: "the nREPL session shares state — one evaluation affects subsequent ones". |
| `bettyguo/mcp-jupyter` | Kernel de Jupyter vivo | Devuelve **resúmenes** por defecto (`df.head(5)`), no datos crudos, con herramientas de opt-in; y un modo que levanta el kernel sin Jupyter (la variante aislada). |
| `ChromeDevTools/chrome-devtools-mcp` (51k★, oficial de Chrome) | Navegador vivo | El precedente más grande de entorno vivo expuesto a un agente: inspeccionar, depurar y **modificar cualquier dato** del navegador. Tiene flags de aislamiento (`--isolated`, `--headless`). |

Además, dos cláusulas de la spec de MCP (2025-06-18) que nos ordenan el diseño:

- **Cancelación** (`notifications/cancelled`, con el id del pedido): el receptor
  *debería* dejar de procesar, liberar recursos y **no responder**. Cualquiera de
  los dos lados puede cancelar. El servidor *puede* ignorarla si el pedido no se
  puede cancelar.
- **Timeouts**: los establece **quien manda el pedido**, y ante un timeout
  *debería* emitir una cancelación. Es decir: el timeout es responsabilidad del
  cliente, no un policía del servidor. Encaja con haber descartado el vigilante
  propio.

Fuera del mundo MCP, dos prácticas conocidas que apuntan a lo mismo (conocimiento
general, no verificado en esta sesión): Erlang/OTP permite que dos versiones de un
módulo convivan y hace el cambio de código **explícito y coordinado**, con la
migración de estado como la parte difícil; y en Clojure recargar código requiere
seguir el grafo de dependencias (tools.namespace), porque el enemigo es el estado
viejo que queda vivo. Lección para nosotros: separar el cambio de código del
cambio de estado, y que el cambio sea explícito.

## Decisiones pendientes

- **Superficie de herramientas**: ¿`evaluate` solo (con él se puede todo, igual
  que un programador), o un conjunto al estilo del System Browser —listar
  clases, listar métodos, leer código, buscar implementadores y referencias,
  compilar un método, correr tests— *además* de `evaluate`? Los precedentes de
  Smalltalk van por la segunda opción, con `eval` siempre presente.
- **Política para las escrituras**: libres, con confirmación desde la imagen, o
  permitidas solo en clases marcadas como seguras. (El compare-and-set que las
  protegía quedó descartado por alcance: ver Problemas 3.)
- **Superficie de herramientas**: en elaboración (ver el inventario de
  herramientas del programador). `evaluate` queda expuesto, pero la interfaz
  expresa que lo esperable es interactuar a través de las herramientas
  específicas, y que `evaluate` es una particularidad.
