# Technical decisions

This document records the main technical decisions of the experiment. Each entry gives the context, the decision, its trade-offs, the alternatives that were tried or considered, and its status. Other documents refer to entries by ID. Problems found along the way are in [findings.md](findings.md); the resulting structure is in [architecture.md](architecture.md).

## Summary

| ID | Decision | Status |
| --- | --- | --- |
| [D1](#d1-run-inside-the-interactive-image-over-http) | Run the server inside the user's interactive image, over HTTP | Implemented |
| [D2](#d2-control-access-not-operations) | Give the agent the programmer's capabilities; control who can reach the server | Implemented for local use (loopback only) |
| [D3](#d3-model-tools-on-ide-operations-at-the-domain-layer) | Model tools on the operations of the IDE's tool windows, at the domain layer | Implemented for Workspace, Browser and Test Runner |
| [D4](#d4-declare-each-tool-once-on-its-implementing-method) | Declare each tool once, on the method that implements it | Implemented; documentation generation deferred |
| [D5](#d5-composition-over-inheritance) | Composition over inheritance; no abstraction before a second implementer | Implemented |
| [D6](#d6-run-agent-work-below-the-ui-priority) | Run tool calls in a worker process below the UI priority | Implemented |
| [D7](#d7-cancellation-belongs-to-the-client) | Support cancellation by the client; no server-side timeout | Implemented |
| [D8](#d8-do-not-take-host-resources) | Fail explicitly instead of taking over a busy port | Implemented |
| [D9](#d9-attribute-changes-to-the-image-owner) | Attribute the agent's changes to the image owner | Partially implemented |
| [D10](#d10-the-handshake-describes-the-environment-not-rules) | Describe the environment in the handshake; add no rules or warnings | Implemented |
| [D11](#d11-reuse-the-images-mechanisms) | Reuse the image's own mechanisms before adding new ones | Partially implemented |

## D1. Run inside the interactive image, over HTTP

**Context.** One way to give an agent access to Smalltalk is to use an image as a remote interpreter: the agent sends code and reads results, often from a separate headless image or through a bridge process. The human then sees the work only through the agent, not in the environment where they program.

**Decision.** The server is a package loaded into the user's own interactive image, with its windows, state and unsaved work. It listens on HTTP from inside that image. There is no bridge process and no second image. The agent's changes appear in the same Browser and Transcript the human uses, and the human can keep working, correct the changes or undo them.

**Trade-offs.**

- The agent's work, the request handlers and the human's UI share one VM and one OS thread. A compute-bound call can freeze the UI ([F1](findings.md#f1-compute-bound-calls-blocked-the-ui-and-other-requests)); this led to D6 and D7.
- There is no isolation: the agent can damage the image the human is working in (D2).
- The human and the agent can edit the same code at the same time without conflict detection ([O1](findings.md#o1-concurrent-edits-by-the-human-and-the-agent)).
- The server's socket and processes do not survive saving and reopening the image ([O2](findings.md#o2-stale-server-handles-and-silent-listeners)).

**Alternatives considered.** A headless image, or an MCP process outside the image that talks to it over a socket. Both isolate the human's work and simplify concurrency, but they remove the shared, visible workspace this experiment set out to explore. See [prior art](#prior-art).

**Status.** Implemented.

## D2. Control access, not operations

**Context.** A tool that evaluates code (`print_it`) can do anything the other tools do, and more. Restricting the other tools therefore guides a cooperating agent but does not constrain one. SmalltalkGenie reaches the same conclusion: "the 'go only through the tools' rule is guidance to a cooperating agent, not a sandbox. So the real job is containing *who can reach the server*."

**Decision.** The agent has the capabilities, and the risks, of a programmer using the image. It gets no rule the human does not have: no evaluation timeout, no forbidden operations, no warnings on particular tools (D7, D10). If the agent can write a loop that freezes the image, so can the human in a Workspace. Instead of making damage impossible, the design aims for three properties:

- **Visibility:** changes happen in the live image and show up in its usual tools.
- **Attribution:** changes carry the image owner's author stamp (D9).
- **Reversibility:** the image's change log is the way back (D11).

The security boundary is therefore who can reach the server. Today that boundary is the network interface: the server listens on `127.0.0.1` only.

**Trade-offs.**

- Any local process that can connect to the port has full control of the image. There is no authentication, no `Origin` validation and no per-tool authorization ([deferred](#deferred-and-out-of-scope)).
- Attribution is weak: the author stamp does not distinguish agent changes from human changes, and there is no activity log (D9).
- Reversibility is manual and partial. Cancelling a call does not roll back what it already compiled, and the image has no transactions ([O3](findings.md#o3-multi-step-operations-need-review-state-and-transactions)).
- This stance fits a single developer working in a local image. A shared or regulated environment would need at least authentication, an explicit write policy (for example, confirmation in the image, or writes limited to designated classes) and an audit trail of agent actions. None of these are implemented.

**Status.** Implemented for local, single-user use.

## D3. Model tools on IDE operations at the domain layer

**Context.** The agent needs a vocabulary of operations, which can range from a single `evaluate` tool to a set of specific operations. Cuis already has a vocabulary programmers know: the operations of its tool windows (Workspace, Browser, Test Runner, Inspector, Process Browser, Debugger).

**Decision.**

1. **Each tool corresponds to an operation that exists in a Cuis tool window.** No operation is invented; the tools offer, without windows, what those windows offer.
2. **A tool is anchored in the domain message that does the work, not in the UI command that triggers it.** Removing a method is `removeSelector:` on the class, not `Browser>>removeMessage`; finding senders is `allCallsOn:`, which answers data, not `browseAllCallsOn:`, which opens a window. The planned exception is the Debugger, where the programmer's vocabulary is the debugger's own (`step`, `send`, `restart`, `proceed`).
3. **Tools keep no window state.** Cuis tool models mix commands with interaction state: `Browser>>removeMessage` takes no arguments and reads the class and selector from the current selection. Tools instead receive every argument explicitly and keep no selection, pane, list index or cursor. The only state carried from one call to the next is the image itself.
4. **The originating window is recorded as provenance.** `tools/list` includes it for each tool as `_meta.system` (`Workspace`, `Browser` or `Test Runner`). Clients can use it for grouping; the demo panel does.
5. **Tool names follow the implementing selector.** The name is the snake_case form of the facade selector, with keywords joined by `_` and no trailing colon: `compileMethod:inClass:classified:` becomes `compile_method_in_class_classified`. Names cannot contain `:` because MCP clients validate tool names.
6. **Evaluation is `print_it`, not `evaluate`.** It is the Workspace's own operation: evaluate code and answer the printed result, limited to 10,000 characters as in the editor. Under that name it is one window operation among the others rather than a special entry point.

The model/view split behind rule 2, as found in the Cuis 7.8 image:

| Model | Category | Superclass | Window |
| --- | --- | --- | --- |
| `Browser` | `Tools-Browser` | `CodeProvider` | `BrowserWindow` (a `CodeWindow`) |
| `MethodSet`, `MethodReference` | `Tools-Browser` | `CodeProvider`, `Object` | `MethodSetWindow` |
| `Debugger` | `Tools-Debugger` | `CodeProvider` | `DebuggerWindow` (a `CodeWindow`) |
| `Inspector` | `Tools-Inspector` | `TextProvider` | `InspectorWindow` |
| `TestRunner` | `Tools-Testing` | `ActiveModel` | `TestRunnerWindow` |
| `ProcessBrowser` | `Tools-Profiling` | `ActiveModel` | `ProcessBrowserWindow` |
| `Workspace` | `System-Text` | `TextModel` | `WorkspaceWindow` |

All the windows are in `Morphic-Tool Windows`. `Browser` and `Debugger` are both `CodeProvider`s, which is why they share `CodeWindow`.

**Trade-offs.**

- Names get long (`define_class_subclass_of_variables_category`) but are predictable to anyone who knows the selectors.
- Some IDE operations have no implementation independent of the UI. Renaming a selector together with its senders only exists in the Browser and the editor, so there is no tool for it ([O3](findings.md#o3-multi-step-operations-need-review-state-and-transactions)).
- The specific tools are a convenience, not a boundary (D2). Nothing forces an agent to prefer them over `print_it`; the catalogue only describes them.
- Results are text for reading, not structured data.

**Alternatives considered.**

- Only `evaluate`: the smallest surface and, in principle, sufficient, but it offers no vocabulary of the environment and turns every operation into an ad-hoc script. The Smalltalk precedents reviewed also combine Browser-style tools with an evaluation tool.
- `evaluate` presented as an exception, with a note that the specific tools are preferred. Dropped once evaluation became `print_it` (rule 6); D10 explains why no warning was added.

**Status.** Implemented for the Workspace (1 tool), Browser (16) and Test Runner (2). Inspector, Process Browser and Debugger tools are [deferred](#deferred-and-out-of-scope).

## D4. Declare each tool once, on its implementing method

**Context.** A tool has a name, a description, an argument list and an implementation. When these live in different places (a registry, a schema file, documentation) they drift apart.

**Decision.** A tool is a method of a facade class carrying an `mcpTool:system:arguments:` pragma. The pragma gives the name, the window and the argument names; the method comment gives the description; the method body is the implementation. The catalogue is built by reading the pragmas ([declaring a tool](architecture.md#declaring-a-tool)).

**Trade-offs.**

- Pragma arguments must be literals, so a declaration cannot compute anything.
- Method comments are kept in the sources file, not in the compiled method, so reading a description requires the method source.
- The input schema is minimal: every argument is a required string. Richer types would need a richer pragma.

**Planned, not built.** The same metadata was meant to produce documentation for people: a Markdown catalogue and an OpenAPI 3.1 document. MCP input schemas are JSON Schema, so the mapping is direct (`open-webui/mcpo` does the same). For now the catalogue is browsed with the demo panel or the MCP Inspector.

**Status.** Implemented. Documentation generation is deferred.

## D5. Composition over inheritance

**Context.** The design written before implementation sketched about 25 classes, including a command class per protocol method, a transport abstraction, a decorator for version checks and several strategy objects ([planned vs. built](architecture.md#planned-vs-built)).

**Decision.**

- Inheritance only for real polymorphism: the same protocol with different behavior and more than one actual implementer. Everything else is composition.
- Smalltalk code is written against a protocol, not a superclass. An abstract class with a single implementer is ceremony, so there is no base tool or base server class. All 13 production classes subclass `Object`.
- One responsibility per class. The protocol does not know HTTP; the facades do not know the protocol.
- No Cuis class is modified. Everything lives in the package.
- No singleton. A server is created with its parameters and destroyed by its owner; several can coexist in one image.

**Trade-offs.**

- `MCPServerProtocol>>handleMessage:` routes the five supported methods with a sequence of conditionals rather than a table of command objects. At this size it is shorter and easier to follow; a larger protocol surface would justify revisiting it.
- To avoid single-implementer classes, some roles are combined: `MCPServer` is both the composition root and the HTTP adapter.

**Status.** Implemented.

## D6. Run agent work below the UI priority

**Context.** A compute-bound tool call blocked both the human's UI and every other request ([F1](findings.md#f1-compute-bound-calls-blocked-the-ui-and-other-requests)). Cuis's `WebServer` runs request handlers at priority 60, above the UI at 50, and a Smalltalk process is only preempted by a process of higher priority.

**Decision.** `MCPServerTool` runs each call in a worker process of its own, at `Processor userInterruptPriority - 10` (40 in Cuis 7.8). The request handler waits on a semaphore for the result. Only the worker's priority is set: the handler, the UI and any other server in the image keep the priorities Cuis gives them. The value is relative, so it stays below the UI if Cuis changes its priority levels.

**Trade-offs.**

- The UI preempts agent work, so the agent's computations slow down while the human is active.
- The handler still blocks for the duration of the call: every call in progress holds a handler process and a worker process.
- The worker gives cancellation a target that can be terminated without touching the handler (D7).
- It is a mitigation, not a guarantee: evaluated code can raise its own priority, and a primitive that blocks the VM stops every process ([F1](findings.md#f1-compute-bound-calls-blocked-the-ui-and-other-requests)).

**Status.** Implemented (`MCPServerToolTest>>test03RunsBelowTheUIsPriority`).

## D7. Cancellation belongs to the client

**Context.** Long or runaway calls need a way to stop. The MCP specification (2025-06-18) makes timeouts the responsibility of the sender of a request, which should send `notifications/cancelled` when a timeout expires. The receiver should stop processing, release resources and not respond, and may ignore a cancellation it cannot act on.

**Decision.**

- The server implements `notifications/cancelled`. It terminates the worker running the named request and sends no JSON-RPC response for it; the cancelled HTTP request is answered `202` with an empty body.
- The server has no timeout of its own.
- Running calls are tracked in an in-flight registry owned by the server, not by a connection, because a cancellation arrives in a different HTTP request from the call it cancels.
- A request id held by more than one running call is not cancelled. JSON-RPC ids are unique per client, not globally, and without MCP sessions two clients can pick the same id. Stopping work nobody asked to stop is worse than stopping none.

The mechanism and its invariants are described in [cancellation](architecture.md#cancellation).

**Trade-offs.**

- A client that never cancels can leave a call running indefinitely.
- Cancelling does not undo side effects: what the call already compiled stays compiled.
- With colliding ids, a cancellation does nothing and reports nothing, since notifications have no response. MCP sessions would make the scope exact ([deferred](#deferred-and-out-of-scope)).
- A cancellation that arrives before the worker has started may leave the cancelled request waiting indefinitely ([O8](findings.md#o8-cancellation-before-the-worker-runs), suspected).

**Alternatives considered.** A server-side watchdog that terminates calls after a timeout. Rejected: a human can freeze the image from a Workspace too, so the agent should not get a limit the human does not have, and the specification assigns timeouts to the client.

**Status.** Implemented (`MCPServerInFlightRequestsTest`; `MCPServerProtocolTest`, tests 09 to 12; `MCPServerTest>>test12ACancellationStopsARequestOverHttp`).

## D8. Do not take host resources

**Context.** Restarting a server by hand (destroy, wait, create again) was easy to get wrong, and a port could stay held by a socket that no longer accepted connections ([O2](findings.md#o2-stale-server-handles-and-silent-listeners)). To simplify this, a `restart` was implemented that freed the port by destroying whatever `WebServer` was listening on it, together with an idempotent `start`.

**Decision.** Both were reverted. A port is an operating-system resource: whoever holds it keeps it, and the next process that asks for it fails. A server should not kill another listener to take its port, least of all an MCP server acting on a client's behalf. Moving or restarting the server is a decision for the owner of the image.

- `start` on a server that is already listening fails with `Already listening on port N`.
- `start` on a port held by something else fails with `Could not listen on port N: ...`, including the underlying error.
- `isListening` tells whether the server has a listener process, which its port and catalogue cannot tell.

**Trade-offs.** Recovering from a stale listener is manual: the owner finds and destroys the `WebServer` holding the port ([README](../README.md#freeing-a-port-held-by-a-stale-server)). In exchange, a silent failure (a port that accepts nothing) becomes an explicit error at start.

**Status.** Implemented (`MCPServerTest>>test07StartingTwiceSaysItIsAlreadyListening`). The forced `restart` is rejected and was removed.

## D9. Attribute changes to the image owner

**Context.** Cuis stamps every compiled method with an author. A new image has no author, and the first code change opens a dialog asking for one, which a server cannot answer ([F4](findings.md#f4-a-new-image-blocks-on-a-modal-author-prompt)). The first approach gave the agent a distinct stamp, `MCP(<owner's initials>)`, so its changes could be told apart. It worked:

```
!MCPServerBrowserToolsScratch methodsFor: 'test' stamp: 'MCP(S.V.) 13/Sep/2026 20:01:17'!
!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:41:59'!
```

**Decision.** The distinct stamp was reverted. An author stamp stands for accountability, and accountability belongs to the person who authorizes a change, whatever tool produced it. This follows the git convention: the commit author is the person, and help from a tool is noted in the message, not by replacing the author.

- The package never sets or invents an author. What the agent writes carries the image owner's stamp.
- `start` requires an author. It reads it with `Utilities authorInitialsPerSe`, which never opens a dialog, and fails with an explicit message if none is set. A hang becomes an error at start.
- Recording what the agent did was meant to be the job of a server activity log. **This is not implemented**: the only record the server writes is a Transcript line for each cancelled request.

**Trade-offs.**

- Agent changes and human changes cannot be told apart by their stamps.
- Two lessons from the reverted approach:
  - The author was switched around every call, in the tool execution path. That put a cross-cutting concern in a position to break every tool, including the ones needed to repair it. Such concerns should be best-effort and unable to fail the operation.
  - A stamp is fixed when the method is compiled and written to the `.changes` file, and cannot be corrected later. Attribution by stamp has to be decided before executing; attribution by log does not.

**Status.** Partially implemented. The author requirement is implemented (`MCPServerTest>>test06StartingRequiresAnAuthor`); the distinct stamp is rejected; the activity log is deferred.

## D10. The handshake describes the environment, not rules

**Context.** The `initialize` result can include `instructions`, a text the client gives to the model. Nothing in the tool list tells the agent that it is working in a running image shared with a person.

**Decision.** `MCPServerProtocol>>instructions` answers a short text, written by the author, that describes the situation:

> This server connects you to a living Smalltalk environment. You are not editing static files in isolation; you are collaborating inside a running system alongside a human. Every change you make is immediately alive and present in their world. The system hides nothing from you. You possess the absolute freedom to redefine its very fabric on the fly. However, this profound malleability means that a careless action can shatter the environment. Keep in mind that every modification carries the human's signature. They are staking their name on your work, so act with thoughtful judgment.

- It describes the environment and the human's stake in it, without prohibitions, which would contradict D2.
- It does not name tool windows. The mapping to windows helps design the interface and is of no use to the agent. `MCPServerProtocolTest>>test08InitializeTellsTheClientAboutTheImage` checks that the text is a single paragraph, mentions a living environment, the human and the signature, and does not mention `Workspace`.
- The tools carry no warnings either. A note such as "prefer the specific tools over `print_it`" would tell the agent not to do what the Workspace allows a person to do; a programmer skilled and confident enough to do everything from a Workspace loses nothing by it. The tool designer's responsibility is to offer specific, well-described tools, in the way the Browser complements the Workspace without replacing it.

**Trade-offs.** Whether the text changes an agent's behavior was not measured. It relies on the model's judgment rather than on enforcement, which is consistent with D2 and shares its limits.

**Status.** Implemented.

## D11. Reuse the image's mechanisms

**Context.** Several problems in this project already have an answer in Cuis, usually in the code behind a tool window.

**Decision.** Before adding a mechanism, find the one the image already uses and follow it.

- **Reverting changes:** `ChangeSet` and the `VersionsBrowser` record and restore method versions. The server adds no revert mechanism.
- **Cleanup under termination:** whoever opens a resource closes it in `ensure:`, as `FileEntry>>writeStreamDo:` does. It matters because a call can be terminated at any point ([execution and concurrency](architecture.md#execution-and-concurrency)).
- **Process safety:** `ProcessBrowser class>>rulesFor:` answers whether a process may be suspended or debugged, and protects the UI process, the low-space watcher, the finalization process, the background process, the input watchers and the `Delay` timer. Future process tools are meant to apply these rules instead of a list of their own.
- **UI work from other processes:** Cuis defers it to the UI process with `UISupervisor whenUIinSafeState:` ([O4](findings.md#o4-ui-actions-from-non-ui-processes)).
- **Declarations and encoding:** `Pragma`, `MethodReference`, and the `String fromUtf8Bytes:` and `asUtf8Bytes` pair that `WebClient` also uses ([F2](findings.md#f2-request-and-response-bodies-were-not-utf-8)).

**Trade-offs.** The design inherits the image's limits: there are no transactions to reuse ([O3](findings.md#o3-multi-step-operations-need-review-state-and-transactions)), and the Browser does not detect concurrent edits ([O1](findings.md#o1-concurrent-edits-by-the-human-and-the-agent)).

**Status.** Partially implemented. Reverting relies on the image's tools, cleanup follows the `ensure:` convention, and declarations and encoding use the image's classes. The process rules apply to tools that do not exist yet, and UI work is not yet deferred to the UI process.

## Deferred and out of scope

| Item | Why it is not implemented | What it would involve |
| --- | --- | --- |
| Optimistic concurrency for write tools | Real use would need it ([O1](findings.md#o1-concurrent-edits-by-the-human-and-the-agent)), but it complicates the agent's interface with version tokens, conflicts and retries, and the experiment does not depend on it. Left out deliberately. | Reads answer a version token; writes require it and fail with the current source when it no longer matches |
| Agent change set, write announcements, revert tooling | The image's `ChangeSet` and `VersionsBrowser` already allow manual reverts (D11) | A change set per server, a Transcript line per write, a tool to discard the agent's changes ([O6](findings.md#o6-growth-of-processes-and-change-sets)) |
| Activity log | Not reached (D9) | A record of each call and its effects, readable from the image |
| Serialized writes | The design assumes one client | A mutex around the write tools |
| Checkpoints | Saving a copy of the image is expensive, and the experiment did not need it | `saveAs:` to a separate file before risky work |
| Renaming a selector with its senders | Needs a review step and all-or-nothing application ([O3](findings.md#o3-multi-step-operations-need-review-state-and-transactions)) | Stateful sessions, and validation of every rewritten sender before applying |
| MCP sessions (`Mcp-Session-Id`) | One client needs no per-client state; the server does not keep the negotiated protocol version | Per-session state, and exact scoping of request ids for cancellation (D7) |
| `Origin` validation, `405` for `GET`, access token | Binding to loopback was enough for local use (D2) | Checks in `MCPServer>>handleRequest:`; a token given when the server is created |
| Tool `annotations` (`readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`) and `notifications/tools/list_changed` | Not needed to explore the integration; noted as the way to express permissions | Hints declared in the pragma; a catalogue that can change |
| Inspector, Process Browser and Debugger tools | The core (explore, read, edit, test) came first. The Debugger is the most delicate: a stopped process and its stack must survive between calls | Sessions with explicit handles (session, process, frame, variables), as in the Debug Adapter Protocol; process tools that apply `ProcessBrowser class>>rulesFor:` (D11) |
| Showing results in real tool windows | Not needed for the experiment | Opening Cuis tools (`MethodSet`, `Browser`) when the human asks, from the UI process ([O4](findings.md#o4-ui-actions-from-non-ui-processes)) |
| Generated tool documentation | The demo panel and the MCP Inspector cover browsing the catalogue (D4) | A Markdown and OpenAPI 3.1 generator over the catalogue |
| Starting the server with the image | Started by hand from a Workspace | A startup hook, which also touches [O2](findings.md#o2-stale-server-handles-and-silent-listeners) |
| Typed input schemas | Strings cover the current tools | Types in the pragma, and conversion in the protocol |

## Prior art

Projects reviewed before and during the experiment: existing MCP servers that expose a live, modifiable environment to an agent.

| Project | What it is | What it informed |
| --- | --- | --- |
| `KentBeck/SmalltalkGenie` (Pharo) | 26 tools over a live image, reached over loopback; headless, without Morphic | Browser-style tool names (`list_classes`, `get_method_source`, `search_implementors`, `define_method`, `run_test`, and `eval`). The conclusion that tools are not a sandbox, so access is the boundary: loopback, `Origin` checks, an optional token, gating of dangerous tools (D2). Keeping the interactive UI is the difference this experiment explores (D1). |
| `CorporateSmalltalkConsultingLtd/ClaudeSmalltalk` (Squeak) | 14 tools over TCP | Another Browser-like surface: evaluate, navigate hierarchies, read and write methods, save the image. |
| `mumez/smalltalk-interop-mcp-server` (Pharo, Squeak) | An MCP server outside the image plus a server inside it | The bridge arrangement that D1 avoids; parameters such as the stack-trace depth of reported errors. |
| `quasi/cl-mcp-server` (Common Lisp) | 37 tools over a persistent REPL | Compiling without running (`compile-form`), `validate-syntax`, `who-calls`, and configurable evaluation timeout and output limits (`configure-limits`). |
| `ctford/mcp-nrepl`, `JohanCodinha/nrepl-mcp-server` (Clojure) | Access to a live nREPL | The same stance as D2 ("the same level of access you have when typing at a REPL prompt"), and the note that a shared session means one evaluation affects the next. |
| `bettyguo/mcp-jupyter` | A live Jupyter kernel | Answering summaries by default rather than raw data, with opt-in tools for more; compare the output bounds in [architecture](architecture.md#output-bounds-and-costs). |
| `ChromeDevTools/chrome-devtools-mcp` | A live browser | A large precedent of a live environment an agent can inspect, debug and modify; isolation options (`--isolated`, `--headless`). |

The descriptions summarize these projects as they were reviewed during the experiment; they were not re-checked for this document.

Two clauses of the MCP specification (2025-06-18) shaped D7:

- **Cancellation.** `notifications/cancelled` names a request id. The receiver should stop processing, release resources and not send a response. Either side may cancel, and a receiver may ignore a cancellation for a request that cannot be cancelled.
- **Timeouts.** The sender of a request sets them, and should send a cancellation when one expires.
