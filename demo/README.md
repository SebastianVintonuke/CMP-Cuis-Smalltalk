# Demo

Two files for trying the server by hand. Loading the package and starting the server are described in the [main README](../README.md#getting-started).

## Panel

`panel-mcp.py` serves a small web page for calling the MCP server manually, similar in purpose to Swagger UI. It uses only the Python 3 standard library.

```bash
python3 demo/panel-mcp.py --port 8790 --panel 8899
```

| Option | Meaning | Default |
| --- | --- | --- |
| `--port` | Port of the MCP server running in the image | `8790` |
| `--panel` | Port on which the panel serves its page | `8899` |

Open `http://127.0.0.1:8899`. The page:

- shows the fields of the `initialize` result, including `instructions`;
- lists the tools answered by `tools/list`, grouped by `_meta.system`, each with a form built from its `inputSchema`, so no tool names are hard-coded in the panel;
- runs a tool with **Run** and shows its text result, and optionally the raw JSON;
- gives each call a request id (`panel-1`, `panel-2`, ...), shows it while the call runs, and offers a **Cancel** button that sends `notifications/cancelled` for that id. A cancelled request receives no response, as the protocol requires, so the panel reports the cancellation instead of waiting for a result.

The panel is only a client. The Python process makes the MCP requests, not the browser, so CORS does not apply. The panel handles each browser request in its own thread, which is what lets it send a cancellation while a call is still waiting for its response.

## Cancellation demo

`cancel-demo.st` is code to paste into the `code` field of `print_it`. It runs 20 rounds. In each round it keeps the CPU busy for one second and then waits for two, writing its progress to the Transcript.

It raises its own process priority to 70, above the UI (50) and the request handlers (60), so that the image becomes unresponsive while it computes and there is something worth cancelling. Without that line the worker runs at priority 40 and the image stays responsive ([D6](../docs/decisions.md#d6-run-agent-work-below-the-ui-priority)).

Pressing **Cancel** stops the Transcript output immediately, because the worker process is terminated. The two-second waits are necessary: at priority 70, the request handler that receives the cancellation only gets to run while the call is waiting. A call that raises its priority and never waits cannot be cancelled ([F1](../docs/findings.md#f1-compute-bound-calls-blocked-the-ui-and-other-requests)).
