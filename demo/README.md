# Probar a mano (panel)

`demo/panel-mcp.py` es un panel chico para usar el servidor MCP sin cliente: lista
las herramientas que contesta `tools/list`, arma un formulario por herramienta con los
campos de su `inputSchema` y las corre con un botón. La lista es dinámica: no hay
nombres de herramientas en el panel.

Los pedidos al MCP los hace el panel (Python), no el navegador: no hay problema de
CORS ni de SSE. Y si el servidor MCP no contesta, el panel se lo pide a la imagen por
el endpoint `/evaluate` (eso es lo que usan los botones **Start server** / **Stop
server**), que es para lo que recibe los identificadores de las fachadas.

```bash
python3 demo/panel-mcp.py \
	--tools MCPServerWorkspaceTools MCPServerBrowserTools \
	--port 8790 --cuis 8765 --panel 8899
```

| Parámetro | Qué es | Por defecto |
| --- | --- | --- |
| `--tools` | identificadores (nombres de clase) de las fachadas cuyas herramientas expone el servidor | `MCPServerWorkspaceTools MCPServerBrowserTools` |
| `--port` | puerto del servidor MCP | `8790` |
| `--cuis` | puerto del `/evaluate` de la imagen (para levantarlo y apagarlo) | `8765` |
| `--panel` | puerto del panel | `8899` |

Queda en `http://127.0.0.1:8899`. En pantalla: **Reload tools**, **Start server**,
**Stop server**, un tilde para ver el JSON crudo, y una tarjeta por herramienta con
sus campos y el botón **Run**. La interfaz está en inglés (los comentarios del código
y la documentación del repo, en español).

## Los dos servidores que hay en juego

El panel habla con dos puertos distintos, y son dos cosas distintas:

- **El servidor MCP** (`--port`, 8790): es el paquete `MCPServer`, el producto. Escucha
  JSON-RPC en `/mcp`. Es lo único que el panel necesita para listar y correr
  herramientas.
- **El endpoint de desarrollo de la imagen** (`--cuis`, 8765): no es parte del paquete.
  Es un `WebServer` con `/evaluate` que se pega en un Workspace de la imagen
  (`demo/evaluate-endpoint.st`) y ejecuta un doit. El panel lo usa **solo** para
  `Start server` y `Stop server`: levantar el servidor MCP hay que pedirlo *dentro* de la
  imagen, y antes de que el servidor exista no hay otra puerta (el servidor no puede
  levantarse a sí mismo).

Si no tenés ese endpoint, el panel funciona igual para ver y correr herramientas; los
botones de arranque avisan que no pudieron. Y como los dos viven en la imagen que está
corriendo, si la apagás y la volvés a levantar hay que rehacerlos.
