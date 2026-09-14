#!/usr/bin/env python3
"""Swagger-like panel for the MCP server that lives in the Cuis image.

It is a client of the product and nothing else: it assumes the MCP server is already running
inside the image and talks to it over MCP (JSON-RPC on HTTP). The only thing it has to be told
is the port that server listens on.

It serves a page at http://127.0.0.1:<panel> that:
  - lists the tools of the MCP server (tools/list),
  - builds a form per tool with the fields of its inputSchema,
  - and has a button to run it (tools/call) and see the answer.

The list is dynamic: it comes from tools/list, and there are no tool names here. The MCP
requests are made by this process (not by the browser), so there is no CORS or transport issue.

Usage:
    python3 demo/panel-mcp.py --port 8790 --panel 8899
"""
import argparse
import html
import json
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Program parameters (main fills them in).
MCP_PORT = 8790

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
  details.group { border: 1px solid #8884; border-radius: 8px; margin-bottom: 16px; padding: 8px 12px; }
  details.group > summary { cursor: pointer; font-size: 14px; font-weight: 600; padding: 4px 2px; }
  details.group > summary .count { opacity: .6; font-weight: 400; }
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
  .note { border-left: 3px solid #8886; padding: 2px 0 2px 12px; margin-bottom: 18px; opacity: .85; }
  .note-label { font-size: 11px; text-transform: uppercase; letter-spacing: .04em; opacity: .6; margin-bottom: 4px; }
  .bar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
  .bar label.inline { margin: 0; display: flex; gap: 6px; align-items: center; font-size: 13px; opacity: .8; }
  .bar label.inline input { width: auto; }
</style>
</head>
<body>
<h1>MCP panel</h1>
<div class="sub" id="sub">connecting to __PORT__...</div>
__NOTE__
<div class="bar">
  <button class="ghost" onclick="load()">Reload tools</button>
  <label class="inline"><input type="checkbox" id="raw"> show raw JSON</label>
</div>
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
    sub.textContent = data.length + (data.length === 1 ? ' tool' : ' tools') + ' on port __PORT__';
    render(data);
  } catch (e) {
    sub.textContent = 'not connected';
    tools.innerHTML = '<pre class="err">Could not read the tool list: ' + e.message +
      '<\\n><\\n>Is the MCP server running on port __PORT__? Start it from the image: ' +
      'MCPServer on: __PORT__ tools: { ... } then start.</pre>';
  }
}
function render(tools) {
  // One window per collapsible item, and inside it the tools that come from there.
  const box = document.getElementById('tools');
  const groups = new Map();
  tools.forEach(t => {
    const system = (t._meta && t._meta.system) || 'Other';
    if (!groups.has(system)) groups.set(system, []);
    groups.get(system).push(t);
  });
  box.innerHTML = '';
  Array.from(groups.keys()).sort().forEach(system => {
    const list = groups.get(system);
    const group = document.createElement('details');
    group.className = 'group';
    group.open = true;
    const summary = document.createElement('summary');
    summary.textContent = system + ' ';
    const count = document.createElement('span');
    count.className = 'count';
    count.textContent = '(' + list.length + ')';
    summary.appendChild(count);
    group.appendChild(summary);
    list.forEach(t => group.appendChild(card(t)));
    box.appendChild(group);
  });
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


def instructions():
    """The message the server gives a client when it connects, or empty if it cannot be read."""
    try:
        response = rpc("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                      "clientInfo": {"name": "panel", "version": "1"}})
        return ((response or {}).get("result") or {}).get("instructions", "")
    except Exception:  # noqa: BLE001 - the panel still serves without it
        return ""


def page():
    block = ""
    note = instructions()
    if note:
        block = ('<div class="note"><div class="note-label">What the server tells an agent that connects'
                 '</div>' + html.escape(note) + '</div>')
    return PAGE.replace("__PORT__", str(MCP_PORT)).replace("__NOTE__", block)


def rpc(method, params=None):
    """One JSON-RPC request to the MCP server."""
    _COUNTER[0] += 1
    payload = {"jsonrpc": "2.0", "id": _COUNTER[0], "method": method}
    if params is not None:
        payload["params"] = params
    request = urllib.request.Request(
        f"http://127.0.0.1:{MCP_PORT}/mcp",
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
        # Streamable HTTP may answer over SSE: keep the last data: line.
        lines = [line[5:].strip() for line in body.splitlines() if line.startswith("data:")]
        body = lines[-1] if lines else ""
    return json.loads(body) if body.strip() else None


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
            except Exception as error:  # noqa: BLE001 - the panel has to be able to report it
                self._send_error(error)
        else:
            self._send(200, page(), "text/html; charset=utf-8")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0) or 0)
        try:
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
    global MCP_PORT
    parser = argparse.ArgumentParser(
        description="Panel to use the MCP server of the Cuis image by hand."
    )
    parser.add_argument("--port", type=int, default=MCP_PORT, help="port of the MCP server")
    parser.add_argument("--panel", type=int, default=8899, help="port of this panel")
    options = parser.parse_args()
    MCP_PORT = options.port
    try:
        response = rpc("tools/list") or {}
        tools = (response.get("result") or {}).get("tools", [])
        print(f"MCP on port {MCP_PORT}: {len(tools)} tools", flush=True)
    except Exception as error:  # noqa: BLE001 - the panel still serves, so it can be seen
        print(f"MCP on port {MCP_PORT}: not answering ({error})", flush=True)
    print(f"Panel on http://127.0.0.1:{options.panel}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", options.panel), Handler).serve_forever()


if __name__ == "__main__":
    main()
