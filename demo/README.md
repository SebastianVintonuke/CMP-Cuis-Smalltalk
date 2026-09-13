# Probar a mano (panel)

`demo/panel-mcp.py` es un panel chico para usar el servidor MCP a mano: lista las
herramientas que contesta `tools/list`, arma un formulario por herramienta con los
campos de su `inputSchema` y las corre con un botón. La lista es dinámica: no hay
nombres de herramientas en el panel.

Es un cliente del producto y nada más: asume que el servidor MCP ya está corriendo
dentro de la imagen. Lo único que hay que decirle es en qué puerto escucha.

```bash
python3 demo/panel-mcp.py --port 8790 --panel 8899
```

| Parámetro | Qué es | Por defecto |
| --- | --- | --- |
| `--port` | puerto del servidor MCP (el producto) | `8790` |
| `--panel` | puerto donde este panel sirve la página | `8899` |

Queda en `http://127.0.0.1:8899`. En pantalla: **Reload tools**, un tilde para ver el
JSON crudo, y una tarjeta por herramienta con sus campos y el botón **Run**. La
interfaz está en inglés (los comentarios del código y la documentación, en español).

Los pedidos al MCP los hace el panel (Python), no el navegador: no hay problema de
CORS ni de transporte.

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

Ojo: si ya había uno escuchando en ese puerto, `start` avisa (`Failed to listen`) y no
levanta nada; para rearmarlo hay que destruir el anterior y esperar un momento antes de
crear el nuevo.

Y se apaga con `(Smalltalk at: #MCPDemo) destroy`.

Dos avisos sobre guardar la imagen. Primero: el servidor **no sobrevive al guardado**
(el socket no se guarda), así que hay que arrancarlo de nuevo. Segundo: el global queda
apuntando a un servidor muerto que igual contesta `port` y `catalogue` como si viviera,
así que no sirve para saber si hay algo escuchando. Está contado como Problema 7 del
README.
