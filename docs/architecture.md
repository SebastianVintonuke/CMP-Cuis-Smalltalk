# Architecture

This document describes the implementation in `src/`. The reasons for the main choices are in [decisions.md](decisions.md). The last section compares the implementation with the design sketched before it was written.

## Overview

```
MCP client
    |  HTTP POST /mcp (JSON-RPC, UTF-8)
    v
WebServer (Cuis), bound to 127.0.0.1      one handler process per request, priority 60
    |
MCPServer                                 composition root and HTTP adapter:
    |                                     UTF-8 bytes <-> text, JSON, 200 or 202
MCPServerProtocol                         MCP methods; a new instance per request
    |
MCPServerToolCatalogue                    tools by name, built once from pragmas
    |
MCPServerTool ----- MCPServerInFlightRequests
    |               registry of running calls, used by cancellation
    |                                     runs each call in a worker process, priority 40
Facades, one per tool window
    MCPServerWorkspaceTools               print_it
    MCPServerBrowserTools                 16 Browser operations
    MCPServerTestingTools                 running tests
    |
MCPServerEnvironment                      class lookup by the name the Browser shows
    |
The Cuis image
```

Dependencies point down. The image does not know the package, the facades do not know the protocol, and the protocol does not know HTTP. No Cuis class is modified.

## Components

| Class | Responsibility | State |
| --- | --- | --- |
| `MCPServer` | Composition root: created with a port and the facade classes; owns the catalogue, the in-flight registry and the `WebServer`. Also the HTTP adapter: decodes the body, hands it to the protocol, encodes the response and answers `200` or `202`. | Port, catalogue, registry, web server |
| `MCPServerProtocol` | MCP over JSON-RPC: routes `initialize`, `ping`, `tools/list`, `tools/call` and `notifications/cancelled`; builds results and errors; describes tools for `tools/list`. Knows the catalogue, not HTTP. | The catalogue and registry it is given; a new instance per request |
| `MCPServerToolCatalogue` | Looks up tools by exposed name and lists them in name order. | Not changed after the builder creates it; no public mutators |
| `MCPServerCatalogueBuilder` | Builds a catalogue by reading the tool pragmas of the given facade classes (Builder). | None |
| `MCPServerToolDescriptor` | What a declaration says: exposed name, window, argument names, and a `MethodReference` to the implementing method (Value Object). | Set once, at creation |
| `MCPServerMethodComment` | Extracts the comment of a method from its source, for the tool description. | None |
| `MCPServerTool` | A tool as a command: runs the implementing method once, in a worker process, on a new facade instance, and answers a result (Command). | The descriptor |
| `MCPServerToolResult` | The text of a result and whether it is an error (Value Object). | Set once, at creation |
| `MCPServerInFlightRequests` | The calls running now, by request id, so they can be cancelled (Registry). | Mutable, shared by all requests, guarded by an internal mutex |
| `MCPServerWorkspaceTools` | Facade for the Workspace: `print_it`. | None |
| `MCPServerBrowserTools` | Facade for the Browser: reading, searching and editing classes and methods, and file out. | None |
| `MCPServerTestingTools` | Facade for the Test Runner: running a test class or a category. | None |
| `MCPServerEnvironment` | Class-side lookup of a class by the name the Browser shows, with `Foo class` for the class side; fails with a message instead of answering `nil`. | None |

The three facades are Facades in the pattern sense, one per tool window, and the catalogue is also used as a registry of tools. All the classes subclass `Object` ([D5](decisions.md#d5-composition-over-inheritance)).

## Declaring a tool

A tool is a method of a facade class. This is the complete declaration of `print_it`:

```smalltalk
printIt: aCodeString
	"Evaluate aCodeString and answer the printed representation of the result, the
	way the Workspace print-it does. The output is limited to 10000 characters,
	as in the editor."
	<mcpTool: #print_it system: 'Workspace' arguments: #('code')>
	^ (Compiler evaluate: aCodeString) printStringLimitedTo: 10000
```

- **Pragma.** `mcpTool:system:arguments:` gives the exposed name, the window (published as `_meta.system`) and the argument names, in the order of the selector's keywords. Pragma arguments must be literals. `MCPServerToolDescriptor` finds the pragma by the prefix of its keyword (`mcpTool`), so the declaration can gain keywords without breaking the lookup.
- **Description.** The method comment becomes the tool description. Comments are kept in the sources file, while pragmas are in the compiled method, so `MCPServerMethodComment` parses the comment from the method source: the first quoted string after the message pattern, with doubled quotes unescaped.
- **Catalogue.** `MCPServerCatalogueBuilder` walks the selectors of each facade class passed to `MCPServer class>>on:tools:`, builds a descriptor for every method that has the pragma, and wraps it in an `MCPServerTool`.
- **Name.** The snake_case form of the implementing selector, without colons ([D3](decisions.md#d3-model-tools-on-ide-operations-at-the-domain-layer)).
- **Input schema.** Every declared argument becomes a required property of type `string`. The facades convert strings to symbols or classes as needed.
- **Result.** A single text content item. If the method signals an `Error`, the result carries the exception class and message with `isError: true`, and the JSON-RPC request itself succeeds.

### Output bounds and costs

- `print_it` output is limited to 10,000 characters, like the editor's print-it.
- Listing tools (`all_calls_on`, `all_implementors_of`, `classes_in_category`, `classes_matching`, `methods_containing`) answer a count and at most 100 entries.
- `methods_containing` reads the source of every method in the image, one at a time. In the Cuis 7.8 image used, that was 18,224 methods in about 2.5 seconds. There is no index.

## Request handling

`MCPServer` registers a single service, `/mcp`, on a Cuis `WebServer` bound to `127.0.0.1`. For each request:

1. The body arrives with one character per byte, and `textFromWire:` decodes it as UTF-8 ([F2](findings.md#f2-request-and-response-bodies-were-not-utf-8)).
2. `Json readFrom:` parses it, and a new `MCPServerProtocol`, holding the server's catalogue and in-flight registry, handles the message.
3. The response is rendered with `Json render:`, encoded as UTF-8 bytes by `wireStringFor:`, and sent with status `200` and `application/json`. When there is nothing to answer, the server replies `202` with an empty body.

| Message | Answer |
| --- | --- |
| `initialize` | `protocolVersion` `2025-06-18`, `capabilities` with `tools`, `serverInfo` (`MCPServer`, `0.1`) and `instructions` ([D10](decisions.md#d10-the-handshake-describes-the-environment-not-rules)) |
| `ping` | An empty result |
| `tools/list` | Every tool in name order, with `name`, `description`, `inputSchema` and `_meta.system` |
| `tools/call` | The tool result; JSON-RPC error `-32602` for an unknown tool |
| Any other method with an `id` | JSON-RPC error `-32601` |
| `notifications/cancelled` | HTTP `202`, no body ([cancellation](#cancellation)) |
| Any other message without an `id` | HTTP `202`, no body |
| A `tools/call` whose worker was cancelled | HTTP `202`, no body |

Results recorded against the running server:

| Call | Recorded `result` |
| --- | --- |
| `print_it` with `(1 to: 10) inject: 0 into: [:a :b \| a + b]` | `{"isError":false,"content":[{"type":"text","text":"55"}]}` |
| `print_it` with `1 zork` | `{"isError":true,"content":[{"type":"text","text":"MessageNotUnderstood: SmallInteger>>zork"}]}` |

Not implemented at this layer: an answer to `GET` (the transport expects `405`), server-sent events, `Origin` validation and `Mcp-Session-Id`. The server does not keep the negotiated protocol version, and there is no explicit handling of malformed JSON or of JSON-RPC batches ([deferred](decisions.md#deferred-and-out-of-scope)).

## Execution and concurrency

Cuis runs all Smalltalk processes on one OS thread. A process runs until it waits or until a process of higher priority becomes ready; a process that computes is not interrupted by processes of equal or lower priority. Priorities in the image:

| Process | Priority |
| --- | --- |
| Timing (`Delay`) | 80 |
| High-priority I/O | 70 |
| `WebServer` listener and request handlers | 60 |
| UI (`Processor userInterruptPriority`) | 50 |
| Tool worker (`userInterruptPriority - 10`) | 40 |

`MCPServerTool>>executeWith:under:in:` runs each call as follows ([D6](decisions.md#d6-run-agent-work-below-the-ui-priority)):

1. Create the worker process, suspended, at priority 40 and named `MCPServer worker`. Its body runs the facade method and turns an `Error` into an error result; its `ensure:` block unregisters the call and signals a semaphore.
2. Register the worker in the in-flight registry under the request id, and keep the handle the registry answers.
3. Resume the worker, and make the request handler wait on the semaphore.
4. Answer the result, or `nil` if the worker was terminated before producing one. `nil` means that no response is sent and the adapter answers `202`.

**State.**

- **Not changed after construction:** the catalogue, the descriptors and the results. Every request shares them without locks. This is by convention (they have no public mutators), not enforced.
- **Mutable and shared:** the in-flight registry, one per server. It is the only shared mutable state in the package, so its lock lives inside `MCPServerInFlightRequests`: every access goes through a `Semaphore forMutualExclusion`, and the critical sections protect only the registry's own data.
- **The image:** mutable, shared with the human, and without transactions. A write by the agent can replace what the human has open ([O1](findings.md#o1-concurrent-edits-by-the-human-and-the-agent)).

**Cleanup.** A call can be terminated at any point, so code that opens a resource closes it in `ensure:`, which is the image's own convention (`FileEntry>>writeStreamDo:` follows it). `terminate` runs pending `ensure:` blocks before returning ([F6](findings.md#f6-process-and-semaphore-semantics)). The convention does not guarantee that later statements of an `ensure:` block run if an earlier one fails, or that the cleanup a tool performs is cheap.

## Cancellation

```
client A   tools/call, id 7        handler 1: register 7 -> resume worker -> wait on semaphore
client B   notifications/cancelled handler 2: cancel: 7 -> remove the entry, then terminate
           (requestId 7)                      the worker outside the lock
                                   worker:    ensure: unregister (already gone), signal
                                   handler 1: result is nil -> 202, no body
                                   handler 2: 202, no body; Transcript line with the reason
```

The invariants, and why each one holds:

1. **Register before resuming.** A worker resumed first could finish and unregister before being registered, and its entry would then stay in the registry forever. A spy records whether the worker was still suspended when registration happened (`MCPServerToolTest>>test06TheCallIsRegisteredBeforeTheWorkerCanRun`).
2. **Unregister by handle, not by id.** Registration answers a handle (`id -> process`) that the call gives back when done, so a call removes its own entry and never that of another call using the same id. Unregistering a handle that is already gone is not an error (`MCPServerInFlightRequestsTest>>test03TwoCallsWithTheSameIdDoNotCrossRemove`).
3. **An ambiguous id is not cancelled** ([D7](decisions.md#d7-cancellation-belongs-to-the-client); `MCPServerInFlightRequestsTest>>test06AnAmbiguousIdIsNotCancelled`).
4. **`cancel:` removes the entry itself,** because a process terminated before it runs does not run its `ensure:` (`MCPServerInFlightRequestsTest>>test07CancellingACallThatHasNotStartedYet`). In that case the waiting handler is not woken either ([O8](findings.md#o8-cancellation-before-the-worker-runs), suspected).
5. **Terminate outside the lock.** Terminating runs the worker's `ensure:`, which unregisters the call and needs the same lock.
6. **The reason goes to the Transcript,** where the person using the image can see it.
7. **A server without a registry ignores cancellations.** A server created before the registry existed answers `202` and stops nothing, since it registered no calls (`MCPServerTest>>test13AServerBornBeforeTheRegistryIgnoresACancellation`).
8. **Cancelling is not rolling back.** What the call already compiled stays compiled.

## Server lifecycle

- `MCPServer class>>on:tools:` builds the catalogue and a new in-flight registry. Nothing listens yet.
- `start` fails if the server is already listening (`Already listening on port N`) and if the image has no author, which it reads with `Utilities authorInitialsPerSe` so that no dialog opens. It then creates a `WebServer` listening on `127.0.0.1` and registers `/mcp`. A port held by another listener fails with `Could not listen on port N: ...` ([D8](decisions.md#d8-do-not-take-host-resources), [D9](decisions.md#d9-attribute-changes-to-the-image-owner)).
- `isListening` answers whether this server has a listener process.
- `destroy` destroys the `WebServer` and releases the port, after which a server can be started again on the same port.
- Several servers can exist in one image, each with its own port, catalogue and registry (`MCPServerTest>>test05TwoServersDoNotShareTheirState`).
- A server can appear alive without listening, notably after the image is saved and reopened ([O2](findings.md#o2-stale-server-handles-and-silent-listeners)).

## Testing

70 SUnit tests in the `MCPServerTest` package, with one test class per class under test:

| Test class | Tests | What it covers |
| --- | --- | --- |
| `MCPServerBrowserToolsTest` | 24 | Every Browser tool; unknown classes and methods, syntax errors, redefinition; class-side names; UTF-8 file-out |
| `MCPServerProtocolTest` | 12 | `initialize` and `instructions`, `tools/list` with `_meta.system`, `tools/call`, unknown tools, tool errors, notifications, cancellation |
| `MCPServerTest` | 11 | Construction, JSON-RPC bodies, notifications, independent servers, author requirement, double start, UTF-8 in and out, `202` and cancellation over real HTTP, a server without a registry |
| `MCPServerInFlightRequestsTest` | 7 | Registration and handles, ambiguous ids, cancelling running and not-yet-started calls |
| `MCPServerToolTest` | 6 | Execution, error results, worker priority, registration order and cleanup |
| `MCPServerTestingToolsTest` | 3 | Running a test class, collecting the classes of a category, invalid targets |
| `MCPServerToolCatalogueTest` | 2 | Building from declarations; running the catalogued tools |
| `MCPServerToolDescriptorTest` | 2 | Reading the pragma; the description from the comment |
| `MCPServerWorkspaceToolsTest` | 2 | `print_it` and its declaration |
| `MCPServerMethodCommentTest` | 1 | Extracting a method comment |

**Levels.**

- **Object level, in the image.** Most tests call objects directly: the facades, the descriptor and catalogue, the protocol with message dictionaries, and `MCPServer>>handleRequestBody:` with JSON strings.
- **HTTP level.** `MCPServerTest>>test11ANotificationIsAnsweredWith202AndNoBody` and `test12ACancellationStopsARequestOverHttp` start a server on a loopback port and use `WebClient`. The second sends a blocking call from one process and the cancellation from another.
- **Writes against the live image.** The Browser tests compile, classify and remove methods in `MCPServerBrowserToolsScratch`, define and remove temporary classes, and clean up in `tearDown`.
- **Test double.** `MCPServerInFlightRecorder` is a spy that understands the registry's protocol and records when it was called. There is no fake image: the facades are tested against the real one.

**Limits.**

- The tests depend on the state of the image and change it while they run ([README](../README.md#running-the-tests)).
- The test for categories collects test classes without running them ([F5](findings.md#f5-a-test-that-ran-its-own-category-froze-the-image)); running a category is exercised through the tool.
- Not covered: the cases in [O7](findings.md#o7-errors-that-do-not-surface) and [O8](findings.md#o8-cancellation-before-the-worker-runs).

## Planned vs. built

Before implementation, a design document proposed a class tree, the patterns to use and the main flows. This document replaces it. What became of each planned element:

| Planned element | Outcome | Reason |
| --- | --- | --- |
| `MCPServer`, the composition root | Built | |
| `MCPHttpEndpoint`, the HTTP adapter | Merged into `MCPServer` | A separate class would have had a single user |
| `MCPTransport` protocol, with HTTP and stdio implementations | Not built | Only HTTP exists; the abstraction waits for a second transport |
| `MCPDispatcher` and one `MCPProtocolCommand` subclass per method (initialize, list tools, call tool, ping, cancel) | Merged into `MCPServerProtocol` | Five methods with one implementation each; cancellation is a branch of `handleMessage:` |
| `MCPSession`, per-connection state | Deferred | The transport has no session identity yet; the in-flight registry moved to the server instead |
| `MCPToolCatalogue`, `MCPCatalogueBuilder`, `MCPToolDescriptor`, `MCPTool` | Built, with the `MCPServer` prefix | |
| `MCPToolDecorator`, `MCPVersionGuardDecorator`, `MCPVersionToken`, `MCPVersioning` | Rejected | They existed for optimistic concurrency, which was left out of scope ([O1](findings.md#o1-concurrent-edits-by-the-human-and-the-agent)) |
| `MCPToolInvocation`, `MCPArguments`, `MCPArgumentCoercion` | Not built | Arguments are strings passed in declaration order; the facades convert them |
| `MCPResult` | Built as `MCPServerToolResult` | |
| `MCPValueRenderer`, `MCPRenderPolicy` | Not built | Tools answer text, and bounds are applied where the text is produced |
| `MCPErrorMapper` | Not built | One rule is enough: an `Error` becomes a result with `isError: true` |
| `MCPWindowProjection`, to show results in real tool windows | Deferred | Not needed for the experiment |
| `MCPEnvironment`, injected so that facades could be tested with a fake | Built as a class-side helper, not injected | The tests run against the live image instead |
| Facades for the Inspector, Process Browser and Debugger | Deferred | See [deferred scope](decisions.md#deferred-and-out-of-scope) |
| `MCPServerInFlightRequests` | Added; not in the plan | Cancellation needed a registry shared across requests |
| `MCPServerMethodComment` | Added; not in the plan | Comments live in the sources file, not in the compiled method |

Of the planned patterns, Command, Builder, Value Object, Facade and Registry remain. Decorator and Memento went with the version guard, Null Object with the window projection, and Strategy was not needed. Template Method was excluded from the start, since it would have meant inheritance for code reuse. The rule behind these outcomes is [D5](decisions.md#d5-composition-over-inheritance).
