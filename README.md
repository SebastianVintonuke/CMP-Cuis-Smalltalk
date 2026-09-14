# MCPServer for Cuis Smalltalk

An experimental [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server that runs inside a live Cuis Smalltalk image. It exposes operations of the image's development tools (Workspace, Browser and Test Runner) as MCP tools, so that an AI agent can read, change and test code in the same image a programmer is using.

## Status: proof of concept

This is a short experiment, not a product. Its purpose was to explore what it takes for an agent to work inside a running Smalltalk image alongside a person, to find the problems that appear, and to propose or implement solutions for them. The code is a working prototype; the documentation records the reasoning and the trade-offs behind it.

It is not suitable for production or shared use. The main limitations:

- **No sandbox, and access control is the loopback interface only.** `print_it` evaluates arbitrary code by design, and any local process that can connect to the port controls the image. There is no authentication and no `Origin` validation ([D2](docs/decisions.md#d2-control-access-not-operations)).
- **No detection of conflicting edits.** If the human and the agent change the same method, the later compile silently replaces the earlier one ([O1](docs/findings.md#o1-concurrent-edits-by-the-human-and-the-agent)).
- **A subset of the HTTP transport.** JSON responses to `POST` only: no server-sent events, no `GET`, no MCP sessions. The design assumes a single client ([deferred scope](docs/decisions.md#deferred-and-out-of-scope)).
- **No undo beyond the image's own change log.** Cancelling a call stops it but does not revert what it already changed ([D7](docs/decisions.md#d7-cancellation-belongs-to-the-client)).
- **The server does not survive saving and reopening the image** ([O2](docs/findings.md#o2-stale-server-handles-and-silent-listeners)).

The package was developed test-first with an AI coding agent working under the author's direction; see [development process](docs/development-log.md#development-process).

## Motivation

One way to connect an agent to Smalltalk is to use the image as a remote interpreter: the agent sends code and reads results, often from a separate headless image. This experiment explores a different arrangement. The user opens their usual image, with its windows, state and unsaved work, loads the package and starts a server. The agent then works inside that image: it browses classes, reads and compiles methods and runs tests, while the human sees the changes in the usual tools and can keep working, correct them or undo them.

That choice shapes most of the design. The agent and the human share one VM ([D1](docs/decisions.md#d1-run-inside-the-interactive-image-over-http)), and the agent has the same capabilities as the programmer, including the ability to break the image ([D2](docs/decisions.md#d2-control-access-not-operations)).

## What is implemented

**Protocol.** MCP version `2025-06-18`: `initialize` (with `instructions`), `ping`, `tools/list`, `tools/call` and `notifications/cancelled`, over HTTP `POST` at `/mcp` on `127.0.0.1`. See [request handling](docs/architecture.md#request-handling).

**Tools.** 19 tools in three facades. Each one corresponds to an operation of a Cuis tool window ([D3](docs/decisions.md#d3-model-tools-on-ide-operations-at-the-domain-layer)) and is declared by a pragma on the method that implements it ([D4](docs/decisions.md#d4-declare-each-tool-once-on-its-implementing-method)).

| Window | Tool | Implementing selector | What it does |
| --- | --- | --- | --- |
| Workspace | `print_it` | `printIt:` | Evaluates code and answers the printed result, up to 10,000 characters. |
| Browser | `selectors_of_class` | `selectorsOfClass:` | Lists the selectors of both sides of a class, by method category. |
| Browser | `source_of_method_in_class` | `sourceOfMethod:inClass:` | Answers the source of a method, with its comment and pragmas. |
| Browser | `comment_of_class` | `commentOfClass:` | Answers the class comment. |
| Browser | `hierarchy_of_class` | `hierarchyOfClass:` | Answers the superclass chain and the direct subclasses. |
| Browser | `classes_in_category` | `classesInCategory:` | Lists the classes of a system category. |
| Browser | `classes_matching` | `classesMatching:` | Lists the classes whose name contains a text. |
| Browser | `all_calls_on` | `allCallsOn:` | Lists the senders of a selector. |
| Browser | `all_implementors_of` | `allImplementorsOf:` | Lists the implementors of a selector. |
| Browser | `methods_containing` | `methodsContaining:` | Lists the methods whose source contains a text. |
| Browser | `compile_method_in_class_classified` | `compileMethod:inClass:classified:` | Compiles a method source in a class, under a method category. |
| Browser | `classify_method_in_class_under` | `classifyMethod:inClass:under:` | Moves a method to another method category. |
| Browser | `remove_method_in_class` | `removeMethod:inClass:` | Removes a method from a class. |
| Browser | `define_class_subclass_of_variables_category` | `defineClass:subclassOf:variables:category:` | Defines a new class; refuses to redefine an existing one. |
| Browser | `rename_class_to` | `renameClass:to:` | Renames a class; references to it follow. |
| Browser | `remove_class` | `removeClass:` | Removes a class and its methods. |
| Browser | `file_out_package_to` | `fileOutPackage:to:` | Writes the package of a category to a file. |
| Test Runner | `run_tests_in_class` | `runTestsInClass:` | Runs the tests of a test class and answers the counts and defects. |
| Test Runner | `run_tests_in_category` | `runTestsInCategory:` | Runs every test class of a category. |

Listing tools answer at most 100 entries. In tools that read or edit methods, a class name ending in ` class` (for example `Object class`) refers to the class side, as in the Browser.

**Behavior.**

- Tool calls run in a worker process below the UI priority, so the human's interface keeps the CPU ([D6](docs/decisions.md#d6-run-agent-work-below-the-ui-priority)).
- The client that issued a call can cancel it while it runs ([D7](docs/decisions.md#d7-cancellation-belongs-to-the-client)).
- Request and response bodies are decoded and encoded as UTF-8 at the HTTP boundary ([F2](docs/findings.md#f2-request-and-response-bodies-were-not-utf-8)).
- The server does not start in an image without an author ([D9](docs/decisions.md#d9-attribute-changes-to-the-image-owner)), and does not take over a port held by another listener ([D8](docs/decisions.md#d8-do-not-take-host-resources)).
- A tool that raises an error answers a result with `isError: true`; the request itself succeeds.

**Tests.** 70 SUnit tests in 10 test classes, covering the facades, the protocol and the HTTP adapter, including cancellation over HTTP ([testing](docs/architecture.md#testing)).

## Getting started

**Requirements.**

- Cuis Smalltalk 7.8, the version used in the experiment. The package declares `WebClient` and `JSON` as requirements, so the image must be able to find those packages.
- The VM launched with `-encoding UTF-8`, as the Cuis launcher does, so that file-outs are written as UTF-8.
- An author set in the image, for example `Utilities setAuthorName: 'Ada Lovelace' initials: 'AL'`. The server refuses to start without one.
- Python 3, only for the optional [demo panel](demo/README.md).

**Load the package.** Put `src/MCPServer.pck.st`, and `src/MCPServerTest.pck.st` if you want the tests, where `Feature require:` looks for packages; the experiment used the image's `Packages/Features` directory. Then evaluate in a Workspace:

```smalltalk
Feature require: 'MCPServer'.
```

**Start a server.**

```smalltalk
| server |
server := MCPServer
	on: 8790
	tools: { MCPServerWorkspaceTools. MCPServerBrowserTools. MCPServerTestingTools }.
server start.
Smalltalk at: #MCPDemo put: server
```

The server exposes the tools declared by the facade classes given in `tools:`. The endpoint is `http://127.0.0.1:8790/mcp`.

**Connect a client.** MCP clients that use HTTP can connect to that URL, within the transport limits listed above; the MCP Inspector was used during the experiment. The repository also includes a small panel that lists the tools, runs them from a form and cancels running calls: see [demo/README.md](demo/README.md).

**Stop the server.**

```smalltalk
(Smalltalk at: #MCPDemo) destroy
```

`destroy` releases the port. Two caveats, both described in [O2](docs/findings.md#o2-stale-server-handles-and-silent-listeners):

- Do not destroy a server from a call it is serving (for example, through `print_it`). The socket can stay open with no process accepting connections.
- A server does not survive saving and reopening the image. Afterwards the global still refers to the server object, which answers its port and tools although nothing is listening. Create and start a new server.

### Freeing a port held by a stale server

If `start` reports that the port is taken, the server does not free it by itself ([D8](docs/decisions.md#d8-do-not-take-host-resources)). To release it from the image, destroy the `WebServer` that is listening on it:

```smalltalk
WebServer allInstances do: [ :each |
	(each listenerProcess isNil not and: [ each listenerPort = 8790 ]) ifTrue: [ each destroy ] ]
```

## Running the tests

```smalltalk
Feature require: 'MCPServerTest'.
```

Run the `MCPServerTest` category from the Test Runner, or through the server with the `run_tests_in_category` tool. Through the tool, a test that raises an unexpected error may abort the run instead of being counted ([O7](docs/findings.md#o7-errors-that-do-not-surface)). The tests run in the live image and have side effects:

- they start servers on `127.0.0.1`, ports 8791 and 8795 to 8797;
- they write temporary file-outs to the Cuis user files directory (`DirectoryEntry userBaseDirectory`) and remove them;
- they compile and remove methods in `MCPServerBrowserToolsScratch`, and define, rename and remove temporary classes;
- they change the image author while `MCPServerTest>>test06StartingRequiresAnAuthor` runs, and restore it afterwards.

## Repository layout

```
src/MCPServer.pck.st       the MCPServer package (13 classes)
src/MCPServerTest.pck.st   the tests (10 test classes and 2 helpers)
demo/panel-mcp.py          manual test panel (Python 3 standard library)
demo/cancel-demo.st        a long-running call for trying cancellation
docs/                      design documentation
```

## Documentation

- [docs/architecture.md](docs/architecture.md): components, request handling, concurrency, cancellation, testing, and how the implementation differs from the initial design.
- [docs/decisions.md](docs/decisions.md): technical decisions with their trade-offs and rejected alternatives, deferred scope, and prior art.
- [docs/findings.md](docs/findings.md): problems found during the experiment, with evidence, causes and resolutions, and the issues that remain open.
- [docs/development-log.md](docs/development-log.md): how the package was developed, and its test-driven milestones.
- [demo/README.md](demo/README.md): the manual test panel and the cancellation demo.
