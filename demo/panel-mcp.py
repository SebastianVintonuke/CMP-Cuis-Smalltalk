#!/usr/bin/env python3
"""Panel estilo Swagger para el servidor MCP que vive en la imagen de Cuis.

Sirve una pagina en http://127.0.0.1:<panel> que:
  - lista las herramientas del servidor MCP (tools/list),
  - arma un formulario por herramienta con los campos de su inputSchema,
  - y tiene un boton para correrla (tools/call) y ver la respuesta.

La lista es dinamica: sale de tools/list, no hay nombres de herramientas aca.

Los pedidos al MCP los hace este proceso (no el navegador), asi que no hay problema
de CORS ni de transporte. Ademas, si el servidor MCP no contesta, el panel se lo pide
a la imagen (endpoint /evaluate del puerto --cuis): es lo que usan los botones de
arrancar y apagar, y necesita los identificadores de las fachadas de herramientas.

Uso:
    python3 demo/panel-mcp.py --tools MCPServerWorkspaceTools MCPServerBrowserTools \\
        --port 8790 --cuis 8765 --panel 8899
"""
import argparse
import json
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Parametros del programa (los llena main).
MCP_PORT = 8790
CUIS_PORT = 8765
TOOLS = ["MCPServerWorkspaceTools", "MCPServerBrowserTools"]

_COUNTER = [0]

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>MCP panel - Cuis</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 15px/1.45 system-ui, sans-serif; margin: 0; padding: 24px; max-width: 900px; }
  h1 { font-size: 19px; margin: 0 0 4px; }
  .sub { opacity: .7; font-size: 13px; margin-bottom: 18px; }
  .tool { border: 1px solid #8884; border-radius: 8px; padding: 14px 16px; margin-bottom: 14px; }
  .tool h2 { font-size: 15px; margin: 0 0 6px; font-family: ui-monospace, monospace; }
  .desc { white-space: pre-wrap; opacity: .8; font-size: 13px; margin-bottom: 10px; }
  label { display: block; font-size: 12px; opacity: .75; margin: 8px 0 3px; }
  input, textarea { width: 100%; box-sizing: border-box; font-family: ui-monospace, monospace;
                    font-size: 13px; padding: 6px 8px; border: 1px solid #8886; border-radius: 5px; }
  textarea { min-height: 70px; resize: vertical; }
  button { padding: 7px 14px; font-size: 14px; border-radius: 6px;
           border: 1px solid #8886; background: #2f6feb; color: #fff; cursor: pointer; }
  button.ghost { background: transparent; color: inherit; }
  button:disabled { opacity: .5; cursor: default; }
  pre { white-space: pre-wrap; word-break: break-word; margin: 10px 0 0; padding: 9px;
        background: #8881; border-radius: 5px; font-size: 13px; max-height: 320px; overflow: auto; }
  .ok { border-left: 3px solid #2e7d32; }
  .err { border-left: 3px solid #c62828; }
  .bar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
  .bar label.inline { margin: 0; display: flex; gap: 6px; align-items: center; font-size: 13px; opacity: .8; }
  .bar label.inline input { width: auto; }
</style>
</head>
<body>
<h1>MCP panel</h1>
<div class="sub" id="sub">connecting...</div>
<div class="bar">
  <button class="ghost" onclick="load()">Reload tools</button>
  <button class="ghost" onclick="server('start')">Start server</button>
  <button class="ghost" onclick="server('stop')">Stop server</button>
  <label class="inline"><input type="checkbox" id="raw"> show raw JSON</label>
</div>
<div id="server"></div>
<div id="tools"></div>
<script>
async function load() {
  const tools = document.getElementById('tools');
  const sub = document.getElementById('sub');
  tools.innerHTML = '';
  sub.textContent = 'reading tools/list...';
  try {
    const r = await fetch('/api/tools');
    const data = await r.json();
    if (!r.ok) throw new Error(data.error || r.statusText);
    sub.textContent = data.length + (data.length === 1 ? ' tool' : ' tools');
    data.forEach(t => tools.appendChild(card(t)));
  } catch (e) {
    sub.textContent = 'not connected';
    tools.innerHTML = '<pre class="err">Could not read the tool list: ' + e.message +
      '<\\n><\\n>Is the MCP server running? Press "Start server" (it needs the Cuis image).</pre>';
  }
}
async function server(action) {
  const box = document.getElementById('server');
  box.innerHTML = '<pre>working...</pre>';
  try {
    const r = await fetch('/api/server/' + action, { method: 'POST' });
    const data = await r.json();
    if (!r.ok || (data.answer || '').startsWith('ERROR')) {
      throw new Error(data.error || data.answer || r.statusText);
    }
    box.innerHTML = '<pre class="ok">' + action + ': ' + data.answer + '</pre>';
    await load();
  } catch (e) {
    box.innerHTML = '<pre class="err">Could not ' + action + ' the server: ' + e.message + '</pre>';
  }
}
function card(t) {
  const box = document.createElement('div');
  box.className = 'tool';
  const props = (t.inputSchema && t.inputSchema.properties) || {};
  const h = document.createElement('h2');
  h.textContent = t.name;
  box.appendChild(h);
  const d = document.createElement('div');
  d.className = 'desc';
  d.textContent = t.description || '';
  box.appendChild(d);
  const inputs = {};
  Object.keys(props).forEach(name => {
    const l = document.createElement('label');
    l.textContent = name;
    box.appendChild(l);
    const long = /code|source|expres|selector/i.test(name);
    const el = document.createElement(long ? 'textarea' : 'input');
    el.placeholder = name;
    box.appendChild(el);
    inputs[name] = el;
  });
  const b = document.createElement('button');
  b.textContent = 'Run';
  box.appendChild(b);
  const out = document.createElement('pre');
  out.style.display = 'none';
  box.appendChild(out);
  b.onclick = async () => {
    const args = {};
    Object.keys(inputs).forEach(k => { args[k] = inputs[k].value; });
    b.disabled = true;
    out.style.display = 'block';
    out.className = '';
    out.textContent = 'running...';
    try {
      const r = await fetch('/api/call', { method: 'POST', body: JSON.stringify({ name: t.name, arguments: args }) });
      const raw = await r.json();
      const showRaw = document.getElementById('raw').checked;
      const res = raw && raw.result;
      if (res && res.content && res.content.length) {
        out.className = res.isError ? 'err' : 'ok';
        out.textContent = (res.isError ? '[error] ' : '') + res.content[0].text +
          (showRaw ? '\\n\\n--- raw JSON ---\\n' + JSON.stringify(raw, null, 2) : '');
      } else {
        out.className = 'err';
        out.textContent = JSON.stringify(raw, null, 2);
      }
    } catch (e) {
      out.className = 'err';
      out.textContent = 'Could not call it: ' + e.message;
    }
    b.disabled = false;
  };
  return box;
}
load();
</script>
</body>
</html>
"""


def mcp_url():
    return f"http://127.0.0.1:{MCP_PORT}/mcp"


def rpc(method, params=None):
    """Un pedido JSON-RPC al servidor MCP."""
    _COUNTER[0] += 1
    payload = {"jsonrpc": "2.0", "id": _COUNTER[0], "method": method}
    if params is not None:
        payload["params"] = params
    request = urllib.request.Request(
        mcp_url(),
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        },
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        body = response.read().decode("utf-8", "replace")
        content_type = response.headers.get("Content-Type", "")
    if "text/event-stream" in content_type:
        # Streamable HTTP puede contestar por SSE: quedarse con el ultimo data:
        lines = [line[5:].strip() for line in body.splitlines() if line.startswith("data:")]
        body = lines[-1] if lines else ""
    return json.loads(body) if body.strip() else None


def cuis_evaluate(source):
    """Le manda Smalltalk al endpoint /evaluate de la imagen y contesta lo que dice."""
    request = urllib.request.Request(
        f"http://127.0.0.1:{CUIS_PORT}/evaluate",
        data=source.encode("utf-8"),
        headers={"Content-Type": "text/plain; charset=utf-8"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8", "replace").strip()


def start_source():
    """El Smalltalk que levanta el servidor: apaga lo que escuche en ese puerto y crea
    uno nuevo con las fachadas que se pasaron por parametro."""
    tools = " ".join(tool + "." for tool in TOOLS)
    return f"""| server |
WebServer allInstances do: [ :each |
	(each listenerProcess isNil not and: [ each listenerPort = {MCP_PORT} ]) ifTrue: [ each destroy ] ].
server := MCPServer on: {MCP_PORT} tools: {{ {tools} }}.
server start.
Smalltalk at: #MCPDemo put: server.
'serving on {MCP_PORT}'"""


def stop_source():
    """El Smalltalk que apaga lo que este escuchando en ese puerto."""
    return f"""WebServer allInstances do: [ :each |
	(each listenerProcess isNil not and: [ each listenerPort = {MCP_PORT} ]) ifTrue: [ each destroy ] ].
'stopped {MCP_PORT}'"""


def ensure_server():
    """Si el servidor MCP no contesta, se lo pide a la imagen. Contesta el detalle."""
    try:
        rpc("tools/list")
        return "already serving"
    except Exception:  # noqa: BLE001 - si no contesta, lo levantamos
        pass
    answer = cuis_evaluate(start_source())
    if answer.startswith("ERROR"):
        raise RuntimeError(answer)
    return answer


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code, body, content_type="application/json"):
        data = body.encode("utf-8") if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_error(self, error):
        self._send(500, json.dumps({"error": f"{type(error).__name__}: {error}"}))

    def do_GET(self):
        if self.path.startswith("/api/tools"):
            try:
                response = rpc("tools/list") or {}
                tools = (response.get("result") or {}).get("tools", [])
                self._send(200, json.dumps(tools))
            except Exception as error:  # noqa: BLE001 - el panel tiene que poder contarlo
                self._send_error(error)
        else:
            self._send(200, PAGE, "text/html; charset=utf-8")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0) or 0)
        try:
            if self.path.startswith("/api/server/"):
                action = self.path.rsplit("/", 1)[-1]
                source = start_source() if action == "start" else stop_source()
                self._send(200, json.dumps({"answer": cuis_evaluate(source)}))
                return
            data = json.loads(self.rfile.read(length) or b"{}")
            response = rpc(
                "tools/call",
                {"name": data.get("name"), "arguments": data.get("arguments") or {}},
            )
            self._send(200, json.dumps(response))
        except Exception as error:  # noqa: BLE001
            self._send_error(error)

    def log_message(self, *args):
        pass


def main():
    global MCP_PORT, CUIS_PORT, TOOLS
    parser = argparse.ArgumentParser(description="Panel estilo Swagger para el MCP de Cuis.")
    parser.add_argument(
        "--tools", nargs="+", default=TOOLS,
        help="identificadores (nombres de clase) de las fachadas cuyas herramientas expone el servidor",
    )
    parser.add_argument("--port", type=int, default=MCP_PORT, help="puerto del servidor MCP")
    parser.add_argument("--cuis", type=int, default=CUIS_PORT, help="puerto del /evaluate de la imagen")
    parser.add_argument("--panel", type=int, default=8899, help="puerto de este panel")
    options = parser.parse_args()
    MCP_PORT = options.port
    CUIS_PORT = options.cuis
    TOOLS = options.tools
    try:
        print(f"MCP {mcp_url()} -> {ensure_server()}", flush=True)
    except Exception as error:  # noqa: BLE001 - el panel sirve igual, para poder verlo
        print(f"MCP {mcp_url()} -> no responde y no pude levantarlo: {error}", flush=True)
    print(f"Panel en http://127.0.0.1:{options.panel}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", options.panel), Handler).serve_forever()


if __name__ == "__main__":
    main()
