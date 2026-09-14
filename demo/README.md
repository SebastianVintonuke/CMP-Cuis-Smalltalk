# Probar a mano (panel)

`demo/panel-mcp.py` es un panel chico para usar el servidor MCP a mano: lista las
herramientas que contesta `tools/list`, arma un formulario por herramienta con los
campos de su `inputSchema` y las corre con un botón. La lista es dinámica: no hay
nombres de herramientas en el panel.

Es un cliente del producto y nada más: asume que el servidor MCP ya está corriendo
dentro de la imagen. Lo único que hay que decirle es en qué puerto escucha.

Cada llamada lleva **el identificador del pedido**, que lo elige la página (`panel-1`,
`panel-2`, ...) y que se muestra mientras corre. Al lado del botón **Run** está el **Cancel**,
que manda `notifications/cancelled` con ese id: es el cliente el que cancela el pedido que él
mismo emitió, que es lo que pide el protocolo. El pedido cancelado **no contesta** —la spec dice
que no debe hacerlo— así que el panel avisa que se canceló, en vez de mostrar una respuesta que
no va a llegar. Como el panel atiende en paralelo (un hilo por pedido), puede mandar la
cancelación mientras la llamada sigue colgada.

```bash
python3 demo/panel-mcp.py --port 8790 --panel 8899
```

| Parámetro | Qué es | Por defecto |
| --- | --- | --- |
| `--port` | puerto del servidor MCP (el producto) | `8790` |
| `--panel` | puerto donde este panel sirve la página | `8899` |

Queda en `http://127.0.0.1:8899`. En pantalla: **Reload tools**, un tilde para ver el
JSON crudo, y una tarjeta por herramienta con sus campos, el botón **Run** y el **Cancel**
de la llamada que esté corriendo. La interfaz está en inglés (los comentarios del código y la
documentación, en español).

Los pedidos al MCP los hace el panel (Python), no el navegador: no hay problema de
CORS ni de transporte.

## La llamada de prueba

`demo/cancel-demo.st` es el código para pegar en el campo `code` de `print_it`: da veinte vueltas
tomando la máquina un segundo y soltándola dos, y va escribiendo cada vuelta en el Transcript.

Sirve para ver las dos cosas de una. Mientras corre, la imagen se siente trabada —la llamada se
pone **por encima de la UI a propósito**, con una línea que se puede sacar, y así hay algo que
cancelar—. Y con **Cancel** vuelve todo a la normalidad: el Transcript deja de crecer en el acto,
porque el trabajador murió.

Para que una cancelación **entre**, el trabajador tiene que soltar el CPU en algún momento: por eso
la llamada duerme entre vuelta y vuelta. Una que no duerme nunca no se puede cancelar ni matando el
proceso desde afuera, y eso está contado como "lo que no se puede salvar" en el Problema 1 del
README.

## Cómo se levanta el servidor

El panel no levanta ni apaga nada: el servidor es parte de la imagen y se arranca desde
adentro, como cualquier otra cosa de Smalltalk (un doit en un Workspace).

Lo primero es cargar el paquete, que declara lo que necesita (JSON y WebClient):

```smalltalk
Feature require: 'JSON'.
Feature require: 'WebClient'.
Feature require: 'MCPServer'.
Feature require: 'MCPServerTest'.
```

Y después se levanta el servidor:

```smalltalk
| server |
server := MCPServer on: 8790 tools: { MCPServerWorkspaceTools. MCPServerBrowserTools. MCPServerTestingTools }.
server start.
Smalltalk at: #MCPDemo put: server
```

Para rearmarlo —por ejemplo si el puerto quedó tomado por un socket viejo que escucha y no
contesta— `start` lo dice y no arranca: **soltar el puerto es cosa tuya, desde la imagen**,
mirando qué `WebServer` está escuchando ahí. El servidor no toma puertos de nadie, ni
siquiera suyos. Desde un Workspace:

```smalltalk
WebServer allInstances do: [ :each |
	(each listenerProcess isNil not and: [ each listenerPort = 8790 ]) ifTrue: [ each destroy ] ]
```

Y se apaga con `(Smalltalk at: #MCPDemo) destroy`.

Dos avisos sobre guardar la imagen. Primero: el servidor **no sobrevive al guardado**
(el socket no se guarda), así que hay que arrancarlo de nuevo. Segundo: el global queda
apuntando a un servidor muerto que igual contesta `port` y `catalogue` como si viviera,
así que no sirve para saber si hay algo escuchando. Está contado como Problema 7 del
README.
